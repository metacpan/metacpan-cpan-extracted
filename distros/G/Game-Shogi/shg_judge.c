/* shg_judge.c - what needs a game's history: a position packed into bytes,
 * the fourfold repetition and the perpetual check, and the impasse
 * declaration.
 *
 * PERL-FREE by design: see include/shg_abi.h. The history is the caller's;
 * this file reads it and keeps nothing.
 */

#include <string.h>
#include "shg_internal.h"

/* ---- a packed position ----------------------------------------------------- */

int shg_pack(const struct shg_board *b, unsigned char *out)
{
    int sq, side, kind, n = 0;
    if (!b || !out) return -1;
    for (sq = 0; sq < SHG_SQUARES; sq++) out[n++] = b->cell[SHG_SQ_OF[sq]];
    for (side = 0; side < SHG_SIDES; side++)
        for (kind = SHG_PAWN; kind <= SHG_ROOK; kind++) out[n++] = b->hand[side][kind];
    out[n++] = (unsigned char) b->to_move;
    return n;
}

/* ---- the repetition judge ------------------------------------------------------
 *
 * W line 613. The last position is judged: when it has stood SHG_REP_TIMES
 * times, counting itself, the game is over. Between the first of those times
 * and the last, a side whose every move gave check has kept checking, and
 * loses. Which side made the move into position j is the side to move in
 * position j - 1, the last byte of its packing.
 */

int shg_repetition(const unsigned long long *keys, const unsigned char *packed,
                   const unsigned char *gave_check, int n, int *loser)
{
    int last, j, seen = 0, first = -1, side;
    int moved[SHG_SIDES] = { 0, 0 }, all_check[SHG_SIDES] = { 1, 1 }, kept = -1, keepers = 0;
    const unsigned char *now;

    if (loser) *loser = -1;
    if (!keys || !packed || !gave_check || n < 1) return SHG_REP_NONE;
    last = n - 1;
    now = packed + (size_t) last * SHG_PACKED;
    for (j = last; j >= 0; j--) {
        if (keys[j] != keys[last]) continue;
        if (memcmp(packed + (size_t) j * SHG_PACKED, now, SHG_PACKED) != 0) continue;
        if (++seen == SHG_REP_TIMES) { first = j; break; }
    }
    if (first < 0) return SHG_REP_NONE;

    for (j = first + 1; j <= last; j++) {
        int mover = packed[(size_t) (j - 1) * SHG_PACKED + SHG_PACKED - 1];
        if (!SHG_IS_SIDE(mover)) continue;
        moved[mover] = 1;
        if (!gave_check[j]) all_check[mover] = 0;
    }
    for (side = 0; side < SHG_SIDES; side++)
        if (moved[side] && all_check[side]) { kept = side; keepers++; }
    if (keepers == 1) {
        if (loser) *loser = kept;
        return SHG_REP_PERPETUAL;
    }
    return SHG_REP_DRAW;
}

/* ---- the impasse declaration ------------------------------------------------------
 *
 * Y lines 101-106 and 125. The camp is the declarer's promotion zone, the
 * three ranks the opponent started on.
 */

static int worth(int kind)
{
    int base = SHG_UNPROMOTED_OF[kind];
    return base == SHG_ROOK || base == SHG_BISHOP ? 5 : 1;
}

int shg_impasse_points(const struct shg_board *b, int side)
{
    int sq, kind, points = 0;
    if (!b || !SHG_IS_SIDE(side)) return -1;
    for (sq = 0; sq < SHG_SQUARES; sq++) {
        int p = b->cell[SHG_SQ_OF[sq]];
        if (p == SHG_EMPTY || SHG_SIDE_OF(p) != side || SHG_KIND_OF(p) == SHG_KING) continue;
        if (!SHG_ZONE[side][sq]) continue;
        points += worth(SHG_KIND_OF(p));
    }
    for (kind = SHG_PAWN; kind <= SHG_ROOK; kind++) points += b->hand[side][kind] * worth(kind);
    return points;
}

int shg_impasse_pieces(const struct shg_board *b, int side)
{
    int sq, pieces = 0;
    if (!b || !SHG_IS_SIDE(side)) return -1;
    for (sq = 0; sq < SHG_SQUARES; sq++) {
        int p = b->cell[SHG_SQ_OF[sq]];
        if (p == SHG_EMPTY || SHG_SIDE_OF(p) != side || SHG_KIND_OF(p) == SHG_KING) continue;
        if (SHG_ZONE[side][sq]) pieces++;
    }
    return pieces;
}

int shg_declare_fault(const struct shg_board *b)
{
    int side, king;
    if (!b) return SHG_DECLARE_NO_KING;
    side = b->to_move;
    king = b->king[side];
    if (king < 0 || !SHG_ZONE[side][king]) return SHG_DECLARE_NO_KING;
    if (shg_impasse_pieces(b, side) < SHG_DECLARE_PIECES) return SHG_DECLARE_FEW_PIECES;
    if (shg_in_check(b, side)) return SHG_DECLARE_IN_CHECK;
    if (shg_impasse_points(b, side)
        < (side == SHG_BLACK ? SHG_DECLARE_POINTS_BLACK : SHG_DECLARE_POINTS_WHITE))
        return SHG_DECLARE_FEW_POINTS;
    return SHG_DECLARE_OK;
}
