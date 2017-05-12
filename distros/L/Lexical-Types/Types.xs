/* This file is part of the Lexical-Types Perl module.
 * See http://search.cpan.org/dist/Lexical-Types/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* --- XS helpers ---------------------------------------------------------- */

#define XSH_PACKAGE "Lexical::Types"

#include "xsh/caps.h"
#include "xsh/util.h"
#include "xsh/mem.h"
#include "xsh/ops.h"
#include "xsh/peep.h"

/* ... Lexical hints ....................................................... */

#define XSH_HINTS_TYPE_SV 1

#include "xsh/hints.h"

#define lt_hint() xsh_hints_detag(xsh_hints_fetch())

/* ... Thread-local storage ................................................ */

typedef struct {
 SV *default_meth;
} xsh_user_cxt_t;

#define XSH_THREADS_COMPILE_TIME_PROTECTION 1
#define XSH_THREADS_USER_CLONE_NEEDS_DUP    1

#if XSH_THREADSAFE

static void xsh_user_clone(pTHX_ const xsh_user_cxt_t *old_cxt, xsh_user_cxt_t *new_cxt, CLONE_PARAMS *params) {
 new_cxt->default_meth = xsh_dup_inc(old_cxt->default_meth, params);

 return;
}

#endif /* XSH_THREADSAFE */

#include "xsh/threads.h"

/* ... op => info map ...................................................... */

#define PTABLE_NAME             ptable_map
#define PTABLE_VAL_FREE(V)      XSH_SHARED_FREE((V), 0, char)
#define PTABLE_VAL_NEED_CONTEXT 0
#define PTABLE_NEED_DELETE      1
#define PTABLE_NEED_WALK        0

#include "xsh/ptable.h"

#define ptable_map_store(T, K, V) ptable_map_store(aPMS_ (T), (K), (V))
#define ptable_map_delete(T, K)   ptable_map_delete(aPMS_ (T), (K))
#define ptable_map_free(T)        ptable_map_free(aPMS_ (T))

#ifdef USE_ITHREADS

static perl_mutex lt_op_map_mutex;

#endif /* USE_ITHREADS */

static ptable *lt_op_padxv_map = NULL;

typedef struct {
 OP *(*old_pp)(pTHX);
#ifdef MULTIPLICITY
 STRLEN buf_size, orig_pkg_len, type_pkg_len, type_meth_len;
 char *buf;
#else /* MULTIPLICITY */
 SV *orig_pkg;
 SV *type_pkg;
 SV *type_meth;
#endif /* !MULTIPLICITY */
} lt_op_padxv_info;

static void lt_op_padxv_info_call(pTHX_ const lt_op_padxv_info *oi, SV *sv) {
#define lt_op_padxv_info_call(O, S) lt_op_padxv_info_call(aTHX_ (O), (S))
 SV *orig_pkg, *type_pkg, *type_meth;
 int items;
 dSP;

 ENTER;
 SAVETMPS;

#ifdef MULTIPLICITY
 {
  STRLEN op_len = oi->orig_pkg_len, tp_len = oi->type_pkg_len;
  char *buf = oi->buf;
  orig_pkg  = sv_2mortal(newSVpvn(buf, op_len));
  SvREADONLY_on(orig_pkg);
  buf      += op_len;
  type_pkg  = sv_2mortal(newSVpvn(buf, tp_len));
  SvREADONLY_on(type_pkg);
  buf      += tp_len;
  type_meth = sv_2mortal(newSVpvn(buf, oi->type_meth_len));
  SvREADONLY_on(type_meth);
 }
#else /* MULTIPLICITY */
 orig_pkg  = oi->orig_pkg;
 type_pkg  = oi->type_pkg;
 type_meth = oi->type_meth;
#endif /* !MULTIPLICITY */

 PUSHMARK(SP);
 EXTEND(SP, 3);
 PUSHs(type_pkg);
 PUSHs(sv);
 PUSHs(orig_pkg);
 PUTBACK;

 items = call_sv(type_meth, G_ARRAY | G_METHOD);

 SPAGAIN;
 switch (items) {
  case 0:
   break;
  case 1:
   sv_setsv(sv, POPs);
   break;
  default:
   croak("Typed scalar initializer method should return zero or one scalar, but got %d", items);
 }
 PUTBACK;

 FREETMPS;
 LEAVE;

 return;
}

static void lt_padxv_map_store(pTHX_ const OP *o, SV *orig_pkg, SV *type_pkg, SV *type_meth, OP *(*old_pp)(pTHX)) {
#define lt_padxv_map_store(O, OP, TP, TM, PP) lt_padxv_map_store(aTHX_ (O), (OP), (TP), (TM), (PP))
 lt_op_padxv_info *oi;

 XSH_LOCK(&lt_op_map_mutex);

 if (!(oi = ptable_fetch(lt_op_padxv_map, o))) {
  XSH_SHARED_ALLOC(oi, 1, lt_op_padxv_info);
  ptable_map_store(lt_op_padxv_map, o, oi);
#ifdef MULTIPLICITY
  oi->buf      = NULL;
  oi->buf_size = 0;
#else /* MULTIPLICITY */
 } else {
  SvREFCNT_dec(oi->orig_pkg);
  SvREFCNT_dec(oi->type_pkg);
  SvREFCNT_dec(oi->type_meth);
#endif /* !MULTIPLICITY */
 }

#ifdef MULTIPLICITY
 {
  STRLEN op_len       = SvCUR(orig_pkg);
  STRLEN tp_len       = SvCUR(type_pkg);
  STRLEN tm_len       = SvCUR(type_meth);
  STRLEN new_buf_size = op_len + tp_len + tm_len;
  char *buf;
  if (new_buf_size > oi->buf_size) {
   XSH_SHARED_REALLOC(oi->buf, oi->buf_size, new_buf_size, char);
   oi->buf_size = new_buf_size;
  }
  buf  = oi->buf;
  Copy(SvPVX(orig_pkg),  buf, op_len, char);
  buf += op_len;
  Copy(SvPVX(type_pkg),  buf, tp_len, char);
  buf += tp_len;
  Copy(SvPVX(type_meth), buf, tm_len, char);
  oi->orig_pkg_len  = op_len;
  oi->type_pkg_len  = tp_len;
  oi->type_meth_len = tm_len;
  SvREFCNT_dec(orig_pkg);
  SvREFCNT_dec(type_pkg);
  SvREFCNT_dec(type_meth);
 }
#else /* MULTIPLICITY */
 oi->orig_pkg  = orig_pkg;
 oi->type_pkg  = type_pkg;
 oi->type_meth = type_meth;
#endif /* !MULTIPLICITY */

 oi->old_pp = old_pp;

 XSH_UNLOCK(&lt_op_map_mutex);
}

static const lt_op_padxv_info *lt_padxv_map_fetch(const OP *o, lt_op_padxv_info *oi) {
 const lt_op_padxv_info *val;

 XSH_LOCK(&lt_op_map_mutex);

 val = ptable_fetch(lt_op_padxv_map, o);
 if (val) {
  *oi = *val;
  val = oi;
 }

 XSH_UNLOCK(&lt_op_map_mutex);

 return val;
}

#if XSH_HAS_PERL(5, 17, 6)

static ptable *lt_op_padrange_map = NULL;

typedef struct {
 OP *(*old_pp)(pTHX);
 const OP *padxv_start;
} lt_op_padrange_info;

static void lt_padrange_map_store(pTHX_ const OP *o, const OP *s, OP *(*old_pp)(pTHX)) {
#define lt_padrange_map_store(O, S, PP) lt_padrange_map_store(aTHX_ (O), (S), (PP))
 lt_op_padrange_info *oi;

 XSH_LOCK(&lt_op_map_mutex);

 if (!(oi = ptable_fetch(lt_op_padrange_map, o))) {
  XSH_SHARED_ALLOC(oi, 1, lt_op_padrange_info);
  ptable_map_store(lt_op_padrange_map, o, oi);
 }

 oi->old_pp      = old_pp;
 oi->padxv_start = s;

 XSH_UNLOCK(&lt_op_map_mutex);
}

static const lt_op_padrange_info *lt_padrange_map_fetch(const OP *o, lt_op_padrange_info *oi) {
 const lt_op_padrange_info *val;

 XSH_LOCK(&lt_op_map_mutex);

 val = ptable_fetch(lt_op_padrange_map, o);
 if (val) {
  *oi = *val;
  val = oi;
 }

 XSH_UNLOCK(&lt_op_map_mutex);

 return val;
}

#endif

static void lt_map_delete(pTHX_ const OP *o) {
#define lt_map_delete(O) lt_map_delete(aTHX_ (O))
 XSH_LOCK(&lt_op_map_mutex);

 ptable_map_delete(lt_op_padxv_map,    o);
#if XSH_HAS_PERL(5, 17, 6)
 ptable_map_delete(lt_op_padrange_map, o);
#endif

 XSH_UNLOCK(&lt_op_map_mutex);
}

/* --- Compatibility wrappers ---------------------------------------------- */

#if XSH_HAS_PERL(5, 10, 0) || defined(PL_parser)
# ifndef PL_in_my_stash
#  define PL_in_my_stash PL_parser->in_my_stash
# endif
#else
# ifndef PL_in_my_stash
#  define PL_in_my_stash PL_Iin_my_stash
# endif
#endif

#ifndef HvNAME_get
# define HvNAME_get(H) HvNAME(H)
#endif

#ifndef HvNAMELEN_get
# define HvNAMELEN_get(H) strlen(HvNAME_get(H))
#endif

#ifndef SvREFCNT_inc_simple_void_NN
# define SvREFCNT_inc_simple_void_NN(S) ((void) SvREFCNT_inc(S))
#endif

/* --- PP functions -------------------------------------------------------- */

/* ... pp_padsv ............................................................ */

static OP *lt_pp_padsv(pTHX) {
 lt_op_padxv_info oi;

 if (lt_padxv_map_fetch(PL_op, &oi)) {
  dTARGET;
  lt_op_padxv_info_call(&oi, TARG);
  return oi.old_pp(aTHX);
 }

 return PL_op->op_ppaddr(aTHX);
}

/* ... pp_padrange (on perl 5.17.6 and above) .............................. */

#if XSH_HAS_PERL(5, 17, 6)

static OP *lt_pp_padrange(pTHX) {
 lt_op_padrange_info roi;

 if (lt_padrange_map_fetch(PL_op, &roi)) {
  PADOFFSET i, base, count;
  const OP *p;

  base  = PL_op->op_targ;
  count = PL_op->op_private & OPpPADRANGE_COUNTMASK;

  for (i = 0, p = roi.padxv_start; i < count && p; ++i, p = p->op_next) {
   lt_op_padxv_info oi;
   while (p->op_type == OP_NULL)
    p = p->op_next;
   if (p->op_type == OP_PADSV && lt_padxv_map_fetch(p, &oi))
    lt_op_padxv_info_call(&oi, PAD_SV(base + i));
  }

  return roi.old_pp(aTHX);
 }

 return PL_op->op_ppaddr(aTHX);
}

#endif

/* --- Check functions ----------------------------------------------------- */

/* ... ck_pad{any,sv} ...................................................... */

/* Sadly, the padsv OPs we are interested in don't trigger the padsv check
 * function, but are instead manually mutated from a padany. So we store
 * the op entry in the op map in the padany check function, and we set their
 * op_ppaddr member in our peephole optimizer replacement below. */

static OP *(*lt_old_ck_padany)(pTHX_ OP *) = 0;

static OP *lt_ck_padany(pTHX_ OP *o) {
 HV *stash;
 SV *code;

 o = lt_old_ck_padany(aTHX_ o);

 stash = PL_in_my_stash;
 if (stash && (code = lt_hint())) {
  dXSH_CXT;
  SV *orig_pkg  = newSVpvn(HvNAME_get(stash), HvNAMELEN_get(stash));
  SV *orig_meth = XSH_CXT.default_meth; /* Guarded by lt_hint() */
  SV *type_pkg  = NULL;
  SV *type_meth = NULL;
  int items;

  dSP;

  SvREADONLY_on(orig_pkg);

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(orig_pkg);
  PUSHs(orig_meth);
  PUTBACK;

  items = call_sv(code, G_ARRAY);

  SPAGAIN;
  if (items > 2)
   croak(XSH_PACKAGE " mangler should return zero, one or two scalars, but got %d", items);
  if (items == 0) {
   SvREFCNT_dec(orig_pkg);
   FREETMPS;
   LEAVE;
   goto skip;
  } else {
   SV *rsv;
   if (items > 1) {
    rsv = POPs;
    if (SvOK(rsv)) {
     type_meth = newSVsv(rsv);
     SvREADONLY_on(type_meth);
    }
   }
   rsv = POPs;
   if (SvOK(rsv)) {
    type_pkg = newSVsv(rsv);
    SvREADONLY_on(type_pkg);
   }
  }
  PUTBACK;

  FREETMPS;
  LEAVE;

  if (!type_pkg) {
   type_pkg = orig_pkg;
   SvREFCNT_inc_simple_void_NN(orig_pkg);
  }

  if (!type_meth) {
   type_meth = orig_meth;
   SvREFCNT_inc_simple_void_NN(orig_meth);
  }

  lt_padxv_map_store(o, orig_pkg, type_pkg, type_meth, o->op_ppaddr);
 } else {
skip:
  lt_map_delete(o);
 }

 return o;
}

static OP *(*lt_old_ck_padsv)(pTHX_ OP *) = 0;

static OP *lt_ck_padsv(pTHX_ OP *o) {
 lt_map_delete(o);

 return lt_old_ck_padsv(aTHX_ o);
}

/* --- Our peephole optimizer ---------------------------------------------- */

#if XSH_HAS_PERL(5, 17, 6)

static int lt_maybe_padrange_setup(pTHX_ OP *o, const OP *start) {
#define lt_maybe_padrange_setup(O, S) lt_maybe_padrange_setup(aTHX_ (O), (S))
 PADOFFSET i, count;
 const OP *p;

 count = o->op_private & OPpPADRANGE_COUNTMASK;

 for (i = 0, p = start; i < count && p; ++i, p = p->op_next) {
  if (p->op_type == OP_PADSV) {
   /* In a padrange sequence, either all lexicals are typed, or none are.
    * Thus we can stop at the first padsv op. However, note that these
    * lexicals can need to call different methods in different packages. */
   XSH_LOCK(&lt_op_map_mutex);
   if (ptable_fetch(lt_op_padxv_map, p)) {
    XSH_UNLOCK(&lt_op_map_mutex);
    lt_padrange_map_store(o, start, o->op_ppaddr);
    o->op_ppaddr = lt_pp_padrange;
   } else {
    XSH_UNLOCK(&lt_op_map_mutex);
   }
   return 1;
  }
 }

 return 0;
}

#endif

static void xsh_peep_rec(pTHX_ OP *o, ptable *seen) {
 for (; o; o = o->op_next) {
  if (xsh_peep_seen(o, seen))
   break;

  switch (o->op_type) {
   case OP_PADSV:
    if (o->op_ppaddr != lt_pp_padsv && o->op_private & OPpLVAL_INTRO) {
     lt_op_padxv_info *oi;
     XSH_LOCK(&lt_op_map_mutex);
     oi = ptable_fetch(lt_op_padxv_map, o);
     if (oi) {
      oi->old_pp   = o->op_ppaddr;
      o->op_ppaddr = lt_pp_padsv;
     }
     XSH_UNLOCK(&lt_op_map_mutex);
    }
    break;
#if XSH_HAS_PERL(5, 17, 6)
   case OP_PADRANGE:
    /* We deal with special padrange ops later, in the aassign op they belong
     * to. */
    if (o->op_ppaddr != lt_pp_padrange && o->op_private & OPpLVAL_INTRO
                                       && !(o->op_flags & OPf_SPECIAL)) {
     /* A padrange op is guaranteed to have previously been a pushmark.
      * Moreover, for non-special padrange ops (i.e. that aren't for
      * my (...) = @_), the first original padxv is its sibling or nephew.
      */
     OP *kid = OpSIBLING(o);
     if (kid->op_type == OP_NULL && kid->op_flags & OPf_KIDS) {
      kid = kUNOP->op_first;
      if (kid->op_type == OP_NULL)
       kid = OpSIBLING(kid);
     }
     lt_maybe_padrange_setup(o, kid);
    }
    break;
   case OP_AASSIGN: {
    OP *op;
    if (cBINOPo->op_first && cBINOPo->op_first->op_flags & OPf_KIDS
                          && (op = cUNOPx(cBINOPo->op_first)->op_first)
                          && op->op_type == OP_PADRANGE
                          && op->op_ppaddr != lt_pp_padrange
                          && op->op_private & OPpLVAL_INTRO
                          && op->op_flags & OPf_SPECIAL) {
     const OP *start = cUNOPx(cBINOPo->op_last)->op_first;
     if (start->op_type == OP_PUSHMARK)
      start = OpSIBLING(start);
     lt_maybe_padrange_setup(op, start);
    }
    break;
   }
#endif
   default:
    xsh_peep_maybe_recurse(o, seen);
    break;
  }
 }
}

/* --- Module setup/teardown ----------------------------------------------- */

static void xsh_user_global_setup(pTHX) {
 lt_op_padxv_map    = ptable_new(32);
#if XSH_HAS_PERL(5, 17, 6)
 lt_op_padrange_map = ptable_new(32);
#endif

#ifdef USE_ITHREADS
 MUTEX_INIT(&lt_op_map_mutex);
#endif

 xsh_ck_replace(OP_PADANY, lt_ck_padany, &lt_old_ck_padany);
 xsh_ck_replace(OP_PADSV,  lt_ck_padsv,  &lt_old_ck_padsv);

 return;
}

static void xsh_user_local_setup(pTHX_ xsh_user_cxt_t *cxt) {
 HV *stash;

 stash = gv_stashpvn(XSH_PACKAGE, XSH_PACKAGE_LEN, 1);
 newCONSTSUB(stash, "LT_THREADSAFE", newSVuv(XSH_THREADSAFE));
 newCONSTSUB(stash, "LT_FORKSAFE",   newSVuv(XSH_FORKSAFE));

 cxt->default_meth = newSVpvn("TYPEDSCALAR", 11);
 SvREADONLY_on(cxt->default_meth);

 return;
}

static void xsh_user_local_teardown(pTHX_ xsh_user_cxt_t *cxt) {
 SvREFCNT_dec(cxt->default_meth);
 cxt->default_meth = NULL;

 return;
}

static void xsh_user_global_teardown(pTHX) {
 xsh_ck_restore(OP_PADANY, &lt_old_ck_padany);
 xsh_ck_restore(OP_PADSV,  &lt_old_ck_padsv);

 ptable_map_free(lt_op_padxv_map);
 lt_op_padxv_map    = NULL;

#if XSH_HAS_PERL(5, 17, 6)
 ptable_map_free(lt_op_padrange_map);
 lt_op_padrange_map = NULL;
#endif

#ifdef USE_ITHREADS
 MUTEX_DESTROY(&lt_op_map_mutex);
#endif

 return;
}

/* --- XS ------------------------------------------------------------------ */

MODULE = Lexical::Types      PACKAGE = Lexical::Types

PROTOTYPES: ENABLE

BOOT:
{
 xsh_setup();
}

#if XSH_THREADSAFE

void
CLONE(...)
PROTOTYPE: DISABLE
PPCODE:
 xsh_clone();
 XSRETURN(0);

#endif

SV *
_tag(SV *code)
PROTOTYPE: $
CODE:
 if (!SvOK(code))
  code = NULL;
 else if (SvROK(code))
  code = SvRV(code);
 RETVAL = xsh_hints_tag(code);
OUTPUT:
 RETVAL
