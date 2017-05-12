#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 202;

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

# Rational
my @list = (
            '-15/4',  '-15/4',  '-15/4',  '-19/20', '-19/20', 'NaN',  '9/20',   '37/20',  '9/20',   '37/20',
            '13/4',   '-3',     '-3',     '-3',     '-1/5',   '-1/5', 'NaN',    '6/5',    '13/5',   '6/5',
            '13/5',   '4',      '-9/4',   '-9/4',   '-9/4',   '-9/4', '-17/20', 'NaN',    '11/20',  '11/20',
            '39/20',  '67/20',  '19/4',   '-3/2',   '-3/2',   '-3/2', '-3/2',   '-1/10',  'NaN',    '13/10',
            '13/10',  '27/10',  '41/10',  '11/2',   '-3/4',   '-3/4', '-3/4',   '-3/4',   '-3/4',   'NaN',
            '13/20',  '41/20',  '69/20',  '97/20',  '25/4',   '0',    '0',      '0',      '0',      '0',
            'NaN',    '0',      '0',      '0',      '0',      '0',    '-25/4',  '-97/20', '-69/20', '-41/20',
            '-13/20', 'NaN',    '3/4',    '3/4',    '3/4',    '3/4',  '3/4',    '-11/2',  '-41/10', '-27/10',
            '-13/10', '-13/10', 'NaN',    '1/10',   '3/2',    '3/2',  '3/2',    '3/2',    '-19/4',  '-67/20',
            '-39/20', '-11/20', '-11/20', 'NaN',    '17/20',  '9/4',  '9/4',    '9/4',    '9/4',    '-4',
            '-13/5',  '-6/5',   '-13/5',  '-6/5',   'NaN',    '1/5',  '1/5',    '3',      '3',      '3',
            '-13/4',  '-37/20', '-9/20',  '-37/20', '-9/20',  'NaN',  '19/20',  '19/20',  '15/4',   '15/4',
            '15/4'
           );

my $c1 = Math::AnyNum->new('4/3');
my $c2 = Math::AnyNum->new('5/7');

is($c1 % "-12", "-32/3");

is(($c2 * 1234) % "42",   "290/7");
is(($c2 * 1234) % 43,     "150/7");
is((-$c2 * 1234) % "-43", "-150/7");
is(($c2 * 1234) % -43,    "-151/7");
is((-$c2 * 1234) % 43,    "151/7");

is($c1 % 0,     "NaN");
is($c2 % "0",   "NaN");
is($c2 % "0/0", "NaN");
is($c2 % "abc", "NaN");

is((1234 * $c1) % Math::AnyNum->new_z('43'), '34/3');
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

foreach my $n (-5 .. 5) {
    foreach my $k (-5 .. 5) {
        my $x = Math::AnyNum->new_q($n)->div($c1);
        my $y = Math::AnyNum->new_q($k)->div($c2);
        is($x % $y, Math::AnyNum->new(shift @list), "$x % $y");
    }
}
