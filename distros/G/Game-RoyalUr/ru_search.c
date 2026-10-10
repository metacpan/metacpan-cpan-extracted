/* ru_search.c - choosing a move.
 *
 * PERL-FREE, like the rest, and it reaches the board only through the table.
 *
 * THIS FILE'S SCOPE. An evaluation of a position in whole numbers, a choice
 * made without looking ahead, and a search that looks ahead through the dice.
 *
 * THERE IS NO FLOAT HERE. A chance is a weight over a denominator, both whole
 * numbers from the chance table; a value is an int; and a division rounds
 * toward zero whichever sign it has, so that a position and its mirror are
 * valued alike.
 *
 * NOTHING HERE READS A CLOCK. A search is bounded in NODES, so that the same
 * position, roll and budget give the same move on every machine and under any
 * load.
 */

#include <stddef.h>
#include "ru_abi.h"

static const struct ru_abi *RU = NULL;

/* ---- the evaluation --------------------------------------------------------------
 *
 * In SIXTEENTHS OF A STEP, for one side, and it is the other side's with the
 * sign turned.
 *
 * The plain evaluation is progress: every step each of a side's pieces has
 * taken, a piece at home counting one more than the route is long and a piece
 * in hand counting nothing, less the same for the other side.
 *
 * Three terms may be added to it, each with a weight that is 0 unless a caller
 * sets it.
 */

static void ru_weights_default(struct ru_weights *w)
{
    int i;
    if (!w) return;
    w->exposed = 0;
    w->rosette = 0;
    w->entry = 0;
    for (i = 0; i < 5; i++) w->reserved[i] = 0;
}

static int progress(const struct ru_board *b, const struct ru_rules *r, int side)
{
    int len = (RU->route_len)(r->route);
    int total = (RU->home)(b, side) * (len + 1);
    int step;
    for (step = 1; step <= len; step++)
        if ((RU->at)(b, (RU->route_cell)(r->route, side, step)) == RU_PIECE_OF(side))
            total += step;
    return total;
}

/* The chance, in sixteenths, that the dice roll exactly `distance`. */
static int chance16(const struct ru_rules *r, int distance)
{
    int n = (RU->chance_count)(r->dice, r->zero_rolls);
    int i, roll, weight, denominator;
    for (i = 0; i < n; i++) {
        (RU->chance)(r->dice, r->zero_rolls, i, &roll, &weight, &denominator);
        if (roll == distance) return weight * 16 / denominator;
    }
    return 0;
}

/* What a side stands to lose to the enemy's next roll: for each of its pieces
 * an enemy piece could land on, the chance of the roll that does it times the
 * steps the piece would be sent back. In sixteenths of a step.
 *
 * A piece is asked of ITS OWN step and its attacker of the ENEMY's step for
 * the same cell, which on the long route is a different number. */
static int exposure(const struct ru_board *b, const struct ru_rules *r, int side)
{
    int len = (RU->route_len)(r->route);
    int enemy = RU_OTHER(side);
    int total = 0, step, distance;

    for (step = 1; step <= len; step++) {
        int cell = (RU->route_cell)(r->route, side, step);
        int theirs, chance = 0;
        if ((RU->at)(b, cell) != RU_PIECE_OF(side)) continue;
        if (!(RU->route_shared)(r->route, cell)) continue;
        if (r->safe_rosettes && (RU->is_rosette)(cell)) continue;

        theirs = (RU->route_step)(r->route, enemy, cell);
        for (distance = 1; distance <= RU_ROLL_MAX; distance++) {
            int from = theirs - distance;
            if (from < 0) continue;
            if (from == 0) {
                if ((RU->hand)(b, enemy) > 0) chance += chance16(r, distance);
            }
            else if ((RU->at)(b, (RU->route_cell)(r->route, enemy, from)) == RU_PIECE_OF(enemy)) {
                chance += chance16(r, distance);
            }
        }
        if (chance > 16) chance = 16;
        total += chance * step;
    }
    return total;
}

/* A side's pieces standing on rosettes both sides visit. */
static int rosettes_held(const struct ru_board *b, const struct ru_rules *r, int side)
{
    int len = (RU->route_len)(r->route);
    int n = 0, step;
    for (step = 1; step <= len; step++) {
        int cell = (RU->route_cell)(r->route, side, step);
        if ((RU->at)(b, cell) == RU_PIECE_OF(side)
            && (RU->is_rosette)(cell) && (RU->route_shared)(r->route, cell)) n++;
    }
    return n;
}

static void standard_rules(struct ru_rules *r) { (RU->rules_named)(RU_RULES_FINKEL, r); }

static int ru_evaluate(const struct ru_board *b, const struct ru_rules *rules,
                       const struct ru_weights *w, int side)
{
    struct ru_rules standard;
    int enemy, v;
    if (!b || (side != RU_SIDE_LIGHT && side != RU_SIDE_DARK)) return 0;
    if (!rules) { standard_rules(&standard); rules = &standard; }
    if (!(RU->rules_ok)(rules)) return 0;
    enemy = RU_OTHER(side);

    v = 16 * (progress(b, rules, side) - progress(b, rules, enemy));
    if (w && w->exposed)
        v -= w->exposed * (exposure(b, rules, side) - exposure(b, rules, enemy)) / 16;
    if (w && w->rosette)
        v += w->rosette * (rosettes_held(b, rules, side) - rosettes_held(b, rules, enemy));
    if (w && w->entry)
        v -= w->entry * ((RU->hand)(b, side) - (RU->hand)(b, enemy));
    return v;
}

/* ---- a choice without looking ahead -------------------------------------------------
 *
 * Of the moves the roll allows: one that captures, if any does; else one that
 * lands on a rosette, if any does; else the piece furthest along. Where two
 * moves are alike in that, the one further along.
 */

static int ru_greedy(const struct ru_board *b, const struct ru_rules *rules, int roll)
{
    struct ru_move m[RU_MOVES_MAX];
    int n = (RU->moves)(b, rules, roll, m, RU_MOVES_MAX);
    int k, capture = -1, rosette = -1;
    if (n <= 0) return -1;
    for (k = 0; k < n; k++) {
        if (m[k].captures) capture = k;
        if (m[k].rosette)  rosette = k;
    }
    if (capture >= 0) return capture;
    if (rosette >= 0) return rosette;
    return n - 1;
}

/* ---- the search ---------------------------------------------------------------------
 *
 * Expectiminimax. A position's value is the sum, over every roll the dice can
 * make, of that roll's weight times the value of the best move it allows,
 * over the denominator. "Best" is the highest for the side the search is for
 * and the lowest for the other.
 *
 * THE VALUE IS ALWAYS FOR ONE SIDE, fixed where the search starts, and whether
 * a level takes the highest or the lowest is asked of the board each time. It
 * is NOT a sign turned on every ply: after a rosette the same side moves
 * again, and a turned sign is wrong on exactly those plies.
 *
 * A roll that allows nothing is a level like any other: the turn is lost, and
 * the search goes on from the other side.
 */

struct search {
    const struct ru_rules *rules;
    const struct ru_weights *weights;
    int root;
    unsigned long long nodes;
    unsigned long long budget;
    int unbounded;                 /* the first depth always finishes */
    int stopped;
};

static int value(struct search *s, struct ru_board *b, int depth);

static int best(struct search *s, struct ru_board *b, int roll, int depth)
{
    struct ru_move m[RU_MOVES_MAX];
    struct ru_undo u;
    int n = (RU->moves)(b, s->rules, roll, m, RU_MOVES_MAX);
    int k, v, chosen = 0, ours;

    if (n <= 0) {
        (RU->forfeit)(b, &u);
        v = value(s, b, depth - 1);
        (RU->unapply)(b, &u);
        return v;
    }
    ours = (RU->side)(b) == s->root;
    for (k = 0; k < n; k++) {
        (RU->apply)(b, s->rules, &m[k], &u);
        v = value(s, b, depth - 1);
        (RU->unapply)(b, &u);
        if (s->stopped) return 0;
        if (k == 0 || (ours ? v > chosen : v < chosen)) chosen = v;
    }
    return chosen;
}

static int value(struct search *s, struct ru_board *b, int depth)
{
    int rolls, i, roll, weight, denominator = 1, sum = 0, winner;

    if (!s->unbounded && s->nodes >= s->budget) { s->stopped = 1; return 0; }
    s->nodes++;

    winner = (RU->winner)(b, s->rules);
    if (winner >= 0) return winner == s->root ? RU_WIN + depth : -(RU_WIN + depth);
    if ((RU->status)(b, s->rules) != RU_ONGOING) return 0;
    if (depth <= 0) return ru_evaluate(b, s->rules, s->weights, s->root);

    rolls = (RU->chance_count)(s->rules->dice, s->rules->zero_rolls);
    for (i = 0; i < rolls; i++) {
        (RU->chance)(s->rules->dice, s->rules->zero_rolls, i, &roll, &weight, &denominator);
        sum += weight * best(s, b, roll, depth);
        if (s->stopped) return 0;
    }
    return sum / denominator;
}

static int ru_search(const struct ru_board *board, const struct ru_rules *rules, int roll,
                     const struct ru_weights *weights, unsigned long long budget, int max_depth,
                     struct ru_search_info *info)
{
    struct ru_rules standard;
    struct ru_weights plain;
    struct ru_search_info local;
    struct ru_move m[RU_MOVES_MAX];
    struct ru_undo u;
    struct ru_board *b;
    struct search s;
    int n, depth, k, chosen = 0;

    if (!info) info = &local;
    info->nodes = 0;
    info->depth = 0;
    info->value = 0;
    info->stopped = 0;

    if (!board) return -1;
    if (!rules) { standard_rules(&standard); rules = &standard; }
    if (!weights) { ru_weights_default(&plain); weights = &plain; }
    if ((RU->status)(board, rules) != RU_ONGOING) return -1;

    b = (RU->board_copy)(board);
    if (!b) return -1;
    n = (RU->moves)(b, rules, roll, m, RU_MOVES_MAX);
    if (n <= 0) { (RU->board_drop)(b); return -1; }
    if (max_depth <= 0 || max_depth > RU_DEPTH_MAX) max_depth = RU_DEPTH_MAX;

    s.rules = rules;
    s.weights = weights;
    s.root = (RU->side)(b);
    s.nodes = 0;
    s.budget = budget;

    /* MOVES OF EQUAL VALUE GO TO THE LAST OF THEM, which is the piece furthest
     * along. That is a measurement and not a taste: with ties to the first,
     * the piece least far along, a search one level deep lost 386 games in 400
     * to the choice made without looking ahead (plan_game_royalur/07). */
    for (depth = 1; depth <= max_depth; depth++) {
        int best_k = 0, best_v = 0, v;
        s.unbounded = (depth == 1);
        s.stopped = 0;
        for (k = 0; k < n; k++) {
            (RU->apply)(b, rules, &m[k], &u);
            v = value(&s, b, depth - 1);
            (RU->unapply)(b, &u);
            if (s.stopped) break;
            if (k == 0 || v >= best_v) { best_v = v; best_k = k; }
        }
        if (s.stopped) { info->stopped = 1; break; }
        chosen = best_k;
        info->depth = depth;
        info->value = best_v;
        if (n == 1) break;
        if (s.nodes >= s.budget) break;
    }

    info->nodes = s.nodes;
    (RU->board_drop)(b);
    return chosen;
}

/* ---- the table ------------------------------------------------------------------- */

void ru_search_install(struct ru_abi *t)
{
    RU = t;
    t->weights_default = ru_weights_default;
    t->evaluate        = ru_evaluate;
    t->greedy          = ru_greedy;
    t->search          = ru_search;
}
