#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 20;

use Math::AnyNum qw(:overload tau);

my $S = sqrt(5);
my $T = (1 + $S) / 2;
my $U = 2 / (1 + $S);

sub fib1 {
    my ($n) = @_;
    (($T**$n - ($U**$n * cos(tau * $n))) / $S)->round;
}

sub fib2 {
    my ($n) = @_;
    (($T**$n - (-$U)**$n) / $S)->round;
}

for (my $i = 10 ; $i <= 100 ; $i += 10) {
    my $f1 = fib1($i);
    my $f2 = fib2($i);

    my $fib = $i->fibonacci;
    is($f1, $fib);
    is($f2, $fib);
}
