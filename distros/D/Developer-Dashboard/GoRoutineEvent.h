/* GoRoutineEvent.h - single-threaded C event loop for GoRoutine.
 *
 * This header replaces GoRoutine012Native.h. There are no threads, no fork,
 * and no perl_clone here: the engine only waits (timers, IO readiness,
 * process exit) and reports which routines are due. Perl dispatches the
 * callbacks on the main thread. All state is plain malloc/free: one thread
 * and one interpreter, so nothing is ever freed across interpreters.
 *
 * Trigger kinds: a due id is returned positive when the callback should run
 * ("fire"), and negative when a timeout fired for that routine (the Perl
 * side cancels it with status timed_out). The sign encoding keeps the
 * _ev_wait return value a flat list of integers.
 *
 * Due ids are collected before any callback runs (the Perl side dispatches
 * after _ev_wait returns), so a callback that registers or cancels other
 * routines cannot corrupt the engine lists.
 *
 * Single translation unit only. This header defines static globals and
 * functions, so it is safe ONLY while exactly one translation unit
 * includes it. Today exactly one does: the build makes a single object
 * from the single XS file HtmlEscape.xs (OBJECT = HtmlEscape$(OBJ_EXT));
 * HtmlEscape.xs includes this header once at line 8 and pulls
 * GoRoutine012.xs in via INCLUDE at line 217; the generated HtmlEscape.c
 * is xsubpp output of that same file, not a second translation unit (it
 * is not in git). If a second translation unit ever includes this header,
 * each unit gets its own copies of the four globals (go_ev_timers,
 * go_ev_ios, go_ev_pids, go_ev_malloc_fail_next): silently split state,
 * and triggers that never fire. The fix shape for that day is extern
 * declarations in this header with the definitions owned behind a
 * GOROUTINE_EVENT_IMPL guard defined in HtmlEscape.xs before line 8 (not
 * in GoRoutine012.xs, which never includes this header: defining the
 * guard there would emit no definition and the link would fail on the
 * four globals).
 */
#ifndef GOROUTINE_EVENT_H
#define GOROUTINE_EVENT_H

#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#else
#include <poll.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#endif

/* ------------------------------------------------------------------ */
/* Routine-local exit (needs perl.h, included before this header)      */
/* ------------------------------------------------------------------ */
/* A runtime CORE::GLOBAL::exit override cannot scope exit() to a
 * routine: a callback is compiled long before it is dispatched, and Perl
 * resolves exit to the core op at compile time. Intercepting OP_EXIT in
 * the op dispatcher catches every exit call during dispatch, whenever the
 * code was compiled. This is the same mechanism the old threaded engine
 * used (its go_runops); the threads are gone, the op interception stays.
 * Installed only for the duration of one callback invocation. */
static int
go_ev_runops(pTHX)
{
    while (PL_op) {
        if (PL_op->op_type == OP_EXIT) {
            croak("__GOROUTINE_EXIT__");
        }
        PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX);
        PERL_ASYNC_CHECK();
    }
    return 0;
}

/* ------------------------------------------------------------------ */
/* Monotonic clock                                                     */
/* ------------------------------------------------------------------ */

static double
go_ev_now(void)
{
#ifdef _WIN32
    return (double)GetTickCount64() / 1000.0;
#else
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
        croak("go_ev_now: clock_gettime failed");
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1000000000.0;
#endif
}

/* ------------------------------------------------------------------ */
/* Process-exit check (non-reaping, same logic as process_exited)      */
/* ------------------------------------------------------------------ */

static int
go_ev_pid_exited(long pid)
{
#ifdef _WIN32
    HANDLE process;
    DWORD result;
    if (pid <= 0 || pid > 0xFFFFFFFFL)
        return 1;
    process = OpenProcess(SYNCHRONIZE, FALSE, (DWORD)pid);
    if (process == NULL)
        return GetLastError() == ERROR_INVALID_PARAMETER ? 1 : 0;
    result = WaitForSingleObject(process, 0);
    CloseHandle(process);
    return result == WAIT_OBJECT_0 ? 1 : 0;
#else
    siginfo_t info;
    int result;
    if (pid <= 0)
        return 1;
    memset(&info, 0, sizeof(info));
    do { result = waitid(P_PID, (id_t)pid, &info, WEXITED | WNOHANG | WNOWAIT); }
    while (result < 0 && errno == EINTR);
    if (result < 0 && errno == ECHILD) {
        if (kill((pid_t)pid, 0) == 0 || errno == EPERM)
            return 0;
        if (errno == ESRCH)
            return 1;
        return 0;
    }
    if (result < 0)
        return 0;
    return info.si_pid != 0 ? 1 : 0;
#endif
}

/* ------------------------------------------------------------------ */
/* Trigger lists                                                       */
/* ------------------------------------------------------------------ */

#define GO_EV_FIRE    0
#define GO_EV_TIMEOUT 1

typedef struct go_ev_timer {
    double when;            /* absolute monotonic time */
    double interval;        /* 0 = one-shot, > 0 = repeating */
    int id;                 /* routine id (Perl side) */
    int kind;               /* GO_EV_FIRE or GO_EV_TIMEOUT */
    struct go_ev_timer *next;
} go_ev_timer;

typedef struct go_ev_io {
    int id;
#ifdef _WIN32
    SOCKET fd;
#else
    int fd;
#endif
    int want_read;
    int want_write;
    int repeat;             /* 1 = stays registered after firing */
    int ready;              /* readiness sampled in the collection pass; the cancellation pass reuses it instead of re-sampling the socket */
    struct go_ev_io *next;
} go_ev_io;

typedef struct go_ev_pid {
    int id;
    long pid;
    struct go_ev_pid *next;
} go_ev_pid;

static go_ev_timer *go_ev_timers = NULL;
static go_ev_io    *go_ev_ios    = NULL;
static go_ev_pid   *go_ev_pids   = NULL;

/* Test-only fault injection: when set, the next go_ev_wait call treats
   its pollfd malloc as failed and takes the sleep branch instead of
   busy-looping. The flag is consumed on use. Production never sets it,
   so behaviour is unchanged when it is 0. On Windows the select path
   allocates nothing, so the flag has no effect there. */
static int go_ev_malloc_fail_next = 0;

static void
go_ev_fail_malloc_once(void)
{
    go_ev_malloc_fail_next = 1;
}

/* ------------------------------------------------------------------ */
/* Registration                                                        */
/* ------------------------------------------------------------------ */

static void
go_ev_add_timer(int id, double when, double interval, int kind)
{
    go_ev_timer *t = (go_ev_timer *)malloc(sizeof(*t));
    go_ev_timer **at;
    if (t == NULL)
        croak("GoRoutine: out of memory registering a timer trigger");
    t->when = when;
    t->interval = interval;
    t->id = id;
    t->kind = kind;
    /* Sorted insert by deadline, stable: equal deadlines keep insertion order. */
    at = &go_ev_timers;
    while (*at != NULL && (*at)->when <= when)
        at = &(*at)->next;
    t->next = *at;
    *at = t;
}

static void
go_ev_add_io(int id,
#ifdef _WIN32
             SOCKET fd,
#else
             int fd,
#endif
             int want_read, int want_write, int repeat)
{
    go_ev_io *io = (go_ev_io *)malloc(sizeof(*io));
    if (io == NULL)
        croak("GoRoutine: out of memory registering an IO trigger");
    io->id = id;
    io->fd = fd;
    io->want_read = want_read;
    io->want_write = want_write;
    io->repeat = repeat;
    io->ready = 0;
    io->next = go_ev_ios;
    go_ev_ios = io;
}

static void
go_ev_add_pid(int id, long pid)
{
    go_ev_pid *p = (go_ev_pid *)malloc(sizeof(*p));
    if (p == NULL)
        croak("GoRoutine: out of memory registering a process trigger");
    p->id = id;
    p->pid = pid;
    p->next = go_ev_pids;
    go_ev_pids = p;
}

/* Remove every trigger registered for one routine id. */
static void
go_ev_cancel(int id)
{
    go_ev_timer **at = &go_ev_timers;
    while (*at != NULL) {
        if ((*at)->id == id) {
            go_ev_timer *dead = *at;
            *at = dead->next;
            free(dead);
        } else {
            at = &(*at)->next;
        }
    }
    {
        go_ev_io **iat = &go_ev_ios;
        while (*iat != NULL) {
            if ((*iat)->id == id) {
                go_ev_io *dead = *iat;
                *iat = dead->next;
                free(dead);
            } else {
                iat = &(*iat)->next;
            }
        }
    }
    {
        go_ev_pid **pat = &go_ev_pids;
        while (*pat != NULL) {
            if ((*pat)->id == id) {
                go_ev_pid *dead = *pat;
                *pat = dead->next;
                free(dead);
            } else {
                pat = &(*pat)->next;
            }
        }
    }
}

/* Remove one IO node from the list, by pointer. The IO removal passes
   must use this, not go_ev_cancel: the broad cancel frees every trigger
   for the id, which would free the saved next node when one routine
   registered both a readable and a writable trigger. */
static void
go_ev_cancel_io(go_ev_io *dead)
{
    go_ev_io **at = &go_ev_ios;
    while (*at != NULL) {
        if (*at == dead) {
            *at = dead->next;
            free(dead);
            return;
        }
        at = &(*at)->next;
    }
}

/* ------------------------------------------------------------------ */
#ifdef _WIN32
/* go_ev_io_ready(io) - zero-timeout readiness check for one IO entry.
   Used when more entries are registered than one fd_set holds: Winsock
   silently drops sockets past FD_SETSIZE, so a single select over all
   of them would starve the extras. One fd per select never overflows.
   nfds is this fd + 1, not 0: Perl's headers redirect select() to
   win32_select(), which only scans fds below nfds, so passing 0 (the
   Winsock convention, where nfds is ignored) would scan nothing and no
   trigger would ever fire. */
static int
go_ev_io_ready(go_ev_io *io)
{
    struct timeval tv_zero;
    int nfds;
    tv_zero.tv_sec = 0;
    tv_zero.tv_usec = 0;
    nfds = (int)io->fd + 1;
    if (io->want_read) {
        fd_set set;
        FD_ZERO(&set);
        FD_SET(io->fd, &set);
        if (select(nfds, &set, NULL, NULL, &tv_zero) > 0
            && FD_ISSET(io->fd, &set))
            return 1;
    }
    if (io->want_write) {
        fd_set set;
        FD_ZERO(&set);
        FD_SET(io->fd, &set);
        if (select(nfds, NULL, &set, NULL, &tv_zero) > 0
            && FD_ISSET(io->fd, &set))
            return 1;
    }
    return 0;
}
#endif

/* Waiting                                                             */
/*                                                                     */
/* go_ev_wait collects due ids into the caller's buffer (capacity      */
/* given by max_due) and returns how many were stored. timeout_ms:     */
/*   >= 0 : wait at most that long for a trigger                       */
/*   < 0  : wait until the next trigger fires (or return at once when  */
/*          nothing is registered)                                     */
/*                                                                     */
/* One call collects expired timers, ready IO, and exited pids.        */
/* Repeating timers re-arm; one-shot triggers are removed as they      */
/* fire. Due ids come back in deadline order; when a routine's         */
/* fire-timer and timeout-timer are both due in one wait, the Perl     */
/* side resolves them by checking the routine's state before acting,   */
/* so the order does not matter.                                       */
/* ------------------------------------------------------------------ */

static int
go_ev_wait(long timeout_ms, int *due, int max_due)
{
    double now = go_ev_now();
    double deadline;
    long wait_ms;
    int count = 0;

    /* Expired timers first: collect and re-arm or remove. Stop at
       max_due: timers past the cap stay queued for the next call
       instead of being freed with their ids dropped. */
    while (go_ev_timers != NULL && go_ev_timers->when <= now) {
        go_ev_timer *t;
        int signed_id;
        if (count >= max_due)
            break;
        t = go_ev_timers;
        go_ev_timers = t->next;
        signed_id = t->kind == GO_EV_TIMEOUT ? -t->id : t->id;
        due[count++] = signed_id;
        if (t->interval > 0.0) {
            double next = t->when + t->interval;
            while (next <= now)
                next += t->interval;
            go_ev_add_timer(t->id, next, t->interval, t->kind);
        }
        free(t);
    }

    /* Exited pids: collect and remove. Stop at max_due, as above. */
    {
        go_ev_pid **pat = &go_ev_pids;
        while (*pat != NULL) {
            if (go_ev_pid_exited((*pat)->pid)) {
                go_ev_pid *dead;
                if (count >= max_due)
                    break;
                dead = *pat;
                *pat = dead->next;
                due[count++] = dead->id;
                free(dead);
            } else {
                pat = &(*pat)->next;
            }
        }
    }

    /* Something is already due: return it now instead of waiting for
       the next deadline. Waiting would collect timers due later into
       the same batch, and the caller dispatches the batch in order, so
       a later timer would run only after an earlier long-running
       routine returns instead of firing during it (a nested pump
       cannot dispatch it: it is no longer in the list). */
    if (count > 0)
        return count;

    /* How long to wait: the caller's bound, or the next timer deadline. */
    if (go_ev_timers != NULL)
        deadline = go_ev_timers->when;
    else
        deadline = now + 3600.0;
    wait_ms = (long)((deadline - now) * 1000.0) + 1;
    /* The +1 rounds the deadline wait UP: truncating to whole
       milliseconds would wake up to 1ms before the deadline and the
       collection below would miss the timer. */
    if (wait_ms < 0)
        wait_ms = 0;
    if (timeout_ms >= 0 && timeout_ms < wait_ms)
        wait_ms = timeout_ms;
    if (timeout_ms < 0 && go_ev_timers == NULL && go_ev_ios == NULL && go_ev_pids == NULL)
        wait_ms = 0;

    /* Wait for IO readiness, or just sleep until the deadline. Ready ids
       are collected in a first pass; non-repeating triggers are cancelled
       in a second pass, so cancelling cannot disturb the scan. */
    if (go_ev_ios != NULL) {
#ifdef _WIN32
        /* Count the IO entries first: Winsock silently drops sockets
           past FD_SETSIZE from an fd_set, so more than 64 entries
           would starve the extras. Over the limit, check each socket
           on its own with a zero-timeout select instead. */
        int n_io = 0;
        go_ev_io *io;
        for (io = go_ev_ios; io != NULL; io = io->next)
            n_io++;
        if (n_io > FD_SETSIZE) {
            int stored_io = 0;
            for (io = go_ev_ios; io != NULL; io = io->next) {
                /* Sample once and keep it: the cancellation pass below
                   reuses io->ready instead of calling go_ev_io_ready
                   again, so a socket whose readiness changes between
                   the two passes cannot be miscounted. */
                io->ready = go_ev_io_ready(io);
                if (io->ready && count < max_due) {
                    due[count++] = io->id;
                    stored_io++;
                }
            }
            {
                int seen_io = 0;
                for (io = go_ev_ios; io != NULL; ) {
                    go_ev_io *next = io->next;
                    /* Reuse the readiness sampled in the collection
                       pass; re-calling go_ev_io_ready here would
                       re-sample a live socket and could disagree. */
                    int ready = io->ready;
                    if (ready)
                        seen_io++;
                    if (ready && !io->repeat && seen_io <= stored_io)
                        go_ev_cancel_io(io);
                    io = next;
                }
            }
        } else {
            fd_set read_set, write_set;
            struct timeval tv;
            int max_fd = -1;
            FD_ZERO(&read_set);
            FD_ZERO(&write_set);
            for (io = go_ev_ios; io != NULL; io = io->next) {
                if ((int)io->fd > max_fd)
                    max_fd = (int)io->fd;
                if (io->want_read)
                    FD_SET(io->fd, &read_set);
                if (io->want_write)
                    FD_SET(io->fd, &write_set);
            }
            tv.tv_sec = (long)(wait_ms / 1000);
            tv.tv_usec = (long)((wait_ms % 1000) * 1000);
            /* A failed select leaves the fd_sets unpopulated, so only scan
               them when select reports ready fds, as the Unix poll path does.
               nfds is max_fd + 1, not 0: Perl's headers redirect select()
               to win32_select(), which only scans fds below nfds, so
               passing 0 (the Winsock convention) would scan nothing and no
               IO trigger would ever fire. */
            int sel_rc = select(max_fd + 1, &read_set, &write_set, NULL, &tv);
            if (sel_rc > 0) {
                int stored_io = 0;
                for (io = go_ev_ios; io != NULL; io = io->next) {
                    int ready = 0;
                    if (io->want_read && FD_ISSET(io->fd, &read_set))
                        ready = 1;
                    if (io->want_write && FD_ISSET(io->fd, &write_set))
                        ready = 1;
                    if (ready && count < max_due) {
                        due[count++] = io->id;
                        stored_io++;
                    }
                }
                /* Cancel only the nodes whose ids were stored above: nodes
                   past the cap stay registered for the next call. */
                {
                    int seen_io = 0;
                    for (io = go_ev_ios; io != NULL; ) {
                        go_ev_io *next = io->next;
                        int ready = 0;
                        if (io->want_read && FD_ISSET(io->fd, &read_set))
                            ready = 1;
                        if (io->want_write && FD_ISSET(io->fd, &write_set))
                            ready = 1;
                        if (ready)
                            seen_io++;
                        if (ready && !io->repeat && seen_io <= stored_io)
                            go_ev_cancel_io(io);
                        io = next;
                    }
                }
            }
        }
#else
        int n = 0;
        go_ev_io *io;
        struct pollfd *fds;
        for (io = go_ev_ios; io != NULL; io = io->next)
            n++;
        /* Test-only fault injection (see go_ev_malloc_fail_next): force
           the malloc-failure branch below, which sleeps for the wait
           period instead of busy-looping. The flag is consumed on use,
           so one call affects exactly one wait. */
        if (go_ev_malloc_fail_next) {
            go_ev_malloc_fail_next = 0;
            fds = NULL;
        } else {
            fds = (struct pollfd *)malloc(sizeof(*fds) * (size_t)(n > 0 ? n : 1));
        }
        if (fds != NULL) {
            int i = 0;
            int rc;
            for (io = go_ev_ios; io != NULL; io = io->next, i++) {
                fds[i].fd = io->fd;
                fds[i].events = 0;
                if (io->want_read)
                    fds[i].events |= POLLIN;
                if (io->want_write)
                    fds[i].events |= POLLOUT;
                fds[i].revents = 0;
            }
            do { rc = poll(fds, (nfds_t)n, (int)wait_ms); }
            while (rc < 0 && errno == EINTR);
            if (rc > 0) {
                int stored_io = 0;
                i = 0;
                for (io = go_ev_ios; io != NULL; io = io->next, i++) {
                    if (fds[i].revents != 0 && count < max_due) {
                        due[count++] = io->id;
                        stored_io++;
                    }
                }
                /* Cancel only the nodes whose ids were stored above. */
                i = 0;
                {
                    int seen_io = 0;
                    for (io = go_ev_ios; io != NULL; ) {
                        go_ev_io *next = io->next;
                        if (fds[i].revents != 0)
                            seen_io++;
                        if (fds[i].revents != 0 && !io->repeat
                            && seen_io <= stored_io)
                            go_ev_cancel_io(io);
                        io = next;
                        i++;
                    }
                }
            }
            free(fds);
        } else {
            /* malloc failed: sleep for the wait period so we do not busy-loop. */
            struct pollfd dummy;
            int rc;
            dummy.fd = -1;
            dummy.events = 0;
            dummy.revents = 0;
            do { rc = poll(&dummy, 0, (int)wait_ms); }
            while (rc < 0 && errno == EINTR);
        }
#endif
    } else if (wait_ms > 0) {
        /* No IO registered: sleep until the deadline with a zero-fd poll. */
#ifndef _WIN32
        {
            struct pollfd dummy;
            int rc;
            dummy.fd = -1;
            dummy.events = 0;
            dummy.revents = 0;
            do { rc = poll(&dummy, 0, (int)wait_ms); }
            while (rc < 0 && errno == EINTR);
        }
#else
        Sleep((DWORD)wait_ms);
#endif
    }

    /* Timers that expired during the wait. Stop at max_due, as above. */
    now = go_ev_now();
    while (go_ev_timers != NULL && go_ev_timers->when <= now) {
        go_ev_timer *t;
        int signed_id;
        if (count >= max_due)
            break;
        t = go_ev_timers;
        go_ev_timers = t->next;
        signed_id = t->kind == GO_EV_TIMEOUT ? -t->id : t->id;
        due[count++] = signed_id;
        if (t->interval > 0.0) {
            double next = t->when + t->interval;
            while (next <= now)
                next += t->interval;
            go_ev_add_timer(t->id, next, t->interval, t->kind);
        }
        free(t);
    }

    /* Pids that exited during the wait. Stop at max_due, as above. */
    {
        go_ev_pid **pat = &go_ev_pids;
        while (*pat != NULL) {
            if (go_ev_pid_exited((*pat)->pid)) {
                go_ev_pid *dead;
                if (count >= max_due)
                    break;
                dead = *pat;
                *pat = dead->next;
                due[count++] = dead->id;
                free(dead);
            } else {
                pat = &(*pat)->next;
            }
        }
    }

    return count;
}

#endif /* GOROUTINE_EVENT_H */
