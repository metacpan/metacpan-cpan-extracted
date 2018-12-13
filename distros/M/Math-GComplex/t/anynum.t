#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Math::AnyNum };
    plan skip_all => "Math::AnyNum is not installed"
      if $@;
    plan skip_all => "Math::AnyNum >= 0.20 is needed"
      if ($Math::AnyNum::VERSION < 0.20);
}

plan tests => 343;

use Math::GComplex;
use Math::AnyNum qw(:overload);

my $x = Math::GComplex->new(3, 4);
my $y = Math::GComplex->new(7, 5);

is(join(' ', ($x + $y)->reals), '10 9');
is(join(' ', ($x - $y)->reals), '-4 -1');
is(join(' ', ($x * $y)->reals), '1 43');
is(join(' ', ($x / $y)->reals), '41/74 13/74');

is(join(' ', $x->conj->reals), '3 -4');
is(join(' ', (-$y)->reals), '-7 -5');

is($x->norm,       25);
is($x->conj->norm, 25);
is($x->neg->norm,  25);

is(join(' ', Math::GComplex->new(0, 0)->pow(3)->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 0)->pow(Math::GComplex->new(3, 4))->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 0)->pow(0)->reals), '1 0');
is(join(' ', Math::GComplex->new(0, 0)->pow(Math::GComplex->new(0, 0))->reals), '1 0');
is(join(' ', Math::GComplex->new(0, 0)->pow(-2)->reals), 'Inf NaN');
is(join(' ', Math::GComplex->new(0, 0)->pow(Math::GComplex->new(-2, -5))->reals), 'Inf NaN');
is(join(' ', Math::GComplex->new(0, 0)->pow(Math::GComplex->new(0,  0))->reals),  '1 0');

is(join(' ', Math::GComplex->new(0, 0)->root(0)->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 0)->root(1)->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 0)->root(Math::GComplex->new(1, -5))->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 0)->root(2)->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 0)->root(Math::GComplex->new(2, 3))->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 0)->root(-2)->reals), 'Inf NaN');
is(join(' ', Math::GComplex->new(0, 0)->root(Math::GComplex->new(-3, 4))->reals), 'Inf NaN');

is(join(' ', Math::GComplex->new(0,  4)->pow(0)->reals),  '1 0');
is(join(' ', Math::GComplex->new(0,  -4)->pow(0)->reals), '1 0');
is(join(' ', Math::GComplex->new(-3, -4)->pow(0)->reals), '1 0');

like(join(' ', Math::GComplex->new(0, 1)->pow(Math::GComplex->new(0, 1))->reals),
     qr/^0\.207879576350761908546955619834\d* 0\z/);

like(join(' ', Math::GComplex->new(0, 4)->pow(Math::GComplex->new(0, 5))->reals),
     qr/^0\.00030944438931709426034562369\d* 0\.000234405412606400922838812072\d*\z/);

is(join(' ', log($x)->reals), join(' ', log(3 + 4 * i)->reals));
is(join(' ', log($y)->reals), join(' ', log(7 + 5 * i)->reals));

is(join(' ', log($x->conj)->reals),    join(' ', log(3 - 4 * i)->reals));
is(join(' ', log(-$x)->reals),         join(' ', log(-3 - 4 * i)->reals));
is(join(' ', log(-($x->conj))->reals), join(' ', log(-3 + 4 * i)->reals));

is(join(' ', abs($x)->reals), '5 0');
is(join(' ', abs($y)->reals), join(' ', abs(7 + 5 * i)->reals));

is(join(' ', $x->sgn->reals),      '0.6 0.8');
is(join(' ', $x->neg->sgn->reals), '-0.6 -0.8');
is(join(' ', Math::GComplex->new(0, 0)->sgn->reals), '0 0');

is(join(' ', sin($x)->reals),            join(' ', sin(3 + 4 * i)->reals));
is(join(' ', sin($x->conj)->reals),      join(' ', sin(3 - 4 * i)->reals));
is(join(' ', sin($x->neg->conj)->reals), join(' ', sin(-3 + 4 * i)->reals));

is(join(' ', cos($x)->reals),            join(' ', cos(3 + 4 * i)->reals));
is(join(' ', cos($x->conj)->reals),      join(' ', cos(3 - 4 * i)->reals));
is(join(' ', cos($x->neg->conj)->reals), join(' ', cos(-3 + 4 * i)->reals));

is(join(' ', ($x**$y)->reals), join(' ', ((3 + 4 * i)**(7 + 5 * i))->reals));
is(join(' ', Math::GComplex->new(-0.123, 0)->pow(0.42)->reals), join(' ', ((-0.123)**0.42)->reals));
is(join(' ', Math::GComplex->new(3, 0)->pow(Math::GComplex->new(0, 5))->reals), join(' ', (3**(5 * i))->reals));
is(join(' ', Math::GComplex->new(3, 0)->pow(Math::GComplex->new(5, 0))->reals), '243 0');

is(join(' ', exp($x)->reals),      join(' ', exp(3 + 4 * i)->reals));
is(join(' ', exp($x->neg)->reals), join(' ', exp(-3 - 4 * i)->reals));

is(join(' ', Math::GComplex->new(13, 0)->sin->reals),  join(' ', sin(13)->reals));
is(join(' ', Math::GComplex->new(0,  13)->sin->reals), join(' ', sin(13 * i)->reals));

is(join(' ', Math::GComplex->new(13, 0)->cos->reals),  join(' ', cos(13)->reals));
is(join(' ', Math::GComplex->new(0,  13)->cos->reals), join(' ', cos(13 * i)->reals));

is(join(' ', map { $_->round(-50) } sqrt(Math::GComplex->new(-1, 0))->reals), '0 1');
is(join(' ', map { $_->round(-50) } sqrt(Math::GComplex->new(-4, 0))->reals), '0 2');

is(join(' ', $x->sqrt->reals), '2 1');
is(join(' ', $y->neg->sqrt->reals),       join(' ', sqrt(-7 - 5 * i)->reals));
is(join(' ', $y->neg->conj->sqrt->reals), join(' ', sqrt(-7 + 5 * i)->reals));

is(join(' ', $x->asin->reals),            join(' ', (3 + 4 * i)->asin->reals));
is(join(' ', $x->conj->asin->reals),      join(' ', (3 - 4 * i)->asin->reals));
is(join(' ', $x->neg->conj->asin->reals), join(' ', (-3 + 4 * i)->asin->reals));

is(join(' ', $y->sinh->reals),            join(' ', (7 + 5 * i)->sinh->reals));
is(join(' ', $y->conj->sinh->reals),      join(' ', (7 - 5 * i)->sinh->reals));
is(join(' ', $y->neg->conj->sinh->reals), join(' ', (-7 + 5 * i)->sinh->reals));

is(join(' ', $y->cosh->reals),            join(' ', (7 + 5 * i)->cosh->reals));
is(join(' ', $y->conj->cosh->reals),      join(' ', (7 - 5 * i)->cosh->reals));
is(join(' ', $y->neg->conj->cosh->reals), join(' ', (-7 + 5 * i)->cosh->reals));

is(join(' ', $y->asinh->reals),            join(' ', (7 + 5 * i)->asinh->reals));
is(join(' ', $y->conj->asinh->reals),      join(' ', (7 - 5 * i)->asinh->reals));
is(join(' ', $y->neg->conj->asinh->reals), join(' ', (-7 + 5 * i)->asinh->reals));

is(join(' ', $y->acosh->reals),            join(' ', (7 + 5 * i)->acosh->reals));
is(join(' ', $y->conj->acosh->reals),      join(' ', (7 - 5 * i)->acosh->reals));
is(join(' ', $y->neg->conj->acosh->reals), join(' ', (-7 + 5 * i)->acosh->reals));

is(join(' ', $y->acos->reals),            join(' ', (7 + 5 * i)->acos->reals));
is(join(' ', $y->conj->acos->reals),      join(' ', (7 - 5 * i)->acos->reals));
is(join(' ', $y->neg->conj->acos->reals), join(' ', (-7 + 5 * i)->acos->reals));

is(join(' ', $y->tan->reals),            join(' ', (7 + 5 * i)->tan->reals));
is(join(' ', $y->conj->tan->reals),      join(' ', (7 - 5 * i)->tan->reals));
is(join(' ', $y->neg->conj->tan->reals), join(' ', (-7 + 5 * i)->tan->reals));

is(join(' ', $y->tanh->reals),            join(' ', (7 + 5 * i)->tanh->reals));
is(join(' ', $y->conj->tanh->reals),      join(' ', (7 - 5 * i)->tanh->reals));
is(join(' ', $y->neg->conj->tanh->reals), join(' ', (-7 + 5 * i)->tanh->reals));

is(join(' ', $y->atanh->reals),            join(' ', (7 + 5 * i)->atanh->reals));
is(join(' ', $y->conj->atanh->reals),      join(' ', (7 - 5 * i)->atanh->reals));
is(join(' ', $y->neg->conj->atanh->reals), join(' ', (-7 + 5 * i)->atanh->reals));

is(join(' ', $y->atan->reals),            join(' ', (7 + 5 * i)->atan->reals));
is(join(' ', $y->conj->atan->reals),      join(' ', (7 - 5 * i)->atan->reals));
is(join(' ', $y->neg->conj->atan->reals), join(' ', (-7 + 5 * i)->atan->reals));

is(join(' ', $y->cot->reals),            join(' ', (7 + 5 * i)->cot->reals));
is(join(' ', $y->conj->cot->reals),      join(' ', (7 - 5 * i)->cot->reals));
is(join(' ', $y->neg->conj->cot->reals), join(' ', (-7 + 5 * i)->cot->reals));

is(join(' ', $y->coth->reals),            join(' ', (7 + 5 * i)->coth->reals));
is(join(' ', $y->conj->coth->reals),      join(' ', (7 - 5 * i)->coth->reals));
is(join(' ', $y->neg->conj->coth->reals), join(' ', (-7 + 5 * i)->coth->reals));

is(join(' ', $y->acot->reals),            join(' ', (7 + 5 * i)->acot->reals));
is(join(' ', $y->conj->acot->reals),      join(' ', (7 - 5 * i)->acot->reals));
is(join(' ', $y->neg->conj->acot->reals), join(' ', (-7 + 5 * i)->acot->reals));

is(join(' ', $y->acoth->reals),            join(' ', (7 + 5 * i)->acoth->reals));
is(join(' ', $y->conj->acoth->reals),      join(' ', (7 - 5 * i)->acoth->reals));
is(join(' ', $y->neg->conj->acoth->reals), join(' ', (-7 + 5 * i)->acoth->reals));

is(join(' ', $y->sec->reals),            join(' ', (7 + 5 * i)->sec->reals));
is(join(' ', $y->conj->sec->reals),      join(' ', (7 - 5 * i)->sec->reals));
is(join(' ', $y->neg->conj->sec->reals), join(' ', (-7 + 5 * i)->sec->reals));

is(join(' ', $y->sech->reals),            join(' ', (7 + 5 * i)->sech->reals));
is(join(' ', $y->conj->sech->reals),      join(' ', (7 - 5 * i)->sech->reals));
is(join(' ', $y->neg->conj->sech->reals), join(' ', (-7 + 5 * i)->sech->reals));

is(join(' ', $y->asec->reals),            join(' ', (7 + 5 * i)->asec->reals));
is(join(' ', $y->conj->asec->reals),      join(' ', (7 - 5 * i)->asec->reals));
is(join(' ', $y->neg->conj->asec->reals), join(' ', (-7 + 5 * i)->asec->reals));

is(join(' ', $y->asech->reals),            join(' ', (7 + 5 * i)->asech->reals));
is(join(' ', $y->conj->asech->reals),      join(' ', (7 - 5 * i)->asech->reals));
is(join(' ', $y->neg->conj->asech->reals), join(' ', (-7 + 5 * i)->asech->reals));

is(join(' ', $y->csc->reals),            join(' ', (7 + 5 * i)->csc->reals));
is(join(' ', $y->conj->csc->reals),      join(' ', (7 - 5 * i)->csc->reals));
is(join(' ', $y->neg->conj->csc->reals), join(' ', (-7 + 5 * i)->csc->reals));

is(join(' ', $y->csch->reals),            join(' ', (7 + 5 * i)->csch->reals));
is(join(' ', $y->conj->csch->reals),      join(' ', (7 - 5 * i)->csch->reals));
is(join(' ', $y->neg->conj->csch->reals), join(' ', (-7 + 5 * i)->csch->reals));

is(join(' ', $y->acsc->reals),            join(' ', (7 + 5 * i)->acsc->reals));
is(join(' ', $y->conj->acsc->reals),      join(' ', (7 - 5 * i)->acsc->reals));
is(join(' ', $y->neg->conj->acsc->reals), join(' ', (-7 + 5 * i)->acsc->reals));

is(join(' ', $y->acsch->reals),            join(' ', (7 + 5 * i)->acsch->reals));
is(join(' ', $y->conj->acsch->reals),      join(' ', (7 - 5 * i)->acsch->reals));
is(join(' ', $y->neg->conj->acsch->reals), join(' ', (-7 + 5 * i)->acsch->reals));

is(join(' ', map { $_->round(-50) } Math::GComplex->new(1 / 2,  0)->asin->reals), join(' ', (0.5)->asin->reals));
is(join(' ', map { $_->round(-50) } Math::GComplex->new(-1 / 2, 0)->asin->reals), join(' ', (-0.5)->asin->reals));

is(join(' ', map { $_->round(-50) } Math::GComplex->new(0, 1 / 2)->asin->reals),  join(' ', (0.5 * i)->asin->reals));
is(join(' ', map { $_->round(-50) } Math::GComplex->new(0, -1 / 2)->asin->reals), join(' ', (-0.5 * i)->asin->reals));

is(join(' ', Math::GComplex->new(1)->sqrt->reals),   '1 0');
is(join(' ', Math::GComplex->new('1')->sqrt->reals), '1 0');

is(join(' ', Math::GComplex->new(0)->sqrt->reals),   '0 0');
is(join(' ', Math::GComplex->new('0')->sqrt->reals), '0 0');

is(join(' ', Math::GComplex->new(0)->atan->reals),   '0 0');
is(join(' ', Math::GComplex->new('0')->atan->reals), '0 0');

is(join(' ', Math::GComplex->new(0)->asin->reals),   '0 0');
is(join(' ', Math::GComplex->new('0')->asin->reals), '0 0');

is(join(' ', Math::GComplex->new(1)->acos->reals),   '0 0');
is(join(' ', Math::GComplex->new('1')->acos->reals), '0 0');

is(join(' ', Math::GComplex->new(0)->sech->reals),   '1 0');
is(join(' ', Math::GComplex->new('0')->sech->reals), '1 0');

is(join(' ', Math::GComplex->new(0)->tan->reals),   '0 0');
is(join(' ', Math::GComplex->new('0')->tan->reals), '0 0');

is(join(' ', Math::GComplex->new(0)->tanh->reals),   '0 0');
is(join(' ', Math::GComplex->new('0')->tanh->reals), '0 0');

is(join(' ', Math::GComplex->new(0)->cosh->reals),   '1 0');
is(join(' ', Math::GComplex->new('0')->cosh->reals), '1 0');

is(join(' ', Math::GComplex->new(0)->cos->reals),   '1 0');
is(join(' ', Math::GComplex->new('0')->cos->reals), '1 0');

is(join(' ', Math::GComplex->new(0)->sin->reals),   '0 0');
is(join(' ', Math::GComplex->new('0')->sin->reals), '0 0');

is(join(' ', Math::GComplex->new(1)->log->reals),   '0 0');
is(join(' ', Math::GComplex->new('1')->log->reals), '0 0');

is(join(' ', Math::GComplex->new(0)->sec->reals),   '1 0');
is(join(' ', Math::GComplex->new('0')->sec->reals), '1 0');

is(join(' ', Math::GComplex->new(1)->asec->reals),   '0 0');
is(join(' ', Math::GComplex->new('1')->asec->reals), '0 0');

is(join(' ', Math::GComplex->new(1)->asech->reals),   '0 0');
is(join(' ', Math::GComplex->new('1')->asech->reals), '0 0');

is(join(' ', atan2($x, $y)->reals), join(' ', ($x / $y)->atan->reals));
is(join(' ', atan2($x,      $y)->reals),      join(' ', atan2(3 + 4 * i,  7 + 5 * i)->reals));
is(join(' ', atan2($x->neg, $y)->reals),      join(' ', atan2(-3 - 4 * i, 7 + 5 * i)->reals));
is(join(' ', atan2($x,      $y->neg)->reals), join(' ', atan2(3 + 4 * i,  -7 - 5 * i)->reals));
is(join(' ', atan2($x->neg, $y->neg)->reals), join(' ', atan2(-3 - 4 * i, -7 - 5 * i)->reals));

is(join(' ', atan2(Math::GComplex->new(-3, 0), Math::GComplex->new(-4, 0))->reals), join(' ', atan2(-3, -4)->reals));

is(join(' ', ($y % $x)->reals),                       '0 4');
is(join(' ', ($y % $x->conj)->reals),                 '3 2');
is(join(' ', ($y % $x->neg)->reals),                  '1 -3');
is(join(' ', ($y->neg % $x->neg)->reals),             '0 -4');
is(join(' ', ($y->neg % $x)->reals),                  '-1 3');
is(join(' ', ($y->neg % $x->conj)->reals),            '4 -3');
is(join(' ', ($y->conj % $x->conj)->reals),           '4 -1');
is(join(' ', ($y->conj % $x->neg->conj)->reals),      '-3 0');
is(join(' ', ($y->neg->conj % $x->neg->conj)->reals), '-4 1');
is(join(' ', ($y->neg->conj % $x->conj)->reals),      '3 0');

is(join(' ', map { $_->round(-50) } Math::GComplex->new(1e5)->sech->reals), '0 0');
is(join(' ', map { $_->round(-50) } Math::GComplex->new(1e5)->csch->reals), '0 0');
is(join(' ', map { $_->round(-50) } Math::GComplex->new(1e5)->tanh->reals), '1 0');
is(join(' ', map { $_->round(-50) } Math::GComplex->new(1e5)->coth->reals), '1 0');

is(join(' ', Math::GComplex->new(13.7)->floor->reals),  '13 0');
is(join(' ', Math::GComplex->new(-13.7)->floor->reals), '-14 0');
is(join(' ', Math::GComplex->new(-13.7, 15.3)->floor->reals),  '-14 15');
is(join(' ', Math::GComplex->new(-13.7, -15.3)->floor->reals), '-14 -16');
is(join(' ', Math::GComplex->new(13.7,  -15.3)->floor->reals), '13 -16');
is(join(' ', Math::GComplex->new(13.7,  -15.9)->floor->reals), '13 -16');
is(join(' ', Math::GComplex->new(13.3,  -15.9)->floor->reals), '13 -16');
is(join(' ', Math::GComplex->new(-13.3, -15.9)->floor->reals), '-14 -16');

is(join(' ', Math::GComplex->new(-14, -15)->floor->reals), '-14 -15');
is(join(' ', Math::GComplex->new(14,  15)->floor->reals),  '14 15');

is(join(' ', Math::GComplex->new(-14, -15)->ceil->reals), '-14 -15');
is(join(' ', Math::GComplex->new(14,  15)->ceil->reals),  '14 15');

is(join(' ', int(Math::GComplex->new(13.7,  12.4))->reals),  '13 12');
is(join(' ', int(Math::GComplex->new(13.7,  -12.4))->reals), '13 -12');
is(join(' ', int(Math::GComplex->new(-13.7, -12.4))->reals), '-13 -12');

is(join(' ', Math::GComplex->new(13.7)->ceil->reals),  '14 0');
is(join(' ', Math::GComplex->new(-13.7)->ceil->reals), '-13 0');
is(join(' ', Math::GComplex->new(-13.7, 15.3)->ceil->reals),  '-13 16');
is(join(' ', Math::GComplex->new(-13.7, -15.3)->ceil->reals), '-13 -15');
is(join(' ', Math::GComplex->new(13.7,  -15.3)->ceil->reals), '14 -15');
is(join(' ', Math::GComplex->new(13.7,  -15.9)->ceil->reals), '14 -15');
is(join(' ', Math::GComplex->new(13.3,  -15.9)->ceil->reals), '14 -15');
is(join(' ', Math::GComplex->new(-13.3, -15.9)->ceil->reals), '-13 -15');

{
    my $z1 = Math::GComplex->new(0.5,  0.3);
    my $z2 = Math::GComplex->new(0.5,  -0.3);
    my $z3 = Math::GComplex->new(-0.5, 0.3);
    my $z4 = Math::GComplex->new(-0.5, -0.3);

    # asin(sin(x)) = x  for |x| < 1
    is(join(' ', sin($z1)->asin->reals), '0.5 0.3');
    is(join(' ', sin($z2)->asin->reals), '0.5 -0.3');
    is(join(' ', sin($z3)->asin->reals), '-0.5 0.3');
    is(join(' ', sin($z4)->asin->reals), '-0.5 -0.3');

    # asin(sin(x)) = x
    is(join(' ', $z1->sinh->asinh->reals), '0.5 0.3');
    is(join(' ', $z2->sinh->asinh->reals), '0.5 -0.3');
    is(join(' ', $z3->sinh->asinh->reals), '-0.5 0.3');
    is(join(' ', $z4->sinh->asinh->reals), '-0.5 -0.3');

    # sin(asin(x)) = x  for |x| < pi/2
    is(join(' ', sin($z1->asin)->reals), '0.5 0.3');
    is(join(' ', sin($z2->asin)->reals), '0.5 -0.3');
    is(join(' ', sin($z3->asin)->reals), '-0.5 0.3');
    is(join(' ', sin($z4->asin)->reals), '-0.5 -0.3');

    # sinh(asinh(x)) = x
    is(join(' ', $z1->asinh->sinh->reals), '0.5 0.3');
    is(join(' ', $z2->asinh->sinh->reals), '0.5 -0.3');
    is(join(' ', $z3->asinh->sinh->reals), '-0.5 0.3');
    is(join(' ', $z4->asinh->sinh->reals), '-0.5 -0.3');

    # acos(cos(x)) = x  for |x| < 1
    is(join(' ', cos($z1)->acos->reals), '0.5 0.3');
    is(join(' ', cos($z2)->acos->reals), '0.5 -0.3');
    is(join(' ', cos($z3)->acos->reals), '0.5 -0.3');    # this is correct
    is(join(' ', cos($z4)->acos->reals), '0.5 0.3');     # =//=

    # acosh(cosh(x)) = x
    is(join(' ', $z1->cosh->acosh->reals), '0.5 0.3');
    is(join(' ', $z2->cosh->acosh->reals), '0.5 -0.3');
    is(join(' ', $z3->cosh->acosh->reals), '0.5 -0.3');    # this is correct
    is(join(' ', $z4->cosh->acosh->reals), '0.5 0.3');     # =//=

    # cos(acos(x)) = x  for |x| < pi/2
    is(join(' ', cos($z1->acos)->reals), '0.5 0.3');
    is(join(' ', cos($z2->acos)->reals), '0.5 -0.3');
    is(join(' ', cos($z3->acos)->reals), '-0.5 0.3');
    is(join(' ', cos($z4->acos)->reals), '-0.5 -0.3');

    # cosh(acosh(x)) = x
    is(join(' ', $z1->acosh->cosh->reals), '0.5 0.3');
    is(join(' ', $z2->acosh->cosh->reals), '0.5 -0.3');
    is(join(' ', $z3->acosh->cosh->reals), '-0.5 0.3');
    is(join(' ', $z4->acosh->cosh->reals), '-0.5 -0.3');

    # tan(atan(x)) = x
    is(join(' ', $z1->atan->tan->reals), '0.5 0.3');
    is(join(' ', $z2->atan->tan->reals), '0.5 -0.3');
    is(join(' ', $z3->atan->tan->reals), '-0.5 0.3');
    is(join(' ', $z4->atan->tan->reals), '-0.5 -0.3');

    # tanh(atanh(x)) = x
    is(join(' ', $z1->atanh->tanh->reals), '0.5 0.3');
    is(join(' ', $z2->atanh->tanh->reals), '0.5 -0.3');
    is(join(' ', $z3->atanh->tanh->reals), '-0.5 0.3');
    is(join(' ', $z4->atanh->tanh->reals), '-0.5 -0.3');

    # atan(tan(x)) = x
    is(join(' ', $z1->tan->atan->reals), '0.5 0.3');
    is(join(' ', $z2->tan->atan->reals), '0.5 -0.3');
    is(join(' ', $z3->tan->atan->reals), '-0.5 0.3');
    is(join(' ', $z4->tan->atan->reals), '-0.5 -0.3');

    # atan(tan(x)) = x
    is(join(' ', $z1->tanh->atanh->reals), '0.5 0.3');
    is(join(' ', $z2->tanh->atanh->reals), '0.5 -0.3');
    is(join(' ', $z3->tanh->atanh->reals), '-0.5 0.3');
    is(join(' ', $z4->tanh->atanh->reals), '-0.5 -0.3');

    # cot(acot(x)) = x
    is(join(' ', $z1->acot->cot->reals), '0.5 0.3');
    is(join(' ', $z2->acot->cot->reals), '0.5 -0.3');
    is(join(' ', $z3->acot->cot->reals), '-0.5 0.3');
    is(join(' ', $z4->acot->cot->reals), '-0.5 -0.3');

    # coth(acoth(x)) = x
    is(join(' ', $z1->acoth->coth->reals), '0.5 0.3');
    is(join(' ', $z2->acoth->coth->reals), '0.5 -0.3');
    is(join(' ', $z3->acoth->coth->reals), '-0.5 0.3');
    is(join(' ', $z4->acoth->coth->reals), '-0.5 -0.3');

    # acot(cot(x)) = x
    is(join(' ', $z1->cot->acot->reals), '0.5 0.3');
    is(join(' ', $z2->cot->acot->reals), '0.5 -0.3');
    is(join(' ', $z3->cot->acot->reals), '-0.5 0.3');
    is(join(' ', $z4->cot->acot->reals), '-0.5 -0.3');

    # acoth(coth(x)) = x
    is(join(' ', $z1->coth->acoth->reals), '0.5 0.3');
    is(join(' ', $z2->coth->acoth->reals), '0.5 -0.3');
    is(join(' ', $z3->coth->acoth->reals), '-0.5 0.3');
    is(join(' ', $z4->coth->acoth->reals), '-0.5 -0.3');

    # asec(sec(x)) = x
    is(join(' ', $z1->sec->asec->reals), '0.5 0.3');
    is(join(' ', $z2->sec->asec->reals), '0.5 -0.3');
    is(join(' ', $z3->sec->asec->reals), '0.5 -0.3');    # this is correct
    is(join(' ', $z4->sec->asec->reals), '0.5 0.3');     # =//=

    # asech(sech(x)) = x
    is(join(' ', $z1->sech->asech->reals), '0.5 0.3');
    is(join(' ', $z2->sech->asech->reals), '0.5 -0.3');
    is(join(' ', $z3->sech->asech->reals), '0.5 -0.3');    # this is correct
    is(join(' ', $z4->sech->asech->reals), '0.5 0.3');     # =//=

    # sec(asec(x)) = x
    is(join(' ', $z1->asec->sec->reals), '0.5 0.3');
    is(join(' ', $z2->asec->sec->reals), '0.5 -0.3');
    is(join(' ', $z3->asec->sec->reals), '-0.5 0.3');
    is(join(' ', $z4->asec->sec->reals), '-0.5 -0.3');

    # sech(asech(x)) = x
    is(join(' ', $z1->asech->sech->reals), '0.5 0.3');
    is(join(' ', $z2->asech->sech->reals), '0.5 -0.3');
    is(join(' ', $z3->asech->sech->reals), '-0.5 0.3');
    is(join(' ', $z4->asech->sech->reals), '-0.5 -0.3');

    # csc(acsc(x)) = x
    is(join(' ', $z1->acsc->csc->reals), '0.5 0.3');
    is(join(' ', $z2->acsc->csc->reals), '0.5 -0.3');
    is(join(' ', $z3->acsc->csc->reals), '-0.5 0.3');
    is(join(' ', $z4->acsc->csc->reals), '-0.5 -0.3');

    # csch(acsch(x)) = x
    is(join(' ', $z1->acsch->csch->reals), '0.5 0.3');
    is(join(' ', $z2->acsch->csch->reals), '0.5 -0.3');
    is(join(' ', $z3->acsch->csch->reals), '-0.5 0.3');
    is(join(' ', $z4->acsch->csch->reals), '-0.5 -0.3');

    # acsc(csc(x)) = x
    is(join(' ', $z1->csc->acsc->reals), '0.5 0.3');
    is(join(' ', $z2->csc->acsc->reals), '0.5 -0.3');
    is(join(' ', $z3->csc->acsc->reals), '-0.5 0.3');
    is(join(' ', $z4->csc->acsc->reals), '-0.5 -0.3');

    # acsch(csch(x)) = x
    is(join(' ', $z1->csch->acsch->reals), '0.5 0.3');
    is(join(' ', $z2->csch->acsch->reals), '0.5 -0.3');
    is(join(' ', $z3->csch->acsch->reals), '-0.5 0.3');
    is(join(' ', $z4->csch->acsch->reals), '-0.5 -0.3');

    # tan(x) = sin(x)/cos(x)
    is(join(' ', (sin($z1) / cos($z1))->reals), join(' ', $z1->tan->reals));
    is(join(' ', (sin($z2) / cos($z2))->reals), join(' ', $z2->tan->reals));
    is(join(' ', (sin($z3) / cos($z3))->reals), join(' ', $z3->tan->reals));
    is(join(' ', (sin($z4) / cos($z4))->reals), join(' ', $z4->tan->reals));

    # tanh(x) = sinh(x)/cosh(x)
    is(join(' ', ($z1->sinh / $z1->cosh)->reals), join(' ', $z1->tanh->reals));
    is(join(' ', ($z2->sinh / $z2->cosh)->reals), join(' ', $z2->tanh->reals));
    is(join(' ', ($z3->sinh / $z3->cosh)->reals), join(' ', $z3->tanh->reals));
    is(join(' ', ($z4->sinh / $z4->cosh)->reals), join(' ', $z4->tanh->reals));

    # sec(x) = 1/cos(x)
    is(join(' ', $z1->sec->reals), join(' ', cos($z1)->inv->reals));
    is(join(' ', $z2->sec->reals), join(' ', cos($z2)->inv->reals));
    is(join(' ', $z3->sec->reals), join(' ', cos($z3)->inv->reals));
    is(join(' ', $z4->sec->reals), join(' ', cos($z4)->inv->reals));

    # sech(x) = 1/cosh(x)
    is(join(' ', $z1->sech->reals), join(' ', $z1->cosh->inv->reals));
    is(join(' ', $z2->sech->reals), join(' ', $z2->cosh->inv->reals));
    is(join(' ', $z3->sech->reals), join(' ', $z3->cosh->inv->reals));
    is(join(' ', $z4->sech->reals), join(' ', $z4->cosh->inv->reals));

    # csc(x) = 1/sin(x)
    is(join(' ', $z1->csc->reals), join(' ', sin($z1)->inv->reals));
    is(join(' ', $z2->csc->reals), join(' ', sin($z2)->inv->reals));
    is(join(' ', $z3->csc->reals), join(' ', sin($z3)->inv->reals));
    is(join(' ', $z4->csc->reals), join(' ', sin($z4)->inv->reals));

    # csch(x) = 1/sinh(x)
    is(join(' ', $z1->csch->reals), join(' ', $z1->sinh->inv->reals));
    is(join(' ', $z2->csch->reals), join(' ', $z2->sinh->inv->reals));
    is(join(' ', $z3->csch->reals), join(' ', $z3->sinh->inv->reals));
    is(join(' ', $z4->csch->reals), join(' ', $z4->sinh->inv->reals));

    # cot(x) = 1/tan(x)
    is(join(' ', $z1->cot->reals), join(' ', $z1->tan->inv->reals));
    is(join(' ', $z2->cot->reals), join(' ', $z2->tan->inv->reals));
    is(join(' ', $z3->cot->reals), join(' ', $z3->tan->inv->reals));
    is(join(' ', $z4->cot->reals), join(' ', $z4->tan->inv->reals));

    # coth(x) = 1/tanh(x)
    is(join(' ', $z1->coth->reals), join(' ', $z1->tanh->inv->reals));
    is(join(' ', $z2->coth->reals), join(' ', $z2->tanh->inv->reals));
    is(join(' ', $z3->coth->reals), join(' ', $z3->tanh->inv->reals));
    is(join(' ', $z4->coth->reals), join(' ', $z4->tanh->inv->reals));
}

is(join(' ', Math::GComplex::deg2rad(45)->reals),              join(' ', (Math::AnyNum->pi / 4)->reals));
is(join(' ', Math::GComplex::deg2rad(Math::AnyNum->e)->reals), join(' ', (Math::AnyNum->e->deg2rad)->reals));
is(join(' ', Math::GComplex::deg2rad(0)->reals),               '0 0');

is(join(' ', Math::GComplex::rad2deg(Math::AnyNum->pi / 4)->reals), '45 0');
is(join(' ', Math::GComplex::rad2deg(Math::AnyNum->e)->reals), join(' ', Math::AnyNum->e->rad2deg->reals));
is(join(' ', Math::GComplex::rad2deg(0)->reals), '0 0');

is(join(' ', Math::GComplex->new(0)->pown(0)->reals),  '1 0');
is(join(' ', Math::GComplex->new(0)->pown(10)->reals), '0 0');
is(join(' ', Math::GComplex->new(0, 1)->pown(3)->reals), '0 -1');
is(join(' ', Math::GComplex->new(0, 1)->pown(4)->reals), '1 0');

is(join(' ', Math::GComplex->new(3, 4)->pown(10)->reals),  '-9653287 1476984');
is(join(' ', Math::GComplex->new(3, 4)->pown(-10)->reals), '-9653287/95367431640625 -1476984/95367431640625');
is(join(' ', Math::GComplex->new(-9, -12)->pown(-13)->reals),
    '-354815761/791908800601959228515625 -597551756/2375726401805877685546875');
