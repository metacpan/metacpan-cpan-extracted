#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "spike.h"

static int only_from_one(int x)
{
    if (x > 10)
        return x * 2;
    return x;
}

MODULE = Spike  PACKAGE = Spike

PROTOTYPES: DISABLE

int
add(a, b)
    int a
    int b
  ALIAS:
    plus = 1
  CODE:
    PERL_UNUSED_VAR(ix);
    RETVAL = a + b;
  OUTPUT:
    RETVAL

int
both(a, b)
    int a
    int b
  CODE:
    if (a && b)
        RETVAL = 1;
    else
        RETVAL = 0;
  OUTPUT:
    RETVAL

const char *
kind(n)
    int n
  CODE:
    switch (n) {
    case 0:
        RETVAL = "zero";
        break;
    case 1:
        RETVAL = "one";
        break;
    case 2:
        RETVAL = "two";
        break;
    case 3:
        RETVAL = "three";
        break;
    default:
        RETVAL = "many";
        break;
    }
  OUTPUT:
    RETVAL

int
twice_big(x)
    int x
  CODE:
    RETVAL = only_from_one(x);
  OUTPUT:
    RETVAL

int
inline_sq(x)
    int x
  CODE:
    RETVAL = spike_square(x);
  OUTPUT:
    RETVAL

int
helper_kind(n)
    int n
  CODE:
    RETVAL = spike_helper_switch(n);
  OUTPUT:
    RETVAL

int
guard(p)
    int p
  CODE:
    if (!p) /* # uncoverable branch true */
        croak("guard: p is zero");
    RETVAL = p;
  OUTPUT:
    RETVAL

INCLUDE: xs/more.xs
