#ifndef FRX_ARENA_H
#define FRX_ARENA_H

/* The allocator, and the string it hands out.
 *
 * A page-chained bump allocator: 64 KiB pages chained through the head,
 * allocations over a quarter of a page on a page of their own, sixteen-byte
 * alignment, and never a realloc - so a pointer handed out is stable for
 * the life of the document, which is what the ABI's frx_node * promises.
 * This is Markdown::Simple's arena with the profiling counters dropped;
 * `pages` remains only because the selftest counts them. Page-chained
 * rather than Template::Stencil's offset-based arena, which survives a
 * realloc by paying a base-plus-offset on every access: a tree the consumer
 * walks by pointer wants the pointers.
 *
 * NULL on failure, never abort; the caller turns it into FRX_E_NOMEM with
 * the offset it was at. malloc and free by rule 3; frx_compat.h has already
 * removed PerlMem's macros so these are libc's.
 *
 * An frx_str is a pointer into the arena and a length. Always
 * NUL-terminated, so a C consumer compares with memcmp and prints with %s
 * and never copies.
 *
 * Needs nothing. */

#define FRX_ARENA_PAGE  (64u * 1024u)
#define FRX_ARENA_BIG   (FRX_ARENA_PAGE / 4u)
#define FRX_ARENA_ALIGN 16u

typedef struct frx_str {
    const char *p;
    size_t      len;
} frx_str;

typedef struct frx_arena_page {
    struct frx_arena_page *next;
    size_t                 used;
    size_t                 cap;
    unsigned char          data[1];     /* the page follows inline */
} frx_arena_page;

typedef struct frx_arena {
    frx_arena_page *head;               /* the page being filled */
    frx_arena_page *big;                /* oversize pages, one allocation each */
    size_t          pages;              /* both lists; for the selftest */
} frx_arena;

static frx_arena_page *
frx_arena_page_new(size_t cap)
{
    frx_arena_page *p = (frx_arena_page *)malloc(sizeof(frx_arena_page) + cap);
    if (!p) return NULL;
    p->next = NULL;
    p->used = 0;
    p->cap  = cap;
    return p;
}

/* the padding that brings data + used onto the alignment */
static size_t
frx_arena_pad(const frx_arena_page *p)
{
    size_t base = (size_t)(const void *)p->data;
    return (FRX_ARENA_ALIGN - (base & (FRX_ARENA_ALIGN - 1))) & (FRX_ARENA_ALIGN - 1);
}

static void
frx_arena_init(frx_arena *a)
{
    a->head  = NULL;
    a->big   = NULL;
    a->pages = 0;
}

static void *
frx_arena_alloc(frx_arena *a, size_t n)
{
    size_t aligned = (n + (FRX_ARENA_ALIGN - 1)) & ~(size_t)(FRX_ARENA_ALIGN - 1);
    void *out;

    if (aligned < n) return NULL;                    /* size_t wrapped */

    if (aligned > FRX_ARENA_BIG) {
        frx_arena_page *p = frx_arena_page_new(aligned + FRX_ARENA_ALIGN);
        size_t pad;
        if (!p) return NULL;
        pad     = frx_arena_pad(p);
        p->used = pad + aligned;
        p->next = a->big;
        a->big  = p;
        a->pages++;
        return p->data + pad;
    }

    if (!a->head || a->head->used + aligned > a->head->cap) {
        frx_arena_page *p = frx_arena_page_new(FRX_ARENA_PAGE);
        if (!p) return NULL;
        p->used = frx_arena_pad(p);                  /* the first pointer is aligned */
        p->next = a->head;
        a->head = p;
        a->pages++;
    }
    out = a->head->data + a->head->used;
    a->head->used += aligned;
    return out;
}

/* n bytes of s into the arena with a NUL after them; p NULL on failure */
static frx_str
frx_arena_strndup(frx_arena *a, const char *s, size_t n)
{
    frx_str out;
    char *p = (char *)frx_arena_alloc(a, n + 1);
    if (p) {
        if (n) memcpy(p, s, n);
        p[n] = '\0';
    }
    out.p   = p;
    out.len = p ? n : 0;
    return out;
}

/* A mark is a position in the arena: everything allocated after it can be
 * released together, which is what a streaming reader does at the end of
 * each record so a million of them cost the memory of one. Pages are
 * pushed at the front of each list, so the pages allocated since the
 * mark are the ones before the marked page. */
typedef struct frx_arena_mark {
    frx_arena_page *head;
    size_t          used;
    frx_arena_page *big;
    size_t          pages;
} frx_arena_mark;

static void
frx_arena_mark_get(const frx_arena *a, frx_arena_mark *m)
{
    m->head  = a->head;
    m->used  = a->head ? a->head->used : 0;
    m->big   = a->big;
    m->pages = a->pages;
}

static void
frx_arena_release(frx_arena *a, const frx_arena_mark *m)
{
    while (a->head && a->head != m->head) { frx_arena_page *n = a->head->next; free(a->head); a->head = n; }
    if (a->head) a->head->used = m->used;
    while (a->big && a->big != m->big)    { frx_arena_page *n = a->big->next;  free(a->big);  a->big  = n; }
    a->pages = m->pages;
}

static void
frx_arena_free(frx_arena *a)
{
    frx_arena_page *p = a->head;
    while (p) { frx_arena_page *n = p->next; free(p); p = n; }
    p = a->big;
    while (p) { frx_arena_page *n = p->next; free(p); p = n; }
    a->head  = NULL;
    a->big   = NULL;
    a->pages = 0;
}

#endif /* FRX_ARENA_H */
