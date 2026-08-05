#ifndef FRJ_ABI_H
#define FRJ_ABI_H

/* Public C ABI for File::Raw::JSON (the provider) and its XS consumers (e.g.
 * Hyperman, which decodes JSON request bodies on the worker hot path). It is
 * resolved at RUNTIME via File::Raw::JSON::_abi_ptr - a DBI-style versioned
 * function-pointer table - so there is no link-time symbol coupling and each
 * dist builds and upgrades independently. A consumer reaches this header through
 * ExtUtils::Depends (no copying) and checks abi_version at boot; a mismatch
 * means "fall back", never a crash.
 *
 * The point: parse/serialise JSON entirely in C, with no per-call Perl codec
 * dispatch (file_json_decode / file_json_encode).
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, AV, STRLEN and pTHX are defined. */

#define FRJ_ABI_VERSION 1

/* Decode/encode options - the consumer-relevant subset of File::Raw::JSON's
 * per-call options. Fill with opts_init() (or pass NULL to a call) for the
 * File::Raw::JSON defaults, then set what you need. A field left 0 means "off"
 * except indent/max_depth, where 0 means "keep the default" (2 and 512). */
typedef struct frj_opts {
    int utf8;           /* bytes are UTF-8 (default on)                    */
    int ordered;        /* decode JSON objects into ordered hashes         */
    int relaxed;        /* decode: allow comments + trailing commas        */
    int allow_nonref;   /* accept top-level scalars (default on)           */
    int allow_nan_inf;  /* round-trip NaN / Infinity                       */
    int max_depth;      /* nesting cap; 0 => default (512)                 */
    int pretty;         /* encode: pretty-print                            */
    int indent;         /* encode: 2 or 4; 0 => default (2)                */
    int sort_keys;      /* encode: sort object keys                        */
    int canonical;      /* encode: canonical form (sorted, minimal ws)     */
} frj_opts;

typedef struct frj_abi {
    int abi_version;                 /* == FRJ_ABI_VERSION */

    /* Fill *o with the File::Raw::JSON defaults. Call this, then override the
     * fields you care about; keeps a consumer forward-compatible if new option
     * fields are added in a later ABI revision. */
    void (*opts_init)(frj_opts *o);

    /* Decode JSON bytes into a Perl value. Returns an SV with refcount 1 owned
     * by the caller (sv_2mortal it or pass it on). `o` may be NULL for defaults.
     * Croaks on malformed input with a byte-offset message. */
    SV *(*decode)(pTHX_ const char *bytes, STRLEN len, const frj_opts *o);

    /* Decode a JSONL / NDJSON stream into an AV of values (refcount 1, owned). */
    AV *(*decode_lines)(pTHX_ const char *bytes, STRLEN len, const frj_opts *o);

    /* Encode any Perl value into JSON bytes. Returns an SV with refcount 1
     * (owned). Croaks on an unencodable shape. */
    SV *(*encode)(pTHX_ SV *value, const frj_opts *o);

    /* Encode an arrayref (one element per record) into JSONL bytes, each record
     * followed by "\n". Returns an SV with refcount 1 (owned); croaks unless
     * `payload` is an arrayref. */
    SV *(*encode_lines)(pTHX_ SV *payload, const frj_opts *o);
} frj_abi;

#endif /* FRJ_ABI_H */
