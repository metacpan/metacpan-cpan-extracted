#ifndef HM_FUTURE_H
#define HM_FUTURE_H

/* Hyperman::Future - native array-slot async primitive.
 * Slots: 0 state, 1 result/failure AV, 2 callbacks, 3 weak upstream.
 * Continuations are trampolined through a fire queue, so long then-chains
 * run iteratively (bounded stack) with or without a loop.
 *
 * Everything here is C: chaining (then/else/followed_by/transform), the
 * combinators, and CPAN Future interop are implemented as anonymous XSUBs
 * carrying their captured state in magic (hm_clos) - no Perl closures. */

#define HMF_PENDING   0
#define HMF_DONE      1
#define HMF_FAILED    2
#define HMF_CANCELLED 3

static AV *hm_fq;                   /* pending (cb, future) pairs */
static int hm_fq_active;

struct hm_loop;
static void hm_loop_run(pTHX_ struct hm_loop *loop, SV *until);
static struct hm_loop *hm_cur_loop;

/* ---- C closures: anon XSUBs with captured SVs attached via magic ------- */

typedef struct {
    SV *a, *b, *c, *d;
    IV  i;
    UV  u;
} hm_clos;

static int hm_clos_free(pTHX_ SV *sv, MAGIC *mg) {
    hm_clos *cl = (hm_clos *)mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    if (cl) {
        if (cl->a) SvREFCNT_dec(cl->a);
        if (cl->b) SvREFCNT_dec(cl->b);
        if (cl->c) SvREFCNT_dec(cl->c);
        if (cl->d) SvREFCNT_dec(cl->d);
        free(cl);
        mg->mg_ptr = NULL;
    }
    return 0;
}

static MGVTBL hm_clos_vtbl = { NULL, NULL, NULL, NULL, hm_clos_free,
                               NULL, NULL, NULL };

static SV *hm_closure(pTHX_ XSUBADDR_t body, SV *a, SV *b, SV *c, SV *d,
                      IV i, UV u) {
    CV *cv = newXS(NULL, body, __FILE__);
    hm_clos *cl = (hm_clos *)hm_xcalloc(1, sizeof(hm_clos));
    cl->a = a ? SvREFCNT_inc(a) : NULL;
    cl->b = b ? SvREFCNT_inc(b) : NULL;
    cl->c = c ? SvREFCNT_inc(c) : NULL;
    cl->d = d ? SvREFCNT_inc(d) : NULL;
    cl->i = i;
    cl->u = u;
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &hm_clos_vtbl, (char *)cl, 0);
    return newRV_noinc((SV *)cv);
}

static hm_clos *hm_clos_of(pTHX_ CV *cv) {
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &hm_clos_vtbl);
    return mg ? (hm_clos *)mg->mg_ptr : NULL;
}

/* ---- core state ---------------------------------------------------------- */

static IV hmf_state(pTHX_ SV *self) {
    SV **s;
    /* A croak, not PENDING: every writer below dereferences the array, so a
     * class name or an unblessed scalar here was a segfault one call later
     * (Hyperman::Future->done(1)), and a ->get on one pumped the loop for
     * ever. Callers that may legitimately hold something else ask
     * hmf_is_future first. */
    if (!(self && SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVAV))
        croak("Hyperman::Future: not a future object");
    s = av_fetch((AV *)SvRV(self), 0, 0);
    return s ? SvIV(*s) : HMF_PENDING;
}

static int hmf_is_future(pTHX_ SV *sv) {
    return sv && SvROK(sv) && SvOBJECT(SvRV(sv))
        && sv_derived_from(sv, "Hyperman::Future");
}

/* Future-compatible: ours, or any object with an on_ready method. */
static int hm_is_awaitable(pTHX_ SV *sv) {
    if (hmf_is_future(aTHX_ sv)) return 1;
    if (sv && SvROK(sv) && SvOBJECT(SvRV(sv))) {
        HV *stash = SvSTASH(SvRV(sv));
        if (stash && gv_fetchmethod_autoload(stash, "on_ready", 0)) return 1;
    }
    return 0;
}

static AV *hmf_values_av(pTHX_ SV *self) {
    SV **v = av_fetch((AV *)SvRV(self), 1, 0);
    return (v && SvROK(*v)) ? (AV *)SvRV(*v) : NULL;
}

/* ---- trampoline ---------------------------------------------------------- */

/* SAVETMPS/FREETMPS around the drain, and they are the difference between a
 * server that runs for a week and one the kernel kills.
 *
 * The pair below is mortalised out of the queue, so without a temps frame of
 * its own the pump hangs them on whichever frame it was entered from. For a
 * timer that is the worker's event loop, which does not return while the
 * server is up: every Future ever resolved, and every callback attached to
 * one, is then held for the life of the process. A caller that reschedules
 * from its own callback - the shape every clock in an application has -
 * leaks one Future and one closure per tick, for ever.
 *
 * SAVETMPS sets a new floor rather than freeing what the caller mortalised
 * before calling in, so a caller's own temporaries are untouched. */
#include <stdarg.h>

/* The server's own messages: a dying handler, a refused response, a wedged
 * worker, a TLS reload that failed. One writer, so `error_log` can point them
 * all somewhere other than the inherited stderr. A whole line per call,
 * stamped like the access log and with the pid, written with one write(2) so
 * lines from several workers do not interleave. -1 means stderr. */
static int hm_err_fd = -1;
static void hm_errlog(const char *fmt, ...) {
    char buf[1024];
    size_t n = 0;
    struct tm tm;
    time_t t = time(NULL);
    va_list ap;
    int k;
    if (hm_localtime_r(&t, &tm))
        n = strftime(buf, sizeof(buf), "[%d/%b/%Y:%H:%M:%S %z] ", &tm);
    k = snprintf(buf + n, sizeof(buf) - n, "[%d] ", hm_os_getpid());
    if (k > 0) n += (size_t)k;
    va_start(ap, fmt);
    k = vsnprintf(buf + n, sizeof(buf) - n, fmt, ap);
    va_end(ap);
    if (k > 0) n += (size_t)k;
    if (n > sizeof(buf) - 2) n = sizeof(buf) - 2;
    while (n > 0 && (buf[n - 1] == '\n' || buf[n - 1] == '\r')) n--;
    /* One line per call: a die message quoting request data must not be
     * able to write a second, forged line into the error log. */
    {
        size_t i;
        for (i = 0; i < n; i++)
            if (buf[i] == '\n' || buf[i] == '\r') buf[i] = ' ';
    }
    buf[n++] = '\n';
    {
        int fd = hm_err_fd >= 0 ? hm_err_fd : 2;
        ssize_t w;
        do { w = hm_os_write_file(fd, buf, n); } while (w < 0 && errno == EINTR);
        (void)w;
    }
}

/* After a G_EVAL call: say what died, on the error log. Every callback
 * the loop runs is trapped, so an exception never unwinds through the C
 * loop (which would skip loop->running-- and leave this queue half drained)
 * - but it must not be silent either, or an app bug becomes a 500 with no
 * line in any log. */
static void hm_warn_died(pTHX_ const char *what) {
    STRLEN l;
    const char *m;
    if (!SvTRUE(ERRSV)) return;
    m = SvPV(ERRSV, l);
    hm_errlog("Hyperman: %s died: %.*s", what, (int)l, m);
}

static void hmf_pump(pTHX) {
    if (hm_fq_active) return;
    ENTER;
    SAVETMPS;
    SAVEINT(hm_fq_active);
    hm_fq_active = 1;
    while (av_len(hm_fq) >= 0) {
        SV *cb  = sv_2mortal(av_shift(hm_fq));
        SV *fut = sv_2mortal(av_shift(hm_fq));
        dSP;
        PUSHMARK(SP);
        XPUSHs(fut);
        PUTBACK;
        call_sv(cb, G_DISCARD | G_EVAL);
        hm_warn_died(aTHX_ "on_ready callback");
    }
    FREETMPS;
    LEAVE;
}

static void hmf_enqueue(pTHX_ SV *cb, SV *self) {
    av_push(hm_fq, SvREFCNT_inc(cb));
    av_push(hm_fq, SvREFCNT_inc(self));
    hmf_pump(aTHX);
}

static void hmf_fire(pTHX_ SV *self) {
    AV  *av = (AV *)SvRV(self);
    SV **slot = av_fetch(av, 2, 0);
    SV  *cbs = (slot && SvOK(*slot)) ? *slot : NULL;
    if (!cbs) return;
    SvREFCNT_inc(cbs);
    av_store(av, 2, &PL_sv_undef);
    if (SvROK(cbs) && SvTYPE(SvRV(cbs)) == SVt_PVAV) {
        AV *list = (AV *)SvRV(cbs);
        SSize_t i, n = av_len(list) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(list, i, 0);
            if (e) {
                av_push(hm_fq, SvREFCNT_inc(*e));
                av_push(hm_fq, SvREFCNT_inc(self));
            }
        }
    } else {
        av_push(hm_fq, SvREFCNT_inc(cbs));
        av_push(hm_fq, SvREFCNT_inc(self));
    }
    SvREFCNT_dec(cbs);
    hmf_pump(aTHX);
}

/* A future settles ONCE. The check is here, at the one place a state is
 * written, rather than at each caller: a continuation that ran a user
 * callback and then found its future cancelled meanwhile (the callback
 * closed the connection, say) used to flip CANCELLED to DONE, and every
 * callback registered after the cancel fired a second time. */
static void hmf_settle(pTHX_ SV *self, IV state, SV **vals, SSize_t n) {
    AV *av;
    AV *val;
    SSize_t i;
    if (hmf_state(aTHX_ self) != HMF_PENDING) return;
    av = (AV *)SvRV(self);
    val = newAV();
    for (i = 0; i < n; i++) av_push(val, newSVsv(vals[i]));
    av_store(av, 0, newSViv(state));
    av_store(av, 1, newRV_noinc((SV *)val));
    hmf_fire(aTHX_ self);
}

/* Takes ownership of vals either way. */
static void hmf_settle_av(pTHX_ SV *self, IV state, AV *vals) {
    AV *av;
    if (hmf_state(aTHX_ self) != HMF_PENDING) { SvREFCNT_dec((SV *)vals); return; }
    av = (AV *)SvRV(self);
    av_store(av, 0, newSViv(state));
    av_store(av, 1, newRV_noinc((SV *)vals));
    hmf_fire(aTHX_ self);
}

static SV *hmf_new(pTHX_ const char *classname) {
    AV *av = newAV();
    SV *rv;
    av_extend(av, 3);
    av_store(av, 0, newSViv(HMF_PENDING));
    rv = newRV_noinc((SV *)av);
    sv_bless(rv, gv_stashpv(classname, GV_ADD));
    return rv;
}

static const char *hmf_class_of(pTHX_ SV *self) {
    HV *stash = (SvROK(self) && SvOBJECT(SvRV(self))) ? SvSTASH(SvRV(self)) : NULL;
    return stash ? HvNAME(stash) : "Hyperman::Future";
}

/* Resolve a loop-created future with no values (readiness signals). */
static void hmf_done0(pTHX_ SV *fut) {
    if (hmf_state(aTHX_ fut) == HMF_PENDING)
        hmf_settle(aTHX_ fut, HMF_DONE, NULL, 0);
}

static void hmf_on_ready(pTHX_ SV *self, SV *cb) {
    if (hmf_state(aTHX_ self) != HMF_PENDING) {
        hmf_enqueue(aTHX_ cb, self);
    } else {
        AV *av = (AV *)SvRV(self);
        SV **slot = av_fetch(av, 2, 0);
        if (!slot || !SvOK(*slot)) {
            av_store(av, 2, newSVsv(cb));
        } else if (SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV) {
            av_push((AV *)SvRV(*slot), newSVsv(cb));
        } else {
            AV *list = newAV();
            av_push(list, SvREFCNT_inc(*slot));
            av_push(list, newSVsv(cb));
            av_store(av, 2, newRV_noinc((SV *)list));
        }
    }
}

/* on_ready that works on ours (direct) or any Future-compatible object. */
static void hm_any_on_ready(pTHX_ SV *f, SV *cb) {
    if (hmf_is_future(aTHX_ f)) {
        hmf_on_ready(aTHX_ f, cb);
    } else {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(f);
        XPUSHs(cb);
        PUTBACK;
        call_method("on_ready", G_DISCARD);
        FREETMPS; LEAVE;
    }
}

static void hmf_set_upstream(pTHX_ SV *derived, SV *upstream) {
    SV *w;
    (void)hmf_state(aTHX_ derived);           /* croaks on a non-future */
    w = newSVsv(upstream);
    sv_rvweaken(w);
    av_store((AV *)SvRV(derived), 3, w);
}

static void hmf_cancel(pTHX_ SV *self);
static IV   hm_any_state(pTHX_ SV *f);

/* Cancel one awaitable of any class: ours directly, a foreign one through
 * its method, trapped so a class without `cancel` cannot unwind the loop. */
static void hm_any_cancel(pTHX_ SV *f) {
    if (hmf_is_future(aTHX_ f)) { hmf_cancel(aTHX_ f); return; }
    if (!(SvROK(f) && SvOBJECT(SvRV(f)))) return;
    {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(f);
        PUTBACK;
        call_method("cancel", G_DISCARD | G_EVAL);
        FREETMPS; LEAVE;
    }
}

/* Cancel every still-pending member of a combinator's input list, over a
 * snapshot: a cancellation fires that member's callbacks, one of which is
 * the combinator's own, which clears this very list. */
static void hmf_cancel_list(pTHX_ AV *list) {
    SSize_t i, n = av_len(list) + 1;
    SV **snap;
    if (n <= 0) return;
    snap = (SV **)hm_xmalloc(sizeof(SV *) * (size_t)n);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        snap[i] = e && *e ? SvREFCNT_inc(*e) : NULL;
    }
    for (i = 0; i < n; i++) {
        if (snap[i] && hm_any_state(aTHX_ snap[i]) == HMF_PENDING)
            hm_any_cancel(aTHX_ snap[i]);
    }
    for (i = 0; i < n; i++) if (snap[i]) SvREFCNT_dec(snap[i]);
    free(snap);
}

static void hmf_cancel(pTHX_ SV *self) {
    AV *av;
    SV **up;
    if (hmf_state(aTHX_ self) != HMF_PENDING) return;
    av = (AV *)SvRV(self);
    hmf_settle(aTHX_ self, HMF_CANCELLED, NULL, 0);
    /* propagate up a then-chain: cancelling a derived future cancels its
     * still-pending upstream - one future, or a combinator's whole list */
    up = av_fetch(av, 3, 0);
    if (!up || !SvROK(*up)) return;
    /* a future is a blessed array too: ask that first, and only an UNBLESSED
     * array is a combinator's input list */
    if (!hmf_is_future(aTHX_ *up)) {
        if (SvTYPE(SvRV(*up)) == SVt_PVAV && !SvOBJECT(SvRV(*up)))
            hmf_cancel_list(aTHX_ (AV *)SvRV(*up));
        return;
    }
    if (hmf_state(aTHX_ *up) == HMF_PENDING) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(*up);
        PUTBACK;
        call_method("cancel", G_DISCARD);
        FREETMPS; LEAVE;
    }
}

static void hmf_await(pTHX_ SV *self) {
    if (hmf_state(aTHX_ self) != HMF_PENDING) return;
    if (hm_cur_loop) {
        hm_loop_run(aTHX_ hm_cur_loop, self);
        if (hmf_state(aTHX_ self) != HMF_PENDING) return;
        croak("Hyperman::Future: loop stopped before the future was ready");
    }
    {
        SV *aw = get_sv("Hyperman::Future::AWAIT", 0);
        if (aw && SvOK(aw)) {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(self);
            PUTBACK;
            call_sv(aw, G_DISCARD);
            FREETMPS; LEAVE;
            if (hmf_state(aTHX_ self) != HMF_PENDING) return;
        }
    }
    croak("Cannot await a pending Hyperman::Future without an event loop");
}

/* ---- foreign-future compatibility --------------------------------------- */

/* state of ours (direct) or a foreign Future-like via method calls */
static IV hm_any_state(pTHX_ SV *f) {
    dSP;
    IV st = HMF_PENDING;
    int n;
    if (hmf_is_future(aTHX_ f)) return hmf_state(aTHX_ f);
    ENTER; SAVETMPS;
    PUSHMARK(SP); XPUSHs(f); PUTBACK;
    n = call_method("is_done", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (n && SvTRUE(TOPs)) st = HMF_DONE;
    (void)POPs;
    PUTBACK;
    if (st == HMF_PENDING) {
        PUSHMARK(SP); XPUSHs(f); PUTBACK;
        n = call_method("is_failed", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (n && SvTRUE(TOPs)) st = HMF_FAILED;
        (void)POPs;
        PUTBACK;
    }
    if (st == HMF_PENDING) {
        PUSHMARK(SP); XPUSHs(f); PUTBACK;
        n = call_method("is_cancelled", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (n && SvTRUE(TOPs)) st = HMF_CANCELLED;
        (void)POPs;
        PUTBACK;
    }
    FREETMPS; LEAVE;
    return st;
}

/* collect a method call's list results into out; returns 1 if it died */
static int hm_call_list(pTHX_ SV *invocant, const char *method, SV *cb,
                        SV **args, SSize_t nargs, AV *out) {
    dSP;
    SSize_t n, i;
    int err = 0;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    if (invocant) XPUSHs(invocant);
    for (i = 0; i < nargs; i++) XPUSHs(args[i]);
    PUTBACK;
    n = method ? call_method(method, G_ARRAY | G_EVAL)
               : call_sv(cb, G_ARRAY | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        err = 1;
        SP -= n;
    } else {
        SV **base = SP - n + 1;
        for (i = 0; i < n; i++) av_push(out, newSVsv(base[i]));
        SP -= n;
    }
    PUTBACK;
    FREETMPS; LEAVE;
    return err;
}

/* result (done) or failure (failed) values of ours or a foreign future */
static void hm_any_values(pTHX_ SV *f, IV st, AV *out) {
    if (hmf_is_future(aTHX_ f)) {
        AV *vals = hmf_values_av(aTHX_ f);
        SSize_t i, n = vals ? av_len(vals) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(vals, i, 0);
            av_push(out, e ? newSVsv(*e) : newSV(0));
        }
    } else if (st == HMF_DONE) {
        hm_call_list(aTHX_ f, "get", NULL, NULL, 0, out);
    } else if (st == HMF_FAILED) {
        hm_call_list(aTHX_ f, "failure", NULL, NULL, 0, out);
    }
}

/* ---- chaining ------------------------------------------------------------ */

XS_INTERNAL(hm_xs_chain_cb);
XS_INTERNAL(hm_xs_chain_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *g = ST(0);
    SV *next;
    IV st;
    if (!cl || items < 1) XSRETURN_EMPTY;
    next = cl->a;
    /* Cancelled while the inner future was still running: nothing to
     * deliver into, and settling it again would flip CANCELLED to DONE. */
    if (hmf_state(aTHX_ next) != HMF_PENDING) XSRETURN_EMPTY;
    st = hm_any_state(aTHX_ g);
    if (st == HMF_DONE || st == HMF_FAILED) {
        AV *vals = newAV();
        hm_any_values(aTHX_ g, st, vals);
        hmf_settle_av(aTHX_ next, st, vals);
    } else {
        hmf_cancel(aTHX_ next);
    }
    XSRETURN_EMPTY;
}

/* Perl's _chain_into: a returned future flattens; plain values resolve. */
static void hmf_chain_into(pTHX_ SV *next, AV *vals) {
    SV **first = av_len(vals) >= 0 ? av_fetch(vals, 0, 0) : NULL;
    if (first && hm_is_awaitable(aTHX_ *first)) {
        SV *cb = hm_closure(aTHX_ hm_xs_chain_cb, next, NULL, NULL, NULL, 0, 0);
        /* The returned future is now what `next` waits on, so cancelling
         * `next` must reach it - the same link then() made to its input. */
        hmf_set_upstream(aTHX_ next, *first);
        hm_any_on_ready(aTHX_ *first, cb);
        SvREFCNT_dec(cb);
        SvREFCNT_dec((SV *)vals);
    } else if (av_len(vals) < 0) {
        av_push(vals, newSV(0));   /* done(undef), as the reference impl did */
        hmf_settle_av(aTHX_ next, HMF_DONE, vals);
    } else {
        hmf_settle_av(aTHX_ next, HMF_DONE, vals);
    }
}

/* then/else/followed_by continuation. i: 0 = then (b=on_done, c=on_fail),
 * 1 = followed_by (b=cb). */
XS_INTERNAL(hm_xs_then_cb);
XS_INTERNAL(hm_xs_then_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f, *next;
    IV st;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    next = cl->a;
    st = hmf_state(aTHX_ f);

    /* `next` was cancelled after this fire was queued (the upstream had
     * already settled, so the cancel had nothing to propagate to): the
     * user's callback must not run and the state must not change. Checked
     * before BOTH branches; followed_by once ran its callback regardless. */
    if (hmf_state(aTHX_ next) != HMF_PENDING) XSRETURN_EMPTY;

    if (cl->i == 1) {                          /* followed_by: cb($f) */
        AV *out = newAV();
        SV *arg = f;
        if (hm_call_list(aTHX_ NULL, NULL, cl->b, &arg, 1, out)) {
            SV *err = sv_2mortal(newSVsv(ERRSV));
            hmf_settle(aTHX_ next, HMF_FAILED, &err, 1);
            SvREFCNT_dec((SV *)out);
        } else {
            hmf_chain_into(aTHX_ next, out);
        }
        XSRETURN_EMPTY;
    }

    if (st == HMF_DONE || st == HMF_FAILED) {
        SV *user = (st == HMF_DONE) ? cl->b : cl->c;
        AV *vals = hmf_values_av(aTHX_ f);
        SSize_t n = vals ? av_len(vals) + 1 : 0;
        if (user && SvOK(user)) {
            AV *out = newAV();
            SV **args = vals ? AvARRAY(vals) : NULL;
            if (hm_call_list(aTHX_ NULL, NULL, user, args, n, out)) {
                SV *err = sv_2mortal(newSVsv(ERRSV));
                hmf_settle(aTHX_ next, HMF_FAILED, &err, 1);
                SvREFCNT_dec((SV *)out);
            } else {
                hmf_chain_into(aTHX_ next, out);
            }
        } else {
            AV *copy = newAV();
            SSize_t i;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(vals, i, 0);
                av_push(copy, e ? newSVsv(*e) : newSV(0));
            }
            hmf_settle_av(aTHX_ next, st, copy);
        }
    } else {
        hmf_cancel(aTHX_ next);
    }
    XSRETURN_EMPTY;
}

/* transform continuation: b = done-mapper, c = fail-mapper */
XS_INTERNAL(hm_xs_transform_cb);
XS_INTERNAL(hm_xs_transform_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f, *next;
    IV st;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    next = cl->a;
    if (hmf_state(aTHX_ next) != HMF_PENDING) XSRETURN_EMPTY;   /* cancelled */
    st = hmf_state(aTHX_ f);
    if (st == HMF_DONE || st == HMF_FAILED) {
        SV *mapper = (st == HMF_DONE) ? cl->b : cl->c;
        AV *vals = hmf_values_av(aTHX_ f);
        SSize_t n = vals ? av_len(vals) + 1 : 0;
        AV *out = newAV();
        if (mapper && SvOK(mapper)) {
            SV **args = vals ? AvARRAY(vals) : NULL;
            if (hm_call_list(aTHX_ NULL, NULL, mapper, args, n, out)) {
                SV *err = sv_2mortal(newSVsv(ERRSV));
                hmf_settle(aTHX_ next, HMF_FAILED, &err, 1);
                SvREFCNT_dec((SV *)out);
                XSRETURN_EMPTY;
            }
        } else {
            SSize_t i;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(vals, i, 0);
                av_push(out, e ? newSVsv(*e) : newSV(0));
            }
        }
        hmf_settle_av(aTHX_ next, st, out);
    } else {
        hmf_cancel(aTHX_ next);
    }
    XSRETURN_EMPTY;
}

/* on_done / on_fail filter: b = user cb, i = required state */
XS_INTERNAL(hm_xs_ondone_cb);
XS_INTERNAL(hm_xs_ondone_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    if (hmf_state(aTHX_ f) == cl->i) {
        AV *vals = hmf_values_av(aTHX_ f);
        SSize_t n = vals ? av_len(vals) + 1 : 0;
        dSP;
        SSize_t j;
        ENTER; SAVETMPS; PUSHMARK(SP);
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(vals, j, 0);
            XPUSHs(e ? *e : &PL_sv_undef);
        }
        PUTBACK;
        call_sv(cl->b, G_DISCARD);
        FREETMPS; LEAVE;
    }
    XSRETURN_EMPTY;
}

/* Run one on_cancel target: a code ref is called with the future, anything
 * else is treated as a future and cancelled. Both spellings are needed
 * because the await protocol registers each - a code block through
 * AWAIT_ON_CANCEL, a future through AWAIT_CHAIN_CANCEL. */
static void hmf_cancel_target(pTHX_ SV *thing, SV *self) {
    dSP;
    if (!(thing && SvROK(thing))) return;
    ENTER; SAVETMPS; PUSHMARK(SP);
    if (SvTYPE(SvRV(thing)) == SVt_PVCV) {
        XPUSHs(self);
        PUTBACK;
        call_sv(thing, G_DISCARD);
    } else {
        XPUSHs(thing);
        PUTBACK;
        call_method("cancel", G_DISCARD);
    }
    FREETMPS; LEAVE;
}

/* on_cancel filter: b = target. Cancel callbacks ride the on_ready list
 * rather than a slot of their own - a future is already four slots wide and
 * two of them are allocated per parked request - so this fires on every
 * settlement and drops everything that is not a cancellation. */
XS_INTERNAL(hm_xs_oncancel_cb);
XS_INTERNAL(hm_xs_oncancel_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    if (hmf_state(aTHX_ f) == HMF_CANCELLED)
        hmf_cancel_target(aTHX_ cl->b, f);
    XSRETURN_EMPTY;
}

/* ---- convergent combinators --------------------------------------------- *
 * a = result future, b = remaining-count SV, c = subfutures AV ref,
 * i = mode. */
#define HM_COMB_WAIT_ALL  0
#define HM_COMB_WAIT_ANY  1
#define HM_COMB_NEEDS_ALL 2
#define HM_COMB_NEEDS_ANY 3

XS_INTERNAL(hm_xs_comb_cb);
XS_INTERNAL(hm_xs_comb_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *g, *res;
    AV *list;
    IV left;
    if (!cl || items < 1) XSRETURN_EMPTY;
    g = ST(0);
    res = cl->a;
    list = (AV *)SvRV(cl->c);
    if (hmf_state(aTHX_ res) != HMF_PENDING) XSRETURN_EMPTY;

    switch (cl->i) {
    case HM_COMB_WAIT_ALL: {
        left = SvIV(cl->b) - 1;
        sv_setiv(cl->b, left);
        if (left == 0) {
            AV *out = newAV();
            SSize_t i, n = av_len(list) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(list, i, 0);
                av_push(out, e ? newSVsv(*e) : newSV(0));
            }
            hmf_settle_av(aTHX_ res, HMF_DONE, out);
        }
        break;
    }
    case HM_COMB_WAIT_ANY: {
        IV st = hm_any_state(aTHX_ g);
        AV *out = newAV();
        hm_any_values(aTHX_ g, st, out);
        if (st == HMF_DONE || st == HMF_FAILED)
            hmf_settle_av(aTHX_ res, st, out);
        else {
            SvREFCNT_dec((SV *)out);
            hmf_cancel(aTHX_ res);
        }
        break;
    }
    case HM_COMB_NEEDS_ALL: {
        IV st = hm_any_state(aTHX_ g);
        if (st == HMF_FAILED) {
            AV *out = newAV();
            hm_any_values(aTHX_ g, st, out);
            hmf_settle_av(aTHX_ res, HMF_FAILED, out);
            break;
        }
        if (st == HMF_CANCELLED) { hmf_cancel(aTHX_ res); break; }
        left = SvIV(cl->b) - 1;
        sv_setiv(cl->b, left);
        if (left == 0) {
            AV *out = newAV();
            SSize_t i, n = av_len(list) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(list, i, 0);
                if (e) hm_any_values(aTHX_ *e, hm_any_state(aTHX_ *e), out);
            }
            hmf_settle_av(aTHX_ res, HMF_DONE, out);
        }
        break;
    }
    case HM_COMB_NEEDS_ANY: {
        IV st = hm_any_state(aTHX_ g);
        if (st == HMF_DONE) {
            AV *out = newAV();
            hm_any_values(aTHX_ g, st, out);
            hmf_settle_av(aTHX_ res, HMF_DONE, out);
            break;
        }
        left = SvIV(cl->b) - 1;
        sv_setiv(cl->b, left);
        if (left == 0) {
            AV *out = newAV();
            hm_any_values(aTHX_ g, st, out);
            hmf_settle_av(aTHX_ res, HMF_FAILED, out);
        }
        break;
    }
    }
    /* The result has settled: the inputs still running lost (wait_any's
     * others, the rest after needs_all's failure or needs_any's success)
     * and are cancelled, as CPAN Future does; and the list is emptied, which
     * breaks the cycle input -> callback -> list -> input that otherwise
     * kept every input alive for as long as the slowest one. */
    if (hmf_state(aTHX_ res) != HMF_PENDING) {
        hmf_cancel_list(aTHX_ list);
        av_clear(list);
    }
    XSRETURN_EMPTY;
}

/* shared combinator builder called from xs/future.xs */
static SV *hmf_combine(pTHX_ SV *classname, SV **futs, SSize_t n, IV mode) {
    SV *res = hmf_new(aTHX_ SvPV_nolen(classname));
    if (n == 0) {
        if (mode == HM_COMB_NEEDS_ANY) {
            SV *msg = sv_2mortal(newSVpvs("needs_any on empty list\n"));
            hmf_settle(aTHX_ res, HMF_FAILED, &msg, 1);
        } else if (mode == HM_COMB_WAIT_ANY) {
            SV *msg = sv_2mortal(newSVpvs("wait_any on empty list\n"));
            hmf_settle(aTHX_ res, HMF_FAILED, &msg, 1);
        } else {
            hmf_settle(aTHX_ res, HMF_DONE, futs, n);
        }
        return res;
    }
    {
        AV *list = newAV();
        SV *list_rv, *count;
        SSize_t i;
        for (i = 0; i < n; i++) av_push(list, SvREFCNT_inc(futs[i]));
        list_rv = sv_2mortal(newRV_noinc((SV *)list));
        count = sv_2mortal(newSViv(n));
        /* cancelling the result cancels what it waits on (hmf_cancel) */
        av_store((AV *)SvRV(res), 3, newSVsv(list_rv));
        for (i = 0; i < n; i++) {
            SV *cb = hm_closure(aTHX_ hm_xs_comb_cb, res, count, list_rv,
                                NULL, mode, 0);
            hm_any_on_ready(aTHX_ futs[i], cb);
            SvREFCNT_dec(cb);
        }
    }
    return res;
}

/* ---- CPAN Future interop ------------------------------------------------- */

/* mirror our resolution into a CPAN Future (a = the CPAN future) */
XS_INTERNAL(hm_xs_tocpan_cb);
XS_INTERNAL(hm_xs_tocpan_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *f;
    IV st;
    if (!cl || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    st = hmf_state(aTHX_ f);
    {
        dSP;
        AV *vals = hmf_values_av(aTHX_ f);
        SSize_t j, n = vals ? av_len(vals) + 1 : 0;
        const char *meth = (st == HMF_DONE)   ? "done"
                         : (st == HMF_FAILED) ? "fail"
                                              : "cancel";
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(cl->a);
        if (st == HMF_DONE || st == HMF_FAILED)
            for (j = 0; j < n; j++) {
                SV **e = av_fetch(vals, j, 0);
                XPUSHs(e ? *e : &PL_sv_undef);
            }
        PUTBACK;
        call_method(meth, G_DISCARD | G_EVAL);
        FREETMPS; LEAVE;
    }
    XSRETURN_EMPTY;
}

/* mirror a foreign future's resolution into ours (a = ours) */
XS_INTERNAL(hm_xs_fromcpan_cb);
XS_INTERNAL(hm_xs_fromcpan_cb) {
    dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    SV *o;
    IV st;
    if (!cl || items < 1) XSRETURN_EMPTY;
    o = ST(0);
    if (hmf_state(aTHX_ cl->a) != HMF_PENDING) XSRETURN_EMPTY;
    st = hm_any_state(aTHX_ o);
    if (st == HMF_DONE || st == HMF_FAILED) {
        AV *out = newAV();
        hm_any_values(aTHX_ o, st, out);
        hmf_settle_av(aTHX_ cl->a, st, out);
    } else {
        hmf_cancel(aTHX_ cl->a);
    }
    XSRETURN_EMPTY;
}

#endif /* HM_FUTURE_H */
