#include <stdlib.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sys::CpuLoadX		PACKAGE = Sys::CpuLoadX

int
foo()
	CODE:
		RETVAL = 42;
	OUTPUT:
		RETVAL

