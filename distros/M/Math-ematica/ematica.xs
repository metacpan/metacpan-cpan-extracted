/*                               -*- Mode: C -*- 
 * $Basename: ematica.xs $
 * $Revision: 1.23 $
 * Author          : Ulrich Pfeifer
 * Created On      : Sat Dec 20 15:18:26 1997
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Tue Apr 26 16:53:01 2005
 * Language        : C
 * Update Count    : 266
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
 * 
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include <mathlink.h>
#include "constants.h"

/* Class for Mathematica Symbols */
#define SYMNAME "Math::ematica::symbol"

MLENV env = NULL;

static void
error(long merrno)
{
  croak("Mathematica error %ld: %s\n", merrno, MLErrorString(env, merrno));
}

static SV *
make_symbol(char * name)
{
  SV * result = newRV_noinc(newSVpv(name,0));
  sv_bless(result, gv_stashpv(SYMNAME,1));
  return (result);
}

static SV *
read_packet (MLINK link)
{
  mlapi_token token;
  SV *RETVAL = NULL;

  token = MLGetNext (link);
  switch (token) {
  case MLTKREAL:{
      double real;

      if (!MLGetDouble (link, &real))
	return (RETVAL);
      RETVAL = newSVnv (real);
      break;
    }
  case MLTKINT:{
      int integer;

      if (!MLGetInteger (link, &integer))
	return (RETVAL);
      RETVAL = newSViv (integer);
      break;
    }
  case MLTKSTR:{
      kcharp_ct string;

      if (!MLGetString (link, &string))
	return (RETVAL);
      RETVAL = newSVpv ((char *) string, 0);
      MLDisownString (link, string);
      break;
    }
  case MLTKSYM:{
      kcharp_ct string;

      if (!MLGetSymbol (link, &string))
	return (RETVAL);
      RETVAL = make_symbol ((char *) string);
      MLDisownSymbol (link, string);
      break;
    }
  case MLTKFUNC:{
      kcharp_ct string;
      long_st nargs;
      long_st i;
      long_st j = 0;
      AV * array;

      if (!MLGetFunction (link, &string, &nargs))
	return (&PL_sv_undef);

      array = newAV ();
      av_extend(array, nargs+1);
      if (strNE(string,"List"))
        av_store (array, j++, make_symbol ((char *) string)); 
      MLDisownSymbol (link, string);
      for (i = 0; i < nargs; i++) {
	av_store (array, j++, read_packet (link));
      }
      RETVAL = (SV *) newRV_noinc((SV*)array);
      break;
    }
  default:
    warn("Unknow packet type: %c\n", token);
  }
  return (RETVAL);
}

MODULE = Math::ematica	 PACKAGE = Math::ematica	  PREFIX = ML

BOOT:
  env = MLInitialize(0);

double
MLconstant(name,arg)
	char *		name
	int		arg


SV*
new(CLASS, ...)
	char *	CLASS
CODE: 
{
  char **argv = NULL;
  int argn;
  long merrno = 0;
  MLINK link;
  HV *self;
  New (14, argv, items, char *);

  if (!argv) croak ("Out of memory");

  for (argn = 0; argn < items; argn++) {
    argv[argn] = (char *) SvPV (ST (argn), PL_na);
  }

  link = MLOpenArgv (env, argv, argv + items, &merrno);

  Safefree(argv);

  if (merrno) error (merrno);
  MLActivate(link);

  self  = newHV();
  hv_store(self, "mlink", 5, newSViv((int) link), 0); 
  if (items == 1) 
    hv_store(self, "passive", 7, newSViv(1), 0); 
  RETVAL = sv_bless(newRV_noinc((SV*) self), gv_stashpv(CLASS,1));
}
OUTPUT: RETVAL


void
DESTROY(link)
	MLINK	link
CODE:
	if (!env) {
	  if (PL_dowarn) {
	    warn("Can not close link during global destruction!");
	  }
	} else {
	  if (link) MLClose(link); 
	}


void
END()
CODE:
        MLDeinitialize(env);
        env = NULL;

kcharp_ct
MLErrorMessage(link)
	MLINK	link


 # Basic PACKET-functions 
 # sending packets

mlapi_result
MLEndPacket(link)
	MLINK	link

mlapi_result
MLFlush(link)
	MLINK	link

mlapi_result
MLNewPacket(link)
	MLINK	link
	
 # receiving packets

mlapi_packet
MLNextPacket(link)
	MLINK	link

mlapi_result
MLReady(link)
	MLINK	link

 # Basic PUT-functions 

mlapi_result
MLPutSymbol(link, string)
	MLINK	  link
	kcharp_ct string

mlapi_result
MLPutString(link, string)
	MLINK	  link
	kcharp_ct string

mlapi_result
MLPutInteger(link, integer)
	MLINK	link
	int_nt 	integer

mlapi_result
MLPutDouble(link, real)
	MLINK	link
	double_nt 	real

mlapi_result
MLPutFunction(link, name, nargs)
	MLINK		link
	kcharp_ct	name
	long_st 	nargs


 # Basic GET-functions

mlapi_token
MLGetNext(link)
	MLINK	link

int
MLGetInteger(link)
	MLINK	link
CODE:   
	if (!MLGetInteger(link, &RETVAL)) XSRETURN_UNDEF;
OUTPUT: 
	RETVAL

double
MLGetDouble(link)
	MLINK	link
CODE:   
	if (!MLGetDouble(link, &RETVAL)) XSRETURN_UNDEF;
OUTPUT: 
	RETVAL

kcharp_ct
MLGetString(link)
	MLINK	link
CODE:   
	if (!MLGetString(link, &RETVAL)) XSRETURN_UNDEF;
OUTPUT: 
	RETVAL
CLEANUP:
        MLDisownString(link, RETVAL);

SV *
MLGetByteString(link, ...)
	MLINK	link
CODE:
        {         
            long                 spec = 0;
            const unsigned char *s;
            long                 n;
            if (items > 1) {
              spec = SvNV(ST(1));
            }
            if (!MLGetByteString(link, &s, &n, spec)) {
              XSRETURN_UNDEF;
            } else {
              RETVAL = newSVpvn(s, n);
              MLDisownByteString(link, s, n);
            }
        }
OUTPUT: 
        RETVAL

SV *
MLGetSymbol(link)
	MLINK	link
PREINIT:
	kcharp_ct symname;
CODE:   
	if (!MLGetSymbol(link, &symname)) XSRETURN_UNDEF;
        RETVAL = make_symbol((char *)symname);
OUTPUT: 
	RETVAL
CLEANUP:
        MLDisownSymbol(link, symname);


void
MLGetFunction(link)
	MLINK	link
PREINIT:
	char *    name;
	long_st   nargs;
        SV *      symbol;
PPCODE:
        if (!MLGetFunction(link, (kcharpp_ct) &name, &nargs)) {
          XSRETURN_UNDEF;
        }
        symbol = make_symbol(name);
        MLDisownSymbol(link, name);
        XPUSHs(sv_2mortal(symbol));
        if (GIMME_V == G_ARRAY) {
          XPUSHs(sv_2mortal(newSViv(nargs)));
          XSRETURN(2);
        } else {
          XSRETURN(1);
        }

void
MLGetRealList(link)
	MLINK	link
PREINIT:
	doublep_nt	array;
	long_st         len;
        long_st         i;
PPCODE:
        if (!MLGetRealList(link, &array, &len)) {
          XSRETURN_UNDEF;
        }
        EXTEND(sp, len);
        for (i=0;i<len;i++) {
          PUSHs(sv_2mortal(newSVnv(array[i])));
        }
        MLDisownRealList(link, array, len);
        XSRETURN(len);

void
symbol(name)
	SV *	name
PPCODE:
        ST(0) = sv_2mortal(newRV_noinc(newSVsv(name)));
        sv_bless(ST(0), gv_stashpv(SYMNAME,1));
	XSRETURN(1);

mlapi_result
PutToken(link, elem, ...)
	MLINK	link
	SV *	elem
CODE:
	if (SvROK(elem)) {
          if (sv_isobject(elem) && sv_isa(elem, SYMNAME)) {
            if (items > 2) {
              RETVAL = MLPutFunction(link, SvPV(SvRV(elem), PL_na), SvIV(ST(2)));
            } else {
              RETVAL = MLPutSymbol(link, SvPV(SvRV(elem), PL_na));
            }
          } else {
            warn( "Math::ematica::PutScalar() -- elem is not a Math::ematica::symbol" );
            XSRETURN_UNDEF;
          }
        } else if (SvIOKp(elem)) {
          RETVAL = MLPutInteger(link, SvIV(elem));
        } else if (SvNOKp(elem)) {
          RETVAL = MLPutDouble(link, SvNV(elem));
        } else if (SvPOKp(elem)) {
          RETVAL = MLPutString(link, SvPV(elem, PL_na));
        } else {
          RETVAL = 0;
        }
OUTPUT:
	RETVAL

SV *
read_packet(link)
	MLINK	link
CODE:
	if ((RETVAL = read_packet(link)) == NULL) {
          XSRETURN_UNDEF;
        }
OUTPUT:
	RETVAL

        
