/* ru_engine.c - the board of the Royal Game of Ur, and nothing that judges a move.
 *
 * PERL-FREE by design: see include/ru_abi.h. This file compiles into the XS,
 * into a plain program, or to wasm, and knows nothing about any of them.
 *
 * THIS FILE'S SCOPE. The twenty cells, the hands and the homes, the side to
 * move, the two routes, the key, the position string in and out, and the
 * chance of each roll. What a roll allows is ru_moves.c, which appends to the
 * table.
 */

#include <stdlib.h>
#include <string.h>
#include "ru_abi.h"

/* ---- the position ---------------------------------------------------------
 *
 * No pointers, so a copy is a struct assignment and two boards never share
 * anything. THE HANDS ARE STORED AND NOT DERIVED: seven less the pieces on the
 * board and at home would be right for a legal position and would make an
 * illegal one impossible to build, and a test needs to build them.
 */

struct ru_board {
    unsigned char cell[RU_CELLS];
    int hand[2];
    int home[2];
    int side;
    int ply;
};

/* Boards handed out and not yet dropped. It exists so a test can show that a
 * destructor ran exactly once; it is a plain int and is not synchronised. */
static int RU_LIVE = 0;

/* ---- geometry ---------------------------------------------------------------
 *
 * Three rows of eight with four squares missing. The index is row by row and
 * skips the gaps, and it is OPAQUE: nothing outside this file may rely on it.
 */

static const signed char CELL_AT[RU_ROWS][RU_FILES] = {
    {  0,  1,  2,  3, -1, -1,  4,  5 },
    {  6,  7,  8,  9, 10, 11, 12, 13 },
    { 14, 15, 16, 17, -1, -1, 18, 19 }
};

static const signed char FILE_AT[RU_CELLS] = {
    0, 1, 2, 3, 6, 7,
    0, 1, 2, 3, 4, 5, 6, 7,
    0, 1, 2, 3, 6, 7
};

static const signed char ROW_AT[RU_CELLS] = {
    0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 1,
    2, 2, 2, 2, 2, 2
};

static int ru_cell_of(int file, int row)
{
    if (file < 0 || file >= RU_FILES || row < 0 || row >= RU_ROWS) return -1;
    return CELL_AT[row][file];
}

static int ru_file_of(int cell)
{
    if (cell < 0 || cell >= RU_CELLS) return -1;
    return FILE_AT[cell];
}

static int ru_row_of(int cell)
{
    if (cell < 0 || cell >= RU_CELLS) return -1;
    return ROW_AT[cell];
}

/* Five of them: the first and the seventh file of each outer row, and the
 * fourth file of the middle row. */
static int ru_is_rosette(int cell)
{
    int f = ru_file_of(cell), r = ru_row_of(cell);
    if (f < 0) return 0;
    if (r == 1) return f == 3;
    return f == 0 || f == 6;
}

/* ---- the routes ---------------------------------------------------------------
 *
 * LIGHT'S ROUTE IS WRITTEN OUT, as file and row, and dark's is light's with
 * rows 1 and 3 exchanged, computed once and not typed twice. Both enter on the
 * fourth file of their own row and walk toward the corner.
 */

static const signed char SHORT_LIGHT[14][2] = {
    {3,0}, {2,0}, {1,0}, {0,0},
    {0,1}, {1,1}, {2,1}, {3,1}, {4,1}, {5,1}, {6,1}, {7,1},
    {7,0}, {6,0}
};

static const signed char LONG_LIGHT[16][2] = {
    {3,0}, {2,0}, {1,0}, {0,0},
    {0,1}, {1,1}, {2,1}, {3,1}, {4,1}, {5,1}, {6,1},
    {6,2}, {7,2}, {7,1}, {7,0}, {6,0}
};

static int ROUTE_CELL[2][2][RU_ROUTE_MAX + 1];
static int ROUTE_STEP[2][2][RU_CELLS];
static int ROUTES_READY = 0;

static int ru_route_len(int route)
{
    if (route == RU_ROUTE_SHORT) return 14;
    if (route == RU_ROUTE_LONG)  return 16;
    return -1;
}

static void routes_init(void)
{
    int route, side, step, c;
    if (ROUTES_READY) return;
    for (route = 0; route < 2; route++) {
        const signed char (*light)[2] = (route == RU_ROUTE_LONG) ? LONG_LIGHT : SHORT_LIGHT;
        int len = ru_route_len(route);
        for (side = 0; side < 2; side++) {
            for (step = 0; step <= RU_ROUTE_MAX; step++) ROUTE_CELL[route][side][step] = -1;
            for (c = 0; c < RU_CELLS; c++) ROUTE_STEP[route][side][c] = 0;
            for (step = 1; step <= len; step++) {
                int file = light[step - 1][0];
                int row  = light[step - 1][1];
                int cell;
                if (side == RU_SIDE_DARK) row = RU_ROWS - 1 - row;
                cell = ru_cell_of(file, row);
                ROUTE_CELL[route][side][step] = cell;
                if (cell >= 0) ROUTE_STEP[route][side][cell] = step;
            }
        }
    }
    ROUTES_READY = 1;
}

static int ru_route_cell(int route, int side, int step)
{
    routes_init();
    if (route < 0 || route > 1 || side < 0 || side > 1) return -1;
    if (step < 1 || step > ru_route_len(route)) return -1;
    return ROUTE_CELL[route][side][step];
}

/* The step a cell is FOR THAT SIDE, or 0 when the side's route does not visit
 * it. On the long route the answer for one cell differs between the sides. */
static int ru_route_step(int route, int side, int cell)
{
    routes_init();
    if (route < 0 || route > 1 || side < 0 || side > 1) return 0;
    if (cell < 0 || cell >= RU_CELLS) return 0;
    return ROUTE_STEP[route][side][cell];
}

/* On both sides' routes. NOT "the middle row": that is true of the short route
 * and false of the long one, whose last five steps run through the far row. */
static int ru_route_shared(int route, int cell)
{
    return ru_route_step(route, RU_SIDE_LIGHT, cell) > 0
        && ru_route_step(route, RU_SIDE_DARK,  cell) > 0;
}

/* ---- the board ------------------------------------------------------------- */

static int clamp_pieces(int n)
{
    if (n < 0) return 0;
    if (n > RU_PIECES_MAX) return RU_PIECES_MAX;
    return n;
}

static struct ru_board *ru_board_new(int pieces)
{
    struct ru_board *b;
    routes_init();
    b = (struct ru_board *) malloc(sizeof(struct ru_board));
    if (!b) return NULL;
    memset(b, 0, sizeof(*b));
    b->hand[RU_SIDE_LIGHT] = b->hand[RU_SIDE_DARK] = clamp_pieces(pieces);
    b->side = RU_SIDE_LIGHT;
    RU_LIVE++;
    return b;
}

static struct ru_board *ru_board_copy(const struct ru_board *b)
{
    struct ru_board *n;
    if (!b) return NULL;
    n = (struct ru_board *) malloc(sizeof(struct ru_board));
    if (!n) return NULL;
    *n = *b;
    RU_LIVE++;
    return n;
}

static void ru_board_drop(struct ru_board *b)
{
    if (!b) return;
    RU_LIVE--;
    free(b);
}

static int ru_live(void) { return RU_LIVE; }

static int ru_at(const struct ru_board *b, int cell)
{
    if (cell < 0 || cell >= RU_CELLS) return -1;
    return b->cell[cell];
}

/* A value that is not a piece or RU_EMPTY is ignored, and so is a cell that is
 * not one. */
static void ru_put(struct ru_board *b, int cell, int piece)
{
    if (cell < 0 || cell >= RU_CELLS) return;
    if (piece != RU_EMPTY && !RU_IS_PIECE(piece)) return;
    b->cell[cell] = (unsigned char) piece;
}

static void ru_lift(struct ru_board *b, int cell)
{
    ru_put(b, cell, RU_EMPTY);
}

static int ru_hand(const struct ru_board *b, int side)
{
    if (side < 0 || side > 1) return -1;
    return b->hand[side];
}

static void ru_set_hand(struct ru_board *b, int side, int n)
{
    if (side < 0 || side > 1) return;
    if (n < 0 || n > RU_PIECES_MAX) return;
    b->hand[side] = n;
}

static int ru_home(const struct ru_board *b, int side)
{
    if (side < 0 || side > 1) return -1;
    return b->home[side];
}

static void ru_set_home(struct ru_board *b, int side, int n)
{
    if (side < 0 || side > 1) return;
    if (n < 0 || n > RU_PIECES_MAX) return;
    b->home[side] = n;
}

static int ru_side(const struct ru_board *b) { return b->side; }

static void ru_set_side(struct ru_board *b, int side)
{
    if (side != RU_SIDE_LIGHT && side != RU_SIDE_DARK) return;
    b->side = side;
}

/* The plies made to reach the position. It is carried by the board and is not
 * part of the position: two boards that differ only in it have one key. */
static int ru_ply(const struct ru_board *b) { return b->ply; }

static void ru_set_ply(struct ru_board *b, int ply)
{
    if (ply < 0) return;
    b->ply = ply;
}

static int ru_count(const struct ru_board *b, int side)
{
    int c, n = 0;
    if (side < 0 || side > 1) return -1;
    for (c = 0; c < RU_CELLS; c++)
        if (b->cell[c] == RU_PIECE_OF(side)) n++;
    return n;
}

static int ru_consistent(const struct ru_board *b, int n)
{
    int side;
    for (side = 0; side < 2; side++)
        if (b->hand[side] + b->home[side] + ru_count(b, side) != n) return 0;
    return 1;
}

/* ---- the key ----------------------------------------------------------------
 *
 * EXACT, and recomputed every time: twenty cells at two bits, two homes at
 * three, and the side to move. Forty-seven bits, no table and no collision.
 * The hands are left out on purpose; see ru_abi.h.
 */

static unsigned long long ru_key(const struct ru_board *b)
{
    unsigned long long k = 0;
    int c;
    for (c = 0; c < RU_CELLS; c++)
        k |= ((unsigned long long) (b->cell[c] & 3)) << (2 * c);
    k |= ((unsigned long long) (b->home[RU_SIDE_LIGHT] & 7)) << 40;
    k |= ((unsigned long long) (b->home[RU_SIDE_DARK] & 7)) << 43;
    k |= ((unsigned long long) (b->side & 1)) << 46;
    return k;
}

/* ---- the position string ------------------------------------------------------
 *
 * Three rows, row 3 first, a slash between rows, a digit for a run of empty
 * squares, an x for each square that does not exist, then the side to move,
 * light's hand and home, and dark's hand and home:
 *
 *     4xx2/8/4xx2 l 7 0 7 0
 *
 * l is a light piece and d a dark one; the side is l or d.
 *
 * EVERY FIELD IS REQUIRED. Defaulting one would turn a string cut short into a
 * position with a player to move and a full hand.
 */

static int letter_piece(char c)
{
    switch (c) {
        case 'l': return RU_LIGHT;
        case 'd': return RU_DARK;
        default:  return -1;
    }
}

static struct ru_board *refuse(struct ru_board *b, int *err, int code)
{
    if (err) *err = code;
    ru_board_drop(b);
    return NULL;
}

static struct ru_board *ru_board_of_string(const char *str, int *err)
{
    struct ru_board *b;
    int row = RU_ROWS - 1, file = 0, field;
    int value[4];
    const char *s = str;
    size_t n;

    if (err) *err = RU_OK;
    if (!str) { if (err) *err = RU_POS_NULL; return NULL; }
    n = strlen(str);
    if (n == 0) { if (err) *err = RU_POS_NULL; return NULL; }
    if (n >= RU_POS_MAX) { if (err) *err = RU_POS_LONG; return NULL; }

    b = ru_board_new(0);
    if (!b) { if (err) *err = RU_POS_NULL; return NULL; }

    for (; *s && *s != ' '; s++) {
        if (*s == '/') {
            if (file != RU_FILES) return refuse(b, err, RU_POS_WIDTH);
            if (row == 0)         return refuse(b, err, RU_POS_ROWS);
            row--; file = 0;
            continue;
        }
        if (*s >= '1' && *s <= '8') {
            int run = *s - '0';
            while (run-- > 0) {
                if (file >= RU_FILES)          return refuse(b, err, RU_POS_WIDTH);
                if (ru_cell_of(file, row) < 0) return refuse(b, err, RU_POS_GAP);
                file++;
            }
            continue;
        }
        if (*s == 'x') {
            if (file >= RU_FILES)           return refuse(b, err, RU_POS_WIDTH);
            if (ru_cell_of(file, row) >= 0) return refuse(b, err, RU_POS_X);
            file++;
            continue;
        }
        {
            int piece = letter_piece(*s);
            if (piece < 0)                 return refuse(b, err, RU_POS_LETTER);
            if (file >= RU_FILES)          return refuse(b, err, RU_POS_WIDTH);
            if (ru_cell_of(file, row) < 0) return refuse(b, err, RU_POS_GAP);
            ru_put(b, ru_cell_of(file, row), piece);
            file++;
        }
    }
    if (row != 0)         return refuse(b, err, RU_POS_ROWS);
    if (file != RU_FILES) return refuse(b, err, RU_POS_WIDTH);

    if (*s != ' ') return refuse(b, err, RU_POS_FIELD);
    s++;
    if (*s == 'l')      ru_set_side(b, RU_SIDE_LIGHT);
    else if (*s == 'd') ru_set_side(b, RU_SIDE_DARK);
    else return refuse(b, err, RU_POS_SIDE);
    s++;

    for (field = 0; field < 4; field++) {
        if (*s != ' ') return refuse(b, err, RU_POS_FIELD);
        s++;
        if (*s == '\0') return refuse(b, err, RU_POS_FIELD);
        if (*s < '0' || *s > '0' + RU_PIECES_MAX) return refuse(b, err, RU_POS_COUNT);
        value[field] = *s - '0';
        s++;
        if (*s && *s != ' ') return refuse(b, err, RU_POS_COUNT);
    }
    if (*s) return refuse(b, err, RU_POS_FIELD);

    ru_set_hand(b, RU_SIDE_LIGHT, value[0]);
    ru_set_home(b, RU_SIDE_LIGHT, value[1]);
    ru_set_hand(b, RU_SIDE_DARK,  value[2]);
    ru_set_home(b, RU_SIDE_DARK,  value[3]);

    return b;
}

static int ru_to_string(const struct ru_board *b, char *buf, int len)
{
    int row, file, i = 0, run, side;
    if (!b || !buf || len < RU_POS_MAX) return -1;
    for (row = RU_ROWS - 1; row >= 0; row--) {
        run = 0;
        for (file = 0; file < RU_FILES; file++) {
            int cell = ru_cell_of(file, row);
            int piece = cell < 0 ? -1 : b->cell[cell];
            if (piece == RU_EMPTY) { run++; continue; }
            if (run) { buf[i++] = (char) ('0' + run); run = 0; }
            buf[i++] = piece < 0 ? 'x' : piece == RU_LIGHT ? 'l' : 'd';
        }
        if (run) buf[i++] = (char) ('0' + run);
        if (row) buf[i++] = '/';
    }
    buf[i++] = ' ';
    buf[i++] = (b->side == RU_SIDE_DARK) ? 'd' : 'l';
    for (side = 0; side < 2; side++) {
        buf[i++] = ' ';
        buf[i++] = (char) ('0' + b->hand[side]);
        buf[i++] = ' ';
        buf[i++] = (char) ('0' + b->home[side]);
    }
    buf[i] = '\0';
    return i;
}

/* ---- the chance of a roll -----------------------------------------------------
 *
 * Each die is marked or not with equal chance, so the count of marked dice is
 * binomial. A roll is the count, except that a count of nothing is worth
 * `zero_rolls`. WHERE THAT IS FOUR AND THERE ARE FOUR DICE, a roll of four comes
 * up two ways, from nothing marked and from everything marked, and its weight
 * is 2.
 *
 * NOTHING HERE THROWS A DIE. These are the odds a search weighs.
 */

struct ru_chance { int roll; int weight; };

static const struct ru_chance FOUR_ZERO_NOTHING[]  = { {0,1}, {1,4}, {2,6}, {3,4}, {4,1} };
static const struct ru_chance FOUR_ZERO_FOUR[]     = { {1,4}, {2,6}, {3,4}, {4,2} };
static const struct ru_chance THREE_ZERO_NOTHING[] = { {0,1}, {1,3}, {2,3}, {3,1} };
static const struct ru_chance THREE_ZERO_FOUR[]    = { {1,3}, {2,3}, {3,1}, {4,1} };

static const struct ru_chance *chance_table(int dice, int zero_rolls, int *count, int *denominator)
{
    if (dice == 4 && zero_rolls == 0) { *count = 5; *denominator = 16; return FOUR_ZERO_NOTHING; }
    if (dice == 4 && zero_rolls == 4) { *count = 4; *denominator = 16; return FOUR_ZERO_FOUR; }
    if (dice == 3 && zero_rolls == 0) { *count = 4; *denominator = 8;  return THREE_ZERO_NOTHING; }
    if (dice == 3 && zero_rolls == 4) { *count = 4; *denominator = 8;  return THREE_ZERO_FOUR; }
    *count = 0; *denominator = 0;
    return NULL;
}

static int ru_chance_count(int dice, int zero_rolls)
{
    int count, denominator;
    chance_table(dice, zero_rolls, &count, &denominator);
    return count;
}

static int ru_chance(int dice, int zero_rolls, int i, int *roll, int *weight, int *denominator)
{
    int count, den;
    const struct ru_chance *table = chance_table(dice, zero_rolls, &count, &den);
    if (!table || i < 0 || i >= count) return 0;
    if (roll)        *roll = table[i].roll;
    if (weight)      *weight = table[i].weight;
    if (denominator) *denominator = den;
    return 1;
}

/* ---- the table -------------------------------------------------------------- */

static struct ru_abi RU_TABLE;
static int RU_TABLE_READY = 0;

/* ru_moves.c installs itself into the table here. It reaches the board through
 * the table and through nothing else. */
void ru_moves_install(struct ru_abi *t);
void ru_search_install(struct ru_abi *t);

const struct ru_abi *ru_abi_table(void)
{
    if (!RU_TABLE_READY) {
        routes_init();
        RU_TABLE.abi_version = RU_ABI_VERSION;

        RU_TABLE.board_new       = ru_board_new;
        RU_TABLE.board_of_string = ru_board_of_string;
        RU_TABLE.board_copy      = ru_board_copy;
        RU_TABLE.board_drop      = ru_board_drop;
        RU_TABLE.live            = ru_live;

        RU_TABLE.at         = ru_at;
        RU_TABLE.put        = ru_put;
        RU_TABLE.lift       = ru_lift;
        RU_TABLE.hand       = ru_hand;
        RU_TABLE.set_hand   = ru_set_hand;
        RU_TABLE.home       = ru_home;
        RU_TABLE.set_home   = ru_set_home;
        RU_TABLE.side       = ru_side;
        RU_TABLE.set_side   = ru_set_side;
        RU_TABLE.count      = ru_count;
        RU_TABLE.consistent = ru_consistent;

        RU_TABLE.key       = ru_key;
        RU_TABLE.to_string = ru_to_string;

        RU_TABLE.cell_of    = ru_cell_of;
        RU_TABLE.file_of    = ru_file_of;
        RU_TABLE.row_of     = ru_row_of;
        RU_TABLE.is_rosette = ru_is_rosette;

        RU_TABLE.route_len    = ru_route_len;
        RU_TABLE.route_cell   = ru_route_cell;
        RU_TABLE.route_step   = ru_route_step;
        RU_TABLE.route_shared = ru_route_shared;

        RU_TABLE.chance_count = ru_chance_count;
        RU_TABLE.chance       = ru_chance;

        RU_TABLE.ply     = ru_ply;
        RU_TABLE.set_ply = ru_set_ply;

        RU_TABLE_READY = 1;      /* before the installer, or it recurses */
        ru_moves_install(&RU_TABLE);
        ru_search_install(&RU_TABLE);
    }
    return &RU_TABLE;
}
