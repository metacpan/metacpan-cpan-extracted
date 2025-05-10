# As of Math-GMPq-0.65, Rmpq_set_str() has been further
# extended to allow for setting of fractional strings,
# even though mpq_set_str() does not accommodate this.
# Here, we do some testing of this latest "extension".

use strict; use warnings;
use Math::GMPq qw(:mpq);

use Test::More;

for(1 .. 20) {

  my $num = rand(10000);
  next if $num =~ /e/i;
  my $den = rand(100000);
  next if $den =~ /e/i;

  my $s1 = rand;
  next if $s1 =~ /e/i;
  my $s2 = rand;
  next if $s2 =~ /e/i;
  my($q1, $q2, $inv1, $inv2) = (Rmpq_init(), Rmpq_init(), Rmpq_init(), Rmpq_init());

  for my $base(10 .. 20) {
    Rmpq_set_str($q1, "$num", $base);
    Rmpq_set_str($q2, "$den", $base);
    Rmpq_inv($inv1, $q1);
    Rmpq_inv($inv2, $q2);

    my $q_1 = $q1 / $q2;
    my $q_2 = $q2 / $q1;
    cmp_ok($q_1 * $q2, '==', $q1, '1: inverts as expected');
    cmp_ok($q_2 * $q1, '==', $q2, '2: inverts as expected');

  }

  for my $base(10 .. 20) {
    Rmpq_set_str($q1, "$s1", $base);
    Rmpq_set_str($q2, "$s2", $base);
    Rmpq_inv($inv1, $q1);
    Rmpq_inv($inv2, $q2);

    my $q_1 = $q1 / $q2;
    my $q_2 = $q2 / $q1;
    cmp_ok($q_1 * $q2, '==', $q1, '1: inverts as expected');
    cmp_ok($q_2 * $q1, '==', $q2, '2: inverts as expected');

  }
}

my $str = '89.1234567';
my $q = Rmpq_init();

for my $base (10 .. 62) {
 Rmpq_set_str($q, $str, $base);
 my ($b1, $b2, $b3, $b4, $b5, $b6, $b7) =
    ($base, $base ** 2, $base ** 3, $base ** 4, $base ** 5, $base ** 6, $base ** 7);
 cmp_ok($q, '==',   Math::GMPq->new(($base * 8) + 9)
                  + Math::GMPq->new("1/$b1")
                  + Math::GMPq->new("2/$b2")
                  + Math::GMPq->new("3/$b3")
                  + Math::GMPq->new("4/$b4")
                  + Math::GMPq->new("5/$b5")
                  + Math::GMPq->new("6/$b6")
                  + Math::GMPq->new("7/$b7"), "correct calculation for base $base");
}

my $base = 10;
Rmpq_set_str($q, '111.2345@2', $base);
cmp_ok($q, '==', Math::GMPq->new('1112345/100'), '111.2345@2 ok');
Rmpq_set_str($q, '111.2345@-3', $base);
cmp_ok($q, '==', Math::GMPq->new('1112345/10000000'), '111.2345@-3 ok');

Rmpq_set_str($q, '1@7', 16);
cmp_ok($q, '==', 0x10000000, '1@8, base 16 ok');
Rmpq_set_str($q, '1@-8', 16);
cmp_ok("$q", 'eq', '1/4294967296', '1@-8, base 16 ok');

my($qa, $qb) = (Rmpq_init(), Rmpq_init());

Rmpq_set_str($qa, '1@21', 16);
Rmpq_set_str($qb, '1@33', -16);
cmp_ok($qa, '==', $qb, '(1@21, 16) == (1@33, -16)');

Rmpq_set_str($qa, '1@-21', 16);
Rmpq_set_str($qb, '1@-33', -16);
cmp_ok($qa, '==', $qb, '(1@-21, 16) == (1@-33, -16)');

Rmpq_set_str($q, '0x1p+18', 0);
cmp_ok($q, '==', 262144, '(0x1p+18, 0) is 262144');
# Don't support octal - leading '0' is too troublesome
#Rmpq_set_str($q, '01p+18', 0);
#cmp_ok($q, '==', 262144, '(01p+18, 0) is 262144');
Rmpq_set_str($q, '0b1p+18', 0);
cmp_ok($q, '==', 262144, '(0b1p+18, 0) is 262144');
Rmpq_set_str($q, '1e5', 0);

eval { Rmpq_set_str($q, '1@15', 5); };
like($@, qr/string supplied to Rmpq_set_str function \(/i, '15 is an illegal exponent for a base 5 number');
Rmpq_set_str($q, '1000000000', 5);
cmp_ok($q, '==', 1953125, '(1000000000, 5) is 1953125');

Rmpq_set_str($q, '0x1.7', 0);
cmp_ok("$q", 'eq', '23/16', '0x1.7 is 23/16');

Rmpq_set_str($q, '0x1.7p0', 0);
cmp_ok("$q", 'eq', '23/16', '0x1.7p0 is 23/16');

Rmpq_set_str($q, '0x17p-4', 0);
cmp_ok("$q", 'eq', '23/16', '0x17p-4 is 23/16');

Rmpq_set_str($q, '0x17p-1', 0);
cmp_ok("$q", 'eq', '23/2', '0x1.7 is 23/16');

Rmpq_set_str($q, '1.7', 0);
cmp_ok("$q", 'eq', '17/10', '(1.7, 0) is 17/10');

Rmpq_set_str($q, '1.7', 10);
cmp_ok("$q", 'eq', '17/10', '(1.7, 10) is 17/10');

Rmpq_set_str($q, '1.755e2', 0);
cmp_ok("$q", 'eq', '351/2', '(1.755e2, 0) is 351/2');

Rmpq_set_str($q, '1.755e2', 10);
cmp_ok("$q", 'eq', '351/2', '(1.755e2, 10) is 351/2');

Rmpq_set_str($q, '0b1.1', 0);
cmp_ok("$q", 'eq', '3/2', '0b1.1 is 3/2');

Rmpq_set_str($q, '0b1.1p0', 0);
cmp_ok("$q", 'eq', '3/2', '0b1.1p0 is 3/2');

Rmpq_set_str($q, '0b11p-1', 0);
cmp_ok("$q", 'eq', '3/2', '0b11p-1 is 3/2');

Rmpq_set_str($q, '671234@-6', 8);
cmp_ok("$q", 'eq', '56487/65536', '(671234@-6, 8) is 56487/65536');

Rmpq_set_str($q, '671234@-6', -8);
cmp_ok("$q", 'eq', '56487/65536', '(671234@-6, 8) is 56487/65536');

Rmpq_set_str($q, '0o671234p-18', 0);
cmp_ok("$q", 'eq', '56487/65536', '(0o671234p-18, 0) is 56487/65536');

# Check some claims made in GMP's mpq_set_str documentation

Rmpq_set_str($q, '0xEF/100', 0);
cmp_ok("$q", 'eq', '239/100', '(0xEF/100,   0) is 239/100');

Rmpq_set_str($q, '0XEF/100', 0);
cmp_ok("$q", 'eq', '239/100', '(0XEF/100,   0) is 239/100');

Rmpq_set_str($q, '0xEF/0x100', 0);
cmp_ok("$q", 'eq', '239/256', '(0xEF/0x100, 0) is 239/256');

Rmpq_set_str($q, '0xEF/0100', 0);
cmp_ok("$q", 'eq', '239/64', '(0xEF/0100,  0) is 239/64');

Rmpq_set_str($q, '0xEF/0b100', 0);
cmp_ok("$q", 'eq', '239/4', '(0xEF/0b100, 0) is 239/4');

Rmpq_set_str($q, '0xEF/0B100', 0);
cmp_ok("$q", 'eq', '239/4', '(0xEF/0B100, 0) is 239/4');

Rmpq_set_str($q, '0xEF/0B100', 0);
cmp_ok("$q", 'eq', '239/4', '(0xEF/0B100, 0) is 239/4');

eval { Rmpq_set_str($q, 'inf/nan', 62);};
my $ok = 1;
if($@) {
  warn "\$\@: $@\n";
  $ok = 0;
}
cmp_ok($ok, '==', 1, "No error thrown by 'inf/nan', base 62, in Rmpq_set_str()");

eval { my $q = Math::GMPq->new('inf/nan', 62);};
$ok = 1;
if($@) {
  warn "\$\@: $@\n";
  $ok = 0;
}
cmp_ok($ok, '==', 1, "No error thrown by 'inf/nan', base 62, in new()");

eval { Rmpq_set_str($q, 'inf', 62);};
$ok = 1;
if($@) {
  warn "\$\@: $@\n";
  $ok = 0;
}
cmp_ok($ok, '==', 1, "No error thrown by 'inf', base 62, in Rmpq_set_str()");

eval { my $q = Math::GMPq->new('inf', 62);};
$ok = 1;
if($@) {
  warn "\$\@: $@\n";
  $ok = 0;
}
cmp_ok($ok, '==', 1, "No error thrown by 'inf', base 62, in new()");

eval { Rmpq_set_str($q, 'nan', 62);};
$ok = 1;
if($@) {
  warn "\$\@: $@\n";
  $ok = 0;
}
cmp_ok($ok, '==', 1, "No error thrown by 'nan', base 62, in Rmpq_set_str()");

eval { my $q = Math::GMPq->new('nan', 62);};
$ok = 1;
if($@) {
  warn "\$\@: $@\n";
  $ok = 0;
}
cmp_ok($ok, '==', 1, "No error thrown by 'nan', base 62, in new()");


done_testing();
