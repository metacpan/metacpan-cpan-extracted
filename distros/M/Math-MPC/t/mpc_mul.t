use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..8\n";

Rmpc_set_default_prec2(500, 500);
Rmpfr_set_default_prec(500);
my $mpfr1 = Math::MPFR->new();
my $mpc1 = Math::MPC->new(10, 20);
my $mpfrr = Math::MPFR->new(10);
my $mpfri = Math::MPFR->new(20);
my $mpfrtemp = Math::MPFR->new();
my $mpfrti = Math::MPFR->new();
my $mpfrtr = Math::MPFR->new();
my $mpfr_tilde0;
my$ok = '';

my $_64 = Math::MPC::_has_longlong() ? 1 : 0;

if($_64) {
  $mpfr_tilde0 = Math::MPFR->new(~0);
}

if($_64) {Rmpc_mul_fr($mpc1, $mpc1, $mpfr_tilde0, MPC_RNDNN)}
else {Rmpc_mul_ui($mpc1, $mpc1, ~0, MPC_RNDNN)}
Rmpc_mul_si($mpc1, $mpc1, -15, MPC_RNDNN);
Rmpc_mul($mpc1, $mpc1, $mpc1, MPC_RNDNN);

$mpfrr *= ~0;
$mpfri *= ~0;
$mpfrr *= -15;
$mpfri *= -15;
$mpfrtemp = ($mpfrr * $mpfri) * 2;
$mpfrr = ($mpfrr * $mpfrr) - ($mpfri * $mpfri);
Rmpfr_set($mpfri, $mpfrtemp, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if abs($mpfr1 - $mpfri) < 0.0000001;

if($ok eq 'ab') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

if($_64) {Rmpc_div_fr($mpc1, $mpc1, $mpfr_tilde0, MPC_RNDNN)}
else {Rmpc_div_ui($mpc1, $mpc1, ~0, MPC_RNDNN)}
$mpfrr /= ~0;
$mpfri /= ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if abs($mpfr1 - $mpfri) < 0.0000001;

Rmpc_ui_div($mpc1, 50, $mpc1, MPC_RNDNN);
$mpfrtr = ($mpfrr * 50) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri)) ;
$mpfrti = (-50 * $mpfri) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri));
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if abs($mpfr1 - $mpfri) < 0.0000001;

my $mpc2 = Math::MPC->new($mpc1);

Rmpc_div($mpc1, $mpc1, $mpc2, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if $mpfr1 == 1;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if $mpfr1 == 0;

if($ok eq 'abcdef') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc1, 10, 20, MPC_RNDNN);
Rmpfr_set_ui($mpfrr, 10, MPC_RNDNN);
Rmpfr_set_ui($mpfri, 20, MPC_RNDNN);

$mpc1 *= ~0;
$mpfrr *= ~0;
$mpfri *= ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 /= ~0;
$mpfrr /= ~0;
$mpfri /= ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 *= -100;
$mpfrr *= -100;
$mpfri *= -100;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 /= -50;
$mpfrr /= -50;
$mpfri /= -50;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 *= 20.25;
$mpfrr *= 20.25;
$mpfri *= 20.25;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 /= -20.5;
$mpfrr /= -20.5;
$mpfri /= -20.5;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'k' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'l' if abs($mpfr1 - $mpfri) < 0.0000001;

my $string = '12345678' x 7;

$mpc1 *= $string;
$mpfrr *= $string;
$mpfri *= $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'm' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'n' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 /= $string;
$mpfrr /= $string;
$mpfri /= $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'o' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'p' if abs($mpfr1 - $mpfri) < 0.0000001;

Rmpc_set_d_d($mpc2, 1099511627770.5, 1099511627770.5, MPC_RNDNN);

$mpc1 *= $mpc2;
$mpfrtr = ($mpfrr * 1099511627770.5) - ($mpfri * 1099511627770.5);
$mpfrti = ($mpfrr * 1099511627770.5) + ($mpfri * 1099511627770.5);
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'q' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'r' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 /= $mpc2;
my $mpfr_sq = Math::MPFR->new(1099511627770.5);
$mpfr_sq *= $mpfr_sq;
$mpfrtr = (($mpfrr * 1099511627770.5) + ($mpfri * 1099511627770.5)) / ($mpfr_sq * 2) ;
$mpfrti = ((1099511627770.5 * $mpfri) - ($mpfrr * 1099511627770.5))/ ($mpfr_sq * 2);
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 's' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 't' if abs($mpfr1 - $mpfri) < 0.0000001;

if($ok eq 'abcdefghijklmnopqrst') {print "ok 3\n"}
else {print "not ok 3 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc1, 10, 20, MPC_RNDNN);
Rmpfr_set_ui($mpfrr, 10, MPC_RNDNN);
Rmpfr_set_ui($mpfri, 20, MPC_RNDNN);

$mpc1 = $mpc1 * ~0;
$mpfrr *= ~0;
$mpfri *= ~0;


RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $mpc1 / ~0;
$mpfrr /= ~0;
$mpfri /= ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $mpc1 * -100;
$mpfrr *= -100;
$mpfri *= -100;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $mpc1 / -50;
$mpfrr /= -50;
$mpfri /= -50;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $mpc1 * 20.25;
$mpfrr *= 20.25;
$mpfri *= 20.25;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $mpc1 / -20.5;
$mpfrr /= -20.5;
$mpfri /= -20.5;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'k' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'l' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $mpc1 * $string;
$mpfrr *= $string;
$mpfri *= $string;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'm' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'n' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $mpc1 / $string;
$mpfrr /= $string;
$mpfri /= $string;
#####################
#####################
RMPC_RE($mpfr1, $mpc1);
$ok .= 'o' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'p' if abs($mpfr1 - $mpfri) < 0.0000001;

#Rmpc_set_d_d($mpc2, 1099511627770.5, 1099511627770.5, MPC_RNDNN);

$mpc1 = $mpc1 * $mpc2;
$mpfrtr = ($mpfrr * 1099511627770.5) - ($mpfri * 1099511627770.5);
$mpfrti = ($mpfrr * 1099511627770.5) + ($mpfri * 1099511627770.5);
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'q' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'r' if abs($mpfr1 - $mpfri) < 0.0000001;
######################
######################
$mpc1 = $mpc1 / $mpc2;
$mpfrtr = (($mpfrr * 1099511627770.5) + ($mpfri * 1099511627770.5)) / ($mpfr_sq * 2) ;
$mpfrti = ((1099511627770.5 * $mpfri) - ($mpfrr * 1099511627770.5))/ ($mpfr_sq * 2);
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 's' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 't' if abs($mpfr1 - $mpfri) < 0.0000001;

if($ok eq 'abcdefghijklmnopqrst') {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc1, 10, 20, MPC_RNDNN);
Rmpfr_set_ui($mpfrr, 10, MPC_RNDNN);
Rmpfr_set_ui($mpfri, 20, MPC_RNDNN);

$mpc1 = ~0 * $mpc1;
$mpfrr *= ~0;
$mpfri *= ~0;

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = ((~0 - 1) / 2) / $mpc1;
$mpfrtr = ($mpfrr * ((~0 - 1) / 2)) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri)) ;
$mpfrti = (-((~0 - 1) / 2) * $mpfri) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri));
Rmpfr_set($mpfrr, $mpfrtr, GMP_RNDN);
Rmpfr_set($mpfri, $mpfrti, GMP_RNDN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = -100 * $mpc1;
$mpfrr *= -100;
$mpfri *= -100;


RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = -50 / $mpc1;
$mpfrtr = ($mpfrr * -50) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri)) ;
$mpfrti = (50 * $mpfri) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri));
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);


RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = 20.25 * $mpc1;
$mpfrr *= 20.25;
$mpfri *= 20.25;


RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = -20.5 / $mpc1;
$mpfrtr = ($mpfrr * -20.5) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri)) ;
$mpfrti = (20.5 * $mpfri) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri));
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'k' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'l' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $string * $mpc1;
$mpfrr *= $string;
$mpfri *= $string;


RMPC_RE($mpfr1, $mpc1);
$ok .= 'm' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'n' if abs($mpfr1 - $mpfri) < 0.0000001;

$mpc1 = $string / $mpc1;
$mpfrtr = ($mpfrr * $string) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri)) ;
$mpfrti = (($string * -$mpfri)) / (($mpfrr * $mpfrr) + ($mpfri * $mpfri));
Rmpfr_set($mpfrr, $mpfrtr, MPC_RNDNN);
Rmpfr_set($mpfri, $mpfrti, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'o' if abs($mpfr1 - $mpfrr) < 0.0000001;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'p' if abs($mpfr1 - $mpfri) < 0.0000001;

if($ok eq 'abcdefghijklmnop') {print "ok 5\n"}
else {print "not ok 5 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc2, 5, 12, MPC_RNDNN);
Rmpc_sqr($mpc1, $mpc2, MPC_RNDNN);
Rmpc_sqrt($mpc1, $mpc1, MPC_RNDNN);

$ok .= 'a' unless Rmpc_cmp($mpc1, $mpc2);

Rmpc_sqr($mpc1, $mpc2, MPC_RNDNN);
$mpc1 = sqrt($mpc1);

$ok .= 'b' if $mpc1 == $mpc2;

Rmpc_abs($mpfr1, $mpc2, MPC_RNDNN);

$ok .= 'c' if $mpfr1 == 13;

$mpfrtemp = abs($mpc2);

$ok .= 'd' if $mpfrtemp == 13;

Rmpc_norm($mpfr1, $mpc2, MPC_RNDNN);

$ok .= 'e' if $mpfr1 == 169;

Rmpc_conj($mpc1, $mpc2, MPC_RNDNN);
$mpc1 += $mpc2;

RMPC_IM($mpfr1, $mpc1);

$ok .= 'f' if $mpfr1 == 0;

Rmpc_neg($mpc1, $mpc2, MPC_RNDNN);

$ok .= 'g' if $mpc1 == -$mpc2;
$ok .= 'h' if $mpc1 == $mpc2  * -1;

Rmpfr_const_pi($mpfrtemp, MPC_RNDNN);
my $double = Rmpfr_get_d($mpfrtemp, MPC_RNDNN);

Rmpc_set_d_d($mpc2, 0, $double, MPC_RNDNN);
Rmpc_exp($mpc1, $mpc2, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if $mpfr1 > -1 && $mpfr1 < -0.9999999;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if $mpfr1 > 0 && $mpfr1 < 0.0000001;

my $mpc3 = exp($mpc2);

RMPC_RE($mpfr1, $mpc3);
$ok .= 'k' if $mpfr1 > -1 && $mpfr1 < -0.9999999;
RMPC_IM($mpfr1, $mpc3);
$ok .= 'l' if $mpfr1 > 0 && $mpfr1 < 0.0000001;

if($ok eq 'abcdefghijkl') {print "ok 6\n"}
else {print "not ok 6\n"}

$ok = '';

my $log = log(exp(Math::MPC->new(8.5, 0)));

RMPC_RE($mpfr1, $log);
$ok .= 'a' if $mpfr1 > 8.499999 && $mpfr1 < 8.500001;
RMPC_IM($mpfr1, $log);
$ok .= 'b' if $mpfr1 == 0;

Rmpc_log($log, Math::MPC->new(1, 0), MPC_RNDNN);

RMPC_RE($mpfr1, $log);
$ok .= 'c' if $mpfr1 == 0;
RMPC_IM($mpfr1, $log);
$ok .= 'd' if $mpfr1 == 0;

if($ok eq 'abcd') {print "ok 7\n"}
else {print "not ok 7\n"}

$ok = '';
my $pow = Math::MPC->new(3);
my $op1 = Math::MPC->new(0, 3);
my $op2 = Math::MPC->new(3, 0);
my $rop = Math::MPC->new();

Rmpc_pow($rop, $op1, $pow, MPC_RNDNN);
RMPC_RE($mpfr1, $rop);
if($mpfr1 == 0) {$ok .= 'a'}
else {warn "8a: $mpfr1\n"}
RMPC_IM($mpfr1, $rop);
if($mpfr1 == -27) {$ok .= 'b'}
else {warn "8b: $mpfr1\n"}

Rmpc_pow($rop, $op2, $pow, MPC_RNDNN);
RMPC_IM($mpfr1, $rop);
if($mpfr1 == 0) {$ok .= 'c'}
else {warn "8c: $mpfr1\n"}
RMPC_RE($mpfr1, $rop);
if($mpfr1 == 27) {$ok .= 'd'}
else {warn "8d: $mpfr1\n"}

my $root_re = Math::MPFR->new();
my $root_im = Math::MPFR->new();
my $pow_re = Math::MPFR->new();
my $pow_im = Math::MPFR->new();

Rmpc_set_d_ui($pow, 0.5, 0, MPC_RNDNN);
Rmpc_set_ui_ui($op1, 17, 16, MPC_RNDNN);
Rmpc_sqrt($rop, $op1, MPC_RNDNN);
RMPC_RE($root_re, $rop);
RMPC_IM($root_im, $rop);
Rmpc_pow($rop, $op1, $pow, MPC_RNDNN);
RMPC_RE($pow_re, $rop);
RMPC_IM($pow_im, $rop);

if($root_re == $pow_re){$ok .= 'e'}
else {warn "8e: $root_re $pow_re\n"}

if($root_im == $pow_im){$ok .= 'f'}
else {warn "8f: $root_im $pow_im\n"}

if($ok eq 'abcdef') {print "ok 8\n"}
else {print "not ok 8 $ok\n"}








