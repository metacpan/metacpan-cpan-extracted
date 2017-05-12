/* -*- c -*- */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#include <stdio.h>
#include <string.h>

#include "ppport.h"

// Hack to work around "error: declaration of 'Perl___notused' has a different
// language linkage" error on Clang
#ifdef dNOOP
# undef dNOOP
# define dNOOP
#endif

#include "encodings/compact_lang_det/compact_lang_det.h"
#include "encodings/compact_lang_det/ext_lang_enc.h"
#include "encodings/compact_lang_det/unittest_data.h"
#include "encodings/proto/encodings.pb.h"

MODULE = Lingua::Identify::CLD		PACKAGE = Lingua::Identify::CLD

const char*
_identify(src, tld_hint, plain, extended, id, percent, is_reliable_int)
   const char* src
   const char* tld_hint
   int plain
   int extended
   const char* id
   int percent
   int is_reliable_int
  CODE:
    int src_length;
    bool is_plain_text = plain ? true : false;
    bool allow_extended_languages = extended ? true : false;
    bool pick_summary_language = false;
    bool remove_weak_matches = false;
    int encoding_hint = UNKNOWN_ENCODING;
    Language language_hint = UNKNOWN_LANGUAGE;

    double normalized_score3[3];
    Language language3[3];
    int percent3[3];

    int text_bytes;
    bool is_reliable;
   
    src_length = strlen(src);
    if (!strlen(tld_hint))
        tld_hint = NULL;

    if (0) {
       fprintf(stderr, "Text is >%s<\n", src);
       fprintf(stderr, "Text length is >%d<\n", src_length);
       fprintf(stderr, "is_plain_text is >%d<\n", is_plain_text);
       fprintf(stderr, "allow_extended_languages is >%d<\n", allow_extended_languages);
       fprintf(stderr, "pick_summary_language is >%d<\n", pick_summary_language);
       fprintf(stderr, "remove_weak_matches is >%d<\n", remove_weak_matches);
       if (!tld_hint) 
           fprintf(stderr, "tld_hint is null\n");
       else
           fprintf(stderr, "tld_hint is >%s<\n", tld_hint);
       fprintf(stderr, "encoding_hint is >%d<\n", encoding_hint);
       fprintf(stderr, "language_hint is >%d<\n", language_hint);
       fprintf(stderr, "\n\n\n");
    }

    Language l = CompactLangDet::DetectLanguage(0,
                                                src,
                                                src_length,
                                                is_plain_text,
                                                allow_extended_languages,
                                                pick_summary_language,
                                                remove_weak_matches,
                                                tld_hint,
                                                encoding_hint,
                                                language_hint,
                                                language3,
                                                percent3,
                                                normalized_score3,
                                                &text_bytes,
                                                &is_reliable);

    is_reliable_int = is_reliable;
    id = LanguageCodeWithDialects(l);
    percent = percent3[0];

    RETVAL = LanguageName(l);
  OUTPUT:
    RETVAL
    id
    percent
    is_reliable_int
