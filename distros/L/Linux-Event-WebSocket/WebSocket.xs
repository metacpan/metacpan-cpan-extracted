#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stream_consumer_abi.h"

#include <stdint.h>
#include <string.h>

#define BQWS_SINGLE_THREAD 1
#define BQWS_DEBUG 0
#define bqws_mutex int
#define bqws_mutex_init(m) ((void)(m))
#define bqws_mutex_free(m) ((void)(m))
#define bqws_mutex_lock(m) ((void)(m))
#define bqws_mutex_unlock(m) ((void)(m))
#define bqws_assert_locked(m) ((void)(m))
#include "vendor/bq_websocket/bq_websocket.c"

typedef struct {
    bqws_socket *ws;
} lews_bq;

static lews_bq *
lews_bq_create(const char *endpoint_type, UV max_message_size)
{
    lews_bq *state;
    bqws_opts opts;

    Newxz(state, 1, lews_bq);
    Zero(&opts, 1, bqws_opts);

    opts.skip_handshake = true;
    opts.recv_control_messages = true;
    opts.ping_interval = SIZE_MAX;
    opts.connect_timeout = SIZE_MAX;
    opts.close_timeout = SIZE_MAX;
    opts.ping_response_timeout = SIZE_MAX;
    opts.limits.max_memory_used = SIZE_MAX;
    opts.limits.max_recv_msg_size =
        (size_t)(max_message_size < 125 ? 125 : max_message_size);
    opts.limits.max_recv_queue_messages = SIZE_MAX;
    opts.limits.max_recv_queue_size = SIZE_MAX;
    opts.limits.max_partial_message_parts = SIZE_MAX;

    if (strEQ(endpoint_type, "client")) {
        state->ws = bqws_new_client(&opts, NULL);
    } else if (strEQ(endpoint_type, "server")) {
        state->ws = bqws_new_server(&opts, NULL);
    } else {
        Safefree(state);
        return NULL;
    }

    if (state->ws == NULL) {
        Safefree(state);
        return NULL;
    }

    return state;
}

static void
lews_bq_free(lews_bq *state)
{
    if (state == NULL)
        return;
    if (state->ws != NULL) {
        bqws_free_socket(state->ws);
        state->ws = NULL;
    }
    Safefree(state);
}

static SV *
lews_bq_new_object(
    const char *class,
    const char *endpoint_type,
    UV max_message_size
)
{
    lews_bq *state = lews_bq_create(endpoint_type, max_message_size);
    SV *object;

    if (state == NULL)
        return NULL;

    object = newSV(0);
    sv_setref_pv(object, class, (void *)state);
    return object;
}

static lews_bq *
lews_bq_from_sv(SV *self)
{
    lews_bq *state;

    if (!SvROK(self)) {
        croak("invalid Linux::Event::WebSocket::_BQ object");
    }

    state = INT2PTR(lews_bq *, SvIV((SV *)SvRV(self)));
    if (state == NULL || state->ws == NULL) {
        croak("invalid Linux::Event::WebSocket::_BQ state");
    }
    return state;
}

static SV *
lews_bq_flush(lews_bq *state)
{
    SV *out = newSVpvn("", 0);
    uint8_t buffer[65536];

    for (;;) {
        size_t n = bqws_write_to(state->ws, buffer, sizeof(buffer));
        if (n > 0) {
            sv_catpvn(out, (const char *)buffer, n);
        }
        if (n < sizeof(buffer)) {
            break;
        }
    }

    return out;
}


static SV *
lews_bq_payload_sv(IV opcode, const char *data, size_t size)
{
    const U8 *bytes = (const U8 *)(data == NULL ? "" : data);
    SV *payload = newSVpvn((const char *)bytes, size);

    if (opcode == 1) {
        const U8 *first_variant = NULL;

        if (!is_utf8_invariant_string_loc(bytes, (STRLEN)size, &first_variant)) {
            if (!is_utf8_string_flags(
                    bytes,
                    (STRLEN)size,
                    UTF8_DISALLOW_ILLEGAL_C9_INTERCHANGE
                )) {
                SvREFCNT_dec(payload);
                return NULL;
            }
            SvUTF8_on(payload);
        }
    }

    return payload;
}

static SV *
lews_bq_call_invalid_utf8(SV *target, SV *connection)
{
    SV *error = NULL;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(target);
    PUSHs(connection);
    PUTBACK;

    sv_setsv(ERRSV, &PL_sv_undef);
    call_method("_bq_invalid_utf8", G_DISCARD | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return error;
}

static SV *
lews_bq_call_event(
    SV *target,
    SV *connection,
    IV opcode,
    const char *data,
    size_t size,
    int *invalid_utf8
)
{
    SV *error = NULL;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 4);
    PUSHs(target);
    PUSHs(connection);
    {
        SV *payload = lews_bq_payload_sv(opcode, data, size);
        if (payload == NULL) {
            if (invalid_utf8 != NULL)
                *invalid_utf8 = 1;
            FREETMPS;
            LEAVE;
            return lews_bq_call_invalid_utf8(target, connection);
        }
        PUSHs(sv_2mortal(newSViv(opcode)));
        PUSHs(sv_2mortal(payload));
    }
    PUTBACK;

    sv_setsv(ERRSV, &PL_sv_undef);
    call_method("_bq_event", G_DISCARD | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return error;
}


typedef struct {
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    SV *stream;
    SV *native;
    SV *engine;
    lews_bq *bq;
} lews_raw_consumer;

static int
lews_raw_stream_config(
    pTHX_
    SV *stream,
    char endpoint_type[7],
    UV *max_message_size
)
{
    int count;
    SV *config;
    AV *values;
    SV **endpoint;
    SV **limit;
    const char *value;
    STRLEN value_len;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(stream);
    PUTBACK;
    sv_setsv(ERRSV, &PL_sv_undef);
    count = call_method("_websocket_raw_config", G_SCALAR | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV) || count != 1) {
        sv_setsv(ERRSV, &PL_sv_undef);
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }

    config = POPs;
    if (!SvROK(config) || SvTYPE(SvRV(config)) != SVt_PVAV) {
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }

    values = (AV *)SvRV(config);
    endpoint = av_fetch(values, 0, 0);
    limit = av_fetch(values, 1, 0);
    if (endpoint == NULL || limit == NULL
        || !SvOK(*endpoint) || !SvOK(*limit)) {
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }

    value = SvPV(*endpoint, value_len);
    if (value_len != 6
        || (!memEQ(value, "client", 6) && !memEQ(value, "server", 6))) {
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }

    *max_message_size = SvUV(*limit);
    if (*max_message_size == 0) {
        PUTBACK;
        FREETMPS;
        LEAVE;
        return 0;
    }

    Copy(value, endpoint_type, 6, char);
    endpoint_type[6] = '\0';

    PUTBACK;
    FREETMPS;
    LEAVE;
    return 1;
}

static void
lews_engine_set_in_feed(SV *engine, int value)
{
    HV *state;
    SV **slot;

    if (!SvROK(engine) || SvTYPE(SvRV(engine)) != SVt_PVHV)
        croak("invalid Linux::Event::WebSocket::_Engine object");

    state = (HV *)SvRV(engine);
    slot = hv_fetchs(state, "in_feed", 0);
    if (slot == NULL)
        croak("WebSocket Engine is missing in_feed state");

    sv_setiv(*slot, value ? 1 : 0);
}

static SV *
lews_raw_call_engine_error(SV *engine, bqws_error error_code)
{
    SV *error = NULL;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(engine);
    PUSHs(sv_2mortal(newSViv((IV)error_code)));
    PUSHs(sv_2mortal(newSVpv(bqws_error_str(error_code), 0)));
    PUTBACK;
    sv_setsv(ERRSV, &PL_sv_undef);
    call_method("_handle_bq_error", G_DISCARD | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return error;
}

static SV *
lews_raw_call_write(SV *stream, SV *wire)
{
    SV *error = NULL;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    XPUSHs(stream);
    XPUSHs(wire);
    PUTBACK;
    sv_setsv(ERRSV, &PL_sv_undef);
    call_method("write", G_DISCARD | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return error;
}

static SV *
lews_raw_call_native_ready(SV *stream, SV *native)
{
    SV *engine = NULL;
    int count;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    XPUSHs(stream);
    XPUSHs(native);
    PUTBACK;
    sv_setsv(ERRSV, &PL_sv_undef);
    count = call_method("_websocket_raw_native_ready", G_SCALAR | G_EVAL);
    SPAGAIN;

    if (!SvTRUE(ERRSV) && count == 1) {
        SV *result = POPs;
        if (SvROK(result)
            && sv_derived_from(result, "Linux::Event::WebSocket::_Engine"))
            engine = newSVsv(result);
    } else {
        sv_setsv(ERRSV, &PL_sv_undef);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return engine;
}
static SV *
lews_engine_native(SV *engine)
{
    HV *state;
    SV **slot;

    if (!SvROK(engine) || SvTYPE(SvRV(engine)) != SVt_PVHV)
        return NULL;

    state = (HV *)SvRV(engine);
    slot = hv_fetchs(state, "native", 0);
    if (slot == NULL || !SvOK(*slot)
        || !SvROK(*slot)
        || !sv_derived_from(*slot, "Linux::Event::WebSocket::_BQ"))
        return NULL;

    return newSVsv(*slot);
}

static SV *
lews_raw_call_complete(SV *engine, SV *stream)
{
    SV *error = NULL;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(engine);
    PUSHs(stream);
    PUTBACK;
    sv_setsv(ERRSV, &PL_sv_undef);
    call_method("_finish_feed", G_DISCARD | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        error = newSVsv(ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return error;
}


static int
lews_raw_consumer_initialize(pTHX_ lews_raw_consumer *context)
{
    char endpoint_type[7];
    UV max_message_size;

    if (context->bq != NULL)
        return 1;

    if (!lews_raw_stream_config(
            aTHX_ context->stream, endpoint_type, &max_message_size))
        return -1;

    context->native = lews_bq_new_object(
        "Linux::Event::WebSocket::_BQ",
        endpoint_type,
        max_message_size
    );
    if (context->native == NULL)
        return -2;

    context->bq = lews_bq_from_sv(context->native);
    context->engine =
        lews_raw_call_native_ready(context->stream, context->native);

    if (context->engine == NULL) {
        context->bq = NULL;
        SvREFCNT_dec(context->native);
        context->native = NULL;
        return -3;
    }

    {
        SV *engine_native = lews_engine_native(context->engine);
        if (engine_native == NULL) {
            context->bq = NULL;
            SvREFCNT_dec(context->engine);
            context->engine = NULL;
            SvREFCNT_dec(context->native);
            context->native = NULL;
            return -3;
        }

        SvREFCNT_dec(context->native);
        context->native = engine_native;
        context->bq = lews_bq_from_sv(context->native);
    }

    return 1;
}

static void *
lews_raw_consumer_create(
    pTHX_
    const les_consumer_host_api_v1_t *host,
    void *host_context,
    SV *stream
)
{
    lews_raw_consumer *context;

    PERL_UNUSED_CONTEXT;

    if (host == NULL
        || host->abi_version != LES_CONSUMER_ABI_VERSION
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || host->retain == NULL || host->release == NULL)
        return NULL;

    Newxz(context, 1, lews_raw_consumer);
    if (context == NULL)
        return NULL;

    context->host = host;
    context->host_context = host_context;
    context->stream = SvREFCNT_inc(stream);
    return context;
}

static int
lews_raw_consumer_input(
    pTHX_
    void *opaque,
    const char *data,
    size_t length,
    size_t *consumed
)
{
    lews_raw_consumer *context = (lews_raw_consumer *)opaque;
    size_t used = 0;
    bqws_msg *msg;
    bqws_error error_code;
    SV *callback_error = NULL;
    SV *wire = NULL;
    int needs_complete = 0;
    int result = LES_CONSUMER_CONTINUE;

    *consumed = 0;

    if (context == NULL
        || context->host == NULL || context->host->retain == NULL
        || context->host->release == NULL)
        return LES_CONSUMER_ERROR;

    if (!context->host->retain(aTHX_ context->host_context))
        return LES_CONSUMER_ERROR;

    {
        int init_status = lews_raw_consumer_initialize(aTHX_ context);
        if (init_status <= 0) {
            context->host->release(aTHX_ context->host_context);
            if (init_status == -1)
                croak("WebSocket raw consumer configuration failed");
            if (init_status == -2)
                croak("WebSocket raw consumer bq initialization failed");
            croak("WebSocket raw consumer Engine handoff failed");
        }
    }

    if (context->host->is_closed(aTHX_ context->host_context)) {
        context->host->release(aTHX_ context->host_context);
        return LES_CONSUMER_CONTINUE;
    }

    lews_engine_set_in_feed(context->engine, 1);

    while (used < length) {
        size_t n = bqws_read_from(
            context->bq->ws,
            data + used,
            length - used
        );
        if (n == 0)
            break;
        used += n;
        if (bqws_get_error(context->bq->ws) != BQWS_OK
            || bqws_get_state(context->bq->ws) >= BQWS_STATE_CLOSING)
            break;
    }
    *consumed = used;

    while (callback_error == NULL
        && (msg = bqws_recv(context->bq->ws)) != NULL) {
        switch (msg->type) {
        case BQWS_MSG_TEXT:
            callback_error = lews_bq_call_event(
                context->engine, context->stream,
                1, msg->data, msg->size, &needs_complete
            );
            break;
        case BQWS_MSG_BINARY:
            callback_error = lews_bq_call_event(
                context->engine, context->stream,
                2, msg->data, msg->size, &needs_complete
            );
            break;
        case BQWS_MSG_CONTROL_CLOSE:
            needs_complete = 1;
            callback_error = lews_bq_call_event(
                context->engine, context->stream,
                8, msg->data, msg->size, &needs_complete
            );
            break;
        case BQWS_MSG_CONTROL_PING:
        case BQWS_MSG_CONTROL_PONG:
            break;
        default:
            callback_error = newSVpvf(
                "unexpected bq_websocket message type %d",
                (int)msg->type
            );
            break;
        }
        bqws_free_msg(msg);

        if (context->host->is_closed(aTHX_ context->host_context))
            break;
    }

    error_code = bqws_get_error(context->bq->ws);
    if (callback_error == NULL && error_code != BQWS_OK) {
        needs_complete = 1;
        callback_error =
            lews_raw_call_engine_error(context->engine, error_code);
    }

    if (callback_error == NULL
        && !context->host->is_closed(aTHX_ context->host_context)) {
        wire = lews_bq_flush(context->bq);
        if (SvCUR(wire) != 0)
            callback_error = lews_raw_call_write(context->stream, wire);
    }

    if (wire != NULL)
        SvREFCNT_dec(wire);

    if (callback_error == NULL && needs_complete
        && !context->host->is_closed(aTHX_ context->host_context))
        callback_error =
            lews_raw_call_complete(context->engine, context->stream);
    else
        lews_engine_set_in_feed(context->engine, 0);

    if (used != length && error_code == BQWS_OK
        && bqws_get_state(context->bq->ws) < BQWS_STATE_CLOSING
        && callback_error == NULL) {
        callback_error = newSVpvf(
            "bq_websocket consumed only %lu of %lu raw input bytes",
            (unsigned long)used,
            (unsigned long)length
        );
    }

    context->host->release(aTHX_ context->host_context);

    if (callback_error != NULL)
        croak_sv(callback_error);

    return result;
}

static void
lews_raw_consumer_event(
    pTHX_
    void *opaque,
    uint32_t event,
    int error,
    const char *message
)
{
    PERL_UNUSED_ARG(opaque);
    PERL_UNUSED_ARG(event);
    PERL_UNUSED_ARG(error);
    PERL_UNUSED_ARG(message);
    PERL_UNUSED_CONTEXT;
}

static void
lews_raw_consumer_destroy(pTHX_ void *opaque)
{
    lews_raw_consumer *context = (lews_raw_consumer *)opaque;

    PERL_UNUSED_CONTEXT;
    if (context == NULL)
        return;

    context->bq = NULL;
    if (context->engine != NULL)
        SvREFCNT_dec(context->engine);
    if (context->native != NULL)
        SvREFCNT_dec(context->native);
    if (context->stream != NULL)
        SvREFCNT_dec(context->stream);
    Safefree(context);
}

typedef struct {
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    SV *stream;
} lews_http_bridge_consumer;

static void *
lews_http_bridge_create(
    pTHX_
    const les_consumer_host_api_v1_t *host,
    void *host_context,
    SV *stream
)
{
    lews_http_bridge_consumer *context;

    PERL_UNUSED_CONTEXT;

    if (host == NULL
        || host->abi_version != LES_CONSUMER_ABI_VERSION
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || host->retain == NULL || host->release == NULL)
        return NULL;

    Newxz(context, 1, lews_http_bridge_consumer);
    if (context == NULL)
        return NULL;

    context->host = host;
    context->host_context = host_context;
    context->stream = SvREFCNT_inc(stream);
    return context;
}

static int
lews_http_bridge_input(
    pTHX_
    void *opaque,
    const char *data,
    size_t length,
    size_t *consumed
)
{
    lews_http_bridge_consumer *context =
        (lews_http_bridge_consumer *)opaque;
    SV *callback_error = NULL;
    dSP;

    *consumed = 0;

    if (context == NULL || context->host == NULL
        || context->host->retain == NULL
        || context->host->release == NULL)
        return LES_CONSUMER_ERROR;

    if (!context->host->retain(aTHX_ context->host_context))
        return LES_CONSUMER_ERROR;

    *consumed = length;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(context->stream);
    PUSHs(sv_2mortal(newSVpvn(data, (STRLEN)length)));
    PUTBACK;
    sv_setsv(ERRSV, &PL_sv_undef);
    call_method("_websocket_http_input", G_DISCARD | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        callback_error = newSVsv(ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    context->host->release(aTHX_ context->host_context);

    if (callback_error != NULL)
        croak_sv(callback_error);

    return LES_CONSUMER_CONTINUE;
}

static void
lews_http_bridge_event(
    pTHX_
    void *opaque,
    uint32_t event,
    int error,
    const char *message
)
{
    PERL_UNUSED_ARG(opaque);
    PERL_UNUSED_ARG(event);
    PERL_UNUSED_ARG(error);
    PERL_UNUSED_ARG(message);
    PERL_UNUSED_CONTEXT;
}

static void
lews_http_bridge_destroy(pTHX_ void *opaque)
{
    lews_http_bridge_consumer *context =
        (lews_http_bridge_consumer *)opaque;

    PERL_UNUSED_CONTEXT;
    if (context == NULL)
        return;

    if (context->stream != NULL)
        SvREFCNT_dec(context->stream);
    Safefree(context);
}

static const les_consumer_ops_v1_t lews_http_bridge_consumer_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "Linux::Event::WebSocket HTTP handoff bridge",
    LES_CONSUMER_F_RAW_INPUT,
    lews_http_bridge_create,
    NULL,
    lews_http_bridge_event,
    lews_http_bridge_destroy,
    NULL,
    lews_http_bridge_input
};

static const les_consumer_ops_v1_t lews_raw_consumer_ops = {
    LES_CONSUMER_ABI_VERSION,
    sizeof(les_consumer_ops_v1_t),
    "Linux::Event::WebSocket bq raw input",
    LES_CONSUMER_F_RAW_INPUT,
    lews_raw_consumer_create,
    NULL,
    lews_raw_consumer_event,
    lews_raw_consumer_destroy,
    NULL,
    lews_raw_consumer_input
};

MODULE = Linux::Event::WebSocket    PACKAGE = Linux::Event::WebSocket::_BQ

PROTOTYPES: DISABLE

UV
_raw_consumer_operations_address()
CODE:
    RETVAL = PTR2UV(&lews_raw_consumer_ops);
OUTPUT:
    RETVAL

UV
_http_bridge_consumer_operations_address()
CODE:
    RETVAL = PTR2UV(&lews_http_bridge_consumer_ops);
OUTPUT:
    RETVAL

SV *
new(class, endpoint_type, max_message_size)
    const char *class
    const char *endpoint_type
    UV max_message_size
CODE:
    RETVAL = lews_bq_new_object(class, endpoint_type, max_message_size);
    if (RETVAL == NULL)
        croak("bq_websocket context initialization failed");
OUTPUT:
    RETVAL

void
feed(self, callback_target, connection, bytes)
    SV *self
    SV *callback_target
    SV *connection
    SV *bytes
PREINIT:
    lews_bq *state;
    STRLEN len;
    const char *data;
    size_t used;
    bqws_msg *msg;
    bqws_error error;
    SV *callback_error;
PPCODE:
    state = lews_bq_from_sv(self);
    data = SvPVbyte(bytes, len);
    used = 0;
    while (used < (size_t)len) {
        size_t n = bqws_read_from(
            state->ws,
            data + used,
            (size_t)len - used
        );
        if (n == 0) {
            break;
        }
        used += n;
        if (bqws_get_error(state->ws) != BQWS_OK
            || bqws_get_state(state->ws) >= BQWS_STATE_CLOSING) {
            break;
        }
    }

    while ((msg = bqws_recv(state->ws)) != NULL) {
        callback_error = NULL;

        switch (msg->type) {
        case BQWS_MSG_TEXT:
            callback_error = lews_bq_call_event(
                callback_target, connection, 1, msg->data, msg->size, NULL
            );
            break;
        case BQWS_MSG_BINARY:
            callback_error = lews_bq_call_event(
                callback_target, connection, 2, msg->data, msg->size, NULL
            );
            break;
        case BQWS_MSG_CONTROL_CLOSE:
            callback_error = lews_bq_call_event(
                callback_target, connection, 8, msg->data, msg->size, NULL
            );
            break;
        case BQWS_MSG_CONTROL_PING:
        case BQWS_MSG_CONTROL_PONG:
            break;
        default:
            bqws_free_msg(msg);
            croak("unexpected bq_websocket message type %d", (int)msg->type);
        }

        bqws_free_msg(msg);

        if (callback_error != NULL) {
            croak_sv(callback_error);
        }
    }

    error = bqws_get_error(state->ws);
    if (used != (size_t)len && error == BQWS_OK
        && bqws_get_state(state->ws) < BQWS_STATE_CLOSING) {
        croak("bq_websocket consumed only %lu of %lu input bytes",
            (unsigned long)used, (unsigned long)len);
    }

    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv((IV)error)));
    PUSHs(sv_2mortal(newSVpv(bqws_error_str(error), 0)));
    XSRETURN(2);

SV *
flush(self)
    SV *self
PREINIT:
    lews_bq *state;
CODE:
    state = lews_bq_from_sv(self);
    RETVAL = lews_bq_flush(state);
OUTPUT:
    RETVAL

void
queue_message(self, opcode, bytes)
    SV *self
    IV opcode
    SV *bytes
PREINIT:
    lews_bq *state;
    STRLEN len;
    const char *data;
CODE:
    state = lews_bq_from_sv(self);
    if (opcode == 1) {
        if (SvUTF8(bytes)) {
            data = SvPVutf8(bytes, len);
        } else {
            data = SvPVbyte(bytes, len);
        }

        if (!is_utf8_string_flags(
                (const U8 *)data,
                len,
                UTF8_DISALLOW_ILLEGAL_C9_INTERCHANGE
            )) {
            croak("send_text(): payload contains invalid UTF-8");
        }

        bqws_send(state->ws, BQWS_MSG_TEXT, data, (size_t)len);
    } else if (opcode == 2) {
        data = SvPVbyte(bytes, len);
        bqws_send(state->ws, BQWS_MSG_BINARY, data, (size_t)len);
    } else if (opcode == 9) {
        data = SvPVbyte(bytes, len);
        bqws_send_ping(state->ws, data, (size_t)len);
    } else {
        croak("unsupported bq_websocket opcode %ld", (long)opcode);
    }

    if (bqws_get_error(state->ws) != BQWS_OK) {
        croak("bq_websocket send failed: %s",
            bqws_error_str(bqws_get_error(state->ws)));
    }

void
queue_close(self, status_code, reason)
    SV *self
    UV status_code
    SV *reason
PREINIT:
    lews_bq *state;
    STRLEN len;
    const char *data;
CODE:
    state = lews_bq_from_sv(self);
    data = SvPVbyte(reason, len);
    bqws_close(
        state->ws,
        (bqws_close_reason)status_code,
        data,
        (size_t)len
    );

void
DESTROY(self)
    SV *self
PREINIT:
    lews_bq *state;
CODE:
    if (SvROK(self)) {
        state = INT2PTR(lews_bq *, SvIV((SV *)SvRV(self)));
        if (state != NULL) {
            lews_bq_free(state);
            sv_setiv((SV *)SvRV(self), 0);
        }
    }
