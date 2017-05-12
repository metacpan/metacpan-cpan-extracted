#!/usr/bin/env perl
use lib '../lib';
use Math::Polygon::Calc 'polygon_centroid';
use warnings;
use strict;

use Test::More tests => 4;

sub compare_point($$)
{   my ($a, $b) = @_;

       $a->[0] == $b->[0]
    && $a->[1] == $b->[1]
}

my $centroid1 = polygon_centroid [0,0], [0,10], [10,10], [10,0], [0,0];
ok(compare_point($centroid1, [5,5]));

my $centroid2 = polygon_centroid [6,2], [12,2], [12,8], [6,2];
ok(compare_point($centroid2, [10,4]));

my $centroid3 = polygon_centroid [1,2], [7,2], [13,8], [1,2];
ok(compare_point($centroid3, [7,4]));

my $centroid4 = polygon_centroid [3,2], [10,2], [12,8], [5,8], [3,2];
ok(compare_point($centroid4, [7.5,5]));

