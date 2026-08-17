/* Hyperman::Event::WSAPoll - the Windows readiness backend.
 *
 * Same algorithm as backend_poll.c (a pollfd array with an fd->index table,
 * a deadline list for timers, a self-pipe to wake the wait), against the
 * three things Windows spells differently:
 *
 *   - WSAPoll takes SOCKETs, not our fds. Our fds ARE sockets wrapped by
 *     _open_osfhandle (hm_win.h), so each entry stores HM_SOCK(fd) for the
 *     kernel and keeps our own fd alongside to hand back in the event.
 *   - there are no signals. A console control handler - which runs on its
 *     OWN thread - sets a flag and pokes the self-pipe; wait() turns that
 *     into the HM_EV_SIGNAL the core already handles. CTRL_C -> SIGINT,
 *     CTRL_CLOSE/LOGOFF/SHUTDOWN -> SIGTERM. SIGHUP/SIGUSR1/SIGUSR2 have
 *     no source on Windows: add_signal accepts them so configuration does
 *     not have to be platform-aware, and they are simply never delivered.
 *   - there is no pipe() worth having here (WSAPoll only polls sockets), so
 *     the self-pipe is a loopback TCP pair built by hand.
 */

#include "hyperman.h"

#ifdef _WIN32

#include "hm_win.h"
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <signal.h>

typedef struct {
    double when;       /* monotonic deadline    */
    double interval;   /* 0 = one-shot          */
    void  *udata;
} hm_wstimer;

typedef struct {
    WSAPOLLFD    *pfds;
    int          *ofd;                 /* pfds[i] <-> our fd        */
    int           npfds, cap;
    int           idx[HM_MAXFD];       /* fd -> pfds index, or -1   */
    unsigned char oneshot[HM_MAXFD];   /* HM_EV_* bits to self-clear */
    hm_wstimer   *timers;
    int           ntimers, tcap;
    int           wake_r, wake_w;      /* self-pipe fds, -1 unused  */
} hm_ws_state;

/* Set by the console handler thread, drained by wait(). sig_atomic_t is
 * the right width for a flag written from another thread and read here;
 * the wake byte is what guarantees the read happens promptly. */
static volatile sig_atomic_t hm_ws_sigflag[64];
static int hm_ws_wake_w = -1;

static BOOL WINAPI hm_ws_ctrl_handler(DWORD type) {
    int signo = 0;
    switch (type) {
        case CTRL_C_EVENT:
        case CTRL_BREAK_EVENT:    signo = SIGINT;  break;
        case CTRL_CLOSE_EVENT:
        case CTRL_LOGOFF_EVENT:
        case CTRL_SHUTDOWN_EVENT: signo = SIGTERM; break;
        default: return FALSE;
    }
    if (signo > 0 && signo < 64) hm_ws_sigflag[signo] = 1;
    if (hm_ws_wake_w >= 0) {
        char b = 1;
        (void)hm_os_send(hm_ws_wake_w, &b, 1);
    }
    return TRUE;   /* handled: do not let the default terminate us */
}

/* QueryPerformanceCounter is the monotonic clock here: GetTickCount64 has
 * ~15ms granularity, which a sub-second timer would round away. */
static double hm_ws_now(void) {
    static LARGE_INTEGER freq;
    LARGE_INTEGER c;
    if (!freq.QuadPart) QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&c);
    return (double)c.QuadPart / (double)freq.QuadPart;
}

/* WSAPoll wants the NORM bits; POLLIN/POLLOUT are aliases that include the
 * band variants we never ask for. */
static SHORT hm_ws_events(int mask) {
    SHORT ev = 0;
    if (mask & HM_EV_READ)  ev |= POLLRDNORM;
    if (mask & HM_EV_WRITE) ev |= POLLWRNORM;
    return ev;
}

static int hm_ws_mask_of(SHORT events) {
    int m = 0;
    if (events & POLLRDNORM) m |= HM_EV_READ;
    if (events & POLLWRNORM) m |= HM_EV_WRITE;
    return m;
}

static int ws_add_io(hm_backend *be, int fd, int mask, int oneshot) {
    hm_ws_state *st = (hm_ws_state *)be->state;
    int i;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    i = st->idx[fd];
    if (i < 0) {
        if (st->npfds == st->cap) {
            st->cap = st->cap ? st->cap * 2 : 64;
            st->pfds = (WSAPOLLFD *)hm_xrealloc(st->pfds,
                            st->cap * sizeof(WSAPOLLFD));
            st->ofd  = (int *)hm_xrealloc(st->ofd, st->cap * sizeof(int));
        }
        i = st->npfds++;
        st->pfds[i].fd      = HM_SOCK(fd);
        st->pfds[i].events  = 0;
        st->pfds[i].revents = 0;
        st->ofd[i]          = fd;
        st->idx[fd]         = i;
    }
    st->pfds[i].events |= hm_ws_events(mask);
    if (oneshot) st->oneshot[fd] |= (unsigned char)mask;
    else         st->oneshot[fd] &= (unsigned char)~mask;
    return 0;
}

static int ws_modify_io(hm_backend *be, int fd, int mask, int oneshot) {
    return ws_add_io(be, fd, mask, oneshot);
}

static int ws_remove_io(hm_backend *be, int fd, int mask) {
    hm_ws_state *st = (hm_ws_state *)be->state;
    int i;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    i = st->idx[fd];
    if (i < 0) return 0;
    st->pfds[i].events &= ~hm_ws_events(mask);
    st->oneshot[fd] &= (unsigned char)~mask;
    if (st->pfds[i].events == 0) {
        int last = st->npfds - 1;
        if (i != last) {
            st->pfds[i] = st->pfds[last];
            st->ofd[i]  = st->ofd[last];
            st->idx[st->ofd[i]] = i;
        }
        st->npfds--;
        st->idx[fd] = -1;
    }
    return 0;
}

static int ws_add_timer(hm_backend *be, double secs, int oneshot, void *udata) {
    hm_ws_state *st = (hm_ws_state *)be->state;
    if (st->ntimers == st->tcap) {
        st->tcap = st->tcap ? st->tcap * 2 : 16;
        st->timers = (hm_wstimer *)hm_xrealloc(st->timers,
                          st->tcap * sizeof(hm_wstimer));
    }
    st->timers[st->ntimers].when     = hm_ws_now() + secs;
    st->timers[st->ntimers].interval = oneshot ? 0.0 : secs;
    st->timers[st->ntimers].udata    = udata;
    st->ntimers++;
    return 0;
}

static int ws_del_timer(hm_backend *be, void *udata) {
    hm_ws_state *st = (hm_ws_state *)be->state;
    int i;
    for (i = 0; i < st->ntimers; i++) {
        if (st->timers[i].udata == udata) {
            st->timers[i] = st->timers[--st->ntimers];
            return 0;
        }
    }
    return -1;
}

static int ws_add_signal(hm_backend *be, int signo) {
    hm_ws_state *st = (hm_ws_state *)be->state;
    if (signo <= 0 || signo >= 64) return -1;
    if (st->wake_r < 0) {
        if (hm_os_selfpipe(&st->wake_r, &st->wake_w) < 0) return -1;
        hm_ws_wake_w = st->wake_w;
        ws_add_io(be, st->wake_r, HM_EV_READ, 0);
        SetConsoleCtrlHandler(hm_ws_ctrl_handler, TRUE);
    }
    /* SIGINT and SIGTERM have a console source; the rest are accepted and
     * never delivered, which is documented rather than pretended away. */
    return 0;
}

static int ws_wait(hm_backend *be, hm_event *out, int max, double timeout) {
    hm_ws_state *st = (hm_ws_state *)be->state;
    double now = hm_ws_now();
    int tmo_ms, n, i, nev = 0;

    {
        double tmo = timeout;
        for (i = 0; i < st->ntimers; i++) {
            double d = st->timers[i].when - now;
            if (d < 0) d = 0;
            if (tmo < 0 || d < tmo) tmo = d;
        }
        tmo_ms = tmo < 0 ? -1 : (int)(tmo * 1000) + 1;
    }

    if (st->npfds == 0) {
        /* WSAPoll rejects an empty set (WSAEINVAL) where poll() would just
         * sleep; do the sleeping ourselves so a timer-only loop still runs */
        Sleep(tmo_ms < 0 ? 50 : (DWORD)tmo_ms);
        n = 0;
    } else {
        n = WSAPoll(st->pfds, (ULONG)st->npfds, tmo_ms);
        if (n == SOCKET_ERROR) {
            hm_os_seterrno();
            return -1;
        }
    }

    for (i = 0; i < st->npfds && nev < max; i++) {
        SHORT rev = st->pfds[i].revents;
        int fd = st->ofd[i];
        if (!rev) continue;

        if (st->wake_r >= 0 && fd == st->wake_r) {
            char buf[64];
            int s;
            while (hm_os_recv(st->wake_r, buf, sizeof(buf)) > 0) { }
            for (s = 1; s < 64 && nev < max; s++) {
                if (hm_ws_sigflag[s]) {
                    hm_ws_sigflag[s] = 0;
                    out[nev].kind = HM_EV_SIGNAL;
                    out[nev].fd = s;
                    out[nev].udata = NULL;
                    nev++;
                }
            }
            continue;
        }

        {
            int had = hm_ws_mask_of(st->pfds[i].events);
            int got = 0;
            if (rev & (POLLRDNORM | POLLHUP | POLLERR | POLLNVAL)) got |= HM_EV_READ;
            if (rev & (POLLWRNORM | POLLERR | POLLNVAL))           got |= HM_EV_WRITE;
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
                ws_remove_io(be, fd, st->oneshot[fd] & got);
                i--;   /* entry may have been swapped away; recheck this slot */
            }
        }
    }

    now = hm_ws_now();
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

static void ws_destroy(hm_backend *be) {
    hm_ws_state *st = (hm_ws_state *)be->state;
    if (st) {
        if (st->wake_r >= 0 && !be->foreign) {
            hm_os_close(st->wake_r);
            hm_os_close(st->wake_w);
        }
        if (hm_ws_wake_w == st->wake_w) hm_ws_wake_w = -1;
        free(st->pfds);
        free(st->ofd);
        free(st->timers);
        free(st);
    }
    free(be);
}

hm_backend *hm_backend_wsapoll_new(void) {
    hm_backend  *be = (hm_backend *)hm_xcalloc(1, sizeof(hm_backend));
    hm_ws_state *st = (hm_ws_state *)hm_xcalloc(1, sizeof(hm_ws_state));
    int i;
    if (!be || !st) { free(be); free(st); return NULL; }
    hm_os_init();
    for (i = 0; i < HM_MAXFD; i++) st->idx[i] = -1;
    st->wake_r = st->wake_w = -1;
    be->name       = "wsapoll";
    be->state      = st;
    be->add_io     = ws_add_io;
    be->modify_io  = ws_modify_io;
    be->remove_io  = ws_remove_io;
    be->add_timer  = ws_add_timer;
    be->del_timer  = ws_del_timer;
    be->add_signal = ws_add_signal;
    be->wait       = ws_wait;
    be->destroy    = ws_destroy;
    return be;
}

int hm_backend_wsapoll_available(void) { return 1; }

#else /* !_WIN32 */

hm_backend *hm_backend_wsapoll_new(void)       { return 0; }
int         hm_backend_wsapoll_available(void) { return 0; }

#endif
