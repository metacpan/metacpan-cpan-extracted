#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum qw(:constant);

for my $i (0 .. 6) {

    my $n = 2 * $i;

    #  Each pair is a square
    my @pairs = (
        ($n**2)**($n**2 + 1) * ($n**2 + 1)**($n**2),
        ($n**2 - 1)**($n**2) * ($n**2)**($n**2 - 1),
    );

    # Print the integer square roots (isqrt)
    printf("(%d, %d)\n -> %s\n -> %s\n\n", $n**2, $n**2 - 1, map { $_->isqrt } @pairs);
}
