#!perl

use strict;
use warnings;

use HTML::GoogleMaps::V3;

my $map = HTML::GoogleMaps::V3->new( key => 'foo' );
$map->center("1210 W Dayton St, Madison, WI");
$map->add_marker(point => "1210 W Dayton St, Madison, WI");
$map->add_marker(point => [ 51, 0 ] );   # Greenwich

my ($head, $map_div) = $map->onload_render;

print "<html><head><title>FSBO Open Houses</title>$head</head>";
print "<body onload=\"html_googlemaps_initialize()\">$map_div</body></html>";
