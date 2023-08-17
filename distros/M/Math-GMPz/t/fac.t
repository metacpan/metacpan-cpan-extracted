use strict;
use warnings;
use Math::GMPz qw(:mpz);

print "1..3\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $rop = Math::GMPz->new();

if(Math::GMPz::__GNU_MP_VERSION > 5 || (Math::GMPz::__GNU_MP_VERSION == 5 && Math::GMPz::__GNU_MP_VERSION_MINOR >= 1)) {

  Rmpz_2fac_ui($rop, 8);
  if($rop == 384) {print "ok 1\n"}
  else {
    warn "\nExpected 384\nGot $rop\n";
    print "not ok 1\n";
  }

  Rmpz_mfac_uiui($rop, 10, 4);
  if($rop == 120) {print "ok 2\n"}
  else {
    warn "\nExpected 120\nGot $rop\n";
    print "not ok 2\n";
  }

  Rmpz_primorial_ui($rop, 12);
  if($rop == 2310) {print "ok 3\n"}
  else {
    warn "\nExpected 2310\nGot $rop\n";
    print "not ok 3\n";
  }

}
else {
  warn "\nUsing gmp-", Math::GMPz::gmp_v(), " - Rmpz_2fac_ui, Rmpz_mfac_uiui and Rmpz_primorial_ui not implemented\n";

  eval {Rmpz_2fac_ui($rop, 4);};
  if($@ =~ /Rmpz_2fac_ui/) {print "ok 1\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 1\n";
  }

  eval {Rmpz_mfac_uiui($rop, 3, 3);};
  if($@ =~ /Rmpz_mfac_uiui/) {print "ok 2\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 2\n";
  }

  eval {Rmpz_primorial_ui($rop, 4);};
  if($@ =~ /Rmpz_primorial_ui/) {print "ok 3\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 3\n";
  }

}
