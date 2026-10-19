/* sen_moves.c - what a roll allows, and a move made.
 *
 * PERL-FREE, like sen_engine.c, and it reaches the board only through the
 * table: this file does not know how a position is stored.
 *
 * THIS FILE'S SCOPE. The moves a roll allows the side to move: forward, the
 * backward fallback, the swap, protection, the blockade, the approach to house
 * 26, and the exit chains of the marked houses beyond it. Then a move MADE:
 * apply and its undo, the forfeit, whose turn it is afterwards, and how a game
 * ends.
 *
 * IT READS FIELDS AND NEVER A SET'S NAME. Nothing in this file knows which rule
 * set it is playing, nor which marked house is which beyond the one the track
 * cannot be passed: 26, which every set shares, and 15, where the walk begins.
 * A house that is safe is a bit of the struct; what a piece on a marked house
 * may do is a chain of the struct.
 */

#include <stddef.h>
#include "sen_abi.h"

static const struct sen_abi *SEN = NULL;

/* The house every piece must stand on before it goes further. */
#define HAPPINESS 26

/* ---- runs ----------------------------------------------------------------------
 *
 * A RUN is a maximal stretch of consecutive house NUMBERS held by one side. Houses
 * 10 and 11 are one run; houses 1 and 20, one above the other on the grid, are
 * not.
 */

static void sen_run_of(const struct sen_board *b, int house, int *lo, int *hi)
{
    int p = (SEN->at)(b, house);
    int l = house, h = house;
    while (l > 1 && (SEN->at)(b, l - 1) == p) l--;
    while (h < SEN_HOUSES && (SEN->at)(b, h + 1) == p) h++;
    *lo = l;
    *hi = h;
}

/* Whether the enemy piece on `house` may not be swapped, judged on the board as
 * it stands BEFORE the move: the house the mover leaves holds the mover's own
 * piece and is never part of the defender's run. */
static int sen_protected_at(const struct sen_board *b, const struct sen_rules *r, int house)
{
    int lo, hi;
    if (r->protect == SEN_PROTECT_NONE) return 0;
    sen_run_of(b, house, &lo, &hi);
    if (hi - lo + 1 < 2) return 0;
    if (r->protect == SEN_PROTECT_RUN) return 1;
    return house == lo || house == hi;
}

/* Whether a move from `from` to `to`, either way, PASSES an enemy run of
 * `blockade` houses or more: a house of the run lies strictly between them. A
 * side's own runs never block it. */
static int sen_blocked(const struct sen_board *b, const struct sen_rules *r,
                   int enemy, int from, int to)
{
    int lo = from < to ? from : to;
    int hi = from < to ? to : from;
    int x;
    if (r->blockade == 0) return 0;
    for (x = lo + 1; x < hi; x++) {
        int rl, rh;
        if ((SEN->at)(b, x) != enemy) continue;
        sen_run_of(b, x, &rl, &rh);
        if (rh - rl + 1 >= r->blockade) return 1;
    }
    return 0;
}

static void sen_set_move(struct sen_move *m, int from, int to, int roll, int swap, int back,
                     int off, int walk)
{
    m->from = from;
    m->to = to;
    m->roll = roll;
    m->swap = swap;
    m->back = back;
    m->off = off;
    m->walk = walk;
    m->reserved[0] = 0;
}

/* One candidate that COUNTS along the track, forward or back. 1 and the move
 * written when it is one. */
static int sen_consider(const struct sen_board *b, const struct sen_rules *r, int roll,
                    int from, int to, int back, struct sen_move *m)
{
    int me = SEN_PIECE_OF((SEN->side)(b));
    int enemy = SEN_PIECE_OF(SEN_OTHER((SEN->side)(b)));
    int there;

    if (to < 1 || to > SEN_HOUSES) return 0;
    if (sen_blocked(b, r, enemy, from, to)) return 0;
    there = (SEN->at)(b, to);
    if (there == me) return 0;
    if (there == enemy) {
        if (r->safe & (1UL << to)) return 0;
        if (sen_protected_at(b, r, to)) return 0;
    }
    sen_set_move(m, from, to, roll, there == enemy, back, 0, 0);
    return 1;
}

/* Where a forward roll from `from` lands, or 0 when it is not a move: no piece
 * goes past 26 without standing on it. Under SEN_REACH_ANY a piece on 25 lands
 * on 26 whatever the roll. */
static int sen_forward_to(const struct sen_rules *r, int from, int roll)
{
    int to = from + roll;
    if (to <= HAPPINESS) return to;
    if (r->reach26 == SEN_REACH_ANY && from == HAPPINESS - 1) return HAPPINESS;
    return 0;
}

/* ---- the marked houses' exits -------------------------------------------------
 *
 * The walk: SEN_REBIRTH, else the first EMPTY house below it. Either side's
 * piece makes a house full, and the walk never swaps. On a consistent board it
 * always finds one: the mover stands on 26 or above, and the other pieces, at
 * most 2 * SEN_PIECES_MAX - 1 of them, cannot fill the fifteen houses from 1.
 */

static int sen_walk_down(const struct sen_board *b)
{
    int x;
    for (x = SEN_REBIRTH; x >= 1; x--)
        if ((SEN->at)(b, x) == SEN_EMPTY) return x;
    return 0;
}

/* A piece on `from`, 26 or beyond, reads its chain for the roll. AN EXIT NEVER
 * COUNTS ALONG THE TRACK, so no blockade judges it, and it never swaps: it lands
 * on an empty house or nowhere. */
static int sen_exit_move(const struct sen_board *b, const struct sen_rules *r, int roll,
                     int from, struct sen_move *m)
{
    int i;
    const signed char *chain = r->exit[from - SEN_EXIT_FIRST][roll - 1];
    for (i = 0; i < SEN_CHAIN_MAX; i++) {
        int e = chain[i];
        if (e == SEN_X_OFF) { sen_set_move(m, from, -1, roll, 0, 0, 1, 0); return 1; }
        if (e == SEN_X_END || e == SEN_X_STAY) return 0;
        if (e == SEN_X_WALK) {
            int to = sen_walk_down(b);
            if (to) { sen_set_move(m, from, to, roll, 0, 0, 0, 1); return 1; }
            continue;
        }
        if ((SEN->at)(b, e) == SEN_EMPTY) { sen_set_move(m, from, e, roll, 0, 0, 0, 0); return 1; }
    }
    return 0;
}

static int sen_moves(const struct sen_board *b, const struct sen_rules *r, int roll,
                     int only, struct sen_move *out, int max)
{
    struct sen_move m;
    int me, h, n = 0, pass;

    if (roll < 1 || roll > SEN_ROLL_MAX) return -1;
    if (!(SEN->rules_ok)(r)) return -1;
    me = SEN_PIECE_OF((SEN->side)(b));

    for (pass = 0; pass < 2 && n == 0; pass++) {
        if (pass == 1 && !r->backward) break;
        for (h = 1; h <= SEN_HOUSES; h++) {
            int to, ok;
            if ((SEN->at)(b, h) != me) continue;
            if (only && h != only) continue;
            if (h >= HAPPINESS) {
                if (pass == 1) continue;
                ok = sen_exit_move(b, r, roll, h, &m);
            }
            else {
                to = pass == 0 ? sen_forward_to(r, h, roll) : h - roll;
                if (pass == 0 && to == 0) continue;
                ok = sen_consider(b, r, roll, h, to, pass, &m);
            }
            if (!ok) continue;
            if (out && n < max) out[n] = m;
            n++;
        }
    }
    return n;
}

/* ---- a move made ----------------------------------------------------------------
 *
 * WHOSE TURN IT IS AFTERWARDS is decided here and nowhere else: the extra throw
 * belongs to the THROW, so a roll of 1, 4 or 5 keeps the side whatever was done
 * with it, a forfeit included, and a 2 or 3 passes it.
 */

static int sen_won(const struct sen_board *b, int side)
{
    return (SEN->count)(b, side) == 0;
}

static int sen_apply(struct sen_board *b, const struct sen_rules *r,
                     const struct sen_move *m, struct sen_undo *u)
{
    int side = (SEN->side)(b);
    int me = SEN_PIECE_OF(side);
    int enemy = SEN_PIECE_OF(SEN_OTHER(side));
    int i;

    u->kind = SEN_UNDO_NONE;
    u->bound = 0;
    for (i = 0; i < 4; i++) u->reserved[i] = 0;
    if (!m || (SEN->at)(b, m->from) != me) return 0;
    if (!m->off && (m->to < 1 || m->to > SEN_HOUSES)) return 0;

    u->kind = SEN_UNDO_MOVE;
    u->side = side;
    u->ply = (SEN->ply)(b);
    u->from = m->from;
    u->to = m->off ? -1 : m->to;
    u->swapped = 0;

    (SEN->lift)(b, m->from);
    if (!m->off) {
        if ((SEN->at)(b, m->to) == enemy) {
            (SEN->put)(b, m->from, enemy);
            u->swapped = 1;
        }
        (SEN->put)(b, m->to, me);
    }
    (SEN->set_ply)(b, u->ply + 1);

    if (sen_won(b, side)) return 1;
    if (r && r->throw_on_26 && !m->off && m->from < HAPPINESS && m->to == HAPPINESS) {
        u->bound = HAPPINESS;
        return 1;
    }
    if ((SEN->extra)(m->roll) != 1) (SEN->set_side)(b, SEN_OTHER(side));
    return 1;
}

static void sen_forfeit(struct sen_board *b, int roll, struct sen_undo *u)
{
    int side = (SEN->side)(b);
    int i;
    u->kind = SEN_UNDO_FORFEIT;
    u->side = side;
    u->ply = (SEN->ply)(b);
    u->from = u->to = 0;
    u->swapped = 0;
    u->bound = 0;
    for (i = 0; i < 4; i++) u->reserved[i] = 0;
    (SEN->set_ply)(b, u->ply + 1);
    if ((SEN->extra)(roll) != 1) (SEN->set_side)(b, SEN_OTHER(side));
}

static void sen_unapply(struct sen_board *b, const struct sen_undo *u)
{
    if (!u || u->kind == SEN_UNDO_NONE) return;
    if (u->kind == SEN_UNDO_MOVE) {
        int me = SEN_PIECE_OF(u->side);
        int enemy = SEN_PIECE_OF(SEN_OTHER(u->side));
        if (u->to > 0) (SEN->put)(b, u->to, u->swapped ? enemy : SEN_EMPTY);
        (SEN->put)(b, u->from, me);
    }
    (SEN->set_side)(b, u->side);
    (SEN->set_ply)(b, u->ply);
}

/* ---- how a game stands ------------------------------------------------------------
 *
 * After the move that wins, the side does not change, so the winner is the
 * side to move when its pieces are all home, and otherwise the other side when
 * its are.
 */

static int sen_winner(const struct sen_board *b)
{
    int side = (SEN->side)(b);
    if (sen_won(b, side)) return side;
    if (sen_won(b, SEN_OTHER(side))) return SEN_OTHER(side);
    return -1;
}

static int sen_how(const struct sen_board *b)
{
    if (sen_winner(b) >= 0) return SEN_BY_HOME;
    if ((SEN->ply)(b) >= SEN_PLY_CAP) return SEN_BY_PLY_CAP;
    return 0;
}

static int sen_status(const struct sen_board *b)
{
    int how = sen_how(b);
    if (how == SEN_BY_HOME) return SEN_WON;
    if (how == SEN_BY_PLY_CAP) return SEN_DRAWN;
    return SEN_ONGOING;
}

static int sen_ply_cap(void) { return SEN_PLY_CAP; }

/* ---- the walk ---------------------------------------------------------------------- */

static unsigned long long sen_walk_from(struct sen_board *b, const struct sen_rules *r,
                                    int depth, int only)
{
    struct sen_move m[SEN_MOVES_MAX];
    struct sen_undo u;
    unsigned long long leaves = 0;
    int roll, n, i;

    if (depth <= 0 || sen_status(b) != SEN_ONGOING) return 1;
    for (roll = 1; roll <= SEN_ROLL_MAX; roll++) {
        n = sen_moves(b, r, roll, only, m, SEN_MOVES_MAX);
        if (n > SEN_MOVES_MAX) n = SEN_MOVES_MAX;
        if (n <= 0) {
            sen_forfeit(b, roll, &u);
            leaves += sen_walk_from(b, r, depth - 1, 0);
            sen_unapply(b, &u);
            continue;
        }
        for (i = 0; i < n; i++) {
            sen_apply(b, r, &m[i], &u);
            leaves += sen_walk_from(b, r, depth - 1, u.bound);
            sen_unapply(b, &u);
        }
    }
    return leaves;
}

static unsigned long long sen_walk(struct sen_board *b, const struct sen_rules *r, int depth)
{
    if (!b || !(SEN->rules_ok)(r)) return 0;
    return sen_walk_from(b, r, depth, 0);
}

/* ---- what a house is ------------------------------------------------------------
 *
 * The same rules the generator applies, asked of one house. A run is measured
 * from the piece that stands there, so an empty house is refused first: the
 * run of empty houses around it is no run of anybody's.
 */

static int sen_held(const struct sen_board *b, const struct sen_rules *r, int house)
{
    int p;
    if (house < 1 || house > SEN_HOUSES) return 0;
    if (!(SEN->rules_ok)(r)) return 0;
    p = (SEN->at)(b, house);
    return p == SEN_PIECE_OF(SEN_SIDE_LIGHT) || p == SEN_PIECE_OF(SEN_SIDE_DARK);
}

static int sen_protected_house(const struct sen_board *b, const struct sen_rules *r, int house)
{
    if (!sen_held(b, r, house)) return 0;
    return sen_protected_at(b, r, house);
}

static int sen_in_blockade(const struct sen_board *b, const struct sen_rules *r, int house)
{
    int lo, hi;
    if (!sen_held(b, r, house)) return 0;
    if (r->blockade == 0) return 0;
    sen_run_of(b, house, &lo, &hi);
    return hi - lo + 1 >= r->blockade;
}

/* ---- the table -------------------------------------------------------------- */

void sen_moves_install(struct sen_abi *t)
{
    SEN = t;
    t->moves   = sen_moves;
    t->apply   = sen_apply;
    t->forfeit = sen_forfeit;
    t->unapply = sen_unapply;
    t->status  = sen_status;
    t->how     = sen_how;
    t->winner  = sen_winner;
    t->ply_cap = sen_ply_cap;
    t->walk    = sen_walk;
    t->protected_at = sen_protected_house;
    t->in_blockade  = sen_in_blockade;
}
