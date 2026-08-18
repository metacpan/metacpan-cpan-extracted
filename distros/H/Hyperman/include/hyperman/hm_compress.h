#ifndef HM_COMPRESS_H
#define HM_COMPRESS_H

/* hm_compress.h - gzip on the way out.
 *
 * Why this layer and not the framework: compression is a property of the
 * write path, and Hyperman serves apps that are not Punk - the
 * openapi-proxy gateway calls Hyperman->run directly and is the heaviest
 * JSON-over-the-wire consumer there is. A framework-level compressor would
 * give the app that needs it most nothing. Hyperman is also the only layer
 * that could ever compress a STREAMED body, since a framework hands
 * psgi.streaming responses off as coderefs and never sees the bytes.
 * (Streaming compression is not in this release; choosing this layer is
 * what leaves the door open.)
 *
 * THE ANTI-COLLISION RULE, which is the whole contract with anything above:
 * we never touch a response that already carries a Content-Encoding. A
 * framework serving precompressed files off disk sets `gzip`; a route that
 * opts out sets `identity`, which we strip before writing. That channel is
 * a plain response header, so it is a contract any PSGI framework can use,
 * not a private arrangement with one of them.
 *
 * Off by default: a server that starts compressing on upgrade is a
 * surprise. `compress => 1` on run() turns it on.
 *
 * Everything is prefixed hz_ / HZ_. Included from hm_core.h after hm_win.h.
 */

#include "hm_parse.h"      /* hm_strncasecmp: header names are case-blind */

#ifdef HM_HAVE_ZLIB
#include <zlib.h>
#endif

/* One MTU. Below this a gzip member's own header and trailer are a
 * meaningful fraction of the payload and the packet count does not change,
 * so there is nothing to win. */
#define HZ_MIN_LENGTH   1400

/* Level 1, not the customary 6, and the number is measured rather than
 * assumed. A 37KB JSON document, 2 workers / 5s / 64 conns on loopback
 * (Punk bench/apps/bare-json40k.psgi, 2026-08-17):
 *
 *     off        130,000 req/s    37.3 KB/req
 *     level 1     66,900 req/s     3.19 KB/req   11.7x smaller, 1.9x slower
 *     level 6     26,300 req/s     2.96 KB/req   12.6x smaller, 4.9x slower
 *
 * Level 6 buys 7% more compression for 2.5x the CPU. On text that repeats -
 * which is what an API payload is - almost all of the win is in the first
 * level, and a worker that is also serving the next request should not pay
 * for the rest of it. `compress_level` on run() overrides for anyone whose
 * bandwidth costs more than their CPU. */
#define HZ_LEVEL        1

/* ---- Accept-Encoding ------------------------------------------------------
 * A left-to-right walk of the header: no split, no hash, no SV. `q=0` is an
 * explicit refusal and loses to nothing; `*` matches anything not separately
 * refused. Runs once per request, on the request path, so it stays a scan. */
static int hz_accepts_gzip(const char *ae, size_t len) {
    size_t i = 0;
    int star = 0;
    if (!ae || !len) return 0;
    while (i < len) {
        size_t start, end, j;
        int refused = 0, is_star, is_gzip;
        while (i < len && (ae[i] == ' ' || ae[i] == '\t' || ae[i] == ',')) i++;
        start = i;
        while (i < len && ae[i] != ',' && ae[i] != ';') i++;
        end = i;
        while (end > start && (ae[end - 1] == ' ' || ae[end - 1] == '\t')) end--;
        if (i < len && ae[i] == ';') {          /* parameters; only q matters */
            size_t ps = i;
            while (i < len && ae[i] != ',') i++;
            for (j = ps; j + 1 < i; j++) {
                if ((ae[j] | 32) != 'q') continue;
                while (j + 1 < i && (ae[j + 1] == ' ' || ae[j + 1] == '=')) j++;
                if (j + 1 < i && ae[j + 1] == '0') {
                    size_t k = j + 2;
                    int nonzero = 0;
                    if (k < i && ae[k] == '.')
                        for (k++; k < i && ae[k] >= '0' && ae[k] <= '9'; k++)
                            if (ae[k] != '0') nonzero = 1;
                    if (!nonzero) refused = 1;   /* q=0, q=0.0, q=0.000 */
                }
                break;
            }
        }
        is_star = (end - start == 1 && ae[start] == '*');
        is_gzip = (end - start == 4
                   && hm_strncasecmp(ae + start, "gzip", 4) == 0);
        if (is_gzip) return !refused;            /* named: it decides */
        if (is_star && !refused) star = 1;
    }
    return star;
}

/* ---- the compressible-type allowlist --------------------------------------
 * An allowlist, not a denylist: a new binary media type must not become
 * compressible by default just because nobody thought to exclude it. The
 * match is on the type up to any ';charset=...' parameter. */
static int hz_type_ok(const char *ct, size_t len) {
    static const char *const HZ_TYPES[] = {
        "text/",                    /* prefix match: html, css, plain, ... */
        "application/json",
        "application/javascript",
        "application/xml",
        "application/x-ndjson",
        "application/manifest+json",
        "image/svg+xml",
        NULL
    };
    size_t i, n = len;
    int k;
    if (!ct || !len) return 0;
    for (i = 0; i < len; i++)
        if (ct[i] == ';') { n = i; break; }
    while (n && (ct[n - 1] == ' ' || ct[n - 1] == '\t')) n--;

    for (k = 0; HZ_TYPES[k]; k++) {
        size_t tl = strlen(HZ_TYPES[k]);
        if (HZ_TYPES[k][tl - 1] == '/') {        /* prefix form */
            if (n >= tl && hm_strncasecmp(ct, HZ_TYPES[k], tl) == 0) return 1;
        } else if (n == tl && hm_strncasecmp(ct, HZ_TYPES[k], tl) == 0) {
            return 1;
        }
    }
    /* the structured-suffix families: anything +json or +xml */
    if (n > 5 && hm_strncasecmp(ct + n - 5, "+json", 5) == 0) return 1;
    if (n > 4 && hm_strncasecmp(ct + n - 4, "+xml", 4) == 0) return 1;
    return 0;
}

/* ---- the compressor -------------------------------------------------------
 * Deflate src into a freshly allocated buffer with a gzip wrapper
 * (windowBits 15 or 16). Returns 1 with the out and olen params owned by
 * the caller
 * (Safefree), or 0 - without zlib, on any error, or when the result is not
 * SMALLER than the input. An incompressible body must go out identity, not
 * larger: a client that asked for gzip and received more bytes than the
 * plain form would have cost is strictly worse off. */
static int hz_gzip(const char *src, size_t len, int level,
                   char **out, size_t *olen) {
#ifdef HM_HAVE_ZLIB
    z_stream s;
    uLong bound;
    char *buf;

    if (!src || !len) return 0;
    memset(&s, 0, sizeof s);
    if (deflateInit2(&s, level, Z_DEFLATED, 15 | 16, 8,
                     Z_DEFAULT_STRATEGY) != Z_OK)
        return 0;
    bound = deflateBound(&s, (uLong)len) + 18;   /* + gzip header/trailer */
    Newx(buf, (size_t)bound, char);
    s.next_in   = (Bytef *)(void *)src;
    s.avail_in  = (uInt)len;
    s.next_out  = (Bytef *)buf;
    s.avail_out = (uInt)bound;
    if (deflate(&s, Z_FINISH) != Z_STREAM_END) {
        deflateEnd(&s);
        Safefree(buf);
        return 0;
    }
    *olen = (size_t)s.total_out;
    deflateEnd(&s);
    if (*olen >= len) { Safefree(buf); return 0; }   /* not worth it */
    *out = buf;
    return 1;
#else
    (void)src; (void)len; (void)level; (void)out; (void)olen;
    return 0;
#endif
}

static int hz_available(void) {
#ifdef HM_HAVE_ZLIB
    return 1;
#else
    return 0;
#endif
}

#endif /* HM_COMPRESS_H */
