#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "const-c.inc"

MODULE = Digest::Trivial		PACKAGE = Digest::Trivial		

INCLUDE: const-xs.inc

int
trivial_x (char *str);
   PROTOTYPE: $
   CODE:
       RETVAL = 0;
       for (; * str; str ++) {
           RETVAL ^= (unsigned char) * str;
       }
   OUTPUT:
       RETVAL


int
trivial_s (char *str);
   PROTOTYPE: $
   CODE:
       RETVAL = 0;
       for (; * str; str ++) {
           RETVAL += (unsigned char) * str;
       }
       RETVAL %= 256;
   OUTPUT:
       RETVAL
