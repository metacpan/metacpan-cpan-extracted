#ifndef STH_ABI_H
#define STH_ABI_H

/* Public C ABI for Game::Sternhalma, the star of 121 holes, and anything that
 * wants to keep a sternhalma position without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in sth_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to wasm.
 * The table is resolved at RUNTIME via Game::Sternhalma::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of fn_abi.h and bd_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. STH_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * NEVER ==.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * AT VERSION 1, THE BOARD AND NOTHING ELSE: the 121 holes, which are
 * neighbours, the six points, the hexagon and its ring, the four hop classes,
 * which points a seat count uses, the seat to move, a zobrist key, and the
 * position string in and out. NOTHING HERE KNOWS WHAT A STEP OR A HOP IS.
 *
 * AT VERSION 2, ONE STEP AND ONE HOP: the empty neighbours of a hole; where a
 * single hop from a hole lands, over one neighbouring piece of any seat into
 * the empty hole straight beyond it; and moving a piece, with the key kept.
 * Nothing is captured. NO CHAIN YET, and NOTHING HERE KNOWS WHOSE TURN IT IS:
 * do_move moves a piece and leaves the seat to move alone.
 *
 * AT VERSION 3, A MOVE: the reach of a piece, every hole a step or a chain of
 * hops can stop on, since the stop is optional; the path a move is shown by;
 * and the legal moves of the seat to move as (from, to) pairs. A move needs
 * no more than its two ends, because nothing is captured and the board after
 * it depends on nothing else. NOTHING HERE KNOWS HOW A GAME ENDS.
 *
 * AT VERSION 4, A GAME: whose turn it is, who is home and in what place, and
 * how it ends. play, pass and resign are the first calls in this table that
 * REFUSE, and each says why. Only "all pieces home" is the game's own rule;
 * the parked piece, the pass, the deadlock, the ply cap and where a resigning
 * seat is placed are this dist's house rules, because W and D say nothing.
 *
 * AT VERSION 5, THE GAME IN THE POSITION STRING, AND NO NEW MEMBER: after the
 * piece count, a ';' and the game (who is home, who resigned, the ply, the
 * passes in a row, the cap if it is not the default, and how it ended), each
 * only when it is not the default. A board at its set-up writes no ';', so
 * every string version 1 wrote still reads the same, and a board read from a
 * string carries its game with it.
 *
 * AT VERSION 6, CHOOSING A MOVE: a seat's score in integers, a search bounded
 * in positions looked at and never in seconds, and the weakest player, a
 * random choice among the moves that go forward.
 *
 * `put`, `lift`, `do_move` and `undo_move` are STRUCTURE PRIMITIVES and
 * JUDGE NOTHING. A caller may fill the board with one seat's pieces.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the zobrist key which
 * is an unsigned 64-bit value. THERE ARE NO FLOATS ANYWHERE IN THIS ENGINE.
 *
 * A HOLE IS 0 TO 120, in reading order: the top tip is 0, then each row from
 * the top, left to right. That numbering is the only one that leaves the
 * engine. Inside, a hole lives in a 21 by 21 mailbox with a margin of two, so
 * that a read two squares out (a hop, from version 2) never wraps into the
 * next row.
 *
 * COORDINATES ARE CUBE COORDINATES (x, y, z) with x + y + z == 0, each from -8
 * to 8. A hole is on the star when all three are at most 4 or all three are at
 * least -4: the two big triangles of 91, overlapping in a hexagon of 61. y is
 * the row (-8 at the top), and x grows to the right along a row.
 *
 * A DIRECTION IS 0 TO 5: E, NE, NW, W, SW, SE, as (dx, dy) of (+1,0) (+1,-1)
 * (0,-1) (-1,0) (-1,+1) (0,+1). The opposite of d is (d + 3) % 6.
 *
 * A POINT IS 0 TO 5, clockwise from the top tip: top, top right, bottom right,
 * bottom, bottom left, top left. The opposite of p is (p + 3) % 6. A hole of
 * the hexagon is in STH_CENTRE.
 *
 * A HOP CLASS IS 0 TO 3: (x & 1) | ((y & 1) << 1), counted on x + 8 and
 * y + 8 so neither is negative. Moving two holes in a line keeps the class.
 *
 * A SEAT IS 0 TO seats - 1, and seat 0 moves first. Which point each seat
 * starts in is fixed by the seat count (layout_point), so a position never
 * has to say it.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h
 * turns into function-like macros under PERL_IMPLICIT_SYS. That is why the
 * destructor is board_drop. Call through the table with the member in
 * parentheses anyway: (STH->board_drop)(b).
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new, board_empty, board_of_string and board_copy return a board the
 * caller drops with board_drop. A board holds no pointers, so a copy is a flat
 * byte copy and two boards never share anything. to_string writes into a
 * caller buffer sized at least STH_POS_MAX. Nothing is retained between calls
 * and nothing is global except the geometry tables and the zobrist table,
 * which are derived deterministically on first use, and the count of live
 * boards, which exists for a leak test and is not synchronised.
 */

/* Version 1 is the board. Version 2 appends the step, the hop and moving a
 * piece. Version 3 appends the reach, the path and the legal moves. Version 4
 * appends the game. Version 5 appends nothing and widens the position string.
 * Version 6 appends the evaluation and the search. Nothing that exists at a
 * version moves or changes meaning at a later one. */
#define STH_ABI_VERSION 6

/* ---- what a hole holds ------------------------------------------------------- */

#define STH_SEATS_MAX 6
#define STH_EMPTY     6
#define STH_OFF       7

/* ---- the star ------------------------------------------------------------------ */

#define STH_HOLES      121
#define STH_ROWS       17
#define STH_ROW_MAX    13
#define STH_POINTS     6
#define STH_POINT_HOLES 10
#define STH_FRONT_HOLES 5
#define STH_CENTRE     6
#define STH_CENTRE_HOLES 61
#define STH_RING_HOLES 24
#define STH_CLASSES    4

/* Each neighbouring pair once: (73 * 6 + 6 * 5 + 36 * 4 + 6 * 2) / 2. */
#define STH_PAIRS      312

/* ---- directions ---------------------------------------------------------------- */

#define STH_E   0
#define STH_NE  1
#define STH_NW  2
#define STH_W   3
#define STH_SW  4
#define STH_SE  5
#define STH_DIRS 6

/* ---- seats and pieces ------------------------------------------------------------
 *
 * The seat counts the engine builds: 2, 3, 4 and 6, and 1 for a crossing alone,
 * which a test of the shortest crossing needs and a game does not offer. Ten
 * pieces a seat, or fifteen where no two points in use are neighbours: one,
 * two or three seats. A fifteen-piece start is the point and the five ring
 * holes in front of it, and two neighbouring points share a ring corner.
 */

#define STH_PIECES      10
#define STH_PIECES_MAX  15

/* The longest string this writer emits is well under 300 characters (a run
 * of one empty hole costs three, a piece one). Sized for a caller's stack
 * buffer, and a string this long or longer is refused unread. */
#define STH_POS_MAX 512

/* ---- why a position string was refused ---------------------------------------
 *
 * STH_OK is 0. Every other value names one fault. A string is refused for its
 * SHAPE and never for its sense: ten pieces in the middle of the star load,
 * because that is a position a test needs to build.
 *
 * THEY ARE ASKED IN THIS ORDER, because one string can have several faults.
 */

#define STH_OK          0
#define STH_POS_NULL    1   /* no string at all, or an empty one                 */
#define STH_POS_LONG    2   /* STH_POS_MAX characters or more                    */
#define STH_POS_LETTER  3   /* a character that is not 0 to 5, '/', or a run     *
                             * written [1] to [13]                               */
#define STH_POS_ROWS    4   /* not seventeen rows                                */
#define STH_POS_WIDTH   5   /* a row that is not as long as that row of the star */
#define STH_POS_FIELDS  6   /* after the rows, not exactly: a space, the seat to *
                             * move, a space, a seat count the engine builds, a  *
                             * space, a piece count that count may have; or the  *
                             * seat to move is not one of the seats              */
#define STH_POS_SEAT    7   /* a piece of a seat the game does not have          */
#define STH_POS_COUNT   8   /* a seat with more or fewer pieces than the count   */
#define STH_POS_GAME    9   /* version 5: the game after the ';' is malformed,  *
                             * out of order, or does not agree with itself       */

/* ---- a step and a hop, version 2 ----------------------------------------------
 *
 * A hole has six directions, so at most six steps and at most six hops. Both
 * calls write at most `max` and return how many there are, so a short buffer
 * is detectable.
 */

#define STH_STEPS_MAX 6
#define STH_HOPS_MAX  6

/* ---- a move, version 3 -----------------------------------------------------------
 *
 * THE BUFFERS A CALLER MUST SUPPLY, and why each is enough.
 *
 * A reach is holes other than the start: at most 120.
 *
 * A path is the start, then each hole the chain lands on. A hop moves two holes
 * in a line, so it keeps the hop class, and a path visits no hole twice: at
 * most the 37 holes of the largest class. A step's path is two holes.
 *
 * Legal moves are at most a reach for each piece of the seat to move: 15 * 120.
 * Every call writes at most `max` and returns how many there are.
 */

#define STH_REACH_MAX 120
#define STH_PATH_MAX  37
#define STH_LEGAL_MAX 1800

/* ---- a game, version 4 -----------------------------------------------------------
 *
 * HOW A GAME ENDED. STH_BY_HOME: everyone but one is home (with two seats,
 * the first home ends it). STH_BY_CAP: the ply cap. STH_BY_DEADLOCK: every seat
 * still racing passed in a row. STH_BY_RESIGN: resigning left one seat racing.
 */

#define STH_ONGOING      0
#define STH_BY_HOME      1
#define STH_BY_CAP       2
#define STH_BY_DEADLOCK  3
#define STH_BY_RESIGN    4

/* PROVISIONAL until phase 07 measures it: a game stops at this many plies a
 * seat. A ply is a move or a pass. */
#define STH_PLY_CAP_PER_SEAT 1000

/* WHY play, pass or resign refused. STH_PLAY_OK is 0. Asked in this order. */
#define STH_PLAY_OK          0
#define STH_WHY_OVER         1   /* the game has ended                        */
#define STH_WHY_NOT_A_HOLE   2   /* `from` or `to` is not a hole              */
#define STH_WHY_NO_PIECE     3   /* nothing on `from`                         */
#define STH_WHY_NOT_YOURS    4   /* the piece is not the seat to move's       */
#define STH_WHY_UNREACHABLE  5   /* `to` is not in the piece's reach          */
#define STH_WHY_HAS_MOVE     6   /* a pass, while the seat has a move         */
#define STH_WHY_NOT_A_SEAT   7   /* resign: no such seat                      */
#define STH_WHY_SEAT_DONE    8   /* resign: that seat is home or resigned     */

#define STH_DID_MOVE    1
#define STH_DID_PASS    2
#define STH_DID_RESIGN  3

/* An undo carries everything play, pass or resign changed, so unplay restores
 * the game exactly, key included. A value type: copy it, do not free it.
 *
 * FROZEN AT THIS SIZE. It is allocated by the CALLER and written by the engine,
 * so a field added later would have a newer engine write past the end of an
 * older caller's struct. The reserved members are room for that. */
struct sth_undo {
    int kind;                   /* STH_DID_MOVE, _PASS or _RESIGN             */
    int from;
    int to;
    int seat;                   /* who moved, passed or resigned              */
    int to_move;                /* and everything as it was before            */
    int ply;
    int pass_run;
    int finished_n;
    int resigned_n;
    int over;
    int how;
    int reserved[8];
};

/* ---- choosing a move, version 6 -------------------------------------------------
 *
 * A SEAT'S SCORE, higher better: STH_WIN_SCORE for a seat home, otherwise
 * minus the weighted sum of how far its pieces are from home, how far its
 * rearmost piece is, how far its pieces' hop classes are from its home's, and
 * how many of its pieces sit in the home in front of an empty hole deeper in.
 * A position's VALUE to a seat is its score less the best score of a rival
 * still racing.
 *
 * FROZEN, both structs: the caller allocates them and the engine writes them.
 */

struct sth_weights {
    int distance;
    int straggler;
    int classes;
    int blocking;
    int reserved[8];
};

#define STH_W_DISTANCE   4
#define STH_W_STRAGGLER  2
#define STH_W_CLASSES    0
#define STH_W_BLOCKING   0

/* What a search did: how many positions, how deep the last iteration that
 * FINISHED went, in plies, its value for the seat to move, and whether the
 * budget ran out part way through the next. */
struct sth_search_info {
    unsigned long long nodes;
    int depth;
    int score;
    int stopped;
    int reserved[4];
};

/* A seat home scores STH_WIN_SCORE, and each place better than last adds
 * STH_PLACE_STEP; a game that ends with a seat still out scores it below
 * -STH_WIN_SCORE. Racing scores lie far inside both. */
#define STH_WIN_SCORE  100000
#define STH_PLACE_STEP 1000
#define STH_INF        1000000

/* Which search. AUTO is the paranoid search: every rival against the seat to
 * move, which with two seats is the plain game. MAXN: every seat for itself. */
#define STH_SEARCH_AUTO     0
#define STH_SEARCH_PARANOID 1
#define STH_SEARCH_MAXN     2

/* ---- the table ------------------------------------------------------------------ */

struct sth_board;

struct sth_abi {
    int abi_version;

    /* ---- version 1: the board -------------------------------------------------- */

    /* A board with every seat in its start, seat 0 to move. NULL when the
     * engine does not build that seat count with that many pieces. */
    struct sth_board * (*board_new)(int seats, int pieces);

    /* The same, with every hole empty. */
    struct sth_board * (*board_empty)(int seats, int pieces);

    /* NULL when the string is refused, and *err set to the STH_POS_ code. */
    struct sth_board * (*board_of_string)(const char *str, int *err);

    struct sth_board * (*board_copy)(const struct sth_board *b);
    void               (*board_drop)(struct sth_board *b);
    int                (*live)(void);                        /* boards not yet dropped */

    /* What a hole holds: a seat, or STH_EMPTY; STH_OFF for a number that is
     * not a hole. */
    int  (*at)(const struct sth_board *b, int hole);

    /* Structure primitives. put places a seat's piece, replacing what was
     * there; lift empties the hole. Both keep the key and the counts, and both
     * do nothing to a number that is not a hole or a seat the board does not
     * have. */
    void (*put)(struct sth_board *b, int hole, int seat);
    void (*lift)(struct sth_board *b, int hole);

    int  (*to_move)(const struct sth_board *b);
    void (*set_to_move)(struct sth_board *b, int seat);
    int  (*seats)(const struct sth_board *b);
    int  (*pieces)(const struct sth_board *b);
    int  (*count)(const struct sth_board *b, int seat);

    /* the key, the seats count, the seat to move and every piece */
    unsigned long long (*key)(const struct sth_board *b);
    unsigned long long (*zobrist)(int seat, int hole);
    unsigned long long (*zobrist_move)(int seat);
    unsigned long long (*zobrist_seats)(int seats);

    /* Writes the position string and its length, with no NUL counted, or -1
     * when `max` is too small. */
    int  (*to_string)(const struct sth_board *b, char *out, int max);

    /* ---- geometry, the same for every board ------------------------------------ */

    /* 1 when the tables were built and every count in this header agreed with
     * them. When it is 0, board_new and board_empty build nothing. */
    int  (*tables_ok)(void);

    int  (*layout_ok)(int seats, int pieces);

    /* The point seat `seat` starts in, for that many seats; -1 when there is
     * no such seat. */
    int  (*layout_point)(int seats, int seat);

    /* The hole at cube (x, y), or -1. */
    int  (*hole_of)(int x, int y);
    int  (*hole_x)(int hole);
    int  (*hole_y)(int hole);
    int  (*row_of)(int hole);
    int  (*col_of)(int hole);
    int  (*row_len)(int row);
    int  (*row_start)(int row);

    /* The neighbour of `hole` in direction `dir`, or -1. */
    int  (*next)(int hole, int dir);
    int  (*degree)(int hole);
    int  (*dir_opposite)(int dir);

    int  (*point_of)(int hole);                  /* 0 to 5, or STH_CENTRE   */
    int  (*on_ring)(int hole);
    int  (*class_of)(int hole);

    /* The ten holes of a point and the five ring holes in front of it, in
     * hole order. Each writes at most `max` and returns how many there are. */
    int  (*point_holes)(int point, int *out, int max);
    int  (*front)(int point, int *out, int max);

    /* Every neighbouring pair once, lower hole first, as 2 * STH_PAIRS ints.
     * Returns the number of PAIRS there are. */
    int  (*pairs)(int *out, int max);

    /* ---- version 2: one step and one hop ------------------------------------ */

    /* The empty neighbours of `hole`, in direction order. */
    int  (*steps)(const struct sth_board *b, int hole, int *out, int max);

    /* Where one hop from `hole` lands, in direction order. `from` is the hole
     * the moving piece left: it counts as EMPTY, so a hop may land on it and
     * may not go over it, and the board may still show the piece there. Pass
     * `hole` itself, or -1, for a piece standing where it is. */
    int  (*hops)(const struct sth_board *b, int hole, int from, int *out, int max);

    /* Moves the piece on `from` to the empty hole `to`, wherever it is, and
     * keeps the key. Returns 1, or 0 and does nothing when `from` holds no
     * piece or `to` is not an empty hole. The seat to move is not touched. */
    int  (*do_move)(struct sth_board *b, int from, int to);

    /* Takes that move back: the piece on `to` returns to the empty `from`. */
    int  (*undo_move)(struct sth_board *b, int from, int to);

    /* ---- version 3: a move ------------------------------------------------ */

    /* Every hole the piece on `from` can stop on, in hole order: its steps,
     * and every hole a chain of hops reaches, wherever the chain stops. Never
     * `from` itself. 0 when `from` holds no piece. */
    int  (*reach)(const struct sth_board *b, int from, int *out, int max);

    /* The move from `from` to `to`, as holes from `from` to `to`: two for a
     * step, and for a chain the start and every landing. A hole a step
     * reaches is always shown as the step. A chain is a shortest one, and
     * among those the one found first trying directions in order. 0 when `to`
     * is not in the reach. */
    int  (*path)(const struct sth_board *b, int from, int to, int *out, int max);

    /* The moves of the seat to move, as pairs: for each of its pieces in hole
     * order, its reach in hole order. No pair twice. */
    int  (*legal)(const struct sth_board *b, int *out_from, int *out_to, int max);

    /* ---- version 4: a game -------------------------------------------------- */

    /* The seat's home is full and at least one piece in it is its own. A
     * question about the position: a seat can be home and not yet counted. */
    int  (*home_complete)(const struct sth_board *b, int seat);

    /* The seat has been counted home, in this game. */
    int  (*finished)(const struct sth_board *b, int seat);

    /* 1 for the best place, places shared on equal distance at the cap or a
     * deadlock; 0 while the game runs for a seat not yet home. */
    int  (*place_of)(const struct sth_board *b, int seat);

    /* How far the seat's pieces are from its home: 0 for a home full of its
     * own pieces, more for every piece out of place. Places a capped game. */
    int  (*distance_left)(const struct sth_board *b, int seat);

    /* The seat to move has no move, and the game runs. */
    int  (*can_pass)(const struct sth_board *b);

    /* The seat to move moves its piece on `from` to `to`, which must be in the
     * piece's reach. On STH_PLAY_OK, `undo` (if given) can take it back. On a
     * refusal nothing changes and `undo` is not written. */
    int  (*play)(struct sth_board *b, int from, int to, struct sth_undo *undo);

    /* The seat to move passes; only when it has no move. */
    int  (*pass)(struct sth_board *b, struct sth_undo *undo);

    /* A seat still racing resigns, on its turn or not. */
    int  (*resign)(struct sth_board *b, int seat, struct sth_undo *undo);

    /* Takes back the play, pass or resign `undo` records. Undos are taken in
     * the reverse of the order they were made. 1, or 0 when it cannot be. */
    int  (*unplay)(struct sth_board *b, const struct sth_undo *undo);

    int  (*game_over)(const struct sth_board *b);
    int  (*game_how)(const struct sth_board *b);
    int  (*ply)(const struct sth_board *b);
    int  (*cap)(const struct sth_board *b);

    /* A cap above 0, in plies; a game past it already ends on its next ply. */
    void (*set_cap)(struct sth_board *b, int cap);

    /* ---- version 6: choosing a move ------------------------------------------ */

    void (*weights_default)(struct sth_weights *w);

    /* the seat's score, higher better, in the units of the weights */
    int  (*evaluate)(const struct sth_board *b, int seat, const struct sth_weights *w);

    /* The move the seat to move should make, into best_from and best_to, both
     * -1 for a pass. Returns 1, or 0 when the game is over. The board is not
     * touched: the search plays into a copy.
     *
     *   budget     positions looked at; the first iteration always finishes
     *   seed       settles the choice among moves of equal value, and nothing
     *              else; 0 is taken as 1
     *   max_depth  plies to look ahead; 0 for no limit but the budget
     *   mode       STH_SEARCH_AUTO, _PARANOID or _MAXN
     *   avoid      own_key()s the seat to move's pieces have already had,
     *              avoid_n of them (NULL and 0 for none): a move that puts
     *              its pieces back as they were is not made while another
     *              move is there. Without it searching seats can shuffle in
     *              their homes for ever. */
    int  (*search)(const struct sth_board *b, const struct sth_weights *w, unsigned long long budget,
                   unsigned long long seed, int max_depth, int mode,
                   const unsigned long long *avoid, int avoid_n,
                   int *best_from, int *best_to, struct sth_search_info *info);

    /* A seeded random choice among the moves that take a piece nearer its
     * home, or among all moves when none does; -1 and -1 for a pass. */
    int  (*random_forward)(const struct sth_board *b, unsigned long long seed, int *best_from, int *best_to);

    /* A key over one seat's pieces alone: where they stand, and nothing of
     * anyone else's. What `avoid` holds. */
    unsigned long long (*own_key)(const struct sth_board *b, int seat);
};

const struct sth_abi *sth_abi_table(void);

#endif
