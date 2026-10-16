/* shg_mate.c - whether a square is attacked, and check.
 *
 * PERL-FREE by design: see include/shg_abi.h.
 *
 * THIS FILE'S SCOPE at version 2: attacked and in_check. Mate and the
 * pawn-drop mate test arrive with version 3.
 */

#include "shg_internal.h"

/* A piece of `by` attacks `sq` when one of its steps lands there, or when it
 * is the first piece along a ray from `sq` and slides back along that ray.
 *
 * THE STEPS ARE ASKED BACKWARDS: for each kind and each of its steps, is that
 * kind of `by` standing one step short of `sq`? That covers the knight, whose
 * jump is a step, and every piece that touches `sq`. The rays then find the
 * sliders, near or far. */
int shg_attacked(const struct shg_board *b, int sq, int by)
{
    int box, kind, i, d;
    if (!b || !SHG_IS_SQ(sq) || !SHG_IS_SIDE(by)) return 0;
    box = SHG_SQ_OF[sq];

    for (kind = SHG_PAWN; kind <= SHG_DRAGON; kind++) {
        int piece = SHG_PIECE(by, kind);
        for (i = 0; i < SHG_NSTEPS[by][kind]; i++)
            if (b->cell[box - SHG_STEP_OFF[by][kind][i]] == piece) return 1;
    }

    for (d = 0; d < SHG_DIRS; d++) {
        int off = SHG_DIR_OFF[d], t, c;
        for (t = box + off; (c = b->cell[t]) == SHG_EMPTY; t += off)
            ;
        if (c == SHG_OFF || SHG_SIDE_OF(c) != by) continue;
        /* The piece at t moves towards sq, the opposite of d: directions are
         * listed so that d's opposite is the one with the offset negated. */
        {
            int back, k = SHG_KIND_OF(c);
            for (back = 0; back < SHG_DIRS; back++)
                if (SHG_DIR_OFF[back] == -off) break;
            if (back < SHG_DIRS && (SHG_SLIDE_MASK[by][k] >> back & 1u)) return 1;
        }
    }
    return 0;
}

int shg_in_check(const struct shg_board *b, int side)
{
    if (!b || !SHG_IS_SIDE(side) || b->king[side] < 0) return 0;
    return shg_attacked(b, b->king[side], side == SHG_BLACK ? SHG_WHITE : SHG_BLACK);
}

/* ---- perft, version 3 -----------------------------------------------------
 *
 * Every legal move to `depth` plies, counted at the last: D's table also
 * counts, of those last moves, the captures, the drops, the promotions, the
 * checks and the mates, and so does this when it is asked to.
 */

static unsigned long long perft_from(struct shg_board *b, int depth, unsigned long long *counts)
{
    int moves[SHG_MOVES_MAX];
    int n, i;
    unsigned long long nodes = 0;
    struct shg_undo u;

    n = shg_legal(b, moves, SHG_MOVES_MAX);
    if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
    if (depth == 1 && !counts) return (unsigned long long) n;

    for (i = 0; i < n; i++) {
        int m = moves[i];
        if (depth == 1) {
            int drop = SHG_MOVE_DROP(m);
            int capture = !drop && b->cell[SHG_SQ_OF[SHG_MOVE_TO(m)]] != SHG_EMPTY;
            counts[SHG_PERFT_NODES]++;
            if (capture) counts[SHG_PERFT_CAPTURES]++;
            if (drop) counts[SHG_PERFT_DROPS]++;
            if (SHG_MOVE_PROMOTE(m)) counts[SHG_PERFT_PROMOTIONS]++;
            if (!shg_do_move(b, m, &u)) continue;
            if (shg_in_check(b, b->to_move)) {
                counts[SHG_PERFT_CHECKS]++;
                if (!shg_has_legal_move(b)) counts[SHG_PERFT_MATES]++;
            }
            shg_undo_move(b, &u);
            nodes++;
            continue;
        }
        if (!shg_do_move(b, m, &u)) continue;
        nodes += perft_from(b, depth - 1, counts);
        shg_undo_move(b, &u);
    }
    return nodes;
}

unsigned long long shg_perft(const struct shg_board *b, int depth, unsigned long long *counts)
{
    struct shg_board copy;
    int i;
    if (counts) for (i = 0; i < SHG_PERFT_COUNTS; i++) counts[i] = 0;
    if (!b || depth < 0) return 0;
    if (depth == 0) {
        if (counts) counts[SHG_PERFT_NODES] = 1;
        return 1;
    }
    copy = *b;
    return perft_from(&copy, depth, counts);
}

/* ---- how a position stands, version 4 ------------------------------------ */

int shg_status(const struct shg_board *b)
{
    if (!b) return -1;
    if (shg_has_legal_move(b)) return SHG_ONGOING;
    return shg_in_check(b, b->to_move) ? SHG_MATE : SHG_NO_MOVE;
}
