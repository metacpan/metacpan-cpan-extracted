#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>

MODULE = MPE::CIvar             PACKAGE = MPE::CIvar            


SV *
hpcigetvar(name)
        char *   name
  PROTOTYPE: $
  PREINIT:
        char buffer[256];
        int buflen=sizeof(buffer)-1;
        int status;
        int len=0;
        int type=0;
        int intval;
        int boolval;
  CODE:
        RETVAL = ST(0) = sv_newmortal();
        HPCIGETVAR(14, name, &status,
                        1, &intval,
                        2, buffer,
                        3, &boolval,
                       10, &buflen,
                       11, &len,
                       13, &type);
        if (status)
          XSRETURN_UNDEF;
        if (type == 1) {
          sv_setiv(RETVAL, intval);
        } else if (type==2) {
          buffer[len] = '\0';
          sv_setpv(RETVAL, buffer);
        } else if (type==3) {
          sv_setiv(RETVAL, boolval);
        }

int
hpcideletevar(name)
      char * name
    PROTOTYPE: $
    CODE:
       HPCIDELETEVAR(2, name, &RETVAL);
    OUTPUT:
       RETVAL

int
hpciputvar(name, value)
       char *   name
       SV   *   value
    PROTOTYPE: $$
    CODE:
       if (SvIOK(value)) {
         int intval = SvIV(value);
         HPCIPUTVAR(14, name, &RETVAL,
                       1, &intval,
                       0, 0,
                       0, 0,
                       0, 0,
                       0, 0,
                       0, 0);
       } else {
         char *string;
         STRLEN len;
         string = SvPV(value, len);
         HPCIPUTVAR(14, name, &RETVAL,
                       2, string,
                      11, &len,
                       0, 0,
                       0, 0,
                       0, 0,
                       0, 0);
       }
    OUTPUT:
      RETVAL

unsigned short
getjcw()
  PROTOTYPE:
  PREINIT:
    SV *s;
  CODE:
    RETVAL = GETJCW();
  OUTPUT:
    RETVAL


short
putjcw(name, value)
     char *name
     unsigned short value
  PROTOTYPE: $$
  CODE:
    PUTJCW(name, &value, &RETVAL);
  OUTPUT:
    RETVAL

unsigned short
findjcw(name)
     char *name
  PROTOTYPE: $
  PREINIT:
     short status=-1;
  CODE:
     FINDJCW(name, &RETVAL, &status);
     if (status)
        XSRETURN_UNDEF;
  OUTPUT:
     RETVAL

void
setjcw(value)
      unsigned short value
   PROTOTYPE: $
   CODE:
      SETJCW(value);

short
hpcicommand(command,...)
       SV *command
   PROTOTYPE: $;$$$
   PREINIT:
       char *pcmd, *pend;
       char savedchar;
       short cmderror, parmnum, msglevel=0;
       STRLEN len;
       SV *sv_cmderror=NULL;
       SV *sv_parmnum=NULL;
   CODE:
       if (items>1) {
         sv_cmderror=ST(1);
         if (items>2) {
           sv_parmnum=ST(2);
           if (items>3)
             msglevel=sv_iv(ST(3));
         }
       }
       pcmd=SvPV(command, len);
       if (pcmd==NULL || len < 1) {
         RETVAL = -1;
       } else {

         pend = &pcmd[len-1];
         savedchar = *pend;
         if (savedchar != ' ' && savedchar != '\0' && savedchar != '\r') {
           if (SvLEN(command) <= len)
             pcmd = SvGROW(command, len+1);
           pend = &pcmd[len];
           savedchar = *pend;
         }
         *pend = '\r';
         HPCICOMMAND(4, pcmd, &cmderror, &parmnum, msglevel);
         *pend = savedchar;
         RETVAL=cmderror;
         if (sv_cmderror && !SvREADONLY(sv_cmderror))
           sv_setiv(sv_cmderror, cmderror);

         if (sv_parmnum && !SvREADONLY(sv_parmnum))
           sv_setiv(sv_parmnum, parmnum);
        }
   OUTPUT:
      RETVAL
