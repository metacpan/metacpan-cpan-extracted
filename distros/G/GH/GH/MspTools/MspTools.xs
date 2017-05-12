#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <Msp/msp.h>
#include <MspTools/msp_tools.h>
#include <MspTools/msp_helpers.h>

typedef MSP* GH__Msp;

MODULE = GH::MspTools		PACKAGE = GH::MspTools		

PROTOTYPES: ENABLE

void
getMSPs(s1, s2)
	char *s1
	char *s2
	PPCODE:
	SV *rv = NULL;

	rv = getMSPs_helper(s1, s2);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}

void
MSPMismatches(pMsp, s1, s2)
	GH::Msp pMsp
	char *s1
	char *s2
	PPCODE:
	{
		SV *mismatches = NULL;
		mismatches = MSPMismatches_helper(pMsp, s1, s2);
		XPUSHs(sv_2mortal(mismatches));
	}

void
getMSPsBulk(s1, arrayRef)
	char *s1
	SV *arrayRef
	PPCODE:
	SV *rv = NULL;

	rv = getMSPsBulk_helper(s1, arrayRef);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}

void
findBestOverlap(s1, s2)
	char *s1
	char *s2
	PPCODE:
	SV *rv = NULL;

	rv = findBestOverlap_helper(s1, s2);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}


void
findBestInclusion(s1, s2)
	char *s1
	char *s2
	PPCODE:
	SV *rv = NULL;

	rv = findBestInclusion_helper(s1, s2);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}

void
tmpPlace(s1, s2)
	char *s1
	char *s2
	PPCODE:
	SV *rv = NULL;

	rv = tmpPlace_helper(s1, s2);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}


void
findBestInclusionBulk(s1, arrayRef)
	char *s1
	SV *arrayRef
	PPCODE:
	SV *rv = NULL;

	rv = findBestInclusionBulk_helper(s1, arrayRef);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}
