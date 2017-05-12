#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = Lchown     PACKAGE = Lchown

PROTOTYPES: ENABLE

SV *
lchown(owner, group, ...)
        unsigned owner
        unsigned group
    PROTOTYPE: @
    PREINIT:
        int i;
        int ok;
        STRLEN len;
    CODE:
#ifdef HAS_LCHOWN
        ok = 0;
        for ( i=2 ; i<items ; i++ )
            if ( lchown((char *)SvPV(ST(i),len), owner, group) == 0 )
                ok++;
        ST(0) = sv_2mortal(newSViv(ok));
#else
        errno = ENOSYS;
        ST(0) = &PL_sv_undef;
#endif

