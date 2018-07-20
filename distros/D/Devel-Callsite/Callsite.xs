#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_caller_cx

#include "ppport.h"

#if PERL_VERSION > 8
#  define MY_RETOP(c) PTR2UV((c)->blk_sub.retop)
#else
#  define MY_RETOP(c) ((UV)PL_retstack[(c)->blk_oldretsp - 1])
#endif

/* addr_to_op code provided by ikegami.
   See https://www.perlmonks.org/?node_id=1218517
 */
static const char * const opclassnames[] = {
  "B::NULL",
  "B::OP",
  "B::UNOP",
  "B::BINOP",
  "B::LOGOP",
  "B::LISTOP",
  "B::PMOP",
  "B::SVOP",
  "B::PADOP",
  "B::PVOP",
  "B::LOOP",
  "B::COP",
  "B::METHOP",
  "B::UNOP_AUX"
};
MODULE = Devel::Callsite	PACKAGE = Devel::Callsite

PROTOTYPES: DISABLE


SV *
addr_to_op(IV o_addr)
  CODE:
     const OP *o = INT2PTR(OP*, o_addr);
     RETVAL = newSV(0);
#if PERL_VERSION < 26
     sv_setiv(newSVrv(RETVAL, "B::OP"), o_addr);
#else
     sv_setiv(newSVrv(RETVAL, opclassnames[op_class(o)]), o_addr);
#endif
  OUTPUT:
     RETVAL


SV *
callsite(level = 0)
        I32 level
    PREINIT:
	const PERL_CONTEXT *cx, *dbcx;
        int rv = 1;
    PPCODE:
        cx = caller_cx(level, &dbcx);
        if (!cx) XSRETURN_EMPTY;

        mXPUSHu(MY_RETOP(cx));
        if (GIMME == G_ARRAY && CopSTASH_eq(PL_curcop, PL_debstash)) {
            rv = 2;
            mXPUSHu(MY_RETOP(dbcx));
        }
        XSRETURN(rv);

UV
context()
    CODE:
	RETVAL = PTR2UV(PERL_GET_CONTEXT);
    OUTPUT:
	RETVAL
