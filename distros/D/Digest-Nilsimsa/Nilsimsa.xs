#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* $Id: Nilsimsa.xs,v 1.1 2002/05/20 22:29:07 chad Exp $ */

/* try to be compatible with older perls */
/* SvPV_nolen() macro first defined in 5.005_55 */
/* this is slow, not threadsafe, but works */
#include "patchlevel.h"
#if (PATCHLEVEL == 4) || ((PATCHLEVEL == 5) && (SUBVERSION < 55))
static STRLEN nolen_na;
# define SvPV_nolen(sv) SvPV ((sv), nolen_na)
#endif

#include "nilsimsa.h"

typedef struct nilsimsastate {
  int mode;
  char errmsg[99];
} *Digest__Nilsimsa;

MODULE = Digest::Nilsimsa		PACKAGE = Digest::Nilsimsa

PROTOTYPES: ENABLE


Digest::Nilsimsa
new(class)
        SV *    class
        CODE:
        {
          Newz(0, RETVAL, 1, struct nilsimsastate); 
          RETVAL->mode = 1;  /* placeholder, not used now */
          # dprint(" -- Opening debug file: /tmp/nilsimsa_debug.txt"); 
        }
        OUTPUT:
        RETVAL

char *
testxs(self, str)
        Digest::Nilsimsa	self;
        char *		str;
        CODE:
          RETVAL = str + 1;
	OUTPUT:
        RETVAL

SV *
errmsg(self)
        Digest::Nilsimsa self;
        CODE:
        {
          RETVAL = newSVpv(self->errmsg,0);
        }
	OUTPUT:
        RETVAL

SV *
text2digest(self, text)
        Digest::Nilsimsa self;
        SV *	text;
        CODE:
        {
	  struct nsrecord gunma;
          char str[65];
          unsigned char *rawbytes;
          int ret;
	  STRLEN size;

          rawbytes = SvPV(text,size);
	  clear(&gunma);
	  filltran();

	  ret=accbuf(rawbytes,size,&gunma);

	  makecode(&gunma);
	  codetostr(&gunma,str);

	  if (ret==size) {
	    RETVAL = newSVpv(str,64);
            *(self->errmsg) = 0;
          } else {  
            RETVAL = newSVpv ("", 0);
            sprintf(self->errmsg,"error: accbuf returned %d", ret);
	  }

        }
	OUTPUT:
        RETVAL

