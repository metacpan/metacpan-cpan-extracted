#ifndef SIMDJSON_DECODE_H
#define SIMDJSON_DECODE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// main JSON struct definition
// also used by main XS code
typedef struct {
  U32 flags;
  U32 max_depth;
  STRLEN max_size;

  SV *cb_object;
  HV *cb_sk_object;

  // for the incremental parser
  SV *incr_text;   // the source text so far
  STRLEN incr_pos; // the current offset into the text
  int incr_nest;   // {[]}-nesting level
  unsigned char incr_mode;

  SV *v_false, *v_true;
} JSON;

// structure used for decoding JSON
// also used by the main XS code
typedef struct
{
  char *cur; // current parser pointer
  char *end; // end of input string
  const char *err; // parse error, if != 0
  JSON json;
  U32 depth; // recursion depth
  U32 maxdepth; // recursion depth limit

  // fields needed for simdjson decoder
  SV *input; // original JSON document, needed because we have to pad it (and for the various SvXXX pointers)
  char *path; // JSON path
  int error_code; // set by simdjson_decoder while parsing, error message will be looked up in the end if != 0
  int error_line_number; // for debug purposes
} dec_t;

// needed by both decoders
SV * filter_object (dec_t *dec, SV *sv, HV* hv);
NV json_atof (const char *s);

// actual interface to simdjson decoder
void simdjson_global_init();
SV* simdjson_decode(dec_t *dec);
SV * simdjson_get_version();

#ifdef __cplusplus
}
#endif

#endif
