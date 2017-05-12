#!perl
use Test::More;
use Test::Deep;
use List::Flatten::Recursive;

my @sublist = ( 1, 2 );

# Construct the flat version
my @flat_list = ( "a", @sublist, "b", @sublist, "c" );

# Construct the non-flat version
my @complex = ( "a", \@sublist, "b", \@sublist, "c" );
push @sublist, \@complex;

# Flatten and compare
cmp_deeply(
    [ flat(\@complex) ],
    \@flat_list,
    "Flatten complex circular structure."
) or diag explain([ flat(@complex) ]);

done_testing();
