/* mahjong_shanten.h - how far a hand is from ready, published.
 *
 * Perl-free like the other two headers. A hand is the concealed count
 * vector (index 1 to MJ_KINDS) plus the number of melds on the table, as
 * for the decomposer.
 *
 * THE NUMBER. -1 is a complete hand, 0 is ready (one tile away), 1 is one
 * tile from ready, and so on up to 8 for the standard form. It is the
 * minimum over the forms a hand can be complete in: four sets and a pair,
 * seven pairs, thirteen orphans, the honours-and-knitted singles.
 *
 * THE STANDARD FORM is the classic count: with S sets (melds included), P
 * partial sets (a pair, two adjacent tiles, two tiles a gap apart), and a
 * head pair, the distance is 8 - 2S - P - head, with P capped so S + P is at
 * most four, minimised over every way of grouping the concealed tiles. A
 * suit's tiles group independently of the others', so each suit's nine
 * counts are reduced ONCE to the Pareto set of (sets, partials) with and
 * without a head taken from it, and remembered; the whole hand is then the
 * best combination of four small sets. The memo is indexed by the base-5
 * value of the nine counts and filled as it is asked, so a process that
 * scores one hand fills a few entries and a bot that scores millions fills
 * what it needs.
 *
 * UKEIRE is the set of kinds whose addition lowers the number: what the
 * hand accepts. How many of each are still to be had is the caller's
 * arithmetic over what it can see.
 */

#ifndef MAHJONG_SHANTEN_H
#define MAHJONG_SHANTEN_H

#define MJ_SHANTEN_ABI_VERSION 1

#define MJ_FORM_S_STANDARD  0
#define MJ_FORM_S_PAIRS     1
#define MJ_FORM_S_ORPHANS   2
#define MJ_FORM_S_KNITTED   3
#define MJ_FORM_S_COUNT     4

/* the minimum over the forms; counts[1..34], melds 0 to 4 */
int mj_shanten(const unsigned char *counts, int melds);

/* the number for each form into out[MJ_FORM_S_COUNT]; a form the hand
 * cannot take (seven pairs with a meld) reports 99; returns the minimum */
int mj_shanten_forms(const unsigned char *counts, int melds, int *out);

/* the kinds (1 to 34, ascending) whose addition lowers mj_shanten; out has
 * room for MJ_KINDS; returns how many. A kind held four times is never one. */
int mj_ukeire(const unsigned char *counts, int melds, unsigned char *out);

#endif
