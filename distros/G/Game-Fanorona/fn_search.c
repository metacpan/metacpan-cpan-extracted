/* fn_search.c - choosing a move: an evaluation, and a search bounded in nodes.
 *
 * PERL-FREE, as the other files are, and INTEGER ONLY: no float is declared
 * here and no clock is read. The same position, budget and seed give the same
 * move on every machine.
 *
 * THE SEARCH WALKS STEPS, NOT MOVES. A position can have thousands of whole
 * moves and never more than a couple of hundred steps, so a node here is a
 * position, possibly with a chain open, and its children are the steps that
 * may be made next. Inside a chain the same side is still to move, so the
 * score is not negated there; and stopping is a child like any other.
 *
 * DEPTH IS COUNTED IN WHOLE MOVES. A chain of five steps costs one. The
 * depth goes down when the turn passes and at no other time.
 *
 * AT THE END OF ITS DEPTH THE SEARCH DOES NOT SCORE A POSITION IN WHICH A STONE
 * CAN BE TAKEN. Taking is compulsory, so that is not a position anyone may sit
 * in. But it does not SEARCH the captures either: in the opening they cascade
 * for twenty moves with a choice at every step and a stop after every step,
 * and a search that followed all of it never came back from its first move.
 * It SETTLES the position instead: each side in turn makes the capture that
 * takes most, step by step, until the side to move has only quiet moves or a
 * few moves have been made, and that is the position scored. It is one line
 * and not a tree, so it costs a handful of steps; it is a guess at how the
 * exchange comes out and not a proof, and it is what stops the search
 * counting a stone that is about to be taken.
 */

#include <stdlib.h>
#include <string.h>
#include "fn_abi.h"

static const struct fn_abi *T = NULL;

/* ---- the weights --------------------------------------------------------------- */

static void fn_weights_default(struct fn_weights *w)
{
    if (!w) return;
    memset(w, 0, sizeof(*w));
    /* MEASURED, each term at 2,000 games against the terms already in, and
     * kept only if it earned three standard deviations. Room to move and
     * standing towards the centre did. Standing on a strong point did by
     * itself and did NOT once the other two were in, so it is here to be
     * given a weight and is given none. */
    w->stone  = 100;
    w->strong = 0;
    w->centre = 2;
    w->room   = 2;
}

static const struct fn_weights *weights_or_default(const struct fn_weights *w)
{
    static struct fn_weights def;
    static int ready = 0;
    if (w) return w;
    if (!ready) { fn_weights_default(&def); ready = 1; }
    return &def;
}

/* ---- the evaluation --------------------------------------------------------------
 *
 * For White. Each term is counted for White's stones and against Black's.
 */

static int fn_evaluate(const struct fn_board *b, const struct fn_weights *w)
{
    int cols = (T->cols)(b), rows = (T->rows)(b);
    int mid_file = cols / 2, mid_rank = rows / 2;
    int rank, file, d, score = 0;
    w = weights_or_default(w);
    for (rank = 0; rank < rows; rank++) {
        for (file = 0; file < cols; file++) {
            int sq = (T->square_of)(file, rank);
            int stone = (T->at)(b, sq);
            int worth, df, dr;
            if (!FN_IS_STONE(stone)) continue;
            worth = w->stone;
            if (w->strong && (T->is_strong)(sq)) worth += w->strong;
            if (w->centre) {
                df = file > mid_file ? file - mid_file : mid_file - file;
                dr = rank > mid_rank ? rank - mid_rank : mid_rank - rank;
                worth += w->centre * ((mid_file - df) + (mid_rank - dr));
            }
            if (w->room) {
                for (d = 0; d < FN_DIRS; d++) {
                    int to = (T->next)(b, sq, d);
                    if (to >= 0 && (T->at)(b, to) == FN_EMPTY) worth += w->room;
                }
            }
            score += stone == FN_WHITE ? worth : -worth;
        }
    }
    return score;
}

/* ---- the table of positions already searched ------------------------------------ */

#define TT_EXACT 0
#define TT_LOWER 1
#define TT_UPPER 2

struct tt_entry {
    unsigned long long key;
    int score;
    short depth;
    unsigned char flag;
    unsigned char used;
    short from;
    unsigned char dir;
    unsigned char kind;
};

#define FN_INF (FN_WIN_SCORE + 1000)
#define FN_DEPTH_MAX 60

/* how deep one line may run in STEPS: the bound on the recursion */
#define FN_LINE_STEPS 512

struct ctx {
    struct fn_game *g;
    const struct fn_weights *w;
    unsigned long long nodes, budget, seed;
    int may_stop;
    int stopped;
    struct tt_entry *tt;
    size_t mask;
};

static unsigned long long mix(unsigned long long z)
{
    z += 0x9E3779B97F4A7C15ULL;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

/* THE ORDER STEPS ARE TRIED IN: the step the table remembers, then the steps
 * that take most. It changes how many nodes a search costs and never which
 * move a search to a fixed depth returns, apart from the choice among moves of
 * equal score, which `salt` settles at the root and a test holds to that. */
static void order_steps(struct fn_step *list, int n, const struct tt_entry *e, unsigned long long salt)
{
    int key[FN_STEPS_MAX];
    int i, j;
    for (i = 0; i < n; i++) {
        int k = list[i].taken_n * 1000;
        if (e && e->used && e->from == list[i].from && e->dir == list[i].dir && e->kind == list[i].kind) k += 100000;
        if (salt) {
            unsigned long long id = ((unsigned long long) list[i].from << 8) | ((unsigned long long) list[i].dir << 4) | (unsigned long long) list[i].kind;
            k += (int) (mix(salt ^ (id * 0x100000001B3ULL)) & 0xFF);
        }
        key[i] = k;
    }
    for (i = 1; i < n; i++) {
        struct fn_step s = list[i];
        int k = key[i];
        for (j = i - 1; j >= 0 && key[j] < k; j--) { list[j + 1] = list[j]; key[j + 1] = key[j]; }
        list[j + 1] = s; key[j + 1] = k;
    }
}

/* A finished game, scored for the side to move. */
static int score_of_end(const struct ctx *c, int side, int ply)
{
    int winner = (T->game_winner)(c->g);
    if (!winner) return 0;
    return winner == side ? FN_WIN_SCORE - ply : -(FN_WIN_SCORE - ply);
}

/* THE SETTLING. From a position between moves in which the side to move can
 * take: play the largest capture, step by step, for each side in turn, until
 * nobody can take or FN_SETTLE_MOVES moves have been made; score what is left
 * for the side that was to move at the start; and take it all back. */
#define FN_SETTLE_MOVES 6

/* what an ending met while settling is worth: more than any count of stones,
 * and well short of the scores that mean a win has been proved */
#define FN_SETTLED_WIN 20000

static int settle(struct ctx *c)
{
    struct fn_step list[FN_STEPS_MAX];
    int side = (T->side)((T->game_board)(c->g));
    int made = 0, moves = 0, score;
    for (;;) {
        const struct fn_board *b = (T->game_board)(c->g);
        int n, i, pick = 0;
        if ((T->game_outcome)(c->g) != FN_ONGOING) break;
        n = (T->game_steps)(c->g, list, FN_STEPS_MAX);
        if (n > FN_STEPS_MAX) n = FN_STEPS_MAX;
        if (n == 0) break;
        if ((T->chain_at)(b) < 0) {
            if (list[0].kind == FN_PAIKA || moves >= FN_SETTLE_MOVES) break;
            moves++;
        }
        for (i = 1; i < n; i++) if (list[i].taken_n > list[pick].taken_n) pick = i;
        (T->game_step)(c->g, list[pick].from, list[pick].dir, list[pick].kind, NULL);
        made++;
        c->nodes++;
    }
    if ((T->game_outcome)(c->g) == FN_ONGOING && (T->chain_at)((T->game_board)(c->g)) >= 0) {
        /* the cap fell in the middle of a chain: end the move where it is */
        (T->game_stop)(c->g);
        made++;
    }
    if ((T->game_outcome)(c->g) != FN_ONGOING) {
        /* A GAME THAT ENDS WHILE SETTLING HAS NOT BEEN PROVED TO END THAT WAY.
         * The settling is one line of largest captures, and where two captures
         * are as large as each other it takes the first; the other may be the
         * one that wins. So this is scored as very good or very bad and NEVER
         * as a win seen to its end, which would stop the search looking any
         * deeper and did, once, make it throw away a won game on the first
         * iteration. Scored for the side that was to move when the settling
         * began, whoever is to move now. */
        int winner = (T->game_winner)(c->g);
        score = !winner ? 0 : winner == side ? FN_SETTLED_WIN : -FN_SETTLED_WIN;
    }
    else {
        score = fn_evaluate((T->game_board)(c->g), c->w);
        if (side != FN_WHITE) score = -score;
    }
    while (made-- > 0) (T->game_undo)(c->g);
    return score;
}

/* One position. `line`, when it is not NULL, receives the rest of the move the
 * side to move should make from here: the caller is that same side, part way
 * through choosing. A node asked for a line never takes its answer from the
 * table, because the table remembers a score and one step and not a line. */
static int node(struct ctx *c, int depth, int alpha, int beta, int ply, struct fn_move *line)
{
    const struct fn_board *b = (T->game_board)(c->g);
    struct fn_step list[FN_STEPS_MAX];
    struct fn_move child;
    struct tt_entry *e = NULL;
    unsigned long long key = 0;
    int side = (T->side)(b);
    int in_chain = (T->chain_at)(b) >= 0;
    int n, i, best = -FN_INF, alpha0 = alpha, best_i = -1;

    if (line) { line->n = 0; line->from = -1; line->taken = 0; }

    c->nodes++;
    if (c->may_stop && c->nodes >= c->budget) c->stopped = 1;
    if (c->stopped) return 0;

    if ((T->game_outcome)(c->g) != FN_ONGOING) return score_of_end(c, side, ply);

    n = (T->game_steps)(c->g, list, FN_STEPS_MAX);
    if (n > FN_STEPS_MAX) n = FN_STEPS_MAX;

    if (!in_chain) {
        /* the obligation makes a list all captures or all paikas */
        int can_take = n > 0 && list[0].kind != FN_PAIKA;
        if (depth <= 0 || ply >= FN_LINE_STEPS) {
            int s;
            if (can_take) return settle(c);
            s = fn_evaluate(b, c->w);
            return side == FN_WHITE ? s : -s;
        }
        key = (T->key)(b);
        if (c->tt) {
            e = &c->tt[(size_t) key & c->mask];
            if (!line && e->used && e->key == key && e->depth >= depth) {
                if (e->flag == TT_EXACT) return e->score;
                if (e->flag == TT_LOWER && e->score > alpha) alpha = e->score;
                if (e->flag == TT_UPPER && e->score < beta)  beta = e->score;
                if (alpha >= beta) return e->score;
            }
            if (e->key != key) e = NULL;
        }
    }

    order_steps(list, n, e, (ply == 0 && !in_chain) ? c->seed : 0);
    if (c->tt && !in_chain) e = &c->tt[(size_t) key & c->mask];

    if (in_chain) {
        /* STOPPING IS A MOVE. It ends this side's move here. */
        int s;
        (T->game_stop)(c->g);
        s = -node(c, depth - 1, -beta, -alpha, ply + 1, NULL);
        (T->game_undo)(c->g);
        if (c->stopped) return 0;
        best = s;
        if (best > alpha) alpha = best;
    }

    for (i = 0; i < n && alpha < beta; i++) {
        int s, why;
        (T->game_step)(c->g, list[i].from, list[i].dir, list[i].kind, &why);
        if ((T->chain_at)((T->game_board)(c->g)) >= 0) {
            /* the same side goes on: no negation, and no depth spent */
            s = node(c, depth, alpha, beta, ply + 1, line ? &child : NULL);
        }
        else {
            s = -node(c, depth - 1, -beta, -alpha, ply + 1, NULL);
            child.n = 0;
        }
        (T->game_undo)(c->g);
        if (c->stopped) return 0;
        if (s > best) {
            best = s;
            best_i = i;
            if (line) {
                int k;
                line->from = list[i].from;
                line->n = 1;
                line->dir[0] = (unsigned char) list[i].dir;
                line->kind[0] = (unsigned char) list[i].kind;
                line->taken = list[i].taken_n;
                for (k = 0; k < child.n && line->n < FN_CHAIN_MAX; k++) {
                    line->dir[line->n] = child.dir[k];
                    line->kind[line->n] = child.kind[k];
                    line->n++;
                }
            }
        }
        if (best > alpha) alpha = best;
    }

    /* A score that is a win or a loss carries the distance from the ROOT, which
     * is the wrong distance for the same position met by another road, so
     * those are left out of the table. So is anything found inside a chain:
     * the table is for positions, and the middle of a move is not one. */
    if (e && !in_chain && best > -(FN_WIN_SCORE - 1000) && best < FN_WIN_SCORE - 1000) {
        e->used = 1;
        e->key = key;
        e->score = best;
        e->depth = (short) depth;
        e->flag = (unsigned char) (best <= alpha0 ? TT_UPPER : best >= beta ? TT_LOWER : TT_EXACT);
        if (best_i >= 0) {
            e->from = (short) list[best_i].from;
            e->dir = (unsigned char) list[best_i].dir;
            e->kind = (unsigned char) list[best_i].kind;
        }
    }
    return best;
}

/* THE MOVE RETURNED IS THE BEST OF THE LAST ITERATION THAT FINISHED. An
 * iteration cut short by the budget has looked at some of the moves and not
 * others, and its "best so far" is the best of an arbitrary subset.
 *
 * The first iteration is never cut short, so there is always a move to
 * return.
 */
static int fn_search(const struct fn_game *game, const struct fn_weights *w,
                     unsigned long long budget, unsigned long long seed, int max_depth,
                     struct fn_move *best, struct fn_search_info *info)
{
    struct ctx c;
    struct fn_move line, kept;
    int depth, done = 0, best_score = 0;
    size_t size = 1024;

    if (info) memset(info, 0, sizeof(*info));
    if (best) { memset(best, 0, sizeof(*best)); best->from = -1; }
    if (!game || (T->game_outcome)(game) != FN_ONGOING) return 0;

    memset(&c, 0, sizeof(c));
    c.g = (T->game_copy)(game);
    if (!c.g) return 0;
    c.w = weights_or_default(w);
    c.budget = budget;
    c.seed = seed ? seed : 1;

    while (size < budget && size < ((size_t) 1 << 20)) size <<= 1;
    c.tt = (struct tt_entry *) calloc(size, sizeof(struct tt_entry));
    c.mask = size - 1;

    if (max_depth <= 0 || max_depth > FN_DEPTH_MAX) max_depth = FN_DEPTH_MAX;
    memset(&kept, 0, sizeof(kept));
    kept.from = -1;

    for (depth = 1; depth <= max_depth; depth++) {
        int s;
        c.may_stop = depth > 1;
        s = node(&c, depth, -FN_INF, FN_INF, 0, &line);
        if (c.stopped) break;
        kept = line;
        best_score = s;
        done = depth;
        /* a win or a loss that is forced has been seen to its end */
        if (best_score > FN_WIN_SCORE - 1000 || best_score < -(FN_WIN_SCORE - 1000)) break;
        if (c.nodes >= c.budget) break;
    }

    if (best) *best = kept;
    if (info) {
        info->nodes = c.nodes;
        info->depth = done;
        info->score = best_score;
        info->stopped = c.stopped;
    }
    free(c.tt);
    (T->game_drop)(c.g);
    return 1;
}

/* ---- installed into the table by fn_engine.c -------------------------------------- */

void fn_search_install(struct fn_abi *t);

void fn_search_install(struct fn_abi *t)
{
    T = t;
    t->weights_default = fn_weights_default;
    t->evaluate        = fn_evaluate;
    t->search          = fn_search;
}
