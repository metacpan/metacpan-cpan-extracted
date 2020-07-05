#!perl
use 5.006;
use open qw(:locale);
use strict;
use warnings;
#use utf8;

use Test::More;

use lib qw(../lib/);

use LCS::BV;

my $width = int 0.999+log(~0)/log(2);

use integer;
no warnings 'portable'; # for 0xffffffffffffffff

my $tests64 = [
  ['bits_0',0,0],
  ['prefix_8', 0xff00000000000000,8],
  ['suffix_8', 0x00000000000000ff,8],
  ['prefix_16',0xffff000000000000,16],
  ['prefix_64',0xffffffffffffffff,64],
];

if (1 & ($width == 64)) {
  #$LCS::BV::width = 64;
  for my $test (@{$tests64}) {
    is(LCS::BV::_count_bits($test->[1]),$test->[2],'_count_bits 64 '.$test->[0]);
  }
}

my $tests32 = [
  ['bits_0',0,0],
  ['prefix_8', 0xff000000,8],
  ['suffix_8', 0x000000ff,8],
  ['prefix_16',0xffff0000,16],
  ['prefix_32',0xffffffff,32],
];

if (1 & ($width == 32)) {
  #$LCS::BV::width = 32;
  for my $test (@{$tests32}) {
    is(LCS::BV::_count_bits($test->[1]),$test->[2],'_count_bits 32 '.$test->[0]);
  }
}

if (1 & ($width == 64)) {
  $LCS::BV::width = 32;
  for my $test (@{$tests32}) {
    is(LCS::BV::_count_bits($test->[1]),$test->[2],'_count_bits 32 '.$test->[0]);
  }
  $LCS::BV::width = 64;
}

done_testing;

