/* Hyperman::Event::Kqueue - the kqueue readiness backend (macOS / BSD).
 * Implements the hm_backend interface from hyperman.h. Timers use the
 * watcher pointer as the kevent ident so one backend hosts many one-shot
 * timers; signals use EVFILT_SIGNAL (caller must SIG_IGN the default
 * disposition). */

#include "hyperman.h"

#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
#define HM_HAVE_KQUEUE 1
#endif

#ifdef HM_HAVE_KQUEUE

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

typedef struct { int kq; } hm_kq_state;

static int kq_apply(hm_backend *be, int fd, int mask, int flags) {
    hm_kq_state *st = (hm_kq_state *)be->state;
    struct kevent kev[2];
    int n = 0;
    if (mask & HM_EV_READ)  { EV_SET(&kev[n], fd, EVFILT_READ,  flags, 0, 0, NULL); n++; }
    if (mask & HM_EV_WRITE) { EV_SET(&kev[n], fd, EVFILT_WRITE, flags, 0, 0, NULL); n++; }
    if (!n) return 0;
    return kevent(st->kq, kev, n, NULL, 0, NULL);
}

static int kq_add_io(hm_backend *be, int fd, int mask, int oneshot) {
    return kq_apply(be, fd, mask, EV_ADD | (oneshot ? EV_ONESHOT : 0));
}

static int kq_modify_io(hm_backend *be, int fd, int mask, int oneshot) {
    /* kqueue ADD on an existing filter re-arms it; same call */
    return kq_apply(be, fd, mask, EV_ADD | (oneshot ? EV_ONESHOT : 0));
}

static int kq_remove_io(hm_backend *be, int fd, int mask) {
    return kq_apply(be, fd, mask, EV_DELETE);
}

static int kq_add_timer(hm_backend *be, double secs, int oneshot, void *udata) {
    hm_kq_state *st = (hm_kq_state *)be->state;
    struct kevent kev;
    long ms = (long)(secs * 1000);
    if (ms < 1) ms = 1;
    EV_SET(&kev, (uintptr_t)udata, EVFILT_TIMER,
           EV_ADD | (oneshot ? EV_ONESHOT : 0), 0, ms, udata);
    return kevent(st->kq, &kev, 1, NULL, 0, NULL);
}

static int kq_del_timer(hm_backend *be, void *udata) {
    hm_kq_state *st = (hm_kq_state *)be->state;
    struct kevent kev;
    EV_SET(&kev, (uintptr_t)udata, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
    return kevent(st->kq, &kev, 1, NULL, 0, NULL);
}

static int kq_add_signal(hm_backend *be, int signo) {
    hm_kq_state *st = (hm_kq_state *)be->state;
    struct kevent kev;
    EV_SET(&kev, signo, EVFILT_SIGNAL, EV_ADD, 0, 0, NULL);
    return kevent(st->kq, &kev, 1, NULL, 0, NULL);
}

static int kq_wait(hm_backend *be, hm_event *out, int max, double timeout) {
    hm_kq_state *st = (hm_kq_state *)be->state;
    struct kevent evs[HM_MAXEV];
    struct timespec ts, *tsp = NULL;
    int n, i;
    if (max > HM_MAXEV) max = HM_MAXEV;
    if (timeout >= 0) {
        ts.tv_sec  = (time_t)timeout;
        ts.tv_nsec = (long)((timeout - (double)ts.tv_sec) * 1e9);
        tsp = &ts;
    }
    n = kevent(st->kq, NULL, 0, evs, max, tsp);
    if (n <= 0) return n;
    for (i = 0; i < n; i++) {
        switch (evs[i].filter) {
        case EVFILT_READ:
            out[i].kind = HM_EV_READ;  out[i].fd = (int)evs[i].ident;
            out[i].udata = NULL; break;
        case EVFILT_WRITE:
            out[i].kind = HM_EV_WRITE; out[i].fd = (int)evs[i].ident;
            out[i].udata = NULL; break;
        case EVFILT_TIMER:
            out[i].kind = HM_EV_TIMER; out[i].fd = -1;
            out[i].udata = evs[i].udata; break;
        case EVFILT_SIGNAL:
            out[i].kind = HM_EV_SIGNAL; out[i].fd = (int)evs[i].ident;
            out[i].udata = NULL; break;
        default:
            out[i].kind = 0; out[i].fd = -1; out[i].udata = NULL;
        }
    }
    return n;
}

static void kq_destroy(hm_backend *be) {
    hm_kq_state *st = (hm_kq_state *)be->state;
    if (st) { if (st->kq >= 0) close(st->kq); free(st); }
    free(be);
}

hm_backend *hm_backend_kqueue_new(void) {
    hm_backend  *be = (hm_backend *)calloc(1, sizeof(hm_backend));
    hm_kq_state *st = (hm_kq_state *)calloc(1, sizeof(hm_kq_state));
    if (!be || !st) { free(be); free(st); return NULL; }
    st->kq = kqueue();
    if (st->kq < 0) { free(be); free(st); return NULL; }
    be->name       = "kqueue";
    be->state      = st;
    be->add_io     = kq_add_io;
    be->modify_io  = kq_modify_io;
    be->remove_io  = kq_remove_io;
    be->add_timer  = kq_add_timer;
    be->del_timer  = kq_del_timer;
    be->add_signal = kq_add_signal;
    be->wait       = kq_wait;
    be->destroy    = kq_destroy;
    return be;
}

int hm_backend_kqueue_available(void) { return 1; }

#else /* !HM_HAVE_KQUEUE */

hm_backend *hm_backend_kqueue_new(void)      { return 0; }
int         hm_backend_kqueue_available(void) { return 0; }

#endif
