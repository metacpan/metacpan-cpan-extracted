#!/usr/bin/perl

use utf8;
use 5.014;

use lib qw(../lib);
use Math::Bacovia qw(:all);
use Math::AnyNum qw(bernfrac binomial);

sub faulhaber_s_formula {
    my ($p, $n) = @_;

    my $sum = Sum();
    foreach my $j (0 .. $p) {
        $sum += Number(binomial($p + 1, $j) * bernfrac($j)) * $n**($p + 1 - $j);
    }

    $sum * Fraction(1, ($p + 1));
}

my $n = Symbol('n');

foreach my $p (0 .. 10) {
    say "F($p) = ", faulhaber_s_formula($p, $n)->simple->pretty;
}
