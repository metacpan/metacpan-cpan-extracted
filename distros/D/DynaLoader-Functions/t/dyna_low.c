#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#if defined(WIN32) && PERL_VERSION_GE(5,13,6)
# define MY_BASE_CALLCONV EXTERN_C
#else /* !(WIN32 && >= 5.13.6) */
# define MY_BASE_CALLCONV PERL_CALLCONV
#endif /* !(WIN32 && >= 5.13.6) */

#define MY_EXPORT_CALLCONV MY_BASE_CALLCONV

MY_EXPORT_CALLCONV int dynalow_foo(void)
{
	return 42;
}

MY_EXPORT_CALLCONV int dynalow_bar(void)
{
	return 69;
}

/* this is necessary for building on some platforms */
MY_EXPORT_CALLCONV int boot_t__dyna_low(void)
{
	return 666;
}
