use strict;
use warnings;
use Math::GMPz qw(__GNU_MP_RELEASE :mpz);

eval {require Math::GMPq;};

if($@) {
  warn "\nCouldn't load Math::GMPq - skipping all tests:\n$@\n";
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

if(60099 > __GNU_MP_RELEASE) { #mpq_cmp_z is unavailable
  print "1..8\n";

  warn "\nmpq_cmp_z NOT available\n";

  print "ok 1\n";

  eval{my $discard = ($z < $q);};
  if($@ =~ /^overloading "<": mpq_cmp_z/) {print "ok 2\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 2\n";
  }

  eval{my $discard = ($z > $q);};
  if($@ =~ /^overloading ">": mpq_cmp_z/) {print "ok 3\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 3\n";
  }

  eval{my $discard = ($z <= $q);};
  if($@ =~ /^overloading "<=": mpq_cmp_z/) {print "ok 4\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 4\n";
  }

  eval{my $discard = ($z >= $q);};
  if($@ =~ /^overloading ">=": mpq_cmp_z/) {print "ok 5\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 5\n";
  }

  eval{my $discard = ($z == $q);};
  if($@ =~ /^overloading "==": mpq_cmp_z/) {print "ok 6\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 6\n";
  }

  eval{my $discard = ($z != $q);};
  if($@ =~ /^overloading "!=": mpq_cmp_z/) {print "ok 7\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 7\n";
  }

  eval{my $discard = ($z <=> $q);};
  if($@ =~ /^overloading "<=>": mpq_cmp_z/) {print "ok 8\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 8\n";
  }

  exit 0;
}

print "1..14\n";

warn "\nmpq_cmp_z is available\n";

print "ok 1\n"; # test removed

$z > $q ? print "ok 2\n"
        : print "not ok 2\n";

$z >= $q ? print "ok 3\n"
         : print "not ok 3\n";

($z <=> $q) > 0 ? print "ok 4\n"
                : print "ok 4\n";

$z *= -1;

print "ok 5\n"; # test removed

$z < $q ? print "ok 6\n"
        : print "not ok 6\n";

$z <= $q ? print "ok 7\n"
         : print "not ok 7\n";

($z <=> $q) < 0 ? print "ok 8\n"
                : print "ok 8\n";

$z != $q ? print "ok 9\n"
         : print "not ok 9\n";

$q *= 2;

print "ok 10\n"; # test removed

$z == $q ? print "ok 11\n"
         : print "not ok 11\n";

$z <= $q ? print "ok 12\n"
         : print "not ok 12\n";

$z >= $q ? print "ok 13\n"
         : print "not ok 13\n";

($z <=> $q) == 0 ? print "ok 14\n"
                 : print "ok 14\n";

