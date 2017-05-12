use strict;
use warnings;

use Test::More;
use Iterator::GroupedRange;

our @ds = (
    [ 1 .. 5 ],
    [ 6 .. 15 ],
    [ 16 .. 30 ],
    [ 31 .. 32 ],
    [ 33 .. 37 ],
    [ 38 .. 58 ],
    [ 59 .. 61 ],
);

sub generator {
    my @ds = @_;
    return sub {
        @ds > 0 ? shift @ds : undef;
    };
}

sub test_is_last {
    my ( $iterator, $expects, $times ) = @_;
    is(
        $iterator->is_last,
        $expects,
        sprintf(
            'is_last is %s (times: %d)',
            $expects ? 'true' : 'false', $times
        )
    );
}

sub test_has_next {
    my ( $iterator, $expects, $times ) = @_;

    is(
        $iterator->has_next,
        $expects,
        sprintf(
            'has_next is %s (times: %d)',
            $expects ? 'true' : 'false', $times
        )
    );
}

sub test_next {
    my ( $iterator, $expects, $times ) = @_;

    is_deeply( scalar $iterator->next, $expects,
        sprintf( 'next() return value (times: %d)', $times ) );
}

subtest 'call has_next() and next() (grouped: 10)' => sub {
    my $iterator = Iterator::GroupedRange->new( generator(@ds), 10, );

    my @test_cases = (
        { is_last => 0, has_next => 1, next => [ 1 .. 10 ], },
        { is_last => 0, has_next => 1, next => [ 11 .. 20 ], },
        { is_last => 0, has_next => 1, next => [ 21 .. 30 ], },
        { is_last => 0, has_next => 1, next => [ 31 .. 40 ], },
        { is_last => 0, has_next => 1, next => [ 41 .. 50 ], },
        { is_last => 0, has_next => 1, next => [ 51 .. 60 ], },
        { is_last => 0, has_next => 1, next => [61], },
        { is_last => 1, has_next => 0, next => undef, },
    );

    for ( my $i = 0 ; $i < @test_cases ; $i++ ) {
        my $test_case = $test_cases[$i];
        test_is_last( $iterator, $test_case->{is_last}, $i );
        test_has_next( $iterator, $test_case->{has_next}, $i );
        test_next( $iterator, $test_case->{next}, $i );
    }

    done_testing;
};

subtest 'call only next() (grouped: 10)' => sub {
    my $iterator = Iterator::GroupedRange->new( generator(@ds), 10, );

    my @test_cases = (
        { is_last => 0, next => [ 1 .. 10 ], },
        { is_last => 0, next => [ 11 .. 20 ], },
        { is_last => 0, next => [ 21 .. 30 ], },
        { is_last => 0, next => [ 31 .. 40 ], },
        { is_last => 0, next => [ 41 .. 50 ], },
        { is_last => 0, next => [ 51 .. 60 ], },
        { is_last => 0, next => [61], },
        { is_last => 1, next => undef, },
    );

    for ( my $i = 0 ; $i < @test_cases ; $i++ ) {
        my $test_case = $test_cases[$i];
        test_is_last( $iterator, $test_case->{is_last}, $i );
        test_next( $iterator, $test_case->{next}, $i );
    }

    done_testing;
};

subtest 'call has_next() and next() (grouped: 15)' => sub {
    my $iterator = Iterator::GroupedRange->new( generator(@ds), 15, );

    my @test_cases = (
        { is_last => 0, has_next => 1, next => [ 1 .. 15 ], },
        { is_last => 0, has_next => 1, next => [ 16 .. 30 ], },
        { is_last => 0, has_next => 1, next => [ 31 .. 45 ], },
        { is_last => 0, has_next => 1, next => [ 46 .. 60 ], },
        { is_last => 0, has_next => 1, next => [61], },
        { is_last => 1, has_next => 0, next => undef, },
    );

    for ( my $i = 0 ; $i < @test_cases ; $i++ ) {
        my $test_case = $test_cases[$i];
        test_is_last( $iterator, $test_case->{is_last}, $i );
        test_has_next( $iterator, $test_case->{has_next}, $i );
        test_next( $iterator, $test_case->{next}, $i );
    }

    done_testing;
};

subtest 'call only next() (grouped: 15)' => sub {
    my $iterator = Iterator::GroupedRange->new( generator(@ds), 15, );

    my @test_cases = (
        { is_last => 0, next => [ 1 .. 15 ], },
        { is_last => 0, next => [ 16 .. 30 ], },
        { is_last => 0, next => [ 31 .. 45 ], },
        { is_last => 0, next => [ 46 .. 60 ], },
        { is_last => 0, next => [61], },
        { is_last => 1, next => undef, },
    );

    for ( my $i = 0 ; $i < @test_cases ; $i++ ) {
        my $test_case = $test_cases[$i];
        test_is_last( $iterator, $test_case->{is_last}, $i );
        test_next( $iterator, $test_case->{next}, $i );
    }

    done_testing;
};

subtest 'append' => sub {
    my $iterator = Iterator::GroupedRange->new( generator(@ds), 10, );

    $iterator->append([ 62 .. 67 ]);
    $iterator->append(68 .. 75);

    my @test_cases = (
        { is_last => 0, next => [ 1  .. 10 ], },
        { is_last => 0, next => [ 11 .. 20 ], },
        { is_last => 0, next => [ 21 .. 30 ], },
        { is_last => 0, next => [ 31 .. 40 ], },
        { is_last => 0, next => [ 41 .. 50 ], },
        { is_last => 0, next => [ 51 .. 60 ], },
        { is_last => 0, next => [ 61 .. 70 ], },
        { is_last => 0, next => [ 71 .. 75 ], },
        { is_last => 1, next => undef, },
    );

    for ( my $i = 0 ; $i < @test_cases ; $i++ ) {
        my $test_case = $test_cases[$i];
        test_is_last( $iterator, $test_case->{is_last}, $i );
        test_next( $iterator, $test_case->{next}, $i );
    }

    done_testing;
};

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
