#! perl

use Test2::V0;
use experimental 'declared_refs';

use Iterator::Flex::Common qw[ imap iarray ];

subtest 'basic' => sub {

    my $iter = imap { $_ + 2 } iarray( [ 0, 10, 20 ] );

    subtest 'object properties' => sub {

        isa_ok( $iter, ['Iterator::Flex::Base'], 'correct parent class' );
        can_ok( $iter, [ 'reset', ], 'has reset' );
        is( $iter->can( 'freeze' ), undef, 'can not freeze' );
    };

    subtest 'scalar' => sub {
        my \@values = $iter->drain( 3 );
        is( \@values,    [ 2, 12, 22 ], 'values are correct' );
        is( $iter->next, undef,         'iterator exhausted' );
    };

};

subtest 'list' => sub {

    my $iter = imap { ( $_ .. $_ + 9 ) } iarray( [ 0, 10, 20 ] );

    subtest 'values' => sub {
        my \@values = $iter->drain( 15 );
        is( \@values, [ 0 .. 14 ], 'drain 15' );
        \@values = $iter->drain( 15 );
        is( \@values,    [ 15 .. 29 ], 'drain another 15' );
        is( $iter->next, undef,        'iterator exhausted' );
    };

};

subtest 'reset' => sub {

    my $iter = imap { $_ + 2 } iarray( [ 0, 10, 20 ] );

    subtest 'values' => sub {
        my \@values = $iter->drain( 3 );
        is( \@values,    [ 2, 12, 22 ], 'values are correct' );
        is( $iter->next, undef,         'iterator exhausted' );
    };

    try_ok { $iter->reset } 'reset';

    subtest 'reset values' => sub {
        my \@values = $iter->drain( 3 );
        is( \@values,    [ 2, 12, 22 ], 'values are correct' );
        is( $iter->next, undef,         'iterator exhausted' );
    };

};

subtest 'rewind' => sub {

    my $iter = imap { $_ + 2 } iarray( [ 0, 10, 20 ] );

    subtest 'values' => sub {
        my \@values = $iter->drain( 3 );
        is( \@values,    [ 2, 12, 22 ], 'values are correct' );
        is( $iter->next, undef,         'iterator exhausted' );
    };

    try_ok { $iter->rewind } 'rewind';

    subtest 'rewind values' => sub {
        my \@values = $iter->drain( 3 );
        is( \@values,    [ 2, 12, 22 ], 'values are correct' );
        is( $iter->next, undef,         'iterator exhausted' );
    };

};


done_testing;
