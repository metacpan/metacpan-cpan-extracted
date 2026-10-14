/* The core, with no perl in the process.
 *
 * Nothing here includes a perl header, and that is half the point: a core
 * header that reaches for an SV stops this file compiling. The other half is
 * that the build is ASan and UBSan, so a use-after-free in the order things
 * are released is a failure here and not a rare crash somewhere else.
 *
 * Output is TAP. xt/core-harness.t builds this, runs it and relays the
 * result. */

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>

/* ---- a value the harness can count ---------------------------------- */

typedef struct hv_val {
    int   refs;
    int   released;                    /* times the count reached zero */
    void (*on_release)(void *cx, struct hv_val *v);
    void *on_release_arg;
} hv_val;

static long hv_retains  = 0;
static long hv_releases = 0;

static void hv_retain(hv_val *v) { v->refs++; hv_retains++; }
static void hv_release(void *cx, hv_val *v) {
    hv_releases++;
    if (--v->refs == 0) {
        v->released++;
        if (v->on_release) v->on_release(cx, v);
    }
}

#define HAMT_VAL_RETAIN(cx, v)  hv_retain((hv_val *)(v))
#define HAMT_VAL_RELEASE(cx, v) hv_release((cx), (hv_val *)(v))
#define HAMT_VAL_EQ(cx, a, b)   ((a) == (b))

/* ---- an allocator the harness can count and fail --------------------- */

static long   ha_live_blocks = 0;
static size_t ha_live_bytes  = 0;
static long   ha_calls       = 0;
static long   ha_fail_at     = -1;     /* fail the call with this index */

/* The pool's own trips to the C library, counted with their sizes, so a
 * block freed at a size it was not allocated at shows in the byte count. */
static long   hr_allocs = 0, hr_frees = 0, hr_live = 0;
static size_t hr_last = 0, hr_live_bytes = 0;
static void *hr_alloc(size_t n) {
    void *p = malloc(n);
    if (p) { hr_allocs++; hr_live++; hr_live_bytes += n; hr_last = n; }
    return p;
}
static void hr_free(void *p, size_t n) {
    hr_frees++; hr_live--; hr_live_bytes -= n;
    free(p);
}
#define HAMT_POOL_RAW_ALLOC(bytes)   hr_alloc(bytes)
#define HAMT_POOL_RAW_FREE(p, bytes) hr_free((p), (bytes))
#include "hamt/hamt_compat.h"
#include "hamt/hamt_pool.h"

/* With HAMT_HARNESS_POOL every allocation the core makes goes through a
 * pool, as it does in the built library, and every check in this file runs
 * on reused blocks. Without it each block is the C library's own and of its
 * exact size, which is what lets ASan see one byte past the end: a pooled
 * block is rounded up, and a freed one is still addressable. So the default
 * is without, and the harness is run both ways. */
#ifdef HAMT_HARNESS_POOL
static hamt_pool ha_pool;
#endif

static void *ha_alloc(size_t n) {
    void *p;
    if (ha_calls++ == ha_fail_at) return NULL;
#ifdef HAMT_HARNESS_POOL
    p = hamt_pool_alloc(&ha_pool, n);
#else
    p = malloc(n);
#endif
    if (p) { ha_live_blocks++; ha_live_bytes += n; }
    return p;
}
static void ha_free(void *p, size_t n) {
    ha_live_blocks--;
    ha_live_bytes -= n;
    /* Scribble first, so a read after free that ASan somehow misses still
     * reads something that is not a plausible entry. */
    memset(p, 0xDD, n);
#ifdef HAMT_HARNESS_POOL
    hamt_pool_free(&ha_pool, p, n);
#else
    free(p);
#endif
}

#define HAMT_ALLOC(cx, bytes)   ha_alloc(bytes)
#define HAMT_FREE(cx, p, bytes) ha_free((p), (bytes))

#include "hamt/hamt_compat.h"
#include "hamt/hamt_val.h"
#include "hamt/hamt_alloc.h"
#include "hamt/hamt_hash.h"
#include "hamt/hamt_entry.h"
#include "hamt/hamt_node.h"
#include "hamt/hamt_map.h"
#include "hamt/hamt_mut.h"
#include "hamt/hamt_iter.h"
#include "hamt/hamt_algebra.h"
static long vec_steps = 0;
#define HAMT_VEC_STEPPED() (vec_steps++)
#include "hamt/hamt_vec.h"
#include "hamt/hamt_check.h"

/* ---- TAP -------------------------------------------------------------- */

static int t_n = 0, t_bad = 0;
static void ok(int cond, const char *name) {
    t_n++;
    if (!cond) t_bad++;
    printf("%s %d - %s\n", cond ? "ok" : "not ok", t_n, name);
}

static hamt_entry *entry_for(const char *key, int utf8, hv_val *v) {
    size_t n = strlen(key);
    return hamt_entry_new(NULL, key, n, utf8, hamt_hash(key, n, utf8), v);
}

/* ---- popcount ---------------------------------------------------------- */

static void t_popcnt(void) {
    uint32_t x = 1;
    int i, good = 1;
    for (i = 0; i < 32; i++, x <<= 1)
        if (hamt_popcnt32(x) != 1 || hamt_popcnt32(x - 1) != (uint32_t)i) good = 0;
    ok(good, "popcnt32 of every single bit and every low run");
    ok(hamt_popcnt32(0) == 0 && hamt_popcnt32(0xffffffffU) == 32,
       "popcnt32 of nothing and of everything");
}

/* ---- the pool ---------------------------------------------------------- */

static void t_pool(void) {
    hamt_pool p;
    void *a, *b, *c, *d, *big;
    void *many[HAMT_POOL_KEEP + 10];
    long allocs, frees;
    int i, good;

    hamt_pool_open(&p);
    ok(p.open && hamt_pool_held(&p) == 0, "pool: a new one is open and holds nothing");

    a = hamt_pool_alloc(&p, 40);
    ok(a != NULL && hr_last == 48, "pool: 40 bytes is a block of 48");
    memset(a, 1, 48);
    frees = hr_frees;
    hamt_pool_free(&p, a, 40);
    ok(hr_frees == frees && hamt_pool_held(&p) == 1, "pool: freed, it is held and not given back");

    allocs = hr_allocs;
    b = hamt_pool_alloc(&p, 33);
    ok(b == a && hr_allocs == allocs && hamt_pool_held(&p) == 0,
       "pool: 33 bytes takes the held block of 48 and allocates nothing");
    memset(b, 2, 48);

    c = hamt_pool_alloc(&p, 32);
    ok(c != NULL && c != b && hr_last == 32, "pool: 32 bytes is a size of its own, exactly");
    d = hamt_pool_alloc(&p, 49);
    ok(d != NULL && hr_last == 64, "pool: 49 bytes is a block of 64");
    memset(c, 3, 32);
    memset(d, 4, 64);

    hamt_pool_free(&p, b, 48);
    allocs = hr_allocs;
    a = hamt_pool_alloc(&p, 20);
    ok(a != b && hr_allocs == allocs + 1 && hamt_pool_held(&p) == 1,
       "pool: a held 48 is not handed to a request for 20");
    hamt_pool_free(&p, a, 20);
    a = hamt_pool_alloc(&p, 64);
    ok(a != b && a != NULL && hamt_pool_held(&p) == 2, "pool: nor to a request for 64");
    memset(a, 5, 64);
    hamt_pool_free(&p, a, 64);
    hamt_pool_free(&p, c, 32);
    hamt_pool_free(&p, d, 49);
    ok(hamt_pool_held(&p) == 5, "pool: five blocks of four sizes are held");
    a = hamt_pool_alloc(&p, 64);
    b = hamt_pool_alloc(&p, 64);
    allocs = hr_allocs;
    c = hamt_pool_alloc(&p, 64);
    ok(a != b && a != c && b != c && hr_allocs == allocs + 1 && hamt_pool_held(&p) == 3,
       "pool: two held blocks of 64 serve two requests and the third is new");
    hamt_pool_free(&p, a, 64);
    hamt_pool_free(&p, b, 64);
    hamt_pool_free(&p, c, 64);

    a = hamt_pool_alloc(&p, 1);
    ok(a != NULL && hr_last == 16, "pool: one byte is a block of 16, room for the link");
    hamt_pool_free(&p, a, 1);
    b = hamt_pool_alloc(&p, 16);
    ok(b == a, "pool: and it serves a request for 16");
    hamt_pool_free(&p, b, 16);

    a = hamt_pool_alloc(&p, 304);
    ok(a != NULL && hr_last == 304, "pool: 304 bytes is the largest pooled size");
    memset(a, 6, 304);
    i = (int)hamt_pool_held(&p);
    hamt_pool_free(&p, a, 304);
    ok((int)hamt_pool_held(&p) == i + 1, "pool: and is held when freed");

    big = hamt_pool_alloc(&p, 305);
    ok(big != NULL && hr_last == 305, "pool: 305 bytes is past every list and allocated exactly");
    memset(big, 7, 305);
    frees = hr_frees;
    i = (int)hamt_pool_held(&p);
    hamt_pool_free(&p, big, 305);
    ok(hr_frees == frees + 1 && (int)hamt_pool_held(&p) == i, "pool: and given straight back");
    big = hamt_pool_alloc(&p, 100000);
    ok(big != NULL && hr_last == 100000, "pool: as is a large one");
    hamt_pool_free(&p, big, 100000);

    /* The bound. */
    good = 1;
    for (i = 0; i < HAMT_POOL_KEEP + 10; i++) {
        many[i] = hamt_pool_alloc(&p, 80);
        if (!many[i]) good = 0; else memset(many[i], 8, 80);
    }
    frees = hr_frees;
    for (i = 0; i < HAMT_POOL_KEEP + 10; i++) hamt_pool_free(&p, many[i], 80);
    ok(good && p.n[5] == HAMT_POOL_KEEP && hr_frees == frees + 10,
       "pool: a list holds its limit and the ten past it are given back");
    allocs = hr_allocs;
    for (i = 0; i < HAMT_POOL_KEEP; i++) many[i] = hamt_pool_alloc(&p, 80);
    ok(hr_allocs == allocs && p.n[5] == 0 && p.head[5] == NULL,
       "pool: every held block comes back out and the list is empty");
    for (i = 0; i < HAMT_POOL_KEEP; i++) hamt_pool_free(&p, many[i], 80);

    /* No pool to use. */
    a = hamt_pool_alloc(NULL, 40);
    ok(a != NULL && hr_last == 48, "pool: with no pool, 40 bytes is still a block of 48");
    memset(a, 9, 48);
    i = (int)hamt_pool_held(&p);
    hamt_pool_free(&p, a, 40);
    ok((int)hamt_pool_held(&p) == i + 1, "pool: so a pool can take it");
    b = hamt_pool_alloc(&p, 48);
    ok(b == a, "pool: and hand it out");
    frees = hr_frees;
    hamt_pool_free(NULL, b, 48);
    ok(hr_frees == frees + 1, "pool: and with no pool a free is given straight back");

    /* Closing. */
    a = hamt_pool_alloc(&p, 64);
    b = hamt_pool_alloc(&p, 200);
    i = (int)hamt_pool_held(&p);
    frees = hr_frees;
    hamt_pool_close(&p);
    ok(i > 0 && hr_frees == frees + i && hamt_pool_held(&p) == 0 && !p.open,
       "pool: closing gives back everything held");
    for (i = 0, good = 1; i < HAMT_POOL_CLASSES; i++) if (p.head[i] || p.n[i]) good = 0;
    ok(good, "pool: and leaves every list empty");
    frees = hr_frees;
    hamt_pool_free(&p, a, 64);
    hamt_pool_free(&p, b, 200);
    ok(hr_frees == frees + 2 && hamt_pool_held(&p) == 0, "pool: a block freed after that is not kept");
    a = hamt_pool_alloc(&p, 64);
    ok(a != NULL && hr_last == 64, "pool: and one can still be allocated");
    hamt_pool_free(&p, a, 64);
    ok(hr_live == 0 && hr_live_bytes == 0, "pool: nothing is left, and every size given back matched");
}

/* ---- the hash ---------------------------------------------------------- */

static void t_hash(void) {
    uint64_t a, b, full;
    int i, good;
    char buf[40];

    hamt_seed = 1;
    hamt_hash_set_bits(64);

    a = hamt_hash("alpha", 5, 0);
    ok(a == hamt_hash("alpha", 5, 0), "the same key hashes the same twice");
    full = a;
    ok(a != hamt_hash("alphb", 5, 0), "a one-byte change moves it");
    ok(a != hamt_hash("alpha", 5, 1), "the UTF-8 flag is part of the key");
    ok(hamt_hash("", 0, 0) != hamt_hash("", 0, 1), "even for the empty key");
    ok(hamt_hash("a\0b", 3, 0) != hamt_hash("a\0c", 3, 0),
       "bytes after an embedded NUL count");
    ok(hamt_hash("a", 1, 0) != hamt_hash("a\0", 2, 0),
       "and so does a trailing NUL");

    hamt_seed = 2;
    b = hamt_hash("alpha", 5, 0);
    ok(a != b, "a different seed gives a different hash");
    hamt_seed = 1;
    ok(a == hamt_hash("alpha", 5, 0), "and the first seed gives the first hash back");

    /* Every length from 0 to 33 crosses the eight-byte step four times and
     * the tail at every size. All distinct, and none reads past its end -
     * which is ASan's to say, on a buffer exactly as long as the key. */
    good = 1;
    for (i = 0; i <= 33 && good; i++) {
        char *k = (char *)malloc((size_t)i + 1);
        int j;
        memset(k, 'x', (size_t)i);
        a = hamt_hash(k, (size_t)i, 0);
        for (j = 0; j < i; j++) {
            char *k2 = (char *)malloc((size_t)j + 1);
            memset(k2, 'x', (size_t)j);
            if (hamt_hash(k2, (size_t)j, 0) == a) good = 0;
            free(k2);
        }
        free(k);
    }
    ok(good, "34 keys of one repeated byte, lengths 0 to 33, all hash apart");

    hamt_hash_set_bits(0);
    ok(hamt_hash("alpha", 5, 0) == 0 && hamt_hash("beta", 4, 1) == 0,
       "0 bits: every key hashes to zero");
    hamt_hash_set_bits(5);
    good = 1;
    for (i = 0; i < 1000; i++) {
        snprintf(buf, sizeof buf, "key-%d", i);
        if (hamt_hash(buf, strlen(buf), 0) > 31) good = 0;
    }
    ok(good, "5 bits: a thousand keys all land under 32");
    {
        int seen[32], distinct = 0;
        memset(seen, 0, sizeof seen);
        for (i = 0; i < 1000; i++) {
            snprintf(buf, sizeof buf, "key-%d", i);
            seen[hamt_hash(buf, strlen(buf), 0)] = 1;
        }
        for (i = 0; i < 32; i++) distinct += seen[i];
        ok(distinct == 32, "and between them reach all 32 values");
    }
    hamt_hash_set_bits(63);
    ok((hamt_hash("alpha", 5, 0) >> 63) == 0, "63 bits: the top bit is clear");
    hamt_hash_set_bits(64);
    ok(hamt_hash("alpha", 5, 0) == full, "64 bits: the whole hash is back");
    hamt_hash_set_bits(200);
    ok(hamt_hash_mask == ~(uint64_t)0, "more than 64 is 64, not a shift past the width");
}

/* ---- the entry --------------------------------------------------------- */

static void t_entry_basic(void) {
    hv_val v = { 1, 0, NULL, NULL };
    hamt_entry *e;
    long live = ha_live_blocks;

    e = entry_for("alpha", 0, &v);
    ok(e != NULL, "an entry is made");
    ok(e->refcnt == 1, "with one reference");
    ok(v.refs == 2, "and it retained the value: the caller keeps its own");
    ok(e->klen == 5 && memcmp(e->key, "alpha", 6) == 0,
       "the key is copied with a NUL after it");
    ok(e->val == &v && e->utf8 == 0, "value and flag are as given");

    hamt_entry_retain(e);
    ok(e->refcnt == 2, "retain adds one");
    hamt_entry_release(NULL, e);
    ok(v.refs == 2 && e->refcnt == 1, "releasing one of two leaves the entry and its value");
    hamt_entry_release(NULL, e);
    ok(v.refs == 1 && v.released == 0, "releasing the last gives the value back once");
    ok(ha_live_blocks == live, "and frees the entry");
}

static void t_entry_keys(void) {
    hamt_entry *e;
    static const char nul[] = { 'a', 0, 'b' };
    char *big;
    size_t n = 70000;

    e = entry_for("alpha", 0, NULL);
    ok(hamt_entry_key_eq(e, "alpha", 5, 0, hamt_hash("alpha", 5, 0)), "a key equals itself");
    ok(!hamt_entry_key_eq(e, "alpha", 5, 1, hamt_hash("alpha", 5, 1)),
       "but not the same bytes under the other flag");
    /* The same wrong answer must come from the flag itself, not only from
     * the hash having folded it in: hand it the entry's own hash. */
    ok(!hamt_entry_key_eq(e, "alpha", 5, 1, e->hash),
       "nor when the hashes are made to agree");
    ok(!hamt_entry_key_eq(e, "alphb", 5, 0, e->hash), "nor different bytes with the same hash");
    ok(!hamt_entry_key_eq(e, "alph", 4, 0, e->hash), "nor a prefix with the same hash");
    ok(!hamt_entry_key_eq(e, "alpha", 5, 0, e->hash ^ 1), "nor the same key with another hash");
    hamt_entry_release(NULL, e);

    e = hamt_entry_new(NULL, "", 0, 0, hamt_hash("", 0, 0), NULL);
    ok(e && e->klen == 0 && e->key[0] == '\0', "the empty key is a key");
    ok(hamt_entry_key_eq(e, "", 0, 0, e->hash), "equal to itself");
    ok(hamt_entry_key_eq(e, NULL, 0, 0, e->hash), "even from a NULL pointer of length zero");
    hamt_entry_release(NULL, e);

    e = hamt_entry_new(NULL, nul, 3, 0, hamt_hash(nul, 3, 0), NULL);
    ok(e && e->klen == 3 && memcmp(e->key, nul, 3) == 0, "a key with a NUL inside keeps all three bytes");
    ok(!hamt_entry_key_eq(e, "a\0c", 3, 0, e->hash), "and differs from one that changes after the NUL");
    hamt_entry_release(NULL, e);

    big = (char *)malloc(n);
    memset(big, 'k', n);
    e = hamt_entry_new(NULL, big, n, 1, hamt_hash(big, n, 1), NULL);
    ok(e && e->klen == n && e->utf8 == 1 && e->key[n] == '\0', "a 70,000-byte key, flagged");
    big[n - 1] = 'j';
    ok(!hamt_entry_key_eq(e, big, n, 1, e->hash), "differs from one that changes in its last byte");
    big[n - 1] = 'k';
    ok(hamt_entry_key_eq(e, big, n, 1, e->hash), "and equals the original");
    hamt_entry_release(NULL, e);
    free(big);

    ok(hamt_entry_new(NULL, "x", (size_t)-1, 0, 0, NULL) == NULL,
       "a length that cannot be allocated is refused, not wrapped");
}

static void t_entry_set_member(void) {
    long r0 = hv_retains, r1 = hv_releases;
    hamt_entry *e = entry_for("member", 0, NULL);
    hamt_entry_retain(e);
    hamt_entry_release(NULL, e);
    hamt_entry_release(NULL, e);
    ok(hv_retains == r0 && hv_releases == r1,
       "an entry with no value never reaches the value macros");
}

/* A value whose release comes back in and releases ANOTHER entry, which
 * frees it. That alone would pass whichever order the first entry did things
 * in, so the callback also counts the blocks live at the moment it runs: one
 * if the entry that held the value was freed first, two if it was not. */
typedef struct reenter {
    hamt_entry *other;
    int         ran;
} reenter;

static long reenter_live_at_callback = -1;

static void reenter_cb(void *cx, hv_val *v) {
    reenter *r = (reenter *)v->on_release_arg;
    r->ran++;
    reenter_live_at_callback = ha_live_blocks;
    hamt_entry_release(cx, r->other);
    r->other = NULL;
}

static void t_entry_reenter(void) {
    hv_val inner = { 1, 0, NULL, NULL };
    hv_val outer = { 1, 0, reenter_cb, NULL };
    reenter r;
    hamt_entry *a, *b;
    long live = ha_live_blocks;

    b = entry_for("second", 0, &inner);
    a = entry_for("first", 0, &outer);
    r.other = b; r.ran = 0;
    outer.on_release_arg = &r;

    /* Drop the harness's own reference, so the entry's is the last. */
    outer.refs--;
    hamt_entry_release(NULL, a);

    ok(r.ran == 1, "the value's release ran once");
    ok(reenter_live_at_callback == live + 1,
       "and by then the entry that held it was already freed: one block live, not two");
    ok(ha_live_blocks == live, "the entry it released on the way is freed too");
    ok(inner.refs == 1, "and gave its own value back");
}

static void t_entry_oom(void) {
    hv_val v = { 1, 0, NULL, NULL };
    hamt_entry *e;
    long live = ha_live_blocks;

    ha_fail_at = ha_calls;
    e = entry_for("alpha", 0, &v);
    ha_fail_at = -1;
    ok(e == NULL, "no memory: no entry");
    ok(v.refs == 1, "and the value was not retained");
    ok(ha_live_blocks == live, "and nothing was left allocated");
}

/* ---- the map ----------------------------------------------------------- */

static char kbuf[40];
static const char *keyn(const char *stem, int i) {
    snprintf(kbuf, sizeof kbuf, "%s-%d", stem, i);
    return kbuf;
}

/* 1 added, 0 replaced or unchanged, -1 no memory. The new root is installed
 * BEFORE the old one is released: releasing it can run a value's callback,
 * and the callback may use this very map. */
static int m_put(hamt_map *m, const char *key, hv_val *v) {
    size_t n = strlen(key);
    int added;
    hamt_node *r, *old;
    hamt_entry *e = hamt_entry_new(NULL, key, n, 0, hamt_hash(key, n, 0), v);
    if (!e) return -1;
    r = hamt_map_put(NULL, m->root, e, &added);
    hamt_entry_release(NULL, e);
    if (!r) return -1;
    old = m->root;
    m->root = r;
    m->count += (size_t)added;
    if (old) hamt_node_release(NULL, old);
    return added;
}

static int m_del(hamt_map *m, const char *key) {
    size_t n = strlen(key);
    int st;
    hamt_node *old, *r = hamt_map_del(NULL, m->root, key, n, 0, hamt_hash(key, n, 0), &st);
    if (st == HAMT_DEL_OOM) return -1;
    old = m->root;
    m->root = r;
    if (st == HAMT_DEL_DONE) m->count--;
    if (old) hamt_node_release(NULL, old);
    return st;
}

static hamt_entry *m_entry(const hamt_map *m, const char *key) {
    size_t n = strlen(key);
    return hamt_map_find(m->root, key, n, 0, hamt_hash(key, n, 0));
}

static void m_free(hamt_map *m) {
    hamt_node *old = m->root;
    m->root = NULL;
    m->count = 0;
    if (old) hamt_node_release(NULL, old);
}

static uint32_t rng_state = 12345;
static uint32_t rng(void) {
    rng_state = rng_state * 1664525U + 1013904223U;
    return rng_state >> 8;
}
static int *shuffled(int n) {
    int *p = (int *)malloc(sizeof(int) * (size_t)(n ? n : 1)), i;
    for (i = 0; i < n; i++) p[i] = i;
    for (i = n - 1; i > 0; i--) {
        int j = (int)(rng() % (uint32_t)(i + 1)), t = p[i];
        p[i] = p[j]; p[j] = t;
    }
    return p;
}

static hv_val *vals_new(int n) {
    hv_val *v = (hv_val *)calloc((size_t)(n ? n : 1), sizeof(hv_val));
    int i;
    for (i = 0; i < n; i++) v[i].refs = 1;
    return v;
}
/* Every value is back to the one reference the harness holds. */
static int vals_idle(const hv_val *v, int n) {
    int i;
    for (i = 0; i < n; i++) if (v[i].refs != 1) return 0;
    return 1;
}

static void named(int code, const char *what, int n, unsigned bits) {
    char name[160];
    snprintf(name, sizeof name, "%s: %d keys, %u hash bits", what, n, bits);
    ok(code == 0, name);
    if (code) printf("# failed at step %d\n", code);
}

static void t_map_small(void) {
    hamt_map m = { NULL, 0 };
    hv_val v1 = { 1, 0, NULL, NULL }, v2 = { 1, 0, NULL, NULL };
    hamt_node *before;
    long live = ha_live_blocks;
    int st;

    ok(m_entry(&m, "a") == NULL, "nothing is found in an empty map");
    ok(hamt_map_del(NULL, NULL, "a", 1, 0, 0, &st) == NULL && st == HAMT_DEL_ABSENT,
       "deleting from an empty map is ABSENT and still empty");
    ok(hamt_map_check(NULL, 0) == 0 && hamt_map_check(NULL, 1) == HAMT_CHK_COUNT,
       "the checker passes an empty map with a count of 0 and no other");

    ok(m_put(&m, "a", &v1) == 1 && m.count == 1, "a first key is added");
    ok(hamt_node_is_single(m.root) && m.root->refcnt == 1, "into a root of one entry");
    ok(m_entry(&m, "a") && m_entry(&m, "a")->val == &v1, "and found with its value");
    ok(m_entry(&m, "b") == NULL, "another key is not");
    ok(v1.refs == 2, "the map holds one reference to the value");

    before = m.root;
    ok(m_put(&m, "a", &v1) == 0 && m.root == before && m.count == 1,
       "the same value under the same key gives the same root back");
    ok(before->refcnt == 1, "with no reference gained or lost");

    ok(m_put(&m, "a", &v2) == 0 && m.count == 1 && m.root != before,
       "a different value replaces it in a new root");
    ok(m_entry(&m, "a")->val == &v2, "found with the new value");
    ok(v1.refs == 1 && v2.refs == 2, "the old value is given back");

    before = m.root;
    ok(m_del(&m, "zz") == HAMT_DEL_ABSENT && m.root == before && before->refcnt == 1,
       "deleting an absent key gives the same root back");

    m_put(&m, "b", &v1);
    m_put(&m, "c", &v1);
    ok(m.count == 3 && hamt_map_check(m.root, 3) == 0, "three keys check out");
    ok(m_del(&m, "a") == HAMT_DEL_DONE && m_del(&m, "b") == HAMT_DEL_DONE
       && m.count == 1 && hamt_map_check(m.root, 1) == 0, "two deleted, one left");
    ok(m_del(&m, "c") == HAMT_DEL_DONE && m.root == NULL && m.count == 0,
       "deleting the last key leaves a NULL root");
    ok(v1.refs == 1 && v2.refs == 1 && ha_live_blocks == live,
       "and nothing held or allocated");
}

/* Insert n, read them all, delete them all in another order, with the
 * checker run every `every` deletes. 0, or the step that failed. */
static int map_model(int n, unsigned bits, int every) {
    hamt_map m = { NULL, 0 };
    hv_val *v = vals_new(n);
    int *order = shuffled(n);
    long live = ha_live_blocks;
    int i, rc = 0;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n && !rc; i++)
        if (m_put(&m, keyn("key", i), &v[i]) != 1) rc = 1;
    if (!rc && (m.count != (size_t)n || hamt_map_check(m.root, (size_t)n))) rc = 2;
    for (i = 0; i < n && !rc; i++) {
        hamt_entry *e = m_entry(&m, keyn("key", i));
        if (!e || e->val != &v[i]) rc = 3;
    }
    for (i = 0; i < 200 && !rc; i++)
        if (m_entry(&m, keyn("nokey", i))) rc = 4;
    for (i = 0; i < 200 && !rc; i++)
        if (m_del(&m, keyn("nokey", i)) != HAMT_DEL_ABSENT) rc = 5;

    for (i = 0; i < n && !rc; i++) {
        if (m_del(&m, keyn("key", order[i])) != HAMT_DEL_DONE) rc = 6;
        else if (m_entry(&m, keyn("key", order[i]))) rc = 7;
        else if (v[order[i]].refs != 1) rc = 8;
        else if ((i % every == 0 || i > n - 40)
                 && hamt_map_check(m.root, (size_t)(n - 1 - i))) rc = 9;
        if (!rc && i == n / 2) {
            int j;
            for (j = 0; j < n && !rc; j++) {
                hamt_entry *e = m_entry(&m, keyn("key", order[j]));
                if (j <= i ? e != NULL : (!e || e->val != &v[order[j]])) rc = 10;
            }
        }
    }
    if (!rc && (m.root != NULL || m.count != 0)) rc = 11;
    m_free(&m);
    if (!rc && !vals_idle(v, n)) rc = 12;
    if (!rc && ha_live_blocks != live) rc = 13;
    hamt_hash_set_bits(64);
    free(order);
    free(v);
    return rc;
}

/* Every size from 1 up, checked after every single step: this is where a
 * node passes through each mix of entries and children on the way up and
 * each fold on the way down. */
static int map_sweep(int max, unsigned bits) {
    int n, i, rc = 0;
    hv_val v = { 1, 0, NULL, NULL };
    long live = ha_live_blocks;

    hamt_hash_set_bits(bits);
    for (n = 1; n <= max && !rc; n++) {
        hamt_map m = { NULL, 0 };
        for (i = 0; i < n && !rc; i++) {
            if (m_put(&m, keyn("key", i), &v) != 1) rc = 1;
            else if (hamt_map_check(m.root, (size_t)i + 1)) rc = 2;
        }
        for (i = 0; i < n && !rc; i++) {
            int k = (n & 1) ? n - 1 - i : i;
            if (m_del(&m, keyn("key", k)) != HAMT_DEL_DONE) rc = 3;
            else if (hamt_map_check(m.root, (size_t)(n - 1 - i))) rc = 4;
        }
        if (!rc && m.root) rc = 5;
        m_free(&m);
    }
    if (!rc && (v.refs != 1 || ha_live_blocks != live)) rc = 6;
    hamt_hash_set_bits(64);
    return rc;
}

static void t_map_model(void) {
    named(map_model(10000, 64, 50), "insert, read, delete", 10000, 64);
    named(map_model(2000, 64, 1), "insert, read, delete, checked each step", 2000, 64);
    named(map_model(2000, 10, 1), "insert, read, delete, checked each step", 2000, 10);
    named(map_model(2000, 5, 1), "insert, read, delete, checked each step", 2000, 5);
    named(map_model(500, 0, 1), "insert, read, delete, checked each step", 500, 0);
    named(map_sweep(150, 64), "every size up to", 150, 64);
    named(map_sweep(150, 10), "every size up to", 150, 10);
    named(map_sweep(150, 5), "every size up to", 150, 5);
    named(map_sweep(40, 0), "every size up to", 40, 0);
}

/* Old roots stay exactly what they were. */
static int map_persist(int n, unsigned bits) {
    hamt_map m = { NULL, 0 };
    hv_val *v = vals_new(n);
    int kept_n = n / 10, i, j, rc = 0, pass;
    hamt_node **kept = (hamt_node **)calloc((size_t)kept_n, sizeof *kept);
    long live = ha_live_blocks;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n && !rc; i++) {
        if (m_put(&m, keyn("key", i), &v[i]) != 1) rc = 1;
        if (i % 10 == 9) kept[i / 10] = hamt_node_retain(m.root);
    }
    /* Twice: once with the newest map alive, and once after it has been
     * emptied key by key, which copies and frees along every path. */
    for (pass = 0; pass < 2 && !rc; pass++) {
        for (j = 0; j < kept_n && !rc; j++) {
            int last = j * 10 + 9;
            hamt_map snap;
            snap.root = kept[j]; snap.count = (size_t)last + 1;
            if (hamt_map_check(snap.root, snap.count)) rc = 2;
            for (i = 0; i <= last && !rc; i++) {
                hamt_entry *e = m_entry(&snap, keyn("key", i));
                if (!e || e->val != &v[i]) rc = 3;
            }
            for (i = last + 1; i < n && i < last + 30 && !rc; i++)
                if (m_entry(&snap, keyn("key", i))) rc = 4;
            if (!rc && last + 1 < n && m_entry(&snap, keyn("key", n - 1))) rc = 5;
        }
        if (pass == 0)
            for (i = 0; i < n && !rc; i++)
                if (m_del(&m, keyn("key", (i * 7) % n)) != HAMT_DEL_DONE) rc = 6;
    }
    if (!rc && m.root) rc = 7;
    for (j = 0; j < kept_n; j++) if (kept[j]) hamt_node_release(NULL, kept[j]);
    m_free(&m);
    if (!rc && !vals_idle(v, n)) rc = 8;
    if (!rc && ha_live_blocks != live) rc = 9;
    hamt_hash_set_bits(64);
    free(kept);
    free(v);
    return rc;
}

static void t_map_persist(void) {
    /* 1999 is prime to 7, so (i * 7) % n visits every key once. */
    named(map_persist(1999, 64), "199 kept roots unchanged", 1999, 64);
    named(map_persist(1999, 10), "199 kept roots unchanged", 1999, 10);
    named(map_persist(1999, 5), "199 kept roots unchanged", 1999, 5);
    named(map_persist(499, 0), "49 kept roots unchanged", 499, 0);
}

/* Same bitmaps all the way down, and the same keys in the same places. */
static int same_shape(const hamt_node *a, const hamt_node *b) {
    uint32_t nd, N, i, j;
    if (a == b) return 1;
    if (!a || !b) return 0;
    if (a->datamap != b->datamap || a->nodemap != b->nodemap || a->ncoll != b->ncoll)
        return 0;
    nd = hamt_node_ndata(a);
    N  = hamt_node_nslots(a);
    if (a->ncoll) {
        for (i = 0; i < nd; i++) {
            const hamt_entry *e = (const hamt_entry *)a->slot[i];
            for (j = 0; j < nd; j++)
                if (hamt_entry_key_eq((const hamt_entry *)b->slot[j],
                                      e->key, e->klen, e->utf8, e->hash)) break;
            if (j == nd) return 0;
        }
        return 1;
    }
    for (i = 0; i < nd; i++) {
        const hamt_entry *e = (const hamt_entry *)a->slot[i];
        if (!hamt_entry_key_eq((const hamt_entry *)b->slot[i],
                               e->key, e->klen, e->utf8, e->hash)) return 0;
    }
    for (; i < N; i++)
        if (!same_shape((const hamt_node *)a->slot[i], (const hamt_node *)b->slot[i]))
            return 0;
    return 1;
}

static int map_canonical(int n, unsigned bits) {
    hamt_map a = { NULL, 0 }, b = { NULL, 0 }, c = { NULL, 0 };
    hv_val v = { 1, 0, NULL, NULL };
    int *order = shuffled(n);
    int i, rc = 0;
    long live = ha_live_blocks;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n; i++) m_put(&a, keyn("key", i), &v);

    /* b: another order, with strangers moving in and out along the way. */
    for (i = 0; i < n; i++) {
        m_put(&b, keyn("key", order[i]), &v);
        if (i % 3 == 0) m_put(&b, keyn("stranger", i), &v);
        if (i % 3 == 2) m_del(&b, keyn("stranger", i - 2));
    }
    for (i = 0; i < n; i++) m_del(&b, keyn("stranger", i));

    if (a.count != b.count) rc = 1;
    else if (hamt_map_check(a.root, a.count) || hamt_map_check(b.root, b.count)) rc = 2;
    else if (!same_shape(a.root, b.root)) rc = 3;

    /* c holds the even keys and never held anything else. a comes down to
     * the same keys by deletion, and has to arrive at the same shape. */
    for (i = 0; i < n; i += 2) m_put(&c, keyn("key", i), &v);
    for (i = 1; i < n; i += 2) m_del(&a, keyn("key", order[i] | 1));
    for (i = 1; i < n; i += 2) m_del(&a, keyn("key", i));
    if (!rc && a.count != c.count) rc = 4;
    if (!rc && hamt_map_check(a.root, a.count)) rc = 5;
    if (!rc && !same_shape(a.root, c.root)) rc = 6;

    /* And the check can fail: one key out of place is a different shape. */
    m_del(&c, keyn("key", 0));
    m_put(&c, keyn("key", 1), &v);
    if (!rc && same_shape(a.root, c.root)) rc = 7;

    m_free(&a); m_free(&b); m_free(&c);
    if (!rc && (v.refs != 1 || ha_live_blocks != live)) rc = 8;
    hamt_hash_set_bits(64);
    free(order);
    return rc;
}

static void t_map_canonical(void) {
    named(map_canonical(1000, 64), "one shape whatever the history", 1000, 64);
    named(map_canonical(1000, 10), "one shape whatever the history", 1000, 10);
    named(map_canonical(1000, 5), "one shape whatever the history", 1000, 5);
    named(map_canonical(300, 0), "one shape whatever the history", 300, 0);
}

/* Nodes reachable from `n` that are not the node at the same place in `o`. */
static int unshared(const hamt_node *n, const hamt_node *o) {
    uint32_t pos;
    int count = 1;
    if (n == o) return 0;
    if (n->ncoll) return 1;
    for (pos = 0; pos < 32; pos++) {
        uint32_t bit = (uint32_t)1 << pos;
        const hamt_node *nc, *oc = NULL;
        if (!(n->nodemap & bit)) continue;
        nc = (const hamt_node *)n->slot[hamt_node_nslots(n) - 1
                                        - hamt_popcnt32(n->nodemap & (bit - 1))];
        if (o && !o->ncoll && (o->nodemap & bit))
            oc = (const hamt_node *)o->slot[hamt_node_nslots(o) - 1
                                            - hamt_popcnt32(o->nodemap & (bit - 1))];
        count += unshared(nc, oc);
    }
    return count;
}

static int count_nodes(const hamt_node *n) { return n ? unshared(n, NULL) : 0; }

static void t_map_sharing(void) {
    hamt_map m = { NULL, 0 };
    hv_val v = { 1, 0, NULL, NULL }, w = { 1, 0, NULL, NULL };
    hamt_node *old;
    int i, total, u;

    for (i = 0; i < 10000; i++) m_put(&m, keyn("key", i), &v);
    total = count_nodes(m.root);
    ok(total > 300, "a 10,000-key map is some hundreds of nodes");

    old = hamt_node_retain(m.root);
    m_put(&m, "one more", &v);
    u = unshared(m.root, old);
    ok(u >= 1 && u <= 13, "adding a key copies one path: at most 13 nodes");
    printf("# %d of %d nodes not shared after one insert\n", u, total);
    {
        int shared = count_nodes(m.root) - u;
        ok(shared <= total && shared >= total - 13,
           "and every other node is the old map's own");
    }
    hamt_node_release(NULL, old);

    old = hamt_node_retain(m.root);
    m_put(&m, keyn("key", 4242), &w);
    u = unshared(m.root, old);
    ok(u >= 1 && u <= 13, "replacing a value copies one path");
    ok(m_entry(&m, keyn("key", 4242))->val == &w, "and the new map has the new value");
    {
        hamt_map snap; snap.root = old; snap.count = m.count;
        ok(m_entry(&snap, keyn("key", 4242))->val == &v, "while the old map has the old one");
    }
    hamt_node_release(NULL, old);

    old = hamt_node_retain(m.root);
    m_del(&m, keyn("key", 77));
    u = unshared(m.root, old);
    ok(u >= 1 && u <= 13, "deleting a key copies one path");
    hamt_node_release(NULL, old);

    m_free(&m);
    ok(v.refs == 1 && w.refs == 1, "all of it given back");
}

/* ---- hashes chosen by hand ---------------------------------------------
 *
 * The core takes the hash as an argument, so a test can put an entry
 * exactly where it wants one. */

static hamt_entry *synth(uint64_t hash, int tag) {
    char k[40];
    snprintf(k, sizeof k, "synth-%d", tag);
    return hamt_entry_new(NULL, k, strlen(k), 0, hash, NULL);
}
static int s_put(hamt_map *m, hamt_entry *e) {
    int added;
    hamt_node *old = m->root, *r = hamt_map_put(NULL, m->root, e, &added);
    if (!r) return -1;
    m->root = r; m->count += (size_t)added;
    if (old) hamt_node_release(NULL, old);
    return added;
}
static int s_del(hamt_map *m, const hamt_entry *e) {
    int st;
    hamt_node *old = m->root,
              *r = hamt_map_del(NULL, m->root, e->key, e->klen, 0, e->hash, &st);
    m->root = r;
    if (st == HAMT_DEL_DONE) m->count--;
    if (old) hamt_node_release(NULL, old);
    return st;
}
static int s_has(const hamt_map *m, const hamt_entry *e) {
    return hamt_map_find(m->root, e->key, e->klen, 0, e->hash) == e;
}
#define BITS3(a, b, c) (((uint32_t)1 << (a)) | ((uint32_t)1 << (b)) | ((uint32_t)1 << (c)))

/* A root with entries at positions 1, 15, 30 and children at 0, 16, 31:
 * three of each, so the first, a middle and the last of both are all
 * addressed, and a slot computed from the wrong end lands on the wrong
 * thing instead of on the only thing there. */
static void t_map_slots(void) {
    static const unsigned epos[3] = { 1, 15, 30 }, cpos[3] = { 0, 16, 31 };
    static const int order[9] = { 4, 8, 0, 6, 2, 7, 1, 5, 3 };
    hamt_map m = { NULL, 0 };
    hamt_entry *e[9];
    int i, good;
    long live = ha_live_blocks;

    for (i = 0; i < 3; i++) e[i] = synth(epos[i], i);
    for (i = 0; i < 3; i++) {
        e[3 + 2 * i] = synth(cpos[i] | (3u << 5), 3 + 2 * i);
        e[4 + 2 * i] = synth(cpos[i] | (7u << 5), 4 + 2 * i);
    }
    for (i = 0; i < 9; i++) s_put(&m, e[order[i]]);

    ok(m.count == 9 && hamt_map_check(m.root, 9) == 0, "nine placed entries check out");
    ok(m.root->datamap == BITS3(1, 15, 30) && m.root->nodemap == BITS3(0, 16, 31),
       "three entries and three children at the root, where they were put");
    good = 1;
    for (i = 0; i < 9; i++) if (!s_has(&m, e[i])) good = 0;
    ok(good, "each found: first, middle and last of both kinds");
    ok(m.root->slot[0] == e[0] && m.root->slot[1] == e[1] && m.root->slot[2] == e[2],
       "entries run up from the front");
    ok(((hamt_node *)m.root->slot[5])->slot[0] == e[3]
       && ((hamt_node *)m.root->slot[4])->slot[0] == e[5]
       && ((hamt_node *)m.root->slot[3])->slot[0] == e[7],
       "children run back from the end: the lowest position is the last slot");

    /* Fold the MIDDLE child first, then the last, then the first. */
    ok(s_del(&m, e[5]) == HAMT_DEL_DONE && hamt_map_check(m.root, 8) == 0
       && m.root->datamap == (BITS3(1, 15, 30) | (1u << 16))
       && m.root->nodemap == ((1u << 0) | (1u << 31)),
       "a middle child down to one entry folds into the root");
    ok(m.root->slot[2] == e[6] && m.root->slot[3] == e[2],
       "its survivor lands between the entries either side of it");
    ok(s_del(&m, e[8]) == HAMT_DEL_DONE && s_del(&m, e[3]) == HAMT_DEL_DONE
       && hamt_map_check(m.root, 6) == 0 && m.root->nodemap == 0,
       "and so do the last and the first");
    good = s_has(&m, e[0]) && s_has(&m, e[1]) && s_has(&m, e[2])
        && s_has(&m, e[4]) && s_has(&m, e[6]) && s_has(&m, e[7])
        && !hamt_map_find(m.root, e[3]->key, e[3]->klen, 0, e[3]->hash)
        && !hamt_map_find(m.root, e[5]->key, e[5]->klen, 0, e[5]->hash)
        && !hamt_map_find(m.root, e[8]->key, e[8]->klen, 0, e[8]->hash);
    ok(good, "six left and found, three gone");

    /* And back: an entry at the root's middle becomes a child again. */
    ok(s_put(&m, e[5]) == 1 && hamt_map_check(m.root, 7) == 0
       && m.root->nodemap == (1u << 16) && s_has(&m, e[5]) && s_has(&m, e[6]),
       "a second key at a folded position grows the child back");

    m_free(&m);
    for (i = 0; i < 9; i++) hamt_entry_release(NULL, e[i]);
    ok(ha_live_blocks == live, "nothing left allocated");
}

/* Sixty hash bits index twelve levels. Two keys that agree on all sixty
 * and differ only above them still end in one collision node, and have to
 * be told apart there by the whole hash and the key. */
static void t_map_deepest(void) {
    const uint64_t low = 0x0123456789abcdeULL;     /* sixty bits */
    hamt_map m = { NULL, 0 };
    hamt_entry *a = synth(low | ((uint64_t)1 << 60), 1);
    hamt_entry *b = synth(low | ((uint64_t)2 << 60), 2);
    hamt_entry *c = synth(low | ((uint64_t)1 << 60), 3);   /* a's hash exactly */
    const hamt_node *n;
    int depth = 0;
    long live;

    s_put(&m, a);
    live = ha_live_blocks;
    s_put(&m, b);
    ok(hamt_map_check(m.root, 2) == 0, "two keys sharing sixty hash bits check out");
    for (n = m.root; !n->ncoll; n = (const hamt_node *)n->slot[0]) depth++;
    ok(depth == 12 && n->ncoll == 2, "twelve single-child nodes down to a collision node of two");
    ok(ha_live_blocks == live + 12, "thirteen nodes where there was one");
    ok(s_has(&m, a) && s_has(&m, b), "both found");
    ok(!hamt_map_find(m.root, a->key, a->klen, 0, b->hash)
       && !hamt_map_find(m.root, b->key, b->klen, 0, a->hash),
       "neither found under the other's hash");

    s_put(&m, c);
    ok(hamt_map_check(m.root, 3) == 0 && s_has(&m, a) && s_has(&m, b) && s_has(&m, c),
       "a third with one of those hashes and another key joins them");

    ok(s_del(&m, b) == HAMT_DEL_DONE && hamt_map_check(m.root, 2) == 0
       && s_has(&m, a) && s_has(&m, c), "one deleted from three leaves a collision node of two");
    ok(s_del(&m, a) == HAMT_DEL_DONE && hamt_map_check(m.root, 1) == 0
       && hamt_node_is_single(m.root) && !m.root->ncoll && s_has(&m, c),
       "one deleted from two folds twelve levels to a root of one entry");
    ok(ha_live_blocks == live, "and the twelve nodes are gone");
    ok(m.root->datamap == HAMT_BIT(c->hash, 0), "the survivor is at its own position in the root");

    m_free(&m);
    hamt_entry_release(NULL, a);
    hamt_entry_release(NULL, b);
    hamt_entry_release(NULL, c);
}

/* ---- a value whose release uses the library ---------------------------- */

typedef struct mapcb {
    hamt_map *target;
    hv_val   *store;
    int       ran, found_before, put_rc, check_rc;
} mapcb;

static void mapcb_run(void *cx, hv_val *v) {
    mapcb *c = (mapcb *)v->on_release_arg;
    (void)cx;
    c->ran++;
    c->found_before = m_entry(c->target, "witness") != NULL;
    c->put_rc   = m_put(c->target, "from-callback", c->store);
    c->check_rc = hamt_map_check(c->target->root, c->target->count);
}

static void t_map_reenter(void) {
    hamt_map m = { NULL, 0 }, other = { NULL, 0 };
    hv_val plain = { 1, 0, NULL, NULL }, store = { 1, 0, NULL, NULL };
    hv_val loud  = { 1, 0, mapcb_run, NULL };
    mapcb c;
    int i;
    long live = ha_live_blocks;

    memset(&c, 0, sizeof c);
    c.store = &store;
    loud.on_release_arg = &c;

    /* 1: the callback uses ANOTHER map while this one is being torn down. */
    m_put(&other, "witness", &plain);
    for (i = 0; i < 200; i++) m_put(&m, keyn("key", i), &plain);
    m_put(&m, "loud", &loud);
    loud.refs--;                       /* the map's reference is the last */
    c.target = &other;
    m_free(&m);
    ok(c.ran == 1 && c.found_before && c.put_rc == 1 && c.check_rc == 0,
       "freeing a map runs a value's release, which reads and writes another map");
    ok(m_entry(&other, "from-callback") != NULL && other.count == 2, "and its write is there");

    /* 2: the callback uses THE SAME map, in the middle of a replace. */
    memset(&c, 0, sizeof c);
    c.store = &store;
    c.target = &m;
    loud.refs = 1; loud.released = 0;
    for (i = 0; i < 200; i++) m_put(&m, keyn("key", i), &plain);
    m_put(&m, "witness", &plain);
    m_put(&m, "loud", &loud);
    loud.refs--;
    m_put(&m, "loud", &plain);
    ok(c.ran == 1 && c.found_before && c.put_rc == 1 && c.check_rc == 0,
       "replacing a value runs its release, which reads and writes the same map");
    ok(m_entry(&m, "from-callback") && m_entry(&m, "loud")->val == &plain
       && m.count == 203 && hamt_map_check(m.root, 203) == 0,
       "and the map holds both the replacement and the callback's key");

    /* 3: and in the middle of a delete. */
    memset(&c, 0, sizeof c);
    c.store = &store;
    c.target = &m;
    m_del(&m, "from-callback");
    loud.refs = 1;
    m_put(&m, "loud", &loud);
    loud.refs--;
    m_del(&m, "loud");
    ok(c.ran == 1 && c.put_rc == 1 && c.check_rc == 0 && !m_entry(&m, "loud")
       && m_entry(&m, "from-callback") && hamt_map_check(m.root, m.count) == 0,
       "deleting a key runs its value's release, which writes the same map");

    m_free(&m);
    m_free(&other);
    ok(plain.refs == 1 && store.refs == 1 && ha_live_blocks == live, "all given back");
}

/* ---- no memory, at every allocation in turn ----------------------------
 *
 * Fail the first allocation an operation makes, then the second, and so on
 * until it gets through. After each failure the map must be the map it was:
 * same root, same count, same blocks live, same references held. */

typedef int (*map_op)(hamt_map *m, hv_val *v);
static int op_insert(hamt_map *m, hv_val *v)  { return m_put(m, "brand new key", v); }
static int op_replace(hamt_map *m, hv_val *v) { return m_put(m, "key-17", v); }
static int op_delete(hamt_map *m, hv_val *v)  { (void)v; return m_del(m, "key-17") == -1 ? -1 : 0; }

static int map_oom(map_op op, unsigned bits, int *failures) {
    hamt_map m = { NULL, 0 };
    hv_val plain = { 1, 0, NULL, NULL }, fresh = { 1, 0, NULL, NULL };
    int i, k, rc = 0, got = -1;

    hamt_hash_set_bits(bits);
    for (i = 0; i < 300; i++) m_put(&m, keyn("key", i), &plain);

    *failures = 0;
    for (k = 0; k < 200 && !rc; k++) {
        hamt_node *root = m.root;
        size_t count = m.count;
        long live = ha_live_blocks, held = hv_retains - hv_releases;

        ha_fail_at = ha_calls + k;
        got = op(&m, &fresh);
        ha_fail_at = -1;
        if (got != -1) break;

        (*failures)++;
        if (m.root != root || m.count != count) rc = 1;
        else if (ha_live_blocks != live) rc = 2;
        else if (hv_retains - hv_releases != held) rc = 3;
        else if (root->refcnt != 1) rc = 4;
        else if (hamt_map_check(m.root, m.count)) rc = 5;
        else if (fresh.refs != 1) rc = 6;
    }
    if (!rc && got == -1) rc = 7;
    if (!rc && *failures == 0) rc = 8;
    if (!rc && hamt_map_check(m.root, m.count)) rc = 9;
    m_free(&m);
    if (!rc && (plain.refs != 1 || fresh.refs != 1)) rc = 10;
    hamt_hash_set_bits(64);
    return rc;
}

static void t_map_oom(void) {
    static const unsigned bits[4] = { 64, 10, 5, 0 };
    static const char *what[3] = {
        "an insert survives every allocation failing in turn",
        "a replace survives every allocation failing in turn",
        "a delete survives every allocation failing in turn"
    };
    map_op ops[3];
    int b, o, failures;
    ops[0] = op_insert; ops[1] = op_replace; ops[2] = op_delete;
    for (b = 0; b < 4; b++)
        for (o = 0; o < 3; o++) {
            int rc = map_oom(ops[o], bits[b], &failures);
            named(rc, what[o], 300, bits[b]);
            printf("# %d allocations failed in turn\n", failures);
        }
}

/* The order a node goes in: freed first, and only then is what it held
 * released. A map of one key is one node and one entry, so when the value's
 * release runs, both must already be gone. */
static long order_live_at_callback = -1;
static void order_cb(void *cx, hv_val *v) {
    (void)cx; (void)v;
    order_live_at_callback = ha_live_blocks;
}

static void t_map_release_order(void) {
    hamt_map m = { NULL, 0 };
    hv_val loud = { 1, 0, order_cb, NULL };
    long live = ha_live_blocks;

    m_put(&m, "only", &loud);
    loud.refs--;
    m_free(&m);
    ok(order_live_at_callback == live,
       "a node is freed before the values under it are released");
}

/* Two keys that meet at one position and part some levels further down:
 * the insert builds a chain of nodes for them and then one more to hang it
 * from. Each of those allocations fails in turn. `part` is the depth at
 * which the two hashes differ; 12 means never, which ends in a collision
 * node instead. */
static int pair_oom(unsigned part, int *failures) {
    hamt_map m = { NULL, 0 };
    const uint64_t base = 0x0123456789abcdeULL;
    uint64_t other = part >= 12 ? base : base ^ ((uint64_t)1 << (HAMT_BITS * part));
    long live0 = ha_live_blocks;
    hamt_entry *a = synth(base, 1), *b = synth(other, 2), *c = synth(base ^ 1, 3);
    int k, rc = 0, got = -1;

    s_put(&m, c);                 /* a root that is more than one entry */
    s_put(&m, a);

    *failures = 0;
    for (k = 0; k < 40 && !rc; k++) {
        hamt_node *root = m.root;
        long live = ha_live_blocks;
        uint32_t ra = a->refcnt, rb = b->refcnt;

        ha_fail_at = ha_calls + k;
        got = s_put(&m, b);
        ha_fail_at = -1;
        if (got != -1) break;

        (*failures)++;
        if (m.root != root || m.count != 2) rc = 1;
        else if (ha_live_blocks != live) rc = 2;
        else if (a->refcnt != ra || b->refcnt != rb) rc = 3;
        else if (hamt_map_check(m.root, 2)) rc = 4;
    }
    if (!rc && got != 1) rc = 5;
    if (!rc && hamt_map_check(m.root, 3)) rc = 6;
    if (!rc && (!s_has(&m, a) || !s_has(&m, b) || !s_has(&m, c))) rc = 7;
    /* part levels of chain below the root, the node or collision node at
     * the end of it, and the root's own copy. */
    if (!rc && (unsigned)*failures != (part >= 12 ? 12 : part) + 1) rc = 8;

    m_free(&m);
    hamt_entry_release(NULL, a);
    hamt_entry_release(NULL, b);
    hamt_entry_release(NULL, c);
    if (!rc && ha_live_blocks != live0) rc = 9;
    return rc;
}

static void t_map_pair_oom(void) {
    static const unsigned parts[5] = { 1, 2, 6, 11, 12 };
    int i, failures;
    for (i = 0; i < 5; i++) {
        char name[120];
        int rc = pair_oom(parts[i], &failures);
        snprintf(name, sizeof name,
                 "two keys parting at depth %u: the insert survives each of %d failed allocations",
                 parts[i], failures);
        ok(rc == 0, name);
        if (rc) printf("# failed at step %d\n", rc);
    }
}

/* ---- the iterator ------------------------------------------------------ */

static int iter_run(int n, unsigned bits) {
    hamt_map m = { NULL, 0 };
    hv_val *v = vals_new(n);
    hamt_iter it, it2;
    hamt_entry *e;
    int i, rc = 0, seen = 0;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n; i++) m_put(&m, keyn("key", i), &v[i]);

    hamt_iter_init(&it, m.root);
    hamt_iter_init(&it2, m.root);
    while ((e = hamt_iter_next(&it))) {
        hv_val *val = (hv_val *)e->val;
        if (val < v || val >= v + n) { rc = 1; break; }
        if (val->released) { rc = 2; break; }       /* borrowed as a "seen" mark */
        val->released = 1;
        seen++;
        if (hamt_iter_next(&it2) != e) { rc = 3; break; }
    }
    if (!rc && seen != n) rc = 4;
    if (!rc && hamt_iter_next(&it) != NULL) rc = 5;
    if (!rc && hamt_iter_next(&it2) != NULL) rc = 6;
    for (i = 0; i < n && !rc; i++) if (!v[i].released) rc = 7;

    m_free(&m);
    hamt_hash_set_bits(64);
    free(v);
    return rc;
}

static void t_iter(void) {
    hamt_iter it;
    hamt_iter_init(&it, NULL);
    ok(hamt_iter_next(&it) == NULL && hamt_iter_next(&it) == NULL,
       "an empty trie has nothing to walk, however often it is asked");
    named(iter_run(1, 64), "every entry once, in the same order twice", 1, 64);
    named(iter_run(10000, 64), "every entry once, in the same order twice", 10000, 64);
    named(iter_run(2000, 10), "every entry once, in the same order twice", 2000, 10);
    named(iter_run(2000, 5), "every entry once, in the same order twice", 2000, 5);
    named(iter_run(300, 0), "every entry once, in the same order twice", 300, 0);
}

/* ---- two tries at once: equal, union, difference ----------------------- */

static int alg_equal(const hamt_map *a, const hamt_map *b, hamt_eq_fn eq, size_t *visits) {
    hamt_eq_ctx c;
    int rc;
    c.cx = NULL; c.eq = eq; c.ud = NULL; c.visits = 0;
    if (a->count != b->count) return 0;
    rc = hamt_node_equal(&c, a->root, b->root);
    if (visits) *visits = c.visits;
    return rc;
}

/* Calls any two values equal: enough to show the callback is what decides. */
static int eq_anything(void *ud, void *cx, void *va, void *vb) {
    (void)ud; (void)cx; (void)va; (void)vb;
    return 1;
}
static int eq_stop(void *ud, void *cx, void *va, void *vb) {
    (void)ud; (void)cx; (void)va; (void)vb;
    return -1;
}

static int equal_run(int n, unsigned bits) {
    hamt_map a = { NULL, 0 }, b = { NULL, 0 };
    hv_val *v = vals_new(n), other = { 1, 0, NULL, NULL };
    int *order = shuffled(n);
    int i, rc = 0;
    size_t visits = 0;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n; i++) m_put(&a, keyn("key", i), &v[i]);
    for (i = 0; i < n; i++) m_put(&b, keyn("key", order[i]), &v[order[i]]);

    if (alg_equal(&a, &a, NULL, &visits) != 1 || visits != 0) rc = 1;
    else if (alg_equal(&a, &b, NULL, NULL) != 1) rc = 2;
    else if (alg_equal(&b, &a, NULL, NULL) != 1) rc = 3;

    /* One value different, somewhere in the middle. */
    m_put(&b, keyn("key", n / 2), &other);
    if (!rc && alg_equal(&a, &b, NULL, NULL) != 0) rc = 4;
    if (!rc && alg_equal(&a, &b, eq_anything, NULL) != 1) rc = 5;
    if (!rc && alg_equal(&a, &b, eq_stop, NULL) >= 0) rc = 6;
    m_put(&b, keyn("key", n / 2), &v[n / 2]);
    if (!rc && alg_equal(&a, &b, NULL, NULL) != 1) rc = 7;

    /* One key different, the count the same. */
    m_del(&b, keyn("key", n / 3));
    m_put(&b, "a stranger", &v[n / 3]);
    if (!rc && alg_equal(&a, &b, NULL, NULL) != 0) rc = 8;
    if (!rc && alg_equal(&a, &b, eq_anything, NULL) != 0) rc = 9;

    /* One key fewer. */
    m_del(&b, "a stranger");
    if (!rc && alg_equal(&a, &b, NULL, NULL) != 0) rc = 10;

    /* A version one step away is compared along one path. */
    m_free(&b);
    b.root = hamt_node_retain(a.root); b.count = a.count;
    m_put(&b, keyn("key", n / 2), &other);
    visits = 0;
    if (!rc && (alg_equal(&a, &b, NULL, &visits) != 0 || visits > 13 || visits < 1)) rc = 11;
    if (!rc && (alg_equal(&a, &b, eq_anything, &visits) != 1 || visits > 13 || visits < 1)) rc = 12;

    m_free(&a); m_free(&b);
    if (!rc && (!vals_idle(v, n) || other.refs != 1)) rc = 13;

    /* Two maps of one shape whose keys differ: same hash, same position,
     * same value, another key. Only comparing the keys can tell them apart,
     * and only a hash chosen by hand can build the case. */
    if (!rc) {
        hamt_map x = { NULL, 0 }, y = { NULL, 0 };
        hamt_entry *ex[3], *ey[3];
        int k;
        for (k = 0; k < 3; k++) {
            ex[k] = synth(0x40 + (uint64_t)k, k);
            ey[k] = synth(0x40 + (uint64_t)k, k == 1 ? 99 : k);
            s_put(&x, ex[k]);
            s_put(&y, ey[k]);
        }
        if (!same_shape(x.root, x.root) || x.root->datamap != y.root->datamap) rc = 14;
        else if (alg_equal(&x, &y, NULL, NULL) != 0) rc = 15;
        else if (alg_equal(&x, &y, eq_anything, NULL) != 0) rc = 16;
        m_free(&x); m_free(&y);
        for (k = 0; k < 3; k++) { hamt_entry_release(NULL, ex[k]); hamt_entry_release(NULL, ey[k]); }
    }
    hamt_hash_set_bits(64);
    free(order); free(v);
    return rc;
}

/* resolvers */
static int resolve_calls = 0, resolve_stop_at = -1;
static int resolve_first(void *ud, void *cx, hamt_entry *ea, hamt_entry *eb, hamt_entry **out) {
    (void)ud; (void)cx; (void)eb;
    if (resolve_calls++ == resolve_stop_at) return HAMT_ERR_ABORT;
    *out = hamt_entry_retain(ea);
    return HAMT_OK;
}
/* A brand new entry under the same key, holding the value passed as ud. */
static int resolve_fresh(void *ud, void *cx, hamt_entry *ea, hamt_entry *eb, hamt_entry **out) {
    (void)eb;
    resolve_calls++;
    *out = hamt_entry_new(cx, ea->key, ea->klen, ea->utf8, ea->hash, ud);
    return *out ? HAMT_OK : HAMT_ERR_OOM;
}

static hamt_entry *synth(uint64_t hash, int tag);
static int s_put(hamt_map *m, hamt_entry *e);

static hamt_node *alg_merge(hamt_merge_ctx *c, const hamt_map *a, const hamt_map *b,
                            hamt_resolve_fn fn, void *ud) {
    c->cx = NULL; c->resolve = fn; c->ud = ud;
    return hamt_map_merge(c, a->root, b->root);
}

/* a holds keys [0, n), b holds [n/2, n + n/2): half of each is shared. */
static int merge_run(int n, unsigned bits) {
    hamt_map a = { NULL, 0 }, b = { NULL, 0 }, r = { NULL, 0 }, built = { NULL, 0 };
    hv_val *va = vals_new(n + n / 2), *vb = vals_new(n + n / 2);
    hv_val fresh = { 1, 0, NULL, NULL };
    hamt_merge_ctx c;
    int i, rc = 0, total = n + n / 2, shared = n - n / 2;
    long live;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n; i++) m_put(&a, keyn("key", i), &va[i]);
    for (i = n / 2; i < total; i++) m_put(&b, keyn("key", i), &vb[i]);
    live = ha_live_blocks;

    /* No resolver: the second map wins. */
    r.root = alg_merge(&c, &a, &b, NULL, NULL);
    r.count = a.count + c.added;
    if (!r.root || c.err) rc = 1;
    else if (r.count != (size_t)total) rc = 2;
    else if (hamt_map_check(r.root, r.count)) rc = 3;
    for (i = 0; i < total && !rc; i++) {
        hamt_entry *e = m_entry(&r, keyn("key", i));
        if (!e || e->val != (i < n / 2 ? &va[i] : &vb[i])) rc = 4;
    }
    /* The same shape as a map that was simply built that way. */
    for (i = 0; i < total; i++) m_put(&built, keyn("key", i), i < n / 2 ? &va[i] : &vb[i]);
    if (!rc && !same_shape(r.root, built.root)) rc = 5;
    m_free(&built);
    m_free(&r);

    /* A resolver that keeps the first map's: called once per shared key. */
    resolve_calls = 0; resolve_stop_at = -1;
    r.root = alg_merge(&c, &a, &b, resolve_first, NULL);
    r.count = a.count + c.added;
    if (!rc && (!r.root || r.count != (size_t)total || hamt_map_check(r.root, r.count))) rc = 6;
    if (!rc && resolve_calls != shared) rc = 7;
    for (i = 0; i < total && !rc; i++) {
        hamt_entry *e = m_entry(&r, keyn("key", i));
        if (!e || e->val != (i < n ? &va[i] : &vb[i])) rc = 8;
    }
    m_free(&r);

    /* A resolver that makes a new entry. */
    resolve_calls = 0;
    r.root = alg_merge(&c, &a, &b, resolve_fresh, &fresh);
    r.count = a.count + c.added;
    if (!rc && (!r.root || r.count != (size_t)total || hamt_map_check(r.root, r.count))) rc = 9;
    for (i = 0; i < total && !rc; i++) {
        hamt_entry *e = m_entry(&r, keyn("key", i));
        hv_val *want = i < n / 2 ? &va[i] : i < n ? &fresh : &vb[i];
        if (!e || e->val != want) rc = 10;
    }
    if (!rc && fresh.refs != 1 + shared) rc = 11;
    m_free(&r);
    if (!rc && fresh.refs != 1) rc = 12;

    /* A resolver that stops, at its first call, in the middle, at its last:
     * nothing comes back and nothing is left behind. */
    for (i = 0; i < 3 && !rc; i++) {
        long held = hv_retains - hv_releases;
        resolve_calls = 0;
        resolve_stop_at = i == 0 ? 0 : i == 1 ? shared / 2 : shared - 1;
        r.root = alg_merge(&c, &a, &b, resolve_first, NULL);
        if (r.root || c.err != HAMT_ERR_ABORT) { rc = 13; if (r.root) hamt_node_release(NULL, r.root); r.root = NULL; }
        else if (ha_live_blocks != live) rc = 14;
        else if (hv_retains - hv_releases != held) rc = 15;
    }
    resolve_stop_at = -1;
    if (!rc && (hamt_map_check(a.root, a.count) || hamt_map_check(b.root, b.count))) rc = 16;

    m_free(&a); m_free(&b);
    if (!rc && (!vals_idle(va, total) || !vals_idle(vb, total))) rc = 17;
    hamt_hash_set_bits(64);
    free(va); free(vb);
    return rc;
}

/* The answers that are one of the operands. */
static int merge_identity(int n, unsigned bits) {
    hamt_map a = { NULL, 0 }, b = { NULL, 0 }, e = { NULL, 0 };
    hv_val v = { 1, 0, NULL, NULL }, w = { 1, 0, NULL, NULL };
    hamt_merge_ctx c;
    hamt_node *r;
    int i, rc = 0;
    long live;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n; i++) m_put(&a, keyn("key", i), &v);
    /* b is a with more keys: it holds every ENTRY a holds, the very same. */
    b.root = hamt_node_retain(a.root); b.count = a.count;
    for (i = 0; i < n / 4 + 1; i++) m_put(&b, keyn("extra", i), &w);
    live = ha_live_blocks;

    r = alg_merge(&c, &a, &a, NULL, NULL);
    if (r != a.root || c.added || c.visits) rc = 1;
    if (r) hamt_node_release(NULL, r);

    r = alg_merge(&c, &b, &a, NULL, NULL);          /* the second adds nothing */
    if (!rc && (r != b.root || c.added)) rc = 2;
    if (r) hamt_node_release(NULL, r);

    r = alg_merge(&c, &a, &b, NULL, NULL);          /* the result is the second */
    if (!rc && (r != b.root || c.added != (size_t)(n / 4 + 1))) rc = 3;
    if (r) hamt_node_release(NULL, r);

    r = alg_merge(&c, &a, &e, NULL, NULL);          /* an empty second */
    if (!rc && (r != a.root || c.added)) rc = 4;
    if (r) hamt_node_release(NULL, r);

    r = alg_merge(&c, &e, &a, NULL, NULL);          /* an empty first */
    if (!rc && (r != a.root || c.added != a.count)) rc = 5;
    if (r) hamt_node_release(NULL, r);

    r = alg_merge(&c, &e, &e, NULL, NULL);
    if (!rc && (r != NULL || c.err || c.added)) rc = 6;

    if (!rc && ha_live_blocks != live) rc = 7;      /* none of it allocated */

    /* Two versions one key apart: one path looked at, whichever way round. */
    m_free(&b);
    b.root = hamt_node_retain(a.root); b.count = a.count;
    m_put(&b, keyn("key", n / 2), &w);
    r = alg_merge(&c, &a, &b, NULL, NULL);
    if (!rc && (r != b.root || c.visits > 13 || c.visits < 1 || c.added)) rc = 8;
    if (r) hamt_node_release(NULL, r);
    resolve_calls = 0; resolve_stop_at = -1;
    r = alg_merge(&c, &a, &b, resolve_first, NULL);
    if (!rc && (r != a.root || c.visits > 13 || resolve_calls != 1)) rc = 9;
    if (r) hamt_node_release(NULL, r);

    /* The same keys and the very same VALUES, built separately: every entry
     * is another object, nothing is shared, and still there is nothing to
     * choose between, so the resolver is never asked and the first map is
     * the answer. */
    m_free(&b);
    for (i = 0; i < n; i++) m_put(&b, keyn("key", n - 1 - i), &v);
    resolve_calls = 0; resolve_stop_at = -1;
    r = alg_merge(&c, &a, &b, resolve_first, NULL);
    if (!rc && (r != a.root || resolve_calls != 0 || c.added)) rc = 11;
    if (r) hamt_node_release(NULL, r);
    r = alg_merge(&c, &a, &b, NULL, NULL);
    if (!rc && (r != a.root || c.added)) rc = 12;
    if (r) hamt_node_release(NULL, r);

    m_free(&a); m_free(&b);
    if (!rc && (v.refs != 1 || w.refs != 1)) rc = 10;
    hamt_hash_set_bits(64);
    return rc;
}

/* Every allocation in a merge fails in turn. */
static int merge_oom(int n, unsigned bits, int *failures) {
    hamt_map a = { NULL, 0 }, b = { NULL, 0 }, r = { NULL, 0 };
    hv_val v = { 1, 0, NULL, NULL }, w = { 1, 0, NULL, NULL }, fresh = { 1, 0, NULL, NULL };
    hamt_merge_ctx c;
    int i, k, rc = 0, done = 0;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n; i++) m_put(&a, keyn("key", i), &v);
    for (i = n / 2; i < n + n / 2; i++) m_put(&b, keyn("key", i), &w);

    *failures = 0;
    for (k = 0; k < 20000 && !rc && !done; k++) {
        long live = ha_live_blocks, held = hv_retains - hv_releases;
        ha_fail_at = ha_calls + k;
        r.root = alg_merge(&c, &a, &b, resolve_fresh, &fresh);
        ha_fail_at = -1;
        if (r.root) { done = 1; break; }
        (*failures)++;
        if (c.err != HAMT_ERR_OOM) rc = 1;
        else if (ha_live_blocks != live) rc = 2;
        else if (hv_retains - hv_releases != held) rc = 3;
    }
    if (!rc && !done) rc = 4;
    if (!rc && *failures == 0) rc = 5;
    r.count = a.count + c.added;
    if (!rc && (r.count != (size_t)(n + n / 2) || hamt_map_check(r.root, r.count))) rc = 6;
    if (!rc && (hamt_map_check(a.root, a.count) || hamt_map_check(b.root, b.count))) rc = 7;
    m_free(&r); m_free(&a); m_free(&b);
    if (!rc && (v.refs != 1 || w.refs != 1 || fresh.refs != 1)) rc = 8;
    hamt_hash_set_bits(64);
    return rc;
}

/* difference */
typedef struct diff_tally { int add, remove, change, stop_after, calls, bad; hv_val *lo, *hi; } diff_tally;
static int diff_cb(void *ud, void *cx, int kind, hamt_entry *ea, hamt_entry *eb) {
    diff_tally *t = (diff_tally *)ud;
    (void)cx;
    if (kind == HAMT_DIFF_ADD)         { t->add++;    if (ea || !eb) t->bad = 1; }
    else if (kind == HAMT_DIFF_REMOVE) { t->remove++; if (!ea || eb) t->bad = 1; }
    else if (kind == HAMT_DIFF_CHANGE) {
        t->change++;
        if (!ea || !eb || ea->val == eb->val
            || !hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) t->bad = 1;
    }
    else t->bad = 1;
    return ++t->calls == t->stop_after ? HAMT_ERR_ABORT : 0;
}

static int alg_diff(const hamt_map *a, const hamt_map *b, diff_tally *t, size_t *visits) {
    hamt_diff_ctx c;
    int rc;
    memset(t, 0, sizeof *t);
    t->stop_after = -1;
    c.cx = NULL; c.fn = diff_cb; c.ud = t;
    c.eq.cx = NULL; c.eq.eq = NULL; c.eq.ud = NULL;
    rc = hamt_map_diff(&c, a->root, b->root);
    if (visits) *visits = c.visits;
    if (c.reported != (size_t)t->calls) t->bad = 1;
    return rc;
}

/* a holds [0, n) and b holds [n/2, n + n/2); of the shared half, every
 * third key has another value in b. */
static int diff_run(int n, unsigned bits) {
    hamt_map a = { NULL, 0 }, b = { NULL, 0 }, e = { NULL, 0 };
    hv_val v = { 1, 0, NULL, NULL }, w = { 1, 0, NULL, NULL };
    diff_tally t;
    hamt_diff_ctx c;
    size_t visits;
    int i, rc = 0, changed = 0, total = n + n / 2;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n; i++) m_put(&a, keyn("key", i), &v);
    for (i = n / 2; i < total; i++) {
        int differs = i < n && i % 3 == 0;
        m_put(&b, keyn("key", i), differs ? &w : &v);
        changed += differs;
    }

    if (alg_diff(&a, &b, &t, NULL) || t.bad) rc = 1;
    else if (t.remove != n / 2 || t.add != total - n || t.change != changed) rc = 2;
    if (!rc && (alg_diff(&b, &a, &t, NULL) || t.bad)) rc = 3;
    if (!rc && (t.add != n / 2 || t.remove != total - n || t.change != changed)) rc = 4;

    if (!rc && (alg_diff(&a, &a, &t, &visits) || t.calls || visits)) rc = 5;
    if (!rc && (alg_diff(&e, &a, &t, NULL) || t.add != n || t.calls != n)) rc = 6;
    if (!rc && (alg_diff(&a, &e, &t, NULL) || t.remove != n || t.calls != n)) rc = 7;
    if (!rc && (alg_diff(&e, &e, &t, NULL) || t.calls)) rc = 8;

    /* Stopping stops. */
    memset(&t, 0, sizeof t);
    t.stop_after = 3;
    c.cx = NULL; c.fn = diff_cb; c.ud = &t;
    c.eq.cx = NULL; c.eq.eq = NULL; c.eq.ud = NULL;
    if (!rc && (hamt_map_diff(&c, a.root, b.root) != HAMT_ERR_ABORT || t.calls != 3)) rc = 9;

    /* One step apart: one report, along one path, for each kind of step. */
    m_free(&b);
    b.root = hamt_node_retain(a.root); b.count = a.count;
    m_put(&b, keyn("key", n / 2), &w);
    if (!rc && (alg_diff(&a, &b, &t, &visits) || t.change != 1 || t.calls != 1 || visits > 13)) rc = 10;
    /* The value put back: the path is new nodes again, holding what the old
     * ones held, so it is walked and nothing is reported. */
    m_put(&b, keyn("key", n / 2), &v);
    if (!rc && (alg_diff(&a, &b, &t, &visits) || t.calls != 0 || visits > 13 || visits < 1)) rc = 11;
    /* Each of the next two starts from a again, so that one path differs
     * and not that one and the last one's. */
    m_free(&b);
    b.root = hamt_node_retain(a.root); b.count = a.count;
    m_put(&b, "one more", &v);
    if (!rc && (alg_diff(&a, &b, &t, &visits) || t.add != 1 || t.calls != 1 || visits > 13)) rc = 12;
    m_free(&b);
    b.root = hamt_node_retain(a.root); b.count = a.count;
    m_del(&b, keyn("key", n / 3));
    if (!rc && (alg_diff(&a, &b, &t, &visits) || t.remove != 1 || t.calls != 1 || visits > 13)) rc = 13;

    m_free(&a); m_free(&b);
    if (!rc && (v.refs != 1 || w.refs != 1)) rc = 14;
    hamt_hash_set_bits(64);
    return rc;
}

static void t_algebra(void) {
    static const unsigned bits[4] = { 64, 10, 5, 0 };
    static const int size[4] = { 2000, 2000, 1000, 200 };
    int i, failures;
    for (i = 0; i < 4; i++) {
        int rc;
        named(equal_run(size[i], bits[i]), "equal, and not equal in each way", size[i], bits[i]);
        named(merge_run(size[i], bits[i]), "union with and without a resolver", size[i], bits[i]);
        named(merge_identity(size[i], bits[i]), "a union that is one of its operands", size[i], bits[i]);
        named(diff_run(size[i], bits[i]), "difference, both ways and one step apart", size[i], bits[i]);
        rc = merge_oom(i == 3 ? 60 : 120, bits[i], &failures);
        named(rc, "a union survives every allocation failing in turn", i == 3 ? 60 : 120, bits[i]);
        printf("# %d allocations failed in turn\n", failures);
    }
    named(equal_run(1, 64), "equal, and not equal in each way", 1, 64);
    named(merge_run(2, 64), "union with and without a resolver", 2, 64);
    named(merge_run(7, 5), "union with and without a resolver", 7, 5);
    named(diff_run(4, 64), "difference, both ways and one step apart", 4, 64);
}

/* ---- changing a trie where it stands ----------------------------------- */

/* 1 added, 0 replaced or unchanged, -1 no memory. The displaced entry is
 * released last, with the new root already in the handle. */
static int t_put(hamt_map *m, const char *key, hv_val *v) {
    size_t n = strlen(key);
    int added;
    hamt_entry *dead, *e = hamt_entry_new(NULL, key, n, 0, hamt_hash(key, n, 0), v);
    if (!e) return -1;
    if (hamt_map_put_mut(NULL, &m->root, e, &added, &dead)) {
        hamt_entry_release(NULL, e);
        return -1;
    }
    hamt_entry_release(NULL, e);
    m->count += (size_t)added;
    if (dead) hamt_entry_release(NULL, dead);
    return added;
}

static int t_del(hamt_map *m, const char *key) {
    size_t n = strlen(key);
    hamt_entry *dead;
    int st = hamt_map_del_mut(NULL, &m->root, key, n, 0, hamt_hash(key, n, 0), &dead);
    if (st == HAMT_DEL_OOM) return -1;
    if (st == HAMT_DEL_DONE) m->count--;
    if (dead) hamt_entry_release(NULL, dead);
    return st;
}

/* The model run of the copying functions, through the in-place ones, on a
 * trie nobody else holds. The result must be the very shape the copying
 * functions build. */
static int mut_model(int n, unsigned bits, int every) {
    hamt_map m = { NULL, 0 }, ref = { NULL, 0 };
    hv_val *v = vals_new(n), other = { 1, 0, NULL, NULL };
    int *order = shuffled(n);
    long live = ha_live_blocks;
    int i, rc = 0;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n && !rc; i++) {
        if (t_put(&m, keyn("key", i), &v[i]) != 1) rc = 1;
        else if (every == 1 && hamt_map_check(m.root, (size_t)i + 1)) rc = 2;
    }
    for (i = 0; i < n; i++) m_put(&ref, keyn("key", i), &v[i]);
    if (!rc && (m.count != (size_t)n || hamt_map_check(m.root, m.count))) rc = 3;
    if (!rc && !same_shape(m.root, ref.root)) rc = 4;
    for (i = 0; i < n && !rc; i++) {
        hamt_entry *e = m_entry(&m, keyn("key", i));
        if (!e || e->val != &v[i]) rc = 5;
    }

    /* Replace half the values, and replace a value with itself. */
    for (i = 0; i < n && !rc; i += 2) {
        if (t_put(&m, keyn("key", i), &other) != 0) rc = 6;
        else if (v[i].refs != 2) rc = 7;         /* the reference map still has it */
        else if (m_entry(&m, keyn("key", i))->val != &other) rc = 8;
    }
    for (i = 0; i < n && !rc; i += 2) {
        hamt_node *root = m.root;
        long calls = ha_calls;
        if (t_put(&m, keyn("key", i), &other) != 0 || m.root != root) rc = 9;
        else if (ha_calls != calls + 1) rc = 10;   /* the entry and nothing else */
    }
    for (i = 0; i < n && !rc; i += 2) if (t_put(&m, keyn("key", i), &v[i]) != 0) rc = 11;
    if (!rc && (hamt_map_check(m.root, m.count) || !same_shape(m.root, ref.root))) rc = 12;
    m_free(&ref);

    for (i = 0; i < 100 && !rc; i++) {
        hamt_node *root = m.root;
        if (t_del(&m, keyn("nokey", i)) != HAMT_DEL_ABSENT || m.root != root) rc = 13;
    }
    for (i = 0; i < n && !rc; i++) {
        if (t_del(&m, keyn("key", order[i])) != HAMT_DEL_DONE) rc = 14;
        else if (m_entry(&m, keyn("key", order[i]))) rc = 15;
        else if (v[order[i]].refs != 1) rc = 16;
        else if ((i % every == 0 || i > n - 40)
                 && hamt_map_check(m.root, (size_t)(n - 1 - i))) rc = 17;
        if (!rc && i == n / 2) {
            /* What is left has to be the shape of a map that only ever
             * held what is left. */
            int j;
            for (j = i + 1; j < n; j++) m_put(&ref, keyn("key", order[j]), &v[order[j]]);
            if (!same_shape(m.root, ref.root)) rc = 18;
            m_free(&ref);
        }
    }
    if (!rc && (m.root != NULL || m.count != 0)) rc = 19;
    m_free(&m);
    if (!rc && (!vals_idle(v, n) || other.refs != 1)) rc = 20;
    if (!rc && ha_live_blocks != live) rc = 21;
    hamt_hash_set_bits(64);
    free(order); free(v);
    return rc;
}

/* The same updates, with a snapshot taken every ten steps: each snapshot is
 * another holder of the root, so the next update has to copy and leave it
 * alone, and the one after may edit in place again. Every snapshot is then
 * read back, after the live trie has been emptied through the in-place
 * delete as well. */
static int mut_snapshots(int n, unsigned bits) {
    hamt_map m = { NULL, 0 };
    hv_val *v = vals_new(n);
    int kept_n = n / 10, i, j, rc = 0, pass;
    hamt_node **kept = (hamt_node **)calloc((size_t)(kept_n ? kept_n : 1), sizeof *kept);
    long live = ha_live_blocks;

    hamt_hash_set_bits(bits);
    for (i = 0; i < n && !rc; i++) {
        if (t_put(&m, keyn("key", i), &v[i]) != 1) rc = 1;
        if (i % 10 == 9) kept[i / 10] = hamt_node_retain(m.root);
    }
    for (pass = 0; pass < 2 && !rc; pass++) {
        for (j = 0; j < kept_n && !rc; j++) {
            int last = j * 10 + 9;
            hamt_map snap;
            snap.root = kept[j]; snap.count = (size_t)last + 1;
            if (hamt_map_check(snap.root, snap.count)) rc = 2;
            for (i = 0; i <= last && !rc; i++) {
                hamt_entry *e = m_entry(&snap, keyn("key", i));
                if (!e || e->val != &v[i]) rc = 3;
            }
            for (i = last + 1; i < n && i < last + 30 && !rc; i++)
                if (m_entry(&snap, keyn("key", i))) rc = 4;
        }
        if (pass == 0)
            for (i = 0; i < n && !rc; i++)
                if (t_del(&m, keyn("key", (i * 7) % n)) != HAMT_DEL_DONE) rc = 5;
    }
    if (!rc && m.root) rc = 6;
    for (j = 0; j < kept_n; j++) if (kept[j]) hamt_node_release(NULL, kept[j]);
    m_free(&m);
    if (!rc && !vals_idle(v, n)) rc = 7;
    if (!rc && ha_live_blocks != live) rc = 8;
    hamt_hash_set_bits(64);
    free(kept); free(v);
    return rc;
}

/* What it is for: a trie built in place allocates far less. */
static void t_mut_allocs(void) {
    hamt_map m = { NULL, 0 }, p = { NULL, 0 };
    hv_val v = { 1, 0, NULL, NULL };
    int i, n = 100000;
    long c0, in_place, copying;

    c0 = ha_calls;
    for (i = 0; i < n; i++) t_put(&m, keyn("key", i), &v);
    in_place = ha_calls - c0 - n;                /* less the n entries */
    c0 = ha_calls;
    for (i = 0; i < n; i++) m_put(&p, keyn("key", i), &v);
    copying = ha_calls - c0 - n;

    printf("# %d keys: %ld node allocations in place, %ld copying\n", n, in_place, copying);
    ok(hamt_map_check(m.root, (size_t)n) == 0 && same_shape(m.root, p.root),
       "100,000 keys in place make the trie that copying makes");
    ok(in_place <= n + n / 4, "with about one node allocation for each key");
    ok(in_place * 2 < copying, "which is under half of what copying a path each time costs");
    m_free(&m); m_free(&p);
    ok(v.refs == 1, "and all given back");
}

/* A value whose release writes to the handle it is being released from. */
static void mutcb_run(void *cx, hv_val *v) {
    mapcb *c = (mapcb *)v->on_release_arg;
    (void)cx;
    c->ran++;
    c->found_before = m_entry(c->target, "witness") != NULL;
    c->put_rc   = t_put(c->target, "from-callback", c->store);
    c->check_rc = hamt_map_check(c->target->root, c->target->count);
}

static void t_mut_reenter(void) {
    hamt_map m = { NULL, 0 };
    hv_val plain = { 1, 0, NULL, NULL }, store = { 1, 0, NULL, NULL };
    hv_val loud  = { 1, 0, mutcb_run, NULL };
    mapcb c;
    unsigned b;
    static const unsigned bits[3] = { 64, 5, 0 };
    int i;

    loud.on_release_arg = &c;
    for (b = 0; b < 3; b++) {
        char name[160];
        int good;
        hamt_hash_set_bits(bits[b]);

        memset(&c, 0, sizeof c); c.store = &store; c.target = &m;
        for (i = 0; i < 100; i++) t_put(&m, keyn("key", i), &plain);
        t_put(&m, "witness", &plain);
        loud.refs = 1; t_put(&m, "loud", &loud); loud.refs--;
        t_put(&m, "loud", &plain);                 /* replace: loud is released */
        good = c.ran == 1 && c.found_before && c.put_rc == 1 && c.check_rc == 0
            && m_entry(&m, "from-callback") && m_entry(&m, "loud")->val == &plain
            && hamt_map_check(m.root, m.count) == 0 && m.count == 103;
        snprintf(name, sizeof name,
                 "a value released by an in-place replace writes to the same handle: %u hash bits", bits[b]);
        ok(good, name);

        memset(&c, 0, sizeof c); c.store = &store; c.target = &m;
        t_del(&m, "from-callback");
        loud.refs = 1; t_put(&m, "loud", &loud); loud.refs--;
        t_del(&m, "loud");                         /* delete: loud is released */
        good = c.ran == 1 && c.put_rc == 1 && c.check_rc == 0 && !m_entry(&m, "loud")
            && m_entry(&m, "from-callback") && hamt_map_check(m.root, m.count) == 0;
        snprintf(name, sizeof name,
                 "a value released by an in-place delete writes to the same handle: %u hash bits", bits[b]);
        ok(good, name);
        m_free(&m);
    }
    hamt_hash_set_bits(64);
    ok(plain.refs == 1 && store.refs == 1, "all given back");
}

/* No memory, at every allocation in turn, on a trie that is the handle's
 * alone and on one a snapshot also holds. After each failure everything is
 * as it was - which for an in-place edit means nothing was edited. */
typedef int (*mut_op)(hamt_map *m, hv_val *v);
static int mop_insert(hamt_map *m, hv_val *v)  { return t_put(m, "brand new key", v); }
static int mop_replace(hamt_map *m, hv_val *v) { return t_put(m, "key-17", v); }
static int mop_delete(hamt_map *m, hv_val *v)  { (void)v; return t_del(m, "key-17") == -1 ? -1 : 0; }

static int mut_oom(mut_op op, unsigned bits, int shared, int *failures) {
    hamt_map m = { NULL, 0 }, ref = { NULL, 0 };
    hv_val plain = { 1, 0, NULL, NULL }, fresh = { 1, 0, NULL, NULL };
    hamt_node *snap = NULL;
    int i, k, rc = 0, got = -1;

    hamt_hash_set_bits(bits);
    for (i = 0; i < 300; i++) { t_put(&m, keyn("key", i), &plain); m_put(&ref, keyn("key", i), &plain); }
    if (shared) snap = hamt_node_retain(m.root);

    *failures = 0;
    for (k = 0; k < 200 && !rc; k++) {
        hamt_node *root = m.root;
        size_t count = m.count;
        long live = ha_live_blocks, held = hv_retains - hv_releases;

        ha_fail_at = ha_calls + k;
        got = op(&m, &fresh);
        ha_fail_at = -1;
        if (got != -1) break;

        (*failures)++;
        if (m.root != root || m.count != count) rc = 1;
        else if (ha_live_blocks != live) rc = 2;
        else if (hv_retains - hv_releases != held) rc = 3;
        else if (hamt_map_check(m.root, m.count)) rc = 4;
        else if (!same_shape(m.root, ref.root)) rc = 5;   /* nothing was half done */
        else if (fresh.refs != 1) rc = 6;
    }
    if (!rc && got == -1) rc = 7;
    /* No failures at all is a pass too: an update that finds room where the
     * node stands allocates nothing but its entry, and a delete nothing. */
    if (!rc && hamt_map_check(m.root, m.count)) rc = 9;
    if (!rc && snap && (hamt_map_check(snap, 300) || !same_shape(snap, ref.root))) rc = 10;
    if (snap) hamt_node_release(NULL, snap);
    m_free(&m); m_free(&ref);
    if (!rc && (plain.refs != 1 || fresh.refs != 1)) rc = 11;
    hamt_hash_set_bits(64);
    return rc;
}

static void t_mut(void) {
    static const unsigned bits[4] = { 64, 10, 5, 0 };
    static const char *what[3] = { "insert", "replace", "delete" };
    mut_op ops[3];
    int b, o, s, failures;

    named(mut_model(10000, 64, 50), "in place: insert, replace, delete", 10000, 64);
    named(mut_model(2000, 64, 1), "in place, checked each step", 2000, 64);
    named(mut_model(2000, 10, 1), "in place, checked each step", 2000, 10);
    named(mut_model(2000, 5, 1), "in place, checked each step", 2000, 5);
    named(mut_model(400, 0, 1), "in place, checked each step", 400, 0);
    for (b = 1; b <= 60; b += 7) named(mut_model(b, 5, 1), "in place, checked each step", b, 5);
    named(mut_snapshots(1999, 64), "199 snapshots untouched by in-place updates", 1999, 64);
    named(mut_snapshots(1999, 10), "199 snapshots untouched by in-place updates", 1999, 10);
    named(mut_snapshots(1999, 5), "199 snapshots untouched by in-place updates", 1999, 5);
    named(mut_snapshots(499, 0), "49 snapshots untouched by in-place updates", 499, 0);
    t_mut_allocs();
    t_mut_reenter();

    ops[0] = mop_insert; ops[1] = mop_replace; ops[2] = mop_delete;
    for (b = 0; b < 4; b++)
        for (o = 0; o < 3; o++)
            for (s = 0; s < 2; s++) {
                char name[160];
                int rc = mut_oom(ops[o], bits[b], s, &failures);
                snprintf(name, sizeof name,
                         "an in-place %s on a %s trie survives %d failed allocations: %u hash bits",
                         what[o], s ? "shared" : "sole-owner", failures, bits[b]);
                ok(rc == 0, name);
                if (rc) printf("# failed at step %d\n", rc);
            }
}

/* What the two functions promise their caller, asked directly: which entry
 * comes back as displaced, and that an update which changes nothing really
 * changes nothing - on a trie the handle holds alone, and on one a snapshot
 * holds too. */
static int mut_contract(unsigned bits, int shared) {
    hamt_map m = { NULL, 0 };
    hv_val plain = { 1, 0, NULL, NULL }, other = { 1, 0, NULL, NULL };
    hamt_node *snap = NULL, *root;
    hamt_entry *was, *e, *dead;
    const char *key = "key-17";
    size_t klen = strlen(key);
    uint64_t h;
    int i, added, st, rc = 0;
    long live = ha_live_blocks;

    hamt_hash_set_bits(bits);
    h = hamt_hash(key, klen, 0);
    for (i = 0; i < 300; i++) t_put(&m, keyn("key", i), &plain);
    if (shared) snap = hamt_node_retain(m.root);

    /* A new value: the entry that held the old one comes back. */
    was = m_entry(&m, key);
    e = hamt_entry_new(NULL, key, klen, 0, h, &other);
    if (hamt_map_put_mut(NULL, &m.root, e, &added, &dead)) rc = 1;
    else if (added != 0 || dead != was) rc = 2;
    else if (m_entry(&m, key) != e) rc = 3;
    hamt_entry_release(NULL, e);
    if (dead) hamt_entry_release(NULL, dead);
    if (shared && !rc) { hamt_node_release(NULL, snap); snap = hamt_node_retain(m.root); }

    /* The same value again, in another entry: nothing is displaced, the
     * entry already there stays, and the root does not move. */
    was = m_entry(&m, key);
    root = m.root;
    e = hamt_entry_new(NULL, key, klen, 0, h, &other);
    if (!rc && hamt_map_put_mut(NULL, &m.root, e, &added, &dead)) rc = 4;
    if (!rc && (added != 0 || dead != NULL)) rc = 5;
    if (!rc && (m.root != root || m_entry(&m, key) != was)) rc = 6;
    hamt_entry_release(NULL, e);

    /* A key that is not there: nothing displaced, nothing moved. */
    st = hamt_map_del_mut(NULL, &m.root, "absent key", 10, 0, hamt_hash("absent key", 10, 0), &dead);
    if (!rc && (st != HAMT_DEL_ABSENT || dead != NULL || m.root != root)) rc = 7;

    /* A key that is: its entry comes back. */
    was = m_entry(&m, key);
    st = hamt_map_del_mut(NULL, &m.root, key, klen, 0, h, &dead);
    if (!rc && (st != HAMT_DEL_DONE || dead != was)) rc = 8;
    if (st == HAMT_DEL_DONE) m.count--;
    if (dead) hamt_entry_release(NULL, dead);
    if (!rc && (m_entry(&m, key) || hamt_map_check(m.root, m.count))) rc = 9;

    if (snap) {
        hamt_map s; s.root = snap; s.count = 300;
        if (!rc && (hamt_map_check(snap, 300) || !m_entry(&s, key) || m_entry(&s, key)->val != &other)) rc = 10;
        hamt_node_release(NULL, snap);
    }
    m_free(&m);

    /* The last key of all. */
    t_put(&m, key, &plain);
    if (shared) snap = hamt_node_retain(m.root); else snap = NULL;
    was = m_entry(&m, key);
    st = hamt_map_del_mut(NULL, &m.root, key, klen, 0, h, &dead);
    if (!rc && (st != HAMT_DEL_DONE || dead != was || m.root != NULL)) rc = 11;
    if (dead) hamt_entry_release(NULL, dead);
    if (snap) hamt_node_release(NULL, snap);
    m.root = NULL; m.count = 0;

    if (!rc && (plain.refs != 1 || other.refs != 1)) rc = 12;
    if (!rc && ha_live_blocks != live) rc = 13;
    hamt_hash_set_bits(64);
    return rc;
}

static void t_mut_contract(void) {
    static const unsigned bits[4] = { 64, 10, 5, 0 };
    int b, s;
    for (b = 0; b < 4; b++)
        for (s = 0; s < 2; s++) {
            char name[160];
            int rc = mut_contract(bits[b], s);
            snprintf(name, sizeof name,
                     "what an in-place update hands back, on a %s trie: %u hash bits",
                     s ? "shared" : "sole-owner", bits[b]);
            ok(rc == 0, name);
            if (rc) printf("# failed at step %d\n", rc);
        }
}

/* ---- sets: entries with no value, and the algebra over them ------------ */

/* The members of a set built for a test, as flags over [0, universe). */
typedef struct tset { hamt_map m; char *in; int universe; } tset;

static void ts_init(tset *s, int universe) {
    s->m.root = NULL; s->m.count = 0; s->universe = universe;
    s->in = (char *)calloc((size_t)universe, 1);
}
static void ts_add(tset *s, int i)    { t_put(&s->m, keyn("m", i), NULL); s->in[i] = 1; }
static void ts_remove(tset *s, int i) { t_del(&s->m, keyn("m", i)); s->in[i] = 0; }
static void ts_free(tset *s)          { m_free(&s->m); free(s->in); s->in = NULL; }

#define OP_INTERSECT 1
#define OP_SUBTRACT  2

/* One operation against the same question asked of the flags: the count,
 * the checker, every member one by one, and the shape of a set that was
 * simply built with those members. */
static int set_op_check(const tset *a, const tset *b, int op) {
    hamt_set_ctx c;
    hamt_map r = { NULL, 0 }, built = { NULL, 0 };
    size_t count = 0, want = 0;
    int i, rc = 0;

    c.cx = NULL;
    r.root = op == OP_INTERSECT
        ? hamt_set_intersect(&c, a->m.root, b->m.root, a->m.count, b->m.count, &count)
        : hamt_set_subtract(&c, a->m.root, b->m.root, a->m.count, b->m.count, &count);
    r.count = count;
    if (c.err) return 1;

    for (i = 0; i < a->universe; i++) {
        int in = a->in[i] && (op == OP_INTERSECT ? b->in[i] : !b->in[i]);
        if (in) { want++; t_put(&built, keyn("m", i), NULL); }
        if (!rc && (m_entry(&r, keyn("m", i)) != NULL) != in) rc = 2;
    }
    if (!rc && count != want) rc = 3;
    if (!rc && hamt_map_check(r.root, r.count)) rc = 4;
    if (!rc && !same_shape(r.root, built.root)) rc = 5;
    /* Every entry in the result is the first set's own entry, not a copy. */
    for (i = 0; i < a->universe && !rc; i++) {
        hamt_entry *e = m_entry(&r, keyn("m", i));
        if (e && e != m_entry(&a->m, keyn("m", i))) rc = 6;
    }
    if (!rc && want == a->m.count && r.root != a->m.root) rc = 7;   /* all kept: the set itself */
    m_free(&built);
    m_free(&r);
    return rc;
}

static int set_ask_check(const tset *a, const tset *b) {
    size_t visits;
    int i, sub = 1, dis = 1;
    for (i = 0; i < a->universe; i++) {
        if (a->in[i] && !b->in[i]) sub = 0;
        if (a->in[i] && b->in[i]) dis = 0;
    }
    if (hamt_set_subset(a->m.root, b->m.root, a->m.count, b->m.count, &visits) != sub) return 1;
    if (hamt_set_disjoint(a->m.root, b->m.root, &visits) != dis) return 2;
    return 0;
}

/* Two sets related in one of several ways, and every operation between
 * them in both directions. */
static int set_run(int n, unsigned bits, int mode) {
    tset a, b;
    int i, rc = 0, step = 0, universe = 2 * n + 10;
    long r0 = hv_retains, r1 = hv_releases, live = ha_live_blocks;

    hamt_hash_set_bits(bits);
    ts_init(&a, universe); ts_init(&b, universe);
    for (i = 0; i < n; i++) ts_add(&a, i);

    switch (mode) {
    case 0: for (i = n; i < 2 * n; i++) ts_add(&b, i); break;               /* disjoint */
    case 1: for (i = n / 2; i < n + n / 2; i++) ts_add(&b, i); break;       /* half shared */
    case 2:                                                                 /* a version of a */
        b.m.root = hamt_node_retain(a.m.root); b.m.count = a.m.count;
        memcpy(b.in, a.in, (size_t)universe);
        for (i = 0; i < 5; i++) { ts_add(&b, n + i); ts_remove(&b, (i * n) / 5); }
        break;
    case 3:                                                                 /* small, some inside */
        for (i = 0; i < n; i += 9) ts_add(&b, i);
        for (i = 0; i < 4; i++) ts_add(&b, n + i);
        break;
    case 4: for (i = 0; i < n + n / 3; i++) ts_add(&b, n + n / 3 - 1 - i); break;  /* a superset */
    default: for (i = 0; i < n; i += 2) ts_add(&b, i); break;               /* a subset */
    }

    if (!rc && (rc = set_op_check(&a, &b, OP_INTERSECT))) step = 10;
    if (!rc && (rc = set_op_check(&b, &a, OP_INTERSECT))) step = 20;
    if (!rc && (rc = set_op_check(&a, &b, OP_SUBTRACT)))  step = 30;
    if (!rc && (rc = set_op_check(&b, &a, OP_SUBTRACT)))  step = 40;
    if (!rc && (rc = set_ask_check(&a, &b))) step = 50;
    if (!rc && (rc = set_ask_check(&b, &a))) step = 60;
    if (!rc && (rc = set_op_check(&a, &a, OP_INTERSECT))) step = 70;
    if (!rc && (rc = set_op_check(&a, &a, OP_SUBTRACT)))  step = 80;
    if (!rc && (rc = set_ask_check(&a, &a))) step = 90;

    ts_free(&a); ts_free(&b);
    if (!rc && (hv_retains != r0 || hv_releases != r1)) { rc = 1; step = 100; }
    if (!rc && ha_live_blocks != live) { rc = 2; step = 100; }
    hamt_hash_set_bits(64);
    return rc ? step + rc : 0;
}

static void t_set_identity(void) {
    tset a, b, e;
    hamt_set_ctx c;
    hamt_node *r;
    size_t count, visits;
    int i, n = 3000;
    long live;

    ts_init(&a, n + 10); ts_init(&b, n + 10); ts_init(&e, n + 10);
    for (i = 0; i < n; i++) ts_add(&a, i);
    b.m.root = hamt_node_retain(a.m.root); b.m.count = a.m.count;
    memcpy(b.in, a.in, (size_t)(n + 10));
    ts_add(&b, n + 1);                              /* b is a and one more */
    live = ha_live_blocks;
    c.cx = NULL;

    r = hamt_set_intersect(&c, a.m.root, b.m.root, a.m.count, b.m.count, &count);
    ok(r == a.m.root && count == (size_t)n && c.visits <= 13,
       "intersecting with a superset one member larger is the set itself, along one path");
    if (r) hamt_node_release(NULL, r);

    r = hamt_set_subtract(&c, b.m.root, a.m.root, b.m.count, a.m.count, &count);
    ok(r && count == 1 && c.visits <= 13 && hamt_map_check(r, 1) == 0,
       "what the larger has that the smaller has not is one member, along one path");
    if (r) hamt_node_release(NULL, r);

    r = hamt_set_subtract(&c, a.m.root, b.m.root, a.m.count, b.m.count, &count);
    ok(r == NULL && count == 0 && !c.err, "and the other way round there is nothing");

    ok(hamt_set_subset(a.m.root, b.m.root, a.m.count, b.m.count, &visits) && visits <= 13,
       "the smaller is a subset of the larger, along one path");
    ok(!hamt_set_subset(b.m.root, a.m.root, b.m.count, a.m.count, &visits) && visits == 0,
       "the larger is not a subset of the smaller, and the counts alone say so");
    ok(!hamt_set_disjoint(a.m.root, b.m.root, &visits) && visits <= 13, "they are not disjoint");

    r = hamt_set_intersect(&c, a.m.root, a.m.root, a.m.count, a.m.count, &count);
    ok(r == a.m.root && count == (size_t)n && c.visits == 0, "a set intersected with itself is itself, unvisited");
    if (r) hamt_node_release(NULL, r);
    r = hamt_set_subtract(&c, a.m.root, a.m.root, a.m.count, a.m.count, &count);
    ok(r == NULL && count == 0 && c.visits == 0, "a set less itself is empty, unvisited");

    r = hamt_set_intersect(&c, a.m.root, e.m.root, a.m.count, 0, &count);
    ok(r == NULL && count == 0, "anything intersected with the empty set is empty");
    r = hamt_set_intersect(&c, e.m.root, a.m.root, 0, a.m.count, &count);
    ok(r == NULL && count == 0, "either way round");
    r = hamt_set_subtract(&c, a.m.root, e.m.root, a.m.count, 0, &count);
    ok(r == a.m.root && count == (size_t)n, "a set less the empty set is itself");
    if (r) hamt_node_release(NULL, r);
    r = hamt_set_subtract(&c, e.m.root, a.m.root, 0, a.m.count, &count);
    ok(r == NULL && count == 0, "the empty set less anything is empty");
    ok(hamt_set_subset(e.m.root, a.m.root, 0, a.m.count, &visits)
       && hamt_set_subset(e.m.root, e.m.root, 0, 0, &visits)
       && !hamt_set_subset(a.m.root, e.m.root, a.m.count, 0, &visits),
       "the empty set is a subset of everything and nothing else is a subset of it");
    ok(hamt_set_disjoint(e.m.root, a.m.root, &visits) && hamt_set_disjoint(e.m.root, e.m.root, &visits)
       && !hamt_set_disjoint(a.m.root, a.m.root, &visits),
       "the empty set is disjoint from everything; a set with members is not disjoint from itself");

    ok(ha_live_blocks == live + 0, "and of all that only the one-member result was ever allocated");
    ts_free(&a); ts_free(&b); ts_free(&e);
}

/* Every allocation in an intersection and a difference fails in turn. */
static int set_oom(int op, unsigned bits, int *failures) {
    tset a, b;
    hamt_set_ctx c;
    hamt_node *r = NULL;
    size_t count;
    int i, k, rc = 0, done = 0, n = 240;

    hamt_hash_set_bits(bits);
    ts_init(&a, 2 * n); ts_init(&b, 2 * n);
    for (i = 0; i < n; i++) ts_add(&a, i);
    for (i = 0; i < n; i += 3) ts_add(&b, i);       /* leaves the first set ragged */
    for (i = n; i < n + 40; i++) ts_add(&b, i);
    c.cx = NULL;

    *failures = 0;
    for (k = 0; k < 5000 && !rc && !done; k++) {
        long live = ha_live_blocks;
        ha_fail_at = ha_calls + k;
        r = op == OP_INTERSECT
            ? hamt_set_intersect(&c, a.m.root, b.m.root, a.m.count, b.m.count, &count)
            : hamt_set_subtract(&c, a.m.root, b.m.root, a.m.count, b.m.count, &count);
        ha_fail_at = -1;
        if (!c.err) { done = 1; break; }
        (*failures)++;
        if (r) rc = 1;
        else if (c.err != HAMT_ERR_OOM) rc = 2;
        else if (ha_live_blocks != live) rc = 3;
    }
    if (!rc && !done) rc = 4;
    if (!rc && *failures == 0) rc = 5;
    if (!rc && hamt_map_check(r, count)) rc = 6;
    if (!rc && (hamt_map_check(a.m.root, a.m.count) || hamt_map_check(b.m.root, b.m.count))) rc = 7;
    if (r) hamt_node_release(NULL, r);
    ts_free(&a); ts_free(&b);
    hamt_hash_set_bits(64);
    return rc;
}

/* Cases only a hand-placed hash can build: one position, with an entry on
 * one side and a subtree on the other, where the answer turns on a single
 * lookup and nothing else in the two sets can give it away. */
static void smap(hamt_map *m, const uint64_t *hash, const int *tag, int n) {
    int i;
    m->root = NULL; m->count = 0;
    for (i = 0; i < n; i++) {
        hamt_entry *e = synth(hash[i], tag[i]);
        s_put(m, e);
        hamt_entry_release(NULL, e);
    }
}

static void t_set_placed(void) {
    /* Position 3 of the root; tags name the keys. 1 and 2 share that
     * position and part one level down. 9 has key 1's hash and another
     * key. Positions 10 to 14 are padding, so the counts decide nothing. */
#define P3(sub) (3u | ((uint64_t)(sub) << 5))
    static const uint64_t pad_h[5] = { 10, 11, 12, 13, 14 };
    static const int      pad_t[5] = { 50, 51, 52, 53, 54 };
    hamt_map sub12, one1, one9, sub1_3, sub2_3, pad;
    hamt_merge_ctx mc;
    hamt_set_ctx sc;
    size_t v, count;
    hamt_node *r;

    { const uint64_t h[2] = { P3(1), P3(2) }; const int t[2] = { 1, 2 }; smap(&sub12, h, t, 2); }
    { const uint64_t h[1] = { P3(1) };        const int t[1] = { 1 };    smap(&one1, h, t, 1); }
    { const uint64_t h[1] = { P3(1) };        const int t[1] = { 9 };    smap(&one9, h, t, 1); }
    { const uint64_t h[2] = { P3(1), P3(4) }; const int t[2] = { 1, 3 }; smap(&sub1_3, h, t, 2); }
    { const uint64_t h[2] = { P3(2), P3(4) }; const int t[2] = { 2, 3 }; smap(&sub2_3, h, t, 2); }
    smap(&pad, pad_h, pad_t, 5);
    mc.cx = NULL; mc.resolve = NULL; mc.ud = NULL;
    sc.cx = NULL;

#define WITH_PAD(dst, src)                                                    \
    do { (dst).root = hamt_map_merge(&mc, (src).root, pad.root);              \
         (dst).count = (src).count + mc.added; } while (0)
    {
        hamt_map Sub12, One1, One9, Sub1_3, Sub2_3;
        WITH_PAD(Sub12, sub12); WITH_PAD(One1, one1); WITH_PAD(One9, one9);
        WITH_PAD(Sub1_3, sub1_3); WITH_PAD(Sub2_3, sub2_3);

        /* subset */
        ok(!hamt_set_subset(sub12.root, One1.root, 2, One1.count, &v),
           "a subtree of two is not a subset of one entry at its position, though the other set is larger");
        ok(hamt_set_subset(one1.root, Sub12.root, 1, Sub12.count, &v),
           "an entry is a subset of a subtree that holds it");
        ok(!hamt_set_subset(one9.root, Sub12.root, 1, Sub12.count, &v),
           "but not of one that holds only its hash's neighbours");
        ok(!hamt_set_subset(one9.root, One1.root, 1, One1.count, &v),
           "an entry is not a subset of another key at the same position");
        ok(hamt_set_subset(one1.root, One1.root, 1, One1.count, &v),
           "and is one of the same key there");
        ok(!hamt_set_subset(sub12.root, Sub1_3.root, 2, Sub1_3.count, &v),
           "two subtrees sharing one key of two: not a subset");

        /* disjoint */
        ok(!hamt_set_disjoint(one1.root, Sub12.root, &v), "an entry and a subtree that holds it are not disjoint");
        ok(!hamt_set_disjoint(Sub12.root, one1.root, &v), "either way round");
        ok(hamt_set_disjoint(one9.root, Sub12.root, &v), "an entry and a subtree without it are disjoint");
        ok(hamt_set_disjoint(Sub12.root, one9.root, &v), "either way round");
        ok(hamt_set_disjoint(one1.root, one9.root, &v), "two keys at one position are disjoint");
        ok(!hamt_set_disjoint(sub12.root, Sub1_3.root, &v), "two subtrees sharing a key are not disjoint");
        ok(hamt_set_disjoint(sub12.root, pad.root, &v), "sets at different positions are disjoint");

        /* intersect and subtract through the same position */
        r = hamt_set_intersect(&sc, Sub12.root, One1.root, Sub12.count, One1.count, &count);
        ok(r && count == One1.count && hamt_map_check(r, count) == 0
           && hamt_map_find(r, "synth-1", 7, 0, P3(1)) && !hamt_map_find(r, "synth-2", 7, 0, P3(2))
           && (r->datamap & (1u << 3)) && !(r->nodemap & (1u << 3)),
           "a subtree intersected with one of its keys leaves that key as an entry in the parent");
        if (r) hamt_node_release(NULL, r);
        r = hamt_set_subtract(&sc, Sub12.root, One1.root, Sub12.count, One1.count, &count);
        ok(r && count == 1 && hamt_map_check(r, 1) == 0 && hamt_map_find(r, "synth-2", 7, 0, P3(2))
           && hamt_node_is_single(r),
           "the same subtree less that key and the padding is the other key alone, folded to the root");
        if (r) hamt_node_release(NULL, r);
        r = hamt_set_subtract(&sc, Sub12.root, One9.root, Sub12.count, One9.count, &count);
        ok(r && count == 2 && hamt_map_check(r, 2) == 0 && (r->nodemap & (1u << 3)),
           "less a key it does not hold, the subtree stays whole");
        if (r) hamt_node_release(NULL, r);
        r = hamt_set_intersect(&sc, Sub12.root, Sub2_3.root, Sub12.count, Sub2_3.count, &count);
        ok(r && count == 1 + pad.count && hamt_map_check(r, count) == 0
           && hamt_map_find(r, "synth-2", 7, 0, P3(2)) && (r->datamap & (1u << 3)),
           "two subtrees with one key in common intersect to that key, folded into the parent");
        if (r) hamt_node_release(NULL, r);

        m_free(&Sub12); m_free(&One1); m_free(&One9); m_free(&Sub1_3); m_free(&Sub2_3);
    }
    m_free(&sub12); m_free(&one1); m_free(&one9); m_free(&sub1_3); m_free(&sub2_3); m_free(&pad);
#undef WITH_PAD
#undef P3
}

/* The counting must not cost what skipping saved. Two cases where one of
 * the tallies is nearly free and the other walks nearly everything: the
 * mode has to pick the free one each time. And a case where the two sets
 * share whole subtrees by pointer AND the second is under half the first,
 * which is the only place those shared subtrees are the ones walked. */
static void t_set_counting(void) {
    tset a, b, small;
    hamt_set_ctx c;
    hamt_node *r;
    size_t count;
    int i, n = 4000, kept = 0;

    ts_init(&a, n + 10); ts_init(&b, n + 10); ts_init(&small, n + 10);
    for (i = 0; i < n; i++) ts_add(&a, i);
    c.cx = NULL;

    /* b: a with one member more. */
    b.m.root = hamt_node_retain(a.m.root); b.m.count = a.m.count;
    memcpy(b.in, a.in, (size_t)(n + 10));
    ts_add(&b, n + 1);
    r = hamt_set_intersect(&c, b.m.root, a.m.root, b.m.count, a.m.count, &count);
    ok(count == (size_t)n && c.walked <= 64, "intersecting two versions one member apart counts by walking next to nothing");
    if (r) hamt_node_release(NULL, r);
    r = hamt_set_subtract(&c, b.m.root, a.m.root, b.m.count, a.m.count, &count);
    ok(count == 1 && c.walked <= 64, "and so does their difference");
    if (r) hamt_node_release(NULL, r);

    /* small: a handful of unrelated members, built separately. */
    for (i = 0; i < 20; i++) ts_add(&small, i * 37);
    r = hamt_set_intersect(&c, a.m.root, small.m.root, a.m.count, small.m.count, &count);
    ok(count == 20 && c.walked <= 64, "intersecting a large set with a small one walks next to nothing");
    if (r) hamt_node_release(NULL, r);
    r = hamt_set_subtract(&c, a.m.root, small.m.root, a.m.count, small.m.count, &count);
    ok(count == (size_t)n - 20 && c.walked <= 64, "and so does their difference");
    if (r) hamt_node_release(NULL, r);

    /* b again: a with every member gone whose hash puts it past position
     * 11 of the root. What is left is under half, and the twelve subtrees
     * it sits in are a's own, by pointer. */
    ts_free(&b); ts_init(&b, n + 10);
    b.m.root = hamt_node_retain(a.m.root); b.m.count = a.m.count;
    memcpy(b.in, a.in, (size_t)(n + 10));
    for (i = 0; i < n; i++) {
        const char *k = keyn("m", i);
        if (HAMT_IDX(hamt_hash(k, strlen(k), 0), 0) > 11) ts_remove(&b, i); else kept++;
    }
    ok(kept * 2 <= n && kept > n / 5, "a set cut down to twelve of its root's positions is under half of it");
    ok(set_op_check(&a, &b, OP_INTERSECT) == 0, "intersecting the whole with that part: right members, right count");
    r = hamt_set_intersect(&c, a.m.root, b.m.root, a.m.count, b.m.count, &count);
    ok(c.count_shared && count == (size_t)kept && c.walked == (size_t)kept,
       "counted by walking the twelve shared subtrees and nothing else");
    if (r) hamt_node_release(NULL, r);
    ok(set_op_check(&a, &b, OP_SUBTRACT) == 0, "the whole less that part: right members, right count");
    r = hamt_set_subtract(&c, a.m.root, b.m.root, a.m.count, b.m.count, &count);
    ok(c.count_shared && count == (size_t)(n - kept) && c.walked == (size_t)kept,
       "counted the same way");
    if (r) hamt_node_release(NULL, r);
    ok(set_op_check(&b, &a, OP_INTERSECT) == 0 && set_op_check(&b, &a, OP_SUBTRACT) == 0,
       "and both the other way round");

    ts_free(&a); ts_free(&b); ts_free(&small);
}

static void t_sets(void) {
    static const unsigned bits[4] = { 64, 10, 5, 0 };
    static const int size[4] = { 1500, 1500, 800, 150 };
    static const char *mode[6] = {
        "disjoint", "half shared", "a version of the other", "small beside the other",
        "a superset", "a subset"
    };
    int b, m, failures;

    for (b = 0; b < 4; b++)
        for (m = 0; m < 6; m++) {
            char name[160];
            int rc = set_run(size[b], bits[b], m);
            snprintf(name, sizeof name,
                     "intersect, subtract, subset and disjoint, both ways: %s, %d members, %u hash bits",
                     mode[m], size[b], bits[b]);
            ok(rc == 0, name);
            if (rc) printf("# failed at step %d\n", rc);
        }
    for (m = 1; m <= 40; m += 3) {
        char name[120];
        int rc = set_run(m, 5, 1) + set_run(m, 5, 2) + set_run(m, 64, 5);
        snprintf(name, sizeof name, "the same at %d members, where every fold is near the root", m);
        ok(rc == 0, name);
    }
    t_set_identity();
    t_set_placed();
    t_set_counting();
    for (b = 0; b < 4; b++) {
        int rc = set_oom(OP_INTERSECT, bits[b], &failures);
        named(rc, "an intersection survives every allocation failing in turn", 240, bits[b]);
        printf("# %d allocations failed in turn\n", failures);
        rc = set_oom(OP_SUBTRACT, bits[b], &failures);
        named(rc, "a difference survives every allocation failing in turn", 240, bits[b]);
        printf("# %d allocations failed in turn\n", failures);
    }
}

/* ---- the vector --------------------------------------------------------- */

static int v_push(hamt_vec *v, hv_val *val) { return hamt_vec_push(NULL, v, val); }
static int v_set(hamt_vec *v, size_t i, hv_val *val) {
    void *dead;
    if (hamt_vec_set(NULL, v, i, val, &dead)) return -1;
    if (dead) hv_release(NULL, (hv_val *)dead);
    return 0;
}
static int v_pop(hamt_vec *v) {
    void *dead;
    if (hamt_vec_pop(NULL, v, &dead)) return -1;
    if (dead) hv_release(NULL, (hv_val *)dead);
    return 0;
}

/* A plain array to check a vector against, and snapshots of both. */
typedef struct varr { hv_val **at; size_t n, cap; } varr;
static void va_push(varr *a, hv_val *v) {
    if (a->n == a->cap) { a->cap = a->cap ? a->cap * 2 : 64; a->at = (hv_val **)realloc(a->at, a->cap * sizeof *a->at); }
    a->at[a->n++] = v;
}
static int va_same(const hamt_vec *v, const varr *a) {
    hamt_vec_iter it;
    void *const *run;
    size_t start, seen = 0;
    uint32_t n, i;
    if (v->count != a->n) return 0;
    for (i = 0; i < 40 && i < a->n; i++)
        if (hamt_vec_get(v, (a->n - 1) * i / 40) != a->at[(a->n - 1) * i / 40]) return 0;
    hamt_vec_iter_init(&it, v);
    while ((run = hamt_vec_iter_next(&it, &start, &n))) {
        if (start != seen) return 0;
        for (i = 0; i < n; i++) if (run[i] != a->at[start + i]) return 0;
        seen += n;
    }
    return seen == a->n;
}

/* Every size at which the tail fills or empties or the tree gains or loses
 * a level, up and then down, with the checker and a full comparison at
 * each. */
static void t_vec_boundaries(void) {
    static const size_t edge[] = { 0, 1, 2, 31, 32, 33, 34, 63, 64, 65, 1023, 1024, 1025, 1055, 1056,
                                   1057, 1088, 1089, 32767, 32768, 32769, 32799, 32800, 32801, 33824, 33825 };
    const int nedge = (int)(sizeof edge / sizeof edge[0]);
    hamt_vec v;
    varr a = { NULL, 0, 0 };
    hv_val *vals = vals_new(34000);
    int e = 0, good = 1, where = -1;
    size_t i;
    long live = ha_live_blocks;

    hamt_vec_init(&v);
    for (i = 0; i <= 33825 && good; i++) {
        if ((size_t)e < (size_t)nedge && i == edge[e]) {
            if (hamt_vec_check(&v) || !va_same(&v, &a)) { good = 0; where = (int)i; }
            e++;
        }
        if (i == 33825) break;
        if (v_push(&v, &vals[i])) { good = 0; where = (int)i; }
        va_push(&a, &vals[i]);
    }
    ok(good && e == nedge, "pushed to 33,825, checked at every size where the shape changes");
    if (!good) printf("# failed at size %d, rule %d\n", where, hamt_vec_check(&v));
    ok(v.shift == 15 && v.root && v.root->len == 2, "33,825 values are three levels of nodes over the leaves");

    good = 1; e = nedge - 1;
    for (i = 33825; good; i--) {
        if (e >= 0 && i == edge[e]) {
            if (hamt_vec_check(&v) || !va_same(&v, &a)) { good = 0; where = (int)i; }
            e--;
        }
        if (i == 0) break;
        if (v_pop(&v)) { good = 0; where = (int)i; }
        a.n--;
        if (vals[i - 1].refs != 1) { good = 0; where = (int)i; }
    }
    ok(good && e == -1, "popped back to nothing, checked at the same sizes on the way down");
    if (!good) printf("# failed at size %d, rule %d\n", where, hamt_vec_check(&v));
    ok(v.count == 0 && !v.root && !v.tail && v_pop(&v) == 0 && v.count == 0,
       "an empty vector pops to an empty vector");
    ok(vals_idle(vals, 34000) && ha_live_blocks == live, "everything given back");
    free(a.at); free(vals);
}

/* Random pushes, pops and sets against the array, with snapshots: each a
 * second struct onto the same nodes, so the next update has to copy. */
static int vec_model(int steps, int bias_up, uint32_t seed) {
    hamt_vec v, snap[64];
    varr a = { NULL, 0, 0 }, sa[64];
    hv_val *vals = vals_new(steps + 1);
    int nsnap = 0, s, i, rc = 0, next = 0;
    long live = ha_live_blocks;

    rng_state = seed;
    hamt_vec_init(&v);
    for (s = 0; s < steps && !rc; s++) {
        uint32_t op = rng() % 100;
        if (op < (uint32_t)bias_up || a.n == 0) {
            if (v_push(&v, &vals[next])) rc = 1;
            va_push(&a, &vals[next++]);
        }
        else if (op < 80) {
            if (v_pop(&v)) rc = 2;
            a.n--;
        }
        else {
            size_t at = rng() % a.n;
            if (v_set(&v, at, &vals[next])) rc = 3;
            a.at[at] = &vals[next++];
        }
        if (!rc && v.count != a.n) rc = 4;
        if (!rc && a.n && hamt_vec_get(&v, a.n - 1) != a.at[a.n - 1]) rc = 5;
        if (!rc && (s % 97 == 0 || s > steps - 50) && (hamt_vec_check(&v) || !va_same(&v, &a))) rc = 6;
        if (!rc && s % (steps / 60 + 1) == 0 && nsnap < 64) {
            hamt_vec_share(&snap[nsnap], &v);
            sa[nsnap].n = a.n; sa[nsnap].cap = a.n;
            sa[nsnap].at = (hv_val **)malloc((a.n ? a.n : 1) * sizeof(hv_val *));
            memcpy(sa[nsnap].at, a.at, a.n * sizeof(hv_val *));
            nsnap++;
        }
    }
    if (!rc && (hamt_vec_check(&v) || !va_same(&v, &a))) rc = 7;
    for (i = 0; i < nsnap; i++) {
        if (!rc && (hamt_vec_check(&snap[i]) || !va_same(&snap[i], &sa[i]))) rc = 8;
        hamt_vec_clear(NULL, &snap[i]);
        free(sa[i].at);
    }
    hamt_vec_clear(NULL, &v);
    if (!rc && !vals_idle(vals, steps + 1)) rc = 9;
    if (!rc && ha_live_blocks != live) rc = 10;
    free(a.at); free(vals);
    return rc;
}

static void t_vec_model(void) {
    int rc;
    rc = vec_model(60000, 55, 1);  ok(rc == 0, "60,000 random pushes, pops and sets, growing, with 60 snapshots");
    if (rc) printf("# failed at step %d\n", rc);
    rc = vec_model(60000, 40, 2);  ok(rc == 0, "60,000 more that hover near empty");
    if (rc) printf("# failed at step %d\n", rc);
    rc = vec_model(200000, 70, 3); ok(rc == 0, "200,000 that grow past two levels");
    if (rc) printf("# failed at step %d\n", rc);
    rc = vec_model(3000, 50, 4) + vec_model(3000, 45, 5) + vec_model(500, 60, 6);
    ok(rc == 0, "and three short ones around the first boundaries");
}

/* A million and more, then what one update costs. */
static void t_vec_big(void) {
    hamt_vec v, old;
    hv_val one = { 1, 0, NULL, NULL }, two = { 1, 0, NULL, NULL };
    size_t i, n = 1100010;      /* ten in the tail, so a push has room */
    int good = 1;
    long calls;
    void *dead;

    hamt_vec_init(&v);
    for (i = 0; i < n && good; i++) {
        if (v_push(&v, &one)) good = 0;
        if ((i == 1055 || i == 1056 || i == 32799 || i == 32800 || i == 1048607 || i == 1048608)
            && hamt_vec_check(&v)) good = 0;
    }
    ok(good && v.count == n && hamt_vec_check(&v) == 0, "1,100,010 pushes, checked across each new level");
    ok(v.shift == 20, "which is four levels of nodes over the leaves");

    hamt_vec_share(&old, &v);
    calls = ha_calls;
    hamt_vec_set(NULL, &v, 500000, &two, &dead);
    hv_release(NULL, (hv_val *)dead);
    printf("# one set on a shared vector of 1,100,010 allocated %ld nodes\n", ha_calls - calls);
    ok(ha_calls - calls == 5, "replacing one value in a vector something else holds copies one path: five nodes");
    ok(hamt_vec_get(&v, 500000) == &two && hamt_vec_get(&old, 500000) == &one,
       "and the other holder still sees the old value");
    ok(hamt_vec_check(&v) == 0 && hamt_vec_check(&old) == 0, "both check out");

    calls = ha_calls;
    hamt_vec_set(NULL, &v, 500001, &two, &dead);
    hv_release(NULL, (hv_val *)dead);
    ok(ha_calls == calls, "a second replacement on that path allocates nothing: the path is this vector's now");
    calls = ha_calls;
    hamt_vec_set(NULL, &v, 500001, &two, &dead);
    ok(ha_calls == calls && dead == NULL, "and putting back the value already there does nothing at all");

    calls = ha_calls;
    v_push(&v, &two); v_pop(&v);
    ok(ha_calls - calls == 1 && hamt_vec_get(&old, n - 1) == &one && old.count == n,
       "a push to a shared tail copies the tail and nothing else");

    hamt_vec_clear(NULL, &old);
    good = 1;
    for (i = n; i > 0 && good; i--) {
        if (v_pop(&v)) good = 0;
        if ((i == 1048609 || i == 1048608 || i == 32801 || i == 32800 || i == 1057 || i == 1056 || i == 33)
            && hamt_vec_check(&v)) good = 0;
    }
    ok(good && v.count == 0 && !v.root && !v.tail, "popped back to nothing, checked across each level lost");
    ok(one.refs == 1 && two.refs == 1, "everything given back");
}

/* A value whose release uses the vector it is being released from. */
typedef struct veccb { hamt_vec *v; hv_val *store; int ran, rc, check; size_t count_seen; long live_seen; } veccb;
static void veccb_run(void *cx, hv_val *val) {
    veccb *c = (veccb *)val->on_release_arg;
    (void)cx;
    c->ran++;
    c->count_seen = c->v->count;
    c->live_seen  = ha_live_blocks;
    c->rc    = v_push(c->v, c->store);
    c->check = hamt_vec_check(c->v);
}

static void t_vec_reenter(void) {
    hamt_vec v;
    hv_val plain = { 1, 0, NULL, NULL }, store = { 1, 0, NULL, NULL };
    hv_val loud = { 1, 0, veccb_run, NULL };
    veccb c;
    int i;

    loud.on_release_arg = &c;
    hamt_vec_init(&v);
    for (i = 0; i < 100; i++) v_push(&v, &plain);

    memset(&c, 0, sizeof c); c.v = &v; c.store = &store;
    v_set(&v, 50, &loud); loud.refs--;
    v_set(&v, 50, &plain);
    ok(c.ran == 1 && c.rc == 0 && c.check == 0 && c.count_seen == 100 && v.count == 101
       && hamt_vec_get(&v, 50) == &plain && hamt_vec_get(&v, 100) == &store,
       "a value released by a set pushes onto the same vector");

    memset(&c, 0, sizeof c); c.v = &v; c.store = &store;
    loud.refs = 1; v_push(&v, &loud); loud.refs--;
    v_pop(&v);
    ok(c.ran == 1 && c.rc == 0 && c.check == 0 && c.count_seen == 101 && v.count == 102
       && hamt_vec_get(&v, 101) == &store && hamt_vec_check(&v) == 0,
       "a value released by a pop pushes onto the same vector");

    /* The pop that empties a one-value tail and pulls a leaf up. */
    while (v.count > 33) v_pop(&v);
    memset(&c, 0, sizeof c); c.v = &v; c.store = &store;
    loud.refs = 1; v_set(&v, 32, &loud); loud.refs--;
    v_pop(&v);
    ok(c.ran == 1 && c.rc == 0 && c.check == 0 && c.count_seen == 32 && v.count == 33,
       "and so does one released by the pop that pulls a leaf up into the tail");

    memset(&c, 0, sizeof c); c.v = &v; c.store = &store;
    loud.refs = 1; v_set(&v, 5, &loud); loud.refs--;
    hamt_vec_clear(NULL, &v);
    ok(c.ran == 1 && c.count_seen == 0 && c.rc == 0 && v.count == 1,
       "a value released by clearing a vector sees it already empty, and may push to it");
    hamt_vec_clear(NULL, &v);

    /* The order a node goes in: freed first, and only then is what it held
     * released. A vector of 40 values is a root, a leaf and a tail; when the
     * value in the tree's leaf is released, the leaf and the root over it
     * must already be gone, leaving only the tail still to go. */
    {
        long base = ha_live_blocks;
        for (i = 0; i < 40; i++) v_push(&v, &plain);
        memset(&c, 0, sizeof c); c.v = &v; c.store = &store;
        loud.refs = 1; v_set(&v, 3, &loud); loud.refs--;
        hamt_vec_clear(NULL, &v);
        ok(c.ran == 1 && c.live_seen == base + 1,
           "a node is freed before the values under it are released");
        hamt_vec_clear(NULL, &v);
    }
    ok(plain.refs == 1 && store.refs == 1, "all given back");
}

/* No memory, at every allocation in turn, at the sizes where an update

 * allocates the most. After each failure the vector holds what it held. */
typedef int (*vec_op)(hamt_vec *v, hv_val *val);
static int vop_push(hamt_vec *v, hv_val *val) { return v_push(v, val); }
static int vop_pop(hamt_vec *v, hv_val *val)  { (void)val; return v_pop(v); }
static int vop_set_tree(hamt_vec *v, hv_val *val) { return v_set(v, 7, val); }
static int vop_set_tail(hamt_vec *v, hv_val *val) { return v_set(v, v->count - 1, val); }

static int vec_oom(vec_op op, size_t n, int shared, int *failures) {
    hamt_vec v, snap;
    varr a = { NULL, 0, 0 };
    hv_val *vals = vals_new((int)n + 1), fresh = { 1, 0, NULL, NULL };
    size_t i;
    int k, rc = 0, got = -1;

    hamt_vec_init(&v); hamt_vec_init(&snap);
    for (i = 0; i < n; i++) { v_push(&v, &vals[i]); va_push(&a, &vals[i]); }
    if (shared) hamt_vec_share(&snap, &v);

    *failures = 0;
    for (k = 0; k < 60 && !rc; k++) {
        long held = hv_retains - hv_releases;
        ha_fail_at = ha_calls + k;
        got = op(&v, &fresh);
        ha_fail_at = -1;
        if (got != -1) break;
        (*failures)++;
        if (hamt_vec_check(&v)) rc = 1;
        else if (!va_same(&v, &a)) rc = 2;
        else if (hv_retains - hv_releases != held) rc = 3;
        else if (fresh.refs != 1) rc = 4;
        else if (shared && (hamt_vec_check(&snap) || !va_same(&snap, &a))) rc = 5;
    }
    if (!rc && got == -1) rc = 6;
    if (!rc && hamt_vec_check(&v)) rc = 7;
    if (!rc && shared && (hamt_vec_check(&snap) || !va_same(&snap, &a))) rc = 8;
    hamt_vec_clear(NULL, &v); hamt_vec_clear(NULL, &snap);
    if (!rc && (!vals_idle(vals, (int)n + 1) || fresh.refs != 1)) rc = 9;
    free(a.at); free(vals);
    return rc;
}

static void t_vec_oom(void) {
    /* 2080 is 2048 in the tree and a full tail: the push that needs a new
     * node at the second level and a path under it, without a new root. */
    static const size_t size[] = { 1, 32, 33, 64, 1056, 1057, 2080, 2081, 32800, 32801 };
    static const char *name[4] = { "push", "pop", "set in the tree", "set in the tail" };
    vec_op ops[4];
    int o, s, sh, failures, total = 0, bad = 0, i;
    long live = ha_live_blocks;
    ops[0] = vop_push; ops[1] = vop_pop; ops[2] = vop_set_tree; ops[3] = vop_set_tail;

    for (o = 0; o < 4; o++) {
        char line[160];
        int worst = 0;
        bad = 0;
        for (i = 0; i < 10; i++)
            for (sh = 0; sh < 2; sh++) {
                if (o == 2 && size[i] < 33) continue;        /* nothing in the tree yet */
                s = vec_oom(ops[o], size[i], sh, &failures);
                if (s) { bad++; printf("# %s at %lu %s: step %d\n", name[o], (unsigned long)size[i], sh ? "shared" : "sole", s); }
                if (failures > worst) worst = failures;
                total += failures;
            }
        snprintf(line, sizeof line,
                 "%s survives every allocation failing in turn, at ten sizes, shared and not (up to %d)",
                 name[o], worst);
        ok(bad == 0, line);
    }
    ok(total > 40 && ha_live_blocks == live, "dozens of failures in all, and nothing left allocated");
}

static void t_vec_equal(void) {
    hamt_vec a, b;
    hamt_eq_ctx c;
    hv_val *vals = vals_new(5001), other = { 1, 0, NULL, NULL };
    int i, r;

    c.cx = NULL; c.eq = NULL; c.ud = NULL; c.visits = 0;
    hamt_vec_init(&a); hamt_vec_init(&b);
    ok(hamt_vec_equal(&c, &a, &b) == 1, "two empty vectors are equal");
    for (i = 0; i < 5000; i++) { v_push(&a, &vals[i]); v_push(&b, &vals[i]); }
    c.visits = 0;
    ok(hamt_vec_equal(&c, &a, &a) == 1 && c.visits == 0, "a vector equals itself without a look");
    ok(hamt_vec_equal(&c, &a, &b) == 1, "and another built the same way, value for value");

    v_set(&b, 2500, &other);
    ok(hamt_vec_equal(&c, &a, &b) == 0 && hamt_vec_equal(&c, &b, &a) == 0, "one value in the middle differing");
    v_set(&b, 2500, &vals[2500]);
    v_set(&b, 4999, &other);
    ok(hamt_vec_equal(&c, &a, &b) == 0, "or the last one, in the tail");
    v_set(&b, 4999, &vals[4999]);
    v_set(&b, 0, &other);
    ok(hamt_vec_equal(&c, &a, &b) == 0, "or the first");
    ok(hamt_vec_equal(&c, &a, &b) == 0 && (c.eq = eq_anything, hamt_vec_equal(&c, &a, &b)) == 1,
       "unless the comparison handed in says otherwise");
    c.eq = eq_stop;
    ok(hamt_vec_equal(&c, &a, &b) < 0, "and a comparison that stops, stops it");
    c.eq = NULL;
    v_set(&b, 0, &vals[0]);
    v_pop(&b);
    ok(hamt_vec_equal(&c, &a, &b) == 0, "one value fewer is not equal");
    v_push(&b, &vals[4999]);
    ok(hamt_vec_equal(&c, &a, &b) == 1, "and put back, it is again");

    /* A version one set away is compared for one leaf. */
    hamt_vec_clear(NULL, &b);
    hamt_vec_share(&b, &a);
    v_set(&b, 1234, &other);
    c.visits = 0;
    r = hamt_vec_equal(&c, &a, &b);
    ok(r == 0 && c.visits == 1, "a version one value away is told apart by looking into one leaf");
    c.eq = eq_anything; c.visits = 0;
    r = hamt_vec_equal(&c, &a, &b);
    ok(r == 1 && c.visits == 1, "and all the rest is skipped as the same memory");

    hamt_vec_clear(NULL, &a); hamt_vec_clear(NULL, &b);
    ok(vals_idle(vals, 5001) && other.refs == 1, "all given back");
    free(vals);
}

/* ---- joining and cutting vectors ---------------------------------------- */

/* A vector of vals[lo..hi), and the array it should equal. */
static void vr_build(hamt_vec *v, varr *a, hv_val *vals, size_t lo, size_t hi) {
    size_t i;
    hamt_vec_init(v);
    a->at = NULL; a->n = 0; a->cap = 0;
    for (i = lo; i < hi; i++) { v_push(v, &vals[i]); va_push(a, &vals[i]); }
}
static void va_concat(varr *out, const varr *a, const varr *b) {
    size_t i;
    out->at = NULL; out->n = 0; out->cap = 0;
    for (i = 0; i < a->n; i++) va_push(out, a->at[i]);
    for (i = 0; i < b->n; i++) va_push(out, b->at[i]);
}
/* The height a vector of this many values may have: one level more than a
 * regular one of the same size, and never less than one for a tree. */
static uint32_t height_allowed(const hamt_vec *v) {
    size_t in_tree = hamt_vec_tailoff(v), cap = HAMT_VEC_WIDTH;
    uint32_t h = 0;
    if (!in_tree) return 0;
    while (cap < in_tree) { cap *= HAMT_VEC_WIDTH; h++; }
    return h + 1;
}
static int vec_good(const hamt_vec *v, const varr *a) {
    return hamt_vec_check(v) == 0 && va_same(v, a)
        && hamt_vec_height(v) <= height_allowed(v) + (v->root ? 1 : 0);
}
/* The same, held to the tighter packing a join or a cut leaves behind. */
static int vec_packed(const hamt_vec *v, const varr *a) {
    return vec_good(v, a) && hamt_vec_check_spare(v, HAMT_VEC_EXTRAS) == 0;
}

/* Every pair of lengths from the list of sizes where a vector's shape
 * changes, joined both ways round. */
static void t_rrb_concat_pairs(void) {
    static const size_t len[] = { 0, 1, 2, 31, 32, 33, 63, 64, 65, 1023, 1024, 1025, 1056, 1057, 1089,
                                  2080, 32768, 32769, 32800, 32801 };
    enum { N = (int)(sizeof len / sizeof len[0]) };
    hv_val *vals = vals_new(70000);
    hamt_vec v[N], w[N];
    varr a[N], b[N];
    int i, j, bad = 0, worst_i = -1, worst_j = -1, code = 0;
    long live = ha_live_blocks;

    for (i = 0; i < N; i++) {
        vr_build(&v[i], &a[i], vals, 0, len[i]);
        vr_build(&w[i], &b[i], vals, 35000, 35000 + len[i]);     /* other values */
    }
    for (i = 0; i < N && !bad; i++)
        for (j = 0; j < N && !bad; j++) {
            hamt_vec r;
            varr want;
            va_concat(&want, &a[i], &b[j]);
            if (hamt_vec_concat(NULL, &r, &v[i], &w[j])) { bad = 1; code = 1; }
            else if (!vec_packed(&r, &want)) { bad = 1; code = hamt_vec_check(&r) ? 100 + hamt_vec_check(&r) : 2; }
            else if (!vec_good(&v[i], &a[i]) || !vec_good(&w[j], &b[j])) { bad = 1; code = 3; }
            else if (len[i] == 0 && (r.root != w[j].root || r.tail != w[j].tail)) { bad = 1; code = 4; }
            else if (len[j] == 0 && (r.root != v[i].root || r.tail != v[i].tail)) { bad = 1; code = 5; }
            if (bad) { worst_i = i; worst_j = j; }
            hamt_vec_clear(NULL, &r);
            free(want.at);
        }
    ok(!bad, "every pair of twenty lengths joined: right values, valid tree, operands untouched");
    if (bad) printf("# lengths %lu and %lu: code %d\n", (unsigned long)len[worst_i], (unsigned long)len[worst_j], code);

    for (i = 0; i < N; i++) { hamt_vec_clear(NULL, &v[i]); hamt_vec_clear(NULL, &w[i]); free(a[i].at); free(b[i].at); }
    ok(vals_idle(vals, 70000) && ha_live_blocks == live, "and everything given back");
    free(vals);
}

/* Every slice of every vector up to 70 long, then random cuts of large ones. */
static void t_rrb_slice(void) {
    hv_val *vals = vals_new(41000);
    hamt_vec v, r;
    varr a = { NULL, 0, 0 }, want;
    size_t n, from, len;
    int bad = 0, code = 0, k;
    size_t wn = 0, wf = 0, wl = 0;
    long live = ha_live_blocks, tried = 0;

    hamt_vec_init(&v);
    for (n = 0; n <= 70 && !bad; n++) {
        for (from = 0; from < n && !bad; from++)
            for (len = 1; from + len <= n && !bad; len++) {
                want.at = a.at + from; want.n = len; want.cap = len;
                tried++;
                if (hamt_vec_slice(NULL, &r, &v, from, len)) { bad = 1; code = 1; }
                else if (!vec_packed(&r, &want)) { bad = 1; code = hamt_vec_check(&r) ? 100 + hamt_vec_check(&r) : 2; }
                else if (from == 0 && len == n && (r.root != v.root || r.tail != v.tail)) { bad = 1; code = 3; }
                if (bad) { wn = n; wf = from; wl = len; }
                hamt_vec_clear(NULL, &r);
            }
        if (!bad && (hamt_vec_check(&v) || !va_same(&v, &a))) { bad = 1; code = 4; wn = n; }
        v_push(&v, &vals[n]); va_push(&a, &vals[n]);
    }
    ok(!bad, "every slice of every vector up to 70 long");
    if (bad) printf("# length %lu from %lu len %lu: code %d\n", (unsigned long)wn, (unsigned long)wf, (unsigned long)wl, code);
    printf("# %ld slices\n", tried);

    for (n = 71; n < 40000; n++) { v_push(&v, &vals[n]); va_push(&a, &vals[n]); }
    rng_state = 77;
    for (k = 0; k < 3000 && !bad; k++) {
        size_t total = a.n;
        from = rng() % total;
        len = 1 + rng() % (total - from);
        if (k % 5 == 0) len = 1 + rng() % (len < 70 ? len : 70);        /* some short ones */
        if (k % 7 == 0) from = from & ~(size_t)31;                      /* some on a leaf edge */
        if (from + len > total) len = total - from;
        want.at = a.at + from; want.n = len; want.cap = len;
        if (hamt_vec_slice(NULL, &r, &v, from, len)) { bad = 1; code = 1; }
        else if (!vec_packed(&r, &want)) { bad = 1; code = hamt_vec_check(&r) ? 100 + hamt_vec_check(&r) : 2; }
        if (bad) { wn = total; wf = from; wl = len; }
        /* A slice of a slice, and a slice pushed to and popped: the cut
         * edges have to carry ordinary updates. */
        if (!bad && len > 4) {
            hamt_vec r2;
            varr w2;
            size_t f2 = rng() % (len - 1), l2 = 1 + rng() % (len - f2);
            w2.at = want.at + f2; w2.n = l2; w2.cap = l2;
            if (hamt_vec_slice(NULL, &r2, &r, f2, l2) || !vec_good(&r2, &w2)) { bad = 1; code = 5; }
            hamt_vec_clear(NULL, &r2);
        }
        if (!bad) {
            int p;
            for (p = 0; p < 40 && !bad; p++) if (v_push(&r, &vals[40000 + p])) { bad = 1; code = 6; }
            if (!bad && (hamt_vec_check(&r) || r.count != len + 40 || hamt_vec_get(&r, len + 39) != &vals[40039]
                         || hamt_vec_get(&r, len - 1) != a.at[from + len - 1])) { bad = 1; code = 7; }
            for (p = 0; p < 40 + (int)(len < 50 ? len : 50) && !bad; p++) if (v_pop(&r)) { bad = 1; code = 8; }
            if (!bad && hamt_vec_check(&r)) { bad = 1; code = 9; }
            if (!bad && r.count && v_set(&r, r.count / 2, &vals[40999])) { bad = 1; code = 10; }
            if (!bad && r.count && (hamt_vec_get(&r, r.count / 2) != &vals[40999] || hamt_vec_check(&r))) { bad = 1; code = 11; }
            if (bad) { wn = total; wf = from; wl = len; }
        }
        hamt_vec_clear(NULL, &r);
    }
    ok(!bad, "3,000 random slices of a 40,000-long vector, each then sliced again, pushed to, popped and set");
    if (bad) printf("# length %lu from %lu len %lu: code %d\n", (unsigned long)wn, (unsigned long)wf, (unsigned long)wl, code);
    ok(hamt_vec_check(&v) == 0 && va_same(&v, &a), "and the vector they were cut from is untouched");

    hamt_vec_clear(NULL, &v);
    ok(vals_idle(vals, 41000) && ha_live_blocks == live, "everything given back");
    free(a.at); free(vals);
}

/* Insert and remove, built from the two operations as the library's own
 * callers build them. */
static int vx_insert(hamt_vec *v, size_t at, hv_val *val) {
    hamt_vec left, right, one, tmp, out;
    int rc = 0;
    hamt_vec_init(&left); hamt_vec_init(&right); hamt_vec_init(&one); hamt_vec_init(&tmp);
    if (at > 0 && hamt_vec_slice(NULL, &left, v, 0, at)) rc = -1;
    if (!rc && at < v->count && hamt_vec_slice(NULL, &right, v, at, v->count - at)) rc = -1;
    if (!rc && v_push(&one, val)) rc = -1;
    if (!rc && hamt_vec_concat(NULL, &tmp, &left, &one)) rc = -1;
    if (!rc && hamt_vec_concat(NULL, &out, &tmp, &right)) rc = -1;
    hamt_vec_clear(NULL, &left); hamt_vec_clear(NULL, &right); hamt_vec_clear(NULL, &one); hamt_vec_clear(NULL, &tmp);
    if (rc) return rc;
    hamt_vec_clear(NULL, v);
    *v = out;
    return 0;
}
static int vx_remove(hamt_vec *v, size_t at, size_t len) {
    hamt_vec left, right, out;
    int rc = 0;
    hamt_vec_init(&left); hamt_vec_init(&right);
    if (at > 0 && hamt_vec_slice(NULL, &left, v, 0, at)) rc = -1;
    if (!rc && at + len < v->count && hamt_vec_slice(NULL, &right, v, at + len, v->count - at - len)) rc = -1;
    if (!rc && hamt_vec_concat(NULL, &out, &left, &right)) rc = -1;
    hamt_vec_clear(NULL, &left); hamt_vec_clear(NULL, &right);
    if (rc) return rc;
    hamt_vec_clear(NULL, v);
    *v = out;
    return 0;
}
static void va_insert(varr *a, size_t at, hv_val *val) {
    va_push(a, val);
    memmove(a->at + at + 1, a->at + at, (a->n - 1 - at) * sizeof *a->at);
    a->at[at] = val;
}
static void va_remove(varr *a, size_t at, size_t len) {
    memmove(a->at + at, a->at + at + len, (a->n - at - len) * sizeof *a->at);
    a->n -= len;
}

/* Every kind of edit at random against the array, the checker after each
 * one. A tree only gets into a bad shape after many seams, so this is the
 * test that finds an invariant drifting. */
static int rrb_edit_model(int steps, uint32_t seed, size_t ceiling, long *most_steps) {
    hamt_vec v, snap[40];
    varr a = { NULL, 0, 0 }, sa[40];
    hv_val *vals = vals_new(steps * 40 + 100);
    int nsnap = 0, s, i, rc = 0, next = 0;
    long live = ha_live_blocks;

    rng_state = seed;
    hamt_vec_init(&v);
    for (s = 0; s < steps && !rc; s++) {
        uint32_t op = rng() % 100;
        if (a.n > ceiling) op = 60;                    /* too big: cut it down */
        if (op < 25 || a.n == 0) {                     /* insert anywhere */
            size_t at = rng() % (a.n + 1);
            if (vx_insert(&v, at, &vals[next])) rc = 1;
            va_insert(&a, at, &vals[next++]);
        }
        else if (op < 40) {                            /* remove a few anywhere */
            size_t at = rng() % a.n, len = 1 + rng() % 5;
            if (at + len > a.n) len = a.n - at;
            if (vx_remove(&v, at, len)) rc = 2;
            va_remove(&a, at, len);
        }
        else if (op < 55) {                            /* join a fresh run on, either end */
            hamt_vec run, out;
            int n = 1 + (int)(rng() % 39), front = (int)(rng() % 2);
            size_t before = a.n;
            hamt_vec_init(&run);
            for (i = 0; i < n; i++) v_push(&run, &vals[next + i]);
            if (hamt_vec_concat(NULL, &out, front ? &run : &v, front ? &v : &run)) rc = 3;
            else { hamt_vec_clear(NULL, &v); v = out; }
            hamt_vec_clear(NULL, &run);
            for (i = 0; i < n; i++) va_insert(&a, front ? (size_t)i : before + (size_t)i, &vals[next + i]);
            next += n;
        }
        else if (op < 65) {                            /* keep a slice */
            size_t from = rng() % a.n, len = 1 + rng() % (a.n - from);
            hamt_vec out;
            if (a.n > ceiling) { from = a.n / 4; len = a.n / 2; }
            if (hamt_vec_slice(NULL, &out, &v, from, len)) rc = 4;
            else { hamt_vec_clear(NULL, &v); v = out; }
            va_remove(&a, from + len, a.n - from - len);
            va_remove(&a, 0, from);
        }
        else if (op < 80) { if (v_push(&v, &vals[next])) rc = 5; va_push(&a, &vals[next++]); }
        else if (op < 90) { if (v_pop(&v)) rc = 6; a.n--; }
        else {
            size_t at = rng() % a.n;
            if (v_set(&v, at, &vals[next])) rc = 7;
            a.at[at] = &vals[next++];
        }
        if (!rc && v.count != a.n) rc = 8;
        if (!rc && hamt_vec_check(&v)) rc = 100 + hamt_vec_check(&v);
        if (!rc && hamt_vec_height(&v) > height_allowed(&v) + (v.root ? 1 : 0)) rc = 9;
        if (!rc && (s % 40 == 0 || s > steps - 30) && !va_same(&v, &a)) rc = 10;
        if (!rc && a.n) {
            size_t at = rng() % a.n;
            long before = vec_steps;
            if (hamt_vec_get(&v, at) != a.at[at]) rc = 11;
            if (vec_steps - before > *most_steps) *most_steps = vec_steps - before;
        }
        if (!rc && s % (steps / 36 + 1) == 0 && nsnap < 40) {
            hamt_vec_share(&snap[nsnap], &v);
            sa[nsnap].n = a.n; sa[nsnap].cap = a.n;
            sa[nsnap].at = (hv_val **)malloc((a.n ? a.n : 1) * sizeof(hv_val *));
            memcpy(sa[nsnap].at, a.at, a.n * sizeof(hv_val *));
            nsnap++;
        }
    }
    if (rc) printf("# stopped at step %d of %d, %lu values\n", s, steps, (unsigned long)a.n);
    for (i = 0; i < nsnap; i++) {
        if (!rc && (hamt_vec_check(&snap[i]) || !va_same(&snap[i], &sa[i]))) rc = 12;
        hamt_vec_clear(NULL, &snap[i]);
        free(sa[i].at);
    }
    hamt_vec_clear(NULL, &v);
    if (!rc && !vals_idle(vals, steps * 40 + 100)) rc = 13;
    if (!rc && ha_live_blocks != live) rc = 14;
    free(a.at); free(vals);
    return rc;
}

static void t_rrb_model(void) {
    long most = 0;
    int rc;
    rc = rrb_edit_model(20000, 11, 20000, &most);
    ok(rc == 0, "20,000 random inserts, removes, joins, slices, pushes, pops and sets, checked after each");
    if (rc) printf("# code %d\n", rc);
    rc = rrb_edit_model(20000, 12, 600, &most);
    ok(rc == 0, "20,000 more held under 600 values, where every edit is near the root");
    if (rc) printf("# code %d\n", rc);
    rc = rrb_edit_model(6000, 13, 200000, &most);
    ok(rc == 0, "6,000 more left to grow");
    if (rc) printf("# code %d\n", rc);
    rc = rrb_edit_model(4000, 14, 40, &most);
    ok(rc == 0, "4,000 more held under 40 values, where the tail is most of the vector");
    if (rc) printf("# code %d\n", rc);
    printf("# the most a lookup stepped along size tables, over all four runs: %ld\n", most);
    ok(most <= 2 * 4, "and no lookup stepped along a table more than twice a level");
}

/* The shapes that are worst by construction. */
static void t_rrb_degenerate(void) {
    hv_val *vals = vals_new(12000);
    hamt_vec v, one, out, big, small;
    varr a = { NULL, 0, 0 }, wb, ws, want;
    int i, bad = 0;
    long calls, most = 0;
    size_t k;

    /* Ten thousand one-value vectors joined on, one at a time, at the back. */
    hamt_vec_init(&v);
    for (i = 0; i < 10000 && !bad; i++) {
        hamt_vec_init(&one); v_push(&one, &vals[i]);
        if (hamt_vec_concat(NULL, &out, &v, &one)) bad = 1;
        else { hamt_vec_clear(NULL, &v); v = out; }
        hamt_vec_clear(NULL, &one);
        va_push(&a, &vals[i]);
        if (i % 500 == 0 && !vec_packed(&v, &a)) bad = 1;
    }
    ok(!bad && vec_packed(&v, &a), "10,000 one-value vectors joined on at the back");
    printf("# height %u for %lu values\n", hamt_vec_height(&v), (unsigned long)v.count);
    hamt_vec_clear(NULL, &v); a.n = 0;

    /* And at the front. */
    bad = 0;
    for (i = 0; i < 10000 && !bad; i++) {
        hamt_vec_init(&one); v_push(&one, &vals[i]);
        if (hamt_vec_concat(NULL, &out, &one, &v)) bad = 1;
        else { hamt_vec_clear(NULL, &v); v = out; }
        hamt_vec_clear(NULL, &one);
        va_insert(&a, 0, &vals[i]);
        if (i % 500 == 0 && !vec_packed(&v, &a)) bad = 1;
    }
    ok(!bad && vec_packed(&v, &a), "10,000 one-value vectors joined on at the front");
    printf("# height %u for %lu values\n", hamt_vec_height(&v), (unsigned long)v.count);
    for (k = 0; k < v.count; k++) {
        long before = vec_steps;
        if (hamt_vec_get(&v, k) != a.at[k]) bad = 1;
        if (vec_steps - before > most) most = vec_steps - before;
    }
    ok(!bad, "every value of it found by index");
    printf("# the most a lookup stepped along size tables there: %ld\n", most);
    ok(most <= 2 * (long)hamt_vec_height(&v), "stepping along a table no more than twice a level");

    /* One off the front and onto the back, five thousand times. */
    bad = 0;
    for (i = 0; i < 5000 && !bad; i++) {
        hamt_vec head, rest;
        hv_val *first = a.at[0];
        if (hamt_vec_slice(NULL, &head, &v, 0, 1) || hamt_vec_slice(NULL, &rest, &v, 1, v.count - 1)
            || hamt_vec_concat(NULL, &out, &rest, &head)) { bad = 1; break; }
        hamt_vec_clear(NULL, &head); hamt_vec_clear(NULL, &rest);
        hamt_vec_clear(NULL, &v); v = out;
        va_remove(&a, 0, 1); va_push(&a, first);
        if (hamt_vec_check(&v)) bad = 1;
        if (i % 250 == 0 && !vec_packed(&v, &a)) bad = 1;
    }
    ok(!bad && vec_good(&v, &a), "rotated by one 5,000 times, valid after every turn");
    hamt_vec_clear(NULL, &v); free(a.at);

    /* A tall tree and a short one, each way round. */
    {
        hv_val bulk = { 1, 0, NULL, NULL };
        size_t n = 1100010;
        hamt_vec_init(&big);
        wb.at = (hv_val **)malloc(n * sizeof *wb.at); wb.n = n; wb.cap = n;
        for (k = 0; k < n; k++) { v_push(&big, &bulk); wb.at[k] = &bulk; }
        vr_build(&small, &ws, vals, 0, 40);

        calls = ha_calls;
        va_concat(&want, &wb, &ws);
        ok(hamt_vec_concat(NULL, &out, &big, &small) == 0 && vec_good(&out, &want),
           "a vector four levels deep joined to one of 40 values");
        hamt_vec_clear(NULL, &out); free(want.at);

        calls = ha_calls;
        va_concat(&want, &ws, &wb);
        ok(hamt_vec_concat(NULL, &out, &small, &big) == 0 && vec_good(&out, &want),
           "and the 40 joined to the front of it");
        printf("# putting 40 values in front of 1,100,010 allocated %ld blocks\n", ha_calls - calls);
        ok(ha_calls - calls <= 60, "which copies a path and not the vector");
        hamt_vec_clear(NULL, &out); free(want.at);

        calls = ha_calls;
        va_concat(&want, &wb, &wb);
        ok(hamt_vec_concat(NULL, &out, &big, &big) == 0 && out.count == 2 * n && hamt_vec_check(&out) == 0
           && hamt_vec_get(&out, n) == &bulk && hamt_vec_get(&out, 2 * n - 1) == &bulk,
           "the big one joined to itself");
        printf("# joining 1,100,010 values to 1,100,010 allocated %ld blocks\n", ha_calls - calls);
        ok(ha_calls - calls <= 60, "which copies a path too");
        hamt_vec_clear(NULL, &out); free(want.at);

        calls = ha_calls;
        ok(hamt_vec_slice(NULL, &out, &big, 500000, 100000) == 0 && out.count == 100000 && hamt_vec_check(&out) == 0,
           "100,000 values cut from its middle");
        printf("# that slice allocated %ld blocks\n", ha_calls - calls);
        ok(ha_calls - calls <= 40, "copying two paths and not the slice");
        hamt_vec_clear(NULL, &out);

        hamt_vec_clear(NULL, &big); hamt_vec_clear(NULL, &small);
        free(wb.at); free(ws.at);
        ok(bulk.refs == 1, "and all of that given back");
    }
    ok(vals_idle(vals, 12000), "everything given back");
    free(vals);
}

/* No memory, at every allocation in turn. */
static void t_rrb_oom(void) {
    /* 5 and 32 are a second vector that is a tail and nothing else; 20500
     * twice is two trees whose roots do not fit under one. */
    static const size_t la[] = { 1, 33, 1057, 2081, 20500, 40000 }, lb[] = { 5, 32, 33, 40, 1057, 20500, 33000 };
    hv_val *vals = vals_new(80000);
    int i, j, k, bad = 0, failures = 0, slices = 0;
    long live = ha_live_blocks;

    for (i = 0; i < 6 && !bad; i++)
        for (j = 0; j < 7 && !bad; j++) {
            hamt_vec a, b, r;
            varr wa, wb;
            int done = 0;
            vr_build(&a, &wa, vals, 0, la[i]);
            vr_build(&b, &wb, vals, 40000, 40000 + lb[j]);
            for (k = 0; k < 400 && !bad && !done; k++) {
                long at = ha_live_blocks, held = hv_retains - hv_releases;
                ha_fail_at = ha_calls + k;
                if (hamt_vec_concat(NULL, &r, &a, &b) == 0) done = 1;
                ha_fail_at = -1;
                if (done) { if (hamt_vec_check(&r) || r.count != la[i] + lb[j]) bad = 1; hamt_vec_clear(NULL, &r); break; }
                failures++;
                if (r.count || r.root || r.tail) bad = 2;
                else if (ha_live_blocks != at || hv_retains - hv_releases != held) bad = 3;
                else if (!vec_good(&a, &wa) || !vec_good(&b, &wb)) bad = 4;
            }
            if (!done && !bad) bad = 5;
            hamt_vec_clear(NULL, &a); hamt_vec_clear(NULL, &b); free(wa.at); free(wb.at);
        }
    ok(!bad, "a join survives every allocation failing in turn, over forty-two pairs of sizes");
    if (bad) printf("# code %d\n", bad);
    printf("# %d failed allocations\n", failures);

    bad = 0;
    {
        /* The last four end exactly where a subtree ends, so what is left
         * shares its right-hand edge with the vector it was cut from and
         * taking its tail out has nodes to copy. */
        static const size_t cut[][2] = { { 0, 1 }, { 5, 20 }, { 31, 2 }, { 100, 900 }, { 33, 1 }, { 1000, 39000 },
                                         { 17, 39983 }, { 39990, 10 }, { 20000, 33 }, { 1, 39998 },
                                         { 0, 32 }, { 0, 1024 }, { 5, 2043 }, { 100, 32668 } };
        hamt_vec v, r;
        varr wv;
        vr_build(&v, &wv, vals, 0, 40000);
        for (i = 0; i < 14 && !bad; i++) {
            int done = 0;
            for (k = 0; k < 200 && !bad && !done; k++) {
                long at = ha_live_blocks, held = hv_retains - hv_releases;
                ha_fail_at = ha_calls + k;
                if (hamt_vec_slice(NULL, &r, &v, cut[i][0], cut[i][1]) == 0) done = 1;
                ha_fail_at = -1;
                if (done) { if (hamt_vec_check(&r) || r.count != cut[i][1]) bad = 1; hamt_vec_clear(NULL, &r); break; }
                slices++;
                if (r.count || r.root || r.tail) bad = 2;
                else if (ha_live_blocks != at || hv_retains - hv_releases != held) bad = 3;
                else if (!vec_good(&v, &wv)) bad = 4;
            }
            if (!done && !bad) bad = 5;
        }
        hamt_vec_clear(NULL, &v); free(wv.at);
    }
    ok(!bad, "a slice survives every allocation failing in turn, over fourteen cuts");
    if (bad) printf("# code %d\n", bad);
    printf("# %d failed allocations\n", slices);
    ok(failures > 100 && slices > 30 && vals_idle(vals, 80000) && ha_live_blocks == live,
       "and after all those failures nothing is held");
    free(vals);
}

/* A vector that has been through a few hundred random inserts, removes and
 * joins: relaxed all over, and as loose along its edges as the bound lets
 * it be. Its values are vals[*next ...]. */
static int rrb_scramble(hamt_vec *v, varr *a, hv_val *vals, int *next, int steps, uint32_t seed) {
    int s, i;
    rng_state = seed;
    hamt_vec_init(v);
    a->at = NULL; a->n = 0; a->cap = 0;
    for (s = 0; s < steps; s++) {
        uint32_t op = rng() % 100;
        if (op < 45 || a->n == 0) {
            size_t at = rng() % (a->n + 1);
            if (vx_insert(v, at, &vals[*next])) return -1;
            va_insert(a, at, &vals[(*next)++]);
        }
        else if (op < 80) {
            hamt_vec run, out;
            int n = 1 + (int)(rng() % 39), front = (int)(rng() % 2);
            size_t before = a->n;
            hamt_vec_init(&run);
            for (i = 0; i < n; i++) v_push(&run, &vals[*next + i]);
            if (hamt_vec_concat(NULL, &out, front ? &run : v, front ? v : &run)) return -1;
            hamt_vec_clear(NULL, v); *v = out;
            hamt_vec_clear(NULL, &run);
            for (i = 0; i < n; i++) va_insert(a, front ? (size_t)i : before + (size_t)i, &vals[*next + i]);
            *next += n;
        }
        else {
            size_t at = rng() % a->n, len = 1 + rng() % 3;
            if (at + len > a->n) len = a->n - at;
            if (vx_remove(v, at, len)) return -1;
            va_remove(a, at, len);
        }
    }
    return 0;
}

/* No memory, on vectors like that: joined to one another, sliced, and
 * pushed to, popped and set while something else holds them. This is where
 * a join really does repack and an update really does copy a size table. */
static void t_rrb_oom_relaxed(void) {
    enum { N = 6 };
    hv_val *vals = vals_new(60000), fresh = { 1, 0, NULL, NULL };
    hamt_vec v[N], r;
    varr a[N];
    int next = 0, i, j, k, bad = 0, joins = 0, cuts = 0, edits = 0;
    long live = ha_live_blocks;

    for (i = 0; i < N; i++)
        if (rrb_scramble(&v[i], &a[i], vals, &next, 500 + 150 * i, 100 + (uint32_t)i)) bad = 1;
    ok(!bad && next < 59000, "six vectors scrambled by a few hundred random edits each");

    for (i = 0; i < N && !bad; i++)
        for (j = 0; j < N && !bad; j++) {
            int done = 0;
            for (k = 0; k < 600 && !bad && !done; k++) {
                long at = ha_live_blocks, held = hv_retains - hv_releases;
                ha_fail_at = ha_calls + k;
                if (hamt_vec_concat(NULL, &r, &v[i], &v[j]) == 0) done = 1;
                ha_fail_at = -1;
                if (done) {
                    /* Not held to the packing bound: a join repacks its
                     * seam, and these operands were loose elsewhere. */
                    varr want;
                    va_concat(&want, &a[i], &a[j]);
                    if (!vec_good(&r, &want)) bad = 1;
                    free(want.at);
                    hamt_vec_clear(NULL, &r);
                    break;
                }
                joins++;
                if (r.count || r.root || r.tail) bad = 2;
                else if (ha_live_blocks != at || hv_retains - hv_releases != held) bad = 3;
                else if (hamt_vec_check(&v[i]) || hamt_vec_check(&v[j])) bad = 4;
            }
            if (!done && !bad) bad = 5;
        }
    ok(!bad, "every pair of them joined, with every allocation failing in turn");
    if (bad) printf("# code %d\n", bad);

    bad = 0;
    rng_state = 4242;
    for (i = 0; i < N && !bad; i++)
        for (j = 0; j < 25 && !bad; j++) {
            size_t from = rng() % a[i].n, len = 1 + rng() % (a[i].n - from);
            int done = 0;
            for (k = 0; k < 300 && !bad && !done; k++) {
                long at = ha_live_blocks, held = hv_retains - hv_releases;
                ha_fail_at = ha_calls + k;
                if (hamt_vec_slice(NULL, &r, &v[i], from, len) == 0) done = 1;
                ha_fail_at = -1;
                if (done) {
                    varr want;
                    want.at = a[i].at + from; want.n = len; want.cap = len;
                    if (!vec_good(&r, &want)) bad = 1;
                    hamt_vec_clear(NULL, &r);
                    break;
                }
                cuts++;
                if (r.count || r.root || r.tail) bad = 2;
                else if (ha_live_blocks != at || hv_retains - hv_releases != held) bad = 3;
                else if (hamt_vec_check(&v[i])) bad = 4;
            }
            if (!done && !bad) bad = 5;
        }
    ok(!bad, "150 random slices of them, with every allocation failing in turn");
    if (bad) printf("# code %d\n", bad);

    /* Updates in place on a second struct, while v[i] still holds every
     * node: each has to copy its path, tables and all. */
    bad = 0;
    for (i = 0; i < N && !bad; i++) {
        hamt_vec w;
        varr wa;
        int step;
        hamt_vec_share(&w, &v[i]);
        wa.n = a[i].n; wa.cap = a[i].n + 200;
        wa.at = (hv_val **)malloc(wa.cap * sizeof *wa.at);
        memcpy(wa.at, a[i].at, a[i].n * sizeof *wa.at);
        for (step = 0; step < 150 && !bad; step++) {
            int kind = step % 3, done = 0;
            size_t at = wa.n ? rng() % wa.n : 0;
            for (k = 0; k < 60 && !bad && !done; k++) {
                long held = hv_retains - hv_releases;
                int rc;
                ha_fail_at = ha_calls + k;
                rc = kind == 0 ? v_push(&w, &fresh) : kind == 1 ? v_set(&w, at, &fresh) : v_pop(&w);
                ha_fail_at = -1;
                if (rc == 0) { done = 1; break; }
                edits++;
                if (hamt_vec_check(&w) || !va_same(&w, &wa)) bad = 2;
                else if (hv_retains - hv_releases != held) bad = 3;
            }
            if (!done && !bad) bad = 5;
            if (kind == 0) va_push(&wa, &fresh);
            else if (kind == 1) wa.at[at] = &fresh;
            else wa.n--;
            if (!bad && (hamt_vec_check(&w) || !va_same(&w, &wa))) bad = 6;
        }
        if (!bad && (hamt_vec_check(&v[i]) || !va_same(&v[i], &a[i]))) bad = 7;
        hamt_vec_clear(NULL, &w);
        free(wa.at);
    }
    ok(!bad, "pushed to, set and popped 150 times each while shared, with every allocation failing in turn");
    if (bad) printf("# code %d\n", bad);
    printf("# %d, %d and %d failed allocations\n", joins, cuts, edits);

    for (i = 0; i < N; i++) { hamt_vec_clear(NULL, &v[i]); free(a[i].at); }
    ok(joins > 300 && cuts > 300 && edits > 300 && vals_idle(vals, 60000) && fresh.refs == 1
       && ha_live_blocks == live, "hundreds of failures of each kind, and nothing held after them");
    free(vals);
}

/* A slice far smaller than the vector it came from must not stay as tall. */
static void t_rrb_slice_height(void) {
    hv_val *vals = vals_new(40000);
    hamt_vec v, r;
    varr a, want;
    static const size_t cut[][2] = { { 32750, 40 }, { 32767, 2 }, { 1010, 30 }, { 1023, 34 },
                                     { 32700, 1100 }, { 31, 2 }, { 32767, 34 } };
    int i, bad = 0;

    vr_build(&v, &a, vals, 0, 40000);
    for (i = 0; i < 7 && !bad; i++) {
        want.at = a.at + cut[i][0]; want.n = cut[i][1]; want.cap = cut[i][1];
        if (hamt_vec_slice(NULL, &r, &v, cut[i][0], cut[i][1]) || !vec_packed(&r, &want)) bad = 1;
        else if (hamt_vec_height(&r) > height_allowed(&r)) bad = 2;
        if (bad) printf("# from %lu len %lu: height %u, allowed %u\n", (unsigned long)cut[i][0],
                        (unsigned long)cut[i][1], hamt_vec_height(&r), height_allowed(&r));
        hamt_vec_clear(NULL, &r);
    }
    ok(!bad, "a short slice across the widest boundaries of a tall vector is no taller than its size needs");
    hamt_vec_clear(NULL, &v); free(a.at);
    ok(vals_idle(vals, 40000), "everything given back");
    free(vals);
}

/* The one append that needs a size table AND a new path: a regular node
 * with room, above the lowest level, whose last child has all 32 of its
 * slots taken and is still not full, because one of its leaves is short.
 * Built by joining 1,029 values to 1,002: the first becomes a full node and
 * a leaf of five, and the leaf of five and the second's 31 leaves make the
 * 32 slots of the last child, holding 997. */
static void t_rrb_oom_table(void) {
    hv_val *vals = vals_new(2200), fresh = { 1, 0, NULL, NULL };
    hamt_vec a, b, r;
    varr wa, wb, want;
    int k, bad = 0, failures = 0, i;
    long live;

    vr_build(&a, &wa, vals, 0, 1029);
    vr_build(&b, &wb, vals, 1100, 1100 + 1002);
    hamt_vec_concat(NULL, &r, &a, &b);
    va_concat(&want, &wa, &wb);
    for (i = 0; i < 22; i++) { v_push(&r, &fresh); va_push(&want, &fresh); }
    ok(vec_good(&r, &want) && r.shift == 10 && r.root->len == 2 && !r.root->sizes
       && r.tail->len == 32 && ((hamt_vnode *)r.root->slot[1])->len == 32
       && hamt_vnode_count((hamt_vnode *)r.root->slot[1], 5) == 997,
       "a regular root with room, over a last child whose 32 leaves hold 997");

    live = ha_live_blocks;
    for (k = 0; k < 20 && !bad; k++) {
        long held = hv_retains - hv_releases;
        int rc;
        ha_fail_at = ha_calls + k;
        rc = v_push(&r, &fresh);
        ha_fail_at = -1;
        if (rc == 0) break;
        failures++;
        if (ha_live_blocks != live) bad = 1;
        else if (hv_retains - hv_releases != held) bad = 2;
        else if (!vec_good(&r, &want)) bad = 3;
    }
    va_push(&want, &fresh);
    ok(!bad && failures == 3, "the push that gives it a table fails cleanly at each of its three allocations");
    if (bad || failures != 3) printf("# code %d after %d failures\n", bad, failures);
    ok(vec_good(&r, &want) && r.root->sizes && r.root->len == 3 && r.root->sizes[1] == 1024 + 997
       && r.root->sizes[2] == 1024 + 997 + 32,
       "and then succeeds, leaving the root with a table that says what is under it");

    hamt_vec_clear(NULL, &r); hamt_vec_clear(NULL, &a); hamt_vec_clear(NULL, &b);
    free(wa.at); free(wb.at); free(want.at);
    ok(vals_idle(vals, 2200) && fresh.refs == 1, "everything given back");
    free(vals);
}

static void t_rrb(void) {
    t_rrb_concat_pairs();
    t_rrb_slice();
    t_rrb_model();
    t_rrb_degenerate();
    t_rrb_oom();
    t_rrb_oom_relaxed();
    t_rrb_oom_table();
    t_rrb_slice_height();
}

/* What a repack and a cut share and what they copy. None of this changes
 * what a vector holds or whether it is well formed, so nothing else in this
 * file can see it: only the node a result uses, and how many it made. */
static void t_rrb_costs(void) {
    static hv_val val;
    void *slots[HAMT_VEC_WIDTH];
    static const uint32_t lens[5] = { 31, 5, 5, 5, 5 };
    hamt_vlist all, out;
    hamt_vec v;
    hamt_vnode *cut;
    long calls;
    uint32_t i;
    int good = 1;

    val.refs = 1;
    for (i = 0; i < HAMT_VEC_WIDTH; i++) slots[i] = &val;

    /* Five leaves holding 51 values, where two would do: the run is one
     * node too long, so one node is emptied, and it is the first that has
     * more than a slot to spare. The leaf of 31 is left alone and shared. */
    all.len = 5;
    for (i = 0; i < 5; i++) {
        all.n[i] = hamt_vnode_leaf(NULL, slots, lens[i]);
        if (!all.n[i]) good = 0;
    }
    calls = ha_calls;
    ok(good && hamt_rrb_repack(NULL, &all, 0, &out) == 0, "repack: five leaves of 31, 5, 5, 5 and 5");
    ok(out.len == 4, "repack: come out as four, one more than the fewest and no fewer");
    ok(out.len == 4 && out.n[0]->len == 31 && out.n[1]->len == 10
       && out.n[2]->len == 5 && out.n[3]->len == 5,
       "repack: of 31, 10, 5 and 5");
    ok(out.len == 4 && out.n[0] == all.n[0], "repack: the nearly full leaf is the same node, not a copy");
    ok(out.len == 4 && out.n[2] == all.n[3] && out.n[3] == all.n[4],
       "repack: and so are the two the emptying did not reach");
    ok(ha_calls == calls + 1, "repack: one node was made for all of it");
    hamt_vlist_release(NULL, &out);
    hamt_vlist_release(NULL, &all);

    /* A cut that lands between two children leaves the one before it whole,
     * and a whole node is shared. */
    hamt_vec_init(&v);
    for (i = 0; i < 5000; i++) if (hamt_vec_push(NULL, &v, &val)) good = 0;
    ok(good && v.shift == 2 * HAMT_VEC_BITS && v.root->len >= 3, "cut: a vector of 5,000 is three levels");
    calls = ha_calls;
    cut = hamt_rrb_cut_right(NULL, v.root, v.shift, 2048);
    ok(cut != NULL && cut->len == 2 && hamt_vnode_count(cut, v.shift) == 2048,
       "cut: keeping 2,048 keeps the first two children");
    ok(cut && cut->slot[0] == v.root->slot[0] && cut->slot[1] == v.root->slot[1],
       "cut: and both are the same nodes, the second as much as the first");
    ok(ha_calls == calls + 1, "cut: one node was made, the new top");
    if (cut) hamt_vnode_release(NULL, cut);
    calls = ha_calls;
    cut = hamt_rrb_cut_right(NULL, v.root, v.shift, 2049);
    ok(cut != NULL && cut->len == 3 && cut->slot[1] == v.root->slot[1] && cut->slot[2] != v.root->slot[2],
       "cut: one value more and the third child is a new node");
    ok(ha_calls == calls + 3, "cut: a path of three: the leaf, its parent and the top");
    if (cut) hamt_vnode_release(NULL, cut);
    hamt_vec_clear(NULL, &v);
}

static void t_vec(void) {
    long live = ha_live_blocks;
    t_vec_boundaries();
    t_vec_model();
    t_vec_big();
    t_vec_reenter();
    t_vec_oom();
    t_vec_equal();
    t_rrb();
    t_rrb_costs();
    ok(ha_live_blocks == live, "the vector tests leave nothing allocated");
}

int main(void) {
    t_popcnt();
    t_pool();
#ifdef HAMT_HARNESS_POOL
    hamt_pool_open(&ha_pool);
#endif
    t_hash();
    hamt_seed = 0x1234567;
    hamt_hash_set_bits(64);
    t_entry_basic();
    t_entry_keys();
    t_entry_set_member();
    t_entry_reenter();
    t_entry_oom();

    t_map_small();
    t_map_slots();
    t_map_deepest();
    t_map_model();
    t_map_persist();
    t_map_canonical();
    t_map_sharing();
    t_map_reenter();
    t_map_oom();
    t_map_release_order();
    t_map_pair_oom();
    t_iter();
    t_algebra();
    t_mut();
    t_mut_contract();
    t_sets();
    t_vec();

    ok(ha_live_blocks == 0 && ha_live_bytes == 0, "nothing is allocated at the end");
#ifdef HAMT_HARNESS_POOL
    ok(hamt_pool_held(&ha_pool) > 0, "the pool was in use throughout");
    hamt_pool_close(&ha_pool);
#endif
    ok(hr_live == 0 && hr_live_bytes == 0, "and nothing is left in a pool");
    printf("1..%d\n", t_n);
    return t_bad ? 1 : 0;
}
