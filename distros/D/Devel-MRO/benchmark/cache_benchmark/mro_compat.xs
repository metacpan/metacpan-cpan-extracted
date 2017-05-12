#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include "mro.h"
#undef mro_get_linear_isa
#undef mro_get_pkg_gen

#define NEED_mro_get_linear_isa
#include "mro_compat.h"

typedef HV STASH;

/* these mro_* functions are only for tests */

MODULE = mro_compat	PACKAGE = mro_compat	PREFIX = mro_

PROTOTYPES: DISABLE

AV*
mro_get_linear_isa_dfs(STASH* package)
CODE:
	RETVAL = mro_get_linear_isa_dfs(aTHX_ package, 0);
OUTPUT:
	RETVAL

AV*
mro_get_linear_isa(STASH* package)

void
mro_method_changed_in(STASH* package)
