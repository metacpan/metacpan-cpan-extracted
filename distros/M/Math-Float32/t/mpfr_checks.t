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
       " Installing Math-MPFR-4.44 or later should enable the running of this script.\n";
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

my $bsd = 0;
$bsd = 1 if $^O =~ /bsd/i; # Attempt to make allowance for *BSD sloppiness.

my $emin_orig = Math::MPFR::Rmpfr_get_emin();
my $emax_orig  = Math::MPFR::Rmpfr_get_emax();
Math::MPFR::Rmpfr_set_default_prec(flt_MANTBITS);

my $flt_rop = Math::Float32->new();
my $mpfr_rop = Math::MPFR->new();
my $mpfr_toward = Math::MPFR->new(0);
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
  if(!$bsd || $flt_rop == log($flt_1)) {
    cmp_ok(log($flt_1), '==', $flt_rop,  "log($v): Math::MPFR & Math::Float32 concur");
  }
  else { # Allow log($flt_1) to be 1ULP away from the correct value. (BSD systems only.)
    if($flt_rop > log($flt_1)) {
      flt_nextbelow($flt_rop);
    }
    else {
      flt_nextabove($flt_rop);
    }
    cmp_ok(log($flt_1), '==', $flt_rop, "log($v): On $^O, accept that the Math::Float32 calculation is off by 1ULP");
  }
}

for my $v(@p) {
  my $flt_1 = Math::Float32->new($v);
  Math::MPFR::Rmpfr_set_FLT($mpfr_rop, $flt_1, 0);
  SET_EMIN_EMAX();
  my $inex = Math::MPFR::Rmpfr_exp($mpfr_rop, $mpfr_rop, 0);
  Math::MPFR::Rmpfr_subnormalize($mpfr_rop, $inex, 0);
  RESET_EMIN_EMAX();
  Math::MPFR::Rmpfr_get_FLT($flt_rop, $mpfr_rop, 0);
  if(!$bsd || $flt_rop == exp($flt_1)) {
    cmp_ok(exp($flt_1), '==', $flt_rop,, "exp($v): Math::MPFR & Math::Float32 concur");
  }
  else { # Allow exp($flt_1) to be 1ULP away from the correct value. (BSD systems only.)
    if($flt_rop > exp($flt_1)) {
      flt_nextbelow($flt_rop);
    }
    else {
      flt_nextabove($flt_rop);
    }
    cmp_ok(exp($flt_1), '==', $flt_rop, "exp($v): On $^O, accept that the Math::Float32 calculation is off by 1ULP");
  }
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
    if(!$bsd || $flt_rop == $flt_1 ** "$pow") {
      cmp_ok( $flt_1 ** "$pow", '==', $flt_rop, "$v ** '$pow': Math::MPFR & Math::Float32 concur");
    }
    else { # Allow $flt_1 ** "$pow" to be 1ULP away from the correct value. (BSD systems only.)
    if($flt_rop > $flt_1 ** "$pow") {
      flt_nextbelow($flt_rop);
    }
    else {
      flt_nextabove($flt_rop);
    }
      cmp_ok($flt_1 ** "$pow", '==', $flt_rop, "$v ** '$pow': On $^O, accept that the Math::Float32 calculation is off by 1ULP");
    }
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

t/mpfr_checks.t ..... 1/?
#   Failed test 'exp(5.2): Accept that Math::MPFR & Math::Float32 differ by 1ULP'
#   at t/mpfr_checks.t line 119.
#          got: 181.27219
#     expected: 181.27222

#   Failed test '1.40129846432482e-44 ** '4.00000006e-1': Accept that Math::MPFR & Math::Float32 differ by 1ULP'
#   at t/mpfr_checks.t line 140.
#          got: 2.8748286e-18
#     expected: 2.874829e-18

#   Failed test '1.1754944e-38 ** '4.00000006e-1': Accept that Math::MPFR & Math::Float32 differ by 1ULP'
#   at t/mpfr_checks.t line 140.
#          got: 6.7311294e-16
#     expected: 6.7311305e-16
# Looks like you failed 3 tests of 545.

############################################################
############################################################
sis@sisyphus:~/pscrpt $ perl mpfr_checks.pl 1>nul
#   Failed test 'log(5.2): Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 98.
#          got: 1.64865863
#     expected: 1.64865851
#   Failed test 'exp(5.2): Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 115.
#          got: 181.272202
#     expected: 181.272217
#   Failed test '1.40129846432482e-44 ** '4.00000006e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 2.87482879e-18
#     expected: 2.874829e-18
#   Failed test '1.17549435e-38 ** '4.00000006e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 6.73112996e-16
#     expected: 6.73113049e-16
#   Failed test '1.40129846432482e-44 ** '6.00000024e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 4.87435728e-27
#     expected: 4.8743569e-27
#   Failed test '5.2 ** '6.00000024e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 2.68906951
#     expected: 2.68906927
#   Failed test '27.2 ** '6.00000024e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 7.25673723
#     expected: 7.25673676
#   Failed test '1.40129846432482e-44 ** '6.99999988e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 2.00711382e-31
#     expected: 2.00711358e-31
#   Failed test '27.2 ** '8.00000012e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 14.0493155
#     expected: 14.0493145
#   Failed test '1.17549435e-38 ** '8.99999976e-1': Math::MPFR & Math::Float32 concur'
#   at mpfr_checks.pl line 136.
#          got: 7.29792524e-35
#     expected: 7.29792466e-35
# Looks like you failed 10 tests of 545.
