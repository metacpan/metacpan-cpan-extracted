/*
 *	OpProf.xs
 *
 *	Copyright (c) 1997 Malcolm Beattie
 *
 *	You may distribute under the terms of either the GNU General Public
 *	License or the Artistic License, as specified in the README file.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef PERL_OBJECT
#define CALLOP this->*PL_op
#else
#define CALLOP *PL_op
#endif

static int profiling = 0;
static unsigned long *op_count;

static int runops_opprof(void)
{
    dTHR;

    do {
	if (profiling)
	    op_count[PL_op->op_type]++;
    } while (PL_op = (CALLOP->op_ppaddr)(ARGS));
    TAINT_NOT;
    return 0;
}

MODULE = Devel::OpProf		PACKAGE = Devel::OpProf

PROTOTYPES: ENABLE

void
profile(flag)
	int	flag
    PPCODE:
	profiling = flag;

void
op_count()
    PPCODE:
	int i;
	EXTEND(sp, PL_maxo);
	for (i = 0; i < PL_maxo; i++)
	    PUSHs(sv_2mortal(newSViv(op_count[i])));
	
void
zero_stats()
    PPCODE:
	Zero(op_count, PL_maxo, unsigned long);

BOOT:
    Newz(0, op_count, PL_maxo, unsigned long);
    PL_runops = runops_opprof;
