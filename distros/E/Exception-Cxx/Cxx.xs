/*
Copyright © 1997-1999 Joshua Nathaniel Pritikin.  All rights reserved.
This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
*/

extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

struct PerlExCxxToken {
    int ret;
    PerlExCxxToken(int _ret) : ret(_ret) {}
};

static void cxx_thrower(int ret)
{ throw PerlExCxxToken(ret); }

void *
cxx_protect(int *except, protect_body_t body, ...)
{
    dTHR;
    dJMPENV;
    void *ret;
    DEBUG_l(deb("Setting up local C++ jumplevel %p, was %p\n",
 		&cur_env, PL_top_env));
    JMPENV_PUSH_INIT(cxx_thrower);
    try {
	va_list args;
 	va_start(args, body);
 	ret = body(args);
 	va_end(args);
	*except = 0;
    } catch (PerlExCxxToken token) {
	JMPENV_POST_CATCH;
	ret = NULL;
	*except = token.ret;
    };
    JMPENV_POP;
    return ret;
}

MODULE = Exception::Cxx		PACKAGE = Exception::Cxx

PROTOTYPES: ENABLE

BOOT:
  PL_protect = FUNC_NAME_TO_PTR(cxx_protect);

