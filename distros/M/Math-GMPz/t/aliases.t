use Math::GMPz qw(:mpz);

use strict;
use warnings;

$| = 1;
print "1..6\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $rop1 = Math::GMPz->new();
my $rop2 = Math::GMPz->new();
my $six = Math::GMPz->new(6);
my $ten = Math::GMPz->new(10);
my $three = Math::GMPz->new(3);
my $eleven = Math::GMPz->new(11);

Rmpz_div($rop1, $six, $three);

if($rop1 == 2) {print "ok 1\n"}
else {
  warn "\$rop1: $rop1\n";
  print "not ok 1\n";
}

Rmpz_divmod($rop1, $rop2, $ten, $three);

if($rop1 == 3 && $rop2 == 1) {print "ok 2\n"}
else {
  warn "\$rop1: $rop1\n\$rop2: $rop2\n";
  print "not ok 2\n";
}

my $mod = Rmpz_div_ui($rop1, $ten, 4);
if($mod == 2 && $rop1 == 2) {print "ok 3\n"}
else {
  warn "\$mod: $mod\n\$rop1: $rop1\n";
  print "not ok 3\n";
}

$mod = Rmpz_divmod_ui($rop1, $rop2, $six, 10);
if($mod == 6 && $rop1 == 0 && $rop2 == 6) {print "ok 4\n"}
else {
  warn "\$mod: $mod\n\$rop1: $rop1\n\$rop2: $rop2\n";
  print "not ok 4\n";
}

Rmpz_div_2exp($rop1, $ten, 1);

if($rop1 == 5) {print "ok 5\n"}
else {
  warn "\$rop1: $rop1\n";
  print "not ok 5\n";
}

Rmpz_mod_2exp($rop1, $eleven, 2);

if($rop1 == 3) {print "ok 6\n"}
else {
  warn "\$rop1: $rop1\n";
  print "not ok 6\n";
}
