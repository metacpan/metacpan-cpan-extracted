#ifndef HM_ABI_IMPL_H
#define HM_ABI_IMPL_H

/* Provider side of the public C ABI (hm_abi.h): thin wrappers translating
 * the stable table entries onto the hm_* / hmf_* internals, plus the filled
 * table itself. Consumers reach it via Hyperman::_abi_ptr (xs/abi.xs).
 * Requires hm_future.h and hm_core.h (included before this file). */

static void *hm_abi_cur_loop(pTHX) {
    PERL_UNUSED_CONTEXT;
    return (void *)hm_cur_loop;
}

static void *hm_abi_loop_of_sv(pTHX_ SV *loop_sv) {
    return (void *)hm_loop_from_sv(aTHX_ loop_sv);
}

/* Shared wrapper, same caching as psgix.loop: one blessed SV per loop, so a
 * consumer never holds a second independently-destroyed wrapper. */
static SV *hm_abi_sv_of_loop(pTHX_ void *vl) {
    hm_loop *loop = (hm_loop *)vl;
    if (!loop->self_sv) loop->self_sv = hm_loop_to_sv(aTHX_ loop);
    return SvREFCNT_inc(loop->self_sv);
}

static void hm_abi_io_watch(pTHX_ void *vl, int fd, int mask,
                            hm_abi_io_cb cb, void *ud) {
    hm_add_io_watch_c(aTHX_ (hm_loop *)vl, fd, mask, cb, ud);
}

static void hm_abi_io_unwatch(pTHX_ void *vl, int fd, int mask) {
    hm_del_io_watch(aTHX_ (hm_loop *)vl, fd, mask);
}

static hm_abi_timer *hm_abi_timer_add(pTHX_ void *vl, double secs,
                                      hm_abi_timer_cb cb, void *ud) {
    PERL_UNUSED_CONTEXT;
    return (hm_abi_timer *)hm_add_timer_watch_c((hm_loop *)vl, secs, cb, ud);
}

static void hm_abi_timer_cancel(pTHX_ void *vl, hm_abi_timer *t) {
    hm_del_timer_watch(aTHX_ (hm_loop *)vl, (hm_tw *)t);
}

static SV *hm_abi_future_new(pTHX) {
    return hmf_new(aTHX_ "Hyperman::Future");
}

static int hm_abi_is_future(pTHX_ SV *sv) {
    return hmf_is_future(aTHX_ sv);
}

static IV hm_abi_future_state(pTHX_ SV *f) {
    return hmf_state(aTHX_ f);
}

static void hm_abi_future_done(pTHX_ SV *f, SV **vals, SSize_t n) {
    if (hmf_state(aTHX_ f) != HMF_PENDING) return;
    hmf_settle(aTHX_ f, HMF_DONE, vals, n);
}

static void hm_abi_future_fail(pTHX_ SV *f, SV *err) {
    if (hmf_state(aTHX_ f) != HMF_PENDING) return;
    hmf_settle(aTHX_ f, HMF_FAILED, &err, 1);
}

/* on_ready continuation body: unbox the C fn + ud from the closure and call
 * it with the future (ST(0), pushed by the fire queue). */
XS_INTERNAL(hm_xs_abi_ready_cb);
XS_INTERNAL(hm_xs_abi_ready_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    hm_abi_ready_cb cb;
    if (!cl || items < 1) XSRETURN_EMPTY;
    cb = (hm_abi_ready_cb)INT2PTR(void *, cl->i);
    cb(aTHX_ ST(0), INT2PTR(void *, cl->u));
    XSRETURN_EMPTY;
}

static void hm_abi_future_on_ready(pTHX_ SV *f, hm_abi_ready_cb cb, void *ud) {
    SV *cbsv = hm_closure(aTHX_ hm_xs_abi_ready_cb, NULL, NULL, NULL, NULL,
                          PTR2IV(cb), PTR2UV(ud));
    hmf_on_ready(aTHX_ f, cbsv);
    SvREFCNT_dec(cbsv);
}

static void hm_abi_run_until(pTHX_ void *vl, SV *f) {
    hm_loop_run(aTHX_ (hm_loop *)vl, f);
}

static int hm_abi_conn_detach(pTHX_ void *vl, int fd, UV id) {
    return hm_detach(aTHX_ (hm_loop *)vl, fd, id);
}

/* v3: abuse controls. Plain forwards onto the shared arena (hm_ratelimit.h);
 * no pTHX, no SV - the arena is process-global. */
static int  hm_abi_deny_check(const char *ip)            { return hm_rl_deny_check(ip); }
static void hm_abi_deny_add(const char *ip, long ttl)    { hm_rl_deny_add(ip, ttl); }
static void hm_abi_deny_remove(const char *ip)           { hm_rl_deny_remove(ip); }
static int  hm_abi_ratelimit_hit(const void *key, STRLEN klen,
                                 IV limit, IV window, IV *remaining, IV *reset) {
    long rem = 0, rst = 0;
    int ok = hm_rl_ratelimit_hit(key, (size_t)klen, (long)limit, (long)window,
                                 &rem, &rst);
    if (remaining) *remaining = (IV)rem;
    if (reset)     *reset     = (IV)rst;
    return ok;
}

/* ---- v5: the bus -------------------------------------------------------- */

static int hm_abi_bus_publish(const char *topic, STRLEN tlen,
                              const char *payload, STRLEN plen) {
#if HM_BUS_HAVE_ATOMICS
    int r = hm_bus_publish(topic, (uint32_t)tlen, payload, (uint32_t)plen);
    return r == HM_BUS_OK ? 1 : r == HM_BUS_LOCAL ? 0 : -1;
#else
    (void)topic; (void)tlen; (void)payload; (void)plen;
    return 0;
#endif
}

/* The ABI's callback takes pTHX and no sequence; the ring's takes a sequence
 * and no pTHX. This is the shim between them, so the ABI can stay a stable C
 * surface while the ring's internals move. */
typedef struct { hm_abi_bus_cb cb; void *ud; } hm_abi_bus_sub;
static hm_abi_bus_sub hm_abi_bus_subs[HM_BUS_SUBS];

static void hm_abi_bus_trampoline(void *ud, uint64_t seq, const char *topic,
                                  uint32_t tlen, const char *payload,
                                  uint32_t plen) {
    dTHX;
    hm_abi_bus_sub *s = (hm_abi_bus_sub *)ud;
    (void)seq;
    if (s && s->cb)
        s->cb(aTHX_ topic, (STRLEN)tlen, payload, (STRLEN)plen, s->ud);
}

static int hm_abi_bus_subscribe(pTHX_ const char *topic, STRLEN tlen,
                                const char *group, STRLEN glen,
                                hm_abi_bus_cb cb, void *ud) {
    int id;
    PERL_UNUSED_CONTEXT;
    if (!cb) return -1;
    id = hm_bus_subscribe(topic, (uint32_t)tlen, group, (uint32_t)glen,
                          hm_abi_bus_trampoline, NULL);
    if (id < 0) return -1;
    hm_abi_bus_subs[id].cb = cb;
    hm_abi_bus_subs[id].ud = ud;
    hm_bus_subs[id].ud     = &hm_abi_bus_subs[id];
    return id;
}

static int hm_abi_bus_unsubscribe(pTHX_ int id) {
    PERL_UNUSED_CONTEXT;
    if (id >= 0 && id < HM_BUS_SUBS) {
        hm_abi_bus_subs[id].cb = NULL;
        hm_abi_bus_subs[id].ud = NULL;
    }
    return hm_bus_unsubscribe(id);
}

static int hm_abi_bus_dispatch(pTHX) {
    PERL_UNUSED_CONTEXT;
    return (int)hm_bus_dispatch();
}

static const hm_abi hm_abi_table = {
    HM_ABI_VERSION,
    hm_abi_cur_loop,
    hm_abi_loop_of_sv,
    hm_abi_sv_of_loop,
    hm_abi_io_watch,
    hm_abi_io_unwatch,
    hm_abi_timer_add,
    hm_abi_timer_cancel,
    hm_abi_future_new,
    hm_abi_is_future,
    hm_abi_future_state,
    hm_abi_future_done,
    hm_abi_future_fail,
    hm_abi_future_on_ready,
    hm_abi_run_until,
    hm_abi_conn_detach,          /* v2 */
    hm_abi_deny_check,           /* v3 */
    hm_abi_deny_add,
    hm_abi_deny_remove,
    hm_abi_ratelimit_hit,
    hm_worker_hook_add,          /* v4 */
    hm_abi_bus_publish,          /* v5 */
    hm_abi_bus_subscribe,
    hm_abi_bus_unsubscribe,
    hm_abi_bus_dispatch,
    hm_stream_open,              /* v6 - the registry lives in hm_stream.h, */
    hm_stream_write_h,           /* which owns the transport branch so the  */
    hm_stream_close_h,           /* table can stay four plain forwards      */
    hm_stream_on_drain,
    hm_stream_on_abort,
    hm_stream_abort_h,           /* v7 - the ending a failed producer needs */
    hm_stream_on_data,           /* v8 - the read half                     */
};

/* ---- v4 on_worker_start, driven from C (t/33-worker-start.t) ------------ *
 * A Perl test cannot register a C callback, so the observable half lives
 * here: _abi_worker_hook_install registers this through the TABLE, and the
 * worker it fires in reports the count back through an ordinary request. The
 * count is a plain static, so it is inherited as 0 across the fork and each
 * worker increments its own copy - which is exactly the property being
 * tested. */
static IV  HM_ABI_ST_WORKER_N = 0;
static int HM_ABI_ST_WORKER_LOOP_OK = 1;

static void hm_abi_st_worker_cb(pTHX_ void *loop, void *ud) {
    PERL_UNUSED_ARG(ud);
    if (!loop) HM_ABI_ST_WORKER_LOOP_OK = 0;   /* must be handed a real loop */
    HM_ABI_ST_WORKER_N++;
}

/* Register through the table, not by calling hm_worker_hook_add directly -
 * the point of a selftest is to prove the function pointer works. */
static int hm_abi_worker_hook_install(pTHX) {
    const hm_abi *A = INT2PTR(const hm_abi *, PTR2IV(&hm_abi_table));
    if (!A || A->abi_version != HM_ABI_VERSION) return 0;
    return A->on_worker_start(aTHX_ hm_abi_st_worker_cb, NULL);
}

/* ---- v6 stream handles, driven from C (t/41-stream-abi.t) --------------- *
 *
 * The static half - that the entries exist and that a stale handle is an
 * error return rather than a crash - is in hm_abi_selftest below. This is the
 * live half, which needs a real connection and therefore a real server: an
 * application calls these from inside a request, the C side does everything
 * through the TABLE, and a later request reads the counters back out.
 *
 * One handle at a time, in a process-global, because the tests that use it
 * run with workers => 1 and a single handle is what makes "did the abort
 * fire" answerable from Perl at all. */
static void *HM_ABI_ST_SH        = NULL;
static IV    HM_ABI_ST_SH_ABORTS = 0;
static IV    HM_ABI_ST_SH_DRAINS = 0;
static IV    HM_ABI_ST_SH_WRITES = 0;
static IV    HM_ABI_ST_SH_TODO   = 0;   /* chunks still owed on the stream */
static IV    HM_ABI_ST_SH_FULLS  = 0;   /* times the connection said stop  */

static void hm_abi_st_stream_abort(pTHX_ void *h, void *ud) {
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(ud);
    HM_ABI_ST_SH_ABORTS++;
    HM_ABI_ST_SH_TODO = 0;              /* nobody is listening any more */
    /* The handle survives an abort - only stream_close frees it - so it is
     * deliberately NOT released here. The test's next request closes it and
     * proves the release path copes with a stream that died first. */
    (void)h;
}

/* Produce until the connection says stop, then stop until it says go. This is
 * the whole backpressure contract, and it is the only honest way to test it:
 * a producer that only ever writes small chunks never reaches it. */
static void hm_abi_st_stream_pump(pTHX_ void *h) {
    const hm_abi *A = &hm_abi_table;
    char buf[4096];
    memset(buf, 'x', sizeof buf);
    while (HM_ABI_ST_SH_TODO > 0) {
        int r = A->stream_write(aTHX_ h, buf, sizeof(buf));
        if (r < 0) { HM_ABI_ST_SH_TODO = 0; return; }
        HM_ABI_ST_SH_TODO--;
        HM_ABI_ST_SH_WRITES++;
        if (r == HM_ABI_STREAM_FULL) { HM_ABI_ST_SH_FULLS++; return; }
    }
    if (HM_ABI_ST_SH == h) {
        A->stream_close(aTHX_ h);
        HM_ABI_ST_SH = NULL;
    }
}

static void hm_abi_st_stream_drain(pTHX_ void *h, void *ud) {
    PERL_UNUSED_ARG(ud);
    HM_ABI_ST_SH_DRAINS++;
    hm_abi_st_stream_pump(aTHX_ h);
}

/* Open a stream on the request this env names, over whichever transport it
 * arrived on. 1 = open, 0 = refused. */
static int hm_abi_st_stream_open(pTHX_ SV *env, int status, SV *headers) {
    const hm_abi *A = &hm_abi_table;
    int fd;
    UV id;
    int64_t sid;
    if (HM_ABI_ST_SH) return 0;                  /* one at a time */
    if (!hm_stream_ticket(aTHX_ env, &fd, &id, &sid)) return 0;
    HM_ABI_ST_SH = A->stream_open(aTHX_ (void *)hm_cur_loop, fd, id, sid,
                                  status, headers);
    if (!HM_ABI_ST_SH) return 0;
    HM_ABI_ST_SH_WRITES = 0;
    A->stream_on_abort(aTHX_ HM_ABI_ST_SH, hm_abi_st_stream_abort, NULL);
    A->stream_on_drain(aTHX_ HM_ABI_ST_SH, hm_abi_st_stream_drain, NULL);
    return 1;
}

static int hm_abi_st_stream_write(pTHX_ SV *data) {
    const hm_abi *A = &hm_abi_table;
    STRLEN l;
    const char *p;
    int r;
    if (!HM_ABI_ST_SH) return HM_ABI_STREAM_STALE;
    p = SvPV(data, l);
    r = A->stream_write(aTHX_ HM_ABI_ST_SH, p, l);
    if (r >= 0) HM_ABI_ST_SH_WRITES++;
    return r;
}

/* Owe the stream n chunks of 4KiB and start producing them. */
static void hm_abi_st_stream_produce(pTHX_ IV n) {
    if (!HM_ABI_ST_SH) return;
    HM_ABI_ST_SH_TODO = n;
    hm_abi_st_stream_pump(aTHX_ HM_ABI_ST_SH);
}

/* v8: what the read half delivered, echoed back so a Perl test can see it.
 * Bounded - this is a test hook on an unbounded stream, and an unbounded
 * buffer behind a test hook is still an unbounded buffer. */
static char HM_ABI_ST_SH_RX[4096];
static IV   HM_ABI_ST_SH_RXLEN = 0;
static IV   HM_ABI_ST_SH_RXN   = 0;

static void hm_abi_st_stream_data(pTHX_ void *h, const char *buf, STRLEN len,
                                  int fin, void *ud) {
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(ud);
    (void)h; (void)fin;
    HM_ABI_ST_SH_RXN++;
    if (len > sizeof(HM_ABI_ST_SH_RX) - (size_t)HM_ABI_ST_SH_RXLEN)
        len = sizeof(HM_ABI_ST_SH_RX) - (size_t)HM_ABI_ST_SH_RXLEN;
    if (len) {
        memcpy(HM_ABI_ST_SH_RX + HM_ABI_ST_SH_RXLEN, buf, len);
        HM_ABI_ST_SH_RXLEN += (IV)len;
    }
}

/* Register the read half on the open handle, through the TABLE. */
static int hm_abi_st_stream_read(pTHX) {
    const hm_abi *A = &hm_abi_table;
    if (!HM_ABI_ST_SH) return HM_ABI_STREAM_STALE;
    HM_ABI_ST_SH_RXLEN = 0;
    HM_ABI_ST_SH_RXN   = 0;
    return A->stream_on_data(aTHX_ HM_ABI_ST_SH, hm_abi_st_stream_data, NULL);
}

static int hm_abi_st_stream_close(pTHX) {
    const hm_abi *A = &hm_abi_table;
    int r;
    if (!HM_ABI_ST_SH) return HM_ABI_STREAM_STALE;
    r = A->stream_close(aTHX_ HM_ABI_ST_SH);
    HM_ABI_ST_SH = NULL;
    return r;
}

/* The other ending, so t/41-stream-abi.t can drive it over both transports.
 * Releases the handle exactly as close does - a producer calls one or the
 * other, and the selftest must not be the thing that gets that wrong. */
static int hm_abi_st_stream_do_abort(pTHX) {
    const hm_abi *A = &hm_abi_table;
    int r;
    if (!HM_ABI_ST_SH) return HM_ABI_STREAM_STALE;
    r = A->stream_abort(aTHX_ HM_ABI_ST_SH);
    HM_ABI_ST_SH = NULL;
    return r;
}

/* ---- _abi_selftest: drive the whole table from C (t/22-abi.t) ----------- */

static void hm_abi_st_ready(pTHX_ SV *f, void *ud) {
    PERL_UNUSED_VAR(f);
    *(int *)ud = 1;
}

static void hm_abi_st_timer(pTHX_ void *ud) {
    hm_abi_table.future_done(aTHX_ (SV *)ud, NULL, 0);
}

typedef struct { SV *f; void *loop; } hm_abi_st_io;

static void hm_abi_st_io_cb(pTHX_ int fd, int mask, void *ud) {
    hm_abi_st_io *st = (hm_abi_st_io *)ud;
    char b;
    PERL_UNUSED_VAR(mask);
    if (read(fd, &b, 1) < 0) { /* settle anyway; the test checks the future */ }
    hm_abi_table.io_unwatch(aTHX_ st->loop, fd, HM_ABI_READ);
    hm_abi_table.future_done(aTHX_ st->f, NULL, 0);
}

static int hm_abi_selftest(pTHX) {
    const hm_abi *A = &hm_abi_table;
    int ok = 1;
    if (A->abi_version != HM_ABI_VERSION) return 0;

    /* future lifecycle: new -> pending -> on_ready (C) -> done -> fired */
    {
        SV *f = A->future_new(aTHX);
        int fired = 0;
        SV *val = sv_2mortal(newSViv(42));
        if (!A->is_future(aTHX_ f))                      ok = 0;
        if (A->future_state(aTHX_ f) != HM_ABI_PENDING)  ok = 0;
        A->future_on_ready(aTHX_ f, hm_abi_st_ready, &fired);
        A->future_done(aTHX_ f, &val, 1);
        A->future_done(aTHX_ f, &val, 1);   /* second settle: no-op */
        if (!fired)                                      ok = 0;
        if (A->future_state(aTHX_ f) != HM_ABI_DONE)     ok = 0;
        SvREFCNT_dec(f);
    }

    /* failure path */
    {
        SV *f = A->future_new(aTHX);
        SV *err = sv_2mortal(newSVpvs("nope"));
        A->future_fail(aTHX_ f, err);
        if (A->future_state(aTHX_ f) != HM_ABI_FAILED)   ok = 0;
        SvREFCNT_dec(f);
    }

    /* loop: C io watcher on a readable pipe, a cancelled timer that must not
     * fire, and a live C timer settling the second future */
    {
        hm_loop *loop = hm_loop_new(aTHX_ NULL);
        int fds[2];
        if (!loop) return 0;
        /* hm_os_selfpipe, not pipe(2): on Windows the readiness backend
         * polls sockets only, so the pair has to be a loopback connection
         * there. hm_os_send/hm_os_close write and close either kind. */
        if (hm_os_selfpipe(&fds[0], &fds[1]) == 0) {
            SV *fio = A->future_new(aTHX);
            SV *ftw = A->future_new(aTHX);
            hm_abi_st_io st;
            hm_abi_timer *dead;
            st.f    = fio;
            st.loop = (void *)loop;
            if (hm_os_send(fds[1], "x", 1) < 0) ok = 0;
            A->io_watch(aTHX_ (void *)loop, fds[0], HM_ABI_READ,
                        hm_abi_st_io_cb, &st);
            dead = A->timer(aTHX_ (void *)loop, 3600.0, hm_abi_st_timer, ftw);
            A->timer_cancel(aTHX_ (void *)loop, dead);
            A->timer(aTHX_ (void *)loop, 0.01, hm_abi_st_timer, ftw);
            A->run_until(aTHX_ (void *)loop, fio);
            if (A->future_state(aTHX_ fio) != HM_ABI_DONE) ok = 0;
            A->run_until(aTHX_ (void *)loop, ftw);
            if (A->future_state(aTHX_ ftw) != HM_ABI_DONE) ok = 0;
            SvREFCNT_dec(fio);
            SvREFCNT_dec(ftw);
            hm_os_close(fds[0]);
            hm_os_close(fds[1]);
        } else ok = 0;

        /* v2 conn_detach: the entry is present and rejects tickets that
         * name no connection. The success path needs a live HTTP
         * connection and is covered end to end by t/23-detach.t. */
        if (!A->conn_detach)                                      ok = 0;
        else if (A->conn_detach(aTHX_ (void *)loop, 4094, 1) != -1) ok = 0;

        /* v6 stream handles. The success path needs a live request and is
         * covered end to end by t/41-stream-abi.t, over HTTP/1.1 and over
         * HTTP/2. What is provable with no connection is the half that
         * matters most for memory safety: a ticket naming nothing hands
         * back no handle, and every entry point given a pointer that is not
         * a live handle SAYS SO instead of dereferencing it. The address
         * below is deliberately a plausible-looking one. */
        if (!A->stream_open || !A->stream_write || !A->stream_close
            || !A->stream_on_drain || !A->stream_on_abort
            || !A->stream_abort)                                  ok = 0;
        else {
            void *bogus = (void *)&hm_abi_table;    /* real memory, no handle */
            if (A->stream_abort(aTHX_ bogus) != HM_ABI_STREAM_STALE) ok = 0;
            if (A->stream_abort(aTHX_ NULL)  != HM_ABI_STREAM_STALE) ok = 0;
            if (A->stream_open(aTHX_ (void *)loop, 4094, 1, -1, 200, NULL))
                                                                  ok = 0;
            if (A->stream_open(aTHX_ (void *)loop, 4094, 1, 3, 200, NULL))
                                                                  ok = 0;
            if (A->stream_write(aTHX_ bogus, "x", 1) != HM_ABI_STREAM_STALE)
                                                                  ok = 0;
            if (A->stream_write(aTHX_ NULL, "x", 1) != HM_ABI_STREAM_STALE)
                                                                  ok = 0;
            if (A->stream_close(aTHX_ bogus) != HM_ABI_STREAM_STALE) ok = 0;
            if (A->stream_on_drain(aTHX_ bogus, NULL, NULL)
                != HM_ABI_STREAM_STALE)                           ok = 0;
            if (A->stream_on_abort(aTHX_ bogus, NULL, NULL)
                != HM_ABI_STREAM_STALE)                           ok = 0;
        }

        hm_loop_free(aTHX_ loop);
    }

    /* v3 abuse controls, driven through the table. Init the arena here so the
     * selftest exercises them even with no server running (idempotent). */
    {
        IV rem = 0, rst = 0;
        hm_rl_arena_init(0, 0);
        if (!A->deny_check || !A->deny_add || !A->deny_remove
            || !A->ratelimit_hit)                                 ok = 0;
        else if (!hm_rl_arena_live()) {
            /* No arena on this platform: the contract is that every entry
             * point FAILS OPEN, and that is what gets asserted. Anything
             * else here would be testing a feature the build does not
             * have. (Windows, or a compiler without the atomics.) */
            A->deny_add("203.0.113.7", 0);
            if (A->deny_check("203.0.113.7") != 0)                ok = 0;
            A->deny_remove("203.0.113.7");
            if (A->ratelimit_hit("st", 2, 1, 60, &rem, &rst) != 1) ok = 0;
            if (A->ratelimit_hit("st", 2, 1, 60, &rem, &rst) != 1) ok = 0;
        }
        else {
            if (A->deny_check("203.0.113.7") != 0)                ok = 0;
            A->deny_add("203.0.113.7", 0);
            if (A->deny_check("203.0.113.7") != 1)                ok = 0;
            if (A->deny_check("203.0.113.8") != 0)                ok = 0;
            A->deny_remove("203.0.113.7");
            if (A->deny_check("203.0.113.7") != 0)                ok = 0;

            /* 2 per window: two allowed, the third over */
            if (A->ratelimit_hit("st", 2, 2, 60, &rem, &rst) != 1) ok = 0;
            if (A->ratelimit_hit("st", 2, 2, 60, &rem, &rst) != 1) ok = 0;
            if (A->ratelimit_hit("st", 2, 2, 60, &rem, &rst) != 0) ok = 0;
            if (rem != 0)                                          ok = 0;
            if (rst <= 0)                                          ok = 0;
            /* unlimited is always allowed */
            if (A->ratelimit_hit("st2", 3, 0, 60, &rem, &rst) != 1) ok = 0;
        }
    }

    return ok;
}

#endif /* HM_ABI_IMPL_H */
