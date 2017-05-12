package Car1;

my $listgroupname = 'vehicles';

my $level1 =
  [
   [ "car-makers", "Select a maker", "",         "dummy-list"  ],
   [ "car-makers", "Toyota",         "Toyota",   "Toyota"       ],
   [ "car-makers", "Honda",          "Honda",    "Honda"        ],
   [ "car-makers", "Chrysler",       "Chrysler", "Chrysler", 1  ],
   [ "car-makers", "Dodge",          "Dodge",    "Dodge" ],
   [ "car-makers", "Ford",           "Ford",     "Ford" ]
  ];

my $level2 =
  [

   ["dummy-list", "Not available", "", "dummy-sub"],

   [ "Toyota", "--- Toyota vehicles ---", "", "dummy-list" ],
   [ "Toyota", "Cars", "car", "Toyota-Cars"            ],
   [ "Toyota", "SUVs/Van", "suv", "Toyota-SUVs/Van"  ],
   [ "Toyota", "Trucks", "truck", "Toyota-Trucks", 1 ],

   [ "Honda", "--- Honda vehicles ---", "", "dummy-list" ],
   [ "Honda", "Cars", "car", "Honda-Cars" ],
   [ "Honda", "SUVs/Van", "suv", "Honda-SUVs/Van", 1 ],

   [ "Chrysler", "--- Chrysler vehicles ---", "", "dummy-list" ],
   [ "Chrysler", "Cars", "car", "Chrysler-Cars", 1 ],
   [ "Chrysler", "SUVs/Van", "suv", "Chrysler-SUVs/Van" ],

   [ "Dodge", "--- Dodge vehicles ---", "", "dummy-list" ],
   [ "Dodge", "Cars", "car", "Dodge-Cars" ],
   [ "Dodge", "SUVs/Van", "suv", "Dodge-SUVs/Van" ],
   [ "Dodge", "Trucks", "truck", "Dodge-Trucks" ],

   [ "Ford", "--- Ford vehicles ---", "", "dummy-list" ],
   [ "Ford", "Cars", "car", "Ford-Cars" ],
   [ "Ford", "SUVs/Van", "suv", "Ford-SUVs/Van" ],
   [ "Ford", "Trucks", "truck", "Ford-Trucks" ],

  ];

my $level3 = 
  [
   [ "dummy-sub", "Not available", "" ],

   [ "Dodge-Cars", "--- Dodge cars ---", "" ],
   [ "Dodge-Cars", "Intrepid", "Intrepid" ],
   [ "Dodge-Cars", "Neon", "Neon" ],
   [ "Dodge-Cars", "SRT-4", "SRT-4" ],
   [ "Dodge-Cars", "Stratus Coupe", "Stratus Coupe" ],
   [ "Dodge-Cars", "Stratus Sedan", "Stratus Sedan" ],
   [ "Dodge-Cars", "Viper", "Viper" ],

   [ "Dodge-SUVs/Van", "--- Dodge SUVs/Van ---", "" ],
   [ "Dodge-SUVs/Van", "Caravan", "Caravan" ],
   [ "Dodge-SUVs/Van", "Durango", "Durango" ],
   [ "Dodge-SUVs/Van", "Ram Van", "Ram Van" ],

   [ "Dodge-Trucks", "--- Dodge trucks ---", "" ],
   [ "Dodge-Trucks", "Dakota", "Dakota" ],
   [ "Dodge-Trucks", "Ram Pickup", "Ram Pickup" ],

   [ "Chrysler-Cars", "--- Chrysler cars ---", "" ],
   [ "Chrysler-Cars", "300M", "300M" ],
   [ "Chrysler-Cars", "PT Cruiser", "PT Cruiser", 1 ],
   [ "Chrysler-Cars", "Concorde", "Concorde" ],
   [ "Chrysler-Cars", "Sebring Coupe", "Sebring Coupe" ],
   [ "Chrysler-Cars", "Sebring Sedan", "Sebring Sedan" ],
   [ "Chrysler-Cars", "Sebring Convertible", "Sebring Convertible", 1 ],

   [ "Chrysler-SUVs/Van", "--- Chrysler SUVs/Van ---", "" ],
   [ "Chrysler-SUVs/Van", "Town & Country", "Town & Country" ],
   [ "Chrysler-SUVs/Van", "Voyager", "Voyager" ],

   [ "Honda-Cars", "--- Honda cars ---", "" ],
   [ "Honda-Cars", "Accord Sedan", "Accord Sedan" ],
   [ "Honda-Cars", "Accord Coupe", "Accord Coupe" ],
   [ "Honda-Cars", "Civic Sedan", "Civic Sedan" ],
   [ "Honda-Cars", "Civic Coupe", "Civic Coupe" ],
   [ "Honda-Cars", "Civic Hybrid", "Civic Hybrid" ],
   [ "Honda-Cars", "Civic Si", "Civic Si" ],
   [ "Honda-Cars", "Civic GX", "Civic GX" ],
   [ "Honda-Cars", "Insight", "Insight" ],
   [ "Honda-Cars", "S2000", "S2000" ],

   [ "Honda-SUVs/Van", "--- Honda SUVs/Van ---", "" ],
   [ "Honda-SUVs/Van", "CR-V", "CR-V" ],
   [ "Honda-SUVs/Van", "Pilot", "Pilot" ],
   [ "Honda-SUVs/Van", "Odyssey", "Odyssey", 1 ],


   [ "Toyota-Cars", "--- Toyota cars ---", "" ],
   [ "Toyota-Cars", "Avalon", "Avalon" ],
   [ "Toyota-Cars", "Camry", "Camry" ],
   [ "Toyota-Cars", "Celica", "Celica" ],
   [ "Toyota-Cars", "Corolla", "Corolla" ],
   [ "Toyota-Cars", "ECHO", "ECHO" ],
   [ "Toyota-Cars", "Matrix", "Matrix" ],
   [ "Toyota-Cars", "MR2 Spyder", "MR2 Spyder" ],
   [ "Toyota-Cars", "Prius", "Prius" ],

   [ "Toyota-SUVs/Van", "--- Toyota SUVs/Van ---", "" ],
   [ "Toyota-SUVs/Van", "4Runner", "4Runner" ],
   [ "Toyota-SUVs/Van", "Highlander", "Highlander" ],
   [ "Toyota-SUVs/Van", "Land Cruiser", "Land Cruiser" ],
   [ "Toyota-SUVs/Van", "RAV4", "RAV4" ],
   [ "Toyota-SUVs/Van", "Sequoia", "Sequoia" ],
   [ "Toyota-SUVs/Van", "Sienna", "Sienna", 1 ],

   [ "Toyota-Trucks", "--- Toyota trucks ---", "" ],
   [ "Toyota-Trucks", "Tacoma", "Tacoma" ],
   [ "Toyota-Trucks", "Tundra", "Tundra", 1 ],

   [ "Ford-Cars", "--- Ford cars ---", "" ],
   [ "Ford-Cars", "ZX2", "ZX2" ],
   [ "Ford-Cars", "Focus", "Focus" ],
   [ "Ford-Cars", "Taurus", "Taurus" ],
   [ "Ford-Cars", "Crown Victoria", "Crown Victoria" ],
   [ "Ford-Cars", "Mustang", "Mustang" ],
   [ "Ford-Cars", "Thunderbird", "Thunderbird" ],

   [ "Ford-SUVs/Van", "--- Ford SUVs/Van ---", "" ],
   [ "Ford-SUVs/Van", "Escape", "Escape" ],
   [ "Ford-SUVs/Van", "Explorer", "Explorer" ],
   [ "Ford-SUVs/Van", "Expedition", "Expedition" ],
   [ "Ford-SUVs/Van", "Excursion", "Excursion" ],
   [ "Ford-SUVs/Van", "Windstar", "Windstar" ],
   [ "Ford-SUVs/Van", "Econoline", "Econoline" ],

   [ "Ford-Trucks", "--- Ford trucks ---", "" ],
   [ "Ford-Trucks", "Ranger", "Ranger" ],
   [ "Ford-Trucks", "F-150", "F-150" ],
   [ "Ford-Trucks", "F-250", "F-250" ],
   [ "Ford-Trucks", "F-350", "F-350" ],

  ];




sub data {

  (
   data  =>  [ $level1, $level2, $level3 ],
   listgroupname => $listgroupname,
  )
	
}

1,
