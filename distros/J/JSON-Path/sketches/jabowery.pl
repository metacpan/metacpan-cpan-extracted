use JSON::Parse 'parse_json';
use JSON::Path;
local $JSON::Path::Safe = 0;
my $json='{
   "4" : {
      "value_raw" : "European",
      "value" : "European",
      "name" : "Ethnicity",
      "type" : "radio",
      "id" : 4
   },
   "1" : {
      "middle" : "",
      "first" : "James",
      "value" : "James Bowery",
      "last" : "Bowery",
      "name" : "Name",
      "type" : "name",
      "id" : 1
   },
   "3" : {
      "value_raw" : "Male",
      "value" : "Male",
      "name" : "Gender",
      "type" : "radio",
      "id" : 3
   },
   "2" : {
      "unix" : 1498176000,
      "time" : "",
      "date" : "06/23/2017",
      "value" : "06/23/2017",
      "name" : "Birthdate",
      "type" : "date-time",
      "id" : 2
   },
   "5" : {
      "value" : "jabowery@emailservice.com",
      "name" : "Email",
      "type" : "text",
      "id" : 5
   }
}';
my $json_hash = parse_json($json);
my $p3 = new JSON::Path '$.[?($_->{name} eq "Email")]';
my @paths=$p3->paths($json_hash);
