/* PerlInterpreter.c: Embed a perl interpreter.
 * ------------------------------------------------------------------------
 * Defines a few helpful functions to embed a perl interpreter.
 * Strongly inspired by the perlembed manpage.
 * ------------------------------------------------------------------------
 * $Id: PerlInterpreter.c 11 2004-10-17 22:19:26Z crenz $
 * Copyright (C) 2001, 2004 Christian Renz <crenz@web42.com>.
 * All rights reserved.
 */

#include "perlinterpreter.h"
#include <stdio.h>
#include <EXTERN.h>
#include <perl.h>

static PerlInterpreter *my_perl;

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

EXTERN_C void xs_init(pTHX) {
    char *file = __FILE__;
    dXSUB_SYS;

	/* DynaLoader is a special case */
	newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

void perl_init(int* argcp, char*** argvp, char*** envp) {
  PERL_SYS_INIT3(argcp, argvp, envp);

  char *embedding[] = { "", "-e", "0" };

  my_perl = perl_alloc();
  perl_construct(my_perl);
  perl_parse(my_perl, xs_init, 3, embedding, NULL);
  perl_run(my_perl);
}

void perl_init_argv(int argc, char **argv) {
  Perl_init_argv_symbols(my_perl, argc - 1, argv + 1);
}

void perl_destroy() {
  perl_destruct(my_perl);
  perl_free(my_perl);

  PERL_SYS_TERM();
}

void perl_exec(char *s) {
  eval_pv(s, TRUE);
}

char * perl_getstring(char *s) {
  SV *sv = get_sv(s, FALSE);

  if (!sv)
    return NULL;

  return SvPV(sv, PL_na);
}

/* eof *******************************************************************/

