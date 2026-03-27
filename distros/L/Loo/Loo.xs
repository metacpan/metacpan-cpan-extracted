#include "loo.h"

/* ── Accessor dispatch table ──────────────────────────────────── */
/* Maps ALIAS index → ( lowercase hash key, key length ) */

typedef struct {
    const char *key;
    STRLEN      klen;
} acc_entry;

static const acc_entry acc_table[] = {
    /* 0 */ { "indent",        6 },
    /* 1 */ { "pad",           3 },
    /* 2 */ { "varname",       7 },
    /* 3 */ { "terse",         5 },
    /* 4 */ { "purity",        6 },
    /* 5 */ { "useqq",         5 },
    /* 6 */ { "quotekeys",     9 },
    /* 7 */ { "maxdepth",      8 },
    /* 8 */ { "maxrecurse",   10 },
    /* 9 */ { "pair",          4 },
    /*10 */ { "trailingcomma", 13 },
    /*11 */ { "deepcopy",      8 },
    /*12 */ { "freezer",       7 },
    /*13 */ { "toaster",       7 },
    /*14 */ { "bless",         5 },
    /*15 */ { "deparse",       7 },
    /*16 */ { "sparseseen",   10 },
    /*17 */ { "indent_width", 12 },
    /*18 */ { "usetabs",       7 },
};

MODULE = Loo  PACKAGE = Loo

# ── _detect_colour ────────────────────────────────────────────────

int
_detect_colour()
    CODE:
        RETVAL = loo_detect_colour(aTHX);
    OUTPUT:
        RETVAL

# ── Constructor ───────────────────────────────────────────────────

SV *
new(class, values_ref = NULL, names_ref = NULL)
        const char *class
        SV *values_ref
        SV *names_ref
    PREINIT:
        HV *self;
        AV *values;
        AV *names;
        HV *colour_hv;
        const LooTheme *theme;
    CODE:
        self = newHV();

        /* values */
        if (values_ref && SvOK(values_ref) && SvROK(values_ref)
            && SvTYPE(SvRV(values_ref)) == SVt_PVAV)
            values = (AV *)SvRV(values_ref);
        else
            values = newAV();
        hv_store(self, "values", 6, newRV_inc((SV *)values), 0);

        /* names */
        if (names_ref && SvOK(names_ref) && SvROK(names_ref)
            && SvTYPE(SvRV(names_ref)) == SVt_PVAV)
            names = (AV *)SvRV(names_ref);
        else
            names = newAV();
        hv_store(self, "names", 5, newRV_inc((SV *)names), 0);

        /* Data::Dumper compat defaults */
        hv_store(self, "indent",        6, newSViv(2),  0);
        hv_store(self, "pad",           3, newSVpvs(""), 0);
        hv_store(self, "varname",       7, newSVpvs("VAR"), 0);
        hv_store(self, "terse",         5, newSViv(0),  0);
        hv_store(self, "purity",        6, newSViv(0),  0);
        hv_store(self, "useqq",         5, newSViv(0),  0);
        hv_store(self, "quotekeys",     9, newSViv(1),  0);
        hv_store(self, "sortkeys",      8, newSViv(0),  0);
        hv_store(self, "sortkeys_cb",  11, newSV(0),    0);  /* undef */
        hv_store(self, "maxdepth",      8, newSViv(0),  0);
        hv_store(self, "maxrecurse",   10, newSViv(1000), 0);
        hv_store(self, "pair",          4, newSVpvs(" => "), 0);
        hv_store(self, "trailingcomma",13, newSViv(0),  0);
        hv_store(self, "deepcopy",      8, newSViv(0),  0);
        hv_store(self, "freezer",       7, newSVpvs(""), 0);
        hv_store(self, "toaster",       7, newSVpvs(""), 0);
        hv_store(self, "bless",         5, newSVpvs("bless"), 0);
        hv_store(self, "deparse",       7, newSViv(0),  0);
        hv_store(self, "sparseseen",   10, newSViv(0),  0);
        hv_store(self, "indent_width", 12, newSViv(2),  0);
        hv_store(self, "usetabs",       7, newSViv(0),  0);

        /* Colour */
        hv_store(self, "use_colour", 10,
                 newSViv(loo_detect_colour(aTHX)), 0);

        colour_hv = newHV();
        theme = loo_find_theme("default");
        if (theme)
            loo_apply_theme(aTHX_ colour_hv, theme);
        hv_store(self, "colour", 6, newRV_noinc((SV *)colour_hv), 0);
        hv_store(self, "theme", 5, newSVpvs("default"), 0);

        RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashpv(class, GV_ADD));
    OUTPUT:
        RETVAL

# ── Accessor/mutators via ALIAS ───────────────────────────────────
# Single XSUB dispatching 17 methods.  Setting returns $self for chaining.

SV *
Indent(self, ...)
        SV *self
    ALIAS:
        Indent        = 0
        Pad           = 1
        Varname       = 2
        Terse         = 3
        Purity        = 4
        Useqq         = 5
        Quotekeys     = 6
        Maxdepth      = 7
        Maxrecurse    = 8
        Pair          = 9
        Trailingcomma = 10
        Deepcopy      = 11
        Freezer       = 12
        Toaster       = 13
        Bless         = 14
        Deparse       = 15
        Sparseseen    = 16
        Indentwidth   = 17
        Usetabs       = 18
    PREINIT:
        HV *hv;
        const acc_entry *e;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Not a hash reference");
        hv = (HV *)SvRV(self);
        e = &acc_table[ix];

        if (items > 1) {
            /* setter */
            hv_store(hv, e->key, e->klen, newSVsv(ST(1)), 0);
            RETVAL = SvREFCNT_inc_simple_NN(self);
        } else {
            /* getter */
            SV **svp = hv_fetch(hv, e->key, e->klen, 0);
            RETVAL = (svp && *svp) ? SvREFCNT_inc_simple_NN(*svp) : newSV(0);
        }
    OUTPUT:
        RETVAL

# ── Sortkeys (special case: 1/0/coderef) ─────────────────────────

SV *
Sortkeys(self, ...)
        SV *self
    PREINIT:
        HV *hv;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Not a hash reference");
        hv = (HV *)SvRV(self);

        if (items > 1) {
            SV *val = ST(1);
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV) {
                hv_store(hv, "sortkeys",    8, newSViv(1), 0);
                hv_store(hv, "sortkeys_cb", 11, newSVsv(val), 0);
            } else {
                int on = SvTRUE(val) ? 1 : 0;
                hv_store(hv, "sortkeys",    8, newSViv(on), 0);
                hv_store(hv, "sortkeys_cb", 11, newSV(0), 0);
            }
            RETVAL = SvREFCNT_inc_simple_NN(self);
        } else {
            SV **svp = hv_fetch(hv, "sortkeys", 8, 0);
            RETVAL = (svp && *svp) ? SvREFCNT_inc_simple_NN(*svp) : newSViv(0);
        }
    OUTPUT:
        RETVAL

# ── Colour ────────────────────────────────────────────────────────

SV *
Colour(self, ...)
        SV *self
    PREINIT:
        HV *hv;
        HV *colour_hv;
        SV **svp;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Not a hash reference");
        hv = (HV *)SvRV(self);

        /* Get or create colour sub-hash */
        svp = hv_fetch(hv, "colour", 6, 0);
        if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV)
            colour_hv = (HV *)SvRV(*svp);
        else {
            colour_hv = newHV();
            hv_store(hv, "colour", 6, newRV_noinc((SV *)colour_hv), 0);
        }

        if (items > 1) {
            /* setter: spec hashref */
            SV *spec_sv = ST(1);
            if (SvROK(spec_sv) && SvTYPE(SvRV(spec_sv)) == SVt_PVHV) {
                HV *spec = (HV *)SvRV(spec_sv);
                const char **elem;
                for (elem = loo_colour_elements; *elem; elem++) {
                    const char *base = *elem;
                    char keybuf[32];
                    int si;
                    for (si = 0; si < 2; si++) {
                        const char *suffix = si == 0 ? "_fg" : "_bg";
                        STRLEN kl;
                        SV **vp;
                        snprintf(keybuf, sizeof(keybuf), "%s%s", base, suffix);
                        kl = strlen(keybuf);
                        vp = hv_fetch(spec, keybuf, kl, 0);
                        if (vp)
                            hv_store(colour_hv, keybuf, kl, newSVsv(*vp), 0);
                    }
                }
            }
            RETVAL = SvREFCNT_inc_simple_NN(self);
        } else {
            /* getter: return colour hashref */
            RETVAL = newRV_inc((SV *)colour_hv);
        }
    OUTPUT:
        RETVAL

# ── Theme ─────────────────────────────────────────────────────────

SV *
Theme(self, ...)
        SV *self
    PREINIT:
        HV *hv;
    CODE:
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Not a hash reference");
        hv = (HV *)SvRV(self);

        if (items > 1) {
            const char *name = SvPV_nolen(ST(1));
            const LooTheme *theme = loo_find_theme(name);
            HV *colour_hv;
            SV **svp;

            if (!theme) {
                /* Build available names for error message */
                SV *msg = newSVpvf("Unknown theme '%s'. Available: ", name);
                const LooTheme *t;
                int first = 1;
                for (t = loo_themes; t->name; t++) {
                    if (!first) sv_catpvs(msg, ", ");
                    sv_catpv(msg, t->name);
                    first = 0;
                }
                sv_catpvs(msg, "\n");
                croak_sv(msg);
            }

            hv_store(hv, "theme", 5, newSVpv(name, 0), 0);

            svp = hv_fetch(hv, "colour", 6, 0);
            if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV)
                colour_hv = (HV *)SvRV(*svp);
            else {
                colour_hv = newHV();
                hv_store(hv, "colour", 6, newRV_noinc((SV *)colour_hv), 0);
            }
            loo_apply_theme(aTHX_ colour_hv, theme);
            RETVAL = SvREFCNT_inc_simple_NN(self);
        } else {
            SV **svp = hv_fetch(hv, "theme", 5, 0);
            RETVAL = (svp && *svp) ? SvREFCNT_inc_simple_NN(*svp) : newSVpvs("default");
        }
    OUTPUT:
        RETVAL

# ── Dump (OO + functional) ───────────────────────────────────────

SV *
Dump(...)
    PREINIT:
        SV *selfarg;
        HV *hv;
    CODE:
        if (items >= 1 && sv_isobject(ST(0))
            && sv_derived_from(ST(0), "Loo")) {
            /* OO call: $dd->Dump */
            selfarg = ST(0);
            hv = (HV *)SvRV(selfarg);
            RETVAL = ddc_dump_self(aTHX_ hv);
        } else {
            /* Functional call: Dump(@values) */
            AV *vals = newAV();
            int i;
            HV *tmp;
            SV *self_rv;
            const LooTheme *theme;
            HV *colour_hv;

            for (i = 0; i < items; i++)
                av_push(vals, newSVsv(ST(i)));

            /* Build a temporary Loo object */
            tmp = newHV();
            hv_store(tmp, "values", 6, newRV_noinc((SV *)vals), 0);
            hv_store(tmp, "names",  5, newRV_noinc((SV *)newAV()), 0);

            hv_store(tmp, "indent",        6, newSViv(2),  0);
            hv_store(tmp, "pad",           3, newSVpvs(""), 0);
            hv_store(tmp, "varname",       7, newSVpvs("VAR"), 0);
            hv_store(tmp, "terse",         5, newSViv(0),  0);
            hv_store(tmp, "purity",        6, newSViv(0),  0);
            hv_store(tmp, "useqq",         5, newSViv(0),  0);
            hv_store(tmp, "quotekeys",     9, newSViv(1),  0);
            hv_store(tmp, "sortkeys",      8, newSViv(0),  0);
            hv_store(tmp, "maxdepth",      8, newSViv(0),  0);
            hv_store(tmp, "maxrecurse",   10, newSViv(1000), 0);
            hv_store(tmp, "pair",          4, newSVpvs(" => "), 0);
            hv_store(tmp, "trailingcomma",13, newSViv(0),  0);
            hv_store(tmp, "deepcopy",      8, newSViv(0),  0);
            hv_store(tmp, "freezer",       7, newSVpvs(""), 0);
            hv_store(tmp, "toaster",       7, newSVpvs(""), 0);
            hv_store(tmp, "bless",         5, newSVpvs("bless"), 0);
            hv_store(tmp, "deparse",       7, newSViv(0),  0);
            hv_store(tmp, "sparseseen",   10, newSViv(0),  0);
            hv_store(tmp, "indent_width", 12, newSViv(2),  0);
            hv_store(tmp, "usetabs",       7, newSViv(0),  0);
            hv_store(tmp, "use_colour",   10,
                     newSViv(loo_detect_colour(aTHX)), 0);

            colour_hv = newHV();
            theme = loo_find_theme("default");
            if (theme)
                loo_apply_theme(aTHX_ colour_hv, theme);
            hv_store(tmp, "colour", 6, newRV_noinc((SV *)colour_hv), 0);

            RETVAL = ddc_dump_self(aTHX_ tmp);
            SvREFCNT_dec((SV *)tmp);
        }
    OUTPUT:
        RETVAL

# ── cDump ─────────────────────────────────────────────────────────

SV *
cDump(...)
    PREINIT:
        AV *vals;
        HV *tmp;
        HV *colour_hv;
        const LooTheme *theme;
        int i;
    CODE:
        vals = newAV();
        for (i = 0; i < items; i++)
            av_push(vals, newSVsv(ST(i)));

        tmp = newHV();
        hv_store(tmp, "values", 6, newRV_noinc((SV *)vals), 0);
        hv_store(tmp, "names",  5, newRV_noinc((SV *)newAV()), 0);

        hv_store(tmp, "indent",        6, newSViv(2),  0);
        hv_store(tmp, "pad",           3, newSVpvs(""), 0);
        hv_store(tmp, "varname",       7, newSVpvs("VAR"), 0);
        hv_store(tmp, "terse",         5, newSViv(0),  0);
        hv_store(tmp, "purity",        6, newSViv(0),  0);
        hv_store(tmp, "useqq",         5, newSViv(0),  0);
        hv_store(tmp, "quotekeys",     9, newSViv(1),  0);
        hv_store(tmp, "sortkeys",      8, newSViv(0),  0);
        hv_store(tmp, "maxdepth",      8, newSViv(0),  0);
        hv_store(tmp, "maxrecurse",   10, newSViv(1000), 0);
        hv_store(tmp, "pair",          4, newSVpvs(" => "), 0);
        hv_store(tmp, "trailingcomma",13, newSViv(0),  0);
        hv_store(tmp, "deepcopy",      8, newSViv(0),  0);
        hv_store(tmp, "freezer",       7, newSVpvs(""), 0);
        hv_store(tmp, "toaster",       7, newSVpvs(""), 0);
        hv_store(tmp, "bless",         5, newSVpvs("bless"), 0);
        hv_store(tmp, "deparse",       7, newSViv(0),  0);
        hv_store(tmp, "sparseseen",   10, newSViv(0),  0);
        hv_store(tmp, "indent_width", 12, newSViv(2),  0);
        hv_store(tmp, "usetabs",       7, newSViv(0),  0);
        hv_store(tmp, "use_colour",   10, newSViv(1), 0);

        colour_hv = newHV();
        theme = loo_find_theme("default");
        if (theme)
            loo_apply_theme(aTHX_ colour_hv, theme);
        hv_store(tmp, "colour", 6, newRV_noinc((SV *)colour_hv), 0);

        RETVAL = ddc_dump_self(aTHX_ tmp);
        SvREFCNT_dec((SV *)tmp);
    OUTPUT:
        RETVAL

# ── ncDump ────────────────────────────────────────────────────────

SV *
ncDump(...)
    PREINIT:
        AV *vals;
        HV *tmp;
        int i;
    CODE:
        vals = newAV();
        for (i = 0; i < items; i++)
            av_push(vals, newSVsv(ST(i)));

        tmp = newHV();
        hv_store(tmp, "values", 6, newRV_noinc((SV *)vals), 0);
        hv_store(tmp, "names",  5, newRV_noinc((SV *)newAV()), 0);

        hv_store(tmp, "indent",        6, newSViv(2),  0);
        hv_store(tmp, "pad",           3, newSVpvs(""), 0);
        hv_store(tmp, "varname",       7, newSVpvs("VAR"), 0);
        hv_store(tmp, "terse",         5, newSViv(0),  0);
        hv_store(tmp, "purity",        6, newSViv(0),  0);
        hv_store(tmp, "useqq",         5, newSViv(0),  0);
        hv_store(tmp, "quotekeys",     9, newSViv(1),  0);
        hv_store(tmp, "sortkeys",      8, newSViv(0),  0);
        hv_store(tmp, "maxdepth",      8, newSViv(0),  0);
        hv_store(tmp, "maxrecurse",   10, newSViv(1000), 0);
        hv_store(tmp, "pair",          4, newSVpvs(" => "), 0);
        hv_store(tmp, "trailingcomma",13, newSViv(0),  0);
        hv_store(tmp, "deepcopy",      8, newSViv(0),  0);
        hv_store(tmp, "freezer",       7, newSVpvs(""), 0);
        hv_store(tmp, "toaster",       7, newSVpvs(""), 0);
        hv_store(tmp, "bless",         5, newSVpvs("bless"), 0);
        hv_store(tmp, "deparse",       7, newSViv(0),  0);
        hv_store(tmp, "sparseseen",   10, newSViv(0),  0);
        hv_store(tmp, "indent_width", 12, newSViv(2),  0);
        hv_store(tmp, "usetabs",       7, newSViv(0),  0);
        hv_store(tmp, "use_colour",   10, newSViv(0),  0);

        hv_store(tmp, "colour", 6, newRV_noinc((SV *)newHV()), 0);

        RETVAL = ddc_dump_self(aTHX_ tmp);
        SvREFCNT_dec((SV *)tmp);
    OUTPUT:
        RETVAL

# ── dDump ─────────────────────────────────────────────────────────

SV *
dDump(...)
    PREINIT:
        AV *vals;
        HV *tmp;
        HV *colour_hv;
        const LooTheme *theme;
        int i;
    CODE:
        vals = newAV();
        for (i = 0; i < items; i++)
            av_push(vals, newSVsv(ST(i)));

        tmp = newHV();
        hv_store(tmp, "values", 6, newRV_noinc((SV *)vals), 0);
        hv_store(tmp, "names",  5, newRV_noinc((SV *)newAV()), 0);

        hv_store(tmp, "indent",        6, newSViv(2),  0);
        hv_store(tmp, "pad",           3, newSVpvs(""), 0);
        hv_store(tmp, "varname",       7, newSVpvs("VAR"), 0);
        hv_store(tmp, "terse",         5, newSViv(0),  0);
        hv_store(tmp, "purity",        6, newSViv(0),  0);
        hv_store(tmp, "useqq",         5, newSViv(0),  0);
        hv_store(tmp, "quotekeys",     9, newSViv(1),  0);
        hv_store(tmp, "sortkeys",      8, newSViv(0),  0);
        hv_store(tmp, "maxdepth",      8, newSViv(0),  0);
        hv_store(tmp, "maxrecurse",   10, newSViv(1000), 0);
        hv_store(tmp, "pair",          4, newSVpvs(" => "), 0);
        hv_store(tmp, "trailingcomma",13, newSViv(0),  0);
        hv_store(tmp, "deepcopy",      8, newSViv(0),  0);
        hv_store(tmp, "freezer",       7, newSVpvs(""), 0);
        hv_store(tmp, "toaster",       7, newSVpvs(""), 0);
        hv_store(tmp, "bless",         5, newSVpvs("bless"), 0);
        hv_store(tmp, "deparse",       7, newSViv(1),  0);
        hv_store(tmp, "sparseseen",   10, newSViv(0),  0);
        hv_store(tmp, "indent_width", 12, newSViv(2),  0);
        hv_store(tmp, "usetabs",       7, newSViv(0),  0);
        hv_store(tmp, "use_colour",   10,
                 newSViv(loo_detect_colour(aTHX)), 0);

        colour_hv = newHV();
        theme = loo_find_theme("default");
        if (theme)
            loo_apply_theme(aTHX_ colour_hv, theme);
        hv_store(tmp, "colour", 6, newRV_noinc((SV *)colour_hv), 0);

        RETVAL = ddc_dump_self(aTHX_ tmp);
        SvREFCNT_dec((SV *)tmp);
    OUTPUT:
        RETVAL

# ── strip_colour ──────────────────────────────────────────────────

SV *
strip_colour(input)
        SV *input
    CODE:
        RETVAL = ddc_strip_colour(aTHX_ input);
    OUTPUT:
        RETVAL

# ── Legacy XS entry points (kept for compatibility) ──────────────

SV *
_xs_dump(values_av, names_av, config_hv)
        AV *values_av
        AV *names_av
        HV *config_hv
    CODE:
        RETVAL = ddc_dump_top(aTHX_ values_av, names_av, config_hv);
    OUTPUT:
        RETVAL

SV *
_xs_strip_colour(input)
        SV *input
    CODE:
        RETVAL = ddc_strip_colour(aTHX_ input);
    OUTPUT:
        RETVAL
