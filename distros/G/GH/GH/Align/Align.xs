#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Align/align_helpers.h"

MODULE = GH::Align		PACKAGE = GH::Align		

PROTOTYPES: ENABLE

void
globalMinDifferences(s1, s2)
	char *s1
	char *s2
	PPCODE:
	SV *rv = NULL;

	rv = globalMinDifferences_helper(s1, s2);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}

void
boundedGlobalMinDifferences(s1, s2, bound)
	char *s1
	char *s2
	int bound
	PPCODE:
	SV *rv = NULL;

	rv = boundedGlobalMinDifferences_helper(s1, s2, bound);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}


void
boundedHirschbergGlobalMinDiffs(s1, s2, bound)
	char *s1
	char *s2
	int bound
	PPCODE:
	SV *rv = NULL;

	rv = boundedHirschbergGlobalMinDiffs_helper(s1, s2, bound);
	if (rv) {
		XPUSHs(sv_2mortal(rv));
	}

