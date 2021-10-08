#! perl

use Test2::V0;
use Test::Lib;

use MyTest::Utils qw[ drain ];

use Iterator::Flex::Common qw[ icache iarray thaw ];
use Data::Dump 'pp';

sub _test_values {

    my $iter = shift;

    my %p = (
        npull    => 5,
        begin    => 0,
        end      => 4,
        expected => [
            [ undef, undef, 0 ],
            [ undef, 0,     10 ],
            [ 0,     10,    20 ],
            [ 10,    20,    undef ],
            [ 20,    undef, undef ],
        ],
        @_
    );


    my @values
      = map { [ $iter->prev, $iter->current, $iter->next ] } 1 .. $p{npull};

    my @expected = ( @{ $p{expected} } )[ $p{begin} .. $p{end} ];

    is( \@values, \@expected, "values are correct" ) or diag pp( \@values );
}

subtest "basic" => sub {

    my $iter = icache( iarray( [ 0, 10, 20 ] ) );

    subtest "object properties" => sub {

        my @methods = ( 'rewind', 'freeze', 'prev', 'current' );
        isa_ok( $iter, ['Iterator::Flex::Base'], "correct parent class" );
        can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
    };

    subtest "values" => sub {
        _test_values( $iter );
        is( $iter->next, undef, "iterator exhausted" );
        ok( $iter->is_exhausted, "iterator exhausted (officially)" );
    };
};

subtest "reset" => sub {


    subtest "fully drain iterator" => sub {
        my $iter = icache( iarray( [ 0, 10, 20 ] ) );

        drain( $iter, 3 );

        try_ok { $iter->reset } "reset";

        _test_values( $iter );
        is( $iter->next, undef, "iterator exhausted" );
        ok( $iter->is_exhausted, "iterator exhausted (officially)" );
    };

    subtest "partially drain iterator" => sub {
        my $iter = icache( iarray( [ 0, 10, 20 ] ) );

        <$iter>;

        try_ok { $iter->reset } "reset";

        _test_values( $iter );
        is( $iter->next, undef, "iterator exhausted" );
        ok( $iter->is_exhausted, "iterator exhausted (officially)" );
    };
};

subtest "rewind" => sub {


    subtest "fully drain iterator" => sub {
        my $iter = icache( iarray( [ 0, 10, 20 ] ) );

        drain( $iter, 3 );

        is(
            [ $iter->prev, $iter->current ],
            [ 20,          undef ],
            "prev/current before rewind"
        );

        try_ok { $iter->rewind } "rewind";

        is(
            [ $iter->prev, $iter->current ],
            [ 20,          undef ],
            "prev/current after rewind"
        );

        _test_values(
            $iter,
            expected => [
                [ 20,    undef, 0 ],
                [ undef, 0,     10 ],
                [ 0,     10,    20 ],
                [ 10,    20,    undef ],
                [ 20,    undef, undef ],
            ],
        );
        is( $iter->next, undef, "iterator exhausted" );
        ok( $iter->is_exhausted, "iterator exhausted (officially)" );
    };

    subtest "partially drain iterator" => sub {
        my $iter = icache( iarray( [ 0, 10, 20 ] ) );

        <$iter> for 1 .. 2;

        is(
            [ $iter->prev, $iter->current ],
            [ 0,           10 ],
            "prev/current before rewind"
        );

        try_ok { $iter->rewind } "rewind";

        is(
            [ $iter->prev, $iter->current ],
            [ 0,           10 ],
            "prev/current after rewind"
        );

        _test_values(
            $iter,
            expected => [
                [ 0,  10,    0 ],
                [ 10, 0,     10 ],
                [ 0,  10,    20 ],
                [ 10, 20,    undef ],
                [ 20, undef, undef ],
            ],
        );

        is( $iter->next, undef, "iterator exhausted" );
        ok( $iter->is_exhausted, "iterator exhausted (officially)" );
    };
};


subtest "freeze" => sub {

    my @values;
    my $freeze;

    {
        my $iter = icache( iarray( [ 0, 10, 20 ] ) );
        _test_values( $iter, npull => 1, begin => 0, end => 0 );

        try_ok { $freeze = $iter->freeze } "freeze iterator";
    }

    {
        my $iter;
        try_ok { $iter = thaw( $freeze ) } "thaw iterator";

        _test_values( $iter, npull => 4, begin => 1, end => 4 );
        is( $iter->next, undef, "iterator exhausted" );
        ok( $iter->is_exhausted, "iterator exhausted (officially)" );
    };

    {
        my $iter = icache( iarray( [ 0, 10, 20 ] ) );

        drain( $iter, 3 );

        try_ok { $freeze = $iter->freeze } "freeze iterator";
        try_ok { $iter   = thaw( $freeze ) } "thaw iterator";

        ok( $iter->is_exhausted,
            "thawed, frozen, exhausted iterator is still exhausted" );

    }

};

done_testing;
