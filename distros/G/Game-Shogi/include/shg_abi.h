#ifndef SHG_ABI_H
#define SHG_ABI_H

/* Public C ABI for Game::Shogi, and anything that wants to keep a shogi
 * position without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in shg_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to wasm.
 * The table is resolved at RUNTIME via Game::Shogi::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of sth_abi.h and xq_abi.h, so
 * there is no link-time symbol coupling and each dist upgrades on its own.
 *
 * The table only ever grows at the end. SHG_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * NEVER ==.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * AT VERSION 1, THE BOARD AND NOTHING ELSE: the 81 squares and their names,
 * a step through the mailbox, the promotion zone, the fourteen kinds and what
 * each promotes to, the forty pieces of a set, the two hands, the side to
 * move, the move number, a zobrist key over the board AND BOTH HANDS, and the
 * SFEN in and out. NOTHING HERE KNOWS HOW A PIECE MOVES.
 *
 * AT VERSION 2, THE BOARD MOVES: whether a square is attacked and whether a
 * side is in check; every move of a piece already on the board, with the
 * promotion choice as two moves where it is optional and one where it is
 * forced; which of those leave the mover's own king safe; and making and
 * unmaking a move, a capture going into the mover's hand as its base kind.
 * NO DROP YET, and NOTHING HERE KNOWS HOW A GAME ENDS.
 *
 * AT VERSION 3, THE DROPS: a piece from hand onto an empty square, with W's
 * three restrictions (no piece where it could never move, no second unpromoted
 * pawn on a file, no pawn dropped to give mate); why a drop is refused; the
 * whole legal list; whether the side to move has any legal move; and perft.
 * do_move and undo_move, which refused a drop at version 2, make and take one
 * back from version 3. STILL NOTHING HERE KNOWS HOW A GAME ENDS: a side with
 * no legal move is a fact here and a result in version 4.
 *
 * AT VERSION 4, HOW A POSITION ENDS: whether the side to move is mated, has
 * no legal move without being in check, or plays on; and why a move is
 * refused, the first rule it breaks in one fixed order. REPETITION AND THE
 * IMPASSE NEED THE GAME'S HISTORY AND ARE NOT HERE.
 *
 * AT VERSION 5, WHAT NEEDS THE HISTORY: a position packed into bytes, so a
 * caller can keep the positions a game has reached; the judge that reads them
 * for a fourfold repetition and a perpetual check; and the impasse
 * declaration's count and conditions (Y lines 101-106). THE HISTORY IS THE
 * CALLER'S: a board still keeps none.
 *
 * AT VERSION 6, THE SEARCH: an evaluation from the side to move's view, and
 * an alpha-beta search bounded in NODES and never in seconds, so a loaded
 * machine plays the same move as an idle one and a bot game replays. The caller
 * hands it the keys of the positions the game has stood in, and a position
 * reached again, from those or along the search's own path, scores as a draw.
 *
 * `put`, `lift` and `set_hand` are STRUCTURE PRIMITIVES and JUDGE NOTHING. A
 * caller may put two black kings on the board or nine pawns on one file.
 * `do_move` checks the move's SHAPE (a piece of the side to move, not onto its
 * own piece, a promotion only of a kind that promotes; a drop of a kind in
 * hand onto an empty square) and never its geometry, the drop restrictions or
 * the king's safety: that is what the move lists are for.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the zobrist key which
 * is an unsigned 64-bit value. THERE ARE NO FLOATS ANYWHERE IN THIS ENGINE.
 *
 * A SQUARE IS 0 TO 80, IN SFEN ORDER: rank a first, and in each rank file 9
 * first, so square 0 is 9a, square 8 is 1a and square 80 is 1i. That numbering
 * is the only one that leaves the engine. Inside, a square lives in an 11 by 13
 * mailbox, a margin of one file each side and two ranks above and below, so a
 * read two ranks out (a knight, from version 2) never wraps.
 *
 * A FILE IS 1 TO 9 AND A RANK IS 1 TO 9, rank 1 being rank a, White's back
 * rank. File 1 is on Black's right. step() takes deltas in the same terms: a
 * drank of -1 is towards rank a, which is forward for Black.
 *
 * A SIDE IS 0 FOR BLACK (sente, uppercase in SFEN, moves first in an even
 * game) AND 1 FOR WHITE.
 *
 * A KIND IS 1 TO 14: the eight base kinds and the six promoted ones. A SQUARE
 * HOLDS 0 FOR EMPTY OR A PIECE, (side << 4) | kind. SHG_OFF is what at()
 * answers for a number that is not a square, and is never a piece.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h
 * turns into function-like macros under PERL_IMPLICIT_SYS. That is why the
 * destructor is board_drop. Call through the table with the member in
 * parentheses anyway: (SHG->board_drop)(b).
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new, board_empty, board_of_sfen and board_copy return a board the
 * caller drops with board_drop. A board holds no pointers, so a copy is a flat
 * byte copy and two boards never share anything. to_sfen writes into a caller
 * buffer sized at least SHG_SFEN_MAX. Nothing is retained between calls and
 * nothing is global except the geometry tables and the zobrist table, which
 * are derived deterministically on first use, and the count of live boards,
 * which exists for a leak test and is not synchronised.
 */

/* Version 1 is the board. Version 2 appends attack, check, the board moves,
 * and making and unmaking a move. Version 3 appends the drops, the legal list
 * and perft, and lets do_move and undo_move take a drop, which version 2 said
 * they would. Version 4 appends status and move_fault. Nothing that exists at
 * a version moves or changes meaning at a later one. Version 5 appends pack,
 * the impasse count and declaration, and the repetition judge. Version 6
 * appends evaluate and search. */
#define SHG_ABI_VERSION 6

/* ---- the board ---------------------------------------------------------------- */

#define SHG_SQUARES 81
#define SHG_FILES   9
#define SHG_RANKS   9
#define SHG_ZONE_RANKS 3

/* ---- sides ---------------------------------------------------------------------- */

#define SHG_BLACK 0
#define SHG_WHITE 1
#define SHG_SIDES 2

/* ---- kinds -----------------------------------------------------------------------
 *
 * The base kinds are numbered in SFEN's own letter order, PLNSGBRK. A promoted
 * kind is its base kind plus eight, except the bishop and the rook, which
 * promote to 13 and 14. The gold and the king never promote.
 */

#define SHG_PAWN           1
#define SHG_LANCE          2
#define SHG_KNIGHT         3
#define SHG_SILVER         4
#define SHG_GOLD           5
#define SHG_BISHOP         6
#define SHG_ROOK           7
#define SHG_KING           8
#define SHG_TOKIN          9
#define SHG_PRO_LANCE     10
#define SHG_PRO_KNIGHT    11
#define SHG_PRO_SILVER    12
#define SHG_HORSE         13
#define SHG_DRAGON        14
#define SHG_KINDS         15   /* one past the last kind: an array bound */

/* A hand holds the seven base kinds a capture can give, pawn to rook. */
#define SHG_HAND_KINDS     8   /* one past the rook: an array bound      */

/* ---- what a square holds -------------------------------------------------------- */

#define SHG_EMPTY 0
#define SHG_OFF   64

#define SHG_PIECE(side, kind) (((side) << 4) | (kind))
#define SHG_SIDE_OF(piece)    (((piece) >> 4) & 1)
#define SHG_KIND_OF(piece)    ((piece) & 15)

/* ---- the set -------------------------------------------------------------------
 *
 * How many of each base kind a whole set has, both sides together. A hand can
 * never hold more of a kind than this, and an SFEN with more of a kind on the
 * board and in the hands together is refused (SHG_POS_COUNT). Forty in all.
 */

#define SHG_SET_PAWNS   18
#define SHG_SET_PIECES  40

/* The longest SFEN this writer emits is under 230 characters: nine ranks of
 * nine promoted pieces, both hands of every kind, and a six-digit move number.
 * Sized for a caller's stack buffer, and a string this long or longer is
 * refused unread. */
#define SHG_SFEN_MAX 256

/* The largest move number an SFEN may carry: six digits. */
#define SHG_MOVE_MAX 999999

/* ---- why an SFEN was refused ------------------------------------------------------
 *
 * SHG_OK is 0. Every other value names one fault. An SFEN is refused for its
 * SHAPE and never for its sense: two pawns on a file, or a pawn on the last
 * rank, load, because those are positions a test needs to build. The two
 * exceptions are counts the set itself fixes: two kings of one side, and more
 * of a kind than a set has.
 *
 * THEY ARE ASKED IN THIS ORDER, because one string can have several faults.
 */

#define SHG_OK            0
#define SHG_POS_NULL      1   /* no string at all, or an empty one                */
#define SHG_POS_LONG      2   /* SHG_SFEN_MAX characters or more                  */
#define SHG_POS_FIELDS    3   /* not three or four fields, single spaces between  */
#define SHG_POS_RANKS     4   /* the board is not nine ranks                      */
#define SHG_POS_LETTER    5   /* a character that is not a piece letter, a run    *
                               * 1 to 9, '+' or '/'; or two runs side by side     */
#define SHG_POS_WIDTH     6   /* a rank that is not nine squares                  */
#define SHG_POS_PROMOTE   7   /* '+' not before a pawn, lance, knight, silver,    *
                               * bishop or rook                                   */
#define SHG_POS_SIDE      8   /* the side to move is not b or w                   */
#define SHG_POS_HAND      9   /* the hands are not '-' or counted base kinds: a   *
                               * king or a '+', a count of 0 or 1 written, a kind *
                               * twice for one side, or more than the set has     */
#define SHG_POS_MOVE     10   /* the move number is not 1 to SHG_MOVE_MAX         */
#define SHG_POS_KINGS    11   /* one side has two kings                           */
#define SHG_POS_COUNT    12   /* more of a kind on the board and in the hands     *
                               * together than a set has                          */

/* ---- a move, versions 2 and 3 ------------------------------------------------------
 *
 * One int: the from square in bits 0-6, the to square in bits 7-13, and bit
 * 14 set for a promotion. Bit 15 and bits 16-19 are kept for a drop and its
 * kind, which arrive at version 3; no version 2 call makes or takes one.
 *
 * A DROP, from version 3: bit 15 set, the base kind (pawn to rook) in bits
 * 16-19, the square in bits 7-13, and bits 0-6 and 14 clear.
 */

#define SHG_MOVE(from, to, promote) ((from) | ((to) << 7) | ((promote) ? 1 << 14 : 0))
#define SHG_MOVE_FROM(m)    ((m) & 127)
#define SHG_MOVE_TO(m)      (((m) >> 7) & 127)
#define SHG_MOVE_PROMOTE(m) (((m) >> 14) & 1)
#define SHG_MOVE_DROP(m)    (((m) >> 15) & 1)

#define SHG_DROP(kind, to)  ((1 << 15) | ((kind) << 16) | ((to) << 7))
#define SHG_MOVE_KIND(m)    (((m) >> 16) & 15)

/* ---- why a drop is refused, version 3 ------------------------------------------
 *
 * SHG_DROP_OK is 0. ASKED IN THIS ORDER, so a drop with two faults gives the
 * first: W lines 505-507 for the three restrictions, then the king.
 */

#define SHG_DROP_OK         0
#define SHG_DROP_BAD        1   /* not a square, or not a kind a hand holds      */
#define SHG_DROP_NOT_HELD   2   /* the side to move has none of that kind        */
#define SHG_DROP_OCCUPIED   3   /* the square is not empty                       */
#define SHG_DROP_DEAD       4   /* a pawn or lance on the last rank, a knight on *
                                 * either of the last two: it could never move   */
#define SHG_DROP_TWO_PAWNS  5   /* a pawn onto a file with an unpromoted pawn of *
                                 * the same side (nifu)                          */
#define SHG_DROP_IN_CHECK   6   /* the drop leaves the side's own king attacked  */
#define SHG_DROP_PAWN_MATE  7   /* a pawn dropped to give mate (uchifuzume)      */

/* ---- perft, version 3 -------------------------------------------------------------
 *
 * What perft counts at its last ply, in the order D's table gives them: every
 * legal move, and of those the captures, the drops, the promotions, the moves
 * that give check, and the moves that give mate.
 */

#define SHG_PERFT_NODES      0
#define SHG_PERFT_CAPTURES   1
#define SHG_PERFT_DROPS      2
#define SHG_PERFT_PROMOTIONS 3
#define SHG_PERFT_CHECKS     4
#define SHG_PERFT_MATES      5
#define SHG_PERFT_COUNTS     6

/* ---- how a position stands, version 4 ------------------------------------------
 *
 * W line 560: mate is check with no move that answers it. A side with no legal
 * move that is NOT in check has lost too: every move left would be one of W's
 * infractions (lines 591-600). The two are told apart so a log can say which.
 */

#define SHG_ONGOING  0
#define SHG_MATE     1
#define SHG_NO_MOVE  2

/* ---- why a move is refused, version 4 --------------------------------------------
 *
 * SHG_FAULT_OK is 0. ASKED IN THIS ORDER, so a move with two faults gives the
 * first. A board move is asked whose piece it is, whether the piece reaches,
 * whether the promotion is right, then the king. A drop is asked whether it is
 * held, whether the square is empty, then W's restrictions in drop_fault's
 * order, with the king between the second and the third.
 */

#define SHG_FAULT_OK                  0
#define SHG_FAULT_BAD                 1   /* not a move at all                    */
#define SHG_FAULT_NOT_YOURS           2   /* no piece of the side to move there  */
#define SHG_FAULT_NOT_HELD            3   /* a drop of a kind not in hand          */
#define SHG_FAULT_CANNOT_REACH        4   /* the piece does not move that way, or *
                                           * its own piece stands there           */
#define SHG_FAULT_OCCUPIED            5   /* a drop onto a piece                   */
#define SHG_FAULT_PROMOTE_NOT_ALLOWED 6   /* a + where the piece may not promote   */
#define SHG_FAULT_PROMOTE_REQUIRED    7   /* no + where it must                    */
#define SHG_FAULT_DEAD                8   /* a drop where it could never move      */
#define SHG_FAULT_TWO_PAWNS           9   /* nifu                                  */
#define SHG_FAULT_IN_CHECK           10   /* it leaves its own king attacked      */
#define SHG_FAULT_PAWN_MATE          11   /* uchifuzume                            */

/* ---- a packed position, version 5 ------------------------------------------------
 *
 * The 81 squares in square order, then Black's hand and White's, pawn to rook,
 * then the side to move. Two positions with the same bytes are the same
 * position as W line 613 counts one: the same pieces, the same hands, the same
 * side to move. The move number is not in it.
 */

#define SHG_PACKED (SHG_SQUARES + 2 * (SHG_HAND_KINDS - 1) + 1)

/* ---- the repetition judge, version 5 ------------------------------------------------
 *
 * W line 613: the fourth time a position stands is the end. A draw, unless one
 * side gave check with every move it made since the first time; that side
 * loses. When both sides did, this judge calls it a draw.
 */

#define SHG_REP_NONE       0
#define SHG_REP_DRAW       1
#define SHG_REP_PERPETUAL  2
#define SHG_REP_TIMES      4

/* ---- the impasse declaration, version 5 ----------------------------------------------
 *
 * Y lines 101-106, with the 27-point thresholds of Y line 125 and W line 694:
 * the declarer's king is in the enemy camp, at least ten of its other pieces
 * are there, its king is not in check, and its points are at least 28 for
 * Black or 27 for White, counting only its pieces in the camp, not the king,
 * and its hand: a rook or bishop, promoted or not, 5, any other piece 1.
 * ASKED IN THIS ORDER.
 */

#define SHG_DECLARE_OK          0
#define SHG_DECLARE_NO_KING     1   /* its king is not in the enemy camp, or it has none */
#define SHG_DECLARE_FEW_PIECES  2   /* fewer than ten other pieces there               */
#define SHG_DECLARE_IN_CHECK    3
#define SHG_DECLARE_FEW_POINTS  4

#define SHG_DECLARE_PIECES       10
#define SHG_DECLARE_POINTS_BLACK 28
#define SHG_DECLARE_POINTS_WHITE 27

/* ---- the search, version 6 --------------------------------------------------------
 *
 * Scores are centipawns from the side to move's view. A mate is SHG_MATE_SCORE less
 * the plies to it, so a nearer mate scores higher; anything beyond
 * SHG_MATE_BOUND is a mate.
 *
 * THE FLAGS turn parts off, for measuring what each is worth (phase 08's F
 * and G). A game passes 0.
 */

#define SHG_MATE_SCORE 30000
#define SHG_MATE_BOUND 29000

#define SHG_EVAL_NO_HAND_BONUS  1   /* a piece in hand worth what it is on the board */
#define SHG_EVAL_NO_KING_SAFETY 2
#define SHG_EVAL_NO_ENTERING    4   /* no bonus for a king entering the enemy camp   */
#define SHG_SEARCH_NO_MATE      8   /* no check-only mate search at the horizon      */

struct shg_search_info {
    unsigned long long nodes;   /* nodes searched                              */
    int depth;                  /* the deepest iteration completed            */
    int score;                  /* its score for the move chosen               */
    int stopped;                /* 1 when the budget ended the search          */
};

/* THE BUFFER A CALLER MUST SUPPLY for a list of moves, and why it is enough.
 *
 * The most board moves one side can have, counting a move with a promotion
 * choice twice: two rooks or bishops, unpromoted, reach at most 16 squares
 * each from the centre and may promote on all of them (4 * 32 = 128); four
 * lances, 8 squares each, twice (64); four knights, 2 squares, twice (16);
 * four silvers, 5 squares, twice (40); four golds, 6 (24); eighteen pawns, 1
 * square, twice (36); the king, 8. A promoted piece reaches no more than its
 * unpromoted kind's count above (a horse or a dragon 20, never twice). That is
 * 316. Drops, from version 3, put at most seven kinds on at most 81 squares,
 * 567. The two together are under 1024. A board built with `put` can hold
 * more than a set, so every call writes at most `max` and returns how many
 * there are, and a short buffer is detectable.
 */

#define SHG_MOVES_MAX 1024

/* What do_move hands back so undo_move can take the move back. The caller
 * owns it; undo_move checks it against the board and refuses one that does
 * not fit. */
struct shg_undo {
    int move;
    int moved;          /* the piece that moved, before any promotion */
    int captured;       /* the piece on the to square, or SHG_EMPTY    */
    int move_number;    /* the board's move number before the move     */
};

/* ---- the table ------------------------------------------------------------------ */

struct shg_board;

struct shg_abi {
    int abi_version;

    /* ---- version 1: the board -------------------------------------------------- */

    /* The start of an even game, Black to move, move 1. */
    struct shg_board * (*board_new)(void);

    /* Every square empty and both hands empty, Black to move, move 1. */
    struct shg_board * (*board_empty)(void);

    /* NULL when the SFEN is refused, and *err set to the SHG_POS_ code. */
    struct shg_board * (*board_of_sfen)(const char *sfen, int *err);

    struct shg_board * (*board_copy)(const struct shg_board *b);
    void               (*board_drop)(struct shg_board *b);
    int                (*live)(void);                       /* boards not yet dropped */

    /* What a square holds: SHG_EMPTY or a piece; SHG_OFF for a number that is
     * not a square. */
    int  (*at)(const struct shg_board *b, int sq);

    /* Structure primitives. put places a piece, replacing what was there; lift
     * empties the square. Both keep the key and the king squares, and both do
     * nothing to a number that is not a square or a value that is not a piece. */
    void (*put)(struct shg_board *b, int sq, int piece);
    void (*lift)(struct shg_board *b, int sq);

    /* How many of a base kind, pawn to rook, a side holds; 0 for anything else.
     * set_hand keeps the key and does nothing for a count outside 0 to the
     * set's count of that kind. */
    int  (*hand)(const struct shg_board *b, int side, int kind);
    void (*set_hand)(struct shg_board *b, int side, int kind, int count);

    int  (*to_move)(const struct shg_board *b);
    void (*set_to_move)(struct shg_board *b, int side);
    int  (*move_number)(const struct shg_board *b);
    void (*set_move_number)(struct shg_board *b, int n);   /* 1 to SHG_MOVE_MAX */

    /* The square of a side's king, or -1 when it has none. Where put has given
     * a side two, it is the one put last, until that one is lifted. */
    int  (*king_sq)(const struct shg_board *b, int side);

    /* The key covers every piece, both hands and the side to move. It does
     * NOT cover the move number: two boards that differ only in it are the
     * same position. */
    unsigned long long (*key)(const struct shg_board *b);
    unsigned long long (*zobrist)(int side, int kind, int sq);
    unsigned long long (*zobrist_hand)(int side, int kind, int count);
    unsigned long long (*zobrist_move)(void);              /* White to move */

    /* Writes the SFEN and its length, with no NUL counted, or -1 when `max`
     * is too small. Always four fields, the hands in RBGSNLP order with
     * Black's first. */
    int  (*to_sfen)(const struct shg_board *b, char *out, int max);

    /* ---- geometry, the same for every board ------------------------------------ */

    /* 1 when the tables were built and every count in this header agreed with
     * them. When it is 0, no board is built. */
    int  (*tables_ok)(void);

    /* The square at (file, rank), or -1. */
    int  (*sq_of)(int file, int rank);
    int  (*file_of)(int sq);                    /* 1 to 9, or 0 */
    int  (*rank_of)(int sq);                    /* 1 to 9, or 0 */

    /* The square (dfile, drank) away from `sq`, read through the mailbox, or
     * -1 when it is off the board. dfile is -1 to 1 and drank -2 to 2: the
     * reach of every piece's single step and the knight's jump. Anything wider
     * is -1. */
    int  (*step)(int sq, int dfile, int drank);

    /* 1 when `sq` is in the three ranks furthest from `side`. */
    int  (*in_zone)(int side, int sq);

    /* How many ranks lie beyond `sq` as `side` faces: 0 on the furthest rank,
     * 8 on its own back rank; -1 for a bad side or square. */
    int  (*last_distance)(int side, int sq);

    /* What a kind promotes to, or 0 when it does not. */
    int  (*promoted)(int kind);

    /* The base kind of a kind; a base kind is its own. 0 for anything else. */
    int  (*unpromoted)(int kind);

    /* How many of a base kind a set has, both sides together; 0 otherwise. */
    int  (*set_count)(int kind);

    /* ---- version 2: the board moves -------------------------------------------- */

    /* 1 when a piece of side `by` on the board could move onto `sq` now,
     * whatever stands there, and whatever that would do to its own king. */
    int  (*attacked)(const struct shg_board *b, int sq, int by);

    /* 1 when `side`'s king is attacked; 0 when it is not or it has none. */
    int  (*in_check)(const struct shg_board *b, int side);

    /* Every move of the side to move's pieces on the board, square by square
     * in square order and each piece's moves in a fixed order, a promotion
     * before its plain twin. Pseudo-legal: the king's safety is not asked. */
    int  (*pseudo_moves)(const struct shg_board *b, int *out, int max);

    /* The same list less every move that leaves the mover's own king
     * attacked. A side with no king has every pseudo-legal move. */
    int  (*board_moves)(const struct shg_board *b, int *out, int max);

    /* Makes a board move: the piece lifted, anything on `to` taken into the
     * mover's hand as its base kind, the piece put down promoted if asked,
     * the side to move turned over and the move number counted on. Returns 1
     * and fills *undo; or 0 and changes nothing when the move's shape is
     * wrong (see the top of this file) or the hand of that kind is full.
     * From version 3 it makes a drop too: one of the kind out of the hand and
     * onto the empty square, unpromoted. */
    int  (*do_move)(struct shg_board *b, int move, struct shg_undo *undo);

    /* Takes back the move `undo` records. Returns 1, or 0 and changes nothing
     * when the board does not show that move just made. */
    int  (*undo_move)(struct shg_board *b, const struct shg_undo *undo);

    /* ---- version 3: the drops ------------------------------------------------ */

    /* The legal drops of the side to move: for each kind in hand in the order
     * rook, bishop, gold, silver, knight, lance, pawn, each square it may go
     * on in square order. */
    int  (*drops)(const struct shg_board *b, int *out, int max);

    /* Every legal move of the side to move: board_moves, then drops. */
    int  (*legal)(const struct shg_board *b, int *out, int max);

    /* 1 when the side to move has a legal move; it stops at the first. */
    int  (*has_legal_move)(const struct shg_board *b);

    /* Why the side to move may not drop `kind` on `sq`: an SHG_DROP_ code. */
    int  (*drop_fault)(const struct shg_board *b, int kind, int sq);

    /* The perft of `depth` plies from the board, which it leaves as it was:
     * counts[SHG_PERFT_NODES] and the rest as above, when `counts` is not
     * NULL. Returns the nodes. Depth 0 is the board itself, one node. A
     * negative depth, or a board that is NULL, counts nothing. */
    unsigned long long (*perft)(const struct shg_board *b, int depth,
                                unsigned long long *counts);

    /* ---- version 4: how a position ends ---------------------------------------- */

    /* SHG_ONGOING, SHG_MATE or SHG_NO_MOVE, for the side to move. -1 for a
     * NULL board. */
    int  (*status)(const struct shg_board *b);

    /* Why the side to move may not make `move`: an SHG_FAULT_ code, and
     * SHG_FAULT_OK exactly for the moves `legal` lists. */
    int  (*move_fault)(const struct shg_board *b, int move);

    /* ---- version 5: what needs the history ------------------------------------ */

    /* Writes SHG_PACKED bytes and returns SHG_PACKED, or -1. */
    int  (*pack)(const struct shg_board *b, unsigned char *out);

    /* What `side` has in the enemy camp, not the king, and in hand: its points
     * as the declaration counts them, and its pieces in the camp. */
    int  (*impasse_points)(const struct shg_board *b, int side);
    int  (*impasse_pieces)(const struct shg_board *b, int side);

    /* Why the side to move may not declare: an SHG_DECLARE_ code. */
    int  (*declare_fault)(const struct shg_board *b);

    /* Reads `n` positions in the order a game reached them, as their keys,
     * their packed bytes (n * SHG_PACKED) and whether the move into each
     * gave check (the first's is not read), and judges the LAST. A position
     * counts as the last only when its key AND its bytes match, so a key
     * collision is not a repetition. Returns SHG_REP_NONE, SHG_REP_DRAW, or
     * SHG_REP_PERPETUAL with *loser set to the side that kept checking. */
    int  (*repetition)(const unsigned long long *keys, const unsigned char *packed,
                       const unsigned char *gave_check, int n, int *loser);

    /* ---- version 6: the search -------------------------------------------------- */

    /* The position's worth to the side to move, in centipawns. */
    int  (*evaluate)(const struct shg_board *b, int flags);

    /* The move to play: a search of at most `budget` nodes and `max_depth`
     * plies (0 for no ceiling), its ties broken by `seed`. `history` holds the
     * keys of the `n_history` positions the game stood in before this one (NULL
     * and 0 for none); a position the search reaches again, from them or along
     * its own path, scores as a draw. 0 when the side to move has no legal move.
     * Leaves the board as it was; fills *info when it is not NULL. */
    int  (*search)(const struct shg_board *b, unsigned long long budget, int max_depth,
                   unsigned int seed, int flags, const unsigned long long *history,
                   int n_history, struct shg_search_info *info);
};

const struct shg_abi *shg_abi_table(void);

#endif
