/* shg_search.c - the evaluation and the search. Phase 08 of plan_game_shogi.
 *
 * PERL-FREE, as the rest of the engine is.
 *
 * ---- WHAT THIS FILE TAKES FROM GAME-XIANGQI, AND WHY ---------------------------------
 *
 * FAIL-SOFT, AND A ROOT TIE IS NEVER PICKED. Game::Oware's bot got weaker with
 * depth because fail-hard children all came back equal to alpha and the root
 * drew among them; Game::Xiangqi's did the same in a different hat, pooling
 * root moves whose scores EQUALLED the best when a fail-soft child that fails
 * high returns a bound, not a value. Here, as there: the root list is shuffled
 * by the seed once, only a STRICT improvement replaces the move, and the
 * ordering is stable, so the first move to reach the best score is a uniform
 * draw among the moves that truly tie.
 *
 * BOUNDED IN NODES, NEVER IN TIME. The site plays the bot inside a database
 * transaction; a budget in seconds would make a bot game unreplayable. Checked
 * every 1024 nodes and never switched off: Xiangqi's quiescence hung the
 * opening position the one time its check was gated.
 *
 * ITERATIVE DEEPENING, so a spent budget leaves a whole shallower search.
 *
 * LEGALITY IS LAZY: moves are generated pseudo-legally and tested after
 * do_move, only the ones searched. Xiangqi measured 90,000 nodes a second
 * filtering every move first and 2.26 million generating them.
 *
 * ---- WHAT SHOGI ADDS ---------------------------------------------------------------
 *
 * DROPS ARE MOST OF THE MOVES (79 percent, measured-branching-2026-10-14.txt)
 * and most are bad, so the ordering decides the depth: the table's move,
 * captures by victim then attacker, promotions, the killers, quiet board
 * moves, drops near either king, and the other drops last. Moves are PICKED
 * best-first one at a time rather than sorted: with five hundred moves a node,
 * a sort costs more than the cutoff it is for.
 *
 * A DROP IS GENERATED WITH ITS CHEAP RULES (an empty square, not dead, no
 * second pawn on the file) and its dear ones are asked after it is made: the
 * king, and for a pawn that checks, whether the defender has a board move
 * (the pawn-drop mate rule, as shg_drop_fault asks it).
 *
 * MATERIAL NEVER LEAVES: a capture moves a piece from one side's board to the
 * other side's hand, so the evaluation values a hand as well as a board.
 */

#include <stdlib.h>
#include <string.h>
#include "shg_internal.h"

/* ---- the evaluation ----------------------------------------------------------------
 *
 * Centipawns from the side to move's view. THE VALUES ARE A GUESS and phase
 * 08's ablation measures the terms built on them; the material term itself is
 * not ablated, because without it nothing is being played.
 */

static const int VALUE[SHG_KINDS] = {
    0, 100, 300, 350, 500, 550, 800, 1000, 0,     /* P L N S G B R K */
    550, 550, 550, 550, 1050, 1250                /* +P +L +N +S +B +R */
};

/* A piece in hand is worth more than the same piece on the board: it can go
 * anywhere. */
#define HAND_BONUS_PCT 15

#define GUARD_BONUS       30   /* a gold, silver or gold-like next to its king */
#define GUARD_MAX         3
#define ATTACKER_PENALTY  25   /* an enemy piece within two squares of the king */
#define HAND_THREAT       10   /* each enemy piece in hand that is not a pawn  */
#define PAWN_THREAT       3
#define ENTERING_BONUS    200
#define ENTERED_PIECE     10

static int distance(int a, int b)
{
    int df = abs(a % SHG_FILES - b % SHG_FILES), dr = abs(a / SHG_FILES - b / SHG_FILES);
    return df > dr ? df : dr;
}

static int is_guard(int kind)
{
    return kind == SHG_GOLD || kind == SHG_SILVER || kind == SHG_TOKIN
        || kind == SHG_PRO_LANCE || kind == SHG_PRO_KNIGHT || kind == SHG_PRO_SILVER;
}

static int side_score(const struct shg_board *b, int side, int flags)
{
    int other = side == SHG_BLACK ? SHG_WHITE : SHG_BLACK;
    int sq, kind, score = 0, guards = 0, king = b->king[side];
    for (sq = 0; sq < SHG_SQUARES; sq++) {
        int p = b->cell[SHG_SQ_OF[sq]];
        if (p == SHG_EMPTY) continue;
        if (SHG_SIDE_OF(p) == side) {
            score += VALUE[SHG_KIND_OF(p)];
            if (!(flags & SHG_EVAL_NO_KING_SAFETY) && king >= 0 && sq != king
                && is_guard(SHG_KIND_OF(p)) && distance(sq, king) == 1)
                guards++;
        }
        else if (!(flags & SHG_EVAL_NO_KING_SAFETY) && king >= 0 && distance(sq, king) <= 2) {
            score -= ATTACKER_PENALTY;
        }
    }
    for (kind = SHG_PAWN; kind <= SHG_ROOK; kind++) {
        int n = b->hand[side][kind];
        score += n * (flags & SHG_EVAL_NO_HAND_BONUS ? VALUE[kind] : VALUE[kind] * (100 + HAND_BONUS_PCT) / 100);
        if (!(flags & SHG_EVAL_NO_KING_SAFETY) && king >= 0)
            score -= b->hand[other][kind] * (kind == SHG_PAWN ? PAWN_THREAT : HAND_THREAT);
    }
    if (!(flags & SHG_EVAL_NO_KING_SAFETY))
        score += GUARD_BONUS * (guards > GUARD_MAX ? GUARD_MAX : guards);
    if (!(flags & SHG_EVAL_NO_ENTERING) && king >= 0 && SHG_ZONE[side][king])
        score += ENTERING_BONUS + ENTERED_PIECE * shg_impasse_pieces(b, side);
    return score;
}

int shg_evaluate(const struct shg_board *b, int flags)
{
    int side;
    if (!b) return 0;
    side = b->to_move;
    return side_score(b, side, flags) - side_score(b, side == SHG_BLACK ? SHG_WHITE : SHG_BLACK, flags);
}

/* ---- moves for the search --------------------------------------------------------- */

#define MAX_PLY 64
#define TT_BITS 17
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
    int flags;
    struct tt_entry *tt;
    int killer[MAX_PLY][2];
    const unsigned long long *history;   /* the game's positions before the root */
    int n_history;
    unsigned long long path[MAX_PLY + 1];  /* the keys from the root to this node */
    int root_side;                         /* who is searching                     */
};

/* CONTEMPT: a draw is scored a little against the side that is searching and
 * a little for its opponent. Scored as an even 0, a repetition tied with every
 * quiet move of a level position and the shuffle picked it: 30 of 100 test
 * games still ended in sennichite after the history was given to the search. */
#define CONTEMPT 50

/* A POSITION REACHED AGAIN SCORES AS A DRAW, whether the game stood in it
 * before or this line of search already passed through it. Without it two
 * bots repeated a quiet position into sennichite in half of 100 test games:
 * the side that was ahead walked into the draw as readily as the side that was
 * behind. The key names the side to move, so equal keys are the same position
 * with the same player to move, as repetition counts one. This calls the first
 * return a draw where the rule needs the fourth, the usual shortcut. */
static int repeated(const struct search *s, unsigned long long key, int ply)
{
    int i;
    for (i = ply - 2; i >= 0; i -= 2) if (s->path[i] == key) return 1;
    for (i = 0; i < s->n_history; i++) if (s->history[i] == key) return 1;
    return 0;
}

/* The board moves the generator gives, then the drops with their cheap rules
 * kept: an empty square, not dead, no second pawn on the file. */
static int generate(const struct shg_board *b, int *out)
{
    int n = shg_pseudo_moves(b, out, SHG_MOVES_MAX), side = b->to_move, kind, sq;
    int pawn_file[SHG_FILES];
    if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
    memset(pawn_file, 0, sizeof pawn_file);
    for (sq = 0; sq < SHG_SQUARES; sq++)
        if (b->cell[SHG_SQ_OF[sq]] == SHG_PIECE(side, SHG_PAWN)) pawn_file[sq % SHG_FILES] = 1;
    for (kind = SHG_ROOK; kind >= SHG_PAWN; kind--) {
        if (b->hand[side][kind] < 1) continue;
        for (sq = 0; sq < SHG_SQUARES && n < SHG_MOVES_MAX; sq++) {
            int last = SHG_LAST[side][sq];
            if (b->cell[SHG_SQ_OF[sq]] != SHG_EMPTY) continue;
            if ((kind == SHG_PAWN || kind == SHG_LANCE) && last == 0) continue;
            if (kind == SHG_KNIGHT && last <= 1) continue;
            if (kind == SHG_PAWN && pawn_file[sq % SHG_FILES]) continue;
            out[n++] = SHG_DROP(kind, sq);
        }
    }
    return n;
}

/* After `move` was made by `mover`: its own king safe, and a pawn dropped with
 * check not mating (the defender, now to move, must have a board move). */
static int legal_after(const struct shg_board *b, int mover, int move)
{
    int other = mover == SHG_BLACK ? SHG_WHITE : SHG_BLACK;
    if (b->king[mover] >= 0 && shg_attacked(b, b->king[mover], other)) return 0;
    if (SHG_MOVE_DROP(move) && SHG_MOVE_KIND(move) == SHG_PAWN
        && shg_in_check(b, other) && !shg_any_board_move(b))
        return 0;
    return 1;
}

static int order_score(const struct shg_board *b, const struct search *s, int move, int tt_move, int ply)
{
    int to = SHG_MOVE_TO(move), other = b->to_move == SHG_BLACK ? SHG_WHITE : SHG_BLACK;
    if (move == tt_move) return 1000000;
    if (!SHG_MOVE_DROP(move)) {
        int victim = b->cell[SHG_SQ_OF[to]];
        int mover = b->cell[SHG_SQ_OF[SHG_MOVE_FROM(move)]];
        if (victim != SHG_EMPTY)
            return 100000 + VALUE[SHG_KIND_OF(victim)] * 4 - VALUE[SHG_KIND_OF(mover)] / 10;
        if (SHG_MOVE_PROMOTE(move))
            return 50000 + VALUE[SHG_PROMOTED_OF[SHG_KIND_OF(mover)]] - VALUE[SHG_KIND_OF(mover)];
        if (ply < MAX_PLY && (move == s->killer[ply][0] || move == s->killer[ply][1])) return 40000;
        return 1000;
    }
    if ((b->king[other] >= 0 && distance(to, b->king[other]) <= 2)
        || (b->king[b->to_move] >= 0 && distance(to, b->king[b->to_move]) <= 1))
        return 500;
    return 0;
}

/* Picks the best-scored move left in [i, n) into place i. */
static void pick(int *moves, int *score, int i, int n)
{
    int j, best = i, t;
    for (j = i + 1; j < n; j++) if (score[j] > score[best]) best = j;
    if (best == i) return;
    t = moves[i]; moves[i] = moves[best]; moves[best] = t;
    t = score[i]; score[i] = score[best]; score[best] = t;
}

/* Compared on every call, not every 1024th node: the mate search counts nodes
 * in a loop of its own, and a count that steps over the multiple of 1024 the
 * check waits for would never stop. That happened, measured: 30,720 nodes on
 * a budget of 400. */
static int spent(struct search *s)
{
    if (s->stopped) return 1;
    if (s->nodes >= s->budget) s->stopped = 1;
    return s->stopped;
}

/* ---- the mate search ---------------------------------------------------------------
 *
 * At the horizon: a check that leaves the defender no legal move. Tried only for
 * moves reaching within two squares of the enemy king, where a check from a
 * stepper or a drop has to be; a slider's long check is left to the main
 * search. Phase 08's G measures whether it is worth its nodes.
 */
static int mates_in_one(struct shg_board *b, struct search *s)
{
    int moves[SHG_MOVES_MAX];
    int n, i, us = b->to_move, them = us == SHG_BLACK ? SHG_WHITE : SHG_BLACK;
    if (b->king[them] < 0) return 0;
    n = generate(b, moves);
    for (i = 0; i < n; i++) {
        struct shg_undo u;
        int found = 0;
        if (distance(SHG_MOVE_TO(moves[i]), b->king[them]) > 2) continue;
        if (!shg_do_move(b, moves[i], &u)) continue;
        s->nodes++;
        if (legal_after(b, us, moves[i]) && shg_in_check(b, them) && !shg_has_legal_move(b))
            found = 1;
        shg_undo_move(b, &u);
        if (found) return 1;
    }
    return 0;
}

/* ---- quiescence: captures only ------------------------------------------------------ */

static int quiesce(struct shg_board *b, struct search *s, int alpha, int beta, int ply)
{
    int moves[SHG_MOVES_MAX], score[SHG_MOVES_MAX];
    int n, i, best, us = b->to_move;
    s->nodes++;
    best = shg_evaluate(b, s->flags);
    if (spent(s) || ply >= MAX_PLY - 1) return best;
    if (best >= beta) return best;
    if (best > alpha) alpha = best;
    n = shg_pseudo_moves(b, moves, SHG_MOVES_MAX);
    if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
    for (i = 0; i < n; i++) {
        int victim = b->cell[SHG_SQ_OF[SHG_MOVE_TO(moves[i])]];
        score[i] = victim == SHG_EMPTY ? -1 : order_score(b, s, moves[i], 0, ply);
    }
    for (i = 0; i < n; i++) {
        struct shg_undo u;
        int v;
        pick(moves, score, i, n);
        if (score[i] < 0) break;                /* the captures are all in front */
        if (!shg_do_move(b, moves[i], &u)) continue;
        if (!legal_after(b, us, moves[i])) { shg_undo_move(b, &u); continue; }
        v = -quiesce(b, s, -beta, -alpha, ply + 1);
        shg_undo_move(b, &u);
        if (s->stopped) return best;
        if (v > best) best = v;
        if (best > alpha) alpha = best;
        if (alpha >= beta) break;
    }
    return best;
}

/* ---- the search ---------------------------------------------------------------------- */

static int alphabeta(struct shg_board *b, struct search *s, int depth, int alpha, int beta, int ply)
{
    int moves[SHG_MOVES_MAX], score[SHG_MOVES_MAX];
    int n, i, best = -SHG_MATE_SCORE * 2, tt_move = 0, alpha0 = alpha, played = 0, us = b->to_move;
    unsigned long long key = b->key;
    struct tt_entry *e = &s->tt[key & (TT_SIZE - 1)];

    s->nodes++;
    if (spent(s)) return shg_evaluate(b, s->flags);
    if (ply <= MAX_PLY) s->path[ply] = key;
    if (ply > 0 && repeated(s, key, ply)) return us == s->root_side ? -CONTEMPT : CONTEMPT;
    if (e->key == key) {
        tt_move = e->move;
        if (e->depth >= depth) {
            if (e->flag == TT_EXACT) return e->score;
            if (e->flag == TT_LOWER && e->score > alpha) alpha = e->score;
            if (e->flag == TT_UPPER && e->score < beta) beta = e->score;
            if (alpha >= beta) return e->score;
        }
    }

    /* At the horizon the loop below never runs. A side in check is tested
     * exactly, since a missed mate is the one error this search may not make;
     * then, unless switched off, a mate in one for the side to move. */
    if (depth <= 0 || ply >= MAX_PLY - 1) {
        if (shg_in_check(b, us) && !shg_has_legal_move(b)) return -SHG_MATE_SCORE + ply;
        if (!(s->flags & SHG_SEARCH_NO_MATE) && mates_in_one(b, s)) return SHG_MATE_SCORE - ply - 1;
        return quiesce(b, s, alpha, beta, ply);
    }

    n = generate(b, moves);
    for (i = 0; i < n; i++) score[i] = order_score(b, s, moves[i], tt_move, ply);
    for (i = 0; i < n; i++) {
        struct shg_undo u;
        int v;
        pick(moves, score, i, n);
        if (!shg_do_move(b, moves[i], &u)) continue;
        if (!legal_after(b, us, moves[i])) { shg_undo_move(b, &u); continue; }
        played++;
        v = -alphabeta(b, s, depth - 1, -beta, -alpha, ply + 1);
        shg_undo_move(b, &u);
        if (s->stopped) return best > -SHG_MATE_SCORE * 2 ? best : shg_evaluate(b, s->flags);
        if (v > best) { best = v; tt_move = moves[i]; }
        if (best > alpha) alpha = best;
        if (alpha >= beta) {
            if (!SHG_MOVE_DROP(moves[i]) && b->cell[SHG_SQ_OF[SHG_MOVE_TO(moves[i])]] == SHG_EMPTY
                && ply < MAX_PLY && s->killer[ply][0] != moves[i]) {
                s->killer[ply][1] = s->killer[ply][0];
                s->killer[ply][0] = moves[i];
            }
            break;
        }
    }
    /* NO LEGAL MOVE IS A LOSS, in check or not (phase 04). Nearer is worse. */
    if (!played) return -SHG_MATE_SCORE + ply;

    /* FAIL-SOFT: best is returned, never alpha. */
    e->key = key;
    e->move = tt_move;
    e->score = (short) (best > 32000 ? 32000 : best < -32000 ? -32000 : best);
    e->depth = (signed char) depth;
    e->flag = (unsigned char) (best <= alpha0 ? TT_UPPER : best >= beta ? TT_LOWER : TT_EXACT);
    return best;
}

/* The root list is shuffled by the seed once, before anything is searched;
 * splitmix32, so a search is the same everywhere given its seed. */
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
        z = z ^ (z >> 15);
        j = (int) (z % (unsigned int) (i + 1));
        t = moves[i]; moves[i] = moves[j]; moves[j] = t;
    }
}

int shg_search(const struct shg_board *start, unsigned long long budget, int max_depth,
               unsigned int seed, int flags, const unsigned long long *history,
               int n_history, struct shg_search_info *info)
{
    int moves[SHG_MOVES_MAX];
    int n, i, depth, best_move, best_score = 0;
    struct search s;
    struct shg_board b;

    if (info) { info->nodes = 0; info->depth = 0; info->score = 0; info->stopped = 0; }
    if (!start) return 0;
    n = shg_legal(start, moves, SHG_MOVES_MAX);
    if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
    if (n == 0) return 0;

    b = *start;
    memset(&s, 0, sizeof s);
    s.budget = budget ? budget : 1;
    s.flags = flags;
    s.history = history;
    s.n_history = history && n_history > 0 ? n_history : 0;
    s.path[0] = b.key;
    s.root_side = b.to_move;
    s.tt = (struct tt_entry *) calloc(TT_SIZE, sizeof(struct tt_entry));

    shuffle(moves, n, seed);
    /* Then a stable sort by kind of move: captures and promotions before quiet
     * moves, drops last. Stable, so moves of one kind keep the shuffled order and
     * a tie within a kind is still a fair draw; and a budget too small for one
     * iteration has looked at taking material first. */
    {
        int sc[SHG_MOVES_MAX], j;
        for (i = 0; i < n; i++) sc[i] = order_score(&b, &s, moves[i], 0, 0);
        for (i = 1; i < n; i++) {
            int m = moves[i], v = sc[i];
            for (j = i - 1; j >= 0 && sc[j] < v; j--) { moves[j + 1] = moves[j]; sc[j + 1] = sc[j]; }
            moves[j + 1] = m; sc[j + 1] = v;
        }
    }
    best_move = moves[0];
    if (!s.tt) return best_move;
    if (max_depth < 1 || max_depth > MAX_PLY - 2) max_depth = MAX_PLY - 2;

    for (depth = 1; depth <= max_depth; depth++) {
        int local_best = -SHG_MATE_SCORE * 2, local_move = best_move, alpha = -SHG_MATE_SCORE * 2;
        /* The last iteration's move first; the rest keep the shuffled order. */
        for (i = 1; i < n; i++) if (moves[i] == best_move) {
            int t = moves[i];
            memmove(moves + 1, moves, (size_t) i * sizeof(int));
            moves[0] = t;
            break;
        }
        for (i = 0; i < n; i++) {
            struct shg_undo u;
            int v;
            shg_do_move(&b, moves[i], &u);
            v = -alphabeta(&b, &s, depth - 1, -SHG_MATE_SCORE * 2, -alpha, 1);
            shg_undo_move(&b, &u);
            if (s.stopped) break;
            /* STRICTLY GREATER: a tie is never picked. The first move to reach
             * the best score keeps it, and the shuffle made "first" a fair draw. */
            if (v > local_best) { local_best = v; local_move = moves[i]; }
            if (local_best > alpha) alpha = local_best;
        }
        /* A STOPPED ITERATION STILL COUNTS for every root move it finished. Each
         * improvement above is an exact score (the child's window is open below,
         * so only a fail-high returns a bound, and a fail-high is never an
         * improvement), and the last iteration's move was searched first, so
         * whatever beat it really is better at this depth. Only an iteration
         * that finished no move at all is thrown away. */
        if (s.stopped) {
            if (local_best > -SHG_MATE_SCORE * 2) {
                best_move = local_move;
                best_score = local_best;
            }
            break;
        }
        best_move = local_move;
        best_score = local_best;
        if (info) { info->depth = depth; info->score = best_score; }
        if (best_score > SHG_MATE_BOUND || best_score < -SHG_MATE_BOUND) break;
    }
    if (info) { info->nodes = s.nodes; info->stopped = s.stopped; }
    free(s.tt);
    return best_move;
}
