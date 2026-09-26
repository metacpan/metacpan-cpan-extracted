#ifndef XQ_ABI_H
#define XQ_ABI_H

/* Public C ABI for Game::Xiangqi, the xiangqi board, and anything that wants to
 * keep a xiangqi position without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in xq_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to wasm.
 * The table is resolved at RUNTIME via Game::Xiangqi::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of go_abi.h and pb_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. XQ_ABI_VERSION bumps on any append, and
 * a consumer requires abi_version >= the version it was written against, NEVER
 * ==. A sibling that used == stopped loading everywhere the moment its provider
 * appended one member.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * AT VERSION 1, THE BOARD AND NOTHING ELSE: points, pieces, the palace and the
 * river as geometry, a packed move, do and undo, a zobrist key, and FEN in and
 * out.
 *
 * AT VERSION 2, GENERATION AND THE ATTACK WALK: the five named predicates,
 * pseudo-legal and legal move lists, `attacked`, `in_check` and perft.
 *
 * `put` and `lift` are STRUCTURE PRIMITIVES and JUDGE NOTHING. A caller may put
 * a soldier in its own palace, stack three generals on one point, or leave a
 * side with no general at all. `do_move` is likewise not a rules call: it moves
 * whatever is on `from` to `to` and maintains the key. Only `gen_legal` filters.
 *
 * Mate, the stalemate loss and the Asian Rules judge are phases 04 to 06 and
 * they APPEND to this table rather than changing it.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the zobrist key which is
 * an unsigned 64-bit value. THERE ARE NO FLOATS ANYWHERE IN THIS ENGINE, so none
 * of the fused-multiply-add reproducibility work a sibling needed for its
 * doubles applies here. Do not copy -ffp-contract=off into this dist's
 * Makefile.PL; there is nothing for it to protect.
 *
 * A POINT IS AN OPAQUE PADDED INDEX. The board is 11 by 12 cells with a sentinel
 * ring of XQ_BORDER all round, so a neighbour walk needs no bounds test:
 *
 *     stride       = 11
 *     point(f, r)  = (r + 1) * stride + (f + 1)
 *     orthogonals  = pt - 1, pt + 1, pt - stride, pt + stride
 *     diagonals    = pt +/- (stride + 1), pt +/- (stride - 1)
 *
 * A point is therefore NOT rank * 9 + file, and nothing outside the engine may
 * assume it is. Use (XQ->point_of) to build one and (XQ->file_of) /
 * (XQ->rank_of) to take one apart.
 *
 * ONE RING IS ENOUGH FOR EVERY MOVE IN THIS GAME, which is worth stating because
 * the elephant and the horse both land two cells from where they started. Both
 * are blocked at the INTERVENING point (the elephant's eye, the horse's leg),
 * and that intervening point is at most one cell outside the board, so the ring
 * catches the blocker; the destination is then caught by the same ring. Phase 03
 * asserts this rather than trusting this paragraph.
 *
 * RANK 0 IS RED'S BACK RANK and rank 9 is Black's, which is ICCS's numbering and
 * therefore the one the move log uses. A FEN's FIRST row is rank 9, as a chess
 * FEN's first row is rank 8.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h turns
 * into function-like macros under PERL_IMPLICIT_SYS. That is why the destructor
 * is board_drop and not board_free. Call through the table with the member in
 * parentheses anyway: (XQ->board_drop)(b).
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new, board_of_fen and board_copy return a board the caller drops with
 * board_drop. A board holds no pointers, so a copy is a flat byte copy and two
 * boards never share anything. to_fen writes into a caller buffer sized at least
 * XQ_FEN_MAX. Nothing is retained between calls and nothing is global except the
 * zobrist table, which is derived deterministically from a fixed seed and is
 * therefore safe to compute twice.
 */

/* Version 1 is the board: phase 02. Version 2 appends generation and the attack
 * walk: phase 03. Version 3 appends the endings and the mate search: phase 04.
 * Version 4 appends the Asian Rules vocabulary: phase 05. Version 5 appends the
 * judge: phase 06. Version 6 appends the search: phase 09. Version 7 appends the
 * depth-limited search: phase 10, because UCCI's `go depth N` is what makes an
 * external engine an oracle and a node budget cannot promise a depth. Nothing that
 * existed at an earlier version moves or changes meaning, which is the only kind of
 * change the >= rule survives. */
#define XQ_ABI_VERSION 7

/* ---- pieces. XQ_EMPTY is 0 so a zeroed board is an empty board -------------
 *
 * A piece is colour | kind. The two colour bits are disjoint from the three kind
 * bits, and XQ_BORDER carries neither, so a sentinel can never be mistaken for a
 * piece however it is masked.
 */

#define XQ_EMPTY     0
#define XQ_GENERAL   1
#define XQ_ADVISOR   2
#define XQ_ELEPHANT  3
#define XQ_CHARIOT   4
#define XQ_HORSE     5
#define XQ_CANNON    6
#define XQ_SOLDIER   7

#define XQ_RED       8
#define XQ_BLACK    16
#define XQ_BORDER   32

#define XQ_KIND(p)    ((p) & 7)
#define XQ_COLOUR(p)  ((p) & (XQ_RED | XQ_BLACK))
#define XQ_OTHER(c)   ((c) == XQ_RED ? XQ_BLACK : XQ_RED)
#define XQ_IS_PIECE(p) (XQ_KIND(p) != 0 && XQ_COLOUR(p) != 0)

/* ---- the board ------------------------------------------------------------- */

#define XQ_FILES    9
#define XQ_RANKS   10
#define XQ_STRIDE  (XQ_FILES + 2)              /* 11 */
#define XQ_CELLS   (XQ_STRIDE * (XQ_RANKS + 2)) /* 132 */
#define XQ_POINTS  (XQ_FILES * XQ_RANKS)       /* 90 */

/* the longest FEN this writer emits is well under this; sized for a caller's
 * stack buffer with room for the fields it does not use */
#define XQ_FEN_MAX 128

/* ---- why a FEN was refused --------------------------------------------------
 *
 * XQ_OK is 0. Every other value names one fault, because "that FEN is bad" is
 * not a thing a caller can act on and because two of these are reached by
 * strings that look correct.
 */

#define XQ_OK            0
#define XQ_FEN_NULL      1   /* no string at all                              */
#define XQ_FEN_ROWS      2   /* not ten rows                                  */
#define XQ_FEN_WIDTH     3   /* a row that is not nine files wide             */
#define XQ_FEN_LETTER    4   /* a letter that names no piece                  */
#define XQ_FEN_SIDE      5   /* the side field is not w, r or b               */
#define XQ_FEN_LONG      6   /* longer than XQ_FEN_MAX                        */

/* ---- a move, and an undo ----------------------------------------------------
 *
 * A move is a packed int and nothing outside this header may unpack one by hand:
 * phases 03 and beyond add flags to the spare bits and a caller that shifted for
 * itself would keep working and start lying.
 *
 * An undo carries everything do_move destroyed, so undo_move restores the
 * position EXACTLY, key included. It is a value type: copy it, do not free it.
 */

struct xq_undo {
    int mv;
    int captured;                    /* the piece that was on `to`, or XQ_EMPTY */
    int side;                        /* whose turn it was before the move       */
    unsigned long long key;          /* the key before the move                 */
};

/* ---- generation, version 2 ---------------------------------------------------
 *
 * XQ_MAX_MOVES is the buffer a caller must supply. The widest position anybody
 * has published for this game is a little over a hundred moves; 128 is that
 * with room, and gen_moves NEVER writes past it.
 */

#define XQ_MAX_MOVES 128

/* ---- how a game ended, version 3 ----------------------------------------------
 *
 * THE SIDE TO MOVE WITH NO LEGAL MOVE LOSES, in check or not.
 *
 *     "Unlike in chess, in which stalemate is a draw, in xiangqi, it is a loss
 *      for the player who has no legal move."
 *
 * Every chess engine's structure puts a DRAW on the stalemate line, so every
 * port of one to this game ships a bug that appears only in endgames, which is
 * where the games that matter are decided. `outcome` is written as one branch
 * with two reasons for exactly that reason: there is no code path here in which
 * "no legal move" produces a draw.
 */

#define XQ_ONGOING       0
#define XQ_BY_CHECKMATE  1   /* 將死: no legal move, and in check               */
#define XQ_BY_STALEMATE  2   /* no legal move, not in check, AND STILL A LOSS   */

/* The four counters of the published perft ladder.
 * FOUR COUNTERS AND NOT ONE, and the reason measured rather than assumed: when
 * three columns match exactly at every depth of every position and the fourth
 * does not, that says the GENERATOR is right and the accounting is ours. That
 * is not hypothetical, it is what happened here on 25 Sep 2026: nodes, checks
 * and captures agreed everywhere and mates was shifted by one ply, which a
 * single-column ladder would have read as a rules bug. Divide on the counter
 * that disagrees, not on nodes.
 */
/* FROZEN AT FOUR FIELDS, and this is a different rule from the table's.
 *
 * The table may grow because a consumer only ever reads members it knows about.
 * This struct is allocated by the CALLER and written by the callee, so adding a
 * field would have a version-3 engine write past the end of a version-2
 * caller's buffer. A fifth counter (stalemates, say) needs its own call and not
 * a fifth member. */
struct xq_perft {
    unsigned long long nodes;
    unsigned long long checks;
    unsigned long long captures;
    unsigned long long mates;    /* CHECKmates: a stalemate is not counted here */
};

/* ---- the judge, version 5 ------------------------------------------------------
 *
 * A POSITION CAN NEVER BE A DRAW IN THIS GAME. `outcome` says so by having no
 * draw value at all. Every draw xiangqi has is a property of a SEQUENCE, and
 * this is where they live.
 *
 * Two families, and the header keeps them apart because their authority differs:
 *
 *   THE ASIAN RULES, Chapter 4. Forty numbered rules on perpetual check and
 *   perpetual chase, plus four principles that decide between them. These are
 *   the rules of xiangqi.
 *
 *   THE THREE COUNTERS, and CXQ's thresholds. The Asian Rules are written for a
 *   REFEREE ("asked by the referee to alter", "has to change. Otherwise, it
 *   loses") and there is no referee here. CXQ is a website that had the same
 *   problem and published its answer, so these are its numbers and they are
 *   OURS by adoption, not the Asian Rules'. The rules page must say so.
 */

#define XQ_JUDGE_ONGOING          0
#define XQ_JUDGE_PERPETUAL_CHECK  1   /* Asian Rules 6: the checker loses      */
#define XQ_JUDGE_PERPETUAL_CHASE  2   /* Section 3's chase table: chaser loses */
#define XQ_JUDGE_MUTUAL           3   /* principle 2, and rules 7, 9 to 14     */
#define XQ_JUDGE_NO_VIOLATION     4   /* principle 1: both persist, draw       */
#define XQ_JUDGE_EFFECTIVE        5   /* CXQ: 120 effective moves each         */
#define XQ_JUDGE_PROGRESS         6   /* CXQ: 30 moves each with no progress   */
#define XQ_JUDGE_MOVES            7   /* CXQ: 300 moves each                   */

/* what a side was doing over the loop */
#define XQ_BEH_NONE      0
#define XQ_BEH_CHECK     1
#define XQ_BEH_CHASE     2
#define XQ_BEH_TTC       3
#define XQ_BEH_BLOCK     4
#define XQ_BEH_EXCHANGE  5
#define XQ_BEH_SACRIFICE 6
#define XQ_BEH_IDLE      7

/* CXQ's thresholds: "CXQ allows a player to check/chase 6 consecutive times
 * using one piece, 12 times using 2 pieces, and 18 times using 3 pieces before
 * considering the check/chase a perpetual check/chase." */
#define XQ_PERPETUAL_1  6
#define XQ_PERPETUAL_2 12
#define XQ_PERPETUAL_3 18

/* CXQ's three automatic draws */
#define XQ_EFFECTIVE_CAP 120
#define XQ_PROGRESS_CAP   30
#define XQ_MOVES_CAP     300

#define XQ_MAX_PLIES 1024

/* what the chase table says about one chaser kind against one victim kind */
#define XQ_CHASE_FORBIDDEN 1   /* the chaser must change, or loses */
#define XQ_CHASE_ALLOWED   2   /* the chased side must live with it */
#define XQ_CHASE_DRAW      3   /* neither is in breach; the game is drawn */

struct xq_chase_rule {
    int number;          /* the Asian Rules number, so a ruling can cite it */
    int chaser;          /* a kind, or 0 for any                            */
    int victim;          /* a kind, or 0 for any                            */
    int protectedness;   /* -1 any, 0 must be unprotected, 1 must be protected */
    int chasers;         /* 0 any, 1 exactly one piece, 2 two or more        */
    int victims;         /* 0 any, 1 exactly one, 2 two or more              */
    int verdict;         /* XQ_CHASE_*                                       */
    const char *text;    /* the source's own sentence, abbreviated           */
};

struct xq_verdict {
    int winner;          /* XQ_RED, XQ_BLACK, or 0                          */
    int reason;          /* XQ_JUDGE_*                                      */
    int rule;            /* the Asian Rules number that decided it, or 0    */
    int loop_from;       /* index of the first move of the loop, or -1      */
    int loop_len;
    int behaviour[2];    /* XQ_BEH_*, [0] red and [1] black                 */
    int run[2];          /* consecutive checks or chases at the end         */
    int kinds[2];        /* how many distinct piece kinds made that run     */
    int effective;       /* CXQ's three counters, as they stood             */
    int progress;
    int plies;
};

/* ---- what a search did, version 6 ---------------------------------------------
 *
 * Reported rather than inferred, because the two numbers a caller most wants to
 * know about a bot move are how much work it took and how deep it got, and both
 * are invisible from the move itself.
 */
struct xq_search_info {
    unsigned long long nodes;
    int depth;            /* the deepest iteration that COMPLETED */
    int score;            /* centi-soldiers, from the side to move */
    int stopped;          /* 1 if the budget ran out mid-iteration */
};

/* Mate is a score, not a flag, and it is adjusted by DISTANCE so a mate in one
 * beats a mate in three. Comfortably inside an int with room for the ply. */
#define XQ_MATE_SCORE 30000
#define XQ_IS_MATE(s) ((s) > XQ_MATE_SCORE - 1000 || (s) < -(XQ_MATE_SCORE - 1000))

struct xq_board;

struct xq_abi {
    unsigned int abi_version;

    /* lifecycle */
    struct xq_board * (*board_new)(void);                 /* the opening position */
    struct xq_board * (*board_empty)(void);               /* no pieces at all     */
    struct xq_board * (*board_of_fen)(const char *fen, int *err);
    struct xq_board * (*board_copy)(const struct xq_board *b);
    void              (*board_drop)(struct xq_board *b);

    /* structure, judging nothing */
    int  (*at)(const struct xq_board *b, int pt);
    void (*put)(struct xq_board *b, int pt, int piece);
    void (*lift)(struct xq_board *b, int pt);
    int  (*side)(const struct xq_board *b);
    void (*set_side)(struct xq_board *b, int colour);
    int  (*count)(const struct xq_board *b, int piece);   /* pieces of that exact code */
    int  (*find)(const struct xq_board *b, int piece);    /* first point, or 0 */

    /* moves */
    int  (*move_make)(int from, int to);
    int  (*move_from)(int mv);
    int  (*move_to)(int mv);
    int  (*do_move)(struct xq_board *b, int mv, struct xq_undo *u); /* -> captured */
    void (*undo_move)(struct xq_board *b, const struct xq_undo *u);

    /* identity */
    unsigned long long (*key)(const struct xq_board *b);
    int  (*to_fen)(const struct xq_board *b, char *buf, int len);
    unsigned long long (*zobrist)(int piece, int pt);     /* exposed for a test */

    /* geometry, so nothing outside synthesises an index */
    int  (*point_of)(int file, int rank);
    int  (*file_of)(int pt);
    int  (*rank_of)(int pt);
    int  (*on_board)(int pt);
    int  (*in_palace)(int pt, int colour);
    int  (*crossed_river)(int pt, int colour);
    int  (*stride)(void);

    /* ---- appended at version 2, phase 03 -----------------------------------
     *
     * The five predicates are separate members ON PURPOSE. A generator written
     * as one loop with the blocking folded in cannot be tested in pieces, and
     * four of these five are the rules a reader of the code will get wrong.
     */

    int  (*horse_leg)(const struct xq_board *b, int from, int to);
        /* the point that hobbles the horse (蹩馬腿), or -1 if `to` is not a
         * horse move from `from` at all. Empty leg means the move is on. */
    int  (*elephant_eye)(const struct xq_board *b, int from, int to);
        /* the point that blocks the elephant (塞象眼), or -1 as above */
    int  (*cannon_screens)(const struct xq_board *b, int from, int to);
        /* occupied points strictly between, or -1 if not on one rank or file.
         * 0 screens and an empty destination is a move; 1 screen and an enemy
         * on the destination is a capture; NOTHING ELSE IS. */
    int  (*soldier_may)(const struct xq_board *b, int from, int to);
    int  (*generals_face)(const struct xq_board *b);
        /* the flying general: 1 when the two generals see each other down an
         * open file. Creating that is moving into check, so `gen_legal`
         * refuses it; the capture itself is therefore never generated. */

    int  (*gen_moves)(const struct xq_board *b, int *out);   /* pseudo-legal */
    int  (*gen_legal)(struct xq_board *b, int *out);
    int  (*attacked)(const struct xq_board *b, int pt, int by);
    int  (*in_check)(const struct xq_board *b, int colour);

    void (*perft)(struct xq_board *b, int depth, struct xq_perft *out);

    /* ---- appended at version 3, phase 04 ----------------------------------- */

    int  (*outcome)(struct xq_board *b, int *reason);
        /* the winning COLOUR (XQ_RED or XQ_BLACK), or 0 while the game is on.
         * `reason` takes XQ_BY_CHECKMATE or XQ_BY_STALEMATE, and BOTH are wins
         * for the side NOT to move. Pass NULL if the reason is not wanted. */

    int  (*mate_in)(struct xq_board *b, int plies);
        /* 1 when the side to move can FORCE CHECKMATE within `plies` half-moves.
         *
         * CHECKMATE SPECIFICALLY, not "a win": a forced stalemate is also a win
         * in this game and this function says nothing about one. That is right
         * for its caller, which is the Asian Rules' "threatening to checkmate"
         * in phase 05, and it is a trap for anybody else. A search wanting
         * terminal values uses `outcome`, which counts both. */

    /* ---- appended at version 4, phase 05: the vocabulary ------------------
     *
     * The nine words Chapter 4 Section 3's FORTY rules are written in, from the
     * Asian Rules' own Section 1, "Terms Used in Defining Asian Rules".
     *
     * THESE RULE ON NOTHING. Not one of them returns "loses" or "draw": they
     * describe one move from one position so that phase 06 can be a table of
     * sentences over predicates rather than forty hand-rolled position tests.
     *
     * Every one takes the position BEFORE the move and the move, so the judge
     * can walk a stored log forwards and ask about either side's moves without
     * building a second code path.
     */

    int (*is_check)    (struct xq_board *b, int mv);
    int (*is_mate)     (struct xq_board *b, int mv);
    int (*is_ttc)      (struct xq_board *b, int mv);
    int (*is_chase)    (struct xq_board *b, int mv, int *victim);
    int (*is_exchange) (struct xq_board *b, int mv);
    int (*is_block)    (struct xq_board *b, int mv);
    int (*is_sacrifice)(struct xq_board *b, int mv);
    int (*is_idle)     (struct xq_board *b, int mv);

    int (*protected_at)(struct xq_board *b, int pt, int *real);
        /* "A piece is protected if there is a piece that can capture any piece
         * that takes the protected piece."
         *
         * `real` takes the source's own distinction, and the forty rules lean on
         * it repeatedly (rule 34 turns on nothing else):
         *
         *   Real protector  - when a protected piece is taken, the protector CAN
         *                     actually remove the taker
         *   False protector - it cannot
         *
         * A protector is false for reasons that do not exist in chess: the
         * recapture would leave its own general facing the enemy general down an
         * open file, or the recapturing piece is an advisor or elephant that
         * cannot reach, or a horse whose leg the taker has just occupied. So
         * `real` is computed BY PLAYING the capture and the recapture, never
         * from a static attack map. */

    int (*value_of)(int piece);
        /* In centi-soldiers. Declared here and not in the search, because
         * `is_exchange` needs it first and two tables would drift. Phase 09's
         * evaluation uses THIS ONE. */

    /* ---- appended at version 5, phase 06: the judge ------------------------ */

    int (*judge)(struct xq_board *start, const int *moves, int n,
                 struct xq_verdict *out);
        /* Rules on a SEQUENCE, which is the only thing that can be a draw in
         * this game. Returns the winner colour or 0, and fills `out`.
         *
         * `start` is the position the moves are played from and is NOT
         * modified: the judge works on a copy. */

    int (*rule_count)(void);
    const struct xq_chase_rule *(*rule_at)(int i);
        /* The chase table, enumerable so a TEST can assert that every rule
         * number is present and that each has a vector, instead of a hand-kept
         * list that rots. */

    /* ---- appended at version 6, phase 09: the search ----------------------- */

    int (*evaluate)(struct xq_board *b);
        /* The position from the SIDE TO MOVE's point of view, in
         * centi-soldiers, using `value_of`'s table so the evaluation and
         * `is_exchange` cannot drift apart. Integer throughout (D5). */

    int (*search_best)(struct xq_board *b, unsigned long long budget,
                       unsigned int seed, struct xq_search_info *info);
        /* The best move it can find inside `budget` NODES, or 0.
         *
         * BOUNDED IN WORK AND NEVER IN TIME (D6). The site plays the bot inside
         * the move transaction, so a search bounded by seconds would make the
         * length of a database transaction a property of how loaded the box is,
         * and would make a bot game unreplayable: a loaded machine would choose
         * a different move from an idle one. There is no alarm, no ualarm and
         * no signal anywhere in this engine.
         *
         * `seed` breaks ties between equal-scoring root moves. THE CALLER MUST
         * MIX THE SEAT INTO IT: without that, both bots in a bot-versus-bot
         * game are the same player, open identically every time, and a soak
         * measures nothing. Game::Goofspiel shipped exactly that. */

    /* ---- appended at version 7, phase 10: the depth-limited search --------- */

    int (*search_to_depth)(struct xq_board *b, int max_depth,
                           unsigned long long budget, unsigned int seed,
                           struct xq_search_info *info);
        /* As `search_best`, but the iterative deepening stops after `max_depth`
         * plies instead of running until the budget is spent. `search_best` is
         * this function with max_depth at its ceiling, so there is ONE search in
         * this file and not two that drift.
         *
         * WHY THIS EXISTS: UCCI's `go depth N`, and therefore the ElephantEye
         * oracle. D1 leaves no pure-Perl board and D7 refuses a shadow generator,
         * so an independent engine is one of only two oracles this dist has, and
         * comparing two engines is only meaningful AT EQUAL DEPTH. A node budget
         * cannot promise a depth: the same 40000 nodes reached depth 3 on half the
         * positions of one measured game and depth 4 on the other half.
         *
         * THE BUDGET STILL APPLIES and is not optional. `quiesce` is bounded by
         * the budget and by nothing else, so a depth-limited search with no budget
         * does not terminate on a tactical position. Pass a generous one. */
};

const struct xq_abi *xq_abi_table(void);

#endif /* XQ_ABI_H */
