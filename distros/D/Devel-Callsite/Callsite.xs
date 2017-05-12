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

MODULE = Devel::Callsite	PACKAGE = Devel::Callsite

PROTOTYPES: DISABLE

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
