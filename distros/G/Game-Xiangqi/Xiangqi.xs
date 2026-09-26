/* Xiangqi.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * siblings that learned this the hard way say so in Go.xs and Balls.xs.
 *
 * The XSUBs land in Game::Xiangqi::Engine, not in Game::Xiangqi, and are named
 * with a leading underscore: they take a raw pointer as a UV and there is no
 * typemap. The Perl that owns the lifetime is lib/Game/Xiangqi/Engine.pm.
 *
 * PHASE 02 SCOPE. This door reaches the board only. `_put` and `_lift` are the
 * structure primitives from xq_abi.h and CHECK NOTHING: they exist so
 * t/01-board.t can build a position by hand. Generation, legality, check and
 * mate are phases 03 and 04 and they append to the table rather than changing
 * it.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xq_abi.h"

static const struct xq_abi *XQ = NULL;

#define BOARD(u) INT2PTR(struct xq_board *, (u))

/* A 64-bit value crosses as a 16-character hex string, never as a UV.
 *
 * On a perl with 32-bit IVs a UV cannot hold it and the top half would vanish
 * silently, which for a zobrist key means a test that passes while comparing
 * half a number. Hand-rolled rather than via my_snprintf, which takes a length
 * argument that shadows a local called len in a way that has bitten the house
 * before. Copied from Go.xs, which is where it was worked out.
 */
static SV *xq_hex64(pTHX_ unsigned long long v)
{
    static const char digits[] = "0123456789abcdef";
    char buf[16];
    int i;
    for (i = 15; i >= 0; i--) {
        buf[i] = digits[v & 0xfULL];
        v >>= 4;
    }
    return newSVpvn(buf, 16);
}

MODULE = Game::Xiangqi    PACKAGE = Game::Xiangqi::Engine

PROTOTYPES: DISABLE

BOOT:
    XQ = xq_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(XQ);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)XQ->abi_version;
    OUTPUT:
        RETVAL

UV
_new_board()
    CODE:
        RETVAL = PTR2UV((XQ->board_new)());
    OUTPUT:
        RETVAL

UV
_new_empty()
    CODE:
        RETVAL = PTR2UV((XQ->board_empty)());
    OUTPUT:
        RETVAL

UV
_copy_board(u)
        UV u
    CODE:
        RETVAL = PTR2UV((XQ->board_copy)(BOARD(u)));
    OUTPUT:
        RETVAL

void
_drop_board(u)
        UV u
    CODE:
        (XQ->board_drop)(BOARD(u));

# A FEN that will not parse returns undef and sets the code in the second
# element, rather than croaking: the reason is what a caller shows a person, and
# six of them are distinguishable.
void
_of_fen(fen)
        const char *fen
    PREINIT:
        struct xq_board *b;
        int err = 0;
    PPCODE:
        b = (XQ->board_of_fen)(fen, &err);
        EXTEND(SP, 2);
        if (b) PUSHs(sv_2mortal(newSVuv(PTR2UV(b))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(err)));

SV *
_to_fen(u)
        UV u
    PREINIT:
        char buf[XQ_FEN_MAX];
        int n;
    CODE:
        n = (XQ->to_fen)(BOARD(u), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

int
_at(u, pt)
        UV u
        int pt
    CODE:
        RETVAL = (XQ->at)(BOARD(u), pt);
    OUTPUT:
        RETVAL

void
_put(u, pt, piece)
        UV u
        int pt
        int piece
    CODE:
        (XQ->put)(BOARD(u), pt, piece);

void
_lift(u, pt)
        UV u
        int pt
    CODE:
        (XQ->lift)(BOARD(u), pt);

int
_side(u)
        UV u
    CODE:
        RETVAL = (XQ->side)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_side(u, colour)
        UV u
        int colour
    CODE:
        (XQ->set_side)(BOARD(u), colour);

int
_count(u, piece)
        UV u
        int piece
    CODE:
        RETVAL = (XQ->count)(BOARD(u), piece);
    OUTPUT:
        RETVAL

int
_find(u, piece)
        UV u
        int piece
    CODE:
        RETVAL = (XQ->find)(BOARD(u), piece);
    OUTPUT:
        RETVAL

int
_move_make(from, to)
        int from
        int to
    CODE:
        RETVAL = (XQ->move_make)(from, to);
    OUTPUT:
        RETVAL

int
_move_from(mv)
        int mv
    CODE:
        RETVAL = (XQ->move_from)(mv);
    OUTPUT:
        RETVAL

int
_move_to(mv)
        int mv
    CODE:
        RETVAL = (XQ->move_to)(mv);
    OUTPUT:
        RETVAL

# The undo crosses as a STRING OF RAW BYTES and not as a pointer, so nothing is
# allocated and nothing can leak when a caller forgets to undo. The header calls
# struct xq_undo a value type; an SV of its bytes is exactly that. Returns
# (captured, undo).
void
_do_move(u, mv)
        UV u
        int mv
    PREINIT:
        struct xq_undo undo;
        int captured;
    PPCODE:
        captured = (XQ->do_move)(BOARD(u), mv, &undo);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(captured)));
        PUSHs(sv_2mortal(newSVpvn((char *)&undo, sizeof(undo))));

void
_undo_move(u, sv)
        UV u
        SV *sv
    PREINIT:
        struct xq_undo undo;
        STRLEN len;
        const char *p;
    CODE:
        p = SvPV(sv, len);
        if (len != sizeof(undo))
            croak("Game::Xiangqi::Engine: undo token is %d bytes, wanted %d",
                  (int)len, (int)sizeof(undo));
        Copy(p, &undo, 1, struct xq_undo);
        (XQ->undo_move)(BOARD(u), &undo);

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = xq_hex64(aTHX_ (XQ->key)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_zobrist_hex(piece, pt)
        int piece
        int pt
    CODE:
        RETVAL = xq_hex64(aTHX_ (XQ->zobrist)(piece, pt));
    OUTPUT:
        RETVAL

int
_point_of(file, rank)
        int file
        int rank
    CODE:
        RETVAL = (XQ->point_of)(file, rank);
    OUTPUT:
        RETVAL

int
_file_of(pt)
        int pt
    CODE:
        RETVAL = (XQ->file_of)(pt);
    OUTPUT:
        RETVAL

int
_rank_of(pt)
        int pt
    CODE:
        RETVAL = (XQ->rank_of)(pt);
    OUTPUT:
        RETVAL

int
_on_board(pt)
        int pt
    CODE:
        RETVAL = (XQ->on_board)(pt);
    OUTPUT:
        RETVAL

int
_in_palace(pt, colour)
        int pt
        int colour
    CODE:
        RETVAL = (XQ->in_palace)(pt, colour);
    OUTPUT:
        RETVAL

int
_crossed_river(pt, colour)
        int pt
        int colour
    CODE:
        RETVAL = (XQ->crossed_river)(pt, colour);
    OUTPUT:
        RETVAL

int
_stride()
    CODE:
        RETVAL = (XQ->stride)();
    OUTPUT:
        RETVAL

# ---- phase 03: generation, the attack walk, and perft -----------------------

int
_horse_leg(u, from, to)
        UV u
        int from
        int to
    CODE:
        RETVAL = (XQ->horse_leg)(BOARD(u), from, to);
    OUTPUT:
        RETVAL

int
_elephant_eye(u, from, to)
        UV u
        int from
        int to
    CODE:
        RETVAL = (XQ->elephant_eye)(BOARD(u), from, to);
    OUTPUT:
        RETVAL

int
_cannon_screens(u, from, to)
        UV u
        int from
        int to
    CODE:
        RETVAL = (XQ->cannon_screens)(BOARD(u), from, to);
    OUTPUT:
        RETVAL

int
_soldier_may(u, from, to)
        UV u
        int from
        int to
    CODE:
        RETVAL = (XQ->soldier_may)(BOARD(u), from, to);
    OUTPUT:
        RETVAL

int
_generals_face(u)
        UV u
    CODE:
        RETVAL = (XQ->generals_face)(BOARD(u));
    OUTPUT:
        RETVAL

int
_attacked(u, pt, by)
        UV u
        int pt
        int by
    CODE:
        RETVAL = (XQ->attacked)(BOARD(u), pt, by);
    OUTPUT:
        RETVAL

int
_in_check(u, colour)
        UV u
        int colour
    CODE:
        RETVAL = (XQ->in_check)(BOARD(u), colour);
    OUTPUT:
        RETVAL

void
_gen_moves(u)
        UV u
    PREINIT:
        int buf[XQ_MAX_MOVES];
        int n, i;
    PPCODE:
        n = (XQ->gen_moves)(BOARD(u), buf);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(buf[i])));

void
_gen_legal(u)
        UV u
    PREINIT:
        int buf[XQ_MAX_MOVES];
        int n, i;
    PPCODE:
        n = (XQ->gen_legal)(BOARD(u), buf);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(buf[i])));

# The four counters come back as strings, for the reason the key does: depth 6
# is 5,392,831,844 nodes and a 32-bit IV would quietly keep the low half.
void
_perft(u, depth)
        UV u
        int depth
    PREINIT:
        struct xq_perft p;
        char buf[24];
    PPCODE:
        (XQ->perft)(BOARD(u), depth, &p);
        EXTEND(SP, 4);
#define PUSH_U64(v) \
        do { int n_ = sprintf(buf, "%.0f", (double)(v)); \
             PUSHs(sv_2mortal(newSVpvn(buf, n_))); } while (0)
        PUSH_U64(p.nodes);
        PUSH_U64(p.checks);
        PUSH_U64(p.captures);
        PUSH_U64(p.mates);
#undef PUSH_U64

# ---- phase 04: the endings and the mate search ------------------------------

# Returns (winner_colour, reason). winner is 0 while the game is on. BOTH
# reasons are a win for the side not to move: a stalemate is a loss in this game.
void
_outcome(u)
        UV u
    PREINIT:
        int reason = 0;
        int winner;
    PPCODE:
        winner = (XQ->outcome)(BOARD(u), &reason);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(winner)));
        PUSHs(sv_2mortal(newSViv(reason)));

int
_mate_in(u, plies)
        UV u
        int plies
    CODE:
        RETVAL = (XQ->mate_in)(BOARD(u), plies);
    OUTPUT:
        RETVAL

# ---- phase 05: the vocabulary of the Asian Rules ----------------------------

int
_is_check(u, mv)
        UV u
        int mv
    CODE:
        RETVAL = (XQ->is_check)(BOARD(u), mv);
    OUTPUT:
        RETVAL

int
_is_mate(u, mv)
        UV u
        int mv
    CODE:
        RETVAL = (XQ->is_mate)(BOARD(u), mv);
    OUTPUT:
        RETVAL

int
_is_ttc(u, mv)
        UV u
        int mv
    CODE:
        RETVAL = (XQ->is_ttc)(BOARD(u), mv);
    OUTPUT:
        RETVAL

# returns (is_chase, victim_point)
void
_is_chase(u, mv)
        UV u
        int mv
    PREINIT:
        int victim = 0, r;
    PPCODE:
        r = (XQ->is_chase)(BOARD(u), mv, &victim);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(r)));
        PUSHs(sv_2mortal(newSViv(victim)));

int
_is_exchange(u, mv)
        UV u
        int mv
    CODE:
        RETVAL = (XQ->is_exchange)(BOARD(u), mv);
    OUTPUT:
        RETVAL

int
_is_block(u, mv)
        UV u
        int mv
    CODE:
        RETVAL = (XQ->is_block)(BOARD(u), mv);
    OUTPUT:
        RETVAL

int
_is_sacrifice(u, mv)
        UV u
        int mv
    CODE:
        RETVAL = (XQ->is_sacrifice)(BOARD(u), mv);
    OUTPUT:
        RETVAL

int
_is_idle(u, mv)
        UV u
        int mv
    CODE:
        RETVAL = (XQ->is_idle)(BOARD(u), mv);
    OUTPUT:
        RETVAL

# returns (protected, real)
void
_protected_at(u, pt)
        UV u
        int pt
    PREINIT:
        int real = 0, r;
    PPCODE:
        r = (XQ->protected_at)(BOARD(u), pt, &real);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(r)));
        PUSHs(sv_2mortal(newSViv(real)));

int
_value_of(piece)
        int piece
    CODE:
        RETVAL = (XQ->value_of)(piece);
    OUTPUT:
        RETVAL

# ---- phase 06: the judge -----------------------------------------------------

# Takes the move list as an array ref of packed moves and returns a flat list of
# key/value pairs, which the Perl side turns into a hash. A struct with eleven
# fields is not worth a typemap for one caller.
void
_judge(u, av)
        UV u
        AV *av
    PREINIT:
        struct xq_verdict v;
        int moves[XQ_MAX_PLIES];
        int n, i;
    PPCODE:
        n = av_len(av) + 1;
        if (n > XQ_MAX_PLIES) n = XQ_MAX_PLIES;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            moves[i] = e ? (int) SvIV(*e) : 0;
        }
        (XQ->judge)(BOARD(u), moves, n, &v);
        EXTEND(SP, 22);
#define PAIR(k, val) \
        do { PUSHs(sv_2mortal(newSVpv(k, 0))); \
             PUSHs(sv_2mortal(newSViv(val))); } while (0)
        PAIR("winner",    v.winner);
        PAIR("reason",    v.reason);
        PAIR("rule",      v.rule);
        PAIR("loop_from", v.loop_from);
        PAIR("loop_len",  v.loop_len);
        PAIR("red",       v.behaviour[0]);
        PAIR("black",     v.behaviour[1]);
        PAIR("red_run",   v.run[0]);
        PAIR("black_run", v.run[1]);
        PAIR("effective", v.effective);
        PAIR("progress",  v.progress);
#undef PAIR

int
_rule_count()
    CODE:
        RETVAL = (XQ->rule_count)();
    OUTPUT:
        RETVAL

void
_rule_at(i)
        int i
    PREINIT:
        const struct xq_chase_rule *r;
    PPCODE:
        r = (XQ->rule_at)(i);
        if (!r) XSRETURN_EMPTY;
        EXTEND(SP, 8);
        PUSHs(sv_2mortal(newSViv(r->number)));
        PUSHs(sv_2mortal(newSViv(r->chaser)));
        PUSHs(sv_2mortal(newSViv(r->victim)));
        PUSHs(sv_2mortal(newSViv(r->protectedness)));
        PUSHs(sv_2mortal(newSViv(r->chasers)));
        PUSHs(sv_2mortal(newSViv(r->victims)));
        PUSHs(sv_2mortal(newSViv(r->verdict)));
        PUSHs(sv_2mortal(newSVpv(r->text, 0)));

# ---- phase 09: the search ----------------------------------------------------

int
_evaluate(u)
        UV u
    CODE:
        RETVAL = (XQ->evaluate)(BOARD(u));
    OUTPUT:
        RETVAL

# returns (move, nodes, depth, score, stopped). nodes as a string: a budget of
# billions is legal and a 32-bit IV would keep the low half.
void
_search(u, budget, seed)
        UV u
        double budget
        UV seed
    PREINIT:
        struct xq_search_info info;
        char buf[24];
        int mv, n;
    PPCODE:
        mv = (XQ->search_best)(BOARD(u), (unsigned long long) budget,
                               (unsigned int) seed, &info);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSViv(mv)));
        n = sprintf(buf, "%.0f", (double) info.nodes);
        PUSHs(sv_2mortal(newSVpvn(buf, n)));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.score)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));

void
_search_to_depth(u, max_depth, budget, seed)
        UV u
        int max_depth
        double budget
        UV seed
    PREINIT:
        struct xq_search_info info;
        char buf[24];
        int mv, n;
    PPCODE:
        mv = (XQ->search_to_depth)(BOARD(u), max_depth,
                                   (unsigned long long) budget,
                                   (unsigned int) seed, &info);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSViv(mv)));
        n = sprintf(buf, "%.0f", (double) info.nodes);
        PUSHs(sv_2mortal(newSVpvn(buf, n)));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.score)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));
