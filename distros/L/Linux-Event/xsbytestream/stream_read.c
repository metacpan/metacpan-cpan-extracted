#include "stream_internal.h"

static void
les_flush_framed_read_boundary(pTHX_ les_xsstate_t *st)
{
    int was_consumer_paused = st->consumer_paused;

    les_flush_message_batch(aTHX_ st);
    les_consumer_flush(aTHX_ st);
    if (les_consumer_resumed_with_buffered_input(st, was_consumer_paused))
        les_process_existing_input(aTHX_ st, 1);
}

static int
les_settle_read_boundary(pTHX_ les_xsstate_t *st,
    les_descriptor_t *descriptor)
{
    if (descriptor->read_mode == LES_READ_DELIVER)
        les_flush_raw_batch(aTHX_ st);
    else
        les_flush_framed_read_boundary(aTHX_ st);
    return !st->closed && !LES_INPUT_PAUSED(st)
        && st->descriptor != descriptor;
}

void
les_read_ready(pTHX_ les_xsstate_t *st)
{
    if (!st || st->closed || st->read_eof)
        return;

    if (st->transport_ops != &les_plain_transport_ops
        && !les_drive_transport(aTHX_ st, "handshake"))
        return;
    if (LES_INPUT_PAUSED(st)) {
        if (st->transport_ops != &les_plain_transport_ops) {
            if (st->pending_bytes)
                les_write_ready(aTHX_ st);
            if (!st->closed)
                les_call_transport_event(aTHX_ st, LES_TRANSPORT_OK,
                    "progress");
        }
        return;
    }

    ENTER;
    SAVEINT(st->input_dispatch_depth);
    st->input_dispatch_depth++;
    LES_STAT(st, read_ready_calls)++;

    size_t drain_bytes = 0;

    while (!st->closed && !LES_INPUT_PAUSED(st) && !st->read_eof) {
        les_transport_result_t result;
        char *target;
        size_t want;

        if (st->descriptor->read_mode != LES_READ_DELIVER
            || !st->read_batch_bytes)
            les_process_existing_input(aTHX_ st, 0);
        if (st->closed || LES_INPUT_PAUSED(st) || st->read_eof)
            break;

        if (st->read_budget_bytes
            && drain_bytes >= (size_t)st->read_budget_bytes)
            break;

        want = st->read_size;
        if (st->read_budget_bytes
            && want > (size_t)st->read_budget_bytes - drain_bytes)
            want = (size_t)st->read_budget_bytes - drain_bytes;

        if (st->descriptor->read_mode == LES_READ_DELIVER) {
            if (st->read_batch_bytes) {
                UV remaining;

                if ((UV)st->input_len >= st->read_batch_bytes) {
                    les_flush_raw_batch(aTHX_ st);
                    continue;
                }
                remaining = st->read_batch_bytes - (UV)st->input_len;
                if ((UV)want > remaining)
                    want = (size_t)remaining;
                les_input_reserve(st, want);
                target = st->input_buffer + st->input_start + st->input_len;
            } else {
                target = st->read_buffer;
            }
        } else {
            if (st->max_buffer) {
                if (st->input_len >= st->max_buffer) {
                    char msg[128];
                    snprintf(msg, sizeof(msg), "input buffer cannot grow beyond max_buffer=%llu",
                        (unsigned long long)st->max_buffer);
                    les_call_framing_error(aTHX_ st, msg);
                    break;
                }
                if ((UV)want > st->max_buffer - (UV)st->input_len)
                    want = (size_t)(st->max_buffer - (UV)st->input_len);
            }
            les_input_reserve(st, want);
            target = st->input_buffer + st->input_start + st->input_len;
        }

        LES_STAT(st, read_calls)++;
        result = les_transport_read(st, target, want);

        if (st->transport_ops != &les_plain_transport_ops
            && result.status != LES_TRANSPORT_INTERRUPT)
            les_call_transport_event(aTHX_ st, result.status, "read");

        if (result.status == LES_TRANSPORT_OK && result.count > 0) {
            LES_STAT(st, bytes_read) += (unsigned long long)result.count;
            drain_bytes += (size_t)result.count;
            les_note_read_activity(aTHX_ st);

            if (st->descriptor->read_mode == LES_READ_DELIVER) {
                if (st->read_batch_bytes) {
                    st->input_len += (size_t)result.count;
                    if ((UV)st->input_len >= st->read_batch_bytes)
                        les_flush_raw_batch(aTHX_ st);
                } else {
                    SV *bytes = sv_2mortal(newSVpvn(
                        st->read_buffer, (STRLEN)result.count));
                    les_call_deliver(aTHX_ st, bytes);
                }
            } else {
                st->input_len += (size_t)result.count;
                LES_STAT(st, input_appends)++;
                if ((unsigned long long)st->input_len > LES_STAT(st, input_peak_bytes))
                    LES_STAT(st, input_peak_bytes) = (unsigned long long)st->input_len;
            }
            continue;
        }

        if (result.status == LES_TRANSPORT_EOF) {
            les_descriptor_t *descriptor = st->descriptor;
            if (les_settle_read_boundary(aTHX_ st, descriptor))
                continue;
            if (st->closed || LES_INPUT_PAUSED(st))
                break;
            st->read_eof = 1;
            LES_STAT(st, eof_count)++;
            les_call_eof(aTHX_ st);
            break;
        }

        if (result.status == LES_TRANSPORT_INTERRUPT) {
            LES_STAT(st, read_eintr_count)++;
            continue;
        }

        if (result.status == LES_TRANSPORT_WANT_READ
            || result.status == LES_TRANSPORT_WANT_WRITE) {
            les_descriptor_t *descriptor = st->descriptor;
            LES_STAT(st, read_eagain_count)++;
            if (les_settle_read_boundary(aTHX_ st, descriptor))
                continue;
            break;
        }

        {
            int err = result.error;
            les_descriptor_t *descriptor = st->descriptor;
            LES_STAT(st, read_error_count)++;
            if (les_settle_read_boundary(aTHX_ st, descriptor))
                continue;
            if (st->closed || LES_INPUT_PAUSED(st))
                break;
            les_call_read_error(aTHX_ st, err);
            break;
        }
    }

    if (!st->closed && st->descriptor->read_mode != LES_READ_DELIVER)
        les_flush_framed_read_boundary(aTHX_ st);

    LEAVE;

    if (!st->closed && st->transport_ops != &les_plain_transport_ops
        && st->pending_bytes)
        les_write_ready(aTHX_ st);
    if (!st->closed && st->transport_ops != &les_plain_transport_ops)
        les_call_transport_event(aTHX_ st, LES_TRANSPORT_OK, "progress");
}
