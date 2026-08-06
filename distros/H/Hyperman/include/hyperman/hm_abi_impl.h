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
};

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
        if (pipe(fds) == 0) {
            SV *fio = A->future_new(aTHX);
            SV *ftw = A->future_new(aTHX);
            hm_abi_st_io st;
            hm_abi_timer *dead;
            st.f    = fio;
            st.loop = (void *)loop;
            if (write(fds[1], "x", 1) < 0) ok = 0;
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
            close(fds[0]);
            close(fds[1]);
        } else ok = 0;
        hm_loop_free(aTHX_ loop);
    }

    return ok;
}

#endif /* HM_ABI_IMPL_H */
