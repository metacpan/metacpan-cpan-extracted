#! perl

use Test2::V0;
use Test::Lib;

use feature 'signatures';

use Iterator::Flex::Common qw[ itake iseq thaw ];
use Data::Dump 'pp';


subtest 'partial take' => sub {

    subtest 'lazy' => sub {

        my $src  = iseq( 10 );
        my $iter = itake( $src, 5 );

        my sub check ( $prev ) {

            is( $iter->next, 0, 'first element' );
            is( $src->next,  1, 'un-taked element in src' );

            is( $iter->current, 0,     'current' );
            is( $iter->prev,    $prev, 'prev' );

            is( $iter->next,    2, 'next' );
            is( $iter->current, 2, 'current' );
            is( $iter->prev,    0, 'prev' );

            is( $iter->drain, [ 3 .. 5 ], 'remaining elements' );

            is( $iter->next,         U(), 'next is undefined' );
            is( $iter->is_exhausted, !!1, 'exhausted' );
        }

        subtest 'initial' => sub {
            check( U() );
        };

        subtest 'rewind after exhaustion' => sub {
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 5 );
        };

        subtest 'reset after exhaustion' => sub {
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };


        subtest 'rewind before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 5 );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 2 );
        };

        subtest 'reset before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 5 );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };

    };


    subtest 'not lazy' => sub {

        my $src  = iseq( 10 );
        my $iter = itake( $src, 5, { lazy => !!0 } );

        my sub check ( $prev ) {

            is( $iter->next, 0, 'first element' );
            is( $src->next,  5, 'un-taked element in src' );

            is( $iter->current, 0,     'current' );
            is( $iter->prev,    $prev, 'prev' );

            is( $iter->next,    1, 'next' );
            is( $iter->current, 1, 'current' );
            is( $iter->prev,    0, 'prev' );

            is( $iter->drain, [ 2 .. 4 ], 'remaining elements' );

            is( $iter->next,         U(), 'next is undefined' );
            is( $iter->is_exhausted, !!1, 'exhausted' );
        }

        subtest 'initial' => sub {
            check( U() );
        };

        subtest 'rewind after exhaustion' => sub {
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 4 );
        };

        subtest 'reset after exhaustion' => sub {
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };


        subtest 'rewind before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 5, { lazy => !!0 } );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 2 );
        };

        subtest 'reset before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 5, { lazy => !!0 } );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };

    };


};

subtest 'complete take' => sub {

    subtest 'lazy' => sub {

        my $src  = iseq( 10 );
        my $iter = itake( $src, 11 );

        my sub check ( $prev ) {

            is( $iter->next, 0, 'first element' );
            is( $src->next,  1, 'un-taked element in src' );

            is( $iter->current, 0,     'current' );
            is( $iter->prev,    $prev, 'prev' );

            is( $iter->next,    2, 'next' );
            is( $iter->current, 2, 'current' );
            is( $iter->prev,    0, 'prev' );

            is( $iter->drain, [ 3 .. 10 ], 'remaining elements' );

            is( $iter->next,         U(), 'next is undefined' );
            is( $iter->is_exhausted, !!1, 'exhausted' );
        }

        subtest 'initial' => sub {
            check( U() );
        };

        subtest 'rewind after exhaustion' => sub {
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 10 );
        };

        subtest 'reset after exhaustion' => sub {
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };


        subtest 'rewind before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 11 );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 2 );
        };

        subtest 'reset before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 11 );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };

    };


    subtest 'not lazy' => sub {

        my $src  = iseq( 10 );
        my $iter = itake( $src, 11, { lazy => !!0 } );

        my sub check ( $prev ) {

            is( $iter->next, 0, 'first element' );

            is( $src->next, U(), 'no -un-taked element in src' );
            ok( $src->is_exhausted, 'src is exhausted' );

            is( $iter->current, 0,     'current' );
            is( $iter->prev,    $prev, 'prev' );

            is( $iter->next,    1, 'next' );
            is( $iter->current, 1, 'current' );
            is( $iter->prev,    0, 'prev' );

            is( $iter->drain, [ 2 .. 10 ], 'remaining elements' );

            is( $iter->next,         U(), 'next is undefined' );
            is( $iter->is_exhausted, !!1, 'exhausted' );
        }

        subtest 'initial' => sub {
            check( U() );
        };

        subtest 'rewind after exhaustion' => sub {
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 10 );
        };

        subtest 'reset after exhaustion' => sub {
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };


        subtest 'rewind before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 11, { lazy => !!0 } );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->rewind }, 'rewind' )
              or diag $@;
            check( 2 );
        };

        subtest 'reset before exhaustion' => sub {
            $src  = iseq( 10 );
            $iter = itake( $src, 11, { lazy => !!0 } );

            is( $iter->drain( 3 ), [ 0 .. 2 ], 'take' );
            ok( lives { $iter->reset }, 'rewind' )
              or diag $@;
            check( U() );
        };
    };
};

done_testing;
