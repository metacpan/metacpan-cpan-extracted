#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "libguile.h"
#include <guile/gh.h>
#include "guile_wrap.h"

MODULE = Guile		PACKAGE = Guile::SCM
PROTOTYPES: DISABLE

SCM
new (pkg, ...)
   SV *pkg
CODE:
 { 
   switch(items) {
   case 1:
     // set undefined SCM
     RETVAL = SCM_UNDEFINED;
     break;
   case 2:
     RETVAL = newSCMsv(ST(1), NULL);
     break;
   case 3:
     RETVAL = newSCMsv(ST(2), SvPV_nolen(ST(1)));
     break;
   default:
     croak("%s::new : too many arguments : 1 or 2 expected.", SvPV_nolen(pkg));
   }
 }
OUTPUT:
   RETVAL


SV * 
stringify (self, ...)
   SCM self
CODE:
   RETVAL = newSVscm(self);
OUTPUT:
   RETVAL

SV * 
numify (self, ...)
   SCM self
CODE:
   RETVAL = newSVscm(self);
OUTPUT:
   RETVAL

SV *
boolate (self, ...)
   SCM self
CODE:
 {
   if (self == SCM_BOOL_F      || 
       self == SCM_UNDEFINED   || 
       self == SCM_UNSPECIFIED || 
       self == SCM_EOL) {
     // definitely false
     RETVAL = &PL_sv_no;
   } else if (SCM_INUMP(self)) {
     // integers get returned as-is
     RETVAL = newSViv(SCM_INUM(self));
   } else {
     // everything else is true
     RETVAL = &PL_sv_yes;
   }
 }
OUTPUT:
   RETVAL


void DESTROY (SCM self)
CODE:
   scm_gc_unprotect_object(self);
