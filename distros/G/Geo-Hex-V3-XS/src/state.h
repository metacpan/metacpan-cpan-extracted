#pragma once

#include "use_perl.h"
#include "geohex3.h"

HV* new_state (pTHX_ const geohex_t *geohex);
HV* init_state (pTHX_ HV* state, const geohex_t *geohex);
SV* bless_state (pTHX_ const HV* state, const char *class);
geohex_t deflate_to_geohex(pTHX_ HV* state);
