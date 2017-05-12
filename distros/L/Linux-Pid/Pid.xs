#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*#include "ppport.h"*/

MODULE = Linux::Pid		PACKAGE = Linux::Pid

int
getpid()
    CODE:
        RETVAL = getpid();
    OUTPUT:
        RETVAL

int
getppid()
    CODE:
        RETVAL = getppid();
    OUTPUT:
        RETVAL
