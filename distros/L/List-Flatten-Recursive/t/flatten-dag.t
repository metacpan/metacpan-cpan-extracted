#!perl
use Test::More;
use Test::Deep;
use List::Flatten::Recursive;

# Test flattening of lists containing multiple references to the same list. Earlier versions of LFR failed this test.

my @sublist = ( 1..10 );

# Construct the flat version
my @flat_list = ( "a", @sublist, "b", @sublist, "c" );

# Construct the non-flat version
my @dag = ( "a", \@sublist, [ [ "b", \@sublist ], "c" ] );

# Flatten and compare
cmp_deeply(
    [ flat(@dag) ],
    \@flat_list,
    "Flatten directed acyclic graph."
);

done_testing();
