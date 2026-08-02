#ifndef FT_TLS_H
#define FT_TLS_H

/* Client-side TLS for Fetch: a shared client SSL_CTX, SNI, optional peer +
 * hostname verification, ALPN, and non-blocking handshake/read/write shims
 * that turn OpenSSL's WANT_READ/WANT_WRITE into a readiness direction the loop
 * can arm. Included from ft_http.h after the ft_conn struct is defined.
 *
 * When OpenSSL is absent (no -DFT_HAVE_OPENSSL) everything compiles to stubs
 * and starting a TLS request fails cleanly. */

#ifdef FT_HAVE_OPENSSL

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>
#include <limits.h>

/* one shared CTX per verify mode, built lazily */
static SSL_CTX *ft_client_ctx(int verify) {
    static SSL_CTX *ctx_v = NULL, *ctx_n = NULL;
    SSL_CTX **slot = verify ? &ctx_v : &ctx_n;
    if (!*slot) {
        SSL_CTX *c = SSL_CTX_new(TLS_client_method());
        if (!c) return NULL;
        SSL_CTX_set_min_proto_version(c, TLS1_2_VERSION);
        SSL_CTX_set_options(c, SSL_OP_NO_COMPRESSION);
        if (verify) {
            SSL_CTX_set_verify(c, SSL_VERIFY_PEER, NULL);
            SSL_CTX_set_default_verify_paths(c);
        } else {
            SSL_CTX_set_verify(c, SSL_VERIFY_NONE, NULL);
        }
        *slot = c;
    }
    return *slot;
}

/* Attach a client SSL to c->fd: SNI, ALPN (http/1.1), optional hostname
 * verification. Returns 0 on success, -1 on error. */
static int ft_tls_start(ft_conn *c, const char *host, int verify) {
    SSL_CTX *ctx = ft_client_ctx(verify);
    SSL     *ssl;
#ifdef FT_HAVE_NGHTTP2
    static const unsigned char alpn[] = { 2,'h','2', 8,'h','t','t','p','/','1','.','1' };
#else
    static const unsigned char alpn[] = { 8,'h','t','t','p','/','1','.','1' };
#endif
    if (!ctx) return -1;
    ssl = SSL_new(ctx);
    if (!ssl) return -1;
    SSL_set_fd(ssl, FT_SSL_FD(c->fd));   /* the real SOCKET on Windows */
    SSL_set_connect_state(ssl);
#ifdef SSL_set_tlsext_host_name
    SSL_set_tlsext_host_name(ssl, host);          /* SNI */
#else
    SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name,
             (void *)host);
#endif
    if (verify) {
        SSL_set1_host(ssl, host);                 /* verify cert matches host */
        SSL_set_hostflags(ssl, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
    }
    SSL_set_alpn_protos(ssl, alpn, sizeof(alpn));
    c->ssl = ssl;
    return 0;
}

/* Drive the handshake. 1 = complete, 0 = need more (sets *want to HM_EV_READ
 * or HM_EV_WRITE), -1 = error. */
static int ft_tls_handshake(ft_conn *c, int *want) {
    int r, e;
    ERR_clear_error();
    r = SSL_connect((SSL *)c->ssl);
    if (r == 1) return 1;
    e = SSL_get_error((SSL *)c->ssl, r);
    if (e == SSL_ERROR_WANT_READ)  { *want = HM_EV_READ;  return 0; }
    if (e == SSL_ERROR_WANT_WRITE) { *want = HM_EV_WRITE; return 0; }
    return -1;
}

/* Non-blocking TLS read/write. Return >0 bytes, 0 = clean close, -1 = error or
 * would-block (errno==EAGAIN, *want set to the needed readiness). */
static ssize_t ft_tls_read(ft_conn *c, void *buf, size_t n, int *want) {
    int r, e;
    ERR_clear_error();
    r = SSL_read((SSL *)c->ssl, buf, (int)(n > INT_MAX ? INT_MAX : n));
    if (r > 0) return r;
    e = SSL_get_error((SSL *)c->ssl, r);
    if (e == SSL_ERROR_ZERO_RETURN) return 0;
    if (e == SSL_ERROR_WANT_READ)  { *want = HM_EV_READ;  errno = EAGAIN; return -1; }
    if (e == SSL_ERROR_WANT_WRITE) { *want = HM_EV_WRITE; errno = EAGAIN; return -1; }
    errno = EIO;
    return -1;
}

static ssize_t ft_tls_write(ft_conn *c, const void *buf, size_t n, int *want) {
    int r, e;
    ERR_clear_error();
    r = SSL_write((SSL *)c->ssl, buf, (int)(n > INT_MAX ? INT_MAX : n));
    if (r > 0) return r;
    e = SSL_get_error((SSL *)c->ssl, r);
    if (e == SSL_ERROR_WANT_WRITE) { *want = HM_EV_WRITE; errno = EAGAIN; return -1; }
    if (e == SSL_ERROR_WANT_READ)  { *want = HM_EV_READ;  errno = EAGAIN; return -1; }
    errno = EIO;
    return -1;
}

/* true if ALPN negotiated "h2" on this connection */
static int ft_tls_is_h2(ft_conn *c) {
    const unsigned char *proto = NULL;
    unsigned int len = 0;
    if (!c->ssl) return 0;
    SSL_get0_alpn_selected((SSL *)c->ssl, &proto, &len);
    return len == 2 && proto && proto[0] == 'h' && proto[1] == '2';
}

static void ft_tls_free(ft_conn *c) {
    if (c->ssl) { SSL_free((SSL *)c->ssl); c->ssl = NULL; }
}

#define FT_TLS_AVAILABLE 1

#else  /* !FT_HAVE_OPENSSL: stubs */

static int ft_tls_is_h2(ft_conn *c) { (void)c; return 0; }

static int     ft_tls_start(ft_conn *c, const char *host, int v) { (void)c;(void)host;(void)v; return -1; }
static int     ft_tls_handshake(ft_conn *c, int *w) { (void)c;(void)w; return -1; }
static ssize_t ft_tls_read(ft_conn *c, void *b, size_t n, int *w) { (void)c;(void)b;(void)n;(void)w; return -1; }
static ssize_t ft_tls_write(ft_conn *c, const void *b, size_t n, int *w) { (void)c;(void)b;(void)n;(void)w; return -1; }
static void    ft_tls_free(ft_conn *c) { (void)c; }

#define FT_TLS_AVAILABLE 0

#endif

#endif /* FT_TLS_H */
