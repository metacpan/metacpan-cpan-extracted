/* go_search.c - the playouts, and the confidence bound over the root moves.
 *
 * PERL-FREE, like go_engine.c, and under the same rules: no perl.h, no stdio.h,
 * no rand, no time. t/24-no-io.t scans this file too.
 *
 * ALPHA-BETA DOES NOT WORK ON GO. There is no static evaluation to search with
 * (whether a stone is strong depends on whether its group will live, which is
 * the thing an evaluation was wanted for) and the branching factor is 361 at
 * the root. So the leaf value here is the result of playing the position out at
 * random and counting it, which needs no evaluation function at all.
 *
 * EVERYTHING IS INTEGER, the confidence bound included. A float in the selection
 * formula is an implementation-defined rounding in the middle of a move choice,
 * and this bot has to return the same move on every machine or the replay of a
 * bot game stops reproducing.
 */

#include <stdlib.h>
#include <string.h>

#include "go_abi.h"

/* go_engine.c's table, fetched once. Using the published ABI rather than
 * reaching for its statics keeps this file a consumer like any other, and keeps
 * the engine's internals the engine's business. */
static const struct go_abi *EN = NULL;
static void need_engine(void) { if (!EN) EN = go_abi_table(); }

/* ---------------------------------------------------------------- xorshift32 --
 *
 * The whole generator, and the reason it is this one rather than something
 * wider, is in go_abi.h: a 64-bit product on a perl with 32-bit integers goes
 * silently through an NV and loses its low bits, so a generator anybody might
 * mirror from Perl has to live in add, xor and shift.
 */
static unsigned int go_prng_next(unsigned int *state)
{
    unsigned int x;
    if (!state) return 0;

    /* ZERO IS A FIXED POINT of xorshift, so a zero state would make every
     * playout identical while every test still passed. Corrected rather than
     * accepted, and the constant is arbitrary but pinned. */
    if (*state == 0) *state = 2463534242u;

    x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x;
    return x;
}

/* ------------------------------------------------------------------ the eye --
 *
 * A TRUE EYE, and the definition is what makes a playout terminate at all. A
 * uniformly random legal move fills its own eyes, which kills its own groups,
 * which means the position never settles and the playout runs to its cap.
 *
 *   a point is a true eye for colour C when
 *     every orthogonal neighbour is C or off the board, AND
 *     of the diagonals that are on the board,
 *       at most one is not C   -- in the middle
 *       none is not C          -- on an edge or in a corner
 *
 * THE EDGE CLAUSE IS THE HALF EVERYBODY LEAVES OUT, and leaving it out makes a
 * playout fill real eyes on the first line. t/20-bot-eyes.t has a position for
 * each clause.
 */
static int is_true_eye(const struct go_board *b, int pt, int colour)
{
    int i, on_edge = 0, wrong = 0;
    int diag[4];

    for (i = 0; i < 4; i++) {
        int c = b->colour[pt + b->nbr[i]];
        if (c == GO_BORDER) { on_edge = 1; continue; }
        if (c != colour) return 0;
    }

    diag[0] = pt - 1 - b->stride;
    diag[1] = pt + 1 - b->stride;
    diag[2] = pt - 1 + b->stride;
    diag[3] = pt + 1 + b->stride;

    for (i = 0; i < 4; i++) {
        int c = b->colour[diag[i]];
        if (c == GO_BORDER) continue;
        if (c != colour) wrong++;
    }

    return on_edge ? (wrong == 0) : (wrong <= 1);
}

/* ---------------------------------------------------------------- a playout --
 *
 * Random legal moves, alternating, until both players pass or the cap trips.
 * Returns the AREA score difference in points, from black's side.
 *
 * The board is played on DESTRUCTIVELY, so the caller hands over a copy. The
 * history is null, which the engine reads as simple ko and nothing else: see
 * go_abi.h for why a playout does not carry a superko history.
 */
static int playout_on(struct go_board *b, int colour, unsigned int *state,
                      int *moves_out, int *capped_out)
{
    int choices[GO_MAX_PTS];
    struct go_played res;
    struct go_score s;
    int passes = 0, moves = 0, cap, size;

    need_engine();
    size = (EN->size_of)(b);
    cap = 3 * size * size;

    while (passes < 2 && moves < cap) {
        int n = 0, r, c;

        for (r = 0; r < size; r++) {
            for (c = 0; c < size; c++) {
                int pt = (EN->point_of)(b, c, r);
                if ((EN->at)(b, pt) != GO_EMPTY) continue;
                if ((EN->legal)(b, NULL, pt, colour) != GO_OK) continue;
                if (is_true_eye(b, pt, colour)) continue;   /* never its own eye */
                choices[n++] = pt;
            }
        }

        if (n == 0) {
            (EN->pass)(b, colour);
            passes++;
        } else {
            (EN->play)(b, NULL, choices[go_prng_next(state) % (unsigned int)n],
                       colour, &res);
            passes = 0;
            moves++;
        }
        colour = GO_OTHER(colour);
    }

    if (moves >= cap && capped_out) (*capped_out)++;
    if (moves_out) *moves_out += moves;

    /* AREA SCORING, because a playout has nobody to agree dead stones with.
     * Komi is not applied here: the search compares playouts against each
     * other, and a constant added to every one of them changes nothing. */
    (EN->score_area)(b, &s);
    return s.area_b - s.area_w;
}

static int go_playout(const struct go_board *b, int colour,
                      unsigned int *state, int *moves_out)
{
    struct go_board *work;
    int diff;

    need_engine();
    if (!b) return 0;
    work = (EN->board_copy)(b);
    if (!work) return 0;

    diff = playout_on(work, colour, state, moves_out, NULL);
    (EN->board_drop)(work);
    return diff;
}

/* ----------------------------------------------------- the confidence bound --
 *
 * UCB1, in integers. Integer square root by Newton, and a floor-log-2 standing
 * in for the natural log: the difference between them is a constant factor, and
 * the constant is a tunable rather than a fact.
 */
static unsigned int isqrt32(unsigned int n)
{
    unsigned int x, y;
    if (n == 0) return 0;
    x = n;
    for (;;) {
        y = (x + n / x) / 2;
        if (y >= x) break;
        x = y;
    }
    return x;
}

static int ilog2i(unsigned int n)
{
    int r = 0;
    while (n >>= 1) r++;
    return r;
}

/* In permille. An unvisited move sorts above every visited one, so the first
 * pass over the root tries each move once, IN POINT ORDER. */
#define GO_UNVISITED (1 << 28)

/* The fewest samples at which a root move's win count means anything. A single
 * playout of a Go position is close to a coin flip, so below this the selection
 * is reading noise. Used to cut the root set down to what the budget can
 * actually compare: see the note in go_search. */
#define GO_MIN_VISITS 8

static int ucb_permille(int wins, int visits, int total, int explore)
{
    int exploit, term, lg;

    if (visits <= 0) return GO_UNVISITED;

    exploit = (wins * 1000) / visits;

    lg = ilog2i((unsigned int)(total < 2 ? 2 : total));
    term = (int)isqrt32((unsigned int)((lg * 1000000) / visits));

    return exploit + (explore * term) / 1000;
}

/* ------------------------------------------------------------- the search ----
 *
 * FLAT, meaning the tree is one level: an array of visits and wins indexed by
 * point, over the root moves the caller handed in. That is what the plan asked
 * for and it is what a beginner-strength bot needs; a deep tree is strength for
 * a lot more memory and a much harder determinism argument.
 *
 * `allowed` is the root moves the CALLER filtered, which is how this file never
 * has to see the superko history. A point of -1 is a pass.
 */
static void go_search(const struct go_board *b, int colour,
                      const int *allowed, int nallowed,
                      unsigned int seed, int playouts, int explore,
                      struct go_search *out)
{
    int visits[GO_MAX_PTS + 1];
    int wins[GO_MAX_PTS + 1];
    int roots[GO_MAX_PTS + 1];      /* the root moves actually searched */
    unsigned int state = seed;
    int i, done = 0, best = 0, nroots = 0;
    int pass_slot = GO_MAX_PTS;     /* the pass lives past the last real point */

    need_engine();
    if (!out) return;
    out->point = -1;
    out->playouts = 0;
    out->visits = 0;
    out->win_permille = 0;
    out->capped = 0;
    out->moves = 0;
    if (!b || !allowed || nallowed <= 0) return;

    for (i = 0; i <= GO_MAX_PTS; i++) { visits[i] = 0; wins[i] = 0; }

    /* ---- THE BUDGET DECIDES HOW MANY MOVES CAN BE COMPARED AT ALL ----------
     *
     * This is arithmetic about the search and not knowledge about Go, which is
     * why it is here rather than in a heuristic.
     *
     * With P playouts spread over M root moves, each move gets P/M samples. A
     * single playout of a Go position is close to a coin flip, so at one or two
     * samples a move's win count carries no information and the selection
     * resolves to whatever the tie-break is. MEASURED: on a 19x19 board with
     * 361 root moves and 300 playouts the search chose the top left corner
     * every time, because every move ended on one visit.
     *
     * So when the budget cannot afford GO_MIN_VISITS samples per move, the root
     * set is CUT DOWN to the number it can afford, chosen by the seed. A
     * shallow search over a random forty moves is a real search result; a
     * one-sample look at every move is a sorting artifact.
     *
     * The shuffle is Fisher-Yates over a copy, driven by the same PRNG as the
     * playouts, so the subset is a function of the seed and nothing else.
     */
    for (i = 0; i < nallowed && i <= GO_MAX_PTS; i++) roots[i] = allowed[i];
    nroots = nallowed;

    if (playouts / GO_MIN_VISITS < nroots) {
        int keep = playouts / GO_MIN_VISITS;
        if (keep < 1) keep = 1;

        for (i = nroots - 1; i > 0; i--) {
            unsigned int j = go_prng_next(&state) % (unsigned int)(i + 1);
            int tmp = roots[i];
            roots[i] = roots[j];
            roots[j] = tmp;
        }
        nroots = keep;
    }

    while (done < playouts) {
        int pick = -1, pick_slot = -1, pick_score = -1;
        struct go_board *work;
        struct go_played res;
        int diff;

        /* selection, with ties to the LOWER POINT INDEX so the choice is total
         * and does not depend on the order anything was stored in */
        for (i = 0; i < nroots; i++) {
            int pt = roots[i];
            int slot = pt < 0 ? pass_slot : pt;
            int score = ucb_permille(wins[slot], visits[slot], done, explore);
            if (score > pick_score) {
                pick_score = score;
                pick = pt;
                pick_slot = slot;
            }
        }
        if (pick_slot < 0) break;

        work = (EN->board_copy)(b);
        if (!work) break;

        if (pick < 0) (EN->pass)(work, colour);
        else          (EN->play)(work, NULL, pick, colour, &res);

        diff = playout_on(work, GO_OTHER(colour), &state, &out->moves, &out->capped);
        (EN->board_drop)(work);

        /* A win from the SEARCHING colour's side. A draw counts for nobody,
         * which on an integer area difference means only an exact zero. */
        visits[pick_slot]++;
        if (colour == GO_BLACK) { if (diff > 0) wins[pick_slot]++; }
        else                    { if (diff < 0) wins[pick_slot]++; }

        done++;
    }

    out->playouts = done;

    /* THE MOVE IS THE MOST WINS, then the most visits, then the lower point.
     *
     * "Most visited" is the standard choice and it is the RIGHT one for a
     * search whose budget exceeded its root move count, because the bound
     * concentrates visits on the move it likes and the visit count is what it
     * spent the budget deciding.
     *
     * IT IS WRONG WHEN THE BUDGET DID NOT. The first pass over the root visits
     * every move once, in point order, so on a 19x19 board with 361 root moves
     * and a few hundred playouts every move ends on one visit and "most
     * visited" resolves to the LOWEST POINT INDEX: the bot played the top left
     * corner every single time. That was measured, not reasoned about.
     *
     * Ordering by wins first fixes it without a heuristic and without changing
     * the well-funded case: where visits are concentrated the most-visited move
     * is also the most-won, and where they are not, wins is the only thing in
     * the table that means anything.
     */
    best = -1;
    for (i = 0; i < nroots; i++) {
        int pt = roots[i];
        int slot = pt < 0 ? pass_slot : pt;
        if (best < 0) { best = slot; continue; }
        if (wins[slot] > wins[best]) { best = slot; continue; }
        if (wins[slot] == wins[best] && visits[slot] > visits[best]) best = slot;
    }
    if (best < 0) return;

    out->point = (best == pass_slot) ? -1 : best;
    out->visits = visits[best];
    out->win_permille = visits[best] ? (wins[best] * 1000) / visits[best] : 0;
}

/* -------------------------------------------------------------- dead stones --
 *
 * PLAYOUTS AND NOT HEURISTICS. From the stopped position, play it out N times
 * and see whose the points end up being; a chain whose own points mostly end up
 * the opponent's is dead. That is what `final_status_list dead` means in every
 * playout engine, and it costs nothing new because the playout is already here.
 */
static int go_dead_guess(const struct go_board *b, unsigned int seed,
                         int playouts, int *out)
{
    int lost[GO_MAX_PTS];
    int seen[GO_MAX_PTS];
    signed char owner[GO_MAX_PTS];
    int chain[GO_MAX_PTS];
    unsigned int state = seed;
    int i, n = 0, r, c, size, pts;

    need_engine();
    if (!b) return 0;
    size = (EN->size_of)(b);
    pts = (EN->stride_of)(b) * (EN->stride_of)(b);

    for (i = 0; i < pts; i++) { lost[i] = 0; seen[i] = 0; }

    for (i = 0; i < playouts; i++) {
        struct go_board *work = (EN->board_copy)(b);
        int j;
        if (!work) break;

        /* Black to play is arbitrary and it does not matter: the question is
         * whose the points end up being, and both sides get to answer. */
        (void)playout_on(work, GO_BLACK, &state, NULL, NULL);
        (EN->territory)(work, NULL, 0, NULL, 0, owner);

        for (j = 0; j < pts; j++) {
            int was = (EN->at)(b, j);
            if (was != GO_BLACK && was != GO_WHITE) continue;
            seen[j]++;
            /* the point ended up the opponent's, either as territory or under
             * an opposing stone */
            if (owner[j] == GO_OTHER(was) || (EN->at)(work, j) == GO_OTHER(was))
                lost[j]++;
        }
        (EN->board_drop)(work);
    }

    /* A chain is dead when MOST of its stones mostly ended up the opponent's.
     * Per chain rather than per stone, because life and death is a property of
     * a chain and half a dead group is not a thing. */
    for (i = 0; i < pts; i++) seen[i] = seen[i] ? seen[i] : 0;

    for (r = 0; r < size; r++) {
        for (c = 0; c < size; c++) {
            int pt = (EN->point_of)(b, c, r);
            int len, j, dead_stones = 0, root_seen = 0;

            if ((EN->at)(b, pt) != GO_BLACK && (EN->at)(b, pt) != GO_WHITE) continue;

            len = (EN->chain_at)(b, pt, chain);
            if (len <= 0) continue;

            /* only from the chain's lowest point, so each chain is judged once */
            {
                int low = chain[0];
                for (j = 1; j < len; j++) if (chain[j] < low) low = chain[j];
                if (low != pt) continue;
            }

            for (j = 0; j < len; j++) {
                if (!seen[chain[j]]) continue;
                root_seen++;
                if (lost[chain[j]] * 2 > seen[chain[j]]) dead_stones++;
            }

            if (root_seen && dead_stones * 2 > root_seen) {
                for (j = 0; j < len; j++) {
                    if (out) out[n] = chain[j];
                    n++;
                }
            }
        }
    }

    return n;
}

/* ------------------------------------------------------------- the exports ---
 *
 * Appended to go_engine.c's table by go_search_install, which is called from
 * go_abi_table. Filled in BY NAME, for the reason the rest of the table is.
 */
void go_search_install(struct go_abi *t)
{
    t->prng_next  = go_prng_next;
    t->playout    = go_playout;
    t->search     = go_search;
    t->dead_guess = go_dead_guess;
}
