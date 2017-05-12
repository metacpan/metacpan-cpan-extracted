#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 1;

use Geo::WKT qw/wkt_multilinestring/;
use Geo::Point;

#### Create

my @line1 = ([1,2], [3,4]);

my $gp1 = Geo::Point->xy(5,6);
my $gp2 = Geo::Point->xy(7,8);
my $gp3 = Geo::Point->xy(12,2);
my @line2 = ($gp1, $gp2, $gp3);

is(wkt_multilinestring(\@line1, \@line2)
  ,'MULTILINESTRING(LINESTRING(1 2,3 4),LINESTRING(5 6,7 8,12 2))');
