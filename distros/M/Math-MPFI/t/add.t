use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..13\n";

my ($have_gmpq, $have_gmpz, $have_gmp) = (0, 0, 0);
my ($mpq, $mpz, $gmp);
my @str = ('1@-1', 10);
my $double = 0.25;
my $ui = 117;
my $si = -123;
my $mpfr = Math::MPFR->new(12347);
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
my $foo2 = Math::MPFI->new();
my $mpfi = Math::MPFI->new($str[0]);

################################### TEST 1

Rmpfi_add($foo2, $foo1, $mpfi);
Rmpfi_add($foo1, $foo1, $mpfi);

if($foo1 == '12345.1') {$ok .= 'a'}
else {warn "1a: $foo1 != 12345.1\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "1b: $foo1 != $foo2\n"}

Rmpfi_sub($foo1, $foo1, $mpfi);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "1c: $foo1 != $orig\n"}

Rmpfi_sub($foo2, $foo2, $mpfi);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "1d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

################################### TEST 2

$ok = '';

Rmpfi_add_d($foo2, $foo1, $double);
Rmpfi_add_d($foo1, $foo1, $double);

if($foo1 == 12345.25) {$ok .= 'a'}
else {warn "2a: $foo1 != 12345.25\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "2b: $foo1 != $foo2\n"}

Rmpfi_sub_d($foo1, $foo1, $double);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "2c: $foo1 != $orig\n"}

Rmpfi_sub_d($foo2, $foo2, $double);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "2d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

################################### TEST 3

$ok = '';

Rmpfi_add_ui($foo2, $foo1, $ui);
Rmpfi_add_ui($foo1, $foo1, $ui);


if($foo1 == 12462) {$ok .= 'a'}
else {warn "3a: $foo1 != 12462\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "3b: $foo1 != $foo2\n"}

Rmpfi_sub_ui($foo1, $foo1, $ui);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "3c: $foo1 != $orig\n"}

Rmpfi_sub_ui($foo2, $foo2, $ui);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "3d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

################################### TEST 4

$ok = '';

Rmpfi_add_si($foo2, $foo1, $si);
Rmpfi_add_si($foo1, $foo1, $si);

if($foo1 == 12222) {$ok .= 'a'}
else {warn "4a: $foo1 != 12222\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "4b: $foo1 != $foo2\n"}

Rmpfi_sub_si($foo1, $foo1, $si);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "4c: $foo1 != $orig\n"}

Rmpfi_sub_si($foo2, $foo2, $si);
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

  Rmpfi_sub_q($foo1, $foo1, $gmp);
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

  Rmpfi_sub_z($foo1, $foo1, $gmp);
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

  Rmpfi_sub_z($foo1, $foo1, $gmp);
  $foo2 -= 9876;
}
else {
  warn "Skipping test 7 - no Math::GMP\n";
  print "ok 7\n";
}

################################### TEST 8

$ok = '';

Rmpfi_add_fr($foo2, $foo1, $mpfr);
Rmpfi_add_fr($foo1, $foo1, $mpfr);

if($foo1 == 24692) {$ok .= 'a'}
else {warn "8a: $foo1 != 24692\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "8b: $foo1 != $foo2\n"}

Rmpfi_sub_fr($foo1, $foo1, $mpfr);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "8c: $foo1 != $orig\n"}

Rmpfi_sub_fr($foo2, $foo2, $mpfr);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "8d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 8\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 8\n";
}

################################### TEST 9

$ok = '';

$double += 10;

Rmpfi_d_sub($foo1, $double, $foo1);

if($foo1 == -12334.75) {$ok .= 'a'}
else {warn "9a: $foo1 != -12334.75\n"}

$foo1 -= $double;
$foo1 *= -1;

if($foo1 == $orig) {$ok .= 'b'}
else {warn "9b: $foo1 != $orig\n"}

# Rmpfi_ui_sub($foo1, $ui, $foo1); # Broken in mpfi-1.4, when source and destination are same variable.
my $foot = Math::MPFI->new();
Rmpfi_ui_sub($foot, $ui, $foo1);

#$foo1 -= $ui;
#$foo1 *= -1;

if($foot == -12228) {$ok .= 'c'}
else {warn "9c: $foot != -12228\n"}

if($foo1 == $orig) {$ok .= 'd'}
else {warn "9d: $foo1 != $orig\n"}

Rmpfi_si_sub($foo1, $si, $foo1);

if($foo1 == -12468) {$ok .= 'e'}
else {warn "9e: $foo1 != -12468\n"}

$foo1 -= $si;
$foo1 *= -1;

if($foo1 == $orig) {$ok .= 'f'}
else {warn "9f: $foo1 != $orig\n"}

Rmpfi_fr_sub($foo1, $mpfr, $foo1);

if($foo1 == 2) {$ok .= 'g'}
else {warn "9g: $foo1 != 2\n"}

Rmpfi_sub_fr($foo1, $foo1, $mpfr);
$foo1 *= -1;

if($foo1 == $orig) {$ok .= 'h'}
else {warn "9h: $foo1 != $orig\n"}

if($ok eq 'abcdefgh') {print "ok 9\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 9\n";
}

################################### TEST 10

if($have_gmpq) {
  my $gmp = Math::GMPq->new('21/2');
  Rmpfi_q_sub($foo1, $gmp, $foo1);

  if($foo1 == -12334.5) {print "ok 10\n"}
  else {
    warn "$foo1 != -12334.5\n";
    print "not ok 10\n";
  }

  Rmpfi_sub_q($foo1, $foo1, $gmp);
  $foo1 *= -1;
}
else {
  warn "Skipping test 10 - no Math::GMPq\n";
  print "ok 10\n";
}

################################### TEST 11

if($have_gmpz) {
  my $gmp = Math::GMPz->new(20);
  Rmpfi_z_sub($foo1, $gmp, $foo1);

  if($foo1 == -12325) {print "ok 11\n"}
  else {
    warn "$foo1 != -12325\n";
    print "not ok 11\n";
  }

  Rmpfi_sub_z($foo1, $foo1, $gmp);
  $foo1 *= -1;
}
else {
  warn "Skipping test 11 - no Math::GMPz\n";
  print "ok 11\n";
}

################################### TEST 12

if($have_gmp) {
  my $gmp = Math::GMP->new(20);
  Rmpfi_z_sub($foo1, $gmp, $foo1);

  if($foo1 == -12325) {print "ok 12\n"}
  else {
    warn "$foo1 != -12325\n";
    print "not ok 12\n";
  }

  Rmpfi_sub_z($foo1, $foo1, $gmp);
  $foo1 *= -1;
}
else {
  warn "Skipping test 12 - no Math::GMP\n";
  print "ok 12\n";
}

################################### TEST 13

if($foo1 == 12345) {print "ok 13\n"}
else {
  warn "13: $foo1 != 12345\n";
  print "not ok 13\n";
}

#print "$foo1\n";
