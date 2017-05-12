#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mpe.h>



extern void CREATEPROCESS(int           *createstatus,
                          short         *pin,
                          const char    *formaldesig,
                          const long    *itemnums,      /* optional */
                          const long    *items);  	/* optional */

extern void ACTIVATE(short   		pin,
                     unsigned short     allow );	/* optional */

static int createstatus;
static char *errmsgs[] = {
  "Successful",
  "Process handling (PH) capability required",
  "Pin or formaldesig parameter missing;"
      "or one of itemnum pair is missing",
  "Parameter address out of bounds",
  "Out of system resources",
  "Process not created; invalid itemnum specified",
  "Process not created; formaldesig does not exist",
  "Process not created; formaldesig invalid",
  "Process not created; entry name invalid or does not exist",
  "Process created; LIBSEARCH bits ignored",
  "Process created; itemnum=19 ignored",
  "Unknown CREATEPROCESS Error (11)",
  "Unknown CREATEPROCESS Error (12)",
  "Unknown CREATEPROCESS Error (13)",
  "Unknown CREATEPROCESS Error (14)",
  "Process not created; reserved item was specified",
  "Process not created; hard load error occurred",
  "Process not created; illegal value specified for itemnum=7",
  "Process not created; specified $STDIN could not be opened",
  "Process not created; specified $STDLIST could not be opened",
  "Process not created; string to be passed to new process invalid",
};

static void
seterror(int status)
{
   int create=1;
   SV *exterr;
   char *msg;
   exterr = get_sv("MPE::Process::CreateStatus", create);
   if (status < 0 || status >= sizeof(errmsgs)/sizeof(errmsgs[0])) {
     msg = "Unknown CREATEPROCESS error";
   } else {
     msg = errmsgs[status];
   }
   sv_setpv(exterr, msg);
   sv_setiv(exterr, status);
   SvPOK_on(exterr);
}

MODULE = MPE::Process		PACKAGE = MPE::Process		
short
createprocess(name, itemnums, itemvals)
  char *name
  char *itemnums
  char *itemvals
  PROTOTYPE: $$$
  CODE:
  {
    short pin=0;
    CREATEPROCESS(&createstatus, &pin, name,
	(long *)itemnums, (long *)itemvals);
	seterror(createstatus);
    RETVAL = pin;
  }
  OUTPUT:
    RETVAL

short
activate1(pin, allow)
  short pin
  unsigned short allow
  CODE:
  {
     ACTIVATE(pin, allow);
     if (ccode() == CCL)
       RETVAL = 0;
     else
       RETVAL = 1;
  }
  OUTPUT:
    RETVAL

short
kill1(pin)
  short pin
  CODE:
  {
     KILL(pin);
     if (ccode() == CCL)
       RETVAL = 0;
     else
       RETVAL = 1;
  }
  OUTPUT:
    RETVAL

short
getorigin()
  CODE:
  {
    RETVAL = GETORIGIN();
  }
  OUTPUT:
    RETVAL

long
getprocinfo(pin)
  short pin
  CODE:
  {
    RETVAL = GETPROCINFO(pin);
  }
  OUTPUT:
    RETVAL
