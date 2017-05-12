#define PERL_CORE
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <string.h>

#include "hook_op_check_entersubforcv.h"

/* lifted from op.c */

#define LINKLIST(o) ((o)->op_next ? (o)->op_next : linklist((OP*)o))

#ifndef linklist
# define linklist(o) THX_linklist(aTHX_ o)
STATIC OP *THX_linklist(pTHX_ OP *o) {
  OP *first;
  if(o->op_next)
    return o->op_next;
  first = cUNOPo->op_first;
  if (first) {
    OP *kid;
    o->op_next = LINKLIST(first);
    kid = first;
    for (;;) {
      if (kid->op_sibling) {
   kid->op_next = LINKLIST(kid->op_sibling);
   kid = kid->op_sibling;
      } else {
   kid->op_next = o;
   break;
      }
    }
  } else {
    o->op_next = o;
  }
  return o->op_next;
}
#endif /* !linklist */

STATIC OP *lift_cb(pTHX_ OP *o, CV *cv, void *user_data) {
  dSP;
  SV *sv;
  SV **stack_save;
  OP *curop, *kid, *saved_next;
  I32 type = o->op_type;

  /* shamelessly lifted from fold_constants in op.c */

  stack_save = SP;

  curop = LINKLIST(o);

  if (0) { /* call as macro */
    OP *arg;
    OP *gv;
    /* this means the argument pushing ops are not executed, only the GV to
     * resolve the call is, and B::OP objects will be made of all the opcodes
     * */
    PUSHMARK(SP); /* push a mark for the arguments */

    /* push an arg for every sibling op */
    for ( arg = curop->op_sibling; arg->op_sibling; arg = arg->op_sibling ) {
      XPUSHs(sv_bless(newRV_inc(newSViv(PTR2IV(arg))), gv_stashpv("B::LISTOP", 0)));
    }

    /* find the last non null before the lifted entersub */
    for ( kid = curop; kid->op_next != o; kid = kid->op_next ) {
      if ( kid->op_type == OP_GV )
          gv = kid;
    }

    PL_op = gv; /* make the call to our sub without evaluating the arg ops */
  } else {
    PL_op = curop;
  }

  /* stop right after the call */
  saved_next = o->op_next;
  o->op_next = NULL;

  PUTBACK;
  SAVETMPS;
  CALLRUNOPS(aTHX);
  SPAGAIN;

  if (SP > stack_save) { /* sub returned something */
    sv = POPs;
    if (o->op_targ && sv == PAD_SV(o->op_targ)) /* grab pad temp? */
      pad_swipe(o->op_targ,  FALSE);
    else if (SvTEMP(sv)) {      /* grab mortal temp? */
      (void)SvREFCNT_inc(sv);
      SvTEMP_off(sv);
    }

    if (SvROK(sv) && sv_derived_from(sv, "B::OP")) {
      OP *new = INT2PTR(OP *,SvIV((SV *)SvRV(sv)));
      new->op_sibling = NULL;

      /* FIXME this is bullshit */
      if ( (PL_opargs[new->op_type] & OA_CLASS_MASK) != OA_SVOP ) {
        new->op_next = saved_next;
      } else {
        new->op_next = new;
      }

      return new;
    }

    if (type == OP_RV2GV)
      return newGVOP(OP_GV, 0, (GV*)sv);

	if (SvTYPE(sv) == SVt_NULL) {
		op_free(o);
		return newOP(OP_NULL, 0);
	}

    return newSVOP(OP_CONST, 0, sv);
  } else {
    /* this bit not lifted, handles the 'sub doesn't return stuff' case
       which fold_constants can ignore */
    op_free(o);
    return newOP(OP_NULL, 0);
  }
}

MODULE = Devel::BeginLift  PACKAGE = Devel::BeginLift

PROTOTYPES: DISABLE

UV
setup_for_cv (class, CV *cv)
  CODE:
    RETVAL = (UV)hook_op_check_entersubforcv (cv, lift_cb, NULL);
  OUTPUT:
    RETVAL

void
teardown_for_cv (class, UV id)
  CODE:
    hook_op_check_entersubforcv_remove ((hook_op_check_id)id);
