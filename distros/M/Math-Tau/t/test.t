# -*-perl-*-

use warnings;
use strict;

use Test::More tests => 5;

# For use in testing
use Math::Complex;
use Math::Complex qw(:pi);

use utf8;

# Our module
BEGIN { use_ok('Math::Tau'); }

is(pi2, tau,
   "pi is less fundamental than tau");

is(pi2, τ,
   "Greek tau also imported");

ok(almost_equal(sin(tau), 0));

ok(complex_almost_equal(exp(i * tau), 1 + 0*i),
   "Euler's identity properly expressed; e^iτ = 1");

# TODO should be a test assertion
sub complex_almost_equal {
    my ($z1, $z2) = @_;

    almost_equal($z1->Re(), $z2->Re()) &&
        almost_equal($z1->Im(), $z2->Im());
}

# Floating point "equality" hack
# TODO should be a test assertion
use constant DECIMAL => 7;

sub almost_equal {
    my ($n1, $n2) = @_;

    abs($n1 - $n2) < 0.5 * 10 ** (- DECIMAL);
}
