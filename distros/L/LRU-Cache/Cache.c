/*
 * Cache.c - Ultra-fast LRU cache with O(1) operations
 *
 * Optimizations:
 *  1. Inline get_lru_cache with LIKELY/UNLIKELY fast path
 *  2. Inline key storage in entry struct (no key SV overhead)
 *  3. PERL_HASH for hash randomization + native integration
 *  4. Avoid sv_mortalcopy in delete (SvREFCNT_inc + sv_2mortal)
 *  5. UNLIKELY/LIKELY branch hints on hot paths
 *  6. Combined hash_find_and_remove for single-pass delete
 *  7. SvPV_const to avoid spurious string overload calls
 *  8. Entry freelist pool to reduce malloc/free churn
 *  9. Variable-length entry allocation for inline keys
 * 10. PERL_STATIC_INLINE on critical internal functions
 * 11. Dynamic rehash when load factor exceeds threshold
 * 12. Struct field reorder for cache-line locality in hash_find
 * 13. sv_setsv in-place value update (no alloc+free per update)
 * 14. Single 'if' eviction instead of while loop
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "include/lru_compat.h"

/* ============================================
   Branch prediction hints (#5)
   ============================================ */
#ifndef UNLIKELY
#  ifdef __GNUC__
#    define UNLIKELY(x) __builtin_expect(!!(x), 0)
#    define LIKELY(x)   __builtin_expect(!!(x), 1)
#  else
#    define UNLIKELY(x) (x)
#    define LIKELY(x)   (x)
#  endif
#endif

/* ============================================
   Entry struct with inline key (#2, #9)
   Key bytes stored directly in struct tail --
   eliminates SV allocation and SvPV dereference
   on every hash_find comparison.
   ============================================ */
typedef struct lru_entry {
    /* Hot fields for hash_find -- packed in first cache line (#12) */
    U32               hash;       /* Cached hash value */
    U32               klen;       /* Key byte length */
    struct lru_entry *hash_next;  /* Hash chain (singly-linked) */
    SV               *value;
    /* Warm fields for LRU list ops */
    struct lru_entry *prev;       /* LRU doubly-linked list */
    struct lru_entry *next;
    U32               alloc_klen; /* Allocated key capacity (for freelist) */
    char              key[1];     /* Variable-length inline key, NUL-terminated */
} LRUEntry;

#define LRU_ENTRY_SIZE(kl)  (offsetof(LRUEntry, key) + (kl) + 1)

/* ============================================
   LRU cache structure (#8, #11)
   ============================================ */
#define LRU_FREELIST_MAX   256
#define LRU_LOAD_NUMER     3   /* rehash threshold = bucket_count * 3/4 */
#define LRU_LOAD_DENOM     4

typedef struct {
    LRUEntry **buckets;
    LRUEntry  *head;             /* Most recently used */
    LRUEntry  *tail;             /* Least recently used */
    LRUEntry  *freelist;         /* Recycled entries (LIFO via hash_next) */
    IV         capacity;
    IV         size;
    IV         bucket_count;     /* Always power of 2 */
    IV         bucket_mask;      /* bucket_count - 1 */
    IV         freelist_count;
    IV         rehash_threshold; /* Grow when size exceeds this */
} LRUCache;

/* ============================================
   Custom op descriptors
   ============================================ */
static XOP lru_get_xop;
static XOP lru_set_xop;
static XOP lru_exists_xop;
static XOP lru_peek_xop;
static XOP lru_delete_xop;

static XOP lru_func_get_xop;
static XOP lru_func_set_xop;
static XOP lru_func_exists_xop;
static XOP lru_func_peek_xop;
static XOP lru_func_delete_xop;
static XOP lru_func_oldest_xop;
static XOP lru_func_newest_xop;

/* ============================================
   Magic vtable
   ============================================ */
static int lru_cache_free(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL lru_cache_vtbl = {
    NULL, NULL, NULL, NULL,
    lru_cache_free,
    NULL, NULL, NULL
};

/* ============================================
   Fast cache extraction (#1, #10)
   Single mg_find -- no vtbl loop, UNLIKELY on
   error paths.  PERL_STATIC_INLINE for hot paths.
   ============================================ */
PERL_STATIC_INLINE LRUCache* get_lru_cache(pTHX_ SV *obj) {
    MAGIC *mg;
    if (UNLIKELY(!SvROK(obj))) croak("Not a reference");
    mg = mg_find(SvRV(obj), PERL_MAGIC_ext);
    if (LIKELY(mg != NULL))
        return (LRUCache*)mg->mg_ptr;
    croak("Not an LRU::Cache object");
    return NULL; /* unreachable */
}

/* ============================================
   Entry allocation with freelist (#8, #9)
   ============================================ */
PERL_STATIC_INLINE LRUEntry* entry_alloc(LRUCache *c, U32 klen) {
    if (c->freelist && c->freelist->alloc_klen >= klen) {
        LRUEntry *e = c->freelist;
        c->freelist = e->hash_next;
        c->freelist_count--;
        return e;
    }
    {
        LRUEntry *e = (LRUEntry*)safemalloc(LRU_ENTRY_SIZE(klen));
        e->alloc_klen = klen;
        return e;
    }
}

static void entry_recycle(pTHX_ LRUCache *c, LRUEntry *e) {
    if (e->value) {
        SvREFCNT_dec(e->value);
        e->value = NULL;
    }
    if (c->freelist_count < LRU_FREELIST_MAX) {
        e->hash_next = c->freelist;
        c->freelist = e;
        c->freelist_count++;
    } else {
        Safefree(e);
    }
}

/* ============================================
   LRU list operations with branch hints (#5)
   ============================================ */
PERL_STATIC_INLINE void lru_unlink(LRUCache *c, LRUEntry *e) {
    if (LIKELY(e->prev != NULL))
        e->prev->next = e->next;
    else
        c->head = e->next;

    if (LIKELY(e->next != NULL))
        e->next->prev = e->prev;
    else
        c->tail = e->prev;

    e->prev = e->next = NULL;
}

PERL_STATIC_INLINE void lru_push_front(LRUCache *c, LRUEntry *e) {
    e->prev = NULL;
    e->next = c->head;
    if (LIKELY(c->head != NULL))
        c->head->prev = e;
    c->head = e;
    if (UNLIKELY(c->tail == NULL))
        c->tail = e;
}

PERL_STATIC_INLINE void lru_promote(LRUCache *c, LRUEntry *e) {
    if (LIKELY(e == c->head)) return;  /* already MRU -- fast path */
    lru_unlink(c, e);
    lru_push_front(c, e);
}

/* ============================================
   Hash table operations (#2 inline key compare)
   ============================================ */

/* Find -- compares inline key bytes directly, no SvPV */
PERL_STATIC_INLINE LRUEntry* hash_find(LRUCache *c, const char *kpv,
                                        STRLEN klen, U32 hash)
{
    LRUEntry *e = c->buckets[hash & c->bucket_mask];
    while (e) {
        if (e->hash == hash
            && e->klen == (U32)klen
            && memcmp(e->key, kpv, klen) == 0)
            return e;
        e = e->hash_next;
    }
    return NULL;
}

PERL_STATIC_INLINE void hash_insert(LRUCache *c, LRUEntry *e) {
    IV idx = e->hash & c->bucket_mask;
    e->hash_next = c->buckets[idx];
    c->buckets[idx] = e;
}

/* Remove a known entry from its bucket chain */
static void hash_remove(LRUCache *c, LRUEntry *e) {
    IV idx = e->hash & c->bucket_mask;
    LRUEntry **pp = &c->buckets[idx];
    while (*pp) {
        if (*pp == e) {
            *pp = e->hash_next;
            e->hash_next = NULL;
            return;
        }
        pp = &(*pp)->hash_next;
    }
}

/* Combined find-and-remove: single chain walk (#6) */
static LRUEntry* hash_find_and_remove(LRUCache *c, const char *kpv,
                                       STRLEN klen, U32 hash)
{
    IV idx = hash & c->bucket_mask;
    LRUEntry **pp = &c->buckets[idx];
    while (*pp) {
        LRUEntry *e = *pp;
        if (e->hash == hash
            && e->klen == (U32)klen
            && memcmp(e->key, kpv, klen) == 0) {
            *pp = e->hash_next;
            e->hash_next = NULL;
            return e;
        }
        pp = &e->hash_next;
    }
    return NULL;
}

/* ============================================
   Dynamic rehash (#11)
   ============================================ */
static void lru_rehash(LRUCache *c) {
    IV new_count = c->bucket_count * 2;
    IV new_mask  = new_count - 1;
    LRUEntry **new_buckets;
    LRUEntry *e;

    Newxz(new_buckets, new_count, LRUEntry*);

    /* Walk LRU list to re-insert all entries */
    for (e = c->head; e; e = e->next) {
        IV idx = e->hash & new_mask;
        e->hash_next = new_buckets[idx];
        new_buckets[idx] = e;
    }

    Safefree(c->buckets);
    c->buckets         = new_buckets;
    c->bucket_count    = new_count;
    c->bucket_mask     = new_mask;
    c->rehash_threshold = (new_count * LRU_LOAD_NUMER) / LRU_LOAD_DENOM;
}

/* ============================================
   Power-of-2 helper
   ============================================ */
static IV next_pow2(IV n) {
    n--;
    n |= n >> 1;  n |= n >> 2;
    n |= n >> 4;  n |= n >> 8;
    n |= n >> 16;
    n++;
    return n < 16 ? 16 : n;
}

/* ============================================
   Eviction -- removes LRU tail entry
   ============================================ */
static void lru_evict(pTHX_ LRUCache *c) {
    LRUEntry *victim = c->tail;
    if (UNLIKELY(!victim)) return;
    lru_unlink(c, victim);
    hash_remove(c, victim);
    entry_recycle(aTHX_ c, victim);
    c->size--;
}

/* ============================================
   Core internal operations (#3 PERL_HASH,
   #7 SvPV_const, #10 PERL_STATIC_INLINE)
   ============================================ */

PERL_STATIC_INLINE SV* lru_get_promote(pTHX_ LRUCache *c,
                                        const char *kpv, STRLEN klen)
{
    U32 hash;
    LRUEntry *e;
    PERL_HASH(hash, kpv, klen);
    e = hash_find(c, kpv, klen, hash);
    if (LIKELY(e != NULL)) {
        lru_promote(c, e);
        return e->value;
    }
    return NULL;
}

PERL_STATIC_INLINE SV* lru_peek_internal(pTHX_ LRUCache *c,
                                          const char *kpv, STRLEN klen)
{
    U32 hash;
    LRUEntry *e;
    PERL_HASH(hash, kpv, klen);
    e = hash_find(c, kpv, klen, hash);
    if (LIKELY(e != NULL))
        return e->value;
    return NULL;
}

static void lru_set_internal(pTHX_ LRUCache *c, const char *kpv,
                              STRLEN klen, SV *value)
{
    U32 hash;
    LRUEntry *e;
    PERL_HASH(hash, kpv, klen);
    e = hash_find(c, kpv, klen, hash);

    if (e) {
        /* Update existing -- reuse SV body in-place (#13) */
        sv_setsv(e->value, value);
        lru_promote(c, e);
    } else {
        /* Evict if at capacity */
        if (c->size >= c->capacity)
            lru_evict(aTHX_ c);

        /* Rehash if load factor exceeded */
        if (UNLIKELY(c->size >= c->rehash_threshold))
            lru_rehash(c);

        /* Allocate entry with inline key (#2) -- no key SV needed */
        e = entry_alloc(c, (U32)klen);
        e->hash  = hash;
        e->klen  = (U32)klen;
        e->value = newSVsv(value);
        e->prev  = e->next = e->hash_next = NULL;
        memcpy(e->key, kpv, klen);
        e->key[klen] = '\0';

        hash_insert(c, e);
        lru_push_front(c, e);
        c->size++;
    }
}

PERL_STATIC_INLINE bool lru_exists_internal(pTHX_ LRUCache *c,
                                             const char *kpv, STRLEN klen)
{
    U32 hash;
    PERL_HASH(hash, kpv, klen);
    return hash_find(c, kpv, klen, hash) != NULL;
}

/* ============================================
   Method-style custom op implementations
   ============================================ */

static OP* pp_lru_get(pTHX) {
    dSP;
    SV *key_sv   = POPs;
    SV *cache_sv = POPs;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    SV *val = lru_get_promote(aTHX_ c, kpv, klen);
    PUSHs(val ? val : &PL_sv_undef);
    RETURN;
}

static OP* pp_lru_set(pTHX) {
    dSP;
    SV *value    = POPs;
    SV *key_sv   = POPs;
    SV *cache_sv = POPs;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    lru_set_internal(aTHX_ c, kpv, klen, value);
    RETURN;
}

static OP* pp_lru_exists(pTHX) {
    dSP;
    SV *key_sv   = POPs;
    SV *cache_sv = POPs;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    PUSHs(lru_exists_internal(aTHX_ c, kpv, klen) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* ============================================
   Function-style custom ops (fastest path)
   ============================================ */

static OP* pp_lru_func_get(pTHX) {
    dSP;
    SV *key_sv   = TOPs;
    SV *cache_sv = TOPm1s;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    SV *val = lru_get_promote(aTHX_ c, kpv, klen);
    SP--;
    SETs(val ? val : &PL_sv_undef);
    RETURN;
}

static OP* pp_lru_func_set(pTHX) {
    dSP;
    SV *value    = TOPs;
    SV *key_sv   = TOPm1s;
    SV *cache_sv = *(SP - 2);
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    lru_set_internal(aTHX_ c, kpv, klen, value);
    *(SP - 2) = value;
    SP -= 2;
    RETURN;
}

static OP* pp_lru_func_exists(pTHX) {
    dSP;
    SV *key_sv   = TOPs;
    SV *cache_sv = TOPm1s;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    SP--;
    SETs(lru_exists_internal(aTHX_ c, kpv, klen) ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

static OP* pp_lru_func_peek(pTHX) {
    dSP;
    SV *key_sv   = TOPs;
    SV *cache_sv = TOPm1s;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    SV *val = lru_peek_internal(aTHX_ c, kpv, klen);
    SP--;
    SETs(val ? val : &PL_sv_undef);
    RETURN;
}

/* Delete: combined find+remove (#6) + avoid sv_mortalcopy (#4) */
static OP* pp_lru_func_delete(pTHX) {
    dSP;
    SV *key_sv   = TOPs;
    SV *cache_sv = TOPm1s;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);
    STRLEN klen;
    const char *kpv = SvPV_const(key_sv, klen);
    U32 hash;
    LRUEntry *e;

    PERL_HASH(hash, kpv, klen);
    e = hash_find_and_remove(c, kpv, klen, hash);

    SP--;
    if (e) {
        SV *val = e->value;
        SvREFCNT_inc_simple_void_NN(val);  /* prevent recycle from freeing */
        lru_unlink(c, e);
        entry_recycle(aTHX_ c, e);
        c->size--;
        SETs(sv_2mortal(val));
    } else {
        SETs(&PL_sv_undef);
    }
    RETURN;
}

static OP* pp_lru_func_oldest(pTHX) {
    dSP;
    SV *cache_sv = TOPs;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);

    if (c->tail) {
        SETs(sv_2mortal(newSVpvn(c->tail->key, c->tail->klen)));
        XPUSHs(c->tail->value);
        RETURN;
    }
    POPs;
    RETURN;
}

static OP* pp_lru_func_newest(pTHX) {
    dSP;
    SV *cache_sv = TOPs;
    LRUCache *c  = get_lru_cache(aTHX_ cache_sv);

    if (c->head) {
        SETs(sv_2mortal(newSVpvn(c->head->key, c->head->klen)));
        XPUSHs(c->head->value);
        RETURN;
    }
    POPs;
    RETURN;
}

/* ============================================
   Call checkers (replace entersub with custom ops)
   ============================================ */

typedef OP* (*lru_ppfunc)(pTHX);

static bool lru_op_is_dollar_underscore(pTHX_ OP *op) {
    if (!op) return FALSE;
    if (op->op_type == OP_RV2SV) {
        OP *gvop = cUNOPx(op)->op_first;
        if (gvop && gvop->op_type == OP_GV) {
            GV *gv = cGVOPx_gv(gvop);
            if (gv && GvNAMELEN(gv) == 1 && GvNAME(gv)[0] == '_')
                return TRUE;
        }
    }
    return FALSE;
}

/* 2-arg call checker: lru_get, lru_exists, lru_peek, lru_delete */
static OP* lru_func_call_checker_2arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    lru_ppfunc ppfunc = (lru_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *cacheop, *keyop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;

    cacheop = OpSIBLING(pushop);
    if (!cacheop) return entersubop;

    keyop = OpSIBLING(cacheop);
    if (!keyop) return entersubop;

    cvop = OpSIBLING(keyop);
    if (!cvop) return entersubop;

    if (OpSIBLING(keyop) != cvop) return entersubop;

    if (lru_op_is_dollar_underscore(aTHX_ cacheop) ||
        lru_op_is_dollar_underscore(aTHX_ keyop))
        return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(keyop, NULL);
    OpLASTSIB_set(cacheop, NULL);

    newop = newBINOP(OP_NULL, 0, cacheop, keyop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;

    op_free(entersubop);
    return newop;
}

/* 3-arg call checker: lru_set */
static OP* lru_func_call_checker_3arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    lru_ppfunc ppfunc = (lru_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *cacheop, *keyop, *valop;
    OP *innerop, *newop;

    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;

    cacheop = OpSIBLING(pushop);
    if (!cacheop) return entersubop;

    keyop = OpSIBLING(cacheop);
    if (!keyop) return entersubop;

    valop = OpSIBLING(keyop);
    if (!valop) return entersubop;

    cvop = OpSIBLING(valop);
    if (!cvop) return entersubop;

    if (OpSIBLING(valop) != cvop) return entersubop;

    if (lru_op_is_dollar_underscore(aTHX_ cacheop) ||
        lru_op_is_dollar_underscore(aTHX_ keyop) ||
        lru_op_is_dollar_underscore(aTHX_ valop))
        return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(cacheop, NULL);
    OpLASTSIB_set(keyop, NULL);
    OpLASTSIB_set(valop, NULL);

    innerop = newBINOP(OP_NULL, 0, cacheop, keyop);

    newop = newBINOP(OP_NULL, 0, innerop, valop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;

    op_free(entersubop);
    return newop;
}

/* 1-arg call checker: lru_oldest, lru_newest */
static OP* lru_func_call_checker_1arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    lru_ppfunc ppfunc = (lru_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *cacheop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop))
        pushop = cUNOPx(pushop)->op_first;

    cacheop = OpSIBLING(pushop);
    if (!cacheop) return entersubop;

    cvop = OpSIBLING(cacheop);
    if (!cvop) return entersubop;

    if (OpSIBLING(cacheop) != cvop) return entersubop;

    if (lru_op_is_dollar_underscore(aTHX_ cacheop))
        return entersubop;

    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(cacheop, NULL);

    newop = newUNOP(OP_NULL, 0, cacheop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;

    op_free(entersubop);
    return newop;
}

/* No-op fallback checker */
static OP* lru_func_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);
    return entersubop;
}

/* ============================================
   Install helpers for function-style accessors
   ============================================ */

static void install_lru_func(pTHX_ const char *pkg, const char *name,
                              XSUBADDR_t xsub, lru_ppfunc ppfunc)
{
    char full_name[256];
    CV *cv;
    SV *ckobj;

    PERL_UNUSED_ARG(ppfunc);

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, lru_func_call_checker, ckobj);
}

static void install_lru_func_2arg(pTHX_ const char *pkg, const char *name,
                                   XSUBADDR_t xsub, lru_ppfunc ppfunc)
{
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, lru_func_call_checker_2arg, ckobj);
}

static void install_lru_func_3arg(pTHX_ const char *pkg, const char *name,
                                   XSUBADDR_t xsub, lru_ppfunc ppfunc)
{
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, lru_func_call_checker_3arg, ckobj);
}

static void install_lru_func_1arg(pTHX_ const char *pkg, const char *name,
                                   XSUBADDR_t xsub, lru_ppfunc ppfunc)
{
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, lru_func_call_checker_1arg, ckobj);
}

/* ============================================
   XS fallbacks for function-style accessors
   ============================================ */

XS_EXTERNAL(XS_LRU__Cache_func_get) {
    dXSARGS;
    if (items != 2) croak("Usage: lru_get($cache, $key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        SV *val = lru_get_promote(aTHX_ c, kpv, klen);
        if (val) { ST(0) = val; XSRETURN(1); }
    }
    XSRETURN_UNDEF;
}

XS_EXTERNAL(XS_LRU__Cache_func_set) {
    dXSARGS;
    if (items != 3) croak("Usage: lru_set($cache, $key, $value)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        lru_set_internal(aTHX_ c, kpv, klen, ST(2));
        ST(0) = ST(2);
    }
    XSRETURN(1);
}

XS_EXTERNAL(XS_LRU__Cache_func_exists) {
    dXSARGS;
    if (items != 2) croak("Usage: lru_exists($cache, $key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        if (lru_exists_internal(aTHX_ c, kpv, klen)) XSRETURN_YES;
    }
    XSRETURN_NO;
}

XS_EXTERNAL(XS_LRU__Cache_func_peek) {
    dXSARGS;
    if (items != 2) croak("Usage: lru_peek($cache, $key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        SV *val = lru_peek_internal(aTHX_ c, kpv, klen);
        if (val) { ST(0) = val; XSRETURN(1); }
    }
    XSRETURN_UNDEF;
}

/* Delete: combined find+remove (#6) + avoid sv_mortalcopy (#4) */
XS_EXTERNAL(XS_LRU__Cache_func_delete) {
    dXSARGS;
    if (items != 2) croak("Usage: lru_delete($cache, $key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        U32 hash;
        LRUEntry *e;

        PERL_HASH(hash, kpv, klen);
        e = hash_find_and_remove(c, kpv, klen, hash);
        if (e) {
            SV *val = e->value;
            SvREFCNT_inc_simple_void_NN(val);
            lru_unlink(c, e);
            entry_recycle(aTHX_ c, e);
            c->size--;
            ST(0) = sv_2mortal(val);
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

XS_EXTERNAL(XS_LRU__Cache_func_oldest) {
    dXSARGS;
    if (items != 1) croak("Usage: lru_oldest($cache)");
    SP -= items;
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        if (c->tail) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVpvn(c->tail->key, c->tail->klen)));
            PUSHs(c->tail->value);
            XSRETURN(2);
        }
    }
    XSRETURN_EMPTY;
}

XS_EXTERNAL(XS_LRU__Cache_func_newest) {
    dXSARGS;
    if (items != 1) croak("Usage: lru_newest($cache)");
    SP -= items;
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        if (c->head) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVpvn(c->head->key, c->head->klen)));
            PUSHs(c->head->value);
            XSRETURN(2);
        }
    }
    XSRETURN_EMPTY;
}

/* ============================================
   Import handler
   ============================================ */
XS_EXTERNAL(XS_LRU__Cache_import) {
    dXSARGS;
    const char *pkg;
    int i;
    bool want_import = FALSE;

    pkg = CopSTASHPV(PL_curcop);

    for (i = 1; i < items; i++) {
        STRLEN len;
        const char *arg = SvPV_const(ST(i), len);
        if (len == 6 && strEQ(arg, "import")) {
            want_import = TRUE;
        }
    }

    if (want_import) {
        install_lru_func_2arg(aTHX_ pkg, "lru_get", XS_LRU__Cache_func_get, pp_lru_func_get);
        install_lru_func_2arg(aTHX_ pkg, "lru_exists", XS_LRU__Cache_func_exists, pp_lru_func_exists);
        install_lru_func_2arg(aTHX_ pkg, "lru_peek", XS_LRU__Cache_func_peek, pp_lru_func_peek);
        install_lru_func_2arg(aTHX_ pkg, "lru_delete", XS_LRU__Cache_func_delete, pp_lru_func_delete);
        install_lru_func_3arg(aTHX_ pkg, "lru_set", XS_LRU__Cache_func_set, pp_lru_func_set);
        install_lru_func_1arg(aTHX_ pkg, "lru_oldest", XS_LRU__Cache_func_oldest, pp_lru_func_oldest);
        install_lru_func_1arg(aTHX_ pkg, "lru_newest", XS_LRU__Cache_func_newest, pp_lru_func_newest);
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Destructor -- frees active entries + freelist
   ============================================ */
static int lru_cache_free(pTHX_ SV *sv, MAGIC *mg) {
    LRUCache *c = (LRUCache*)mg->mg_ptr;
    LRUEntry *e, *next;

    PERL_UNUSED_ARG(sv);

    /* Free active entries (walk LRU list) */
    for (e = c->head; e; e = next) {
        next = e->next;
        if (e->value) SvREFCNT_dec(e->value);
        Safefree(e);
    }

    /* Free pooled freelist entries */
    for (e = c->freelist; e; e = next) {
        next = e->hash_next;
        Safefree(e);
    }

    Safefree(c->buckets);
    Safefree(c);
    return 0;
}

/* ============================================
   Constructor
   ============================================ */
XS_EXTERNAL(XS_LRU__Cache_new) {
    dXSARGS;
    LRUCache *c;
    SV *obj_sv, *rv;
    IV capacity;
    HV *stash;

    if (items < 1 || items > 2)
        croak("Usage: LRU::Cache::new(capacity)");

    capacity = SvIV(items == 2 ? ST(1) : ST(0));
    if (capacity < 1) croak("Capacity must be positive");

    Newxz(c, 1, LRUCache);
    c->capacity         = capacity;
    c->size             = 0;
    c->bucket_count     = next_pow2(capacity);  /* Start at capacity, grow via rehash (#11) */
    c->bucket_mask      = c->bucket_count - 1;
    c->rehash_threshold = (c->bucket_count * LRU_LOAD_NUMER) / LRU_LOAD_DENOM;
    c->freelist         = NULL;
    c->freelist_count   = 0;
    Newxz(c->buckets, c->bucket_count, LRUEntry*);
    c->head = c->tail = NULL;

    obj_sv = newSV(0);
    sv_magicext(obj_sv, NULL, PERL_MAGIC_ext, &lru_cache_vtbl, (char*)c, 0);

    rv = newRV_noinc(obj_sv);
    stash = gv_stashpvn("LRU::Cache", 10, GV_ADD);
    sv_bless(rv, stash);

    ST(0) = rv;
    XSRETURN(1);
}

/* ============================================
   Method-style XS functions
   ============================================ */

XS_EXTERNAL(XS_LRU__Cache_set) {
    dXSARGS;
    if (items != 3) croak("Usage: $cache->set($key, $value)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        lru_set_internal(aTHX_ c, kpv, klen, ST(2));
    }
    XSRETURN_EMPTY;
}

XS_EXTERNAL(XS_LRU__Cache_get) {
    dXSARGS;
    if (items != 2) croak("Usage: $cache->get($key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        SV *val = lru_get_promote(aTHX_ c, kpv, klen);
        if (val) {
            ST(0) = val;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

XS_EXTERNAL(XS_LRU__Cache_peek) {
    dXSARGS;
    if (items != 2) croak("Usage: $cache->peek($key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        SV *val = lru_peek_internal(aTHX_ c, kpv, klen);
        if (val) {
            ST(0) = val;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

XS_EXTERNAL(XS_LRU__Cache_exists) {
    dXSARGS;
    if (items != 2) croak("Usage: $cache->exists($key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        if (lru_exists_internal(aTHX_ c, kpv, klen))
            XSRETURN_YES;
    }
    XSRETURN_NO;
}

/* Delete: combined find+remove (#6) + avoid sv_mortalcopy (#4) */
XS_EXTERNAL(XS_LRU__Cache_delete) {
    dXSARGS;
    if (items != 2) croak("Usage: $cache->delete($key)");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        STRLEN klen;
        const char *kpv = SvPV_const(ST(1), klen);
        U32 hash;
        LRUEntry *e;

        PERL_HASH(hash, kpv, klen);
        e = hash_find_and_remove(c, kpv, klen, hash);
        if (e) {
            SV *val = e->value;
            SvREFCNT_inc_simple_void_NN(val);
            lru_unlink(c, e);
            entry_recycle(aTHX_ c, e);
            c->size--;
            ST(0) = sv_2mortal(val);
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

XS_EXTERNAL(XS_LRU__Cache_size) {
    dXSARGS;
    if (items != 1) croak("Usage: $cache->size");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        XSRETURN_IV(c->size);
    }
}

XS_EXTERNAL(XS_LRU__Cache_capacity) {
    dXSARGS;
    if (items != 1) croak("Usage: $cache->capacity");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        XSRETURN_IV(c->capacity);
    }
}

/* Clear: recycles entries to freelist (#8) */
XS_EXTERNAL(XS_LRU__Cache_clear) {
    dXSARGS;
    if (items != 1) croak("Usage: $cache->clear");
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        LRUEntry *e = c->head;

        while (e) {
            LRUEntry *next = e->next;
            entry_recycle(aTHX_ c, e);
            e = next;
        }

        Zero(c->buckets, c->bucket_count, LRUEntry*);
        c->head = c->tail = NULL;
        c->size = 0;
    }
    XSRETURN_EMPTY;
}

/* Keys: creates mortal SVs from inline key bytes */
XS_EXTERNAL(XS_LRU__Cache_keys) {
    dXSARGS;
    if (items != 1) croak("Usage: $cache->keys");
    SP -= items;
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        LRUEntry *e;
        EXTEND(SP, c->size);
        for (e = c->head; e; e = e->next)
            PUSHs(sv_2mortal(newSVpvn(e->key, e->klen)));
        XSRETURN(c->size);
    }
}

XS_EXTERNAL(XS_LRU__Cache_oldest) {
    dXSARGS;
    if (items != 1) croak("Usage: $cache->oldest");
    SP -= items;
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        if (c->tail) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVpvn(c->tail->key, c->tail->klen)));
            PUSHs(c->tail->value);
            XSRETURN(2);
        }
    }
    XSRETURN_EMPTY;
}

XS_EXTERNAL(XS_LRU__Cache_newest) {
    dXSARGS;
    if (items != 1) croak("Usage: $cache->newest");
    SP -= items;
    {
        LRUCache *c = get_lru_cache(aTHX_ ST(0));
        if (c->head) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVpvn(c->head->key, c->head->klen)));
            PUSHs(c->head->value);
            XSRETURN(2);
        }
    }
    XSRETURN_EMPTY;
}

/* ============================================
   Boot function
   ============================================ */
XS_EXTERNAL(boot_LRU__Cache) {
    dXSBOOTARGSXSAPIVERCHK;

    /* Register method-style custom ops */
    XopENTRY_set(&lru_get_xop, xop_name, "lru_get");
    XopENTRY_set(&lru_get_xop, xop_desc, "lru cache get");
    Perl_custom_op_register(aTHX_ pp_lru_get, &lru_get_xop);

    XopENTRY_set(&lru_set_xop, xop_name, "lru_set");
    XopENTRY_set(&lru_set_xop, xop_desc, "lru cache set");
    Perl_custom_op_register(aTHX_ pp_lru_set, &lru_set_xop);

    XopENTRY_set(&lru_exists_xop, xop_name, "lru_exists");
    XopENTRY_set(&lru_exists_xop, xop_desc, "lru cache exists");
    Perl_custom_op_register(aTHX_ pp_lru_exists, &lru_exists_xop);

    /* Register function-style custom ops */
    XopENTRY_set(&lru_func_get_xop, xop_name, "lru_func_get");
    XopENTRY_set(&lru_func_get_xop, xop_desc, "lru function get");
    Perl_custom_op_register(aTHX_ pp_lru_func_get, &lru_func_get_xop);

    XopENTRY_set(&lru_func_set_xop, xop_name, "lru_func_set");
    XopENTRY_set(&lru_func_set_xop, xop_desc, "lru function set");
    Perl_custom_op_register(aTHX_ pp_lru_func_set, &lru_func_set_xop);

    XopENTRY_set(&lru_func_exists_xop, xop_name, "lru_func_exists");
    XopENTRY_set(&lru_func_exists_xop, xop_desc, "lru function exists");
    Perl_custom_op_register(aTHX_ pp_lru_func_exists, &lru_func_exists_xop);

    XopENTRY_set(&lru_func_peek_xop, xop_name, "lru_func_peek");
    XopENTRY_set(&lru_func_peek_xop, xop_desc, "lru function peek");
    Perl_custom_op_register(aTHX_ pp_lru_func_peek, &lru_func_peek_xop);

    XopENTRY_set(&lru_func_delete_xop, xop_name, "lru_func_delete");
    XopENTRY_set(&lru_func_delete_xop, xop_desc, "lru function delete");
    Perl_custom_op_register(aTHX_ pp_lru_func_delete, &lru_func_delete_xop);

    XopENTRY_set(&lru_func_oldest_xop, xop_name, "lru_func_oldest");
    XopENTRY_set(&lru_func_oldest_xop, xop_desc, "lru function oldest");
    Perl_custom_op_register(aTHX_ pp_lru_func_oldest, &lru_func_oldest_xop);

    XopENTRY_set(&lru_func_newest_xop, xop_name, "lru_func_newest");
    XopENTRY_set(&lru_func_newest_xop, xop_desc, "lru function newest");
    Perl_custom_op_register(aTHX_ pp_lru_func_newest, &lru_func_newest_xop);

    /* Register XS subs */
    newXS("LRU::Cache::new", XS_LRU__Cache_new, __FILE__);
    newXS("LRU::Cache::set", XS_LRU__Cache_set, __FILE__);
    newXS("LRU::Cache::get", XS_LRU__Cache_get, __FILE__);
    newXS("LRU::Cache::peek", XS_LRU__Cache_peek, __FILE__);
    newXS("LRU::Cache::exists", XS_LRU__Cache_exists, __FILE__);
    newXS("LRU::Cache::delete", XS_LRU__Cache_delete, __FILE__);
    newXS("LRU::Cache::size", XS_LRU__Cache_size, __FILE__);
    newXS("LRU::Cache::capacity", XS_LRU__Cache_capacity, __FILE__);
    newXS("LRU::Cache::clear", XS_LRU__Cache_clear, __FILE__);
    newXS("LRU::Cache::keys", XS_LRU__Cache_keys, __FILE__);
    newXS("LRU::Cache::oldest", XS_LRU__Cache_oldest, __FILE__);
    newXS("LRU::Cache::newest", XS_LRU__Cache_newest, __FILE__);
    newXS("LRU::Cache::import", XS_LRU__Cache_import, __FILE__);

#if PERL_VERSION_GE(5,22,0)
    Perl_xs_boot_epilog(aTHX_ ax);
#else
    XSRETURN_YES;
#endif
}
