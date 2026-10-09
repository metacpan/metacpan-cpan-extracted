#ifndef BD_ABI_H
#define BD_ABI_H

/* Public C ABI for Game::Brandubh, the 7 by 7 tafl board, and anything that
 * wants to keep a brandubh position without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in bd_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to wasm.
 * The table is resolved at RUNTIME via Game::Brandubh::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of xq_abi.h and go_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. BD_ABI_VERSION bumps on any append, and
 * a consumer requires abi_version >= the version it was written against, NEVER
 * ==. A sibling that used == stopped loading everywhere the moment its provider
 * appended one member.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * AT VERSION 1, THE BOARD AND NOTHING ELSE: squares, the three pieces, the two
 * sides, the throne and the corners as geometry, a zobrist key, and the
 * position string in and out.
 *
 * AT VERSION 2, WHERE A PIECE MAY GO: the rule set as a struct, a packed move,
 * the move list, why a move was refused, and a perft that counts slides. NO
 * CAPTURE YET: `relocate` moves one piece and passes the turn and removes
 * nothing.
 *
 * AT VERSION 3, WHAT A MOVE CAPTURES: the one predicate that says which squares
 * are an enemy, the pieces a move takes, do and undo, and a perft that plays
 * captures. NOTHING HERE KNOWS HOW A GAME ENDS: do_move reports that the king
 * was taken or reached home and plays on regardless.
 *
 * AT VERSION 4, A GAME: a board with the moves that made it, how it ends, and
 * who won. game_do is the first call in this table that REFUSES a move. A
 * board on its own still judges nothing about endings: do_move plays on after
 * a king is taken, and only a game stops.
 *
 * AT VERSION 5, CHOOSING A MOVE: an evaluation in integers, and a search
 * bounded in nodes and never in seconds.
 *
 * `put` and `lift` are STRUCTURE PRIMITIVES and JUDGE NOTHING. A caller may put
 * two kings on a corner or a defender on the throne.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the zobrist key which is
 * an unsigned 64-bit value. THERE ARE NO FLOATS ANYWHERE IN THIS ENGINE, so none
 * of the fused-multiply-add reproducibility work a sibling needed for its
 * doubles applies here. Do not copy -ffp-contract=off into this dist's
 * Makefile.PL; there is nothing for it to protect.
 *
 * A SQUARE IS AN OPAQUE PADDED INDEX. The board is 9 by 9 cells with a sentinel
 * ring of BD_BORDER all round, so a slide walks until it meets something that is
 * not BD_EMPTY and needs no bounds test:
 *
 *     stride        = 9
 *     square(f, r)  = (r + 1) * stride + (f + 1)
 *     orthogonals   = sq - 1, sq + 1, sq - stride, sq + stride
 *
 * A square is therefore NOT rank * 7 + file, and nothing outside the engine may
 * assume it is. Use (BD->square_of) to build one and (BD->file_of) /
 * (BD->rank_of) to take one apart.
 *
 * FILE 0 IS a AND RANK 0 IS 1. Rank 0 is the bottom row of the diagram, and a
 * position string's FIRST row is rank 6, as a chess FEN's first row is rank 8.
 *
 * THE SPECIAL SQUARES ARE GEOMETRY AND NOT CONTENTS. An empty throne reads
 * BD_EMPTY like any other empty square. What makes it special is a caller
 * asking (BD->is_throne).
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h turns
 * into function-like macros under PERL_IMPLICIT_SYS. That is why the destructor
 * is board_drop and not board_free. Call through the table with the member in
 * parentheses anyway: (BD->board_drop)(b).
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new, board_empty, board_of_string and board_copy return a board the
 * caller drops with board_drop. A board holds no pointers, so a copy is a flat
 * byte copy and two boards never share anything. to_string writes into a caller
 * buffer sized at least BD_POS_MAX. Nothing is retained between calls and
 * nothing is global except the zobrist table, which is derived deterministically
 * from a fixed seed and is therefore safe to compute twice, and the count of
 * live boards, which exists for a leak test and is not synchronised.
 */

/* Version 1 is the board. Version 2 appends the rule set, generation and the
 * slide perft. Version 3 appends capture, do and undo. Version 4 appends the
 * game and its endings. Version 5 appends the evaluation and the search. Nothing that existed at an earlier version moves or changes
 * meaning, which is the only kind of change the >= rule survives. */
#define BD_ABI_VERSION 5

/* ---- cells. BD_EMPTY is 0 so a zeroed square is an empty square ------------- */

#define BD_EMPTY     0
#define BD_ATTACKER  1
#define BD_DEFENDER  2
#define BD_KING      3
#define BD_BORDER    4

#define BD_IS_PIECE(p) ((p) >= BD_ATTACKER && (p) <= BD_KING)

/* ---- the two sides. The king is on the defenders' side, and bd_side_of is the
 * one place that says so. ----------------------------------------------------- */

#define BD_ATTACKERS 0
#define BD_DEFENDERS 1

#define BD_OTHER(s) ((s) == BD_ATTACKERS ? BD_DEFENDERS : BD_ATTACKERS)

/* ---- the board ------------------------------------------------------------- */

#define BD_SIZE     7
#define BD_STRIDE   (BD_SIZE + 2)            /* 9  */
#define BD_CELLS    (BD_STRIDE * BD_STRIDE)  /* 81 */
#define BD_SQUARES  (BD_SIZE * BD_SIZE)      /* 49 */

/* The longest string this writer emits is 7 rows of 7, 6 slashes, a space and a
 * side: 57 characters. Sized for a caller's stack buffer. */
#define BD_POS_MAX 64

/* ---- why a position string was refused ---------------------------------------
 *
 * BD_OK is 0. Every other value names one fault, because "that string is bad"
 * is not a thing a caller can act on.
 *
 * A string is refused for its SHAPE and never for its sense: two kings, no
 * king, or a defender on a corner all load, because they are positions a test
 * needs to build.
 */

#define BD_OK          0
#define BD_POS_NULL    1   /* no string at all, or an empty one             */
#define BD_POS_ROWS    2   /* not seven rows                                */
#define BD_POS_WIDTH   3   /* a row that is not seven files wide            */
#define BD_POS_LETTER  4   /* a character that is not a, d, k or 1 to 7     */
#define BD_POS_SIDE    5   /* the side field is missing, or is not a or d   */
#define BD_POS_LONG    6   /* BD_POS_MAX characters or more                 */

/* ---- the rule set, version 2 --------------------------------------------------
 *
 * FROZEN AT THIS SIZE, and that is a different rule from the table's. The table
 * may grow because a consumer only reads members it knows about. This struct is
 * allocated by the CALLER and read by the callee, so a field added later would
 * have a newer engine read past the end of an older caller's struct. Every
 * field the plan names is here from the first version that has the struct,
 * used or not, and `reserved` is the only room there will ever be. A reserved
 * int of 0 must always mean "as before".
 *
 * Fill one with (BD->variant_default) and then change what differs. A NULL
 * variant anywhere in this table means the default.
 */

struct bd_variant {
    int throne_pass;          /* 1: a piece may slide across the empty throne   */
    int throne_reentry;       /* 1: the king may land on the throne again       */
    int king_everywhere_two;  /* 1: the king is taken by two wherever he is     */
    int king_strong;          /* 1: the king needs every side closed            */
    int escape_edge;          /* 1: the king is home on any edge square         */
    int repeat;               /* which occurrence of a position draws the game  */
    int ply_cap;              /* the ply at which a game is drawn               */
    int reserved[4];
};

#define BD_REPEAT_DEFAULT   3
#define BD_PLY_CAP_DEFAULT  400   /* provisional until the search has measured it */

/* A game keeps four arrays as long as its cap, so the cap has a ceiling. A
 * cap of 0 or less, or above this, means the default; a repeat below 2 would
 * draw every game at its first position, and means 2. */
#define BD_PLY_CAP_MAX      4096

/* ---- a move, version 2 --------------------------------------------------------
 *
 * A move is a packed int and nothing outside this header may unpack one by
 * hand. From and to are squares, each under 128, so seven bits apiece. What a
 * move CAPTURES is a function of the position and is not stored in the move.
 *
 * BD_MOVES_MAX is the buffer a caller must supply, and it is a PROOF and not a
 * guess. Along one line every empty square can be reached by at most two
 * pieces, the nearest on each side of it, so a line holding k >= 2 pieces of
 * the mover yields at most 2 * (7 - k) <= 10 moves and a line holding one
 * yields at most 6. Seven ranks and seven files: at most 140 on ANY board,
 * whatever is standing on it. gen_moves never writes past the max it is given
 * and returns the number it FOUND, so a short buffer is detectable.
 */

#define BD_MOVES_MAX 144

/* ---- why a move is not one, version 2 ------------------------------------------
 *
 * BD_WHY_OK is 0 and means the move is legal. why_not agrees with is_legal on
 * every pair of squares, and a test holds it to that.
 */

#define BD_WHY_OK          0
#define BD_WHY_OFF_BOARD   1   /* one of the two is not a square               */
#define BD_WHY_NO_PIECE    2   /* nothing stands on `from`                     */
#define BD_WHY_NOT_YOURS   3   /* the piece is not of the side to move         */
#define BD_WHY_NO_MOVE     4   /* from and to are the same square              */
#define BD_WHY_NOT_A_LINE  5   /* not along a rank or a file                   */
#define BD_WHY_THRONE      6   /* it would stop on the throne, or cross a      *
                                * throne the rule set does not let it cross    */
#define BD_WHY_CORNER      7   /* only the king may stand on a corner          */
#define BD_WHY_BLOCKED     8   /* a piece is in the way, or on `to`            */

/* ---- what a move did, version 3 ---------------------------------------------
 *
 * do_move returns these, or'd together, and writes them into the undo. They
 * are REPORTS and not rulings: the engine at this version plays on after
 * either of the last two.
 */

#define BD_DID_CAPTURE  1   /* at least one piece was taken                     */
#define BD_KING_TAKEN   2   /* a king was among them                            */
#define BD_KING_HOME    4   /* the king moved, and ended where he wins          */

/* One move takes at most three pieces: it can close on an enemy in three
 * directions and the fourth is the way it came. The arrays hold FOUR because
 * do_move does not ask whether the move was legal, and a piece set down in the
 * middle of four enemies by a caller that did not slide it there closes on
 * four. */
#define BD_CAPTURES_MAX 4

/* An undo carries everything do_move destroyed, so undo_move restores the
 * position EXACTLY, key included. It is a value type: copy it, do not free it.
 *
 * FROZEN, for the reason bd_variant is: the caller allocates it and the engine
 * writes it. */
struct bd_undo {
    int mv;                          /* 0 when do_move did nothing             */
    int flags;                       /* BD_DID_CAPTURE and the rest            */
    int n;                           /* how many were taken                    */
    int square[BD_CAPTURES_MAX];     /* where each stood                       */
    int piece[BD_CAPTURES_MAX];      /* and what it was                        */
    int side;                        /* whose turn it was before the move      */
    unsigned long long key;          /* the key before the move                */
};

/* ---- how a game ended, version 4 ---------------------------------------------
 *
 * BD_ONGOING is 0. Two wins for the defenders, one for the attackers, three
 * draws. Agreement and resignation are not here: they are something two
 * people do, and the caller records them.
 *
 * THEY ARE ASKED IN THIS ORDER, because one move can satisfy two: the win the
 * move itself made, then no pieces, then no move, then repetition, then the
 * cap.
 */

#define BD_ONGOING          0
#define BD_BY_CORNER        1   /* the king's move ended where he wins          */
#define BD_BY_CAPTURE       2   /* an attacker's move captured the king        */
#define BD_BY_NO_PIECES     3   /* the attackers have no piece left            */
#define BD_DRAW_REPETITION  4   /* the position occurred for the Nth time      */
#define BD_DRAW_NO_MOVE     5   /* the side to move has pieces and no move     */
#define BD_DRAW_PLY_CAP     6   /* the ply count reached the cap               */

/* what game_do answers */
#define BD_PLAY_OK       0
#define BD_PLAY_OVER     1   /* the game has ended; nothing was played        */
#define BD_PLAY_ILLEGAL  2   /* not a move of the side to move; nothing was   */

/* ---- the evaluation and the search, version 5 -----------------------------------
 *
 * THE WEIGHTS of the evaluation, each an int. FROZEN at this size, as
 * bd_variant is and for its reason: the caller allocates one and the engine
 * reads it. Fill one with (BD->weights_default) and change what differs; a
 * NULL anywhere means the default.
 *
 * The evaluation is scored FOR THE ATTACKERS. A positive number is good for
 * them.
 */
struct bd_weights {
    int attacker;       /* each attacker on the board                         */
    int defender;       /* each defender on the board, against               */
    int lane_one;       /* each winning square the king reaches in one move   */
    int lane_two;       /* each he reaches in two and not in one              */
    int freedom;        /* each square the king can move to at all            */
    int corner_guard;   /* each attacker on a square that closes a corner     */
    int ring;           /* each attacker standing next to the king            */
    int reserved[5];
};

/* What a search did. Reported and not inferred: how deep it got and what it
 * cost are invisible from the move it returns. FROZEN: the caller allocates
 * it and the engine writes it. */
struct bd_search_info {
    unsigned long long nodes;
    int depth;            /* the deepest iteration that FINISHED               */
    int score;            /* for the side to move                              */
    int stopped;          /* 1 if the budget ran out part way through one      */
};

/* A win is a score and not a flag, less the number of moves it is away, so a
 * win in one is preferred to a win in three and a loss in three to a loss in
 * one. */
#define BD_WIN_SCORE 30000

struct bd_board;
struct bd_game;

struct bd_abi {
    unsigned int abi_version;

    /* lifecycle */
    struct bd_board * (*board_new)(void);                 /* the set-up        */
    struct bd_board * (*board_empty)(void);               /* no pieces at all  */
    struct bd_board * (*board_of_string)(const char *s, int *err);
    struct bd_board * (*board_copy)(const struct bd_board *b);
    void              (*board_drop)(struct bd_board *b);
    int               (*live)(void);                      /* boards not yet dropped */

    /* structure, judging nothing */
    int  (*at)(const struct bd_board *b, int sq);
    void (*put)(struct bd_board *b, int sq, int piece);
    void (*lift)(struct bd_board *b, int sq);
    int  (*side)(const struct bd_board *b);
    void (*set_side)(struct bd_board *b, int side);
    int  (*count)(const struct bd_board *b, int piece);
    int  (*king_square)(const struct bd_board *b);        /* or -1 */

    /* the key and the string */
    unsigned long long (*key)(const struct bd_board *b);       /* maintained   */
    unsigned long long (*key_full)(const struct bd_board *b);  /* recomputed   */
    unsigned long long (*zobrist)(int piece, int sq);
    unsigned long long (*zobrist_side)(void);
    int  (*to_string)(const struct bd_board *b, char *buf, int len);

    /* geometry */
    int (*stride)(void);
    int (*square_of)(int file, int rank);                 /* or -1 */
    int (*file_of)(int sq);                               /* or -1 */
    int (*rank_of)(int sq);                               /* or -1 */
    int (*on_board)(int sq);
    int (*is_throne)(int sq);
    int (*is_corner)(int sq);
    int (*beside_throne)(int sq);
    int (*side_of)(int piece);                            /* or -1 */

    /* ---- version 2: where a piece may go --------------------------------- */

    void (*variant_default)(struct bd_variant *v);

    int (*move_make)(int from, int to);
    int (*move_from)(int mv);
    int (*move_to)(int mv);

    /* the moves of the side to move, in square order then left, right, down,
     * up. Writes at most `max`, returns how many there ARE. */
    int (*gen_moves)(const struct bd_board *b, const struct bd_variant *v, int *out, int max);
    int (*is_legal)(const struct bd_board *b, const struct bd_variant *v, int mv);
    int (*why_not)(const struct bd_board *b, const struct bd_variant *v, int from, int to);

    /* NOT A RULES CALL. Moves whatever is on `from` to `to`, replacing what
     * was there, and passes the turn. It captures nothing and asks nothing. */
    void (*relocate)(struct bd_board *b, int mv);

    /* leaf nodes of the capture-free game, to `depth` plies. The board is
     * left as it was found. */
    unsigned long long (*perft_slides)(struct bd_board *b, const struct bd_variant *v, int depth);

    /* ---- version 3: what a move captures --------------------------------- */

    /* THE ONE PREDICATE. Is `sq` an enemy of `side` for the purpose of a
     * capture: an enemy piece, an empty corner, or the empty throne. The edge
     * of the board never is. */
    int (*hostile_to)(const struct bd_board *b, int sq, int side);

    /* The squares whose pieces are captured by the piece NOW STANDING on
     * `to`, which has just arrived there. Only that piece captures, so the
     * search goes outward from its square and nowhere else. Writes up to
     * BD_CAPTURES_MAX squares, returns how many. Judges on the board as it
     * stands and removes nothing. */
    int (*captures_at)(const struct bd_board *b, const struct bd_variant *v, int to, int *out);

    /* Moves the piece, removes what it captured, passes the turn, and returns
     * the flags. IT DOES NOT ASK WHETHER THE MOVE IS LEGAL; that is is_legal.
     * It asks only that something stands on `from` and nothing on `to`, and
     * when that is not so it does nothing, returns 0 and sets u->mv to 0. */
    int  (*do_move)(struct bd_board *b, const struct bd_variant *v, int mv, struct bd_undo *u);
    void (*undo_move)(struct bd_board *b, const struct bd_undo *u);

    /* What do_move would take and report, on a board it leaves alone. */
    int (*preview)(const struct bd_board *b, const struct bd_variant *v, int mv, int *out, int *flags);

    /* leaf nodes to `depth` plies with captures played. No ending stops it: a
     * side whose king is gone moves what it has left. */
    unsigned long long (*perft)(struct bd_board *b, const struct bd_variant *v, int depth);

    /* ---- version 4: a game ------------------------------------------------ */

    /* A game from a COPY of `b`, or from the set-up when `b` is NULL. The
     * rule set is copied in too and cannot be changed afterwards. */
    struct bd_game * (*game_new)(const struct bd_board *b, const struct bd_variant *v);
    struct bd_game * (*game_copy)(const struct bd_game *g);
    void             (*game_drop)(struct bd_game *g);
    int              (*games_live)(void);                 /* games not yet dropped */

    /* The game's own board, BORROWED: read it, never write it, never drop
     * it, and do not keep it past the game. */
    const struct bd_board * (*game_board)(const struct bd_game *g);
    void (*game_variant)(const struct bd_game *g, struct bd_variant *out);
    int  (*game_ply)(const struct bd_game *g);            /* moves made so far     */
    int  (*game_cap)(const struct bd_game *g);            /* the cap, as clamped   */
    int  (*game_outcome)(const struct bd_game *g);        /* BD_ONGOING and the rest */
    int  (*game_winner)(const struct bd_game *g);         /* a side, or -1         */
    int  (*winner_of)(int outcome);                       /* a side, or -1         */
    unsigned long long (*game_key_at)(const struct bd_game *g, int ply);

    /* the moves of the side to move, and NONE once the game is over */
    int  (*game_moves)(const struct bd_game *g, int *out, int max);

    /* how many times the current position has occurred, this time included */
    int  (*repeats)(const struct bd_game *g);

    /* Plays a move and answers BD_PLAY_OK, or refuses and leaves the game
     * exactly as it was. `flags` receives what do_move reported. */
    int  (*game_do)(struct bd_game *g, int mv, int *flags);
    /* Takes the last move back. 0 when there is none. */
    int  (*game_undo)(struct bd_game *g);

    /* ---- version 5: choosing a move ---------------------------------------- */

    /* game_do for a caller that TOOK THE MOVE FROM A MOVE LIST and will make
     * its own list at the next position. Two things game_do asks are not asked:
     * whether the move is legal, and whether the side now to move has any move.
     * So the outcome after a push can read BD_ONGOING for a side that is
     * blocked, and the caller finds that out from its own empty list. Every
     * other ending is judged as game_do judges it. It is for a search and for
     * nothing else. Always plays; `flags` as game_do. */
    void (*game_push)(struct bd_game *g, int mv, int *flags);

    void (*weights_default)(struct bd_weights *w);

    /* the position scored for the ATTACKERS, in the units of the weights */
    int  (*evaluate)(const struct bd_board *b, const struct bd_variant *v, const struct bd_weights *w);

    /* The best move for the side to move, or 0 when the game is over. The
     * game is not touched: the search plays into a copy.
     *
     *   budget     nodes. Asked about every 1,024, so it may be passed by
     *              that many; and the first iteration always finishes, so a
     *              budget smaller than one node a legal move is passed by it.
     *   seed       settles the choice among moves of equal score, and nothing
     *              else. 0 is taken as 1.
     *   max_depth  0 for no limit but the budget.
     */
    int  (*search)(const struct bd_game *g, const struct bd_weights *w,
                   unsigned long long budget, unsigned long long seed, int max_depth,
                   struct bd_search_info *info);
};

const struct bd_abi *bd_abi_table(void);

#endif
