#! perl

use Test2::V0;
use Test::Lib;

use MyTest::Utils qw[ drain ];

use Iterator::Flex::Common qw[ iseq ifreeze thaw igrep ];
use Data::Dump 'pp';

sub _test_values {

    my $iter = shift;

    my %p = (
        pull_end   => 6,
        pull_begin => 1,
        begin      => 0,
        end        => 5,
        expected   => [
            [ undef, undef, 0, ],
            [ undef, 0,     1 ],
            [ 0,     1,     2 ],
            [ 1,     2,     3 ],
            [ 2,     3,     undef ],
            [ 3,     undef, undef ],
        ],
        @_
    );

    my @values = map { [ $iter->prev, $iter->current, $iter->next ] } $p{pull_begin} .. $p{pull_end};

    my @expected = ( @{ $p{expected} } )[ $p{begin} .. $p{end} ];

    is( \@values, \@expected, "values are correct" )
      or diag pp( \@values, \@expected );
}


subtest "basic" => sub {

    my $iter = ifreeze {} iseq( 3 );

    subtest "object properties" => sub {

        my @methods = ( 'rewind', 'prev', 'reset', 'current' );
        isa_ok( $iter, ['Iterator::Flex::Base'], "correct parent class" );
        can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
    };

    _test_values( $iter );
    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );

};

subtest "reset" => sub {

    my $iter = ifreeze {} iseq( 3 );

    drain( $iter, 4 );

    try_ok { $iter->reset } "reset";

    _test_values( $iter );
    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );
};

subtest "serialize" => sub {

    my @freeze;

    my $iter = ifreeze { push @freeze, $_ } iseq( 3 );

    drain( $iter, 4 );

    is( scalar @freeze, 5, "number of frozen states" );

    for ( 0 .. 4 ) {
        subtest(
            "thaw state $_" => sub {
                my $idx = shift;
                _test_values(
                    thaw( $freeze[$idx] ),
                    pull_begin => $idx + 2,
                    begin      => $idx + 1,
                );
            },
            $_
        );
    }

};

subtest "downstream can't freeze" => sub {
    my $err = dies {
        ifreeze {} igrep { %_ / 2 } iseq( 3 )
    };
    isa_ok( $err, ['Iterator::Flex::Failure::parameter'], "parameter exception" );
    like( "$err", qr/must provide a freeze method/, "correct message" );
};

done_testing;
