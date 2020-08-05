#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::Revhash;

plan tests => 2_214; # 2 * (9 + 99 + 999)

for my $len (1..3) {
   my $rh = Math::Revhash->new($len);
   for (1..(10**$len - 1)) {
      my %h;
      my $number = $_;
      my $hash = $rh->hash($number);
      my $rnumber = $rh->unhash($hash);
      ok($number == $rnumber, "reverse hash");
      ok($h{$hash}++ == 0, "hash collision");
   }
}
