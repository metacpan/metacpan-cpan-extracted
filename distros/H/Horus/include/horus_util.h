#ifndef HORUS_UTIL_H
#define HORUS_UTIL_H

/*
 * horus_util.h - UUID utility functions: validate, compare, extract
 */

#include <string.h>
#include <stdint.h>

/* ── Extract version from binary UUID ───────────────────────────── */

static inline int horus_uuid_version_bin(const unsigned char *uuid) {
    return (uuid[6] >> 4) & 0x0F;
}

/* ── Extract variant from binary UUID ───────────────────────────── */

static inline int horus_uuid_variant_bin(const unsigned char *uuid) {
    unsigned char v = uuid[8];
    if ((v & 0x80) == 0)    return 0;  /* NCS backward compatibility */
    if ((v & 0xC0) == 0x80) return 1;  /* RFC 9562 (standard) */
    if ((v & 0xE0) == 0xC0) return 2;  /* Microsoft */
    return 3;                           /* Future/reserved */
}

/* ── Compare two binary UUIDs ───────────────────────────────────── */

static inline int horus_uuid_cmp_bin(const unsigned char *a, const unsigned char *b) {
    return memcmp(a, b, 16);
}

/* ── Check if NIL ───────────────────────────────────────────────── */

static inline int horus_uuid_is_nil_bin(const unsigned char *uuid) {
    /* Optimise with 64-bit comparison */
    const uint64_t *p = (const uint64_t *)uuid;
    return (p[0] == 0) && (p[1] == 0);
}

/* ── Check if MAX ───────────────────────────────────────────────── */

static inline int horus_uuid_is_max_bin(const unsigned char *uuid) {
    const uint64_t *p = (const uint64_t *)uuid;
    return (p[0] == UINT64_C(0xFFFFFFFFFFFFFFFF))
        && (p[1] == UINT64_C(0xFFFFFFFFFFFFFFFF));
}

/* ── Validate a UUID string (any format) ────────────────────────── */

static inline int horus_uuid_validate(const char *input, size_t len) {
    unsigned char tmp[16];
    if (horus_parse_uuid(tmp, input, len) != HORUS_PARSE_OK)
        return 0;
    /* Check that variant is RFC 9562 or it's NIL/MAX */
    if (horus_uuid_is_nil_bin(tmp) || horus_uuid_is_max_bin(tmp))
        return 1;
    return (horus_uuid_variant_bin(tmp) == 1) ? 1 : 0;
}

/* ── Extract timestamp as Unix epoch seconds (NV) ───────────────── */

static inline double horus_uuid_extract_time(const unsigned char *uuid) {
    int version = horus_uuid_version_bin(uuid);
    switch (version) {
        case 1:
            return horus_gregorian_to_unix(horus_extract_time_v1(uuid));
        case 6:
            return horus_gregorian_to_unix(horus_extract_time_v6(uuid));
        case 7:
            return horus_ms_to_unix(horus_extract_time_v7(uuid));
        default:
            return 0.0; /* No timestamp for other versions */
    }
}

#endif /* HORUS_UTIL_H */
