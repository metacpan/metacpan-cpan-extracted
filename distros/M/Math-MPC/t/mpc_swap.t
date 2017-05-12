use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..2\n";

my $mpc1 = Rmpc_init3(100, 150);
my $mpc1_copy = Rmpc_init3(100, 150);
my $mpc2 = Rmpc_init3(90, 70);
my $mpc2_copy = Rmpc_init3(90, 70);

Rmpc_set_d_d($mpc1, 1.31, 1.173, MPC_RNDNN);
Rmpc_set_d_d($mpc2, 2.59, 2.871, MPC_RNDNN);
Rmpc_set_d_d($mpc1_copy, 1.31, 1.173, MPC_RNDNN);
Rmpc_set_d_d($mpc2_copy, 2.59, 2.871, MPC_RNDNN);

Rmpc_swap($mpc1, $mpc2);

if($mpc1 == $mpc2_copy) {print "ok 1\n"}
else {
  warn "\nmpc1: $mpc1\nmpc2_copy: $mpc2_copy\n";
  print "not ok 1\n";
}

if($mpc2 == $mpc1_copy) {print "ok 2\n"}
else {
  warn "\nmpc2: $mpc2\nmpc1_copy: $mpc1_copy\n";
  print "not ok 2\n";
}
