#include "EXTERN.h"
#include "perl.h"

/*
 * chocolateboy 2009-02-08
 *
 * for binary compatibility (see perlapi.h), XS modules perform a function call to
 * access each and every interpreter variable. So, for instance, an innocuous-looking
 * reference to PL_op becomes:
 *
 *     (*Perl_Iop_ptr(my_perl))
 *
 * This (obviously) impacts performance. Internally, PL_op is accessed as:
 *
 *     my_perl->Iop
 *
 * (in threaded/multiplicity builds (see intrpvar.h)), which is significantly faster.
 *
 * defining PERL_CORE gets us the fast version, at the expense of a future maintenance release
 * possibly breaking things: http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2008-04/msg00171.html
 *
 * Rather than globally defining PERL_CORE, which pokes its fingers into various headers, exposing
 * internals we'd rather not see, just define it for XSUB.h, which includes
 * perlapi.h, which imposes the speed limit.
 */

#define PERL_CORE
#include "XSUB.h"
#undef PERL_CORE

#define NEED_sv_2pv_flags
#include "ppport.h"

#include "hook_op_check.h"
#include "hook_op_annotation.h"
#include "mro.h"

#include <string.h> /* for strchr and strlen */
/* #define NDEBUG */
#include <assert.h>

#define METHOD_LEXICAL_INSTALLED "Method::Lexical"

#define METHOD_LEXICAL_ENABLED(table, svp)                                                            \
    ((PL_hints & 0x20000) &&                                                                          \
    (table = GvHVn(PL_hintgv)) &&                                                                     \
    (svp = hv_fetch(table, METHOD_LEXICAL_INSTALLED, sizeof(METHOD_LEXICAL_INSTALLED) - 1, FALSE)) && \
    *svp &&                                                                                           \
    SvOK(*svp) &&                                                                                     \
    SvROK(*svp) &&                                                                                    \
    SvRV(*svp) &&                                                                                     \
    SvTYPE(SvRV(*svp)) == SVt_PVHV)

typedef struct MethodLexicalDataList {
    const HV *stash;
    U32 generation;
    const CV *cv;
    const SV * method;
    struct MethodLexicalDataList *next;
} MethodLexicalDataList;

typedef struct MethodLexicalData {
    HV *hv;
    MethodLexicalDataList *list;
    U32 dynamic;
    U32 autoload;
} MethodLexicalData;

STATIC CV * method_lexical_hash_get(pTHX_ const HV * const hv, const SV * const key);
STATIC HV * method_lexical_get_fqname_stash(pTHX_ SV **method_sv_ptr, char **class_name_ptr);
STATIC HV * method_lexical_get_invocant_stash(pTHX_ SV * const invocant, char **class_name_ptr);
STATIC HV * method_lexical_get_super_stash(pTHX_ const char * const class_name, char **class_name_ptr);
STATIC MethodLexicalData * method_lexical_data_new(pTHX_ HV * const hv, const U32 dynamic, const U32 autoload);
STATIC OP * method_lexical_check_method_dynamic(pTHX_ OP * o);
STATIC OP * method_lexical_check_method(pTHX_ OP * o, void *user_data);
STATIC OP * method_lexical_check_method_static(pTHX_ OP * o);
STATIC OP * method_lexical_method_dynamic(pTHX);
STATIC OP * method_lexical_method_static(pTHX);
STATIC void method_lexical_data_free(pTHX_ void *data);
STATIC void method_lexical_data_list_free(pTHX_ void *vp);
STATIC void method_lexical_enter();
STATIC void method_lexical_leave();

STATIC MethodLexicalDataList * method_lexical_data_list_new(
    pTHX_
    const HV * const stash,
    const U32 generation,
    const SV * const method,
    const CV * const cv
);

STATIC SV *method_lexical_cache_fetch(
    pTHX_
    MethodLexicalData *data,
    const HV * const stash,
    const SV * const method,
    U32 * const found
);

STATIC void method_lexical_cache_store(
    pTHX_
    MethodLexicalData * const data,
    const HV * const stash,
    const U32 generation,
    const SV * const method,
    const CV * const cv
);

STATIC SV * method_lexical_method_common(
    pTHX_
    MethodLexicalData * const data,
    const HV * const stash,
    const char * const class_name,
    const SV * const method
);

STATIC void method_lexical_cache_remove(
    pTHX_
    MethodLexicalData * const data,
    MethodLexicalDataList *prev,
    MethodLexicalDataList *head
);

STATIC void method_lexical_set_autoload(
    pTHX_
    const HV * const stash,
    const char * const class_name,
    const SV *method,
    CV * cv
);

STATIC CV *method_lexical_lookup_method(
    pTHX_
    const HV * const stash,
    const HV * const installed,
    const char * const class_name,
    const char * const name,
    U32 *generation_ptr
);

STATIC hook_op_check_id method_lexical_check_method_id = 0;
STATIC OPAnnotationGroup METHOD_LEXICAL_ANNOTATIONS = NULL;
STATIC U32 METHOD_LEXICAL_COMPILING = 0;
STATIC U32 METHOD_LEXICAL_DEBUG = 0;

STATIC MethodLexicalData * method_lexical_data_new(pTHX_ HV * const hv, const U32 dynamic, const U32 autoload) {
    MethodLexicalData *data;

    Newx(data, 1, MethodLexicalData);

    if (!data) {
        croak("Method::Lexical: couldn't allocate annotation data");
    }

    data->hv = (HV * const)SvREFCNT_inc(hv); /* this is needed to prevent the hash being garbage-collected */
    data->dynamic = dynamic;
    data->autoload = autoload;
    data->list = NULL;

    return data;
}

STATIC void method_lexical_data_free(pTHX_ void *vp) {
    MethodLexicalData *data = (MethodLexicalData *)vp;

    if (data->list) {
        method_lexical_data_list_free(aTHX_ data->list);
    }

    SvREFCNT_dec(data->hv);
    Safefree(data);
}

STATIC MethodLexicalDataList * method_lexical_data_list_new(
    pTHX_
    const HV * const stash,
    const U32 generation,
    const SV * const method,
    const CV * const cv
) {
    MethodLexicalDataList *list;
    Newx(list, 1, MethodLexicalDataList);

    if (!list) {
        croak("Method::Lexical: couldn't allocate annotation data list");
    }

    /* the refcount increments are needed to prevent the values being garbage-collected */
    list->stash = (HV *const)SvREFCNT_inc(stash);
    list->method = method ? (SV * const)SvREFCNT_inc(method) : method;
    list->generation = generation;
    list->cv = (CV * const)SvREFCNT_inc(cv);
    list->next = NULL;

    return list;
}

STATIC void method_lexical_data_list_free(pTHX_ void *vp) {
    MethodLexicalDataList *list = (MethodLexicalDataList *)vp;
    MethodLexicalDataList *temp;

    while (list) {
        temp = list->next;
        SvREFCNT_dec(list->stash);
        SvREFCNT_dec(list->method);
        SvREFCNT_dec(list->cv);
        Safefree(list);
        list = temp;
    }
}

/*
 * TODO
 *
 * the method name may be qualified e.g.
 *
 *     $self->Foo::Bar::baz($quux);
 *
 * in this case, we can turn it into a subroutine call:
 *
 *     Foo::Bar::baz($self, $quux)
 *
 * XXX: Perl_ck_method does not turn fully-qualified names into OP_METHOD_NAMED
 * XXX: Perl_ck_method does not normalize fully-qualified names i.e. need to s/'/::/g
 */

STATIC OP * method_lexical_check_method(pTHX_ OP * o, void * user_data) {
     PERL_UNUSED_VAR(user_data);

    /*
     * Perl_ck_method can upgrade an OP_METHOD to an OP_METHOD_NAMED (perly.y
     * channels all method calls through newUNOP(OP_METHOD)),
     * so we need to assign the right method op_ppaddr, or bail if the OP's no
     * longer a method (i.e. another module has changed it)
     */

    if (o->op_type == OP_METHOD_NAMED) {
        return method_lexical_check_method_static(aTHX_ o);
    } else if (o->op_type == OP_METHOD) {
        return method_lexical_check_method_dynamic(aTHX_ o);
    }

    return o;
}

STATIC OP * method_lexical_check_method_dynamic(pTHX_ OP * o) {
    HV * table;
    SV ** svp;

    /* if there are bindings for the currently-compiling scope in $^H{METHOD_LEXICAL_INSTALLED} */
    if (METHOD_LEXICAL_ENABLED(table, svp)) {
        MethodLexicalData *data;
        HV *installed = (HV *)SvRV(*svp);

        /* FIXME autoload == TRUE is hardwired for dynamic lookups for now */
        data = method_lexical_data_new(aTHX_ installed, TRUE, TRUE);
        op_annotate(METHOD_LEXICAL_ANNOTATIONS, o, (void *)data, method_lexical_data_free);
        o->op_ppaddr = method_lexical_method_dynamic;
    }

    return o;
}

STATIC OP * method_lexical_check_method_static(pTHX_ OP * o) {
    HV * table;
    SV ** svp;

    /* if there are bindings for the currently-compiling scope in $^H{METHOD_LEXICAL_INSTALLED} */
    if (METHOD_LEXICAL_ENABLED(table, svp)) {
        STRLEN fqnamelen, namelen;
        HE *entry;
        HV *installed = (HV *)SvRV(*svp);
        UV count = 0;
        SV *method = cSVOPo->op_sv;
        const char *fqname, *name = SvPV_const(method, namelen);
        U32 autoload = FALSE;

        hv_iterinit(installed);

        while ((entry = hv_iternext(installed))) {
            const char *rcolon;

            fqname = HePV(entry, fqnamelen);

            /*
             * There are 2 options:
             *
             * 1) count == 0: the name isn't in the hash: don't change the op_ppaddr
             * 2) count >  0: this *may* be a lexical method call - change the op_ppaddr
             */

            rcolon = strrchr(fqname, ':');

            /* WARN("comparing OP method (%*s) => fqname method (%s)", namelen, name, rcolon + 1); */
            /* if (strnEQ(name, rcolon + 1, namelen)) */
            if ((strnEQ(rcolon + 1, "AUTOLOAD", 8) && (autoload = TRUE)) || strnEQ(name, rcolon + 1, namelen)) {
                ++count;
            }
        }

        if (count) {
            MethodLexicalData *data;

            data = method_lexical_data_new(aTHX_ installed, FALSE, autoload);
            op_annotate(METHOD_LEXICAL_ANNOTATIONS, o, (void *)data, method_lexical_data_free);
            o->op_ppaddr = method_lexical_method_static;
        } /* else no lexical method of this name */
    }

    return o;
}

/*
 * this handles:
 *
 *     1) $foo->$bar # $bar is a code ref
 *     2) $foo->Bar::baz
 *     3) $foo->SUPER::bar
 *     4) $foo->$bar # $bar is a method name
 *
 * 1) is quick and easy to handle in all cases as the method CV we're supposed to look up
 * has already been supplied
 *
 * 2) is syntactic sugar for:
 *
 *     &Bar::baz($foo)
 *
 * perl always turns these into (or rather keeps them as) OP_METHOD rather than OP_METHOD_NAMED.
 * ideally, we should rewrite these as static subroutine calls at compile-time in
 * method_lexical_check_method, although that's strictly not the responsibility of this module.
 * it could be done in another module (Method::Peep?), which we could use
 * (it would need to hook PL_check[OP_METHOD] before us). As it currently stands, though, we can't
 * determine the stash (Bar) containing the CV (baz) from the invocant ($foo); we need to extract it from
 * the method name. So we hand the method name off to method_lexical_get_fqname_stash.
 *
 * 3) is like 2) but complicated by the peculiar semantics [1] of the SUPER pseudo-package,
 * which is handled by method_lexical_get_fqname_stash.
 *
 * 4) is like a static method call (i.e. we can get the stash from the invocant), but
 * we don't know that till we've looked at what's in $bar. Again, method_lexical_get_fqname_stash
 * handles this, and delegates to method_lexical_get_invocant_stash if the method name is "simple",
 * i.e. not qualified (no double colons or single quotes)
 *
 * So: 1) is trivial; 2) could be optimized away at compile-time; 3) is a pain that we have
 * to deal with (we can't resolve it at compile time, because even though SUPER refers to the
 * superclass of the package the SUPER call is compiled in (rather than the invocant's superclass),
 * that package's superclass(es) can still be changed at runtime; 4) requires us to scan the string,
 * so we may as well handle 2) (for now), and 3) while we're at it.
 *
 * On the plus side, none of these idioms are especially common. The bareword unqualified method name
 * is the common case.
 *
 * [1] http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2008-01/msg00809.html
 */

STATIC OP * method_lexical_method_dynamic(pTHX) {
    dSP;
    SV * cv;
    SV * method_sv = TOPs;

    if (SvROK(method_sv) && (cv = SvRV(method_sv)) && (SvTYPE(cv) == SVt_PVCV)) {
        SETs(cv);
        RETURN;
    } else {
        char *class_name;
        const OPAnnotation * annotation = op_annotation_get(METHOD_LEXICAL_ANNOTATIONS, PL_op);
        const HV * const stash = method_lexical_get_fqname_stash(aTHX_ &method_sv, &class_name);

        if (stash) {
            U32 found;
            MethodLexicalData * data;
            data = (MethodLexicalData *)annotation->data;
            cv = method_lexical_cache_fetch(aTHX_ data, stash, method_sv, &found);

            if (!found) {
                /* look it up the slow way - caches the result (which may be NULL) */
                cv = method_lexical_method_common(aTHX_ data, stash, class_name, method_sv);
            }

            if (cv) {
                SETs(cv);
                RETURN;
            } /* else cached, but NULL i.e. not a lexical method - fall through */
        } /* some weird invocant without a stash: fall through and let perl deal with it */

        return annotation->op_ppaddr(aTHX);
    }
}

STATIC OP *method_lexical_method_static(pTHX) {
    dSP;
    char *class_name;
    const OPAnnotation * const annotation = op_annotation_get(METHOD_LEXICAL_ANNOTATIONS, PL_op);
    SV * const invocant = *(PL_stack_base + TOPMARK + 1);
    const HV * const stash = method_lexical_get_invocant_stash(aTHX_ invocant, &class_name);

    if (stash) {
        U32 found;
        const SV * const method = cSVOP_sv;
        MethodLexicalData * const data = (MethodLexicalData *)annotation->data;
        SV *cv = method_lexical_cache_fetch(aTHX_ data, stash, method, &found);

        if (!found) {
            /* look it up the slow way - caches the result (which may be NULL) */
            cv = method_lexical_method_common(aTHX_ data, stash, class_name, method);
        }

        if (cv) {
            XPUSHs(cv);
            RETURN;
        } /* else cached, but NULL i.e. not a lexical method - fall through */
    } /* some weird invocant without a stash: fall through and let perl deal with it */

    return annotation->op_ppaddr(aTHX);
}

STATIC SV * method_lexical_method_common(
    pTHX_
    MethodLexicalData * const data,
    const HV * const stash,
    const char * const class_name,
    const SV * const method
) {
    const char * name;
    HV * const installed = data->hv;
    CV *cv;
    U32 generation;
    STRLEN namelen;

    name = SvPV((SV *)method, namelen); /* temporarily cast off constness */
    cv = method_lexical_lookup_method(aTHX_ stash, installed, class_name, name, &generation);

    if (!cv && data->autoload) {
        const GV * gv;

        generation = mro_get_pkg_gen(stash);

        if (METHOD_LEXICAL_DEBUG) {
            warn("Method::Lexical: looking up: %s::%s (public)", class_name, name);
        }

        gv = gv_fetchmethod((HV *)stash, name); /* temporarily cast off constness */

        if (gv) {
            if (METHOD_LEXICAL_DEBUG) {
                warn("Method::Lexical: found: %s::%s (public)", class_name, name);
            }
            cv = isGV(gv) ? GvCV(gv) : (CV *)gv;
        } else {
            cv = method_lexical_lookup_method(aTHX_ stash, installed, class_name, "AUTOLOAD", NULL);

            if (cv) {
                method_lexical_set_autoload(aTHX_ stash, class_name, method, cv);
            }
        }
    }

    method_lexical_cache_store(aTHX_ data, stash, generation, method, cv);

    return (SV *)cv;
}

STATIC CV * method_lexical_lookup_method(
    pTHX_
    const HV * const stash,
    const HV * const installed,
    const char * const class_name,
    const char * const name,
    U32 *generation_ptr
) {
    const SV *key;
    CV *cv;

    key = sv_2mortal(newSVpvf("%s::%s", class_name, name));
    cv = method_lexical_hash_get(aTHX_ installed, key);

    if (cv) {
        /*
         * the installed hash ($^H{'Method::Lexical'}) can't be modified/countermanded
         * after the fact, so its lookups can be cached without recourse to the same
         * generational invalidation as "public" methods
         */
        if (generation_ptr) {
            *generation_ptr = 0;
        }
    } else { /* try superclasses */
        U32 items;
        SV ** svp;
        const AV *isa;

        if (generation_ptr) {
            *generation_ptr = mro_get_pkg_gen(stash);
        }

        isa = mro_get_linear_isa((HV *)stash); /* temporarily cast off constness */
        items = AvFILLp(isa) + 1; /* add 1 (even though we're skipping self) to include the appended "UNIVERSAL" */
        svp = AvARRAY(isa) + 1;   /* skip self */

        while (items--) { /* always entered, if only for "UNIVERSAL" */
            SV *class_name_sv;

            if (items == 0) {
                class_name_sv = sv_2mortal(newSVpvn("UNIVERSAL", 9));
            } else {
                class_name_sv = *svp++;
            }

            key = sv_2mortal(newSVpvf("%s::%s", SvPVX(class_name_sv), name));
            cv = method_lexical_hash_get(aTHX_ installed, key);

            if (cv) {
                break;
            }
        }
    }

    return cv;
}

STATIC void method_lexical_set_autoload(
    pTHX_
    const HV * const stash,
    const char * const class_name,
    const SV *method,
    CV * cv
) {

#ifndef CvISXSUB
#  define CvISXSUB(cv) (CvXSUB(cv) ? TRUE : FALSE)
#endif

    assert(CvROOT(cv) || CvISXSUB(cv));

    /* <copypasta file="gv.c" function="gv_autoload4"> */

#ifndef USE_5005THREADS /* chocolateboy: shouldn't be defined after 5.8.x */
    if (CvISXSUB(cv)) {

        /* rather than lookup/init $AUTOLOAD here
         * only to have the XSUB do another lookup for $AUTOLOAD
         * and split that value on the last '::',
         * pass along the same data via some unused fields in the CV
         */

        /* chocolateboy 2011-03-13: portability fix for perl 5.13 */
#ifdef CvSTASH_set
        CvSTASH_set(cv, (HV *)stash); /* temporarily cast off constness */
#else
        CvSTASH(cv) = (HV *)stash; /* temporarily cast off constness */
#endif

        SvPV_set(cv, (char *)SvPVX(method)); /* cast to lose constness warning */
        SvCUR_set(cv, SvCUR(method));
        return;
    } else
#endif

    {
        HV* varstash;
        GV* vargv;
        SV* varsv;

        /*
         * Given &FOO::AUTOLOAD, set $FOO::AUTOLOAD to desired function name.
         * The subroutine's original name may not be "AUTOLOAD", so we don't
         * use that, but for lack of anything better we will use the sub's
         * original package to look up $AUTOLOAD.
         */
        varstash = GvSTASH(CvGV(cv));
        vargv = *(GV**)hv_fetch(varstash, "AUTOLOAD", 8, TRUE);
        ENTER;

#ifdef USE_5005THREADS /* chocolateboy: shouldn't be defined after 5.8.x */
        sv_lock((SV *)varstash);
#endif

        if (!isGV(vargv)) {
            gv_init(vargv, varstash, "AUTOLOAD", 8, FALSE);
#ifdef PERL_DONT_CREATE_GVSV
            GvSV(vargv) = newSV(0);
#endif
        }
        LEAVE;

#ifndef GvSVn
#  ifdef PERL_DONT_CREATE_GVSV
#    define GvSVn(gv) (*(GvGP(gv)->gp_sv ? &(GvGP(gv)->gp_sv) : &(GvGP(gv_SVadd(gv))->gp_sv)))
#  else
#    define GvSVn(gv) GvSV(gv)
#  endif
#endif

        varsv = GvSVn(vargv);

#ifdef USE_5005THREADS /* chocolateboy: shouldn't be defined after 5.8.x */
        sv_lock(varsv);
#endif

        sv_setpv(varsv, class_name);
        sv_catpvs(varsv, "::");
        /* Ensure SvSETMAGIC() is called if necessary. In particular, to clear
           tainting if $FOO::AUTOLOAD was previously tainted, but is not now.  */
        sv_catpv_mg(varsv, SvPVX(method));
    }

    /* </copypasta> */
}

STATIC HV *method_lexical_get_invocant_stash(pTHX_ SV * const invocant, char **class_name_ptr) {
    HV *stash = NULL;
    char *class_name = NULL;
    STRLEN packlen;

    SvGETMAGIC(invocant);

    if (!(invocant && SvOK(invocant))) {
        goto done;
    }

    if (SvROK(invocant)) {
        if (SvOBJECT(SvRV(invocant))) { /* blessed reference */
#ifdef HvNAME_HEK
            HEK *hek;

            if (
                (stash = SvSTASH(SvRV(invocant))) &&
                (hek = HvNAME_HEK(stash)) &&
                (class_name = HEK_KEY(hek))
            ) {
                goto done;
            }
#else
            if (
                ((stash = SvSTASH(SvRV(invocant)))) &&
                (class_name = HvNAME(stash))
            ) {
                goto done;
            }
#endif
        } /* unblessed reference */
    } else if ((class_name = SvPV(invocant, packlen))) { /* not a reference: try package name */
        const HE *const he = hv_fetch_ent(PL_stashcache, invocant, 0, 0);

        if (he) {
            stash = INT2PTR(HV *, SvIV(HeVAL(he)));
        } else if ((stash = gv_stashpvn(class_name, packlen, 0))) {
            SV *const sref = newSViv(PTR2IV(stash));
            (void)hv_store(PL_stashcache, class_name, packlen, sref, 0);
        } /* can't find a stash */
    }

    done:
        if (class_name_ptr) {
            *class_name_ptr = class_name;
        }

        return stash;
}

STATIC HV * method_lexical_get_super_stash(pTHX_ const char * const class_name, char **class_name_ptr) {
    SV * const invocant = sv_2mortal(newSVpv(class_name, 0));
    HV * stash = method_lexical_get_invocant_stash(aTHX_ invocant, NULL);

    if (stash) {
        AV * const isa = mro_get_linear_isa((HV *)stash); /* temporarily cast off constness */

        /* AvFILL is $#ARRAY i.e. -1 if the array is empty, so > 0 means two or more */
        if (isa && ((AvFILL(isa)) > 0)) { /* at least two items: self and the superclass */
            SV * const * const svp = AvARRAY(isa) + 1; /* skip self */

            if (svp && *svp) {
                assert(SvOK(*svp));
                return method_lexical_get_invocant_stash(aTHX_ *svp, class_name_ptr);
            }
        }
    }

    return stash;
}

STATIC HV * method_lexical_get_fqname_stash(pTHX_ SV **method_sv_ptr, char **class_name_ptr) {
    HV * stash = NULL;
    const char * fqname;
    STRLEN len, last, i, offset = 0; /* XXX bugfix: make sure offset is initialized to 0 */
    SV * invocant_sv, *normalized_sv = NULL, *fqmethod_sv = *method_sv_ptr;

    fqname = SvPV(fqmethod_sv, len);
    last = len - 1;

    /*
     * kill two birds with one scan:
     *
     * 1) normalized_sv: normalize the fully-qualified name if it contains '\'' i.e. s/'/::/g
     * 2) offset: find the offset (in fqname) of the start of the unqualified method name i.e.
     * the offset of "baz" in "Foo::Bar::baz"
     */

    for (i = 0; i < last; ++i) {
        if ((fqname[i] == ':') && (fqname[i + 1] == ':')) {
            offset = i + 2;
            ++i; /* in conjunction with the ++i above, this skips both colons */
        } else if (fqname[i] == '\'') {
            STRLEN j;
            normalized_sv = sv_2mortal(newSVpv(fqname, i));
            sv_catpvs(normalized_sv, "::");
            offset = i + 1;

            /*
             * with
             *
             *     Foo'b
             *
             * we need to append 'b' to normalized_sv, so j must range
             * up to len - 1 (in this case: 4) rather than i's upper bound (above), which
             * only ranges up to len - 2 (e.g. 3). In the case above, we're not copying characters,
             * and so can use a reduced upper bound to remove a bounds check. In this case we
             * are copying, and thus need to scan to the end and include the bounds check.
             */
            for (j = offset; j < len; ++j) {
                if (fqname[j] == '\'') {
                    sv_catpvs(normalized_sv, "::");
                    offset = j + 1;
                } else if ((fqname[j] == ':') && (j < last) && (fqname[j + 1] == ':')) {
                    sv_catpvs(normalized_sv, "::");
                    offset = j + 2;
                    ++j; /* in conjunction with the ++j above, this skips both colons */
                } else {
                    sv_catpvn(normalized_sv, fqname + j, 1);
                }
            }

            break;
        }
    }

    if (offset) {
        /*
         * offset might be out of bounds if the name is mangled, which shouldn't happen
         * for a static name, but e.g.
         *
         *     my $name = "foo'";
         *     $self->$name();
         *
         * so check that the offset (4 in this case) is sane
         */
        if (offset == len) {
            goto done;
        } else {
            STRLEN method_len = len - offset;
            char *class_name;
            STRLEN class_name_len;

            if (normalized_sv) {
                fqmethod_sv = normalized_sv;
            }

            *method_sv_ptr = sv_2mortal(newSVpvn(fqname + offset, len - offset));
            invocant_sv = sv_2mortal(newSVpvn(SvPVX(fqmethod_sv), SvCUR(fqmethod_sv) - (method_len + 2)));

            class_name = SvPV(invocant_sv, class_name_len);

            /*
             * we need to intercept SUPER before perl gets its hands on the method name
             * (in method_lexical_get_invocant_stash) because perl handles SUPER differently,
             * autovivifying stashes with a ::SUPER suffix - e.g. %Foo::SUPER:: - to create @Foo::SUPER::ISA
             * (see gv_get_super_pkg in gv.c). This causes lookups to succeed when we want them to fail (so that
             * we can fall back to perl).
             *
             * if valid, the class name either a) is "SUPER", b) ends with "::SUPER",
             * or c) doesn't contain "SUPER"
             *
             * if b), make sure it's prefixed with at least one character
             */

            if (strnEQ(class_name, "SUPER", 5)) {
                assert(CopSTASHPV(PL_curcop)); /* FIXME - CopSTASHPV can be NULL */
                return method_lexical_get_super_stash(aTHX_ CopSTASHPV(PL_curcop), class_name_ptr);
            } else if ((class_name_len > 7) && strnEQ(class_name + (class_name_len - 7), "::SUPER", 7)) {
                class_name[(class_name_len - 7)] = '\0';
                return method_lexical_get_super_stash(aTHX_ class_name, class_name_ptr);
            }
        }
    }

    /* unqualified method name: don't change the method SV */
    invocant_sv = *(PL_stack_base + TOPMARK + 1);
    stash = method_lexical_get_invocant_stash(aTHX_ invocant_sv, class_name_ptr);

    done:
        return stash;
}

STATIC void method_lexical_cache_store(
    pTHX_
    MethodLexicalData * const data,
    const HV * const stash,
    const U32 generation,
    const SV * const method,
    const CV * const cv
) {
    MethodLexicalDataList *list;

    list = method_lexical_data_list_new(aTHX_ stash, generation, method, cv);

    if (data->list) {
        list->next = data->list;
    }

    data->list = list;
}

STATIC void method_lexical_cache_remove(
    pTHX_
    MethodLexicalData * const data,
    MethodLexicalDataList *prev,
    MethodLexicalDataList *head
) {
    if (prev) { /* not first */
        prev->next = head->next;
    } else if (head->next) { /* first */
        data->list = head->next;
    } else { /* only */
        data->list = NULL;
    }

    head->next = NULL;

    method_lexical_data_list_free(aTHX_ head);
}

STATIC SV *method_lexical_cache_fetch(
    pTHX_
    MethodLexicalData *data,
    const HV * const stash,
    const SV * const method,
    U32 * const found
) {
    const CV *cv = NULL;
    U32 generation = 0;

    *found = FALSE;

    if (data->list) {
        MethodLexicalDataList *head, *prev = NULL;

        for (head = data->list; head; prev = head, head = head->next) {
            if ((stash == head->stash) &&
                (!data->dynamic || sv_eq((SV *)method, (SV *)head->method))) { /* cast off constness */
                if (head->generation) {
                    if (!generation) {
                        generation = mro_get_pkg_gen(stash);
                    }

                    /* fresh: cv may be NULL, indicating (still) not found */
                    if (head->generation == generation) {
                        cv = head->cv;
                        *found = TRUE;
                        break;
                    } else { /* stale: remove from list */
                        method_lexical_cache_remove(aTHX_ data, prev, head);
                        break;
                    }
                } else {
                    cv = head->cv;
                    *found = TRUE;
                    break;
                }
            }
        }
    }

    return (SV *)cv;
}

STATIC CV *method_lexical_hash_get(pTHX_ const HV * const hv, const SV * const key) {
    HE *he;

    if (METHOD_LEXICAL_DEBUG) {
        warn("Method::Lexical: looking up: %s (private)", SvPVX(key));
    }

    he = hv_fetch_ent((HV *)hv, (SV *)key, FALSE, 0); /* don't create an undef value if it doesn't exist */

    if (he) {
        const SV * const rv = HeVAL(he);
        if (METHOD_LEXICAL_DEBUG) {
            warn("Method::Lexical: found: %s (private)", SvPVX(key));
        }
        return (CV *)SvRV(rv);
    }

    return NULL;
}

STATIC void method_lexical_enter() {
    if (METHOD_LEXICAL_COMPILING != 0) {
        croak("Method::Lexical: scope overflow");
    } else {
        METHOD_LEXICAL_COMPILING = 1;
        method_lexical_check_method_id = hook_op_check(OP_METHOD, method_lexical_check_method, NULL);
    }
}

STATIC void method_lexical_leave() {
    if (METHOD_LEXICAL_COMPILING != 1) {
        croak("Method::Lexical: scope underflow");
    } else {
        METHOD_LEXICAL_COMPILING = 0;
        hook_op_check_remove(OP_METHOD, method_lexical_check_method_id);
    }
}

MODULE = Method::Lexical                PACKAGE = Method::Lexical

BOOT:
    if (PerlEnv_getenv("METHOD_LEXICAL_DEBUG")) {
        METHOD_LEXICAL_DEBUG = 1;
    }

    METHOD_LEXICAL_ANNOTATIONS = op_annotation_group_new();

void
END()
    CODE:
        if (METHOD_LEXICAL_ANNOTATIONS) { /* make sure it was initialised */
            op_annotation_group_free(aTHX_ METHOD_LEXICAL_ANNOTATIONS);
        }

SV *
xs_get_debug()
    PROTOTYPE:
    CODE:
        RETVAL = newSViv(METHOD_LEXICAL_DEBUG);
    OUTPUT:
        RETVAL

void
xs_set_debug(SV * dbg)
    PROTOTYPE:$
    CODE:
        METHOD_LEXICAL_DEBUG = SvIV(dbg);

char *
xs_signature()
    PROTOTYPE:
    CODE:
        RETVAL = METHOD_LEXICAL_INSTALLED;
    OUTPUT:
        RETVAL

void
xs_enter()
    PROTOTYPE:
    CODE:
        method_lexical_enter();

void
xs_leave()
    PROTOTYPE:
    CODE:
        method_lexical_leave();
