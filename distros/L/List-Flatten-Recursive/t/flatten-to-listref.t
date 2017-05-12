#!perl
use Test::More;
use Test::Deep;
use List::Flatten::Recursive qw( flat flatten_to_listref );

# Construct the non-flat version
my @nonflat_list = (1, [2, 3], [4, [5, 6, [7,], 8, [9,]]], 10,);

# Flatten both ways and compare
cmp_deeply(
    flatten_to_listref(@nonflat_list),
    [ flat(@nonflat_list) ],
    "Flatten list via flatten_to_listref."
);

done_testing();
