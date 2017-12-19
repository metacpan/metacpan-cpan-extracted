#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 13;

use Math::Bacovia qw(Power Symbol Fraction);

my $P = Power(5, '1/2');
my $S = Fraction($P + 1, 2);
my $T = $S->inv;

sub fibonacci {
    my ($n) = @_;
    Fraction(($S**$n - (-$T)**$n), $P);
}

my @fibs = qw(0 1 1 2 3 5 8 13 21 34);

foreach my $n (0 .. 9) {
    is(fibonacci($n)->simple->numeric, shift(@fibs));
}

my $expr = fibonacci(Symbol('n', 12));

is($expr->simple->numeric, 144);
is($expr->expand->numeric, 144);

my $f = $expr->simple->pretty;
is($f, '((((1 + 5^(1/2))/2)^n - (-(2/(1 + 5^(1/2))))^n)/5^(1/2))');
