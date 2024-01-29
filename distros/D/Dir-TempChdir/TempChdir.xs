/* Needed for O_PATH on Linux. */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* ppport.h says we don't need caller_cx but a few cpantesters report
 * "undefined symbol: caller_cx". */
#define NEED_caller_cx
#define NEED_croak_xs_usage
#define NEED_newCONSTSUB_GLOBAL
#include "ppport.h"

/* Get O_SEARCH, O_PATH definitions. */
#ifdef I_FCNTL
#include <fcntl.h>
#endif

#include "const-c.inc"

#define PACKNAME "Dir::TempChdir"

MODULE = Dir::TempChdir    PACKAGE = Dir::TempChdir

INCLUDE: const-xs.inc

BOOT:
{
}
