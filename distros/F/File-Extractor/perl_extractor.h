#ifndef __PERL_EXTRACTOR_H__
#define __PERL_EXTRACTOR_H__

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <proto.h>

#define NEED_sv_2pvbyte
#define NEED_newRV_noinc
#include "ppport.h"

#include <string.h>
#include <extractor.h>

#define EXTRACTOR_ExtractorList_or_null EXTRACTOR_ExtractorList

#define PERL_EXTRACTOR_INVALIDED "invalidated"

START_EXTERN_C

SV *perl_extractor_new_sv_from_ptr (void *ptr, const char *class);

void *perl_extractor_get_ptr_from_sv (SV *sv, const char *class);

SV *perl_extractor_keyword_type_to_sv (EXTRACTOR_KeywordType type);

char *perl_extractor_slurp_from_handle (SV *handle, STRLEN *len);

void perl_extractor_invalidate_object (SV *obj);

bool perl_extractor_object_is_invalid (SV *obj);

END_EXTERN_C

#endif
