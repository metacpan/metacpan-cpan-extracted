#include "fm.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ── big-endian read helpers ──────────────────────────────────────────────── */
#define RD_U16(p) ((uint16_t)( \
    (unsigned)((const uint8_t *)(p))[0] << 8 | \
    (unsigned)((const uint8_t *)(p))[1]))
#define RD_S16(p) ((int16_t)RD_U16(p))
#define RD_U32(p) ((uint32_t)( \
    (uint32_t)((const uint8_t *)(p))[0] << 24 | \
    (uint32_t)((const uint8_t *)(p))[1] << 16 | \
    (uint32_t)((const uint8_t *)(p))[2] <<  8 | \
    (uint32_t)((const uint8_t *)(p))[3]))

/* ── locate a named table; returns offset into buf, or 0 if absent ──────── */
static uint32_t
find_table(const uint8_t *buf, size_t bufsz, const char *tag)
{
    uint16_t i, ntab;
    const uint8_t *p;
    if (bufsz < 12) return 0;
    ntab = RD_U16(buf + 4);
    p    = buf + 12;
    for (i = 0; i < ntab; i++, p += 16) {
        if ((size_t)(p + 16 - buf) > bufsz) break;
        if (memcmp(p, tag, 4) == 0)
            return RD_U32(p + 8);   /* table offset field */
    }
    return 0;
}

/* ── shared: (codepoint, glyph) pair for sorting ────────────────────────── */
typedef struct { uint32_t cp; uint16_t glyph; } cp_pair_t;

static int cp_cmp(const void *a, const void *b) {
    uint32_t ca = ((const cp_pair_t *)a)->cp;
    uint32_t cb = ((const cp_pair_t *)b)->cp;
    return (ca > cb) - (ca < cb);
}

/* ── cmap format 12: sequential groups → sorted (cp, glyph) arrays ──────── */
static int
parse_cmap12(const uint8_t *sub, size_t sublen,
             uint32_t **out_cp, uint16_t **out_glyph, int *out_n)
{
    uint32_t ngroups, g, total;
    const uint8_t *p;
    cp_pair_t *pairs;
    int n = 0;

    if (sublen < 16) return 0;
    ngroups = RD_U32(sub + 12);
    if (ngroups == 0 || 16 + ngroups * 12 > (uint32_t)sublen) return 0;

    /* count total codepoints to pre-allocate */
    total = 0;
    p = sub + 16;
    for (g = 0; g < ngroups; g++, p += 12) {
        uint32_t scp = RD_U32(p), ecp = RD_U32(p + 4);
        if (ecp >= scp) total += ecp - scp + 1;
    }
    if (total == 0 || total > 0x200000) return 0;  /* sanity: ≤ 2M codepoints */

    pairs = (cp_pair_t *)malloc(total * sizeof(cp_pair_t));
    if (!pairs) return 0;

    p = sub + 16;
    for (g = 0; g < ngroups; g++, p += 12) {
        uint32_t scp   = RD_U32(p);
        uint32_t ecp   = RD_U32(p + 4);
        uint32_t sglyph = RD_U32(p + 8);
        uint32_t cp;
        for (cp = scp; cp <= ecp; cp++) {
            uint32_t glyph = sglyph + (cp - scp);
            if (glyph == 0 || glyph > 0xFFFF) continue;
            pairs[n].cp    = cp;
            pairs[n].glyph = (uint16_t)glyph;
            n++;
        }
    }

    if (n == 0) { free(pairs); return 0; }
    qsort(pairs, (size_t)n, sizeof(cp_pair_t), cp_cmp);

    {
        uint32_t *cps    = (uint32_t *)malloc((size_t)n * sizeof(uint32_t));
        uint16_t *glyphs = (uint16_t *)malloc((size_t)n * sizeof(uint16_t));
        int j;
        if (!cps || !glyphs) { free(cps); free(glyphs); free(pairs); return 0; }
        for (j = 0; j < n; j++) { cps[j] = pairs[j].cp; glyphs[j] = pairs[j].glyph; }
        free(pairs);
        *out_cp = cps; *out_glyph = glyphs; *out_n = n;
    }
    return 1;
}

/* ── cmap format 4: expand segments → sorted (cp, glyph) arrays ─────────── */
static int
parse_cmap4(const uint8_t *sub, size_t sublen,
            uint32_t **out_cp, uint16_t **out_glyph, int *out_n)
{
    uint16_t segCount, i;
    uint32_t n_glyph_arr;
    const uint8_t *endArr, *startArr, *deltaArr, *rangeArr, *glyphArr;
    cp_pair_t *pairs;
    int n = 0, cap;

    if (sublen < 14) return 0;
    segCount = RD_U16(sub + 6) >> 1;
    if (segCount == 0 || (uint32_t)(14 + segCount * 8 + 2) > (uint32_t)sublen)
        return 0;

    endArr      = sub  + 14;
    startArr    = endArr  + segCount * 2 + 2;  /* +2 = reservedPad */
    deltaArr    = startArr  + segCount * 2;
    rangeArr    = deltaArr  + segCount * 2;
    glyphArr    = rangeArr  + segCount * 2;
    n_glyph_arr = (uint32_t)((sub + sublen - glyphArr) / 2);

    cap   = (int)(segCount * 64 + 64);
    pairs = (cp_pair_t *)malloc((size_t)cap * sizeof(cp_pair_t));
    if (!pairs) return 0;

    for (i = 0; i < segCount; i++) {
        uint16_t ecp = RD_U16(endArr   + i * 2);
        uint16_t scp = RD_U16(startArr + i * 2);
        int16_t  del = RD_S16(deltaArr + i * 2);
        uint16_t rng = RD_U16(rangeArr + i * 2);
        uint32_t cp;

        if (ecp == 0xFFFF) break;   /* terminator segment */

        for (cp = scp; cp <= ecp; cp++) {
            uint16_t glyph;
            if (rng != 0) {
                /* pointer arithmetic relative to &rangeArr[i] */
                int32_t idx = (int32_t)i + (int32_t)(rng >> 1)
                            + (int32_t)(cp - scp) - (int32_t)segCount;
                if (idx < 0 || (uint32_t)idx >= n_glyph_arr) continue;
                glyph = RD_U16(glyphArr + (uint32_t)idx * 2);
                if (glyph == 0) continue;
                glyph = (uint16_t)((glyph + (uint16_t)del) & 0xFFFF);
            } else {
                glyph = (uint16_t)((cp + (uint32_t)(uint16_t)del) & 0xFFFF);
            }
            if (glyph == 0) continue;

            if (n >= cap) {
                cp_pair_t *tp;
                cap = cap * 2;
                tp = (cp_pair_t *)realloc(pairs, (size_t)cap * sizeof(cp_pair_t));
                if (!tp) { free(pairs); return 0; }
                pairs = tp;
            }
            pairs[n].cp    = cp;
            pairs[n].glyph = glyph;
            n++;
        }
    }

    if (n == 0) { free(pairs); return 0; }

    qsort(pairs, (size_t)n, sizeof(cp_pair_t), cp_cmp);

    /* split into parallel arrays */
    {
        uint32_t *cps    = (uint32_t *)malloc((size_t)n * sizeof(uint32_t));
        uint16_t *glyphs = (uint16_t *)malloc((size_t)n * sizeof(uint16_t));
        int j;
        if (!cps || !glyphs) { free(cps); free(glyphs); free(pairs); return 0; }
        for (j = 0; j < n; j++) {
            cps[j]    = pairs[j].cp;
            glyphs[j] = pairs[j].glyph;
        }
        free(pairs);
        *out_cp    = cps;
        *out_glyph = glyphs;
        *out_n     = n;
    }
    return 1;
}

/* ── kern table: format 0 pairs → sorted (packed_glyph_pair, value) ──────── */
static void
parse_kern(const uint8_t *buf, size_t bufsz, uint32_t off_kern, fm_font_t *fm)
{
    uint32_t off, stab_off;
    uint16_t i, tbl_ver, ntab, nPairs;
    uint32_t *pairs = NULL;
    int16_t  *vals  = NULL;
    int n = 0, cap = 0;

    if (!off_kern || off_kern + 4 > bufsz) return;

    tbl_ver = RD_U16(buf + off_kern);   /* 0 = standard TTF, 1 = Apple (Fixed 1.0) */

    if (tbl_ver == 0) {
        /* Standard TTF kern: uint16 version=0, uint16 nTables */
        ntab     = RD_U16(buf + off_kern + 2);
        stab_off = off_kern + 4;
    } else if (tbl_ver == 1) {
        /* Apple extended kern: Fixed version=0x00010000, uint32 nTables */
        if (off_kern + 8 > bufsz) return;
        ntab     = (uint16_t)RD_U32(buf + off_kern + 4);
        stab_off = off_kern + 8;
    } else {
        return;
    }

    off = stab_off;
    for (i = 0; i < ntab; i++) {
        uint16_t subtab_len, coverage, sub_fmt, np, j;
        uint32_t sub_data;

        if (off + 6 > bufsz) break;

        if (tbl_ver == 0) {
            /* standard: uint16 version, uint16 length, uint16 coverage */
            subtab_len = RD_U16(buf + off + 2);
            coverage   = RD_U16(buf + off + 4);
            sub_data   = off + 6;
        } else {
            /* Apple: uint32 length, uint16 coverage, uint16 tupleIndex */
            subtab_len = (uint16_t)RD_U32(buf + off);
            coverage   = RD_U16(buf + off + 4);
            sub_data   = off + 8;
        }

        sub_fmt = (uint16_t)(coverage >> 8);  /* format in high byte */
        /* low byte: bit 0 = horizontal, bit 2 = cross-stream */
        if (sub_fmt != 0 || !(coverage & 0x01) || (coverage & 0x04)) {
            off += subtab_len; continue;
        }

        if (sub_data + 8 > bufsz) break;
        np = RD_U16(buf + sub_data);
        sub_data += 8;  /* skip nPairs, searchRange, entrySelector, rangeShift */

        if ((uint32_t)sub_data + (uint32_t)np * 6 > bufsz) break;

        /* grow buffers */
        if (n + np > cap) {
            uint32_t *tp; int16_t *tv;
            cap = (n + np) * 2 + 16;
            tp = (uint32_t *)realloc(pairs, (size_t)cap * sizeof(uint32_t));
            tv = (int16_t  *)realloc(vals,  (size_t)cap * sizeof(int16_t));
            if (!tp || !tv) { free(tp ? tp : pairs); free(tv ? tv : vals); return; }
            pairs = tp; vals = tv;
        }

        for (j = 0; j < np; j++) {
            uint32_t key = ((uint32_t)RD_U16(buf + sub_data + j * 6)     << 16)
                         |  (uint32_t)RD_U16(buf + sub_data + j * 6 + 2);
            int16_t  val = RD_S16(buf + sub_data + j * 6 + 4);
            pairs[n] = key;
            vals[n]  = val;
            n++;
        }

        off += subtab_len;
    }

    if (n == 0) { free(pairs); free(vals); return; }

    /* Sort by key (kern format 0 is already sorted per subtable,
       but multiple subtables may be interleaved) */
    {
        int a, b;  /* insertion sort: n is typically small (< 1000) */
        for (a = 1; a < n; a++) {
            uint32_t kp = pairs[a]; int16_t kv = vals[a];
            for (b = a - 1; b >= 0 && pairs[b] > kp; b--) {
                pairs[b+1] = pairs[b]; vals[b+1] = vals[b];
            }
            pairs[b+1] = kp; vals[b+1] = kv;
        }
    }

    fm->kern_pairs  = pairs;
    fm->kern_values = vals;
    fm->n_kern      = n;
}

/* ── GPOS PairPos kerning ─────────────────────────────────────────────────── */

typedef struct { uint32_t key; int16_t val; } gkpair_t;
typedef struct { gkpair_t *p; int n, cap; } gkacc_t;

static int gkpair_cmp(const void *a, const void *b) {
    uint32_t ka = ((const gkpair_t *)a)->key;
    uint32_t kb = ((const gkpair_t *)b)->key;
    return (ka > kb) - (ka < kb);
}

static void gk_add(gkacc_t *a, uint16_t g1, uint16_t g2, int16_t val) {
    gkpair_t *np;
    int nc;
    if (!val) return;
    if (a->n >= a->cap) {
        nc = a->cap ? a->cap * 2 : 128;
        np = (gkpair_t *)realloc(a->p, (size_t)nc * sizeof(*np));
        if (!np) return;
        a->p = np; a->cap = nc;
    }
    a->p[a->n].key = ((uint32_t)g1 << 16) | g2;
    a->p[a->n].val = val;
    a->n++;
}

/* ValueFormat: byte count of all set bits in bits 0-7 (each field = 2 bytes) */
static int vf_sz(uint16_t vf) {
    int n = 0; uint16_t v = vf & 0x00FF;
    while (v) { n += v & 1; v = (uint16_t)(v >> 1); }
    return n * 2;
}

/* Extract XAdvance (bit 2) from a ValueRecord; 0 if not present */
static int16_t vf_xadv(const uint8_t *vr, uint16_t vf) {
    int off = 0;
    if (!(vf & 0x0004)) return 0;
    if (vf & 0x0001) off += 2;   /* XPlacement before XAdvance */
    if (vf & 0x0002) off += 2;   /* YPlacement before XAdvance */
    return RD_S16(vr + off);
}

/* Coverage → sorted array of covered glyph IDs (caller frees); 0 on error */
static int
gpos_cov(const uint8_t *buf, size_t sz, uint32_t off, uint16_t **pg)
{
    const uint8_t *p; uint16_t fmt, n, i, *arr;
    if (off + 4 > sz) return 0;
    p = buf + off; fmt = RD_U16(p);
    if (fmt == 1) {
        n = RD_U16(p + 2);
        if (!n || off + 4 + (uint32_t)n * 2 > sz) return 0;
        arr = (uint16_t *)malloc((size_t)n * 2);
        if (!arr) return 0;
        for (i = 0; i < n; i++) arr[i] = RD_U16(p + 4 + i * 2);
        *pg = arr; return n;
    } else if (fmt == 2) {
        uint16_t rc = RD_U16(p + 2); int tot = 0, wi = 0;
        if (off + 4 + (uint32_t)rc * 6 > sz) return 0;
        for (i = 0; i < rc; i++) {
            uint16_t s = RD_U16(p + 4 + i * 6), e = RD_U16(p + 4 + i * 6 + 2);
            if (e >= s) tot += e - s + 1;
        }
        if (!tot) return 0;
        arr = (uint16_t *)malloc((size_t)tot * 2);
        if (!arr) return 0;
        for (i = 0; i < rc; i++) {
            uint16_t s = RD_U16(p + 4 + i * 6), e = RD_U16(p + 4 + i * 6 + 2), g;
            for (g = s; g <= e; g++) arr[wi++] = g;
        }
        *pg = arr; return tot;
    }
    return 0;
}

/* ClassDef → calloc'd glyph→class array [0..max_glyph] (caller frees) */
static uint16_t *
gpos_cdef(const uint8_t *buf, size_t sz, uint32_t off, uint16_t *outmax)
{
    const uint8_t *p; uint16_t fmt, *arr, mg;
    if (off + 4 > sz) return NULL;
    p = buf + off; fmt = RD_U16(p);
    if (fmt == 1) {
        uint16_t start = RD_U16(p + 2), cnt = RD_U16(p + 4), i;
        if (!cnt || off + 6 + (uint32_t)cnt * 2 > sz) return NULL;
        mg  = (uint16_t)(start + cnt - 1);
        arr = (uint16_t *)calloc((uint32_t)mg + 1, 2);
        if (!arr) return NULL;
        for (i = 0; i < cnt; i++) arr[start + i] = RD_U16(p + 6 + i * 2);
        if (outmax) *outmax = mg; return arr;
    } else if (fmt == 2) {
        uint16_t rc = RD_U16(p + 2), i;
        if (off + 4 + (uint32_t)rc * 6 > sz) return NULL;
        mg = 0;
        for (i = 0; i < rc; i++) { uint16_t e = RD_U16(p + 4 + i * 6 + 2); if (e > mg) mg = e; }
        if (!mg) return NULL;
        arr = (uint16_t *)calloc((uint32_t)mg + 1, 2);
        if (!arr) return NULL;
        for (i = 0; i < rc; i++) {
            uint16_t s = RD_U16(p + 4 + i * 6), e = RD_U16(p + 4 + i * 6 + 2),
                     cls = RD_U16(p + 4 + i * 6 + 4), g;
            for (g = s; g <= e; g++) arr[g] = cls;
        }
        if (outmax) *outmax = mg; return arr;
    }
    return NULL;
}

/* PairPosFormat1: explicit pairs via Coverage + PairSet array */
static void
pairpos1(const uint8_t *buf, size_t sz, uint32_t sub, gkacc_t *acc)
{
    uint16_t vf1, vf2, nps, i;
    int vs1, vs2, recsz;
    uint16_t *cg = NULL; int cn;

    if (sub + 10 > sz) return;
    vf1 = RD_U16(buf + sub + 4); vf2 = RD_U16(buf + sub + 6);
    nps = RD_U16(buf + sub + 8);
    vs1 = vf_sz(vf1); vs2 = vf_sz(vf2);
    recsz = 2 + vs1 + vs2;

    cn = gpos_cov(buf, sz, sub + RD_U16(buf + sub + 2), &cg);
    if (cn <= 0) return;
    if (nps > (uint16_t)cn) nps = (uint16_t)cn;
    if (sub + 10 + (uint32_t)nps * 2 > sz) { free(cg); return; }

    for (i = 0; i < nps; i++) {
        uint16_t g1 = cg[i];
        uint32_t ps = sub + RD_U16(buf + sub + 10 + i * 2);
        uint16_t pvc, j;
        if (ps + 2 > sz) continue;
        pvc = RD_U16(buf + ps);
        if (ps + 2 + (uint32_t)pvc * recsz > sz) continue;
        for (j = 0; j < pvc; j++) {
            const uint8_t *r = buf + ps + 2 + j * recsz;
            gk_add(acc, g1, RD_U16(r), vf_xadv(r + 2, vf1));
        }
    }
    free(cg);
}

/* PairPosFormat2: class-pair matrix via ClassDef1 + ClassDef2 */
static void
pairpos2(const uint8_t *buf, size_t sz, uint32_t sub, gkacc_t *acc)
{
    uint16_t vf1, vf2, c1cnt, c2cnt;
    int vs1, vs2, r2sz, r1sz, cn, c2, ci;
    uint16_t *cg = NULL, *cd1 = NULL, *cd2 = NULL;
    uint16_t cd1max = 0, cd2max = 0;
    /* inverted class2 index */
    uint16_t **c2g = NULL; int *c2n = NULL;

    if (sub + 16 > sz) return;
    vf1   = RD_U16(buf + sub + 4);  vf2   = RD_U16(buf + sub + 6);
    c1cnt = RD_U16(buf + sub + 12); c2cnt = RD_U16(buf + sub + 14);
    if (!c1cnt || !c2cnt) return;
    vs1 = vf_sz(vf1); vs2 = vf_sz(vf2);
    r2sz = vs1 + vs2;                  /* one Class2Record */
    r1sz = c2cnt * r2sz;               /* one Class1Record */
    if ((uint64_t)c1cnt * r1sz + 16 > (uint64_t)(sz - sub)) return;

    cn  = gpos_cov(buf, sz, sub + RD_U16(buf + sub +  2), &cg);
    cd1 = gpos_cdef(buf, sz, sub + RD_U16(buf + sub +  8), &cd1max);
    cd2 = gpos_cdef(buf, sz, sub + RD_U16(buf + sub + 10), &cd2max);
    if (cn <= 0 || !cd1 || !cd2) goto done;

    /* Build class2 → [glyph list] inverted index (skip class 0 = catch-all) */
    c2g = (uint16_t **)calloc(c2cnt, sizeof(*c2g));
    c2n = (int *)calloc(c2cnt, sizeof(int));
    if (!c2g || !c2n) goto done;
    for (ci = 0; ci <= (int)cd2max; ci++) {           /* count */
        uint16_t c = cd2[ci]; if (c && c < c2cnt) c2n[c]++;
    }
    for (c2 = 1; c2 < c2cnt; c2++) {                  /* allocate */
        if (c2n[c2]) { c2g[c2] = (uint16_t *)malloc((size_t)c2n[c2] * 2); c2n[c2] = 0; }
    }
    for (ci = 0; ci <= (int)cd2max; ci++) {           /* fill */
        uint16_t c = cd2[ci];
        if (c && c < c2cnt && c2g[c]) c2g[c][c2n[c]++] = (uint16_t)ci;
    }

    for (ci = 0; ci < cn; ci++) {
        uint16_t g1   = cg[ci];
        uint16_t c1c  = (g1 <= cd1max) ? cd1[g1] : 0;
        const uint8_t *r1;
        if (c1c >= c1cnt) continue;
        r1 = buf + sub + 16 + (uint32_t)c1c * r1sz;
        for (c2 = 1; c2 < c2cnt; c2++) {
            int16_t xadv; int k;
            if (!c2g[c2] || !c2n[c2]) continue;
            xadv = vf_xadv(r1 + c2 * r2sz, vf1);
            if (!xadv) continue;
            for (k = 0; k < c2n[c2]; k++) gk_add(acc, g1, c2g[c2][k], xadv);
        }
    }

done:
    if (c2g) { int i2; for (i2 = 1; i2 < c2cnt; i2++) free(c2g[i2]); free(c2g); }
    free(c2n); free(cg); free(cd1); free(cd2);
}

static void
parse_gpos(const uint8_t *buf, size_t sz, uint32_t off, fm_font_t *fm)
{
    uint32_t lloff;
    uint16_t nlook, li;
    gkacc_t  acc = {NULL, 0, 0};

    if (!off || off + 10 > sz) return;
    lloff = off + RD_U16(buf + off + 8);     /* LookupList offset from GPOS base */
    if (lloff + 2 > sz) return;
    nlook = RD_U16(buf + lloff);
    if (lloff + 2 + (uint32_t)nlook * 2 > sz) return;

    for (li = 0; li < nlook; li++) {
        uint32_t loff = lloff + RD_U16(buf + lloff + 2 + li * 2);
        uint16_t ltype, nsub, si;
        if (loff + 6 > sz) continue;
        ltype = RD_U16(buf + loff);
        if (ltype != 2) continue;            /* only PairPos */
        nsub = RD_U16(buf + loff + 4);
        if (loff + 6 + (uint32_t)nsub * 2 > sz) continue;
        for (si = 0; si < nsub; si++) {
            uint32_t soff = loff + RD_U16(buf + loff + 6 + si * 2);
            uint16_t pfmt;
            if (soff + 2 > sz) continue;
            pfmt = RD_U16(buf + soff);
            if      (pfmt == 1) pairpos1(buf, sz, soff, &acc);
            else if (pfmt == 2) pairpos2(buf, sz, soff, &acc);
        }
    }

    if (!acc.n) { free(acc.p); return; }

    /* Sort and dedup (first subtable/lookup encountered wins) */
    qsort(acc.p, (size_t)acc.n, sizeof(gkpair_t), gkpair_cmp);
    {
        int ri = 0, wi = 0;
        while (ri < acc.n) {
            if (!wi || acc.p[ri].key != acc.p[wi-1].key) acc.p[wi++] = acc.p[ri];
            ri++;
        }
        acc.n = wi;
    }

    /* Merge with existing kern-table pairs; GPOS wins on conflict */
    if (fm->n_kern == 0) {
        uint32_t *kp = (uint32_t *)malloc((size_t)acc.n * sizeof(uint32_t));
        int16_t  *kv = (int16_t  *)malloc((size_t)acc.n * sizeof(int16_t));
        if (kp && kv) {
            int i;
            for (i = 0; i < acc.n; i++) { kp[i] = acc.p[i].key; kv[i] = acc.p[i].val; }
            fm->kern_pairs = kp; fm->kern_values = kv; fm->n_kern = acc.n;
        } else { free(kp); free(kv); }
    } else {
        int total = fm->n_kern + acc.n;
        uint32_t *kp = (uint32_t *)malloc((size_t)total * sizeof(uint32_t));
        int16_t  *kv = (int16_t  *)malloc((size_t)total * sizeof(int16_t));
        if (kp && kv) {
            int ai = 0, bi = 0, ni = 0;
            while (ai < fm->n_kern || bi < acc.n) {
                uint32_t ka = (ai < fm->n_kern) ? fm->kern_pairs[ai] : ~(uint32_t)0;
                uint32_t kb = (bi < acc.n)      ? acc.p[bi].key      : ~(uint32_t)0;
                if      (ka < kb) { kp[ni] = ka; kv[ni] = fm->kern_values[ai]; ni++; ai++; }
                else if (kb < ka) { kp[ni] = kb; kv[ni] = acc.p[bi].val;       ni++; bi++; }
                else              { kp[ni] = kb; kv[ni] = acc.p[bi].val;       ni++; ai++; bi++; }
            }
            free(fm->kern_pairs); free(fm->kern_values);
            fm->kern_pairs = kp; fm->kern_values = kv; fm->n_kern = ni;
        } else { free(kp); free(kv); }
    }
    free(acc.p);
}

/* ── main loader ─────────────────────────────────────────────────────────── */
fm_font_t *fm_load_truetype(const char *path)
{
    FILE      *f;
    uint8_t   *buf;
    long       fsz;
    size_t     bufsz;
    uint32_t   off_head, off_hhea, off_os2, off_cmap, off_hmtx;
    uint16_t   upe, num_hmtx;
    fm_font_t *fm;

    f = fopen(path, "rb");
    if (!f) return NULL;

    fseek(f, 0, SEEK_END);
    fsz = ftell(f);
    rewind(f);
    if (fsz < 12) { fclose(f); return NULL; }

    bufsz = (size_t)fsz;
    buf   = (uint8_t *)malloc(bufsz);
    if (!buf) { fclose(f); return NULL; }
    if (fread(buf, 1, bufsz, f) != bufsz) { fclose(f); free(buf); return NULL; }
    fclose(f);

    /* Accept TTF (0x00010000) and OTF CFF (OTTO) sfVersion */
    {
        uint32_t sfver = RD_U32(buf);
        if (sfver != 0x00010000UL && sfver != 0x4F54544FUL) {
            free(buf); return NULL;
        }
    }

    off_head = find_table(buf, bufsz, "head");
    off_hhea = find_table(buf, bufsz, "hhea");
    off_cmap = find_table(buf, bufsz, "cmap");
    off_hmtx = find_table(buf, bufsz, "hmtx");
    off_os2  = find_table(buf, bufsz, "OS/2");

    if (!off_head || !off_hhea || !off_cmap || !off_hmtx) {
        free(buf); return NULL;
    }

    fm = (fm_font_t *)calloc(1, sizeof(fm_font_t));
    if (!fm) { free(buf); return NULL; }
    fm->type = FM_TRUETYPE;

    /* ── head: unitsPerEm ──────────────────────────────────────────────── */
    if (off_head + 20 > bufsz) goto fail;
    upe = RD_U16(buf + off_head + 18);
    fm->units_per_em = (upe > 0) ? upe : 1000;

    /* ── hhea: ascender, descender, numberOfHMetrics ───────────────────── */
    if (off_hhea + 36 > bufsz) goto fail;
    fm->tt_ascender  = RD_S16(buf + off_hhea + 4);
    fm->tt_descender = RD_S16(buf + off_hhea + 6);
    num_hmtx         = RD_U16(buf + off_hhea + 34);

    /* ── OS/2: cap_height, x_height (version ≥ 2 only) ────────────────── */
    if (off_os2 && off_os2 + 2 <= bufsz) {
        uint16_t os2ver = RD_U16(buf + off_os2);
        if (os2ver >= 2 && off_os2 + 90 <= bufsz) {
            fm->tt_x_height   = RD_S16(buf + off_os2 + 86);  /* sxHeight    */
            fm->tt_cap_height = RD_S16(buf + off_os2 + 88);  /* sCapHeight  */
        } else if (off_os2 + 70 <= bufsz) {
            /* v0/v1: no cap_height field; use sTypoAscender as approximation */
            fm->tt_cap_height = RD_S16(buf + off_os2 + 68);
        }
    }

    /* ── hmtx: advance widths ────────────────────────────────────────────── */
    if (num_hmtx > 0 && off_hmtx + (uint32_t)num_hmtx * 4 <= bufsz) {
        uint16_t *adv;
        uint16_t j;
        adv = (uint16_t *)malloc(num_hmtx * sizeof(uint16_t));
        if (!adv) goto fail;
        for (j = 0; j < num_hmtx; j++)
            adv[j] = RD_U16(buf + off_hmtx + j * 4);
        fm->adv_width = adv;
        fm->n_glyphs  = num_hmtx;
    }

    /* ── cmap: find best Unicode subtable ───────────────────────────────── */
    if (off_cmap + 4 > bufsz) goto fail;
    {
        uint16_t ntab = RD_U16(buf + off_cmap + 2);
        uint16_t t;
        uint32_t best_off  = 0;
        uint16_t best_fmt  = 0;
        int      best_pri  = -1;

        for (t = 0; t < ntab; t++) {
            const uint8_t *rec = buf + off_cmap + 4 + t * 8;
            uint16_t platID, encID, fmt;
            uint32_t suboff;
            int      pri = -1;

            if (rec + 8 > buf + bufsz) break;
            platID = RD_U16(rec);
            encID  = RD_U16(rec + 2);
            suboff = off_cmap + RD_U32(rec + 4);
            if (suboff + 2 > bufsz) continue;
            fmt = RD_U16(buf + suboff);
            if (fmt != 4 && fmt != 12) continue;

            /* Priority: fmt12 > fmt4; Windows/Unicode > others */
            if      (platID == 3 && encID == 10 && fmt == 12) pri = 4;
            else if (platID == 0 && encID >= 3  && fmt == 12) pri = 3;
            else if (platID == 3 && encID == 1  && fmt == 4)  pri = 2;
            else if (platID == 0                && fmt == 4)  pri = 1;
            if (pri > best_pri) {
                best_pri = pri; best_off = suboff; best_fmt = fmt;
            }
        }

        if (best_off) {
            if (best_fmt == 12) {
                uint32_t sublen = (best_off + 8 <= bufsz)
                                ? RD_U32(buf + best_off + 4) : 0;
                if (sublen > 0 && best_off + sublen <= bufsz)
                    parse_cmap12(buf + best_off, sublen,
                                 &fm->cmap_cp, &fm->cmap_glyph, &fm->n_cmap);
            } else {
                uint32_t sublen = (best_off + 4 <= bufsz)
                                ? RD_U16(buf + best_off + 2) : 0;
                if (sublen > 0 && best_off + sublen <= bufsz)
                    parse_cmap4(buf + best_off, sublen,
                                &fm->cmap_cp, &fm->cmap_glyph, &fm->n_cmap);
            }
        }
    }

    /* ── kern table ──────────────────────────────────────────────────────── */
    {
        uint32_t off_kern = find_table(buf, bufsz, "kern");
        if (off_kern) parse_kern(buf, bufsz, off_kern, fm);
    }

    /* ── GPOS PairPos (covers OTF/CFF fonts with no kern table) ─────────── */
    {
        uint32_t off_gpos = find_table(buf, bufsz, "GPOS");
        if (off_gpos) parse_gpos(buf, bufsz, off_gpos, fm);
    }

    free(buf);
    return fm;

fail:
    free(buf);
    fm_free(fm);
    return NULL;
}

void fm_free(fm_font_t *fm)
{
    if (!fm) return;
    free(fm->adv_width);
    free(fm->cmap_cp);
    free(fm->cmap_glyph);
    free(fm->kern_pairs);
    free(fm->kern_values);
    free(fm);
}
