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

/* Perl_xs_boot_epilog - introduced in 5.21.6 (use 5.22 as safe boundary).
 *
 * Must be a variadic macro (not a fixed-arity macro and not a function):
 * the preprocessor identifies macro arguments by commas at the call site
 * BEFORE expanding aTHX_, so a 2-arg macro can't be called with
 * `Perl_xs_boot_epilog(aTHX_ ax)` — that's one preprocessor argument.
 * A function won't work either because the body is XSRETURN_YES, whose
 * `return` must exit the BOOT XSUB, not a helper frame. */
#if !PERL_VERSION_GE(5,22,0)
#  ifndef Perl_xs_boot_epilog
#    define Perl_xs_boot_epilog(...) XSRETURN_YES
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

/* op_convert_list - the 5.21.6 rename of core's convert()
 *
 * Perl_convert is NOT a usable fallback, for the same reason pad_alloc above
 * needs one: embed.fnc flags it `pR`, with no A, X or E, so it never entered
 * the exported symbol list. It is declared in proto.h, so it compiles; ELF
 * exports it regardless, so it links on Linux; Windows exports only what is
 * in perl5xx.def, so the DLL link fails there with
 * `undefined reference to _imp__Perl_convert`.
 *
 * Reimplementing all of convert() is not possible either: it ends in
 * fold_constants(op_integerize(op_std_init(o))) and all three are core
 * statics. It is also not necessary. The one call in this distribution is
 * op_convert_list(OP_LIST, OPf_STACKED, arg), and regen/opcodes declares
 *
 *     list    list    ck_null    m@    L
 *
 * so for OP_LIST every one of those steps is a no-op: ck_null is the identity
 * check, no `s` means op_std_init contextualizes nothing, no `t` means it
 * allocates no target, and no `f` means op_integerize and fold_constants both
 * decline. `m` (OA_MARK) is set, so the pushmark is kept rather than nulled,
 * and the only other branch there tests the second kid for OP_COREARGS, which
 * a call checker's argument never is.
 *
 * What is left is the wrap, built on newLISTOP, which is `Apda` - exported
 * everywhere - plus the sibling repair below, which core does through its own
 * static force_list(). The assert is the guard on that reasoning: it holds
 * for OP_LIST and was not checked for anything else. */
#if !PERL_VERSION_GE(5,22,0)
#  ifndef op_convert_list
static OP *fu_convert_list(pTHX_ I32 type, I32 flags, OP *o) {
    assert(type == OP_LIST);
    PERL_UNUSED_ARG(type);
    if (!o || o->op_type != OP_LIST) {
        OP *head = o, *tail = o;
        OP *rest = o ? OpSIBLING(o) : NULL;
        if (o) OpLASTSIB_set(o, NULL);
        o = newLISTOP(OP_LIST, 0, head, NULL);
        /* newLISTOP was handed one kid, so it set op_last to that kid. The
         * caller's argument is the head of a chain, and the rest of it has to
         * be re-attached and op_last moved to the real end, or the optree is
         * malformed: the kids are reachable through the sibling links while
         * op_last names the first of them. That crashes - verified, a SEGV on
         * clamp($x, $l, $h) - rather than misbehaving quietly. */
        if (rest) {
            OpMORESIB_set(tail, rest);
            while (OpSIBLING(tail)) tail = OpSIBLING(tail);
            OpLASTSIB_set(tail, o);
            cLISTOPx(o)->op_last = tail;
            o->op_flags |= OPf_KIDS;
        }
    }
    else {
        o->op_flags &= ~OPf_WANT;
    }
    o->op_flags |= flags;
    return o;
}
#    define op_convert_list(type, flags, op) fu_convert_list(aTHX_ (type), (flags), (op))
#  endif
#endif

#endif /* FUNCUTIL_COMPAT_H */
