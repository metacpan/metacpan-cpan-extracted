#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 68;

use lib '../lib';
use Math::Polygon::Clip;

# crossing square (-1,-1)(2,2)
# name p[0-9]a is in the reverse direction of p[0-9]b
my $bb0 = [-1,-1,2,2];

# west
my @p0a = Math::Polygon::Clip::_cross_x(-1, [-2,1], [1,1]);
cmp_ok(@p0a, '==', 1);
cmp_ok($p0a[0][0], '==', -1);
cmp_ok($p0a[0][1], '==', 1);

my @p0b = Math::Polygon::Clip::_cross_x(-1, [1,1], [-2,1]);
cmp_ok(@p0b, '==', 1);
cmp_ok($p0b[0][0], '==', -1);
cmp_ok($p0b[0][1], '==', 1);

# north
my @p1a = Math::Polygon::Clip::_cross_y(2, [1,1], [1,3]);
cmp_ok(@p1a, '==', 1);
cmp_ok($p1a[0][0], '==', 1);
cmp_ok($p1a[0][1], '==', 2);

my @p1b = Math::Polygon::Clip::_cross_y(2, [1,3], [1,1]);
cmp_ok(@p1b, '==', 1);
cmp_ok($p1b[0][0], '==', 1);
cmp_ok($p1b[0][1], '==', 2);

# east
my @p2a = Math::Polygon::Clip::_cross_x(2, [1,0], [3,0]);
cmp_ok(@p2a, '==', 1);
cmp_ok($p2a[0][0], '==', 2);
cmp_ok($p2a[0][1], '==', 0);

my @p2b = Math::Polygon::Clip::_cross_x(2, [3,0], [1,0]);
cmp_ok(@p2b, '==', 1);
cmp_ok($p2b[0][0], '==', 2);
cmp_ok($p2b[0][1], '==', 0);

# south
my @p3a = Math::Polygon::Clip::_cross_y(-1, [1,0], [1,-2]);
cmp_ok(@p3a, '==', 1);
cmp_ok($p3a[0][0], '==', 1);
cmp_ok($p3a[0][1], '==', -1);

my @p3b = Math::Polygon::Clip::_cross_y(-1, [1,0], [1,-2]);
cmp_ok(@p3b, '==', 1);
cmp_ok($p3b[0][0], '==', 1);
cmp_ok($p3b[0][1], '==', -1);

# via _cross

my @p4a = Math::Polygon::Clip::_cross($bb0, [-2,1], [1,1]);
cmp_ok(@p4a, '==', 1);
cmp_ok($p4a[0][0], '==', -1);
cmp_ok($p4a[0][1], '==', 1);

my @p4b = Math::Polygon::Clip::_cross($bb0, [1,1], [-2,1]);
cmp_ok(@p4b, '==', 1);
cmp_ok($p4b[0][0], '==', -1);
cmp_ok($p4b[0][1], '==', 1);

#
# Cross 2 at once
#

# west-east
my @p5a = Math::Polygon::Clip::_cross($bb0, [-2,1], [3,1]);
cmp_ok(@p5a, '==', 2);
cmp_ok($p5a[0][0], '==', -1);
cmp_ok($p5a[0][1], '==', 1);
cmp_ok($p5a[1][0], '==', 2);
cmp_ok($p5a[1][1], '==', 1);

# east-west
my @p5b = Math::Polygon::Clip::_cross($bb0, [3,1], [-2,1]);
cmp_ok(@p5b, '==', 2);
cmp_ok($p5b[0][0], '==', 2);
cmp_ok($p5b[0][1], '==', 1);
cmp_ok($p5b[1][0], '==', -1);
cmp_ok($p5b[1][1], '==', 1);

# north-south
my @p6a = Math::Polygon::Clip::_cross($bb0, [-1,5], [2,-4]);
cmp_ok(@p6a, '==', 2);
cmp_ok($p6a[0][0], '==', 0);
cmp_ok($p6a[0][1], '==', 2);
cmp_ok($p6a[1][0], '==', 1);
cmp_ok($p6a[1][1], '==', -1);

# south-north
my @p6b = Math::Polygon::Clip::_cross($bb0, [2,-4], [-1,5]);
cmp_ok(@p6b, '==', 2);
cmp_ok($p6b[0][0], '==', 1);
cmp_ok($p6b[0][1], '==', -1);
cmp_ok($p6b[1][0], '==', 0);
cmp_ok($p6b[1][1], '==', 2);

# west-south
my @p7a = Math::Polygon::Clip::_cross($bb0, [-2,3], [8,-2]);
cmp_ok(@p7a, '==', 4);
cmp_ok($p7a[0][0], '==', -1);
cmp_ok($p7a[0][1], '==', 2.5);
cmp_ok($p7a[1][0], '==', 0);
cmp_ok($p7a[1][1], '==', 2);
cmp_ok($p7a[2][0], '==', 2);
cmp_ok($p7a[2][1], '==', 1);
cmp_ok($p7a[3][0], '==', 6);
cmp_ok($p7a[3][1], '==', -1);

# south-west
my @p7b = Math::Polygon::Clip::_cross($bb0, [8,-2], [-2,3]);
cmp_ok(@p7b, '==', 4);
cmp_ok($p7b[0][0], '==', 6);
cmp_ok($p7b[0][1], '==', -1);
cmp_ok($p7b[1][0], '==', 2);
cmp_ok($p7b[1][1], '==', 1);
cmp_ok($p7b[2][0], '==', 0);
cmp_ok($p7b[2][1], '==', 2);
cmp_ok($p7b[3][0], '==', -1);
cmp_ok($p7b[3][1], '==', 2.5);

