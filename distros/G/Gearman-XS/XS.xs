/* Gearman Perl front end
 * Copyright (C) 2013 Data Differential, http://datadifferential.com/
 * Copyright (C) 2009-2010 Dennis Schoen
 * All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.8.9 or,
 * at your option, any later version of Perl 5 you may have available.
 */

#include "gearman_xs.h"

static void
call_XS ( pTHX_ void (*subaddr) (pTHX_ CV *), CV * cv, SV ** mark )
{
 dSP;
 PUSHMARK (mark);
 (*subaddr) (aTHX_ cv);
 PUTBACK;
}

#define CALL_BOOT(name)	call_XS (aTHX_ name, cv, mark)

SV *_bless(const char *class, void *obj) {
  SV * ret = newSViv(0);
  XS_STRUCT2OBJ(ret, class, obj);
  return ret;
}

void _perl_free(void *ptr, void *arg)
{
  PERL_UNUSED_VAR(arg);
  Safefree(ptr);
}

void *_perl_malloc(size_t size, void *arg)
{
  PERL_UNUSED_VAR(arg);
  return safemalloc(size);
}

/* get the stringified version of the SV without a trailing NULL byte */
void *_get_string(SV *sv, size_t *size)
{
  void *string= NULL;
  SvPV_nolen(sv); /* this is necessary for SvCUR to get the stringified length */
  *size= SvCUR(sv);
  Newxz(string, *size, char);
  memcpy(string, SvPV_nolen(sv), *size);
  return string;
}

/* We need these declarations with "C" linkage */

#ifdef __cplusplus
extern "C" {
#endif
  XS(boot_Gearman__XS__Const);
  XS(boot_Gearman__XS__Worker);
  XS(boot_Gearman__XS__Task);
  XS(boot_Gearman__XS__Client);
  XS(boot_Gearman__XS__Job);
#ifdef __cplusplus
}
#endif

MODULE = Gearman::XS    PACKAGE = Gearman::XS

PROTOTYPES: ENABLE

BOOT:
  /* call other *.xs modules */
  CALL_BOOT(boot_Gearman__XS__Const);
  CALL_BOOT(boot_Gearman__XS__Worker);
  CALL_BOOT(boot_Gearman__XS__Task);
  CALL_BOOT(boot_Gearman__XS__Client);
  CALL_BOOT(boot_Gearman__XS__Job);

const char *
strerror(gearman_return_t rc)
  CODE:
    RETVAL = gearman_strerror(rc);
  OUTPUT:
    RETVAL
