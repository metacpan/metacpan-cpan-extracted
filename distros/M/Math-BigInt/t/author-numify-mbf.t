#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print "1..0 # SKIP these tests are for testing by the author";
        exit;
    }
}

use strict;
use warnings;

use Test::More tests => 9;

use Math::BigFloat;

use Math::Complex;

my $inf = Math::Complex::Inf();
my $nan = $inf - $inf;

###############################################################################
# Check numify() on finite values.

{
    my $x = Math::BigFloat -> new("0.008");
    my $y = Math::BigFloat -> new(2);
    $x -> bdiv(3, $y);
    cmp_ok($x, "==", "0.0027",
           qq|\$x = Math::BigFloat -> new("0.008");|
         . qq| \$y = Math::BigFloat -> new(2); \$x -> bdiv(3, \$y);|);

    cmp_ok(Math::BigFloat -> new("12345e67") -> numify(), "==", 1.2345e71,
           qq|Math::BigFloat -> new("12345e67") -> numify()|);
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
