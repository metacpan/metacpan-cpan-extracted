#include "stream_internal.h"

/* Private conformance provider used only by the core regression suite. It
 * exercises the same exported table an independent XS distribution supplies. */
typedef struct les_test_consumer_s {
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    AV *messages;
    AV *events;
    AV *trace;
    SV *ready_cb;
    UV permits;
    UV delivered;
    UV flushes;
    UV sequence;
    UV last_flush_sequence;
    UV last_event_sequence;
} les_test_consumer_t;

static UV les_test_destroyed = 0;
static UV les_test_last_destroy_flushes = 0;

static void *
les_test_create(pTHX_ const les_consumer_host_api_v1_t *host,
    void *host_context, SV *stream)
{
    les_test_consumer_t *context;
    PERL_UNUSED_ARG(stream);

    Newxz(context, 1, les_test_consumer_t);
    context->host = host;
    context->host_context = host_context;
    context->messages = newAV();
    context->events = newAV();
    context->trace = newAV();
    return context;
}

static void *
les_test_create_failure(pTHX_ const les_consumer_host_api_v1_t *host,
    void *host_context, SV *stream)
{
    PERL_UNUSED_ARG(host);
    PERL_UNUSED_ARG(host_context);
    PERL_UNUSED_ARG(stream);
    PERL_UNUSED_CONTEXT;
    return NULL;
}

static int
les_test_message(pTHX_ void *opaque, SV *message)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    SV *callback;
    dSP;

    if (!context->permits)
        return LES_CONSUMER_ERROR;
    context->permits--;
    context->delivered++;
    av_push(context->messages, newSVsv(message));

    callback = context->ready_cb;
    context->ready_cb = NULL;
    if (callback) {
        ENTER;
        SAVETMPS;
        SAVEFREESV(callback);
        PUSHMARK(SP);
        PUTBACK;
        call_sv(callback, G_DISCARD | G_VOID);
        FREETMPS;
        LEAVE;
    }
    return context->permits ? LES_CONSUMER_CONTINUE : LES_CONSUMER_PAUSE;
}

static int
les_test_input(pTHX_ void *opaque, const char *data, size_t length,
    size_t *consumed)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    SV *callback;
    size_t index;
    dSP;

    if (!context->permits)
        return LES_CONSUMER_ERROR;
    *consumed = 0;
    for (index = 0; index < length; index++) {
        if (data[index] != '\n')
            continue;
        context->permits--;
        context->delivered++;
        av_push(context->messages, newSVpvn(data, (STRLEN)index));
        *consumed = index + 1;

        callback = context->ready_cb;
        context->ready_cb = NULL;
        if (callback) {
            ENTER;
            SAVETMPS;
            SAVEFREESV(callback);
            PUSHMARK(SP);
            PUTBACK;
            call_sv(callback, G_DISCARD | G_VOID);
            FREETMPS;
            LEAVE;
        }
        return context->permits
            ? LES_CONSUMER_CONTINUE : LES_CONSUMER_PAUSE;
    }
    return LES_CONSUMER_CONTINUE;
}

static int
les_test_input_transition_target(pTHX_ void *opaque, const char *data,
    size_t length, size_t *consumed)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    size_t index;
    PERL_UNUSED_CONTEXT;

    *consumed = 0;
    for (index = 0; index < length; index++) {
        if (data[index] != '\n')
            continue;
        context->delivered++;
        av_push(context->messages, newSVpvn(data, (STRLEN)index));
        *consumed = index + 1;
        return LES_CONSUMER_CONTINUE;
    }
    return LES_CONSUMER_CONTINUE;
}

static int
les_test_message_pause(pTHX_ void *opaque, SV *message)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    PERL_UNUSED_CONTEXT;
    context->delivered++;
    av_push(context->messages, newSVsv(message));
    return LES_CONSUMER_PAUSE;
}

static int
les_test_message_croak(pTHX_ void *opaque, SV *message)
{
    PERL_UNUSED_ARG(opaque);
    PERL_UNUSED_ARG(message);
    croak("synthetic consumer message exception");
    return LES_CONSUMER_ERROR;
}

static int
les_test_message_continue(pTHX_ void *opaque, SV *message)
{
    les_test_message(aTHX_ opaque, message);
    return LES_CONSUMER_CONTINUE;
}

static int
les_test_message_invalid(pTHX_ void *opaque, SV *message)
{
    les_test_message(aTHX_ opaque, message);
    return 99;
}

static int
les_test_message_transition(pTHX_ void *opaque, SV *message)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    SV *callback;
    SV *entry;
    dSP;

    context->delivered++;
    av_push(context->messages, newSVsv(message));
    entry = newSVpvs("message:");
    sv_catsv(entry, message);
    av_push(context->trace, entry);

    callback = context->ready_cb;
    context->ready_cb = NULL;
    if (callback) {
        ENTER;
        SAVETMPS;
        SAVEFREESV(callback);
        PUSHMARK(SP);
        PUTBACK;
        call_sv(callback, G_DISCARD | G_VOID);
        FREETMPS;
        LEAVE;
    }
    return LES_CONSUMER_CONTINUE;
}

static void
les_test_event(pTHX_ void *opaque, uint32_t event, int error,
    const char *message)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    AV *row = newAV();
    SV *callback;
    dSP;

    context->last_event_sequence = ++context->sequence;
    av_push(row, newSVuv((UV)event));
    av_push(row, newSViv((IV)error));
    av_push(row, newSVpv(message ? message : "", 0));
    av_push(context->events, newRV_noinc((SV *)row));
    context->permits = 0;
    callback = context->ready_cb;
    context->ready_cb = NULL;
    if (callback) {
        ENTER;
        SAVETMPS;
        SAVEFREESV(callback);
        PUSHMARK(SP);
        PUTBACK;
        call_sv(callback, G_DISCARD | G_VOID);
        FREETMPS;
        LEAVE;
    }
}

static void
les_test_event_croak(pTHX_ void *opaque, uint32_t event, int error,
    const char *message)
{
    PERL_UNUSED_ARG(opaque);
    PERL_UNUSED_ARG(event);
    PERL_UNUSED_ARG(error);
    PERL_UNUSED_ARG(message);
    croak("synthetic consumer event exception");
}

static int
les_test_flush(pTHX_ void *opaque)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    PERL_UNUSED_CONTEXT;

    context->flushes++;
    context->last_flush_sequence = ++context->sequence;
    av_push(context->trace, newSVpvs("flush"));
    return context->permits ? LES_CONSUMER_CONTINUE : LES_CONSUMER_PAUSE;
}

static int
les_test_flush_continue(pTHX_ void *opaque)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    PERL_UNUSED_CONTEXT;
    context->flushes++;
    context->last_flush_sequence = ++context->sequence;
    av_push(context->trace, newSVpvs("flush"));
    return LES_CONSUMER_CONTINUE;
}

static int
les_test_flush_error(pTHX_ void *opaque)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    PERL_UNUSED_CONTEXT;
    context->flushes++;
    context->last_flush_sequence = ++context->sequence;
    av_push(context->trace, newSVpvs("flush"));
    return LES_CONSUMER_ERROR;
}

static int
les_test_flush_close(pTHX_ void *opaque)
{
    les_test_flush(aTHX_ opaque);
    return LES_CONSUMER_CLOSE;
}

static void
les_test_destroy(pTHX_ void *opaque)
{
    les_test_consumer_t *context = (les_test_consumer_t *)opaque;
    PERL_UNUSED_CONTEXT;

    if (!context)
        return;
    if (context->ready_cb)
        SvREFCNT_dec(context->ready_cb);
    SvREFCNT_dec((SV *)context->messages);
    SvREFCNT_dec((SV *)context->events);
    SvREFCNT_dec((SV *)context->trace);
    les_test_last_destroy_flushes = context->flushes;
    Safefree(context);
    les_test_destroyed++;
}

static const les_consumer_ops_v1_t les_test_raw_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "raw-input test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH
        | LES_CONSUMER_F_RAW_INPUT,
    les_test_create,
    NULL,
    les_test_event,
    les_test_destroy,
    les_test_flush,
    les_test_input
};

static const les_consumer_ops_v1_t les_test_raw_transition_target_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "raw-input transition target test consumer",
    LES_CONSUMER_F_WANT_FLUSH | LES_CONSUMER_F_RAW_INPUT,
    les_test_create,
    NULL,
    les_test_event,
    les_test_destroy,
    les_test_flush_continue,
    les_test_input_transition_target
};

static const les_consumer_ops_v1_t les_test_raw_missing_input_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "raw-input missing-input test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_RAW_INPUT,
    les_test_create,
    NULL,
    les_test_event,
    les_test_destroy,
    NULL,
    NULL
};

static const les_consumer_ops_v1_t les_test_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "Linux::Event core test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message,
    les_test_event,
    les_test_destroy,
    les_test_flush
};

static const les_consumer_ops_v1_t les_test_flush_continue_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "flush-continue test consumer",
    LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message_pause,
    les_test_event,
    les_test_destroy,
    les_test_flush_continue
};

static const les_consumer_ops_v1_t les_test_croak_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "croaking test consumer",
    LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message_croak,
    les_test_event,
    les_test_destroy,
    les_test_flush
};

static const les_consumer_ops_v1_t les_test_message_continue_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "message-continue test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message_continue,
    les_test_event,
    les_test_destroy,
    les_test_flush
};

static const les_consumer_ops_v1_t les_test_message_invalid_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "message-invalid test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message_invalid,
    les_test_event,
    les_test_destroy,
    les_test_flush
};

static const les_consumer_ops_v1_t les_test_event_croak_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "event-croak test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message,
    les_test_event_croak,
    les_test_destroy,
    les_test_flush
};

static const les_consumer_ops_v1_t les_test_flush_error_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "flush-error test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message,
    les_test_event,
    les_test_destroy,
    les_test_flush_error
};

static const les_consumer_ops_v1_t les_test_flush_close_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "flush-close test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message,
    les_test_event,
    les_test_destroy,
    les_test_flush_close
};

static const les_consumer_ops_v1_t les_test_transition_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "transition trace test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message_transition,
    les_test_event,
    les_test_destroy,
    les_test_flush_continue
};

/* The original ABI v1 ended at destroy. Keep a provider with that exact
 * layout in the conformance suite so appended optional fields cannot make old
 * external providers fail validation or be read past struct_size. */
typedef struct les_test_original_ops_v1_s {
    uint32_t abi_version;
    size_t struct_size;
    const char *name;
    uint32_t flags;
    void *(*create)(pTHX_ const les_consumer_host_api_v1_t *host,
        void *host_context, SV *stream);
    int (*message)(pTHX_ void *context, SV *message);
    void (*event)(pTHX_ void *context, uint32_t event, int error,
        const char *message);
    void (*destroy)(pTHX_ void *context);
} les_test_original_ops_v1_t;

static const les_test_original_ops_v1_t les_test_original_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_test_original_ops_v1_t),
    "original-layout ABI v1 test consumer",
    LES_CONSUMER_F_START_PAUSED,
    les_test_create,
    les_test_message,
    les_test_event,
    les_test_destroy
};

static const les_consumer_ops_v1_t les_test_incomplete_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "incomplete test consumer",
    LES_CONSUMER_F_START_PAUSED,
    les_test_create,
    NULL,
    les_test_event,
    les_test_destroy,
    NULL
};

static const les_consumer_ops_v1_t les_test_wrong_version_ops = {
    LES_CONSUMER_ABI_VERSION + 1,
    sizeof(les_consumer_ops_v1_t),
    "wrong-version test consumer",
    LES_CONSUMER_F_START_PAUSED,
    les_test_create,
    les_test_message,
    les_test_event,
    les_test_destroy,
    NULL
};

static const les_consumer_ops_v1_t les_test_missing_flush_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "missing-flush test consumer",
    LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH,
    les_test_create,
    les_test_message,
    les_test_event,
    les_test_destroy,
    NULL
};

static const les_consumer_ops_v1_t les_test_unknown_flags_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "unknown-flags test consumer",
    LES_CONSUMER_F_START_PAUSED | 0x80000000U,
    les_test_create,
    les_test_message,
    les_test_event,
    les_test_destroy,
    NULL
};

static const les_consumer_ops_v1_t les_test_create_failure_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "create-failure test consumer",
    LES_CONSUMER_F_START_PAUSED,
    les_test_create_failure,
    les_test_message,
    les_test_event,
    les_test_destroy,
    NULL
};

static les_test_consumer_t *
les_test_context(les_xsstate_t *st)
{
    if (!st || (st->consumer_ops != &les_test_ops
        && st->consumer_ops != &les_test_raw_ops
        && st->consumer_ops != &les_test_raw_transition_target_ops
        && st->consumer_ops != &les_test_flush_continue_ops
        && st->consumer_ops != &les_test_croak_ops
        && st->consumer_ops != &les_test_message_continue_ops
        && st->consumer_ops != &les_test_message_invalid_ops
        && st->consumer_ops != &les_test_event_croak_ops
        && st->consumer_ops != &les_test_flush_error_ops
        && st->consumer_ops != &les_test_flush_close_ops
        && st->consumer_ops != &les_test_transition_ops
        && st->consumer_ops != (const les_consumer_ops_v1_t *)
            &les_test_original_ops) || !st->consumer_context)
        croak("Stream does not use the Linux::Event core test consumer");
    return (les_test_consumer_t *)st->consumer_context;
}

SV *
les_test_consumer_definition(pTHX_ const char *variant)
{
    const les_consumer_ops_v1_t *ops = &les_test_ops;
    UV declared_version = LES_CONSUMER_ABI_VERSION;
    HV *definition = newHV();

    if (strEQ(variant, "raw-input"))
        ops = &les_test_raw_ops;
    else if (strEQ(variant, "raw-transition-target"))
        ops = &les_test_raw_transition_target_ops;
    else if (strEQ(variant, "raw-missing-input"))
        ops = &les_test_raw_missing_input_ops;
    else if (strEQ(variant, "incomplete"))
        ops = &les_test_incomplete_ops;
    else if (strEQ(variant, "original-v1"))
        ops = (const les_consumer_ops_v1_t *)&les_test_original_ops;
    else if (strEQ(variant, "wrong-table-version"))
        ops = &les_test_wrong_version_ops;
    else if (strEQ(variant, "missing-flush"))
        ops = &les_test_missing_flush_ops;
    else if (strEQ(variant, "unknown-flags"))
        ops = &les_test_unknown_flags_ops;
    else if (strEQ(variant, "create-failure"))
        ops = &les_test_create_failure_ops;
    else if (strEQ(variant, "flush-continue"))
        ops = &les_test_flush_continue_ops;
    else if (strEQ(variant, "message-croak"))
        ops = &les_test_croak_ops;
    else if (strEQ(variant, "message-continue"))
        ops = &les_test_message_continue_ops;
    else if (strEQ(variant, "message-invalid"))
        ops = &les_test_message_invalid_ops;
    else if (strEQ(variant, "event-croak"))
        ops = &les_test_event_croak_ops;
    else if (strEQ(variant, "flush-error"))
        ops = &les_test_flush_error_ops;
    else if (strEQ(variant, "flush-close"))
        ops = &les_test_flush_close_ops;
    else if (strEQ(variant, "transition-trace"))
        ops = &les_test_transition_ops;
    else if (strEQ(variant, "wrong-declaration-version"))
        declared_version++;
    else if (!strEQ(variant, "valid"))
        croak("unknown test consumer definition variant '%s'", variant);

    hv_stores(definition, "provider", newSVpvs("Linux::Event core test consumer"));
    hv_stores(definition, "abi_version", newSVuv(declared_version));
    hv_stores(definition, "operations_address", newSVuv(PTR2UV(ops)));
    return newRV_noinc((SV *)definition);
}

void
les_test_consumer_arm(pTHX_ les_xsstate_t *st, SV *callback)
{
    les_test_consumer_t *context = les_test_context(st);

    if (context->permits || context->ready_cb)
        croak("test consumer already has an armed receive");
    context->permits = 1;
    if (callback && SvOK(callback))
        context->ready_cb = les_store_cb(callback, "test consumer callback");
    context->host->resume(aTHX_ context->host_context);
}

int
les_test_consumer_external_arm(pTHX_ SV *stream, SV *callback)
{
    HV *stream_hv;
    SV **state_slot;
    les_xsstate_t *st;
    les_test_consumer_t *context;
    int resumed;
    int observed_after_resume;

    if (!SvROK(stream) || SvTYPE(SvRV(stream)) != SVt_PVHV)
        croak("test consumer external arm requires a hash-based Stream");
    stream_hv = (HV *)SvRV(stream);
    state_slot = hv_fetchs(stream_hv, "xs_state", 0);
    if (!state_slot || !SvOK(*state_slot))
        croak("test consumer external arm requires live native state");
    st = les_state_from_sv(*state_slot);
    context = les_test_context(st);
    if (context->permits || context->ready_cb)
        croak("test consumer already has an armed receive");
    if (context->host->struct_size
        < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !context->host->retain || !context->host->release)
        croak("test consumer host lifetime extension is unavailable");

    context->permits = 1;
    if (callback && SvOK(callback))
        context->ready_cb = les_store_cb(callback, "test consumer callback");
    if (!context->host->retain(aTHX_ context->host_context))
        croak("test consumer could not retain host lifetime");
    resumed = context->host->resume(aTHX_ context->host_context);
    observed_after_resume = context->delivered > 0
        && context->host->is_closed(aTHX_ context->host_context);
    context->host->release(aTHX_ context->host_context);
    return resumed >= 0 && observed_after_resume;
}

SV *
les_test_consumer_transition_retain(pTHX_ SV *stream, SV *callback)
{
    HV *stream_hv;
    SV **state_slot;
    les_xsstate_t *st;
    les_test_consumer_t *context;
    AV *result;
    UV destroyed_before;
    int resume_result;
    int pause_result;
    int retain_result;
    dSP;

    if (!SvROK(stream) || SvTYPE(SvRV(stream)) != SVt_PVHV)
        croak("test consumer transition retain requires a hash-based Stream");
    if (!callback || !SvOK(callback) || !SvROK(callback)
        || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("test consumer transition retain requires a callback");

    stream_hv = (HV *)SvRV(stream);
    state_slot = hv_fetchs(stream_hv, "xs_state", 0);
    if (!state_slot || !SvOK(*state_slot))
        croak("test consumer transition retain requires live native state");
    st = les_state_from_sv(*state_slot);
    context = les_test_context(st);
    if (context->host->struct_size
        < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !context->host->retain || !context->host->release)
        croak("test consumer host lifetime extension is unavailable");
    if (!context->host->retain(aTHX_ context->host_context))
        croak("test consumer could not retain host lifetime");

    destroyed_before = les_test_destroyed;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    call_sv(callback, G_DISCARD | G_VOID);
    FREETMPS;
    LEAVE;

    resume_result = context->host->resume(aTHX_ context->host_context);
    pause_result = context->host->pause(aTHX_ context->host_context);
    retain_result = context->host->retain(aTHX_ context->host_context);

    result = newAV();
    av_push(result, newSViv(resume_result));
    av_push(result, newSViv(pause_result));
    av_push(result, newSViv(retain_result));
    av_push(result, newSViv(les_test_destroyed == destroyed_before ? 1 : 0));

    context->host->release(aTHX_ context->host_context);
    return newRV_noinc((SV *)result);
}

void
les_test_consumer_cancel(pTHX_ les_xsstate_t *st)
{
    les_test_consumer_t *context = les_test_context(st);

    context->permits = 0;
    if (context->ready_cb) {
        SvREFCNT_dec(context->ready_cb);
        context->ready_cb = NULL;
    }
    context->host->pause(aTHX_ context->host_context);
}

SV *
les_test_consumer_take(pTHX_ les_xsstate_t *st)
{
    les_test_consumer_t *context = les_test_context(st);
    SV *message = av_shift(context->messages);
    PERL_UNUSED_CONTEXT;
    return message ? message : newSV(0);
}

SV *
les_test_consumer_events(pTHX_ les_xsstate_t *st)
{
    les_test_consumer_t *context = les_test_context(st);
    AV *copy = newAV();
    SSize_t index;

    for (index = 0; index <= av_top_index(context->events); index++) {
        SV **row = av_fetch(context->events, index, 0);
        if (row)
            av_push(copy, newSVsv(*row));
    }
    return newRV_noinc((SV *)copy);
}

SV *
les_test_consumer_stats(pTHX_ les_xsstate_t *st)
{
    les_test_consumer_t *context = les_test_context(st);
    HV *stats = newHV();
    PERL_UNUSED_CONTEXT;

    hv_stores(stats, "permits", newSVuv(context->permits));
    hv_stores(stats, "queued_messages",
        newSVuv((UV)(av_top_index(context->messages) + 1)));
    hv_stores(stats, "delivered", newSVuv(context->delivered));
    hv_stores(stats, "flushes", newSVuv(context->flushes));
    hv_stores(stats, "last_flush_sequence",
        newSVuv(context->last_flush_sequence));
    hv_stores(stats, "last_event_sequence",
        newSVuv(context->last_event_sequence));
    return newRV_noinc((SV *)stats);
}

SV *
les_test_consumer_trace(pTHX_ les_xsstate_t *st)
{
    les_test_consumer_t *context = les_test_context(st);
    AV *copy = newAV();
    SSize_t index;

    for (index = 0; index <= av_top_index(context->trace); index++) {
        SV **entry = av_fetch(context->trace, index, 0);
        if (entry)
            av_push(copy, newSVsv(*entry));
    }
    return newRV_noinc((SV *)copy);
}

UV
les_test_consumer_destroy_count(void)
{
    return les_test_destroyed;
}

UV
les_test_consumer_last_destroy_flushes(void)
{
    return les_test_last_destroy_flushes;
}
