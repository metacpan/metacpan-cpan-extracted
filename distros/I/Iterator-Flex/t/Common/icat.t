#! perl

use Test2::V0;
use Iterator::Flex::Common 'icat';
use experimental 'signatures';

sub iterator {
    icat [ 0, 10, 20 ], [ 30, 40, 50, 60 ];
}

sub test_values ( $iter ) {
    subtest "values" => sub {
        is( [ map { <$iter> } 1 .. 7 ], [ 0, 10, 20, 30, 40, 50, 60 ], "values are correct" );
        is( $iter->next,                U(),                           'beyond is undef' );
        is( $iter->is_exhausted,        T(),                           "iterator exhausted" );
    };
}


my $iter = iterator();

subtest "object properties" => sub {
    isa_ok( $iter, ['Iterator::Flex::Base'], "correct parent class" );
    can_ok( $iter, ['reset'],  'can reset' );
    can_ok( $iter, ['rewind'], 'can rewind' );
};

test_values( $iter );
my $prev = $iter->prev;

subtest "rewind" => sub {
    $iter->rewind;
    is( $iter->prev, $prev, "wrapped prev" );
    test_values( $iter );
};

subtest "reset" => sub {
    $iter->reset;
    is( $iter->prev, U(), "wrapped prev" );
    test_values( $iter );
};



done_testing;
