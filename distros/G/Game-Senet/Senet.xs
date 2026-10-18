/* Senet.xs - the door to the C board.
 *
 * At the TOP of the distribution and not under lib/, because an XSMULTI build's
 * export list and Strawberry's import library rule never agree on a name. The
 * siblings that learned this the hard way say so in Go.xs and Xiangqi.xs.
 *
 * The XSUBs land in Game::Senet::Engine, not in Game::Senet, and are named with
 * a leading underscore: they take a raw pointer as a UV and there is no
 * typemap. The Perl that owns the lifetime is lib/Game/Senet/Engine.pm.
 *
 * `_put` and `_lift` are the structure primitives from sen_abi.h and CHECK
 * NOTHING.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sen_abi.h"

static const struct sen_abi *SEN = NULL;

#define BOARD(u) INT2PTR(struct sen_board *, (u))

/* The key crosses as a 16-character hex string, never as a UV.
 *
 * It is 61 bits. On a perl with 32-bit IVs a UV cannot hold it and the top
 * would vanish silently, which for a key means a test that passes while
 * comparing part of a number. Hand-rolled rather than via my_snprintf, as
 * RoyalUr.xs and Brandubh.xs do it.
 */
static SV *sen_hex64(pTHX_ unsigned long long v)
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

/* A count crosses as a decimal STRING, for the reason a key crosses as hex: the
 * leaves of a walk outgrow a 32-bit IV. Integer only. */
static SV *sen_dec64(pTHX_ unsigned long long v)
{
    char buf[24];
    int i = (int) sizeof(buf);
    do {
        buf[--i] = (char) ('0' + (int) (v % 10ULL));
        v /= 10ULL;
    } while (v);
    return newSVpvn(buf + i, (STRLEN) (sizeof(buf) - i));
}

static int sen_word_is(const char *s, STRLEN len, const char *word)
{
    STRLEN n = strlen(word);
    return len == n && memEQ(s, word, n);
}

/* The rule set crosses as undef for the default set, as the NAME of a set, or
 * as a hash reference of what differs from a set: `exits` names the set whose
 * chains and safe houses to start from, and every other key overrides one
 * scalar field.
 *
 * AN UNKNOWN KEY IS A CROAK and not a shrug: `blockade3 => 0` silently playing
 * the default set is the kind of mistake that agrees with you. So is a value a
 * field may not hold. THE NAMES OF THE SETS ARE NOT IN THIS FILE: the engine
 * answers them through rules_id.
 */
static void sen_rules_of_sv(pTHX_ SV *sv, struct sen_rules *r)
{
    HV *hv;
    HE *he;
    SV **base;

    (SEN->rules_named)(SEN_RULES_KENDALL, r);
    if (!sv || !SvOK(sv)) return;

    if (!SvROK(sv)) {
        int id = (SEN->rules_id)(SvPV_nolen(sv));
        if (id < 0)
            croak("Game::Senet::Engine: no rule set is called '%" SVf "'", SVfARG(sv));
        (SEN->rules_named)(id, r);
        return;
    }
    if (SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("Game::Senet::Engine: a rule set is a name or a hash reference");
    hv = (HV *) SvRV(sv);

    base = hv_fetchs(hv, "exits", 0);
    if (base && SvOK(*base)) {
        int id = (SEN->rules_id)(SvPV_nolen(*base));
        if (id < 0)
            croak("Game::Senet::Engine: exits names a rule set, and no set is called '%" SVf "'",
                  SVfARG(*base));
        (SEN->rules_named)(id, r);
    }

    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen, vlen;
        const char *key = HePV(he, klen);
        SV *val = HeVAL(he);
        const char *s;

        if (sen_word_is(key, klen, "exits"))
            continue;
        if (sen_word_is(key, klen, "pieces"))
            r->pieces = (int) SvIV(val);
        else if (sen_word_is(key, klen, "blockade"))
            r->blockade = (int) SvIV(val);
        else if (sen_word_is(key, klen, "backward"))
            r->backward = (int) SvIV(val);
        else if (sen_word_is(key, klen, "throw_on_26"))
            r->throw_on_26 = (int) SvIV(val);
        else if (sen_word_is(key, klen, "protect")) {
            s = SvPV(val, vlen);
            if (sen_word_is(s, vlen, "none"))      r->protect = SEN_PROTECT_NONE;
            else if (sen_word_is(s, vlen, "run"))  r->protect = SEN_PROTECT_RUN;
            else if (sen_word_is(s, vlen, "ends")) r->protect = SEN_PROTECT_ENDS;
            else croak("Game::Senet::Engine: protect is 'none', 'run' or 'ends'");
        }
        else if (sen_word_is(key, klen, "reach26")) {
            s = SvPV(val, vlen);
            if (sen_word_is(s, vlen, "exact"))    r->reach26 = SEN_REACH_EXACT;
            else if (sen_word_is(s, vlen, "any")) r->reach26 = SEN_REACH_ANY;
            else croak("Game::Senet::Engine: reach26 is 'exact' or 'any'");
        }
        else
            croak("Game::Senet::Engine: no rule is called '%" SVf "'",
                  SVfARG(HeSVKEY_force(he)));
    }
    if (!(SEN->rules_ok)(r))
        croak("Game::Senet::Engine: pieces is 1 to 7, blockade is 0, 2 or 3, and backward and throw_on_26 are 0 or 1");
}

static void sen_push_rules(pTHX_ SV **sp, const struct sen_rules *r)
{
    int h, roll, i;
    PUSHs(sv_2mortal(newSViv(r->pieces)));
    PUSHs(sv_2mortal(newSViv(r->blockade)));
    PUSHs(sv_2mortal(newSViv(r->protect)));
    PUSHs(sv_2mortal(newSViv(r->backward)));
    PUSHs(sv_2mortal(newSViv(r->reach26)));
    PUSHs(sv_2mortal(newSViv(r->throw_on_26)));
    PUSHs(sv_2mortal(newSVuv((UV) r->safe)));
    for (h = 0; h < SEN_EXIT_HOUSES; h++)
        for (roll = 0; roll < SEN_ROLL_MAX; roll++)
            for (i = 0; i < SEN_CHAIN_MAX; i++)
                PUSHs(sv_2mortal(newSViv(r->exit[h][roll][i])));
}

/* The weights of the evaluation cross as a hash reference, or as undef for the
 * plain evaluation, and an unknown key croaks, for the reason a rule's does. */
static void sen_weights_of_sv(pTHX_ SV *sv, struct sen_weights *w)
{
    HV *hv;
    HE *he;

    (SEN->weights_default)(w);
    if (!sv || !SvOK(sv)) return;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("Game::Senet::Engine: weights are a hash reference");
    hv = (HV *) SvRV(sv);

    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        STRLEN klen;
        const char *key = HePV(he, klen);
        int val = (int) SvIV(HeVAL(he));

        if      (sen_word_is(key, klen, "blockade")) w->blockade = val;
        else if (sen_word_is(key, klen, "ties"))     w->ties = val ? SEN_TIES_FIRST : SEN_TIES_LAST;
        else
            croak("Game::Senet::Engine: no weight is called '%" SVf "'",
                  SVfARG(HeSVKEY_force(he)));
    }
}

#define SEN_RULES_WORDS (7 + SEN_EXIT_HOUSES * SEN_ROLL_MAX * SEN_CHAIN_MAX)

MODULE = Game::Senet    PACKAGE = Game::Senet::Engine

PROTOTYPES: DISABLE

BOOT:
    SEN = sen_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(SEN);
    OUTPUT:
        RETVAL

UV
_abi_version()
    CODE:
        RETVAL = (UV)SEN->abi_version;
    OUTPUT:
        RETVAL

UV
_new_board(pieces)
        int pieces
    CODE:
        RETVAL = PTR2UV((SEN->board_new)(pieces));
    OUTPUT:
        RETVAL

UV
_copy_board(u)
        UV u
    CODE:
        RETVAL = PTR2UV((SEN->board_copy)(BOARD(u)));
    OUTPUT:
        RETVAL

void
_drop_board(u)
        UV u
    CODE:
        (SEN->board_drop)(BOARD(u));

# The board is let go by an object of its own, held by the board's object and
# freed with it. Its DESTROY is C and calls no perl.
SV *
_hold_board(u)
        UV u
    CODE:
        RETVAL = sv_setref_uv(newSV(0), "Game::Senet::Engine::Hold", u);
    OUTPUT:
        RETVAL

int
_live()
    CODE:
        RETVAL = (SEN->live)();
    OUTPUT:
        RETVAL

# A string that will not parse returns undef and the code, rather than
# croaking: the reason is what a caller shows a person, and nine of them are
# distinguishable.
void
_of_string(str)
        const char *str
    PREINIT:
        struct sen_board *b;
        int err = 0;
    PPCODE:
        b = (SEN->board_of_string)(str, &err);
        EXTEND(SP, 2);
        if (b) PUSHs(sv_2mortal(newSVuv(PTR2UV(b))));
        else   PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSViv(err)));

SV *
_to_string(u)
        UV u
    PREINIT:
        char buf[SEN_POS_MAX];
        int n;
    CODE:
        n = (SEN->to_string)(BOARD(u), buf, (int)sizeof(buf));
        if (n < 0) XSRETURN_UNDEF;
        RETVAL = newSVpvn(buf, (STRLEN)n);
    OUTPUT:
        RETVAL

int
_at(u, house)
        UV u
        int house
    CODE:
        RETVAL = (SEN->at)(BOARD(u), house);
    OUTPUT:
        RETVAL

void
_put(u, house, piece)
        UV u
        int house
        int piece
    CODE:
        (SEN->put)(BOARD(u), house, piece);

void
_lift(u, house)
        UV u
        int house
    CODE:
        (SEN->lift)(BOARD(u), house);

int
_side(u)
        UV u
    CODE:
        RETVAL = (SEN->side)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_side(u, side)
        UV u
        int side
    CODE:
        (SEN->set_side)(BOARD(u), side);

int
_pieces(u)
        UV u
    CODE:
        RETVAL = (SEN->pieces)(BOARD(u));
    OUTPUT:
        RETVAL

int
_count(u, side)
        UV u
        int side
    CODE:
        RETVAL = (SEN->count)(BOARD(u), side);
    OUTPUT:
        RETVAL

int
_home(u, side)
        UV u
        int side
    CODE:
        RETVAL = (SEN->home)(BOARD(u), side);
    OUTPUT:
        RETVAL

int
_consistent(u)
        UV u
    CODE:
        RETVAL = (SEN->consistent)(BOARD(u));
    OUTPUT:
        RETVAL

int
_ply(u)
        UV u
    CODE:
        RETVAL = (SEN->ply)(BOARD(u));
    OUTPUT:
        RETVAL

void
_set_ply(u, ply)
        UV u
        int ply
    CODE:
        (SEN->set_ply)(BOARD(u), ply);

SV *
_key_hex(u)
        UV u
    CODE:
        RETVAL = sen_hex64(aTHX_ (SEN->key)(BOARD(u)));
    OUTPUT:
        RETVAL

int
_house_of(row, col)
        int row
        int col
    CODE:
        RETVAL = (SEN->house_of)(row, col);
    OUTPUT:
        RETVAL

int
_row_of(house)
        int house
    CODE:
        RETVAL = (SEN->row_of)(house);
    OUTPUT:
        RETVAL

int
_col_of(house)
        int house
    CODE:
        RETVAL = (SEN->col_of)(house);
    OUTPUT:
        RETVAL

int
_is_marked(house)
        int house
    CODE:
        RETVAL = (SEN->is_marked)(house);
    OUTPUT:
        RETVAL

# The rule set a name or a hash stands for, flat: pieces, blockade, protect,
# backward, reach26, throw_on_26, the safe mask, then the 100 chain entries,
# house by house, roll by roll.
void
_rules(rules)
        SV *rules
    PREINIT:
        struct sen_rules r;
    PPCODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        EXTEND(SP, SEN_RULES_WORDS);
        sen_push_rules(aTHX_ SP, &r);
        SP += SEN_RULES_WORDS;

# The same flat list for a set by NUMBER, or nothing when there is no such set.
void
_rules_named(name)
        int name
    PREINIT:
        struct sen_rules r;
    PPCODE:
        if ((SEN->rules_named)(name, &r)) {
            EXTEND(SP, SEN_RULES_WORDS);
            sen_push_rules(aTHX_ SP, &r);
            SP += SEN_RULES_WORDS;
        }

int
_rules_id(name)
        const char *name
    CODE:
        RETVAL = (SEN->rules_id)(name);
    OUTPUT:
        RETVAL

# rules_ok on a struct written field by field, so that a test can hand it
# what no name and no hash would ever make.
int
_rules_ok_raw(pieces, blockade, protect, backward, reach26, throw_on_26, safe, chains, reserved)
        int pieces
        int blockade
        int protect
        int backward
        int reach26
        int throw_on_26
        UV safe
        SV *chains
        int reserved
    PREINIT:
        struct sen_rules r;
        AV *av;
        int h, roll, i, k = 0;
    CODE:
        if (!SvROK(chains) || SvTYPE(SvRV(chains)) != SVt_PVAV)
            croak("Game::Senet::Engine: the chains are an array reference");
        av = (AV *) SvRV(chains);
        if (av_len(av) + 1 != SEN_EXIT_HOUSES * SEN_ROLL_MAX * SEN_CHAIN_MAX)
            croak("Game::Senet::Engine: the chains are %d numbers",
                  SEN_EXIT_HOUSES * SEN_ROLL_MAX * SEN_CHAIN_MAX);
        Zero(&r, 1, struct sen_rules);
        r.pieces = pieces;
        r.blockade = blockade;
        r.protect = protect;
        r.backward = backward;
        r.reach26 = reach26;
        r.throw_on_26 = throw_on_26;
        r.safe = (unsigned long) safe;
        r.reserved[0] = reserved;
        for (h = 0; h < SEN_EXIT_HOUSES; h++)
            for (roll = 0; roll < SEN_ROLL_MAX; roll++)
                for (i = 0; i < SEN_CHAIN_MAX; i++) {
                    SV **e = av_fetch(av, k++, 0);
                    r.exit[h][roll][i] = (signed char) (e ? SvIV(*e) : 0);
                }
        RETVAL = (SEN->rules_ok)(&r);
    OUTPUT:
        RETVAL

# ---- version 2: the chance of a roll -------------------------------------------

int
_chance_count()
    CODE:
        RETVAL = (SEN->chance_count)();
    OUTPUT:
        RETVAL

# The roll, its weight and the denominator, or nothing when there is no such
# entry.
void
_chance(i)
        int i
    PREINIT:
        int roll = 0, weight = 0, denominator = 0;
    PPCODE:
        if ((SEN->chance)(i, &roll, &weight, &denominator)) {
            EXTEND(SP, 3);
            PUSHs(sv_2mortal(newSViv(roll)));
            PUSHs(sv_2mortal(newSViv(weight)));
            PUSHs(sv_2mortal(newSViv(denominator)));
        }

int
_extra(roll)
        int roll
    CODE:
        RETVAL = (SEN->extra)(roll);
    OUTPUT:
        RETVAL

# ---- version 3: what a roll allows ---------------------------------------------

int
_moves_max()
    CODE:
        RETVAL = SEN_MOVES_MAX;
    OUTPUT:
        RETVAL

# Each move as seven numbers in an array: from, to, roll, swap, back, off,
# walk. A roll
# that is not 1 to 5 croaks; it is not an empty list.
void
_moves(u, roll, rules, only)
        UV u
        int roll
        SV *rules
        int only
    PREINIT:
        struct sen_rules r;
        struct sen_move m[SEN_MOVES_MAX];
        int n, i;
    PPCODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        n = (SEN->moves)(BOARD(u), &r, roll, only, m, SEN_MOVES_MAX);
        if (n < 0)
            croak("Game::Senet::Engine: a roll is a whole number of houses from 1 to %d", SEN_ROLL_MAX);
        if (n > SEN_MOVES_MAX) n = SEN_MOVES_MAX;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *av = newAV();
            av_extend(av, 6);
            av_push(av, newSViv(m[i].from));
            av_push(av, newSViv(m[i].to));
            av_push(av, newSViv(m[i].roll));
            av_push(av, newSViv(m[i].swap));
            av_push(av, newSViv(m[i].back));
            av_push(av, newSViv(m[i].off));
            av_push(av, newSViv(m[i].walk));
            PUSHs(sv_2mortal(newRV_noinc((SV *) av)));
        }

# FOR A TEST, and nothing else: `count` random positions from a seeded
# generator of its own, each roll 1 to 5, the lists under protect `ends` and
# under protect `run` compared, with `blockade` as given and the rest of
# skyruk. Returns how many (position, roll) pairs were compared and how many
# DIFFERED. In C because 200,000 positions from Perl is minutes.
void
_compare_ends_run(count, seed, blockade)
        int count
        UV seed
        int blockade
    PREINIT:
        struct sen_rules ends, run;
        struct sen_move a[SEN_MOVES_MAX], c[SEN_MOVES_MAX];
        unsigned long long s;
        int i, roll, differ = 0, compared = 0;
    PPCODE:
        (SEN->rules_named)(SEN_RULES_SKYRUK, &ends);
        ends.blockade = blockade;
        ends.pieces = SEN_PIECES_MAX;
        run = ends;
        run.protect = SEN_PROTECT_RUN;
        if (!(SEN->rules_ok)(&ends))
            croak("Game::Senet::Engine: blockade is 0, 2 or 3");
        s = (unsigned long long) seed * 6364136223846793005ULL + 1442695040888963407ULL;
        for (i = 0; i < count; i++) {
            struct sen_board *b = (SEN->board_new)(SEN_PIECES_MAX);
            int side, placed;
            for (side = 0; side < 2; side++) {
                int want;
                s = s * 6364136223846793005ULL + 1442695040888963407ULL;
                want = (int) ((s >> 33) % (SEN_PIECES_MAX + 1));
                placed = 0;
                while (placed < want) {
                    int h;
                    s = s * 6364136223846793005ULL + 1442695040888963407ULL;
                    h = 1 + (int) ((s >> 33) % SEN_HOUSES);
                    if ((SEN->at)(b, h) != SEN_EMPTY) continue;
                    (SEN->put)(b, h, SEN_PIECE_OF(side));
                    placed++;
                }
            }
            s = s * 6364136223846793005ULL + 1442695040888963407ULL;
            (SEN->set_side)(b, (int) ((s >> 33) & 1));
            for (roll = 1; roll <= SEN_ROLL_MAX; roll++) {
                int na = (SEN->moves)(b, &ends, roll, 0, a, SEN_MOVES_MAX);
                int nc = (SEN->moves)(b, &run, roll, 0, c, SEN_MOVES_MAX);
                int k, same = (na == nc);
                for (k = 0; same && k < na; k++)
                    if (a[k].from != c[k].from || a[k].to != c[k].to || a[k].swap != c[k].swap
                        || a[k].back != c[k].back)
                        same = 0;
                compared++;
                if (!same) differ++;
            }
            (SEN->board_drop)(b);
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(compared)));
        PUSHs(sv_2mortal(newSViv(differ)));

# ---- version 4: a move made ------------------------------------------------------

int
_ply_cap()
    CODE:
        RETVAL = (SEN->ply_cap)();
    OUTPUT:
        RETVAL

# What apply hands back is the undo, as the bytes of the struct, and the house
# the next throw is bound to, or 0. The undo is opaque: the only thing to do
# with one is hand it to _unapply. Nothing when the move was not made.
void
_apply(u, rules, from, to, roll, off)
        UV u
        SV *rules
        int from
        int to
        int roll
        int off
    PREINIT:
        struct sen_rules r;
        struct sen_move m;
        struct sen_undo undo;
    PPCODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        Zero(&m, 1, struct sen_move);
        m.from = from;
        m.to = off ? -1 : to;
        m.roll = roll;
        m.off = off ? 1 : 0;
        if ((SEN->apply)(BOARD(u), &r, &m, &undo)) {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVpvn((const char *) &undo, sizeof(undo))));
            PUSHs(sv_2mortal(newSViv(undo.bound)));
        }

SV *
_forfeit(u, roll)
        UV u
        int roll
    PREINIT:
        struct sen_undo undo;
    CODE:
        (SEN->forfeit)(BOARD(u), roll, &undo);
        RETVAL = newSVpvn((const char *) &undo, sizeof(undo));
    OUTPUT:
        RETVAL

void
_unapply(u, token)
        UV u
        SV *token
    PREINIT:
        struct sen_undo undo;
        STRLEN len;
        const char *bytes;
    CODE:
        if (!SvOK(token) || SvROK(token))
            croak("Game::Senet::Engine: unapply takes what apply or forfeit returned");
        bytes = SvPVbyte(token, len);
        if (len != sizeof(undo))
            croak("Game::Senet::Engine: unapply takes what apply or forfeit returned");
        Copy(bytes, &undo, 1, struct sen_undo);
        (SEN->unapply)(BOARD(u), &undo);

int
_status(u)
        UV u
    CODE:
        RETVAL = (SEN->status)(BOARD(u));
    OUTPUT:
        RETVAL

int
_how(u)
        UV u
    CODE:
        RETVAL = (SEN->how)(BOARD(u));
    OUTPUT:
        RETVAL

int
_winner(u)
        UV u
    CODE:
        RETVAL = (SEN->winner)(BOARD(u));
    OUTPUT:
        RETVAL

SV *
_walk(u, depth, rules)
        UV u
        int depth
        SV *rules
    PREINIT:
        struct sen_rules r;
    CODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        RETVAL = sen_dec64(aTHX_ (SEN->walk)(BOARD(u), &r, depth));
    OUTPUT:
        RETVAL

# FOR A TEST, and nothing else: `count` random boards of `pieces` a side, light
# to move with ONE piece on 26 and every other piece of both sides placed at
# random on houses 1 to 15, and the kendall chain for a roll of 1, which is the
# walk. Returns how many boards the walk landed on and the lowest house it
# reached. In C because 200,000 boards from Perl is minutes.
void
_sample_walk(count, seed, pieces)
        int count
        UV seed
        int pieces
    PREINIT:
        struct sen_rules r;
        struct sen_move m[SEN_MOVES_MAX];
        unsigned long long s;
        int i, landed = 0, lowest = SEN_HOUSES + 1;
    PPCODE:
        if (pieces < 1 || pieces > SEN_PIECES_MAX)
            croak("Game::Senet::Engine: pieces is 1 to %d", SEN_PIECES_MAX);
        (SEN->rules_named)(SEN_RULES_KENDALL, &r);
        r.pieces = pieces;
        s = (unsigned long long) seed * 6364136223846793005ULL + 1442695040888963407ULL;
        for (i = 0; i < count; i++) {
            struct sen_board *b = (SEN->board_new)(pieces);
            int placed = 0, others = 2 * pieces - 1, n;
            (SEN->put)(b, 26, SEN_LIGHT);
            while (placed < others) {
                int h;
                s = s * 6364136223846793005ULL + 1442695040888963407ULL;
                h = 1 + (int) ((s >> 33) % SEN_REBIRTH);
                if ((SEN->at)(b, h) != SEN_EMPTY) continue;
                (SEN->put)(b, h, placed < pieces - 1 ? SEN_LIGHT : SEN_DARK);
                placed++;
            }
            n = (SEN->moves)(b, &r, 1, 26, m, SEN_MOVES_MAX);
            if (n == 1 && m[0].walk && m[0].to >= 1) {
                landed++;
                if (m[0].to < lowest) lowest = m[0].to;
            }
            (SEN->board_drop)(b);
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(landed)));
        PUSHs(sv_2mortal(newSViv(lowest)));

# ---- version 5: choosing a move ------------------------------------------------

int
_evaluate(u, rules, weights, side)
        UV u
        SV *rules
        SV *weights
        int side
    PREINIT:
        struct sen_rules r;
        struct sen_weights w;
    CODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        sen_weights_of_sv(aTHX_ weights, &w);
        RETVAL = (SEN->evaluate)(BOARD(u), &r, &w, side);
    OUTPUT:
        RETVAL

int
_greedy(u, roll, rules, only)
        UV u
        int roll
        SV *rules
        int only
    PREINIT:
        struct sen_rules r;
    CODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        RETVAL = (SEN->greedy)(BOARD(u), &r, roll, only);
    OUTPUT:
        RETVAL

# The index chosen, then the nodes spent as a string of digits, the depth
# finished, the value, and whether the budget ran out. A budget is a whole
# number of nodes from 0 to 2,000,000,000: more than that is refused, and does
# not wrap round on a perl whose integers are 32 bits.
void
_search(u, roll, rules, weights, budget, max_depth, only)
        UV u
        int roll
        SV *rules
        SV *weights
        IV budget
        int max_depth
        int only
    PREINIT:
        struct sen_rules r;
        struct sen_weights w;
        struct sen_search_info info;
        int chosen;
    PPCODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        sen_weights_of_sv(aTHX_ weights, &w);
        if (budget < 0 || budget > 2000000000)
            croak("Game::Senet::Engine: a budget is a number of nodes from 0 to 2000000000");
        chosen = (SEN->search)(BOARD(u), &r, roll, only, &w, (unsigned long long) budget, max_depth, &info);
        EXTEND(SP, 5);
        PUSHs(sv_2mortal(newSViv(chosen)));
        PUSHs(sv_2mortal(sen_dec64(aTHX_ info.nodes)));
        PUSHs(sv_2mortal(newSViv(info.depth)));
        PUSHs(sv_2mortal(newSViv(info.value)));
        PUSHs(sv_2mortal(newSViv(info.stopped)));

int
_expect(u, rules, weights, only, depth, side)
        UV u
        SV *rules
        SV *weights
        int only
        int depth
        int side
    PREINIT:
        struct sen_rules r;
        struct sen_weights w;
    CODE:
        sen_rules_of_sv(aTHX_ rules, &r);
        sen_weights_of_sv(aTHX_ weights, &w);
        RETVAL = (SEN->expect)(BOARD(u), &r, &w, only, depth, side);
    OUTPUT:
        RETVAL

MODULE = Game::Senet    PACKAGE = Game::Senet::Engine::Hold

PROTOTYPES: DISABLE

# ---- letting go -----------------------------------------------------------------
#
# WHY THIS IS NOT A DEMOLISH IN PERL. On perls 5.14 to 5.26 an eval that runs
# inside a destructor, while an exception is unwinding past a TEMPORARY of that
# class, leaves $@ empty: the caller's die arrives with no message. Object::Proto
# calls DEMOLISH under an eval, so any class with one has this. Game-Fanorona's
# packaging matrix found it; a DESTROY written in C runs no eval.

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
                (SEN->board_drop)(BOARD(u));
            }
        }
