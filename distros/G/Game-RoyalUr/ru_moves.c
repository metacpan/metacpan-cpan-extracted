/* ru_moves.c - what a roll allows.
 *
 * PERL-FREE, like ru_engine.c, and it reaches the board only through the
 * table: this file does not know how a position is stored.
 *
 * THIS FILE'S SCOPE. The rule set as a struct, the moves a roll allows the
 * side to move, a count of the positions a rule set has, and then a move MADE:
 * apply and its undo, the forfeit, whose turn it is afterwards, and how a game
 * ends.
 */

#include <stddef.h>
#include "ru_abi.h"

static const struct ru_abi *RU = NULL;

/* ---- the rule set ------------------------------------------------------------- */

static int ru_rules_named(int name, struct ru_rules *r)
{
    int i;
    if (!r) return 0;
    for (i = 0; i < 4; i++) r->reserved[i] = 0;
    if (name == RU_RULES_FINKEL) {
        r->route = RU_ROUTE_SHORT;
        r->dice = 4;
        r->zero_rolls = 0;
        r->safe_rosettes = 1;
        r->pieces = 7;
        return 1;
    }
    if (name == RU_RULES_MASTERS) {
        r->route = RU_ROUTE_LONG;
        r->dice = 3;
        r->zero_rolls = 4;
        r->safe_rosettes = 0;
        r->pieces = 7;
        return 1;
    }
    return 0;
}

static int ru_rules_ok(const struct ru_rules *r)
{
    if (!r) return 0;
    if (r->route != RU_ROUTE_SHORT && r->route != RU_ROUTE_LONG) return 0;
    if (r->dice != 3 && r->dice != 4) return 0;
    if (r->zero_rolls != 0 && r->zero_rolls != 4) return 0;
    if (r->safe_rosettes != 0 && r->safe_rosettes != 1) return 0;
    if (r->pieces < 1 || r->pieces > RU_PIECES_MAX) return 0;
    return 1;
}

/* ---- the generator --------------------------------------------------------------
 *
 * The candidates are the hand, when it holds a piece, and then the side's
 * pieces in ascending order of STEP. That order is part of the contract.
 *
 * For each, the landing step is the step it stands on plus the roll, and:
 *
 *   past home                          no move: a piece leaves on an exact roll
 *   home                               a move
 *   a cell holding the side's own      no move
 *   an enemy on a rosette that is safe no move
 *   an enemy anywhere else             a move, and a capture
 *   an empty cell                      a move
 *
 * NOTHING BETWEEN THE TWO STEPS IS LOOKED AT. A piece passes over any piece of
 * either side, an enemy on a safe rosette included: the rosette refuses a
 * landing, it does not close the route.
 *
 * THE LANDING CELL IS ASKED OF THE MOVER'S ROUTE, and what stands on it is
 * asked of the CELL. On the long route one cell is two different steps, one
 * for each side, so "is there an enemy on my step 12" is not a question about
 * the enemy's step 12.
 */

static int consider(const struct ru_board *b, const struct ru_rules *r, int side,
                    int from_step, int roll, struct ru_move *m)
{
    int len = (RU->route_len)(r->route);
    int to = from_step + roll;
    int cell, standing;

    if (to > len + 1) return 0;

    m->from_step = from_step;
    m->to_step = to;
    m->from_cell = from_step == 0 ? -1 : (RU->route_cell)(r->route, side, from_step);
    m->to_cell = -1;
    m->captures = 0;
    m->rosette = 0;
    m->home = 0;
    m->reserved[0] = m->reserved[1] = 0;

    if (to == len + 1) {
        m->home = 1;
        return 1;
    }

    cell = (RU->route_cell)(r->route, side, to);
    standing = (RU->at)(b, cell);
    if (standing == RU_PIECE_OF(side)) return 0;
    if (standing == RU_PIECE_OF(RU_OTHER(side))) {
        if (r->safe_rosettes && (RU->is_rosette)(cell)) return 0;
        m->captures = 1;
    }
    m->to_cell = cell;
    m->rosette = (RU->is_rosette)(cell) ? 1 : 0;
    return 1;
}

static int ru_moves(const struct ru_board *b, const struct ru_rules *rules, int roll,
                    struct ru_move *out, int max)
{
    struct ru_rules standard;
    struct ru_move m;
    int side, len, step, n = 0;

    if (!b) return -1;
    if (roll < 0 || roll > RU_ROLL_MAX) return -1;
    if (!rules) { ru_rules_named(RU_RULES_FINKEL, &standard); rules = &standard; }
    if (!ru_rules_ok(rules)) return -1;
    if (roll == 0) return 0;

    side = (RU->side)(b);
    len = (RU->route_len)(rules->route);

    if ((RU->hand)(b, side) > 0 && consider(b, rules, side, 0, roll, &m)) {
        if (out && n < max) out[n] = m;
        n++;
    }
    for (step = 1; step <= len; step++) {
        int cell = (RU->route_cell)(rules->route, side, step);
        if ((RU->at)(b, cell) != RU_PIECE_OF(side)) continue;
        if (!consider(b, rules, side, step, roll, &m)) continue;
        if (out && n < max) out[n] = m;
        n++;
    }
    return n;
}

/* ---- how many positions a rule set has -------------------------------------------
 *
 * Every way of standing each side's pieces on cells of ITS OWN route, no two
 * on one cell, with what is left split between hand and home, for each side to
 * move. It is a count of positions that are consistent, not of positions play
 * can reach, and a finished game is counted.
 *
 * Walked cell by cell and not computed, so that it can be held against a
 * formula that was.
 */

static unsigned long long count_from(const struct ru_rules *r, int cell, int light, int dark)
{
    unsigned long long total;
    if (cell == RU_CELLS)
        return (unsigned long long) (r->pieces - light + 1)
             * (unsigned long long) (r->pieces - dark + 1);
    total = count_from(r, cell + 1, light, dark);
    if (light < r->pieces && (RU->route_step)(r->route, RU_SIDE_LIGHT, cell) > 0)
        total += count_from(r, cell + 1, light + 1, dark);
    if (dark < r->pieces && (RU->route_step)(r->route, RU_SIDE_DARK, cell) > 0)
        total += count_from(r, cell + 1, light, dark + 1);
    return total;
}

static unsigned long long ru_count_positions(const struct ru_rules *rules)
{
    struct ru_rules standard;
    if (!rules) { ru_rules_named(RU_RULES_FINKEL, &standard); rules = &standard; }
    if (!ru_rules_ok(rules)) return 0;
    return 2ULL * count_from(rules, 0, 0, 0);
}

/* ---- a move made ------------------------------------------------------------------
 *
 * WHOSE TURN IT IS AFTERWARDS is decided here and nowhere else:
 *
 *   a move to an ordinary cell          the other side
 *   a move to a rosette                 the SAME side
 *   a capture on an ordinary cell       the other side
 *   a capture on a rosette              the same side
 *   a move home                         the other side: home is not a cell
 *   a forfeit                           the other side, always
 *
 * A CAPTURED PIECE GOES TO ITS OWNER'S HAND. Not to its owner's home, not to
 * the mover's hand, and not back onto the board at its first step.
 */

static int ru_apply(struct ru_board *b, const struct ru_rules *rules,
                    const struct ru_move *m, struct ru_undo *u)
{
    struct ru_undo local;
    int side, enemy, i;

    (void) rules;
    if (!u) u = &local;
    u->kind = RU_UNDO_NONE;
    for (i = 0; i < 4; i++) u->reserved[i] = 0;
    if (!b || !m) return 0;

    side = (RU->side)(b);
    enemy = RU_OTHER(side);

    if (m->from_step == 0) {
        if ((RU->hand)(b, side) < 1) return 0;
    }
    else if ((RU->at)(b, m->from_cell) != RU_PIECE_OF(side)) return 0;

    u->kind = RU_UNDO_MOVE;
    u->side = side;
    u->ply = (RU->ply)(b);
    u->from_step = m->from_step;
    u->from_cell = m->from_step == 0 ? -1 : m->from_cell;
    u->to_cell = m->home ? -1 : m->to_cell;
    u->captured = 0;

    if (m->from_step == 0) (RU->set_hand)(b, side, (RU->hand)(b, side) - 1);
    else                   (RU->lift)(b, m->from_cell);

    if (m->home) {
        (RU->set_home)(b, side, (RU->home)(b, side) + 1);
    }
    else {
        if ((RU->at)(b, m->to_cell) == RU_PIECE_OF(enemy)) {
            u->captured = 1;
            (RU->set_hand)(b, enemy, (RU->hand)(b, enemy) + 1);
        }
        (RU->put)(b, m->to_cell, RU_PIECE_OF(side));
    }

    if (m->home || !(RU->is_rosette)(m->to_cell)) (RU->set_side)(b, enemy);
    (RU->set_ply)(b, u->ply + 1);
    return 1;
}

static void ru_forfeit(struct ru_board *b, struct ru_undo *u)
{
    struct ru_undo local;
    int i;
    if (!u) u = &local;
    u->kind = RU_UNDO_NONE;
    for (i = 0; i < 4; i++) u->reserved[i] = 0;
    if (!b) return;
    u->kind = RU_UNDO_FORFEIT;
    u->side = (RU->side)(b);
    u->ply = (RU->ply)(b);
    u->from_step = 0;
    u->from_cell = u->to_cell = -1;
    u->captured = 0;
    (RU->set_side)(b, RU_OTHER(u->side));
    (RU->set_ply)(b, u->ply + 1);
}

static void ru_unapply(struct ru_board *b, const struct ru_undo *u)
{
    int side, enemy;
    if (!b || !u || u->kind == RU_UNDO_NONE) return;
    side = u->side;
    enemy = RU_OTHER(side);

    if (u->kind == RU_UNDO_MOVE) {
        if (u->to_cell < 0) {
            (RU->set_home)(b, side, (RU->home)(b, side) - 1);
        }
        else if (u->captured) {
            (RU->put)(b, u->to_cell, RU_PIECE_OF(enemy));
            (RU->set_hand)(b, enemy, (RU->hand)(b, enemy) - 1);
        }
        else {
            (RU->lift)(b, u->to_cell);
        }
        if (u->from_step == 0) (RU->set_hand)(b, side, (RU->hand)(b, side) + 1);
        else                   (RU->put)(b, u->from_cell, RU_PIECE_OF(side));
    }
    (RU->set_side)(b, side);
    (RU->set_ply)(b, u->ply);
}

/* ---- how a game stands --------------------------------------------------------------
 *
 * Asked in this order, because the move that brings the last piece home can
 * also be the ply that reaches the cap: home first.
 */

static int ru_winner(const struct ru_board *b, const struct ru_rules *rules)
{
    struct ru_rules standard;
    if (!b) return -1;
    if (!rules) { ru_rules_named(RU_RULES_FINKEL, &standard); rules = &standard; }
    if ((RU->home)(b, RU_SIDE_LIGHT) >= rules->pieces) return RU_SIDE_LIGHT;
    if ((RU->home)(b, RU_SIDE_DARK)  >= rules->pieces) return RU_SIDE_DARK;
    return -1;
}

static int ru_how(const struct ru_board *b, const struct ru_rules *rules)
{
    if (!b) return 0;
    if (ru_winner(b, rules) >= 0) return RU_BY_HOME;
    if ((RU->ply)(b) >= RU_PLY_CAP) return RU_BY_PLY_CAP;
    return 0;
}

static int ru_status(const struct ru_board *b, const struct ru_rules *rules)
{
    int how = ru_how(b, rules);
    if (how == RU_BY_HOME)    return RU_WON;
    if (how == RU_BY_PLY_CAP) return RU_DRAWN;
    return RU_ONGOING;
}

static int ru_ply_cap(void) { return RU_PLY_CAP; }

/* ---- the walk ------------------------------------------------------------------------ */

static unsigned long long ru_walk(struct ru_board *b, const struct ru_rules *rules, int depth)
{
    struct ru_rules standard;
    struct ru_move m[RU_MOVES_MAX];
    struct ru_undo u;
    unsigned long long total = 0;
    int rolls, i, k, n, roll, weight, denominator;

    if (!b) return 0;
    if (!rules) { ru_rules_named(RU_RULES_FINKEL, &standard); rules = &standard; }
    if (!ru_rules_ok(rules)) return 0;
    if (depth <= 0 || ru_status(b, rules) != RU_ONGOING) return 1;

    rolls = (RU->chance_count)(rules->dice, rules->zero_rolls);
    for (i = 0; i < rolls; i++) {
        (RU->chance)(rules->dice, rules->zero_rolls, i, &roll, &weight, &denominator);
        n = ru_moves(b, rules, roll, m, RU_MOVES_MAX);
        if (n <= 0) {
            ru_forfeit(b, &u);
            total += ru_walk(b, rules, depth - 1);
            ru_unapply(b, &u);
            continue;
        }
        for (k = 0; k < n; k++) {
            ru_apply(b, rules, &m[k], &u);
            total += ru_walk(b, rules, depth - 1);
            ru_unapply(b, &u);
        }
    }
    return total;
}

/* ---- the table ------------------------------------------------------------------- */

void ru_moves_install(struct ru_abi *t)
{
    RU = t;
    t->rules_named     = ru_rules_named;
    t->rules_ok        = ru_rules_ok;
    t->moves           = ru_moves;
    t->count_positions = ru_count_positions;
    t->apply   = ru_apply;
    t->forfeit = ru_forfeit;
    t->unapply = ru_unapply;
    t->status  = ru_status;
    t->how     = ru_how;
    t->winner  = ru_winner;
    t->ply_cap = ru_ply_cap;
    t->walk    = ru_walk;
}
