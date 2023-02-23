use warnings;
use strict;
use Math::MPFR qw(:mpfr);

unless(Math::MPFR::_MPFR_WANT_DECIMAL128()) {
  print "1..1\n";
  warn "\n Skipping all tests - Math::MPFR not built with MPFR_WANT_DECIMAL_FLOATS defined\n";
  print "ok 1\n";
  exit 0;
}

my $t = 21;
print "1..$t\n";

eval {require Math::Decimal128; Math::Decimal128->import (qw(:all));};

my $why;
if($@) {
  $why = "Couldn't load Math::Decimal128\n";
  warn "\n Skipping all tests: $why: $@\n";
  print "ok $_\n" for 1..$t;
  exit 0;
}

my $proceed = Math::MPFR::_MPFR_WANT_DECIMAL128();

if($proceed) {
  Rmpfr_set_default_prec(114); # Using complementary Rounding Modes needs prec of 114.
  my $ok = 1;
  my $it;
  for $it(1 .. 10000) {
    my $nv = rand(1024) / (1 + rand(1024));
    #$ $larg_1 and $larg_2 will be complementary Rounding modes.
    my $larg_1 = int(rand(5));
    my $larg_2 = $larg_1 ? 5 - $larg_1 : $larg_1;
    my $d128_1 = NVtoD128($nv);
    my $fr_1 = Math::MPFR->new();
    Rmpfr_set_DECIMAL128($fr_1, $d128_1, $larg_1);
    my $d128_2 = NVtoD128(0);
    Rmpfr_get_DECIMAL128($d128_2, $fr_1, $larg_2);
    unless($d128_1 == $d128_2) {
      $ok = 0;
      warn "$it: $d128_1 != $d128_2\n   $larg_1 : $larg_2\n\n";
    }
  }
  if($ok) {print "ok 1\n"}
  else {print "not ok 1\n"}

  $ok = 1;

  Rmpfr_set_default_prec(114);
  for $it(1 .. 10000) {
    my $nv = rand(1024) / (1 + rand(1024));
    my $d128_1 = NVtoD128($nv);
    my $fr_1 = Math::MPFR->new();
    Rmpfr_set_DECIMAL128($fr_1, $d128_1, 0);
    my $d128_2 = NVtoD128(0);
    Rmpfr_get_DECIMAL128($d128_2, $fr_1, 0);
    unless($d128_1 == $d128_2) {
      $ok = 0;
      warn "$it: $d128_1 != $d128_2\n";
    }
  }
  if($ok) {print "ok 2\n"}
  else {print "not ok 2\n"}

  my $nanD128   = NaND128();
  my $pinfD128  = InfD128(1);
  my $ninfD128  = InfD128(-1);
  my $zeroD128  = ZeroD128(1);
  my $nzeroD128 = ZeroD128(-1);
  my $rop = Math::Decimal128->new();

  my $fr = Math::MPFR->new();

  Rmpfr_set_DECIMAL128($fr, $nanD128, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($rop, $fr, MPFR_RNDN);

  if(is_NaND128($rop)) {print "ok 3\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 3\n";
  }

  Rmpfr_set_DECIMAL128($fr, $pinfD128, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($rop, $fr, MPFR_RNDN);

  if(is_InfD128($rop) > 0) {print "ok 4\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 4\n";
  }

  Rmpfr_set_DECIMAL128($fr, $ninfD128, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($rop, $fr, MPFR_RNDN);

  if(is_InfD128($rop) < 0) {print "ok 5\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 5\n";
  }

  Rmpfr_set_DECIMAL128($fr, $zeroD128, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($rop, $fr, MPFR_RNDN);

  if(is_ZeroD128($rop) > 0) {print "ok 6\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 6\n";
  }

  Rmpfr_set_DECIMAL128($fr, $nzeroD128, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($rop, $fr, MPFR_RNDN);

  if(is_ZeroD128($rop) < 0) {print "ok 7\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 7\n";
  }

  my $bigpos = Math::MPFR->new('1@6145');
  my $bigneg = $bigpos * -1;

  Rmpfr_get_DECIMAL128($rop, $bigpos, MPFR_RNDN);
  if(is_InfD128($rop) > 0) {print "ok 8\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 8\n";
  }

  Rmpfr_get_DECIMAL128($rop, $bigneg, MPFR_RNDN);
  if(is_InfD128($rop) < 0) {print "ok 9\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 9\n";
  }

  Rmpfr_get_DECIMAL128($rop, $bigpos, MPFR_RNDZ);
  if($rop == Math::Decimal128->new('9999999999999999999999999999999999', '6111')) {print "ok 10\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 10\n";
  }

  if($rop == Math::Decimal128->new('9999999999999999999999999999999999', '6111')) {print "ok 11\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 11\n";
  }

  if($rop == Math::Decimal128::DEC128_MAX()) {print "ok 12\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 12\n";
  }

  my $littlepos = Math::MPFR->new('1@-6177');
  my $littleneg = $littlepos * -1;

  Rmpfr_get_DECIMAL128($rop, $littlepos, MPFR_RNDZ);
  if(is_ZeroD128($rop) > 0) {print "ok 13\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 13\n";
  }

  Rmpfr_get_DECIMAL128($rop, $littleneg, MPFR_RNDZ);
  if(is_ZeroD128($rop) < 0) {print "ok 14\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 14\n";
  }

  Rmpfr_get_DECIMAL128($rop, $littlepos, MPFR_RNDA);
  if($rop == Math::Decimal128->new(1, -6176)) {print "ok 15\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 15\n";
  }

  Rmpfr_get_DECIMAL128($rop, $littleneg, MPFR_RNDA);
  if($rop == Math::Decimal128->new(-1, -6176)) {print "ok 16\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 16\n";
  }

  if($rop == Math::Decimal128::DEC128_MIN() * Math::Decimal128::UnityD128(-1)) {print "ok 17\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 17\n";
  }

  my $fr_d128 = Rmpfr_init2(114);
  my $d128_1 = MEtoD128('1', -298);
  my $d128_2 = Math::Decimal128->new();
  Rmpfr_set_DECIMAL128($fr_d128, $d128_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($d128_2, $fr_d128, MPFR_RNDN);
  if($d128_1 == $d128_2) {print "ok 18\n"}
  else {
    warn "\n $d128_1: $d128_1\n \$d128_2: $d128_2\n";
    print "not ok 18\n";
  }

  $d128_1 = NVtoD128(1e-298);
  Rmpfr_set_DECIMAL128($fr_d128, $d128_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($d128_2, $fr_d128, MPFR_RNDN);
  if($d128_1 == $d128_2) {print "ok 19\n"}
  else {
    warn "\n $d128_1: $d128_1\n \$d128_2: $d128_2\n";
    print "not ok 19\n";
  }

  $d128_1 = MEtoD128('1', -360);
  Rmpfr_set_DECIMAL128($fr_d128, $d128_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($d128_2, $fr_d128, MPFR_RNDN);
  if($d128_1 == $d128_2) {print "ok 20\n"}
  else {
    warn "\n $d128_1: $d128_1\n \$d128_2: $d128_2\n";
    print "not ok 20\n";
  }

  $d128_1 = NVtoD128(1e-360);
  Rmpfr_set_DECIMAL128($fr_d128, $d128_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL128($d128_2, $fr_d128, MPFR_RNDN);
  if($d128_1 == $d128_2) {print "ok 21\n"}
  else {
    warn "\n $d128_1: $d128_1\n \$d128_2: $d128_2\n";
    print "not ok 21\n";
  }
}
else {
  warn "Skipping all tests - Math::MPFR not built for Decimal128 support";
  print "ok $_\n" for 1..$t;
}

