#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#define NEED_mro_get_linear_isa_GLOBAL
#include "mro_compat.h"

typedef HV STASH;

/* these mro_* functions are only for tests */

MODULE = MyMRO		PACKAGE = MyMRO

PROTOTYPES: DISABLE

AV*
mro_get_linear_isa(package)
	STASH* package

U32
mro_get_pkg_gen(package)
	STASH* package

void
mro_method_changed_in(package)
	STASH* package

