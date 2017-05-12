#include <stdio.h>
#include "myconversions.h"
#include <encodings.h>

using namespace CLD2;


HV *
resultchunk_to_hash(pTHX_ const ResultChunk &rc)
{
  HV *hv = newHV();

  hv_stores(hv, "offset", newSViv(rc.offset));
  hv_stores(hv, "bytes", newSViv(rc.bytes));
  hv_stores(hv, "lang1", newSVuv(rc.lang1));
  const char *ln = CLD2::LanguageName((CLD2::Language)rc.lang1);
  hv_stores(hv, "lang1_str", newSVpv(ln, 0));
  hv_stores(hv, "pad", newSVuv(rc.pad));

  return hv;
}

AV *
resultchunk_vector_to_array(pTHX_ const ResultChunkVector &rcv)
{
  AV *av = newAV();

  const unsigned int n = rcv.size();
  for (unsigned int i = 0; i < n; ++i) {
    HV *hv = resultchunk_to_hash(aTHX_ rcv[i]);
    av_push(av, newRV_noinc((SV *)hv));
  }

  return av;
}

HV*
language_to_hash(CLD2::Language language, int percent, double score) {
    HV *hv = newHV();
    hv_stores(hv, "language_code", newSVpv(CLD2::LanguageCode(language), 0));
    hv_stores(hv, "percent", newSViv(percent));
    hv_stores(hv, "score", newSViv(score));
    return hv;
}

AV*
languages_to_array(CLD2::Language languages[3], int percent[3], double score[3]) {
    AV* av = newAV();
    for (int i = 0; i < 3; ++i) {
        if (languages[i] == UNKNOWN_LANGUAGE) {
            continue;
        }
        av_push(av, newRV_noinc((SV *)language_to_hash(languages[i], percent[i], score[i])));
    }
    return av;
}

CLD2::Language
scalar_to_language(SV* lang) {
    char* lang_string = SvPOK(lang) ? SvPV_nolen(lang) : NULL;
    if (lang_string) {
        return CLD2::GetLanguageFromName(lang_string);
    } else if (SvIOK(lang)) {
        return (CLD2::Language)SvIV(lang);
    } else {
        return (CLD2::Language)0;
    }
}
