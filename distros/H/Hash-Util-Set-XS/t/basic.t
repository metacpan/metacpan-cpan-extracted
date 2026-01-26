#!perl
use strict;
use warnings;

use utf8;
use open ':std', ':encoding(UTF-8)';

use Test::More;

BEGIN {
  use_ok('Hash::Util::Set::XS', qw[ keys_union
                                    keys_intersection
                                    keys_difference
                                    keys_symmetric_difference
                                    keys_disjoint
                                    keys_equal
                                    keys_subset
                                    keys_proper_subset
                                    keys_superset
                                    keys_proper_superset
                                    keys_any
                                    keys_all
                                    keys_none ]);
}

{
  note "Testing with empty hashes";
  my %x = ();
  my %y = ();

  is_deeply([ keys_union %x, %y ], [], 'union of empty hashes');
  is_deeply([ keys_intersection %x, %y ], [], 'intersection of empty hashes');
  is_deeply([ keys_difference %x, %y ], [], 'difference of empty hashes');
  is_deeply([ keys_symmetric_difference %x, %y ], [], 'symmetric difference of empty hashes');

  ok(keys_disjoint(%x, %y), 'empty hashes are disjoint');
  ok(keys_equal(%x, %y), 'empty hashes are equal');
  ok(keys_subset(%x, %y), 'empty is subset of empty');
  ok(!keys_proper_subset(%x, %y), 'empty is not proper subset of empty');
  ok(keys_superset(%x, %y), 'empty is superset of empty');
  ok(!keys_proper_superset(%x, %y), 'empty is not proper superset of empty');
}

{
  note "Testing empty vs non-empty";
  my %empty = ();
  my %full = (a => 1, b => 2, c => 3);

  {
    my $got = [ sort { $a cmp $b } keys_union %empty, %full ];
    is_deeply($got, [qw(a b c)], 'union: empty + full');
  }

  is_deeply([ keys_intersection %empty, %full ], [], 'intersection: empty ∩ full');
  is_deeply([ keys_difference %empty, %full ], [], 'difference: empty - full');

  {
    my $got = [ sort { $a cmp $b } keys_difference %full, %empty ];
    is_deeply($got, [qw(a b c)], 'difference: full - empty');
  }

  {
    my $got = [ sort { $a cmp $b } keys_symmetric_difference %empty, %full ];
    is_deeply($got, [qw(a b c)], 'symmetric difference: empty △ full');
  }

  ok(keys_disjoint(%empty, %full), 'empty and full are disjoint');
  ok(!keys_equal(%empty, %full), 'empty ≠ full');
  ok(keys_subset(%empty, %full), 'empty ⊆ full');
  ok(keys_proper_subset(%empty, %full), 'empty ⊂ full');
  ok(!keys_subset(%full, %empty), 'full ⊄ empty');
  ok(keys_superset(%full, %empty), 'full ⊇ empty');
  ok(keys_proper_superset(%full, %empty), 'full ⊃ empty');
}

{
  note "Testing identical hashes";
  my %x = (a => 1, b => 2, c => 3);
  my %y = (a => 10, b => 20, c => 30);

  {
    my $got = [ sort { $a cmp $b } keys_union %x, %y ];
    is_deeply($got, [qw(a b c)], 'union: identical keys');
  }

  {
    my $got = [ sort { $a cmp $b } keys_intersection %x, %y ];
    is_deeply($got, [qw(a b c)], 'intersection: identical keys');
  }

  is_deeply([ keys_difference %x, %y ], [], 'difference: identical keys');
  is_deeply([ keys_symmetric_difference %x, %y ], [], 'symmetric difference: identical keys');

  ok(!keys_disjoint(%x, %y), 'identical keys are not disjoint');
  ok(keys_equal(%x, %y), 'identical keys are equal');
  ok(keys_subset(%x, %y), 'identical keys: subset');
  ok(!keys_proper_subset(%x, %y), 'identical keys: not proper subset');
  ok(keys_superset(%x, %y), 'identical keys: superset');
  ok(!keys_proper_superset(%x, %y), 'identical keys: not proper superset');
}

{
  note "Testing disjoint sets";
  my %x = (a => 1, b => 2);
  my %y = (c => 3, d => 4);

  {
    my $got = [ sort { $a cmp $b } keys_union %x, %y ];
    is_deeply($got, [qw(a b c d)], 'union: disjoint');
  }

  is_deeply([ keys_intersection %x, %y ], [], 'intersection: disjoint');

  {
    my $got = [ sort { $a cmp $b } keys_difference %x, %y ];
    is_deeply($got, [qw(a b)], 'difference: disjoint x - y');
  }

  {
    my $got = [ sort { $a cmp $b } keys_difference %y, %x ];
    is_deeply($got, [qw(c d)], 'difference: disjoint y - x');
  }

  {
    my $got = [ sort { $a cmp $b } keys_symmetric_difference %y, %x ];
    is_deeply($got, [qw(a b c d)], 'symmetric difference: disjoint');
  }

  ok(keys_disjoint(%x, %y), 'disjoint sets');
  ok(!keys_equal(%x, %y), 'disjoint: not equal');
}

{
  note "Testing keys_any";
  my %h = (a => 1, b => 2, c => 3);

  ok(keys_any(%h, 'a'), 'any: single existing key');
  ok(!keys_any(%h, 'x'), 'any: single non-existing key');
  ok(keys_any(%h, 'x', 'y', 'a'), 'any: one match among several');
  ok(keys_any(%h, 'a', 'b', 'c'), 'any: all match');
  ok(!keys_any(%h, 'x', 'y', 'z'), 'any: none match');
  ok(!keys_any(%h), 'any: empty list');

  my %empty = ();
  ok(!keys_any(%empty, 'a'), 'any: empty hash');
  ok(!keys_any(%empty), 'any: empty hash, empty list');
}

{
  note "Testing keys_all";
  my %h = (a => 1, b => 2, c => 3);

  ok(keys_all(%h, 'a'), 'all: single existing key');
  ok(!keys_all(%h, 'x'), 'all: single non-existing key');
  ok(keys_all(%h, 'a', 'b'), 'all: multiple existing keys');
  ok(!keys_all(%h, 'a', 'b', 'x'), 'all: some non-existing');
  ok(!keys_all(%h, 'x', 'y', 'z'), 'all: none existing');
  ok(keys_all(%h), 'all: empty list returns true');

  my %empty = ();
  ok(!keys_all(%empty, 'a'), 'all: empty hash');
  ok(keys_all(%empty), 'all: empty hash, empty list returns true');
}

{
  note "Testing keys_none";
  my %h = (a => 1, b => 2, c => 3);

  ok(!keys_none(%h, 'a'), 'none: single existing key');
  ok(keys_none(%h, 'x'), 'none: single non-existing key');
  ok(!keys_none(%h, 'a', 'b'), 'none: multiple existing keys');
  ok(!keys_none(%h, 'a', 'x'), 'none: some existing');
  ok(keys_none(%h, 'x', 'y', 'z'), 'none: all non-existing');
  ok(keys_none(%h), 'none: empty list returns true');

  my %empty = ();
  ok(keys_none(%empty, 'a'), 'none: empty hash');
  ok(keys_none(%empty), 'none: empty hash, empty list returns true');
}

done_testing;
