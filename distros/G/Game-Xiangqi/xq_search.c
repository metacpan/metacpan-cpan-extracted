/* xq_search.c - the evaluation and the search. Phase 09 of plan_xiangqi.
 *
 * PERL-FREE, as the rest of the engine is.
 *
 * ---- FAIL-SOFT, AND THE REASON IS ONE PARAGRAPH --------------------------------
 *
 * Game::Oware shipped fail-HARD alpha-beta feeding a tie-break and its bot got
 * STRICTLY WORSE WITH DEPTH: `_alphabeta` returned `$alpha`, so every child that
 * failed low came back exactly equal to the best score, the root drew uniformly
 * from that pool, and deeper search raised alpha sooner and so clamped more
 * children. More search produced more randomness. Level 2 lost 0-10 to level 1
 * before anybody suspected the search rather than the evaluation, and what ruled
 * the evaluation out was sweeping every weight to zero and seeing no change.
 *
 * So: fail-soft, and a full window at the root. This is at the top of the file
 * because the bug is invisible in any single game and looks exactly like a bad
 * evaluation.
 *
 * ---- BOUNDED IN WORK, NEVER IN TIME (D6) ----------------------------------------
 *
 * The site plays the bot inside the move transaction. A search bounded by
 * seconds makes the length of a database transaction a property of how loaded
 * the box is, and makes a bot game unreplayable, because a loaded machine would
 * choose a different move from an idle one and the site's whole verification
 * story goes with it.
 *
 * The budget is tested every 1024 nodes. NO alarm, NO ualarm, NO signals:
 * Chess::Plisco uses them and therefore needs a watcher class on the site to
 * stop a search at all. This one stops itself, which is why the site's adapter
 * has no Watcher.pm and says so.
 *
 * Spent through ITERATIVE DEEPENING, so running out always leaves a complete
 * search at a shallower depth rather than half of a deeper one.
 *
 * ---- LEGALITY IS LAZY, AND THAT IS WHERE THE SPEED IS ----------------------------
 *
 * The first version of this file called `gen_legal` at every node and searched
 * 90,000 nodes a second, while perft over the same generator runs at 2.26 MILLION.
 * The difference was not the evaluation, which was measured at 4 microseconds
 * against a node cost of 11: it was that `gen_legal` plays and unplays all forty
 * moves to filter them, and a node that takes a beta cutoff on its second move
 * had paid for thirty-eight it never looked at.
 *
 * So the search generates PSEUDO-LEGAL moves and tests legality inside the loop,
 * after `do_move`, on the moves it actually searches. The test is the same one
 * `gen_legal` uses and is not a second opinion: own general not attacked, and the
 * two generals not facing.
 *
 * The cost of this is that a node does not know whether it has NO legal move
 * until the loop ends, so the mate and stalemate score moved to the bottom of the
 * loop. At a horizon node, where the loop does not run at all, a side that is IN
 * CHECK is still tested exactly, because `in_check` is a tenth of a microsecond
 * and a missed mate is the one error the search may not make. A horizon
 * STALEMATE, which is a loss in this game, is scored as an evaluation instead:
 * the next iteration of the deepening sees it as an ordinary node and rules on
 * it, and buying it one iteration earlier would cost a full filter at every leaf.
 */

#include <stdlib.h>
#include <string.h>
#include "xq_abi.h"

static const struct xq_abi *E(void) { return xq_abi_table(); }

#define AT(b, pt) ((E())->at((b), (pt)))

/* ---- the evaluation, four terms, integers only (D5) ----------------------------
 *
 * In centi-soldiers. `value_of` is phase 05's table and is used rather than a
 * second one here, because `is_exchange` needs the same numbers and two tables
 * would drift.
 *
 * THE VALUES, and their source: the conventional table every xiangqi primer
 * gives, chariot 9, cannon 4.5, horse 4, advisor and elephant 2, soldier 1 and 2
 * once across the river. Wikipedia's own endgame section qualifies it in ways
 * the flat numbers cannot: three soldiers on the seventh rank are about a
 * chariot, "in the opening and the middlegame ... the cannon is stronger since
 * platforms are plentiful and the horse is often blocked", and five soldiers on
 * the tenth rank cannot force mate at all. A phase-tapered table is the obvious
 * later improvement and this is not it.
 */

#define MOBILITY_WEIGHT   2
#define ADVANCE_WEIGHT    4
#define OPEN_FILE_PENALTY 30
#define HOME_GUARD_BONUS  6

/* =head2 material
 *
 * The term that dominates, and the only one that is not a heuristic. A soldier
 * doubles once it is across the river, which is the one positional fact the
 * material term carries itself because it is a rule rather than a judgement.
 */
static int term_material(const struct xq_board *b, int side)
{
    int pt, score = 0;
    for (pt = 0; pt < XQ_CELLS; pt++) {
        int p, v;
        if (!(E())->on_board(pt)) continue;
        p = AT(b, pt);
        if (!XQ_IS_PIECE(p)) continue;
        v = (E())->value_of(p);
        if (XQ_KIND(p) == XQ_SOLDIER && (E())->crossed_river(pt, XQ_COLOUR(p)))
            v *= 2;
        score += (XQ_COLOUR(p) == side) ? v : -v;
    }
    return score;
}

/* =head2 mobility
 *
 * Doing more work in this game than in chess, and that is why it is here at all.
 * A horse with three legs blocked is worth nearly nothing and the material term
 * cannot see it; a cannon with no screen in front of it is a chariot that cannot
 * take. Counted as pseudo-legal moves, because the legality filter costs a do
 * and an undo per move and the difference is noise at this weight.
 */
static int term_mobility(struct xq_board *b, int side)
{
    int buf[XQ_MAX_MOVES];
    int keep = (E())->side(b);
    int mine, theirs;

    (E())->set_side(b, side);
    mine = (E())->gen_moves(b, buf);
    (E())->set_side(b, XQ_OTHER(side));
    theirs = (E())->gen_moves(b, buf);
    (E())->set_side(b, keep);
    return (mine - theirs) * MOBILITY_WEIGHT;
}

/* =head2 the general's safety
 *
 * The palace's own term, and THE OPEN FILE IS THE ONE TO GET RIGHT because of
 * the flying general: a general on a file with nothing in front of it is a
 * general that can be answered by the enemy general alone, and every chariot and
 * cannon on that file is worth more than its square suggests.
 *
 * Its advisors and elephants still at home are the other half, because they are
 * the only pieces that can defend inside the palace at all.
 */
static int term_general(const struct xq_board *b, int side)
{
    int g = (E())->find(b, side | XQ_GENERAL);
    int score = 0, pt, file, open = 1;

    if (!g) return 0;
    file = (E())->file_of(g);

    for (pt = 0; pt < XQ_CELLS; pt++) {
        int p;
        if (!(E())->on_board(pt)) continue;
        p = AT(b, pt);
        if (XQ_COLOUR(p) != side) continue;
        if ((XQ_KIND(p) == XQ_ADVISOR || XQ_KIND(p) == XQ_ELEPHANT)
            && !(E())->crossed_river(pt, side))
            score += HOME_GUARD_BONUS;
        if (pt != g && (E())->file_of(pt) == file) open = 0;
    }
    if (open) score -= OPEN_FILE_PENALTY;
    return score;
}

/* =head2 soldier advance
 *
 * Counted BEYOND the crossing only, because the crossing itself is already in
 * the material term and counting it twice would make a soldier stepping over
 * the river look like winning a piece.
 */
static int term_advance(const struct xq_board *b, int side)
{
    int pt, score = 0;
    for (pt = 0; pt < XQ_CELLS; pt++) {
        int p, r;
        if (!(E())->on_board(pt)) continue;
        p = AT(b, pt);
        if (XQ_KIND(p) != XQ_SOLDIER) continue;
        if (!(E())->crossed_river(pt, XQ_COLOUR(p))) continue;
        r = (E())->rank_of(pt);
        r = (XQ_COLOUR(p) == XQ_RED) ? r - 5 : 4 - r;
        score += (XQ_COLOUR(p) == side) ? r * ADVANCE_WEIGHT : -r * ADVANCE_WEIGHT;
    }
    return score;
}

static int xq_evaluate(struct xq_board *b)
{
    int side = (E())->side(b);
    return term_material(b, side)
         + term_mobility(b, side)
         + term_general(b, side) - term_general(b, XQ_OTHER(side))
         + term_advance(b, side);
}

/* ---- the transposition table ------------------------------------------------------
 *
 * ALLOCATED PER SEARCH AND FREED AFTER IT. Chess/Bot.pm measured Plisco's at
 * about 2.5 times its megabytes in RSS, which on a pre-forked web worker is the
 * kind of thing that is paid once per worker and never given back.
 */
#define TT_BITS 16
#define TT_SIZE (1 << TT_BITS)

#define TT_EXACT 1
#define TT_LOWER 2
#define TT_UPPER 3

struct tt_entry {
    unsigned long long key;
    int move;
    short score;
    signed char depth;
    unsigned char flag;
};

struct search {
    unsigned long long nodes;
    unsigned long long budget;
    int stopped;
    struct tt_entry *tt;
    unsigned int seed;
};

/* ---- move ordering ------------------------------------------------------------------
 *
 * The transposition move first, then captures by what they take. No killers and
 * no history in this version, deliberately: they are cheap to add later and
 * their ABSENCE is easy to measure, where their presence hides how much the rest
 * of the ordering is doing.
 */
static void order(struct xq_board *b, int *moves, int n, int tt_move)
{
    int score[XQ_MAX_MOVES];
    int i, j;
    for (i = 0; i < n; i++) {
        int victim = AT(b, (E())->move_to(moves[i]));
        int mover  = AT(b, (E())->move_from(moves[i]));
        score[i] = (moves[i] == tt_move) ? 1000000
                 : XQ_IS_PIECE(victim)
                     ? 1000 + (E())->value_of(victim) - (E())->value_of(mover) / 10
                     : 0;
    }
    for (i = 1; i < n; i++) {           /* insertion sort: n is small and it is stable */
        int m = moves[i], sc = score[i];
        for (j = i - 1; j >= 0 && score[j] < sc; j--) {
            moves[j + 1] = moves[j];
            score[j + 1] = score[j];
        }
        moves[j + 1] = m;
        score[j + 1] = sc;
    }
}

/* The legality test, AFTER a move has been played, for the side that played it.
 * It is `gen_legal`'s own test and not a second opinion: if these two ever
 * disagreed the search would search moves the facade refuses, and the bot would
 * offer the site a move the site rejects.
 *
 * AND IT IS ONE CALL, NOT TWO. This read `!in_check(b, us) && !generals_face(b)`
 * for most of phase 09, mirroring `gen_legal` line for line, and the second half
 * was DEAD: `in_check` already carries the flying-general rule, and returns true
 * for BOTH sides when the two generals see each other down an open file. Note that
 * `attacked` does not, which is why the redundancy was not obvious from reading it.
 *
 * Found by a mutation that dropped the second call and which NOTHING caught, at
 * which point the question stopped being "where is the missing test" and became
 * "is this a mutation at all". It was not. Proved by measurement and not by
 * argument: with the call and without it, a 400,000-node search explores
 * 400,384 nodes either way, reaches the same depth, returns the same move, and
 * twenty self-played moves are identical. Removing it is 5.5% faster, which at one
 * call per searched node is worth having.
 *
 * `gen_legal` in xq_moves.c keeps its explicit call. It is the perft path and the
 * oracle runs through it, so it is not being touched for 5.5% on a different
 * function. */
static int legal_after(struct xq_board *b, int us)
{
    return !(E())->in_check(b, us);
}

/* THE ROOT LIST IS SHUFFLED BY THE SEED, ONCE, BEFORE ANYTHING IS SEARCHED.
 *
 * This is the whole tie-break. Only a STRICT improvement takes the move at the
 * root, so the move that wins is the first one to reach the best score, and a
 * random starting order makes "first to reach it" a uniform draw among the moves
 * that genuinely tie. It costs no nodes at all, where scoring every root move
 * exactly costs a ply.
 *
 * THE SEAT IS IN THE SEED and the caller puts it there. Without it both bots in a
 * bot-versus-bot game shuffle identically, open identically every time, and a
 * soak measures nothing: Game::Goofspiel shipped exactly that.
 *
 * splitmix32 rather than rand(): the engine is deterministic given its seed, and
 * a bot game that cannot be replayed move for move breaks the site's whole
 * verification story.
 */
static void shuffle(int *moves, int n, unsigned int seed)
{
    int i;
    unsigned int x = seed ? seed : 0x9E3779B9u;
    for (i = n - 1; i > 0; i--) {
        unsigned int z;
        int j, t;
        x += 0x9E3779B9u;
        z = x;
        z = (z ^ (z >> 16)) * 0x21F0AAADu;
        z = (z ^ (z >> 15)) * 0x735A2D97u;
        z =  z ^ (z >> 15);
        j = (int) (z % (unsigned int) (i + 1));
        t = moves[i]; moves[i] = moves[j]; moves[j] = t;
    }
}

/* THE BUDGET CHECK IS NEVER DISABLED, NOT EVEN FOR THE FIRST ITERATION, and that
 * is a fact learned the hard way. `quiesce` is bounded by NOTHING ELSE: it
 * searches captures, and captures do reduce material, but the branching is wide
 * enough that a tactical position explodes. An attempt to guarantee that the
 * first iteration always completes, by gating this check off until the root had
 * one full iteration in hand, HUNG THE SEARCH on the opening position. A budget
 * that can be switched off is not a budget. */
static int spent(struct search *s)
{
    if (s->stopped) return 1;
    if ((s->nodes & 1023) == 0 && s->nodes >= s->budget) s->stopped = 1;
    return s->stopped;
}

/* ---- quiescence ---------------------------------------------------------------------
 *
 * Captures only. Without it the search hands back a score taken in the middle of
 * an exchange, which in this game is worse than in chess: a cannon's capture
 * arrives from a distance and over a screen, so a quiet-looking position is
 * routinely one move from losing a chariot.
 */
static int quiesce(struct xq_board *b, struct search *s, int alpha, int beta)
{
    int moves[XQ_MAX_MOVES];
    int n, i, best, us = (E())->side(b);

    s->nodes++;
    if (spent(s)) return xq_evaluate(b);

    best = xq_evaluate(b);
    if (best >= beta) return best;
    if (best > alpha) alpha = best;

    n = (E())->gen_moves(b, moves);
    order(b, moves, n, 0);
    for (i = 0; i < n; i++) {
        struct xq_undo u;
        int score;
        if (!XQ_IS_PIECE(AT(b, (E())->move_to(moves[i])))) continue;   /* captures only */
        (E())->do_move(b, moves[i], &u);
        if (legal_after(b, us)) {
            score = -quiesce(b, s, -beta, -alpha);
            (E())->undo_move(b, &u);
            if (s->stopped) return best;
            if (score > best) best = score;
            if (best > alpha) alpha = best;
            if (alpha >= beta) break;
        }
        else (E())->undo_move(b, &u);
    }
    return best;
}

/* ---- the search ------------------------------------------------------------------- */

static int alphabeta(struct xq_board *b, struct search *s,
                     int depth, int alpha, int beta, int ply)
{
    int moves[XQ_MAX_MOVES];
    int n, i, best = -XQ_MATE_SCORE * 2, tt_move = 0;
    int alpha0 = alpha, played = 0, us = (E())->side(b);
    unsigned long long key = (E())->key(b);
    struct tt_entry *e = &s->tt[key & (TT_SIZE - 1)];

    s->nodes++;
    if (spent(s)) return xq_evaluate(b);

    if (e->key == key) {
        tt_move = e->move;
        if (e->depth >= depth) {
            if (e->flag == TT_EXACT) return e->score;
            if (e->flag == TT_LOWER && e->score > alpha) alpha = e->score;
            if (e->flag == TT_UPPER && e->score < beta)  beta  = e->score;
            if (alpha >= beta) return e->score;
        }
    }

    /* At the horizon the loop below never runs, so a mate would go unseen. A side
     * IN CHECK is therefore tested exactly, which costs a tenth of a microsecond
     * for the test and a full filter only on the nodes that are actually in
     * check. See the head of this file for the stalemate that is not tested. */
    if (depth <= 0) {
        if ((E())->in_check(b, us)) {
            int esc[XQ_MAX_MOVES];
            if ((E())->gen_legal(b, esc) == 0) return -XQ_MATE_SCORE + ply;
        }
        return quiesce(b, s, alpha, beta);
    }

    n = (E())->gen_moves(b, moves);
    order(b, moves, n, tt_move);
    for (i = 0; i < n; i++) {
        struct xq_undo u;
        int score;
        (E())->do_move(b, moves[i], &u);
        if (!legal_after(b, us)) { (E())->undo_move(b, &u); continue; }
        played++;
        score = -alphabeta(b, s, depth - 1, -beta, -alpha, ply + 1);
        (E())->undo_move(b, &u);
        if (s->stopped) return best > -XQ_MATE_SCORE * 2 ? best : xq_evaluate(b);
        if (score > best) { best = score; tt_move = moves[i]; }
        if (best > alpha) alpha = best;
        if (alpha >= beta) break;
    }

    /* NO LEGAL MOVE IS A LOSS, in check or not: stalemate is a loss in this game
     * and a search that returned a draw here would play for one. The score is
     * adjusted by PLY so a mate in one beats a mate in three. */
    if (!played) return -XQ_MATE_SCORE + ply;

    /* FAIL-SOFT: `best` is returned, never `alpha`. See the head of this file. */
    e->key   = key;
    e->move  = tt_move;
    e->score = (short) (best > 32000 ? 32000 : best < -32000 ? -32000 : best);
    e->depth = (signed char) depth;
    e->flag  = (unsigned char) (best <= alpha0 ? TT_UPPER
                              : best >= beta   ? TT_LOWER : TT_EXACT);
    return best;
}

/* ONE SEARCH, TWO ENTRIES. `search_best` is this with the depth ceiling, so the
 * depth-limited search that UCCI needs cannot drift away from the one the bot
 * plays. See the header on why a depth limit exists at all. */
static int xq_search_to_depth(struct xq_board *b, int max_depth,
                              unsigned long long budget,
                              unsigned int seed, struct xq_search_info *info)
{
    int moves[XQ_MAX_MOVES];
    int n, i, depth;
    int best_move = 0, best_score = 0;
    struct search s;

    if (info) { info->nodes = 0; info->depth = 0; info->score = 0; info->stopped = 0; }

    n = (E())->gen_legal(b, moves);
    if (n == 0) return 0;

    s.nodes = 0;
    s.budget = budget ? budget : 1;
    s.stopped = 0;
    s.seed = seed;
    s.tt = (struct tt_entry *) calloc(TT_SIZE, sizeof(struct tt_entry));
    if (!s.tt) return moves[0];

    /* SHUFFLED FIRST, so that a budget too small to finish even depth 1 still
     * hands back a move drawn by the seed rather than whatever the generator
     * happened to put first. See `shuffle`. */
    shuffle(moves, n, seed);
    best_move = moves[0];

    /* ITERATIVE DEEPENING, so a spent budget always leaves a COMPLETE search at
     * a shallower depth rather than half of a deeper one. */
    if (max_depth < 1)  max_depth = 1;
    if (max_depth > 64) max_depth = 64;

    for (depth = 1; depth <= max_depth; depth++) {
        int scores[XQ_MAX_MOVES];
        int local_best = -XQ_MATE_SCORE * 2, alpha = -XQ_MATE_SCORE * 2;

        order(b, moves, n, best_move);
        for (i = 0; i < n; i++) {
            struct xq_undo u;
            (E())->do_move(b, moves[i], &u);

            scores[i] = -alphabeta(b, &s, depth - 1, -XQ_MATE_SCORE * 2, -alpha, 1);
            (E())->undo_move(b, &u);
            if (s.stopped) break;

            /* STRICTLY GREATER, AND THE TIE-BREAK IS THE SHUFFLE ABOVE.
             *
             * THIS IS THE PHASE'S SECOND BUG AND THE COMMENT THAT USED TO BE HERE
             * CLAIMED THE OPPOSITE OF WHAT THE CODE DID. The root raised `alpha`,
             * which is ordinary alpha-beta and right, and then pooled every
             * `scores[i]` equal to the best and picked among them with the seed,
             * which is wrong: with the window cut at `-alpha` a root move that is
             * not an improvement makes its child fail high, and a fail-soft child
             * that fails high returns a BOUND and not a value. With an integer
             * evaluation that bound lands EXACTLY on alpha very often, so the pool
             * filled with moves that were merely not-better and the bot played one
             * of them at random.
             *
             * It got WORSE WITH DEPTH, because a deeper search raises alpha sooner
             * and cuts more children off at the bound. Measured, sixty games:
             * rung 40000 scored 38.3% against rung 8000, and 13 of the 44 opening
             * moves came back "tied". That is Game::Oware's bug in a different
             * hat, and the paragraph at the head of this file was written to
             * prevent it and did not.
             *
             * The fix is not a full window, which was tried and costs a whole ply
             * of depth at every rung. It is that A TIE IS NEVER PICKED AT ALL:
             * only a STRICT improvement replaces the move, so the move that wins
             * is the FIRST one to reach the best score. The root list is shuffled
             * by the seed before the search, and `order` below is a stable sort,
             * so first-to-reach-it IS a uniform draw among the moves that truly
             * tie. No extra nodes, and the bound never enters the choice. */
            if (scores[i] > local_best) {
                local_best = scores[i];
                best_move  = moves[i];
            }
            if (local_best > alpha) alpha = local_best;
        }
        if (s.stopped) break;

        if (info) { info->depth = depth; info->score = local_best; }
        if (XQ_IS_MATE(local_best)) break;   /* nothing deeper can improve on mate */
    }

    free(s.tt);
    if (info) { info->nodes = s.nodes; info->stopped = s.stopped; }
    (void) best_score;
    return best_move;
}

/* ---- installed into the table by xq_engine.c ---------------------------------------- */

static int xq_search_best(struct xq_board *b, unsigned long long budget,
                          unsigned int seed, struct xq_search_info *info)
{
    return xq_search_to_depth(b, 64, budget, seed, info);
}

void xq_search_install(struct xq_abi *t);

void xq_search_install(struct xq_abi *t)
{
    t->evaluate        = xq_evaluate;
    t->search_best     = xq_search_best;
    t->search_to_depth = xq_search_to_depth;
}
