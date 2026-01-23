#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/*
 * Full XS implementation of Future::Batch
 * Uses CvXSUBANY to create closures for Future callbacks
 */

/* Forward declarations */
static void start_one(pTHX_ SV *state_sv);
XS(XS_on_done_callback);
XS(XS_on_fail_callback);
XS(XS_start_one_wrapper);

/*
 * BatchState - main state structure stored with SV magic
 */
typedef struct {
    SV *self_ref;       /* Weak ref back to our State object */
    AV *items;
    AV *results;
    AV *queue;
    AV *errors;
    SV *worker;
    SV *on_progress;
    SV *loop;
    SV *result_future;
    SV *start_one_cv;
    IV concurrent;
    IV in_flight;
    IV finished;
    IV total;
    bool fail_fast;
    bool aborted;
} BatchState;

/*
 * CallbackData - closure data for on_done/on_fail callbacks
 */
typedef struct {
    SV *state_sv;
    SV *item;
    IV idx;
} CallbackData;

/* Magic vtable for BatchState */
static int state_magic_free(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL state_vtbl = {
    NULL, NULL, NULL, NULL,
    state_magic_free,
    NULL, NULL, NULL
};

static int
state_magic_free(pTHX_ SV *sv, MAGIC *mg)
{
    BatchState *state = (BatchState*)mg->mg_ptr;
    if (state) {
        if (state->items)         SvREFCNT_dec((SV*)state->items);
        if (state->results)       SvREFCNT_dec((SV*)state->results);
        if (state->queue)         SvREFCNT_dec((SV*)state->queue);
        if (state->errors)        SvREFCNT_dec((SV*)state->errors);
        if (state->worker)        SvREFCNT_dec(state->worker);
        if (state->on_progress)   SvREFCNT_dec(state->on_progress);
        if (state->loop)          SvREFCNT_dec(state->loop);
        if (state->result_future) SvREFCNT_dec(state->result_future);
        if (state->start_one_cv)  SvREFCNT_dec(state->start_one_cv);
        Safefree(state);
    }
    return 0;
}

/* Magic vtable for callback closure data cleanup */
static int callback_magic_free(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL callback_vtbl = {
    NULL, NULL, NULL, NULL,
    callback_magic_free,
    NULL, NULL, NULL
};

static int
callback_magic_free(pTHX_ SV *sv, MAGIC *mg)
{
    CallbackData *data = (CallbackData*)mg->mg_ptr;
    if (data) {
        if (data->state_sv) SvREFCNT_dec(data->state_sv);
        if (data->item)     SvREFCNT_dec(data->item);
        Safefree(data);
    }
    return 0;
}

static BatchState*
get_state(pTHX_ SV *sv)
{
    MAGIC *mg;
    if (SvROK(sv)) sv = SvRV(sv);
    mg = mg_findext(sv, PERL_MAGIC_ext, &state_vtbl);
    return mg ? (BatchState*)mg->mg_ptr : NULL;
}

static SV*
new_state_sv(pTHX_ BatchState *state)
{
    SV *inner = newSV(0);
    SV *ref;
    sv_magicext(inner, NULL, PERL_MAGIC_ext, &state_vtbl, (char*)state, 0);
    ref = sv_bless(newRV_noinc(inner), gv_stashpv("Future::Batch::XS::State", GV_ADD));
    state->self_ref = ref;
    return ref;
}

/* Helper: check if SV is a Future */
static bool
is_future(pTHX_ SV *sv)
{
    if (!SvROK(sv)) return FALSE;
    return sv_derived_from(sv, "Future");
}

/* Helper: check if result_future is ready */
static bool
is_ready(pTHX_ SV *future)
{
    dSP;
    bool ready = 0;
    int count;
    
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(future);
    PUTBACK;
    count = call_method("is_ready", G_SCALAR);
    SPAGAIN;
    if (count > 0) {
        SV *result_sv = POPs;
        if (result_sv && SvOK(result_sv)) {
            ready = SvTRUE(result_sv);
        }
    }
    PUTBACK; FREETMPS; LEAVE;
    return ready;
}

/* Helper: call progress callback */
static void
call_progress(pTHX_ BatchState *state)
{
    if (state->on_progress && SvOK(state->on_progress) && SvROK(state->on_progress)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi(state->finished);
        mXPUSHi(state->total);
        PUTBACK;
        call_sv(state->on_progress, G_DISCARD);
        FREETMPS; LEAVE;
    }
}

/* Helper: schedule via loop->later */
static void
schedule_later(pTHX_ BatchState *state)
{
    if (state->loop && SvOK(state->loop) && state->start_one_cv) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(state->loop);
        XPUSHs(state->start_one_cv);
        PUTBACK;
        call_method("later", G_DISCARD);
        FREETMPS; LEAVE;
    }
}

/* Finish the batch - call done or fail on result_future */
static void
finish_batch(pTHX_ BatchState *state)
{
    dSP;
    if (av_len(state->errors) >= 0) {
        IV count = av_len(state->errors) + 1;
        SV *msg = newSVpvf("Batch failed with %" IVdf " error(s)", count);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(state->result_future);
        XPUSHs(sv_2mortal(msg));
        mXPUSHs(newSVpv("batch", 0));
        XPUSHs(sv_2mortal(newRV_inc((SV*)state->errors)));
        XPUSHs(sv_2mortal(newRV_inc((SV*)state->results)));
        PUTBACK;
        call_method("fail", G_DISCARD);
        FREETMPS; LEAVE;
    } else {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(state->result_future);
        XPUSHs(sv_2mortal(newRV_inc((SV*)state->results)));
        PUTBACK;
        call_method("done", G_DISCARD);
        FREETMPS; LEAVE;
    }
}

/* Abort the batch (fail_fast) */
static void
abort_batch(pTHX_ BatchState *state, const char *message)
{
    dSP;
    if (state->aborted) return;
    state->aborted = TRUE;
    av_clear(state->queue);
    
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(state->result_future);
    mXPUSHs(newSVpv(message, 0));
    mXPUSHs(newSVpv("batch", 0));
    XPUSHs(sv_2mortal(newRV_inc((SV*)state->errors)));
    XPUSHs(sv_2mortal(newRV_inc((SV*)state->results)));
    PUTBACK;
    call_method("fail", G_DISCARD);
    FREETMPS; LEAVE;
}

/* Create an XS closure with CallbackData attached using CvXSUBANY */
static SV*
make_callback_cv(pTHX_ XSUBADDR_t xsub, SV *state_sv, SV *item, IV idx)
{
    CallbackData *data;
    CV *cv;
    
    Newxz(data, 1, CallbackData);
    data->state_sv = newSVsv(state_sv);
    data->item = item ? newSVsv(item) : NULL;
    data->idx = idx;
    
    cv = newXS(NULL, xsub, __FILE__);
    CvXSUBANY(cv).any_ptr = (void*)data;
    /* Also attach magic for cleanup */
    sv_magicext((SV*)cv, NULL, PERL_MAGIC_ext, &callback_vtbl, (char*)data, 0);
    
    return newRV_noinc((SV*)cv);
}

/* Get CallbackData from a CV using CvXSUBANY */
static CallbackData*
get_callback_data(pTHX_ CV *cv)
{
    return (CallbackData*)CvXSUBANY(cv).any_ptr;
}

/*
 * XS callback for Future->on_done
 */
XS(XS_on_done_callback)
{
    dVAR; dXSARGS;
    CallbackData *data;
    BatchState *state;
    SV *result;
    bool has_loop;
    PERL_UNUSED_VAR(items);
    
    data = get_callback_data(aTHX_ cv);
    if (!data || !data->state_sv) XSRETURN(0);
    
    state = get_state(aTHX_ data->state_sv);
    if (!state) XSRETURN(0);
    
    /* Store result */
    if (items == 1) {
        result = ST(0);
    } else if (items > 1) {
        AV *av = newAV();
        IV i;
        for (i = 0; i < items; i++) {
            av_push(av, newSVsv(ST(i)));
        }
        result = sv_2mortal(newRV_noinc((SV*)av));
    } else {
        result = &PL_sv_undef;
    }
    
    if (data->idx <= av_len(state->results)) {
        SvREFCNT_dec(AvARRAY(state->results)[data->idx]);
        AvARRAY(state->results)[data->idx] = newSVsv(result);
    }
    
    state->in_flight--;
    state->finished++;
    call_progress(aTHX_ state);
    
    has_loop = state->loop && SvOK(state->loop);
    
    if (state->finished == state->total) {
        finish_batch(aTHX_ state);
    } else if (!state->aborted && !is_ready(aTHX_ state->result_future)) {
        if (has_loop) {
            schedule_later(aTHX_ state);
        } else {
            /* Need to save state_sv before returning as callback data may be freed */
            SV *state_copy = newSVsv(data->state_sv);
            PUTBACK;  /* Save stack before calling start_one */
            start_one(aTHX_ state_copy);
            SvREFCNT_dec(state_copy);
            SPAGAIN;  /* Restore stack */
        }
    }
    
    XSRETURN(0);
}

/*
 * XS callback for Future->on_fail
 */
XS(XS_on_fail_callback)
{
    dVAR; dXSARGS;
    CallbackData *data;
    BatchState *state;
    HV *err;
    AV *failure;
    IV i;
    const char *msg;
    bool has_loop;
    PERL_UNUSED_VAR(items);
    
    data = get_callback_data(aTHX_ cv);
    if (!data || !data->state_sv) XSRETURN(0);
    
    state = get_state(aTHX_ data->state_sv);
    if (!state) XSRETURN(0);
    
    state->in_flight--;
    state->finished++;
    
    /* Store error */
    failure = newAV();
    for (i = 0; i < items; i++) {
        av_push(failure, newSVsv(ST(i)));
    }
    
    err = newHV();
    hv_store(err, "index", 5, newSViv(data->idx), 0);
    hv_store(err, "item", 4, data->item ? newSVsv(data->item) : newSV(0), 0);
    hv_store(err, "failure", 7, newRV_noinc((SV*)failure), 0);
    av_push(state->errors, newRV_noinc((SV*)err));
    
    call_progress(aTHX_ state);
    
    has_loop = state->loop && SvOK(state->loop);
    
    if (state->fail_fast) {
        msg = (items > 0 && SvOK(ST(0))) ? SvPV_nolen(ST(0)) : "unknown error";
        char buf[256];
        snprintf(buf, sizeof(buf), "Batch aborted: %s", msg);
        abort_batch(aTHX_ state, buf);
    } else if (state->finished == state->total) {
        finish_batch(aTHX_ state);
    } else if (!state->aborted && !is_ready(aTHX_ state->result_future)) {
        if (has_loop) {
            schedule_later(aTHX_ state);
        } else {
            SV *state_copy = newSVsv(data->state_sv);
            PUTBACK;
            start_one(aTHX_ state_copy);
            SvREFCNT_dec(state_copy);
            SPAGAIN;
        }
    }
    
    XSRETURN(0);
}

/*
 * XS wrapper for start_one - used with loop->later
 */
XS(XS_start_one_wrapper)
{
    dVAR; dXSARGS;
    CallbackData *data;
    PERL_UNUSED_VAR(items);
    
    data = get_callback_data(aTHX_ cv);
    if (data && data->state_sv) {
        start_one(aTHX_ data->state_sv);
    }
    XSRETURN(0);
}

/*
 * Core start_one implementation - starts processing one item
 */
static void
start_one(pTHX_ SV *state_sv)
{
    dSP;
    BatchState *state;
    IV idx;
    SV *item, *worker_result, *future;
    SV *on_done_cv, *on_fail_cv;
    
    state = get_state(aTHX_ state_sv);
    if (!state) return;
    
    /* Check if we should stop */
    if (state->aborted || is_ready(aTHX_ state->result_future)) return;
    if (av_len(state->queue) < 0) return;
    if (state->in_flight >= state->concurrent) return;
    
    /* Get next item */
    {
        SV *idx_sv = av_shift(state->queue);
        idx = SvIV(idx_sv);
        SvREFCNT_dec(idx_sv);
    }
    
    item = *av_fetch(state->items, idx, 0);
    state->in_flight++;
    
    /* Call worker */
    if (state->worker && SvOK(state->worker)) {
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(item);
        mXPUSHi(idx);
        PUTBACK;
        
        if (call_sv(state->worker, G_SCALAR | G_EVAL) > 0) {
            SPAGAIN;
            worker_result = newSVsv(POPs);
        } else {
            worker_result = &PL_sv_undef;
        }
        PUTBACK; FREETMPS; LEAVE;
        
        if (SvTRUE(ERRSV)) {
            /* Worker died - create Future->fail */
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            mXPUSHs(newSVpv("Future", 0));
            XPUSHs(ERRSV);
            PUTBACK;
            call_method("fail", G_SCALAR);
            SPAGAIN;
            future = newSVsv(POPs);
            PUTBACK; FREETMPS; LEAVE;
            SvREFCNT_dec(worker_result);
        } else if (is_future(aTHX_ worker_result)) {
            future = worker_result;
        } else {
            /* Wrap in Future->done */
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            mXPUSHs(newSVpv("Future", 0));
            XPUSHs(worker_result);
            PUTBACK;
            call_method("done", G_SCALAR);
            SPAGAIN;
            future = newSVsv(POPs);
            PUTBACK; FREETMPS; LEAVE;
            SvREFCNT_dec(worker_result);
        }
    } else {
        /* Default worker: Future->done($item) */
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(newSVpv("Future", 0));
        XPUSHs(item);
        PUTBACK;
        call_method("done", G_SCALAR);
        SPAGAIN;
        future = newSVsv(POPs);
        PUTBACK; FREETMPS; LEAVE;
    }
    
    /* Create callback closures */
    on_done_cv = make_callback_cv(aTHX_ XS_on_done_callback, state_sv, item, idx);
    on_fail_cv = make_callback_cv(aTHX_ XS_on_fail_callback, state_sv, item, idx);
    
    /* Attach on_done callback */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(future);
    XPUSHs(on_done_cv);
    PUTBACK;
    call_method("on_done", G_DISCARD);
    FREETMPS; LEAVE;
    
    /* Attach on_fail callback */
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(future);
    XPUSHs(on_fail_cv);
    PUTBACK;
    call_method("on_fail", G_DISCARD);
    FREETMPS; LEAVE;
    
    SvREFCNT_dec(future);
    SvREFCNT_dec(on_done_cv);
    SvREFCNT_dec(on_fail_cv);
}

/*
 * Run the batch - fill initial concurrent slots
 */
static void
run_loop(pTHX_ SV *state_sv)
{
    BatchState *state = get_state(aTHX_ state_sv);
    bool has_loop;
    IV i, initial;
    
    if (!state) return;
    
    has_loop = state->loop && SvOK(state->loop);
    
    /* Create start_one wrapper CV for loop->later */
    if (has_loop) {
        state->start_one_cv = make_callback_cv(aTHX_ XS_start_one_wrapper, state_sv, NULL, 0);
    }
    
    /* Start initial batch */
    initial = state->concurrent;
    if (av_len(state->queue) + 1 < initial) {
        initial = av_len(state->queue) + 1;
    }
    
    if (has_loop) {
        /* Start first one directly, schedule rest */
        start_one(aTHX_ state_sv);
        for (i = 1; i < initial; i++) {
            schedule_later(aTHX_ state);
        }
    } else {
        /* Synchronous mode - start all initial slots */
        while (av_len(state->queue) >= 0 && state->in_flight < state->concurrent) {
            start_one(aTHX_ state_sv);
        }
    }
}


MODULE = Future::Batch::XS    PACKAGE = Future::Batch::XS

PROTOTYPES: DISABLE

SV *
new(class, ...)
    char *class
PREINIT:
    HV *self;
    IV concurrent = 10;
    bool fail_fast = FALSE;
    SV *on_progress = &PL_sv_undef;
    SV *loop_sv = &PL_sv_undef;
    IV i;
CODE:
    self = newHV();
    
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "concurrent") && SvOK(val)) {
                concurrent = SvIV(val);
            } else if (strEQ(key, "fail_fast") && SvOK(val)) {
                fail_fast = SvTRUE(val) ? TRUE : FALSE;
            } else if (strEQ(key, "on_progress") && SvOK(val)) {
                on_progress = val;
            } else if (strEQ(key, "loop") && SvOK(val)) {
                loop_sv = val;
            }
        }
    }
    
    if (concurrent < 1) concurrent = 1;
    
    hv_store(self, "concurrent", 10, newSViv(concurrent), 0);
    hv_store(self, "fail_fast", 9, newSViv(fail_fast ? 1 : 0), 0);
    hv_store(self, "on_progress", 11, newSVsv(on_progress), 0);
    hv_store(self, "loop", 4, newSVsv(loop_sv), 0);
    
    RETVAL = sv_bless(newRV_noinc((SV*)self), gv_stashpv(class, GV_ADD));
OUTPUT:
    RETVAL

IV
concurrent(self, ...)
    SV *self
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self)) croak("self is not a reference");
    hv = (HV*)SvRV(self);
    if (items > 1 && SvOK(ST(1))) {
        hv_store(hv, "concurrent", 10, newSViv(SvIV(ST(1))), 0);
    }
    {
        SV **svp = hv_fetch(hv, "concurrent", 10, 0);
        RETVAL = svp ? SvIV(*svp) : 10;
    }
OUTPUT:
    RETVAL

IV
fail_fast(self, ...)
    SV *self
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self)) croak("self is not a reference");
    hv = (HV*)SvRV(self);
    if (items > 1 && SvOK(ST(1))) {
        hv_store(hv, "fail_fast", 9, newSViv(SvTRUE(ST(1)) ? 1 : 0), 0);
    }
    {
        SV **svp = hv_fetch(hv, "fail_fast", 9, 0);
        RETVAL = svp ? SvIV(*svp) : 0;
    }
OUTPUT:
    RETVAL

SV *
on_progress(self, ...)
    SV *self
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self)) croak("self is not a reference");
    hv = (HV*)SvRV(self);
    if (items > 1) {
        hv_store(hv, "on_progress", 11, newSVsv(ST(1)), 0);
    }
    {
        SV **svp = hv_fetch(hv, "on_progress", 11, 0);
        RETVAL = svp ? newSVsv(*svp) : &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV *
loop(self, ...)
    SV *self
PREINIT:
    HV *hv;
CODE:
    if (!SvROK(self)) croak("self is not a reference");
    hv = (HV*)SvRV(self);
    if (items > 1) {
        hv_store(hv, "loop", 4, newSVsv(ST(1)), 0);
    }
    {
        SV **svp = hv_fetch(hv, "loop", 4, 0);
        RETVAL = svp ? newSVsv(*svp) : &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV *
run(self, ...)
    SV *self
PREINIT:
    dSP;
    HV *self_hv;
    AV *items_av = NULL;
    SV *worker = NULL;
    SV *on_progress, *loop_sv;
    IV concurrent, fail_fast, total, i;
    BatchState *state;
    SV *state_sv;
CODE:
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("self is not a hash reference");
    self_hv = (HV*)SvRV(self);
    
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "items") && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                items_av = (AV*)SvRV(val);
            } else if (strEQ(key, "worker") && SvROK(val)) {
                worker = val;
            }
        }
    }
    
    /* Empty items - return Future->done([]) */
    if (!items_av || av_len(items_av) < 0) {
        AV *empty = newAV();
        ENTER; SAVETMPS; PUSHMARK(SP);
        mXPUSHs(newSVpv("Future", 0));
        mXPUSHs(newRV_noinc((SV*)empty));
        PUTBACK;
        call_method("done", G_SCALAR);
        SPAGAIN;
        RETVAL = newSVsv(POPs);
        PUTBACK; FREETMPS; LEAVE;
    } else {
        /* Get instance attributes */
        {
            SV **svp = hv_fetch(self_hv, "concurrent", 10, 0);
            concurrent = svp ? SvIV(*svp) : 10;
        }
        {
            SV **svp = hv_fetch(self_hv, "fail_fast", 9, 0);
            fail_fast = svp ? SvIV(*svp) : 0;
        }
        {
            SV **svp = hv_fetch(self_hv, "on_progress", 11, 0);
            on_progress = (svp && SvOK(*svp)) ? *svp : NULL;
        }
        {
            SV **svp = hv_fetch(self_hv, "loop", 4, 0);
            loop_sv = (svp && SvOK(*svp)) ? *svp : NULL;
        }
        
        total = av_len(items_av) + 1;
        
        /* Allocate BatchState */
        Newxz(state, 1, BatchState);
        state->items = (AV*)SvREFCNT_inc((SV*)items_av);
        state->concurrent = concurrent;
        state->fail_fast = fail_fast ? TRUE : FALSE;
        state->total = total;
        state->in_flight = 0;
        state->finished = 0;
        state->aborted = FALSE;
        
        /* Create results array */
        state->results = newAV();
        av_extend(state->results, total - 1);
        for (i = 0; i < total; i++) {
            av_push(state->results, newSV(0));
        }
        
        /* Create queue */
        state->queue = newAV();
        av_extend(state->queue, total - 1);
        for (i = 0; i < total; i++) {
            av_push(state->queue, newSViv(i));
        }
        
        /* Create errors array */
        state->errors = newAV();
        
        /* Store callbacks */
        if (worker && SvOK(worker)) {
            state->worker = newSVsv(worker);
        }
        if (on_progress && SvOK(on_progress)) {
            state->on_progress = newSVsv(on_progress);
        }
        if (loop_sv && SvOK(loop_sv)) {
            state->loop = newSVsv(loop_sv);
        }
        
        /* Create result Future */
        ENTER; SAVETMPS; PUSHMARK(SP);
        mXPUSHs(newSVpv("Future", 0));
        PUTBACK;
        call_method("new", G_SCALAR);
        SPAGAIN;
        state->result_future = newSVsv(POPs);
        PUTBACK; FREETMPS; LEAVE;
        
        /* Create state object */
        state_sv = new_state_sv(aTHX_ state);
        
        /* Run the batch - fully in XS! */
        run_loop(aTHX_ state_sv);
        
        RETVAL = newSVsv(state->result_future);
        /* Don't dec state_sv - callbacks hold copies that keep it alive */
        /* It will be freed when all callbacks complete and are GC'd */
    }
OUTPUT:
    RETVAL

SV *
batch(...)
PREINIT:
    dSP;
    SV *obj;
    IV concurrent = 10;
    IV fail_fast = 0;
    SV *on_progress = &PL_sv_undef;
    SV *loop_sv = &PL_sv_undef;
    AV *items_av = NULL;
    SV *worker = NULL;
    IV i;
CODE:
    for (i = 0; i < items; i += 2) {
        if (i + 1 < items) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            if (strEQ(key, "concurrent") && SvOK(val)) {
                concurrent = SvIV(val);
            } else if (strEQ(key, "fail_fast") && SvOK(val)) {
                fail_fast = SvTRUE(val) ? 1 : 0;
            } else if (strEQ(key, "on_progress") && SvOK(val)) {
                on_progress = val;
            } else if (strEQ(key, "loop") && SvOK(val)) {
                loop_sv = val;
            } else if (strEQ(key, "items") && SvROK(val)) {
                items_av = (AV*)SvRV(val);
            } else if (strEQ(key, "worker") && SvROK(val)) {
                worker = val;
            }
        }
    }
    
    ENTER; SAVETMPS; PUSHMARK(SP);
    mXPUSHs(newSVpv("Future::Batch::XS", 0));
    mXPUSHs(newSVpv("concurrent", 0));
    mXPUSHi(concurrent);
    mXPUSHs(newSVpv("fail_fast", 0));
    mXPUSHi(fail_fast);
    mXPUSHs(newSVpv("on_progress", 0));
    XPUSHs(on_progress);
    mXPUSHs(newSVpv("loop", 0));
    XPUSHs(loop_sv);
    PUTBACK;
    call_method("new", G_SCALAR);
    SPAGAIN;
    obj = newSVsv(POPs);
    PUTBACK; FREETMPS; LEAVE;
    
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(obj);
    mXPUSHs(newSVpv("items", 0));
    if (items_av) {
        XPUSHs(sv_2mortal(newRV_inc((SV*)items_av)));
    } else {
        AV *empty = newAV();
        XPUSHs(sv_2mortal(newRV_noinc((SV*)empty)));
    }
    mXPUSHs(newSVpv("worker", 0));
    if (worker) {
        XPUSHs(worker);
    } else {
        XPUSHs(&PL_sv_undef);
    }
    PUTBACK;
    call_method("run", G_SCALAR);
    SPAGAIN;
    RETVAL = newSVsv(POPs);
    PUTBACK; FREETMPS; LEAVE;
    
    SvREFCNT_dec(obj);
OUTPUT:
    RETVAL


IV
_min(a, b)
    IV a
    IV b
CODE:
    RETVAL = a < b ? a : b;
OUTPUT:
    RETVAL

void
_presize_array(av, size)
    AV *av
    IV size
CODE:
    av_extend(av, size - 1);
    while (av_len(av) < size - 1) {
        av_push(av, newSV(0));
    }

void
_set_result(av, idx, value)
    AV *av
    IV idx
    SV *value
CODE:
    if (idx <= av_len(av)) {
        SvREFCNT_dec(AvARRAY(av)[idx]);
        AvARRAY(av)[idx] = newSVsv(value);
    }

bool
_is_future(sv)
    SV *sv
CODE:
    RETVAL = is_future(aTHX_ sv);
OUTPUT:
    RETVAL

IV
_shift_queue(av)
    AV *av
CODE:
    if (av_len(av) >= 0) {
        SV *sv = av_shift(av);
        RETVAL = SvIV(sv);
        SvREFCNT_dec(sv);
    } else {
        RETVAL = -1;
    }
OUTPUT:
    RETVAL

void
_build_queue(av, n)
    AV *av
    IV n
CODE:
    IV i;
    av_clear(av);
    av_extend(av, n - 1);
    for (i = 0; i < n; i++) {
        av_push(av, newSViv(i));
    }

IV
_queue_len(av)
    AV *av
CODE:
    RETVAL = av_len(av) + 1;
OUTPUT:
    RETVAL

MODULE = Future::Batch::XS    PACKAGE = Future::Batch::XS::State

# Minimal accessors for State object (mainly for debugging/introspection)

SV *
items(self)
    SV *self
CODE:
    BatchState *state = get_state(aTHX_ self);
    RETVAL = state ? newRV_inc((SV*)state->items) : &PL_sv_undef;
OUTPUT:
    RETVAL

SV *
results(self)
    SV *self
CODE:
    BatchState *state = get_state(aTHX_ self);
    RETVAL = state ? newRV_inc((SV*)state->results) : &PL_sv_undef;
OUTPUT:
    RETVAL

IV
total(self)
    SV *self
CODE:
    BatchState *state = get_state(aTHX_ self);
    RETVAL = state ? state->total : 0;
OUTPUT:
    RETVAL

IV
finished(self)
    SV *self
CODE:
    BatchState *state = get_state(aTHX_ self);
    RETVAL = state ? state->finished : 0;
OUTPUT:
    RETVAL

IV
in_flight(self)
    SV *self
CODE:
    BatchState *state = get_state(aTHX_ self);
    RETVAL = state ? state->in_flight : 0;
OUTPUT:
    RETVAL

bool
aborted(self)
    SV *self
CODE:
    BatchState *state = get_state(aTHX_ self);
    RETVAL = state ? state->aborted : FALSE;
OUTPUT:
    RETVAL
