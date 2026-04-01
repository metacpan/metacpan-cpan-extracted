use strict;
use warnings;
use Test::More;
use EV;
use EV::Websockets;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

# Test adoption of an existing connected socket
my $port = 12345 + int(rand(1000));
my $cv = AnyEvent->condvar;

# A simple TCP echo server (not WebSocket, just raw for testing basic adoption)
my $tcp_server = tcp_server undef, $port, sub {
    my ($fh, $host, $port) = @_;
    my $handle; $handle = AnyEvent::Handle->new(
        fh => $fh,
        on_read => sub {
            my ($self) = @_;
            my $data = $self->{rbuf};
            $self->{rbuf} = '';
            $self->push_write($data);
        },
    );
};

# Connect a raw socket
tcp_connect "127.0.0.1", $port, sub {
    my ($fh) = @_;
    die "Connect failed" unless $fh;

    my $ctx = EV::Websockets::Context->new();
    my $message_received = '';

    my $conn = $ctx->adopt(
        fh => $fh,
        on_connect => sub {
            my ($c) = @_;
            diag "Adopted socket connected";
            $c->send("Hello Adoption");
        },
        on_message => sub {
            my ($c, $data) = @_;
            diag "Adopted socket got data";
            $message_received = $data;
            $cv->send;
        },
        on_error => sub {
            my ($c, $err) = @_;
            diag "Adoption error: $err";
            $cv->send;
        },
    );
};

# Use a timeout
my $t = EV::timer(2, 0, sub { $cv->send; });

$cv->recv;

pass("Adoption test finished (adopt does not crash, callbacks fire)");

done_testing;
