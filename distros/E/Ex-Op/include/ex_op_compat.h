#ifndef EX_OP_COMPAT_H
#define EX_OP_COMPAT_H

#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

#if !PERL_VERSION_GE(5,14,0)
typedef OP * (*Perl_call_checker)(pTHX_ OP *, GV *, SV *);
#endif

#ifndef GvCV_set
#  define GvCV_set(gv, cv) (GvCV(gv) = (cv))
#endif

/* Call sites are found with call checkers from 5.14. Before that, and in a
 * build made with EX_OP_CHECK_WRAP=1 to test that path on a newer perl,
 * entersub's check is wrapped instead. */
#if !PERL_VERSION_GE(5,14,0) || defined(EO_FORCE_CHECK_WRAP)
#  define EO_CHECK_WRAP 1
#else
#  define EO_CHECK_WRAP 0
#endif

#if EO_CHECK_WRAP
#  if !PERL_VERSION_GE(5,14,0)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
#  endif
#  if PERL_VERSION_GE(5,16,0)
#    define eo_wrap_check(type, fn, nextp) wrap_op_checker((type), (fn), (nextp))
#  else
#    define eo_wrap_check(type, fn, nextp) \
         STMT_START { *(nextp) = PL_check[(type)]; PL_check[(type)] = (fn); } STMT_END
#  endif
#endif

#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o) (OpSIBLING(o) != NULL)
#endif

#ifndef HvNAMEUTF8
#  define HvNAMEUTF8(hv) 0
#endif

#ifndef hv_deletes
#  define hv_deletes(hv, key, flags) \
      hv_delete((hv), ("" key ""), (sizeof(key) - 1), (flags))
#endif

#ifndef isWORDCHAR
#  define isWORDCHAR(c) isALNUM(c)
#endif

/* Core's convert() was never exported (embed.fnc flags it `pR`), so it links
 * on ELF and fails on Windows. For OP_LIST every step after the wrap is a
 * no-op (ck_null, no `s`, `t` or `f` flags), which leaves newLISTOP and the
 * sibling repair that core does in its static force_list(). The same
 * reasoning and shim as Func-Util's funcutil_compat.h. */
#if !PERL_VERSION_GE(5,22,0) && !defined(op_convert_list)
PERL_STATIC_INLINE OP *
eo_convert_list(pTHX_ I32 type, I32 flags, OP *o)
{
    assert(type == OP_LIST);
    PERL_UNUSED_ARG(type);
    if (!o || o->op_type != OP_LIST) {
        OP *tail = o;
        OP *rest = o ? OpSIBLING(o) : NULL;
        if (o) OpLASTSIB_set(o, NULL);
        o = newLISTOP(OP_LIST, 0, o, NULL);
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
#  define op_convert_list(type, flags, op) eo_convert_list(aTHX_ (type), (flags), (op))
#endif

#endif
