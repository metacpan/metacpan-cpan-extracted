#!/usr/bin/env perl
# Distance from point to closest point on polygon

use strict;
use warnings;

use Test::More tests => 15;

use lib '../lib';
use Math::Polygon::Calc;

my @p = ([1,1], [3,1], [3,3], [1,3], [1,1]);

is( polygon_distance([1,1], @p), 0);
is( polygon_distance([1,0], @p), 1);
is( polygon_distance([0,1], @p), 1);
is( polygon_distance([2,0], @p), 1);
is( polygon_distance([2,2], @p), 1);
is( polygon_distance([0,2], @p), 1);
is( polygon_distance([3,0], @p), 1);
is( polygon_distance([0,3], @p), 1);
is( polygon_distance([0,0], @p), polygon_distance([4,4], @p));
is( polygon_distance([4,0], @p), polygon_distance([0,4], @p));

@p = ([6,2],[7,1],[8,2],[7,3],[6,2]);

is( polygon_distance([5,1], @p), polygon_distance([5,3], @p));
is( polygon_distance([6,0], @p), polygon_distance([6,4], @p));
is( polygon_distance([7,2], @p), polygon_distance([8,3], @p));

# single points

is( polygon_distance([1,1], [4,5]), 5 );

# empty poly

ok( !defined polygon_distance([1,1]) );
