#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 24;

use lib '../lib', 'lib';
use Math::Polygon::Calc;

sub compare_poly($$$)
{   my ($got, $want, $text) = @_;

    cmp_ok(scalar(@$got), '==', scalar(@$want), "nr points, $text");
    return unless @$want;

    my $gotp  = polygon_string polygon_start_minxy @$got;
    my $wantp = polygon_string polygon_start_minxy @$want;

    is($gotp, $wantp);
}

#
# p0 is a single point, not a poly
#

my @p0   = ( [3,4] );
my @cp0a = polygon_beautify @p0;
compare_poly(\@cp0a, [], "single point");

#
# p1 is a line, also not a poly
#

my @p1   = ([1,2],[3,5],[1,2]);
my @cp1a = polygon_beautify @p1;
compare_poly(\@cp1a, [], "line");

#
# p2 is a triangle
#

my @p2   = ( [0,0],[1,2],[2,0],[0,0] );
my @cp2a = polygon_beautify @p2;
compare_poly(\@cp2a, \@p2, "triangle");

#
# p3 is traingle p2 with x-spike
#

my @p3   = ( [0,0],[1,2],[3,2],[1,2],[2,0],[0,0] );
my @cp3a = polygon_beautify @p3;
compare_poly(\@cp3a, \@p3, "triangle with spike, no despike");

my @cp3b = polygon_beautify {remove_spikes => 1}, @p3;
compare_poly(\@cp3b, \@p2, "triangle with spike");

#
# p4 is traingle p2 with y-spike
#

my @p4   = ( [0,0],[1,2],[1,4],[1,2],[2,0],[0,0] );
my @cp4a = polygon_beautify @p4;
compare_poly(\@cp4a, \@p4, "triangle with spike, no despike");

my @cp4b = polygon_beautify {remove_spikes => 1}, @p4;
compare_poly(\@cp4b, \@p2, "triangle with spike");

#
# p5 is traingle p2 with combined x+y-spike
#

my @p5   = ( [0,0],[1,2],[1,4],[3,4],[1,4],[1,2],[2,0],[0,0] );
my @cp5a = polygon_beautify @p5;
compare_poly(\@cp5a, \@p5, "triangle with spike, no despike");

my @cp5b = polygon_beautify {remove_spikes => 1}, @p5;
compare_poly(\@cp5b, \@p2, "triangle with spike");

#
# p6 is square c(2x2) with extra point at each side
#

my @c    = ( [0,0],[0,2],[2,2],[2,0],[0,0] );
my @p6   = ( [0,0],[0,1],[0,2],[1,2],[2,2],[2,1],[2,0],[1,0],[0,0] );
my @cp6a = polygon_beautify @p6;
compare_poly(\@cp6a, \@c, "square with extra points");

#
# p7 has multiple points at one side
#

my @p7   = ( [0,0],[0,0.5],[0,1],[0,1.5],[0,2],[2,2],[2,0],[0,0] );
my @cp7a = polygon_beautify @p7;
compare_poly(\@cp7a, \@c, "square with many superfluous points");

#
# p8 has multiple points mixed in a side
#

my @p8   = ( [0,0],[0,1.5],[0,1],[0,0.5],[0,2],[2,2],[2,0],[0,0] );
my @cp8a = polygon_beautify @p8;
compare_poly(\@cp8a, \@c, "square with mixed superfluous points");

#
# p9 contains loads of doubles
#

my @p9   = ( [0,0], [0,0], [0,0], [1,2],[1,2], [3,2],[3,2], [0,0] );
my @cp9a = polygon_beautify @p9;
compare_poly(\@cp9a, [[0,0],[1,2],[3,2],[0,0]], "doubles");

