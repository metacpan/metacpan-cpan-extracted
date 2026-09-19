/* Go.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * sibling that learned this the hard way says so in Balls.xs.
 *
 * The XSUBs land in Game::Go::Engine, not in Game::Go, and are named with a
 * leading underscore: they take a raw pointer as a UV and there is no typemap.
 * The Perl that owns the lifetime is lib/Game/Go/Engine.pm.
 *
 * PHASE 01 SCOPE. This door reaches the board and the chains only. `_put` and
 * `_lift` are the structure primitives from go_abi.h and CHECK NOTHING: they
 * exist so t/01-chains.t can build a position by hand. The rules XSUBs
 * (legality, capture, ko, superko) are phase 02 and append to the table rather
 * than changing it.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "go_abi.h"

static const struct go_abi *GO = NULL;

#define BOARD(u) INT2PTR(struct go_board *, (u))

/* A history UV of 0 is a null history, which the engine reads as simple ko
 * only. Zero is safe as the sentinel here in a way it is not for a point: a
 * point of 0 is a real index into the padded board, but no allocation ever
 * lands at address 0. */
#define HIST(u)  ((u) ? INT2PTR(struct go_hist *, (u)) : (struct go_hist *)NULL)

/* A 64-bit value crosses as a 16-character hex string, never as a UV.
 *
 * On a perl with 32-bit IVs a UV cannot hold it and the top half would vanish
 * silently, which for a zobrist hash means a test that passes while comparing
 * half a number. Hand-rolled rather than via my_snprintf, which takes a length
 * argument that shadows a local called len in a way that has bitten the house
 * before. */
static SV *go_hex64(pTHX_ unsigned long long v)
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

MODULE = Game::Go    PACKAGE = Game::Go::Engine

PROTOTYPES: DISABLE

BOOT:
    GO = go_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(GO);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)GO->abi_version;
    OUTPUT:
        RETVAL

UV
_new_board(size)
        int size
    PREINIT:
        struct go_board *b;
    CODE:
        b = (GO->board_new)(size);
        if (!b) croak("Game::Go::Engine: no board of size %d", size);
        RETVAL = PTR2UV(b);
    OUTPUT:
        RETVAL

void
_drop_board(u)
        UV u
    CODE:
        (GO->board_drop)(BOARD(u));

UV
_copy_board(u)
        UV u
    PREINIT:
        struct go_board *b;
    CODE:
        b = (GO->board_copy)(BOARD(u));
        if (!b) croak("Game::Go::Engine: could not copy the board");
        RETVAL = PTR2UV(b);
    OUTPUT:
        RETVAL

int
_at(u, pt)
        UV u
        int pt
    CODE:
        RETVAL = (GO->at)(BOARD(u), pt);
    OUTPUT:
        RETVAL

int
_libs(u, pt)
        UV u
        int pt
    CODE:
        RETVAL = (GO->libs)(BOARD(u), pt);
    OUTPUT:
        RETVAL

int
_chain_size(u, pt)
        UV u
        int pt
    CODE:
        RETVAL = (GO->chain_size)(BOARD(u), pt);
    OUTPUT:
        RETVAL

void
_chain_at(u, pt)
        UV u
        int pt
    PREINIT:
        int pts[GO_MAX_PTS];
        int n, i;
    PPCODE:
        n = (GO->chain_at)(BOARD(u), pt, pts);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(pts[i])));

SV *
_pack(u)
        UV u
    PREINIT:
        unsigned char buf[GO_MAX_PTS];
        int n;
    CODE:
        n = (GO->pack)(BOARD(u), buf);
        RETVAL = newSVpvn((char *)buf, (STRLEN)n);
    OUTPUT:
        RETVAL

SV *
_hash_hex(u)
        UV u
    CODE:
        RETVAL = go_hex64(aTHX_ (GO->hash)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_zobrist_hex(colour, pt)
        int colour
        int pt
    CODE:
        RETVAL = go_hex64(aTHX_ (GO->zobrist)(colour, pt));
    OUTPUT:
        RETVAL

int
_stones(u, colour)
        UV u
        int colour
    CODE:
        RETVAL = (GO->stones)(BOARD(u), colour);
    OUTPUT:
        RETVAL

int
_point_of(u, col, row)
        UV u
        int col
        int row
    CODE:
        RETVAL = (GO->point_of)(BOARD(u), col, row);
    OUTPUT:
        RETVAL

int
_col_of(u, pt)
        UV u
        int pt
    CODE:
        RETVAL = (GO->col_of)(BOARD(u), pt);
    OUTPUT:
        RETVAL

int
_row_of(u, pt)
        UV u
        int pt
    CODE:
        RETVAL = (GO->row_of)(BOARD(u), pt);
    OUTPUT:
        RETVAL

int
_size_of(u)
        UV u
    CODE:
        RETVAL = (GO->size_of)(BOARD(u));
    OUTPUT:
        RETVAL

int
_stride_of(u)
        UV u
    CODE:
        RETVAL = (GO->stride_of)(BOARD(u));
    OUTPUT:
        RETVAL

void
_put(u, pt, colour)
        UV u
        int pt
        int colour
    CODE:
        (GO->put)(BOARD(u), pt, colour);

int
_lift(u, pt)
        UV u
        int pt
    CODE:
        RETVAL = (GO->lift)(BOARD(u), pt);
    OUTPUT:
        RETVAL

# ---------------------------------------------------------------------------
# PHASE 02: the rules of play.
#
# A history is a separate handle, because a board must stay pointer-free so a
# copy is a flat byte copy. A history UV of 0 means "no history", which the
# engine reads as simple ko and nothing else: that is the playout's rule and it
# is passed in rather than defaulted, so nobody inherits it by accident.
# ---------------------------------------------------------------------------

UV
_new_hist(size)
        int size
    PREINIT:
        struct go_hist *h;
    CODE:
        h = (GO->hist_new)(size);
        if (!h) croak("Game::Go::Engine: no history for size %d", size);
        RETVAL = PTR2UV(h);
    OUTPUT:
        RETVAL

void
_drop_hist(h)
        UV h
    CODE:
        (GO->hist_drop)(HIST(h));

UV
_copy_hist(h)
        UV h
    PREINIT:
        struct go_hist *n;
    CODE:
        n = (GO->hist_copy)(HIST(h));
        if (!n) croak("Game::Go::Engine: could not copy the history");
        RETVAL = PTR2UV(n);
    OUTPUT:
        RETVAL

int
_hist_len(h)
        UV h
    CODE:
        RETVAL = (GO->hist_len)(HIST(h));
    OUTPUT:
        RETVAL

void
_hist_clear(h)
        UV h
    CODE:
        (GO->hist_clear)(HIST(h));

int
_hist_push(h, u)
        UV h
        UV u
    CODE:
        RETVAL = (GO->hist_push)(HIST(h), BOARD(u));
    OUTPUT:
        RETVAL

int
_hist_has(h, u)
        UV h
        UV u
    CODE:
        RETVAL = (GO->hist_has)(HIST(h), BOARD(u));
    OUTPUT:
        RETVAL

int
_legal(u, h, pt, colour)
        UV u
        UV h
        int pt
        int colour
    CODE:
        RETVAL = (GO->legal)(BOARD(u), HIST(h), pt, colour);
    OUTPUT:
        RETVAL

void
_legal_moves(u, h, colour)
        UV u
        UV h
        int colour
    PREINIT:
        int pts[GO_MAX_PTS];
        int n, i;
    PPCODE:
        n = (GO->legal_moves)(BOARD(u), HIST(h), colour, pts);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(pts[i])));

# Returns (code, ko_point, @captured). The code comes first because it is the
# only part a caller may ignore at its peril, and the captures come last
# because there can be any number of them.
void
_play(u, h, pt, colour)
        UV u
        UV h
        int pt
        int colour
    PREINIT:
        struct go_played res;
        int i;
    PPCODE:
        (GO->play)(BOARD(u), HIST(h), pt, colour, &res);
        EXTEND(SP, 2 + res.ncaps);
        PUSHs(sv_2mortal(newSViv(res.code)));
        PUSHs(sv_2mortal(newSViv(res.ko_point)));
        for (i = 0; i < res.ncaps; i++)
            PUSHs(sv_2mortal(newSViv(res.caps[i])));

void
_pass(u, colour)
        UV u
        int colour
    CODE:
        (GO->pass)(BOARD(u), colour);

int
_ko_point(u)
        UV u
    CODE:
        RETVAL = (GO->ko_point)(BOARD(u));
    OUTPUT:
        RETVAL

int
_ko_colour(u)
        UV u
    CODE:
        RETVAL = (GO->ko_colour)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_superko(u, on)
        UV u
        int on
    CODE:
        (GO->set_superko)(BOARD(u), on);

int
_superko_on(u)
        UV u
    CODE:
        RETVAL = (GO->superko_on)(BOARD(u));
    OUTPUT:
        RETVAL

SV *
_hash_after_hex(u, pt, colour)
        UV u
        int pt
        int colour
    CODE:
        RETVAL = go_hex64(aTHX_ (GO->hash_after)(BOARD(u), pt, colour));
    OUTPUT:
        RETVAL

# ---------------------------------------------------------------------------
# PHASE 04: the only part of life and death that is decidable.
# ---------------------------------------------------------------------------

void
_alive(u, colour)
        UV u
        int colour
    PREINIT:
        int pts[GO_MAX_PTS];
        int n, i;
    PPCODE:
        n = (GO->alive)(BOARD(u), colour, pts);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(pts[i])));

# ---------------------------------------------------------------------------
# PHASE 05: the two scorers. Both fill one struct; the Perl picks what it wants.
# Scores come back in TENTHS, because komi is fractional and the engine has no
# floats at all.
# ---------------------------------------------------------------------------

void
_score(u, dead, seki, prisoners_b, prisoners_w, komi_tenths)
        UV u
        AV *dead
        AV *seki
        int prisoners_b
        int prisoners_w
        int komi_tenths
    PREINIT:
        struct go_score s;
        int dpts[GO_MAX_PTS];
        int spts[GO_MAX_PTS];
        int nd, ns, i;
    PPCODE:
        nd = (int)(av_len(dead) + 1);
        if (nd > GO_MAX_PTS) nd = GO_MAX_PTS;
        for (i = 0; i < nd; i++) {
            SV **e = av_fetch(dead, i, 0);
            dpts[i] = e ? (int)SvIV(*e) : -1;
        }
        ns = (int)(av_len(seki) + 1);
        if (ns > GO_MAX_PTS) ns = GO_MAX_PTS;
        for (i = 0; i < ns; i++) {
            SV **e = av_fetch(seki, i, 0);
            spts[i] = e ? (int)SvIV(*e) : -1;
        }

        (GO->score_jp)(BOARD(u), dpts, nd, spts, ns,
                       prisoners_b, prisoners_w, komi_tenths, &s);

        EXTEND(SP, 26);
        PUSHs(sv_2mortal(newSVpvs("eyes_b")));      PUSHs(sv_2mortal(newSViv(s.eyes_b)));
        PUSHs(sv_2mortal(newSVpvs("eyes_w")));      PUSHs(sv_2mortal(newSViv(s.eyes_w)));
        PUSHs(sv_2mortal(newSVpvs("territory_b"))); PUSHs(sv_2mortal(newSViv(s.territory_b)));
        PUSHs(sv_2mortal(newSVpvs("territory_w"))); PUSHs(sv_2mortal(newSViv(s.territory_w)));
        PUSHs(sv_2mortal(newSVpvs("dame")));        PUSHs(sv_2mortal(newSViv(s.dame)));
        PUSHs(sv_2mortal(newSVpvs("prisoners_b"))); PUSHs(sv_2mortal(newSViv(s.prisoners_b)));
        PUSHs(sv_2mortal(newSVpvs("prisoners_w"))); PUSHs(sv_2mortal(newSViv(s.prisoners_w)));
        PUSHs(sv_2mortal(newSVpvs("stones_b")));    PUSHs(sv_2mortal(newSViv(s.stones_b)));
        PUSHs(sv_2mortal(newSVpvs("stones_w")));    PUSHs(sv_2mortal(newSViv(s.stones_w)));
        PUSHs(sv_2mortal(newSVpvs("area_b")));      PUSHs(sv_2mortal(newSViv(s.area_b)));
        PUSHs(sv_2mortal(newSVpvs("area_w")));      PUSHs(sv_2mortal(newSViv(s.area_w)));
        PUSHs(sv_2mortal(newSVpvs("score_b")));     PUSHs(sv_2mortal(newSViv(s.score_b)));
        PUSHs(sv_2mortal(newSVpvs("score_w")));     PUSHs(sv_2mortal(newSViv(s.score_w)));

void
_score_area(u)
        UV u
    PREINIT:
        struct go_score s;
    PPCODE:
        (GO->score_area)(BOARD(u), &s);
        EXTEND(SP, 10);
        PUSHs(sv_2mortal(newSVpvs("area_b")));   PUSHs(sv_2mortal(newSViv(s.area_b)));
        PUSHs(sv_2mortal(newSVpvs("area_w")));   PUSHs(sv_2mortal(newSViv(s.area_w)));
        PUSHs(sv_2mortal(newSVpvs("dame")));     PUSHs(sv_2mortal(newSViv(s.dame)));
        PUSHs(sv_2mortal(newSVpvs("stones_b"))); PUSHs(sv_2mortal(newSViv(s.stones_b)));
        PUSHs(sv_2mortal(newSVpvs("stones_w"))); PUSHs(sv_2mortal(newSViv(s.stones_w)));

# Who owns each empty point, by the scorer's own classification. Returns a list
# of (point, colour) pairs for the points that belong to somebody.
void
_territory(u, dead, seki)
        UV u
        AV *dead
        AV *seki
    PREINIT:
        signed char owner[GO_MAX_PTS];
        int dpts[GO_MAX_PTS];
        int spts[GO_MAX_PTS];
        int nd, ns, i, n;
        struct go_board *b;
    PPCODE:
        b = BOARD(u);
        nd = (int)(av_len(dead) + 1);
        if (nd > GO_MAX_PTS) nd = GO_MAX_PTS;
        for (i = 0; i < nd; i++) {
            SV **e = av_fetch(dead, i, 0);
            dpts[i] = e ? (int)SvIV(*e) : -1;
        }
        ns = (int)(av_len(seki) + 1);
        if (ns > GO_MAX_PTS) ns = GO_MAX_PTS;
        for (i = 0; i < ns; i++) {
            SV **e = av_fetch(seki, i, 0);
            spts[i] = e ? (int)SvIV(*e) : -1;
        }

        (GO->territory)(b, dpts, nd, spts, ns, owner);

        n = (GO->size_of)(b);
        n = (n + 2) * (n + 2);
        for (i = 0; i < n; i++) {
            if (owner[i] != GO_BLACK && owner[i] != GO_WHITE) continue;
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(i)));
            PUSHs(sv_2mortal(newSViv(owner[i])));
        }

# ---------------------------------------------------------------------------
# PHASE 08: the search. Budget in PLAYOUTS, never in seconds.
# ---------------------------------------------------------------------------

UV
_prng_next(state)
        UV state
    PREINIT:
        unsigned int s;
    CODE:
        s = (unsigned int)state;
        (void)(GO->prng_next)(&s);
        RETVAL = (UV)s;
    OUTPUT:
        RETVAL

# Returns (score difference, moves played). THE MOVE COUNT IS THE OBSERVABLE
# THAT MATTERS: the playout runs on an internal copy, so the caller's board is
# untouched and there is nothing to inspect afterwards. Whether it SETTLED (two
# consecutive passes, few moves) or hit its cap (3 * size * size) is the only
# way to see the eye rule working from outside.
void
_playout(u, colour, seed)
        UV u
        int colour
        UV seed
    PREINIT:
        unsigned int s;
        int moves = 0;
        int diff;
    PPCODE:
        s = (unsigned int)seed;
        diff = (GO->playout)(BOARD(u), colour, &s, &moves);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(diff)));
        PUSHs(sv_2mortal(newSViv(moves)));

void
_search(u, colour, allowed, seed, playouts, explore)
        UV u
        int colour
        AV *allowed
        UV seed
        int playouts
        int explore
    PREINIT:
        struct go_search res;
        int pts[GO_MAX_PTS + 1];
        int n, i;
    PPCODE:
        n = (int)(av_len(allowed) + 1);
        if (n > GO_MAX_PTS) n = GO_MAX_PTS;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(allowed, i, 0);
            pts[i] = e ? (int)SvIV(*e) : -1;
        }

        (GO->search)(BOARD(u), colour, pts, n,
                     (unsigned int)seed, playouts, explore, &res);

        EXTEND(SP, 12);
        PUSHs(sv_2mortal(newSVpvs("point")));        PUSHs(sv_2mortal(newSViv(res.point)));
        PUSHs(sv_2mortal(newSVpvs("playouts")));     PUSHs(sv_2mortal(newSViv(res.playouts)));
        PUSHs(sv_2mortal(newSVpvs("visits")));       PUSHs(sv_2mortal(newSViv(res.visits)));
        PUSHs(sv_2mortal(newSVpvs("win_permille"))); PUSHs(sv_2mortal(newSViv(res.win_permille)));
        PUSHs(sv_2mortal(newSVpvs("capped")));       PUSHs(sv_2mortal(newSViv(res.capped)));
        PUSHs(sv_2mortal(newSVpvs("moves")));        PUSHs(sv_2mortal(newSViv(res.moves)));

void
_dead_guess(u, seed, playouts)
        UV u
        UV seed
        int playouts
    PREINIT:
        int pts[GO_MAX_PTS];
        int n, i;
    PPCODE:
        n = (GO->dead_guess)(BOARD(u), (unsigned int)seed, playouts, pts);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(pts[i])));
