/* mahjong_shanten.c - the distance to ready.
 *
 * Per suit: a recursive grouping of the nine counts into sets, partials and
 * at most one head, reduced to two 25-bit masks (sets 0..4 x partials 0..4,
 * with and without a head) and memoised by the base-5 value of the counts.
 * The honours group trivially. The hand is the best combination.
 */

#include <string.h>
#include "mahjong_abi.h"
#include "mahjong_shanten.h"

#define BASE5_MAX 1953125   /* 5^9 */

/* memo[head][index]: a 25-bit mask of reachable (sets, partials); 0 means
 * unfilled (a filled entry always has at least the (0, 0) bit set) */
static unsigned int MEMO[2][BASE5_MAX];

#define BIT(s, p) (1u << ((s) * 5 + (p)))

struct suit_walk {
    unsigned char c[9];
    unsigned int  mask[2];
};

static void walk(struct suit_walk *w, int i, int sets, int partials, int head)
{
    int c;
    while (i < 9 && !w->c[i]) i++;
    if (i >= 9) {
        if (sets <= 4 && partials <= 4) w->mask[head] |= BIT(sets, partials);
        return;
    }
    c = w->c[i];

    /* a pung of i */
    if (c >= 3) {
        w->c[i] -= 3;
        walk(w, i, sets + 1, partials, head);
        w->c[i] += 3;
    }
    /* a chow from i */
    if (i <= 6 && w->c[i + 1] && w->c[i + 2]) {
        w->c[i]--; w->c[i + 1]--; w->c[i + 2]--;
        walk(w, i, sets + 1, partials, head);
        w->c[i]++; w->c[i + 1]++; w->c[i + 2]++;
    }
    /* a pair of i as the head, once */
    if (c >= 2 && !head) {
        w->c[i] -= 2;
        walk(w, i, sets, partials, 1);
        w->c[i] += 2;
    }
    /* a pair of i as a partial */
    if (c >= 2) {
        w->c[i] -= 2;
        walk(w, i, sets, partials + 1, head);
        w->c[i] += 2;
    }
    /* two adjacent */
    if (i <= 7 && w->c[i + 1]) {
        w->c[i]--; w->c[i + 1]--;
        walk(w, i, sets, partials + 1, head);
        w->c[i]++; w->c[i + 1]++;
    }
    /* two a gap apart */
    if (i <= 6 && w->c[i + 2]) {
        w->c[i]--; w->c[i + 2]--;
        walk(w, i, sets, partials + 1, head);
        w->c[i]++; w->c[i + 2]++;
    }
    /* leave one i ungrouped */
    w->c[i]--;
    walk(w, i, sets, partials, head);
    w->c[i]++;
}

static void suit_masks(const unsigned char *nine, unsigned int *out)
{
    unsigned int idx = 0;
    int i;
    for (i = 0; i < 9; i++) idx = idx * 5 + nine[i];
    if (!MEMO[0][idx]) {
        struct suit_walk w;
        memcpy(w.c, nine, 9);
        w.mask[0] = w.mask[1] = 0;
        walk(&w, 0, 0, 0, 0);
        MEMO[0][idx] = w.mask[0];
        MEMO[1][idx] = w.mask[1];
    }
    out[0] = MEMO[0][idx];
    out[1] = MEMO[1][idx];
}

/* the honours: every kind with three or more is a set, with two a partial
 * or the head */
static void honour_masks(const unsigned char *counts, unsigned int *out)
{
    int k, sets = 0, pairs = 0;
    for (k = 28; k <= 34; k++) {
        if (counts[k] >= 3) sets++;
        else if (counts[k] == 2) pairs++;
    }
    out[0] = out[1] = 0;
    if (sets <= 4 && pairs <= 4) out[0] |= BIT(sets, pairs);
    if (pairs && sets <= 4) out[1] |= BIT(sets, pairs - 1);
    if (!out[0]) out[0] = BIT(0, 0);
}

static int standard(const unsigned char *counts, int melds)
{
    unsigned int m[4][2];
    int best = 99, g, s0, p0, s1, p1, s2, p2, s3, p3, h0, h1, h2, h3;
    unsigned char nine[9];
    for (g = 0; g < 3; g++) {
        memcpy(nine, counts + 1 + 9 * g, 9);
        suit_masks(nine, m[g]);
    }
    honour_masks(counts, m[3]);

    /* every combination of one (sets, partials) from each group, at most
     * one head among them */
    for (h0 = 0; h0 < 2; h0++) for (s0 = 0; s0 <= 4; s0++) for (p0 = 0; p0 <= 4; p0++) {
        if (!(m[0][h0] & BIT(s0, p0))) continue;
        for (h1 = 0; h1 < 2; h1++) { if (h1 && h0) continue;
        for (s1 = 0; s1 <= 4; s1++) for (p1 = 0; p1 <= 4; p1++) {
            if (!(m[1][h1] & BIT(s1, p1))) continue;
            for (h2 = 0; h2 < 2; h2++) { if (h2 && (h0 || h1)) continue;
            for (s2 = 0; s2 <= 4; s2++) for (p2 = 0; p2 <= 4; p2++) {
                if (!(m[2][h2] & BIT(s2, p2))) continue;
                for (h3 = 0; h3 < 2; h3++) { if (h3 && (h0 || h1 || h2)) continue;
                for (s3 = 0; s3 <= 4; s3++) for (p3 = 0; p3 <= 4; p3++) {
                    int S, P, head, d;
                    if (!(m[3][h3] & BIT(s3, p3))) continue;
                    S = melds + s0 + s1 + s2 + s3;
                    P = p0 + p1 + p2 + p3;
                    head = h0 || h1 || h2 || h3;
                    if (S > 4) S = 4;
                    if (S + P > 4) P = 4 - S;
                    d = 8 - 2 * S - P - head;
                    if (d < best) best = d;
                } }
            } }
        } }
    }
    return best;
}

static int seven_pairs(const unsigned char *counts, int melds)
{
    int k, pairs = 0, kinds = 0;
    if (melds) return 99;
    for (k = 1; k <= MJ_KINDS; k++) {
        if (counts[k]) kinds++;
        if (counts[k] >= 2) pairs++;
    }
    return 6 - pairs + (kinds < 7 ? 7 - kinds : 0);
}

static const int ORPHAN[13] = { 1, 9, 10, 18, 19, 27, 28, 29, 30, 31, 32, 33, 34 };

static int thirteen_orphans(const unsigned char *counts, int melds)
{
    int i, have = 0, pair = 0;
    if (melds) return 99;
    for (i = 0; i < 13; i++) {
        if (counts[ORPHAN[i]]) have++;
        if (counts[ORPHAN[i]] >= 2) pair = 1;
    }
    return 13 - have - pair;
}

static const int KNIT_BASE[3] = { 1, 2, 3 };
static const int PERM[6][3] = {
    { 0, 1, 2 }, { 0, 2, 1 }, { 1, 0, 2 }, { 1, 2, 0 }, { 2, 0, 1 }, { 2, 1, 0 }
};

static int honours_knitted(const unsigned char *counts, int melds)
{
    int p, k, honours = 0, best = 0;
    if (melds) return 99;
    for (k = 28; k <= 34; k++) if (counts[k]) honours++;
    for (p = 0; p < 6; p++) {
        int s, usable = honours;
        for (s = 0; s < 3; s++) {
            int base = KNIT_BASE[PERM[p][s]], r;
            for (r = base; r <= 9; r += 3) if (counts[1 + 9 * s + r - 1]) usable++;
        }
        if (usable > best) best = usable;
    }
    return 13 - best;
}

int mj_shanten_forms(const unsigned char *counts, int melds, int *out)
{
    int min;
    out[MJ_FORM_S_STANDARD] = standard(counts, melds);
    out[MJ_FORM_S_PAIRS]    = seven_pairs(counts, melds);
    out[MJ_FORM_S_ORPHANS]  = thirteen_orphans(counts, melds);
    out[MJ_FORM_S_KNITTED]  = honours_knitted(counts, melds);
    min = out[0];
    if (out[1] < min) min = out[1];
    if (out[2] < min) min = out[2];
    if (out[3] < min) min = out[3];
    return min;
}

int mj_shanten(const unsigned char *counts, int melds)
{
    int forms[MJ_FORM_S_COUNT];
    return mj_shanten_forms(counts, melds, forms);
}

int mj_ukeire(const unsigned char *counts, int melds, unsigned char *out)
{
    unsigned char c[MJ_KINDS + 1];
    int k, n = 0, now;
    memcpy(c, counts, MJ_KINDS + 1);
    now = mj_shanten(c, melds);
    for (k = 1; k <= MJ_KINDS; k++) {
        if (c[k] >= MJ_PER_KIND) continue;
        c[k]++;
        if (mj_shanten(c, melds) < now) out[n++] = (unsigned char)k;
        c[k]--;
    }
    return n;
}
