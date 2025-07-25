#! perl

use Test2::V0;

use experimental 'signatures', 'declared_refs';

use Data::Dump 'pp';

use Iterator::Flex::Common qw[ igather iseq iarray ];

use Iterator::Flex::Gather::Constants ':all';

subtest 'synopsis' => sub {

    my $sub = sub ( $gathered, $state ) {

        return $gathered->@* && $gathered->[-1] == 100 ? GATHER_CYCLE_STOP : GATHER_CYCLE_ABORT
          if $state == GATHER_SRC_EXHAUSTED;

        return GATHER_ELEMENT_EXCLUDE | GATHER_CYCLE_CONTINUE
          if $_ % 2;

        return GATHER_ELEMENT_INCLUDE
          | ( $gathered->@* == 9 ? GATHER_CYCLE_RESTART : GATHER_CYCLE_CONTINUE );
    };

    subtest 'cycle stop on exhaustion' => sub {

        my $iter = iseq( 100 )->igather( $sub );

        my $limit = 0;
        my @values;
        push @values, <$iter> while ++$limit < 20 && !$iter->is_exhausted;

        is( $limit, 7, 'correct number of iterations' );

        is(
            \@values,
            [
                [ 0,  2,  4,  6,  8,  10, 12, 14, 16, 18 ],
                [ 20, 22, 24, 26, 28, 30, 32, 34, 36, 38 ],
                [ 40, 42, 44, 46, 48, 50, 52, 54, 56, 58 ],
                [ 60, 62, 64, 66, 68, 70, 72, 74, 76, 78 ],
                [ 80, 82, 84, 86, 88, 90, 92, 94, 96, 98 ],
                [100],
            ],
            'values'
        );
    };

    subtest 'cycle abort on exhaustion' => sub {

        my $iter = iseq( 102 )->igather( $sub, { exhaustion => 'throw' } );

        my $limit = 0;
        my @values;
        isa_ok( dies { push @values, <$iter> while ++$limit < 20; },
            ['Iterator::Flex::Failure::Exhausted'], 'exhausted' );

        is( $limit, 6, 'correct number of iterations' );

        is(
            \@values,
            array {
                item [ 0,  2,  4,  6,  8,  10, 12, 14, 16, 18 ];
                item [ 20, 22, 24, 26, 28, 30, 32, 34, 36, 38 ];
                item [ 40, 42, 44, 46, 48, 50, 52, 54, 56, 58 ];
                item [ 60, 62, 64, 66, 68, 70, 72, 74, 76, 78 ];
                item [ 80, 82, 84, 86, 88, 90, 92, 94, 96, 98 ];
                end;
            },
            'values'
        ) or diag pp \@values;
    };


};

subtest "exhaustion" => sub {

    my $iter = igather {
        my ( undef, $state ) = @_;

        return GATHER_CYCLE_STOP if $state == GATHER_SRC_EXHAUSTED;

        return $_ >= 10
          ? GATHER_ELEMENT_INCLUDE | GATHER_CYCLE_CONTINUE
          : GATHER_ELEMENT_EXCLUDE | GATHER_CYCLE_CONTINUE

    }
    [ 0, 10, 20 ];

    subtest 'object properties' => sub {
        isa_ok( $iter, ['Iterator::Flex::Base'], 'correct parent class' );
        can_ok( $iter, [ 'reset', ], 'has reset' );
    };

    subtest 'values' => sub {
        my @values;
        push @values, <$iter>;
        is( \@values,    [ [ 10, 20 ] ], 'values are correct' );
        is( $iter->next, undef,          'iterator exhausted' );
    };
};

subtest 'reset' => sub {

    my $gather = sub ( $gathered, $state ) {
        return GATHER_CYCLE_STOP if $state == GATHER_SRC_EXHAUSTED;
        return GATHER_ELEMENT_INCLUDE | ( $gathered->@* == 1 ? GATHER_CYCLE_STOP : GATHER_CYCLE_CONTINUE );
    };

    my @expected = ( [ 0, 1 ], [ 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 8, 9 ] );

    my $iter = iseq( 10 )->igather( $gather );

    is( $iter->drain, \@expected, 'first drain' );

    $iter->reset;
    is( $iter->drain, \@expected, 'second drain' );

};

done_testing;
