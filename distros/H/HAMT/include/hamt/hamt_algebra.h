#ifndef HAMT_ALGEBRA_H
#define HAMT_ALGEBRA_H

/* Operations over TWO tries at once: are they equal, what is their union,
 * where do they differ.
 *
 * All three walk the two together, position by position, and all three get
 * their speed from one fact: if the two nodes at the same place are the same
 * pointer, everything under them is the same, and there is nothing to do.
 * Two versions of one map differ along a handful of paths, so comparing or
 * merging them costs what changed between them and not what they hold.
 *
 * They can be walked in step at all because of the canonical shape: the
 * same keys always make the same trie, so a position that holds a child in
 * one and an entry in the other is a real difference in content, never an
 * accident of history.
 *
 * Callbacks return 0 to carry on. Anything else stops the operation, which
 * unwinds what it had built and reports HAMT_ERR_ABORT; a callback that ran
 * out of memory returns HAMT_ERR_OOM and that is reported instead. */

#define HAMT_OK          0
#define HAMT_ERR_ABORT   1
#define HAMT_ERR_OOM     2

/* How many entries a subtree holds. Visits every node of it. */
static size_t hamt_node_count(const hamt_node *n) {
    uint32_t nd, N, i;
    size_t total;
    if (!n) return 0;
    nd = hamt_node_ndata(n);
    N  = hamt_node_nslots(n);
    total = nd;
    for (i = nd; i < N; i++) total += hamt_node_count((const hamt_node *)n->slot[i]);
    return total;
}

/* ---- equality ---------------------------------------------------------- */

/* 1 equal, 0 not, negative to stop. */
typedef int (*hamt_eq_fn)(void *ud, void *cx, void *va, void *vb);

typedef struct hamt_eq_ctx {
    void      *cx;
    hamt_eq_fn eq;      /* NULL: HAMT_VAL_EQ */
    void      *ud;
    size_t     visits;  /* node pairs looked at */
} hamt_eq_ctx;

static int hamt_val_same(hamt_eq_ctx *c, void *va, void *vb) {
    if (va == vb) return 1;
    if (!va || !vb) return 0;
    if (c->eq) return c->eq(c->ud, c->cx, va, vb);
    return HAMT_VAL_EQ(c->cx, va, vb) ? 1 : 0;
}

/* 1 when the two subtrees hold the same keys with equal values, 0 when they
 * do not, negative when the comparison callback stopped it. */
static int hamt_node_equal(hamt_eq_ctx *c, const hamt_node *a, const hamt_node *b) {
    uint32_t nd, N, i, j;

    if (a == b) return 1;
    if (!a || !b) return 0;
    c->visits++;

    if (a->datamap != b->datamap || a->nodemap != b->nodemap || a->ncoll != b->ncoll)
        return 0;
    nd = hamt_node_ndata(a);
    N  = hamt_node_nslots(a);

    if (a->ncoll) {
        /* The same keys, in whatever order each node happens to hold them. */
        for (i = 0; i < nd; i++) {
            const hamt_entry *ea = (const hamt_entry *)a->slot[i];
            const hamt_entry *eb = NULL;
            int rc;
            for (j = 0; j < nd; j++) {
                eb = (const hamt_entry *)b->slot[j];
                if (hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) break;
            }
            if (j == nd) return 0;
            rc = hamt_val_same(c, ea->val, eb->val);
            if (rc <= 0) return rc;
        }
        return 1;
    }

    for (i = 0; i < nd; i++) {
        const hamt_entry *ea = (const hamt_entry *)a->slot[i];
        const hamt_entry *eb = (const hamt_entry *)b->slot[i];
        int rc;
        if (ea == eb) continue;
        if (!hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) return 0;
        rc = hamt_val_same(c, ea->val, eb->val);
        if (rc <= 0) return rc;
    }
    for (; i < N; i++) {
        int rc = hamt_node_equal(c, (const hamt_node *)a->slot[i],
                                 (const hamt_node *)b->slot[i]);
        if (rc <= 0) return rc;
    }
    return 1;
}

/* ---- union ------------------------------------------------------------- */

/* Called for a key in both maps whose two values are not the same pointer.
 * Sets *out to the entry the result should hold, with one reference for the
 * caller: `ea` or `eb` retained, or a new entry under the same key.
 * Returns HAMT_OK, HAMT_ERR_ABORT or HAMT_ERR_OOM. */
typedef int (*hamt_resolve_fn)(void *ud, void *cx, hamt_entry *ea,
                               hamt_entry *eb, hamt_entry **out);

typedef struct hamt_merge_ctx {
    void           *cx;
    hamt_resolve_fn resolve;   /* NULL: the second map's entry wins */
    void           *ud;
    size_t          added;     /* keys of the second map that the first lacked */
    size_t          visits;    /* node pairs looked at */
    int             err;
} hamt_merge_ctx;

/* The entry for a key both maps hold. One reference, or NULL with err set. */
static hamt_entry *hamt_merge_resolve(hamt_merge_ctx *c, hamt_entry *ea,
                                      hamt_entry *eb) {
    hamt_entry *out = NULL;
    int rc;

    /* The first map's entry when there is nothing to choose between, so the
     * result shares with the first map wherever it can. */
    if (ea == eb || ea->val == eb->val) return hamt_entry_retain(ea);
    if (!c->resolve) return hamt_entry_retain(eb);

    rc = c->resolve(c->ud, c->cx, ea, eb, &out);
    if (rc != HAMT_OK) { c->err = rc; return NULL; }
    return out;
}

/* One entry from one map into a subtree of the other. `e_is_first` says
 * which map the entry came from, which is the order the resolver is told.
 * `*found` is whether the subtree already had the key. Returns `n` itself,
 * retained, when the subtree is unchanged. */
static hamt_node *hamt_merge_put(hamt_merge_ctx *c, hamt_node *n, unsigned depth,
                                 hamt_entry *e, int e_is_first, int *found) {
    hamt_entry *old = hamt_node_find(n, depth, e->key, e->klen, e->utf8, e->hash);
    hamt_entry *r;
    hamt_node *out;
    int added = 0;

    *found = old != NULL;
    if (!old) {
        out = hamt_node_put(c->cx, n, depth, e, &added);
        if (!out) c->err = HAMT_ERR_OOM;
        return out;
    }

    r = e_is_first ? hamt_merge_resolve(c, e, old) : hamt_merge_resolve(c, old, e);
    if (!r) return NULL;
    /* When the choice is the entry already there, the put gives `n` back. */
    out = hamt_node_put(c->cx, n, depth, r, &added);
    hamt_entry_release(c->cx, r);
    if (!out) c->err = HAMT_ERR_OOM;
    return out;
}

static hamt_node *hamt_node_merge(hamt_merge_ctx *c, hamt_node *a, hamt_node *b,
                                  unsigned depth);

/* Two collision nodes: the first's entries, each resolved against the
 * second's where the key is in both, then the second's that the first has
 * not got. */
static hamt_node *hamt_coll_merge(hamt_merge_ctx *c, hamt_node *a, hamt_node *b) {
    size_t cap = (size_t)a->ncoll + (size_t)b->ncoll;
    size_t bytes = cap * sizeof(void *);
    hamt_entry **list;
    uint32_t n = 0, i, j;
    int same_a = 1, same_b = 1;
    hamt_node *r = NULL;

    if (cap > 0xffffffffU) { c->err = HAMT_ERR_OOM; return NULL; }
    list = (hamt_entry **)HAMT_ALLOC(c->cx, bytes);
    if (!list) { c->err = HAMT_ERR_OOM; return NULL; }

    for (i = 0; i < a->ncoll; i++) {
        hamt_entry *ea = (hamt_entry *)a->slot[i], *eb = NULL, *e;
        for (j = 0; j < b->ncoll; j++) {
            eb = (hamt_entry *)b->slot[j];
            if (hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) break;
        }
        if (j == b->ncoll) {
            e = hamt_entry_retain(ea);
            same_b = 0;
        }
        else {
            e = hamt_merge_resolve(c, ea, eb);
            if (!e) goto fail;
            if (e != ea) same_a = 0;
            if (e != eb) same_b = 0;
        }
        list[n++] = e;
    }
    for (j = 0; j < b->ncoll; j++) {
        hamt_entry *eb = (hamt_entry *)b->slot[j];
        for (i = 0; i < a->ncoll; i++) {
            hamt_entry *ea = (hamt_entry *)a->slot[i];
            if (hamt_entry_key_eq(ea, eb->key, eb->klen, eb->utf8, eb->hash)) break;
        }
        if (i < a->ncoll) continue;
        list[n++] = hamt_entry_retain(eb);
        c->added++;
        same_a = 0;
    }

    if (same_a)      r = hamt_node_retain(a);
    else if (same_b) r = hamt_node_retain(b);
    else {
        r = hamt_node_new(c->cx, n);
        if (!r) { c->err = HAMT_ERR_OOM; goto fail; }
        r->ncoll = n;
        memcpy(r->slot, list, (size_t)n * sizeof(void *));
        HAMT_FREE(c->cx, list, bytes);
        return r;                        /* the list's references are the node's now */
    }

  fail:
    for (i = 0; i < n; i++) hamt_entry_release(c->cx, list[i]);
    HAMT_FREE(c->cx, list, bytes);
    return r;
}

/* The union of two subtrees that hang at the same place. One reference, or
 * NULL with err set. Returns `a` itself when the result is exactly `a`, and
 * `b` itself when it is exactly `b`, so a caller can tell that nothing
 * changed on that side by comparing pointers. */
static hamt_node *hamt_node_merge(hamt_merge_ctx *c, hamt_node *a, hamt_node *b,
                                  unsigned depth) {
    void *rd[32], *rc[32];          /* what goes in the result: entries, children */
    uint32_t datamap = 0, nodemap = 0, nd = 0, nc = 0, pos, i, N;
    uint32_t na_slots, nb_slots;
    int same_a = 1, same_b = 1;
    hamt_node *r;

    if (a == b) return hamt_node_retain(a);
    c->visits++;
    if (a->ncoll) return hamt_coll_merge(c, a, b);

    na_slots = hamt_node_nslots(a);
    nb_slots = hamt_node_nslots(b);

    /* Every pointer put in rd[] and rc[] is one this function owns a
     * reference to, shared or newly made alike, so the two ways out - build
     * the node, or give everything back - need not tell them apart. */
    for (pos = 0; pos < 32; pos++) {
        uint32_t bit = (uint32_t)1 << pos;
        hamt_entry *ea = NULL, *eb = NULL;
        hamt_node  *ca = NULL, *cb = NULL;

        if (a->datamap & bit)
            ea = (hamt_entry *)a->slot[hamt_popcnt32(a->datamap & (bit - 1))];
        else if (a->nodemap & bit)
            ca = (hamt_node *)a->slot[na_slots - 1 - hamt_popcnt32(a->nodemap & (bit - 1))];
        if (b->datamap & bit)
            eb = (hamt_entry *)b->slot[hamt_popcnt32(b->datamap & (bit - 1))];
        else if (b->nodemap & bit)
            cb = (hamt_node *)b->slot[nb_slots - 1 - hamt_popcnt32(b->nodemap & (bit - 1))];

        if (!ea && !ca && !eb && !cb) continue;

        if (!eb && !cb) {                           /* the first map's alone */
            same_b = 0;
            if (ea) { rd[nd++] = hamt_entry_retain(ea); datamap |= bit; }
            else    { rc[nc++] = hamt_node_retain(ca);  nodemap |= bit; }
        }
        else if (!ea && !ca) {                      /* the second's alone */
            same_a = 0;
            if (eb) { rd[nd++] = hamt_entry_retain(eb); datamap |= bit; c->added++; }
            else {
                rc[nc++] = hamt_node_retain(cb);
                nodemap |= bit;
                c->added += hamt_node_count(cb);
            }
        }
        else if (ea && eb) {
            if (hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) {
                hamt_entry *e = hamt_merge_resolve(c, ea, eb);
                if (!e) goto fail;
                if (e != ea) same_a = 0;
                if (e != eb) same_b = 0;
                rd[nd++] = e;
                datamap |= bit;
            }
            else {                                  /* two keys, one position */
                hamt_node *sub = hamt_node_pair(c->cx, ea, eb, depth + 1);
                if (!sub) { c->err = HAMT_ERR_OOM; goto fail; }
                same_a = same_b = 0;
                c->added++;
                rc[nc++] = sub;
                nodemap |= bit;
            }
        }
        else if (ea) {                              /* an entry meets a subtree */
            int found;
            hamt_node *sub = hamt_merge_put(c, cb, depth + 1, ea, 1, &found);
            if (!sub) goto fail;
            same_a = 0;
            if (sub != cb) same_b = 0;
            c->added += hamt_node_count(cb) - (found ? 1 : 0);
            rc[nc++] = sub;
            nodemap |= bit;
        }
        else if (eb) {                              /* a subtree meets an entry */
            int found;
            hamt_node *sub = hamt_merge_put(c, ca, depth + 1, eb, 0, &found);
            if (!sub) goto fail;
            if (sub != ca) same_a = 0;
            same_b = 0;
            if (!found) c->added++;
            rc[nc++] = sub;
            nodemap |= bit;
        }
        else {                                      /* two subtrees */
            hamt_node *sub = hamt_node_merge(c, ca, cb, depth + 1);
            if (!sub) goto fail;
            if (sub != ca) same_a = 0;
            if (sub != cb) same_b = 0;
            rc[nc++] = sub;
            nodemap |= bit;
        }
    }

    if (same_a || same_b) {
        for (i = 0; i < nd; i++) hamt_entry_release(c->cx, (hamt_entry *)rd[i]);
        for (i = 0; i < nc; i++) hamt_node_release(c->cx, (hamt_node *)rc[i]);
        return hamt_node_retain(same_a ? a : b);
    }

    N = nd + nc;
    r = hamt_node_new(c->cx, N);
    if (!r) { c->err = HAMT_ERR_OOM; goto fail; }
    r->datamap = datamap;
    r->nodemap = nodemap;
    for (i = 0; i < nd; i++) r->slot[i] = rd[i];
    for (i = 0; i < nc; i++) r->slot[N - 1 - i] = rc[i];    /* lowest position last */
    return r;

  fail:
    for (i = 0; i < nd; i++) hamt_entry_release(c->cx, (hamt_entry *)rd[i]);
    for (i = 0; i < nc; i++) hamt_node_release(c->cx, (hamt_node *)rc[i]);
    return NULL;
}

/* The root of a trie holding every key of both. Where a key is in both, the
 * resolver chooses, or the second map's entry wins when there is none.
 *
 * One reference, owned by the caller. c->added is how many keys the second
 * map brought that the first did not have, so the result's count is the
 * first map's plus that. The result IS `a` when `b` added and changed
 * nothing, and IS `b` when the result is exactly `b`.
 *
 * NULL with c->err set means it stopped: nothing is leaked and neither
 * input is touched. NULL with c->err clear means both were empty. */
static hamt_node *hamt_map_merge(hamt_merge_ctx *c, hamt_node *a, hamt_node *b) {
    c->added  = 0;
    c->visits = 0;
    c->err    = HAMT_OK;
    if (!b) return a ? hamt_node_retain(a) : NULL;
    if (!a) { c->added = hamt_node_count(b); return hamt_node_retain(b); }
    return hamt_node_merge(c, a, b, 0);
}

/* ---- difference -------------------------------------------------------- */

#define HAMT_DIFF_ADD    1   /* in the second map only: ea is NULL */
#define HAMT_DIFF_REMOVE 2   /* in the first map only: eb is NULL  */
#define HAMT_DIFF_CHANGE 3   /* in both, with values that are not equal */

/* 0 to carry on, anything else to stop. */
typedef int (*hamt_diff_fn)(void *ud, void *cx, int kind, hamt_entry *ea,
                            hamt_entry *eb);

typedef struct hamt_diff_ctx {
    void        *cx;
    hamt_diff_fn fn;
    void        *ud;
    hamt_eq_ctx  eq;       /* how two values under one key are compared */
    size_t       visits;   /* node pairs looked at */
    size_t       reported;
} hamt_diff_ctx;

static int hamt_diff_report(hamt_diff_ctx *c, int kind, hamt_entry *ea,
                            hamt_entry *eb) {
    c->reported++;
    return c->fn ? c->fn(c->ud, c->cx, kind, ea, eb) : 0;
}

/* The same key on both sides: a change, or nothing. */
static int hamt_diff_same_key(hamt_diff_ctx *c, hamt_entry *ea, hamt_entry *eb) {
    int rc;
    if (ea == eb) return 0;
    rc = hamt_val_same(&c->eq, ea->val, eb->val);
    if (rc < 0) return HAMT_ERR_ABORT;
    return rc ? 0 : hamt_diff_report(c, HAMT_DIFF_CHANGE, ea, eb);
}

/* Everything under a subtree is on one side only. */
static int hamt_diff_all(hamt_diff_ctx *c, const hamt_node *n, int kind) {
    hamt_iter it;
    hamt_entry *e;
    int rc;
    hamt_iter_init(&it, n);
    while ((e = hamt_iter_next(&it))) {
        rc = kind == HAMT_DIFF_ADD ? hamt_diff_report(c, kind, NULL, e)
                                   : hamt_diff_report(c, kind, e, NULL);
        if (rc) return rc;
    }
    return 0;
}

/* One entry against a subtree of the other map. `kind` is what the
 * subtree's other entries are: ADD when the subtree is the second map's. */
static int hamt_diff_entry_vs_node(hamt_diff_ctx *c, hamt_entry *e,
                                   const hamt_node *n, int kind) {
    hamt_iter it;
    hamt_entry *x;
    int rc, found = 0;

    hamt_iter_init(&it, n);
    while ((x = hamt_iter_next(&it))) {
        if (hamt_entry_key_eq(x, e->key, e->klen, e->utf8, e->hash)) {
            found = 1;
            rc = kind == HAMT_DIFF_ADD ? hamt_diff_same_key(c, e, x)
                                       : hamt_diff_same_key(c, x, e);
        }
        else {
            rc = kind == HAMT_DIFF_ADD ? hamt_diff_report(c, kind, NULL, x)
                                       : hamt_diff_report(c, kind, x, NULL);
        }
        if (rc) return rc;
    }
    if (found) return 0;
    return kind == HAMT_DIFF_ADD ? hamt_diff_report(c, HAMT_DIFF_REMOVE, e, NULL)
                                 : hamt_diff_report(c, HAMT_DIFF_ADD, NULL, e);
}

static int hamt_node_diff(hamt_diff_ctx *c, const hamt_node *a, const hamt_node *b) {
    uint32_t pos, i, j, na_slots, nb_slots;
    int rc;

    if (a == b) return 0;
    c->visits++;

    if (a->ncoll) {
        for (i = 0; i < a->ncoll; i++) {
            hamt_entry *ea = (hamt_entry *)a->slot[i], *eb = NULL;
            for (j = 0; j < b->ncoll; j++) {
                eb = (hamt_entry *)b->slot[j];
                if (hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) break;
            }
            rc = j == b->ncoll ? hamt_diff_report(c, HAMT_DIFF_REMOVE, ea, NULL)
                               : hamt_diff_same_key(c, ea, eb);
            if (rc) return rc;
        }
        for (j = 0; j < b->ncoll; j++) {
            hamt_entry *eb = (hamt_entry *)b->slot[j];
            for (i = 0; i < a->ncoll; i++) {
                hamt_entry *ea = (hamt_entry *)a->slot[i];
                if (hamt_entry_key_eq(ea, eb->key, eb->klen, eb->utf8, eb->hash)) break;
            }
            if (i < a->ncoll) continue;
            rc = hamt_diff_report(c, HAMT_DIFF_ADD, NULL, eb);
            if (rc) return rc;
        }
        return 0;
    }

    na_slots = hamt_node_nslots(a);
    nb_slots = hamt_node_nslots(b);

    for (pos = 0; pos < 32; pos++) {
        uint32_t bit = (uint32_t)1 << pos;
        hamt_entry *ea = NULL, *eb = NULL;
        const hamt_node *ca = NULL, *cb = NULL;

        if (a->datamap & bit)
            ea = (hamt_entry *)a->slot[hamt_popcnt32(a->datamap & (bit - 1))];
        else if (a->nodemap & bit)
            ca = (const hamt_node *)a->slot[na_slots - 1 - hamt_popcnt32(a->nodemap & (bit - 1))];
        if (b->datamap & bit)
            eb = (hamt_entry *)b->slot[hamt_popcnt32(b->datamap & (bit - 1))];
        else if (b->nodemap & bit)
            cb = (const hamt_node *)b->slot[nb_slots - 1 - hamt_popcnt32(b->nodemap & (bit - 1))];

        if (!ea && !ca && !eb && !cb) continue;

        if (!eb && !cb)
            rc = ea ? hamt_diff_report(c, HAMT_DIFF_REMOVE, ea, NULL)
                    : hamt_diff_all(c, ca, HAMT_DIFF_REMOVE);
        else if (!ea && !ca)
            rc = eb ? hamt_diff_report(c, HAMT_DIFF_ADD, NULL, eb)
                    : hamt_diff_all(c, cb, HAMT_DIFF_ADD);
        else if (ea && eb) {
            if (hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash))
                rc = hamt_diff_same_key(c, ea, eb);
            else {
                rc = hamt_diff_report(c, HAMT_DIFF_REMOVE, ea, NULL);
                if (!rc) rc = hamt_diff_report(c, HAMT_DIFF_ADD, NULL, eb);
            }
        }
        else if (ea) rc = hamt_diff_entry_vs_node(c, ea, cb, HAMT_DIFF_ADD);
        else if (eb) rc = hamt_diff_entry_vs_node(c, eb, ca, HAMT_DIFF_REMOVE);
        else         rc = hamt_node_diff(c, ca, cb);

        if (rc) return rc;
    }
    return 0;
}

/* Reports every key that is in one map and not the other, or in both with
 * values that are not equal, once each and in no promised order. Allocates
 * nothing. 0, or whatever stopped it. */
static int hamt_map_diff(hamt_diff_ctx *c, const hamt_node *a, const hamt_node *b) {
    c->visits   = 0;
    c->reported = 0;
    c->eq.visits = 0;
    if (a == b) return 0;
    if (!a) return hamt_diff_all(c, b, HAMT_DIFF_ADD);
    if (!b) return hamt_diff_all(c, a, HAMT_DIFF_REMOVE);
    return hamt_node_diff(c, a, b);
}

/* ---- intersection and difference --------------------------------------
 *
 * Both keep some of the FIRST trie's entries and none of the second's: the
 * intersection keeps those whose key the second trie has, the difference
 * those whose key it has not. Values play no part, so these serve a set,
 * whose entries have none, and would serve a map's keys as well.
 *
 * Unlike a union, these REMOVE, so a subtree can come back smaller than a
 * subtree is allowed to be. The canonical shape is restored on the way up,
 * exactly as delete does it: what comes back from a position is a part -
 * nothing, or a lone entry for the parent to hold in place of the child, or
 * a node.
 *
 * COUNTING. The result's size has to be known without walking the result,
 * or the speed of skipping shared subtrees is spent counting them. Two
 * tallies are kept - entries kept and entries removed - and either gives
 * the size, as `kept` or as the first trie's count less `removed`. Each is
 * exact only if one kind of skipped subtree is walked after all: `kept`
 * needs the subtrees that are kept whole, `removed` the ones removed whole.
 * `count_shared` picks: when the second trie is small next to the first,
 * the subtrees the two have in common are small, and those are the ones
 * walked; otherwise the ones only the first has. The caller sets it from
 * the two counts, and reads back whichever tally that makes exact. */

#define HAMT_PART_NONE  0
#define HAMT_PART_ENTRY 1
#define HAMT_PART_NODE  2

typedef struct hamt_part {
    int   kind;
    void *p;        /* one reference, the receiver's */
} hamt_part;

typedef struct hamt_set_ctx {
    void  *cx;
    int    count_shared;   /* walk the subtrees common to both, not the first's own */
    size_t kept;
    size_t removed;
    size_t visits;         /* node pairs looked at */
    size_t walked;         /* entries counted by walking a subtree */
    int    err;
} hamt_set_ctx;

/* The size of a subtree that is being kept or removed whole, found by
 * walking it. The tally of what this costs is what the tests hold to
 * account: it must stay small whenever one of the two results is. */
static size_t hamt_set_walk(hamt_set_ctx *c, const hamt_node *n) {
    size_t k = hamt_node_count(n);
    c->walked += k;
    return k;
}

static hamt_part hamt_part_make(int kind, void *p) {
    hamt_part r;
    r.kind = kind;
    r.p    = p;
    return r;
}

/* What a position's gathered entries and children amount to. Every pointer
 * in rd[] and rc[] is one the caller owns a reference to; all of them are
 * used or released here. `same` means they are exactly what `a` holds, in
 * which case `a` itself is the answer. */
static hamt_part hamt_part_build(hamt_set_ctx *c, hamt_node *a, unsigned depth,
                                 int same, uint32_t datamap, uint32_t nodemap,
                                 void **rd, uint32_t nd, void **rc, uint32_t nc) {
    uint32_t i, N = nd + nc;
    hamt_node *r;

    if (same || N == 0 || c->err) {
        for (i = 0; i < nd; i++) hamt_entry_release(c->cx, (hamt_entry *)rd[i]);
        for (i = 0; i < nc; i++) hamt_node_release(c->cx, (hamt_node *)rc[i]);
        if (c->err || N == 0) return hamt_part_make(HAMT_PART_NONE, NULL);
        return hamt_part_make(HAMT_PART_NODE, hamt_node_retain(a));
    }
    /* One entry and nothing else, below the root: the parent holds it. */
    if (nc == 0 && nd == 1 && depth > 0)
        return hamt_part_make(HAMT_PART_ENTRY, rd[0]);

    r = hamt_node_new(c->cx, N);
    if (!r) {
        c->err = HAMT_ERR_OOM;
        for (i = 0; i < nd; i++) hamt_entry_release(c->cx, (hamt_entry *)rd[i]);
        for (i = 0; i < nc; i++) hamt_node_release(c->cx, (hamt_node *)rc[i]);
        return hamt_part_make(HAMT_PART_NONE, NULL);
    }
    r->datamap = datamap;
    r->nodemap = nodemap;
    for (i = 0; i < nd; i++) r->slot[i] = rd[i];
    for (i = 0; i < nc; i++) r->slot[N - 1 - i] = rc[i];
    return hamt_part_make(HAMT_PART_NODE, r);
}

/* Two collision nodes: the first's entries that the second has (`keep_common`)
 * or has not. */
static hamt_part hamt_coll_filter(hamt_set_ctx *c, hamt_node *a, hamt_node *b,
                                  int keep_common) {
    size_t bytes = (size_t)a->ncoll * sizeof(void *);
    hamt_entry **list = (hamt_entry **)HAMT_ALLOC(c->cx, bytes);
    uint32_t n = 0, i, j;
    hamt_part out = hamt_part_make(HAMT_PART_NONE, NULL);

    if (!list) { c->err = HAMT_ERR_OOM; return out; }
    for (i = 0; i < a->ncoll; i++) {
        hamt_entry *ea = (hamt_entry *)a->slot[i];
        for (j = 0; j < b->ncoll; j++) {
            hamt_entry *eb = (hamt_entry *)b->slot[j];
            if (hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) break;
        }
        if ((j < b->ncoll) == (keep_common != 0)) { list[n++] = ea; c->kept++; }
        else c->removed++;
    }

    if (n == a->ncoll) out = hamt_part_make(HAMT_PART_NODE, hamt_node_retain(a));
    else if (n == 1)   out = hamt_part_make(HAMT_PART_ENTRY, hamt_entry_retain(list[0]));
    else if (n > 1) {
        hamt_node *r = hamt_node_new(c->cx, n);
        if (!r) c->err = HAMT_ERR_OOM;
        else {
            r->ncoll = n;
            memcpy(r->slot, list, (size_t)n * sizeof(void *));
            hamt_node_adopt(r, HAMT_NO_SKIP);
            out = hamt_part_make(HAMT_PART_NODE, r);
        }
    }
    HAMT_FREE(c->cx, list, bytes);
    return out;
}

/* Where the gathering loop puts a part that came back from below. */
#define HAMT_PART_PLACE(part, child, bit)                                    \
    do {                                                                     \
        if ((part).kind == HAMT_PART_NODE) {                                 \
            if ((part).p != (void *)(child)) same = 0;                       \
            rc[nc++] = (part).p; nodemap |= (bit);                           \
        }                                                                    \
        else {                                                               \
            same = 0;                                                        \
            if ((part).kind == HAMT_PART_ENTRY) {                            \
                rd[nd++] = (part).p; datamap |= (bit);                       \
            }                                                                \
        }                                                                    \
    } while (0)

static hamt_part hamt_node_intersect(hamt_set_ctx *c, hamt_node *a, hamt_node *b,
                                     unsigned depth) {
    void *rd[32], *rc[32];
    uint32_t datamap = 0, nodemap = 0, nd = 0, nc = 0, pos, na_slots, nb_slots;
    int same = 1;

    c->visits++;
    if (a->ncoll) return hamt_coll_filter(c, a, b, 1);

    na_slots = hamt_node_nslots(a);
    nb_slots = hamt_node_nslots(b);

    for (pos = 0; pos < 32 && !c->err; pos++) {
        uint32_t bit = (uint32_t)1 << pos;
        hamt_entry *ea = NULL, *eb = NULL;
        hamt_node  *ca = NULL, *cb = NULL;

        if (a->datamap & bit)
            ea = (hamt_entry *)a->slot[hamt_popcnt32(a->datamap & (bit - 1))];
        else if (a->nodemap & bit)
            ca = (hamt_node *)a->slot[na_slots - 1 - hamt_popcnt32(a->nodemap & (bit - 1))];
        else continue;                              /* nothing here to keep */

        if (b->datamap & bit)
            eb = (hamt_entry *)b->slot[hamt_popcnt32(b->datamap & (bit - 1))];
        else if (b->nodemap & bit)
            cb = (hamt_node *)b->slot[nb_slots - 1 - hamt_popcnt32(b->nodemap & (bit - 1))];

        if (ea) {
            int has = eb ? hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)
                    : cb ? hamt_node_find(cb, depth + 1, ea->key, ea->klen, ea->utf8, ea->hash) != NULL
                    : 0;
            if (has) { rd[nd++] = hamt_entry_retain(ea); datamap |= bit; c->kept++; }
            else     { same = 0; c->removed++; }
        }
        else if (!eb && !cb) {                      /* a subtree with no partner */
            same = 0;
            if (!c->count_shared) c->removed += hamt_set_walk(c, ca);
        }
        else if (eb) {                              /* at most one of a subtree */
            hamt_entry *e = hamt_node_find(ca, depth + 1, eb->key, eb->klen, eb->utf8, eb->hash);
            same = 0;
            if (!c->count_shared) c->removed += hamt_set_walk(c, ca) - (e ? 1 : 0);
            if (e) { rd[nd++] = hamt_entry_retain(e); datamap |= bit; c->kept++; }
        }
        else if (ca == cb) {                        /* the same subtree: all of it */
            rc[nc++] = hamt_node_retain(ca);
            nodemap |= bit;
            if (c->count_shared) c->kept += hamt_set_walk(c, ca);
        }
        else {
            hamt_part part = hamt_node_intersect(c, ca, cb, depth + 1);
            HAMT_PART_PLACE(part, ca, bit);
        }
    }
    return hamt_part_build(c, a, depth, same, datamap, nodemap, rd, nd, rc, nc);
}

static hamt_part hamt_node_subtract(hamt_set_ctx *c, hamt_node *a, hamt_node *b,
                                    unsigned depth) {
    void *rd[32], *rc[32];
    uint32_t datamap = 0, nodemap = 0, nd = 0, nc = 0, pos, na_slots, nb_slots;
    int same = 1;

    c->visits++;
    if (a->ncoll) return hamt_coll_filter(c, a, b, 0);

    na_slots = hamt_node_nslots(a);
    nb_slots = hamt_node_nslots(b);

    for (pos = 0; pos < 32 && !c->err; pos++) {
        uint32_t bit = (uint32_t)1 << pos;
        hamt_entry *ea = NULL, *eb = NULL;
        hamt_node  *ca = NULL, *cb = NULL;

        if (a->datamap & bit)
            ea = (hamt_entry *)a->slot[hamt_popcnt32(a->datamap & (bit - 1))];
        else if (a->nodemap & bit)
            ca = (hamt_node *)a->slot[na_slots - 1 - hamt_popcnt32(a->nodemap & (bit - 1))];
        else continue;

        if (b->datamap & bit)
            eb = (hamt_entry *)b->slot[hamt_popcnt32(b->datamap & (bit - 1))];
        else if (b->nodemap & bit)
            cb = (hamt_node *)b->slot[nb_slots - 1 - hamt_popcnt32(b->nodemap & (bit - 1))];

        if (ea) {
            int has = eb ? hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)
                    : cb ? hamt_node_find(cb, depth + 1, ea->key, ea->klen, ea->utf8, ea->hash) != NULL
                    : 0;
            if (has) { same = 0; c->removed++; }
            else     { rd[nd++] = hamt_entry_retain(ea); datamap |= bit; c->kept++; }
        }
        else if (!eb && !cb) {                      /* a subtree with no partner: kept whole */
            rc[nc++] = hamt_node_retain(ca);
            nodemap |= bit;
            if (!c->count_shared) c->kept += hamt_set_walk(c, ca);
        }
        else if (eb) {                              /* a subtree less at most one key */
            hamt_entry *e = hamt_node_find(ca, depth + 1, eb->key, eb->klen, eb->utf8, eb->hash);
            if (!c->count_shared) c->kept += hamt_set_walk(c, ca) - (e ? 1 : 0);
            if (!e) { rc[nc++] = hamt_node_retain(ca); nodemap |= bit; }
            else {
                int status;
                hamt_node *sub = hamt_node_del(c->cx, ca, depth + 1, eb->key, eb->klen,
                                               eb->utf8, eb->hash, &status);
                same = 0;
                c->removed++;
                if (status == HAMT_DEL_OOM || !sub) { c->err = HAMT_ERR_OOM; break; }
                if (hamt_node_is_single(sub)) {     /* down to one: it moves up */
                    rd[nd++] = hamt_entry_retain((hamt_entry *)sub->slot[0]);
                    datamap |= bit;
                    hamt_node_release(c->cx, sub);
                }
                else { rc[nc++] = sub; nodemap |= bit; }
            }
        }
        else if (ca == cb) {                        /* the same subtree: none of it */
            same = 0;
            if (c->count_shared) c->removed += hamt_set_walk(c, ca);
        }
        else {
            hamt_part part = hamt_node_subtract(c, ca, cb, depth + 1);
            HAMT_PART_PLACE(part, ca, bit);
        }
    }
    return hamt_part_build(c, a, depth, same, datamap, nodemap, rd, nd, rc, nc);
}

static void hamt_set_ctx_start(hamt_set_ctx *c, size_t ca, size_t cb) {
    c->count_shared = cb <= ca / 2;
    c->kept    = 0;
    c->removed = 0;
    c->visits  = 0;
    c->walked  = 0;
    c->err     = HAMT_OK;
}

/* The root of a trie holding the first trie's entries whose key the second
 * also has. `ca` and `cb` are the two counts; `*count` is the result's.
 * The result IS `a` when the second has every key of the first. NULL is an
 * empty result, or a failure when c->err is set. */
static hamt_node *hamt_set_intersect(hamt_set_ctx *c, hamt_node *a, hamt_node *b,
                                     size_t ca, size_t cb, size_t *count) {
    hamt_part part;

    hamt_set_ctx_start(c, ca, cb);
    *count = 0;
    if (!a || !b) return NULL;
    if (a == b) { *count = ca; return hamt_node_retain(a); }

    part = hamt_node_intersect(c, a, b, 0);
    if (c->err || part.kind == HAMT_PART_NONE) return NULL;
    *count = c->count_shared ? c->kept : ca - c->removed;
    return (hamt_node *)part.p;
}

/* The root of a trie holding the first trie's entries whose key the second
 * has NOT. The result IS `a` when the two share no key. */
static hamt_node *hamt_set_subtract(hamt_set_ctx *c, hamt_node *a, hamt_node *b,
                                    size_t ca, size_t cb, size_t *count) {
    hamt_part part;

    hamt_set_ctx_start(c, ca, cb);
    *count = 0;
    if (!a || a == b) return NULL;
    if (!b) { *count = ca; return hamt_node_retain(a); }

    part = hamt_node_subtract(c, a, b, 0);
    if (c->err || part.kind == HAMT_PART_NONE) return NULL;
    *count = c->count_shared ? ca - c->removed : c->kept;
    return (hamt_node *)part.p;
}

/* ---- two questions that need no result --------------------------------- */

/* 1 when every key of `a` is a key of `b`. Stops at the first that is not,
 * and allocates nothing. */
static int hamt_node_subset(const hamt_node *a, const hamt_node *b, unsigned depth,
                            size_t *visits) {
    uint32_t pos, i, j, na_slots, nb_slots;

    if (a == b) return 1;
    (*visits)++;

    if (a->ncoll) {
        for (i = 0; i < a->ncoll; i++) {
            const hamt_entry *ea = (const hamt_entry *)a->slot[i];
            for (j = 0; j < b->ncoll; j++)
                if (hamt_entry_key_eq((const hamt_entry *)b->slot[j],
                                      ea->key, ea->klen, ea->utf8, ea->hash)) break;
            if (j == b->ncoll) return 0;
        }
        return 1;
    }

    /* Anything of `a` at a position where `b` has nothing settles it. */
    if ((a->datamap | a->nodemap) & ~(b->datamap | b->nodemap)) return 0;
    /* A subtree holds two keys at least, and cannot fit in one entry. */
    if (a->nodemap & b->datamap) return 0;

    na_slots = hamt_node_nslots(a);
    nb_slots = hamt_node_nslots(b);
    for (pos = 0; pos < 32; pos++) {
        uint32_t bit = (uint32_t)1 << pos;
        if (a->datamap & bit) {
            const hamt_entry *ea = (const hamt_entry *)
                a->slot[hamt_popcnt32(a->datamap & (bit - 1))];
            if (b->datamap & bit) {
                const hamt_entry *eb = (const hamt_entry *)
                    b->slot[hamt_popcnt32(b->datamap & (bit - 1))];
                if (!hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) return 0;
            }
            else {
                const hamt_node *cb = (const hamt_node *)
                    b->slot[nb_slots - 1 - hamt_popcnt32(b->nodemap & (bit - 1))];
                if (!hamt_node_find(cb, depth + 1, ea->key, ea->klen, ea->utf8, ea->hash)) return 0;
            }
        }
        else if (a->nodemap & bit) {
            const hamt_node *ca = (const hamt_node *)
                a->slot[na_slots - 1 - hamt_popcnt32(a->nodemap & (bit - 1))];
            const hamt_node *cb = (const hamt_node *)
                b->slot[nb_slots - 1 - hamt_popcnt32(b->nodemap & (bit - 1))];
            if (!hamt_node_subset(ca, cb, depth + 1, visits)) return 0;
        }
    }
    return 1;
}

static int hamt_set_subset(const hamt_node *a, const hamt_node *b, size_t ca,
                           size_t cb, size_t *visits) {
    *visits = 0;
    if (!a) return 1;
    if (!b || ca > cb) return 0;
    return hamt_node_subset(a, b, 0, visits);
}

/* 1 when the two have no key in common. Stops at the first they share. */
static int hamt_node_disjoint(const hamt_node *a, const hamt_node *b, unsigned depth,
                              size_t *visits) {
    uint32_t common, pos, i, j, na_slots, nb_slots;

    if (a == b) return 0;                           /* a node is never empty */
    (*visits)++;

    if (a->ncoll) {
        for (i = 0; i < a->ncoll; i++) {
            const hamt_entry *ea = (const hamt_entry *)a->slot[i];
            for (j = 0; j < b->ncoll; j++)
                if (hamt_entry_key_eq((const hamt_entry *)b->slot[j],
                                      ea->key, ea->klen, ea->utf8, ea->hash)) return 0;
        }
        return 1;
    }

    /* Only positions both use can hold a shared key. */
    common = (a->datamap | a->nodemap) & (b->datamap | b->nodemap);
    na_slots = hamt_node_nslots(a);
    nb_slots = hamt_node_nslots(b);
    for (pos = 0; pos < 32; pos++) {
        uint32_t bit = (uint32_t)1 << pos;
        const hamt_entry *ea = NULL, *eb = NULL;
        const hamt_node  *ca = NULL, *cb = NULL;

        if (!(common & bit)) continue;
        if (a->datamap & bit) ea = (const hamt_entry *)a->slot[hamt_popcnt32(a->datamap & (bit - 1))];
        else ca = (const hamt_node *)a->slot[na_slots - 1 - hamt_popcnt32(a->nodemap & (bit - 1))];
        if (b->datamap & bit) eb = (const hamt_entry *)b->slot[hamt_popcnt32(b->datamap & (bit - 1))];
        else cb = (const hamt_node *)b->slot[nb_slots - 1 - hamt_popcnt32(b->nodemap & (bit - 1))];

        if (ea && eb) {
            if (hamt_entry_key_eq(eb, ea->key, ea->klen, ea->utf8, ea->hash)) return 0;
        }
        else if (ea) {
            if (hamt_node_find(cb, depth + 1, ea->key, ea->klen, ea->utf8, ea->hash)) return 0;
        }
        else if (eb) {
            if (hamt_node_find(ca, depth + 1, eb->key, eb->klen, eb->utf8, eb->hash)) return 0;
        }
        else if (!hamt_node_disjoint(ca, cb, depth + 1, visits)) return 0;
    }
    return 1;
}

static int hamt_set_disjoint(const hamt_node *a, const hamt_node *b, size_t *visits) {
    *visits = 0;
    if (!a || !b) return 1;
    return hamt_node_disjoint(a, b, 0, visits);
}

#endif
