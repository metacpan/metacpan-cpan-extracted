/* Mahjong.xs - the door to the C tile table.
 *
 * At the TOP of the distribution and not under lib/, for Game::Go's reason: an
 * XSMULTI build's export list and Strawberry's import library rule never agree
 * on a name.
 *
 * The XSUBs land in Game::Mahjong::Tiles. Every one that takes a kind checks
 * it and croaks with the distribution's own sentence on a number that names no
 * tile, because an off-table id is a programmer error and the house rule is
 * that programmer error dies where a refused move is returned.
 *
 * PHASE 01 SCOPE. This door reaches the table and nothing else. The decomposer
 * (phase 03) and the shanten (phase 07) append their own sections rather than
 * changing this one.
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "mahjong_abi.h"
#include "mahjong_decompose.h"
#include "mahjong_shanten.h"

static const struct mj_abi *MJ = NULL;

/* ---- the decomposer's helpers ------------------------------------------------ */

/* A counts arrayref crosses as thirty-five bytes. Index 0 is ignored, a
 * missing or undef element is 0, and a count outside 0 to 4 croaks: a hand
 * that holds five of a kind is a programmer error upstream. */
static void mj_counts_from_av(pTHX_ AV *av, unsigned char *c)
{
    int i;
    c[0] = 0;
    for (i = 1; i <= MJ_KINDS; i++) {
        SV **sv = av_fetch(av, i, 0);
        IV v = (sv && SvOK(*sv)) ? SvIV(*sv) : 0;
        if (v < 0 || v > MJ_PER_KIND)
            croak("Game::Mahjong::Decompose: a count is 0 to %d, not %" IVdf " for kind %d",
                  MJ_PER_KIND, v, i);
        c[i] = (unsigned char)v;
    }
}

static const char *SET_WORD[]  = { "", "chow", "pung", "knit" };
static const char *FORM_WORD[] = { "", "standard", "seven_pairs", "thirteen_orphans",
                                   "honours_knitted", "knitted_straight" };
static const char *IN_WORD[]   = { "", "set", "pair", "single" };
static const char *WAIT_WORD[] = { "", "edge", "closed", "two_sided", "pair", "pung",
                                   "single", "knit" };

static SV *mj_split_to_sv(pTHX_ const struct mj_split *s)
{
    HV *h = newHV();
    AV *sets = newAV();
    AV *singles = newAV();
    HV *place = newHV();
    int i;

    (void)hv_stores(h, "form", newSVpv(FORM_WORD[s->form], 0));
    for (i = 0; i < s->nsets; i++) {
        HV *set = newHV();
        AV *tiles = newAV();
        int j;
        for (j = 0; j < 3; j++) av_push(tiles, newSViv(s->sets[i].tiles[j]));
        (void)hv_stores(set, "kind", newSVpv(SET_WORD[s->sets[i].kind], 0));
        (void)hv_stores(set, "tiles", newRV_noinc((SV *)tiles));
        av_push(sets, newRV_noinc((SV *)set));
    }
    (void)hv_stores(h, "sets", newRV_noinc((SV *)sets));
    (void)hv_stores(h, "pair", s->pair ? newSViv(s->pair) : newSV(0));
    for (i = 0; i < s->nsingles; i++) av_push(singles, newSViv(s->singles[i]));
    (void)hv_stores(h, "singles", newRV_noinc((SV *)singles));
    (void)hv_stores(place, "in", s->place_in ? newSVpv(IN_WORD[s->place_in], 0) : newSV(0));
    (void)hv_stores(place, "index", newSViv(s->place_index));
    (void)hv_stores(place, "wait", s->wait ? newSVpv(WAIT_WORD[s->wait], 0) : newSV(0));
    (void)hv_stores(h, "placement", newRV_noinc((SV *)place));
    return newRV_noinc((SV *)h);
}

/* The suit letters as the Perl side spells them: the code's first letter for
 * a suit tile, undef for everything else. */
static const char SUIT_LETTER[] = { 0, 'm', 'p', 's', 0, 0, 0, 0 };

static int mj_kind_arg(pTHX_ SV *sv)
{
    IV id;
    if (!SvOK(sv) || !looks_like_number(sv))
        croak("Game::Mahjong::Tiles: a kind is a number from 1 to %d, not '%s'",
              MJ_PATTERNS, SvOK(sv) ? SvPV_nolen(sv) : "undef");
    id = SvIV(sv);
    if (id < 1 || id > MJ_PATTERNS)
        croak("Game::Mahjong::Tiles: there is no tile %" IVdf, id);
    return (int)id;
}

MODULE = Game::Mahjong    PACKAGE = Game::Mahjong::Tiles

PROTOTYPES: DISABLE

BOOT:
    MJ = mj_abi_table();

UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(MJ);
    OUTPUT:
        RETVAL

int
_abi_version()
    CODE:
        RETVAL = (int)MJ->version;
    OUTPUT:
        RETVAL

int
_abi_kinds()
    CODE:
        RETVAL = (int)MJ->patterns;
    OUTPUT:
        RETVAL

void
code_of(SV *kind)
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            XPUSHs(sv_2mortal(newSVpvn(MJ->kind[id].code, 2)));
            XSRETURN(1);
        }

void
id_of(SV *code)
    PPCODE:
        {
            int id;
            if (!SvOK(code))
                croak("Game::Mahjong::Tiles: a code is two letters, not undef");
            id = MJ->id_of(SvPV_nolen(code));
            if (!id)
                croak("Game::Mahjong::Tiles: there is no tile '%s'", SvPV_nolen(code));
            XSRETURN_IV(id);
        }

void
suit_of(SV *kind)
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            char letter = SUIT_LETTER[MJ->kind[id].suit];
            if (!letter) XSRETURN_UNDEF;
            XPUSHs(sv_2mortal(newSVpvn(&letter, 1)));
            XSRETURN(1);
        }

void
rank_of(SV *kind)
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            if (!(MJ->kind[id].flags & MJ_F_SUIT)) XSRETURN_UNDEF;
            XSRETURN_IV(MJ->kind[id].rank);
        }

void
wind_index(SV *kind)
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            if (!(MJ->kind[id].flags & MJ_F_WIND)) XSRETURN_UNDEF;
            XSRETURN_IV(MJ->kind[id].rank - 1);
        }

void
dragon_index(SV *kind)
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            if (!(MJ->kind[id].flags & MJ_F_DRAGON)) XSRETURN_UNDEF;
            XSRETURN_IV(MJ->kind[id].rank - 1);
        }

void
bonus_index(SV *kind)
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            if (!(MJ->kind[id].flags & MJ_F_BONUS)) XSRETURN_UNDEF;
            XSRETURN_IV(MJ->kind[id].rank - 1);
        }

void
flags_of(SV *kind)
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            XSRETURN_IV(MJ->kind[id].flags);
        }

# One XSUB, eleven names: the flag bit rides in ix. A C macro that stamped
# out eleven XSUBs would not survive xsubpp, which reads the file as XS and
# not as C.
void
is_suit(SV *kind)
    ALIAS:
        is_honour     = MJ_F_HONOUR
        is_wind       = MJ_F_WIND
        is_dragon     = MJ_F_DRAGON
        is_terminal   = MJ_F_TERMINAL
        is_simple     = MJ_F_SIMPLE
        is_bonus      = MJ_F_BONUS
        is_flower     = MJ_F_FLOWER
        is_season     = MJ_F_SEASON
        is_green      = MJ_F_GREEN
        is_reversible = MJ_F_REVERSIBLE
    PPCODE:
        {
            int id = mj_kind_arg(aTHX_ kind);
            unsigned bit = ix ? (unsigned)ix : MJ_F_SUIT;
            XSRETURN_IV((MJ->kind[id].flags & bit) ? 1 : 0);
        }

MODULE = Game::Mahjong    PACKAGE = Game::Mahjong::Decompose

# The decomposer's door. A counts arrayref (index 0 unused, 1 to 34 the
# kinds) crosses as thirty-five bytes; the splits come back as Perl
# structures the scorer and the bot read, with the forms, kinds and waits
# spelled out as words here so nothing in Perl knows a C enum.

void
_decompose(AV *counts, int melds, int winning)
    PPCODE:
        {
            unsigned char c[MJ_KINDS + 1];
            struct mj_split splits[MJ_MAX_SPLITS];
            int n, i;
            AV *list;
            mj_counts_from_av(aTHX_ counts, c);
            if (melds < 0 || melds > 4)
                croak("Game::Mahjong::Decompose: melds is 0 to 4, not %d", melds);
            if (winning < 0 || winning > MJ_KINDS)
                croak("Game::Mahjong::Decompose: a winning kind is 0 to %d, not %d", MJ_KINDS, winning);
            n = mj_decompose(c, melds, winning, splits, MJ_MAX_SPLITS);
            if (n < 0) XSRETURN_UNDEF;
            list = newAV();
            for (i = 0; i < n; i++)
                av_push(list, mj_split_to_sv(aTHX_ &splits[i]));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)list)));
            XSRETURN(1);
        }

int
_is_complete(AV *counts, int melds)
    CODE:
        {
            unsigned char c[MJ_KINDS + 1];
            mj_counts_from_av(aTHX_ counts, c);
            RETVAL = mj_is_complete(c, melds);
        }
    OUTPUT:
        RETVAL

void
_waits(AV *counts, int melds)
    PPCODE:
        {
            unsigned char c[MJ_KINDS + 1];
            unsigned char out[MJ_KINDS];
            int n, i;
            AV *list;
            mj_counts_from_av(aTHX_ counts, c);
            n = mj_waits(c, melds, out);
            list = newAV();
            for (i = 0; i < n; i++) av_push(list, newSViv(out[i]));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)list)));
            XSRETURN(1);
        }

MODULE = Game::Mahjong    PACKAGE = Game::Mahjong::Shanten

# The shanten's door: the same thirty-five bytes in, numbers out.

int
_shanten(AV *counts, int melds)
    CODE:
        {
            unsigned char c[MJ_KINDS + 1];
            mj_counts_from_av(aTHX_ counts, c);
            if (melds < 0 || melds > 4)
                croak("Game::Mahjong::Shanten: melds is 0 to 4, not %d", melds);
            RETVAL = mj_shanten(c, melds);
        }
    OUTPUT:
        RETVAL

void
_forms(AV *counts, int melds)
    PPCODE:
        {
            unsigned char c[MJ_KINDS + 1];
            int forms[MJ_FORM_S_COUNT], i;
            AV *list;
            mj_counts_from_av(aTHX_ counts, c);
            if (melds < 0 || melds > 4)
                croak("Game::Mahjong::Shanten: melds is 0 to 4, not %d", melds);
            mj_shanten_forms(c, melds, forms);
            list = newAV();
            for (i = 0; i < MJ_FORM_S_COUNT; i++) av_push(list, newSViv(forms[i]));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)list)));
            XSRETURN(1);
        }

void
_ukeire(AV *counts, int melds)
    PPCODE:
        {
            unsigned char c[MJ_KINDS + 1];
            unsigned char out[MJ_KINDS];
            int n, i;
            AV *list;
            mj_counts_from_av(aTHX_ counts, c);
            if (melds < 0 || melds > 4)
                croak("Game::Mahjong::Shanten: melds is 0 to 4, not %d", melds);
            n = mj_ukeire(c, melds, out);
            list = newAV();
            for (i = 0; i < n; i++) av_push(list, newSViv(out[i]));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)list)));
            XSRETURN(1);
        }
