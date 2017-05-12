#!perl
use Test::More;
use Test::Deep;
use List::Flatten::Recursive;

# Construct the flat version
my @flat_list = ( 1..10 );

# Construct the non-flat version
my @nonflat_list = (1, [2, 3], [4, [5, 6, [7,], 8, [9,]]], 10,);

# Flatten and compare
cmp_deeply(
    [ flat(@nonflat_list) ],
    \@flat_list,
    "Flatten list."
);

done_testing();
