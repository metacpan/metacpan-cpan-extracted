use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);

print "1..8\n";

print "# Using mpfr version ", MPFR_VERSION_STRING, "\n";
print "# Using mpc library version ", MPC_VERSION_STRING, "\n";

my ($ok, $ret);
my $round = MPC_RNDNN;
Rmpc_set_default_prec2(128, 128);
Rmpfr_set_default_prec(128);
my $mpc = Math::MPC->new();
my $mpfr = Math::MPFR->new(12.625);
my $mpfr2 = $mpfr - 11;
my $mpfr_re = Math::MPFR->new();
my $mpfr_im = Math::MPFR->new();
my $d = 6.5;
my $d2 = $d - 11;
my $si = -117;
my $si2 = $si - 11;
my $ui = 4294912975;
my $ui2 = $ui - 11;
my $uj = 9223372036854721487;
my $uj2 = $uj - 11;
my $sj = -36028797018909647;
my $sj2 = $sj - 11;
my $ld = -(2 ** 57) + 0.5;
my $ld2 = $ld - 11;

$ret = Rmpc_set_d_ui($mpc, $d, $ui, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $d && $mpfr_im == $ui) {$ok .= 'a'}
else {warn "a: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_d_si($mpc, $d, $si, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $d && $mpfr_im == $si) {$ok .= 'b'}
else {warn "b: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_d_fr($mpc, $d, $mpfr, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $d && $mpfr_im == $mpfr) {$ok .= 'c'}
else {warn "c: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_ui_d($mpc, $ui, $d, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $ui && $mpfr_im == $d) {$ok .= 'd'}
else {warn "d: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_ui_si($mpc, $ui, $si, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $ui && $mpfr_im == $si) {$ok .= 'e'}
else {warn "e: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_ui_fr($mpc, $ui, $mpfr, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $ui && $mpfr_im == $mpfr) {$ok .= 'f'}
else {warn "f: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_si_d($mpc, $si, $d, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $si && $mpfr_im == $d) {$ok .= 'g'}
else {warn "g: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_si_ui($mpc, $si, $ui, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $si && $mpfr_im == $ui) {$ok .= 'h'}
else {warn "h: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_si_fr($mpc, $si, $mpfr, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $si && $mpfr_im == $mpfr) {$ok .= 'i'}
else {warn "i: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_fr_d($mpc, $mpfr, $d, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == $d) {$ok .= 'j'}
else {warn "j: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_fr_ui($mpc, $mpfr, $ui, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == $ui) {$ok .= 'k'}
else {warn "k: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_fr_si($mpc, $mpfr, $si, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == $si) {$ok .= 'l'}
else {warn "l: $ret $mpfr_re $mpfr_im\n$mpc\n"}

### 64-bit int
if(Math::MPC::_has_longlong()) {
  $ret = Rmpc_set_d_uj($mpc, $d, $uj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $d && $mpfr_im == $uj) {$ok .= 'm'}
  else {warn "m: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_d_sj($mpc, $d, $sj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $d && $mpfr_im == $sj) {$ok .= 'n'}
  else {warn "n: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_uj_d($mpc, $uj, $d, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == $d) {$ok .= 'o'}
  else {warn "o: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj_d($mpc, $sj, $d, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == $d) {$ok .= 'p'}
  else {warn "p: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_uj_fr($mpc, $uj, $mpfr, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == $mpfr) {$ok .= 'q'}
  else {warn "q: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj_fr($mpc, $sj, $mpfr, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == $mpfr) {$ok .= 'r'}
  else {warn "r: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_fr_uj($mpc, $mpfr, $uj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == $uj) {$ok .= 's'}
  else {warn "s: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_fr_sj($mpc, $mpfr, $sj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == $sj) {$ok .= 't'}
  else {warn "t: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_uj_sj($mpc, $uj, $sj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == $sj) {$ok .= 'u'}
  else {warn "u: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj_uj($mpc, $sj, $uj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == $uj) {$ok .= 'v'}
  else {warn "v: $ret $mpfr_re $mpfr_im\n$mpc\n"}
}
else {
  eval {Rmpc_set_d_uj($mpc, $d, $uj, $round);};
  if($@ =~ /Rmpc_set_d_uj not implemented/) {$ok .= 'm'}
  else {warn "m: \$\@: $@\n"}
  eval {Rmpc_set_d_sj($mpc, $d, $sj, $round);};
  if($@ =~ /Rmpc_set_d_sj not implemented/) {$ok .= 'n'}
  else {warn "n: \$\@: $@\n"}
  eval {Rmpc_set_uj_d($mpc, $uj, $d, $round);};
  if($@ =~ /Rmpc_set_uj_d not implemented/) {$ok .= 'o'}
  else {warn "o: \$\@: $@\n"}
  eval {Rmpc_set_sj_d($mpc, $sj, $d, $round);};
  if($@ =~ /Rmpc_set_sj_d not implemented/) {$ok .= 'p'}
  else {warn "p: \$\@: $@\n"}
  eval {Rmpc_set_uj_fr($mpc, $uj, $mpfr, $round);};
  if($@ =~ /Rmpc_set_uj_fr not implemented/) {$ok .= 'q'}
  else {warn "q: \$\@: $@\n"}
  eval {Rmpc_set_sj_fr($mpc, $sj, $mpfr, $round);};
  if($@ =~ /Rmpc_set_sj_fr not implemented/) {$ok .= 'r'}
  else {warn "r: \$\@: $@\n"}
  eval {Rmpc_set_fr_uj($mpc, $mpfr, $uj, $round);};
  if($@ =~ /Rmpc_set_fr_uj not implemented/) {$ok .= 's'}
  else {warn "s: \$\@: $@\n"}
  eval {Rmpc_set_fr_sj($mpc, $mpfr, $sj, $round);};
  if($@ =~ /Rmpc_set_fr_sj not implemented/) {$ok .= 't'}
  else {warn "t: \$\@: $@\n"}
  eval {Rmpc_set_uj_sj($mpc, $uj, $sj, $round);};
  if($@ =~ /Rmpc_set_uj_sj not implemented/) {$ok .= 'u'}
  else {warn "u: \$\@: $@\n"}
  eval {Rmpc_set_sj_uj($mpc, $sj, $uj, $round);};
  if($@ =~ /Rmpc_set_sj_uj not implemented/) {$ok .= 'v'}
  else {warn "v: \$\@: $@\n"}
}

if(Math::MPC::_has_longdouble()) {
  $ret = Rmpc_set_ui_ld($mpc, $ui, $ld, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ui && $mpfr_im == $ld) {$ok .= 'w'}
  else {warn "w: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_si_ld($mpc, $si, $ld, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $si && $mpfr_im == $ld) {$ok .= 'x'}
  else {warn "x: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_fr_ld($mpc, $mpfr, $ld, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == $ld) {$ok .= 'y'}
  else {warn "y: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ld_ui($mpc, $ld, $ui, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == $ui) {$ok .= 'z'}
  else {warn "z: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ld_si($mpc, $ld, $si, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == $si) {$ok .= 'A'}
  else {warn "A: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ld_fr($mpc, $ld, $mpfr, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == $mpfr) {$ok .= 'B'}
  else {warn "B: $ret $mpfr_re $mpfr_im\n$mpc\n"}
}else {
  eval {Rmpc_set_ui_ld($mpc, $ui, $ld, $round);};
  if($@ =~ /Rmpc_set_ui_ld not implemented/) {$ok .= 'w'}
  else {warn "w: \$\@: $@\n"}
  eval {Rmpc_set_si_ld($mpc, $si, $ld, $round);};
  if($@ =~ /Rmpc_set_si_ld not implemented/) {$ok .= 'x'}
  else {warn "x: \$\@: $@\n"}
  eval {Rmpc_set_fr_ld($mpc, $mpfr, $ld, $round);};
  if($@ =~ /Rmpc_set_fr_ld not implemented/) {$ok .= 'y'}
  else {warn "y: \$\@: $@\n"}
  eval {Rmpc_set_ld_ui($mpc, $ld, $ui, $round);};
  if($@ =~ /Rmpc_set_ld_ui not implemented/) {$ok .= 'z'}
  else {warn "z: \$\@: $@\n"}
  eval {Rmpc_set_ld_si($mpc, $ld, $si, $round);};
  if($@ =~ /Rmpc_set_ld_si not implemented/) {$ok .= 'A'}
  else {warn "A: \$\@: $@\n"}
  eval {Rmpc_set_ld_fr($mpc, $ld, $mpfr, $round);};
  if($@ =~ /Rmpc_set_ld_fr not implemented/) {$ok .= 'B'}
  else {warn "B: \$\@: $@\n"}
}

if(Math::MPC::_has_longlong() && Math::MPC::_has_longdouble()) {
  $ret = Rmpc_set_ld_uj($mpc, $ld, $uj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == $uj) {$ok .= 'C'}
  else {warn "C: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ld_sj($mpc, $ld, $sj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == $sj) {$ok .= 'D'}
  else {warn "D: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_uj_ld($mpc, $uj, $ld, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == $ld) {$ok .= 'E'}
  else {warn "E: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj_ld($mpc, $sj, $ld, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == $ld) {$ok .= 'F'}
  else {warn "F: $ret $mpfr_re $mpfr_im\n$mpc\n"}
}
else {
  eval {Rmpc_set_uj_ld($mpc, $ui, $ld, $round);};
  if($@ =~ /Rmpc_set_uj_ld not implemented/) {$ok .= 'C'}
  else {warn "C: \$\@: $@\n"}
  eval {Rmpc_set_sj_ld($mpc, $sj, $ld, $round);};
  if($@ =~ /Rmpc_set_sj_ld not implemented/) {$ok .= 'D'}
  else {warn "D: \$\@: $@\n"}
  eval {Rmpc_set_ld_sj($mpc, $ld, $sj, $round);};
  if($@ =~ /Rmpc_set_ld_sj not implemented/) {$ok .= 'E'}
  else {warn "E: \$\@: $@\n"}
  eval {Rmpc_set_ld_uj($mpc, $ld, $uj, $round);};
  if($@ =~ /Rmpc_set_ld_uj not implemented/) {$ok .= 'F'}
  else {warn "F: \$\@: $@\n"}
}

### X_X (d_d, ui_ui, si_si, fr_fr)

$ret = Rmpc_set_ui_ui($mpc, $ui, $ui2, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $ui && $mpfr_im == $ui - 11) {$ok .= 'G'}
else {warn "G: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_d_d($mpc, $d, $d2, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $d && $mpfr_im == $d - 11) {$ok .= 'H'}
else {warn "H: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_si_si($mpc, $si, $si2, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $si && $mpfr_im == $si - 11) {$ok .= 'I'}
else {warn "I: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_fr_fr($mpc, $mpfr, $mpfr2, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == $mpfr - 11) {$ok .= 'J'}
else {warn "J: $ret $mpfr_re $mpfr_im\n$mpc\n"}

if(Math::MPC::_has_longlong()) {
  $ret = Rmpc_set_uj_uj($mpc, $uj, $uj2, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == $uj - 11) {$ok .= 'K'}
  else {warn "K: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj_sj($mpc, $sj, $sj2, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == $sj - 11) {$ok .= 'L'}
  else {warn "L: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_uj_si($mpc, $uj, $si, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == $si) {$ok .= 'M'}
  else {warn "M: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ui_sj($mpc, $ui, $sj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ui && $mpfr_im == $sj) {$ok .= 'N'}
  else {warn "N: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj_ui($mpc, $sj, $ui, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == $ui) {$ok .= 'O'}
  else {warn "O: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_si_uj($mpc, $si, $uj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $si && $mpfr_im == $uj) {$ok .= 'P'}
  else {warn "P: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_uj_ui($mpc, $uj, $ui, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == $ui) {$ok .= 'Q'}
  else {warn "Q: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ui_uj($mpc, $ui, $uj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ui && $mpfr_im == $uj) {$ok .= 'R'}
  else {warn "R: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj_si($mpc, $sj, $si, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == $si) {$ok .= 'S'}
  else {warn "S: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_si_sj($mpc, $si, $sj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $si && $mpfr_im == $sj) {$ok .= 'T'}
  else {warn "T: $ret $mpfr_re $mpfr_im\n$mpc\n"}
}
else {
  eval {Rmpc_set_uj_uj($mpc, $uj, $uj2, $round);};
  if($@ =~ /Rmpc_set_uj_uj not implemented/) {$ok .= 'K'}
  else {warn "K: \$\@: $@\n"}

  eval {Rmpc_set_sj_sj($mpc, $sj, $sj, $round);};
  if($@ =~ /Rmpc_set_sj_sj not implemented/) {$ok .= 'L'}
  else {warn "L: \$\@: $@\n"}

  eval {Rmpc_set_uj_si($mpc, $uj, $si, $round);};
  if($@ =~ /Rmpc_set_uj_sj not implemented/) {$ok .= 'M'}
  else {warn "M: \$\@: $@\n"}

  eval {Rmpc_set_ui_sj($mpc, $ui, $sj, $round);};
  if($@ =~ /Rmpc_set_uj_sj not implemented/) {$ok .= 'N'}
  else {warn "N: \$\@: $@\n"}

  eval {Rmpc_set_sj_ui($mpc, $sj, $ui, $round);};
  if($@ =~ /Rmpc_set_sj_uj not implemented/) {$ok .= 'O'}
  else {warn "O: \$\@: $@\n"}

  eval {Rmpc_set_si_uj($mpc, $si, $uj, $round);};
  if($@ =~ /Rmpc_set_sj_uj not implemented/) {$ok .= 'P'}
  else {warn "P: \$\@: $@\n"}

  eval {Rmpc_set_uj_ui($mpc, $uj, $ui, $round);};
  if($@ =~ /Rmpc_set_uj_uj not implemented/) {$ok .= 'Q'}
  else {warn "Q: \$\@: $@\n"}

  eval {Rmpc_set_ui_uj($mpc, $ui, $uj, $round);};
  if($@ =~ /Rmpc_set_uj_uj not implemented/) {$ok .= 'R'}
  else {warn "R: \$\@: $@\n"}

  eval {Rmpc_set_sj_si($mpc, $sj, $si, $round);};
  if($@ =~ /Rmpc_set_sj_sj not implemented/) {$ok .= 'S'}
  else {warn "S: \$\@: $@\n"}

  eval {Rmpc_set_si_sj($mpc, $si, $sj, $round);};
  if($@ =~ /Rmpc_set_sj_sj not implemented/) {$ok .= 'T'}
  else {warn "T: \$\@: $@\n"}
}

if(Math::MPC::_has_longdouble()) {
  $ret = Rmpc_set_ld_ld($mpc, $ld, $ld2, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == $ld - 11) {$ok .= 'U'}
  else {warn "U: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_d_ld($mpc, $d, $ld, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $d && $mpfr_im == $ld) {$ok .= 'V'}
  else {warn "V: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ld_d($mpc, $ld, $d, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == $d) {$ok .= 'W'}
  else {warn "W: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ld($mpc, $ld, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ld && $mpfr_im == 0) {$ok .= 'X'}
  else {warn "X: $ret $mpfr_re $mpfr_im\n$mpc\n"}
}
else{
  eval {Rmpc_set_ld_ld($mpc, $ld, $ld2, $round);};
  if($@ =~ /Rmpc_set_ld_ld not implemented/) {$ok .= 'U'}
  else {warn "U: \$\@: $@\n"}

  eval {Rmpc_set_d_ld($mpc, $d, $ld, $round);};
  if($@ =~ /Rmpc_set_ld_ld not implemented/) {$ok .= 'V'}
  else {warn "V: \$\@: $@\n"}

  eval {Rmpc_set_ld_d($mpc, $ld, $d, $round);};
  if($@ =~ /Rmpc_set_ld_ld not implemented/) {$ok .= 'W'}
  else {warn "W: \$\@: $@\n"}

  eval {Rmpc_set_ld($mpc, $ld, $round);};
  if($@ =~ /Rmpc_set_ld not implemented/) {$ok .= 'X'}
  else {warn "X: \$\@: $@\n"}
}

if($ok eq 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX') {print "ok 1\n"}
else {print "not ok 1\n$ok\n"}

$ok = '';

$ret = Rmpc_set_ui($mpc, $ui, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $ui && $mpfr_im == 0) {$ok .= 'a'}
else {warn "2a: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_si($mpc, $si, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $si && $mpfr_im == 0) {$ok .= 'b'}
else {warn "2b: $ret $mpfr_re $mpfr_im\n$mpc\n"}

$ret = Rmpc_set_d($mpc, $d, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $d && $mpfr_im == 0) {$ok .= 'c'}
else {warn "2c: $ret $mpfr_re $mpfr_im\n$mpc\n"}

if(Math::MPC::_has_longlong()) {
  $ret = Rmpc_set_uj($mpc, $uj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $uj && $mpfr_im == 0) {$ok .= 'd'}
  else {warn "2d: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_sj($mpc, $sj, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $sj && $mpfr_im == 0) {$ok .= 'e'}
  else {warn "2e: $ret $mpfr_re $mpfr_im\n$mpc\n"}
}
else {
  eval {Rmpc_set_uj($mpc, $uj, $round);};
  if($@ =~ /Rmpc_set_uj not implemented/) {$ok .= 'd'}
  else {warn "2d: \$\@: $@\n"}

  eval {Rmpc_set_sj($mpc, $sj, $round);};
  if($@ =~ /Rmpc_set_sj not implemented/) {$ok .= 'e'}
  else {warn "2e: \$\@: $@\n"}
}

# Rmpc_set_ld is already checked above

$ret = Rmpc_set_fr($mpc, $mpfr, $round);
Rmpc_real($mpfr_re, $mpc, $round);
Rmpc_imag($mpfr_im, $mpc, $round);
if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == 0) {$ok .= 'f'}
else {warn "2d: $ret $mpfr_re $mpfr_im\n$mpc\n"}

if($ok eq 'abcdef') {print "ok 2\n"}
else {print "not ok 2\n$ok\n"}

my ($have_GMP, $have_GMPz, $have_GMPq, $have_GMPf) = (0, 0, 0, 0);

eval{require Math::GMP;};
$have_GMP = 1 if !$@;

eval{require Math::GMPz;};
$have_GMPz = 1 if !$@;

eval{require Math::GMPq;};
$have_GMPq = 1 if !$@;

eval{require Math::GMPf;};
$have_GMPf = 1 if !$@;

if($have_GMP) {
  $ok = '';
  my $gmp = Math::GMP->new(1234567);
  $ret = Rmpc_set_z($mpc, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == 0) {$ok .= 'a'}
  else {warn "3a: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  my $gmp2 = Math::GMP->new(890);
  $ret = Rmpc_set_z_z($mpc, $gmp, $gmp2, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == 890) {$ok .= 'b'}
  else {warn "3b: $ret $mpfr_re $mpfr_im\n$mpc\n"}


  $ret = Rmpc_set_z_ui($mpc, $gmp, $ui, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == $ui) {$ok .= 'c'}
  else {warn "3c: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ui_z($mpc, $ui, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ui && $mpfr_im == 1234567) {$ok .= 'd'}
  else {warn "3d: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_z_si($mpc, $gmp, $si, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == $si) {$ok .= 'e'}
  else {warn "4e: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_si_z($mpc, $si, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $si && $mpfr_im == 1234567) {$ok .= 'f'}
  else {warn "3f: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_z_d($mpc, $gmp, $d, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == $d) {$ok .= 'g'}
  else {warn "3g: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_d_z($mpc, $d, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $d && $mpfr_im == 1234567) {$ok .= 'h'}
  else {warn "3h: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  if(Math::MPC::_has_longlong()) {
    $ret = Rmpc_set_z_uj($mpc, $gmp, $uj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == $uj) {$ok .= 'i'}
    else {warn "3i: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_uj_z($mpc, $uj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $uj && $mpfr_im == 1234567) {$ok .= 'j'}
    else {warn "3j: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_z_sj($mpc, $gmp, $sj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == $sj) {$ok .= 'k'}
    else {warn "3k: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_sj_z($mpc, $sj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $sj && $mpfr_im == 1234567) {$ok .= 'l'}
    else {warn "3l: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_z_uj($mpc, $gmp, $uj, $round);};
    if($@ =~ /Rmpc_set_z_uj not implemented/) {$ok .= 'i'}
    else {warn "3i: \$\@: $@\n"}

    eval {Rmpc_set_uj_z($mpc, $uj, $gmp, $round);};
    if($@ =~ /Rmpc_set_uj_z not implemented/) {$ok .= 'j'}
    else {warn "3j: \$\@: $@\n"}

    eval {Rmpc_set_z_sj($mpc, $gmp, $sj, $round);};
    if($@ =~ /Rmpc_set_z_sj not implemented/) {$ok .= 'k'}
    else {warn "3k: \$\@: $@\n"}

    eval {Rmpc_set_sj_z($mpc, $sj, $gmp, $round);};
    if($@ =~ /Rmpc_set_sj_z not implemented/) {$ok .= 'l'}
    else {warn "3l: \$\@: $@\n"}
  }

  if(Math::MPC::_has_longdouble()) {
    $ret = Rmpc_set_z_ld($mpc, $gmp, $ld, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == $ld) {$ok .= 'm'}
    else {warn "3m: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_ld_z($mpc, $ld, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $ld && $mpfr_im == 1234567) {$ok .= 'n'}
    else {warn "3n: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_z_ld($mpc, $gmp, $ld, $round);};
    if($@ =~ /Rmpc_set_z_ld not implemented/) {$ok .= 'm'}
    else {warn "3m: \$\@: $@\n"}

    eval {Rmpc_set_ld_z($mpc, $ld, $gmp, $round);};
    if($@ =~ /Rmpc_set_ld_z not implemented/) {$ok .= 'n'}
    else {warn "3n: \$\@: $@\n"}
  }

  $ret = Rmpc_set_z_fr($mpc, $gmp, $mpfr, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == $mpfr) {$ok .= 'o'}
  else {warn "3o: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_fr_z($mpc, $mpfr, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == 1234567) {$ok .= 'p'}
  else {warn "3p: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  if($have_GMPq) {
    my $gmpq = Math::GMPq->new(89083);
    $ret = Rmpc_set_z_q($mpc, $gmp, $gmpq, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == 89083) {$ok .= 'q'}
    else {warn "3q: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_q_z($mpc, $gmpq, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 89083 && $mpfr_im == 1234567) {$ok .= 'r'}
    else {warn "3r: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    warn " skipping 3q and 3r - no Math::GMPq\n";
    $ok .= 'qr';
  }

  if($have_GMPf) {
    my $gmpf = Math::GMPf->new(890213.5);
    $ret = Rmpc_set_z_f($mpc, $gmp, $gmpf, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234567 && $mpfr_im == 890213.5) {$ok .= 's'}
    else {warn "3s: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_f_z($mpc, $gmpf, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 890213.5 && $mpfr_im == 1234567) {$ok .= 't'}
    else {warn "3t: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    warn " skipping 3s and 3t - no Math::GMPf\n";
    $ok .= 'st';
  }

  if($ok eq 'abcdefghijklmnopqrst') {print "ok 3\n"}
  else {print "not ok 3\n$ok\n"}
}
else {
  print "ok 3 - skipped, no Math::GMP\n";
}

if($have_GMPz) {
  $ok = '';
  my $gmp = Math::GMPz->new(1234566);
  $ret = Rmpc_set_z($mpc, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == 0) {$ok .= 'a'}
  else {warn "4a: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  my $gmp2 = Math::GMPz->new(891);
  $ret = Rmpc_set_z_z($mpc, $gmp, $gmp2, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == 891) {$ok .= 'b'}
  else {warn "4b: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_z_ui($mpc, $gmp, $ui, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == $ui) {$ok .= 'c'}
  else {warn "4c: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ui_z($mpc, $ui, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ui && $mpfr_im == 1234566) {$ok .= 'd'}
  else {warn "4d: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_z_si($mpc, $gmp, $si, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == $si) {$ok .= 'e'}
  else {warn "4e: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_si_z($mpc, $si, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $si && $mpfr_im == 1234566) {$ok .= 'f'}
  else {warn "4f: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_z_d($mpc, $gmp, $d, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == $d) {$ok .= 'g'}
  else {warn "4g: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_d_z($mpc, $d, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $d && $mpfr_im == 1234566) {$ok .= 'h'}
  else {warn "4h: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  if(Math::MPC::_has_longlong()) {
    $ret = Rmpc_set_z_uj($mpc, $gmp, $uj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == $uj) {$ok .= 'i'}
    else {warn "4i: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_uj_z($mpc, $uj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $uj && $mpfr_im == 1234566) {$ok .= 'j'}
    else {warn "4j: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_z_sj($mpc, $gmp, $sj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == $sj) {$ok .= 'k'}
    else {warn "4k: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_sj_z($mpc, $sj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $sj && $mpfr_im == 1234566) {$ok .= 'l'}
    else {warn "4l: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_z_uj($mpc, $gmp, $uj, $round);};
    if($@ =~ /Rmpc_set_z_uj not implemented/) {$ok .= 'i'}
    else {warn "4i: \$\@: $@\n"}

    eval {Rmpc_set_uj_z($mpc, $uj, $gmp, $round);};
    if($@ =~ /Rmpc_set_uj_z not implemented/) {$ok .= 'j'}
    else {warn "4j: \$\@: $@\n"}

    eval {Rmpc_set_z_sj($mpc, $gmp, $sj, $round);};
    if($@ =~ /Rmpc_set_z_sj not implemented/) {$ok .= 'k'}
    else {warn "4k: \$\@: $@\n"}

    eval {Rmpc_set_sj_z($mpc, $sj, $gmp, $round);};
    if($@ =~ /Rmpc_set_sj_z not implemented/) {$ok .= 'l'}
    else {warn "4l: \$\@: $@\n"}
  }

  if(Math::MPC::_has_longdouble()) {
    $ret = Rmpc_set_z_ld($mpc, $gmp, $ld, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == $ld) {$ok .= 'm'}
    else {warn "4m: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_ld_z($mpc, $ld, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $ld && $mpfr_im == 1234566) {$ok .= 'n'}
    else {warn "4n: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_z_ld($mpc, $gmp, $ld, $round);};
    if($@ =~ /Rmpc_set_z_ld not implemented/) {$ok .= 'm'}
    else {warn "4m: \$\@: $@\n"}

    eval {Rmpc_set_ld_z($mpc, $ld, $gmp, $round);};
    if($@ =~ /Rmpc_set_ld_z not implemented/) {$ok .= 'n'}
    else {warn "4n: \$\@: $@\n"}
  }

  $ret = Rmpc_set_z_fr($mpc, $gmp, $mpfr, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == $mpfr) {$ok .= 'o'}
  else {warn "4o: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_fr_z($mpc, $mpfr, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == 1234566) {$ok .= 'p'}
  else {warn "4p: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  if($have_GMPq) {
    my $gmpq = Math::GMPq->new(8903);
    $ret = Rmpc_set_z_q($mpc, $gmp, $gmpq, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == 8903) {$ok .= 'q'}
    else {warn "4q: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_q_z($mpc, $gmpq, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 8903 && $mpfr_im == 1234566) {$ok .= 'r'}
    else {warn "4r: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    warn " skipping 4q and 4r - no Math::GMPq\n";
    $ok .= 'qr';
  }

  if($have_GMPf) {
    my $gmpf = Math::GMPf->new(89023.5);
    $ret = Rmpc_set_z_f($mpc, $gmp, $gmpf, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234566 && $mpfr_im == 89023.5) {$ok .= 's'}
    else {warn "4s: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_f_z($mpc, $gmpf, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 89023.5 && $mpfr_im == 1234566) {$ok .= 't'}
    else {warn "4t: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    warn " skipping 4s and 4t - no Math::GMPf\n";
    $ok .= 'st';
  }

  if($ok eq 'abcdefghijklmnopqrst') {print "ok 4\n"}
  else {print "not ok 4\n$ok\n"}
}
else {
  print "ok 4 - skipped, no Math::GMPz\n";
}

if($have_GMPq) {
  $ok = '';
  my $gmp = Math::GMPq->new(1234565);
  $ret = Rmpc_set_q($mpc, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == 0) {$ok .= 'a'}
  else {warn "5a: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  my $gmp2 = Math::GMPq->new(8921);
  $ret = Rmpc_set_q_q($mpc, $gmp, $gmp2, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == 8921) {$ok .= 'b'}
  else {warn "5b: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_q_ui($mpc, $gmp, $ui, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == $ui) {$ok .= 'c'}
  else {warn "5c: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ui_q($mpc, $ui, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ui && $mpfr_im == 1234565) {$ok .= 'd'}
  else {warn "5d: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_q_si($mpc, $gmp, $si, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == $si) {$ok .= 'e'}
  else {warn "5e: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_si_q($mpc, $si, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $si && $mpfr_im == 1234565) {$ok .= 'f'}
  else {warn "5f: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_q_d($mpc, $gmp, $d, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == $d) {$ok .= 'g'}
  else {warn "5g: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_d_q($mpc, $d, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $d && $mpfr_im == 1234565) {$ok .= 'h'}
  else {warn "5h: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  if(Math::MPC::_has_longlong()) {
    $ret = Rmpc_set_q_uj($mpc, $gmp, $uj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == $uj) {$ok .= 'i'}
    else {warn "5i: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_uj_q($mpc, $uj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $uj && $mpfr_im == 1234565) {$ok .= 'j'}
    else {warn "5j: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_q_sj($mpc, $gmp, $sj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == $sj) {$ok .= 'k'}
    else {warn "4k: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_sj_q($mpc, $sj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $sj && $mpfr_im == 1234565) {$ok .= 'l'}
    else {warn "5l: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_q_uj($mpc, $gmp, $uj, $round);};
    if($@ =~ /Rmpc_set_q_uj not implemented/) {$ok .= 'i'}
    else {warn "5i: \$\@: $@\n"}

    eval {Rmpc_set_uj_q($mpc, $uj, $gmp, $round);};
    if($@ =~ /Rmpc_set_uj_q not implemented/) {$ok .= 'j'}
    else {warn "5j: \$\@: $@\n"}

    eval {Rmpc_set_q_sj($mpc, $gmp, $sj, $round);};
    if($@ =~ /Rmpc_set_q_sj not implemented/) {$ok .= 'k'}
    else {warn "5k: \$\@: $@\n"}

    eval {Rmpc_set_sj_q($mpc, $sj, $gmp, $round);};
    if($@ =~ /Rmpc_set_sj_q not implemented/) {$ok .= 'l'}
    else {warn "5l: \$\@: $@\n"}
  }

  if(Math::MPC::_has_longdouble()) {
    $ret = Rmpc_set_q_ld($mpc, $gmp, $ld, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == $ld) {$ok .= 'm'}
    else {warn "5m: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_ld_q($mpc, $ld, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $ld && $mpfr_im == 1234565) {$ok .= 'n'}
    else {warn "5n: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_q_ld($mpc, $gmp, $ld, $round);};
    if($@ =~ /Rmpc_set_q_ld not implemented/) {$ok .= 'm'}
    else {warn "5m: \$\@: $@\n"}

    eval {Rmpc_set_ld_q($mpc, $ld, $gmp, $round);};
    if($@ =~ /Rmpc_set_ld_q not implemented/) {$ok .= 'n'}
    else {warn "5n: \$\@: $@\n"}
  }

  $ret = Rmpc_set_q_fr($mpc, $gmp, $mpfr, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == $mpfr) {$ok .= 'o'}
  else {warn "5o: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_fr_q($mpc, $mpfr, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == 1234565) {$ok .= 'p'}
  else {warn "5p: $ret $mpfr_re $mpfr_im\n$mpc\n"}


  if($have_GMPf) {
    my $gmpf = Math::GMPf->new(89024.5);
    $ret = Rmpc_set_q_f($mpc, $gmp, $gmpf, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234565 && $mpfr_im == 89024.5) {$ok .= 'q'}
    else {warn "5q: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_f_q($mpc, $gmpf, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 89024.5 && $mpfr_im == 1234565) {$ok .= 'r'}
    else {warn "5r: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    warn " skipping 5q and 5r - no Math::GMPf\n";
    $ok .= 'qr';
  }

  if($ok eq 'abcdefghijklmnopqr') {print "ok 5\n"}
  else {print "not ok 5\n$ok\n"}
}
else {
  print "ok 5 - skipped, no Math::GMPq\n";
}

if($have_GMPf) {
  $ok = '';
  my $gmp = Math::GMPf->new(1234564.5);
  $ret = Rmpc_set_f($mpc, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == 0) {$ok .= 'a'}
  else {warn "6a: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  my $gmp2 = Math::GMPf->new(8921.5);
  $ret = Rmpc_set_f_f($mpc, $gmp, $gmp2, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == 8921.5) {$ok .= 'b'}
  else {warn "6b: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_f_ui($mpc, $gmp, $ui, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == $ui) {$ok .= 'c'}
  else {warn "6c: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_ui_f($mpc, $ui, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $ui && $mpfr_im == 1234564.5) {$ok .= 'd'}
  else {warn "6d: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_f_si($mpc, $gmp, $si, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == $si) {$ok .= 'e'}
  else {warn "6e: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_si_f($mpc, $si, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $si && $mpfr_im == 1234564.5) {$ok .= 'f'}
  else {warn "6f: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_f_d($mpc, $gmp, $d, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == $d) {$ok .= 'g'}
  else {warn "6g: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_d_f($mpc, $d, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $d && $mpfr_im == 1234564.5) {$ok .= 'h'}
  else {warn "6h: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  if(Math::MPC::_has_longlong()) {
    $ret = Rmpc_set_f_uj($mpc, $gmp, $uj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == $uj) {$ok .= 'i'}
    else {warn "6i: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_uj_f($mpc, $uj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $uj && $mpfr_im == 1234564.5) {$ok .= 'j'}
    else {warn "6j: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_f_sj($mpc, $gmp, $sj, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == $sj) {$ok .= 'k'}
    else {warn "6k: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_sj_f($mpc, $sj, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $sj && $mpfr_im == 1234564.5) {$ok .= 'l'}
    else {warn "6l: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_f_uj($mpc, $gmp, $uj, $round);};
    if($@ =~ /Rmpc_set_f_uj not implemented/) {$ok .= 'i'}
    else {warn "6i: \$\@: $@\n"}

    eval {Rmpc_set_uj_f($mpc, $uj, $gmp, $round);};
    if($@ =~ /Rmpc_set_uj_f not implemented/) {$ok .= 'j'}
    else {warn "6j: \$\@: $@\n"}

    eval {Rmpc_set_f_sj($mpc, $gmp, $sj, $round);};
    if($@ =~ /Rmpc_set_f_sj not implemented/) {$ok .= 'k'}
    else {warn "6k: \$\@: $@\n"}

    eval {Rmpc_set_sj_f($mpc, $sj, $gmp, $round);};
    if($@ =~ /Rmpc_set_sj_f not implemented/) {$ok .= 'l'}
    else {warn "6l: \$\@: $@\n"}
  }

  if(Math::MPC::_has_longdouble()) {
    $ret = Rmpc_set_f_ld($mpc, $gmp, $ld, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == $ld) {$ok .= 'm'}
    else {warn "6m: $ret $mpfr_re $mpfr_im\n$mpc\n"}

    $ret = Rmpc_set_ld_f($mpc, $ld, $gmp, $round);
    Rmpc_real($mpfr_re, $mpc, $round);
    Rmpc_imag($mpfr_im, $mpc, $round);
    if($ret == 0 && $mpfr_re == $ld && $mpfr_im == 1234564.5) {$ok .= 'n'}
    else {warn "6n: $ret $mpfr_re $mpfr_im\n$mpc\n"}
  }
  else {
    eval {Rmpc_set_f_ld($mpc, $gmp, $ld, $round);};
    if($@ =~ /Rmpc_set_f_ld not implemented/) {$ok .= 'm'}
    else {warn "6m: \$\@: $@\n"}

    eval {Rmpc_set_ld_f($mpc, $ld, $gmp, $round);};
    if($@ =~ /Rmpc_set_ld_f not implemented/) {$ok .= 'n'}
    else {warn "6n: \$\@: $@\n"}
  }

  $ret = Rmpc_set_f_fr($mpc, $gmp, $mpfr, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == 1234564.5 && $mpfr_im == $mpfr) {$ok .= 'o'}
  else {warn "6o: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  $ret = Rmpc_set_fr_f($mpc, $mpfr, $gmp, $round);
  Rmpc_real($mpfr_re, $mpc, $round);
  Rmpc_imag($mpfr_im, $mpc, $round);
  if($ret == 0 && $mpfr_re == $mpfr && $mpfr_im == 1234564.5) {$ok .= 'p'}
  else {warn "6p: $ret $mpfr_re $mpfr_im\n$mpc\n"}

  if($ok eq 'abcdefghijklmnop') {print "ok 6\n"}
  else {print "not ok 6\n$ok\n"}
}
else {
  print "ok 6 - skipped, no Math::GMPf\n";
}

$ok = '';

unless(Math::MPC::_have_Complex_h()) {
  eval{Rmpc_set_dc($mpc, $round, $round);};
  if($@){
    $ok .= 'a';
    if($@ =~ /not implemented/){$ok .= 'b'}
    else {warn "a: \$\@: $@\n"}
  }

  eval{Rmpc_set_ldc($mpc, $round, $round);};
  if($@){
    $ok .= 'c';
    if($@ =~ /not implemented/){$ok .= 'd'}
    else {warn "a: \$\@: $@\n"}
  }
}
else {
  warn "Skipping test 7 - Math::MPC::_have_complex_h returns true\n";
  $ok = 'abcd';
}

if($ok eq 'abcd') {print "ok 7\n"}
else {
  warn "7: \$ok: $ok\n";
  print "not ok 7\n";
}

$ok = '';

unless(Math::MPC::_have_Complex_h()) {
  eval{Rmpc_get_dc($round, $mpc, $round);};
  if($@){
    $ok .= 'a';
    if($@ =~ /not implemented/){$ok .= 'b'}
    else {warn "a: \$\@: $@\n"}
  }

  eval{Rmpc_get_ldc($round, $mpc, $round);};
  if($@){
    $ok .= 'c';
    if($@ =~ /not implemented/){$ok .= 'd'}
    else {warn "a: \$\@: $@\n"}
  }
}
else {
  warn "Skipping test 8 - Math::MPC::_have_complex_h returns true\n";
  $ok = 'abcd';
}

if($ok eq 'abcd') {print "ok 8\n"}
else {
  warn "8: \$ok: $ok\n";
  print "not ok 8\n";
}
