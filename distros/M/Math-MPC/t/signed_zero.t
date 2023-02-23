# Some adhoc tests to check that signed zeroes are being dealt with correctly.
# By no means exhaustive tests - they just deal with a known issue with
# 64-bit builds and overloaded mul and div operations (which  should now be fixed).

use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..15\n";

my $ok;
my $z = Math::MPC->new(0, 0);
my $mul = -1;

my $x = $z * $mul;
if(Math::MPC::overload_string($x) eq '(-0 -0)') {$ok .= 'a'}
else {warn "\n1a: got '",Math::MPC::overload_string($x), "'\nexpected '(-0 -0)'\n"}

my $y = $z / $mul;
if(Math::MPC::overload_string($y) eq '(-0 -0)') {$ok .= 'b'}
else {warn "\n1b: got '",Math::MPC::overload_string($y), "'\nexpected '(-0 -0)'\n"}

$z *= $mul;
if(Math::MPC::overload_string($z) eq '(-0 -0)') {$ok .= 'c'}
else {warn "\n1c: got '",Math::MPC::overload_string($z), "'\nexpected '(-0 -0)'\n"}

$z *= $mul;
if(Math::MPC::overload_string($z) eq '(0 0)') {$ok .= 'd'}
else {warn "\n1d: got '",Math::MPC::overload_string($z), "'\nexpected '(0 0)'\n"}

$z /= $mul;
if(Math::MPC::overload_string($z) eq '(-0 -0)') {$ok .= 'e'}
else {warn "\n1e: got '",Math::MPC::overload_string($z), "'\nexpected '(-0 -0)'\n"}

if($ok eq 'abcde') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

$ok = '';
Rmpc_set_ui_ui($z, 0, 0, MPC_RNDNN);
$mul = -10.625;

$x = $z * $mul;
if(Math::MPC::overload_string($x) eq '(-0 -0)') {$ok .= 'a'}
else {warn "\n2a: got '",Math::MPC::overload_string($x), "'\nexpected '(-0 -0)'\n"}

$y = $z / $mul;
if(Math::MPC::overload_string($y) eq '(-0 -0)') {$ok .= 'b'}
else {warn "\n2b: got '",Math::MPC::overload_string($y), "'\nexpected '(-0 -0)'\n"}

$z *= $mul;
if(Math::MPC::overload_string($z) eq '(-0 -0)') {$ok .= 'c'}
else {warn "\n2c: got '",Math::MPC::overload_string($z), "'\nexpected '(-0 -0)'\n"}

$z *= $mul;
if(Math::MPC::overload_string($z) eq '(0 0)') {$ok .= 'd'}
else {warn "\n2d: got '",Math::MPC::overload_string($z), "'\nexpected '(0 0)'\n"}

$z /= $mul;
if(Math::MPC::overload_string($z) eq '(-0 -0)') {$ok .= 'e'}
else {warn "\n2e: got '",Math::MPC::overload_string($z), "'\nexpected '(-0 -0)'\n"}

if($ok eq 'abcde') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

$ok = '';
my $_64i = Math::MPC::_has_longlong();
my $_64d = Math::MPC::_has_longdouble();

my $long = -15;
my $double = -2.5;
Rmpc_set_ui_ui($z, 10, 8, MPC_RNDNN);
my $rop = Math::MPC->new();
my $check = Math::MPFR->new();

Rmpc_mul_d($rop, $z, $double, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'a' if $check == -25;
RMPC_IM($check, $rop);
$ok .= 'b' if $check == -20;

Rmpc_div_d($rop, $rop, $double, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'c' if $check == 10;
RMPC_IM($check, $rop);
$ok .= 'd' if $check == 8;

Rmpc_d_div($rop, $double, $z, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'e' if ($check > -1.524390244e-1  && $check < -1.5243902439e-1) ;
RMPC_IM($check, $rop);
$ok .= 'f' if ($check < 0.12195122 && $check > 0.1219512195);

if($ok eq 'abcdef') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3 \n";
}

$ok = '';

if($_64i) {
Rmpc_mul_sj($rop, $z, $long, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'a' if $check == -150;
RMPC_IM($check, $rop);
$ok .= 'b' if $check == -120;

Rmpc_div_sj($rop, $rop, $long, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'c' if $check == 10;
RMPC_IM($check, $rop);
$ok .= 'd' if $check == 8;

Rmpc_sj_div($rop, $long, $z, MPC_RNDNN);
# (-9.1463414634146345e-1 7.3170731707317072e-1)
RMPC_RE($check, $rop);
$ok .= 'e' if ($check < -9.14634e-1 && $check > -9.1463415e-1) ;
RMPC_IM($check, $rop);
$ok .= 'f' if ($check < 7.3170732e-1 && $check > 7.3170731e-1);

if($ok eq 'abcdef') {print "ok 4\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 4 \n";
}
}
else {
  warn "Skipping test 4 - not built with intmax_t\n";
  print "ok 4\n";
}

$ok = '';

if($_64d) {
Rmpc_mul_ld($rop, $z, $double, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'a' if $check == -25;
RMPC_IM($check, $rop);
$ok .= 'b' if $check == -20;

Rmpc_div_ld($rop, $rop, $double, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'c' if $check == 10;
RMPC_IM($check, $rop);
$ok .= 'd' if $check == 8;

Rmpc_ld_div($rop, $double, $z, MPC_RNDNN);
RMPC_RE($check, $rop);
$ok .= 'e' if ($check > -1.524390244e-1  && $check < -1.5243902439e-1) ;
RMPC_IM($check, $rop);
$ok .= 'f' if ($check < 0.12195122 && $check > 0.1219512195);

if($ok eq 'abcdef') {print "ok 5\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 5 \n";
}
}
else {
  warn "Skipping test 5 - no long double support\n";
  print "ok 5\n";
}

my($p1, $p2) = (Math::MPC->new(1.1, 0.0), Math::MPC->new(1.1, '-0.0'));
my($n1, $n2) = ($p1 * -1.0, $p2 * -1.0);

################################

Rmpc_acos($rop, $p1, MPC_RNDNN);

RMPC_RE($check, $rop);

if($check == 0) {print "ok 6\n"}
else {
  warn "\ntest 6: expected 0, got $check\n";
  print "not ok 6\n";
}

RMPC_IM($check, $rop);

if($check < -0.443568254 && $check > -0.4435682544) {print "ok 7\n"}
else {
  warn "\ntest 7: expected approx -0.443568254385, got $check\n";
  print "not ok 7\n";
}

#################################

Rmpc_acos($rop, $p2, MPC_RNDNN);

RMPC_RE($check, $rop);

if($check == 0) {print "ok 8\n"}
else {
  warn "\ntest 8: expected 0, got $check\n";
  print "not ok 8\n";
}

RMPC_IM($check, $rop);

if($check > 0.443568254 && $check < 0.4435682544) {print "ok 9\n"}
else {
  warn "\ntest 9: expected approx 0.443568254385, got $check\n";
  print "not ok 9\n";
}

################################

Rmpc_acos($rop, $n1, MPC_RNDNN);

RMPC_RE($check, $rop);

if($check > 3.141592653 && $check < 3.1415926536) {print "ok 10\n"}
else {
  warn "\ntest 10: expected approx 3.1415926535897931, got $check\n";
  print "not ok 10\n";
}

RMPC_IM($check, $rop);

if($check > 0.443568254 && $check < 0.4435682544) {print "ok 11\n"}
else {
  warn "\ntest 11: expected approx 0.443568254385, got $check\n";
  print "not ok 11\n";
}

#################################

Rmpc_acos($rop, $n2, MPC_RNDNN);

RMPC_RE($check, $rop);

if($check > 3.141592653 && $check < 3.1415926536) {print "ok 12\n"}
else {
  warn "\ntest 12: expected approx 3.1415926535897931, got $check\n";
  print "not ok 12\n";
}

RMPC_IM($check, $rop);

if($check < -0.443568254 && $check > -0.4435682544) {print "ok 13\n"}
else {
  warn "\ntest 13: expected approx -0.443568254385, got $check\n";
  print "not ok 13\n";
}

#################################

my $neg_one = Math::MPC->new(-1.0, 0.0);

my $n3 = $p1 * $neg_one;

################################

Rmpc_acos($rop, $n3, MPC_RNDNN);

RMPC_RE($check, $rop);

if($check > 3.141592653 && $check < 3.1415926536) {print "ok 14\n"}
else {
  warn "\ntest 14: expected approx 3.1415926535897931, got $check\n";
  print "not ok 14\n";
}

RMPC_IM($check, $rop);

if($check < -0.443568254 && $check > -0.4435682544) {print "ok 15\n"}
else {
  warn "\ntest 15: expected approx -0.443568254385, got $check\n";
  print "not ok 15\n";
}

#################################

