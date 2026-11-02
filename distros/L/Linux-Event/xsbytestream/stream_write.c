#define _GNU_SOURCE
#include "stream_internal.h"
#include <fcntl.h>
#include <limits.h>
#include <pthread.h>
#include <signal.h>
#include <sys/sendfile.h>
#include <sys/stat.h>

#define LES_FILE_DRAIN_BUDGET 65536U
#define LES_SENDFILE_SYSCALL_MAX 0x7ffff000U

/*
 * Linux sendfile() has no MSG_NOSIGNAL flag. Mask SIGPIPE only around this
 * syscall, consume a newly generated EPIPE signal, and restore the original
 * thread mask. Never change the process-global signal disposition.
 */
static ssize_t
les_safe_sendfile(int output, int input, off_t *offset, size_t length)
{
    sigset_t mask, old_mask, pending;
    struct timespec zero = { 0, 0 };
    int mask_error, already_pending, saved_errno;
    ssize_t result;

    sigemptyset(&mask);
    sigaddset(&mask, SIGPIPE);
    mask_error = pthread_sigmask(SIG_BLOCK, &mask, &old_mask);
    if (mask_error) {
        errno = mask_error;
        return -1;
    }
    already_pending = sigpending(&pending) == 0
        && sigismember(&pending, SIGPIPE) == 1;
    result = sendfile(output, input, offset, length);
    saved_errno = errno;
    if (result < 0 && saved_errno == EPIPE && !already_pending)
        (void)sigtimedwait(&mask, NULL, &zero);
    (void)pthread_sigmask(SIG_SETMASK, &old_mask, NULL);
    errno = saved_errno;
    return result;
}

static void
les_release_write_seg(les_xsstate_t *st, les_write_seg_t *seg)
{
    if (seg->sv) {
        SvREFCNT_dec(seg->sv);
    } else {
        les_file_seg_t *file = (les_file_seg_t *)seg;
        (void)close(file->fd);
        if (st->file_segments)
            st->file_segments--;
    }
    free(seg);
}


void
les_clear_write_queue(les_xsstate_t *st)
{
    les_write_seg_t *seg = st->whead;
    while (seg) {
        les_write_seg_t *next = seg->next;
        les_release_write_seg(st, seg);
        seg = next;
    }
    st->whead = NULL;
    st->wtail = NULL;
    st->pending_bytes = 0;
    st->file_segments = 0;
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
        les_release_write_seg(st, seg);
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

/*
 * Accept a fixed regular-file range. File segments embed the same byte
 * header so ordinary write() allocations and the immediate path do not grow.
 * The explicit sendfile offset never changes the caller's file position.
 */
int
les_sendfile_submit(pTHX_ les_xsstate_t *st, int source_fd,
    UV offset, int has_length, UV length)
{
    struct stat info;
    les_file_seg_t *file;
    UV size, remaining, attempted;
    int owned_fd;

    if (!st || st->closed)
        return 0;
    if (st->transport_ops != &les_plain_transport_ops)
        croak("sendfile(): requires a plain transport");
    if (st->write_fd < 0)
        croak("sendfile(): writable side has ended");

#ifdef F_DUPFD_CLOEXEC
    owned_fd = fcntl(source_fd, F_DUPFD_CLOEXEC, 0);
#else
    croak("sendfile(): F_DUPFD_CLOEXEC is unavailable");
#endif
    if (owned_fd < 0)
        croak("sendfile(): cannot duplicate source fd: %s", strerror(errno));
    if (fstat(owned_fd, &info) < 0) {
        int err = errno;
        close(owned_fd);
        croak("sendfile(): fstat failed: %s", strerror(err));
    }
    if (!S_ISREG(info.st_mode) || info.st_size < 0) {
        close(owned_fd);
        croak("sendfile(): source must be a regular file");
    }
    {
        int access = fcntl(owned_fd, F_GETFL);
        if (access < 0 || (access & O_ACCMODE) == O_WRONLY) {
            int err = access < 0 ? errno : EBADF;
            close(owned_fd);
            croak("sendfile(): source file is not readable: %s",
                strerror(err));
        }
    }
    if ((off_t)offset < 0 || (UV)(off_t)offset != offset
        || (off_t)(UV)info.st_size != info.st_size) {
        close(owned_fd);
        croak("sendfile(): source file offset/size is out of range");
    }
    size = (UV)info.st_size;
    if (offset > size || (has_length && length > size - offset)) {
        close(owned_fd);
        croak("sendfile(): range extends beyond the source file");
    }
    remaining = has_length ? length : size - offset;
    if ((UV)(STRLEN)remaining != remaining) {
        close(owned_fd);
        croak("sendfile(): range is too large for native queue counters");
    }
    if (remaining == 0) {
        close(owned_fd);
        return LES_WRITE_FLOW_OK;
    }
    if (UV_MAX - st->pending_bytes < remaining) {
        close(owned_fd);
        croak("sendfile(): pending byte counter would overflow");
    }
    attempted = st->pending_bytes + remaining;
    if (st->max_pending_bytes && attempted > st->max_pending_bytes) {
        close(owned_fd);
        les_call_output_limit(aTHX_ st, attempted);
        return 0;
    }

    LES_STAT(st, write_submit_calls)++;
    if (!st->whead) {
        /* One successful immediate sendfile, capped to the fairness budget. */
        for (;;) {
            ssize_t written;
            size_t requested = remaining > LES_FILE_DRAIN_BUDGET
                ? LES_FILE_DRAIN_BUDGET : (size_t)remaining;
            off_t current = (off_t)offset;

            LES_STAT(st, write_calls)++;
            written = les_safe_sendfile(
                st->write_fd, owned_fd, &current, requested);
            if (written > 0) {
                offset = (UV)current;
                remaining -= (UV)written;
                LES_STAT(st, bytes_written) += (unsigned long long)written;
                les_note_write_activity(aTHX_ st);
                break;
            }
            if (written < 0 && errno == EINTR) {
                LES_STAT(st, write_eintr_count)++;
                continue;
            }
            if (written < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                LES_STAT(st, write_eagain_count)++;
                break;
            }
            {
                int err = written == 0 ? EIO : errno;
                close(owned_fd);
                LES_STAT(st, write_error_count)++;
                les_call_write_error(aTHX_ st, err);
                return 0;
            }
        }
        if (!remaining) {
            close(owned_fd);
            return LES_WRITE_FLOW_OK;
        }
    }

    file = (les_file_seg_t *)calloc(1, sizeof(*file));
    if (!file) {
        close(owned_fd);
        croak("calloc Stream file segment failed");
    }
    file->fd = owned_fd;
    file->file_offset = (off_t)offset;
    file->base.sv = NULL;
    file->base.off = 0;
    file->base.len = (STRLEN)remaining;
    if (st->wtail)
        st->wtail->next = &file->base;
    else
        st->whead = &file->base;
    st->wtail = &file->base;
    st->file_segments++;
    st->pending_bytes += remaining;
    LES_STAT(st, queued_segments)++;
    if ((unsigned long long)st->pending_bytes > LES_STAT(st, queue_peak_bytes))
        LES_STAT(st, queue_peak_bytes) = (unsigned long long)st->pending_bytes;
    if (!st->write_blocked && st->pending_bytes > st->high_watermark)
        st->write_blocked = 1;
    return (st->write_blocked ? 0 : LES_WRITE_FLOW_OK)
         | LES_WRITE_QUEUED;
}

void
les_write_ready(pTHX_ les_xsstate_t *st)
{
    int had_pending;
    int bounded = 0;
    size_t budget = LES_FILE_DRAIN_BUDGET;

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
        size_t gathered = 0;

        if (st->file_segments)
            bounded = 1;
        if (bounded && budget == 0)
            return;

        if (st->whead && !st->whead->sv) {
            les_file_seg_t *file = (les_file_seg_t *)st->whead;
            size_t count = (size_t)(file->base.len - file->base.off);
            ssize_t written;

            /* Native guard against a later non-plain provider attachment. */
            if (st->transport_ops != &les_plain_transport_ops) {
                LES_STAT(st, write_error_count)++;
                les_call_write_error(aTHX_ st, EOPNOTSUPP);
                return;
            }
            if (count > budget)
                count = budget;
            if (count > LES_SENDFILE_SYSCALL_MAX)
                count = LES_SENDFILE_SYSCALL_MAX;
            LES_STAT(st, write_calls)++;
            written = les_safe_sendfile(
                st->write_fd, file->fd, &file->file_offset, count);
            if (written > 0) {
                LES_STAT(st, bytes_written) += (unsigned long long)written;
                les_note_write_activity(aTHX_ st);
                budget -= (size_t)written;
                les_consume_written(st, (size_t)written);
                les_maybe_drain_transition(aTHX_ st);
                continue;
            }
            if (written < 0 && errno == EINTR) {
                LES_STAT(st, write_eintr_count)++;
                continue;
            }
            if (written < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                LES_STAT(st, write_eagain_count)++;
                return;
            }
            {
                int err = written == 0 ? EIO : errno;
                LES_STAT(st, write_error_count)++;
                les_call_write_error(aTHX_ st, err);
                return;
            }
        }

        for (seg = st->whead; seg && iovcnt < LES_IOV_MAX; seg = seg->next) {
            if (!seg->sv)
                break;
            STRLEN pvlen;
            const char *pv = SvPV(seg->sv, pvlen);
            STRLEN avail = seg->len - seg->off;

            if (seg->off > pvlen || avail > pvlen - seg->off)
                croak("internal Stream write segment bounds corrupted");

            if (bounded && (size_t)avail > budget - gathered)
                avail = (STRLEN)(budget - gathered);
            if (avail == 0)
                break;
            iov[iovcnt].iov_base = (void *)(pv + seg->off);
            iov[iovcnt].iov_len = (size_t)avail;
            gathered += (size_t)avail;
            iovcnt++;
            if (bounded && gathered == budget)
                break;
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
            if (bounded)
                budget -= (size_t)result.count;
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
