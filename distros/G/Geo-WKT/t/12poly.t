#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 10;

use Geo::WKT qw/parse_wkt_polygon wkt_polygon/;

#### Parse

my $p1 = parse_wkt_polygon "POLYGON((2.5 8, 3.5 6.7, 4.5 8))";
isa_ok($p1, 'Geo::Surface', 'parse polygon');
is($p1->toString, <<_OUT);
surface[wgs84]
  ([[2.5,8], [3.5,6.7], [4.5,8]])
_OUT

my $p2 = parse_wkt_polygon "POLYGON((1 2, 3 4, 5 6),(7 8, 9 10, 11 12))";
isa_ok($p2, 'Geo::Surface', 'parse polygon');
is($p2->toString, <<'__OUT');
surface[wgs84]
  ([[1,2], [3,4], [5,6]])
 -([[7,8], [9,10], [11,12]])
__OUT

#### Create

is(wkt_polygon([1,2], [3,4], [5,6]), "POLYGON((1 2,3 4,5 6))");

my $gp1 = Geo::Point->xy(7,8);
my $gp2 = Geo::Point->xy(9,10);
my $gp3 = Geo::Point->xy(11,12);
my $gp4 = Geo::Point->xy(13,14);

#list of Geo::Points for outer

#array of points for outer
is(wkt_polygon([[2,3],[4,5],[6,7]]), "POLYGON((2 3,4 5,6 7))");

#array with Geo::Points for outer
is(wkt_polygon([$gp1, $gp2, $gp3]), "POLYGON((7 8,9 10,11 12))");

my $outer = Geo::Line->new(points => [[16,17],[18,19]]);

is(wkt_polygon($outer), "POLYGON((16 17,18 19))");

my @inner1 = ($gp1, $gp2, $gp3);
my $inner3 = $outer;
is(wkt_polygon($outer, \@inner1, $inner3),
 "POLYGON((16 17,18 19),(7 8,9 10,11 12),(16 17,18 19))");

is(wkt_polygon([$gp1,$gp2],[$gp3,$gp4,$gp1]),
  "POLYGON((7 8,9 10),(11 12,13 14,7 8))");

