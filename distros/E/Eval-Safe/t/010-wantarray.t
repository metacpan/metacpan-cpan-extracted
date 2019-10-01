#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 12;

my $sub = 'if (defined wantarray) { $v = (wantarray) ? "1" : "0" } else { $v = "n" }';

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    my @ignored = $eval->eval($sub);
    is(${$eval->var_ref('$v')}, '1', 'list context'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my $ignored = $eval->eval($sub);
    is(${$eval->var_ref('$v')}, '0', 'scalar context'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->eval($sub);
    is(${$eval->var_ref('$v')}, 'n', 'void context'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my @ignored = $eval->wrap($sub)->();
    is(${$eval->var_ref('$v')}, '1', 'list context in wrapped sub'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my $ignored = $eval->wrap($sub)->();
    is(${$eval->var_ref('$v')}, '0', 'scalar context in wrapped sub'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->wrap($sub)->();
    is(${$eval->var_ref('$v')}, 'n', 'void context in wrapped sub'.$s);
  }
}
