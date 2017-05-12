# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 8;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new(_signer=>"");

my $visible=$map->visible(location=>"Washington,DC");

isa_ok($visible, "Geo::Google::StaticMaps::V2::Visible");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&visible=Washington%2CDC", '$map->url simple example');

$visible->addLocation("Clifton,VA");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&visible=Washington%2CDC%7CClifton%2CVA", '$map->url');

$visible->addLocation("Arlington,VA");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&visible=Washington%2CDC%7CClifton%2CVA%7CArlington%2CVA", '$map->url');

$visible->addLocation("38.846272,-77.306607"); #Fairfax, VA

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&visible=Washington%2CDC%7CClifton%2CVA%7CArlington%2CVA%7C38.846272%2C-77.306607", '$map->url');

$visible->addLocation([38.901564,-77.265220]); #Vienna, VA

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&visible=Washington%2CDC%7CClifton%2CVA%7CArlington%2CVA%7C38.846272%2C-77.306607%7C38.901564%2C-77.265220", '$map->url');

$visible->addLocation({lat=>38.882233,lon=>-77.171077}); #Falls Church, VA

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&visible=Washington%2CDC%7CClifton%2CVA%7CArlington%2CVA%7C38.846272%2C-77.306607%7C38.901564%2C-77.265220%7C38.882233%2C-77.171077", '$map->url');
