/* shg_engine.c - the shogi board, and nothing that judges a move.
 *
 * PERL-FREE by design: see include/shg_abi.h. This file compiles into the XS,
 * into a plain program, or to wasm, and knows nothing about any of them.
 *
 * THIS FILE'S SCOPE. The mailbox, the square names, the step, the zone, the
 * kinds and their promotion, the set, put and lift, the hands, the side to
 * move, the move number, the zobrist key, and the SFEN in and out.
 */

#include <stdlib.h>
#include <string.h>
#include "shg_internal.h"

/* ---- the mailbox and the tables: see shg_internal.h ------------------------- */

int SHG_SQ_OF[SHG_SQUARES];
int SHG_SQ_AT[SHG_BOX];
static int FILE_OF[SHG_SQUARES];
static int RANK_OF[SHG_SQUARES];
static int ZONE[SHG_SIDES][SHG_SQUARES];
static int LAST[SHG_SIDES][SHG_SQUARES];
static int TABLES_READY = 0;
static int TABLES_OK = 0;

/* ---- the kinds and the set ------------------------------------------------------
 *
 * Indexed by kind. A promoted kind's letter is its base kind's, written after
 * a '+'. SET is how many of each base kind a whole set has: nine pawns, two
 * lances, two knights, two silvers, two golds, one bishop, one rook and one
 * king a side.
 */

static const char LETTER[SHG_KINDS] = { 0, 'P', 'L', 'N', 'S', 'G', 'B', 'R', 'K',
                                        'P', 'L', 'N', 'S', 'B', 'R' };
static const int PROMOTED[SHG_KINDS]   = { 0, 9, 10, 11, 12, 0, 13, 14, 0, 0, 0, 0, 0, 0, 0 };
static const int UNPROMOTED[SHG_KINDS] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 6, 7 };
static const int SET[SHG_KINDS]        = { 0, 18, 4, 4, 4, 4, 2, 2, 2, 0, 0, 0, 0, 0, 0 };

int (*SHG_ZONE)[SHG_SQUARES] = ZONE;
int (*SHG_LAST)[SHG_SQUARES] = LAST;
const int *SHG_PROMOTED_OF = PROMOTED;
const int *SHG_UNPROMOTED_OF = UNPROMOTED;
const int *SHG_SET_OF = SET;

/* The hands are written in this order, which U gives: rook, bishop, gold,
 * silver, knight, lance, pawn. */
static const int HAND_ORDER[SHG_HAND_KINDS - 1] = { SHG_ROOK, SHG_BISHOP, SHG_GOLD,
    SHG_SILVER, SHG_KNIGHT, SHG_LANCE, SHG_PAWN };

/* The start of an even game, as SFEN reads it, rank a first. */
static const char *START[SHG_RANKS] = {
    "lnsgkgsnl", ".r.....b.", "ppppppppp", ".........", ".........",
    ".........", "PPPPPPPPP", ".B.....R.", "LNSGKGSNL",
};

static int kind_of_letter(int c)
{
    int k;
    if (c >= 'a' && c <= 'z') c -= 'a' - 'A';
    for (k = SHG_PAWN; k <= SHG_KING; k++)
        if (LETTER[k] == c) return k;
    return 0;
}

void shg_tables_init(void)
{
    int sq, box, side, df, dr, k, n = 0, ok = 1;
    int zone_n[SHG_SIDES] = { 0, 0 };
    int set_total = 0;

    if (TABLES_READY) return;
    for (box = 0; box < SHG_BOX; box++) SHG_SQ_AT[box] = -1;

    for (sq = 0; sq < SHG_SQUARES; sq++) {
        int row = sq / SHG_FILES, col = sq % SHG_FILES;
        box = (row + SHG_MARGIN_ROWS) * SHG_WIDTH + (col + SHG_MARGIN_COLS);
        SHG_SQ_OF[sq] = box;
        SHG_SQ_AT[box] = sq;
        FILE_OF[sq] = SHG_FILES - col;
        RANK_OF[sq] = row + 1;
        ZONE[SHG_BLACK][sq] = RANK_OF[sq] <= SHG_ZONE_RANKS;
        ZONE[SHG_WHITE][sq] = RANK_OF[sq] > SHG_RANKS - SHG_ZONE_RANKS;
        LAST[SHG_BLACK][sq] = RANK_OF[sq] - 1;
        LAST[SHG_WHITE][sq] = SHG_RANKS - RANK_OF[sq];
        for (side = 0; side < SHG_SIDES; side++) zone_n[side] += ZONE[side][sq];
        n++;
    }
    if (n != SHG_SQUARES) ok = 0;
    if (zone_n[SHG_BLACK] != 27 || zone_n[SHG_WHITE] != 27) ok = 0;

    /* Every step the mailbox serves, from every square, against the arithmetic
     * on files and ranks. A margin too narrow, or an offset with the wrong
     * sign, cannot pass this. */
    for (sq = 0; sq < SHG_SQUARES; sq++)
        for (df = -1; df <= 1; df++)
            for (dr = -2; dr <= 2; dr++) {
                int f = FILE_OF[sq] + df, r = RANK_OF[sq] + dr;
                int want = (f >= 1 && f <= SHG_FILES && r >= 1 && r <= SHG_RANKS)
                         ? (r - 1) * SHG_FILES + (SHG_FILES - f) : -1;
                int at = SHG_SQ_OF[sq] + dr * SHG_WIDTH - df;
                if (at < 0 || at >= SHG_BOX || SHG_SQ_AT[at] != want) ok = 0;
            }

    for (k = SHG_PAWN; k <= SHG_DRAGON; k++) {
        set_total += SET[k];
        if (UNPROMOTED[k] < SHG_PAWN || UNPROMOTED[k] > SHG_KING) ok = 0;
        if (PROMOTED[k] && UNPROMOTED[PROMOTED[k]] != k) ok = 0;
    }
    if (set_total != SHG_SET_PIECES || SET[SHG_PAWN] != SHG_SET_PAWNS) ok = 0;

    if (!shg_move_tables_init()) ok = 0;

    TABLES_OK = ok;
    TABLES_READY = 1;
}

static int shg_tables_ok(void) { shg_tables_init(); return TABLES_OK; }

static int shg_sq_of(int file, int rank)
{
    if (file < 1 || file > SHG_FILES || rank < 1 || rank > SHG_RANKS) return -1;
    return (rank - 1) * SHG_FILES + (SHG_FILES - file);
}

static int shg_file_of(int sq) { shg_tables_init(); return SHG_IS_SQ(sq) ? FILE_OF[sq] : 0; }
static int shg_rank_of(int sq) { shg_tables_init(); return SHG_IS_SQ(sq) ? RANK_OF[sq] : 0; }

static int shg_step(int sq, int dfile, int drank)
{
    shg_tables_init();
    if (!SHG_IS_SQ(sq) || dfile < -1 || dfile > 1 || drank < -2 || drank > 2) return -1;
    return SHG_SQ_AT[SHG_SQ_OF[sq] + drank * SHG_WIDTH - dfile];
}

static int shg_in_zone(int side, int sq)
{
    shg_tables_init();
    return SHG_IS_SIDE(side) && SHG_IS_SQ(sq) ? ZONE[side][sq] : 0;
}

static int shg_last_distance(int side, int sq)
{
    shg_tables_init();
    return SHG_IS_SIDE(side) && SHG_IS_SQ(sq) ? LAST[side][sq] : -1;
}

static int shg_promoted(int kind)   { return SHG_IS_KIND(kind) ? PROMOTED[kind] : 0; }
static int shg_unpromoted(int kind) { return SHG_IS_KIND(kind) ? UNPROMOTED[kind] : 0; }
static int shg_set_count(int kind)  { return SHG_IS_KIND(kind) ? SET[kind] : 0; }

/* ---- the zobrist table -----------------------------------------------------
 *
 * DERIVED, NOT COMMITTED. A fixed function of a fixed seed is the same in every
 * process and on every machine, and cannot suffer the transcription error a
 * hand-pasted array can. splitmix64 is published and has no weak seeds.
 *
 * A HAND IS HASHED BY ITS COUNT, one number per (side, kind, count), so adding
 * a piece to a hand XORs out the old count's number and XORs in the new one's.
 * A count of 0 is 0, so an empty hand adds nothing.
 *
 * CHANGING THIS GENERATOR, ITS SEED OR THE ORDER THE TABLE IS FILLED IN
 * CHANGES EVERY KEY. t/02-position.t pins values so that is a red test.
 */

unsigned long long SHG_ZOB[SHG_SIDES][SHG_KINDS][SHG_SQUARES];
unsigned long long SHG_ZOB_HAND[SHG_SIDES][SHG_HAND_KINDS][SHG_SET_PAWNS + 1];
unsigned long long SHG_ZOB_MOVE;
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
    unsigned long long s = 0x73686F6769303031ULL;   /* "shogi001" */
    int side, kind, sq, n;
    if (ZOB_READY) return;
    for (side = 0; side < SHG_SIDES; side++)
        for (kind = 0; kind < SHG_KINDS; kind++)
            for (sq = 0; sq < SHG_SQUARES; sq++)
                SHG_ZOB[side][kind][sq] = kind ? splitmix64(&s) : 0;
    for (side = 0; side < SHG_SIDES; side++)
        for (kind = 0; kind < SHG_HAND_KINDS; kind++)
            for (n = 0; n <= SHG_SET_PAWNS; n++)
                SHG_ZOB_HAND[side][kind][n] = kind && n ? splitmix64(&s) : 0;
    SHG_ZOB_MOVE = splitmix64(&s);
    ZOB_READY = 1;
}

static unsigned long long shg_zobrist(int side, int kind, int sq)
{
    zob_init();
    if (!SHG_IS_SIDE(side) || !SHG_IS_KIND(kind) || !SHG_IS_SQ(sq)) return 0;
    return SHG_ZOB[side][kind][sq];
}

static unsigned long long shg_zobrist_hand(int side, int kind, int count)
{
    zob_init();
    if (!SHG_IS_SIDE(side) || !SHG_IS_HAND(kind) || count < 0 || count > SET[kind]) return 0;
    return SHG_ZOB_HAND[side][kind][count];
}

static unsigned long long shg_zobrist_move(void) { zob_init(); return SHG_ZOB_MOVE; }

/* ---- a board --------------------------------------------------------------- */

/* Boards handed out and not yet dropped. It exists so a test can show that a
 * destructor ran exactly once; it is a plain int and is not synchronised. */
static int SHG_LIVE = 0;

static struct shg_board *board_alloc(void)
{
    struct shg_board *b;
    int sq;
    shg_tables_init();
    zob_init();
    if (!TABLES_OK) return NULL;
    b = (struct shg_board *) malloc(sizeof(struct shg_board));
    if (!b) return NULL;
    memset(b->cell, SHG_OFF, sizeof b->cell);
    for (sq = 0; sq < SHG_SQUARES; sq++) b->cell[SHG_SQ_OF[sq]] = SHG_EMPTY;
    memset(b->hand, 0, sizeof b->hand);
    b->to_move = SHG_BLACK;
    b->move_number = 1;
    b->king[SHG_BLACK] = -1;
    b->king[SHG_WHITE] = -1;
    b->key = 0;
    SHG_LIVE++;
    return b;
}

static int is_piece(int piece)
{
    return piece >= 0 && (piece & ~0x1F) == 0 && SHG_IS_KIND(SHG_KIND_OF(piece));
}

static int shg_at(const struct shg_board *b, int sq)
{
    if (!b || !SHG_IS_SQ(sq)) return SHG_OFF;
    return b->cell[SHG_SQ_OF[sq]];
}

void shg_lift(struct shg_board *b, int sq)
{
    int box, old, side, kind;
    if (!b || !SHG_IS_SQ(sq)) return;
    box = SHG_SQ_OF[sq];
    old = b->cell[box];
    if (old == SHG_EMPTY) return;
    side = SHG_SIDE_OF(old);
    kind = SHG_KIND_OF(old);
    b->key ^= SHG_ZOB[side][kind][sq];
    if (kind == SHG_KING && b->king[side] == sq) b->king[side] = -1;
    b->cell[box] = SHG_EMPTY;
}

void shg_put(struct shg_board *b, int sq, int piece)
{
    int side, kind;
    if (!b || !SHG_IS_SQ(sq) || !is_piece(piece)) return;
    shg_lift(b, sq);
    side = SHG_SIDE_OF(piece);
    kind = SHG_KIND_OF(piece);
    b->cell[SHG_SQ_OF[sq]] = (unsigned char) piece;
    b->key ^= SHG_ZOB[side][kind][sq];
    if (kind == SHG_KING) b->king[side] = sq;
}

static int shg_hand(const struct shg_board *b, int side, int kind)
{
    if (!b || !SHG_IS_SIDE(side) || !SHG_IS_HAND(kind)) return 0;
    return b->hand[side][kind];
}

void shg_set_hand(struct shg_board *b, int side, int kind, int count)
{
    if (!b || !SHG_IS_SIDE(side) || !SHG_IS_HAND(kind) || count < 0 || count > SET[kind]) return;
    b->key ^= SHG_ZOB_HAND[side][kind][b->hand[side][kind]] ^ SHG_ZOB_HAND[side][kind][count];
    b->hand[side][kind] = (unsigned char) count;
}

static struct shg_board *shg_board_empty(void) { return board_alloc(); }

static struct shg_board *shg_board_new(void)
{
    struct shg_board *b = board_alloc();
    int row, col, c, placed = 0;
    if (!b) return NULL;
    for (row = 0; row < SHG_RANKS; row++)
        for (col = 0; col < SHG_FILES; col++) {
            c = START[row][col];
            if (c == '.') continue;
            shg_put(b, row * SHG_FILES + col,
                    SHG_PIECE(c >= 'a' ? SHG_WHITE : SHG_BLACK, kind_of_letter(c)));
            placed++;
        }
    /* The constructor counts what it built. */
    if (placed != SHG_SET_PIECES || b->king[SHG_BLACK] < 0 || b->king[SHG_WHITE] < 0) {
        free(b);
        SHG_LIVE--;
        return NULL;
    }
    return b;
}

static struct shg_board *shg_board_copy(const struct shg_board *b)
{
    struct shg_board *n;
    if (!b) return NULL;
    n = (struct shg_board *) malloc(sizeof(struct shg_board));
    if (!n) return NULL;
    *n = *b;
    SHG_LIVE++;
    return n;
}

static void shg_board_drop(struct shg_board *b)
{
    if (!b) return;
    free(b);
    SHG_LIVE--;
}

static int shg_live(void) { return SHG_LIVE; }

static int shg_to_move(const struct shg_board *b) { return b ? b->to_move : -1; }

void shg_set_to_move(struct shg_board *b, int side)
{
    if (!b || !SHG_IS_SIDE(side) || side == b->to_move) return;
    b->key ^= SHG_ZOB_MOVE;
    b->to_move = side;
}

static int shg_move_number(const struct shg_board *b) { return b ? b->move_number : 0; }

static void shg_set_move_number(struct shg_board *b, int n)
{
    if (!b || n < 1 || n > SHG_MOVE_MAX) return;
    b->move_number = n;
}

static int shg_king_sq(const struct shg_board *b, int side)
{
    if (!b || !SHG_IS_SIDE(side)) return -1;
    return b->king[side];
}

static unsigned long long shg_key(const struct shg_board *b) { return b ? b->key : 0; }

/* ---- the SFEN ---------------------------------------------------------------
 *
 * U, section 3: the board rank a first and each rank from file 9; uppercase
 * for Black and lowercase for White; '+' before a promoted piece; a digit for
 * a run of empty squares. Then the side to move, b or w; then the hands,
 * counted, rook to pawn, Black's first, or '-'; then the move number, which U
 * calls optional and this reader takes as 1 when it is missing. The start is
 *
 *   lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1
 */

static int put_int(char *tmp, int n, int v)
{
    char rev[12];
    int i = 0;
    do { rev[i++] = (char) ('0' + v % 10); v /= 10; } while (v && i < 11);
    while (i) tmp[n++] = rev[--i];
    return n;
}

static int shg_to_sfen(const struct shg_board *b, char *out, int max)
{
    char tmp[SHG_SFEN_MAX];
    int n = 0, row, col, run, c, side, i, any = 0;
    if (!b || !out) return -1;
    for (row = 0; row < SHG_RANKS; row++) {
        if (row > 0) tmp[n++] = '/';
        run = 0;
        for (col = 0; col < SHG_FILES; col++) {
            int kind;
            char letter;
            c = b->cell[SHG_SQ_OF[row * SHG_FILES + col]];
            if (c == SHG_EMPTY) { run++; continue; }
            if (run) { tmp[n++] = (char) ('0' + run); run = 0; }
            kind = SHG_KIND_OF(c);
            if (kind > SHG_KING) tmp[n++] = '+';
            letter = LETTER[kind];
            tmp[n++] = SHG_SIDE_OF(c) == SHG_WHITE ? (char) (letter + ('a' - 'A')) : letter;
        }
        if (run) tmp[n++] = (char) ('0' + run);
    }
    tmp[n++] = ' ';
    tmp[n++] = b->to_move == SHG_WHITE ? 'w' : 'b';
    tmp[n++] = ' ';
    for (side = 0; side < SHG_SIDES; side++)
        for (i = 0; i < SHG_HAND_KINDS - 1; i++) {
            int kind = HAND_ORDER[i], count = b->hand[side][kind];
            if (!count) continue;
            if (count > 1) n = put_int(tmp, n, count);
            tmp[n++] = side == SHG_WHITE ? (char) (LETTER[kind] + ('a' - 'A')) : LETTER[kind];
            any = 1;
        }
    if (!any) tmp[n++] = '-';
    tmp[n++] = ' ';
    n = put_int(tmp, n, b->move_number);
    if (n + 1 > max) return -1;
    memcpy(out, tmp, (size_t) n);
    out[n] = '\0';
    return n;
}

static int is_digit(int c) { return c >= '0' && c <= '9'; }

static struct shg_board *shg_board_of_sfen(const char *str, int *err)
{
    int code = SHG_OK;
    char field[4][SHG_SFEN_MAX];
    int nfields = 0, flen = 0, ranks = 1, i, side, kind, move = 1;
    int cells[SHG_SQUARES];
    int hands[SHG_SIDES][SHG_HAND_KINDS];
    int seen[SHG_SIDES][SHG_HAND_KINDS];
    int kings[SHG_SIDES] = { 0, 0 };
    int total[SHG_KINDS];
    const char *s;
    size_t len;
    struct shg_board *b;

    shg_tables_init();
    if (!str || !*str) { code = SHG_POS_NULL; goto refused; }
    len = strlen(str);
    if (len >= SHG_SFEN_MAX) { code = SHG_POS_LONG; goto refused; }

    /* ---- the fields: single spaces between, none before or after ---- */
    if (str[0] == ' ' || str[len - 1] == ' ') { code = SHG_POS_FIELDS; goto refused; }
    for (s = str; *s; s++) {
        if (*s == ' ') {
            if (s[1] == ' ' || nfields >= 3) { code = SHG_POS_FIELDS; goto refused; }
            field[nfields][flen] = '\0';
            nfields++;
            flen = 0;
            continue;
        }
        field[nfields][flen++] = *s;
    }
    field[nfields][flen] = '\0';
    nfields++;
    if (nfields != 3 && nfields != 4) { code = SHG_POS_FIELDS; goto refused; }

    /* ---- the board ---- */
    for (s = field[0]; *s; s++)
        if (*s == '/') ranks++;
    if (ranks != SHG_RANKS) { code = SHG_POS_RANKS; goto refused; }

    for (s = field[0]; *s; s++) {
        if (*s == '/' || *s == '+' || kind_of_letter(*s)) continue;
        if (*s >= '1' && *s <= '9' && !is_digit(s[1])) continue;
        code = SHG_POS_LETTER; goto refused;
    }

    {
        int width = 0;
        for (s = field[0]; ; s++) {
            if (*s == '/' || !*s) {
                if (width != SHG_FILES) { code = SHG_POS_WIDTH; goto refused; }
                if (!*s) break;
                width = 0;
                continue;
            }
            if (is_digit(*s)) width += *s - '0';
            else if (*s != '+') width++;
        }
    }

    for (s = field[0]; *s; s++) {
        if (*s != '+') continue;
        kind = kind_of_letter(s[1]);
        if (!kind || !PROMOTED[kind]) { code = SHG_POS_PROMOTE; goto refused; }
    }

    /* ---- the side to move ---- */
    if ((field[1][0] != 'b' && field[1][0] != 'w') || field[1][1]) {
        code = SHG_POS_SIDE; goto refused;
    }

    /* ---- the hands ---- */
    memset(hands, 0, sizeof hands);
    memset(seen, 0, sizeof seen);
    if (strcmp(field[2], "-") != 0) {
        for (s = field[2]; *s; ) {
            int count = 1;
            if (is_digit(*s)) {
                if (*s == '0') { code = SHG_POS_HAND; goto refused; }
                count = 0;
                while (is_digit(*s) && count <= SHG_SET_PAWNS) count = count * 10 + (*s++ - '0');
                if (count < 2) { code = SHG_POS_HAND; goto refused; }
            }
            kind = kind_of_letter(*s);
            if (!SHG_IS_HAND(kind)) { code = SHG_POS_HAND; goto refused; }
            side = *s >= 'a' ? SHG_WHITE : SHG_BLACK;
            if (seen[side][kind] || count > SET[kind]) { code = SHG_POS_HAND; goto refused; }
            seen[side][kind] = 1;
            hands[side][kind] = count;
            s++;
        }
    }

    /* ---- the move number ---- */
    if (nfields == 4) {
        s = field[3];
        if (*s < '1' || *s > '9' || strlen(s) > 6) { code = SHG_POS_MOVE; goto refused; }
        move = 0;
        for (; *s; s++) {
            if (!is_digit(*s)) { code = SHG_POS_MOVE; goto refused; }
            move = move * 10 + (*s - '0');
        }
    }

    /* ---- what the board holds ---- */
    {
        int sq = 0, promote = 0;
        for (s = field[0]; *s; s++) {
            if (*s == '/') continue;
            if (*s == '+') { promote = 1; continue; }
            if (is_digit(*s)) {
                for (i = 0; i < *s - '0'; i++) cells[sq++] = SHG_EMPTY;
                continue;
            }
            kind = kind_of_letter(*s);
            if (promote) kind = PROMOTED[kind];
            promote = 0;
            side = *s >= 'a' ? SHG_WHITE : SHG_BLACK;
            if (kind == SHG_KING) kings[side]++;
            cells[sq++] = SHG_PIECE(side, kind);
        }
    }
    if (kings[SHG_BLACK] > 1 || kings[SHG_WHITE] > 1) { code = SHG_POS_KINGS; goto refused; }

    memset(total, 0, sizeof total);
    for (i = 0; i < SHG_SQUARES; i++)
        if (cells[i] != SHG_EMPTY) total[UNPROMOTED[SHG_KIND_OF(cells[i])]]++;
    for (side = 0; side < SHG_SIDES; side++)
        for (kind = SHG_PAWN; kind <= SHG_ROOK; kind++) total[kind] += hands[side][kind];
    for (kind = SHG_PAWN; kind <= SHG_KING; kind++)
        if (total[kind] > SET[kind]) { code = SHG_POS_COUNT; goto refused; }

    b = board_alloc();
    if (!b) { code = SHG_POS_NULL; goto refused; }
    for (i = 0; i < SHG_SQUARES; i++)
        if (cells[i] != SHG_EMPTY) shg_put(b, i, cells[i]);
    for (side = 0; side < SHG_SIDES; side++)
        for (kind = SHG_PAWN; kind <= SHG_ROOK; kind++) shg_set_hand(b, side, kind, hands[side][kind]);
    shg_set_to_move(b, field[1][0] == 'w' ? SHG_WHITE : SHG_BLACK);
    b->move_number = move;
    if (err) *err = SHG_OK;
    return b;

refused:
    if (err) *err = code;
    return NULL;
}

/* ---- the table ---------------------------------------------------------------- */

static const struct shg_abi SHG_ABI = {
    SHG_ABI_VERSION,

    shg_board_new,
    shg_board_empty,
    shg_board_of_sfen,
    shg_board_copy,
    shg_board_drop,
    shg_live,

    shg_at,
    shg_put,
    shg_lift,

    shg_hand,
    shg_set_hand,

    shg_to_move,
    shg_set_to_move,
    shg_move_number,
    shg_set_move_number,
    shg_king_sq,

    shg_key,
    shg_zobrist,
    shg_zobrist_hand,
    shg_zobrist_move,

    shg_to_sfen,

    shg_tables_ok,
    shg_sq_of,
    shg_file_of,
    shg_rank_of,
    shg_step,
    shg_in_zone,
    shg_last_distance,
    shg_promoted,
    shg_unpromoted,
    shg_set_count,

    shg_attacked,
    shg_in_check,
    shg_pseudo_moves,
    shg_board_moves,
    shg_do_move,
    shg_undo_move,

    shg_drops,
    shg_legal,
    shg_has_legal_move,
    shg_drop_fault,
    shg_perft,

    shg_status,
    shg_move_fault,

    shg_pack,
    shg_impasse_points,
    shg_impasse_pieces,
    shg_declare_fault,
    shg_repetition,

    shg_evaluate,
    shg_search,
};

const struct shg_abi *shg_abi_table(void)
{
    shg_tables_init();
    zob_init();
    return &SHG_ABI;
}
