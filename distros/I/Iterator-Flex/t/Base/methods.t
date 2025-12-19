#! perl

use v5.28;
use Test2::V0;

use Iterator::Flex::Common 'iseq', 'iarray';
use Iterator::Flex::Gather::Constants ':all';

use experimental 'declared_refs';

subtest buffer => sub {
    my $count = 0;
    my $iter  = iseq( 20 )->map( sub { ++$count; $_ } )->buffer( 10 );
    is( $iter->(),    0,           'first value' );
    is( $count,       10,          'buffer count' );
    is( $iter->drain, [ 1 .. 20 ], 'rest of values' );
    is( $count,       21,          'buffer count' );
};

subtest cache => sub {

    my $iter = iseq( 20 )->cache( { capacity => 5 } );

    is( $iter->drain( 10 ),                 [ 0 .. 9 ],         'first set of values' );
    is( [ map { $iter->at( $_ ) } 0 .. 4 ], [ reverse 5 .. 9 ], 'cached values' );

    is( $iter->drain, [ 10 .. 20 ], 'rest of values' );
};

subtest cat => sub {
    my $iter = iseq( 4 )->cat( iseq( 5, 9 ), iseq( 10, 15 ) );
    is( $iter->drain, [ 0 .. 15 ], 'values' );
};

subtest chunk => sub {
    my $iter = iseq( 1, 10 )->chunk( { capacity => 5 } );
    is( $iter->(), [ 1 .. 5 ],  'first chunk' );
    is( $iter->(), [ 6 .. 10 ], 'last chunk' );
};

subtest 'drain' => sub {

    subtest 'return' => sub {
        my $iter = iseq( 20, { exhaustion => 'return' } );
        my \@values = $iter->drain;
        is( $iter->is_exhausted, T(),         'exhausted' );
        is( \@values,            [ 0 .. 20 ], 'values' );
    };

    subtest 'throw' => sub {
        my $iter = iseq( 20, { exhaustion => 'throw' } );
        my \@values = $iter->drain;
        is( $iter->is_exhausted, T(),         'exhausted' );
        is( \@values,            [ 0 .. 20 ], 'values' );
    };

};

subtest 'flatten' => sub {
    my $iter = iarray( [ iseq( 1, 3 ), 4, [ 5, 6, 7 ], [ [ 8, 9, 10 ] ] ] )->flatten;
    is( $iter->drain, [ 1 .. 7, [ 8, 9, 10 ] ], 'values' );
};

subtest 'foreach' => sub {
    my $count = 0;
    iseq( 1, 4 )->foreach( sub { $count += $_ } );
    is( $count, 10 );
};

subtest 'gather' => sub {

    my $iter = iseq( 1, 10 )->gather(
        sub {
            return GATHER_CYCLE_CONTINUE | (
                $_ % 2
                ? GATHER_ELEMENT_EXCLUDE
                : GATHER_ELEMENT_INCLUDE
            );
        } );

    is( $iter->drain, [ [ 2, 4, 6, 8, 10 ] ] );

};

subtest grep => sub {
    is( iseq( 1, 10 )->grep( sub { $_ % 2 } )->drain, [ 1, 3, 5, 7, 9 ] );
};

subtest map => sub {
    is( iseq( 1, 4 )->map( sub { $_ * 2 } )->drain, [ 2, 4, 6, 8 ] );
};

subtest take => sub {
    is( iseq( 10 )->take( 3 )->drain, [ 0 .. 2 ] );
};

done_testing;
