#ifndef HAMT_MUT_H
#define HAMT_MUT_H

/* Insert and delete that change a trie where it stands, wherever that is
 * safe, and copy only where it is not.
 *
 * WHEN IT IS SAFE. A node may be changed in place exactly when its
 * reference count is one. The caller of these functions owns one reference
 * to the root and hands it over; if that is the only reference there is,
 * nobody else can reach the root, so nobody else can see it change. The
 * same holds one level down: a child with a count of one is pointed at by
 * that parent alone, and the walk only reaches it through a parent it has
 * just found to be its own. A node with any other count is shared with
 * something - an older version, a snapshot, a walk in progress - and is
 * copied instead; the copy takes its own reference to each child, which
 * makes every child shared too, so everything under a shared node is copied
 * in turn without anything having to say so.
 *
 * This is why a batch of updates on a fresh handle costs one path of copies
 * for the first update and almost nothing for the rest: after the first,
 * the path is the handle's alone.
 *
 * It rests on one rule that every caller keeps: NOBODY HOLDS A NODE WITHOUT
 * COUNTING IT. A pointer kept across a call here without a reference of its
 * own is a pointer to something that may have been changed or freed.
 *
 * THE DISPLACED ENTRY. An update displaces at most one entry: the one whose
 * value is replaced, or the one deleted. Releasing it can run a value's
 * destructor, which can call back into the very handle being updated, so it
 * is not released here. It is handed back through `dead`, with a reference,
 * for the caller to release once the new root is in place.
 *
 * NO MEMORY. Every function either does all of its work or none: on failure
 * the trie is exactly as it was and the caller still owns the reference it
 * passed in. Nothing is changed in place until every allocation the change
 * needs has succeeded. */

#define HAMT_EDITABLE(n) ((n)->refcnt == 1)

/* The node with an entry added at a position that held nothing. If it has
 * room, it is changed where it stands and comes back itself. If not, it is
 * a new allocation that takes over the old node's references rather than
 * adding to them, and the old node's memory is freed. NULL when there is no
 * memory, with the node untouched. */
static hamt_node *hamt_node_add_entry_move(void *cx, hamt_node *n, uint32_t bit,
                                           hamt_entry *e) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    hamt_node *r;

    /* Room for one more where it stands: nothing is allocated. */
    if (HAMT_NODE_ROOM(N + 1) == HAMT_NODE_ROOM(N) && N) {
        memmove(n->slot + di + 1, n->slot + di, (size_t)(N - di) * sizeof(void *));
        n->slot[di] = hamt_entry_retain(e);
        n->datamap |= bit;
        return n;
    }
    r = hamt_node_new(cx, N + 1);
    if (!r) return NULL;
    r->datamap = n->datamap | bit;
    r->nodemap = n->nodemap;
    memcpy(r->slot, n->slot, (size_t)di * sizeof(void *));
    r->slot[di] = hamt_entry_retain(e);
    memcpy(r->slot + di + 1, n->slot + di, (size_t)(N - di) * sizeof(void *));
    HAMT_FREE(cx, n, HAMT_NODE_BYTES(N));
    return r;
}

/* The node without the entry at a position, the same way. The entry is
 * handed back with the reference the node held. */
static hamt_node *hamt_node_drop_entry_move(void *cx, hamt_node *n, uint32_t bit,
                                            hamt_entry **dropped) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    hamt_node *r;

    /* One fewer still needs the room it has: it stays where it is. */
    if (HAMT_NODE_ROOM(N - 1) == HAMT_NODE_ROOM(N)) {
        *dropped = (hamt_entry *)n->slot[di];
        memmove(n->slot + di, n->slot + di + 1, (size_t)(N - 1 - di) * sizeof(void *));
        n->datamap &= ~bit;
        return n;
    }
    r = hamt_node_new(cx, N - 1);
    if (!r) return NULL;
    r->datamap = n->datamap & ~bit;
    r->nodemap = n->nodemap;
    *dropped = (hamt_entry *)n->slot[di];
    memcpy(r->slot, n->slot, (size_t)di * sizeof(void *));
    memcpy(r->slot + di, n->slot + di + 1, (size_t)(N - 1 - di) * sizeof(void *));
    HAMT_FREE(cx, n, HAMT_NODE_BYTES(N));
    return r;
}

/* Same size, so no allocation: the entry at a position gives way to a
 * child, which takes over the caller's reference. The entry is handed back
 * with the reference the node held. */
static hamt_entry *hamt_node_entry_to_child_here(hamt_node *n, uint32_t bit,
                                                 hamt_node *child) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    uint32_t ci = N - 1 - hamt_popcnt32(n->nodemap & (bit - 1));
    hamt_entry *old = (hamt_entry *)n->slot[di];
    memmove(n->slot + di, n->slot + di + 1, (size_t)(ci - di) * sizeof(void *));
    n->slot[ci] = child;
    n->datamap &= ~bit;
    n->nodemap |= bit;
    return old;
}

/* And back: the child at a position gives way to an entry, which takes over
 * the caller's reference. The child is handed back with the reference the
 * node held. */
static hamt_node *hamt_node_child_to_entry_here(hamt_node *n, uint32_t bit,
                                                hamt_entry *e) {
    uint32_t N  = hamt_node_nslots(n);
    uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
    uint32_t ci = N - 1 - hamt_popcnt32(n->nodemap & (bit - 1));
    hamt_node *old = (hamt_node *)n->slot[ci];
    memmove(n->slot + di + 1, n->slot + di, (size_t)(ci - di) * sizeof(void *));
    n->slot[di] = e;
    n->datamap |= bit;
    n->nodemap &= ~bit;
    return old;
}

/* Takes over the caller's reference to `n` and returns a node the caller
 * owns one reference to, which may be `n` itself. NULL means no memory: `n`
 * is untouched and still the caller's. */
static hamt_node *hamt_node_put_mut(void *cx, hamt_node *n, unsigned depth,
                                    hamt_entry *e, int *added, hamt_entry **dead) {
    int edit = HAMT_EDITABLE(n);
    uint32_t bit, i;
    hamt_node *r;

    if (n->ncoll) {
        for (i = 0; i < n->ncoll; i++) {
            hamt_entry *old = (hamt_entry *)n->slot[i];
            if (!hamt_entry_key_eq(old, e->key, e->klen, e->utf8, e->hash)) continue;
            if (old == e || old->val == e->val) return n;
            if (edit) {
                n->slot[i] = hamt_entry_retain(e);
                *dead = old;
                return n;
            }
            r = hamt_node_with_slot(cx, n, i, e, HAMT_NO_SKIP);
            if (!r) return NULL;
            *dead = hamt_entry_retain(old);
            hamt_node_release(cx, n);
            return r;
        }
        /* A collision node is rare enough to grow by copying whether or not
         * it is ours. The copy holds every entry, so letting the old node
         * go releases nothing that matters. */
        r = hamt_node_coll_add(cx, n, e);
        if (!r) return NULL;
        *added = 1;
        hamt_node_release(cx, n);
        return r;
    }

    bit = HAMT_BIT(e->hash, depth);

    if (n->datamap & bit) {
        uint32_t di = hamt_popcnt32(n->datamap & (bit - 1));
        hamt_entry *old = (hamt_entry *)n->slot[di];
        hamt_node *sub;

        if (hamt_entry_key_eq(old, e->key, e->klen, e->utf8, e->hash)) {
            if (old == e || old->val == e->val) return n;
            if (edit) {
                n->slot[di] = hamt_entry_retain(e);
                *dead = old;
                return n;
            }
            r = hamt_node_with_slot(cx, n, di, e, HAMT_NO_SKIP);
            if (!r) return NULL;
            *dead = hamt_entry_retain(old);
            hamt_node_release(cx, n);
            return r;
        }

        /* Two keys at one position. The subtree that holds both takes its
         * own reference to each, so the entry leaving this node is not
         * displaced, only moved down. */
        sub = hamt_node_pair(cx, old, e, depth + 1);
        if (!sub) return NULL;
        if (edit) {
            hamt_entry_release(cx, hamt_node_entry_to_child_here(n, bit, sub));
            *added = 1;
            return n;
        }
        r = hamt_node_entry_to_child(cx, n, bit, sub);
        if (!r) { hamt_node_release(cx, sub); return NULL; }
        *added = 1;
        hamt_node_release(cx, n);
        return r;
    }

    if (n->nodemap & bit) {
        uint32_t ci = hamt_node_nslots(n) - 1 - hamt_popcnt32(n->nodemap & (bit - 1));
        hamt_node *child = (hamt_node *)n->slot[ci];
        hamt_node *sub;

        if (edit) {
            /* This node's reference to the child is the one handed down. */
            sub = hamt_node_put_mut(cx, child, depth + 1, e, added, dead);
            if (!sub) return NULL;
            n->slot[ci] = sub;
            return n;
        }

        /* A shared node's reference to its child is not ours to hand down,
         * so the child goes down with one of its own - which makes it
         * shared, and so copied rather than changed. */
        hamt_node_retain(child);
        sub = hamt_node_put_mut(cx, child, depth + 1, e, added, dead);
        if (!sub) { hamt_node_release(cx, child); return NULL; }
        if (sub == child) {
            hamt_node_release(cx, sub);
            return n;
        }
        r = hamt_node_with_slot(cx, n, ci, sub, ci);
        if (!r) {
            /* Everything below was a copy, so it can all be let go. */
            hamt_node_release(cx, sub);
            if (*dead) { hamt_entry_release(cx, *dead); *dead = NULL; }
            *added = 0;
            return NULL;
        }
        hamt_node_release(cx, n);
        return r;
    }

    r = edit ? hamt_node_add_entry_move(cx, n, bit, e)
             : hamt_node_add_entry(cx, n, bit, e);
    if (!r) return NULL;
    *added = 1;
    if (!edit) hamt_node_release(cx, n);
    return r;
}

/* Puts an entry into the trie at *rootp, which the caller owns one
 * reference to before and after; the pointer may change. The entry is
 * shared: the caller keeps its own reference.
 *
 * `*added` is 1 for a new key. `*dead` is the entry this one displaced, if
 * any, for the caller to release AFTER it has put the new root wherever it
 * keeps its root.
 *
 * 0, or -1 for no memory with everything as it was. */
static int hamt_map_put_mut(void *cx, hamt_node **rootp, hamt_entry *e,
                            int *added, hamt_entry **dead) {
    hamt_node *r;

    *added = 0;
    *dead  = NULL;
    if (!*rootp) {
        r = hamt_node_new(cx, 1);
        if (!r) return -1;
        r->datamap = HAMT_BIT(e->hash, 0);
        r->slot[0] = hamt_entry_retain(e);
        *added = 1;
        *rootp = r;
        return 0;
    }
    r = hamt_node_put_mut(cx, *rootp, 0, e, added, dead);
    if (!r) { *added = 0; return -1; }
    *rootp = r;
    return 0;
}

/* Takes over the caller's reference to `n` when it removes something
 * (HAMT_DEL_DONE) and returns what replaces it, which may be `n` itself, or
 * NULL for a root that is now empty. HAMT_DEL_ABSENT returns `n`, untouched
 * and still the caller's. HAMT_DEL_OOM returns NULL, likewise. */
static hamt_node *hamt_node_del_mut(void *cx, hamt_node *n, unsigned depth,
                                    const char *key, size_t klen, int utf8,
                                    uint64_t hash, int *status, hamt_entry **dead) {
    int edit = HAMT_EDITABLE(n);
    uint32_t bit, i;
    hamt_node *r;

    if (n->ncoll) {
        for (i = 0; i < n->ncoll; i++) {
            hamt_entry *old = (hamt_entry *)n->slot[i];
            if (!hamt_entry_key_eq(old, key, klen, utf8, hash)) continue;
            r = hamt_node_coll_drop(cx, n, i);
            if (!r) { *status = HAMT_DEL_OOM; return NULL; }
            *dead = hamt_entry_retain(old);
            *status = HAMT_DEL_DONE;
            hamt_node_release(cx, n);
            return r;
        }
        *status = HAMT_DEL_ABSENT;
        return n;
    }

    bit = HAMT_BIT(hash, depth);

    if (n->datamap & bit) {
        hamt_entry *old = (hamt_entry *)
            n->slot[hamt_popcnt32(n->datamap & (bit - 1))];

        if (!hamt_entry_key_eq(old, key, klen, utf8, hash)) {
            *status = HAMT_DEL_ABSENT;
            return n;
        }
        if (hamt_node_nslots(n) == 1) {             /* the last of a root */
            *dead = hamt_entry_retain(old);
            *status = HAMT_DEL_DONE;
            hamt_node_release(cx, n);
            return NULL;
        }
        if (edit) {
            r = hamt_node_drop_entry_move(cx, n, bit, dead);
            if (!r) { *status = HAMT_DEL_OOM; return NULL; }
            *status = HAMT_DEL_DONE;
            return r;
        }
        r = hamt_node_drop_entry(cx, n, bit);
        if (!r) { *status = HAMT_DEL_OOM; return NULL; }
        *dead = hamt_entry_retain(old);
        *status = HAMT_DEL_DONE;
        hamt_node_release(cx, n);
        return r;
    }

    if (n->nodemap & bit) {
        uint32_t ci = hamt_node_nslots(n) - 1 - hamt_popcnt32(n->nodemap & (bit - 1));
        hamt_node *child = (hamt_node *)n->slot[ci];
        hamt_node *sub;

        if (edit) {
            sub = hamt_node_del_mut(cx, child, depth + 1, key, klen, utf8, hash,
                                    status, dead);
            if (*status != HAMT_DEL_DONE) return *status == HAMT_DEL_ABSENT ? n : NULL;
            if (!sub) HAMT_FATAL("a node below the root came back empty");

            if (hamt_node_is_single(sub)) {
                /* The fold, where the node stands. The entry is kept alive
                 * by a reference of this node's before the child that held
                 * it is let go. */
                hamt_entry *up = hamt_entry_retain((hamt_entry *)sub->slot[0]);
                n->slot[ci] = sub;
                hamt_node_release(cx, hamt_node_child_to_entry_here(n, bit, up));
            }
            else n->slot[ci] = sub;
            return n;
        }

        hamt_node_retain(child);
        sub = hamt_node_del_mut(cx, child, depth + 1, key, klen, utf8, hash,
                                status, dead);
        if (*status == HAMT_DEL_OOM) { hamt_node_release(cx, child); return NULL; }
        if (*status == HAMT_DEL_ABSENT) { hamt_node_release(cx, child); return n; }
        if (!sub) HAMT_FATAL("a node below the root came back empty");

        r = hamt_node_is_single(sub)
          ? hamt_node_child_to_entry(cx, n, bit, (hamt_entry *)sub->slot[0])
          : hamt_node_with_slot(cx, n, ci, sub, HAMT_NO_SKIP);
        hamt_node_release(cx, sub);
        if (!r) {
            if (*dead) { hamt_entry_release(cx, *dead); *dead = NULL; }
            *status = HAMT_DEL_OOM;
            return NULL;
        }
        hamt_node_release(cx, n);
        return r;
    }

    *status = HAMT_DEL_ABSENT;
    return n;
}

/* Takes a key out of the trie at *rootp, which the caller owns one
 * reference to before and after; the pointer may change, and is NULL for a
 * trie that is now empty. `*dead` is the entry removed, for the caller to
 * release after it has put the new root wherever it keeps its root.
 *
 * HAMT_DEL_DONE, HAMT_DEL_ABSENT, or HAMT_DEL_OOM with everything as it
 * was. */
static int hamt_map_del_mut(void *cx, hamt_node **rootp, const char *key,
                            size_t klen, int utf8, uint64_t hash,
                            hamt_entry **dead) {
    int status = HAMT_DEL_ABSENT;
    hamt_node *r;

    *dead = NULL;
    if (!*rootp) return HAMT_DEL_ABSENT;
    r = hamt_node_del_mut(cx, *rootp, 0, key, klen, utf8, hash, &status, dead);
    if (status == HAMT_DEL_DONE) *rootp = r;
    return status;
}

#endif
