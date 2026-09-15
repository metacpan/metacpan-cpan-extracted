#include "stream_internal.h"

static SV *
les_tuning_value(pTHX_ HV *tuning, const char *key)
{
    SV **slot = hv_fetch(tuning, key, (I32)strlen(key), 0);
    if (!slot)
        croak("tune(): missing validated tuning field '%s'", key);
    return *slot;
}

static UV
les_tuning_uv(pTHX_ HV *tuning, const char *key)
{
    SV *value = les_tuning_value(aTHX_ tuning, key);
    return SvUV(value);
}

static void
les_apply_tuning(pTHX_ les_xsstate_t *st, HV *tuning)
{
    les_descriptor_t *descriptor = st->descriptor;
    UV read_size = les_tuning_uv(aTHX_ tuning, "read_size");
    UV read_budget_bytes = les_tuning_uv(aTHX_ tuning, "read_budget_bytes");
    UV read_batch_bytes = les_tuning_uv(aTHX_ tuning, "read_batch_bytes");
    UV message_batch_size = les_tuning_uv(aTHX_ tuning, "message_batch_size");
    UV high_watermark = les_tuning_uv(aTHX_ tuning, "high_watermark");
    UV low_watermark = les_tuning_uv(aTHX_ tuning, "low_watermark");
    UV max_pending_bytes = les_tuning_uv(aTHX_ tuning, "max_pending_bytes");
    UV max_buffer = les_tuning_uv(aTHX_ tuning, "max_buffer");
    SV **input_slot = hv_fetch(tuning, "input_cb", 8, 0);
    SV *input_cb_sv = input_slot ? *input_slot : NULL;
    SV *next_input_cb = NULL;
    SV *old_input_cb;
    SV *old_instance_input_cb;
    char *next_read_buffer = NULL;
    int replace_input_cb = input_slot ? 1 : 0;
    int fire_drain = 0;
    int was_blocked;

    if (!read_size || read_size > (UV)(size_t)-1)
        croak("tune(): read_size is outside the native size_t range");
    if (read_budget_bytes > (UV)(size_t)-1)
        croak("tune(): read_budget_bytes exceeds native size_t");
    if (read_batch_bytes > (UV)(size_t)-1)
        croak("tune(): read_batch_bytes exceeds native size_t");
    if (!max_buffer)
        croak("tune(): max_buffer must be > 0");
    if (low_watermark > high_watermark)
        croak("tune(): low_watermark must be <= high_watermark");
    if (descriptor->read_mode == LES_READ_DELIVER && message_batch_size)
        croak("tune(): message_batch_size requires a framed Stream");
    if (descriptor->read_mode != LES_READ_DELIVER && read_batch_bytes)
        croak("tune(): read_batch_bytes requires a raw Stream");
    if (descriptor->consumer_ops && message_batch_size)
        croak("tune(): native consumer cannot use message_batch_size");
    if (descriptor->consumer_ops && replace_input_cb
        && input_cb_sv && SvOK(input_cb_sv))
        croak("tune(): native consumer cannot use a Perl input callback");
    if (message_batch_size != st->message_batch_size
        && descriptor->read_mode != LES_READ_DELIVER
        && !descriptor->consumer_ops && !replace_input_cb)
        croak("tune(): changing message_batch_size requires an effective input callback");
    if (replace_input_cb && st->read_fd >= 0 && !descriptor->consumer_ops
        && (!input_cb_sv || !SvOK(input_cb_sv)))
        croak("tune(): readable Stream requires an effective input callback");

    /* A change in batching policy settles work owned by the old policy before
     * any new callback or threshold becomes visible. */
    if (st->message_batch_count
        && message_batch_size != st->message_batch_size) {
        les_flush_message_batch(aTHX_ st);
        if (st->closed)
            return;
        if (st->descriptor != descriptor)
            croak("tune(): Stream protocol changed while flushing a message batch");
    }
    if (descriptor->read_mode == LES_READ_DELIVER && st->input_len
        && st->read_batch_bytes
        && read_batch_bytes != st->read_batch_bytes) {
        les_flush_raw_batch(aTHX_ st);
        if (st->closed)
            return;
        if (st->descriptor != descriptor)
            croak("tune(): Stream protocol changed while flushing a raw batch");
    }

    if (st->read_fd >= 0 && descriptor->read_mode == LES_READ_DELIVER
        && (size_t)read_size != st->read_size) {
        next_read_buffer = (char *)malloc((size_t)read_size);
        if (!next_read_buffer)
            croak("tune(): malloc raw read buffer failed");
    }

    if (replace_input_cb)
        next_input_cb = les_store_optional_cb(input_cb_sv,
            "tune() input callback");

    if (next_read_buffer) {
        free(st->read_buffer);
        st->read_buffer = next_read_buffer;
    }

    if (replace_input_cb) {
        old_input_cb = st->input_cb;
        old_instance_input_cb = st->instance_input_cb;
        st->input_cb = next_input_cb;
        st->instance_input_cb = NULL;
        st->instance_input_kind = LES_CALLBACK_NONE;
        if (old_input_cb && old_input_cb != old_instance_input_cb)
            SvREFCNT_dec(old_input_cb);
        if (old_instance_input_cb)
            SvREFCNT_dec(old_instance_input_cb);
    }

    was_blocked = st->write_blocked;
    st->read_size = (size_t)read_size;
    st->read_budget_bytes = read_budget_bytes;
    st->read_batch_bytes = read_batch_bytes;
    st->message_batch_size = message_batch_size;
    st->high_watermark = high_watermark;
    st->low_watermark = low_watermark;
    st->max_pending_bytes = max_pending_bytes;
    st->max_buffer = max_buffer;

    if (was_blocked) {
        if (st->pending_bytes <= st->low_watermark) {
            st->write_blocked = 0;
            fire_drain = 1;
        } else {
            st->write_blocked = 1;
        }
    } else {
        st->write_blocked = st->pending_bytes > st->high_watermark;
    }

    if (fire_drain && !st->closed)
        les_call_drain(aTHX_ st);
}

/*
 * Swap immutable protocol/type configuration. The connection fd,
 * watcher-owned XSState, queued output, application object, instrumentation,
 * pause/EOF state, and unread native input remain connection-local and live.
 * A same-descriptor call with a hash reference is reserved for validated
 * construction/live tuning and changes only connection-local operating state.
 */
void
les_transition_descriptor(pTHX_ les_xsstate_t *st, SV *descriptor_obj,
    SV *input_sv)
{
    les_descriptor_t *next_descriptor;
    SV *next_descriptor_sv;
    SV *old_descriptor_sv;
    SV *next_input_cb = NULL;
    SV *old_input_cb;
    SV *next_drain_cb = NULL;
    SV *old_drain_cb;
    const char *injected = NULL;
    STRLEN injected_len = 0;
    size_t total_input;
    char *next_input_buffer = NULL;
    size_t next_input_cap = 0;
    char *next_read_buffer = NULL;

    if (!st || st->closed)
        croak("transition_to(): stream is closed");

    next_descriptor = les_descriptor_from_sv(descriptor_obj);
    if (!next_descriptor)
        croak("transition_to(): target descriptor is closed");

    if (next_descriptor == st->descriptor && input_sv && SvROK(input_sv)
        && SvTYPE(SvRV(input_sv)) == SVt_PVHV) {
        les_apply_tuning(aTHX_ st, (HV *)SvRV(input_sv));
        return;
    }

    if (input_sv && SvOK(input_sv))
        injected = SvPVbyte(input_sv, injected_len);
    if ((size_t)injected_len > (size_t)-1 - st->input_len)
        croak("transition_to(): input size overflow");
    total_input = st->input_len + (size_t)injected_len;

    /* Allocate every replacement before mutating live state. A failed
     * transition therefore leaves the old descriptor and buffers intact. */
    if (next_descriptor->read_mode == LES_READ_DELIVER) {
        next_read_buffer = (char *)malloc(next_descriptor->read_size);
        if (!next_read_buffer)
            croak("transition_to(): malloc raw read buffer failed");
    }

    if (injected_len) {
        next_input_cap = total_input < 4096 ? 4096 : total_input;
        next_input_buffer = (char *)malloc(next_input_cap);
        if (!next_input_buffer) {
            free(next_read_buffer);
            croak("transition_to(): malloc preserved input buffer failed");
        }
        if (st->input_len)
            memcpy(next_input_buffer, les_input_data(st), st->input_len);
        memcpy(next_input_buffer + st->input_len, injected,
            (size_t)injected_len);
    }

    next_descriptor_sv = newSVsv(descriptor_obj);
    old_descriptor_sv = st->descriptor_sv;
    old_input_cb = st->input_cb;
    if (st->instance_input_kind == les_descriptor_input_kind(next_descriptor)) {
        next_input_cb = st->instance_input_cb;
    } else {
        SV *descriptor_cb = les_descriptor_input_cb(next_descriptor);
        if (descriptor_cb)
            next_input_cb = SvREFCNT_inc_simple_NN(descriptor_cb);
    }
    old_drain_cb = st->drain_cb;
    next_drain_cb = st->has_instance_drain_cb
        ? old_drain_cb
        : next_descriptor->drain_cb
            ? SvREFCNT_inc_simple_NN(next_descriptor->drain_cb) : NULL;

    if (injected_len) {
        free(st->input_buffer);
        st->input_buffer = next_input_buffer;
        st->input_cap = next_input_cap;
        st->input_start = 0;
        st->input_len = total_input;
        LES_STAT(st, input_appends)++;
        if ((unsigned long long)st->input_len > LES_STAT(st, input_peak_bytes))
            LES_STAT(st, input_peak_bytes) = (unsigned long long)st->input_len;
    }

    free(st->read_buffer);
    st->read_buffer = next_read_buffer;
    st->descriptor = next_descriptor;
    st->descriptor_sv = next_descriptor_sv;
    st->input_cb = next_input_cb;
    st->drain_cb = next_drain_cb;
    st->delimiter_scan = 0;

    st->read_size = next_descriptor->read_size;
    st->read_budget_bytes = next_descriptor->read_budget_bytes;
    st->read_batch_bytes = next_descriptor->read_batch_bytes;
    st->message_batch_size = next_descriptor->message_batch_size;
    st->high_watermark = next_descriptor->high_watermark;
    st->low_watermark = next_descriptor->low_watermark;
    st->max_pending_bytes = next_descriptor->max_pending_bytes;
    st->max_buffer = next_descriptor->max_buffer;
    st->write_blocked = st->pending_bytes > st->high_watermark;
    LES_STAT(st, transition_count)++;

    if (old_descriptor_sv)
        SvREFCNT_dec(old_descriptor_sv);
    if (old_input_cb && old_input_cb != st->instance_input_cb)
        SvREFCNT_dec(old_input_cb);
    if (!st->has_instance_drain_cb && old_drain_cb)
        SvREFCNT_dec(old_drain_cb);
}
