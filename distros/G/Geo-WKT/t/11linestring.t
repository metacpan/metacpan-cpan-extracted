#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 2;

use Geo::WKT qw/wkt_linestring/;
use Geo::Point;

is(wkt_linestring([1,2], [2,3], [3,2], [1, 2])
  , 'LINESTRING(1 2,2 3,3 2,1 2)', 'by array');

my $gp1 = Geo::Point->xy(6,7);
my $gp2 = Geo::Point->xy(8,9);
my $gp3 = Geo::Point->xy(6,9);
is(wkt_linestring($gp1, $gp2, $gp3)
  , 'LINESTRING(6 7,8 9,6 9)', 'by Geo::Points');
