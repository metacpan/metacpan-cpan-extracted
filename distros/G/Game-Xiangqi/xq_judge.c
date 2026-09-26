/* xq_judge.c - the vocabulary of the Asian Rules. Phase 05 of plan_xiangqi.
 *
 * PERL-FREE, as the rest of the engine is.
 *
 * THIS FILE RULES ON NOTHING. Not one function here returns "loses" or "draw".
 * It writes the nine words that Chapter 4 Section 3's FORTY rules are written
 * in, taken from the Asian Rules' own Section 1, "Terms Used in Defining Asian
 * Rules" (clubxiangqi.com/rules/asiarule.htm, curl'd 25 Sep 2026), so that phase
 * 06 can be a table of sentences over predicates rather than forty hand-rolled
 * position tests.
 *
 * Seven of the nine are one-line compositions of phases 03 and 04. The value of
 * writing them separately is that phase 06's forty rules then READ AS THE SOURCE
 * READS, which is the only way forty rules get reviewed by a person.
 *
 * Every predicate takes the position BEFORE the move and the move, so the judge
 * can walk a stored log forwards and ask about either side's moves without
 * building a second code path.
 */

#include <string.h>
#include "xq_abi.h"

static const struct xq_abi *E(void) { return xq_abi_table(); }

#define AT(b, pt) ((E())->at((b), (pt)))

/* ---- what a piece is worth ----------------------------------------------------
 *
 * In centi-soldiers. Here and not in the search because `is_exchange` needs it
 * first, and two tables would drift. Phase 09's evaluation uses this one.
 *
 * The general is 0 rather than huge: it is never exchanged, it cannot be
 * captured in a legal game, and a huge number here would make every comparison
 * involving it meaningless rather than absurd.
 */
static int xq_value_of(int piece)
{
    switch (XQ_KIND(piece)) {
        case XQ_CHARIOT:  return 900;
        case XQ_CANNON:   return 450;
        case XQ_HORSE:    return 400;
        case XQ_ADVISOR:  return 200;
        case XQ_ELEPHANT: return 200;
        case XQ_SOLDIER:  return 100;
        default:          return 0;
    }
}

/* ---- the three that are phases 03 and 04 wearing the source's words ----------- */

/* "A move of any piece that causes the opponent's King to be threatened with
 * capture in the next move." */
static int xq_is_check(struct xq_board *b, int mv)
{
    struct xq_undo u;
    int them = XQ_OTHER((E())->side(b));
    int r;
    (E())->do_move(b, mv, &u);
    r = (E())->in_check(b, them);
    (E())->undo_move(b, &u);
    return r;
}

/* "Check in such a way that the opponent's King cannot resolve the check." */
static int xq_is_mate(struct xq_board *b, int mv)
{
    struct xq_undo u;
    int reason = XQ_ONGOING;
    (E())->do_move(b, mv, &u);
    (E())->outcome(b, &reason);
    (E())->undo_move(b, &u);
    return reason == XQ_BY_CHECKMATE;
}

/* "Threatening to Checkmate (TTC) - A piece moves into a position where it can
 * launch a sequence of attack that leads to checkmate."
 *
 * THE INTERPRETATION, AND IT IS OURS. The source bounds nothing: "a sequence"
 * read literally makes almost every move a TTC and the forty rules unusable.
 * What a referee means at a board is that the opponent must answer NOW or be
 * mated, so this is implemented as
 *
 *     play the move, hand the turn straight back, and ask for a mate in one
 *
 * which is "after this move I threaten mate next move". The null move is what
 * makes it a THREAT rather than a forced mate: a forced mate is what `mate_in`
 * answers and it is a different question.
 *
 * THE PLAN SAID 3 PLIES AND THAT WAS WRONG, not by a little. After the move it
 * is the OPPONENT's turn, so any depth has to be measured after a null move,
 * and `mate_in(3)` after a null move means "I could mate in two if you never
 * moved again", which is true of a large fraction of middlegame positions. The
 * deviation is recorded in the phase file. If the judge later disagrees with a
 * cited diagram because of this, the number moves and the file records it.
 */
static int xq_is_ttc(struct xq_board *b, int mv)
{
    struct xq_undo u;
    int me = (E())->side(b);
    int r;

    (E())->do_move(b, mv, &u);
    (E())->set_side(b, me);              /* the null move */
    r = (E())->mate_in(b, 1);
    (E())->undo_move(b, &u);             /* restores the side and the key exactly */
    return r;
}

/* ---- chase ---------------------------------------------------------------------
 *
 * "Chase - A piece moves to a position where it can capture an opponent's piece,
 * which is not the King, in the next move."
 *
 * IMPLEMENTED AS A NEW ATTACK BY THE SIDE, not by the moved piece alone, and
 * that is deliberate. The source's sentence describes the ordinary case, and
 * Section 3 rules 25 and 26 are explicit that a chase happens when only the
 * cannon's SCREEN moves and neither the cannon nor its target does. A
 * moved-piece reading gets both of those rules wrong, and they are two of the
 * forty.
 *
 * So: an enemy piece that is not a general and that the mover's side did NOT
 * attack before and DOES attack after.
 */
static int xq_is_chase(struct xq_board *b, int mv, int *victim)
{
    struct xq_undo u;
    int me = (E())->side(b);
    int them = XQ_OTHER(me);
    unsigned char before[XQ_CELLS];
    int pt, found = 0;

    if (victim) *victim = 0;

    for (pt = 0; pt < XQ_CELLS; pt++) {
        int p = AT(b, pt);
        before[pt] = (unsigned char)
            ((E())->on_board(pt) && XQ_COLOUR(p) == them && XQ_KIND(p) != XQ_GENERAL
             && (E())->attacked(b, pt, me));
    }

    (E())->do_move(b, mv, &u);
    for (pt = 0; pt < XQ_CELLS && !found; pt++) {
        int p = AT(b, pt);
        if (!(E())->on_board(pt)) continue;
        if (XQ_COLOUR(p) != them || XQ_KIND(p) == XQ_GENERAL) continue;
        if (before[pt]) continue;                      /* already attacked */
        if (!(E())->attacked(b, pt, me)) continue;
        found = 1;
        if (victim) *victim = pt;
    }
    (E())->undo_move(b, &u);
    return found;
}

/* ---- exchange -------------------------------------------------------------------
 *
 * "Exchange - Using piece A to capture the opponent's piece B and let the
 * opponent take piece A. ... Usually it is an exchange only when the value of A
 * and B are similar."
 *
 * THAT "USUALLY" IS THE ONE SOFT EDGE IN THE WHOLE VOCABULARY and this pins it:
 * SIMILAR MEANS WITHIN ONE SOLDIER on `value_of`'s table, which is 100
 * centi-soldiers. That number is ours, not the source's, and it is written here
 * rather than in a comment somewhere else so the next reader finds it where the
 * decision is made.
 */
static int xq_is_exchange(struct xq_board *b, int mv)
{
    struct xq_undo u;
    int to = (E())->move_to(mv);
    int from = (E())->move_from(mv);
    int mover = AT(b, from);
    int taken = AT(b, to);
    int them = XQ_OTHER((E())->side(b));
    int recapturable;

    if (taken == XQ_EMPTY) return 0;                       /* not a capture at all */
    if (xq_value_of(mover) - xq_value_of(taken) >  100) return 0;
    if (xq_value_of(taken) - xq_value_of(mover) >  100) return 0;

    (E())->do_move(b, mv, &u);
    recapturable = (E())->attacked(b, to, them);
    (E())->undo_move(b, &u);
    return recapturable;
}

/* ---- block ----------------------------------------------------------------------
 *
 * "Block - A piece moves to a position where it prevents the opponent from
 * moving one of its pieces in certain direction."
 *
 * Cheap here and nowhere else, because phase 03 already named the blocking
 * points: the horse's leg, the elephant's eye, and a ray for the chariot and the
 * cannon. This counts the opponent's PSEUDO-LEGAL destinations before and after
 * and asks whether the square the mover landed on is what removed one.
 *
 * Pseudo-legal and not legal, deliberately: a move that puts the opponent in
 * check removes most of their legal moves without blocking anything, and that is
 * a check, which is a different word in this vocabulary.
 */
/* Counted PER ORIGIN and not per destination, which the first version got
 * wrong. A capture removes the taken piece, so every destination that piece had
 * disappears, and a destination-total comparison reports a plain capture as a
 * block: the cannon taking a horse in the opening read as one. Per origin, and
 * skipping the square the capture emptied, a block is what it says it is. */
static void dests_by_origin(struct xq_board *b, int side, int *out)
{
    int buf[XQ_MAX_MOVES];
    int keep = (E())->side(b);
    int n, i;
    (E())->set_side(b, side);
    n = (E())->gen_moves(b, buf);
    (E())->set_side(b, keep);
    memset(out, 0, sizeof(int) * XQ_CELLS);
    for (i = 0; i < n; i++) out[(E())->move_from(buf[i])]++;
}

/* A BLOCK IS CAUSED BY OCCUPYING THE DESTINATION, and that has to be isolated
 * from everything else the move does, which took two goes to get right.
 *
 * Comparing before against after catches two things that are not blocks:
 *   - a CAPTURE removes the taken piece, so all of its moves vanish
 *   - VACATING the origin removes a capture target, or removes a cannon's
 *     screen, so the enemy loses destinations because the mover RAN AWAY
 * The second is the subtle one: a red horse stepping off b0 was reported as
 * blocking, because the black cannon on b7 could no longer jump the cannon on
 * b2 to take it.
 *
 * So the baseline is the position with the origin ALREADY EMPTY and the
 * destination untouched, and the comparison is against the same position with
 * the mover placed. The only difference between those two boards is the
 * occupancy of one square, which is what the word means.
 */
static int xq_is_block(struct xq_board *b, int mv)
{
    int from = (E())->move_from(mv);
    int to   = (E())->move_to(mv);
    int mover = AT(b, from);
    int taken = AT(b, to);
    int them = XQ_OTHER((E())->side(b));
    int was[XQ_CELLS], now[XQ_CELLS];
    int pt, lost = 0;

    (E())->lift(b, from);
    dests_by_origin(b, them, was);
    (E())->put(b, to, mover);
    dests_by_origin(b, them, now);
    (E())->put(b, to, taken);            /* XQ_EMPTY when it was not a capture */
    (E())->put(b, from, mover);          /* and the key comes back with it */

    for (pt = 0; pt < XQ_CELLS; pt++) {
        if (pt == to) continue;          /* the piece that stood here was taken */
        if (now[pt] < was[pt]) { lost = 1; break; }
    }
    return lost;
}

/* "Sacrifice - A piece moves to a position where it can be taken by the
 * opponent." Literally that, and the overlap with `is_exchange` is the source's
 * and not ours: the two are separate words and a move can be both. */
static int xq_is_sacrifice(struct xq_board *b, int mv)
{
    struct xq_undo u;
    int to = (E())->move_to(mv);
    int them = XQ_OTHER((E())->side(b));
    int r;
    (E())->do_move(b, mv, &u);
    r = (E())->attacked(b, to, them);
    (E())->undo_move(b, &u);
    return r;
}

/* "Idle - A move that does not Check, TTC, Chase, Exchange, Block, or
 * Sacrifice."
 *
 * WRITTEN AS EXACTLY THAT NEGATION and never as a list of its own. Two
 * definitions of the same word drift, and the drift is invisible: a seventh
 * predicate added to the vocabulary is automatically excluded from idle here,
 * and would have to be remembered in a hand-rolled version.
 */
static int xq_is_idle(struct xq_board *b, int mv)
{
    if (xq_is_check(b, mv))     return 0;
    if (xq_is_ttc(b, mv))       return 0;
    if (xq_is_chase(b, mv, 0))  return 0;
    if (xq_is_exchange(b, mv))  return 0;
    if (xq_is_block(b, mv))     return 0;
    if (xq_is_sacrifice(b, mv)) return 0;
    return 1;
}

/* ---- protected, and the real protector -------------------------------------------
 *
 * "A piece is protected if there is a piece that can capture any piece that
 * takes the protected piece. When A takes B, if C can take A, B is protected."
 *
 *   "Real protector  - When a protected piece is taken, the protector can
 *                      actually remove the taker.
 *    False protector - When a protected piece is taken, the protector cannot
 *                      actually remove the taker."
 *
 * `real` IS COMPUTED BY PLAYING THE CAPTURE AND THE RECAPTURE, never from a
 * static attack map, because in this game a protector is false for reasons that
 * do not exist in chess:
 *
 *   the recapture would leave its own general facing the enemy general
 *   the protector is an advisor or an elephant that cannot legally reach
 *   the protector is a horse whose leg the TAKER has just occupied
 *
 * Rule 34 of Section 3 ("a protected piece cannot be perpetually chased if its
 * protector has lost its effectness") is unimplementable without this, and it is
 * one of the forty.
 */
static int xq_protected_at(struct xq_board *b, int pt, int *real)
{
    int piece = AT(b, pt);
    int mine, theirs;
    int buf[XQ_MAX_MOVES];
    int keep = (E())->side(b);
    int n, i, defended, all_recaptured = 1, tested = 0;

    if (real) *real = 0;
    if (!(E())->on_board(pt) || !XQ_IS_PIECE(piece)) return 0;
    mine = XQ_COLOUR(piece);
    theirs = XQ_OTHER(mine);

    defended = (E())->attacked(b, pt, mine);
    if (!defended) return 0;

    /* every legal capture of this piece, answered */
    (E())->set_side(b, theirs);
    n = (E())->gen_legal(b, buf);
    for (i = 0; i < n; i++) {
        struct xq_undo u;
        int back[XQ_MAX_MOVES];
        int m, j, answered = 0;
        if ((E())->move_to(buf[i]) != pt) continue;
        tested++;
        (E())->do_move(b, buf[i], &u);
        m = (E())->gen_legal(b, back);
        for (j = 0; j < m; j++)
            if ((E())->move_to(back[j]) == pt) { answered = 1; break; }
        (E())->undo_move(b, &u);
        if (!answered) { all_recaptured = 0; break; }
    }
    (E())->set_side(b, keep);

    /* Nothing can take it: the protection is untested, not false. A piece
     * nobody attacks is not one whose protector has failed. */
    if (real) *real = (tested == 0) ? 1 : all_recaptured;
    return 1;
}

/* ---- installed into the table by xq_engine.c ------------------------------------- */

void xq_judge_install(struct xq_abi *t);

void xq_judge_install(struct xq_abi *t)
{
    t->is_check     = xq_is_check;
    t->is_mate      = xq_is_mate;
    t->is_ttc       = xq_is_ttc;
    t->is_chase     = xq_is_chase;
    t->is_exchange  = xq_is_exchange;
    t->is_block     = xq_is_block;
    t->is_sacrifice = xq_is_sacrifice;
    t->is_idle      = xq_is_idle;
    t->protected_at = xq_protected_at;
    t->value_of     = xq_value_of;
}

/* ================================================================================
 * THE JUDGE. Phase 06 of plan_xiangqi, and the largest phase in it.
 *
 * A POSITION CAN NEVER BE A DRAW IN THIS GAME. `outcome` says so by having no
 * draw value at all. Every draw xiangqi has is a property of a SEQUENCE, and
 * this is where they live.
 *
 * FOUR STEPS, each testable on its own:
 *
 *   1. find the loop           walk the keys back for a repeat, same side to move
 *   2. describe every move     the nine predicates of phase 05, both sides
 *   3. classify each side      perpetual check, chase, TTC, block, exchange, none
 *   4. rule                    Section 2's four principles over Section 3's forty
 *
 * AND THE PART THAT IS NOT THE ASIAN RULES AT ALL. Rule 3 of Section 3 reads
 * "The side who violates a rule, asked by the referee to alter, and repeats the
 * violation for three times will be ruled to lose", and principle 4 reads "the
 * side violating the rules has to change. Otherwise, it loses". Both presuppose
 * somebody at the table saying so. A bot cannot be asked to alter and a player
 * at a one-minute limit cannot be warned. CXQ is a website that had the same
 * problem and published its answer, so its thresholds supply the WHEN that the
 * Asian Rules leave to a person, and the rules page says they are ours.
 * ============================================================================= */

/* ---- the chase table, rules 15 to 40 --------------------------------------------
 *
 * ROWS CARRY THEIR RULE NUMBER so a ruling can cite it: a player who loses a won
 * position to rule 19 is owed the number, and the site's log prints it.
 *
 * FIRST MATCH WINS, so the specific rows come before the general ones.
 *
 * SIX RULES ARE NOT HERE AND ARE NOT SILENTLY DROPPED: 19, 20, 22, 23, 27 and 37
 * turn on positional facts this table cannot express (a chariot immobilised by a
 * horse, a chariot confined to a line by a cannon, two pieces taking turns under
 * a named control pattern). `rule_count` and `rule_at` enumerate what IS here so
 * a test computes the gap instead of a comment claiming it.
 */
static const struct xq_chase_rule CHASE[] = {
  /* num chaser       victim       prot chasers victims verdict            text */
  /* RULE 34 IS DEFENDED-BUT-FALSELY, NOT UNDEFENDED, and the two have to be
   * told apart or this row shadows every specific rule below it. It matched the
   * first live chase fixture and cited 34 where 18 was the right number, which
   * matters because the site's log prints the number to the player. */
  { 34, 0,            0,            2,  0, 1, XQ_CHASE_FORBIDDEN,
    "a protected piece cannot be perpetually chased if its protector has lost its effectness" },
  { 32, 0,            0,           -1,  1, 2, XQ_CHASE_DRAW,
    "one piece perpetually chases two pieces or more should be ruled as a draw" },
  { 35, 0,            0,            1,  2, 1, XQ_CHASE_DRAW,
    "two or more pieces trying to capture a protected piece does not constitute a perpetual chase" },
  { 33, 0,            0,            0,  2, 1, XQ_CHASE_FORBIDDEN,
    "two or more pieces cannot take turns to perpetually chase a piece" },
  { 30, XQ_GENERAL,   0,           -1,  2, 0, XQ_CHASE_FORBIDDEN,
    "a King or a Pawn cannot work together with another piece to perpetually chase" },
  { 30, XQ_SOLDIER,   0,           -1,  2, 0, XQ_CHASE_FORBIDDEN,
    "a King or a Pawn cannot work together with another piece to perpetually chase" },
  { 28, XQ_GENERAL,   0,           -1,  1, 0, XQ_CHASE_ALLOWED,
    "the King can perpetually chase an enemy piece" },
  { 29, XQ_SOLDIER,   0,           -1,  0, 0, XQ_CHASE_ALLOWED,
    "a Pawn can perpetually chase; two or more Pawns can work together" },
  { 16, XQ_CANNON,    XQ_CHARIOT,  -1,  0, 2, XQ_CHASE_DRAW,
    "one Cannon perpetually chasing two Rooks can be ruled a draw; two Cannons likewise" },
  { 15, XQ_CANNON,    XQ_CHARIOT,  -1,  0, 0, XQ_CHASE_FORBIDDEN,
    "one or two Cannons cannot perpetually chase a Rook even if the Rook is protected" },
  { 21, XQ_HORSE,     XQ_CHARIOT,  -1,  0, 0, XQ_CHASE_FORBIDDEN,
    "a Knight cannot perpetually chase a Rook, regardless of whether the Rook is protected" },
  { 31, XQ_CHARIOT,   XQ_SOLDIER,  -1,  0, 0, XQ_CHASE_FORBIDDEN,
    "a Rook cannot perpetually chase a Pawn that has crossed the river" },
  { 17, XQ_CHARIOT,   XQ_CANNON,    1,  0, 0, XQ_CHASE_ALLOWED,
    "Rook can perpetually chase a protected Cannon" },
  { 18, XQ_CHARIOT,   XQ_CANNON,    0,  0, 0, XQ_CHASE_FORBIDDEN,
    "a Rook cannot perpetually chase an unprotected Cannon" },
  { 25, XQ_CANNON,    XQ_HORSE,     0,  0, 0, XQ_CHASE_FORBIDDEN,
    "a Cannon attacking an unprotected Knight, Guard, Minister or crossed Pawn is a chase" },
  { 25, XQ_CANNON,    XQ_ADVISOR,   0,  0, 0, XQ_CHASE_FORBIDDEN,
    "a Cannon attacking an unprotected Knight, Guard, Minister or crossed Pawn is a chase" },
  { 25, XQ_CANNON,    XQ_ELEPHANT,  0,  0, 0, XQ_CHASE_FORBIDDEN,
    "a Cannon attacking an unprotected Knight, Guard, Minister or crossed Pawn is a chase" },
  { 24, XQ_CHARIOT,   XQ_CHARIOT,  -1,  0, 0, XQ_CHASE_DRAW,
    "Rook chases Rook: if both can capture the other it is perpetual sacrifice, a draw" },
  { 24, XQ_CANNON,    XQ_CANNON,   -1,  0, 0, XQ_CHASE_DRAW,
    "Cannon chases Cannon: if both can capture the other it is perpetual sacrifice, a draw" },
  { 24, XQ_HORSE,     XQ_HORSE,    -1,  0, 0, XQ_CHASE_DRAW,
    "Knight chases Knight: if both can capture the other it is perpetual sacrifice, a draw" },
  /* the general case, which is the encyclopaedia's one-line summary and the
   * LAST row rather than the first: an unprotected piece may not be chased */
  { 36, 0,            0,            0,  0, 0, XQ_CHASE_FORBIDDEN,
    "perpetual chase of an unprotected piece is forbidden; an exchange offer is still a chase" },
  { 36, 0,            0,            1,  0, 0, XQ_CHASE_ALLOWED,
    "a protected piece may be perpetually chased unless a more specific rule says otherwise" }
};

#define CHASE_N ((int)(sizeof(CHASE) / sizeof(CHASE[0])))

static int xq_rule_count(void) { return CHASE_N; }
static const struct xq_chase_rule *xq_rule_at(int i)
{
    if (i < 0 || i >= CHASE_N) return 0;
    return &CHASE[i];
}

/* ---- describing one ply ---------------------------------------------------------- */

struct ply {
    int side;
    int mv;
    int kind;            /* the kind of piece that moved */
    int check, ttc, chase, exchange, block, sacrifice, idle;
    int victim_kind;     /* the chased piece's kind, 0 if not a chase */
    int victim_prot;     /* 1 protected by a REAL protector, 0 otherwise */
    int victim_def;      /* 1 defended AT ALL, real protector or not */
    unsigned long long key;   /* the key AFTER the move */
    int captured;
    int progress;        /* a capture, or a crossed soldier advancing */
};

static int soldier_advance(struct xq_board *b, int mv)
{
    int from = (E())->move_from(mv);
    int p = AT(b, from);
    if (XQ_KIND(p) != XQ_SOLDIER) return 0;
    return (E())->crossed_river(from, XQ_COLOUR(p));
}

/* ---- the judge ------------------------------------------------------------------- */

static int beh_of(const struct ply *p)
{
    if (p->check)     return XQ_BEH_CHECK;
    if (p->chase)     return XQ_BEH_CHASE;
    if (p->ttc)       return XQ_BEH_TTC;
    if (p->block)     return XQ_BEH_BLOCK;
    if (p->exchange)  return XQ_BEH_EXCHANGE;
    if (p->sacrifice) return XQ_BEH_SACRIFICE;
    return XQ_BEH_IDLE;
}

static int threshold(int kinds)
{
    if (kinds <= 1) return XQ_PERPETUAL_1;
    if (kinds == 2) return XQ_PERPETUAL_2;
    return XQ_PERPETUAL_3;
}

/* Section 3's table, applied to one side's perpetual chase. Returns the row or
 * NULL when nothing matches, which cannot happen because the last two rows are
 * general and between them cover every protectedness. */
static const struct xq_chase_rule *chase_rule(int chaser_kind, int victim_kind,
                                              int prot, int def,
                                              int chasers, int victims)
{
    int i;
    for (i = 0; i < CHASE_N; i++) {
        const struct xq_chase_rule *r = &CHASE[i];
        if (r->chaser && r->chaser != chaser_kind) continue;
        if (r->victim && r->victim != victim_kind) continue;
        /* protectedness 2 is rule 34's case: DEFENDED, but falsely */
        if (r->protectedness == 2) { if (!(def && !prot)) continue; }
        else if (r->protectedness >= 0 && r->protectedness != prot) continue;
        if (r->chasers == 1 && chasers != 1) continue;
        if (r->chasers == 2 && chasers < 2) continue;
        if (r->victims == 1 && victims != 1) continue;
        if (r->victims == 2 && victims < 2) continue;
        return r;
    }
    return 0;
}

static int xq_judge(struct xq_board *start, const int *moves, int n,
                    struct xq_verdict *out)
{
    static struct ply ply[XQ_MAX_PLIES];
    struct xq_board *b;
    unsigned long long seen[XQ_MAX_PLIES + 1];
    int i, s, red_first;
    int effective = 0, progress = 0;
    int tolerating = 0;   /* a check or chase run that has not reached CXQ's threshold */

    if (out) {
        out->winner = 0; out->reason = XQ_JUDGE_ONGOING; out->rule = 0;
        out->loop_from = -1; out->loop_len = 0;
        out->behaviour[0] = out->behaviour[1] = XQ_BEH_NONE;
        out->run[0] = out->run[1] = 0;
        out->kinds[0] = out->kinds[1] = 0;
        out->effective = out->progress = out->plies = 0;
    }
    if (n <= 0 || n > XQ_MAX_PLIES) return 0;

    b = (E())->board_copy(start);
    if (!b) return 0;

    /* ---- 1 and 2: replay, describing every ply as it goes ------------------- */
    seen[0] = (E())->key(b);
    for (i = 0; i < n; i++) {
        struct xq_undo u;
        struct ply *p = &ply[i];
        int victim = 0;

        p->side = (E())->side(b);
        p->mv = moves[i];
        p->kind = XQ_KIND(AT(b, (E())->move_from(moves[i])));
        p->check     = (E())->is_check(b, moves[i]);
        p->ttc       = (E())->is_ttc(b, moves[i]);
        p->chase     = (E())->is_chase(b, moves[i], &victim);
        p->exchange  = (E())->is_exchange(b, moves[i]);
        p->block     = (E())->is_block(b, moves[i]);
        p->sacrifice = (E())->is_sacrifice(b, moves[i]);
        p->idle      = (E())->is_idle(b, moves[i]);
        p->progress  = soldier_advance(b, moves[i]);

        p->victim_kind = 0;
        p->victim_prot = 0;
        p->victim_def = 0;
        p->captured = (E())->do_move(b, moves[i], &u);
        if (p->captured != XQ_EMPTY) p->progress = 1;
        if (victim) {
            int real = 0;
            p->victim_kind = XQ_KIND(AT(b, victim));
            /* RULE 34 IS APPLIED HERE AND NOT IN THE TABLE: a protected piece
             * whose protector cannot actually recapture is chased as an
             * unprotected one. Folding it in at the point the protection is
             * measured is what makes the table readable. */
            p->victim_def = (E())->protected_at(b, victim, &real);
            p->victim_prot = p->victim_def && real;
        }
        p->key = (E())->key(b);
        seen[i + 1] = p->key;

        /* CXQ's Effective Rule: "moves made by each side excluding
         * checking/chasing moves or moves to respond to checking/chasing". The
         * count cannot be taken before the classification, which is why phase
         * 08's `play` judges and only then counts. */
        if (!p->check && !p->chase &&
            !(i > 0 && (ply[i - 1].check || ply[i - 1].chase)))
            effective++;
        if (p->progress) progress = 0; else progress++;
    }

    if (out) {
        out->effective = effective / 2;
        out->progress = progress / 2;
        out->plies = n;
    }
    red_first = ply[0].side == XQ_RED ? 0 : 1;
    (void) red_first;

    /* ---- 3: the run at the end, and how many kinds made it ------------------ */
    {
    int raw[2];
    raw[0] = raw[1] = XQ_BEH_NONE;
    for (s = 0; s < 2; s++) {
        int colour = s == 0 ? XQ_RED : XQ_BLACK;
        int run = 0, beh = XQ_BEH_NONE, kindmask = 0, kinds = 0, k;
        for (i = n - 1; i >= 0; i--) {
            if (ply[i].side != colour) continue;
            if (beh == XQ_BEH_NONE) {
                beh = beh_of(&ply[i]);
                if (beh != XQ_BEH_CHECK && beh != XQ_BEH_CHASE &&
                    beh != XQ_BEH_TTC && beh != XQ_BEH_BLOCK &&
                    beh != XQ_BEH_EXCHANGE && beh != XQ_BEH_SACRIFICE) break;
            }
            else if (beh_of(&ply[i]) != beh) break;
            run++;
            kindmask |= 1 << ply[i].kind;
        }
        for (k = 0; k < 8; k++) if (kindmask & (1 << k)) kinds++;
        if (out) { out->run[s] = run; out->kinds[s] = kinds; }
        raw[s] = beh;
        if (beh != XQ_BEH_NONE && run >= threshold(kinds)) {
            if (out) out->behaviour[s] = beh;
        }
    }

    /* PRINCIPLE 1 MUST NOT FIRE WHILE CXQ'S TOLERANCE IS STILL RUNNING, and the
     * first version of this let it.
     *
     * "When neither side violates the rules and both persist on not altering
     * their moves. The game can be ruled as a draw." A side four checks into a
     * shuttle is not a side that violates nothing: it is a side whose violation
     * has not been reached yet. Ruling that a draw hands the checking side an
     * escape it has not earned, and it fired on the perpetual-check fixture at
     * every length below twelve plies.
     *
     * So: if either side's run IS a check or a chase but has not reached the
     * threshold, the answer is ONGOING and nothing else. */
    for (s = 0; s < 2; s++)
        if ((raw[s] == XQ_BEH_CHECK || raw[s] == XQ_BEH_CHASE) &&
            out && out->behaviour[s] == XQ_BEH_NONE)
            tolerating = 1;
    }

    /* ---- the loop, which principle 1 needs --------------------------------- */
    {
        int from = -1;
        for (i = n - 1; i >= 0 && from < 0; i--)
            if (seen[i] == seen[n]) from = i;
        if (out && from >= 0) { out->loop_from = from; out->loop_len = n - from; }
    }

    (E())->board_drop(b);
    if (!out) return 0;

    /* ---- 4: rule ------------------------------------------------------------ */
    {
        int r = out->behaviour[0], k = out->behaviour[1];

        /* Section 2, principle 3: "If one side perpetually check and the other
         * side perpetually chase, the perpetually checking side has to stop or
         * be ruled to lose." It comes FIRST because it decides a case both of
         * the others would also match. */
        if (r == XQ_BEH_CHECK && k == XQ_BEH_CHASE) {
            out->winner = XQ_BLACK; out->reason = XQ_JUDGE_PERPETUAL_CHECK; out->rule = 12;
            return out->winner;
        }
        if (k == XQ_BEH_CHECK && r == XQ_BEH_CHASE) {
            out->winner = XQ_RED; out->reason = XQ_JUDGE_PERPETUAL_CHECK; out->rule = 12;
            return out->winner;
        }

        /* principle 2 and rule 7: "It is a draw when both sides keep checking."
         * Both violating the same rule at the same time is a draw. */
        if (r != XQ_BEH_NONE && r == k) {
            out->winner = 0; out->reason = XQ_JUDGE_MUTUAL;
            out->rule = (r == XQ_BEH_CHECK) ? 7 : 0;
            return 0;
        }

        /* Asian Rules 6: "Under any circumstance, the side that perpetually
         * checks with one piece or several pieces will be ruled to lose." */
        if (r == XQ_BEH_CHECK) { out->winner = XQ_BLACK; out->reason = XQ_JUDGE_PERPETUAL_CHECK; out->rule = 6; return out->winner; }
        if (k == XQ_BEH_CHECK) { out->winner = XQ_RED;   out->reason = XQ_JUDGE_PERPETUAL_CHECK; out->rule = 6; return out->winner; }

        /* rules 9 and 10: perpetual TTC, and resolve-TTC-and-TTC-back, are
         * draws rather than losses, which is the half of the source a summary
         * always drops */
        if (r == XQ_BEH_TTC || k == XQ_BEH_TTC) {
            out->winner = 0; out->reason = XQ_JUDGE_MUTUAL; out->rule = 9; return 0;
        }
        /* rule 39, perpetual block, and rule 40, perpetual exchange or
         * sacrifice: both draws */
        if (r == XQ_BEH_BLOCK || k == XQ_BEH_BLOCK) {
            out->winner = 0; out->reason = XQ_JUDGE_MUTUAL; out->rule = 39; return 0;
        }
        if (r == XQ_BEH_EXCHANGE || k == XQ_BEH_EXCHANGE ||
            r == XQ_BEH_SACRIFICE || k == XQ_BEH_SACRIFICE) {
            out->winner = 0; out->reason = XQ_JUDGE_MUTUAL; out->rule = 40; return 0;
        }

        /* Section 3's chase table, for whichever side is chasing */
        for (s = 0; s < 2; s++) {
            int colour = s == 0 ? XQ_RED : XQ_BLACK;
            int kindmask = 0, vmask = 0, chasers = 0, victims = 0, kk;
            const struct xq_chase_rule *row;
            int vkind = 0, prot = 1, def = 1, ckind = 0;
            if (out->behaviour[s] != XQ_BEH_CHASE) continue;
            for (i = n - 1; i >= 0 && n - i <= out->run[s] * 2 + 1; i--) {
                if (ply[i].side != colour || !ply[i].chase) continue;
                kindmask |= 1 << ply[i].kind;
                vmask |= 1 << ply[i].victim_kind;
                vkind = ply[i].victim_kind;
                /* THE CHASER'S KIND COMES FROM THE CHASING SIDE'S OWN PLY.
                 * Taking it from the last ply of the log takes it from the side
                 * RUNNING AWAY, which cited rule 24 (chariot chases chariot) for
                 * a chariot chasing a cannon. */
                if (!ckind) ckind = ply[i].kind;
                if (!ply[i].victim_prot) prot = 0;
                if (!ply[i].victim_def) def = 0;
            }
            for (kk = 0; kk < 8; kk++) {
                if (kindmask & (1 << kk)) chasers++;
                if (kk && (vmask & (1 << kk))) victims++;
            }
            row = chase_rule(ckind, vkind, prot, def, chasers, victims);
            if (!row) continue;
            out->rule = row->number;
            if (row->verdict == XQ_CHASE_FORBIDDEN) {
                out->winner = XQ_OTHER(colour);
                out->reason = XQ_JUDGE_PERPETUAL_CHASE;
                return out->winner;
            }
            if (row->verdict == XQ_CHASE_DRAW) {
                out->winner = 0; out->reason = XQ_JUDGE_MUTUAL; return 0;
            }
            /* ALLOWED: the chased side must live with it, and the game goes on
             * unless a counter fires below */
            out->rule = row->number;
        }

        /* ---- CXQ's three automatic draws, and they are OURS by adoption ----- */
        if (out->progress >= XQ_PROGRESS_CAP) {
            out->winner = 0; out->reason = XQ_JUDGE_PROGRESS; out->rule = 0; return 0;
        }
        if (out->effective >= XQ_EFFECTIVE_CAP) {
            out->winner = 0; out->reason = XQ_JUDGE_EFFECTIVE; out->rule = 0; return 0;
        }
        if (n / 2 >= XQ_MOVES_CAP) {
            out->winner = 0; out->reason = XQ_JUDGE_MOVES; out->rule = 0; return 0;
        }

        /* Section 2, principle 1: "When neither side violates the rules and both
         * persist on not altering their moves. The game can be ruled as a draw."
         * A loop with nobody in breach is that, and nothing else is. */
        if (out->loop_from >= 0 && r == XQ_BEH_NONE && k == XQ_BEH_NONE &&
            !tolerating && out->loop_len >= 4) {
            out->winner = 0; out->reason = XQ_JUDGE_NO_VIOLATION; out->rule = 5;
            return 0;
        }
    }
    return 0;
}

void xq_judge2_install(struct xq_abi *t);

void xq_judge2_install(struct xq_abi *t)
{
    t->judge      = xq_judge;
    t->rule_count = xq_rule_count;
    t->rule_at    = xq_rule_at;
}
