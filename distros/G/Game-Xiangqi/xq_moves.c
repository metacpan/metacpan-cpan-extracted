/* xq_moves.c - move generation, the attack walk, and perft.
 *
 * PERL-FREE, as xq_engine.c is. Phase 03 of plan_xiangqi.
 *
 * THE FIVE PREDICATES EACH HAVE A NAME so a test can address one. A generator
 * written as a single loop with the blocking folded in cannot be tested in
 * pieces, and four of the five are the rules a reader gets wrong:
 *
 *   horse_leg        the orthogonal step must be empty, either colour blocks
 *   elephant_eye     the intervening diagonal point must be empty
 *   cannon_screens   exactly one, and only for a capture
 *   soldier_may      forward always, sideways only across the river, never back
 *   generals_face    the flying general, implemented as an ATTACK
 *
 * ONE DEVIATION FROM THE PLAN, and it is a phase boundary rather than a
 * decision: `attacked` was scoped to phase 04, and it cannot be, because
 * `gen_legal` filters on "does this leave my own general attacked" and perft
 * counts LEGAL moves. Generation cannot be finished without it. Phase 04 keeps
 * `outcome`, `mate_in` and the stalemate loss, which genuinely are its own.
 */

#include <string.h>
#include "xq_abi.h"

/* xq_engine.c owns the struct; this file reaches it through the same table
 * every other consumer uses, which keeps the two files honest about the
 * interface and costs one indirection per call in code that is not the search. */
static const struct xq_abi *E(void) { return xq_abi_table(); }

#define AT(b, pt)   ((E())->at((b), (pt)))
#define PT(f, r)    ((E())->point_of((f), (r)))
#define FILE_OF(pt) ((E())->file_of(pt))
#define RANK_OF(pt) ((E())->rank_of(pt))
#define ONB(pt)     ((E())->on_board(pt))

static const int ORTHO[4] = { -1, 1, -XQ_STRIDE, XQ_STRIDE };
static const int DIAG[4]  = { -XQ_STRIDE - 1, -XQ_STRIDE + 1, XQ_STRIDE - 1, XQ_STRIDE + 1 };

/* ---- the five predicates ----------------------------------------------------- */

/* The horse's eight destinations are eight PAIRS: one orthogonal step, which
 * must be empty, then one diagonal away from it. The blocker is of either
 * colour and there are four blocking points for eight destinations.
 *
 * THE MISTAKE TO AVOID is testing the blocker against the destination's own
 * neighbour. Both readings agree for six of the eight and differ for two, which
 * is the shape of a bug that wins most of its games.
 */
static int xq_horse_leg(const struct xq_board *b, int from, int to)
{
    int d = to - from, i;
    static const int MOVE[8] = {
        -2 * XQ_STRIDE - 1, -2 * XQ_STRIDE + 1,   /* two up,   one across */
         2 * XQ_STRIDE - 1,  2 * XQ_STRIDE + 1,   /* two down, one across */
        -XQ_STRIDE - 2, -XQ_STRIDE + 2,           /* one up,   two across */
         XQ_STRIDE - 2,  XQ_STRIDE + 2
    };
    static const int LEG[8] = {
        -XQ_STRIDE, -XQ_STRIDE, XQ_STRIDE, XQ_STRIDE, -1, 1, -1, 1
    };
    (void) b;
    for (i = 0; i < 8; i++)
        if (d == MOVE[i]) return from + LEG[i];
    return -1;
}

/* "Exactly two points diagonally and may not jump over intervening pieces", and
 * the intervening point is the eye. Four destinations, four eyes, one each. */
static int xq_elephant_eye(const struct xq_board *b, int from, int to)
{
    int d = to - from, i;
    (void) b;
    for (i = 0; i < 4; i++)
        if (d == 2 * DIAG[i]) return from + DIAG[i];
    return -1;
}

/* One ray walk answers both halves of the cannon.
 *
 *   0 screens, destination empty        a move
 *   0 screens, destination occupied     NOT a move: a cannon does not capture
 *                                       adjacently, and this is the row that
 *                                       gets written wrong
 *   1 screen,  destination enemy        a capture
 *   1 screen,  destination own or empty nothing
 *   2 or more                           nothing
 */
static int xq_cannon_screens(const struct xq_board *b, int from, int to)
{
    int df = FILE_OF(to) - FILE_OF(from);
    int dr = RANK_OF(to) - RANK_OF(from);
    int step, pt, n = 0;

    if (from == to) return -1;
    if (!ONB(from) || !ONB(to)) return -1;
    if (df != 0 && dr != 0) return -1;
    step = (df != 0) ? (df > 0 ? 1 : -1) : (dr > 0 ? XQ_STRIDE : -XQ_STRIDE);
    for (pt = from + step; pt != to; pt += step)
        if (AT(b, pt) != XQ_EMPTY) n++;
    return n;
}

/* One point forward; sideways as well once across the river; NEVER backward and
 * never promoted. A soldier on the enemy's last rank has only its sideways
 * moves, which is a rule and not a dead end. */
static int xq_soldier_may(const struct xq_board *b, int from, int to)
{
    int piece = AT(b, from);
    int colour = XQ_COLOUR(piece);
    int d = to - from;
    int fwd = (colour == XQ_RED) ? XQ_STRIDE : -XQ_STRIDE;

    if (XQ_KIND(piece) != XQ_SOLDIER) return 0;
    if (!ONB(to)) return 0;
    if (d == fwd) return 1;
    if ((d == 1 || d == -1) && (E())->crossed_river(from, colour)) return 1;
    return 0;
}

/* The flying general. The generals may not end a move facing each other down an
 * open file, and the encyclopaedia's sentence is the one that matters: "creating
 * this situation in the first place means moving into check, and is therefore
 * not allowed". So this is not a special case in the generator: gen_legal
 * refuses any move that leaves it true, in both directions, with no extra
 * branch, and the flying capture itself is therefore never generated. */
static int xq_generals_face(const struct xq_board *b)
{
    int rg = (E())->find(b, XQ_RED | XQ_GENERAL);
    int bg = (E())->find(b, XQ_BLACK | XQ_GENERAL);
    int pt;

    if (!rg || !bg) return 0;
    if (FILE_OF(rg) != FILE_OF(bg)) return 0;
    for (pt = rg + XQ_STRIDE; pt < bg; pt += XQ_STRIDE)
        if (AT(b, pt) != XQ_EMPTY) return 0;
    return 1;
}

/* ---- generation --------------------------------------------------------------
 *
 * PSEUDO-LEGAL: every move the piece may make, without asking whether it leaves
 * its own general attacked. gen_legal filters these.
 */

static int add(int *out, int n, int from, int to)
{
    if (n >= XQ_MAX_MOVES) return n;
    out[n] = (E())->move_make(from, to);
    return n + 1;
}

static int xq_gen_moves(const struct xq_board *b, int *out)
{
    int side = (E())->side(b);
    int n = 0, f, r, i;

    for (r = 0; r < XQ_RANKS; r++) {
    for (f = 0; f < XQ_FILES; f++) {
        int from = PT(f, r);
        int piece = AT(b, from);
        int kind;
        if (XQ_COLOUR(piece) != side) continue;
        kind = XQ_KIND(piece);

        switch (kind) {
        case XQ_GENERAL:
            for (i = 0; i < 4; i++) {
                int to = from + ORTHO[i];
                if (!(E())->in_palace(to, side)) continue;
                if (XQ_COLOUR(AT(b, to)) == side) continue;
                n = add(out, n, from, to);
            }
            break;

        case XQ_ADVISOR:
            for (i = 0; i < 4; i++) {
                int to = from + DIAG[i];
                if (!(E())->in_palace(to, side)) continue;
                if (XQ_COLOUR(AT(b, to)) == side) continue;
                n = add(out, n, from, to);
            }
            break;

        case XQ_ELEPHANT:
            for (i = 0; i < 4; i++) {
                int to = from + 2 * DIAG[i];
                if (!ONB(to)) continue;
                /* never crosses the river: the elephant stays on its own half */
                if ((E())->crossed_river(to, side)) continue;
                if (AT(b, from + DIAG[i]) != XQ_EMPTY) continue;   /* the eye */
                if (XQ_COLOUR(AT(b, to)) == side) continue;
                n = add(out, n, from, to);
            }
            break;

        case XQ_HORSE:
            for (i = 0; i < 8; i++) {
                static const int MOVE[8] = {
                    -2 * XQ_STRIDE - 1, -2 * XQ_STRIDE + 1,
                     2 * XQ_STRIDE - 1,  2 * XQ_STRIDE + 1,
                    -XQ_STRIDE - 2, -XQ_STRIDE + 2,
                     XQ_STRIDE - 2,  XQ_STRIDE + 2
                };
                int to = from + MOVE[i];
                int leg;
                if (!ONB(to)) continue;
                leg = xq_horse_leg(b, from, to);
                if (leg < 0 || AT(b, leg) != XQ_EMPTY) continue;
                if (XQ_COLOUR(AT(b, to)) == side) continue;
                n = add(out, n, from, to);
            }
            break;

        case XQ_CHARIOT:
            for (i = 0; i < 4; i++) {
                int to;
                for (to = from + ORTHO[i]; ONB(to); to += ORTHO[i]) {
                    int t = AT(b, to);
                    if (t == XQ_EMPTY) { n = add(out, n, from, to); continue; }
                    if (XQ_COLOUR(t) != side) n = add(out, n, from, to);
                    break;
                }
            }
            break;

        case XQ_CANNON:
            for (i = 0; i < 4; i++) {
                int to, seen = 0;
                for (to = from + ORTHO[i]; ONB(to); to += ORTHO[i]) {
                    int t = AT(b, to);
                    if (!seen) {
                        if (t == XQ_EMPTY) { n = add(out, n, from, to); continue; }
                        seen = 1;             /* the screen; not a capture */
                        continue;
                    }
                    if (t == XQ_EMPTY) continue;
                    if (XQ_COLOUR(t) != side) n = add(out, n, from, to);
                    break;                    /* one screen only, ever */
                }
            }
            break;

        case XQ_SOLDIER:
            {
                int fwd = (side == XQ_RED) ? XQ_STRIDE : -XQ_STRIDE;
                int cand[3];
                int c = 0, k;
                cand[c++] = from + fwd;
                if ((E())->crossed_river(from, side)) {
                    cand[c++] = from - 1;
                    cand[c++] = from + 1;
                }
                for (k = 0; k < c; k++) {
                    int to = cand[k];
                    if (!ONB(to)) continue;
                    if (XQ_COLOUR(AT(b, to)) == side) continue;
                    n = add(out, n, from, to);
                }
            }
            break;

        default:
            break;
        }
    }
    }
    return n;
}

/* ---- the attack walk ---------------------------------------------------------
 *
 * Generated BACKWARDS from the point rather than forwards from every piece,
 * which is what makes the legality filter affordable. Three things here are not
 * a chess engine's:
 *
 *   the cannon needs exactly one screen, so the ray walk counts
 *   the horse is blocked, and the leg is checked FROM THE HORSE'S SIDE
 *   the general attacks its orthogonal neighbours inside its own palace
 */
static int xq_attacked(const struct xq_board *b, int pt, int by)
{
    int i;

    if (!ONB(pt)) return 0;

    /* chariots and cannons share the ray: the first piece along it can be a
     * chariot, and the first piece BEYOND that first piece can be a cannon */
    for (i = 0; i < 4; i++) {
        int s, first = 0, t;
        for (s = pt + ORTHO[i]; ONB(s); s += ORTHO[i]) {
            t = AT(b, s);
            if (t == XQ_EMPTY) continue;
            if (!first) {
                if (XQ_COLOUR(t) == by && XQ_KIND(t) == XQ_CHARIOT) return 1;
                /* A general one step away, and THE TARGET must be in that
                 * general's palace, not merely the general itself. A general
                 * cannot leave its palace, so it cannot capture outside one;
                 * testing the general's own square instead said that a general
                 * on d2 attacked c2, which made an enemy piece there look
                 * defended when it was not.
                 *
                 * PERFT CANNOT SEE THIS, which is why it survived phase 03: the
                 * only point `attacked` is asked about during a legality filter
                 * is a general, and a general is always inside its own palace.
                 * Phase 05's `protected_at` would have inherited it. */
                if (XQ_COLOUR(t) == by && XQ_KIND(t) == XQ_GENERAL
                    && s == pt + ORTHO[i] && (E())->in_palace(pt, by)) return 1;
                first = 1;
                continue;
            }
            if (XQ_COLOUR(t) == by && XQ_KIND(t) == XQ_CANNON) return 1;
            break;
        }
    }

    /* horses: eight origins, each with its leg tested from the horse's side */
    {
        static const int MOVE[8] = {
            -2 * XQ_STRIDE - 1, -2 * XQ_STRIDE + 1,
             2 * XQ_STRIDE - 1,  2 * XQ_STRIDE + 1,
            -XQ_STRIDE - 2, -XQ_STRIDE + 2,
             XQ_STRIDE - 2,  XQ_STRIDE + 2
        };
        for (i = 0; i < 8; i++) {
            int from = pt - MOVE[i];
            int t, leg;
            if (!ONB(from)) continue;
            t = AT(b, from);
            if (XQ_COLOUR(t) != by || XQ_KIND(t) != XQ_HORSE) continue;
            leg = xq_horse_leg(b, from, pt);
            if (leg >= 0 && AT(b, leg) == XQ_EMPTY) return 1;
        }
    }

    /* elephants and advisors capture too, and a legality filter that forgets
     * them lets a general walk onto a defended point */
    for (i = 0; i < 4; i++) {
        int from = pt - 2 * DIAG[i];
        int t;
        if (ONB(from)) {
            t = AT(b, from);
            if (XQ_COLOUR(t) == by && XQ_KIND(t) == XQ_ELEPHANT
                && AT(b, from + DIAG[i]) == XQ_EMPTY
                && !(E())->crossed_river(pt, by)) return 1;
        }
        from = pt - DIAG[i];
        if (ONB(from)) {
            t = AT(b, from);
            if (XQ_COLOUR(t) == by && XQ_KIND(t) == XQ_ADVISOR
                && (E())->in_palace(from, by) && (E())->in_palace(pt, by)) return 1;
        }
    }

    /* soldiers: one behind, and one to each side once it is across the river */
    {
        int back = (by == XQ_RED) ? -XQ_STRIDE : XQ_STRIDE;
        int from = pt + back, t;
        if (ONB(from)) {
            t = AT(b, from);
            if (XQ_COLOUR(t) == by && XQ_KIND(t) == XQ_SOLDIER) return 1;
        }
        for (i = -1; i <= 1; i += 2) {
            from = pt + i;
            if (!ONB(from)) continue;
            t = AT(b, from);
            if (XQ_COLOUR(t) == by && XQ_KIND(t) == XQ_SOLDIER
                && (E())->crossed_river(from, by)) return 1;
        }
    }

    return 0;
}

/* IN CHECK INCLUDES THE FLYING GENERAL, and `attacked` deliberately does not.
 *
 * `attacked` answers "could a piece of that colour capture this point", which is
 * a question about pieces and is what the perft ladder validates. Facing
 * generals are a question about the two generals only, so folding it into the
 * general walk would make `attacked` answer differently for one point than for
 * every other, which is a worse interface.
 *
 * It matters here and nowhere else: after a LEGAL move the generals never face,
 * so perft never asks. A position built by hand or read from a FEN can have them
 * facing, and without this a mated general reads as STALEMATED, which phase 04
 * will turn into the right result by the wrong route. Found by building a mate
 * fixture for t/04 and being told it was not check. */
static int xq_in_check(const struct xq_board *b, int colour)
{
    int g = (E())->find(b, colour | XQ_GENERAL);
    if (!g) return 0;
    if (xq_generals_face(b)) return 1;
    return xq_attacked(b, g, XQ_OTHER(colour));
}

/* A move is legal when it leaves your own general unattacked AND does not leave
 * the two generals facing each other. The second clause is the flying general
 * and it is why that rule costs nothing anywhere else. */
static int xq_gen_legal(struct xq_board *b, int *out)
{
    int buf[XQ_MAX_MOVES];
    int n = xq_gen_moves(b, buf);
    int side = (E())->side(b);
    int i, k = 0;

    for (i = 0; i < n; i++) {
        struct xq_undo u;
        (E())->do_move(b, buf[i], &u);
        if (!xq_in_check(b, side) && !xq_generals_face(b)) out[k++] = buf[i];
        (E())->undo_move(b, &u);
    }
    return k;
}

/* ---- perft --------------------------------------------------------------------
 *
 * In C because depth 4 is 3.29 million nodes and depth 5 is 133 million: a Perl
 * loop over do_move and undo_move would take the afternoon. The oracle is
 * external either way, which is the point: this counts, the wiki says what the
 * count should be.
 *
 * NODES, CHECKS AND CAPTURES ARE ABOUT THE LEAF PLY. Of the 44 moves at depth 1,
 * two are captures and none gives check, which is what the published table says.
 *
 * MATES ARE NOT, AND THAT COST AN HOUR. They are counted at the NODE whose side
 * to move is mated, which is one ply EARLIER than the move that delivered the
 * mate. So a mate delivered by the third move is counted by perft(4) and not by
 * perft(3).
 *
 * The first version here counted a mate at the move that delivered it, which is
 * the reading the column name invites, and it produced a table that agreed with
 * the source on nodes, checks and captures at EVERY depth of every position and
 * disagreed on mates at every depth by exactly one ply: 23, 1537 and 41673 all
 * appeared one row too early. Three columns matching exactly is what said the
 * generator was right and the accounting was ours; a single-column ladder would
 * have read as a bug in the rules and sent somebody into the cannon code.
 */
static void perft_go(struct xq_board *b, int depth, struct xq_perft *out)
{
    int moves[XQ_MAX_MOVES];
    int n = xq_gen_legal(b, moves);
    int side = (E())->side(b);
    int them = XQ_OTHER(side);
    int i;

    /* No legal move: the side to move is mated if it is in check, and
     * stalemated if it is not, which phase 04 will make a loss as well. Either
     * way this node has no descendants and contributes no nodes.
     *
     * THE MATE IS COUNTED ONLY AT THE LEAF PLY, which is `depth == 1`. Counting
     * it at every depth accumulates the shallower plies' mates into the deeper
     * rows: position 2 at depth 5 then reads 1560, which is the true 1537 plus
     * the 23 that belong to depth 4. That version PASSED THE WHOLE t/ SUITE,
     * because the positions run there have no mates above the leaf ply, and only
     * xt/perft-deep.t found it. */
    if (n == 0) {
        if (depth == 1 && xq_in_check(b, side)) out->mates++;
        return;
    }

    if (depth == 1) {
        for (i = 0; i < n; i++) {
            struct xq_undo u;
            int captured = (E())->do_move(b, moves[i], &u);
            out->nodes++;
            if (captured != XQ_EMPTY) out->captures++;
            if (xq_in_check(b, them)) out->checks++;
            (E())->undo_move(b, &u);
        }
        return;
    }
    for (i = 0; i < n; i++) {
        struct xq_undo u;
        (E())->do_move(b, moves[i], &u);
        perft_go(b, depth - 1, out);
        (E())->undo_move(b, &u);
    }
}

static void xq_perft(struct xq_board *b, int depth, struct xq_perft *out)
{
    out->nodes = out->checks = out->captures = out->mates = 0;
    if (depth < 1) { out->nodes = 1; return; }
    perft_go(b, depth, out);
}

/* ---- installed into the table by xq_engine.c --------------------------------- */

void xq_moves_install(struct xq_abi *t);

void xq_moves_install(struct xq_abi *t)
{
    t->horse_leg      = xq_horse_leg;
    t->elephant_eye   = xq_elephant_eye;
    t->cannon_screens = xq_cannon_screens;
    t->soldier_may    = xq_soldier_may;
    t->generals_face  = xq_generals_face;
    t->gen_moves      = xq_gen_moves;
    t->gen_legal      = xq_gen_legal;
    t->attacked       = xq_attacked;
    t->in_check       = xq_in_check;
    t->perft          = xq_perft;
}
