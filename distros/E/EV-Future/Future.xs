#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "EVAPI.h"

#define IS_PVCV(sv) (sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)

typedef struct {
    AV *tasks;
    SV *final_cb;
    I32 remaining;
    CV **cvs;
    I32 num_cvs;
    CV *shared_cv; /* for unsafe mode */
    int *is_freed_ptr;
} parallel_ctx;

typedef struct {
    AV *tasks;
    SV *final_cb;
    I32 current_idx;
    int running;
    int delayed;
    I32 total_tasks;
    int unsafe;
    CV *current_cv;
    int *is_freed_ptr;
} series_ctx;

typedef struct {
    AV *tasks;
    SV *final_cb;
    I32 remaining;
    I32 current_idx;
    I32 total_tasks;
    I32 limit;
    I32 active;
    int unsafe;
    int running;
    int delayed;
    CV **cvs;
    I32 num_cvs;
    CV *shared_cv;
    int *is_freed_ptr;
} plimit_ctx;

static void parallel_cleanup(pTHX_ parallel_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    parallel_ctx *ctx = *ctx_ptr;
    *ctx_ptr = NULL;

    if (ctx->is_freed_ptr) {
        *(ctx->is_freed_ptr) = 1;
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
    }
    if (ctx->tasks) SvREFCNT_dec((SV*)ctx->tasks);
    if (ctx->final_cb) SvREFCNT_dec(ctx->final_cb);
    Safefree(ctx);
}

static void parallel_task_done(pTHX_ CV *cv) {
    dXSARGS;
    SvREFCNT_inc_simple_void(cv);
    sv_2mortal((SV*)cv);
    parallel_ctx *ctx = (parallel_ctx *)CvXSUBANY(cv).any_ptr;
    if (!ctx) {
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

    if (ctx->current_cv) {
        CvXSUBANY(ctx->current_cv).any_ptr = NULL;
        SvREFCNT_dec((SV*)ctx->current_cv);
    }
    if (ctx->tasks) SvREFCNT_dec((SV*)ctx->tasks);
    if (ctx->final_cb) SvREFCNT_dec(ctx->final_cb);
    Safefree(ctx);
}

static void _series_next(pTHX_ series_ctx **ctx_ptr);

static void series_next_cb(pTHX_ CV *cv) {
    dXSARGS;
    SvREFCNT_inc_simple_void(cv);
    sv_2mortal((SV*)cv);
    series_ctx *ctx = (series_ctx *)CvXSUBANY(cv).any_ptr;
    if (!ctx) {
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
            return;
        }

        SV **fetch_ptr = (task_ary && ctx->current_idx <= AvFILL(ctx->tasks))
            ? &task_ary[ctx->current_idx]
            : av_fetch(ctx->tasks, ctx->current_idx, 0);
        SV *task_sv = fetch_ptr ? *fetch_ptr : NULL;

        ctx->current_idx++;

        if (IS_PVCV(task_sv)) {
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
            XPUSHs(next_rv);
            PUTBACK;
            
            U32 flags = G_DISCARD | (ctx->unsafe ? 0 : G_EVAL);
            call_sv(task_sv, flags);

            if (!ctx->unsafe) {
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    SV *err = sv_mortalcopy(ERRSV);
                    series_cleanup(aTHX_ ctx_ptr);
                    croak_sv(err);
                }
            }

            FREETMPS;
            LEAVE;
            if (!*ctx_ptr) return;
        } else {
            ctx->delayed = 1;
        }
    }

    if (*ctx_ptr) (*ctx_ptr)->running = 0;
}

static void plimit_cleanup(pTHX_ plimit_ctx **ctx_ptr) {
    if (!ctx_ptr || !*ctx_ptr) return;
    plimit_ctx *ctx = *ctx_ptr;
    *ctx_ptr = NULL;

    if (ctx->is_freed_ptr) {
        *(ctx->is_freed_ptr) = 1;
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
    }
    if (ctx->tasks) SvREFCNT_dec((SV*)ctx->tasks);
    if (ctx->final_cb) SvREFCNT_dec(ctx->final_cb);
    Safefree(ctx);
}

static void _plimit_dispatch(pTHX_ plimit_ctx **ctx_ptr);

static void plimit_task_done(pTHX_ CV *cv) {
    dXSARGS;
    SvREFCNT_inc_simple_void(cv);
    sv_2mortal((SV*)cv);
    plimit_ctx *ctx = (plimit_ctx *)CvXSUBANY(cv).any_ptr;
    if (!ctx) {
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

    int is_freed = 0;
    int *old_is_freed_ptr = ctx->is_freed_ptr;
    ctx->is_freed_ptr = &is_freed;

    ctx->running = 1;
    ctx->delayed = 1;

    while (ctx->delayed) {
        ctx->delayed = 0;

        while (!is_freed && ctx->active < ctx->limit && ctx->current_idx < ctx->total_tasks) {
            SV **task_ary = (AvREAL(ctx->tasks) && !SvMAGICAL(ctx->tasks)) ? AvARRAY(ctx->tasks) : NULL;
            SV **fetch_ptr = (task_ary && ctx->current_idx <= AvFILL(ctx->tasks))
                ? &task_ary[ctx->current_idx]
                : av_fetch(ctx->tasks, ctx->current_idx, 0);
            SV *task_sv = fetch_ptr ? *fetch_ptr : NULL;

            ctx->current_idx++;

            if (IS_PVCV(task_sv)) {
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
                XPUSHs(done_rv);
                PUTBACK;

                U32 flags = G_DISCARD | (task_unsafe ? 0 : G_EVAL);
                call_sv(task_sv, flags);

                if (!task_unsafe) {
                    SPAGAIN;
                    if (SvTRUE(ERRSV)) {
                        SV *err = sv_mortalcopy(ERRSV);
                        if (!is_freed) {
                            plimit_cleanup(aTHX_ ctx_ptr);
                        }
                        if (old_is_freed_ptr) *old_is_freed_ptr = 1;
                        croak_sv(err);
                    }
                }

                FREETMPS;
                LEAVE;
                if (is_freed) goto done;
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
                        if (old_is_freed_ptr) *old_is_freed_ptr = 1;
                        call_sv(cb, G_DISCARD | G_VOID);
                        FREETMPS;
                        LEAVE;
                    } else {
                        plimit_cleanup(aTHX_ ctx_ptr);
                        if (old_is_freed_ptr) *old_is_freed_ptr = 1;
                    }
                    goto done;
                }
                ctx->delayed = 1;
            }
        }
    }

    if (!is_freed) {
        ctx->is_freed_ptr = old_is_freed_ptr;
        ctx->running = 0;
    }
done:
    if (is_freed && old_is_freed_ptr) {
        *old_is_freed_ptr = 1;
    }
}

MODULE = EV::Future		PACKAGE = EV::Future

PROTOTYPES: DISABLE

BOOT:
    I_EV_API ("EV::Future");

void
parallel(tasks, final_cb, ...)
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
            return;
        }

        int is_freed = 0;
        parallel_ctx *ctx;
        Newx(ctx, 1, parallel_ctx);
        ctx->is_freed_ptr = &is_freed;
        ctx->tasks = (AV*)SvREFCNT_inc((SV*)tasks);
        ctx->final_cb = SvREFCNT_inc(final_cb);
        ctx->remaining = len;
        ctx->cvs = NULL;
        ctx->num_cvs = 0;
        ctx->shared_cv = NULL;

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
        U32 flags = G_DISCARD | (unsafe ? 0 : G_EVAL);

        for (i = 0; i < len; i++) {
            if (is_freed) break;

            SV **task_ary = (AvREAL(tasks) && !SvMAGICAL(tasks)) ? AvARRAY(tasks) : NULL;
            SV **fetch_ptr = (task_ary && i <= AvFILL(tasks))
                ? &task_ary[i]
                : av_fetch(tasks, i, 0);
            SV *task_sv = fetch_ptr ? *fetch_ptr : NULL;

            if (IS_PVCV(task_sv)) {
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
                XPUSHs(done_rv);
                PUTBACK;

                call_sv(task_sv, flags);
                if (!unsafe) {
                    SPAGAIN;
                    if (SvTRUE(ERRSV)) {
                        SV *err = sv_mortalcopy(ERRSV);
                        if (!is_freed) {
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
        if (!is_freed && ctx) {
            ctx->is_freed_ptr = NULL;
        }

void
series(tasks, final_cb, ...)
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
            return;
        }

        int is_freed = 0;
        series_ctx *ctx;
        Newx(ctx, 1, series_ctx);
        ctx->is_freed_ptr = &is_freed;
        ctx->tasks = (AV*)SvREFCNT_inc((SV*)tasks);
        ctx->final_cb = SvREFCNT_inc(final_cb);
        ctx->current_idx = 0;
        ctx->running = 0;
        ctx->delayed = 0;
        ctx->total_tasks = len;
        ctx->unsafe = unsafe;
        ctx->current_cv = NULL;

        _series_next(aTHX_ &ctx);
        if (!is_freed && ctx) {
            ctx->is_freed_ptr = NULL;
        }

void
parallel_limit(tasks, limit, final_cb, ...)
    AV *tasks
    I32 limit
    SV *final_cb
    CODE:
        int unsafe = 0;
        if (items > 3 && SvTRUE(ST(3))) unsafe = 1;

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
            return;
        }

        if (limit < 1) limit = 1;
        if (limit > len) limit = len;

        int is_freed = 0;
        plimit_ctx *ctx;
        Newx(ctx, 1, plimit_ctx);
        ctx->is_freed_ptr = &is_freed;
        ctx->tasks = (AV*)SvREFCNT_inc((SV*)tasks);
        ctx->final_cb = SvREFCNT_inc(final_cb);
        ctx->remaining = len;
        ctx->current_idx = 0;
        ctx->total_tasks = len;
        ctx->limit = limit;
        ctx->active = 0;
        ctx->unsafe = unsafe;
        ctx->running = 0;
        ctx->delayed = 0;
        ctx->cvs = NULL;
        ctx->num_cvs = 0;
        ctx->shared_cv = NULL;

        if (unsafe) {
            ctx->shared_cv = newXS(NULL, plimit_task_done, __FILE__);
            CvXSUBANY(ctx->shared_cv).any_ptr = ctx;
        } else {
            ctx->num_cvs = len;
            Newxz(ctx->cvs, len, CV*);
        }

        _plimit_dispatch(aTHX_ &ctx);
        if (!is_freed && ctx) {
            ctx->is_freed_ptr = NULL;
        }
