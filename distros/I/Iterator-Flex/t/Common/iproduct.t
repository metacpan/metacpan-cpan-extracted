#! perl

use Test2::V0;
use Test::Lib;

use MyTest::Utils qw[ drain ];

use Iterator::Flex::Common qw[ iproduct thaw ];
use Data::Dump 'pp';

sub _test_values {

    my $iter  = shift;
    my $npull = shift || 6;
    my ( $begin, $end );

    defined( $begin = shift ) or $begin = 0;
    defined( $end   = shift ) or $end   = 5;

    my @values = map { [ $iter->current, $iter->next ] } 1 .. $npull;

    my @expected = (
        [ undef, [ 0, 2 ] ],
        [ [ 0, 2 ], [ 0, 3 ] ],
        [ [ 0, 3 ], [ 1, 2 ] ],
        [ [ 1, 2 ], [ 1, 3 ] ],
        [ [ 1, 3 ], undef ],
        [ undef, undef ],
    )[ $begin .. $end ];

    is( \@values, \@expected, "values are correct" )
      or diag pp( \@values );
}

subtest "basic" => sub {

    subtest "unlabeled iterators" => sub {
        my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

        subtest "object properties" => sub {

            my @methods = ( 'rewind', 'freeze' );
            isa_ok( $iter, ['Iterator::Flex::Base'], "correct parent class" );
            can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
        };

        subtest "values" => sub {

            _test_values( $iter );
            is( $iter->next, undef, "iterator exhausted" );
            ok( $iter->is_exhausted, "iterator exhausted (officially)" );
        };

    };

    subtest "labeled iterators" => sub {
        my $iter = iproduct( a => [ 0, 1 ], b => [ 2, 3 ] );

        subtest "values" => sub {
            my @values = map { [ $iter->current, $iter->next ] } 1 .. 6;

            is( $iter->next, undef, "iterator exhausted" );
            ok( $iter->is_exhausted, "iterator exhausted (officially)" );

            is(
                \@values,
                [
                    [ undef, { a => 0, b => 2 } ],
                    [ { a => 0, b => 2 }, { a => 0, b => 3 } ],
                    [ { a => 0, b => 3 }, { a => 1, b => 2 } ],
                    [ { a => 1, b => 2 }, { a => 1, b => 3 } ],
                    [ { a => 1, b => 3 }, undef ],
                    [ undef, undef ],
                ],
                "values are correct"
            ) or diag pp( \@values );

        };

    };

};


subtest "rewind" => sub {

    my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

    drain( $iter, 4 );

    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );

    try_ok { $iter->rewind } "rewind";


    _test_values( $iter );
    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );

};

subtest "only one" => sub {

    my $iter = iproduct( [ 1 ], [ 2, 3 ] );

    my @values = map { [ $iter->current, $iter->next ] } 1 .. 3;

            is(
                \@values,
               array {
                   item [ undef, [ 1, 2] ];
                   item [ [1,2], [ 1, 3] ];
                   item [ [1,3], undef ];
                   end;
               },
                "values are correct"
            ) or diag pp( \@values );


};

subtest "freeze" => sub {

    my $freeze;

    subtest "unlabeled" => sub {

        subtest "setup iter and pull some values" => sub {
            my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

            _test_values( $iter, 2, 0, 1 );

            try_ok { $freeze = $iter->freeze } "freeze iterator";
        };

        subtest "thaw" => sub {
            my $iter;
            try_ok { $iter = thaw( $freeze ) } "thaw iterator";

            _test_values( $iter, 4, 2, 5 );

            is( $iter->next, undef, "iterator exhausted" );
            ok( $iter->is_exhausted, "iterator exhausted (officially)" );
        };

    };

    subtest "labeled" => sub {

        subtest "setup iter and pull some values" => sub {
            my $iter = iproduct( a => [ 0, 1 ], b => [ 2, 3 ] );

            my @values = map { [ $iter->current, $iter->next ] } 1 .. 2;

            is(
                \@values,
                [
                    [ undef, { a => 0, b => 2 } ],
                    [ { a => 0, b => 2 }, { a => 0, b => 3 } ],
                ],
                "values are correct"
            ) or diag pp( \@values );


            try_ok { $freeze = $iter->freeze } "freeze iterator";
        };

        subtest "thaw" => sub {
            my $iter;
            try_ok { $iter = thaw( $freeze ) } "thaw iterator";

            my @values = map { [ $iter->current, $iter->next ] } 3 .. 6;

            is(
                \@values,
                [
                    [ { a => 0, b => 3 }, { a => 1, b => 2 } ],
                    [ { a => 1, b => 2 }, { a => 1, b => 3 } ],
                    [ { a => 1, b => 3 }, undef ],
                    [ undef, undef ],
                ],
                "values are correct"
            ) or diag pp( \@values );


            is( $iter->next, undef, "iterator exhausted" );
            ok( $iter->is_exhausted, "iterator exhausted (officially)" );
        };

    };


};

done_testing;
