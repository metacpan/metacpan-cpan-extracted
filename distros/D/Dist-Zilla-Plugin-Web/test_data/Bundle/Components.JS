COMPONENTS = {
	// a comment
	
    EvenPlusOdd : {
        
        saveAs      : "even-plus-odd.js",
        
        "contains"  : [
            "+Even",
            "+Odd"
        ]
    },
    
    
    "EvenPlusOddMin" : {
        
        "saveAs"    : "even-plus-odd.min.js",
        
        "minify"    : "yui",
        
        "contains"  : [
            "+EvenPlusOdd"
        ]
    },
    
	
	"Even" : {
        "contains"    : [
            "File2",
            "File4"
        ]
    },
    
    
    "Odd" : [
    	"File1",
    	"File3"
    ],
    
    
    "Part21" : {
        "saveAs"   : "bundles/part21.js",
        
        "contains" :     [
            "+Part22",
            "Part2.File1",
            "node_modules/some_module/File4.js"
        ]
    },
    
    
    "Part22" : {
        
        "contains" :     [
            "+Part23",
            "Part2.File2"
        ]
    },
    
    
    Part23 : {
        
        contains : [
            "node_modules/some_module/File1.js",
            "Part2.File3",
            
            {
                "text" : "yo!"
            },
            
            "node_modules/some_module/File2.js"
        ]
    } 
}