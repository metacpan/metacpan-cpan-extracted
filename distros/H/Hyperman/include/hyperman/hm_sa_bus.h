/* hm_sa_bus.h - the cross-worker message bus, on a Shared::Arena ring.
 *
 * One ring in the arena hm_sa.h creates, opened before the fork so every
 * worker publishes into and reads from the same copy. Perl-free: the includer
 * defines `HM_SA` and `hm_sa_region` (hm_sa.h in the server; the benchmark
 * harness with no interpreter).
 *
 * A message is published once; the delivery mode is WHERE THE CURSOR LIVES. A
 * fanout subscriber keeps its cursor in its own process, so every subscriber
 * reads every message. A queue group keeps one cursor in the arena, so
 * exactly one member gets each message, and the load balancing falls out of
 * the claim: a busy worker is not in the drain loop and not claiming.
 *
 * ---- what this header keeps, and what the ring changes -----------------------
 *
 * Every contract the old ring gave is kept here, at the seam:
 *
 *   - publish answers HM_BUS_OK / HM_BUS_LOCAL / HM_BUS_OVERSIZE, and an
 *     oversize message is REFUSED, never truncated. The ring would ACCEPT it -
 *     a record may span up to half the ring - so the ceiling is Hyperman's,
 *     checked BEFORE the ring sees the record: `bus_slot_size - 16`, the bytes
 *     the old slot header left, so a caller that sized its messages against
 *     the old bus sizes them the same against this one. The ring's own slot
 *     is 64 bytes wider than the configured one, so one message always fits
 *     ONE slot and never spans.
 *   - two fanout cursors per process, the dispatcher's and receive()'s, so two
 *     readers in one process never consume each other's records.
 *   - a group's identity is the (topic, name) PAIR. The ring's is the name
 *     alone with the topic bound at open, so the ring's group name is derived
 *     from both, and two subscriptions sharing a name across two topics get
 *     two groups, as they did.
 *   - a slot still being written is waited for, not counted lapped: the ring's
 *     claim reads before it claims and answers PENDING with the cursor
 *     unmoved, and the next dispatch retries. It never sleeps doing so.
 *   - queue groups are AT-MOST-ONCE. A member that claims and then dies loses
 *     the record; Punk::Queue is the durable one.
 *
 * Gaps are the cursor's lapped + abandoned: what this reader missed because
 * the ring wrapped, plus the holes a dead publisher left that the ring filled
 * and this reader stepped over. Both are counted, never silent.
 *
 * Everything FAILS OPEN. With no table, no arena or no ring, publish answers
 * HM_BUS_LOCAL and the caller delivers to its own subscribers, which is the
 * answer the abuse controls give with no arena.
 */

#ifndef HM_SA_BUS_H
#define HM_SA_BUS_H

#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

#include "sa_abi.h"
#include "hm_atomic.h"

#define HM_BUS_SLOTS      2048
#define HM_BUS_SLOT_SIZE  2048
#define HM_BUS_NAMELEN    64
#define HM_BUS_SUBS       64       /* registrations per process */
#define HM_SA_BUS_GROUPS  64       /* the ring's own table size */

/* The ring slot is this much wider than the configured slot, and a message
 * may use this much less than the configured slot: together they say one
 * message is one slot. Two numbers, one comment, one test (t/35 oversize). */
#define HM_SA_BUS_SLOT_PAD 64
#define HM_SA_BUS_HDR      16

/* publish outcomes */
#define HM_BUS_OK        0    /* on the ring, visible to the pool */
#define HM_BUS_LOCAL     1    /* no ring: the caller's own subscribers only */
#define HM_BUS_OVERSIZE (-1)  /* refused; never truncated */

typedef void (*hm_bus_cb)(void *ud, uint64_t seq,
                          const char *topic, uint32_t tlen,
                          const char *payload, uint32_t plen);

static sa_ring   *hm_sa_ring        = NULL;   /* NULL = fail open */
static uint32_t   hm_sa_bus_max_msg = 0;      /* topic + payload ceiling */
static sa_cursor *hm_sa_disp_cur    = NULL;   /* the dispatcher's fanout cursor */
static sa_cursor *hm_sa_recv_cur    = NULL;   /* receive()'s                    */

static int hm_sa_bus_live(void) { return hm_sa_ring != NULL; }

/* ---- lifecycle ------------------------------------------------------------- */

/* Open the ring in the arena. MUST run before the fork. Idempotent; zero takes
 * the default. 0, or -1 with *err set when the ring could not be carved, in
 * which case the bus is local-only. */
static int hm_sa_bus_open(uint32_t slots, uint32_t slot_size, int *err) {
    int e = 0;
    if (err) *err = 0;
    if (!HM_SA || !hm_sa_region || hm_sa_ring) return 0;
    if (!slots)     slots     = HM_BUS_SLOTS;
    if (!slot_size) slot_size = HM_BUS_SLOT_SIZE;
    if (slot_size < HM_SA_BUS_HDR + 16) slot_size = HM_BUS_SLOT_SIZE;
    hm_sa_ring = HM_SA->ring_open(hm_sa_region, "bus", 3, slots,
                                  slot_size + HM_SA_BUS_SLOT_PAD, &e);
    if (!hm_sa_ring) { if (err) *err = e; return -1; }
    hm_sa_bus_max_msg = slot_size - HM_SA_BUS_HDR;
    return 0;
}

/* ---- the wakeup ------------------------------------------------------------ */

/* Make `n` wakers. MUST run before the fork: the descriptors are inherited,
 * which is what lets their numbers live in the region. */
static int hm_sa_bus_wake_init(uint32_t n) {
    if (!HM_SA || !hm_sa_region) return 0;
    return HM_SA->wake_init(hm_sa_region, n);
}

/* Claim waker `idx` for this process, after the fork, and return its read
 * end, or -1. The entry drains stale bytes and clears the flag itself. */
static int hm_sa_bus_waker_take(int idx) {
    if (!HM_SA || !hm_sa_region) return -1;
    if (HM_SA->wake_take(hm_sa_region, idx) < 0) return -1;
    return HM_SA->wake_fd(hm_sa_region);
}

static int hm_sa_bus_waker_fd(void) {
    if (!HM_SA || !hm_sa_region) return -1;
    return HM_SA->wake_fd(hm_sa_region);
}

/* Empty the pipe, THEN clear the flag, and only then read the ring. The order
 * is the whole correctness of the wakeup (the ring's wake_drained keeps it):
 * clear first and a publisher can set the flag and write its byte while the
 * read loop still runs, the byte is swallowed, and this worker goes deaf. */
static void hm_sa_bus_waker_drained(void) {
    if (!HM_SA || !hm_sa_region) return;
    HM_SA->wake_drained(hm_sa_region);
}

/* ---- publishing ------------------------------------------------------------ */

static int hm_sa_bus_publish(const char *topic, uint32_t tlen,
                             const char *payload, uint32_t plen) {
    int64_t rc;
    if (!hm_sa_ring) return HM_BUS_LOCAL;
    if ((uint64_t)tlen + plen > hm_sa_bus_max_msg) return HM_BUS_OVERSIZE;
    rc = HM_SA->publish(hm_sa_ring, topic, tlen, payload, plen);
    if (SA_PUBLISHED(rc)) return HM_BUS_OK;
    return rc == SA_TOO_BIG ? HM_BUS_OVERSIZE : HM_BUS_LOCAL;
}

/* The next sequence to be published: what a cursor is reset TO. */
static uint64_t hm_sa_bus_seq(void) {
    return hm_sa_ring ? HM_SA->ring_position(hm_sa_ring) : 0;
}

/* Records published so far. Sequences start at one and a message is one
 * slot, so the position less one is the count. */
static uint64_t hm_sa_bus_published(void) {
    uint64_t p = hm_sa_bus_seq();
    return p ? p - 1 : 0;
}

/* ---- fanout cursors -------------------------------------------------------- */

typedef struct { hm_bus_cb cb; void *ud; } hm_sa_bus_ctx;

/* The ring hands a record with a flags word; the bus callback never had one. */
static void hm_sa_bus_rec(void *ud, uint64_t seq, const char *topic,
                          uint32_t tlen, const char *data, uint32_t dlen,
                          uint32_t flags) {
    hm_sa_bus_ctx *x = (hm_sa_bus_ctx *)ud;
    (void)flags;
    if (x->cb) x->cb(x->ud, seq, topic, tlen, data, dlen);
}

/* A cursor, opened on first use. From the START of what the ring still holds,
 * which is what a cursor born at sequence one did before: a worker resets it
 * to "from now on" in its attach, a script that never resets replays. */
static sa_cursor *hm_sa_bus_cursor(sa_cursor **c) {
    if (!*c && hm_sa_ring) *c = HM_SA->cursor_open(hm_sa_ring, 1);
    return *c;
}

/* Point a cursor at "from now on": release and reopen, which also zeroes its
 * gaps, as the old reset did. */
static void hm_sa_bus_reset_cursor(sa_cursor **c) {
    if (!hm_sa_ring) return;
    if (*c) HM_SA->cursor_release(*c);
    *c = HM_SA->cursor_open(hm_sa_ring, 0);
}

/* Both, because a caller saying "from now on" means the process, not one of
 * its two halves; resetting only one leaves the other replaying history. */
static void hm_sa_bus_reset_cursors(void) {
    hm_sa_bus_reset_cursor(&hm_sa_disp_cur);
    hm_sa_bus_reset_cursor(&hm_sa_recv_cur);
}

/* Everything this cursor has not seen. Stops at a record still being written
 * rather than waiting; the ring's escalation never sleeps and a hole left by
 * a dead publisher is filled and stepped over on a later turn. */
static long hm_sa_bus_drain(sa_cursor **c, hm_bus_cb cb, void *ud) {
    hm_sa_bus_ctx x;
    sa_cursor *cur;
    if (!hm_sa_ring) return 0;
    cur = hm_sa_bus_cursor(c);
    if (!cur) return 0;
    x.cb = cb;
    x.ud = ud;
    return HM_SA->drain(cur, 0, hm_sa_bus_rec, &x);
}

/* What this cursor MISSED: lapped by the ring, or a hole left by a dead
 * publisher. Different diagnoses, one number the caller was promised. */
static uint64_t hm_sa_bus_gaps_of(sa_cursor *c) {
    sa_counts n;
    if (!c || !HM_SA) return 0;
    HM_SA->counts(c, &n);
    return n.lapped + n.abandoned;
}

/* ---- queue groups ---------------------------------------------------------- */

/* The ring's group name for a (topic, name) pair: 14 bytes of the name, a
 * colon, and the topic's hash, 31 bytes at most. Two names sharing a prefix
 * are told apart by the topic; two topics sharing a name get two groups. */
static uint32_t hm_sa_bus_gname(char out[32], const char *topic, uint32_t tlen,
                                const char *name, uint32_t nlen) {
    char nm[15];
    uint32_t n = nlen > 14 ? 14 : nlen;
    memcpy(nm, name, n);
    nm[n] = '\0';
    return (uint32_t)snprintf(out, 32, "%s:%016llx", nm,
                              (unsigned long long)hm_at_fnv(topic, tlen));
}

/* The group handles this process holds, one per (topic, name) it has used.
 * A handle is process-local; the group it names is in the ring. */
typedef struct {
    int         used;
    uint32_t    glen;
    char        gname[32];
    sa_group_h *gh;
} hm_sa_bus_grp;

static hm_sa_bus_grp hm_sa_bus_grps[HM_SA_BUS_GROUPS];

/* Find or open the group for (topic, name). NULL with no ring, a bad name, or
 * a full table. A new group starts at the CURRENT sequence: joining means
 * "from now on", and replaying the ring to a worker that just started is a
 * surprise nobody asked for. */
static sa_group_h *hm_sa_bus_group(const char *topic, uint32_t tlen,
                                   const char *name, uint32_t nlen) {
    char g[32];
    uint32_t gl;
    int i, free_at = -1, err = 0;
    sa_group_h *gh;

    if (!hm_sa_ring || !name || !nlen || nlen >= HM_BUS_NAMELEN) return NULL;
    if (!topic || !tlen || tlen >= HM_BUS_NAMELEN) return NULL;
    gl = hm_sa_bus_gname(g, topic, tlen, name, nlen);

    for (i = 0; i < HM_SA_BUS_GROUPS; i++) {
        hm_sa_bus_grp *e = &hm_sa_bus_grps[i];
        if (!e->used) { if (free_at < 0) free_at = i; continue; }
        if (e->glen == gl && memcmp(e->gname, g, gl) == 0) return e->gh;
    }
    if (free_at < 0) return NULL;
    gh = HM_SA->group_open(hm_sa_ring, g, gl, topic, tlen, 0, &err);
    if (!gh) return NULL;
    hm_sa_bus_grps[free_at].used = 1;
    hm_sa_bus_grps[free_at].glen = gl;
    memcpy(hm_sa_bus_grps[free_at].gname, g, gl);
    hm_sa_bus_grps[free_at].gh = gh;
    return gh;
}

/* Claim and handle whatever this group has that nobody else has taken; how
 * many this caller handled. The ring's claim reads BEFORE it claims, so a
 * record still being written comes back PENDING with the cursor unmoved and
 * is picked up next time, never counted lost. Records on other topics are
 * stepped over by the ring and never handed here. */
static long hm_sa_bus_claim(sa_group_h *gh, hm_bus_cb cb, void *ud) {
    long n = 0;
    uint64_t seq = 0;
    const char *tp = NULL, *dp = NULL;
    uint32_t tl = 0, dl = 0, fl = 0;
    if (!gh || !HM_SA) return 0;
    while (HM_SA->group_claim(gh, &seq, &tp, &tl, &dp, &dl, &fl) == SA_READ_OK) {
        if (cb) cb(ud, seq, tp, tl, dp, dl);
        n++;
    }
    return n;
}

/* Records the GROUP lost before any member claimed them: the loss belongs to
 * the group, not to whichever member noticed. */
static uint64_t hm_sa_bus_group_gaps(sa_group_h *gh) {
    sa_group_counts c;
    if (!gh || !HM_SA) return 0;
    HM_SA->group_counts(gh, &c);
    return c.lapped;
}

/* ---- subscribers ----------------------------------------------------------- */
/*
 * PROCESS-LOCAL: a registration is a callback and a callback cannot cross a
 * fork. The shared thing is the ring, not the list of people reading it. A
 * subscription is FANOUT (group empty) or a QUEUE GROUP; one registration
 * function, because they are one mechanism. The table keeps the old name
 * and shape, so hm_abi_impl.h and the Perl side alias `ud` as they did.
 */
typedef struct {
    int         used;
    hm_bus_cb   cb;
    void       *ud;
    uint32_t    tlen, glen;
    sa_group_h *gh;                    /* the group, or NULL for fanout */
    char        topic[HM_BUS_NAMELEN];
    char        group[HM_BUS_NAMELEN];
} hm_bus_sub;

static hm_bus_sub hm_bus_subs[HM_BUS_SUBS];
static int        hm_bus_nsubs = 0;

/* Register. An id, or -1 when the table is full. `group` NULL or empty is
 * fanout. A group is resolved NOW when there is a ring, so it starts where the
 * caller subscribed, and lazily at first dispatch when there is not yet -
 * subscriptions belong at boot, in the parent, before run() opens the ring,
 * and nothing can have been published before the ring existed. */
static int hm_sa_bus_subscribe(const char *topic, uint32_t tlen,
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
        if (group && glen) {
            memcpy(sb->group, group, glen);
            sb->glen = glen;
            sb->gh = hm_sa_ring ? hm_sa_bus_group(topic, tlen, group, glen) : NULL;
        }
        sb->cb   = cb;
        sb->ud   = ud;
        sb->used = 1;
        if (i >= hm_bus_nsubs) hm_bus_nsubs = i + 1;
        return i;
    }
    return -1;
}

static int hm_sa_bus_unsubscribe(int id) {
    if (id < 0 || id >= HM_BUS_SUBS || !hm_bus_subs[id].used) return 0;
    hm_bus_subs[id].used = 0;
    return 1;
}

/* Counted here rather than taken from the drain's return, because they answer
 * different questions: the drain says how many records it READ, a caller
 * asking what dispatch did means how many reached a subscriber. */
static long hm_bus_delivered = 0;

static void hm_sa_bus_fan_cb(void *ud, uint64_t seq, const char *topic,
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

static void hm_sa_bus_grp_cb(void *ud, uint64_t seq, const char *topic,
                             uint32_t tlen, const char *payload, uint32_t plen) {
    hm_bus_sub *sb = (hm_bus_sub *)ud;
    sb->cb(sb->ud, seq, topic, tlen, payload, plen);
    hm_bus_delivered++;
}

/* Everything waiting, to everybody registered. Called from the wakeup, and
 * safe to call at any other time - it is how a caller with no loop polls.
 * Fanout first, in ONE pass over the ring however many subscribers there are;
 * then each group subscriber claims until the group is empty. */
static long hm_sa_bus_dispatch(void) {
    int i, any_fan = 0;

    if (!hm_sa_ring) return 0;
    hm_bus_delivered = 0;
    for (i = 0; i < hm_bus_nsubs; i++)
        if (hm_bus_subs[i].used && !hm_bus_subs[i].glen) { any_fan = 1; break; }

    if (any_fan)
        (void)hm_sa_bus_drain(&hm_sa_disp_cur, hm_sa_bus_fan_cb, NULL);
    else if (hm_sa_disp_cur) {
        /* Nobody is fanning out: drop the cursor rather than let it fall a
         * ring behind, so the next fanout subscriber starts from now. */
        HM_SA->cursor_release(hm_sa_disp_cur);
        hm_sa_disp_cur = NULL;
    }

    for (i = 0; i < hm_bus_nsubs; i++) {
        hm_bus_sub *sb = &hm_bus_subs[i];
        if (!sb->used || !sb->glen) continue;
        if (!sb->gh) sb->gh = hm_sa_bus_group(sb->topic, sb->tlen,
                                              sb->group, sb->glen);
        if (!sb->gh) continue;             /* the group table is full */
        (void)hm_sa_bus_claim(sb->gh, hm_sa_bus_grp_cb, sb);
    }
    return hm_bus_delivered;
}

#endif /* HM_SA_BUS_H */
