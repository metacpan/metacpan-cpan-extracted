/* Hyperman::Event::Poll - the portable poll(2) readiness backend, and the
 * backend dispatcher (hm_backend_create). This is the portability floor:
 * timers are a deadline list checked against a
 * monotonic clock, signals use a self-pipe. Always available.
 *
 * Native Windows lacks poll(2) and this whole file; there hm_backend_create
 * and the select() backend live in backend_select.c instead. */

#ifndef _WIN32

#include "ft_backend.h"

#include <poll.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

typedef struct {
    double when;       /* monotonic deadline    */
    double interval;   /* 0 = one-shot          */
    void  *udata;
} hm_ptimer;

typedef struct {
    struct pollfd *pfds;
    int            npfds, cap;
    int            idx[HM_MAXFD];       /* fd -> pfds index, or -1   */
    unsigned char  oneshot[HM_MAXFD];   /* HM_EV_* bits to self-clear */
    hm_ptimer     *timers;
    int            ntimers, tcap;
    int            sigpipe[2];          /* self-pipe, -1 until used  */
} hm_poll_state;

/* self-pipe globals: async-signal-safe handler writes one byte */
static volatile sig_atomic_t hm_poll_sigflag[64];
static int hm_poll_pipe_w = -1;

static void hm_poll_handler(int signo) {
    if (signo > 0 && signo < 64) hm_poll_sigflag[signo] = 1;
    if (hm_poll_pipe_w >= 0) {
        char b = 1;
        ssize_t r = write(hm_poll_pipe_w, &b, 1);
        (void)r;
    }
}

static double hm_poll_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

static short hm_poll_events(int mask) {
    short ev = 0;
    if (mask & HM_EV_READ)  ev |= POLLIN;
    if (mask & HM_EV_WRITE) ev |= POLLOUT;
    return ev;
}

static int hm_poll_mask_of(short events) {
    int m = 0;
    if (events & POLLIN)  m |= HM_EV_READ;
    if (events & POLLOUT) m |= HM_EV_WRITE;
    return m;
}

static int pl_add_io(hm_backend *be, int fd, int mask, int oneshot) {
    hm_poll_state *st = (hm_poll_state *)be->state;
    int i;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    i = st->idx[fd];
    if (i < 0) {
        if (st->npfds == st->cap) {
            st->cap = st->cap ? st->cap * 2 : 64;
            st->pfds = (struct pollfd *)realloc(st->pfds,
                            st->cap * sizeof(struct pollfd));
        }
        i = st->npfds++;
        st->pfds[i].fd = fd;
        st->pfds[i].events = 0;
        st->idx[fd] = i;
    }
    st->pfds[i].events |= hm_poll_events(mask);
    if (oneshot) st->oneshot[fd] |= (unsigned char)mask;
    else         st->oneshot[fd] &= (unsigned char)~mask;
    return 0;
}

static int pl_modify_io(hm_backend *be, int fd, int mask, int oneshot) {
    return pl_add_io(be, fd, mask, oneshot);
}

static int pl_remove_io(hm_backend *be, int fd, int mask) {
    hm_poll_state *st = (hm_poll_state *)be->state;
    int i;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    i = st->idx[fd];
    if (i < 0) return 0;
    st->pfds[i].events &= ~hm_poll_events(mask);
    st->oneshot[fd] &= (unsigned char)~mask;
    if (st->pfds[i].events == 0) {
        int last = st->npfds - 1;
        if (i != last) {
            st->pfds[i] = st->pfds[last];
            st->idx[st->pfds[i].fd] = i;
        }
        st->npfds--;
        st->idx[fd] = -1;
    }
    return 0;
}

static int pl_add_timer(hm_backend *be, double secs, int oneshot, void *udata) {
    hm_poll_state *st = (hm_poll_state *)be->state;
    if (st->ntimers == st->tcap) {
        st->tcap = st->tcap ? st->tcap * 2 : 16;
        st->timers = (hm_ptimer *)realloc(st->timers,
                          st->tcap * sizeof(hm_ptimer));
    }
    st->timers[st->ntimers].when     = hm_poll_now() + secs;
    st->timers[st->ntimers].interval = oneshot ? 0.0 : secs;
    st->timers[st->ntimers].udata    = udata;
    st->ntimers++;
    return 0;
}

static int pl_del_timer(hm_backend *be, void *udata) {
    hm_poll_state *st = (hm_poll_state *)be->state;
    int i;
    for (i = 0; i < st->ntimers; i++) {
        if (st->timers[i].udata == udata) {
            st->timers[i] = st->timers[--st->ntimers];
            return 0;
        }
    }
    return -1;
}

static int pl_add_signal(hm_backend *be, int signo) {
    hm_poll_state *st = (hm_poll_state *)be->state;
    struct sigaction sa;
    if (st->sigpipe[0] < 0) {
        if (pipe(st->sigpipe) < 0) return -1;
        fcntl(st->sigpipe[0], F_SETFL, O_NONBLOCK);
        fcntl(st->sigpipe[1], F_SETFL, O_NONBLOCK);
        hm_poll_pipe_w = st->sigpipe[1];
        pl_add_io(be, st->sigpipe[0], HM_EV_READ, 0);
    }
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = hm_poll_handler;
    sigemptyset(&sa.sa_mask);
    return sigaction(signo, &sa, NULL);
}

static int pl_wait(hm_backend *be, hm_event *out, int max, double timeout) {
    hm_poll_state *st = (hm_poll_state *)be->state;
    double now = hm_poll_now();
    int tmo_ms, n, i, nev = 0;

    /* clamp the poll timeout to the nearest timer deadline */
    {
        double tmo = timeout;
        for (i = 0; i < st->ntimers; i++) {
            double d = st->timers[i].when - now;
            if (d < 0) d = 0;
            if (tmo < 0 || d < tmo) tmo = d;
        }
        tmo_ms = tmo < 0 ? -1 : (int)(tmo * 1000) + 1;
    }

    n = poll(st->pfds, (nfds_t)st->npfds, tmo_ms);
    if (n < 0 && errno != EINTR) return -1;

    /* io + signal readiness */
    for (i = 0; i < st->npfds && nev < max; i++) {
        short rev = st->pfds[i].revents;
        int fd = st->pfds[i].fd;
        if (!rev) continue;

        if (st->sigpipe[0] >= 0 && fd == st->sigpipe[0]) {
            char buf[64];
            int s;
            while (read(st->sigpipe[0], buf, sizeof(buf)) > 0) { }
            for (s = 1; s < 64 && nev < max; s++) {
                if (hm_poll_sigflag[s]) {
                    hm_poll_sigflag[s] = 0;
                    out[nev].kind = HM_EV_SIGNAL;
                    out[nev].fd = s;
                    out[nev].udata = NULL;
                    nev++;
                }
            }
            continue;
        }

        {
            int had = hm_poll_mask_of(st->pfds[i].events);
            int got = 0;
            if (rev & (POLLIN  | POLLHUP | POLLERR | POLLNVAL)) got |= HM_EV_READ;
            if (rev & (POLLOUT | POLLHUP | POLLERR | POLLNVAL)) got |= HM_EV_WRITE;
            got &= had;
            if (!got) got = had;   /* error on an fd: wake whatever watches it */
            if (got & HM_EV_READ) {
                out[nev].kind = HM_EV_READ;
                out[nev].fd = fd;
                out[nev].udata = NULL;
                nev++;
            }
            if ((got & HM_EV_WRITE) && nev < max) {
                out[nev].kind = HM_EV_WRITE;
                out[nev].fd = fd;
                out[nev].udata = NULL;
                nev++;
            }
            if (st->oneshot[fd] & got) {
                pl_remove_io(be, fd, st->oneshot[fd] & got);
                i--;   /* entry may have been swapped away; recheck this slot */
            }
        }
    }

    /* expired timers */
    now = hm_poll_now();
    for (i = 0; i < st->ntimers && nev < max; i++) {
        if (st->timers[i].when <= now) {
            out[nev].kind = HM_EV_TIMER;
            out[nev].fd = -1;
            out[nev].udata = st->timers[i].udata;
            nev++;
            if (st->timers[i].interval > 0) {
                st->timers[i].when += st->timers[i].interval;
            } else {
                st->timers[i] = st->timers[--st->ntimers];
                i--;
            }
        }
    }

    return nev;
}

static void pl_destroy(hm_backend *be) {
    hm_poll_state *st = (hm_poll_state *)be->state;
    if (st) {
        if (st->sigpipe[0] >= 0) { close(st->sigpipe[0]); close(st->sigpipe[1]); }
        if (hm_poll_pipe_w == st->sigpipe[1]) hm_poll_pipe_w = -1;
        free(st->pfds);
        free(st->timers);
        free(st);
    }
    free(be);
}

hm_backend *hm_backend_poll_new(void) {
    hm_backend    *be = (hm_backend *)calloc(1, sizeof(hm_backend));
    hm_poll_state *st = (hm_poll_state *)calloc(1, sizeof(hm_poll_state));
    int i;
    if (!be || !st) { free(be); free(st); return NULL; }
    for (i = 0; i < HM_MAXFD; i++) st->idx[i] = -1;
    st->sigpipe[0] = st->sigpipe[1] = -1;
    be->name       = "poll";
    be->state      = st;
    be->add_io     = pl_add_io;
    be->modify_io  = pl_modify_io;
    be->remove_io  = pl_remove_io;
    be->add_timer  = pl_add_timer;
    be->del_timer  = pl_del_timer;
    be->add_signal = pl_add_signal;
    be->wait_ev       = pl_wait;
    be->destroy    = pl_destroy;
    return be;
}

int hm_backend_poll_available(void) { return 1; }

/* ---- backend selection: kqueue > epoll > poll, HYPERMAN_BACKEND to force */

hm_backend *hm_backend_create(const char *name) {
    if (name && *name) {
        if (strcmp(name, "kqueue")   == 0) return hm_backend_kqueue_new();
        if (strcmp(name, "io_uring") == 0) return hm_backend_iouring_new();
        if (strcmp(name, "epoll")    == 0) return hm_backend_epoll_new();
        if (strcmp(name, "poll")     == 0) return hm_backend_poll_new();
        return NULL;
    }
    /* auto: kqueue > epoll > poll; io_uring stays opt-in until benchmarked */
    {
        hm_backend *be;
        if ((be = hm_backend_kqueue_new())) return be;
        if ((be = hm_backend_iouring_new())) return be;
        if ((be = hm_backend_epoll_new()))  return be;
        return hm_backend_poll_new();
    }
}

#endif /* !_WIN32 */
