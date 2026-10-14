#ifndef HAMT_MAP_H
#define HAMT_MAP_H

/* Lookup, insert and delete on a trie of hamt_node.
 *
 * Everything here works on a ROOT, and an empty map is a NULL root. An
 * update copies the nodes on one path from the root to where the key lives
 * and shares every other node with the trie it started from, which it never
 * touches: the caller still holds the old root, and it is exactly as it was.
 *
 * THE CANONICAL SHAPE. Below the root, a node exists only where two or more
 * entries share the path to it. Insert cannot break that. Delete can - it
 * can leave a node holding one entry and nothing else - so on the way back
 * up, a child that has come down to a single entry is folded into its
 * parent as that entry. The fold can repeat all the way to the root.
 *
 * It follows that two maps holding the same keys have the same shape,
 * whatever order they were built in and whatever was deleted on the way. */

#ifndef HAMT_MAP_FWD
#define HAMT_MAP_FWD
typedef struct hamt_map hamt_map;
#endif
struct hamt_map {
    hamt_node *root;
    size_t     count;
};

#define HAMT_DEL_OOM   (-1)
#define HAMT_DEL_ABSENT  0
#define HAMT_DEL_DONE    1

/* The entry for a key in the subtree under `n`, which hangs at `depth`:
 * borrowed, or NULL. Allocates nothing and changes no reference count. */
static hamt_entry *hamt_node_find(const hamt_node *n, unsigned depth,
                                  const char *key, size_t klen, int utf8,
                                  uint64_t hash) {

    while (n) {
        uint32_t bit, i;

        if (n->ncoll) {
            for (i = 0; i < n->ncoll; i++) {
                hamt_entry *e = (hamt_entry *)n->slot[i];
                if (hamt_entry_key_eq(e, key, klen, utf8, hash)) return e;
            }
            return NULL;
        }

        bit = HAMT_BIT(hash, depth);
        if (n->datamap & bit) {
            hamt_entry *e = (hamt_entry *)
                n->slot[hamt_popcnt32(n->datamap & (bit - 1))];
            return hamt_entry_key_eq(e, key, klen, utf8, hash) ? e : NULL;
        }
        if (!(n->nodemap & bit)) return NULL;

        n = (const hamt_node *)n->slot[hamt_node_nslots(n) - 1
                                       - hamt_popcnt32(n->nodemap & (bit - 1))];
        depth++;
    }
    return NULL;
}

/* The entry for a key, borrowed, or NULL. Retain what you keep. */
static hamt_entry *hamt_map_find(const hamt_node *root, const char *key,
                                 size_t klen, int utf8, uint64_t hash) {
    return hamt_node_find(root, 0, key, klen, utf8, hash);
}

static hamt_node *hamt_node_put(void *cx, hamt_node *n, unsigned depth,
                                hamt_entry *e, int *added) {
    uint32_t bit, i;

    if (n->ncoll) {
        for (i = 0; i < n->ncoll; i++) {
            hamt_entry *old = (hamt_entry *)n->slot[i];
            if (!hamt_entry_key_eq(old, e->key, e->klen, e->utf8, e->hash)) continue;
            if (old == e || old->val == e->val) return hamt_node_retain(n);
            return hamt_node_with_slot(cx, n, i, e, HAMT_NO_SKIP);
        }
        *added = 1;
        return hamt_node_coll_add(cx, n, e);
    }

    bit = HAMT_BIT(e->hash, depth);

    if (n->datamap & bit) {
        uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
        hamt_entry *old = (hamt_entry *)n->slot[di];
        hamt_node *sub, *r;

        if (hamt_entry_key_eq(old, e->key, e->klen, e->utf8, e->hash)) {
            /* The same value under the same key is no change, and the same
             * root comes back: nothing is allocated. */
            if (old == e || old->val == e->val) return hamt_node_retain(n);
            return hamt_node_with_slot(cx, n, di, e, HAMT_NO_SKIP);
        }

        sub = hamt_node_pair(cx, old, e, depth + 1);
        if (!sub) return NULL;
        r = hamt_node_entry_to_child(cx, n, bit, sub);
        if (!r) { hamt_node_release(cx, sub); return NULL; }
        *added = 1;
        return r;
    }

    if (n->nodemap & bit) {
        uint32_t ci = hamt_node_nslots(n) - 1 - hamt_popcnt32(n->nodemap & (bit - 1));
        hamt_node *child = (hamt_node *)n->slot[ci];
        hamt_node *sub = hamt_node_put(cx, child, depth + 1, e, added);
        hamt_node *r;

        if (!sub) return NULL;
        if (sub == child) {
            hamt_node_release(cx, sub);
            return hamt_node_retain(n);
        }
        r = hamt_node_with_slot(cx, n, ci, sub, ci);
        if (!r) { hamt_node_release(cx, sub); *added = 0; return NULL; }
        return r;
    }

    {
        hamt_node *r = hamt_node_add_entry(cx, n, bit, e);
        if (r) *added = 1;
        return r;
    }
}

/* The root of a trie that holds everything `root` holds and `e` as well, or
 * in place of the entry with e's key. One reference, owned by the caller.
 * The entry is shared: the caller keeps its own reference to it.
 *
 * `*added` is 1 when the key was not there before and 0 when it was. When
 * the key was there with the very same value, the root that comes back IS
 * `root`, retained.
 *
 * NULL means no memory, and only that: `root` is untouched, and nothing was
 * retained. */
static hamt_node *hamt_map_put(void *cx, hamt_node *root, hamt_entry *e,
                               int *added) {
    hamt_node *r;

    *added = 0;
    if (!root) {
        r = hamt_node_new(cx, 1);
        if (!r) return NULL;
        r->datamap = HAMT_BIT(e->hash, 0);
        r->slot[0] = e;
        hamt_node_adopt(r, HAMT_NO_SKIP);
        *added = 1;
        return r;
    }
    r = hamt_node_put(cx, root, 0, e, added);
    if (!r) *added = 0;
    return r;
}

static hamt_node *hamt_node_del(void *cx, hamt_node *n, unsigned depth,
                                const char *key, size_t klen, int utf8,
                                uint64_t hash, int *status) {
    uint32_t bit, i;

    if (n->ncoll) {
        for (i = 0; i < n->ncoll; i++) {
            hamt_node *r;
            if (!hamt_entry_key_eq((hamt_entry *)n->slot[i], key, klen, utf8, hash))
                continue;
            r = hamt_node_coll_drop(cx, n, i);
            *status = r ? HAMT_DEL_DONE : HAMT_DEL_OOM;
            return r;
        }
        *status = HAMT_DEL_ABSENT;
        return hamt_node_retain(n);
    }

    bit = HAMT_BIT(hash, depth);

    if (n->datamap & bit) {
        hamt_entry *old = (hamt_entry *)
            n->slot[hamt_popcnt32(n->datamap & (bit - 1))];
        hamt_node *r;

        if (!hamt_entry_key_eq(old, key, klen, utf8, hash)) {
            *status = HAMT_DEL_ABSENT;
            return hamt_node_retain(n);
        }
        /* The last entry of the last node: the map is empty. Only a root
         * gets here, since nothing below a root is ever down to one. */
        if (hamt_node_nslots(n) == 1) {
            *status = HAMT_DEL_DONE;
            return NULL;
        }
        r = hamt_node_drop_entry(cx, n, bit);
        *status = r ? HAMT_DEL_DONE : HAMT_DEL_OOM;
        return r;
    }

    if (n->nodemap & bit) {
        uint32_t ci = hamt_node_nslots(n) - 1 - hamt_popcnt32(n->nodemap & (bit - 1));
        hamt_node *child = (hamt_node *)n->slot[ci];
        hamt_node *sub = hamt_node_del(cx, child, depth + 1, key, klen, utf8,
                                       hash, status);
        hamt_node *r;

        if (*status == HAMT_DEL_OOM) return NULL;
        if (*status == HAMT_DEL_ABSENT) {
            hamt_node_release(cx, sub);
            return hamt_node_retain(n);
        }
        if (!sub) HAMT_FATAL("a node below the root came back empty");

        /* The fold. The child is down to one entry, so it stops existing and
         * the entry moves up into the position the child had. If that leaves
         * THIS node with one entry and nothing else, the caller folds it in
         * turn. */
        if (hamt_node_is_single(sub))
            r = hamt_node_child_to_entry(cx, n, bit, (hamt_entry *)sub->slot[0]);
        else
            r = hamt_node_with_slot(cx, n, ci, sub, HAMT_NO_SKIP);

        hamt_node_release(cx, sub);
        if (!r) *status = HAMT_DEL_OOM;
        return r;
    }

    *status = HAMT_DEL_ABSENT;
    return hamt_node_retain(n);
}

/* The root of a trie that holds everything `root` holds but the entry for
 * this key. One reference, owned by the caller, when it is not NULL.
 *
 *   HAMT_DEL_DONE    the key was there. The root may be NULL: an empty map.
 *   HAMT_DEL_ABSENT  it was not. The root that comes back IS `root`, retained
 *                    (or NULL for NULL).
 *   HAMT_DEL_OOM     no memory. NULL comes back and `root` is untouched. */
static hamt_node *hamt_map_del(void *cx, hamt_node *root, const char *key,
                               size_t klen, int utf8, uint64_t hash,
                               int *status) {
    if (!root) {
        *status = HAMT_DEL_ABSENT;
        return NULL;
    }
    return hamt_node_del(cx, root, 0, key, klen, utf8, hash, status);
}

#endif
