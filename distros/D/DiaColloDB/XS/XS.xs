/*-*- Mode: C -*-*/

/*==============================================================================
 * Header stuff
 */
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <inttypes.h>
/*#include "ppport.h"*/
}

#include "utils.h"
#include "cof-gen.h"
#include "cof-compile.h"

/*==============================================================================
 * XS Guts
 */

MODULE = DiaColloDB::XS    PACKAGE = DiaColloDB::XS

##=====================================================================
## bootstrap
##=====================================================================
BOOT:
//-- nothing to see here, move along

##=====================================================================
## submodules

INCLUDE: CofUtils.xs
