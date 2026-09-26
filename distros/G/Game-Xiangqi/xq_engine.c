/* xq_engine.c - the xiangqi board, and nothing that judges a move.
 *
 * PERL-FREE by design: see include/xq_abi.h. This file compiles into the XS,
 * into a plain program, or to wasm, and knows nothing about any of them.
 *
 * PHASE 02 SCOPE. The board, the padded index, put and lift, do and undo, the
 * zobrist key, and FEN in and out. No move generation, no legality, no check.
 * Those are phases 03 and 04 and they append to the table.
 */

#include <stdlib.h>
#include <string.h>
#include "xq_abi.h"

/* ---- the position ---------------------------------------------------------
 *
 * A flat 132-cell array with a sentinel ring, the side to move, and a key
 * maintained incrementally. No pointers, so a copy is a struct assignment and
 * two boards never share anything.
 */

struct xq_board {
    unsigned char cell[XQ_CELLS];
    int side;
    unsigned long long key;
};

/* ---- the zobrist table -----------------------------------------------------
 *
 * DERIVED, NOT COMMITTED, and the difference is worth a paragraph because the
 * plan asked for a committed table of constants.
 *
 * What the requirement actually is: two workers in a pool must agree about
 * whether a position has been seen, so the table must not come from rand() or
 * from anything that varies per process. A fixed function of a fixed seed
 * satisfies that exactly as a committed array does, in four lines instead of
 * four thousand, and it cannot suffer the transcription error a hand-pasted
 * array can. splitmix64 is used rather than a hand-rolled mixer because it is
 * published, has no weak seeds, and passes the usual test batteries.
 *
 * The consequence to keep in mind: CHANGING THIS GENERATOR CHANGES EVERY KEY.
 * Nothing persists a key across versions today, and if anything ever does, this
 * is the line that breaks it. t/03-key.t pins four values so the change is
 * caught by a red test rather than by a silent disagreement between a stored
 * key and a live one.
 */

static unsigned long long ZOB[XQ_BORDER + 1][XQ_CELLS];
static unsigned long long ZOB_SIDE;
static int ZOB_READY = 0;

static unsigned long long splitmix64(unsigned long long *state)
{
    unsigned long long z;
    *state += 0x9E3779B97F4A7C15ULL;
    z = *state;
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

static void zob_init(void)
{
    unsigned long long s = 0x7869616E67716921ULL;   /* "xiangqi!" */
    int p, c;
    if (ZOB_READY) return;
    for (p = 0; p <= XQ_BORDER; p++)
        for (c = 0; c < XQ_CELLS; c++)
            ZOB[p][c] = splitmix64(&s);
    ZOB_SIDE = splitmix64(&s);
    ZOB_READY = 1;
}

/* The key covers the pieces, their points, and the side to move, and NOTHING
 * else. There is no castling, no en passant and no halfmove clock in this game,
 * so a position repeating is a position repeating, which is what phase 06's
 * loop detector needs it to mean. */
static unsigned long long zob_of(int piece, int pt)
{
    zob_init();
    if (piece <= 0 || piece > XQ_BORDER) return 0;
    if (pt < 0 || pt >= XQ_CELLS) return 0;
    return ZOB[piece][pt];
}

/* ---- geometry -------------------------------------------------------------- */

static int xq_stride(void) { return XQ_STRIDE; }

static int xq_point_of(int file, int rank)
{
    if (file < 0 || file >= XQ_FILES || rank < 0 || rank >= XQ_RANKS) return -1;
    return (rank + 1) * XQ_STRIDE + (file + 1);
}

static int xq_on_board(int pt)
{
    int f, r;
    if (pt < 0 || pt >= XQ_CELLS) return 0;
    f = pt % XQ_STRIDE;
    r = pt / XQ_STRIDE;
    return f >= 1 && f <= XQ_FILES && r >= 1 && r <= XQ_RANKS;
}

static int xq_file_of(int pt)
{
    if (!xq_on_board(pt)) return -1;
    return (pt % XQ_STRIDE) - 1;
}

static int xq_rank_of(int pt)
{
    if (!xq_on_board(pt)) return -1;
    return (pt / XQ_STRIDE) - 1;
}

/* The palace is files d to f and the three ranks at that side's own end. Nine
 * points each, and the general and the advisor never leave them. */
static int xq_in_palace(int pt, int colour)
{
    int f = xq_file_of(pt), r = xq_rank_of(pt);
    if (f < 3 || f > 5) return 0;
    if (colour == XQ_RED)   return r >= 0 && r <= 2;
    if (colour == XQ_BLACK) return r >= 7 && r <= 9;
    return 0;
}

/* Red advances up the ranks and Black down them, so "across the river" is rank
 * 5 or more for Red and rank 4 or less for Black. Forty-five points each. */
static int xq_crossed_river(int pt, int colour)
{
    int r = xq_rank_of(pt);
    if (r < 0) return 0;
    if (colour == XQ_RED)   return r >= 5;
    if (colour == XQ_BLACK) return r <= 4;
    return 0;
}

/* ---- the board ------------------------------------------------------------- */

static void board_blank(struct xq_board *b)
{
    int f, r;
    memset(b, 0, sizeof(*b));
    memset(b->cell, XQ_BORDER, sizeof(b->cell));
    for (r = 0; r < XQ_RANKS; r++)
        for (f = 0; f < XQ_FILES; f++)
            b->cell[xq_point_of(f, r)] = XQ_EMPTY;
    b->side = XQ_RED;
    b->key = 0;
}

static struct xq_board *xq_board_empty(void)
{
    struct xq_board *b;
    zob_init();
    b = (struct xq_board *) malloc(sizeof(struct xq_board));
    if (!b) return NULL;
    board_blank(b);
    return b;
}

/* put and lift MAINTAIN THE KEY and judge nothing else. A caller may stack
 * three generals on three points or leave a side without one; that is what the
 * structure primitives are for and it is how a test builds a position. */
static void xq_put(struct xq_board *b, int pt, int piece)
{
    int old;
    if (!xq_on_board(pt)) return;
    old = b->cell[pt];
    if (old != XQ_EMPTY) b->key ^= zob_of(old, pt);
    b->cell[pt] = (unsigned char) piece;
    if (piece != XQ_EMPTY) b->key ^= zob_of(piece, pt);
}

static void xq_lift(struct xq_board *b, int pt)
{
    xq_put(b, pt, XQ_EMPTY);
}

static int xq_at(const struct xq_board *b, int pt)
{
    if (pt < 0 || pt >= XQ_CELLS) return XQ_BORDER;
    return b->cell[pt];
}

static int xq_side(const struct xq_board *b) { return b->side; }

static void xq_set_side(struct xq_board *b, int colour)
{
    if (colour != XQ_RED && colour != XQ_BLACK) return;
    if (b->side == colour) return;
    b->side = colour;
    b->key ^= ZOB_SIDE;
}

static int xq_count(const struct xq_board *b, int piece)
{
    int pt, n = 0;
    for (pt = 0; pt < XQ_CELLS; pt++)
        if (b->cell[pt] == piece && xq_on_board(pt)) n++;
    return n;
}

static int xq_find(const struct xq_board *b, int piece)
{
    int pt;
    for (pt = 0; pt < XQ_CELLS; pt++)
        if (b->cell[pt] == piece && xq_on_board(pt)) return pt;
    return 0;
}

/* The opening position, from the Asian Rules chapter 1 section 1. Rank 0 is
 * Red's back rank. */
static const int BACK[XQ_FILES] = {
    XQ_CHARIOT, XQ_HORSE, XQ_ELEPHANT, XQ_ADVISOR, XQ_GENERAL,
    XQ_ADVISOR, XQ_ELEPHANT, XQ_HORSE, XQ_CHARIOT
};

static struct xq_board *xq_board_new(void)
{
    struct xq_board *b = xq_board_empty();
    int f;
    if (!b) return NULL;
    for (f = 0; f < XQ_FILES; f++) {
        xq_put(b, xq_point_of(f, 0), (int) (XQ_RED   | BACK[f]));
        xq_put(b, xq_point_of(f, 9), (int) (XQ_BLACK | BACK[f]));
    }
    xq_put(b, xq_point_of(1, 2), XQ_RED   | XQ_CANNON);
    xq_put(b, xq_point_of(7, 2), XQ_RED   | XQ_CANNON);
    xq_put(b, xq_point_of(1, 7), XQ_BLACK | XQ_CANNON);
    xq_put(b, xq_point_of(7, 7), XQ_BLACK | XQ_CANNON);
    for (f = 0; f < XQ_FILES; f += 2) {
        xq_put(b, xq_point_of(f, 3), XQ_RED   | XQ_SOLDIER);
        xq_put(b, xq_point_of(f, 6), XQ_BLACK | XQ_SOLDIER);
    }
    return b;
}

static struct xq_board *xq_board_copy(const struct xq_board *b)
{
    struct xq_board *n = (struct xq_board *) malloc(sizeof(struct xq_board));
    if (!n) return NULL;
    *n = *b;
    return n;
}

static void xq_board_drop(struct xq_board *b) { free(b); }

/* ---- moves ------------------------------------------------------------------
 *
 * from and to each fit in eight bits (a point is 0 to 131), so a move is packed
 * into sixteen and the upper bits are left for the flags phases 03 and beyond
 * will want. Nothing outside the header unpacks one by hand.
 */

static int xq_move_make(int from, int to) { return (from & 0xFF) | ((to & 0xFF) << 8); }
static int xq_move_from(int mv)           { return mv & 0xFF; }
static int xq_move_to(int mv)             { return (mv >> 8) & 0xFF; }

/* NOT A RULES CALL. It moves whatever is on `from` to `to`, captures whatever
 * was there, flips the side and maintains the key. Whether the move was legal
 * is phase 03's question and this function never asks it. */
static int xq_do_move(struct xq_board *b, int mv, struct xq_undo *u)
{
    int from = xq_move_from(mv), to = xq_move_to(mv);
    int piece, captured;

    if (!xq_on_board(from) || !xq_on_board(to)) {
        if (u) { u->mv = 0; u->captured = XQ_EMPTY; u->side = b->side; u->key = b->key; }
        return XQ_EMPTY;
    }
    piece = b->cell[from];
    captured = b->cell[to];

    if (u) {
        u->mv = mv;
        u->captured = captured;
        u->side = b->side;
        u->key = b->key;
    }
    xq_lift(b, from);
    xq_put(b, to, piece);
    xq_set_side(b, XQ_OTHER(b->side));
    return captured;
}

/* Restores the position EXACTLY, key included, by putting the key back rather
 * than by xor-ing the same values again. The two are equal when nothing else
 * touched the board, and only one of them stays true if anything did. */
static void xq_undo_move(struct xq_board *b, const struct xq_undo *u)
{
    int from, to;
    if (!u || u->mv == 0) return;
    from = xq_move_from(u->mv);
    to = xq_move_to(u->mv);
    b->cell[from] = b->cell[to];
    b->cell[to] = (unsigned char) u->captured;
    b->side = u->side;
    b->key = u->key;
}

static unsigned long long xq_key(const struct xq_board *b) { return b->key; }

/* ---- FEN --------------------------------------------------------------------
 *
 * THE READER TAKES BOTH LETTER CONVENTIONS AND THE WRITER EMITS h/e.
 *
 * The same opening position is published both ways by the same author: the
 * Chess Programming Wiki's Chinese Chess perft page spells the horse h and the
 * elephant e, and Maksim Korzh's TalkChess post of the same table spells them n
 * and b after chess's knight and bishop. A reader that takes one convention
 * cannot load half the oracles there are, and the failure is the bad kind: the
 * position does not parse, the test skips, and the suite is green.
 */

static int letter_piece(char c)
{
    int colour = (c >= 'a' && c <= 'z') ? XQ_BLACK : XQ_RED;
    char u = (c >= 'a' && c <= 'z') ? (char) (c - 'a' + 'A') : c;
    switch (u) {
        case 'K': return colour | XQ_GENERAL;
        case 'A': return colour | XQ_ADVISOR;
        case 'E': case 'B': return colour | XQ_ELEPHANT;
        case 'R': return colour | XQ_CHARIOT;
        case 'H': case 'N': return colour | XQ_HORSE;
        case 'C': return colour | XQ_CANNON;
        case 'P': return colour | XQ_SOLDIER;
        default: return -1;
    }
}

static char piece_letter(int piece)
{
    static const char up[8] = { '.', 'K', 'A', 'E', 'R', 'H', 'C', 'P' };
    char c = up[XQ_KIND(piece)];
    if (XQ_COLOUR(piece) == XQ_BLACK) c = (char) (c - 'A' + 'a');
    return c;
}

static struct xq_board *xq_board_of_fen(const char *fen, int *err)
{
    struct xq_board *b;
    int rank = XQ_RANKS - 1, file = 0;
    const char *s = fen;
    size_t n;

    if (err) *err = XQ_OK;
    if (!fen) { if (err) *err = XQ_FEN_NULL; return NULL; }
    n = strlen(fen);
    if (n == 0) { if (err) *err = XQ_FEN_NULL; return NULL; }
    if (n >= XQ_FEN_MAX) { if (err) *err = XQ_FEN_LONG; return NULL; }

    b = xq_board_empty();
    if (!b) { if (err) *err = XQ_FEN_NULL; return NULL; }

    for (; *s && *s != ' '; s++) {
        if (*s == '/') {
            if (file != XQ_FILES) { if (err) *err = XQ_FEN_WIDTH; xq_board_drop(b); return NULL; }
            if (rank == 0)        { if (err) *err = XQ_FEN_ROWS;  xq_board_drop(b); return NULL; }
            rank--; file = 0;
            continue;
        }
        if (*s >= '1' && *s <= '9') {
            file += *s - '0';
            if (file > XQ_FILES) { if (err) *err = XQ_FEN_WIDTH; xq_board_drop(b); return NULL; }
            continue;
        }
        {
            int piece = letter_piece(*s);
            if (piece < 0)        { if (err) *err = XQ_FEN_LETTER; xq_board_drop(b); return NULL; }
            if (file >= XQ_FILES) { if (err) *err = XQ_FEN_WIDTH;  xq_board_drop(b); return NULL; }
            xq_put(b, xq_point_of(file, rank), piece);
            file++;
        }
    }
    if (rank != 0 || file != XQ_FILES) {
        if (err) *err = (rank != 0) ? XQ_FEN_ROWS : XQ_FEN_WIDTH;
        xq_board_drop(b);
        return NULL;
    }

    /* the side field. w and r both mean Red: the perft sources write w, and
     * much of the xiangqi world writes r. Anything else is a refusal rather
     * than a silent default, because defaulting here would make a typo into a
     * position with the wrong player to move, which is a different position. */
    while (*s == ' ') s++;
    if (*s) {
        if (*s == 'w' || *s == 'W' || *s == 'r' || *s == 'R') xq_set_side(b, XQ_RED);
        else if (*s == 'b' || *s == 'B')                      xq_set_side(b, XQ_BLACK);
        else { if (err) *err = XQ_FEN_SIDE; xq_board_drop(b); return NULL; }
    }
    /* every field after the side is ignored: this game has no castling, no en
     * passant, and the two clocks are the caller's business */
    return b;
}

static int xq_to_fen(const struct xq_board *b, char *buf, int len)
{
    int rank, file, i = 0, run;
    if (!buf || len < XQ_FEN_MAX) return -1;
    for (rank = XQ_RANKS - 1; rank >= 0; rank--) {
        run = 0;
        for (file = 0; file < XQ_FILES; file++) {
            int piece = b->cell[xq_point_of(file, rank)];
            if (piece == XQ_EMPTY) { run++; continue; }
            if (run) { buf[i++] = (char) ('0' + run); run = 0; }
            buf[i++] = piece_letter(piece);
        }
        if (run) buf[i++] = (char) ('0' + run);
        if (rank) buf[i++] = '/';
    }
    buf[i++] = ' ';
    buf[i++] = (b->side == XQ_BLACK) ? 'b' : 'w';
    buf[i++] = ' '; buf[i++] = '-';
    buf[i++] = ' '; buf[i++] = '-';
    buf[i++] = ' '; buf[i++] = '0';
    buf[i++] = ' '; buf[i++] = '1';
    buf[i] = '\0';
    return i;
}

/* ---- the table -------------------------------------------------------------- */

static struct xq_abi XQ_TABLE;
static int XQ_TABLE_READY = 0;

/* Phase 03 lives in xq_moves.c and installs itself into the table here.
 *
 * The two files call into each other and it terminates: xq_abi_table sets
 * XQ_TABLE_READY before calling the installer, and xq_moves.c only ever reaches
 * xq_abi_table from inside a function the installer has already been handed.
 * Game::Go's search does the same dance and its comment says the same thing. */
void xq_moves_install(struct xq_abi *t);
void xq_mate_install(struct xq_abi *t);
void xq_judge_install(struct xq_abi *t);
void xq_judge2_install(struct xq_abi *t);
void xq_search_install(struct xq_abi *t);

const struct xq_abi *xq_abi_table(void)
{
    if (!XQ_TABLE_READY) {
        zob_init();
        XQ_TABLE.abi_version = XQ_ABI_VERSION;

        XQ_TABLE.board_new    = xq_board_new;
        XQ_TABLE.board_empty  = xq_board_empty;
        XQ_TABLE.board_of_fen = xq_board_of_fen;
        XQ_TABLE.board_copy   = xq_board_copy;
        XQ_TABLE.board_drop   = xq_board_drop;

        XQ_TABLE.at       = xq_at;
        XQ_TABLE.put      = xq_put;
        XQ_TABLE.lift     = xq_lift;
        XQ_TABLE.side     = xq_side;
        XQ_TABLE.set_side = xq_set_side;
        XQ_TABLE.count    = xq_count;
        XQ_TABLE.find     = xq_find;

        XQ_TABLE.move_make = xq_move_make;
        XQ_TABLE.move_from = xq_move_from;
        XQ_TABLE.move_to   = xq_move_to;
        XQ_TABLE.do_move   = xq_do_move;
        XQ_TABLE.undo_move = xq_undo_move;

        XQ_TABLE.key     = xq_key;
        XQ_TABLE.to_fen  = xq_to_fen;
        XQ_TABLE.zobrist = zob_of;

        XQ_TABLE.point_of      = xq_point_of;
        XQ_TABLE.file_of       = xq_file_of;
        XQ_TABLE.rank_of       = xq_rank_of;
        XQ_TABLE.on_board      = xq_on_board;
        XQ_TABLE.in_palace     = xq_in_palace;
        XQ_TABLE.crossed_river = xq_crossed_river;
        XQ_TABLE.stride        = xq_stride;

        XQ_TABLE_READY = 1;      /* before the installer, or it recurses */
        xq_moves_install(&XQ_TABLE);
        xq_mate_install(&XQ_TABLE);
        xq_judge_install(&XQ_TABLE);
        xq_judge2_install(&XQ_TABLE);
        xq_search_install(&XQ_TABLE);
    }
    return &XQ_TABLE;
}
