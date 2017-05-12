#!/usr/bin/perl

use Test::More tests => 29;

BEGIN {
    if (-f 'dont_use_xs' or -f 't/dont_use_xs') {
	$Math::Vector::Real::dont_use_XS = 1;
	diag "XS backend dissabled";
    }
}
use Math::Vector::Real;

my $PI = 3.14159_26535_89793_23846_26433_83279;

my $u = V(1, 0, 0);
my $v = V(0, 1, 0);
my $w = V(0, 0, 1);
my $r = V(1, 1, 1);

is (abs($_), 1) for ($u, $v, $w);
ok (abs(abs($u + $w) - sqrt(2)) < 0.0001);
ok (abs(cos(atan2($u, $v)))     < 0.0001);
ok ($u + $v == [1, 1, 0]);
ok ($u + $w != [1, 1, 1]);
ok ($u - $v == [1, -1, 0]);
ok (-$v - $w * 2 == [0, -1, -2]);
ok (-2 * $v - $w == [0, -2, -1]);
is ($u * $v, 0);
is (($u + $v) * $v, 1);
ok ($u x $v == $w);

ok (abs($u->rotate_3d($PI/2, $v) - $w)    < 0.0001);
ok (abs($v->rotate_3d($PI/2, $w) - $u)    < 0.0001);
ok (abs($w->rotate_3d($PI/2, $v) - (-$u)) < 0.0001);

my ($b1, $b2, $b3) = $r->rotation_base_3d;
ok (abs($b1 * $r * $b1 - $r) < 0.0001);
ok (abs($b1 x $b2 - $b3)     < 0.0001);

my $x = V(2,3,4);
ok ($x x $x              == [   0,    0,   0]);
ok ($x x [  1,   0,   0] == [   0,    4,  -3]);
ok ($x x [  1,   1,   0] == [  -4,    4,  -1]);
ok ($x x [ -4,   4,  -1] == [ -19,  -14,  20]);
ok ($x x [-19, -14,  20] == [ 116, -116,  29]);

ok ([  1,   0,   0] x $x == [   0,   -4,   3]);
ok ([  1,   1,   0] x $x == [   4,   -4,   1]);
ok ([ -4,   4,  -1] x $x == [  19,   14, -20]);
ok ([-19, -14,  20] x $x == [-116,  116, -29]);

ok ($x / 2 == [1, 1.5, 2]);
my $y = V(@$x);
$y /= 2;
ok ($y == [1, 1.5, 2]);
