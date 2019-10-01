#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Scalar::Util 'blessed';
use Test::More;

plan tests => 4;

{
  my $eval = Eval::Safe->new();
  is (blessed $eval, 'Eval::Safe::Eval', 'default new is Eval');
}{
  my $eval = Eval::Safe->new(safe => 0);
  is (blessed $eval, 'Eval::Safe::Eval', 'explicitly built with Eval');
}{
  my $eval = Eval::Safe->new(safe => 1);
  is (blessed $eval, 'Eval::Safe::Safe', 'build using Safe');
}{
  eval { my $eval = Eval::Safe->new(foobar => 1) };
  like ($@, qr/Unknown options: foobar/, 'unknown options');
}

# Add test for bad arguments to strict and warnings, and package