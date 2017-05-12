use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);
use Config;

Rmpc_set_default_prec2(100, 100);
Rmpfr_set_default_prec(100);

print "1..2\n";

my $_64i = Math::MPC::_has_longlong();
my $_64d = Math::MPC::_has_longdouble();

if($_64i) {print "Using 64-bit integer\n"}
else {print "Using 32-bit integer\n"}

if($_64d) {print "Using long double\n"}
else {print "Not using long double\n"};

my $uimax = ~0;
my $simax = ($uimax - 1) / -2;
my $mpc1 = Rmpc_init3(100, 100);
my $mpfr1 = Rmpfr_init();
my $uimpfr = Math::MPFR->new(~0);
my $simpfr = Math::MPFR->new((~0 - 1) / -2);

my $ok = '';

$ok .= 'a' if Math::MPC::_itsa($uimax == 1);
$ok .= 'b' if Math::MPC::_itsa($simax == 2);
$ok .= 'c' if $simax < 0;
$ok .= 'd' if $uimpfr == $uimax;
$ok .= 'e' if $simpfr == $simax;

if($ok eq 'abcde') {print "ok 1\n"}
else {print "not ok 1 $ok mpc_64.t test script bug\n"}

$ok = '';

if($_64i) {Rmpc_set_uj_uj($mpc1, ~0, ~0, MPC_RNDNN)}
else {Rmpc_set_ui_ui($mpc1, ~0, ~0, MPC_RNDNN)}

RMPC_RE($mpfr1, $mpc1);
$ok .= 'a' if $mpfr1 == ~0;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'b' if $mpfr1 == ~0;

if($_64i) {Rmpc_set_sj_sj($mpc1, $simax, $simax, MPC_RNDNN)}
else {Rmpc_set_si_si($mpc1, $simax, $simax, MPC_RNDNN)}

RMPC_RE($mpfr1, $mpc1);
$ok .= 'c' if $mpfr1 == $simax;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'd' if $mpfr1 == $simax;

if($_64d) {Rmpc_set_ld_ld($mpc1, $uimax + 2, $uimax + 2, MPC_RNDNN)}
else {Rmpc_set_d_d($mpc1, $uimax + 2, $uimax + 2, MPC_RNDNN)}

# $uimax + 2 == $uimax + 1 (overflow) unless the precision of the NV exceeds that of the UV,
# in which case $uimax + 2 == $uimax + 2

if($Config{nvtype} ne '__float128' || MPFR_LDBL_DIG == 33) {
  RMPC_RE($mpfr1, $mpc1);
  if($mpfr1 == $uimax + 2) {$ok .= 'e'}
  else {
    warn "\n2e: \$uimax: $uimax \$mpfr1: $mpfr1\n";
  }

  RMPC_IM($mpfr1, $mpc1);
  if($mpfr1 == $uimax + 2) {$ok .= 'f'}
  else {
    warn "\n2f: \$uimax: $uimax \$mpfr1: $mpfr1\n";
  }
}
else { # MPFR_LDBL_DIG == 18 && nvtype eq '__float128'
  RMPC_RE($mpfr1, $mpc1);
  if($mpfr1 == $uimax + 1) {$ok .= 'e'}
  else {
    warn "\n2e: \$uimax: $uimax \$mpfr1: $mpfr1\n";
  }

  RMPC_IM($mpfr1, $mpc1);
  if($mpfr1 == $uimax + 1) {$ok .= 'f'}
  else {
    warn "\n2f: \$uimax: $uimax \$mpfr1: $mpfr1\n";
  }
}

Rmpc_set_fr_fr($mpc1, $uimpfr, $uimpfr, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'g' if $mpfr1 == ~0;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'h' if $mpfr1 == ~0;

Rmpc_set_fr_fr($mpc1, $simpfr, $simpfr, MPC_RNDNN);

RMPC_RE($mpfr1, $mpc1);
$ok .= 'i' if $mpfr1 == $simpfr;
RMPC_IM($mpfr1, $mpc1);
$ok .= 'j' if $mpfr1 == $simpfr;

if($ok eq 'abcdefghij') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

