#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::BigInt;
use Math::Revhash;

plan tests => 19999; # 1 + 9999 * 2

$Math::Revhash::UNSAFE = 1;

# Should fail even in unsafe
eval { Math::Revhash->new(10) } or ok($@ =~ /A.*undefined/, "A value");

my $length = 4;
my %h;
my $rh = Math::Revhash->new($length);
for my $number (1..(10 ** $length - 1)) {
   my $hash = $rh->hash($number);
   my $rnumber = $rh->unhash($hash);
   ok($number == $rnumber, "reverse hash");
   ok($h{$hash}++ == 0, "hash collision");
}
