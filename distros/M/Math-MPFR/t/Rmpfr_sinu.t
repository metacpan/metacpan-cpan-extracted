# Test file for Rmpfr_sinu(), Rmpfr_cosu(), Rmpfr_tanu(),
# and also for Rmpfr_sinpi(), Rmpfr_cospi() and Rmpfr_tanpi()

use strict;
use warnings;
use Config;
use Test::More;
use Math::MPFR qw(:mpfr);

# For testing, set mpfr default precision
# to the same value as NV precision

my $default_prec = 53;
if($Config{nvsize} > 8) {
  if($Config{nvtype} eq '__float128' || Math::MPFR::_have_IEEE_754_long_double()) {
    $default_prec = 113;
  }
  else { $default_prec = 64 }
}
Rmpfr_set_default_prec($default_prec);

my $rop1 = Math::MPFR->new();
my $rop2 = Math::MPFR->new();
my $pinf = Math::MPFR->new();

Rmpfr_set_inf($pinf, 1);
my $ninf = $pinf * -1;

if(MPFR_VERSION() >= 262656) {
  # Rmpfr_sinu() and Rmpfr_cosu are available

  # With Rmpfr_sinu, when 2*$op divided by the third argument is an integer,
  # $rop should be set to 0 (-0 if $op is negative).

  Rmpfr_sinu($rop1, Math::MPFR->new(6), 3, MPFR_RNDN);
  cmp_ok( "$rop1", 'eq', '0', 'Rmpfr_sinu: Get 0 when 2*$op/3 is +ve integer');

  Rmpfr_sinu($rop1, Math::MPFR->new(-12), 4, MPFR_RNDN);
  cmp_ok( "$rop1", 'eq', '-0', 'Rmpfr_sinu: Get -0 when 2*$op/4 is -ve integer');

  # For Rmpfr_cosu, when 2*$op divided by the third argument is a half-integer,
  # $rop should be set to zero, irrespective of the sign of $op.

  Rmpfr_cosu($rop1, Math::MPFR->new(5), 4, MPFR_RNDN);
  cmp_ok( "$rop1", 'eq', '0', 'Rmpfr_cosu: Get 0 when 2*$op/4 is a +ve half-integer');

  Rmpfr_cosu($rop1, Math::MPFR->new(-6.5), 2, MPFR_RNDN);
  cmp_ok( "$rop1", 'eq', '0', 'Rmpfr_cosu: Get 0 when 2*$op/2 is a -ve half-integer');

  my $op1 = Math::MPFR->new(30);
  my $op2 = Math::MPFR->new(60);

  Rmpfr_sinu($rop1, $op1, 360, MPFR_RNDN);
  cmp_ok( $rop1, '==', 0.5, "sine of 30 degrees is 0.5");

  Rmpfr_sinu($rop2, $op2, 360, MPFR_RNDN);
  cmp_ok( $rop2, '==', sqrt(3) / 2, "sine of 60 degrees is 0.5 * sqrt(3)");

  Rmpfr_cosu($rop1, $op1, 360, MPFR_RNDN);
  cmp_ok( $rop1, '==', $rop2, "cosine of 30 degrees == sine of 60 degrees");

  Rmpfr_cosu($rop2, $op2, 360, MPFR_RNDN);
  cmp_ok( $rop2, '==', 0.5, "cosine of 60 degrees is 0.5");
##
  Rmpfr_sinpi($rop1, Math::MPFR->new(1), MPFR_RNDN);
  cmp_ok("$rop1", 'eq', '0', 'sinpi(1) is 0');

  Rmpfr_sinpi($rop1, Math::MPFR->new(-1), MPFR_RNDN);
  cmp_ok("$rop1", 'eq', '-0', 'sinpi(-1) is -0');

  Rmpfr_sinpi($rop1, Math::MPFR->new(0.5), MPFR_RNDN);
  cmp_ok($rop1, '==', 1, 'sinpi(0.5) is 1');

  Rmpfr_sinpi($rop1, Math::MPFR->new(-0.5), MPFR_RNDN);
  cmp_ok($rop1, '==', -1, 'sinpi(-0.5) is -1');

  SKIP: {
    skip 'USE_QUADMATH builds miscalculate sqrt(0.5) by 1ULP',
         2 if ($Config{nvtype} eq '__float128');
    Rmpfr_sinpi($rop1, Math::MPFR->new(0.25), MPFR_RNDN);
    cmp_ok($rop1, '==', sqrt(0.5), 'sinpi(0.25) == sqrt(0.5)');

    Rmpfr_sinpi($rop1, Math::MPFR->new(-0.25), MPFR_RNDN);
    cmp_ok($rop1, '==', -sqrt(0.5), 'sinpi(0.25) == -sqrt(0.5)');
  }
##
  Rmpfr_cospi($rop1, Math::MPFR->new(1), MPFR_RNDN);
  cmp_ok($rop1, '==', -1, 'cospi(1) is -1');

  Rmpfr_cospi($rop1, Math::MPFR->new(-1), MPFR_RNDN);
  cmp_ok($rop1, '==', -1, 'cospi(-1) is -1');

  Rmpfr_cospi($rop1, Math::MPFR->new(0.5), MPFR_RNDN);
  cmp_ok("$rop1", 'eq', '0', 'cospi(0.5) is 0');

  Rmpfr_cospi($rop1, Math::MPFR->new(-0.5), MPFR_RNDN);
  cmp_ok("$rop1", 'eq', '0', 'cospi(-0.5) is 0');

  SKIP: {
    skip 'USE_QUADMATH builds miscalculate sqrt(0.5) by 1ULP',
         2 if ($Config{nvtype} eq '__float128');
    Rmpfr_cospi($rop1, Math::MPFR->new(0.25), MPFR_RNDN);
    cmp_ok($rop1, '==', sqrt(0.5), 'cospi(0.25) == sqrt(0.5)');

    Rmpfr_cospi($rop1, Math::MPFR->new(-0.25), MPFR_RNDN);
    cmp_ok($rop1, '==', sqrt(0.5), 'cospi(-0.25) == sqrt(0.5)');
  };
##
  Rmpfr_tanpi($rop1, Math::MPFR->new(1), MPFR_RNDN);
  cmp_ok("$rop1", 'eq', '-0', 'tanpi(1) is -0');

  Rmpfr_tanpi($rop1, Math::MPFR->new(-1), MPFR_RNDN);
  cmp_ok("$rop1", 'eq', '0', 'tanpi(-1) is 0');

  Rmpfr_tanpi($rop1, Math::MPFR->new(0.5), MPFR_RNDN);
  cmp_ok($rop1, '==', $pinf, 'tanpi(0.5) is +Inf');

  Rmpfr_tanpi($rop1, Math::MPFR->new(-0.5), MPFR_RNDN);
  cmp_ok($rop1, '==', $ninf, 'tanpi(-0.5) is -Inf');

  Rmpfr_tanpi($rop1, Math::MPFR->new(0.25), MPFR_RNDN);
  cmp_ok($rop1, '==', 1, 'tanpi(0.25) is 1');

  Rmpfr_tanpi($rop1, Math::MPFR->new(-0.25), MPFR_RNDN);
  cmp_ok($rop1, '==', -1, 'tanpi(-0.25) is -1');
##
  my($s, $c) = (0, 0);
  my $rop3 = Math::MPFR->new();
  my $rop4 = Math::MPFR->new();
  for(2 .. $default_prec) {
    next unless $_ % 11;
    $s += 2 ** -$_;
    $c = 0.5 - $s;

    my $op1 = Math::MPFR->new($s);
    my $op2 = Math::MPFR->new($c);

    Rmpfr_sinpi($rop1, Math::MPFR->new($op1), MPFR_RNDN);
    Rmpfr_cospi($rop2, Math::MPFR->new($op2), MPFR_RNDN);

    cmp_ok($rop1, '==', $rop2, "$_: sinpi(x) == cospi(0.5 - x)");

    Rmpfr_sinu($rop3, Math::MPFR->new($op1 * 180), 360, MPFR_RNDN);
    Rmpfr_cosu($rop4, Math::MPFR->new($op2 * 180), 360, MPFR_RNDN);

    cmp_ok($rop1, '==', $rop3, "$_: sinpi(x) == sinu(x * 180, 360)");
    cmp_ok($rop2, '==', $rop4, "$_: cospi(x) == cosu(x * 180, 360)");
   }

}
else {
  # Rmpfr_sinu(), Rmpfr_cosu(), Rmpfr_tanu(), Rmpfr_sinpi(),
  # Rmpfr_cospi and Rmpfr_tanpi() are all unavailable

  eval{ Rmpfr_sinu($rop1, Math::MPFR->new(6), 3, MPFR_RNDN); };
  like($@, qr/^Rmpfr_sinu function not implemented/, 'Rmpfr_sinu: $@ set as expected');

  eval{ Rmpfr_cosu($rop1, Math::MPFR->new(6), 3, MPFR_RNDN); };
  like($@, qr/^Rmpfr_cosu function not implemented/, 'Rmpfr_cosu: $@ set as expected');

  eval{ Rmpfr_tanu($rop1, Math::MPFR->new(6), 3, MPFR_RNDN); };
  like($@, qr/^Rmpfr_tanu function not implemented/, 'Rmpfr_tanu: $@ set as expected');

  eval{ Rmpfr_sinpi($rop1, Math::MPFR->new(6), MPFR_RNDN); };
  like($@, qr/^Rmpfr_sinpi function not implemented/, 'Rmpfr_sinpi: $@ set as expected');

  eval{ Rmpfr_cospi($rop1, Math::MPFR->new(6), MPFR_RNDN); };
  like($@, qr/^Rmpfr_cospi function not implemented/, 'Rmpfr_cospi: $@ set as expected');

  eval{ Rmpfr_tanpi($rop1, Math::MPFR->new(6), MPFR_RNDN); };
  like($@, qr/^Rmpfr_tanpi function not implemented/, 'Rmpfr_tanpi: $@ set as expected');
}


done_testing();
