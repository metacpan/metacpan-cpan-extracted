/* mahjong_abi.h - the tile table, published.
 *
 * Perl-free on purpose: the same struct compiles into the XS, into a plain
 * program, or to wasm. Everything downstream that reasons about tiles (the
 * decomposer, the shanten, a client that wants to check a hand offline) reads
 * this one table, so there is exactly one place a kind's suit, rank and flags
 * are written down.
 *
 * KINDS ARE 1 TO 42 AND THE ORDER IS PART OF THE ABI. The suits run
 * characters, dots, bamboo, rank 1 to 9 within each, so `id + 1` is the next
 * rank of the same suit for a suit tile below 9, and `m9 + 1` is p1 and not a
 * character. The shifted-chow and shifted-pung checks walk ids inside a suit
 * on that promise. Then the winds east south west north, the dragons red green
 * white, the four flowers, the four seasons. Index 0 of the table is a
 * sentinel no tile has.
 *
 * A KIND, NOT A TILE. There are four tiles of every kind 1 to 34 and one of
 * every bonus kind 35 to 42, and they are identical: nothing in this
 * distribution ever names the third five of bamboo. The count table a hand
 * keeps is over kinds.
 *
 * ABI VERSION. Bump MJ_ABI_VERSION when a field moves or a flag changes
 * meaning; never when a value is corrected, which is a bug fix and not an
 * interface change.
 */

#ifndef MAHJONG_ABI_H
#define MAHJONG_ABI_H

#define MJ_ABI_VERSION 1

#define MJ_KINDS     34   /* the kinds four tiles exist of */
#define MJ_BONUS      8   /* flowers and seasons, one tile each */
#define MJ_PATTERNS  42   /* MJ_KINDS + MJ_BONUS: every face on the table */
#define MJ_PER_KIND   4
#define MJ_TILES    144   /* MJ_KINDS * MJ_PER_KIND + MJ_BONUS */

/* The suit byte. MJ_SUIT_NONE is the sentinel's. */
#define MJ_SUIT_NONE     0
#define MJ_SUIT_CHAR     1   /* characters, wan */
#define MJ_SUIT_DOT      2   /* dots, tong */
#define MJ_SUIT_BAM      3   /* bamboo, tiao */
#define MJ_SUIT_WIND     4
#define MJ_SUIT_DRAGON   5
#define MJ_SUIT_FLOWER   6
#define MJ_SUIT_SEASON   7

/* The flag bits. A kind carries every bit that is true of it. */
#define MJ_F_SUIT        0x0001   /* characters, dots or bamboo */
#define MJ_F_HONOUR      0x0002   /* a wind or a dragon */
#define MJ_F_WIND        0x0004
#define MJ_F_DRAGON      0x0008
#define MJ_F_TERMINAL    0x0010   /* a one or a nine */
#define MJ_F_SIMPLE      0x0020   /* two to eight */
#define MJ_F_BONUS       0x0040   /* a flower or a season */
#define MJ_F_FLOWER      0x0080
#define MJ_F_SEASON      0x0100
#define MJ_F_GREEN       0x0200   /* the All Green set: 2 3 4 6 8 of bamboo and the green dragon */
#define MJ_F_REVERSIBLE  0x0400   /* the Reversible Tiles set: 1 2 3 4 5 8 9 of dots, 2 4 5 6 8 9 of bamboo, the white dragon */

/* The wind index for kinds 28 to 31, east 0 south 1 west 2 north 3, and the
 * dragon index for 32 to 34, red 0 green 1 white 2. Held in `rank` for those
 * kinds, 1-based like a suit rank, so rank 0 means "not a rank". */

struct mj_kind {
    char           code[3];   /* "m5", "we", "dr", "f1"; NUL-terminated */
    unsigned char  suit;      /* MJ_SUIT_* */
    unsigned char  rank;      /* 1 to 9 for a suit tile, 1 to 4 for a wind, 1 to 3 for a dragon, 1 to 4 for a bonus; 0 for the sentinel */
    unsigned short flags;     /* MJ_F_* */
};

struct mj_abi {
    unsigned              version;    /* MJ_ABI_VERSION */
    unsigned              kinds;      /* MJ_KINDS */
    unsigned              patterns;   /* MJ_PATTERNS */
    unsigned              per_kind;   /* MJ_PER_KIND */
    unsigned              tiles;      /* MJ_TILES */
    const struct mj_kind *kind;       /* indexed 0 (the sentinel) to MJ_PATTERNS */
    int                 (*id_of)(const char *code);   /* 1 to MJ_PATTERNS, or 0 for a code that names no kind */
};

const struct mj_abi *mj_abi_table(void);

#endif
