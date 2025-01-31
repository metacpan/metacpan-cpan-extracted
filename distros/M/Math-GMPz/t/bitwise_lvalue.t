# This script won't compile if $] <= 5.041002
use strict;
use warnings;
use Test::More;
use Math::GMPz qw(:mpz);

BEGIN{
 if($] <= 5.041002) {
   print "1..1\n";
   warn "\n skipping all tests - this script won't even compile because \$] <= 5.041002\n See https://github.com/Perl/perl5/pull/22414\n";
   print "ok 1\n";
   exit;
   }
};

my $iv = 123456789;
($iv &= 987654321) ^= 555555555;

my $z = Math::GMPz->new(123456789);
($z &= 987654321) ^= 555555555;
cmp_ok($z, '==', $iv, "TEST 1");

$z = Math::GMPz->new(987654321);
($z &= 123456789) ^= 555555555;
cmp_ok($z, '==', $iv, "TEST 2");

$iv = 123456789;
($iv |= 987654321) &= 555555555;

$z = Math::GMPz->new(123456789);
($z |= 987654321) &= 555555555;
cmp_ok($z, '==', $iv, "TEST 3");

$z = Math::GMPz->new(987654321);
($z |= 123456789) &= 555555555;
cmp_ok($z, '==', $iv, "TEST 4");

done_testing();
