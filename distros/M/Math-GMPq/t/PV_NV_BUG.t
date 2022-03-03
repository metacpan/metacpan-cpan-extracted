# Check that scalars that are (or might be)
# both POK and NOK are being handled correctly.

use strict;
use warnings;

use Math::GMPq qw(:mpq);
*_ITSA = \&Math::GMPq::_itsa;

use Test::More;

warn "\n GMPQ_PV_NV_BUG set to ", GMPQ_PV_NV_BUG, "\n";
warn " The string 'nan' apparently numifies to zero\n"
  if 'nan' + 0 == 0;

# Check that both the perl environment and the XS
# environment agree on whether the problem is present.
cmp_ok(GMPQ_PV_NV_BUG, '==', Math::GMPq::_has_pv_nv_bug(),
       "Perl environment and XS environment agree");       # Test 1

my $nv_1 = 1.5;
my $s    = "$nv_1";

cmp_ok(_ITSA($nv_1), '==', 3, "NV slot will be used");     # Test 2

cmp_ok(Math::GMPq->new($nv_1), '==', '3/2',
       "NV slot was used by new()");                       # Test 3

cmp_ok(Math::GMPq->new(1) * $nv_1, '==', '3/2',
       "NV slot was used by overload_mul()");              # Test 4

my $nv_2 = '1.7';

if($nv_2 > 1) {      # True

  cmp_ok(_ITSA($nv_2), '==', 4, "PV slot will be used");   # Test 5

  eval {my $q = Math::GMPq->new($nv_2);};
  like($@, qr/^String supplied to Rmpq_set_str function is not a valid/,
       "PV slot was used by new()");                       # Test 6

 eval {my $q = Math::GMPq->new(3) * $nv_2;};
  like($@, qr/^Invalid string supplied to Math::GMPq::overload_mul/,
       "PV slot was used by overload_mul()");              # Test 7
}


my $nv_3 = '123' x 20;

if($nv_3 > 1) {    # True

   cmp_ok(_ITSA($nv_3), '==', 4, "PV slot will be used");   # Test 8

   cmp_ok(Math::GMPq->new($nv_3), '==', '123' x 20,
          "PV slot was used by new()");                     # Test 9

   cmp_ok(Math::GMPq->new(2) * $nv_3, '==', '246' x 20,
         "PV slot was used by overload_mul()");             # Test 10

}

my $nv_sqrt = sqrt(2);
my $t = "$nv_sqrt";

# The next 4 tests should fail if the value
# in the PV slot of $nv_sqrt is used.

cmp_ok(Math::GMPq->new(1) * $nv_sqrt, '==', sqrt(2),
       "overload_mul() uses value in NV slot");            # Test 11

cmp_ok(Math::GMPq->new(0) + $nv_sqrt, '==', sqrt(2),
       "overload_add() uses value in NV slot");            # Test 12

cmp_ok(Math::GMPq->new(0) - $nv_sqrt, '==', -(sqrt(2)),
       "overload_sub() uses value in NV slot");            # Test 13

cmp_ok(Math::GMPq->new(sqrt 2) / $nv_sqrt, '==', 1.0,
       "overload_div() uses value in NV slot");            # Test 14

done_testing();
