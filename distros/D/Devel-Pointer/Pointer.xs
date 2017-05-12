#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Devel::Pointer		PACKAGE = Devel::Pointer		

IV
address_of(foo)
    SV* foo
    CODE:
        RETVAL = PTR2IV(foo);
    OUTPUT:
        RETVAL

SV*
deref(foo)
    IV foo
    ALIAS:
        deref = 1
        unsmash_sv = 2
    CODE:
        RETVAL = SvREFCNT_inc((SV*)(foo));
    OUTPUT:
        RETVAL

AV*
unsmash_av(foo)
    IV foo
    CODE:
        RETVAL = (AV*)SvREFCNT_inc((AV*)(foo));
    OUTPUT:
        RETVAL

HV*
unsmash_hv(foo)
    IV foo
    CODE:
        RETVAL = (HV*)SvREFCNT_inc((HV*)(foo));
    OUTPUT:
        RETVAL

CV*
unsmash_cv(foo)
    IV foo
    CODE:
        RETVAL = (CV*)SvREFCNT_inc((CV*)(foo));
    OUTPUT:
        RETVAL
