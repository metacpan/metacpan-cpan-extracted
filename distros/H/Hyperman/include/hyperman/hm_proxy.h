#ifndef HM_PROXY_H
#define HM_PROXY_H

/* The PROXY protocol (HAProxy's, v1 and v2), parsed off the first bytes of a
 * connection on a listener that asked for it. Perl-free, like hm_parse.h, so
 * it can be fuzzed standalone (tools/fuzz/fuzz_proxy.c) and driven from C by
 * the selftest below.
 *
 * The contract with the caller (hm_proxy_readable in hm_core.h): the caller
 * PEEKS at the socket, hands the prefix here, and only when this returns a
 * complete length does it read exactly that many bytes. So the parser never
 * sees more than one header, and the bytes behind the header - a ClientHello,
 * an h2 preface, a request line - are never taken off the socket by it. */

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#ifdef _WIN32
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <sys/socket.h>
#endif

/* v1 is one text line of at most 107 bytes including its CRLF (the spec's
 * figure); v2 is a 16-byte fixed header plus an address block and TLVs, and
 * anything over this ceiling is refused rather than buffered. */
#define HM_PP_V1_MAX 107
#define HM_PP_MAX    4096

typedef struct {
    int           family;      /* AF_INET, AF_INET6, or 0 = keep the accepted peer */
    unsigned char src[16];     /* the client's address, in network order        */
    int           src_port;
} hm_pp_result;

static const unsigned char hm_pp_v2_sig[12] =
    { 0x0d, 0x0a, 0x0d, 0x0a, 0x00, 0x0d, 0x0a, 0x51, 0x55, 0x49, 0x54, 0x0a };

/* digits only, 0..65535 */
static int hm_pp_port(const char *s, size_t n, int *out) {
    size_t i;
    long v = 0;
    if (n == 0 || n > 5) return -1;
    for (i = 0; i < n; i++) {
        if (s[i] < '0' || s[i] > '9') return -1;
        v = v * 10 + (s[i] - '0');
    }
    if (v > 65535) return -1;
    *out = (int)v;
    return 0;
}

/* One token up to the next space (or the end), into a NUL-terminated buffer. */
static size_t hm_pp_tok(const char *p, size_t n, char *out, size_t cap) {
    size_t i = 0;
    while (i < n && p[i] != ' ') i++;
    if (i == 0 || i >= cap) return 0;
    memcpy(out, p, i);
    out[i] = '\0';
    return i;
}

/* Returns the header's length when it is complete and valid, 0 when more
 * bytes are needed, -1 when the bytes cannot be a PROXY header. */
static long hm_pp_parse(const unsigned char *p, size_t n, hm_pp_result *out) {
    out->family = 0;
    out->src_port = 0;
    if (n == 0) return 0;

    /* ---- v2: the binary signature ------------------------------------- */
    if (n >= 1 && p[0] == 0x0d) {
        size_t cmp = n < 12 ? n : 12;
        if (memcmp(p, hm_pp_v2_sig, cmp) != 0) {
            /* a bare CR starts no v1 line either */
            return -1;
        }
        if (n < 16) return 0;
        {
            unsigned ver_cmd = p[12], fam_proto = p[13];
            size_t len = ((size_t)p[14] << 8) | p[15];
            size_t total = 16 + len;
            if ((ver_cmd >> 4) != 2) return -1;            /* not version 2 */
            if ((ver_cmd & 0x0f) > 1) return -1;           /* LOCAL or PROXY */
            if (total > HM_PP_MAX) return -1;
            if (n < total) return 0;
            if ((ver_cmd & 0x0f) == 0) return (long)total; /* LOCAL: keep peer */
            if (fam_proto == 0x11) {                       /* TCP over IPv4 */
                if (len < 12) return -1;
                out->family = AF_INET;
                memcpy(out->src, p + 16, 4);
                out->src_port = (p[24] << 8) | p[25];
            } else if (fam_proto == 0x21) {                /* TCP over IPv6 */
                if (len < 36) return -1;
                out->family = AF_INET6;
                memcpy(out->src, p + 16, 16);
                out->src_port = (p[48] << 8) | p[49];
            }
            /* UNSPEC, UDP, UNIX: the peer stays what accept said; TLVs are
             * skipped by the length */
            return (long)total;
        }
    }

    /* ---- v1: "PROXY TCP4|TCP6|UNKNOWN src dst sport dport\r\n" ----------- */
    {
        static const char pfx[] = "PROXY ";
        size_t cmp = n < 6 ? n : 6;
        const unsigned char *eol;
        size_t linelen, i;
        char fam[8], a1[48], a2[48], p1[8], p2[8];
        size_t l;
        if (memcmp(p, pfx, cmp) != 0) return -1;
        if (n < 6) return 0;
        eol = NULL;
        for (i = 0; i + 1 < n && i + 1 < HM_PP_V1_MAX; i++)
            if (p[i] == '\r' && p[i + 1] == '\n') { eol = p + i; break; }
        if (!eol) return n >= HM_PP_V1_MAX ? -1 : 0;   /* no CRLF within 107 */
        linelen = (size_t)(eol - p) + 2;
        /* the five tokens after "PROXY " */
        {
            const char *q = (const char *)p + 6, *end = (const char *)eol;
            if (!(l = hm_pp_tok(q, (size_t)(end - q), fam, sizeof fam))) return -1;
            q += l;
            if (strcmp(fam, "UNKNOWN") == 0) return (long)linelen;   /* keep peer */
            if (strcmp(fam, "TCP4") != 0 && strcmp(fam, "TCP6") != 0) return -1;
            if (q >= end || *q != ' ') return -1; q++;
            if (!(l = hm_pp_tok(q, (size_t)(end - q), a1, sizeof a1))) return -1; q += l;
            if (q >= end || *q != ' ') return -1; q++;
            if (!(l = hm_pp_tok(q, (size_t)(end - q), a2, sizeof a2))) return -1; q += l;
            if (q >= end || *q != ' ') return -1; q++;
            if (!(l = hm_pp_tok(q, (size_t)(end - q), p1, sizeof p1))) return -1; q += l;
            if (q >= end || *q != ' ') return -1; q++;
            if (!(l = hm_pp_tok(q, (size_t)(end - q), p2, sizeof p2))) return -1; q += l;
            if (q != end) return -1;                        /* trailing junk */
            if (hm_pp_port(p1, strlen(p1), &out->src_port) < 0) return -1;
            { int dp; if (hm_pp_port(p2, strlen(p2), &dp) < 0) return -1; }
            if (fam[3] == '4') {
                unsigned char tmp[4];
                if (inet_pton(AF_INET, a1, out->src) != 1) return -1;
                if (inet_pton(AF_INET, a2, tmp) != 1) return -1;
                out->family = AF_INET;
            } else {
                unsigned char tmp[16];
                if (inet_pton(AF_INET6, a1, out->src) != 1) return -1;
                if (inet_pton(AF_INET6, a2, tmp) != 1) return -1;
                out->family = AF_INET6;
            }
        }
        return (long)linelen;
    }
}

/* Driven from C by Hyperman::_proxy_selftest (t/61). Returns the number of
 * the first failing step, or 0. Hostile inputs on purpose: these are the
 * bytes a parser gets from a port open to the internet. */
static int hm_proxy_selftest(void) {
    hm_pp_result r;
    unsigned char v2[64];
    /* 1: v1 TCP4 */
    { const char *s = "PROXY TCP4 192.0.2.1 198.51.100.2 54321 443\r\nGET";
      long n = hm_pp_parse((const unsigned char *)s, strlen(s), &r);
      if (n != 45 || r.family != AF_INET || r.src_port != 54321
          || r.src[0] != 192 || r.src[3] != 1) return 1; }
    /* 2: v1 TCP6 */
    { const char *s = "PROXY TCP6 2001:db8::1 2001:db8::2 1 2\r\n";
      long n = hm_pp_parse((const unsigned char *)s, strlen(s), &r);
      if (n != (long)strlen(s) || r.family != AF_INET6 || r.src_port != 1
          || r.src[0] != 0x20 || r.src[15] != 1) return 2; }
    /* 3: v1 UNKNOWN keeps the peer */
    { const char *s = "PROXY UNKNOWN\r\n";
      if (hm_pp_parse((const unsigned char *)s, strlen(s), &r) != 15 || r.family != 0) return 3; }
    /* 4: a partial v1 line needs more */
    { const char *s = "PROXY TCP4 192.0.2.1 198.51.";
      if (hm_pp_parse((const unsigned char *)s, strlen(s), &r) != 0) return 4; }
    /* 5: 107 bytes with no CRLF is invalid, not "more" */
    { unsigned char big[120]; memset(big, 'x', sizeof big); memcpy(big, "PROXY ", 6);
      if (hm_pp_parse(big, sizeof big, &r) != -1) return 5; }
    /* 6: not a PROXY line at all */
    { const char *s = "GET / HTTP/1.1\r\n";
      if (hm_pp_parse((const unsigned char *)s, strlen(s), &r) != -1) return 6; }
    /* 7: bad port */
    { const char *s = "PROXY TCP4 192.0.2.1 198.51.100.2 99999 443\r\n";
      if (hm_pp_parse((const unsigned char *)s, strlen(s), &r) != -1) return 7; }
    /* 8: trailing junk */
    { const char *s = "PROXY TCP4 192.0.2.1 198.51.100.2 1 2 3\r\n";
      if (hm_pp_parse((const unsigned char *)s, strlen(s), &r) != -1) return 8; }
    /* 9: v2 PROXY TCP4 with a TLV */
    memcpy(v2, hm_pp_v2_sig, 12);
    v2[12] = 0x21; v2[13] = 0x11; v2[14] = 0; v2[15] = 12 + 6;
    v2[16] = 10; v2[17] = 0; v2[18] = 0; v2[19] = 7;      /* src 10.0.0.7 */
    v2[20] = 10; v2[21] = 0; v2[22] = 0; v2[23] = 1;      /* dst */
    v2[24] = 0x1f; v2[25] = 0x90;                          /* 8080 */
    v2[26] = 0x00; v2[27] = 0x50;                          /* 80 */
    v2[28] = 0xee; v2[29] = 0; v2[30] = 3; v2[31] = 'a'; v2[32] = 'b'; v2[33] = 'c';
    { long n = hm_pp_parse(v2, 34, &r);
      if (n != 34 || r.family != AF_INET || r.src_port != 8080 || r.src[3] != 7) return 9; }
    /* 10: the same, truncated, needs more */
    if (hm_pp_parse(v2, 30, &r) != 0) return 10;
    /* 11: v2 LOCAL keeps the peer */
    v2[12] = 0x20; v2[14] = 0; v2[15] = 0;
    if (hm_pp_parse(v2, 16, &r) != 16 || r.family != 0) return 11;
    /* 12: a version nibble other than 2 is refused */
    v2[12] = 0x31;
    if (hm_pp_parse(v2, 16, &r) != -1) return 12;
    /* 13: a length past the ceiling is refused */
    v2[12] = 0x21; v2[14] = 0xff; v2[15] = 0xff;
    if (hm_pp_parse(v2, 16, &r) != -1) return 13;
    /* 14: a CR that is not the signature is invalid */
    { const unsigned char s[] = { 0x0d, 0x0a, 0x0d, 0x0a, 0x01 };
      if (hm_pp_parse(s, sizeof s, &r) != -1) return 14; }
    return 0;
}

#endif /* HM_PROXY_H */
