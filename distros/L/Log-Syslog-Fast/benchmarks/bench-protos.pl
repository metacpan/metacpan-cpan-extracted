#!/usr/bin/perl

# compare speeds of different transport protocols (tcp/udp/unix socket) and use cases

use strict;
use warnings;

use Time::HiRes 'time';
use File::Temp 'tempdir';
use IO::Select;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Log::Syslog::Constants ':all';
use POSIX 'strftime';

use Log::Syslog::Fast ':protos';

my $test_dir = tempdir(CLEANUP => 1);

my %servers = (
    tcp => sub {
        my $listener = IO::Socket::INET->new(
            Proto       => 'tcp',
            Type        => SOCK_STREAM,
            LocalHost   => 'localhost',
            LocalPort   => 0,
            Listen      => 5,
        ) or die $!;
        return StreamServer->new(
            listener    => $listener,
            proto       => LOG_TCP,
            address     => [$listener->sockhost, $listener->sockport],
        );
    },
    udp => sub {
        my $listener = IO::Socket::INET->new(
            Proto       => 'udp',
            Type        => SOCK_DGRAM,
            LocalHost   => 'localhost',
            LocalPort   => 0,
        ) or die $!;
        return DgramServer->new(
            listener    => $listener,
            proto       => LOG_UDP,
            address     => [$listener->sockhost, $listener->sockport],
        );
    },
    unix_stream => sub {
        my $listener = IO::Socket::UNIX->new(
            Local   => "$test_dir/stream",
            Type    => SOCK_STREAM,
            Listen  => 1,
        ) or die $!;
        return StreamServer->new(
            listener    => $listener,
            proto       => LOG_UNIX,
            address     => [$listener->hostpath, 0],
        );
    },
    unix_dgram => sub {
        my $listener = IO::Socket::UNIX->new(
            Local   => "$test_dir/dgram",
            Type    => SOCK_DGRAM,
            Listen  => 1,
        ) or die $!;
        return DgramServer->new(
            listener    => $listener,
            proto       => LOG_UNIX,
            address     => [$listener->hostpath, 0],
        );
    },
);

# strerror(3) messages on linux in the "C" locale are included below for reference

my @params = (LOG_AUTH, LOG_INFO, 'localhost', 'test');

sub bench(&$) {
    my $block = shift;
    my $name = shift;
    my $start = time();
    eval {
        $block->();
    };
    my $end = time();
    if ($@) {
        warn sprintf "$name failed after %.3fs ($@)\n", $end - $start;
    }
    else {
        warn sprintf "$name took %.3fs\n", $end - $start;
    }
}

for my $p (sort keys %servers) {
    my $listen = $servers{$p};

    # basic behavior
    bench {
        my $server = $listen->();
        my $logger = $server->connect(@params);
        my $receiver = $server->accept;

        for my $config (['without time'], ['with time', time()]) {
            my ($msg, @extra) = @$config;

            my $buf;
            for (1 .. 100000) {
                $logger->send($msg, @extra);
                $receiver->recv($buf, 1024);
            }
        }
    } "$p basic";

    # write accessors
    bench {

        my $server = $listen->();
        my $logger = $server->connect(@params);

        # ignore first connection for stream protos since reconnect is expected
        $server->accept();

        $logger->set_priority(LOG_NEWS, LOG_CRIT);
        $logger->set_sender('otherhost');
        $logger->set_name('test2');
        $logger->set_pid(12345);
        $logger->set_receiver($server->proto, $server->address);

        my $receiver = $server->accept;

        my $msg = "testing 3";

        my $buf;
        for (1 .. 100000) {
            $logger->send($msg);
            $receiver->recv($buf, 1024);
        }
    } "$p reconnect";

}
package ServerCreator;

sub new {
    my $class = shift;
    return bless {label => $_[0], listen => $_[1]}, $class;
}


sub listen {
    my $self = shift;
    $self->{listen}->();
}

package Server;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}
sub proto {
    my $self = shift;
    return $self->{proto};
}

sub address {
    my $self = shift;
    return @{ $self->{address} };
}

sub connect {
    my $self = shift;
    return Log::Syslog::Fast->new($self->proto, $self->address, @_);
}

sub close {
    my $self = shift;
    $self->{listener} = undef;
}

# remove unix socket file on server close
sub DESTROY {
    my $self = shift;
    if ($self->{address}[1] == 0) {
        unlink $self->{address}[0];
    }
}

package StreamServer;

use base 'Server';

sub accept {
    my $self = shift;
    my $receiver = $self->{listener}->accept;
    $receiver->blocking(0);
    return $receiver;
}

package DgramServer;

use base 'Server';

sub accept {
    my $self = shift;
    return $self->{listener};
}

# vim: filetype=perl
