#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/*---------------------------------------------------------------------------------------------------*/
#include "xs/shared-ts/shared/DVBT-common.h"
#include "xs/DVBT-specific.h"

#include "xs/shared-ts/DVBT-ts-shared-c.c"
#include "xs/DVBT-advert-c.c"
#include "xs/DVBT-ad-tie-c.c"

#define DVBT_AD_VERSION		"1.00"


MODULE = Linux::DVB::DVBT::Advert		PACKAGE = Linux::DVB::DVBT::Advert

PROTOTYPES: ENABLE

 # /*---------------------------------------------------------------------------------------------------*/
INCLUDE: xs/DVBT-const.c

INCLUDE: xs/DVBT-advert.c
INCLUDE: xs/DVBT-ad-skip.c
INCLUDE: xs/DVBT-ad-tie.c


 # /*---------------------------------------------------------------------------------------------------*/


