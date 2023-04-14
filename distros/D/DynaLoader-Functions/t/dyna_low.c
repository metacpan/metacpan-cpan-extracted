#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define Q_PERL_VERSION_DECIMAL(r,v,s) ((r)*1000000 + (v)*1000 + (s))
#define Q_PERL_DECIMAL_VERSION \
	Q_PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define Q_PERL_VERSION_GE(r,v,s) \
	(Q_PERL_DECIMAL_VERSION >= Q_PERL_VERSION_DECIMAL(r,v,s))
#define Q_PERL_VERSION_LT(r,v,s) \
	(Q_PERL_DECIMAL_VERSION < Q_PERL_VERSION_DECIMAL(r,v,s))

#if (Q_PERL_VERSION_GE(5,17,6) && Q_PERL_VERSION_LT(5,17,11)) || \
	(Q_PERL_VERSION_GE(5,19,3) && Q_PERL_VERSION_LT(5,21,1))
PERL_STATIC_INLINE void suppress_unused_warning(void)
{
	(void) S_croak_memory_wrap;
}
#endif /* (>=5.17.6 && <5.17.11) || (>=5.19.3 && <5.21.1) */

#if defined(WIN32) && Q_PERL_VERSION_GE(5,13,6)
# define Q_BASE_CALLCONV EXTERN_C
#else /* !(WIN32 && >= 5.13.6) */
# define Q_BASE_CALLCONV PERL_CALLCONV
#endif /* !(WIN32 && >= 5.13.6) */

#define Q_EXPORT_CALLCONV Q_BASE_CALLCONV

Q_EXPORT_CALLCONV int dynalow_foo(void)
{
	return 42;
}

Q_EXPORT_CALLCONV int dynalow_bar(void)
{
	return 69;
}

/* this is necessary for building on some platforms */
Q_EXPORT_CALLCONV int boot_t__dyna_low(void)
{
	return 666;
}
