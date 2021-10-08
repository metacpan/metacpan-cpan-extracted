#! perl

use Test2::V0;

use Iterator::Flex::Common qw[ iseq thaw ];

my @tests = (

    {
        name     => "end",
        args     => [3],
        expected => [
            [ undef, undef, 0 ],
            [ undef, 0,     1 ],
            [ 0,     1,     2 ],
            [ 1,     2,     3 ],
            [ 2,     3,     undef ],
            [ 3,     undef, undef ],
        ],
    },

    {
        name     => "begin, end",
        args     => [ 1, 5 ],
        expected => [
            [ undef, undef, 1 ],
            [ undef, 1,     2 ],
            [ 1,     2,     3 ],
            [ 2,     3,     4 ],
            [ 3,     4,     5 ],
            [ 4,     5,     undef ],
            [ 5,     undef, undef ]
        ],
    },

    {
        name     => "begin, end, step",
        args     => [ 1, 2.2, 0.5 ],
        expected => [
            [ undef, undef, 1 ],
            [ undef, 1,     1.5 ],
            [ 1,     1.5,   2 ],
            [ 1.5,   2,     undef ],
            [ 2,     undef, undef ],
        ],
    },

);

for my $test ( @tests ) {

    my ( $args, $expected ) = @{$test}{qw [ args expected ]};

    my $split = @$expected / 2;

    subtest $test->{name} => sub {

        subtest "iterator" => sub {

            my $iter = iseq( @$args );

            subtest "object properties" => sub {

                my @methods = ( 'rewind', 'freeze', 'prev', 'current' );
                isa_ok( $iter, ['Iterator::Flex::Base'],
                    "correct parent class" );
                can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
            };

            subtest "values" => sub {

                my @values
                  = map { [ $iter->prev, $iter->current, $iter->next ] }
                  1 .. @$expected;

                is( $iter->next, undef, "iterator exhausted" );
                ok( $iter->is_exhausted, "iterator exhausted (officially)" );

                is( \@values, $expected, "values are correct" )
                  or diag pp( \@values );
            };

            subtest "reset" => sub {
                try_ok { $iter->reset } "reset";

                my @values
                  = map { [ $iter->prev, $iter->current, $iter->next ] }
                  1 .. @$expected;

                is( $iter->next, undef, "iterator exhausted" );
                ok( $iter->is_exhausted, "iterator exhausted (officially)" );

                is( \@values, $expected, "values are correct" )
                  or diag pp( \@values );
            };

            subtest "rewind" => sub {

                $iter->reset;

                <$iter>;
                my ( $prev, $current )
                  = ( $expected->[1][0], $expected->[1][1] );
                is(
                    [ $iter->prev, $iter->current ],
                    [ $prev,       $current ],
                    "prev/current before rewind"
                );

                try_ok { $iter->rewind } "reset";

                is(
                    [ $iter->prev, $iter->current ],
                    [ $prev,       $current ],
                    "prev/current after rewind"
                );

                my @expected = @$expected;
                $expected[0] = [ $prev, $current, $expected->[0][-1] ];
                $expected[1]
                  = [ $current, $expected->[0][-1], $expected->[1][-1] ];

                my @values
                  = map { [ $iter->prev, $iter->current, $iter->next ] }
                  1 .. @$expected;

                is( $iter->next, undef, "iterator exhausted" );
                ok( $iter->is_exhausted, "iterator exhausted (officially)" );

                is( \@values, \@expected, "values are correct" )
                  or diag pp( \@values );
            };

        };

        subtest "freeze" => sub {

            my @values;
            my $freeze;
            subtest "setup iter and pull some values" => sub {

                my $iter = iseq( @$args );

                @values = map { [ $iter->prev, $iter->current, $iter->next ] }
                  1 .. $split;

                is(
                    \@values,
                    [ @{$expected}[ 0 .. $split - 1 ] ],
                    "values are correct"
                ) or diag pp( \@values );

                try_ok { $freeze = $iter->freeze } "freeze iterator";
            };

            subtest "thaw" => sub {
                my $iter;
                try_ok { $iter = thaw( $freeze ) } "thaw iterator";

                push @values,
                  map { [ $iter->prev, $iter->current, $iter->next ] }
                  $split + 1 .. @$expected;

                is( $iter->next, undef, "iterator exhausted" );
                ok( $iter->is_exhausted, "iterator exhausted (officially)" );

                is( \@values, $expected, "values are correct" )
                  or diag pp( \@values );
            };

        };

    };

}

done_testing;
