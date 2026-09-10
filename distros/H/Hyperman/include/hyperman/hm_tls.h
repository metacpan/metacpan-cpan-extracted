#ifndef HM_TLS_H
#define HM_TLS_H

/* Upper bound on a session-ticket key, which is a 16-byte key name plus an
 * HMAC key plus an AES key. The last two widened from 16 to 32 bytes in
 * OpenSSL 3.0, so the total is 48 through 1.1.1 and 80 on 3.x - and passing
 * the wrong length makes the ctrl a no-op that merely returns 0, with nothing
 * logged. The real length is therefore asked of the library at runtime and
 * this only has to bound it. Defined outside the HM_HAVE_OPENSSL fence
 * because hm_core.h sizes a buffer with it either way. */
#define HM_TLS_TKEY_MAX 128

/* TLS/HTTPS via OpenSSL. Enabled by Makefile.PL when OpenSSL is found
 * (-DHM_HAVE_OPENSSL, -lssl -lcrypto); otherwise the entry points compile to
 * stubs and tls_cert/tls_key error at runtime.
 *
 * Provides: the server SSL_CTX (certificate/key, ALPN, client-certificate
 * verification, and SNI-based multi-certificate selection), the per-connection
 * SSL wrap, the non-blocking read/write shims hm_cread/hm_cwrite (WANT_READ/
 * WANT_WRITE -> EAGAIN plus a cross-direction flag), peer-certificate capture,
 * and the $env keys apps expect (HTTPS, SSL_CLIENT_*). The handshake driver
 * (hm_tls_handshake) lives in hm_core.h. */

#ifdef HM_HAVE_OPENSSL

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509.h>
/* The session-ticket-key macros live here, not in ssl.h, and 3.x stopped
 * pulling this in transitively - without it the HM_HAVE_TICKET_KEYS probe
 * below silently fails and every reload rotates to an unshared key. */
#include <openssl/tls1.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

/* Pre-1.1.0 OpenSSL compatibility. Before 1.1.0 the library-init function,
 * the version-agnostic method constructor, and the min-proto-version setter
 * did not exist; init was explicit and TLS was selected via SSLv23_*_method
 * with SSL_OP_NO_* to fence off the obsolete protocols. LibreSSL reports a
 * >= 1.1.0 version number and ships these, so it takes the modern path. */
#if OPENSSL_VERSION_NUMBER < 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER)
static int OPENSSL_init_ssl(unsigned long opts, const void *settings) {
    (void)opts; (void)settings;
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();
    return 1;
}
#define OPENSSL_INIT_LOAD_SSL_STRINGS    0
#define OPENSSL_INIT_LOAD_CRYPTO_STRINGS 0
#define TLS_server_method                SSLv23_server_method
/* emulate set_min_proto_version(TLS1_2) with SSL_OP_NO_* below; the setter
 * itself is a no-op so hm_tls_ctx_one compiles unchanged. */
#define SSL_CTX_set_min_proto_version(ctx, v) \
    SSL_CTX_set_options((ctx), SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 \
                             | SSL_OP_NO_TLSv1 | SSL_OP_NO_TLSv1_1)
#endif

/* SSL_get1_peer_certificate is the 3.0 spelling of SSL_get_peer_certificate. */
#if OPENSSL_VERSION_NUMBER < 0x30000000L || defined(LIBRESSL_VERSION_NUMBER)
#define SSL_get1_peer_certificate SSL_get_peer_certificate
#endif

/* ALPN (server-side protocol negotiation, needed to offer HTTP/2 over TLS)
 * arrived in OpenSSL 1.0.2 - SSL_CTX_set_alpn_select_cb does not exist before
 * that. On an older library we simply do not install the callback: h2-over-TLS
 * is not offered and HTTPS falls back to HTTP/1.1. Without this guard the .so
 * links an undefined symbol and fails to load (see CPAN Testers on OpenSSL
 * 1.0.1 smokers). LibreSSL reports >= 1.0.2 and ships ALPN, so it takes this
 * path too. */
#if OPENSSL_VERSION_NUMBER >= 0x10002000L
#define HM_HAVE_ALPN 1
#endif

/* SSL_CTX_set_num_tickets is 1.1.1+ (it only means anything under TLS 1.3).
 * LibreSSL reports a >= 1.1.1 version number but has not always shipped it,
 * so it is excluded rather than probed. */
#if OPENSSL_VERSION_NUMBER >= 0x10101000L && !defined(LIBRESSL_VERSION_NUMBER)
#define HM_HAVE_NUM_TICKETS 1
#endif

/* TLS 1.3 itself: the version constant is 1.1.1+, the max-version setter
 * 1.1.0+. LibreSSL ships both once it defines TLS1_3_VERSION, so the constant
 * alone is the probe. Without it a build serves TLS 1.2 and no QUIC. */
#ifdef TLS1_3_VERSION
#define HM_HAVE_TLS13 1
#endif

/* HTTP/3 is TLS 1.3 or nothing. The Makefile.PL probe links against this same
 * library, so this cannot normally fire - it fires if HM_HAVE_HTTP3 is forced
 * by hand, and says why rather than failing later inside ngtcp2. */
#if defined(HM_HAVE_HTTP3) && !defined(HM_HAVE_TLS13)
#error "HM_HAVE_HTTP3 needs a TLS 1.3 OpenSSL (1.1.1+)"
#endif

/* The ticket-key get/set pair are macros over SSL_CTX_ctrl, absent when the
 * library was built with OPENSSL_NO_TLSEXT. */
#ifdef SSL_CTX_set_tlsext_ticket_keys
#define HM_HAVE_TICKET_KEYS 1
#endif

/* client-cert verification modes */
#define HM_TLS_VERIFY_NONE     0
#define HM_TLS_VERIFY_OPTIONAL 1
#define HM_TLS_VERIFY_REQUIRE  2

/* one SNI host -> its own SSL_CTX; the default ctx carries the registry in
 * ex_data so its servername callback can switch. Hosts are stored lowercased
 * and the array kept sorted, so the callback binary-searches with memcmp
 * rather than walking every entry through strcasecmp - the map is one entry
 * per certificate, and a multi-tenant gateway runs to hundreds. */
typedef struct { char *host; size_t hlen; SSL_CTX *ctx; } hm_sni_entry;
typedef struct { hm_sni_entry *entries; int n; } hm_sni_registry;

/* Only allocated when the client actually presented a certificate; the
 * protocol/cipher strings are OpenSSL-owned and live directly on hm_conn. */
typedef struct {
    int   verified;
    char *subject;
    char *issuer;
} hm_tls_peer;

/* ASCII lowercase, in place or into dst (which may equal src). DNS names are
 * ASCII, and tolower() would fold per the locale - in tr_TR 'I' does not go
 * to 'i', which would make a hostname match depend on the server's LANG. */
static void hm_tls_lc(char *dst, const char *src, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) {
        unsigned char ch = (unsigned char)src[i];
        dst[i] = (char)(ch >= 'A' && ch <= 'Z' ? ch + ('a' - 'A') : ch);
    }
}

/* Order by length first, then bytes: any total order works as long as the
 * sort and the search agree, and comparing lengths up front skips most
 * memcmps outright. */
static int hm_sni_cmp(const void *a, const void *b) {
    const hm_sni_entry *x = (const hm_sni_entry *)a;
    const hm_sni_entry *y = (const hm_sni_entry *)b;
    if (x->hlen != y->hlen) return x->hlen < y->hlen ? -1 : 1;
    return memcmp(x->host, y->host, x->hlen);
}

static int hm_tls_sni_ex_idx = -1;

/* ALPN: prefer h2, fall back to http/1.1. Installed only when HTTP/2 is on and
 * the OpenSSL in use provides ALPN (1.0.2+). */
#ifdef HM_HAVE_ALPN
/* QUIC serves h3 and nothing else - there is no "fall back to HTTP/1.1 over
 * QUIC" - so this is a second, shorter callback rather than a parameter on
 * the TCP one, which is on the h2 path and should not move. */
static const unsigned char HM_TLS_ALPN_H3[] = { 2, 'h', '3' };

static int hm_tls_alpn_h3_cb(SSL *ssl, const unsigned char **out,
                             unsigned char *outlen, const unsigned char *in,
                             unsigned int inlen, void *arg) {
    (void)ssl; (void)arg;
    if (SSL_select_next_proto((unsigned char **)out, outlen,
                              HM_TLS_ALPN_H3, sizeof(HM_TLS_ALPN_H3),
                              in, inlen) != OPENSSL_NPN_NEGOTIATED)
        return SSL_TLSEXT_ERR_ALERT_FATAL;
    return SSL_TLSEXT_ERR_OK;
}

static int hm_tls_alpn_cb(SSL *ssl, const unsigned char **out,
                          unsigned char *outlen, const unsigned char *in,
                          unsigned int inlen, void *arg) {
    static const unsigned char pref[] =
        { 2, 'h','2', 8, 'h','t','t','p','/','1','.','1' };
    (void)ssl; (void)arg;
    if (SSL_select_next_proto((unsigned char **)out, outlen,
                              pref, sizeof(pref), in, inlen)
        != OPENSSL_NPN_NEGOTIATED)
        return SSL_TLSEXT_ERR_NOACK;
    return SSL_TLSEXT_ERR_OK;
}
#endif

/* optional-mode verify: accept regardless; the real result is read back from
 * SSL_get_verify_result after the handshake and reported in $env. */
static int hm_tls_verify_cb(int ok, X509_STORE_CTX *ctx) {
    (void)ok; (void)ctx;
    return 1;
}

/* SNI: switch to the matching host's SSL_CTX (case-insensitive). */
static int hm_tls_sni_cb(SSL *ssl, int *ad, void *arg) {
    SSL_CTX *ctx = SSL_get_SSL_CTX(ssl);
    hm_sni_registry *reg = (hm_sni_registry *)
        (hm_tls_sni_ex_idx >= 0 ? SSL_CTX_get_ex_data(ctx, hm_tls_sni_ex_idx) : NULL);
    const char *host = SSL_get_servername(ssl, TLSEXT_NAMETYPE_host_name);
    (void)ad; (void)arg;
    if (host && reg && reg->n > 0) {
        char lc[256];                     /* a DNS name is at most 253 bytes */
        size_t hl = strlen(host);
        if (hl > 0 && hl < sizeof(lc)) {
            int lo = 0, hi = reg->n - 1;
            hm_tls_lc(lc, host, hl);
            while (lo <= hi) {
                int mid = lo + (hi - lo) / 2;
                hm_sni_entry *e = &reg->entries[mid];
                int cmp = hl != e->hlen ? (hl < e->hlen ? -1 : 1)
                                        : memcmp(lc, e->host, hl);
                if (cmp == 0) { SSL_set_SSL_CTX(ssl, e->ctx); break; }
                if (cmp < 0) hi = mid - 1; else lo = mid + 1;
            }
        }
    }
    return SSL_TLSEXT_ERR_OK;
}

static void hm_tls_init(void) {
    static int inited = 0;
    if (!inited) {
        OPENSSL_init_ssl(OPENSSL_INIT_LOAD_SSL_STRINGS
                         | OPENSSL_INIT_LOAD_CRYPTO_STRINGS, NULL);
        hm_tls_sni_ex_idx = SSL_CTX_get_ex_new_index(0, NULL, NULL, NULL, NULL);
        inited = 1;
    }
}

/* Build and configure one server SSL_CTX from a cert/key pair, with optional
 * ALPN and client-cert verification. tkey, when given, is a 48-byte
 * session-ticket key to install instead of the random one SSL_CTX_new mints
 * (see hm_tls_ctx_build). Returns NULL (reason on stderr) on error. */
/* HM_TLSCTX_QUIC: build the context QUIC needs instead of the TCP one. It is
 * a flag rather than a second builder because everything that matters is the
 * same - the certificate, the chain, the CA and client-cert verification, and
 * above all the SESSION TICKET KEY. A QUIC context carrying a different key
 * from its TCP sibling silently degrades cross-protocol resumption to full
 * handshakes, which is the identical bug the SNI note below describes. */
#define HM_TLSCTX_QUIC 1

static SSL_CTX *hm_tls_ctx_one(const char *cert, const char *key,
                               const char *ca, int verify, int alpn_h2,
                               const unsigned char *tkey, size_t tkeylen,
                               int flags) {
    const int quic = (flags & HM_TLSCTX_QUIC) != 0;
    /* Any fixed non-empty string will do: it only has to be stable across the
     * contexts a client might resume against, which one constant guarantees. */
    static const unsigned char sid[] = "hyperman";
    SSL_CTX *ctx = SSL_CTX_new(TLS_server_method());
    if (!ctx) return NULL;
    /* QUIC is TLS 1.3 only - there is no QUIC over 1.2 - and pinning the max
     * as well as the min says so rather than leaving it to negotiation.
     * TLS1_3_VERSION and the max-version setter are 1.1.1 and 1.1.0; a library
     * with neither cannot drive ngtcp2, so HM_HAVE_HTTP3 is never set against
     * one and no QUIC context is ever built there. The pinning is therefore
     * compiled out rather than emulated, leaving the TLS 1.2 floor the TCP
     * listener has always had. */
#ifdef HM_HAVE_TLS13
    SSL_CTX_set_min_proto_version(ctx, quic ? TLS1_3_VERSION : TLS1_2_VERSION);
    if (quic) SSL_CTX_set_max_proto_version(ctx, TLS1_3_VERSION);
#else
    SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
#endif
    SSL_CTX_set_options(ctx, SSL_OP_NO_COMPRESSION | SSL_OP_CIPHER_SERVER_PREFERENCE
#ifdef HM_HAVE_KTLS
                             /* Ask for the kernel record layer. OpenSSL only
                              * takes it up if the kernel has the tls ULP and
                              * the negotiated cipher is one it can offload;
                              * otherwise this is inert and every connection
                              * encrypts in userspace exactly as before. */
                             | SSL_OP_ENABLE_KTLS
#endif
#ifdef SSL_OP_NO_RENEGOTIATION
                             /* client-initiated TLS 1.2 renegotiation is an
                              * asymmetric-CPU DoS and nothing here wants it;
                              * refusing it also retires the only case that
                              * makes SSL_write block wanting a read */
                             | SSL_OP_NO_RENEGOTIATION
#endif
                             );
#ifdef HM_HAVE_KTLS
    /* There is no kernel record layer for QUIC: ngtcp2 encrypts every packet
     * itself, so asking for kTLS here is at best inert and at worst a
     * handshake OpenSSL sets up and nothing uses. */
    if (quic) SSL_CTX_clear_options(ctx, SSL_OP_ENABLE_KTLS);
#endif
    /* PARTIAL_WRITE is about SSL_write, which a QUIC context never calls. */
    if (!quic)
    SSL_CTX_set_mode(ctx, SSL_MODE_ENABLE_PARTIAL_WRITE
                          | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER
#ifdef SSL_MODE_RELEASE_BUFFERS
                          /* hand OpenSSL's record buffers back whenever they
                           * drain, rather than pinning them for a
                           * connection's whole life. A keep-alive server is
                           * mostly idle connections, which is exactly the
                           * case this covers. How much it saves depends on
                           * the OpenSSL version's buffer sizing and on the
                           * allocator actually returning the pages - worth
                           * measuring on the deployment platform (Linux
                           * /proc/PID/status VmRSS; macOS RSS is far too
                           * noisy to read anything off). */
                          | SSL_MODE_RELEASE_BUFFERS
#endif
                          );
    /* Without a session id context OpenSSL declines to resume a session on a
     * context that verifies peers, so every mTLS connection would pay a full
     * handshake plus a full chain verification. */
    SSL_CTX_set_session_id_context(ctx, sid, sizeof(sid) - 1);
#ifdef HM_HAVE_NUM_TICKETS
    /* TLS 1.3 issues two NewSessionTickets per handshake by default; one is
     * enough to resume with, and the second is pure post-handshake write. */
    SSL_CTX_set_num_tickets(ctx, 1);
#endif
#ifdef HM_HAVE_TICKET_KEYS
    /* copied rather than cast: the setter takes a non-const void * */
    if (tkey && tkeylen && tkeylen <= HM_TLS_TKEY_MAX) {
        unsigned char tk[HM_TLS_TKEY_MAX];
        memcpy(tk, tkey, tkeylen);
        SSL_CTX_set_tlsext_ticket_keys(ctx, tk, (long)tkeylen);
    }
#else
    (void)tkey; (void)tkeylen;
#endif
    if (SSL_CTX_use_certificate_chain_file(ctx, cert) <= 0) {
        fprintf(stderr, "Hyperman TLS: cannot load certificate '%s'\n", cert);
        ERR_print_errors_fp(stderr); SSL_CTX_free(ctx); return NULL;
    }
    if (SSL_CTX_use_PrivateKey_file(ctx, key, SSL_FILETYPE_PEM) <= 0) {
        fprintf(stderr, "Hyperman TLS: cannot load private key '%s'\n", key);
        ERR_print_errors_fp(stderr); SSL_CTX_free(ctx); return NULL;
    }
    if (!SSL_CTX_check_private_key(ctx)) {
        fprintf(stderr, "Hyperman TLS: certificate and key do not match\n");
        SSL_CTX_free(ctx); return NULL;
    }
#ifdef HM_HAVE_ALPN
    /* h3 only on a QUIC context: offering h2 or http/1.1 over QUIC is a
     * protocol error. The TCP list is untouched - h3 is discovered through
     * Alt-Svc, never through ALPN over TCP. */
    if (quic)         SSL_CTX_set_alpn_select_cb(ctx, hm_tls_alpn_h3_cb, NULL);
    else if (alpn_h2) SSL_CTX_set_alpn_select_cb(ctx, hm_tls_alpn_cb, NULL);
#else
    (void)alpn_h2;   /* ALPN unavailable on this OpenSSL; h2-over-TLS not offered */
#endif
    /* 0-RTT refused explicitly rather than left at a default: accepting it
     * means accepting replayable application data, and that is a decision
     * this server has not made. The setter is 1.1.1+, and a library without
     * it has no 0-RTT to refuse - nor any QUIC context to refuse it on. */
#ifdef HM_HAVE_TLS13
    if (quic) SSL_CTX_set_max_early_data(ctx, 0);
#endif
    if (verify != HM_TLS_VERIFY_NONE) {
        int flags = SSL_VERIFY_PEER;
        if (ca && SSL_CTX_load_verify_locations(ctx, ca, NULL) <= 0) {
            fprintf(stderr, "Hyperman TLS: cannot load CA '%s'\n", ca);
            ERR_print_errors_fp(stderr); SSL_CTX_free(ctx); return NULL;
        }
        if (ca) {   /* tell the client which CAs we accept */
            STACK_OF(X509_NAME) *names = SSL_load_client_CA_file(ca);
            if (names) SSL_CTX_set_client_CA_list(ctx, names);
        }
        if (verify == HM_TLS_VERIFY_REQUIRE) flags |= SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
        SSL_CTX_set_verify(ctx, flags,
            verify == HM_TLS_VERIFY_OPTIONAL ? hm_tls_verify_cb : NULL);
    }
    return ctx;
}

/* Copy a context's session-ticket key into buf (at most HM_TLS_TKEY_MAX
 * bytes) and report its length. The size is asked of the library rather than
 * assumed - it differs between 1.1.1 and 3.x, and the getter answers a
 * mismatched length with a plain 0. Returns 1 on success, 0 if the library
 * cannot report one (built without TLSEXT, or TLS not compiled in here). */
static int hm_tls_get_ticket_key(void *ctxv, unsigned char *buf, size_t *len) {
#ifdef HM_HAVE_TICKET_KEYS
    long need;
    if (!ctxv) return 0;
    need = SSL_CTX_ctrl((SSL_CTX *)ctxv, SSL_CTRL_GET_TLSEXT_TICKET_KEYS,
                        0, NULL);                    /* 0/NULL asks the size */
    if (need <= 0 || (size_t)need > HM_TLS_TKEY_MAX) return 0;
    if (SSL_CTX_get_tlsext_ticket_keys((SSL_CTX *)ctxv, buf, need) != 1)
        return 0;
    *len = (size_t)need;
    return 1;
#else
    (void)ctxv; (void)buf; (void)len;
    return 0;
#endif
}

/* Build the default SSL_CTX plus any SNI per-host contexts (sni_hv:
 * { host => { cert => ..., key => ... }, ... }). The registry is attached to
 * the default ctx via ex_data and the servername callback installed. Returns
 * the default ctx or NULL.
 *
 * tkey, when given, is the session-ticket key to install across every context
 * built here; otherwise the default context's own random key is read back and
 * shared with the per-host ones. Either way all of them end up with the SAME
 * key, which is what makes a ticket usable: SSL_CTX_new mints an independent
 * random key per context, so left alone a ticket issued while one certificate
 * was in effect would not decrypt on the context that a later handshake
 * selects, and the client would silently fall back to a full handshake.
 * hm_tls_reload passes the running context's key in for the same reason
 * across processes - it runs per worker, so each would otherwise rotate to a
 * key its siblings cannot read. */
/* The QUIC context for a listener, built through hm_tls_ctx_one so it shares
 * the certificate, the verification policy and - the one that bites quietly -
 * the SESSION TICKET KEY with its TCP sibling.
 *
 * `tkey` is the key already in use on that sibling. Pass it, always: a QUIC
 * context left to mint its own means a client that resumes across protocols
 * gets a full handshake and nothing reports it. */
static void *hm_tls_quic_ctx_build(const char *cert, const char *key,
                                   const char *ca, int verify,
                                   const unsigned char *tkey, size_t tkeylen) {
    hm_tls_init();
    return (void *)hm_tls_ctx_one(cert, key, ca, verify, 0, tkey, tkeylen,
                                  HM_TLSCTX_QUIC);
}

/* The session-ticket key a built context is using, so the QUIC context can be
 * given the same one. */
static int hm_tls_ctx_tkey(void *ctx, unsigned char *out, size_t *len) {
    return hm_tls_get_ticket_key((SSL_CTX *)ctx, out, len);
}

static void *hm_tls_ctx_build(pTHX_ const char *cert, const char *key,
                              const char *ca, int verify,
                              SV *sni_hv, int alpn_h2,
                              const unsigned char *tkey, size_t tkeylen) {
    SSL_CTX *def;
    unsigned char kbuf[HM_TLS_TKEY_MAX];
    hm_tls_init();
    def = hm_tls_ctx_one(cert, key, ca, verify, alpn_h2, tkey, tkeylen, 0);
    if (!def) return NULL;
    if (!tkey && hm_tls_get_ticket_key(def, kbuf, &tkeylen)) tkey = kbuf;

    if (sni_hv && SvROK(sni_hv) && SvTYPE(SvRV(sni_hv)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(sni_hv);
        I32 n = hv_iterinit(hv), i = 0;
        hm_sni_registry *reg = (hm_sni_registry *)hm_xcalloc(1, sizeof(hm_sni_registry));
        HE *he;
        reg->entries = (hm_sni_entry *)hm_xcalloc(n > 0 ? n : 1, sizeof(hm_sni_entry));
        while ((he = hv_iternext(hv))) {
            I32 klen; char *host = hv_iterkey(he, &klen);
            SV *val = hv_iterval(hv, he);
            const char *hc = NULL, *hk = NULL;
            SSL_CTX *hctx;
            char *lchost;
            if (klen <= 0) continue;          /* a key we cannot match on */
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                HV *e = (HV *)SvRV(val);
                SV **c = hv_fetchs(e, "cert", 0);
                SV **k = hv_fetchs(e, "key", 0);
                if (c && SvOK(*c)) hc = SvPV_nolen(*c);
                if (k && SvOK(*k)) hk = SvPV_nolen(*k);
            }
            if (!hc || !hk) {
                fprintf(stderr, "Hyperman TLS: SNI host '%s' needs cert and key\n", host);
                continue;
            }
            hctx = hm_tls_ctx_one(hc, hk, ca, verify, alpn_h2, tkey, tkeylen, 0);
            if (!hctx) continue;
            lchost = strdup(host);
            if (!lchost) { SSL_CTX_free(hctx); continue; }
            hm_tls_lc(lchost, lchost, (size_t)klen);
            reg->entries[i].host = lchost;
            reg->entries[i].hlen = (size_t)klen;
            reg->entries[i].ctx  = hctx;
            i++;
        }
        reg->n = i;
        if (i > 1) qsort(reg->entries, (size_t)i, sizeof(hm_sni_entry), hm_sni_cmp);
        SSL_CTX_set_ex_data(def, hm_tls_sni_ex_idx, reg);
        SSL_CTX_set_tlsext_servername_callback(def, hm_tls_sni_cb);
    }
    return def;
}

/* How many SNI hosts a built context actually carries. -1 when it has no
 * registry at all (a plain default with no SNI map).
 *
 * hm_tls_ctx_build SKIPS a host whose certificate will not load and
 * still returns a usable default, which is right at boot - one bad PEM
 * should not stop a server starting. It is wrong for a reload, where
 * the same behaviour silently drops every domain that failed down to
 * the fallback certificate. A reload compares this against what it
 * asked for and refuses to install a context that carries fewer. */
static int hm_tls_sni_count(void *ctxv) {
    hm_sni_registry *reg;
    if (!ctxv || hm_tls_sni_ex_idx < 0) return -1;
    reg = (hm_sni_registry *)SSL_CTX_get_ex_data((SSL_CTX *)ctxv,
                                                 hm_tls_sni_ex_idx);
    return reg ? reg->n : -1;
}

/* Release a context built by hm_tls_ctx_build, and the SNI registry that
 * hangs off it.
 *
 * The registry has to be freed by hand: hm_tls_sni_ex_idx is created with
 * a NULL free function, so SSL_CTX_free walks past it. Nothing needed
 * this until tls_reload, because a context used to live exactly as long
 * as the process did.
 *
 * Safe on a context that was built before a fork. Copy-on-write means
 * the caller is decrementing refcounts in its own copy of those pages;
 * the parent's context and its siblings' are untouched. */
static void hm_tls_ctx_free(void *ctxv) {
    SSL_CTX *ctx = (SSL_CTX *)ctxv;
    hm_sni_registry *reg;
    if (!ctx) return;

    reg = (hm_sni_registry *)(hm_tls_sni_ex_idx >= 0
            ? SSL_CTX_get_ex_data(ctx, hm_tls_sni_ex_idx) : NULL);
    if (reg) {
        int i;
        for (i = 0; i < reg->n; i++) {
            free(reg->entries[i].host);
            if (reg->entries[i].ctx) SSL_CTX_free(reg->entries[i].ctx);
        }
        free(reg->entries);
        free(reg);
        SSL_CTX_set_ex_data(ctx, hm_tls_sni_ex_idx, NULL);
    }
    SSL_CTX_free(ctx);
}

/* Wrap an accepted fd in a server-side SSL and put it in handshake state. */
static int hm_tls_wrap(hm_conn *c, void *ctx) {
    SSL *ssl = SSL_new((SSL_CTX *)ctx);
    if (!ssl) return -1;
    SSL_set_fd(ssl, HM_SSL_FD(c->fd));
    SSL_set_accept_state(ssl);
    c->ssl = ssl;
    c->tls_hs = 1;
    return 0;
}

/* After a successful handshake, record protocol/cipher and any client cert.
 * The protocol and cipher names are OpenSSL-owned and valid for the life of
 * the connection, so they sit on hm_conn directly; the heap struct is only
 * paid for when a client certificate was actually presented, which on a
 * public listener is never. */
/* The handshake's results, off an SSL and into three out-parameters rather
 * than into an hm_conn.
 *
 * QUIC's handshake is a TLS handshake and its connection is an hm_qconn, not
 * an hm_conn - so a version of this that took hm_conn * could only ever serve
 * the TCP half, and HTTP/3 would silently report no client certificate at
 * all. mTLS working on one transport and quietly not on the other is a worse
 * failure than not supporting it. */
static void hm_tls_capture_ssl(SSL *ssl, const char **proto,
                               const char **cipher, void **peer_out) {
    X509 *cert;
    if (proto)  *proto  = SSL_get_version(ssl);
    if (cipher) *cipher = SSL_get_cipher(ssl);
    if (!peer_out) return;
    cert = SSL_get1_peer_certificate(ssl);
    if (cert) {
        hm_tls_peer *p = (hm_tls_peer *)hm_xcalloc(1, sizeof(hm_tls_peer));
        char buf[512];
        p->verified = (SSL_get_verify_result(ssl) == X509_V_OK);
        if (X509_NAME_oneline(X509_get_subject_name(cert), buf, sizeof(buf)))
            p->subject = strdup(buf);
        if (X509_NAME_oneline(X509_get_issuer_name(cert), buf, sizeof(buf)))
            p->issuer = strdup(buf);
        X509_free(cert);
        *peer_out = p;
    }
}

static void hm_tls_capture_peer(hm_conn *c) {
    hm_tls_capture_ssl((SSL *)c->ssl, &c->tls_proto, &c->tls_cipher,
                       &c->tls_peer);
}

static void hm_tls_conn_free(hm_conn *c) {
    if (c->tls_peer) {
        hm_tls_peer *p = (hm_tls_peer *)c->tls_peer;
        if (p->subject) free(p->subject);
        if (p->issuer)  free(p->issuer);
        free(p);
        c->tls_peer = NULL;
    }
    c->tls_proto = c->tls_cipher = NULL;
    if (c->ssl) {
        /* close_notify costs a write syscall and only means anything once a
         * session exists - a connection dropped mid-handshake has nothing to
         * shut down, so tell OpenSSL not to emit the alert for it. */
        if (c->tls_hs) SSL_set_quiet_shutdown((SSL *)c->ssl, 1);
        else           SSL_shutdown((SSL *)c->ssl);
        SSL_free((SSL *)c->ssl);
        c->ssl = NULL;
    }
}

/* The TLS $env keys as shared key SVs, made once. hv_stores against a literal
 * hashes the string and cuts a fresh HEK out of the shared string table on
 * every request, then releases it again at env teardown; storing through a
 * shared SV reuses the precomputed hash and the one HEK for the life of the
 * process. Same trick, and the same reasoning, as the HTTP_* table in
 * hm_core.h - it just pays per TLS request rather than per header.
 *
 * The values stay freshly allocated per request even though they are constant
 * for the connection: an env value is what a PSGI app assigns THROUGH when it
 * writes $env->{HTTPS}, and perl assigns into the SV already in the hash slot
 * rather than replacing it, so a shared value SV would let one request's
 * rewrite bleed into the next on the same keep-alive connection. */
/* Is this connection's SEND side offloaded to the kernel right now?
 *
 * When it is, the socket itself is in TLS mode: a plain writev(2) or
 * sendfile(2) on the descriptor comes out as encrypted records, which is what
 * lets an HTTPS response take the same two fast paths a plaintext one takes.
 *
 * ASKED EVERY TIME, NEVER CACHED, and that is the important part. OpenSSL
 * hands the record layer back to userspace if it ever has to take it back - a
 * TLS 1.3 KeyUpdate is the case that does - and a connection that answered
 * "yes" at handshake would then have Hyperman writing straight to a socket
 * that is no longer encrypting. That failure does not look like a crash or a
 * corrupt response: it PUTS THE PLAINTEXT ON THE WIRE. A cached flag is not
 * worth that, and the check is a flag test on the BIO, not a syscall.
 *
 * c->ktls_tx is a report of what happened at handshake, for stats and tests.
 * It is deliberately not what the write paths consult. */
static int hm_ktls_tx(hm_conn *c) {
#ifdef HM_HAVE_KTLS
    if (!c->ssl) return 0;
    return BIO_get_ktls_send(SSL_get_wbio((SSL *)c->ssl)) > 0;
#else
    (void)c;
    return 0;
#endif
}

enum {
    HM_TLSK_HTTPS, HM_TLSK_PROTOCOL, HM_TLSK_CIPHER,
    HM_TLSK_VERIFY, HM_TLSK_S_DN, HM_TLSK_I_DN, HM_TLSK_KTLS, HM_TLSK_COUNT
};
static const char *const hm_tlsk_name[HM_TLSK_COUNT] = {
    "HTTPS", "SSL_PROTOCOL", "SSL_CIPHER",
    "SSL_CLIENT_VERIFY", "SSL_CLIENT_S_DN", "SSL_CLIENT_I_DN",
    /* 1 when the kernel took the send side of this connection. The only way
     * to SEE kTLS working: it depends on the kernel, the OpenSSL build and
     * the negotiated cipher all agreeing, any of which can silently say no,
     * and a server that quietly did not offload looks exactly like one that
     * did. */
    "SSL_KTLS"
};
static SV *hm_tlsk[HM_TLSK_COUNT];

static void hm_tls_env_init(pTHX) {
    int i;
    if (hm_tlsk[0]) return;
    for (i = 0; i < HM_TLSK_COUNT; i++)
        hm_tlsk[i] = newSVpvn_share(hm_tlsk_name[i],
                                    (I32)strlen(hm_tlsk_name[i]), 0);
}

/* Add the TLS $env keys (mod_ssl-style) for a TLS connection. */
/* The TLS half of $env, from the captured results rather than from a
 * connection - so HTTP/3 reports SSL_CLIENT_* exactly as HTTP/1.1 and
 * HTTP/2 do. ktls is passed in because there is no kernel record layer for
 * QUIC and the caller is the only one that knows which it is. */
static void hm_tls_env_from(pTHX_ HV *env, const char *proto,
                            const char *cipher, void *peer, int ktls) {
    hm_tls_peer *p;
    hm_tls_env_init(aTHX);
    (void)hv_store_ent(env, hm_tlsk[HM_TLSK_HTTPS], newSVpvs("on"), 0);
    if (proto)
        (void)hv_store_ent(env, hm_tlsk[HM_TLSK_PROTOCOL],
                           newSVpv(proto, 0), 0);
    if (cipher)
        (void)hv_store_ent(env, hm_tlsk[HM_TLSK_CIPHER],
                           newSVpv(cipher, 0), 0);
    (void)hv_store_ent(env, hm_tlsk[HM_TLSK_KTLS], newSViv(ktls ? 1 : 0), 0);
    p = (hm_tls_peer *)peer;
    if (p) {
        (void)hv_store_ent(env, hm_tlsk[HM_TLSK_VERIFY],
                           newSVpv(p->verified ? "SUCCESS" : "FAILED", 0), 0);
        if (p->subject)
            (void)hv_store_ent(env, hm_tlsk[HM_TLSK_S_DN],
                               newSVpv(p->subject, 0), 0);
        if (p->issuer)
            (void)hv_store_ent(env, hm_tlsk[HM_TLSK_I_DN],
                               newSVpv(p->issuer, 0), 0);
    } else {
        (void)hv_store_ent(env, hm_tlsk[HM_TLSK_VERIFY], newSVpvs("NONE"), 0);
    }
}

static void hm_tls_env(pTHX_ hm_conn *c, HV *env) {
    if (!c->ssl) return;
    hm_tls_env_from(aTHX_ env, c->tls_proto, c->tls_cipher, c->tls_peer,
                    hm_ktls_tx(c) ? 1 : 0);
}

/* Non-blocking read. >0 bytes, 0 = EOF/closed, -1 = error (errno==EAGAIN when
 * the TLS engine would block; c->tls_r_wants_w records a needed writable). */
static ssize_t hm_cread(hm_conn *c, void *buf, size_t n) {
    int r, e;
    if (!c->ssl) return hm_os_recv(c->fd, buf, n);
    ERR_clear_error();
    r = SSL_read((SSL *)c->ssl, buf, (int)(n > INT_MAX ? INT_MAX : n));
    if (r > 0) return r;
    e = SSL_get_error((SSL *)c->ssl, r);
    if (e == SSL_ERROR_WANT_READ)  { c->tls_r_wants_w = 0; errno = EAGAIN; return -1; }
    if (e == SSL_ERROR_WANT_WRITE) { c->tls_r_wants_w = 1; errno = EAGAIN; return -1; }
    return 0;   /* ZERO_RETURN or fatal: treat as closed */
}

/* Non-blocking write. Mirrors hm_cread; c->tls_w_wants_r records a needed
 * readable (e.g. during a TLS 1.2 renegotiation). */
static ssize_t hm_cwrite(hm_conn *c, const void *buf, size_t n) {
    int r, e;
    if (!c->ssl) return hm_os_send(c->fd, buf, n);
    if (n == 0) return 0;
    ERR_clear_error();
    r = SSL_write((SSL *)c->ssl, buf, (int)(n > INT_MAX ? INT_MAX : n));
    if (r > 0) return r;
    e = SSL_get_error((SSL *)c->ssl, r);
    if (e == SSL_ERROR_WANT_WRITE) { c->tls_w_wants_r = 0; errno = EAGAIN; return -1; }
    if (e == SSL_ERROR_WANT_READ)  { c->tls_w_wants_r = 1; errno = EAGAIN; return -1; }
    errno = EIO;
    return -1;
}

static int hm_tls_available(void) { return 1; }

/* The runtime library banner ("OpenSSL 3.0.13 30 Jan 2024", "LibreSSL
 * 3.8.2"): which stack is actually loaded, not which headers built this.
 * OpenSSL_version arrived in 1.1.0 and LibreSSL in 2.7.0; before those it
 * is SSLeay_version, same string, older name. */
static const char *hm_tls_library(void) {
#if OPENSSL_VERSION_NUMBER >= 0x10100000L \
    && (!defined(LIBRESSL_VERSION_NUMBER) || LIBRESSL_VERSION_NUMBER >= 0x2070000fL)
    return OpenSSL_version(OPENSSL_VERSION);
#else
    return SSLeay_version(SSLEAY_VERSION);
#endif
}

#else /* !HM_HAVE_OPENSSL */

/* The stubs read and write through hm_os_recv/hm_os_send, which hm_win.h
 * has already provided along with <unistd.h> where there is one. */
static void *hm_tls_ctx_build(pTHX_ const char *cert, const char *key,
                              const char *ca, int verify, SV *sni, int alpn,
                              const unsigned char *tkey, size_t tkeylen) {
    (void)cert; (void)key; (void)ca; (void)verify; (void)sni; (void)alpn;
    (void)tkey; (void)tkeylen;
    return 0;
}
static int  hm_tls_get_ticket_key(void *ctx, unsigned char *buf, size_t *len)
    { (void)ctx; (void)buf; (void)len; return 0; }
static int  hm_tls_sni_count(void *ctx) { (void)ctx; return -1; }
static void hm_tls_ctx_free(void *ctx) { (void)ctx; }
static int  hm_tls_wrap(hm_conn *c, void *ctx) { (void)c; (void)ctx; return -1; }
static void hm_tls_capture_peer(hm_conn *c) { (void)c; }
static void hm_tls_conn_free(hm_conn *c) { (void)c; }
static void hm_tls_env(pTHX_ hm_conn *c, HV *env) { (void)c; (void)env; }
static int     hm_ktls_tx(hm_conn *c) { (void)c; return 0; }
static ssize_t hm_cread(hm_conn *c, void *buf, size_t n)
    { return hm_os_recv(c->fd, buf, n); }
static ssize_t hm_cwrite(hm_conn *c, const void *buf, size_t n)
    { return hm_os_send(c->fd, buf, n); }
static int  hm_tls_available(void) { return 0; }
static const char *hm_tls_library(void) { return 0; }

#endif /* HM_HAVE_OPENSSL */

#endif /* HM_TLS_H */
