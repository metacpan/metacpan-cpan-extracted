#ifndef HORUS_CORE_H
#define HORUS_CORE_H

/*
 * horus_core.h - Pure C UUID library header (no Perl dependencies)
 *
 * This is the reusable entry point for any C or XS project that needs
 * UUID generation. It has ZERO Perl/XS dependencies.
 *
 * Usage from another XS module:
 *
 *     // In your .xs or .h file:
 *     #define HORUS_FATAL(msg) croak("%s", (msg))   // optional: Perl error handling
 *     #include "horus_core.h"
 *
 * Usage from plain C:
 *
 *     #include "horus_core.h"
 *     // HORUS_FATAL defaults to fprintf(stderr,...) + abort()
 *
 * Build: add -I/path/to/Horus/include to your compiler flags.
 */

#include <stdint.h>
#include <string.h>

/* ── Well-known namespace UUIDs (RFC 9562 Appendix A) ───────────── */

static const unsigned char HORUS_NS_DNS[16] = {
    0x6b, 0xa7, 0xb8, 0x10, 0x9d, 0xad, 0x11, 0xd1,
    0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8
};

static const unsigned char HORUS_NS_URL[16] = {
    0x6b, 0xa7, 0xb8, 0x11, 0x9d, 0xad, 0x11, 0xd1,
    0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8
};

static const unsigned char HORUS_NS_OID[16] = {
    0x6b, 0xa7, 0xb8, 0x12, 0x9d, 0xad, 0x11, 0xd1,
    0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8
};

static const unsigned char HORUS_NS_X500[16] = {
    0x6b, 0xa7, 0xb8, 0x14, 0x9d, 0xad, 0x11, 0xd1,
    0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8
};

/* ── Sub-headers (all pure C) ───────────────────────────────────── */

#include "horus_random.h"
#include "horus_time.h"
#include "horus_md5.h"
#include "horus_sha1.h"
#include "horus_encode.h"
#include "horus_format.h"
#include "horus_uuid.h"
#include "horus_parse.h"
#include "horus_util.h"

#endif /* HORUS_CORE_H */
