#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Devel::PL_origargv    PACKAGE = Devel::PL_origargv

PROTOTYPES: DISABLE

int
_my_argc ()
CODE:
	RETVAL = PL_origargc;
OUTPUT:
	RETVAL

char *
_my_argv (x)
	int    x
CODE:
	RETVAL = PL_origargv[x - 1];
OUTPUT:
	RETVAL
