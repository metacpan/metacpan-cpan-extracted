use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..1\n";

Rmpc_set_default_prec(64);
Rmpfr_set_default_prec(64);
my $ok = '';

my $mpc = Math::MPC->new();
my $re = Math::MPFR->new();
my $im = Math::MPFR->new();

my $ret = Rmpc_strtoc($mpc, '(@nan@ @inf@)', 10, MPC_RNDNN);

RMPC_RE($re, $mpc);
RMPC_IM($im, $mpc);

$ok .= 'a' if $ret == 0;
$ok .= 'b' if Rmpfr_nan_p($re);
$ok .= 'c' if Rmpfr_inf_p($im);

$ret = Rmpc_strtoc($mpc, '(  -@inf@   @nan@)', 16, MPC_RNDNN);

RMPC_RE($re, $mpc);
RMPC_IM($im, $mpc);

$ok .= 'd' if $ret == 0;
$ok .= 'e' if Rmpfr_nan_p($im);
$ok .= 'f' if Rmpfr_inf_p($re);
$ok .= 'g' if $re < 0;

$ret = Rmpc_strtoc($mpc, '(0b1p+5 +0x802)', 0, MPC_RNDNN);

RMPC_RE($re, $mpc);
RMPC_IM($im, $mpc);

$ok .= 'h' if $ret == 0;
$ok .= 'i' if $re == 32;
$ok .= 'j' if $im == 2050;

$ret = Rmpc_set_str($mpc, '(0b1p+5 +0x802)', 0, MPC_RNDNN);

RMPC_RE($re, $mpc);
RMPC_IM($im, $mpc);

$ok .= 'k' if $ret == 0;
$ok .= 'l' if $re == 32;
$ok .= 'm' if $im == 2050;

eval{$ret = Rmpc_set_str($mpc, '(0b1p+5 +0x802z)', 0, MPC_RNDNN);};

$ok .= 'nopq' if $@ =~ /^Invalid string given to Rmpc_set_str/;

if($ok eq 'abcdefghijklmnopq') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

