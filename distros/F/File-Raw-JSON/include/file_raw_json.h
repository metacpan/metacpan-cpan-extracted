/*
 * include/file_raw_json.h - File::Raw::JSON internal declarations
 *
 * Dist-internal C glue between yyjson and Perl SVs.  JSON.xs and
 * file_raw_json.c both include this.  Not installed - this dist
 * doesn't currently expose a public C ABI to dependents (yyjson is
 * vendored privately for the same reason).
 *
 */

#ifndef FILE_RAW_JSON_H
#define FILE_RAW_JSON_H

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stddef.h>

/* Strawberry / Win32 Perl is built with PERL_IMPLICIT_SYS, which makes
 * iperlsys.h redefine malloc/free/realloc/calloc as 1-arg function-
 * like macros routed through PerlMem_*. yyjson_alc has a struct field
 * named `free` and yyjson.h calls `alc.free(alc.ctx, ptr)` - that
 * macro-expands to PerlMem_free(alc.ctx, ptr), which is wrong-arity
 * and breaks the build with:
 *   "macro 'PerlMem_free' passed 2 arguments, but takes just 1"
 * Undef the four memory macros here so yyjson.h (and our own
 * allocator glue further down in file_raw_json.c) see plain libc
 * symbols. yyjson manages its own arenas; we don't hand any of these
 * allocations off to Perl. */
#undef malloc
#undef free
#undef realloc
#undef calloc

/* PERL_STATIC_INLINE landed in Perl 5.18. Our minimum is 5.010; on
 * 5.10/5.12/5.14/5.16 it isn't defined and file_raw_json.c fails to
 * compile with "expected ';' before 'int'" at the first use site.
 * Fall back to plain `static` - older toolchains may decline to
 * inline, which we don't care about on those Perls. */
#ifndef PERL_STATIC_INLINE
#  define PERL_STATIC_INLINE static
#endif

#include "yyjson.h"

/* ============================================================
 * Mode tag carried by the plugin registration. The 'json' plugin
 * registers with MODE_DOCUMENT (slurp returns a single parsed value).
 * 'jsonl' registers with MODE_LINES (slurp returns AV of values).
 * The 'mode' option overrides this per call.
 * ============================================================ */

typedef enum {
    JSON_MODE_DOCUMENT = 0,
    JSON_MODE_LINES    = 1
} json_mode_t;

/* ============================================================
 * Per-call options. decode_opts() validates an HV into one of these.
 * ============================================================ */

typedef struct {
    json_mode_t  mode;          /* document vs lines */
    int          pretty;        /* 0 / 1 */
    int          indent;        /* 2 or 4 (yyjson constraint) */
    int          sort_keys;     /* 0 / 1 */
    int          canonical;     /* sort_keys + minimal whitespace */
    int          utf8;          /* 1 = bytes are UTF-8 */
    int          relaxed;       /* allow comments + trailing commas (decode) */
    int          allow_nonref;  /* accept top-level scalars */
    int          allow_nan_inf; /* round-trip NaN / Infinity */
    int          ordered;       /* decode JSON objects as Tie::IxHash    */
                                /* HVs so insertion order is preserved   */
                                /* on the Perl side (yyjson already      */
                                /* preserves it; HV randomisation is the */
                                /* thing we're working around).          */
    int          max_depth;     /* nesting cap */
    char         eol[4];        /* JSONL only; "\n" by default */
    int          eol_len;
    /* boolean_class is held as an SV* outside this struct (see XS).  */
} json_options_t;

void json_options_defaults(json_options_t *o);

/* ============================================================
 * JSONL brace-balancer (state machine)
 *
 * Returns the byte range of the next complete top-level JSON value in
 * `buf[0..len)`, or signals NEED_MORE / NO_OPENER. Skips ASCII white-
 * space at the start. *next_pos is the byte index past the matched
 * value (and any trailing whitespace) on FOUND.
 * ============================================================ */

typedef enum {
    JSONL_FOUND     =  1,
    JSONL_NEED_MORE =  0,
    JSONL_NO_OPENER = -1
} jsonl_scan_t;

jsonl_scan_t json_jsonl_next(const char *buf, STRLEN len,
                             STRLEN *out_start, STRLEN *out_end,
                             STRLEN *next_pos);

/* ============================================================
 * Value-mapping (yyjson <-> SV)
 *
 * sv_from_yyjson returns a fresh SV (refcount 1) which the caller
 * should sv_2mortal or pass on. sv_to_yyjson_mut adds a value into
 * `doc`'s mutable arena and returns it (must not outlive `doc`).
 *
 * boolean_stash is the HV* of the class blessed-to for true/false on
 * decode (e.g. File::Raw::JSON::Boolean's stash). May be NULL, in
 * which case decode falls back to plain &PL_sv_yes / &PL_sv_no
 * (legacy mode; almost never desirable).
 * ============================================================ */

/* `max_depth` caps recursion through nested objects/arrays.  Pass
 * INT_MAX (or any large value) to disable.  json_decode_document /
 * json_decode_lines wire opts->max_depth here. */
SV *json_sv_from_yyjson(pTHX_ yyjson_val *val, HV *boolean_stash,
                        int ordered, int max_depth);

/* ============================================================
 * Boolean singletons (defined in JSON.xs)
 *
 * Allocated once at BOOT and marked read-only. When the caller's
 * boolean_stash matches g_frj_default_stash (the default class,
 * File::Raw::JSON::Boolean), make_bool_sv returns the cached
 * singleton with an SvREFCNT_inc instead of allocating a fresh
 * blessed scalar - measurable win on parse-side when a JSON
 * stream contains many booleans.
 * ============================================================ */
extern SV *g_frj_true_sv;
extern SV *g_frj_false_sv;
extern HV *g_frj_default_stash;

yyjson_mut_val *json_sv_to_yyjson(pTHX_ SV *sv, yyjson_mut_doc *doc,
                                  const json_options_t *opts);

/* ============================================================
 * Read / write entry points (used by the XS layer / plugin shims).
 *
 * On error, all four croak with a useful message including byte
 * offset (decode side) or a description of the bad shape (encode).
 * ============================================================ */

/* Decode a single JSON document. Returns SV with refcount 1. */
SV *json_decode_document(pTHX_ const char *bytes, STRLEN len,
                         const json_options_t *opts, HV *boolean_stash);

/* Decode a JSONL stream into AV of values. Returns the AV* (refcount 1). */
AV *json_decode_lines(pTHX_ const char *bytes, STRLEN len,
                      const json_options_t *opts, HV *boolean_stash);

/* Encode any SV to JSON bytes. Returns SV with refcount 1. */
SV *json_encode_document(pTHX_ SV *value, const json_options_t *opts);

/* Encode an AV (each element is one JSONL record) to bytes.
 * Each record is followed by opts->eol. Returns SV with refcount 1.
 * Croaks if `payload` is not an arrayref. */
SV *json_encode_lines(pTHX_ SV *payload, const json_options_t *opts);

#endif /* FILE_RAW_JSON_H */
