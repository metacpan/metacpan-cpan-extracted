#!/usr/bin/perl

#
## https://rosettacode.org/wiki/Miller%E2%80%93Rabin_primality_test#Perl
#

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(valuation irand powmod);

sub is_prime {
    my ($n, $k) = @_;

    return 1 if $n == 2;
    return 0 if $n < 2 or $n % 2 == 0;

    my $d = $n - 1;
    my $s = valuation($d, 2);

    $d >>= $s;

  LOOP: for (1 .. $k) {
        my $a = irand(2, $n - 1);

        my $x = powmod($a, $d, $n);
        next if $x == 1 or $x == $n - 1;

        for (1 .. $s - 1) {
            $x = ($x * $x) % $n;
            return 0  if $x == 1;
            next LOOP if $x == $n - 1;
        }
        return 0;
    }
    return 1;
}

say join ", ", grep { is_prime($_, 10) } (1 .. 1000);
