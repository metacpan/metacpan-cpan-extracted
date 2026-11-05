#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Dropped    PACKAGE = Dropped

int
twice(x)
        int x
    CODE:
        # a comment xsubpp drops without a #line
#define DROPPED_TWO 2
        RETVAL = x * DROPPED_TWO;
        # and another
        RETVAL += 0;
    OUTPUT:
        RETVAL
