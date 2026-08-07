package Hyperman;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.12';

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

    #define HM_ABI_VERSION 2

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
    } hm_abi;

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
