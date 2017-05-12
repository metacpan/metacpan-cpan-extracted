#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "StackBlech.h"

/*
 * CXt_NULL
 * CXt_SUB
 * CXt_BLOCK
 * CXt_EVAL
 * CXt_FORMAT      5.6.0 ...
 * CXt_LOOP        5.0.0 ... 5.10.x
 * CXt_LOOP_FOR    5.11.0 ... 
 * CXt_LOOP_LAZYIV 5.11.0 ...
 * CXt_LOOP_LAZYSV 5.11.0 ...
 * CXt_LOOP_PLAIN  5.11.0 ...
 * CXt_GIVEN       5.9.3 ...
 * CXt_WHEN        5.9.3 ...
 */

/*

LOOP:
    struct loop {
        BASEOP
        OP *	op_first;
        OP *	op_last;
        OP *	op_redoop;
        OP *	op_nextop;
        OP *	op_lastop;
    };

PERL_CONTEXT:
    struct context {
        union {
    	struct block	cx_blk;
    	struct subst	cx_subst;
        } cx_u;
    };
    typedef struct context PERL_CONTEXT;

CXt_SUBST
    * substitution context *
    struct subst {
        U8		sbu_type;	* what kind of context this is *
        U8		sbu_rflags;
        U16		sbu_rxtainted;	* matches struct block *
        I32		sbu_iters;
        I32		sbu_maxiters;
        I32		sbu_oldsave;
        char *	sbu_orig;
        SV *	sbu_dstr;
        SV *	sbu_targ;
        char *	sbu_s;
        char *	sbu_m;
        char *	sbu_strend;
        void *	sbu_rxres;
        REGEXP *	sbu_rx;
    };

CXt_SUB
    * subroutine context *
    struct block_sub {
        OP *	retop;	* op to execute on exit from sub *
    
        Above here is the same for sub, format and eval.
        CV *	cv;
    
        Above here is the same for sub and format.
        AV *	savearray;
        AV *	argarray;
        I32		olddepth;
        PAD		*oldcomppad;
    };

CXt_FORMAT
    * format context *
    struct block_format {
        OP *	retop;	* op to execute on exit from sub *
        * Above here is the same for sub, format and eval.  *
        CV *	cv;
        * Above here is the same for sub and format.  *
        GV *	gv;
        GV *	dfoutgv;
    };

CXt_EVAL
    * eval context *
    struct block_eval {
        OP *	retop;	* op to execute on exit from eval *
        * Above here is the same for sub, format and eval.  *
        SV *	old_namesv;
        OP *	old_eval_root;
        SV *	cur_text;
        CV *	cv;
        JMPENV *	cur_top_env; * value of PL_top_env when eval CX created *
    };

CXt_LOOP...
    * loop context *
    struct block_loop {
        I32		resetsp;
        LOOP *	my_op;	* My op, that contains redo, next and last ops.  *
        * (except for non_ithreads we need to modify next_op in pp_ctl.c, hence
    	why next_op is conditionally defined below.)  *
    #ifdef USE_ITHREADS
        PAD		*oldcomppad; * Also used for the GV, if targoffset is 0 *
        * This is also accesible via cx->blk_loop.my_op->op_targ *
        PADOFFSET	targoffset;
    #else
        OP *	next_op;
        SV **	itervar;
    #endif
        union {
    	struct { * valid if type is LOOP_FOR or LOOP_PLAIN (but {NULL,0})*
    	    AV * ary; * use the stack if this is NULL *
    	    IV ix;
    	} ary;
    	struct { * valid if type is LOOP_LAZYIV *
    	    IV cur;
    	    IV end;
    	} lazyiv;
    	struct { * valid if type if LOOP_LAZYSV *
    	    SV * cur;
    	    SV * end; * maxiumum value (or minimum in reverse) *
    	} lazysv;
        } state_u;
    };

struct block_givwhen {
	OP *leave_op;
};

struct block {
    U8		blku_type;	* what kind of context this is *
    U8		blku_gimme;	* is this block running in list context? *
    U16		blku_u16;	* used by block_sub and block_eval (so far) *
    I32		blku_oldsp;	* stack pointer to copy stuff down to *
    COP *	blku_oldcop;	* old curcop pointer *
    I32		blku_oldmarksp;	* mark stack index *
    I32		blku_oldscopesp;	* scope stack index *
    PMOP *	blku_oldpm;	* values of pattern match vars *

    union {
	struct block_sub	blku_sub;
	struct block_format	blku_format;
	struct block_eval	blku_eval;
	struct block_loop	blku_loop;
	struct block_givwhen	blku_givwhen;
    } blk_u;
};

 */

/*
 * Dump a context.
 */
void dsb_dumpFrame( const PERL_CONTEXT *const cx )
{
  switch(CxTYPE(cx)) {
  case CXt_NULL:
    PerlIO_printf(PerlIO_stdout(),"NULL\n");
    break;
  case CXt_SUB:
    if ( cx->blk_sub.cv == PL_DBcv ) {
      PerlIO_printf(PerlIO_stdout(),"DB::");
    }
    PerlIO_printf(PerlIO_stdout(),"SUB retop=0x%x cv=0x%0x\n",
		  (int)(cx->blk_sub.retop),
		  (int)(cx->blk_sub.cv));
    break;
  case CXt_EVAL:
    PerlIO_printf(PerlIO_stdout(),"EVAL old_eval_root=0x%x retop=0x%x\n", (int)((*cx).blk_eval.old_eval_root), (int)((*cx).blk_eval.retop));
    break;
  case CXt_SUBST:
    PerlIO_printf(PerlIO_stdout(),"SUBST\n");
    break;
  case CXt_BLOCK:
    PerlIO_printf(PerlIO_stdout(),"BLOCK\n");
    break;
#if PERL_VERSION >= 6
  case CXt_FORMAT:
    PerlIO_printf(PerlIO_stdout(),"FORMAT\n");
    break;
#endif

    /* v5.11.0 removed CXt_LOOP and replaced it with
     * CXt_LOOP_(FOR,LAZYIV,LAZYSV,PLAIN) */
#if PERL_VERSION < 11
  case CXt_LOOP:

#ifdef USE_ITHREADS
    PerlIO_printf(PerlIO_stdout(),"LOOP my_op=0x%x\n", (int)((*cx).blk_loop.my_op));
#else
    PerlIO_printf(PerlIO_stdout(),"LOOP my_op=0x%x next_op=0x%x\n", (int)((*cx).blk_loop.my_op), (int)((*cx).blk_loop.next_op));
#endif
    break;
#else /* PERL_VERSION >= 11 */
  case CXt_LOOP_FOR:
    PerlIO_printf(PerlIO_stdout(),"LOOP_FOR\n");
    break;
  case CXt_LOOP_LAZYIV:
    PerlIO_printf(PerlIO_stdout(),"LOOP_LAZYIV\n");
    break;
  case CXt_LOOP_LAZYSV:
    PerlIO_printf(PerlIO_stdout(),"LOOP_LAZYSV\n");
    break;
  case CXt_LOOP_PLAIN:
    PerlIO_printf(PerlIO_stdout(),"LOOP_PLAIN\n");
    break;
#endif

#if PERL_VERSION >= 9 && PERL_SUBVERSION >= 3
  case CXt_GIVEN:
    PerlIO_printf(PerlIO_stdout(),"GIVEN\n");
    break;
  case CXt_WHEN:
    PerlIO_printf(PerlIO_stdout(),"WHEN leave_op=0x%x\n", (int)((*cx).blk_givwhen.leave_op));
    break;
#endif
  }
}

/*
 * cop.h:
 * struct stackinfo {
 *     AV *		si_stack;	* stack for current runlevel *
 *     PERL_CONTEXT *	si_cxstack;	* context stack for runlevel *
 *     struct stackinfo *	si_prev;
 *     struct stackinfo *	si_next;
 *     I32			si_cxix;	* current context index *
 *     I32			si_cxmax;	* maximum allocated index *
 *     I32			si_type;	* type of runlevel *
 *     I32			si_markoff;	* offset where markstack begins for us.
 * 					 * currently used only with DEBUGGING,
 * 					 * but not #ifdef-ed for bincompat *
 * };
 * 
 * typedef struct stackinfo PERL_SI;
 */

/*
 * Dump all contexts in this runloop level.
 */
void dsb_dumpFrames( PERL_SI *si ) {
  PERL_CONTEXT *cx = si->si_cxstack;
  I32 i;
  
  for (i = si->si_cxix; i >= 0; --i ) {
    dsb_dumpFrame( &cx[i] );
  }
}

/*
 * Dump all levels of the interpreter's runloop stacks.
 *
 * This is the backend, reuseable implementation for the perl function C<dumpStacks()>.
 */
void dsb_dumpStacks()
{
  PERL_SI *si;
  
  for ( si = PL_curstackinfo; si; si = si->si_prev ) {
    PerlIO_printf(PerlIO_stdout(),"PERL_SI=0x%0x\n", (int)si);
    dsb_dumpFrames( si );
  }
}


MODULE = Devel::StackBlech  PACKAGE = Devel::StackBlech	PREFIX = StackBlech_

PROTOTYPES: DISABLE

void
StackBlech_dumpStack()
  CODE:
    dsb_dumpStacks();

void
StackBlech_dumpStacks()
  CODE:
    dsb_dumpStacks(); 

## Local Variables:
## mode: c
## mode: auto-fill
## End:
