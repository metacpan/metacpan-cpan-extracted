/* Brandubh.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * siblings that learned this the hard way say so in Go.xs and Xiangqi.xs.
 *
 * The XSUBs land in Game::Brandubh::Engine, not in Game::Brandubh, and are named
 * with a leading underscore: they take a raw pointer as a UV and there is no
 * typemap. The Perl that owns the lifetime is lib/Game/Brandubh/Engine.pm.
 *
 * `_put`, `_lift` and `_relocate` are the structure primitives from bd_abi.h
 * and CHECK NOTHING.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "bd_abi.h"

static const struct bd_abi *BD = NULL;

#define BOARD(u) INT2PTR(struct bd_board *, (u))
#define GAME(u)  INT2PTR(struct bd_game *, (u))

/* A 64-bit value crosses as a 16-character hex string, never as a UV.
 *
 * On a perl with 32-bit IVs a UV cannot hold it and the top half would vanish
 * silently, which for a zobrist key means a test that passes while comparing
 * half a number. Hand-rolled rather than via my_snprintf. Copied from
 * Xiangqi.xs, which copied it from Go.xs, which is where it was worked out.
 */
static SV *bd_hex64(pTHX_ unsigned long long v)
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

/* A count crosses as a decimal STRING, for the reason a key crosses as hex: a
 * perft total outgrows a 32-bit IV within a few plies. Hand-rolled and integer
 * only; there is no floating point anywhere in this distribution's C.
 */
static SV *bd_dec64(pTHX_ unsigned long long v)
{
    char buf[24];
    int i = (int) sizeof(buf);
    do {
        buf[--i] = (char) ('0' + (int) (v % 10ULL));
        v /= 10ULL;
    } while (v);
    return newSVpvn(buf + i, (STRLEN) (sizeof(buf) - i));
}

/* The rule set crosses as a hash reference, or as undef for the default. Only
 * the keys that differ need be given.
 *
 * AN UNKNOWN KEY IS A CROAK and not a shrug: `throne_pas => 0` silently
 * playing the default game is the kind of mistake that agrees with you.
 */
static void bd_variant_of_sv(pTHX_ SV *sv, struct bd_variant *v)
{
    HV *hv;
    HE *he;

    (BD->variant_default)(v);
    if (!sv || !SvOK(sv)) return;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("Game::Brandubh::Engine: a variant is a hash reference");
    hv = (HV *) SvRV(sv);

    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        const char *key = HePV(he, klen);
        SV *val = HeVAL(he);

        if (klen == 11 && memEQ(key, "throne_pass", 11))
            v->throne_pass = SvTRUE(val) ? 1 : 0;
        else if (klen == 14 && memEQ(key, "throne_reentry", 14))
            v->throne_reentry = SvTRUE(val) ? 1 : 0;
        else if (klen == 19 && memEQ(key, "king_everywhere_two", 19))
            v->king_everywhere_two = SvTRUE(val) ? 1 : 0;
        else if (klen == 11 && memEQ(key, "king_strong", 11))
            v->king_strong = SvTRUE(val) ? 1 : 0;
        else if (klen == 6 && memEQ(key, "escape", 6)) {
            STRLEN vlen;
            const char *s = SvPV(val, vlen);
            if (vlen == 4 && memEQ(s, "edge", 4))        v->escape_edge = 1;
            else if (vlen == 6 && memEQ(s, "corner", 6)) v->escape_edge = 0;
            else croak("Game::Brandubh::Engine: escape is 'corner' or 'edge'");
        }
        else if (klen == 6 && memEQ(key, "repeat", 6))
            v->repeat = (int) SvIV(val);
        else if (klen == 7 && memEQ(key, "ply_cap", 7))
            v->ply_cap = (int) SvIV(val);
        else
            croak("Game::Brandubh::Engine: no variant field is called '%" SVf "'",
                  SVfARG(HeSVKEY_force(he)));
    }
}

/* The weights of the evaluation cross as a hash reference, or as undef for the
 * defaults, and an unknown key croaks, for the reason a variant's does. */
static void bd_weights_of_sv(pTHX_ SV *sv, struct bd_weights *w)
{
    HV *hv;
    HE *he;

    (BD->weights_default)(w);
    if (!sv || !SvOK(sv)) return;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("Game::Brandubh::Rules: weights are a hash reference");
    hv = (HV *) SvRV(sv);

    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        const char *key = HePV(he, klen);
        int val = (int) SvIV(HeVAL(he));

        if      (klen == 8  && memEQ(key, "attacker", 8))      w->attacker = val;
        else if (klen == 8  && memEQ(key, "defender", 8))      w->defender = val;
        else if (klen == 8  && memEQ(key, "lane_one", 8))      w->lane_one = val;
        else if (klen == 8  && memEQ(key, "lane_two", 8))      w->lane_two = val;
        else if (klen == 7  && memEQ(key, "freedom", 7))       w->freedom = val;
        else if (klen == 12 && memEQ(key, "corner_guard", 12)) w->corner_guard = val;
        else if (klen == 4  && memEQ(key, "ring", 4))          w->ring = val;
        else
            croak("Game::Brandubh::Rules: no weight is called '%" SVf "'",
                  SVfARG(HeSVKEY_force(he)));
    }
}

MODULE = Game::Brandubh    PACKAGE = Game::Brandubh::Engine

PROTOTYPES: DISABLE

BOOT:
    BD = bd_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(BD);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)BD->abi_version;
    OUTPUT:
        RETVAL

UV
_new_board()
    CODE:
        RETVAL = PTR2UV((BD->board_new)());
    OUTPUT:
        RETVAL

UV
_new_empty()
    CODE:
        RETVAL = PTR2UV((BD->board_empty)());
    OUTPUT:
        RETVAL

UV
_copy_board(u)
        UV u
    CODE:
        RETVAL = PTR2UV((BD->board_copy)(BOARD(u)));
    OUTPUT:
        RETVAL

void
_drop_board(u)
        UV u
    CODE:
        (BD->board_drop)(BOARD(u));

int
_live()
    CODE:
        RETVAL = (BD->live)();
    OUTPUT:
        RETVAL

# A string that will not parse returns undef and the code, rather than
# croaking: the reason is what a caller shows a person, and six of them are
# distinguishable.
void
_of_string(str)
        const char *str
    PREINIT:
        struct bd_board *b;
        int err = 0;
    PPCODE:
        b = (BD->board_of_string)(str, &err);
        EXTEND(SP, 2);
        if (b) PUSHs(sv_2mortal(newSVuv(PTR2UV(b))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(err)));

SV *
_to_string(u)
        UV u
    PREINIT:
        char buf[BD_POS_MAX];
        int n;
    CODE:
        n = (BD->to_string)(BOARD(u), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

int
_at(u, sq)
        UV u
        int sq
    CODE:
        RETVAL = (BD->at)(BOARD(u), sq);
    OUTPUT:
        RETVAL

void
_put(u, sq, piece)
        UV u
        int sq
        int piece
    CODE:
        (BD->put)(BOARD(u), sq, piece);

void
_lift(u, sq)
        UV u
        int sq
    CODE:
        (BD->lift)(BOARD(u), sq);

int
_side(u)
        UV u
    CODE:
        RETVAL = (BD->side)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_side(u, side)
        UV u
        int side
    CODE:
        (BD->set_side)(BOARD(u), side);

int
_count(u, piece)
        UV u
        int piece
    CODE:
        RETVAL = (BD->count)(BOARD(u), piece);
    OUTPUT:
        RETVAL

int
_king_square(u)
        UV u
    CODE:
        RETVAL = (BD->king_square)(BOARD(u));
    OUTPUT:
        RETVAL

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = bd_hex64(aTHX_ (BD->key)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_key_full_hex(u)
        UV u
    CODE:
        RETVAL = bd_hex64(aTHX_ (BD->key_full)(BOARD(u)));
    OUTPUT:
        RETVAL

SV *
_zobrist_hex(piece, sq)
        int piece
        int sq
    CODE:
        RETVAL = bd_hex64(aTHX_ (BD->zobrist)(piece, sq));
    OUTPUT:
        RETVAL

SV *
_zobrist_side_hex()
    CODE:
        RETVAL = bd_hex64(aTHX_ (BD->zobrist_side)());
    OUTPUT:
        RETVAL

int
_stride()
    CODE:
        RETVAL = (BD->stride)();
    OUTPUT:
        RETVAL

int
_square_of(file, rank)
        int file
        int rank
    CODE:
        RETVAL = (BD->square_of)(file, rank);
    OUTPUT:
        RETVAL

int
_file_of(sq)
        int sq
    CODE:
        RETVAL = (BD->file_of)(sq);
    OUTPUT:
        RETVAL

int
_rank_of(sq)
        int sq
    CODE:
        RETVAL = (BD->rank_of)(sq);
    OUTPUT:
        RETVAL

int
_on_board(sq)
        int sq
    CODE:
        RETVAL = (BD->on_board)(sq);
    OUTPUT:
        RETVAL

int
_is_throne(sq)
        int sq
    CODE:
        RETVAL = (BD->is_throne)(sq);
    OUTPUT:
        RETVAL

int
_is_corner(sq)
        int sq
    CODE:
        RETVAL = (BD->is_corner)(sq);
    OUTPUT:
        RETVAL

int
_beside_throne(sq)
        int sq
    CODE:
        RETVAL = (BD->beside_throne)(sq);
    OUTPUT:
        RETVAL

int
_side_of(piece)
        int piece
    CODE:
        RETVAL = (BD->side_of)(piece);
    OUTPUT:
        RETVAL

# ---- version 2: where a piece may go ------------------------------------------

int
_moves_max()
    CODE:
        RETVAL = BD_MOVES_MAX;
    OUTPUT:
        RETVAL

int
_move_make(from, to)
        int from
        int to
    CODE:
        RETVAL = (BD->move_make)(from, to);
    OUTPUT:
        RETVAL

int
_move_from(mv)
        int mv
    CODE:
        RETVAL = (BD->move_from)(mv);
    OUTPUT:
        RETVAL

int
_move_to(mv)
        int mv
    CODE:
        RETVAL = (BD->move_to)(mv);
    OUTPUT:
        RETVAL

# The whole list in list context. gen_moves reports how many moves there ARE
# and writes no more than the buffer holds, so a count above BD_MOVES_MAX would
# mean the bound in bd_abi.h is wrong: that is a croak and not a truncation.
void
_gen_moves(u, variant = &PL_sv_undef)
        UV u
        SV *variant
    PREINIT:
        struct bd_variant v;
        int list[BD_MOVES_MAX];
        int n, i;
    PPCODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        n = (BD->gen_moves)(BOARD(u), &v, list, BD_MOVES_MAX);
        if (n > BD_MOVES_MAX)
            croak("Game::Brandubh::Engine: %d moves, more than the %d the board can have", n, BD_MOVES_MAX);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(list[i])));

int
_is_legal(u, mv, variant = &PL_sv_undef)
        UV u
        int mv
        SV *variant
    PREINIT:
        struct bd_variant v;
    CODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        RETVAL = (BD->is_legal)(BOARD(u), &v, mv);
    OUTPUT:
        RETVAL

int
_why_not(u, from, to, variant = &PL_sv_undef)
        UV u
        int from
        int to
        SV *variant
    PREINIT:
        struct bd_variant v;
    CODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        RETVAL = (BD->why_not)(BOARD(u), &v, from, to);
    OUTPUT:
        RETVAL

void
_relocate(u, mv)
        UV u
        int mv
    CODE:
        (BD->relocate)(BOARD(u), mv);

SV *
_perft_slides(u, depth, variant = &PL_sv_undef)
        UV u
        int depth
        SV *variant
    PREINIT:
        struct bd_variant v;
    CODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        RETVAL = bd_dec64(aTHX_ (BD->perft_slides)(BOARD(u), &v, depth));
    OUTPUT:
        RETVAL

# ---- version 3: what a move captures ------------------------------------------

int
_hostile_to(u, sq, side)
        UV u
        int sq
        int side
    CODE:
        RETVAL = (BD->hostile_to)(BOARD(u), sq, side);
    OUTPUT:
        RETVAL

void
_captures_at(u, to, variant = &PL_sv_undef)
        UV u
        int to
        SV *variant
    PREINIT:
        struct bd_variant v;
        int out[BD_CAPTURES_MAX];
        int n, i;
    PPCODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        n = (BD->captures_at)(BOARD(u), &v, to, out);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(out[i])));

# The undo crosses as a STRING OF RAW BYTES and not as a pointer, so nothing is
# allocated that a caller could forget to release, and a board can be undone
# after the scalar holding the token has been copied about.
void
_do_move(u, mv, variant = &PL_sv_undef)
        UV u
        int mv
        SV *variant
    PREINIT:
        struct bd_variant v;
        struct bd_undo undo;
        int flags;
    PPCODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        flags = (BD->do_move)(BOARD(u), &v, mv, &undo);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(flags)));
        PUSHs(sv_2mortal(newSVpvn((const char *)&undo, sizeof(undo))));

void
_undo_move(u, token)
        UV u
        SV *token
    PREINIT:
        STRLEN len;
        const char *bytes;
        struct bd_undo undo;
    CODE:
        bytes = SvPV(token, len);
        if (len != sizeof(undo))
            croak("Game::Brandubh::Engine: that is not an undo token");
        Copy(bytes, &undo, 1, struct bd_undo);
        (BD->undo_move)(BOARD(u), &undo);

# (flags, square, square, ...)
void
_preview(u, mv, variant = &PL_sv_undef)
        UV u
        int mv
        SV *variant
    PREINIT:
        struct bd_variant v;
        int out[BD_CAPTURES_MAX];
        int n, i, flags = 0;
    PPCODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        n = (BD->preview)(BOARD(u), &v, mv, out, &flags);
        EXTEND(SP, n + 1);
        PUSHs(sv_2mortal(newSViv(flags)));
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(out[i])));

SV *
_perft(u, depth, variant = &PL_sv_undef)
        UV u
        int depth
        SV *variant
    PREINIT:
        struct bd_variant v;
    CODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        RETVAL = bd_dec64(aTHX_ (BD->perft)(BOARD(u), &v, depth));
    OUTPUT:
        RETVAL

# ---- version 4: a game ----------------------------------------------------------
#
# A SECOND PACKAGE. A game is a different thing from a board: it owns one,
# remembers how it got there, and is the only thing here that refuses a move.
# The Perl that owns the lifetime is lib/Game/Brandubh/Rules.pm.

MODULE = Game::Brandubh    PACKAGE = Game::Brandubh::Rules

PROTOTYPES: DISABLE

# (pointer, error). With no position the game starts from the set-up. A
# position that will not parse returns undef and the code.
void
_new_game(position, variant = &PL_sv_undef)
        SV *position
        SV *variant
    PREINIT:
        struct bd_variant v;
        struct bd_board *b = NULL;
        struct bd_game *g;
        int err = 0;
    PPCODE:
        bd_variant_of_sv(aTHX_ variant, &v);
        if (SvOK(position)) {
            b = (BD->board_of_string)(SvPV_nolen(position), &err);
            if (!b) {
                EXTEND(SP, 2);
                PUSHs(&PL_sv_undef);
                PUSHs(sv_2mortal(newSViv(err)));
                XSRETURN(2);
            }
        }
        g = (BD->game_new)(b, &v);
        if (b) (BD->board_drop)(b);
        EXTEND(SP, 2);
        if (g) PUSHs(sv_2mortal(newSVuv(PTR2UV(g))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(0)));

UV
_copy_game(u)
        UV u
    CODE:
        RETVAL = PTR2UV((BD->game_copy)(GAME(u)));
    OUTPUT:
        RETVAL

void
_drop_game(u)
        UV u
    CODE:
        (BD->game_drop)(GAME(u));

int
_games_live()
    CODE:
        RETVAL = (BD->games_live)();
    OUTPUT:
        RETVAL

SV *
_position(u)
        UV u
    PREINIT:
        char buf[BD_POS_MAX];
        int n;
    CODE:
        n = (BD->to_string)((BD->game_board)(GAME(u)), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = bd_hex64(aTHX_ (BD->key)((BD->game_board)(GAME(u))));
    OUTPUT:
        RETVAL

SV *
_key_at_hex(u, ply)
        UV u
        int ply
    CODE:
        if (ply < 0 || ply > (BD->game_ply)(GAME(u))) XSRETURN_UNDEF;
        RETVAL = bd_hex64(aTHX_ (BD->game_key_at)(GAME(u), ply));
    OUTPUT:
        RETVAL

int
_side(u)
        UV u
    CODE:
        RETVAL = (BD->side)((BD->game_board)(GAME(u)));
    OUTPUT:
        RETVAL

int
_at(u, sq)
        UV u
        int sq
    CODE:
        RETVAL = (BD->at)((BD->game_board)(GAME(u)), sq);
    OUTPUT:
        RETVAL

int
_count(u, piece)
        UV u
        int piece
    CODE:
        RETVAL = (BD->count)((BD->game_board)(GAME(u)), piece);
    OUTPUT:
        RETVAL

int
_ply(u)
        UV u
    CODE:
        RETVAL = (BD->game_ply)(GAME(u));
    OUTPUT:
        RETVAL

int
_cap(u)
        UV u
    CODE:
        RETVAL = (BD->game_cap)(GAME(u));
    OUTPUT:
        RETVAL

int
_outcome(u)
        UV u
    CODE:
        RETVAL = (BD->game_outcome)(GAME(u));
    OUTPUT:
        RETVAL

int
_winner(u)
        UV u
    CODE:
        RETVAL = (BD->game_winner)(GAME(u));
    OUTPUT:
        RETVAL

int
_winner_of(outcome)
        int outcome
    CODE:
        RETVAL = (BD->winner_of)(outcome);
    OUTPUT:
        RETVAL

int
_repeats(u)
        UV u
    CODE:
        RETVAL = (BD->repeats)(GAME(u));
    OUTPUT:
        RETVAL

void
_moves(u)
        UV u
    PREINIT:
        int list[BD_MOVES_MAX];
        int n, i;
    PPCODE:
        n = (BD->game_moves)(GAME(u), list, BD_MOVES_MAX);
        if (n > BD_MOVES_MAX)
            croak("Game::Brandubh::Rules: %d moves, more than the %d the board can have", n, BD_MOVES_MAX);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(list[i])));

# (answer, flags)
void
_play(u, mv)
        UV u
        int mv
    PREINIT:
        int flags = 0, answer;
    PPCODE:
        answer = (BD->game_do)(GAME(u), mv, &flags);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(answer)));
        PUSHs(sv_2mortal(newSViv(flags)));

int
_undo(u)
        UV u
    CODE:
        RETVAL = (BD->game_undo)(GAME(u));
    OUTPUT:
        RETVAL

# (flags, square, square, ...) under the game's own rule set
void
_preview(u, mv)
        UV u
        int mv
    PREINIT:
        struct bd_variant v;
        int out[BD_CAPTURES_MAX];
        int n, i, flags = 0;
    PPCODE:
        (BD->game_variant)(GAME(u), &v);
        n = (BD->preview)((BD->game_board)(GAME(u)), &v, mv, out, &flags);
        EXTEND(SP, n + 1);
        PUSHs(sv_2mortal(newSViv(flags)));
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSViv(out[i])));

int
_why_not(u, from, to)
        UV u
        int from
        int to
    PREINIT:
        struct bd_variant v;
    CODE:
        (BD->game_variant)(GAME(u), &v);
        RETVAL = (BD->why_not)((BD->game_board)(GAME(u)), &v, from, to);
    OUTPUT:
        RETVAL

# the rule set the game is playing, AS CLAMPED, so a caller can see what a cap
# of 0 or a repeat of 1 became
SV *
_variant(u)
        UV u
    PREINIT:
        struct bd_variant v;
        HV *hv;
    CODE:
        (BD->game_variant)(GAME(u), &v);
        hv = newHV();
        (void)hv_stores(hv, "throne_pass",         newSViv(v.throne_pass));
        (void)hv_stores(hv, "throne_reentry",      newSViv(v.throne_reentry));
        (void)hv_stores(hv, "king_everywhere_two", newSViv(v.king_everywhere_two));
        (void)hv_stores(hv, "king_strong",         newSViv(v.king_strong));
        (void)hv_stores(hv, "escape",              newSVpv(v.escape_edge ? "edge" : "corner", 0));
        (void)hv_stores(hv, "repeat",              newSViv(v.repeat));
        (void)hv_stores(hv, "ply_cap",             newSViv(v.ply_cap));
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

# ---- version 5: choosing a move ---------------------------------------------------

# (move, nodes, depth, score, stopped). The move is 0 when the game is over.
# The node count is a decimal string, as every count that can outgrow 32 bits
# is. The budget and the seed are UVs: a budget fits 32 bits with room, and the
# caller keeps a seed inside them.
void
_search(u, budget, seed = 1, max_depth = 0, weights = &PL_sv_undef)
        UV u
        UV budget
        UV seed
        int max_depth
        SV *weights
    PREINIT:
        struct bd_weights w;
        struct bd_search_info info;
        int mv;
    PPCODE:
        bd_weights_of_sv(aTHX_ weights, &w);
        mv = (BD->search)(GAME(u), &w, (unsigned long long)budget, (unsigned long long)seed, max_depth, &info);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSViv(mv)));
        PUSHs(sv_2mortal(bd_dec64(aTHX_ info.nodes)));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.score)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));

int
_evaluate(u, weights = &PL_sv_undef)
        UV u
        SV *weights
    PREINIT:
        struct bd_weights w;
        struct bd_variant v;
    CODE:
        bd_weights_of_sv(aTHX_ weights, &w);
        (BD->game_variant)(GAME(u), &v);
        RETVAL = (BD->evaluate)((BD->game_board)(GAME(u)), &v, &w);
    OUTPUT:
        RETVAL

# the default weights, as a hash
SV *
_weights()
    PREINIT:
        struct bd_weights w;
        HV *hv;
    CODE:
        (BD->weights_default)(&w);
        hv = newHV();
        (void)hv_stores(hv, "attacker",     newSViv(w.attacker));
        (void)hv_stores(hv, "defender",     newSViv(w.defender));
        (void)hv_stores(hv, "lane_one",     newSViv(w.lane_one));
        (void)hv_stores(hv, "lane_two",     newSViv(w.lane_two));
        (void)hv_stores(hv, "freedom",      newSViv(w.freedom));
        (void)hv_stores(hv, "corner_guard", newSViv(w.corner_guard));
        (void)hv_stores(hv, "ring",         newSViv(w.ring));
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL
