#ifndef XSH_PEEP_H
#define XSH_PEEP_H 1

#include "caps.h" /* XSH_HAS_PERL(), XSH_THREADSAFE */
#include "util.h" /* XSH_ASSERT(), NOOP */

#ifdef XSH_THREADS_H
# error threads.h must be loaded at the very end
#endif

#ifndef XSH_HAS_RPEEP
# define XSH_HAS_RPEEP XSH_HAS_PERL(5, 13, 5)
#endif

#define PTABLE_USE_DEFAULT 1
#define PTABLE_NEED_DELETE 0

#include "ptable.h"

#define ptable_seen_store(T, K, V) ptable_default_store(aPTBL_ (T), (K), (V))
#define ptable_seen_clear(T)       ptable_default_clear(aPTBL_ (T))
#define ptable_seen_free(T)        ptable_default_free(aPTBL_ (T))

#define XSH_THREADS_PEEP_CONTEXT 1

typedef struct {
#if XSH_HAS_RPEEP
 peep_t  old_rpeep;
#else
 peep_t  old_peep;
#endif
 ptable *seen;
} xsh_peep_cxt_t;

static xsh_peep_cxt_t *xsh_peep_get_cxt(pTHX);

static void xsh_peep_rec(pTHX_ OP *o, ptable *seen);

#if XSH_HAS_RPEEP

static void xsh_rpeep(pTHX_ OP *o) {
 ptable         *seen;
 xsh_peep_cxt_t *cxt = xsh_peep_get_cxt(aTHX);

 cxt->old_rpeep(aTHX_ o);

 seen = cxt->seen;
 XSH_ASSERT(seen);

 ptable_seen_clear(seen);

 xsh_peep_rec(aTHX_ o, seen);

 ptable_seen_clear(seen);

 return;
}

#define xsh_peep_maybe_recurse(O, S) NOOP

#else  /*  XSH_HAS_RPEEP */

static void xsh_peep(pTHX_ OP *o) {
 ptable         *seen;
 xsh_peep_cxt_t *cxt = xsh_peep_get_cxt(aTHX);

 cxt->old_peep(aTHX_ o); /* Will call the rpeep */

 seen = cxt->seen;
 XSH_ASSERT(seen);

 ptable_seen_clear(seen);

 xsh_peep_rec(aTHX_ o, seen);

 ptable_seen_clear(seen);

 return;
}

static void xsh_peep_maybe_recurse(pTHX_ OP *o, ptable *seen) {
#define xsh_peep_maybe_recurse(O, S) xsh_peep_maybe_recurse(aTHX_ (O), (S))
 switch (o->op_type) {
  case OP_MAPWHILE:
  case OP_GREPWHILE:
  case OP_AND:
  case OP_OR:
  case OP_ANDASSIGN:
  case OP_ORASSIGN:
  case OP_COND_EXPR:
  case OP_RANGE:
#if XSH_HAS_PERL(5, 10, 0)
  case OP_ONCE:
  case OP_DOR:
  case OP_DORASSIGN:
#endif
   xsh_peep_rec(aTHX_ cLOGOPo->op_other, seen);
   break;
  case OP_ENTERLOOP:
  case OP_ENTERITER:
   xsh_peep_rec(aTHX_ cLOOPo->op_redoop, seen);
   xsh_peep_rec(aTHX_ cLOOPo->op_nextop, seen);
   xsh_peep_rec(aTHX_ cLOOPo->op_lastop, seen);
   break;
#if XSH_HAS_PERL(5, 9, 5)
  case OP_SUBST:
   xsh_peep_rec(aTHX_ cPMOPo->op_pmstashstartu.op_pmreplstart, seen);
   break;
#else
  case OP_QR:
  case OP_MATCH:
  case OP_SUBST:
   xsh_peep_rec(aTHX_ cPMOPo->op_pmreplstart, seen);
   break;
#endif
 }

 return;
}

#endif /* !XSH_HAS_RPEEP */

static int xsh_peep_seen(pTHX_ OP *o, ptable *seen) {
#define xsh_peep_seen(O, S) xsh_peep_seen(aTHX_ (O), (S))
#if XSH_HAS_RPEEP
 switch (o->op_type) {
  case OP_NEXTSTATE:
  case OP_DBSTATE:
  case OP_UNSTACK:
  case OP_STUB:
   break;
  default:
   return 0;
 }
#endif /* XSH_HAS_RPEEP */

 if (ptable_fetch(seen, o))
  return 1;

 ptable_seen_store(seen, o, o);

 return 0;
}

static void xsh_peep_local_setup(pTHX_ xsh_peep_cxt_t *cxt) {
#if XSH_HAS_RPEEP
 if (PL_rpeepp != xsh_rpeep) {
  cxt->old_rpeep = PL_rpeepp;
  PL_rpeepp      = xsh_rpeep;
 } else {
  cxt->old_rpeep = 0;
 }
#else
 if (PL_peepp != xsh_peep) {
  cxt->old_peep = PL_peepp;
  PL_peepp      = xsh_peep;
 } else {
  cxt->old_peep = 0;
 }
#endif

 cxt->seen = ptable_new(32);
}

static void xsh_peep_local_teardown(pTHX_ xsh_peep_cxt_t *cxt) {
 ptable_seen_free(cxt->seen);
 cxt->seen = NULL;

#if XSH_HAS_RPEEP
 if (cxt->old_rpeep) {
  PL_rpeepp      = cxt->old_rpeep;
  cxt->old_rpeep = 0;
 }
#else
 if (cxt->old_peep) {
  PL_peepp      = cxt->old_peep;
  cxt->old_peep = 0;
 }
#endif

 return;
}

static void xsh_peep_clone(pTHX_ const xsh_peep_cxt_t *old_cxt, xsh_peep_cxt_t *new_cxt) {
 new_cxt->seen = ptable_new(32);

 return;
}

#endif /* XSH_PEEP_H */
