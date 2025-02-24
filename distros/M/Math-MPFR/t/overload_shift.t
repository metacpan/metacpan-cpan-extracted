
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
use Math::BigFloat; # Aiming to emulate Math::BigFloat in Math::MPFR.
use Config;

use Test::More;

my $f = Math::MPFR->new() << 10;
cmp_ok(Rmpfr_nan_p($f), '!=', 0, "NaN << returns NaN");

$f = Math::MPFR->new() >> 10;
cmp_ok(Rmpfr_nan_p($f), '!=', 0, "NaN >> returns NaN");

$f <<= 10;
cmp_ok(Rmpfr_nan_p($f), '!=', 0, "NaN <<= returns NaN");

$f >>= 10;
cmp_ok(Rmpfr_nan_p($f), '!=', 0, "NaN <<= returns NaN");

Rmpfr_set_inf($f, 0);

my $n = $f << 10;
cmp_ok(Rmpfr_inf_p($n), '!=', 0, "+Inf << returns Inf");
cmp_ok($n, '>', 0, "+Inf << returns +Inf");

$n = $f >> 10;
cmp_ok(Rmpfr_inf_p($n), '!=', 0, "+Inf >> returns Inf");
cmp_ok($n, '>', 0, "+Inf >> returns +Inf");

$f <<= 10;
cmp_ok(Rmpfr_inf_p($f), '!=', 0, "+Inf <<= returns Inf");
cmp_ok($f, '>', 0, "+Inf <<= returns +Inf");

$f >>= 10;
cmp_ok(Rmpfr_inf_p($f), '!=', 0, "+Inf >>= returns Inf");
cmp_ok($f, '>', 0, "-Inf >>= returns +Inf");


my $fneg = Math::MPFR->new();
Rmpfr_set_inf($fneg, -1);
##########################
$n = $fneg << 10;
cmp_ok(Rmpfr_inf_p($n), '!=', 0, "-Inf << returns Inf");
cmp_ok($n, '<', 0, "-Inf << returns -Inf");

$n = $fneg >> 10;
cmp_ok(Rmpfr_inf_p($n), '!=', 0, "-Inf >> returns Inf");
cmp_ok($n, '<', 0, "-Inf >> returns -Inf");

$fneg <<= 10;
cmp_ok(Rmpfr_inf_p($f), '!=', 0, "-Inf <<= returns Inf");
cmp_ok($fneg, '<', 0, "-Inf <<= returns -Inf");

$fneg >>= 10;
cmp_ok(Rmpfr_inf_p($f), '!=', 0, "-Inf >>= returns Inf");
cmp_ok($fneg, '<', 0, "-Inf >>= returns -Inf");

Rmpfr_set_NV($f, 0.0, MPFR_RNDN);

$n = $f << 10;
cmp_ok(Rmpfr_zero_p($f), '!=', 0, "'<<' 0 results in 0");

$n = $f >> 10;
cmp_ok(Rmpfr_zero_p($f), '!=', 0, "'>>' 0 results in 0");

my $samples = 10;
my($mpfr_res, $mbf_res);
my @values;
for(1 .. $samples) {push @values, rand(10000)}

my @shifts;
for(1 .. $samples) {push @shifts, int(rand(40)) - 20}

$samples--;
for my $i(0 .. $samples) {
  my $obj = Math::MPFR->new($values[$i]);
  my $mbf = Math::BigFloat->new($values[$i]);
  my $shift = $shifts[$i];
  cmp_ok($obj << $shift, '==', $obj >> -$shift, "A: $obj: handled consistently by << and >>");
  cmp_ok($obj << -$shift, '==', $obj >> $shift, "B: $obj: handled consistently by << and >>");

  if($] >= 5.04) {
    $mpfr_res = $obj << $shift;
    $mbf_res = $mbf << $shift;
    cmp_ok("$mpfr_res", '==', "$mbf_res", "<<: Math::BigFloat and Math::MPFR concur");

    $mpfr_res = $obj >> $shift;
    $mbf_res = $mbf >> $shift;
    cmp_ok("$mpfr_res", '==', "$mbf_res", ">>: Math::BigFloat and Math::MPFR concur");
  }

  my($x, $y) = ($obj + 10, $obj + 10);
  $x <<= $shift;
  $y >>= -$shift;
  cmp_ok($x, '==', $y, "A: $obj: handled consistently by <<= and >>=");
  $x <<= -$shift;
  $y >>= $shift;
   cmp_ok($x, '==', $y, "B: $obj: handled consistently by <<= and >>=");
 }


cmp_ok(Math::MPFR->new(-401.3) >> 1.8, '==', -201, "-401.3 >> 1.8 == -201");
cmp_ok(Math::MPFR->new(-401.3) >> 1.8, '==', -201, "-401.3 << -1.8 == -201");


eval { my $discard = 2 >> Math::MPFR->new(7);};
like($@, qr/argument that specifies the number of bits to be/, "switched overload throws expected error");

eval {my $discard = $f >> Math::BigFloat->new(7);};
like($@, qr/argument that specifies the number of bits to be/, "Math::BigFloat shift arg throws expected error with '>>'");

eval {$f <<= Math::BigInt->new(7);};
like($@, qr/argument that specifies the number of bits to be/, "Math::BigFloat shift arg throws expected error with '<<='");

if($Config{longsize} < $Config{ivsize}) {
  eval { my $discard = $f >> ~0;};
  like ( $@, qr/In Math::MPFR overloading of '>>' operator,/, "mp_bitcnt_t overflow is caught in '>>'");

  eval { my $discard = $f << ~0;};
  like ( $@, qr/In Math::MPFR overloading of '<<' operator,/, "mp_bitcnt_t overflow is caught in '<<'");

  eval { $f >>= ~0;};
  like ( $@, qr/In Math::MPFR overloading of '>>=' operator,/, "mp_bitcnt_t overflow is caught in '>>='");

  eval { $f <<= ~0;};
  like ( $@, qr/In Math::MPFR overloading of '<<=' operator,/, "mp_bitcnt_t overflow is caught in '<<='");
}




done_testing();
