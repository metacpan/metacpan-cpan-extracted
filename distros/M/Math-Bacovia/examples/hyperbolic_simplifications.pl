#!/usr/bin/perl

use 5.014;

use lib qw(../lib);
use Math::Bacovia qw(Symbol);

my $x = Symbol('x');

say "sinh(log(x)) = ", $x->log->sinh->simple->pretty;
say "cosh(log(x)) = ", $x->log->cosh->simple->pretty;

say "tanh(log(x)) = ", $x->log->tanh->simple->pretty;
say "coth(log(x)) = ", $x->log->coth->simple->pretty;

say "sech(log(x)) = ", $x->log->sech->simple->pretty;
say "csch(log(x)) = ", $x->log->csch->simple->pretty;

say '-' x 60;

say "exp(asinh(x)) = ", $x->asinh->exp->simple(full => 1)->pretty;
say "exp(acosh(x)) = ", $x->acosh->exp->simple(full => 1)->pretty;

say "exp(atanh(x)) = ", $x->atanh->exp->simple(full => 1)->pretty;
say "exp(acoth(x)) = ", $x->acoth->exp->simple(full => 1)->pretty;

say "exp(asech(x)) = ", $x->asech->exp->simple(full => 1)->pretty;
say "exp(acsch(x)) = ", $x->acsch->exp->simple(full => 1)->pretty;

say '-' x 60;

say "sin(log(x)) = ", $x->log->sin->simple(full => 1)->pretty;
say "cos(log(x)) = ", $x->log->cos->simple(full => 1)->pretty;

say "tan(log(x)) = ", $x->log->tan->simple(full => 1)->pretty;
say "cot(log(x)) = ", $x->log->cot->simple(full => 1)->pretty;

say "sec(log(x)) = ", $x->log->sec->simple(full => 1)->pretty;
say "csc(log(x)) = ", $x->log->csc->simple(full => 1)->pretty;

say '-' x 60;

say "exp(asin(x)) = ", $x->asin->exp->simple(full => 1)->pretty;
say "exp(acos(x)) = ", $x->acos->exp->simple(full => 1)->pretty;

say "exp(atan(x)) = ", $x->atan->exp->simple(full => 1)->pretty;
say "exp(acot(x)) = ", $x->acot->exp->simple(full => 1)->pretty;

say "exp(asec(x)) = ", $x->asec->exp->simple(full => 1)->pretty;
say "exp(acsc(x)) = ", $x->acsc->exp->simple(full => 1)->pretty;

__END__
sinh(log(x)) = ((x^2 - 1)/(2 * x))
cosh(log(x)) = ((1 + x^2)/(2 * x))
tanh(log(x)) = ((x^2 - 1)/(1 + x^2))
coth(log(x)) = ((1 + x^2)/(x^2 - 1))
sech(log(x)) = ((2 * x)/(1 + x^2))
csch(log(x)) = ((2 * x)/(x^2 - 1))
------------------------------------------------------------
exp(asinh(x)) = ((1 + x^2)^(1/2) + x)
exp(acosh(x)) = (((x - 1)^(1/2) * (1 + x)^(1/2)) + x)
exp(atanh(x)) = ((1 + x)^(1/2)/(1 - x)^(1/2))
exp(acoth(x)) = (((1 + x)/x)^(1/2)/(1 - (1/x))^(1/2))
exp(asech(x)) = ((1/x) + (((1 - x)/x)^(1/2) * ((1 + x)/x)^(1/2)))
exp(acsch(x)) = ((1/x) + (1 + (1/x)^2)^(1/2))
------------------------------------------------------------
sin(log(x)) = ((x^i - x^-i)/(2i))
cos(log(x)) = ((x^-i + x^i)/2)
tan(log(x)) = (((2i) + (-i * (1 + x^(2i))))/(1 + x^(2i)))
cot(log(x)) = (((2i) + (i * x^(2i)) + -i)/(x^(2i) - 1))
sec(log(x)) = (2/(x^-i + x^i))
csc(log(x)) = ((-2i)/(x^-i - x^i))
------------------------------------------------------------
exp(asin(x)) = ((1 - x^2)^(1/2) + (i * x))^-i
exp(acos(x)) = (((1 + (x))/2)^(1/2) + (i * ((1 - x)/2)^(1/2)))^(-2i)
exp(atan(x)) = ((1 - (i * x))^(1/2)/(1 + (i * x))^(1/2))^i
exp(acot(x)) = ((1 - (i/x))^(1/2)/((i + x)/x)^(1/2))^i
exp(asec(x)) = (((1 + x)/(2 * x))^(1/2) + (i * ((1 - (1/x))/2)^(1/2)))^(-2i)
exp(acsc(x)) = ((i/x) + (1 - (1/x)^2)^(1/2))^-i
