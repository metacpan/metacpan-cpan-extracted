use strict;
use warnings;
use Math::GMPq qw(__GNU_MP_RELEASE :mpq);

eval {require Math::GMPz;};

if($@) {
  warn "\nCouldn't load Math::GMPz - skipping all tests:\n$@\n";
  print "1..1\n";
  print "ok 1\n";
  exit 0;
}

my $z = Math::GMPz->new(1);
my $q;
{
no warnings 'uninitialized'; # __GNU_MP_RELEASE may be undef.
$q = Math::GMPq->new("20/-40"); # should automatically be canonicalized to -1/2.
}

print "1..14\n";

Rmpq_cmp_z($q, $z) < 0 ? print "ok 1\n"
                       : print "not ok 1\n";

$q < $z ? print "ok 2\n"
        : print "not ok 2\n";

$q <= $z ? print "ok 3\n"
         : print "not ok 3\n";

($q <=> $z) < 0 ? print "ok 4\n"
                : print "ok 4\n";

$z *= -1;

Rmpq_cmp_z($q, $z) > 0 ? print "ok 5\n"
                       : print "not ok 5\n";

$q > $z ? print "ok 6\n"
        : print "not ok 6\n";

$q >= $z ? print "ok 7\n"
         : print "not ok 7\n";

($q <=> $z) > 0 ? print "ok 8\n"
                : print "ok 8\n";

$q != $z ? print "ok 9\n"
         : print "not ok 9\n";

$q *= 2;

Rmpq_cmp_z($q, $z) == 0 ? print "ok 10\n"
                        : print "not ok 10\n";

$q == $z ? print "ok 11\n"
         : print "not ok 11\n";

$q <= $z ? print "ok 12\n"
         : print "not ok 12\n";

$q >= $z ? print "ok 13\n"
         : print "not ok 13\n";

($q <=> $z) == 0 ? print "ok 14\n"
                 : print "ok 14\n";

