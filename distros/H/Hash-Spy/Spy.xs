#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

enum {
    DELETE = 0,
    STORE  = 1,
    CLEAR  = 2,
    EMPTY  = 3,
    NUM_CALLBACKS = 4,
};

static void
set_cb(pTHX_ HV *spy, int slot, SV *cb) {
    MAGIC *mg = mg_find((SV*)spy, PERL_MAGIC_ext);
    if (mg) {
        AV *av = (AV*)(mg->mg_obj);
        if (av && (SvTYPE((SV*)av) == SVt_PVAV)) {
            av_store(av, slot, newSVsv(cb));
            return;
        }
    }
    Perl_croak(aTHX_ "internal error: tied object is missing the extra magic or it is of the wrong type");
}

static SV *
get_cb(pTHX_ HV *spy, int slot) {
    MAGIC *mg = mg_find((SV*)spy, PERL_MAGIC_ext);
    if (mg) {
        AV *av = (AV*)(mg->mg_obj);
        if (av && (SvTYPE(av) == SVt_PVAV)) {
            SV **svp = av_fetch(av, slot, 0);
            if (svp) {
                SV *sv = *svp;
                if (sv && SvOK(sv)) {
                    return sv;
                }
            }
            return NULL;
        }
    }
    Perl_croak(aTHX_ "internal error: tied object is missing the extra magic or it is of the wrong type");
}

static void
spyback(pTHX_ HV *spy, int slot, U32 argc, ...) {
    SV *cb = get_cb(aTHX_ spy, slot);
    if (cb) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        if (argc > 0) {
            va_list args;
            va_start(args, argc);
            EXTEND(SP, argc);
            do {
                SV *const sv = va_arg(args, SV *);
                PUSHs(sv_mortalcopy(sv));
            } while (--argc);
            va_end(args);
        }
        PUTBACK;
        call_sv(cb, G_SCALAR|G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}

MODULE = Hash::Spy		PACKAGE = Hash::Spy		

SV *
_hash_get_spy(HV *hv)
PREINIT:
    const MAGIC *mg;
CODE:
    if (mg = SvTIED_mg((SV*)hv, PERL_MAGIC_tied)) {
        RETVAL = SvTIED_obj((SV*)hv, mg);
        if (!sv_isa(RETVAL, "Hash::Spy"))
            Perl_croak(aTHX_ "Hash::Spy does not support tied hashes");
        RETVAL = newSVsv(RETVAL);
    }
    else if (!SvMAGICAL((SV*)hv)) {
        HV *spy = newHV();
        AV *av = newAV();
        void *array;
        STRLEN max, total;
        if (HvSHAREKEYS(hv))
            HvSHAREKEYS_on(spy);
        else
            HvSHAREKEYS_off(spy);

        hv_iterinit(spy);
        if (!SvOOK(hv))
            hv_iterinit(hv);

        max              = HvMAX(hv);
        HvMAX(hv)        = HvMAX(spy);
        HvMAX(spy)       = max;

        total            = HvTOTALKEYS(hv);
        HvTOTALKEYS(hv)  = HvTOTALKEYS(spy);
        HvTOTALKEYS(spy) = total;

        array            = HvARRAY(hv);
        HvARRAY(hv)      = HvARRAY(spy);
        HvARRAY(spy)     = array;

        RETVAL = newRV_noinc((SV*)spy);
        sv_magic((SV*)spy, (SV*)av, PERL_MAGIC_ext, NULL, 0);
        sv_bless(RETVAL, gv_stashpvs("Hash::Spy", 1));
        
        hv_magic(hv, RETVAL, PERL_MAGIC_tied);
    }
    else {
        Perl_croak(aTHX_ "Hash::Spy does not support hashes with magic attached");
    }
OUTPUT:
    RETVAL

SV *
FETCH(HV *spy, SV *key)
PREINIT:
    HE *he;
CODE:
    he = hv_fetch_ent(spy, key, 0, 0);
    RETVAL = (he ? newSVsv(hv_iterval(spy, he)) : &PL_sv_undef);
OUTPUT:
    RETVAL

void
STORE(HV *spy, SV *key, SV *value)
CODE:
    spyback(aTHX_ spy, STORE, 2, key, value);
    value = newSVsv(value);
    if (!hv_store_ent(spy, key, value, 0)) sv_2mortal(value);

SV *
DELETE(HV *spy, SV *key)
PREINIT:
    STRLEN total_keys;
CODE:
    if (hv_exists_ent(spy, key, 0)) {
        spyback(aTHX_ spy, DELETE, 1, key);
        RETVAL = hv_delete_ent(spy, key, 0, 0);
        SvREFCNT_inc(RETVAL);
        if (!HvTOTALKEYS(spy))
            spyback(aTHX_ spy, EMPTY, 0);
    }
    else
        RETVAL = &PL_sv_undef;
OUTPUT:
    RETVAL

void
CLEAR(HV *spy)
ALIAS:
    UNTIE = 0
CODE:
    if (HvTOTALKEYS(spy)) {
        spyback(aTHX_ spy, CLEAR, 0);
        hv_clear(spy);
        spyback(aTHX_ spy, EMPTY, 0);
    }

SV *
EXISTS(HV *spy, SV *key)
CODE:
    RETVAL = (hv_exists_ent(spy, key, 0) ? &PL_sv_yes : &PL_sv_no);
OUTPUT:
    RETVAL

SV *
FIRSTKEY(HV *spy)
PREINIT:
    HE *he;
CODE:
    hv_iterinit(spy);
    he = hv_iternext(spy);
    RETVAL = (he ? newSVsv(hv_iterkeysv(he)) : &PL_sv_undef);
OUTPUT:
    RETVAL

SV *
NEXTKEY(HV *spy, SV *last)
PREINIT:
    HE *he;
CODE:
    he = hv_iternext(spy);
    RETVAL = (he ? newSVsv(hv_iterkeysv(he)) : &PL_sv_undef);
OUTPUT:
    RETVAL

SV *
SCALAR(HV *spy)
CODE:
    RETVAL = hv_scalar(spy);
OUTPUT:
    RETVAL

void
_set_cb(HV *spy, IV slot, SV *cb)
CODE:
    set_cb(aTHX_ spy, slot, cb);
