/* mahjong_decompose.h - every way a hand is complete, published.
 *
 * Perl-free like mahjong_abi.h. A hand here is a count vector over the kinds
 * (index 1 to MJ_KINDS, index 0 unused) of the CONCEALED tiles, plus the
 * number of melds already on the table. The decomposer never sees a meld's
 * tiles: a meld is a set whatever it holds, and the Perl side puts the melds
 * back beside the concealed sets it finds.
 *
 * EVERY SPLIT IS RETURNED, not the first. A hand can be complete more than
 * one way (111222333 is three pungs or three chows) and the scoring rules let
 * the winner take the higher (3.9.1.5.4), so a decomposer that stopped at the
 * first split would score every such hand low with nothing red.
 *
 * THE PLACEMENT is where the winning tile went in a split: which set or the
 * pair, and what kind of wait that was. The wait fans (edge, closed, single)
 * need it, and it is per split: the same fourteen tiles won on the same tile
 * can be an edge wait in one split and a two-sided one in another, and the
 * scorer chooses. So a split that could hold the winning tile in two places
 * is returned twice, once per placement. With winning == 0 no placement is
 * computed and each split is returned once.
 */

#ifndef MAHJONG_DECOMPOSE_H
#define MAHJONG_DECOMPOSE_H

#define MJ_DECOMPOSE_ABI_VERSION 1

#define MJ_MAX_SPLITS   64   /* more than any hand has; mj_decompose says if it ran out */
#define MJ_MAX_SETS      4   /* concealed sets in a standard split */
#define MJ_MAX_SINGLES  14

/* the forms of a complete hand, 3.7.2 */
#define MJ_FORM_STANDARD          1   /* four sets and a pair */
#define MJ_FORM_SEVEN_PAIRS       2
#define MJ_FORM_THIRTEEN_ORPHANS  3
#define MJ_FORM_HONOURS_KNITTED   4   /* fans 20 and 34: fourteen singles */
#define MJ_FORM_KNITTED_STRAIGHT  5   /* fan 35: three knitted sequences, a set, a pair */

/* the kinds of a concealed set */
#define MJ_SET_CHOW  1
#define MJ_SET_PUNG  2
#define MJ_SET_KNIT  3   /* 1-4-7, 2-5-8 or 3-6-9 of one suit, in a knitted straight */

/* where the winning tile went */
#define MJ_IN_NONE    0
#define MJ_IN_SET     1
#define MJ_IN_PAIR    2
#define MJ_IN_SINGLE  3

/* what the wait was, from the placement alone; whether the wait was the
 * hand's ONLY wait is a question about the thirteen tiles, mj_waits */
#define MJ_WAIT_NONE       0
#define MJ_WAIT_EDGE       1   /* the 3 of 1-2-3 or the 7 of 7-8-9 */
#define MJ_WAIT_CLOSED     2   /* the middle of a chow */
#define MJ_WAIT_TWO_SIDED  3   /* an end of a chow that is not an edge */
#define MJ_WAIT_PAIR       4   /* the second tile of the pair */
#define MJ_WAIT_PUNG       5   /* the third tile of a pung */
#define MJ_WAIT_SINGLE     6   /* a single in a special form */
#define MJ_WAIT_KNIT       7   /* a tile of a knitted sequence */

struct mj_set {
    unsigned char kind;       /* MJ_SET_* */
    unsigned char tiles[3];   /* kinds: a chow ascending, a pung three the same, a knit ascending */
};

struct mj_split {
    unsigned char form;                     /* MJ_FORM_* */
    unsigned char nsets;                    /* concealed sets, 0 to MJ_MAX_SETS */
    struct mj_set sets[MJ_MAX_SETS];
    unsigned char pair;                     /* the pair's kind, or 0 */
    unsigned char nsingles;                 /* the special forms' singles */
    unsigned char singles[MJ_MAX_SINGLES];
    unsigned char place_in;                 /* MJ_IN_* */
    unsigned char place_index;              /* the set or single the tile is in */
    unsigned char wait;                     /* MJ_WAIT_* */
};

/* counts[1..34] are the concealed tiles INCLUDING the winning tile; melds is
 * the number of sets on the table; winning is the kind won on, or 0 for no
 * placement. Returns the number of splits written, at most max; a hand that
 * is not complete returns 0. Returns -1 if more than max splits exist. */
int mj_decompose(const unsigned char *counts, int melds, int winning,
                 struct mj_split *out, int max);

/* 1 if the counts plus the melds are a complete hand in any form. */
int mj_is_complete(const unsigned char *counts, int melds);

/* counts[1..34] are THIRTEEN tiles' worth (14 - 3 * melds - 1); out[0..33]
 * receives the kinds (1 to 34) whose addition completes the hand, ascending;
 * returns how many. A kind already held four times is never a wait. */
int mj_waits(const unsigned char *counts, int melds, unsigned char *out);

#endif
