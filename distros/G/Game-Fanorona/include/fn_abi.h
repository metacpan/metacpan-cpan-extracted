#ifndef FN_ABI_H
#define FN_ABI_H

/* Public C ABI for Game::Fanorona, the board of points and lines, and anything
 * that wants to keep a fanorona position without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in fn_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to wasm.
 * The table is resolved at RUNTIME via Game::Fanorona::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of bd_abi.h and ru_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. FN_ABI_VERSION bumps on any append, and
 * a consumer requires abi_version >= the version it was written against, NEVER
 * ==.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * AT VERSION 1, THE BOARD AND NOTHING ELSE: points, which of them are strong,
 * which are joined, the two colours of stone, the side to move, a zobrist key,
 * and the position string in and out.
 *
 * AT VERSION 2, ONE STONE AND ONE STEP: where a stone may go, whether the step
 * takes, by which of the two methods, and which stones; the obligation to take
 * when anything can; why a step was refused; do and undo; and a perft that
 * counts steps. NO CHAIN YET: a step that takes passes the turn like any
 * other, and nothing here lets the same stone step again. NOTHING HERE KNOWS
 * HOW A GAME ENDS.
 *
 * AT VERSION 3, A WHOLE MOVE: a stone that has taken may step again, and the
 * mover may stop. The chain is STATE on the board: which stone is in the
 * middle of its move, which way it last went, and every point it has stood
 * on. `play_step`, `play_stop` and `play_undo` are the game's step; the
 * version 2 calls are untouched beside them and still pass the turn every
 * time. Whole moves are counted and listed on top. NOTHING HERE KNOWS HOW A
 * GAME ENDS.
 *
 * AT VERSION 4, A GAME: a board with the moves that made it, how it ends, and
 * who won. game_step is the first call in this table that REFUSES a step. A
 * board on its own still judges nothing about endings: play_step plays on
 * after the last stone is taken, and only a game stops.
 *
 * AT VERSION 5, CHOOSING A MOVE: an evaluation in integers, and a search
 * bounded in positions looked at and never in seconds.
 *
 * `put` and `lift` are STRUCTURE PRIMITIVES and JUDGE NOTHING. A caller may
 * fill the board with white stones.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the zobrist key which is
 * an unsigned 64-bit value. THERE ARE NO FLOATS ANYWHERE IN THIS ENGINE.
 *
 * A BOARD HAS A SIZE. The game is nine files by five ranks. The engine also
 * builds every board of odd width 3 to 9 and height 3 or 5, because the small
 * ones are the cheapest check on the rules there is.
 *
 * A POINT IS AN OPAQUE PADDED INDEX, AND IT IS THE SAME INDEX ON EVERY SIZE.
 * The grid is always 11 by 7 cells, the largest board with a sentinel ring of
 * FN_BORDER round it, and a smaller board fills the rest with FN_BORDER too:
 *
 *     stride        = 11
 *     square(f, r)  = (r + 1) * stride + (f + 1)
 *     the eight     = +stride, +stride+1, +1, -stride+1, -stride, -stride-1, -1, +stride-1
 *
 * A point is therefore NOT rank * 9 + file, and nothing outside the engine may
 * assume it is. Use (FN->square_of) to build one and (FN->file_of) /
 * (FN->rank_of) to take one apart. a1 is the same number on a 3 by 3 board as
 * on the 9 by 5.
 *
 * FILE 0 IS a AND RANK 0 IS 1. Rank 0 is the bottom row of the diagram, where
 * White stands, and a position string's FIRST row is the top rank.
 *
 * A POINT IS STRONG WHEN file + rank IS EVEN. A strong point has diagonal
 * lines; a weak one has none. That is geometry and not contents, it does not
 * depend on the size, and the centre of every board this engine builds is
 * strong.
 *
 * A DIRECTION IS 0 TO 7, clockwise from north: N, NE, E, SE, S, SW, W, NW.
 * The odd ones are the diagonals, and the opposite of d is (d + 4) % 8.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h turns
 * into function-like macros under PERL_IMPLICIT_SYS. That is why the destructor
 * is board_drop. Call through the table with the member in parentheses anyway:
 * (FN->board_drop)(b). No identifier here is `near`, `far` or `small` either.
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new, board_empty, board_of_string and board_copy return a board the
 * caller drops with board_drop. A board holds no pointers, so a copy is a flat
 * byte copy and two boards never share anything. to_string writes into a caller
 * buffer sized at least FN_POS_MAX. Nothing is retained between calls and
 * nothing is global except the zobrist table, which is derived deterministically
 * from a fixed seed, and the count of live boards, which exists for a leak test
 * and is not synchronised.
 */

/* Version 1 is the board. Version 2 appends the step, the two captures, do and
 * undo. Version 3 appends the chain and the whole move. Version 4 appends the
 * game and its endings. Version 5 appends the evaluation and the search.
 * Nothing that existed at an earlier version moves or changes meaning. */
#define FN_ABI_VERSION 5

/* ---- cells. FN_EMPTY is 0 so a zeroed point is an empty point ---------------- */

#define FN_EMPTY   0
#define FN_WHITE   1
#define FN_BLACK   2
#define FN_BORDER  3

#define FN_IS_STONE(p) ((p) == FN_WHITE || (p) == FN_BLACK)

/* A SIDE IS ITS STONE. The side to move is FN_WHITE or FN_BLACK and there is no
 * second numbering to keep in step with the first. */
#define FN_OTHER(s) (FN_WHITE + FN_BLACK - (s))

/* ---- the grid ---------------------------------------------------------------- */

#define FN_COLS_MAX    9
#define FN_ROWS_MAX    5
#define FN_STRIDE      (FN_COLS_MAX + 2)                 /* 11 */
#define FN_CELLS       (FN_STRIDE * (FN_ROWS_MAX + 2))   /* 77 */
#define FN_POINTS_MAX  (FN_COLS_MAX * FN_ROWS_MAX)       /* 45 */

/* On the largest board: 40 along the ranks, 36 up the files, and one diagonal
 * in each of the 32 unit cells. */
#define FN_SEGMENTS_MAX 108

/* ---- directions ---------------------------------------------------------------- */

#define FN_N   0
#define FN_NE  1
#define FN_E   2
#define FN_SE  3
#define FN_S   4
#define FN_SW  5
#define FN_W   6
#define FN_NW  7
#define FN_DIRS 8

/* The longest string this writer emits is 5 rows of 9, 4 slashes, a space and
 * a side: 51 characters. Sized for a caller's stack buffer. */
#define FN_POS_MAX 64

/* ---- why a position string was refused ---------------------------------------
 *
 * FN_OK is 0. Every other value names one fault. A string is refused for its
 * SHAPE and never for its sense: forty-five white stones load, because that is
 * a position a test needs to build.
 *
 * THEY ARE ASKED IN THIS ORDER, because one string can have several faults.
 */

#define FN_OK          0
#define FN_POS_NULL    1   /* no string at all, or an empty one                 */
#define FN_POS_LONG    2   /* FN_POS_MAX characters or more                     */
#define FN_POS_LETTER  3   /* a character that is not w, b, / or 1 to 9         */
#define FN_POS_ROWS    4   /* not three rows and not five                       */
#define FN_POS_WIDTH   5   /* rows of different widths, or a width that is not  *
                            * 3, 5, 7 or 9                                      */
#define FN_POS_SIDE    6   /* the side field is missing, or is not w or b, or   *
                            * something follows it                              */

/* ---- a step, version 2 ---------------------------------------------------------
 *
 * ONE STONE GOING TO ONE ADJACENT POINT along a line. It is a PAIKA when it
 * takes nothing. It takes by APPROACH when the point beyond `to`, in the
 * direction of the step, holds an enemy stone; and by WITHDRAWAL when the
 * point behind `from` does. Either way it takes that stone and every enemy
 * stone in an unbroken line behind it, stopping at the first empty point, the
 * first stone of the mover's own, or the edge.
 *
 * A step that could take both ways is TWO steps, one of each kind, and
 * neither takes the other's line.
 */

#define FN_PAIKA       0
#define FN_APPROACH    1
#define FN_WITHDRAWAL  2

/* The longest line one step takes. A step uses two points of its line, and a
 * rank is the longest line there is, nine points: seven are left. A PROOF and
 * not a guess, and a test builds the seven. */
#define FN_LINE_MAX 7

/* FROZEN AT THIS SIZE, and that is a different rule from the table's. The
 * table may grow because a consumer only reads members it knows about. This
 * struct is allocated by the CALLER and written by the engine, so a field
 * added later would have a newer engine write past the end of an older
 * caller's struct. */
struct fn_step {
    int from;
    int to;
    int dir;                    /* FN_N to FN_NW                              */
    int kind;                   /* FN_PAIKA, FN_APPROACH or FN_WITHDRAWAL     */
    int taken_n;                /* 0 for a paika                              */
    int taken[FN_LINE_MAX];     /* nearest first                              */
};

/* THE BUFFER A CALLER MUST SUPPLY, and a PROOF. A step leaves a stone and
 * enters an empty point, so it runs along a segment from its stone end to its
 * empty end, and a segment has only one such direction if it has any. There
 * are 108 segments on the largest board and each step is at most two entries,
 * one of each kind: 216. gen_steps never writes past the max it is given and
 * returns the number it FOUND, so a short buffer is detectable. */
#define FN_STEPS_MAX 216

/* ---- why a step is not one, version 2 -------------------------------------------
 *
 * FN_WHY_OK is 0 and means the step is legal. step_why agrees with gen_steps
 * on every stone, direction and kind, and a test holds it to that.
 *
 * THEY ARE ASKED IN THIS ORDER, because one step can have several faults.
 */

#define FN_WHY_OK             0
#define FN_WHY_OFF_BOARD      1   /* `from` is not a point of this board          */
#define FN_WHY_BAD_STEP       2   /* not a direction, or not a kind               */
#define FN_WHY_NO_STONE       3   /* nothing stands on `from`                     */
#define FN_WHY_NOT_YOURS      4   /* the stone is not of the side to move         */
#define FN_WHY_NO_LINE        5   /* no line goes that way from there: the edge,  *
                                   * or a diagonal asked of a weak point          */
#define FN_WHY_OCCUPIED       6   /* a stone stands where the step would go       */
#define FN_WHY_TAKES_NOTHING  7   /* asked to take that way, and no enemy is there */
#define FN_WHY_NOT_A_PAIKA    8   /* asked not to take, and the step does take    */
#define FN_WHY_MUST_CAPTURE   9   /* a paika, while some stone of the mover's can *
                                   * take                                         */

/* Version 3, and only play_why answers them: all four need a chain to be
 * open. With no chain open play_why IS step_why. */
#define FN_WHY_NOT_THE_STONE  10  /* a chain is open and this is another stone    */
#define FN_WHY_SAME_DIRECTION 11  /* the direction of the step directly before    */
#define FN_WHY_REVISIT        12  /* a point this chain has already stood on,     *
                                   * the one it started from included             */
#define FN_WHY_PAIKA_IN_CHAIN 13  /* a step that takes nothing, after one that    *
                                   * took                                         */

/* An undo carries everything do_step destroyed, so undo_step restores the
 * position EXACTLY, key included. It is a value type: copy it, do not free it.
 *
 * FROZEN, for the reason fn_step is. The reserved members are room for the
 * state a later version has to restore. play_step and play_stop use them, at
 * the indices below, for the chain as it was; do_step leaves them zero. */
struct fn_undo {
    struct fn_step step;
    int did;                        /* 0 when do_step did nothing             */
    int stone;                      /* the stone that stepped                 */
    int side;                       /* whose turn it was before the step      */
    int was[FN_LINE_MAX];           /* what stood on each taken point         */
    unsigned long long key;         /* the key before the step                */
    unsigned long long reserved64[2];
    int reserved[6];
};

#define FN_UNDO_SEEN    0   /* reserved64: the points the chain had stood on  */
#define FN_UNDO_PLAYED  0   /* reserved: 1 when play_step or play_stop wrote it */
#define FN_UNDO_AT      1   /* reserved: the chain's stone before, or -1      */
#define FN_UNDO_DIR     2   /* reserved: its last direction before, or -1     */
#define FN_UNDO_STOP    3   /* reserved: 1 when this is a stop and not a step */

/* ---- a whole move, version 3 ------------------------------------------------------
 *
 * EVERYTHING ONE SIDE DOES BEFORE THE OTHER PLAYS: one paika, or a chain of
 * steps by one stone, every one of which takes. A chain may be stopped after
 * any of its steps, so every beginning of a chain is a move as well.
 *
 * A move is held small: where it starts, and the direction and kind of each
 * step. What each step takes is a function of the position and is found by
 * replaying it (move_steps).
 *
 * FN_CHAIN_MAX IS A PROOF. A chain never stands on a point twice, the start
 * included, so on forty-five points it makes at most forty-four steps.
 *
 * FROZEN, for the reason fn_step is.
 */

#define FN_CHAIN_MAX 44

struct fn_move {
    int from;
    int n;                              /* steps: 1 for a paika             */
    int taken;                          /* stones taken, all steps together */
    unsigned char dir[FN_CHAIN_MAX];
    unsigned char kind[FN_CHAIN_MAX];
};

/* ---- how a game ends, version 4 --------------------------------------------------
 *
 * THE LIMITS, as a struct the caller fills. FROZEN at this size, as fn_step
 * is and for its reason. Fill one with (FN->variant_default) and change what
 * differs; a NULL anywhere means the default.
 *
 * A limit below zero means the default. A quiet limit or a repeat of ZERO
 * turns that draw OFF, which a table of forced results needs. The cap cannot
 * be turned off: a game keeps an array as long as it.
 */

struct fn_variant {
    int quiet_limit;    /* moves running, both sides counted, that took nothing */
    int repeat;         /* which occurrence of a position draws the game        */
    int ply_cap;        /* the number of moves at which a game is drawn         */
    int reserved[5];
};

/* THE QUIET LIMIT IS PROVISIONAL. It was to be read off a measurement, and
 * the measurement would not give one number: among players who take what
 * they can, 60 draws about one won game in forty; between two players who
 * count material and plan nothing, no limit short of hundreds would do. 60
 * stands until a real search has been measured.
 *
 * THE CAP IS A GUARD, and with the default quiet limit a game cannot reach
 * it: forty-four stones allow at most forty-four moves that take, with at
 * most sixty quiet moves before each and after the last, which is 2,744. */
#define FN_QUIET_DEFAULT    60
#define FN_REPEAT_DEFAULT   3
#define FN_PLY_CAP_DEFAULT  3000
#define FN_PLY_CAP_MAX      100000

/* FN_ONGOING is 0. Two wins and three draws. Agreement and resignation are
 * not here: they are something two people do, and the caller records them.
 *
 * THEY ARE ASKED IN THIS ORDER once a move is complete, because one move can
 * satisfy two.
 */

#define FN_ONGOING          0
#define FN_BY_STONES        1   /* a side has no stones left                    */
#define FN_BY_NO_MOVES      2   /* the side to move has stones and no move      */
#define FN_DRAW_REPETITION  3   /* the position occurred for the Nth time       */
#define FN_DRAW_QUIET       4   /* the quiet limit was reached                  */
#define FN_DRAW_PLY_CAP     5   /* the cap on moves was reached                 */

/* what game_step and game_stop answer */
#define FN_PLAY_OK       0
#define FN_PLAY_OVER     1   /* the game has ended; nothing was played          */
#define FN_PLAY_ILLEGAL  2   /* not a step of the side to move; nothing was     */

struct fn_game;

/* ---- the evaluation and the search, version 5 -----------------------------------
 *
 * THE WEIGHTS of the evaluation, each an int. FROZEN at this size, as fn_step
 * is and for its reason. Fill one with (FN->weights_default) and change what
 * differs; a NULL anywhere means the default.
 *
 * The evaluation is scored FOR WHITE. A positive number is good for White.
 */
struct fn_weights {
    int stone;          /* each stone on the board                              */
    int strong;         /* each stone standing on a strong point                */
    int centre;         /* each step a stone stands nearer the centre           */
    int room;           /* each empty point a stone could step to               */
    int reserved[8];
};

/* What a search did. Reported and not inferred: how deep it got and what it
 * cost are invisible from the move it returns. FROZEN: the caller allocates
 * it and the engine writes it. */
struct fn_search_info {
    unsigned long long nodes;
    int depth;            /* the deepest iteration that FINISHED, in whole moves */
    int score;            /* for the side to move                                */
    int stopped;          /* 1 if the budget ran out part way through one        */
    int reserved[4];
};

/* A win is a score and not a flag, less the number of steps it is away, so a
 * win sooner is preferred to a win later and a loss later to a loss sooner. */
#define FN_WIN_SCORE 30000

struct fn_board;

struct fn_abi {
    unsigned int abi_version;

    /* lifecycle. A size this engine does not build answers NULL. */
    struct fn_board * (*board_new)(int cols, int rows);       /* the set-up        */
    struct fn_board * (*board_empty)(int cols, int rows);     /* no stones at all  */
    struct fn_board * (*board_of_string)(const char *s, int *err);
    struct fn_board * (*board_copy)(const struct fn_board *b);
    void              (*board_drop)(struct fn_board *b);
    int               (*live)(void);                          /* boards not yet dropped */

    /* structure, judging nothing */
    int  (*at)(const struct fn_board *b, int sq);             /* FN_BORDER off the board */
    void (*put)(struct fn_board *b, int sq, int stone);
    void (*lift)(struct fn_board *b, int sq);
    int  (*side)(const struct fn_board *b);
    void (*set_side)(struct fn_board *b, int side);
    int  (*count)(const struct fn_board *b, int stone);

    /* the size of this board */
    int (*cols)(const struct fn_board *b);
    int (*rows)(const struct fn_board *b);
    int (*points)(const struct fn_board *b);
    int (*centre)(const struct fn_board *b);
    int (*on_board)(const struct fn_board *b, int sq);

    /* the key and the string */
    unsigned long long (*key)(const struct fn_board *b);       /* maintained   */
    unsigned long long (*key_full)(const struct fn_board *b);  /* recomputed   */
    unsigned long long (*zobrist)(int stone, int sq);
    unsigned long long (*zobrist_side)(void);
    unsigned long long (*zobrist_size)(int cols, int rows);
    int  (*to_string)(const struct fn_board *b, char *buf, int len);

    /* geometry that does not depend on the size */
    int (*size_ok)(int cols, int rows);
    int (*stride)(void);
    int (*square_of)(int file, int rank);                 /* or -1 */
    int (*file_of)(int sq);                               /* or -1 */
    int (*rank_of)(int sq);                               /* or -1 */
    int (*is_strong)(int sq);
    int (*dir_opposite)(int dir);                         /* or -1 */
    int (*dir_is_diagonal)(int dir);

    /* THE LINES. The point one step from `sq` in direction `dir`, or -1 when
     * no line of this board goes that way from there: off the edge, or a
     * diagonal asked of a weak point. */
    int (*next)(const struct fn_board *b, int sq, int dir);

    /* how many lines meet at `sq`: 3 to 8, and 0 off the board */
    int (*degree)(const struct fn_board *b, int sq);

    /* Every joined pair of points ONCE, as two ints a pair, the lower point
     * first, in point order. Writes at most `max` pairs and returns how many
     * there ARE, so a short buffer is detectable. */
    int (*segments)(const struct fn_board *b, int *out, int max);

    /* ---- version 2: one stone, one step ------------------------------------ */

    /* THE STEPS OF THE SIDE TO MOVE, with the obligation applied: if any of
     * them takes, none of them is a paika. In point order, then clockwise from
     * north, an approach before a withdrawal. Writes at most `max`, returns
     * how many there ARE. */
    int (*gen_steps)(const struct fn_board *b, struct fn_step *out, int max);

    /* Every step the stone on `sq` could make, WHOEVER IS TO MOVE AND WITH NO
     * OBLIGATION APPLIED: its paikas are listed beside another stone's
     * capture. Its enemy is the other colour from its own. At most 16. */
    int (*steps_of)(const struct fn_board *b, int sq, struct fn_step *out, int max);

    /* whether any stone of `side` has a step that takes */
    int (*can_capture)(const struct fn_board *b, int side);

    /* FN_WHY_OK, or the first reason this is not a step of the side to move.
     * When it is one and `out` is not NULL, the step is written there. */
    int (*step_why)(const struct fn_board *b, int from, int dir, int kind, struct fn_step *out);

    /* GEOMETRY ONLY, judging nothing about whose turn it is or what else
     * could take. Fills `out` and returns 1 when a stone stands on `from`, a
     * line leads that way to an empty point, and, for the two taking kinds,
     * there is an enemy line to take. A paika is built with nothing taken
     * EVEN WHERE THE STEP WOULD TAKE. Returns 0 otherwise. */
    int (*step_build)(const struct fn_board *b, int from, int dir, int kind, struct fn_step *out);

    /* Moves the stone, removes what the step names, passes the turn, and
     * returns how many stones were removed. IT DOES NOT ASK WHETHER THE STEP
     * IS LEGAL; that is step_why. It asks only that a stone stands on `from`
     * and nothing on `to`, and when that is not so it does nothing, returns
     * -1 and sets u->did to 0. */
    int  (*do_step)(struct fn_board *b, const struct fn_step *s, struct fn_undo *u);
    void (*undo_step)(struct fn_board *b, const struct fn_undo *u);

    /* Leaf nodes to `depth` plies, EACH STEP PASSING THE TURN. This is not the
     * game: a stone that takes may step again, and this count never lets it.
     * It is the generator's own ladder, kept so that a wrong number later
     * says which half is wrong. The board is left as it was found. */
    unsigned long long (*perft_steps)(struct fn_board *b, int depth);

    /* ---- version 3: the chain, and the whole move ---------------------------- */

    /* THE CHAIN AS STATE. chain_at is the stone in the middle of its move, or
     * -1 when no chain is open. chain_dir is the direction of its last step.
     * chain_seen is 1 for every point it has stood on, the start included. */
    int (*chain_at)(const struct fn_board *b);
    int (*chain_dir)(const struct fn_board *b);
    int (*chain_seen)(const struct fn_board *b, int sq);
    unsigned long long (*chain_mask)(const struct fn_board *b);

    /* A STRUCTURE PRIMITIVE, judging nothing: sets the three together. `at`
     * of -1 closes the chain whatever the other two say. The mask has a bit
     * a point, numbered by point_bit. */
    void (*chain_set)(struct fn_board *b, int at, int dir, unsigned long long mask);

    /* the bit of a point in a mask: rank * 9 + file, 0 to 44, or -1. NOT the
     * padded index, which runs to 76 and does not fit a 64-bit word. */
    int (*point_bit)(int sq);

    /* THE STEPS THE GAME ALLOWS NEXT. With no chain open they are gen_steps.
     * With one open they are the steps of that stone alone that TAKE, do not
     * go the way it last went, and do not arrive where it has stood. Stopping
     * is not in the list: ask can_stop. */
    int (*play_steps)(const struct fn_board *b, struct fn_step *out, int max);
    int (*can_stop)(const struct fn_board *b);

    /* step_why for the game: FN_WHY_OK or the first reason, the four of
     * version 3 among them. */
    int (*play_why)(const struct fn_board *b, int from, int dir, int kind, struct fn_step *out);

    /* THE GAME'S STEP. Moves the stone and removes what it takes, as do_step
     * does and with as little judgement. Then: a step that took nothing
     * passes the turn. A step that took leaves the turn where it is and the
     * chain open on that stone, UNLESS nothing in play_steps would follow, in
     * which case the chain is closed and the turn passed here. So a position
     * with a chain open always has a step to make. Returns the stones
     * removed, or -1 when it did nothing. */
    int  (*play_step)(struct fn_board *b, const struct fn_step *s, struct fn_undo *u);

    /* Closes an open chain and passes the turn. Returns 1, or 0 when no chain
     * was open and nothing was done. */
    int  (*play_stop)(struct fn_board *b, struct fn_undo *u);

    /* Takes back one play_step or one play_stop, chain and all. */
    void (*play_undo)(struct fn_board *b, const struct fn_undo *u);

    /* HOW MANY WHOLE MOVES the side to move has, from a position with no
     * chain open. A cap of 0 is no cap; otherwise the count stops at the cap,
     * for a caller that only wants to know whether there are too many. The
     * board is left as it was found. */
    unsigned long long (*count_moves)(struct fn_board *b, unsigned long long cap);

    /* The whole moves, each chain's shorter beginnings before its longer
     * ones. Writes at most `max` and returns how many it found, LOOKING NO
     * FURTHER THAN ONE PAST `max`: an answer of max + 1 means "more than
     * max", and count_moves is the call that says how many. A position can
     * have more whole moves than anyone will wait for. */
    int  (*gen_moves)(struct fn_board *b, struct fn_move *out, int max);

    /* The steps of a move with what each takes, by replaying it. `out` holds
     * FN_CHAIN_MAX. Returns the number of steps, or -1 when the move cannot
     * be played from here; the board is left as it was found either way. */
    int  (*move_steps)(struct fn_board *b, const struct fn_move *m, struct fn_step *out);

    /* Leaf nodes to `depth` WHOLE MOVES. This is the game's perft, short of
     * knowing how a game ends: a side with no move has no leaves. */
    unsigned long long (*perft_moves)(struct fn_board *b, int depth);

    /* ---- version 4: a game ----------------------------------------------------- */

    void (*variant_default)(struct fn_variant *v);

    /* A game from a COPY of `b`, or from the set-up of the nine by five when
     * `b` is NULL. The limits are copied in too and cannot be changed
     * afterwards. A game begins between moves: a chain the board came with
     * is dropped. The starting position is judged at once, so a game begun
     * with one side stoneless or stuck is over before a step is made. */
    struct fn_game * (*game_new)(const struct fn_board *b, const struct fn_variant *v);
    struct fn_game * (*game_copy)(const struct fn_game *g);
    void             (*game_drop)(struct fn_game *g);
    int              (*games_live)(void);                 /* games not yet dropped */

    /* The game's own board, BORROWED: read it, never write it, never drop
     * it, and do not keep it past the game. */
    const struct fn_board * (*game_board)(const struct fn_game *g);
    void (*game_variant)(const struct fn_game *g, struct fn_variant *out);
    int  (*game_ply)(const struct fn_game *g);            /* whole moves completed  */
    int  (*game_quiet)(const struct fn_game *g);          /* of them, running quiet */
    int  (*game_depth)(const struct fn_game *g);          /* steps and stops that   *
                                                           * game_undo can take back */
    int  (*game_outcome)(const struct fn_game *g);        /* FN_ONGOING and the rest */
    int  (*game_winner)(const struct fn_game *g);         /* FN_WHITE, FN_BLACK or 0 */
    unsigned long long (*game_key_at)(const struct fn_game *g, int ply);

    /* how many times the current position has occurred, this time included */
    int  (*repeats)(const struct fn_game *g);

    /* the steps the side to move may make, and NONE once the game is over */
    int  (*game_steps)(const struct fn_game *g, struct fn_step *out, int max);
    int  (*game_can_stop)(const struct fn_game *g);

    /* Plays a step and answers FN_PLAY_OK, or refuses and leaves the game
     * exactly as it was. On FN_PLAY_ILLEGAL, `why` receives the reason
     * play_why gave. A move is complete, and judged, when the turn passes. */
    int  (*game_step)(struct fn_game *g, int from, int dir, int kind, int *why);

    /* Ends a move whose chain is open. FN_PLAY_ILLEGAL when none is. */
    int  (*game_stop)(struct fn_game *g);

    /* Takes the last step or stop back, counts and outcome with it. 0 when
     * there is none. */
    int  (*game_undo)(struct fn_game *g);

    /* ---- version 5: choosing a move ------------------------------------------- */

    void (*weights_default)(struct fn_weights *w);

    /* the position scored for WHITE, in the units of the weights */
    int  (*evaluate)(const struct fn_board *b, const struct fn_weights *w);

    /* THE REST OF THE MOVE the side to move should make, written into `best`:
     * from a position between moves, a whole move; from the middle of a
     * chain, the steps still to make, and best->n of 0 means STOP NOW.
     * Returns 1, or 0 when the game is over and there is nothing to choose.
     * The game is not touched: the search plays into a copy.
     *
     *   budget     positions looked at. Asked at every position, so it is
     *              passed only by the few steps of settling one; and the
     *              first iteration always finishes, so a budget smaller than
     *              it takes is passed by that.
     *   seed       settles the choice among moves of equal score, and nothing
     *              else. 0 is taken as 1.
     *   max_depth  whole moves to look ahead; 0 for no limit but the budget.
     *
     * At the end of its depth the search does not score a position in which
     * a stone can be taken: it plays the largest captures out, each side in
     * turn, and scores what is left. That is a line and not a search. */
    int  (*search)(const struct fn_game *g, const struct fn_weights *w,
                   unsigned long long budget, unsigned long long seed, int max_depth,
                   struct fn_move *best, struct fn_search_info *info);
};

const struct fn_abi *fn_abi_table(void);

#endif
