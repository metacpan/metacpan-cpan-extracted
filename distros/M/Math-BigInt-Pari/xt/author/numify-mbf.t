# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 12;

use Math::BigFloat;

use Math::Complex ();

my $inf = $Math::Complex::Inf;
my $nan = $inf - $inf;

# Compute parameters for relative tolerance.
#
# $p is the precision, i.e., the number of bits in the mantissa/significand, as
# defined in IEEE754. $eps is the smallest number that, when subtracted from 1,
# gives a number smaller than 1.

my $p = 0;
my $eps = 1;
while (((1 + $eps) - 1) != 0) {
    $eps *= 0.5;
    $p++;
}
my $reltol = 20 * $eps;

###############################################################################
# Check numify() on finite, floating point values.

for my $entry
  (
   [ 'Math::BigFloat -> new("+1234e+56") -> numify()', +1234e+56 ],
   [ 'Math::BigFloat -> new("-1234e+56") -> numify()', -1234e+56 ],
   [ 'Math::BigFloat -> new("+1234e-56") -> numify()', +1234e-56 ],
   [ 'Math::BigFloat -> new("-1234e-56") -> numify()', -1234e-56 ],
   [ 'Math::BigFloat -> bpi() -> numify()', atan2(0, -1) ],
  )
{
    my ($test, $expected) = @$entry;
    my $x = eval $test;
    die $@ if $@;

    my $abserr   = $x - $expected;
    my $relerr   = $abserr / $expected;
    if (abs($relerr) <= $reltol) {
        pass($test);
    } else {
        fail($test);
        diag(<<EOF);
          got: $x
     expected: $expected
    abs. err.: $abserr
    rel. err.: $relerr
    rel. tol.: $reltol
EOF
    }
}

###############################################################################
# Verify that numify() underflows and overflows when given "extreme" values.

# positive overflow
cmp_ok(Math::BigFloat -> new("1e9999") -> numify(), "==", $inf,
   qq|Math::BigFloat -> new("1e9999") -> numify()|);

# negative overflow
cmp_ok(Math::BigFloat -> new("-1e9999") -> numify(), "==", -$inf,
   qq|Math::BigFloat -> new("-1e9999") -> numify()|);

# positive underflow
cmp_ok(Math::BigFloat -> new("1e-9999") -> numify(), "==", 0,
       qq|Math::BigFloat -> new("1e-9999") -> numify()|);

# negative underflow
cmp_ok(Math::BigFloat -> new("-1e-9999") -> numify(), "==", 0,
       qq|Math::BigFloat -> new("-1e-9999") -> numify()|);

###############################################################################
# Check numify on non-finite objects.

is(Math::BigFloat -> binf("+") -> numify(),  $inf, "numify of +Inf");
is(Math::BigFloat -> binf("-") -> numify(), -$inf, "numify of -Inf");
is(Math::BigFloat -> bnan()    -> numify(),  $nan, "numify of NaN");
