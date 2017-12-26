use warnings;
use strict;
use Math::GMPz;

print "1..2\n";

eval {require Math::MPFR;};

unless($@) {
  if($Math::MPFR::VERSION <= 3.12) {
    warn "\n  Skipping tests -  Math::MPFR version 3.13 (or later)\n" .
          "  is needed. We have only version $Math::MPFR::VERSION\n";
    print "ok 1\n";
  }
  else {
    my($rop, $op, $op_pow, $mpz, $ok);
    # Run the tests.
    $op = Math::MPFR->new(100);
    $op_pow = Math::MPFR->new(3.5);
    $mpz = Math::GMPz->new(10075);

    $rop = $mpz + $op;
    if(ref($rop) eq 'Math::MPFR'){$ok .= 'a'}
    else { warn "1a: ref: ", ref($rop), "\n"}
    if($rop == 10175) {$ok .= 'b'}
    else {warn "1b: \$rop: $rop\n"}

    $rop = $mpz * $op;
    if(ref($rop) eq 'Math::MPFR'){$ok .= 'c'}
    else { warn "1c: ref: ", ref($rop), "\n"}
    if($rop == 1007500) {$ok .= 'd'}
    else {warn "1d: \$rop: $rop\n"}

    $rop = $mpz - $op;
    if(ref($rop) eq 'Math::MPFR'){$ok .= 'e'}
    else { warn "1e: ref: ", ref($rop), "\n"}
    if($rop == 9975) {$ok .= 'f'}
    else {warn "1f: \$rop: $rop\n"}

    $rop = $mpz / $op;
    if(ref($rop) eq 'Math::MPFR'){$ok .= 'g'}
    else { warn "1g: ref: ", ref($rop), "\n"}
    if($rop == 100.75) {$ok .= 'h'}
    else {warn "1h: \$rop: $rop\n"}

    $mpz /= 100;

    $rop = $mpz ** $op_pow;
    if(ref($rop) eq 'Math::MPFR'){$ok .= 'i'}
    else { warn "1i: ref: ", ref($rop), "\n"}
    if($rop == 10000000) {$ok .= 'j'}
    else {warn "1j: \$rop: $rop\n"}

    my $ccount = Math::GMPz::_wrap_count();

    for(1..100) {
      $rop = $mpz + $op;
      $rop = $mpz - $op;
      $rop = $mpz * $op;
      $rop = $mpz / $op;
      $rop = $mpz ** $op_pow;
    }

    my $ncount = Math::GMPz::_wrap_count();

    if($ccount == $ncount) {$ok .= 'k'}
    else { warn "1k: \$ccount: $ccount \$ncount: $ncount\n Looks like we have a memory leak\n"}

    if($ok eq 'abcdefghijk') {print "ok 1\n"}
    else {
      warn "\$ok: $ok\n";
      print "not ok 1\n";
    }
  }
}
else {
  warn "\nSkipping Math::MPFR tests - no Math::MPFR\n";
  print "ok 1\n";
}

eval {require Math::GMPq;};

unless($@) {
  if($Math::GMPq::VERSION <= 0.42) {
    warn "\n  Skipping tests -  Math::GMPq version 0.43 (or later)\n" .
          "  is needed. We have only version $Math::GMPq::VERSION\n";
    print "ok 2\n";
  }
  else {
    my($rop, $op, $op_pow, $mpz, $ok);
    # Run the tests.
    $op = Math::GMPq->new('100/37');
    $mpz = Math::GMPz->new(10075);

    $rop = $mpz + $op;
    if(ref($rop) eq 'Math::GMPq'){$ok .= 'a'}
    else { warn "1a: ref: ", ref($rop), "\n"}
    if($rop == '372875/37') {$ok .= 'b'}
    else {warn "1b: \$rop: $rop\n"}

    $rop = $mpz * $op;
    if(ref($rop) eq 'Math::GMPq'){$ok .= 'c'}
    else { warn "1c: ref: ", ref($rop), "\n"}
    if($rop == '1007500/37') {$ok .= 'd'}
    else {warn "1d: \$rop: $rop\n"}

    $rop = $mpz - $op;
    if(ref($rop) eq 'Math::GMPq'){$ok .= 'e'}
    else { warn "1e: ref: ", ref($rop), "\n"}
    if($rop == '372675/37') {$ok .= 'f'}
    else {warn "1f: \$rop: $rop\n"}

    $rop = $mpz / $op;
    if(ref($rop) eq 'Math::GMPq'){$ok .= 'g'}
    else { warn "1g: ref: ", ref($rop), "\n"}
    if($rop == '14911/4') {$ok .= 'h'}
    else {warn "1h: \$rop: $rop\n"}

    my $ccount = Math::GMPz::_wrap_count();

    for(1..100) {
      $rop = $mpz + $op;
      $rop = $mpz - $op;
      $rop = $mpz * $op;
      $rop = $mpz / $op;
    }

    my $ncount = Math::GMPz::_wrap_count();

    if($ccount == $ncount) {$ok .= 'j'}
    else { warn "2j: \$ccount: $ccount \$ncount: $ncount\n Looks like we have a memory leak\n"}

    if($ok eq 'abcdefghj') {print "ok 2\n"}
    else {
      warn "\$ok: $ok\n";
      print "not ok 2\n";
    }
  }
}
else {
  warn "\nSkipping Math::GMPq tests - no Math::GMPq\n";
  print "ok 2\n";
}

