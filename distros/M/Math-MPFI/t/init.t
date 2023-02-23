use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..12\n";

my ($have_gmpq, $have_gmpz, $have_gmp) = (0, 0, 0);
my ($mpq, $mpz, $gmp);
my $quad;
my $double = 0.1;
my $si = -12345;
my $ui = ~0;
my $prec = 65;
Rmpfi_set_default_prec($prec);

eval{require Math::GMPq;};
unless($@) {$have_gmpq = 1}

eval{require Math::GMPz;};
unless($@) {$have_gmpz = 1}

eval{require Math::GMP;};
unless($@) {$have_gmp = 1}

########################## TEST 1

my $ok = '';

if(Rmpfi_get_default_prec() == Rmpfr_get_default_prec()) {$ok .= 'a'}
else {warn "Math::MPFR and Math::MPFI default precisions do not match\n"}

if(Rmpfi_get_default_prec() == $prec) {$ok .= 'b'}
else {warn "Expected Math::MPFI default precisions of: $prec\nGot: ", Rmpfi_get_default_prec(), "\n"}

if($ok eq 'ab') {print "ok 1\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 1\n";
}

########################## TEST 2

$ok = '';

my $foo = Rmpfi_init2($prec + 11);

if(Rmpfi_get_prec($foo) == $prec + 11) {$ok .= 'a'}
else {
  my $expected = $prec + 11;
  warn "\n Expected: $expected\nGot: ", Rmpfi_get_prec($foo), "\n";
}

undef $foo;

$foo = Rmpfi_init();

if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
else {
  warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
}

if($ok eq 'ab') {print "ok 2\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 2\n";
}

########################## TEST 3

undef $foo;
my ($tri, $mpfr, $cmp);
$ok = '';

($foo, $tri) = Rmpfi_init_set_str('1@-1', 10);
$mpfr = Math::MPFR->new('1@-1');

if($tri) {
   warn $tri == 1 ? "\nThe input is incorrect\n" : $tri == -1 ? "\nAn internal overflow has occurred\n"
                                                              : "\nUnknown Error\n";
}
else {$ok .= 'a'}

if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
else {
  warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
}

$cmp = Rmpfi_cmp_fr($foo, $mpfr);

if($cmp) {
  warn "\nComparing \$foo and \$mpfr, expected: 0\nGot: $cmp\n";
}
else {$ok .= 'c'}

if($ok eq 'abc') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

########################## TEST 4

undef($foo);
$ok = '';

($foo, $quad) = Rmpfi_init_set_fr($mpfr);

if($quad != 0) {
   warn "Rmpfi_init_set_fr() returned $quad\n";
}
else {$ok .= 'a'}

if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
else {
  warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
}

$cmp = Rmpfi_cmp_fr($foo, $mpfr);

if($cmp) {
  warn "\nComparing \$foo and \$mpfr, expected: 0\nGot: $cmp\n";
}
else {$ok .= 'c'}

if($ok eq 'abc') {print "ok 4\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 4\n";
}

########################## TEST 5

if($have_gmpq) {
  undef($foo);
  $ok = '';
  $mpq = Math::GMPq->new('1/10');

  ($foo, $quad) = Rmpfi_init_set_q($mpq);

if($quad != 3) {
   warn "Rmpfi_init_set_q() returned $quad\n";
}
  else {$ok .= 'a'}

  if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
  else {
    warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
  }

  $cmp = Rmpfi_cmp_q($foo, $mpq);

  if($cmp) {
    warn "\nComparing \$foo and \$mpq, expected: 0\nGot: $cmp\n";
  }
  else {$ok .= 'c'}

  if($ok eq 'abc') {print "ok 5\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 5\n";
  }
}
else {
  warn "Skipping test 5 - no Math::GMPq\n";
  print "ok 5\n";
}

########################## TEST 6

if($have_gmpz) {
  undef($foo);
  $ok = '';
  $mpz = Math::GMPz->new(12345);

  ($foo, $quad) = Rmpfi_init_set_z($mpz);

if($quad != 0) {
   warn "Rmpfi_init_set_z() returned $quad\n";
}
  else {$ok .= 'a'}

  if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
  else {
    warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
  }

  $cmp = Rmpfi_cmp_z($foo, $mpz);

  if($cmp) {
    warn "\nComparing \$foo and \$mpz, expected: 0\nGot: $cmp\n";
  }
  else {$ok .= 'c'}

  if($ok eq 'abc') {print "ok 6\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 6\n";
  }
}
else {
  warn "Skipping test 6 - no Math::GMPz\n";
  print "ok 6\n";
}

########################## TEST 7

if($have_gmp) {
  undef($foo);
  $ok = '';
  $gmp = Math::GMP->new(12345);

  ($foo, $quad) = Rmpfi_init_set_z($gmp);

if($quad != 0) {
   warn "Rmpfi_init_set_z() returned $quad\n";
}
  else {$ok .= 'a'}

  if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
  else {
    warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
  }

  $cmp = Rmpfi_cmp_z($foo, $gmp);

  if($cmp) {
    warn "\nComparing \$foo and \$gmp, expected: 0\nGot: $cmp\n";
  }
  else {$ok .= 'c'}

  if($ok eq 'abc') {print "ok 7\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 7\n";
  }
}
else {
  warn "Skipping test 7 - no Math::GMP\n";
  print "ok 7\n";
}

########################## TEST 8

undef($foo);
$ok = '';

($foo, $quad) = Rmpfi_init_set_d($double);

if($quad != 0) {
   warn "Rmpfi_init_set_d() returned $quad\n";
}
else {$ok .= 'a'}

if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
else {
  warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
}

$cmp = Rmpfi_cmp_d($foo, $double);

if($cmp) {
  warn "\nComparing \$foo and \$double, expected: 0\nGot: $cmp\n";
}
else {$ok .= 'c'}

if($ok eq 'abc') {print "ok 8\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 8\n";
}

########################## TEST 9

undef($foo);
$ok = '';

($foo, $quad) = Rmpfi_init_set_si($si);

if($quad != 0) {
   warn "Rmpfi_init_set_si() returned $quad\n";
}
else {$ok .= 'a'}

if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
else {
  warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
}

$cmp = Rmpfi_cmp_si($foo, $si);

if($cmp) {
  warn "\nComparing \$foo and \$si, expected: 0\nGot: $cmp\n";
}
else {$ok .= 'c'}

if($ok eq 'abc') {print "ok 9\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 9\n";
}

########################## TEST 10
undef($foo);
$ok = '';

($foo, $quad) = Rmpfi_init_set_ui($ui);

if($quad != 0) {
   warn "Rmpfi_init_set_ui() returned $quad\n";
}
else {$ok .= 'a'}

if(Rmpfi_get_prec($foo) == $prec && ref($foo) =~ /Math::MPFI/) {$ok .= 'b'}
else {
  warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo), "\n";
}

$cmp = Rmpfi_cmp_ui($foo, $ui);

if($cmp) {
  warn "\nComparing \$foo and \$ui, expected: 0\nGot: $cmp\n";
}
else {$ok .= 'c'}

if($ok eq 'abc') {print "ok 10\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 10\n";
}

########################## TEST 11

my $foo2;
$ok = '';

($foo2, $quad) = Rmpfi_init_set($foo);

if($quad != 0) {
   warn "Rmpfi_init_set() returned $quad\n";
}
else {$ok .= 'a'}

if(Rmpfi_get_prec($foo2) == $prec && ref($foo2) =~ /Math::MPFI/) {$ok .= 'b'}
else {
  warn "\n Expected: $prec\nGot: ", Rmpfi_get_prec($foo2), "\n";
}

$cmp = Rmpfi_cmp($foo2, $foo);

if($cmp) {
  warn "\nComparing \$foo2 and \$foo, expected: 0\nGot: $cmp\n";
}
else {$ok .= 'c'}

if($ok eq 'abc') {print "ok 11\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 11\n";
}

##########################

$ok = '';

undef $foo;

$foo = Rmpfi_init_nobless();
if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'a'}
Rmpfi_clear($foo);
undef $foo;

$foo = Rmpfi_init2_nobless($prec + 21);
if(Rmpfi_get_prec($foo) == ($prec + 21) && ref($foo) !~ /Math::MPFI/) { $ok .= 'b'}
Rmpfi_clear($foo);
undef $foo;

($foo, $quad) = Rmpfi_init_set_ui_nobless(17);
if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'c'}
Rmpfi_clear($foo);
undef $foo;

($foo, $quad) = Rmpfi_init_set_si_nobless(-17);
if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'd'}
Rmpfi_clear($foo);
undef $foo;

($foo, $quad) = Rmpfi_init_set_d_nobless(17.123);
if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'e'}
Rmpfi_clear($foo);
undef $foo;

if($have_gmp) {
  ($foo, $quad) = Rmpfi_init_set_z_nobless(Math::GMP->new(23));
  if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'f'}
  Rmpfi_clear($foo);
  undef $foo;
}
else {
  warn "Skipping 12e - no Math::GMP\n";
  $ok .= 'f';
}

if($have_gmpz) {
  ($foo, $quad) = Rmpfi_init_set_z_nobless(Math::GMPz->new(23));
  if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'g'}
  Rmpfi_clear($foo);
  undef $foo;
}
else {
  warn "Skipping 12g - no Math::GMPz\n";
  $ok .= 'g';
}

if($have_gmpq) {
  ($foo, $quad) = Rmpfi_init_set_q_nobless(Math::GMPq->new(23));
  if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'h'}
  Rmpfi_clear($foo);
  undef $foo;
}
else {
  warn "Skipping 12h - no Math::GMPq\n";
  $ok .= 'h';
}

($foo, $quad) = Rmpfi_init_set_fr_nobless(Math::MPFR->new(17.123));
if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'i'}
  Rmpfi_clear($foo);
  undef $foo;

($foo, $quad) = Rmpfi_init_set_nobless($foo2);
if(Rmpfi_get_prec($foo) == $prec && ref($foo) !~ /Math::MPFI/) { $ok .= 'j'}
Rmpfi_clear($foo);
undef $foo;
undef $foo2;

if($ok eq 'abcdefghij') {print "ok 12\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 12\n";
}


