# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 15;

use Math::BigInt;

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
# Check numify() on finite values.

cmp_ok(Math::BigInt -> bzero() -> numify(), "==", 0,
       'Math::BigInt -> bzero() -> numify()');
cmp_ok(Math::BigInt -> bone() -> numify(), "==", 1,
       'Math::BigInt -> bone() -> numify()');
cmp_ok(Math::BigInt -> new("4711") -> numify(), "==", 4711,
       'Math::BigInt -> new("4711") -> numify()');
cmp_ok(Math::BigInt -> new("-4711") -> numify(), "==", -4711,
       'Math::BigInt -> new("-4711") -> numify()');

###############################################################################
# Check numify() on finite, floating point values.

for my $entry
  (
   [ 'Math::BigInt -> new("+1234e+56") -> numify()', +1234e+56 ],
   [ 'Math::BigInt -> new("-1234e+56") -> numify()', -1234e+56 ],
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
# Verify that numify() overflows when given "extreme" values.

# positive overflow
is(Math::BigInt -> new("1e9999") -> numify(), $inf,
   qq|Math::BigInt -> new("1e9999") -> numify()|);

# negative overflow
is(Math::BigInt -> new("-1e9999") -> numify(), -$inf,
   qq|Math::BigInt -> new("-1e9999") -> numify()|);

###############################################################################
# Check numify on non-finite objects.

is(Math::BigInt -> binf("+") -> numify(),  $inf, "numify of +Inf");
is(Math::BigInt -> binf("-") -> numify(), -$inf, "numify of -Inf");
is(Math::BigInt -> bnan()    -> numify(),  $nan, "numify of NaN");

###############################################################################

SKIP: {
    skip "insufficient 64 bit integer support", 4
      unless ($Config::Config{ptrsize} == 8 &&
              $] >= 5.008                   &&
              ($Config::Config{use64bitint} ||
               $Config::Config{use64bitall}));

    # The following should not give "1.84467440737096e+19".

    {
        my $x = Math::BigInt -> new(2) -> bpow(64) -> bdec();
        is($x -> bstr(),   "18446744073709551615",
           "Math::BigInt 2**64-1 as string");
        is($x -> numify(), "18446744073709551615",
           "Math::BigInt 2**64-1 as number");
    }

    # The following should not give "-9.22337203685478e+18".

    {
        my $x = Math::BigInt -> new(2) -> bpow(63) -> bneg();
        is($x -> bstr(),   "-9223372036854775808",
           "Math::BigInt -2**63 as string");
        is($x -> numify(), "-9223372036854775808",
           "Math::BigInt -2**63 as number");
    }
}
