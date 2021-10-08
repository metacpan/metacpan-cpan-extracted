#! perl

use Test2::V0;

use Iterator::Flex::Common qw[ icycle thaw ];
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
            [ 10,    20,    0 ],
            [ 20,    0,     10 ],
        ],
        @_
    );


    my @values
      = map { [ $iter->prev, $iter->current, $iter->next ] } 1 .. $p{npull};

    my @expected = ( @{ $p{expected} } )[ $p{begin} .. $p{end} ];

    is( \@values, \@expected, "values are correct" ) or diag pp( \@values );
}

subtest "basic" => sub {

    my $iter = icycle( [ 0, 10, 20 ] );

    subtest "object properties" => sub {

        my @methods = ( 'rewind', 'freeze', 'prev', 'current' );
        isa_ok( $iter, ['Iterator::Flex::Base'], "correct parent class" );
        can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
    };

    subtest "values" => sub {
        _test_values( $iter );
    };
};

subtest "reset" => sub {


    subtest "partially drain iterator" => sub {
        my $iter = icycle( [ 0, 10, 20 ] );

        <$iter>;

        try_ok { $iter->reset } "reset";

        _test_values( $iter );
    };
};

subtest "rewind" => sub {


    subtest "partially drain iterator" => sub {
        my $iter = icycle( [ 0, 10, 20 ] );

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
                [ 0,  10, 0 ],
                [ 10, 0,  10 ],
                [ 0,  10, 20 ],
                [ 10, 20, 0 ],
                [ 20, 0,  10 ],
            ],
        );
    };
};


subtest "freeze" => sub {

    my @values;
    my $freeze;

    {
        my $iter = icycle( [ 0, 10, 20 ] );
        _test_values( $iter, npull => 1, begin => 0, end => 0 );

        try_ok { $freeze = $iter->freeze } "freeze iterator";
    }

    {
        my $iter;
        try_ok { $iter = thaw( $freeze ) } "thaw iterator";

        _test_values( $iter, npull => 4, begin => 1, end => 4 );
    };

};

done_testing;
