/* hm_sa_abuse.h - the abuse controls on Hyperman's Shared::Arena: an IP
 * denylist checked at accept and fixed-window rate counters checked per
 * request, on two Map tenants of the one arena hm_sa.h creates.
 *
 * Perl-free. The includer defines `HM_SA` (the sa_abi table, or NULL) and
 * `hm_sa_region` (the arena, or NULL) before this header: hm_sa.h does in
 * the server, and bench/arena_bench.c does with no interpreter at all, which
 * is how the accept path is measured.
 *
 * THE CONTRACT, which every consumer relies on and 00-overview of the port
 * plan spells out: deny_add/remove/check take IP strings; ratelimit_hit is a
 * FIXED WINDOW - at most `limit` hits per key in each `window`-second
 * wall-clock slot, `reset` the epoch second the slot rolls, `remaining` never
 * below zero, `limit <= 0` unlimited with remaining -1 - and everything
 * FAILS OPEN: no table, no arena, a full map or a contended stripe answer
 * "not denied" and "allowed". The limiter must never be the reason a good
 * request is refused.
 *
 * ---- the denylist ------------------------------------------------------------
 *
 * A Map keyed by the IP string with an empty value and a per-key deadline.
 * The check is a fetch with a zero-length buffer: a hash, a probe, a seqlock
 * read, and the clock only for an entry that carries a deadline. The empty
 * home slot, which is nearly every accept, is a hash and one load - and no
 * time(2) per connection, which the old table paid unconditionally.
 *
 * ---- the fixed window --------------------------------------------------------
 *
 * A Map keyed by the 64-bit FNV of the caller's opaque bytes, exactly the key
 * the old table used, so the collision set is unchanged and a key may be any
 * length with NULs in it. The first hit in a window CREATES the counter with
 * a deadline at the window's END; map_incr_ttl sets a deadline only on a
 * create or a reset, so later hits inside the window count against the same
 * deadline and the window does not slide. Every process, whichever wall-clock
 * second it read, agrees on when the counter lapses.
 *
 * Over capacity the map refuses the new key and the request is allowed. The
 * old table evicted the key's home slot instead, resetting a live counter.
 * Both leak looser, never tighter; this one no longer disturbs anybody else's.
 */

#ifndef HM_SA_ABUSE_H
#define HM_SA_ABUSE_H

#include <string.h>
#include <time.h>
#include <stdint.h>
#include <stddef.h>
#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/time.h>
#endif

#include "sa_abi.h"
#include "hm_atomic.h"

#define HM_SA_DENY_CAP   1024
#define HM_SA_RATE_CAP   4096
#define HM_SA_DENY_SLOT  96    /* 39 of header, room for an IPv6 string    */
#define HM_SA_RATE_SLOT  64    /* 39 of header, 8 of key, 8 of counter     */

static sa_hash *hm_sa_deny = NULL;     /* NULL = fail open */
static sa_hash *hm_sa_rate = NULL;

/* The same wall clock the map's deadlines are on, in milliseconds. sa_time.h
 * is not an installed header, so this is its twin, coarse clock included:
 * on Linux CLOCK_REALTIME_COARSE is a vDSO read of the last tick with no
 * counter access, a quarter of gettimeofday's cost, and a tick's granularity
 * on a deadline a second wide is nothing. Makefile.PL probes for it by
 * running it (HM_HAVE_COARSE_CLOCK); the harness inherits Shared::Arena's
 * verdict (SA_HAVE_COARSE_CLOCK). */
static uint64_t hm_sa_now_ms(void) {
#ifdef _WIN32
    FILETIME ft;
    ULARGE_INTEGER u;
    GetSystemTimeAsFileTime(&ft);
    u.LowPart  = ft.dwLowDateTime;
    u.HighPart = ft.dwHighDateTime;
    return (uint64_t)((u.QuadPart - 116444736000000000ULL) / 10000ULL);
#else
    struct timeval tv;
#  if defined(HM_HAVE_COARSE_CLOCK) || defined(SA_HAVE_COARSE_CLOCK)
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME_COARSE, &ts) == 0)
        return (uint64_t)ts.tv_sec * 1000ULL + (uint64_t)(ts.tv_nsec / 1000000);
#  endif
    gettimeofday(&tv, NULL);
    return (uint64_t)tv.tv_sec * 1000ULL + (uint64_t)(tv.tv_usec / 1000);
#endif
}

/* Open both maps in the arena. Idempotent; zero caps take the defaults.
 * Returns 0, or -1 with *which naming the tenant that could not be carved
 * ("deny" or "rate"), so the caller can say so. Both stay NULL then: the
 * controls fail open together rather than one of them half working. */
static int hm_sa_abuse_open(unsigned deny_cap, unsigned rate_cap,
                            const char **which, int *err) {
    sa_hash *d, *r;
    int e = 0;
    if (which) *which = NULL;
    if (err) *err = 0;
    if (!HM_SA || !hm_sa_region || hm_sa_deny) return 0;
    if (!deny_cap) deny_cap = HM_SA_DENY_CAP;
    if (!rate_cap) rate_cap = HM_SA_RATE_CAP;
    d = HM_SA->map_open(hm_sa_region, "deny", 4, deny_cap, HM_SA_DENY_SLOT, &e);
    if (!d) { if (which) *which = "deny"; if (err) *err = e; return -1; }
    r = HM_SA->map_open(hm_sa_region, "rate", 4, rate_cap, HM_SA_RATE_SLOT, &e);
    if (!r) {
        HM_SA->map_release(d);
        if (which) *which = "rate";
        if (err) *err = e;
        return -1;
    }
    hm_sa_deny = d;
    hm_sa_rate = r;
    return 0;
}

static int hm_sa_abuse_live(void) { return hm_sa_deny != NULL; }

/* ---- the denylist ------------------------------------------------------------ */

/* 1 if ip is on the list and not lapsed, else 0. The accept path. */
static int hm_sa_deny_check(const char *ip) {
    char none[1];
    uint32_t vlen = 0;
    if (!hm_sa_deny || !ip || !ip[0]) return 0;
    return HM_SA->map_fetch(hm_sa_deny, ip, (uint32_t)strlen(ip), none, 0, &vlen)
           == SA_MAP_HIT;
}

/* Add or refresh for ttl_secs (0 = until the arena goes). Silent when the
 * map is full or the stripe is contended past its bound, as before. */
static void hm_sa_deny_add(const char *ip, long ttl_secs) {
    if (!hm_sa_deny || !ip || !ip[0]) return;
    (void)HM_SA->map_store_ttl(hm_sa_deny, ip, (uint32_t)strlen(ip), "", 0,
                               ttl_secs > 0 ? (uint64_t)ttl_secs * 1000u : 0);
}

static void hm_sa_deny_remove(const char *ip) {
    if (!hm_sa_deny || !ip || !ip[0]) return;
    (void)HM_SA->map_delete(hm_sa_deny, ip, (uint32_t)strlen(ip));
}

/* ---- the fixed window -------------------------------------------------------- */

/* Count one hit against the opaque key under `limit` per `window` seconds.
 * Returns 1 within the limit, 0 over. *remaining and *reset are filled when
 * non-NULL, whichever way it went. limit <= 0 is unlimited. */
static int hm_sa_ratelimit_hit(const void *key, size_t klen,
                               long limit, long window,
                               long *remaining, long *reset) {
    long w = window > 0 ? window : 60;
    /* ONE clock read: the second the window is computed from and the
     * millisecond the deadline is measured from are the same reading, so
     * they cannot straddle a boundary, and a hit pays one clock here rather
     * than time() and gettimeofday both. */
    uint64_t now_ms = hm_sa_now_ms();
    long now = (long)(now_ms / 1000u);
    long wstart = now - (now % w);
    uint64_t hkey, count = 0, end_ms, ttl_ms;
    int rc;

    if (reset) *reset = wstart + w;
    if (limit <= 0) { if (remaining) *remaining = -1; return 1; }
    if (!hm_sa_rate) { if (remaining) *remaining = limit - 1; return 1; }

    hkey = hm_at_fnv(key, klen);
    if (!hkey) hkey = 1;                 /* the old table's empty marker */

    /* The deadline is the window's END, so the first hit of a window sets
     * what every later hit inherits. */
    end_ms = (uint64_t)(wstart + w) * 1000u;
    ttl_ms = end_ms > now_ms ? end_ms - now_ms : 1;

    /* On the clock reading above: the map neither reads it again for the
     * deadline it sets nor for the deadline it checks. */
    rc = HM_SA->map_incr_at(hm_sa_rate, (const char *)&hkey, 8, 1, ttl_ms,
                            now_ms, &count);
    if (rc != SA_MAP_STORE_OK) {         /* full, contended, or not ours */
        if (remaining) *remaining = limit - 1;
        return 1;
    }
    if (remaining)
        *remaining = count >= (uint64_t)limit ? 0 : limit - (long)count;
    return count <= (uint64_t)limit ? 1 : 0;
}

#endif /* HM_SA_ABUSE_H */
