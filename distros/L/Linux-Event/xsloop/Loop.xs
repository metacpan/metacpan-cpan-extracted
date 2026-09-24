/*
 * Linux::Event XS reactor core
 * ============================
 *
 * This file contains the native implementation behind Linux::Event::Loop and
 * its opaque registration handles.  The design goal is a short readiness path:
 *
 *     epoll_wait()
 *       -> epoll_event.data.ptr
 *       -> le_watcher_t *
 *       -> native dispatch
 *       -> one Perl callback
 *
 * The fd-indexed registry is intentionally not used for hot-path lookup after
 * epoll_wait(); it exists for registration, replacement, cancellation and
 * lifecycle operations.  epoll_event.data.ptr points directly at the watcher.
 *
 * The core is a reactor, not a stream implementation.  It reports descriptor
 * readiness and deliberately leaves sysread/syswrite/buffering policy to the
 * caller. Native buffering, write queues, and framing live in the higher-level
 * Linux::Event::Stream layer so the raw watcher API remains general.
 *
 * Lifetime invariant
 * ------------------
 * le_loop_t owns all native le_watcher_t records.  Opaque Perl registration
 * handles refer to loop-owned state.  Returned epoll batches may still contain
 * a watcher pointer after EPOLL_CTL_DEL, so any optional reuse/reclaim path
 * must not recycle a watcher until the current dispatch batch is finished.
 *
 * Callback invariant
 * ------------------
 * For one epoll event terminal/error readiness is handled before read and
 * write readiness.  The watcher is re-checked after callbacks so a callback
 * may cancel itself safely.  Plain coderefs are stored as direct CVs to avoid
 * an extra RV layer on the hot call path.
 *
 * Profiling
 * ---------
 * Cheap counters are always available.  Nanosecond timing is opt-in because
 * measuring each hot operation changes the workload.  Benchmark-only native
 * echo code remains private and is explicitly marked below.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/epoll.h>
#include <sys/timerfd.h>
#include <unistd.h>
#include <errno.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <limits.h>
#include <sys/types.h>
#include <pthread.h>

#ifndef EPOLLRDHUP
#define EPOLLRDHUP 0x2000
#endif

#define LE_INITIAL_EVENTS 8192
#define LE_INITIAL_REGISTRY 1024
#define LE_CALLBACK_SCOPE_DEFAULT 128
#define LE_INITIAL_TIMER_HEAP 64
#define LE_TIMER_CALLBACK_BATCH 1024
#define LE_HEAP_NONE ((size_t)-1)
#define LE_WATCHER_USER 0
#define LE_WATCHER_TIMER 1

#define LE_TIMER_UNATTACHED 0
#define LE_TIMER_ACTIVE 1
#define LE_TIMER_FIRING 2
#define LE_TIMER_EXPIRED 3
#define LE_TIMER_CANCELLED 4

typedef struct le_loop_s le_loop_t;
typedef struct le_watcher_s le_watcher_t;
typedef struct le_registration_s le_registration_t;
typedef struct le_timer_s le_timer_t;
typedef struct le_timer_descriptor_s le_timer_descriptor_t;

static pid_t le_process_pid;
static int le_atfork_registered;

static void le_process_after_fork_child(void) {
    le_process_pid = getpid();
}

struct le_timer_descriptor_s {
    SV *callback_cv;
    int callback_direct_cv;
};

/*
 * One public Timer object owns one native record. Active records are retained
 * by self_sv while the Loop's indexed heap stores their native pointers.
 * Callback behavior is shared through one immutable descriptor per subclass.
 */
struct le_timer_s {
    le_loop_t *loop;
    le_timer_descriptor_t *descriptor;
    SV *descriptor_sv;
    SV *self_sv;
    SV *loop_sv;
    SV *data_sv;
    unsigned long long deadline_ns;
    unsigned long long interval_ns;
    unsigned long long initial_ns;
    unsigned long long sequence;
    unsigned long long expirations;
    size_t heap_index;
    int initial_absolute;
    int state;
    int in_callback;
    int cleanup_pending;
};

/*
 * Stable indirection for a public registration handle. epoll continues to
 * point directly at the watcher; only handle method calls cross this boundary.
 * The watcher and Perl handle each own one reference.
 */
struct le_registration_s {
    le_watcher_t *watcher;
    unsigned int refs;
};

/*
 * Native watcher record.
 *
 * Callback SVs live here so readiness dispatch does not need a Perl hash or
 * method lookup. Accessor references are optional: lean no-argument watchers
 * can omit them when user code captures its state in the callback closure.
 */
struct le_watcher_s {
    le_watcher_t *next_free;
    le_watcher_t *next_retired;
    int fd;
    uint32_t mask;
    uint32_t flags;
    int active;
    le_loop_t *loop;
    SV *self_sv;
    SV *loop_sv;
    SV *fh_sv;
    SV *data_sv;
    SV *read_cb;
    SV *write_cb;
    SV *error_cb;
    int read_cb_direct_cv;
    int write_cb_direct_cv;
    int error_cb_direct_cv;
    int callback_args;
    int callback_arg_data;
    int lean;
    int bench_native_echo;
    int kind;
    int internal;
    int recycle_after_dispatch;
    le_registration_t *registration;
};

/*
 * Native loop state.
 *
 * The reusable epoll event array and fd registry are allocated once and kept
 * with the loop. Counters are colocated here so instrumentation does not need
 * Perl-side bookkeeping.
 */
struct le_loop_s {
    int epoll_fd;
    pid_t owner_pid;
    int stop_flag;
    size_t event_cap;
    struct epoll_event *events;
    size_t reg_cap;
    le_watcher_t **registry;
    unsigned long long epoll_wait_calls;
    unsigned long long epoll_wait_empty_calls;
    unsigned long long epoll_wait_full_batches;
    unsigned long long epoll_wait_max_batch;
    unsigned long long ready_events_returned;
    unsigned long long ready_read_events;
    unsigned long long ready_write_events;
    unsigned long long ready_error_events;
    unsigned long long ready_epollerr_events;
    unsigned long long ready_hup_events;
    unsigned long long ready_rdhup_events;
    unsigned long long ready_in_hup_events;
    unsigned long long ready_in_rdhup_events;
    unsigned long long ready_multi_events;
    unsigned long long callback_calls;
    unsigned long long read_callback_calls;
    unsigned long long write_callback_calls;
    unsigned long long error_callback_calls;
    unsigned long long epoll_ctl_add_calls;
    unsigned long long epoll_ctl_mod_calls;
    unsigned long long epoll_ctl_del_calls;
    unsigned long long watcher_lookup_calls;
    unsigned long long direct_watcher_events;
    unsigned long long dispatch_events;
    unsigned long long callback_noarg_calls;
    unsigned long long callback_onearg_calls;
    unsigned long long callback_direct_cv_calls;
    unsigned long long callback_sv_calls;
    unsigned long long callback_batch_scope_enters;
    unsigned long long callback_scope_rotations;
    unsigned long long callback_scope_max_callbacks;
    unsigned int callback_scope_limit;
    unsigned long long poll_calls;
    unsigned long long run_once_calls;
    unsigned long long run_calls;
    unsigned long long run_for_calls;
    unsigned long long bench_native_echo_read_events;
    unsigned long long bench_native_echo_perl_read_callbacks;
    unsigned long long bench_native_echo_sysread_calls;
    unsigned long long bench_native_echo_syswrite_calls;
    unsigned long long bench_native_echo_bytes_read;
    unsigned long long bench_native_echo_bytes_written;
    unsigned long long bench_native_echo_read_eagain;
    unsigned long long bench_native_echo_write_eagain;
    unsigned long long bench_native_echo_partial_writes;
    unsigned long long bench_native_echo_read_zero;
    unsigned long long bench_native_echo_errors;
    unsigned long long lean_watchers;
    unsigned long long watcher_alloc_calls;
    unsigned long long watcher_reuse_calls;
    unsigned long long watcher_recycle_calls;
    unsigned long long watcher_destroy_calls;
    unsigned long long watcher_freelist_depth;
    unsigned long long watcher_freelist_max_depth;
    int watcher_reclaim_enabled;
    int in_dispatch_batch;
    int driver_depth;
    le_watcher_t *watcher_freelist;
    le_watcher_t *watcher_pending;
    le_watcher_t *watcher_retired;
    int timer_fd;
    le_watcher_t *timer_source;
    le_timer_t **timer_heap;
    size_t timer_heap_size;
    size_t timer_heap_cap;
    unsigned long long timer_sequence;
    unsigned long long timerfd_create_calls;
    unsigned long long timerfd_settime_calls;
    unsigned long long timer_schedule_calls;
    unsigned long long timer_reschedule_calls;
    unsigned long long timer_cancel_calls;
    unsigned long long timer_callback_calls;
    unsigned long long timer_expired_calls;
    unsigned long long timer_coalesced_expirations;
    unsigned long long timer_heap_max_size;
    int in_timer_dispatch;
    le_timer_t *current_timer;
    int profile_enabled;
    unsigned long long epoll_wait_ns;
    unsigned long long epoll_ctl_add_ns;
    unsigned long long epoll_ctl_mod_ns;
    unsigned long long epoll_ctl_del_ns;
    unsigned long long watcher_lookup_ns;
    unsigned long long dispatch_ns;
};

/* ---- Cheap readiness and epoll instrumentation ----------------------- */

static void le_note_epoll_batch(le_loop_t *loop, int n) {
    loop->epoll_wait_calls++;
    if (n == 0) loop->epoll_wait_empty_calls++;
    if (n == (int)loop->event_cap) loop->epoll_wait_full_batches++;
    if ((unsigned long long)n > loop->epoll_wait_max_batch) loop->epoll_wait_max_batch = (unsigned long long)n;
    loop->ready_events_returned += (unsigned long long)n;
}

static void le_note_ready_flags(le_loop_t *loop, uint32_t events) {
    int buckets = 0;
    if (events & EPOLLERR) loop->ready_epollerr_events++;
    if (events & EPOLLHUP) loop->ready_hup_events++;
    if (events & EPOLLRDHUP) loop->ready_rdhup_events++;
    if ((events & EPOLLIN) && (events & EPOLLHUP)) loop->ready_in_hup_events++;
    if ((events & EPOLLIN) && (events & EPOLLRDHUP)) loop->ready_in_rdhup_events++;
    if (events & (EPOLLERR | EPOLLHUP | EPOLLRDHUP)) { loop->ready_error_events++; buckets++; }
    if (events & EPOLLIN)  { loop->ready_read_events++;  buckets++; }
    if (events & EPOLLOUT) { loop->ready_write_events++; buckets++; }
    if (buckets > 1) loop->ready_multi_events++;
}

static unsigned long long le_now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ((unsigned long long)ts.tv_sec * 1000000000ULL) + (unsigned long long)ts.tv_nsec;
}

static int le_epoll_ctl_timed(le_loop_t *loop, int op, int fd, struct epoll_event *ev) {
    unsigned long long t0 = 0;
    if (loop && loop->profile_enabled) t0 = le_now_ns();
    int rc = epoll_ctl(loop->epoll_fd, op, fd, ev);
    if (loop) {
        unsigned long long *calls = NULL;
        unsigned long long *ns = NULL;
        if (op == EPOLL_CTL_ADD) { calls = &loop->epoll_ctl_add_calls; ns = &loop->epoll_ctl_add_ns; }
        else if (op == EPOLL_CTL_MOD) { calls = &loop->epoll_ctl_mod_calls; ns = &loop->epoll_ctl_mod_ns; }
        else if (op == EPOLL_CTL_DEL) { calls = &loop->epoll_ctl_del_calls; ns = &loop->epoll_ctl_del_ns; }
        if (calls) (*calls)++;
        if (ns && loop->profile_enabled) (*ns) += le_now_ns() - t0;
    }
    return rc;
}

/* ---- Perl object <-> native pointer conversion ---------------------- */

static le_loop_t *le_loop_from_sv(SV *sv) {
    if (!sv_isobject(sv) || !SvROK(sv)) croak("not a loop object");
    return INT2PTR(le_loop_t *, SvIV((SV*)SvRV(sv)));
}

static void le_loop_assert_owner(le_loop_t *loop, const char *operation) {
    pid_t current = le_process_pid;
    if (!loop) croak("%s(): Loop is closed", operation);
    if (loop->owner_pid != current)
        croak("%s(): Loop belongs to PID %ld and cannot be used in PID %ld after fork",
            operation, (long)loop->owner_pid, (long)current);
}

static le_registration_t *le_registration_from_sv(SV *sv) {
    if (!sv_isobject(sv) || !SvROK(sv)) croak("not a watcher object");
    return INT2PTR(le_registration_t *, SvIV((SV*)SvRV(sv)));
}

static le_watcher_t *le_watcher_from_sv(SV *sv) {
    le_registration_t *registration = le_registration_from_sv(sv);
    return registration ? registration->watcher : NULL;
}

static le_timer_t *le_timer_from_sv(SV *sv) {
    if (!sv_isobject(sv) || !SvROK(sv)) croak("not a Timer object");
    return INT2PTR(le_timer_t *, SvIV((SV*)SvRV(sv)));
}

static le_timer_descriptor_t *le_timer_descriptor_from_sv(SV *sv) {
    if (!sv_isobject(sv) || !SvROK(sv))
        croak("not a Timer descriptor object");
    return INT2PTR(le_timer_descriptor_t *, SvIV((SV*)SvRV(sv)));
}

/* ---- Native fd registry --------------------------------------------- */

static void le_registry_grow(le_loop_t *loop, int fd) {
    if (fd < 0) croak("negative fd");
    if ((size_t)fd < loop->reg_cap) return;
    size_t new_cap = loop->reg_cap ? loop->reg_cap : LE_INITIAL_REGISTRY;
    while ((size_t)fd >= new_cap) new_cap *= 2;
    le_watcher_t **new_reg = (le_watcher_t **)calloc(new_cap, sizeof(le_watcher_t *));
    if (!new_reg) croak("calloc registry failed");
    if (loop->registry) {
        memcpy(new_reg, loop->registry, loop->reg_cap * sizeof(le_watcher_t *));
        free(loop->registry);
    }
    loop->registry = new_reg;
    loop->reg_cap = new_cap;
}

static uint32_t le_mask_from_callbacks(SV *read_cb, SV *write_cb) {
    uint32_t mask = EPOLLERR | EPOLLHUP | EPOLLRDHUP;
    if (read_cb && SvOK(read_cb))  mask |= EPOLLIN;
    if (write_cb && SvOK(write_cb)) mask |= EPOLLOUT;
    return mask;
}

static uint32_t le_epoll_events(le_watcher_t *w) {
    return w->mask | w->flags;
}

static SV *le_stored_callback_from_sv(SV *cb, int *direct_cv) {
    if (direct_cv) *direct_cv = 0;
    if (!cb || !SvOK(cb)) return NULL;
    if (SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV) {
        if (direct_cv) *direct_cv = 1;
        return SvREFCNT_inc_NN(SvRV(cb));
    }
    return newSVsv(cb);
}

/* ---- Watcher allocation, ownership and safe deferred reuse ---------- */

static void le_registration_release(le_registration_t *registration) {
    if (!registration) return;
    if (--registration->refs == 0) free(registration);
}

static void le_watcher_invalidate_registration(le_watcher_t *w) {
    le_registration_t *registration;
    if (!w || !w->registration) return;
    registration = w->registration;
    w->registration = NULL;
    if (registration->watcher == w) registration->watcher = NULL;
    le_registration_release(registration);
}

static void le_watcher_clear_refs(le_watcher_t *w) {
    if (!w) return;
    le_watcher_invalidate_registration(w);
    if (w->read_cb)  { SvREFCNT_dec(w->read_cb);  w->read_cb = NULL; }
    if (w->write_cb) { SvREFCNT_dec(w->write_cb); w->write_cb = NULL; }
    if (w->error_cb) { SvREFCNT_dec(w->error_cb); w->error_cb = NULL; }
    if (w->data_sv)  { SvREFCNT_dec(w->data_sv);  w->data_sv = NULL; }
    if (w->fh_sv)    { SvREFCNT_dec(w->fh_sv);    w->fh_sv = NULL; }
    if (w->loop_sv)  { SvREFCNT_dec(w->loop_sv);  w->loop_sv = NULL; }
    if (w->self_sv)  { SvREFCNT_dec(w->self_sv);  w->self_sv = NULL; }
}

static void le_watcher_destroy(le_watcher_t *w) {
    if (!w) return;
    le_loop_t *loop = w->loop;
    le_watcher_clear_refs(w);
    if (loop) loop->watcher_destroy_calls++;
    free(w);
}

static le_watcher_t *le_watcher_alloc(le_loop_t *loop) {
    le_watcher_t *w = NULL;
    if (loop && loop->watcher_freelist) {
        w = loop->watcher_freelist;
        loop->watcher_freelist = w->next_free;
        if (loop->watcher_freelist_depth) loop->watcher_freelist_depth--;
        loop->watcher_reuse_calls++;
        memset(w, 0, sizeof(*w));
        return w;
    }
    w = (le_watcher_t *)calloc(1, sizeof(le_watcher_t));
    if (!w) croak("calloc watcher failed");
    if (loop) loop->watcher_alloc_calls++;
    return w;
}

static void le_watcher_push_list(le_watcher_t **list, le_watcher_t *w) {
    w->next_free = *list;
    *list = w;
}

static void le_watcher_recycle_or_destroy(le_watcher_t *w) {
    if (!w) return;
    le_loop_t *loop = w->loop;
    if (!loop) {
        le_watcher_destroy(w);
        return;
    }
    w->active = 0;
    w->recycle_after_dispatch = loop->watcher_reclaim_enabled ? 1 : 0;
    if (loop->in_dispatch_batch) {
        le_watcher_push_list(&loop->watcher_pending, w);
        return;
    }
    le_watcher_clear_refs(w);
    if (!w->recycle_after_dispatch) {
        /*
         * Retain native storage in compatibility mode, but release every Perl
         * reference and detach the stable public handle immediately.
         */
        w->next_retired = loop->watcher_retired;
        loop->watcher_retired = w;
        return;
    }
    w->fd = -1;
    loop->watcher_recycle_calls++;
    le_watcher_push_list(&loop->watcher_freelist, w);
    loop->watcher_freelist_depth++;
    if (loop->watcher_freelist_depth > loop->watcher_freelist_max_depth) loop->watcher_freelist_max_depth = loop->watcher_freelist_depth;
}

static void le_watcher_promote_pending(le_loop_t *loop) {
    le_watcher_t *w;
    if (!loop) return;
    while ((w = loop->watcher_pending) != NULL) {
        loop->watcher_pending = w->next_free;
        le_watcher_clear_refs(w);
        if (w->recycle_after_dispatch) {
            w->fd = -1;
            loop->watcher_recycle_calls++;
            le_watcher_push_list(&loop->watcher_freelist, w);
            loop->watcher_freelist_depth++;
            if (loop->watcher_freelist_depth > loop->watcher_freelist_max_depth) loop->watcher_freelist_max_depth = loop->watcher_freelist_depth;
        }
        else {
            w->next_retired = loop->watcher_retired;
            loop->watcher_retired = w;
        }
    }
}

/* ---- Shared native Timer scheduler ---------------------------------- */

static int le_timer_less(const le_timer_t *a, const le_timer_t *b) {
    if (a->deadline_ns != b->deadline_ns)
        return a->deadline_ns < b->deadline_ns;
    return a->sequence < b->sequence;
}

static void le_timer_heap_swap(le_loop_t *loop, size_t a, size_t b) {
    le_timer_t *temporary = loop->timer_heap[a];
    loop->timer_heap[a] = loop->timer_heap[b];
    loop->timer_heap[b] = temporary;
    loop->timer_heap[a]->heap_index = a;
    loop->timer_heap[b]->heap_index = b;
}

static void le_timer_heap_reserve(le_loop_t *loop) {
    size_t capacity;
    le_timer_t **heap;
    if (loop->timer_heap_size < loop->timer_heap_cap) return;
    capacity = loop->timer_heap_cap
        ? loop->timer_heap_cap * 2 : LE_INITIAL_TIMER_HEAP;
    if (capacity < loop->timer_heap_cap)
        croak("Timer heap capacity overflow");
    heap = (le_timer_t **)realloc(
        loop->timer_heap, capacity * sizeof(le_timer_t *));
    if (!heap) croak("realloc Timer heap failed");
    loop->timer_heap = heap;
    loop->timer_heap_cap = capacity;
}

static void le_timer_heap_up(le_loop_t *loop, size_t at) {
    while (at > 0) {
        size_t parent = (at - 1) / 2;
        if (!le_timer_less(loop->timer_heap[at], loop->timer_heap[parent]))
            break;
        le_timer_heap_swap(loop, at, parent);
        at = parent;
    }
}

static void le_timer_heap_down(le_loop_t *loop, size_t at) {
    while (1) {
        size_t left = at * 2 + 1;
        size_t right = left + 1;
        size_t smallest = at;
        if (left < loop->timer_heap_size
            && le_timer_less(loop->timer_heap[left],
                loop->timer_heap[smallest]))
            smallest = left;
        if (right < loop->timer_heap_size
            && le_timer_less(loop->timer_heap[right],
                loop->timer_heap[smallest]))
            smallest = right;
        if (smallest == at) break;
        le_timer_heap_swap(loop, at, smallest);
        at = smallest;
    }
}

static void le_timer_heap_insert(le_loop_t *loop, le_timer_t *timer) {
    size_t at;
    le_timer_heap_reserve(loop);
    at = loop->timer_heap_size++;
    loop->timer_heap[at] = timer;
    timer->heap_index = at;
    le_timer_heap_up(loop, at);
    if ((unsigned long long)loop->timer_heap_size
        > loop->timer_heap_max_size)
        loop->timer_heap_max_size
            = (unsigned long long)loop->timer_heap_size;
}

static void le_timer_heap_remove(le_loop_t *loop, le_timer_t *timer) {
    size_t at;
    size_t last;
    if (!loop || !timer || timer->heap_index == LE_HEAP_NONE) return;
    at = timer->heap_index;
    if (at >= loop->timer_heap_size || loop->timer_heap[at] != timer)
        croak("Timer heap index corrupted");
    last = --loop->timer_heap_size;
    timer->heap_index = LE_HEAP_NONE;
    if (at == last) return;
    loop->timer_heap[at] = loop->timer_heap[last];
    loop->timer_heap[at]->heap_index = at;
    if (at > 0 && le_timer_less(loop->timer_heap[at],
        loop->timer_heap[(at - 1) / 2]))
        le_timer_heap_up(loop, at);
    else
        le_timer_heap_down(loop, at);
}

static unsigned long long le_seconds_to_ns(double seconds,
    int allow_zero, const char *name) {
    double maximum = (double)ULLONG_MAX / 1000000000.0;
    unsigned long long nanoseconds;
    if (!isfinite(seconds) || seconds < 0.0
        || (!allow_zero && seconds == 0.0))
        croak("%s must be a %sfinite number of seconds", name,
            allow_zero ? "non-negative " : "positive ");
    if (seconds >= maximum) croak("%s is too large", name);
    nanoseconds = (unsigned long long)(seconds * 1000000000.0);
    if (!allow_zero && nanoseconds == 0)
        croak("%s is below the one-nanosecond scheduler resolution", name);
    return nanoseconds;
}

static void le_timer_rearm(le_loop_t *loop) {
    struct itimerspec specification;
    unsigned long long deadline;
    if (!loop || loop->timer_fd < 0) return;
    memset(&specification, 0, sizeof(specification));
    if (loop->timer_heap_size) {
        deadline = loop->timer_heap[0]->deadline_ns;
        if (deadline == 0) deadline = 1;
        specification.it_value.tv_sec = (time_t)(deadline / 1000000000ULL);
        specification.it_value.tv_nsec = (long)(deadline % 1000000000ULL);
    }
    loop->timerfd_settime_calls++;
    if (timerfd_settime(loop->timer_fd, TFD_TIMER_ABSTIME,
        &specification, NULL) != 0)
        croak("timerfd_settime failed: %s", strerror(errno));
}

static void le_timer_maybe_rearm(le_loop_t *loop,
    unsigned long long old_first) {
    unsigned long long next_first = loop->timer_heap_size
        ? loop->timer_heap[0]->deadline_ns : 0;
    if (!loop->in_timer_dispatch && old_first != next_first)
        le_timer_rearm(loop);
}

static void le_timer_source_ensure(le_loop_t *loop) {
    le_watcher_t *source;
    le_watcher_t *old;
    struct epoll_event event;
    int operation;
    int fd;
    if (loop->timer_fd >= 0) return;
    fd = timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK | TFD_CLOEXEC);
    if (fd < 0) croak("timerfd_create failed: %s", strerror(errno));
    loop->timerfd_create_calls++;
    le_registry_grow(loop, fd);
    old = loop->registry[fd];
    source = le_watcher_alloc(loop);
    source->fd = fd;
    source->loop = loop;
    source->active = 1;
    source->mask = EPOLLIN | EPOLLERR | EPOLLHUP;
    source->kind = LE_WATCHER_TIMER;
    source->internal = 1;
    memset(&event, 0, sizeof(event));
    event.events = source->mask;
    event.data.ptr = (void *)source;
    operation = old ? EPOLL_CTL_MOD : EPOLL_CTL_ADD;
    if (le_epoll_ctl_timed(loop, operation, fd, &event) < 0
        && !(old && errno == ENOENT
            && le_epoll_ctl_timed(loop, EPOLL_CTL_ADD, fd, &event) == 0)) {
        int error = errno;
        source->loop = NULL;
        le_watcher_destroy(source);
        close(fd);
        croak("epoll_ctl Timer fd failed: %s", strerror(error));
    }
    if (old) {
        old->active = 0;
        le_watcher_recycle_or_destroy(old);
    }
    loop->registry[fd] = source;
    loop->timer_fd = fd;
    loop->timer_source = source;
}

static void le_timer_release_refs(le_timer_t *timer) {
    SV *descriptor_sv;
    SV *data_sv;
    SV *loop_sv;
    SV *self_sv;
    if (!timer) return;
    descriptor_sv = timer->descriptor_sv;
    data_sv = timer->data_sv;
    loop_sv = timer->loop_sv;
    self_sv = timer->self_sv;
    timer->descriptor = NULL;
    timer->descriptor_sv = NULL;
    timer->data_sv = NULL;
    timer->loop_sv = NULL;
    timer->self_sv = NULL;
    timer->loop = NULL;
    timer->cleanup_pending = 0;
    if (descriptor_sv) SvREFCNT_dec(descriptor_sv);
    if (data_sv) SvREFCNT_dec(data_sv);
    if (loop_sv) SvREFCNT_dec(loop_sv);
    /* This may destroy the Timer and free its native record. */
    if (self_sv) SvREFCNT_dec(self_sv);
}

static void le_timer_finish_terminal(le_timer_t *timer) {
    if (!timer) return;
    if (timer->in_callback) {
        timer->cleanup_pending = 1;
        return;
    }
    le_timer_release_refs(timer);
}

static void le_timer_cancel_native(le_timer_t *timer) {
    le_loop_t *loop;
    unsigned long long old_first = 0;
    if (!timer || timer->state == LE_TIMER_CANCELLED
        || timer->state == LE_TIMER_EXPIRED)
        return;
    loop = timer->loop;
    if (loop && loop->timer_heap_size)
        old_first = loop->timer_heap[0]->deadline_ns;
    if (loop && timer->heap_index != LE_HEAP_NONE)
        le_timer_heap_remove(loop, timer);
    timer->state = LE_TIMER_CANCELLED;
    if (loop) {
        loop->timer_cancel_calls++;
        le_timer_maybe_rearm(loop, old_first);
    }
    le_timer_finish_terminal(timer);
}

static void le_timer_activate(SV *timer_obj, le_timer_t *timer,
    SV *loop_obj, le_loop_t *loop) {
    unsigned long long now;
    unsigned long long deadline;
    unsigned long long old_first;
    if (timer->state != LE_TIMER_UNATTACHED || timer->loop)
        croak("add(): Timer is not unattached");
    le_timer_source_ensure(loop);
    now = le_now_ns();
    if (timer->initial_absolute) {
        deadline = timer->initial_ns;
    }
    else {
        if (timer->initial_ns > ULLONG_MAX - now)
            croak("Timer deadline overflow");
        deadline = now + timer->initial_ns;
    }
    old_first = loop->timer_heap_size
        ? loop->timer_heap[0]->deadline_ns : 0;
    timer->loop = loop;
    timer->loop_sv = newSVsv(loop_obj);
    if (SvROK(timer->loop_sv)) sv_rvweaken(timer->loop_sv);
    timer->self_sv = newSVsv(timer_obj);
    timer->deadline_ns = deadline;
    timer->sequence = ++loop->timer_sequence;
    timer->state = LE_TIMER_ACTIVE;
    le_timer_heap_insert(loop, timer);
    loop->timer_schedule_calls++;
    le_timer_maybe_rearm(loop, old_first);
}

static void le_timer_reschedule_native(le_timer_t *timer, int absolute,
    unsigned long long first_ns, unsigned long long interval_ns) {
    le_loop_t *loop;
    unsigned long long now;
    unsigned long long deadline;
    unsigned long long old_first;
    if (!timer || !timer->loop
        || (timer->state != LE_TIMER_ACTIVE
            && timer->state != LE_TIMER_FIRING))
        croak("reschedule(): Timer is not active");
    loop = timer->loop;
    now = le_now_ns();
    if (absolute) {
        deadline = first_ns;
    }
    else {
        if (first_ns > ULLONG_MAX - now)
            croak("Timer deadline overflow");
        deadline = now + first_ns;
    }
    old_first = loop->timer_heap_size
        ? loop->timer_heap[0]->deadline_ns : 0;
    if (timer->heap_index != LE_HEAP_NONE)
        le_timer_heap_remove(loop, timer);
    timer->initial_absolute = absolute ? 1 : 0;
    timer->initial_ns = first_ns;
    timer->interval_ns = interval_ns;
    timer->deadline_ns = deadline;
    timer->expirations = 0;
    timer->sequence = ++loop->timer_sequence;
    timer->state = LE_TIMER_ACTIVE;
    le_timer_heap_insert(loop, timer);
    loop->timer_reschedule_calls++;
    le_timer_maybe_rearm(loop, old_first);
}

static SV *le_timer_call(pTHX_ le_timer_t *timer) {
    SV *error = NULL;
    le_loop_t *loop = timer->loop;
    le_timer_descriptor_t *descriptor = timer->descriptor;
    if (!descriptor || !descriptor->callback_cv)
        croak("Timer callback descriptor is unavailable");
    ENTER;
    SAVETMPS;
    {
        dSP;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(timer->self_sv);
        PUTBACK;
        call_sv(descriptor->callback_cv, G_DISCARD | G_VOID | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            error = newSVsv(ERRSV);
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        PUTBACK;
    }
    FREETMPS;
    LEAVE;
    if (loop) {
        loop->callback_calls++;
        loop->callback_onearg_calls++;
        loop->callback_direct_cv_calls++;
        loop->timer_callback_calls++;
    }
    return error;
}

static void le_timer_source_ready(pTHX_ le_loop_t *loop) {
    unsigned long long kernel_expirations;
    unsigned long long batch_now;
    unsigned long long cutoff_sequence;
    unsigned int callbacks = 0;
    ssize_t count;
    SV *callback_error = NULL;
    if (!loop || loop->timer_fd < 0) return;
    do {
        count = read(loop->timer_fd, &kernel_expirations,
            sizeof(kernel_expirations));
    } while (count < 0 && errno == EINTR);
    if (count < 0 && errno != EAGAIN && errno != EWOULDBLOCK)
        croak("read timerfd failed: %s", strerror(errno));
    if (count >= 0 && count != (ssize_t)sizeof(kernel_expirations))
        croak("short read from timerfd");

    batch_now = le_now_ns();
    cutoff_sequence = loop->timer_sequence;
    loop->in_timer_dispatch++;
    while (callbacks < LE_TIMER_CALLBACK_BATCH && loop->timer_heap_size) {
        le_timer_t *timer = loop->timer_heap[0];
        unsigned long long due;
        unsigned long long represented = 1;
        if (timer->deadline_ns > batch_now
            || timer->sequence > cutoff_sequence)
            break;
        due = timer->deadline_ns;
        le_timer_heap_remove(loop, timer);
        if (timer->state != LE_TIMER_ACTIVE) continue;
        if (timer->interval_ns) {
            represented += (batch_now - due) / timer->interval_ns;
            if (represented > 1)
                loop->timer_coalesced_expirations += represented - 1;
            if (represented > (ULLONG_MAX - due) / timer->interval_ns)
                timer->deadline_ns = ULLONG_MAX;
            else
                timer->deadline_ns = due
                    + represented * timer->interval_ns;
            timer->expirations = represented;
            timer->sequence = ++loop->timer_sequence;
            timer->state = LE_TIMER_ACTIVE;
            le_timer_heap_insert(loop, timer);
        }
        else {
            timer->expirations = 1;
            timer->state = LE_TIMER_FIRING;
        }

        timer->in_callback = 1;
        loop->current_timer = timer;
        callback_error = le_timer_call(aTHX_ timer);
        loop->current_timer = NULL;
        timer->in_callback = 0;
        callbacks++;

        if (timer->state == LE_TIMER_FIRING) {
            timer->state = LE_TIMER_EXPIRED;
            loop->timer_expired_calls++;
            timer->cleanup_pending = 1;
        }
        if (timer->cleanup_pending)
            le_timer_release_refs(timer);
        if (callback_error || loop->stop_flag) break;
    }
    loop->in_timer_dispatch--;
    le_timer_rearm(loop);
    if (callback_error) croak_sv(callback_error);
}

static void le_timer_loop_cancel_all(le_loop_t *loop) {
    while (loop && loop->timer_heap_size) {
        le_timer_t *timer = loop->timer_heap[0];
        le_timer_heap_remove(loop, timer);
        timer->state = LE_TIMER_CANCELLED;
        timer->loop = NULL;
        le_timer_release_refs(timer);
    }
}

static void le_loop_child_detach_timers(le_loop_t *loop) {
    size_t index;
    if (!loop || !loop->timer_heap_size) return;
    for (index = 0; index < loop->timer_heap_size; index++) {
        le_timer_t *timer = loop->timer_heap[index];
        SV *loop_sv;
        SV *self_sv;
        if (!timer) continue;
        loop_sv = timer->loop_sv;
        self_sv = timer->self_sv;
        timer->loop = NULL;
        timer->loop_sv = NULL;
        timer->self_sv = NULL;
        timer->heap_index = LE_HEAP_NONE;
        timer->initial_absolute = 1;
        timer->initial_ns = timer->deadline_ns;
        timer->sequence = 0;
        timer->state = LE_TIMER_UNATTACHED;
        timer->cleanup_pending = 0;
        if (loop_sv) SvREFCNT_dec(loop_sv);
        if (self_sv) SvREFCNT_dec(self_sv);
        loop->timer_heap[index] = NULL;
    }
    loop->timer_heap_size = 0;
}

static void le_loop_child_discard_watchers(le_loop_t *loop) {
    size_t index;
    le_watcher_t *watcher;
    if (!loop) return;
    if (loop->registry) {
        for (index = 0; index < loop->reg_cap; index++) {
            watcher = loop->registry[index];
            if (!watcher) continue;
            loop->registry[index] = NULL;
            watcher->active = 0;
            le_watcher_destroy(watcher);
        }
    }
    while ((watcher = loop->watcher_pending) != NULL) {
        loop->watcher_pending = watcher->next_free;
        le_watcher_destroy(watcher);
    }
    while ((watcher = loop->watcher_freelist) != NULL) {
        loop->watcher_freelist = watcher->next_free;
        le_watcher_destroy(watcher);
    }
    while ((watcher = loop->watcher_retired) != NULL) {
        loop->watcher_retired = watcher->next_retired;
        le_watcher_destroy(watcher);
    }
    loop->watcher_freelist_depth = 0;
}

static void le_loop_child_reset(le_loop_t *loop) {
    int new_epoll_fd;
    int old_epoll_fd;
    int old_timer_fd;
    pid_t current = le_process_pid;
    if (!loop) croak("fork(): Loop is closed");
    if (loop->owner_pid == current)
        croak("fork(): child Loop reset requires an inherited Loop");
    if (loop->driver_depth || loop->in_dispatch_batch || loop->in_timer_dispatch)
        croak("fork(): Loop must be quiescent before fork");

    new_epoll_fd = epoll_create1(EPOLL_CLOEXEC);
    if (new_epoll_fd < 0)
        croak("fork(): child epoll_create1 failed: %s", strerror(errno));

    old_epoll_fd = loop->epoll_fd;
    old_timer_fd = loop->timer_fd;
    le_loop_child_detach_timers(loop);
    le_loop_child_discard_watchers(loop);

    loop->timer_fd = -1;
    loop->timer_source = NULL;
    if (old_timer_fd >= 0) close(old_timer_fd);
    if (old_epoll_fd >= 0) close(old_epoll_fd);
    loop->epoll_fd = new_epoll_fd;
    loop->owner_pid = current;
    loop->stop_flag = 0;
    loop->driver_depth = 0;
    loop->in_dispatch_batch = 0;
    loop->in_timer_dispatch = 0;
    loop->current_timer = NULL;
    if (loop->events)
        memset(loop->events, 0, loop->event_cap * sizeof(struct epoll_event));
}

static void le_loop_destroy(le_loop_t *loop) {
    if (!loop) return;
    le_timer_loop_cancel_all(loop);
    if (loop->registry) {
        for (size_t i = 0; i < loop->reg_cap; i++) {
            le_watcher_t *w = loop->registry[i];
            if (w) {
                loop->registry[i] = NULL;
                w->active = 0;
                le_watcher_destroy(w);
            }
        }
        free(loop->registry);
    }
    while (loop->watcher_pending) { le_watcher_t *w = loop->watcher_pending; loop->watcher_pending = w->next_free; le_watcher_destroy(w); }
    while (loop->watcher_freelist) { le_watcher_t *w = loop->watcher_freelist; loop->watcher_freelist = w->next_free; le_watcher_destroy(w); }
    while (loop->watcher_retired) { le_watcher_t *w = loop->watcher_retired; loop->watcher_retired = w->next_retired; le_watcher_destroy(w); }
    if (loop->timer_heap) free(loop->timer_heap);
    if (loop->timer_fd >= 0) close(loop->timer_fd);
    if (loop->events) free(loop->events);
    if (loop->epoll_fd >= 0) close(loop->epoll_fd);
    free(loop);
}

/* ---- Perl callback dispatch ----------------------------------------- */

static void le_count_callback(le_watcher_t *w, int one_arg, int direct_cv) {
    if (!w || !w->loop) return;
    w->loop->callback_calls++;
    if (one_arg) w->loop->callback_onearg_calls++;
    else w->loop->callback_noarg_calls++;
    if (direct_cv) w->loop->callback_direct_cv_calls++;
    else w->loop->callback_sv_calls++;
}

/*
 * Bounded Perl callback temporary scopes.
 *
 * ENTER/SAVETMPS setup is amortized across a bounded group of callbacks while
 * FREETMPS still runs after every callback. The measured default is 128. A
 * limit of zero intentionally means one scope for the complete epoll batch and
 * is retained only as a diagnostic tuning mode.
 */
static void le_call_watcher_cb_noarg(pTHX_ le_watcher_t *w, SV *cb, int direct_cv) {
    if (!cb || (!direct_cv && !SvOK(cb)) || !w || !w->active) return;
    dSP;
    PUSHMARK(SP);
    PUTBACK;
    call_sv(cb, G_DISCARD | G_VOID);
    FREETMPS;

    le_count_callback(w, 0, direct_cv);
}

static void le_call_watcher_cb_onearg(pTHX_ le_watcher_t *w, SV *cb, int direct_cv) {
    if (!cb || (!direct_cv && !SvOK(cb)) || !w || !w->active) return;
    dSP;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(w->callback_arg_data && w->data_sv ? w->data_sv : w->self_sv);
    PUTBACK;
    call_sv(cb, G_DISCARD | G_VOID);
    FREETMPS;

    le_count_callback(w, 1, direct_cv);
}

static void le_call_watcher_cb(pTHX_ le_watcher_t *w, SV *cb, int direct_cv) {
    if (!w || !w->active) return;
    if (w->callback_args) le_call_watcher_cb_onearg(aTHX_ w, cb, direct_cv);
    else le_call_watcher_cb_noarg(aTHX_ w, cb, direct_cv);
}

/*
 * Benchmark-only native echo path.
 *
 * NOT AN APPLICATION API. This diagnostic keeps the same real TCP workload
 * while removing Perl read/write work, allowing the benchmark to separate
 * callback entry from Perl sysread/buffer/syswrite cost. Mode 1 performs the
 * native echo with no Perl read callback; mode 2 calls an empty Perl callback
 * before the same native echo. Terminal handling remains on the normal path.
 */
static void le_bench_native_echo_read(le_watcher_t *w) {
    char buf[8192];
    le_loop_t *loop;

    if (!w || !w->active || !w->loop) return;
    loop = w->loop;
    loop->bench_native_echo_read_events++;

    while (w->active) {
        ssize_t n;
        size_t off;
        size_t len;

        loop->bench_native_echo_sysread_calls++;
        n = read(w->fd, buf, sizeof(buf));
        if (n > 0) {
            loop->bench_native_echo_bytes_read += (unsigned long long)n;
            off = 0;
            len = (size_t)n;
            while (off < len) {
                ssize_t wr;
                size_t remain = len - off;
                loop->bench_native_echo_syswrite_calls++;
                wr = write(w->fd, buf + off, remain);
                if (wr > 0) {
                    loop->bench_native_echo_bytes_written += (unsigned long long)wr;
                    if ((size_t)wr < remain) loop->bench_native_echo_partial_writes++;
                    off += (size_t)wr;
                    continue;
                }
                if (wr < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
                    loop->bench_native_echo_write_eagain++;
                    break;
                }
                loop->bench_native_echo_errors++;
                break;
            }
            continue;
        }
        if (n == 0) {
            loop->bench_native_echo_read_zero++;
            break;
        }
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            loop->bench_native_echo_read_eagain++;
            break;
        }
        loop->bench_native_echo_errors++;
        break;
    }
}

/* Apply the watcher's current logical interest mask back to epoll. */
static int le_apply_mask(le_watcher_t *w) {
    struct epoll_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.events = le_epoll_events(w);
    ev.data.ptr = (void *)w;
    return le_epoll_ctl_timed(w->loop, EPOLL_CTL_MOD, w->fd, &ev);
}

static void le_dispatch_batch_leave(pTHX_ void *ptr) {
    le_loop_t *loop = (le_loop_t *)ptr;
    PERL_UNUSED_CONTEXT;
    if (!loop) return;
    if (loop->in_dispatch_batch) loop->in_dispatch_batch--;
    if (!loop->in_dispatch_batch) le_watcher_promote_pending(loop);
}

static void le_loop_driver_leave(pTHX_ void *ptr) {
    le_loop_t *loop = (le_loop_t *)ptr;
    PERL_UNUSED_CONTEXT;
    if (loop && loop->driver_depth) loop->driver_depth--;
}

static void le_loop_driver_enter(pTHX_ le_loop_t *loop) {
    if (loop->driver_depth)
        croak("Loop is already running; reentrant driving is not allowed");
    loop->driver_depth++;
}


/*
 * Dispatch one epoll batch.
 *
 * Every event already carries the watcher pointer in data.ptr. The watcher is
 * validated against its active flag and owner loop before use. Reclaim/reuse
 * is deferred until the batch ends so stale data.ptr values cannot refer to a
 * newly repurposed watcher record.
 */
static void
le_dispatch_batch(pTHX_ le_loop_t *loop, int n) {
    int i;
    unsigned int scope_callbacks = 0;
    unsigned long long callback_before;

    loop->in_dispatch_batch++;
    ENTER;
    SAVEDESTRUCTOR_X(le_dispatch_batch_leave, loop);
    SAVETMPS;
    loop->callback_batch_scope_enters++;

    for (i = 0; i < n; i++) {
        uint32_t events = loop->events[i].events;
        le_watcher_t *w = (le_watcher_t *)loop->events[i].data.ptr;
        loop->direct_watcher_events++;
        if (!w || !w->active || w->loop != loop) continue;
        loop->dispatch_events++;
        le_note_ready_flags(loop, events);

        if (w->kind == LE_WATCHER_TIMER) {
            if (events & (EPOLLERR | EPOLLHUP))
                croak("Timer event source failed");
            if (events & EPOLLIN)
                le_timer_source_ready(aTHX_ loop);
            if (loop->stop_flag) break;
            continue;
        }

        /* Terminal/error callbacks run before normal read/write readiness. */
        if (events & (EPOLLERR | EPOLLHUP | EPOLLRDHUP)) {
            if (w->error_cb) {
                if (loop->callback_scope_limit && scope_callbacks >= loop->callback_scope_limit) {
                    if (scope_callbacks > loop->callback_scope_max_callbacks) loop->callback_scope_max_callbacks = scope_callbacks;
                    FREETMPS;
                    LEAVE;
                    ENTER;
                    SAVETMPS;
                    loop->callback_batch_scope_enters++;
                    loop->callback_scope_rotations++;
                    scope_callbacks = 0;
                }
                loop->error_callback_calls++;
                callback_before = loop->callback_calls;
                le_call_watcher_cb(aTHX_ w, w->error_cb, w->error_cb_direct_cv);
                scope_callbacks += (unsigned int)(loop->callback_calls - callback_before);
            }
            if (!w->active) continue;
        }
        if (events & EPOLLIN) {
            if (w->bench_native_echo) {
                if (w->bench_native_echo == 2 && w->read_cb) {
                    if (loop->callback_scope_limit && scope_callbacks >= loop->callback_scope_limit) {
                        if (scope_callbacks > loop->callback_scope_max_callbacks) loop->callback_scope_max_callbacks = scope_callbacks;
                        FREETMPS;
                        LEAVE;
                        ENTER;
                        SAVETMPS;
                        loop->callback_batch_scope_enters++;
                        loop->callback_scope_rotations++;
                        scope_callbacks = 0;
                    }
                    loop->read_callback_calls++;
                    loop->bench_native_echo_perl_read_callbacks++;
                    callback_before = loop->callback_calls;
                    le_call_watcher_cb(aTHX_ w, w->read_cb, w->read_cb_direct_cv);
                    scope_callbacks += (unsigned int)(loop->callback_calls - callback_before);
                }
                if (!w->active) continue;
                le_bench_native_echo_read(w);
            }
            else if (w->read_cb) {
                if (loop->callback_scope_limit && scope_callbacks >= loop->callback_scope_limit) {
                    if (scope_callbacks > loop->callback_scope_max_callbacks) loop->callback_scope_max_callbacks = scope_callbacks;
                    FREETMPS;
                    LEAVE;
                    ENTER;
                    SAVETMPS;
                    loop->callback_batch_scope_enters++;
                    loop->callback_scope_rotations++;
                    scope_callbacks = 0;
                }
                loop->read_callback_calls++;
                callback_before = loop->callback_calls;
                le_call_watcher_cb(aTHX_ w, w->read_cb, w->read_cb_direct_cv);
                scope_callbacks += (unsigned int)(loop->callback_calls - callback_before);
            }
            if (!w->active) continue;
        }
        if (events & EPOLLOUT) {
            if (w->write_cb) {
                if (loop->callback_scope_limit && scope_callbacks >= loop->callback_scope_limit) {
                    if (scope_callbacks > loop->callback_scope_max_callbacks) loop->callback_scope_max_callbacks = scope_callbacks;
                    FREETMPS;
                    LEAVE;
                    ENTER;
                    SAVETMPS;
                    loop->callback_batch_scope_enters++;
                    loop->callback_scope_rotations++;
                    scope_callbacks = 0;
                }
                loop->write_callback_calls++;
                callback_before = loop->callback_calls;
                le_call_watcher_cb(aTHX_ w, w->write_cb, w->write_cb_direct_cv);
                scope_callbacks += (unsigned int)(loop->callback_calls - callback_before);
            }
        }
        if (loop->stop_flag) break;
    }

    if (scope_callbacks > loop->callback_scope_max_callbacks) loop->callback_scope_max_callbacks = scope_callbacks;
    FREETMPS;
    LEAVE;
}



typedef struct {
    SV *fh;
    SV *data;
    SV *read_cb;
    SV *write_cb;
    SV *error_cb;
    int oneshot;
    int edge_triggered;
    int callback_args;
    int callback_arg_data;
    int lean;
    int bench_native_echo;
    int internal;
} le_watch_opts_t;

static void le_watch_opts_init(le_watch_opts_t *opt) {
    memset(opt, 0, sizeof(*opt));
    opt->callback_args = 1;
}

static int le_watch_parse_common_option(const char *key, SV *val, le_watch_opts_t *opt) {
    if (strEQ(key, "data")) opt->data = val;
    else if (strEQ(key, "read")) opt->read_cb = val;
    else if (strEQ(key, "write")) opt->write_cb = val;
    else if (strEQ(key, "error")) opt->error_cb = val;
    else if (strEQ(key, "oneshot")) opt->oneshot = SvTRUE(val) ? 1 : 0;
    else if (strEQ(key, "edge_triggered")) opt->edge_triggered = SvTRUE(val) ? 1 : 0;
    else if (strEQ(key, "no_args")) {
        if (SvTRUE(val)) opt->callback_args = 0;
    }
    else if (strEQ(key, "_callback_data_arg")) {
        opt->callback_arg_data = SvTRUE(val) ? 1 : 0;
        if (opt->callback_arg_data) opt->callback_args = 1;
    }
    else if (strEQ(key, "_internal")) {
        opt->internal = SvTRUE(val) ? 1 : 0;
    }
    else if (strEQ(key, "lean")) {
        opt->lean = SvTRUE(val) ? 1 : 0;
    }
    else if (strEQ(key, "_bench_native_echo")) {
        opt->bench_native_echo = (int)SvIV(val);
        if (opt->bench_native_echo < 0 || opt->bench_native_echo > 2)
            croak("_bench_native_echo must be 0, 1, or 2");
    }
    else return 0;
    return 1;
}

static SV *le_watch_register(SV *loop_obj, le_loop_t *loop, int fd, le_watch_opts_t *opt) {
    le_watcher_t *w;
    le_watcher_t *old;
    SV *watcher_sv;
    le_registration_t *registration;
    struct epoll_event ev;
    int operation;

    if (opt->callback_arg_data) {
        opt->callback_args = 1;
        if (!opt->data || !SvOK(opt->data)) croak("_callback_data_arg requires data");
    }

    le_registry_grow(loop, fd);
    old = loop->registry[fd];

    w = le_watcher_alloc(loop);
    w->fd = fd;
    w->loop = loop;
    w->active = 1;
    w->mask = le_mask_from_callbacks(opt->read_cb, opt->write_cb);
    w->flags = (opt->oneshot ? EPOLLONESHOT : 0) | (opt->edge_triggered ? EPOLLET : 0);
    w->callback_args = opt->callback_args ? 1 : 0;
    w->callback_arg_data = opt->callback_arg_data ? 1 : 0;
    w->internal = opt->internal ? 1 : 0;
    w->bench_native_echo = opt->bench_native_echo;
    if (w->bench_native_echo) w->mask |= EPOLLIN;
    w->lean = (opt->lean && !w->callback_args) ? 1 : 0;
    if (w->lean) loop->lean_watchers++;

    registration = (le_registration_t *)calloc(1, sizeof(*registration));
    if (!registration) {
        le_watcher_destroy(w);
        croak("calloc registration failed");
    }
    registration->watcher = w;
    registration->refs = 2;
    w->registration = registration;
    watcher_sv = sv_setref_pv(newSV(0), "Linux::Event::_Registration", (void*)registration);
    if (!w->lean || (w->callback_args && !w->callback_arg_data))
        w->self_sv = newSVsv(watcher_sv);
    if (!w->lean) {
        w->loop_sv = newSVsv(loop_obj);
        if (opt->fh) w->fh_sv = newSVsv(opt->fh);
        if (opt->data) w->data_sv = newSVsv(opt->data);
    }
    if (opt->read_cb) w->read_cb = le_stored_callback_from_sv(opt->read_cb, &w->read_cb_direct_cv);
    if (opt->write_cb) w->write_cb = le_stored_callback_from_sv(opt->write_cb, &w->write_cb_direct_cv);
    if (opt->error_cb) w->error_cb = le_stored_callback_from_sv(opt->error_cb, &w->error_cb_direct_cv);

    memset(&ev, 0, sizeof(ev));
    ev.events = le_epoll_events(w);
    ev.data.ptr = (void *)w;
    operation = old ? EPOLL_CTL_MOD : EPOLL_CTL_ADD;
    if (le_epoll_ctl_timed(loop, operation, fd, &ev) < 0
        && !(old && errno == ENOENT
            && le_epoll_ctl_timed(loop, EPOLL_CTL_ADD, fd, &ev) == 0)) {
        int err = errno;
        le_watcher_destroy(w);
        SvREFCNT_dec(watcher_sv);
        croak("epoll_ctl %s fd %d failed: %s",
            old ? "MOD" : "ADD", fd, strerror(err));
    }
    if (old) {
        old->active = 0;
        le_watcher_recycle_or_destroy(old);
    }
    loop->registry[fd] = w;
    return watcher_sv;
}

static int le_fd_from_fh(SV *fh) {
    IO *io = sv_2io(fh);
    PerlIO *fp = IoIFP(io);
    int fd;
    if (!fp) fp = IoOFP(io);
    if (!fp) croak("watch(): fh has no file descriptor");
    fd = PerlIO_fileno(fp);
    if (fd < 0) croak("watch(): fh has no file descriptor");
    return fd;
}

static int le_fd_from_sv(SV *value, const char *method) {
    NV number;
    if (!value || !SvOK(value) || SvROK(value) || !looks_like_number(value))
        croak("%s(): fd must be a non-negative integer", method);
    number = SvNV(value);
    if (!isfinite(number) || number < 0.0 || number > (NV)INT_MAX
            || number != (NV)(int)number)
        croak("%s(): fd must be a non-negative integer", method);
    return (int)number;
}

MODULE = Linux::Event::Loop    PACKAGE = Linux::Event::Loop
PROTOTYPES: DISABLE

BOOT:
    le_process_pid = getpid();
    if (!le_atfork_registered) {
        int error = pthread_atfork(NULL, NULL, le_process_after_fork_child);
        if (error)
            croak("pthread_atfork failed: %s", strerror(error));
        le_atfork_registered = 1;
    }


SV *
new(CLASS)
    const char *CLASS
  CODE:
    le_loop_t *loop = (le_loop_t *)calloc(1, sizeof(le_loop_t));
    if (!loop) croak("calloc loop failed");
    loop->timer_fd = -1;
    loop->owner_pid = le_process_pid;
    loop->epoll_fd = epoll_create1(EPOLL_CLOEXEC);
    if (loop->epoll_fd < 0) { int err = errno; free(loop); croak("epoll_create1 failed: %s", strerror(err)); }
    loop->event_cap = LE_INITIAL_EVENTS;
    loop->callback_scope_limit = LE_CALLBACK_SCOPE_DEFAULT;
    loop->events = (struct epoll_event *)calloc(loop->event_cap, sizeof(struct epoll_event));
    loop->reg_cap = LE_INITIAL_REGISTRY;
    loop->registry = (le_watcher_t **)calloc(loop->reg_cap, sizeof(le_watcher_t *));
    if (!loop->events || !loop->registry) {
        if (loop->events) free(loop->events);
        if (loop->registry) free(loop->registry);
        close(loop->epoll_fd);
        free(loop);
        croak("calloc loop internals failed");
    }
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void*)loop);
  OUTPUT:
    RETVAL

void
DESTROY(loop_obj)
    SV *loop_obj
  CODE:
    le_loop_t *loop = le_loop_from_sv(loop_obj);
    sv_setiv(SvRV(loop_obj), 0);
    le_loop_destroy(loop);

void
stop(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "stop");
    loop->stop_flag = 1;

void
_assert_owner_native(loop_obj, operation)
    SV *loop_obj
    const char *operation
  CODE:
    le_loop_assert_owner(le_loop_from_sv(loop_obj), operation);

IV
_owner_pid_native(loop_obj)
    SV *loop_obj
  CODE:
    RETVAL = (IV)le_loop_from_sv(loop_obj)->owner_pid;
  OUTPUT:
    RETVAL

void
_fork_child_reset(loop_obj)
    SV *loop_obj
  CODE:
    le_loop_child_reset(le_loop_from_sv(loop_obj));

int
running(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "running");
    RETVAL = loop->driver_depth > 0 ? 1 : 0;
  OUTPUT:
    RETVAL

SV *
_object_candidates_native(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
    AV *objects;
    size_t index;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "objects");
    objects = newAV();
    for (index = 0; index < loop->reg_cap; index++) {
        le_watcher_t *watcher = loop->registry[index];
        if (watcher && watcher->active && watcher->data_sv)
            av_push(objects, newSVsv(watcher->data_sv));
    }
    for (index = 0; index < loop->timer_heap_size; index++) {
        le_timer_t *timer = loop->timer_heap[index];
        if (timer && timer->self_sv)
            av_push(objects, newSVsv(timer->self_sv));
    }
    if (loop->current_timer && loop->current_timer->self_sv)
        av_push(objects, newSVsv(loop->current_timer->self_sv));
    RETVAL = newRV_noinc((SV *)objects);
  OUTPUT:
    RETVAL

SV *
_resources_native(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
    HV *result;
    AV *public_fds;
    unsigned long long registered = 0;
    unsigned long long public_count = 0;
    unsigned long long internal_count = 0;
    size_t index;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "resources");
    result = newHV();
    public_fds = newAV();
    for (index = 0; index < loop->reg_cap; index++) {
        le_watcher_t *watcher = loop->registry[index];
        if (!watcher || !watcher->active) continue;
        registered++;
        if (watcher->internal || watcher->kind != LE_WATCHER_USER) {
            internal_count++;
        }
        else {
            public_count++;
            av_push(public_fds, newSViv(watcher->fd));
        }
    }
    hv_stores(result, "epoll_fd", newSViv(loop->epoll_fd));
    hv_stores(result, "timer_fd", loop->timer_fd >= 0
        ? newSViv(loop->timer_fd) : newSV(0));
    hv_stores(result, "registered_fds", newSVuv(registered));
    hv_stores(result, "public_registrations", newSVuv(public_count));
    hv_stores(result, "internal_registrations", newSVuv(internal_count));
    hv_stores(result, "public_registration_fds",
        newRV_noinc((SV *)public_fds));
    hv_stores(result, "active_timers", newSVuv(loop->timer_heap_size));
    hv_stores(result, "registry_capacity", newSVuv(loop->reg_cap));
    hv_stores(result, "timer_heap_capacity", newSVuv(loop->timer_heap_cap));
    hv_stores(result, "event_capacity", newSVuv(loop->event_cap));
    RETVAL = newRV_noinc((SV *)result);
  OUTPUT:
    RETVAL

SV *
stats(loop_obj)
    SV *loop_obj
  CODE:
    le_loop_t *loop = le_loop_from_sv(loop_obj);
    HV *hv;
    le_loop_assert_owner(loop, "stats");
    hv = newHV();
    hv_stores(hv, "event_capacity", newSVuv(loop->event_cap));
    hv_stores(hv, "epoll_wait_calls", newSVuv(loop->epoll_wait_calls));
    hv_stores(hv, "epoll_wait_empty_calls", newSVuv(loop->epoll_wait_empty_calls));
    hv_stores(hv, "epoll_wait_full_batches", newSVuv(loop->epoll_wait_full_batches));
    hv_stores(hv, "epoll_wait_max_batch", newSVuv(loop->epoll_wait_max_batch));
    hv_stores(hv, "ready_events_returned", newSVuv(loop->ready_events_returned));
    hv_stores(hv, "ready_read_events", newSVuv(loop->ready_read_events));
    hv_stores(hv, "ready_write_events", newSVuv(loop->ready_write_events));
    hv_stores(hv, "ready_error_events", newSVuv(loop->ready_error_events));
    hv_stores(hv, "ready_epollerr_events", newSVuv(loop->ready_epollerr_events));
    hv_stores(hv, "ready_hup_events", newSVuv(loop->ready_hup_events));
    hv_stores(hv, "ready_rdhup_events", newSVuv(loop->ready_rdhup_events));
    hv_stores(hv, "ready_in_hup_events", newSVuv(loop->ready_in_hup_events));
    hv_stores(hv, "ready_in_rdhup_events", newSVuv(loop->ready_in_rdhup_events));
    hv_stores(hv, "ready_multi_events", newSVuv(loop->ready_multi_events));
    hv_stores(hv, "callback_calls", newSVuv(loop->callback_calls));
    hv_stores(hv, "read_callback_calls", newSVuv(loop->read_callback_calls));
    hv_stores(hv, "write_callback_calls", newSVuv(loop->write_callback_calls));
    hv_stores(hv, "error_callback_calls", newSVuv(loop->error_callback_calls));
    hv_stores(hv, "epoll_ctl_add_calls", newSVuv(loop->epoll_ctl_add_calls));
    hv_stores(hv, "epoll_ctl_mod_calls", newSVuv(loop->epoll_ctl_mod_calls));
    hv_stores(hv, "epoll_ctl_del_calls", newSVuv(loop->epoll_ctl_del_calls));
    hv_stores(hv, "watcher_lookup_calls", newSVuv(loop->watcher_lookup_calls));
    hv_stores(hv, "direct_watcher_events", newSVuv(loop->direct_watcher_events));
    hv_stores(hv, "dispatch_events", newSVuv(loop->dispatch_events));
    hv_stores(hv, "callback_noarg_calls", newSVuv(loop->callback_noarg_calls));
    hv_stores(hv, "callback_onearg_calls", newSVuv(loop->callback_onearg_calls));
    hv_stores(hv, "callback_direct_cv_calls", newSVuv(loop->callback_direct_cv_calls));
    hv_stores(hv, "callback_sv_calls", newSVuv(loop->callback_sv_calls));
    hv_stores(hv, "callback_batch_scope_enters", newSVuv(loop->callback_batch_scope_enters));
    hv_stores(hv, "callback_scope_rotations", newSVuv(loop->callback_scope_rotations));
    hv_stores(hv, "callback_scope_max_callbacks", newSVuv(loop->callback_scope_max_callbacks));
    hv_stores(hv, "callback_scope_limit", newSVuv(loop->callback_scope_limit));
    hv_stores(hv, "poll_calls", newSVuv(loop->poll_calls));
    hv_stores(hv, "run_once_calls", newSVuv(loop->run_once_calls));
    hv_stores(hv, "run_calls", newSVuv(loop->run_calls));
    hv_stores(hv, "run_for_calls", newSVuv(loop->run_for_calls));
    hv_stores(hv, "active_timers", newSVuv(loop->timer_heap_size));
    hv_stores(hv, "timerfd_create_calls", newSVuv(loop->timerfd_create_calls));
    hv_stores(hv, "timerfd_settime_calls", newSVuv(loop->timerfd_settime_calls));
    hv_stores(hv, "timer_schedule_calls", newSVuv(loop->timer_schedule_calls));
    hv_stores(hv, "timer_reschedule_calls", newSVuv(loop->timer_reschedule_calls));
    hv_stores(hv, "timer_cancel_calls", newSVuv(loop->timer_cancel_calls));
    hv_stores(hv, "timer_callback_calls", newSVuv(loop->timer_callback_calls));
    hv_stores(hv, "timer_expired_calls", newSVuv(loop->timer_expired_calls));
    hv_stores(hv, "timer_coalesced_expirations", newSVuv(loop->timer_coalesced_expirations));
    hv_stores(hv, "timer_heap_max_size", newSVuv(loop->timer_heap_max_size));
    hv_stores(hv, "bench_native_echo_read_events", newSVuv(loop->bench_native_echo_read_events));
    hv_stores(hv, "bench_native_echo_perl_read_callbacks", newSVuv(loop->bench_native_echo_perl_read_callbacks));
    hv_stores(hv, "bench_native_echo_sysread_calls", newSVuv(loop->bench_native_echo_sysread_calls));
    hv_stores(hv, "bench_native_echo_syswrite_calls", newSVuv(loop->bench_native_echo_syswrite_calls));
    hv_stores(hv, "bench_native_echo_bytes_read", newSVuv(loop->bench_native_echo_bytes_read));
    hv_stores(hv, "bench_native_echo_bytes_written", newSVuv(loop->bench_native_echo_bytes_written));
    hv_stores(hv, "bench_native_echo_read_eagain", newSVuv(loop->bench_native_echo_read_eagain));
    hv_stores(hv, "bench_native_echo_write_eagain", newSVuv(loop->bench_native_echo_write_eagain));
    hv_stores(hv, "bench_native_echo_partial_writes", newSVuv(loop->bench_native_echo_partial_writes));
    hv_stores(hv, "bench_native_echo_read_zero", newSVuv(loop->bench_native_echo_read_zero));
    hv_stores(hv, "bench_native_echo_errors", newSVuv(loop->bench_native_echo_errors));
    hv_stores(hv, "lean_watchers", newSVuv(loop->lean_watchers));
    hv_stores(hv, "watcher_alloc_calls", newSVuv(loop->watcher_alloc_calls));
    hv_stores(hv, "watcher_reuse_calls", newSVuv(loop->watcher_reuse_calls));
    hv_stores(hv, "watcher_recycle_calls", newSVuv(loop->watcher_recycle_calls));
    hv_stores(hv, "watcher_destroy_calls", newSVuv(loop->watcher_destroy_calls));
    hv_stores(hv, "watcher_freelist_depth", newSVuv(loop->watcher_freelist_depth));
    hv_stores(hv, "watcher_freelist_max_depth", newSVuv(loop->watcher_freelist_max_depth));
    hv_stores(hv, "watcher_reclaim_enabled", newSViv(loop->watcher_reclaim_enabled));
    hv_stores(hv, "profile_enabled", newSViv(loop->profile_enabled));
    hv_stores(hv, "epoll_wait_ns", newSVuv(loop->epoll_wait_ns));
    hv_stores(hv, "epoll_ctl_add_ns", newSVuv(loop->epoll_ctl_add_ns));
    hv_stores(hv, "epoll_ctl_mod_ns", newSVuv(loop->epoll_ctl_mod_ns));
    hv_stores(hv, "epoll_ctl_del_ns", newSVuv(loop->epoll_ctl_del_ns));
    hv_stores(hv, "watcher_lookup_ns", newSVuv(loop->watcher_lookup_ns));
    hv_stores(hv, "dispatch_ns", newSVuv(loop->dispatch_ns));
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
profile(loop_obj, enabled)
    SV *loop_obj
    int enabled
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "profile");
    loop->profile_enabled = enabled ? 1 : 0;
    RETVAL = newSVsv(loop_obj);
  OUTPUT:
    RETVAL

void
enable_watcher_reclaim(loop_obj, enabled = 1)
    SV *loop_obj
    int enabled
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "enable_watcher_reclaim");
    loop->watcher_reclaim_enabled = enabled ? 1 : 0;


unsigned int
event_capacity(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "event_capacity");
    RETVAL = (unsigned int)loop->event_cap;
  OUTPUT:
    RETVAL

void
set_event_capacity(loop_obj, capacity)
    SV *loop_obj
    unsigned int capacity
  CODE:
    le_loop_t *loop = le_loop_from_sv(loop_obj);
    struct epoll_event *events;
    le_loop_assert_owner(loop, "set_event_capacity");
    if (capacity < 1) croak("event capacity must be >= 1");
    if (capacity > 1048576) croak("event capacity too large");
    if (loop->driver_depth || loop->in_dispatch_batch)
        croak("event capacity cannot change while Loop is running or dispatching");
    events = (struct epoll_event *)calloc((size_t)capacity, sizeof(struct epoll_event));
    if (!events) croak("calloc events failed");
    free(loop->events);
    loop->events = events;
    loop->event_cap = (size_t)capacity;

unsigned int
callback_scope_limit(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "callback_scope_limit");
    RETVAL = loop->callback_scope_limit;
  OUTPUT:
    RETVAL

void
set_callback_scope_limit(loop_obj, limit)
    SV *loop_obj
    unsigned int limit
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "set_callback_scope_limit");
    if (limit > 1048576) croak("callback scope limit too large");
    loop->callback_scope_limit = limit;

void
reset_stats(loop_obj)
    SV *loop_obj
  CODE:
    le_loop_t *loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "reset_stats");
    loop->epoll_wait_calls = 0;
    loop->epoll_wait_empty_calls = 0;
    loop->epoll_wait_full_batches = 0;
    loop->epoll_wait_max_batch = 0;
    loop->ready_events_returned = 0;
    loop->ready_read_events = 0;
    loop->ready_write_events = 0;
    loop->ready_error_events = 0;
    loop->ready_epollerr_events = 0;
    loop->ready_hup_events = 0;
    loop->ready_rdhup_events = 0;
    loop->ready_in_hup_events = 0;
    loop->ready_in_rdhup_events = 0;
    loop->ready_multi_events = 0;
    loop->callback_calls = 0;
    loop->read_callback_calls = 0;
    loop->write_callback_calls = 0;
    loop->error_callback_calls = 0;
    loop->epoll_ctl_add_calls = 0;
    loop->epoll_ctl_mod_calls = 0;
    loop->epoll_ctl_del_calls = 0;
    loop->watcher_lookup_calls = 0;
    loop->direct_watcher_events = 0;
    loop->dispatch_events = 0;
    loop->callback_noarg_calls = 0;
    loop->callback_onearg_calls = 0;
    loop->callback_direct_cv_calls = 0;
    loop->callback_sv_calls = 0;
    loop->callback_batch_scope_enters = 0;
    loop->callback_scope_rotations = 0;
    loop->callback_scope_max_callbacks = 0;
    loop->poll_calls = 0;
    loop->run_once_calls = 0;
    loop->run_calls = 0;
    loop->run_for_calls = 0;
    loop->timerfd_create_calls = 0;
    loop->timerfd_settime_calls = 0;
    loop->timer_schedule_calls = 0;
    loop->timer_reschedule_calls = 0;
    loop->timer_cancel_calls = 0;
    loop->timer_callback_calls = 0;
    loop->timer_expired_calls = 0;
    loop->timer_coalesced_expirations = 0;
    loop->timer_heap_max_size = (unsigned long long)loop->timer_heap_size;
    loop->bench_native_echo_read_events = 0;
    loop->bench_native_echo_perl_read_callbacks = 0;
    loop->bench_native_echo_sysread_calls = 0;
    loop->bench_native_echo_syswrite_calls = 0;
    loop->bench_native_echo_bytes_read = 0;
    loop->bench_native_echo_bytes_written = 0;
    loop->bench_native_echo_read_eagain = 0;
    loop->bench_native_echo_write_eagain = 0;
    loop->bench_native_echo_partial_writes = 0;
    loop->bench_native_echo_read_zero = 0;
    loop->bench_native_echo_errors = 0;
    loop->lean_watchers = 0;
    loop->watcher_alloc_calls = 0;
    loop->watcher_reuse_calls = 0;
    loop->watcher_recycle_calls = 0;
    loop->watcher_destroy_calls = 0;
    loop->watcher_freelist_max_depth = loop->watcher_freelist_depth;
    loop->epoll_wait_ns = 0;
    loop->epoll_ctl_add_ns = 0;
    loop->epoll_ctl_mod_ns = 0;
    loop->epoll_ctl_del_ns = 0;
    loop->watcher_lookup_ns = 0;
    loop->dispatch_ns = 0;

SV *
watch(loop_obj, ...)
    SV *loop_obj
  PREINIT:
    int i;
    int fd = -1;
    int has_fh = 0;
    int has_fd = 0;
    SV *fd_sv = NULL;
    le_loop_t *loop;
    le_watch_opts_t opt;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "watch");
    if (items < 3 || ((items - 1) % 2) != 0)
        croak("watch requires key/value pairs including exactly one of fh or fd");
    le_watch_opts_init(&opt);
    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "fh")) {
            if (has_fh) croak("watch(): duplicate fh option");
            opt.fh = val;
            has_fh = 1;
        }
        else if (strEQ(key, "fd")) {
            if (has_fd) croak("watch(): duplicate fd option");
            fd_sv = val;
            has_fd = 1;
        }
        else if (!le_watch_parse_common_option(key, val, &opt)) {
            croak("unknown watch option '%s'", key);
        }
    }
    if (has_fh == has_fd) croak("watch(): exactly one of fh or fd is required");
    if (has_fh) {
        fd = le_fd_from_fh(opt.fh);
    } else {
        fd = le_fd_from_sv(fd_sv, "watch");
    }
    RETVAL = le_watch_register(loop_obj, loop, fd, &opt);
  OUTPUT:
    RETVAL

SV *
watch_fd(loop_obj, fd_sv, ...)
    SV *loop_obj
    SV *fd_sv
  PREINIT:
    int i;
    int fd;
    le_loop_t *loop;
    le_watch_opts_t opt;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "watch_fd");
    fd = le_fd_from_sv(fd_sv, "watch_fd");
    if (items < 2 || ((items - 2) % 2) != 0)
        croak("watch_fd requires fd plus key/value pairs");
    le_watch_opts_init(&opt);
    for (i = 2; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);
        if (strEQ(key, "fh")) opt.fh = val;
        else if (!le_watch_parse_common_option(key, val, &opt))
            croak("unknown watch_fd option '%s'", key);
    }
    RETVAL = le_watch_register(loop_obj, loop, fd, &opt);
  OUTPUT:
    RETVAL

void
unwatch_fd(loop_obj, fd_sv)
    SV *loop_obj
    SV *fd_sv
  PREINIT:
    int fd;
  CODE:
    le_loop_t *loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "unwatch_fd");
    fd = le_fd_from_sv(fd_sv, "unwatch_fd");
    if (fd < 0 || (size_t)fd >= loop->reg_cap) XSRETURN_EMPTY;
    le_watcher_t *w = loop->registry[fd];
    if (!w) XSRETURN_EMPTY;
    le_epoll_ctl_timed(loop, EPOLL_CTL_DEL, fd, NULL);
    loop->registry[fd] = NULL;
    w->active = 0;
    le_watcher_recycle_or_destroy(w);


int
poll_fd(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "poll_fd");
    RETVAL = loop->epoll_fd;
  OUTPUT:
    RETVAL

int
poll(loop_obj)
    SV *loop_obj
  PREINIT:
    int n;
    le_loop_t *loop;
    unsigned long long t0;
    unsigned long long dispatch_t0;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "poll");
    loop->poll_calls++;
    le_loop_driver_enter(aTHX_ loop);
    ENTER;
    SAVEDESTRUCTOR_X(le_loop_driver_leave, loop);
    loop->stop_flag = 0;
    t0 = loop->profile_enabled ? le_now_ns() : 0;
    n = epoll_wait(loop->epoll_fd, loop->events, (int)loop->event_cap, 0);
    if (loop->profile_enabled) loop->epoll_wait_ns += le_now_ns() - t0;
    if (n < 0) {
        if (errno == EINTR) RETVAL = 0;
        else croak("epoll_wait failed: %s", strerror(errno));
    }
    else {
        le_note_epoll_batch(loop, n);
        dispatch_t0 = loop->profile_enabled ? le_now_ns() : 0;
        le_dispatch_batch(aTHX_ loop, n);
        if (loop->profile_enabled) loop->dispatch_ns += le_now_ns() - dispatch_t0;
        RETVAL = n;
    }
    LEAVE;
  OUTPUT:
    RETVAL

int
run_once(loop_obj, timeout_value = -1)
    SV *loop_obj
    IV timeout_value
  PREINIT:
    int n; int timeout_ms; le_loop_t *loop; unsigned long long t0; unsigned long long dispatch_t0;
  CODE:
    if (timeout_value > INT_MAX)
        croak("run_once timeout is too large");
    timeout_ms = timeout_value < 0 ? -1 : (int)timeout_value;
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "run_once");
    loop->run_once_calls++;
    le_loop_driver_enter(aTHX_ loop);
    ENTER;
    SAVEDESTRUCTOR_X(le_loop_driver_leave, loop);
    loop->stop_flag = 0;
    {
        t0 = loop->profile_enabled ? le_now_ns() : 0;
        n = epoll_wait(loop->epoll_fd, loop->events, (int)loop->event_cap, timeout_ms);
        if (loop->profile_enabled) loop->epoll_wait_ns += le_now_ns() - t0;
        if (n < 0) { if (errno == EINTR) RETVAL = 0; else croak("epoll_wait failed: %s", strerror(errno)); }
        else {
            le_note_epoll_batch(loop, n);
            dispatch_t0 = loop->profile_enabled ? le_now_ns() : 0;
            le_dispatch_batch(aTHX_ loop, n);
            if (loop->profile_enabled) loop->dispatch_ns += le_now_ns() - dispatch_t0;
            RETVAL = n;
        }
    }
    LEAVE;
  OUTPUT:
    RETVAL

void
run(loop_obj)
    SV *loop_obj
  PREINIT:
    le_loop_t *loop;
    int n;
    unsigned long long t0;
    unsigned long long dispatch_t0;
  CODE:
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "run");
    loop->run_calls++;
    le_loop_driver_enter(aTHX_ loop);
    ENTER;
    SAVEDESTRUCTOR_X(le_loop_driver_leave, loop);
    loop->stop_flag = 0;
    while (!loop->stop_flag) {
        t0 = loop->profile_enabled ? le_now_ns() : 0;
        n = epoll_wait(loop->epoll_fd, loop->events, (int)loop->event_cap, -1);
        if (loop->profile_enabled) loop->epoll_wait_ns += le_now_ns() - t0;
        if (n < 0) { if (errno == EINTR) continue; croak("epoll_wait failed: %s", strerror(errno)); }
        le_note_epoll_batch(loop, n);
        dispatch_t0 = loop->profile_enabled ? le_now_ns() : 0;
        le_dispatch_batch(aTHX_ loop, n);
        if (loop->profile_enabled) loop->dispatch_ns += le_now_ns() - dispatch_t0;
    }
    LEAVE;

void
run_for(loop_obj, seconds)
    SV *loop_obj
    double seconds
  PREINIT:
    le_loop_t *loop;
    int n;
    int timeout_ms;
    unsigned long long duration_ns;
    unsigned long long now_ns;
    unsigned long long deadline_ns;
    unsigned long long remaining_ns;
    unsigned long long remaining_ms;
    unsigned long long t0;
    unsigned long long dispatch_t0;
  CODE:
    if (!isfinite(seconds) || seconds < 0.0)
        croak("run_for seconds must be a finite non-negative number");
    if (seconds >= 18446744073.0) croak("run_for seconds too large");
    now_ns = le_now_ns();
    duration_ns = (unsigned long long)(seconds * 1000000000.0);
    if (duration_ns > ULLONG_MAX - now_ns)
        croak("run_for deadline overflow");
    deadline_ns = now_ns + duration_ns;
    loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "run_for");
    loop->run_for_calls++;
    le_loop_driver_enter(aTHX_ loop);
    ENTER;
    SAVEDESTRUCTOR_X(le_loop_driver_leave, loop);
    loop->stop_flag = 0;

    while (!loop->stop_flag) {
        now_ns = le_now_ns();
        if (now_ns >= deadline_ns) break;
        remaining_ns = deadline_ns - now_ns;
        remaining_ms = remaining_ns / 1000000ULL
            + (remaining_ns % 1000000ULL != 0);
        timeout_ms = remaining_ms > (unsigned long long)INT_MAX
            ? INT_MAX : (int)remaining_ms;

        t0 = loop->profile_enabled ? le_now_ns() : 0;
        n = epoll_wait(loop->epoll_fd, loop->events, (int)loop->event_cap, timeout_ms);
        if (loop->profile_enabled) loop->epoll_wait_ns += le_now_ns() - t0;
        if (n < 0) {
            if (errno == EINTR) continue;
            croak("epoll_wait failed: %s", strerror(errno));
        }
        le_note_epoll_batch(loop, n);
        if (n == 0) continue;
        dispatch_t0 = loop->profile_enabled ? le_now_ns() : 0;
        le_dispatch_batch(aTHX_ loop, n);
        if (loop->profile_enabled) loop->dispatch_ns += le_now_ns() - dispatch_t0;
    }
    LEAVE;

MODULE = Linux::Event::Loop    PACKAGE = Linux::Event::Kernel::Timer::_Descriptor
PROTOTYPES: DISABLE

SV *
new(CLASS, callback)
    const char *CLASS
    SV *callback
  CODE:
    le_timer_descriptor_t *descriptor;
    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
        croak("Timer on_timer must resolve to a coderef");
    descriptor = (le_timer_descriptor_t *)calloc(1, sizeof(*descriptor));
    if (!descriptor) croak("calloc Timer descriptor failed");
    descriptor->callback_cv = le_stored_callback_from_sv(
        callback, &descriptor->callback_direct_cv);
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)descriptor);
  OUTPUT:
    RETVAL

void
DESTROY(descriptor_obj)
    SV *descriptor_obj
  CODE:
    le_timer_descriptor_t *descriptor
        = le_timer_descriptor_from_sv(descriptor_obj);
    if (descriptor) {
        if (descriptor->callback_cv)
            SvREFCNT_dec(descriptor->callback_cv);
        free(descriptor);
        sv_setiv(SvRV(descriptor_obj), 0);
    }

MODULE = Linux::Event::Loop    PACKAGE = Linux::Event::Kernel::Timer
PROTOTYPES: DISABLE

SV *
_new_native(CLASS, descriptor_obj, absolute, first_seconds, interval_seconds, data)
    const char *CLASS
    SV *descriptor_obj
    int absolute
    double first_seconds
    double interval_seconds
    SV *data
  CODE:
    le_timer_t *timer;
    le_timer_descriptor_t *descriptor
        = le_timer_descriptor_from_sv(descriptor_obj);
    if (!descriptor || !descriptor->callback_cv)
        croak("Timer descriptor is closed");
    timer = (le_timer_t *)calloc(1, sizeof(*timer));
    if (!timer) croak("calloc Timer failed");
    timer->heap_index = LE_HEAP_NONE;
    timer->state = LE_TIMER_UNATTACHED;
    timer->descriptor = descriptor;
    timer->descriptor_sv = newSVsv(descriptor_obj);
    timer->data_sv = SvOK(data) ? newSVsv(data) : NULL;
    timer->initial_absolute = absolute ? 1 : 0;
    timer->initial_ns = le_seconds_to_ns(
        first_seconds, 1, absolute ? "at" : "after");
    timer->interval_ns = interval_seconds == 0.0
        ? 0 : le_seconds_to_ns(interval_seconds, 0, "every");
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)timer);
  OUTPUT:
    RETVAL

void
DESTROY(timer_obj)
    SV *timer_obj
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    if (timer) {
        if (timer->state == LE_TIMER_ACTIVE
            || timer->state == LE_TIMER_FIRING)
            le_timer_cancel_native(timer);
        if (timer->descriptor_sv || timer->data_sv || timer->loop_sv)
            le_timer_release_refs(timer);
        free(timer);
        sv_setiv(SvRV(timer_obj), 0);
    }

SV *
_attach_to_loop(timer_obj, loop_obj)
    SV *timer_obj
    SV *loop_obj
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    le_loop_t *loop = le_loop_from_sv(loop_obj);
    le_loop_assert_owner(loop, "add");
    le_timer_activate(timer_obj, timer, loop_obj, loop);
    RETVAL = newSVsv(timer_obj);
  OUTPUT:
    RETVAL

SV *
_reschedule_native(timer_obj, absolute, first_seconds, interval_seconds)
    SV *timer_obj
    int absolute
    double first_seconds
    double interval_seconds
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    unsigned long long first_ns;
    unsigned long long interval_ns;
    if (timer->loop)
        le_loop_assert_owner(timer->loop, "reschedule");
    first_ns = le_seconds_to_ns(
        first_seconds, 1, absolute ? "at" : "after");
    interval_ns = interval_seconds == 0.0
        ? 0 : le_seconds_to_ns(interval_seconds, 0, "every");
    le_timer_reschedule_native(timer, absolute, first_ns, interval_ns);
    RETVAL = newSVsv(timer_obj);
  OUTPUT:
    RETVAL

SV *
cancel(timer_obj)
    SV *timer_obj
  PREINIT:
    le_timer_t *timer;
  CODE:
    timer = le_timer_from_sv(timer_obj);
    if (timer->loop)
        le_loop_assert_owner(timer->loop, "cancel");
    le_timer_cancel_native(timer);
    RETVAL = newSVsv(timer_obj);
  OUTPUT:
    RETVAL

SV *
data(timer_obj, ...)
    SV *timer_obj
  PREINIT:
    le_timer_t *timer;
  CODE:
    timer = le_timer_from_sv(timer_obj);
    if (items > 2) croak("data() accepts at most one value");
    if (items == 2) {
        if (timer->state == LE_TIMER_CANCELLED
            || timer->state == LE_TIMER_EXPIRED)
            croak("data(): Timer is terminal");
        if (timer->data_sv) SvREFCNT_dec(timer->data_sv);
        timer->data_sv = SvOK(ST(1)) ? newSVsv(ST(1)) : NULL;
    }
    RETVAL = timer->data_sv ? newSVsv(timer->data_sv) : newSV(0);
  OUTPUT:
    RETVAL

SV *
loop(timer_obj)
    SV *timer_obj
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    RETVAL = timer->loop_sv && SvOK(timer->loop_sv)
        ? newSVsv(timer->loop_sv) : newSV(0);
  OUTPUT:
    RETVAL

SV *
deadline(timer_obj)
    SV *timer_obj
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    if (timer->state == LE_TIMER_ACTIVE
        || timer->state == LE_TIMER_FIRING)
        RETVAL = newSVnv((NV)timer->deadline_ns / 1000000000.0);
    else if (timer->state == LE_TIMER_UNATTACHED
        && timer->initial_absolute)
        RETVAL = newSVnv((NV)timer->initial_ns / 1000000000.0);
    else
        RETVAL = newSV(0);
  OUTPUT:
    RETVAL

double
interval(timer_obj)
    SV *timer_obj
  CODE:
    RETVAL = (double)le_timer_from_sv(timer_obj)->interval_ns
        / 1000000000.0;
  OUTPUT:
    RETVAL

UV
expirations(timer_obj)
    SV *timer_obj
  CODE:
    RETVAL = (UV)le_timer_from_sv(timer_obj)->expirations;
  OUTPUT:
    RETVAL

SV *
state(timer_obj)
    SV *timer_obj
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    const char *name = "unattached";
    if (timer->state == LE_TIMER_ACTIVE || timer->state == LE_TIMER_FIRING)
        name = "active";
    else if (timer->state == LE_TIMER_EXPIRED)
        name = "expired";
    else if (timer->state == LE_TIMER_CANCELLED)
        name = "cancelled";
    RETVAL = newSVpv(name, 0);
  OUTPUT:
    RETVAL

int
is_active(timer_obj)
    SV *timer_obj
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    RETVAL = timer->state == LE_TIMER_ACTIVE
        || timer->state == LE_TIMER_FIRING;
  OUTPUT:
    RETVAL

int
is_terminal(timer_obj)
    SV *timer_obj
  CODE:
    le_timer_t *timer = le_timer_from_sv(timer_obj);
    RETVAL = timer->state == LE_TIMER_EXPIRED
        || timer->state == LE_TIMER_CANCELLED;
  OUTPUT:
    RETVAL

double
now(CLASS)
    const char *CLASS
  CODE:
    PERL_UNUSED_ARG(CLASS);
    RETVAL = (double)le_now_ns() / 1000000000.0;
  OUTPUT:
    RETVAL

MODULE = Linux::Event::Loop    PACKAGE = Linux::Event::_Registration
PROTOTYPES: DISABLE

void
DESTROY(w_obj)
    SV *w_obj
  CODE:
    le_registration_t *registration = le_registration_from_sv(w_obj);
    sv_setiv(SvRV(w_obj), 0);
    le_registration_release(registration);

int
fd(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    RETVAL = w ? w->fd : -1;
  OUTPUT:
    RETVAL

SV *
fh(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    RETVAL = w && w->fh_sv ? newSVsv(w->fh_sv) : newSV(0);
  OUTPUT:
    RETVAL

SV *
data(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    RETVAL = w && w->data_sv ? newSVsv(w->data_sv) : newSV(0);
  OUTPUT:
    RETVAL

int
lean(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    RETVAL = w ? w->lean : 0;
  OUTPUT:
    RETVAL

SV *
loop(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    RETVAL = w && w->loop_sv ? newSVsv(w->loop_sv) : newSV(0);
  OUTPUT:
    RETVAL

void
cancel(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    if (w && w->active && w->loop) {
        le_loop_t *loop = w->loop; int fd = w->fd;
        if (fd >= 0 && (size_t)fd < loop->reg_cap && loop->registry[fd] == w) {
            le_epoll_ctl_timed(loop, EPOLL_CTL_DEL, fd, NULL);
            loop->registry[fd] = NULL;
        }
        w->active = 0;
        le_watcher_recycle_or_destroy(w);
    }

void
enable_read(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    if (w && w->active && (!(w->mask & EPOLLIN) || (w->flags & EPOLLONESHOT))) { w->mask |= EPOLLIN; if (le_apply_mask(w) < 0) croak("enable_read epoll_ctl MOD failed: %s", strerror(errno)); }

void
disable_read(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    if (w && w->active && (w->mask & EPOLLIN)) { w->mask &= ~EPOLLIN; if (le_apply_mask(w) < 0) croak("disable_read epoll_ctl MOD failed: %s", strerror(errno)); }

void
enable_write(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    if (w && w->active && (!(w->mask & EPOLLOUT) || (w->flags & EPOLLONESHOT))) { w->mask |= EPOLLOUT; if (le_apply_mask(w) < 0) croak("enable_write epoll_ctl MOD failed: %s", strerror(errno)); }

void
disable_write(w_obj)
    SV *w_obj
  CODE:
    le_watcher_t *w = le_watcher_from_sv(w_obj);
    if (w && w->active && (w->mask & EPOLLOUT)) { w->mask &= ~EPOLLOUT; if (le_apply_mask(w) < 0) croak("disable_write epoll_ctl MOD failed: %s", strerror(errno)); }
