use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

print "1..9\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

if(Math::MPFR::_has_longdouble()) {print "Using long double\n"}
else {print "Not using long double\n"}

Rmpfr_set_default_prec(300);

if(Math::MPFR::_has_longdouble()) {
  my $ok = '';
  my $n = (2 ** 55) + 0.5;
  my $ld1 = Math::MPFR->new($n);
  my $ld2 = Math::MPFR::new($n);
  my $ld3 = Math::MPFR->new();
  Rmpfr_set_ld($ld3, $n, GMP_RNDN);

  if(
     $ld1 == $ld2 &&
     $ld2 == $ld3 &&
     $ld2 <= $n  &&
     $ld2 >= $n  &&
     $ld2 < $n + 1 &&
     $ld2 > $n - 1 &&
     ($ld2 <=> $n) == 0 &&
     ($ld2 <=> $n - 1) > 0 &&
     ($ld2 <=> $n + 1) < 0 &&
     $ld2 != $n - 1
                   ) {$ok .= 'a'}

  my $d2 = Rmpfr_get_ld($ld1, GMP_RNDN);

  if($d2 == $n) {$ok .= 'b'}

  if(!Rmpfr_cmp_ld($ld1, $n)) {$ok .= 'c'}

  if($ok eq 'abc') {print "ok 1\n"}
  else {print "not ok 1 $ok\n"}

  $ok = '';

# Check the overloaded operators.

  if($ld1 - 1 == $n - 1) {$ok .= 'a'}

  $ld1 -= 1;

  if($ld1 == $n - 1) {$ok .= 'b'}

  $ld1 = $ld1 / 2;

  if($ld1 == ($n - 1) / 2) {$ok .= 'c'}

  $ld1 = $ld1 * 2;

  if($ld1 == $n - 1) {$ok .= 'd'}

  $ld1 /= 2;

  if($ld1 == ($n - 1) / 2) {$ok .= 'e'}

  $ld1 *= 2;

  if($ld1 == $n - 1) {$ok .= 'f'}

  if($ld1 + 1 == $n) {$ok .= 'g'}

  $ld1 += 1;

  if($ld1 == $n) {$ok .= 'h'}

  if($ld1 ** 0.5 < 189812531.25 &&
     $ld1 ** 0.5 > 189812531.24) {$ok .= 'i'}

  $ld1 **= 0.5;

  if($ld1 < 189812531.25 &&
     $ld1 > 189812531.24) {$ok .= 'j'}

  if($ok eq 'abcdefghij') {print "ok 2\n"}
  else {print "not ok 2 $ok\n"}

  my $bits = $Config::Config{longdblsize} > $Config::Config{doublesize} ? $Config::Config{doublesize} * 7 : 50;

  $n = (2 ** $bits) + 0.5;

  my $ld4 = Math::MPFR->new($n);

  if($ld4 == int($ld4)) { print "not ok 3 precision has been lost: $ld4\n"}
  else {print "ok 3\n"}

}
else {
  my $ok = '';
  my $int1 = Rmpfr_init();
  eval{Rmpfr_set_ld($int1, 2 ** 23, GMP_RNDN);};
  if($@ =~ /not implemented on this build of perl/i) {$ok = 'a'}
  eval{Rmpfr_cmp_ld($int1, 2 ** 23);};
  if($@ =~ /not implemented on this build of perl/i) {$ok .= 'b'}
  eval{Rmpfr_get_ld($int1, GMP_RNDN);};
  if($@ =~ /not implemented on this build of perl/i) {$ok .= 'c'}
  eval{my($int2, $ret) = Rmpfr_init_set_ld(2 ** 23, GMP_RNDN);};
  if($@ =~ /not implemented on this build of perl/i) {$ok .= 'd'}
  if($ok eq 'abcd') {print "ok 1\n"}
  else {print "not ok 1 $ok\n"}
  warn "Skipping test 2 - nothing to test\n";
  print "ok 2\n";
  warn "Skipping test 3 - nothing to test\n";
  print "ok 3\n";
}

if(Math::MPFR::_has_longdouble()) {
  my $mpfr = Math::MPFR->new('1' x 62, 2);
  my $mpfr2 = Rmpfr_init();
  my $ok = '';

  if ($mpfr <  4611686018427387904 && $mpfr >  4611686018427387902) {$ok .= 'a'}
  if ($mpfr <= 4611686018427387904 && $mpfr >= 4611686018427387902) {$ok .= 'b'}
  if ($mpfr == 4611686018427387903) {$ok .= 'c'}
  if ($mpfr <= 4611686018427387903) {$ok .= 'd'}
  if ($mpfr >= 4611686018427387903) {$ok .= 'e'}

  my $ld = Rmpfr_get_ld($mpfr, GMP_RNDN);

  if ($ld < 4611686018427387904 && $ld > 4611686018427387902) {$ok .= 'f'}
  if ($ld == 4611686018427387903) {$ok .= 'g'}

  my $cmp = $mpfr <=> 4611686018427387902;
  if($cmp > 0) {$ok .= 'h'}

  $cmp = $mpfr <=> 4611686018427387903;
  if($cmp == 0) {$ok .= 'i'}

  $cmp = $mpfr <=> 4611686018427387904;
  if($cmp < 0) {$ok .= 'j'}

  $cmp = 4611686018427387902 <=> $mpfr;
  if($cmp < 0) {$ok .= 'k'}

  $cmp = 4611686018427387903 <=> $mpfr;
  if($cmp == 0) {$ok .= 'l'}

  $cmp = 4611686018427387904 <=> $mpfr;
  if($cmp > 0) {$ok .= 'm'}

  Rmpfr_set_ld($mpfr2, 4611686018427387903, GMP_RNDN);
  if($mpfr2 == $mpfr) {$ok .= 'n'}

  if($ok eq 'abcdefghijklmn') {print "ok 4\n"}
  else {print "not ok 4 $ok\n"}
}
else {
  warn "Skipping test 4 - no long double support\n";
  print "ok 4\n";
}

my $num1 = Math::MPFR->new(100);
my $exp = \$num1;

if(Math::MPFR::_has_longdouble()) {
   my $double = Rmpfr_get_ld_2exp($exp, $num1, GMP_RNDN);
   if($double > 0.781249 && $double < 0.781251 && $exp == 7) {print "ok 5\n"}
   else {
      warn "\n   Got (double): $double\n   Expected: 0.78125\n\n",
           "   Got (exp): $exp\n   Expected: 7\n";
      print "not ok 5\n";
   }
}
else {
   eval{my $double = Rmpfr_get_ld_2exp($exp, $num1, GMP_RNDN);};
   if($@ =~ /Rmpfr_get_ld_2exp not implemented/) {print "ok 5\n"}
   else {
      warn "\n\$\@: $@\n";
      print "not ok 5\n";
   }
}

if(Math::MPFR::_has_longdouble()) {
  my $double = (2 ** 55) + 0.5;

  if($double == Rmpfr_get_NV(Math::MPFR->new($double), GMP_RNDN)) {print "ok 6\n"}
  else {
    warn "\nGot: ", Rmpfr_get_NV(Math::MPFR->new($double), GMP_RNDN) , "\nExpected: $double\n";
    print "not ok 43\n";
  }
}
else {
  warn "Skipping test 6 - no long double support\n";
  print "ok 6\n";
}

if(Math::MPFR::_has_longdouble()) {
  my $nan = Math::MPFR->new();
  my $posinf = Math::MPFR->new('inf');
  my $neginf = Math::MPFR->new('-inf');

  my $ok = '';

  if($posinf == - $neginf) {$ok .= 'a'}
  else {warn "a: $posinf ", $neginf * -1, "\n"}

  my $double = Rmpfr_get_ld($nan, GMP_RNDN);
  Rmpfr_set_ld($nan, $double, GMP_RNDN);
  if(Rmpfr_nan_p($nan)) {$ok .= 'b'}
  else {warn "b: $nan\n"}

  $double = Rmpfr_get_ld($posinf, GMP_RNDN);
  Rmpfr_set_ld($posinf, $double, GMP_RNDN);
  if(Rmpfr_inf_p($posinf) && $posinf > 0) {$ok .= 'c'}
  else {warn "c: $posinf\n"}

  $double = Rmpfr_get_ld($neginf, GMP_RNDN);
  Rmpfr_set_ld($neginf, $double, GMP_RNDN);
  if(Rmpfr_inf_p($neginf) && $neginf < 0) {$ok .= 'd'}
  else {warn "d: $neginf\n"}

  $double = Rmpfr_get_NV($nan, GMP_RNDN);
  Rmpfr_set_ld($nan, $double, GMP_RNDN);
  if(Rmpfr_nan_p($nan)) {$ok .= 'e'}
  else {warn "e: $nan\n"}

  $double = Rmpfr_get_NV($posinf, GMP_RNDN);
  Rmpfr_set_ld($posinf, $double, GMP_RNDN);
  if(Rmpfr_inf_p($posinf) && $posinf > 0) {$ok .= 'f'}
  else {warn "f: $posinf\n"}

  $double = Rmpfr_get_NV($neginf, GMP_RNDN);
  Rmpfr_set_ld($neginf, $double, GMP_RNDN);
  if(Rmpfr_inf_p($neginf) && $neginf < 0) {$ok .= 'g'}
  else {warn "g: $neginf\n"}

  if($ok eq 'abcdefg') {print "ok 7\n"}
  else {print "not ok 7 $ok\n"}
}
else {
  warn "Skipping test 7 - no long double support\n";
  print "ok 7\n";
}

if(Math::MPFR::_has_longdouble()) {
  # Check that the mpfr_get_ld() bug has been fixed (mpfr-2.4.2 and later only)
  if(MPFR_VERSION > 132097) {
    my $prec = Rmpfr_get_default_prec();
    Rmpfr_set_default_prec(64);
    my $bugtest = Math::MPFR->new(-12345);
    Rmpfr_exp($bugtest, $bugtest, GMP_RNDN);
    my $ld = Rmpfr_get_ld($bugtest, GMP_RNDN);
    Rmpfr_set_default_prec($prec);
    if($ld < 0.000000001 && $ld >= 0){print "ok 8\n"}
    else {
      warn "Got: $ld\n";
      print "not ok 8\n";
    }
  }
  else {
    warn "Skipping test 8 - mpfr_get_ld bug with mpfr-2.4.1 and earlier will cause the test to fail\n";
    print "ok 8\n";
  }
}
else {
  warn "Skipping test 8 - no long double support\n";
  print "ok 8\n";
}

# Test for a bug that affects Double-Double type only.
if(Math::MPFR::_has_longdouble()) {
  my $prob1 = Rmpfr_init2(2097);
  my $prob2 = Rmpfr_init2(2098);
  my $p_val = (2 ** 1023) + (2 ** -1074);

  my $res = $p_val > 2 ** 1023 ? 1 : 0;

  my $res1 = Rmpfr_set_ld($prob1, $p_val, MPFR_RNDN);
  my $res2 = Rmpfr_set_ld($prob2, $p_val, MPFR_RNDN);

  if($res) { # double-double
    if($res1 == -1 && $res2 == 0) {
      print "ok 9\n";
    }
    else {
      warn "\nDouble-Double type: \$res1: $res1 \$res2: $res2\n";
      print "not ok 9\n";
    }
  }
  else {
    if(!$res1 && !$res2) {
      print "ok 9\n";
    }
    else {
      warn "\nNOT Double-Double type: \$res1: $res1 \$res2: $res2\n";
      print "not ok 9\n";
    }
  }
}
else {
  warn "Skipping test 9 - no long double support\n";
  print "ok 9\n";
}

