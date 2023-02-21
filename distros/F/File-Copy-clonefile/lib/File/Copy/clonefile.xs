#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

#include <sys/attr.h>
#include <sys/clonefile.h>

#include "const-c.inc"

MODULE = File::Copy::clonefile  PACKAGE = File::Copy::clonefile

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

void
clonefile(...)
PPCODE:
{
  if (items != 2 && items != 3) {
    croak("clonefile: the length of arguments must be 2 or 3");
  }
  const char* src = SvPV_nolen(ST(0));
  const char* dst = SvPV_nolen(ST(1));
  IV flags = 0;
  if (items == 3) {
    flags = SvIV(ST(2));
  }
  if (clonefile(src, dst, (int)flags) == 0) {
    XSRETURN_YES;
  } else {
    XSRETURN_UNDEF;
  }
}
