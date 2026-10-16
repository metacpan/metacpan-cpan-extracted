/* sth_moves.c - one step, one hop, and moving a piece.
 *
 * PERL-FREE by design: see include/sth_abi.h.
 *
 * THIS FILE'S SCOPE. Version 2: the two atoms a move is made of, a step to a
 * neighbouring empty hole and a single hop over one neighbouring piece of any
 * seat into the empty hole straight beyond it. Nothing is captured, so a hop
 * changes nothing but where the hopping piece is. Moving a piece is a
 * structure primitive like put, and judges nothing about whose turn it is.
 * Version 3: the chain built from the atoms, as a reach, a path and the legal
 * moves of the seat to move.
 */

#include "sth_internal.h"

int sth_steps(const struct sth_board *b, int hole, int *out, int max)
{
    int d, sq, to, n = 0;
    if (!b || !STH_IS_HOLE(hole)) return 0;
    sq = STH_SQ_OF[hole];
    for (d = 0; d < STH_DIRS; d++) {
        to = sq + STH_STEP[d];
        if (b->cell[to] != STH_EMPTY) continue;
        if (n < max) out[n] = STH_HOLE_AT[to];
        n++;
    }
    return n;
}

/* THE MIDDLE IS READ BEFORE THE LANDING. A middle that holds a piece is a
 * hole, so the landing is one square past a hole at most, inside the margin
 * whatever the direction. `from` is the hole the moving piece left: in a chain
 * it is empty, so it can be landed on and cannot be hopped over. */
int sth_hops(const struct sth_board *b, int hole, int from, int *out, int max)
{
    int d, sq, mid, land, from_sq, c, n = 0;
    if (!b || !STH_IS_HOLE(hole)) return 0;
    sq = STH_SQ_OF[hole];
    from_sq = STH_IS_HOLE(from) ? STH_SQ_OF[from] : -1;
    for (d = 0; d < STH_DIRS; d++) {
        mid = sq + STH_STEP[d];
        if (mid == from_sq || !STH_IS_PIECE(b->cell[mid])) continue;
        land = mid + STH_STEP[d];
        c = b->cell[land];
        if (c != STH_EMPTY && land != from_sq) continue;
        if (n < max) out[n] = STH_HOLE_AT[land];
        n++;
    }
    return n;
}

int sth_do_move(struct sth_board *b, int from, int to)
{
    int fsq, tsq, seat;
    if (!b || !STH_IS_HOLE(from) || !STH_IS_HOLE(to) || from == to) return 0;
    fsq = STH_SQ_OF[from];
    tsq = STH_SQ_OF[to];
    seat = b->cell[fsq];
    if (!STH_IS_PIECE(seat) || b->cell[tsq] != STH_EMPTY) return 0;
    b->cell[fsq] = STH_EMPTY;
    b->cell[tsq] = (unsigned char) seat;
    b->key ^= STH_ZOB[seat][from] ^ STH_ZOB[seat][to];
    return 1;
}

/* The move from `from` to `to` taken back: the piece on `to` goes home. */
int sth_undo_move(struct sth_board *b, int from, int to)
{
    int fsq, tsq, seat;
    if (!b || !STH_IS_HOLE(from) || !STH_IS_HOLE(to) || from == to) return 0;
    fsq = STH_SQ_OF[from];
    tsq = STH_SQ_OF[to];
    seat = b->cell[tsq];
    if (!STH_IS_PIECE(seat) || b->cell[fsq] != STH_EMPTY) return 0;
    b->cell[tsq] = STH_EMPTY;
    b->cell[fsq] = (unsigned char) seat;
    b->key ^= STH_ZOB[seat][to] ^ STH_ZOB[seat][from];
    return 1;
}

/* ---- version 3: the reach, the path and the legal moves ---------------------
 *
 * A move is a step, or a chain of hops that may stop after any hop. Nothing
 * is captured, so the board after a move depends only on where it started and
 * where it stopped, and the reach is the set of holes a piece can stop on.
 *
 * WALKS AND SIMPLE PATHS REACH THE SAME HOLES. While a chain runs only the
 * hopping piece moves, and its start is empty throughout, so the board it hops
 * over never changes: the hops form a fixed graph, and anything a walk round
 * that graph reaches, a path with no hole twice reaches too. So a breadth-first
 * search that visits each hole once finds every stop, and the first time it
 * finds a hole is by a shortest chain.
 */

struct sth_bfs {
    int parent[STH_HOLES];      /* the hole a chain hopped from, or -1     */
    int depth[STH_HOLES];       /* hops to get here; 0 for the start       */
    int found[STH_HOLES];       /* 1 for every hole a chain can stop on    */
};

static void hop_search(const struct sth_board *b, int from, struct sth_bfs *s)
{
    int queue[STH_HOLES], head = 0, tail = 0, i, n, at, land[STH_HOPS_MAX];
    for (i = 0; i < STH_HOLES; i++) { s->parent[i] = -1; s->depth[i] = -1; s->found[i] = 0; }
    s->depth[from] = 0;
    queue[tail++] = from;
    while (head < tail) {
        at = queue[head++];
        n = sth_hops(b, at, from, land, STH_HOPS_MAX);
        for (i = 0; i < n; i++) {
            if (s->depth[land[i]] >= 0) continue;
            s->depth[land[i]] = s->depth[at] + 1;
            s->parent[land[i]] = at;
            s->found[land[i]] = 1;
            queue[tail++] = land[i];
        }
    }
}

static int movable(const struct sth_board *b, int from)
{
    return b && STH_IS_HOLE(from) && STH_IS_PIECE(b->cell[STH_SQ_OF[from]]);
}

int sth_reach(const struct sth_board *b, int from, int *out, int max)
{
    struct sth_bfs s;
    int step[STH_STEPS_MAX], i, ns, n = 0;
    if (!movable(b, from)) return 0;
    hop_search(b, from, &s);
    ns = sth_steps(b, from, step, STH_STEPS_MAX);
    for (i = 0; i < ns; i++) s.found[step[i]] = 1;
    s.found[from] = 0;
    for (i = 0; i < STH_HOLES; i++) {
        if (!s.found[i]) continue;
        if (n < max) out[n] = i;
        n++;
    }
    return n;
}

/* A STEP IS SHOWN AS A STEP. A hole a step reaches is shown as the step, even
 * when a chain reaches it too: the board ends the same, and one move is one
 * move. Otherwise the BFS parents, which is a shortest chain, and among the
 * shortest the one whose hops were found first in direction order. */
int sth_path(const struct sth_board *b, int from, int to, int *out, int max)
{
    struct sth_bfs s;
    int step[STH_STEPS_MAX], i, ns, n, at;
    if (!movable(b, from) || !STH_IS_HOLE(to) || to == from) return 0;
    ns = sth_steps(b, from, step, STH_STEPS_MAX);
    for (i = 0; i < ns; i++) {
        if (step[i] != to) continue;
        if (max > 0) out[0] = from;
        if (max > 1) out[1] = to;
        return 2;
    }
    hop_search(b, from, &s);
    if (!s.found[to]) return 0;
    n = s.depth[to] + 1;
    for (at = to, i = n - 1; i >= 0; i--, at = s.parent[at])
        if (i < max) out[i] = at;
    return n;
}

int sth_legal(const struct sth_board *b, int *out_from, int *out_to, int max)
{
    int h, i, k, n = 0, to[STH_HOLES];
    if (!b) return 0;
    for (h = 0; h < STH_HOLES; h++) {
        if (b->cell[STH_SQ_OF[h]] != b->to_move) continue;
        k = sth_reach(b, h, to, STH_HOLES);
        for (i = 0; i < k; i++) {
            if (n < max) { out_from[n] = h; out_to[n] = to[i]; }
            n++;
        }
    }
    return n;
}
