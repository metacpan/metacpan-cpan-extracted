/* sen_engine.c - the board of Senet, and nothing that judges a move.
 *
 * PERL-FREE by design: see include/sen_abi.h. This file compiles into the XS,
 * into a plain program, or to wasm, and knows nothing about any of them.
 *
 * THIS FILE'S SCOPE. The thirty houses, the side to move, the number of pieces
 * a side has, the grid, the marked houses, the two named rule sets as data, the
 * key, the position string in and out, and the chance of each roll. What a
 * roll allows is sen_moves.c, which appends to the table.
 */

#include <stdlib.h>
#include <string.h>
#include "sen_abi.h"

/* ---- the position ---------------------------------------------------------
 *
 * No pointers, so a copy is a struct assignment and two boards never share
 * anything. house[0] is never read or written; house h is house[h].
 *
 * THE HOMES ARE DERIVED AND NOT STORED. Nothing enters this board from off it,
 * so a stored home could only ever disagree with the houses.
 */

struct sen_board {
    unsigned char house[SEN_HOUSES + 1];
    int pieces;
    int side;
    int ply;
};

/* Boards handed out and not yet dropped. It exists so a test can show that a
 * destructor ran exactly once; it is a plain int and is not synchronised. */
static int SEN_LIVE = 0;

/* ---- geometry ---------------------------------------------------------------
 *
 * The reversed S: the top row left to right, the middle row right to left, the
 * bottom row left to right. Three formulas, and t/01-houses.t types the grid out
 * by hand to check them.
 */

static int sen_house_of(int row, int col)
{
    if (col < 0 || col >= SEN_COLS) return -1;
    if (row == 0) return col + 1;
    if (row == 1) return 20 - col;
    if (row == 2) return 21 + col;
    return -1;
}

static int sen_row_of(int house)
{
    if (house < 1 || house > SEN_HOUSES) return -1;
    return (house - 1) / SEN_COLS;
}

static int sen_col_of(int house)
{
    if (house < 1 || house > SEN_HOUSES) return -1;
    if (sen_row_of(house) == 1) return 20 - house;
    return (house - 1) % SEN_COLS;
}

/* The house of rebirth and the last five. The same under every set: which of
 * them is SAFE is the set's, and lives in the rules struct. */
static int sen_is_marked(int house)
{
    return house == SEN_REBIRTH || (house >= 26 && house <= SEN_HOUSES);
}

/* ---- the named rule sets ----------------------------------------------------
 *
 * THE ONLY PLACE IN THE C WHERE A SET HAS A NAME. Everything else reads fields.
 * Each is written out from plan_game_senet/00-overview.md: `kendall` from G's
 * Kendall set, `skyruk` from G's Skyruk set, every divergence between the
 * sources decided there and not here.
 */

#define SAFE(h) (1UL << (h))
#define W SEN_X_WALK
#define O SEN_X_OFF
#define S SEN_X_STAY

static const struct sen_rules RULES_KENDALL = {
    5, 3, SEN_PROTECT_RUN, 1, SEN_REACH_EXACT, 0,
    SAFE(15) | SAFE(26) | SAFE(28) | SAFE(29) | SAFE(30),
    {
        { {W}, {28}, {29}, {30}, {O} },
        { {0}, {0},  {0},  {0},  {0} },
        { {0}, {0},  {O},  {0},  {0} },
        { {0}, {O},  {0},  {0},  {0} },
        { {O}, {0},  {0},  {0},  {0} }
    },
    { 0, 0, 0, 0 }
};

static const struct sen_rules RULES_SKYRUK = {
    5, 2, SEN_PROTECT_ENDS, 1, SEN_REACH_ANY, 1,
    SAFE(15) | SAFE(26) | SAFE(27) | SAFE(28) | SAFE(29) | SAFE(30),
    {
        { {27, W}, {28, 27, W}, {29, 27, W}, {30, 27, W}, {O} },
        { {W},     {W},         {W},         {O},         {S} },
        { {0},     {0},         {O},         {0},         {0} },
        { {0},     {O},         {0},         {0},         {0} },
        { {O},     {O},         {O},         {O},         {O} }
    },
    { 0, 0, 0, 0 }
};

#undef W
#undef O
#undef S

static int sen_rules_named(int name, struct sen_rules *r)
{
    if (!r) return 0;
    if (name == SEN_RULES_KENDALL) { *r = RULES_KENDALL; return 1; }
    if (name == SEN_RULES_SKYRUK)  { *r = RULES_SKYRUK;  return 1; }
    return 0;
}

static int sen_rules_id(const char *name)
{
    if (!name) return -1;
    if (strcmp(name, "kendall") == 0) return SEN_RULES_KENDALL;
    if (strcmp(name, "skyruk") == 0)  return SEN_RULES_SKYRUK;
    return -1;
}

static int sen_rules_ok(const struct sen_rules *r)
{
    int h, roll, i;
    if (!r) return 0;
    if (r->pieces < 1 || r->pieces > SEN_PIECES_MAX) return 0;
    if (r->blockade != 0 && r->blockade != 2 && r->blockade != 3) return 0;
    if (r->protect < SEN_PROTECT_NONE || r->protect > SEN_PROTECT_ENDS) return 0;
    if (r->backward != 0 && r->backward != 1) return 0;
    if (r->reach26 != SEN_REACH_EXACT && r->reach26 != SEN_REACH_ANY) return 0;
    if (r->throw_on_26 != 0 && r->throw_on_26 != 1) return 0;
    if (r->safe & 1UL) return 0;
    if (r->safe >> (SEN_HOUSES + 1)) return 0;
    for (h = 0; h < SEN_EXIT_HOUSES; h++) {
        for (roll = 0; roll < SEN_ROLL_MAX; roll++) {
            int ended = 0;
            for (i = 0; i < SEN_CHAIN_MAX; i++) {
                int e = r->exit[h][roll][i];
                if (e < SEN_X_END || e > SEN_X_STAY) return 0;
                if (ended && e != SEN_X_END) return 0;
                if (e == SEN_X_END) ended = 1;
            }
        }
    }
    for (i = 0; i < 4; i++)
        if (r->reserved[i] != 0) return 0;
    return 1;
}

/* ---- the board ------------------------------------------------------------- */

static int sen_clamp_pieces(int n)
{
    if (n < 1) return 1;
    if (n > SEN_PIECES_MAX) return SEN_PIECES_MAX;
    return n;
}

static struct sen_board *sen_board_new(int pieces)
{
    struct sen_board *b = (struct sen_board *) malloc(sizeof(struct sen_board));
    if (!b) return NULL;
    memset(b, 0, sizeof(*b));
    b->pieces = sen_clamp_pieces(pieces);
    b->side = SEN_SIDE_LIGHT;
    SEN_LIVE++;
    return b;
}

static struct sen_board *sen_board_copy(const struct sen_board *b)
{
    struct sen_board *n;
    if (!b) return NULL;
    n = (struct sen_board *) malloc(sizeof(struct sen_board));
    if (!n) return NULL;
    *n = *b;
    SEN_LIVE++;
    return n;
}

static void sen_board_drop(struct sen_board *b)
{
    if (!b) return;
    SEN_LIVE--;
    free(b);
}

static int sen_live(void) { return SEN_LIVE; }

static int sen_at(const struct sen_board *b, int house)
{
    if (house < 1 || house > SEN_HOUSES) return -1;
    return b->house[house];
}

/* A value that is not a piece or SEN_EMPTY is ignored, and so is a house that
 * is not one. */
static void sen_put(struct sen_board *b, int house, int piece)
{
    if (house < 1 || house > SEN_HOUSES) return;
    if (piece != SEN_EMPTY && !SEN_IS_PIECE(piece)) return;
    b->house[house] = (unsigned char) piece;
}

static void sen_lift(struct sen_board *b, int house)
{
    sen_put(b, house, SEN_EMPTY);
}

static int sen_side(const struct sen_board *b) { return b->side; }

static void sen_set_side(struct sen_board *b, int side)
{
    if (side != SEN_SIDE_LIGHT && side != SEN_SIDE_DARK) return;
    b->side = side;
}

static int sen_pieces(const struct sen_board *b) { return b->pieces; }

static int sen_count(const struct sen_board *b, int side)
{
    int h, n = 0;
    if (side != SEN_SIDE_LIGHT && side != SEN_SIDE_DARK) return -1;
    for (h = 1; h <= SEN_HOUSES; h++)
        if (b->house[h] == SEN_PIECE_OF(side)) n++;
    return n;
}

static int sen_home(const struct sen_board *b, int side)
{
    if (side != SEN_SIDE_LIGHT && side != SEN_SIDE_DARK) return -1;
    return b->pieces - sen_count(b, side);
}

static int sen_consistent(const struct sen_board *b)
{
    return sen_home(b, SEN_SIDE_LIGHT) >= 0 && sen_home(b, SEN_SIDE_DARK) >= 0;
}

/* The plies made to reach the position. It is carried by the board and is not
 * part of the position: two boards that differ only in it have one key. */
static int sen_ply(const struct sen_board *b) { return b->ply; }

static void sen_set_ply(struct sen_board *b, int ply)
{
    if (ply < 0) return;
    b->ply = ply;
}

/* ---- the key ----------------------------------------------------------------
 *
 * EXACT, and recomputed every time: thirty houses at two bits and the side to
 * move. Sixty-one bits, no table and no collision. The homes and `pieces` are
 * left out on purpose; see sen_abi.h.
 */

static unsigned long long sen_key(const struct sen_board *b)
{
    unsigned long long k = 0;
    int h;
    for (h = 1; h <= SEN_HOUSES; h++)
        k |= ((unsigned long long) (b->house[h] & 3)) << (2 * (h - 1));
    k |= ((unsigned long long) (b->side & 1)) << 60;
    return k;
}

/* ---- the position string ------------------------------------------------------
 *
 * The houses IN TRACK ORDER, three groups of ten with a slash between, a
 * character a house, then the side to move and `pieces`:
 *
 *     dldldldldl/........../.......... l 5
 *
 * l is a light piece, d a dark one and . an empty house. Character k of the
 * thirty is house k: the middle group runs 11 to 20 from the left, which the
 * grid draws from the right. A string is not a picture.
 *
 * EVERY FIELD IS REQUIRED. Defaulting one would turn a string cut short into a
 * position with a player to move.
 */

static int sen_letter_piece(char c)
{
    switch (c) {
        case 'l': return SEN_LIGHT;
        case 'd': return SEN_DARK;
        case '.': return SEN_EMPTY;
        default:  return -1;
    }
}

static struct sen_board *sen_refuse(struct sen_board *b, int *err, int code)
{
    if (err) *err = code;
    sen_board_drop(b);
    return NULL;
}

static struct sen_board *sen_board_of_string(const char *str, int *err)
{
    struct sen_board *b;
    int group = 0, width = 0, house = 0;
    const char *s = str;
    size_t n;

    if (err) *err = SEN_OK;
    if (!str) { if (err) *err = SEN_POS_NULL; return NULL; }
    n = strlen(str);
    if (n == 0) { if (err) *err = SEN_POS_NULL; return NULL; }
    if (n >= SEN_POS_MAX) { if (err) *err = SEN_POS_LONG; return NULL; }

    b = sen_board_new(1);
    if (!b) { if (err) *err = SEN_POS_NULL; return NULL; }

    for (; *s && *s != ' '; s++) {
        int piece;
        if (*s == '/') {
            if (width != SEN_COLS) return sen_refuse(b, err, SEN_POS_WIDTH);
            if (group == SEN_ROWS - 1) return sen_refuse(b, err, SEN_POS_GROUPS);
            group++; width = 0;
            continue;
        }
        piece = sen_letter_piece(*s);
        if (piece < 0)          return sen_refuse(b, err, SEN_POS_LETTER);
        if (width >= SEN_COLS)  return sen_refuse(b, err, SEN_POS_WIDTH);
        house = group * SEN_COLS + width + 1;
        sen_put(b, house, piece);
        width++;
    }
    if (group != SEN_ROWS - 1) return sen_refuse(b, err, SEN_POS_GROUPS);
    if (width != SEN_COLS)     return sen_refuse(b, err, SEN_POS_WIDTH);

    if (*s != ' ') return sen_refuse(b, err, SEN_POS_FIELD);
    s++;
    if (*s == 'l')      sen_set_side(b, SEN_SIDE_LIGHT);
    else if (*s == 'd') sen_set_side(b, SEN_SIDE_DARK);
    else if (*s == '\0') return sen_refuse(b, err, SEN_POS_FIELD);
    else return sen_refuse(b, err, SEN_POS_SIDE);
    s++;

    if (*s != ' ') return sen_refuse(b, err, *s ? SEN_POS_SIDE : SEN_POS_FIELD);
    s++;
    if (*s == '\0') return sen_refuse(b, err, SEN_POS_FIELD);
    if (*s < '1' || *s > '0' + SEN_PIECES_MAX) return sen_refuse(b, err, SEN_POS_PIECES);
    b->pieces = *s - '0';
    s++;
    if (*s && *s != ' ') return sen_refuse(b, err, SEN_POS_PIECES);
    if (*s) return sen_refuse(b, err, SEN_POS_FIELD);

    if (!sen_consistent(b)) return sen_refuse(b, err, SEN_POS_EXCESS);
    return b;
}

static int sen_to_string(const struct sen_board *b, char *buf, int len)
{
    int h, i = 0;
    if (!b || !buf || len < SEN_POS_MAX) return -1;
    for (h = 1; h <= SEN_HOUSES; h++) {
        int p = b->house[h];
        buf[i++] = p == SEN_LIGHT ? 'l' : p == SEN_DARK ? 'd' : '.';
        if (h % SEN_COLS == 0 && h < SEN_HOUSES) buf[i++] = '/';
    }
    buf[i++] = ' ';
    buf[i++] = (b->side == SEN_SIDE_DARK) ? 'd' : 'l';
    buf[i++] = ' ';
    buf[i++] = (char) ('0' + b->pieces);
    buf[i] = '\0';
    return i;
}

/* ---- the chance of a roll -----------------------------------------------------
 *
 * Each stick lands light or dark with equal chance, so the count of light faces
 * is binomial over sixteen ways: 1, 4, 6, 4, 1 for 0 to 4. A throw of 0 is a
 * roll of 5, so IN ORDER OF ROLL the weights are 4, 6, 4, 1, 1. The last row is
 * the throw of nothing.
 *
 * NOTHING HERE THROWS A STICK. These are the odds a search weighs.
 */

struct sen_chance { int roll; int weight; };

static const struct sen_chance CHANCE[] = { {1,4}, {2,6}, {3,4}, {4,1}, {5,1} };

#define CHANCE_COUNT 5
#define CHANCE_DENOMINATOR 16

static int sen_chance_count(void) { return CHANCE_COUNT; }

static int sen_chance(int i, int *roll, int *weight, int *denominator)
{
    if (i < 0 || i >= CHANCE_COUNT) return 0;
    if (roll)        *roll = CHANCE[i].roll;
    if (weight)      *weight = CHANCE[i].weight;
    if (denominator) *denominator = CHANCE_DENOMINATOR;
    return 1;
}

static int sen_extra(int roll)
{
    if (roll < 1 || roll > SEN_ROLL_MAX) return -1;
    return roll == 1 || roll == 4 || roll == 5;
}

/* ---- the table -------------------------------------------------------------- */

static struct sen_abi SEN_TABLE;
static int SEN_TABLE_READY = 0;

/* sen_moves.c installs itself into the table here. It reaches the board through
 * the table and through nothing else. */
void sen_moves_install(struct sen_abi *t);
void sen_search_install(struct sen_abi *t);

const struct sen_abi *sen_abi_table(void)
{
    if (!SEN_TABLE_READY) {
        SEN_TABLE.abi_version = SEN_ABI_VERSION;

        SEN_TABLE.board_new       = sen_board_new;
        SEN_TABLE.board_of_string = sen_board_of_string;
        SEN_TABLE.board_copy      = sen_board_copy;
        SEN_TABLE.board_drop      = sen_board_drop;
        SEN_TABLE.live            = sen_live;

        SEN_TABLE.at         = sen_at;
        SEN_TABLE.put        = sen_put;
        SEN_TABLE.lift       = sen_lift;
        SEN_TABLE.side       = sen_side;
        SEN_TABLE.set_side   = sen_set_side;
        SEN_TABLE.pieces     = sen_pieces;
        SEN_TABLE.count      = sen_count;
        SEN_TABLE.home       = sen_home;
        SEN_TABLE.consistent = sen_consistent;
        SEN_TABLE.ply        = sen_ply;
        SEN_TABLE.set_ply    = sen_set_ply;

        SEN_TABLE.key       = sen_key;
        SEN_TABLE.to_string = sen_to_string;

        SEN_TABLE.house_of  = sen_house_of;
        SEN_TABLE.row_of    = sen_row_of;
        SEN_TABLE.col_of    = sen_col_of;
        SEN_TABLE.is_marked = sen_is_marked;

        SEN_TABLE.rules_named = sen_rules_named;
        SEN_TABLE.rules_id    = sen_rules_id;
        SEN_TABLE.rules_ok    = sen_rules_ok;

        SEN_TABLE.chance_count = sen_chance_count;
        SEN_TABLE.chance       = sen_chance;
        SEN_TABLE.extra        = sen_extra;

        SEN_TABLE_READY = 1;      /* before the installer, or it recurses */
        sen_moves_install(&SEN_TABLE);
        sen_search_install(&SEN_TABLE);
    }
    return &SEN_TABLE;
}
