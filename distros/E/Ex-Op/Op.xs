#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_caller_cx
#define NEED_mg_findext
#include "ppport.h"

#include "xop_compat.h"
#include "ex_op_compat.h"
#include "ex_op.h"
#include "ex_op_reg.h"

START_MY_CXT

#include "ex_op_call.h"
#include "ex_op_kw.h"

static void
eo_cxt_init(pTHX_ my_cxt_t *cxt)
{
    cxt->exports        = newHV();
    cxt->ret            = NULL;
    cxt->ret_top        = 0;
    cxt->ret_max        = 0;
    cxt->level_gv       = gv_fetchpvs("Ex::Op::ExportLevel", GV_ADDMULTI, SVt_PV);
    cxt->verbose_gv     = gv_fetchpvs("Ex::Op::Verbose", GV_ADDMULTI, SVt_PV);
    if (!SvOK(GvSVn(cxt->level_gv)))
        sv_setiv(GvSVn(cxt->level_gv), 0);
    if (!SvOK(GvSVn(cxt->verbose_gv)))
        sv_setiv(GvSVn(cxt->verbose_gv), 0);
    cxt->import_cv      = get_cvs("Ex::Op::import", 0);
    cxt->export_cv      = get_cvs("Ex::Op::export", 0);
    cxt->export_fail_cv = get_cvs("Ex::Op::export_fail", 0);
}

/* What Exporter's caller($level) sees from inside an exporter sub. An XSUB
 * has no frame of its own, so level 0 is the statement that called it and
 * level N is the call site of the Perl frame N-1 above it. */
static const COP *
eo_caller_cop(pTHX_ IV level)
{
    const PERL_CONTEXT *cx;
    if (level <= 0)
        return PL_curcop;
    cx = caller_cx((I32)(level - 1), NULL);
    return cx ? cx->blk_oldcop : NULL;
}

static SV *
eo_stash_name(pTHX_ HV *stash)
{
    if (!stash || !HvNAME_get(stash))
        return newSVpvs_flags("main", SVs_TEMP);
    return newSVpvn_flags(HvNAME_get(stash), HvNAMELEN_get(stash),
                          SVs_TEMP | (HvNAMEUTF8(stash) ? SVf_UTF8 : 0));
}

static SV *
eo_qualify(pTHX_ SV *pkg, const char *name, STRLEN len, bool utf8)
{
    SV *full = newSVsv(pkg);
    sv_2mortal(full);
    sv_catpvs(full, "::");
    if (utf8 && !SvUTF8(full))
        sv_utf8_upgrade(full);
    if (SvUTF8(full) && !utf8) {
        SV *tail = newSVpvn_flags(name, len, SVs_TEMP);
        sv_catsv(full, tail);
    }
    else {
        sv_catpvn(full, name, len);
    }
    return full;
}

/* The glob a plain name already has in a stash, found without building
 * "Pkg::name". NULL for a qualified or UTF-8 name, or one with no glob yet. */
static GV *
eo_stash_gv(pTHX_ HV *stash, const char *name, STRLEN len, bool utf8)
{
    SV **svp;
    if (!stash || utf8 || !len || memchr(name, ':', len) || memchr(name, '\'', len))
        return NULL;
    svp = hv_fetch(stash, name, (I32)len, 0);
    return (svp && isGV_with_GP(*svp)) ? (GV *)*svp : NULL;
}

/* The same, made when it is not there yet, for a name gv_fetchpvn would
 * give nothing special: two or more word characters, the first lower case
 * or an underscore. EXPORT, ISA, VERSION, ARGV, SIG, ENV, STDIN, $a, $b and
 * the rest all start otherwise, and go the long way. */
static GV *
eo_stash_gv_add(pTHX_ HV *stash, const char *name, STRLEN len, bool utf8)
{
    GV *gv = eo_stash_gv(aTHX_ stash, name, len, utf8);
    STRLEN i;
    SV **svp;
    if (gv || !stash || utf8 || len < 2 || !(isLOWER(*name) || *name == '_'))
        return gv;
    for (i = 1; i < len; i++)
        if (!isWORDCHAR(name[i]))
            return NULL;
    svp = hv_fetch(stash, name, (I32)len, 1);
    if (!svp)
        return NULL;
    if (!isGV_with_GP(*svp))
        gv_init((GV *)*svp, stash, name, len, TRUE);
    return isGV_with_GP(*svp) ? (GV *)*svp : NULL;
}

static GV *
eo_pkg_gv(pTHX_ SV *pkg, const char *name, STRLEN len, svtype type)
{
    GV *gv = eo_stash_gv(aTHX_ gv_stashsv(pkg, 0), name, len, FALSE);
    if (gv)
        return gv;
    gv = gv_fetchsv(eo_qualify(aTHX_ pkg, name, len, FALSE), 0, type);
    return (gv && isGV_with_GP(gv)) ? gv : NULL;
}

static AV *
eo_pkg_av(pTHX_ SV *pkg, const char *name, STRLEN len)
{
    GV *gv = eo_pkg_gv(aTHX_ pkg, name, len, SVt_PVAV);
    return gv ? GvAV(gv) : NULL;
}

static HV *
eo_pkg_hv(pTHX_ SV *pkg, const char *name, STRLEN len)
{
    GV *gv = eo_pkg_gv(aTHX_ pkg, name, len, SVt_PVHV);
    return gv ? GvHV(gv) : NULL;
}

static SV *
eo_strip_amp(pTHX_ SV *sv)
{
    STRLEN len;
    const char *s = SvPV_const(sv, len);
    if (len && *s == '&') {
        s++;
        len--;
    }
    return newSVpvn_flags(s, len, SVs_TEMP | (SvUTF8(sv) ? SVf_UTF8 : 0));
}

/* Exporter's _rebuild_cache runs s/^&// over @EXPORT and @EXPORT_OK
 * themselves, so after the first import with a list :DEFAULT names d2, not
 * &d2. The arrays are changed in place here too. */
static void
eo_add_names(pTHX_ HV *set, AV *av)
{
    SSize_t i, top;
    if (!av)
        return;
    top = av_len(av);
    for (i = 0; i <= top; i++) {
        SV **svp = av_fetch(av, i, 0);
        STRLEN len;
        const char *s;
        if (!svp)
            continue;
        s = SvPV_const(*svp, len);
        if (len && *s == '&')
            sv_chop(*svp, s + 1);
        (void)hv_store_ent(set, *svp, &PL_sv_yes, 0);
    }
}

static void
eo_av_append(pTHX_ AV *to, AV *from)
{
    SSize_t i, top;
    if (!from)
        return;
    top = av_len(from);
    for (i = 0; i <= top; i++) {
        SV **svp = av_fetch(from, i, 0);
        av_push(to, svp ? newSVsv(*svp) : newSV(0));
    }
}

static AV *
eo_av_copy(pTHX_ AV *from)
{
    AV *to = (AV *)sv_2mortal((SV *)newAV());
    eo_av_append(aTHX_ to, from);
    return to;
}

static SV *
eo_join(pTHX_ AV *av, const char *sep)
{
    SV *out = sv_2mortal(newSVpvs(""));
    SSize_t i, top = av_len(av);
    for (i = 0; i <= top; i++) {
        SV **svp = av_fetch(av, i, 0);
        if (i)
            sv_catpv(out, sep);
        if (svp)
            sv_catsv(out, *svp);
    }
    return out;
}

/* The set of exportable names for a package, with & stripped, as
 * Exporter's %Cache holds it. It is rebuilt when @EXPORT or @EXPORT_OK has
 * been replaced or changed size, and by the caller on a miss, as Exporter
 * rebuilds on a miss. */
static HV *
eo_cache_build(pTHX_ SV *pkg, AV *exp, AV *ok)
{
    dMY_CXT;
    HV *set = newHV();
    AV *entry = newAV();
    eo_add_names(aTHX_ set, exp);
    eo_add_names(aTHX_ set, ok);
    av_store(entry, EO_CACHE_SET,  newRV_noinc((SV *)set));
    av_store(entry, EO_CACHE_EXP,  exp ? newRV_inc((SV *)exp) : newSV(0));
    av_store(entry, EO_CACHE_OK,   ok  ? newRV_inc((SV *)ok)  : newSV(0));
    av_store(entry, EO_CACHE_NEXP, newSViv(exp ? av_len(exp) : -2));
    av_store(entry, EO_CACHE_NOK,  newSViv(ok  ? av_len(ok)  : -2));
    (void)hv_store_ent(MY_CXT.exports, pkg, newRV_noinc((SV *)entry), 0);
    return set;
}

static bool
eo_cache_same(pTHX_ AV *entry, I32 slot, I32 nslot, AV *av)
{
    SV **ref = av_fetch(entry, slot, 0);
    SV **n   = av_fetch(entry, nslot, 0);
    AV *had;
    if (!ref || !n)
        return FALSE;
    had = SvROK(*ref) ? (AV *)SvRV(*ref) : NULL;
    if (had != av)
        return FALSE;
    return SvIV(*n) == (av ? av_len(av) : -2);
}

static HV *
eo_cache_get(pTHX_ SV *pkg, AV *exp, AV *ok, bool *built)
{
    dMY_CXT;
    HE *he = hv_fetch_ent(MY_CXT.exports, pkg, 0, 0);
    if (he && SvROK(HeVAL(he))) {
        AV *entry = (AV *)SvRV(HeVAL(he));
        if (eo_cache_same(aTHX_ entry, EO_CACHE_EXP, EO_CACHE_NEXP, exp)
         && eo_cache_same(aTHX_ entry, EO_CACHE_OK, EO_CACHE_NOK, ok)) {
            SV **set = av_fetch(entry, EO_CACHE_SET, 0);
            *built = FALSE;
            return (HV *)SvRV(*set);
        }
    }
    *built = TRUE;
    return eo_cache_build(aTHX_ pkg, exp, ok);
}

static bool
eo_is_word_start(const char *s, STRLEN len, bool utf8)
{
    U8 c;
    if (!len)
        return TRUE;
    c = (U8)*s;
    if (utf8 && c >= 0x80)
        return TRUE;
    return isWORDCHAR(c) ? TRUE : FALSE;
}

static void eo_install_slow(pTHX_ SV *pkg, SV *callpkg, SV *name);

/* The usual install: a plain name in two stashes, both found once for the
 * whole import. Anything else goes the long way, by full name. */
static void
eo_install_one(pTHX_ SV *pkg, SV *callpkg, HV *srcstash, HV *dststash, SV *name)
{
    STRLEN len;
    const char *s = SvPV_const(name, len);
    bool utf8 = SvUTF8(name) ? TRUE : FALSE;
    char type = '&';
    GV *src, *dgv;
    SV *thing, *ref;

    if (utf8 || !len) {
        eo_install_slow(aTHX_ pkg, callpkg, name);
        return;
    }
    if (!isWORDCHAR(*s)) {
        type = *s;
        s++;
        len--;
    }
    src = eo_stash_gv(aTHX_ srcstash, s, len, FALSE);
    if (!src) {
        eo_install_slow(aTHX_ pkg, callpkg, name);
        return;
    }
    switch (type) {
    case '&': thing = (SV *)GvCVu(src);    break;
    case '$': thing = GvSVn(src);           break;
    case '@': thing = (SV *)GvAVn(src);    break;
    case '%': thing = (SV *)GvHVn(src);    break;
    case '*': thing = (SV *)src;           break;
    default:  thing = NULL;                  break;
    }
    if (!thing || !(dgv = eo_stash_gv_add(aTHX_ dststash, s, len, FALSE))) {
        eo_install_slow(aTHX_ pkg, callpkg, name);
        return;
    }

    if (type == '*') {
        sv_setsv_mg((SV *)dgv, thing);
        GvIMPORTED_on(dgv);
        return;
    }
    ref = newRV_inc(thing);
    sv_setsv_mg((SV *)dgv, ref);
    SvREFCNT_dec(ref);
    switch (type) {
    case '&': GvIMPORTED_CV_on(dgv); break;
    case '$': GvIMPORTED_SV_on(dgv); break;
    case '@': GvIMPORTED_AV_on(dgv); break;
    case '%': GvIMPORTED_HV_on(dgv); break;
    }
}

static void
eo_install_slow(pTHX_ SV *pkg, SV *callpkg, SV *name)
{
    STRLEN len;
    const char *s = SvPV_const(name, len);
    bool utf8 = SvUTF8(name) ? TRUE : FALSE;
    char type = '&';
    SV *src, *dst, *ref;
    GV *gv, *dgv;

    if (!eo_is_word_start(s, len, utf8)) {
        type = *s;
        s++;
        len--;
    }

    src = eo_qualify(aTHX_ pkg, s, len, utf8);
    dst = eo_qualify(aTHX_ callpkg, s, len, utf8);

    switch (type) {
    case '&': {
        HV *st;
        CV *cv = sv_2cv(src, &st, &gv, GV_ADDMULTI);
        ref = sv_2mortal(newRV_inc((SV *)cv));
        break;
    }
    case '$':
        gv = gv_fetchsv(src, GV_ADDMULTI, SVt_PV);
        ref = sv_2mortal(newRV_inc(GvSVn(gv)));
        break;
    case '@':
        gv = gv_fetchsv(src, GV_ADDMULTI, SVt_PVAV);
        ref = sv_2mortal(newRV_inc((SV *)GvAVn(gv)));
        break;
    case '%':
        gv = gv_fetchsv(src, GV_ADDMULTI, SVt_PVHV);
        ref = sv_2mortal(newRV_inc((SV *)GvHVn(gv)));
        break;
    case '*':
        ref = (SV *)gv_fetchsv(src, GV_ADDMULTI, SVt_PVGV);
        break;
    default:
        Perl_croak(aTHX_ "Can't export symbol: %c%" SVf, type,
                   SVfARG(newSVpvn_flags(s, len, SVs_TEMP | (utf8 ? SVf_UTF8 : 0))));
    }

    dgv = gv_fetchsv(dst, GV_ADDMULTI, SVt_PVGV);
    sv_setsv_mg((SV *)dgv, ref);

    switch (type) {
    case '&': GvIMPORTED_CV_on(dgv); break;
    case '$': GvIMPORTED_SV_on(dgv); break;
    case '@': GvIMPORTED_AV_on(dgv); break;
    case '%': GvIMPORTED_HV_on(dgv); break;
    case '*': GvIMPORTED_on(dgv);    break;
    }
}

/* Exporter assigns the globs from its own file, which has no lexical
 * warnings, so a redefinition warns only under $^W. The copy of the caller's
 * statement keeps its file and line for the message and drops its warnings. */
static void
eo_install_list(pTHX_ SV *pkg, SV *callpkg, HV *srcstash, SV **list, SSize_t n)
{
    COP fake;
    SSize_t i;

    ENTER;
    StructCopy(PL_curcop, &fake, COP);
    fake.cop_warnings = pWARN_STD;
    SAVEVPTR(PL_curcop);
    PL_curcop = &fake;

    {
        HV *dststash = gv_stashsv(callpkg, GV_ADD);
        for (i = 0; i < n; i++)
            if (list[i])
                eo_install_one(aTHX_ pkg, callpkg, srcstash, dststash, list[i]);
    }

    LEAVE;
}

static void
eo_install(pTHX_ SV *pkg, SV *callpkg, AV *names)
{
    eo_install_list(aTHX_ pkg, callpkg, gv_stashsv(pkg, 0), AvARRAY(names), av_len(names) + 1);
}

static void
eo_call_version(pTHX_ SV *pkg, SV *wanted)
{
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(pkg);
    XPUSHs(wanted);
    PUTBACK;
    call_method("VERSION", G_DISCARD);
    FREETMPS;
    LEAVE;
}

/* The names in a list of specs, in the order first added. Exporter keeps
 * them in a hash, so its order is the hash's; the set is the same. */
typedef struct {
    AV *order;
    HV *at;
} eo_picks;

static void
eo_pick(pTHX_ eo_picks *p, SV *name, bool remove)
{
    if (remove) {
        (void)hv_delete_ent(p->at, name, G_DISCARD, 0);
    }
    else if (!hv_exists_ent(p->at, name, 0)) {
        av_push(p->order, newSVsv(name));
        (void)hv_store_ent(p->at, name, newSViv(av_len(p->order)), 0);
    }
}

static AV *
eo_picked(pTHX_ eo_picks *p)
{
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    SSize_t i, top = av_len(p->order);
    for (i = 0; i <= top; i++) {
        SV *name = *av_fetch(p->order, i, 0);
        HE *he = hv_fetch_ent(p->at, name, 0, 0);
        if (he && SvIV(HeVAL(he)) == i)
            av_push(out, newSVsv(name));
    }
    return out;
}

static bool
eo_has_specs(pTHX_ AV *names)
{
    SSize_t i, top = av_len(names);
    for (i = 0; i <= top; i++) {
        STRLEN len;
        const char *s = SvPV_const(*av_fetch(names, i, 0), len);
        if (len && (*s == '/' || *s == '!' || *s == ':'))
            return TRUE;
    }
    return FALSE;
}

static AV *
eo_all_exports(pTHX_ AV *exp, AV *ok)
{
    AV *all = (AV *)sv_2mortal((SV *)newAV());
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    AV *lists[2];
    int l;
    lists[0] = exp;
    lists[1] = ok;
    for (l = 0; l < 2; l++) {
        SSize_t i, top;
        if (!lists[l])
            continue;
        top = av_len(lists[l]);
        for (i = 0; i <= top; i++) {
            SV **svp = av_fetch(lists[l], i, 0);
            SV *name;
            if (!svp)
                continue;
            name = eo_strip_amp(aTHX_ *svp);
            if (hv_exists_ent(seen, name, 0))
                continue;
            (void)hv_store_ent(seen, name, &PL_sv_yes, 0);
            av_push(all, newSVsv(name));
        }
    }
    return all;
}

static void
eo_grep(pTHX_ AV *into, AV *from, const char *pat, STRLEN plen, bool utf8)
{
    SV *patsv = newSVpvn_flags(pat, plen, SVs_TEMP | (utf8 ? SVf_UTF8 : 0));
    REGEXP *rx;
    COP fake;
    SSize_t i, top = av_len(from);

    ENTER;
    StructCopy(PL_curcop, &fake, COP);
    fake.cop_hints = 0;
    SAVEVPTR(PL_curcop);
    PL_curcop = &fake;
    SAVEI32(*(I32 *)&PL_hints);
    PL_hints = 0;
    rx = pregcomp(patsv, 0);
    LEAVE;

    for (i = 0; i <= top; i++) {
        SV *name = *av_fetch(from, i, 0);
        STRLEN len;
        char *s = SvPV(name, len);
        if (pregexec(rx, s, s + len, s, 0, name, 1))
            av_push(into, newSVsv(name));
    }
    ReREFCNT_dec(rx);
}

static AV *
eo_walk_specs(pTHX_ SV *pkg, AV *specs, AV *exp, AV *ok, bool verbose, I32 *oops)
{
    HV *tags = eo_pkg_hv(aTHX_ pkg, STR_WITH_LEN("EXPORT_TAGS"));
    AV *all = NULL;
    eo_picks p;
    SSize_t i, top;

    p.order = (AV *)sv_2mortal((SV *)newAV());
    p.at    = (HV *)sv_2mortal((SV *)newHV());

    if (av_len(specs) >= 0) {
        STRLEN len;
        const char *s = SvPV_const(*av_fetch(specs, 0, 0), len);
        if (len && *s == '!')
            av_unshift(specs, 1), av_store(specs, 0, newSVpvs(":DEFAULT"));
    }

    top = av_len(specs);
    for (i = 0; i <= top; i++) {
        SV *spec = *av_fetch(specs, i, 0);
        AV *names = (AV *)sv_2mortal((SV *)newAV());
        STRLEN len;
        const char *s = SvPV_const(spec, len);
        bool utf8 = SvUTF8(spec) ? TRUE : FALSE;
        bool remove = FALSE;
        SSize_t j, ntop;

        if (len && *s == '!') {
            remove = TRUE;
            s++;
            len--;
        }

        if (len && *s == ':') {
            SV *tag = newSVpvn_flags(s + 1, len - 1, SVs_TEMP | (utf8 ? SVf_UTF8 : 0));
            HE *he;
            if (len - 1 == 7 && memEQ(s + 1, "DEFAULT", 7)) {
                eo_av_append(aTHX_ names, exp);
            }
            else if (tags && (he = hv_fetch_ent(tags, tag, 0, 0)) && SvTRUE(HeVAL(he))) {
                SV *val = HeVAL(he);
                if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
                    Perl_croak(aTHX_ "Not an ARRAY reference");
                eo_av_append(aTHX_ names, (AV *)SvRV(val));
            }
            else {
                Perl_warn(aTHX_ "\"%" SVf "\" is not defined in %%%" SVf "::EXPORT_TAGS",
                          SVfARG(tag), SVfARG(pkg));
                ++*oops;
                continue;
            }
        }
        else if (len >= 2 && *s == '/'
                 && (s[len - 1] == '/' || (len >= 3 && s[len - 1] == '\n' && s[len - 2] == '/'))) {
            STRLEN plen = s[len - 1] == '/' ? len - 2 : len - 3;
            if (!all)
                all = eo_all_exports(aTHX_ exp, ok);
            eo_grep(aTHX_ names, all, s + 1, plen, utf8);
        }
        else {
            av_push(names, newSVpvn_flags(s, len, utf8 ? SVf_UTF8 : 0));
        }

        if (verbose)
            Perl_warn(aTHX_ "Import %s: %" SVf " ", remove ? "del" : "add",
                      SVfARG(eo_join(aTHX_ names, " ")));

        ntop = av_len(names);
        for (j = 0; j <= ntop; j++)
            eo_pick(aTHX_ &p, *av_fetch(names, j, 0), remove);
    }

    return eo_picked(aTHX_ &p);
}

static AV *
eo_call_export_fail(pTHX_ SV *pkg, AV *failed)
{
    dMY_CXT;
    HV *stash = gv_stashsv(pkg, 0);
    GV *meth = stash ? gv_fetchmethod_autoload(stash, "export_fail", FALSE) : NULL;
    CV *fcv = (meth && isGV_with_GP(meth)) ? GvCV(meth) : NULL;
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    SSize_t i, top;
    I32 count;
    dSP;

    if (!fcv || fcv == MY_CXT.export_fail_cv) {
        eo_av_append(aTHX_ out, failed);
        return out;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    top = av_len(failed);
    EXTEND(SP, top + 2);
    PUSHs(pkg);
    for (i = 0; i <= top; i++)
        PUSHs(*av_fetch(failed, i, 0));
    PUTBACK;
    count = call_sv((SV *)fcv, G_ARRAY);
    SPAGAIN;
    for (i = 0; i < count; i++)
        av_push(out, newSVsv(SP[i - count + 1]));
    SP -= count;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return out;
}

static void
eo_check_fail(pTHX_ SV *pkg, AV *names, bool verbose)
{
    AV *fail = eo_pkg_av(aTHX_ pkg, STR_WITH_LEN("EXPORT_FAIL"));
    HV *fset;
    AV *expanded, *failed;
    SSize_t i, top;

    if (!fail || av_len(fail) < 0)
        return;

    fset = (HV *)sv_2mortal((SV *)newHV());
    expanded = (AV *)sv_2mortal((SV *)newAV());
    top = av_len(fail);
    for (i = 0; i <= top; i++) {
        SV **svp = av_fetch(fail, i, 0);
        STRLEN len;
        const char *s;
        if (!svp)
            continue;
        s = SvPV_const(*svp, len);
        av_push(expanded, newSVsv(*svp));
        (void)hv_store_ent(fset, *svp, &PL_sv_yes, 0);
        if (len && eo_is_word_start(s, len, SvUTF8(*svp) ? TRUE : FALSE)) {
            SV *amp = sv_2mortal(newSVpvs("&"));
            sv_catsv(amp, *svp);
            av_push(expanded, newSVsv(amp));
            (void)hv_store_ent(fset, amp, &PL_sv_yes, 0);
        }
    }
    if (verbose)
        Perl_warn(aTHX_ "%" SVf "::EXPORT_FAIL cached: %" SVf,
                  SVfARG(pkg), SVfARG(eo_join(aTHX_ expanded, " ")));

    failed = (AV *)sv_2mortal((SV *)newAV());
    top = av_len(names);
    for (i = 0; i <= top; i++) {
        SV *sym = *av_fetch(names, i, 0);
        if (hv_exists_ent(fset, sym, 0))
            av_push(failed, newSVsv(sym));
    }
    if (av_len(failed) < 0)
        return;

    failed = eo_call_export_fail(aTHX_ pkg, failed);
    top = av_len(failed);
    for (i = 0; i <= top; i++)
        Perl_warn(aTHX_ "\"%" SVf "\" is not implemented by the %" SVf " module on this architecture",
                  SVfARG(*av_fetch(failed, i, 0)), SVfARG(pkg));
    if (top >= 0)
        Perl_croak(aTHX_ "Can't continue after import errors");
}

static void
eo_vivify(pTHX_ SV *pkg, const char *name, STRLEN len, svtype type)
{
    GV *gv = eo_stash_gv(aTHX_ gv_stashsv(pkg, 0), name, len, FALSE);
    if (!gv)
        gv = gv_fetchsv(eo_qualify(aTHX_ pkg, name, len, FALSE), GV_ADDMULTI, type);
    if (type == SVt_PVAV)
        (void)GvAVn(gv);
    else
        (void)GvHVn(gv);
}

static bool
eo_has_nonword(const char *s, STRLEN len, bool utf8)
{
    STRLEN i;
    for (i = 0; i < len; i++) {
        U8 c = (U8)s[i];
        if (utf8 && c >= 0x80)
            continue;
        if (!isWORDCHAR(c))
            return TRUE;
    }
    return FALSE;
}

/* Exporter.pm's import takes Exporter::Heavy only for some lists, and the
 * heavy path is the one that touches @EXPORT_FAIL. This is its test. */
static bool
eo_would_be_heavy(pTHX_ SV *pkg, AV *list, bool args, HV *set, bool verbose)
{
    HV *stash = gv_stashsv(pkg, 0);
    SV **failgv = stash ? hv_fetchs(stash, "EXPORT_FAIL", 0) : NULL;
    AV *fail = failgv ? eo_pkg_av(aTHX_ pkg, STR_WITH_LEN("EXPORT_FAIL")) : NULL;
    SV *first = NULL;
    SSize_t i, top;

    if (verbose)
        return TRUE;
    if (fail && av_len(fail) >= 1)
        return TRUE;
    if (fail && av_len(fail) >= 0) {
        SV **svp = av_fetch(fail, 0, 0);
        first = svp ? *svp : NULL;
    }

    top = list ? av_len(list) : -1;
    for (i = 0; i <= top; i++) {
        SV **svp = av_fetch(list, i, 0);
        STRLEN len;
        const char *s;
        if (!svp)
            continue;
        s = SvPV_const(*svp, len);
        if (eo_has_nonword(s, len, SvUTF8(*svp) ? TRUE : FALSE))
            return TRUE;
        if (args && set && !hv_exists_ent(set, *svp, 0))
            return TRUE;
        if (first && sv_eq(*svp, first))
            return TRUE;
    }
    return FALSE;
}

static void
eo_export(pTHX_ SV *pkg, SV *callpkg, SV **items, I32 n, const COP *errcop, bool via_import)
{
    dMY_CXT;
    AV *exp, *names;
    bool verbose = SvTRUE(GvSVn(MY_CXT.verbose_gv)) ? TRUE : FALSE;

    ENTER;
    if (errcop && errcop != PL_curcop) {
        SAVEVPTR(PL_curcop);
        PL_curcop = (COP *)errcop;
    }

    /* The common import: plain names, every one already known, and nothing
     * that would send Exporter.pm down its heavy path. It is installed
     * straight from the stack. */
    if (n > 0 && via_import && !verbose) {
        HV *stash = gv_stashsv(pkg, 0);
        GV *expgv = eo_stash_gv(aTHX_ stash, STR_WITH_LEN("EXPORT"), FALSE);
        GV *okgv  = eo_stash_gv(aTHX_ stash, STR_WITH_LEN("EXPORT_OK"), FALSE);
        SV **failp = stash ? hv_fetchs(stash, "EXPORT_FAIL", 0) : NULL;
        AV *fail = (failp && isGV_with_GP(*failp)) ? GvAV((GV *)*failp) : NULL;
        if (expgv && GvAV(expgv) && okgv && GvAV(okgv)
            && (!failp || (isGV_with_GP(*failp) && (!fail || av_len(fail) < 0)))) {
            bool current;
            HV *set = eo_cache_get(aTHX_ pkg, GvAV(expgv), GvAV(okgv), &current);
            I32 i;
            for (i = 0; i < n; i++) {
                STRLEN len;
                const char *s;
                if (!SvPOK(items[i]) || SvGMAGICAL(items[i]))
                    break;
                s = SvPVX_const(items[i]);
                len = SvCUR(items[i]);
                if (!len || eo_has_nonword(s, len, SvUTF8(items[i]) ? TRUE : FALSE)
                    || !hv_exists_ent(set, items[i], 0))
                    break;
            }
            if (i == n) {
                eo_install_list(aTHX_ pkg, callpkg, stash, items, n);
                LEAVE;
                return;
            }
        }
    }

    eo_vivify(aTHX_ pkg, STR_WITH_LEN("EXPORT"), SVt_PVAV);
    if (n)
        eo_vivify(aTHX_ pkg, STR_WITH_LEN("EXPORT_OK"), SVt_PVAV);
    exp = eo_pkg_av(aTHX_ pkg, STR_WITH_LEN("EXPORT"));

    if (n == 0) {
        names = eo_av_copy(aTHX_ exp);
        if (!via_import || eo_would_be_heavy(aTHX_ pkg, names, FALSE, NULL, verbose))
            eo_vivify(aTHX_ pkg, STR_WITH_LEN("EXPORT_FAIL"), SVt_PVAV);
    }
    else {
        AV *ok = eo_pkg_av(aTHX_ pkg, STR_WITH_LEN("EXPORT_OK"));
        bool current;
        HV *set = eo_cache_get(aTHX_ pkg, exp, ok, &current);
        SV *errors = NULL;
        I32 oops = 0;
        SSize_t i, top;
        I32 i32;

        names = (AV *)sv_2mortal((SV *)newAV());
        for (i32 = 0; i32 < n; i32++)
            av_push(names, newSVsv(items[i32]));

        if (!via_import || eo_would_be_heavy(aTHX_ pkg, names, TRUE, set, verbose))
            eo_vivify(aTHX_ pkg, STR_WITH_LEN("EXPORT_FAIL"), SVt_PVAV);

        if (eo_has_specs(aTHX_ names)) {
            eo_vivify(aTHX_ pkg, STR_WITH_LEN("EXPORT_TAGS"), SVt_PVHV);
            names = eo_walk_specs(aTHX_ pkg, names, exp, ok, verbose, &oops);
        }

        top = av_len(names);
        for (i = 0; i <= top; i++) {
            SV *sym = *av_fetch(names, i, 0);
            STRLEN len;
            const char *s = SvPV_const(sym, len);

            if (hv_exists_ent(set, sym, 0))
                continue;

            if (len && isDIGIT(*s)) {
                eo_call_version(aTHX_ pkg, sym);
                if (top == 0) {
                    names = eo_av_copy(aTHX_ exp);
                    break;
                }
                if (top == 1 && !SvTRUE(*av_fetch(names, 1, 0))) {
                    names = (AV *)sv_2mortal((SV *)newAV());
                    break;
                }
                continue;
            }

            if (len && *s == '&') {
                sv_chop(sym, s + 1);
                if (hv_exists_ent(set, sym, 0))
                    continue;
            }

            if (!current) {
                set = eo_cache_build(aTHX_ pkg, exp, ok);
                current = TRUE;
                if (hv_exists_ent(set, sym, 0))
                    continue;
            }

            if (!errors)
                errors = sv_2mortal(newSVpvs(""));
            sv_catpvf(errors, "\"%" SVf "\" is not exported by the %" SVf " module\n",
                      SVfARG(sym), SVfARG(pkg));
            oops++;
        }

        if (oops) {
            if (!errors)
                errors = sv_2mortal(newSVpvs(""));
            sv_catpvs(errors, "Can't continue after import errors");
            Perl_croak(aTHX_ "%" SVf, SVfARG(errors));
        }
    }

    eo_check_fail(aTHX_ pkg, names, verbose);

    if (verbose) {
        AV *sorted = eo_av_copy(aTHX_ names);
        if (av_len(sorted) > 0)
            sortsv(AvARRAY(sorted), av_len(sorted) + 1, Perl_sv_cmp);
        Perl_warn(aTHX_ "Importing into %" SVf " from %" SVf ": %" SVf,
                  SVfARG(callpkg), SVfARG(pkg), SVfARG(eo_join(aTHX_ sorted, ", ")));
    }

    eo_install(aTHX_ pkg, callpkg, names);
    LEAVE;
}

static void
eo_setup(pTHX_ SV **items, I32 n)
{
    dMY_CXT;
    bool want_import = TRUE;
    SV *errors = NULL;
    I32 i;

    for (i = 0; i < n; i++) {
        STRLEN len;
        const char *s = SvPV_const(items[i], len);
        if (len == 6 && memEQ(s, "import", 6))
            continue;
        if (len == 9 && memEQ(s, "-noimport", 9)) {
            want_import = FALSE;
            continue;
        }
        if (len == 6 && memEQ(s, "strict", 6)) {
            SV **v;
            PL_hints |= HINT_LOCALIZE_HH;
            v = hv_stores(GvHVn(PL_hintgv), EO_STRICT_KEY, newSViv(1));
            if (v)
                SvSETMAGIC(*v);
            continue;
        }
        if (!errors)
            errors = sv_2mortal(newSVpvs(""));
        sv_catpvf(errors, "\"%" SVf "\" is not exported by the Ex::Op module\n",
                  SVfARG(items[i]));
    }
    if (errors) {
        sv_catpvs(errors, "Can't continue after import errors");
        Perl_croak(aTHX_ "%" SVf, SVfARG(errors));
    }

    {
        SV **v;
        PL_hints |= HINT_LOCALIZE_HH;
        v = hv_stores(GvHVn(PL_hintgv), EO_KW_KEY, newSViv(1));
        if (v)
            SvSETMAGIC(*v);
    }

    if (want_import) {
        SV *callpkg = eo_stash_name(aTHX_ CopSTASH(PL_curcop));
        SV *dst = eo_qualify(aTHX_ callpkg, STR_WITH_LEN("import"), FALSE);
        GV *gv = gv_fetchsv(dst, 0, SVt_PVCV);
        CV *have = (gv && isGV_with_GP(gv)) ? GvCVu(gv) : NULL;
        if (!have || !(CvROOT(have) || CvXSUB(have))) {
            gv = gv_fetchsv(dst, GV_ADDMULTI, SVt_PVGV);
            sv_setsv_mg((SV *)gv, sv_2mortal(newRV_inc((SV *)MY_CXT.import_cv)));
            GvIMPORTED_CV_on(gv);
        }
    }
}

static void
eo_push_tags(pTHX_ const char *var, STRLEN varlen, SV **items, I32 n)
{
    SV *pkg = eo_stash_name(aTHX_ CopSTASH(PL_curcop));
    HV *tags = eo_pkg_hv(aTHX_ pkg, STR_WITH_LEN("EXPORT_TAGS"));
    AV *target = GvAVn(gv_fetchsv(eo_qualify(aTHX_ pkg, var, varlen, FALSE), GV_ADDMULTI, SVt_PVAV));
    AV *list = (AV *)sv_2mortal((SV *)newAV());
    AV *nontag = (AV *)sv_2mortal((SV *)newAV());
    SSize_t i, top;
    I32 i32;

    if (n) {
        for (i32 = 0; i32 < n; i32++)
            av_push(list, newSVsv(items[i32]));
    }
    else if (tags) {
        HE *he;
        hv_iterinit(tags);
        while ((he = hv_iternext(tags)))
            av_push(list, newSVsv(hv_iterkeysv(he)));
        if (av_len(list) > 0)
            sortsv(AvARRAY(list), av_len(list) + 1, Perl_sv_cmp);
    }

    top = av_len(list);
    for (i = 0; i <= top; i++) {
        SV *name = *av_fetch(list, i, 0);
        HE *he = tags ? hv_fetch_ent(tags, name, 0, 0) : NULL;
        if (he && SvTRUE(HeVAL(he))) {
            SV *val = HeVAL(he);
            if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
                Perl_croak(aTHX_ "Not an ARRAY reference");
            eo_av_append(aTHX_ target, (AV *)SvRV(val));
        }
        else {
            av_push(nontag, newSVsv(name));
            av_push(target, newSVsv(name));
        }
    }

    if (av_len(nontag) >= 0 && (PL_dowarn & G_WARN_ON))
        Perl_warn(aTHX_ "%" SVf " are not tags of %" SVf,
                  SVfARG(eo_join(aTHX_ nontag, ", ")), SVfARG(pkg));
}

MODULE = Ex::Op    PACKAGE = Ex::Op

PROTOTYPES: DISABLE

void
import(...)
CODE:
{
    SV *pkg;
    if (items < 1)
        XSRETURN_EMPTY;
    pkg = ST(0);
    if (!SvROK(pkg) && strEQ(SvPV_nolen_const(pkg), "Ex::Op")) {
        eo_setup(aTHX_ &ST(1), items - 1);
    }
    else {
        dMY_CXT;
        IV level = SvIV(GvSVn(MY_CXT.level_gv));
        const COP *at = eo_caller_cop(aTHX_ level);
        SV *callpkg = eo_stash_name(aTHX_ at ? CopSTASH(at) : NULL);
        eo_export(aTHX_ sv_mortalcopy(pkg), callpkg, &ST(1), items - 1, at, TRUE);
    }
    XSRETURN_EMPTY;
}

void
unimport(...)
CODE:
{
    if (items < 1 || SvROK(ST(0)) || !strEQ(SvPV_nolen_const(ST(0)), "Ex::Op"))
        XSRETURN_EMPTY;
    PL_hints |= HINT_LOCALIZE_HH;
    (void)hv_deletes(GvHVn(PL_hintgv), EO_KW_KEY, G_DISCARD);
    (void)hv_deletes(GvHVn(PL_hintgv), EO_STRICT_KEY, G_DISCARD);
    XSRETURN_EMPTY;
}

void
export(pkg, callpkg, ...)
    SV *pkg
    SV *callpkg
CODE:
{
    eo_export(aTHX_ sv_mortalcopy(pkg), sv_mortalcopy(callpkg), &ST(2), items - 2, PL_curcop, FALSE);
    XSRETURN_EMPTY;
}

void
export_to_level(pkg, level, ...)
    SV *pkg
    IV level
CODE:
{
    dMY_CXT;
    const COP *at = eo_caller_cop(aTHX_ level);
    SV *callpkg = eo_stash_name(aTHX_ at ? CopSTASH(at) : NULL);
    I32 skip = items > 2 ? 3 : 2;
    HV *stash = gv_stashsv(pkg, 0);
    GV *meth = stash ? gv_fetchmethod_autoload(stash, "export", FALSE) : NULL;
    CV *ecv = (meth && isGV_with_GP(meth)) ? GvCV(meth) : NULL;

    if (ecv && ecv != MY_CXT.export_cv) {
        AV *args = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, top;
        av_push(args, newSVsv(pkg));
        av_push(args, newSVsv(callpkg));
        for (i = skip; i < items; i++)
            av_push(args, newSVsv(ST(i)));
        top = av_len(args);
        SP = MARK;
        PUSHMARK(SP);
        EXTEND(SP, top + 1);
        for (i = 0; i <= top; i++)
            PUSHs(*av_fetch(args, i, 0));
        PUTBACK;
        call_sv((SV *)ecv, G_VOID | G_DISCARD);
    }
    else {
        eo_export(aTHX_ sv_mortalcopy(pkg), callpkg, &ST(skip), items - skip, at, FALSE);
    }
    XSRETURN_EMPTY;
}

void
export_fail(self, ...)
    SV *self
PPCODE:
{
    I32 i;
    PERL_UNUSED_VAR(self);
    for (i = 1; i < items; i++)
        ST(i - 1) = ST(i);
    XSRETURN(items - 1);
}

void
export_tags(...)
CODE:
{
    eo_push_tags(aTHX_ STR_WITH_LEN("EXPORT"), &ST(0), items);
    XSRETURN_EMPTY;
}

void
export_ok_tags(...)
CODE:
{
    eo_push_tags(aTHX_ STR_WITH_LEN("EXPORT_OK"), &ST(0), items);
    XSRETURN_EMPTY;
}

SV *
require_version(self, wanted)
    SV *self
    SV *wanted
CODE:
{
    SV *pkg = SvROK(self) && SvOBJECT(SvRV(self))
            ? newSVpv(HvNAME_get(SvSTASH(SvRV(self))), 0)
            : newSVsv(self);
    I32 count;
    sv_2mortal(pkg);
    PUSHMARK(SP);
    XPUSHs(pkg);
    XPUSHs(wanted);
    PUTBACK;
    count = call_method("VERSION", G_SCALAR);
    SPAGAIN;
    RETVAL = count ? newSVsv(POPs) : newSV(0);
    PUTBACK;
}
OUTPUT:
    RETVAL

void
reset_cache(...)
CODE:
{
    dMY_CXT;
    I32 i;
    if (items == 0)
        hv_clear(MY_CXT.exports);
    for (i = 0; i < items; i++)
        (void)hv_delete_ent(MY_CXT.exports, ST(i), G_DISCARD, 0);
    XSRETURN_EMPTY;
}

void
make(name, code)
    SV *name
    SV *code
PPCODE:
{
    CV *cv = eo_code_arg(aTHX_ code, "Ex::Op::make");
    STRLEN len;
    const char *s = SvPV_const(name, len);
    SV *full;
    GV *gv;
    eo_op_t *e;

    if (!len)
        Perl_croak(aTHX_ "Ex::Op::make needs a name");
    if (instr(s, "::"))
        full = sv_mortalcopy(name);
    else
        full = eo_qualify(aTHX_ eo_stash_name(aTHX_ CopSTASH(PL_curcop)), s, len,
                          SvUTF8(name) ? TRUE : FALSE);

    gv = gv_fetchsv(full, GV_ADDMULTI, SVt_PVCV);
    sv_setsv_mg((SV *)gv, code);

    e = eo_register(aTHX_ cv);
    if (!e->accepted && eo_strict_on(aTHX))
        Perl_croak(aTHX_ "%" SVf " cannot be an op: %s", SVfARG(full), e->why);

    ST(0) = e->accepted ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

void
is_op(code)
    SV *code
PPCODE:
{
    CV *cv = eo_code_arg(aTHX_ code, "Ex::Op::is_op");
    ST(0) = eo_op_live(aTHX_ cv) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

void
why_not(code)
    SV *code
PPCODE:
{
    CV *cv = eo_code_arg(aTHX_ code, "Ex::Op::why_not");
    eo_op_t *e = eo_op_find(aTHX_ cv);
    if (eo_op_live(aTHX_ cv))
        ST(0) = &PL_sv_undef;
    else if (!e)
        ST(0) = sv_2mortal(newSVpvs("it was never made an op"));
    else if (e->why)
        ST(0) = sv_2mortal(newSVpv(e->why, 0));
    else
        ST(0) = sv_2mortal(newSVpvs("it has been redefined or undefined since it was made an op"));
    XSRETURN(1);
}

#ifdef EO_TEST_HOOKS

void
_test_add_checker()
CODE:
    eo_wrap_check(OP_ENTERSUB, eo_test_ck, &eo_test_next_ck);

IV
_test_checker_seen()
CODE:
    RETVAL = eo_test_seen;
OUTPUT:
    RETVAL

IV
_test_check_wrap()
CODE:
    RETVAL = EO_CHECK_WRAP;
OUTPUT:
    RETVAL

#endif

void
CLONE(...)
CODE:
{
    MY_CXT_CLONE;
    eo_cxt_init(aTHX_ &MY_CXT);
    PERL_UNUSED_VAR(items);
}

BOOT:
{
    MY_CXT_INIT;
    eo_cxt_init(aTHX_ &MY_CXT);
    eo_boot_ops(aTHX);
    eo_boot_keyword(aTHX);
}
