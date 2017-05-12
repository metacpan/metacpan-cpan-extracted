#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use lib '../lib';
use Math::Polygon::Clip;
use Math::Polygon::Calc;

sub compare_clip($$$)
{   my ($got, $want, $text) = @_;

    cmp_ok(scalar(@$got), '==', scalar(@$want), "nr fragments, $text");
    for(my $i = 0; $i < @$got; $i++)
    {   my $g = $got->[$i];
        my $w = $want->[$i];
        cmp_ok(scalar(@$g), '==', scalar(@$w), "points in fragment $i");
	for(my $j=0; $j < @$g; $j++)
	{    cmp_ok($g->[$j][0], '==', $w->[$j][0], "X $i,$j");
	     cmp_ok($g->[$j][1], '==', $w->[$j][1], "Y $i,$j");
	}
    }
}

#
# p0 is square
#

my @p0 = ([1,1],[3,1],[3,3],[1,3],[1,1]);
my @q0 = polygon_fill_clip1 [0,0, 2,2], @p0;
cmp_ok(scalar(@q0),'==',5, 'overlapping squares');
is(polygon_string(@q0), '[1,1], [2,1], [2,2], [1,2], [1,1]');

my @q0b = polygon_fill_clip1 [0,0, 4,4], @p0;
is(polygon_string(@q0b), '[1,1], [3,1], [3,3], [1,3], [1,1]', 'take all');
