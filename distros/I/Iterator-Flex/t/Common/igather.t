#! perl

use Test2::V0;

use experimental 'signatures', 'declared_refs';

use Data::Dump 'pp';

use Iterator::Flex::Common qw[ igather iseq iarray izip imap ];

use Iterator::Flex::Gather::Constants ':all';

subtest 'examples' => sub {

    subtest 'complex' => sub {

        my $sub = sub ( $gathered, $state ) {

            return $gathered->@* && $gathered->[-1] == 100 ? GATHER_CYCLE_STOP : GATHER_CYCLE_ABORT
              if $state == GATHER_SRC_EXHAUSTED;

            return GATHER_ELEMENT_EXCLUDE | GATHER_CYCLE_CONTINUE
              if $_ % 2;

            return GATHER_ELEMENT_INCLUDE
              | ( $gathered->@* == 9 ? GATHER_CYCLE_RESTART : GATHER_CYCLE_CONTINUE );
        };

        subtest 'cycle stop on exhaustion' => sub {

            my $iter = iseq( 100 )->igather( $sub, { cycle_on_exhaustion => GATHER_CYCLE_CHOOSE } );

            my \@values = $iter->drain( 20 );
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

            my $iter = iseq( 102 )->igather(
                $sub,
                {
                    exhaustion          => 'throw',
                    cycle_on_exhaustion => GATHER_CYCLE_CHOOSE,
                } );

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

    subtest 'even numbers' => sub {
        my $sub = sub ( $gathered, $ ) {
            return GATHER_CYCLE_CONTINUE | (
                $_ % 2
                ? GATHER_ELEMENT_EXCLUDE
                : GATHER_ELEMENT_INCLUDE
            );
        };

        my \@values = iseq( 10 )->igather( $sub )->drain->[0];
        is( \@values, [ 0, 2, 4, 6, 8, 10 ] ) or diag pp \@values;
    };

    subtest 'batch into sized groups' => sub {

        subtest 'Add the current element' => sub {

            my $sub = sub ( $gathered, $state ) {
                return GATHER_ELEMENT_INCLUDE
                  | ( $gathered->@* == ( 2 - 1 ) ? GATHER_CYCLE_RESTART : GATHER_CYCLE_CONTINUE );
            };

            my \@values = iseq( 10 )->igather( $sub )->drain;
            is( \@values, [ [ 0, 1 ], [ 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 8, 9 ], [10] ] ) or diag pp \@values;
        };

        subtest 'cache current for next group' => sub {

            my $sub = sub ( $gathered, $state ) {
                return ( $gathered->@* == 2 )
                  ? GATHER_ELEMENT_CACHE | GATHER_CYCLE_RESTART
                  : GATHER_ELEMENT_INCLUDE | GATHER_CYCLE_CONTINUE;
            };

            my \@values = iseq( 10 )->igather( $sub )->drain;
            is( \@values, [ [ 0, 1 ], [ 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 8, 9 ], [10] ] ) or diag pp \@values;
        };


    };

    subtest 'groups based on key' => sub {

        my $sub = sub ( $gathered, $state ) {
            # if nothing in the list, charge ahead
            return GATHER_ELEMENT_INCLUDE | GATHER_CYCLE_CONTINUE
              if !$gathered->@*;

            # If the current element's key is the same as the last
            # gathered one, gather
            return GATHER_ELEMENT_INCLUDE | GATHER_CYCLE_CONTINUE
              if $gathered->[-1]{group} eq $_->{group};

            # have a different key, need to start a new group. cache
            # the current value to use in the next cycle
            return GATHER_ELEMENT_CACHE | GATHER_CYCLE_RESTART;
        };

        my \@values = izip( [ 'a', 'b', 'c' ], [ 3, 7, 5, ], )->imap(
            sub {
                my ( $group, $n ) = $_->@*;
                map { { group => $group, value => $_ } } 1 .. $n;
            } )->igather( $sub )->drain;

        is(
            \@values,
            array {
                item [ { group => 'a', value => 1 }, { group => 'a', value => 2 }, { group => 'a', value => 3 }, ];
                item [
                    { group => 'b', value => 1 },
                    { group => 'b', value => 2 },
                    { group => 'b', value => 3 },
                    { group => 'b', value => 4 },
                    { group => 'b', value => 5 },
                    { group => 'b', value => 6 },
                    { group => 'b', value => 7 },
                ];
                item [
                    { group => 'c', value => 1 },
                    { group => 'c', value => 2 },
                    { group => 'c', value => 3 },
                    { group => 'c', value => 4 },
                    { group => 'c', value => 5 },
                ];

                end;
            },
            'values'
        ) or diag pp \@values;
    };

};

subtest 'exhaustion' => sub {

    my $iter = igather {
        my ( undef, $state ) = @_;
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

for my $method ( 'reset', 'rewind' ) {

    subtest $method => sub {

        my $gather = sub ( $gathered, $state ) {
            return GATHER_ELEMENT_INCLUDE | ( $gathered->@* == 1 ? GATHER_CYCLE_STOP : GATHER_CYCLE_CONTINUE );
        };

        my @expected = ( [ 0, 1 ], [ 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 8, 9 ] );

        my $iter = iseq( 9 )->igather( $gather );

        local $ENV{DEBUG} = 1;
        for my $label ( 'first drain', 'second drain' ) {
            subtest $label => sub {
                my \@got = $iter->drain;
                is( \@got, \@expected ) or diag pp \@got;
                $iter->$method;
            };
        }

    };

}

done_testing;
