/* Fanorona.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * siblings that learned this the hard way say so in Go.xs and Xiangqi.xs.
 *
 * The XSUBs land in Game::Fanorona::Engine, not in Game::Fanorona, and are named
 * with a leading underscore: they take a raw pointer as a UV and there is no
 * typemap. The Perl that owns the lifetime is lib/Game/Fanorona/Engine.pm.
 *
 * `_put` and `_lift` are the structure primitives from fn_abi.h and CHECK
 * NOTHING.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "fn_abi.h"

static const struct fn_abi *FN = NULL;

#define BOARD(u) INT2PTR(struct fn_board *, (u))

/* A 64-bit value crosses as a 16-character hex string, never as a UV.
 *
 * On a perl with 32-bit IVs a UV cannot hold it and the top half would vanish
 * silently, which for a zobrist key means a test that passes while comparing
 * half a number. Hand-rolled rather than via my_snprintf, as Brandubh.xs has it.
 */
static SV *fn_hex64(pTHX_ unsigned long long v)
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

MODULE = Game::Fanorona    PACKAGE = Game::Fanorona::Engine

PROTOTYPES: DISABLE

BOOT:
    FN = fn_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(FN);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)FN->abi_version;
    OUTPUT:
        RETVAL

# A size the engine does not build answers 0, which the Perl turns into a
# croak with the size in it.
UV
_new_board(cols, rows)
        int cols
        int rows
    CODE:
        RETVAL = PTR2UV((FN->board_new)(cols, rows));
    OUTPUT:
        RETVAL

UV
_new_empty(cols, rows)
        int cols
        int rows
    CODE:
        RETVAL = PTR2UV((FN->board_empty)(cols, rows));
    OUTPUT:
        RETVAL

UV
_copy_board(u)
        UV u
    CODE:
        RETVAL = PTR2UV((FN->board_copy)(BOARD(u)));
    OUTPUT:
        RETVAL

# The board is let go by an object of its own, held by the board's object and
# freed with it. Its DESTROY is C and calls no perl.
SV *
_hold_board(u)
        UV u
    CODE:
        RETVAL = sv_setref_uv(newSV(0), "Game::Fanorona::Engine::Hold", u);
    OUTPUT:
        RETVAL

int
_live()
    CODE:
        RETVAL = (FN->live)();
    OUTPUT:
        RETVAL

# A string that will not parse returns undef and the code, rather than
# croaking: the reason is what a caller shows a person, and six of them are
# distinguishable.
void
_of_string(str)
        const char *str
    PREINIT:
        struct fn_board *b;
        int err = 0;
    PPCODE:
        b = (FN->board_of_string)(str, &err);
        EXTEND(SP, 2);
        if (b) PUSHs(sv_2mortal(newSVuv(PTR2UV(b))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(err)));

SV *
_to_string(u)
        UV u
    PREINIT:
        char buf[FN_POS_MAX];
        int n;
    CODE:
        n = (FN->to_string)(BOARD(u), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

int
_at(u, sq)
        UV u
        int sq
    CODE:
        RETVAL = (FN->at)(BOARD(u), sq);
    OUTPUT:
        RETVAL

void
_put(u, sq, stone)
        UV u
        int sq
        int stone
    CODE:
        (FN->put)(BOARD(u), sq, stone);

void
_lift(u, sq)
        UV u
        int sq
    CODE:
        (FN->lift)(BOARD(u), sq);

int
_side(u)
        UV u
    CODE:
        RETVAL = (FN->side)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_side(u, side)
        UV u
        int side
    CODE:
        (FN->set_side)(BOARD(u), side);

int
_count(u, stone)
        UV u
        int stone
    CODE:
        RETVAL = (FN->count)(BOARD(u), stone);
    OUTPUT:
        RETVAL

int
_board_cols(u)
        UV u
    CODE:
        RETVAL = (FN->cols)(BOARD(u));
    OUTPUT:
        RETVAL

int
_board_rows(u)
        UV u
    CODE:
        RETVAL = (FN->rows)(BOARD(u));
    OUTPUT:
        RETVAL

int
_board_points(u)
        UV u
    CODE:
        RETVAL = (FN->points)(BOARD(u));
    OUTPUT:
        RETVAL

int
_board_centre(u)
        UV u
    CODE:
        RETVAL = (FN->centre)(BOARD(u));
    OUTPUT:
        RETVAL

int
_on_board(u, sq)
        UV u
        int sq
    CODE:
        RETVAL = (FN->on_board)(BOARD(u), sq);
    OUTPUT:
        RETVAL

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = fn_hex64(aTHX_ (FN->key)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_key_full_hex(u)
        UV u
    CODE:
        RETVAL = fn_hex64(aTHX_ (FN->key_full)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_zobrist_hex(stone, sq)
        int stone
        int sq
    CODE:
        RETVAL = fn_hex64(aTHX_ (FN->zobrist)(stone, sq));
    OUTPUT:
        RETVAL

SV *
_zobrist_side_hex()
    CODE:
        RETVAL = fn_hex64(aTHX_ (FN->zobrist_side)());
    OUTPUT:
        RETVAL

SV *
_zobrist_size_hex(cols, rows)
        int cols
        int rows
    CODE:
        RETVAL = fn_hex64(aTHX_ (FN->zobrist_size)(cols, rows));
    OUTPUT:
        RETVAL

int
_size_ok(cols, rows)
        int cols
        int rows
    CODE:
        RETVAL = (FN->size_ok)(cols, rows);
    OUTPUT:
        RETVAL

int
_stride()
    CODE:
        RETVAL = (FN->stride)();
    OUTPUT:
        RETVAL

int
_square_of(file, rank)
        int file
        int rank
    CODE:
        RETVAL = (FN->square_of)(file, rank);
    OUTPUT:
        RETVAL

int
_file_of(sq)
        int sq
    CODE:
        RETVAL = (FN->file_of)(sq);
    OUTPUT:
        RETVAL

int
_rank_of(sq)
        int sq
    CODE:
        RETVAL = (FN->rank_of)(sq);
    OUTPUT:
        RETVAL

int
_is_strong(sq)
        int sq
    CODE:
        RETVAL = (FN->is_strong)(sq);
    OUTPUT:
        RETVAL

int
_dir_opposite(dir)
        int dir
    CODE:
        RETVAL = (FN->dir_opposite)(dir);
    OUTPUT:
        RETVAL

int
_dir_is_diagonal(dir)
        int dir
    CODE:
        RETVAL = (FN->dir_is_diagonal)(dir);
    OUTPUT:
        RETVAL

int
_next(u, sq, dir)
        UV u
        int sq
        int dir
    CODE:
        RETVAL = (FN->next)(BOARD(u), sq, dir);
    OUTPUT:
        RETVAL

int
_degree(u, sq)
        UV u
        int sq
    CODE:
        RETVAL = (FN->degree)(BOARD(u), sq);
    OUTPUT:
        RETVAL

# The joined pairs as a flat list, two points a segment.
void
_segments(u)
        UV u
    PREINIT:
        int out[2 * FN_SEGMENTS_MAX];
        int n, i;
    PPCODE:
        n = (FN->segments)(BOARD(u), out, FN_SEGMENTS_MAX);
        if (n > FN_SEGMENTS_MAX) n = FN_SEGMENTS_MAX;
        EXTEND(SP, 2 * n);
        for (i = 0; i < 2 * n; i++)
            PUSHs(sv_2mortal(newSViv(out[i])));

# ---- version 2: one stone, one step ------------------------------------------
#
# A step crosses as an array reference: [ from, to, dir, kind, taken... ].

void
_gen_steps(u)
        UV u
    PREINIT:
        struct fn_step list[FN_STEPS_MAX];
        int n, i, j;
    PPCODE:
        n = (FN->gen_steps)(BOARD(u), list, FN_STEPS_MAX);
        if (n > FN_STEPS_MAX)
            croak("Game::Fanorona::Engine: %d steps, more than the %d a board can have", n, FN_STEPS_MAX);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *av = newAV();
            av_extend(av, 3 + list[i].taken_n);
            av_push(av, newSViv(list[i].from));
            av_push(av, newSViv(list[i].to));
            av_push(av, newSViv(list[i].dir));
            av_push(av, newSViv(list[i].kind));
            for (j = 0; j < list[i].taken_n; j++)
                av_push(av, newSViv(list[i].taken[j]));
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
        }

void
_steps_of(u, sq)
        UV u
        int sq
    PREINIT:
        struct fn_step list[16];
        int n, i, j;
    PPCODE:
        n = (FN->steps_of)(BOARD(u), sq, list, 16);
        if (n > 16) n = 16;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *av = newAV();
            av_extend(av, 3 + list[i].taken_n);
            av_push(av, newSViv(list[i].from));
            av_push(av, newSViv(list[i].to));
            av_push(av, newSViv(list[i].dir));
            av_push(av, newSViv(list[i].kind));
            for (j = 0; j < list[i].taken_n; j++)
                av_push(av, newSViv(list[i].taken[j]));
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
        }

int
_can_capture(u, side)
        UV u
        int side
    CODE:
        RETVAL = (FN->can_capture)(BOARD(u), side);
    OUTPUT:
        RETVAL

int
_step_why(u, from, dir, kind)
        UV u
        int from
        int dir
        int kind
    CODE:
        RETVAL = (FN->step_why)(BOARD(u), from, dir, kind, NULL);
    OUTPUT:
        RETVAL

# The step as an array reference, or nothing when there is no such step to
# build.
void
_step_build(u, from, dir, kind)
        UV u
        int from
        int dir
        int kind
    PREINIT:
        struct fn_step s;
        int j;
    PPCODE:
        if ((FN->step_build)(BOARD(u), from, dir, kind, &s)) {
            AV *av = newAV();
            av_extend(av, 3 + s.taken_n);
            av_push(av, newSViv(s.from));
            av_push(av, newSViv(s.to));
            av_push(av, newSViv(s.dir));
            av_push(av, newSViv(s.kind));
            for (j = 0; j < s.taken_n; j++)
                av_push(av, newSViv(s.taken[j]));
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
        }

# (removed, token), or nothing when the step could not be made. The token is
# the undo record's own bytes: opaque to Perl, and checked for length on the
# way back.
void
_do_step(u, from, dir, kind)
        UV u
        int from
        int dir
        int kind
    PREINIT:
        struct fn_step s;
        struct fn_undo undo;
        int removed;
    PPCODE:
        if (!(FN->step_build)(BOARD(u), from, dir, kind, &s))
            XSRETURN_EMPTY;
        removed = (FN->do_step)(BOARD(u), &s, &undo);
        if (removed < 0)
            XSRETURN_EMPTY;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(removed)));
        PUSHs(sv_2mortal(newSVpvn((const char *)&undo, sizeof(undo))));

void
_undo_step(u, token)
        UV u
        SV *token
    PREINIT:
        STRLEN len;
        const char *bytes;
        struct fn_undo undo;
    CODE:
        bytes = SvPV(token, len);
        if (len != sizeof(undo))
            croak("Game::Fanorona::Engine: that is not an undo token");
        Copy(bytes, &undo, 1, struct fn_undo);
        (FN->undo_step)(BOARD(u), &undo);

# A count crosses as a decimal STRING, for the reason a key crosses as hex: a
# perft total outgrows a 32-bit IV within a few plies.
SV *
_perft_steps(u, depth)
        UV u
        int depth
    PREINIT:
        unsigned long long v;
        char buf[24];
        int i;
    CODE:
        v = (FN->perft_steps)(BOARD(u), depth);
        i = (int) sizeof(buf);
        do {
            buf[--i] = (char) ('0' + (int) (v % 10ULL));
            v /= 10ULL;
        } while (v);
        RETVAL = newSVpvn(buf + i, (STRLEN) (sizeof(buf) - i));
    OUTPUT:
        RETVAL

int
_steps_max()
    CODE:
        RETVAL = FN_STEPS_MAX;
    OUTPUT:
        RETVAL

int
_line_max()
    CODE:
        RETVAL = FN_LINE_MAX;
    OUTPUT:
        RETVAL

# ---- version 3: the chain, and the whole move ---------------------------------

int
_chain_at(u)
        UV u
    CODE:
        RETVAL = (FN->chain_at)(BOARD(u));
    OUTPUT:
        RETVAL

int
_chain_dir(u)
        UV u
    CODE:
        RETVAL = (FN->chain_dir)(BOARD(u));
    OUTPUT:
        RETVAL

int
_chain_seen(u, sq)
        UV u
        int sq
    CODE:
        RETVAL = (FN->chain_seen)(BOARD(u), sq);
    OUTPUT:
        RETVAL

int
_point_bit(sq)
        int sq
    CODE:
        RETVAL = (FN->point_bit)(sq);
    OUTPUT:
        RETVAL

void
_play_steps(u)
        UV u
    PREINIT:
        struct fn_step list[FN_STEPS_MAX];
        int n, i, j;
    PPCODE:
        n = (FN->play_steps)(BOARD(u), list, FN_STEPS_MAX);
        if (n > FN_STEPS_MAX)
            croak("Game::Fanorona::Engine: %d steps, more than the %d a board can have", n, FN_STEPS_MAX);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *av = newAV();
            av_extend(av, 3 + list[i].taken_n);
            av_push(av, newSViv(list[i].from));
            av_push(av, newSViv(list[i].to));
            av_push(av, newSViv(list[i].dir));
            av_push(av, newSViv(list[i].kind));
            for (j = 0; j < list[i].taken_n; j++)
                av_push(av, newSViv(list[i].taken[j]));
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
        }

int
_can_stop(u)
        UV u
    CODE:
        RETVAL = (FN->can_stop)(BOARD(u));
    OUTPUT:
        RETVAL

int
_play_why(u, from, dir, kind)
        UV u
        int from
        int dir
        int kind
    CODE:
        RETVAL = (FN->play_why)(BOARD(u), from, dir, kind, NULL);
    OUTPUT:
        RETVAL

# (removed, token), or nothing, as _do_step.
void
_play_step(u, from, dir, kind)
        UV u
        int from
        int dir
        int kind
    PREINIT:
        struct fn_step s;
        struct fn_undo undo;
        int removed;
    PPCODE:
        if (!(FN->step_build)(BOARD(u), from, dir, kind, &s))
            XSRETURN_EMPTY;
        removed = (FN->play_step)(BOARD(u), &s, &undo);
        if (removed < 0)
            XSRETURN_EMPTY;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(removed)));
        PUSHs(sv_2mortal(newSVpvn((const char *)&undo, sizeof(undo))));

# The token, or nothing when no chain was open.
void
_play_stop(u)
        UV u
    PREINIT:
        struct fn_undo undo;
    PPCODE:
        if (!(FN->play_stop)(BOARD(u), &undo))
            XSRETURN_EMPTY;
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpvn((const char *)&undo, sizeof(undo))));

void
_play_undo(u, token)
        UV u
        SV *token
    PREINIT:
        STRLEN len;
        const char *bytes;
        struct fn_undo undo;
    CODE:
        bytes = SvPV(token, len);
        if (len != sizeof(undo))
            croak("Game::Fanorona::Engine: that is not an undo token");
        Copy(bytes, &undo, 1, struct fn_undo);
        (FN->play_undo)(BOARD(u), &undo);

SV *
_count_moves(u, cap)
        UV u
        UV cap
    PREINIT:
        unsigned long long v;
        char buf[24];
        int i;
    CODE:
        v = (FN->count_moves)(BOARD(u), (unsigned long long) cap);
        i = (int) sizeof(buf);
        do {
            buf[--i] = (char) ('0' + (int) (v % 10ULL));
            v /= 10ULL;
        } while (v);
        RETVAL = newSVpvn(buf + i, (STRLEN) (sizeof(buf) - i));
    OUTPUT:
        RETVAL

# Each move as an array reference of its steps, each step an array reference
# as _gen_steps gives it. The list is counted first, no further than one past
# `limit`, and the buffer sized to it; a position with more moves than `limit`
# croaks and writes nothing.
void
_gen_moves(u, limit)
        UV u
        int limit
    PREINIT:
        struct fn_move *list;
        struct fn_step steps[FN_CHAIN_MAX];
        int n, i, j, k, m;
    PPCODE:
        if (limit < 0) limit = 0;
        n = (int) (FN->count_moves)(BOARD(u), (unsigned long long) limit + 1ULL);
        if (n > limit)
            croak("Game::Fanorona::Engine: more than %d whole moves", limit);
        if (n == 0)
            XSRETURN_EMPTY;
        Newx(list, n, struct fn_move);
        SAVEFREEPV(list);
        (FN->gen_moves)(BOARD(u), list, n);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *mv = newAV();
            m = (FN->move_steps)(BOARD(u), &list[i], steps);
            for (k = 0; k < m; k++) {
                AV *av = newAV();
                av_extend(av, 3 + steps[k].taken_n);
                av_push(av, newSViv(steps[k].from));
                av_push(av, newSViv(steps[k].to));
                av_push(av, newSViv(steps[k].dir));
                av_push(av, newSViv(steps[k].kind));
                for (j = 0; j < steps[k].taken_n; j++)
                    av_push(av, newSViv(steps[k].taken[j]));
                av_push(mv, newRV_noinc((SV *) av));
            }
            PUSHs(sv_2mortal(newRV_noinc((SV *) mv)));
        }

SV *
_perft_moves(u, depth)
        UV u
        int depth
    PREINIT:
        unsigned long long v;
        char buf[24];
        int i;
    CODE:
        v = (FN->perft_moves)(BOARD(u), depth);
        i = (int) sizeof(buf);
        do {
            buf[--i] = (char) ('0' + (int) (v % 10ULL));
            v /= 10ULL;
        } while (v);
        RETVAL = newSVpvn(buf + i, (STRLEN) (sizeof(buf) - i));
    OUTPUT:
        RETVAL

int
_chain_max()
    CODE:
        RETVAL = FN_CHAIN_MAX;
    OUTPUT:
        RETVAL

MODULE = Game::Fanorona    PACKAGE = Game::Fanorona::Rules

PROTOTYPES: DISABLE

# ---- version 4: a game -----------------------------------------------------------
#
# A game crosses as a raw pointer in a UV, as a board does. Each limit is an
# int, and a negative one means the default.

UV
_new_game(position, quiet, repeat, cap)
        const char *position
        int quiet
        int repeat
        int cap
    PREINIT:
        struct fn_board *b;
        struct fn_variant v;
        int err = 0;
    CODE:
        (FN->variant_default)(&v);
        v.quiet_limit = quiet;
        v.repeat = repeat;
        if (cap > 0) v.ply_cap = cap;
        b = (FN->board_of_string)(position, &err);
        if (!b) XSRETURN_UNDEF;
        RETVAL = PTR2UV((FN->game_new)(b, &v));
        (FN->board_drop)(b);
    OUTPUT:
        RETVAL

UV
_copy_game(g)
        UV g
    CODE:
        RETVAL = PTR2UV((FN->game_copy)(INT2PTR(struct fn_game *, g)));
    OUTPUT:
        RETVAL

SV *
_hold_game(g)
        UV g
    CODE:
        RETVAL = sv_setref_uv(newSV(0), "Game::Fanorona::Rules::Hold", g);
    OUTPUT:
        RETVAL

int
_games_live()
    CODE:
        RETVAL = (FN->games_live)();
    OUTPUT:
        RETVAL

# The game's own board, BORROWED: an address to read through and nothing else.
UV
_game_board(g)
        UV g
    CODE:
        RETVAL = PTR2UV((FN->game_board)(INT2PTR(struct fn_game *, g)));
    OUTPUT:
        RETVAL

void
_game_variant(g)
        UV g
    PREINIT:
        struct fn_variant v;
    PPCODE:
        (FN->game_variant)(INT2PTR(struct fn_game *, g), &v);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(v.quiet_limit)));
        PUSHs(sv_2mortal(newSViv(v.repeat)));
        PUSHs(sv_2mortal(newSViv(v.ply_cap)));

int
_game_ply(g)
        UV g
    CODE:
        RETVAL = (FN->game_ply)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

int
_game_quiet(g)
        UV g
    CODE:
        RETVAL = (FN->game_quiet)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

int
_game_depth(g)
        UV g
    CODE:
        RETVAL = (FN->game_depth)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

int
_game_outcome(g)
        UV g
    CODE:
        RETVAL = (FN->game_outcome)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

int
_game_winner(g)
        UV g
    CODE:
        RETVAL = (FN->game_winner)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

SV *
_game_key_hex(g, ply)
        UV g
        int ply
    CODE:
        RETVAL = fn_hex64(aTHX_ (FN->game_key_at)(INT2PTR(struct fn_game *, g), ply));
    OUTPUT:
        RETVAL

int
_game_repeats(g)
        UV g
    CODE:
        RETVAL = (FN->repeats)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

void
_game_steps(g)
        UV g
    PREINIT:
        struct fn_step list[FN_STEPS_MAX];
        int n, i, j;
    PPCODE:
        n = (FN->game_steps)(INT2PTR(struct fn_game *, g), list, FN_STEPS_MAX);
        if (n > FN_STEPS_MAX) n = FN_STEPS_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *av = newAV();
            av_extend(av, 3 + list[i].taken_n);
            av_push(av, newSViv(list[i].from));
            av_push(av, newSViv(list[i].to));
            av_push(av, newSViv(list[i].dir));
            av_push(av, newSViv(list[i].kind));
            for (j = 0; j < list[i].taken_n; j++)
                av_push(av, newSViv(list[i].taken[j]));
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
        }

int
_game_can_stop(g)
        UV g
    CODE:
        RETVAL = (FN->game_can_stop)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

# (answer, why): FN_PLAY_OK and the rest, and the reason when it is illegal.
void
_game_step(g, from, dir, kind)
        UV g
        int from
        int dir
        int kind
    PREINIT:
        int answer, why = 0;
    PPCODE:
        answer = (FN->game_step)(INT2PTR(struct fn_game *, g), from, dir, kind, &why);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(answer)));
        PUSHs(sv_2mortal(newSViv(why)));

int
_game_stop(g)
        UV g
    CODE:
        RETVAL = (FN->game_stop)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

int
_game_undo(g)
        UV g
    CODE:
        RETVAL = (FN->game_undo)(INT2PTR(struct fn_game *, g));
    OUTPUT:
        RETVAL

# ---- version 5: choosing a move ------------------------------------------------
#
# The four weights of the evaluation, in the order the struct has them.
void
_weights_default()
    PREINIT:
        struct fn_weights w;
    PPCODE:
        (FN->weights_default)(&w);
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(w.stone)));
        PUSHs(sv_2mortal(newSViv(w.strong)));
        PUSHs(sv_2mortal(newSViv(w.centre)));
        PUSHs(sv_2mortal(newSViv(w.room)));

# The game's board scored for White.
int
_game_evaluate(g, stone, strong, centre, room)
        UV g
        int stone
        int strong
        int centre
        int room
    PREINIT:
        struct fn_weights w;
    CODE:
        (FN->weights_default)(&w);
        w.stone = stone; w.strong = strong; w.centre = centre; w.room = room;
        RETVAL = (FN->evaluate)((FN->game_board)(INT2PTR(struct fn_game *, g)), &w);
    OUTPUT:
        RETVAL

# (found, nodes, depth, score, stopped, from, dir, kind, dir, kind, ...). The
# count of positions crosses as a string, for the reason a perft total does.
# The seed is a UV and so at most 32 bits on some perls, which is all the
# seed is for: it settles ties.
void
_game_search(g, budget, seed, max_depth, stone, strong, centre, room)
        UV g
        UV budget
        UV seed
        int max_depth
        int stone
        int strong
        int centre
        int room
    PREINIT:
        struct fn_weights w;
        struct fn_move best;
        struct fn_search_info info;
        unsigned long long v;
        char buf[24];
        int found, i, k;
    PPCODE:
        (FN->weights_default)(&w);
        w.stone = stone; w.strong = strong; w.centre = centre; w.room = room;
        found = (FN->search)(INT2PTR(struct fn_game *, g), &w, (unsigned long long) budget,
                             (unsigned long long) seed, max_depth, &best, &info);
        v = info.nodes;
        i = (int) sizeof(buf);
        do {
            buf[--i] = (char) ('0' + (int) (v % 10ULL));
            v /= 10ULL;
        } while (v);
        EXTEND(SP, 6 + 2 * best.n);
        PUSHs(sv_2mortal(newSViv(found)));
        PUSHs(sv_2mortal(newSVpvn(buf + i, (STRLEN) (sizeof(buf) - i))));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.score)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));
        PUSHs(sv_2mortal(newSViv(best.from)));
        for (k = 0; k < best.n; k++) {
            PUSHs(sv_2mortal(newSViv(best.dir[k])));
            PUSHs(sv_2mortal(newSViv(best.kind[k])));
        }

int
_win_score()
    CODE:
        RETVAL = FN_WIN_SCORE;
    OUTPUT:
        RETVAL

MODULE = Game::Fanorona    PACKAGE = Game::Fanorona::Engine::Hold

PROTOTYPES: DISABLE

# ---- letting go -----------------------------------------------------------------
#
# WHY THIS IS NOT A DEMOLISH IN PERL. It was, through eight phases. On perls
# 5.14 to 5.26 an eval that runs inside a destructor, while an exception is
# unwinding past a TEMPORARY of that class, leaves $@ empty: the caller's die
# arrives with no message. Object::Proto calls DEMOLISH under an eval, so any
# class with one has this. `eval { f(Class->new) }` with f dying is enough.
# The packaging matrix found it; a DESTROY written in C runs no eval.

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
                (FN->board_drop)(BOARD(u));
            }
        }

MODULE = Game::Fanorona    PACKAGE = Game::Fanorona::Rules::Hold

PROTOTYPES: DISABLE

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
                (FN->game_drop)(INT2PTR(struct fn_game *, u));
            }
        }
