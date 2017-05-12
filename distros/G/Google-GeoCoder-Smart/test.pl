use Google::GeoCoder::Smart;
  
 $geo = Google::GeoCoder::Smart->new();

 my ($resultnum, $error, @results, $returncontent) = $geo->geocode("address" => "1600 Amphitheatre Parkway Mountain View, CA 94043");





 $lat = $results[0]{geometry}{location}{lat};

 $lng = $results[0]{geometry}{location}{lng};



if ($lat) { 

if ($lng) { 

print "test successful!\n";

 } 

else { 

print "error no longitude\n"; 

}; 

} 

else { 

print "error no latitude\n";

 };  

print "Google Returned Request Status: $error\n";


#blame any bugs on the government and the Android phone I wrote this test.pl version from
