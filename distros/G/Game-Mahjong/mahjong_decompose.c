/* mahjong_decompose.c - every split of a hand, and the waits.
 *
 * Counts over the thirty-four kinds, the melds a number. The standard form
 * is a backtracking walk from the lowest kind held: at that kind the split
 * either takes a pung of it or a chow starting from it, and nothing else can
 * consume it, so every multiset of sets is found exactly once and none twice
 * (the pung count of the lowest kind is 0 or 1, and the chows from it are
 * whatever is left, so the choice is forced by the multiset). The special
 * forms are checked by their shape.
 *
 * The table it reads is mahjong_abi.h's, and nothing here knows a tile's
 * suit or rank except through it.
 */

#include <string.h>
#include "mahjong_abi.h"
#include "mahjong_decompose.h"

static const struct mj_abi *MJ = 0;

#define SUIT(k)  (MJ->kind[k].suit)
#define RANK(k)  (MJ->kind[k].rank)
#define IS_SUIT(k) (MJ->kind[k].flags & MJ_F_SUIT)

/* the three knitted patterns, as rank offsets 1-4-7, 2-5-8, 3-6-9 */
static const int KNIT_BASE[3] = { 1, 2, 3 };
/* the six assignments of patterns to the suits characters, dots, bamboo */
static const int PERM[6][3] = {
    { 0, 1, 2 }, { 0, 2, 1 }, { 1, 0, 2 }, { 1, 2, 0 }, { 2, 0, 1 }, { 2, 1, 0 }
};
/* the kind of rank r in suit s (1 char, 2 dot, 3 bam) */
#define KIND_OF(s, r) (((s) - 1) * 9 + (r))

/* the thirteen orphans: the six terminals and the seven honours */
static const int ORPHAN[13] = { 1, 9, 10, 18, 19, 27, 28, 29, 30, 31, 32, 33, 34 };

struct walk {
    unsigned char     c[MJ_KINDS + 1];
    int               melds;
    int               winning;
    struct mj_split  *out;
    int               max;
    int               n;          /* splits written */
    int               overflow;
    struct mj_set     sets[MJ_MAX_SETS];
    int               nsets;
    int               pair;
};

static int total(const unsigned char *c)
{
    int i, t = 0;
    for (i = 1; i <= MJ_KINDS; i++) t += c[i];
    return t;
}

/* ---- emitting a split, with its placements ---------------------------------- */

static void emit(struct walk *w, struct mj_split *base)
{
    int i, placed = 0;

    if (!w->winning) {
        if (w->n >= w->max) { w->overflow = 1; return; }
        w->out[w->n++] = *base;
        return;
    }

    /* one copy per place the winning tile can sit */
    for (i = 0; i < base->nsets; i++) {
        const struct mj_set *s = &base->sets[i];
        int j, in = 0, wait = MJ_WAIT_NONE;
        for (j = 0; j < 3; j++) if (s->tiles[j] == w->winning) in = 1;
        if (!in) continue;
        if (s->kind == MJ_SET_PUNG) wait = MJ_WAIT_PUNG;
        else if (s->kind == MJ_SET_KNIT) wait = MJ_WAIT_KNIT;
        else {
            int r = RANK(s->tiles[0]);
            if (w->winning == s->tiles[1]) wait = MJ_WAIT_CLOSED;
            else if (r == 1 && w->winning == s->tiles[2]) wait = MJ_WAIT_EDGE;
            else if (r == 7 && w->winning == s->tiles[0]) wait = MJ_WAIT_EDGE;
            else wait = MJ_WAIT_TWO_SIDED;
        }
        if (w->n >= w->max) { w->overflow = 1; return; }
        w->out[w->n] = *base;
        w->out[w->n].place_in = MJ_IN_SET;
        w->out[w->n].place_index = (unsigned char)i;
        w->out[w->n].wait = (unsigned char)wait;
        w->n++;
        placed = 1;
    }
    if (base->pair && base->pair == w->winning) {
        if (w->n >= w->max) { w->overflow = 1; return; }
        w->out[w->n] = *base;
        w->out[w->n].place_in = MJ_IN_PAIR;
        w->out[w->n].place_index = 0;
        w->out[w->n].wait = MJ_WAIT_PAIR;
        w->n++;
        placed = 1;
    }
    for (i = 0; i < base->nsingles; i++) {
        if (base->singles[i] != w->winning) continue;
        if (w->n >= w->max) { w->overflow = 1; return; }
        w->out[w->n] = *base;
        w->out[w->n].place_in = MJ_IN_SINGLE;
        w->out[w->n].place_index = (unsigned char)i;
        w->out[w->n].wait = MJ_WAIT_SINGLE;
        w->n++;
        placed = 1;
        break;   /* a kind appears once among the singles */
    }
    /* the winning tile is in a meld, or not in the hand at all: the caller
     * asked for a placement that does not exist; return the split unplaced
     * rather than nothing, so the hand still counts as complete */
    if (!placed) {
        if (w->n >= w->max) { w->overflow = 1; return; }
        w->out[w->n++] = *base;
    }
}

static void emit_standard(struct walk *w, int form)
{
    struct mj_split s;
    memset(&s, 0, sizeof s);
    s.form = (unsigned char)form;
    s.nsets = (unsigned char)w->nsets;
    memcpy(s.sets, w->sets, sizeof(struct mj_set) * (size_t)w->nsets);
    s.pair = (unsigned char)w->pair;
    emit(w, &s);
}

/* ---- the standard form ------------------------------------------------------ */

static void walk_sets(struct walk *w, int from, int form)
{
    int i;
    for (i = from; i <= MJ_KINDS && !w->c[i]; i++) ;
    if (i > MJ_KINDS) { emit_standard(w, form); return; }
    if (w->nsets >= MJ_MAX_SETS) return;

    if (w->c[i] >= 3) {
        struct mj_set *s = &w->sets[w->nsets++];
        s->kind = MJ_SET_PUNG;
        s->tiles[0] = s->tiles[1] = s->tiles[2] = (unsigned char)i;
        w->c[i] -= 3;
        walk_sets(w, i, form);
        w->c[i] += 3;
        w->nsets--;
    }
    if (IS_SUIT(i) && RANK(i) <= 7 && w->c[i + 1] && w->c[i + 2]) {
        struct mj_set *s = &w->sets[w->nsets++];
        s->kind = MJ_SET_CHOW;
        s->tiles[0] = (unsigned char)i;
        s->tiles[1] = (unsigned char)(i + 1);
        s->tiles[2] = (unsigned char)(i + 2);
        w->c[i]--; w->c[i + 1]--; w->c[i + 2]--;
        walk_sets(w, i, form);
        w->c[i]++; w->c[i + 1]++; w->c[i + 2]++;
        w->nsets--;
    }
}

static void standard(struct walk *w)
{
    int p, need = 14 - 3 * w->melds;
    if (total(w->c) != need) return;
    for (p = 1; p <= MJ_KINDS; p++) {
        if (w->c[p] < 2) continue;
        w->c[p] -= 2;
        w->pair = p;
        w->nsets = 0;
        walk_sets(w, 1, MJ_FORM_STANDARD);
        w->c[p] += 2;
    }
    w->pair = 0;
}

/* ---- seven pairs ------------------------------------------------------------ */

static void seven_pairs(struct walk *w)
{
    int i, pairs = 0;
    struct mj_split s;
    if (w->melds) return;
    if (total(w->c) != 14) return;
    for (i = 1; i <= MJ_KINDS; i++) {
        if (w->c[i] & 1) return;
        pairs += w->c[i] / 2;
    }
    if (pairs != 7) return;
    memset(&s, 0, sizeof s);
    s.form = MJ_FORM_SEVEN_PAIRS;
    /* the pairs ride in singles, one entry per pair, a four-of-a-kind twice */
    for (i = 1; i <= MJ_KINDS; i++) {
        int k;
        for (k = 0; k < w->c[i] / 2; k++) s.singles[s.nsingles++] = (unsigned char)i;
    }
    /* the winning tile completed one pair: a pair wait */
    if (w->winning && w->c[w->winning]) {
        if (w->n >= w->max) { w->overflow = 1; return; }
        s.place_in = MJ_IN_PAIR;
        s.place_index = 0;
        s.wait = MJ_WAIT_PAIR;
        s.pair = (unsigned char)w->winning;
        w->out[w->n++] = s;
        return;
    }
    if (w->n >= w->max) { w->overflow = 1; return; }
    w->out[w->n++] = s;
}

/* ---- thirteen orphans ------------------------------------------------------- */

static void thirteen_orphans(struct walk *w)
{
    int i, pair = 0;
    struct mj_split s;
    if (w->melds) return;
    if (total(w->c) != 14) return;
    for (i = 1; i <= MJ_KINDS; i++) {
        int orphan = 0, j;
        for (j = 0; j < 13; j++) if (ORPHAN[j] == i) orphan = 1;
        if (!orphan) { if (w->c[i]) return; continue; }
        if (w->c[i] == 0 || w->c[i] > 2) return;
        if (w->c[i] == 2) { if (pair) return; pair = i; }
    }
    if (!pair) return;
    memset(&s, 0, sizeof s);
    s.form = MJ_FORM_THIRTEEN_ORPHANS;
    s.pair = (unsigned char)pair;
    for (i = 0; i < 13; i++) s.singles[s.nsingles++] = (unsigned char)ORPHAN[i];
    if (w->winning) {
        if (w->n >= w->max) { w->overflow = 1; return; }
        if (w->winning == pair) { s.place_in = MJ_IN_PAIR; s.wait = MJ_WAIT_PAIR; }
        else {
            for (i = 0; i < 13; i++) if (ORPHAN[i] == w->winning) s.place_index = (unsigned char)i;
            s.place_in = MJ_IN_SINGLE;
            s.wait = MJ_WAIT_SINGLE;
        }
        w->out[w->n++] = s;
        return;
    }
    if (w->n >= w->max) { w->overflow = 1; return; }
    w->out[w->n++] = s;
}

/* ---- honours and knitted tiles (fans 20 and 34) ----------------------------- */

/* every tile a single; the suit tiles of each suit a subset of the pattern
 * the permutation assigns it; at least the honours to make fourteen */
static void honours_knitted(struct walk *w)
{
    int i, p;
    if (w->melds) return;
    if (total(w->c) != 14) return;
    for (i = 1; i <= MJ_KINDS; i++) if (w->c[i] > 1) return;
    for (p = 0; p < 6; p++) {
        int ok = 1, s;
        for (s = 1; s <= 3 && ok; s++) {
            int base = KNIT_BASE[PERM[p][s - 1]], r;
            for (r = 1; r <= 9; r++) {
                if (w->c[KIND_OF(s, r)] && (r - base) % 3 != 0) { ok = 0; break; }
            }
        }
        if (!ok) continue;
        {
            struct mj_split sp;
            memset(&sp, 0, sizeof sp);
            sp.form = MJ_FORM_HONOURS_KNITTED;
            for (i = 1; i <= MJ_KINDS; i++) if (w->c[i]) sp.singles[sp.nsingles++] = (unsigned char)i;
            if (w->winning) {
                for (i = 0; i < sp.nsingles; i++) if (sp.singles[i] == w->winning) sp.place_index = (unsigned char)i;
                sp.place_in = MJ_IN_SINGLE;
                sp.wait = MJ_WAIT_SINGLE;
            }
            if (w->n >= w->max) { w->overflow = 1; return; }
            w->out[w->n++] = sp;
        }
        /* one split whatever the assignment: the singles are the same tiles */
        return;
    }
}

/* ---- the knitted straight (fan 35) ------------------------------------------ */

/* nine tiles making 1-4-7, 2-5-8, 3-6-9 one pattern per suit; the rest a
 * standard hand of (1 - melds) sets and a pair */
static void knitted_straight(struct walk *w)
{
    int p, need = 14 - 3 * w->melds;
    if (w->melds > 1) return;
    if (total(w->c) != need) return;
    for (p = 0; p < 6; p++) {
        int ok = 1, s, k;
        struct mj_set knit[3];
        for (s = 1; s <= 3 && ok; s++) {
            int base = KNIT_BASE[PERM[p][s - 1]];
            for (k = 0; k < 3; k++) {
                int kind = KIND_OF(s, base + 3 * k);
                if (!w->c[kind]) { ok = 0; break; }
                knit[s - 1].tiles[k] = (unsigned char)kind;
            }
            knit[s - 1].kind = MJ_SET_KNIT;
        }
        if (!ok) continue;
        /* take the nine out, split the rest */
        for (s = 0; s < 3; s++) for (k = 0; k < 3; k++) w->c[knit[s].tiles[k]]--;
        {
            int q;
            for (q = 1; q <= MJ_KINDS; q++) {
                if (w->c[q] < 2) continue;
                w->c[q] -= 2;
                w->pair = q;
                w->nsets = 3;
                memcpy(w->sets, knit, sizeof knit);
                walk_sets(w, 1, MJ_FORM_KNITTED_STRAIGHT);
                w->c[q] += 2;
            }
            w->pair = 0;
            w->nsets = 0;
        }
        for (s = 0; s < 3; s++) for (k = 0; k < 3; k++) w->c[knit[s].tiles[k]]++;
    }
}

/* ---- the public three --------------------------------------------------------- */

int mj_decompose(const unsigned char *counts, int melds, int winning,
                 struct mj_split *out, int max)
{
    struct walk w;
    if (!MJ) MJ = mj_abi_table();
    memset(&w, 0, sizeof w);
    memcpy(w.c, counts, MJ_KINDS + 1);
    w.c[0] = 0;
    w.melds = melds;
    w.winning = winning;
    w.out = out;
    w.max = max;

    standard(&w);
    seven_pairs(&w);
    thirteen_orphans(&w);
    honours_knitted(&w);
    knitted_straight(&w);

    return w.overflow ? -1 : w.n;
}

int mj_is_complete(const unsigned char *counts, int melds)
{
    struct mj_split one;
    int n = mj_decompose(counts, melds, 0, &one, 1);
    return n != 0 ? 1 : 0;
}

int mj_waits(const unsigned char *counts, int melds, unsigned char *out)
{
    unsigned char c[MJ_KINDS + 1];
    int k, n = 0;
    if (!MJ) MJ = mj_abi_table();
    memcpy(c, counts, MJ_KINDS + 1);
    for (k = 1; k <= MJ_KINDS; k++) {
        if (c[k] >= MJ_PER_KIND) continue;
        c[k]++;
        if (mj_is_complete(c, melds)) out[n++] = (unsigned char)k;
        c[k]--;
    }
    return n;
}
