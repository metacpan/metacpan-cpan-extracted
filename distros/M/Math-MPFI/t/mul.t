use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..14\n";

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

Rmpfi_mul($foo2, $foo1, $mpfi);
Rmpfi_mul($foo1, $foo1, $mpfi);

if($foo1 == '1234.5') {$ok .= 'a'}
else {warn "1a: $foo1 != 1234.5\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "1b: $foo1 != $foo2\n"}

Rmpfi_div($foo1, $foo1, $mpfi);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "1c: $foo1 != $orig\n"}

Rmpfi_div($foo2, $foo2, $mpfi);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "1d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

################################### TEST 2

$ok = '';

Rmpfi_mul_d($foo2, $foo1, $double);
Rmpfi_mul_d($foo1, $foo1, $double);

if($foo1 == 3086.25) {$ok .= 'a'}
else {warn "2a: $foo1 != 3086.25\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "2b: $foo1 != $foo2\n"}

Rmpfi_div_d($foo1, $foo1, $double);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "2c: $foo1 != $orig\n"}

Rmpfi_div_d($foo2, $foo2, $double);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "2d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

################################### TEST 3

$ok = '';

Rmpfi_mul_ui($foo2, $foo1, $ui);
Rmpfi_mul_ui($foo1, $foo1, $ui);


if($foo1 == 1444365) {$ok .= 'a'}
else {warn "3a: $foo1 != 1444365\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "3b: $foo1 != $foo2\n"}

Rmpfi_div_ui($foo1, $foo1, $ui);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "3c: $foo1 != $orig\n"}

Rmpfi_div_ui($foo2, $foo2, $ui);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "3d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

################################### TEST 4

$ok = '';

Rmpfi_mul_si($foo2, $foo1, $si);
Rmpfi_mul_si($foo1, $foo1, $si);

if($foo1 == -1518435) {$ok .= 'a'}
else {warn "4a: $foo1 != -11518435\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "4b: $foo1 != $foo2\n"}

Rmpfi_div_si($foo1, $foo1, $si);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "4c: $foo1 != $orig\n"}

Rmpfi_div_si($foo2, $foo2, $si);
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
  Rmpfi_mul_q($foo1, $foo1, $gmp);

  if($foo1 == 6172.5) {print "ok 5\n"}
  else {
    warn "$foo1 != 6172.5\n";
    print "not ok 5\n";
  }

  Rmpfi_div_q($foo1, $foo1, $gmp);
}
else {
  warn "Skipping test 5 - no Math::GMPq\n";
  print "ok 5\n";
}

################################### TEST 6

$ok = '';

if($have_gmpz) {
  my $gmp = Math::GMPz->new(9876);
  Rmpfi_mul_z($foo1, $foo1, $gmp);


  if($foo1 == 121919220) {print "ok 6\n"}
  else {
    warn "$foo1 != 121919220\n";
    print "not ok 6\n";
  }

  Rmpfi_div_z($foo1, $foo1, $gmp);
}
else {
  warn "Skipping test 6 - no Math::GMPz\n";
  print "ok 6\n";
}

################################### TEST 7

$ok = '';

if($have_gmp) {
  my $gmp = Math::GMP->new(9876);
  Rmpfi_mul_z($foo1, $foo1, $gmp);

  if($foo1 == 121919220) {print "ok 7\n"}
  else {
    warn "$foo1 != 121919220\n";
    print "not ok 7\n";
  }

  Rmpfi_div_z($foo1, $foo1, $gmp);
}
else {
  warn "Skipping test 7 - no Math::GMP\n";
  print "ok 7\n";
}

################################### TEST 8

$ok = '';

Rmpfi_mul_fr($foo2, $foo1, $mpfr);
Rmpfi_mul_fr($foo1, $foo1, $mpfr);

if($foo1 == 152423715) {$ok .= 'a'}
else {warn "8a: $foo1 != 152423715\n"}

if($foo1 == $foo2) {$ok .= 'b'}
else {warn "8b: $foo1 != $foo2\n"}

Rmpfi_div_fr($foo1, $foo1, $mpfr);
if($foo1 == $orig) {$ok .= 'c'}
else {warn "8c: $foo1 != $orig\n"}

Rmpfi_div_fr($foo2, $foo2, $mpfr);
if($foo2 == $orig) {$ok .= 'd'}
else {warn "8d: $foo2 != $orig\n"}

if($ok eq 'abcd') {print "ok 8\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 8\n";
}

################################### TEST 9

$ok = '';

$double = 24690.0;

Rmpfi_d_div($foo1, $double, $foo1);

if($foo1 == 2) {$ok .= 'a'}
else {warn "9a: $foo1 != 2\n"}

$foo1 = $double / $foo1;

if($foo1 == $orig) {$ok .= 'b'}
else {warn "9b: $foo1 != $orig\n"}

$ui = 24690;

Rmpfi_ui_div($foo1, $ui, $foo1);

if($foo1 == 2) {$ok .= 'c'}
else {warn "9c: $foo1 != 2\n"}

$foo1 = $ui / $foo1;

if($foo1 == $orig) {$ok .= 'd'}
else {warn "9d: $foo1 != $orig\n"}

$si = -24690;

Rmpfi_si_div($foo1, $si, $foo1);

if($foo1 == -2) {$ok .= 'e'}
else {warn "9e: $foo1 != -2\n"}

$foo1 = $si / $foo1;;

if($foo1 == $orig) {$ok .= 'f'}
else {warn "9f: $foo1 != $orig\n"}

Rmpfr_set_ui($mpfr, 24690, GMP_RNDN);

Rmpfi_fr_div($foo1, $mpfr, $foo1);

if($foo1 == 2) {$ok .= 'g'}
else {warn "9g: $foo1 != 2\n"}

Rmpfi_fr_div($foo1, $mpfr, $foo1);

if($foo1 == $orig) {$ok .= 'h'}
else {warn "9h: $foo1 != $orig\n"}

if($ok eq 'abcdefgh') {print "ok 9\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 9\n";
}

################################### TEST 10

if($have_gmpq) {
  my $gmp = Math::GMPq->new('24690');
  Rmpfi_q_div($foo1, $gmp, $foo1);

  if($foo1 == 2) {print "ok 10\n"}
  else {
    warn "$foo1 != 2\n";
    print "not ok 10\n";
  }

  Rmpfi_q_div($foo1, $gmp, $foo1);
}
else {
  warn "Skipping test 10 - no Math::GMPq\n";
  print "ok 10\n";
}

################################### TEST 11

if($have_gmpz) {
  my $gmp = Math::GMPz->new(-24690);
  Rmpfi_z_div($foo1, $gmp, $foo1);

  if($foo1 == -2) {print "ok 11\n"}
  else {
    warn "$foo1 != -2\n";
    print "not ok 11\n";
  }

  Rmpfi_z_div($foo1, $gmp, $foo1);
}
else {
  warn "Skipping test 11 - no Math::GMPz\n";
  print "ok 11\n";
}

################################### TEST 12

if($have_gmp) {
  my $gmp = Math::GMP->new(24690);
  Rmpfi_z_div($foo1, $gmp, $foo1);

  if($foo1 == 2) {print "ok 12\n"}
  else {
    warn "$foo1 != 2\n";
    print "not ok 12\n";
  }

  Rmpfi_z_div($foo1, $gmp, $foo1);
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

################################### TEST 14

if($foo1 != 12346) {print "ok 14\n"}
else {
  warn "14: $foo1 == 12346\n";
  print "not ok 14\n";
}

#print $foo1, "\n";
