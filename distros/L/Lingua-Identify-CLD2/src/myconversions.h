#ifndef MYCONVERSIONS_H_
#define MYCONVERSIONS_H_

#include <compact_lang_det.h>
#include <EXTERN.h>
#include <perl.h>
#include <vector>


HV *resultchunk_to_hash(pTHX_ const CLD2::ResultChunk &rc);

AV *resultchunk_vector_to_array(pTHX_ const CLD2::ResultChunkVector &rcv);

AV* languages_to_array(CLD2::Language languages[3], int percent[3], double score[3]);

CLD2::Language scalar_to_language(SV* lang);

#endif
