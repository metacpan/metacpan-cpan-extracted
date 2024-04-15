#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


SV * get_refcnt(SV * s) {
     return newSVuv(SvREFCNT(s));
}


MODULE = Math::Int113  PACKAGE = Math::Int113

PROTOTYPES: DISABLE


SV *
get_refcnt (s)
	SV *	s

