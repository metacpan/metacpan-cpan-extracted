#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stream_consumer_abi.h"
#include "unblock_http1_native_abi.h"
#include "unblock_http2_native_abi.h"

/* The provider tables have different contracts. Never cast one to the other. */
typedef struct {
    const les_consumer_host_api_v1_t *host;
    void *host_context;
    SV *stream;
    int protocol;
    int (*input)(pTHX_ void *, const char *, size_t, size_t *);
    void (*destroy)(pTHX_ void *);
    void *input_context;
} bridge_context;

static void *
bridge_create(pTHX_ const les_consumer_host_api_v1_t *host,
    void *host_context, SV *stream)
{
    bridge_context *ctx;
    if (host->abi_version != LES_CONSUMER_ABI_VERSION
        || host->struct_size < LES_CONSUMER_HOST_V1_RETAIN_REQUIRED_SIZE
        || !host->retain || !host->release)
        croak("HTTP bridge requires Linux::Event consumer lifetime support");
    Newxz(ctx, 1, bridge_context);
    ctx->host = host;
    ctx->host_context = host_context;
    ctx->stream = newSVsv(stream);
    sv_rvweaken(ctx->stream);
    return ctx;
}

/* Select only after TLS readiness has attached the actual engine. The
 * protocols have distinct tables even where individual signatures match. */
static void
bridge_attach(pTHX_ bridge_context *ctx, SV *engine)
{
    UV address;
    int protocol, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(engine);
    PUTBACK;
    count = call_pv("Linux::Event::HTTP::_NativeBridge::_input_operations_address", G_ARRAY);
    SPAGAIN;
    if (count != 2) croak("HTTP bridge provider returned an invalid definition");
    address = POPu;
    protocol = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    ctx->protocol = protocol;
    if (protocol == 1) {
        const ub_http1_input_ops_v1 *ops = INT2PTR(const ub_http1_input_ops_v1 *, address);
        if (!ops || ops->abi_version != UB_HTTP1_INPUT_ABI_VERSION
            || ops->struct_size < sizeof(ub_http1_input_ops_v1)
            || !ops->create || !ops->input || !ops->eof || !ops->destroy)
            croak("incompatible Unblock::HTTP1 native input ABI");
        ctx->input = ops->input;
        ctx->destroy = ops->destroy;
        ctx->input_context = ops->create(aTHX_ engine);
    } else if (protocol == 2) {
        const ub_http2_native_ops_v1 *ops = INT2PTR(const ub_http2_native_ops_v1 *, address);
        if (!ops || ops->abi_version != UB_HTTP2_NATIVE_ABI_VERSION
            || ops->struct_size < sizeof(ub_http2_native_ops_v1)
            || !ops->create || !ops->input || !ops->eof || !ops->destroy)
            croak("incompatible Unblock::HTTP2 native input ABI");
        ctx->input = ops->input;
        ctx->destroy = ops->destroy;
        ctx->input_context = ops->create(aTHX_ engine);
    } else {
        croak("unsupported HTTP native input protocol");
    }
    if (!ctx->input_context)
        croak("HTTP bridge could not create input context");
}

static void
bridge_flush_http2(pTHX_ bridge_context *ctx)
{
    dSP;
    if (!SvROK(ctx->stream)) return;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(ctx->stream);
    PUTBACK;
    call_method("_http_flush", G_DISCARD);
    FREETMPS;
    LEAVE;
}

typedef struct {
    bridge_context *ctx;
    const char *data;
    size_t length;
    size_t *consumed;
    int result;
} bridge_http2_frame;

/* HTTP2 can throw for malformed peer input after closing its engine. A real
 * Perl eval scope contains that failure without unwinding the reactor. Only
 * a stack-frame address crosses the XSUB call: the input bytes stay borrowed. */
static int
bridge_http2_input(pTHX_ bridge_context *ctx, const char *data,
    size_t length, size_t *consumed)
{
    bridge_http2_frame frame = { ctx, data, length, consumed, UB_HTTP2_INPUT_OK };
    SV *error = NULL;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVuv(PTR2UV(&frame))));
    PUTBACK;
    call_pv("Linux::Event::HTTP::_NativeBridge::_http2_input", G_DISCARD | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) error = newSVsv(ERRSV);
    PUTBACK;
    if (error) {
        sv_2mortal(error);
        if (SvROK(ctx->stream)) {
            PUSHMARK(SP);
            XPUSHs(ctx->stream);
            XPUSHs(error);
            PUTBACK;
            call_method("_http_input_failed", G_DISCARD);
        }
        *consumed = length;
        frame.result = UB_HTTP2_INPUT_CLOSED;
    }
    FREETMPS;
    LEAVE;
    return frame.result;
}

static int
bridge_input(pTHX_ void *opaque, const char *data, size_t length, size_t *consumed)
{
    bridge_context *ctx = (bridge_context *)opaque;
    const les_consumer_host_api_v1_t *host = ctx->host;
    void *host_context = ctx->host_context;
    int jump_status;
    int result = UB_HTTP1_INPUT_OK;
    dJMPENV;
    *consumed = 0;
    if (!host->retain(aTHX_ host_context))
        return LES_CONSUMER_CLOSE;
    JMPENV_PUSH(jump_status);
    if (jump_status == 0) {
        if (!ctx->input_context) {
            SV **engine;
            if (!SvROK(ctx->stream) || SvTYPE(SvRV(ctx->stream)) != SVt_PVHV)
                croak("HTTP bridge stream is unavailable");
            engine = hv_fetch((HV *)SvRV(ctx->stream), "http_engine", 11, 0);
            if (!engine || !SvROK(*engine))
                croak("HTTP bridge received input before engine attachment");
            bridge_attach(aTHX_ ctx, *engine);
        }
        result = ctx->protocol == 2
            ? bridge_http2_input(aTHX_ ctx, data, length, consumed)
            : ctx->input(aTHX_ ctx->input_context, data, length, consumed);
        if (*consumed > length)
            croak("HTTP engine consumed beyond its borrowed input window");
        switch (result) {
        case UB_HTTP1_INPUT_OK:
        case UB_HTTP1_INPUT_MORE:
            break;
        case UB_HTTP1_INPUT_CLOSED:
            /* End has already queued the final output. Discard trailing HTTP
             * input; do not close the socket ahead of its pending writes. */
            *consumed = length;
            break;
        case UB_HTTP1_INPUT_SWITCH:
            /* The Unblock on_switch callback must have synchronously
             * transitioned this very Stream. The native host applies the
             * consumed HTTP prefix and re-drives its unread tail through
             * the new ordinary input sink after our retained frame ends. */
            if (ctx->protocol != 1 || !SvROK(ctx->stream)
                || !sv_derived_from(ctx->stream,
                    "Linux::Event::HTTP::_UpgradedStream"))
                croak("native HTTP1 switch has no upgraded input consumer");
            break;
        default:
            croak("HTTP engine returned an unknown native input status");
        }
        JMPENV_POP;
    } else {
        JMPENV_POP;
        host->release(aTHX_ host_context);
        JMPENV_JUMP(jump_status);
    }
    /* May destroy ctx and the host after reentrant close. Last access. */
    host->release(aTHX_ host_context);
    return LES_CONSUMER_CONTINUE;
}

static void
bridge_event(pTHX_ void *opaque, uint32_t event, int error, const char *message)
{
    /* Ordinary Stream lifecycle callbacks deliver EOF/error exactly once. */
    PERL_UNUSED_ARG(opaque);
    PERL_UNUSED_ARG(event);
    PERL_UNUSED_ARG(error);
    PERL_UNUSED_ARG(message);
    PERL_UNUSED_CONTEXT;
}

static void
bridge_destroy(pTHX_ void *opaque)
{
    bridge_context *ctx = (bridge_context *)opaque;
    if (!ctx) return;
    if (ctx->input_context)
        ctx->destroy(aTHX_ ctx->input_context);
    SvREFCNT_dec(ctx->stream);
    Safefree(ctx);
}

static const les_consumer_ops_v1_t bridge_ops = {
    LES_CONSUMER_ABI_VERSION, sizeof(les_consumer_ops_v1_t),
    "Linux::Event::HTTP Unblock HTTP input", LES_CONSUMER_F_RAW_INPUT,
    bridge_create, NULL, bridge_event, bridge_destroy, NULL, bridge_input
};

MODULE = Linux::Event::HTTP::_NativeBridge PACKAGE = Linux::Event::HTTP::_NativeBridge
PROTOTYPES: DISABLE

void
_http2_input(frame_address)
    UV frame_address
  PREINIT:
    bridge_http2_frame *frame;
  CODE:
    frame = INT2PTR(bridge_http2_frame *, frame_address);
    frame->result = frame->ctx->input(aTHX_ frame->ctx->input_context,
        frame->data, frame->length, frame->consumed);
    /* Native input leaves attached output flushing to the caller. */
    bridge_flush_http2(aTHX_ frame->ctx);

UV
_operations_address()
  CODE:
    RETVAL = PTR2UV(&bridge_ops);
  OUTPUT:
    RETVAL
