#! perl

use Test2::V0;
use Test::Lib;

use feature 'signatures';
use Iterator::Flex::Common qw[ ibuffer iseq thaw ];
use Data::Dump 'pp';

sub xsubtest { }

subtest 'buffer is multiple of input' => sub {

    my $iterable = iseq( 10 );
    my $iter     = ibuffer( $iterable, 5 );

    my sub check ( $prev ) {

        is( $iter->next,     0, 'first element' );
        is( $iterable->next, 5, 'un-buffered element in iterable' );

        is( $iter->current, 0,     'current' );
        is( $iter->prev,    $prev, 'prev' );

        is( $iter->next,    1, 'next' );
        is( $iter->current, 1, 'current' );
        is( $iter->prev,    0, 'prev' );

        is( $iter->drain( 3 ), [ 2, 3, 4 ], 'read  elements' );
        is( $iter->current,    4,           'current' );
        is( $iter->prev,       3,           'prev' );

        is( $iter->drain( 2 ), [ 6, 7 ], 'read  elements' );
        is( $iter->current,    7,        'current' );
        is( $iter->prev,       6,        'prev' );

        is( $iter->drain, [ 8, 9, 10 ], 'drain' );

        is( $iter->prev, 10, 'prev' );

        is( $iter->next, U(), 'next is undefined' );
        ok( $iter->is_exhausted, 'exhausted' );

    }

    subtest 'intial run' => sub {
        check( U() );
    };

    subtest 'rewind' => sub {
        ok( lives { $iter->rewind }, 'rewind' )
          or diag $@;
        check( 10 );
    };

    subtest 'reset' => sub {
        ok( lives { $iter->reset }, 'reset' )
          or diag $@;
        check( U() );
    };

    subtest 'interrupt, then rewind' => sub {
        $iterable = iseq( 10 );
        $iter     = ibuffer( $iterable, 5 );

        ok( $iter->drain( 3 ), [ 0, 1, 2 ], 'drain some' );
        ok( lives { $iter->rewind }, 'rewind' )
          or diag $@;

        check( 2 );
    };

    subtest 'interrupt, then reset' => sub {
        $iterable = iseq( 10 );
        $iter     = ibuffer( $iterable, 5 );

        ok( $iter->drain( 3 ), [ 0, 1, 2 ], 'drain some' );
        ok( lives { $iter->reset }, 'reset' )
          or diag $@;

        check( U() );
    };


};

subtest 'buffer is not multiple of input' => sub {

    my $iterable = iseq( 10 );
    my $iter     = ibuffer( $iterable, 3 );

    my sub check ( $prev ) {

        is( $iter->next,     0, 'first element' );
        is( $iterable->next, 3, 'un-buffered element in iterable' );

        is( $iter->current, 0,     'current' );
        is( $iter->prev,    $prev, 'undefined prev' );

        is( $iter->next,    1, 'next' );
        is( $iter->current, 1, 'current' );
        is( $iter->prev,    0, 'prev' );

        is( $iter->drain( 3 ), [ 2, 4, 5 ], 'read  elements' );
        is( $iter->current,    5,           'current' );
        is( $iter->prev,       4,           'prev' );

        is( $iter->drain( 2 ), [ 6, 7 ], 'read  elements' );
        is( $iter->current,    7,        'current' );
        is( $iter->prev,       6,        'prev' );

        is( $iter->drain, [ 8, 9, 10 ], 'drain' );

        is( $iter->prev, 10, 'prev' );

        is( $iter->next, U(), 'next is undefined' );
        ok( $iter->is_exhausted, 'exhausted' );

    }

    subtest 'intial run' => sub {
        check( U() );
    };

    subtest 'rewind' => sub {
        ok( lives { $iter->rewind }, 'rewind' )
          or diag $@;
        check( 10 );
    };

    subtest 'reset' => sub {
        ok( lives { $iter->reset }, 'reset' )
          or diag $@;
        check( U() );
    };

    subtest 'interrupt, then rewind' => sub {
        $iterable = iseq( 10 );
        $iter     = ibuffer( $iterable, 3 );

        ok( $iter->drain( 3 ), [ 0, 1, 2 ], 'drain some' );
        ok( lives { $iter->rewind }, 'rewind' )
          or diag $@;

        check( 2 );
    };

    subtest 'interrupt, then reset' => sub {
        $iterable = iseq( 10 );
        $iter     = ibuffer( $iterable, 3 );

        ok( $iter->drain( 3 ), [ 0, 1, 2 ], 'drain some' );
        ok( lives { $iter->reset }, 'reset' )
          or diag $@;

        check( U() );
    };
};

subtest 'infinite buffer' => sub {

    my $iterable = iseq( 10 );
    my $iter     = ibuffer( $iterable );

    is( $iter->next, 0, 'first element' );
    ok( $iterable->is_exhausted, 'src is exhausted' );
    is( $iter->drain, [ 1 .. 10 ], 'drain' );
};

done_testing;
