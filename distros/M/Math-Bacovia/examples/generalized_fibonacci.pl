#!/usr/bin/perl

# Runtime: 0.190s

use 5.014;
use lib qw(../lib);
use Math::Bacovia qw(:all);
use experimental qw(signatures);

use Test::More;

sub fibonacci ($t, $n) {
    my $a = Power($n**2 + 4, Fraction(1, 2));
    my $b = Fraction($a + Power(Power($a, 2) - 4, Fraction(1, 2)), 2);
    Fraction(Power($b, $t) - Power(-$b, -$t), $a);
}

my $x = fibonacci(Symbol('n', 12), 1)->simple->simple;
my $y = fibonacci(Symbol('n', 12), Symbol('m', 1))->simple->simple;

say $x->pretty;
say $y->pretty;

plan tests => 4;

#<<<
#is($x->pretty, '((((1 + 5^(1/2))/2)^n - (-((1 + 5^(1/2))/2))^(-n))/5^(1/2))');
#is($y->pretty, '(((((4 + m^2)^(1/2) + ((4 + m^2) - 4)^(1/2))/2)^n - (-(((4 + m^2)^(1/2) + ((4 + m^2) - 4)^(1/2))/2))^(-n))/(4 + m^2)^(1/2))');
#>>>

#<<<
is($x->pretty, '((((5^(1/2) + ((5^(1/2))^2 - 4)^(1/2))/2)^n - (-((5^(1/2) + ((5^(1/2))^2 - 4)^(1/2))/2))^(-n))/5^(1/2))');
is($y->pretty, '(((((4 + m^2)^(1/2) + (((4 + m^2)^(1/2))^2 - 4)^(1/2))/2)^n - (-(((4 + m^2)^(1/2) + (((4 + m^2)^(1/2))^2 - 4)^(1/2))/2))^(-n))/(4 + m^2)^(1/2))');
#>>>


#<<<
is($x->numeric, 144);
is($y->numeric, 144);
#>>>
