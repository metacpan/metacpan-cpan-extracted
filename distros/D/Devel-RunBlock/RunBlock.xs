/* ----------------------------------------------------------------------------
 * RunBlock.xs
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2006 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id$
 * ------------------------------------------------------------------------- */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define DEBUG_MESSAGES 0

typedef struct run_info
{
  runops_proc_t old_runops;
  int prev_op_is_return;
  CV* cv_ret_array;
  CV* cv_ret_scalar;
  CV* cv_ret_void;
  CV* cv_ret_cur;
} RUN_INFO;
static RUN_INFO* run_info;

/* ----------------------------------------------------------------------------
 run_info_new.
 * ------------------------------------------------------------------------- */
static RUN_INFO*
run_info_new(void)
{
  RUN_INFO* run_info = malloc(sizeof(*run_info));
  int i;
  
  memset(run_info, 0, sizeof(*run_info));
  
  for( i=0; i<3; ++i ) /* array,scalar,void */
  {
    const char* nm = NULL;
    CV* cv_retops;
    switch( i )
    {
      case 0: nm = "Devel::RunBlock::__ret_array";  break;
      case 1: nm = "Devel::RunBlock::__ret_scalar"; break;
      case 2: nm = "Devel::RunBlock::__ret_void";   break;
    }
    cv_retops = get_cv(nm, 0);
    if( !cv_retops ) croak("no sub %s", nm);
    switch(i)
    {
      case 0: run_info->cv_ret_array  = cv_retops; break;
      case 1: run_info->cv_ret_scalar = cv_retops; break;
      case 2: run_info->cv_ret_void   = cv_retops; break;
    }
  }
  return run_info;
}

/* ----------------------------------------------------------------------------
 * my_runops(pTHX);
 * ------------------------------------------------------------------------- */
static int
my_runops(pTHX)
{
  OPCODE prev_opcode = OP_NULL;
  while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX))) {
    PERL_ASYNC_CHECK();
    prev_opcode = PL_op->op_type;
  }
  run_info->prev_op_is_return = prev_opcode==OP_RETURN;
  TAINT_NOT;
  return 0;
}

/* ----------------------------------------------------------------------------
 * my_trace_runops(pTHX);
 * ------------------------------------------------------------------------- */
#if DEBUG_MESSAGES
static int
my_trace_runops(pTHX)
{
  static int depth;
  ++depth;
  fprintf(stderr, "(my_trace_runopts:enter#%d)\n", depth);
  fprintf(stderr, "%*s:%*s> op:%p (%s) [cxix=%d] next=%p sib=%p\n",
    depth*2-2, "", cxstack_ix*2, "", 
    PL_op, OP_NAME(PL_op), cxstack_ix, PL_op->op_next, PL_op->op_sibling);
  while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX))) {
    PERL_ASYNC_CHECK();
    fprintf(stderr, "%*s:%*s> op:%p (%s) [cx=%d] next:%p sib=%p\n",
      depth*2-2, "", cxstack_ix*2, "", 
      PL_op, OP_NAME(PL_op), cxstack_ix, PL_op->op_next, PL_op->op_sibling);
  }
  fprintf(stderr, "(my_trace_runopts:leave#%d)\n", depth);
  --depth;
  TAINT_NOT;
  return 0;
}
#endif

/* ----------------------------------------------------------------------------
 * dopoptosub_at (pp_ctl.c).
 * ------------------------------------------------------------------------- */
STATIC I32
S_dopoptosub_at(pTHX_ const PERL_CONTEXT *cxstk, I32 startingblock)
{
  I32 i;
  for (i = startingblock; i >= 0; i--)
  {
    switch( CxTYPE(&cxstk[i]) )
    {
      default:
        continue;
      case CXt_EVAL:
      case CXt_SUB:
      case CXt_FORMAT:
        DEBUG_l( Perl_deb(aTHX_ "(Found sub #%ld)\n", (long)i));
        return i;
    }
  }
  return i;
}

/* ----------------------------------------------------------------------------
 * XS codes.
 * ------------------------------------------------------------------------- */

MODULE = Devel::RunBlock    PACKAGE = Devel::RunBlock    

int
_runblock(coderef)
    SV* coderef;
  CODE:
    {
      run_info->prev_op_is_return = 0;
      run_info->old_runops = PL_runops;
      PL_runops = &my_runops;
      call_sv(coderef, G_DISCARD);
      if( run_info->old_runops )
      {
        PL_runops = run_info->old_runops;
        run_info->old_runops = NULL;
      }
      RETVAL = run_info->prev_op_is_return;
    }
  OUTPUT:
    RETVAL

void
_long_wantarray(up)
    int up;
  PPCODE:
    {
      I32 cxix;
      for( cxix = cxstack_ix; up>=0; --up, --cxix )
      {
        cxix = S_dopoptosub_at(aTHX_ cxstack, cxix);
      }
      if (cxix < 0)
        XSRETURN_UNDEF;
      switch (cxstack[cxix].blk_gimme)
      {
      case G_ARRAY:  XSRETURN_YES;
      case G_SCALAR: XSRETURN_NO;
      default:       XSRETURN_UNDEF;
      }
    }

void
_long_return(up)
    int up;
  PPCODE:
    {
      I32 cxix;
      CV* cv_retops;
#if DEBUG_MESSAGES
      fprintf(stderr, "_long_return:enter(up=%d)\n", up)
      for( cxix=cxstack_ix; cxix>=0; --cxix )
      {
        switch( CxTYPE(&cxstack[cxix]) )
        {
        case CXt_NULL:   fprintf(stderr, "  #%d %s\n", cxix, "null"); break;
        case CXt_SUB:    fprintf(stderr, "  #%d %s\n", cxix, "sub"); break;
        case CXt_EVAL:   fprintf(stderr, "  #%d %s\n", cxix, "eval"); break;
        case CXt_LOOP:   fprintf(stderr, "  #%d %s\n", cxix, "loop"); break;
        case CXt_SUBST:  fprintf(stderr, "  #%d %s\n", cxix, "subst"); break;
        case CXt_BLOCK:  fprintf(stderr, "  #%d %s\n", cxix, "block"); break;
        case CXt_FORMAT: fprintf(stderr, "  #%d %s\n", cxix, "format"); break;
        default:         fprintf(stderr, "  #%d %d\n", cxix, CxTYPE(&cxstack[cxix])); break;
        }
      }
#endif
      cxix = cxstack_ix;
      for( ; up>1; --up )
      {
        const PERL_CONTEXT* cx;
        CV* cv;
#if DEBUG_MESSAGES
        fprintf(stderr, "_long_return: up = %d cx <= %d\n", up, cxix);
#endif
        cxix = S_dopoptosub_at(aTHX_ cxstack, cxix);
#if DEBUG_MESSAGES
        fprintf(stderr, "_long_return: up = %d cx => %d\n", up, cxix);
#endif
        if( cxix < 0 )
        {
          croak("_long_return run out callstack");
        }
        cx = &cxstack[cxix];
        if( 0 && CxTYPE(cx)==CXt_EVAL )
        {
          ++up;
          --cxix;
          continue;
        }
        cv = cx->blk_sub.cv;
#if DEBUG_MESSAGES
        fprintf(stderr, "_long_return: up = %d type=%d, cv => %p\n", up, CxTYPE(cx), cv);
#endif
        if( CxTYPE(cx)==CXt_SUB && CvXSUB(cv) )
        {
          croak("_long_return could not through xsub");
        }
        if( up>0 )
        {
          --cxix;
        }
      }
#if DEBUG_MESSAGES
      fprintf(stderr, "_long_return:rewrite ix(%d..%d)..\n", cxix, cxstack_ix);
      fprintf(stderr, "_long_return:rewrite sp(%d..%d/%d)..\n", cxstack[cxix].blk_oldretsp, cxstack[cxstack_ix].blk_oldretsp,PL_retstack_ix);
#endif
      switch( cxstack[cxix].blk_gimme )
      {
      case G_ARRAY:  cv_retops = run_info->cv_ret_array;  break;
      case G_SCALAR: cv_retops = run_info->cv_ret_scalar; break;
      case G_VOID:   cv_retops = run_info->cv_ret_void;   break;
      default: croak("unknown gimme value");
      }
      run_info->cv_ret_cur = cv_retops;
#if DEBUG_MESSAGES
      fprintf(stderr, "cv_retops = %p\n", cv_retops);
      {
        OP* op;
        CV* cv;
        cv = run_info->cv_ret_array;
        fprintf(stderr, "retops-array %p%s\n", cv, cv==cv_retops?" *":"");
        for( op = CvSTART(cv); op; op = op->op_next )
        {
          fprintf(stderr, "  %p:%s\n", op, OP_NAME(op));
        }
        cv = run_info->cv_ret_scalar;
        fprintf(stderr, "retops-scalar %p%s\n", cv, cv==cv_retops?" *":"");
        for( op = CvSTART(cv); op; op = op->op_next )
        {
          fprintf(stderr, "  %p:%s\n", op, OP_NAME(op));
        }
        cv = run_info->cv_ret_void;
        fprintf(stderr, "retops-void %p%s\n", cv, cv==cv_retops?" *":"");
        for( op = CvSTART(cv); op; op = op->op_next )
        {
          fprintf(stderr, "  %p:%s\n", op, OP_NAME(op));
        }
      }
#endif
      /* TODO: currently could not return values.. */
      cv_retops = run_info->cv_ret_void;
      for( ; cxix<cxstack_ix; ++cxix )
      {
        const PERL_CONTEXT* cx = &cxstack[cxix];
#if DEBUG_MESSAGES
        {
          OP* op1 = PL_retstack[cx->blk_oldretsp];
          OP* op2 = CvSTART(run_info->cv_ret_void);
          fprintf(stderr, "_long_return: rewrite ix %d ret[%d] %p:%s => %p:%s\n", cxix, cx->blk_oldretsp, op1, OP_NAME(op1), op2, OP_NAME(op2));
        }
#endif
        /* cx_u.cx_blk.blku_oldretsp */
        PL_retstack[cx->blk_oldretsp] = CvSTART(cv_retops);
        cv_retops = run_info->cv_ret_void;
      }
#if DEBUG_MESSAGES
        fprintf(stderr, "_long_return: rewrite cur, %p:%s => %p:%s.\n", PL_op, OP_NAME(PL_op), CvSTART(cv_retops), OP_NAME(CvSTART(cv_retops)));
#endif
      PL_op = CvSTART(cv_retops);
#if DEBUG_MESSAGES
      PL_runops = &my_trace_runops;
      fprintf(stderr, "_long_return:leave\n");
#endif
    }

BOOT:
  run_info = run_info_new();
#if 0
  fprintf(stderr, "set trace runopts\n");
  PL_runops = &my_trace_runops;
#endif

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
