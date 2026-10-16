/* sth_engine.c - the sternhalma board, and nothing that judges a move.
 *
 * PERL-FREE by design: see include/sth_abi.h. This file compiles into the XS,
 * into a plain program, or to wasm, and knows nothing about any of them.
 *
 * THIS FILE'S SCOPE. The star, the mailbox, the neighbours, the points, the
 * ring, the hop classes, the layouts, put and lift, the seat to move, the
 * zobrist key, and the position string in and out.
 */

#include <stdlib.h>
#include <string.h>
#include "sth_internal.h"

/* ---- the mailbox and the tables: see sth_internal.h ------------------------- */

const int STH_STEP[STH_DIRS] = { 1, -(STH_SIDE - 1), -STH_SIDE, -1, STH_SIDE - 1, STH_SIDE };

int STH_SQ_OF[STH_HOLES];
int STH_HOLE_AT[STH_BOX];
int STH_HX[STH_HOLES];
int STH_HY[STH_HOLES];
static int ROW[STH_HOLES];
static int COL[STH_HOLES];
static int ROW_LEN[STH_ROWS];
static int ROW_START[STH_ROWS];
static int NEXT[STH_HOLES][STH_DIRS];
static int DEGREE[STH_HOLES];
static int POINT[STH_HOLES];
static int RING[STH_HOLES];
static int CLS[STH_HOLES];
int STH_POINT_LIST[STH_POINTS][STH_POINT_HOLES];
int STH_FRONT[STH_POINTS][STH_FRONT_HOLES];
static int PAIR[STH_PAIRS][2];
static int TABLES_READY = 0;
static int TABLES_OK = 0;

/* ---- the layouts --------------------------------------------------------------
 *
 * Which point each seat starts in, by the seat count, in seat order. Seat order
 * is turn order, and the points run clockwise, so the seats do too. Four seats
 * are two opposite pairs that are neighbours; six fill the star; three take
 * every other point and race into the three empty ones.
 */

const int STH_LAYOUT[STH_SEATS_MAX + 1][STH_SEATS_MAX] = {
    { -1, -1, -1, -1, -1, -1 },
    {  0, -1, -1, -1, -1, -1 },
    {  0,  3, -1, -1, -1, -1 },
    {  0,  2,  4, -1, -1, -1 },
    {  0,  1,  3,  4, -1, -1 },
    { -1, -1, -1, -1, -1, -1 },
    {  0,  1,  2,  3,  4,  5 },
};

static int sth_layout_ok(int seats, int pieces)
{
    if (seats < 1 || seats > STH_SEATS_MAX || STH_LAYOUT[seats][0] < 0) return 0;
    if (pieces == STH_PIECES) return 1;
    if (pieces == STH_PIECES_MAX) return seats <= 3;
    return 0;
}

static int sth_layout_point(int seats, int seat)
{
    if (seats < 1 || seats > STH_SEATS_MAX || STH_LAYOUT[seats][0] < 0) return -1;
    if (seat < 0 || seat >= seats) return -1;
    return STH_LAYOUT[seats][seat];
}

/* ---- the geometry tables -------------------------------------------------------- */

static int on_star(int x, int y)
{
    int z = -x - y;
    if (x < -8 || x > 8 || y < -8 || y > 8 || z < -8 || z > 8) return 0;
    if (x <= 4 && y <= 4 && z <= 4) return 1;
    if (x >= -4 && y >= -4 && z >= -4) return 1;
    return 0;
}

static int point_of_xy(int x, int y)
{
    int z = -x - y;
    if (y < -4) return 0;
    if (x > 4)  return 1;
    if (z < -4) return 2;
    if (y > 4)  return 3;
    if (x < -4) return 4;
    if (z > 4)  return 5;
    return STH_CENTRE;
}

/* The ring line in front of each point: the hexagon's edge that faces it. A
 * corner of the hexagon is on two edges, so two neighbouring points share it,
 * which is why fifteen pieces a seat cannot sit at neighbouring points. */
static int in_front_of(int point, int x, int y)
{
    int z = -x - y;
    if (x < -4 || x > 4 || y < -4 || y > 4 || z < -4 || z > 4) return 0;
    switch (point) {
    case 0: return y == -4;
    case 1: return x == 4;
    case 2: return z == -4;
    case 3: return y == 4;
    case 4: return x == -4;
    case 5: return z == 4;
    }
    return 0;
}

static int abs_int(int v) { return v < 0 ? -v : v; }

void sth_tables_init(void)
{
    int x, y, d, h, n = 0, pairs = 0, row;
    int point_n[STH_POINTS], front_n[STH_POINTS];
    int deg_n[STH_DIRS + 1], cls_n[STH_CLASSES];
    int centre = 0, ring = 0, ok = 1;

    if (TABLES_READY) return;
    memset(point_n, 0, sizeof point_n);
    memset(front_n, 0, sizeof front_n);
    memset(deg_n, 0, sizeof deg_n);
    memset(cls_n, 0, sizeof cls_n);
    for (h = 0; h < STH_BOX; h++) STH_HOLE_AT[h] = -1;

    for (y = -8; y <= 8; y++) {
        row = y + 8;
        ROW_START[row] = n;
        ROW_LEN[row] = 0;
        for (x = -8; x <= 8; x++) {
            int sq, p, f;
            if (!on_star(x, y)) continue;
            if (n >= STH_HOLES) { ok = 0; continue; }
            sq = (y + STH_MARGIN) * STH_SIDE + (x + STH_MARGIN);
            STH_SQ_OF[n] = sq;
            STH_HOLE_AT[sq] = n;
            STH_HX[n] = x;
            STH_HY[n] = y;
            ROW[n] = row;
            COL[n] = ROW_LEN[row]++;
            p = point_of_xy(x, y);
            POINT[n] = p;
            if (p == STH_CENTRE) centre++;
            else if (point_n[p] < STH_POINT_HOLES) STH_POINT_LIST[p][point_n[p]++] = n;
            else ok = 0;
            RING[n] = p == STH_CENTRE
                && (abs_int(x) == 4 || abs_int(y) == 4 || abs_int(x + y) == 4);
            if (RING[n]) ring++;
            for (f = 0; f < STH_POINTS; f++) {
                if (!in_front_of(f, x, y)) continue;
                if (front_n[f] < STH_FRONT_HOLES) STH_FRONT[f][front_n[f]++] = n;
                else ok = 0;
            }
            CLS[n] = ((x + 8) & 1) | (((y + 8) & 1) << 1);
            cls_n[CLS[n]]++;
            n++;
        }
    }
    if (n != STH_HOLES) ok = 0;

    for (h = 0; h < n && h < STH_HOLES; h++) {
        DEGREE[h] = 0;
        for (d = 0; d < STH_DIRS; d++) {
            int to = STH_HOLE_AT[STH_SQ_OF[h] + STH_STEP[d]];
            NEXT[h][d] = to;
            if (to >= 0) {
                DEGREE[h]++;
                if (to > h) {
                    if (pairs < STH_PAIRS) {
                        PAIR[pairs][0] = h;
                        PAIR[pairs][1] = to;
                    }
                    pairs++;
                }
            }
        }
        deg_n[DEGREE[h]]++;
    }

    if (centre != STH_CENTRE_HOLES || ring != STH_RING_HOLES || pairs != STH_PAIRS) ok = 0;
    for (d = 0; d < STH_POINTS; d++)
        if (point_n[d] != STH_POINT_HOLES || front_n[d] != STH_FRONT_HOLES) ok = 0;
    if (deg_n[6] != 73 || deg_n[5] != 6 || deg_n[4] != 36 || deg_n[2] != 6) ok = 0;
    if (cls_n[0] != 37 || cls_n[1] != 28 || cls_n[2] != 28 || cls_n[3] != 28) ok = 0;
    for (row = 0; row < STH_ROWS; row++)
        if (ROW_LEN[row] > STH_ROW_MAX) ok = 0;

    TABLES_OK = ok;
    TABLES_READY = 1;
}

static int is_hole(int hole) { return hole >= 0 && hole < STH_HOLES; }

static int sth_tables_ok(void) { sth_tables_init(); return TABLES_OK; }

static int sth_hole_of(int x, int y)
{
    sth_tables_init();
    if (x < -8 || x > 8 || y < -8 || y > 8) return -1;
    return STH_HOLE_AT[(y + STH_MARGIN) * STH_SIDE + (x + STH_MARGIN)];
}

static int sth_hole_x(int hole)  { sth_tables_init(); return is_hole(hole) ? STH_HX[hole] : 0; }
static int sth_hole_y(int hole)  { sth_tables_init(); return is_hole(hole) ? STH_HY[hole] : 0; }
static int sth_row_of(int hole)  { sth_tables_init(); return is_hole(hole) ? ROW[hole] : -1; }
static int sth_col_of(int hole)  { sth_tables_init(); return is_hole(hole) ? COL[hole] : -1; }
static int sth_row_len(int row)  { sth_tables_init(); return row >= 0 && row < STH_ROWS ? ROW_LEN[row] : 0; }
static int sth_row_start(int row){ sth_tables_init(); return row >= 0 && row < STH_ROWS ? ROW_START[row] : -1; }

static int sth_next(int hole, int dir)
{
    sth_tables_init();
    if (!is_hole(hole) || dir < 0 || dir >= STH_DIRS) return -1;
    return NEXT[hole][dir];
}

static int sth_degree(int hole)       { sth_tables_init(); return is_hole(hole) ? DEGREE[hole] : 0; }
static int sth_dir_opposite(int dir)  { return dir >= 0 && dir < STH_DIRS ? (dir + 3) % STH_DIRS : -1; }
static int sth_point_of(int hole)     { sth_tables_init(); return is_hole(hole) ? POINT[hole] : -1; }
static int sth_on_ring(int hole)      { sth_tables_init(); return is_hole(hole) ? RING[hole] : 0; }
static int sth_class_of(int hole)     { sth_tables_init(); return is_hole(hole) ? CLS[hole] : -1; }

static int copy_ints(const int *from, int n, int *out, int max)
{
    int i;
    for (i = 0; i < n && i < max; i++) out[i] = from[i];
    return n;
}

static int sth_point_holes(int point, int *out, int max)
{
    sth_tables_init();
    if (point < 0 || point >= STH_POINTS) return 0;
    return copy_ints(STH_POINT_LIST[point], STH_POINT_HOLES, out, max);
}

static int sth_front(int point, int *out, int max)
{
    sth_tables_init();
    if (point < 0 || point >= STH_POINTS) return 0;
    return copy_ints(STH_FRONT[point], STH_FRONT_HOLES, out, max);
}

static int sth_pairs(int *out, int max)
{
    sth_tables_init();
    return copy_ints(&PAIR[0][0], 2 * STH_PAIRS, out, max) / 2;
}

/* ---- the zobrist table -----------------------------------------------------
 *
 * DERIVED, NOT COMMITTED. A fixed function of a fixed seed is the same in every
 * process and on every machine, and cannot suffer the transcription error a
 * hand-pasted array can. splitmix64 is published and has no weak seeds.
 *
 * CHANGING THIS GENERATOR, ITS SEED OR THE ORDER THE TABLE IS FILLED IN
 * CHANGES EVERY KEY. t/02-position.t pins values so that is a red test.
 */

unsigned long long STH_ZOB[STH_SEATS_MAX][STH_HOLES];
unsigned long long STH_ZOB_MOVE[STH_SEATS_MAX];
static unsigned long long ZOB_SEATS[STH_SEATS_MAX + 1];
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
    unsigned long long s = 0x737465726E68616CULL;   /* "sternhal" */
    int seat, h;
    if (ZOB_READY) return;
    for (seat = 0; seat < STH_SEATS_MAX; seat++)
        for (h = 0; h < STH_HOLES; h++)
            STH_ZOB[seat][h] = splitmix64(&s);
    for (seat = 0; seat < STH_SEATS_MAX; seat++)
        STH_ZOB_MOVE[seat] = splitmix64(&s);
    for (seat = 0; seat <= STH_SEATS_MAX; seat++)
        ZOB_SEATS[seat] = splitmix64(&s);
    ZOB_READY = 1;
}

static unsigned long long sth_zobrist(int seat, int hole)
{
    zob_init();
    if (seat < 0 || seat >= STH_SEATS_MAX || !is_hole(hole)) return 0;
    return STH_ZOB[seat][hole];
}

static unsigned long long sth_zobrist_move(int seat)
{
    zob_init();
    if (seat < 0 || seat >= STH_SEATS_MAX) return 0;
    return STH_ZOB_MOVE[seat];
}

static unsigned long long sth_zobrist_seats(int seats)
{
    zob_init();
    if (seats < 0 || seats > STH_SEATS_MAX) return 0;
    return ZOB_SEATS[seats];
}

/* Boards handed out and not yet dropped. It exists so a test can show that a
 * destructor ran exactly once; it is a plain int and is not synchronised. */
static int STH_LIVE = 0;

static struct sth_board *board_alloc(int seats, int pieces)
{
    struct sth_board *b;
    int h;
    sth_tables_init();
    zob_init();
    if (!TABLES_OK || !sth_layout_ok(seats, pieces)) return NULL;
    b = (struct sth_board *) malloc(sizeof(struct sth_board));
    if (!b) return NULL;
    memset(b->cell, STH_OFF, sizeof b->cell);
    for (h = 0; h < STH_HOLES; h++) b->cell[STH_SQ_OF[h]] = STH_EMPTY;
    memset(b->count, 0, sizeof b->count);
    b->seats = seats;
    b->pieces = pieces;
    b->to_move = 0;
    sth_game_init(b);
    b->key = ZOB_SEATS[seats] ^ STH_ZOB_MOVE[0];
    STH_LIVE++;
    return b;
}

static int sth_at(const struct sth_board *b, int hole)
{
    if (!b || !is_hole(hole)) return STH_OFF;
    return b->cell[STH_SQ_OF[hole]];
}

static void sth_put(struct sth_board *b, int hole, int seat)
{
    int sq, old;
    if (!b || !is_hole(hole) || seat < 0 || seat >= b->seats) return;
    sq = STH_SQ_OF[hole];
    old = b->cell[sq];
    if (old != STH_EMPTY) {
        b->key ^= STH_ZOB[old][hole];
        b->count[old]--;
    }
    b->cell[sq] = (unsigned char) seat;
    b->key ^= STH_ZOB[seat][hole];
    b->count[seat]++;
}

static void sth_lift(struct sth_board *b, int hole)
{
    int sq, old;
    if (!b || !is_hole(hole)) return;
    sq = STH_SQ_OF[hole];
    old = b->cell[sq];
    if (old == STH_EMPTY) return;
    b->key ^= STH_ZOB[old][hole];
    b->count[old]--;
    b->cell[sq] = STH_EMPTY;
}

static struct sth_board *sth_board_empty(int seats, int pieces)
{
    return board_alloc(seats, pieces);
}

static struct sth_board *sth_board_new(int seats, int pieces)
{
    struct sth_board *b = board_alloc(seats, pieces);
    int seat, i, p;
    if (!b) return NULL;
    for (seat = 0; seat < seats; seat++) {
        p = STH_LAYOUT[seats][seat];
        for (i = 0; i < STH_POINT_HOLES; i++) sth_put(b, STH_POINT_LIST[p][i], seat);
        if (pieces == STH_PIECES_MAX)
            for (i = 0; i < STH_FRONT_HOLES; i++) sth_put(b, STH_FRONT[p][i], seat);
    }
    return b;
}

static struct sth_board *sth_board_copy(const struct sth_board *b)
{
    struct sth_board *n;
    if (!b) return NULL;
    n = (struct sth_board *) malloc(sizeof(struct sth_board));
    if (!n) return NULL;
    *n = *b;
    STH_LIVE++;
    return n;
}

static void sth_board_drop(struct sth_board *b)
{
    if (!b) return;
    free(b);
    STH_LIVE--;
}

static int sth_live(void) { return STH_LIVE; }

static int sth_to_move(const struct sth_board *b) { return b ? b->to_move : -1; }

static void sth_set_to_move(struct sth_board *b, int seat)
{
    if (!b || seat < 0 || seat >= b->seats) return;
    b->key ^= STH_ZOB_MOVE[b->to_move] ^ STH_ZOB_MOVE[seat];
    b->to_move = seat;
}

static int sth_seats(const struct sth_board *b)  { return b ? b->seats : 0; }
static int sth_pieces(const struct sth_board *b) { return b ? b->pieces : 0; }

static int sth_count(const struct sth_board *b, int seat)
{
    if (!b || seat < 0 || seat >= b->seats) return 0;
    return b->count[seat];
}

static unsigned long long sth_key(const struct sth_board *b) { return b ? b->key : 0; }

/* ---- the position string -------------------------------------------------
 *
 * The seventeen rows from the top, '/' between them. In a row, a digit 0 to 5
 * is that seat's piece and [n] is a run of n empty holes, 1 to 13. Then a
 * space, the seat to move, a space, the seat count, a space, the piece count,
 * and from version 5 the game after a ';' (sth_rules.c). The two-seat set-up is
 *
 *   0/00/000/0000/[13]/[12]/[11]/[10]/[9]/[10]/[11]/[12]/[13]/1111/111/11/1 0 2 10
 */

static int put_num(char *tmp, int n, int v)
{
    if (v >= 10) tmp[n++] = (char) ('0' + v / 10);
    tmp[n++] = (char) ('0' + v % 10);
    return n;
}

static int sth_to_string(const struct sth_board *b, char *out, int max)
{
    char tmp[STH_POS_MAX];
    int n = 0, row, i, run, c;
    if (!b || !out) return -1;
    for (row = 0; row < STH_ROWS; row++) {
        if (row > 0) tmp[n++] = '/';
        run = 0;
        for (i = 0; i < ROW_LEN[row]; i++) {
            c = b->cell[STH_SQ_OF[ROW_START[row] + i]];
            if (c == STH_EMPTY) { run++; continue; }
            if (run) { tmp[n++] = '['; n = put_num(tmp, n, run); tmp[n++] = ']'; run = 0; }
            tmp[n++] = (char) ('0' + c);
        }
        if (run) { tmp[n++] = '['; n = put_num(tmp, n, run); tmp[n++] = ']'; }
    }
    tmp[n++] = ' ';
    tmp[n++] = (char) ('0' + b->to_move);
    tmp[n++] = ' ';
    tmp[n++] = (char) ('0' + b->seats);
    tmp[n++] = ' ';
    n = put_num(tmp, n, b->pieces);
    n = sth_game_suffix_write(b, tmp, n);
    if (n + 1 > max) return -1;
    memcpy(out, tmp, (size_t) n);
    out[n] = '\0';
    return n;
}

/* A decimal of one or two digits with no leading zero, or -1. */
static int read_num(const char *s, const char **end)
{
    int v;
    if (*s < '1' || *s > '9') return -1;
    v = *s++ - '0';
    if (*s >= '0' && *s <= '9') v = v * 10 + (*s++ - '0');
    *end = s;
    return v;
}

static struct sth_board *sth_board_of_string(const char *str, int *err)
{
    int code = STH_OK;
    int cells[STH_HOLES];
    int width[STH_ROWS];
    int nrows = 1, filled = 0, seat_max = -1, to_move, seats, pieces, i, seat;
    int count[STH_SEATS_MAX];
    const char *s, *tail, *end, *game;
    size_t len;
    struct sth_board *b;

    sth_tables_init();
    if (!str || !*str) { code = STH_POS_NULL; goto refused; }
    len = strlen(str);
    if (len >= STH_POS_MAX) { code = STH_POS_LONG; goto refused; }

    tail = strchr(str, ' ');
    if (!tail) tail = str + len;

    for (s = str; s < tail; s++) {
        if (*s == '/' || (*s >= '0' && *s <= '5')) continue;
        if (*s == '[') {
            int v = read_num(s + 1, &end);
            if (v < 1 || v > STH_ROW_MAX || end >= tail || *end != ']') {
                code = STH_POS_LETTER; goto refused;
            }
            s = end;
            continue;
        }
        code = STH_POS_LETTER; goto refused;
    }

    memset(width, 0, sizeof width);
    for (s = str; s < tail; s++)
        if (*s == '/') nrows++;
    if (nrows != STH_ROWS) { code = STH_POS_ROWS; goto refused; }

    nrows = 1;
    for (s = str; s < tail; s++) {
        if (*s == '/') { nrows++; continue; }
        if (*s == '[') {
            int v = read_num(s + 1, &end);
            width[nrows - 1] += v;
            s = end;
            continue;
        }
        width[nrows - 1]++;
    }
    for (i = 0; i < STH_ROWS; i++)
        if (width[i] != ROW_LEN[i]) { code = STH_POS_WIDTH; goto refused; }

    s = tail;
    if (s[0] != ' ' || s[1] < '0' || s[1] > '5' || s[2] != ' ' || s[3] < '1' || s[3] > '6'
        || s[4] != ' ') {
        code = STH_POS_FIELDS; goto refused;
    }
    to_move = s[1] - '0';
    seats = s[3] - '0';
    pieces = read_num(s + 5, &end);
    if (pieces < 0 || (*end != '\0' && *end != ';') || !sth_layout_ok(seats, pieces) || to_move >= seats) {
        code = STH_POS_FIELDS; goto refused;
    }
    game = *end == ';' ? end + 1 : NULL;

    for (s = str; s < tail; s++) {
        if (*s == '/') continue;
        if (*s == '[') {
            int v = read_num(s + 1, &end);
            for (i = 0; i < v; i++) cells[filled++] = STH_EMPTY;
            s = end;
            continue;
        }
        seat = *s - '0';
        if (seat > seat_max) seat_max = seat;
        cells[filled++] = seat;
    }
    if (seat_max >= seats) { code = STH_POS_SEAT; goto refused; }

    memset(count, 0, sizeof count);
    for (i = 0; i < STH_HOLES; i++)
        if (cells[i] != STH_EMPTY) count[cells[i]]++;
    for (seat = 0; seat < seats; seat++)
        if (count[seat] != pieces) { code = STH_POS_COUNT; goto refused; }

    b = board_alloc(seats, pieces);
    if (!b) { code = STH_POS_FIELDS; goto refused; }
    for (i = 0; i < STH_HOLES; i++)
        if (cells[i] != STH_EMPTY) sth_put(b, i, cells[i]);
    sth_set_to_move(b, to_move);
    if (game) {
        int g = sth_game_suffix_read(b, game);
        if (g != STH_OK) { sth_board_drop(b); code = g; goto refused; }
    }
    if (err) *err = STH_OK;
    return b;

refused:
    if (err) *err = code;
    return NULL;
}

/* ---- the table ---------------------------------------------------------------- */

static const struct sth_abi STH_ABI = {
    STH_ABI_VERSION,

    sth_board_new,
    sth_board_empty,
    sth_board_of_string,
    sth_board_copy,
    sth_board_drop,
    sth_live,

    sth_at,
    sth_put,
    sth_lift,

    sth_to_move,
    sth_set_to_move,
    sth_seats,
    sth_pieces,
    sth_count,

    sth_key,
    sth_zobrist,
    sth_zobrist_move,
    sth_zobrist_seats,

    sth_to_string,

    sth_tables_ok,
    sth_layout_ok,
    sth_layout_point,
    sth_hole_of,
    sth_hole_x,
    sth_hole_y,
    sth_row_of,
    sth_col_of,
    sth_row_len,
    sth_row_start,
    sth_next,
    sth_degree,
    sth_dir_opposite,
    sth_point_of,
    sth_on_ring,
    sth_class_of,
    sth_point_holes,
    sth_front,
    sth_pairs,

    sth_steps,
    sth_hops,
    sth_do_move,
    sth_undo_move,

    sth_reach,
    sth_path,
    sth_legal,

    sth_home_complete,
    sth_finished,
    sth_place_of,
    sth_distance_left,
    sth_can_pass,
    sth_play,
    sth_pass,
    sth_resign,
    sth_unplay,
    sth_game_over,
    sth_game_how,
    sth_ply,
    sth_cap,
    sth_set_cap,

    sth_weights_default,
    sth_evaluate,
    sth_search,
    sth_random_forward,
    sth_own_key,
};

const struct sth_abi *sth_abi_table(void)
{
    sth_tables_init();
    zob_init();
    return &STH_ABI;
}
