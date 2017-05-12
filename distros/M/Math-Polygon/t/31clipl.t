#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 132;

use lib '../lib';
use Math::Polygon::Clip;

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
# p0 is a single point
#

my @p0 = ( [3,4] );

my @cp0a = polygon_line_clip [0,0, 8,8], @p0;
compare_clip(\@cp0a, [ \@p0 ],"single point inside");

my @cp0b = polygon_line_clip [0,0, 1,1], @p0;
compare_clip(\@cp0b, [ ], "single point outside");

#
# p1 is an octagon, with center .5,.5, sides of 1
#

my @p1 = ( [0,2], [1,2], [2,1], [2,0], [1,-1], [0,-1], [-1,0], [-1,1], [0,2]);

my @cp1a = polygon_line_clip [-4,-4, 4,4], @p1;
compare_clip(\@cp1a, [ \@p1 ], "whole outside");

my @cp1b = polygon_line_clip [0,0, 1,1], @p1;
compare_clip(\@cp1b, [ ], "whole inside");

my @cp1c = polygon_line_clip [0,0,3,3], @p1;
compare_clip(\@cp1c, [ [[0,2],[1,2],[2,1],[2,0]] ], "one piece");

my @cp1d = polygon_line_clip [-4,-0.5, 4,1.5], @p1;
compare_clip(\@cp1d, [ [[1.5,1.5],[2,1],[2,0],[1.5,-0.5]]
                     , [[-0.5,-0.5],[-1,0],[-1,1],[-0.5,1.5]]
                     ], "two pieces");

my @cp1e = polygon_line_clip [-4,-0.5, 4,1.5], reverse(@p1);
compare_clip(\@cp1e, [ [[-0.5,1.5],[-1,1],[-1,0],[-0.5,-0.5]]
                     , [[1.5,-0.5],[2,0],[2,1],[1.5,1.5]]
		     ], "two pieces reverse");

my @cp1f = polygon_line_clip [-0.5,-1, 1.5,4], @p1;
compare_clip(\@cp1f, [ [[-0.5,1.5],[0,2],[1,2],[1.5,1.5]]
                     , [[1.5,-0.5],[1,-1],[0,-1],[-0.5,-0.5]]
                     ], "two glued pieces");

my @cp1g = polygon_line_clip [-0.5,-4, 1.5,4], reverse(@p1);
compare_clip(\@cp1g, [ [[1.5,1.5],[1,2],[0,2],[-0.5,1.5]]
                     , [[-0.5,-0.5],[0,-1],[1,-1],[1.5,-0.5]]
		     ], "two glued pieces reverse");

#
# p2 is a weird polygon
#

my @p2 = ( [0,1], [4,2], [3,1], [3,0], [2,1], [0,-3], [0,1] );
my @cp2a = polygon_line_clip [1.5,0.5, 3.5,2], @p2;

compare_clip(\@cp2a, [ [[1.5,1.375],[3.5,1.875]]
                     , [[3.5,1.5],[3,1],[3,0.5]]
		     , [[2.5,0.5],[2,1],[1.75,0.5]]
		     ], "complex cut");
