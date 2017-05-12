#!/usr/bin/env perl

# Test proper loading and exporting of binsearch and binsearch_pos from
# List::BinarySearch::PP.  Verify List::BinarySearch::PP can be used.

# In-depth testing provided in other test scripts.  Here we're only verifying
# they are present and functional.

use strict;
use warnings;

use Test::More;

BEGIN {
  # Force pure-Perl testing.
  $ENV{List_BinarySearch_PP} = 1; ## no critic (local)
}

BEGIN {
  use_ok 'List::BinarySearch::PP', qw( binsearch binsearch_pos );
}


can_ok 'main', qw( binsearch binsearch_pos );
can_ok 'List::BinarySearch::PP', qw( binsearch binsearch_pos );


is( ( binsearch { $a <=> $b } 5, @{[0,1,2,3,4,5,6]} ), 5,
  'binsearch: Found an item.'
);


is( ( binsearch { $a <=> $b } -1, @{[0,1,2,3,4,5,6]} ), undef,
  'binsearch: Found undef.'
);

is( ( binsearch { $a <=> $b } 2, @{[0,1, ,3,4,5,6]} ), undef,
  'binsearch: Found undef again.'
);

is( ( binsearch_pos { $a <=> $b } 2, @{[0,1,2,3,4,5,6]} ), 2,
  'binearch_pos: Found an item.'
);

is( ( binsearch_pos { $a <=> $b } 2, @{[0,1,  3,4,5,6]} ), 2,
  'binsearch_pos: Found an insert point.'
);

done_testing;
