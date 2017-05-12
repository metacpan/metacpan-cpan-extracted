#!perl

use strict;
use warnings;

use Test::More tests => 27;
use AnyEvent;
use Juno::Check::Ping;

# TODO: check the on_before
# TODO: check an illegal packet

my %checks = (
    # single packets, success
    HostA => [ [ 'OK', 0.001 ] ],

    # multiple packets, one is okay
    HostB => [
        [ 'TIMEOUT', 0.02  ],
        [ 'TIMEOUT', 0.03  ],
        [ 'OK',      0.001 ],
        [ 'TIMEOUT', 0.02  ],
    ],

    # multiple packets, none are okay
    HostC => [
        [ 'TIMEOUT',   0.02 ],
        [ 'TIMEOUT',   0.03 ],
        [ 'MALFORMED', 0.02 ],
    ],
);

{
    package FakePinger;
    use Moo;
    has timeout  => ( is => 'ro' );
    has interval => ( is => 'ro' );
    sub ping {
        my ( $self, $host, $num, $cb ) = @_;
        ::isa_ok( $self, 'FakePinger' );
        ::ok( exists $checks{$host}, "$host exists (FakePinger)" );
        ::cmp_ok( $num, '==', 1, 'Correct number of packets requested' );
        $cb->( $checks{$host} );
    }
}

sub check {
    my ( $checker, $host, $answer ) = @_;
    isa_ok( $checker, 'Juno::Check::Ping' );
    ok( exists $checks{$host}, "Host $host exists" );
    is_deeply(
        $answer, $checks{$host}, "Correct answer for $host"
    );
}

my $cv = AnyEvent->condvar;

# three hosts, each taking two callbacks
# once for result, and one for either success or fail
$cv->begin for 1 .. ( 3 * 2 );

use Juno;
use Juno::Check::Ping;
my $juno = Juno->new(
    checks        => {},
    check_objects => [
        Juno::Check::Ping->new(
            pinger     => FakePinger->new,
            hosts      => [ qw<HostA HostB HostC> ],
            on_success => sub {
                check(@_);
                $cv->end;
            },

            on_fail => sub {
                check(@_);
                $cv->end;
            },

            on_result => sub {
                check(@_);
                $cv->end;
            },
        ),
    ],
);

# start check
$juno->run;

# wait for test_number*scalar(@array) points to resolve
$cv->recv;

