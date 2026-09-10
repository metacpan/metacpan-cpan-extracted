#ifndef FZ_READ_H
#define FZ_READ_H

#include "fz/fz_format.h"
#include "fz/fz_mphf.h"

#define FZ_LEAF    1
#define FZ_BRANCH  2
#define FZ_ABSENT  0
#define FZ_BADNODE (-1)

static int fz_handle_ok(const unsigned char *b, uint32_t len, uint32_t slot) {
    uint32_t tag = FZ_SLOT_TAG(slot);
    uint32_t off = FZ_SLOT_OFF(slot);
    uint32_t n;

    if (tag > FZ_T_MAX) return 0;
    if (tag == FZ_T_UNDEF || tag == FZ_T_TRUE || tag == FZ_T_FALSE) return 1;
    if (off < FZ_HEADER_SIZE || off >= len) return 0;
    if (off & (FZ_ALIGN - 1))               return 0;

    switch (tag) {
    case FZ_T_INT: case FZ_T_UINT: case FZ_T_NUM:
        return off + 8 <= len;
    case FZ_T_STR:
        if (off + 8 > len) return 0;
        n = fz_rd_u32(b + off);
        return n <= len && off + 8 + n + 1 <= len;
    case FZ_T_ARRAY:
        if (off + 4 > len) return 0;
        n = fz_rd_u32(b + off);
        return n <= (len - off) / 4 && off + 4 + n * 4 <= len;
    case FZ_T_HASH:
        if (off + 8 > len) return 0;
        n = fz_rd_u32(b + off);
        return n <= (len - off) / 8 && off + 8 + n * 8 <= len;
    }
    return 0;
}

static int fz_is_branch(uint32_t slot) {
    uint32_t t = FZ_SLOT_TAG(slot);
    return t == FZ_T_HASH || t == FZ_T_ARRAY;
}

static uint32_t fz_count(const unsigned char *b, uint32_t len, uint32_t slot) {
    uint32_t off = FZ_SLOT_OFF(slot);
    if (!fz_is_branch(slot) || off + 4 > len) return 0;
    return fz_rd_u32(b + off);
}

static int fz_probe(const unsigned char *b, uint32_t len, uint32_t node,
                    const char *key, uint32_t klen, uint32_t *out) {
    uint32_t slot;
    if (FZ_SLOT_TAG(node) != FZ_T_HASH) return FZ_ABSENT;
    slot = fz_hash_find(b, len, FZ_SLOT_OFF(node), key, klen);
    if (slot == FZ_NOTFOUND) return FZ_ABSENT;

    if (!fz_handle_ok(b, len, slot)) return FZ_ABSENT;
    if (out) *out = slot;
    return fz_is_branch(slot) ? FZ_BRANCH : FZ_LEAF;
}

static int fz_at(const unsigned char *b, uint32_t len, uint32_t node,
                 uint32_t i, uint32_t *out) {
    uint32_t off = FZ_SLOT_OFF(node), n;
    if (FZ_SLOT_TAG(node) != FZ_T_ARRAY || off + 4 > len) return FZ_ABSENT;
    n = fz_rd_u32(b + off);
    if (i >= n) return FZ_ABSENT;
    {
        uint32_t slot = fz_rd_u32(b + off + 4 + i * 4);
        if (!fz_handle_ok(b, len, slot)) return FZ_ABSENT;
        if (out) *out = slot;
        return fz_is_branch(slot) ? FZ_BRANCH : FZ_LEAF;
    }
}

static int fz_key_at(const unsigned char *b, uint32_t len, uint32_t node,
                     uint32_t i, const char **kp, uint32_t *klen, int *utf8) {
    uint32_t off = FZ_SLOT_OFF(node), n, koff;
    if (FZ_SLOT_TAG(node) != FZ_T_HASH || off + 8 > len) return 0;
    n = fz_rd_u32(b + off);
    if (i >= n) return 0;
    koff = fz_rd_u32(b + off + 8 + i * 4);
    if (koff + 8 > len) return 0;
    *klen = fz_rd_u32(b + koff);
    if (koff + 8 + *klen + 1 > len) return 0;
    *kp   = (const char *)(b + koff + 8);
    if (utf8) *utf8 = b[koff + 4];
    return 1;
}

static uint32_t fz_val_at(const unsigned char *b, uint32_t len, uint32_t node,
                          uint32_t i) {
    uint32_t off = FZ_SLOT_OFF(node);
    uint32_t n   = fz_rd_u32(b + off);
    if (i >= n) return 0;
    return fz_rd_u32(b + off + 8 + n * 4 + i * 4);
}

static const char *fz_str_at(const unsigned char *b, uint32_t len,
                             uint32_t slot, uint32_t *slen, int *utf8) {
    uint32_t off = FZ_SLOT_OFF(slot);
    if (FZ_SLOT_TAG(slot) != FZ_T_STR || !fz_handle_ok(b, len, slot))
        return NULL;
    if (slen) *slen = fz_rd_u32(b + off);
    if (utf8) *utf8 = b[off + 4] ? 1 : 0;

    return (const char *)(b + off + 8);
}

static int fz_i64_at(const unsigned char *b, uint32_t len, uint32_t slot,
                     int64_t *out) {
    uint32_t off = FZ_SLOT_OFF(slot);
    uint64_t v = 0;
    int i;
    if (FZ_SLOT_TAG(slot) != FZ_T_INT || !fz_handle_ok(b, len, slot)) return 0;
    for (i = 7; i >= 0; i--) v = (v << 8) | (uint64_t)b[off + i];
    if (out) *out = (int64_t)v;
    return 1;
}

static int fz_u64_at(const unsigned char *b, uint32_t len, uint32_t slot,
                     uint64_t *out) {
    uint32_t off = FZ_SLOT_OFF(slot);
    uint64_t v = 0;
    int i;
    if (FZ_SLOT_TAG(slot) != FZ_T_UINT || !fz_handle_ok(b, len, slot)) return 0;
    for (i = 7; i >= 0; i--) v = (v << 8) | (uint64_t)b[off + i];
    if (out) *out = v;
    return 1;
}

static int fz_f64_at(const unsigned char *b, uint32_t len, uint32_t slot,
                     double *out) {
    uint32_t off = FZ_SLOT_OFF(slot);
    double d;
    if (FZ_SLOT_TAG(slot) != FZ_T_NUM || !fz_handle_ok(b, len, slot)) return 0;

    memcpy(&d, b + off, sizeof d);
    if (out) *out = d;
    return 1;
}

typedef void (*fz_leaf_cb)(void *ud, const char **segs, const uint32_t *lens,
                           int depth, uint32_t slot);

static int fz_walk_rec(const unsigned char *b, uint32_t len, uint32_t node,
                       const char **segs, uint32_t *lens, char *idxbuf,
                       int depth, fz_leaf_cb cb, void *ud, uint32_t *budget) {
    uint32_t n, i;
    if (depth >= FZ_MAX_DEPTH) return 0;
    if (!*budget) return 0;
    (*budget)--;
    if (!fz_handle_ok(b, len, node))  return 0;

    if (!fz_is_branch(node)) { cb(ud, segs, lens, depth, node); return 1; }

    n = fz_count(b, len, node);
    if (FZ_SLOT_TAG(node) == FZ_T_HASH) {
        for (i = 0; i < n; i++) {
            const char *k; uint32_t kl;
            if (!fz_key_at(b, len, node, i, &k, &kl, NULL)) continue;
            segs[depth] = k; lens[depth] = kl;
            if (!fz_walk_rec(b, len, fz_val_at(b, len, node, i),
                             segs, lens, idxbuf, depth + 1, cb, ud, budget))
                return 0;
        }
    }
    else {
        uint32_t off = FZ_SLOT_OFF(node);
        for (i = 0; i < n; i++) {
            char *slot_buf = idxbuf + depth * 12;
            uint32_t l = 0, v = i;
            char tmp[12];
            int t = 0;
            do { tmp[t++] = (char)('0' + (v % 10)); v /= 10; } while (v);
            while (t) slot_buf[l++] = tmp[--t];
            segs[depth] = slot_buf; lens[depth] = l;
            if (!fz_walk_rec(b, len, fz_rd_u32(b + off + 4 + i * 4),
                             segs, lens, idxbuf, depth + 1, cb, ud, budget))
                return 0;
        }
    }
    return 1;
}

static uint32_t fz_flat_find(const unsigned char *b, uint32_t len,
                             const char *key, uint32_t klen) {
    uint32_t off = fz_rd_u32(b + FZ_H_FLATIDX);
    uint32_t n, r, seed, bkt, d, pos, koff, kl;
    uint64_t h, h2;

    if (!off || off + 12 > len || (off & (FZ_ALIGN - 1))) return FZ_NOTFOUND;
    n    = fz_rd_u32(b + off);
    r    = fz_rd_u32(b + off + 4);
    seed = fz_rd_u32(b + off + 8);
    if (!n || !r) return FZ_NOTFOUND;

    {
        uint32_t room = len - off - 12;
        if (r > room / 4) return FZ_NOTFOUND;
        room -= r * 4;
        if (n > room / 8) return FZ_NOTFOUND;
    }

    h   = fz_hash(key, klen, seed);
    h2  = fz_remix(h);
    bkt = FZ_REDUCE(h >> 32, r);
    d   = fz_rd_u32(b + off + 12 + bkt * 4);
    pos = (uint32_t)(((uint32_t)h + (d & 0xFFu) * ((uint32_t)h2 | 1u)
                      + (d >> 8)) % n);

    koff = fz_rd_u32(b + off + 12 + r * 4 + pos * 4);
    if (koff + 8 > len) return FZ_NOTFOUND;
    kl = fz_rd_u32(b + koff);

    if (kl != klen || memcmp(b + koff + 8, key, klen) != 0) return FZ_NOTFOUND;
    {
        uint32_t slot = fz_rd_u32(b + off + 12 + r * 4 + n * 4 + pos * 4);
        return fz_handle_ok(b, len, slot) ? slot : FZ_NOTFOUND;
    }
}

static int fz_has_flat(const unsigned char *b) {
    return (fz_rd_u32(b + FZ_H_FLAGS) & FZ_FLAG_FLATINDEX) ? 1 : 0;
}

static uint32_t fz_path_find(const unsigned char *b, uint32_t len,
                             uint32_t from, const char *p, uint32_t plen,
                             char sep) {
    uint32_t cur = from, slot = 0, i, start;

    if (sep == '.' && fz_has_flat(b) && from == fz_rd_u32(b + FZ_H_ROOT)) {
        uint32_t got = fz_flat_find(b, len, p, plen);
        if (got != FZ_NOTFOUND) return got;
    }

    for (i = 0, start = 0; i <= plen; i++) {
        if (i == plen || p[i] == sep) {
            if (fz_probe(b, len, cur, p + start, i - start, &slot) == FZ_ABSENT)
                return FZ_NOTFOUND;
            cur = slot;
            start = i + 1;
        }
    }
    return cur;
}

#endif
