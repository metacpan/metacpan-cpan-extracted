package EV::Nats;
use strict;
use warnings;
use EV;

BEGIN {
    use XSLoader;
    our $VERSION = '0.01';
    XSLoader::load __PACKAGE__, $VERSION;
}

*pub   = \&publish;
*hpub  = \&hpublish;
*sub   = \&subscribe;
*unsub = \&unsubscribe;
*req   = \&request;

sub creds_file {
    my ($self, $path) = @_;
    open my $fh, '<', $path or die "cannot open creds file $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    # NATS creds format: --- BEGIN USER JWT --- / jwt / --- END / --- BEGIN NKEY SEED --- / seed / --- END
    if ($content =~ /-----BEGIN NATS USER JWT-----\s*\n\s*(\S+)\s*\n/) {
        $self->jwt($1);
    }
    if ($content =~ /-----BEGIN USER NKEY SEED-----\s*\n\s*(\S+)\s*\n/) {
        $self->nkey_seed($1);
    }
    $self;
}

sub subscribe_max {
    my ($self, $subject, $cb, $max_msgs, $queue_group) = @_;
    my $sid = defined $queue_group
        ? $self->subscribe($subject, $cb, $queue_group)
        : $self->subscribe($subject, $cb);
    $self->unsubscribe($sid, $max_msgs) if $max_msgs;
    $sid;
}

1;

=head1 NAME

EV::Nats - High-performance asynchronous NATS client using EV

=head1 SYNOPSIS

    use EV::Nats;

    my $nats = EV::Nats->new(
        host       => '127.0.0.1',
        port       => 4222,
        on_error   => sub { warn "nats error: @_" },
        on_connect => sub { warn "connected to NATS" },
    );

    # Subscribe
    my $sid = $nats->subscribe('foo.>', sub {
        my ($subject, $payload, $reply) = @_;
        print "[$subject] $payload\n";
    });

    # Subscribe with queue group
    $nats->subscribe('worker.>', sub {
        my ($subject, $payload, $reply) = @_;
    }, 'workers');

    # Publish
    $nats->publish('foo.bar', 'hello world');

    # Request/reply
    $nats->request('service.echo', 'ping', sub {
        my ($response, $err) = @_;
        die $err if $err;
        print "reply: $response\n";
    }, 5000);  # 5s timeout

    # Unsubscribe
    $nats->unsubscribe($sid);

    EV::run;

=head1 DESCRIPTION

EV::Nats is a high-performance asynchronous NATS client that implements
the NATS client protocol in pure XS with L<EV> event loop integration.
No external C NATS library is required.

Features:

=over

=item * Full NATS client protocol (PUB, SUB, UNSUB, MSG, HMSG)

=item * Request/reply with automatic inbox management

=item * Queue group subscriptions for load balancing

=item * Wildcard subjects (C<*> and C<E<gt>>)

=item * Headers support (HPUB/HMSG)

=item * Automatic PING/PONG keep-alive

=item * Automatic reconnection with subscription and queue group restore

=item * Fire-and-forget publish (no callback overhead)

=item * Token, user/pass authentication

=item * TCP keepalive and connect timeout

=item * Write coalescing via ev_prepare (batches writes per event loop iteration)

=item * O(1) subscription lookup via hash table

=item * Graceful drain (unsubscribe all, flush, then disconnect)

=item * Server pool with cluster URL failover from INFO connect_urls

=item * Optional TLS via OpenSSL (auto-detected at build time)

=item * Reconnect jitter to prevent thundering herd

=item * Per-connection stats counters (msgs/bytes in/out)

=item * JetStream API (L<EV::Nats::JetStream>)

=item * Key-Value store (L<EV::Nats::KV>)

=item * Object store with chunking (L<EV::Nats::ObjectStore>)

=item * NKey/JWT authentication (Ed25519 via OpenSSL)

=item * Slow consumer detection with configurable threshold

=item * Publish batching API (C<batch>)

=item * Lame duck mode (leaf node graceful shutdown) notification

=back

B<Note:> DNS resolution via C<getaddrinfo> is blocking. Use numeric IP
addresses for latency-sensitive applications.

=head1 METHODS

=head2 new(%options)

Create a new EV::Nats instance. Connects automatically if C<host> is given.

    my $nats = EV::Nats->new(
        host     => '127.0.0.1',
        port     => 4222,
        on_error => sub { die @_ },
    );

Options:

=over

=item host => 'Str'

=item port => 'Int' (default 4222)

Server hostname and port. If C<host> is provided, connection starts
immediately.

=item on_error => $cb->($errstr)

Error callback. Default: C<croak>.

=item on_connect => $cb->()

Called when connection is fully established (after CONNECT/PONG handshake).

=item on_disconnect => $cb->()

Called on disconnect.

=item user => 'Str'

=item pass => 'Str'

Username/password authentication. Values are JSON-escaped in the
CONNECT command.

=item token => 'Str'

Token authentication.

=item name => 'Str'

Client name sent in CONNECT.

=item verbose => $bool (default 0)

Request +OK acknowledgments from server.

=item pedantic => $bool (default 0)

Enable strict subject checking.

=item echo => $bool (default 1)

Receive messages published by this client.

=item no_responders => $bool (default 0)

Enable no-responders notification for requests.

=item reconnect => $bool (default 0)

Enable automatic reconnection.

=item reconnect_delay => $ms (default 2000)

Delay between reconnect attempts.

=item max_reconnect_attempts => $num (default 60)

Maximum reconnect attempts. 0 = unlimited.

=item connect_timeout => $ms

Connection timeout. 0 = no timeout.

=item ping_interval => $ms (default 120000)

Interval for client-initiated PING. 0 = disabled.

=item max_pings_outstanding => $num (default 2)

Max unanswered PINGs before declaring stale connection.

=item priority => $num (-2 to +2)

EV watcher priority.

=item keepalive => $seconds

TCP keepalive interval.

=item path => 'Str'

Unix socket path. Mutually exclusive with C<host>.

=item loop => EV::Loop

EV loop to use. Default: C<EV::default_loop>.

=back

=head2 connect($host, [$port])

Connect to NATS server. Port defaults to 4222.

=head2 connect_unix($path)

Connect via Unix domain socket.

=head2 disconnect

Graceful disconnect.

=head2 is_connected

Returns true if connected.

=head2 publish($subject, [$payload], [$reply_to])

Publish a message. Alias: C<pub>.

    $nats->publish('foo', 'hello');
    $nats->publish('foo', 'hello', 'reply.subject');

=head2 hpublish($subject, $headers, [$payload], [$reply_to])

Publish with headers. Alias: C<hpub>.

    $nats->hpublish('foo', "NATS/1.0\r\nX-Key: val\r\n\r\n", 'body');

=head2 subscribe($subject, $cb, [$queue_group])

Subscribe to a subject. Returns subscription ID. Alias: C<sub>.

    my $sid = $nats->subscribe('foo.*', sub {
        my ($subject, $payload, $reply, $headers) = @_;
    });

Queue groups are preserved across reconnects.

Callback receives:

=over

=item C<$subject> - actual subject the message was published to

=item C<$payload> - message body

=item C<$reply> - reply-to subject (undef if none)

=item C<$headers> - raw headers string (only for HMSG)

=back

=head2 subscribe_max($subject, $cb, $max_msgs, [$queue_group])

Subscribe and auto-unsubscribe after C<$max_msgs> messages in one call.

=head2 unsubscribe($sid, [$max_msgs])

Unsubscribe. With C<$max_msgs>, auto-unsubscribes after receiving that many
messages. Auto-unsub state is restored on reconnect. Alias: C<unsub>.

=head2 request($subject, $payload, $cb, [$timeout_ms])

Request/reply. Uses automatic inbox subscription. Alias: C<req>.

    $nats->request('service', 'data', sub {
        my ($response, $err) = @_;
        die $err if $err;
        print "got: $response\n";
    }, 5000);

Callback receives C<($response, $error)>. Error is set on timeout
("request timeout") or no responders ("no responders").

=head2 drain([$cb])

Graceful shutdown: sends UNSUB for all subscriptions, flushes pending
writes with a PING fence, fires C<$cb> when the server confirms with
PONG, then disconnects. No new messages will be received after drain
is initiated.

    $nats->drain(sub {
        print "drained, safe to exit\n";
    });

=head2 ping

Send PING to server.

=head2 flush

Send PING as a write fence; the subsequent PONG guarantees all prior
messages were processed by the server.

=head2 server_info

Returns raw INFO JSON string from server.

=head2 max_payload([$limit])

Get/set max payload size.

=head2 waiting_count

Number of writes queued locally (during connect/reconnect).

=head2 skip_waiting

Cancel all waiting writes.

=head2 reconnect($enable, [$delay_ms], [$max_attempts])

Configure reconnection.

=head2 reconnect_enabled

Returns true if reconnect is enabled.

=head2 connect_timeout([$ms])

Get/set connect timeout.

=head2 ping_interval([$ms])

Get/set PING interval.

=head2 max_pings_outstanding([$num])

Get/set max outstanding PINGs.

=head2 priority([$num])

Get/set EV watcher priority.

=head2 keepalive([$seconds])

Get/set TCP keepalive.

=head2 batch($coderef)

Batch multiple publishes into a single write. Suppresses per-publish
write scheduling; all buffered data is flushed after the coderef returns.

    $nats->batch(sub {
        $nats->publish("foo.$_", "msg-$_") for 1..1000;
    });

=head2 slow_consumer($bytes_threshold, [$cb])

Enable slow consumer detection. When the write buffer exceeds
C<$bytes_threshold> bytes, C<$cb> is called with the current buffer size.

    $nats->slow_consumer(1024*1024, sub {
        my ($pending_bytes) = @_;
        warn "slow consumer: ${pending_bytes}B pending\n";
    });

=head2 on_lame_duck([$cb])

Get/set callback for lame duck mode. Fired when the server signals
it's shutting down (leaf node / rolling restart). Use this to migrate
to another server.

=head2 nkey_seed($seed)

Set NKey seed for Ed25519 authentication (requires OpenSSL at build time).
The seed is a base32-encoded NATS NKey. The server nonce from INFO is
automatically signed during CONNECT.

    $nats->nkey_seed('SUAM...');

Or via constructor: C<nkey_seed =E<gt> 'SUAM...'>.

=head2 jwt($token)

Set user JWT for authentication. Combined with C<nkey_seed> for
NATS decentralized auth.

=head2 tls($enable, [$ca_file], [$skip_verify])

Configure TLS (requires OpenSSL at build time).

    $nats->tls(1);                           # system CA
    $nats->tls(1, '/path/to/ca.pem');        # custom CA
    $nats->tls(1, undef, 1);                 # skip verification

Or via constructor: C<tls =E<gt> 1, tls_ca_file =E<gt> $path>.

=head2 stats

Returns a hash of connection statistics:

    my %s = $nats->stats;
    # msgs_in, msgs_out, bytes_in, bytes_out

=head2 reset_stats

Reset all stats counters to zero.

=head2 on_error([$cb])

=head2 on_connect([$cb])

=head2 on_disconnect([$cb])

Get/set handler callbacks.

=head1 BENCHMARKS

Measured on Linux with TCP loopback, Perl 5.40, nats-server 2.12,
100-byte payloads (C<bench/benchmark.pl>):

                                100K msgs    200K msgs
    PUB fire-and-forget         4.7M         5.0M msgs/sec
    PUB + SUB (loopback)        1.8M         1.6M msgs/sec
    PUB + SUB (8B payload)      2.2M         1.9M msgs/sec
    REQ/REP (pipelined, 128)    334K               msgs/sec

Connected-path publish appends directly to the write buffer with no
per-message allocation. Write coalescing via C<ev_prepare> batches
all publishes per event-loop iteration into a single C<write()> syscall.

Run C<perl bench/benchmark.pl> for full results. Set C<BENCH_MESSAGES>,
C<BENCH_PAYLOAD>, C<BENCH_HOST>, C<BENCH_PORT> to customize.

=head1 NATS PROTOCOL

This module implements the NATS client protocol directly in XS.
The protocol is text-based with CRLF-delimited control lines and
binary payloads.

Connection flow: server sends INFO, client sends CONNECT + PING,
server responds with PONG to confirm. All subscriptions (including
queue groups and auto-unsub state) are automatically restored on
reconnect.

Request/reply uses a single wildcard inbox subscription
(C<_INBOX.E<lt>randomE<gt>.*>) for all requests, with unique
suffixes per request.

=head1 CAVEATS

=over

=item * DNS resolution via C<getaddrinfo> is blocking. Use numeric IP
addresses for latency-sensitive applications.


=item * TLS requires OpenSSL headers at build time (auto-detected).

=item * NKey auth requires OpenSSL with Ed25519 support (1.1.1+).

=item * The module handles all data as bytes. Encode UTF-8 strings before
passing them.

=back

=head1 ENVIRONMENT

=over

=item TEST_NATS_HOST, TEST_NATS_PORT

Set these to run the test suite against a NATS server
(default: 127.0.0.1:4222).

=back

=head1 SEE ALSO

L<EV>, L<NATS protocol|https://docs.nats.io/reference/reference-protocols/nats-protocol>,
L<nats-server|https://github.com/nats-io/nats-server>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
