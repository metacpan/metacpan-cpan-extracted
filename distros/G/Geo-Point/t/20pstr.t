#!/usr/bin/perl -T
#
# Test parsing of points, a combination of two strings
# (Geo::Point->fromString)
#

use strict;
use warnings;

use lib qw(. .. lib tests);

use Test::More tests => 107;

use Geo::Point;

my $pkg = 'Geo::Point';

# Prepare

sub check($$$$)
{   my ($string, $proj, $one, $two) = @_;

    my $point = $pkg->fromString($string);
    isa_ok($point, $pkg);
    is($point->proj, $proj);
    cmp_ok($point->x, '==', $one);
    cmp_ok($point->y, '==', $two);
}

my $w = Geo::Proj->projection('wgs84');
ok($w);

my $u = Geo::Proj->new(nick => 'utm31-wgs84'
  , proj4 => "+proj=utm +zone=31 +datum=WGS84");
ok($u);

### lat long

check("wgs84 2d30' 5d3",  'wgs84', 5.05, 2.5);
check("wgs84 2d30'N 5d3", 'wgs84', 5.05, 2.5);
check("wgs84 5d3 2d30'N", 'wgs84', 5.05, 2.5);
check("wgs84 2d30' 5d3E", 'wgs84', 5.05, 2.5);
check("wgs84 5d3E 2d30'", 'wgs84', 5.05, 2.5);
check("wgs84 2d30' 5d3e", 'wgs84', 5.05, 2.5);
check("wgs84 5d3e 2d30'", 'wgs84', 5.05, 2.5);

check("wgs84 N2d30' 5d3", 'wgs84', 5.05, 2.5);
check("wgs84 5d3 N2d30'", 'wgs84', 5.05, 2.5);
check("wgs84 2d30' E5d3", 'wgs84', 5.05, 2.5);
check("wgs84 E5d3 2d30'", 'wgs84', 5.05, 2.5);
check("wgs84 2d30' e5d3", 'wgs84', 5.05, 2.5);
check("wgs84 e5d3 2d30'", 'wgs84', 5.05, 2.5);

check("wgs84: 2d30' 5d3e", 'wgs84', 5.05, 2.5);
check("wgs84: 5d3e 2d30'", 'wgs84', 5.05, 2.5);

check("wgs84: 2d30', 5d3e", 'wgs84', 5.05, 2.5);
check("wgs84: 5d3e, 2d30'", 'wgs84', 5.05, 2.5);

check("wgs84, 2d30', 5d3e", 'wgs84', 5.05, 2.5);
check("wgs84, 5d3e, 2d30'", 'wgs84', 5.05, 2.5);

is(Geo::Proj->defaultProjection, 'wgs84');

check("2d30', 5d3e", 'wgs84', 5.05, 2.5);
check("5d3e, 2d30'", 'wgs84', 5.05, 2.5);

## utm

check("utm: 31 12.34 5.678",   'utm31-wgs84', 12.34, 5.678);
check("utm: 31,12.34,5.678",   'utm31-wgs84', 12.34, 5.678);
check("utm: 31, 12.34, 5.678", 'utm31-wgs84', 12.34, 5.678);
check("utm, 31, 12.34, 5.678", 'utm31-wgs84', 12.34, 5.678);
check("utm 31 12.34 5.678",    'utm31-wgs84', 12.34, 5.678);

