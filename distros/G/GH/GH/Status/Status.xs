#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <status.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_STAT_N(char *name, int len, int arg)
{
    if (6 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[6 + 1]) {
    case 'T':
	if (strEQ(name + 6, "OT_OPTIMAL")) {	/* STAT_N removed */
#ifdef STAT_NOT_OPTIMAL
	    return STAT_NOT_OPTIMAL;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (strEQ(name + 6, "O_MEM")) {	/* STAT_N removed */
#ifdef STAT_NO_MEM
	    return STAT_NO_MEM;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (strEQ(name + 6, "ULL_PTR")) {	/* STAT_N removed */
#ifdef STAT_NULL_PTR
	    return STAT_NULL_PTR;
#else
	    goto not_there;
#endif
        }
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_STAT_B(char *name, int len, int arg)
{
    switch (name[6 + 0]) {
    case 'A':
	if (strEQ(name + 6, "AD_ARGS")) {	/* STAT_B removed */
#ifdef STAT_BAD_ARGS
	    return STAT_BAD_ARGS;
#else
	    goto not_there;
#endif
	}
    case 'O':
	if (strEQ(name + 6, "OUND_TOO_TIGHT")) {	/* STAT_B removed */
#ifdef STAT_BOUND_TOO_TIGHT
	    return STAT_BOUND_TOO_TIGHT;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    if (0 + 5 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 5]) {
    case 'B':
	if (!strnEQ(name + 0,"STAT_", 5))
	    break;
	return constant_STAT_B(name, len, arg);
    case 'E':
	if (strEQ(name + 0, "STAT_EOF")) {	/*  removed */
#ifdef STAT_EOF
	    return STAT_EOF;
#else
	    goto not_there;
#endif
	}
    case 'F':
	if (strEQ(name + 0, "STAT_FAIL")) {	/*  removed */
#ifdef STAT_FAIL
	    return STAT_FAIL;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (!strnEQ(name + 0,"STAT_", 5))
	    break;
	return constant_STAT_N(name, len, arg);
    case 'O':
	if (strEQ(name + 0, "STAT_OK")) {	/*  removed */
#ifdef STAT_OK
	    return STAT_OK;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = GH::Status		PACKAGE = GH::Status		

PROTOTYPES: ENABLE


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

