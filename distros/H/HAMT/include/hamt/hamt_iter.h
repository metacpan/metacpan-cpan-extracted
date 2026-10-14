#ifndef HAMT_ITER_H
#define HAMT_ITER_H

/* Every entry of a trie, once each. A node's own entries come first, in
 * slot order, and then each child in slot order, so the order is the same
 * every time for the same trie and two tries of the same shape are walked
 * in step.
 *
 * The iterator borrows the root. Whoever walks holds a reference to it for
 * as long as the walk lasts; since nothing reachable from a root ever
 * changes, nothing else can go wrong underneath it. */

typedef struct hamt_iter {
    const hamt_node *node[HAMT_MAX_DEPTH + 1];
    uint32_t         pos[HAMT_MAX_DEPTH + 1];
    int              depth;      /* -1 when there is nothing left */
} hamt_iter;

static void hamt_iter_init(hamt_iter *it, const hamt_node *root) {
    it->depth = root ? 0 : -1;
    it->node[0] = root;
    it->pos[0]  = 0;
}

static hamt_entry *hamt_iter_next(hamt_iter *it) {
    while (it->depth >= 0) {
        const hamt_node *n = it->node[it->depth];
        uint32_t p = it->pos[it->depth];

        if (p < hamt_node_ndata(n)) {
            it->pos[it->depth] = p + 1;
            return (hamt_entry *)n->slot[p];
        }
        if (p < hamt_node_nslots(n)) {
            it->pos[it->depth] = p + 1;
            it->depth++;
            it->node[it->depth] = (const hamt_node *)n->slot[p];
            it->pos[it->depth]  = 0;
            continue;
        }
        it->depth--;
    }
    return NULL;
}

#endif
