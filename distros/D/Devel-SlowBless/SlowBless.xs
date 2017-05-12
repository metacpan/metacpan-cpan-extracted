#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = Devel::SlowBless		PACKAGE = Devel::SlowBless		

int
sub_gen()
    CODE:
        RETVAL = PL_sub_generation;
    OUTPUT:
        RETVAL

int
amg_gen()
    CODE:
        RETVAL = PL_amagic_generation;
    OUTPUT:
        RETVAL

