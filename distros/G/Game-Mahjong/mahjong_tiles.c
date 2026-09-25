/* mahjong_tiles.c - the forty-two kinds, filled in once.
 *
 * The table is written out by hand rather than generated in a loop, so that
 * reading it IS checking it: every row says its code, its suit, its rank and
 * its flags, and t/01-tiles.t holds the same facts in Perl, written from the
 * rulebook and not from this file.
 */

#include <string.h>
#include "mahjong_abi.h"

#define S   (MJ_F_SUIT)
#define T   (MJ_F_SUIT | MJ_F_TERMINAL)
#define M   (MJ_F_SUIT | MJ_F_SIMPLE)
#define W   (MJ_F_HONOUR | MJ_F_WIND)
#define D   (MJ_F_HONOUR | MJ_F_DRAGON)
#define FL  (MJ_F_BONUS | MJ_F_FLOWER)
#define SE  (MJ_F_BONUS | MJ_F_SEASON)
#define G   (MJ_F_GREEN)
#define R   (MJ_F_REVERSIBLE)

static const struct mj_kind KIND[MJ_PATTERNS + 1] = {
    { "",   MJ_SUIT_NONE,   0, 0 },

    /* characters, wan. No character is green or reversible. */
    { "m1", MJ_SUIT_CHAR,   1, T },
    { "m2", MJ_SUIT_CHAR,   2, M },
    { "m3", MJ_SUIT_CHAR,   3, M },
    { "m4", MJ_SUIT_CHAR,   4, M },
    { "m5", MJ_SUIT_CHAR,   5, M },
    { "m6", MJ_SUIT_CHAR,   6, M },
    { "m7", MJ_SUIT_CHAR,   7, M },
    { "m8", MJ_SUIT_CHAR,   8, M },
    { "m9", MJ_SUIT_CHAR,   9, T },

    /* dots, tong. Reversible: 1 2 3 4 5 8 9 (fan 40). */
    { "p1", MJ_SUIT_DOT,    1, T | R },
    { "p2", MJ_SUIT_DOT,    2, M | R },
    { "p3", MJ_SUIT_DOT,    3, M | R },
    { "p4", MJ_SUIT_DOT,    4, M | R },
    { "p5", MJ_SUIT_DOT,    5, M | R },
    { "p6", MJ_SUIT_DOT,    6, M },
    { "p7", MJ_SUIT_DOT,    7, M },
    { "p8", MJ_SUIT_DOT,    8, M | R },
    { "p9", MJ_SUIT_DOT,    9, T | R },

    /* bamboo, tiao. Green: 2 3 4 6 8 (fan 3). Reversible: 2 4 5 6 8 9 (fan 40). */
    { "s1", MJ_SUIT_BAM,    1, T },
    { "s2", MJ_SUIT_BAM,    2, M | G | R },
    { "s3", MJ_SUIT_BAM,    3, M | G },
    { "s4", MJ_SUIT_BAM,    4, M | G | R },
    { "s5", MJ_SUIT_BAM,    5, M | R },
    { "s6", MJ_SUIT_BAM,    6, M | G | R },
    { "s7", MJ_SUIT_BAM,    7, M },
    { "s8", MJ_SUIT_BAM,    8, M | G | R },
    { "s9", MJ_SUIT_BAM,    9, T | R },

    /* the winds, in the order of the rounds and the seats */
    { "we", MJ_SUIT_WIND,   1, W },
    { "ws", MJ_SUIT_WIND,   2, W },
    { "ww", MJ_SUIT_WIND,   3, W },
    { "wn", MJ_SUIT_WIND,   4, W },

    /* the dragons: red, green (fan 3's), white (fan 40's) */
    { "dr", MJ_SUIT_DRAGON, 1, D },
    { "dg", MJ_SUIT_DRAGON, 2, D | G },
    { "dw", MJ_SUIT_DRAGON, 3, D | R },

    /* the flowers, in the rulebook's order: plum, orchid, bamboo, chrysanthemum (3.5.5.1) */
    { "f1", MJ_SUIT_FLOWER, 1, FL },
    { "f2", MJ_SUIT_FLOWER, 2, FL },
    { "f3", MJ_SUIT_FLOWER, 3, FL },
    { "f4", MJ_SUIT_FLOWER, 4, FL },

    /* the seasons: spring, summer, autumn, winter */
    { "t1", MJ_SUIT_SEASON, 1, SE },
    { "t2", MJ_SUIT_SEASON, 2, SE },
    { "t3", MJ_SUIT_SEASON, 3, SE },
    { "t4", MJ_SUIT_SEASON, 4, SE },
};

/* A linear scan over forty-two three-byte codes. The Perl side caches ids
 * where it loops, and forty-two compares is cheaper than the hash it would
 * take to beat it. */
static int mj_id_of(const char *code)
{
    int i;
    if (!code || !code[0] || !code[1] || code[2]) return 0;
    for (i = 1; i <= MJ_PATTERNS; i++) {
        if (KIND[i].code[0] == code[0] && KIND[i].code[1] == code[1]) return i;
    }
    return 0;
}

static const struct mj_abi ABI = {
    MJ_ABI_VERSION,
    MJ_KINDS,
    MJ_PATTERNS,
    MJ_PER_KIND,
    MJ_TILES,
    KIND,
    mj_id_of,
};

const struct mj_abi *mj_abi_table(void)
{
    return &ABI;
}
