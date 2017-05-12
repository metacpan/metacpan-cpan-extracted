#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use List::BinarySearch;

# lib/List/BinarySearch.pm Line 229.
is(
  ( List::BinarySearch::binsearch_range { $a <=> $b } 200, 500, @{[100,200,300,400]} ),
  3,
  'binsearch_range: Adjusts for overshooting range.'
);

is(
  ( List::BinarySearch::binsearch_range { $a <=> $b } 200, 350, @{[100,200,300,400]} ),
  2,
  'binsearch_range: Correct range when upper bound is in-bounds but not found.'
);

is(
  ( List::BinarySearch::binsearch { $a <=> $b } 250, @{[100]} ),
  undef,
  'binsearch: Match in range but not found.'
);


done_testing();
