use warnings;
use strict;
use Config;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "# Using mpfr version ", MPFR_VERSION_STRING, "\n";
print "# Using mpc library version ", MPC_VERSION_STRING, "\n";
my $prec = Math::MPC::_get_nv_precision();
warn "\n# using precision: $prec\n";

print "1..10\n";

if($Config{nvtype} eq '__float128') {
  if($prec == 113){print "ok 1\n"}
  else {
    warn "\nExpected 113, got $prec\n";
    print "not ok 1\n";
  }
}
elsif($Config{nvtype} eq 'long double') {
  if(defined $Config{longdblkind}) {
    my $k = $Config{longdblkind};
    warn "\n \$Config{longdblkind} is: $k\n";
    if($k == 0) {
      if($prec == 53){print "ok 1\n"}
      else {
        warn "\nExpected 53, got $prec\n";
        print "not ok 1\n";
      }
    }
    elsif($k == 1 || $k == 2) {
      if($prec == 113){print "ok 1\n"}
      else {
        warn "\nExpected 113, got $prec\n";
        print "not ok 1\n";
      }
    }
    elsif($k == 3 || $k == 4) {
      if($prec == 64){print "ok 1\n"}
      else {
        warn "\nExpected 64, got $prec\n";
        print "not ok 1\n";
      }
    }
    elsif($k >= 5 || $k <= 8) {
      if($prec == 2098){print "ok 1\n"}
      else {
        warn "\nExpected 2098, got $prec\n";
        print "not ok 1\n";
      }
    }
    else {
      warn "\n\$Config{longdblkind} is: $k\n";
      print "not ok 1\n";
    }
  }
  else {
    warn "\n\$Config{longdblkind} not defined\n";
    if($prec == 53 || $prec == 64 || $prec == 113 || $prec == 2098) {print "ok 1\n"}
    else {print "not ok 1\n"}
  }
}
elsif($Config{nvtype} eq 'double') {
  if($prec == 53) {print "ok 1\n"}
  else {
    warn "\nExpected 53, got $prec\n";
    print "not ok 1\n";
  }
}
else {
  warn "Unexpected nvtype: $Config{nvtype}\n";
  print "not ok 1\n";
}

Rmpc_set_default_prec2($prec, $prec);
Rmpfr_set_default_prec($prec);

my $mpc  = Math::MPC->new();
my $real = Math::MPFR->new();
my $imag = Math::MPFR->new();
Rmpc_set_NV($mpc, -3.0,  MPC_RNDNN);
Rmpc_sqrt  ($mpc, $mpc, MPC_RNDNN);

RMPC_RE($real, $mpc);
RMPC_IM($imag, $mpc);

if($real == 0) {print "ok 2\n"}
else {
  warn "\nexpected 0, got $real\n";
  print "not ok 2\n";
}

if($prec != 2098) {

  if($imag == sqrt(3.0)) {print "ok 3\n"}
  else {
    warn "\nexpected ", sqrt(3.0), ", got $imag\n";
    print "not ok 3\n";
  }

  Rmpc_set_NV_NV($mpc, 0.0, sqrt(3.0), MPC_RNDNN);

  $mpc **= 2;

  RMPC_RE($real, $mpc);
  RMPC_IM($imag, $mpc);

  my $re_expected = (sqrt(3.0) ** 2) * -1.0;

  if($real == $re_expected) {print "ok 4\n"}
  else {
    warn "\nexpected $re_expected, got $real\n";
    print "not ok 4\n";
  }
}
else {
  ##########
  # Not sure how to get exact agreement with sqrt on double-double.
  # In the interim, just check for approximate correctness.

  my $eps = 1.3e-32;

  my $ld = Rmpfr_get_ld($imag, MPFR_RNDN);
  if($ld - sqrt(3.0) > -$eps && $ld - sqrt(3.0) < $eps) {print "ok 3\n"}
  else {
    warn "\nexpected ", sqrt(3.0), ", got $ld\nDifference is ", $ld - sqrt(3.0), "\n";
    print "not ok 3\n";
  }

  Rmpc_set_NV_NV($mpc, 0.0, sqrt(3.0), MPC_RNDNN);

  $mpc **= 2;

  RMPC_RE($real, $mpc);
  RMPC_IM($imag, $mpc);

  my $re_expected = (sqrt(3.0) ** 2) * -1.0;

  $ld = Rmpfr_get_ld($real, MPFR_RNDN);

  if($ld - $re_expected > -$eps && $ld - $re_expected < $eps) {print "ok 4\n"}
  else {
    warn "\nexpected $re_expected, got $ld\nDifference is ", $ld - $re_expected, "\n";
    print "not ok 4\n";
  }
  ###########
}

if($imag == 0) {print "ok 5\n"}
else {
  warn "\nexpected 0 got $imag\n";
  print "not ok 5\n";
}

my $inf = 999**(999**999);
my $fin = -1.39e-35;

Rmpc_set_NV_NV($mpc, $fin, $inf, MPC_RNDNN);

RMPC_RE($real, $mpc);
RMPC_IM($imag, $mpc);

if($real == $fin) {print "ok 6\n"}
else {
  warn "\nexpected $fin, got $real\n";
  print "not ok 6\n";
}

if($imag == $inf) {print "ok 7\n"}
else {
  warn "\nexpected $inf, got $imag\n";
  print "not ok 7\n";
}

if($mpc == Math::MPC->new($fin) + Math::MPC->new(0,'inf')) {print "ok 8\n"}
else {
  warn "\nexpected $mpc, got",  Math::MPC->new($fin) + Math::MPC->new(0,'inf'), "\n";
  print "not ok 8\n";
}

Rmpc_set_NV_NV($mpc, $inf, $fin, MPC_RNDNN);

RMPC_RE($real, $mpc);
RMPC_IM($imag, $mpc);

if($real == $inf) {print "ok 9\n"}
else {
  warn "\nexpected $inf, got $real\n";
  print "not ok 9\n";
}

if($imag == $fin) {print "ok 10\n"}
else {
  warn "\nexpected $fin, got $imag\n";
  print "not ok 10\n";
}





