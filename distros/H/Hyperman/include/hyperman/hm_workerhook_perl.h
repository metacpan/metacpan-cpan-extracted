/* hm_workerhook_perl.h - the Perl door onto the v4 on_worker_start registry.
 *
 * hm_workerhook.h holds C function pointers, which is what an XS consumer
 * wants. This registers a SHIM into that same table whose user data is a Perl
 * coderef, so an ordinary application can run code in each worker after the
 * fork:
 *
 *     Hyperman->on_worker_start(sub { $dbh = DBI->connect(...) });
 *     Hyperman->run(app => $app, workers => 4);
 *
 * A prefork server needs that and PSGI has no standard for it. Anything
 * holding a file descriptor - a database handle, a cache connection, a
 * seeded RNG - is wrong in a child that inherited it from the parent, and
 * until now the only ways to deal with that under Hyperman were to be an XS
 * module or to detect the fork yourself on the first request.
 *
 * Register BEFORE run(). The registry is walked in the child once its loop
 * exists and before the loop starts turning, so a callback registered after
 * run() has already forked will never fire in the workers already running.
 *
 * The coderef survives the fork for free: it lives in the parent interpreter,
 * which is what a child gets a copy of. That is why this can hold an SV where
 * hm_workerhook.h deliberately does not - it stores a pointer into memory the
 * fork duplicates wholesale, not a resource the child would have to reopen.
 *
 * A callback runs at worker boot, before anything is being served, so there
 * is no request for a death to damage - but a die propagating out of here
 * would come up through hm_worker and take the whole worker with it, before
 * it has served anything. So the shim runs under G_EVAL and turns a death
 * into a warning: a worker that could not run your setup code is still a
 * worker, and one that never starts is an outage.
 *
 * Needs hm_workerhook.h. Included after it.
 */

#ifndef HM_WORKERHOOK_PERL_H
#define HM_WORKERHOOK_PERL_H

#include "hm_workerhook.h"

typedef struct { SV *cb; } hm_worker_perl;

/* The shim. Called with no arguments: the callback that wants this worker's
 * loop asks Hyperman->loop for it, and the one that wants the pid has $$.
 * Passing the raw loop pointer would mean blessing something whose only
 * documented use is a C entry point. */
static void hm_worker_perl_cb(pTHX_ void *loop, void *ud) {
    hm_worker_perl *p = (hm_worker_perl *)ud;
    dSP;
    PERL_UNUSED_ARG(loop);
    if (!p || !p->cb) return;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    call_sv(p->cb, G_DISCARD | G_EVAL);
    SPAGAIN; PUTBACK; FREETMPS; LEAVE;
    if (SvTRUE(ERRSV))
        warn("Hyperman: on_worker_start callback died: %s "
             "(this worker is still serving)", SvPV_nolen(ERRSV));
}

/* Hyperman->on_worker_start(\&cb). Returns 1, or 0 when the table is full
 * (HM_ABI_MAX_WORKER_CB). A non-coderef croaks here, in the caller's own
 * frame, which is long before any worker exists to be confused by it. */
static int hm_worker_hook_add_perl(pTHX_ SV *cb) {
    hm_worker_perl *p;
    if (!(cb && SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
        croak("Hyperman->on_worker_start: expects a code reference");
    Newxz(p, 1, hm_worker_perl);
    p->cb = newSVsv(cb);
    if (!hm_worker_hook_add(aTHX_ hm_worker_perl_cb, p)) {
        SvREFCNT_dec(p->cb);
        Safefree(p);
        return 0;
    }
    return 1;
}

#endif /* HM_WORKERHOOK_PERL_H */
