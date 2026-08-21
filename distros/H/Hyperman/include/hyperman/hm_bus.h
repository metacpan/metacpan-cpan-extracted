/* hm_bus.h - a cross-worker message bus on a fork-shared ring.
 *
 * WHAT THIS EXISTS FOR.
 *
 * Punk::WebSocket::Room says it in its own documentation: a room is per
 * worker, so under `workers => 4` a broadcast reaches roughly a quarter of
 * the people in it. The call succeeds, the return value is a plausible
 * number, and nobody is told. That is not a missing feature, it is a wrong
 * answer that nothing reports.
 *
 * This is the substrate that fixes it: one ring in shared memory, mapped by
 * the supervisor BEFORE it forks, so every worker publishes into and reads
 * from the same copy. No Redis, no hub process, no new prerequisite.
 *
 * TWO DELIVERY MODES, ONE MECHANISM.
 *
 * A message is published once. What differs is WHERE THE CURSOR LIVES:
 *
 *   - a FANOUT subscriber keeps its cursor in its own process, so every
 *     subscriber reads every message. This is what a chat room wants.
 *
 *   - a QUEUE GROUP keeps one cursor in the arena, advanced with an atomic
 *     add, so exactly one member gets each message. This is load-balanced
 *     work distribution, and the balancing falls out of the claim: a worker
 *     that is busy is not in the drain loop, is not claiming, and the free
 *     workers take the traffic. There is no scheduler and nothing to tune.
 *
 * The claim races. Every worker wakes on a publish and only one wins each
 * slot; a lost race costs one compare-and-swap and a retry - measured at 20ns
 * with two processes and 167ns with eight, against a message that is about to
 * be written to a socket. That is why waking everybody is affordable.
 *
 * It is a CAS and not a fetch-add, and the difference is not performance. A
 * fetch-add cannot be taken back: a claimer that added and then found it had
 * overshot the last published sequence has already moved the SHARED cursor
 * past sequences nobody has written yet, and every one of those messages is
 * then skipped forever with no gap counted, because nothing noticed. The
 * phase-0 spike printed that bug in its own output - `final cursor 1000002`
 * for two processes claiming a million - and it went unread until a forked
 * test lost a message an hour later.
 *
 * QUEUE GROUPS ARE AT-MOST-ONCE, AND THAT IS NOT A BUG TO BE FIXED LATER.
 * A worker that claims a slot and then dies loses that message. If losing it
 * matters, the answer is Punk::Queue, which is durable and at-least-once and
 * already exists. This is the fast lossy one. Both are right for different
 * jobs and choosing wrongly is a data-loss bug, so the documentation says so
 * beside the feature rather than in a footnote.
 *
 * OVERFLOW: BOUNDED, DROP-OLDEST, COUNTED.
 *
 * A slow reader gets lapped. Every part of the response is deliberate:
 * bounded, because an unbounded buffer in front of a stalled worker is a
 * memory leak with a schedule; drop-OLDEST, because the recent messages are
 * the ones anybody wants; and COUNTED, because a silently short chat room is
 * indistinguishable from a quiet one. A gap with a number beside it is a
 * diagnosis; a gap without one is a mystery. The job is not "do not lose
 * messages", it is DO NOT BECOME THE PROBLEM.
 *
 * WHY FIXED SLOTS.
 *
 * Measured against a length-prefixed byte ring (plan_punk_bus/phase-0-ring.md
 * has the numbers). Publishing is ~3ns slower for a small message and FASTER
 * for a large one; draining is a wash. The decision is the claim: with fixed
 * slots the group's cursor IS the slot address, so a claim is one atomic add.
 * A byte ring has no such integer and would need a second index of message
 * offsets kept in lockstep with the write cursor, under concurrent
 * publishers, for nothing.
 *
 * Everything here FAILS OPEN. With no arena - Windows, no atomics, or simply
 * not running under Hyperman - publish reports that it was local only and the
 * caller delivers to its own subscribers. A test script and a single-process
 * dev server keep working, which is the same answer deny_check and
 * ratelimit_hit give.
 */

#ifndef HM_BUS_H
#define HM_BUS_H

#ifndef _WIN32
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <sched.h>
#endif
#include <string.h>
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>

#include "hm_atomic.h"

/* Give the CPU back, so a DESCHEDULED publisher can run.
 *
 * This is not a shorter spin, it is a different kind of wait, and the
 * difference is the whole point. A claimer waiting on a slot is waiting for
 * one specific process to finish two memcpys. If that publisher holds no CPU
 * - four spinning claimers on a two-core smoker, or any oversubscribed box -
 * then spinning is not merely wasteful, it is the thing PREVENTING the
 * progress it waits for. Only yielding can end that wait. */
#ifdef _WIN32
#  define hm_bus_yield() SwitchToThread()
#else
#  define hm_bus_yield() sched_yield()
#endif

#if !defined(MAP_ANONYMOUS) && defined(MAP_ANON)
#  define MAP_ANONYMOUS MAP_ANON
#endif

#define HM_BUS_HAVE_ATOMICS HM_HAVE_ATOMICS

#define HM_BUS_MAGIC      0x484D4255u   /* "HMBU" */

/* The defaults come from the phase-0 measurements, and the shape of the ring
 * is chosen for DEPTH over message size. Mapped memory is not resident until
 * written - 16MB mapped and never used costs 1MB - but after one full wrap
 * every page has been touched and a long-running server always gets there. So
 * the steady-state cost is the whole mapping, and 4MB is what that should be.
 *
 * At 4MB the shape is free, and 2048 x 2KB buys 2048 messages of headroom
 * before a slow worker is lapped, with 2KB carrying a chat message, a
 * presence update, an SSE event or an invalidation key with room over.
 *
 * bus_slot_size raises the ceiling for bigger messages; bus_slots raises the
 * headroom for burstier ones. */
#define HM_BUS_SLOTS      2048
#define HM_BUS_SLOT_SIZE  2048
#define HM_BUS_GROUPS     64            /* named queue groups */
#define HM_BUS_NAMELEN    64
#define HM_BUS_CLAIM_SPIN 10000    /* bounded wait for a slot being written */
/* ... then yields, because the spin cannot outlast a descheduled publisher.
 * 10000 yields is a long time to a scheduler and still finite, so a publisher
 * killed between reserving a sequence and writing it costs one gap rather
 * than a wedged pool. */
#define HM_BUS_CLAIM_YIELD 10000
#define HM_BUS_WAKERS     256      /* one per worker; the pool is smaller */
#define HM_BUS_SUBS       64       /* registrations per process */

/* What a read of one slot found.
 *
 * PENDING is the distinction that matters, and getting it wrong is expensive:
 * a publisher zeroes a slot's sequence before it writes the body, so a reader
 * that arrives at that exact moment sees a sequence which is not the one it
 * wanted. Treating that as "lapped" counts a gap and skips forever a message
 * that was merely still being written - which at four readers spinning against
 * one publisher lost ten percent of a chat room and blamed the ring for it.
 *
 * A slot whose sequence is BELOW the one wanted has not been written yet:
 * wait. Only a sequence ABOVE it means the ring has moved past. */
#define HM_BUS_READ_OK       1
#define HM_BUS_READ_PENDING  0
#define HM_BUS_READ_LAPPED (-1)

/* publish outcomes */
#define HM_BUS_OK        0    /* on the ring, visible to the pool */
#define HM_BUS_LOCAL     1    /* no arena: the caller's own subscribers only */
#define HM_BUS_OVERSIZE (-1)  /* refused; never truncated */

/* A slot. `seq` is written LAST, with a release store, and is what makes a
 * reader able to tell a slot it was handed from one that was overwritten
 * while it read. A slot whose seq is not the sequence the reader wanted has
 * been lapped. */
typedef struct {
    volatile uint64_t seq;
    uint32_t tlen, plen;
    char     bytes[1];         /* topic then payload, slot_size total */
} hm_bus_slot;

/* A named queue group. `cursor` is the shared one - the whole difference
 * between the two delivery modes.
 *
 * A group is bound to a TOPIC, and that is not decoration. The cursor is
 * consumed by whatever it advances past, so a group that claimed every topic
 * on the ring would swallow other people's messages: a thumbnail worker would
 * take a chat broadcast, mark it handled, and the room would never see it.
 * A slot whose topic does not match is stepped over without being delivered -
 * cheap, because the group's cursor is nobody else's. */
typedef struct {
    volatile uint64_t cursor;  /* next sequence to claim */
    volatile uint64_t gaps;    /* claims that found a lapped slot */
    volatile uint32_t state;   /* 0 empty, 1 live */
    char     name[HM_BUS_NAMELEN];
    char     topic[HM_BUS_NAMELEN];
    uint32_t tlen;
} hm_bus_group;

/* How a worker gets TOLD, rather than finding out when it next looks.
 *
 * Without this a reader polls, and the interval is the delivery latency: a
 * chat message sits in the ring until somebody wakes up anyway. With it a
 * publish pokes every other worker's descriptor and the loop returns from
 * epoll with the message already there.
 *
 * The descriptors are created BEFORE THE FORK, which is the only time it can
 * be done: a pipe made in a worker is invisible to its siblings, and the bug
 * that produces is "delivery works to some workers". Being inherited, the fd
 * NUMBERS are the same in every process, so they can live in shared memory
 * as plain integers.
 *
 * `pending` is the coalescing flag, and it is not an optimisation. A burst of
 * a thousand publishes must not become a thousand writes to each of N
 * descriptors - the bus would become its own thundering herd, precisely under
 * the load where that hurts. A publisher only writes to a worker whose flag it
 * won the right to set, and the worker clears it when it drains. */
typedef struct {
    volatile uint32_t pending;   /* 1 = a poke is already in flight */
    volatile uint32_t live;      /* 0 = this slot is unused */
    int rfd, wfd;
} hm_bus_waker;

typedef struct hm_bus_arena {
    uint32_t magic;
    uint32_t slots, slot_size, ngroups;
    volatile uint64_t seq;             /* next sequence to be published */
    volatile uint64_t published;       /* total, for the stats */
    volatile unsigned char locks[HM_LOCK_STRIPES];
    hm_bus_group *groups;              /* into the same mapping */
    char         *data;                /* the slots, in the same mapping */
    hm_bus_waker  wakers[HM_BUS_WAKERS];
    volatile uint32_t nwakers;
} hm_bus_arena;

/* Process-global. NULL = no arena = fail open. Set once, before the fork, so
 * every worker inherits the same pointer at the same address. */
static hm_bus_arena *hm_bus = NULL;

/* A per-process scratch buffer. A reader copies a slot out before it hands it
 * to a callback, because a publisher may overwrite the slot while the
 * callback runs - see hm_bus_read_slot. Sized to slot_size at init. */
static char  *hm_bus_scratch = NULL;
static size_t hm_bus_scratch_sz = 0;

static int hm_bus_arena_live(void) { return hm_bus != NULL; }

/* Which waker slot is THIS process. -1 in the supervisor and in anything that
 * never registered, which is correct: a publisher does not poke itself, it
 * drains inline. */
static int hm_bus_self = -1;

#define HM_BUS_SLOT_AT(a, i) \
    ((hm_bus_slot *)((a)->data + (size_t)((i) % (a)->slots) * (a)->slot_size))

/* The payload a callback is handed. Copied out of the ring, so it stays valid
 * for as long as the callback runs. */
typedef void (*hm_bus_cb)(void *ud, uint64_t seq,
                          const char *topic, uint32_t tlen,
                          const char *payload, uint32_t plen);

/* ---- lifecycle ----------------------------------------------------------- */

/* Allocate the arena. MUST run in the supervisor before it forks, so the
 * mapping and the pointer to it are inherited by every worker. Idempotent; a
 * zero argument takes the default. On any failure hm_bus stays NULL and
 * everything below takes its fail-open path. */
static void hm_bus_arena_init(uint32_t slots, uint32_t slot_size,
                              uint32_t ngroups) {
#if HM_BUS_HAVE_ATOMICS
    size_t hdr, gsz, dsz, total;
    void *m;
    hm_bus_arena *a;

    if (hm_bus) return;
    if (!slots)     slots     = HM_BUS_SLOTS;
    if (!slot_size) slot_size = HM_BUS_SLOT_SIZE;
    if (!ngroups)   ngroups   = HM_BUS_GROUPS;

    /* a slot has to hold its own header plus something */
    if (slot_size < sizeof(hm_bus_slot) + 16) slot_size = HM_BUS_SLOT_SIZE;

    hdr   = sizeof(hm_bus_arena);
    gsz   = (size_t)ngroups * sizeof(hm_bus_group);
    dsz   = (size_t)slots * slot_size;
    total = hdr + gsz + dsz;

    m = mmap(NULL, total, PROT_READ | PROT_WRITE,
             MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (m == MAP_FAILED) return;               /* fail open */
    memset(m, 0, hdr + gsz);                   /* the slots need no zeroing:
                                                * a slot is only believed when
                                                * its seq matches, and zeroed
                                                * seq means "never written" */
    a = (hm_bus_arena *)m;
    a->magic     = HM_BUS_MAGIC;
    a->slots     = slots;
    a->slot_size = slot_size;
    a->ngroups   = ngroups;
    /* Sequence 0 means "never written", so publishing starts at 1 - and every
     * cursor starts there too. A cursor left at 0 reads the zeroed slot 0,
     * whose sequence is 0 and therefore MATCHES, and hands back a phantom
     * message with a zero-length topic. It delivers to nobody, so it is
     * invisible except as an off-by-one in the count. */
    a->seq       = 1;
    a->groups    = (hm_bus_group *)((char *)m + hdr);
    a->data      = (char *)m + hdr + gsz;

    hm_bus_scratch = (char *)malloc(slot_size);
    if (!hm_bus_scratch) { munmap(m, total); return; }
    hm_bus_scratch_sz = slot_size;

    hm_bus = a;
#else
    (void)slots; (void)slot_size; (void)ngroups;
#endif
}

/* The scratch buffer is per-process and malloc'd, so a worker that inherited
 * the parent's needs its own only if it was never allocated - it was, before
 * the fork, and a forked child gets a private copy-on-write copy. Nothing to
 * do after a fork for the buffer.
 *
 * A CURSOR, though, must not survive a fork: a worker that inherited the
 * parent's would replay what the parent already delivered or skip what it has
 * not. Cursors live in the caller, and the caller resets them from
 * on_worker_start. hm_bus_seq() is what to reset them TO. */
static uint64_t hm_bus_seq(void) {
#if HM_BUS_HAVE_ATOMICS
    if (!hm_bus) return 0;
    return hm_at_load64_acq(&hm_bus->seq);
#else
    return 0;
#endif
}

/* ---- the wakeup ---------------------------------------------------------- */

#if HM_BUS_HAVE_ATOMICS
/* Make `n` wakers. MUST run in the supervisor, before it forks: a descriptor
 * created in a worker is invisible to its siblings, and the failure that
 * produces is the worst kind - delivery that works to SOME workers.
 *
 * A pipe rather than an eventfd, deliberately. eventfd is Linux-only and the
 * saving is one descriptor per worker; a pipe is the same three lines
 * everywhere this runs, and the wakeup path is one byte either way. */
static void hm_bus_wakers_init(uint32_t n) {
    hm_bus_arena *a = hm_bus;
    uint32_t i;
    if (!a || a->nwakers) return;
    if (n > HM_BUS_WAKERS) n = HM_BUS_WAKERS;
    for (i = 0; i < n; i++) {
        int fd[2];
        if (pipe(fd) != 0) break;
        /* Non-blocking on BOTH ends. A worker that has stopped draining fills
         * its pipe, and a publisher that blocked on it would have been taken
         * down by the slowest consumer in the pool. The ring carries the data;
         * the poke is only a nudge, and a lost nudge costs latency, not a
         * message.
         *
         * Done here with fcntl rather than through hm_core.h's helper, because
         * this header knows nothing about the server and should not start. */
        (void)fcntl(fd[0], F_SETFL, fcntl(fd[0], F_GETFL, 0) | O_NONBLOCK);
        (void)fcntl(fd[1], F_SETFL, fcntl(fd[1], F_GETFL, 0) | O_NONBLOCK);
        a->wakers[i].rfd = fd[0];
        a->wakers[i].wfd = fd[1];
        a->wakers[i].pending = 0;
        hm_at_store32_rel(&a->wakers[i].live, 1);
    }
    a->nwakers = i;
}

/* Claim a waker slot for this process and return its read end, or -1.
 * Called from a worker after the fork, which is when it knows it is one.
 *
 * The slot is EMPTIED as it is taken, and that is not tidiness. The
 * descriptors exist from before the fork, so anything published in the
 * supervisor - loading config, warming a cache - has already poked every
 * slot, including the ones no process owned yet. A worker inheriting those
 * bytes returns from its first select immediately, with nothing on the ring
 * for it, and every measurement of "did the wakeup work" is then measuring a
 * stale byte instead. The bug hides itself by passing the test. */
static int hm_bus_waker_take(int widx) {
    hm_bus_arena *a = hm_bus;
    char buf[64];
    if (!a || widx < 0 || (uint32_t)widx >= a->nwakers) return -1;
    hm_bus_self = widx;
    while (read(a->wakers[widx].rfd, buf, sizeof buf) > 0) ;
    hm_at_store32_rel(&a->wakers[widx].pending, 0);
    return a->wakers[widx].rfd;
}

/* This process's read end, or -1 if it never took a slot. */
static int hm_bus_waker_fd(void) {
    hm_bus_arena *a = hm_bus;
    if (!a || hm_bus_self < 0) return -1;
    return a->wakers[hm_bus_self].rfd;
}

/* Drain the poke. One byte or a hundred mean the same thing - there is
 * something on the ring - so the read is only to stop the descriptor staying
 * readable.
 *
 * THE ORDER OF THE TWO LINES BELOW IS THE WHOLE CORRECTNESS OF THE WAKEUP.
 *
 * Empty the pipe FIRST, then clear the flag, and only then let the caller
 * read the ring. The flag says "a poke is already on its way", so it may only
 * go back to zero once every byte it stands for has been consumed. Clearing
 * it first opens a window in which a publisher sees a clear flag, sets it,
 * writes its byte - and this read loop, still running, swallows that byte.
 * The flag is then set with an empty pipe, and since only the process that
 * flips it from zero writes anything, NO publisher ever pokes this worker
 * again. It goes permanently deaf to the bus and only sees a message again if
 * it publishes one itself and drains inline.
 *
 * That is not a theoretical window. A publisher that sends two messages in a
 * row - a room forwarding to two topics - aims its second poke squarely at
 * the first one's wakeup, which is where the swallow happens.
 *
 * Clearing before the ring is read is still required, and for the opposite
 * reason: a publish that lands while the caller is draining must be able to
 * set the flag and poke afresh rather than being folded into a wakeup that
 * has already looked. Nothing is lost in the gap between the read and the
 * clear either - a publisher there skips its write, but it has already
 * committed to the ring, and the caller reads the ring after the clear. */
static void hm_bus_waker_drained(void) {
    hm_bus_arena *a = hm_bus;
    char buf[64];
    int fd;
    if (!a || hm_bus_self < 0) return;
    fd = a->wakers[hm_bus_self].rfd;
    while (read(fd, buf, sizeof buf) > 0) ;
    hm_at_store32_rel(&a->wakers[hm_bus_self].pending, 0);
}

/* Poke everybody except the publisher, who drains inline. */
static void hm_bus_poke(void) {
    hm_bus_arena *a = hm_bus;
    uint32_t i, n;
    if (!a) return;
    n = a->nwakers;
    for (i = 0; i < n; i++) {
        hm_bus_waker *w = &a->wakers[i];
        if ((int)i == hm_bus_self) continue;
        if (!hm_at_load32_acq(&w->live)) continue;
        /* Only the caller that flips the flag writes. Everybody else has
         * nothing to do, which is what keeps a burst of a thousand publishes
         * from becoming a thousand writes per worker. */
        if (!hm_at_test_and_set32(&w->pending)) continue;
        {
            char one = 1;
            ssize_t r = write(w->wfd, &one, 1);
            (void)r;    /* EAGAIN means the pipe is full, which means a poke
                         * is already waiting to be noticed. Nothing to fix. */
        }
    }
}
#endif /* HM_BUS_HAVE_ATOMICS */

/* ---- publishing ---------------------------------------------------------- */

/* Put a message on the ring.
 *
 * Returns HM_BUS_OK, HM_BUS_LOCAL (no arena - the caller delivers to its own
 * subscribers and nothing else will see it), or HM_BUS_OVERSIZE.
 *
 * An oversize message is REFUSED, never truncated. A truncated WebSocket
 * frame is a protocol violation delivered to every member of a room, which is
 * a worse outcome than the publish failing where the caller can see it. */
static int hm_bus_publish(const char *topic, uint32_t tlen,
                          const char *payload, uint32_t plen) {
#if HM_BUS_HAVE_ATOMICS
    hm_bus_arena *a = hm_bus;
    uint64_t s;
    hm_bus_slot *sl;
    size_t need;

    if (!a) return HM_BUS_LOCAL;
    need = (sizeof(hm_bus_slot) - 1) + tlen + plen;
    if (need > a->slot_size) return HM_BUS_OVERSIZE;

    s  = hm_at_fetch_add64(&a->seq, 1);
    sl = HM_BUS_SLOT_AT(a, s);

    /* Invalidate the slot before touching its body, so a reader that is
     * mid-copy sees a sequence that matches neither what it wanted nor what
     * is arriving, and discards rather than returning half of each. */
    hm_at_store64_rel(&sl->seq, 0);

    sl->tlen = tlen;
    sl->plen = plen;
    if (tlen) memcpy(sl->bytes, topic, tlen);
    if (plen) memcpy(sl->bytes + tlen, payload, plen);

    hm_at_store64_rel(&sl->seq, s);        /* published: written LAST */
    hm_at_fetch_add64(&a->published, 1);
    hm_bus_poke();                         /* ... and tell everybody else */
    return HM_BUS_OK;
#else
    (void)topic; (void)tlen; (void)payload; (void)plen;
    return HM_BUS_LOCAL;
#endif
}

/* ---- reading ------------------------------------------------------------- */

#if HM_BUS_HAVE_ATOMICS
/* Copy the slot holding `want` into the scratch buffer, or say it was lapped.
 *
 * This is a seqlock read and the ORDER MATTERS. Check the sequence, copy,
 * then check it again: a publisher that lapped the slot mid-copy would
 * otherwise hand the caller the first half of one message and the second half
 * of another, which is worse than the drop it is meant to be. A bus that
 * drops under pressure is doing its job; one that fabricates a message is
 * not. */
static int hm_bus_read_slot(hm_bus_arena *a, uint64_t want,
                            uint32_t *tlen, uint32_t *plen) {
    hm_bus_slot *sl = HM_BUS_SLOT_AT(a, want);
    uint64_t got;
    uint32_t tl, pl;
    size_t body;

    got = hm_at_load64_acq(&sl->seq);
    if (got != want)
        return got > want ? HM_BUS_READ_LAPPED : HM_BUS_READ_PENDING;

    tl = sl->tlen;
    pl = sl->plen;
    body = (size_t)tl + pl;
    if (body > hm_bus_scratch_sz) return HM_BUS_READ_LAPPED;  /* cannot be ours */

    if (body) memcpy(hm_bus_scratch, sl->bytes, body);

    /* Re-check AFTER copying. A publisher that lapped this slot mid-copy would
     * otherwise hand back the first half of one message and the second half of
     * another, which is worse than the drop it is meant to be: a bus that
     * drops under pressure is doing its job, one that fabricates a message is
     * not. */
    got = hm_at_load64_acq(&sl->seq);
    if (got != want)
        return got > want ? HM_BUS_READ_LAPPED : HM_BUS_READ_PENDING;

    *tlen = tl;
    *plen = pl;
    return HM_BUS_READ_OK;
}
#endif

/* Drain everything a fanout subscriber has not seen.
 *
 * `cursor` is the caller's own, in the caller's own process - that is what
 * makes this fanout rather than a claim. It is advanced past what was
 * delivered AND past what was lost, because a cursor that stalls on a lapped
 * slot never moves again.
 *
 * `gaps` is incremented by the number of messages this subscriber missed.
 * Reporting it is not optional: it is the difference between a diagnosis and
 * a mystery.
 *
 * Returns how many were delivered. */
static long hm_bus_drain(uint64_t *cursor, uint64_t *gaps,
                         hm_bus_cb cb, void *ud) {
#if HM_BUS_HAVE_ATOMICS
    hm_bus_arena *a = hm_bus;
    uint64_t end;
    long n = 0;

    if (!a || !cursor) return 0;
    end = hm_at_load64_acq(&a->seq);

    /* A cursor from before this process existed, or one left behind by a long
     * stall, may point at a sequence the ring wrapped past long ago. Skipping
     * to the oldest slot still held is the drop-oldest rule applied in one
     * step, and it counts every message it skipped. */
    if (end > (uint64_t)a->slots && *cursor < end - a->slots) {
        uint64_t oldest = end - a->slots;
        if (gaps) *gaps += oldest - *cursor;
        *cursor = oldest;
    }

    while (*cursor < end) {
        uint32_t tl = 0, pl = 0;
        int r = hm_bus_read_slot(a, *cursor, &tl, &pl);

        /* Still being written. Leave the cursor where it is and come back:
         * skipping here would count a gap for a message that is about to
         * arrive, which is how a reader loses ten percent of a busy room and
         * blames the ring. */
        if (r == HM_BUS_READ_PENDING) break;

        if (r == HM_BUS_READ_OK) {
            if (cb) cb(ud, *cursor, hm_bus_scratch, tl,
                       hm_bus_scratch + tl, pl);
            n++;
        }
        else if (gaps) (*gaps)++;      /* genuinely overwritten */
        (*cursor)++;
    }
    return n;
#else
    (void)cursor; (void)gaps; (void)cb; (void)ud;
    return 0;
#endif
}

/* ---- queue groups -------------------------------------------------------- */

/* Find a group by name, creating it if there is room. Returns its index, or
 * -1 when the table is full or there is no arena.
 *
 * A new group starts at the CURRENT sequence, not at zero: joining a group
 * means "from now on", and replaying the whole ring to a worker that just
 * started is a surprise nobody asked for. */
static int hm_bus_group_of(const char *topic, uint32_t tlen,
                           const char *name, uint32_t nlen) {
#if HM_BUS_HAVE_ATOMICS
    hm_bus_arena *a = hm_bus;
    uint64_t h;
    uint32_t i, start;

    if (!a || !name || !nlen || nlen >= HM_BUS_NAMELEN) return -1;
    if (!topic || !tlen || tlen >= HM_BUS_NAMELEN) return -1;

    /* The identity is the PAIR. Two groups on different topics may share a
     * name without sharing a cursor, and the same name on the same topic is
     * the same group whichever worker asks. */
    h     = hm_at_fnv(name, nlen) ^ (hm_at_fnv(topic, tlen) * 1099511628211ULL);
    start = (uint32_t)(h % a->ngroups);

#define HM_BUS_GROUP_IS(g) \
    ((g)->tlen == tlen && !memcmp((g)->topic, topic, tlen) \
     && !strncmp((g)->name, name, nlen) && (g)->name[nlen] == '\0')

    /* a lock-free look first: the common case is a group that already exists */
    for (i = 0; i < a->ngroups; i++) {
        uint32_t idx = (start + i) % a->ngroups;
        hm_bus_group *g = &a->groups[idx];
        if (!hm_at_load32_acq(&g->state)) break;      /* empty: not present */
        if (HM_BUS_GROUP_IS(g)) return (int)idx;
    }

    if (!hm_at_lock(a->locks, h)) return -1;          /* fail open */
    for (i = 0; i < a->ngroups; i++) {
        uint32_t idx = (start + i) % a->ngroups;
        hm_bus_group *g = &a->groups[idx];
        if (hm_at_load32_acq(&g->state)) {
            if (HM_BUS_GROUP_IS(g)) { hm_at_unlock(a->locks, h); return (int)idx; }
            continue;
        }
        memcpy(g->name, name, nlen);
        g->name[nlen] = '\0';
        memcpy(g->topic, topic, tlen);
        g->tlen   = tlen;
        g->cursor = hm_at_load64_acq(&a->seq);   /* from now on, not from 0 */
        g->gaps   = 0;
        hm_at_store32_rel(&g->state, 1);
        hm_at_unlock(a->locks, h);
        return (int)idx;
    }
    hm_at_unlock(a->locks, h);
    return -1;                                        /* table full */
#undef HM_BUS_GROUP_IS
#else
    (void)topic; (void)tlen; (void)name; (void)nlen;
    return -1;
#endif
}

/* Claim and handle whatever this group has not been handled by anybody.
 *
 * THE ONE ATOMIC THAT MAKES IT WORK: fetch-add on the group's shared cursor
 * hands each sequence to exactly one caller, in one process, across the whole
 * pool. Everything else here is bookkeeping.
 *
 * Balancing is not implemented, it is a consequence: a busy worker is not in
 * this loop, so it does not claim, so the free workers take the traffic.
 *
 * Returns how many this caller handled. */
static long hm_bus_claim(int gidx, hm_bus_cb cb, void *ud) {
#if HM_BUS_HAVE_ATOMICS
    hm_bus_arena *a = hm_bus;
    hm_bus_group *g;
    uint64_t end;
    long n = 0;

    if (!a || gidx < 0 || (uint32_t)gidx >= a->ngroups) return 0;
    g   = &a->groups[gidx];
    end = hm_at_load64_acq(&a->seq);

    for (;;) {
        uint64_t mine = hm_at_load64_acq(&g->cursor);
        uint32_t tl = 0, pl = 0;

        /* CAS, NOT fetch-add.
         *
         * A fetch-add cannot be taken back. A claimer that added and then
         * found it had overshot `end` would already have moved the SHARED
         * cursor past sequences nobody had published yet - and every one of
         * those messages would then be skipped forever, with no gap counted,
         * because nothing had noticed. That is silent loss, which is the one
         * failure this design promises not to have.
         *
         * The CAS advances only when this caller both wins the race and is
         * still inside what has actually been published. Losing costs a
         * retry. */
        if (mine >= end) break;
        if (!hm_at_cas64(&g->cursor, mine, mine + 1)) continue;

        {
            /* This caller now OWNS sequence `mine` - the CAS said so, and no
             * other member will ever look at it. So a slot that is still being
             * written has to be waited for rather than skipped: skipping would
             * discard a message nobody else can pick up. The wait is bounded,
             * because the publisher is doing one memcpy and a store, and a
             * publisher that died mid-write must not wedge the pool. */
            int r, spin = 0, yields = 0;

            while ((r = hm_bus_read_slot(a, mine, &tl, &pl))
                       == HM_BUS_READ_PENDING && ++spin < HM_BUS_CLAIM_SPIN)
                ;

            /* Still PENDING is NOT still lapped, and the spin expiring says
             * nothing about which one it is.
             *
             * A publisher reserves its sequence with the fetch-add and only
             * then writes the slot, so `a->seq` promises the message before
             * the bytes are there. A claimer that wins that sequence and
             * finds the slot unwritten is waiting on a live publisher inside
             * a window of two memcpys - and the ONE thing that closes the
             * window is that publisher getting a CPU.
             *
             * Spinning does not give it one. On an oversubscribed box the
             * spin budget expired with the publisher still runnable-not-
             * running, the claimer counted a gap, and the message was skipped
             * forever - by the only member that could ever have handled it.
             * That is silent loss wearing a gap counter, and it is what the
             * smokers caught: 39 of 40 handled, one gap, in a ring that had
             * 24 free slots and could not have lapped anything.
             *
             * So yield, and keep yielding. The bound stays - a publisher
             * killed mid-write must not wedge the pool forever - but it is
             * now a bound on SCHEDULER time rather than on instructions, and
             * a gap is counted only once a real publisher has had every
             * chance to finish. */
            while (r == HM_BUS_READ_PENDING && ++yields < HM_BUS_CLAIM_YIELD) {
                hm_bus_yield();
                r = hm_bus_read_slot(a, mine, &tl, &pl);
            }

            if (r == HM_BUS_READ_OK) {
                /* Another topic's message. The sequence is consumed by THIS
                 * group - its cursor is nobody else's - but it is not
                 * delivered and not counted, or a thumbnail worker would eat
                 * a chat broadcast. */
                if (tl != g->tlen || memcmp(hm_bus_scratch, g->topic, tl))
                    continue;
                if (cb) cb(ud, mine, hm_bus_scratch, tl, hm_bus_scratch + tl, pl);
                n++;
            }
            else {
                /* Lapped, or a publisher that never finished. Counted on the
                 * GROUP, because the loss belongs to the group rather than to
                 * whichever member was holding the cursor when it noticed. */
                hm_at_fetch_add64(&g->gaps, 1);
            }
        }
    }
    return n;
#else
    (void)gidx; (void)cb; (void)ud;
    return 0;
#endif
}

static uint64_t hm_bus_group_gaps(int gidx) {
#if HM_BUS_HAVE_ATOMICS
    hm_bus_arena *a = hm_bus;
    if (!a || gidx < 0 || (uint32_t)gidx >= a->ngroups) return 0;
    return hm_at_load64_acq(&a->groups[gidx].gaps);
#else
    (void)gidx;
    return 0;
#endif
}

static uint64_t hm_bus_published(void) {
#if HM_BUS_HAVE_ATOMICS
    if (!hm_bus) return 0;
    return hm_at_load64_acq(&hm_bus->published);
#else
    return 0;
#endif
}

/* ---- subscribers --------------------------------------------------------- */
/*
 * PROCESS-LOCAL, and that is the point. A registration is a callback, and a
 * callback cannot cross a fork; the shared thing is the ring, not the list of
 * people reading it.
 *
 * A subscription is either FANOUT (group empty - this process sees every
 * message on the topic) or a QUEUE GROUP (this process competes with every
 * other member for each one). One registration function, with the group as
 * the only difference, because they are one mechanism.
 */
typedef struct {
    int       used;
    hm_bus_cb cb;
    void     *ud;
    uint32_t  tlen, glen;
    int       gidx;                    /* resolved group, or -1 for fanout */
    char      topic[HM_BUS_NAMELEN];
    char      group[HM_BUS_NAMELEN];
} hm_bus_sub;

static hm_bus_sub hm_bus_subs[HM_BUS_SUBS];
static int        hm_bus_nsubs = 0;

/* The dispatcher's own fanout cursor, separate from the one the Perl-level
 * receive() uses. Two readers in one process must not consume each other's
 * messages: a cursor is a position, not a queue, and sharing one would mean
 * whichever asked first got everything. */
static uint64_t hm_bus_disp_cursor = 1;
static uint64_t hm_bus_disp_gaps   = 0;

/* Register. Returns an id, or -1 when the table is full or there is no arena
 * to read from. `group` NULL or empty is fanout. */
static int hm_bus_subscribe(const char *topic, uint32_t tlen,
                            const char *group, uint32_t glen,
                            hm_bus_cb cb, void *ud) {
    int i;
    if (!topic || !tlen || tlen >= HM_BUS_NAMELEN || !cb) return -1;
    if (group && glen >= HM_BUS_NAMELEN) return -1;
    for (i = 0; i < HM_BUS_SUBS; i++) {
        hm_bus_sub *sb = &hm_bus_subs[i];
        if (sb->used) continue;
        memset(sb, 0, sizeof(*sb));
        memcpy(sb->topic, topic, tlen);
        sb->tlen = tlen;
        sb->gidx = -1;
        if (group && glen) {
            memcpy(sb->group, group, glen);
            sb->glen = glen;
            /* Resolve NOW if there is an arena, and lazily if there is not.
             *
             * Both halves matter. A subscription starts "from now on", and
             * "now" is when the caller subscribed - resolving at first
             * dispatch instead would silently move a group's start point
             * later and lose whatever was published in between.
             *
             * But there is often no arena yet: subscriptions belong at boot,
             * in the parent, before the server forks - which is also before
             * run() maps the ring. Failing here would break group
             * subscriptions in the one place they should be made, and the
             * failure would look like the group simply never receiving
             * anything. So it is deferred, and nothing is lost by that,
             * because nothing can have been published before the ring
             * existed. */
#if HM_BUS_HAVE_ATOMICS
            sb->gidx = hm_bus ? hm_bus_group_of(topic, tlen, group, glen) : -1;
#else
            sb->gidx = -1;
#endif
        }
        sb->cb   = cb;
        sb->ud   = ud;
        sb->used = 1;
        if (i >= hm_bus_nsubs) hm_bus_nsubs = i + 1;
        return i;
    }
    return -1;
}

static int hm_bus_unsubscribe(int id) {
    if (id < 0 || id >= HM_BUS_SUBS || !hm_bus_subs[id].used) return 0;
    hm_bus_subs[id].used = 0;
    return 1;
}

#if HM_BUS_HAVE_ATOMICS
/* One drained message, offered to every FANOUT subscriber whose topic it is.
 * Group subscribers are not served from here: they claim, which is a
 * different cursor and a different guarantee. */
/* Counted here rather than taken from the drain's return, because they answer
 * different questions: the drain says how many messages it READ, and a caller
 * asking what dispatch did means how many reached a subscriber. A message on a
 * topic nobody subscribed to is read and not delivered, and reporting it as
 * delivered makes the number useless for the one thing it is for - telling
 * whether the wiring works. */
static long hm_bus_delivered = 0;

static void hm_bus_fan_cb(void *ud, uint64_t seq, const char *topic,
                          uint32_t tlen, const char *payload, uint32_t plen) {
    int i;
    (void)ud;
    for (i = 0; i < hm_bus_nsubs; i++) {
        hm_bus_sub *sb = &hm_bus_subs[i];
        if (!sb->used || sb->glen) continue;
        if (sb->tlen != tlen || memcmp(sb->topic, topic, tlen)) continue;
        sb->cb(sb->ud, seq, topic, tlen, payload, plen);
        hm_bus_delivered++;
    }
}

static void hm_bus_grp_cb(void *ud, uint64_t seq, const char *topic,
                          uint32_t tlen, const char *payload, uint32_t plen) {
    hm_bus_sub *sb = (hm_bus_sub *)ud;
    sb->cb(sb->ud, seq, topic, tlen, payload, plen);
    hm_bus_delivered++;
}

/* Point every cursor this process owns at "from now on".
 *
 * A worker must do this after the fork. A cursor is a position in a stream
 * this process has not been reading, and inheriting one means either replaying
 * what the parent already handled or skipping what it has not - and both look
 * from the outside like the bus being broken rather than the reader being
 * confused. Same discipline as otel_tracer.h's owner_pid check.
 *
 * A GROUP's cursor is deliberately untouched: it is shared, it belongs to the
 * group rather than to any member, and resetting it in a worker would throw
 * away work its siblings had not taken yet. */
static void hm_bus_reset_cursors(void) {
    uint64_t now = hm_bus ? hm_at_load64_acq(&hm_bus->seq) : 0;
    hm_bus_disp_cursor = now;
    hm_bus_disp_gaps   = 0;
}

/* Everything waiting, to everybody registered. Called from the wakeup, and
 * safe to call at any other time - it is how a caller with no loop polls.
 *
 * Fanout first, in ONE pass over the ring however many subscribers there are:
 * a pass per subscriber would read the same slots repeatedly and, worse, each
 * would need its own cursor to stay honest about gaps. */
static long hm_bus_dispatch(void) {
    int i, any_fan = 0;

    if (!hm_bus) return 0;
    hm_bus_delivered = 0;
    for (i = 0; i < hm_bus_nsubs; i++)
        if (hm_bus_subs[i].used && !hm_bus_subs[i].glen) { any_fan = 1; break; }

    if (any_fan)
        (void)hm_bus_drain(&hm_bus_disp_cursor, &hm_bus_disp_gaps,
                           hm_bus_fan_cb, NULL);
    else
        hm_bus_disp_cursor = hm_at_load64_acq(&hm_bus->seq);

    for (i = 0; i < hm_bus_nsubs; i++) {
        hm_bus_sub *sb = &hm_bus_subs[i];
        if (!sb->used || !sb->glen) continue;
        /* Resolve on first use: by now the arena exists, which it did not
         * when the application registered. */
        if (sb->gidx < 0)
            sb->gidx = hm_bus_group_of(sb->topic, sb->tlen,
                                       sb->group, sb->glen);
        if (sb->gidx < 0) continue;          /* the group table is full */
        (void)hm_bus_claim(sb->gidx, hm_bus_grp_cb, sb);
    }
    return hm_bus_delivered;
}
#else
static long hm_bus_dispatch(void) { return 0; }
#endif


#endif /* HM_BUS_H */
