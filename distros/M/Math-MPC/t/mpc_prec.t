use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..4\n";

my $mpc1 = Math::MPC->new();
my @prec = Rmpc_get_default_prec2();
my $mpc2 = Rmpc_init3(@prec);

Rmpc_set_default_prec2(100, 121);
Rmpfr_set_default_prec(150);

my $mpc3 = Math::MPC->new();
@prec = Rmpc_get_default_prec2();
my $mpc4 = Rmpc_init3(@prec);
my $mpc5 = Rmpc_init2(200);
my $mpc6 = Rmpc_init3(150, 180);

my $ok = '';

$ok .= 'a' if $prec[0] == 100 && $prec[1] == 121;

$ok .= 'b' if Rmpfr_get_default_prec() == 150;
$ok .= 'c' if Rmpc_get_re_prec($mpc1) == 53;
$ok .= 'd' if Rmpc_get_im_prec($mpc1) == 53;
$ok .= 'e' if Rmpc_get_re_prec($mpc2) == 53;
$ok .= 'f' if Rmpc_get_im_prec($mpc2) == 53;

$ok .= 'g' if Rmpc_get_re_prec($mpc3) == 100;
$ok .= 'h' if Rmpc_get_im_prec($mpc3) == 121;
$ok .= 'i' if Rmpc_get_re_prec($mpc4) == 100;
$ok .= 'j' if Rmpc_get_im_prec($mpc4) == 121;

$ok .= 'k' if Rmpc_get_re_prec($mpc5) == 200;
$ok .= 'l' if Rmpc_get_im_prec($mpc5) == 200;
$ok .= 'm' if Rmpc_get_re_prec($mpc6) == 150;
$ok .= 'n' if Rmpc_get_im_prec($mpc6) == 180;

my($re_prec, $im_prec) = Rmpc_get_prec2($mpc6);

$ok .= 'o' if $re_prec == 150;
$ok .= 'p' if $im_prec == 180;

my $prec = Rmpc_get_prec($mpc6);
$ok .= 'q' if !$prec;

$prec = Rmpc_get_prec($mpc5);
$ok .= 'r' if $prec == 200;

$prec = Rmpc_get_prec($mpc4);
$ok .= 's' if $prec == 0;

@prec = Rmpc_get_prec2($mpc4);
$ok .= 't' if $prec[0] == 100 && $prec[1] == 121;

Rmpc_set_default_prec2(401, 400);
$ok .= 'u' if Rmpc_get_default_prec() == 0;

Rmpc_set_default_prec(401);
$ok .= 'v' if Rmpc_get_default_prec() == 401;

if($ok eq 'abcdefghijklmnopqrstuv') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

Rmpfr_set_default_prec(60);

my $mpfr = Math::MPFR->new();

$ok .= 'a' if Rmpfr_get_prec($mpfr) == 60;

RMPC_RE($mpfr, $mpc6);

$ok .= 'b' if Rmpfr_get_prec($mpfr) == 150;

RMPC_IM($mpfr, $mpc6);

$ok .= 'c' if Rmpfr_get_prec($mpfr) == 180;


if($ok eq 'abc') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

$ok = '';

Rmpc_set_ui_ui($mpc3, ~0, ~0, MPC_RNDNN);

Rmpc_set_re_prec($mpc3, 111);
Rmpc_set_im_prec($mpc3, 222);

$ok .= 'a' if Rmpc_get_re_prec($mpc3) == 111;
$ok .= 'b' if Rmpc_get_im_prec($mpc3) == 222;

RMPC_RE($mpfr, $mpc3);

$ok .= 'c' if Rmpfr_nan_p($mpfr);

RMPC_IM($mpfr, $mpc3);

$ok .= 'd' if Rmpfr_nan_p($mpfr);

if($ok eq 'abcd') {print "ok 3\n"}
else {print "not ok 3 $ok\n"}

$ok = '';

Rmpfr_set_prec($mpfr, 71);
my $mpc7 = Math::MPC->new(1234, 5678);
my $ret = Rmpc_real($mpfr, $mpc7, GMP_RNDN);
if($ret == 0) {$ok .= 'a'}
if($mpfr == 1234) {$ok .= 'b'}
if(Rmpfr_get_prec($mpfr) == 71) {$ok .= 'c'}
Rmpfr_set_prec($mpfr, 72);
$ret = Rmpc_imag($mpfr, $mpc7, GMP_RNDN);
if($ret == 0) {$ok .= 'd'}
if($mpfr == 5678) {$ok .= 'e'}
if(Rmpfr_get_prec($mpfr) == 72) {$ok .= 'f'}

if($ok eq 'abcdef') {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

# Not yet implemented
#if(RMPC_MAX_PREC($mpc6) > 0) {print "ok 4\n"}
#else {print "not ok 4: ", RMPC_MAX_PREC($mpc6), "\n"}

