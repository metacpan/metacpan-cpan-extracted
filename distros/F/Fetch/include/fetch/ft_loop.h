#ifndef FT_LOOP_H
#define FT_LOOP_H

/* Fetch's minimal event loop: a readiness backend plus per-fd read/write
 * callbacks and timers, with run_until(future) for re-entrant awaiting. This
 * supplies the hm_loop_run + hm_cur_loop hook that ft_future.h's await path
 * calls. Far smaller than Hyperman's server loop - no connections, PSGI, or
 * idle/timeout sweeps; just IO readiness and timers.
 *
 * Must be included AFTER ft_future.h (which forward-declares struct hm_loop,
 * declares hm_loop_run, and defines the shared hm_cur_loop) and after the
 * backend .c files. */

#include <errno.h>

typedef struct ft_timer {
    SV               *cb;
    int               oneshot;
    UV                id;        /* the token the backend holds; never reused */
    double            secs;      /* as requested, for re-arming an interval */
    double            due;       /* monotonic deadline, for re-arming a oneshot */
    struct ft_timer  *next;
} ft_timer;

/* the monotonic clock the deadline backends already keep */
#ifdef _WIN32
#define ft_loop_now() hm_sel_now()
#else
#define ft_loop_now() hm_poll_now()
#endif

struct hm_loop {                 /* name matches ft_future.h's forward decl */
    hm_backend *be;              /* NULL between a fork and the child's first need */
    const char *be_name;         /* the backend to rebuild with (a static string) */
    IV          pid;             /* the process whose kernel object `be` is */
    SV        **rcb;             /* [HM_MAXFD] read-ready callbacks  */
    SV        **wcb;             /* [HM_MAXFD] write-ready callbacks */
    ft_timer   *timers;          /* live timers, for dispatch + cleanup */
    UV          last_timer_id;   /* monotonic; see ft_timer_token */
    int         stop;
    int         nio;             /* live fd interests, for the idle check */
};

/* What the backend is given to identify a timer, and gives back when one
 * fires. It is a counter, not the ft_timer address, because a cancelled timer
 * can still have an event in flight - queued in the kernel, or already in a
 * completion ring - and the freed struct is exactly the right size to be
 * handed straight back to the next ft_add_timer. Then the stale event names a
 * live timer and takes that down instead: the next request fails on a deadline
 * that was never its own. A counter is never reused, so the lookup below
 * simply does not find it and the event is dropped. */
#define ft_timer_token(id) INT2PTR(void *, (UV)(id))

typedef struct hm_loop ft_loop;
/* hm_cur_loop is defined (static) in ft_future.h; we only read/write it. */

static ft_timer *ft_timer_of_token(ft_loop *l, void *token) {
    UV        id = PTR2UV(token);
    ft_timer *t;
    for (t = l->timers; t; t = t->next) if (t->id == id) return t;
    return NULL;
}

static ft_loop *ft_loop_new(pTHX_ const char *name) {
    ft_loop *l = (ft_loop *)calloc(1, sizeof(ft_loop));
    if (!l) croak("Fetch::Loop: out of memory");
    l->be = hm_backend_create(name && *name ? name : NULL);
    if (!l->be) { free(l); croak("Fetch::Loop: no event backend available"); }
    l->be_name = l->be->name;
    l->pid     = (IV)PerlProc_getpid();
    l->rcb = (SV **)calloc(HM_MAXFD, sizeof(SV *));
    l->wcb = (SV **)calloc(HM_MAXFD, sizeof(SV *));
    if (!l->rcb || !l->wcb) croak("Fetch::Loop: out of memory");
    return l;
}

/* A loop inherited across a fork must never reach its backend again.
 *
 * The backend's kernel object is SHARED with the parent, not copied. An epoll
 * instance is one interest list for both processes, so a child "cleaning up"
 * its inherited watchers deregisters the parent's sockets and the parent
 * waits on an empty set forever. An io_uring is worse: the submission ring is
 * shared memory, while liburing's cursors are per-process copies that stop
 * agreeing the moment the parent submits again. The child's first
 * io_uring_submit then hands the kernel a wrapped-negative count, the kernel
 * pushes a full ring of stale entries, and the parent - now equally out of
 * step - loops on io_uring_enter submitting 1024 dead requests per call
 * until the machine runs out of memory. That is exactly what a forked test
 * server did at exit, through global destruction of a Fetch it never used.
 *
 * So the first call that finds the pid changed disowns the loop: the
 * inherited backend is released with `foreign` set (memory only, no
 * descriptor, no ring) and a fresh one is built only if this process goes
 * on to need one. A child that merely exits, running DESTROY on the way,
 * never creates a ring just to tear it down. The watcher and timer tables
 * are KEPT and mirrored onto the new backend when it is built: they are
 * the child's copies of live connections, and a parked connection revived
 * from the pool sends without re-arming, trusting that it is still
 * READ-armed exactly as it was parked. */
#define FT_LOOP_INHERITED(l) ((l)->pid != (IV)PerlProc_getpid())

static void ft_loop_disown(pTHX_ ft_loop *l) {
    l->pid = (IV)PerlProc_getpid();
    if (l->be) { l->be->foreign = 1; l->be->destroy(l->be); l->be = NULL; }
}

/* Called on every entry that can reach the backend: hands back a backend
 * this process owns, building one after a fork the first time it is needed.
 * NULL only when nothing is needed (need == 0) and there is none. */
static hm_backend *ft_loop_be(pTHX_ ft_loop *l, int need) {
    if (FT_LOOP_INHERITED(l)) ft_loop_disown(aTHX_ l);
    if (!l->be && need) {
        int       fd;
        ft_timer *t;
        double    now;
        l->be = hm_backend_create(l->be_name);
        if (!l->be) l->be = hm_backend_create(NULL);
        if (!l->be) croak("Fetch::Loop: no event backend available");
        for (fd = 0; fd < HM_MAXFD; fd++) {
            int mask = (l->rcb[fd] ? HM_EV_READ : 0) | (l->wcb[fd] ? HM_EV_WRITE : 0);
            if (mask) l->be->add_io(l->be, fd, mask, 0);
        }
        now = ft_loop_now();
        for (t = l->timers; t; t = t->next) {
            double left = t->oneshot ? t->due - now : t->secs;
            if (left < 0) left = 0;
            l->be->add_timer(l->be, left, t->oneshot, ft_timer_token(t->id));
        }
    }
    return l->be;
}

static void ft_loop_free(pTHX_ ft_loop *l) {
    int fd;
    ft_timer *t;
    if (!l) return;
    if (FT_LOOP_INHERITED(l)) ft_loop_disown(aTHX_ l);
    if (l->rcb) {
        for (fd = 0; fd < HM_MAXFD; fd++) {
            SV *cb = l->rcb[fd];
            if (cb) { l->rcb[fd] = NULL; SvREFCNT_dec(cb); }
        }
    }
    if (l->wcb) {
        for (fd = 0; fd < HM_MAXFD; fd++) {
            SV *cb = l->wcb[fd];
            if (cb) { l->wcb[fd] = NULL; SvREFCNT_dec(cb); }
        }
    }
    t = l->timers;
    l->timers = NULL;
    while (t) { ft_timer *n = t->next; if (t->cb) SvREFCNT_dec(t->cb); free(t); t = n; }
    if (l->be) l->be->destroy(l->be);
    free(l->rcb);
    free(l->wcb);
    free(l);
}

/* call $cb->() discarding the result, trapping death into a warning */
static void ft_call0(pTHX_ SV *cb) {
    /* Fast path: the loop's own watchers are C closures (hm_closure XSUBs
     * carrying hm_clos magic) - call the XSUB body directly, skipping
     * pp_entersub, the eval frame and the Perl stack dance. These callbacks
     * do not die; any user Perl code they reach (future on_ready callbacks)
     * is eval-guarded where it runs, in hmf_pump. */
    if (SvROK(cb)) {
        CV *cv = (CV *)SvRV(cb);
        if (SvTYPE((SV *)cv) == SVt_PVCV && CvISXSUB(cv)
            && hm_clos_of(aTHX_ cv)) {
            dSP;
            PUSHMARK(SP);
            PUTBACK;
            (CvXSUB(cv))(aTHX_ cv);
            return;
        }
    }
    {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
        call_sv(cb, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) warn("Fetch: loop callback died: %s", SvPV_nolen(ERRSV));
        FREETMPS; LEAVE;
    }
}

static void ft_watch_io(pTHX_ ft_loop *l, int fd, int mask, SV *cb) {
    hm_backend *be = ft_loop_be(aTHX_ l, 1);
    if (fd < 0 || fd >= HM_MAXFD) croak("watch_io: fd %d out of range", fd);
    if (mask & HM_EV_READ)  { if (l->rcb[fd]) SvREFCNT_dec(l->rcb[fd]); else l->nio++; l->rcb[fd] = SvREFCNT_inc(cb); }
    if (mask & HM_EV_WRITE) { if (l->wcb[fd]) SvREFCNT_dec(l->wcb[fd]); else l->nio++; l->wcb[fd] = SvREFCNT_inc(cb); }
    be->add_io(be, fd, mask, 0);
}

static void ft_unwatch_io(pTHX_ ft_loop *l, int fd, int mask) {
    hm_backend *be = ft_loop_be(aTHX_ l, 0);
    if (fd < 0 || fd >= HM_MAXFD) return;
    if (mask & HM_EV_READ)  { if (l->rcb[fd]) { SvREFCNT_dec(l->rcb[fd]); l->rcb[fd] = NULL; l->nio--; } }
    if (mask & HM_EV_WRITE) { if (l->wcb[fd]) { SvREFCNT_dec(l->wcb[fd]); l->wcb[fd] = NULL; l->nio--; } }
    if (be) be->remove_io(be, fd, mask);
}

static ft_timer *ft_add_timer(pTHX_ ft_loop *l, double secs, SV *cb, int oneshot) {
    hm_backend *be = ft_loop_be(aTHX_ l, 1);
    ft_timer *t = (ft_timer *)calloc(1, sizeof(ft_timer));
    if (!t) croak("Fetch: out of memory");
    t->cb      = SvREFCNT_inc(cb);
    t->oneshot = oneshot ? 1 : 0;
    t->secs    = secs;
    t->due     = ft_loop_now() + secs;
    t->id      = ++l->last_timer_id;
    t->next    = l->timers;
    l->timers  = t;
    be->add_timer(be, secs, oneshot, ft_timer_token(t->id));
    return t;
}

static void ft_timer_unlink(pTHX_ ft_loop *l, ft_timer *dead) {
    ft_timer **pp = &l->timers;
    while (*pp) {
        if (*pp == dead) {
            *pp = dead->next;
            if (dead->cb) SvREFCNT_dec(dead->cb);
            free(dead);
            return;
        }
        pp = &(*pp)->next;
    }
}

/* Cancel a still-pending timer: drop it from the backend so it never fires,
 * then unlink+free. (The fire path in hm_loop_run unlinks without del_timer,
 * since a oneshot the backend has already dropped.) */
static void ft_del_timer(pTHX_ ft_loop *l, ft_timer *t) {
    hm_backend *be = ft_loop_be(aTHX_ l, 0);
    ft_timer   *p;
    if (!t) return;
    /* Only a timer still linked is ours to read: a connection copied into a
     * forked child still points at a timer the disown above has freed. */
    for (p = l->timers; p && p != t; p = p->next) ;
    if (!p) return;
    if (be) be->del_timer(be, ft_timer_token(t->id));
    ft_timer_unlink(aTHX_ l, t);
}

/* Pump until `until` (a Fetch::Future SV) resolves, ->stop is set, or forever
 * when until == NULL. Re-entrant: saves/restores hm_cur_loop and ->stop. */
static void hm_loop_run(pTHX_ struct hm_loop *l, SV *until) {
    ft_loop *saved      = hm_cur_loop;
    int      saved_stop = l->stop;
    hm_cur_loop = l;
    l->stop = 0;

    while (!l->stop) {
        hm_event    evs[HM_MAXEV];
        hm_backend *be;
        int n, i;

        /* Per turn, not per call: a callback may fork, and the child that
         * carries on from inside it must not pump the parent's backend. */
        be = ft_loop_be(aTHX_ l, 1);

        hmf_pump(aTHX);                       /* drain future continuations */
        if (until && hmf_state(aTHX_ until) != HMF_PENDING) break;

        /* Nothing armed and nothing timed means nothing can ever wake us:
         * wait_ev below blocks in the kernel with no deadline, which is not
         * a stall a Perl-level alarm can even interrupt. Awaiting a future
         * this loop was never going to resolve is the way to get here, so
         * say that rather than hanging the process. */
        if (until && !l->nio && !l->timers) {
            l->stop     = saved_stop;
            hm_cur_loop = saved;
            croak("Fetch::Future: awaited on a loop with no watchers - the "
                  "future belongs to a different loop");
        }

        n = be->wait_ev(be, evs, HM_MAXEV, -1.0);
        if (n < 0) { if (errno == EINTR) continue; break; }

        for (i = 0; i < n && !l->stop; i++) {
            hm_event *e = &evs[i];
            if (e->kind & HM_EV_TIMER) {
                ft_timer *t = ft_timer_of_token(l, e->udata);
                if (t && t->cb) {
                    SV *cb  = SvREFCNT_inc(t->cb);
                    int one = t->oneshot;
                    if (one) ft_timer_unlink(aTHX_ l, t);  /* backend already dropped it */
                    ft_call0(aTHX_ cb);
                    SvREFCNT_dec(cb);
                }
            } else {
                if ((e->kind & HM_EV_READ) && e->fd >= 0 && e->fd < HM_MAXFD && l->rcb[e->fd]) {
                    SV *cb = SvREFCNT_inc(l->rcb[e->fd]);
                    ft_call0(aTHX_ cb);
                    SvREFCNT_dec(cb);
                }
                if ((e->kind & HM_EV_WRITE) && e->fd >= 0 && e->fd < HM_MAXFD && l->wcb[e->fd]) {
                    SV *cb = SvREFCNT_inc(l->wcb[e->fd]);
                    ft_call0(aTHX_ cb);
                    SvREFCNT_dec(cb);
                }
            }
            hmf_pump(aTHX);
            if (until && hmf_state(aTHX_ until) != HMF_PENDING) { l->stop = 1; break; }
        }
    }

    l->stop     = saved_stop;
    hm_cur_loop = saved;
}

#endif /* FT_LOOP_H */
