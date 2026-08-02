/* Windows readiness backend + backend dispatcher, using select(). We use
 * select rather than WSAPoll because WSAPoll cannot report a failed
 * non-blocking connect (a Microsoft-acknowledged bug), whereas select flags it
 * in exceptfds - which we surface as writable so the connect path checks
 * SO_ERROR exactly as on Unix. Timers are a monotonic deadline list, like the
 * poll backend. Capacity is bounded by FD_SETSIZE (raised in ft_win.h). This
 * file compiles to nothing off Windows. */

#ifdef _WIN32

#include "ft_backend.h"
#include "ft_win.h"        /* winsock2 + raised FD_SETSIZE */
#include <windows.h>
#include <string.h>
#include <stdlib.h>

typedef struct { double when; double interval; void *udata; } hm_stimer;

typedef struct {
    int           *fds;            /* watched fds                    */
    unsigned char *masks;          /* HM_EV_* per entry              */
    unsigned char *oneshot;        /* HM_EV_* bits to self-clear     */
    int            n, cap;
    int            idx[HM_MAXFD];   /* fd -> entry index, or -1       */
    hm_stimer     *timers;
    int            ntimers, tcap;
} hm_sel_state;

static double hm_sel_now(void) {
    return (double)GetTickCount64() / 1000.0;
}

static int sl_add_io(hm_backend *be, int fd, int mask, int oneshot) {
    hm_sel_state *st = (hm_sel_state *)be->state;
    int i;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    i = st->idx[fd];
    if (i < 0) {
        if (st->n == st->cap) {
            st->cap = st->cap ? st->cap * 2 : 64;
            st->fds     = (int *)realloc(st->fds, st->cap * sizeof(int));
            st->masks   = (unsigned char *)realloc(st->masks, st->cap);
            st->oneshot = (unsigned char *)realloc(st->oneshot, st->cap);
        }
        i = st->n++;
        st->fds[i]     = fd;
        st->masks[i]   = 0;
        st->oneshot[i] = 0;
        st->idx[fd]    = i;
    }
    st->masks[i] |= (unsigned char)mask;
    if (oneshot) st->oneshot[i] |= (unsigned char)mask;
    else         st->oneshot[i] &= (unsigned char)~mask;
    return 0;
}

static int sl_modify_io(hm_backend *be, int fd, int mask, int oneshot) {
    return sl_add_io(be, fd, mask, oneshot);
}

static int sl_remove_io(hm_backend *be, int fd, int mask) {
    hm_sel_state *st = (hm_sel_state *)be->state;
    int i, last;
    if (fd < 0 || fd >= HM_MAXFD) return -1;
    i = st->idx[fd];
    if (i < 0) return 0;
    st->masks[i] &= (unsigned char)~mask;
    if (st->masks[i]) return 0;
    last = st->n - 1;
    if (i != last) {
        st->fds[i]     = st->fds[last];
        st->masks[i]   = st->masks[last];
        st->oneshot[i] = st->oneshot[last];
        st->idx[st->fds[i]] = i;
    }
    st->n--;
    st->idx[fd] = -1;
    return 0;
}

static int sl_add_timer(hm_backend *be, double secs, int oneshot, void *udata) {
    hm_sel_state *st = (hm_sel_state *)be->state;
    if (st->ntimers == st->tcap) {
        st->tcap = st->tcap ? st->tcap * 2 : 16;
        st->timers = (hm_stimer *)realloc(st->timers, st->tcap * sizeof(hm_stimer));
    }
    st->timers[st->ntimers].when     = hm_sel_now() + secs;
    st->timers[st->ntimers].interval = oneshot ? 0.0 : secs;
    st->timers[st->ntimers].udata    = udata;
    st->ntimers++;
    return 0;
}

static int sl_del_timer(hm_backend *be, void *udata) {
    hm_sel_state *st = (hm_sel_state *)be->state;
    int i;
    for (i = 0; i < st->ntimers; i++) {
        if (st->timers[i].udata == udata) {
            st->timers[i] = st->timers[--st->ntimers];
            return 0;
        }
    }
    return -1;
}

static int sl_add_signal(hm_backend *be, int signo) {
    (void)be; (void)signo;   /* the Windows client does not use signals */
    return 0;
}

static int sl_wait(hm_backend *be, hm_event *out, int max, double timeout) {
    hm_sel_state *st = (hm_sel_state *)be->state;
    fd_set rfds, wfds, efds;
    struct timeval tv, *tvp;
    double now = hm_sel_now(), tmo = timeout;
    int i, r, nev = 0;

    FD_ZERO(&rfds); FD_ZERO(&wfds); FD_ZERO(&efds);
    for (i = 0; i < st->n; i++) {
        SOCKET s = FT_SOCK(st->fds[i]);
        if (s == INVALID_SOCKET) continue;
        if (st->masks[i] & HM_EV_READ)  FD_SET(s, &rfds);
        if (st->masks[i] & HM_EV_WRITE) { FD_SET(s, &wfds); FD_SET(s, &efds); }
    }

    for (i = 0; i < st->ntimers; i++) {
        double d = st->timers[i].when - now;
        if (d < 0) d = 0;
        if (tmo < 0 || d < tmo) tmo = d;
    }
    if (tmo < 0) { tvp = NULL; }
    else { tv.tv_sec = (long)tmo; tv.tv_usec = (long)((tmo - tv.tv_sec) * 1e6); tvp = &tv; }

    r = select(0, (st->n ? &rfds : NULL), (st->n ? &wfds : NULL),
                  (st->n ? &efds : NULL), tvp);
    if (r == SOCKET_ERROR) {
        if (WSAGetLastError() == WSAEINTR) return 0;
        return -1;
    }

    for (i = 0; i < st->n && nev < max; i++) {
        int fd = st->fds[i];
        SOCKET s = FT_SOCK(fd);
        int had = st->masks[i], got = 0;
        if (s == INVALID_SOCKET) continue;
        if (FD_ISSET(s, &rfds)) got |= HM_EV_READ;
        if (FD_ISSET(s, &wfds)) got |= HM_EV_WRITE;
        if (FD_ISSET(s, &efds)) got |= HM_EV_WRITE;   /* connect failure */
        got &= had;
        if (!got) continue;
        if (got & HM_EV_READ) {
            out[nev].kind = HM_EV_READ; out[nev].fd = fd; out[nev].udata = NULL; nev++;
        }
        if ((got & HM_EV_WRITE) && nev < max) {
            out[nev].kind = HM_EV_WRITE; out[nev].fd = fd; out[nev].udata = NULL; nev++;
        }
        if (st->oneshot[i] & got) {
            sl_remove_io(be, fd, st->oneshot[i] & got);
            i--;   /* entry swapped away; recheck this slot */
        }
    }

    now = hm_sel_now();
    for (i = 0; i < st->ntimers && nev < max; i++) {
        if (st->timers[i].when <= now) {
            out[nev].kind = HM_EV_TIMER; out[nev].fd = -1;
            out[nev].udata = st->timers[i].udata; nev++;
            if (st->timers[i].interval > 0) st->timers[i].when += st->timers[i].interval;
            else { st->timers[i] = st->timers[--st->ntimers]; i--; }
        }
    }
    return nev;
}

static void sl_destroy(hm_backend *be) {
    hm_sel_state *st = (hm_sel_state *)be->state;
    if (st) { free(st->fds); free(st->masks); free(st->oneshot); free(st->timers); free(st); }
    free(be);
}

static hm_backend *hm_backend_select_new(void) {
    hm_backend   *be = (hm_backend *)calloc(1, sizeof(hm_backend));
    hm_sel_state *st = (hm_sel_state *)calloc(1, sizeof(hm_sel_state));
    int i;
    if (!be || !st) { free(be); free(st); return NULL; }
    for (i = 0; i < HM_MAXFD; i++) st->idx[i] = -1;
    ft_win_init();
    be->name       = "select";
    be->state      = st;
    be->add_io     = sl_add_io;
    be->modify_io  = sl_modify_io;
    be->remove_io  = sl_remove_io;
    be->add_timer  = sl_add_timer;
    be->del_timer  = sl_del_timer;
    be->add_signal = sl_add_signal;
    be->wait       = sl_wait;
    be->destroy    = sl_destroy;
    return be;
}

/* Windows has one backend; honour an explicit "select" name, else default. */
hm_backend *hm_backend_create(const char *name) {
    if (name && *name && strcmp(name, "select") != 0) return NULL;
    return hm_backend_select_new();
}

#endif /* _WIN32 */
