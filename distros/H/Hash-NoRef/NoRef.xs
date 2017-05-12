#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = Hash::NoRef		PACKAGE = Hash::NoRef


# usage: SvREFCNT(\$var) ;

I32
SvREFCNT(sv)
SV *	sv
 CODE:
	if ( SvROK(sv) ) {
	  sv = (SV*)SvRV(sv);
	  RETVAL = SvREFCNT(sv) ;
    }
    else { RETVAL = -1 ;}
 OUTPUT:
    RETVAL




# usage: SvREFCNT_inc(\$var) ;
#        PPCODE needed since otherwise sv_2mortal is inserted that will kill
#        the value.


SV *
SvREFCNT_inc(sv)
SV *	sv
 PPCODE:
	if ( SvROK(sv) ) {
	  sv = (SV*)SvRV(sv);
	  RETVAL = SvREFCNT_inc(sv) ;
      SvFLAGS(sv) |= SVf_BREAK ;
	  PUSHs(RETVAL);
    }


# usage: SvREFCNT_dec(\$var) ;
#        PPCODE needed since by default it is void

SV *
SvREFCNT_dec(sv)
SV *	sv
 PPCODE:
	if ( SvROK(sv) ) {
	  sv = (SV*)SvRV(sv);
	  SvREFCNT_dec(sv);
      SvFLAGS(sv) |= SVf_BREAK ;
	  PUSHs(sv);
    }

#
# From Scalar::Util:
#

void
weaken(sv)
	SV *sv
PROTOTYPE: $
CODE:
#ifdef SvWEAKREF
	sv_rvweaken(sv);
#else
	croak("weak references are not implemented in this release of perl");
#endif



void
isweak(sv)
	SV *sv
PROTOTYPE: $
CODE:
#ifdef SvWEAKREF
	ST(0) = boolSV(SvROK(sv) && SvWEAKREF(sv));
	XSRETURN(1);
#else
	croak("weak references are not implemented in this release of perl");
#endif



