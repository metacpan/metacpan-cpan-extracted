use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..6\n";

Rmpc_set_default_prec2(200, 200);
Rmpfr_set_default_prec(200);
my $_64 = Math::MPC::_has_longlong();

my $mpc1 = Rmpc_init2(200);
Rmpc_set_ui_ui($mpc1, 10, 10, MPC_RNDNN);
my $mpfr1 = Math::MPFR->new(50.5);
my $ok = '';

Rmpc_add_ui($mpc1, $mpc1, 30, MPC_RNDNN);
Rmpc_add_fr($mpc1, $mpc1, $mpfr1, MPC_RNDNN);
Rmpc_add($mpc1, $mpc1, $mpc1, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 == 181;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 == 20;

if($ok eq 'ab') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

#$mpc1 is 181, 20
Rmpc_sub_ui($mpc1, $mpc1, 31, MPC_RNDNN);

#$mpc1 is 150, 20
Rmpc_ui_sub($mpc1, 50, $mpc1, MPC_RNDNN);

#$mpc1 is -100, -20
Rmpc_ui_ui_sub($mpc1, 30, 40, $mpc1, MPC_RNDNN);

#$mpc1 is 130, 60
RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 == 130;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 == 60;

my $mpc2 = Math::MPC->new($mpc1);

Rmpc_sub($mpc1, $mpc1, $mpc2, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if $mpfr1 == 0;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if $mpfr1 == 0;

if($ok eq 'abcd') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc1, 10, 10, MPC_RNDNN);
my $mpfr = Math::MPFR->new(~0);
$mpfr += 10;

$mpc1 += ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 == 10;

$mpc1 -= ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if $mpfr1 == 10;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if $mpfr1 == 10;

$mpc1 += -100;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if $mpfr1 == -90;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if $mpfr1 == 10;

$mpc1 -= -50;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if $mpfr1 == -40;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if $mpfr1 == 10;

$mpc1 += 20.25;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if $mpfr1 == -19.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if $mpfr1 == 10;

$mpc1 -= -20.5;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'k' if $mpfr1 == 0.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'l' if $mpfr1 == 10;

my $string = '12345678' x 7;

Rmpfr_set_str($mpfr, $string, 0, MPC_RNDNN);
$mpfr += 0.75;

$mpc1 += $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'm' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'n' if $mpfr1 == 10;

$mpc1 -= $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'o' if $mpfr1 == 0.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'p' if $mpfr1 == 10;

Rmpc_set_d_d($mpc2, 1099511627770.5, 1099511627770.5, MPC_RNDNN);

$mpc1 += $mpc2;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'q' if $mpfr1 == 1099511627771.25;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'r' if $mpfr1 == 1099511627780.5;

$mpc1 -= $mpc2;

RMPC_RE($mpfr1, $mpc1);
$ok .= 's' if $mpfr1 == 0.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 't' if $mpfr1 == 10;

if($ok eq 'abcdefghijklmnopqrst') {print "ok 3\n"}
else {print "not ok 3 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc1, 10, 10, MPC_RNDNN);
if($_64){
  if(Math::MPC::_has_inttypes()) {Math::MPFR::Rmpfr_set_uj($mpfr, ~0, GMP_RNDN)}
  else {Math::MPFR::Rmpfr_set_str($mpfr, ~0, 10, GMP_RNDN)}
}
else {Rmpfr_set_ui($mpfr, ~0, GMP_RNDN)}
$mpfr += 10;

$mpc1 = $mpc1 + ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 == 10;

$mpc1 = $mpc1 - ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if $mpfr1 == 10;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if $mpfr1 == 10;

$mpc1 = $mpc1 + -100;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if $mpfr1 == -90;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if $mpfr1 == 10;

$mpc1 = $mpc1 - -50;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if $mpfr1 == -40;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if $mpfr1 == 10;

$mpc1 = $mpc1 + 20.25;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if $mpfr1 == -19.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if $mpfr1 == 10;

$mpc1 = $mpc1 - -20.5;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'k' if $mpfr1 == 0.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'l' if $mpfr1 == 10;

# LINE 189

Rmpfr_set_str($mpfr, $string, 0, MPC_RNDNN);
$mpfr += 0.75;

$mpc1 = $mpc1 + $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'm' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'n' if $mpfr1 == 10;

$mpc1 = $mpc1 - $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'o' if $mpfr1 == 0.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'p' if $mpfr1 == 10;

Rmpc_set_d_d($mpc2, 1099511627770.5, 1099511627770.5, MPC_RNDNN);

$mpc1 = $mpc1 + $mpc2;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'q' if $mpfr1 == 1099511627771.25;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'r' if $mpfr1 == 1099511627780.5;

$mpc1 = $mpc1 - $mpc2;

RMPC_RE($mpfr1, $mpc1);
$ok .= 's' if $mpfr1 == 0.75;
RMPC_IM($mpfr1, $mpc1);
$ok .= 't' if $mpfr1 == 10;

if($ok eq 'abcdefghijklmnopqrst') {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc1, 10, 10, MPC_RNDNN);
if($_64){
  if(Math::MPC::_has_inttypes()) {Math::MPFR::Rmpfr_set_uj($mpfr, ~0, GMP_RNDN)}
  else {Math::MPFR::Rmpfr_set_str($mpfr, ~0, 10, GMP_RNDN)}
}
else {Rmpfr_set_ui($mpfr, ~0, GMP_RNDN)}
$mpfr += 10;

$mpc1 = ~0 + $mpc1;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 == 10;

$mpc1 = ~0 - $mpc1;
$mpfr = ~0 - $mpfr;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if $mpfr1 == -10;

$mpc1 = -100 + $mpc1;
$mpfr -= 100;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if $mpfr1 == -10;

$mpc1 = -50 - $mpc1;
$mpfr = -50 - $mpfr;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if $mpfr1 == 10;

$mpc1 = 20.25 + $mpc1;
$mpfr += 20.25;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if $mpfr1 == 10;

$mpc1 = -20.5 - $mpc1;
$mpfr = -20.5 - $mpfr;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'k' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'l' if $mpfr1 == -10;

$mpc1 = $string + $mpc1;
$mpfr += $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'm' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'n' if $mpfr1 == -10;

$mpc1 = $string - $mpc1;
$mpfr = $string - $mpfr;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'o' if $mpfr1 == $mpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'p' if $mpfr1 == 10;

if($ok eq 'abcdefghijklmnop') {print "ok 5\n"}
else {print "not ok 5 $ok\n"}

$ok = '';

Rmpc_neg($mpc2, $mpc1, MPC_RNDNN);

if($mpc2 == -$mpc1 && $mpc1 == -$mpc2) {print "ok 6\n"}
else {print "not ok 6\n"}






