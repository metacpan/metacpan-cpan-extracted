#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
  # Force pure-Perl testing.
  $ENV{List_BinarySearch_PP} = 1; ## no critic (local)
}

use List::BinarySearch qw( :all );

my @integers    = ( 100, 200, 300, 400, 500 );
my @strings      = qw( ape  bat  bear  cat  dog );

subtest
    "Test numeric search function that returns insert position upon no-match."
    => sub {
        plan tests => 2;
        is(
            binsearch_pos( sub{ $a <=> $b }, 100, @integers ), 0,
            "bsearch_custom_pos: Found at position 0."
        );
        is( binsearch_pos( sub{ $a <=> $b }, 500, @integers ), 4,
            "bsearch_custom_pos: Found at last position."
        );
        done_testing();
};

# my @strings      = qw( ape  bat  bear  cat  dog );

subtest
    "Test string search function that returns insert position upon no-match."
    => sub {
        plan tests => 1;
        is(
            binsearch_pos( sub{ $a cmp $b }, 'zebra', @strings ),
            5, "bsearch_custom_pos: Insert after last position."
        );
        done_testing();
};

subtest "Test range functions." => sub {
    plan tests => 2;
    my( $low, $high );
    ( $low, $high )
      = ( binsearch_range { $a cmp $b }  'bat', 'cat', @strings );
  is( $low,  1, "bsearch_custom_range: Found low at 1." );
  is( $high, 3, "bsearch_custom_range: Found high at 3." );
  
    done_testing();
};

done_testing();
