#ifndef SHG_INTERNAL_H
#define SHG_INTERNAL_H

/* What the engine's own files share and a consumer never sees: the board
 * struct, the mailbox and the tables. NOT installed: include/shg_abi.h is the
 * public face, and a board is opaque there.
 *
 * Every name here that the linker sees starts shg_ or SHG_, because the XS
 * bundle links these files together and another bundle in the same process
 * may have a SQ_OF of its own.
 */

#include "shg_abi.h"

/* ---- the mailbox -------------------------------------------------------------
 *
 * 11 wide and 13 tall, indexed (row + 2) * 11 + (col + 1), where row is rank
 * - 1 and col is 9 - file, so the mailbox runs in SFEN order too. One column
 * of margin each side and two rows above and below: the widest read is the
 * knight's, one file across and two ranks along. A box square that is not a
 * board square is SHG_OFF in every board.
 */

#define SHG_WIDTH  11
#define SHG_HEIGHT 13
#define SHG_BOX    (SHG_WIDTH * SHG_HEIGHT)
#define SHG_MARGIN_COLS 1
#define SHG_MARGIN_ROWS 2

extern int SHG_SQ_OF[SHG_SQUARES];
extern int SHG_SQ_AT[SHG_BOX];
extern unsigned long long SHG_ZOB[SHG_SIDES][SHG_KINDS][SHG_SQUARES];
extern unsigned long long SHG_ZOB_HAND[SHG_SIDES][SHG_HAND_KINDS][SHG_SET_PAWNS + 1];
extern unsigned long long SHG_ZOB_MOVE;

/* ---- the position ---------------------------------------------------------
 *
 * The mailbox, both hands, the side to move, the move number, where each
 * king is, and a key maintained incrementally. No pointers, so a copy is a
 * struct assignment and two boards never share anything.
 */

struct shg_board {
    unsigned char cell[SHG_BOX];
    unsigned char hand[SHG_SIDES][SHG_HAND_KINDS];
    int to_move;
    int move_number;
    int king[SHG_SIDES];
    unsigned long long key;
};

#define SHG_IS_SQ(s)    ((s) >= 0 && (s) < SHG_SQUARES)
#define SHG_IS_SIDE(s)  ((s) == SHG_BLACK || (s) == SHG_WHITE)
#define SHG_IS_KIND(k)  ((k) >= SHG_PAWN && (k) <= SHG_DRAGON)
#define SHG_IS_HAND(k)  ((k) >= SHG_PAWN && (k) <= SHG_ROOK)

/* shg_engine.c's tables, by square and by kind, for the files that move
 * pieces. Pointers, so the tables themselves keep their names there. */
extern int (*SHG_ZONE)[SHG_SQUARES];
extern int (*SHG_LAST)[SHG_SQUARES];
extern const int *SHG_PROMOTED_OF;
extern const int *SHG_UNPROMOTED_OF;
extern const int *SHG_SET_OF;

void shg_tables_init(void);

/* The structure primitives, which keep the key and the kings. */
void shg_put(struct shg_board *b, int sq, int piece);
void shg_lift(struct shg_board *b, int sq);
void shg_set_hand(struct shg_board *b, int side, int kind, int count);
void shg_set_to_move(struct shg_board *b, int side);

/* ---- how the pieces move, version 2, shg_moves.c ---------------------------
 *
 * Eight directions as mailbox offsets, the same for both sides. A kind's
 * steps (the knight's jump among them) and slides are offsets too, built per
 * side: White's are Black's with the rank turned over. SHG_SLIDE_MASK holds a
 * bit for each of the eight directions a kind slides in, which is what
 * `attacked` asks of the first piece it meets along a ray.
 */

#define SHG_DIRS 8

extern int SHG_DIR_OFF[SHG_DIRS];
extern int SHG_NSTEPS[SHG_SIDES][SHG_KINDS];
extern int SHG_STEP_OFF[SHG_SIDES][SHG_KINDS][SHG_DIRS];
extern int SHG_NSLIDES[SHG_SIDES][SHG_KINDS];
extern int SHG_SLIDE_OFF[SHG_SIDES][SHG_KINDS][4];
extern unsigned SHG_SLIDE_MASK[SHG_SIDES][SHG_KINDS];

/* 1 when every kind's table has the count its movement says. */
int shg_move_tables_init(void);

int shg_attacked(const struct shg_board *b, int sq, int by);
int shg_in_check(const struct shg_board *b, int side);
int shg_pseudo_moves(const struct shg_board *b, int *out, int max);
int shg_board_moves(const struct shg_board *b, int *out, int max);
int shg_do_move(struct shg_board *b, int move, struct shg_undo *undo);
int shg_undo_move(struct shg_board *b, const struct shg_undo *undo);

/* ---- version 3, shg_moves.c and shg_mate.c ------------------------------- */

int shg_drops(const struct shg_board *b, int *out, int max);
int shg_legal(const struct shg_board *b, int *out, int max);
int shg_has_legal_move(const struct shg_board *b);
int shg_drop_fault(const struct shg_board *b, int kind, int sq);
unsigned long long shg_perft(const struct shg_board *b, int depth, unsigned long long *counts);

/* ---- version 4 ---------------------------------------------------------- */

int shg_status(const struct shg_board *b);
int shg_move_fault(const struct shg_board *b, int move);

/* ---- version 5, shg_judge.c ---------------------------------------------- */

int shg_pack(const struct shg_board *b, unsigned char *out);
int shg_impasse_points(const struct shg_board *b, int side);
int shg_impasse_pieces(const struct shg_board *b, int side);
int shg_declare_fault(const struct shg_board *b);
int shg_repetition(const unsigned long long *keys, const unsigned char *packed,
                   const unsigned char *gave_check, int n, int *loser);

/* ---- version 6, shg_search.c, and what it borrows ------------------------ */

int shg_any_board_move(const struct shg_board *b);
int shg_evaluate(const struct shg_board *b, int flags);
int shg_search(const struct shg_board *b, unsigned long long budget, int max_depth,
               unsigned int seed, int flags, const unsigned long long *history,
               int n_history, struct shg_search_info *info);

#endif
