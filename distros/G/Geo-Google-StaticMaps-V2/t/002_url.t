# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new(_signer=>"");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&center=Clifton%2C+VA&zoom=7", '$map->url');

is($map->width, 600);
is($map->width(700), 700);

is($map->height, 400);
is($map->height(500), 500);

