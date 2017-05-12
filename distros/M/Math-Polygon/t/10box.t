#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use lib '../lib';
use Math::Polygon::Calc;

sub compare_box($$)
{   my ($a, $b) = @_;
#warn "[@$a] == [@$b]\n";

       $a->[0] == $b->[0]
    && $a->[1] == $b->[1]
    && $a->[2] == $b->[2]
    && $a->[3] == $b->[3]
}

my @bb1 = polygon_bbox [3,4];
ok(compare_box(\@bb1, [3,4,3,4]));

my @bb2 = polygon_bbox [0,2], [1,2], [2,1], [2,0], [1,-1]
                      , [0,-1], [-1,0], [-1,1], [0,2];

ok(compare_box(\@bb2, [-1,-1, 2,2]));
