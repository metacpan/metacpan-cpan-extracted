/* This file is part of the Mac::NSGetExecutablePath Perl module.
 * See http://search.cpan.org/dist/Mac-NSGetExecutablePath/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mach-o/dyld.h>

static const char nsgep_too_long[] = "NSGetExecutablePath() wants to return a path too large";

/* --- XS ------------------------------------------------------------------ */

MODULE = Mac::NSGetExecutablePath        PACKAGE = Mac::NSGetExecutablePath

PROTOTYPES: ENABLE

void
NSGetExecutablePath()
PROTOTYPE:
PREINIT:
 char      buf[1];
 uint32_t  size = sizeof buf;
 SV       *dst;
 char     *buffer;
PPCODE:
 _NSGetExecutablePath(buf, &size);
 if (size >= MAXPATHLEN * MAXPATHLEN)
  croak(nsgep_too_long);
 dst    = sv_newmortal();
 sv_upgrade(dst, SVt_PV);
 buffer = SvGROW(dst, size);
 if (_NSGetExecutablePath(buffer, &size))
  croak(nsgep_too_long);
 if (size)
  SvCUR_set(dst, size - 1);
 SvPOK_on(dst);
 XPUSHs(dst);
 XSRETURN(1);
