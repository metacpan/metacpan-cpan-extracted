#include "stream_internal.h"

const char *
les_input_data(const les_xsstate_t *st)
{
    return st->input_buffer ? st->input_buffer + st->input_start : NULL;
}

int
les_input_reserve(les_xsstate_t *st, size_t extra)
{
    size_t need;
    size_t cap;
    char *next;

    if (extra == 0)
        return 1;
    if (extra > (size_t)-1 - st->input_len)
        croak("Stream input buffer size overflow");
    need = st->input_len + extra;

    if (st->input_buffer && st->input_start + need <= st->input_cap)
        return 1;

    if (st->input_buffer && need <= st->input_cap) {
        if (st->input_len)
            memmove(st->input_buffer, st->input_buffer + st->input_start, st->input_len);
        st->input_start = 0;
        LES_STAT(st, input_compactions)++;
        return 1;
    }

    cap = st->input_cap ? st->input_cap : 4096;
    while (cap < need) {
        size_t grown = cap < ((size_t)-1 / 2) ? cap * 2 : need;
        if (grown < cap || grown < need)
            grown = need;
        cap = grown;
    }

    next = (char *)malloc(cap);
    if (!next)
        croak("malloc Stream input buffer failed");
    if (st->input_len)
        memcpy(next, les_input_data(st), st->input_len);
    free(st->input_buffer);
    st->input_buffer = next;
    st->input_cap = cap;
    st->input_start = 0;
    return 1;
}

void
les_input_consume(les_xsstate_t *st, size_t count)
{
    if (count > st->input_len)
        croak("internal Stream input consume exceeds buffered bytes");
    st->input_start += count;
    st->input_len -= count;
    st->delimiter_scan = 0;
    if (st->input_len == 0)
        st->input_start = 0;
}

void
les_process_buffered(pTHX_ les_xsstate_t *st)
{
    if (st->descriptor->read_mode == LES_READ_DELIMITER)
        les_process_delimiter(aTHX_ st);
    else if (st->descriptor->read_mode == LES_READ_FIXED)
        les_process_fixed(aTHX_ st);
    else if (st->descriptor->read_mode == LES_READ_LENGTH)
        les_process_length(aTHX_ st);
    else if (st->descriptor->read_mode == LES_READ_NETSTRING)
        les_process_netstring(aTHX_ st);
    else if (st->descriptor->read_mode == LES_READ_VARINT)
        les_process_varint(aTHX_ st);
    else if (st->descriptor->read_mode == LES_READ_DECIMAL)
        les_process_decimal_length(aTHX_ st);
}

void
les_process_existing_input(pTHX_ les_xsstate_t *st, int flush_batch)
{
    while (!st->closed && !LES_INPUT_PAUSED(st) && !st->read_eof
        && st->input_len) {
        les_descriptor_t *descriptor = st->descriptor;

        if (descriptor->read_mode == LES_READ_DELIVER) {
            if (st->read_batch_bytes) {
                les_flush_raw_batch(aTHX_ st);
            } else {
                const char *data = les_input_data(st);
                size_t len = st->input_len;
                SV *bytes = sv_2mortal(newSVpvn(data, (STRLEN)len));
                les_input_consume(st, len);
                les_call_deliver(aTHX_ st, bytes);
            }
        } else {
            int was_consumer_paused = st->consumer_paused;
            les_process_buffered(aTHX_ st);
            if (st->descriptor != descriptor) {
                les_consumer_flush(aTHX_ st);
                continue;
            }
            if (flush_batch) {
                les_flush_message_batch(aTHX_ st);
                les_consumer_flush(aTHX_ st);
            }
            if (les_consumer_resumed_with_buffered_input(
                    st, was_consumer_paused))
                continue;
        }
        if (st->descriptor != descriptor)
            continue;
        if (descriptor->read_mode == LES_READ_DELIVER
            && st->read_batch_bytes && st->input_len)
            continue;
        return;
    }
}
