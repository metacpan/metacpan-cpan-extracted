#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#include "ppport.h"

/*
 * http://www.nntp.perl.org/group/perl.perl5.porters/2014/11/msg222354.html
 *
 * Maybe it just shows that the macro is poorly named.  Or, rather,
 * IN_PERL_COMPILETIME means that we are currently in the middle of parsing
 * and building ops via toke.c/op.c.  We switch to 'run time' for
 * running any code, even BEGIN blocks.
 */

MODULE = Devel::Pragma                PACKAGE = Devel::Pragma

SV *
ccstash()
    PROTOTYPE:
    CODE:
        if (PL_in_eval && EVAL_INREQUIRE) { /* being required: return the stash name */
            RETVAL = newSVpv(HvNAME(PL_curstash), 0);
        } else { /* not being required: return undef */
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

void
xs_scope()
    PROTOTYPE:
    CODE:
        XSRETURN_UV(PTR2UV(GvHV(PL_hintgv)));
