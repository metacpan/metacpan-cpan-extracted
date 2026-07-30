#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "EVAPI.h"

#define IS_PVCV(sv) (sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)

#define EVF_KIND_PARALLEL 0
#define EVF_KIND_PLIMIT   1
#define EVF_KIND_SERIES   2
#define EVF_KIND_RACE     3

/* Refcounted cell between a context and its Perl-side handle object. The
   context is freed the moment the operation completes, but the caller may hold
   the handle long after that, so neither side may own the other. Completion
   NULLs `ctx`, which makes every later method call a safe no-op. */
typedef struct {
    void *ctx;    /* NULL once the operation is over */
    int   kind;   /* which primitive, so we can pick the right cleanup */
    int   refcnt; /* held by the Perl object and, while live, by the context */
} evf_handle;

static evf_handle *evf_handle_new(pTHX_ void *ctx, int kind) {
    evf_handle *h;
    Newx(h, 1, evf_handle);
    h->ctx = ctx;
    h->kind = kind;
    h->refcnt = 1; /* the Perl object we are about to hand back */
    return h;
}

static void evf_handle_dec(pTHX_ evf_handle *h) {
    if (!h) return;
    if (--h->refcnt <= 0) Safefree(h);
}

static void evf_handle_attach(pTHX_ evf_handle *h, void *ctx) {
    if (!h) return;
    h->ctx = ctx;
    h->refcnt++; /* the context's reference */
}

static SV *evf_handle_wrap(pTHX_ evf_handle *h) {
    SV *sv = newSViv(PTR2IV(h));
    SV *rv = newRV_noinc(sv);
    sv_bless(rv, gv_stashpv("EV::Future::Handle", GV_ADD));
    SvREADONLY_on(sv);
    return rv; /* does not increment: evf_handle_new already counted this */
}

/* The one place a method turns its invocant back into a cell. Anything that is
   not a reference to an integer is not one of ours - a subclass built on a
   hashref, or the class name from a class-method call - so refuse it rather
   than treat a foreign body as a pointer. A zeroed payload (already destroyed)
   comes back as NULL too, which every caller must tolerate. */
static evf_handle *evf_handle_from_sv(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self))) return NULL;
    return INT2PTR(evf_handle *, SvIV(SvRV(self)));
}

typedef struct {
    AV *tasks;
    SV *final_cb;
    SV *worker;    /* NULL for the task form; the worker CV for the map form */
    I32 remaining;
    CV **cvs;
    I32 num_cvs;
    CV *shared_cv; /* for unsafe mode */
    int abandoned;
    int *is_freed_ptr;
    evf_handle *h;   /* NULL unless the caller asked for a handle */
} parallel_ctx;

/* Guard registered with SAVEDESTRUCTOR_X by every frame that dispatches tasks,
   so the frame unwinds cleanly even when an unsafe-mode task croaks straight
   through it. is_freed is the flag the frame pointed ctx->is_freed_ptr at; it
   lives in the guard, so it stays valid for exactly as long as the field
   pointing at it. If it is set, cleanup already ran and the context is gone:
   nothing may be dereferenced, we only propagate the flag to the enclosing
   frame. Otherwise the context outlived the frame, so put back what the frame
   borrowed - and if the frame never reached its normal exit (completed == 0)
   the unwind was an exception, so abandon the operation rather than let a
   later completion run against half-updated state. */
typedef struct {
    int **target_field; /* &ctx->is_freed_ptr */
    int *restore_val;   /* what to put back there; NULL at XSUB level */
    int *running_field; /* &ctx->running, or NULL if the primitive has none */
    int *abandon_field; /* &ctx->abandoned */
    int is_freed;
    int completed;
    evf_handle *pending_h; /* handle reference not yet handed to Perl */
} ifp_guard;

static void ifp_guard_destroy(pTHX_ void *p) {
    ifp_guard *g = (ifp_guard *)p;
    if (g->is_freed) {
        if (g->restore_val) *(g->restore_val) = 1;
    } else {
        *(g->target_field) = g->restore_val;
        if (g->running_field) *(g->running_field) = 0;
        if (!g->completed) *(g->abandon_field) = 1;
    }
    /* The handle cell is created before dispatch but only becomes a Perl
       object once the frame returns normally. An unwind (a task that croaked)
       never gets there, so release that reference here instead of orphaning
       the cell. The context, if it still lives, holds its own. */
    if (!g->completed) evf_handle_dec(aTHX_ g->pending_h);
    Safefree(g);
}

/* Call inside an ENTER/LEAVE pair. Takes over ctx->is_freed_ptr for the life of
   the frame and hands the guard back so the caller can read the flag and mark
   its normal exit. */
static ifp_guard *ifp_guard_push(pTHX_ int **target_field, int *restore_val,
                                 int *running_field, int *abandon_field) {
    ifp_guard *g;
    Newx(g, 1, ifp_guard);
    g->target_field = target_field;
    g->restore_val = restore_val;
    g->running_field = running_field;
    g->abandon_field = abandon_field;
    g->is_freed = 0;
    g->completed = 0;
    g->pending_h = NULL;
    *target_field = &g->is_freed;
    SAVEDESTRUCTOR_X(ifp_guard_destroy, g);
    return g;
}

typedef struct {
    AV *tasks;
    SV *final_cb;
    SV *worker;    /* NULL for the task form; the worker CV for the map form */
    I32 current_idx;
    int running;
    int delayed;
    I32 total_tasks;
    int unsafe;
    int abandoned;
    CV *current_cv;
    int *is_freed_ptr;
    evf_handle *h;   /* NULL unless the caller asked for a handle */
} series_ctx;

typedef struct {
    AV *tasks;
    SV *final_cb;
    SV *worker;    /* NULL for the task form; the worker CV for the map form */
    I32 remaining;
    I32 current_idx;
    I32 total_tasks;
    I32 limit;
    I32 active;
    int unsafe;
    int running;
    int delayed;
    int abandoned;
    CV **cvs;
    I32 num_cvs;
    CV *shared_cv;
    int *is_freed_ptr;
    evf_handle *h;   /* NULL unless the caller asked for a handle */
} plimit_ctx;

typedef struct {
    AV *tasks;
    SV *final_cb;
    int settled;
    I32 total_tasks;
    int abandoned;
    CV **cvs;
    I32 num_cvs;
    CV *shared_cv;
    int *is_freed_ptr;
    evf_handle *h;   /* NULL unless the caller asked for a handle */
} race_ctx;

static evf_handle *parallel_start(pTHX_ AV *list, SV *worker, SV *final_cb, int unsafe, int want_handle);
static evf_handle *series_start(pTHX_ AV *list, SV *worker, SV *final_cb, int unsafe, int want_handle);
static evf_handle *plimit_start(pTHX_ AV *list, SV *worker, IV limit, SV *final_cb, int unsafe, int want_handle);

static void parallel_cleanup(pTHX_ parallel_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    parallel_ctx *ctx = *ctx_ptr;
    *ctx_ptr = NULL;

    if (ctx->is_freed_ptr) {
        *(ctx->is_freed_ptr) = 1;
    }

    /* Detach first: freeing tasks/worker/final_cb below can run user DESTROY,
       and a cancel from there must not re-enter this cleanup. */
    if (ctx->h) {
        ctx->h->ctx = NULL;
        evf_handle_dec(aTHX_ ctx->h);
        ctx->h = NULL;
    }

    if (ctx->shared_cv) {
        CvXSUBANY(ctx->shared_cv).any_ptr = NULL;
        SvREFCNT_dec((SV*)ctx->shared_cv);
    }
    if (ctx->cvs) {
        I32 i;
        for (i = 0; i < ctx->num_cvs; i++) {
            if (ctx->cvs[i]) {
                CvXSUBANY(ctx->cvs[i]).any_ptr = NULL;
                SvREFCNT_dec((SV*)ctx->cvs[i]);
            }
        }
        Safefree(ctx->cvs);
        /* Belt and braces: nothing may reach this context again now that the
           handle is detached, but a dangling cvs with a non-zero count is what
           turned an earlier re-entrancy into a segfault rather than a no-op. */
        ctx->cvs = NULL;
        ctx->num_cvs = 0;
    }
    if (ctx->tasks) SvREFCNT_dec((SV*)ctx->tasks);
    if (ctx->final_cb) SvREFCNT_dec(ctx->final_cb);
    if (ctx->worker) SvREFCNT_dec(ctx->worker);
    Safefree(ctx);
}

static void parallel_task_done(pTHX_ CV *cv) {
    dXSARGS;
    SvREFCNT_inc_simple_void(cv);
    sv_2mortal((SV*)cv);
    parallel_ctx *ctx = (parallel_ctx *)CvXSUBANY(cv).any_ptr;
    if (!ctx || ctx->abandoned) {
        XSRETURN_EMPTY;
    }

    if (ctx->cvs) {
        CvXSUBANY(cv).any_ptr = NULL;
    }

    if (--ctx->remaining <= 0) {
        SV *cb = ctx->final_cb;
        if (IS_PVCV(cb)) {
            dSP;
            ENTER;
            SAVETMPS;
            SvREFCNT_inc(cb);
            sv_2mortal(cb);
            PUSHMARK(SP);
            PUTBACK;

            parallel_cleanup(aTHX_ &ctx);

            call_sv(cb, G_DISCARD | G_VOID);

            FREETMPS;
            LEAVE;
        } else {
            parallel_cleanup(aTHX_ &ctx);
        }
    }
    XSRETURN_EMPTY;
}

static void series_cleanup(pTHX_ series_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    series_ctx *ctx = *ctx_ptr;
    *ctx_ptr = NULL;

    if (ctx->is_freed_ptr) {
        *(ctx->is_freed_ptr) = 1;
    }

    /* Detach first: freeing tasks/worker/final_cb below can run user DESTROY,
       and a cancel from there must not re-enter this cleanup. */
    if (ctx->h) {
        ctx->h->ctx = NULL;
        evf_handle_dec(aTHX_ ctx->h);
        ctx->h = NULL;
    }

    if (ctx->current_cv) {
        CvXSUBANY(ctx->current_cv).any_ptr = NULL;
        SvREFCNT_dec((SV*)ctx->current_cv);
    }
    if (ctx->tasks) SvREFCNT_dec((SV*)ctx->tasks);
    if (ctx->final_cb) SvREFCNT_dec(ctx->final_cb);
    if (ctx->worker) SvREFCNT_dec(ctx->worker);
    Safefree(ctx);
}

static void _series_next(pTHX_ series_ctx **ctx_ptr);

static void series_next_cb(pTHX_ CV *cv) {
    dXSARGS;
    SvREFCNT_inc_simple_void(cv);
    sv_2mortal((SV*)cv);
    series_ctx *ctx = (series_ctx *)CvXSUBANY(cv).any_ptr;
    if (!ctx || ctx->abandoned) {
        XSRETURN_EMPTY;
    }

    if (!ctx->unsafe) {
        CvXSUBANY(cv).any_ptr = NULL;
        if (ctx->current_cv == cv) {
            ctx->current_cv = NULL;
            SvREFCNT_dec((SV*)cv);
        }
    }

    if (items > 0 && SvTRUE(ST(0))) {
        ctx->current_idx = ctx->total_tasks;
    }
    _series_next(aTHX_ &ctx);
    XSRETURN_EMPTY;
}

static void _series_next(pTHX_ series_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    series_ctx *ctx = *ctx_ptr;

    if (ctx->running) {
        ctx->delayed = 1;
        return;
    }

    ENTER;

    int *old_is_freed_ptr = ctx->is_freed_ptr;
    ifp_guard *guard = ifp_guard_push(aTHX_ &ctx->is_freed_ptr, old_is_freed_ptr,
                                      &ctx->running, &ctx->abandoned);
    int *is_freed = &guard->is_freed;

    SV *worker = ctx->worker;
    const int have_worker = (worker != NULL);

    ctx->running = 1;
    ctx->delayed = 1;

    while (ctx->delayed) {
        ctx->delayed = 0;
        SV **task_ary = (AvREAL(ctx->tasks) && !SvMAGICAL(ctx->tasks)) ? AvARRAY(ctx->tasks) : NULL;
        if (ctx->current_idx >= ctx->total_tasks) {
            SV *cb = ctx->final_cb;
            if (IS_PVCV(cb)) {
                dSP;
                ENTER;
                SAVETMPS;
                SvREFCNT_inc(cb);
                sv_2mortal(cb);
                PUSHMARK(SP);
                PUTBACK;
                series_cleanup(aTHX_ ctx_ptr);
                call_sv(cb, G_DISCARD | G_VOID);
                FREETMPS;
                LEAVE;
            } else {
                series_cleanup(aTHX_ ctx_ptr);
            }
            goto done;
        }

        SV **fetch_ptr = (task_ary && ctx->current_idx <= AvFILL(ctx->tasks))
            ? &task_ary[ctx->current_idx]
            : av_fetch(ctx->tasks, ctx->current_idx, 0);
        SV *task_sv = fetch_ptr ? *fetch_ptr : NULL;

        ctx->current_idx++;

        if (have_worker || IS_PVCV(task_sv)) {
            if (!ctx->unsafe) {
                if (ctx->current_cv) {
                    CvXSUBANY(ctx->current_cv).any_ptr = NULL;
                    SvREFCNT_dec((SV*)ctx->current_cv);
                }
                CV *cv = newXS(NULL, series_next_cb, __FILE__);
                CvXSUBANY(cv).any_ptr = ctx;
                ctx->current_cv = (CV*)SvREFCNT_inc((SV*)cv);
            } else if (!ctx->current_cv) {
                ctx->current_cv = newXS(NULL, series_next_cb, __FILE__);
                CvXSUBANY(ctx->current_cv).any_ptr = ctx;
            }

            SV *next_rv = NULL;
            dSP;
            ENTER;
            SAVETMPS;
            if (!ctx->unsafe) {
                next_rv = sv_2mortal(newRV_noinc((SV*)ctx->current_cv));
            } else {
                next_rv = sv_2mortal(newRV_inc((SV*)ctx->current_cv));
            }
            PUSHMARK(SP);
            if (have_worker) {
                XPUSHs(task_sv ? sv_2mortal(SvREFCNT_inc(task_sv)) : &PL_sv_undef);
            }
            XPUSHs(next_rv);
            PUTBACK;

            int task_unsafe = ctx->unsafe;
            /* G_VOID: see parallel_start. */
            U32 flags = G_DISCARD | G_VOID | (task_unsafe ? 0 : G_EVAL);
            call_sv(have_worker ? worker : task_sv, flags);

            if (!task_unsafe) {
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    SV *err = sv_mortalcopy(ERRSV);
                    if (!*is_freed) {
                        series_cleanup(aTHX_ ctx_ptr);
                    }
                    croak_sv(err);
                }
            }

            FREETMPS;
            LEAVE;
            if (*is_freed) goto done;
        } else {
            ctx->delayed = 1;
        }
    }

    /* The guard restores is_freed_ptr and clears running; on an unwind that
       skipped this point it abandons the series instead. */
done:
    guard->completed = 1;
    LEAVE;
}

static void plimit_cleanup(pTHX_ plimit_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    plimit_ctx *ctx = *ctx_ptr;
    *ctx_ptr = NULL;

    if (ctx->is_freed_ptr) {
        *(ctx->is_freed_ptr) = 1;
    }

    /* Detach first: freeing tasks/worker/final_cb below can run user DESTROY,
       and a cancel from there must not re-enter this cleanup. */
    if (ctx->h) {
        ctx->h->ctx = NULL;
        evf_handle_dec(aTHX_ ctx->h);
        ctx->h = NULL;
    }

    if (ctx->shared_cv) {
        CvXSUBANY(ctx->shared_cv).any_ptr = NULL;
        SvREFCNT_dec((SV*)ctx->shared_cv);
    }
    if (ctx->cvs) {
        I32 i;
        for (i = 0; i < ctx->num_cvs; i++) {
            if (ctx->cvs[i]) {
                CvXSUBANY(ctx->cvs[i]).any_ptr = NULL;
                SvREFCNT_dec((SV*)ctx->cvs[i]);
            }
        }
        Safefree(ctx->cvs);
        /* See parallel_cleanup. */
        ctx->cvs = NULL;
        ctx->num_cvs = 0;
    }
    if (ctx->tasks) SvREFCNT_dec((SV*)ctx->tasks);
    if (ctx->final_cb) SvREFCNT_dec(ctx->final_cb);
    if (ctx->worker) SvREFCNT_dec(ctx->worker);
    Safefree(ctx);
}

static void _plimit_dispatch(pTHX_ plimit_ctx **ctx_ptr);

static void plimit_task_done(pTHX_ CV *cv) {
    dXSARGS;
    SvREFCNT_inc_simple_void(cv);
    sv_2mortal((SV*)cv);
    plimit_ctx *ctx = (plimit_ctx *)CvXSUBANY(cv).any_ptr;
    if (!ctx || ctx->abandoned) {
        XSRETURN_EMPTY;
    }

    if (ctx->cvs) {
        CvXSUBANY(cv).any_ptr = NULL;
    }

    ctx->active--;

    if (--ctx->remaining <= 0) {
        SV *cb = ctx->final_cb;
        if (IS_PVCV(cb)) {
            dSP;
            ENTER;
            SAVETMPS;
            SvREFCNT_inc(cb);
            sv_2mortal(cb);
            PUSHMARK(SP);
            PUTBACK;

            plimit_cleanup(aTHX_ &ctx);

            call_sv(cb, G_DISCARD | G_VOID);

            FREETMPS;
            LEAVE;
        } else {
            plimit_cleanup(aTHX_ &ctx);
        }
    } else {
        _plimit_dispatch(aTHX_ &ctx);
    }
    XSRETURN_EMPTY;
}

static void _plimit_dispatch(pTHX_ plimit_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    plimit_ctx *ctx = *ctx_ptr;

    if (ctx->running) {
        ctx->delayed = 1;
        return;
    }

    ENTER;

    int *old_is_freed_ptr = ctx->is_freed_ptr;
    ifp_guard *guard = ifp_guard_push(aTHX_ &ctx->is_freed_ptr, old_is_freed_ptr,
                                      &ctx->running, &ctx->abandoned);
    int *is_freed = &guard->is_freed;

    SV *worker = ctx->worker;
    const int have_worker = (worker != NULL);

    ctx->running = 1;
    ctx->delayed = 1;

    while (ctx->delayed) {
        ctx->delayed = 0;

        while (!*is_freed && ctx->active < ctx->limit && ctx->current_idx < ctx->total_tasks) {
            SV **task_ary = (AvREAL(ctx->tasks) && !SvMAGICAL(ctx->tasks)) ? AvARRAY(ctx->tasks) : NULL;
            SV **fetch_ptr = (task_ary && ctx->current_idx <= AvFILL(ctx->tasks))
                ? &task_ary[ctx->current_idx]
                : av_fetch(ctx->tasks, ctx->current_idx, 0);
            SV *task_sv = fetch_ptr ? *fetch_ptr : NULL;

            ctx->current_idx++;

            if (have_worker || IS_PVCV(task_sv)) {
                SV *done_rv = NULL;
                CV *cv = NULL;
                dSP;

                if (!ctx->unsafe) {
                    cv = newXS(NULL, plimit_task_done, __FILE__);
                    CvXSUBANY(cv).any_ptr = ctx;
                    ctx->cvs[ctx->current_idx - 1] = (CV*)SvREFCNT_inc((SV*)cv);
                }

                ctx->active++;
                int task_unsafe = ctx->unsafe;

                ENTER;
                SAVETMPS;
                if (!ctx->unsafe) {
                    done_rv = sv_2mortal(newRV_noinc((SV*)cv));
                } else {
                    done_rv = sv_2mortal(newRV_inc((SV*)ctx->shared_cv));
                }
                PUSHMARK(SP);
                if (have_worker) {
                    XPUSHs(task_sv ? sv_2mortal(SvREFCNT_inc(task_sv)) : &PL_sv_undef);
                }
                XPUSHs(done_rv);
                PUTBACK;

                /* G_VOID: see parallel_start. */
                U32 flags = G_DISCARD | G_VOID | (task_unsafe ? 0 : G_EVAL);
                call_sv(have_worker ? worker : task_sv, flags);

                if (!task_unsafe) {
                    SPAGAIN;
                    if (SvTRUE(ERRSV)) {
                        SV *err = sv_mortalcopy(ERRSV);
                        if (!*is_freed) {
                            plimit_cleanup(aTHX_ ctx_ptr);
                        }
                        croak_sv(err);
                    }
                }

                FREETMPS;
                LEAVE;
                if (*is_freed) goto done;
            } else {
                if (--ctx->remaining <= 0) {
                    SV *cb = ctx->final_cb;
                    if (IS_PVCV(cb)) {
                        dSP;
                        ENTER;
                        SAVETMPS;
                        SvREFCNT_inc(cb);
                        sv_2mortal(cb);
                        PUSHMARK(SP);
                        PUTBACK;
                        plimit_cleanup(aTHX_ ctx_ptr);
                        call_sv(cb, G_DISCARD | G_VOID);
                        FREETMPS;
                        LEAVE;
                    } else {
                        plimit_cleanup(aTHX_ ctx_ptr);
                    }
                    goto done;
                }
                ctx->delayed = 1;
            }
        }
    }

    /* The guard restores is_freed_ptr and clears running, or propagates the
       flag outwards when cleanup already freed the context. On an unwind that
       skipped this point it abandons the remaining tasks instead. */
done:
    guard->completed = 1;
    LEAVE;
}

static void race_cleanup(pTHX_ race_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    race_ctx *ctx = *ctx_ptr;
    *ctx_ptr = NULL;

    if (ctx->is_freed_ptr) {
        *(ctx->is_freed_ptr) = 1;
    }

    /* Detach first: freeing tasks/final_cb below can run user DESTROY, and a
       cancel from there must not re-enter this cleanup. */
    if (ctx->h) {
        ctx->h->ctx = NULL;
        evf_handle_dec(aTHX_ ctx->h);
        ctx->h = NULL;
    }

    if (ctx->shared_cv) {
        CvXSUBANY(ctx->shared_cv).any_ptr = NULL;
        SvREFCNT_dec((SV*)ctx->shared_cv);
    }
    if (ctx->cvs) {
        I32 i;
        for (i = 0; i < ctx->num_cvs; i++) {
            if (ctx->cvs[i]) {
                CvXSUBANY(ctx->cvs[i]).any_ptr = NULL;
                SvREFCNT_dec((SV*)ctx->cvs[i]);
            }
        }
        Safefree(ctx->cvs);
        /* See parallel_cleanup. */
        ctx->cvs = NULL;
        ctx->num_cvs = 0;
    }
    if (ctx->tasks) SvREFCNT_dec((SV*)ctx->tasks);
    if (ctx->final_cb) SvREFCNT_dec(ctx->final_cb);
    Safefree(ctx);
}

static void race_task_done(pTHX_ CV *cv) {
    dXSARGS;
    SvREFCNT_inc_simple_void(cv);
    sv_2mortal((SV*)cv);
    race_ctx *ctx = (race_ctx *)CvXSUBANY(cv).any_ptr;
    if (!ctx || ctx->settled || ctx->abandoned) {
        XSRETURN_EMPTY;
    }
    ctx->settled = 1;

    if (ctx->cvs) {
        CvXSUBANY(cv).any_ptr = NULL;
    }

    SV *cb = ctx->final_cb;
    if (IS_PVCV(cb)) {
        dSP;
        ENTER;
        SAVETMPS;
        SvREFCNT_inc(cb);
        sv_2mortal(cb);

        PUSHMARK(SP);
        for (I32 i = 0; i < items; i++) {
            XPUSHs(sv_mortalcopy(ST(i)));
        }
        PUTBACK;

        race_cleanup(aTHX_ &ctx);

        call_sv(cb, G_DISCARD | G_VOID);

        FREETMPS;
        LEAVE;
    } else {
        race_cleanup(aTHX_ &ctx);
    }
    XSRETURN_EMPTY;
}

static evf_handle *parallel_start(pTHX_ AV *list, SV *worker, SV *final_cb, int unsafe, int want_handle) {
    I32 len = av_len(list) + 1;
    if (len <= 0) {
        if (IS_PVCV(final_cb)) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            call_sv(final_cb, G_DISCARD | G_VOID);
            FREETMPS;
            LEAVE;
        }
        /* Already over: hand back a dead handle so callers get a uniform
           object rather than undef. */
        return want_handle ? evf_handle_new(aTHX_ NULL, EVF_KIND_PARALLEL) : NULL;
    }

    ENTER;

    parallel_ctx *ctx;
    Newx(ctx, 1, parallel_ctx);
    ctx->is_freed_ptr = NULL;
    ctx->h = NULL;
    ctx->tasks = (AV*)SvREFCNT_inc((SV*)list);
    ctx->final_cb = SvREFCNT_inc(final_cb);
    ctx->worker = worker ? SvREFCNT_inc(worker) : NULL;
    ctx->remaining = len;
    ctx->cvs = NULL;
    ctx->num_cvs = 0;
    ctx->shared_cv = NULL;
    ctx->abandoned = 0;

    ifp_guard *guard = ifp_guard_push(aTHX_ &ctx->is_freed_ptr, NULL,
                                      NULL, &ctx->abandoned);
    int *is_freed = &guard->is_freed;

    /* Counted before anything is dispatched: a task that completes the whole
       operation synchronously runs cleanup, which drops the context's
       reference, and only this one keeps the cell alive until we return it. */
    evf_handle *h = NULL;
    if (want_handle) {
        h = evf_handle_new(aTHX_ NULL, EVF_KIND_PARALLEL);
        evf_handle_attach(aTHX_ h, ctx);
        ctx->h = h;
        guard->pending_h = h;
    }

    SV *done_rv = NULL;
    if (unsafe) {
        ctx->shared_cv = newXS(NULL, parallel_task_done, __FILE__);
        CvXSUBANY(ctx->shared_cv).any_ptr = ctx;
        done_rv = sv_2mortal(newRV_inc((SV*)ctx->shared_cv));
    } else {
        ctx->num_cvs = len;
        Newxz(ctx->cvs, len, CV*);
    }

    dSP;

    I32 i;
    /* G_VOID as well as G_DISCARD: the value is discarded either way, but
       without the want bit the task's tail expression runs in scalar context,
       so a nested primitive there would allocate a handle nobody asked for.
       The final_cb calls in this file already pass G_VOID for the same reason. */
    U32 flags = G_DISCARD | G_VOID | (unsafe ? 0 : G_EVAL);
    const int have_worker = (worker != NULL);

    for (i = 0; i < len; i++) {
        if (*is_freed) break;

        SV **task_ary = (AvREAL(list) && !SvMAGICAL(list)) ? AvARRAY(list) : NULL;
        SV **fetch_ptr = (task_ary && i <= AvFILL(list))
            ? &task_ary[i]
            : av_fetch(list, i, 0);
        SV *task_sv = fetch_ptr ? *fetch_ptr : NULL;

        if (have_worker || IS_PVCV(task_sv)) {
            CV *cv = NULL;
            if (!unsafe) {
                cv = newXS(NULL, parallel_task_done, __FILE__);
                CvXSUBANY(cv).any_ptr = ctx;
                ctx->cvs[i] = (CV*)SvREFCNT_inc((SV*)cv);
            }

            ENTER;
            SAVETMPS;
            if (!unsafe) {
                done_rv = sv_2mortal(newRV_noinc((SV*)cv));
            }
            PUSHMARK(SP);
            if (have_worker) {
                XPUSHs(task_sv ? sv_2mortal(SvREFCNT_inc(task_sv)) : &PL_sv_undef);
            }
            XPUSHs(done_rv);
            PUTBACK;

            call_sv(have_worker ? worker : task_sv, flags);
            SPAGAIN;
            if (!unsafe) {
                if (SvTRUE(ERRSV)) {
                    SV *err = sv_mortalcopy(ERRSV);
                    if (!*is_freed) {
                        parallel_cleanup(aTHX_ &ctx);
                    }
                    croak_sv(err);
                }
            }

            FREETMPS;
            LEAVE;
        } else {
            if (--ctx->remaining <= 0) {
                SV *cb = ctx->final_cb;
                if (IS_PVCV(cb)) {
                    ENTER;
                    SAVETMPS;
                    SvREFCNT_inc(cb);
                    sv_2mortal(cb);
                    PUSHMARK(SP);
                    PUTBACK;
                    parallel_cleanup(aTHX_ &ctx);
                    call_sv(cb, G_DISCARD | G_VOID);
                    FREETMPS;
                    LEAVE;
                } else {
                    parallel_cleanup(aTHX_ &ctx);
                }
                break;
            }
        }
    }
    guard->completed = 1;
    LEAVE;
    return h;
}

static evf_handle *series_start(pTHX_ AV *list, SV *worker, SV *final_cb, int unsafe, int want_handle) {
    I32 len = av_len(list) + 1;
    if (len <= 0) {
        if (IS_PVCV(final_cb)) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            call_sv(final_cb, G_DISCARD | G_VOID);
            FREETMPS;
            LEAVE;
        }
        /* Already over: hand back a dead handle so callers get a uniform
           object rather than undef. */
        return want_handle ? evf_handle_new(aTHX_ NULL, EVF_KIND_SERIES) : NULL;
    }

    ENTER;

    series_ctx *ctx;
    Newx(ctx, 1, series_ctx);
    ctx->is_freed_ptr = NULL;
    ctx->h = NULL;
    ctx->tasks = (AV*)SvREFCNT_inc((SV*)list);
    ctx->final_cb = SvREFCNT_inc(final_cb);
    ctx->worker = worker ? SvREFCNT_inc(worker) : NULL;
    ctx->current_idx = 0;
    ctx->running = 0;
    ctx->delayed = 0;
    ctx->total_tasks = len;
    ctx->unsafe = unsafe;
    ctx->abandoned = 0;
    ctx->current_cv = NULL;

    ifp_guard *guard = ifp_guard_push(aTHX_ &ctx->is_freed_ptr, NULL,
                                      NULL, &ctx->abandoned);

    /* Counted before anything is dispatched; see parallel_start. */
    evf_handle *h = NULL;
    if (want_handle) {
        h = evf_handle_new(aTHX_ NULL, EVF_KIND_SERIES);
        evf_handle_attach(aTHX_ h, ctx);
        ctx->h = h;
        guard->pending_h = h;
    }

    _series_next(aTHX_ &ctx);

    guard->completed = 1;
    LEAVE;
    return h;
}

static evf_handle *plimit_start(pTHX_ AV *list, SV *worker, IV limit, SV *final_cb, int unsafe, int want_handle) {
    I32 len = av_len(list) + 1;
    if (len <= 0) {
        if (IS_PVCV(final_cb)) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            call_sv(final_cb, G_DISCARD | G_VOID);
            FREETMPS;
            LEAVE;
        }
        /* Already over: hand back a dead handle so callers get a uniform
           object rather than undef. */
        return want_handle ? evf_handle_new(aTHX_ NULL, EVF_KIND_PLIMIT) : NULL;
    }

    if (limit < 1) limit = 1;
    if (limit > len) limit = len;

    ENTER;

    plimit_ctx *ctx;
    Newx(ctx, 1, plimit_ctx);
    ctx->is_freed_ptr = NULL;
    ctx->h = NULL;
    ctx->tasks = (AV*)SvREFCNT_inc((SV*)list);
    ctx->final_cb = SvREFCNT_inc(final_cb);
    ctx->worker = worker ? SvREFCNT_inc(worker) : NULL;
    ctx->remaining = len;
    ctx->current_idx = 0;
    ctx->total_tasks = len;
    ctx->limit = limit;
    ctx->active = 0;
    ctx->unsafe = unsafe;
    ctx->running = 0;
    ctx->delayed = 0;
    ctx->abandoned = 0;
    ctx->cvs = NULL;
    ctx->num_cvs = 0;
    ctx->shared_cv = NULL;

    ifp_guard *guard = ifp_guard_push(aTHX_ &ctx->is_freed_ptr, NULL,
                                      NULL, &ctx->abandoned);

    /* Counted before anything is dispatched; see parallel_start. */
    evf_handle *h = NULL;
    if (want_handle) {
        h = evf_handle_new(aTHX_ NULL, EVF_KIND_PLIMIT);
        evf_handle_attach(aTHX_ h, ctx);
        ctx->h = h;
        guard->pending_h = h;
    }

    if (unsafe) {
        ctx->shared_cv = newXS(NULL, plimit_task_done, __FILE__);
        CvXSUBANY(ctx->shared_cv).any_ptr = ctx;
    } else {
        ctx->num_cvs = len;
        Newxz(ctx->cvs, len, CV*);
    }

    _plimit_dispatch(aTHX_ &ctx);

    guard->completed = 1;
    LEAVE;
    return h;
}

/* Cancel can only stop future dispatch; a task already in flight is user code
   sitting in an EV callback and cannot be interrupted. Running the primitive's
   normal cleanup NULLs any_ptr on every outstanding done CV, so those tasks
   calling done later are ignored. Cleanup also sets *(ctx->is_freed_ptr), which
   is how a cancel issued from inside a task makes the dispatch loop bail on its
   next turn. */
static void evf_handle_cancel(pTHX_ evf_handle *h, int fire) {
    SV *cb = NULL;

    if (!h || !h->ctx) return;

    switch (h->kind) {
        case EVF_KIND_PARALLEL: {
            parallel_ctx *ctx = (parallel_ctx *)h->ctx;
            if (fire && IS_PVCV(ctx->final_cb)) cb = sv_2mortal(SvREFCNT_inc(ctx->final_cb));
            parallel_cleanup(aTHX_ &ctx);
            break;
        }
        case EVF_KIND_PLIMIT: {
            plimit_ctx *ctx = (plimit_ctx *)h->ctx;
            if (fire && IS_PVCV(ctx->final_cb)) cb = sv_2mortal(SvREFCNT_inc(ctx->final_cb));
            plimit_cleanup(aTHX_ &ctx);
            break;
        }
        case EVF_KIND_SERIES: {
            series_ctx *ctx = (series_ctx *)h->ctx;
            if (fire && IS_PVCV(ctx->final_cb)) cb = sv_2mortal(SvREFCNT_inc(ctx->final_cb));
            series_cleanup(aTHX_ &ctx);
            break;
        }
        case EVF_KIND_RACE: {
            race_ctx *ctx = (race_ctx *)h->ctx;
            if (fire && IS_PVCV(ctx->final_cb)) cb = sv_2mortal(SvREFCNT_inc(ctx->final_cb));
            race_cleanup(aTHX_ &ctx);
            break;
        }
    }

    if (cb) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(cb, G_DISCARD | G_VOID);
        FREETMPS;
        LEAVE;
    }
}

/* pending: tasks not yet completed, counting both in flight and not yet
   dispatched. active: tasks currently in flight. parallel and race collapse the
   two because they dispatch everything up front and the handle is not returned
   until the XSUB returns. Returns 0 once the operation is over, so
   pending == 0 exactly when it has finished or been cancelled. */
static IV evf_handle_count(pTHX_ evf_handle *h, int want_active) {
    if (!h || !h->ctx) return 0;

    switch (h->kind) {
        case EVF_KIND_PARALLEL: {
            parallel_ctx *ctx = (parallel_ctx *)h->ctx;
            return (IV)ctx->remaining;
        }
        case EVF_KIND_PLIMIT: {
            plimit_ctx *ctx = (plimit_ctx *)h->ctx;
            IV act;
            if (!want_active) return (IV)ctx->remaining;
            /* Reachable, unlike the SERIES clamp below: an unsafe-mode task
               that calls its done more than once while the dispatch loop is
               still running decrements active per call with no re-dispatch to
               put it back, and a read from inside that task sees the deficit.
               Floor it rather than hand Perl a negative in-flight count. */
            act = (IV)ctx->active;
            return act < 0 ? 0 : act;
        }
        case EVF_KIND_SERIES: {
            series_ctx *ctx = (series_ctx *)h->ctx;
            IV left;
            if (want_active) return 1;
            left = (IV)ctx->total_tasks - (IV)ctx->current_idx + 1;
            /* Unreachable today - current_idx never exceeds total_tasks - but
               this floors a value crossing into Perl, so it stays cheap
               insurance against a future current_idx writer. */
            return left < 0 ? 0 : left;
        }
        case EVF_KIND_RACE: {
            race_ctx *ctx = (race_ctx *)h->ctx;
            return (IV)ctx->total_tasks;
        }
    }
    return 0;
}

MODULE = EV::Future		PACKAGE = EV::Future

PROTOTYPES: DISABLE

BOOT:
    /* No libev entry point is called from here; the primitives are pure
       callback-flow control over CVs the caller supplies. This pins the EV
       ABI the module was built against, which is why EV stays a prereq. */
    I_EV_API ("EV::Future");

void
parallel(list, final_cb, ...)
    AV *list
    SV *final_cb
    CODE:
        int unsafe = (items > 2 && SvTRUE(ST(2)));
        evf_handle *h = parallel_start(aTHX_ list, NULL, final_cb, unsafe,
                                       GIMME_V != G_VOID);
        if (h) {
            ST(0) = sv_2mortal(evf_handle_wrap(aTHX_ h));
            XSRETURN(1);
        }

void
parallel_map(list, worker, final_cb, ...)
    AV *list
    SV *worker
    SV *final_cb
    CODE:
        int unsafe = (items > 3 && SvTRUE(ST(3)));
        if (!IS_PVCV(worker))
            croak("EV::Future::parallel_map: worker must be a code reference");
        evf_handle *h = parallel_start(aTHX_ list, worker, final_cb, unsafe,
                                       GIMME_V != G_VOID);
        if (h) {
            ST(0) = sv_2mortal(evf_handle_wrap(aTHX_ h));
            XSRETURN(1);
        }

void
series(list, final_cb, ...)
    AV *list
    SV *final_cb
    CODE:
        int unsafe = (items > 2 && SvTRUE(ST(2)));
        evf_handle *h = series_start(aTHX_ list, NULL, final_cb, unsafe,
                                     GIMME_V != G_VOID);
        if (h) {
            ST(0) = sv_2mortal(evf_handle_wrap(aTHX_ h));
            XSRETURN(1);
        }

void
series_map(list, worker, final_cb, ...)
    AV *list
    SV *worker
    SV *final_cb
    CODE:
        int unsafe = (items > 3 && SvTRUE(ST(3)));
        if (!IS_PVCV(worker))
            croak("EV::Future::series_map: worker must be a code reference");
        evf_handle *h = series_start(aTHX_ list, worker, final_cb, unsafe,
                                     GIMME_V != G_VOID);
        if (h) {
            ST(0) = sv_2mortal(evf_handle_wrap(aTHX_ h));
            XSRETURN(1);
        }

void
parallel_limit(list, limit, final_cb, ...)
    AV *list
    IV limit
    SV *final_cb
    CODE:
        int unsafe = (items > 3 && SvTRUE(ST(3)));
        evf_handle *h = plimit_start(aTHX_ list, NULL, limit, final_cb, unsafe,
                                     GIMME_V != G_VOID);
        if (h) {
            ST(0) = sv_2mortal(evf_handle_wrap(aTHX_ h));
            XSRETURN(1);
        }

void
parallel_map_limit(list, worker, limit, final_cb, ...)
    AV *list
    SV *worker
    IV limit
    SV *final_cb
    CODE:
        int unsafe = (items > 4 && SvTRUE(ST(4)));
        if (!IS_PVCV(worker))
            croak("EV::Future::parallel_map_limit: worker must be a code reference");
        evf_handle *h = plimit_start(aTHX_ list, worker, limit, final_cb, unsafe,
                                     GIMME_V != G_VOID);
        if (h) {
            ST(0) = sv_2mortal(evf_handle_wrap(aTHX_ h));
            XSRETURN(1);
        }

void
race(tasks, final_cb, ...)
    AV *tasks
    SV *final_cb
    CODE:
        int unsafe = 0;
        if (items > 2 && SvTRUE(ST(2))) unsafe = 1;

        I32 len = av_len(tasks) + 1;
        if (len <= 0) {
            if (IS_PVCV(final_cb)) {
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                PUTBACK;
                call_sv(final_cb, G_DISCARD | G_VOID);
                FREETMPS;
                LEAVE;
            }
            /* Already over: hand back a dead handle so callers get a uniform
               object rather than undef. */
            if (GIMME_V != G_VOID) {
                ST(0) = sv_2mortal(evf_handle_wrap(aTHX_
                            evf_handle_new(aTHX_ NULL, EVF_KIND_RACE)));
                XSRETURN(1);
            }
            return;
        }

        ENTER;

        race_ctx *ctx;
        Newx(ctx, 1, race_ctx);
        ctx->is_freed_ptr = NULL;
        ctx->h = NULL;
        ctx->tasks = (AV*)SvREFCNT_inc((SV*)tasks);
        ctx->final_cb = SvREFCNT_inc(final_cb);
        ctx->settled = 0;
        ctx->total_tasks = len;
        ctx->abandoned = 0;
        ctx->cvs = NULL;
        ctx->num_cvs = 0;
        ctx->shared_cv = NULL;

        ifp_guard *guard = ifp_guard_push(aTHX_ &ctx->is_freed_ptr, NULL,
                                          NULL, &ctx->abandoned);
        int *is_freed = &guard->is_freed;

        /* Counted before anything is dispatched; see parallel_start. */
        evf_handle *h = NULL;
        if (GIMME_V != G_VOID) {
            h = evf_handle_new(aTHX_ NULL, EVF_KIND_RACE);
            evf_handle_attach(aTHX_ h, ctx);
            ctx->h = h;
            guard->pending_h = h;
        }

        SV *done_rv = NULL;
        if (unsafe) {
            ctx->shared_cv = newXS(NULL, race_task_done, __FILE__);
            CvXSUBANY(ctx->shared_cv).any_ptr = ctx;
            done_rv = sv_2mortal(newRV_inc((SV*)ctx->shared_cv));
        } else {
            ctx->num_cvs = len;
            Newxz(ctx->cvs, len, CV*);
        }

        dSP;

        I32 i;
        /* G_VOID: see parallel_start. */
        U32 flags = G_DISCARD | G_VOID | (unsafe ? 0 : G_EVAL);

        for (i = 0; i < len; i++) {
            if (*is_freed || ctx->settled) break;

            SV **task_ary = (AvREAL(tasks) && !SvMAGICAL(tasks)) ? AvARRAY(tasks) : NULL;
            SV **fetch_ptr = (task_ary && i <= AvFILL(tasks))
                ? &task_ary[i]
                : av_fetch(tasks, i, 0);
            SV *task_sv = fetch_ptr ? *fetch_ptr : NULL;

            if (IS_PVCV(task_sv)) {
                CV *cv = NULL;
                if (!unsafe) {
                    cv = newXS(NULL, race_task_done, __FILE__);
                    CvXSUBANY(cv).any_ptr = ctx;
                    ctx->cvs[i] = (CV*)SvREFCNT_inc((SV*)cv);
                }

                ENTER;
                SAVETMPS;
                if (!unsafe) {
                    done_rv = sv_2mortal(newRV_noinc((SV*)cv));
                }
                PUSHMARK(SP);
                XPUSHs(done_rv);
                PUTBACK;

                call_sv(task_sv, flags);
                SPAGAIN;
                if (!unsafe) {
                    if (SvTRUE(ERRSV)) {
                        SV *err = sv_mortalcopy(ERRSV);
                        if (!*is_freed) {
                            race_cleanup(aTHX_ &ctx);
                        }
                        croak_sv(err);
                    }
                }

                FREETMPS;
                LEAVE;
            } else {
                ctx->settled = 1;
                SV *cb = ctx->final_cb;
                if (IS_PVCV(cb)) {
                    ENTER;
                    SAVETMPS;
                    SvREFCNT_inc(cb);
                    sv_2mortal(cb);
                    PUSHMARK(SP);
                    PUTBACK;
                    race_cleanup(aTHX_ &ctx);
                    call_sv(cb, G_DISCARD | G_VOID);
                    FREETMPS;
                    LEAVE;
                } else {
                    race_cleanup(aTHX_ &ctx);
                }
                break;
            }
        }
        guard->completed = 1;
        LEAVE;
        if (h) {
            ST(0) = sv_2mortal(evf_handle_wrap(aTHX_ h));
            XSRETURN(1);
        }

MODULE = EV::Future		PACKAGE = EV::Future::Handle

void
DESTROY(self)
    SV *self
    CODE:
        evf_handle *h = evf_handle_from_sv(aTHX_ self);
        if (h) {
            evf_handle_dec(aTHX_ h);
            /* Zero the payload so a hand-written second DESTROY is inert. */
            SvIV_set(SvRV(self), 0);
        }

void
cancel(self, ...)
    SV *self
    CODE:
        evf_handle *h = evf_handle_from_sv(aTHX_ self);
        int fire = (items > 1 && SvTRUE(ST(1)));
        evf_handle_cancel(aTHX_ h, fire);

IV
pending(self)
    SV *self
    CODE:
        RETVAL = evf_handle_count(aTHX_ evf_handle_from_sv(aTHX_ self), 0);
    OUTPUT:
        RETVAL

IV
active(self)
    SV *self
    CODE:
        RETVAL = evf_handle_count(aTHX_ evf_handle_from_sv(aTHX_ self), 1);
    OUTPUT:
        RETVAL
