#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Sim4/sim4_helpers.h"

MODULE = GH::Sim4		PACKAGE = GH::Sim4

PROTOTYPES: ENABLE

void
_sim4(genomic, cDNA, args)
	char *genomic
	char *cDNA
	SV* args
	SV *rv = NULL;
	PPCODE:

	rv = sim4_helper(genomic, cDNA, args);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}

