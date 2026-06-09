use strict;
use warnings;

use Test::More tests => 7;

use List::Search qw( list_search nlist_search list_contains nlist_contains );

# Test that an empty array returns -1
is list_search( 'foo', [] ), -1, "list_search: empty array returns -1";

# Test that an empty array contains nothing
is list_contains( 'foo', [] ), 0, "list_contains: empty array returns false";
is nlist_contains( 42,   [] ), 0, "nlist_contains: empty array returns false";

# Test that the first index of repeated values are returned.
my @repeated = qw( a a a b b c c c d );
is list_search( 'a', \@repeated ), 0, "a at 0 in '@repeated'";
is list_search( 'b', \@repeated ), 3, "b at 3 in '@repeated'";
is list_search( 'c', \@repeated ), 5, "c at 5 in '@repeated'";
is list_search( 'd', \@repeated ), 8, "d at 8 in '@repeated'";

