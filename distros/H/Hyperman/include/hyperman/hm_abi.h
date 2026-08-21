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
 *   4 - on_worker_start (once per worker, after the fork, with its loop) */
#define HM_ABI_VERSION 5

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
} hm_abi;

/* How many worker-start callbacks the server will hold. Fixed, so
 * registration allocates nothing. */
#define HM_ABI_MAX_WORKER_CB 8

#endif /* HM_ABI_H */
