#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/*---------------------------------------------------------------------------------------------------*/
#include "xs/shared/DVBT-common.h"

#include "xs/DVBT-ts-c.c"

#define DVBT_TS_VERSION		"1.00"


MODULE = Linux::DVB::DVBT::TS		PACKAGE = Linux::DVB::DVBT::TS

PROTOTYPES: ENABLE

 # /*---------------------------------------------------------------------------------------------------*/
INCLUDE: xs/DVBT-ts.c
INCLUDE: xs/DVBT-ts-skip.c


 # /*---------------------------------------------------------------------------------------------------*/



