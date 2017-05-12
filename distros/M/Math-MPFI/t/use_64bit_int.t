use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

my $tests = 14;

print "1..$tests\n";

Rmpfi_set_default_prec(65);

if(Math::MPFI::_has_longlong()) {
  my $bi = 36028797018964023;

  my $rop = Math::MPFI->new(2);
  $rop = sqrt($rop);

  my $fr = Math::MPFR->new(2);
  $fr = sqrt($fr);

  ## Add, Sub

  $rop = $rop + $bi;
  $fr = $fr + $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 1\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 1\n";
  }

  $rop += $bi;
  $fr += $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 2\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 2\n";
  }


  $rop -= $bi;
  $fr -= $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 3\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 3\n";
  }


  $rop = $rop - $bi;
  $fr = $fr - $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 4\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 4\n";
  }


  ## Mul, Div

  $rop = $rop * $bi;
  $fr = $fr * $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 5\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 5\n";
  }


  $rop *= $bi;
  $fr *= $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 6\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 6\n";
  }


  $rop /= $bi;
  $fr /= $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 7\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 7\n";
  }


  $rop = $rop / $bi;
  $fr = $fr / $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 8\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 8\n";
  }


  ## Sub, Mul

  $rop = $bi - $rop;
  $fr = $bi - $fr;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 9\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 9\n";
  }


  $rop -= $bi;
  $fr -= $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 10\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 10\n";
  }


  $rop *= -1;
  $fr *= -1;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 11\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 11\n";
  }


  $rop = $bi / $rop;
  $fr = $bi / $fr;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 12\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 12\n";
  }


  $rop /= $bi;
  $fr /= $bi;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 13\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 13\n";
  }


  Rmpfi_inv($rop, $rop);
  $fr = 1 / $fr;
  if(!Rmpfi_cmp_fr($rop, $fr)) {print "ok 14\n"}
  else {
    warn "\$rop: $rop\n\$fr: $fr\n";
    print "not ok 14\n";
  }

} # _has_longlong

else {
  warn "Skipping all tests - Math::MPFI::_has_longlong() returned false\n";
  for(1..$tests) {print "ok $_\n"}
}
