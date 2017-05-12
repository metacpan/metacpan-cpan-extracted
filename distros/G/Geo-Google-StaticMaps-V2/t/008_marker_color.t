# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 8;

BEGIN { use_ok( 'Geo::Google::StaticMaps::V2' ); }

my $map=Geo::Google::StaticMaps::V2->new(_signer=>"");

my $marker=$map->marker(location=>"Washington,DC");

isa_ok($marker, "Geo::Google::StaticMaps::V2::Markers");

is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=Washington%2CDC", '$map->url simple example');

$marker->color("blue");
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3Ablue%7CWashington%2CDC", '$map->url simple example');

$marker->color("0x0000FF");
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3A0x0000FF%7CWashington%2CDC", '$map->url simple example');

$marker->color([0,0,255]);
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3A0x0000FF%7CWashington%2CDC", '$map->url simple example');

$marker->color({r=>0,g=>0,b=>255});
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3A0x0000FF%7CWashington%2CDC", '$map->url simple example');

$marker->color({r=>0,g=>0,b=>255,a=>255}); #should not set alpha
is($map->url, "http://maps.googleapis.com/maps/api/staticmap?size=600x400&sensor=false&markers=color%3A0x0000FF%7CWashington%2CDC", '$map->url simple example');
