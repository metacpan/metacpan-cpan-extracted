#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/personality.h>

#include "const-c.inc"

MODULE = Linux::Personality		PACKAGE = Linux::Personality		

INCLUDE: const-xs.inc

int
personality(a)
                unsigned long int a
        OUTPUT:
                RETVAL

