#ifndef HAMT_NODE_H
#define HAMT_NODE_H

/* One node of the map's trie, and the handful of ways a node is copied with
 * one thing different.
 *
 * A node is 32 positions wide, and each position is empty, or holds an
 * entry, or holds a child. Two bitmaps say which: `datamap` has a bit for
 * each position holding an entry and `nodemap` a bit for each holding a
 * child, and no bit is in both. Only what is there is stored:
 *
 *     slot[]:  [ entries, lowest position first | children, HIGHEST first ]
 *
 * So with nd entries and N slots in all, the entry at position p is at
 *
 *     slot[ popcount(datamap & (bit(p) - 1)) ]
 *
 * and the child at position p is at
 *
 *     slot[ N - 1 - popcount(nodemap & (bit(p) - 1)) ]
 *
 * Children fill from the end so that turning an entry into a child, or a
 * child back into an entry, moves the fewest slots.
 *
 * The position at each level is five bits of the key's hash: bits 0-4 at the
 * root, 5-9 below it, and so on for twelve levels and sixty bits. A node
 * thirteen deep has no hash left to index by, and is a COLLISION node: both
 * maps zero, `ncoll` entries in a plain array, searched one by one.
 *
 * A node is never changed once more than one thing points at it. Every
 * function here that "changes" a node allocates a new one; the functions
 * that change one where it stands are in hamt_mut.h, and they first make
 * sure nobody else is looking. */

#define HAMT_BITS      5
#define HAMT_MAX_DEPTH 12   /* depths 0..11 index by hash; depth 12 collides */

#define HAMT_IDX(hash, depth) \
    ((unsigned)(((uint64_t)(hash) >> (HAMT_BITS * (depth))) & 31))
#define HAMT_BIT(hash, depth) ((uint32_t)1 << HAMT_IDX((hash), (depth)))

typedef struct hamt_node {
    uint32_t refcnt;
    uint32_t datamap;
    uint32_t nodemap;
    uint32_t ncoll;     /* > 0: a collision node, both maps zero */
    void    *slot[1];
} hamt_node;

/* How many slots a node holding n things has room for: n rounded up to the
 * next multiple of four. A node that is being built up in place gains a
 * slot at a time, and with no room to spare every one of those would be a
 * new allocation, a copy and a free; with this, three in four are a few
 * pointers moved along. The room is a function of n and is stored nowhere,
 * which is what keeps one rule true everywhere: A NODE HOLDING n THINGS IS
 * ALLOCATED AT HAMT_NODE_BYTES(n). So whoever changes n in place has to
 * check first that the new n has the same room, and reallocate if not. */
#define HAMT_NODE_ROOM(n)  (((uint32_t)(n) + 3u) & ~3u)
#define HAMT_NODE_BYTES(n) \
    (offsetof(hamt_node, slot) + (size_t)((n) ? HAMT_NODE_ROOM(n) : 4) * sizeof(void *))

#define HAMT_NO_SKIP 0xffffffffU

/* Entries in the node: the first this-many slots. */
static uint32_t hamt_node_ndata(const hamt_node *n) {
    return n->ncoll ? n->ncoll : hamt_popcnt32(n->datamap);
}

static uint32_t hamt_node_nslots(const hamt_node *n) {
    return n->ncoll ? n->ncoll
                    : hamt_popcnt32(n->datamap) + hamt_popcnt32(n->nodemap);
}

/* One entry and nothing else. Legal as a root. Anywhere else it is a node
 * on its way to being folded into its parent, and never left standing. */
static int hamt_node_is_single(const hamt_node *n) {
    if (n->ncoll) return n->ncoll == 1;
    return n->nodemap == 0 && n->datamap != 0
        && (n->datamap & (n->datamap - 1)) == 0;
}

static hamt_node *hamt_node_new(void *cx, uint32_t nslots) {
    hamt_node *n = (hamt_node *)HAMT_ALLOC(cx, HAMT_NODE_BYTES(nslots));
    if (!n) return NULL;
    n->refcnt  = 1;
    n->datamap = 0;
    n->nodemap = 0;
    n->ncoll   = 0;
    (void)cx;
    return n;
}

static hamt_node *hamt_node_retain(hamt_node *n) {
    if (n->refcnt == 0xffffffffU) HAMT_FATAL("a node's reference count would wrap");
    n->refcnt++;
    return n;
}

/* A node that has just been filled with borrowed pointers takes its own
 * reference to each. `skip` is the one slot whose reference the caller is
 * handing over rather than sharing, or HAMT_NO_SKIP. */
static void hamt_node_adopt(hamt_node *n, uint32_t skip) {
    uint32_t nd = hamt_node_ndata(n), N = hamt_node_nslots(n), i;
    for (i = 0; i < nd; i++)
        if (i != skip) hamt_entry_retain((hamt_entry *)n->slot[i]);
    for (; i < N; i++)
        if (i != skip) hamt_node_retain((hamt_node *)n->slot[i]);
}

/* At zero the node is freed BEFORE anything it held is released, the same
 * rule as an entry and for the same reason: a value's release can run code
 * that comes back in here. The slots are copied out to make that possible.
 *
 * A collision node can be wider than any buffer worth putting on the stack,
 * so a wide one releases in place and is freed after. That is safe too - a
 * node whose count has reached zero is reachable from nowhere, so nothing
 * that runs can find it - it is only not the same order. */
static void hamt_node_release(void *cx, hamt_node *n) {
    uint32_t nd, N, i;

    if (--n->refcnt) return;
    nd = hamt_node_ndata(n);
    N  = hamt_node_nslots(n);

    if (N <= 32) {
        void *s[32];
        memcpy(s, n->slot, (size_t)N * sizeof(void *));
        HAMT_FREE(cx, n, HAMT_NODE_BYTES(N));
        for (i = 0; i < nd; i++) hamt_entry_release(cx, (hamt_entry *)s[i]);
        for (; i < N; i++)       hamt_node_release(cx, (hamt_node *)s[i]);
    }
    else {
        for (i = 0; i < N; i++) hamt_entry_release(cx, (hamt_entry *)n->slot[i]);
        HAMT_FREE(cx, n, HAMT_NODE_BYTES(N));
    }
}

/* ---- copies with one thing different ----------------------------------
 *
 * Each returns a new node holding one reference to everything in it, or
 * NULL when there is no memory, in which case nothing was retained. The
 * node copied from is untouched. */

/* The same node with slot i pointing somewhere else. `skip` as for adopt:
 * pass i to hand over the caller's reference to p, HAMT_NO_SKIP to share. */
static hamt_node *hamt_node_with_slot(void *cx, const hamt_node *n, uint32_t i,
                                      void *p, uint32_t skip) {
    uint32_t N = hamt_node_nslots(n);
    hamt_node *r = hamt_node_new(cx, N);
    if (!r) return NULL;
    r->datamap = n->datamap;
    r->nodemap = n->nodemap;
    r->ncoll   = n->ncoll;
    memcpy(r->slot, n->slot, (size_t)N * sizeof(void *));
    r->slot[i] = p;
    hamt_node_adopt(r, skip);
    return r;
}

/* An entry at a position that held nothing. */
static hamt_node *hamt_node_add_entry(void *cx, const hamt_node *n,
                                      uint32_t bit, hamt_entry *e) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    hamt_node *r = hamt_node_new(cx, N + 1);
    if (!r) return NULL;
    r->datamap = n->datamap | bit;
    r->nodemap = n->nodemap;
    memcpy(r->slot, n->slot, (size_t)di * sizeof(void *));
    r->slot[di] = e;
    memcpy(r->slot + di + 1, n->slot + di, (size_t)(N - di) * sizeof(void *));
    hamt_node_adopt(r, HAMT_NO_SKIP);
    return r;
}

/* The entry at a position gone, and nothing in its place. */
static hamt_node *hamt_node_drop_entry(void *cx, const hamt_node *n, uint32_t bit) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    hamt_node *r = hamt_node_new(cx, N - 1);
    if (!r) return NULL;
    r->datamap = n->datamap & ~bit;
    r->nodemap = n->nodemap;
    memcpy(r->slot, n->slot, (size_t)di * sizeof(void *));
    memcpy(r->slot + di, n->slot + di + 1, (size_t)(N - 1 - di) * sizeof(void *));
    hamt_node_adopt(r, HAMT_NO_SKIP);
    return r;
}

/* The entry at a position replaced by a child: a second key arrived there.
 * The caller's reference to the child is handed over.
 *
 * The entry leaves the front and the child joins the back, so every slot
 * between the two moves down by one and nothing outside them moves:
 *
 *     old:  e0 .. [E] .. e(nd-1) | c(high) ..     .. c(low)
 *     new:  e0 ..     .. e(nd-1) | c(high) .. [C] .. c(low)
 */
static hamt_node *hamt_node_entry_to_child(void *cx, const hamt_node *n,
                                           uint32_t bit, hamt_node *child) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    uint32_t r  = hamt_popcnt32(n->nodemap & (bit - 1));
    uint32_t ci = N - 1 - r;
    hamt_node *x = hamt_node_new(cx, N);
    if (!x) return NULL;
    x->datamap = n->datamap & ~bit;
    x->nodemap = n->nodemap | bit;
    memcpy(x->slot, n->slot, (size_t)di * sizeof(void *));
    memcpy(x->slot + di, n->slot + di + 1, (size_t)(ci - di) * sizeof(void *));
    x->slot[ci] = child;
    memcpy(x->slot + ci + 1, n->slot + ci + 1, (size_t)r * sizeof(void *));
    hamt_node_adopt(x, ci);
    return x;
}

/* The reverse: a child that is down to one entry is folded away and the
 * entry takes its position. The entry is shared, not handed over.
 *
 *     old:  e0 ..     .. e(nd-1) | c(high) .. [C] .. c(low)
 *     new:  e0 .. [E] .. e(nd-1) | c(high) ..     .. c(low)
 */
static hamt_node *hamt_node_child_to_entry(void *cx, const hamt_node *n,
                                           uint32_t bit, hamt_entry *e) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    uint32_t r  = hamt_popcnt32(n->nodemap & (bit - 1));
    uint32_t ci = N - 1 - r;
    hamt_node *x = hamt_node_new(cx, N);
    if (!x) return NULL;
    x->datamap = n->datamap | bit;
    x->nodemap = n->nodemap & ~bit;
    memcpy(x->slot, n->slot, (size_t)di * sizeof(void *));
    x->slot[di] = e;
    memcpy(x->slot + di + 1, n->slot + di, (size_t)(ci - di) * sizeof(void *));
    memcpy(x->slot + ci + 1, n->slot + ci + 1, (size_t)r * sizeof(void *));
    hamt_node_adopt(x, HAMT_NO_SKIP);
    return x;
}

/* A collision node with one more entry at its end. */
static hamt_node *hamt_node_coll_add(void *cx, const hamt_node *n, hamt_entry *e) {
    hamt_node *r;
    if (n->ncoll == 0xffffffffU) return NULL;
    r = hamt_node_new(cx, n->ncoll + 1);
    if (!r) return NULL;
    r->ncoll = n->ncoll + 1;
    memcpy(r->slot, n->slot, (size_t)n->ncoll * sizeof(void *));
    r->slot[n->ncoll] = e;
    hamt_node_adopt(r, HAMT_NO_SKIP);
    return r;
}

/* A collision node without its i-th entry. Down to one, it is a node its
 * parent will fold away at once. */
static hamt_node *hamt_node_coll_drop(void *cx, const hamt_node *n, uint32_t i) {
    hamt_node *r = hamt_node_new(cx, n->ncoll - 1);
    if (!r) return NULL;
    r->ncoll = n->ncoll - 1;
    memcpy(r->slot, n->slot, (size_t)i * sizeof(void *));
    memcpy(r->slot + i, n->slot + i + 1, (size_t)(n->ncoll - 1 - i) * sizeof(void *));
    hamt_node_adopt(r, HAMT_NO_SKIP);
    return r;
}

/* The smallest subtree that holds two entries with different keys, built to
 * hang at `depth`. Where their hashes still agree it is a chain of nodes
 * with one child each; where they part, a node with the two entries; and if
 * they never part, a collision node. Both entries are shared. */
static hamt_node *hamt_node_pair(void *cx, hamt_entry *a, hamt_entry *b,
                                 unsigned depth) {
    hamt_node *n, *sub;
    unsigned ia, ib;

    if (depth >= HAMT_MAX_DEPTH) {
        n = hamt_node_new(cx, 2);
        if (!n) return NULL;
        n->ncoll   = 2;
        n->slot[0] = a;
        n->slot[1] = b;
        hamt_node_adopt(n, HAMT_NO_SKIP);
        return n;
    }

    ia = HAMT_IDX(a->hash, depth);
    ib = HAMT_IDX(b->hash, depth);
    if (ia != ib) {
        n = hamt_node_new(cx, 2);
        if (!n) return NULL;
        n->datamap = ((uint32_t)1 << ia) | ((uint32_t)1 << ib);
        n->slot[0] = ia < ib ? a : b;
        n->slot[1] = ia < ib ? b : a;
        hamt_node_adopt(n, HAMT_NO_SKIP);
        return n;
    }

    sub = hamt_node_pair(cx, a, b, depth + 1);
    if (!sub) return NULL;
    n = hamt_node_new(cx, 1);
    if (!n) { hamt_node_release(cx, sub); return NULL; }
    n->nodemap = (uint32_t)1 << ia;
    n->slot[0] = sub;
    return n;
}

#endif
