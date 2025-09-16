#! perl

# ABSTRACT: test translation of imported iterators

use strict;
use warnings;

use Test2::V0;

use Iterator::Flex::Common 'iterator';
use Iterator::Flex::Utils ':ExhaustionActions', ':SignalParameters';

use constant MESSAGE    => 'danger will robinson';
use constant MESSAGE_QR => qr/@{[MESSAGE]}/;

subtest 'default' => sub {
    my @data = ( 1 .. 10 );
    my @got;
    my $iter;

    $iter = iterator { $iter->signal_error( MESSAGE ) if $data[0] == 5; shift @data }
    +{ +( EXHAUSTION ) => [ +( RETURN ) => 11 ] };

    my $error;
    isa_ok(
        $error = dies {
            while ( ( my $data = $iter->() ) != 11 ) { push @got, $data }
        },
        'Iterator::Flex::Failure::Error',
    );

    is( $error->msg, MESSAGE, 'message' );

    ok( $iter->is_error, 'error flag' );
    is( \@got, [ 1 .. 4 ], 'got data' );
};

subtest 'custom' => sub {

    my @data = ( 1 .. 10 );
    my @got;
    my $iter;

    $iter = iterator { $iter->signal_error( MESSAGE ) if $data[0] == 5; shift @data }
    +{
        +( EXHAUSTION ) => [ +( RETURN ) => 11 ],
        +( ERROR )      => [ +( THROW )  => sub { die @_ }, ],
    };

    like(
        dies {
            while ( ( my $data = $iter->() ) != 11 ) { push @got, $data }
        },
        MESSAGE_QR,
        'throws with correct message'
    );

    ok( $iter->is_error, 'error flag' );
    is( \@got, [ 1 .. 4 ], 'got data' );
};

done_testing;
