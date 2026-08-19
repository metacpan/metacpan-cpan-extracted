package Fetch::WebSocket;

use strict;
use warnings;

our $VERSION = '0.15';

require Fetch;

1;

__END__

=head1 NAME

Fetch::WebSocket - a live WebSocket connection from L<Fetch>

=head1 SYNOPSIS

    my $ws = $ua->websocket('ws://host/echo')->get;   # after the 101

    $ws->send('hello');                 # text (UTF-8)
    $ws->send_binary($bytes);           # binary
    my $reply = $ws->next_message->get; # Future for the next message

    $ws->on_message(sub { my ($msg) = @_; ... });
    $ws->on_close(sub { warn "closed\n" });
    $ws->close;

=head1 DESCRIPTION

A WebSocket (RFC 6455) connection, returned by C<< $ua->websocket($url) >>. The
HTTP/1.1 Upgrade handshake and all framing are native C (masking, message
reassembly, automatic ping/pong and close); this object drives the same
non-blocking connection and event loop as an ordinary request, so it composes
with Futures like everything else in Fetch.

=head1 METHODS

=head2 send($text) / send_binary($bytes)

Send a text (UTF-8) or binary message.

=head2 next_message

A L<Fetch::Future> resolving to the next inbound message (text is decoded,
binary is raw bytes). Fails if the socket has closed.

=head2 on_message($cb) / on_close($cb)

Install a persistent per-message callback (buffered messages are delivered at
once), or a one-shot close callback.

=head2 is_closed / close

Whether the socket has closed; send a close frame and shut it down.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
