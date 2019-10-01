#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 20;

# Test the behavior of 'die', 'warn', etc in the safe.

# Test that bad code will set $@ (at compile time, at execution time of wrapped
# code?)...

# Also test what happen with signals (Safe will do a local *SIG, around the code)

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $eval = Eval::Safe->new(safe => $safe);
    $@ = '';
    is($eval->eval('die "foobar"'), undef, 'die in eval'.$s);
    like($@, qr/foobar/, '$@ is set after die'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $@ = '';
    is($eval->eval('not_a_keyword()'), undef, 'bad code in eval'.$s);
    like($@, qr/Undefined subroutine/, '$@ is set after bad code'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my $w = $eval->wrap('die "foobar"');
    ok($w, 'wrap with die statement'.$s);
    $@ = '';
    # In safe mode this does not need to be wrapped in eval as this does not
    # die and the error is not set :-(
    is($w->(), undef, 'calling wrapped die'.$s);
    like($@, qr/foobar/, '$@ is set after call to bad code'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    my $w = $eval->wrap('sub { die "foobar"} ');
    my $ww = $w->();
    ok($ww, 'recursive wrap with die statement'.$s);
    $@ = '';
    # In safe mode this does not need to be wrapped in eval as this does not
    # die and the error is not set :-(
    is($ww->(), undef, 'calling recursively wrapped die'.$s);
    like($@, qr/foobar/, '$@ is set after call to recursively bad code'.$s);
  }
}
