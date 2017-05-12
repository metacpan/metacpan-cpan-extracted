#!perl
use Test::More;
use Test::Deep;
use List::Flatten::Recursive;

# Construct the flat version
my @flat_list_of_one = ( 1 );

# Construct the non-flat version
my $scalar = 1;

# Flatten and compare
cmp_deeply(
    [ flat($scalar) ],
    \@flat_list_of_one,
    "Flatten scalar."
);

done_testing();
