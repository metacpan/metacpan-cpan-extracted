package Car2;

my $listgroupname = 'vehicles';

my $level1 =
  [
   { 'car-makers' =>
     [
      [  "Select a maker", ""          => "dummy-list"  ],
      [  "Toyota",         "Toyota"    => "Toyota"     ],
      [  "Honda",          "Honda"     => "Honda"       ],
      [  "Chrysler",       "Chrysler"  => "Chrysler", 1  ],
      [  "Dodge",          "Dodge"     => "Dodge" ],
      [  "Ford",           "Ford"      => "Ford" ]
     ]
   }
  ] ;

my $level2 =
  [

   { 'dummy-list' => 
     [
      [ "Not available", "" => "dummy-sub"] 
     ] },

   { Toyota => 
     [
      ["--- Toyota vehicles ---", "" => "dummy-list" ],
      [ "Cars",    "car",            => "Toyota-Cars"            ],
      [ "SUVs/Van", "suv",           => "Toyota-SUVs/Van"  ],
      [ "Trucks", "truck",           => "Toyota-Trucks", 1 ]
     ]
   },

   { "Honda" =>
     [
      [ "--- Honda vehicles ---", "" => "dummy-list" ],
      [ "Cars", "car"                => "Honda-Cars" ],
      [ "SUVs/Van", "suv"            => "Honda-SUVs/Van", 1 ]
     ]
   },

   { "Chrysler" => 
     [
      [ "--- Chrysler vehicles ---", "" => "dummy-list" ],
      [ "Cars", "car"                   => "Chrysler-Cars", 1 ],
      [ "SUVs/Van", "suv"               => "Chrysler-SUVs/Van" ]
     ]
   },

   { "Dodge" =>
     [
      [ "--- Dodge vehicles ---", ""    => "dummy-list" ],
      [ "Cars", "car"                   => "Dodge-Cars" ],
      [ "SUVs/Van", "suv",               => "Dodge-SUVs/Van" ],
      [ "Trucks", "truck"               => "Dodge-Trucks" ]
     ]
   },

   { Ford =>
     [
      [ "--- Ford vehicles ---", ""     => "dummy-list" ],
      [ "Cars", "car"                   => "Ford-Cars" ],
      [ "SUVs/Van", "suv"               => "Ford-SUVs/Van" ],
      [ "Trucks", "truck"               => "Ford-Trucks" ]
     ]
   }

  ];

my $level3 = 
  [
   { "dummy-sub" => 
     [
      [ "Not available", "" ]
     ]
   },

   { "Dodge-Cars" => 
     [
      [ "--- Dodge cars ---", "" ],
      [  "Intrepid", "Intrepid" ],
      [  "Neon", "Neon" ],
      [  "SRT-4", "SRT-4" ],
      [  "Stratus Coupe", "Stratus Coupe" ],
      [  "Stratus Sedan", "Stratus Sedan" ],
      [  "Viper", "Viper" ]
     ]
   },

   { "Dodge-SUVs/Van" =>
     [
      ["--- Dodge SUVs/Van ---", "" ],
      [ "Caravan", "Caravan" ],
      [ "Durango", "Durango" ],
      [ "Ram Van", "Ram Van" ]
     ]
   },

   { "Dodge-Trucks" =>
     [
      ["--- Dodge trucks ---", "" ],
      [  "Dakota", "Dakota" ],
      [  "Ram Pickup", "Ram Pickup" ],
     ] },

   { "Chrysler-Cars" =>
     [
      ["--- Chrysler cars ---", "" ],
      [  "300M", "300M" ],
      [  "PT Cruiser", "PT Cruiser", 1 ],
      [  "Concorde", "Concorde" ],
      [  "Sebring Coupe", "Sebring Coupe" ],
      [  "Sebring Sedan", "Sebring Sedan" ],
      [  "Sebring Convertible", "Sebring Convertible", 1 ]
     ] },

   { "Chrysler-SUVs/Van" =>
     [
      ["--- Chrysler SUVs/Van ---", "" ],
      [  "Town & Country", "Town & Country" ],
      [  "Voyager", "Voyager" ]
     ] 
   },

   { "Honda-Cars" => 
     [
      ["--- Honda cars ---", "" ],
      [  "Accord Sedan", "Accord Sedan" ],
      [  "Accord Coupe", "Accord Coupe" ],
      [  "Civic Sedan", "Civic Sedan" ],
      [  "Civic Coupe", "Civic Coupe" ],
      [  "Civic Hybrid", "Civic Hybrid" ],
      [  "Civic Si", "Civic Si" ],
      [  "Civic GX", "Civic GX" ],
      [  "Insight", "Insight" ],
      [  "S2000", "S2000" ]
     ] } ,

   { "Honda-SUVs/Van" =>
     [
      ["--- Honda SUVs/Van ---", "" ],
      [  "CR-V", "CR-V" ],
      [  "Pilot", "Pilot" ],
      [  "Odyssey", "Odyssey", 1 ] ] },


   { "Toyota-Cars" => 
     [
      [ "--- Toyota cars ---", "" ],
      [  "Avalon", "Avalon" ],
      [  "Camry", "Camry" ],
      [  "Celica", "Celica" ],
      [  "Corolla", "Corolla" ],
      [  "ECHO", "ECHO" ],
      [  "Matrix", "Matrix" ],
      [  "MR2 Spyder", "MR2 Spyder" ],
      [  "Prius", "Prius" ] ] },


   { "Toyota-SUVs/Van" =>
     [
      ["--- Toyota SUVs/Van ---", "" ],
      [  "4Runner", "4Runner" ],
      [  "Highlander", "Highlander" ],
      [  "Land Cruiser", "Land Cruiser" ],
      [  "RAV4", "RAV4" ],
      [  "Sequoia", "Sequoia" ],
      [  "Sienna", "Sienna", 1 ] ] },

   { "Toyota-Trucks" => 
     [
      ["--- Toyota trucks ---", "" ],
      [  "Tacoma", "Tacoma" ],
      [  "Tundra", "Tundra", 1 ] ] },

   { "Ford-Cars" => 
     [
      ["--- Ford cars ---", "" ],
      [  "ZX2", "ZX2" ],
      [  "Focus", "Focus" ],
      [  "Taurus", "Taurus" ],
      [  "Crown Victoria", "Crown Victoria" ],
      [  "Mustang", "Mustang" ],
      [  "Thunderbird", "Thunderbird" ] ] },

   { "Ford-SUVs/Van" => 
     [
      [ "--- Ford SUVs/Van ---", "" ],
      [  "Escape", "Escape" ],
      [  "Explorer", "Explorer" ],
      [  "Expedition", "Expedition" ],
      [  "Excursion", "Excursion" ],
      [  "Windstar", "Windstar" ],
      [  "Econoline", "Econoline" ] ] },

   { "Ford-Trucks" =>
     [
      [ "--- Ford trucks ---", "" ],
      [  "Ranger", "Ranger" ],
      [  "F-150", "F-150" ],
      [  "F-250", "F-250" ],
      [  "F-350", "F-350" ] ] },

  ];




sub model {

  {
   data  =>  [ $level1, $level2, $level3 ],
   listgroupname => $listgroupname,
 }
	
}

1,
