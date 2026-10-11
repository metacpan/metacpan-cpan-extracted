/* fn_moves.c - one stone, one step: where it may go and what it takes; and
 * then the chain of steps that is a whole move.
 *
 * PERL-FREE, as fn_engine.c is.
 *
 * THE RULES THIS FILE IMPLEMENTS, quoted from the sources the distribution
 * names in its documentation:
 *
 *   "A paika move consists of moving one stone along a line to an adjacent
 *    intersection."
 *   "Capturing moves are obligatory and have to be played in preference to
 *    paika moves." And: "If any capturing moves are possible anywhere on the
 *    board, then a capturing move must be made. If multiple captures are
 *    possible, you can choose which to do."
 *   Approach: "moving the capturing stone to a point adjacent to an opponent's
 *    stone, which must be on the continuation of the capturing stone's
 *    movement line."
 *   Withdrawal: "the capturing stone moves from a point adjacent to the
 *    opponent's stone, away from the stone along the continuation of the line
 *    between them."
 *   "All opponent pieces in line beyond that stone (as long as there is no
 *    interruption by an empty point or an own stone) are captured as well."
 *   "It is not allowed to capture by approach and withdrawal at the same time
 *    ... the player has to choose".
 *
 * and two readings where the sources are brief:
 *
 *   - A STEP THAT COULD TAKE, TAKES. Capture is obligatory, so there is no
 *     moving there and declining: a step is a paika only when it takes
 *     nothing by either method.
 *   - THE OBLIGATION IS GLOBAL AND THE CHOICE IS FREE. If any stone can take,
 *     no stone may make a paika; but which capture is made is the mover's,
 *     and the largest has no priority.
 *
 * THE LINE IS READ OUTWARD FROM THE STEP. Nothing here scans the board for
 * lines: an approach looks at the point beyond `to`, a withdrawal at the point
 * behind `from`, and each walks on from there.
 */

#include <string.h>
#include "fn_abi.h"

/* fn_engine.c owns the struct; this file reaches it through the same table
 * every other consumer uses, which keeps the two files honest about the
 * interface. */
static const struct fn_abi *E(void) { return fn_abi_table(); }

#define AT(b, sq)        ((E())->at((b), (sq)))
#define NEXT(b, sq, dir) ((E())->next((b), (sq), (dir)))

/* A stone has at most eight ways to go and each is at most two entries. */
#define STONE_STEPS_MAX 16

/* ---- the line ------------------------------------------------------------------
 *
 * The enemy stones from `start` onward in `dir`, nearest first, until the
 * line breaks. `start` may be -1, which is the edge and an empty line.
 *
 * A diagonal walk never has to ask whether it may go on: every point on a
 * diagonal is a strong point, so NEXT answers -1 only at the edge.
 */
static int line_from(const struct fn_board *b, int start, int dir, int foe, int *out)
{
    int n = 0, sq = start;
    while (sq >= 0 && n < FN_LINE_MAX && AT(b, sq) == foe) {
        out[n++] = sq;
        sq = NEXT(b, sq, dir);
    }
    return n;
}

static void step_fill(struct fn_step *s, int from, int to, int dir, int kind, const int *taken, int n)
{
    int i;
    s->from = from;
    s->to = to;
    s->dir = dir;
    s->kind = kind;
    s->taken_n = n;
    for (i = 0; i < FN_LINE_MAX; i++) s->taken[i] = i < n ? taken[i] : 0;
}

/* The steps of one stone, judging nothing but the geometry. Returns how many
 * there are and writes at most `max`. */
static int fn_steps_of(const struct fn_board *b, int sq, struct fn_step *out, int max)
{
    int stone = AT(b, sq);
    int foe, dir, n = 0;
    if (!FN_IS_STONE(stone)) return 0;
    foe = FN_OTHER(stone);
    for (dir = 0; dir < FN_DIRS; dir++) {
        int ahead[FN_LINE_MAX], behind[FN_LINE_MAX];
        int a, w;
        int to = NEXT(b, sq, dir);
        if (to < 0 || AT(b, to) != FN_EMPTY) continue;
        a = line_from(b, NEXT(b, to, dir), dir, foe, ahead);
        w = line_from(b, NEXT(b, sq, (dir + 4) % FN_DIRS), (dir + 4) % FN_DIRS, foe, behind);
        if (a) {
            if (out && n < max) step_fill(&out[n], sq, to, dir, FN_APPROACH, ahead, a);
            n++;
        }
        if (w) {
            if (out && n < max) step_fill(&out[n], sq, to, dir, FN_WITHDRAWAL, behind, w);
            n++;
        }
        if (!a && !w) {
            if (out && n < max) step_fill(&out[n], sq, to, dir, FN_PAIKA, ahead, 0);
            n++;
        }
    }
    return n;
}

static int fn_can_capture(const struct fn_board *b, int side)
{
    const struct fn_abi *e = E();
    struct fn_step tmp[STONE_STEPS_MAX];
    int rank, file, i, n;
    if (!FN_IS_STONE(side)) return 0;
    for (rank = 0; rank < e->rows(b); rank++) {
        for (file = 0; file < e->cols(b); file++) {
            int sq = e->square_of(file, rank);
            if (AT(b, sq) != side) continue;
            n = fn_steps_of(b, sq, tmp, STONE_STEPS_MAX);
            for (i = 0; i < n; i++)
                if (tmp[i].kind != FN_PAIKA) return 1;
        }
    }
    return 0;
}

/* THE OBLIGATION. Every step of every stone is found first; if one of them
 * takes, the paikas are dropped from the list, wherever they stand. */
static int fn_gen_steps(const struct fn_board *b, struct fn_step *out, int max)
{
    const struct fn_abi *e = E();
    struct fn_step tmp[STONE_STEPS_MAX];
    int side = e->side(b);
    int must = fn_can_capture(b, side);
    int rank, file, i, n, found = 0;
    for (rank = 0; rank < e->rows(b); rank++) {
        for (file = 0; file < e->cols(b); file++) {
            int sq = e->square_of(file, rank);
            if (AT(b, sq) != side) continue;
            n = fn_steps_of(b, sq, tmp, STONE_STEPS_MAX);
            for (i = 0; i < n; i++) {
                if (must && tmp[i].kind == FN_PAIKA) continue;
                if (out && found < max) out[found] = tmp[i];
                found++;
            }
        }
    }
    return found;
}

static int fn_step_build(const struct fn_board *b, int from, int dir, int kind, struct fn_step *out)
{
    int ahead[FN_LINE_MAX];
    int stone, to, n = 0;
    if (dir < 0 || dir >= FN_DIRS) return 0;
    if (kind != FN_PAIKA && kind != FN_APPROACH && kind != FN_WITHDRAWAL) return 0;
    stone = AT(b, from);
    if (!FN_IS_STONE(stone)) return 0;
    to = NEXT(b, from, dir);
    if (to < 0 || AT(b, to) != FN_EMPTY) return 0;
    if (kind == FN_APPROACH)
        n = line_from(b, NEXT(b, to, dir), dir, FN_OTHER(stone), ahead);
    else if (kind == FN_WITHDRAWAL)
        n = line_from(b, NEXT(b, from, (dir + 4) % FN_DIRS), (dir + 4) % FN_DIRS, FN_OTHER(stone), ahead);
    if (kind != FN_PAIKA && !n) return 0;
    if (out) step_fill(out, from, to, dir, kind, ahead, n);
    return 1;
}

static int fn_step_why(const struct fn_board *b, int from, int dir, int kind, struct fn_step *out)
{
    const struct fn_abi *e = E();
    struct fn_step either;
    int stone, to, takes;
    if (!e->on_board(b, from)) return FN_WHY_OFF_BOARD;
    if (dir < 0 || dir >= FN_DIRS) return FN_WHY_BAD_STEP;
    if (kind != FN_PAIKA && kind != FN_APPROACH && kind != FN_WITHDRAWAL) return FN_WHY_BAD_STEP;
    stone = AT(b, from);
    if (!FN_IS_STONE(stone)) return FN_WHY_NO_STONE;
    if (stone != e->side(b)) return FN_WHY_NOT_YOURS;
    to = NEXT(b, from, dir);
    if (to < 0) return FN_WHY_NO_LINE;
    if (AT(b, to) != FN_EMPTY) return FN_WHY_OCCUPIED;
    if (kind != FN_PAIKA) {
        if (!fn_step_build(b, from, dir, kind, out)) return FN_WHY_TAKES_NOTHING;
        return FN_WHY_OK;
    }
    takes = fn_step_build(b, from, dir, FN_APPROACH, &either)
         || fn_step_build(b, from, dir, FN_WITHDRAWAL, &either);
    if (takes) return FN_WHY_NOT_A_PAIKA;
    if (fn_can_capture(b, stone)) return FN_WHY_MUST_CAPTURE;
    fn_step_build(b, from, dir, FN_PAIKA, out);
    return FN_WHY_OK;
}

/* ---- do and undo ----------------------------------------------------------------
 *
 * do_step takes the step at its word about what is taken, and records what
 * actually stood on each point so that undo puts back exactly that.
 */

static int fn_do_step(struct fn_board *b, const struct fn_step *s, struct fn_undo *u)
{
    const struct fn_abi *e = E();
    int stone, i, n, removed = 0;
    if (u) memset(u, 0, sizeof(*u));
    if (!s) return -1;
    stone = AT(b, s->from);
    if (!FN_IS_STONE(stone) || AT(b, s->to) != FN_EMPTY) return -1;
    n = s->taken_n;
    if (n < 0) n = 0;
    if (n > FN_LINE_MAX) n = FN_LINE_MAX;
    if (u) {
        u->step = *s;
        u->step.taken_n = n;
        u->did = 1;
        u->stone = stone;
        u->side = e->side(b);
        u->key = e->key(b);
    }
    e->lift(b, s->from);
    e->put(b, s->to, stone);
    for (i = 0; i < n; i++) {
        int was = AT(b, s->taken[i]);
        if (u) u->was[i] = FN_IS_STONE(was) ? was : FN_EMPTY;
        if (!FN_IS_STONE(was)) continue;
        e->lift(b, s->taken[i]);
        removed++;
    }
    e->set_side(b, FN_OTHER(e->side(b)));
    return removed;
}

static void fn_undo_step(struct fn_board *b, const struct fn_undo *u)
{
    const struct fn_abi *e = E();
    int i;
    if (!u || !u->did) return;
    e->set_side(b, u->side);
    for (i = 0; i < u->step.taken_n; i++)
        if (FN_IS_STONE(u->was[i])) e->put(b, u->step.taken[i], u->was[i]);
    e->lift(b, u->step.to);
    e->put(b, u->step.from, u->stone);
}

static unsigned long long fn_perft_steps(struct fn_board *b, int depth)
{
    struct fn_step list[FN_STEPS_MAX];
    struct fn_undo u;
    unsigned long long total = 0;
    int n, i;
    if (depth <= 0) return 1;
    n = fn_gen_steps(b, list, FN_STEPS_MAX);
    if (depth == 1) return (unsigned long long) n;
    for (i = 0; i < n; i++) {
        fn_do_step(b, &list[i], &u);
        total += fn_perft_steps(b, depth - 1);
        fn_undo_step(b, &u);
    }
    return total;
}

/* ---- the chain, version 3 ---------------------------------------------------------
 *
 * THE RULES, quoted from the same sources:
 *
 *   "it is allowed to continue capturing with the same piece ... (Even if a
 *    move consists of multiple movements of one single piece it still counts
 *    as a single move.)"
 *   "the player may stop capturing after any number of opponent pieces are
 *    captured."
 *   "It is not allowed to make a capturing move in the same direction as the
 *    capturing move directly before ... A player is allowed to play a
 *    capturing sequence two times into the same direction if a capturing
 *    movement in another direction is done in between. The last movement
 *    direction of the capturing move in the previous turn ... does not
 *    influence possible capturing directions in the current turn."
 *   "The current capturing piece is not allowed to arrive on the same
 *    intersection twice during a capturing sequence." The source's own
 *    example refuses a return to the point the chain STARTED from.
 *   "you must keep moving the same piece"
 *
 * and one reading: every step of a chain after the first must take. A stone
 * that has taken may stop; it may not then make a paika.
 *
 * THE DIRECTION RULE LOOKS BACK ONE STEP AND NO FURTHER, and nothing of a
 * chain outlives it: closing clears all three fields.
 */

static unsigned long long bit_of(int sq)
{
    int bit = (E())->point_bit(sq);
    return bit < 0 ? 0 : (1ULL << bit);
}

/* The steps that may follow in an open chain. */
static int chain_steps(const struct fn_board *b, struct fn_step *out, int max)
{
    const struct fn_abi *e = E();
    struct fn_step tmp[STONE_STEPS_MAX];
    int at = e->chain_at(b);
    int last = e->chain_dir(b);
    int i, n, found = 0;
    if (at < 0) return 0;
    n = fn_steps_of(b, at, tmp, STONE_STEPS_MAX);
    for (i = 0; i < n; i++) {
        if (tmp[i].kind == FN_PAIKA) continue;
        if (tmp[i].dir == last) continue;
        if (e->chain_seen(b, tmp[i].to)) continue;
        if (out && found < max) out[found] = tmp[i];
        found++;
    }
    return found;
}

static int fn_play_steps(const struct fn_board *b, struct fn_step *out, int max)
{
    if ((E())->chain_at(b) >= 0) return chain_steps(b, out, max);
    return fn_gen_steps(b, out, max);
}

static int fn_can_stop(const struct fn_board *b)
{
    return (E())->chain_at(b) >= 0;
}

static int fn_play_why(const struct fn_board *b, int from, int dir, int kind, struct fn_step *out)
{
    const struct fn_abi *e = E();
    struct fn_step either;
    int at = e->chain_at(b);
    int stone, to;
    if (at < 0) return fn_step_why(b, from, dir, kind, out);
    if (!e->on_board(b, from)) return FN_WHY_OFF_BOARD;
    if (dir < 0 || dir >= FN_DIRS) return FN_WHY_BAD_STEP;
    if (kind != FN_PAIKA && kind != FN_APPROACH && kind != FN_WITHDRAWAL) return FN_WHY_BAD_STEP;
    stone = AT(b, from);
    if (!FN_IS_STONE(stone)) return FN_WHY_NO_STONE;
    if (stone != e->side(b)) return FN_WHY_NOT_YOURS;
    if (from != at) return FN_WHY_NOT_THE_STONE;
    to = NEXT(b, from, dir);
    if (to < 0) return FN_WHY_NO_LINE;
    if (AT(b, to) != FN_EMPTY) return FN_WHY_OCCUPIED;
    if (dir == e->chain_dir(b)) return FN_WHY_SAME_DIRECTION;
    if (e->chain_seen(b, to)) return FN_WHY_REVISIT;
    if (kind == FN_PAIKA) {
        if (fn_step_build(b, from, dir, FN_APPROACH, &either)
         || fn_step_build(b, from, dir, FN_WITHDRAWAL, &either)) return FN_WHY_NOT_A_PAIKA;
        return FN_WHY_PAIKA_IN_CHAIN;
    }
    if (!fn_step_build(b, from, dir, kind, out)) return FN_WHY_TAKES_NOTHING;
    return FN_WHY_OK;
}

static void undo_keep_chain(const struct fn_board *b, struct fn_undo *u, int stop)
{
    const struct fn_abi *e = E();
    if (!u) return;
    u->reserved[FN_UNDO_PLAYED] = 1;
    u->reserved[FN_UNDO_AT]     = e->chain_at(b);
    u->reserved[FN_UNDO_DIR]    = e->chain_dir(b);
    u->reserved[FN_UNDO_STOP]   = stop;
    u->reserved64[FN_UNDO_SEEN] = e->chain_mask(b);
}

static int fn_play_step(struct fn_board *b, const struct fn_step *s, struct fn_undo *u)
{
    const struct fn_abi *e = E();
    struct fn_undo local;
    unsigned long long seen;
    int mover, was_open, removed;
    if (!u) u = &local;
    mover = e->side(b);
    was_open = e->chain_at(b) >= 0;
    seen = e->chain_mask(b);
    {
        /* the chain as it was, before do_step clears the record */
        int at = e->chain_at(b), dir = e->chain_dir(b);
        removed = fn_do_step(b, s, u);
        if (removed < 0) return -1;
        u->reserved[FN_UNDO_PLAYED] = 1;
        u->reserved[FN_UNDO_AT]     = at;
        u->reserved[FN_UNDO_DIR]    = dir;
        u->reserved[FN_UNDO_STOP]   = 0;
        u->reserved64[FN_UNDO_SEEN] = seen;
    }
    if (removed == 0) {
        /* a paika: do_step has passed the turn, and no chain survives one */
        e->chain_set(b, -1, -1, 0);
        return 0;
    }
    /* it took: the turn stays with the mover and the chain is on this stone */
    e->set_side(b, mover);
    if (!was_open) seen = bit_of(s->from);
    seen |= bit_of(s->to);
    e->chain_set(b, s->to, s->dir, seen);
    if (chain_steps(b, NULL, 0) == 0) {
        e->chain_set(b, -1, -1, 0);
        e->set_side(b, FN_OTHER(mover));
    }
    return removed;
}

static int fn_play_stop(struct fn_board *b, struct fn_undo *u)
{
    const struct fn_abi *e = E();
    if (u) memset(u, 0, sizeof(*u));
    if (e->chain_at(b) < 0) return 0;
    if (u) {
        u->did = 1;
        u->side = e->side(b);
        u->key = e->key(b);
    }
    undo_keep_chain(b, u, 1);
    e->chain_set(b, -1, -1, 0);
    e->set_side(b, FN_OTHER(e->side(b)));
    return 1;
}

static void fn_play_undo(struct fn_board *b, const struct fn_undo *u)
{
    const struct fn_abi *e = E();
    if (!u || !u->did) return;
    if (u->reserved[FN_UNDO_STOP]) e->set_side(b, u->side);
    else                           fn_undo_step(b, u);
    e->chain_set(b, u->reserved[FN_UNDO_AT], u->reserved[FN_UNDO_DIR], u->reserved64[FN_UNDO_SEEN]);
}

/* ---- whole moves -------------------------------------------------------------------
 *
 * A walk of the step tree, depth first. A move ends after every step: a paika
 * is a move, a step that closed its own chain is a move, and a step that left
 * the chain open is a move too, because the mover may stop there. So every
 * node of the tree below the root is one move, and a chain's shorter
 * beginnings are met before its longer ones.
 */

struct walk {
    struct fn_move cur;
    struct fn_move *out;
    int max;
    unsigned long long found;
    unsigned long long cap;
};

static void walk_from(struct fn_board *b, struct walk *w, struct fn_step *list, int n)
{
    const struct fn_abi *e = E();
    struct fn_step next[STONE_STEPS_MAX];
    struct fn_undo u;
    int i, m;
    for (i = 0; i < n; i++) {
        if (w->cap && w->found >= w->cap) return;
        if (w->cur.n >= FN_CHAIN_MAX) return;
        if (w->cur.n == 0) w->cur.from = list[i].from;
        w->cur.dir[w->cur.n]  = (unsigned char) list[i].dir;
        w->cur.kind[w->cur.n] = (unsigned char) list[i].kind;
        w->cur.n++;
        w->cur.taken += list[i].taken_n;
        fn_play_step(b, &list[i], &u);
        if (w->out && w->found < (unsigned long long) w->max) w->out[w->found] = w->cur;
        w->found++;
        if (e->chain_at(b) >= 0) {
            m = chain_steps(b, next, STONE_STEPS_MAX);
            walk_from(b, w, next, m);
        }
        fn_play_undo(b, &u);
        w->cur.taken -= list[i].taken_n;
        w->cur.n--;
    }
}

static unsigned long long walk_moves(struct fn_board *b, struct fn_move *out, int max, unsigned long long cap)
{
    struct fn_step list[FN_STEPS_MAX];
    struct walk w;
    int n;
    memset(&w, 0, sizeof(w));
    w.out = out;
    w.max = max;
    w.cap = cap;
    if ((E())->chain_at(b) >= 0) return 0;
    n = fn_gen_steps(b, list, FN_STEPS_MAX);
    walk_from(b, &w, list, n);
    return w.found;
}

static unsigned long long fn_count_moves(struct fn_board *b, unsigned long long cap)
{
    return walk_moves(b, NULL, 0, cap);
}

/* THE WALK STOPS ONE PAST `max`. A position can have more whole moves than
 * anyone will wait for, so "how many there are" is answered only as far as
 * the caller's buffer plus one: enough to know the buffer was short, and no
 * further. count_moves is the call that counts. */
static int fn_gen_moves(struct fn_board *b, struct fn_move *out, int max)
{
    if (max < 0) max = 0;
    return (int) walk_moves(b, out, max, (unsigned long long) max + 1ULL);
}

static int fn_move_steps(struct fn_board *b, const struct fn_move *m, struct fn_step *out)
{
    const struct fn_abi *e = E();
    struct fn_undo undo[FN_CHAIN_MAX];
    struct fn_step s;
    int at, i, ok = 1;
    if (!m || m->n < 1 || m->n > FN_CHAIN_MAX || e->chain_at(b) >= 0) return -1;
    at = m->from;
    for (i = 0; i < m->n; i++) {
        if (fn_play_why(b, at, m->dir[i], m->kind[i], &s) != FN_WHY_OK) { ok = 0; break; }
        if (out) out[i] = s;
        fn_play_step(b, &s, &undo[i]);
        at = s.to;
    }
    while (i-- > 0) fn_play_undo(b, &undo[i]);
    return ok ? m->n : -1;
}

static unsigned long long fn_perft_moves(struct fn_board *b, int depth)
{
    const struct fn_abi *e = E();
    struct fn_step list[FN_STEPS_MAX];
    struct fn_undo u, stop;
    unsigned long long total = 0;
    int n, i;
    if (depth <= 0) return 1;
    n = fn_play_steps(b, list, FN_STEPS_MAX);
    for (i = 0; i < n; i++) {
        fn_play_step(b, &list[i], &u);
        if (e->chain_at(b) >= 0) {
            /* the mover may stop here, which ends this move ... */
            fn_play_stop(b, &stop);
            total += fn_perft_moves(b, depth - 1);
            fn_play_undo(b, &stop);
            /* ... or go on, which is still this move */
            total += fn_perft_moves(b, depth);
        }
        else {
            total += fn_perft_moves(b, depth - 1);
        }
        fn_play_undo(b, &u);
    }
    return total;
}

/* ---- installed into the table by fn_engine.c ---------------------------------- */

void fn_moves_install(struct fn_abi *t);

void fn_moves_install(struct fn_abi *t)
{
    t->gen_steps   = fn_gen_steps;
    t->steps_of    = fn_steps_of;
    t->can_capture = fn_can_capture;
    t->step_why    = fn_step_why;
    t->step_build  = fn_step_build;
    t->do_step     = fn_do_step;
    t->undo_step   = fn_undo_step;
    t->perft_steps = fn_perft_steps;

    t->play_steps  = fn_play_steps;
    t->can_stop    = fn_can_stop;
    t->play_why    = fn_play_why;
    t->play_step   = fn_play_step;
    t->play_stop   = fn_play_stop;
    t->play_undo   = fn_play_undo;
    t->count_moves = fn_count_moves;
    t->gen_moves   = fn_gen_moves;
    t->move_steps  = fn_move_steps;
    t->perft_moves = fn_perft_moves;
}
