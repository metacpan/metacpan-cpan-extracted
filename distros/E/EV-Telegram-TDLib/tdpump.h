#ifndef TDPUMP_H
#define TDPUMP_H

#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <stdatomic.h>
#include <time.h>
#include <errno.h>
/* _POSIX_MONOTONIC_CLOCK, tested below, arrives with this: today it is in
   scope only because perl.h is included first */
#include <unistd.h>
#include <td/telegram/td_json_client.h>

#define TD_RECEIVE_TIMEOUT 10.0

typedef struct td_msg {
    struct td_msg *next;
    char *json;
    int client_id;
} td_msg;

typedef struct {
    pthread_mutex_t lock;
    pthread_cond_t done_cond;
    clockid_t cond_clock;
    pthread_t thread;
    td_msg *head;
    td_msg *tail;
    ev_async async;
    SV *dispatch;
    int wakeup_client;
    int running;
    int reader_done;
    _Atomic int closing;
    _Atomic int stop;
    _Atomic int poisoned;
    _Atomic int ever_client;
    int refcnt;
} td_pump;

static td_pump PUMP;

#define TD_CHECK_FORK() \
    if (atomic_load(&PUMP.poisoned)) \
        croak("EV::Telegram::TDLib: cannot be used after fork; " \
              "TDLib is not fork-safe")

/* Runs in the forked child with only the calling thread left: the queue
   mutex may be held by the dead reader, so no lock and no free; the
   leaked nodes are the price of staying async-signal-safe. */
static void td_atfork_child(void) {
    /* a child forked before this process ever made a client inherits a pump
       that was never used: no reader, no held mutex, no loop refs, and TDLib
       itself has spawned nothing, since td_create_client_id is what starts
       it. Such a child is as clean as a fresh process, so let it work --
       this is what makes fork-then-create-per-worker viable. The flag must
       be "ever", not "running", or a fork after shutdown would slip past.
       "TDLib spawns nothing before the first client" was measured on 1.8.66
       (thread and fd counts unchanged across load and td_execute); recheck
       it when the pinned TDLib moves. */
    if (!atomic_load(&PUMP.ever_client))
        return;
    atomic_store(&PUMP.poisoned, 1);
    PUMP.running = 0;
    PUMP.head = PUMP.tail = NULL;
    /* the child can never receive and _pump_unref croaks on poison, so
       the inherited loop refs are dropped here or EV::run blocks on a
       phantom count; plain counter ops, safe in the single-threaded child */
    /* one ev_ref is outstanding however high refcnt is: _pump_ref takes it
       on the 0->1 transition only. Giving back one per client left the
       child's loop short, and a child with two clients saw EV::run return
       at once without running anything of its own. */
    if (PUMP.refcnt > 0) {
        ev_unref(EV_DEFAULT_UC);
        PUMP.refcnt = 0;
    }
}

/* "@client_id" is appended at the end of the object, so the last match is
   the real one; a payload may contain the same text earlier. */
static int td_scan_client_id(const char *s, size_t len) {
    static const char key[] = "\"@client_id\":";
    const size_t klen = sizeof(key) - 1;
    size_t i;
    if (len < klen + 2) return 0;
    for (i = len - klen; ; i--) {
        if (memcmp(s + i, key, klen) == 0)
            return (int) strtol(s + i + klen, NULL, 10);
        if (i == 0) break;
    }
    return 0;
}

/* Never touches the interpreter. The td_receive pointer is deallocated by
   the next td_receive/td_execute, so it is copied before anything else. */
static void *td_reader(void *arg) {
    (void) arg;
    for (;;) {
        const char *r = td_receive(TD_RECEIVE_TIMEOUT);
        if (atomic_load(&PUMP.stop)) break;
        if (!r) continue;
        {
            size_t len = strlen(r);
            td_msg *m = (td_msg *) malloc(sizeof(td_msg));
            if (!m) continue;
            m->json = (char *) malloc(len + 1);
            if (!m->json) { free(m); continue; }
            memcpy(m->json, r, len + 1);
            m->client_id = td_scan_client_id(m->json, len);
            m->next = NULL;
            if (atomic_load(&PUMP.closing)
                && m->client_id == PUMP.wakeup_client
                && strstr(m->json, "\"@type\":\"updateAuthorizationState\"")
                && strstr(m->json, "authorizationStateClosed")) {
                free(m->json);
                free(m);
                break;
            }
            pthread_mutex_lock(&PUMP.lock);
            if (PUMP.tail) PUMP.tail->next = m; else PUMP.head = m;
            PUMP.tail = m;
            pthread_mutex_unlock(&PUMP.lock);
            ev_async_send(EV_DEFAULT_UC, &PUMP.async);
        }
    }
    pthread_mutex_lock(&PUMP.lock);
    PUMP.reader_done = 1;
    pthread_cond_signal(&PUMP.done_cond);
    pthread_mutex_unlock(&PUMP.lock);
    return NULL;
}

/* The list is detached under the lock and the lock released before Perl
   runs: a callback that sends a request deadlocks on a held lock. */
static void td_drain(EV_P_ ev_async *w, int revents) {
    dTHX;
    td_msg *list;
    PERL_UNUSED_VAR(w); PERL_UNUSED_VAR(revents);

    /* forked child: the reader that owned this mutex is dead and may have
       held it at fork time; EV keeps the loop alive there, so bail out */
    if (atomic_load(&PUMP.poisoned))
        return;

    pthread_mutex_lock(&PUMP.lock);
    list = PUMP.head;
    PUMP.head = PUMP.tail = NULL;
    pthread_mutex_unlock(&PUMP.lock);

    while (list) {
        td_msg *m = list;
        list = list->next;
        if (m->client_id != PUMP.wakeup_client && PUMP.dispatch) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(m->client_id)));
            PUSHs(sv_2mortal(newSVpv(m->json, 0)));
            PUTBACK;
            call_sv(PUMP.dispatch, G_DISCARD | G_EVAL);
            SPAGAIN;
            /* SvROK first: a blessed exception object may overload bool, and
               testing truth would run that overload here, outside any eval */
            if (SvROK(ERRSV) || SvTRUE(ERRSV)) {
                /* routed to the client's on_error (warn as fallback) by
                   drain_error, which is written to never die: a dying
                   handler or __WARN__ hook must not unwind the drain and
                   leak the rest of the detached list.
                   The error is passed unstringified for the same reason --
                   an overloaded "" that dies would escape from here, where
                   nothing catches it, rather than from inside drain_error */
                PUSHMARK(SP);
                EXTEND(SP, 2);
                PUSHs(sv_2mortal(newSViv(m->client_id)));
                PUSHs(sv_2mortal(newSVsv(ERRSV)));
                PUTBACK;
                call_pv("EV::Telegram::TDLib::drain_error",
                        G_DISCARD | G_EVAL);
                SPAGAIN;
            }
            FREETMPS; LEAVE;
        }
        free(m->json);
        free(m);
    }
}

static void td_pump_boot(pTHX) {
    /* PUMP is process-global but BOOT runs per interpreter; a second
       interpreter would memset a live pump and share TDLib's single
       reader queue, so refuse instead of re-initialising */
    static _Atomic int booted = 0;
    if (atomic_fetch_or(&booted, 1))
        croak("EV::Telegram::TDLib: already initialised; "
              "the pump cannot serve a second interpreter");

    memset(&PUMP, 0, sizeof PUMP);
    pthread_mutex_init(&PUMP.lock, NULL);
    PUMP.cond_clock = CLOCK_REALTIME;
/* 0 means "check at runtime" (glibc), so the setclock return decides;
   Apple lacks pthread_condattr_setclock outright */
#if defined(_POSIX_MONOTONIC_CLOCK) && _POSIX_MONOTONIC_CLOCK >= 0 \
    && !defined(__APPLE__)
    {
        /* a wall-clock step must not stretch the shutdown deadline;
           degrade to the realtime condvar where this is unavailable */
        pthread_condattr_t cattr;
        if (pthread_condattr_init(&cattr) == 0) {
            if (pthread_condattr_setclock(&cattr, CLOCK_MONOTONIC) == 0)
                PUMP.cond_clock = CLOCK_MONOTONIC;
            pthread_cond_init(&PUMP.done_cond, &cattr);
            pthread_condattr_destroy(&cattr);
        }
        else
            pthread_cond_init(&PUMP.done_cond, NULL);
    }
#else
    pthread_cond_init(&PUMP.done_cond, NULL);
#endif
    ev_async_init(&PUMP.async, td_drain);
    ev_async_start(EV_DEFAULT_UC, &PUMP.async);
    ev_unref(EV_DEFAULT_UC);
    pthread_atfork(NULL, NULL, td_atfork_child);
}

static void td_pump_start(pTHX) {
    sigset_t all, prev;
    int rc;
    if (PUMP.running) return;
    atomic_store(&PUMP.ever_client, 1);
    PUMP.wakeup_client = td_create_client_id();
    PUMP.reader_done = 0;
    atomic_store(&PUMP.closing, 0);
    atomic_store(&PUMP.stop, 0);
    /* the reader has no perl context: block all signals across the create so
       it inherits a FULL mask and delivery stays on the main thread */
    sigfillset(&all);
    pthread_sigmask(SIG_SETMASK, &all, &prev);
    rc = pthread_create(&PUMP.thread, NULL, td_reader, NULL);
    pthread_sigmask(SIG_SETMASK, &prev, NULL);
    if (rc != 0)
        croak("EV::Telegram::TDLib: cannot start the reader thread");
    PUMP.running = 1;
}

/* Close the wakeup client and wait (bounded) for its Closed, so TDLib has
   no open clients when its statics tear down at process exit; td_receive
   cannot be interrupted, so if the deadline passes the stop flag plus a
   throwaway request forces the reader out. */
static void td_pump_stop(pTHX) {
    struct timespec deadline;
    int forced = 0;
    if (!PUMP.running) return;

    atomic_store(&PUMP.closing, 1);
    td_send(PUMP.wakeup_client, "{\"@type\":\"close\"}");

    clock_gettime(PUMP.cond_clock, &deadline);
    deadline.tv_sec += 2;

    pthread_mutex_lock(&PUMP.lock);
    while (!PUMP.reader_done) {
        int rc = forced
            ? pthread_cond_wait(&PUMP.done_cond, &PUMP.lock)
            : pthread_cond_timedwait(&PUMP.done_cond, &PUMP.lock, &deadline);
        if (!forced && rc == ETIMEDOUT) {
            forced = 1;
            atomic_store(&PUMP.stop, 1);
            td_send(PUMP.wakeup_client,
                    "{\"@type\":\"getOption\",\"name\":\"version\"}");
        }
    }
    pthread_mutex_unlock(&PUMP.lock);

    pthread_join(PUMP.thread, NULL);
    PUMP.running = 0;
    while (PUMP.head) {
        td_msg *m = PUMP.head;
        PUMP.head = m->next;
        free(m->json);
        free(m);
    }
    PUMP.tail = NULL;
}

#endif
