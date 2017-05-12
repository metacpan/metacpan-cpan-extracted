use strict;
use warnings;

use Test::More;
use Iterator::GroupedRange;

our @ds = ( 1 .. 61 );

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

    my $got = $iterator->next;
    is_deeply( $got, $expects,
        sprintf( 'next() return value (times: %d)', $times ) );
}

subtest 'call has_next() and next() (grouped: 10)' => sub {
    my $iterator = Iterator::GroupedRange->new( \@ds, 10, );

    is($iterator->rows, scalar @ds, 'rows ok');

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
    my $iterator = Iterator::GroupedRange->new( \@ds, 10, );

    is($iterator->rows, scalar @ds, 'rows ok');

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
    my $iterator = Iterator::GroupedRange->new( \@ds, 15, );

    is($iterator->rows, scalar @ds, 'rows ok');

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
    my $iterator = Iterator::GroupedRange->new( \@ds, 15, );

    is($iterator->rows, scalar @ds, 'rows ok');

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
    my $iterator = Iterator::GroupedRange->new( \@ds, 10, );

    is($iterator->rows, scalar @ds, 'rows ok');

    $iterator->append([ 62 .. 67 ]);
    $iterator->append(68 .. 75);

    my @appended = ( 62 .. 75 );

    is($iterator->rows, scalar @ds + scalar @appended, 'rows ok after called append() method');

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

subtest 'empty array' => sub {
    my $iterator = Iterator::GroupedRange->new([]);

    is($iterator->rows, 0, 'rows ok');
    ok !$iterator->next, 'next() return empty';
    ok !$iterator->has_next, 'has_next() return false';
};

subtest 'append after contract in empty array' => sub {
    my $iterator = Iterator::GroupedRange->new([]);

    is $iterator->append([1..10]), 10, 'append success';
    ok $iterator->has_next, 'has_next() return true';
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
