#ifndef GO_ABI_H
#define GO_ABI_H

/* Public C ABI for Game::Go, the Go board, and anything that wants to keep a
 * Go position without a Perl frame in between.
 *
 * The engine is PERL-FREE. Nothing in this header or in go_engine.c needs
 * perl.h, so the same C compiles into the XS, into a plain program, or to
 * wasm. The table is resolved at RUNTIME via Game::Go::Engine::_abi_ptr, a
 * versioned function-pointer table in the shape of pb_abi.h, sc_abi.h and
 * hm_abi.h, so there is no link-time symbol coupling and each dist upgrades on
 * its own.
 *
 * The table only ever grows at the end. GO_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * NEVER ==. A sibling that used == stopped loading everywhere the moment its
 * provider appended one member.
 *
 * ---- what this header covers, and what it does not ---------------------------
 *
 * THE BOARD AND THE RULES OF PLAY. Points, colours, chains, liberties, the
 * zobrist hash and a packed position; and over those, legality, capture, the ko
 * rule and the positional superko backstop.
 *
 * `put` and `lift` remain STRUCTURE PRIMITIVES and still judge nothing: they
 * maintain the chains exactly and that is all. `legal` and `play` are the rules
 * layer over them. A caller playing Go wants `play`; a caller building a
 * position by hand wants `put`.
 *
 * It does NOT know whose turn it is, does not count passes toward the end of
 * play, does not score, and has no opinion about life and death. Turn order,
 * the two-pass stop, the confirmation phase and scoring are all above this
 * header.
 *
 * ---- units and conventions ----------------------------------------------------
 *
 * Every number crossing this boundary is an int, except the zobrist hash which
 * is an unsigned 64-bit value. THERE ARE NO FLOATS ANYWHERE IN THIS ENGINE, so
 * none of the fused-multiply-add reproducibility work a sibling needed for its
 * doubles applies here. Do not copy -ffp-contract=off into this dist's
 * Makefile.PL; there is nothing for it to protect.
 *
 * A POINT IS AN OPAQUE PADDED INDEX. The board is (size + 2) squared cells with
 * a sentinel ring of GO_BORDER all round, so the four-neighbour walk needs no
 * bounds test:
 *
 *     stride       = size + 2
 *     point(c, r)  = (r + 1) * stride + (c + 1)
 *     neighbours   = pt - 1, pt + 1, pt - stride, pt + stride
 *
 * A point is therefore NOT row * size + col, and nothing outside the engine may
 * assume it is. Use (GO->point_of) to build one and (GO->col_of)/(GO->row_of)
 * to take one apart. The sentinel ring is the only thing that makes the
 * neighbour arithmetic safe, so a caller must never synthesise an index.
 *
 * ---- names ---------------------------------------------------------------------
 *
 * No member is called open, close, read, write, free or time, which XSUB.h
 * turns into function-like macros under PERL_IMPLICIT_SYS. That is why the
 * destructor is board_drop and not board_free, and why a chain comes off with
 * `lift` rather than `remove` (which stdio.h declares). Call through the table
 * with the member in parentheses anyway: (GO->board_drop)(b).
 *
 * ---- ownership ------------------------------------------------------------------
 *
 * board_new and board_copy return a board the caller drops with board_drop.
 * A board holds no pointers, so a copy is a flat byte copy and two boards never
 * share anything. chain_at and pack write into a caller buffer; the caller sizes
 * it with GO_MAX_PTS. Nothing is retained between calls and nothing is global
 * except the zobrist table, which is derived deterministically and is therefore
 * safe to compute twice.
 */

/* 2 appended the rules layer to the table that version 1 ended at, 3 appended
 * Benson's unconditionally-alive set, 4 appended the two scorers and 5 the
 * territory map and 6 the search. Nothing that existed at an earlier version
 * has moved or changed meaning, which is the only kind of change the >= rule
 * survives. */
#define GO_ABI_VERSION 6

/* ---- colours. GO_EMPTY is 0 so a fresh board is a zeroed board ------------- */

#define GO_EMPTY  0
#define GO_BLACK  1
#define GO_WHITE  2
#define GO_BORDER 3

#define GO_OTHER(c) ((c) == GO_BLACK ? GO_WHITE : GO_BLACK)

/* ---- sizes ------------------------------------------------------------------ */

#define GO_MIN_SIZE 2
#define GO_MAX_SIZE 19
#define GO_MAX_PTS  ((GO_MAX_SIZE + 2) * (GO_MAX_SIZE + 2))   /* 441 */

/* ---- why a move was refused ------------------------------------------------
 *
 * GO_OK is 0. Every other value names one rule, and the rules layer returns
 * these rather than a boolean because the reason is what a player is shown and
 * because two of them are indistinguishable from the board alone.
 *
 * GO_ILL_KO and GO_ILL_REPEAT are BOTH repetition rules and they are separate
 * on purpose. Positional superko subsumes simple ko in the ordinary ko shape,
 * so a single code would be correct and would read wrongly: "the ko rule
 * forbids retaking that point" is a sentence a Go player expects, and "that
 * move repeats a position the game has already had" is not what happened.
 */

#define GO_OK           0
#define GO_ILL_OFF      1   /* not a point on the board                       */
#define GO_ILL_TAKEN    2   /* there is already a stone there                 */
#define GO_ILL_KO       3   /* Article 6, simple ko                           */
#define GO_ILL_SUICIDE  4   /* Article 4, and forbidden: see the note below   */
#define GO_ILL_REPEAT   5   /* positional superko, the declared amendment     */
#define GO_ILL_COLOUR   6   /* neither black nor white: programmer error      */

/* ---- suicide, and the one place this engine leaves its source --------------
 *
 * Suicide is FORBIDDEN here, per the Japanese rules of 1989 (Article 4, and the
 * British Go Association's comparison table lists Japanese and Korean as the
 * rulesets that refuse it).
 *
 * TROMP-TAYLOR PERMITS IT. Its rule 7 clears the opponent's colour and then
 * one's own, so a play that kills only your own stones is legal there and the
 * stones come straight off. A reader comparing this engine against a
 * Tromp-Taylor reference will find this difference first, so it is written at
 * the point of refusal rather than left to be discovered.
 */

/* ---- what a position is worth ----------------------------------------------
 *
 * TWO SCORERS OVER ONE FLOOD FILL, and the second one is not decoration.
 *
 * Japanese territory scoring is what this engine ships. Tromp-Taylor area
 * scoring is computed beside it, always, for two reasons: it needs nobody's
 * agreement, so it is what a disputed game falls through to; and the two must
 * agree under a published condition, which is the only differential test a
 * distribution with a single implementation of everything can have.
 *
 * EVERY SCORE IS IN TENTHS, because komi is fractional and there are no floats
 * anywhere in this engine. 6.5 komi is komi_tenths = 65.
 */

struct go_score {
    int eyes_b, eyes_w;         /* empty points reaching only one colour       */
    int territory_b, territory_w; /* the same, less any region agreed seki     */
    int dame;                   /* empty points reaching both colours, or none */
    int prisoners_b, prisoners_w; /* held, INCLUDING the dead stones removed   */
    int stones_b, stones_w;     /* on the board once the dead are off          */
    int area_b, area_w;         /* Tromp rule 9: stones plus own-reaching empty */
    int score_b, score_w;       /* TENTHS. Japanese, after Article 10.2        */
};

/* ---- what a search did ------------------------------------------------------ */

struct go_search {
    int point;          /* the chosen point, or -1 for a pass                */
    int playouts;        /* how many were actually run                        */
    int visits;          /* the chosen move's visits                          */
    int win_permille;    /* its win rate, from the searching colour's side    */
    int capped;          /* playouts that hit the move cap without settling   */
    int moves;           /* total moves played across every playout           */
};

/* ---- what a play did ------------------------------------------------------- */

struct go_played {
    int code;                   /* GO_OK, or the rule that refused it          */
    int ncaps;                  /* stones captured. 0 on a refusal             */
    int caps[GO_MAX_PTS];       /* their points, in the order they came off    */
    int ko_point;              /* the point now forbidden to the opponent, or -1 */
};

/* A board is a flat struct with no pointers, declared here rather than kept
 * opaque so that a consumer can size a copy and so that board_copy is a plain
 * assignment. Treat the members as private: they are here for sizeof, not for
 * reaching into. */

struct go_board {
    int size;
    int stride;
    int pts;                        /* stride * stride */
    int nbr[4];                     /* -1, +1, -stride, +stride */

    signed char colour[GO_MAX_PTS]; /* GO_EMPTY | GO_BLACK | GO_WHITE | GO_BORDER */

    int chain_root[GO_MAX_PTS];     /* the chain's representative point */
    int chain_next[GO_MAX_PTS];     /* the next stone in the chain, circularly */
    int chain_size[GO_MAX_PTS];     /* stones. Indexed by root only */
    int chain_libs[GO_MAX_PTS];     /* liberties, EXACT. Indexed by root only */

    int mark[GO_MAX_PTS];           /* scratch for the distinct-liberty count */
    int mark_stamp;                 /* bumped per count; reset when it wraps */

    int stones[4];                  /* stones on the board, by colour */
    unsigned long long hash;        /* zobrist over (point, colour) */

    /* appended at version 2. All three are per-POSITION state and are small,
     * which is why they live here and the superko history does not: see below. */
    int ko_point;                   /* the point a ko forbids, or -1 */
    int ko_colour;                  /* AND THE ONE COLOUR IT FORBIDS IT TO */
    int superko_on;                 /* the backstop. 1 unless turned off */
};

/* ---- the superko history, and why it is NOT in the board -------------------
 *
 * Positional superko needs every colouring the game has had. A 19x19 game of
 * three hundred moves is about 110 KB of them, which is nothing to store and
 * everything to copy: phase 08's playouts copy a board per playout, millions of
 * times per gate run, and a board carrying its own history would make each copy
 * 110 KB instead of eight.
 *
 * So the history is a SEPARATE object, passed to `legal` and `play` explicitly.
 * That keeps the board pointer-free and a copy a flat byte copy, which is the
 * invariant version 1 established and this version does not get to break.
 *
 * It also makes the playouts' rule explicit rather than inherited: a caller
 * that passes a null history gets simple ko and nothing else, which is exactly
 * what a playout wants and what every playout engine does. A rule that
 * important should be an argument, not a default.
 */

struct go_hist;                     /* opaque: it owns allocations */

struct go_abi {
    unsigned int abi_version;

    /* the board */
    struct go_board * (*board_new)(int size);
    void              (*board_drop)(struct go_board *b);
    struct go_board * (*board_copy)(const struct go_board *b);

    /* reading a position */
    int  (*at)(const struct go_board *b, int pt);
    int  (*libs)(const struct go_board *b, int pt);
    int  (*chain_at)(const struct go_board *b, int pt, int *out);
    int  (*chain_size)(const struct go_board *b, int pt);
    int  (*pack)(const struct go_board *b, unsigned char *buf);
    unsigned long long (*hash)(const struct go_board *b);
    int  (*stones)(const struct go_board *b, int colour);

    /* points */
    int  (*point_of)(const struct go_board *b, int col, int row);
    int  (*col_of)(const struct go_board *b, int pt);
    int  (*row_of)(const struct go_board *b, int pt);
    int  (*size_of)(const struct go_board *b);
    int  (*stride_of)(const struct go_board *b);

    /* structure primitives. NEITHER CHECKS ANYTHING: see the note above */
    void (*put)(struct go_board *b, int pt, int colour);
    int  (*lift)(struct go_board *b, int pt);       /* returns stones removed */

    /* the zobrist table, exposed so a test can verify it against SHA-256 */
    unsigned long long (*zobrist)(int colour, int pt);

    /* ---- appended at version 2: the rules of play -------------------------
     *
     * Everything above this line existed at version 1 and has not moved. A
     * consumer written against 1 keeps working against 2, which is the whole
     * point of the >= rule.
     */

    /* the history. board_new does not make one; a caller that wants superko
     * makes one and hands it in. hist_drop frees it. */
    struct go_hist * (*hist_new)(int size);
    void             (*hist_drop)(struct go_hist *h);
    /* A copy, because a cloned board sharing its parent's history would let
     * one line of play refuse a move in the other. */
    struct go_hist * (*hist_copy)(const struct go_hist *h);
    int              (*hist_len)(const struct go_hist *h);
    void             (*hist_clear)(struct go_hist *h);
    int              (*hist_push)(struct go_hist *h, const struct go_board *b);
    int              (*hist_has)(const struct go_hist *h, const struct go_board *b);

    /* legality, WITHOUT MUTATING THE BOARD and without allocating. `h` may be
     * null, which means simple ko only. Returns GO_OK or a GO_ILL_* code. */
    int  (*legal)(const struct go_board *b, const struct go_hist *h, int pt, int colour);

    /* every legal point for a colour, into a caller buffer. Returns the count.
     * Phase 08 calls this per move of every playout, so it allocates nothing. */
    int  (*legal_moves)(const struct go_board *b, const struct go_hist *h,
                        int colour, int *out);

    /* play it. Checks legality first and refuses without touching anything, so
     * a refused play leaves the board exactly as it was. On GO_OK it places the
     * stone, lifts the captured chains, sets the ko point and pushes the new
     * position onto `h` if one was given. */
    void (*play)(struct go_board *b, struct go_hist *h, int pt, int colour,
                 struct go_played *out);

    /* a pass. Clears the ko point, because Article 6 forbids the recapture on
     * the NEXT move only. Pushes nothing: a pass changes no colouring, and
     * pushing the unchanged one would make the next real move that returned to
     * it illegal for a reason no player could see. */
    void (*pass)(struct go_board *b, int colour);

    int  (*ko_point)(const struct go_board *b);
    /* A ko forbids its point to ONE colour, and this is which. Article 6 is
     * specific: "A player WHOSE STONE HAS BEEN CAPTURED in a ko cannot
     * recapture in that ko on the next move." The other player may play the
     * point, and on a filled board sometimes wants to. */
    int  (*ko_colour)(const struct go_board *b);
    void (*set_superko)(struct go_board *b, int on);
    int  (*superko_on)(const struct go_board *b);

    /* the hash the position WOULD have after a play, without playing it. The
     * superko filter is built on this, and it is exposed because a test that
     * cannot see the filter's input cannot tell a working filter from one that
     * always misses. */
    unsigned long long (*hash_after)(const struct go_board *b, int pt, int colour);

    /* ---- appended at version 3: life and death, as far as it is decidable --
     *
     * Benson's algorithm (D. B. Benson, "Life in the Game of Go", Information
     * Sciences 10, 1976): the chains of one colour that are UNCONDITIONALLY
     * ALIVE, meaning alive even if their owner never answers another move.
     *
     * This is the only part of life and death that is exactly computable, and
     * the whole of what this engine will ever claim to know. Everything beyond
     * it belongs to the two players, which is what Article 9.2's confirmation
     * phase is for.
     *
     * Writes the POINTS of every unconditionally alive chain of `colour` into
     * a caller buffer of GO_MAX_PTS, and returns how many. A chain is alive or
     * it is not, so every stone of an alive chain appears.
     *
     * IT RUNS ONCE PER POSITION AND NEVER INSIDE A SEARCH, so it is allowed to
     * be the slowest thing in this file, and it is. It allocates nothing but
     * uses about 12 KB of stack for its working sets.
     */
    int (*alive)(const struct go_board *b, int colour, int *out);

    /* ---- appended at version 4: the two scorers ---------------------------
     *
     * JAPANESE TERRITORY, Articles 8 and 10, in five steps:
     *
     *   1. remove every chain named in `dead`, adding each stone to the
     *      prisoners of the player who did NOT own it            (10.1)
     *   2. flood-fill the empty regions of what is left
     *   3. a region reaching exactly one colour is that colour's eye points;
     *      a region reaching both is dame                        (8)
     *   4. territory is the eye points, less any region agreed seki   (8)
     *   5. black = territory(black) - prisoners held by WHITE
     *      white = territory(white) - prisoners held by BLACK + komi  (10.2)
     *
     * STEP 5 IS SUBTRACTION FROM THE OPPONENT, NOT ADDITION TO YOURSELF.
     * Article 10.2 fills prisoners "into the opponent's territory". Adding your
     * own prisoners to your own score gives the same difference and a different
     * pair of numbers, and the pair is what a scoreboard prints and what an SGF
     * record's RE[] encodes.
     *
     * `prisoners_b` is what BLACK holds: white stones black captured in play.
     *
     * SEKI IS AGREED, NOT DETECTED, and `seki` is the list of points the
     * players agreed on. Article 8 gives a seki no territory, not even its eye
     * points, and no flood fill can see that on its own: it would have to know
     * which groups are alive-with-dame, which is life and death again. A region
     * containing any listed point scores nothing.
     */
    void (*score_jp)(const struct go_board *b,
                     const int *dead, int ndead,
                     const int *seki, int nseki,
                     int prisoners_b, int prisoners_w,
                     int komi_tenths,
                     struct go_score *out);

    /* TROMP-TAYLOR AREA, rule 9, verbatim: "A player's score is the number of
     * points of her color, plus the number of empty points that reach only her
     * color."
     *
     * No dead set, no prisoners, no komi, no agreement about anything. That is
     * the whole point of it: it is what a game whose players cannot agree is
     * scored by, and it is the second opinion the territory scorer is checked
     * against. Fills area_b and area_w and leaves the Japanese fields alone.
     */
    void (*score_area)(const struct go_board *b, struct go_score *out);

    /* ---- appended at version 5 --------------------------------------------
     *
     * WHO OWNS EACH EMPTY POINT, by the same classification score_jp uses.
     * Fills `out` with one value per padded point: GO_BLACK or GO_WHITE for a
     * point in that colour's territory, and GO_EMPTY for dame, for an agreed
     * seki, and for anything holding a stone.
     *
     * It exists because a SECOND implementation of the classification is a
     * second thing to get wrong. A caller that wants to shade the territory on
     * a board, or to write SGF's TB and TW properties, needs exactly what the
     * scorer decided and not a per-point approximation of it: territory is a
     * property of a REGION, and an empty point next to one black stone on an
     * otherwise open board belongs to nobody.
     */
    void (*territory)(const struct go_board *b,
                      const int *dead, int ndead,
                      const int *seki, int nseki,
                      signed char *out);

    /* ---- appended at version 6: the search --------------------------------
     *
     * ALPHA-BETA DOES NOT WORK ON GO and this is what does instead: Monte Carlo
     * with an upper-confidence bound over the root moves. There is no static
     * evaluation to search with (whether a stone is strong depends on whether
     * its group will live, which is the thing an evaluation was wanted for),
     * and the branching factor is 361 at the root.
     *
     * THE BUDGET IS PLAYOUTS, NEVER SECONDS. The bot runs inside a web move
     * transaction, and a loaded machine must return the same move as an idle
     * one or the replay of a bot game stops reproducing. A wall-clock budget
     * makes the output depend on the machine it ran on.
     *
     * EVERYTHING HERE IS INTEGER, including the confidence bound, for the same
     * reason: a float in the selection formula is an implementation-defined
     * rounding in the middle of a move choice.
     */

    /* xorshift32, and the whole generator is these three lines:
     *
     *     x ^= x << 13;   x ^= x >> 17;   x ^= x << 5;
     *
     * NOT a 64-bit generator and nothing with a 32x32 multiply. On a perl with
     * 32-bit integers a 64-bit product goes silently through an NV, which has a
     * 53-bit mantissa, and the low bits are lost; a generator anybody might
     * want to mirror or verify from Perl has to live in add, xor and shift.
     *
     * Exposed so a test can mirror it in Perl and digest the two streams
     * against each other. A zero state is corrected rather than accepted,
     * because zero is a fixed point of xorshift and a zero seed would make
     * every playout identical while every test still passed.
     */
    unsigned int (*prng_next)(unsigned int *state);

    /* A playout's rules are NOT the shipped game's, and both differences are
     * deliberate:
     *
     *   IT SCORES BY AREA. A playout has no players to agree dead stones with,
     *     so Japanese territory scoring is not available to it at all. Tromp's
     *     rule 9 needs nobody's consent, which is exactly why it is the
     *     playout scorer.
     *   IT ENFORCES SIMPLE KO ONLY. Maintaining a superko history inside a
     *     playout costs more than the playout does. Every playout engine makes
     *     this choice; saying so here is what stops it being a silent
     *     difference between the search and the rules.
     *
     * And it never fills its own true eye, which is what makes a playout
     * terminate at all: a uniformly random legal move fills its own eyes, kills
     * its own groups, and the position never settles.
     */
    int (*playout)(const struct go_board *b, int colour,
                   unsigned int *state, int *moves_out);

    /* `allowed` is the root moves the CALLER has already filtered, which is how
     * the C never has to see the superko history: the facade knows the history
     * and computes the legal roots, and the search takes them as given. A
     * point of -1 in the list is a pass.
     *
     * `explore` is the confidence bound's weight in permille. Ties in the
     * selection go to the LOWER POINT INDEX, so the choice is total and does
     * not depend on the order anything was stored in.
     */
    void (*search)(const struct go_board *b, int colour,
                   const int *allowed, int nallowed,
                   unsigned int seed, int playouts, int explore,
                   struct go_search *out);

    /* Which chains a run of playouts says are dead, for the confirmation
     * phase. Playouts and NOT heuristics: from the stopped position, play it
     * out N times and see whose the points end up being. That is what
     * `final_status_list dead` means in every playout engine.
     *
     * Writes the points of every chain judged dead and returns how many.
     */
    int (*dead_guess)(const struct go_board *b, unsigned int seed,
                      int playouts, int *out);
};

/* The one exported symbol. */
const struct go_abi *go_abi_table(void);

#endif /* GO_ABI_H */
