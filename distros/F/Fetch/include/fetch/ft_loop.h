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
    struct ft_timer  *next;
} ft_timer;

struct hm_loop {                 /* name matches ft_future.h's forward decl */
    hm_backend *be;
    SV        **rcb;             /* [HM_MAXFD] read-ready callbacks  */
    SV        **wcb;             /* [HM_MAXFD] write-ready callbacks */
    ft_timer   *timers;          /* live timers, for dispatch + cleanup */
    int         stop;
};
typedef struct hm_loop ft_loop;
/* hm_cur_loop is defined (static) in ft_future.h; we only read/write it. */

static ft_loop *ft_loop_new(pTHX_ const char *name) {
    ft_loop *l = (ft_loop *)calloc(1, sizeof(ft_loop));
    if (!l) croak("Fetch::Loop: out of memory");
    l->be = hm_backend_create(name && *name ? name : NULL);
    if (!l->be) { free(l); croak("Fetch::Loop: no event backend available"); }
    l->rcb = (SV **)calloc(HM_MAXFD, sizeof(SV *));
    l->wcb = (SV **)calloc(HM_MAXFD, sizeof(SV *));
    if (!l->rcb || !l->wcb) croak("Fetch::Loop: out of memory");
    return l;
}

static void ft_loop_free(pTHX_ ft_loop *l) {
    int fd;
    ft_timer *t;
    if (!l) return;
    if (l->rcb) { for (fd = 0; fd < HM_MAXFD; fd++) if (l->rcb[fd]) SvREFCNT_dec(l->rcb[fd]); free(l->rcb); }
    if (l->wcb) { for (fd = 0; fd < HM_MAXFD; fd++) if (l->wcb[fd]) SvREFCNT_dec(l->wcb[fd]); free(l->wcb); }
    for (t = l->timers; t; ) { ft_timer *n = t->next; if (t->cb) SvREFCNT_dec(t->cb); free(t); t = n; }
    if (l->be) l->be->destroy(l->be);
    free(l);
}

/* call $cb->() discarding the result, trapping death into a warning */
static void ft_call0(pTHX_ SV *cb) {
    dSP;
    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) warn("Fetch: loop callback died: %s", SvPV_nolen(ERRSV));
    FREETMPS; LEAVE;
}

static void ft_watch_io(pTHX_ ft_loop *l, int fd, int mask, SV *cb) {
    if (fd < 0 || fd >= HM_MAXFD) croak("watch_io: fd %d out of range", fd);
    if (mask & HM_EV_READ)  { if (l->rcb[fd]) SvREFCNT_dec(l->rcb[fd]); l->rcb[fd] = SvREFCNT_inc(cb); }
    if (mask & HM_EV_WRITE) { if (l->wcb[fd]) SvREFCNT_dec(l->wcb[fd]); l->wcb[fd] = SvREFCNT_inc(cb); }
    l->be->add_io(l->be, fd, mask, 0);
}

static void ft_unwatch_io(pTHX_ ft_loop *l, int fd, int mask) {
    if (fd < 0 || fd >= HM_MAXFD) return;
    if (mask & HM_EV_READ)  { if (l->rcb[fd]) { SvREFCNT_dec(l->rcb[fd]); l->rcb[fd] = NULL; } }
    if (mask & HM_EV_WRITE) { if (l->wcb[fd]) { SvREFCNT_dec(l->wcb[fd]); l->wcb[fd] = NULL; } }
    l->be->remove_io(l->be, fd, mask);
}

static ft_timer *ft_add_timer(pTHX_ ft_loop *l, double secs, SV *cb, int oneshot) {
    ft_timer *t = (ft_timer *)calloc(1, sizeof(ft_timer));
    if (!t) croak("Fetch: out of memory");
    t->cb      = SvREFCNT_inc(cb);
    t->oneshot = oneshot ? 1 : 0;
    t->next    = l->timers;
    l->timers  = t;
    l->be->add_timer(l->be, secs, oneshot, t);
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
    if (!t) return;
    l->be->del_timer(l->be, t);
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
        hm_event evs[HM_MAXEV];
        int n, i;

        hmf_pump(aTHX);                       /* drain future continuations */
        if (until && hmf_state(aTHX_ until) != HMF_PENDING) break;

        n = l->be->wait(l->be, evs, HM_MAXEV, -1.0);
        if (n < 0) { if (errno == EINTR) continue; break; }

        for (i = 0; i < n && !l->stop; i++) {
            hm_event *e = &evs[i];
            if (e->kind & HM_EV_TIMER) {
                ft_timer *t = (ft_timer *)e->udata;
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
