use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..8\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my ($have_mpz, $have_gmp) = (0, 0);
my $c = Rmpfr_init();
my $check2 = Rmpfr_init();
my $z;

Rmpfr_set_default_prec(300);

eval{require Math::GMP};
if(!$@) {$have_gmp = 1}

eval{require Math::GMPz};
if(!$@) {$have_mpz = 1}

if($have_gmp || $have_mpz) {
  if($have_gmp) {$z = Math::GMP->new("1123")}
  else {$z = Math::GMPz->new("1123")}
  Rmpfr_set_z($c, $z, GMP_RNDN);
  if($c == 1123 && Math::MPFR::get_refcnt($z) == 1
     && (Math::MPFR::get_package_name($z) eq "Math::GMP"
         || Math::MPFR::get_package_name($z) eq "Math::GMPz")) {print "ok 1\n"}
  else {print "not ok 1\n"}
}
else {
  warn "Skipping test 1 - no Math::GMP or Math::GMPz\n";
  print "ok 1\n";
}

if($have_gmp || $have_mpz) {
  Rmpfr_set_prec($c, 53);
  Rmpfr_set_ui($c, 2, GMP_RNDN);
  if($have_gmp) {$z = Math::GMP->new(0)}
  else {$z = Math::GMPz->new(0)}
  my $exp = Rmpfr_get_z_exp($z, $c);
  if($exp == -51 && "$z" eq '4503599627370496'
     && (Math::MPFR::get_package_name($z) eq "Math::GMP"
         || Math::MPFR::get_package_name($z) eq "Math::GMPz")) {print "ok 2\n"}
  else {print "not ok 2\n"}
}
else {
  warn "Skipping test 2 - no Math::GMP or Math::GMPz\n";
  print "ok 2\n";
}

if($have_gmp || $have_mpz) {
  if($have_gmp) {$z = Math::GMP->new(11234)}
  else {$z = Math::GMPz->new(11234)}
  Rmpfr_set_prec($c, 300);
  Rmpfr_set_ui($c, 237, GMP_RNDN);
  Rmpfr_div_z($check2, $c, $z, GMP_RNDN);
  Rmpfr_mul_z($check2, $check2, $z, GMP_RNDN);
  if($check2 - $c > -0.000001
     && $check2 - $c < 0.000001
     && (Math::MPFR::get_package_name($z) eq "Math::GMP"
         || Math::MPFR::get_package_name($z) eq "Math::GMPz")) {print "ok 3\n"}
  else {print "not ok 3\n"}
}
else {
  warn "Skipping test 3 - no Math::GMP or Math::GMPz\n";
  print "ok 3\n";
}

if($have_gmp || $have_mpz) {
  if($have_gmp) {$z = Math::GMP->new("1123")}
  else {$z = Math::GMPz->new("1123")}
  my ($c, $cmp) = Rmpfr_init_set_z($z, GMP_RNDN);
  if($c == 1123 && Math::MPFR::get_refcnt($z) == 1
     && (Math::MPFR::get_package_name($z) eq "Math::GMP"
         || Math::MPFR::get_package_name($z) eq "Math::GMPz")) {print "ok 4\n"}
  else {print "not ok 4\n"}
}
else {
  warn "Skipping test 4 - no Math::GMP or Math::GMPz\n";
  print "ok 4\n";
}

if($have_gmp || $have_mpz) {
  if($have_gmp) {$z = Math::GMP->new(17)}
  else {$z = Math::GMPz->new(17)}
  Rmpfr_set($check2, $c, GMP_RNDN);

  Rmpfr_add_z($c, $c, $z, GMP_RNDN);
  Rmpfr_sub_z($c, $c, $z, GMP_RNDN);

  if($c == $check2) {print "ok 5\n"}
  else {print "not ok 5\n"}
}
else {
  warn "Skipping test 5 - no Math::GMP or Math::GMPz\n";
  print "ok 5\n";
}

my $op1 = Math::MPFR->new(123);
my $op2 = Math::MPFR->new(456);
my $rop = Math::MPFR->new();

Rmpfr_dim($rop, $op1, $op2, GMP_RNDN);
if($rop == 0) {print "ok 6\n"}
else {
   warn "\n\$rop: $rop\n";
   print "not ok 6\n";
}

Rmpfr_dim($rop, $op2, $op1, GMP_RNDN);
if($rop == 333) {print "ok 7\n"}
else {
   warn "\n\$rop: $rop\n";
   print "not ok 7\n";
}

if($have_gmp || $have_mpz) {
  if((MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3) {
    my $gmp;
    my $fr = Math::MPFR->new(10.25);
    if($have_gmp) {$gmp = Math::GMP->new(5)}
    else {$gmp = Math::GMPz->new(5)}
    my $ok = '';

    Rmpfr_z_sub($fr, $gmp, $fr, GMP_RNDN);
    if($fr == -5.25) {print "ok 8\n"}
    else {print "not ok 8\n"}
  }
  else {
    my $z;
    my $fr = Math::MPFR->new(10.25);
    if($have_gmp) {$z =  Math::GMP->new(5)}
    else {$z = Math::GMPz->new(5)}
    eval{Rmpfr_z_sub($fr, $z, $fr, GMP_RNDN);};
    if($@ =~ /Rmpfr_z_sub not implemented/) {print "ok 8\n"}
    else {
      warn "\$\@: $@";
      print "not ok 8\n";
    }
  }
}
else {
  warn "Skipping test 8 - no Math::GMP or Math::GMPz\n";
  print "ok 8\n";
}



