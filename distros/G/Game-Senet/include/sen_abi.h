#ifndef SEN_ABI_H
#define SEN_ABI_H

/* Public C ABI for Game::Senet, the Egyptian game of passing, and anything that
 * wants to keep a position of it without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in any sen_*.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to wasm.
 * The table is resolved at RUNTIME via Game::Senet::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of ru_abi.h and bd_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. SEN_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * NEVER ==.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * AT VERSION 1, THE BOARD AND NOTHING ELSE: thirty houses, what stands on each,
 * the side to move, the number of pieces a side has, the grid the houses are
 * drawn on, the marked houses, the two named rule sets as DATA, an exact key,
 * and the position string in and out. NO RULES. A caller may put nine light
 * pieces in a row and this version has no opinion.
 *
 * A POSITION HOLDS NO THROW AND NO ROLL. A roll is an argument to the calls
 * that need one, and a throw that must be made again on house 26 is a fact of
 * the turn, not of the position.
 *
 * AT VERSION 2, THE CHANCE OF A ROLL: each roll four sticks can make, in order
 * of ROLL, how often it comes up in sixteenths, and whether it gives another
 * throw. THE ENGINE STILL MAKES NO THROW. These are the odds a search weighs;
 * the sticks themselves are thrown elsewhere, from a seed.
 *
 * AT VERSION 3, WHAT A ROLL ALLOWS: a move as a struct, and the moves of the side
 * to move for a roll: forward, the backward fallback, the swap, protection, the
 * blockade and the approach to house 26. A MOVE IS DESCRIBED AND NOT MADE. A
 * piece standing on 26 or beyond is not a candidate at this version: it leaves
 * by the exit chains, which a later version reads.
 *
 * AT VERSION 4, A MOVE MADE: the exit chains walked for a piece on 26 to 30,
 * apply and its undo, the forfeit, whose turn it is afterwards, the count of
 * plies, and how a game ends. apply DOES NOT ASK WHETHER A MOVE IS LEGAL; it is
 * handed one the generator made.
 *
 * AT VERSION 5, CHOOSING A MOVE: an evaluation in whole numbers, a choice made
 * without looking ahead, and a search through the sticks that is bounded in
 * nodes and never in seconds.
 *
 * `put` and `lift` are STRUCTURE PRIMITIVES and JUDGE NOTHING.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the key, which is an
 * unsigned 64-bit value of which 61 bits are used, and the safe-house mask,
 * which is an unsigned long of which bits 1 to 30 are used. THERE ARE NO FLOATS
 * ANYWHERE IN THIS ENGINE.
 *
 * A HOUSE IS ITS NUMBER, 1 to 30, and the number is the index. The track is one
 * table for both sides: house h is step h for light and for dark alike. House 0
 * is not a house.
 *
 * THE GRID IS FOR DRAWING AND FOR NOTHING ELSE. Three rows of ten, the track a
 * reversed S:
 *
 *     row 0     1  2  3  4  5  6  7  8  9 10
 *     row 1    20 19 18 17 16 15 14 13 12 11
 *     row 2    21 22 23 24 25 26 27 28 29 30
 *
 * No rule asks which row a house is in. Houses 10 and 11 are next to each other
 * because their NUMBERS are; houses 1 and 20 stand one above the other on the
 * grid and are not.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h turns
 * into function-like macros under PERL_IMPLICIT_SYS. That is why the destructor
 * is board_drop. Call through the table with the member in parentheses anyway:
 * (SEN->board_drop)(b).
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new, board_of_string and board_copy return a board the caller drops
 * with board_drop. A board holds no pointers, so a copy is a flat byte copy and
 * two boards never share anything. to_string writes into a caller buffer sized
 * at least SEN_POS_MAX. Nothing is retained between calls and nothing is global
 * except the two named rule sets, which are constants, and the count of live
 * boards, which exists for a leak test and is not synchronised.
 */

#define SEN_ABI_VERSION 5

/* ---- houses. SEN_EMPTY is 0 so a zeroed house is an empty house -------------- */

#define SEN_EMPTY  0
#define SEN_LIGHT  1
#define SEN_DARK   2

#define SEN_IS_PIECE(p) ((p) == SEN_LIGHT || (p) == SEN_DARK)

/* ---- the two sides. A side's piece is the side plus one. --------------------- */

#define SEN_SIDE_LIGHT 0
#define SEN_SIDE_DARK  1

#define SEN_OTHER(s)    ((s) == SEN_SIDE_LIGHT ? SEN_SIDE_DARK : SEN_SIDE_LIGHT)
#define SEN_PIECE_OF(s) ((s) + 1)

/* ---- the board ------------------------------------------------------------- */

#define SEN_HOUSES 30
#define SEN_ROWS    3
#define SEN_COLS   10

/* The most pieces a side may have. IT MAY NOT GROW: the walk down from house 15
 * after the water always finds an empty house only while the other pieces on
 * the board, 2 * SEN_PIECES_MAX - 1 of them, are fewer than the fifteen houses
 * from 1 to 15. */
#define SEN_PIECES_MAX 7

/* The longest string this writer emits is three groups of ten, two slashes, and
 * two fields of a space and a character: 36. Sized for a caller's stack
 * buffer. */
#define SEN_POS_MAX 48

/* ---- why a position string was refused ---------------------------------------
 *
 * SEN_OK is 0. Every other value names one fault.
 *
 * A string is refused for its SHAPE, and for one thing more: a side with more
 * pieces on the board than `pieces`. A home is pieces less those on the board,
 * so such a side would have a negative home, and that is not a position at all.
 */

#define SEN_OK            0
#define SEN_POS_NULL      1   /* no string at all, or an empty one                 */
#define SEN_POS_GROUPS    2   /* not three groups                                  */
#define SEN_POS_WIDTH     3   /* a group that is not ten houses long               */
#define SEN_POS_LETTER    4   /* a character that is not l, d or .                 */
#define SEN_POS_SIDE      5   /* the side to move is not l or d                    */
#define SEN_POS_PIECES    6   /* pieces is not one digit, 1 to 7                   */
#define SEN_POS_EXCESS    7   /* a side has more pieces on the board than pieces  */
#define SEN_POS_FIELD     8   /* a field is missing, or something follows the last */
#define SEN_POS_LONG      9   /* SEN_POS_MAX characters or more                    */

/* ---- the rule set -------------------------------------------------------------
 *
 * THE TWO NAMED SETS ARE DATA, two initialisers in sen_engine.c copied into a
 * caller's struct by rules_named. No function in the engine branches on which
 * set it holds.
 *
 * FROZEN AT THIS SIZE, and that is a different rule from the table's. The table
 * may grow because a consumer only reads members it knows about. This struct is
 * allocated by the CALLER and read by the callee, so a field added later would
 * have a newer engine read past the end of an older caller's struct.
 * `reserved` is the only room there will ever be, and a reserved int of 0 must
 * always mean "as before".
 *
 * THE MARKED HOUSES' EXITS. exit[house - 26][roll - 1] is a CHAIN of at most
 * SEN_CHAIN_MAX entries for a piece standing on houses 26 to 30, read in order
 * until one can be taken:
 *
 *     SEN_X_END    0    the chain is exhausted: not a move
 *     1 .. 30           that house, if it is empty
 *     SEN_X_OFF   31    bear off
 *     SEN_X_WALK  32    house 15, else the first empty house below it
 *     SEN_X_STAY  33    the piece does not move
 *
 * Once an entry is SEN_X_END every entry after it is too.
 */

#define SEN_PROTECT_NONE 0   /* any lone or grouped enemy piece may be swapped      */
#define SEN_PROTECT_RUN  1   /* every piece of a run of two or more is protected    */
#define SEN_PROTECT_ENDS 2   /* only the first and the last of a run are protected  */

#define SEN_REACH_EXACT 0    /* a roll past 26 from below it is not a move          */
#define SEN_REACH_ANY   1    /* from 25, any roll lands on 26                       */

#define SEN_CHAIN_MAX 4
#define SEN_EXIT_FIRST 26
#define SEN_EXIT_HOUSES 5
#define SEN_ROLL_MAX 5

#define SEN_X_END   0
#define SEN_X_OFF  31
#define SEN_X_WALK 32
#define SEN_X_STAY 33

/* The house SEN_X_WALK aims for first. */
#define SEN_REBIRTH 15

struct sen_rules {
    int pieces;              /* a side, 1 to SEN_PIECES_MAX                         */
    int blockade;            /* a run this long cannot be passed: 2, 3, or 0 none   */
    int protect;             /* SEN_PROTECT_NONE, _RUN or _ENDS                      */
    int backward;            /* 1: a backward move when no forward move exists      */
    int reach26;             /* SEN_REACH_EXACT or SEN_REACH_ANY                     */
    int throw_on_26;         /* 1: a piece arriving on 26 is thrown for again        */
    unsigned long safe;      /* bit h set: no piece on house h can be swapped        */
    signed char exit[SEN_EXIT_HOUSES][SEN_ROLL_MAX][SEN_CHAIN_MAX];
    int reserved[4];
};

#define SEN_RULES_KENDALL 0
#define SEN_RULES_SKYRUK  1

/* ---- a move, version 3 ---------------------------------------------------------
 *
 * One piece, one roll. FROZEN, for the reason sen_rules is: the caller
 * allocates it and the engine writes it.
 */

struct sen_move {
    int from;            /* a house, 1 to 30: a piece is always on the board  */
    int to;              /* a house, or -1 when `off` is 1                      */
    int roll;            /* the roll that made it                              */
    int swap;            /* 1: an enemy piece stands on `to`; it goes to `from` */
    int back;            /* 1: a backward move                                  */
    int off;             /* 1: the piece bears off                              */
    int walk;            /* 1: the landing came by the walk down from 15. V4    */
    int reserved[1];
};

/* One for each piece a side has. */
#define SEN_MOVES_MAX SEN_PIECES_MAX

/* ---- a move made, version 4 ---------------------------------------------------
 *
 * An undo carries everything apply or forfeit changed, so unapply restores the
 * position EXACTLY: the houses, the side to move and the ply. It is a value
 * type: copy it, do not free it. FROZEN, for the reason sen_rules is.
 *
 * `bound` is not part of the position. It is the house whose piece alone the
 * NEXT throw may move, or 0: under throw_on_26, the piece that has just arrived
 * on 26. The turn keeps it, and hands it to (SEN->moves) as `only`.
 */

#define SEN_UNDO_NONE     0   /* nothing was done, and unapply does nothing     */
#define SEN_UNDO_MOVE     1
#define SEN_UNDO_FORFEIT  2

struct sen_undo {
    int kind;            /* SEN_UNDO_NONE and the rest                         */
    int side;            /* whose turn it was before                           */
    int ply;             /* the ply before                                     */
    int from;
    int to;              /* -1 when the piece bore off                         */
    int swapped;         /* 1 when an enemy piece stood on `to`                */
    int bound;           /* the house the next throw is bound to, or 0         */
    int reserved[4];
};

/* ---- how a game stands, version 4 ---------------------------------------------
 *
 * SEN_ONGOING is 0. A side wins the moment its home holds every piece it has:
 * the move that bears off its last piece ends the game whatever its roll. The
 * only draw is the ply cap, which exists so a game cannot go on for ever: a
 * swap and the water send pieces back, so nothing else bounds it.
 */

#define SEN_ONGOING  0
#define SEN_WON      1
#define SEN_DRAWN    2

#define SEN_BY_HOME     1
#define SEN_BY_PLY_CAP  2

/* A move is a ply and so is a forfeit. MEASURED, not chosen: the longest of
 * 140,000 games played under three crude policies and both named rule sets, from
 * the start and from crowded starts, 18 October 2026, was 815 plies, and the cap
 * is ten times that, rounded up. It is not to be raised to make a long game
 * finish; a game that reaches it is a finding. */
#define SEN_PLY_CAP 10000

/* ---- the evaluation and the search, version 5 -----------------------------------
 *
 * THE WEIGHT of the one term that may be added to the plain evaluation, 0 for
 * "not used", and the rule for moves of equal value. Three more terms were
 * measured and removed (plan_game_senet/07): protect, stuck and water each lost
 * ground or moved nothing under both sets.
 * FROZEN at this size, as sen_rules is and for its reason. Fill one with
 * (SEN->weights_default) and change what differs; a NULL means every weight 0.
 *
 * An evaluation is in SIXTEENTHS OF A HOUSE, for the side asked about.
 */

#define SEN_TIES_LAST  0   /* moves of equal value go to the later in the list  */
#define SEN_TIES_FIRST 1   /* to the earlier                                   */

struct sen_weights {
    int blockade;    /* own blockades with an enemy piece behind them             */
    int ties;        /* SEN_TIES_LAST or SEN_TIES_FIRST                          */
    int reserved[6];
};

/* What a search did. Reported and not inferred. FROZEN: the caller allocates it
 * and the engine writes it. */
struct sen_search_info {
    unsigned long long nodes;
    int depth;            /* the deepest level that FINISHED                   */
    int value;            /* of the move chosen, for the side to move          */
    int stopped;          /* 1 if the budget ran out part way through a level  */
};

/* A win is a value and not a flag, plus the levels the search still had in hand
 * when it found it, so that a win sooner is preferred to a win later. It is
 * above any evaluation by two orders of magnitude: progress is at most
 * 16 * 7 * 31 = 3,472 sixteenths a side, and no term weight in use is large
 * enough to carry a position near it. */
#define SEN_WIN 1000000

/* The deepest a search goes, in throws, whatever its budget. */
#define SEN_DEPTH_MAX 32

struct sen_board;

struct sen_abi {
    unsigned int abi_version;

    /* lifecycle. board_new is an EMPTY board, light to move, ply 0, with
     * `pieces` a side (clamped to 1 .. SEN_PIECES_MAX). */
    struct sen_board * (*board_new)(int pieces);
    struct sen_board * (*board_of_string)(const char *s, int *err);
    struct sen_board * (*board_copy)(const struct sen_board *b);
    void               (*board_drop)(struct sen_board *b);
    int                (*live)(void);                    /* boards not yet dropped */

    /* structure, judging nothing. A house, a piece or a side that is out of
     * range is ignored by a writer and answers -1 from a reader. */
    int  (*at)(const struct sen_board *b, int house);
    void (*put)(struct sen_board *b, int house, int piece);
    void (*lift)(struct sen_board *b, int house);
    int  (*side)(const struct sen_board *b);
    void (*set_side)(struct sen_board *b, int side);
    int  (*pieces)(const struct sen_board *b);
    int  (*count)(const struct sen_board *b, int side);  /* pieces on the board */

    /* DERIVED AND NEVER STORED: pieces less those of the side on the board.
     * Negative on a board a test built overfull. */
    int  (*home)(const struct sen_board *b, int side);

    /* 1 when neither side has more pieces on the board than `pieces` */
    int  (*consistent)(const struct sen_board *b);

    /* Moves and forfeits made to reach this position. NOT part of the key or of
     * the position string: a board read from a string is at ply 0. */
    int  (*ply)(const struct sen_board *b);
    void (*set_ply)(struct sen_board *b, int ply);       /* a negative is ignored */

    /* The key IS the position: thirty houses at two bits, house h at bit
     * 2(h - 1), and the side to move at bit 60. NEITHER THE HOMES NOR `pieces`
     * ARE IN IT: the homes follow from the houses and `pieces`, and two games
     * that differ in `pieces` never meet. */
    unsigned long long (*key)(const struct sen_board *b);
    int  (*to_string)(const struct sen_board *b, char *buf, int len);

    /* geometry, for drawing */
    int (*house_of)(int row, int col);                   /* or -1 */
    int (*row_of)(int house);                            /* or -1 */
    int (*col_of)(int house);                            /* or -1 */
    int (*is_marked)(int house);                         /* 15, 26 .. 30 */

    /* the rule sets. rules_named fills `r` with a named set: 1 when `name` is
     * one, 0 when it is not. rules_id answers the number of the set a NAME
     * stands for, or -1, so that the words live in the engine and nowhere
     * else. rules_ok is 1 when every field of `r` holds a value it may. */
    int (*rules_named)(int name, struct sen_rules *r);
    int (*rules_id)(const char *name);
    int (*rules_ok)(const struct sen_rules *r);

    /* ---- version 2: the chance of a roll ---------------------------------- */

    /* How many different rolls four sticks can make: 5. */
    int (*chance_count)(void);

    /* Roll number `i` of those, counted from 0 in ascending order of ROLL, not
     * of throw: the roll, how many of the sixteen ways four sticks fall make
     * it, and 16. 1 when written, 0 when there is no such entry. */
    int (*chance)(int i, int *roll, int *weight, int *denominator);

    /* 1 when a roll gives another throw: 1, 4 or 5. 0 for 2 and 3. -1 for
     * anything that is not a roll, 0 included. */
    int (*extra)(int roll);

    /* ---- version 3: what a roll allows ------------------------------------- */

    /* The moves `roll` allows the side to move, in ascending order of `from`.
     * BACKWARD MOVES ARE A FALLBACK: when the rule set allows them, they are
     * listed only if no forward move exists, so a list is all forward or all
     * backward. `only` is 0, or the one house whose piece alone may move.
     * Writes at most `max`, returns how many there ARE. A roll outside 1 ..
     * SEN_ROLL_MAX, or a rule set that is not ok, answers -1: a roll of 0 is a
     * THROW, and that is a refused argument and not an empty list. */
    int (*moves)(const struct sen_board *b, const struct sen_rules *r, int roll,
                 int only, struct sen_move *out, int max);

    /* ---- version 4: a move made ------------------------------------------- */

    /* Makes a move for the side to move: the piece leaves `from`, an enemy
     * standing on `to` goes to `from` (the swap), the piece lands or bears off,
     * the ply goes up by one, and the side to move follows the roll: the same
     * side after a 1, 4 or 5, the other after a 2 or 3, the same side when
     * throw_on_26 and the piece arrived on 26 (u->bound is then 26), and no
     * change at all after the move that wins. 1 when made.
     *
     * IT DOES NOT ASK WHETHER THE MOVE IS LEGAL, only that a piece of the side
     * to move stands on `from`. When it does not, nothing changes, the answer
     * is 0 and u->kind is SEN_UNDO_NONE. */
    int  (*apply)(struct sen_board *b, const struct sen_rules *r,
                  const struct sen_move *m, struct sen_undo *u);

    /* A throw that allows nothing: the ply goes up by one, and the side to move
     * follows the roll as it does after a move. A Senet forfeit does not always
     * pass the turn. */
    void (*forfeit)(struct sen_board *b, int roll, struct sen_undo *u);

    void (*unapply)(struct sen_board *b, const struct sen_undo *u);

    int  (*status)(const struct sen_board *b);   /* SEN_ONGOING ... */
    int  (*how)(const struct sen_board *b);      /* 0, SEN_BY_HOME, SEN_BY_PLY_CAP */
    int  (*winner)(const struct sen_board *b);   /* a side, or -1 */
    int  (*ply_cap)(void);

    /* Every roll and every move each allows, to `depth` plies, counting the
     * positions at the end. A roll that allows nothing is one branch, a
     * forfeit; a finished game is an end; a bound throw moves the bound piece.
     * Each roll counts once however likely it is. The board is left as found. */
    unsigned long long (*walk)(struct sen_board *b, const struct sen_rules *r, int depth);

    /* ---- version 5: choosing a move ---------------------------------------- */

    void (*weights_default)(struct sen_weights *w);

    /* The position valued for `side`, in sixteenths of a house. */
    int  (*evaluate)(const struct sen_board *b, const struct sen_rules *r,
                     const struct sen_weights *w, int side);

    /* The move to make without looking ahead, as an index into what (moves)
     * returns for the same roll and `only`: a bear-off, else a swap, else a
     * landing on 26, else the move whose piece ends furthest on. -1 when the
     * roll allows nothing. */
    int  (*greedy)(const struct sen_board *b, const struct sen_rules *r, int roll, int only);

    /* The best move for the side to move, as an index into what (moves)
     * returns for the same roll and `only`, or -1 when the roll allows nothing
     * or the game is over. The board is not touched: the search plays into a
     * copy. `budget` is in nodes; the first level always finishes. `max_depth`
     * is in throws, 0 for no limit but the budget and SEN_DEPTH_MAX. The same
     * arguments give the same answer every time. */
    int  (*search)(const struct sen_board *b, const struct sen_rules *r, int roll, int only,
                   const struct sen_weights *w, unsigned long long budget, int max_depth,
                   struct sen_search_info *info);

    /* The value of a position BEFORE its throw, for `side`, `depth` throws
     * deep, `only` bounding that first throw. For tests worked by hand. */
    int  (*expect)(const struct sen_board *b, const struct sen_rules *r,
                   const struct sen_weights *w, int only, int depth, int side);
};

const struct sen_abi *sen_abi_table(void);

#endif
