# Test file for Rmpfr_asinpi(), Rmpfr_acospi(), Rmpfr_atanpi(), Rmpfr_atan2pi(),
# and also for Rmpfr_asinu(), Rmpfr_acosu(), Rmpfr_atanu() anf Rmpfr_atan2u().

use strict;
use warnings;
use Config;
use Test::More;
use Math::MPFR qw(:mpfr);

my $inex;
my $has_420 = 0;
$has_420++ if MPFR_VERSION() >= 262656; # mpfr-4.2.0 or later

my $rop   = Math::MPFR->new();
my $rop2  = Math::MPFR->new();
my $ropu  = Math::MPFR->new();
my $roppi = Math::MPFR->new();
my $pi    = Math::MPFR->new('3.1415926535897931');
my $op    = Math::MPFR->new('0.5');
my $op2   = Math::MPFR->new('0.7');
my $pinf  = Math::MPFR->new();
my $ui    = 128;

Rmpfr_set_inf($pinf, 1);
my $ninf = $pinf * -1;

if($has_420) {

  #### acos ####
  Rmpfr_acos  ($rop,   $op,      MPFR_RNDN);
  Rmpfr_acospi($roppi, $op,      MPFR_RNDN);
  Rmpfr_acosu ($ropu,  $op, 128, MPFR_RNDN);

  # $ropu = $rop * 128 / (2 * $pi)
  my $rop_check = ($rop * 128) / (2 * $pi);
  cmp_ok(abs($ropu - $rop_check), '<', 1e-14, "Rmpfr_acosu in range ($ropu | $rop_check");

  $inex = Rmpfr_acosu($rop2, Math::MPFR->new(0.5), 360, MPFR_RNDN);
  cmp_ok( $rop2, '==', 60, "inverse cosine of 0.5 is 60 degrees");
  cmp_ok($inex, '==', 0, 'result was exact');

  # $roppi = $rop / $pi
  $rop_check = $rop / $pi;
  cmp_ok(abs($roppi - $rop_check), '<', 1e-16, "Rmpfr_acospi in range ($roppi | $rop_check");

  $inex = Rmpfr_acospi($rop2, Math::MPFR->new(-1), MPFR_RNDN);
  cmp_ok($rop2, '==', 1, 'acospi(-1) is 1');
  cmp_ok($inex, '==', 0, 'result was exact');

  $inex = Rmpfr_acospi($rop2, Math::MPFR->new(0), MPFR_RNDN);
  cmp_ok($rop2, '==', 0.5, 'acospi(0) is 0.5');
  cmp_ok($inex, '==', 0, 'result was exact');

  ### asin ###
  Rmpfr_asin  ($rop,   $op,      MPFR_RNDN);
  Rmpfr_asinpi($roppi, $op,      MPFR_RNDN);
  Rmpfr_asinu ($ropu,  $op, 128, MPFR_RNDN);

  $inex = Rmpfr_asinu($rop2, Math::MPFR->new(0.5), 360, MPFR_RNDN);
  cmp_ok( $rop2, '==', 30, "inverse sine of 0.5 is 30 degrees");
  cmp_ok($inex, '==', 0, 'result was exact');

  # $ropu = $rop * 128 / (2 * $pi)
  $rop_check = ($rop * 128) / (2 * $pi);
  cmp_ok(abs($ropu - $rop_check), '<', 1e-14, "Rmpfr_asinu in range ($ropu | $rop_check");

  # $roppi = $rop / $pi
  $rop_check = $rop / $pi;
  cmp_ok(abs($roppi - $rop_check), '<', 1e-16, "Rmpfr_asinpi in range ($roppi | $rop_check");

  $inex = Rmpfr_asinpi($rop2, Math::MPFR->new(0), MPFR_RNDN);
  cmp_ok($rop2, '==', 0, 'asinpi(0) is 0');
  cmp_ok($inex, '==', 0, 'result was exact');

  $inex = Rmpfr_asinpi($rop2, Math::MPFR->new(1), MPFR_RNDN);
  cmp_ok($rop2, '==', 0.5, 'asinpi(1) is 0.5');
  cmp_ok($inex, '==', 0, 'result was exact');

  $inex = Rmpfr_asinpi($rop2, Math::MPFR->new(-1), MPFR_RNDN);
  cmp_ok($rop2, '==', -0.5, 'asinpi(-1) is -0.5');
  cmp_ok($inex, '==', 0, 'result was exact');

  ### atan ###
  Rmpfr_atan  ($rop,   $op,      MPFR_RNDN);
  Rmpfr_atanpi($roppi, $op,      MPFR_RNDN);
  Rmpfr_atanu ($ropu,  $op, 128, MPFR_RNDN);

  # $ropu = $rop * 128 / (2 * $pi)
  $rop_check = ($rop * 128) / (2 * $pi);
  cmp_ok(abs($ropu - $rop_check), '==', 0, "Rmpfr_atanu in range ($ropu | $rop_check"); # 1e-14

  $inex = Rmpfr_atanu($rop2, Math::MPFR->new(1), 360, MPFR_RNDN);
  cmp_ok( $rop2, '==', 45, "inverse tan of 1 is 45 degrees");
  cmp_ok($inex, '==', 0, 'result was exact');

  # $roppi = $rop / $pi
  $rop_check = $rop / $pi;
  cmp_ok(abs($roppi - $rop_check), '==', 0, "Rmpfr_atanpi in range ($roppi | $rop_check"); # 1e-16

  $inex = Rmpfr_atanpi($rop2, Math::MPFR->new(0), MPFR_RNDN);
  cmp_ok("$rop2", 'eq', '0', 'atanpi(0) is 0');
  cmp_ok($inex, '==', 0, 'result was exact');

  $inex = Rmpfr_atanpi($rop2, $pinf, MPFR_RNDN);
  cmp_ok($rop2, '==', 0.5, 'atanpi(Inf) is 0.5');
  cmp_ok($inex, '==', 0, 'result was exact');

  $inex = Rmpfr_atanpi($rop2, $ninf, MPFR_RNDN);
  cmp_ok($rop2, '==', -0.5, 'atanpi(-Inf) is -0.5');
  cmp_ok($inex, '==', 0, 'result was exact');

  $inex = Rmpfr_atanpi($rop2, Math::MPFR->new(1), MPFR_RNDN);
  cmp_ok($rop2, '==', 0.25, 'atanpi(1) is 0.25');
  cmp_ok($inex, '==', 0, 'result was exact');

  $inex = Rmpfr_atanpi($rop2, Math::MPFR->new(-1), MPFR_RNDN);
  cmp_ok($rop2, '==', -0.25, 'atanpi(-1) is -0.25');
  cmp_ok($inex, '==', 0, 'result was exact');

  #### atan2 ####
  Rmpfr_atan2  ($rop,   $op, $op2,      MPFR_RNDN);
  Rmpfr_atan2pi($roppi, $op, $op2,      MPFR_RNDN);
  Rmpfr_atan2u ($ropu,  $op, $op2, 128, MPFR_RNDN);

  # $ropu = ($rop * 128) / (2 * $pi)
  $rop_check = ($rop * 128) / (2 * $pi);
  cmp_ok(abs($ropu - $rop_check), '==', 0, "Rmpfr_atan2u in range ($ropu | $rop_check"); # 1e-14

  Rmpfr_atan2u ($rop_check,  $op, $op2, 2, MPFR_RNDN);
  cmp_ok(abs($roppi - $rop_check), '==', 0, "Rmpfr_atan2pi in range ($roppi | $rop_check"); # 1e-16

}
else {
  for (qw(Rmpfr_acosu Rmpfr_acospi Rmpfr_asinu Rmpfr_asinpi Rmpfr_atanu Rmpfr_atanpi Rmpfr_atan2u Rmpfr_atan2pi)) {
    if($_ =~ /u/) { version_check($_, 'u') }
    else { version_check($_, 'pi') }
  }
}


done_testing();

sub version_check{
  my $f = shift;
  my $which = shift;
  my $op = Math::MPFR->new('0.5');
  my $s;

  if($which eq 'pi') {
    if($f =~ /2/) { $s = "$f(\$op, \$op, \$op, MPFR_RNDN)" } # atan2
    else { $s = "$f(\$op, \$op, MPFR_RNDN)" }
    eval( $s );
  }
  else {
    if($f =~ /2/) { $s = "$f(\$op, \$op, \$op, 7, MPFR_RNDN)" } # atan2
    else { $s = "$f(\$op, \$op, 7, MPFR_RNDN)" }
    eval( $s );
  }

  like($@, qr/^$f function not implemented until/, "$f not implemented");
}

