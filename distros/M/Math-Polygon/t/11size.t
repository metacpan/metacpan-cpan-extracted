#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 11;

use lib '../lib';
use Math::Polygon::Calc;

my @p0 = ( [3,4] );
cmp_ok(polygon_area(@p0), '==', 0);
ok(!polygon_is_clockwise @p0);
ok(!polygon_is_clockwise reverse @p0);

my @p1 = ( [0,2], [1,2], [2,1], [2,0], [1,-1], [0,-1], [-1,0], [-1,1], [0,2]);
cmp_ok(polygon_area(@p1), '==', 7);
cmp_ok(polygon_area(reverse @p1), '==', 7);
ok(polygon_is_clockwise(@p1));
ok(!polygon_is_clockwise(reverse @p1));

my @p2 = ( [0,1], [3,2], [3,1], [2,0], [1,1], [0,-2], [0,1] );
cmp_ok(polygon_area(@p2), '==', 4);
cmp_ok(polygon_area(@p2), '==', 4);
ok(polygon_is_clockwise(@p2));
ok(!polygon_is_clockwise(reverse @p2));

