#ifndef FZ_MPHF_H
#define FZ_MPHF_H

#include "fz/fz_hash.h"
#include "fz/fz_format.h"

#define FZ_MPHF_MIN       8
#define FZ_MPHF_LAMBDA    4
#define FZ_MPHF_MAX_DISP  65536
#define FZ_MPHF_MAX_SEED  64

#define FZ_REDUCE(x, n) ((uint32_t)(((uint64_t)(uint32_t)(x) * (uint64_t)(n)) >> 32))

#define FZ_MPHF_OK        0
#define FZ_MPHF_EXHAUSTED (-1)
#define FZ_MPHF_NOMEM     (-2)
#define FZ_MPHF_DUP       (-3)

typedef struct {
    const char *k;
    uint32_t    len;
} fz_mphf_key;

static int fz_mphf_build(const fz_mphf_key *keys, uint32_t n,
                         uint32_t *disp, uint32_t r,
                         uint32_t *pos, uint32_t *seed_out) {
    uint32_t *bucket_of = NULL, *border = NULL, *bkeys = NULL;
    uint32_t *order = NULL, *sizes = NULL;
    unsigned char *taken = NULL;
    uint32_t *trial = NULL, *kf = NULL, *kg = NULL;
    uint32_t seed, i, b;
    int rc = FZ_MPHF_EXHAUSTED;

    if (!n || !r) return FZ_MPHF_OK;

    bucket_of = (uint32_t *)malloc((size_t)n * sizeof(uint32_t));
    border    = (uint32_t *)malloc(((size_t)r + 1) * sizeof(uint32_t));
    bkeys     = (uint32_t *)malloc((size_t)n * sizeof(uint32_t));
    order     = (uint32_t *)malloc((size_t)r * sizeof(uint32_t));
    sizes     = (uint32_t *)malloc((size_t)r * sizeof(uint32_t));
    taken     = (unsigned char *)malloc((size_t)n);
    trial     = (uint32_t *)malloc((size_t)n * sizeof(uint32_t));
    kf        = (uint32_t *)malloc((size_t)n * sizeof(uint32_t));
    kg        = (uint32_t *)malloc((size_t)n * sizeof(uint32_t));
    if (!bucket_of || !border || !bkeys || !order || !sizes || !taken || !trial
        || !kf || !kg) {
        rc = FZ_MPHF_NOMEM;
        goto done;
    }

    for (seed = 0; seed < FZ_MPHF_MAX_SEED; seed++) {
        uint32_t placed = 0;

        for (i = 0; i <= r; i++) border[i] = 0;
        for (i = 0; i < n; i++) {
            uint64_t h  = fz_hash(keys[i].k, keys[i].len, seed);
            uint64_t h2 = fz_remix(h);
            bucket_of[i] = FZ_REDUCE(h >> 32, r);
            kf[i] = (uint32_t)h;
            kg[i] = (uint32_t)h2 | 1u;
            border[bucket_of[i] + 1]++;
        }
        for (i = 0; i < r; i++) sizes[i] = border[i + 1];
        for (i = 0; i < r; i++) border[i + 1] += border[i];
        {
            uint32_t *cur = (uint32_t *)malloc((size_t)r * sizeof(uint32_t));
            if (!cur) { rc = FZ_MPHF_NOMEM; goto done; }
            for (i = 0; i < r; i++) cur[i] = border[i];
            for (i = 0; i < n; i++) bkeys[cur[bucket_of[i]]++] = i;
            free(cur);
        }

        {
            uint32_t maxsz = 0, *cnt, *at;
            for (i = 0; i < r; i++) if (sizes[i] > maxsz) maxsz = sizes[i];
            cnt = (uint32_t *)malloc(((size_t)maxsz + 2) * sizeof(uint32_t));
            at  = (uint32_t *)malloc(((size_t)maxsz + 2) * sizeof(uint32_t));
            if (!cnt || !at) { free(cnt); free(at); rc = FZ_MPHF_NOMEM; goto done; }
            for (i = 0; i <= maxsz + 1; i++) cnt[i] = 0;
            for (i = 0; i < r; i++) cnt[sizes[i]]++;

            at[maxsz] = 0;
            for (i = maxsz; i > 0; i--) at[i - 1] = at[i] + cnt[i];
            for (i = 0; i < r; i++) order[at[sizes[i]]++] = i;
            free(cnt); free(at);
        }

        memset(taken, 0, (size_t)n);
        placed = 0;

        for (b = 0; b < r; b++) {
            uint32_t bi = order[b];
            uint32_t from = border[bi], to = border[bi + 1];
            uint32_t cnt = to - from;
            uint32_t d;
            int ok = 0;

            if (!cnt) { disp[bi] = 0; placed++; continue; }

            for (d = 0; d < FZ_MPHF_MAX_DISP; d++) {
                uint32_t j, k;
                uint32_t d1 = d & 0xFFu, d2 = d >> 8;
                ok = 1;
                for (j = 0; j < cnt; j++) {
                    uint32_t ki = bkeys[from + j];
                    uint32_t p  = (uint32_t)((kf[ki] + d1 * kg[ki] + d2) % n);
                    if (taken[p]) { ok = 0; break; }

                    for (k = 0; k < j; k++) if (trial[k] == p) { ok = 0; break; }
                    if (!ok) break;
                    trial[j] = p;
                }
                if (ok) {
                    for (j = 0; j < cnt; j++) {
                        taken[trial[j]] = 1;
                        pos[bkeys[from + j]] = trial[j];
                    }
                    disp[bi] = d;
                    placed++;
                    break;
                }
            }
            if (!ok) break;
        }

        if (placed == r) {
            *seed_out = seed;
            rc = FZ_MPHF_OK;
            goto done;
        }
    }

done:
    free(bucket_of); free(border); free(bkeys);
    free(order); free(sizes); free(taken); free(trial);
    free(kf); free(kg);
    return rc;
}

static uint32_t fz_mphf_pos(const char *k, uint32_t len, uint32_t n,
                            uint32_t r, uint32_t seed, const uint32_t *disp) {
    uint64_t h  = fz_hash(k, len, seed);
    uint64_t h2 = fz_remix(h);
    uint32_t b  = FZ_REDUCE(h >> 32, r);
    uint32_t f  = (uint32_t)h;
    uint32_t g  = (uint32_t)h2 | 1u;
    uint32_t d  = disp[b];
    return (uint32_t)((f + (d & 0xFFu) * g + (d >> 8)) % n);
}

#define FZ_NOTFOUND 0xFFFFFFFFu

static uint32_t fz_hash_find(const unsigned char *b, uint32_t len,
                             uint32_t node, const char *key, uint32_t klen) {
    uint32_t n, lookup, i;

    if (node + 8 > len) return FZ_NOTFOUND;
    n      = fz_rd_u32(b + node);
    lookup = fz_rd_u32(b + node + 4);
    if (!n) return FZ_NOTFOUND;

    if (lookup) {
        uint32_t r, seed;

        if (lookup + 12 > len || (lookup & (FZ_ALIGN - 1))) return FZ_NOTFOUND;
        r    = fz_rd_u32(b + lookup);
        seed = fz_rd_u32(b + lookup + 4);

        if (!r || r > (len - lookup - 8) / 4) return FZ_NOTFOUND;
        uint64_t h    = fz_hash(key, klen, seed);
        uint64_t h2   = fz_remix(h);
        uint32_t bkt, d, pos, koff, kl;
        if (!r) return FZ_NOTFOUND;
        bkt = FZ_REDUCE(h >> 32, r);
        if (bkt >= r) return FZ_NOTFOUND;
        d   = fz_rd_u32(b + lookup + 8 + bkt * 4);
        pos = (uint32_t)(((uint32_t)h + (d & 0xFFu) * ((uint32_t)h2 | 1u)
                          + (d >> 8)) % n);

        if (pos >= n || n > (len - node - 8) / 8) return FZ_NOTFOUND;
        koff = fz_rd_u32(b + node + 8 + pos * 4);
        if (koff + 8 > len || (koff & (FZ_ALIGN - 1))) return FZ_NOTFOUND;
        kl = fz_rd_u32(b + koff);

        if (kl != klen || memcmp(b + koff + 8, key, klen) != 0)
            return FZ_NOTFOUND;
        return fz_rd_u32(b + node + 8 + n * 4 + pos * 4);
    }

    for (i = 0; i < n; i++) {
        uint32_t koff;
        uint32_t kl;
        if (n > (len - node - 8) / 8) return FZ_NOTFOUND;
        koff = fz_rd_u32(b + node + 8 + i * 4);
        if (koff + 8 > len || (koff & (FZ_ALIGN - 1))) return FZ_NOTFOUND;
        kl = fz_rd_u32(b + koff);
        if (kl == klen && memcmp(b + koff + 8, key, klen) == 0)
            return fz_rd_u32(b + node + 8 + n * 4 + i * 4);
    }
    return FZ_NOTFOUND;
}

#endif
