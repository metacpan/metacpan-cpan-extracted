#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/prctl.h>

#include "const-c.inc"

MODULE = Linux::Pdeathsig		PACKAGE = Linux::Pdeathsig		PREFIX = prpl_

INCLUDE: const-xs.inc

int
prpl_set_pdeathsig(signum)
    unsigned long signum
  INIT:
    char *errmsg;
  CODE:
    RETVAL = prctl(PR_SET_PDEATHSIG,signum);
    if (RETVAL == -1) {
        errmsg = strerror(errno);
        croak("set_pdeathsig failed: %s", errmsg);
    }
  OUTPUT:
    RETVAL 

int
prpl_get_pdeathsig()
  INIT:
    int rv;
    char *errmsg;
  CODE:
    rv = prctl(PR_GET_PDEATHSIG,&RETVAL);
    if (rv == -1) {
        errmsg = strerror(errno);
        croak("get_pdeathsig failed: %s", errmsg);
    }
  OUTPUT:
    RETVAL
