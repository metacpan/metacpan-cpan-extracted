/*
 * multicall_compat.h - MULTICALL API compatibility for Perl 5.10+
 *
 * PUSH_MULTICALL was introduced in 5.11.0. For 5.10.x, we provide
 * a fallback using the older manual context setup.
 *
 * Usage:
 *   #include "multicall_compat.h"
 *
 *   // Then use dMULTICALL, PUSH_MULTICALL, MULTICALL, POP_MULTICALL as normal
 */

#ifndef MULTICALL_COMPAT_H
#define MULTICALL_COMPAT_H

/* Version checking macro */
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

/*
 * For Perl 5.10.x: PUSH_MULTICALL exists and works.
 * The MULTICALL macros were designed to efficiently call a CV multiple times
 * without the overhead of full call_sv() each time.
 *
 * The MULTICALL API was introduced in 5.9.3 and is available in 5.10+.
 * We only need to handle the cxinc declaration on pre-5.14.
 */

#if !PERL_VERSION_GE(5,14,0)
/* cxinc may not be declared in pre-5.14 headers - declare it */
#ifndef PERL_CORE
  I32 Perl_cxinc(pTHX);
#  define cxinc() Perl_cxinc(aTHX)
#endif
#endif /* !PERL_VERSION_GE(5,14,0) */

/*
 * For Perl 5.11.0 - 5.23.7: use standard MULTICALL API
 * This is the stable API before the cx_* functions were introduced.
 */

#if PERL_VERSION_GE(5,11,0) && !PERL_VERSION_GE(5,24,0)
/* Standard MULTICALL API works as-is */
#endif

/*
 * For Perl 5.24.0+: new context API (cx_pushblock, etc.)
 * The MULTICALL macros use these internally but the high-level API
 * (dMULTICALL, PUSH_MULTICALL, MULTICALL, POP_MULTICALL) remains the same.
 */

#if PERL_VERSION_GE(5,24,0)
/* Modern MULTICALL API works as-is */
#endif

/*
 * CX_CUR compatibility
 * CX_CUR was introduced in 5.23.8 to get current context.
 * Before that, use cxstack[cxstack_ix].
 */
#if !PERL_VERSION_GE(5,24,0)
#  ifndef CX_CUR
#    define CX_CUR() (&cxstack[cxstack_ix])
#  endif
#endif

/*
 * cx_pushblock/cx_popblock compatibility
 * These were introduced in 5.23.8 as part of the context API rewrite.
 * They're internal to MULTICALL macros, so we don't need to provide
 * fallbacks if we're using the high-level MULTICALL API.
 *
 * If code explicitly uses cx_pushblock/cx_popblock, it needs to be
 * rewritten to use MULTICALL or the even older PUSHSUB/POPSUB interface.
 */

/*
 * Additional context macros that may be needed
 */

/* PERL_CONTEXT type compatibility */
#ifndef PERL_CONTEXT
#  define PERL_CONTEXT struct context
#endif

/* CXp_MULTICALL flag - added in 5.9.3 */
#ifndef CXp_MULTICALL
#  ifdef CXf_MULTIARG
     /* Very old Perl - this shouldn't be reached with MIN_PERL_VERSION 5.10 */
#    define CXp_MULTICALL CXf_MULTIARG
#  else
#    define CXp_MULTICALL 0x20  /* Common value */
#  endif
#endif

/* CXt_SUB - context type for subroutine */
#ifndef CXt_SUB
#  define CXt_SUB 8
#endif

/*
 * GvCV_set compatibility (5.9.3+)
 */
#ifndef GvCV_set
#  define GvCV_set(gv, cv) (GvCV(gv) = (cv))
#endif

/*
 * SvREFCNT_inc_simple_NN compatibility
 */
#ifndef SvREFCNT_inc_simple_NN
#  define SvREFCNT_inc_simple_NN(sv) SvREFCNT_inc(sv)
#endif

#ifndef SvREFCNT_dec_NN
#  define SvREFCNT_dec_NN(sv) SvREFCNT_dec(sv)
#endif

/*
 * For code that MUST use manual context manipulation (e.g., the cx_* functions),
 * this macro can be checked to determine if the new API is available.
 */
#if PERL_VERSION_GE(5,24,0)
#  define MULTICALL_COMPAT_HAS_CX_API 1
#else
#  define MULTICALL_COMPAT_HAS_CX_API 0
#endif

#endif /* MULTICALL_COMPAT_H */
