#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use Test::More tests=> 11;
$|++;

use Math::Primality qw/ prime_count /;

# test data from http://mathworld.wolfram.com/PrimeCountingFunction.html 

my $i = 1;
while (<DATA>) {
    chomp;
    cmp_ok ( prime_count(10**$i), '==', $_, "$_ primes <= 10^$i");
    $i++;
}

__DATA__
4
25
168
1229
9592
78498
664579
5761455
50847534
455052511
4118054813
