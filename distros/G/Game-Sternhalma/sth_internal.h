#ifndef STH_INTERNAL_H
#define STH_INTERNAL_H

/* What the engine's own files share and a consumer never sees: the board
 * struct, the mailbox and the tables. NOT installed: include/sth_abi.h is the
 * public face, and a board is opaque there.
 *
 * Every name here that the linker sees starts sth_ or STH_, because the XS
 * bundle links these files together and another bundle in the same process
 * may have a SQ_OF of its own.
 */

#include "sth_abi.h"

/* ---- the mailbox -------------------------------------------------------------
 *
 * 21 by 21, indexed (y + 10) * 21 + (x + 10). The star uses -8 to 8 on each
 * axis, so every hole has two squares of margin round it. A square that is not
 * a hole is STH_OFF in every board.
 */

#define STH_SIDE   21
#define STH_MARGIN 10
#define STH_BOX    (STH_SIDE * STH_SIDE)

extern const int STH_STEP[STH_DIRS];
extern int STH_SQ_OF[STH_HOLES];
extern int STH_HOLE_AT[STH_BOX];
extern unsigned long long STH_ZOB[STH_SEATS_MAX][STH_HOLES];
extern unsigned long long STH_ZOB_MOVE[STH_SEATS_MAX];
extern int STH_HX[STH_HOLES];
extern int STH_HY[STH_HOLES];
extern int STH_POINT_LIST[STH_POINTS][STH_POINT_HOLES];
extern int STH_FRONT[STH_POINTS][STH_FRONT_HOLES];
extern const int STH_LAYOUT[STH_SEATS_MAX + 1][STH_SEATS_MAX];

/* ---- the position ---------------------------------------------------------
 *
 * The mailbox, the seat count, the piece count, the seat to move, the pieces
 * of each seat, and a key maintained incrementally. No pointers, so a copy is
 * a struct assignment and two boards never share anything.
 */

struct sth_board {
    unsigned char cell[STH_BOX];
    int seats;
    int pieces;
    int to_move;
    int count[STH_SEATS_MAX];
    unsigned long long key;

    /* version 4: the game. Not in the key: the key names a position. */
    int ply;                          /* moves and passes made             */
    int cap;                          /* the ply the game stops at         */
    int pass_run;                     /* passes in a row, just now         */
    int finished_n;
    int finished[STH_SEATS_MAX];      /* seats home, in the order they got */
    int resigned_n;
    int resigned[STH_SEATS_MAX];      /* seats that resigned, in order     */
    int over;
    int how;                          /* STH_ONGOING and the rest          */
};

#define STH_IS_HOLE(h) ((h) >= 0 && (h) < STH_HOLES)
#define STH_IS_PIECE(c) ((c) < STH_SEATS_MAX)

void sth_tables_init(void);

/* ---- version 2, sth_moves.c ------------------------------------------------ */

int sth_steps(const struct sth_board *b, int hole, int *out, int max);
int sth_hops(const struct sth_board *b, int hole, int from, int *out, int max);
int sth_do_move(struct sth_board *b, int from, int to);
int sth_undo_move(struct sth_board *b, int from, int to);

/* ---- version 3, sth_moves.c ------------------------------------------------ */

int sth_reach(const struct sth_board *b, int from, int *out, int max);
int sth_path(const struct sth_board *b, int from, int to, int *out, int max);
int sth_legal(const struct sth_board *b, int *out_from, int *out_to, int max);

/* ---- version 4, sth_rules.c ------------------------------------------------ */

void sth_game_init(struct sth_board *b);
int  sth_home_complete(const struct sth_board *b, int seat);
int  sth_finished(const struct sth_board *b, int seat);
int  sth_place_of(const struct sth_board *b, int seat);
int  sth_distance_left(const struct sth_board *b, int seat);
int  sth_can_pass(const struct sth_board *b);
int  sth_play(struct sth_board *b, int from, int to, struct sth_undo *undo);
int  sth_pass(struct sth_board *b, struct sth_undo *undo);
int  sth_resign(struct sth_board *b, int seat, struct sth_undo *undo);
int  sth_unplay(struct sth_board *b, const struct sth_undo *undo);
int  sth_game_over(const struct sth_board *b);
int  sth_game_how(const struct sth_board *b);
int  sth_ply(const struct sth_board *b);
int  sth_cap(const struct sth_board *b);
void sth_set_cap(struct sth_board *b, int cap);

/* ---- version 5, sth_rules.c: the game in the position string --------------- */

int  sth_game_suffix_write(const struct sth_board *b, char *out, int n);
int  sth_game_suffix_read(struct sth_board *b, const char *s);

int  sth_play_trusted(struct sth_board *b, int from, int to, struct sth_undo *undo);

/* ---- version 6, sth_search.c ------------------------------------------------- */

void sth_weights_default(struct sth_weights *w);
int  sth_evaluate(const struct sth_board *b, int seat, const struct sth_weights *w);
int  sth_search(const struct sth_board *b, const struct sth_weights *w, unsigned long long budget,
                unsigned long long seed, int max_depth, int mode,
                const unsigned long long *avoid, int avoid_n,
                int *best_from, int *best_to, struct sth_search_info *info);
int  sth_random_forward(const struct sth_board *b, unsigned long long seed, int *best_from, int *best_to);
unsigned long long sth_own_key(const struct sth_board *b, int seat);

#endif
