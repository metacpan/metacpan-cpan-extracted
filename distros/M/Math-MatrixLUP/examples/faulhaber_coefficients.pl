#!/usr/bin/perl

# Compute the Faulhaber triangle of coffiecients.

# See also:
#   https://en.wikipedia.org/wiki/Faulhaber's_formula
#   https://en.wikipedia.org/wiki/Vandermonde_matrix

use 5.014;
use lib qw(../lib);
use experimental qw(signatures);

use Math::MatrixLUP;
use Math::AnyNum qw(:overload ipow);

sub faulhaber_coefficients ($n) {

    my @acc = (0, 1);

    foreach my $k (1 .. $n + 1) {
        $acc[$k] = $acc[$k - 1] + ipow($k, $n);
    }

    # Build a Vandermonde matrix
    my $A = Math::MatrixLUP->build($n + 2, sub ($i, $j) {
            ipow($i, $j);
        }
    );

    $A->solve(\@acc);
}

foreach my $n (0 .. 10) {
    say "F($n) = [", join(', ', @{faulhaber_coefficients($n)}), "]";
}

__END__
F(0) = [0, 1]
F(1) = [0, 1/2, 1/2]
F(2) = [0, 1/6, 1/2, 1/3]
F(3) = [0, 0, 1/4, 1/2, 1/4]
F(4) = [0, -1/30, 0, 1/3, 1/2, 1/5]
F(5) = [0, 0, -1/12, 0, 5/12, 1/2, 1/6]
F(6) = [0, 1/42, 0, -1/6, 0, 1/2, 1/2, 1/7]
F(7) = [0, 0, 1/12, 0, -7/24, 0, 7/12, 1/2, 1/8]
F(8) = [0, -1/30, 0, 2/9, 0, -7/15, 0, 2/3, 1/2, 1/9]
F(9) = [0, 0, -3/20, 0, 1/2, 0, -7/10, 0, 3/4, 1/2, 1/10]
F(10) = [0, 5/66, 0, -1/2, 0, 1, 0, -1, 0, 5/6, 1/2, 1/11]
