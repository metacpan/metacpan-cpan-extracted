#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 14;

use Math::BigInt;

use Math::Complex;

my $inf = Math::Complex::Inf();
my $nan = $inf - $inf;

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
cmp_ok(Math::BigInt -> new("12345e67") -> numify(), "==", 12345e67,
       qq|Math::BigInt -> new("12345e67") -> numify()|);

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
