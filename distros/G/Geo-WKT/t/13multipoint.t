#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 3;

use Geo::WKT qw/wkt_multipoint/;
use Geo::Point;

#### Create

is(wkt_multipoint([1,2], [3,4])
  ,'MULTIPOINT(POINT(1 2),POINT(3 4))', 'by array');

my $gp1 = Geo::Point->xy(5,6);
my $gp2 = Geo::Point->xy(7,8);
my $gp3 = Geo::Point->xy(12,2);

is(wkt_multipoint($gp1),'MULTIPOINT(POINT(5 6))', 'one Geo::Point');
is(wkt_multipoint($gp1,$gp2,$gp3,$gp1),
   'MULTIPOINT(POINT(5 6),POINT(7 8),POINT(12 2),POINT(5 6))', '4 Geo::Points');

