#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "fz/fz_compat.h"

#include "fz_abi.h"
#include "fz/fz_format.h"
#include "fz/fz_build.h"
#include "fz/fz_map.h"
#include "fz/fz_read.h"
#include "fz/fz_sv.h"
#include "fz/fz_xop.h"
#include "fz/fz_abi_impl.h"

MODULE = Frozen    PACKAGE = Frozen

PROTOTYPES: DISABLE

INCLUDE: xs/freeze.xs
INCLUDE: xs/container.xs
INCLUDE: xs/read.xs
INCLUDE: xs/tie.xs
INCLUDE: xs/xop.xs
INCLUDE: xs/abi.xs
