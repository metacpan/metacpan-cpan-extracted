#include "stream_internal.h"

static void
les_call_stream_method(pTHX_ les_xsstate_t *st, const char *method)
{
    dSP;

    if (!st || !st->stream_sv)
        return;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(st->stream_sv);
    PUTBACK;
    call_method(method, G_DISCARD | G_VOID);
    FREETMPS;
    LEAVE;
}

static int
les_consumer_host_resume(pTHX_ void *host_context)
{
    return les_consumer_resume(aTHX_ (les_xsstate_t *)host_context);
}

static int
les_consumer_host_pause(pTHX_ void *host_context)
{
    les_xsstate_t *st = (les_xsstate_t *)host_context;

    if (!st || !st->consumer_ops || !st->consumer_context
        || st->consumer_terminal || st->closed || st->read_eof)
        return 0;
    if (!st->consumer_paused) {
        st->consumer_paused = 1;
        LES_STAT(st, consumer_pause_count)++;
        les_consumer_notify_paused(aTHX_ st);
    }
    return 1;
}

static SV *
les_consumer_host_stream(pTHX_ void *host_context)
{
    les_xsstate_t *st = (les_xsstate_t *)host_context;
    return st && st->stream_sv ? st->stream_sv : &PL_sv_undef;
}

static int
les_consumer_host_is_closed(pTHX_ void *host_context)
{
    les_xsstate_t *st = (les_xsstate_t *)host_context;
    return !st || st->closed || st->destroy_pending ? 1 : 0;
}

static int
les_consumer_host_retain(pTHX_ void *host_context)
{
    les_xsstate_t *st = (les_xsstate_t *)host_context;
    PERL_UNUSED_CONTEXT;

    if (!st || st->destroy_pending)
        return 0;
    if (st->consumer_host_retain_count == (UV)-1)
        croak("native Stream consumer host retain count overflow");
    st->consumer_host_retain_count++;
    return 1;
}

static void
les_consumer_host_release(pTHX_ void *host_context)
{
    les_xsstate_t *st = (les_xsstate_t *)host_context;

    if (!st || !st->consumer_host_retain_count)
        croak("unbalanced native Stream consumer host release");
    st->consumer_host_retain_count--;
    if (!st->consumer_host_retain_count && st->destroy_pending)
        les_state_destroy(aTHX_ st);
}

static const les_consumer_host_api_v1_t les_consumer_host_v1 = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_host_api_v1_t),
    les_consumer_host_resume,
    les_consumer_host_pause,
    les_consumer_host_stream,
    les_consumer_host_is_closed,
    les_consumer_host_retain,
    les_consumer_host_release
};

int
les_consumer_create(pTHX_ les_xsstate_t *st)
{
    if (!st || !st->descriptor)
        return 1;

    /* The immutable descriptor is the construction template. Copy the
     * effective operating defaults into connection-local state exactly once;
     * ordinary I/O reads only these fields afterward. */
    st->read_size = st->descriptor->read_size;
    st->read_budget_bytes = st->descriptor->read_budget_bytes;
    st->read_batch_bytes = st->descriptor->read_batch_bytes;
    st->message_batch_size = st->descriptor->message_batch_size;
    st->high_watermark = st->descriptor->high_watermark;
    st->low_watermark = st->descriptor->low_watermark;
    st->max_pending_bytes = st->descriptor->max_pending_bytes;
    st->max_buffer = st->descriptor->max_buffer;

    if (!st->descriptor->consumer_ops)
        return 1;

    st->consumer_ops = st->descriptor->consumer_ops;
    st->consumer_context = st->consumer_ops->create(aTHX_
        &les_consumer_host_v1, st, st->stream_sv);
    if (!st->consumer_context) {
        st->consumer_ops = NULL;
        return 0;
    }
    st->consumer_paused =
        (st->consumer_ops->flags & LES_CONSUMER_F_START_PAUSED) ? 1 : 0;
    return 1;
}

void
les_consumer_destroy(pTHX_ les_xsstate_t *st)
{
    const les_consumer_ops_v1_t *ops;
    void *context;

    if (!st || !st->consumer_ops || !st->consumer_context)
        return;
    ops = st->consumer_ops;
    context = st->consumer_context;
    st->consumer_ops = NULL;
    st->consumer_context = NULL;
    ops->destroy(aTHX_ context);
}

void
les_consumer_notify_paused(pTHX_ les_xsstate_t *st)
{
    if (st && !st->closed && st->consumer_paused)
        les_call_stream_method(aTHX_ st, "_xs_consumer_paused");
}

static int
les_consumer_validate_status(pTHX_ les_xsstate_t *st, int status,
    const char *operation)
{
    if (status < LES_CONSUMER_CONTINUE || status > LES_CONSUMER_ERROR) {
        if (operation)
            croak("native Stream consumer '%s' returned invalid status %d from %s",
                st->consumer_ops->name, status, operation);
        croak("native Stream consumer '%s' returned invalid status %d",
            st->consumer_ops->name, status);
    }
    if (status == LES_CONSUMER_ERROR) {
        if (operation)
            croak("native Stream consumer '%s' reported an error from %s",
                st->consumer_ops->name, operation);
        croak("native Stream consumer '%s' reported an error",
            st->consumer_ops->name);
    }
    return status;
}

static int
les_consumer_apply_status(pTHX_ les_xsstate_t *st, int status,
    int resume_on_continue)
{
    if (status == LES_CONSUMER_CONTINUE) {
        if (resume_on_continue && st->consumer_paused) {
            st->consumer_paused = 0;
            LES_STAT(st, consumer_resume_count)++;
            les_call_stream_method(aTHX_ st, "_xs_consumer_resumed");
        }
        return status;
    }
    if (status == LES_CONSUMER_PAUSE) {
        if (!st->consumer_paused) {
            st->consumer_paused = 1;
            LES_STAT(st, consumer_pause_count)++;
            les_consumer_notify_paused(aTHX_ st);
        }
        return status;
    }
    if (status == LES_CONSUMER_CLOSE) {
        les_call_stream_method(aTHX_ st, "_xs_consumer_close");
        return status;
    }
    croak("internal native Stream consumer status was not validated");
    return LES_CONSUMER_ERROR;
}

int
les_consumer_message(pTHX_ les_xsstate_t *st, SV *message)
{
    int status;
    int jump_status;
    dJMPENV;

    if (!st || !st->consumer_ops || !st->consumer_context)
        croak("native Stream consumer is not attached");
    LES_STAT(st, consumer_message_calls)++;
    st->consumer_flush_pending = 1;
    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        status = st->consumer_ops->message(aTHX_ st->consumer_context, message);
        JMPENV_POP;
    } else {
        st->consumer_flush_pending = 0;
        JMPENV_POP;
        JMPENV_JUMP(jump_status);
    }
    les_consumer_validate_status(aTHX_ st, status, NULL);
    if (st->closed || st->read_eof || st->consumer_terminal)
        return status;
    return les_consumer_apply_status(aTHX_ st, status, 0);
}

static int
les_consumer_call_pending_flush(pTHX_ les_xsstate_t *st, int terminal)
{
    int status;

    if (!st || !st->consumer_ops || !st->consumer_context
        || !st->consumer_flush_pending || st->consumer_terminal)
        return LES_CONSUMER_CONTINUE;
    if (!terminal && (st->closed || st->read_eof))
        return LES_CONSUMER_CONTINUE;
    st->consumer_flush_pending = 0;
    if (!(st->consumer_ops->flags & LES_CONSUMER_F_WANT_FLUSH))
        return LES_CONSUMER_CONTINUE;
    LES_STAT(st, consumer_flush_calls)++;
    status = st->consumer_ops->flush(aTHX_ st->consumer_context);
    les_consumer_validate_status(aTHX_ st, status,
        terminal ? "terminal flush" : "flush");
    if (terminal || st->closed || st->read_eof || st->consumer_terminal)
        return status;
    return les_consumer_apply_status(aTHX_ st, status, 1);
}

int
les_consumer_flush(pTHX_ les_xsstate_t *st)
{
    return les_consumer_call_pending_flush(aTHX_ st, 0);
}

int
les_consumer_flush_terminal(pTHX_ les_xsstate_t *st)
{
    return les_consumer_call_pending_flush(aTHX_ st, 1);
}

int
les_consumer_resumed_with_buffered_input(const les_xsstate_t *st,
    int was_consumer_paused)
{
    return was_consumer_paused && st && !LES_INPUT_PAUSED(st)
        && !st->closed && !st->read_eof && st->input_len;
}

void
les_consumer_event(pTHX_ les_xsstate_t *st, uint32_t event, int error,
    const char *message)
{
    if (!st || !st->consumer_ops || !st->consumer_context
        || st->consumer_terminal)
        return;
    st->consumer_terminal = 1;
    LES_STAT(st, consumer_event_calls)++;
    st->consumer_ops->event(aTHX_ st->consumer_context, event, error,
        message ? message : "");
}

int
les_consumer_resume(pTHX_ les_xsstate_t *st)
{
    if (!st || !st->consumer_ops || !st->consumer_context
        || st->consumer_terminal || st->closed || st->read_eof)
        return 0;

    if (st->consumer_paused) {
        st->consumer_paused = 0;
        LES_STAT(st, consumer_resume_count)++;
    }

    if (!st->read_paused && st->input_dispatch_depth == 0 && st->input_len) {
        ENTER;
        SAVEINT(st->input_dispatch_depth);
        st->input_dispatch_depth++;
        les_process_existing_input(aTHX_ st, 1);
        LEAVE;
    }

    if (!LES_INPUT_PAUSED(st) && !st->closed && !st->read_eof)
        les_call_stream_method(aTHX_ st, "_xs_consumer_resumed");
    return !LES_INPUT_PAUSED(st) && !st->closed && !st->read_eof;
}
