#ifndef __linux
#error "No linux. Compile aborted."
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stdlib.h"

MODULE = Linux::loadavg		PACKAGE = Linux::loadavg		

void
loadavg(nelem=3)
   int nelem;
PREINIT:
   double loadavg[3];
   int     rc, i;
PPCODE:
   if (nelem > 3 || nelem < 1)
      croak("invalid nelem (%d)", nelem);
   if ((rc = getloadavg(loadavg, nelem)) != nelem)
      croak("getloadavg failed (%d)", rc);
   for(i=0; i<nelem; i++) {
      ST(i) = newSVnv(loadavg[i]);
      sv_2mortal(ST(i));
   }
   XSRETURN(nelem);
