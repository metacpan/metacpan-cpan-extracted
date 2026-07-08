/*
 * heap_compat.h - Perl compatibility macros for heap
 */

#ifndef HEAP_COMPAT_H
#define HEAP_COMPAT_H

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

/* newSVpvn_flags */
#ifndef newSVpvn_flags
#  define newSVpvn_flags(s,len,flags) newSVpvn(s,len)
#endif

/* PUSH_MULTICALL on pre-5.11 perls inlines cxinc() directly into the .so.
 * On FreeBSD (and other platforms) with a static libperl.a, cxinc is not
 * reachable via dlopen even when the perl binary was linked with -Wl,-E.
 * We define a portable call_sv fallback used by heap_sift_{up,down}_custom
 * on those perls; the MULTICALL fast path is used on 5.11+. */
#if PERL_VERSION_GE(5, 11, 0)
#  define HEAP_USE_MULTICALL 1
#else
#  define HEAP_USE_MULTICALL 0
#endif

/* Portable comparison call: set $a/$b then invoke the comparator via call_sv.
 * Used in the pre-5.11 fallback path inside heap_sift_{up,down}_custom. */
#define HEAP_CMP_CALL(h, sv_a, sv_b, result_var) \
    STMT_START { \
        int _heap_cnt; \
        GvSV((h)->gv_a) = (sv_a); \
        GvSV((h)->gv_b) = (sv_b); \
        ENTER; SAVETMPS; \
        PUSHMARK(SP); \
        PUTBACK; \
        _heap_cnt = call_sv((h)->comparator, G_SCALAR); \
        SPAGAIN; \
        (result_var) = _heap_cnt > 0 ? SvIV(POPs) : 0; \
        PUTBACK; FREETMPS; LEAVE; \
    } STMT_END

#endif /* HEAP_COMPAT_H */
