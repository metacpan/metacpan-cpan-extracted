#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "threads1_callchecker0.h"
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

#if Q_PERL_VERSION_LT(5,7,2)
# undef dNOOP
# define dNOOP extern int Perl___notused_func(void)
#endif /* <5.7.2 */

MODULE = t::threads1 PACKAGE = t::threads1

PROTOTYPES: DISABLE

void
cv_set_call_checker_proto(CV *pcv, SV *proto)
PROTOTYPE: $$
CODE:
	if (SvROK(proto))
		proto = SvRV(proto);
	cv_set_call_checker(pcv, Perl_ck_entersub_args_proto, proto);
