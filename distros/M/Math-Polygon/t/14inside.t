#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 19;

use lib '../lib';
use Math::Polygon::Calc;

my @p = ([0,0], [1,1], [-2,1], [-2,-2], [-1,-1], [0,-2], [1,-1], [0,0]);

ok( polygon_contains_point([-1,0], @p), '(-1,0)');
ok( polygon_contains_point([0,-1], @p), '(0,-1)');

ok(!polygon_contains_point([10,10], @p), '(10,10)');
ok(!polygon_contains_point([1,0], @p), '(1,0)');
ok(!polygon_contains_point([-1,-1.5], @p), '(-1,-1.5)');

# On the edge
ok( polygon_contains_point([0,0], @p), '(0,0)');
ok( polygon_contains_point([-1,-1], @p), '(-1,-1)');


@p = ([1,1],[1,3],[4,3],[4,1],[1,1]);

ok( polygon_contains_point([3,1], @p), '2nd (3,1)');  # on vertical edge

ok( polygon_contains_point([1,1], @p), '2nd (1,1)');
ok( polygon_contains_point([1,3], @p), '2nd (1,3)');
ok( polygon_contains_point([4,3], @p), '2nd (4,3)');
ok( polygon_contains_point([4,1], @p), '2nd (4,1)');

# rt.cpan.org#118030  On edge
@p = ([400, 0], [500, 0], [600, 100], [600, 900], [500, 1000],
      [400, 1000], [400, 0]);
ok( polygon_contains_point([400, 400], @p), 'on edge 1');
ok( polygon_contains_point([550,  50], @p), 'on edge 2');
ok( polygon_contains_point([551,  51], @p), 'on edge 2b');
ok( polygon_contains_point([552,  52], @p), 'on edge 2c');
ok( polygon_contains_point([550, 950], @p), 'on edge 3');
ok( polygon_contains_point([600, 300], @p), 'on edge 4');
ok( polygon_contains_point([450,1000], @p), 'on edge 5');

