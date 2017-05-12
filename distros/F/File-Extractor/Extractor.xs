#include "perl_extractor.h"

MODULE = File::Extractor	PACKAGE = File::Extractor	PREFIX = EXTRACTOR_

PROTOTYPES: DISABLE

void
EXTRACTOR_getDefaultLibraries (class)
	PREINIT:
		const char *libraries;
		char *copy, *pos, *token;
	PPCODE:
		libraries = EXTRACTOR_getDefaultLibraries ();

		if (!libraries) {
			XSRETURN_EMPTY;
		}

		copy = strdup (libraries);
		pos = copy;

		while ((token = strsep (&pos, ":"))) {
			mXPUSHp (token, strlen (token));
		}

		free (copy);

EXTRACTOR_ExtractorList *
EXTRACTOR_loadDefaultLibraries (class)
	C_ARGS:
		/* void */

EXTRACTOR_ExtractorList *
EXTRACTOR_loadConfigLibraries (prev, config)
		EXTRACTOR_ExtractorList_or_null *prev
		const char *config
	POSTCALL:
		if (prev) {
			perl_extractor_invalidate_object (ST (0));
		}

EXTRACTOR_ExtractorList *
EXTRACTOR_addLibrary (prev, library)
		EXTRACTOR_ExtractorList_or_null *prev
		const char *library
	POSTCALL:
		if (prev) {
			perl_extractor_invalidate_object (ST (0));
		}

EXTRACTOR_ExtractorList *
EXTRACTOR_addLibraryLast (prev, library)
		EXTRACTOR_ExtractorList_or_null *prev
		const char *library
	POSTCALL:
		if (prev) {
			perl_extractor_invalidate_object (ST (0));
		}

EXTRACTOR_ExtractorList *
EXTRACTOR_removeLibrary (prev, library)
		EXTRACTOR_ExtractorList *prev
		const char *library
	POSTCALL:
		perl_extractor_invalidate_object (ST (0));

void
EXTRACTOR_getKeywords (extractor, data)
		EXTRACTOR_ExtractorList *extractor
		SV *data
	PREINIT:
		STRLEN len;
		char *buf;
		EXTRACTOR_KeywordList *list, *i;
	PPCODE:
		if (SvROK (data) && (SvTYPE (SvRV (data)) == SVt_PVGV)) {
			buf = perl_extractor_slurp_from_handle (data, &len);
		}
		else {
			buf = SvPVbyte (data, len);
		}

		list = EXTRACTOR_getKeywords2 (extractor, buf, len);
		list = EXTRACTOR_removeEmptyKeywords (list);
		list = EXTRACTOR_removeDuplicateKeywords (list, 0);

		if (!list) {
			XSRETURN_EMPTY;
		}

		for (i = list; i; i = i->next) {
			EXTEND (sp, 2);
			PUSHs (perl_extractor_keyword_type_to_sv (i->keywordType));
			PUSHs (newSVpv (i->keyword, 0));
		}

		EXTRACTOR_freeKeywords (list);

void
DESTROY (libraries)
		EXTRACTOR_ExtractorList *libraries = perl_extractor_object_is_invalid ($arg) ? NULL : ($type)perl_extractor_get_ptr_from_sv ($arg, "File::Extractor");
	CODE:
		if (libraries) {
			EXTRACTOR_removeAll (libraries);
		}
