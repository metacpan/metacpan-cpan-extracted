package Linux::Event::HTTP;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.004';

1;

__END__

=head1 NAME

Linux::Event::HTTP - Linux-native integration of Unblock HTTP

=head1 SYNOPSIS

    use Linux::Event::Loop;
    use Linux::Event::HTTP::Server;

    my $loop = Linux::Event::Loop->new;
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, port => 8080,
        on_request => sub ($tx, $request) {
            $tx->respond(status => 200, body => "Hello\n");
        },
    );
    $loop->run;

=head1 DESCRIPTION

This distribution uses Unblock::HTTP as the framework-neutral protocol layer.
Server and Client support HTTP/1 over TCP/TLS, optional HTTP/2 over TLS,
and optional HTTP/3 over QUIC/TLS. They expose
real Unblock transactions and Uniform messages. Linux::Event owns sockets, TLS,
timers and backpressure; Unblock owns protocol behavior and client pooling.

No compatibility with the former public API is promised. HTTP/3 requires a
concrete listener address and is not yet supported as an H3-only server.
WebSocket and generic Upgrade/CONNECT handoff are implemented. Server shutdown
drains admitted requests and enforces a seconds-based grace deadline.
The native HTTP/1 input bridge is implemented. Measured HTTP/1 throughput
differs from the former implementation; this is a documented trade-off,
not a change in protocol capability.

See L<Linux::Event::HTTP::Server> and L<Linux::Event::HTTP::Client>
for the application API. No web framework or user-agent policy is provided.

=cut
