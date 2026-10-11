/* fn_rules.c - a game: a board, the moves that made it, and how it ends.
 *
 * PERL-FREE, as the other two files are.
 *
 * THE RULES THIS FILE IMPLEMENTS, quoted from the sources the distribution
 * names in its documentation:
 *
 *   "The game ends when one player captures all stones of the opponent."
 *   "The game is a draw if no player is able to win. In practice this is
 *    achieved by repetition of the same position with the same player to
 *    move."
 *   "There does not exist any documentation stating what the outcome of the
 *    game would be if a player is not able to move. If this occurs during a
 *    game we define that a player who is not able to move forfeits the game."
 *
 * and three readings where the sources give no number:
 *
 *   - REPETITION DRAWS AT THE THIRD OCCURRENCE, counted between moves only. A
 *     position in the middle of a chain is not a position.
 *   - A QUIET LIMIT. A game is drawn after a set number of moves running,
 *     both sides counted, that took nothing.
 *   - A PLY CAP far above anything a game reaches, as a guard.
 *
 * A MOVE IS COMPLETE WHEN THE TURN PASSES: after a paika, after a stop, and
 * after a step that left nothing to follow. Only then is anything judged, the
 * history written and the counts moved. A step in the middle of a chain
 * changes the board and nothing else.
 *
 * THEY ARE ASKED IN THIS ORDER, because one move can satisfy two: no stones,
 * no move, repetition, the quiet limit, the cap.
 *
 * REPETITION LOOKS BACK ONLY AS FAR AS THE LAST CAPTURE. A capture takes a
 * stone off the board for good, so no position before it can come again; the
 * quiet count is exactly how many positions are worth comparing.
 */

#include <stdlib.h>
#include <string.h>
#include "fn_abi.h"

static const struct fn_abi *E(void) { return fn_abi_table(); }

/* What one game_step or game_stop changed, so that game_undo restores it. */
struct played {
    struct fn_undo undo;
    int quiet;
    int ply;
    int outcome;
};

struct fn_game {
    struct fn_board *board;
    struct fn_variant variant;
    int outcome;
    int ply;                        /* moves completed                          */
    int quiet;                      /* of them, how many running took nothing   */
    int took;                       /* whether the move in progress has taken   */
    unsigned long long *key;        /* key[i] is the position after i moves     */
    int key_room;
    struct played *stack;           /* one a step or stop                       */
    int stack_n;
    int stack_room;
    unsigned char *took_at;         /* took, as it was before each stack entry  */
};

static int FN_GAMES_LIVE = 0;

static void fn_variant_default(struct fn_variant *v)
{
    if (!v) return;
    memset(v, 0, sizeof(*v));
    v->quiet_limit = FN_QUIET_DEFAULT;
    v->repeat = FN_REPEAT_DEFAULT;
    v->ply_cap = FN_PLY_CAP_DEFAULT;
}

/* A limit below zero means the default. Zero turns the quiet limit and
 * repetition OFF, which a table of forced results needs; the cap cannot be
 * turned off, because the history is an array as long as it. */
static void variant_clamp(struct fn_variant *v)
{
    if (v->quiet_limit < 0) v->quiet_limit = FN_QUIET_DEFAULT;
    if (v->repeat < 0) v->repeat = FN_REPEAT_DEFAULT;
    if (v->repeat == 1) v->repeat = 2;
    if (v->ply_cap <= 0 || v->ply_cap > FN_PLY_CAP_MAX) v->ply_cap = FN_PLY_CAP_DEFAULT;
}


static int fn_repeats(const struct fn_game *g)
{
    unsigned long long now = g->key[g->ply];
    int n = 1, i;
    for (i = g->ply - 2; i >= 0 && i >= g->ply - g->quiet; i -= 2)
        if (g->key[i] == now) n++;
    return n;
}

/* Judges the position a completed move has left. */
static int judge(const struct fn_game *g)
{
    const struct fn_abi *e = E();
    const struct fn_board *b = g->board;
    int side = e->side(b);
    if (e->count(b, side) == 0 || e->count(b, FN_OTHER(side)) == 0) return FN_BY_STONES;
    if (e->play_steps(b, NULL, 0) == 0) return FN_BY_NO_MOVES;
    if (g->variant.repeat && fn_repeats(g) >= g->variant.repeat) return FN_DRAW_REPETITION;
    if (g->variant.quiet_limit && g->quiet >= g->variant.quiet_limit) return FN_DRAW_QUIET;
    if (g->ply >= g->variant.ply_cap) return FN_DRAW_PLY_CAP;
    return FN_ONGOING;
}

static struct fn_game *fn_game_new(const struct fn_board *b, const struct fn_variant *v)
{
    const struct fn_abi *e = E();
    struct fn_game *g = (struct fn_game *) calloc(1, sizeof(struct fn_game));
    if (!g) return NULL;
    if (v) g->variant = *v; else fn_variant_default(&g->variant);
    variant_clamp(&g->variant);
    g->board = b ? e->board_copy(b) : e->board_new(FN_COLS_MAX, FN_ROWS_MAX);
    g->key_room = g->variant.ply_cap + 2;
    g->key = (unsigned long long *) calloc((size_t) g->key_room, sizeof(unsigned long long));
    if (!g->board || !g->key) {
        if (g->board) e->board_drop(g->board);
        free(g->key);
        free(g);
        return NULL;
    }
    /* a game begins between moves: a chain the board came with is dropped */
    e->chain_set(g->board, -1, -1, 0);
    g->key[0] = e->key(g->board);
    g->outcome = judge(g);
    FN_GAMES_LIVE++;
    return g;
}

static struct fn_game *fn_game_copy(const struct fn_game *g)
{
    const struct fn_abi *e = E();
    struct fn_game *n;
    if (!g) return NULL;
    n = (struct fn_game *) malloc(sizeof(struct fn_game));
    if (!n) return NULL;
    *n = *g;
    n->board = e->board_copy(g->board);
    n->key = (unsigned long long *) malloc((size_t) g->key_room * sizeof(unsigned long long));
    n->stack = NULL;
    n->took_at = NULL;
    if (g->stack_room) {
        n->stack = (struct played *) malloc((size_t) g->stack_room * sizeof(struct played));
        n->took_at = (unsigned char *) malloc((size_t) g->stack_room);
    }
    if (!n->board || !n->key || (g->stack_room && (!n->stack || !n->took_at))) {
        if (n->board) e->board_drop(n->board);
        free(n->key); free(n->stack); free(n->took_at); free(n);
        return NULL;
    }
    memcpy(n->key, g->key, (size_t) g->key_room * sizeof(unsigned long long));
    if (g->stack_n) {
        memcpy(n->stack, g->stack, (size_t) g->stack_n * sizeof(struct played));
        memcpy(n->took_at, g->took_at, (size_t) g->stack_n);
    }
    FN_GAMES_LIVE++;
    return n;
}

static void fn_game_drop(struct fn_game *g)
{
    if (!g) return;
    (E())->board_drop(g->board);
    free(g->key);
    free(g->stack);
    free(g->took_at);
    free(g);
    FN_GAMES_LIVE--;
}

static int fn_games_live(void) { return FN_GAMES_LIVE; }

static const struct fn_board *fn_game_board(const struct fn_game *g) { return g->board; }
static void fn_game_variant(const struct fn_game *g, struct fn_variant *out) { if (out) *out = g->variant; }
static int fn_game_ply(const struct fn_game *g)     { return g->ply; }
static int fn_game_quiet(const struct fn_game *g)   { return g->quiet; }
static int fn_game_outcome(const struct fn_game *g) { return g->outcome; }
static int fn_game_depth(const struct fn_game *g)   { return g->stack_n; }

/* The side that won, or 0. A game won on stones is won by the side that has
 * some: after a move that is always the mover, but a game may be BEGUN from a
 * position in which one side has none, and then it is whoever has. A game won
 * because the side to move is stuck is won by the other side. */
static int fn_game_winner(const struct fn_game *g)
{
    const struct fn_abi *e = E();
    int side = e->side(g->board);
    if (g->outcome == FN_BY_STONES)
        return e->count(g->board, side) == 0 ? FN_OTHER(side) : side;
    if (g->outcome == FN_BY_NO_MOVES) return FN_OTHER(side);
    return 0;
}

static unsigned long long fn_game_key_at(const struct fn_game *g, int ply)
{
    if (ply < 0 || ply > g->ply) return 0;
    return g->key[ply];
}

static int fn_game_steps(const struct fn_game *g, struct fn_step *out, int max)
{
    if (g->outcome != FN_ONGOING) return 0;
    return (E())->play_steps(g->board, out, max);
}

static int fn_game_can_stop(const struct fn_game *g)
{
    if (g->outcome != FN_ONGOING) return 0;
    return (E())->can_stop(g->board);
}

/* Room for one more entry on the stack, or 0. */
static int stack_grow(struct fn_game *g)
{
    struct played *s;
    unsigned char *t;
    int room;
    if (g->stack_n < g->stack_room) return 1;
    room = g->stack_room ? g->stack_room * 2 : 64;
    s = (struct played *) realloc(g->stack, (size_t) room * sizeof(struct played));
    if (!s) return 0;
    g->stack = s;
    t = (unsigned char *) realloc(g->took_at, (size_t) room);
    if (!t) return 0;
    g->took_at = t;
    g->stack_room = room;
    return 1;
}

/* The turn has just passed: count the move, write the position, judge it. */
static void move_done(struct fn_game *g)
{
    g->ply++;
    g->quiet = g->took ? 0 : g->quiet + 1;
    g->took = 0;
    g->key[g->ply] = (E())->key(g->board);
    g->outcome = judge(g);
}

static void remember(struct fn_game *g, struct played *p)
{
    p->quiet = g->quiet;
    p->ply = g->ply;
    p->outcome = g->outcome;
    g->took_at[g->stack_n] = (unsigned char) g->took;
}

/* THE ONE DOOR A STEP COMES THROUGH. Refuses and changes nothing, or plays. */
static int fn_game_step(struct fn_game *g, int from, int dir, int kind, int *why)
{
    const struct fn_abi *e = E();
    struct fn_step s;
    struct played *p;
    int reason, removed;
    if (why) *why = FN_WHY_OK;
    if (g->outcome != FN_ONGOING) return FN_PLAY_OVER;
    reason = e->play_why(g->board, from, dir, kind, &s);
    if (reason != FN_WHY_OK) {
        if (why) *why = reason;
        return FN_PLAY_ILLEGAL;
    }
    if (!stack_grow(g)) return FN_PLAY_ILLEGAL;
    p = &g->stack[g->stack_n];
    remember(g, p);
    removed = e->play_step(g->board, &s, &p->undo);
    g->stack_n++;
    if (removed > 0) g->took = 1;
    if (e->chain_at(g->board) < 0) move_done(g);
    return FN_PLAY_OK;
}

static int fn_game_stop(struct fn_game *g)
{
    const struct fn_abi *e = E();
    struct played *p;
    if (g->outcome != FN_ONGOING) return FN_PLAY_OVER;
    if (!e->can_stop(g->board)) return FN_PLAY_ILLEGAL;
    if (!stack_grow(g)) return FN_PLAY_ILLEGAL;
    p = &g->stack[g->stack_n];
    remember(g, p);
    e->play_stop(g->board, &p->undo);
    g->stack_n++;
    move_done(g);
    return FN_PLAY_OK;
}

/* Takes back the last step or stop. 0 when there is none. */
static int fn_game_undo(struct fn_game *g)
{
    struct played *p;
    if (g->stack_n == 0) return 0;
    g->stack_n--;
    p = &g->stack[g->stack_n];
    (E())->play_undo(g->board, &p->undo);
    g->quiet = p->quiet;
    g->ply = p->ply;
    g->outcome = p->outcome;
    g->took = g->took_at[g->stack_n];
    return 1;
}

/* ---- installed into the table by fn_engine.c ---------------------------------- */

void fn_rules_install(struct fn_abi *t);

void fn_rules_install(struct fn_abi *t)
{
    t->variant_default = fn_variant_default;
    t->game_new        = fn_game_new;
    t->game_copy       = fn_game_copy;
    t->game_drop       = fn_game_drop;
    t->games_live      = fn_games_live;
    t->game_board      = fn_game_board;
    t->game_variant    = fn_game_variant;
    t->game_ply        = fn_game_ply;
    t->game_quiet      = fn_game_quiet;
    t->game_depth      = fn_game_depth;
    t->game_outcome    = fn_game_outcome;
    t->game_winner     = fn_game_winner;
    t->game_key_at     = fn_game_key_at;
    t->repeats         = fn_repeats;
    t->game_steps      = fn_game_steps;
    t->game_can_stop   = fn_game_can_stop;
    t->game_step       = fn_game_step;
    t->game_stop       = fn_game_stop;
    t->game_undo       = fn_game_undo;
}
