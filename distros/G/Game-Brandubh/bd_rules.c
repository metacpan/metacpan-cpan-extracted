/* bd_rules.c - a game: a board, the moves that made it, and how it ends.
 *
 * PERL-FREE, as the other bd_*.c files are.
 *
 * THE RULES THIS FILE IMPLEMENTS, quoted from the source the distribution
 * names in its documentation:
 *
 *  11. "The king wins the game on reaching any of the marked corner squares.
 *      The attackers win if they capture the king."
 *  12. "The game is drawn if a position is repeated, if a player cannot move,
 *      or if the players otherwise agree it."
 *
 * and three decisions where that text is silent or would give a result nobody
 * means:
 *
 *   - "REPEATED" IS THE THIRD TIME, with the same side to move, as draughts
 *     and chess count it. bd_variant.repeat says which occurrence; the literal
 *     reading of the sentence is 2.
 *   - ATTACKERS WITH NO PIECE LEFT HAVE LOST. Read literally rule 12 draws
 *     that game, because a side with nothing "cannot move". The sentence is
 *     for a side that is blocked.
 *   - A GAME THAT WILL NOT END IS DRAWN AT A PLY CAP. The attackers can seal
 *     all four corners, and then nothing above ends the game.
 *
 * Agreement and resignation are not here. They are something two people do,
 * and the caller records them.
 *
 * THE ORDER THE ENDINGS ARE ASKED IN IS PART OF THE RULE, because one move can
 * satisfy two of them:
 *
 *   1. the win the move itself made: the king home, or the king taken
 *   2. the attackers have no piece
 *   3. the side to move has no legal move
 *   4. the position has occurred for the Nth time
 *   5. the ply cap
 *
 * So a king who reaches a corner on the move that also repeats a position has
 * won, and taking the last attacker is a win and not a blocked side.
 */

#include <stdlib.h>
#include <string.h>
#include "bd_abi.h"

static const struct bd_abi *E(void) { return bd_abi_table(); }

/* ---- the game ------------------------------------------------------------------
 *
 * Everything about a ply is kept by its index: the key of the position after
 * it, the outcome as it stood then, whether the move that made it captured,
 * and the undo that takes it back. Index 0 is the starting position and has no
 * move behind it.
 *
 * THE ARRAYS HOLD ply_cap + 1 ENTRIES AND CANNOT OVERFLOW: at the cap the
 * outcome is a draw and game_do refuses, so the index never passes it.
 */

struct bd_game {
    struct bd_board *board;
    struct bd_variant variant;
    int cap;                         /* the ply cap, as clamped              */
    int ply;                         /* moves made so far                    */
    unsigned long long *key;         /* [0 .. cap]                           */
    int *outcome;                    /* [0 .. cap]                           */
    unsigned char *captured;         /* [0 .. cap], 1 if that move captured  */
    struct bd_undo *undo;            /* [1 .. cap], undo[i] takes ply i back */
};

static int GAMES_LIVE = 0;

/* A rule set as a game will use it. A cap of nothing or less means the
 * default, and so does a cap above what the arrays are allowed to be; a
 * repeat below 2 would draw every game at its first position, and means 2. */
static void variant_clamped(struct bd_variant *out, const struct bd_variant *v)
{
    if (v) *out = *v;
    else   (E())->variant_default(out);
    if (out->ply_cap <= 0 || out->ply_cap > BD_PLY_CAP_MAX) out->ply_cap = BD_PLY_CAP_DEFAULT;
    if (out->repeat < 2) out->repeat = 2;
}

/* ---- repetition -----------------------------------------------------------------
 *
 * How many times the current position has occurred, this time included.
 *
 * THE WALK STOPS AT THE LAST CAPTURE. Pieces only ever leave the board, so a
 * position from before a capture has more pieces on it than any after and
 * cannot be the one on the board now. Stopping there changes no answer; it
 * only means a long game does not search its whole length on every move.
 *
 * A KEY MATCH IS TRUSTED. Two different positions sharing a 64-bit key would
 * be a draw called in error, and nothing here guards against it.
 */
static int bd_repeats(const struct bd_game *g)
{
    unsigned long long now;
    int i, n = 0;
    if (!g) return 0;
    now = g->key[g->ply];
    for (i = g->ply; i >= 0; i--) {
        if (g->key[i] == now) n++;
        if (g->captured[i]) break;
    }
    return n;
}

/* ---- the outcome ------------------------------------------------------------------ */

static int king_home_somewhere(const struct bd_game *g)
{
    int f, r;
    for (r = 0; r < BD_SIZE; r++) {
        for (f = 0; f < BD_SIZE; f++) {
            int sq = (E())->square_of(f, r);
            int edge = f == 0 || r == 0 || f == BD_SIZE - 1 || r == BD_SIZE - 1;
            if ((E())->at(g->board, sq) != BD_KING) continue;
            if ((E())->is_corner(sq) || (g->variant.escape_edge && edge)) return 1;
        }
    }
    return 0;
}

/* endings 2 to 5: the ones that are read off the position and its history and
 * not off the move that was just made */
static int judge_rest(const struct bd_game *g)
{
    if ((E())->count(g->board, BD_ATTACKER) == 0) return BD_BY_NO_PIECES;
    if ((E())->gen_moves(g->board, &g->variant, NULL, 0) == 0) return BD_DRAW_NO_MOVE;
    if (bd_repeats(g) >= g->variant.repeat) return BD_DRAW_REPETITION;
    if (g->ply >= g->cap) return BD_DRAW_PLY_CAP;
    return BD_ONGOING;
}

/* A position nobody moved into, so there is no move to read a win from. No
 * king on the board: he has been captured. A king standing where he wins: he
 * has won. Otherwise it is judged like any other. */
static int judge_start(const struct bd_game *g)
{
    if ((E())->count(g->board, BD_KING) == 0) return BD_BY_CAPTURE;
    if (king_home_somewhere(g)) return BD_BY_CORNER;
    return judge_rest(g);
}

static int judge_move(const struct bd_game *g, int flags)
{
    if (flags & BD_KING_HOME)  return BD_BY_CORNER;
    if (flags & BD_KING_TAKEN) return BD_BY_CAPTURE;
    return judge_rest(g);
}

/* ---- lifecycle -------------------------------------------------------------------- */

static void bd_game_drop(struct bd_game *g)
{
    if (!g) return;
    if (g->board) (E())->board_drop(g->board);
    free(g->key);
    free(g->outcome);
    free(g->captured);
    free(g->undo);
    free(g);
    GAMES_LIVE--;
}

static struct bd_game *game_alloc(const struct bd_variant *v)
{
    struct bd_game *g = (struct bd_game *) calloc(1, sizeof(struct bd_game));
    size_t slots;
    if (!g) return NULL;
    GAMES_LIVE++;
    variant_clamped(&g->variant, v);
    g->cap = g->variant.ply_cap;
    slots = (size_t) g->cap + 1;
    g->key      = (unsigned long long *) calloc(slots, sizeof(unsigned long long));
    g->outcome  = (int *) calloc(slots, sizeof(int));
    g->captured = (unsigned char *) calloc(slots, 1);
    g->undo     = (struct bd_undo *) calloc(slots, sizeof(struct bd_undo));
    if (!g->key || !g->outcome || !g->captured || !g->undo) {
        bd_game_drop(g);
        return NULL;
    }
    return g;
}

/* A game from a copy of `b`, or from the set-up when `b` is NULL. The board
 * handed in is left alone and may be dropped at once. */
static struct bd_game *bd_game_new(const struct bd_board *b, const struct bd_variant *v)
{
    struct bd_game *g = game_alloc(v);
    if (!g) return NULL;
    g->board = b ? (E())->board_copy(b) : (E())->board_new();
    if (!g->board) { bd_game_drop(g); return NULL; }
    g->ply = 0;
    g->key[0] = (E())->key(g->board);
    g->captured[0] = 0;
    g->outcome[0] = judge_start(g);
    return g;
}

static struct bd_game *bd_game_copy(const struct bd_game *src)
{
    struct bd_game *g;
    size_t slots;
    if (!src) return NULL;
    g = game_alloc(&src->variant);
    if (!g) return NULL;
    g->board = (E())->board_copy(src->board);
    if (!g->board) { bd_game_drop(g); return NULL; }
    slots = (size_t) src->cap + 1;
    g->ply = src->ply;
    memcpy(g->key, src->key, slots * sizeof(unsigned long long));
    memcpy(g->outcome, src->outcome, slots * sizeof(int));
    memcpy(g->captured, src->captured, slots);
    memcpy(g->undo, src->undo, slots * sizeof(struct bd_undo));
    return g;
}

static int bd_games_live(void) { return GAMES_LIVE; }

/* ---- reading a game --------------------------------------------------------------- */

static const struct bd_board *bd_game_board(const struct bd_game *g) { return g ? g->board : NULL; }
static int bd_game_ply(const struct bd_game *g)     { return g ? g->ply : 0; }
static int bd_game_cap(const struct bd_game *g)     { return g ? g->cap : 0; }
static int bd_game_outcome(const struct bd_game *g) { return g ? g->outcome[g->ply] : BD_ONGOING; }

static void bd_game_variant(const struct bd_game *g, struct bd_variant *out)
{
    if (g && out) *out = g->variant;
}

static int bd_winner_of(int outcome)
{
    if (outcome == BD_BY_CAPTURE) return BD_ATTACKERS;
    if (outcome == BD_BY_CORNER || outcome == BD_BY_NO_PIECES) return BD_DEFENDERS;
    return -1;
}

static int bd_game_winner(const struct bd_game *g) { return bd_winner_of(bd_game_outcome(g)); }

/* The key of the position after `ply` moves, or 0 for a ply the game has not
 * reached. */
static unsigned long long bd_game_key_at(const struct bd_game *g, int ply)
{
    if (!g || ply < 0 || ply > g->ply) return 0;
    return g->key[ply];
}

/* The moves of the side to move, and NONE once the game is over: a finished
 * game has no legal move, whatever the pieces could do. */
static int bd_game_moves(const struct bd_game *g, int *out, int max)
{
    if (!g || g->outcome[g->ply] != BD_ONGOING) return 0;
    return (E())->gen_moves(g->board, &g->variant, out, max);
}

/* ---- playing ----------------------------------------------------------------------
 *
 * game_do IS A RULES CALL, the first in this distribution that refuses. A
 * move in a finished game is BD_PLAY_OVER; a move the side to move may not
 * make is BD_PLAY_ILLEGAL; and in both cases the game is exactly as it was.
 */
static int bd_game_do(struct bd_game *g, int mv, int *flags_out)
{
    int flags, at;
    if (flags_out) *flags_out = 0;
    if (!g) return BD_PLAY_ILLEGAL;
    if (g->outcome[g->ply] != BD_ONGOING) return BD_PLAY_OVER;
    if (!(E())->is_legal(g->board, &g->variant, mv)) return BD_PLAY_ILLEGAL;

    at = g->ply + 1;
    flags = (E())->do_move(g->board, &g->variant, mv, &g->undo[at]);
    g->ply = at;
    g->key[at] = (E())->key(g->board);
    g->captured[at] = (flags & BD_DID_CAPTURE) ? 1 : 0;
    g->outcome[at] = judge_move(g, flags);

    if (flags_out) *flags_out = flags;
    return BD_PLAY_OK;
}

/* game_do with two questions left out, for a search: see the header. The
 * outcome is judged in the same order with "no move" skipped, and a position
 * that is both blocked and something else is a draw either way. */
static void bd_game_push(struct bd_game *g, int mv, int *flags_out)
{
    int flags, at, outcome;
    if (flags_out) *flags_out = 0;
    if (!g || g->ply >= g->cap) return;

    at = g->ply + 1;
    flags = (E())->do_move(g->board, &g->variant, mv, &g->undo[at]);
    g->ply = at;
    g->key[at] = (E())->key(g->board);
    g->captured[at] = (flags & BD_DID_CAPTURE) ? 1 : 0;

    if      (flags & BD_KING_HOME)  outcome = BD_BY_CORNER;
    else if (flags & BD_KING_TAKEN) outcome = BD_BY_CAPTURE;
    else if ((E())->count(g->board, BD_ATTACKER) == 0)  outcome = BD_BY_NO_PIECES;
    else if (bd_repeats(g) >= g->variant.repeat)        outcome = BD_DRAW_REPETITION;
    else if (g->ply >= g->cap)                          outcome = BD_DRAW_PLY_CAP;
    else                                                outcome = BD_ONGOING;
    g->outcome[at] = outcome;

    if (flags_out) *flags_out = flags;
}

/* Takes the last move back. Everything kept for that ply is simply left
 * behind: the index steps down and the entries above it are dead until a new
 * move writes over them. Returns 0 when there is no move to take back. */
static int bd_game_undo(struct bd_game *g)
{
    if (!g || g->ply == 0) return 0;
    (E())->undo_move(g->board, &g->undo[g->ply]);
    g->ply--;
    return 1;
}

/* ---- installed into the table by bd_engine.c ------------------------------------- */

void bd_rules_install(struct bd_abi *t);

void bd_rules_install(struct bd_abi *t)
{
    t->game_new     = bd_game_new;
    t->game_copy    = bd_game_copy;
    t->game_drop    = bd_game_drop;
    t->games_live   = bd_games_live;

    t->game_board   = bd_game_board;
    t->game_variant = bd_game_variant;
    t->game_ply     = bd_game_ply;
    t->game_cap     = bd_game_cap;
    t->game_outcome = bd_game_outcome;
    t->game_winner  = bd_game_winner;
    t->winner_of    = bd_winner_of;
    t->game_key_at  = bd_game_key_at;
    t->game_moves   = bd_game_moves;
    t->repeats      = bd_repeats;

    t->game_do      = bd_game_do;
    t->game_undo    = bd_game_undo;
    t->game_push    = bd_game_push;
}
