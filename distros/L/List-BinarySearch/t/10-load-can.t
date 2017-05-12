#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  # Force pure-Perl testing.
  $ENV{List_BinarySearch_PP} = 1; ## no critic (local)
}

BEGIN {
    use_ok( 'List::BinarySearch', qw( :all ) )
        || BAIL_OUT();
}


can_ok(
    'List::BinarySearch',
    qw(  binsearch    binsearch_pos    binsearch_range  )
);

done_testing();
