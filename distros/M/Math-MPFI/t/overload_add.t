use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;
use Config;

print "1..11\n";

my $f128_mismatch = 0;

# Set $f128_mismatch if Math::MPFR can handle __float128 && Math::MPFI has been built to *not*
# handle __float128 && nvtype is __float128.
$f128_mismatch = 1 if(Math::MPFR::_can_pass_float128()
                  && !Math::MPFI::_can_pass_float128());

warn "\nMath::MPFR and Math::MPFI have been built with different __float128 handling\n",
     "capabilities. Better to build Math::MPFI by starting with:\n",
     "   perl Makefile.PL F128=1\n\n" if $f128_mismatch;

my ($have_gmpq, $have_gmpz, $have_gmp) = (0, 0, 0);
my ($mpq, $mpz, $gmp);
my @str = ('1@-1', 10);
my $double = 0.1;
my $ui = ~0;
my $si = (($ui - 1) / 2) * -1;
my $mpfr = Math::MPFR->new('12347.1');
my $prec = 165;
my $ok = '';
Rmpfi_set_default_prec($prec);

eval{require Math::GMPq;};
unless($@) {$have_gmpq = 1}

eval{require Math::GMPz;};
unless($@) {$have_gmpz = 1}

eval{require Math::GMP;};
unless($@) {$have_gmp = 1}

my $foo1 = Math::MPFI->new(12345);
my $orig = Math::MPFI->new($foo1);

################################### TEST 1

my $foo2 = $foo1 + $str[0];
$foo1 += $str[0];

if($foo1 == '12345.1') {$ok .= 'a'}
else {warn "1a: $foo1 != 12345.1\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "1b: $foo1 != $foo2\n"}

$foo1 -= $str[0];
if($foo1 == $orig) {$ok .= 'c'}
else {warn "1c: $foo1 != $orig\n"}

$foo2 = $foo2 - $str[0];
if($foo2 == $orig) {$ok .= 'd'}
else {warn "1d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

################################### TEST 2

$ok = '';

$foo2 = $foo1 + $double;
$foo1 += $double;

my $check = Math::MPFI->new(12345);
if(Math::MPFI::_has_longdouble()) { # MPFI has no _ld/_float128 functions
  my $temp;
  if(!$f128_mismatch) {
    $temp = Math::MPFR->new($double);
  }
  else {
    $temp = Math::MPFR->new();
    Rmpfr_set_ld($temp, $double, Rmpfr_get_default_rounding_mode());
  }
  Rmpfi_add_fr($check, $check, $temp);
}
else {
  Rmpfi_add_d($check, $check, $double);
}

if($foo1 == $check) {$ok .= 'a'}
else {warn "2a: $foo1 != ", $check, "\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "2b: $foo1 != $foo2\n"}

$foo1 -= $double;
if($foo1 == $orig) {$ok .= 'c'}
else {warn "2c: $foo1 != $orig\n"}

$foo2 = $foo2 - $double;
if($foo2 == $orig) {$ok .= 'd'}
else {warn "2d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

################################### TEST 3

$ok = '';

$foo2 = $foo1 + $ui;
$foo1 += $ui;

Rmpfi_set_ui($check, 12345);
if(Math::MPFI::_has_longlong()) { # MPFI has no _uj functions
  my $temp = Math::MPFR->new($ui);
  Rmpfi_add_fr($check, $check, $temp);
}
else {
  Rmpfi_add_ui($check, $check, $ui);
}

if($foo1 == $check) {$ok .= 'a'}
else {warn "3a: $foo1 != ", $check, "\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "3b: $foo1 != $foo2\n"}

$foo1 -= $ui;
if($foo1 == $orig) {$ok .= 'c'}
else {warn "3c: $foo1 != $orig\n"}

$foo2 = $foo2 - $ui;
if($foo2 == $orig) {$ok .= 'd'}
else {warn "3d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

################################### TEST 4

$ok = '';

$foo2 = $foo1 + $si;
$foo1 += $si;

Rmpfi_set_ui($check, 12345);
if(Math::MPFI::_has_longlong()) { # MPFI has no _sj functions
  my $temp = Math::MPFR->new($si);
  Rmpfi_add_fr($check, $check, $temp);
}
else {
  Rmpfi_add_si($check, $check, $si);
}

if($foo1 == $check) {$ok .= 'a'}
else {warn "4a: $foo1 != ", $check, "\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "4b: $foo1 != $foo2\n"}

$foo1 -= $si;
if($foo1 == $orig) {$ok .= 'c'}
else {warn "4c: $foo1 != $orig\n"}

$foo2 = $foo2 - $si;
if($foo2 == $orig) {$ok .= 'd'}
else {warn "4d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 4\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 4\n";
}

################################### TEST 5

$ok = '';

if($have_gmpq) {
  my $gmp = Math::GMPq->new('1/2');
  Rmpfi_add_q($foo2, $foo1, $gmp);
  $foo1 += 0.5;

  if($foo1 == $foo2) {print "ok 5\n"}
  else {
    warn "$foo1 != $foo2\n";
    print "not ok 5\n";
  }

  $foo1 -= 0.5;
  $foo2 -= 0.5;
}
else {
  warn "Skipping test 5 - no Math::GMPq\n";
  print "ok 5\n";
}

################################### TEST 6

$ok = '';

if($have_gmpz) {
  my $gmp = Math::GMPz->new(9876);
  Rmpfi_add_z($foo2, $foo1, $gmp);
  $foo1 += 9876;

  if($foo1 == $foo2) {print "ok 6\n"}
  else {
    warn "$foo1 != $foo2\n";
    print "not ok 6\n";
  }

  $foo1 -= 9876;
  $foo2 -= 9876;
}
else {
  warn "Skipping test 6 - no Math::GMPz\n";
  print "ok 6\n";
}

################################### TEST 7

$ok = '';

if($have_gmp) {
  my $gmp = Math::GMP->new(9876);
  Rmpfi_add_z($foo2, $foo1, $gmp);
  $foo1 += 9876;

  if($foo1 == $foo2) {print "ok 7\n"}
  else {
    warn "$foo1 != $foo2\n";
    print "not ok 7\n";
  }

  $foo1 -= 9876;
  $foo2 -= 9876;
}
else {
  warn "Skipping test 7 - no Math::GMP\n";
  print "ok 7\n";
}

################################### TEST 8

if($foo1 + $foo1 == 2 * $foo1) {print "ok 8\n"}
else {
  warn $foo1 + $foo1, " != ", 2 * $foo1, "\n";
  print "not ok 8\n";
}

################################### TEST 9

$orig += $orig;

if($orig == 2 * $foo1) {print "ok 9\n"}
else {
  warn $orig, " != ", 2 * $foo1, "\n";
  print "not ok 9\n";
}

################################### TEST 10

$orig -= 12345;

if($orig ==  $foo1) {print "ok 10\n"}
else {
  warn $orig, " != ", $foo1, "\n";
  print "not ok 10\n";
}

################################### TEST 11

$ok = '';

$foo1 = '5@-1' - $foo1;
if($foo1 == -12344.5) {$ok .= 'a'}
else {warn "11a: $foo1 != -12344.5\n"}

$foo1 = 0.5 - $foo1;
if($foo1 == 12345) {$ok .= 'b'}
else {warn "11b: $foo1 != 12345\n"}

$foo1 = $ui - $foo1;
if($foo1 == ~0 - 12345) {$ok .= 'c'}
else {warn "11c: $foo1 != ", ~0 - 12345, "\n"}

$foo1 = $ui - $foo1; # Restore $foo1 to 12345.
if($foo1 == 12345) {$ok .= 'd'}
else {warn "11d: $foo1 != 12345\n"}

$si += 12347; # To avoid overflow on 64-bit int builds

$foo1 = $si - $foo1;
if($foo1 == $si - 12345) {$ok .= 'e'}
else {warn "11e: $foo1 != ", $si - 12345, "\n"}

$foo1 = $si - $foo1; # Restore $foo1 to 12345.
if($foo1 == 12345) {$ok .= 'f'}
else {warn "11f: $foo1 != 12345\n"}

if($ok eq 'abcdef') {print "ok 11\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 11\n";
}
