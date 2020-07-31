
# testing mpc_rootofunity and mpc_cmp_abs,
# which are new in mpc-1.1.1.

use strict;
use warnings;

use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

my $skip;
$skip = 65793 > MPC_VERSION ? 1 : 0;

my $rop = Math::MPC->new();
my @m1 = (Math::MPC->new(1, 1), Math::MPC->new(2, 2), Math::MPC->new(3, 4));
my @m2 = (Math::MPC->new(1, 2), Math::MPC->new(2, 3), Math::MPC->new(3, 1));

if($skip) {

  print "1..2\n";

  eval {Rmpc_dot($rop, \@m1, \@m2, 3, MPC_RNDNN);};
  if($@ =~ /^The Rmpc_dot function requires mpc\-1\.1\.1 or later/) {print "ok 1\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 1\n";
  }

  eval {Rmpc_sum($rop, \@m1, 3, MPC_RNDNN);};
  if($@ =~ /^The Rmpc_sum function requires mpc\-1\.1\.1 or later/) {print "ok 2\n"}
  else {
    warn "\n\$\@:\n$@\n";
    print "not ok 2\n";
  }

}
else {
  print "1..6\n";

  my($mpfr1, $mpfr2) = (Math::MPFR->new(), Math::MPFR->new());

  my $inex = Rmpc_dot($rop, \@m1, \@m2, scalar(@m2), MPC_RNDNN);

  if($inex == 0) { print "ok 1\n" }
  else {
    warn "\n inex: $inex\n";
    print "not ok 1\n";
  }

  RMPC_RE($mpfr1, $rop);
  RMPC_IM($mpfr2, $rop);

  if($mpfr1 == 2) { print "ok 2\n" }
  else {
    warn "\n real: $mpfr1\n";
    print "not ok 2\n";
  }

  if($mpfr2 == 28) { print "ok 3\n" }
  else {
    warn "\n im: $mpfr2\n";
    print "not ok 3\n";
  }

$inex = Rmpc_sum($rop, \@m1, scalar(@m1), MPC_RNDNN);

  if($inex == 0) { print "ok 4\n" }
  else {
    warn "\n inex: $inex\n";
    print "not ok 4\n";
  }

  RMPC_RE($mpfr1, $rop);
  RMPC_IM($mpfr2, $rop);

  if($mpfr1 == 6) { print "ok 5\n" }
  else {
    warn "\n real: $mpfr1\n";
    print "not ok 5\n";
  }

  if($mpfr2 == 7) { print "ok 6\n" }
  else {
    warn "\n im: $mpfr2\n";
    print "not ok 6\n";
  }

}
