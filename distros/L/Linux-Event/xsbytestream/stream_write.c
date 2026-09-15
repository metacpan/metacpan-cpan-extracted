#include "stream_internal.h"

void
les_clear_write_queue(les_xsstate_t *st)
{
    les_write_seg_t *seg = st->whead;
    while (seg) {
        les_write_seg_t *next = seg->next;
        if (seg->sv)
            SvREFCNT_dec(seg->sv);
        free(seg);
        seg = next;
    }
    st->whead = NULL;
    st->wtail = NULL;
    st->pending_bytes = 0;
    st->write_blocked = 0;
}

void
les_queue_bytes(les_xsstate_t *st, const char *data, STRLEN len)
{
    les_write_seg_t *seg;

    if (len == 0)
        return;

    seg = (les_write_seg_t *)calloc(1, sizeof(*seg));
    if (!seg)
        croak("calloc Stream write segment failed");

    seg->sv = newSVpvn(data, len);
    seg->off = 0;
    seg->len = len;

    if (st->wtail)
        st->wtail->next = seg;
    else
        st->whead = seg;
    st->wtail = seg;

    st->pending_bytes += (UV)len;
    LES_STAT(st, queued_segments)++;
    if ((unsigned long long)st->pending_bytes > LES_STAT(st, queue_peak_bytes))
        LES_STAT(st, queue_peak_bytes) = (unsigned long long)st->pending_bytes;
}

void
les_consume_written(les_xsstate_t *st, size_t count)
{
    size_t remaining = count;

    while (remaining && st->whead) {
        les_write_seg_t *seg = st->whead;
        size_t avail = (size_t)(seg->len - seg->off);

        if (remaining < avail) {
            seg->off += (STRLEN)remaining;
            st->pending_bytes -= (UV)remaining;
            return;
        }

        remaining -= avail;
        st->pending_bytes -= (UV)avail;
        st->whead = seg->next;
        if (!st->whead)
            st->wtail = NULL;
        SvREFCNT_dec(seg->sv);
        free(seg);
    }
}

/*
 * Clear the blocked state before invoking on_drain.  If the callback writes
 * enough data to cross the high watermark again, _write() establishes a new
 * blocked interval and a later drain transition can fire normally.
 */
void
les_maybe_drain_transition(pTHX_ les_xsstate_t *st)
{
    if (!st->write_blocked)
        return;
    if (st->pending_bytes > st->low_watermark)
        return;

    st->write_blocked = 0;
    les_call_drain(aTHX_ st);
}

/*
 * Submit application bytes.  This function preserves write ordering: direct
 * write() is attempted only when no older bytes are queued.  Queued data is
 * copied into an owned segment only for the partial/EAGAIN path.
 */
int
les_write_submit(pTHX_ les_xsstate_t *st, SV *bytes_sv)
{
    STRLEN len;
    const char *data;
    STRLEN off = 0;

    if (!st || st->closed)
        return 0;

    data = SvPVbyte(bytes_sv, len);
    if (len == 0)
        return LES_WRITE_FLOW_OK;

    LES_STAT(st, write_submit_calls)++;

    if (st->pending_bytes == 0) {
        /*
         * Match the reference Stream's latency/fairness policy: make one
         * successful immediate write attempt.  EINTR is retried, but a partial
         * success queues the remainder instead of monopolizing the caller.
         */
        while (1) {
            les_transport_result_t result;

            LES_STAT(st, write_calls)++;
            result = les_transport_write(st, data, (size_t)len);

            if (st->transport_ops != &les_plain_transport_ops
                && result.status != LES_TRANSPORT_INTERRUPT) {
                les_call_transport_event(aTHX_ st, result.status, "write");
                if (result.status == LES_TRANSPORT_ERROR)
                    return 0;
            }

            if (result.status == LES_TRANSPORT_OK && result.count > 0) {
                off = (STRLEN)result.count;
                LES_STAT(st, bytes_written) += (unsigned long long)result.count;
                les_note_write_activity(aTHX_ st);
                break;
            }

            if (result.status == LES_TRANSPORT_EOF)
                break;

            if (result.status == LES_TRANSPORT_INTERRUPT) {
                LES_STAT(st, write_eintr_count)++;
                continue;
            }

            if (result.status == LES_TRANSPORT_WANT_READ
                || result.status == LES_TRANSPORT_WANT_WRITE) {
                LES_STAT(st, write_eagain_count)++;
                break;
            }

            {
                int err = result.error;
                LES_STAT(st, write_error_count)++;
                les_call_write_error(aTHX_ st, err);
                return 0;
            }
        }

        if (off == len)
            return LES_WRITE_FLOW_OK;
    }

    if (!st->closed && off < len) {
        UV remaining = (UV)(len - off);
        UV limit = st->max_pending_bytes;

        /* Lowering max_pending_bytes never discards an existing queue. While
         * the queue is above the new limit, any operation that would grow it
         * fails until ordinary draining brings it back below the limit. */
        if (limit && (remaining > limit
            || st->pending_bytes > limit - remaining)) {
            UV attempted = st->pending_bytes;
            if (UV_MAX - attempted < remaining)
                attempted = UV_MAX;
            else
                attempted += remaining;
            les_call_output_limit(aTHX_ st, attempted);
            return 0;
        }
        les_queue_bytes(st, data + off, len - off);
    }

    if (!st->write_blocked && st->pending_bytes > st->high_watermark)
        st->write_blocked = 1;

    return (st->write_blocked ? 0 : LES_WRITE_FLOW_OK)
         | (st->pending_bytes ? LES_WRITE_QUEUED : 0);
}

void
les_write_ready(pTHX_ les_xsstate_t *st)
{
    int had_pending;

    if (!st || st->closed)
        return;

    had_pending = st->pending_bytes ? 1 : 0;
    if (!had_pending) {
        if (st->transport_ops != &les_plain_transport_ops) {
            if (les_drive_transport(aTHX_ st, "handshake"))
                les_call_transport_event(aTHX_ st, LES_TRANSPORT_OK,
                    "handshake");
        }
        return;
    }

    LES_STAT(st, write_ready_calls)++;

    while (!st->closed && st->pending_bytes > 0) {
        struct iovec iov[LES_IOV_MAX];
        les_write_seg_t *seg;
        int iovcnt = 0;
        les_transport_result_t result;

        for (seg = st->whead; seg && iovcnt < LES_IOV_MAX; seg = seg->next) {
            STRLEN pvlen;
            const char *pv = SvPV(seg->sv, pvlen);
            STRLEN avail = seg->len - seg->off;

            if (seg->off > pvlen || avail > pvlen - seg->off)
                croak("internal Stream write segment bounds corrupted");

            iov[iovcnt].iov_base = (void *)(pv + seg->off);
            iov[iovcnt].iov_len = (size_t)avail;
            iovcnt++;
        }

        if (iovcnt == 0)
            break;

        LES_STAT(st, writev_calls)++;
        result = les_transport_writev(st, iov, iovcnt);

        if (st->transport_ops != &les_plain_transport_ops
            && result.status != LES_TRANSPORT_INTERRUPT) {
            les_call_transport_event(aTHX_ st, result.status, "write");
            if (result.status == LES_TRANSPORT_ERROR)
                return;
        }

        if (result.status == LES_TRANSPORT_OK && result.count > 0) {
            LES_STAT(st, bytes_written) += (unsigned long long)result.count;
            les_note_write_activity(aTHX_ st);
            les_consume_written(st, (size_t)result.count);
            les_maybe_drain_transition(aTHX_ st);
            continue;
        }

        if (result.status == LES_TRANSPORT_EOF)
            return;

        if (result.status == LES_TRANSPORT_INTERRUPT) {
            LES_STAT(st, write_eintr_count)++;
            continue;
        }

        if (result.status == LES_TRANSPORT_WANT_READ
            || result.status == LES_TRANSPORT_WANT_WRITE) {
            LES_STAT(st, write_eagain_count)++;
            return;
        }

        {
            int err = result.error;
            LES_STAT(st, write_error_count)++;
            les_call_write_error(aTHX_ st, err);
            return;
        }
    }

    if (!st->closed && had_pending && st->pending_bytes == 0) {
        les_maybe_drain_transition(aTHX_ st);
        if (!st->closed)
            les_call_empty(aTHX_ st);
    }
}
