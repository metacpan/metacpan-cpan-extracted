#! perl

use Test2::V0;
use Iterator::Flex::Common 'iseq', 'istack';
use experimental 'signatures';

subtest 'modify stack' => sub {

    my $iter = istack();

    $iter->push( iseq( 1, 10 ) );
    is( $iter->next, 1 );

    $iter->unshift( iseq( 11, 20 ) );
    is( $iter->next, 11 );

    my $tmp = $iter->pop;

    is( $tmp->next,    2 );
    is( $tmp->current, 2 );

    $iter->unshift( $tmp );

    is( $iter->next,    3 );
    is( $iter->current, 3 );
    is( $iter->prev,    11 );


    $tmp = $iter->shift;

    is( $iter->next,    12 );
    is( $iter->current, 12 );
    is( $iter->prev,    3 );

    $iter->push( $tmp );

    is( $iter->next,    13 );
    is( $iter->current, 13 );
    is( $iter->prev,    12 );

    my @rest = map { $iter->next } 1 .. 7 + 7;

    is( \@rest, [ 14 .. 20, 4 .. 10 ] );

    is( $iter->next,         U() );
    is( $iter->is_exhausted, T() );
};

subtest 'rewind' => sub {

    my $iter = istack( [ 0, 10 ], [ 20, 30 ] );
    is( $iter->drain, [ 0, 10, 20, 30 ], 'test initial iterator' );

    ok( lives { $iter->rewind }, 'rewind' )
      or diag $@;

    is( $iter->prev,  30,                'prev' );
    is( $iter->drain, [ 0, 10, 20, 30 ], 'test rewound iterator' );

    $iter->push( [ 40, 50 ] );
    is( $iter->drain, [ 40, 50 ], 'push a new iterator and drain' );

    ok( lives { $iter->rewind }, 'rewind' )
      or diag $@;

    is( $iter->prev,  50,                'prev' );
    is( $iter->drain, [ 0, 10, 20, 30 ], 'rewind' );

    ok( lives { $iter->rewind }, 'rewind' )
      or diag $@;

    $iter->push( [ 40, 50 ] );
    $iter->snapshot;
    is( $iter->drain, [ 0, 10, 20, 30, 40, 50 ], 'push, snapshot, rewind' );
};

subtest 'reset' => sub {

    my $iter = istack( [ 0, 10 ], [ 20, 30 ] );
    is( $iter->drain, [ 0, 10, 20, 30 ], 'test initial iterator' );

    ok( lives { $iter->reset }, 'reset' )
      or diag $@;

    is( $iter->prev,  undef,             'prev' );
    is( $iter->drain, [ 0, 10, 20, 30 ], 'test rewound iterator' );

    $iter->push( [ 40, 50 ] );
    is( $iter->drain, [ 40, 50 ], 'push a new iterator and drain' );

    ok( lives { $iter->reset }, 'reset' )
      or diag $@;

    is( $iter->prev,  undef,             'prev' );
    is( $iter->drain, [ 0, 10, 20, 30 ], 'reset' );

    ok( lives { $iter->reset }, 'reset' )
      or diag $@;

    $iter->push( [ 40, 50 ] );
    $iter->snapshot;
    is( $iter->drain, [ 0, 10, 20, 30, 40, 50 ], 'push, snapshot, reset' );
};

done_testing;
