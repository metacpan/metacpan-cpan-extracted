use strict;
use warnings;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..1\n";

my $ok = '';
my $nan1 = Math::MPC->new(1,1);
my $rop = Math::MPC->new();
my $zero = Math::MPC->new(0,0);
my $pnan = Rmpfr_get_d(Math::MPFR->new(), GMP_RNDN);
my $nan2 = Math::MPC->new($pnan, $pnan);
my $re = Math::MPFR->new(1);
my $im = Math::MPFR->new(2);
Rmpc_set_nan($nan1);

RMPC_RE($re, $nan1);
RMPC_IM($im, $nan1);

if(Rmpfr_nan_p($re)) {$ok .= 'a'}
else {warn "1a: $re\n"}
if(Rmpfr_nan_p($im)) {$ok .= 'b'}
else {warn "1b: $im\n"}

Rmpc_pow($rop, $nan1, $zero, MPC_RNDNN);

RMPC_RE($re, $rop);
RMPC_IM($im, $rop);

if($re == 1) {$ok .= 'c'}
else {warn "1c: $re\n"}
if($im == 0) {$ok .= 'd'}
else {warn "1d: $im\n"}

Rmpc_mul($rop, $nan2, $zero, MPC_RNDNN);

RMPC_RE($re, $rop);
RMPC_IM($im, $rop);

if(Rmpfr_nan_p($re)) {$ok .= 'e'}
else {warn "1e: $re\n"}
if(Rmpfr_nan_p($im)) {$ok .= 'f'}
else {warn "1f: $im\n"}

if($ok eq 'abcdef') {print "ok 1\n"}
else {
  warn "1: $ok\n";
  print "not ok 1\n";
}

