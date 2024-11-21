use strict;
use warnings;
use Config;
use Math::MPFR qw(:mpfr);

use Test::More;

my($have_gmp, $have_mpz, $have_mpq, $have_mpf) = (0, 0, 0, 0);

eval {require Math::GMP;};
$have_gmp = 1 unless $@;

eval {require Math::GMPz;};
$have_mpz = 1 unless $@;

eval {require Math::GMPq;};
$have_mpq = 1 unless $@;

eval {require Math::GMPf;};
$have_mpf = 1 unless $@;

my $buflen = 32;
my $buf;
my $nv = sqrt(2);

if($Config{nvtype} eq 'double') {
  Rmpfr_sprintf($buf, "%.14g", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'double'");
}

if($Config{nvtype} eq 'long double') {
  Rmpfr_sprintf($buf, "%.14Lg", $nv, $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "sqrt 2 ok for 'long double'");
}

Rmpfr_sprintf($buf, "%s", 'hello world', $buflen);
cmp_ok($buf, 'eq', 'hello world', "'hello world' ok for PV");

if($have_gmp) {
  Rmpfr_sprintf($buf, "%Zd", Math::GMP->new(~0), $buflen);
  cmp_ok($buf, '==', ~0, "Math::GMP: ~0 ok");
}

if($have_mpz) {
  Rmpfr_sprintf($buf, "%Zd", Math::GMPz->new(~0), $buflen);
  cmp_ok($buf, '==', ~0, "Math::GMPz: ~0 ok");
}

if($have_mpq) {
  Rmpfr_sprintf($buf, "%Qd", Math::GMPq->new('19/21'), $buflen);
  cmp_ok($buf, 'eq', '19/21', "Math::GMPq: 19/21 ok");
}

if($have_mpf) {
  Rmpfr_sprintf($buf, "%.14Fg", sqrt(Math::GMPf->new(2)), $buflen);
  cmp_ok($buf, 'eq', '1.4142135623731', "Math::GMPf: sqrt 2 ok");
}


my $fr = Math::MPFR->new($nv);

Rmpfr_sprintf($buf, "%.14RUg", $fr, $buflen);
cmp_ok($buf, 'eq', '1.4142135623731', "Math::MPFR: sqrt 2 ok");

Rmpfr_sprintf($buf, "%.14RDg", $fr, $buflen);
cmp_ok($buf, 'eq', '1.414213562373', "Math::MPFR: sqrt 2 ok");

Rmpfr_sprintf($buf, "%Pd", prec_cast(Rmpfr_get_prec($fr)), $buflen);
cmp_ok($buf, 'eq', '53', "Math::MPFR precision is '53'");

if($Config{nvsize} == 8) {
  Rmpfr_sprintf($buf, "%a", sqrt(2), 32);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%a" correctly');
  Rmpfr_sprintf($buf, "%A", sqrt(2), 32);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%A" correctly');
}
elsif($Config{nvtype} ne '__float128') {
  my $prec_orig = Rmpfr_get_default_prec();
  my $prec = 64;
  if(length(sqrt(2)) > 25) { $prec = 113 }
  Rmpfr_set_default_prec($prec);
  Rmpfr_sprintf($buf, "%La", sqrt(2), 48);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%La" correctly');
  Rmpfr_sprintf($buf, "%LA", sqrt(2), 48);
  cmp_ok(Math::MPFR->new($buf), '==', sqrt(2), 'Rmpfr_sprintf() reads "%LA" correctly');
  Rmpfr_set_default_prec($prec_orig);
}

unless($Config{nvtype} eq '__float128') { # print formatting not supported by mpfr library
  my $fmt_string = $Math::MPFR::NV_properties{'bits'} == 53 ? "%a"
                                                            : "%La";

  my $garbage = $Math::MPFR::NV_properties{'bits'} == 53 ? "  %%a  "
                                                         : "  %%La  ";
  my @check = ();
  my @expected = ();
  my @fmt_strings = ($fmt_string);
  push @fmt_strings, "$fmt_string\n";
  push @fmt_strings, $garbage . $fmt_string;
  push @fmt_strings, $fmt_string . $garbage;
  push @fmt_strings, $garbage . $fmt_string . $garbage;

  for(0..4) {
    my $alt = $fmt_strings[$_];
    $alt =~s/a/A/g;
    push @fmt_strings, $alt;
  }

  #for(@fmt_strings) {print "$_\n";}

  my $fmt_obj = Rmpfr_init2($Math::MPFR::NV_properties{'bits'});
  my $fmt_nv = sqrt(2.0);
  Rmpfr_set_NV($fmt_obj, $fmt_nv, MPFR_RNDN);

  for (@fmt_strings) {
    my $s = $_;
    Rmpfr_sprintf($buf, $s, $fmt_nv, 64);
    push @check, "|$buf|";
  }

  if($Math::MPFR::NV_properties{'bits'} == 53) {
    @expected = (
      "|0x1.6a09e667f3bcdp+0|",
      "|0x1.6a09e667f3bcdp+0\n|",
      "|  %a  0x1.6a09e667f3bcdp+0|",
      "|0x1.6a09e667f3bcdp+0  %a  |",
      "|  %a  0x1.6a09e667f3bcdp+0  %a  |",
      "|0X1.6A09E667F3BCDP+0|",
      "|0X1.6A09E667F3BCDP+0\n|",
      "|  %A  0X1.6A09E667F3BCDP+0|",
      "|0X1.6A09E667F3BCDP+0  %A  |",
      "|  %A  0X1.6A09E667F3BCDP+0  %A  |",
                 );
    for my $index(0..9) { cmp_ok($check[$index], 'eq', $expected[$index], "\$check[$index] eq \$expected[$index]") }
  }
  else {
   # Correct 64-bit precision "%a" formatting of sqrt(2) can be either:
   # 0x1.6a09e667f3bcc908p+0 or 0xb.504f333f9de6484p-3 or 0x5.a827999fcef3242p-2 or 0x2.d413cccfe779921p-1
   #
   # Correct 113-bit precision "%a" formatting of sqrt(2) produces:
   # 0x1.6a09e667f3bcc908b2fb1366ea95p+0

   my $expect1 = "0x1.6a09e667f3bcc908p+0";
   my $expect2 = "0x2.d413cccfe779921p-1";
   my $expect3 = "0x5.a827999fcef3242p-2";
   my $expect4 = "0xb.504f333f9de6484p-3";
   my $expect5 = "0x1.6a09e667f3bcc908b2fb1366ea95p+0";
   my ($insert, $INSERT);

   if($check[0]    =~ /0x1\.6a09e667f3bcc908p\+0/) { $insert = $expect1 }
   elsif($check[0] =~ /0x2\.d413cccfe779921p\-1/)  { $insert = $expect2 }
   elsif($check[0] =~ /0x5\.a827999fcef3242p\-2/)  { $insert = $expect3 }
   elsif($check[0] =~ /0xb\.504f333f9de6484p\-3/)  { $insert = $expect4 }
   elsif($check[0] =~ /0x1\.6a09e667f3bcc908b2fb1366ea95p\+0/)  { $insert = $expect5 }
   else {
     # If we haven't already found a valid representation of sqrt(2), then a FAIL should be reported.
     cmp_ok($check[0], 'eq', 'satisfactory value found', "Looking for a valid representation of sqrt(2)");
   }

   $INSERT = uc($insert);

   #  print "$_\n" for @check;

   my @expected = (
        "|${insert}|",
        "|${insert}\n|",
        "|  %La  ${insert}|",
        "|${insert}  %La  |",
        "|  %La  ${insert}  %La  |",
        "|${INSERT}|",
        "|${INSERT}\n|",
        "|  %LA  ${INSERT}|",
        "|${INSERT}  %LA  |",
        "|  %LA  ${INSERT}  %LA  |",
                 );

    for my $index(0..9) { cmp_ok($check[$index], 'eq', $expected[$index], "\$check[$index] eq \$expected[$index]") }
  }
}

done_testing();
