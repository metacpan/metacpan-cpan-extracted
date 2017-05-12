#ifndef SIM_TYPES_H
#define SIM_TYPES_H
/* $Id: types.h,v 1.1 2002/12/03 20:12:37 hartzell Exp $ */

#define NACHARS 128

#ifdef PERL_SIM4
#undef bool			/* XXXX someone up the chain #defines bool. sigh... */
#endif
typedef int bool;
typedef int ss_t[NACHARS][NACHARS];
typedef unsigned char uchar;

#endif
