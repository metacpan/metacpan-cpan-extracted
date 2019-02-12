#!/usr/bin/perl

# Computing Bernoulli numbers from Pascal's triangle.

# See also:
#   https://en.wikipedia.org/wiki/Bernoulli_number#Connection_with_Pascal’s_triangle

use 5.014;
use lib qw(../lib);
use experimental qw(signatures);

use Math::MatrixLUP;
use Math::AnyNum qw(:overload binomial factorial);

sub pascal_bernoulli_number($n) {

    my $A = Math::MatrixLUP->build($n, sub ($i, $k) {
        $k > $i + 1 ? 0 : binomial($i + 2, $k)
    });

    $A->det / factorial($n + 1);
}

foreach my $n (0 .. 20) {
    say "B($n) = ", pascal_bernoulli_number($n);
}
