# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new(_signer=>"");

my $path=$map->path(locations=>["Washington,DC", "Alexandria,VA", "Clifton,VA", "Vienna,VA", "Washington,DC"]);

isa_ok ($path, 'Geo::Google::StaticMaps::V2::Path');

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=Washington%2CDC%7CAlexandria%2CVA%7CClifton%2CVA%7CVienna%2CVA%7CWashington%2CDC", '$map->url');

$path->fillcolor("blue");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=fillcolor%3Ablue%7CWashington%2CDC%7CAlexandria%2CVA%7CClifton%2CVA%7CVienna%2CVA%7CWashington%2CDC", '$map->url');

my $path2=$map->path(color=>"red", fillcolor=>"red", locations=>["Clifton,VA", "Vienna,VA", "Chantilly,VA", "Clifton,VA"]);

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=fillcolor%3Ablue%7CWashington%2CDC%7CAlexandria%2CVA%7CClifton%2CVA%7CVienna%2CVA%7CWashington%2CDC&path=color%3Ared%7Cfillcolor%3Ared%7CClifton%2CVA%7CVienna%2CVA%7CChantilly%2CVA%7CClifton%2CVA", '$map->url');
