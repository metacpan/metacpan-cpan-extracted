
# Performing shift operations on floating-point types is not
# permitted under IEEE standards.
# Here, we simply overload the '<<' and '>>' operators to
# increase/decrease the exponent by the given "shift" amount.
# Effectively, we are multiplying/dividing the value held in
# the Math::MPFR object by 2**$hift.
# This is precisely what happens when we left-shift/right-shift
# an integer value.

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Test::More;

my $f = Math::MPFR->new() << 10;
cmp_ok(Rmpfr_nan_p($f), '!=', 0, "'<<' NaN results in NaN");

$f = Math::MPFR->new() >> 10;
cmp_ok(Rmpfr_nan_p($f), '!=', 0, "'>>' NaN results in NaN");

Rmpfr_set_inf($f, 0);

my $n = $f << 10;
cmp_ok(Rmpfr_inf_p($f), '!=', 0, "'<<' Inf results in Inf");

$n = $f >> 10;
cmp_ok(Rmpfr_inf_p($f), '!=', 0, "'>>' Inf results in Inf");

Rmpfr_set_NV($f, 0.0, MPFR_RNDN);

my $n = $f << 10;
cmp_ok(Rmpfr_zero_p($f), '!=', 0, "'<<' 0 results in 0");

$n = $f >> 10;
cmp_ok(Rmpfr_zero_p($f), '!=', 0, "'>>' 0 results in 0");

Rmpfr_set_NV($f, 4.625, MPFR_RNDN);

cmp_ok($f << 2, '==', 18.5, "4.625 << 2 results in 18.5");
cmp_ok($f, '==', Math::MPFR->new(18.5) >> 2, "18.5 >> 2 results in 4.625");

$f <<= 3;

cmp_ok($f, '==', 37, "4.625 << 3 results in 37");

$f >>= 3;
cmp_ok($f, '==', 4.625, "37 >> 3 results in 4.625");

cmp_ok($f >> -2, '==', 18.5, "4.625 >> -2 results in 18.5");
cmp_ok($f, '==', Math::MPFR->new(18.5) << -2, "18.5 << -2 results in 4.625");

$f >>= -3;

cmp_ok($f, '==', 37, "4.625 >> -3 results in 37");

$f <<= -3;
cmp_ok($f, '==', 4.625, "37 << -3 results in 4.625");

eval {$f >> '3'};
like ($@, qr/In overloading of '>>' operator,/, "'>>' doesn't accept a string");

eval {$f << 3.1};
like ($@, qr/In overloading of '<<' operator,/, "'<<' doesn't accept an NV");

eval {$f >>= 3.1};
like ($@, qr/In overloading of '>>=' operator,/, "'>>=' doesn't accept an NV");

eval {$f <<= '3'};
like ($@, qr/In overloading of '<<=' operator,/, "'<<=' doesn't accept a string");

done_testing();
