#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 20;

use Math::BigNum qw(:constant);

my $S = sqrt(5);
my $T = (1 + $S) / 2;
my $U = 2 / (1 + $S);

my $tau = Math::BigNum->tau;

sub fib1 {
    my ($n) = @_;
    (($T**$n - ($U**$n * cos($tau * $n))) / $S)->round(0);
}

sub fib2 {
    my ($n) = @_;
    (($T**$n - (-$U)**$n) / $S)->round(0);
}

for (my $i = 10 ; $i <= 100 ; $i += 10) {
    my $f1 = fib1($i);
    my $f2 = fib2($i);

    my $fib = $i->fib;
    is($f1, $fib);
    is($f2, $fib);
}
