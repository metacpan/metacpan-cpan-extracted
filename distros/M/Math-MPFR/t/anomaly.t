
# Here we check that a (somewhat anomalous) behaviour that can
# arise when strings are involved in overloaded comparisons with
# Math::MPFR objects ('==', '!=', '<', '>', '<=', '>=' and '<=>')
# is as expected.
# Some of these tests require Math::GMPz.

use strict;
use warnings;
use Math::MPFR;

use Config;
use Test::More;

my $have_mpz = 0;
eval {require Math::GMPz;};
$have_mpz++ unless $@;

if($Config{ivsize} == 8) {
   my $f = Math::MPFR->new(2 ** 64); # 0x1p+63
   my $i =  ~0; # == 18446744073709551615, 1 less than 2 ** 64

   cmp_ok($f, '>',   $i,  '2**64 >   18446744073709551615  (IV)'); # $i is evaluated to its full (64-bit) precision.
   cmp_ok($f, '==', "$i", '2**64 == "18446744073709551615" (PV)'); # "$i" is rounded to 53-bit precision.

   if($have_mpz) {
     # In order to have the string "$i" evaluated to its full 64-bit precision:
     cmp_ok($f, '>', Math::GMPz->new("$i"), '2**64 >  "18446744073709551615" (mpz)');
   }
}

if($Config{nvsize} > 8) {

  my $f = Math::MPFR->new(2 ** 63);       # 9.223372036854775808e18
  my $s = sprintf "%.20e", (2 ** 63) + 1; # 9.223372036854775809e18

  cmp_ok(  $f, '==', $s,     '2**63 == (2**63)+1 - RHS is PV');       # $s, (POK):             treated as PV

  if($Config{ivsize} < 8) {
    cmp_ok($f, '<',  $s + 0, '2**63 <  (2**63)+1 - RHS is NV');       # '$s + 0', (NOK):       treated as NV
    cmp_ok($f, '==', $s,     '2**63 == (2**63)+1 - RHS is again PV'); # $s, (now POK and NOK): treated as PV
  }
  else {
    cmp_ok($f, '<',  $s + 0, '2**63 <  (2**63)+1 - RHS is IV');       # '$s + 0', (IOK):       treated as IV
    cmp_ok($f, '<', $s,      '2**63 <  (2**63)+1 - RHS is still IV'); # $s, (now POK and IOK): treated as IV
  }

}

my $f = Math::MPFR->new(2 ** 70); # 1180591620717411303424
my $s = '1180591620717411303423'; # 1 less than 2 ** 70;


cmp_ok($f, '==', $s, '2**70 == (2**70)-1 - RHS is PV'); # Value of $s is rounded to 53-bit precision.

if($have_mpz) {
  # $s is evaluated to its full (70-bit) precision:
  cmp_ok($f, '>',  Math::GMPz->new($s), '2**70 >  (2**70)-1 - RHS is mpz');
}

done_testing();



