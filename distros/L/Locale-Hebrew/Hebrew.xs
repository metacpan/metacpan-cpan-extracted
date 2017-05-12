/* $File: //member/autrijus/Locale-Hebrew/Hebrew.xs $ $Author: autrijus $
   $Revision: #2 $ $Change: 11166 $ $DateTime: 2004/09/17 21:16:27 $ */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

MODULE = Locale::Hebrew		PACKAGE = Locale::Hebrew		

SV *
_hebrewflip(s)
SV * s
CODE:
    int l;
    char *src, *dst;
    SV *r;

    r = newSVsv(s);
    src = SvPV(r, l);
    bidimain(src, l);
    RETVAL = r;
    OUTPUT:
    RETVAL
    
