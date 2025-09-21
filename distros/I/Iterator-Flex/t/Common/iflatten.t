#! perl

use Test2::V0;

use feature 'signatures', 'state';

use Data::Dump 'pp';

use Iterator::Flex::Common qw( iflatten iseq );

sub test_iter ( $iter, $prev ) {

    subtest first => sub {
        is( $iter->next,    1,     'next' );
        is( $iter->current, 1,     'current' );
        is( $iter->prev,    $prev, 'prev' );
    };

    subtest second => sub {
        is( $iter->next,    2, 'next' );
        is( $iter->current, 2, 'current' );
        is( $iter->prev,    1, 'prev' );
    };

    my $got = $iter->drain;
    is(
        $got,
        array {
            item $_ for 3 .. 4;
            item $_ for 0 .. 5;
            item hash {
                field a => 2;
                field b => 1;
                end;
            };
            item $_ for 0 .. 3;
            item array { item $_ for 5, 6; end; };
            item 7;
            item array { item $_ for 8, 9; end; };
            end;
        },
        'rest'
    ) or diag pp $got;

    is( $iter->current, undef,    'current' );
    is( $iter->prev,    [ 8, 9 ], 'prev' );

}

subtest 'basic' => sub {

    my $iter = iflatten(    #
        [
            1,              #
            [ 2, 3, 4 ],
            iseq( 5 ),
            { a => 2, b => 1 },
            iseq( 3 ),
            [   [ 5, 6 ],
                7,
                [ 8, 9 ],
            ],
        ],
    );

    test_iter( $iter, U() );

};

subtest 'rewind' => sub {

    my $iter = iflatten(    #
        [
            1,              #
            [ 2, 3, 4 ],
            iseq( 5 ),
            { a => 2, b => 1 },
            iseq( 3 ),
            [   [ 5, 6 ],
                7,
                [ 8, 9 ],
            ],
        ],
    );

    subtest first => sub {
        is( $iter->next,    1,   'next' );
        is( $iter->current, 1,   'current' );
        is( $iter->prev,    U(), 'prev' );
    };

    subtest 'rewind' => sub {
        $iter->rewind;
        is( $iter->current, 1, 'current' );
        test_iter( $iter, 1 );
    };

    subtest 'no rewind' => sub {

        my $iter0 = sub {
            state $value = 1;
            my $old = $value;
            $value = undef;
            return $old;
        };

        my $iter1 = iflatten( [ [ 1, 2 ], \&$iter0 ] );
        $iter1->rewind;
        isa_ok( dies { $iter1->drain }, ['Iterator::Flex::Failure::Unsupported'], 'dies' );
    };

};

subtest 'reset' => sub {

    my $iter = iflatten(    #
        [
            1,              #
            [ 2, 3, 4 ],
            iseq( 5 ),
            { a => 2, b => 1 },
            iseq( 3 ),
            [   [ 5, 6 ],
                7,
                [ 8, 9 ],
            ],
        ],
    );

    subtest first => sub {
        is( $iter->next,    1,   'next' );
        is( $iter->current, 1,   'current' );
        is( $iter->prev,    U(), 'prev' );
    };

    subtest 'reset' => sub {
        $iter->reset;
        is( $iter->current, U(), 'current' );
        test_iter( $iter, U() );
    };

    subtest 'no reset' => sub {

        my $iter0 = sub {
            state $value = 1;
            my $old = $value;
            $value = undef;
            return $old;
        };

        my $iter1 = iflatten( [ [ 1, 2 ], \&$iter0 ] );
        $iter1->reset;
        isa_ok( dies { $iter1->drain }, ['Iterator::Flex::Failure::Unsupported'], 'dies' );
    };


};


done_testing;

1;
