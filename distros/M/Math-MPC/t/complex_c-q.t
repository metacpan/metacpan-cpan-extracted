use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

eval {require Math::Complex_C::Q;};

if($@) {
  print "1..1\n";
  warn "\nSkipping all tests - couldn't load Math::Complex_C::Q\n\$\@: $@\n";
  print "ok 1\n";
  exit 0;
}

unless(Math::MPC::_can_pass_float128()) {
  print "1..1\n";
  warn "\nSkipping all tests - cannot pass float128 values between perl and mpc\n";
  print "ok 1\n";
  exit 0;
}

my $count = 3;

print "1..$count\n";

Rmpc_set_default_prec2(200, 200);

my $ccl = Math::Complex_C::Q->new(4.5, -231.125);
my $mpcc = Math::MPC->new();
my $mpfr = Math::MPFR->new();

Rmpc_set_F128C($mpcc, $ccl, MPC_RNDNN);

RMPC_RE($mpfr, $mpcc);
if($mpfr == 4.5) {print "ok 1\n"}
else {
  warn "\$mpfr: $mpfr\n";
  print "not ok 1\n";
}

RMPC_IM($mpfr, $mpcc);
if($mpfr == -231.125) {print "ok 2\n"}
else {
  warn "\$mpfr: $mpfr\n";
  print "not ok 2\n";
}

Math::Complex_C::Q::assign_cq($ccl, 3.19, -12.621);

my $mpccl = Math::MPC->new();

Rmpc_set_F128C($mpccl, $ccl, MPC_RNDNN);

my $ccl_check = Math::Complex_C::Q->new();

Rmpc_get_F128C($ccl_check, $mpccl, MPC_RNDNN);

if($ccl_check == $ccl) {print "ok 3\n"}
else {
  warn "\$ccl_check: $ccl_check\n\$ccl: $ccl\n";
  print "not ok 3\n";
}

