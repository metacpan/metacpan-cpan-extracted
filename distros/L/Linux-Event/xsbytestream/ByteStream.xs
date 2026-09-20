/* Linux::Event private ordered-byte XS boundary. */

#include "stream_internal.h"

static SV *
les_descriptor_spec_sv(pTHX_ HV *spec, const char *key)
{
    I32 key_len = (I32)strlen(key);
    SV **slot = hv_fetch(spec, key, key_len, 0);

    if (!slot)
        croak("missing ordered-byte descriptor field '%s'", key);
    return *slot;
}

static UV
les_descriptor_spec_uv(pTHX_ HV *spec, const char *key)
{
    SV *value = les_descriptor_spec_sv(aTHX_ spec, key);
    return SvOK(value) ? SvUV(value) : 0;
}

static int
les_descriptor_spec_int(pTHX_ HV *spec, const char *key)
{
    SV *value = les_descriptor_spec_sv(aTHX_ spec, key);
    return SvOK(value) ? (int)SvIV(value) : 0;
}

MODULE = Linux::Event::_ByteStream    PACKAGE = Linux::Event::_ByteStream::Descriptor::Native
PROTOTYPES: DISABLE

SV *
_new_validated(CLASS, spec_rv)
    const char *CLASS
    SV *spec_rv
  PREINIT:
    HV *spec;
    les_descriptor_t *descriptor;
    const les_consumer_ops_v1_t *consumer_ops = NULL;
    STRLEN delimiter_len = 0;
    const char *delimiter = NULL;
    UV read_size, read_budget_bytes, read_batch_bytes, message_batch_size;
    UV high_watermark, low_watermark, max_pending_bytes, max_buffer;
    UV fixed_size, consumer_abi_version, consumer_ops_address;
    int read_mode, include_delimiter, prefix_bytes, prefix_little;
    int include_prefix;
    SV *deliver_cb, *message_cb, *message_batch_cb, *drain_cb, *eof_cb;
    SV *read_error_cb, *write_error_cb, *output_limit_cb, *write_empty_cb;
    SV *framing_error_cb, *delimiter_sv, *max_frame_sv, *consumer_provider;
  CODE:
    if (!spec_rv || !SvROK(spec_rv) || SvTYPE(SvRV(spec_rv)) != SVt_PVHV)
        croak("native descriptor requires a hash reference");
    spec = (HV *)SvRV(spec_rv);
    if (HvUSEDKEYS(spec) != 29)
        croak("native descriptor requires a complete validated specification");

    read_size = les_descriptor_spec_uv(aTHX_ spec, "read_size");
    read_budget_bytes = les_descriptor_spec_uv(aTHX_ spec,
        "read_budget_bytes");
    read_batch_bytes = les_descriptor_spec_uv(aTHX_ spec,
        "read_batch_bytes");
    message_batch_size = les_descriptor_spec_uv(aTHX_ spec,
        "message_batch_size");
    high_watermark = les_descriptor_spec_uv(aTHX_ spec, "high_watermark");
    low_watermark = les_descriptor_spec_uv(aTHX_ spec, "low_watermark");
    max_pending_bytes = les_descriptor_spec_uv(aTHX_ spec,
        "max_pending_bytes");
    max_buffer = les_descriptor_spec_uv(aTHX_ spec, "max_buffer");
    fixed_size = les_descriptor_spec_uv(aTHX_ spec, "fixed_size");
    consumer_abi_version = les_descriptor_spec_uv(aTHX_ spec,
        "consumer_abi_version");
    consumer_ops_address = les_descriptor_spec_uv(aTHX_ spec,
        "consumer_ops_address");
    read_mode = les_descriptor_spec_int(aTHX_ spec, "read_mode");
    include_delimiter = les_descriptor_spec_int(aTHX_ spec,
        "include_delimiter");
    prefix_bytes = les_descriptor_spec_int(aTHX_ spec, "prefix_bytes");
    prefix_little = les_descriptor_spec_int(aTHX_ spec, "prefix_little");
    include_prefix = les_descriptor_spec_int(aTHX_ spec, "include_prefix");
    deliver_cb = les_descriptor_spec_sv(aTHX_ spec, "deliver_cb");
    message_cb = les_descriptor_spec_sv(aTHX_ spec, "message_cb");
    message_batch_cb = les_descriptor_spec_sv(aTHX_ spec,
        "message_batch_cb");
    drain_cb = les_descriptor_spec_sv(aTHX_ spec, "drain_cb");
    eof_cb = les_descriptor_spec_sv(aTHX_ spec, "eof_cb");
    read_error_cb = les_descriptor_spec_sv(aTHX_ spec, "read_error_cb");
    write_error_cb = les_descriptor_spec_sv(aTHX_ spec, "write_error_cb");
    output_limit_cb = les_descriptor_spec_sv(aTHX_ spec, "output_limit_cb");
    write_empty_cb = les_descriptor_spec_sv(aTHX_ spec, "write_empty_cb");
    framing_error_cb = les_descriptor_spec_sv(aTHX_ spec,
        "framing_error_cb");
    delimiter_sv = les_descriptor_spec_sv(aTHX_ spec, "delimiter");
    max_frame_sv = les_descriptor_spec_sv(aTHX_ spec, "max_frame");
    consumer_provider = les_descriptor_spec_sv(aTHX_ spec,
        "consumer_provider");

    if (read_size == 0) croak("read_size must be > 0");
    if (read_budget_bytes > (UV)(size_t)-1)
        croak("read_budget_bytes exceeds native size_t");
    if (read_batch_bytes > (UV)(size_t)-1)
        croak("read_batch_bytes exceeds native size_t");
    if (read_mode != LES_READ_DELIVER
        && (read_mode < LES_READ_DELIMITER || read_mode > LES_READ_DECIMAL))
        croak("invalid ordered-byte native read mode");
    if (read_mode == LES_READ_FIXED && fixed_size == 0)
        croak("fixed_size must be > 0 for native fixed framing");
    if (read_mode == LES_READ_LENGTH
        && prefix_bytes != 1 && prefix_bytes != 2 && prefix_bytes != 4)
        croak("prefix_bytes must be 1, 2, or 4 for native length framing");

    if (consumer_ops_address) {
        if (!consumer_provider || !SvOK(consumer_provider))
            croak("native consumer provider is required");
        if (consumer_abi_version != LES_CONSUMER_ABI_VERSION)
            croak("consumer ABI version mismatch: got %llu, need %u",
                (unsigned long long)consumer_abi_version,
                LES_CONSUMER_ABI_VERSION);
        consumer_ops = INT2PTR(const les_consumer_ops_v1_t *,
            consumer_ops_address);
        if (consumer_ops->abi_version != LES_CONSUMER_ABI_VERSION)
            croak("consumer operations table has an incompatible ABI version");
        if (consumer_ops->struct_size < LES_CONSUMER_OPS_V1_REQUIRED_SIZE)
            croak("consumer operations table is smaller than ABI v1");
        if (consumer_ops->flags
            & ~(LES_CONSUMER_F_START_PAUSED | LES_CONSUMER_F_WANT_FLUSH
                | LES_CONSUMER_F_RAW_INPUT))
            croak("consumer operations table has unsupported flags");
        if (!consumer_ops->name || !consumer_ops->name[0]
            || !consumer_ops->create || !consumer_ops->event
            || !consumer_ops->destroy)
            croak("consumer operations table is incomplete");
        if ((consumer_ops->flags & LES_CONSUMER_F_RAW_INPUT)) {
            if (consumer_ops->struct_size
                    < LES_CONSUMER_OPS_V1_RAW_INPUT_REQUIRED_SIZE
                || !consumer_ops->input)
                croak("consumer operations table requests raw input without an input function");
            if (read_mode != LES_READ_DELIVER)
                croak("raw-input native consumer requires an unframed ordered-byte class");
            if (read_batch_bytes)
                croak("raw-input native consumer cannot use read_batch_bytes");
        } else {
            if (!consumer_ops->message)
                croak("consumer operations table is incomplete");
            if (read_mode == LES_READ_DELIVER)
                croak("framed native consumer requires a built-in native framer");
        }
        if ((consumer_ops->flags & LES_CONSUMER_F_WANT_FLUSH)
            && (consumer_ops->struct_size
                    < LES_CONSUMER_OPS_V1_FLUSH_REQUIRED_SIZE
                || !consumer_ops->flush))
            croak("consumer operations table requests flush without a flush function");
    } else if ((consumer_provider && SvOK(consumer_provider))
        || consumer_abi_version) {
        croak("native consumer declaration is incomplete");
    }

    if (read_mode == LES_READ_DELIMITER || read_mode == LES_READ_DECIMAL) {
        if (!delimiter_sv || !SvOK(delimiter_sv))
            croak("delimiter required for native delimiter mode");
        delimiter = SvPVbyte(delimiter_sv, delimiter_len);
        if (delimiter_len == 0)
            croak("delimiter must not be empty");
        if (read_mode == LES_READ_DECIMAL && delimiter_len != 1)
            croak("separator must be exactly one byte for native decimal framing");
    }

    descriptor = (les_descriptor_t *)calloc(1, sizeof(*descriptor));
    if (!descriptor) croak("calloc native descriptor failed");

    descriptor->read_size = (size_t)read_size;
    descriptor->read_budget_bytes = read_budget_bytes;
    descriptor->read_batch_bytes = read_batch_bytes;
    descriptor->message_batch_size = message_batch_size;
    descriptor->high_watermark = high_watermark;
    descriptor->low_watermark = low_watermark;
    descriptor->max_pending_bytes = max_pending_bytes;
    descriptor->max_buffer = max_buffer;
    descriptor->read_mode = read_mode;
    descriptor->include_delimiter = include_delimiter ? 1 : 0;
    descriptor->fixed_size = fixed_size;
    descriptor->prefix_bytes = prefix_bytes;
    descriptor->prefix_little = prefix_little ? 1 : 0;
    descriptor->include_prefix = include_prefix ? 1 : 0;
    if (max_frame_sv && SvOK(max_frame_sv)) {
        descriptor->has_max_frame = 1;
        descriptor->max_frame = SvUV(max_frame_sv);
    }
    if (delimiter_len) {
        descriptor->delimiter = (char *)malloc((size_t)delimiter_len);
        if (!descriptor->delimiter) {
            free(descriptor);
            croak("malloc native descriptor delimiter failed");
        }
        memcpy(descriptor->delimiter, delimiter, (size_t)delimiter_len);
        descriptor->delimiter_len = (size_t)delimiter_len;
    }

    descriptor->deliver_cb = les_store_optional_cb(deliver_cb, "on_data callback");
    descriptor->message_cb = les_store_optional_cb(message_cb, "on_message callback");
    descriptor->message_batch_cb = les_store_optional_cb(message_batch_cb,
        "on_messages callback");
    descriptor->drain_cb = les_store_optional_cb(drain_cb, "on_drain callback");
    descriptor->eof_cb = les_store_cb(eof_cb, "EOF callback");
    descriptor->read_error_cb = les_store_cb(read_error_cb, "read error callback");
    descriptor->write_error_cb = les_store_cb(write_error_cb, "write error callback");
    descriptor->output_limit_cb = les_store_cb(output_limit_cb, "output limit callback");
    descriptor->write_empty_cb = les_store_cb(write_empty_cb, "write empty callback");
    descriptor->framing_error_cb = les_store_cb(framing_error_cb, "framing error callback");
    descriptor->consumer_ops = consumer_ops;
    if (consumer_ops)
        descriptor->consumer_provider_sv = newSVsv(consumer_provider);

    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)descriptor);
  OUTPUT:
    RETVAL

void
DESTROY(descriptor_obj)
    SV *descriptor_obj
  PREINIT:
    les_descriptor_t *descriptor;
  CODE:
    descriptor = les_descriptor_from_sv(descriptor_obj);
    if (descriptor) {
        if (descriptor->deliver_cb) SvREFCNT_dec(descriptor->deliver_cb);
        if (descriptor->message_cb) SvREFCNT_dec(descriptor->message_cb);
        if (descriptor->message_batch_cb) SvREFCNT_dec(descriptor->message_batch_cb);
        if (descriptor->drain_cb) SvREFCNT_dec(descriptor->drain_cb);
        if (descriptor->eof_cb) SvREFCNT_dec(descriptor->eof_cb);
        if (descriptor->read_error_cb) SvREFCNT_dec(descriptor->read_error_cb);
        if (descriptor->write_error_cb) SvREFCNT_dec(descriptor->write_error_cb);
        if (descriptor->output_limit_cb) SvREFCNT_dec(descriptor->output_limit_cb);
        if (descriptor->write_empty_cb) SvREFCNT_dec(descriptor->write_empty_cb);
        if (descriptor->framing_error_cb) SvREFCNT_dec(descriptor->framing_error_cb);
        if (descriptor->consumer_provider_sv)
            SvREFCNT_dec(descriptor->consumer_provider_sv);
        free(descriptor->delimiter);
        free(descriptor);
        sv_setiv(SvRV(descriptor_obj), 0);
    }

MODULE = Linux::Event::_ByteStream    PACKAGE = Linux::Event::_ByteStream::State
PROTOTYPES: DISABLE

SV *
_new_validated(CLASS, object, read_fd, write_fd, descriptor_obj, input_cb = &PL_sv_undef, drain_cb = &PL_sv_undef)
    const char *CLASS
    SV *object
    int read_fd
    int write_fd
    SV *descriptor_obj
    SV *input_cb
    SV *drain_cb
  PREINIT:
    les_xsstate_t *st;
    les_descriptor_t *descriptor;
  CODE:
    if (read_fd < 0 && write_fd < 0)
        croak("ordered-byte state requires a read or write fd");
    descriptor = les_descriptor_from_sv(descriptor_obj);
    if (!descriptor) croak("ordered-byte descriptor is closed");
    st = (les_xsstate_t *)calloc(1, sizeof(*st));
    if (!st) croak("calloc ordered-byte state failed");
    st->read_fd = read_fd;
    st->write_fd = write_fd;
    st->plain_transport.read_fd = read_fd;
    st->plain_transport.write_fd = write_fd;
    st->transport_ops = &les_plain_transport_ops;
    st->transport_context = &st->plain_transport;
    st->descriptor = descriptor;
    st->descriptor_sv = newSVsv(descriptor_obj);
    st->stream_sv = newSVsv(object);
    st->instance_input_kind = input_cb && SvOK(input_cb)
        ? les_descriptor_input_kind(descriptor) : LES_CALLBACK_NONE;
    st->has_instance_drain_cb = drain_cb && SvOK(drain_cb);
    if (st->instance_input_kind) {
        st->instance_input_cb = les_store_cb(input_cb,
            "ordered-byte input callback");
        st->input_cb = st->instance_input_cb;
    } else {
        SV *descriptor_cb = les_descriptor_input_cb(descriptor);
        if (descriptor_cb)
            st->input_cb = SvREFCNT_inc_simple_NN(descriptor_cb);
    }
    st->drain_cb = st->has_instance_drain_cb
        ? les_store_cb(drain_cb, "on_drain callback")
        : descriptor->drain_cb
            ? SvREFCNT_inc_simple_NN(descriptor->drain_cb) : NULL;

    if (read_fd >= 0 && descriptor->read_mode == LES_READ_DELIVER
        && !(descriptor->consumer_ops
            && (descriptor->consumer_ops->flags & LES_CONSUMER_F_RAW_INPUT))) {
        st->read_buffer = (char *)malloc(descriptor->read_size);
        if (!st->read_buffer) {
            SvREFCNT_dec(st->descriptor_sv);
            SvREFCNT_dec(st->stream_sv);
            if (st->input_cb && st->input_cb != st->instance_input_cb)
                SvREFCNT_dec(st->input_cb);
            if (st->instance_input_cb) SvREFCNT_dec(st->instance_input_cb);
            if (st->drain_cb) SvREFCNT_dec(st->drain_cb);
            free(st);
            croak("malloc ordered-byte read buffer failed");
        }
    }
    if (!les_consumer_create(aTHX_ st)) {
        const char *consumer_name = descriptor->consumer_ops->name;
        SvREFCNT_dec(st->descriptor_sv);
        SvREFCNT_dec(st->stream_sv);
        if (st->input_cb && st->input_cb != st->instance_input_cb)
            SvREFCNT_dec(st->input_cb);
        if (st->instance_input_cb) SvREFCNT_dec(st->instance_input_cb);
        if (st->drain_cb) SvREFCNT_dec(st->drain_cb);
        free(st->read_buffer);
        free(st);
        croak("native consumer '%s' failed to create context", consumer_name);
    }

    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)st);
  OUTPUT:
    RETVAL

void
DESTROY(state_obj)
    SV *state_obj
  PREINIT:
    les_xsstate_t *st;
  CODE:
    st = les_state_from_sv(state_obj);
    if (st) {
        sv_setiv(SvRV(state_obj), 0);
        st->destroy_pending = 1;
        if (!st->consumer_host_retain_count)
            les_state_destroy(aTHX_ st);
    }

SV *
object(state_obj)
    SV *state_obj
  CODE:
    les_xsstate_t *st = les_state_from_sv(state_obj);
    RETVAL = st->stream_sv ? newSVsv(st->stream_sv) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
_read_ready(state_obj)
    SV *state_obj
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    les_read_ready(aTHX_ les_state_from_sv(state_obj));
    LEAVE;

int
_write(state_obj, bytes)
    SV *state_obj
    SV *bytes
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    RETVAL = les_write_submit(aTHX_ les_state_from_sv(state_obj), bytes);
    LEAVE;
  OUTPUT:
    RETVAL

void
_write_ready(state_obj)
    SV *state_obj
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    les_write_ready(aTHX_ les_state_from_sv(state_obj));
    LEAVE;

void
_attach_transport(state_obj, provider, abi_version, ops_address, context_address)
    SV *state_obj
    SV *provider
    UV abi_version
    UV ops_address
    UV context_address
  PREINIT:
    les_xsstate_t *st;
    const les_transport_ops_t *ops;
  CODE:
    st = les_state_from_sv(state_obj);
    if (st->closed) croak("cannot attach a transport to closed ordered-byte state");
    if (st->transport_ops != &les_plain_transport_ops)
        croak("ordered-byte state already has a non-plain transport");
    if (abi_version != LES_TRANSPORT_ABI_VERSION)
        croak("transport ABI version mismatch: got %llu, need %u",
            (unsigned long long)abi_version, LES_TRANSPORT_ABI_VERSION);
    if (!ops_address || !context_address)
        croak("transport returned a null native address");
    ops = INT2PTR(const les_transport_ops_t *, ops_address);
    if (ops->abi_version != LES_TRANSPORT_ABI_VERSION)
        croak("transport operations table has an incompatible ABI version");
    if (!ops->name || !ops->name[0] || !ops->read_bytes || !ops->write_bytes
        || !ops->write_vectors || !ops->shutdown_write || !ops->drive
        || !ops->is_ready || !ops->error_string)
        croak("transport operations table is incomplete");
    st->transport_provider_sv = newSVsv(provider);
    st->transport_ops = ops;
    st->transport_context = INT2PTR(void *, context_address);

void
_shutdown_write(state_obj)
    SV *state_obj
  PREINIT:
    les_xsstate_t *st;
    les_transport_result_t result;
  PPCODE:
    st = les_state_from_sv(state_obj);
    if (st->closed) {
        result.count = 0;
        result.status = LES_TRANSPORT_ERROR;
        result.error = EBADF;
    } else {
        result = les_transport_shutdown_write(st);
    }
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSViv(result.status)));
    PUSHs(sv_2mortal(newSViv(result.error)));
    PUSHs(sv_2mortal(newSVpv(
        result.status == LES_TRANSPORT_ERROR
            ? st->transport_ops->error_string(st->transport_context) : "", 0)));

void
_pause(state_obj)
    SV *state_obj
  CODE:
    les_state_from_sv(state_obj)->read_paused = 1;

void
_resume(state_obj)
    SV *state_obj
  PREINIT:
    les_xsstate_t *st;
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    st = les_state_from_sv(state_obj);
    if (!st->closed && !st->read_eof) {
        st->read_paused = 0;
        if (!st->consumer_paused && st->input_dispatch_depth == 0
            && st->input_len) {
            ENTER;
            SAVEINT(st->input_dispatch_depth);
            st->input_dispatch_depth++;
            les_process_existing_input(aTHX_ st, 1);
            LEAVE;
        }
    }
    LEAVE;

void
_set_activity_tracking(state_obj, enabled)
    SV *state_obj
    int enabled
  PREINIT:
    les_xsstate_t *st;
    unsigned long long now;
  CODE:
    st = les_state_from_sv(state_obj);
    if (enabled) {
        if (!st->activity_tracking) {
            now = les_activity_now_ns(aTHX);
            st->last_read_ns = now;
            st->last_write_ns = now;
            LES_STAT(st, activity_clock_calls)++;
        }
        st->activity_tracking = 1;
    } else {
        st->activity_tracking = 0;
    }

void
_activity_snapshot(state_obj)
    SV *state_obj
  PREINIT:
    les_xsstate_t *st;
  PPCODE:
    st = les_state_from_sv(state_obj);
    if (!st->activity_tracking)
        croak("ordered-byte activity tracking is not enabled");
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVnv((NV)st->last_read_ns / 1000000000.0)));
    PUSHs(sv_2mortal(newSVnv((NV)st->last_write_ns / 1000000000.0)));

void
_transition_validated(state_obj, descriptor_obj, input = &PL_sv_undef)
    SV *state_obj
    SV *descriptor_obj
    SV *input
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    les_transition_descriptor(aTHX_ les_state_from_sv(state_obj),
        descriptor_obj, input);
    LEAVE;

void
_transition_ready(state_obj)
    SV *state_obj
  PREINIT:
    les_xsstate_t *st;
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    st = les_state_from_sv(state_obj);
    if (st->consumer_transition_pending && !st->consumer_call_depth
        && !st->consumer_host_retain_count)
        les_consumer_flush(aTHX_ st);
    if (!st->consumer_transition_pending
        && !st->closed && !LES_INPUT_PAUSED(st) && !st->read_eof
        && st->input_dispatch_depth == 0 && st->input_len) {
        ENTER;
        SAVEINT(st->input_dispatch_depth);
        st->input_dispatch_depth++;
        les_process_existing_input(aTHX_ st, 1);
        LEAVE;
    }
    LEAVE;

void
_close(state_obj, consumer_event = 0)
    SV *state_obj
    UV consumer_event
  PREINIT:
    les_xsstate_t *st;
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    st = les_state_from_sv(state_obj);
    if (!st->closed) {
        st->closed = 1;
        les_clear_write_queue(st);
        les_discard_message_batch(st);
        st->input_start = 0;
        st->input_len = 0;
        les_consumer_flush_terminal(aTHX_ st);
        if (consumer_event)
            les_consumer_event(aTHX_ st, (uint32_t)consumer_event, 0, "");
    }
    LEAVE;

void
_close_read(state_obj, consumer_event = 0)
    SV *state_obj
    UV consumer_event
  PREINIT:
    les_xsstate_t *st;
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    st = les_state_from_sv(state_obj);
    if (!st->closed && !st->read_eof) {
        st->read_eof = 1;
        st->read_paused = 1;
        st->read_fd = -1;
        st->plain_transport.read_fd = -1;
        les_discard_message_batch(st);
        st->input_start = 0;
        st->input_len = 0;
        les_consumer_flush_terminal(aTHX_ st);
        if (consumer_event)
            les_consumer_event(aTHX_ st, (uint32_t)consumer_event, 0, "");
    }
    LEAVE;

void
_close_write(state_obj)
    SV *state_obj
  PREINIT:
    les_xsstate_t *st;
  CODE:
    st = les_state_from_sv(state_obj);
    if (!st->closed) {
        les_clear_write_queue(st);
        st->write_fd = -1;
        st->plain_transport.write_fd = -1;
    }

int
consumer_paused(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_state_from_sv(state_obj)->consumer_paused ? 1 : 0;
  OUTPUT:
    RETVAL

UV
_input_buffered_bytes(state_obj)
    SV *state_obj
  CODE:
    RETVAL = (UV)les_state_from_sv(state_obj)->input_len;
  OUTPUT:
    RETVAL

int
_consumer_resume(state_obj)
    SV *state_obj
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    RETVAL = les_consumer_resume(aTHX_ les_state_from_sv(state_obj));
    LEAVE;
  OUTPUT:
    RETVAL

int
is_read_eof(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_state_from_sv(state_obj)->read_eof ? 1 : 0;
  OUTPUT:
    RETVAL

UV
pending_bytes(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_state_from_sv(state_obj)->pending_bytes;
  OUTPUT:
    RETVAL

int
is_write_blocked(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_state_from_sv(state_obj)->write_blocked ? 1 : 0;
  OUTPUT:
    RETVAL

const char *
transport_name(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_state_from_sv(state_obj)->transport_ops->name;
  OUTPUT:
    RETVAL

int
transport_ready(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_transport_ready(les_state_from_sv(state_obj)) ? 1 : 0;
  OUTPUT:
    RETVAL

SV *
_stats_snapshot(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_state_stats_snapshot(aTHX_ les_state_from_sv(state_obj));
  OUTPUT:
    RETVAL

void
_test_consumer_arm(state_obj, callback = &PL_sv_undef)
    SV *state_obj
    SV *callback
  CODE:
    ENTER;
    SAVEFREESV(SvREFCNT_inc(state_obj));
    les_test_consumer_arm(aTHX_ les_state_from_sv(state_obj), callback);
    LEAVE;

void
_test_consumer_cancel(state_obj)
    SV *state_obj
  CODE:
    les_test_consumer_cancel(aTHX_ les_state_from_sv(state_obj));

SV *
_test_consumer_take(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_test_consumer_take(aTHX_ les_state_from_sv(state_obj));
  OUTPUT:
    RETVAL

SV *
_test_consumer_events(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_test_consumer_events(aTHX_ les_state_from_sv(state_obj));
  OUTPUT:
    RETVAL

SV *
_test_consumer_stats(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_test_consumer_stats(aTHX_ les_state_from_sv(state_obj));
  OUTPUT:
    RETVAL

SV *
_test_consumer_trace(state_obj)
    SV *state_obj
  CODE:
    RETVAL = les_test_consumer_trace(aTHX_ les_state_from_sv(state_obj));
  OUTPUT:
    RETVAL

MODULE = Linux::Event::_ByteStream    PACKAGE = Linux::Event::_ByteStream
PROTOTYPES: DISABLE

UV
_native_consumer_abi_version(CLASS)
    const char *CLASS
  CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = LES_CONSUMER_ABI_VERSION;
  OUTPUT:
    RETVAL

MODULE = Linux::Event::_ByteStream    PACKAGE = Linux::Event::_ByteStream::TestSupport
PROTOTYPES: DISABLE

SV *
_test_consumer_definition(CLASS, variant = "valid")
    const char *CLASS
    const char *variant
  CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = les_test_consumer_definition(aTHX_ variant);
  OUTPUT:
    RETVAL

UV
_test_consumer_destroy_count(CLASS)
    const char *CLASS
  CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = les_test_consumer_destroy_count();
  OUTPUT:
    RETVAL

UV
_test_consumer_last_destroy_flushes(CLASS)
    const char *CLASS
  CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = les_test_consumer_last_destroy_flushes();
  OUTPUT:
    RETVAL

int
_test_consumer_external_arm(object, callback)
    SV *object
    SV *callback
  CODE:
    RETVAL = les_test_consumer_external_arm(aTHX_ object, callback);
  OUTPUT:
    RETVAL

SV *
_test_consumer_transition_retain(object, callback)
    SV *object
    SV *callback
  CODE:
    RETVAL = les_test_consumer_transition_retain(aTHX_ object, callback);
  OUTPUT:
    RETVAL
