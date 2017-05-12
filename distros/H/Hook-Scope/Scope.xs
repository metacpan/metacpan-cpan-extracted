#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"




/* Global Data */

#define MY_CXT_KEY "Hook::Scope::_guts" XS_VERSION

typedef struct {
    /* Put Global Data in here */
    int dummy;		/* you can access this elsewhere as MY_CXT.dummy */
} my_cxt_t;

START_MY_CXT

void
exec_leave(pTHX_ SV* hook) {
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  PUTBACK;
  call_sv(hook, G_VOID);
  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
  SvREFCNT_dec(hook);
}

MODULE = Hook::Scope		PACKAGE = Hook::Scope		

PROTOTYPES: ENABLE

void
POST(SV* hook)
PROTOTYPE: &
PPCODE:
{
  LEAVE;
  SAVEDESTRUCTOR_X(exec_leave,newSVsv(hook));
  ENTER;
}


BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
}










