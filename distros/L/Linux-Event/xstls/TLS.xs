#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <arpa/inet.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/timerfd.h>

#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/x509_vfy.h>

#include "stream_transport_abi.h"

typedef struct let_server_config_s {
    unsigned char *alpn;
    unsigned int alpn_len;
    UV refs;
} let_server_config_t;

typedef struct let_tls_s {
    SSL_CTX *ctx;
    SSL *ssl;
    BIO_METHOD *bio_method;
    int fd;
    int role;
    int ready;
    int bound;
    int shutdown_sent;
    int deadline_fd;
    int deadline_phase;
    double handshake_timeout;
    double shutdown_timeout;
    unsigned char *alpn;
    unsigned int alpn_len;
    let_server_config_t *server_config;
    char error[512];
    unsigned long long handshake_calls;
    unsigned long long handshake_successes;
    unsigned long long read_calls;
    unsigned long long bytes_read;
    unsigned long long write_calls;
    unsigned long long writev_calls;
    unsigned long long bytes_written;
    unsigned long long shutdown_calls;
    unsigned long long want_read_count;
    unsigned long long want_write_count;
    unsigned long long interrupt_count;
    unsigned long long error_count;
    unsigned long long clean_eof_count;
    unsigned long long unclean_eof_count;
    unsigned long long handshake_timeout_count;
    unsigned long long shutdown_timeout_count;
} let_tls_t;

static int
let_bio_fd(BIO *bio)
{
    return (int)((intptr_t)BIO_get_data(bio) - 1);
}

static int
let_bio_create(BIO *bio)
{
    BIO_set_data(bio, NULL);
    BIO_set_init(bio, 0);
    BIO_set_shutdown(bio, BIO_NOCLOSE);
    return 1;
}

static int
let_bio_destroy(BIO *bio)
{
    if (!bio)
        return 0;
    BIO_set_data(bio, NULL);
    BIO_set_init(bio, 0);
    return 1;
}

static int
let_bio_read(BIO *bio, char *buffer, int length)
{
    ssize_t result;

    if (!buffer || length <= 0)
        return 0;
    BIO_clear_retry_flags(bio);
    result = recv(let_bio_fd(bio), buffer, (size_t)length, 0);
    if (result < 0 && (errno == EAGAIN || errno == EWOULDBLOCK))
        BIO_set_retry_read(bio);
    return (int)result;
}

static int
let_bio_write(BIO *bio, const char *buffer, int length)
{
    ssize_t result;

    if (!buffer || length <= 0)
        return 0;
    BIO_clear_retry_flags(bio);
    result = send(let_bio_fd(bio), buffer, (size_t)length, MSG_NOSIGNAL);
    if (result < 0 && (errno == EAGAIN || errno == EWOULDBLOCK))
        BIO_set_retry_write(bio);
    return (int)result;
}

static long
let_bio_ctrl(BIO *bio, int command, long argument, void *pointer)
{
    (void)argument;
    switch (command) {
    case BIO_C_GET_FD:
        if (pointer)
            *(int *)pointer = let_bio_fd(bio);
        return let_bio_fd(bio);
    case BIO_CTRL_GET_CLOSE:
        return BIO_NOCLOSE;
    case BIO_CTRL_SET_CLOSE:
    case BIO_CTRL_DUP:
    case BIO_CTRL_FLUSH:
        return 1;
    case BIO_CTRL_PENDING:
    case BIO_CTRL_WPENDING:
        return 0;
    default:
        return 0;
    }
}

static BIO_METHOD *
let_bio_method_new(void)
{
    BIO_METHOD *method = BIO_meth_new(BIO_TYPE_SOCKET,
        "Linux::Event::TLS no-SIGPIPE socket");

    if (!method)
        return NULL;
    if (!BIO_meth_set_create(method, let_bio_create)
        || !BIO_meth_set_destroy(method, let_bio_destroy)
        || !BIO_meth_set_read(method, let_bio_read)
        || !BIO_meth_set_write(method, let_bio_write)
        || !BIO_meth_set_ctrl(method, let_bio_ctrl)) {
        BIO_meth_free(method);
        return NULL;
    }
    return method;
}

static les_transport_result_t
let_result(int status, ssize_t count, int error)
{
    les_transport_result_t result;
    result.count = count;
    result.status = status;
    result.error = error;
    return result;
}

static void
let_set_error(let_tls_t *tls, const char *fallback)
{
    unsigned long code = ERR_get_error();
    if (code)
        ERR_error_string_n(code, tls->error, sizeof(tls->error));
    else if (errno)
        snprintf(tls->error, sizeof(tls->error), "%s: %s",
            fallback, strerror(errno));
    else
        snprintf(tls->error, sizeof(tls->error), "%s", fallback);
}

static les_transport_result_t
let_ssl_result(let_tls_t *tls, int return_value, const char *operation)
{
    int ssl_error = SSL_get_error(tls->ssl, return_value);
    unsigned long code;

    if (ssl_error == SSL_ERROR_WANT_READ) {
        tls->want_read_count++;
        return let_result(LES_TRANSPORT_WANT_READ, 0, 0);
    }
    if (ssl_error == SSL_ERROR_WANT_WRITE) {
        tls->want_write_count++;
        return let_result(LES_TRANSPORT_WANT_WRITE, 0, 0);
    }
    if (ssl_error == SSL_ERROR_ZERO_RETURN) {
        tls->clean_eof_count++;
        return let_result(LES_TRANSPORT_EOF, 0, 0);
    }
    if (ssl_error == SSL_ERROR_SYSCALL && errno == EINTR) {
        tls->interrupt_count++;
        return let_result(LES_TRANSPORT_INTERRUPT, 0, 0);
    }

    if (ssl_error == SSL_ERROR_SYSCALL && return_value == 0 && errno == 0) {
        tls->unclean_eof_count++;
        tls->error_count++;
        snprintf(tls->error, sizeof(tls->error),
            "TLS peer closed without close_notify");
        return let_result(LES_TRANSPORT_ERROR, 0, 0);
    }

    code = ERR_peek_last_error();
#ifdef SSL_R_UNEXPECTED_EOF_WHILE_READING
    if (ssl_error == SSL_ERROR_SSL && code
        && ERR_GET_REASON(code) == SSL_R_UNEXPECTED_EOF_WHILE_READING) {
        tls->unclean_eof_count++;
        tls->error_count++;
        snprintf(tls->error, sizeof(tls->error),
            "TLS peer closed without close_notify");
        ERR_clear_error();
        return let_result(LES_TRANSPORT_ERROR, 0, 0);
    }
#endif

    tls->error_count++;
    let_set_error(tls, operation);
    return let_result(LES_TRANSPORT_ERROR, 0,
        ssl_error == SSL_ERROR_SYSCALL ? errno : 0);
}

static les_transport_result_t
let_drive(void *context)
{
    let_tls_t *tls = (let_tls_t *)context;
    int result;

    if (tls->ready)
        return let_result(LES_TRANSPORT_OK, 0, 0);
    tls->handshake_calls++;
    ERR_clear_error();
    errno = 0;
    result = SSL_do_handshake(tls->ssl);
    if (result == 1) {
        tls->ready = 1;
        tls->handshake_successes++;
        tls->error[0] = '\0';
        return let_result(LES_TRANSPORT_OK, 0, 0);
    }
    return let_ssl_result(tls, result, "TLS handshake failed");
}

static les_transport_result_t
let_read(void *context, void *buffer, size_t length)
{
    let_tls_t *tls = (let_tls_t *)context;
    size_t read_count = 0;
    les_transport_result_t handshake;

    if (!tls->ready) {
        handshake = let_drive(tls);
        if (handshake.status != LES_TRANSPORT_OK)
            return handshake;
    }
    tls->read_calls++;
    ERR_clear_error();
    errno = 0;
    if (SSL_read_ex(tls->ssl, buffer, length, &read_count) == 1) {
        tls->bytes_read += (unsigned long long)read_count;
        return let_result(LES_TRANSPORT_OK, (ssize_t)read_count, 0);
    }
    return let_ssl_result(tls, 0, "TLS read failed");
}

static les_transport_result_t
let_write(void *context, const void *buffer, size_t length)
{
    let_tls_t *tls = (let_tls_t *)context;
    size_t written = 0;
    les_transport_result_t handshake;

    if (!tls->ready) {
        handshake = let_drive(tls);
        if (handshake.status != LES_TRANSPORT_OK)
            return handshake;
    }
    tls->write_calls++;
    ERR_clear_error();
    errno = 0;
    if (SSL_write_ex(tls->ssl, buffer, length, &written) == 1) {
        tls->bytes_written += (unsigned long long)written;
        return let_result(LES_TRANSPORT_OK, (ssize_t)written, 0);
    }
    return let_ssl_result(tls, 0, "TLS write failed");
}

static les_transport_result_t
let_writev(void *context, const struct iovec *vectors, int count)
{
    let_tls_t *tls = (let_tls_t *)context;
    int index;
    tls->writev_calls++;
    for (index = 0; index < count; index++) {
        if (vectors[index].iov_len)
            return let_write(context, vectors[index].iov_base,
                vectors[index].iov_len);
    }
    return let_result(LES_TRANSPORT_OK, 0, 0);
}

static les_transport_result_t
let_shutdown(void *context)
{
    let_tls_t *tls = (let_tls_t *)context;
    les_transport_result_t handshake;
    int result;

    if (tls->shutdown_sent)
        return let_result(LES_TRANSPORT_OK, 0, 0);
    tls->shutdown_calls++;
    if (!tls->ready) {
        handshake = let_drive(tls);
        if (handshake.status != LES_TRANSPORT_OK)
            return handshake;
    }
    ERR_clear_error();
    errno = 0;
    result = SSL_shutdown(tls->ssl);
    if (result >= 0) {
        tls->shutdown_sent = 1;
        return let_result(LES_TRANSPORT_OK, 0, 0);
    }
    return let_ssl_result(tls, result, "TLS shutdown failed");
}

static int let_is_ready(void *context)
{ return ((let_tls_t *)context)->ready; }

static const char *let_error_string(void *context)
{
    let_tls_t *tls = (let_tls_t *)context;
    return tls->error[0] ? tls->error : "TLS transport error";
}

static const les_transport_ops_t let_ops = {
    LES_TRANSPORT_ABI_VERSION,
    "tls",
    let_read,
    let_write,
    let_writev,
    let_shutdown,
    let_drive,
    let_is_ready,
    let_error_string
};

static let_tls_t *
let_from_sv(SV *object)
{
    if (!sv_isobject(object) || !SvROK(object))
        croak("not a Linux::Event::TLS object");
    return INT2PTR(let_tls_t *, SvIV((SV *)SvRV(object)));
}

static int
let_server_alpn_select(SSL *ssl, const unsigned char **out,
    unsigned char *outlen, const unsigned char *client, unsigned int client_len,
    void *argument)
{
    let_tls_t *tls = (let_tls_t *)argument;
    unsigned char *selected = NULL;
    unsigned char selected_len = 0;
    int result;
    (void)ssl;

    if (!tls->alpn_len)
        return SSL_TLSEXT_ERR_NOACK;
    result = SSL_select_next_proto(&selected, &selected_len,
        tls->alpn, tls->alpn_len, client, client_len);
    if (result != OPENSSL_NPN_NEGOTIATED)
        return SSL_TLSEXT_ERR_NOACK;
    *out = selected;
    *outlen = selected_len;
    return SSL_TLSEXT_ERR_OK;
}

static int
let_prepared_server_alpn_select(SSL *ssl, const unsigned char **out,
    unsigned char *outlen, const unsigned char *client, unsigned int client_len,
    void *argument)
{
    let_server_config_t *config = (let_server_config_t *)argument;
    unsigned char *selected = NULL;
    unsigned char selected_len = 0;
    int result;
    (void)ssl;

    if (!config || !config->alpn_len)
        return SSL_TLSEXT_ERR_NOACK;
    result = SSL_select_next_proto(&selected, &selected_len,
        config->alpn, config->alpn_len, client, client_len);
    if (result != OPENSSL_NPN_NEGOTIATED)
        return SSL_TLSEXT_ERR_NOACK;
    *out = selected;
    *outlen = selected_len;
    return SSL_TLSEXT_ERR_OK;
}

static void
let_copy_alpn(let_tls_t *tls, const unsigned char *alpn, STRLEN length)
{
    if (!length)
        return;
    tls->alpn = (unsigned char *)malloc((size_t)length);
    if (!tls->alpn)
        croak("malloc ALPN buffer failed");
    memcpy(tls->alpn, alpn, (size_t)length);
    tls->alpn_len = (unsigned int)length;
}

static let_server_config_t *
let_server_config_new(const unsigned char *alpn, STRLEN length)
{
    let_server_config_t *config;

    config = (let_server_config_t *)calloc(1, sizeof(*config));
    if (!config)
        return NULL;
    config->refs = 1;
    if (length) {
        config->alpn = (unsigned char *)malloc((size_t)length);
        if (!config->alpn) {
            free(config);
            return NULL;
        }
        memcpy(config->alpn, alpn, (size_t)length);
        config->alpn_len = (unsigned int)length;
    }
    return config;
}

static void
let_server_config_retain(let_server_config_t *config)
{
    if (!config)
        return;
    if (config->refs == (UV)-1)
        croak("TLS prepared server context reference overflow");
    config->refs++;
}

static void
let_server_config_release(let_server_config_t *config)
{
    if (!config)
        return;
    if (!config->refs)
        croak("TLS prepared server context reference underflow");
    config->refs--;
    if (!config->refs) {
        free(config->alpn);
        free(config);
    }
}

static void
let_close_deadline(let_tls_t *tls)
{
    if (tls->deadline_fd >= 0) {
        close(tls->deadline_fd);
        tls->deadline_fd = -1;
    }
    tls->deadline_phase = 0;
}

static void
let_disarm_deadline(let_tls_t *tls)
{
    struct itimerspec timer;
    if (tls->deadline_fd < 0)
        return;
    memset(&timer, 0, sizeof(timer));
    timerfd_settime(tls->deadline_fd, 0, &timer, NULL);
    tls->deadline_phase = 0;
}

static int
let_arm_deadline(let_tls_t *tls, int phase, double seconds)
{
    struct itimerspec timer;
    time_t whole;
    long nanos;

    if (seconds <= 0.0)
        return -1;

    if (tls->deadline_fd < 0) {
        tls->deadline_fd = timerfd_create(CLOCK_MONOTONIC,
            TFD_NONBLOCK | TFD_CLOEXEC);
        if (tls->deadline_fd < 0) {
            let_set_error(tls, "timerfd_create for TLS deadline failed");
            return -2;
        }
    }

    memset(&timer, 0, sizeof(timer));
    whole = (time_t)seconds;
    nanos = (long)((seconds - (double)whole) * 1000000000.0);
    if (whole == 0 && nanos == 0)
        nanos = 1;
    timer.it_value.tv_sec = whole;
    timer.it_value.tv_nsec = nanos;
    if (timerfd_settime(tls->deadline_fd, 0, &timer, NULL) != 0) {
        let_set_error(tls, "timerfd_settime for TLS deadline failed");
        let_close_deadline(tls);
        return -2;
    }
    tls->deadline_phase = phase;
    return tls->deadline_fd;
}

MODULE = Linux::Event::TLS    PACKAGE = Linux::Event::TLS
PROTOTYPES: DISABLE

SV *
_new_client(CLASS, server_name, verify, ca_file, ca_path, alpn_sv, handshake_timeout, shutdown_timeout)
    const char *CLASS
    const char *server_name
    int verify
    SV *ca_file
    SV *ca_path
    SV *alpn_sv
    NV handshake_timeout
    NV shutdown_timeout
  PREINIT:
    let_tls_t *tls;
    STRLEN alpn_len;
    const unsigned char *alpn;
    const char *ca_file_name = NULL;
    const char *ca_path_name = NULL;
    unsigned char address_bytes[sizeof(struct in6_addr)];
    int is_ip_address;
    int server_name_ok;
    char construction_error[512];
  CODE:
    tls = (let_tls_t *)calloc(1, sizeof(*tls));
    if (!tls) croak("calloc TLS provider failed");
    tls->fd = -1;
    tls->deadline_fd = -1;
    tls->role = 1;
    tls->handshake_timeout = (double)handshake_timeout;
    tls->shutdown_timeout = (double)shutdown_timeout;
    tls->ctx = SSL_CTX_new(TLS_client_method());
    if (!tls->ctx) {
        free(tls);
        croak("SSL_CTX_new client failed");
    }
    SSL_CTX_set_min_proto_version(tls->ctx, TLS1_2_VERSION);
    SSL_CTX_set_verify(tls->ctx, verify ? SSL_VERIFY_PEER : SSL_VERIFY_NONE, NULL);
    if (ca_file && SvOK(ca_file)) ca_file_name = SvPV_nolen(ca_file);
    if (ca_path && SvOK(ca_path)) ca_path_name = SvPV_nolen(ca_path);
    if (verify && ((ca_file_name || ca_path_name)
        ? SSL_CTX_load_verify_locations(tls->ctx, ca_file_name, ca_path_name) != 1
        : SSL_CTX_set_default_verify_paths(tls->ctx) != 1)) {
        let_set_error(tls, "failed to load TLS trust roots");
        snprintf(construction_error, sizeof(construction_error), "%s", tls->error);
        SSL_CTX_free(tls->ctx);
        free(tls);
        croak("%s", construction_error);
    }
    tls->ssl = SSL_new(tls->ctx);
    if (!tls->ssl) {
        SSL_CTX_free(tls->ctx);
        free(tls);
        croak("SSL_new client failed");
    }
    SSL_set_mode(tls->ssl,
        SSL_MODE_ENABLE_PARTIAL_WRITE | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
    is_ip_address = inet_pton(AF_INET, server_name, address_bytes) == 1
        || inet_pton(AF_INET6, server_name, address_bytes) == 1;
    if (is_ip_address) {
        server_name_ok = !verify
            || X509_VERIFY_PARAM_set1_ip_asc(
                SSL_get0_param(tls->ssl), server_name) == 1;
    } else {
        server_name_ok = SSL_set_tlsext_host_name(tls->ssl, server_name) == 1
            && (!verify || SSL_set1_host(tls->ssl, server_name) == 1);
    }
    if (!server_name_ok) {
        let_set_error(tls, "failed to configure TLS server name");
        snprintf(construction_error, sizeof(construction_error), "%s", tls->error);
        SSL_free(tls->ssl);
        SSL_CTX_free(tls->ctx);
        free(tls);
        croak("%s", construction_error);
    }
    alpn = (const unsigned char *)SvPVbyte(alpn_sv, alpn_len);
    let_copy_alpn(tls, alpn, alpn_len);
    if (tls->alpn_len
        && SSL_set_alpn_protos(tls->ssl, tls->alpn, tls->alpn_len) != 0) {
        SSL_free(tls->ssl);
        SSL_CTX_free(tls->ctx);
        free(tls->alpn);
        free(tls);
        croak("failed to configure client ALPN");
    }
    SSL_set_connect_state(tls->ssl);
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)tls);
  OUTPUT:
    RETVAL

SV *
_new_server(CLASS, cert_file, key_file, alpn_sv, handshake_timeout, shutdown_timeout)
    const char *CLASS
    const char *cert_file
    const char *key_file
    SV *alpn_sv
    NV handshake_timeout
    NV shutdown_timeout
  PREINIT:
    let_tls_t *tls;
    STRLEN alpn_len;
    const unsigned char *alpn;
    char construction_error[512];
  CODE:
    tls = (let_tls_t *)calloc(1, sizeof(*tls));
    if (!tls) croak("calloc TLS provider failed");
    tls->fd = -1;
    tls->deadline_fd = -1;
    tls->role = 2;
    tls->handshake_timeout = (double)handshake_timeout;
    tls->shutdown_timeout = (double)shutdown_timeout;
    tls->ctx = SSL_CTX_new(TLS_server_method());
    if (!tls->ctx) {
        free(tls);
        croak("SSL_CTX_new server failed");
    }
    SSL_CTX_set_min_proto_version(tls->ctx, TLS1_2_VERSION);
    if (SSL_CTX_use_certificate_chain_file(tls->ctx, cert_file) != 1
        || SSL_CTX_use_PrivateKey_file(tls->ctx, key_file,
            SSL_FILETYPE_PEM) != 1
        || SSL_CTX_check_private_key(tls->ctx) != 1) {
        let_set_error(tls, "failed to load TLS server identity");
        snprintf(construction_error, sizeof(construction_error), "%s", tls->error);
        SSL_CTX_free(tls->ctx);
        free(tls);
        croak("%s", construction_error);
    }
    alpn = (const unsigned char *)SvPVbyte(alpn_sv, alpn_len);
    let_copy_alpn(tls, alpn, alpn_len);
    if (tls->alpn_len)
        SSL_CTX_set_alpn_select_cb(tls->ctx, let_server_alpn_select, tls);
    tls->ssl = SSL_new(tls->ctx);
    if (!tls->ssl) {
        SSL_CTX_free(tls->ctx);
        free(tls->alpn);
        free(tls);
        croak("SSL_new server failed");
    }
    SSL_set_mode(tls->ssl,
        SSL_MODE_ENABLE_PARTIAL_WRITE | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
    SSL_set_accept_state(tls->ssl);
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)tls);
  OUTPUT:
    RETVAL

SV *
_new_server_template(CLASS, cert_file, key_file, alpn_sv, handshake_timeout, shutdown_timeout)
    const char *CLASS
    const char *cert_file
    const char *key_file
    SV *alpn_sv
    NV handshake_timeout
    NV shutdown_timeout
  PREINIT:
    let_tls_t *tls;
    let_server_config_t *config;
    STRLEN alpn_len;
    const unsigned char *alpn;
    char construction_error[512];
  CODE:
    tls = (let_tls_t *)calloc(1, sizeof(*tls));
    if (!tls) croak("calloc TLS server template failed");
    tls->fd = -1;
    tls->deadline_fd = -1;
    tls->role = 2;
    tls->handshake_timeout = (double)handshake_timeout;
    tls->shutdown_timeout = (double)shutdown_timeout;
    tls->ctx = SSL_CTX_new(TLS_server_method());
    if (!tls->ctx) {
        free(tls);
        croak("SSL_CTX_new prepared server failed");
    }
    SSL_CTX_set_min_proto_version(tls->ctx, TLS1_2_VERSION);
    if (SSL_CTX_use_certificate_chain_file(tls->ctx, cert_file) != 1
        || SSL_CTX_use_PrivateKey_file(tls->ctx, key_file,
            SSL_FILETYPE_PEM) != 1
        || SSL_CTX_check_private_key(tls->ctx) != 1) {
        let_set_error(tls, "failed to load prepared TLS server identity");
        snprintf(construction_error, sizeof(construction_error), "%s", tls->error);
        SSL_CTX_free(tls->ctx);
        free(tls);
        croak("%s", construction_error);
    }
    alpn = (const unsigned char *)SvPVbyte(alpn_sv, alpn_len);
    config = let_server_config_new(alpn, alpn_len);
    if (!config) {
        SSL_CTX_free(tls->ctx);
        free(tls);
        croak("malloc prepared TLS server configuration failed");
    }
    tls->server_config = config;
    if (config->alpn_len)
        SSL_CTX_set_alpn_select_cb(tls->ctx,
            let_prepared_server_alpn_select, config);
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)tls);
  OUTPUT:
    RETVAL

SV *
_clone_server(object)
    SV *object
  PREINIT:
    let_tls_t *template;
    let_tls_t *tls;
  CODE:
    template = let_from_sv(object);
    if (!template || !template->ctx || template->role != 2
        || template->ssl || !template->server_config)
        croak("not a prepared Linux::Event TLS server context");
    tls = (let_tls_t *)calloc(1, sizeof(*tls));
    if (!tls) croak("calloc TLS server connection failed");
    tls->fd = -1;
    tls->deadline_fd = -1;
    tls->role = 2;
    tls->handshake_timeout = template->handshake_timeout;
    tls->shutdown_timeout = template->shutdown_timeout;
    if (SSL_CTX_up_ref(template->ctx) != 1) {
        free(tls);
        croak("SSL_CTX_up_ref prepared server failed");
    }
    tls->ctx = template->ctx;
    tls->server_config = template->server_config;
    let_server_config_retain(tls->server_config);
    tls->ssl = SSL_new(tls->ctx);
    if (!tls->ssl) {
        SSL_CTX_free(tls->ctx);
        let_server_config_release(tls->server_config);
        free(tls);
        croak("SSL_new prepared server connection failed");
    }
    SSL_set_mode(tls->ssl,
        SSL_MODE_ENABLE_PARTIAL_WRITE | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
    SSL_set_accept_state(tls->ssl);
    RETVAL = sv_setref_pv(newSV(0), "Linux::Event::TLS", (void *)tls);
  OUTPUT:
    RETVAL

void
_bind_fd(object, fd)
    SV *object
    int fd
  PREINIT:
    let_tls_t *tls;
    BIO *bio;
  PPCODE:
    tls = let_from_sv(object);
    if (!tls) croak("TLS provider is closed");
    if (!tls->ssl) croak("prepared TLS server context cannot be bound directly");
    if (tls->bound) croak("TLS provider is already bound to a Stream");
    if (fd < 0) croak("TLS file descriptor must be >= 0");
    tls->bio_method = let_bio_method_new();
    if (!tls->bio_method) {
        let_set_error(tls, "creating TLS socket BIO method failed");
        croak("%s", tls->error);
    }
    bio = BIO_new(tls->bio_method);
    if (!bio) {
        let_set_error(tls, "creating TLS socket BIO failed");
        BIO_meth_free(tls->bio_method);
        tls->bio_method = NULL;
        croak("%s", tls->error);
    }
    BIO_set_data(bio, (void *)(intptr_t)(fd + 1));
    BIO_set_init(bio, 1);
    BIO_set_shutdown(bio, BIO_NOCLOSE);
    SSL_set_bio(tls->ssl, bio, bio);
    tls->fd = fd;
    tls->bound = 1;
    EXTEND(SP, 4);
    PUSHs(sv_2mortal(newSVuv(LES_TRANSPORT_ABI_VERSION)));
    PUSHs(sv_2mortal(newSVuv(PTR2UV(&let_ops))));
    PUSHs(sv_2mortal(newSVuv(PTR2UV(tls))));
    PUSHs(sv_2mortal(newSViv(tls->role == 1 ? 2 : 1)));

SV *
_arm_deadline(object, operation)
    SV *object
    const char *operation
  PREINIT:
    let_tls_t *tls;
    int phase;
    int fd;
    double seconds;
  CODE:
    tls = let_from_sv(object);
    if (!tls) croak("TLS provider is closed");
    if (strcmp(operation, "handshake") == 0) {
        phase = 1;
        seconds = tls->handshake_timeout;
    } else if (strcmp(operation, "shutdown") == 0) {
        phase = 2;
        seconds = tls->shutdown_timeout;
    } else {
        croak("unknown TLS deadline operation '%s'", operation);
    }
    fd = let_arm_deadline(tls, phase, seconds);
    if (fd == -2) croak("%s", tls->error);
    RETVAL = fd < 0 ? &PL_sv_undef : newSViv(fd);
  OUTPUT:
    RETVAL

const char *
_deadline_operation(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
  CODE:
    tls = let_from_sv(object);
    if (!tls || tls->deadline_phase == 0)
        croak("TLS deadline is not active");
    RETVAL = tls->deadline_phase == 1 ? "handshake" : "shutdown";
  OUTPUT:
    RETVAL

SV *
_consume_deadline(object, operation)
    SV *object
    const char *operation
  PREINIT:
    let_tls_t *tls;
    uint64_t expirations = 0;
    int expected_phase;
  CODE:
    tls = let_from_sv(object);
    if (!tls) croak("TLS provider is closed");
    expected_phase = strcmp(operation, "handshake") == 0 ? 1
        : strcmp(operation, "shutdown") == 0 ? 2 : 0;
    if (!expected_phase) croak("unknown TLS deadline operation '%s'", operation);
    if (tls->deadline_fd < 0 || tls->deadline_phase != expected_phase)
        croak("TLS %s deadline is not active", operation);
    if (read(tls->deadline_fd, &expirations, sizeof(expirations)) < 0
        && errno != EAGAIN)
        let_set_error(tls, "reading TLS deadline failed");
    tls->deadline_phase = 0;
    if (expected_phase == 1) {
        tls->handshake_timeout_count++;
        snprintf(tls->error, sizeof(tls->error), "TLS handshake timed out");
    } else {
        tls->shutdown_timeout_count++;
        snprintf(tls->error, sizeof(tls->error), "TLS shutdown timed out");
    }
    RETVAL = newSVpv(tls->error, 0);
  OUTPUT:
    RETVAL

void
_cancel_deadline(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
  CODE:
    tls = let_from_sv(object);
    if (tls) let_disarm_deadline(tls);

void
_close_deadline(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
  CODE:
    tls = let_from_sv(object);
    if (tls) let_close_deadline(tls);

SV *
selected_alpn(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
    const unsigned char *selected = NULL;
    unsigned int length = 0;
  CODE:
    tls = let_from_sv(object);
    if (!tls || !tls->ssl || !tls->ready) {
        RETVAL = &PL_sv_undef;
    } else {
        SSL_get0_alpn_selected(tls->ssl, &selected, &length);
        RETVAL = length ? newSVpvn((const char *)selected, length)
                        : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
protocol(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
    const char *name;
  CODE:
    tls = let_from_sv(object);
    name = tls && tls->ssl && tls->ready ? SSL_get_version(tls->ssl) : NULL;
    RETVAL = name ? newSVpv(name, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
cipher(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
    const char *name;
  CODE:
    tls = let_from_sv(object);
    name = tls && tls->ssl && tls->ready ? SSL_get_cipher_name(tls->ssl) : NULL;
    RETVAL = name ? newSVpv(name, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
    HV *hv;
  CODE:
    tls = let_from_sv(object);
    hv = newHV();
    hv_stores(hv, "handshake_calls", newSVuv(tls->handshake_calls));
    hv_stores(hv, "handshake_successes", newSVuv(tls->handshake_successes));
    hv_stores(hv, "read_calls", newSVuv(tls->read_calls));
    hv_stores(hv, "bytes_read", newSVuv(tls->bytes_read));
    hv_stores(hv, "write_calls", newSVuv(tls->write_calls));
    hv_stores(hv, "writev_calls", newSVuv(tls->writev_calls));
    hv_stores(hv, "bytes_written", newSVuv(tls->bytes_written));
    hv_stores(hv, "shutdown_calls", newSVuv(tls->shutdown_calls));
    hv_stores(hv, "want_read_count", newSVuv(tls->want_read_count));
    hv_stores(hv, "want_write_count", newSVuv(tls->want_write_count));
    hv_stores(hv, "interrupt_count", newSVuv(tls->interrupt_count));
    hv_stores(hv, "error_count", newSVuv(tls->error_count));
    hv_stores(hv, "clean_eof_count", newSVuv(tls->clean_eof_count));
    hv_stores(hv, "unclean_eof_count", newSVuv(tls->unclean_eof_count));
    hv_stores(hv, "handshake_timeout_count", newSVuv(tls->handshake_timeout_count));
    hv_stores(hv, "shutdown_timeout_count", newSVuv(tls->shutdown_timeout_count));
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

void
DESTROY(object)
    SV *object
  PREINIT:
    let_tls_t *tls;
  CODE:
    tls = let_from_sv(object);
    if (tls) {
        let_close_deadline(tls);
        if (tls->ssl) SSL_free(tls->ssl);
        if (tls->bio_method) BIO_meth_free(tls->bio_method);
        if (tls->ctx) SSL_CTX_free(tls->ctx);
        free(tls->alpn);
        let_server_config_release(tls->server_config);
        free(tls);
        sv_setiv(SvRV(object), 0);
    }
