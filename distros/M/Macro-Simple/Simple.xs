#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
 
MODULE = Macro::Simple               PACKAGE = Macro::Simple

bool truthy (...)
CODE:
	XSRETURN_YES;

bool falsey (...)
CODE:
	XSRETURN_NO;

void make_truthy (name)
	char *name
CODE:
	newXS(name, XS_Macro__Simple_truthy, __FILE__);

void make_falsey (name)
	char *name
CODE:
	newXS(name, XS_Macro__Simple_falsey, __FILE__);
