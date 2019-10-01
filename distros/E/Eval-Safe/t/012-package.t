#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

use Data::Dumper;

plan tests => 14;

for my $safe (0..1) {
  my $s = $safe ? ' safe' : '';
  {
    my $a = Eval::Safe->new(safe => $safe);
    my $b = Eval::Safe->new(safe => $safe);
    cmp_ok($a->package(), 'ne', $b->package(), 'new package'.$s);
  }{
    my $p = 't::Eval::Safe::TestP';
    my $eval = Eval::Safe->new(safe => $safe, package => $p);
    is($eval->package(), $p, 'explicit package'.$s);
  }{
    my $eval = Eval::Safe->new(safe => $safe);
    $eval->eval('$foo = 42');
    my $p = $eval->package();
    is(eval("\$${p}::foo"), 42, 'read from implicit package'.$s)
  }{
    my $p = 't::Eval::Safe::TestP';
    my $eval = Eval::Safe->new(safe => $safe, package => $p);
    $eval->eval('$foo = 42');
    # This is an eval, to avoid auto-vivifying the TestP package (which would
    # prevent creating the object).
    is(eval('$t::Eval::Safe::TestP::foo'), 42, 'read from explicit package'.$s)
  }{
    # We have to eval this, otherwise the package is created when the code is
    # compiled and then deleted after the first run of this test. On the second
    # run, the code still refers to the deleted package, so the package is not
    # actually re-created.
    eval('$t::Eval::Safe::OtherP::foo = 1');
    my $p = 't::Eval::Safe::OtherP';
    is(eval { Eval::Safe->new(safe => $safe, package => $p) }, undef, 'package already exists'.$s);
    like($@, qr/OtherP already exists/, 'error already exists'.$s);
    my $eval = Eval::Safe->new(safe => $safe, package => $p, force_package => 1);
    is($eval->package, $p, 'forced package'.$s);
  }
}
