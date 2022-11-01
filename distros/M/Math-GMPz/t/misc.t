use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..5\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $n2 =  '1010101010101010000000000000000000000111111110001010';

my $q = Rmpz_init_set_str( $n2, 2);
my $num = Rmpz_init_set_str($n2 x 3, 2);

if(!Rmpz_fits_ulong_p($num)
   &&
   !Rmpz_fits_slong_p($num))
     {print "ok 1\n"}
else {print "not ok 1\n"}

if(!Rmpz_fits_uint_p($num)
   &&
   !Rmpz_fits_sint_p($num))
     {print "ok 2\n"}
else {print "not ok 2\n"}

if(!Rmpz_fits_ushort_p($q)
   &&
   !Rmpz_fits_sshort_p($q))
     {print "ok 3\n"}
else {
   warn "\n$q fits ushort: ", Rmpz_fits_ushort_p($q), "\n";
   warn "$q fits sshort: ", Rmpz_fits_sshort_p($q), "\n";
   print "not ok 3\n";
}

if(Rmpz_even_p($q)
   &&
   !Rmpz_odd_p($q))
     {print "ok 4\n"}
else {print "not ok 4\n"}

# If limbs are 32 bit, there will be 2
# If limbs are 64 bit, there will be 1

if((Rmpz_size($q) == 2 || Rmpz_size($q) == 1)
   &&
   Rmpz_sizeinbase($q, 2) == 52)
     {print "ok 5\n"}
else {print "not ok 5\n"}
