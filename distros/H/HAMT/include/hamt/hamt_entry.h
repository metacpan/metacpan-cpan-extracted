#ifndef HAMT_ENTRY_H
#define HAMT_ENTRY_H

/* One key and its value, in one allocation, shared by every node of every
 * version that holds it.
 *
 * An entry never changes after it is made. Giving a key a new value makes a
 * new entry and copies the key's bytes: a key is short, and in exchange a
 * node carries one pointer for each entry and retains one thing when it is
 * copied. */

typedef struct hamt_entry {
    uint32_t refcnt;
    uint8_t  utf8;      /* the key is UTF-8 that could not be downgraded */
    uint64_t hash;
    void    *val;       /* NULL in a set */
    size_t   klen;
    char     key[1];    /* klen bytes, then a NUL */
} hamt_entry;

#define HAMT_ENTRY_BYTES(klen) (offsetof(hamt_entry, key) + (size_t)(klen) + 1)

/* One reference, owned by the caller. The value is retained; the caller
 * keeps whatever reference it came in with. NULL when there is no memory, in
 * which case the value was not retained. */
static hamt_entry *hamt_entry_new(void *cx, const char *key, size_t klen,
                                  int utf8, uint64_t hash, void *val) {
    hamt_entry *e;

    if (klen > (size_t)-1 - offsetof(hamt_entry, key) - 1) return NULL;
    e = (hamt_entry *)HAMT_ALLOC(cx, HAMT_ENTRY_BYTES(klen));
    if (!e) return NULL;

    e->refcnt = 1;
    e->utf8   = utf8 ? 1 : 0;
    e->hash   = hash;
    e->val    = val;
    e->klen   = klen;
    if (klen) memcpy(e->key, key, klen);
    e->key[klen] = '\0';

    if (val) HAMT_VAL_RETAIN(cx, val);
    (void)cx;
    return e;
}

/* Reaching the limit takes four billion live nodes pointing at one entry.
 * It stops rather than wrapping to a count that frees the entry under them. */
static hamt_entry *hamt_entry_retain(hamt_entry *e) {
    if (e->refcnt == 0xffffffffU) HAMT_FATAL("an entry's reference count would wrap");
    e->refcnt++;
    return e;
}

/* The order matters. Releasing the value can run code that comes back into
 * this library, and by then the entry must be gone: so the value's pointer
 * is taken out, the entry is freed, and the value is released last. */
static void hamt_entry_release(void *cx, hamt_entry *e) {
    void *val;

    if (--e->refcnt) return;
    val = e->val;
    HAMT_FREE(cx, e, HAMT_ENTRY_BYTES(e->klen));
    if (val) HAMT_VAL_RELEASE(cx, val);
    (void)cx;
}

/* Cheapest test first: almost every miss is settled by the hash. */
static int hamt_entry_key_eq(const hamt_entry *e, const char *key, size_t klen,
                             int utf8, uint64_t hash) {
    return e->hash == hash
        && e->klen == klen
        && e->utf8 == (utf8 ? 1 : 0)
        && (klen == 0 || memcmp(e->key, key, klen) == 0);
}

#endif
