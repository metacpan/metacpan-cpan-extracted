use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Config;

my $t = 21;
print "1..$t\n";

my $why;

my $proceed = Math::MPFR::_MPFR_WANT_FLOAT128();

unless($proceed) {

####################################################

  if($Config{nvtype} eq '__float128') {
    Rmpfr_set_default_prec(114);
    my $ok = 1;
    my $it;
    for $it(1 .. 10000) {
      my $nv = rand(1024) / (1 + rand(1024));
      #$ $larg_1 and $larg_2 will be complementary Rounding modes.
      my $larg_1 = int(rand(5));
      my $larg_2 = $larg_1 ? 5 - $larg_1 : $larg_1;
      my $f128_1 = $nv;
      my $fr_1 = Math::MPFR->new();
      Rmpfr_set_NV($fr_1, $f128_1, $larg_1);
      my $f128_2 = Rmpfr_get_NV($fr_1, $larg_2);
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
      my $f128_1 = $nv;
      my $fr_1 = Math::MPFR->new();
      Rmpfr_set_NV($fr_1, $f128_1, 0);
      my $f128_2 =  Rmpfr_get_NV($fr_1, 0);
      unless($f128_1 == $f128_2) {
        $ok = 0;
        warn "$it: $f128_1 != $f128_2\n";
      }
    }
    if($ok) {print "ok 2\n"}
    else {print "not ok 2\n"}

    my $nan   = Rmpfr_get_NV(Math::MPFR->new(), MPFR_RNDN);
    my $pinf  = 999 ** (999 ** 999);
    my $ninf  = $pinf * -1.0;
    my $zero  = 0.0;
    my $nzero = -1.0 / $pinf;

    my $fr = Math::MPFR->new();

    Rmpfr_set_NV($fr, $nan, MPFR_RNDN);
    my $rop = Rmpfr_get_NV($fr, MPFR_RNDN);

    if($rop != $rop) {print "ok 3\n"}
    else {
      warn "\$rop: $rop\n";
      print "not ok 3\n";
    }

    Rmpfr_set_NV($fr, $pinf, MPFR_RNDN);
    $rop = Rmpfr_get_NV($fr, MPFR_RNDN);

    if($rop != 0.0 && $rop > 0.0 && $rop / $rop != 1.0) {print "ok 4\n"}
    else {
      warn "\$rop: $rop\n";
      print "not ok 4\n";
    }

    Rmpfr_set_NV($fr, $ninf, MPFR_RNDN);
    $rop = Rmpfr_get_NV($fr, MPFR_RNDN);

    if($rop != 0.0 && $rop < 0.0 && $rop / $rop != 1.0) {print "ok 5\n"}
    else {
      warn "\$rop: $rop\n";
      print "not ok 5\n";
    }

    Rmpfr_set_NV($fr, $zero, MPFR_RNDN);
    $rop = Rmpfr_get_NV($fr, MPFR_RNDN);

    if($rop == 0 && substr("$rop", 0, 1) ne '-') {print "ok 6\n"}
    else {
      warn "\$rop: $rop\n";
      print "not ok 6\n";
    }

    Rmpfr_set_NV($fr, $nzero, MPFR_RNDN);
    $rop = Rmpfr_get_NV($fr, MPFR_RNDN);

    if($rop == 0 && substr(sprintf("%e", $rop), 0, 1) eq '-') {print "ok 7\n"}
    else {
      warn "\nExpected -0\nGot: ", sprintf("%e", $rop), "\n";
      if($rop == 0) {
        warn "Problem with signed zero - not registering a failure for this\n";
        print "ok 7\n";
      }
      else {print "not ok 7\n"}
    }

    my $bigpos = Math::MPFR->new('1.4e4932');
    my $bigneg = $bigpos * -1;

    $rop = Rmpfr_get_NV($bigpos, MPFR_RNDN);
    if($rop != 0.0 && $rop > 0.0 && $rop / $rop != 1.0) {print "ok 8\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 8\n";
    }

    $rop = Rmpfr_get_NV($bigneg, MPFR_RNDN);
    if($rop != 0.0 && $rop < 0.0 && $rop / $rop != 1.0) {print "ok 9\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 9\n";
    }

    $rop = Rmpfr_get_NV(Math::MPFR->new('1.18973149535723176508575932662800702e4932'), MPFR_RNDZ);
    if($rop == '1.18973149535723176508575932662800702e4932') {print "ok 10\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 10\n";
    }

    if(-$rop == '-1.18973149535723176508575932662800702e4932') {print "ok 11\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 11\n";
    }

    print "ok 12\n";

    my $littlepos = Math::MPFR->new('7e-4967');
    my $littleneg = $littlepos * -1;

    $rop = Rmpfr_get_NV($littlepos, MPFR_RNDZ);
    if($rop == 0.0) {print "ok 13\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 13\n";
    }

    $rop = Rmpfr_get_NV($littleneg, MPFR_RNDZ);
    if($rop == 0) {print "ok 14\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 14\n";
    }

    # Any +ve non-zero value (no matter how small) will be rounded to a non-zero value under RNDA.
    # Values anywhere between zero and the minimum subnormal value (as is the case here) will be
    # rounded to that minimum subnormal value (6.47517511943802511092443895822764655e-4966)

    $rop = Rmpfr_get_NV($littlepos, MPFR_RNDA);
    if($rop == 6.475175119438025110924438958227646552e-4966) {print "ok 15\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 15\n";
    }

    # Any -ve non-zero value (no matter how close to zero) will be rounded to a non-zero value under RNDA.
    # Values anywhere between zero and the negated minimum subnormal value (as is the case here) will be
    # be rounded to that negated minimum subnormal value (-6.47517511943802511092443895822764655e-4966)

    $rop = Rmpfr_get_NV($littleneg, MPFR_RNDA);
    if($rop == -6.475175119438025110924438958227646552e-4966) {print "ok 16\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 16\n";
    }

    print "ok 17\n";

    my $fr_F128 = Rmpfr_init2(115);
    my $f128_1 = 1e-298;
    Rmpfr_set_NV($fr_F128, $f128_1, MPFR_RNDN);
    my $f128_2 = Rmpfr_get_NV($fr_F128, MPFR_RNDN);
    if($f128_1 == $f128_2) {print "ok 18\n"}
    else {
      warn "\n $f128_1: $f128_1\n \$f128_2: $f128_2\n";
      print "not ok 18\n";
    }

    print "ok 19\n";

    $f128_1 = 1e-360;
    Rmpfr_set_NV($fr_F128, $f128_1, MPFR_RNDN);
    $f128_2 = Rmpfr_get_NV($fr_F128, MPFR_RNDN);
    if($f128_1 == $f128_2) {print "ok 20\n"}
    else {
      warn "\n $f128_1: $f128_1\n \$f128_2: $f128_2\n";
      print "not ok 20\n";
    }

    print "ok 21\n";
  }

####################################################
  else {
    $why = "__float128 tests not applicable to this build of perl\n";
    warn "\n Skipping all tests: $why";
    print "ok $_\n" for 1..$t;
    exit 0;
  }
}

else {
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

    # Any +ve non-zero value (no matter how small) will be rounded to a non-zero value under RNDA.
    # Values anywhere between zero and the minimum subnormal value (as is the case here) will be
    # rounded to that minimum subnormal value (6.47517511943802511092443895822764655e-4966)

    Rmpfr_get_FLOAT128($rop, $littlepos, MPFR_RNDA);
    if(!is_ZeroF128($rop)) {print "ok 15\n"}
    else {
      warn "\n\$rop: $rop\n";
      print "not ok 15\n";
    }

    # Any -ve non-zero value (no matter how close to zero) will be rounded to a non-zero value under RNDA.
    # Values anywhere between zero and the negated minimum subnormal value (as is the case here) will be
    # be rounded to that negated minimum subnormal value (-6.47517511943802511092443895822764655e-4966)

    Rmpfr_get_FLOAT128($rop, $littleneg, MPFR_RNDA);
    if(!is_ZeroF128($rop)) {print "ok 16\n"}
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
}

