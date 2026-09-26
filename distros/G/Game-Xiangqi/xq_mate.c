/* xq_mate.c - how a game ended, and the fixed-depth mate search.
 *
 * PERL-FREE, as the rest of the engine is. Phase 04 of plan_xiangqi.
 *
 * TWO FUNCTIONS, AND THE FIRST ONE IS THE RULE EVERYBODY GETS WRONG.
 */

#include "xq_abi.h"

static const struct xq_abi *E(void) { return xq_abi_table(); }

/* ---- the ending ---------------------------------------------------------------
 *
 *     "Unlike in chess, in which stalemate is a draw, in xiangqi, it is a loss
 *      for the player who has no legal move."
 *
 * ONE BRANCH, TWO REASONS, AND NO DRAW ANYWHERE IN IT. A chess engine's
 * structure is
 *
 *     if (no moves) return in_check ? MATE : DRAW;
 *
 * and a port of that ships a bug which appears only in endgames. There is
 * deliberately no `draw` value in this function at all: the draws this game has
 * are the Asian Rules' repetition rulings and the three house counters, and
 * every one of them is phase 06's. A position on its own can never be a draw.
 */
static int xq_outcome(struct xq_board *b, int *reason)
{
    int moves[XQ_MAX_MOVES];
    int side = (E())->side(b);

    if (reason) *reason = XQ_ONGOING;
    if ((E())->gen_legal(b, moves) > 0) return XQ_ONGOING;

    if (reason)
        *reason = (E())->in_check(b, side) ? XQ_BY_CHECKMATE : XQ_BY_STALEMATE;
    return XQ_OTHER(side);
}

/* ---- the mate search -----------------------------------------------------------
 *
 * A fixed-depth, alpha-beta-free recursion. The mover needs ONE move that works;
 * the defender needs EVERY reply to fail. Getting that quantifier backwards is
 * the whole bug surface of this function, and it is why t/08 has a position
 * where a mate in two does not exist: a version with `any` where `all` belongs
 * finds a mate in almost every checking position and passes every test built
 * from positions that really are mates.
 *
 * CHECKMATE SPECIFICALLY. A forced stalemate is also a win in this game and this
 * function ignores it, because its caller is the Asian Rules' "threatening to
 * checkmate" and a referee means mate when they say mate. Phase 09's search uses
 * `outcome`, which counts both.
 *
 * BOUNDED BY `plies` AND BY NOTHING ELSE: no clock, no node budget, no table.
 * Phase 05 calls it with 3. It is not the bot and must never become the bot, or
 * the judge's rulings would depend on how loaded the box is.
 */
static int mate_within(struct xq_board *b, int plies)
{
    int moves[XQ_MAX_MOVES];
    int n, i;

    if (plies < 1) return 0;
    n = (E())->gen_legal(b, moves);
    if (n == 0) return 0;                  /* the mover is itself finished */

    for (i = 0; i < n; i++) {
        struct xq_undo u;
        int reason = XQ_ONGOING;
        int over;

        (E())->do_move(b, moves[i], &u);
        over = xq_outcome(b, &reason);

        if (over && reason == XQ_BY_CHECKMATE) {
            (E())->undo_move(b, &u);
            return 1;                      /* mate on this move */
        }

        if (!over && plies >= 3) {
            int replies[XQ_MAX_MOVES];
            int m = (E())->gen_legal(b, replies);
            int j, all = 1;
            /* EVERY reply must fail to save the defender */
            for (j = 0; j < m; j++) {
                struct xq_undo v;
                (E())->do_move(b, replies[j], &v);
                if (!mate_within(b, plies - 2)) all = 0;
                (E())->undo_move(b, &v);
                if (!all) break;
            }
            if (m > 0 && all) {
                (E())->undo_move(b, &u);
                return 1;
            }
        }
        (E())->undo_move(b, &u);
    }
    return 0;
}

static int xq_mate_in(struct xq_board *b, int plies)
{
    return mate_within(b, plies);
}

/* ---- installed into the table by xq_engine.c ----------------------------------- */

void xq_mate_install(struct xq_abi *t);

void xq_mate_install(struct xq_abi *t)
{
    t->outcome = xq_outcome;
    t->mate_in = xq_mate_in;
}
