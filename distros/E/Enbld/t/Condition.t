#!perl

use strict;
use warnings;

use Test::More;

require_ok( 'Enbld::Condition' );

subtest 'getter method' => sub {
    subtest 'set version' => sub {
        my $condition = Enbld::Condition->new( version => '1.0' );
        is( $condition->version, '1.0', 'version' );
    };

    subtest 'no version' => sub {
        my $condition = Enbld::Condition->new;
        is( $condition->version, 'latest', 'version' );
    };

    subtest 'set make_test' => sub {
        my $condition = Enbld::Condition->new( make_test => 1 );
        is( $condition->make_test, 1, 'make test' );
    };

    subtest 'no make_test' => sub {
        my $condition = Enbld::Condition->new;
        is( $condition->make_test, undef, 'no make test' );
    };
};

subtest 'serialize' => sub {

    subtest 'defined serialize' => sub {
        my $condition = Enbld::Condition->new( make_test => 1 );

        is_deeply(
                $condition->serialize, { version => 'latest', make_test => 1 },
                'serialized version'
                );
    };

    subtest 'not defined serialize' => sub {
        my $condition = Enbld::Condition->new;

        is_deeply(
                $condition->serialize, { version => 'latest' },
                'serialized version'
                );
    };

};

subtest 'is_equal_to method' => sub {

    subtest 'condition check' => sub {
        my $condition = Enbld::Condition->new( version => 'latest' );
        my $param     = Enbld::Condition->new( version => 'latest' );

        is( $condition->is_equal_to( $param ), $condition, 'same version' );

        my $param_diff = Enbld::Condition->new( version => '1.0' );

        is( $condition->is_equal_to( $param_diff ), undef,
                'different version' );

    };

    subtest 'make_test check' => sub {
        my $condition = Enbld::Condition->new( make_test => 1 );
        my $param     = Enbld::Condition->new( make_test => 1 );

        is( $condition->is_equal_to( $param ), $condition, 'same make_test' );

        my $param_diff = Enbld::Condition->new( make_test => undef );

        is( $condition->is_equal_to( $param_diff ), undef,
                'different make_test' );

        my $condition_diff = Enbld::Condition->new( make_test => undef );

        is( $condition_diff->is_equal_to( $param ), undef,
                'different not equal pattern' );
    };

};

done_testing();
