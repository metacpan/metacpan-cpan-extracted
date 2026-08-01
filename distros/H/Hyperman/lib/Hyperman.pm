package Hyperman;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Hyperman', $VERSION);

1;

__END__

=head1 NAME

Hyperman - an event-loop PSGI server

=head1 SYNOPSIS

    use Hyperman;

    my $app = sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello' ] ] };
    Hyperman->run( app => $app, port => 8080, workers => 4 );

    # async: a handler may return a Hyperman::Future of the response
    my $async = sub {
        my $env = shift;
        Hyperman->timer(0.5)->then(sub {
            [ 200, [ 'Content-Type' => 'text/plain' ], [ 'later' ] ];
        });
    };

=head1 DESCRIPTION

Hyperman is a PSGI server built on a prefork supervisor with a per-worker XS
event loop (L<Hyperman::Loop> over a pluggable readiness backend), aiming to
match a JIT HTTP server's throughput without a JIT. Handlers may return a
L<Hyperman::Future> (or any Future-compatible object) of the PSGI response;
the connection is parked while the worker keeps serving, and awaiting a
future inside a handler pumps the worker's own loop. Runs any Plack app via
C<plackup -s Hyperman>.

The entire implementation is XS: the loop, HTTP machinery, Futures, and the
process model live in C (F<include/hyperman/>), with per-package XS
interfaces (F<xs/>).

=head2 run

    Hyperman->run(
        app            => $psgi_app,   # required
        host           => '0.0.0.0',
        port           => 8080,
        workers        => 0,           # 0/unset = one per CPU; 1 = in-process
                                       # dev mode (no supervisor)
        idle_timeout   => 60,          # close idle keep-alive conns (secs)
        header_timeout => 30,          # slow/partial request guard (secs)
        max_pipeline   => 32,          # requests per conn per wakeup
        reuseport      => 0,           # per-worker listeners (SO_REUSEPORT;
                                       # Linux accept scaling - regressed on
                                       # macOS, keep off there)
        access_log     => sub {        # optional; called after each response
            my ($env, $status, $bytes) = @_;   # $bytes undef for streaming
        },
        max_requests_per_worker => 0,  # recycle a worker after N requests
        shutdown_grace => 30,          # bound on graceful drain (secs)
        affinity       => 0,           # pin worker i to core i%ncpu (Linux)
        http2          => 0,           # accept HTTP/2 (h2c, and h2 over TLS via
                                       # ALPN); needs the nghttp2 build
        tls_cert       => $cert_pem,   # serve HTTPS (needs the OpenSSL build,
        tls_key        => $key_pem,    # Hyperman->has_tls); both required
        tls_ca         => $ca_pem,     # verify client certs against this CA
        tls_verify     => 'require',   # none (default) | optional | require
        tls_sni        => {            # per-hostname certificates (SNI)
            'other.example' => { cert => $c2, key => $k2 },
        },
    );

The event backend is chosen automatically (kqueue, io_uring, epoll, then poll) and can
be forced with C<HYPERMAN_BACKEND>.

=head2 HTTP/2

With C<< http2 => 1 >> (requires the nghttp2 build; C<< Hyperman->has_http2 >>
reports it), a connection whose first bytes are the HTTP/2 preface is served
as cleartext HTTP/2 (h2c, prior knowledge) via L<nghttp2|https://nghttp2.org>:
multiplexed streams, HPACK, and flow control, with each stream dispatched to
the app like any request (sync, C<Hyperman::Future>, or C<psgi.streaming>
responses all work). HTTP/1.1 remains the default on the same port.

=head2 TLS / HTTPS

With C<tls_cert>/C<tls_key> (PEM paths; requires the OpenSSL build,
C<< Hyperman->has_tls >>), the listener serves HTTPS: a non-blocking TLS
handshake is driven on the event loop, then reads/writes go through OpenSSL.
The certificate and key are validated once before forking, so a bad pair
fails fast. Combined with C<< http2 => 1 >>, ALPN negotiates B<h2> vs
B<http/1.1> per connection on the same port - the path browsers use for
HTTP/2. C<psgi.url_scheme> is C<https> for TLS requests, and C<HTTPS> is set
to C<on>.

B<Client certificates (mTLS).> C<tls_verify> (C<optional>/C<require>, with
C<tls_ca> as the trust anchor) requests and checks a client certificate;
C<require> fails the handshake without a valid one. The result is surfaced in
C<$env> the mod_ssl way: C<SSL_CLIENT_VERIFY> (C<SUCCESS>/C<FAILED>/C<NONE>),
C<SSL_CLIENT_S_DN>, C<SSL_CLIENT_I_DN>, plus C<SSL_PROTOCOL>/C<SSL_CIPHER>.

B<SNI (multiple certificates).> C<tls_sni> maps hostnames to their own
C<cert>/C<key>; the certificate is chosen from the TLS ServerName, falling
back to C<tls_cert>/C<tls_key>.

B<h2c Upgrade.> With C<< http2 => 1 >> over cleartext, an HTTP/1.1 request
carrying C<Upgrade: h2c> is answered with C<101 Switching Protocols> and the
connection continues as HTTP/2 (the original request becomes stream 1) - as
well as the prior-knowledge preface. Over TLS, h2 is chosen by ALPN instead.

With C<< workers > 1 >> a supervisor process manages the pool: a crashed
worker is respawned (exponential backoff on crash loops; clean exits respawn
immediately), C<SIGHUP> or C<SIGUSR2> recycles all workers with zero
downtime (new workers start, old ones drain gracefully), C<SIGUSR1> makes
every worker dump its stats to stderr, and C<SIGTERM> / C<SIGINT> drain -
bounded by C<shutdown_grace> - and exit. With C<< workers => 1 >> the server
runs in the calling process, no supervisor.

=head2 timer / io_ready

    my $f = Hyperman->timer($secs);          # Future, resolves after $secs
    my $g = Hyperman->io_ready($fh, 'r');    # Future, resolves on readiness

Both require a running worker loop. C<< Hyperman->loop >> returns the current
worker's L<Hyperman::Loop> (or undef outside one).

=head2 stats

    my $s = Hyperman->stats;   # in-app, inside a worker
    # { requests => N, accepts => N, bytes_out => N, connections => N,
    #   backend => 'kqueue', pid => $$ }

Per-worker counters; returns undef outside a running loop.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
