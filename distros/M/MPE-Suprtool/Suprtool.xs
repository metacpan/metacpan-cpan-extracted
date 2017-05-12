#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>

static void (*supr)(char *);
#ifndef ST2LOC
# define ST2LOC ST2XL.PUB.ROBELLE
#endif
#define STR(x) #x
#define XSTR(x) STR(x)

int
getsuprcall(char *xl)
{
    static char suprtool2[] = "\0suprtool2";
    int stat;
    HPGETPROCPLABEL(4, suprtool2, &supr, &stat, xl, 0,0,0,0,0);
    if (stat) {
      int depth, stat2;
      HPERRMSG(4, 2, 0, 0, stat, 0, 0, 0);
      HPERRDEPTH(2, &depth, &stat2);
      if (stat2 == 0 && depth != 0) {
	HPERRMSG(4, 1, depth, 0, stat, 0, 0, 0);
      }
      fprintf (stderr, "Could not load suprtool2 xl='%s'\n",
	            xl+1);
    }
    return (int)supr;
}

MODULE = MPE::Suprtool		PACKAGE = MPE::Suprtool

char *
configst2loc()
  CODE:
    RETVAL = XSTR(ST2LOC);
  OUTPUT:
    RETVAL


int
getsuprcall(xl)
  char *xl
  PROTOTYPE: $

int
suprcall(suprbuf)
    char *suprbuf
  PROTOTYPE: $
  CODE:
    supr(suprbuf);
    RETVAL = !*(short *)(&suprbuf[2]);
  OUTPUT:
    RETVAL
