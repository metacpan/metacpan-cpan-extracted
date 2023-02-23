use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

eval {require Math::Complex_C;};

if($@) {
  print "1..1\n";
  warn "Skipping all tests - couldn't load Math::Complex_C\n\$\@: $@\n";
  print "ok 1\n";
  exit 0;
}


my $count = 3;

print "1..$count\n";

Rmpc_set_default_prec2(200, 200);

unless(Math::MPC::_have_Complex_h()) {
  warn "Skipping all tests - Math::MPC not built with support for 'double _Complex' & 'long double _Complex' types";
  for(1 .. $count) {print "ok $_\n"}
  exit 0;
}

my $cc = Math::Complex_C->new(4.5, -231.125);
my $mpcc = Math::MPC->new();
my $mpfr = Math::MPFR->new();

Rmpc_set_DC($mpcc, $cc, MPC_RNDNN);

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

Math::Complex_C::assign_c($cc, 3.19, -12.621);

Rmpc_set_DC($mpcc, $cc, MPC_RNDNN);

my $cc_check = Math::Complex_C->new();

Rmpc_get_DC($cc_check, $mpcc, MPC_RNDNN);

if($cc_check == $cc) {print "ok 3\n"}
else {
  warn "\$cc_check: $cc_check\n\$cc: $cc\n";
  print "not ok 3\n";
}



