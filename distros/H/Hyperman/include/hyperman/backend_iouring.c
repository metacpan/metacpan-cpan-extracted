/* Hyperman::Event::IOUring - io_uring readiness backend (Linux), built on
 * liburing. Enabled by Makefile.PL when liburing is found (pkg-config or a
 * -luring compile probe), which defines HM_HAVE_LIBURING and links -luring;
 * otherwise this compiles to graceful "unavailable" stubs.
 *
 * Readiness comes from the ring in *poll mode*: IORING_OP_POLL_ADD
 * completions mapped onto the hm_backend vtable (persistent watchers are
 * re-armed on delivery), timers as IORING_OP_TIMEOUT, and shutdown signals
 * via a signalfd polled on the ring.
 *
 * COMPLETION-MODE READS (HYPERMAN_COMPLETION=1) go further: the core asks for
 * the read up front with ur_submit_recv and is handed bytes that are already
 * in its buffer, so the read stops being a syscall per request and becomes
 * part of the one batched submission per turn of the loop. Measured, 2000
 * keep-alive requests over 50 connections:
 *
 *     poll mode        read 10050  writev 10000  enter 222   2.02 syscalls/req
 *     completion mode  read     0  writev 10000  enter 203   1.02 syscalls/req
 *
 * The write side is still a writev per response and is the next thing to move.
 *
 * Opt-in for now: HYPERMAN_BACKEND=io_uring or Hyperman::Loop->new('io_uring');
 * auto-selection stays kqueue > epoll > poll until this is benchmarked on
 * reference hardware.
 */

#include "hyperman.h"

#if defined(__linux__) && defined(HM_HAVE_LIBURING)
#define HM_IOURING_ACTIVE 1
#endif

#ifdef HM_IOURING_ACTIVE

#include <liburing.h>
#include <sys/signalfd.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <poll.h>

/* user_data tagging (low 3 bits). Timer completions carry a pointer to
 * their ur_timer, which is 8-aligned so its tag is 0. liburing's own
 * internal wait-timeout uses LIBURING_UDATA_TIMEOUT and is skipped. */
#define UR_TAG_MASK   7ULL
#define UR_TAG_TIMER  0ULL   /* aligned ur_timer* */
#define UR_TAG_READ   1ULL
#define UR_TAG_WRITE  2ULL
#define UR_TAG_RECV   3ULL   /* completion-mode recv (see ur_submit_recv) */
#define UR_TAG_IGNORE 5ULL   /* poll-remove completions: drop */

/* io_uring_sqe_set_data64() was only added in liburing 2.2; assign the
 * user_data field directly (exactly what that helper does) so we build and
 * load against every liburing version. */
#define UR_SET_DATA(sqe, val) ((sqe)->user_data = (__u64)(val))

typedef struct ur_timer {
    struct __kernel_timespec ts;
    void            *udata;
    int              interval;   /* re-arm on fire?  */
    int              cancelled;  /* freed when its completion lands, not before */
    struct ur_timer *prev, *next;
} ur_timer;

typedef struct {
    struct io_uring ring;
    unsigned char   mask[HM_MAXFD];    /* wanted HM_EV bits             */
    unsigned char   once[HM_MAXFD];    /* oneshot HM_EV bits            */
    unsigned char   armed[HM_MAXFD];   /* HM_EV bits with in-flight sqe */
    /* completion-mode recv: at most ONE in flight per fd, and the token that
     * identifies whose it is. Kept per-fd rather than in user_data because
     * user_data is 64 bits and already carries the fd and the tag. */
    uint64_t        recv_token[HM_MAXFD];
    unsigned char   recv_armed[HM_MAXFD];
    ur_timer       *timers;            /* doubly-linked, for cleanup    */
    int             sfd;               /* signalfd, -1 until first sig  */
    sigset_t        sigs;
    /* A poll re-arm found no submission slot (the ring was full and the
     * submit that should have drained it failed, -EBUSY under completion
     * overflow). The interest is still in mask[] with armed[] clear, and
     * ur_wait re-arms every such fd before it sleeps, so a connection is
     * never left unwatched by a momentary full ring. */
    int             sq_dropped;
} hm_ur_state;

/* Get an sqe, flushing the ring if the submission queue is momentarily full. */
static struct io_uring_sqe *ur_sqe(hm_ur_state *st) {
    struct io_uring_sqe *sqe = io_uring_get_sqe(&st->ring);
    if (!sqe) {
        io_uring_submit(&st->ring);
        sqe = io_uring_get_sqe(&st->ring);
    }
    return sqe;
}

static void ur_arm_poll(hm_ur_state *st, int fd, int evbit) {
    struct io_uring_sqe *sqe = ur_sqe(st);
    unsigned mask = (evbit == HM_EV_READ) ? (POLLIN | POLLHUP | POLLERR)
                                          : (POLLOUT | POLLHUP | POLLERR);
    if (!sqe) { st->sq_dropped = 1; return; }
    io_uring_prep_poll_add(sqe, fd, mask);
    UR_SET_DATA(sqe,
        ((__u64)(unsigned)fd << 3)
        | (evbit == HM_EV_READ ? UR_TAG_READ : UR_TAG_WRITE));
    st->armed[fd] |= (unsigned char)evbit;
}

static int ur_add_io(hm_backend *be, int fd, int mask, int oneshot) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    int bit;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    st->mask[fd] |= (unsigned char)mask;
    if (oneshot) st->once[fd] |= (unsigned char)mask;
    else         st->once[fd] &= (unsigned char)~mask;
    for (bit = HM_EV_READ; bit <= HM_EV_WRITE; bit <<= 1)
        if ((mask & bit) && !(st->armed[fd] & bit))
            ur_arm_poll(st, fd, bit);
    return 0;
}

static int ur_modify_io(hm_backend *be, int fd, int mask, int oneshot) {
    return ur_add_io(be, fd, mask, oneshot);
}

static int ur_remove_io(hm_backend *be, int fd, int mask) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    int bit;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    st->mask[fd] &= (unsigned char)~mask;
    st->once[fd] &= (unsigned char)~mask;
    /* cancel any in-flight poll for the dropped interest, so a closed+reused
     * fd can't be woken by a stale completion */
    for (bit = HM_EV_READ; bit <= HM_EV_WRITE; bit <<= 1) {
        if ((mask & bit) && (st->armed[fd] & bit)) {
            struct io_uring_sqe *sqe = ur_sqe(st);
            if (sqe) {
                io_uring_prep_poll_remove(sqe,
                    ((__u64)(unsigned)fd << 3)
                    | (bit == HM_EV_READ ? UR_TAG_READ : UR_TAG_WRITE));
                UR_SET_DATA(sqe, UR_TAG_IGNORE);
                st->armed[fd] &= (unsigned char)~bit;
            }
            /* No slot for the cancel: the poll stays in flight and armed
             * stays SET, so a later add does not arm a second one; its
             * completion finds the interest gone (mask) and is dropped
             * there, which clears armed. */
        }
    }
    return 0;
}

#ifdef HM_HAVE_URING_RECV
/* Ask for one read into `buf`, delivered later as HM_EV_RECV.
 *
 * REFUSES WHILE ONE IS ALREADY IN FLIGHT ON THIS FD, and that refusal is
 * load-bearing rather than defensive. The token lives in a per-fd slot, so a
 * second submission would overwrite the first one's token - and then the
 * FIRST completion, belonging to a connection that has already gone, would
 * arrive wearing the SECOND connection's identity, pass the core's generation
 * check, and have its byte count added to a buffer it never wrote into. The
 * core reads -1 as "do it yourself" and falls back to a readiness read, which
 * is always correct, just not as cheap. */
static int ur_submit_recv(hm_backend *be, int fd, void *buf, size_t len,
                          uint64_t token) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    struct io_uring_sqe *sqe;
    if (fd < 0 || fd >= HM_MAXFD || len == 0) return -1;
    if (st->recv_armed[fd]) return -1;
    sqe = ur_sqe(st);
    if (!sqe) return -1;
    io_uring_prep_recv(sqe, fd, buf, len, 0);
    UR_SET_DATA(sqe, ((__u64)(unsigned)fd << 3) | UR_TAG_RECV);
    st->recv_token[fd] = token;
    st->recv_armed[fd] = 1;
    return 0;
}

/* Best-effort cancel at close.
 *
 * recv_armed is deliberately NOT cleared here. The completion still lands -
 * cancelled or not - and it is the only moment at which the buffer the kernel
 * was given can be known to be free again. Clearing the flag early would let
 * the next connection on this fd number arm a second recv while the first is
 * still outstanding, which is exactly the overwrite ur_submit_recv refuses. */
static void ur_cancel_recv(hm_backend *be, int fd) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    struct io_uring_sqe *sqe;
    if (fd < 0 || fd >= HM_MAXFD || !st->recv_armed[fd]) return;
    sqe = ur_sqe(st);
    if (!sqe) return;
    io_uring_prep_cancel(sqe,
        (void *)(uintptr_t)(((__u64)(unsigned)fd << 3) | UR_TAG_RECV), 0);
    UR_SET_DATA(sqe, UR_TAG_IGNORE);
}
#endif /* HM_HAVE_URING_RECV */

static int ur_arm_timer(hm_ur_state *st, ur_timer *t) {
    struct io_uring_sqe *sqe = ur_sqe(st);
    if (!sqe) return -1;
    io_uring_prep_timeout(sqe, &t->ts, 0, 0);
    UR_SET_DATA(sqe, (__u64)(uintptr_t)t);   /* tag 0 (aligned) */
    return 0;
}

static int ur_add_timer(hm_backend *be, double secs, int oneshot, void *udata) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    ur_timer *t = (ur_timer *)hm_xcalloc(1, sizeof(ur_timer));
    if (!t) return -1;
    t->ts.tv_sec  = (int64_t)secs;
    t->ts.tv_nsec = (int64_t)((secs - (double)t->ts.tv_sec) * 1e9);
    if (t->ts.tv_sec == 0 && t->ts.tv_nsec == 0) t->ts.tv_nsec = 1;
    t->udata    = udata;
    t->interval = !oneshot;
    t->next = st->timers;
    if (st->timers) st->timers->prev = t;
    st->timers = t;
    if (ur_arm_timer(st, t) < 0) {
        /* No submission slot: the caller is told, as the other backends
         * tell it when a timerfd cannot be had, rather than owning a timer
         * that will never fire. t is the list head, just linked. */
        st->timers = t->next;
        if (t->next) t->next->prev = NULL;
        free(t);
        errno = EAGAIN;
        return -1;
    }
    return 0;
}

static void ur_timer_unlink(hm_ur_state *st, ur_timer *t) {
    if (t->prev) t->prev->next = t->next;
    else         st->timers = t->next;
    if (t->next) t->next->prev = t->prev;
}

/* Cancel a timer. The timeout is already in flight in the kernel and its
 * user_data IS this pointer, so freeing here would leave the kernel holding a
 * dangling reference: the completion still arrives, ur_wait dereferences it
 * and frees it a second time. Worse, the block is the right size to be handed
 * straight back to the next ur_add_timer, so the stale completion lands on a
 * live timer and takes that down instead - which is why this showed up as an
 * intermittent "double free or corruption" rather than a reliable one.
 *
 * So: ask the kernel to remove the timeout and mark the watcher dead, but
 * leave it linked and allocated. Its completion (-ECANCELED, or a genuine
 * fire that raced the removal) frees it in ur_wait; anything still linked at
 * shutdown is freed by ur_destroy. */
static int ur_del_timer(hm_backend *be, void *udata) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    ur_timer *t;
    for (t = st->timers; t; t = t->next) {
        if (t->udata == udata && !t->cancelled) {
            struct io_uring_sqe *sqe;
            t->cancelled = 1;
            t->interval  = 0;          /* never re-arm a cancelled timer */
            if ((sqe = ur_sqe(st)) != NULL) {
                io_uring_prep_timeout_remove(sqe, (__u64)(uintptr_t)t, 0);
                UR_SET_DATA(sqe, UR_TAG_IGNORE);
            }
            return 0;
        }
    }
    return -1;
}

static int ur_add_signal(hm_backend *be, int signo) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    sigaddset(&st->sigs, signo);
    if (sigprocmask(SIG_BLOCK, &st->sigs, NULL) < 0) return -1;
    {
        int sfd = signalfd(st->sfd, &st->sigs, SFD_NONBLOCK | SFD_CLOEXEC);
        if (sfd < 0) return -1;
        if (st->sfd < 0) {
            st->sfd = sfd;
            st->mask[sfd] |= HM_EV_READ;   /* persistent poll on the ring */
            ur_arm_poll(st, sfd, HM_EV_READ);
        }
    }
    return 0;
}

static int ur_wait(hm_backend *be, hm_event *out, int max, double timeout) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    struct io_uring_cqe *cqes[HM_MAXEV];
    struct io_uring_cqe *cqe;
    unsigned want, n, i;
    int nev = 0, ret;

    if (st->sq_dropped) {
        /* A re-arm found the ring full: every interest with no poll in
         * flight is armed again now, with the ring drained by the submit
         * below between attempts. Rare, so the full-table walk is fine. */
        int fd;
        st->sq_dropped = 0;
        for (fd = 0; fd < HM_MAXFD; fd++) {
            unsigned char need = st->mask[fd] & (unsigned char)~st->armed[fd];
            if (!need) continue;
            if (need & HM_EV_READ)  ur_arm_poll(st, fd, HM_EV_READ);
            if (need & HM_EV_WRITE) ur_arm_poll(st, fd, HM_EV_WRITE);
        }
    }
    io_uring_submit(&st->ring);   /* flush re-arms, cancels, timers */

    if (timeout < 0) {
        ret = io_uring_wait_cqe(&st->ring, &cqe);
    } else if (timeout == 0) {
        ret = io_uring_peek_cqe(&st->ring, &cqe);
        if (ret == -EAGAIN) return 0;
    } else {
        struct __kernel_timespec ts;
        ts.tv_sec  = (int64_t)timeout;
        ts.tv_nsec = (int64_t)((timeout - (double)ts.tv_sec) * 1e9);
        ret = io_uring_wait_cqe_timeout(&st->ring, &cqe, &ts);
        if (ret == -ETIME) return 0;
    }
    if (ret < 0) return (ret == -EINTR) ? 0 : -1;

    /* headroom so a single signalfd completion (multiple queued signals)
     * can't overflow the caller's event buffer */
    want = (max > 8) ? (unsigned)(max - 8) : 1u;
    if (want > HM_MAXEV) want = HM_MAXEV;
    n = io_uring_peek_batch_cqe(&st->ring, cqes, want);

    for (i = 0; i < n; i++) {
        __u64 data = cqes[i]->user_data;
        int   res  = cqes[i]->res;
        __u64 tag  = data & UR_TAG_MASK;

        if (data == LIBURING_UDATA_TIMEOUT) continue;   /* liburing internal */
        if (tag == UR_TAG_IGNORE) continue;             /* poll-remove ack   */

#ifdef HM_HAVE_URING_RECV
        if (tag == UR_TAG_RECV) {
            int fd = (int)(data >> 3);
            st->recv_armed[fd] = 0;   /* the buffer is the kernel's no longer */
            if (nev >= max) break;
            /* Delivered even when cancelled or failed: a completion is the
             * only signal that the buffer handed to the kernel is free, and
             * the core has one to release whether the read worked or not. */
            out[nev].kind  = HM_EV_RECV;
            out[nev].fd    = fd;
            out[nev].res   = res;
            out[nev].token = st->recv_token[fd];
            out[nev].udata = NULL;
            nev++;
            continue;
        }
#endif

        if (tag == UR_TAG_READ || tag == UR_TAG_WRITE) {
            int fd  = (int)(data >> 3);
            int bit = (tag == UR_TAG_READ) ? HM_EV_READ : HM_EV_WRITE;
            st->armed[fd] &= (unsigned char)~bit;
            if (res == -ECANCELED || !(st->mask[fd] & bit)) continue;

            if (st->sfd >= 0 && fd == st->sfd) {
                struct signalfd_siginfo si;
                while (nev < max
                       && read(st->sfd, &si, sizeof(si)) == (ssize_t)sizeof(si)) {
                    out[nev].kind = HM_EV_SIGNAL;
                    out[nev].fd = (int)si.ssi_signo;
                    out[nev].udata = NULL;
                    nev++;
                }
                ur_arm_poll(st, st->sfd, HM_EV_READ);   /* persistent */
                continue;
            }

            out[nev].kind  = bit;
            out[nev].fd    = fd;
            out[nev].udata = NULL;
            nev++;
            if (st->once[fd] & bit) {
                st->mask[fd] &= (unsigned char)~bit;
                st->once[fd] &= (unsigned char)~bit;
            } else {
                ur_arm_poll(st, fd, bit);   /* persistent: re-arm */
            }
            continue;
        }

        {   /* timer: user_data is the ur_timer pointer (tag 0) */
            ur_timer *t = (ur_timer *)(uintptr_t)data;
            if (!t) continue;
            /* A cancelled timer's completion still arrives; it owns the
             * struct, and it must not be reported to the loop. -ECANCELED
             * covers the removal succeeding, t->cancelled the case where the
             * timeout fired before the removal reached the kernel. */
            if (t->cancelled || res == -ECANCELED) {
                ur_timer_unlink(st, t);
                free(t);
                continue;
            }
            out[nev].kind  = HM_EV_TIMER;
            out[nev].fd    = -1;
            out[nev].udata = t->udata;
            nev++;
            if (t->interval) {
                ur_arm_timer(st, t);
            } else {
                ur_timer_unlink(st, t);
                free(t);
            }
        }
    }
    io_uring_cq_advance(&st->ring, n);
    return nev;
}

static void ur_destroy(hm_backend *be) {
    hm_ur_state *st = (hm_ur_state *)be->state;
    if (st) {
        while (st->timers) {
            ur_timer *t = st->timers;
            st->timers = t->next;
            free(t);
        }
        /* be->foreign: inherited across a fork. The signalfd and the ring's
         * own descriptor are the parent's; io_uring_queue_exit would close
         * the ring fd and unmap rings this process never set up. */
        if (!be->foreign) {
            if (st->sfd >= 0) close(st->sfd);
            io_uring_queue_exit(&st->ring);
        }
        free(st);
    }
    free(be);
}

hm_backend *hm_backend_iouring_new(void) {
    hm_backend  *be = (hm_backend *)hm_xcalloc(1, sizeof(hm_backend));
    hm_ur_state *st = (hm_ur_state *)hm_xcalloc(1, sizeof(hm_ur_state));
    if (!be || !st) { free(be); free(st); return NULL; }
    st->sfd = -1;
    sigemptyset(&st->sigs);
    if (io_uring_queue_init(1024, &st->ring, 0) < 0) {
        free(be); free(st); return NULL;
    }
    be->name       = "io_uring";
    be->state      = st;
    be->add_io     = ur_add_io;
    be->modify_io  = ur_modify_io;
    be->remove_io  = ur_remove_io;
    be->add_timer  = ur_add_timer;
    be->del_timer  = ur_del_timer;
    be->add_signal = ur_add_signal;
    be->wait       = ur_wait;
    be->destroy    = ur_destroy;
#ifdef HM_HAVE_URING_RECV
    be->submit_recv = ur_submit_recv;
    be->cancel_recv = ur_cancel_recv;
#endif
    return be;
}

int hm_backend_iouring_available(void) {
    /* liburing is linked; confirm the kernel actually supports io_uring
     * (not the case under, e.g., default Docker seccomp) */
    static int avail = -1;
    if (avail < 0) {
        struct io_uring ring;
        if (io_uring_queue_init(2, &ring, 0) == 0) {
            io_uring_queue_exit(&ring);
            avail = 1;
        } else {
            avail = 0;
        }
    }
    return avail;
}

#else /* !HM_IOURING_ACTIVE */

hm_backend *hm_backend_iouring_new(void)       { return 0; }
int         hm_backend_iouring_available(void) { return 0; }

#endif
