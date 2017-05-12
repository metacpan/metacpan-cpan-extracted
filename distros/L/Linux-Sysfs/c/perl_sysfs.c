#include "perl_sysfs.h"

SV*
perl_sysfs_new_sv_from_ptr(void* ptr, const char* class) {
	SV* obj;
	SV* sv;
	HV* stash;

	obj = (SV*)newHV();
	sv_magic(obj, 0, PERL_MAGIC_ext, (const char*)ptr, 0);
	sv = newRV_noinc(obj);
	stash = gv_stashpv(class, 0);
	sv_bless(sv, stash);

	return sv;
}

void*
perl_sysfs_get_ptr_from_sv(SV* sv, const char* class) {
	MAGIC* mg;

	if (!sv || !SvOK(sv) || !SvROK(sv) || !sv_derived_from(sv, class) || !(mg = mg_find(SvRV(sv), PERL_MAGIC_ext)))
		return NULL;

	return (void*)mg->mg_ptr;
}

void
perl_sysfs_call_xs(pTHX_ void (*subaddr) (pTHX_ CV*), CV* cv, SV** mark) {
	dSP;
	PUSHMARK(mark);
	(*subaddr) (aTHX_ cv);
	PUTBACK;
}
