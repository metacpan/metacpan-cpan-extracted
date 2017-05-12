/* Gearman Perl front end
 * Copyright (C) 2013 Data Differential, http://datadifferential.com/
 * Copyright (C) 2009-2010 Dennis Schoen
 * All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.8.9 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#pragma once

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <libgearman-1.0/gearman.h>

#define XS_STATE(type, x) (INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x)))

#define XS_STRUCT2OBJ(sv, class, obj) if (obj == NULL) {  sv_setsv(sv, &PL_sv_undef); } else {  sv_setref_pv(sv, class, (void *) obj);  }

SV *_bless(const char *class, void *obj);
void _perl_free(void *ptr, void *arg);
void *_perl_malloc(size_t size, void *arg);
void *_get_string(SV *sv, size_t *size);
