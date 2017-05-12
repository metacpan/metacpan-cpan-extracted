#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "bcd.c"
#include "hazy-cosmic-jive-perl.c"

MODULE=Hazy::Cosmic::Jive PACKAGE=Hazy::Cosmic::Jive

PROTOTYPES: DISABLE

SV *
float_to_string(d)
	SV * d;
CODE:
	RETVAL = bcd_float_to_string (d);
OUTPUT:
	RETVAL

