use warnings;
use strict;
use Math::GMPq qw(:mpq);
use Config;

print "1..1\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

my $_64 = Math::GMPq::_has_longlong();

if($_64) {print "Using 64-bit integer\n"}
else {print "Using 32-bit integer\n"}
my $ok;

if($_64) {
  use integer;
  my $int1 = 2 ** 57 + 12345;
  my $int2 = $int1 - 1;
  my $int3 = $int1 + 1;

  if($int1 == 144115188075868217 &&
     $int2 == 144115188075868216 &&
     $int3 == 144115188075868218) {$ok = 'a'}

  my $p = Rmpq_init();
  my $q = Rmpq_init();
  my $r = Rmpq_init();
  my $s = Rmpq_init();

  Rmpq_set_str($p,"$int1/1", 10);
  Rmpq_set_str($q, "$int2/1", 10);
  Rmpq_set_str($r, "$int3/1", 10);

  Rmpq_canonicalize($p);
  Rmpq_canonicalize($q);
  Rmpq_canonicalize($r);
  Rmpq_canonicalize($s);

  Rmpq_set($s, $p);
  $s -= 1;

  if($s == $q &&
     $s >= $q &&
     $s <= $q &&
     ($s <=> $q) == 0 &&
     $p == 144115188075868217 &&
     $p == "144115188075868217" &&
     $p == 2 ** 57 + 12345 &&
     $p < $r &&
     $p > $q &&
     $q + $r == $p * 2 &&
     !($p + ($p *- 1))) {$ok .= 'b'}

  my $uintmax = ~0;
  my $mpq1 = Math::GMPq->new($uintmax);
  my $mpq2 = Math::GMPq::new($uintmax);

  if($mpq1 == $mpq2 &&
     $mpq2 == $uintmax &&
     $uintmax == $mpq1) {$ok .= 'c'}

  if($ok eq 'abc') {print "ok 1\n"}
  else {print "not ok 1 $ok\n"}

}

else {
  my $uintmax = ~0;
  my $mpq1 = Math::GMPq->new($uintmax);
  my $mpq2 = Math::GMPq::new($uintmax);

  if($mpq1 == $mpq2 &&
     $mpq2 == $uintmax &&
     $uintmax == $mpq1){print "ok 1\n"}
  else {print "not ok 1\n"}
}
