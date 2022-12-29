# Here, we test only the wrapping of mpc_eta and mpc_agm.
# Testing of the ball functions, also new in mpc-1.3.0, is
# conducted in the (new) test scripts Radius.t and Ball.t.

use strict;
use warnings;
use Math::MPC qw(:mpc);

use Test::More;

my $rop = Math::MPC->new();
my $op1  = Math::MPC->new(-0.3, 1.2);
my $op2 = Math::MPC->new(6.2, -2.6);

my $inf_mpfr = Math::MPFR->new(); # NaN
my $nan = Math::MPFR::Rmpfr_get_NV($inf_mpfr, 0);

Math::MPFR::Rmpfr_set_inf($inf_mpfr, 1); # +Inf
my $inf = Math::MPFR::Rmpfr_get_NV($inf_mpfr, 0);

if(MPC_VERSION < 66304) {
  eval{Rmpc_eta_fund($rop, $op1, MPC_RNDAA);};
  like($@, qr/^Rmpc_eta_fund function requires mpc version 1\.3\.0/, "Function croaks in pre mpc-1.3.0");

  eval{Rmpc_agm($rop, $op1, $op2, MPC_RNDAA);};
  like($@, qr/^Rmpc_agm function requires mpc version 1\.3\.0/, "Function croaks in pre mpc-1.3.0");
}
else {
  Rmpc_eta_fund($rop, $op1, MPC_RNDNN);
  cmp_ok("$rop", 'eq', '(7.2829981913846153e-1 -5.6948215660904557e-2)', "Rmpc_eta_fund output is ok");

  my $inex = Rmpc_agm($rop, $op1, $op2, MPC_RNDAA);
  cmp_ok("$rop", 'eq', '(2.7191494731957273 6.4237609338121771e-1)', "Rmpc_agm output is ok");

  Rmpc_set_si_si($op1, 5, 12, MPC_RNDNN);
  Rmpc_set_si_si($op2, 3, 4, MPC_RNDNN);
  my $unity = Math::MPC->new(1, 0);

  my($re0, $re1, $re2) = (Math::MPFR->new(), Math::MPFR->new(), Math::MPFR->new());
  my($im0, $im1, $im2) = (Math::MPFR->new(), Math::MPFR->new(), Math::MPFR->new());

  Rmpc_agm($rop, $op1, $op2, MPC_RNDNN);
  RMPC_RE($re0, $rop);
  RMPC_RE($im0, $rop);

  Rmpc_agm($rop, $unity, $op2 / $op1, MPC_RNDNN);
  $rop *= $op1;
  RMPC_RE($re1, $rop);
  RMPC_RE($im1, $rop);

  Rmpc_agm($rop, $unity, $op1 / $op2, MPC_RNDNN);
  $rop *= $op2;
  RMPC_RE($re2, $rop);
  RMPC_RE($im2, $rop);

  # Check that $re0 == $re1 == $re2
  cmp_ok($re0, '==', $re1, "Rmpcr_agm: first two reals are equivalent");
  cmp_ok($re1, '==', $re2, "Rmpcr_agm: last two reals are equivalent");

  # Check that $im0 == $im1 == $im2
  cmp_ok($im0, '==', $im1, "Rmpcr_agm: first two imaginaries are equivalent");
  cmp_ok($im1, '==', $im2, "Rmpcr_agm: last two imaginaries are equivalent");
}

# The in_fund_dom() function is visible to all Math::MPC builds,
# irrespective of the version of the mpc library being used.

for( [0.49, -10], [-0.49, -10], [-0.49, 1], [-0.5, sqrt(0.8)], [0, 1.0001], [0.49, $inf],
     [0.49, 0 - $inf]  ){
  my $bool = in_fund_dom(Math::MPC->new(@$_));
  cmp_ok($bool, '==', 1, "[@$_] inside fundamental  domain");
}

for( [0.51, 10], [-0.51, 10], [0.49, sqrt(0.75)], [0.51, sqrt(0.75)], [-0.5, sqrt(0.7)],
     [$nan, 20.0], [$nan, $nan], [0.4, $nan], [$nan, $inf],
     [$inf, $nan], [$inf, 0.2] ){
  my $bool = in_fund_dom(Math::MPC->new(@$_));
  cmp_ok($bool, '==', 0, "[@$_] outside fundamental  domain");
}

done_testing();
