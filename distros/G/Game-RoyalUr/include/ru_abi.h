#ifndef RU_ABI_H
#define RU_ABI_H

/* Public C ABI for Game::RoyalUr, the Royal Game of Ur, and anything that wants
 * to keep a position of it without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in any ru_*.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to wasm.
 * The table is resolved at RUNTIME via Game::RoyalUr::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of bd_abi.h and xq_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. RU_ABI_VERSION bumps on any append, and
 * a consumer requires abi_version >= the version it was written against, NEVER
 * ==.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * AT VERSION 1, THE BOARD AND NOTHING ELSE: twenty cells, what stands on each,
 * the two hands, the two homes, the side to move, the two routes as tables, an
 * exact key, and the position string in and out. NO RULES. A caller may put
 * eight light pieces on the board and this version has no opinion.
 *
 * AT VERSION 2, THE CHANCE OF A ROLL: for a number of dice and what a throw with
 * nothing marked is worth, each roll that can come up and how often, in whole
 * numbers. THE ENGINE STILL MAKES NO ROLL. These are the odds a search weighs,
 * and the dice themselves are thrown elsewhere, from a seed.
 *
 * AT VERSION 3, WHAT A ROLL ALLOWS: the rule set as a struct, a move as a
 * struct, the moves of the side to move for a roll, and a count of the
 * positions a rule set has. A MOVE IS DESCRIBED AND NOT MADE: nothing here
 * takes a captured piece off the board, passes the turn or ends a game.
 *
 * AT VERSION 4, A MOVE MADE: apply and its undo, the forfeit, whose turn it is
 * afterwards, the count of plies, and how a game ends. apply DOES NOT ASK
 * WHETHER A MOVE IS LEGAL; it is handed one the generator made.
 *
 * AT VERSION 5, CHOOSING A MOVE: an evaluation in whole numbers, a choice
 * made without looking ahead, and a search through the dice that is bounded
 * in nodes and never in seconds.
 *
 * A POSITION HOLDS NO ROLL. A roll is an argument to the calls that need one.
 *
 * `put`, `lift`, `set_hand` and `set_home` are STRUCTURE PRIMITIVES and JUDGE
 * NOTHING.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the key which is an
 * unsigned 64-bit value of which 47 bits are used. THERE ARE NO FLOATS ANYWHERE
 * IN THIS ENGINE. Do not copy -ffp-contract=off into this dist's Makefile.PL;
 * there is nothing for it to protect.
 *
 * A CELL IS AN OPAQUE INDEX, 0 to 19, and nothing outside the engine may assume
 * which index is which square. Use (RU->cell_of) to build one and (RU->file_of)
 * / (RU->row_of) to take one apart.
 *
 * FILE 0 IS a AND ROW 0 IS 1. The board is three rows of eight with four
 * squares missing: e1, f1, e3 and f3. Row 0 is light's row and row 2 is dark's.
 *
 *     3  a3 b3 c3 d3 .  .  g3 h3
 *     2  a2 b2 c2 d2 e2 f2 g2 h2
 *     1  a1 b1 c1 d1 .  .  g1 h1
 *
 * A ROUTE IS DATA. A step is a place on a side's route, counted from 1. Step 0
 * is the hand and step route_len + 1 is home, and neither is a cell. THE SAME
 * CELL CAN BE A DIFFERENT STEP FOR EACH SIDE: on the long route g3 is light's
 * step 12 and dark's step 16. Ask a capture of the CELL and a piece's progress
 * of the STEP.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h turns
 * into function-like macros under PERL_IMPLICIT_SYS. That is why the destructor
 * is board_drop. Call through the table with the member in parentheses anyway:
 * (RU->board_drop)(b).
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new, board_of_string and board_copy return a board the caller drops
 * with board_drop. A board holds no pointers, so a copy is a flat byte copy and
 * two boards never share anything. to_string writes into a caller buffer sized
 * at least RU_POS_MAX. Nothing is retained between calls and nothing is global
 * except the route tables, which are built once from constants, and the count
 * of live boards, which exists for a leak test and is not synchronised.
 */

#define RU_ABI_VERSION 5

/* ---- cells. RU_EMPTY is 0 so a zeroed cell is an empty cell ------------------ */

#define RU_EMPTY  0
#define RU_LIGHT  1
#define RU_DARK   2

#define RU_IS_PIECE(p) ((p) == RU_LIGHT || (p) == RU_DARK)

/* ---- the two sides. A side's piece is the side plus one. -------------------- */

#define RU_SIDE_LIGHT 0
#define RU_SIDE_DARK  1

#define RU_OTHER(s)    ((s) == RU_SIDE_LIGHT ? RU_SIDE_DARK : RU_SIDE_LIGHT)
#define RU_PIECE_OF(s) ((s) + 1)

/* ---- the board ------------------------------------------------------------- */

#define RU_FILES  8
#define RU_ROWS   3
#define RU_CELLS  20

/* The most pieces a side may have. A hand or a home is 0 to this. */
#define RU_PIECES_MAX 7

/* ---- the routes --------------------------------------------------------------- */

#define RU_ROUTE_SHORT 0   /* fourteen steps                                  */
#define RU_ROUTE_LONG  1   /* sixteen steps, through the other side's row     */

#define RU_ROUTE_MAX 16    /* the longest route, for a caller's buffer        */

/* The longest string this writer emits is three rows of eight, two slashes, and
 * five fields of a space and a character: 36. Sized for a caller's stack
 * buffer. */
#define RU_POS_MAX 48

/* ---- why a position string was refused ---------------------------------------
 *
 * RU_OK is 0. Every other value names one fault.
 *
 * A string is refused for its SHAPE and never for its sense: nine pieces a
 * side, or a hand that does not add up, load, because they are positions a
 * test needs to build.
 */

#define RU_OK          0
#define RU_POS_NULL    1   /* no string at all, or an empty one                 */
#define RU_POS_ROWS    2   /* not three rows                                    */
#define RU_POS_WIDTH   3   /* a row that is not eight files wide                */
#define RU_POS_LETTER  4   /* a character that is not l, d, x or 1 to 8         */
#define RU_POS_GAP     5   /* a piece, or a run of empties, on e1 f1 e3 or f3   */
#define RU_POS_X       6   /* an x where a square exists                        */
#define RU_POS_SIDE    7   /* the side to move is not l or d                    */
#define RU_POS_COUNT   8   /* a hand or a home that is not one digit, 0 to 7    */
#define RU_POS_FIELD   9   /* a field is missing, or something follows the last */
#define RU_POS_LONG   10   /* RU_POS_MAX characters or more                     */

/* ---- the rule set, version 3 --------------------------------------------------
 *
 * FROZEN AT THIS SIZE, and that is a different rule from the table's. The table
 * may grow because a consumer only reads members it knows about. This struct is
 * allocated by the CALLER and read by the callee, so a field added later would
 * have a newer engine read past the end of an older caller's struct.
 * `reserved` is the only room there will ever be, and a reserved int of 0 must
 * always mean "as before".
 *
 * Fill one with (RU->rules_named) and then change what differs. A NULL rule
 * set anywhere in this table means RU_RULES_FINKEL.
 *
 * THE GENERATOR READS `route` AND `safe_rosettes` AND NOTHING ELSE. It is
 * handed a roll and does not know how the roll was thrown, so `dice` and
 * `zero_rolls` are not its business; and it judges a board as it stands, so
 * neither is `pieces`.
 */

struct ru_rules {
    int route;           /* RU_ROUTE_SHORT or RU_ROUTE_LONG                    */
    int dice;            /* 3 or 4                                             */
    int zero_rolls;      /* what a throw with nothing marked is worth: 0 or 4  */
    int safe_rosettes;   /* 1: a piece on a rosette cannot be captured         */
    int pieces;          /* a side, 1 to RU_PIECES_MAX                         */
    int reserved[4];
};

#define RU_RULES_FINKEL   0   /* short, four dice, nothing is nothing, safe      */
#define RU_RULES_MASTERS  1   /* long, three dice, nothing is four, not safe     */

/* The most a roll is ever worth. */
#define RU_ROLL_MAX 4

/* ---- a move, version 3 ---------------------------------------------------------
 *
 * One piece, one roll. BOTH THE STEP AND THE CELL ARE HERE, because they are
 * different questions and every consumer wants one or the other.
 *
 * FROZEN, for the reason ru_rules is: the caller allocates it and the engine
 * writes it.
 */

struct ru_move {
    int from_step;       /* 0 is the hand                                      */
    int to_step;         /* route_len + 1 is home                              */
    int from_cell;       /* -1 from the hand                                   */
    int to_cell;         /* -1 for home                                        */
    int captures;        /* 1: the landing cell holds an enemy piece           */
    int rosette;         /* 1: the landing cell is a rosette. 0 FOR HOME       */
    int home;            /* 1: the piece leaves the board                      */
    int reserved[2];
};

/* One for each piece not yet home, and the hand counts once however many it
 * holds: at most seven. */
#define RU_MOVES_MAX 7

/* ---- a move made, version 4 ---------------------------------------------------
 *
 * An undo carries everything apply or forfeit changed, so unapply restores the
 * position EXACTLY: the cells, both hands, both homes, the side to move and
 * the ply. It is a value type: copy it, do not free it.
 *
 * FROZEN, for the reason ru_rules is: the caller allocates it and the engine
 * writes it.
 */

#define RU_UNDO_NONE     0   /* nothing was done, and unapply does nothing     */
#define RU_UNDO_MOVE     1
#define RU_UNDO_FORFEIT  2

struct ru_undo {
    int kind;            /* RU_UNDO_NONE and the rest                          */
    int side;            /* whose turn it was before                           */
    int ply;             /* the ply before                                     */
    int from_step;       /* 0 when the piece came from the hand                */
    int from_cell;       /* -1 from the hand                                   */
    int to_cell;         /* -1 when the piece went home                        */
    int captured;        /* 1 when an enemy piece stood on to_cell             */
    int reserved[4];
};

/* ---- how a game stands, version 4 -----------------------------------------------
 *
 * RU_ONGOING is 0. A side wins the moment its home holds every piece it has.
 * The only draw is the ply cap, which exists so that a game cannot go on for
 * ever: a capture sends a piece back to the start, so nothing else bounds it.
 * Resignation and a clock are something two people do, and the caller records
 * them.
 */

#define RU_ONGOING  0
#define RU_WON      1
#define RU_DRAWN    2

#define RU_BY_HOME     1   /* a side brought its last piece home               */
#define RU_BY_PLY_CAP  2   /* the ply count reached RU_PLY_CAP                 */

/* A move is a ply and so is a forfeit. MEASURED, not chosen: the longest of
 * 600,000 games played under three crude policies and both named rule sets,
 * 9 October 2026, was 1,330 plies, and the cap is ten times that, rounded up.
 * It is not to be raised to make a long game finish; a game that reaches it is
 * a finding. */
#define RU_PLY_CAP 15000

/* ---- the evaluation and the search, version 5 -----------------------------------
 *
 * THE WEIGHTS of the three terms that may be added to the plain evaluation,
 * each an int and each 0 for "not used". FROZEN at this size, as ru_rules is
 * and for its reason. Fill one with (RU->weights_default) and change what
 * differs; a NULL anywhere means every weight 0.
 *
 * An evaluation is in SIXTEENTHS OF A STEP, for the side asked about.
 */
struct ru_weights {
    int exposed;     /* sixteenths of the progress a side stands to lose to the
                      * enemy's next roll that are held against it: 16 is all */
    int rosette;     /* for each of a side's pieces on a rosette both visit    */
    int entry;       /* against each of a side's pieces still in hand          */
    int reserved[5];
};

/* What a search did. Reported and not inferred: how deep it got and what it
 * cost cannot be seen from the move it returns. FROZEN: the caller allocates
 * it and the engine writes it. */
struct ru_search_info {
    unsigned long long nodes;
    int depth;            /* the deepest level that FINISHED                   */
    int value;            /* of the move chosen, for the side to move          */
    int stopped;          /* 1 if the budget ran out part way through a level  */
};

/* A win is a value and not a flag, plus the levels the search still had in
 * hand when it found it, so that a win sooner is preferred to a win later. */
#define RU_WIN 1000000

/* The deepest a search goes, whatever its budget. */
#define RU_DEPTH_MAX 32

struct ru_board;

struct ru_abi {
    unsigned int abi_version;

    /* lifecycle. board_new is an EMPTY board, light to move, both hands
     * holding `pieces` (clamped to 0 .. RU_PIECES_MAX) and both homes 0. */
    struct ru_board * (*board_new)(int pieces);
    struct ru_board * (*board_of_string)(const char *s, int *err);
    struct ru_board * (*board_copy)(const struct ru_board *b);
    void              (*board_drop)(struct ru_board *b);
    int               (*live)(void);                      /* boards not yet dropped */

    /* structure, judging nothing. A cell, a piece, a side or a count that is
     * out of range is ignored by a writer and answers -1 from a reader. */
    int  (*at)(const struct ru_board *b, int cell);
    void (*put)(struct ru_board *b, int cell, int piece);
    void (*lift)(struct ru_board *b, int cell);
    int  (*hand)(const struct ru_board *b, int side);
    void (*set_hand)(struct ru_board *b, int side, int n);
    int  (*home)(const struct ru_board *b, int side);
    void (*set_home)(struct ru_board *b, int side, int n);
    int  (*side)(const struct ru_board *b);
    void (*set_side)(struct ru_board *b, int side);
    int  (*count)(const struct ru_board *b, int side);    /* pieces on the board */

    /* 1 when each side's hand, home and pieces on the board add up to `n` */
    int  (*consistent)(const struct ru_board *b, int n);

    /* The key IS the position: the twenty cells, the two homes and the side to
     * move, packed. THE HANDS ARE NOT IN IT: for a consistent position they
     * follow from the cells and the homes. */
    unsigned long long (*key)(const struct ru_board *b);
    int  (*to_string)(const struct ru_board *b, char *buf, int len);

    /* geometry */
    int (*cell_of)(int file, int row);                    /* or -1 */
    int (*file_of)(int cell);                             /* or -1 */
    int (*row_of)(int cell);                              /* or -1 */
    int (*is_rosette)(int cell);

    /* the routes */
    int (*route_len)(int route);                          /* 14, 16, or -1 */
    int (*route_cell)(int route, int side, int step);     /* a cell, or -1 */
    int (*route_step)(int route, int side, int cell);     /* a step, or 0  */
    int (*route_shared)(int route, int cell);             /* on BOTH sides' routes */

    /* ---- version 2: the chance of a roll ---------------------------------- */

    /* How many different rolls `dice` dice can make when a throw with nothing
     * marked is worth `zero_rolls` steps. 0 when `dice` is not 3 or 4 or
     * `zero_rolls` is not 0 or 4. */
    int (*chance_count)(int dice, int zero_rolls);

    /* Roll number `i` of those, counted from 0 in ascending order of roll: the
     * roll, how many of the equally likely throws make it, and how many throws
     * there are. 1 when written, 0 when there is no such entry. */
    int (*chance)(int dice, int zero_rolls, int i, int *roll, int *weight, int *denominator);

    /* ---- version 3: what a roll allows ------------------------------------- */

    /* Fills `r` with a named set. 1 when `name` is one, 0 when it is not. */
    int (*rules_named)(int name, struct ru_rules *r);
    /* 1 when every field of `r` holds a value it may. */
    int (*rules_ok)(const struct ru_rules *r);

    /* The moves `roll` allows the side to move, the hand first and then its
     * pieces in ascending order of step. Writes at most `max`, returns how
     * many there ARE. A roll of 0 allows none and answers 0. A roll outside
     * 0 .. RU_ROLL_MAX, or a rule set that is not ok, answers -1: that is a
     * refused argument and not an empty list. */
    int (*moves)(const struct ru_board *b, const struct ru_rules *r, int roll,
                 struct ru_move *out, int max);

    /* How many consistent positions the rule set has, either side to move,
     * finished games included. 0 for a rule set that is not ok. It walks every
     * one: about a second for seven pieces. */
    unsigned long long (*count_positions)(const struct ru_rules *r);

    /* ---- version 4: a move made --------------------------------------------- */

    /* Moves and forfeits made to reach this position. NOT part of the key or
     * of the position string: a board read from a string is at ply 0. */
    int  (*ply)(const struct ru_board *b);
    void (*set_ply)(struct ru_board *b, int ply);        /* a negative is ignored */

    /* Makes a move for the side to move: the piece leaves `from`, an enemy
     * standing on the landing cell goes back to ITS OWNER'S HAND, the piece
     * arrives or goes home, the ply goes up by one, and the turn passes UNLESS
     * the landing cell is a rosette. 1 when made.
     *
     * IT DOES NOT ASK WHETHER THE MOVE IS LEGAL. It asks only that the piece
     * it is told to move is there: a piece of the side to move on `from_cell`,
     * or one in its hand. When that is not so it does nothing, answers 0 and
     * sets u->kind to RU_UNDO_NONE. */
    int  (*apply)(struct ru_board *b, const struct ru_rules *r,
                  const struct ru_move *m, struct ru_undo *u);

    /* A turn lost to the roll: the ply goes up by one and the turn passes,
     * ALWAYS, an extra roll earned on a rosette included. */
    void (*forfeit)(struct ru_board *b, struct ru_undo *u);

    void (*unapply)(struct ru_board *b, const struct ru_undo *u);

    int  (*status)(const struct ru_board *b, const struct ru_rules *r);   /* RU_ONGOING ... */
    int  (*how)(const struct ru_board *b, const struct ru_rules *r);      /* 0, RU_BY_HOME ... */
    int  (*winner)(const struct ru_board *b, const struct ru_rules *r);   /* a side, or -1 */
    int  (*ply_cap)(void);

    /* Every roll the rule set's dice can make and every move each allows, to
     * `depth` plies, counting the positions at the end. A roll that allows
     * nothing is one branch, a forfeit; a finished game is an end. Each roll
     * counts once however likely it is. The board is left as it was found. */
    unsigned long long (*walk)(struct ru_board *b, const struct ru_rules *r, int depth);

    /* ---- version 5: choosing a move ------------------------------------------ */

    void (*weights_default)(struct ru_weights *w);

    /* The position valued for `side`, in sixteenths of a step. */
    int  (*evaluate)(const struct ru_board *b, const struct ru_rules *r,
                     const struct ru_weights *w, int side);

    /* The move to make without looking ahead, as an index into what (moves)
     * returns for the same roll: one that captures if any does, else one onto
     * a rosette if any is, else the piece furthest along. -1 when the roll
     * allows nothing. */
    int  (*greedy)(const struct ru_board *b, const struct ru_rules *r, int roll);

    /* The best move for the side to move, as an index into what (moves)
     * returns for the same roll, or -1 when the roll allows nothing or the
     * game is over. The board is not touched: the search plays into a copy.
     *
     *   budget     nodes. The first level always finishes whatever it is, so
     *              a budget smaller than the moves there are is passed by
     *              that much and by no more.
     *   max_depth  0 for no limit but the budget and RU_DEPTH_MAX.
     *
     * Moves of equal value go to the HIGHEST index, the piece furthest along.
     * The same board, rules, roll, weights, budget and depth give the same
     * answer every time. */
    int  (*search)(const struct ru_board *b, const struct ru_rules *r, int roll,
                   const struct ru_weights *w, unsigned long long budget, int max_depth,
                   struct ru_search_info *info);
};

const struct ru_abi *ru_abi_table(void);

#endif
