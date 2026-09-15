#include "stream_internal.h"

void
les_discard_message_batch(les_xsstate_t *st)
{
    if (!st || !st->message_batch)
        return;
    SvREFCNT_dec((SV *)st->message_batch);
    st->message_batch = NULL;
    st->message_batch_count = 0;
    st->message_batch_bytes = 0;
}

void
les_flush_message_batch(pTHX_ les_xsstate_t *st)
{
    AV *batch;
    SV *batch_rv;
    SV *callback;
    UV count;

    if (!st || !st->message_batch || st->message_batch_count == 0)
        return;

    batch = st->message_batch;
    count = st->message_batch_count;
    callback = st->input_cb;
    st->message_batch = NULL;
    st->message_batch_count = 0;
    st->message_batch_bytes = 0;

    batch_rv = sv_2mortal(newRV_noinc((SV *)batch));
    LES_STAT(st, message_batch_calls)++;
    if (count > LES_STAT(st, message_batch_peak_messages))
        LES_STAT(st, message_batch_peak_messages) = count;
    les_call_two(aTHX_ callback, st->stream_sv, batch_rv);
}

void
les_emit_message(pTHX_ les_xsstate_t *st, SV *message)
{
    UV bytes;

    LES_STAT(st, frames_emitted)++;
    if (st->consumer_ops) {
        les_consumer_message(aTHX_ st, message);
        return;
    }
    if (!st->message_batch_size) {
        LES_STAT(st, message_callback_calls)++;
        les_call_two(aTHX_ st->input_cb, st->stream_sv, message);
        return;
    }

    if (!st->message_batch)
        st->message_batch = newAV();
    bytes = (UV)SvCUR(message);
    av_push(st->message_batch, SvREFCNT_inc_simple_NN(message));
    st->message_batch_count++;
    if (bytes > (UV)-1 - st->message_batch_bytes)
        st->message_batch_bytes = (UV)-1;
    else
        st->message_batch_bytes += bytes;
    if (st->message_batch_bytes > LES_STAT(st, message_batch_peak_bytes))
        LES_STAT(st, message_batch_peak_bytes) = st->message_batch_bytes;

    if (st->message_batch_count >= st->message_batch_size
        || st->message_batch_bytes >= st->max_buffer)
        les_flush_message_batch(aTHX_ st);
}

void
les_flush_raw_batch(pTHX_ les_xsstate_t *st)
{
    const char *data;
    size_t len;
    SV *bytes;

    if (!st || !st->input_len || st->descriptor->read_mode != LES_READ_DELIVER
        || !st->read_batch_bytes)
        return;

    data = les_input_data(st);
    len = st->input_len;
    if ((UV)len > st->read_batch_bytes)
        len = (size_t)st->read_batch_bytes;
    bytes = sv_2mortal(newSVpvn(data, (STRLEN)len));
    les_input_consume(st, len);
    LES_STAT(st, read_batch_flushes)++;
    if ((unsigned long long)len > LES_STAT(st, read_batch_peak_bytes))
        LES_STAT(st, read_batch_peak_bytes) = (unsigned long long)len;
    les_call_deliver(aTHX_ st, bytes);
}
