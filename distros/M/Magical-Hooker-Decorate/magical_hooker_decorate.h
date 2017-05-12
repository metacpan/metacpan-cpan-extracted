#ifndef __MAGICAL_HOOKER_DECORATE_H__
#define __MAGICAL_HOOKER_DECORATE_H__

#include "perl.h"

START_EXTERN_C

MAGIC *magical_hooker_decoration_set (pTHX_ SV *sv, SV *obj, void *ptr);
MAGIC *magical_hooker_decoration_get_mg (pTHX_ SV *sv, void *ptr);
SV *magical_hooker_decoration_get (pTHX_ SV *sv, void *ptr);
SV *magical_hooker_decoration_clear (pTHX_ SV *sv, void *ptr);

END_EXTERN_C

#endif

