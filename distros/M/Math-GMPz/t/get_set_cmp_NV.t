
# Test that Rmpz_get_NV() and Rmpz_set_NV()
# reciprocate as expected.
# Also, provide tests that probe Rmpz_cmp_d()
# and Rmpz_cmp_NV more intensely.
# Finally, test Rmpz_get_d() as it has not
# been tested elsewhere in the test suite.


use strict;
use warnings;
use Config;
use Math::GMPz qw(:mpz NOK_flag);

use Test::More;

my $dd = 0;
$dd = 1 if((2 ** 100) + (2 ** -100) > 2 ** 100); # NV is doubledouble

my $use_mpfr = 0;
eval {require Math::MPFR; Math::MPFR->import(":mpfr"); };
$use_mpfr = 1 unless $@;

my $mpfr_obj;

if($use_mpfr) {
  if($dd) {
    Rmpfr_set_default_prec(2098);
  }
  else {
    Rmpfr_set_default_prec(113);
  }

  $mpfr_obj = Math::MPFR->new();
}

my $z = Math::GMPz->new();

Rmpz_set_NV($z, 123456.0);

cmp_ok(Rmpz_cmp_NV($z, 123456.0), '==', 0, "compares correctly with equivalent double");
cmp_ok(Rmpz_cmp_NV($z, 123455.999), '>', 0, "compares correctly with smaller double");
cmp_ok(Rmpz_cmp_NV($z, 123456.001), '<', 0, "compares correctly with larger double");

################################
################################

my $nv = (2 ** 100) + (2 ** 50);

Rmpz_set_NV($z, $nv);
cmp_ok($nv, '==', Rmpz_get_NV($z), "Rmpz_get_NV returns correct NV");
cmp_ok(Rmpz_cmp_NV($z, $nv), '==', 0, "Rmpz_cmp_NV compares correctly");

Rmpz_set_NV($z, 2.0);
$z **= 16385;

my $t = Rmpz_get_NV($z);

my $is_inf = 0;
$is_inf++ if($t > 0 && $t / $t != 1);

cmp_ok($is_inf, '==', 1, "Rmpz_get_NV() detects and returns 'inf'");
cmp_ok($z, '<', $t, "overloaded comparison 'inf'");
cmp_ok(Rmpz_cmp_NV($z, $t), '<', 0, "Rmpz_cmp_NV compares 'inf' correctly");


Rmpz_set_NV($z, 999.87654321e-3);
cmp_ok($z, '==', 0, "Rmpz_set_NV set correctly for 0 <= NV < 1");

Rmpz_set_NV($z, -999.87654321e-3);
cmp_ok($z, '==', 0, "Rmpz_set_NV set correctly for 0 >= NV > -1");


for(1 .. 5000) {

  my $str = random_string();

  my ($integerize, $check) = (0, 0);

  my $s = $str;
  my $n = $s / 1.0;

  die "$str numifies to zero"
    if $n == 0;

  die "$str numifies to NaN"
    if $n != $n;

  $check = int($n);

  next if $n / $n != 1; # $n is Inf

  if(!NOK_flag($n)) {
    $n = "${n}.0" + 0;
    next if !NOK_flag($n);
  }

  Rmpz_set_NV($z, $n);

  # Rmpfr_set_NV() not implemented until version 3.22.
  if($use_mpfr && $Math::MPFR::VERSION >= 3.22) {

    # With Math-MPFR-4.17 and earlier, Rmpfr_set_NV() croaks
    # unless the NOK flag of $n is set.
    # In some instances here, $n's IOK flag  could be set,
    # and the NOK flag unset.
    # We skip further testing of this $n if those 2 conditions
    # are met :
    next if($Math::MPFR::VERSION < 4.18 && Math::MPFR::_itsa($n) != 3);

    Rmpfr_set_NV($mpfr_obj, $n, 0);
    Rmpfr_rint_trunc($mpfr_obj, $mpfr_obj, 0);
    my $nv_check = Rmpfr_get_NV($mpfr_obj, 0);
    cmp_ok(Rmpz_get_NV($z), '==', $nv_check, "Rmpz_get_NV returns the value that mpfr predicts");

    # If the test that was just run has failed, then we
    # don't bother with running any more tests:
    if(Rmpz_get_NV($z) != $nv_check) {
      warn "$str\n";
      next;
    }
  }

  cmp_ok($z, '==', Math::GMPz->new($n), "Rmpz_set_NV and Rmpz_init_set_NV assign identical values");

  unless($dd) { #  Perl's int() function is buggy on my DoubleDouble builds.

    my $nv = Rmpz_get_NV($z);

    unless($Config{nvsize} == $Config{ivsize} && $] < 5.030 && $nv < 1e20 && $nv > 1e15) {
      # pre-5.30.0 versions of perl might mis-assign values.
      # If a mis-assignment of a value in the (approximate)
      # range 1e15 .. 1e20 occurs on a perl whose ivsize and
      # nvsize are both 8 then this test is invalidated
      # and could register a fail. So we skip it.

      cmp_ok($nv, '==', $check, "Rmpz_get_NV handles $str correctly" );
    }

    if(NOK_flag($check)) {
      cmp_ok(Rmpz_cmp_NV($z, $check), '==', 0, "Rmpz_cmp_NV compares $str correctly");
    }
    else {
      eval { Rmpz_cmp_NV($z, $check);};
      like($@, qr/In Rmpz_cmp_NV, 2nd argument is not an NV/, "Rmpz_cmp_NV croaks when 2nd arg is is not NOK");
    }
  }

  if($z != $n) {
    # For positive values only
    cmp_ok(Rmpz_cmp_NV($z, $n), '<', 0, "$z is less than $n");
    cmp_ok(Rmpz_cmp_NV($z + 1, $n), '>', 0, "$z + 1 is greater than $n");
  }

  cmp_ok(Rmpz_cmp_NV($z, Rmpz_get_NV($z)), '==', 0, "Rmpz_cmp_NV affirms Rmpz_get_NV is retrieving value correctly");
}

my $dbl_max = 0;
for(971 .. 1023) { $dbl_max += 2 ** $_ }
my $dbl_min = -$dbl_max;
my $dbl_next = 2 ** 970;

my $mpz_pos = Math::GMPz->new($dbl_max);
my $mpz_neg = Math::GMPz->new($dbl_min);

$mpz_pos += Math::GMPz->new($dbl_next);
$mpz_neg -= Math::GMPz->new($dbl_next);

my $nv_pos = Rmpz_get_NV($mpz_pos);
my $nv_neg = Rmpz_get_NV($mpz_neg);

if($dd) {
  cmp_ok($nv_pos, '>', 0, "Inf > 0");
  cmp_ok($nv_neg, '<', 0, "-Inf < 0");

  if($nv_pos != 0) {
    cmp_ok($nv_pos / $nv_pos, '!=', 1, "is Inf");
  }

  if($nv_neg != 0) {
    cmp_ok($nv_neg / $nv_neg, '!=', 1, "is -Inf");
  }
}
elsif($Config{nvsize} == 8) {
  cmp_ok($nv_pos, '==', $dbl_max, "is DBL_MAX");
  cmp_ok($nv_neg, '==', $dbl_min, "is -DBL_MAX");
}
else {
  cmp_ok($nv_pos, '>', $dbl_max, "> DBL_MAX");
  cmp_ok($nv_neg, '<', $dbl_min, "< -DBL_MAX");
}

unless($Config{nvsize} == 8 || $dd) { # Skip these tests for 'double' and 'doubledouble'
                                      # as the values we're testing here are all Inf on
                                      # on those configurations.

  for(1 .. 100) {

    my $str = random_string_big_exponent();

    my $s = $str;
    my $n = $s / 1.0;

    die "$str numifies to zero"
      if $n == 0;

    die "$str numifies to NaN"
      if $n != $n;

    next if $n / $n != 1; # $n is Inf

    Rmpz_set_NV($z, $n);

    cmp_ok($z, '==', Math::GMPz->new($n), "Rmpz_set_NV and Rmpz_init_set_NV assign identical values");
    cmp_ok(Rmpz_get_NV($z), '==', int($n), "Rmpz_get_NV handles $str correctly" );
    cmp_ok(Rmpz_cmp_NV($z, int($n) / 1.0), '==', 0, "Rmpz_cmp_NV compares $str correctly");
    cmp_ok(Rmpz_cmp_NV($z, Rmpz_get_NV($z)), '==', 0, "Rmpz_cmp_NV affirms Rmpz_get_NV is retrieving value correctly");

  }
}

done_testing();

sub random_string {
 my $str = '1.';
 for(1 .. 36) { $str .= int(rand(10)) }

 $str .= 'e' . int(rand(500));

 return $str;
}

sub random_string_big_exponent {
 my $str = '1.';
 for(1 .. 36) { $str .= int(rand(10)) }

 $str .= 'e' . (int(rand(1000)) + 4000);

 return $str;
}

__END__
1.545143676791001168350990143070476153e19
1.088355858462611894930586880325393409e19
1.147387420406408722255266019251435023e18
1.069080449043293909274989126610866662e17
