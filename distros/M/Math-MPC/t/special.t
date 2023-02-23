use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..3\n";

my $ok = '';

Rmpc_set_default_prec2(100, 100);
Rmpfr_set_default_prec(81);

my $mpc1 = Math::MPC->new(1.23456, 654321);
my $mpfr1 = Math::MPFR->new();

Rmpc_arg($mpfr1, $mpc1, GMP_RNDN);

if(!Rmpfr_nan_p($mpfr1)) {$ok .= 'a'}
if(Rmpfr_get_prec($mpfr1) == 81) {$ok .= 'b'}

if($ok eq 'ab') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

$ok = '';

$mpfr1 *= -1;
$mpfr1 /= 0; # -inf
my $minus_zero = $mpfr1;

my $mpfr2 = Math::MPFR->new();

my $mpc2 = Math::MPC->new($mpfr2, $mpfr1);

Rmpc_proj($mpc1, $mpc2, MPC_RNDNN);

my $ret = Rmpc_real($mpfr1, $mpc1, GMP_RNDN);

if($ret == 0) {$ok .= 'a'}
if($mpfr1 > 0) {$ok .= 'b'}
if(Rmpfr_inf_p($mpfr1)) {$ok .= 'c'}
if(Rmpfr_get_prec($mpfr1) == 81) {$ok .= 'd'}

$ret = Rmpc_imag($mpfr1, $mpc1, GMP_RNDN);

if($ret == 0) {$ok .= 'e'}
if($mpfr1 == 0 && $mpfr1 == $minus_zero) {$ok .= 'f'}
if(Rmpfr_get_prec($mpfr1) == 81) {$ok .= 'g'}

if($ok eq 'abcdefg') {print "ok 2\n"}
else {print "not ok 2 $ok \n"}

Rmpc_set_ui($mpc1, 10, MPC_RNDNN);
eval {Rmpc_log10($mpc1, $mpc1, MPC_RNDNN);};

if(65536 > MPC_VERSION) {
  if($@ =~ /mpc_log10 not implemented until mpc\-1\.0/) {print "ok 3\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 3\n";
  }
}
else {
  if($mpc1 == 1) {print "ok 3\n"}
  else {
    warn "\$mpc1: $mpc1\n";
    print "not ok 3\n";
  }
}
