/* Hyperman::Event::Epoll - the Linux readiness backend. Implements the
 * hm_backend interface from hyperman.h: io via epoll_ctl (per-fd combined
 * mask, oneshot emulated by clearing after delivery), timers via
 * timerfd_create, signals via signalfd (the signals are blocked and read
 * as data). */

#include "hyperman.h"

#ifdef __linux__
#define HM_HAVE_EPOLL 1
#endif

#ifdef HM_HAVE_EPOLL

#include <sys/epoll.h>
#include <sys/timerfd.h>
#include <sys/signalfd.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

#define EP_NONE   0
#define EP_IO     1
#define EP_TIMER  2
#define EP_SIGNAL 3

typedef struct {
    int            ep;                 /* epoll fd                       */
    int            sfd;                /* signalfd, -1 until first signal */
    sigset_t       sigs;
    unsigned char  kind[HM_MAXFD];     /* EP_* per registered fd          */
    unsigned char  mask[HM_MAXFD];     /* current HM_EV_ bits (io fds)    */
    unsigned char  once[HM_MAXFD];     /* oneshot HM_EV_ bits (io fds)    */
    void          *tudata[HM_MAXFD];   /* timerfd -> watcher udata        */
    unsigned char  toneshot[HM_MAXFD];
} hm_ep_state;

static int ep_ctl_io(hm_ep_state *st, int fd) {
    struct epoll_event ev;
    int op;
    memset(&ev, 0, sizeof(ev));
    ev.data.fd = fd;
    if (st->mask[fd] & HM_EV_READ)  ev.events |= EPOLLIN;
    if (st->mask[fd] & HM_EV_WRITE) ev.events |= EPOLLOUT;
    if (st->mask[fd] == 0) {
        st->kind[fd] = EP_NONE;
        return epoll_ctl(st->ep, EPOLL_CTL_DEL, fd, NULL);
    }
    op = (st->kind[fd] == EP_IO) ? EPOLL_CTL_MOD : EPOLL_CTL_ADD;
    st->kind[fd] = EP_IO;
    return epoll_ctl(st->ep, op, fd, &ev);
}

static int ep_add_io(hm_backend *be, int fd, int mask, int oneshot) {
    hm_ep_state *st = (hm_ep_state *)be->state;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    st->mask[fd] |= (unsigned char)mask;
    if (oneshot) st->once[fd] |= (unsigned char)mask;
    else         st->once[fd] &= (unsigned char)~mask;
    return ep_ctl_io(st, fd);
}

static int ep_modify_io(hm_backend *be, int fd, int mask, int oneshot) {
    return ep_add_io(be, fd, mask, oneshot);
}

static int ep_remove_io(hm_backend *be, int fd, int mask) {
    hm_ep_state *st = (hm_ep_state *)be->state;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    if (st->kind[fd] != EP_IO) return 0;
    st->mask[fd] &= (unsigned char)~mask;
    st->once[fd] &= (unsigned char)~mask;
    return ep_ctl_io(st, fd);
}

static int ep_add_timer(hm_backend *be, double secs, int oneshot, void *udata) {
    hm_ep_state *st = (hm_ep_state *)be->state;
    struct itimerspec its;
    struct epoll_event ev;
    int tfd = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK | TFD_CLOEXEC);
    if (tfd < 0 || tfd >= HM_MAXFD) { if (tfd >= 0) close(tfd); return -1; }
    memset(&its, 0, sizeof(its));
    its.it_value.tv_sec  = (time_t)secs;
    its.it_value.tv_nsec = (long)((secs - (double)its.it_value.tv_sec) * 1e9);
    if (its.it_value.tv_sec == 0 && its.it_value.tv_nsec == 0)
        its.it_value.tv_nsec = 1;
    if (!oneshot) its.it_interval = its.it_value;
    if (timerfd_settime(tfd, 0, &its, NULL) < 0) { close(tfd); return -1; }
    st->kind[tfd] = EP_TIMER;
    st->tudata[tfd] = udata;
    st->toneshot[tfd] = (unsigned char)(oneshot ? 1 : 0);
    memset(&ev, 0, sizeof(ev));
    ev.events = EPOLLIN;
    ev.data.fd = tfd;
    return epoll_ctl(st->ep, EPOLL_CTL_ADD, tfd, &ev);
}

static int ep_del_timer(hm_backend *be, void *udata) {
    hm_ep_state *st = (hm_ep_state *)be->state;
    int fd;
    for (fd = 0; fd < HM_MAXFD; fd++) {
        if (st->kind[fd] == EP_TIMER && st->tudata[fd] == udata) {
            epoll_ctl(st->ep, EPOLL_CTL_DEL, fd, NULL);
            close(fd);
            st->kind[fd] = EP_NONE;
            st->tudata[fd] = NULL;
            return 0;
        }
    }
    return -1;
}

static int ep_add_signal(hm_backend *be, int signo) {
    hm_ep_state *st = (hm_ep_state *)be->state;
    sigaddset(&st->sigs, signo);
    if (sigprocmask(SIG_BLOCK, &st->sigs, NULL) < 0) return -1;
    {
        int sfd = signalfd(st->sfd, &st->sigs, SFD_NONBLOCK | SFD_CLOEXEC);
        if (sfd < 0) return -1;
        if (st->sfd < 0) {
            struct epoll_event ev;
            st->sfd = sfd;
            st->kind[sfd] = EP_SIGNAL;
            memset(&ev, 0, sizeof(ev));
            ev.events = EPOLLIN;
            ev.data.fd = sfd;
            return epoll_ctl(st->ep, EPOLL_CTL_ADD, sfd, &ev);
        }
    }
    return 0;
}

static int ep_wait(hm_backend *be, hm_event *out, int max, double timeout) {
    hm_ep_state *st = (hm_ep_state *)be->state;
    struct epoll_event evs[HM_MAXEV];
    int tmo_ms = timeout < 0 ? -1 : (int)(timeout * 1000);
    int n, i, nev = 0;
    if (max > HM_MAXEV) max = HM_MAXEV;
    n = epoll_wait(st->ep, evs, max, tmo_ms);
    if (n < 0) return (errno == EINTR) ? 0 : -1;
    for (i = 0; i < n && nev < max; i++) {
        int fd = evs[i].data.fd;
        switch (st->kind[fd]) {
        case EP_TIMER: {
            unsigned long long exp;
            ssize_t r = read(fd, &exp, sizeof(exp));
            (void)r;
            out[nev].kind = HM_EV_TIMER;
            out[nev].fd = -1;
            out[nev].udata = st->tudata[fd];
            nev++;
            if (st->toneshot[fd]) {
                epoll_ctl(st->ep, EPOLL_CTL_DEL, fd, NULL);
                close(fd);
                st->kind[fd] = EP_NONE;
                st->tudata[fd] = NULL;
            }
            break;
        }
        case EP_SIGNAL: {
            struct signalfd_siginfo si;
            while (nev < max
                   && read(fd, &si, sizeof(si)) == (ssize_t)sizeof(si)) {
                out[nev].kind = HM_EV_SIGNAL;
                out[nev].fd = (int)si.ssi_signo;
                out[nev].udata = NULL;
                nev++;
            }
            break;
        }
        default: {
            unsigned ev = evs[i].events;
            int got = 0;
            if (ev & (EPOLLIN  | EPOLLHUP | EPOLLERR)) got |= HM_EV_READ;
            if (ev & (EPOLLOUT | EPOLLHUP | EPOLLERR)) got |= HM_EV_WRITE;
            got &= st->mask[fd];
            if (!got) got = st->mask[fd];
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
            if (st->once[fd] & got)
                ep_remove_io(be, fd, st->once[fd] & got);
            break;
        }
        }
    }
    return nev;
}

static void ep_destroy(hm_backend *be) {
    hm_ep_state *st = (hm_ep_state *)be->state;
    if (st) {
        /* be->foreign: inherited across a fork - these descriptors are the
         * parent's, and closing our duplicates only frees numbers the child
         * has already reused */
        if (!be->foreign) {
            int fd;
            for (fd = 0; fd < HM_MAXFD; fd++)
                if (st->kind[fd] == EP_TIMER) close(fd);
            if (st->sfd >= 0) close(st->sfd);
            if (st->ep >= 0) close(st->ep);
        }
        free(st);
    }
    free(be);
}

hm_backend *hm_backend_epoll_new(void) {
    hm_backend  *be = (hm_backend *)hm_xcalloc(1, sizeof(hm_backend));
    hm_ep_state *st = (hm_ep_state *)hm_xcalloc(1, sizeof(hm_ep_state));
    if (!be || !st) { free(be); free(st); return NULL; }
    st->ep = epoll_create1(EPOLL_CLOEXEC);
    if (st->ep < 0) { free(be); free(st); return NULL; }
    st->sfd = -1;
    sigemptyset(&st->sigs);
    be->name       = "epoll";
    be->state      = st;
    be->add_io     = ep_add_io;
    be->modify_io  = ep_modify_io;
    be->remove_io  = ep_remove_io;
    be->add_timer  = ep_add_timer;
    be->del_timer  = ep_del_timer;
    be->add_signal = ep_add_signal;
    be->wait       = ep_wait;
    be->destroy    = ep_destroy;
    return be;
}

int hm_backend_epoll_available(void) { return 1; }

#else /* !HM_HAVE_EPOLL */

hm_backend *hm_backend_epoll_new(void)       { return 0; }
int         hm_backend_epoll_available(void) { return 0; }

#endif
