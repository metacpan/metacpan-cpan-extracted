/* Sternhalma.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * siblings that learned this the hard way say so in Go.xs and Xiangqi.xs.
 *
 * The XSUBs land in Game::Sternhalma::Engine, not in Game::Sternhalma, and are
 * named with a leading underscore: they take a raw pointer as a UV and there is
 * no typemap. The Perl that owns the lifetime is lib/Game/Sternhalma/Engine.pm.
 *
 * `_put` and `_lift` are the structure primitives from sth_abi.h and CHECK
 * NOTHING.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sth_abi.h"

static const struct sth_abi *STH = NULL;

#define BOARD(u) INT2PTR(struct sth_board *, (u))

/* A 64-bit value crosses as a 16-character hex string, never as a UV.
 *
 * On a perl with 32-bit IVs a UV cannot hold it and the top half would vanish
 * silently, which for a zobrist key means a test that passes while comparing
 * half a number. Hand-rolled rather than via my_snprintf, as Fanorona.xs has it.
 */
static SV *sth_hex64(pTHX_ unsigned long long v)
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

MODULE = Game::Sternhalma    PACKAGE = Game::Sternhalma::Engine

PROTOTYPES: DISABLE

BOOT:
    STH = sth_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(STH);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)STH->abi_version;
    OUTPUT:
        RETVAL

int
_tables_ok()
    CODE:
        RETVAL = (STH->tables_ok)();
    OUTPUT:
        RETVAL

# A layout the engine does not build answers 0, which the Perl turns into a
# croak with the seats and pieces in it.
UV
_new_board(seats, pieces)
        int seats
        int pieces
    CODE:
        RETVAL = PTR2UV((STH->board_new)(seats, pieces));
    OUTPUT:
        RETVAL

UV
_new_empty(seats, pieces)
        int seats
        int pieces
    CODE:
        RETVAL = PTR2UV((STH->board_empty)(seats, pieces));
    OUTPUT:
        RETVAL

UV
_copy_board(u)
        UV u
    CODE:
        RETVAL = PTR2UV((STH->board_copy)(BOARD(u)));
    OUTPUT:
        RETVAL

# The board is let go by an object of its own, held by the board's object and
# freed with it. Its DESTROY is C and calls no perl.
SV *
_hold_board(u)
        UV u
    CODE:
        RETVAL = sv_setref_uv(newSV(0), "Game::Sternhalma::Engine::Hold", u);
    OUTPUT:
        RETVAL

int
_live()
    CODE:
        RETVAL = (STH->live)();
    OUTPUT:
        RETVAL

# A string that will not parse returns undef and the code, rather than
# croaking: the reason is what a caller shows a person, and eight of them are
# distinguishable.
void
_of_string(str)
        const char *str
    PREINIT:
        struct sth_board *b;
        int err = 0;
    PPCODE:
        b = (STH->board_of_string)(str, &err);
        EXTEND(SP, 2);
        if (b) PUSHs(sv_2mortal(newSVuv(PTR2UV(b))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(err)));

SV *
_to_string(u)
        UV u
    PREINIT:
        char buf[STH_POS_MAX];
        int n;
    CODE:
        n = (STH->to_string)(BOARD(u), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

int
_at(u, hole)
        UV u
        int hole
    CODE:
        RETVAL = (STH->at)(BOARD(u), hole);
    OUTPUT:
        RETVAL

void
_put(u, hole, seat)
        UV u
        int hole
        int seat
    CODE:
        (STH->put)(BOARD(u), hole, seat);

void
_lift(u, hole)
        UV u
        int hole
    CODE:
        (STH->lift)(BOARD(u), hole);

int
_to_move(u)
        UV u
    CODE:
        RETVAL = (STH->to_move)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_to_move(u, seat)
        UV u
        int seat
    CODE:
        (STH->set_to_move)(BOARD(u), seat);

int
_board_seats(u)
        UV u
    CODE:
        RETVAL = (STH->seats)(BOARD(u));
    OUTPUT:
        RETVAL

int
_board_pieces(u)
        UV u
    CODE:
        RETVAL = (STH->pieces)(BOARD(u));
    OUTPUT:
        RETVAL

int
_count(u, seat)
        UV u
        int seat
    CODE:
        RETVAL = (STH->count)(BOARD(u), seat);
    OUTPUT:
        RETVAL

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = sth_hex64(aTHX_ (STH->key)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_zobrist_hex(seat, hole)
        int seat
        int hole
    CODE:
        RETVAL = sth_hex64(aTHX_ (STH->zobrist)(seat, hole));
    OUTPUT:
        RETVAL

SV *
_zobrist_move_hex(seat)
        int seat
    CODE:
        RETVAL = sth_hex64(aTHX_ (STH->zobrist_move)(seat));
    OUTPUT:
        RETVAL

SV *
_zobrist_seats_hex(seats)
        int seats
    CODE:
        RETVAL = sth_hex64(aTHX_ (STH->zobrist_seats)(seats));
    OUTPUT:
        RETVAL

int
_layout_ok(seats, pieces)
        int seats
        int pieces
    CODE:
        RETVAL = (STH->layout_ok)(seats, pieces);
    OUTPUT:
        RETVAL

int
_layout_point(seats, seat)
        int seats
        int seat
    CODE:
        RETVAL = (STH->layout_point)(seats, seat);
    OUTPUT:
        RETVAL

int
_hole_of(x, y)
        int x
        int y
    CODE:
        RETVAL = (STH->hole_of)(x, y);
    OUTPUT:
        RETVAL

int
_hole_x(hole)
        int hole
    CODE:
        RETVAL = (STH->hole_x)(hole);
    OUTPUT:
        RETVAL

int
_hole_y(hole)
        int hole
    CODE:
        RETVAL = (STH->hole_y)(hole);
    OUTPUT:
        RETVAL

int
_row_of(hole)
        int hole
    CODE:
        RETVAL = (STH->row_of)(hole);
    OUTPUT:
        RETVAL

int
_col_of(hole)
        int hole
    CODE:
        RETVAL = (STH->col_of)(hole);
    OUTPUT:
        RETVAL

int
_row_len(row)
        int row
    CODE:
        RETVAL = (STH->row_len)(row);
    OUTPUT:
        RETVAL

int
_row_start(row)
        int row
    CODE:
        RETVAL = (STH->row_start)(row);
    OUTPUT:
        RETVAL

int
_next(hole, dir)
        int hole
        int dir
    CODE:
        RETVAL = (STH->next)(hole, dir);
    OUTPUT:
        RETVAL

int
_degree(hole)
        int hole
    CODE:
        RETVAL = (STH->degree)(hole);
    OUTPUT:
        RETVAL

int
_dir_opposite(dir)
        int dir
    CODE:
        RETVAL = (STH->dir_opposite)(dir);
    OUTPUT:
        RETVAL

int
_point_of(hole)
        int hole
    CODE:
        RETVAL = (STH->point_of)(hole);
    OUTPUT:
        RETVAL

int
_on_ring(hole)
        int hole
    CODE:
        RETVAL = (STH->on_ring)(hole);
    OUTPUT:
        RETVAL

int
_class_of(hole)
        int hole
    CODE:
        RETVAL = (STH->class_of)(hole);
    OUTPUT:
        RETVAL

void
_point_holes(point)
        int point
    PREINIT:
        int out[STH_POINT_HOLES];
        int n, i;
    PPCODE:
        n = (STH->point_holes)(point, out, STH_POINT_HOLES);
        if (n > STH_POINT_HOLES) n = STH_POINT_HOLES;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

void
_front(point)
        int point
    PREINIT:
        int out[STH_FRONT_HOLES];
        int n, i;
    PPCODE:
        n = (STH->front)(point, out, STH_FRONT_HOLES);
        if (n > STH_FRONT_HOLES) n = STH_FRONT_HOLES;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

void
_pairs()
    PREINIT:
        int out[2 * STH_PAIRS];
        int n, i;
    PPCODE:
        n = (STH->pairs)(out, 2 * STH_PAIRS);
        if (n > STH_PAIRS) n = STH_PAIRS;
        EXTEND(SP, 2 * n);
        for (i = 0; i < 2 * n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

# ---- version 2: one step and one hop ----------------------------------------------

void
_steps(u, hole)
        UV u
        int hole
    PREINIT:
        int out[STH_STEPS_MAX];
        int n, i;
    PPCODE:
        n = (STH->steps)(BOARD(u), hole, out, STH_STEPS_MAX);
        if (n > STH_STEPS_MAX) n = STH_STEPS_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

void
_hops(u, hole, from)
        UV u
        int hole
        int from
    PREINIT:
        int out[STH_HOPS_MAX];
        int n, i;
    PPCODE:
        n = (STH->hops)(BOARD(u), hole, from, out, STH_HOPS_MAX);
        if (n > STH_HOPS_MAX) n = STH_HOPS_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

int
_do_move(u, from, to)
        UV u
        int from
        int to
    CODE:
        RETVAL = (STH->do_move)(BOARD(u), from, to);
    OUTPUT:
        RETVAL

int
_undo_move(u, from, to)
        UV u
        int from
        int to
    CODE:
        RETVAL = (STH->undo_move)(BOARD(u), from, to);
    OUTPUT:
        RETVAL

# ---- version 3: a move -------------------------------------------------------------

void
_reach(u, from)
        UV u
        int from
    PREINIT:
        int out[STH_REACH_MAX];
        int n, i;
    PPCODE:
        n = (STH->reach)(BOARD(u), from, out, STH_REACH_MAX);
        if (n > STH_REACH_MAX) n = STH_REACH_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

void
_path(u, from, to)
        UV u
        int from
        int to
    PREINIT:
        int out[STH_PATH_MAX];
        int n, i;
    PPCODE:
        n = (STH->path)(BOARD(u), from, to, out, STH_PATH_MAX);
        if (n > STH_PATH_MAX) n = STH_PATH_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSViv(out[i])));

# Flat: from, to, from, to. The Perl pairs them.
void
_legal(u)
        UV u
    PREINIT:
        int from[STH_LEGAL_MAX], to[STH_LEGAL_MAX];
        int n, i;
    PPCODE:
        n = (STH->legal)(BOARD(u), from, to, STH_LEGAL_MAX);
        if (n > STH_LEGAL_MAX) n = STH_LEGAL_MAX;
        EXTEND(SP, 2 * n);
        for (i = 0; i < n; i++) {
            PUSHs(sv_2mortal(newSViv(from[i])));
            PUSHs(sv_2mortal(newSViv(to[i])));
        }

# ---- version 4: a game --------------------------------------------------------------
#
# play, pass and resign answer the code and, when it is STH_PLAY_OK, the undo
# as a string of the struct's bytes, which _unplay takes back.

int
_home_complete(u, seat)
        UV u
        int seat
    CODE:
        RETVAL = (STH->home_complete)(BOARD(u), seat);
    OUTPUT:
        RETVAL

int
_finished(u, seat)
        UV u
        int seat
    CODE:
        RETVAL = (STH->finished)(BOARD(u), seat);
    OUTPUT:
        RETVAL

int
_place_of(u, seat)
        UV u
        int seat
    CODE:
        RETVAL = (STH->place_of)(BOARD(u), seat);
    OUTPUT:
        RETVAL

int
_distance_left(u, seat)
        UV u
        int seat
    CODE:
        RETVAL = (STH->distance_left)(BOARD(u), seat);
    OUTPUT:
        RETVAL

int
_can_pass(u)
        UV u
    CODE:
        RETVAL = (STH->can_pass)(BOARD(u));
    OUTPUT:
        RETVAL

void
_play(u, from, to)
        UV u
        int from
        int to
    PREINIT:
        struct sth_undo undo;
        int why;
    PPCODE:
        why = (STH->play)(BOARD(u), from, to, &undo);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(why)));
        if (why == STH_PLAY_OK) PUSHs(sv_2mortal(newSVpvn((const char *)&undo, sizeof(undo))));

void
_pass(u)
        UV u
    PREINIT:
        struct sth_undo undo;
        int why;
    PPCODE:
        why = (STH->pass)(BOARD(u), &undo);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(why)));
        if (why == STH_PLAY_OK) PUSHs(sv_2mortal(newSVpvn((const char *)&undo, sizeof(undo))));

void
_resign(u, seat)
        UV u
        int seat
    PREINIT:
        struct sth_undo undo;
        int why;
    PPCODE:
        why = (STH->resign)(BOARD(u), seat, &undo);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(why)));
        if (why == STH_PLAY_OK) PUSHs(sv_2mortal(newSVpvn((const char *)&undo, sizeof(undo))));

int
_unplay(u, token)
        UV u
        SV *token
    PREINIT:
        STRLEN len;
        const char *bytes;
        struct sth_undo undo;
    CODE:
        bytes = SvPV(token, len);
        if (len != sizeof(undo))
            croak("Game::Sternhalma::Engine: that is not an undo token");
        Copy(bytes, &undo, 1, struct sth_undo);
        RETVAL = (STH->unplay)(BOARD(u), &undo);
    OUTPUT:
        RETVAL

int
_game_over(u)
        UV u
    CODE:
        RETVAL = (STH->game_over)(BOARD(u));
    OUTPUT:
        RETVAL

int
_game_how(u)
        UV u
    CODE:
        RETVAL = (STH->game_how)(BOARD(u));
    OUTPUT:
        RETVAL

int
_ply(u)
        UV u
    CODE:
        RETVAL = (STH->ply)(BOARD(u));
    OUTPUT:
        RETVAL

int
_cap(u)
        UV u
    CODE:
        RETVAL = (STH->cap)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_cap(u, cap)
        UV u
        int cap
    CODE:
        (STH->set_cap)(BOARD(u), cap);

# ---- version 6: choosing a move ------------------------------------------------------
#
# The weights cross as four ints, distance, straggler, classes, blocking. The
# node count crosses as a decimal string, as a key crosses as hex: a budget can
# outgrow a 32-bit IV.

void
_weights_default()
    PREINIT:
        struct sth_weights w;
    PPCODE:
        (STH->weights_default)(&w);
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(w.distance)));
        PUSHs(sv_2mortal(newSViv(w.straggler)));
        PUSHs(sv_2mortal(newSViv(w.classes)));
        PUSHs(sv_2mortal(newSViv(w.blocking)));

int
_evaluate(u, seat, distance, straggler, classes, blocking)
        UV u
        int seat
        int distance
        int straggler
        int classes
        int blocking
    PREINIT:
        struct sth_weights w;
    CODE:
        (STH->weights_default)(&w);
        w.distance = distance; w.straggler = straggler; w.classes = classes; w.blocking = blocking;
        RETVAL = (STH->evaluate)(BOARD(u), seat, &w);
    OUTPUT:
        RETVAL

# `avoid` is an array reference of keys as sixteen hex digits, the positions
# the game has already had.
void
_search(u, budget, seed, max_depth, mode, distance, straggler, classes, blocking, avoid)
        UV u
        UV budget
        UV seed
        int max_depth
        int mode
        int distance
        int straggler
        int classes
        int blocking
        SV *avoid
    PREINIT:
        struct sth_weights w;
        struct sth_search_info info;
        int from = -1, to = -1, ok, n = 0, i;
        unsigned long long *keys = NULL;
        char buf[24];
    PPCODE:
        (STH->weights_default)(&w);
        w.distance = distance; w.straggler = straggler; w.classes = classes; w.blocking = blocking;
        if (SvROK(avoid) && SvTYPE(SvRV(avoid)) == SVt_PVAV) {
            AV *av = (AV *) SvRV(avoid);
            int len = (int) (av_len(av) + 1);
            if (len > 0) {
                Newx(keys, len, unsigned long long);
                for (i = 0; i < len; i++) {
                    SV **e = av_fetch(av, i, 0);
                    if (e && SvOK(*e)) keys[n++] = strtoull(SvPV_nolen(*e), NULL, 16);
                }
            }
        }
        ok = (STH->search)(BOARD(u), &w, (unsigned long long)budget, (unsigned long long)seed,
                           max_depth, mode, keys, n, &from, &to, &info);
        Safefree(keys);
        if (!ok) XSRETURN_EMPTY;
        my_snprintf(buf, sizeof buf, "%llu", info.nodes);
        EXTEND(SP, 6);
        PUSHs(sv_2mortal(newSViv(from)));
        PUSHs(sv_2mortal(newSViv(to)));
        PUSHs(sv_2mortal(newSVpv(buf, 0)));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.score)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));

void
_random_forward(u, seed)
        UV u
        UV seed
    PREINIT:
        int from = -1, to = -1;
    PPCODE:
        if (!(STH->random_forward)(BOARD(u), (unsigned long long)seed, &from, &to)) XSRETURN_EMPTY;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(from)));
        PUSHs(sv_2mortal(newSViv(to)));

SV *
_own_key_hex(u, seat)
        UV u
        int seat
    CODE:
        RETVAL = sth_hex64(aTHX_ (STH->own_key)(BOARD(u), seat));
    OUTPUT:
        RETVAL

MODULE = Game::Sternhalma    PACKAGE = Game::Sternhalma::Engine::Hold

PROTOTYPES: DISABLE

# ---- letting go -----------------------------------------------------------------
#
# WHY THIS IS NOT A DEMOLISH IN PERL. Fanorona's was, through eight phases. On
# perls 5.14 to 5.26 an eval that runs inside a destructor, while an exception
# is unwinding past a TEMPORARY of that class, leaves $@ empty: the caller's die
# arrives with no message. Object::Proto calls DEMOLISH under an eval, so any
# class with one has this. A DESTROY written in C runs no eval.

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
                (STH->board_drop)(BOARD(u));
            }
        }
