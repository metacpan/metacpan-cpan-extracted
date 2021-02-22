#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 81;

use Math::AnyNum qw(:overload);

my $m = 5;
my $x = (100->factorial + $m);
my $y = 23;

is($x % $y,   $m);
is(-$x % -$y, -$m);
is($x % -$y,  $m - $y);
is(-$x % $y,  $y - $m);

is($x % "$y",   $m);
is(-$x % "-$y", -$m);
is($x % "-$y",  $m - $y);
is(-$x % "$y",  $y - $m);

is("$x" % $y,   $m);
is("-$x" % -$y, -$m);
is("$x" % -$y,  $m - $y);
is("-$x" % $y,  $y - $m);

my $f1 = 399.8;
my $f2 = 41.2;

is(($f1 % $f2),   29);
is((-$f1 % -$f2), -29);
is(($f1 % -$f2),  -12.2);
is((-$f1 % $f2),  12.2);

is(($f1 % "$f2"),   29);
is((-$f1 % "-$f2"), -29);
is(($f1 % "-$f2"),  -12.2);
is((-$f1 % "$f2"),  12.2);

is(("$f1" % $f2),   29);
is(("-$f1" % -$f2), -29);
is(("$f1" % -$f2),  -12.2);
is(("-$f1" % $f2),  12.2);

is($f1 % "43",  12.8);
is($f1 % "-43", -30.2);

#is($x % Inf,      $x);
#is("$x" % Inf,    $x);
is(-$x % Inf,   NaN);    # should be Inf?
is("-$x" % Inf, NaN);    # =//=
is($x % -Inf,   NaN);    # should be -Inf?
is("$x" % -Inf, NaN);    # =//=

#is(-$x % -Inf,    -$x);
#is("-$x" % -Inf,  -$x);
is(Inf % $x,      NaN);
is(-Inf % $x,     NaN);
is(Inf % Inf,     NaN);
is(-Inf % Inf,    NaN);
is(-Inf % -Inf,   NaN);
is(Inf % NaN,     NaN);
is(-Inf % NaN,    NaN);
is(NaN % Inf,     NaN);
is($x % 0,        NaN);
is(-$y % 0,       NaN);
is($y % "0",      NaN);
is(-$x % "0.000", NaN);

# Integer
my $r = $x;
$r %= $y;
is($r, $m);

$r = -$x;
$r %= -$y;
is($r, -$m);

$r = $x;
$r %= -$y;
is($r, $m - $y);

$r = -$x;
$r %= $y;
is($r, $y - $m);

$r = $x;
$r %= "$y";
is($r, $m);

$r = -$x;
$r %= "-$y";
is($r, -$m);

$r = $x;
$r %= "-$y";
is($r, $m - $y);

$r = -$x;
$r %= "$y";
is($r, $y - $m);

# Float
$r = $f1;
$r %= $f2;
is($r->round(0), 29);

$r = -$f1;
$r %= -$f2;
is($r->round(0), -29);

$r = $f1;
$r %= -$f2;
is($r->round(-1), -12.2);

$r = -$f1;
$r %= $f2;
is($r->round(-1), 12.2);

$r = $f1;
$r %= "$f2";
is($r->round(0), 29);

$r = -$f1;
$r %= "-$f2";
is($r->round(0), -29);

$r = $f1;
$r %= "-$f2";
is($r->round(-1), -12.2);

$r = -$f1;
$r %= "$f2";
is($r->round(-1), 12.2);

# Extreme
$r = $x;
$r %= 0;
is($r, NaN);

$r = -$x;
$r %= 0;
is($r, NaN);

$r = $x;
$r %= "0";
is("$r", NaN);

$r = -$x;
$r %= "0.000";
is("$r", NaN);

my $c1 = Math::AnyNum->new('4/3');
my $c2 = Math::AnyNum->new('5/7');

is($c1 % "-12", "NaN");

is(($c2 * 1234) % "42",   "NaN");
is(($c2 * 1234) % 43,     "3");
is((-$c2 * 1234) % "-43", "40");
is(($c2 * 1234) % -43,    "3");
is((-$c2 * 1234) % 43,    "40");

is($c1 % 0,     "NaN");
is($c2 % "0",   "NaN");
is($c2 % "0/0", "NaN");
is($c2 % "abc", "NaN");

is((1234 * $c1) % Math::AnyNum->new_z('43'), '40');
like((1234 * $c1) % Math::AnyNum->new_f('43'), qr/^11\.3333333333333333\d*\z/);
like((1234 * $c1) % Math::AnyNum->new_c('43'), qr/^11\.3333333333333333\d*\z/);

#is(Math::AnyNum->new_c('123.5', '4') % Math::AnyNum->new_c('5.6', '2.5'), '-2.9+1.3i');
#is(Math::AnyNum->new_c('123.5', '4') % Math::AnyNum->new_c('2.3'), '-0.7-0.6i');
#is(Math::AnyNum->new_f('123.5') % Math::AnyNum->new_c('2.3', '4.7'), '1.8+1.3i');

is(Math::AnyNum->new_c('123.5') % Math::AnyNum->new_c('2.3'),   '1.6');
is(Math::AnyNum->new_c('-123.5') % Math::AnyNum->new_c('-2.3'), '-1.6');
is(Math::AnyNum->new_c('123.5') % Math::AnyNum->new_c('-2.3'),  '-0.7');
is(Math::AnyNum->new_c('-123.5') % Math::AnyNum->new_c('2.3'),  '0.7');

is(Math::AnyNum->new_c('-123.5') % "43",  '5.5');
is(Math::AnyNum->new_c('-123.5') % "-43", '-37.5');
