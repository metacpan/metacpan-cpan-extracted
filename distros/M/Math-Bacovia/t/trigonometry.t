#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 146;

use Math::AnyNum;
use Math::Bacovia qw(:all);

my $x = Symbol('x', +43);
my $y = Symbol('y', -43);
my $z = Symbol('z', 1.5);
my $k = Symbol('k', -0.5);

#
## sinh / cosh / tanh / coth / sech / csch
#

is($x->log->sinh->simple(full => 1)->pretty, '((x^2 - 1)/(2 * x))');
is($x->log->cosh->simple(full => 1)->pretty, '((1 + x^2)/(2 * x))');

is($x->log->tanh->simple(full => 1)->pretty, '((x^2 - 1)/(1 + x^2))');
is($x->log->coth->simple(full => 1)->pretty, '((1 + x^2)/(x^2 - 1))');

is($x->log->sech->simple(full => 1)->pretty, '((2 * x)/(1 + x^2))');
is($x->log->csch->simple(full => 1)->pretty, '((2 * x)/(x^2 - 1))');

is($x->log->sinh->simple(full => 1)->numeric, $x->log->sinh->numeric->rat_approx);
is($x->log->cosh->simple(full => 1)->numeric, $x->log->cosh->numeric->rat_approx);

is($x->log->tanh->simple(full => 1)->numeric, $x->log->tanh->numeric->rat_approx);
is($x->log->coth->simple(full => 1)->numeric, $x->log->coth->numeric->rat_approx);

is($x->log->sech->simple(full => 1)->numeric, $x->log->sech->numeric->rat_approx);
is($x->log->csch->simple(full => 1)->numeric, $x->log->csch->numeric->rat_approx);

#
## asinh / acosh / atanh / acoth / asech / acsch
#

is($x->asinh->exp->simple(full => 1)->pretty, '((1 + x^2)^(1/2) + x)');
is($x->acosh->exp->simple(full => 1)->pretty, '(((x - 1)^(1/2) * (1 + x)^(1/2)) + x)');

is($x->atanh->exp->simple(full => 1)->pretty, '((1 + x)^(1/2)/(1 - x)^(1/2))');
is($x->acoth->exp->simple(full => 1)->pretty, '(((1 + x)/x)^(1/2)/(1 - (1/x))^(1/2))');

is($x->asech->exp->simple(full => 1)->pretty, '((1/x) + (((1 - x)/x)^(1/2) * ((1 + x)/x)^(1/2)))');
is($x->acsch->exp->simple(full => 1)->pretty, '((1/x) + (1 + (1/x)^2)^(1/2))');

is($x->asinh->exp->simple(full => 1)->numeric, $x->asinh->exp->numeric);
is($x->acosh->exp->simple(full => 1)->numeric, $x->acosh->exp->numeric);

is($x->atanh->exp->simple(full => 1)->numeric->round(-50), $x->atanh->exp->numeric->round(-50));
is($x->acoth->exp->simple(full => 1)->numeric,             $x->acoth->exp->numeric);

is($x->asech->exp->simple(full => 1)->numeric, $x->asech->exp->numeric);
is($x->acsch->exp->simple(full => 1)->numeric, $x->acsch->exp->numeric);

#
## sin / cos / tan / cot / sec / csc
#

is($x->log->sin->simple(full => 1)->pretty, '((x^i - x^-i)/(2i))');
is($x->log->cos->simple(full => 1)->pretty, '((x^-i + x^i)/2)');

is($x->log->tan->simple(full => 1)->pretty, '(((2i) + (-i * (1 + x^(2i))))/(1 + x^(2i)))');
is($x->log->cot->simple(full => 1)->pretty, '(((2i) + (i * x^(2i)) + -i)/(x^(2i) - 1))');

is($x->log->sec->simple(full => 1)->pretty, '(2/(x^-i + x^i))');
is($x->log->csc->simple(full => 1)->pretty, '((-2i)/(x^-i - x^i))');

is($x->log->sin->simple(full => 1)->numeric, $x->log->sin->numeric);
is($x->log->cos->simple(full => 1)->numeric, $x->log->cos->numeric);

is($x->log->tan->simple(full => 1)->numeric->round(-50), $x->log->tan->numeric->round(-50));
is($x->log->cot->simple(full => 1)->numeric->round(-50), $x->log->cot->numeric->round(-50));

is($x->log->sec->simple(full => 1)->numeric, $x->log->sec->numeric);
is($x->log->csc->simple(full => 1)->numeric, $x->log->csc->numeric);

#
## asin / acos / atan / acot / asec / acsc
#

is($x->asin->exp->simple(full => 1)->pretty, '((1 - x^2)^(1/2) + (i * x))^-i');
is($x->acos->exp->simple(full => 1)->pretty, '(((1 + (x))/2)^(1/2) + (i * ((1 - x)/2)^(1/2)))^(-2i)');

is($x->atan->exp->simple(full => 1)->pretty, '((1 - (i * x))^(1/2)/(1 + (i * x))^(1/2))^i');
is($x->acot->exp->simple(full => 1)->pretty, '((1 - (i/x))^(1/2)/((i + x)/x)^(1/2))^i');

is($x->asec->exp->simple(full => 1)->pretty, '(((1 + x)/(2 * x))^(1/2) + (i * ((1 - (1/x))/2)^(1/2)))^(-2i)');
is($x->acsc->exp->simple(full => 1)->pretty, '((i/x) + (1 - (1/x)^2)^(1/2))^-i');

is($x->asin->exp->simple(full => 1)->numeric, $x->asin->exp->numeric);
is($x->acos->exp->simple(full => 1)->numeric, $x->acos->exp->numeric);

is($x->asec->exp->simple(full => 1)->numeric, $x->asec->exp->numeric);
is($x->acsc->exp->simple(full => 1)->numeric, $x->acsc->exp->numeric);

is($x->atan->exp->simple(full => 1)->numeric, $x->atan->exp->numeric);
is($x->acot->exp->simple(full => 1)->numeric, $x->acot->exp->numeric);

#
## Other tests
#

is(Log($x)->cosh->simple, Fraction(Sum(1, Power(Symbol("x", 43), 2)), Product(2, Symbol("x", 43))));

is((sin(+$z))->asin->numeric->round(-20), +1.5);
is((sin(-$z))->asin->numeric->round(-20), -1.5);

is((cos(+$z))->acos->numeric->round(-20), +1.5);
is((cos(-$z))->acos->numeric->round(-20), +1.5);

is((+$x)->tanh->atanh->simple->numeric->round(-20), +43);
is((-$x)->tanh->atanh->simple->numeric->round(-20), -43);
is((+$y)->tanh->atanh->simple->numeric->round(-20), -43);

is((+$x)->cosh->acosh->simple->numeric, +43);
is((-$x)->cosh->acosh->simple->numeric, +43);
is((+$y)->cosh->acosh->simple->numeric, +43);

is((+$x)->sinh->asinh->numeric,             +43);
is((-$x)->sinh->asinh->numeric->round(-20), -43);
is((+$y)->sinh->asinh->numeric->round(-20), -43);

is(($k)->sinh->asinh->numeric->round(-20), -0.5);
is(($k)->tanh->atanh->numeric->round(-20), -0.5);
is(($k)->csch->acsch->numeric->round(-20), -0.5);
is(($k)->coth->acoth->numeric->round(-20), -0.5);
is(($k)->cosh->acosh->numeric->round(-20), 0.5);
is(($k)->sech->asech->numeric->round(-20), 0.5);

is($k->cot->acot->numeric->round(-20), -0.5);
is($k->acot->cot->numeric->round(-20), -0.5);

is($k->sin->asin->numeric->round(-20), -0.5);
is($k->asin->sin->numeric->round(-20), -0.5);

is($k->sec->asec->numeric->round(-20), 0.5);
is($k->asec->sec->numeric->round(-20), -0.5);

foreach my $method (
                    qw(
                    sin sinh asin asinh
                    cos cosh acos acosh
                    tan tanh atan atanh
                    cot coth acot acoth
                    sec sech asec asech
                    csc csch acsc acsch
                    )
  ) {

    my $n = Math::AnyNum->new(5)->rand;

    if (rand(1) < 0.5) {
        $n = -$n;
    }

#<<<
    is(Math::Bacovia::Number->new($n)->$method->numeric->round(-50)->abs,                    $n->$method->round(-50)->abs, "$method($n)");
    is(Math::Bacovia::Number->new($n)->$method->simple->numeric->round(-50)->abs,            $n->$method->round(-50)->abs, "$method($n)");
    is(Math::Bacovia::Number->new($n)->$method->simple(full => 1)->numeric->round(-50)->abs, $n->$method->round(-50)->abs, "$method($n)");
#>>>
}
