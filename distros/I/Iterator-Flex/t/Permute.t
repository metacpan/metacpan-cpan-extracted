#! perl

use Test2::V0;
use Test::Lib;

use Iterator::Flex::Permute;
use Math::BigInt;
use List::Util 'uniqstr';

use experimental 'declared_refs', 'signatures';

# https://en.wikipedia.org/wiki/Permute#k-permutations_of_n
sub nexpect ( $n, $k ) { Math::BigInt->bfac( $n ) / Math::BigInt->bfac( $n - $k ) }

for my $set ( [ 2, 2 ], [ 3, 3 ], [ 3, 2 ], [ 4, 2 ] ) {

    ## no critic (Ambiguous)
    my ( $n, $k ) = $set->@*;
    my $nexpect = nexpect( $n, $k );

    my $iter = Iterator::Flex::Permute->new( [ 1 .. $n ], { k => $k } );
    my @results;
    push @results, join q{}, $_->@* while $_ = $iter->();
    @results = uniqstr sort @results;
    is( 0+ @results, $nexpect->numify, "n = $n; k = $k" );
}

done_testing;
