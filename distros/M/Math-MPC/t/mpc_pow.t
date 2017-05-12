use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPC qw(:mpc);

print "1..8\n";

my($have_gmpz, $have_gmp) = (0, 0);
my $ok = '';

eval {require Math::GMPz;};
if(!$@) { $have_gmpz = 1 }

eval {require Math::GMP;};
if(!$@) { $have_gmp = 1 }

my($mp1, $mp2);

$mp1 = Math::GMPz->new(2) if $have_gmpz;
$mp2 = Math::GMP->new(2) if $have_gmp;
my $fr = Math::MPFR->new(2.5);
my $d = 2.5;
my $ld = 2.5;
my $si = -2;
my $ui = 2;
my $mpc = Math::MPC->new(3, 4);
my $rop = Math::MPC->new();
my $mpfr = Math::MPFR->new();

Rmpc_pow_d($rop, $mpc, $d, MPC_RNDNN);
RMPC_RE($mpfr, $rop);
if($mpfr == -38) {$ok .= 'a'}
RMPC_IM($mpfr, $rop);
if($mpfr == 41) {$ok .= 'b'}

eval {Rmpc_pow_ld($rop, $mpc, $ld, MPC_RNDNN);};
if(!$@) {
  RMPC_RE($mpfr, $rop);
  if($mpfr == -38) {$ok .= 'c'}
  RMPC_IM($mpfr, $rop);
  if($mpfr == 41) {$ok .= 'd'}
}
else {
  if(! Math::MPC::_has_longdouble() && $@ =~ /not implemented/) {$ok .= 'cd'}
}

Rmpc_pow_si($rop, $mpc, $si, MPC_RNDNN);
RMPC_RE($mpfr, $rop);
if($mpfr > -0.0112001 && $mpfr < -0.0111999) {$ok .= 'e'}
RMPC_IM($mpfr, $rop);
if($mpfr > -0.0384001 && $mpfr < -0.0383999) {$ok .= 'f'}

Rmpc_pow_ui($rop, $mpc, $ui, MPC_RNDNN);
RMPC_RE($mpfr, $rop);
if($mpfr == -7) {$ok .= 'g'}
RMPC_IM($mpfr, $rop);
if($mpfr == 24) {$ok .= 'h'}

if($have_gmpz) {
  Rmpc_pow_z($rop, $mpc, $mp1, MPC_RNDNN);
  RMPC_RE($mpfr, $rop);
  if($mpfr == -7) {$ok .= 'i'}
  RMPC_IM($mpfr, $rop);
  if($mpfr == 24) {$ok .= 'j'}
}
else {
  warn "No Math::GMPz - skipping tests 1(i) and 1(j)\n";
  $ok .= 'ij';
}

if($have_gmp) {
  Rmpc_pow_z($rop, $mpc, $mp2, MPC_RNDNN);
  RMPC_RE($mpfr, $rop);
  if($mpfr == -7) {$ok .= 'k'}
  RMPC_IM($mpfr, $rop);
  if($mpfr == 24) {$ok .= 'l'}
}
else {
  warn "No Math::GMP - skipping tests 1(k) and 1(l)\n";
  $ok .= 'kl';
}

Rmpc_pow_fr($rop, $mpc, $fr, MPC_RNDNN);
RMPC_RE($mpfr, $rop);
if($mpfr == -38) {$ok .= 'm'}
RMPC_IM($mpfr, $rop);
if($mpfr == 41) {$ok .= 'n'}

Rmpc_pow($rop, $mpc, $mpc, MPC_RNDNN);
RMPC_RE($mpfr, $rop);
if($mpfr < -2.997990598 && $mpfr > -2.997990599) {$ok .= 'o'}
RMPC_IM($mpfr, $rop);
if($mpfr > 0.6237845862 && $mpfr < 0.62378458628) {$ok .= 'p'}

if($ok eq 'abcdefghijklmnop') { print "ok 1\n" }
else { print "not ok 1 $ok\n" }

$ok = '';

$rop = $mpc ** $d;
RMPC_RE($mpfr, $rop);
if($mpfr == -38) {$ok .= 'a'}
RMPC_IM($mpfr, $rop);
if($mpfr == 41) {$ok .= 'b'}

$rop = $mpc ** $si;
RMPC_RE($mpfr, $rop);
if($mpfr > -0.0112001 && $mpfr < -0.0111999) {$ok .= 'c'}
RMPC_IM($mpfr, $rop);
if($mpfr > -0.0384001 && $mpfr < -0.0383999) {$ok .= 'd'}

$rop = $mpc ** $mpc;
RMPC_RE($mpfr, $rop);
if($mpfr < -2.997990598 && $mpfr > -2.997990599) {$ok .= 'e'}
RMPC_IM($mpfr, $rop);
if($mpfr > 0.6237845862 && $mpfr < 0.62378458628) {$ok .= 'f'}

if($ok eq 'abcdef') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

Rmpc_set_ui($mpc, 5, MPC_RNDNN);

Rmpc_mul_2exp($mpc, $mpc, 4, MPC_RNDNN);

if($mpc == 80) {print "ok 3\n"}
else {
  warn "\$mpc: $mpc\n";
  print "not ok 3\n";
}

eval{Rmpc_mul_2si($mpc, $mpc, -4, MPC_RNDNN);};

if(MPC_VERSION >= 65536) {
  if($mpc == 5) {print "ok 4\n"}
  else {
    warn "\$mpc: $mpc\n";
    print "not ok 4\n";
  }
}
else {
  if($@ =~ /mpc_mul_2si not implemented until mpc\-1\.0/) {print "ok 4\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 4\n";
  }
}

#####################################
Rmpc_set_ui($mpc, 5, MPC_RNDNN);

Rmpc_mul_2ui($mpc, $mpc, 4, MPC_RNDNN);

if($mpc == 80) {print "ok 5\n"}
else {
  warn "\$mpc: $mpc\n";
  print "not ok 5\n";
}

Rmpc_div_2ui($mpc, $mpc, 4, MPC_RNDNN);

if($mpc == 5) {print "ok 6\n"}
else {
  warn "\$mpc: $mpc\n";
  print "not ok 6\n";
}
#####################################

Rmpc_set_ui($mpc, 5, MPC_RNDNN);

eval {Rmpc_div_2si($mpc, $mpc, -4, MPC_RNDNN);};

if(MPC_VERSION >= 65536) {
  if($mpc == 80) {print "ok 7\n"}
  else {
    warn "\$mpc: $mpc\n";
    print "not ok 7\n";
  }
}
else {
  if($@ =~ /mpc_div_2si not implemented until mpc\-1\.0/) {print "ok 7\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 7\n";
  }
}

Rmpc_set_ui($mpc, 80, MPC_RNDNN);
Rmpc_div_2exp($mpc, $mpc, 4, MPC_RNDNN);

if($mpc == 5) {print "ok 8\n"}
else {
  warn "\$mpc: $mpc\n";
  print "not ok 8\n";
}

print "$mpc\n";


