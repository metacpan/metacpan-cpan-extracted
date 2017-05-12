#include "perl_extractor.h"

SV *
perl_extractor_new_sv_from_ptr (void *ptr, const char *class) {
	SV *obj, *sv;
	HV *stash;

	obj = (SV *)newHV ();
	sv_magic (obj, 0, PERL_MAGIC_ext, (const char *)ptr, 0);

	sv = newRV_noinc (obj);
	stash = gv_stashpv (class, 0);
	sv_bless (sv, stash);

	return sv;
}

void *
perl_extractor_get_ptr_from_sv (SV *sv, const char *class) {
	MAGIC *mg;

	if (!sv || !SvOK (sv) || !SvROK (sv)
	 || SvTYPE (SvRV (sv)) != SVt_PVHV
	 || (class && !sv_derived_from (sv, class))
	 || !(mg = mg_find (SvRV (sv), PERL_MAGIC_ext))) {
		croak ("invalid object");
	}

	if (perl_extractor_object_is_invalid (sv)) {
		croak ("You used the instance methods loadConfigLibraries, addLibrary, "
		       "addLibraryLast or removeLibrary to create a new extractor from "
		       "an existing one. This automatically invalidates the old object "
		       "and you will need to use the return value of the above methods "
		       "to call any any method on them.");
	}

	return (void *)mg->mg_ptr;
}

SV *
perl_extractor_keyword_type_to_sv (EXTRACTOR_KeywordType type) {
	SV *ret;

	ret = newSVpv (EXTRACTOR_getKeywordTypeAsString (type), 0);

	return ret;
}

char *
perl_extractor_slurp_from_handle (SV *handle, STRLEN *len) {
	char *ret;
	SV *sv;
	PerlIO *io;
	int got;
	char buf[4096];

	io = IoIFP (sv_2io (handle));
	sv = sv_2mortal (newSVpv ("", 0));

	while ((got = PerlIO_read (io, &buf, sizeof (buf))) > 0) {
		sv_catpvn (sv, (const char *)&buf, got);
	}

	ret = SvPV (sv, *len);

	return ret;
}

void
perl_extractor_invalidate_object (SV *obj) {
	HV *hv;

	hv = (HV *)SvRV (obj);
	if (!hv_stores (hv, PERL_EXTRACTOR_INVALIDED, &PL_sv_yes)) {
		croak ("failed to store invalidation flag");
	}
}

bool
perl_extractor_object_is_invalid (SV *obj) {
	HV *hv;
	SV **val;

	if (!obj || !SvOK (obj) || !SvROK (obj)
	 || SvTYPE (SvRV (obj)) != SVt_PVHV
	 || !mg_find (SvRV (obj), PERL_MAGIC_ext)) {
		croak ("invalid object");
	}

	hv = (HV *)SvRV (obj);
	val = hv_fetchs (hv, PERL_EXTRACTOR_INVALIDED, 0);

	if (!val || !*val) {
		return 0;
	}

	return SvTRUE (*val);
}
