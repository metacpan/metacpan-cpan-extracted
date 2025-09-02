use strict;
use warnings;
use Math::FakeBfloat16 qw(:all);

use Test::More;

my $nan = Math::FakeBfloat16->new();
cmp_ok( (is_bf16_nan($nan)), '==', 1, "new obj is NaN");

bf16_nextabove($nan);
cmp_ok( (is_bf16_nan($nan)), '==', 1, "next above NaN is NaN");

bf16_nextbelow($nan);
cmp_ok( (is_bf16_nan($nan)), '==', 1, "next below NaN is NaN");

my $pinf = Math::FakeBfloat16->new();

bf16_set_inf($pinf, 1);
cmp_ok( (is_bf16_inf($pinf)), '==', 1, "+inf is inf");

bf16_nextbelow($pinf);
cmp_ok( (is_bf16_inf($pinf)), '==', 0, "next below +inf is not inf");
cmp_ok( $pinf, '==', '3.39e38' , "next below +inf is 3.39e38");

bf16_nextabove($pinf);
cmp_ok( (is_bf16_inf($pinf)), '==', 1, "next above 3.39e38 is inf");

my $pmin = $Math::FakeBfloat16::bf16_DENORM_MIN;
cmp_ok($pmin, '==', '9.184e-41', "+min is 9.184e-41");

bf16_nextbelow($pmin);
cmp_ok($pmin, '==', 0, "next below +min is zero");
cmp_ok( (is_bf16_zero($pmin)), '==', 1, "next below +min is unsigned zero");

bf16_nextabove($pmin);
cmp_ok($pmin, '==', $Math::FakeBfloat16::bf16_DENORM_MIN, "next above zero is DENORM_MIN");

my $ninf = -$pinf;
cmp_ok( (is_bf16_inf($ninf)), '==', -1, "inf is -inf");

bf16_nextabove($ninf);
cmp_ok( (is_bf16_inf($ninf)), '==', 0, "next above -inf is not inf");
cmp_ok( $ninf, '==', -$Math::FakeBfloat16::bf16_NORM_MAX , "next above -inf is -NORM_MAX");

bf16_nextbelow($ninf);
cmp_ok( (is_bf16_inf($ninf)), '==', -1, "next below -3.39e38 is -inf");

my $nmin = -$pmin;

bf16_nextabove($nmin);
cmp_ok($nmin, '==', 0, "next above -min is zero");
cmp_ok( (is_bf16_zero($nmin)), '==', -1, "next above -min is -0");

bf16_nextbelow($nmin);
cmp_ok($nmin, '==', -$Math::FakeBfloat16::bf16_DENORM_MIN, "next below zero is -DENORM_MIN");

my $zero =Math::FakeBfloat16->new(0);

#for(127 .. 133) { $max_subnormal += 2 ** -$_ }
my $max_subnormal = $Math::FakeBfloat16::bf16_DENORM_MAX;
cmp_ok($max_subnormal, '==', '1.166e-38', "DENORM_MAX is 1.166e-38");

bf16_nextabove($max_subnormal);
cmp_ok($max_subnormal, '==', $Math::FakeBfloat16::bf16_NORM_MIN, "next above max subnormal is NORM_MIN");

bf16_nextbelow($max_subnormal);
cmp_ok($max_subnormal, '==', $Math::FakeBfloat16::bf16_DENORM_MAX, "next below NORM_MIN is DENORM_MAX");

my $neg_normal_min = -$Math::FakeBfloat16::bf16_NORM_MIN;
bf16_nextabove($neg_normal_min);
cmp_ok($neg_normal_min, '==', -$Math::FakeBfloat16::bf16_DENORM_MAX, "next above -NORM_MIN is -DENORM_MAX");

my $min        = Math::FakeBfloat16->new("$Math::FakeBfloat16::bf16_DENORM_MIN");
my $cumulative = Math::FakeBfloat16->new("$Math::FakeBfloat16::bf16_DENORM_MIN");

my @p = ($cumulative);
my $n = 2 ** (bf16_MANTBITS - 1);
$n--;
for(1..$n) {
   $cumulative += $min;
   push (@p, $cumulative);
}

my $check = Math::FakeBfloat16->new(0);

for(0..$n) {
  bf16_nextabove($check);
  cmp_ok($check, '==', $p[$_], "$_: as expected ($p[$_])");
}

bf16_nextbelow($check);
cmp_ok($check, '==', $Math::FakeBfloat16::bf16_DENORM_MAX, "DENORM_MAX as expected");

bf16_nextbelow($check);
cmp_ok($check, '==', $Math::FakeBfloat16::bf16_DENORM_MAX - $Math::FakeBfloat16::bf16_DENORM_MIN, "DENORM_MAX - DENORM_MIN as expected");

bf16_set_zero($check, 1);

for(0..$n) {
  bf16_nextbelow($check);
  cmp_ok($check, '==', -$p[$_], "$_: as expected (-$p[$_])");
}

cmp_ok($check, '==', '-1.175e-38', "\$check is set to -NORM_MIN");

bf16_nextabove($check);
cmp_ok($check, '==', -$Math::FakeBfloat16::bf16_DENORM_MAX, "-DENORM_MAX as expected");

cmp_ok($check, '==', '-1.166e-38', "\$check is set to -DENORM_MAX");

bf16_nextabove($check);
cmp_ok($check, '==', -$Math::FakeBfloat16::bf16_DENORM_MAX + $Math::FakeBfloat16::bf16_DENORM_MIN, "-DENORM_MAX + DENORM_MIN as expected");

done_testing();
