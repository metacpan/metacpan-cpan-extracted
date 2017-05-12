# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new(_signer=>"");

my $path=$map->path(locations=>["Clifton,VA", "Pag,Croatia"]);

isa_ok ($path, 'Geo::Google::StaticMaps::V2::Path');

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=Clifton%2CVA%7CPag%2CCroatia", '$map->url');

$path->geodesic(1);

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&path=geodesic%3Atrue%7CClifton%2CVA%7CPag%2CCroatia", '$map->url');
