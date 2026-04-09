/*
 * util_compat.h - Perl compatibility macros for util
 * Op sibling navigation (5.22+), refcount, and boot macros
 */

#ifndef FUNCUTIL_COMPAT_H
#define FUNCUTIL_COMPAT_H

/* XS_INTERNAL was introduced in Perl 5.16.
 * On older Perls and Cygwin, static XS() can cause link failures
 * because the symbol isn't exported. XS_INTERNAL marks it correctly. */
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) static XS(name)
#endif

/* Devel::PPPort compatibility - provides many backported macros */
#include "ppport.h"

/* Include shared XOP compatibility for custom ops (5.14+ fallback) */
#include "xop_compat.h"

/* Version checking macro */
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

/* C89/C99/C23 bool compatibility
 * - C89: no bool type, need typedef
 * - C99: bool from <stdbool.h> (macro expanding to _Bool)
 * - C23: bool is a keyword, cannot typedef over it
 *
 * Note: Old Perl defines 'bool' as a macro but not 'true'/'false'
 */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 202311L
   /* C23: bool is a keyword, true/false are keywords - nothing to do */
#elif defined(__bool_true_false_are_defined)
   /* stdbool.h already included with true/false - nothing to do */
#else
   /* bool may or may not be defined by perl.h, but we need true/false */
#  ifndef bool
     typedef int bool;
#  endif
#  ifndef true
#    define true 1
#  endif
#  ifndef false
#    define false 0
#  endif
#endif

/* Op sibling macros - introduced in 5.22 */
#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o)      ((o)->op_sibling != NULL)
#endif

#ifndef OpSIBLING
#  define OpSIBLING(o)          ((o)->op_sibling)
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
#endif

#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif

/* Refcount macros */
#ifndef SvREFCNT_inc_simple_NN
#  define SvREFCNT_inc_simple_NN(sv) SvREFCNT_inc(sv)
#endif

#ifndef SvREFCNT_dec_NN
#  define SvREFCNT_dec_NN(sv) SvREFCNT_dec(sv)
#endif

/* XS boot macros - introduced in 5.22 */
#ifndef dXSBOOTARGSXSAPIVERCHK
#  define dXSBOOTARGSXSAPIVERCHK dXSARGS
#endif

/* Perl_xs_boot_epilog - introduced in 5.21.6 (use 5.22 as safe boundary)
 * Use PERL_IMPLICIT_CONTEXT not USE_ITHREADS - that's what controls aTHX_ expansion */
#if !PERL_VERSION_GE(5,22,0)
#  ifndef Perl_xs_boot_epilog
#    ifdef PERL_IMPLICIT_CONTEXT
#      define Perl_xs_boot_epilog(ctx, ax) XSRETURN_YES
#    else
#      define Perl_xs_boot_epilog(ax) XSRETURN_YES
#    endif
#  endif
#endif

/* XS_EXTERNAL - introduced in 5.16 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif

/* Utility macros */
#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(x) ((void)(x))
#endif

#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) ((void)(x))
#endif

/* DEFSV macros - DEFSV_set was added in 5.24.0 */
#ifndef DEFSV_set
#  define DEFSV_set(sv) (GvSV(PL_defgv) = (sv))
#endif

#ifndef SAVE_DEFSV
#  define SAVE_DEFSV SAVESPTR(GvSV(PL_defgv))
#endif

/* PL_sv_zero - introduced in 5.28 */
#if !PERL_VERSION_GE(5,28,0)
/* Pre-5.28: PL_sv_zero doesn't exist, use sv_2mortal(newSViv(0)) */
#  define PL_sv_zero (*funcutil_compat_get_sv_zero(aTHX))
static SV* funcutil_compat_get_sv_zero(pTHX) {
    static SV* sv_zero = NULL;
    if (!sv_zero) {
        sv_zero = newSViv(0);
        SvREADONLY_on(sv_zero);
    }
    return sv_zero;
}
#endif

/* GvCV_set - introduced in 5.22 */
#if !PERL_VERSION_GE(5,22,0)
#  ifndef GvCV_set
#    define GvCV_set(gv, cv) (GvCV(gv) = (cv))
#  endif
#endif

/* Perl_call_checker - introduced in 5.14 */
#if !PERL_VERSION_GE(5,14,0)
typedef OP * (*Perl_call_checker)(pTHX_ OP *, GV *, SV *);
#endif

/* pad_alloc - not exported until 5.15.1 (use 5.16 as safe boundary)
 * Fallback: return 0 (disables pad optimization) */
#if !PERL_VERSION_GE(5,16,0)
#  ifndef pad_alloc
#    define pad_alloc(optype, sv_type) 0
#  endif
#endif

/* op_convert_list - introduced in 5.22
 * Fallback: use Perl_convert which exists in older Perls */
#if !PERL_VERSION_GE(5,22,0)
#  ifndef op_convert_list
#    define op_convert_list(type, flags, op) Perl_convert(aTHX_ type, flags, op)
#  endif
#endif

#endif /* FUNCUTIL_COMPAT_H */
