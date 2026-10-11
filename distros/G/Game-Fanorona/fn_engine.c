/* fn_engine.c - the fanorona board, and nothing that judges a move.
 *
 * PERL-FREE by design: see include/fn_abi.h. This file compiles into the XS,
 * into a plain program, or to wasm, and knows nothing about any of them.
 *
 * THIS FILE'S SCOPE. The grid, the padded index, the lines, put and lift, the
 * side to move, the zobrist key, the position string in and out, and the three
 * fields of the chain as plain state.
 */

#include <stdlib.h>
#include <string.h>
#include "fn_abi.h"

/* ---- the position ---------------------------------------------------------
 *
 * A flat 77-cell array, the size of the board inside it, the side to move, the
 * stones of each colour, and a key maintained incrementally. No pointers, so a
 * copy is a struct assignment and two boards never share anything.
 */

struct fn_board {
    unsigned char cell[FN_CELLS];
    int cols;
    int rows;
    int side;
    int stones[FN_BLACK + 1];
    unsigned long long key;
    int chain_at;                       /* -1 when no chain is open */
    int chain_dir;
    unsigned long long chain_seen;      /* a bit a point, by point_bit */
};

/* Boards handed out and not yet dropped. It exists so a test can show that a
 * destructor ran exactly once; it is a plain int and is not synchronised. */
static int FN_LIVE = 0;

/* ---- the zobrist table -----------------------------------------------------
 *
 * DERIVED, NOT COMMITTED. A fixed function of a fixed seed is the same in every
 * process and on every machine, and cannot suffer the transcription error a
 * hand-pasted array can. splitmix64 is published and has no weak seeds.
 *
 * CHANGING THIS GENERATOR, ITS SEED OR THE ORDER THE TABLE IS FILLED IN
 * CHANGES EVERY KEY. t/02-position.t pins values so that is a red test.
 */

static unsigned long long ZOB[FN_BLACK + 1][FN_CELLS];
static unsigned long long ZOB_SIDE;
static unsigned long long ZOB_SIZE[FN_COLS_MAX + 1][FN_ROWS_MAX + 1];
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
    unsigned long long s = 0x66616E6F726F6E61ULL;   /* "fanorona" */
    int p, c, r;
    if (ZOB_READY) return;
    for (p = 0; p <= FN_BLACK; p++)
        for (c = 0; c < FN_CELLS; c++)
            ZOB[p][c] = splitmix64(&s);
    ZOB_SIDE = splitmix64(&s);
    for (c = 0; c <= FN_COLS_MAX; c++)
        for (r = 0; r <= FN_ROWS_MAX; r++)
            ZOB_SIZE[c][r] = splitmix64(&s);
    ZOB_READY = 1;
}

/* ---- geometry that does not depend on the size ------------------------------ */

static int fn_stride(void) { return FN_STRIDE; }

/* Odd widths 3 to 9, heights 3 and 5. An even side has no centre point. */
static int fn_size_ok(int cols, int rows)
{
    if (cols < 3 || cols > FN_COLS_MAX || cols % 2 == 0) return 0;
    if (rows != 3 && rows != 5) return 0;
    return 1;
}

static int fn_square_of(int file, int rank)
{
    if (file < 0 || file >= FN_COLS_MAX || rank < 0 || rank >= FN_ROWS_MAX) return -1;
    return (rank + 1) * FN_STRIDE + (file + 1);
}

static int in_grid(int sq)
{
    int f, r;
    if (sq < 0 || sq >= FN_CELLS) return 0;
    f = sq % FN_STRIDE;
    r = sq / FN_STRIDE;
    return f >= 1 && f <= FN_COLS_MAX && r >= 1 && r <= FN_ROWS_MAX;
}

static int fn_file_of(int sq)
{
    if (!in_grid(sq)) return -1;
    return (sq % FN_STRIDE) - 1;
}

static int fn_rank_of(int sq)
{
    if (!in_grid(sq)) return -1;
    return (sq / FN_STRIDE) - 1;
}

/* A STRONG POINT HAS DIAGONALS, and this is the one place that says which. */
static int fn_is_strong(int sq)
{
    if (!in_grid(sq)) return 0;
    return (fn_file_of(sq) + fn_rank_of(sq)) % 2 == 0;
}

static const int DIR_OFFSET[FN_DIRS] = {
    FN_STRIDE, FN_STRIDE + 1, 1, -FN_STRIDE + 1,
    -FN_STRIDE, -FN_STRIDE - 1, -1, FN_STRIDE - 1
};

static int fn_dir_opposite(int dir)
{
    if (dir < 0 || dir >= FN_DIRS) return -1;
    return (dir + 4) % FN_DIRS;
}

static int fn_dir_is_diagonal(int dir)
{
    if (dir < 0 || dir >= FN_DIRS) return 0;
    return dir % 2 == 1;
}

/* ---- the size of one board ---------------------------------------------------- */

static int fn_cols(const struct fn_board *b)   { return b->cols; }
static int fn_rows(const struct fn_board *b)   { return b->rows; }
static int fn_points(const struct fn_board *b) { return b->cols * b->rows; }

static int fn_centre(const struct fn_board *b)
{
    return fn_square_of(b->cols / 2, b->rows / 2);
}

static int fn_on_board(const struct fn_board *b, int sq)
{
    if (!in_grid(sq)) return 0;
    return fn_file_of(sq) < b->cols && fn_rank_of(sq) < b->rows;
}

/* ---- the lines ---------------------------------------------------------------- */

static int fn_next(const struct fn_board *b, int sq, int dir)
{
    int to;
    if (dir < 0 || dir >= FN_DIRS) return -1;
    if (!fn_on_board(b, sq)) return -1;
    if (fn_dir_is_diagonal(dir) && !fn_is_strong(sq)) return -1;
    to = sq + DIR_OFFSET[dir];
    return fn_on_board(b, to) ? to : -1;
}

static int fn_degree(const struct fn_board *b, int sq)
{
    int d, n = 0;
    for (d = 0; d < FN_DIRS; d++)
        if (fn_next(b, sq, d) >= 0) n++;
    return n;
}

/* Each segment is found from its LOWER end, which is the end the four
 * directions N, NE, E and NW climb or advance away from. SE is left out
 * because a diagonal that descends is found from its other end as NW. */
static int fn_segments(const struct fn_board *b, int *out, int max)
{
    static const int forward[4] = { FN_N, FN_NE, FN_E, FN_NW };
    int rank, file, i, n = 0;
    for (rank = 0; rank < b->rows; rank++) {
        for (file = 0; file < b->cols; file++) {
            int sq = fn_square_of(file, rank);
            for (i = 0; i < 4; i++) {
                int to = fn_next(b, sq, forward[i]);
                if (to < 0) continue;
                if (out && n < max) {
                    out[2 * n]     = sq < to ? sq : to;
                    out[2 * n + 1] = sq < to ? to : sq;
                }
                n++;
            }
        }
    }
    return n;
}

/* ---- the key ----------------------------------------------------------------
 *
 * The key covers the size of the board, the stones, their points, and the side
 * to move, and NOTHING else, so a position repeating is a position repeating.
 */

static unsigned long long fn_zobrist(int stone, int sq)
{
    zob_init();
    if (!FN_IS_STONE(stone)) return 0;
    if (!in_grid(sq)) return 0;
    return ZOB[stone][sq];
}

static unsigned long long fn_zobrist_side(void)
{
    zob_init();
    return ZOB_SIDE;
}

static unsigned long long fn_zobrist_size(int cols, int rows)
{
    zob_init();
    if (!fn_size_ok(cols, rows)) return 0;
    return ZOB_SIZE[cols][rows];
}

/* ---- structure, judging nothing ------------------------------------------------ */

static struct fn_board *fn_board_empty(int cols, int rows)
{
    struct fn_board *b;
    int rank, file;
    if (!fn_size_ok(cols, rows)) return NULL;
    b = (struct fn_board *) malloc(sizeof(struct fn_board));
    if (!b) return NULL;
    memset(b, 0, sizeof(struct fn_board));
    memset(b->cell, FN_BORDER, sizeof(b->cell));
    b->cols = cols;
    b->rows = rows;
    for (rank = 0; rank < rows; rank++)
        for (file = 0; file < cols; file++)
            b->cell[fn_square_of(file, rank)] = FN_EMPTY;
    b->side = FN_WHITE;
    b->key = fn_zobrist_size(cols, rows);
    b->chain_at = -1;
    b->chain_dir = -1;
    FN_LIVE++;
    return b;
}

static void fn_put(struct fn_board *b, int sq, int stone)
{
    int old;
    if (!fn_on_board(b, sq)) return;
    if (stone != FN_EMPTY && !FN_IS_STONE(stone)) return;
    old = b->cell[sq];
    if (old != FN_EMPTY) {
        b->key ^= fn_zobrist(old, sq);
        b->stones[old]--;
    }
    b->cell[sq] = (unsigned char) stone;
    if (stone != FN_EMPTY) {
        b->key ^= fn_zobrist(stone, sq);
        b->stones[stone]++;
    }
}

static void fn_lift(struct fn_board *b, int sq)
{
    fn_put(b, sq, FN_EMPTY);
}

static int fn_at(const struct fn_board *b, int sq)
{
    if (!fn_on_board(b, sq)) return FN_BORDER;
    return b->cell[sq];
}

static int fn_side(const struct fn_board *b) { return b->side; }

static void fn_set_side(struct fn_board *b, int side)
{
    if (!FN_IS_STONE(side)) return;
    if (side == b->side) return;
    b->side = side;
    b->key ^= fn_zobrist_side();
}

static int fn_count(const struct fn_board *b, int stone)
{
    if (!FN_IS_STONE(stone)) return 0;
    return b->stones[stone];
}

static unsigned long long fn_key(const struct fn_board *b) { return b->key; }

/* The key from nothing. A test holds the maintained key to it after every
 * kind of change, which is the only way a missed update shows. */
static unsigned long long fn_key_full(const struct fn_board *b)
{
    unsigned long long k = fn_zobrist_size(b->cols, b->rows);
    int rank, file;
    for (rank = 0; rank < b->rows; rank++) {
        for (file = 0; file < b->cols; file++) {
            int sq = fn_square_of(file, rank);
            int p = b->cell[sq];
            if (p != FN_EMPTY) k ^= fn_zobrist(p, sq);
        }
    }
    if (b->side == FN_BLACK) k ^= fn_zobrist_side();
    return k;
}

/* ---- the chain ------------------------------------------------------------------
 *
 * Which stone is in the middle of its move, the way it last went, and where it
 * has stood. THE KEY DOES NOT COVER IT: a position is compared between moves,
 * and between moves there is no chain. The rules that read it are fn_moves.c's;
 * here it is three fields set together.
 */

static int fn_point_bit(int sq)
{
    if (!in_grid(sq)) return -1;
    return fn_rank_of(sq) * FN_COLS_MAX + fn_file_of(sq);
}

static int fn_chain_at(const struct fn_board *b)  { return b->chain_at; }
static int fn_chain_dir(const struct fn_board *b) { return b->chain_at < 0 ? -1 : b->chain_dir; }

static unsigned long long fn_chain_mask(const struct fn_board *b)
{
    return b->chain_at < 0 ? 0 : b->chain_seen;
}

static int fn_chain_seen(const struct fn_board *b, int sq)
{
    int bit = fn_point_bit(sq);
    if (bit < 0 || b->chain_at < 0) return 0;
    return (int) ((b->chain_seen >> bit) & 1ULL);
}

static void fn_chain_set(struct fn_board *b, int at, int dir, unsigned long long mask)
{
    if (at < 0 || !fn_on_board(b, at)) {
        b->chain_at = -1;
        b->chain_dir = -1;
        b->chain_seen = 0;
        return;
    }
    b->chain_at = at;
    b->chain_dir = (dir >= 0 && dir < FN_DIRS) ? dir : -1;
    b->chain_seen = mask;
}

/* ---- the set-up ---------------------------------------------------------------
 *
 * The rows below the middle are White's and the rows above it Black's. The
 * middle row alternates OUTWARD from the centre, which is empty: the point
 * directly left of the centre is White and the point directly right of it is
 * Black. On the nine by five that is  b w b w . b w b w.
 */

static int setup_stone(int cols, int rows, int file, int rank)
{
    int mid_rank = rows / 2, mid_file = cols / 2, away;
    if (rank < mid_rank) return FN_WHITE;
    if (rank > mid_rank) return FN_BLACK;
    if (file == mid_file) return FN_EMPTY;
    if (file < mid_file) {
        away = mid_file - file;
        return away % 2 == 1 ? FN_WHITE : FN_BLACK;
    }
    away = file - mid_file;
    return away % 2 == 1 ? FN_BLACK : FN_WHITE;
}

static struct fn_board *fn_board_new(int cols, int rows)
{
    struct fn_board *b = fn_board_empty(cols, rows);
    int rank, file;
    if (!b) return NULL;
    for (rank = 0; rank < rows; rank++)
        for (file = 0; file < cols; file++)
            fn_put(b, fn_square_of(file, rank), setup_stone(cols, rows, file, rank));
    return b;
}

static struct fn_board *fn_board_copy(const struct fn_board *b)
{
    struct fn_board *n;
    if (!b) return NULL;
    n = (struct fn_board *) malloc(sizeof(struct fn_board));
    if (!n) return NULL;
    *n = *b;
    FN_LIVE++;
    return n;
}

static void fn_board_drop(struct fn_board *b)
{
    if (!b) return;
    FN_LIVE--;
    free(b);
}

static int fn_live(void) { return FN_LIVE; }

/* ---- the position string ------------------------------------------------------
 *
 *     bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w
 *
 * Rows from the TOP rank down, `w` and `b`, a digit 1 to 9 for a run of empty
 * points, `/` between rows, one space, and the side to move. The size of the
 * board is read from the string: the number of rows and their width.
 */

static struct fn_board *fn_board_of_string(const char *str, int *err)
{
    struct fn_board *b;
    const char *s, *end;
    int width[FN_ROWS_MAX + 1];
    int nrows = 1, i, rank, file, cols, side;
    int code = FN_OK;
    size_t len;

    if (err) *err = FN_OK;
    if (!str || !*str) { code = FN_POS_NULL; goto refused; }
    len = strlen(str);
    if (len >= FN_POS_MAX) { code = FN_POS_LONG; goto refused; }

    for (end = str; *end && *end != ' '; end++) {
        char c = *end;
        if (c != 'w' && c != 'b' && c != '/' && !(c >= '1' && c <= '9')) {
            code = FN_POS_LETTER;
            goto refused;
        }
    }

    for (s = str; s < end; s++)
        if (*s == '/') nrows++;
    if (nrows != 3 && nrows != 5) { code = FN_POS_ROWS; goto refused; }

    for (i = 0; i <= FN_ROWS_MAX; i++) width[i] = 0;
    for (s = str, i = 0; s < end; s++) {
        if (*s == '/') { i++; continue; }
        width[i] += (*s >= '1' && *s <= '9') ? (*s - '0') : 1;
    }
    cols = width[0];
    for (i = 1; i < nrows; i++)
        if (width[i] != cols) { code = FN_POS_WIDTH; goto refused; }
    if (!fn_size_ok(cols, nrows)) { code = FN_POS_WIDTH; goto refused; }

    if (end[0] != ' ' || (end[1] != 'w' && end[1] != 'b') || end[2] != '\0') {
        code = FN_POS_SIDE;
        goto refused;
    }
    side = end[1] == 'w' ? FN_WHITE : FN_BLACK;

    b = fn_board_empty(cols, nrows);
    if (!b) { code = FN_POS_NULL; goto refused; }
    rank = nrows - 1;
    file = 0;
    for (s = str; s < end; s++) {
        if (*s == '/') { rank--; file = 0; continue; }
        if (*s >= '1' && *s <= '9') { file += *s - '0'; continue; }
        fn_put(b, fn_square_of(file, rank), *s == 'w' ? FN_WHITE : FN_BLACK);
        file++;
    }
    fn_set_side(b, side);
    return b;

refused:
    if (err) *err = code;
    return NULL;
}

/* Writes the string and returns its length, or -1 when `len` cannot hold it. */
static int fn_to_string(const struct fn_board *b, char *buf, int len)
{
    char tmp[FN_POS_MAX];
    int n = 0, rank, file, run;
    for (rank = b->rows - 1; rank >= 0; rank--) {
        run = 0;
        for (file = 0; file < b->cols; file++) {
            int p = b->cell[fn_square_of(file, rank)];
            if (p == FN_EMPTY) { run++; continue; }
            if (run) { tmp[n++] = (char) ('0' + run); run = 0; }
            tmp[n++] = p == FN_WHITE ? 'w' : 'b';
        }
        if (run) tmp[n++] = (char) ('0' + run);
        if (rank > 0) tmp[n++] = '/';
    }
    tmp[n++] = ' ';
    tmp[n++] = b->side == FN_WHITE ? 'w' : 'b';
    if (!buf || len < n + 1) return -1;
    memcpy(buf, tmp, (size_t) n);
    buf[n] = '\0';
    return n;
}

/* ---- the table ----------------------------------------------------------------
 *
 * fn_moves.c, fn_rules.c and fn_search.c install themselves into the table here. The two files call into each
 * other and it terminates: FN_TABLE_READY is set before the installer runs, and
 * fn_moves.c only reaches fn_abi_table from inside a function the installer
 * has already handed over.
 */

static struct fn_abi FN_TABLE;
static int FN_TABLE_READY = 0;

void fn_moves_install(struct fn_abi *t);
void fn_rules_install(struct fn_abi *t);
void fn_search_install(struct fn_abi *t);

const struct fn_abi *fn_abi_table(void)
{
    if (!FN_TABLE_READY) {
        zob_init();
        FN_TABLE.abi_version     = FN_ABI_VERSION;

        FN_TABLE.board_new       = fn_board_new;
        FN_TABLE.board_empty     = fn_board_empty;
        FN_TABLE.board_of_string = fn_board_of_string;
        FN_TABLE.board_copy      = fn_board_copy;
        FN_TABLE.board_drop      = fn_board_drop;
        FN_TABLE.live            = fn_live;

        FN_TABLE.at              = fn_at;
        FN_TABLE.put             = fn_put;
        FN_TABLE.lift            = fn_lift;
        FN_TABLE.side            = fn_side;
        FN_TABLE.set_side        = fn_set_side;
        FN_TABLE.count           = fn_count;

        FN_TABLE.cols            = fn_cols;
        FN_TABLE.rows            = fn_rows;
        FN_TABLE.points          = fn_points;
        FN_TABLE.centre          = fn_centre;
        FN_TABLE.on_board        = fn_on_board;

        FN_TABLE.key             = fn_key;
        FN_TABLE.key_full        = fn_key_full;
        FN_TABLE.zobrist         = fn_zobrist;
        FN_TABLE.zobrist_side    = fn_zobrist_side;
        FN_TABLE.zobrist_size    = fn_zobrist_size;
        FN_TABLE.to_string       = fn_to_string;

        FN_TABLE.size_ok         = fn_size_ok;
        FN_TABLE.stride          = fn_stride;
        FN_TABLE.square_of       = fn_square_of;
        FN_TABLE.file_of         = fn_file_of;
        FN_TABLE.rank_of         = fn_rank_of;
        FN_TABLE.is_strong       = fn_is_strong;
        FN_TABLE.dir_opposite    = fn_dir_opposite;
        FN_TABLE.dir_is_diagonal = fn_dir_is_diagonal;

        FN_TABLE.next            = fn_next;
        FN_TABLE.degree          = fn_degree;
        FN_TABLE.segments        = fn_segments;

        FN_TABLE.chain_at        = fn_chain_at;
        FN_TABLE.chain_dir       = fn_chain_dir;
        FN_TABLE.chain_seen      = fn_chain_seen;
        FN_TABLE.chain_mask      = fn_chain_mask;
        FN_TABLE.chain_set       = fn_chain_set;
        FN_TABLE.point_bit       = fn_point_bit;

        FN_TABLE_READY = 1;      /* before the installer, or it recurses */
        fn_moves_install(&FN_TABLE);
        fn_rules_install(&FN_TABLE);
        fn_search_install(&FN_TABLE);
    }
    return &FN_TABLE;
}
