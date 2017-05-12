#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

struct sort_elem {
    SV *key;
    SV *orig;
};

static I32
sv_cmp_str_asc(pTHX_ SV *sv1, SV *sv2)
{
    struct sort_elem *se1, *se2;

    se1 = (struct sort_elem*)SvIV(sv1);
    se2 = (struct sort_elem*)SvIV(sv2);

    return sv_cmp_locale(se1->key, se2->key);
}

static I32
sv_cmp_str_desc(pTHX_ SV *sv1, SV *sv2)
{
    struct sort_elem *se1, *se2;

    se1 = (struct sort_elem*)SvIV(sv1);
    se2 = (struct sort_elem*)SvIV(sv2);

    return sv_cmp_locale(se2->key, se1->key);
}

static I32
sv_cmp_number_asc(pTHX_ SV *sv1, SV *sv2)
{
    struct sort_elem *se1, *se2;
    NV key1, key2;

    se1 = (struct sort_elem*)SvIV(sv1);
    se2 = (struct sort_elem*)SvIV(sv2);

    key1 = SvNV(se1->key);
    key2 = SvNV(se2->key);

    return (key1 > key2)
           ? 1 : (key1 == key2)
           ? 0 : -1;
}

static I32
sv_cmp_number_desc(pTHX_ SV *sv1, SV *sv2)
{
    struct sort_elem *se1, *se2;
    NV key1, key2;

    se1 = (struct sort_elem*)SvIV(sv1);
    se2 = (struct sort_elem*)SvIV(sv2);

    key1 = SvNV(se2->key);
    key2 = SvNV(se1->key);

    return (key1 > key2)
           ? 1 : (key1 == key2)
           ? 0 : -1;
}

MODULE = List::UtilsBy::XS        PACKAGE = List::UtilsBy::XS

void
sort_by (code, ...)
    SV *code
PROTOTYPE: &@
ALIAS:
    sort_by     = 0
    rev_sort_by = 1
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &PL_stack_base[ax];
    int i;
    AV *tmps;
    struct sort_elem *elems;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    tmps = (AV *)sv_2mortal((SV *)newAV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    Newx(elems, items - 1, struct sort_elem);

    for (i = 1; i < items; i++) {
        struct sort_elem *elem = &elems[i - 1];

        GvSV(PL_defgv) = args[i];
        MULTICALL;

        elem->key  = newSVsv(*PL_stack_sp);
        elem->orig = newSVsv(args[i]);

        av_push(tmps, newSViv((IV)elem));
    }

    POP_MULTICALL;

    if (ix) {
        sortsv(AvARRAY(tmps), av_len(tmps) + 1, sv_cmp_str_desc);
    } else {
        sortsv(AvARRAY(tmps), av_len(tmps) + 1, sv_cmp_str_asc);
    }

    for (i = 1; i < items; i++) {
        struct sort_elem *elem;
        elem  = (struct sort_elem *)SvIV(*av_fetch(tmps, i-1, 0));
        ST(i-1) = sv_2mortal(elem->orig);
        (void)sv_2mortal(elem->key);
    }

    Safefree(elems);

    XSRETURN(items - 1);
}

void
nsort_by (code, ...)
    SV *code
PROTOTYPE: &@
ALIAS:
    nsort_by     = 0
    rev_nsort_by = 1
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &PL_stack_base[ax];
    int i;
    AV *tmps;
    struct sort_elem *elems;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    tmps = (AV *)sv_2mortal((SV *)newAV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    Newx(elems, items - 1, struct sort_elem);

    for (i = 1; i < items; i++) {
        struct sort_elem *elem = &elems[i - 1];

        GvSV(PL_defgv) = args[i];
        MULTICALL;

        elem->key  = newSVsv(*PL_stack_sp);
        elem->orig = newSVsv(args[i]);

        av_push(tmps, newSViv((IV)elem));
    }

    POP_MULTICALL;

    if (ix) {
        sortsv(AvARRAY(tmps), av_len(tmps) + 1, sv_cmp_number_desc);
    } else {
        sortsv(AvARRAY(tmps), av_len(tmps) + 1, sv_cmp_number_asc);
    }

    for (i = 1; i < items; i++) {
        struct sort_elem *elem;
        elem  = (struct sort_elem *)SvIV(*av_fetch(tmps, i-1, 0));
        ST(i-1) = sv_2mortal(elem->orig);
        (void)sv_2mortal(elem->key);
    }

    Safefree(elems);

    XSRETURN(items - 1);
}

void
min_by (code, ...)
    SV *code
PROTOTYPE: &@
ALIAS:
    min_by = 0
    max_by = 1
    nmin_by = 2
    nmax_by = 3
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &ST(1);
    I32 const len = items - 1;
    int i;
    AV *tmps;
    NV max;
    IV ret_count = 0;
    struct sort_elem *elems, *first;

    if (len < 1) {
        XSRETURN_EMPTY;
    }

    tmps = (AV *)sv_2mortal((SV *)newAV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    Newx(elems, items - 1, struct sort_elem);

    for (i = 0; i < len; i++) {
        struct sort_elem *elem = &elems[i];

        GvSV(PL_defgv) = args[i];
        MULTICALL;

        elem->key  = newSVsv(*PL_stack_sp);
        elem->orig = newSVsv(args[i]);

        av_push(tmps, newSViv((IV)elem));
    }

    POP_MULTICALL;

    if (ix & 0x1) {
        sortsv(AvARRAY(tmps), len, sv_cmp_number_desc);
    } else {
        sortsv(AvARRAY(tmps), len, sv_cmp_number_asc);
    }

    for(i = 0; i < len; i++) {
        struct sort_elem* elem
            = (struct sort_elem*)SvIVx(*av_fetch(tmps, i, TRUE));
        sv_2mortal(elem->key);
        sv_2mortal(elem->orig);
    }

    first = (struct sort_elem *)SvIV(*av_fetch(tmps, 0, 0));
    max   = SvNV(first->key);
    ST(0) = first->orig;
    ret_count++;

    if (GIMME_V != G_ARRAY) {
        goto ret;
    }

    for (i = 2; i < items; i++) {
        struct sort_elem *elem;
        elem  = (struct sort_elem *)SvIV(*av_fetch(tmps, i-1, 0));

        if (max == SvNV(elem->key)) {
            ST(ret_count) = elem->orig;
            ret_count++;
        } else {
            goto ret;
        }
    }

 ret:
    Safefree(elems);
    XSRETURN(ret_count);
}

void
uniq_by (code, ...)
    SV *code
PROTOTYPE: &@
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &PL_stack_base[ax];
    int i;
    AV *tmps;
    HV *rh;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    tmps = (AV *)sv_2mortal((SV *)newAV());
    rh = (HV *)sv_2mortal((SV *)newHV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    for (i = 1; i < items; i++) {
        STRLEN len;
        char *str;

        GvSV(PL_defgv) = args[i];
        MULTICALL;

        str = SvPV(*PL_stack_sp, len);
        if (!hv_exists(rh, str, len)) {
            av_push(tmps, newSVsv(args[i]));
            (void)hv_store(rh, str, len, newSViv(1), 0);
        }
    }

    POP_MULTICALL;

    for (i = 0; i <= av_len(tmps); i++) {
        ST(i) = *av_fetch(tmps, i, 0);
    }

    XSRETURN(av_len(tmps) + 1);
}

void
partition_by (code, ...)
    SV *code
PROTOTYPE: &@
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &PL_stack_base[ax];
    int i;
    HV *rh;
    HE *iter = NULL;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    rh = (HV *)sv_2mortal((SV *)newHV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    for (i = 1; i < items; i++) {
        STRLEN len;
        char *str;

        GvSV(PL_defgv) = args[i];
        MULTICALL;

        str = SvPV(*PL_stack_sp, len);
        if (!hv_exists(rh, str, len)) {
            AV* av = (AV *)sv_2mortal((SV *)newAV());
            av_push(av, newSVsv(args[i]));
            (void)hv_store(rh, str, len, newRV_inc((SV *)av), 0);
        } else {
            AV *av = (AV *)SvRV(*hv_fetch(rh, str, len, 0));
            av_push(av, newSVsv(args[i]));
        }
    }

    POP_MULTICALL;

    hv_iterinit(rh);

    i = 0;
    while ( (iter = hv_iternext( rh )) != NULL ) {
          ST(i) = hv_iterkeysv(iter);
          i++;
          ST(i) = hv_iterval(rh, iter);
          i++;
    }

    XSRETURN(i);
}

void
count_by (code, ...)
    SV *code
PROTOTYPE: &@
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &PL_stack_base[ax];
    int i;
    HV *rh;
    HE *iter = NULL;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    rh = (HV *)sv_2mortal((SV *)newHV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    for (i = 1; i < items; i++) {
        STRLEN len;
        char *str;

        GvSV(PL_defgv) = args[i];
        MULTICALL;

        str = SvPV(*PL_stack_sp, len);
        if (!hv_exists(rh, str, len)) {
            SV* count = newSViv(1);
            (void)hv_store(rh, str, len, count, 0);
        } else {
            SV **count = hv_fetch(rh, str, len, 0);
            sv_inc(*count);
        }
    }

    POP_MULTICALL;

    hv_iterinit(rh);

    i = 0;
    while ( (iter = hv_iternext( rh )) != NULL ) {
          ST(i) = hv_iterkeysv(iter);
          i++;
          ST(i) = hv_iterval(rh, iter);
          i++;
    }

    XSRETURN(i);
}

void
zip_by (code, ...)
    SV *code
PROTOTYPE: &@
CODE:
{
    dSP;
    SV **args = &PL_stack_base[ax];
    AV *tmps, *retvals;
    I32 i, j, count;
    I32 len, max_length = -1;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    tmps = (AV *)sv_2mortal((SV *)newAV());
    retvals = (AV *)sv_2mortal((SV *)newAV());

    for (i = 1; i < items; i++) {
        if (!SvROK(args[i]) || (SvTYPE(SvRV(args[i])) != SVt_PVAV)) {
            croak("arguments should be ArrayRef");
        }

        len = av_len((AV*)SvRV(args[i]));
        if (len > max_length) {
            max_length = len;
        }

        av_push(tmps, newSVsv(args[i]));
    }

    SAVESPTR(GvSV(PL_defgv));

    for (i = 0; i <= max_length; i++) {
        ENTER;
        SAVETMPS;

        PUSHMARK(sp);
        for (j = 1; j < items; j++) {
            AV *av = (AV*)SvRV( *av_fetch(tmps, j-1, 0) );

            if (av_exists(av, i)) {
                SV *elem = *av_fetch(av, i, 0);
                XPUSHs(sv_2mortal(newSVsv(elem)));
            } else {
                XPUSHs(&PL_sv_undef);
            }
        }
        PUTBACK;

        count = call_sv(code, G_ARRAY);

        SPAGAIN;

        len = av_len(retvals);
        for (j = 0; j < count; j++) {
            av_store(retvals, len + (count - j), newSVsv(POPs));
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    len = av_len(retvals) + 1;
    for (i = 0; i < len; i++) {
        ST(i) = *av_fetch(retvals, i, 0);
    }

    XSRETURN(len);
}

void
unzip_by (code, ...)
    SV *code
PROTOTYPE: &@
CODE:
{
    dSP;
    SV **args = &PL_stack_base[ax];
    AV *retvals;
    I32 i, j, count;
    I32 len, max_len = 0;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    retvals = (AV *)sv_2mortal((SV *)newAV());

    SAVESPTR(GvSV(PL_defgv));

    for (i = 1; i < items; i++) {
        ENTER;
        SAVETMPS;

        PUSHMARK(sp);
        XPUSHs(sv_2mortal(newSVsv(args[i])));
        PUTBACK;

        GvSV(PL_defgv) = args[i];
        count = call_sv(code, G_ARRAY);

        SPAGAIN;

        for (j = max_len; j < count; j++) {
            AV *tmp = (AV *)sv_2mortal((SV *)newAV());
            av_store(retvals, j, newRV((SV*)tmp));
        }

        if (max_len < count) {
            max_len = count;
        }

        for (j = count - 1; j >= 0; j--) {
            SV *ret  = newSVsv(POPs);
            AV *tmp = (AV *)SvRV((SV*)*av_fetch(retvals, j, 0));
            av_store(tmp, i - 1, ret);
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    len = av_len(retvals) + 1;
    for (i = 0; i < len; i++) {
        AV *tmp = (AV *)SvRV((SV*)*av_fetch(retvals, i, 0));
        for (j = av_len(tmp) + 1; j < (items - 1); j++) {
            av_push(tmp, &PL_sv_undef);
        }
    }

    for (i = 0; i < len; i++) {
        ST(i) = *av_fetch(retvals, i, 0);
    }

    XSRETURN(len);
}

void
extract_by (code, ...)
    SV *code
PROTOTYPE: &\@
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR, ret_gimme = GIMME_V;
    SV **args = &PL_stack_base[ax];
    IV i, len;
    AV *ret_vals, *remains, *origs;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    ret_vals = (AV *)sv_2mortal((SV *)newAV());
    remains  = (AV *)sv_2mortal((SV *)newAV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    if (!SvROK(args[1]) || (SvTYPE(SvRV(args[1])) != SVt_PVAV)) {
        croak("arguments should be ArrayRef");
    }

    origs = (AV*)SvRV(args[1]);
    len = av_len((AV*)SvRV(args[1])) + 1;

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    for (i = 0; i < len; i++) {
        SV *val, *arg;

        arg = *av_fetch(origs, i, 0);
        GvSV(PL_defgv) = arg;
        MULTICALL;

        val = newSVsv(*PL_stack_sp);
        if (SvTRUE(val)) {
            av_push(ret_vals, newSVsv(arg));
        } else {
            SV *val = newSVsv(arg);
            SvFLAGS(val) = SvFLAGS(arg);
            av_push(remains, val);
        }
    }

    POP_MULTICALL;

    av_clear(origs);

    len = av_len(remains) + 1;
    for (i = 0; i < len; i++) {
        SV *val = *av_fetch(remains, i, 0);
        av_push(origs, newSVsv(val));
    }

    if (ret_gimme == G_SCALAR) {
        len = 1;
        ST(0) = sv_2mortal(newSViv(av_len(ret_vals)+1));
    } else {
        len = av_len(ret_vals) + 1;
        for (i = 0; i < len; i++) {
            ST(i) = sv_mortalcopy(*av_fetch(ret_vals, i, 0));
        }
    }

    XSRETURN(len);
}

void
weighted_shuffle_by (code, ...)
    SV *code
PROTOTYPE: &@
CODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;
    SV **args = &PL_stack_base[ax];
    I32 i, len;
    AV *weights, *origs, *retvals;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    weights = (AV *)sv_2mortal((SV *)newAV());
    origs   = (AV *)sv_2mortal((SV *)newAV());
    retvals = (AV *)sv_2mortal((SV *)newAV());

    cv = sv_2cv(code, &stash, &gv, 0);
    if (cv == Nullcv) {
       croak("Not a subroutine reference");
    }

    PUSH_MULTICALL(cv);
    SAVESPTR(GvSV(PL_defgv));

    for (i = 1; i < items; i++) {
        av_push(origs, newSVsv(args[i]));

        GvSV(PL_defgv) = args[i];
        MULTICALL;

        av_push(weights, newSVsv(*PL_stack_sp));
    }

    POP_MULTICALL;

    /* Initialize Drand01 if rand() or srand() has
       not already been called
    */
    if (!PL_srand_called) {
        (void)seedDrand01((Rand_seed_t)seed());
        PL_srand_called = TRUE;
    }

    while ( (av_len(origs) + 1) > 1) {
        IV total = 0;
        I32 select;
        I32 idx;
        SV *selected, *last;

        len = av_len(weights) + 1;
        for (i = 0; i < len; i++) {
            total += SvIV(*av_fetch(weights, i, 0));
        }

        select = (I32)(Drand01() * (double)total);
        idx = 0;
        while (select >= SvIV(*av_fetch(weights, idx, 0))) {
            select -= SvIV(*av_fetch(weights, idx, 0));

            if (av_len(weights) > idx) {
                idx++;
            } else {
                break;
            }
        }

        selected = *av_fetch(origs, idx, 0);
        av_push(retvals, newSVsv(selected));

        last = *av_fetch(origs, av_len(origs), 0);
        av_store(origs, idx, last);
        (void)av_pop(origs);

        last = *av_fetch(weights, av_len(weights), 0);
        av_store(weights, idx, last);
        (void)av_pop(weights);
    }

    len = av_len(origs) + 1;
    for (i = 0 ; i < len; i++) {
        av_push(retvals, av_shift(origs));
    }

    for (i = 1 ; i < items; i++) {
        ST(i-1) = sv_2mortal(newSVsv( *av_fetch(retvals, i-1, 0) ));
    }

    XSRETURN(items-1);
}

void
bundle_by (code, ...)
    SV *code
PROTOTYPE: &@
CODE:
{
    dSP;
    SV **args = &PL_stack_base[ax];
    AV *retvals;
    IV argnum;
    I32 i, j, count, len, loop;

    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    argnum = SvIV(args[1]);
    if (argnum <= 0) {
        croak("bundle number is larger than 0");
    }

    retvals = (AV *)sv_2mortal((SV *)newAV());

    SAVESPTR(GvSV(PL_defgv));

    for (i = 2, loop = 0; i < items; i += argnum, loop++) {
        ENTER;
        SAVETMPS;

        PUSHMARK(sp);
        for (j = 0; j < argnum; j++) {
            I32 index = (loop * argnum) + j + 2;
            if (SvOK(args[index])) {
                XPUSHs(sv_2mortal(newSVsv(args[index])));
            } else {
                XPUSHs(&PL_sv_undef);
            }
        }
        PUTBACK;

        count = call_sv(code, G_ARRAY);

        SPAGAIN;

        len = av_len(retvals);
        for (j = 0; j < count; j++) {
            av_store(retvals, len + (count - j), newSVsv(POPs));
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    len = av_len(retvals) + 1;
    for (i = 0; i < len; i++) {
        ST(i) = *av_fetch(retvals, i, 0);
    }

    XSRETURN(len);
}
