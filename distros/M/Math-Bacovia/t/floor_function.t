#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 15;

use Math::Bacovia qw(:all);

sub my_floor {
    my ($x) = @_;
    $x - 1 / 2 + ((i * (Log(1 - Exp(i * tau * $x)) - Log(Exp(-i * tau * $x) * (Exp(i * tau * $x) - 1)))) / (tau));
}

is(my_floor(13.1)->numeric->round(-50), 13);
is(my_floor(13.5)->numeric->round(-50), 13);
is(my_floor(13.9)->numeric->round(-50), 13);

is(my_floor(13.1)->simple->numeric->round(-50), 13);
is(my_floor(13.5)->simple->numeric->round(-50), 13);
is(my_floor(13.9)->simple->numeric->round(-50), 13);

is(my_floor(43.999)->numeric->round(-50),   43);
is(my_floor(-123.12)->numeric->round(-50),  -124);
is(my_floor(-129.999)->numeric->round(-50), -130);

is(my_floor(43.999)->simple->numeric->round(-50),   43);
is(my_floor(-123.12)->simple->numeric->round(-50),  -124);
is(my_floor(-129.999)->simple->numeric->round(-50), -130);

is(my_floor(Symbol('x', 43.999))->simple->numeric->round(-50),  43);
is(my_floor(Symbol('x', -123.12))->simple->numeric->round(-50), -124);

my $f = my_floor(Symbol('x'))->simple->simple(full => 1);
is($f->pretty, '((x - 0.5) + ((-0.5/log(-1)) * log(((1 - exp((2 * log(-1) * x)))/((exp((2 * log(-1) * x)) - 1) * exp((-2 * log(-1) * x)))))))');
