package Linux::Event::WebSocket;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.002';

1;

__END__

=head1 NAME

Linux::Event::WebSocket - WebSocket client and server for Linux::Event

=head1 SYNOPSIS

    use Linux::Event::WebSocket::Server;
    use Linux::Event::WebSocket::Client;

=head1 DESCRIPTION

C<Linux::Event::WebSocket> provides callback-first WebSocket client and server
support on top of Linux::Event.

Linux::Event owns the live socket, TLS transport, ordered byte buffering,
backpressure, and protocol transition. Linux::Event::HTTP owns the opening
HTTP/1.1 Upgrade exchange. Private modules in this distribution own RFC 6455
handshake validation, framing, masking, fragmentation, text validation, and
control semantics.

The production frame/message path uses a small vendored C protocol core through
a private XS adapter. No external WebSocket C library is required at install
time. Linux::Event still owns the socket and event loop; the native code is
limited to WebSocket-specific protocol work.

The protocol engine is intentionally kept behind private classes so it can
evolve without changing the public Linux::Event API.

=head1 STATUS

Version 0.002 fixes native allocation cleanup for rejected Close frames found by CPAN Testers.

=cut
