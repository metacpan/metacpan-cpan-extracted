use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..1\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $z = Rmpz_init2(50);

my
$binstring = 'ôW¼+¯·?+ACé??+ÅRHK3V+Ü¦n-¦+üû!é+?k7ß';
Rmpz_import($z, length($binstring), 1, 1, 0, 0, $binstring);
my
 ($order, $size, $endian, $nails) = (1, 1, 0, 0);
my
 $check = Rmpz_export( $order, $size, $endian, $nails, $z);
if($check eq $binstring)
     {print "ok 1\n"}
else {print "not ok 1\n"}

