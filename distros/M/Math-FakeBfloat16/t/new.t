use strict;
use warnings;
use Math::FakeBfloat16 qw(:all);

use Test::More;

my($have_gmpf, $have_gmpq) = (0, 0);

eval { require Math::GMPf };
$have_gmpf = 1 unless $@;

eval { require Math::GMPq };
$have_gmpq = 1 unless $@;

my @inputs = ('1.5', '-1.75', 2.625, Math::MPFR->new(3.875), 42);

#push(@inputs, Math::GMPf->new(5.25)) if $have_gmpf;
push(@inputs, Math::GMPq->new('3/4')) if $have_gmpq;

for my $in(@inputs) {
  cmp_ok(bf16_to_NV(Math::FakeBfloat16->new($in)), '==', $in, "bf16_to_NV: $in ok");
  cmp_ok(bf16_to_MPFR(Math::FakeBfloat16->new($in)), '==', $in, "bf16_to_MPFR: $in ok");

  cmp_ok(bf16_to_NV(Math::FakeBfloat16->new(-$in)), '==', -$in, "bf16_to_NV: -$in ok");
  cmp_ok(bf16_to_MPFR(Math::FakeBfloat16->new(-$in)), '==', -$in, "bf16_to_MPFR: -$in ok");
}

if($have_gmpf) {
  # There's no overloading of '==' between Math::MPFR and Math::GMPf
  my $in = Math::GMPf->new(5.25);
  cmp_ok(bf16_to_MPFR(Math::FakeBfloat16->new($in)),  '==', Math::MPFR->new($in),  "bf16_to_MPFR from GMPf: $in ok");
  cmp_ok(bf16_to_MPFR(Math::FakeBfloat16->new(-$in)), '==', Math::MPFR->new(-$in), "bf16_to_MPFR from GMPf: -$in ok");
}

cmp_ok(ref(Math::FakeBfloat16->new()), 'eq', 'Math::FakeBfloat16', "Math::FakeBfloat16->new() returns a Math::FakeBfloat16 object");
cmp_ok(ref(Math::FakeBfloat16::new()), 'eq', 'Math::FakeBfloat16', "Math::FakeBfloat16::new() returns a Math::FakeBfloat16 object");


cmp_ok(is_bf16_nan(Math::FakeBfloat16->new()), '==', 1, "Math::FakeBfloat16->new() returns NaN");
cmp_ok(is_bf16_nan(Math::FakeBfloat16::new()), '==', 1, "Math::FakeBfloat16::new() returns NaN");

my $obj = Math::FakeBfloat16->new('1.414');
cmp_ok(Math::FakeBfloat16->new($obj), '==', $obj, "new(obj) == obj");
cmp_ok(Math::FakeBfloat16->new($obj), '==', '1.414', "new(obj) == value of obj");

my $mpfr_obj = Math::MPFR->new();
Math::MPFR::Rmpfr_set_inf($mpfr_obj, 1);
#print "$mpfr_obj\n";
my $pinf = Math::FakeBfloat16->new($mpfr_obj);
cmp_ok(is_bf16_inf($pinf), '==', 1, "+Inf, as expected");

Math::MPFR::Rmpfr_set_inf($mpfr_obj, -1);
my $ninf = Math::FakeBfloat16->new($mpfr_obj);
cmp_ok(is_bf16_inf($ninf), '==', -1, "-Inf, as expected");

Math::MPFR::Rmpfr_set_si($mpfr_obj, -1, 0);
my $not_inf = Math::FakeBfloat16->new($mpfr_obj);
cmp_ok(is_bf16_inf($not_inf), '==', 0, "Not an infinity");
cmp_ok(is_bf16_zero($not_inf), '==', 0, "Not a zero");

Math::MPFR::Rmpfr_set_zero($mpfr_obj, 1);
my $pzero = Math::FakeBfloat16->new($mpfr_obj);
cmp_ok(is_bf16_zero($pzero), '==', 1, "+0, as expected");

Math::MPFR::Rmpfr_set_zero($mpfr_obj, -1);
my $nzero = Math::FakeBfloat16->new($mpfr_obj);
cmp_ok(is_bf16_zero($nzero), '==', -1, "-0, as expected");

done_testing();
