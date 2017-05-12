#ifndef __GIT_XS_HELPERS_H__
#define __GIT_XS_HELPERS_H__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

START_EXTERN_C

SV *call_getter(SV *self, char *has);
int call_test(SV *self, char *test, SV* arg);

END_EXTERN_C

#endif
