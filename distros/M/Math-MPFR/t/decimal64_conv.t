use warnings;
use strict;
use Math::MPFR qw(:mpfr);

my $t = 21;
print "1..$t\n";

eval {require Math::Decimal64; Math::Decimal64->import (qw(:all));};

my $why;
if($@) {
  $why = "Couldn't load Math::Decimal64\n";
  warn "\n Skipping all tests: $why: $@\n";
  print "ok $_\n" for 1..$t;
  exit 0;
}

my $proceed = Math::MPFR::_MPFR_WANT_DECIMAL_FLOATS();

if($proceed) {
  Rmpfr_set_default_prec(55); # Using complementary Rounding Modes needs prec of 55.
  my $ok = 1;
  my $it;
  for $it(1 .. 10000) {
    my $nv = rand(1024) / (1 + rand(1024));
    #$ $larg_1 and $larg_2 will be complementary Rounding modes.
    my $larg_1 = int(rand(5));
    my $larg_2 = $larg_1 ? 5 - $larg_1 : $larg_1;
    my $d64_1 = NVtoD64($nv);
    my $fr_1 = Math::MPFR->new();
    Rmpfr_set_DECIMAL64($fr_1, $d64_1, $larg_1);
    my $d64_2 = NVtoD64(0);
    Rmpfr_get_DECIMAL64($d64_2, $fr_1, $larg_2);
    unless($d64_1 == $d64_2) {
      $ok = 0;
      warn "$it: $d64_1 != $d64_2\n   $larg_1 : $larg_2\n\n";
    }
  }
  if($ok) {print "ok 1\n"}
  else {print "not ok 1\n"}

  $ok = 1;

  Rmpfr_set_default_prec(55);
  for $it(1 .. 10000) {
    my $nv = rand(1024) / (1 + rand(1024));
    my $d64_1 = NVtoD64($nv);
    my $fr_1 = Math::MPFR->new();
    Rmpfr_set_DECIMAL64($fr_1, $d64_1, 0);
    my $d64_2 = NVtoD64(0);
    Rmpfr_get_DECIMAL64($d64_2, $fr_1, 0);
    unless($d64_1 == $d64_2) {
      $ok = 0;
      warn "$it: $d64_1 != $d64_2\n";
    }
  }
  if($ok) {print "ok 2\n"}
  else {print "not ok 2\n"}

  my $nanD64   = NaND64();
  my $pinfD64  = InfD64(1);
  my $ninfD64  = InfD64(-1);
  my $zeroD64  = ZeroD64(1);
  my $nzeroD64 = ZeroD64(-1);
  my $rop = Math::Decimal64->new();

  my $fr = Math::MPFR->new();

  Rmpfr_set_DECIMAL64($fr, $nanD64, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($rop, $fr, MPFR_RNDN);

  if(is_NaND64($rop)) {print "ok 3\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 3\n";
  }

  Rmpfr_set_DECIMAL64($fr, $pinfD64, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($rop, $fr, MPFR_RNDN);

  if(is_InfD64($rop) > 0) {print "ok 4\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 4\n";
  }

  Rmpfr_set_DECIMAL64($fr, $ninfD64, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($rop, $fr, MPFR_RNDN);

  if(is_InfD64($rop) < 0) {print "ok 5\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 5\n";
  }

  Rmpfr_set_DECIMAL64($fr, $zeroD64, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($rop, $fr, MPFR_RNDN);

  if(is_ZeroD64($rop) > 0) {print "ok 6\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 6\n";
  }

  Rmpfr_set_DECIMAL64($fr, $nzeroD64, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($rop, $fr, MPFR_RNDN);

  if(is_ZeroD64($rop) < 0) {print "ok 7\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 7\n";
  }

  my $bigpos = Math::MPFR->new('1@385');
  my $bigneg = $bigpos * -1;

  Rmpfr_get_DECIMAL64($rop, $bigpos, MPFR_RNDN);
  if(is_InfD64($rop) > 0) {print "ok 8\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 8\n";
  }

  Rmpfr_get_DECIMAL64($rop, $bigneg, MPFR_RNDN);
  if(is_InfD64($rop) < 0) {print "ok 9\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 9\n";
  }

  Rmpfr_get_DECIMAL64($rop, $bigpos, MPFR_RNDZ);
  if($rop == Math::Decimal64->new('9999999999999999','369')) {print "ok 10\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 10\n";
  }

  if($rop == Math::Decimal64->new('9999999999999999','369')) {print "ok 11\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 11\n";
  }

  if($rop == Math::Decimal64::DEC64_MAX()) {print "ok 12\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 12\n";
  }

  my $littlepos = Math::MPFR->new('1@-399');
  my $littleneg = $littlepos * -1;

  Rmpfr_get_DECIMAL64($rop, $littlepos, MPFR_RNDZ);
  if(is_ZeroD64($rop) > 0) {print "ok 13\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 13\n";
  }

  Rmpfr_get_DECIMAL64($rop, $littleneg, MPFR_RNDZ);
  if(is_ZeroD64($rop) < 0) {print "ok 14\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 14\n";
  }

  Rmpfr_get_DECIMAL64($rop, $littlepos, MPFR_RNDA);
  if($rop == Math::Decimal64->new(1, -398)) {print "ok 15\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 15\n";
  }

  Rmpfr_get_DECIMAL64($rop, $littleneg, MPFR_RNDA);
  if($rop == Math::Decimal64->new(-1, -398)) {print "ok 16\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 16\n";
  }

  if($rop == Math::Decimal64::DEC64_MIN() * Math::Decimal64::UnityD64(-1)) {print "ok 17\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 17\n";
  }

  my $fr_d64 = Rmpfr_init2(55);
  my $d64_1 = MEtoD64('1', -298);
  my $d64_2 = Math::Decimal64->new();
  Rmpfr_set_DECIMAL64($fr_d64, $d64_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($d64_2, $fr_d64, MPFR_RNDN);
  if($d64_1 == $d64_2) {print "ok 18\n"}
  else {
    warn "\n $d64_1: $d64_1\n \$d64_2: $d64_2\n";
    print "not ok 18\n";
  }

  $d64_1 = NVtoD64(1e-298);
  Rmpfr_set_DECIMAL64($fr_d64, $d64_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($d64_2, $fr_d64, MPFR_RNDN);
  if($d64_1 == $d64_2) {print "ok 19\n"}
  else {
    warn "\n $d64_1: $d64_1\n \$d64_2: $d64_2\n";
    print "not ok 19\n";
  }

  $d64_1 = MEtoD64('1', -360);
  Rmpfr_set_DECIMAL64($fr_d64, $d64_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($d64_2, $fr_d64, MPFR_RNDN);
  if($d64_1 == $d64_2) {print "ok 20\n"}
  else {
    warn "\n $d64_1: $d64_1\n \$d64_2: $d64_2\n";
    print "not ok 20\n";
  }

  $d64_1 = NVtoD64(1e-360);
  Rmpfr_set_DECIMAL64($fr_d64, $d64_1, MPFR_RNDN);
  Rmpfr_get_DECIMAL64($d64_2, $fr_d64, MPFR_RNDN);
  if($d64_1 == $d64_2) {print "ok 21\n"}
  else {
    warn "\n $d64_1: $d64_1\n \$d64_2: $d64_2\n";
    print "not ok 21\n";
  }
}
else {
  warn "Skipping all tests - Math::MPFR not built for Decimal64 support";
  print "ok $_\n" for 1..$t;
}

