#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 4;

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    my $wrapped = $eval->wrap('$foo');
    $eval->eval('$foo = 55');
    is($wrapped->(), 55, 'wrapped'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my $wrapped = $eval->wrap('$foo = 42');
    $eval->eval('$foo = 55');
    $wrapped->();
    is($eval->eval('$foo'), 42, 'modify'.$s);
  }
}
