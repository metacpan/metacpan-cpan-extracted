# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 13;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new(_signer=>"");

my $marker=$map->marker(location=>"Washington,DC");

isa_ok($marker, "Geo::Google::StaticMaps::V2::Markers");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=Washington%2CDC", '$map->url simple example');

$marker->color("blue");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3Ablue%7CWashington%2CDC", '$map->url simple example');


$marker->addLocation("Clifton,VA");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3Ablue%7CWashington%2CDC%7CClifton%2CVA", '$map->url');

$marker->addLocation("Arlington,VA");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3Ablue%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA", '$map->url');

$marker->label("A");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3Ablue%7Clabel%3AA%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA", '$map->url');


$marker->size("tiny");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=size%3Atiny%7Ccolor%3Ablue%7Clabel%3AA%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA", '$map->url');

$marker->icon("http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=size%3Atiny%7Ccolor%3Ablue%7Clabel%3AA%7Cicon%3Ahttp%3A%2F%2Fmaps.google.com%2Fmapfiles%2Fkml%2Fshapes%2Fplacemark_circle.png%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA", '$map->url');

$marker->shadow(0);

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=size%3Atiny%7Ccolor%3Ablue%7Clabel%3AA%7Cicon%3Ahttp%3A%2F%2Fmaps.google.com%2Fmapfiles%2Fkml%2Fshapes%2Fplacemark_circle.png%7Cshadow%3Afalse%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA", '$map->url');

$marker->addLocation("38.846272,-77.306607"); #Fairfax, VA

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=size%3Atiny%7Ccolor%3Ablue%7Clabel%3AA%7Cicon%3Ahttp%3A%2F%2Fmaps.google.com%2Fmapfiles%2Fkml%2Fshapes%2Fplacemark_circle.png%7Cshadow%3Afalse%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA%7C38.846272%2C-77.306607", '$map->url');

$marker->addLocation([38.901564,-77.265220]); #Vienna, VA

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=size%3Atiny%7Ccolor%3Ablue%7Clabel%3AA%7Cicon%3Ahttp%3A%2F%2Fmaps.google.com%2Fmapfiles%2Fkml%2Fshapes%2Fplacemark_circle.png%7Cshadow%3Afalse%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA%7C38.846272%2C-77.306607%7C38.901564%2C-77.265220", '$map->url');

$marker->addLocation({lat=>38.882233,lon=>-77.171077}); #Falls Church, VA

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=size%3Atiny%7Ccolor%3Ablue%7Clabel%3AA%7Cicon%3Ahttp%3A%2F%2Fmaps.google.com%2Fmapfiles%2Fkml%2Fshapes%2Fplacemark_circle.png%7Cshadow%3Afalse%7CWashington%2CDC%7CClifton%2CVA%7CArlington%2CVA%7C38.846272%2C-77.306607%7C38.901564%2C-77.265220%7C38.882233%2C-77.171077", '$map->url');
