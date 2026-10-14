#ifndef HAMT_VEC_H
#define HAMT_VEC_H

/* The vector: a sequence indexed from zero, with cheap append, cheap removal
 * from the end, cheap replacement anywhere - and, from the second half of
 * this file, concatenation, slicing and so insertion and removal in the
 * middle, all without copying what does not change.
 *
 * It is a tree 32 wide whose leaves hold the values. The last few values -
 * up to 32 of them - are kept out of the tree in a leaf of their own, the
 * TAIL, so that nearly every append and every removal from the end touches
 * one node and no path.
 *
 *     count   how many values in all
 *     tail    the last 1..32 of them; NULL only when count is 0
 *     root    a tree of everything before the tail; NULL when there is none
 *     shift   five times the number of levels of nodes above the leaves
 *
 * REGULAR AND RELAXED. In a vector that has only been pushed to, every leaf
 * in the tree is full and every node is full but the last on its level, so
 * the child that holds an index is five bits of the index and nothing has
 * to be looked up. Joining two such trees, or cutting one, leaves nodes
 * along the join or the cut that are part full. Those nodes are RELAXED:
 * each carries a table, `sizes`, of how many values lie under its first
 * child, its first two, and so on. Finding a child in one is a guess from
 * the index bits and then a step or two forward along the table.
 *
 * A node with no table is regular, and that is a promise: every child but
 * its last holds exactly as many values as a child at that level can. A
 * node is given a table exactly when that would not be true (hamt_vnode_make
 * decides), so a tree that happens to come out regular is treated as one.
 *
 * How far a relaxed tree strays is put right where two trees are joined and
 * where one is cut: the run of nodes along the join, or under each node
 * along the cut, is repacked until no more than HAMT_VEC_EXTRAS of them are
 * spare. That is what keeps the tree's height, and the steps a lookup takes
 * along a table, close to a regular tree's. It is a repair made at each
 * seam and not a promise about every node; see hamt_vec_check_spare.
 *
 * WHO MAY CHANGE WHAT. push, pop and set change a vector where it stands.
 * The caller owns the hamt_vec struct, and the struct owns one reference to
 * its root and one to its tail. A node whose reference count is one is the
 * vector's alone and is changed in place; any other is shared, and is copied
 * first, the copy taking the vector's place as holder of that reference. The
 * walk makes each node on its way its own before it steps into it
 * (hamt_vnode_own). A vector that never changes is made by giving every
 * update a struct of its own that starts out sharing the root and the tail.
 *
 * concat and slice are the other kind: they build a new vector from old
 * ones, which they only read.
 *
 * NO MEMORY. Every function either does what it was asked or leaves each
 * vector holding exactly the values it held. A failed push, pop or set may
 * leave some nodes as private copies of what they were, which nothing can
 * observe.
 *
 * THE DISPLACED VALUE. A set or a pop takes one value out. It is handed
 * back, with the reference the vector held, for the caller to release once
 * it is done with the struct: releasing it can run code that uses this very
 * vector. */

#define HAMT_VEC_BITS   5
#define HAMT_VEC_WIDTH  32
#define HAMT_VEC_MASK   31
#define HAMT_VEC_EXTRAS 2

/* For a test that wants to know how far a lookup had to step along a table. */
#ifndef HAMT_VEC_STEPPED
#  define HAMT_VEC_STEPPED() ((void)0)
#endif

typedef struct hamt_vnode {
    uint32_t  refcnt;
    uint16_t  len;       /* slots in use, 1..32 */
    uint16_t  leaf;      /* 1: the slots are values. 0: they are nodes */
    size_t   *sizes;     /* NULL: regular. Else sizes[k] is the number of
                          * values under children 0..k, for k < len */
    void     *slot[HAMT_VEC_WIDTH];
} hamt_vnode;

#define HAMT_VEC_SIZES_BYTES (HAMT_VEC_WIDTH * sizeof(size_t))

#ifndef HAMT_VEC_FWD
#define HAMT_VEC_FWD
typedef struct hamt_vec hamt_vec;
#endif
struct hamt_vec {
    size_t      count;
    uint32_t    shift;
    hamt_vnode *root;
    hamt_vnode *tail;
};

static hamt_vnode *hamt_vnode_new(void *cx, int leaf) {
    hamt_vnode *n = (hamt_vnode *)HAMT_ALLOC(cx, sizeof(hamt_vnode));
    if (!n) return NULL;
    n->refcnt = 1;
    n->len    = 0;
    n->leaf   = leaf ? 1 : 0;
    n->sizes  = NULL;
    (void)cx;
    return n;
}

static hamt_vnode *hamt_vnode_retain(hamt_vnode *n) {
    if (n->refcnt == 0xffffffffU) HAMT_FATAL("a vector node's reference count would wrap");
    n->refcnt++;
    return n;
}

/* The node's memory and its table: what it pointed at is the caller's
 * business. */
static void hamt_vnode_free_raw(void *cx, hamt_vnode *n) {
    if (n->sizes) HAMT_FREE(cx, n->sizes, HAMT_VEC_SIZES_BYTES);
    HAMT_FREE(cx, n, sizeof(hamt_vnode));
    (void)cx;
}

/* At zero the node is freed before anything it held is released: a value's
 * release can run code that comes back in here. */
static void hamt_vnode_release(void *cx, hamt_vnode *n) {
    void *s[HAMT_VEC_WIDTH];
    uint32_t i, len;
    int leaf;

    if (--n->refcnt) return;
    len  = n->len;
    leaf = n->leaf;
    memcpy(s, n->slot, (size_t)len * sizeof(void *));
    hamt_vnode_free_raw(cx, n);
    if (leaf) { for (i = 0; i < len; i++) HAMT_VAL_RELEASE(cx, s[i]); }
    else      { for (i = 0; i < len; i++) hamt_vnode_release(cx, (hamt_vnode *)s[i]); }
    (void)cx;
}

/* Makes the node in *slot the holder's alone and returns it. If it already
 * is, nothing happens. Otherwise *slot gets a copy that takes its own
 * reference to everything the original held, and the original loses the
 * reference *slot had. NULL when there is no memory, with *slot untouched. */
static hamt_vnode *hamt_vnode_own(void *cx, hamt_vnode **slot) {
    hamt_vnode *n = *slot, *c;
    uint32_t i;

    if (n->refcnt == 1) return n;
    c = hamt_vnode_new(cx, n->leaf);
    if (!c) return NULL;
    if (n->sizes) {
        c->sizes = (size_t *)HAMT_ALLOC(cx, HAMT_VEC_SIZES_BYTES);
        if (!c->sizes) { hamt_vnode_free_raw(cx, c); return NULL; }
        memcpy(c->sizes, n->sizes, (size_t)n->len * sizeof(size_t));
    }
    c->len = n->len;
    memcpy(c->slot, n->slot, (size_t)n->len * sizeof(void *));
    if (n->leaf) { for (i = 0; i < n->len; i++) HAMT_VAL_RETAIN(cx, c->slot[i]); }
    else         { for (i = 0; i < n->len; i++) hamt_vnode_retain((hamt_vnode *)c->slot[i]); }
    n->refcnt--;                    /* it was above one: this frees nothing */
    *slot = c;
    return c;
}

/* How many values a subtree holds. `level` is the node's own: 0 for a leaf.
 * A relaxed node knows; a regular one is full children and whatever its
 * last child holds, so this is one walk down the right-hand edge at most. */
static size_t hamt_vnode_count(const hamt_vnode *n, uint32_t level) {
    size_t total = 0;
    for (;;) {
        if (n->leaf) return total + n->len;
        if (n->sizes) return total + n->sizes[n->len - 1];
        total += (size_t)(n->len - 1) << level;
        n = (const hamt_vnode *)n->slot[n->len - 1];
        level -= HAMT_VEC_BITS;
    }
}

/* Which child of a node holds the value at *i, counted from the node's
 * first value; *i is left counted from that child's first. */
static uint32_t hamt_vnode_child(const hamt_vnode *n, uint32_t level, size_t *i) {
    uint32_t k = (uint32_t)(*i >> level);

    if (!n->sizes) {
        *i &= ((size_t)1 << level) - 1;
        return k;
    }
    /* The guess cannot be past the child: no child holds more than a full
     * one, so there cannot be fewer values before it than that many. */
    while (n->sizes[k] <= *i) { k++; HAMT_VEC_STEPPED(); }
    if (k) *i -= n->sizes[k - 1];
    return k;
}

/* A node at `level` over the children in kids[], which are nodes one level
 * down. Takes over the caller's references to them. It is given a table
 * exactly when it needs one. NULL when there is no memory, with the
 * children still the caller's. */
static hamt_vnode *hamt_vnode_make(void *cx, hamt_vnode **kids, uint32_t n, uint32_t level) {
    hamt_vnode *node = hamt_vnode_new(cx, 0);
    size_t full = (size_t)1 << level, total = 0;
    uint32_t k;
    int regular = 1;

    if (!node) return NULL;
    for (k = 0; k + 1 < n && regular; k++)
        if (hamt_vnode_count(kids[k], level - HAMT_VEC_BITS) != full) regular = 0;

    if (!regular) {
        node->sizes = (size_t *)HAMT_ALLOC(cx, HAMT_VEC_SIZES_BYTES);
        if (!node->sizes) { hamt_vnode_free_raw(cx, node); return NULL; }
        for (k = 0; k < n; k++) {
            total += hamt_vnode_count(kids[k], level - HAMT_VEC_BITS);
            node->sizes[k] = total;
        }
    }
    node->len = (uint16_t)n;
    memcpy(node->slot, kids, (size_t)n * sizeof(void *));
    return node;
}

/* A leaf holding the n values at vals[], each of which it retains. */
static hamt_vnode *hamt_vnode_leaf(void *cx, void *const *vals, uint32_t n) {
    hamt_vnode *leaf = hamt_vnode_new(cx, 1);
    uint32_t i;
    if (!leaf) return NULL;
    leaf->len = (uint16_t)n;
    memcpy(leaf->slot, vals, (size_t)n * sizeof(void *));
    for (i = 0; i < n; i++) HAMT_VAL_RETAIN(cx, leaf->slot[i]);
    (void)cx;
    return leaf;
}

static void hamt_vec_init(hamt_vec *v) {
    v->count = 0;
    v->shift = HAMT_VEC_BITS;
    v->root  = NULL;
    v->tail  = NULL;
}

/* A second struct onto the same vector: both now hold the root and the
 * tail, so the first update through either copies what it touches. */
static void hamt_vec_share(hamt_vec *dst, const hamt_vec *src) {
    *dst = *src;
    if (dst->root) hamt_vnode_retain(dst->root);
    if (dst->tail) hamt_vnode_retain(dst->tail);
}

/* Lets go of everything the struct holds and leaves it empty. The struct is
 * emptied first, so a value's release that looks at it sees an empty vector
 * and not a half-released one. */
static void hamt_vec_clear(void *cx, hamt_vec *v) {
    hamt_vnode *root = v->root, *tail = v->tail;
    hamt_vec_init(v);
    if (root) hamt_vnode_release(cx, root);
    if (tail) hamt_vnode_release(cx, tail);
}

/* Where the tail starts: the number of values in the tree. */
static size_t hamt_vec_tailoff(const hamt_vec *v) {
    return v->tail ? v->count - v->tail->len : v->count;
}

/* The leaf holding index i, which must be below the count, and where in the
 * vector that leaf starts. Borrowed. */
static const hamt_vnode *hamt_vec_leaf(const hamt_vec *v, size_t i, size_t *start) {
    const hamt_vnode *n;
    uint32_t level;
    size_t tailoff = hamt_vec_tailoff(v), rel = i;

    if (i >= tailoff) { *start = tailoff; return v->tail; }
    n = v->root;
    for (level = v->shift; level > 0; level -= HAMT_VEC_BITS)
        n = (const hamt_vnode *)n->slot[hamt_vnode_child(n, level, &rel)];
    *start = i - rel;
    return n;
}

/* The value at index i, which must be below the count. Borrowed. */
static void *hamt_vec_get(const hamt_vec *v, size_t i) {
    size_t start;
    const hamt_vnode *leaf = hamt_vec_leaf(v, i, &start);
    return leaf->slot[i - start];
}

/* A chain of nodes `level` deep with `leaf` at the bottom of it, taking over
 * the caller's reference to the leaf. A node with one child is regular
 * whatever the child holds. NULL when there is no memory, with the leaf
 * still the caller's. */
static hamt_vnode *hamt_vec_new_path(void *cx, uint32_t level, hamt_vnode *leaf) {
    hamt_vnode *top = leaf;
    uint32_t l;

    for (l = 0; l < level; l += HAMT_VEC_BITS) {
        hamt_vnode *n = hamt_vnode_new(cx, 0);
        if (!n) {
            while (top != leaf) {
                hamt_vnode *down = (hamt_vnode *)top->slot[0];
                hamt_vnode_free_raw(cx, top);
                top = down;
            }
            return NULL;
        }
        n->slot[0] = top;
        n->len = 1;
        top = n;
    }
    return top;
}

/* Hangs a leaf at the right-hand end of the tree, taking over the caller's
 * reference to it. The leaf may be short. 0, or -1 for no memory with the
 * leaf still the caller's and the vector holding what it held.
 *
 * The leaf goes under the lowest node on the right-hand edge that has a
 * slot free; if none has, a new root goes over the old one. A regular node
 * that gets a new last child stays regular only if the child that was last
 * is full, and is given a table if it is not. */
static int hamt_vec_push_leaf(void *cx, hamt_vec *v, hamt_vnode *leaf) {
    hamt_vnode *path, *n, *host = NULL;
    hamt_vnode **at;
    size_t *table = NULL;
    uint32_t level, host_level = 0;
    const hamt_vnode *scan;

    if (!v->root) {
        n = hamt_vnode_new(cx, 0);
        if (!n) return -1;
        n->slot[0] = leaf;
        n->len = 1;
        v->root  = n;
        v->shift = HAMT_VEC_BITS;
        return 0;
    }

    /* First, only looking: the lowest node on the edge with room. */
    scan = v->root;
    for (level = v->shift; level > 0; level -= HAMT_VEC_BITS) {
        if (scan->len < HAMT_VEC_WIDTH) host_level = level;
        scan = (const hamt_vnode *)scan->slot[scan->len - 1];
    }

    if (!host_level) {
        /* No room anywhere: a new root over the old one and a new path. */
        hamt_vnode *kids[2];
        path = hamt_vec_new_path(cx, v->shift, leaf);
        if (!path) return -1;
        kids[0] = v->root;
        kids[1] = path;
        n = hamt_vnode_make(cx, kids, 2, v->shift + HAMT_VEC_BITS);
        if (!n) {
            /* Take the chain down again without touching the leaf. */
            while (path != leaf) {
                hamt_vnode *down = (hamt_vnode *)path->slot[0];
                hamt_vnode_free_raw(cx, path);
                path = down;
            }
            return -1;
        }
        v->root   = n;
        v->shift += HAMT_VEC_BITS;
        return 0;
    }

    /* Make the edge this vector's own down to the host. Then everything the
     * change needs is allocated, and only then is anything changed. */
    at = &v->root;
    for (level = v->shift; ; level -= HAMT_VEC_BITS) {
        n = hamt_vnode_own(cx, at);
        if (!n) return -1;
        if (level == host_level) { host = n; break; }
        at = (hamt_vnode **)&n->slot[n->len - 1];
    }

    if (!host->sizes) {
        const hamt_vnode *was_last = (const hamt_vnode *)host->slot[host->len - 1];
        size_t under = hamt_vnode_count(was_last, host_level - HAMT_VEC_BITS);
        if (under != ((size_t)1 << host_level)) {
            uint32_t k;
            table = (size_t *)HAMT_ALLOC(cx, HAMT_VEC_SIZES_BYTES);
            if (!table) return -1;
            for (k = 0; k + 1 < host->len; k++) table[k] = (size_t)(k + 1) << host_level;
            table[host->len - 1] = ((size_t)(host->len - 1) << host_level) + under;
        }
    }
    path = hamt_vec_new_path(cx, host_level - HAMT_VEC_BITS, leaf);
    if (!path) {
        if (table) HAMT_FREE(cx, table, HAMT_VEC_SIZES_BYTES);
        return -1;
    }

    /* Nothing below can fail. Every relaxed node above the host has that
     * many more values under its last child. */
    n = v->root;
    for (level = v->shift; level > host_level; level -= HAMT_VEC_BITS) {
        if (n->sizes) n->sizes[n->len - 1] += leaf->len;
        n = (hamt_vnode *)n->slot[n->len - 1];
    }
    if (table) host->sizes = table;
    if (host->sizes) host->sizes[host->len] = host->sizes[host->len - 1] + leaf->len;
    host->slot[host->len++] = path;
    return 0;
}

/* Takes the tree's last leaf out to be the tail. The vector must have a
 * tree and no tail. 0, or -1 for no memory with the vector as it was. */
static int hamt_vec_pull_tail(void *cx, hamt_vec *v) {
    hamt_vnode *path[14], *n, *leaf;
    hamt_vnode **at;
    uint32_t level;
    int depth = 0, d;

    at = &v->root;
    for (level = v->shift; level > 0; level -= HAMT_VEC_BITS) {
        n = hamt_vnode_own(cx, at);
        if (!n) return -1;
        path[depth++] = n;
        at = (hamt_vnode **)&n->slot[n->len - 1];
    }
    leaf = *at;

    /* The leaf's reference moves from its parent to the tail. Going back up,
     * a node left with nothing is freed and its parent loses the slot; the
     * first node that still has something, and every relaxed node above it,
     * has that many fewer values under its last child. */
    d = depth;
    while (d > 0) {
        n = path[--d];
        if (--n->len > 0) break;
        hamt_vnode_free_raw(cx, n);
        if (d == 0) v->root = NULL;
    }
    while (d > 0) {
        n = path[--d];
        if (n->sizes) n->sizes[n->len - 1] -= leaf->len;
    }
    /* A root with one child is a level the tree no longer needs. */
    while (v->root && v->shift > HAMT_VEC_BITS && v->root->len == 1) {
        hamt_vnode *top = v->root;
        v->root = (hamt_vnode *)top->slot[0];
        hamt_vnode_free_raw(cx, top);
        v->shift -= HAMT_VEC_BITS;
    }
    if (!v->root) v->shift = HAMT_VEC_BITS;
    v->tail = leaf;
    return 0;
}

/* Appends a value. The vector takes its own reference. 0, or -1 for no
 * memory with the vector holding what it held. */
static int hamt_vec_push(void *cx, hamt_vec *v, void *val) {
    hamt_vnode *fresh, *n;

    /* Room in the tail: the common case, one node and no path. */
    if (v->tail && v->tail->len < HAMT_VEC_WIDTH) {
        n = hamt_vnode_own(cx, &v->tail);
        if (!n) return -1;
        HAMT_VAL_RETAIN(cx, val);
        n->slot[n->len++] = val;
        v->count++;
        return 0;
    }

    fresh = hamt_vnode_new(cx, 1);
    if (!fresh) return -1;
    if (v->tail && hamt_vec_push_leaf(cx, v, v->tail)) {
        hamt_vnode_free_raw(cx, fresh);
        return -1;
    }
    HAMT_VAL_RETAIN(cx, val);
    fresh->slot[0] = val;
    fresh->len = 1;
    v->tail = fresh;
    v->count++;
    return 0;
}

/* Replaces the value at index i, which must be below the count. The vector
 * takes its own reference to the new value; the old one comes back through
 * `dead` with the reference the vector held, or NULL when the new value is
 * the one already there and nothing was done. 0, or -1 for no memory. */
static int hamt_vec_set(void *cx, hamt_vec *v, size_t i, void *val, void **dead) {
    hamt_vnode **at, *n;
    uint32_t level;
    size_t tailoff = hamt_vec_tailoff(v);

    *dead = NULL;
    if (hamt_vec_get(v, i) == val) return 0;

    if (i >= tailoff) {
        n = hamt_vnode_own(cx, &v->tail);
        if (!n) return -1;
        i -= tailoff;
    }
    else {
        at = &v->root;
        for (level = v->shift; level > 0; level -= HAMT_VEC_BITS) {
            n = hamt_vnode_own(cx, at);
            if (!n) return -1;
            at = (hamt_vnode **)&n->slot[hamt_vnode_child(n, level, &i)];
        }
        n = hamt_vnode_own(cx, at);
        if (!n) return -1;
    }
    HAMT_VAL_RETAIN(cx, val);
    *dead = n->slot[i];
    n->slot[i] = val;
    return 0;
}

/* Lets go of a leaf that holds exactly one value, handing the value back
 * with a reference rather than releasing it. */
static void *hamt_vec_take_last(void *cx, hamt_vnode *leaf) {
    void *val = leaf->slot[0];
    if (leaf->refcnt == 1) hamt_vnode_free_raw(cx, leaf);   /* its reference is the caller's now */
    else {
        HAMT_VAL_RETAIN(cx, val);
        leaf->refcnt--;
    }
    (void)cx;
    return val;
}

/* Removes the last value, which comes back through `dead` with the
 * reference the vector held; NULL for an empty vector, which stays empty.
 * 0, or -1 for no memory with the vector holding what it held. */
static int hamt_vec_pop(void *cx, hamt_vec *v, void **dead) {
    hamt_vnode *n, *tail;

    *dead = NULL;
    if (v->count == 0) return 0;

    if (v->tail->len > 1) {
        n = hamt_vnode_own(cx, &v->tail);
        if (!n) return -1;
        *dead = n->slot[--n->len];
        v->count--;
        return 0;
    }

    /* The tail is down to its last value. If there is a tree, its last leaf
     * comes out to be the new tail - which is all that can fail, so it is
     * done first, with the old tail set aside. */
    tail = v->tail;
    v->tail = NULL;
    if (v->root && hamt_vec_pull_tail(cx, v)) {
        v->tail = tail;
        return -1;
    }
    v->count--;
    *dead = hamt_vec_take_last(cx, tail);
    return 0;
}

/* ---- walking ----------------------------------------------------------- */

/* Hands out the vector a leaf at a time: a run of up to 32 values and the
 * index of the first. One descent for each run, not for each value. The
 * vector is borrowed; whoever walks keeps it alive and unchanged. */
typedef struct hamt_vec_iter {
    const hamt_vec *v;
    size_t          pos;
} hamt_vec_iter;

static void hamt_vec_iter_init(hamt_vec_iter *it, const hamt_vec *v) {
    it->v   = v;
    it->pos = 0;
}

/* The next run, or NULL at the end. */
static void *const *hamt_vec_iter_next(hamt_vec_iter *it, size_t *start, uint32_t *n) {
    const hamt_vnode *leaf;
    size_t leaf_start;

    if (it->pos >= it->v->count) return NULL;
    /* A run is a whole leaf, so the position is always where one starts. */
    leaf = hamt_vec_leaf(it->v, it->pos, &leaf_start);
    *start = leaf_start;
    *n = leaf->len;
    it->pos = leaf_start + leaf->len;
    return (void *const *)leaf->slot;
}

/* 1 when the two hold equal values in the same order, 0 when not, negative
 * when the comparison stopped it. Two runs that are the same memory are the
 * same values and are not looked into, so two versions of one vector are
 * compared for what differs between them. The leaves of two vectors need
 * not line up: each stretch compared is as long as both current runs allow. */
static int hamt_vec_equal(hamt_eq_ctx *c, const hamt_vec *a, const hamt_vec *b) {
    hamt_vec_iter ia, ib;
    void *const *ra = NULL, *const *rb = NULL;
    size_t sa = 0, sb = 0, pos = 0;
    uint32_t na = 0, nb = 0;

    if (a->count != b->count) return 0;
    if (a->root == b->root && a->tail == b->tail) return 1;

    hamt_vec_iter_init(&ia, a);
    hamt_vec_iter_init(&ib, b);
    while (pos < a->count) {
        uint32_t i, k;
        if (pos >= sa + na) ra = hamt_vec_iter_next(&ia, &sa, &na);
        if (pos >= sb + nb) rb = hamt_vec_iter_next(&ib, &sb, &nb);
        k = (uint32_t)((sa + na < sb + nb ? sa + na : sb + nb) - pos);
        if (ra + (pos - sa) != rb + (pos - sb)) {
            c->visits++;
            for (i = 0; i < k; i++) {
                int rc = hamt_val_same(c, ra[pos - sa + i], rb[pos - sb + i]);
                if (rc <= 0) return rc;
            }
        }
        pos += k;
    }
    return 1;
}

/* ---- joining ------------------------------------------------------------
 *
 * Two trees are joined along the right-hand edge of the first and the
 * left-hand edge of the second. From the bottom up, at each level, there is
 * a run of nodes: what the left node holds but for its last child, what
 * came up from the level below, and what the right node holds but for its
 * first child. The run is repacked - nodes that are nearly full are left
 * exactly as they are and shared, a short one is poured into those after
 * it - until it is no more than HAMT_VEC_EXTRAS nodes longer than the
 * shortest it could be. Then it is gathered under one parent, or two, and
 * those go up to the level above.
 *
 * Nothing that is read is changed: every node the result uses unchanged is
 * shared, and only the nodes along the join are new. */

/* A handful of nodes, each of which the list owns a reference to. */
typedef struct hamt_vlist {
    hamt_vnode *n[2 * HAMT_VEC_WIDTH + 2];
    uint32_t    len;
} hamt_vlist;

static void hamt_vlist_release(void *cx, hamt_vlist *l) {
    uint32_t i;
    for (i = 0; i < l->len; i++) hamt_vnode_release(cx, l->n[i]);
    l->len = 0;
}

/* The run `all`, whose nodes are at `level` (0: leaves), repacked into
 * `out`. 0, or -1 for no memory with `out` empty. `all` is only read. */
static int hamt_rrb_repack(void *cx, const hamt_vlist *all, uint32_t level,
                           hamt_vlist *out) {
    uint32_t c[2 * HAMT_VEC_WIDTH + 2];
    uint32_t n = all->len, i, j, src = 0, off = 0;
    size_t total = 0, shortest;

    out->len = 0;
    for (i = 0; i < n; i++) { c[i] = all->n[i]->len; total += c[i]; }
    shortest = (total + HAMT_VEC_MASK) / HAMT_VEC_WIDTH;

    /* The plan: how many slots each node of the result will hold. While the
     * run is too long, the first node with a slot or more to spare is
     * emptied into the nodes after it, each filled in turn, and the run is
     * one node shorter. */
    i = 0;
    while (n > shortest + HAMT_VEC_EXTRAS) {
        uint32_t carry;
        while (c[i] >= HAMT_VEC_WIDTH - 1) i++;
        carry = c[i];
        do {
            uint32_t take = carry + c[i + 1] < HAMT_VEC_WIDTH ? carry + c[i + 1] : HAMT_VEC_WIDTH;
            carry = carry + c[i + 1] - take;
            c[i] = take;
            i++;
        } while (carry > 0);
        for (j = i; j + 1 < n; j++) c[j] = c[j + 1];
        n--;
        i--;
    }

    /* Carrying it out. A node the plan leaves whole is shared; anything
     * else is a new node filled from the old ones in order. */
    for (i = 0; i < n; i++) {
        hamt_vnode *made;

        if (off == 0 && all->n[src]->len == c[i]) {
            made = hamt_vnode_retain(all->n[src++]);
        }
        else {
            void *slots[HAMT_VEC_WIDTH];
            uint32_t got = 0, k;

            while (got < c[i]) {
                const hamt_vnode *from = all->n[src];
                uint32_t take = from->len - off;
                if (take > c[i] - got) take = c[i] - got;
                memcpy(slots + got, from->slot + off, (size_t)take * sizeof(void *));
                got += take;
                off += take;
                if (off == from->len) { src++; off = 0; }
            }
            if (level == 0) made = hamt_vnode_leaf(cx, slots, got);
            else {
                for (k = 0; k < got; k++) hamt_vnode_retain((hamt_vnode *)slots[k]);
                made = hamt_vnode_make(cx, (hamt_vnode **)slots, got, level);
                if (!made) for (k = 0; k < got; k++) hamt_vnode_release(cx, (hamt_vnode *)slots[k]);
            }
            if (!made) { hamt_vlist_release(cx, out); return -1; }
        }
        out->n[out->len++] = made;
    }
    return 0;
}

/* The nodes of `kids`, at the level below `level`, gathered under one node
 * at `level` or two. Takes over the list's references, which the caller must
 * then not release. 0, or -1 for no memory with `kids` still the caller's. */
static int hamt_rrb_gather(void *cx, hamt_vlist *kids, uint32_t level, hamt_vlist *out) {
    uint32_t first = kids->len < HAMT_VEC_WIDTH ? kids->len : HAMT_VEC_WIDTH;
    hamt_vnode *a, *b = NULL;

    out->len = 0;
    a = hamt_vnode_make(cx, kids->n, first, level);
    if (!a) return -1;
    if (kids->len > first) {
        b = hamt_vnode_make(cx, kids->n + first, kids->len - first, level);
        if (!b) {
            /* Undo the first without letting go of its children. */
            a->len = 0;
            hamt_vnode_free_raw(cx, a);
            return -1;
        }
    }
    out->n[out->len++] = a;
    if (b) out->n[out->len++] = b;
    return 0;
}

/* Joins the subtree L, at level ll, to the subtree R, at level rl. `out`
 * gets one node or two at the higher of the two levels, holding everything
 * under L followed by everything under R. L and R are only read. */
static int hamt_rrb_join(void *cx, const hamt_vnode *L, uint32_t ll,
                         const hamt_vnode *R, uint32_t rl, hamt_vlist *out) {
    hamt_vlist mid, all, packed;
    uint32_t level = ll > rl ? ll : rl, i;
    int rc;

    out->len = 0;
    if (level == 0) {
        out->n[0] = hamt_vnode_retain((hamt_vnode *)L);
        out->n[1] = hamt_vnode_retain((hamt_vnode *)R);
        out->len = 2;
        return 0;
    }

    /* Down whichever edge is higher, or both, until the levels meet. */
    if (ll > rl)      rc = hamt_rrb_join(cx, (const hamt_vnode *)L->slot[L->len - 1], ll - HAMT_VEC_BITS, R, rl, &mid);
    else if (ll < rl) rc = hamt_rrb_join(cx, L, ll, (const hamt_vnode *)R->slot[0], rl - HAMT_VEC_BITS, &mid);
    else              rc = hamt_rrb_join(cx, (const hamt_vnode *)L->slot[L->len - 1], ll - HAMT_VEC_BITS,
                                             (const hamt_vnode *)R->slot[0], rl - HAMT_VEC_BITS, &mid);
    if (rc) return rc;

    all.len = 0;
    if (ll >= rl)
        for (i = 0; i + 1 < L->len; i++) all.n[all.len++] = hamt_vnode_retain((hamt_vnode *)L->slot[i]);
    for (i = 0; i < mid.len; i++) all.n[all.len++] = mid.n[i];      /* the references move */
    if (rl >= ll)
        for (i = 1; i < R->len; i++) all.n[all.len++] = hamt_vnode_retain((hamt_vnode *)R->slot[i]);

    rc = hamt_rrb_repack(cx, &all, level - HAMT_VEC_BITS, &packed);
    hamt_vlist_release(cx, &all);
    if (rc) return rc;

    rc = hamt_rrb_gather(cx, &packed, level, out);
    if (rc) hamt_vlist_release(cx, &packed);
    return rc;
}

/* `out` becomes a vector of everything in `a` followed by everything in
 * `b`. Neither is changed, and the result shares with both everything that
 * is not along the join. `out` is uninitialised on the way in. 0, or -1 for
 * no memory with `out` empty. */
static int hamt_vec_concat(void *cx, hamt_vec *out, const hamt_vec *a, const hamt_vec *b) {
    hamt_vec left;
    hamt_vlist top;
    hamt_vnode *root;
    uint32_t shift;

    if (a->count == 0) { hamt_vec_share(out, b); return 0; }
    if (b->count == 0) { hamt_vec_share(out, a); return 0; }

    if (!b->root) {
        /* The second is a tail and nothing more: its values are pushed. */
        uint32_t i;
        hamt_vec_share(out, a);
        for (i = 0; i < b->tail->len; i++)
            if (hamt_vec_push(cx, out, b->tail->slot[i])) { hamt_vec_clear(cx, out); return -1; }
        return 0;
    }

    /* The first with its tail put into its tree, short as it may be, in a
     * struct of its own so that `a` is not touched. */
    hamt_vec_share(&left, a);
    if (hamt_vec_push_leaf(cx, &left, left.tail)) { hamt_vec_clear(cx, &left); hamt_vec_init(out); return -1; }
    left.tail = NULL;

    if (hamt_rrb_join(cx, left.root, left.shift, b->root, b->shift, &top)) {
        hamt_vec_clear(cx, &left);
        hamt_vec_init(out);
        return -1;
    }
    shift = left.shift > b->shift ? left.shift : b->shift;
    if (top.len == 1) root = top.n[0];
    else {
        root = hamt_vnode_make(cx, top.n, 2, shift + HAMT_VEC_BITS);
        if (!root) {
            hamt_vlist_release(cx, &top);
            hamt_vec_clear(cx, &left);
            hamt_vec_init(out);
            return -1;
        }
        shift += HAMT_VEC_BITS;
    }
    hamt_vec_clear(cx, &left);

    /* The root has two children at least: each tree's own root had, above
     * the lowest level, and what the join put between them is one more. */
    out->count = a->count + b->count;
    out->shift = shift;
    out->root  = root;
    out->tail  = hamt_vnode_retain(b->tail);
    return 0;
}

/* ---- cutting ------------------------------------------------------------ */

/* A node at `level` over the n children in kids[], one of which has just
 * been cut short. Cutting takes slots away without taking a child away, so
 * the children are repacked exactly as a join repacks its run, and the node
 * is no looser for having been cut. Takes over the caller's references to
 * the children whether or not it succeeds. */
static hamt_vnode *hamt_rrb_cut_node(void *cx, hamt_vnode **kids, uint32_t n, uint32_t level) {
    hamt_vlist all, packed;
    hamt_vnode *made;

    memcpy(all.n, kids, (size_t)n * sizeof(void *));
    all.len = n;
    if (hamt_rrb_repack(cx, &all, level - HAMT_VEC_BITS, &packed)) {
        hamt_vlist_release(cx, &all);
        return NULL;
    }
    hamt_vlist_release(cx, &all);
    made = hamt_vnode_make(cx, packed.n, packed.len, level);
    if (!made) hamt_vlist_release(cx, &packed);
    return made;
}

/* The first `keep` values under a node, as a node at the same level. `keep`
 * is at least one and at most what the node holds. One reference, or NULL
 * for no memory. Everything left of the cut is shared; the nodes along it
 * are new. */
static hamt_vnode *hamt_rrb_cut_right(void *cx, const hamt_vnode *n, uint32_t level, size_t keep) {
    hamt_vnode *kids[HAMT_VEC_WIDTH], *sub;
    size_t i = keep - 1;
    uint32_t k, j;

    if (keep == hamt_vnode_count(n, level)) return hamt_vnode_retain((hamt_vnode *)n);
    if (level == 0) return hamt_vnode_leaf(cx, (void *const *)n->slot, (uint32_t)keep);

    k = hamt_vnode_child(n, level, &i);
    sub = hamt_rrb_cut_right(cx, (const hamt_vnode *)n->slot[k], level - HAMT_VEC_BITS, i + 1);
    if (!sub) return NULL;
    for (j = 0; j < k; j++) kids[j] = hamt_vnode_retain((hamt_vnode *)n->slot[j]);
    kids[k] = sub;
    return hamt_rrb_cut_node(cx, kids, k + 1, level);
}

/* Everything under a node but its first `drop` values. `drop` is less than
 * what the node holds. */
static hamt_vnode *hamt_rrb_cut_left(void *cx, const hamt_vnode *n, uint32_t level, size_t drop) {
    hamt_vnode *kids[HAMT_VEC_WIDTH], *sub;
    size_t i = drop;
    uint32_t k, j, m = 0;

    if (drop == 0) return hamt_vnode_retain((hamt_vnode *)n);
    if (level == 0)
        return hamt_vnode_leaf(cx, (void *const *)n->slot + drop, (uint32_t)(n->len - drop));

    k = hamt_vnode_child(n, level, &i);
    sub = hamt_rrb_cut_left(cx, (const hamt_vnode *)n->slot[k], level - HAMT_VEC_BITS, i);
    if (!sub) return NULL;
    kids[m++] = sub;
    for (j = k + 1; j < n->len; j++) kids[m++] = hamt_vnode_retain((hamt_vnode *)n->slot[j]);
    return hamt_rrb_cut_node(cx, kids, m, level);
}

/* `out` becomes a vector of the `len` values of `v` starting at `from`,
 * which must lie within it; `len` is at least one. `v` is not changed.
 * `out` is uninitialised on the way in. 0, or -1 for no memory with `out`
 * empty. */
static int hamt_vec_slice(void *cx, hamt_vec *out, const hamt_vec *v, size_t from, size_t len) {
    size_t to = from + len, tailoff = hamt_vec_tailoff(v);
    hamt_vnode *root = NULL, *tail = NULL;
    uint32_t shift = v->shift;

    hamt_vec_init(out);

    if (to > tailoff) {
        /* Some of the tail is kept: that is the new tail. */
        size_t t0 = from > tailoff ? from - tailoff : 0, t1 = to - tailoff;
        if (t0 == 0 && t1 == v->tail->len) tail = hamt_vnode_retain(v->tail);
        else tail = hamt_vnode_leaf(cx, (void *const *)v->tail->slot + t0, (uint32_t)(t1 - t0));
        if (!tail) return -1;
        if (from < tailoff) {
            root = hamt_rrb_cut_left(cx, v->root, shift, from);
            if (!root) { hamt_vnode_release(cx, tail); return -1; }
        }
    }
    else {
        /* It ends inside the tree: cut the right, then the left. The last
         * leaf of what is left will be taken out as the tail. */
        hamt_vnode *right = hamt_rrb_cut_right(cx, v->root, shift, to);
        if (!right) return -1;
        root = hamt_rrb_cut_left(cx, right, shift, from);
        hamt_vnode_release(cx, right);
        if (!root) return -1;
    }

    /* What is left may be far smaller than the tree it was cut from, and
     * still as tall: a root with one child is a level too many, and a root
     * with two is the two cut edges and nothing between them, which is
     * exactly what a join takes. So the two are joined, level by level,
     * until the root is one that holds something. */
    while (root && shift > HAMT_VEC_BITS) {
        hamt_vnode *down;
        if (root->len == 1) down = hamt_vnode_retain((hamt_vnode *)root->slot[0]);
        else if (root->len == 2) {
            hamt_vlist top;
            if (hamt_rrb_join(cx, (const hamt_vnode *)root->slot[0], shift - HAMT_VEC_BITS,
                              (const hamt_vnode *)root->slot[1], shift - HAMT_VEC_BITS, &top)) {
                hamt_vnode_release(cx, root);
                if (tail) hamt_vnode_release(cx, tail);
                return -1;
            }
            if (top.len == 2) { hamt_vlist_release(cx, &top); break; }   /* it does need both */
            down = top.n[0];
        }
        else break;
        hamt_vnode_release(cx, root);
        root = down;
        shift -= HAMT_VEC_BITS;
    }
    out->count = len;
    out->shift = root ? shift : HAMT_VEC_BITS;
    out->root  = root;
    out->tail  = tail;
    if (!tail && hamt_vec_pull_tail(cx, out)) { hamt_vec_clear(cx, out); return -1; }
    return 0;
}

/* ---- the checker ------------------------------------------------------- */

#define HAMT_VCHK_OK          0
#define HAMT_VCHK_EMPTY       1   /* count 0 with a root or a tail, or the reverse */
#define HAMT_VCHK_TAIL        2   /* a tail that is not a leaf of 1..32 */
#define HAMT_VCHK_ROOT        3   /* a root where there should be none, or none where one */
#define HAMT_VCHK_SHIFT       4   /* a shift that is not a positive multiple of 5 */
#define HAMT_VCHK_REFCNT      5   /* a node with a count of zero */
#define HAMT_VCHK_LEN         6   /* a node holding nothing, or more than 32 */
#define HAMT_VCHK_KIND        7   /* a leaf where a node belongs, or the reverse */
#define HAMT_VCHK_NOT_FULL    8   /* a regular node with a child that is not last and not full */
#define HAMT_VCHK_TALL        9   /* a root with one child above the lowest level */
#define HAMT_VCHK_TOTAL      10   /* the tree does not hold what the count says */
#define HAMT_VCHK_NULL       11   /* a slot holding nothing */
#define HAMT_VCHK_SIZES      12   /* a table that does not say what is under the node */
#define HAMT_VCHK_SPARE      13   /* a relaxed node with more children to spare than allowed */
#define HAMT_VCHK_LEAF_TABLE 14   /* a leaf with a table */

/* How many values the subtree holds, recounted from its leaves; *rc gets
 * the first rule broken. */
static size_t hamt_vnode_check(const hamt_vnode *n, uint32_t level, uint32_t spare, int *rc) {
    size_t total = 0, full = (size_t)1 << level, slots = 0;
    uint32_t i;

    if (*rc) return 0;
    if (!n) { *rc = HAMT_VCHK_NULL; return 0; }
    if (n->refcnt == 0) { *rc = HAMT_VCHK_REFCNT; return 0; }
    if (n->len == 0 || n->len > HAMT_VEC_WIDTH) { *rc = HAMT_VCHK_LEN; return 0; }
    if ((n->leaf != 0) != (level == 0)) { *rc = HAMT_VCHK_KIND; return 0; }

    if (level == 0) {
        if (n->sizes) { *rc = HAMT_VCHK_LEAF_TABLE; return 0; }
        for (i = 0; i < n->len; i++) if (!n->slot[i]) { *rc = HAMT_VCHK_NULL; return 0; }
        return n->len;
    }
    for (i = 0; i < n->len; i++) {
        const hamt_vnode *kid = (const hamt_vnode *)n->slot[i];
        size_t got = hamt_vnode_check(kid, level - HAMT_VEC_BITS, spare, rc);
        if (*rc) return 0;
        total += got;
        slots += kid->len;
        if (n->sizes) { if (n->sizes[i] != total) { *rc = HAMT_VCHK_SIZES; return 0; } }
        else if (i + 1 < n->len && got != full) { *rc = HAMT_VCHK_NOT_FULL; return 0; }
    }
    /* No more children than the slots under them need, plus the spare. */
    if (n->len > (slots + HAMT_VEC_MASK) / HAMT_VEC_WIDTH + spare) {
        *rc = HAMT_VCHK_SPARE;
        return 0;
    }
    return total;
}

/* 0 when the vector is one this library could have built, otherwise the
 * number of the first rule it breaks. Visits every node.
 *
 * `spare` is how many more children a node may have than the slots under
 * them need, for a caller that wants to hold a vector to that as well.
 *
 * It is NOT something every vector satisfies, and hamt_vec_check does not
 * ask it. A join repacks the run of nodes along its seam until the RUN is
 * within HAMT_VEC_EXTRAS of the shortest it could be, and a cut does the
 * same for each node along the cut. That bounds the run, not each node
 * made from it: one level up, the same repacking moves whole children from
 * one parent to the next, and a parent can end up holding the loose end of
 * one neighbour and the loose start of another. So looseness is put right
 * where two trees meet and can gather, a little, elsewhere. What holds for
 * a vector made by joining and cutting vectors that were only ever pushed
 * to is the bound itself, and the tests hold those to it. What is held for
 * every vector is measured instead: its height, and how far a lookup steps
 * along a table. */
static int hamt_vec_check_spare(const hamt_vec *v, uint32_t spare) {
    size_t tailoff, total;
    uint32_t i;
    int rc = 0;

    if (v->count == 0) return (v->root || v->tail) ? HAMT_VCHK_EMPTY : HAMT_VCHK_OK;
    if (!v->tail) return HAMT_VCHK_EMPTY;
    if (!v->tail->leaf || v->tail->len == 0 || v->tail->len > HAMT_VEC_WIDTH
        || v->tail->len > v->count) return HAMT_VCHK_TAIL;
    if (v->tail->sizes) return HAMT_VCHK_LEAF_TABLE;
    if (v->tail->refcnt == 0) return HAMT_VCHK_REFCNT;
    for (i = 0; i < v->tail->len; i++) if (!v->tail->slot[i]) return HAMT_VCHK_NULL;

    tailoff = v->count - v->tail->len;
    if ((tailoff == 0) != (v->root == NULL)) return HAMT_VCHK_ROOT;
    if (!v->root) return HAMT_VCHK_OK;

    if (v->shift == 0 || v->shift % HAMT_VEC_BITS || v->shift > 60) return HAMT_VCHK_SHIFT;
    if (v->shift > HAMT_VEC_BITS && v->root->len == 1) return HAMT_VCHK_TALL;
    total = hamt_vnode_check(v->root, v->shift, spare, &rc);
    if (rc) return rc;
    return total == tailoff ? HAMT_VCHK_OK : HAMT_VCHK_TOTAL;
}

static int hamt_vec_check(const hamt_vec *v) {
    return hamt_vec_check_spare(v, HAMT_VEC_WIDTH);      /* no node has more children than that */
}

/* How many levels of nodes are over the leaves. */
static uint32_t hamt_vec_height(const hamt_vec *v) {
    return v->root ? v->shift / HAMT_VEC_BITS : 0;
}

#endif
