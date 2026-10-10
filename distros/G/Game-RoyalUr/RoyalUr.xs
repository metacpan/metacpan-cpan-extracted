/* RoyalUr.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * siblings that learned this the hard way say so in Go.xs and Xiangqi.xs.
 *
 * The XSUBs land in Game::RoyalUr::Engine, not in Game::RoyalUr, and are named
 * with a leading underscore: they take a raw pointer as a UV and there is no
 * typemap. The Perl that owns the lifetime is lib/Game/RoyalUr/Engine.pm.
 *
 * `_put`, `_lift`, `_set_hand` and `_set_home` are the structure primitives
 * from ru_abi.h and CHECK NOTHING.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ru_abi.h"

static const struct ru_abi *RU = NULL;

#define BOARD(u) INT2PTR(struct ru_board *, (u))

/* The key crosses as a 12-character hex string, never as a UV.
 *
 * It is 47 bits. On a perl with 32-bit IVs a UV cannot hold it and the top
 * would vanish silently, which for a key means a test that passes while
 * comparing part of a number. Hand-rolled rather than via my_snprintf, as
 * Brandubh.xs, Xiangqi.xs and Go.xs do it.
 */
static SV *ru_hex48(pTHX_ unsigned long long v)
{
    static const char digits[] = "0123456789abcdef";
    char buf[12];
    int i;
    for (i = 11; i >= 0; i--) {
        buf[i] = digits[v & 0xfULL];
        v >>= 4;
    }
    return newSVpvn(buf, 12);
}

/* A count crosses as a decimal STRING, for the reason a key crosses as hex: the
 * positions of a rule set outgrow a 32-bit IV. Hand-rolled and integer only;
 * there is no floating point anywhere in this distribution's C.
 */
static SV *ru_dec64(pTHX_ unsigned long long v)
{
    char buf[24];
    int i = (int) sizeof(buf);
    do {
        buf[--i] = (char) ('0' + (int) (v % 10ULL));
        v /= 10ULL;
    } while (v);
    return newSVpvn(buf + i, (STRLEN) (sizeof(buf) - i));
}

/* The rule set crosses as undef for the standard game, as the NAME of a set,
 * or as a hash reference of what differs from the standard game.
 *
 * AN UNKNOWN KEY IS A CROAK and not a shrug: `safe_rosette => 0` silently
 * playing the standard game is the kind of mistake that agrees with you. So
 * is a value a field may not hold.
 */
static void ru_rules_of_sv(pTHX_ SV *sv, struct ru_rules *r)
{
    HV *hv;
    HE *he;

    (RU->rules_named)(RU_RULES_FINKEL, r);
    if (!sv || !SvOK(sv)) return;

    if (!SvROK(sv)) {
        STRLEN len;
        const char *name = SvPV(sv, len);
        if (len == 6 && memEQ(name, "finkel", 6))       return;
        if (len == 7 && memEQ(name, "masters", 7))      { (RU->rules_named)(RU_RULES_MASTERS, r); return; }
        croak("Game::RoyalUr::Engine: no rule set is called '%" SVf "'", SVfARG(sv));
    }
    if (SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("Game::RoyalUr::Engine: a rule set is a name or a hash reference");
    hv = (HV *) SvRV(sv);

    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        const char *key = HePV(he, klen);
        SV *val = HeVAL(he);

        if (klen == 5 && memEQ(key, "route", 5)) {
            STRLEN vlen;
            const char *s = SvPV(val, vlen);
            if (vlen == 5 && memEQ(s, "short", 5))     r->route = RU_ROUTE_SHORT;
            else if (vlen == 4 && memEQ(s, "long", 4)) r->route = RU_ROUTE_LONG;
            else croak("Game::RoyalUr::Engine: route is 'short' or 'long'");
        }
        else if (klen == 4 && memEQ(key, "dice", 4))
            r->dice = (int) SvIV(val);
        else if (klen == 10 && memEQ(key, "zero_rolls", 10))
            r->zero_rolls = (int) SvIV(val);
        else if (klen == 13 && memEQ(key, "safe_rosettes", 13))
            r->safe_rosettes = SvTRUE(val) ? 1 : 0;
        else if (klen == 6 && memEQ(key, "pieces", 6))
            r->pieces = (int) SvIV(val);
        else
            croak("Game::RoyalUr::Engine: no rule is called '%" SVf "'",
                  SVfARG(HeSVKEY_force(he)));
    }
    if (!(RU->rules_ok)(r))
        croak("Game::RoyalUr::Engine: dice is 3 or 4, zero_rolls is 0 or 4, and pieces is 1 to 7");
}

/* The weights of the evaluation cross as a hash reference, or as undef for the
 * plain evaluation, and an unknown key croaks, for the reason a rule's does. */
static void ru_weights_of_sv(pTHX_ SV *sv, struct ru_weights *w)
{
    HV *hv;
    HE *he;

    (RU->weights_default)(w);
    if (!sv || !SvOK(sv)) return;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("Game::RoyalUr::Engine: weights are a hash reference");
    hv = (HV *) SvRV(sv);

    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        const char *key = HePV(he, klen);
        int val = (int) SvIV(HeVAL(he));

        if      (klen == 7 && memEQ(key, "exposed", 7)) w->exposed = val;
        else if (klen == 7 && memEQ(key, "rosette", 7)) w->rosette = val;
        else if (klen == 5 && memEQ(key, "entry", 5))   w->entry = val;
        else
            croak("Game::RoyalUr::Engine: no weight is called '%" SVf "'",
                  SVfARG(HeSVKEY_force(he)));
    }
}

MODULE = Game::RoyalUr    PACKAGE = Game::RoyalUr::Engine

PROTOTYPES: DISABLE

BOOT:
    RU = ru_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(RU);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)RU->abi_version;
    OUTPUT:
        RETVAL

UV
_new_board(pieces)
        int pieces
    CODE:
        RETVAL = PTR2UV((RU->board_new)(pieces));
    OUTPUT:
        RETVAL

UV
_copy_board(u)
        UV u
    CODE:
        RETVAL = PTR2UV((RU->board_copy)(BOARD(u)));
    OUTPUT:
        RETVAL

void
_drop_board(u)
        UV u
    CODE:
        (RU->board_drop)(BOARD(u));

int
_live()
    CODE:
        RETVAL = (RU->live)();
    OUTPUT:
        RETVAL

# A string that will not parse returns undef and the code, rather than
# croaking: the reason is what a caller shows a person, and ten of them are
# distinguishable.
void
_of_string(str)
        const char *str
    PREINIT:
        struct ru_board *b;
        int err = 0;
    PPCODE:
        b = (RU->board_of_string)(str, &err);
        EXTEND(SP, 2);
        if (b) PUSHs(sv_2mortal(newSVuv(PTR2UV(b))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(err)));

SV *
_to_string(u)
        UV u
    PREINIT:
        char buf[RU_POS_MAX];
        int n;
    CODE:
        n = (RU->to_string)(BOARD(u), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

int
_at(u, cell)
        UV u
        int cell
    CODE:
        RETVAL = (RU->at)(BOARD(u), cell);
    OUTPUT:
        RETVAL

void
_put(u, cell, piece)
        UV u
        int cell
        int piece
    CODE:
        (RU->put)(BOARD(u), cell, piece);

void
_lift(u, cell)
        UV u
        int cell
    CODE:
        (RU->lift)(BOARD(u), cell);

int
_hand(u, side)
        UV u
        int side
    CODE:
        RETVAL = (RU->hand)(BOARD(u), side);
    OUTPUT:
        RETVAL

void
_set_hand(u, side, n)
        UV u
        int side
        int n
    CODE:
        (RU->set_hand)(BOARD(u), side, n);

int
_home(u, side)
        UV u
        int side
    CODE:
        RETVAL = (RU->home)(BOARD(u), side);
    OUTPUT:
        RETVAL

void
_set_home(u, side, n)
        UV u
        int side
        int n
    CODE:
        (RU->set_home)(BOARD(u), side, n);

int
_side(u)
        UV u
    CODE:
        RETVAL = (RU->side)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_side(u, side)
        UV u
        int side
    CODE:
        (RU->set_side)(BOARD(u), side);

int
_count(u, side)
        UV u
        int side
    CODE:
        RETVAL = (RU->count)(BOARD(u), side);
    OUTPUT:
        RETVAL

int
_consistent(u, n)
        UV u
        int n
    CODE:
        RETVAL = (RU->consistent)(BOARD(u), n);
    OUTPUT:
        RETVAL

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = ru_hex48(aTHX_ (RU->key)(BOARD(u)));
    OUTPUT:
        RETVAL

int
_cell_of(file, row)
        int file
        int row
    CODE:
        RETVAL = (RU->cell_of)(file, row);
    OUTPUT:
        RETVAL

int
_file_of(cell)
        int cell
    CODE:
        RETVAL = (RU->file_of)(cell);
    OUTPUT:
        RETVAL

int
_row_of(cell)
        int cell
    CODE:
        RETVAL = (RU->row_of)(cell);
    OUTPUT:
        RETVAL

int
_is_rosette(cell)
        int cell
    CODE:
        RETVAL = (RU->is_rosette)(cell);
    OUTPUT:
        RETVAL

int
_route_len(route)
        int route
    CODE:
        RETVAL = (RU->route_len)(route);
    OUTPUT:
        RETVAL

int
_route_cell(route, side, step)
        int route
        int side
        int step
    CODE:
        RETVAL = (RU->route_cell)(route, side, step);
    OUTPUT:
        RETVAL

int
_route_step(route, side, cell)
        int route
        int side
        int cell
    CODE:
        RETVAL = (RU->route_step)(route, side, cell);
    OUTPUT:
        RETVAL

int
_route_shared(route, cell)
        int route
        int cell
    CODE:
        RETVAL = (RU->route_shared)(route, cell);
    OUTPUT:
        RETVAL

# ---- version 2: the chance of a roll -------------------------------------------

int
_chance_count(dice, zero_rolls)
        int dice
        int zero_rolls
    CODE:
        RETVAL = (RU->chance_count)(dice, zero_rolls);
    OUTPUT:
        RETVAL

# The roll, its weight and the denominator, or nothing when there is no such
# entry.
void
_chance(dice, zero_rolls, i)
        int dice
        int zero_rolls
        int i
    PREINIT:
        int roll = 0, weight = 0, denominator = 0;
    PPCODE:
        if ((RU->chance)(dice, zero_rolls, i, &roll, &weight, &denominator)) {
            EXTEND(SP, 3);
            PUSHs(sv_2mortal(newSViv(roll)));
            PUSHs(sv_2mortal(newSViv(weight)));
            PUSHs(sv_2mortal(newSViv(denominator)));
        }

# ---- version 3: what a roll allows ---------------------------------------------

int
_moves_max()
    CODE:
        RETVAL = RU_MOVES_MAX;
    OUTPUT:
        RETVAL

# The rule set a name or a hash stands for, as five numbers: route, dice,
# zero_rolls, safe_rosettes, pieces.
void
_rules(rules)
        SV *rules
    PREINIT:
        struct ru_rules r;
    PPCODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSViv(r.route)));
        PUSHs(sv_2mortal(newSViv(r.dice)));
        PUSHs(sv_2mortal(newSViv(r.zero_rolls)));
        PUSHs(sv_2mortal(newSViv(r.safe_rosettes)));
        PUSHs(sv_2mortal(newSViv(r.pieces)));

# Each move as seven numbers in an array: from_step, to_step, from_cell,
# to_cell, captures, rosette, home. A roll that is not 0 to 4 croaks; it is
# not an empty list.
void
_moves(u, roll, rules)
        UV u
        int roll
        SV *rules
    PREINIT:
        struct ru_rules r;
        struct ru_move m[RU_MOVES_MAX];
        int n, i;
    PPCODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        n = (RU->moves)(BOARD(u), &r, roll, m, RU_MOVES_MAX);
        if (n < 0)
            croak("Game::RoyalUr::Engine: a roll is a whole number from 0 to %d", RU_ROLL_MAX);
        if (n > RU_MOVES_MAX) n = RU_MOVES_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *av = newAV();
            av_extend(av, 6);
            av_push(av, newSViv(m[i].from_step));
            av_push(av, newSViv(m[i].to_step));
            av_push(av, newSViv(m[i].from_cell));
            av_push(av, newSViv(m[i].to_cell));
            av_push(av, newSViv(m[i].captures));
            av_push(av, newSViv(m[i].rosette));
            av_push(av, newSViv(m[i].home));
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
        }

SV *
_count_positions(rules)
        SV *rules
    PREINIT:
        struct ru_rules r;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        RETVAL = ru_dec64(aTHX_ (RU->count_positions)(&r));
    OUTPUT:
        RETVAL

# ---- version 4: a move made ------------------------------------------------------

int
_ply(u)
        UV u
    CODE:
        RETVAL = (RU->ply)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_ply(u, ply)
        UV u
        int ply
    CODE:
        (RU->set_ply)(BOARD(u), ply);

int
_ply_cap()
    CODE:
        RETVAL = (RU->ply_cap)();
    OUTPUT:
        RETVAL

# What apply and forfeit hand back is the undo, as the bytes of the struct. It
# is opaque: the only thing to do with one is hand it to _unapply. undef when
# the move was not made.
SV *
_apply(u, rules, from_step, to_step, from_cell, to_cell, home)
        UV u
        SV *rules
        int from_step
        int to_step
        int from_cell
        int to_cell
        int home
    PREINIT:
        struct ru_rules r;
        struct ru_move m;
        struct ru_undo undo;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        Zero(&m, 1, struct ru_move);
        m.from_step = from_step;
        m.to_step = to_step;
        m.from_cell = from_cell;
        m.to_cell = to_cell;
        m.home = home ? 1 : 0;
        if (!(RU->apply)(BOARD(u), &r, &m, &undo)) XSRETURN_UNDEF;
        RETVAL = newSVpvn((const char *) &undo, sizeof(undo));
    OUTPUT:
        RETVAL

SV *
_forfeit(u)
        UV u
    PREINIT:
        struct ru_undo undo;
    CODE:
        (RU->forfeit)(BOARD(u), &undo);
        RETVAL = newSVpvn((const char *) &undo, sizeof(undo));
    OUTPUT:
        RETVAL

void
_unapply(u, token)
        UV u
        SV *token
    PREINIT:
        struct ru_undo undo;
        STRLEN len;
        const char *bytes;
    CODE:
        if (!SvOK(token) || SvROK(token))
            croak("Game::RoyalUr::Engine: unapply takes what apply or forfeit returned");
        bytes = SvPVbyte(token, len);
        if (len != sizeof(undo))
            croak("Game::RoyalUr::Engine: unapply takes what apply or forfeit returned");
        Copy(bytes, &undo, 1, struct ru_undo);
        (RU->unapply)(BOARD(u), &undo);

int
_status(u, rules)
        UV u
        SV *rules
    PREINIT:
        struct ru_rules r;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        RETVAL = (RU->status)(BOARD(u), &r);
    OUTPUT:
        RETVAL

int
_how(u, rules)
        UV u
        SV *rules
    PREINIT:
        struct ru_rules r;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        RETVAL = (RU->how)(BOARD(u), &r);
    OUTPUT:
        RETVAL

int
_winner(u, rules)
        UV u
        SV *rules
    PREINIT:
        struct ru_rules r;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        RETVAL = (RU->winner)(BOARD(u), &r);
    OUTPUT:
        RETVAL

SV *
_walk(u, depth, rules)
        UV u
        int depth
        SV *rules
    PREINIT:
        struct ru_rules r;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        RETVAL = ru_dec64(aTHX_ (RU->walk)(BOARD(u), &r, depth));
    OUTPUT:
        RETVAL

# ---- version 5: choosing a move ------------------------------------------------

int
_evaluate(u, rules, weights, side)
        UV u
        SV *rules
        SV *weights
        int side
    PREINIT:
        struct ru_rules r;
        struct ru_weights w;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        ru_weights_of_sv(aTHX_ weights, &w);
        RETVAL = (RU->evaluate)(BOARD(u), &r, &w, side);
    OUTPUT:
        RETVAL

int
_greedy(u, roll, rules)
        UV u
        int roll
        SV *rules
    PREINIT:
        struct ru_rules r;
    CODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        RETVAL = (RU->greedy)(BOARD(u), &r, roll);
    OUTPUT:
        RETVAL

# The index chosen, then the nodes spent as a string of digits, the depth
# finished, the value, and whether the budget ran out. A budget is a whole
# number of nodes from 0 to 2,000,000,000: more than that is refused, and does
# not wrap round on a perl whose integers are 32 bits.
void
_search(u, roll, rules, weights, budget, max_depth)
        UV u
        int roll
        SV *rules
        SV *weights
        IV budget
        int max_depth
    PREINIT:
        struct ru_rules r;
        struct ru_weights w;
        struct ru_search_info info;
        int chosen;
    PPCODE:
        ru_rules_of_sv(aTHX_ rules, &r);
        ru_weights_of_sv(aTHX_ weights, &w);
        if (budget < 0 || budget > 2000000000)
            croak("Game::RoyalUr::Engine: a budget is a number of nodes from 0 to 2000000000");
        chosen = (RU->search)(BOARD(u), &r, roll, &w, (unsigned long long) budget, max_depth, &info);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSViv(chosen)));
        PUSHs(sv_2mortal(ru_dec64(aTHX_ info.nodes)));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.value)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));
