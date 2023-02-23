use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..4\n";

Rmpc_set_default_prec2(359, 359);

my $z = Math::MPC->new(2, 2);
my $zz = Math::MPC->new(1,1);
my $mpc1 = Math::MPC->new();
my $mpfr1 = Math::MPFR->new();
my $tan = Math::MPC->new();
my $zero = Math::MPC->new(0,0);
my $ok = '';

Rmpc_sin($mpc1, $z, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 < 3.420954862 && $mpfr1 > 3.42095486;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 > -1.50930648533 && $mpfr1 < -1.5093064853;

my $mpc2 = sin($zz);

RMPC_RE($mpfr1, $mpc2);
$ok .= 'c' if $mpfr1 < 1.29845758142 && $mpfr1 > 1.2984575814;
RMPC_IM($mpfr1, $mpc2);
$ok .= 'd' if $mpfr1 > 0.634963914784 && $mpfr1 < 0.634963914785;

if($ok eq 'abcd') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

my $sin = sin($z);
my $cos = cos($z);
Rmpc_tan($tan, $z, MPC_RNDNN);

my $diff1 = $tan - ($sin / $cos);

RMPC_RE($mpfr1, $diff1);
$ok .= 'a' if $mpfr1 < 0.000001 && $mpfr1 > -0.000001;
RMPC_IM($mpfr1, $diff1);
$ok .= 'b' if $mpfr1 < 0.000001 && $mpfr1 > -0.000001;

RMPC_RE($mpfr1, ($sin * $sin) + ($cos * $cos));
$ok .= 'c' if $mpfr1 < 1.000001 && $mpfr1 > 0.999999;
RMPC_IM($mpfr1, ($sin * $sin) + ($cos * $cos));
$ok .= 'd' if $mpfr1 < 0.000001 && $mpfr1 > -0.000001;

if($ok eq 'abcd') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

Rmpc_sin($mpc1, $zero, MPC_RNDNN);
$ok .= 'a' if $mpc1 == 0;

Rmpc_cos($mpc1, $zero, MPC_RNDNN);
$ok .= 'b' if $mpc1 == 1;

Rmpc_tan($mpc1, $zero, MPC_RNDNN);
$ok .= 'c' if $mpc1 == 0;

Rmpc_sinh($mpc1, $zero, MPC_RNDNN);
$ok .= 'd' if $mpc1 == 0;

Rmpc_cosh($mpc1, $zero, MPC_RNDNN);
$ok .= 'e' if $mpc1 == 1;

Rmpc_tanh($mpc1, $zero, MPC_RNDNN);
$ok .= 'f' if $mpc1 == 0;

if(MPC_VERSION_MAJOR > 0 || MPC_VERSION_MINOR > 8) {
  Rmpc_sin_cos($mpc1, $mpc2, $zero, MPC_RNDNN, MPC_RNDNN);
  $ok .= 'g' if $mpc1 == 0 && $mpc2 == 1;
}
else {
  eval{Rmpc_sin_cos($mpc1, $mpc2, $zero, MPC_RNDNN, MPC_RNDNN);};
  if($@) {
    if($@ =~ /not supported by your version/){$ok .= 'g'}
    else {warn "3g: \$\@: $@\n"}
  }
  else {warn "\$\@ not set\n"}
}

if($ok eq 'abcdefg') {print "ok 3\n"}
else {
  warn "3: $ok\n";
  print "not ok 3 $ok\n";
}

$ok = '';

Rmpc_sinh($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 < -1.509306485 && $mpfr1 > -1.50930649;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 > 3.42095486 && $mpfr1 < 3.420954862;

Rmpc_cosh($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if $mpfr1 < -1.565625835 && $mpfr1 > -1.5656258354;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if $mpfr1 > 3.297894836 && $mpfr1 < 3.2978948364;

Rmpc_tanh($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'e' if $mpfr1 < 1.0238355946 && $mpfr1 > 1.023835594;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'f' if $mpfr1 > -0.028392953 && $mpfr1 < -0.02839295;

Rmpc_asin($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if $mpfr1 < 0.7542492 && $mpfr1 > 0.754249;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if $mpfr1 > 1.734324521 && $mpfr1 < 1.7343245215;

Rmpc_acos($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if $mpfr1 < 0.8165471821 && $mpfr1 > 0.816547182;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if $mpfr1 > -1.7343245215 && $mpfr1 < -1.734324521;

Rmpc_atan($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'k' if $mpfr1 < 1.3112232697 && $mpfr1 > 1.311223269;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'l' if $mpfr1 > 0.23887786 && $mpfr1 < 0.238877862;

Rmpc_asinh($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'm' if $mpfr1 < 1.734324522 && $mpfr1 > 1.734324521;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'n' if $mpfr1 > 0.754249144698 && $mpfr1 < 0.7542491446981;

Rmpc_acosh($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'o' if $mpfr1 < 1.734324522 && $mpfr1 > 1.734324521;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'p' if $mpfr1 > 0.816547182 && $mpfr1 < 0.8165471821;

Rmpc_atanh($mpc1, $z, MPC_RNDNN);
RMPC_RE($mpfr1, $mpc1);
$ok .= 'q' if $mpfr1 < 0.2388778613 && $mpfr1 > 0.2388778612;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'r' if $mpfr1 > 1.3112232 && $mpfr1 < 1.31122327;

if($ok eq 'abcdefghijklmnopqr') { print "ok 4\n" }
else { print "not ok 4 $ok\n" }

