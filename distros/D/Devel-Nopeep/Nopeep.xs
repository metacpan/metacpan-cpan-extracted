#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

void no_peep(pTHX_ OP *o) {
	return;
}

MODULE = Devel::Nopeep         PACKAGE = Devel::Nopeep

BOOT:
	PL_peepp = no_peep;
