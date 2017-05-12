#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Msp/msp.h"

typedef MSP* GH__Msp;

MODULE = GH::Msp		PACKAGE = GH::Msp		

PROTOTYPES: ENABLE

GH::Msp
new(package)
	char *package
	CODE:
	RETVAL = newMSP();
	OUTPUT:
	RETVAL

void
setPos1(pMsp, pos)
	GH::Msp pMsp
	int pos
	CODE:
	pMsp->pos1 = pos;

int
getPos1(pMsp)
	GH::Msp pMsp
	CODE:
	RETVAL = pMsp->pos1;
	OUTPUT:
	RETVAL

void
setPos2(pMsp, pos)
	GH::Msp pMsp
	int pos
	CODE:
	pMsp->pos2 = pos;

int
getPos2(pMsp)
	GH::Msp pMsp
	CODE:
	RETVAL = pMsp->pos2;
	OUTPUT:
	RETVAL

void
setLen(pMsp, pos)
	GH::Msp pMsp
	int pos
	CODE:
	pMsp->len = pos;

int
getLen(pMsp)
	GH::Msp pMsp
	CODE:
	RETVAL = pMsp->len;
	OUTPUT:
	RETVAL

void
setScore(pMsp, pos)
	GH::Msp pMsp
	int pos
	CODE:
	pMsp->score = pos;

int
getScore(pMsp)
	GH::Msp pMsp
	CODE:
	RETVAL = pMsp->score;
	OUTPUT:
	RETVAL


void
dump(pMsp)
	GH::Msp pMsp
	CODE:
	printf("addr: %d, ", pMsp);
	printf(" pos1: %d, ", pMsp->pos1);
	printf(" pos2: %d,", pMsp->pos2);
	printf(" len: %d,", pMsp->len);
	printf(" score: %d\n", pMsp->score);

void
DESTROY(pMsp)
	GH::Msp pMsp
	CODE:
	free(pMsp);

