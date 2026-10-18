/* sen_search.c - choosing a move.
 *
 * PERL-FREE, like the rest, and it reaches the board only through the table.
 *
 * THIS FILE'S SCOPE. An evaluation of a position in whole numbers, a choice
 * made without looking ahead, and a search that looks ahead through the sticks.
 *
 * THERE IS NO FLOAT HERE. A chance is a weight in sixteenths from the chance
 * table; a value is an int; and a division rounds toward zero whichever sign it
 * has, written out, because C89 leaves the rounding of a negative quotient to
 * the compiler.
 *
 * NOTHING HERE READS A CLOCK. A search is bounded in NODES, so that the same
 * position, throw and budget give the same move on every machine and under any
 * load.
 *
 * IT READS FIELDS AND NEVER A SET'S NAME: what a piece on a marked house may do
 * is read from the chains, so a term that weighs it knows the set by its table.
 */

#include <stddef.h>
#include "sen_abi.h"

static const struct sen_abi *SEN = NULL;

#define HAPPINESS 26
#define HOME_HOUSE 31

/* ---- the evaluation --------------------------------------------------------------
 *
 * In SIXTEENTHS OF A HOUSE, for one side, and it is the other side's with the
 * sign turned. The plain evaluation is progress: the house each of a side's
 * pieces stands on, a piece at home counting 31, less the same for the other
 * side. WHERE A PIECE ENDS is what counts: a move that falls into the water and
 * walks down to 15 has lost ground, and is valued so.
 *
 * One term may be added, with a weight a rule set's ladder sets: BLOCKADE, the
 * side's own runs wide enough to block with an enemy piece behind them.
 * PROTECT, STUCK and WATER were written, measured and removed: each lost ground
 * or moved nothing under both named sets (plan_game_senet/07, R3).
 */

static void sen_weights_default(struct sen_weights *w)
{
    int i;
    if (!w) return;
    w->blockade = 0;
    w->ties = SEN_TIES_LAST;
    for (i = 0; i < 6; i++) w->reserved[i] = 0;
}

static int sen_progress(const struct sen_board *b, int side)
{
    int total = (SEN->home)(b, side) * HOME_HOUSE;
    int h;
    for (h = 1; h <= SEN_HOUSES; h++)
        if ((SEN->at)(b, h) == SEN_PIECE_OF(side)) total += h;
    return total;
}

static int sen_run_len(const struct sen_board *b, int house, int *lo, int *hi)
{
    int p = (SEN->at)(b, house);
    int l = house, h = house;
    while (l > 1 && (SEN->at)(b, l - 1) == p) l--;
    while (h < SEN_HOUSES && (SEN->at)(b, h + 1) == p) h++;
    if (lo) *lo = l;
    if (hi) *hi = h;
    return h - l + 1;
}

/* BLOCKADE: own runs at least `blockade` wide with an enemy piece below them. */
static int sen_term_blockade(const struct sen_board *b, const struct sen_rules *r, int side)
{
    int me = SEN_PIECE_OF(side), enemy = SEN_PIECE_OF(SEN_OTHER(side));
    int h = 1, n = 0, lowest_enemy = 0, x;
    if (r->blockade == 0) return 0;
    for (x = 1; x <= SEN_HOUSES; x++)
        if ((SEN->at)(b, x) == enemy) { lowest_enemy = x; break; }
    if (!lowest_enemy) return 0;
    while (h <= SEN_HOUSES) {
        int lo, hi;
        if ((SEN->at)(b, h) != me) { h++; continue; }
        if (sen_run_len(b, h, &lo, &hi) >= r->blockade && lowest_enemy < lo) n++;
        h = hi + 1;
    }
    return n;
}

static int sen_evaluate(const struct sen_board *b, const struct sen_rules *r,
                        const struct sen_weights *w, int side)
{
    int enemy, v;
    if (!b || !r || (side != SEN_SIDE_LIGHT && side != SEN_SIDE_DARK)) return 0;
    enemy = SEN_OTHER(side);
    v = 16 * (sen_progress(b, side) - sen_progress(b, enemy));
    if (w && w->blockade)
        v += w->blockade * (sen_term_blockade(b, r, side) - sen_term_blockade(b, r, enemy));
    return v;
}

/* ---- a choice without looking ahead -------------------------------------------------
 *
 * Of the moves the roll allows: bear off if one does; else swap if one does;
 * else land on 26 if one does; else the move whose piece ENDS furthest on. A
 * walk down from the water ends low, and is chosen last. Where two moves are
 * alike in that, the later in the list.
 */

static int sen_ends_at(const struct sen_move *m) { return m->off ? HOME_HOUSE : m->to; }

static int sen_greedy(const struct sen_board *b, const struct sen_rules *r, int roll, int only)
{
    struct sen_move m[SEN_MOVES_MAX];
    int n = (SEN->moves)(b, r, roll, only, m, SEN_MOVES_MAX);
    int k, off = -1, swap = -1, happy = -1, furthest = -1;
    if (n <= 0) return -1;
    if (n > SEN_MOVES_MAX) n = SEN_MOVES_MAX;
    for (k = 0; k < n; k++) {
        if (m[k].off) off = k;
        if (m[k].swap && (swap < 0 || sen_ends_at(&m[k]) >= sen_ends_at(&m[swap]))) swap = k;
        if (!m[k].off && m[k].to == HAPPINESS) happy = k;
        if (furthest < 0 || sen_ends_at(&m[k]) >= sen_ends_at(&m[furthest])) furthest = k;
    }
    if (off >= 0) return off;
    if (swap >= 0) return swap;
    if (happy >= 0) return happy;
    return furthest;
}

/* ---- the search ---------------------------------------------------------------------
 *
 * Expectiminimax. A position's value is the sum, over the five rolls the sticks
 * can make, of that roll's weight in sixteenths times the value of the best move
 * it allows, over sixteen. "Best" is the highest for the side the search is for
 * and the lowest for the other.
 *
 * THE VALUE IS ALWAYS FOR ONE SIDE, fixed where the search starts, and whether
 * a level takes the highest or the lowest is asked of the board each time. It is
 * NOT a sign turned on every ply: after a 1, 4 or 5 the same side throws again,
 * and a turned sign is wrong on exactly those plies.
 *
 * DEPTH COUNTS THROWS. A throw that allows nothing is a forfeit and spends a
 * level like any other, so a chain of extra throws is bounded however long the
 * sticks keep giving. THE BOUND PIECE TRAVELS WITH THE SEARCH, not in the
 * board: after a move onto 26 under throw_on_26 the next throw moves that piece
 * alone.
 */

struct search {
    const struct sen_rules *rules;
    const struct sen_weights *weights;
    int root;
    unsigned long long nodes;
    unsigned long long budget;
    int unbounded;
    int stopped;
};

static int sen_value(struct search *s, struct sen_board *b, int depth, int only);

static int sen_best(struct search *s, struct sen_board *b, int roll, int depth, int only)
{
    struct sen_move m[SEN_MOVES_MAX];
    struct sen_undo u;
    int n = (SEN->moves)(b, s->rules, roll, only, m, SEN_MOVES_MAX);
    int k, v, chosen = 0, ours;

    if (n <= 0) {
        (SEN->forfeit)(b, roll, &u);
        v = sen_value(s, b, depth - 1, 0);
        (SEN->unapply)(b, &u);
        return v;
    }
    if (n > SEN_MOVES_MAX) n = SEN_MOVES_MAX;
    ours = (SEN->side)(b) == s->root;
    for (k = 0; k < n; k++) {
        (SEN->apply)(b, s->rules, &m[k], &u);
        v = sen_value(s, b, depth - 1, u.bound);
        (SEN->unapply)(b, &u);
        if (s->stopped) return 0;
        if (k == 0 || (ours ? v > chosen : v < chosen)) chosen = v;
    }
    return chosen;
}

static int sen_value(struct search *s, struct sen_board *b, int depth, int only)
{
    int i, roll, weight, denominator, sum = 0, winner;

    if (!s->unbounded && s->nodes >= s->budget) { s->stopped = 1; return 0; }
    s->nodes++;

    winner = (SEN->winner)(b);
    if (winner >= 0) return winner == s->root ? SEN_WIN + depth : -(SEN_WIN + depth);
    if ((SEN->status)(b) != SEN_ONGOING) return 0;
    if (depth <= 0) return sen_evaluate(b, s->rules, s->weights, s->root);

    for (i = 0; i < (SEN->chance_count)(); i++) {
        (SEN->chance)(i, &roll, &weight, &denominator);
        sum += weight * sen_best(s, b, roll, depth, only);
        if (s->stopped) return 0;
    }
    return sum >= 0 ? sum / denominator : -((-sum) / denominator);
}

/* The value of a position BEFORE its throw, for `side`, `depth` throws deep.
 * For tests whose answer is worked by hand. */
static int sen_expect(const struct sen_board *board, const struct sen_rules *r,
                      const struct sen_weights *w, int only, int depth, int side)
{
    struct sen_weights plain;
    struct sen_board *b;
    struct search s;
    int v;
    if (!board || !r || !(SEN->rules_ok)(r)) return 0;
    if (!w) { sen_weights_default(&plain); w = &plain; }
    b = (SEN->board_copy)(board);
    if (!b) return 0;
    s.rules = r;
    s.weights = w;
    s.root = side;
    s.nodes = 0;
    s.budget = 0;
    s.unbounded = 1;
    s.stopped = 0;
    v = sen_value(&s, b, depth, only);
    (SEN->board_drop)(b);
    return v;
}

static int sen_search(const struct sen_board *board, const struct sen_rules *r, int roll, int only,
                      const struct sen_weights *weights, unsigned long long budget, int max_depth,
                      struct sen_search_info *info)
{
    struct sen_weights plain;
    struct sen_search_info local;
    struct sen_move m[SEN_MOVES_MAX];
    struct sen_undo u;
    struct sen_board *b;
    struct search s;
    int n, depth, k, chosen = 0;

    if (!info) info = &local;
    info->nodes = 0;
    info->depth = 0;
    info->value = 0;
    info->stopped = 0;

    if (!board || !r || !(SEN->rules_ok)(r)) return -1;
    if (!weights) { sen_weights_default(&plain); weights = &plain; }
    if ((SEN->status)(board) != SEN_ONGOING) return -1;

    b = (SEN->board_copy)(board);
    if (!b) return -1;
    n = (SEN->moves)(b, r, roll, only, m, SEN_MOVES_MAX);
    if (n <= 0) { (SEN->board_drop)(b); return -1; }
    if (n > SEN_MOVES_MAX) n = SEN_MOVES_MAX;
    if (max_depth <= 0 || max_depth > SEN_DEPTH_MAX) max_depth = SEN_DEPTH_MAX;

    s.rules = r;
    s.weights = weights;
    s.root = (SEN->side)(b);
    s.nodes = 0;
    s.budget = budget;

    for (depth = 1; depth <= max_depth; depth++) {
        int best_k = 0, best_v = 0, v;
        s.unbounded = (depth == 1);
        s.stopped = 0;
        for (k = 0; k < n; k++) {
            (SEN->apply)(b, r, &m[k], &u);
            v = sen_value(&s, b, depth - 1, u.bound);
            (SEN->unapply)(b, &u);
            if (s.stopped) break;
            if (k == 0 || (weights->ties == SEN_TIES_LAST ? v >= best_v : v > best_v)) {
                best_v = v;
                best_k = k;
            }
        }
        if (s.stopped) { info->stopped = 1; break; }
        chosen = best_k;
        info->depth = depth;
        info->value = best_v;
        if (n == 1) break;
        if (s.nodes >= s.budget) break;
    }

    info->nodes = s.nodes;
    (SEN->board_drop)(b);
    return chosen;
}

/* ---- the table ------------------------------------------------------------------- */

void sen_search_install(struct sen_abi *t)
{
    SEN = t;
    t->weights_default = sen_weights_default;
    t->evaluate        = sen_evaluate;
    t->greedy          = sen_greedy;
    t->search          = sen_search;
    t->expect          = sen_expect;
}
