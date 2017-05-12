#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <math.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_M_PI_(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case '2':
	if (strEQ(name + 5, "2")) {	/* M_PI_ removed */
#ifdef M_PI_2
	    return M_PI_2;
#else
	    goto not_there;
#endif
	}
    case '4':
	if (strEQ(name + 5, "4")) {	/* M_PI_ removed */
#ifdef M_PI_4
	    return M_PI_4;
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
constant_M_P(char *name, int len, int arg)
{
    if (3 + 1 > len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 1]) {
    case '\0':
	if (strEQ(name + 3, "I")) {	/* M_P removed */
#ifdef M_PI
	    return M_PI;
#else
	    goto not_there;
#endif
	}
    case '_':
	if (!strnEQ(name + 3,"I", 1))
	    break;
	return constant_M_PI_(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_M_2(char *name, int len, int arg)
{
    if (3 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 1]) {
    case 'P':
	if (strEQ(name + 3, "_PI")) {	/* M_2 removed */
#ifdef M_2_PI
	    return M_2_PI;
#else
	    goto not_there;
#endif
	}
    case 'S':
	if (strEQ(name + 3, "_SQRTPI")) {	/* M_2 removed */
#ifdef M_2_SQRTPI
	    return M_2_SQRTPI;
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
constant_M_S(char *name, int len, int arg)
{
    if (3 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[3 + 3]) {
    case '1':
	if (strEQ(name + 3, "QRT1_2")) {	/* M_S removed */
#ifdef M_SQRT1_2
	    return M_SQRT1_2;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 3, "QRT2")) {	/* M_S removed */
#ifdef M_SQRT2
	    return M_SQRT2;
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
constant_M_LN(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case '1':
	if (strEQ(name + 4, "10")) {	/* M_LN removed */
#ifdef M_LN10
	    return M_LN10;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 4, "2")) {	/* M_LN removed */
#ifdef M_LN2
	    return M_LN2;
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
constant_M_LO(char *name, int len, int arg)
{
    if (4 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 1]) {
    case '1':
	if (strEQ(name + 4, "G10E")) {	/* M_LO removed */
#ifdef M_LOG10E
	    return M_LOG10E;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (strEQ(name + 4, "G2E")) {	/* M_LO removed */
#ifdef M_LOG2E
	    return M_LOG2E;
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
constant_M_L(char *name, int len, int arg)
{
    switch (name[3 + 0]) {
    case 'N':
	return constant_M_LN(name, len, arg);
    case 'O':
	return constant_M_LO(name, len, arg);
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
    if (0 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[0 + 2]) {
    case '1':
	if (strEQ(name + 0, "M_1_PI")) {	/*  removed */
#ifdef M_1_PI
	    return M_1_PI;
#else
	    goto not_there;
#endif
	}
    case '2':
	if (!strnEQ(name + 0,"M_", 2))
	    break;
	return constant_M_2(name, len, arg);
    case 'E':
	if (strEQ(name + 0, "M_E")) {	/*  removed */
#ifdef M_E
	    return M_E;
#else
	    goto not_there;
#endif
	}
    case 'L':
	if (!strnEQ(name + 0,"M_", 2))
	    break;
	return constant_M_L(name, len, arg);
    case 'P':
	if (!strnEQ(name + 0,"M_", 2))
	    break;
	return constant_M_P(name, len, arg);
    case 'S':
	if (!strnEQ(name + 0,"M_", 2))
	    break;
	return constant_M_S(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Math::Libm		PACKAGE = Math::Libm


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

double
acos(x)
	double	x
	PROTOTYPE: $

double
acosh(x)
	double	x
	PROTOTYPE: $

double
asin(x)
	double	x
	PROTOTYPE: $

double
asinh(x)
	double	x
	PROTOTYPE: $

double
atan(x)
	double	x
	PROTOTYPE: $

double
atanh(x)
	double	x
	PROTOTYPE: $

double
cbrt(x)
	double	x
	PROTOTYPE: $

double
ceil(x)
	double	x
	PROTOTYPE: $

double
cosh(x)
	double	x
	PROTOTYPE: $

double
erf(x)
	double	x
	PROTOTYPE: $

double
erfc(x)
	double	x
	PROTOTYPE: $

double
expm1(x)
	double	x
	PROTOTYPE: $

double
floor(x)
	double	x
	PROTOTYPE: $

double
hypot(x, y)
	double	x
	double	y
	PROTOTYPE: $$

double
j0(x)
	double	x
	PROTOTYPE: $

double
j1(x)
	double	x
	PROTOTYPE: $

double
jn(n, x)
	int	n
	double	x
	PROTOTYPE: $$

double
lgamma_r(x, signgamp)
	double	x
	int	&signgamp
	PROTOTYPE: $$
	CODE:
#ifdef _AIX
	RETVAL = lgamma(x);
	signgamp = signgam;
#else
	RETVAL = lgamma_r(x, &signgamp);
#endif
	OUTPUT:
	signgamp
	RETVAL

double
log10(x)
	double	x
	PROTOTYPE: $

double
log1p(x)
	double	x
	PROTOTYPE: $

double
pow(x, y)
	double	x
	double	y
	PROTOTYPE: $$

double
rint(x)
	double	x
	PROTOTYPE: $

double
sinh(x)
	double	x
	PROTOTYPE: $

double
tan(x)
	double	x
	PROTOTYPE: $

double
tanh(x)
	double	x
	PROTOTYPE: $

double
y0(x)
	double	x
	PROTOTYPE: $

double
y1(x)
	double	x
	PROTOTYPE: $

double
yn(n, x)
	int	n
	double	x
	PROTOTYPE: $$
