#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 8;

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    is($eval->interpolate('abc'), 'abc', 'no interpolation'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->eval('$a = "abc"');
    is($eval->interpolate('$a'), 'abc', 'simple interpolation'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->eval('$a = "abc"');
    is($eval->interpolate('"$a"'), '"abc"', 'double quote'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->eval('$a = "abc"');
    is($eval->interpolate("'\$a'"), "'abc'", 'simple quote'.$s);
  }
}
