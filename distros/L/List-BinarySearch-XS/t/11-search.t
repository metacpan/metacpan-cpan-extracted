#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use List::BinarySearch::XS qw( binsearch binsearch_pos );

local( $a, $b ) = ( 'Hello', 'world!' );

my @numeric_tests = (
#                                0  1  2  3  4   5   6   7   8   9   10  11  12  13  14  15  16
  [ 'Odd number of elements',  [ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 53, 59, 61 ] ],
  [ 'Even number of elements', [ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 53, 59     ] ],
  [ 'Single element',          [ 2                                                              ] ],
  [ 'Two elements',            [ 2, 3                                                           ] ],
  [ 'Empty list',              [                                                                ] ],
);
#                0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64
my @position = ( 0,0,0,1,2,2,3,3,4,4, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9,10,10,11,11,11,11,11,11,12,12,12,12,13,13,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,16,16,17,17,17 ); 

is( "$a $b", 'Hello world!', '$a and $b initial value set.' );

subtest "Basic Usage" => sub {
  subtest "binsearch" => sub {
    foreach my $test ( @numeric_tests ) {
      foreach my $needle ( 0 .. 64 ) {
        my( $control ) = grep{ $test->[1][$_] == $needle } 0 .. $#{$test->[1]};
        my $found      = binsearch { $a <=> $b } $needle, @{$test->[1]};
        is( $found, $control,
            "binsearch: $test->[0]. Needle => $needle. Location => "
            . ( defined( $found ) ? "$found." : "undef." )
        );
      }
    }
    done_testing();
  };

  subtest "binsearch_pos" => sub {
    foreach my $test ( @numeric_tests ) {
      foreach my $needle ( 0 .. 64 ) {
        my $control = $position[$needle] > $#{$test->[1]} ? $#{$test->[1]} + 1 : $position[$needle];
        my $found = binsearch_pos { $a <=> $b } $needle, @{$test->[1]};
        is( $found, $control,
            "binsearch_pos: $test->[0]. Needle => $needle. Location => $found."
        );
      }
    }
    done_testing();
  };
  done_testing();
};

# No match contextual returns: undef, or empty list.
is( ( binsearch { $a <=> $b } 10, @{[ 7, 9, 11 ]} ), undef,
    'binsearch: undef returned in scalar context for no match.'
);

{
  my @result_set = binsearch { $a <=> $b } 10, @{[ 7, 9, 11 ]};
  is( scalar @result_set, 0,
      'binsearch: empty list returned in list context for no match.'
  );
} 

# Verify we can use a subref rather than block.
my $found = binsearch_pos( sub{ $a <=> $b }, 10, @{[ 2, 4, 6, 8, 10, 12, 14, 16 ]} );
is( $found, 4, 'Subref and aref work despite prototypes.' );

# Verify that $a and $b are in-tact.
is( "$a $b", 'Hello world!', '$a and $b were not clobbered.' );

done_testing();
