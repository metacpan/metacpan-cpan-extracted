/* hm_atomic.h - the atomics probe, and the handful of operations the
 * fork-shared arenas are built from.
 *
 * WHY THIS IS ITS OWN FILE.
 *
 * There are two shared-memory arenas now - the abuse controls in
 * hm_ratelimit.h and the message bus in hm_bus.h - and they need the same
 * four operations over the same builtins. Probed separately they would
 * eventually disagree, and the disagreement would surface on the one machine
 * nobody develops on: the FreeBSD 9 smoker, whose base cc is gcc 4.2.1. One
 * probe, one answer, both arenas.
 *
 * THE PROBE IS OF A FEATURE, NOT A COMPILER VERSION.
 *
 * The __atomic builtins are the ones we want, but they only arrived in GCC
 * 4.7: __GNUC__ alone is not the question to ask, and asking it broke the
 * build on FreeBSD 9 ('__ATOMIC_ACQUIRE' undeclared). That compiler does have
 * the older __sync family (GCC 4.1), and __sync says everything needed here:
 * a lock test-and-set IS an acquire, a lock release IS a release, and a full
 * barrier either side of a plain aligned word turns it into the acquire load
 * / release store a slot is published with.
 *
 * Only when NEITHER family exists is the whole thing disabled, and every
 * caller is written to fail open in that case. That is a supported
 * configuration, not a broken one.
 */

#ifndef HM_ATOMIC_H
#define HM_ATOMIC_H

#include <stdint.h>

#if defined(__has_builtin)
#  if __has_builtin(__atomic_load_n)
#    define HM_ATOMIC_GNU 1
#  endif
#endif
#if !defined(HM_ATOMIC_GNU) && defined(__GNUC__) \
    && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 7))
#  define HM_ATOMIC_GNU 1
#endif

#if defined(_WIN32)
/* No arena on Windows, and nothing to lose by it: an arena exists so state is
 * exact across a FORKED pool, and Windows runs a single worker (there is no
 * fork there), where per-process state is exact by construction. Every caller
 * is written to fail open with no arena, so this is the tested path rather
 * than a new one. CreateFileMapping only becomes worth writing if a
 * multi-process pool ever lands. */
#  define HM_HAVE_ATOMICS 0
#elif defined(HM_ATOMIC_GNU)
#  define HM_HAVE_ATOMICS 1
#elif defined(__GNUC__) \
    && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1))
#  define HM_HAVE_ATOMICS 1
#  define HM_ATOMIC_SYNC 1
#else
#  define HM_HAVE_ATOMICS 0
#endif

#define HM_LOCK_STRIPES  64        /* spinlock stripes in an arena */
#define HM_SPIN_MAX      100000    /* bounded spin -> fail open */

#if HM_HAVE_ATOMICS

/* The operations an arena needs, over whichever builtin family exists.
 *
 * Reads and writes of a naturally aligned 32-bit or 64-bit word cannot tear
 * on any target this builds on; the barrier is what orders them against the
 * other fields of the slot they publish, and that is all the __sync spelling
 * has to add. */

static int hm_at_tas(volatile unsigned char *l) {
#if defined(HM_ATOMIC_SYNC)
    return __sync_lock_test_and_set(l, (unsigned char)1) != 0;
#else
    return __atomic_test_and_set(l, __ATOMIC_ACQUIRE) != 0;
#endif
}

static void hm_at_clear(volatile unsigned char *l) {
#if defined(HM_ATOMIC_SYNC)
    __sync_lock_release(l);
#else
    __atomic_clear(l, __ATOMIC_RELEASE);
#endif
}

static uint32_t hm_at_load32_acq(volatile uint32_t *p) {
#if defined(HM_ATOMIC_SYNC)
    uint32_t v = *p;
    __sync_synchronize();          /* nothing below may be hoisted above it */
    return v;
#else
    return __atomic_load_n(p, __ATOMIC_ACQUIRE);
#endif
}

static void hm_at_store32_rel(volatile uint32_t *p, uint32_t v) {
#if defined(HM_ATOMIC_SYNC)
    __sync_synchronize();          /* the other fields land before this one */
    *p = v;
#else
    __atomic_store_n(p, v, __ATOMIC_RELEASE);
#endif
}

/* The 64-bit pair, for the bus: a sequence number that must not wrap in any
 * plausible lifetime, and a slot stamped with the sequence it holds. */

static uint64_t hm_at_load64_acq(volatile uint64_t *p) {
#if defined(HM_ATOMIC_SYNC)
    uint64_t v = *p;
    __sync_synchronize();
    return v;
#else
    return __atomic_load_n(p, __ATOMIC_ACQUIRE);
#endif
}

static void hm_at_store64_rel(volatile uint64_t *p, uint64_t v) {
#if defined(HM_ATOMIC_SYNC)
    __sync_synchronize();
    *p = v;
#else
    __atomic_store_n(p, v, __ATOMIC_RELEASE);
#endif
}

/* The one that makes a queue group work: take the next sequence and return
 * the one this caller now owns, exclusively, across every process sharing the
 * mapping. Both families spell it the same way. */
static uint64_t hm_at_fetch_add64(volatile uint64_t *p, uint64_t n) {
#if defined(HM_ATOMIC_SYNC)
    return __sync_fetch_and_add(p, n);
#else
    return __atomic_fetch_add(p, n, __ATOMIC_ACQ_REL);
#endif
}

/* Compare and swap a 64-bit word; 1 if this caller won.
 *
 * The queue group's claim needs this rather than a plain fetch-add. A
 * fetch-add cannot be undone: a claimer that adds and then finds it overshot
 * the last published sequence has ALREADY moved the shared cursor past
 * sequences that have not been written yet, and those messages are then
 * skipped forever - with nothing counted, because nothing noticed. A CAS
 * advances only when the caller both wins the race and is still inside what
 * has been published. */
static int hm_at_cas64(volatile uint64_t *p, uint64_t expect, uint64_t want) {
#if defined(HM_ATOMIC_SYNC)
    return __sync_bool_compare_and_swap(p, expect, want) ? 1 : 0;
#else
    return __atomic_compare_exchange_n(p, &expect, want, 0,
                                       __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)
           ? 1 : 0;
#endif
}

/* Set a flag from 0 to 1 and say whether this caller was the one who did it.
 * The bus wakeup needs exactly this: whoever wins pokes the worker, everybody
 * else has nothing to do. */
static int hm_at_test_and_set32(volatile uint32_t *p) {
#if defined(HM_ATOMIC_SYNC)
    return __sync_bool_compare_and_swap(p, 0u, 1u) ? 1 : 0;
#else
    uint32_t expect = 0;
    return __atomic_compare_exchange_n(p, &expect, 1u, 0,
                                       __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)
           ? 1 : 0;
#endif
}

/* Bounded acquire on a striped lock; returns 1 if it was taken, 0 if it gave
 * up. A worker that died holding one must not wedge the pool, so the caller
 * fails open rather than spinning forever. */
static int hm_at_lock(volatile unsigned char *locks, uint64_t h) {
    volatile unsigned char *l = &locks[h % HM_LOCK_STRIPES];
    long spin = 0;
    while (hm_at_tas(l)) {
        if (++spin >= HM_SPIN_MAX) return 0;
    }
    return 1;
}

static void hm_at_unlock(volatile unsigned char *locks, uint64_t h) {
    hm_at_clear(&locks[h % HM_LOCK_STRIPES]);
}

#endif /* HM_HAVE_ATOMICS */

/* FNV-1a 64, for hashing a key onto a table slot. Not cryptographic and not
 * meant to be: the tables it indexes hold no secret, and a collision costs a
 * probe. */
static uint64_t hm_at_fnv(const void *data, size_t len) {
    const unsigned char *p = (const unsigned char *)data;
    uint64_t h = 1469598103934665603ULL;
    size_t i;
    for (i = 0; i < len; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

#endif /* HM_ATOMIC_H */
