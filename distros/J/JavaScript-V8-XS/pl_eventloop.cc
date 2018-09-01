/*
 *  Timer insertion is an O(n) operation; in a real world eventloop based on a
 *  heap insertion would be O(log N).
 */
#include <stdio.h>
#include <poll.h>
#include <v8.h>
#include "pl_util.h"
#include "pl_eval.h"
#include "pl_console.h"
#include "pl_eventloop.h"

#if !defined(EVENTLOOP_DEBUG)
#define EVENTLOOP_DEBUG 0       /* set to 1 to debug with printf */
#endif

#define  MIN_DELAY              1.0
#define  MIN_WAIT               1.0
#define  MAX_WAIT               60000.0
#define  MAX_EXPIRIES           10
#define  MAX_TIMERS             4096     /* this is quite excessive for embedded use, but good for testing */

typedef struct {
    int64_t id;       /* numeric ID (returned from e.g. setTimeout); zero if unused */
    double target;    /* next target time */
    double delay;     /* delay/interval */
    int oneshot;      /* oneshot=1 (setTimeout), repeated=0 (setInterval) */
    int removed;      /* timer has been requested for removal */
    Persistent<Function> v8_func;       /* callback associated with the timer */
} ev_timer;

/* Active timers.  Dense list, terminates to end of list or first unused timer.
 * The list is sorted by 'target', with lowest 'target' (earliest expiry) last
 * in the list.  When a timer's callback is being called, the timer is moved
 * to 'timer_expiring' as it needs special handling should the user callback
 * delete that particular timer.
 */
static ev_timer timer_list[MAX_TIMERS];
static ev_timer timer_expiring;
static int timer_count;  /* last timer at timer_count - 1 */
static int64_t timer_next_id = 1;

static ev_timer *find_nearest_timer(void) {
    /* Last timer expires first (list is always kept sorted). */
    if (timer_count <= 0) {
        return NULL;
    }
    return timer_list + timer_count - 1;
}

/* Bubble last timer on timer list backwards until it has been moved to
 * its proper sorted position (based on 'target' time).
 */
static void bubble_last_timer(void) {
    int i;
    int n = timer_count;
    ev_timer *t;
    ev_timer tmp;

    for (i = n - 1; i > 0; i--) {
        /* Timer to bubble is at index i, timer to compare to is
         * at i-1 (both guaranteed to exist).
         */
        t = timer_list + i;
        if (t->target <= (t-1)->target) {
            /* 't' expires earlier than (or same time as) 't-1', so we're done. */
            break;
        } else {
            /* 't' expires later than 't-1', so swap them and repeat. */
            memcpy((void *) &tmp, (void *) (t - 1), sizeof(ev_timer));
            memcpy((void *) (t - 1), (void *) t, sizeof(ev_timer));
            memcpy((void *) t, (void *) &tmp, sizeof(ev_timer));
        }
    }
}

static void expire_timers(V8Context* ctx) {
    ev_timer *t;
    int sanity = MAX_EXPIRIES;
    double now;

    /* Because a user callback can mutate the timer list (by adding or deleting
     * a timer), we expire one timer and then rescan from the end again.  There
     * is a sanity limit on how many times we do this per expiry round.
     */

    now = now_us() / 1000.0;
    while (sanity-- > 0) {
        /*
         *  Expired timer(s) still exist?
         */
        if (timer_count <= 0) {
            break;
        }
        t = timer_list + timer_count - 1;
        if (t->target > now) {
            break;
        }

        /*
         *  Move the timer to 'expiring' for the duration of the callback.
         *  Mark a one-shot timer deleted, compute a new target for an interval.
         */
        memcpy((void *) &timer_expiring, (void *) t, sizeof(ev_timer));
        memset((void *) t, 0, sizeof(ev_timer));
        timer_count--;
        t = &timer_expiring;

        if (t->oneshot) {
            t->removed = 1;
        } else {
            t->target = now + t->delay;  /* XXX: or t->target + t->delay? */
        }

        /*
         *  Call timer callback.  The callback can operate on the timer list:
         *  add new timers, remove timers.  The callback can even remove the
         *  expired timer whose callback we're calling.  However, because the
         *  timer being expired has been moved to 'timer_expiring', we don't
         *  need to worry about the timer's offset changing on the timer list.
         */
#if EVENTLOOP_DEBUG > 0
        fprintf(stderr, "> calling user callback for timer id %d\n", (int) t->id);
        fflush(stderr);
#endif
        pl_run_function(ctx, t->v8_func);
#if EVENTLOOP_DEBUG > 0
        fprintf(stderr, "> called user callback for timer id %d\n", (int) t->id);
        fflush(stderr);
#endif

        if (t->removed) {
            /* One-shot timer (always removed) or removed by user callback. */
#if EVENTLOOP_DEBUG > 0
            fprintf(stderr, "> callback deleted timer %d\n", (int) t->id);
            fflush(stderr);
#endif
        } else {
            /* Interval timer, not removed by user callback.  Queue back to
             * timer list and bubble to its final sorted position.
             */
#if EVENTLOOP_DEBUG > 0
            fprintf(stderr, "> queueing timer %d back into active list\n", (int) t->id);
            fflush(stderr);
#endif
            if (timer_count >= MAX_TIMERS) {
                // TODO error out of here
                pl_show_error(ctx, "out of timer slots, max is %ld", (long) MAX_TIMERS);
                fflush(stderr);
            }
            memcpy((void *) (timer_list + timer_count), (void *) t, sizeof(ev_timer));
            timer_count++;
            bubble_last_timer();
        }
    }

    memset((void *) &timer_expiring, 0, sizeof(ev_timer));
}

int eventloop_run(V8Context* ctx) {
    ev_timer *t;
    double now;
    double diff;
    int timeout;
    int rc;

    while (1) {
        /*
         *  Expire timers.
         */
        expire_timers(ctx);

        /*
         *  Determine poll() timeout (as close to poll() as possible as
         *  the wait is relative).
         */
        now = now_us() / 1000.0;
        t = find_nearest_timer();
        if (t) {
            diff = t->target - now;
            if (diff < MIN_WAIT) {
                diff = MIN_WAIT;
            } else if (diff > MAX_WAIT) {
                diff = MAX_WAIT;
            }
            timeout = (int) diff;  /* clamping ensures that fits */
        } else {
#if EVENTLOOP_DEBUG > 0
            fprintf(stderr, "> no timers to poll, exiting\n");
            fflush(stderr);
#endif
            break;
        }

        /*
         *  Poll for timeout.
         */
#if EVENTLOOP_DEBUG > 0
        fprintf(stderr, "> going to poll, timeout %d ms\n", timeout);
        fflush(stderr);
#endif
        rc = poll(0, 0, timeout);
#if EVENTLOOP_DEBUG > 0
        fprintf(stderr, "> poll rc: %d\n", rc);
        fflush(stderr);
#endif
        if (rc < 0) {
            /* error */
        } else if (rc == 0) {
            /* timeout */
        } else {
            /* 'rc' fds active  -- huh?*/
        }
    }

    return 0;
}

static void create_timer(const FunctionCallbackInfo<Value>& args)
{
    Local<External> v8_val = Local<External>::Cast(args.Data());
    V8Context* ctx = (V8Context*) v8_val->Value();

    if (timer_count >= MAX_TIMERS) {
        // TODO: error out of here
        pl_show_error(ctx, "Too many timers, max is %ld", (long) MAX_TIMERS);
        abort();
    }
    if (args.Length() != 3) {
        // TODO: error out of here
        pl_show_error(ctx, "create_timer() needs 3 args, got %d", args.Length());
        abort();
    }

    HandleScope handle_scope(args.GetIsolate());
    Local<Function> v8_func    = Local<Function>::Cast(args[0]);
    Local<Value>    v8_delay   = Local<Value>::Cast(args[1]);
    Local<Value>    v8_oneshot = Local<Value>::Cast(args[2]);

    double delay = v8_delay->NumberValue();
    if (delay < MIN_DELAY) {
        delay = MIN_DELAY;
    }
    bool oneshot =  v8_oneshot->BooleanValue();

    int idx = timer_count++;
    int64_t timer_id = timer_next_id++;
    ev_timer* t = timer_list + idx;

    double now = now_us() / 1000.0;
    memset((void *) t, 0, sizeof(ev_timer));
    t->id = timer_id;
    t->target = now + delay;
    t->delay = delay;
    t->oneshot = oneshot;
    t->removed = 0;
    t->v8_func.Reset(args.GetIsolate(), v8_func);

    /* Timer is now at the last position; use swaps to "bubble" it to its
     * correct sorted position.
     */
    bubble_last_timer();

    /* Return timer id. */
#if EVENTLOOP_DEBUG > 0
    fprintf(stderr, "> created timer id: %lld\n", timer_id);
    fflush(stderr);
#endif
    args.GetReturnValue().Set(Local<Object>::Cast(Number::New(args.GetIsolate(), timer_id)));
}

static void delete_timer(const FunctionCallbackInfo<Value>& args)
{
    Local<External> v8_val = Local<External>::Cast(args.Data());
    V8Context* ctx = (V8Context*) v8_val->Value();

    if (args.Length() != 1) {
        // TODO: error out of here
        pl_show_error(ctx, "delete_timer() needs 1 arg, got %d", args.Length());
        abort();
    }

    HandleScope handle_scope(args.GetIsolate());
    Local<Value>    v8_timer_id = Local<Value>::Cast(args[0]);

    int64_t  timer_id = v8_timer_id->NumberValue();

    /*
     *  Unlike insertion, deletion needs a full scan of the timer list
     *  and an expensive remove.  If no match is found, nothing is deleted.
     *  Caller gets a boolean return code indicating match.
     *
     *  When a timer is being expired and its user callback is running,
     *  the timer has been moved to 'timer_expiring' and its deletion
     *  needs special handling: just mark it to-be-deleted and let the
     *  expiry code remove it.
     */

    ev_timer* t = &timer_expiring;
    if (t->id == timer_id) {
        t->removed = 1;
#if EVENTLOOP_DEBUG > 0
        fprintf(stderr, "> deleted expiring timer id: %lld\n", timer_id);
        fflush(stderr);
#endif
        args.GetReturnValue().Set(Local<Object>::Cast(Boolean::New(args.GetIsolate(), true)));
        return;
    }

    bool found = false;
    int n = timer_count;
    for (int i = 0; i < n; i++) {
        t = timer_list + i;
        if (t->id == timer_id) {
            t->v8_func.Reset();

            /* Shift elements downwards to keep the timer list dense
             * (no need if last element).
             */

            if (i < timer_count - 1) {
                memmove((void *) t, (void *) (t + 1), (timer_count - i - 1) * sizeof(ev_timer));
            }

            /* Zero last element for clarity. */
            memset((void *) (timer_list + n - 1), 0, sizeof(ev_timer));

            /* Update timer_count. */
            timer_count--;

#if EVENTLOOP_DEBUG > 0
            fprintf(stderr, "> deleted timer id: %lld\n", timer_id);
            fflush(stderr);
#endif
            found = true;
            break;
        }
    }

#if EVENTLOOP_DEBUG > 0
    if (!found) {
        fprintf(stderr, "> trying to delete timer id %lld, but not found; ignoring\n", timer_id);
        fflush(stderr);
    }
#endif

    args.GetReturnValue().Set(Local<Object>::Cast(Boolean::New(args.GetIsolate(), found)));
}

int pl_register_eventloop_functions(V8Context* ctx)
{
    typedef void (*Handler)(const FunctionCallbackInfo<Value>& args);
    static struct Data {
        const char* name;
        Handler func;
    } data[] = {
        { "EventLoop.createTimer", create_timer },
        { "EventLoop.deleteTimer", delete_timer },
    };
    HandleScope handle_scope(ctx->isolate);
    Local<Context> context = Local<Context>::New(ctx->isolate, *ctx->persistent_context);
    Context::Scope context_scope(context);
    int n = sizeof(data) / sizeof(data[0]);
    for (int j = 0; j < n; ++j) {
        Local<Object> object;
        Local<Value> slot;
        bool found = find_parent(ctx, data[j].name, context, object, slot, true);
        if (!found) {
            pl_show_error(ctx, "could not create parent for %s", data[j].name);
            continue;
        }
        Local<Value> v8_val = External::New(ctx->isolate, ctx);
        Local<FunctionTemplate> ft = FunctionTemplate::New(ctx->isolate, data[j].func, v8_val);
        Local<Function> v8_func = ft->GetFunction();
        object->Set(slot, v8_func);
    }
    return n;
}
