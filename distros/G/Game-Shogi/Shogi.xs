/* Shogi.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * siblings that learned this the hard way say so in Go.xs and Xiangqi.xs.
 *
 * The XSUBs land in Game::Shogi::Engine, not in Game::Shogi, and are named
 * with a leading underscore: they take a raw pointer as a UV and there is no
 * typemap. The Perl that owns the lifetime is lib/Game/Shogi/Engine.pm.
 *
 * `_put`, `_lift` and `_set_hand` are the structure primitives from shg_abi.h
 * and CHECK NOTHING.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "shg_abi.h"

static const struct shg_abi *SHG = NULL;

#define BOARD(u) INT2PTR(struct shg_board *, (u))

/* A 64-bit value crosses as a 16-character hex string, never as a UV.
 *
 * On a perl with 32-bit IVs a UV cannot hold it and the top half would vanish
 * silently, which for a zobrist key means a test that passes while comparing
 * half a number. Hand-rolled rather than via my_snprintf, as Sternhalma.xs has
 * it.
 */
static SV *shg_hex64(pTHX_ unsigned long long v)
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

MODULE = Game::Shogi    PACKAGE = Game::Shogi::Engine

PROTOTYPES: DISABLE

BOOT:
    SHG = shg_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(SHG);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)SHG->abi_version;
    OUTPUT:
        RETVAL

int
_tables_ok()
    CODE:
        RETVAL = (SHG->tables_ok)();
    OUTPUT:
        RETVAL

UV
_new_board()
    CODE:
        RETVAL = PTR2UV((SHG->board_new)());
    OUTPUT:
        RETVAL

UV
_new_empty()
    CODE:
        RETVAL = PTR2UV((SHG->board_empty)());
    OUTPUT:
        RETVAL

UV
_copy_board(u)
        UV u
    CODE:
        RETVAL = PTR2UV((SHG->board_copy)(BOARD(u)));
    OUTPUT:
        RETVAL

# The board is let go by an object of its own, held by the board's object and
# freed with it. Its DESTROY is C and calls no perl.
SV *
_hold_board(u)
        UV u
    CODE:
        RETVAL = sv_setref_uv(newSV(0), "Game::Shogi::Engine::Hold", u);
    OUTPUT:
        RETVAL

int
_live()
    CODE:
        RETVAL = (SHG->live)();
    OUTPUT:
        RETVAL

# An SFEN that will not parse returns undef and the code, rather than
# croaking: the reason is what a caller shows a person, and twelve of them are
# distinguishable.
void
_of_sfen(str)
        const char *str
    PREINIT:
        struct shg_board *b;
        int err = 0;
    PPCODE:
        b = (SHG->board_of_sfen)(str, &err);
        EXTEND(SP, 2);
        if (b) PUSHs(sv_2mortal(newSVuv(PTR2UV(b))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(err)));

SV *
_to_sfen(u)
        UV u
    PREINIT:
        char buf[SHG_SFEN_MAX];
        int n;
    CODE:
        n = (SHG->to_sfen)(BOARD(u), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

int
_at(u, sq)
        UV u
        int sq
    CODE:
        RETVAL = (SHG->at)(BOARD(u), sq);
    OUTPUT:
        RETVAL

void
_put(u, sq, piece)
        UV u
        int sq
        int piece
    CODE:
        (SHG->put)(BOARD(u), sq, piece);

void
_lift(u, sq)
        UV u
        int sq
    CODE:
        (SHG->lift)(BOARD(u), sq);

int
_hand(u, side, kind)
        UV u
        int side
        int kind
    CODE:
        RETVAL = (SHG->hand)(BOARD(u), side, kind);
    OUTPUT:
        RETVAL

void
_set_hand(u, side, kind, count)
        UV u
        int side
        int kind
        int count
    CODE:
        (SHG->set_hand)(BOARD(u), side, kind, count);

int
_to_move(u)
        UV u
    CODE:
        RETVAL = (SHG->to_move)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_to_move(u, side)
        UV u
        int side
    CODE:
        (SHG->set_to_move)(BOARD(u), side);

int
_move_number(u)
        UV u
    CODE:
        RETVAL = (SHG->move_number)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_move_number(u, n)
        UV u
        int n
    CODE:
        (SHG->set_move_number)(BOARD(u), n);

int
_king_sq(u, side)
        UV u
        int side
    CODE:
        RETVAL = (SHG->king_sq)(BOARD(u), side);
    OUTPUT:
        RETVAL

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = shg_hex64(aTHX_ (SHG->key)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_zobrist_hex(side, kind, sq)
        int side
        int kind
        int sq
    CODE:
        RETVAL = shg_hex64(aTHX_ (SHG->zobrist)(side, kind, sq));
    OUTPUT:
        RETVAL

SV *
_zobrist_hand_hex(side, kind, count)
        int side
        int kind
        int count
    CODE:
        RETVAL = shg_hex64(aTHX_ (SHG->zobrist_hand)(side, kind, count));
    OUTPUT:
        RETVAL

SV *
_zobrist_move_hex()
    CODE:
        RETVAL = shg_hex64(aTHX_ (SHG->zobrist_move)());
    OUTPUT:
        RETVAL

int
_sq_of(file, rank)
        int file
        int rank
    CODE:
        RETVAL = (SHG->sq_of)(file, rank);
    OUTPUT:
        RETVAL

int
_file_of(sq)
        int sq
    CODE:
        RETVAL = (SHG->file_of)(sq);
    OUTPUT:
        RETVAL

int
_rank_of(sq)
        int sq
    CODE:
        RETVAL = (SHG->rank_of)(sq);
    OUTPUT:
        RETVAL

int
_step(sq, dfile, drank)
        int sq
        int dfile
        int drank
    CODE:
        RETVAL = (SHG->step)(sq, dfile, drank);
    OUTPUT:
        RETVAL

int
_in_zone(side, sq)
        int side
        int sq
    CODE:
        RETVAL = (SHG->in_zone)(side, sq);
    OUTPUT:
        RETVAL

int
_last_distance(side, sq)
        int side
        int sq
    CODE:
        RETVAL = (SHG->last_distance)(side, sq);
    OUTPUT:
        RETVAL

int
_promoted(kind)
        int kind
    CODE:
        RETVAL = (SHG->promoted)(kind);
    OUTPUT:
        RETVAL

int
_unpromoted(kind)
        int kind
    CODE:
        RETVAL = (SHG->unpromoted)(kind);
    OUTPUT:
        RETVAL

int
_set_count(kind)
        int kind
    CODE:
        RETVAL = (SHG->set_count)(kind);
    OUTPUT:
        RETVAL

# ---- version 2: the board moves ---------------------------------------------------

int
_attacked(u, sq, by)
        UV u
        int sq
        int by
    CODE:
        RETVAL = (SHG->attacked)(BOARD(u), sq, by);
    OUTPUT:
        RETVAL

int
_in_check(u, side)
        UV u
        int side
    CODE:
        RETVAL = (SHG->in_check)(BOARD(u), side);
    OUTPUT:
        RETVAL

void
_pseudo_moves(u)
        UV u
    PREINIT:
        int out[SHG_MOVES_MAX];
        int n, i;
    PPCODE:
        n = (SHG->pseudo_moves)(BOARD(u), out, SHG_MOVES_MAX);
        if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

void
_board_moves(u)
        UV u
    PREINIT:
        int out[SHG_MOVES_MAX];
        int n, i;
    PPCODE:
        n = (SHG->board_moves)(BOARD(u), out, SHG_MOVES_MAX);
        if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

# The undo record crosses as the bytes of the struct. undo_move checks it
# against the board, so a string that was never one is refused, not obeyed.
SV *
_do_move(u, move)
        UV u
        int move
    PREINIT:
        struct shg_undo undo;
    CODE:
        if (!(SHG->do_move)(BOARD(u), move, &undo)) XSRETURN_UNDEF;
        RETVAL = newSVpvn((const char *)&undo, sizeof undo);
    OUTPUT:
        RETVAL

int
_undo_move(u, record)
        UV u
        SV *record
    PREINIT:
        struct shg_undo undo;
        STRLEN len;
        const char *bytes;
    CODE:
        bytes = SvPV(record, len);
        if (len != sizeof undo) XSRETURN_IV(0);
        memcpy(&undo, bytes, sizeof undo);
        RETVAL = (SHG->undo_move)(BOARD(u), &undo);
    OUTPUT:
        RETVAL

# ---- version 3: the drops ---------------------------------------------------------

void
_drops(u)
        UV u
    PREINIT:
        int out[SHG_MOVES_MAX];
        int n, i;
    PPCODE:
        n = (SHG->drops)(BOARD(u), out, SHG_MOVES_MAX);
        if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

void
_legal(u)
        UV u
    PREINIT:
        int out[SHG_MOVES_MAX];
        int n, i;
    PPCODE:
        n = (SHG->legal)(BOARD(u), out, SHG_MOVES_MAX);
        if (n > SHG_MOVES_MAX) n = SHG_MOVES_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

int
_has_legal_move(u)
        UV u
    CODE:
        RETVAL = (SHG->has_legal_move)(BOARD(u));
    OUTPUT:
        RETVAL

int
_drop_fault(u, kind, sq)
        UV u
        int kind
        int sq
    CODE:
        RETVAL = (SHG->drop_fault)(BOARD(u), kind, sq);
    OUTPUT:
        RETVAL

# The six counts as NVs: exact to 2**53, which no perft this dist runs comes
# near, and a UV on a 32-bit perl does not hold depth 7's fifteen billion.
void
_perft(u, depth)
        UV u
        int depth
    PREINIT:
        unsigned long long counts[SHG_PERFT_COUNTS];
        int i;
    PPCODE:
        (SHG->perft)(BOARD(u), depth, counts);
        EXTEND(SP, SHG_PERFT_COUNTS);
        for (i = 0; i < SHG_PERFT_COUNTS; i++) PUSHs(sv_2mortal(newSVnv((NV)counts[i])));

# ---- version 4: how a position ends -----------------------------------------------

int
_status(u)
        UV u
    CODE:
        RETVAL = (SHG->status)(BOARD(u));
    OUTPUT:
        RETVAL

int
_move_fault(u, move)
        UV u
        int move
    CODE:
        RETVAL = (SHG->move_fault)(BOARD(u), move);
    OUTPUT:
        RETVAL

# ---- version 5: what needs the history ---------------------------------------------

SV *
_pack(u)
        UV u
    PREINIT:
        unsigned char buf[SHG_PACKED];
    CODE:
        if ((SHG->pack)(BOARD(u), buf) != SHG_PACKED) XSRETURN_UNDEF;
        RETVAL = newSVpvn((const char *)buf, SHG_PACKED);
    OUTPUT:
        RETVAL

int
_impasse_points(u, side)
        UV u
        int side
    CODE:
        RETVAL = (SHG->impasse_points)(BOARD(u), side);
    OUTPUT:
        RETVAL

int
_impasse_pieces(u, side)
        UV u
        int side
    CODE:
        RETVAL = (SHG->impasse_pieces)(BOARD(u), side);
    OUTPUT:
        RETVAL

int
_declare_fault(u)
        UV u
    CODE:
        RETVAL = (SHG->declare_fault)(BOARD(u));
    OUTPUT:
        RETVAL

# Three array references of the same length: the keys as sixteen hex digits,
# the packed positions, and whether the move into each gave check. Anything
# malformed is no repetition. Returns the code and the loser, -1 for none.
void
_repetition(keys_rv, packed_rv, checks_rv)
        SV *keys_rv
        SV *packed_rv
        SV *checks_rv
    PREINIT:
        AV *ka, *pa, *ca;
        SSize_t n, i;
        unsigned long long *keys;
        unsigned char *packed, *checks;
        int code = SHG_REP_NONE, loser = -1, ok = 1;
    PPCODE:
        if (SvROK(keys_rv) && SvTYPE(SvRV(keys_rv)) == SVt_PVAV
            && SvROK(packed_rv) && SvTYPE(SvRV(packed_rv)) == SVt_PVAV
            && SvROK(checks_rv) && SvTYPE(SvRV(checks_rv)) == SVt_PVAV) {
            ka = (AV *)SvRV(keys_rv);
            pa = (AV *)SvRV(packed_rv);
            ca = (AV *)SvRV(checks_rv);
            n = av_len(ka) + 1;
            if (n > 0 && n == av_len(pa) + 1 && n == av_len(ca) + 1 && n < 100000) {
                Newx(keys, n, unsigned long long);
                Newx(packed, (size_t)n * SHG_PACKED, unsigned char);
                Newx(checks, n, unsigned char);
                for (i = 0; i < n && ok; i++) {
                    SV **k = av_fetch(ka, i, 0), **p = av_fetch(pa, i, 0), **c = av_fetch(ca, i, 0);
                    STRLEN klen, plen;
                    const char *ks, *ps;
                    char *end;
                    if (!k || !p || !c) { ok = 0; break; }
                    ks = SvPV(*k, klen);
                    ps = SvPV(*p, plen);
                    if (klen != 16 || plen != SHG_PACKED) { ok = 0; break; }
                    keys[i] = strtoull(ks, &end, 16);
                    if (end != ks + 16) { ok = 0; break; }
                    memcpy(packed + (size_t)i * SHG_PACKED, ps, SHG_PACKED);
                    checks[i] = SvTRUE(*c) ? 1 : 0;
                }
                if (ok) code = (SHG->repetition)(keys, packed, checks, (int)n, &loser);
                Safefree(keys);
                Safefree(packed);
                Safefree(checks);
            }
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(code)));
        PUSHs(sv_2mortal(newSViv(loser)));

# ---- version 6: the search ----------------------------------------------------------

int
_evaluate(u, flags)
        UV u
        int flags
    CODE:
        RETVAL = (SHG->evaluate)(BOARD(u), flags);
    OUTPUT:
        RETVAL

# The move, then the nodes (an NV, exact to 2**53), the depth, the score and
# whether the budget stopped it. `history` is an array reference of the keys,
# as sixteen hex digits, of the positions the game stood in before this one;
# anything else is no history.
void
_search(u, budget, max_depth, seed, flags, history)
        UV u
        NV budget
        int max_depth
        UV seed
        int flags
        SV *history
    PREINIT:
        struct shg_search_info info;
        int move, n = 0;
        unsigned long long *keys = NULL;
    PPCODE:
        if (SvROK(history) && SvTYPE(SvRV(history)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(history);
            SSize_t i, len = av_len(av) + 1;
            if (len > 0 && len < 100000) {
                Newx(keys, len, unsigned long long);
                for (i = 0; i < len; i++) {
                    SV **k = av_fetch(av, i, 0);
                    STRLEN kl;
                    const char *ks;
                    if (!k) continue;
                    ks = SvPV(*k, kl);
                    if (kl == 16) keys[n++] = strtoull(ks, NULL, 16);
                }
            }
        }
        move = (SHG->search)(BOARD(u), budget < 1 ? 1ULL : (unsigned long long) budget, max_depth,
                             (unsigned int) seed, flags, keys, n, &info);
        if (keys) Safefree(keys);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSViv(move)));
        PUSHs(sv_2mortal(newSVnv((NV) info.nodes)));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.score)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));

MODULE = Game::Shogi    PACKAGE = Game::Shogi::Engine::Hold

PROTOTYPES: DISABLE

# ---- letting go -----------------------------------------------------------------
#
# WHY THIS IS NOT A DEMOLISH IN PERL. On perls 5.14 to 5.26 an eval that runs
# inside a destructor, while an exception is unwinding past a TEMPORARY of that
# class, leaves $@ empty: the caller's die arrives with no message. Object::Proto
# calls DEMOLISH under an eval, so any class with one has this. Fanorona found
# it; Sternhalma.xs carries the same fix. A DESTROY written in C runs no eval.

void
DESTROY(self)
        SV *self
    PREINIT:
        SV *inner;
        UV u;
    CODE:
        if (SvROK(self)) {
            inner = SvRV(self);
            u = SvUV(inner);
            if (u) {
                sv_setuv(inner, 0);
                (SHG->board_drop)(BOARD(u));
            }
        }
