#! perl

use Test2::V0;

use Iterator::Flex::Common qw[ igrep iarray iterator ];

subtest "basic" => sub {

    my $iter = igrep { $_ >= 10 } iarray( [ 0, 10, 20 ] );

    subtest "object properties" => sub {

        isa_ok( $iter, ['Iterator::Flex::Base'], "correct parent class" );
        can_ok( $iter, [ 'reset', ], "has reset" );
        is( $iter->can( 'freeze' ), undef, "can't freeze" );
    };

    subtest "values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( \@values, [ 10, 20 ], "values are correct" );
        is( $iter->next, undef, "iterator exhausted" );
    };
};

subtest "reset" => sub {

    {
        my $iter = igrep { $_ >= 10 } iterator { undef };
        isa_ok( dies { $iter->reset }, [ 'Iterator::Flex::Failure::Unsupported' ], 'unsupported' );
    }


    my $iter = igrep { $_ >= 10 } iarray( [ 0, 10, 20 ] );

    subtest "values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( \@values, [ 10, 20 ], "values are correct" );
        is( $iter->next, undef, "iterator exhausted" );
    };

    try_ok { $iter->reset } "reset";

    subtest "rewound values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( \@values, [ 10, 20 ], "values are correct" );
        is( $iter->next, undef, "iterator exhausted" );
    };

};


done_testing;
