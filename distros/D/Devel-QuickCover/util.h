#ifndef UTIL_H_
#define UTIL_H_

/*
 * A bunch of helper functions.
 */

#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include "ppport.h"

#include <stdio.h>
#include "buffer.h"

void dump_value(pTHX_ SV* val, Buffer* buf);
void dump_hash(pTHX_ HV* hash, Buffer* buf);
void dump_array(pTHX_ AV* array, Buffer* buf);

#endif
