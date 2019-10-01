#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 10;

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->eval('$foo = 55');
    is(${$eval->var_ref('$foo')}, 55, 'var_ref'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my $ref = $eval->var_ref('$bar');
    is(ref $ref, 'SCALAR', 'get future ref'.$s);
    $eval->eval('$bar = 42');
    is($$ref, 42, 'read future var_ref'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my $ref = $eval->var_ref('@baz');
    is(ref $ref, 'ARRAY', 'get future array ref'.$s);
    @$ref = (4, 5, 6);
    is_deeply([$eval->eval('@baz')], [4, 5, 6], 'set future var_ref'.$s);
  }
}
