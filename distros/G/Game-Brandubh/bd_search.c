/* bd_search.c - choosing a move: an evaluation, and a search bounded in nodes.
 *
 * PERL-FREE, as the other bd_*.c files are.
 *
 * INTEGER ONLY. A score is an int and nothing here is a float, so the same
 * position, budget and seed give the same move on every machine and every
 * compiler.
 *
 * THE SEARCH NEVER READS A CLOCK. Its budget is a count of nodes, asked about
 * every 1,024 of them, and the move it returns is the best move of the last
 * iteration that FINISHED. A loaded machine therefore plays the move an idle
 * one plays, and a game against it can be played again.
 *
 * THE SEARCH KNOWS HOW A GAME ENDS. It plays its moves into a copy of the game,
 * so a line that repeats a position for the last time the rule set allows, or
 * runs into the ply cap, is scored as the draw it is. A search that did not
 * would walk into drawn positions believing it was winning them.
 *
 * It is a plain negamax with alpha-beta, deepened one ply at a time, with a
 * table of positions already searched and the previous iteration's best move
 * tried first. Nothing here is clever, and the reason is the use it is put to:
 * the second thing this file is for, after choosing a move, is measuring
 * whether the two sides of this game win about as often as each other.
 */

#include <stdlib.h>
#include <string.h>
#include "bd_abi.h"

static const struct bd_abi *T = NULL;

/* ---- the weights ---------------------------------------------------------------
 *
 * The evaluation is scored FOR THE ATTACKERS and negated for the defenders.
 * Every term is one int in one struct, so a measurement can vary one and leave
 * the rest.
 */

static void bd_weights_default(struct bd_weights *w)
{
    if (!w) return;
    memset(w, 0, sizeof(*w));
    w->attacker     = 100;
    w->defender     = 160;
    w->lane_one     = 450;
    w->lane_two     = 70;
    w->freedom      = 4;
    w->corner_guard = 14;
    w->ring         = 22;
}

static const struct bd_weights *weights_or_default(const struct bd_weights *w)
{
    static struct bd_weights DEFAULT;
    static int ready = 0;
    if (w) return w;
    if (!ready) { bd_weights_default(&DEFAULT); ready = 1; }
    return &DEFAULT;
}

/* ---- the evaluation ------------------------------------------------------------- */

static const int ORTHO[4] = { -1, 1, -BD_STRIDE, BD_STRIDE };

static int is_home(int sq, const struct bd_variant *v)
{
    int f, r;
    if ((T->is_corner)(sq)) return 1;
    if (!v->escape_edge) return 0;
    f = (T->file_of)(sq);
    r = (T->rank_of)(sq);
    return f == 0 || r == 0 || f == BD_SIZE - 1 || r == BD_SIZE - 1;
}

/* Where the king could stop if he moved in direction `d` from `from`, written
 * into `out`. The same walk the move generator makes, for one piece. */
static int king_slide(const struct bd_board *b, const struct bd_variant *v, int from, int d, int *out)
{
    int sq = from + d, n = 0;
    while ((T->at)(b, sq) == BD_EMPTY) {
        if ((T->is_throne)(sq)) {
            if (v->throne_reentry) out[n++] = sq;
            if (!v->throne_pass) break;
        }
        else out[n++] = sq;
        sq += d;
    }
    return n;
}

/* How many squares the king wins on can he reach in ONE move. The whole of the
 * tactics of this game hangs on this number: with the defenders to move and it
 * above zero the game is won, and with the attackers to move it is a threat
 * that must be answered now. */
static int king_lanes(const struct bd_board *b, const struct bd_variant *v)
{
    int king = (T->king_square)(b), d, i, n, one = 0;
    int stops[BD_SIZE];
    if (king < 0) return 0;
    for (d = 0; d < 4; d++) {
        n = king_slide(b, v, king, ORTHO[d], stops);
        for (i = 0; i < n; i++)
            if (is_home(stops[i], v)) one++;
    }
    return one;
}

/* THE SEVEN TERMS.
 *
 *   material      attackers left, and defenders left, each with its own weight
 *   lane_one      squares the king wins on that he can reach in ONE move
 *   lane_two      such squares he can reach in two and not in one
 *   freedom       how many squares the king can move to at all
 *   corner_guard  attackers on the three squares that close a corner
 *   ring          attackers standing next to the king
 *
 * The first two lanes are what the game is about: a king with a line to a
 * corner has won unless it is closed at once, and a king with two has won.
 */
static int bd_evaluate(const struct bd_board *b, const struct bd_variant *v, const struct bd_weights *w)
{
    static const int GUARD[4][3][2] = {
        { { 0, 2 }, { 1, 1 }, { 2, 0 } },
        { { 6, 2 }, { 5, 1 }, { 4, 0 } },
        { { 0, 4 }, { 1, 5 }, { 2, 6 } },
        { { 6, 4 }, { 5, 5 }, { 4, 6 } }
    };
    struct bd_variant dv;
    int score, king, d, e, i, c;
    int one = 0, two = 0, freedom = 0, ring = 0, guards = 0;
    int home_one[BD_CELLS];
    int stops[BD_SIZE], n;

    if (!b) return 0;
    if (!v) { (T->variant_default)(&dv); v = &dv; }
    w = weights_or_default(w);

    score = w->attacker * (T->count)(b, BD_ATTACKER) - w->defender * (T->count)(b, BD_DEFENDER);

    for (c = 0; c < 4; c++)
        for (i = 0; i < 3; i++)
            if ((T->at)(b, (T->square_of)(GUARD[c][i][0], GUARD[c][i][1])) == BD_ATTACKER) guards++;
    score += w->corner_guard * guards;

    king = (T->king_square)(b);
    if (king < 0) return score;

    memset(home_one, 0, sizeof(home_one));
    for (d = 0; d < 4; d++) {
        if ((T->at)(b, king + ORTHO[d]) == BD_ATTACKER) ring++;
        n = king_slide(b, v, king, ORTHO[d], stops);
        freedom += n;
        for (i = 0; i < n; i++)
            if (is_home(stops[i], v) && !home_one[stops[i]]) { home_one[stops[i]] = 1; one++; }
    }
    {
        int home_two[BD_CELLS];
        memset(home_two, 0, sizeof(home_two));
        for (d = 0; d < 4; d++) {
            n = king_slide(b, v, king, ORTHO[d], stops);
            for (i = 0; i < n; i++) {
                int reach[BD_SIZE], m, j;
                if (is_home(stops[i], v)) continue;
                for (e = 0; e < 4; e++) {
                    m = king_slide(b, v, stops[i], ORTHO[e], reach);
                    for (j = 0; j < m; j++) {
                        int sq = reach[j];
                        if (sq == king) continue;
                        if (is_home(sq, v) && !home_one[sq] && !home_two[sq]) { home_two[sq] = 1; two++; }
                    }
                }
            }
        }
    }

    score += w->ring * ring;
    score -= w->lane_one * one;
    score -= w->lane_two * two;
    score -= w->freedom * freedom;
    return score;
}

/* ---- the table of positions already searched ------------------------------------ */

#define TT_EXACT 0
#define TT_LOWER 1
#define TT_UPPER 2

struct tt_entry {
    unsigned long long key;
    int move;
    int score;
    short depth;
    unsigned char flag;
    unsigned char used;
};

#define BD_INF (BD_WIN_SCORE + 1000)

/* how deep one line may run, the extension included */
#define BD_PLY_MAX 96

struct ctx {
    struct bd_game *g;
    struct bd_variant v;
    const struct bd_weights *w;
    unsigned long long nodes, budget, seed;
    int may_stop;
    int stopped;
    struct tt_entry *tt;
    size_t mask;
    int killer[BD_PLY_MAX][2];
};


/* The order moves are tried in: the move the table remembers, the king going
 * home, a move that cut this depth off a moment ago in another line, moves
 * that land beside an enemy, the king's other moves, the rest. It
 * changes how many nodes a search costs and never which move a search to a
 * fixed depth returns, apart from the choice among moves of equal score, which
 * `salt` settles and a test holds to that. */
static unsigned long long mix(unsigned long long z)
{
    z += 0x9E3779B97F4A7C15ULL;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

static void order_moves(const struct ctx *c, const struct bd_board *b, int *list, int n, int first, unsigned long long salt, int ply)
{
    int key[BD_MOVES_MAX];
    int i, j, side = (T->side)(b);

    for (i = 0; i < n; i++) {
        int from = (T->move_from)(list[i]), to = (T->move_to)(list[i]);
        int piece = (T->at)(b, from);
        int k = 0, d;
        if (list[i] == first) k += 100000;
        if (ply >= 0 && ply < BD_PLY_MAX && (list[i] == c->killer[ply][0] || list[i] == c->killer[ply][1])) k += 20000;
        if (piece == BD_KING) k += is_home(to, &c->v) ? 50000 : 300;
        for (d = 0; d < 4; d++) {
            int beside = (T->at)(b, to + ORTHO[d]);
            if (BD_IS_PIECE(beside) && (T->side_of)(beside) != side) { k += 1000; break; }
        }
        if (salt) k += (int) (mix(salt ^ ((unsigned long long) list[i] * 0x100000001B3ULL)) & 0xFF);
        key[i] = k;
    }
    for (i = 1; i < n; i++) {
        int m = list[i], k = key[i];
        for (j = i - 1; j >= 0 && key[j] < k; j--) { list[j + 1] = list[j]; key[j + 1] = key[j]; }
        list[j + 1] = m; key[j + 1] = k;
    }
}

static int score_of_outcome(int outcome, int side, int ply)
{
    int winner = (T->winner_of)(outcome);
    if (winner < 0) return 0;
    return winner == side ? BD_WIN_SCORE - ply : -(BD_WIN_SCORE - ply);
}

/* THE EXTENSION. A search that stops at a fixed depth stops, as often as not,
 * with the king one move from a corner, and scores that as a quiet position.
 * So at the horizon the king's lanes are counted first:
 *
 *   the defenders to move with a lane open    he walks out: a win, and exact
 *   the attackers to move with a lane open    they must answer it NOW, so the
 *                                             line is searched one ply further
 *
 * IT CANNOT RUN AWAY, and needs no counter to stop it. The one extra ply is
 * the attackers', and at the end of it the defenders are to move, where the
 * search never extends: it returns a win if the lane is still open and the
 * evaluation if it is not. Because the extension depends on the position alone
 * and not on how the line got there, a position is worth the same by every
 * road, which is what lets the table of positions be trusted.
 *
 * Without it the attackers of this file lost every game they played in
 * eight moves, to combinations one ply past where they were looking. */
static int negamax(struct ctx *c, int depth, int alpha, int beta, int ply)
{
    const struct bd_board *b = (T->game_board)(c->g);
    int list[BD_MOVES_MAX];
    int n, i, best = -BD_INF, best_move = 0, first = 0, alpha0 = alpha;
    int side = (T->side)(b);
    int outcome;
    unsigned long long key;
    struct tt_entry *e = NULL;

    c->nodes++;
    if (c->may_stop && (c->nodes & 1023ULL) == 0 && c->nodes >= c->budget) c->stopped = 1;
    if (c->stopped) return 0;

    outcome = (T->game_outcome)(c->g);
    if (outcome != BD_ONGOING) return score_of_outcome(outcome, side, ply);

    if (depth <= 0) {
        int lanes = king_lanes(b, &c->v);
        if (lanes && side == BD_DEFENDERS) return BD_WIN_SCORE - ply - 1;
        if (lanes && ply < BD_PLY_MAX - 2) {
            depth = 1;
        }
        else {
            int s = bd_evaluate(b, &c->v, c->w);
            return side == BD_ATTACKERS ? s : -s;
        }
    }

    /* game_push left "can the side to move, move?" unasked, so it is asked
     * here, by the list this node needs anyway */
    n = (T->gen_moves)(b, &c->v, list, BD_MOVES_MAX);
    if (n == 0) return 0;
    if (n > BD_MOVES_MAX) n = BD_MOVES_MAX;

    key = (T->key)(b);
    if (c->tt) {
        e = &c->tt[(size_t) key & c->mask];
        if (e->used && e->key == key) {
            first = e->move;
            if (e->depth >= depth) {
                if (e->flag == TT_EXACT) return e->score;
                if (e->flag == TT_LOWER && e->score > alpha) alpha = e->score;
                if (e->flag == TT_UPPER && e->score < beta)  beta = e->score;
                if (alpha >= beta) return e->score;
            }
        }
    }

    order_moves(c, b, list, n, first, 0, ply);

    for (i = 0; i < n; i++) {
        int s;
        (T->game_push)(c->g, list[i], NULL);
        s = -negamax(c, depth - 1, -beta, -alpha, ply + 1);
        (T->game_undo)(c->g);
        if (c->stopped) return 0;
        if (s > best) { best = s; best_move = list[i]; }
        if (best > alpha) alpha = best;
        if (alpha >= beta) {
            if (ply < BD_PLY_MAX && c->killer[ply][0] != list[i]) {
                c->killer[ply][1] = c->killer[ply][0];
                c->killer[ply][0] = list[i];
            }
            break;
        }
    }

    /* A score that is a win or a loss carries the distance from the ROOT, which
     * is the wrong distance for the same position met by another road, so those
     * are left out of the table. */
    if (e && best > -(BD_WIN_SCORE - 1000) && best < BD_WIN_SCORE - 1000) {
        e->used = 1;
        e->key = key;
        e->move = best_move;
        e->score = best;
        e->depth = (short) depth;
        e->flag = (unsigned char) (best <= alpha0 ? TT_UPPER : best >= beta ? TT_LOWER : TT_EXACT);
    }
    return best;
}

#define BD_DEPTH_MAX 60

/* THE MOVE RETURNED IS THE BEST OF THE LAST ITERATION THAT FINISHED. An
 * iteration cut short by the budget has looked at some of the moves and not
 * others, and its "best so far" is the best of an arbitrary subset.
 *
 * The first iteration is never cut short, so there is always a move to
 * return; it costs one node a legal move and a budget smaller than that is
 * simply exceeded by it.
 *
 * `seed` settles the choice among root moves of equal score, and nothing else.
 */
static int bd_search(const struct bd_game *game, const struct bd_weights *w,
                     unsigned long long budget, unsigned long long seed, int max_depth,
                     struct bd_search_info *info)
{
    struct ctx c;
    int root[BD_MOVES_MAX];
    int n, depth, i, best_move = 0, best_score = 0, done = 0;
    size_t size = 1024;

    if (info) memset(info, 0, sizeof(*info));
    if (!game) return 0;

    memset(&c, 0, sizeof(c));
    c.g = (T->game_copy)(game);
    if (!c.g) return 0;
    (T->game_variant)(c.g, &c.v);
    c.w = weights_or_default(w);
    c.budget = budget;
    c.seed = seed ? seed : 1;

    n = (T->game_moves)(c.g, root, BD_MOVES_MAX);
    if (n <= 0) { (T->game_drop)(c.g); return 0; }
    if (n > BD_MOVES_MAX) n = BD_MOVES_MAX;

    while (size < budget && size < ((size_t) 1 << 20)) size <<= 1;
    c.tt = (struct tt_entry *) calloc(size, sizeof(struct tt_entry));
    c.mask = size - 1;

    if (max_depth <= 0 || max_depth > BD_DEPTH_MAX) max_depth = BD_DEPTH_MAX;

    for (depth = 1; depth <= max_depth; depth++) {
        int alpha = -BD_INF, beta = BD_INF, it_best = -BD_INF, it_move = 0;
        const struct bd_board *b = (T->game_board)(c.g);

        c.may_stop = depth > 1;
        order_moves(&c, b, root, n, best_move, c.seed, -1);

        for (i = 0; i < n; i++) {
            int s;
            (T->game_push)(c.g, root[i], NULL);
            s = -negamax(&c, depth - 1, -beta, -alpha, 1);
            (T->game_undo)(c.g);
            if (c.stopped) break;
            if (s > it_best) { it_best = s; it_move = root[i]; }
            if (it_best > alpha) alpha = it_best;
        }
        if (c.stopped) break;

        best_move = it_move;
        best_score = it_best;
        done = depth;

        /* a win or a loss that is forced has been seen to its end, and looking
         * further would only find the same thing more slowly */
        if (best_score > BD_WIN_SCORE - 1000 || best_score < -(BD_WIN_SCORE - 1000)) break;
        if (c.nodes >= c.budget) break;
    }

    if (info) {
        info->nodes = c.nodes;
        info->depth = done;
        info->score = best_score;
        info->stopped = c.stopped;
    }
    free(c.tt);
    (T->game_drop)(c.g);
    return best_move;
}

/* ---- installed into the table by bd_engine.c -------------------------------------- */

void bd_search_install(struct bd_abi *t);

void bd_search_install(struct bd_abi *t)
{
    T = t;
    t->weights_default = bd_weights_default;
    t->evaluate        = bd_evaluate;
    t->search          = bd_search;
}
