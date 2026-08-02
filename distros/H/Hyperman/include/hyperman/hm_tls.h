#ifndef HM_TLS_H
#define HM_TLS_H

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
#include <errno.h>
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

/* client-cert verification modes */
#define HM_TLS_VERIFY_NONE     0
#define HM_TLS_VERIFY_OPTIONAL 1
#define HM_TLS_VERIFY_REQUIRE  2

/* one SNI host -> its own SSL_CTX; the default ctx carries the registry in
 * ex_data so its servername callback can switch. */
typedef struct { char *host; SSL_CTX *ctx; } hm_sni_entry;
typedef struct { hm_sni_entry *entries; int n; } hm_sni_registry;

/* captured at handshake, surfaced into $env */
typedef struct {
    int         has_cert;
    int         verified;
    char       *subject;
    char       *issuer;
    const char *proto;   /* OpenSSL-owned, valid for the connection */
    const char *cipher;
} hm_tls_peer;

static int hm_tls_sni_ex_idx = -1;

/* ALPN: prefer h2, fall back to http/1.1. Installed only when HTTP/2 is on. */
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
    if (host && reg) {
        int i;
        for (i = 0; i < reg->n; i++)
            if (strcasecmp(host, reg->entries[i].host) == 0) {
                SSL_set_SSL_CTX(ssl, reg->entries[i].ctx);
                break;
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
 * ALPN and client-cert verification. Returns NULL (reason on stderr) on error. */
static SSL_CTX *hm_tls_ctx_one(const char *cert, const char *key,
                               const char *ca, int verify, int alpn_h2) {
    SSL_CTX *ctx = SSL_CTX_new(TLS_server_method());
    if (!ctx) return NULL;
    SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
    SSL_CTX_set_options(ctx, SSL_OP_NO_COMPRESSION | SSL_OP_CIPHER_SERVER_PREFERENCE);
    SSL_CTX_set_mode(ctx, SSL_MODE_ENABLE_PARTIAL_WRITE
                          | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
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
    if (alpn_h2) SSL_CTX_set_alpn_select_cb(ctx, hm_tls_alpn_cb, NULL);
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

/* Build the default SSL_CTX plus any SNI per-host contexts (sni_hv:
 * { host => { cert => ..., key => ... }, ... }). The registry is attached to
 * the default ctx via ex_data and the servername callback installed. Returns
 * the default ctx or NULL. */
static void *hm_tls_ctx_build(pTHX_ const char *cert, const char *key,
                              const char *ca, int verify,
                              SV *sni_hv, int alpn_h2) {
    SSL_CTX *def;
    hm_tls_init();
    def = hm_tls_ctx_one(cert, key, ca, verify, alpn_h2);
    if (!def) return NULL;

    if (sni_hv && SvROK(sni_hv) && SvTYPE(SvRV(sni_hv)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(sni_hv);
        I32 n = hv_iterinit(hv), i = 0;
        hm_sni_registry *reg = (hm_sni_registry *)calloc(1, sizeof(hm_sni_registry));
        HE *he;
        reg->entries = (hm_sni_entry *)calloc(n > 0 ? n : 1, sizeof(hm_sni_entry));
        while ((he = hv_iternext(hv))) {
            I32 klen; char *host = hv_iterkey(he, &klen);
            SV *val = hv_iterval(hv, he);
            const char *hc = NULL, *hk = NULL;
            SSL_CTX *hctx;
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
            hctx = hm_tls_ctx_one(hc, hk, ca, verify, alpn_h2);
            if (!hctx) continue;
            reg->entries[i].host = strdup(host);
            reg->entries[i].ctx  = hctx;
            i++;
        }
        reg->n = i;
        SSL_CTX_set_ex_data(def, hm_tls_sni_ex_idx, reg);
        SSL_CTX_set_tlsext_servername_callback(def, hm_tls_sni_cb);
    }
    return def;
}

/* Wrap an accepted fd in a server-side SSL and put it in handshake state. */
static int hm_tls_wrap(hm_conn *c, void *ctx) {
    SSL *ssl = SSL_new((SSL_CTX *)ctx);
    if (!ssl) return -1;
    SSL_set_fd(ssl, c->fd);
    SSL_set_accept_state(ssl);
    c->ssl = ssl;
    c->tls_hs = 1;
    return 0;
}

/* After a successful handshake, record protocol/cipher and any client cert. */
static void hm_tls_capture_peer(hm_conn *c) {
    SSL *ssl = (SSL *)c->ssl;
    hm_tls_peer *p = (hm_tls_peer *)calloc(1, sizeof(hm_tls_peer));
    X509 *cert;
    p->proto  = SSL_get_version(ssl);
    p->cipher = SSL_get_cipher(ssl);
    cert = SSL_get1_peer_certificate(ssl);
    if (cert) {
        char buf[512];
        p->has_cert = 1;
        p->verified = (SSL_get_verify_result(ssl) == X509_V_OK);
        if (X509_NAME_oneline(X509_get_subject_name(cert), buf, sizeof(buf)))
            p->subject = strdup(buf);
        if (X509_NAME_oneline(X509_get_issuer_name(cert), buf, sizeof(buf)))
            p->issuer = strdup(buf);
        X509_free(cert);
    }
    c->tls_peer = p;
}

static void hm_tls_conn_free(hm_conn *c) {
    if (c->tls_peer) {
        hm_tls_peer *p = (hm_tls_peer *)c->tls_peer;
        if (p->subject) free(p->subject);
        if (p->issuer)  free(p->issuer);
        free(p);
        c->tls_peer = NULL;
    }
    if (c->ssl) {
        SSL_shutdown((SSL *)c->ssl);
        SSL_free((SSL *)c->ssl);
        c->ssl = NULL;
    }
}

/* Add the TLS $env keys (mod_ssl-style) for a TLS connection. */
static void hm_tls_env(pTHX_ hm_conn *c, HV *env) {
    hm_tls_peer *p;
    if (!c->ssl) return;
    hv_stores(env, "HTTPS", newSVpvs("on"));
    p = (hm_tls_peer *)c->tls_peer;
    if (!p) return;
    if (p->proto)  hv_stores(env, "SSL_PROTOCOL", newSVpv(p->proto, 0));
    if (p->cipher) hv_stores(env, "SSL_CIPHER",   newSVpv(p->cipher, 0));
    if (p->has_cert) {
        hv_stores(env, "SSL_CLIENT_VERIFY",
                  newSVpv(p->verified ? "SUCCESS" : "FAILED", 0));
        if (p->subject) hv_stores(env, "SSL_CLIENT_S_DN", newSVpv(p->subject, 0));
        if (p->issuer)  hv_stores(env, "SSL_CLIENT_I_DN", newSVpv(p->issuer, 0));
    } else {
        hv_stores(env, "SSL_CLIENT_VERIFY", newSVpvs("NONE"));
    }
}

/* Non-blocking read. >0 bytes, 0 = EOF/closed, -1 = error (errno==EAGAIN when
 * the TLS engine would block; c->tls_r_wants_w records a needed writable). */
static ssize_t hm_cread(hm_conn *c, void *buf, size_t n) {
    int r, e;
    if (!c->ssl) return read(c->fd, buf, n);
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
    if (!c->ssl) return write(c->fd, buf, n);
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

#else /* !HM_HAVE_OPENSSL */

#include <unistd.h>
static void *hm_tls_ctx_build(pTHX_ const char *cert, const char *key,
                              const char *ca, int verify, SV *sni, int alpn) {
    (void)cert; (void)key; (void)ca; (void)verify; (void)sni; (void)alpn;
    return 0;
}
static int  hm_tls_wrap(hm_conn *c, void *ctx) { (void)c; (void)ctx; return -1; }
static void hm_tls_capture_peer(hm_conn *c) { (void)c; }
static void hm_tls_conn_free(hm_conn *c) { (void)c; }
static void hm_tls_env(pTHX_ hm_conn *c, HV *env) { (void)c; (void)env; }
static ssize_t hm_cread(hm_conn *c, void *buf, size_t n)
    { return read(c->fd, buf, n); }
static ssize_t hm_cwrite(hm_conn *c, const void *buf, size_t n)
    { return write(c->fd, buf, n); }
static int  hm_tls_available(void) { return 0; }

#endif /* HM_HAVE_OPENSSL */

#endif /* HM_TLS_H */
