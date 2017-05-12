#!perl -T

use strict;
BEGIN { $^W = 1 }

use Test::More 'no_plan';

use Geo::Coordinates::RDNAP qw/dms deg/;

my ($d, $m, $s) = dms(52.555);
is($d, 52, "Degrees");
is($m, 33, "Minutes");
is(0+sprintf("%.5f",$s),18,"Seconds");

my ($a, $b, $c, $x, $y, $z) = dms(52.555, 6.3456);
is($x, 6, "Degrees");
is($y, 20, "Minutes");
is(0+sprintf("%.5f",$z),44.16,"Seconds");

my ($d1, $d2) = deg(52, 33, 18, 6, 20, 44.16);
cmp_ok(abs($d1 - 52.555),'<',1e6,"d1");
cmp_ok(abs($d2 - 6.3456),'<',1e6,"d2");

# Scalar
my $d3 = deg(52, 33, 18);
cmp_ok(abs($d3 - 52.555),'<',1e6,"d3 (scalar)");
