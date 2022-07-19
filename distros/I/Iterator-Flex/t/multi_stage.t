#! perl

use Test2::V0;
use Data::Dump 'pp';

use Iterator::Flex::Common qw[ igrep imap iarray ];

subtest "basic" => sub {

    my $iter = igrep { $_ >= 12 } imap { $_ + 2 } iarray( [ 0, 10, 20 ] );

    subtest "object properties" => sub {

        isa_ok( $iter, ['Iterator::Flex::Base'], "correct parent class" );
        can_ok( $iter, [ 'reset', ], "has reset" );
        is( $iter->can( 'freeze' ), undef, "can't freeze" );
    };

    subtest "values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( $iter->next, undef,      "iterator exhausted" );
        is( \@values,    [ 12, 22 ], "values are correct" )
          or diag pp( \@values );
    };
};

subtest "reset" => sub {

    my $iter = igrep { $_ >= 10 } imap { $_ + 2 } iarray( [ 0, 10, 20 ] );

    subtest "values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( $iter->next, undef,      "iterator exhausted" );
        is( \@values,    [ 12, 22 ], "values are correct" )
          or diag pp( \@values );
    };

    try_ok { $iter->reset } "reset";

    subtest "rewound values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( $iter->next, undef,      "iterator exhausted" );
        is( \@values,    [ 12, 22 ], "values are correct" )
          or diag pp( \@values );
    };

};


done_testing;
