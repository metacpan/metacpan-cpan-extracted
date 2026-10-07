/* modified version of hiredis's libev adapter */
#ifndef __HIREDIS_LIBEV_H__
#define __HIREDIS_LIBEV_H__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"

#include <poll.h>

#include "hiredis.h"
#include "async.h"
#include "net.h"
#include <errno.h>

/* hiredis.c, not in its public headers */
void __redisSetError(redisContext *c, int type, const char *str);

typedef struct redisLibevEvents {
    redisAsyncContext *context;
    struct ev_loop *loop;
    int reading, writing, timing;
    int timing_connected; /* the armed timer belongs to the connected phase */
    void *armed_for; /* the reply record it was armed for; the adapter itself
                      * once a read pushed it for the whole queue */
    int *gone; /* set by cleanup, for a caller that must not touch e after */
    int sending; /* the last write left part of the output unsent */
    int parked_read, parked_write; /* stopped while a callback of it runs */
    size_t obuf_sent; /* written head of obuf that hiredis has not dropped yet */
    unsigned int fork_gen;
    HV *unsubs[2]; /* overlapping channel/pattern unsubscribe confirmations */
    ev_io rev, wev;
    ev_timer timer;
} redisLibevEvents;

/* bumped in each forked child: an inherited context would take the parent's replies */
static unsigned int redisLibevForkGen;

static void redisLibevAtforkChild(void) {
    redisLibevForkGen++;
}

/* an inherited context fails as a lost connection without reading or writing:
 * hiredis checks c->err before any read. The context may be gone after. */
static int redisLibevInherited(redisLibevEvents *e) {
    redisAsyncContext *ac = e->context;
    if (e->fork_gen == redisLibevForkGen) return 0;
    if (!ac->c.err) {
        __redisSetError(&ac->c, REDIS_ERR_IO,
                        "connection inherited from the parent process");
    }
    ac->err = ac->c.err;
    ac->errstr = ac->c.errstr;
    /* still connecting: redisAsyncHandleRead would call connect() on the
     * shared socket and wait for it; the timeout path fails it untouched */
    if (!(ac->c.flags & REDIS_CONNECTED)) redisAsyncHandleTimeout(ac);
    else redisAsyncHandleRead(ac);
    return 1;
}

/* A nested loop in a callback would trip assert(!REDIS_IN_CALLBACK): the io
 * watchers, level-triggered, are parked until it returns (redisLibevResumeParked)
 * or the loop would spin; the repeating timer just fires again later. */
#define REDIS_LIBEV_IN_CALLBACK(e) ((e)->context->c.flags & REDIS_IN_CALLBACK)

static void redisLibevAddRead(void *privdata);
static void redisLibevDelRead(void *privdata);
static void redisLibevAddWrite(void *privdata);
static void redisLibevDelWrite(void *privdata);

#ifdef EV_REDIS_SSL
#include <openssl/ssl.h>
#include <openssl/err.h>
/* OpenSSL judges an I/O result by its per-thread error queue, which hiredis
 * empties only when connecting: a stale error would fail the next read or write */
#define REDIS_LIBEV_BEFORE_IO(e) \
    do { if (NULL != (e)->context->c.privctx) ERR_clear_error(); } while (0)

/* Once a read found no data, hiredis parks unfinished writes until the next
 * read, also when SSL_write only filled the socket: a large command would stall.
 * Its private struct behind privctx (deps/hiredis/ssl.c) starts with the SSL*. */
static void redisLibevResumeWrite(redisLibevEvents *e) {
    redisContext *c = &e->context->c;
    if (NULL != c->privctx && !e->writing && sdslen(c->obuf) > 0
            && SSL_READING != SSL_want(*(SSL **)c->privctx)) {
        redisLibevAddWrite(e);
    }
}
#else
#define REDIS_LIBEV_BEFORE_IO(e)
#define redisLibevResumeWrite(e)
#endif

static void redisLibevRead(redisLibevEvents *e) {
    /* incoming data is progress: push the command timeout */
    if (e->timing && e->timing_connected) {
        e->armed_for = (void*)e;
        ev_now_update(e->loop);
        ev_timer_again(e->loop, &e->timer);
    }
    REDIS_LIBEV_BEFORE_IO(e);
    redisAsyncHandleRead(e->context);
}

static void redisLibevReadEvent(EV_P_ ev_io *watcher, int revents) {
#if EV_MULTIPLICITY
    ((void)loop);
#endif
    ((void)revents);

    redisLibevEvents *e = (redisLibevEvents*)watcher->data;
    if (e == NULL || e->context == NULL) return;
    if (REDIS_LIBEV_IN_CALLBACK(e)) {
        redisLibevDelRead(e);
        e->parked_read = 1;
        return;
    }
    if (redisLibevInherited(e)) return;
    redisLibevRead(e);
}

static void redisLibevWriteEvent(EV_P_ ev_io *watcher, int revents) {
#if EV_MULTIPLICITY
    ((void)loop);
#endif
    ((void)revents);

    redisLibevEvents *e = (redisLibevEvents*)watcher->data;
    size_t before, after;
    int gone = 0;
    if (e == NULL || e->context == NULL) return;
    if (REDIS_LIBEV_IN_CALLBACK(e)) {
        redisLibevDelWrite(e);
        e->parked_write = 1;
        return;
    }
    if (redisLibevInherited(e)) return;
    before = sdslen(e->context->c.obuf) - e->obuf_sent;
    e->gone = &gone;
    REDIS_LIBEV_BEFORE_IO(e);
    redisAsyncHandleWrite(e->context);
    if (gone) return;
    e->gone = NULL;
    redisLibevResumeWrite(e);
    /* progress is output draining over several writes, not one write sending it
     * all; TLS keeps the whole buffer until it is out, so there it is a write
     * event with output pending, unless parked until a read (watcher stopped) */
    after = sdslen(e->context->c.obuf) - e->obuf_sent;
    if (e->timing && e->timing_connected
            && (after < before ? (after > 0 || e->sending)
                               : (after > 0 && e->writing && NULL != e->context->c.privctx))) {
        e->armed_for = (void*)e;
        ev_now_update(e->loop);
        ev_timer_again(e->loop, &e->timer);
    }
    e->sending = after > 0;
}

static void redisLibevAddRead(void *privdata) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    struct ev_loop *loop;
    if (e == NULL) return;
    loop = e->loop;
    if (loop == NULL) return;
    if (!e->reading) {
        e->reading = 1;
        ev_io_start(loop, &e->rev);
    }
}

static void redisLibevDelRead(void *privdata) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    struct ev_loop *loop;
    if (e == NULL) return;
    loop = e->loop;
    if (e->reading) {
        e->reading = 0;
        if (loop != NULL) ev_io_stop(loop, &e->rev);
    }
}

static void redisLibevAddWrite(void *privdata) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    struct ev_loop *loop;
    if (e == NULL) return;
    loop = e->loop;
    if (loop == NULL) return;
    if (!e->writing) {
        e->writing = 1;
        ev_io_start(loop, &e->wev);
    }
}

static void redisLibevDelWrite(void *privdata) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    struct ev_loop *loop;
    if (e == NULL) return;
    loop = e->loop;
    if (e->writing) {
        e->writing = 0;
        if (loop != NULL) ev_io_stop(loop, &e->wev);
    }
}

/* Call once a hiredis callback of ac has returned: hiredis runs them all
 * before its cleanup, so ev.data is still this adapter or NULL. */
static void redisLibevResumeParked(redisAsyncContext *ac) {
    redisLibevEvents *e = (redisLibevEvents*)ac->ev.data;
    if (e == NULL) return;
    if (e->parked_read) {
        e->parked_read = 0;
        redisLibevAddRead(e);
    }
    if (e->parked_write) {
        e->parked_write = 0;
        redisLibevAddWrite(e);
    }
}

static void redisLibevCleanup(void *privdata) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    redisAsyncContext *ctx;
    struct ev_loop *loop;
    if (e == NULL) return;

    /* hiredis keeps the other hooks installed: they must find no adapter */
    ctx = e->context;
    if (ctx != NULL) {
        ctx->ev.data = NULL;
    }

    loop = e->loop;
    e->loop = NULL;
    e->context = NULL;

    e->rev.data = NULL;
    e->wev.data = NULL;
    e->timer.data = NULL;
    if (e->gone != NULL) *e->gone = 1;

    if (loop != NULL) {
        ev_io_stop(loop, &e->rev);
        ev_io_stop(loop, &e->wev);
        ev_timer_stop(loop, &e->timer);
    }

    /* Global destruction frees Perl's arenas, possibly before this context. */
    if (!PL_dirty) {
        if (e->unsubs[0] != NULL) SvREFCNT_dec((SV*)e->unsubs[0]);
        if (e->unsubs[1] != NULL) SvREFCNT_dec((SV*)e->unsubs[1]);
    }
    Safefree(e);
}

static void redisLibevTimeout(EV_P_ ev_timer *timer, int revents) {
#if EV_MULTIPLICITY
    ((void)loop);
#endif
    ((void)revents);

    redisLibevEvents *e = (redisLibevEvents*)timer->data;
    redisContext *c;
    struct pollfd pfd;
    if (e == NULL || e->context == NULL) return;
    if (REDIS_LIBEV_IN_CALLBACK(e)) return;
    if (redisLibevInherited(e)) return;

    /* libev runs an expired timer ahead of I/O that became ready in the same
     * iteration: after the loop was blocked, the answer may be waiting */
    c = &e->context->c;
    if (c->fd != REDIS_INVALID_FD) {
        pfd.fd = c->fd;
        pfd.events = (c->flags & REDIS_CONNECTED) ? POLLIN : POLLOUT;
        pfd.revents = 0;
        if (poll(&pfd, 1, 0) > 0) {
            int gone = 0;
            if (c->flags & REDIS_CONNECTED) {
                redisLibevRead(e);
                return;
            }
            /* let hiredis finish the connect; one still in progress (a unix
             * socket refused by a full backlog stays writable) times out */
            e->gone = &gone;
            REDIS_LIBEV_BEFORE_IO(e);
            redisAsyncHandleWrite(e->context);
            if (gone) return;
            e->gone = NULL;
            redisLibevResumeWrite(e);
            if (c->flags & REDIS_CONNECTED) return;
        }
    }
    /* connected with nothing to time: stop repeating, the next command re-arms */
    if ((c->flags & REDIS_CONNECTED)
            && ((NULL == e->context->replies.head && NULL == e->context->sub.replies.head)
                || NULL == c->command_timeout
                || (0 == c->command_timeout->tv_sec && 0 == c->command_timeout->tv_usec))) {
        e->timing = 0;
        ev_timer_stop(e->loop, &e->timer);
        return;
    }
    redisAsyncHandleTimeout(e->context);
}

/* both lists: once subscribed, hiredis queues command replies in sub.replies */
static int redisLibevSeveralOutstanding(redisAsyncContext *ac) {
    return ac->replies.head != ac->replies.tail
        || ac->sub.replies.head != ac->sub.replies.tail
        || (ac->replies.head && ac->sub.replies.head);
}

/* (P)(UN)SUBSCRIBE add no record, so they cannot pass for a new reply */
static void *redisLibevFirstOutstanding(redisAsyncContext *ac) {
    return ac->replies.head ? (void*)ac->replies.head : (void*)ac->sub.replies.head;
}

/* before a command with its own reply record: an idle connection gets a fresh deadline */
static void redisLibevExpectNewReply(redisAsyncContext *ac) {
    redisLibevEvents *e = (redisLibevEvents*)ac->ev.data;
    if (e != NULL && redisLibevFirstOutstanding(ac) == NULL) e->armed_for = NULL;
}

/* hiredis calls this on every command, read and write. Connecting, keep the
 * connect's deadline; connected, re-arm only for a new first outstanding reply:
 * incoming data pushes it (redisLibevRead), new commands must not. */
static void redisLibevSetTimeout(void *privdata, struct timeval tv) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    struct ev_loop *loop;
    void *first;
    int connected;
    if (e == NULL) return;
    loop = e->loop;
    if (loop == NULL) return;

    connected = (e->context->c.flags & REDIS_CONNECTED) ? 1 : 0;
    first = connected ? redisLibevFirstOutstanding(e->context) : NULL;
    if (e->timing && e->timing_connected == connected
            && (!connected || redisLibevSeveralOutstanding(e->context)
                || first == e->armed_for || e->armed_for == (void*)e)) {
        return;
    }

    e->timing = 1;
    e->timing_connected = connected;
    e->armed_for = first;
    e->timer.repeat = tv.tv_sec + tv.tv_usec / 1000000.00;
    /* a connect outside ev_run or a long callback leaves ev_now stale */
    ev_now_update(loop);
    ev_timer_again(loop, &e->timer);
}

/* hiredis moves the unsent rest of obuf to its head after each partial write,
 * quadratic in a large buffer: report a write only once it covers what is left */
static ssize_t redisLibevNetWrite(redisContext *c) {
    redisLibevEvents *e = (redisLibevEvents*)((redisAsyncContext*)c)->ev.data;
    size_t len = sdslen(c->obuf);
    size_t off = (e != NULL && e->obuf_sent < len) ? e->obuf_sent : 0;
    ssize_t n = send(c->fd, c->obuf + off, len - off, 0);

    if (n < 0) {
        if (errno == EWOULDBLOCK || errno == EAGAIN || errno == EINTR) return 0;
        if (e != NULL) e->obuf_sent = 0;
        __redisSetError(c, REDIS_ERR_IO, strerror(errno));
        return -1;
    }
    off += (size_t)n;
    if (e == NULL || off == len || off >= len - off) {
        if (e != NULL) e->obuf_sent = 0;
        return (ssize_t)off;
    }
    e->obuf_sent = off;
    return 0;
}

static redisContextFuncs redisLibevNetFuncs;

/* plain TCP and unix only: TLS keeps the whole buffer until it is all out */
static void redisLibevUseNetWrite(redisContext *c) {
    if (c->funcs->write != redisNetWrite) return;
    if (redisLibevNetFuncs.write == NULL) {
        redisLibevNetFuncs = *c->funcs;
        redisLibevNetFuncs.write = redisLibevNetWrite;
    }
    c->funcs = &redisLibevNetFuncs;
}

static int redisLibevAttach(EV_P_ redisAsyncContext *ac) {
    redisContext *c = &(ac->c);
    redisLibevEvents *e;

    if (ac->ev.data != NULL)
        return REDIS_ERR;

    Newx(e, 1, redisLibevEvents);
    e->context = ac;
#if EV_MULTIPLICITY
    e->loop = loop;
#else
#error "EV_MULTIPLICITY is required for EV::Redis libev adapter"
#endif
    e->reading = e->writing = e->timing = e->timing_connected = 0;
    e->armed_for = NULL;
    e->gone = NULL;
    e->sending = 0;
    e->parked_read = e->parked_write = 0;
    e->obuf_sent = 0;
    e->fork_gen = redisLibevForkGen;
    e->unsubs[0] = e->unsubs[1] = NULL;
    e->rev.data = (void*)e;
    e->wev.data = (void*)e;

    ac->ev.addRead = redisLibevAddRead;
    ac->ev.delRead = redisLibevDelRead;
    ac->ev.addWrite = redisLibevAddWrite;
    ac->ev.delWrite = redisLibevDelWrite;
    ac->ev.cleanup = redisLibevCleanup;
    ac->ev.scheduleTimer = redisLibevSetTimeout;
    ac->ev.data = e;

    ev_io_init(&e->rev, redisLibevReadEvent, c->fd, EV_READ);
    ev_io_init(&e->wev, redisLibevWriteEvent, c->fd, EV_WRITE);

    /* init now: redisLibevSetPriority may run before the first schedule */
    ev_init(&e->timer, redisLibevTimeout);
    e->timer.data = (void*)e;

    return REDIS_OK;
}

/* redisAsyncSetTimeout leaves an armed timer on its old deadline until the next I/O */
static void redisLibevRefreshTimeout(redisAsyncContext *ac, struct timeval tv) {
    redisLibevEvents *e = (redisLibevEvents*)ac->ev.data;
    struct ev_loop *loop;
    if (e == NULL) return;
    loop = e->loop;
    if (loop == NULL) return;

    if (tv.tv_sec || tv.tv_usec) {
        e->timing = 1;
        e->timing_connected = (ac->c.flags & REDIS_CONNECTED) ? 1 : 0;
        e->armed_for = redisLibevFirstOutstanding(ac);
        e->timer.repeat = tv.tv_sec + tv.tv_usec / 1000000.00;
        ev_now_update(loop);
        ev_timer_again(loop, &e->timer);
    }
    else {
        e->timing = 0;
        e->timer.repeat = 0.;
        ev_timer_stop(loop, &e->timer);
    }
}

static void redisLibevSetPriority(redisAsyncContext *ac, int priority) {
    redisLibevEvents *e = (redisLibevEvents*)ac->ev.data;
    struct ev_loop *loop;
    if (e == NULL) return;

    loop = e->loop;
    if (loop == NULL) return;

    /* ev_set_priority is only valid on an inactive watcher */
    if (e->reading) {
        ev_io_stop(loop, &e->rev);
        ev_set_priority(&e->rev, priority);
        ev_io_start(loop, &e->rev);
    } else {
        ev_set_priority(&e->rev, priority);
    }

    if (e->writing) {
        ev_io_stop(loop, &e->wev);
        ev_set_priority(&e->wev, priority);
        ev_io_start(loop, &e->wev);
    } else {
        ev_set_priority(&e->wev, priority);
    }

    if (e->timing) {
        /* keep the deadline: a priority change is not progress; an expired
         * timer is already pending and re-armed, so fire it right away */
        ev_tstamp left = ev_is_pending(&e->timer) ? 0. : ev_timer_remaining(loop, &e->timer);
        ev_timer_stop(loop, &e->timer);
        ev_set_priority(&e->timer, priority);
        ev_timer_set(&e->timer, left, e->timer.repeat);
        ev_timer_start(loop, &e->timer);
    } else {
        ev_set_priority(&e->timer, priority);
    }
}

#endif
