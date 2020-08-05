#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Math::Revhash qw( revhash revunhash );

plan tests => 222_210; # 2 * (9 + 99 + 999 + 9999 + 99999)

for my $len (1..5) {
   for (1..(10**$len - 1)) {
      my %h;
      my $number = $_;
      my $hash = revhash($number, $len);
      my $rnumber = revunhash($hash, $len);
      ok($number == $rnumber, "reverse hash");
      ok($h{$hash}++ == 0, "hash collision");
   }
}
