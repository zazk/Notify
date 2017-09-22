//
//  ViewController.swift
//  Notify
//
//  Created by user on 9/14/17.
//  Copyright © 2017 cubix. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableData:[(titulo:String,contenido:String,imagen:String,web:String)] = []
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? NewsTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        cell.details.text = tableData[indexPath.row].contenido
        cell.title.text = tableData[indexPath.row].titulo
        if let url = URL.init(string:tableData[indexPath.row].imagen ) {
            cell.img.downloadedFrom(url: url)
            
        }
        return cell
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        get_data_from_url(url: "http://w.areminds.com/data.json")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95.0
    }
    
    
    func get_data_from_url(url:String)
    {
        
        var request = URLRequest(url: URL(string:url)!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                
            }
            
            self.extract_json(data)
        }
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Move to a background thread to do some long running work
        DispatchQueue.global(qos: .userInitiated).async {
            // Bounce back to the main thread to update the UI
            DispatchQueue.main.async {
                guard let url = URL(string: self.tableData[indexPath.row].web as String) else {
                    return //be safe
                }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                
            }
        }
    }
    
    
    
    func extract_json(_ data: Data)
    {
        
        
        let json: Any?
        
        print("DATA = \(String(describing: data))")
        do
        {
            json = try JSONSerialization.jsonObject(with: data, options: [])
        }
        catch
        {
            print("Error deserializing JSON: \(error)")
            return
        }
        
        guard let data_list = json as? NSArray else
        {
            return
        }
        
        
        if let list = json as? NSArray
        {
            for i in 0 ..< data_list.count
            {
                
                
                if let item = list[i] as? NSDictionary
                {
                    
                    tableData.append(
                        (titulo:item["titulo"] ,
                         contenido:item["contenido"] ,
                         imagen:item["url_imagen"],
                         web:item["url_web"]) as! (titulo: String, contenido: String, imagen: String, web: String)
                    )
                    
                    
                }
            }
        }
        
        
        
        DispatchQueue.main.async(execute: {self.do_table_refresh()})
        
    }
    
    
    func do_table_refresh()
    {
        self.tableView.reloadData()
        
    }
    
}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                
                self.contentMode = .scaleAspectFill
                self.clipsToBounds = true
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
