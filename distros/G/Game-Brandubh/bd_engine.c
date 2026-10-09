/* bd_engine.c - the brandubh board, and nothing that judges a move.
 *
 * PERL-FREE by design: see include/bd_abi.h. This file compiles into the XS,
 * into a plain program, or to wasm, and knows nothing about any of them.
 *
 * THIS FILE'S SCOPE. The board, the padded index, put and lift, the side to
 * move, the zobrist key, and the position string in and out. Where a piece
 * may go is bd_moves.c, which appends to the table.
 */

#include <stdlib.h>
#include <string.h>
#include "bd_abi.h"

/* ---- the position ---------------------------------------------------------
 *
 * A flat 81-cell array with a sentinel ring, the side to move, and a key
 * maintained incrementally. No pointers, so a copy is a struct assignment and
 * two boards never share anything.
 */

struct bd_board {
    unsigned char cell[BD_CELLS];
    int side;
    unsigned long long key;
};

/* Boards handed out and not yet dropped. It exists so a test can show that a
 * destructor ran exactly once; it is a plain int and is not synchronised. */
static int BD_LIVE = 0;

/* ---- the zobrist table -----------------------------------------------------
 *
 * DERIVED, NOT COMMITTED. Two workers in a pool must agree about whether a
 * position has been seen, so the table must not come from rand() or from
 * anything that varies per process. A fixed function of a fixed seed satisfies
 * that exactly as a committed array does, and it cannot suffer the
 * transcription error a hand-pasted array can. splitmix64 is published, has no
 * weak seeds, and is what the sibling engine uses.
 *
 * CHANGING THIS GENERATOR OR ITS SEED CHANGES EVERY KEY. t/03-key.t pins
 * values so that is caught by a red test.
 */

static unsigned long long ZOB[BD_KING + 1][BD_CELLS];
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
    unsigned long long s = 0x6272616E64756268ULL;   /* "brandubh" */
    int p, c;
    if (ZOB_READY) return;
    for (p = 0; p <= BD_KING; p++)
        for (c = 0; c < BD_CELLS; c++)
            ZOB[p][c] = splitmix64(&s);
    ZOB_SIDE = splitmix64(&s);
    ZOB_READY = 1;
}

/* ---- geometry -------------------------------------------------------------- */

static int bd_stride(void) { return BD_STRIDE; }

static int bd_square_of(int file, int rank)
{
    if (file < 0 || file >= BD_SIZE || rank < 0 || rank >= BD_SIZE) return -1;
    return (rank + 1) * BD_STRIDE + (file + 1);
}

static int bd_on_board(int sq)
{
    int f, r;
    if (sq < 0 || sq >= BD_CELLS) return 0;
    f = sq % BD_STRIDE;
    r = sq / BD_STRIDE;
    return f >= 1 && f <= BD_SIZE && r >= 1 && r <= BD_SIZE;
}

static int bd_file_of(int sq)
{
    if (!bd_on_board(sq)) return -1;
    return (sq % BD_STRIDE) - 1;
}

static int bd_rank_of(int sq)
{
    if (!bd_on_board(sq)) return -1;
    return (sq / BD_STRIDE) - 1;
}

#define BD_THRONE ((BD_SIZE / 2 + 1) * BD_STRIDE + (BD_SIZE / 2 + 1))

static int bd_is_throne(int sq) { return sq == BD_THRONE; }

static int bd_is_corner(int sq)
{
    int f = bd_file_of(sq), r = bd_rank_of(sq);
    if (f < 0) return 0;
    return (f == 0 || f == BD_SIZE - 1) && (r == 0 || r == BD_SIZE - 1);
}

/* The four squares that share an edge with the throne. Not the diagonals: the
 * king's capture there counts orthogonal neighbours and nothing else. */
static int bd_beside_throne(int sq)
{
    if (!bd_on_board(sq)) return 0;
    return sq == BD_THRONE - 1 || sq == BD_THRONE + 1
        || sq == BD_THRONE - BD_STRIDE || sq == BD_THRONE + BD_STRIDE;
}

/* THE KING IS ON THE DEFENDERS' SIDE, and this is the one place that says so. */
static int bd_side_of(int piece)
{
    if (piece == BD_ATTACKER) return BD_ATTACKERS;
    if (piece == BD_DEFENDER || piece == BD_KING) return BD_DEFENDERS;
    return -1;
}

/* ---- the key ----------------------------------------------------------------
 *
 * The key covers the pieces, their squares, and the side to move, and NOTHING
 * else, so a position repeating is a position repeating.
 */

static unsigned long long bd_zobrist(int piece, int sq)
{
    zob_init();
    if (!BD_IS_PIECE(piece)) return 0;
    if (!bd_on_board(sq)) return 0;
    return ZOB[piece][sq];
}

static unsigned long long bd_zobrist_side(void)
{
    zob_init();
    return ZOB_SIDE;
}

/* ---- the board ------------------------------------------------------------- */

static void board_blank(struct bd_board *b)
{
    int f, r;
    memset(b, 0, sizeof(*b));
    memset(b->cell, BD_BORDER, sizeof(b->cell));
    for (r = 0; r < BD_SIZE; r++)
        for (f = 0; f < BD_SIZE; f++)
            b->cell[bd_square_of(f, r)] = BD_EMPTY;
    b->side = BD_ATTACKERS;
    b->key = 0;
}

static struct bd_board *bd_board_empty(void)
{
    struct bd_board *b;
    zob_init();
    b = (struct bd_board *) malloc(sizeof(struct bd_board));
    if (!b) return NULL;
    board_blank(b);
    BD_LIVE++;
    return b;
}

/* put and lift MAINTAIN THE KEY and judge nothing else. A piece value that is
 * not one of the three, or BD_EMPTY, is ignored: the ring is not writable and
 * neither is a square with a border on it. */
static void bd_put(struct bd_board *b, int sq, int piece)
{
    int old;
    if (!bd_on_board(sq)) return;
    if (piece != BD_EMPTY && !BD_IS_PIECE(piece)) return;
    old = b->cell[sq];
    if (old != BD_EMPTY) b->key ^= bd_zobrist(old, sq);
    b->cell[sq] = (unsigned char) piece;
    if (piece != BD_EMPTY) b->key ^= bd_zobrist(piece, sq);
}

static void bd_lift(struct bd_board *b, int sq)
{
    bd_put(b, sq, BD_EMPTY);
}

static int bd_at(const struct bd_board *b, int sq)
{
    if (sq < 0 || sq >= BD_CELLS) return BD_BORDER;
    return b->cell[sq];
}

static int bd_side(const struct bd_board *b) { return b->side; }

static void bd_set_side(struct bd_board *b, int side)
{
    if (side != BD_ATTACKERS && side != BD_DEFENDERS) return;
    if (b->side == side) return;
    b->side = side;
    b->key ^= ZOB_SIDE;
}

static int bd_count(const struct bd_board *b, int piece)
{
    int sq, n = 0;
    for (sq = 0; sq < BD_CELLS; sq++)
        if (b->cell[sq] == piece && bd_on_board(sq)) n++;
    return n;
}

/* -1 and not 0 for "no king": 0 is a cell of the ring, and a caller that walked
 * from it would be walking the border. */
static int bd_king_square(const struct bd_board *b)
{
    int sq;
    for (sq = 0; sq < BD_CELLS; sq++)
        if (b->cell[sq] == BD_KING && bd_on_board(sq)) return sq;
    return -1;
}

static unsigned long long bd_key(const struct bd_board *b) { return b->key; }

/* The key from nothing, by walking the board. It must equal the maintained key
 * after any sequence of put, lift and set_side, and a test holds it to that. */
static unsigned long long bd_key_full(const struct bd_board *b)
{
    unsigned long long k = 0;
    int sq;
    for (sq = 0; sq < BD_CELLS; sq++)
        if (bd_on_board(sq) && b->cell[sq] != BD_EMPTY)
            k ^= bd_zobrist(b->cell[sq], sq);
    if (b->side == BD_DEFENDERS) k ^= bd_zobrist_side();
    return k;
}

/* The set-up: the king on the throne, a defender on each side of him, and the
 * attackers two deep at the end of each arm of the cross. Attackers move first.
 *
 *     7  . . . A . . .
 *     6  . . . A . . .
 *     5  . . . D . . .
 *     4  A A D K D A A
 *     3  . . . D . . .
 *     2  . . . A . . .
 *     1  . . . A . . .
 *        a b c d e f g
 */
static struct bd_board *bd_board_new(void)
{
    static const int ARM[BD_SIZE] = {
        BD_ATTACKER, BD_ATTACKER, BD_DEFENDER, BD_KING,
        BD_DEFENDER, BD_ATTACKER, BD_ATTACKER
    };
    struct bd_board *b = bd_board_empty();
    int mid = BD_SIZE / 2, i;
    if (!b) return NULL;
    for (i = 0; i < BD_SIZE; i++) {
        bd_put(b, bd_square_of(i, mid), ARM[i]);
        bd_put(b, bd_square_of(mid, i), ARM[i]);
    }
    return b;
}

static struct bd_board *bd_board_copy(const struct bd_board *b)
{
    struct bd_board *n;
    if (!b) return NULL;
    n = (struct bd_board *) malloc(sizeof(struct bd_board));
    if (!n) return NULL;
    *n = *b;
    BD_LIVE++;
    return n;
}

static void bd_board_drop(struct bd_board *b)
{
    if (!b) return;
    BD_LIVE--;
    free(b);
}

static int bd_live(void) { return BD_LIVE; }

/* ---- the position string ------------------------------------------------------
 *
 * Seven rows, rank 7 first, a slash between rows, a digit for a run of empty
 * squares, then one space and the side to move:
 *
 *     3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a
 *
 * a is an attacker, d a defender, k the king; the side is a or d.
 *
 * THE SIDE IS REQUIRED. Defaulting it would turn a string with the field cut
 * off into a position with a player to move, which is a different position
 * from the one somebody meant.
 */

static int letter_piece(char c)
{
    switch (c) {
        case 'a': return BD_ATTACKER;
        case 'd': return BD_DEFENDER;
        case 'k': return BD_KING;
        default:  return -1;
    }
}

static char piece_letter(int piece)
{
    switch (piece) {
        case BD_ATTACKER: return 'a';
        case BD_DEFENDER: return 'd';
        case BD_KING:     return 'k';
        default:          return '?';
    }
}

static struct bd_board *refuse(struct bd_board *b, int *err, int code)
{
    if (err) *err = code;
    bd_board_drop(b);
    return NULL;
}

static struct bd_board *bd_board_of_string(const char *str, int *err)
{
    struct bd_board *b;
    int rank = BD_SIZE - 1, file = 0;
    const char *s = str;
    size_t n;

    if (err) *err = BD_OK;
    if (!str) { if (err) *err = BD_POS_NULL; return NULL; }
    n = strlen(str);
    if (n == 0) { if (err) *err = BD_POS_NULL; return NULL; }
    if (n >= BD_POS_MAX) { if (err) *err = BD_POS_LONG; return NULL; }

    b = bd_board_empty();
    if (!b) { if (err) *err = BD_POS_NULL; return NULL; }

    for (; *s && *s != ' '; s++) {
        if (*s == '/') {
            if (file != BD_SIZE) return refuse(b, err, BD_POS_WIDTH);
            if (rank == 0)       return refuse(b, err, BD_POS_ROWS);
            rank--; file = 0;
            continue;
        }
        if (*s >= '1' && *s <= '7') {
            file += *s - '0';
            if (file > BD_SIZE) return refuse(b, err, BD_POS_WIDTH);
            continue;
        }
        {
            int piece = letter_piece(*s);
            if (piece < 0)       return refuse(b, err, BD_POS_LETTER);
            if (file >= BD_SIZE) return refuse(b, err, BD_POS_WIDTH);
            bd_put(b, bd_square_of(file, rank), piece);
            file++;
        }
    }
    if (rank != 0)       return refuse(b, err, BD_POS_ROWS);
    if (file != BD_SIZE) return refuse(b, err, BD_POS_WIDTH);

    if (*s != ' ') return refuse(b, err, BD_POS_SIDE);
    s++;
    if (*s == 'a')      bd_set_side(b, BD_ATTACKERS);
    else if (*s == 'd') bd_set_side(b, BD_DEFENDERS);
    else return refuse(b, err, BD_POS_SIDE);
    s++;
    if (*s) return refuse(b, err, BD_POS_SIDE);

    return b;
}

static int bd_to_string(const struct bd_board *b, char *buf, int len)
{
    int rank, file, i = 0, run;
    if (!b || !buf || len < BD_POS_MAX) return -1;
    for (rank = BD_SIZE - 1; rank >= 0; rank--) {
        run = 0;
        for (file = 0; file < BD_SIZE; file++) {
            int piece = b->cell[bd_square_of(file, rank)];
            if (piece == BD_EMPTY) { run++; continue; }
            if (run) { buf[i++] = (char) ('0' + run); run = 0; }
            buf[i++] = piece_letter(piece);
        }
        if (run) buf[i++] = (char) ('0' + run);
        if (rank) buf[i++] = '/';
    }
    buf[i++] = ' ';
    buf[i++] = (b->side == BD_DEFENDERS) ? 'd' : 'a';
    buf[i] = '\0';
    return i;
}

/* ---- the table -------------------------------------------------------------- */

static struct bd_abi BD_TABLE;
static int BD_TABLE_READY = 0;

/* bd_moves.c installs itself into the table here. The two files call into each
 * other and it terminates: BD_TABLE_READY is set before the installer runs, and
 * bd_moves.c only reaches bd_abi_table from inside a function the installer
 * has already handed over. */
void bd_moves_install(struct bd_abi *t);
void bd_rules_install(struct bd_abi *t);
void bd_search_install(struct bd_abi *t);

const struct bd_abi *bd_abi_table(void)
{
    if (!BD_TABLE_READY) {
        zob_init();
        BD_TABLE.abi_version = BD_ABI_VERSION;

        BD_TABLE.board_new       = bd_board_new;
        BD_TABLE.board_empty     = bd_board_empty;
        BD_TABLE.board_of_string = bd_board_of_string;
        BD_TABLE.board_copy      = bd_board_copy;
        BD_TABLE.board_drop      = bd_board_drop;
        BD_TABLE.live            = bd_live;

        BD_TABLE.at          = bd_at;
        BD_TABLE.put         = bd_put;
        BD_TABLE.lift        = bd_lift;
        BD_TABLE.side        = bd_side;
        BD_TABLE.set_side    = bd_set_side;
        BD_TABLE.count       = bd_count;
        BD_TABLE.king_square = bd_king_square;

        BD_TABLE.key          = bd_key;
        BD_TABLE.key_full     = bd_key_full;
        BD_TABLE.zobrist      = bd_zobrist;
        BD_TABLE.zobrist_side = bd_zobrist_side;
        BD_TABLE.to_string    = bd_to_string;

        BD_TABLE.stride        = bd_stride;
        BD_TABLE.square_of     = bd_square_of;
        BD_TABLE.file_of       = bd_file_of;
        BD_TABLE.rank_of       = bd_rank_of;
        BD_TABLE.on_board      = bd_on_board;
        BD_TABLE.is_throne     = bd_is_throne;
        BD_TABLE.is_corner     = bd_is_corner;
        BD_TABLE.beside_throne = bd_beside_throne;
        BD_TABLE.side_of       = bd_side_of;

        BD_TABLE_READY = 1;      /* before the installer, or it recurses */
        bd_moves_install(&BD_TABLE);
        bd_rules_install(&BD_TABLE);
        bd_search_install(&BD_TABLE);
    }
    return &BD_TABLE;
}
