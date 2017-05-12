#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "editop.h"

typedef EditOp* GH__EditOp;

MODULE = GH::EditOp		PACKAGE = GH::EditOp		

PROTOTYPES: ENABLE

GH::EditOp
new(package)
	char *package
	CODE:
	RETVAL = newEditOp();
	OUTPUT:
	RETVAL

void
setType(pEditOp, type)
	GH::EditOp pEditOp
	int type
	CODE:
	pEditOp->type = type;

int
getType(pEditOp)
	GH::EditOp pEditOp
	CODE:
	RETVAL = pEditOp->type;
	OUTPUT:
	RETVAL

void
setCount(pEditOp, pos)
	GH::EditOp pEditOp
	int pos
	CODE:
	pEditOp->count = pos;

int
getCount(pEditOp)
	GH::EditOp pEditOp
	CODE:
	RETVAL = pEditOp->count;
	OUTPUT:
	RETVAL

void
dump(pEditOp)
	GH::EditOp pEditOp
	CODE:
	printf("addr: %d, ", pEditOp);
	printf(" type: %d, ", pEditOp->type);
	printf(" count: %d,", pEditOp->count);

void
DESTROY(pEditOp)
	GH::EditOp pEditOp
	CODE:
	free(pEditOp);

