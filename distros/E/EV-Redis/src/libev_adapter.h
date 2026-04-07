/* modified version of hiredis's libev adapter */
#ifndef __HIREDIS_LIBEV_H__
#define __HIREDIS_LIBEV_H__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"

#include "hiredis.h"
#include "async.h"

typedef struct redisLibevEvents {
    redisAsyncContext *context;
    struct ev_loop *loop;
    int reading, writing, timing;
    ev_io rev, wev;
    ev_timer timer;
} redisLibevEvents;

static void redisLibevReadEvent(EV_P_ ev_io *watcher, int revents) {
#if EV_MULTIPLICITY
    ((void)loop);
#endif
    ((void)revents);

    redisLibevEvents *e = (redisLibevEvents*)watcher->data;
    if (e == NULL || e->context == NULL) return;
    redisAsyncHandleRead(e->context);
}

static void redisLibevWriteEvent(EV_P_ ev_io *watcher, int revents) {
#if EV_MULTIPLICITY
    ((void)loop);
#endif
    ((void)revents);

    redisLibevEvents *e = (redisLibevEvents*)watcher->data;
    if (e == NULL || e->context == NULL) return;
    redisAsyncHandleWrite(e->context);
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

static void redisLibevCleanup(void *privdata) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    redisAsyncContext *ctx;
    struct ev_loop *loop;
    if (e == NULL) return;

    /* Clear ev.data first to prevent double-cleanup if hiredis calls
     * cleanup multiple times (e.g., disconnect then free). */
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

    if (loop != NULL) {
        ev_io_stop(loop, &e->rev);
        ev_io_stop(loop, &e->wev);
        ev_timer_stop(loop, &e->timer);
    }

    Safefree(e);
}

static void redisLibevTimeout(EV_P_ ev_timer *timer, int revents) {
#if EV_MULTIPLICITY
    ((void)loop);
#endif
    ((void)revents);

    redisLibevEvents *e = (redisLibevEvents*)timer->data;
    if (e == NULL || e->context == NULL) return;
    redisAsyncHandleTimeout(e->context);
}

static void redisLibevSetTimeout(void *privdata, struct timeval tv) {
    redisLibevEvents *e = (redisLibevEvents*)privdata;
    struct ev_loop *loop;
    if (e == NULL) return;
    loop = e->loop;
    if (loop == NULL) return;

    e->timing = 1;
    e->timer.repeat = tv.tv_sec + tv.tv_usec / 1000000.00;
    ev_timer_again(loop, &e->timer);
}

static int redisLibevAttach(EV_P_ redisAsyncContext *ac) {
    redisContext *c = &(ac->c);
    redisLibevEvents *e;

    /* Nothing should be attached when something is already attached */
    if (ac->ev.data != NULL)
        return REDIS_ERR;

    /* Create container for context and r/w events */
    Newx(e, 1, redisLibevEvents);
    e->context = ac;
#if EV_MULTIPLICITY
    e->loop = loop;
#else
#error "EV_MULTIPLICITY is required for EV::Redis libev adapter"
#endif
    e->reading = e->writing = e->timing = 0;
    e->rev.data = (void*)e;
    e->wev.data = (void*)e;

    /* Register functions to start/stop listening for events */
    ac->ev.addRead = redisLibevAddRead;
    ac->ev.delRead = redisLibevDelRead;
    ac->ev.addWrite = redisLibevAddWrite;
    ac->ev.delWrite = redisLibevDelWrite;
    ac->ev.cleanup = redisLibevCleanup;
    ac->ev.scheduleTimer = redisLibevSetTimeout;
    ac->ev.data = e;

    /* Initialize read/write events */
    ev_io_init(&e->rev, redisLibevReadEvent, c->fd, EV_READ);
    ev_io_init(&e->wev, redisLibevWriteEvent, c->fd, EV_WRITE);

    /* Initialize timer (but don't start it) so ev_set_priority is safe */
    ev_init(&e->timer, redisLibevTimeout);
    e->timer.data = (void*)e;

    return REDIS_OK;
}

static void redisLibevSetPriority(redisAsyncContext *ac, int priority) {
    redisLibevEvents *e = (redisLibevEvents*)ac->ev.data;
    struct ev_loop *loop;
    if (e == NULL) return;

    loop = e->loop;
    if (loop == NULL) return;

    /* Stop watchers, set priority, restart if they were running */
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
        ev_timer_stop(loop, &e->timer);
        ev_set_priority(&e->timer, priority);
        ev_timer_again(loop, &e->timer);
    } else {
        ev_set_priority(&e->timer, priority);
    }
}

#endif
