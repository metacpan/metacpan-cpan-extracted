
# testing mpc_rootofunity and mpc_cmp_abs,
# which are new in mpc-1.1.0.

use strict;
use warnings;

use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

my $skip;
$skip = 65792 > MPC_VERSION() ? 1 : 0;

my $mpc1 = Math::MPC->new();
my $mpc2 = Math::MPC->new();

if($skip) {

  print "1..2\n";

  eval {Rmpc_cmp_abs($mpc1, $mpc2);};
  if($@ =~ /^Rmpc_cmp_abs not available/) {print "ok 1\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 1\n";
  }

  eval {Rmpc_rootofunity($mpc1, 1, 2, MPC_RNDNN);};
  if($@ =~ /^Rmpc_rootofunity not available/) {print "ok 2\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 2\n";
  }

}
else {
  print "1..7\n";

  Rmpc_set_si_si($mpc1, -1, 1, MPC_RNDNN);
  Rmpc_set_si_si($mpc2, 1, -1, MPC_RNDNN);

  my $ret = Rmpc_cmp_abs($mpc1, $mpc2);

  if($ret == 0) {print "ok 1\n"}
  else {
    warn "\n Expected 0, got $ret\n";
    print "not ok 1\n";
  }

  Rmpc_set_si($mpc2, -2, MPC_RNDNN);

  $ret = Rmpc_cmp_abs($mpc1, $mpc2);

  if($ret < 0) {print "ok 2\n"}
  else {
    warn "\n Expected a -ve value, got $ret\n";
    print "not ok 2\n";
  }

  $ret = Rmpc_cmp_abs($mpc2, $mpc1);

  if($ret > 0) {print "ok 3\n"}
  else {
    warn "\n Expected a +ve value, got $ret\n";
    print "not ok 3\n";
  }

  my $root = Math::MPC->new();

  Rmpc_rootofunity($root, 3, 2, MPC_RNDNN);

  #print "$root\n";

  my($mpfr, $mpfr2) = (Math::MPFR->new(), Math::MPFR->new());
  Rmpfr_const_pi($mpfr, MPFR_RNDN);
  my $mpfr1 = $mpfr * 4 / 3;
  Rmpc_set_d_fr($mpc2, 0.0, $mpfr1, MPC_RNDNN);
  Rmpc_exp($mpc1, $mpc2, MPC_RNDNN);

  #print "$mpc1\n";

  RMPC_RE($mpfr1, $mpc1);
  RMPC_RE($mpfr2, $root);

  if(abs($mpfr1 - $mpfr2) < 0.00000000000001) {print "ok 4\n"}
  else {
    warn $mpfr1 - $mpfr2, " is not < 0.00000000000001";
    print "not ok 4\n";
  }

  RMPC_IM($mpfr1, $mpc1);
  RMPC_IM($mpfr2, $root);

  if(abs($mpfr1 - $mpfr2) < 0.00000000000001) {print "ok 5\n"}
  else {
    warn $mpfr1 - $mpfr2, " is not < 0.00000000000001";
    print "not ok 5\n";
  }

  Rmpc_rootofunity($root, 2, 3, MPC_RNDNN);

  $mpfr1 = $mpfr * 3;

  Rmpc_set_d_fr($mpc2, 0.0, $mpfr1, MPC_RNDNN);
  Rmpc_exp($mpc1, $mpc2, MPC_RNDNN);


  RMPC_RE($mpfr1, $mpc1);
  RMPC_RE($mpfr2, $root);

  if(abs($mpfr1 - $mpfr2) < 0.000000000000001) {print "ok 6\n"}
  else {
    warn $mpfr1 - $mpfr2, " is not < 0.000000000000001";
    print "not ok 6\n";
  }

  RMPC_IM($mpfr1, $mpc1);
  RMPC_IM($mpfr2, $root);

  if(abs($mpfr1 - $mpfr2) < 0.000000000000001) {print "ok 7\n"}
  else {
    warn $mpfr1 - $mpfr2, " is not < 0.000000000000001";
    print "not ok 7\n";
  }

}
