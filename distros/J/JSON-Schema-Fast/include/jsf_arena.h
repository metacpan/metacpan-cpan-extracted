#ifndef JSF_ARENA_H
#define JSF_ARENA_H

/* Bump arena: one growable block holds the whole IR (nodes, interned string
 * pool, prop tables, ref table). Children are referenced by uint32_t OFFSET,
 * never a pointer, so the block can realloc during build with no fixups
 * (principle 9). Freed in one shot on DESTROY.
 *
 * All functions are C89-clean (declarations at block start) so the module
 * builds under perl's conservative C dialect on every smoker. */

/* Alignment a type actually requires, asked of the compiler rather than
 * guessed. Every jsf_arena_alloc passes JSF_ALIGNOF(T) for the T it is about
 * to store: a hardcoded 8 was correct only while NV was a double. Build perl
 * -Duselongdouble or -Dusequadmath and NV becomes a 16-byte-aligned type, so
 * jsf_node_t needs 16; at 8 every node landed on an odd 8-byte boundary and
 * the SSE load gcc emits for __float128 faulted, segfaulting the first
 * compile() on x86-64. Deriving it from the type keeps that true for any
 * member anyone adds later. */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#  define JSF_ALIGNOF(T) ((uint32_t)_Alignof(T))
#elif defined(__GNUC__)
#  define JSF_ALIGNOF(T) ((uint32_t)__alignof__(T))
#elif defined(_MSC_VER)
#  define JSF_ALIGNOF(T) ((uint32_t)__alignof(T))
#else
#  define JSF_ALIGNOF(T) ((uint32_t)offsetof(struct { char c_; T t_; }, t_))
#endif

typedef struct jsf_arena {
    char     *base;        /* the block */
    uint32_t  used;        /* bytes in use (offset 0 reserved as null) */
    uint32_t  cap;         /* allocated capacity */
    uint32_t *itab;        /* intern index: offsets of interned strings */
    uint32_t  in;          /* interned count */
    uint32_t  icap;        /* intern index capacity */
} jsf_arena_t;

/* An interned string: length prefix, then `len` bytes, then a NUL. */
typedef struct jsf_str { uint32_t len; } jsf_str_t;

static jsf_arena_t *jsf_arena_new(uint32_t cap) {
    jsf_arena_t *a;
    a = (jsf_arena_t *)malloc(sizeof *a);
    if (!a) return NULL;
    if (cap < 64) cap = 64;
    a->base = (char *)malloc(cap);
    if (!a->base) { free(a); return NULL; }
    a->cap  = cap;
    a->used = 1;            /* reserve offset 0 as the null sentinel */
    a->base[0] = 0;
    a->itab = NULL;
    a->in   = 0;
    a->icap = 0;
    return a;
}

static void jsf_arena_free(jsf_arena_t *a) {
    if (!a) return;
    free(a->itab);
    free(a->base);
    free(a);
}

static int jsf__arena_grow(jsf_arena_t *a, uint32_t need) {
    uint32_t cap;
    char    *nb;
    cap = a->cap;
    while (cap < need) {
        if (cap > 0x80000000u) return 0;   /* would overflow uint32 */
        cap <<= 1;
    }
    if (cap != a->cap) {
        nb = (char *)realloc(a->base, cap);
        if (!nb) return 0;
        a->base = nb;
        a->cap  = cap;
    }
    return 1;
}

/* Allocate `size` bytes at `align`; returns an offset, or JSF_NULL_OFF on OOM/
 * overflow. The region (and any alignment padding) is zeroed. */
static uint32_t jsf_arena_alloc(jsf_arena_t *a, uint32_t size, uint32_t align) {
    uint32_t off, end;
    off = a->used;
    if (align > 1) off = (off + (align - 1)) & ~(align - 1);
    end = off + size;
    if (end < off) return JSF_NULL_OFF;                 /* size overflow */
    if (end > a->cap && !jsf__arena_grow(a, end)) return JSF_NULL_OFF;
    memset(a->base + a->used, 0, (size_t)(end - a->used));
    a->used = end;
    return off;
}

/* Resolve an offset to a live pointer. Never cache the result across a call
 * that might grow the arena - recompute from the offset instead. */
static char *jsf_arena_ptr(jsf_arena_t *a, uint32_t off) {
    return a->base + off;
}

/* Intern a string; identical (len+bytes) strings dedup to one offset. Returns
 * the offset of the jsf_str_t header. */
static uint32_t jsf_arena_intern(jsf_arena_t *a, const char *s, uint32_t len) {
    uint32_t   i, off;
    jsf_str_t *st;
    for (i = 0; i < a->in; i++) {
        uint32_t o = a->itab[i];
        st = (jsf_str_t *)(a->base + o);
        if (st->len == len &&
            memcmp(a->base + o + sizeof(jsf_str_t), s, len) == 0)
            return o;
    }
    off = jsf_arena_alloc(a, (uint32_t)(sizeof(jsf_str_t) + len + 1),
                          JSF_ALIGNOF(jsf_str_t));
    if (off == JSF_NULL_OFF) return JSF_NULL_OFF;
    st = (jsf_str_t *)(a->base + off);
    st->len = len;
    memcpy(a->base + off + sizeof(jsf_str_t), s, len);
    a->base[off + sizeof(jsf_str_t) + len] = 0;
    if (a->in == a->icap) {
        uint32_t  nc = a->icap ? a->icap * 2 : 16;
        uint32_t *ni = (uint32_t *)realloc(a->itab, nc * sizeof(uint32_t));
        if (!ni) return off;                 /* dedup degrades; still usable */
        a->itab = ni;
        a->icap = nc;
    }
    a->itab[a->in++] = off;
    return off;
}

/* Bytes + length of an interned string. */
static const char *jsf_str_bytes(jsf_arena_t *a, uint32_t off, uint32_t *len) {
    jsf_str_t *st = (jsf_str_t *)(a->base + off);
    if (len) *len = st->len;
    return a->base + off + sizeof(jsf_str_t);
}

#endif /* JSF_ARENA_H */
