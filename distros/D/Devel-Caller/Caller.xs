/* -*- C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Devel::Caller                PACKAGE = Devel::Caller

SV*
_context_cv(context)
SV* context;
  CODE:
    PERL_CONTEXT *cx = INT2PTR(PERL_CONTEXT *, SvIV(context));
    CV *cur_cv;

    if (CxTYPE(cx) != CXt_SUB)
        croak("cx_type is %d not CXt_SUB\n", CxTYPE(cx));

    cur_cv = cx->blk_sub.cv;
    if (!cur_cv)
        croak("Context has no CV!\n");

    RETVAL = (SV*) newRV_inc( (SV*) cur_cv );
  OUTPUT:
    RETVAL

SV*
_context_op(context)
SV* context;
  CODE:
    PERL_CONTEXT *cx = INT2PTR(PERL_CONTEXT*, SvIV(context));
    OP *op = cx->blk_oldcop->op_next;
    SV *rv = newSV(0);
    sv_setref_iv(rv, "B::OP", PTR2IV(op));
    RETVAL = rv;
  OUTPUT:
    RETVAL

