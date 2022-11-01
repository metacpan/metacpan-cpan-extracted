use strict;
use warnings;
use Math::GMPq qw(:mpq);

print "1..3\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my $ui = 12345679;
my $mpz;
eval {require Math::GMPz;};
if(!$@) {$mpz = Math::GMPz->new($ui)}

if(!$mpz) {
  eval {require Math::GMP;};
  if(!$@) {$mpz = Math::GMP->new($ui)}
}

my @s;

$s[0] = qgmp_randinit_default();
qgmp_randseed_ui($s[0], $ui);
$s[1] = qgmp_randinit_mt();
qgmp_randseed_ui($s[1], $ui - 1);
if($mpz) {
  $s[2] = qgmp_randinit_lc_2exp($mpz, $ui - 5, 24);
  qgmp_randseed_ui($s[2], $ui + 3);
}
else {$s[2] = qgmp_randinit_set($s[1])}
$s[3] = qgmp_randinit_lc_2exp_size(104);
qgmp_randseed_ui($s[3], $ui - 234);
$s[4] = qgmp_randinit_set($s[3]);

my $ok = 1;
for(0 .. 100) {
  my $x = qgmp_urandomb_ui($s[$_ % 5], 15);
  if($x >= 2 ** 15) {
    warn "$x is out of range\n";
    $ok = 0;
  }
}

if($ok) {print "ok 1\n"}
else {print "not ok 1\n"}

$ok = 1;
for(0 .. 100) {
  my $x = qgmp_urandomm_ui($s[$_ % 5], $ui);
  if($x >= $ui) {
    warn "$x is greater than $ui\n";
    $ok = 0;
  }
}

if($ok) {print "ok 2\n"}
else {print "not ok 2\n"}

eval {my $x = qgmp_urandomb_ui($s[0], $ui);};
if($@ =~ /In Math::GMPq::Random::Rgmp_urandomb_ui/) {print "ok 3\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 3\n";
}
