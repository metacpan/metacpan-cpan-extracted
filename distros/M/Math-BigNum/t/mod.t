#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 105;

use Math::BigNum qw(:constant);

my $m = 5;
my $x = (100->fac + $m);
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

# imod

is($x->imod($y),     $m);
is((-$x)->imod(-$y), -$m);
is($x->imod(-$y),    $m - $y);
is((-$x)->imod($y),  $y - $m);

is($x->imod("$y"),     $m);
is((-$x)->imod("-$y"), -$m);
is($x->imod("-$y"),    $m - $y);
is((-$x)->imod("$y"),  $y - $m);

# bimod

is($x->copy->bimod($y),  $m);
is((-$x)->bimod(-$y),    -$m);
is($x->copy->bimod(-$y), $m - $y);
is((-$x)->bimod($y),     $y - $m);

is($x->copy->bimod("$y"),  $m);
is((-$x)->bimod("-$y"),    -$m);
is($x->copy->bimod("-$y"), $m - $y);
is((-$x)->bimod("$y"),     $y - $m);

my $xcp = $x->copy;
$xcp->bimod($y);
is($xcp, $m);

$xcp = $x->copy;
$xcp->bimod("-$y");
is($xcp, $m - $y);

my $f1 = 399.8;
my $f2 = 41.2;

is(($f1 % $f2)->round(0),   29);
is((-$f1 % -$f2)->round(0), -29);
is(($f1 % -$f2)->round(-1), -12.2);
is((-$f1 % $f2)->round(-1), 12.2);

is(($f1 % "$f2")->round(0),   29);
is((-$f1 % "-$f2")->round(0), -29);
is(($f1 % "-$f2")->round(-1), -12.2);
is((-$f1 % "$f2")->round(-1), 12.2);

is(("$f1" % $f2)->round(0),   29);
is(("-$f1" % -$f2)->round(0), -29);
is(("$f1" % -$f2)->round(-1), -12.2);
is(("-$f1" % $f2)->round(-1), 12.2);

# fmod

is(($f1->fmod($f2))->round(0),     29);
is(((-$f1)->fmod(-$f2))->round(0), -29);
is(($f1->fmod(-$f2))->round(-1),   -12.2);
is(((-$f1)->fmod($f2))->round(-1), 12.2);

is(($f1->fmod("$f2"))->round(0),     29);
is(((-$f1)->fmod("-$f2"))->round(0), -29);
is(($f1->fmod("-$f2"))->round(-1),   -12.2);
is(((-$f1)->fmod("$f2"))->round(-1), 12.2);

# bfmod

is(($f1->copy->bfmod($f2))->round(0),   29);
is(((-$f1)->bfmod(-$f2))->round(0),     -29);
is(($f1->copy->bfmod(-$f2))->round(-1), -12.2);
is(((-$f1)->bfmod($f2))->round(-1),     12.2);

is(($f1->copy->bfmod("$f2"))->round(0),   29);
is(((-$f1)->bfmod("-$f2"))->round(0),     -29);
is(($f1->copy->bfmod("-$f2"))->round(-1), -12.2);
is(((-$f1)->bfmod("$f2"))->round(-1),     12.2);

my $f1cp = $f1->copy;
$f1cp->bfmod($f2)->bround(0);
is($f1cp, 29);

$f1cp = $f1->copy;
$f1cp->bfmod("-$f2")->bround(-1);
is($f1cp, -12.2);

is($f1, "399.8");
is($f2, "41.2");

{
    my $n = Math::BigNum->new('12.6');
    $n->bmod('3.45');
    is($n->as_frac, "9/4");
}

{
    my $n = Math::BigNum->new('12.6');
    $n->bfmod('3.45');
    is("$n", "2.25");
}

{
    my $n = Math::BigNum->new('17.6');
    $n->bimod('3.45');
    is("$n", "2");
}

##################################################
# extreme

is($x % Inf,      $x);
is("$x" % Inf,    $x);
is(-$x % Inf,     Inf);
is("-$x" % Inf,   Inf);
is($x % -Inf,     -Inf);
is("$x" % -Inf,   -Inf);
is(-$x % -Inf,    -$x);
is("-$x" % -Inf,  -$x);
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

##################################################
# bmod

# Integer
my $r = $x->copy;
$r %= $y;
is($r, $m);

$r = -$x;
$r %= -$y;
is($r, -$m);

$r = $x->copy;
$r %= -$y;
is($r, $m - $y);

$r = -$x;
$r %= $y;
is($r, $y - $m);

$r = $x->copy;
$r %= "$y";
is($r, $m);

$r = -$x;
$r %= "-$y";
is($r, -$m);

$r = $x->copy;
$r %= "-$y";
is($r, $m - $y);

$r = -$x;
$r %= "$y";
is($r, $y - $m);

# Float
$r = $f1->copy;
$r %= $f2;
is($r->round(0), 29);

$r = -$f1;
$r %= -$f2;
is($r->round(0), -29);

$r = $f1->copy;
$r %= -$f2;
is($r->round(-1), -12.2);

$r = -$f1;
$r %= $f2;
is($r->round(-1), 12.2);

$r = $f1->copy;
$r %= "$f2";
is($r->round(0), 29);

$r = -$f1;
$r %= "-$f2";
is($r->round(0), -29);

$r = $f1->copy;
$r %= "-$f2";
is($r->round(-1), -12.2);

$r = -$f1;
$r %= "$f2";
is($r->round(-1), 12.2);

# Extreme
$r = $x->copy;
$r %= 0;
is($r, NaN);

$r = -$x;
$r %= 0;
is($r, NaN);

$r = $x->copy;
$r %= "0";
is("$r", NaN);

$r = -$x;
$r %= "0.000";
is("$r", NaN);
