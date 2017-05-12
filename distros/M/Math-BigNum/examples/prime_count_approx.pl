#!/usr/bin/perl

#
## Some simple approximations to the prime counting function.
#

use 5.010;
use strict;
use warnings;

use lib qw(../lib);
use Math::BigNum qw(:constant);

foreach my $n (1 .. 10) {
    my $x = 10**$n;

    my $f1 = $x->sqr->bidiv(($x + 1)->lngamma);
    my $f2 = int $x->li;

    say "PI($x) =~ ", $f1, ' =~ ', $f2;
}
