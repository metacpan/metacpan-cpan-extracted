#!/usr/bin/perl -T
#
# Test parsing of bboxes
# (Geo::Line->bboxFromString)
#

use strict;
use warnings;

use lib qw(. lib .. tests ../MathPolygon/lib ../../MathPolygon/lib);

use Test::More tests => 41;

use Geo::Point;
use Geo::Proj;

my $pkg = 'Geo::Line';

Geo::Proj->new(nick => 'wgs84', proj4 => '+proj=latlong +datum=WGS84');

# Prepare

sub check($$$$$$)
{   my ($string, $xmin, $ymin, $xmax, $ymax, $proj) = @_;
#warn "$string\n";

    my @b = $pkg->bboxFromString($string);
    cmp_ok(@b, '==', 5);
    cmp_ok($b[0], '==', $xmin);
    cmp_ok($b[1], '==', $ymin);
    cmp_ok($b[2], '==', $xmax);
    cmp_ok($b[3], '==', $ymax);
}

is(Geo::Proj->defaultProjection, 'wgs84');

check("5n 2n 3e e12",       3, 2, 12, 5, 'wgs84');
check("5n , 2n , 3e , e12", 3, 2, 12, 5, 'wgs84');
check("5n,2n,3e,e12",       3, 2, 12, 5, 'wgs84');
check("2.12-23.1E, N1-4",  2.12, 1, 23.1, 4, 'wgs84');
check("W2.12-23.1, 1-4S",  -23.1, -4, -2.12, -1, 'wgs84');
check("10N, 30E, 45N, 70E", 30, 10, 70, 45, 'wgs84');

check("wgs84: 2-5e, 1-8n", 2, 1, 5, 8, 'wgs84');
check("wgs84: e2d12'-3d, n1, n7d0'36", 2.2, 1, 3, 7.01, 'wgs84');
