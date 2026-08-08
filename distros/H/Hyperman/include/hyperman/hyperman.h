#ifndef HYPERMAN_H
#define HYPERMAN_H

/* Hyperman - shared types for the event loop core and its pluggable
 * readiness backends. The backend wraps the OS
 * mechanism (kqueue now, epoll later) behind add/modify/remove/wait; the
 * loop core and HTTP/PSGI machinery live in Hyperman.xs. */

#include <stddef.h>
#include <stdint.h>
#include <time.h>

#define HM_MAXFD   65536
#define HM_MAXEV   1024
#define HM_RBUF    16384

/* interest / event kinds */
#define HM_EV_READ   0x1
#define HM_EV_WRITE  0x2
#define HM_EV_TIMER  0x4
#define HM_EV_SIGNAL 0x8

/* one normalized readiness event out of the backend */
typedef struct {
    int      kind;   /* HM_EV_* */
    int      fd;     /* READ/WRITE: the fd; SIGNAL: signo */
    void    *udata;  /* TIMER: the watcher registered with add_timer */
} hm_event;

/* Backend interface: add($fd,$mask) / modify / remove /
 * wait($timeout) -> @ready. Timers and signals are watcher-style adds. */
typedef struct hm_backend hm_backend;
struct hm_backend {
    const char *name;
    void       *state;
    /* Set when this backend was inherited across a fork: destroy() then
     * releases its memory but closes NO descriptor, because none of them
     * belong to this process. A kqueue does not even survive fork - the
     * kernel invalidates the child's copy, so the number is free and the
     * child's own kqueue() is handed it straight back; closing it there
     * would shut the queue the child is actually using. */
    int         foreign;
    int  (*add_io)    (hm_backend *, int fd, int mask, int oneshot);
    int  (*modify_io) (hm_backend *, int fd, int mask, int oneshot);
    int  (*remove_io) (hm_backend *, int fd, int mask);
    int  (*add_timer) (hm_backend *, double secs, int oneshot, void *udata);
    int  (*del_timer) (hm_backend *, void *udata);
    int  (*add_signal)(hm_backend *, int signo);
    /* timeout < 0 waits forever; returns count or -1 (errno) */
    int  (*wait)      (hm_backend *, hm_event *out, int max, double timeout);
    void (*destroy)   (hm_backend *);
};

hm_backend *hm_backend_kqueue_new(void);
int         hm_backend_kqueue_available(void);
hm_backend *hm_backend_epoll_new(void);
int         hm_backend_epoll_available(void);
hm_backend *hm_backend_poll_new(void);
int         hm_backend_poll_available(void);
hm_backend *hm_backend_iouring_new(void);
int         hm_backend_iouring_available(void);

/* pick by name ("kqueue"/"epoll"/"poll"), or best-available when NULL */
hm_backend *hm_backend_create(const char *name);

/* Allocation wrappers used throughout the core, backends and XS glue. An
 * out-of-memory result croaks (noreturn) rather than returning NULL, so no
 * caller has to null-check a hot-path allocation. Compiled in the single
 * Hyperman unity translation unit, after perl.h. */
#include <stdlib.h>

static void *hm_xmalloc(size_t n) {
    void *p = malloc(n);
    if (!p) Perl_croak_nocontext("Hyperman: out of memory (%llu bytes)",
                                 (unsigned long long)n);
    return p;
}
static void *hm_xcalloc(size_t count, size_t size) {
    void *p = calloc(count, size);
    if (!p) Perl_croak_nocontext("Hyperman: out of memory (%llu x %llu bytes)",
                                 (unsigned long long)count, (unsigned long long)size);
    return p;
}
static void *hm_xrealloc(void *old, size_t n) {
    void *p = realloc(old, n);
    if (!p) Perl_croak_nocontext("Hyperman: out of memory (%llu bytes)",
                                 (unsigned long long)n);
    return p;
}

#endif
