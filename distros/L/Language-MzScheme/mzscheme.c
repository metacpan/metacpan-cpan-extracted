#include "scheme.h"
#include "mzscheme.h"

void
mzscheme_init () {
    int dummy;
    scheme_set_stack_base(&dummy, 1);
}

Scheme_Object *
mzscheme_make_perl_prim_w_arity (Perl_Scalar cv_ref, const char *name, int mina, int maxa, const char *sigil_string) {
    Perl_Callback *callback = (Perl_Callback *)malloc(sizeof(Perl_Callback));
    callback->magic = Perl_Callback_MAGIC;
    callback->sv = cv_ref;
    callback->sigil = ((sigil_string == NULL) ? NULL : *sigil_string);
    SvREFCNT_inc(cv_ref);

    return scheme_make_closed_prim_w_arity(
        &_mzscheme_closed_prim_CV,
        (void *)callback, savepv(name), mina, maxa
    );
}

Scheme_Object *
mzscheme_make_perl_object_w_arity (Perl_Scalar object, const char *name, int mina, int maxa, const char *sigil_string) {
    Perl_Callback *callback = (Perl_Callback *)malloc(sizeof(Perl_Callback));
    callback->magic = Perl_Callback_MAGIC;
    callback->sv = object;
    callback->sigil = ((sigil_string == NULL) ? Perl_Context_AUTO : *sigil_string);
    SvREFCNT_inc(object);

    return scheme_make_closed_prim_w_arity(
        &_mzscheme_closed_prim_OBJ,
        (void *)callback, savepv(name), mina, maxa
    );
}

Scheme_Object *
mzscheme_from_perl_arrayref (Perl_Scalar sv) {
    return scheme_build_list(
        1+(int)av_len( (AV*)SvRV(sv) ),
        _mzscheme_from_perl_arrayref_to_objects(sv)
    );
}

Scheme_Object *
mzscheme_from_perl_hashref (Perl_Scalar sv) {
    HV* hv = (HV*)SvRV(sv);
    HE* entry;
    I32 retlen;
    Scheme_Hash_Table *hash = scheme_make_hash_table(SCHEME_hash_ptr);

    (void)hv_iterinit(hv);
    while ((entry = hv_iternext(hv))) {
        scheme_hash_set(
            hash,
            scheme_intern_symbol( hv_iterkey(entry, &retlen) ),
            mzscheme_from_perl_scalar( hv_iterval(hv, entry) )
        );
    }

    return (Scheme_Object *)hash;
}

Scheme_Object *
mzscheme_from_perl_scalar (Perl_Scalar sv) {
    Scheme_Object *temp;

    return (
        SvROK(sv) ?
            (SWIG_ConvertPtr(sv, (void **) &temp, SWIGTYPE_p_Scheme_Object, 0) >= 0)
                ? temp :
            sv_isobject(sv)
                ? mzscheme_make_perl_object_w_arity(
                    sv, Perl_form(aTHX_ "REF(0x%"UVxf")", PTR2UV(SvRV(sv))), 1, -1, NULL
                ) :
            (SvTYPE(SvRV(sv)) == SVt_PVCV)
                ? mzscheme_make_perl_prim_w_arity(sv, SvPV(sv, PL_na), 0, -1, NULL) :
            (SvTYPE(SvRV(sv)) == SVt_PVAV)
                ? mzscheme_from_perl_arrayref(sv) :
            (SvTYPE(SvRV(sv)) == SVt_PVHV)
                ? mzscheme_from_perl_hashref(sv) :
                scheme_box(mzscheme_from_perl_scalar((Perl_Scalar)SvRV(sv)))
            :
        SvIOK(sv) ? scheme_make_integer_value( (int)SvIV(sv) ) :
        SvNOK(sv) ? scheme_make_double( (double)SvNV(sv) ) :
        SvPOK(sv) ? scheme_make_string( (char *)SvPV(sv, PL_na) ) : scheme_void
    );
}

Scheme_Object *
mzscheme_from_perl_symbol (Perl_Scalar sv) {
    Scheme_Object *temp;

    /* XXX - eventually rewrite the symbol logic from ROK */
    return (
        SvROK(sv) ?
            (SWIG_ConvertPtr(sv, (void **) &temp, SWIGTYPE_p_Scheme_Object, 0) >= 0)
                ? temp :
            sv_isobject(sv)
                ? mzscheme_make_perl_object_w_arity(
                    sv, Perl_form(aTHX_ "REF(0x%"UVxf")", PTR2UV(SvRV(sv))), 1, -1, NULL
                ) :
            (SvTYPE(SvRV(sv)) == SVt_PVCV)
                ? mzscheme_make_perl_prim_w_arity(sv, SvPV(sv, PL_na), 0, -1, NULL) :
            (SvTYPE(SvRV(sv)) == SVt_PVAV)
                ? mzscheme_from_perl_arrayref(sv) :
            (SvTYPE(SvRV(sv)) == SVt_PVHV)
                ? mzscheme_from_perl_hashref(sv) :
                scheme_box(mzscheme_from_perl_scalar((Perl_Scalar)SvRV(sv)))
            :
        SvIOK(sv) ? scheme_make_integer_value( (int)SvIV(sv) ) :
        SvNOK(sv) ? scheme_make_double( (double)SvNV(sv) ) :
        SvPOK(sv) ? scheme_intern_symbol( (char *)SvPV(sv, PL_na) ) : scheme_void
    );
}

Perl_Scalar
mzscheme_to_perl_scalar (Scheme_Object *obj) {
    if (MZSCHEME_PERLP(obj)) {
        return ((Perl_Callback *)SCHEME_CLSD_PRIM_DATA(obj))->sv;
    }
    else {
        Perl_Scalar sv = sv_newmortal();
        SWIG_MakePtr(sv, (void *)obj, SWIGTYPE_p_Scheme_Object, 0);
        return sv;
    }
}

void
_mzscheme_enter (int argc, Scheme_Object **argv) {
    dSP ;
    int i;

    push_scope() ;
    SAVETMPS;

    PUSHMARK(SP) ;
    EXTEND(SP, argc);

    for (i = 0; i < argc; i++) {
        PUSHs(mzscheme_to_perl_scalar(argv[i]));
    }

    PUTBACK ;
}

void
_mzscheme_enter_with_sv (Perl_Scalar sv, int argc, Scheme_Object **argv) {
    dSP ;
    int i;

    push_scope() ;
    SAVETMPS;

    PUSHMARK(SP) ;
    EXTEND(SP, argc);

    PUSHs(sv);

    for (i = 1; i < argc; i++) {
        PUSHs(mzscheme_to_perl_scalar(argv[i]));
    }

    PUTBACK ;
}

Scheme_Object *
_mzscheme_leave (int count, char sigil) {
    dSP;
    Scheme_Object *rv = NULL;
    Scheme_Object **return_values;
    int i;

    SPAGAIN ;

    if (sigil == Perl_Context_AUTO) {
        /* Auto-context */
        sigil = ((count == 1) ? Perl_Context_SCALAR : Perl_Context_LIST);
    }

    switch (sigil) {
        case Perl_Context_VOID :
            rv = scheme_void;
            break;
        case Perl_Context_BOOLEAN :
            rv = (((count > 0) && SvTRUE(TOPs)) ? scheme_true : scheme_false);
            break;
        case Perl_Context_SCALAR :
            rv = ((count > 0) ? mzscheme_from_perl_scalar(TOPs) : scheme_null);
            break;
        case Perl_Context_STRING :
            rv = scheme_make_string( (count > 0) ? (char *)SvPV(TOPs, PL_na) : "" );
            break;
        case Perl_Context_NUMBER :
            rv = ((count > 0) ? SvIOK(TOPs) ? scheme_make_integer_value( (int)SvIV(TOPs) )
                              : SvNOK(TOPs) ? scheme_make_double( (double)SvNV(TOPs) )
                                            : (strchr(SvPV(TOPs, PL_na), '.') == NULL)
                                                ? scheme_make_integer_value( (int)SvIV(TOPs) )
                                                : scheme_make_double( (double)SvNV(TOPs) )
                              : scheme_make_integer_value(0));
            break;
        case Perl_Context_CHAR : {
            char *tmpstr;
            rv = scheme_make_character(
                ((count > 0) && (tmpstr = SvPV(TOPs, PL_na))) ? *tmpstr : '\0'
            );
        }   break;
        case Perl_Context_HASH : {
            Scheme_Hash_Table *hash = scheme_make_hash_table(SCHEME_hash_ptr);
            if ((count % 2) == 1) {
                scheme_hash_set(
                    hash,
                    mzscheme_from_perl_symbol(POPs),
                    scheme_void
                );
                count--;
            }
            for (i = 0; i < count ; i+=2) {
                rv = mzscheme_from_perl_symbol(POPs);
                scheme_hash_set(
                    hash,
                    mzscheme_from_perl_symbol(POPs),
                    rv
                );
            }
            rv = (Scheme_Object *)hash;
        }   break;
        case Perl_Context_ALIST : {
            return_values = (Scheme_Object **) malloc(((int)(count/2)+3)*sizeof(Scheme_Object *));
            if ((count % 2) == 1) { 
                count--;
                return_values[count / 2] = scheme_make_pair(
                    mzscheme_from_perl_scalar(POPs),
                    scheme_null
                );
            }
            count = count / 2;
            for (i = count - 1; i >= 0 ; i--) {
                rv = mzscheme_from_perl_scalar(POPs);
                return_values[i] = scheme_make_pair(
                    mzscheme_from_perl_scalar(POPs),
                    rv
                );
            }
            rv = scheme_build_list(count, return_values);
        }   break;
        case Perl_Context_VECTOR :
            rv = scheme_make_vector(count+1, NULL);
            SCHEME_VEC_SIZE(rv) = count;
            for (i = count - 1; i >= 0 ; i--) {
                SCHEME_VEC_ELS(rv)[i] = mzscheme_from_perl_scalar(POPs);
            }
            SCHEME_VEC_ELS(rv)[count] = NULL;
            break;
        default: /* LIST */
            if (count == 0) {
                rv = scheme_null;
            }
            else {
                return_values = (Scheme_Object **) malloc((count+2)*sizeof(Scheme_Object *));
                for (i = count - 1; i >= 0 ; i--) {
                    return_values[i] = mzscheme_from_perl_scalar(POPs);
                }
                rv = scheme_build_list((int)count, return_values);
            }
    }

    PUTBACK ;
    FREETMPS ;
    LEAVE ;

    return rv;
}

Scheme_Object *
_mzscheme_closed_prim_CV (void *callback, int argc, Scheme_Object **argv) {
    char sigil = ((Perl_Callback *)callback)->sigil;

    _mzscheme_enter(argc, argv);
    return _mzscheme_leave(
        (int)call_sv( ((Perl_Callback *)callback)->sv, Perl_Context(sigil) ),
        sigil
    );
}

Scheme_Object *
_mzscheme_closed_prim_OBJ (void *callback, int argc, Scheme_Object **argv) {
    char sigil = ((Perl_Callback *)callback)->sigil;
    char *method;

    if (argc == 0) {
        return scheme_undefined;
    }

    method = savepv(SCHEME_STRSYM_VAL(argv[0]));
    if (sigil == NULL) {
        char *i = method;
        while (*i) { i++; }
        if (ispunct(*--i)) {
            sigil = *i;
            *i = NULL;
        }
    }
    _mzscheme_enter_with_sv(((Perl_Callback *)callback)->sv, argc, argv);
    return _mzscheme_leave(
        (int)call_method( method, Perl_Context(sigil) ),
        sigil
    );
}

AV *
_mzscheme_objects_AV (void **objects, char *type) {
    AV *myav;
    SV **svs;
    int i = 0, len = 0;
    while (objects[len]) {
        len++;
    };
    svs = (SV **)malloc(len*sizeof(SV *));
    for (i = 0; i < len ; i++) {
        svs[i] = mzscheme_to_perl_scalar(objects[i]);
    };
    myav = av_make(len, svs);
    free(svs);
    return myav;
}

int
_mzscheme_alistp (Scheme_Object *object) {
    return (SCHEME_NULLP(object) || (
        SCHEME_PAIRP(object) &&
        SCHEME_PAIRP(SCHEME_CAR(object)) &&
        !SCHEME_LISTP(SCHEME_CAAR(object)) && (
            (!SCHEME_PAIRP(SCHEME_CDR(SCHEME_CAR(object)))) ||
            SCHEME_NULLP(SCHEME_CDDR(SCHEME_CAR(object)))
        ) &&
        _mzscheme_alistp(SCHEME_CDR(object))
    ));
}

Scheme_Object **
_mzscheme_from_perl_arrayref_to_objects (Perl_Scalar sv) {
    Scheme_Object **rv;
    AV *tempav;
    I32 len;
    int i;
    SV  **tv;

    tempav = (AV*)SvRV(sv);
    len = av_len(tempav);
    rv = malloc((len+2)*sizeof(Scheme_Object *));

    for (i = 0; i <= len; i++) {
        tv = av_fetch(tempav, i, 0);
        rv[i] = mzscheme_from_perl_scalar(*tv);
    }
    rv[i] = NULL;
    return rv;
}

Scheme_Object *
mzscheme_do_apply (Scheme_Object *f, int c, Scheme_Object **args) {
    MZSCHEME_DO( scheme_apply(f, c, args) );
}

Scheme_Object *
mzscheme_do_eval (Scheme_Object *expr, Scheme_Env *env) {
    MZSCHEME_DO( scheme_eval(expr, env) );
}

Scheme_Object *
mzscheme_do_eval_string_all (char *str, Scheme_Env *env, int all) {
    MZSCHEME_DO( scheme_eval_string_all(str, env, all) );
}
