use warnings;
use strict;
use Math::GMPz;

print "1..1\n";

my($rop, $op, $op_pow, $mpz, $ok);

eval {require Math::MPFR;};


unless($@) {
  if($Math::MPFR::VERSION <= 3.12) {
    warn "\n  Skipping tests -  Math::MPFR version 3.13 (or later)\n" .
          "  is needed. We have only version $Math::MPFR::VERSION\n";
    print "ok 1\n";
  }
  else {

    if($Math::MPFR::VERSION >= 4.19) {
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
      $mpz -= 0.75;

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
      else {
        warn "1k: \$ccount: $ccount \$ncount: $ncount\n";
        warn "Looks like we have a memory leak\n" if $ncount > $ccount;
      }

      if($ok eq 'abcdefghijk') {print "ok 1\n"}
      else {
        warn "\$ok: $ok\n";
        print "not ok 1\n";
      }
    }
    else {
      warn "\nSkipping all tests, as some of these tests will fail.\n";
      warn "Math-MPFR-4.19 or later is needed for all tests to PASS\n";
      warn "We have only version $Math::MPFR::VERSION";
      print "ok 1\n";
    }
  }
}
else {
  warn "\nSkipping tests - no Math::MPFR\n";
  print "ok 1\n";
}

# Check that the &PL_sv_yes bug
# does not rear its ugly head here
# See https://github.com/sisyphus/math-decimal64/pull/1

sub hmmmm () {!0}
sub aaarh () {!1}
