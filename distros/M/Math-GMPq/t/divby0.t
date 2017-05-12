use strict;
use warnings;
use Math::GMPq qw(:mpq);

# Test that we catch divby0 in:
# Rmpq_div
# Rmpq_div_z
# Rmpq_z_div
# overload_div		(div by IV, NV, PV, object)
# overload_div_eq	(div by IV, NV, PV, object)

# t/NV_overloading.t tests that operations involving
# Inf and NaN are caught

print "1..24\n";

############
# Rmpq_div #
############

my $rop = Math::GMPq->new(-42);
my $q1 = Math::GMPq->new('7/10');
my $q2 = Math::GMPq->new('0/1');

eval{Rmpq_div($rop, $q1, $q2);};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div/) {print "ok 1\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$rop $q1 $q2\n";
  print "not ok 1\n";
}

eval{Rmpq_div($q1, $q1, $q2);};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div/) {print "ok 2\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$rop $q1 $q2\n";
  print "not ok 2\n";
}

eval{Rmpq_div($q2, $q1, $q2);};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div/) {print "ok 3\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$rop $q1 $q2\n";
  print "not ok 3\n";
}

######################
# overload_div by IV #
######################

eval{$rop = $q1 / 0;};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div/) {print "ok 4\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$rop $q1\n";
  print "not ok 4\n";
}

######################
# overload_div by NV #
######################

eval{$rop = $q1 / 0.0;};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div/) {print "ok 5\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$rop $q1\n";
  print "not ok 5\n";
}

#######################
# overload_div by str #
#######################

eval{$rop = $q1 / '0';};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div/) {print "ok 6\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$rop $q1\n";
  print "not ok 6\n";
}

#########################
# overload_div by mpq_t #
#########################

eval{$rop = $q1 / Math::GMPq->new('0/1');};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div/) {print "ok 7\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$rop $q1\n";
  print "not ok 7\n";
}

#########################
#########################

#########################
# overload_div_eq by IV #
#########################

eval{$q1 /= 0;};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div_eq/) {print "ok 8\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$q1\n";
  print "not ok 8\n";
}

#########################
# overload_div_eq by NV #
#########################

eval{$q1 /= 0.0;};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div_eq/) {print "ok 9\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$q1\n";
  print "not ok 9\n";
}

##########################
# overload_div_eq by str #
##########################

eval{$q1 /= '0';};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div_eq/) {print "ok 10\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$q1\n";
  print "not ok 10\n";
}

############################
# overload_div_eq by mpq_t #
############################

eval{$q1 /= Math::GMPq->new('0/1');};

if($@ =~ /^Division by 0 not allowed in Math::GMPq::overload_div_eq/) {print "ok 11\n"}
else {
  warn "\n\$\@: $@\n";
  warn "$q1\n";
  print "not ok 11\n";
}

eval{require Math::GMPz;};

if(!$@) {

  #############################
  # divisions involving mpz_t #
  #############################

  my $z0 = Math::GMPz->new(0);
  my $z1 = Math::GMPz->new(42);
  my $q0 = Math::GMPq->new(0);
  my $q1 = Math::GMPq->new('41/42');
  my $rop = Math::GMPq->new(-1);

  eval{Rmpq_div_z($rop, $q1, $z0);};

  if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div_z/) {print "ok 12\n"}
  else {
    warn "\n\$\@: $@\n";
    warn "$rop $q1\n";
    print "not ok 12\n";
  }

  eval{Rmpq_div_z($q1, $q1, $z0);};

  if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div_z/) {print "ok 13\n"}
  else {
    warn "\n\$\@: $@\n";
    warn "$q1\n";
    print "not ok 13\n";
  }

  eval{Rmpq_z_div($rop, $z1, $q0);};

  if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_z_div/) {print "ok 14\n"}
  else {
    warn "\n\$\@: $@\n";
    warn "$rop $q0\n";
    print "not ok 14\n";
  }

  eval{Rmpq_z_div($q0, $z1, $q0);};

  if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_z_div/) {print "ok 15\n"}
  else {
    warn "\n\$\@: $@\n";
    warn "$q0\n";
    print "not ok 15\n";
  }

  eval{$rop = $q1 / $z0;};

  if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div_z/) {print "ok 16\n"}
  else {
    warn "\n\$\@: $@\n";
    warn "$rop $q1\n";
    print "not ok 16\n";
  }

  eval{$q1 = $q1 / $z0;};

  if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div_z/) {print "ok 17\n"}
  else {
    warn "\n\$\@: $@\n";
    warn "$q1\n";
    print "not ok 17\n";
  }

  # Tests 18 and 19 require version 0.47 of Math::GMPz

  if($Math::GMPz::VERSION >= 0.47) {

    eval{$rop = $z1 / $q0;};

    if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_z_div/) {print "ok 18\n"}
    else {
      warn "\n\$\@: $@\n";
      warn "$rop $q0\n";
      print "not ok 18\n";
    }

    eval{$q0 = $z1 / $q0;};

    if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_z_div/) {print "ok 19\n"}
    else {
      warn "\n\$\@: $@\n";
      warn "$q0\n";
      print "not ok 19\n";
    }

  }
  else {
    warn "\nSkipping tests 18 and 19 - need Math-GMPz-0.47\n";
    print "ok 18\n";
    print "ok 19\n";
  }

  eval{$q1 /= $z0;};

  if($@ =~ /^Division by 0 not allowed in Math::GMPq::Rmpq_div_z/) {print "ok 20\n"}
  else {
    warn "\n\$\@: $@\n";
    warn "$q1\n";
    print "not ok 20\n";
  }
}
else {
  warn "\n\$\@: $@\n";
  warn "Skipping tests 12 to 20 - could not load Math::GMPz\n";
  for(12..20) {print "ok $_\n"}
}

eval{require Math::MPFR;};

if($@) {
  warn "\n\$\@: $@\n";
  warn "Skipping tests 21 to 24 - could not load Math::MPFR\n";
  for(21..24) {print "ok $_\n"}
}

#elsif($Math::MPFR::VERSION < 3.36) {
#  warn "Skipping tests 21 to 24 - need Math-MPFR-3.36 or later\n";
#  warn "We have only version $Math::MPFR::VERSION\n";
#  for(21..24) {print "ok $_\n"}
#}

else {

  #################################
  # overloaded division by mpfr_t #
  #################################

  my $fr0 = Math::MPFR->new(0);
  my $pq = Math::GMPq->new('1/10031256');
  my $nq = $pq * -1;
  my $zq = Math::GMPq->new(0);
  my $pinf = $pq / $fr0;

  if(Math::MPFR::Rmpfr_inf_p($pinf) && $pinf > 0) {print "ok 21\n"}
  else {
    warn "\nExpected +Inf, got $pinf\n";
    print "not ok 21\n";
  }

  my $ninf = $nq / $fr0;
  if(Math::MPFR::Rmpfr_inf_p($ninf) && $ninf < 0) {print "ok 22\n"}
  else {
    warn "\nExpected -Inf, got $ninf\n";
    print "not ok 22\n";
  }

  my $nan = $zq / $fr0;
  if(Math::MPFR::Rmpfr_nan_p($nan)) {print "ok 23\n"}
  else {
    warn "\nExpected NaN, got $nan\n";
    print "not ok 23\n";
  }

  if($pinf == $nq / ($fr0 * -1)) {print "ok 24\n"}
  else {
    warn "\nExpected +Inf, got ", $nq / ($fr0 * -1), "\n";
    print "not ok 24\n";
  }
}

