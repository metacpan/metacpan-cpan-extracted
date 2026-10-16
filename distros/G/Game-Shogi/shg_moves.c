/* shg_moves.c - how the pieces move, and making and unmaking a move.
 *
 * PERL-FREE by design: see include/shg_abi.h.
 *
 * THIS FILE'S SCOPE. The step and slide tables for each kind and side, the
 * pseudo-legal board moves with the promotion choice, the filter that keeps
 * the mover's king safe, and do_move and undo_move. NO DROP: that is version
 * 3. Whether a square is attacked is shg_mate.c's.
 */

#include <string.h>
#include "shg_internal.h"

/* ---- the eight directions -------------------------------------------------
 *
 * As (dfile, drank) for Black, drank -1 being forward, towards rank a. A
 * mailbox offset is drank * SHG_WIDTH - dfile: a file up is a column left.
 */

static const int DF[SHG_DIRS] = { 0, 1, -1, 1, -1, 0, 1, -1 };
static const int DR[SHG_DIRS] = { -1, -1, -1, 0, 0, 1, 1, 1 };

#define D_F   0   /* forward                   */
#define D_FL  1   /* forward and a file up     */
#define D_FR  2   /* forward and a file down   */
#define D_L   3   /* a file up                 */
#define D_R   4   /* a file down               */
#define D_B   5   /* back                      */
#define D_BL  6   /* back and a file up        */
#define D_BR  7   /* back and a file down      */

int SHG_DIR_OFF[SHG_DIRS];
int SHG_NSTEPS[SHG_SIDES][SHG_KINDS];
int SHG_STEP_OFF[SHG_SIDES][SHG_KINDS][SHG_DIRS];
int SHG_NSLIDES[SHG_SIDES][SHG_KINDS];
int SHG_SLIDE_OFF[SHG_SIDES][SHG_KINDS][4];
unsigned SHG_SLIDE_MASK[SHG_SIDES][SHG_KINDS];

/* ---- each kind, from W's "Movement" section, as Black sees it --------------
 *
 * A list of directions ends at -1. The knight's jump is not a direction and
 * is added on its own: two ranks forward and one file either way.
 */

static const int PAWN_STEPS[]   = { D_F, -1 };
static const int SILVER_STEPS[] = { D_F, D_FL, D_FR, D_BL, D_BR, -1 };
static const int GOLD_STEPS[]   = { D_F, D_FL, D_FR, D_L, D_R, D_B, -1 };
static const int KING_STEPS[]   = { D_F, D_FL, D_FR, D_L, D_R, D_B, D_BL, D_BR, -1 };
static const int ORTH[]         = { D_F, D_L, D_R, D_B, -1 };
static const int DIAG[]         = { D_FL, D_FR, D_BL, D_BR, -1 };
static const int LANCE_SLIDES[] = { D_F, -1 };
static const int NONE[]         = { -1 };

static const int *STEPS_OF[SHG_KINDS];
static const int *SLIDES_OF[SHG_KINDS];

/* What each kind's tables must hold, as (steps, slides): the knight's two
 * jumps count as steps. Checked when the tables are built. */
static const int WANT_STEPS[SHG_KINDS]  = { 0, 1, 0, 2, 5, 6, 0, 0, 8, 6, 6, 6, 6, 4, 4 };
static const int WANT_SLIDES[SHG_KINDS] = { 0, 0, 1, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 4, 4 };

static int offset_of(int side, int df, int dr)
{
    if (side == SHG_WHITE) dr = -dr;
    return dr * SHG_WIDTH - df;
}

static int dir_of_offset(int off)
{
    int d;
    for (d = 0; d < SHG_DIRS; d++)
        if (SHG_DIR_OFF[d] == off) return d;
    return -1;
}

int shg_move_tables_init(void)
{
    int side, kind, i, ok = 1;

    STEPS_OF[SHG_PAWN] = PAWN_STEPS;     SLIDES_OF[SHG_PAWN] = NONE;
    STEPS_OF[SHG_LANCE] = NONE;          SLIDES_OF[SHG_LANCE] = LANCE_SLIDES;
    STEPS_OF[SHG_KNIGHT] = NONE;         SLIDES_OF[SHG_KNIGHT] = NONE;
    STEPS_OF[SHG_SILVER] = SILVER_STEPS; SLIDES_OF[SHG_SILVER] = NONE;
    STEPS_OF[SHG_GOLD] = GOLD_STEPS;     SLIDES_OF[SHG_GOLD] = NONE;
    STEPS_OF[SHG_BISHOP] = NONE;         SLIDES_OF[SHG_BISHOP] = DIAG;
    STEPS_OF[SHG_ROOK] = NONE;           SLIDES_OF[SHG_ROOK] = ORTH;
    STEPS_OF[SHG_KING] = KING_STEPS;     SLIDES_OF[SHG_KING] = NONE;
    STEPS_OF[SHG_TOKIN] = GOLD_STEPS;    SLIDES_OF[SHG_TOKIN] = NONE;
    STEPS_OF[SHG_PRO_LANCE] = GOLD_STEPS;  SLIDES_OF[SHG_PRO_LANCE] = NONE;
    STEPS_OF[SHG_PRO_KNIGHT] = GOLD_STEPS; SLIDES_OF[SHG_PRO_KNIGHT] = NONE;
    STEPS_OF[SHG_PRO_SILVER] = GOLD_STEPS; SLIDES_OF[SHG_PRO_SILVER] = NONE;
    STEPS_OF[SHG_HORSE] = ORTH;          SLIDES_OF[SHG_HORSE] = DIAG;
    STEPS_OF[SHG_DRAGON] = DIAG;         SLIDES_OF[SHG_DRAGON] = ORTH;

    for (i = 0; i < SHG_DIRS; i++) SHG_DIR_OFF[i] = offset_of(SHG_BLACK, DF[i], DR[i]);

    for (side = 0; side < SHG_SIDES; side++) {
        for (kind = SHG_PAWN; kind <= SHG_DRAGON; kind++) {
            const int *d;
            int n = 0, m = 0;
            unsigned mask = 0;
            for (d = STEPS_OF[kind]; *d >= 0; d++)
                SHG_STEP_OFF[side][kind][n++] = offset_of(side, DF[*d], DR[*d]);
            if (kind == SHG_KNIGHT) {
                SHG_STEP_OFF[side][kind][n++] = offset_of(side, 1, -2);
                SHG_STEP_OFF[side][kind][n++] = offset_of(side, -1, -2);
            }
            for (d = SLIDES_OF[kind]; *d >= 0; d++) {
                int off = offset_of(side, DF[*d], DR[*d]);
                SHG_SLIDE_OFF[side][kind][m++] = off;
                mask |= 1u << dir_of_offset(off);
            }
            SHG_NSTEPS[side][kind] = n;
            SHG_NSLIDES[side][kind] = m;
            SHG_SLIDE_MASK[side][kind] = mask;
            if (n != WANT_STEPS[kind] || m != WANT_SLIDES[kind]) ok = 0;
        }
    }
    return ok;
}

/* ---- the pseudo-legal board moves -------------------------------------------
 *
 * W line 363: a move may promote when it starts or ends in the zone. W line
 * 365: a pawn or lance onto the last rank, or a knight onto either of the
 * last two, must. A promotion is listed before its plain twin.
 */

static int emit(int *out, int n, int max, int side, int kind, int from, int to)
{
    int can = SHG_PROMOTED_OF[kind] && (SHG_ZONE[side][from] || SHG_ZONE[side][to]);
    int last = SHG_LAST[side][to];
    int forced = ((kind == SHG_PAWN || kind == SHG_LANCE) && last == 0)
              || (kind == SHG_KNIGHT && last <= 1);
    if (can) {
        if (n < max) out[n] = SHG_MOVE(from, to, 1);
        n++;
    }
    if (!forced) {
        if (n < max) out[n] = SHG_MOVE(from, to, 0);
        n++;
    }
    return n;
}

int shg_pseudo_moves(const struct shg_board *b, int *out, int max)
{
    int sq, n = 0, side, i;
    if (!b || (!out && max > 0)) return 0;
    side = b->to_move;
    for (sq = 0; sq < SHG_SQUARES; sq++) {
        int box = SHG_SQ_OF[sq], p = b->cell[box], kind, t, c;
        if (p == SHG_EMPTY || SHG_SIDE_OF(p) != side) continue;
        kind = SHG_KIND_OF(p);
        for (i = 0; i < SHG_NSTEPS[side][kind]; i++) {
            t = box + SHG_STEP_OFF[side][kind][i];
            c = b->cell[t];
            if (c == SHG_OFF || (c != SHG_EMPTY && SHG_SIDE_OF(c) == side)) continue;
            n = emit(out, n, max, side, kind, sq, SHG_SQ_AT[t]);
        }
        for (i = 0; i < SHG_NSLIDES[side][kind]; i++) {
            int off = SHG_SLIDE_OFF[side][kind][i];
            for (t = box + off; ; t += off) {
                c = b->cell[t];
                if (c == SHG_OFF || (c != SHG_EMPTY && SHG_SIDE_OF(c) == side)) break;
                n = emit(out, n, max, side, kind, sq, SHG_SQ_AT[t]);
                if (c != SHG_EMPTY) break;
            }
        }
    }
    return n;
}

/* ---- the legal board moves ----------------------------------------------------
 *
 * Each pseudo-legal move is made on a copy and kept when the mover's king is
 * not attacked after it. A move do_move refuses (taking a king, a full hand)
 * is not kept either.
 */

int shg_board_moves(const struct shg_board *b, int *out, int max)
{
    int all[SHG_MOVES_MAX];
    int count, i, n = 0, side;
    struct shg_board copy;
    struct shg_undo u;
    if (!b || (!out && max > 0)) return 0;
    count = shg_pseudo_moves(b, all, SHG_MOVES_MAX);
    if (count > SHG_MOVES_MAX) count = SHG_MOVES_MAX;
    copy = *b;
    side = b->to_move;
    for (i = 0; i < count; i++) {
        int safe;
        if (!shg_do_move(&copy, all[i], &u)) continue;
        safe = copy.king[side] < 0
            || !shg_attacked(&copy, copy.king[side], side == SHG_BLACK ? SHG_WHITE : SHG_BLACK);
        shg_undo_move(&copy, &u);
        if (!safe) continue;
        if (n < max) out[n] = all[i];
        n++;
    }
    return n;
}

/* ---- making and unmaking a move ------------------------------------------- */

static int is_board_move(int move)
{
    return move >= 0 && !SHG_MOVE_DROP(move) && (move >> 16) == 0
        && SHG_IS_SQ(SHG_MOVE_FROM(move)) && SHG_IS_SQ(SHG_MOVE_TO(move))
        && SHG_MOVE_FROM(move) != SHG_MOVE_TO(move);
}

/* A drop: bit 15, a hand kind in bits 16-19, a square in bits 7-13, and
 * nothing else. */
static int is_drop(int move)
{
    return move >= 0 && SHG_MOVE_DROP(move) && (move >> 20) == 0
        && SHG_MOVE_FROM(move) == 0 && !SHG_MOVE_PROMOTE(move)
        && SHG_IS_HAND(SHG_MOVE_KIND(move)) && SHG_IS_SQ(SHG_MOVE_TO(move));
}

static int do_drop(struct shg_board *b, int move, struct shg_undo *undo)
{
    int side = b->to_move, kind = SHG_MOVE_KIND(move), to = SHG_MOVE_TO(move);
    if (b->hand[side][kind] < 1 || b->cell[SHG_SQ_OF[to]] != SHG_EMPTY) return 0;
    undo->move = move;
    undo->moved = SHG_PIECE(side, kind);
    undo->captured = SHG_EMPTY;
    undo->move_number = b->move_number;
    shg_set_hand(b, side, kind, b->hand[side][kind] - 1);
    shg_put(b, to, SHG_PIECE(side, kind));
    shg_set_to_move(b, side == SHG_BLACK ? SHG_WHITE : SHG_BLACK);
    if (b->move_number < SHG_MOVE_MAX) b->move_number++;
    return 1;
}

static int undo_drop(struct shg_board *b, const struct shg_undo *undo)
{
    int move = undo->move, p = undo->moved, kind = SHG_MOVE_KIND(move), to = SHG_MOVE_TO(move), side;
    if (p <= 0 || (p & ~0x1F) || SHG_KIND_OF(p) != kind) return 0;
    side = SHG_SIDE_OF(p);
    if (b->to_move == side || undo->captured != SHG_EMPTY) return 0;
    if (b->cell[SHG_SQ_OF[to]] != p) return 0;
    if (b->hand[side][kind] + 1 > SHG_SET_OF[kind]) return 0;
    if (undo->move_number < 1 || undo->move_number > SHG_MOVE_MAX) return 0;
    shg_set_to_move(b, side);
    b->move_number = undo->move_number;
    shg_lift(b, to);
    shg_set_hand(b, side, kind, b->hand[side][kind] + 1);
    return 1;
}

int shg_do_move(struct shg_board *b, int move, struct shg_undo *undo)
{
    int from, to, p, c, side, kind, base = 0, put;
    if (b && undo && is_drop(move)) return do_drop(b, move, undo);
    if (!b || !undo || !is_board_move(move)) return 0;
    from = SHG_MOVE_FROM(move);
    to = SHG_MOVE_TO(move);
    side = b->to_move;
    p = b->cell[SHG_SQ_OF[from]];
    c = b->cell[SHG_SQ_OF[to]];
    if (p == SHG_EMPTY || SHG_SIDE_OF(p) != side) return 0;
    if (c != SHG_EMPTY && SHG_SIDE_OF(c) == side) return 0;
    kind = SHG_KIND_OF(p);
    if (SHG_MOVE_PROMOTE(move) && !SHG_PROMOTED_OF[kind]) return 0;
    if (c != SHG_EMPTY) {
        base = SHG_UNPROMOTED_OF[SHG_KIND_OF(c)];
        if (base == SHG_KING) return 0;
        if (b->hand[side][base] + 1 > SHG_SET_OF[base]) return 0;
    }

    undo->move = move;
    undo->moved = p;
    undo->captured = c;
    undo->move_number = b->move_number;

    put = SHG_MOVE_PROMOTE(move) ? SHG_PIECE(side, SHG_PROMOTED_OF[kind]) : p;
    shg_lift(b, from);
    if (c != SHG_EMPTY) {
        shg_lift(b, to);
        shg_set_hand(b, side, base, b->hand[side][base] + 1);
    }
    shg_put(b, to, put);
    shg_set_to_move(b, side == SHG_BLACK ? SHG_WHITE : SHG_BLACK);
    if (b->move_number < SHG_MOVE_MAX) b->move_number++;
    return 1;
}

int shg_undo_move(struct shg_board *b, const struct shg_undo *undo)
{
    int move, from, to, p, c, side, kind, base = 0, shown;
    if (!b || !undo) return 0;
    move = undo->move;
    p = undo->moved;
    c = undo->captured;
    if (is_drop(move)) return undo_drop(b, undo);
    if (!is_board_move(move)) return 0;
    if (p <= 0 || (p & ~0x1F) || !SHG_IS_KIND(SHG_KIND_OF(p))) return 0;
    from = SHG_MOVE_FROM(move);
    to = SHG_MOVE_TO(move);
    side = SHG_SIDE_OF(p);
    kind = SHG_KIND_OF(p);
    if (b->to_move == side) return 0;
    if (SHG_MOVE_PROMOTE(move) && !SHG_PROMOTED_OF[kind]) return 0;
    shown = SHG_MOVE_PROMOTE(move) ? SHG_PIECE(side, SHG_PROMOTED_OF[kind]) : p;
    if (b->cell[SHG_SQ_OF[from]] != SHG_EMPTY || b->cell[SHG_SQ_OF[to]] != shown) return 0;
    if (c != SHG_EMPTY) {
        if (c < 0 || (c & ~0x1F) || !SHG_IS_KIND(SHG_KIND_OF(c)) || SHG_SIDE_OF(c) == side) return 0;
        base = SHG_UNPROMOTED_OF[SHG_KIND_OF(c)];
        if (base == SHG_KING || b->hand[side][base] < 1) return 0;
    }
    if (undo->move_number < 1 || undo->move_number > SHG_MOVE_MAX) return 0;

    shg_set_to_move(b, side);
    b->move_number = undo->move_number;
    shg_lift(b, to);
    if (c != SHG_EMPTY) {
        shg_set_hand(b, side, base, b->hand[side][base] - 1);
        shg_put(b, to, c);
    }
    shg_put(b, from, p);
    return 1;
}

/* ---- the drops, version 3 ----------------------------------------------------
 *
 * W lines 499-507. A piece from hand onto any empty square, unpromoted, never
 * capturing. Three restrictions: no piece where it could never move; no pawn
 * onto a file with an unpromoted pawn of the same side; no pawn dropped to
 * give mate. And, as for any move, not leaving the side's own king attacked.
 */

/* 1 when the side to move has a legal board move; it stops at the first. */
static int any_board_move(const struct shg_board *b)
{
    int all[SHG_MOVES_MAX];
    int count, i, side = b->to_move;
    struct shg_board copy = *b;
    struct shg_undo u;
    count = shg_pseudo_moves(b, all, SHG_MOVES_MAX);
    if (count > SHG_MOVES_MAX) count = SHG_MOVES_MAX;
    for (i = 0; i < count; i++) {
        int safe;
        if (!shg_do_move(&copy, all[i], &u)) continue;
        safe = copy.king[side] < 0
            || !shg_attacked(&copy, copy.king[side], side == SHG_BLACK ? SHG_WHITE : SHG_BLACK);
        shg_undo_move(&copy, &u);
        if (safe) return 1;
    }
    return 0;
}

static int pawn_on_file(const struct shg_board *b, int side, int sq)
{
    int col = sq % SHG_FILES, row;
    for (row = 0; row < SHG_RANKS; row++)
        if (b->cell[SHG_SQ_OF[row * SHG_FILES + col]] == SHG_PIECE(side, SHG_PAWN)) return 1;
    return 0;
}

int shg_drop_fault(const struct shg_board *b, int kind, int sq)
{
    int side, last, other, fault = SHG_DROP_OK;
    struct shg_board copy;
    struct shg_undo u;
    if (!b || !SHG_IS_HAND(kind) || !SHG_IS_SQ(sq)) return SHG_DROP_BAD;
    side = b->to_move;
    other = side == SHG_BLACK ? SHG_WHITE : SHG_BLACK;
    if (b->hand[side][kind] < 1) return SHG_DROP_NOT_HELD;
    if (b->cell[SHG_SQ_OF[sq]] != SHG_EMPTY) return SHG_DROP_OCCUPIED;
    last = SHG_LAST[side][sq];
    if (((kind == SHG_PAWN || kind == SHG_LANCE) && last == 0) || (kind == SHG_KNIGHT && last <= 1))
        return SHG_DROP_DEAD;
    if (kind == SHG_PAWN && pawn_on_file(b, side, sq)) return SHG_DROP_TWO_PAWNS;

    copy = *b;
    if (!shg_do_move(&copy, SHG_DROP(kind, sq), &u)) return SHG_DROP_NOT_HELD;
    if (copy.king[side] >= 0 && shg_attacked(&copy, copy.king[side], other))
        fault = SHG_DROP_IN_CHECK;
    /* A dropped pawn checks only from the square in front of the king, so the
     * check cannot be blocked and is never double: the only answers are board
     * moves. No board move is mate. */
    else if (kind == SHG_PAWN && shg_in_check(&copy, other) && !any_board_move(&copy))
        fault = SHG_DROP_PAWN_MATE;
    return fault;
}

int shg_drops(const struct shg_board *b, int *out, int max)
{
    static const int ORDER[SHG_HAND_KINDS - 1] = { SHG_ROOK, SHG_BISHOP, SHG_GOLD,
        SHG_SILVER, SHG_KNIGHT, SHG_LANCE, SHG_PAWN };
    int i, sq, n = 0;
    if (!b || (!out && max > 0)) return 0;
    for (i = 0; i < SHG_HAND_KINDS - 1; i++) {
        int kind = ORDER[i];
        if (b->hand[b->to_move][kind] < 1) continue;
        for (sq = 0; sq < SHG_SQUARES; sq++) {
            if (shg_drop_fault(b, kind, sq) != SHG_DROP_OK) continue;
            if (n < max) out[n] = SHG_DROP(kind, sq);
            n++;
        }
    }
    return n;
}

int shg_legal(const struct shg_board *b, int *out, int max)
{
    int n, m, room;
    if (!b || (!out && max > 0)) return 0;
    n = shg_board_moves(b, out, max);
    room = n < max ? max - n : 0;
    m = shg_drops(b, room ? out + n : NULL, room);
    return n + m;
}

int shg_has_legal_move(const struct shg_board *b)
{
    int i, sq;
    if (!b) return 0;
    if (any_board_move(b)) return 1;
    for (i = SHG_PAWN; i <= SHG_ROOK; i++) {
        if (b->hand[b->to_move][i] < 1) continue;
        for (sq = 0; sq < SHG_SQUARES; sq++)
            if (shg_drop_fault(b, i, sq) == SHG_DROP_OK) return 1;
    }
    return 0;
}

/* ---- why a move is refused, version 4 ---------------------------------------
 *
 * Built on the lists, so it cannot disagree with them: a board move is looked
 * for in the pseudo-legal list, by its squares and then by its promotion, and
 * then made on a copy to ask about the king. A drop is drop_fault's answer.
 */

int shg_move_fault(const struct shg_board *b, int move)
{
    int all[SHG_MOVES_MAX];
    int count, i, from, to, p, plain = 0, promote = 0, side, safe;
    struct shg_board copy;
    struct shg_undo u;

    if (!b) return SHG_FAULT_BAD;
    if (is_drop(move)) {
        switch (shg_drop_fault(b, SHG_MOVE_KIND(move), SHG_MOVE_TO(move))) {
        case SHG_DROP_OK:        return SHG_FAULT_OK;
        case SHG_DROP_NOT_HELD:  return SHG_FAULT_NOT_HELD;
        case SHG_DROP_OCCUPIED:  return SHG_FAULT_OCCUPIED;
        case SHG_DROP_DEAD:      return SHG_FAULT_DEAD;
        case SHG_DROP_TWO_PAWNS: return SHG_FAULT_TWO_PAWNS;
        case SHG_DROP_IN_CHECK:  return SHG_FAULT_IN_CHECK;
        case SHG_DROP_PAWN_MATE: return SHG_FAULT_PAWN_MATE;
        default:                 return SHG_FAULT_BAD;
        }
    }
    if (!is_board_move(move)) return SHG_FAULT_BAD;

    from = SHG_MOVE_FROM(move);
    to = SHG_MOVE_TO(move);
    side = b->to_move;
    p = b->cell[SHG_SQ_OF[from]];
    if (p == SHG_EMPTY || SHG_SIDE_OF(p) != side) return SHG_FAULT_NOT_YOURS;

    count = shg_pseudo_moves(b, all, SHG_MOVES_MAX);
    if (count > SHG_MOVES_MAX) count = SHG_MOVES_MAX;
    for (i = 0; i < count; i++) {
        if (SHG_MOVE_FROM(all[i]) != from || SHG_MOVE_TO(all[i]) != to) continue;
        if (SHG_MOVE_PROMOTE(all[i])) promote = 1;
        else plain = 1;
    }
    if (!plain && !promote) return SHG_FAULT_CANNOT_REACH;
    if (SHG_MOVE_PROMOTE(move) && !promote) return SHG_FAULT_PROMOTE_NOT_ALLOWED;
    if (!SHG_MOVE_PROMOTE(move) && !plain) return SHG_FAULT_PROMOTE_REQUIRED;

    copy = *b;
    if (!shg_do_move(&copy, move, &u)) return SHG_FAULT_BAD;
    safe = copy.king[side] < 0
        || !shg_attacked(&copy, copy.king[side], side == SHG_BLACK ? SHG_WHITE : SHG_BLACK);
    return safe ? SHG_FAULT_OK : SHG_FAULT_IN_CHECK;
}

/* For the search: whether the side to move has a legal board move. */
int shg_any_board_move(const struct shg_board *b) { return b ? any_board_move(b) : 0; }
