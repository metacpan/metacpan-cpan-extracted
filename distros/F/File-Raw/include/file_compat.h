/*
 * file_compat.h - Perl compatibility macros for file module
 * Supports Perl 5.14+ on Windows, Linux, macOS, BSD, and other POSIX systems
 */

#ifndef FILE_COMPAT_H
#define FILE_COMPAT_H

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

/* Op sibling macros - introduced in 5.22, needed for call checkers */
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

/* Windows-specific compatibility */
#ifdef _WIN32
#  ifndef X_OK
#    define X_OK 1  /* Execute permission check - not used on Windows */
#  endif
#  ifndef EXDEV
#    define EXDEV 18  /* Cross-device link error */
#  endif
#  ifndef S_ISLNK
#    define S_ISLNK(m) (0)  /* Windows doesn't have symlinks in traditional sense */
#  endif
#endif

/* snprintf compatibility for very old systems */
#ifndef snprintf
#  ifdef _MSC_VER
#    define snprintf _snprintf
#  endif
#endif

#endif /* FILE_COMPAT_H */
