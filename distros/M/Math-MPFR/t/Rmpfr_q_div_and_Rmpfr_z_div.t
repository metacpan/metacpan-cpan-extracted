use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..28\n";

eval{require Math::GMPq;};

if($@) {
  warn "\n\$\@: $@\n";
  warn "\nSkipping mpq tests - couldn't load Math::GMPq\n";
  for(1..14) {print "ok $_\n"}
}
else {
  my $rop = Math::MPFR->new();
  my $fr = Math::MPFR->new(23);
  my $q = Math::GMPq->new('1/3');
  my $check = Math::MPFR->new(Math::GMPq->new('1/69'));

  my $inex = Rmpfr_q_div($fr, $q, $fr, MPFR_RNDN);

  if($inex) {print "ok 1\n"}
  else {
    warn "\n\$inex: $inex\n";
    print "not ok 1\n";
  }

  if($check == $fr) {print "ok 2\n"}
  else {
    warn "\nExpected $check, got $fr\n";
    print "not ok 2\n";
  }

  $inex = Rmpfr_q_div($rop, $q, Math::MPFR->new(27), MPFR_RNDN);

  my $inex2 = Rmpfr_set_q($check, Math::GMPq->new('1/81'), MPFR_RNDN);

  if($inex == $inex2) {print "ok 3\n"}
  else {
    warn "\nExpected $inex, got $inex2\n";
    print "not ok 3\n";
  }

  if($rop == $check) {print "ok 4\n"}
  else {
    warn "\nExpected $rop, got $check\n";
    print "not ok 4\n";
  }

  $rop = $q / Math::MPFR->new(-10);
  Rmpfr_set_q($check, Math::GMPq->new('-1/30'), MPFR_RNDN);
  if($rop == $check) {print "ok 5\n"}
  else {
    warn "$rop != $check\n";
    print "not ok 5\n";
  }

  #########################
  # divide by Inf, NaN, 0 #
  #########################

  my $pzero = Math::MPFR->new(0);
  my $nzero = $pzero * -1.0;
  my $pinf  = Math::MPFR->new(1) / $pzero;
  my $ninf  = $pinf * -1.0;
  my $nan   = $pinf / $pinf;
  my $pq    = Math::GMPq->new('1/7');
  my $nq    = Math::GMPq->new('-1/7');
  my $zq    = $pq + $nq;

  my $rop1  = Math::MPFR->new();
  my $rop2  = Math::MPFR->new();

  Rmpfr_q_div($rop1, $pq, $pzero, MPFR_RNDN);
  Rmpfr_q_div($rop2, $pq, $nzero, MPFR_RNDN);

  if($rop1 > 0 && $rop1 == $rop2 * -1.0 && Rmpfr_inf_p($rop1)) {print "ok 6\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 6\n";
  }

  Rmpfr_q_div($rop1, $nq, $pzero, MPFR_RNDN);
  Rmpfr_q_div($rop2, $nq, $nzero, MPFR_RNDN);

  if($rop1 < 0 && $rop1 == $rop2 * -1.0 && Rmpfr_inf_p($rop1)) {print "ok 7\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 7\n";
  }

  Rmpfr_q_div($rop1, $zq, $pzero, MPFR_RNDN);
  Rmpfr_q_div($rop2, $zq, $nzero, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1) && Rmpfr_nan_p($rop2)) {print "ok 8\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 8\n";
  }

  Rmpfr_q_div($rop1, $pq, $pinf, MPFR_RNDN);
  Rmpfr_q_div($rop2, $pq, $ninf, MPFR_RNDN);

  if(Rmpfr_zero_p($rop1) && Rmpfr_zero_p($rop2) && !Rmpfr_signbit($rop1) && Rmpfr_signbit($rop2)) {print "ok 9\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 9\n";
  }

  Rmpfr_q_div($rop1, $nq, $pinf, MPFR_RNDN);
  Rmpfr_q_div($rop2, $nq, $ninf, MPFR_RNDN);

  if(Rmpfr_zero_p($rop1) && Rmpfr_zero_p($rop2) && Rmpfr_signbit($rop1) && !Rmpfr_signbit($rop2)) {print "ok 10\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 10\n";
  }

  Rmpfr_q_div($rop1, $zq, $pinf, MPFR_RNDN);
  Rmpfr_q_div($rop2, $zq, $ninf, MPFR_RNDN);

  if(Rmpfr_zero_p($rop1) && Rmpfr_zero_p($rop2) && !Rmpfr_signbit($rop1) && Rmpfr_signbit($rop2)) {print "ok 11\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 11\n";
  }

  Rmpfr_q_div($rop1, $pq, $nan, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1)) {print "ok 12\n"}
  else {
    warn "$rop1\n";
    print "not ok 12\n";
  }

  Rmpfr_q_div($rop1, $nq, $nan, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1)) {print "ok 13\n"}
  else {
    warn "$rop1\n";
    print "not ok 13\n";
  }

  Rmpfr_q_div($rop1, $zq, $nan, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1)) {print "ok 14\n"}
  else {
    warn "$rop1\n";
    print "not ok 14\n";
  }
}

eval{require Math::GMPz;};

if($@) {
  warn "\n\$\@: $@\n";
  warn "\nSkipping mpz tests - couldn't load Math::GMPz\n";
  for(15..28) {print "ok $_\n"}
}
else {
  my $rop = Math::MPFR->new();
  my $fr = Math::MPFR->new(23);
  my $z = Math::GMPz->new(11);
  my $check = Math::MPFR->new(Math::MPFR->new(11) / Math::MPFR->new(23));

  my $inex = Rmpfr_z_div($fr, $z, $fr, MPFR_RNDN);

  if($inex) {print "ok 15\n"}
  else {
    warn "\n\$inex: $inex\n";
    print "not ok 15\n";
  }

  if($check == $fr) {print "ok 16\n"}
  else {
    warn "\nExpected $check, got $fr\n";
    print "not ok 16\n";
  }

  $inex = Rmpfr_z_div($rop, $z, Math::MPFR->new(27), MPFR_RNDN);

  my $inex2 = Rmpfr_set($check, Math::MPFR->new(11) / Math::MPFR->new(27), MPFR_RNDN);

  if(0 == $inex2) {print "ok 17\n"}
  else {
    warn "\nExpected $inex, got $inex2\n";
    print "not ok 17\n";
  }

  if($rop == $check) {print "ok 18\n"}
  else {
    warn "\nExpected $rop, got $check\n";
    print "not ok 18\n";
  }

  $rop = $z / Math::MPFR->new(-10);
  Rmpfr_set($check, Math::MPFR->new(11) / Math::MPFR->new(-10), MPFR_RNDN);
  if($rop == $check) {print "ok 19\n"}
  else {
    warn "$rop != $check\n";
    print "not ok 19\n";
  }

  #########################
  # divide by Inf, NaN, 0 #
  #########################

  my $pzero = Math::MPFR->new(0);
  my $nzero = $pzero * -1.0;
  my $pinf  = Math::MPFR->new(1) / $pzero;
  my $ninf  = $pinf * -1.0;
  my $nan   = $pinf / $pinf;
  my $pz    = Math::GMPz->new('17');
  my $nz    = Math::GMPz->new('-17');
  my $zz    = $pz + $nz;

  my $rop1  = Math::MPFR->new();
  my $rop2  = Math::MPFR->new();

  Rmpfr_z_div($rop1, $pz, $pzero, MPFR_RNDN);
  Rmpfr_z_div($rop2, $pz, $nzero, MPFR_RNDN);

  if($rop1 > 0 && $rop1 == $rop2 * -1.0 && Rmpfr_inf_p($rop1)) {print "ok 20\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 20\n";
  }

  Rmpfr_z_div($rop1, $nz, $pzero, MPFR_RNDN);
  Rmpfr_z_div($rop2, $nz, $nzero, MPFR_RNDN);

  if($rop1 < 0 && $rop1 == $rop2 * -1.0 && Rmpfr_inf_p($rop1)) {print "ok 21\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 21\n";
  }

  Rmpfr_z_div($rop1, $zz, $pzero, MPFR_RNDN);
  Rmpfr_z_div($rop2, $zz, $nzero, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1) && Rmpfr_nan_p($rop2)) {print "ok 22\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 22\n";
  }

  Rmpfr_z_div($rop1, $pz, $pinf, MPFR_RNDN);
  Rmpfr_z_div($rop2, $pz, $ninf, MPFR_RNDN);

  if(Rmpfr_zero_p($rop1) && Rmpfr_zero_p($rop2) && !Rmpfr_signbit($rop1) && Rmpfr_signbit($rop2)) {print "ok 23\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 23\n";
  }

  Rmpfr_z_div($rop1, $nz, $pinf, MPFR_RNDN);
  Rmpfr_z_div($rop2, $nz, $ninf, MPFR_RNDN);

  if(Rmpfr_zero_p($rop1) && Rmpfr_zero_p($rop2) && Rmpfr_signbit($rop1) && !Rmpfr_signbit($rop2)) {print "ok 24\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 24\n";
  }

  Rmpfr_z_div($rop1, $zz, $pinf, MPFR_RNDN);
  Rmpfr_z_div($rop2, $zz, $ninf, MPFR_RNDN);

  if(Rmpfr_zero_p($rop1) && Rmpfr_zero_p($rop2) && !Rmpfr_signbit($rop1) && Rmpfr_signbit($rop2)) {print "ok 25\n"}
  else {
    warn "$rop1 $rop2\n";
    print "not ok 25\n";
  }

  Rmpfr_z_div($rop1, $pz, $nan, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1)) {print "ok 26\n"}
  else {
    warn "$rop1\n";
    print "not ok 26\n";
  }

  Rmpfr_z_div($rop1, $nz, $nan, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1)) {print "ok 27\n"}
  else {
    warn "$rop1\n";
    print "not ok 27\n";
  }

  Rmpfr_z_div($rop1, $zz, $nan, MPFR_RNDN);

  if(Rmpfr_nan_p($rop1)) {print "ok 28\n"}
  else {
    warn "$rop1\n";
    print "not ok 28\n";
  }
}

