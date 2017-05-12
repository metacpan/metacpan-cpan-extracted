use strict;
use warnings;

use Carp qw(croak);
use Log::Dispatch;
use IO::Select;
use IO::Socket::INET;
use Readonly;
use Socket qw(SOCK_DGRAM);

use Test::More tests => 3;

Readonly::Scalar my $PORT_NUMBER    => 9000;
Readonly::Scalar my $BIND_ADDRESS   => '127.0.0.1';
Readonly::Scalar my $MESSAGE_LENGTH => 8192;
Readonly::Scalar my $TIMEOUT        => 2;

sub perform_udp_listen {
    my ( $callback ) = @_;

    my $pid = fork;
    if($pid) {
        my $sock = IO::Socket::INET->new(
            Proto     => 'udp',
            Type      => SOCK_DGRAM,
            LocalHost => $BIND_ADDRESS,
            LocalPort => $PORT_NUMBER,
        );
        my $select = IO::Select->new;
        my $message;

        croak $! unless $sock;

        $select->add($sock);

        if($select->can_read($TIMEOUT)) {
            $sock->recv($message, $MESSAGE_LENGTH, 0);
        } else {
            kill TERM => $pid;
            $message = undef;
        }

        waitpid $pid, 0;

        return $message;
    } elsif(defined $pid) {
        sleep 1; # give the parent time to establish a listening socket

        $callback->();

        exit 0;
    } else {
        croak $!;
    }
}

sub expect_message {
    my ( $expected_message, $callback, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $message = perform_udp_listen($callback);

    if(defined $message) {
        is $message, $expected_message, $name;
    } else {
        fail 'timeout';
    }
}

sub expect_timeout {
    my ( $callback, $name ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $message = perform_udp_listen($callback);

    if(defined $message) {
        fail 'timeout expected';
    } else {
        pass $name;
    }
}

expect_message 'test message', sub {
    my $log = Log::Dispatch->new(
        outputs => [
            [ 'UDP',
               host      => $BIND_ADDRESS,
               port      => $PORT_NUMBER,
               min_level => 'info',
            ],
        ],
    );

    $log->info('test message');
};

expect_message "test message\n", sub {
    my $log = Log::Dispatch->new(
        outputs => [
            [ 'UDP',
               host      => $BIND_ADDRESS,
               port      => $PORT_NUMBER,
               min_level => 'info',
               newline   => 1,
            ],
        ],
    );

    $log->info('test message');
};

expect_timeout sub {
    my $log = Log::Dispatch->new(
        outputs => [
            [ 'UDP',
               host      => $BIND_ADDRESS,
               port      => $PORT_NUMBER,
               min_level => 'error',
               newline   => 1,
            ],
        ],
    );

    $log->info('test message');
};
