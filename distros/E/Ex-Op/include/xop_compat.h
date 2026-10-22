#ifndef XOP_COMPAT_H
#define XOP_COMPAT_H

#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

#if PERL_VERSION_GE(5,14,0)
#  define XOP_COMPAT_HAS_XOP 1
#else
#  define XOP_COMPAT_HAS_XOP 0

#  ifndef XOP_DEFINED_BY_COMPAT
#    define XOP_DEFINED_BY_COMPAT 1
typedef struct {
    const char *xop_name;
    const char *xop_desc;
} XOP;
#  endif

#  ifndef XopENTRY_set
#    define XopENTRY_set(xop, field, value) \
        XopENTRY_set_impl_##field(xop, value)
#    define XopENTRY_set_impl_xop_name(xop, value) do { (xop)->xop_name = (value); } while(0)
#    define XopENTRY_set_impl_xop_desc(xop, value) do { (xop)->xop_desc = (value); } while(0)
#    define XopENTRY_set_impl_xop_class(xop, value) do { } while(0)
#  endif

#  ifndef Perl_custom_op_register
#    define Perl_custom_op_register(...) xop_compat_register_custom_op(__VA_ARGS__)
#  endif

static void xop_compat_register_custom_op(pTHX_ Perl_ppaddr_t ppfunc, XOP *xop) {
    if (!PL_custom_op_names) {
        PL_custom_op_names = newHV();
    }
    if (!PL_custom_op_descs) {
        PL_custom_op_descs = newHV();
    }
    hv_store(PL_custom_op_names, (char*)&ppfunc, sizeof(ppfunc), newSVpv(xop->xop_name, 0), 0);
    hv_store(PL_custom_op_descs, (char*)&ppfunc, sizeof(ppfunc), newSVpv(xop->xop_desc, 0), 0);
}

#endif

#if !PERL_VERSION_GE(5,14,0)
#  ifndef cv_set_call_checker
#    define cv_set_call_checker(cv, checker, ckobj)
#  endif
#endif

#endif
