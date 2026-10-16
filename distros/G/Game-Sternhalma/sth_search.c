/* sth_search.c - an evaluation, and a search bounded in positions looked at.
 *
 * PERL-FREE by design: see include/sth_abi.h.
 *
 * THIS FILE'S SCOPE, version 6. How good a position is for a seat, in
 * integers; the move a seat should make, by alpha-beta for two seats racing
 * and by a paranoid search or max-n for more; and the weakest player there
 * is, a random choice among the moves that go forward.
 *
 * A BUDGET IS POSITIONS, NEVER SECONDS, so a test asks the same thing on a
 * fast machine and a slow one. The first iteration always finishes; after
 * that, a search that runs out plays the best move of the last iteration it
 * finished, never the first move in the list.
 */

#include <stdlib.h>
#include <string.h>
#include "sth_internal.h"

/* ---- tables for the evaluation --------------------------------------------- */

static int TIP[STH_POINTS];                       /* each point's tip hole        */
static int DIST[STH_POINTS][STH_HOLES];           /* hex distance to that tip     */
static int HOME_CLS[2][STH_POINTS][STH_CLASSES];  /* 10- and 15-hole homes        */
static int IN_HOME[2][STH_POINTS][STH_HOLES];
static int SEARCH_READY = 0;

static int hexd(int a, int b)
{
    int dx = STH_HX[a] - STH_HX[b], dy = STH_HY[a] - STH_HY[b], dz = -dx - dy;
    if (dx < 0) dx = -dx;
    if (dy < 0) dy = -dy;
    if (dz < 0) dz = -dz;
    return (dx + dy + dz) / 2;
}

static int cls_of(int h)
{
    return ((STH_HX[h] + 8) & 1) | (((STH_HY[h] + 8) & 1) << 1);
}

static void search_init(void)
{
    int p, h, i, k, n;
    if (SEARCH_READY) return;
    sth_tables_init();
    for (p = 0; p < STH_POINTS; p++) {
        TIP[p] = STH_POINT_LIST[p][0];
        for (i = 0; i < STH_POINT_HOLES; i++) {
            n = 0;
            for (k = 0; k < STH_DIRS; k++)
                n += STH_HOLE_AT[STH_SQ_OF[STH_POINT_LIST[p][i]] + STH_STEP[k]] >= 0;
            if (n == 2) TIP[p] = STH_POINT_LIST[p][i];
        }
        for (h = 0; h < STH_HOLES; h++) DIST[p][h] = hexd(h, TIP[p]);
        memset(HOME_CLS[0][p], 0, sizeof HOME_CLS[0][p]);
        memset(HOME_CLS[1][p], 0, sizeof HOME_CLS[1][p]);
        memset(IN_HOME[0][p], 0, sizeof IN_HOME[0][p]);
        memset(IN_HOME[1][p], 0, sizeof IN_HOME[1][p]);
        for (i = 0; i < STH_POINT_HOLES; i++) {
            h = STH_POINT_LIST[p][i];
            HOME_CLS[0][p][cls_of(h)]++;
            HOME_CLS[1][p][cls_of(h)]++;
            IN_HOME[0][p][h] = IN_HOME[1][p][h] = 1;
        }
        for (i = 0; i < STH_FRONT_HOLES; i++) {
            h = STH_FRONT[p][i];
            HOME_CLS[1][p][cls_of(h)]++;
            IN_HOME[1][p][h] = 1;
        }
    }
    SEARCH_READY = 1;
}

void sth_weights_default(struct sth_weights *w)
{
    memset(w, 0, sizeof *w);
    w->distance  = STH_W_DISTANCE;
    w->straggler = STH_W_STRAGGLER;
    w->classes   = STH_W_CLASSES;
    w->blocking  = STH_W_BLOCKING;
}

static int home_of(const struct sth_board *b, int seat)
{
    return (STH_LAYOUT[b->seats][seat] + 3) % STH_POINTS;
}

static int in_list(const int *list, int n, int x)
{
    int i;
    for (i = 0; i < n; i++) if (list[i] == x) return 1;
    return 0;
}

static int racing(const struct sth_board *b, int seat)
{
    return !in_list(b->finished, b->finished_n, seat) && !in_list(b->resigned, b->resigned_n, seat);
}

/* EVERY SEAT'S SCORE, higher better. A seat home scores STH_WIN_SCORE.
 * Otherwise minus the weighted sum of four things a racing seat wants small:
 *
 *   distance   for a piece in its home, its distance to the home's tip; for
 *              a piece outside, the cheapest way into an empty home hole,
 *              the walk there and that hole's own distance to the tip; all
 *              less what a full home sums to, so 0 is home. Measuring an
 *              outside piece to the tip instead left a seat with one piece
 *              out and the empty hole at the edge of its home with nothing
 *              to gain by walking toward it, and four-seat games stalled
 *              there for thousands of plies (07)
 *   straggler  the distance of its rearmost piece to the tip: a piece left
 *              behind has nothing to hop over later
 *   classes    how far its pieces' hop classes are from its home's
 *   blocking   pairs of a piece in the home and an empty hole deeper in */
static void evaluate_all(const struct sth_board *b, const struct sth_weights *w, int *score)
{
    int s, h, k, big = b->pieces == STH_PIECES_MAX;
    int at[STH_SEATS_MAX][STH_PIECES_MAX], n[STH_SEATS_MAX];
    memset(n, 0, sizeof n);
    for (h = 0; h < STH_HOLES; h++) {
        int c = b->cell[STH_SQ_OF[h]];
        if (STH_IS_PIECE(c) && n[c] < STH_PIECES_MAX) at[c][n[c]++] = h;
    }
    for (s = 0; s < b->seats; s++) {
        int p = home_of(b, s), floor = 0, mismatch = 0, blocking = 0, sum = 0, worst = 0, i, j;
        int nholes = big ? STH_POINT_HOLES + STH_FRONT_HOLES : STH_POINT_HOLES;
        int holes[STH_POINT_HOLES + STH_FRONT_HOLES], free_[STH_POINT_HOLES + STH_FRONT_HOLES], nfree = 0;
        int cls[STH_CLASSES];
        if (in_list(b->finished, b->finished_n, s)) { score[s] = STH_WIN_SCORE; continue; }
        memset(cls, 0, sizeof cls);
        for (i = 0; i < STH_POINT_HOLES; i++) holes[i] = STH_POINT_LIST[p][i];
        if (big) for (i = 0; i < STH_FRONT_HOLES; i++) holes[STH_POINT_HOLES + i] = STH_FRONT[p][i];
        for (i = 0; i < nholes; i++) {
            floor += DIST[p][holes[i]];
            if (b->cell[STH_SQ_OF[holes[i]]] == STH_EMPTY) free_[nfree++] = holes[i];
        }
        for (k = 0; k < n[s]; k++) {
            int piece = at[s][k], cost = DIST[p][piece];
            if (!IN_HOME[big][p][piece] && nfree) {
                int best = -1;
                for (j = 0; j < nfree; j++) {
                    int c = hexd(piece, free_[j]) + DIST[p][free_[j]];
                    if (best < 0 || c < best) best = c;
                }
                cost = best;
            }
            sum += cost;
            if (DIST[p][piece] > worst) worst = DIST[p][piece];
            cls[cls_of(piece)]++;
        }
        for (k = 0; k < STH_CLASSES; k++) {
            int dk = cls[k] - HOME_CLS[big][p][k];
            mismatch += dk < 0 ? -dk : dk;
        }
        for (i = 0; i < nfree; i++)
            for (j = 0; j < nholes; j++)
                if (b->cell[STH_SQ_OF[holes[j]]] == s && DIST[p][holes[j]] > DIST[p][free_[i]]) blocking++;
        score[s] = -(w->distance * (sum - floor) + w->straggler * worst
                     + w->classes * mismatch + w->blocking * blocking);
    }
}

int sth_evaluate(const struct sth_board *b, int seat, const struct sth_weights *w)
{
    int score[STH_SEATS_MAX];
    search_init();
    if (!b || seat < 0 || seat >= b->seats) return 0;
    evaluate_all(b, w, score);
    return score[seat];
}

/* A position's value to one seat: its own score less the best score of a
 * rival still racing. Two seats: the difference. More: the race for the next
 * place is against whoever is nearest. */
static int value_for(const struct sth_board *b, const int *score, int seat)
{
    int r, best = 0, any = 0;
    for (r = 0; r < b->seats; r++) {
        if (r == seat || !racing(b, r)) continue;
        if (!any || score[r] > best) best = score[r];
        any = 1;
    }
    return any ? score[seat] - best : score[seat];
}

/* A SEAT PLACED, scored by its place. Home is always worth more than any
 * position in which the seat is still racing, and an earlier place more than
 * a later one; a game that ends with the seat still out is worth less than
 * anything. The first version scored places from a win for first to a loss
 * for last, linearly: so third of four, home, came out worse than racing on,
 * and a seat one step from home stepped back and forth for ever rather than
 * go in (07: every four- and six-seat stall). Sooner is better and later
 * worse, by the plies it is away. */
static int placed_value(const struct sth_board *b, int seat, int ply)
{
    int place = sth_place_of(b, seat);
    if (place <= 0) return 0;
    if (in_list(b->finished, b->finished_n, seat))
        return STH_WIN_SCORE + (b->seats - place) * STH_PLACE_STEP - ply;
    return -STH_WIN_SCORE + (b->seats - place) * STH_PLACE_STEP + ply;
}

/* ---- the search -------------------------------------------------------------- */

struct tt_entry {
    unsigned long long key;
    int score;
    short depth;
    short flag;                 /* 1 exact, 2 lower bound, 3 upper bound */
    short from, to;
};

#define TT_BITS 16
#define TT_SIZE (1 << TT_BITS)

struct ctx {
    const struct sth_weights *w;
    unsigned long long budget, nodes, seed;
    int root, stopped, mode;
    struct tt_entry *tt;
};

static unsigned long long mix(unsigned long long x)
{
    x ^= x >> 33; x *= 0xff51afd7ed558ccdULL; x ^= x >> 33; x *= 0xc4ceb9fe1a85ec53ULL; x ^= x >> 33;
    return x;
}

static unsigned long long tie(const struct ctx *c, int from, int to)
{
    return mix(c->seed * 0x9E3779B97F4A7C15ULL + (unsigned long long) (from * 131 + to + 1));
}

/* Moves of the seat to move, best-looking first: the ones that take a piece
 * furthest toward home. A pass is from = -1. */
static int ordered_moves(const struct sth_board *b, int *from, int *to, int prefer_from, int prefer_to)
{
    static int gain[STH_LEGAL_MAX];
    int n, i, j, p, g, f, t;
    n = sth_legal(b, from, to, STH_LEGAL_MAX);
    if (n > STH_LEGAL_MAX) n = STH_LEGAL_MAX;
    if (n == 0) { from[0] = to[0] = -1; return 1; }
    p = home_of(b, b->to_move);
    for (i = 0; i < n; i++) {
        gain[i] = DIST[p][from[i]] - DIST[p][to[i]];
        if (from[i] == prefer_from && to[i] == prefer_to) gain[i] = 1000;
    }
    for (i = 1; i < n; i++) {
        g = gain[i]; f = from[i]; t = to[i];
        for (j = i; j > 0 && gain[j - 1] < g; j--) { gain[j] = gain[j - 1]; from[j] = from[j - 1]; to[j] = to[j - 1]; }
        gain[j] = g; from[j] = f; to[j] = t;
    }
    return n;
}

static int apply(struct sth_board *b, int from, int to, struct sth_undo *u)
{
    if (from < 0) return sth_pass(b, u) == STH_PLAY_OK;
    return sth_play_trusted(b, from, to, u) == STH_PLAY_OK;
}

static int leaf(const struct sth_board *b, const struct ctx *c, int ply)
{
    int score[STH_SEATS_MAX];
    if (b->over || in_list(b->finished, b->finished_n, c->root)) return placed_value(b, c->root, ply);
    evaluate_all(b, c->w, score);
    return value_for(b, score, c->root);
}

/* Alpha-beta over the root seat's value: the root maximises, every other seat
 * minimises it. With two seats that is the plain game; with more it is the
 * paranoid assumption, every rival against the root. */
static int ab(struct sth_board *b, struct ctx *c, int depth, int alpha, int beta, int ply)
{
    int from[STH_LEGAL_MAX], to[STH_LEGAL_MAX], n, i, best, maximise, v;
    int pf = -2, pt = -2, bf = -2, bt = -2, a0 = alpha, b0 = beta;
    struct tt_entry *e;
    struct sth_undo u;

    c->nodes++;
    if (depth == 0 || b->over || in_list(b->finished, b->finished_n, c->root)) return leaf(b, c, ply);
    if (c->nodes > c->budget) { c->stopped = 1; return 0; }

    e = &c->tt[b->key & (TT_SIZE - 1)];
    if (e->key == b->key && e->depth >= depth) {
        if (e->flag == 1) return e->score;
        if (e->flag == 2 && e->score >= beta) return e->score;
        if (e->flag == 3 && e->score <= alpha) return e->score;
    }
    if (e->key == b->key) { pf = e->from; pt = e->to; }

    n = ordered_moves(b, from, to, pf, pt);
    maximise = b->to_move == c->root;
    best = maximise ? -STH_INF : STH_INF;
    for (i = 0; i < n; i++) {
        if (!apply(b, from[i], to[i], &u)) continue;
        v = ab(b, c, depth - 1, alpha, beta, ply + 1);
        sth_unplay(b, &u);
        if (c->stopped) return 0;
        if (maximise ? v > best : v < best) { best = v; bf = from[i]; bt = to[i]; }
        if (maximise) { if (best > alpha) alpha = best; }
        else { if (best < beta) beta = best; }
        if (alpha >= beta) break;
    }
    e->key = b->key;
    e->depth = (short) depth;
    e->score = best;
    e->flag = (short) (best <= a0 ? 3 : best >= b0 ? 2 : 1);
    e->from = (short) bf;
    e->to = (short) bt;
    return best;
}

/* Max-n: every seat maximises its own value. A vector comes back, one value
 * a seat; no pruning applies, so it looks less deep for the same budget. */
static void maxn(struct sth_board *b, struct ctx *c, int depth, int ply, int *out)
{
    int from[STH_LEGAL_MAX], to[STH_LEGAL_MAX], n, i, s, mover, have = 0;
    int v[STH_SEATS_MAX], score[STH_SEATS_MAX];
    struct sth_undo u;

    c->nodes++;
    if (depth > 0 && !b->over && c->nodes > c->budget) { c->stopped = 1; return; }
    if (depth == 0 || b->over) {
        if (b->over) { for (s = 0; s < b->seats; s++) out[s] = placed_value(b, s, ply); return; }
        evaluate_all(b, c->w, score);
        for (s = 0; s < b->seats; s++)
            out[s] = in_list(b->finished, b->finished_n, s) ? placed_value(b, s, ply) : value_for(b, score, s);
        return;
    }
    mover = b->to_move;
    n = ordered_moves(b, from, to, -2, -2);
    for (i = 0; i < n; i++) {
        if (!apply(b, from[i], to[i], &u)) continue;
        maxn(b, c, depth - 1, ply + 1, v);
        sth_unplay(b, &u);
        if (c->stopped) return;
        if (!have || v[mover] > out[mover]) { memcpy(out, v, sizeof v); have = 1; }
    }
}

/* With two seats racing the paranoid search is the plain game; with more it
 * is the cheaper of the two to explain, and 07 measured it against max-n. */
static int pick_mode(int mode)
{
    return mode == STH_SEARCH_MAXN ? STH_SEARCH_MAXN : STH_SEARCH_PARANOID;
}

static int seen_before(unsigned long long key, const unsigned long long *avoid, int avoid_n)
{
    int i;
    for (i = 0; i < avoid_n; i++) if (avoid[i] == key) return 1;
    return 0;
}

/* A SEAT'S OWN PIECES NEVER GO BACK TO AN ARRANGEMENT THEY HAVE HAD, unless
 * every move takes them back to one. Shuffling a piece inside its home costs
 * nothing, and at depth 2 a seat can see that walking its last piece forward
 * hands a rival a hop: so seats shuffle, and the game never ends (07 found it
 * between searching players). Asked of the whole board, the rule caught two
 * seats and missed four, whose other seats keep the board from ever quite
 * repeating; asked of the mover's own pieces it catches a shuffle whatever
 * the rest of the board does. */
unsigned long long sth_own_key(const struct sth_board *b, int seat)
{
    unsigned long long k = 0;
    int h;
    if (!b || seat < 0 || seat >= b->seats) return 0;
    for (h = 0; h < STH_HOLES; h++)
        if (b->cell[STH_SQ_OF[h]] == seat) k ^= STH_ZOB[seat][h];
    return k;
}

int sth_search(const struct sth_board *b0, const struct sth_weights *w, unsigned long long budget,
                      unsigned long long seed, int max_depth, int mode,
                      const unsigned long long *avoid, int avoid_n,
                      int *best_from, int *best_to, struct sth_search_info *info)
{
    struct sth_board b;
    struct ctx c;
    int from[STH_LEGAL_MAX], to[STH_LEGAL_MAX], n, i, depth, done_from = -1, done_to = -1, done_score = 0;
    int done_depth = 0;
    struct sth_undo u;

    search_init();
    if (info) memset(info, 0, sizeof *info);
    if (!b0 || b0->over) return 0;
    b = *b0;
    memset(&c, 0, sizeof c);
    c.w = w;
    c.budget = budget ? budget : 1;
    c.seed = seed ? seed : 1;
    c.root = b.to_move;
    c.mode = pick_mode(mode);
    c.tt = (struct tt_entry *) calloc(TT_SIZE, sizeof(struct tt_entry));
    if (!c.tt) return 0;

    n = ordered_moves(&b, from, to, -2, -2);
    {
        int fresh = 0;
        for (i = 0; i < n; i++) {
            if (!apply(&b, from[i], to[i], &u)) continue;
            if (!seen_before(sth_own_key(&b, c.root), avoid, avoid_n)) fresh++;
            sth_unplay(&b, &u);
        }
        if (!fresh) avoid_n = 0;
    }

    for (depth = 1; max_depth == 0 || depth <= max_depth; depth++) {
        int it_from = -1, it_to = -1, it_best = -STH_INF, pf = done_from, pt = done_to;
        unsigned long long it_tie = 0;
        n = ordered_moves(&b, from, to, pf, pt);
        for (i = 0; i < n; i++) {
            int v;
            if (!apply(&b, from[i], to[i], &u)) continue;
            if (avoid_n && seen_before(sth_own_key(&b, c.root), avoid, avoid_n)) { sth_unplay(&b, &u); continue; }
            if (c.mode == STH_SEARCH_MAXN) {
                int vec[STH_SEATS_MAX];
                maxn(&b, &c, depth - 1, 1, vec);
                v = vec[c.root];
            }
            else v = ab(&b, &c, depth - 1, -STH_INF, STH_INF, 1);
            sth_unplay(&b, &u);
            if (c.stopped && depth > 1) break;
            c.stopped = 0;
            {
                unsigned long long t = tie(&c, from[i], to[i]);
                if (v > it_best || (v == it_best && t < it_tie)) { it_best = v; it_from = from[i]; it_to = to[i]; it_tie = t; }
            }
        }
        if (c.stopped && depth > 1) break;
        done_from = it_from; done_to = it_to; done_score = it_best; done_depth = depth;
        if (c.nodes >= c.budget) break;
        if (n == 1) break;
        if (done_score >= STH_WIN_SCORE - 1000 || done_score <= -STH_WIN_SCORE + 1000) break;
        if (depth >= 64) break;
    }
    free(c.tt);
    if (best_from) *best_from = done_from;
    if (best_to) *best_to = done_to;
    if (info) {
        info->nodes = c.nodes;
        info->depth = done_depth;
        info->score = done_score;
        info->stopped = c.stopped;
    }
    return 1;
}

/* THE WEAKEST PLAYER: a seeded random choice among the moves that take a piece
 * nearer the tip of its home, or among all of them when none does. */
int sth_random_forward(const struct sth_board *b, unsigned long long seed, int *best_from, int *best_to)
{
    int from[STH_LEGAL_MAX], to[STH_LEGAL_MAX], fwd[STH_LEGAL_MAX], n, i, k = 0, p, pick;
    search_init();
    if (!b || b->over) return 0;
    n = sth_legal(b, from, to, STH_LEGAL_MAX);
    if (n > STH_LEGAL_MAX) n = STH_LEGAL_MAX;
    if (n == 0) { *best_from = *best_to = -1; return 1; }
    p = home_of(b, b->to_move);
    for (i = 0; i < n; i++) if (DIST[p][to[i]] < DIST[p][from[i]]) fwd[k++] = i;
    seed = mix((seed ? seed : 1) ^ b->key);
    pick = k ? fwd[seed % (unsigned long long) k] : (int) (seed % (unsigned long long) n);
    *best_from = from[pick];
    *best_to = to[pick];
    return 1;
}
