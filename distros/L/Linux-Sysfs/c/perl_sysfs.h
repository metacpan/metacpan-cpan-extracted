#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "sysfs/libsysfs.h"

void perl_sysfs_call_xs(pTHX_ void (*subaddr) (pTHX_ CV* cv), CV* cv, SV** mark);

SV* perl_sysfs_new_sv_from_ptr(void* ptr, const char* class);

void* perl_sysfs_get_ptr_from_sv(SV* sv, const char* class);


#define PERL_SYSFS_BOOT(name)						\
	{												\
		extern XS(name);							\
		perl_sysfs_call_xs(aTHX_ name, cv, mark);	\
	}
