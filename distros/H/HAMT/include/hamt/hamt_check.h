#ifndef HAMT_CHECK_H
#define HAMT_CHECK_H

/* Walks a whole trie and says whether it is one this library could have
 * built. For the tests: it visits every node, so it costs what the map
 * holds, and nothing in the library calls it.
 *
 * 0 when every rule holds. Otherwise the number of the first rule that did
 * not, from the list below, so a failure names what broke. */

#define HAMT_CHK_OK              0
#define HAMT_CHK_REFCNT          1   /* a node or entry with a count of zero */
#define HAMT_CHK_MAPS_OVERLAP    2   /* a position in both maps */
#define HAMT_CHK_EMPTY_NODE      3   /* a node holding nothing */
#define HAMT_CHK_SINGLE_BELOW    4   /* one entry, no children, not the root */
#define HAMT_CHK_COLL_SHALLOW    5   /* a collision node above depth 12 */
#define HAMT_CHK_COLL_MAPS       6   /* a collision node with a map bit set */
#define HAMT_CHK_COLL_SMALL      7   /* a collision node with fewer than two */
#define HAMT_CHK_COLL_DUP        8   /* two equal keys in a collision node */
#define HAMT_CHK_TOO_DEEP        9   /* an indexing node at depth 12 */
#define HAMT_CHK_ENTRY_PATH     10   /* an entry not where its hash puts it */
#define HAMT_CHK_NULL_SLOT      11   /* a slot holding nothing */
#define HAMT_CHK_COUNT          12   /* the entries do not total the count */
#define HAMT_CHK_ORDER          13   /* entries or children out of order */

/* The hash bits that every entry under a node at this depth must share. */
static uint64_t hamt_chk_prefix_mask(unsigned depth) {
    unsigned bits = HAMT_BITS * depth;
    return bits >= 64 ? ~(uint64_t)0 : (((uint64_t)1 << bits) - 1);
}

static int hamt_node_check(const hamt_node *n, unsigned depth, uint64_t prefix,
                           size_t *count) {
    uint32_t nd, N, i, pos;
    uint64_t pmask = hamt_chk_prefix_mask(depth);

    if (!n) return HAMT_CHK_NULL_SLOT;
    if (n->refcnt == 0) return HAMT_CHK_REFCNT;

    if (n->ncoll) {
        if (depth < HAMT_MAX_DEPTH) return HAMT_CHK_COLL_SHALLOW;
        if (n->datamap || n->nodemap) return HAMT_CHK_COLL_MAPS;
        if (n->ncoll < 2) return HAMT_CHK_COLL_SMALL;
        for (i = 0; i < n->ncoll; i++) {
            const hamt_entry *e = (const hamt_entry *)n->slot[i];
            uint32_t j;
            if (!e) return HAMT_CHK_NULL_SLOT;
            if (e->refcnt == 0) return HAMT_CHK_REFCNT;
            if ((e->hash & pmask) != prefix) return HAMT_CHK_ENTRY_PATH;
            for (j = 0; j < i; j++) {
                const hamt_entry *f = (const hamt_entry *)n->slot[j];
                if (hamt_entry_key_eq(f, e->key, e->klen, e->utf8, e->hash))
                    return HAMT_CHK_COLL_DUP;
            }
        }
        *count += n->ncoll;
        return HAMT_CHK_OK;
    }

    if (depth >= HAMT_MAX_DEPTH) return HAMT_CHK_TOO_DEEP;
    if (n->datamap & n->nodemap) return HAMT_CHK_MAPS_OVERLAP;

    nd = hamt_popcnt32(n->datamap);
    N  = nd + hamt_popcnt32(n->nodemap);
    if (N == 0) return HAMT_CHK_EMPTY_NODE;
    if (depth > 0 && hamt_node_is_single(n)) return HAMT_CHK_SINGLE_BELOW;

    /* Entries: the i-th slot must hold the entry for the i-th set bit of
     * the datamap, lowest first. */
    i = 0;
    for (pos = 0; pos < 32; pos++) {
        const hamt_entry *e;
        if (!(n->datamap & ((uint32_t)1 << pos))) continue;
        e = (const hamt_entry *)n->slot[i++];
        if (!e) return HAMT_CHK_NULL_SLOT;
        if (e->refcnt == 0) return HAMT_CHK_REFCNT;
        if ((e->hash & pmask) != prefix) return HAMT_CHK_ENTRY_PATH;
        if (HAMT_IDX(e->hash, depth) != pos) return HAMT_CHK_ORDER;
    }
    *count += nd;

    /* Children: the last slot holds the child for the lowest set bit of the
     * nodemap, and they run backwards from there. Each child is checked
     * against the prefix its position gives it, so a child in the wrong
     * slot fails on its own entries. */
    i = N;
    for (pos = 0; pos < 32; pos++) {
        int rc;
        if (!(n->nodemap & ((uint32_t)1 << pos))) continue;
        rc = hamt_node_check((const hamt_node *)n->slot[--i], depth + 1,
                             prefix | ((uint64_t)pos << (HAMT_BITS * depth)),
                             count);
        if (rc) return rc;
    }
    return HAMT_CHK_OK;
}

static int hamt_map_check(const hamt_node *root, size_t count) {
    size_t seen = 0;
    int rc;
    if (!root) return count == 0 ? HAMT_CHK_OK : HAMT_CHK_COUNT;
    rc = hamt_node_check(root, 0, 0, &seen);
    if (rc) return rc;
    return seen == count ? HAMT_CHK_OK : HAMT_CHK_COUNT;
}

#endif
