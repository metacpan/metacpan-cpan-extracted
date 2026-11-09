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
/* A COMPLETION, not a readiness: the read the core asked for has already
 * happened and the bytes are in the buffer it supplied. Only a backend that
 * implements submit_recv ever produces these. */
#define HM_EV_RECV   0x10

/* one normalized event out of the backend - readiness, or a completion */
typedef struct {
    int      kind;   /* HM_EV_* */
    int      fd;     /* READ/WRITE: the fd; SIGNAL: signo */
    void    *udata;  /* TIMER: the watcher registered with add_timer */
    int      res;    /* RECV: bytes read, 0 = EOF, <0 = -errno */
    uint64_t token;  /* RECV: whatever the core passed to submit_recv */
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

    /* ---- optional: completion-based receive ----------------------------
     *
     * NULL on a readiness backend, which is all of them but io_uring - the
     * core then reads for itself exactly as it always has, and none of this
     * is reachable. The whole point of the vtable staying a superset is that
     * kqueue, epoll, poll and wsapoll are not touched by any of it.
     *
     * submit_recv asks for ONE read of up to len bytes into buf, delivered
     * later as an HM_EV_RECV carrying `token` back. The buffer must stay put
     * and untouched until that completion arrives - the kernel writes into it
     * whenever it likes.
     *
     * `token` is opaque here on purpose. The core puts an fd-plus-generation
     * in it, because a completion can outlive the connection that asked for
     * it: the fd may be closed and REUSED before the kernel gets round to
     * it, and a bare fd would then deliver another connection's bytes to
     * whoever now holds that number.
     *
     * Returns 0 if submitted, -1 if not (the core falls back to reading).
     *
     * cancel_recv drops an in-flight read at close. It is best-effort: a
     * completion may already be on its way, which is what the generation in
     * the token is for. */
    int  (*submit_recv)(hm_backend *, int fd, void *buf, size_t len,
                        uint64_t token);
    void (*cancel_recv)(hm_backend *, int fd);
};

hm_backend *hm_backend_kqueue_new(void);
int         hm_backend_kqueue_available(void);
hm_backend *hm_backend_epoll_new(void);
int         hm_backend_epoll_available(void);
hm_backend *hm_backend_poll_new(void);
int         hm_backend_poll_available(void);
hm_backend *hm_backend_wsapoll_new(void);
int         hm_backend_wsapoll_available(void);
hm_backend *hm_backend_iouring_new(void);
int         hm_backend_iouring_available(void);

/* pick by name ("kqueue"/"epoll"/"poll"), or best-available when NULL */
hm_backend *hm_backend_create(const char *name);

/* Allocation wrappers used throughout the core, backends and XS glue. An
 * out-of-memory result croaks (noreturn) rather than returning NULL, so no
 * caller has to null-check a hot-path allocation. Compiled in the single
 * Hyperman unity translation unit, after perl.h. */
#include <stdlib.h>

/* A forked child leaves by _exit, which runs no atexit handler: under a
 * coverage build its counters would be lost with it. The gcov runtime's dump
 * is bound weakly, so an ordinary build resolves it to nothing and skips it. */
#if (defined(__GNUC__) || defined(__clang__)) && !defined(_WIN32)
#include <unistd.h>
extern void __gcov_dump(void) __attribute__((weak));
static void hm_exit(int status) {
    /*
     # uncoverable branch false class:ignore_covered_err
     # uncoverable condition right count:1 class:ignore_covered_err */
    if (__gcov_dump) __gcov_dump();
    _exit(status); /* # uncoverable statement class:ignore_covered_err */
}
#else
#define hm_exit(status) _exit(status)
#endif

static void *hm_xmalloc(size_t n) {
    void *p = malloc(n);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (!p) Perl_croak_nocontext("Hyperman: out of memory (%llu bytes)",
                                 (unsigned long long)n); /* # uncoverable statement */
    return p;
}
static void *hm_xcalloc(size_t count, size_t size) {
    void *p = calloc(count, size);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (!p) Perl_croak_nocontext("Hyperman: out of memory (%llu x %llu bytes)",
                                 (unsigned long long)count, (unsigned long long)size); /* # uncoverable statement */
    return p;
}
static void *hm_xrealloc(void *old, size_t n) {
    void *p = realloc(old, n);
    /*
     # uncoverable branch true
     # uncoverable condition left count:1 class:ignore_covered_err */
    if (!p) Perl_croak_nocontext("Hyperman: out of memory (%llu bytes)",
                                 (unsigned long long)n); /* # uncoverable statement */
    return p;
}

#endif
