#!/usr/bin/env perl
# test ::Convex::chainHull_2D;

use strict;
use warnings;

use Test::More tests => 2;

use Math::Polygon::Convex qw/chainHull_2D/;
use Math::Polygon;

# Correct results according to Jari Turkia
my @q = ( [9,7], [-1,1], [-6,7], [-8,7], [8,-7], [-3,2]
        , [1,-5], [-10,3], [7,-8], [-10,8]);

my $p = chainHull_2D @q;
isa_ok($p, 'Math::Polygon');
is($p->string, "[-10,3], [1,-5], [7,-8], [8,-7], [9,7], [-10,8], [-10,3]");

