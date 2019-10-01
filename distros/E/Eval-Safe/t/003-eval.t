#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 12;

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    is($eval->eval('1+1'), 2, 'super simple eval'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    is_deeply([$eval->eval('(4, 5, 6)')], [4, 5, 6], 'eval in list context'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe, strict => 0);
    is($eval->eval('$foo = 42'), 42, 'non strict eval'.$s);
    is($@, '', 'non strict eval error'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe, strict => 1);
    is($eval->eval('$foo = 42'), undef, 'strict eval'.$s);
    like($@, qr/\$foo/, 'strict eval error'.$s);
  }
}

# TODO add tests for the various argument to the strict option and, if possible,
# tests for the warning one.
