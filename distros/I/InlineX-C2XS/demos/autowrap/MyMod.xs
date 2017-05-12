#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"
double erf(double);
MODULE = MyMod	PACKAGE = MyMod

PROTOTYPES: DISABLE


double
erf (arg1)
	double	arg1

