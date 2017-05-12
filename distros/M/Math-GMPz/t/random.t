use strict;
use warnings;
use Math::GMPz qw(:mpz);

print "1..2\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $str = '';
my $s = '';

for(1..64) {$str .= int(rand(2))}

for(1 .. 70) {$s .= int(rand(2))}

my $seed = Rmpz_init_set_str($str, 2);
my $state = rand_init($seed);
my $max = Rmpz_init_set_str($s, 2);

my @r = ();

for(1..100) {push @r, Rmpz_init2(75)}

my $ok = 1;
Rmpz_urandomm(@r, $state, $max, 100);
for(@r) {
   if(Rmpz_cmp_ui($_, 2 ** 30) <= 0 || Rmpz_cmp($_, $max) >= 0) {$ok = 0}
   }

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}

$ok = 1;
Rmpz_urandomb(@r, $state, 200, 100);
for(@r) {
   if(Rmpz_cmp($_, $max) <= 0) {$ok = 0}
   }

if($ok) {print "ok 2\n"}
else {print "not ok 2\n"}

rand_clear($state);
