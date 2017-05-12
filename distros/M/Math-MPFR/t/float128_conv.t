use warnings;
use strict;
use Math::MPFR qw(:mpfr);

my $t = 21;
print "1..$t\n";

my $why;

my $proceed = Math::MPFR::_MPFR_WANT_FLOAT128();

unless($proceed) {
  $why = "Math::MPFR built without float128 support\n";
  warn "\n Skipping all tests: $why";
  print "ok $_\n" for 1..$t;
  exit 0;
}

eval {require Math::Float128; Math::Float128->import (qw(:all));};

if($@) {
  $why = "Couldn't load Math::Float128\n";
  warn "\n Skipping all tests: $why: $@\n";
  print "ok $_\n" for 1..$t;
  exit 0;
}

if(196866 >= MPFR_VERSION) {
  $why = "No float128 support with this version of the mpfr library\n";
  warn "\n Skipping all tests: $why";
  print "ok $_\n" for 1..$t;
  exit 0;
}

if($proceed) {
  Rmpfr_set_default_prec(114);
  my $ok = 1;
  my $it;
  for $it(1 .. 10000) {
    my $nv = rand(1024) / (1 + rand(1024));
    #$ $larg_1 and $larg_2 will be complementary Rounding modes.
    my $larg_1 = int(rand(5));
    my $larg_2 = $larg_1 ? 5 - $larg_1 : $larg_1;
    my $f128_1 = NVtoF128($nv);
    my $fr_1 = Math::MPFR->new();
    Rmpfr_set_FLOAT128($fr_1, $f128_1, $larg_1);
    my $f128_2 = NVtoF128(0);
    Rmpfr_get_FLOAT128($f128_2, $fr_1, $larg_2);
    unless($f128_1 == $f128_2) {
      $ok = 0;
      warn "$it: $f128_1 != $f128_2\n   $larg_1 : $larg_2\n\n";
    }
  }
  if($ok) {print "ok 1\n"}
  else {print "not ok 1\n"}

  $ok = 1;

  Rmpfr_set_default_prec(115);
  for $it(1 .. 10000) {
    my $nv = rand(1024) / (1 + rand(1024));
    my $f128_1 = NVtoF128($nv);
    my $fr_1 = Math::MPFR->new();
    Rmpfr_set_FLOAT128($fr_1, $f128_1, 0);
    my $f128_2 = NVtoF128(0);
    Rmpfr_get_FLOAT128($f128_2, $fr_1, 0);
    unless($f128_1 == $f128_2) {
      $ok = 0;
      warn "$it: $f128_1 != $f128_2\n";
    }
  }
  if($ok) {print "ok 2\n"}
  else {print "not ok 2\n"}

  my $nanF128   = NaNF128();
  my $pinfF128  = InfF128(1);
  my $ninfF128  = InfF128(-1);
  my $zeroF128  = ZeroF128(1);
  my $nzeroF128 = ZeroF128(-1);
  my $rop = Math::Float128->new();

  my $fr = Math::MPFR->new();

  Rmpfr_set_FLOAT128($fr, $nanF128, MPFR_RNDN);
  Rmpfr_get_FLOAT128($rop, $fr, MPFR_RNDN);

  if(is_NaNF128($rop)) {print "ok 3\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 3\n";
  }

  Rmpfr_set_FLOAT128($fr, $pinfF128, MPFR_RNDN);
  Rmpfr_get_FLOAT128($rop, $fr, MPFR_RNDN);

  if(is_InfF128($rop) > 0) {print "ok 4\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 4\n";
  }

  Rmpfr_set_FLOAT128($fr, $ninfF128, MPFR_RNDN);
  Rmpfr_get_FLOAT128($rop, $fr, MPFR_RNDN);

  if(is_InfF128($rop) < 0) {print "ok 5\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 5\n";
  }

  Rmpfr_set_FLOAT128($fr, $zeroF128, MPFR_RNDN);
  Rmpfr_get_FLOAT128($rop, $fr, MPFR_RNDN);

  if(is_ZeroF128($rop) > 0) {print "ok 6\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 6\n";
  }

  Rmpfr_set_FLOAT128($fr, $nzeroF128, MPFR_RNDN);
  Rmpfr_get_FLOAT128($rop, $fr, MPFR_RNDN);

  if(is_ZeroF128($rop) < 0) {print "ok 7\n"}
  else {
    warn "\$rop: $rop\n";
    print "not ok 7\n";
  }

  my $bigpos = Math::MPFR->new('1.4e4932');
  my $bigneg = $bigpos * -1;

  Rmpfr_get_FLOAT128($rop, $bigpos, MPFR_RNDN);
  if(is_InfF128($rop) > 0) {print "ok 8\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 8\n";
  }

  Rmpfr_get_FLOAT128($rop, $bigneg, MPFR_RNDN);
  if(is_InfF128($rop) < 0) {print "ok 9\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 9\n";
  }

  Rmpfr_get_FLOAT128($rop, Math::MPFR->new('1.18973149535723176508575932662800702e4932'), MPFR_RNDZ);
  if($rop == Math::Float128->new('1.18973149535723176508575932662800702e4932')) {print "ok 10\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 10\n";
  }

  if(-$rop == Math::Float128->new('-1.18973149535723176508575932662800702e4932')) {print "ok 11\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 11\n";
  }

  if($rop == Math::Float128::FLT128_MAX()) {print "ok 12\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 12\n";
  }

  my $littlepos = Math::MPFR->new('7e-4967');
  my $littleneg = $littlepos * -1;

  Rmpfr_get_FLOAT128($rop, $littlepos, MPFR_RNDZ);
  if(is_ZeroF128($rop) > 0) {print "ok 13\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 13\n";
  }

  Rmpfr_get_FLOAT128($rop, $littleneg, MPFR_RNDZ);
  if(is_ZeroF128($rop) < 0) {print "ok 14\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 14\n";
  }

  Rmpfr_get_FLOAT128($rop, $littlepos, MPFR_RNDA);
  if(is_ZeroF128($rop) > 0) {print "ok 15\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 15\n";
  }

  Rmpfr_get_FLOAT128($rop, $littleneg, MPFR_RNDA);
  if(is_ZeroF128($rop) < 0) {print "ok 16\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 16\n";
  }

  Rmpfr_get_FLOAT128($rop, Math::MPFR->new('6.475175119438025110924438958227646552e-4966'), MPFR_RNDN);
  if($rop == Math::Float128::FLT128_DENORM_MIN()) {print "ok 17\n"}
  else {
    warn "\n\$rop: $rop\n";
    print "not ok 17\n";
  }

  my $fr_F128 = Rmpfr_init2(115);
  my $f128_1 = STRtoF128('1e-298');
  my $f128_2 = Math::Float128->new();
  Rmpfr_set_FLOAT128($fr_F128, $f128_1, MPFR_RNDN);
  Rmpfr_get_FLOAT128($f128_2, $fr_F128, MPFR_RNDN);
  if($f128_1 == $f128_2) {print "ok 18\n"}
  else {
    warn "\n $f128_1: $f128_1\n \$f128_2: $f128_2\n";
    print "not ok 18\n";
  }

  $f128_1 = NVtoF128(1e-298);
  Rmpfr_set_FLOAT128($fr_F128, $f128_1, MPFR_RNDN);
  Rmpfr_get_FLOAT128($f128_2, $fr_F128, MPFR_RNDN);
  if($f128_1 == $f128_2) {print "ok 19\n"}
  else {
    warn "\n $f128_1: $f128_1\n \$f128_2: $f128_2\n";
    print "not ok 19\n";
  }

  $f128_1 = STRtoF128('1e-360');
  Rmpfr_set_FLOAT128($fr_F128, $f128_1, MPFR_RNDN);
  Rmpfr_get_FLOAT128($f128_2, $fr_F128, MPFR_RNDN);
  if($f128_1 == $f128_2) {print "ok 20\n"}
  else {
    warn "\n $f128_1: $f128_1\n \$f128_2: $f128_2\n";
    print "not ok 20\n";
  }

  $f128_1 = NVtoF128(1e-360);
  Rmpfr_set_FLOAT128($fr_F128, $f128_1, MPFR_RNDN);
  Rmpfr_get_FLOAT128($f128_2, $fr_F128, MPFR_RNDN);
  if($f128_1 == $f128_2) {print "ok 21\n"}
  else {
    warn "\n $f128_1: $f128_1\n \$f128_2: $f128_2\n";
    print "not ok 21\n";
  }
}
else {
  warn "Skipping all tests - Math::MPFR not built for Float128 support";
  print "ok $_\n" for 1..$t;
}

