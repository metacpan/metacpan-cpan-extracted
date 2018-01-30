#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Geo::Coordinates::MGRS::XS', ':all') };

our $delta = 0.00001;

my ($z, $h, $e, $n) = mgrs_to_utm("32VNN1010");
ok($z == 32, "zone ok!");
ok($e == 510000, "easting ok!");
ok($n == 6710000, "northing ok!");
ok($h eq "N", "hemisphere ok!");

my ($lat, $lon) = mgrs_to_latlon("32VNN1010");
ok($lat - 60.5259390 < $delta, "latitude within margin of error");
ok($lon - 9.1821827 < $delta, "longitude within margin of error");

my $mgrs;
$mgrs = latlon_to_mgrs(60.5259390, 9.1821827, 2);
ok($mgrs eq "32VNN1010", "lat/lon to mgrs, precision 2");
$mgrs = latlon_to_mgrs(60.5259390, 9.1821827, 5);
ok($mgrs eq "32VNN1000010000", "lat/lon to mgrs, precision 5");

$mgrs = "34VFD0350049500";
mgrs_to_utm($mgrs);

ok(1);
