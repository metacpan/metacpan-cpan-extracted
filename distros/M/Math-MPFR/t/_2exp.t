use warnings;
use strict;
use Math::MPFR qw(:mpfr);
#use Devel::Peek;

print "1..3\n";

my ($exp, $ret);
my $rop   = Math::MPFR->new();
my $op1   = Math::MPFR->new(64.75);
my $op2   = Math::MPFR->new(0.25);
my $nan   = Math::MPFR->new();
my $zero  = Math::MPFR->new(0);
my $unity = Math::MPFR->new(1);
my $inf   = $unity / $zero;
my $ninf  = -($inf);
my $nzero = $zero * -1;
my $ok = '';

if((MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3) {
  $ret = Rmpfr_frexp($exp, $rop, $op1, GMP_RNDN);
  if($ret == 0 && $exp == 7 && $rop == 0.505859375) {$ok .= 'a'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, $op2, GMP_RNDN);
  if($ret == 0 && $exp == -1 && $rop == 0.5) {$ok .= 'b'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, -$op1, GMP_RNDN);
  if($ret == 0 && $exp == 7 && $rop == -0.505859375) {$ok .= 'c'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, -$op2, GMP_RNDN);
  if($ret == 0 && $exp == -1 && $rop == -0.5) {$ok .= 'd'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, $zero, GMP_RNDN);
  if($ret == 0 && $exp == 0 && $rop == 0 && Rmpfr_sgn($rop) == 0 && !Rmpfr_signbit($rop)) {$ok .= 'e'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, $nzero, GMP_RNDN);
  if($ret == 0 && $exp == 0 && $rop == 0 && !Rmpfr_sgn($rop) && Rmpfr_signbit($rop)) {$ok .= 'f'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, $nan, GMP_RNDN);
  if($ret == 0 && Rmpfr_nan_p($rop)) {$ok .= 'g'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, $inf, GMP_RNDN);
  if($ret == 0 && Rmpfr_inf_p($rop) && !Rmpfr_signbit($rop)) {$ok .= 'h'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  $ret = Rmpfr_frexp($exp, $rop, $ninf, GMP_RNDN);
  if($ret == 0 && Rmpfr_inf_p($rop) && Rmpfr_signbit($rop)) {$ok .= 'i'}
  #print "$ret $exp $rop\n", $rop * (2 ** $exp), "\n\n";

  if($ok eq 'abcdefghi') {print "ok 1\n"}
  else {
    warn "1: \$ok: $ok\n";
    print "not ok 1\n";
  }
}
else {
  eval{Rmpfr_frexp($exp, $rop, $op1, GMP_RNDN);};
  if($@ =~ /Rmpfr_frexp not implemented/) {print "ok 1\n"}
  else {
    warn "\$\@: $@";
    print "not ok 1\n";
  }
}

$ok = '';

$ret = Rmpfr_get_d_2exp($exp, $op1, GMP_RNDN);
if($exp == 7 && $ret == 0.505859375) {$ok .= 'a'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, $op2, GMP_RNDN);
if($exp == -1 && $ret == 0.5) {$ok .= 'b'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, -$op1, GMP_RNDN);
if($exp == 7 && $ret == -0.505859375) {$ok .= 'c'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, -$op2, GMP_RNDN);
if($exp == -1 && $ret == -0.5) {$ok .= 'd'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, $zero, GMP_RNDN);
if($exp == 0 && is_pzero($ret)) {$ok .= 'e'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, $nzero, GMP_RNDN);
if($exp == 0 && is_nzero($ret)) {$ok .= 'f'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, $nan, GMP_RNDN);
if(is_nan($ret)) {$ok .= 'g'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, $inf, GMP_RNDN);
if(is_pinf($ret)) {$ok .= 'h'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

$ret = Rmpfr_get_d_2exp($exp, $ninf, GMP_RNDN);
if(is_ninf($ret)) {$ok .= 'i'}
#print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

if($ok eq 'abcdefghi') {print "ok 2\n"}
else {
  warn "2: \$ok: $ok\n";
  print "not ok 2\n";
}

$ok = '';

if(Math::MPFR::_has_longdouble()) {
  $ret = Rmpfr_get_ld_2exp($exp, $op1, GMP_RNDN);
  if($exp == 7 && $ret == 0.505859375) {$ok .= 'a'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, $op2, GMP_RNDN);
  if($exp == -1 && $ret == 0.5) {$ok .= 'b'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, -$op1, GMP_RNDN);
  if($exp == 7 && $ret == -0.505859375) {$ok .= 'c'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, -$op2, GMP_RNDN);
  if($exp == -1 && $ret == -0.5) {$ok .= 'd'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, $zero, GMP_RNDN);
  if($exp == 0 && is_pzero($ret)) {$ok .= 'e'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, $nzero, GMP_RNDN);
  if($exp == 0 && is_nzero($ret)) {$ok .= 'f'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, $nan, GMP_RNDN);
  if(is_nan($ret)) {$ok .= 'g'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, $inf, GMP_RNDN);
  if(is_pinf($ret)) {$ok .= 'h'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  $ret = Rmpfr_get_ld_2exp($exp, $ninf, GMP_RNDN);
  if(is_ninf($ret)) {$ok .= 'i'}
  #print "$ret $exp\n", $ret * (2 ** $exp), "\n\n";

  if($ok eq 'abcdefghi') {print "ok 3\n"}
  else {
    warn "3: \$ok: $ok\n";
    print "not ok 3\n";
  }
}
else {
  warn "Skipping test 3 - no long double support\n";
  print "ok 3\n";
}

sub is_nan {
    return Rmpfr_nan_p(Math::MPFR->new($_[0]));
}

sub is_pinf {
    my $x = Math::MPFR->new($_[0]);
    if(Rmpfr_inf_p($x) && !Rmpfr_signbit($x)) {return 1}
    return 0;
}

sub is_ninf {
    my $x = Math::MPFR->new($_[0]);
    if(Rmpfr_inf_p($x) && Rmpfr_signbit($x)) {return 1}
    return 0;
}

sub is_pzero {
    my $x = Math::MPFR->new($_[0]);
    if(Rmpfr_zero_p($x) && !Rmpfr_signbit($x)) {return 1}
    return 0;
}

sub is_nzero {
    my $x = Math::MPFR->new($_[0]);
    if(Rmpfr_zero_p($x) && Rmpfr_signbit($x)) {return 1}
    return 0;
}

