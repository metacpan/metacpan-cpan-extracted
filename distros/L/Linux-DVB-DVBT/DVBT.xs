#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/*---------------------------------------------------------------------------------------------------*/
#include "xs/shared/DVBT-common.h"
#include "xs/DVBT-specific.h"

#include "xs/DVBT-init-c.c"

#define DVBT_VERSION		"2.03"

MODULE = Linux::DVB::DVBT		PACKAGE = Linux::DVB::DVBT

PROTOTYPES: ENABLE

 # /*---------------------------------------------------------------------------------------------------*/
INCLUDE: xs/DVBT-const.c

INCLUDE: xs/DVBT-init.c
INCLUDE: xs/DVBT-scan.c
INCLUDE: xs/DVBT-tuning.c
INCLUDE: xs/DVBT-epg.c
INCLUDE: xs/DVBT-record.c


 # /*---------------------------------------------------------------------------------------------------*/


