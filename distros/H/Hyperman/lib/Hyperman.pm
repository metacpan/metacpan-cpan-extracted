package Hyperman;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.27';

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
        port           => 8080,        # a scalar, or an arrayref of ports
                                       # ([80, 8080]) for several plain
                                       # listeners sharing these options
        workers        => 0,           # 0/unset = one per CPU; 1 = in-process
                                       # dev mode (no supervisor)
        idle_timeout   => 60,          # close idle keep-alive conns (secs)
        header_timeout => 30,          # slow/partial request guard (secs)
        max_pipeline   => 32,          # requests per conn per wakeup
        reuseport      => 0,           # per-worker listeners (SO_REUSEPORT;
                                       # Linux accept scaling - regressed on
                                       # macOS, keep off there)
        access_log     => '/var/log/app.log',  # fast built-in Combined-log
                                       # writer (a path, or an open handle
                                       # like \*STDERR). Or pass a coderef
                                       # for custom logging:
                                       #   sub { my ($env,$status,$bytes)=@_ }
                                       # ($bytes is undef for streaming)
        max_body       => 16777216,    # request ceiling, bytes (see below);
                                       # the default is 16MB, 0 is refused
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
        deny           => ['1.2.3.4'], # IPs dropped at accept (see below)
        deny_capacity  => 1024,        # denylist table size (0 = default)
        rate_capacity  => 4096,        # rate-counter table size (0 = default)
    );

The event backend is chosen automatically (kqueue, io_uring, epoll, then poll) and can
be forced with C<HYPERMAN_BACKEND>.

=head2 Multiple listeners

A single C<run> can bind several listeners, each independently plain or TLS -
the common case being plain B<:80> beside HTTPS B<:443>. Pass C<listen> an
arrayref of per-listener hashrefs; each takes its own C<port> (required) plus
any of C<host>, C<tls_cert>, C<tls_key>, C<tls_ca>, C<tls_verify>, C<tls_sni>,
C<http2>, and C<redirect_https>. A missing per-listener field falls back to the
top-level value of the same name, and the top-level C<port>/C<listen> are
mutually exclusive shorthands - C<< port => [80, 8080] >> is sugar for several
plain listeners sharing the top-level options.

    Hyperman->run(
        app     => $app,
        workers => 8,
        listen  => [
            { port => 80,  redirect_https => 443 },   # 301 every request to https
            { port => 443, tls_cert => $cert, tls_key => $key },
        ],
    );

C<redirect_https> makes a listener answer B<every> request with a C<301> to the
same host and request-target on the given https port (in C, before the app is
reached); the value is that target port, and a bare true value means the
standard C<443>. Its C<SERVER_PORT> and, for TLS listeners, C<psgi.url_scheme>
reflect the listener the request arrived on. All listeners serve the one C<app>.
Ports below 1024 (80, 443) still require the process to start as root or hold
C<CAP_NET_BIND_SERVICE>.

=head3 access_log

When C<access_log> is a path or an open filehandle, Hyperman formats an
Apache-style Combined Log Format line

    host - user [dd/Mon/YYYY:HH:MM:SS +ZZZZ] "METHOD URI PROTO" status bytes "referer" "ua"

entirely in C and appends it to the file, with no per-request Perl call on
the hot path. The timestamp is cached and recomputed at most once a second,
lines are buffered and flushed once per event-loop wakeup, and a file target
is opened once in the parent and shared C<O_APPEND> across workers so their
lines stay interleaved without tearing. Quoted fields are escaped, so a
hostile URI or User-Agent cannot forge a log line. C<REMOTE_ADDR> is captured
at accept and is also visible to the app in C<$env>.

Pass a coderef instead (C<< sub { my ($env, $status, $bytes) = @_ } >>) for
full control; that path calls back into Perl for every response.

=head2 max_body: the request ceiling

C<max_body> is the largest request Hyperman will buffer - B<headers plus
body> - before the application is called. Over it, the request is answered
C<413 Payload Too Large> and the connection is closed. The default is
B<16MB>, which is what it was as a hard-coded literal before 0.25.

    Hyperman->run(app => $app, max_body => 64 * 1024 * 1024);

=head2 Response compression

With C<< compress => 1 >>, responses are gzipped on the
way out.

    Hyperman->run(app => $app, compress => 1);

B<Off by default>, here and under L<Plack::Handler::Hyperman>. A server
that starts compressing because it was upgraded is a surprise, and the
cost is real - see the C<compress_level> table below. Whether it is worth
paying depends on whether bandwidth or CPU is what limits a given
deployment, which is something only its operator knows.

A response is compressed only when B<all> of these hold:

=over 4

=item * the request's C<Accept-Encoding> accepted gzip (C<q=0> is an
explicit refusal and is honoured)

=item * the response carries B<no C<Content-Encoding> of its own>

=item * the body is a plain in-memory body, not a filehandle, reader or
streamed source - compressing those would undo the sendfile and drip paths

=item * it is at least C<compress_min_length> bytes (default 1400, one MTU)

=item * the status is 200 or 203 - never 206, whose C<Content-Range>
describes offsets into the B<uncompressed> representation

=item * the C<Content-Type> is on the compressible allowlist: C<text/*>,
C<application/json>, C<application/javascript>, C<application/xml>,
C<application/x-ndjson>, C<image/svg+xml>, and anything ending C<+json> or
C<+xml>. An allowlist, so a new binary media type never becomes
compressible by default.

=back

=head3 The C<Content-Encoding> contract

B<Hyperman never touches a response that already declares a
C<Content-Encoding>.> That one rule is the whole interface with whatever is
above it:

=over 4

=item * a framework serving precompressed C<.gz> files off disk sets
C<gzip>, and its bytes go out as they are

=item * a route that wants no compression sets C<< Content-Encoding:
identity >>, which Hyperman honours and B<strips> before writing

=back

It is a plain response header, so it is a contract any PSGI framework can
use rather than a private arrangement. L<Punk>'s C<< { compress => 0 } >>
route option is exactly this spelling.

=head3 Two things it changes about your response

B<The C<ETag> is rewritten> - a C<-gzip> suffix is added inside the closing
quote. The layer that compresses must be the layer that fixes the
validator, or a shared cache serves the compressed bytes to a client that
asked for none. nginx does the same. It is said plainly here because
otherwise an application author finds it by debugging.

B<C<Vary: Accept-Encoding> is added> whenever a response was compressed, for
the same reason.

An app-supplied C<Content-Length> is replaced, since it described the bytes
that were just replaced.

=head3 C<compress_level>

Default 1, not the customary 6, on measurement rather than convention. A
37KB JSON document, 2 workers / 5s / 64 connections on loopback:

    off        130,000 req/s    37.3 KB/req
    level 1     66,900 req/s     3.19 KB/req   11.7x smaller, 1.9x slower
    level 6     26,300 req/s     2.96 KB/req   12.6x smaller, 4.9x slower

Level 6 buys 7% more compression for 2.5x the CPU. Almost all of the win on
repetitive text - which is what an API payload is - lands in the first
level. Raise it with C<< compress_level => 6 >> if bandwidth costs you more
than CPU does; the range is 1 to 9.

B<Read that table carefully: a loopback benchmark charges the whole CPU
cost and pays none of the benefit, because the network is free.> It is the
worst case for compression and the best case for sending 37KB uncompressed.
Once the link is finite, the same two numbers say the opposite thing -
requests actually served, taking whichever of CPU and bandwidth binds
first:

    link        without gzip    with gzip    winner
    100 Mbps             327        3,827    gzip, 11.7x
    1 Gbps             3,273       38,267    gzip, 11.7x
    10 Gbps           32,727       66,900    gzip, 2.0x
    25 Gbps           81,817       66,900    uncompressed, 1.2x
    40 Gbps          130,000       66,900    uncompressed, 1.9x

Compression loses only above roughly 20 Gbps of egress per host, which is
not a situation a PSGI application is usually in. Below that, halving the
CPU per response buys nothing because the CPU was not the constraint.

Small responses are unaffected either way: anything under
C<compress_min_length> is never touched, and a benchmark of tiny bodies
measures no difference at all.

=head3 Without zlib

C<compress> and C<compress_min_length> are accepted and inert, so one
configuration is portable across builds. C<< Hyperman->has_compression >>
is the honest answer.

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
back to C<tls_cert>/C<tls_key>. See L</tls_reload> for replacing that map
while the server is running.

B<The library.> C<< Hyperman->tls_library >> returns the runtime TLS
library banner (C<OpenSSL 3.0.13 30 Jan 2024>, C<LibreSSL 3.8.2>), or
undef when TLS support was not built. The two stacks agree on the API but
not on behaviour - LibreSSL performs no TLS 1.3 session resumption, for
one - and this is how a deployment (or a test) tells them apart.

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

=head2 tls_reload

    my $n = Hyperman->tls_reload(\%sni);   # listeners rebuilt

Replace this worker's TLS certificates without replacing the process.

A listener's C<SSL_CTX> is built once, in the parent, before the fork -
so a certificate issued while the server is running is not served, and
C<SIGHUP> does not help because it re-forks from that same parent. This
is the way to pick one up. C<%sni> is the same shape C<run> takes,
C<< { host => { cert => $path, key => $path } } >>, and replaces the map
entirely rather than merging into it.

Call it B<from inside a worker> - from the app, or from a timer on
C<< Hyperman->loop >>. Each worker holds its own context pointer (the
fork copied it), so a reload changes that worker and no other; a pool
picks the new certificate up as each worker calls it. The listening
socket is never touched, so nothing is unbound and no connection is
refused, and connections already handshook keep the one they have. The
next connection B<that worker> accepts uses the new certificate.

Returns the number of listeners rebuilt: 0 outside a worker, 0 on a
plain-only server, and 0 when the rebuild would have served less than
what is already running - either because the default certificate would
not load, or because a per-host one would not and that host would have
silently dropped to the fallback. In every one of those cases the
running certificates are left exactly as they were, and the reason is
printed to C<STDERR>.

A worker respawned after a crash, or recycled by C<SIGHUP>, inherits the
parent's boot-time context again and needs its own C<tls_reload>. That
is a feature of where the context is built, not a bug here: whatever
drives the reload should drive it per worker rather than once.

=head2 stats

    my $s = Hyperman->stats;   # in-app, inside a worker
    # { requests => N, accepts => N, denied => N, bytes_out => N,
    #   connections => N, backend => 'kqueue', pid => $$ }

Per-worker counters; returns undef outside a running loop. C<denied> counts
connections dropped at accept by the denylist (see below).

=head2 detach

    my $fd = Hyperman::detach($env);

Hand a live HTTP/1 connection to the application. The server removes its
watchers for the socket, forgets the connection and B<does not close it>,
so from that point the application's own C<psgix.loop> watchers on that
descriptor are what drive it. This is the seam a protocol upgrade needs:
before it, a hijacked socket raced the server's own read watcher, which
consumed post-upgrade bytes into a buffer nothing drained.

The application writes its own upgrade response - the server's writer is
out of the picture - and returns C<[101, [], []]>, which is discarded.
Returns the real file descriptor.

    my $conn = $env->{'psgix.hyperman.conn'};   # [ fd, generation id ]

C<psgix.hyperman.conn> is both the ticket detach works from and the way an
application detects that detaching is possible at all: it is absent on
HTTP/2 and on servers that are not Hyperman. Detaching croaks, with the
reason, when the connection is gone or the ticket is stale, on HTTP/2, on
TLS, when output is still queued, or when it has already been detached.

Detach is legal from a Future continuation - asynchronous authentication
before an upgrade - but not from a C<psgi.streaming> responder, which has
already forced C<Connection: close>, nor once response bytes are queued.

The equivalent for a C consumer is the table's C<conn_detach>.

=head2 Denylist and rate limiting

Hyperman maps a small anonymous shared-memory arena B<before it forks its
workers>, holding an IP denylist and a set of fixed-window rate counters. It
is shared, not per-worker, on purpose: a counter kept per worker would let a
C<100/min> limit through at C<workers x 100/min>, and a denylist kept per
worker would be a different list on each. Because the mapping is inherited
across the fork, every worker reads and writes the one copy.

The B<denylist> is enforced at C<accept>: a blocked peer's connection is
closed before a connection object is built or a byte is read - the cheapest
possible rejection - and the worker's C<denied> stat counts it. Seed it
statically with C<< run(deny => ['1.2.3.4', ...]) >>; C<deny_capacity> and
C<rate_capacity> size the two tables (both default, and both round-trip a few
thousand entries).

The B<rate counters> are a fixed window: at most C<limit> hits against a key
in each C<window>-second wall-clock slot, the first hit of a new slot finding
a stale record and zeroing it - no timer, no sweep. A slot whose window has
rolled is reclaimable, so when the keys that filled the table go quiet their
slots are reused on demand by new keys rather than lingering; sizing
C<rate_capacity> above the peak of distinct keys in a window keeps live
counters from evicting each other (an over-capacity eviction resets a
counter, so it would leak looser, never tighter). N gateways behind a load
balancer admit up to N times the limit, which is honest rather than a
distributed count this does not implement.

An XS module reaches all of this through the C ABI below - C<deny_check> /
C<deny_add> / C<deny_remove> and C<ratelimit_hit> - which is how L<Punk>'s
C<rate_limit> keyword and C<< $c->block_ip >> are built, with no Perl on the
hot path. The same four are also plain class methods, for an application that
is not an XS module:

    Hyperman->deny_add($ip, $ttl_seconds);   # 0 = until the server stops
    Hyperman->deny_remove($ip);
    my $blocked = Hyperman->deny_check($ip);

    my ($allowed, $remaining, $reset)
        = Hyperman->ratelimit_hit($key, $limit, $window);

C<ratelimit_hit> counts one hit against C<$key> in the current window and says
whether it is within C<$limit>; C<$reset> is the epoch second the window
rolls, which is what an C<X-RateLimit-Reset> header wants. A C<$limit> of 0 is
unlimited and reports a C<$remaining> of -1. C<$window> defaults to 60.

Reach for these rather than a Perl equivalent, because a Perl equivalent is
wrong in a way that is hard to see: a hash in the worker gives a B<different
denylist per worker>, and a counter in the worker turns a limit of C<$n> into
C<workers x $n>. The arena is the one copy all of them share.

All four fail B<open> when there is no arena - outside a running server, or
on a platform without the atomics it needs - so nothing is denied and nothing
is limited. That is the same answer the accept path gives itself, and the safe
one for a check that could not run. Note that a denylist entry added from
inside a request is enforced at C<accept> from then on, so it takes effect on
the B<next> connection, not the one that added it.

=head2 on_worker_start

    Hyperman->on_worker_start(sub {
        $dbh = DBI->connect(...);          # this child's own handle
        srand;                             # this child's own seed
    });

    Hyperman->run(app => $app, workers => 4);

Registers a callback that runs once in every worker, B<after the fork> and
before that worker's loop starts turning. Register before C<run>: the registry
is read in the child, so a callback added afterwards will never reach the
workers already running.

A prefork server needs this and PSGI has no standard for it. Anything holding
a file descriptor - a database handle, a cache connection - is wrong in a
child that inherited it from the parent, and sharing one across workers
corrupts it in ways that look like anything but the cause.

Returns 1, or 0 when the table is full (8 callbacks). Croaks on a non-coderef,
at registration. If the callback dies the death becomes a warning and the
worker carries on serving: a worker that could not run your setup code is
still a worker, and one that never starts is an outage - so check what you
depend on rather than assuming it ran.

The C ABI's C<on_worker_start> is the same registry, for a consumer that would
rather register a C function than a coderef.

=head1 C ABI

Hyperman exposes a public C ABI so that B<other XS modules> can drive its
event loop and futures entirely from C - fd watchers and timers whose
callbacks run with no Perl call frame per event, and Hyperman::Future
create/settle/inspect without method dispatch. The motivating consumer is
L<DBIx::Loop>, whose pure-XS loop adapter watches database socket fds and
settles futures on the worker loop C-to-C.

=head2 Getting the header

The contract lives in F<include/hyperman/hm_abi.h>. Two ways to reach it:

B<ExtUtils::Depends> (no copying). Hyperman is a provider: building installs
F<hm_abi.h> and writes C<Hyperman::Install::Files>, so a dependent's
F<Makefile.PL> that says

    my $pkg = ExtUtils::Depends->new('My::Consumer', 'Hyperman');
    WriteMakefile( ..., $pkg->get_makefile_vars );

picks up F<hm_abi.h> on its include path automatically - but makes Hyperman
a configure-time dependency of the consumer.

B<Vendoring a pinned copy>. Because the table is resolved at runtime and the
header is pure declarations, a consumer that wants Hyperman to stay
B<optional> (as DBIx::Loop does) instead ships its own copy of F<hm_abi.h>
pinned at a known C<HM_ABI_VERSION> and simply fails its resolve when
Hyperman is not loaded.

Perl headers (F<EXTERN.h> / F<perl.h> / F<XSUB.h>) must be included before
F<hm_abi.h>.

=head2 The table

    #define HM_ABI_VERSION 4

    #define HM_ABI_READ  0x1        /* io_watch masks     */
    #define HM_ABI_WRITE 0x2

    #define HM_ABI_PENDING   0      /* future_state       */
    #define HM_ABI_DONE      1
    #define HM_ABI_FAILED    2
    #define HM_ABI_CANCELLED 3

    typedef struct hm_abi_timer hm_abi_timer;    /* opaque handle */

    typedef void (*hm_abi_io_cb)(pTHX_ int fd, int mask, void *ud);
    typedef void (*hm_abi_timer_cb)(pTHX_ void *ud);
    typedef void (*hm_abi_ready_cb)(pTHX_ SV *future, void *ud);
    typedef void (*hm_abi_worker_cb)(pTHX_ void *loop, void *ud);

    typedef struct hm_abi {
        int abi_version;                          /* == HM_ABI_VERSION */

        /* loop handles (opaque hm_loop*) */
        void *(*cur_loop)(pTHX);
        void *(*loop_of_sv)(pTHX_ SV *loop_sv);
        SV   *(*sv_of_loop)(pTHX_ void *loop);

        /* persistent fd watchers, pure C dispatch */
        void (*io_watch)(pTHX_ void *loop, int fd, int mask,
                         hm_abi_io_cb cb, void *ud);
        void (*io_unwatch)(pTHX_ void *loop, int fd, int mask);

        /* one-shot timer with cancellation */
        hm_abi_timer *(*timer)(pTHX_ void *loop, double secs,
                               hm_abi_timer_cb cb, void *ud);
        void (*timer_cancel)(pTHX_ void *loop, hm_abi_timer *t);

        /* Hyperman::Future */
        SV  *(*future_new)(pTHX);
        int  (*is_future)(pTHX_ SV *sv);
        IV   (*future_state)(pTHX_ SV *f);
        void (*future_done)(pTHX_ SV *f, SV **vals, SSize_t n);
        void (*future_fail)(pTHX_ SV *f, SV *err);
        void (*future_on_ready)(pTHX_ SV *f, hm_abi_ready_cb cb, void *ud);

        /* await: pump the loop until f settles (re-entrant) */
        void (*run_until)(pTHX_ void *loop, SV *f);

        /* v2: detach a live HTTP/1 connection (see Hyperman::detach).
         * 0 ok; -1 no such connection or a stale id; -2 HTTP/2; -3 TLS;
         * -4 output still queued; -5 already detached. */
        int (*conn_detach)(pTHX_ void *loop, int fd, UV id);

        /* v3: abuse controls on the fork-shared arena (no pTHX, no SV;
         * process-global; fail open with no arena). deny_check is the
         * lock-free accept-path check; ratelimit_hit is a fixed window,
         * returns 1 within the limit and 0 over, filling *remaining and
         * *reset (the epoch the window rolls) when non-NULL. */
        int  (*deny_check)(const char *ip);
        void (*deny_add)(const char *ip, long ttl_secs);
        void (*deny_remove)(const char *ip);
        int  (*ratelimit_hit)(const void *key, STRLEN klen,
                              IV limit, IV window, IV *remaining, IV *reset);

        /* v4: run cb once in every worker, AFTER the fork, in the child,
         * with that child's own loop, before the loop starts turning.
         * Register before run(). Fires in the single-worker case too.
         * Returns 1, or 0 when the table is full. */
        int (*on_worker_start)(pTHX_ hm_abi_worker_cb cb, void *ud);
    } hm_abi;

C<on_worker_start> is the seam for anything a consumer owns that is bound to
an event loop. A flush timer, a wakeup listener, a metrics reader: none of
them can be created before C<run>, because the loop they would attach to is
not the loop that ends up serving - a prefork server has forked by then, and
on kqueue the child's copy of the descriptor is not even valid. This is the
one moment where the loop exists, belongs to the process that will serve, and
has not started turning.

    static void on_worker(pTHX_ void *loop, void *ud) {
        A->timer(aTHX_ loop, 5.0, flush, ud);      /* the child's own loop */
    }
    A->on_worker_start(aTHX_ on_worker, ud);       /* before run() */

L</on_worker_start> is the same registry as a class method, for an
application that wants to reopen a database handle rather than attach a
watcher. A Perl callback is handed no loop - C<< Hyperman->loop >> is the
worker's own once it is running - because the useful thing to do with the raw
pointer is a C entry point.

=head2 Hyperman::_abi_ptr

    my $iv = Hyperman::_abi_ptr;

Returns the address of the process-wide C<hm_abi> table as an integer (an
C<IV>). A consumer calls this once (at C<BOOT>, or lazily on first use),
C<INT2PTR>s it to a C<< const hm_abi * >>, and checks
C<< ->abi_version >= HM_ABI_VERSION >> (the version it was compiled
against) before using it. Not intended to be called from Perl for any other
purpose. C<Hyperman::_abi_selftest> exercises the whole table from C and
returns 1; it exists for Hyperman's own test suite.

=head2 Loop handles

C<cur_loop> returns the currently running loop or C<NULL> - inside a
Hyperman worker it is the worker's loop, so a consumer resolving at request
time needs no loop object at all. C<loop_of_sv> unwraps a L<Hyperman::Loop>
SV (croaks on anything else); C<sv_of_loop> returns the loop's blessed
wrapper SV (+1, caller owns), the same shared wrapper C<psgix.loop> uses.
The handle is opaque; pass it back to every loop-taking entry.

=head2 Watchers and timers

C<io_watch> installs a B<persistent> C watcher for one direction of one fd
(C<HM_ABI_READ> or C<HM_ABI_WRITE> - one direction per call). The callback
fires on every readiness event with no Perl call frame, receiving the fd,
the direction that fired, and C<ud>. Installing replaces any existing
watcher (C, Perl callback, or future) for that fd+direction; C<io_unwatch>
is idempotent and safe from inside the callback. fd must be below
Hyperman's fd ceiling (65536); a bad fd croaks.

C<timer> arms a B<one-shot> timer and returns an opaque handle;
C<timer_cancel> disarms a timer that has not fired yet. The handle dies
when the callback fires - never cancel after the fire (clear any stored
handle inside the callback). Cancel live timers before dropping a loop.

=head2 Futures

C<future_new> returns a pending L<Hyperman::Future> (+1, caller owns).
C<future_done> / C<future_fail> settle it and run its continuations through
the normal trampoline; both are no-ops on an already-settled future, and
values are copied, not stolen. C<future_state> returns the C<HM_ABI_*>
state without dispatch. C<future_on_ready> attaches a C continuation that
fires exactly once when the future settles - B<including cancellation>
(check C<future_state> to see which); this is how a consumer hooks
cancellation, e.g. issuing a database cancel when a caller cancels the
future. It fires immediately if the future is already settled.

C<run_until> pumps the loop until the given future settles. It is
re-entrant - calling it from inside a callback nests, exactly like
C<< ->get >> inside a Hyperman worker - so a blocking-style C<await> can be
built on it directly.

=head2 Abuse controls (v3)

The v3 entries reach the fork-shared arena described under L</Denylist and
rate limiting>. They take no C<pTHX> and touch no SV - they operate only on
that process-global arena - so a consumer may call them from any worker, and
they B<fail open> when no arena is mapped.

C<deny_check($ip)> returns 1 if C<$ip> (an C<INET6_ADDRSTRLEN> string) is
denylisted and unexpired, else 0; it is lock-free, being the check Hyperman
itself runs on every accept. C<deny_add($ip, $ttl_secs)> adds or refreshes an
entry (C<$ttl_secs> 0 = permanent); C<deny_remove($ip)> lifts one.

C<ratelimit_hit(key, klen, limit, window, &remaining, &reset)> counts one hit
against the opaque C<key> (C<klen> bytes) under C<limit> per C<window>
seconds, returning 1 within the limit and 0 over, and filling C<*remaining>
(never below zero) and C<*reset> (the epoch the window rolls) when they are
non-NULL. A C<limit> of 0 or less is unlimited. The window is fixed and a
function of the clock, exactly as the arena describes.

L<Punk> builds its C<rate_limit> keyword, C<< $c->block_ip >> and
C<< $c->rate_hit >> on these four.

The same four are class methods for a consumer that is not an XS module - see
L</Denylist and rate limiting>. They are the same arena and interchangeable
with these; what differs is a Perl call per invocation instead of none, which
is why the framework-level keywords are built on the C entries.

=head2 Contracts

Everything is single-threaded and fires on the loop thread, inside the
loop's dispatch:

=over 4

=item * C callbacks must B<not croak>. Trap errors (C<G_EVAL> around any
Perl you call) and settle a future instead; a longjmp out of the dispatch
loop leaves it inconsistent.

=item * C<ud> lifetime is the consumer's problem: it must stay valid until
the watcher is removed, the timer fires or is cancelled, or C<on_ready>
fires. Remove watchers before freeing their C<ud>.

=item * Callbacks may re-enter the table freely, including C<run_until>.

=item * The table only ever grows at the end. C<HM_ABI_VERSION> bumps on
any append; a consumer requires C<< abi_version >= >> the version it was
written against.

=back

=head2 Example: resolve and use

    #include "hm_abi.h"     /* via ExtUtils::Depends, or a vendored copy */

    static const hm_abi *HM = NULL;   /* resolved on first use */

    static const hm_abi *my_hm(pTHX) {
        if (!HM) {
            dSP; int n;
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            n = call_pv("Hyperman::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && n > 0) {
                IV p = POPi;
                if (p) {
                    const hm_abi *a = INT2PTR(const hm_abi *, p);
                    if (a->abi_version >= HM_ABI_VERSION) HM = a;
                }
            } else if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
        }
        return HM;   /* NULL => Hyperman absent or too old: fall back */
    }

    /* watch a DB socket; on readable, collect the result and settle */
    static void on_db_readable(pTHX_ int fd, int mask, void *ud) {
        my_req *r = (my_req *)ud;            /* must not croak */
        if (collect_result(r) == DONE) {
            HM->io_unwatch(aTHX_ r->loop, fd, HM_ABI_READ);
            if (r->timeout) {
                HM->timer_cancel(aTHX_ r->loop, r->timeout);
                r->timeout = NULL;
            }
            HM->future_done(aTHX_ r->future, &r->result_sv, 1);
        }
    }

    /* fire a query: future + fd watch + timeout, all C */
    void *loop = HM->cur_loop(aTHX);         /* the worker's loop */
    r->future  = HM->future_new(aTHX);
    HM->io_watch(aTHX_ loop, db_fd, HM_ABI_READ, on_db_readable, r);
    r->timeout = HM->timer(aTHX_ loop, 5.0, on_db_timeout, r);
    HM->future_on_ready(aTHX_ r->future, on_settled_or_cancelled, r);

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
