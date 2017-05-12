# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 11;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new(_signer=>"");

my $path=$map->path(locations=>["Clifton,VA", "Vienna,VA"]);

isa_ok ($path, 'Geo::Google::StaticMaps::V2::Path');

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=Clifton%2CVA%7CVienna%2CVA", '$map->url path only');

$path->color("red");
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3Ared%7CClifton%2CVA%7CVienna%2CVA", '$map->url red');

$path->color("0xFF0000");
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3A0xFF0000%7CClifton%2CVA%7CVienna%2CVA", '$map->url 0xFF0000');

$path->color("0xFF000019");
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3A0xFF000019%7CClifton%2CVA%7CVienna%2CVA", '$map->url 0xFF000019');

$path->color([255,0,0,25]);
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3A0xFF000019%7CClifton%2CVA%7CVienna%2CVA", '$map->url [255,0,0,25]');

$path->color([255,0,0,"10%"]);
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3A0xFF000019%7CClifton%2CVA%7CVienna%2CVA", '$map->url [255,0,0,"10%"]');

$path->color({r=>255});
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3A0xFF0000%7CClifton%2CVA%7CVienna%2CVA", '$map->url {r=>255}');

$path->color({r=>255, a=>25});
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3A0xFF000019%7CClifton%2CVA%7CVienna%2CVA", '$map->url {r=>255, a=>25}');

$path->color({r=>255, a=>"10%"});
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=color%3A0xFF000019%7CClifton%2CVA%7CVienna%2CVA", '$map->url {r=>255, a=>"10%"}');

