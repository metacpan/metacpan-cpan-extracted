#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 8;

use Geo::WKT qw/parse_wkt_point wkt_point/;

#### Parse

my $p1 = parse_wkt_point "POINT(2.5 8)";
isa_ok($p1, 'Geo::Point', 'parse point');
is($p1->toString, 'point[wgs84](8.0000 2.5000)');

my $p2 = parse_wkt_point "POINT(3.5 6.7)", 'wgs84';
isa_ok($p2, 'Geo::Point', 'parse point with coordinate');
is($p2->toString, 'point[wgs84](6.7000 3.5000)');

#### Create

is(wkt_point(4.5, 8),     'POINT(4.5 8)', 'create from LIST');
is(wkt_point([5.5, 9.5]), 'POINT(5.5 9.5)', 'create from ARRAY');
is(wkt_point($p1),        'POINT(2.5 8)', 'create from Geo::Point p1');
is(wkt_point($p2),        'POINT(3.5 6.7)', 'create from Geo::Point p2');
