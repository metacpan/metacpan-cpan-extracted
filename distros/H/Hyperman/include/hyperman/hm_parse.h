#ifndef HM_PARSE_H
#define HM_PARSE_H

/* Pure-C HTTP/1 request-framing helpers, with no Perl dependency, so they can
 * be unit-tested and fuzzed standalone (see tools/fuzz/). Included by
 * hm_core.h; the SV/HV-building parser (hm_build_env) stays there.
 *
 * These decide how a request body is framed and decode chunked bodies, and are
 * the security-critical, attacker-controlled path - hardened against request
 * smuggling (RFC 7230 3.3.3) and fuzzed for memory safety. */

#include <stddef.h>
#include <string.h>
#include <limits.h>    /* LONG_MAX, ULLONG_MAX */

/* Case-insensitive compare. POSIX puts it in <strings.h>; MSVC has no such
 * header at all and MinGW's is a thin inline over the CRT's _strnicmp, so we
 * name the CRT call directly there. Prefixed rather than #defined over the
 * system name: perl.h and the platform headers are already in this
 * translation unit, and redefining an ambient symbol they may have declared
 * is the mistake Eshu spent three releases undoing. This file stays
 * dependency-free (tools/fuzz/ compiles it alone), so the shim lives here
 * and not in hm_win.h. */
#ifdef _WIN32
#  define hm_strncasecmp(a, b, n) _strnicmp((a), (b), (n))
#else
#  include <strings.h>
#  define hm_strncasecmp(a, b, n) strncasecmp((a), (b), (n))
#endif

/* One parsed header line: name at head+off (klen bytes), value at head+voff
 * (vlen bytes, leading OWS trimmed; trailing OWS kept, matching what the env
 * builder has always exposed). Only lines with a non-empty name before a
 * colon are recorded - the same lines the env builder consumes. */
typedef struct { unsigned off, klen, voff, vlen; } hm_hline;

/* Single pass over the header block: decide how the request body is framed
 * (hardened against request smuggling, RFC 7230 3.3.3) and, when idx is
 * given, record every header line so the env builder never rescans.
 *
 *   - Transfer-Encoding: "chunked" is decoded (signalled by *clen = -1); any
 *     other coding is 501; a repeated Transfer-Encoding, or Transfer-Encoding
 *     together with Content-Length, is the classic TE.CL / CL.TE smuggling
 *     vector and is rejected 400.
 *   - Content-Length must appear at most once and be a single run of ASCII
 *     digits (no sign, no spaces, no trailing junk, no overflow); a duplicate,
 *     conflicting, or malformed value is 400.
 *
 * Returns 0 and sets *clen (>= 0 for a fixed length, -1 for chunked); an HTTP
 * error status (400/501) to reject the request; or -2 when idx was too small,
 * with *nlines set to the count needed (rejection takes precedence). */
static int hm_parse_index(const char *head, size_t headlen, long *clen,
                          hm_hline *idx, int idx_cap, int *nlines) {
    const char *line_end = (const char *)memchr(head, '\r', headlen);
    const char *p = line_end ? line_end + 2 : head + headlen;  /* skip req line */
    const char *hend = head + headlen;
    int seen_cl = 0, seen_te = 0, chunked = 0, n = 0;
    long cl = 0;
    while (p < hend) {
        const char *eol = (const char *)memchr(p, '\r', hend - p);
        size_t len = eol ? (size_t)(eol - p) : (size_t)(hend - p);
        const char *colon = (const char *)memchr(p, ':', len);
        if (colon && colon > p) {
            size_t nk = (size_t)(colon - p);
            const char *v = colon + 1, *vend = p + len;
            while (v < vend && (*v == ' ' || *v == '\t')) v++;
            if (idx && n < idx_cap) {
                idx[n].off  = (unsigned)(p - head);
                idx[n].klen = (unsigned)nk;
                idx[n].voff = (unsigned)(v - head);
                idx[n].vlen = (unsigned)(vend - v);
            }
            n++;
            if (nk == 17 && hm_strncasecmp(p, "Transfer-Encoding", 17) == 0) {
                const char *tvend = vend;
                while (tvend > v && (tvend[-1] == ' ' || tvend[-1] == '\t')) tvend--;
                if (seen_te) return 400;             /* repeated TE: ambiguous */
                seen_te = 1;
                if ((size_t)(tvend - v) == 7 && hm_strncasecmp(v, "chunked", 7) == 0)
                    chunked = 1;
                else
                    return 501;                      /* unsupported coding */
            } else if (nk == 14 && hm_strncasecmp(p, "Content-Length", 14) == 0) {
                const char *d, *dvend = vend;
                while (dvend > v && (dvend[-1] == ' ' || dvend[-1] == '\t')) dvend--;
                if (seen_cl || v == dvend) return 400;  /* duplicate or empty */
                seen_cl = 1;
                for (d = v; d < dvend; d++) {
                    if (*d < '0' || *d > '9') return 400;             /* non-digit */
                    if (cl > (LONG_MAX - (*d - '0')) / 10) return 400; /* overflow */
                    cl = cl * 10 + (*d - '0');
                }
            }
        }
        p = eol ? eol + 2 : hend;
    }
    if (seen_te && seen_cl) return 400;    /* TE + CL together: smuggling */
    if (nlines) *nlines = n;
    if (idx && n > idx_cap) return -2;
    *clen = chunked ? -1 : cl;
    return 0;
}

/* Framing decision alone (no line index) - the fuzzer's entry point. */
static int hm_frame_length(const char *head, size_t headlen, long *clen) {
    return hm_parse_index(head, headlen, clen, NULL, 0, NULL);
}

/* Validate a chunked request body in buf[0..avail) WITHOUT mutating it (so an
 * incomplete body can be re-checked as more bytes arrive). On a complete body
 * set *encoded (input octets through the terminating CRLF) and *decoded (total
 * data octets) and return 1; return 0 if more input is needed, -1 if
 * malformed, and HM_CHUNKED_TOOBIG if the decoded size would exceed max.
 *
 * "Too large" is a separate answer from "malformed" because they are
 * different answers to the CLIENT: 400 says your framing is broken and
 * retrying identically is pointless, 413 says the framing was fine and you
 * should send less. Folding them together (as this did before 0.25) told
 * every oversize chunked upload to go and fix its syntax. */
#define HM_CHUNKED_TOOBIG (-2)
static int hm_chunked_scan(const char *buf, size_t avail,
                           size_t *encoded, size_t *decoded, size_t max) {
    size_t pos = 0, dec = 0;
    for (;;) {
        size_t i = pos;
        unsigned long long size = 0;
        int ndig = 0;
        while (i < avail && buf[i] != '\r' && buf[i] != ';') {
            int ch = (unsigned char)buf[i], v;
            if      (ch >= '0' && ch <= '9') v = ch - '0';
            else if (ch >= 'a' && ch <= 'f') v = ch - 'a' + 10;
            else if (ch >= 'A' && ch <= 'F') v = ch - 'A' + 10;
            else return -1;                              /* bad hex digit */
            if (size > (ULLONG_MAX >> 4)) return -1;     /* size overflow */
            size = (size << 4) | (unsigned)v;
            ndig++; i++;
        }
        if (ndig == 0) return -1;                        /* missing chunk-size */
        while (i < avail && buf[i] != '\r') i++;         /* skip chunk-ext */
        if (i + 1 >= avail) return 0;
        if (buf[i] != '\r' || buf[i + 1] != '\n') return -1;
        i += 2;
        if (size == 0) {                                 /* last-chunk + trailers */
            for (;;) {
                size_t j = i;
                while (j < avail && buf[j] != '\r') j++;
                if (j + 1 >= avail) return 0;
                if (buf[j] != '\r' || buf[j + 1] != '\n') return -1;
                if (j == i) { *encoded = j + 2; *decoded = dec; return 1; }
                i = j + 2;                               /* skip a trailer line */
            }
        }
        if (size > max || dec + size > max) return HM_CHUNKED_TOOBIG;
        if (i + size + 2 > avail) return 0;              /* await chunk + CRLF */
        if (buf[i + size] != '\r' || buf[i + size + 1] != '\n') return -1;
        dec += (size_t)size;
        pos = i + (size_t)size + 2;
    }
}

/* Compact a chunked body already validated by hm_chunked_scan to its decoded
 * octets at the front of buf; returns the decoded length. Structure is trusted
 * (scan verified every bound over the same, unmodified bytes). */
static size_t hm_chunked_compact(char *buf) {
    size_t pos = 0, w = 0;
    for (;;) {
        size_t i = pos;
        size_t size = 0;
        while (buf[i] != '\r' && buf[i] != ';') {
            int ch = (unsigned char)buf[i];
            size = (size << 4) | (unsigned)(ch <= '9' ? ch - '0' : (ch | 32) - 'a' + 10);
            i++;
        }
        while (buf[i] != '\r') i++;
        i += 2;
        if (size == 0) return w;
        memmove(buf + w, buf + i, size);
        w += size;
        pos = i + size + 2;
    }
}

#endif
