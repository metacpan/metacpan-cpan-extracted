#!/usr/bin/perl -T
#
# Test parsing of bboxes into rings
# (Geo::Line->ringFromString)
#

use strict;
use warnings;

use lib qw(. lib .. tests ../MathPolygon/lib ../../MathPolygon/lib);

use Test::More tests => 24;

use Geo::Point;

my $pkg = 'Geo::Line';

# Prepare

my $ring = $pkg->ringFromString("wgs84: e2d12'-3d, n1, n7d0'36");
my ($xmin, $ymin, $xmax, $ymax, $proj) = (2.2, 1, 3, 7.01, 'wgs84');

ok(defined $ring,              'ring created');
isa_ok($ring, $pkg);
ok($ring->isRing);

my @p = $ring->points;
cmp_ok(scalar(@p), '==', 5);

for my $p (@p)
{   is(ref $p, 'ARRAY');
    cmp_ok(scalar(@$p), '==', 2);
}

cmp_ok($p[0][0], '==', $xmin);
cmp_ok($p[0][1], '==', $ymin);
cmp_ok($p[1][0], '==', $xmax);
cmp_ok($p[1][1], '==', $ymin);
cmp_ok($p[2][0], '==', $xmax);
cmp_ok($p[2][1], '==', $ymax);
cmp_ok($p[3][0], '==', $xmin);
cmp_ok($p[3][1], '==', $ymax);
cmp_ok($p[4][0], '==', $xmin);
cmp_ok($p[4][1], '==', $ymin);
