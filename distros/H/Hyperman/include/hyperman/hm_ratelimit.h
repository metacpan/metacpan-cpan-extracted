#ifndef HM_RATELIMIT_H
#define HM_RATELIMIT_H

/* Abuse controls on a fork-shared arena: an IP denylist checked at accept and
 * fixed-window rate counters checked per request. Both live in ONE anonymous
 * shared-memory region mmap'd by the supervisor BEFORE it forks the workers,
 * so every worker sees the same state - a per-worker copy would multiply a
 * 100/min limit into workers x 100/min, the whole reason Maat::RateLimit put
 * its counters in a shared file rather than a Perl variable. Here the sharing
 * is memory, not a file, so a hit costs no syscall.
 *
 * Everything fails OPEN: with no arena (mmap failed, or the compiler has no
 * atomics) deny_check answers 0 and ratelimit_hit answers "allowed", matching
 * the gateway's fail-open ethos. The limiter must never be the reason a good
 * request is refused.
 *
 * Concurrency: workers are separate PROCESSES sharing the mapping. The accept
 * hot path (deny_check) is lock-free - a writer fills a slot and publishes it
 * with a release store, a reader acquires it - so a denylist lookup on every
 * inbound connection never blocks. The rarer writes and the counter
 * read-modify-write take a striped spinlock in the arena, with a bounded spin
 * that fails open rather than risk a stall if a worker died holding one. */

#include <sys/mman.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <stddef.h>

/* Linux spells it MAP_ANONYMOUS, the BSDs and Solaris/illumos MAP_ANON. */
#if !defined(MAP_ANONYMOUS) && defined(MAP_ANON)
#  define MAP_ANONYMOUS MAP_ANON
#endif

/* Atomics. GCC/Clang __atomic covers every platform this ships on; without it
 * the arena is simply disabled and the whole feature fails open. */
#if defined(__GNUC__)
#  define HM_RL_HAVE_ATOMICS 1
#else
#  define HM_RL_HAVE_ATOMICS 0
#endif

#define HM_RL_MAGIC     0x484D524Cu   /* "HMRL" */
#define HM_RL_IPLEN     46            /* INET6_ADDRSTRLEN */
#define HM_RL_LOCKS     64            /* spinlock stripes */
#define HM_RL_SPIN_MAX  100000        /* bounded spin -> fail open */
#define HM_RL_DENY_CAP  1024          /* default table sizes */
#define HM_RL_RATE_CAP  4096

/* A denylist slot. `state`: 0 empty (probe stops), 1 live, 2 tombstone (probe
 * continues). `expiry`: 0 permanent, else the epoch it lapses at. */
typedef struct {
    uint32_t state;
    long     expiry;
    char     ip[HM_RL_IPLEN];
} hm_rl_deny_slot;

/* A fixed-window counter slot, keyed by a 64-bit hash of the caller's opaque
 * key. `keyhash` 0 means empty. A slot whose `window` has rolled holds a
 * counter that is about to reset anyway, so it is reclaimable: a new key
 * reuses the first such stale slot it probes past before it would evict a
 * live one. When every slot is a live counter (the table is genuinely over
 * capacity) a new key overwrites its hash-home slot, which resets that
 * counter - so over-capacity leaks looser, not tighter; size the table above
 * the peak of distinct keys in a window. */
typedef struct {
    uint64_t keyhash;
    long     window;
    long     count;
} hm_rl_rate_slot;

typedef struct hm_rl_arena {
    uint32_t magic;
    uint32_t deny_cap;
    uint32_t rate_cap;
    volatile unsigned char locks[HM_RL_LOCKS];
    hm_rl_deny_slot *deny;   /* into the same mapping, valid across fork */
    hm_rl_rate_slot *rate;
} hm_rl_arena;

/* Process-global. NULL = disabled/fail-open. Set once, before the fork, so
 * every worker inherits the same pointer at the same address. */
static hm_rl_arena *hm_rl = NULL;

/* ---- primitives ------------------------------------------------------------ */

static uint64_t hm_rl_fnv(const void *data, size_t len) {
    const unsigned char *p = (const unsigned char *)data;
    uint64_t h = 1469598103934665603ULL;         /* FNV-1a 64 */
    size_t i;
    for (i = 0; i < len; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

#if HM_RL_HAVE_ATOMICS
/* Bounded acquire; returns 1 if the lock was taken, 0 if it gave up (a worker
 * that died holding it must not wedge the pool - the caller fails open). */
static int hm_rl_lock(hm_rl_arena *a, uint64_t h) {
    volatile unsigned char *l = &a->locks[h % HM_RL_LOCKS];
    long spin = 0;
    while (__atomic_test_and_set(l, __ATOMIC_ACQUIRE)) {
        if (++spin >= HM_RL_SPIN_MAX) return 0;
    }
    return 1;
}
static void hm_rl_unlock(hm_rl_arena *a, uint64_t h) {
    __atomic_clear(&a->locks[h % HM_RL_LOCKS], __ATOMIC_RELEASE);
}
#endif

/* ---- lifecycle ------------------------------------------------------------- */

/* Allocate the arena. MUST run in the supervisor before it forks, so the
 * mapping (and the pointer to it) is inherited by every worker. Idempotent;
 * a zero cap takes the default. On any failure hm_rl stays NULL (fail open). */
static void hm_rl_arena_init(uint32_t deny_cap, uint32_t rate_cap) {
#if HM_RL_HAVE_ATOMICS
    size_t hdr, dsz, rsz, total;
    void *m;
    hm_rl_arena *a;
    if (hm_rl) return;
    if (!deny_cap) deny_cap = HM_RL_DENY_CAP;
    if (!rate_cap) rate_cap = HM_RL_RATE_CAP;
    hdr   = sizeof(hm_rl_arena);
    dsz   = (size_t)deny_cap * sizeof(hm_rl_deny_slot);
    rsz   = (size_t)rate_cap * sizeof(hm_rl_rate_slot);
    total = hdr + dsz + rsz;
    m = mmap(NULL, total, PROT_READ | PROT_WRITE,
             MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (m == MAP_FAILED) return;
    memset(m, 0, total);
    a = (hm_rl_arena *)m;
    a->magic    = HM_RL_MAGIC;
    a->deny_cap = deny_cap;
    a->rate_cap = rate_cap;
    a->deny = (hm_rl_deny_slot *)((char *)m + hdr);
    a->rate = (hm_rl_rate_slot *)((char *)m + hdr + dsz);
    hm_rl = a;
#else
    (void)deny_cap; (void)rate_cap;
#endif
}

/* ---- denylist -------------------------------------------------------------- */

/* 1 if ip is on the denylist and not lapsed, else 0. Lock-free: on the accept
 * path for every inbound connection. */
static int hm_rl_deny_check(const char *ip) {
#if HM_RL_HAVE_ATOMICS
    hm_rl_arena *a = hm_rl;
    uint32_t cap, i, start;
    long now;
    if (!a || !ip || !ip[0]) return 0;
    cap   = a->deny_cap;
    start = (uint32_t)(hm_rl_fnv(ip, strlen(ip)) % cap);
    now   = (long)time(NULL);
    for (i = 0; i < cap; i++) {
        hm_rl_deny_slot *s = &a->deny[(start + i) % cap];
        uint32_t st = __atomic_load_n(&s->state, __ATOMIC_ACQUIRE);
        if (st == 0) return 0;                       /* empty: not present */
        if (st == 2) continue;                       /* tombstone: keep going */
        if (strncmp(s->ip, ip, HM_RL_IPLEN) != 0) continue;
        if (s->expiry != 0 && s->expiry <= now) return 0;  /* lapsed */
        return 1;
    }
    return 0;
#else
    (void)ip; return 0;
#endif
}

/* Add (or refresh) ip for ttl_secs (0 = permanent). Silently does nothing if
 * the arena is full or the stripe is contended past the bound. */
static void hm_rl_deny_add(const char *ip, long ttl_secs) {
#if HM_RL_HAVE_ATOMICS
    hm_rl_arena *a = hm_rl;
    uint32_t cap, i, start;
    uint64_t h;
    int free_at = -1;
    long expiry;
    if (!a || !ip || !ip[0]) return;
    cap    = a->deny_cap;
    h      = hm_rl_fnv(ip, strlen(ip));
    start  = (uint32_t)(h % cap);
    expiry = ttl_secs > 0 ? (long)time(NULL) + ttl_secs : 0;
    if (!hm_rl_lock(a, h)) return;
    for (i = 0; i < cap; i++) {
        uint32_t idx = (start + i) % cap;
        hm_rl_deny_slot *s = &a->deny[idx];
        if (s->state == 1 && strncmp(s->ip, ip, HM_RL_IPLEN) == 0) {
            s->expiry = expiry;                      /* refresh in place */
            hm_rl_unlock(a, h);
            return;
        }
        if (s->state != 1 && free_at < 0) free_at = (int)idx;  /* 0 or 2 */
        if (s->state == 0) break;                    /* no live match beyond */
    }
    if (free_at >= 0) {
        hm_rl_deny_slot *s = &a->deny[free_at];
        memset(s->ip, 0, HM_RL_IPLEN);
        strncpy(s->ip, ip, HM_RL_IPLEN - 1);
        s->expiry = expiry;
        __atomic_store_n(&s->state, 1u, __ATOMIC_RELEASE);   /* publish */
    }
    hm_rl_unlock(a, h);
#else
    (void)ip; (void)ttl_secs;
#endif
}

static void hm_rl_deny_remove(const char *ip) {
#if HM_RL_HAVE_ATOMICS
    hm_rl_arena *a = hm_rl;
    uint32_t cap, i, start;
    uint64_t h;
    if (!a || !ip || !ip[0]) return;
    cap   = a->deny_cap;
    h     = hm_rl_fnv(ip, strlen(ip));
    start = (uint32_t)(h % cap);
    if (!hm_rl_lock(a, h)) return;
    for (i = 0; i < cap; i++) {
        hm_rl_deny_slot *s = &a->deny[(start + i) % cap];
        if (s->state == 0) break;
        if (s->state == 1 && strncmp(s->ip, ip, HM_RL_IPLEN) == 0) {
            __atomic_store_n(&s->state, 2u, __ATOMIC_RELEASE);  /* tombstone */
            break;
        }
    }
    hm_rl_unlock(a, h);
#else
    (void)ip;
#endif
}

/* ---- fixed-window rate limit ----------------------------------------------- */

/* Count one hit against the opaque key under `limit` per `window` seconds.
 * Returns 1 if within the limit, 0 if over. *remaining / *reset are filled
 * when non-NULL. limit <= 0 is unlimited. Same fixed window as
 * Maat::RateLimit: the window is a function of the clock, and the first hit of
 * a new window finds a stale record and zeroes it - no timer, no sweep. */
static int hm_rl_ratelimit_hit(const void *key, size_t klen,
                               long limit, long window,
                               long *remaining, long *reset) {
    long now, wstart, wreset;
    if (window <= 0) window = 60;
    now    = (long)time(NULL);
    wstart = now - (now % window);
    wreset = wstart + window;
    if (reset) *reset = wreset;

    if (limit <= 0) {                                 /* unlimited */
        if (remaining) *remaining = -1;
        return 1;
    }
#if HM_RL_HAVE_ATOMICS
    {
        hm_rl_arena *a = hm_rl;
        uint32_t cap, i, start;
        uint64_t h;
        long count;
        hm_rl_rate_slot *slot = NULL, *stale = NULL;
        if (!a) {                                     /* fail open */
            if (remaining) *remaining = limit - 1;
            return 1;
        }
        cap   = a->rate_cap;
        h     = hm_rl_fnv(key, klen);
        if (h == 0) h = 1;                            /* 0 marks empty */
        start = (uint32_t)(h % cap);
        if (!hm_rl_lock(a, h)) {                      /* contended: fail open */
            if (remaining) *remaining = limit - 1;
            return 1;
        }
        for (i = 0; i < cap; i++) {
            hm_rl_rate_slot *s = &a->rate[(start + i) % cap];
            if (s->keyhash == h) { slot = s; break; }        /* our counter */
            if (s->keyhash == 0) { slot = s; s->keyhash = h; break; }  /* claim */
            /* another key whose window has rolled: its counter is stale, so
             * remember it - reusing it reclaims an idle slot rather than
             * evicting a live counter. This is how the table drains when the
             * keys that filled it go quiet: no sweep, reclaimed on demand. */
            if (!stale && s->window != wstart) stale = s;
        }
        if (!slot) slot = stale ? stale : &a->rate[start];  /* reuse stale; else evict home */
        if (slot->keyhash != h) {                     /* took over another slot */
            slot->keyhash = h;
            slot->window  = 0;
        }
        if (slot->window != wstart) { slot->window = wstart; slot->count = 0; }
        slot->count++;
        count = slot->count;
        hm_rl_unlock(a, h);
        if (remaining) { long r = limit - count; *remaining = r < 0 ? 0 : r; }
        return count <= limit ? 1 : 0;
    }
#else
    (void)key; (void)klen;
    if (remaining) *remaining = limit - 1;
    return 1;
#endif
}

#endif /* HM_RATELIMIT_H */
