use strict;
use warnings;

use Math::Float32 qw(:all);

use Test::More;

use constant EMIN_MOD  => flt_EMIN;
use constant EMAX_MOD  => flt_EMAX;

eval{ require Math::MPFR;};
if($@) {
  warn "\n Aborting this test script:\n",
       " This test script needs Math-MPFR-4.44 but Math-MPFR failed to load.\n",
       " Installing Math-MPFR-4.44 or later should enable the running of this script.\n",
       " If Math-MPFR-4.44 is not yet on CPAN, install the devel version from the github repo\n at https://github.com/sisyphus/math-mpfr\n";
       is(1, 1);
       done_testing();
       exit 0;
}

if($Math::MPFR::VERSION < 4.44) {
  warn "\n Aborting this test script:\n",
       " This test script needs Math-MPFR-4.44 but we have only version $Math::MPFR::VERSION\n",
       " If Math-MPFR-4.44 is not yet on CPAN, install the devel version from the github repo\n at https://github.com/sisyphus/math-mpfr\n";
       is(1, 1);
       done_testing();
       exit 0;
}

my $emin_orig = Math::MPFR::Rmpfr_get_emin();
my $emax_orig  = Math::MPFR::Rmpfr_get_emax();
Math::MPFR::Rmpfr_set_default_prec(flt_MANTBITS);

my $flt_rop = Math::Float32->new();
my $mpfr_rop = Math::MPFR->new();
my $mpfr1 = Math::MPFR->new();
my $mpfr2 = Math::MPFR->new();

my @p = (  (2 ** (flt_EMIN -1)),
           (2 ** flt_EMIN) + (2 ** (flt_EMIN + 2)),
           "$Math::Float32::flt_NORM_MIN",
           "$Math::Float32::flt_NORM_MAX",
           "$Math::Float32::flt_DENORM_MIN",
           "$Math::Float32::flt_DENORM_MAX",
            '2.2', '3.2', '5.2', '27.2',
        );

for my $v(@p) {
  my $flt_1 = Math::Float32->new($v);
  Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
  SET_EMIN_EMAX();
  my $inex = Math::MPFR::Rmpfr_sqrt($mpfr_rop, $mpfr_rop, 0);
  Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
  RESET_EMIN_EMAX();
  Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
  cmp_ok($flt_rop, '==', sqrt($flt_1), "sqrt($v): Math::MPFR & Math::Float32 concur");
}

for my $v1(@p) {
  my $flt_1 = Math::Float32->new($v1);
  Math::MPFR::Rmpfr_set_FLT($mpfr1, $flt_1, 0);
  for my $v2(@p) {
    my $flt_2 = Math::Float32->new($v2);
    Math::MPFR::Rmpfr_set_FLT($mpfr2, $flt_2, 0);
    SET_EMIN_EMAX();
    my $inex = Math::MPFR::Rmpfr_fmod($mpfr_rop, $mpfr1, $mpfr2, 0);
    Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
    RESET_EMIN_EMAX();
    Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
    cmp_ok($flt_rop, '==', $flt_1 % $flt_2, "fmod($v1, $v2): Math::MPFR & Math::Float32 concur");
  }
}

for my $v(@p) {
  my $flt_1 = Math::Float32->new($v);
  Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
  SET_EMIN_EMAX();
  my $inex = Math::MPFR::Rmpfr_sqr($mpfr_rop, $mpfr_rop, 0);
  Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
  RESET_EMIN_EMAX();
  Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
  cmp_ok($flt_rop, '==', $flt_1 ** 2, "$v ** 2: Math::MPFR & Math::Float32 concur");
}

for my $v(@p) {
  my $flt_1 = Math::Float32->new($v);
  Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
  SET_EMIN_EMAX();
  my $inex = Math::MPFR::Rmpfr_log($mpfr_rop, $mpfr_rop, 0);
  Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
  RESET_EMIN_EMAX();
  Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
  cmp_ok($flt_rop, '==', log($flt_1), "log($v): Math::MPFR & Math::Float32 concur");
}

for my $v(@p) {
  my $flt_1 = Math::Float32->new($v);
  Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
  SET_EMIN_EMAX();
  my $inex = Math::MPFR::Rmpfr_exp($mpfr_rop, $mpfr_rop, 0);
  Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
  RESET_EMIN_EMAX();
  Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
  cmp_ok($flt_rop, '==', exp($flt_1), "exp($v): Math::MPFR & Math::Float32 concur");
}

my @powers = ('0.1', '0.2', '0.3', '0.4', '0.6', '0.7', '0.8', '0.9');

for my $p(@powers) {
  my $pow = Math::MPFR->new($p);
  for my $v(@p) {
    my $flt_1 = Math::Float32->new($v);
    Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
    SET_EMIN_EMAX();
    my $inex = Math::MPFR::Rmpfr_pow($mpfr_rop, $mpfr_rop, $pow, 0);
    Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
    RESET_EMIN_EMAX();
    Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
    cmp_ok($flt_rop, '==', $flt_1 ** "$pow", "$v ** '$pow': Math::MPFR & Math::Float32 concur");
  }
}

for my $p(@powers) {
  my $pow = Math::MPFR->new($p);
  for my $v(@p) {
    my $flt_1 = Math::Float32->new($v);
    Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
    SET_EMIN_EMAX();
    my $inex = Math::MPFR::Rmpfr_mul($mpfr_rop, $mpfr_rop, $pow, 0);
    Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
    RESET_EMIN_EMAX();
    Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
    cmp_ok($flt_rop, '==', $flt_1 * "$pow", "'$v * $pow': Math::MPFR & Math::Float32 concur");
  }
}

for my $p(@powers) {
  my $pow = Math::MPFR->new($p);
  for my $v(@p) {
    my $flt_1 = Math::Float32->new($v);
    Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
    SET_EMIN_EMAX();
    my $inex = Math::MPFR::Rmpfr_div($mpfr_rop, $mpfr_rop, $pow, 0);
    Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
    RESET_EMIN_EMAX();
    Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
    cmp_ok($flt_rop, '==', $flt_1 / "$pow", "$v / '$pow': Math::MPFR & Math::Float32 concur");
  }
}

for my $p(@powers) {
  my $pow = Math::MPFR->new($p);
  for my $v(@p) {
    my $flt_1 = Math::Float32->new($v);
    Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
    SET_EMIN_EMAX();
    my $inex = Math::MPFR::Rmpfr_add($mpfr_rop, $mpfr_rop, $pow, 0);
    Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
    RESET_EMIN_EMAX();
    Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
    cmp_ok($flt_rop, '==', $flt_1 + "$pow", "$v + '$pow': Math::MPFR & Math::Float32 concur");
  }
}

for my $p(@powers) {
  my $pow = Math::MPFR->new($p);
  for my $v(@p) {
    my $flt_1 = Math::Float32->new($v);
    Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
    SET_EMIN_EMAX();
    my $inex = Math::MPFR::Rmpfr_sub($mpfr_rop, $mpfr_rop, $pow, 0);
    Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
    RESET_EMIN_EMAX();
    Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
    cmp_ok($flt_rop, '==', $flt_1 - "$pow", "$v - '$pow': Math::MPFR & Math::Float32 concur");
  }
}

# Test that Math::MPFR::subnormalize_float32
# fixes a known double-rounding anomaly.
# Requires Math-MPFR-4.44 or later.

my $s = '2.10194765e-45';
my $round = 0; # MPFR_RNDN
my $mpfr_anom1 = Math::MPFR::Rmpfr_init2(8);
Math::MPFR::Rmpfr_strtofr($mpfr_anom1, $s, 10, 0); # RNDN
my $anom1 = Math::Float32->new($s);
cmp_ok(unpack_flt_hex($anom1), 'eq', '00000001', "direct assignment results in '00000001'");
cmp_ok(Math::MPFR::unpack_float32($mpfr_anom1, $round), 'eq', '00000002', "indirect assignment results in '00000002'");
cmp_ok($anom1, '!=', Math::Float32->new("$mpfr_anom1"), "double-checked: values are different");
my $mpfr_anom2 = Math::MPFR::subnormalize_float32($s);
cmp_ok(Math::MPFR::unpack_float32($mpfr_anom2, $round), 'eq', '00000001', "Math::MPFR::subnormalize_float32() ok");
cmp_ok($anom1, '==', Math::Float32->new("$mpfr_anom2"), "double-checked: values are equivalent");

done_testing();

sub SET_EMIN_EMAX {
  Math::MPFR::Rmpfr_set_emin(EMIN_MOD);
  Math::MPFR::Rmpfr_set_emax(EMAX_MOD);
}

sub RESET_EMIN_EMAX {
  Math::MPFR::Rmpfr_set_emin($emin_orig);
  Math::MPFR::Rmpfr_set_emax($emax_orig);
}
__END__
