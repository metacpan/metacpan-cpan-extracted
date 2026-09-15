#include "stream_internal.h"

les_xsstate_t *
les_state_from_sv(SV *sv)
{
    if (!sv_isobject(sv) || !SvROK(sv))
        croak("not a Linux::Event::_ByteStream::State object");
    return INT2PTR(les_xsstate_t *, SvIV((SV *)SvRV(sv)));
}

les_descriptor_t *
les_descriptor_from_sv(SV *sv)
{
    if (!sv_isobject(sv) || !SvROK(sv))
        croak("not a Linux::Event::_ByteStream::Descriptor::Native object");
    return INT2PTR(les_descriptor_t *, SvIV((SV *)SvRV(sv)));
}

SV *
les_store_cb(SV *cb, const char *name)
{
    SV *cv;
    if (!cb || !SvOK(cb) || !SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV)
        croak("%s must be a coderef", name);
    cv = SvRV(cb);
    SvREFCNT_inc(cv);
    return cv;
}

SV *
les_store_optional_cb(SV *cb, const char *name)
{
    if (!cb || !SvOK(cb))
        return NULL;
    return les_store_cb(cb, name);
}

int
les_descriptor_input_kind(const les_descriptor_t *descriptor)
{
    if (!descriptor)
        return LES_CALLBACK_NONE;
    if (descriptor->read_mode == LES_READ_DELIVER)
        return LES_CALLBACK_DATA;
    return descriptor->message_batch_size
        ? LES_CALLBACK_MESSAGES : LES_CALLBACK_MESSAGE;
}

SV *
les_descriptor_input_cb(const les_descriptor_t *descriptor)
{
    int kind = les_descriptor_input_kind(descriptor);
    if (kind == LES_CALLBACK_DATA)
        return descriptor->deliver_cb;
    if (kind == LES_CALLBACK_MESSAGES)
        return descriptor->message_batch_cb;
    if (kind == LES_CALLBACK_MESSAGE)
        return descriptor->message_cb;
    return NULL;
}

SV *
les_state_stats_snapshot(pTHX_ les_xsstate_t *st)
{
    AV *values = newAV();

    av_extend(values, 48);
#define LES_PUSH_STAT(name) av_push(values, newSVuv((UV)LES_STAT(st, name)))
    LES_PUSH_STAT(activity_clock_calls);
    LES_PUSH_STAT(read_ready_calls);
    LES_PUSH_STAT(read_calls);
    LES_PUSH_STAT(bytes_read);
    LES_PUSH_STAT(read_eagain_count);
    LES_PUSH_STAT(read_eintr_count);
    LES_PUSH_STAT(eof_count);
    LES_PUSH_STAT(read_error_count);
    LES_PUSH_STAT(delivery_calls);
    LES_PUSH_STAT(read_batch_flushes);
    LES_PUSH_STAT(read_batch_peak_bytes);
    LES_PUSH_STAT(input_appends);
    LES_PUSH_STAT(input_compactions);
    LES_PUSH_STAT(input_peak_bytes);
    LES_PUSH_STAT(delimiter_searches);
    LES_PUSH_STAT(frames_emitted);
    LES_PUSH_STAT(message_callback_calls);
    LES_PUSH_STAT(message_batch_calls);
    LES_PUSH_STAT(message_batch_peak_messages);
    LES_PUSH_STAT(message_batch_peak_bytes);
    LES_PUSH_STAT(framing_error_count);
    LES_PUSH_STAT(transition_count);
    LES_PUSH_STAT(consumer_message_calls);
    LES_PUSH_STAT(consumer_pause_count);
    LES_PUSH_STAT(consumer_resume_count);
    LES_PUSH_STAT(consumer_event_calls);
    LES_PUSH_STAT(consumer_flush_calls);
    LES_PUSH_STAT(write_submit_calls);
    LES_PUSH_STAT(write_ready_calls);
    LES_PUSH_STAT(write_calls);
    LES_PUSH_STAT(writev_calls);
    LES_PUSH_STAT(bytes_written);
    LES_PUSH_STAT(write_eagain_count);
    LES_PUSH_STAT(write_eintr_count);
    LES_PUSH_STAT(write_error_count);
    LES_PUSH_STAT(output_limit_count);
    LES_PUSH_STAT(queued_segments);
    LES_PUSH_STAT(queue_peak_bytes);
    LES_PUSH_STAT(drain_calls);
    LES_PUSH_STAT(empty_calls);
#undef LES_PUSH_STAT
    av_push(values, newSVuv(st->read_budget_bytes));
    av_push(values, newSVuv(st->read_batch_bytes));
    av_push(values, newSVuv(st->message_batch_size));
    av_push(values, newSVuv(st->input_len));
    av_push(values, newSViv(st->consumer_flush_pending ? 1 : 0));
    av_push(values, newSViv(st->consumer_paused ? 1 : 0));
    av_push(values, newSVuv(st->pending_bytes));
    av_push(values, newSViv(st->write_blocked ? 1 : 0));
    av_push(values, newSViv(st->activity_tracking ? 1 : 0));

    return newRV_noinc((SV *)values);
}

void
les_state_destroy(pTHX_ les_xsstate_t *st)
{
    if (!st)
        return;
    les_clear_write_queue(st);
    les_discard_message_batch(st);
    les_consumer_destroy(aTHX_ st);
    if (st->stream_sv) SvREFCNT_dec(st->stream_sv);
    if (st->descriptor_sv) SvREFCNT_dec(st->descriptor_sv);
    if (st->input_cb && st->input_cb != st->instance_input_cb)
        SvREFCNT_dec(st->input_cb);
    if (st->instance_input_cb) SvREFCNT_dec(st->instance_input_cb);
    if (st->drain_cb) SvREFCNT_dec(st->drain_cb);
    if (st->transport_provider_sv) SvREFCNT_dec(st->transport_provider_sv);
    free(st->read_buffer);
    free(st->input_buffer);
    free(st);
}
