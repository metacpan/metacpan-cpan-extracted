#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>

MODULE = File::fgets            PACKAGE = File::fgets

SV*
xs_fgets(fh, limit)
    FILE* fh
    int limit
    CODE:
      limit++;  /* C's fgets gets length - 1 */

      SV* buffer = newSV(limit);
      SvPOK_on(buffer);

      char *string = SvPVX(buffer);
      char *ret = fgets(string, limit, fh);
      SvCUR_set(buffer, strlen(string));
      RETVAL = buffer;
    OUTPUT:
      RETVAL
