#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <dmapp.h>

static
int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static
double
constant(char *name, int arg)
{
    errno = 0;
   switch (*name) {
   }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Db::Documentum		PACKAGE = Db::Documentum		

double
constant(name,arg)
	char *name
	int	arg

int
dmAPIInit()
	PROTOTYPE: 
	CODE:
		RETVAL = dmAPIInit();
	OUTPUT:
	RETVAL

int
dmAPIDeInit()
	PROTOTYPE: 
	CODE:
		RETVAL = dmAPIDeInit();
	OUTPUT:
	RETVAL

int
dmAPIExec(cmd)
	char *cmd
	PROTOTYPE: $
	CODE:
		RETVAL = dmAPIExec(cmd);
	OUTPUT:
	RETVAL

char *
dmAPIGet(cmd)
	char *cmd
	PROTOTYPE: $
	CODE:
		RETVAL = dmAPIGet(cmd);
	OUTPUT:
	RETVAL

int
dmAPISet(name,value)
	char *name
	char *value
	PROTOTYPE: $$
	CODE:
		RETVAL = dmAPISet(name, value);
	OUTPUT:
	RETVAL

