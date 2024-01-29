use strict;
use warnings;

use Math::MPFR qw(:mpfr);
use Config;

if($Config{nvsize} != 8) {

  print "1..2\n";

  if(Math::MPFR::_fallback_notify()) { print "not ok 1\n"}
  else {print "ok 1\n"}

  eval {my $x = doubletoa(42.0) };

  if($@ =~ /^The doubletoa function is unavailable/) { print "ok 2\n" }
  else {
    warn "\$\@: $@\n";
    print "not ok 2\n";
  }

}

elsif(MPFR_VERSION() <= 196869) {
  print "1..1\n";
  warn "\nSkipping all tests - they require mpfr-3.1.6 or later\n";
  print "ok 1\n";
}

else {

  print "1..11\n";

  my $ok = 1;
  my $fb = Math::MPFR::_fallback_notify();
  my $fb_tracker = 0;
  my ($count, $mismatch_count) = (0, 0);


  for my $iteration(1..1000) {
    last unless $ok;
    for my $exp(-326 .. 325) {
      $count++;
      my $str = rand(100);
      if($str !~ /e/) { $str .= (int(rand(10)) . int(rand(10)) . "e$exp") }
      $str = '-' . $str unless $iteration % 3;
      if($fb) { $fb_tracker = $Math::MPFR::doubletoa_fallback }
      my $v = $str + 0;
      my $s1 = doubletoa($v, "S");
      my $s2 = nvtoa($v);

      if($s1 ne $s2) {
        #print "$str $s1 $s2\n";
        $mismatch_count++;
        my $s1_alt = doubletoa($v);

        if($fb && $Math::MPFR::doubletoa_fallback - $fb_tracker != 2) {
          $ok = 0;
          warn "\nfallback anomaly with $str: $s1 ($s1_alt) $s2\n";
          last;
        }

        my ($check1, $check2, $check3) =  (
                                           ($s1 eq $s1_alt),
                                           (atonv($s1) != atonv($s1_alt)),
                                           (atonv($s1) != atonv($s2))
                                          );

        if($check1 || $check2 || $check3) {
          $ok = 0;
          warn "\nmismatch for $str: $s1 ($s1_alt) $s2\n";
          last;
        }
      }
    }
  }

#  print "Fallback: $Math::MPFR::doubletoa_fallback Mismatch: $mismatch_count\n";

  if($ok) { print "ok 1\n" }
  else { print "not ok 1\n" }

  if($fb) {
    if($count > 10000) {
      if($Math::MPFR::doubletoa_fallback > 10 && $count / $Math::MPFR::doubletoa_fallback > 50) {
        print "ok 2\n";
      }
      else {
        warn "\n  Total Count: $count\nFallback count: $Math::MPFR::doubletoa_fallback\n";
        print "not ok 2\n";
      }
    }
    else {
      warn "\n Skipping test 2 - didn't test enough values\n";
      print "ok 2\n";
    }
  }
  else {
    if($Math::MPFR::doubletoa_fallback) { print "not ok 2\n" }
    else { print "ok 2\n" }
  }

  if(doubletoa(atodouble('8e94')) eq '8e+94') { print "ok 3\n" }
  else {
    warn "\nexpected: '8e+94'\ngot     : '", doubletoa(atodouble('8e+94')), "'\n";
    print "not ok 3\n";
  }

  if(doubletoa(atodouble('-8e94')) eq '-8e+94') { print "ok 4\n" }
  else {
    warn "\nexpected: '-8e+94'\ngot     : '", doubletoa(atodouble('-8e+94')), "'\n";
    print "not ok 4\n";
  }

  if(doubletoa(atodouble('80e94')) eq '8e+95') { print "ok 5\n" }
  else {
    warn "\nexpected: '8e+95'\ngot     : '", doubletoa(atodouble('80e+94')), "'\n";
    print "not ok 5\n";
  }

  if(doubletoa(atodouble('81e94')) eq '8.1e+95') { print "ok 6\n" }
  else {
    warn "\nexpected: '8.1e+95'\ngot     : '", doubletoa(atodouble('81e+94')), "'\n";
    print "not ok 6\n";
  }

  if(doubletoa(atodouble('8000000e94')) eq '8e+100') { print "ok 7\n" }
  else {
    warn "\nexpected: '8e+100'\ngot     : '", doubletoa(atodouble('8000000e+94')), "'\n";
    print "not ok 7\n";
  }

  # 1e+23 is one of the values that Grisu3 cannot handle.

  my $d    = atodouble('1e+23');
  my $dtoa = doubletoa($d); # fall back to dragon

  if($dtoa eq '1e+23') { print "ok 8\n" }
  else {
    warn "\nexpected: '1e+23'\ngot     : '", $dtoa, "'\n";
    print "not ok 8\n";
  }

  $dtoa = doubletoa($d, ''); # fall back to sprintf("%.17g", $d)

  if($dtoa eq '9.9999999999999992e+22' || $dtoa eq '9.9999999999999992e+022') { print "ok 9\n" }
  else {
    warn "\nexpected: '9.9999999999999992e+22 or 9.9999999999999992e+022'\ngot     : '", $dtoa, "'\n";
    print "not ok 9\n";
  }

  $dtoa = doubletoa(0.0);

  if($dtoa eq '0.0') { print "ok 10\n" }
  else {
    warn "\nexpected: '0.0'\ngot     : '", $dtoa, "'\n";
    print "not ok 10\n";
  }

  my $z = Math::MPFR->new(0);
  Rmpfr_neg($z, $z, MPFR_RNDN); # $z is -0.0
  my $negzero = Rmpfr_get_NV($z, MPFR_RNDN);

  $dtoa = doubletoa($negzero);

  if($dtoa eq '-0.0') { print "ok 11\n" }
  else {
    warn "\nexpected: '-0.0'\ngot     : '", $dtoa, "'\n";
    print "not ok 11\n";
  }
}


__END__
