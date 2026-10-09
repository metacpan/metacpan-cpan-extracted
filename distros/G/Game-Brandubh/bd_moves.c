/* bd_moves.c - where a piece may go, what it captures, and two perfts.
 *
 * PERL-FREE, as bd_engine.c is.
 *
 * THE RULES THIS FILE IMPLEMENTS, quoted from the source the distribution
 * names in its documentation:
 *
 *   4. "Pieces move any distance orthogonally, not landing on nor jumping over
 *      other pieces on the board."
 *   5. "No piece may land on the central square, not even the king once he has
 *      left it. Only the king may land on the corner squares."
 *
 * and one decision the source leaves open: a piece may SLIDE ACROSS the empty
 * throne and may not stop on it. Rule 4 forbids jumping pieces and rule 5
 * forbids landing; neither says the empty square blocks. bd_variant.throne_pass
 * turns that off.
 *
 * TWO PERFTS. `relocate` moves a piece and passes the turn, and perft_slides
 * counts that capture-free game; `do_move` captures as well, and perft counts
 * that one. Two ladders, so that a wrong number says which half is wrong.
 *
 * THE CAPTURE RULES, from the same source:
 *
 *   6. "A piece other than the king is captured when it is surrounded
 *      orthogonally on two opposite squares by enemies. The king can take part
 *      in captures in partnership with a defender."
 *   7. "A piece may also be captured between an enemy and the empty central
 *      square or a corner square."
 *   8. "When in the central square, the king is captured by surrounding him on
 *      four orthogonal sides with attackers."
 *   9. "When standing beside the central square, the king may be captured by
 *      surrounding him on the remaining three sides with attackers."
 *  10. "Elsewhere on the board, the king is captured as other pieces. This
 *      includes beside the corners, where he can be captured between an
 *      attacker and the corner as in rule 7."
 *
 * and three decisions where the source is silent or brief:
 *
 *   - ONLY THE PIECE THAT MOVED CAPTURES. A piece may stand between two
 *     enemies unharmed if neither of them just moved to make it so. The search
 *     therefore goes outward from the square moved to and nowhere else.
 *   - EVERY ENEMY THE MOVE CLOSES ON IS TAKEN, up to three, each judged on the
 *     board as it stands after the move and before anything is removed.
 *   - THE KING CAPTURES like any piece of his side, as the piece that moves or
 *     as the piece that waits.
 */


#include <string.h>
#include "bd_abi.h"

/* bd_engine.c owns the struct; this file reaches it through the same table
 * every other consumer uses, which keeps the two files honest about the
 * interface. */
static const struct bd_abi *E(void) { return bd_abi_table(); }

#define AT(b, sq) ((E())->at((b), (sq)))

/* left, right, down, up: the order the move list is written in */
static const int ORTHO[4] = { -1, 1, -BD_STRIDE, BD_STRIDE };

/* ---- the rule set ------------------------------------------------------------ */

static void bd_variant_default(struct bd_variant *v)
{
    if (!v) return;
    memset(v, 0, sizeof(*v));
    v->throne_pass = 1;
    v->repeat      = BD_REPEAT_DEFAULT;
    v->ply_cap     = BD_PLY_CAP_DEFAULT;
}

static const struct bd_variant *variant_or_default(const struct bd_variant *v)
{
    static struct bd_variant DEFAULT;
    static int ready = 0;
    if (v) return v;
    if (!ready) { bd_variant_default(&DEFAULT); ready = 1; }
    return &DEFAULT;
}

/* ---- a move ------------------------------------------------------------------ */

static int bd_move_make(int from, int to) { return (from & 0x7F) | ((to & 0x7F) << 7); }
static int bd_move_from(int mv)           { return mv & 0x7F; }
static int bd_move_to(int mv)             { return (mv >> 7) & 0x7F; }

/* ---- rule 5: who may STOP where ------------------------------------------------
 *
 * The one place that knows. The square is empty when this is asked.
 */
static int may_land(int piece, int sq, const struct bd_variant *v)
{
    if ((E())->is_throne(sq)) return piece == BD_KING && v->throne_reentry;
    if ((E())->is_corner(sq)) return piece == BD_KING;
    return 1;
}

/* ---- generation ----------------------------------------------------------------
 *
 * A slide walks while the cell is BD_EMPTY. The ring reads BD_BORDER and a
 * piece reads as itself, so both end the walk with no bounds test. An empty
 * throne does not end it unless the rule set says so; it is only refused as a
 * place to stop.
 */
static int bd_gen_moves(const struct bd_board *b, const struct bd_variant *v, int *out, int max)
{
    int side = (E())->side(b);
    int rank, file, d, n = 0;
    v = variant_or_default(v);

    for (rank = 0; rank < BD_SIZE; rank++) {
        for (file = 0; file < BD_SIZE; file++) {
            int from = (E())->square_of(file, rank);
            int piece = AT(b, from);
            if (!BD_IS_PIECE(piece) || (E())->side_of(piece) != side) continue;
            for (d = 0; d < 4; d++) {
                int sq = from + ORTHO[d];
                while (AT(b, sq) == BD_EMPTY) {
                    if (may_land(piece, sq, v)) {
                        if (out && n < max) out[n] = bd_move_make(from, sq);
                        n++;
                    }
                    if ((E())->is_throne(sq) && !v->throne_pass) break;
                    sq += ORTHO[d];
                }
            }
        }
    }
    return n;
}

/* Generation and a search of the list. NOT a second implementation of the
 * rules: why_not below is that, by necessity, and a test holds the two
 * together. */
static int bd_is_legal(const struct bd_board *b, const struct bd_variant *v, int mv)
{
    int list[BD_MOVES_MAX];
    int n = bd_gen_moves(b, v, list, BD_MOVES_MAX), i;
    if (n > BD_MOVES_MAX) n = BD_MOVES_MAX;
    for (i = 0; i < n; i++)
        if (list[i] == mv) return 1;
    return 0;
}

/* The reason a person is shown. It walks the line itself, so that it can say
 * WHAT was wrong and not only that something was. */
static int bd_why_not(const struct bd_board *b, const struct bd_variant *v, int from, int to)
{
    int piece, step, sq, ff, fr, tf, tr;
    v = variant_or_default(v);

    if (!(E())->on_board(from) || !(E())->on_board(to)) return BD_WHY_OFF_BOARD;
    piece = AT(b, from);
    if (!BD_IS_PIECE(piece)) return BD_WHY_NO_PIECE;
    if ((E())->side_of(piece) != (E())->side(b)) return BD_WHY_NOT_YOURS;
    if (from == to) return BD_WHY_NO_MOVE;

    ff = (E())->file_of(from); fr = (E())->rank_of(from);
    tf = (E())->file_of(to);   tr = (E())->rank_of(to);
    if (ff != tf && fr != tr) return BD_WHY_NOT_A_LINE;

    if (fr == tr) step = (tf > ff) ? 1 : -1;
    else          step = (tr > fr) ? BD_STRIDE : -BD_STRIDE;

    for (sq = from + step; sq != to; sq += step) {
        if (AT(b, sq) != BD_EMPTY) return BD_WHY_BLOCKED;
        if ((E())->is_throne(sq) && !v->throne_pass) return BD_WHY_THRONE;
    }
    if (AT(b, to) != BD_EMPTY) return BD_WHY_BLOCKED;
    if (!may_land(piece, to, v))
        return (E())->is_throne(to) ? BD_WHY_THRONE : BD_WHY_CORNER;
    return BD_WHY_OK;
}

/* ---- relocate ------------------------------------------------------------------ */

static void bd_relocate(struct bd_board *b, int mv)
{
    int from = bd_move_from(mv), to = bd_move_to(mv);
    int piece;
    if (!(E())->on_board(from) || !(E())->on_board(to)) return;
    piece = AT(b, from);
    (E())->lift(b, from);
    (E())->put(b, to, piece);
    (E())->set_side(b, BD_OTHER((E())->side(b)));
}

/* ---- perft, slides only --------------------------------------------------------
 *
 * The last ply is counted and not played: the number of leaves under a node
 * one ply from the bottom is the length of its move list.
 *
 * A move is taken back by hand here because nothing is ever captured: put the
 * piece where it was and give the turn back. The key comes back with it, being
 * an xor each way.
 */
static unsigned long long perft_go(struct bd_board *b, const struct bd_variant *v, int depth)
{
    int list[BD_MOVES_MAX];
    int n = bd_gen_moves(b, v, list, BD_MOVES_MAX), i;
    unsigned long long total = 0;

    if (depth <= 1) return (unsigned long long) n;
    if (n > BD_MOVES_MAX) n = BD_MOVES_MAX;
    for (i = 0; i < n; i++) {
        int from = bd_move_from(list[i]), to = bd_move_to(list[i]);
        int piece = AT(b, from);
        int side = (E())->side(b);
        bd_relocate(b, list[i]);
        total += perft_go(b, v, depth - 1);
        (E())->lift(b, to);
        (E())->put(b, from, piece);
        (E())->set_side(b, side);
    }
    return total;
}

static unsigned long long bd_perft_slides(struct bd_board *b, const struct bd_variant *v, int depth)
{
    if (!b) return 0;
    if (depth <= 0) return 1;
    return perft_go(b, variant_or_default(v), depth);
}

/* ---- capture -------------------------------------------------------------------
 *
 * THE ONE PREDICATE. A piece is judged as a piece wherever it stands, the
 * throne and the corners included: the king on his throne is an enemy of the
 * attackers because he is the king, and a friend of the defenders for the same
 * reason. Only an EMPTY marked square is hostile in its own right, and it is
 * hostile to both sides ("A piece may also be captured...").
 *
 * The ring is not hostile. Nothing in the rules captures against the edge, and
 * that is what lets a walk two cells out from the moved piece read the border
 * and carry on.
 */
static int bd_hostile_to(const struct bd_board *b, int sq, int side)
{
    int cell = AT(b, sq);
    if (BD_IS_PIECE(cell)) return (E())->side_of(cell) != side;
    if (cell != BD_EMPTY) return 0;
    if ((E())->is_corner(sq)) return 1;
    if ((E())->is_throne(sq)) return 1;
    return 0;
}

/* The king stands on `king` and an attacker has just arrived at king - step.
 * Three places, and three rules.
 *
 * On the throne and beside it the king is judged on his whole neighbourhood
 * and not on the line through the piece that moved. That piece is one of the
 * neighbours by construction, so the mover is still what closes the capture.
 */
static int king_falls(const struct bd_board *b, const struct bd_variant *v, int king, int step)
{
    int d;

    if (v->king_everywhere_two)
        return bd_hostile_to(b, king + step, BD_DEFENDERS);

    if (v->king_strong) {
        /* every side closed: by an attacker or by the empty throne. The edge
         * closes nothing, so a king on it cannot be taken; and since every
         * square next to a corner is on the edge, a corner never gets to
         * count and is not asked about. */
        for (d = 0; d < 4; d++) {
            int sq = king + ORTHO[d];
            int cell = AT(b, sq);
            if (cell == BD_ATTACKER) continue;
            if (cell == BD_EMPTY && (E())->is_throne(sq)) continue;
            return 0;
        }
        return 1;
    }

    if ((E())->is_throne(king)) {
        for (d = 0; d < 4; d++)
            if (AT(b, king + ORTHO[d]) != BD_ATTACKER) return 0;
        return 1;
    }

    if ((E())->beside_throne(king)) {
        /* "the remaining three sides": the fourth is the throne. In play it is
         * empty, the king being the only piece that ever stands there. A
         * DEFENDER on it, which only a hand-built board has, is a friend at
         * his side and he is not surrounded. */
        for (d = 0; d < 4; d++) {
            int sq = king + ORTHO[d];
            int cell = AT(b, sq);
            if ((E())->is_throne(sq)) {
                if (BD_IS_PIECE(cell) && (E())->side_of(cell) == BD_DEFENDERS) return 0;
            }
            else if (cell != BD_ATTACKER) return 0;
        }
        return 1;
    }

    return bd_hostile_to(b, king + step, BD_DEFENDERS);
}

static int bd_captures_at(const struct bd_board *b, const struct bd_variant *v, int to, int *out)
{
    int mover = AT(b, to);
    int side, d, n = 0;
    v = variant_or_default(v);
    if (!BD_IS_PIECE(mover)) return 0;
    side = (E())->side_of(mover);

    for (d = 0; d < 4; d++) {
        int sq = to + ORTHO[d];
        int victim = AT(b, sq);
        int taken;
        if (!BD_IS_PIECE(victim) || (E())->side_of(victim) == side) continue;
        if (victim == BD_KING) taken = king_falls(b, v, sq, ORTHO[d]);
        else                   taken = bd_hostile_to(b, sq + ORTHO[d], (E())->side_of(victim));
        if (taken) {
            if (out) out[n] = sq;
            n++;
        }
    }
    return n;
}

static int on_edge(int sq)
{
    int f = (E())->file_of(sq), r = (E())->rank_of(sq);
    return f == 0 || r == 0 || f == BD_SIZE - 1 || r == BD_SIZE - 1;
}

/* COLLECT, THEN REMOVE. Every capture is decided on the board as it stands
 * after the move and before any piece leaves it, so the order they leave in
 * cannot matter. A test removes them in every order to show that it does not.
 */
static int bd_do_move(struct bd_board *b, const struct bd_variant *v, int mv, struct bd_undo *u)
{
    int from = bd_move_from(mv), to = bd_move_to(mv);
    int taken[BD_CAPTURES_MAX];
    int piece, n, i, flags = 0;
    v = variant_or_default(v);

    if (u) {
        memset(u, 0, sizeof(*u));
        u->side = (E())->side(b);
        u->key  = (E())->key(b);
    }
    if (!(E())->on_board(from) || !(E())->on_board(to)) return 0;
    piece = AT(b, from);
    if (!BD_IS_PIECE(piece) || AT(b, to) != BD_EMPTY) return 0;

    (E())->lift(b, from);
    (E())->put(b, to, piece);

    n = bd_captures_at(b, v, to, taken);
    for (i = 0; i < n; i++) {
        int gone = AT(b, taken[i]);
        if (gone == BD_KING) flags |= BD_KING_TAKEN;
        if (u) { u->square[i] = taken[i]; u->piece[i] = gone; }
    }
    for (i = 0; i < n; i++) (E())->lift(b, taken[i]);
    if (n) flags |= BD_DID_CAPTURE;

    if (piece == BD_KING && ((E())->is_corner(to) || (v->escape_edge && on_edge(to))))
        flags |= BD_KING_HOME;

    (E())->set_side(b, BD_OTHER((E())->side(b)));

    if (u) { u->mv = mv; u->flags = flags; u->n = n; }
    return flags;
}

/* Puts every piece back and the turn with it. The key returns by the same
 * xors that moved it, and a test holds it to the key that was saved. */
static void bd_undo_move(struct bd_board *b, const struct bd_undo *u)
{
    int from, to, piece, i;
    if (!u || u->mv == 0) return;
    from = bd_move_from(u->mv);
    to = bd_move_to(u->mv);
    piece = AT(b, to);
    (E())->lift(b, to);
    (E())->put(b, from, piece);
    for (i = 0; i < u->n && i < BD_CAPTURES_MAX; i++)
        (E())->put(b, u->square[i], u->piece[i]);
    (E())->set_side(b, u->side);
}

/* do_move on a copy, so that the board asked about is never touched, not even
 * for the length of the call. */
static int bd_preview(const struct bd_board *b, const struct bd_variant *v, int mv, int *out, int *flags)
{
    struct bd_board *c = (E())->board_copy(b);
    struct bd_undo u;
    int i, n;
    if (flags) *flags = 0;
    if (!c) return 0;
    bd_do_move(c, v, mv, &u);
    (E())->board_drop(c);
    n = u.n;
    for (i = 0; i < n && out; i++) out[i] = u.square[i];
    if (flags) *flags = u.flags;
    return n;
}

/* ---- perft, with captures -------------------------------------------------------
 *
 * The same shape as perft_slides: the last ply is counted and not played.
 * NOTHING ENDS THE WALK. A king may be taken and the count goes on through
 * what his side has left, which is what the reference implementation it is
 * compared with does too.
 */
static unsigned long long perft_full(struct bd_board *b, const struct bd_variant *v, int depth)
{
    int list[BD_MOVES_MAX];
    int n = bd_gen_moves(b, v, list, BD_MOVES_MAX), i;
    unsigned long long total = 0;

    if (depth <= 1) return (unsigned long long) n;
    if (n > BD_MOVES_MAX) n = BD_MOVES_MAX;
    for (i = 0; i < n; i++) {
        struct bd_undo u;
        bd_do_move(b, v, list[i], &u);
        total += perft_full(b, v, depth - 1);
        bd_undo_move(b, &u);
    }
    return total;
}

static unsigned long long bd_perft(struct bd_board *b, const struct bd_variant *v, int depth)
{
    if (!b) return 0;
    if (depth <= 0) return 1;
    return perft_full(b, variant_or_default(v), depth);
}

/* ---- installed into the table by bd_engine.c ---------------------------------- */

void bd_moves_install(struct bd_abi *t);

void bd_moves_install(struct bd_abi *t)
{
    t->variant_default = bd_variant_default;
    t->move_make       = bd_move_make;
    t->move_from       = bd_move_from;
    t->move_to         = bd_move_to;
    t->gen_moves       = bd_gen_moves;
    t->is_legal        = bd_is_legal;
    t->why_not         = bd_why_not;
    t->relocate        = bd_relocate;
    t->perft_slides    = bd_perft_slides;

    t->hostile_to      = bd_hostile_to;
    t->captures_at     = bd_captures_at;
    t->do_move         = bd_do_move;
    t->undo_move       = bd_undo_move;
    t->preview         = bd_preview;
    t->perft           = bd_perft;
}
