#!perl -T

use Test::More tests => 1; # no_plan => 1; # 
use Math::Prime::TiedArray;

tie my @a, "Math::Prime::TiedArray", precompute => 1;

my @primes = (
    qw/2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79
      83 89 97/
);
my @b;
push @b, shift @a for @primes;

is_deeply( \@b, \@primes, "shifting the primes up to 100 worked" );
