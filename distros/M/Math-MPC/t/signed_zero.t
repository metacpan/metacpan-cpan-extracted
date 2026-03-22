# Some adhoc tests to check that signed zeroes are being dealt with correctly.
# By no means exhaustive tests - they just deal with a known issue with
# 64-bit builds and overloaded mul and div operations (which  should now be fixed).
# The release of mpc-1.4.0 corrects some earlier mishandling of signed zero so
# we also test for that - and have the tests pass if their results match the value
# that the underlying mpc library expects.

use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

use Test::More;

*p = \&Math::MPC::overload_string;

my $z = Math::MPC->new(0, 0);
my $mul = -1;

my $x = $z * $mul;
cmp_ok(p($x), 'eq', '(-0 -0)', "Test 1a");

my $y = $z / $mul;
cmp_ok(p($y), 'eq', '(-0 -0)', "Test 2a");

$z *= $mul;
cmp_ok(p($z), 'eq', '(-0 -0)', "Test 3a");

$z *= $mul;
cmp_ok(p($z), 'eq', '(0 0)', "Test 4a");

$z /= $mul;
cmp_ok(p($z), 'eq', '(-0 -0)', "Test 5a"); # line 31

Rmpc_set_ui_ui($z, 0, 0, MPC_RNDNN);
$mul = -10.625;

$x = $z * $mul;
cmp_ok(p($x), 'eq', '(-0 -0)', "Test 6a");

$y = $z / $mul;
cmp_ok(p($y), 'eq', '(-0 -0)', "Test 7a");

$z *= $mul;
cmp_ok(p($z), 'eq', '(-0 -0)', "Test 8a");

$z *= $mul;
cmp_ok(p($z), 'eq', '(0 0)', "Test 9a");

$z /= $mul;
cmp_ok(p($z), 'eq', '(-0 -0)', "Test 10a"); # line 49

my $_64i = Math::MPC::_has_longlong();
my $_64d = Math::MPC::_has_longdouble();

my $long = -15;
my $double = -2.5;
Rmpc_set_ui_ui($z, 10, 8, MPC_RNDNN);
my $rop = Math::MPC->new();
my $check = Math::MPFR->new();

Rmpc_mul_d($rop, $z, $double, MPC_RNDNN);
RMPC_RE($check, $rop);
cmp_ok($check, '==', -25, "Test 11a");
RMPC_IM($check, $rop);
cmp_ok($check, '==', -20, "Test 12a");

Rmpc_div_d($rop, $rop, $double, MPC_RNDNN);
RMPC_RE($check, $rop);
cmp_ok($check, '==', 10, "Test 13a");
RMPC_IM($check, $rop);
cmp_ok($check, '==', 8, "Test 14a");

Rmpc_d_div($rop, $double, $z, MPC_RNDNN);
RMPC_RE($check, $rop);
cmp_ok($check, '>', -1.524390244e-1, "Test 15a");
cmp_ok($check, '<', -1.5243902439e-1, "Test 16a");
RMPC_IM($check, $rop);
cmp_ok($check, '<', 0.12195122, "Test 17a");
cmp_ok($check, '>', 0.1219512195, "Test 18a");

if($_64i) {
  Rmpc_mul_sj($rop, $z, $long, MPC_RNDNN);
  RMPC_RE($check, $rop);
  cmp_ok($check, '==', -150, "Test 19a");
  RMPC_IM($check, $rop);
  cmp_ok($check, '==', -120, "Test 20a");

  Rmpc_div_sj($rop, $rop, $long, MPC_RNDNN);
  RMPC_RE($check, $rop);
  cmp_ok($check, '==', 10, "Test 21a");
  RMPC_IM($check, $rop);
  cmp_ok($check, '==', 8, "Test 22a");

  Rmpc_sj_div($rop, $long, $z, MPC_RNDNN);
  # (-9.1463414634146345e-1 7.3170731707317072e-1)
  RMPC_RE($check, $rop);
  cmp_ok($check, '<', -9.14634e-1, "Test 23a");
  cmp_ok($check, '>', -9.1463415e-1, "Test 24a");
  RMPC_IM($check, $rop);
  cmp_ok($check, '<', 7.3170732e-1, "Test 25a");
  cmp_ok($check, '>', 7.3170731e-1, "Test 26a");
}

if($_64d) {
  Rmpc_mul_ld($rop, $z, $double, MPC_RNDNN);
  RMPC_RE($check, $rop);
  cmp_ok($check, '==', -25, "Test 27a");
  RMPC_IM($check, $rop);
  cmp_ok($check, '==', -20, "Test 28a");

  Rmpc_div_ld($rop, $rop, $double, MPC_RNDNN);
  RMPC_RE($check, $rop);
  cmp_ok($check, '==', 10, "Test 29");
  RMPC_IM($check, $rop);
  cmp_ok($check, '==', 8, "Test 30a");

  Rmpc_ld_div($rop, $double, $z, MPC_RNDNN);
  RMPC_RE($check, $rop);
  cmp_ok($check, '>', -1.524390244e-1, "Test 31a");
  cmp_ok($check, '<', -1.5243902439e-1, "Test 32a");
  RMPC_IM($check, $rop);
  cmp_ok($check, '<', 0.12195122, "Test 33a");
  cmp_ok($check, '>', 0.1219512195, "Test 34a");
}

my($p1, $p2) = (Math::MPC->new(1.1, 0.0), Math::MPC->new(1.1, '-0.0'));
my($n1, $n2) = ($p1 * -1.0, $p2 * -1.0);

################################

Rmpc_acos($rop, $p1, MPC_RNDNN);

RMPC_RE($check, $rop);
cmp_ok($check, '==', 0, "Test 35a");

RMPC_IM($check, $rop);
cmp_ok($check, '<', -0.443568254, "Test36a");
cmp_ok($check, '>', -0.4435682544, "Test 37a");

#################################

Rmpc_acos($rop, $p2, MPC_RNDNN);

RMPC_RE($check, $rop);
cmp_ok($check, '==', 0, "Test 38a");

RMPC_IM($check, $rop);
cmp_ok($check, '>', 0.443568254, "Test 39a");
cmp_ok($check, '<', 0.4435682544, "Test 40a");

################################

Rmpc_acos($rop, $n1, MPC_RNDNN);

RMPC_RE($check, $rop);
cmp_ok($check, '>', 3.141592653, "Test 41a");
cmp_ok($check, '<', 3.1415926536, "Test 42a");

RMPC_IM($check, $rop);
cmp_ok($check, '>', 0.443568254, "Test 43a");
cmp_ok($check, '<', 0.4435682544, "Test 44a");

#################################

Rmpc_acos($rop, $n2, MPC_RNDNN);

RMPC_RE($check, $rop);
cmp_ok($check, '>', 3.141592653, "Test 45a");
cmp_ok($check, '<', 3.1415926536, "Test 46a");

RMPC_IM($check, $rop);
cmp_ok($check, '<', -0.443568254, "Test 47a");
cmp_ok($check, '>', -0.4435682544, "Test 48a");

#################################

my $neg_one = Math::MPC->new(-1.0, 0.0);
my $n3 = $p1 * $neg_one;

################################

Rmpc_acos($rop, $n3, MPC_RNDNN);

RMPC_RE($check, $rop);
cmp_ok($check, '>', 3.141592653, "Test 49a");
cmp_ok($check, '<', 3.1415926536, "Test 50a");

RMPC_IM($check, $rop);
cmp_ok($check, '<', -0.443568254, "Test 51a");
cmp_ok($check, '>', -0.4435682544, "Test 52a");

#################################

my @args = (6, 6.0, Math::MPFR->new(6));
#$rop = Math::MPC->new();
my $arg1 = Math::MPC->new(3);
$check = 6 / $arg1;

Rmpc_ui_div($rop, $args[0], $arg1, MPC_RNDNN);
cmp_ok(p($rop), 'eq', p($check), "Rmpc_ui_div, imaginary component of zero");

$rop = $args[0] / $arg1;
cmp_ok(p($rop), 'eq', p($check), "ui_div (overloaded), imaginary component of zero");

Rmpc_div_ui($rop, $arg1, $args[0], MPC_RNDNN);
cmp_ok(p($rop), 'eq', p(1 / $check), "Rmpc_div_ui, imaginary component of zero");

$rop = $arg1 / $args[0], MPC_RNDNN;
cmp_ok(p($rop), 'eq', p(1 / $check), "div_ui (overloaded), imaginary component of zero");

# There is no Rmpc_d_div.
#Rmpc_d_div($rop, $args[1], $arg1, MPC_RNDNN);
#cmp_ok(p($rop), 'eq', p($check), "Rmpc_d_div, imaginary component of zero");

$rop = $args[1] / $arg1;
cmp_ok(p($rop), 'eq', p($check), "NV_div (overloaded), imaginary component of zero");

$rop = $arg1 / $args[1];
cmp_ok(p($rop), 'eq', p(1 / $check), "div_NV (overloaded), imaginary component of zero");

if($Math::MPC::VERSION > 1.34) {
  Rmpc_fr_div($rop, $args[2], $arg1, MPC_RNDNN);
  cmp_ok(p($rop), 'eq', p($check), "Rmpc_fr_div, imaginary component of zero");
}

$rop = $arg1 / $args[2];
cmp_ok(p($rop), 'eq', p(1 / $check), "fr_div(overloaded), imaginary component of zero");

Rmpc_div_fr($rop, $arg1, $args[2], MPC_RNDNN);
cmp_ok(p($rop), 'eq', p(1 / $check), "Rmpc_div_fr, imaginary component of zero");

$rop = $arg1 / $args[2];
cmp_ok(p($rop), 'eq', p(1 / $check), "div_fr (overloaded), imaginary component of zero");

$check = 6 - $arg1;

Rmpc_ui_sub($rop, $args[0], $arg1, MPC_RNDNN);
cmp_ok(p($rop), 'eq', p($check), "Rmpc_ui_sub, imaginary component of zero");

$rop = $args[0] - $arg1;
cmp_ok(p($rop), 'eq', p($check), "ui_sub (overloaded), imaginary component of zero");

Rmpc_sub_ui($rop, $arg1, $args[0], MPC_RNDNN);
cmp_ok(p($rop), 'eq', p($check * -1), "Rmpc_sub_ui, imaginary component of zero");

$rop = $arg1 - $args[0];
cmp_ok(p($rop), 'eq', p($check * -1), "sub_ui (overloaded), imaginary component of zero");

# There is no Rmpc_d_sub or mpc_sub_d

$rop = $args[1] - $arg1;
cmp_ok(p($rop), 'eq', p($check), "NV_sub (overloaded), imaginary component of zero");

$rop = $arg1 - $args[1];
cmp_ok(p($rop), 'eq', p($check * -1), "sub_NV (overloaded), imaginary component of zero");

if($Math::MPC::VERSION > 1.34) {
  Rmpc_fr_sub($rop, $args[2], $arg1, MPC_RNDNN);
  cmp_ok(p($rop), 'eq', p($check), "Rmpc_fr_sub, imaginary component of zero");
}

if($Math::MPC::VERSION > 1.34 && $Math::MPFR::VERSION >= '4.47') {
  $rop = $args[2] - $arg1;
  cmp_ok(p($rop), 'eq', p($check), "fr_sub (overloaded), imaginary component of zero");
}

if($Math::MPC::VERSION > 1.34) {
  Rmpc_sub_fr($rop, $arg1, $args[2], MPC_RNDNN);
  cmp_ok(p($rop), 'eq', p($check * -1), "Rmpc_sub_fr, imaginary component of zero");
}

if($Math::MPC::VERSION > 1.34) {
  $rop = $arg1 - $args[2];
  cmp_ok(p($rop), 'eq', p($check * -1), "sub_fr (overloaded), imaginary component of zero");
}

done_testing();

