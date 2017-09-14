#!/usr/bin/perl
use warnings;
use strict;

use Test::Simple tests => 1;

use Geo::Coordinates::Converter::LV03 qw(lat_lng_2_y_x  y_x_2_lat_lng);

my ($dummy1, $dummy2) = lat_lng_2_y_x(     47,      8);
   ($dummy1, $dummy2) = y_x_2_lat_lng($dummy1, $dummy2);

ok(1);
