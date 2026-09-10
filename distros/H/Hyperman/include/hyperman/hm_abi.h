#ifndef HM_ABI_H
#define HM_ABI_H

/* Public C ABI for Hyperman (the provider) and its XS consumers (e.g.
 * DBIx::Loop's pure-XS loop adapter, which watches DB socket fds and settles
 * Hyperman::Futures without a Perl call frame on the hot path). It is
 * resolved at RUNTIME via Hyperman::_abi_ptr - a DBI-style versioned
 * function-pointer table - so there is no link-time symbol coupling and each
 * dist builds and upgrades independently. A consumer reaches this header
 * through ExtUtils::Depends, or vendors a copy pinned at HM_ABI_VERSION, and
 * checks abi_version at boot; a mismatch means "fall back", never a crash.
 *
 * The table only ever grows at the end; HM_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against.
 *
 * Contracts (single-threaded; everything fires on the loop thread):
 *   - C callbacks must NOT croak. Trap errors and settle a future instead;
 *     a longjmp out of the dispatch loop leaves it inconsistent.
 *   - Callbacks may re-enter this table (the loop is re-entrant, including
 *     run_until from inside a callback).
 *   - ud lifetime is the consumer's problem: it must stay valid until the
 *     watcher is removed, the timer fires or is cancelled, or on_ready fires.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this
 * file so SV, IV, SSize_t and pTHX are defined. */

/* Version history (the table only ever grows at the tail, so a consumer
 * built against an older header keeps working against a newer provider -
 * check `abi_version >= the version you need`):
 *   1 - loop handles, io watchers, timers, futures, run_until
 *   2 - conn_detach
 *   3 - deny_check/deny_add/deny_remove/ratelimit_hit (abuse controls)
 *   4 - on_worker_start (once per worker, after the fork, with its loop)
 *   5 - bus_publish/bus_subscribe/bus_unsubscribe/bus_dispatch
 *   6 - stream handles (stream_open .. stream_on_abort)
 *   7 - stream_abort (end a stream so the peer can tell it was not finished)
 *   8 - stream_on_data (the read half: a stream handle becomes
 *       bidirectional, which is what Extended CONNECT needs) */
#define HM_ABI_VERSION 8

/* io_watch masks (match Hyperman's internal HM_EV_READ/HM_EV_WRITE) */
#define HM_ABI_READ  0x1
#define HM_ABI_WRITE 0x2

/* future_state results (match Hyperman::Future's internal states) */
#define HM_ABI_PENDING   0
#define HM_ABI_DONE      1
#define HM_ABI_FAILED    2
#define HM_ABI_CANCELLED 3

/* Opaque one-shot timer handle. Valid from timer() until the callback fires
 * or timer_cancel() is called, whichever comes first; using it after either
 * is undefined (the fire callback should clear any stored copy). */
typedef struct hm_abi_timer hm_abi_timer;

/* fd readiness; mask is the HM_ABI_* direction that fired */
typedef void (*hm_abi_io_cb)(pTHX_ int fd, int mask, void *ud);
typedef void (*hm_abi_timer_cb)(pTHX_ void *ud);
/* fires exactly once when the future settles - including cancellation
 * (future_state says which); this is the cancellation hook */
typedef void (*hm_abi_ready_cb)(pTHX_ SV *future, void *ud);
/* fires once in each worker, after any fork, with that worker's own loop and
 * before the loop starts turning (v4) */
typedef void (*hm_abi_worker_cb)(pTHX_ void *loop, void *ud);

/* v5: one delivered message. Copied out of the ring before the call, so it
 * stays valid for as long as the callback runs. Like every other callback in
 * this table it MUST NOT CROAK: it is reached from the event loop with no
 * Perl frame to unwind into. */
typedef void (*hm_abi_bus_cb)(pTHX_ const char *topic, STRLEN tlen,
                              const char *payload, STRLEN plen, void *ud);

/* v6: something happened to a stream handle (see stream_open below). Fires
 * on the loop thread with no Perl frame to unwind into, so like every other
 * callback in this table it MUST NOT CROAK. `h` is the handle it concerns;
 * after an abort the handle is still valid to pass to stream_close, and to
 * nothing else. */
typedef void (*hm_abi_stream_cb)(pTHX_ void *h, void *ud);

/* v8: bytes arrived from the peer on this handle's stream. `fin` is true on
 * the last delivery. Same rule as every other callback here - it MUST NOT
 * CROAK, and buf is only valid for the duration of the call. */
typedef void (*hm_abi_stream_data_cb)(pTHX_ void *h, const char *buf,
                                      STRLEN len, int fin, void *ud);

/* stream_write / stream_close / stream_on_* results */
#define HM_ABI_STREAM_OK      0   /* accepted                              */
#define HM_ABI_STREAM_FULL    1   /* accepted, but over the high-water mark:
                                   * stop producing until on_drain fires   */
#define HM_ABI_STREAM_STALE  -1   /* not a live handle (closed, or never
                                   * came out of stream_open)              */
#define HM_ABI_STREAM_GONE   -2   /* the stream is gone: the connection
                                   * closed, or the peer reset it          */
#define HM_ABI_STREAM_ARG    -3   /* bad argument                          */

/* How much unwritten output a stream may hold before stream_write starts
 * answering HM_ABI_STREAM_FULL. */
#define HM_ABI_STREAM_HIWAT (256 * 1024)

typedef struct hm_abi {
    int abi_version;                 /* == HM_ABI_VERSION */

    /* ---- loop handles (opaque hm_loop*) ---------------------------------
     * cur_loop: the currently running loop, or NULL (inside a Hyperman
     * worker it is the worker's loop). loop_of_sv croaks unless the SV is a
     * Hyperman::Loop. sv_of_loop returns a blessed SV (+1, caller owns). */
    void *(*cur_loop)(pTHX);
    void *(*loop_of_sv)(pTHX_ SV *loop_sv);
    SV   *(*sv_of_loop)(pTHX_ void *loop);

    /* ---- persistent fd watchers, pure C dispatch ------------------------
     * cb fires on every readiness event for (fd, mask 1 direction) with no
     * Perl call frame. Replaces any existing watcher (C, Perl callback or
     * future) for that fd+direction. fd must be < 65536 (croaks otherwise).
     * io_unwatch is idempotent and safe from inside the callback. */
    void (*io_watch)(pTHX_ void *loop, int fd, int mask,
                     hm_abi_io_cb cb, void *ud);
    void (*io_unwatch)(pTHX_ void *loop, int fd, int mask);

    /* ---- one-shot timer with cancellation -------------------------------
     * timer() returns a handle; timer_cancel() removes a timer that has not
     * fired yet (never call it after the callback ran - the handle is freed
     * on fire). Cancel any live timers before dropping the loop. */
    hm_abi_timer *(*timer)(pTHX_ void *loop, double secs,
                           hm_abi_timer_cb cb, void *ud);
    void (*timer_cancel)(pTHX_ void *loop, hm_abi_timer *t);

    /* ---- Hyperman::Future (the ecosystem-native future) -----------------
     * future_new returns a pending Hyperman::Future (+1, caller owns).
     * future_done/future_fail settle it (no-ops if already settled) and run
     * its continuations; vals/err are copied, not stolen. future_on_ready
     * registers a C continuation (fires immediately if already settled). */
    SV  *(*future_new)(pTHX);
    int  (*is_future)(pTHX_ SV *sv);
    IV   (*future_state)(pTHX_ SV *f);          /* HM_ABI_PENDING.. */
    void (*future_done)(pTHX_ SV *f, SV **vals, SSize_t n);
    void (*future_fail)(pTHX_ SV *f, SV *err);
    void (*future_on_ready)(pTHX_ SV *f, hm_abi_ready_cb cb, void *ud);

    /* ---- await: pump the loop until f settles (re-entrant) -------------- */
    void (*run_until)(pTHX_ void *loop, SV *f);

    /* ---- v2: conn_detach ------------------------------------------------
     * Returns 0 on success, or:
     *   -1 no such connection, or the ticket is stale
     *   -2 HTTP/2 (streams share one connection - not detachable)
     *   -3 TLS (the SSL session cannot be handed over)
     *   -4 output still draining for an earlier response
     *   -5 already detached */
    int (*conn_detach)(pTHX_ void *loop, int fd, UV id);

    /* ---- v3: abuse controls on a fork-shared arena --------------------- */
    int  (*deny_check)(const char *ip);
    void (*deny_add)(const char *ip, long ttl_secs);
    void (*deny_remove)(const char *ip);
    int  (*ratelimit_hit)(const void *key, STRLEN klen,
                          IV limit, IV window, IV *remaining, IV *reset);

    /* ---- v4: worker-start callback ------------------------------------- */
    int (*on_worker_start)(pTHX_ hm_abi_worker_cb cb, void *ud);

    /* ---- v5: the cross-worker message bus ------------------------------
     *
     * One ring in shared memory, mapped before the fork. bus_publish puts a
     * message on it and pokes every other worker; bus_subscribe registers a
     * callback in THIS process.
     *
     * `group` NULL is FANOUT - this process sees every message on the topic.
     * A group name makes it a QUEUE GROUP - exactly one member of the pool
     * sees each message, and the balancing falls out of the claim rather than
     * from a scheduler. One entry point, because they are one mechanism and a
     * caller choosing between them should be choosing an argument.
     *
     * bus_publish returns 1 on the ring, 0 local-only (no arena: Windows, no
     * atomics, or not under a Hyperman server), -1 refused as oversize.
     * Oversize is never truncated.
     *
     * Delivery is AT-MOST-ONCE and drops OLDEST under pressure, counting what
     * it dropped. A consumer that cannot lose the message wants Punk::Queue,
     * which is durable and at-least-once. */
    int (*bus_publish)(const char *topic, STRLEN tlen,
                       const char *payload, STRLEN plen);
    int (*bus_subscribe)(pTHX_ const char *topic, STRLEN tlen,
                         const char *group, STRLEN glen,
                         hm_abi_bus_cb cb, void *ud);
    int (*bus_unsubscribe)(pTHX_ int id);

    /* Run this process's subscriptions now, returning how many messages
     * reached a subscriber. The wakeup calls this; a consumer calls it when
     * it wants the local half of its own publish to have happened before it
     * returns - which is the only way to answer "how many got it" without
     * inventing a number. */
    int (*bus_dispatch)(pTHX);

    /* ---- v6: stream handles -------------------------------------------
     *
     * conn_detach hands over a file descriptor, which is why it refuses
     * HTTP/2 (-2) and TLS (-3): an h2 stream is one of many on a shared
     * connection and there is no fd that means "this stream", and a TLS
     * session's state belongs to the server. Those refusals are correct,
     * so the transport-neutral seam is a STREAM HANDLE rather than an fd.
     *
     * stream_open sends status + headers and returns an opaque handle, or
     * NULL if the ticket names no live connection, a response has already
     * been sent on it, or - on HTTP/1.1 - the response has not been deferred
     * yet. Deferred means a psgi.streaming coderef or a handler parked on a
     * Future: a synchronous handler's return value would be serialised on
     * top of the body being streamed. (fd, id, stream_id) is the ticket
     * published as psgix.hyperman.stream, which is [fd, generation, -1] on
     * HTTP/1.1 and [fd, generation, stream id] on HTTP/2. It is a separate
     * key from psgix.hyperman.conn, which names an fd an application may
     * take over and which HTTP/2 has nothing to put behind.
     * headers is a PSGI header arrayref [k, v, k, v, ...] rather
     * than a byte string, so h2 can hand it to nghttp2 as nghttp2_nv[]
     * instead of reparsing it; hop-by-hop names are dropped there.
     *
     * The handle carries its own generation guard, so a write after the
     * connection died is HM_ABI_STREAM_GONE and never a use-after-free.
     * The CALLER owns it from stream_open until stream_close, which is the
     * only entry point that frees it - a stream that is aborted underneath
     * you still has to be closed. Passing a handle that is not live is
     * HM_ABI_STREAM_STALE, not a crash.
     *
     * stream_write copies buf; a NULL buf with a non-zero len is
     * HM_ABI_STREAM_ARG. HM_ABI_STREAM_FULL means the bytes were taken but
     * the connection is holding more than HM_ABI_STREAM_HIWAT unwritten:
     * a well-behaved producer pauses there and resumes from on_drain.
     *
     * stream_close ends the body. It returns HM_ABI_STREAM_GONE if the
     * stream had already died, and releases the handle either way.
     *
     * stream_abort (v7) is the OTHER ending, for a producer that failed half
     * way. A body of undeclared length has no length for the peer to check,
     * so a stream that stops early and closes cleanly is received as a
     * complete short body. What telling the peer means differs by transport:
     *
     *   HTTP/2   RST_STREAM with INTERNAL_ERROR. In-protocol, and it kills
     *            this stream alone - the other streams on the connection are
     *            untouched, which is the whole reason a multiplexed
     *            transport needs its own verb here.
     *   HTTP/1.1 the connection is reset rather than closed. An EOF-delimited
     *            body ends at the close, so a graceful close IS the success
     *            signal and there is nothing else left to say; a TCP reset is
     *            the only thing a client can tell apart from it. Output still
     *            queued is discarded, which is the price of saying so.
     *
     * Like stream_close it releases the handle, returns HM_ABI_STREAM_GONE
     * for a stream that had already died, and HM_ABI_STREAM_STALE for a
     * pointer that was never live. A producer calls one or the other, never
     * both. It does NOT fire this stream's own on_abort: the caller is the
     * one doing the aborting and already knows.
     *
     * on_drain fires when output that was over the high-water mark has gone
     * out. on_abort fires once when the stream dies before it was closed - an
     * h2 RST_STREAM, or the connection going away - which is what detach
     * cannot report: a multiplexed peer can kill one stream and the producer
     * has to hear about it. Registering on_abort on an already-dead stream
     * fires it immediately, the way future_on_ready settles, so the wakeup
     * cannot be lost to a race. Each replaces any previous registration; a
     * NULL cb removes one. Both return HM_ABI_STREAM_STALE for a dead
     * handle. */
    void *(*stream_open)(pTHX_ void *loop, int fd, UV id, int64_t stream_id,
                         int status, SV *headers);
    int   (*stream_write)(pTHX_ void *h, const char *buf, STRLEN len);
    int   (*stream_close)(pTHX_ void *h);
    int   (*stream_on_drain)(pTHX_ void *h, hm_abi_stream_cb cb, void *ud);
    int   (*stream_on_abort)(pTHX_ void *h, hm_abi_stream_cb cb, void *ud);

    /* ---- v7 ------------------------------------------------------------ */
    int   (*stream_abort)(pTHX_ void *h);

    /* ---- v8: the read half ---------------------------------------------
     *
     * Everything above writes. That is the whole of an ordinary response,
     * and it was deliberately all Phase 2 built - but it is not enough for
     * a stream that carries traffic in both directions, which is what
     * Extended CONNECT (RFC 8441 on h2, RFC 9220 on h3) opens.
     *
     * With a data callback registered, request bytes on this stream are
     * handed straight to it INSTEAD of being accumulated into psgi.input.
     * That is the point: a tunnelled stream has no end, so buffering it
     * would grow without bound and the application would never see any of
     * it. Registering on a stream whose body has already been buffered and
     * dispatched is allowed and simply delivers nothing further.
     *
     * A NULL cb removes the registration and restores buffering.
     * HM_ABI_STREAM_STALE for a handle that is not live. */
    int   (*stream_on_data)(pTHX_ void *h, hm_abi_stream_data_cb cb, void *ud);
} hm_abi;

/* How many worker-start callbacks the server will hold. Fixed, so
 * registration allocates nothing. */
#define HM_ABI_MAX_WORKER_CB 8

#endif /* HM_ABI_H */
