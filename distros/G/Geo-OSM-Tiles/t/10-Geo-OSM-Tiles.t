#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 74;
BEGIN { use_ok('Geo::OSM::Tiles', qw(:all)) };

# Simple tests of well known values.
{
    # 2..4
    my $zoom = 13;
    my $lat = 49.60055;
    my $lon = 11.01296;
    my $tilex = lon2tilex($lon, $zoom);
    is($tilex, 4346, "tile x at lon = $lon, zoom = $zoom");
    my $tiley = lat2tiley($lat, $zoom);
    is($tiley, 2792, "tile y at lat = $lat, zoom = $zoom");
    my $path = tile2path($tilex, $tiley, $zoom);
    is($path, '13/4346/2792.png', "path");
}

# Simple consistency test for zooming:
# tile numbers must get halved when zooming out one level.
{
    # 5..38
    # At this position we get all possible combinations of even and
    # odd tile numbers throughout the different zoom levels.
    my $lat = -33.84122;
    my $lon = 108.00000;
    my $zoom = 18;
    my $tilex = lon2tilex($lon, $zoom);
    my $tiley = lat2tiley($lat, $zoom);
    while ($zoom > 1) {
	my $otx = $tilex;
	my $oty = $tiley;
	$zoom--;
	$tilex = lon2tilex($lon, $zoom);
	is($tilex, int($otx / 2), "tile x at lon = $lon, zoom = $zoom");
	$tiley = lat2tiley($lat, $zoom);
	is($tiley, int($oty / 2), "tile y at lat = $lat, zoom = $zoom");
    }
}

# Check the bound checking in checklonrange and checklatrange.
{
    # 39..74
    # A range of coordinates that is out of bounds for sure.
    my @hugerange = (-1000.0, 1000.0);
    for my $zoom (0, 1, 2, 5, 10, 15, 18, 20, 30) {
	# 4 tests per zoom level
	my $max = 2**$zoom-1;

	my ($lonmin, $lonmax) = checklonrange(@hugerange);
	my ($xmin, $xmax) = map { lon2tilex($_, $zoom) } ($lonmin, $lonmax);
	is($xmin, 0, "\$xmin at zoom = $zoom");
	is($xmax, $max, "\$xmax at zoom = $zoom");

	# Note that lat2tiley is decreasing,
	# so $ymin = lat2tiley($latmax, $zoom).
	my ($latmin, $latmax) = checklatrange(@hugerange);
	my ($ymax, $ymin) = map { lat2tiley($_, $zoom) } ($latmin, $latmax);
	is($ymin, 0, "\$ymin at zoom = $zoom");
	is($ymax, $max, "\$ymax at zoom = $zoom");
    }
}

# Local Variables:
# mode: perl
# End:
