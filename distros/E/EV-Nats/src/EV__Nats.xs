#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"
#include "ngx-queue.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <arpa/inet.h>

#ifdef HAVE_OPENSSL
  #include <openssl/ssl.h>
  #include <openssl/err.h>
  #include <openssl/x509v3.h>
#endif

/* ================================================================
 * Constants
 * ================================================================ */

#define NATS_MAGIC_ALIVE 0xCA5E4A75

#define BUF_INIT_SIZE  16384
#define MAX_CONTROL_LINE 4096

#define DEFAULT_MAX_PAYLOAD (1024 * 1024)

#define PARSE_OP       0
#define PARSE_MSG_BODY 1

#define MSG_TYPE_MSG   0
#define MSG_TYPE_HMSG  1

#define CLEAR_HANDLER(field) \
    do { if (NULL != (field)) { SvREFCNT_dec(field); (field) = NULL; } } while(0)

#define NATS_CROAK_UNLESS_CONNECTED(self) \
    do { \
        if (!(self)->connected && !(self)->connecting && \
            !((self)->reconnect_enabled && (self)->reconnect_timer_active)) \
            croak("not connected"); \
    } while(0)

/* ================================================================
 * Type declarations
 * ================================================================ */

typedef struct nats_s       nats_t;
typedef struct nats_sub_s   nats_sub_t;
typedef struct nats_pub_s   nats_pub_t;

typedef nats_t* EV__Nats;
typedef struct ev_loop* EV__Loop;

/* ================================================================
 * Data structures
 * ================================================================ */

struct nats_sub_s {
    uint64_t sid;
    SV *subject;
    SV *queue_group;
    SV *cb;
    int max_msgs;
    int received;
    ngx_queue_t queue;
};

/* PONG callback entry (for flush) */
typedef struct nats_pong_cb_s {
    SV *cb;
    ngx_queue_t queue;
} nats_pong_cb_t;

/* Server pool entry (parsed from INFO connect_urls) */
typedef struct nats_server_s {
    char *host;
    int port;
    ngx_queue_t queue;
} nats_server_t;

struct nats_pub_s {
    char *data;
    size_t len;
    ngx_queue_t queue;
};

struct nats_s {
    unsigned int magic;
    struct ev_loop *loop;
    int fd;
    int connected;
    int connecting;

    ev_io rio, wio;
    int reading, writing;

    char *rbuf;
    size_t rbuf_len, rbuf_cap;

    char *wbuf;
    size_t wbuf_len, wbuf_off, wbuf_cap;

    SV *on_error;
    SV *on_connect;
    SV *on_disconnect;

    ngx_queue_t subs;
    HV *sub_map;            /* SID -> nats_sub_t* hash for O(1) lookup */
    uint64_t next_sid;

    ngx_queue_t wait_queue;
    int waiting_count;

    /* Write coalescing */
    ev_prepare prepare_watcher;
    int prepare_active;
    int wbuf_dirty;

    char *host;
    int port;
    char *path; /* Unix socket path */

    int reconnect_enabled;
    int reconnect_delay_ms;
    int max_reconnect_delay_ms;
    int max_reconnect_attempts;
    int reconnect_attempts;
    ev_timer reconnect_timer;
    int reconnect_timer_active;
    int intentional_disconnect;

    int connect_timeout_ms;
    ev_timer connect_timer;
    int connect_timer_active;

    int ping_interval_ms;
    ev_timer ping_timer;
    int ping_timer_active;
    int pings_outstanding;
    int max_pings_outstanding;

    int max_payload;
    SV *server_info_json;

    char *user;
    char *pass;
    char *token;
    char *name;
    int verbose;
    int pedantic;
    int echo;
    int no_responders;

    char inbox_prefix[32];
    uint64_t next_req_id;
    ngx_queue_t req_queue;
    uint64_t inbox_sub_sid;

    int parse_state;
    int msg_type;
    /* MSG/HMSG fields: absolute offsets into rbuf (safe across Renew) */
    size_t msg_subject_off;
    size_t msg_subject_len;
    size_t msg_reply_off;       /* msg_reply_len == 0 means no reply */
    size_t msg_reply_len;
    uint64_t msg_sid;
    size_t msg_hdr_len;
    size_t msg_total_len;

    int priority;
    int keepalive;

    /* Stats */
    UV msgs_in;
    UV msgs_out;
    UV bytes_in;
    UV bytes_out;

    /* Server pool for cluster failover */
    ngx_queue_t server_pool;
    int server_pool_count;

    /* Drain state */
    int draining;
    SV *drain_cb;

    /* Slow consumer detection */
    size_t slow_consumer_bytes;  /* wbuf threshold, 0 = disabled */
    SV *on_slow_consumer;

    /* Batch mode */
    int batch_mode;

    /* PONG callback queue (for flush) */
    ngx_queue_t pong_cbs;

    /* NKey auth */
    char *nkey_seed;     /* Ed25519 seed (base32-encoded) */
    char *jwt;
    char *server_nonce;  /* nonce from INFO for signing */

    /* Lame duck mode (leaf node graceful shutdown) */
    int ldm;
    SV *on_ldm;

    /* TLS */
#ifdef HAVE_OPENSSL
    SSL_CTX *ssl_ctx;
    SSL     *ssl;
    int tls;
    int tls_skip_verify;
    char *tls_ca_file;
    int ssl_handshaking;
#endif
};

typedef struct nats_req_s {
    uint64_t req_id;
    SV *cb;
    ev_timer timer;
    int timer_active;
    nats_t *self;
    ngx_queue_t queue;
} nats_req_t;

/* ================================================================
 * Forward declarations
 * ================================================================ */

static void nats_connect_tcp(nats_t *self);
static void nats_connect_unix(nats_t *self);
static void nats_do_connect(nats_t *self);
static void nats_schedule_reconnect(nats_t *self);
static void nats_next_server(nats_t *self);
static void nats_free_server_pool(nats_t *self);
static void nats_on_read(struct ev_loop *loop, ev_io *w, int revents);
static void nats_on_prepare(struct ev_loop *loop, ev_prepare *w, int revents);
static void nats_parse_connect_urls(nats_t *self, const char *json, size_t len);
static void nats_on_write(struct ev_loop *loop, ev_io *w, int revents);
static void nats_on_connect_timeout(struct ev_loop *loop, ev_timer *w, int revents);
static void nats_on_reconnect_timer(struct ev_loop *loop, ev_timer *w, int revents);
static void nats_on_ping_timer(struct ev_loop *loop, ev_timer *w, int revents);
static void nats_send_connect(nats_t *self);
static void nats_try_write(nats_t *self);
static void nats_process_line(nats_t *self, char *line, size_t len);
static void nats_process_msg(nats_t *self, char *payload, size_t len);
static void nats_emit_error(nats_t *self, const char *err);
static void nats_cleanup(nats_t *self);
static void nats_start_ping_timer(nats_t *self);
static void nats_drain_waiting(nats_t *self);
static void nats_setup_inbox(nats_t *self);
static nats_sub_t *nats_find_sub(nats_t *self, uint64_t sid);
static void nats_remove_sub(nats_t *self, nats_sub_t *sub);
static void nats_cancel_all_requests(nats_t *self, const char *err);
static void nats_resub_all(nats_t *self);

/* ================================================================
 * String helpers
 * ================================================================ */

/* Replace *dst with a fresh copy of NUL-terminated src; frees existing. */
static void nats_set_str(char **dst, const char *src)
{
    if (*dst) { Safefree(*dst); *dst = NULL; }
    if (src) {
        size_t l = strlen(src);
        Newx(*dst, l + 1, char);
        memcpy(*dst, src, l + 1);
    }
}

/* Replace *dst with a copy of an SV's bytes (handles non-NUL-terminated PV). */
static void nats_set_str_sv(char **dst, SV *val)
{
    STRLEN l;
    const char *s = SvPV(val, l);
    if (*dst) { Safefree(*dst); *dst = NULL; }
    Newx(*dst, l + 1, char);
    memcpy(*dst, s, l);
    (*dst)[l] = '\0';
}

/* ================================================================
 * Buffer helpers
 * ================================================================ */

static void buf_ensure(char **buf, size_t *cap, size_t needed)
{
    if (needed <= *cap)
        return;
    size_t newcap = *cap ? *cap : BUF_INIT_SIZE;
    while (newcap < needed)
        newcap *= 2;
    Renew(*buf, newcap, char);
    *cap = newcap;
}

static void wbuf_append(nats_t *self, const char *data, size_t len)
{
    size_t used = self->wbuf_len - self->wbuf_off;
    if (self->wbuf_off > 0 && self->wbuf_off > self->wbuf_len / 2) {
        if (used > 0)
            memmove(self->wbuf, self->wbuf + self->wbuf_off, used);
        self->wbuf_len = used;
        self->wbuf_off = 0;
    }
    buf_ensure(&self->wbuf, &self->wbuf_cap, self->wbuf_len + len);
    memcpy(self->wbuf + self->wbuf_len, data, len);
    self->wbuf_len += len;
}

/* ================================================================
 * NKey helpers (base32 + Ed25519)
 * ================================================================ */

#ifdef HAVE_OPENSSL
#include <openssl/evp.h>

/* NATS base32 decode (RFC 4648, no padding) */
static int nats_base32_decode(const char *src, size_t src_len, unsigned char *dst, size_t *dst_len)
{
    static const int8_t b32_tab[128] = {
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,26,27,28,29,30,31,-1,-1,-1,-1,-1,-1,-1,-1,  /* 2-7 */
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,  /* A-O */
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,   /* P-Z */
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,  /* a-o */
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,   /* p-z */
    };
    uint64_t buf = 0;
    int bits = 0;
    size_t di = 0;
    size_t i;

    for (i = 0; i < src_len; i++) {
        unsigned char c = (unsigned char)src[i];
        if (c == '=' || c == ' ') continue;
        if (c >= 128 || b32_tab[c] < 0) return -1;
        buf = (buf << 5) | b32_tab[c];
        bits += 5;
        if (bits >= 8) {
            bits -= 8;
            dst[di++] = (unsigned char)(buf >> bits);
        }
    }
    *dst_len = di;
    return 0;
}

/* NATS base32 encode (RFC 4648, no padding). Streams 8-bit input through
   a 5-bit accumulator. Returns number of chars written, or -1 if dst is
   too small. */
static int nats_base32_encode(const unsigned char *src, size_t src_len,
                              char *dst, size_t dst_size)
{
    static const char b32[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    size_t di = 0;
    uint64_t buf = 0;
    int bits = 0;
    size_t i;
    for (i = 0; i < src_len; i++) {
        buf = (buf << 8) | src[i];
        bits += 8;
        while (bits >= 5) {
            if (di >= dst_size) return -1;
            bits -= 5;
            dst[di++] = b32[(buf >> bits) & 0x1F];
        }
    }
    if (bits > 0) {
        if (di >= dst_size) return -1;
        dst[di++] = b32[(buf << (5 - bits)) & 0x1F];
    }
    return (int)di;
}

/* NATS base64url encode (no padding) */
static int nats_base64url_encode(const unsigned char *src, size_t src_len, char *dst, size_t dst_size)
{
    static const char b64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    size_t di = 0;
    size_t i;
    for (i = 0; i + 2 < src_len; i += 3) {
        if (di + 4 > dst_size) return -1;
        uint32_t v = ((uint32_t)src[i] << 16) | ((uint32_t)src[i+1] << 8) | src[i+2];
        dst[di++] = b64[(v >> 18) & 0x3F];
        dst[di++] = b64[(v >> 12) & 0x3F];
        dst[di++] = b64[(v >>  6) & 0x3F];
        dst[di++] = b64[v & 0x3F];
    }
    if (i < src_len) {
        if (di + 4 > dst_size) return -1;
        uint32_t v = (uint32_t)src[i] << 16;
        if (i + 1 < src_len) v |= (uint32_t)src[i+1] << 8;
        dst[di++] = b64[(v >> 18) & 0x3F];
        dst[di++] = b64[(v >> 12) & 0x3F];
        if (i + 1 < src_len) dst[di++] = b64[(v >> 6) & 0x3F];
    }
    if (di < dst_size) dst[di] = '\0';
    return (int)di;
}

/* CRC-16/XMODEM (CRC-CCITT, poly 0x1021, init 0x0000) — what NATS NKeys
   use. NOT CRC-16/IBM. Used for seed/pubkey integrity. */
static uint16_t nats_crc16(const unsigned char *data, size_t len)
{
    uint16_t crc = 0;
    size_t i;
    int j;
    for (i = 0; i < len; i++) {
        crc ^= ((uint16_t)data[i]) << 8;
        for (j = 0; j < 8; j++) {
            if (crc & 0x8000) crc = (uint16_t)((crc << 1) ^ 0x1021);
            else crc = (uint16_t)(crc << 1);
        }
    }
    return crc;
}

static int nats_nkey_sign(const char *seed_encoded, const char *nonce, size_t nonce_len,
                          char *sig_out, size_t sig_out_size)
{
    unsigned char raw[64];
    size_t raw_len = 0;

    if (nats_base32_decode(seed_encoded, strlen(seed_encoded), raw, &raw_len) != 0)
        return -1;
    if (raw_len < 36) return -1; /* prefix(2) + seed(32) + CRC(2) */

    /* Validate CRC16 */
    uint16_t expected_crc = (uint16_t)raw[raw_len - 2] | ((uint16_t)raw[raw_len - 1] << 8);
    uint16_t actual_crc = nats_crc16(raw, raw_len - 2);
    if (expected_crc != actual_crc) return -1;

    unsigned char *seed = raw + 2;

    EVP_PKEY *pkey = EVP_PKEY_new_raw_private_key(EVP_PKEY_ED25519, NULL, seed, 32);
    if (!pkey) return -1;

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    if (!ctx) { EVP_PKEY_free(pkey); return -1; }

    unsigned char sig[64];
    size_t sig_len = sizeof(sig);

    int ok = (EVP_DigestSignInit(ctx, NULL, NULL, NULL, pkey) == 1 &&
              EVP_DigestSign(ctx, sig, &sig_len, (const unsigned char *)nonce, nonce_len) == 1);

    EVP_MD_CTX_free(ctx);
    EVP_PKEY_free(pkey);

    if (!ok) return -1;

    return nats_base64url_encode(sig, sig_len, sig_out, sig_out_size);
}

static int nats_nkey_public(const char *seed_encoded, char *pub_out, size_t pub_out_size)
{
    unsigned char raw[64];
    size_t raw_len = 0;

    if (nats_base32_decode(seed_encoded, strlen(seed_encoded), raw, &raw_len) != 0)
        return -1;
    if (raw_len < 36) return -1;

    uint16_t expected_crc = (uint16_t)raw[raw_len - 2] | ((uint16_t)raw[raw_len - 1] << 8);
    if (nats_crc16(raw, raw_len - 2) != expected_crc) return -1;

    unsigned char *seed = raw + 2;

    EVP_PKEY *pkey = EVP_PKEY_new_raw_private_key(EVP_PKEY_ED25519, NULL, seed, 32);
    if (!pkey) return -1;

    unsigned char pub[32];
    size_t pub_len = 32;
    int ok = EVP_PKEY_get_raw_public_key(pkey, pub, &pub_len) == 1;
    EVP_PKEY_free(pkey);
    if (!ok) return -1;

    /* Derive public-key prefix from the role embedded in the seed prefix.
       Seed encoding (NATS Go nkeys EncodeSeed):
           raw[0] = PrefixByteSeed | (role >> 5)
           raw[1] = (role & 31) << 3
       so role = ((raw[0] & 7) << 5) | (raw[1] >> 3). */
    unsigned char role = (unsigned char)(((raw[0] & 0x07) << 5) | (raw[1] >> 3));
    unsigned char pub_prefix;
    switch (role) {
        case 0xA0: pub_prefix = 0xA0; break; /* User */
        case 0x70: pub_prefix = 0x70; break; /* Operator */
        case 0x00: pub_prefix = 0x00; break; /* Account */
        default:   pub_prefix = 0xA0; break; /* default to User */
    }

    /* Build: prefix(1) + pubkey(32) + CRC16(2) = 35 bytes */
    unsigned char full[35];
    full[0] = pub_prefix;
    memcpy(full + 1, pub, 32);
    uint16_t crc = nats_crc16(full, 33);
    full[33] = crc & 0xFF;
    full[34] = (crc >> 8) & 0xFF;

    /* Base32 encode 35 bytes -> 56 chars (35*8 = 280 bits, 280/5 = 56). */
    int n = nats_base32_encode(full, sizeof(full), pub_out,
                               pub_out_size > 0 ? pub_out_size - 1 : 0);
    if (n < 0) return -1;
    if ((size_t)n < pub_out_size) pub_out[n] = '\0';
    return n;
}
#endif

/* ================================================================
 * I/O helpers (with optional TLS)
 * ================================================================ */

static ssize_t nats_io_read(nats_t *self, void *buf, size_t len)
{
#ifdef HAVE_OPENSSL
    if (self->ssl) {
        int n = SSL_read(self->ssl, buf, (len > (size_t)INT_MAX) ? INT_MAX : (int)len);
        if (n <= 0) {
            int err = SSL_get_error(self->ssl, n);
            if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
                errno = EAGAIN;
                return -1;
            }
            if (err == SSL_ERROR_ZERO_RETURN) return 0;
            errno = EIO;
            return -1;
        }
        return n;
    }
#endif
    return read(self->fd, buf, len);
}

static ssize_t nats_io_write(nats_t *self, const void *buf, size_t len)
{
#ifdef HAVE_OPENSSL
    if (self->ssl) {
        int n = SSL_write(self->ssl, buf, (len > (size_t)INT_MAX) ? INT_MAX : (int)len);
        if (n <= 0) {
            int err = SSL_get_error(self->ssl, n);
            if (err == SSL_ERROR_WANT_WRITE || err == SSL_ERROR_WANT_READ) {
                errno = EAGAIN;
                return -1;
            }
            errno = EIO;
            return -1;
        }
        return n;
    }
#endif
    return write(self->fd, buf, len);
}

#ifdef HAVE_OPENSSL
static int nats_ssl_setup(nats_t *self)
{
    if (!self->ssl_ctx) {
        self->ssl_ctx = SSL_CTX_new(TLS_client_method());
        if (!self->ssl_ctx) return -1;

        if (self->tls_ca_file) {
            if (!SSL_CTX_load_verify_locations(self->ssl_ctx, self->tls_ca_file, NULL))
                return -1;
        } else {
            SSL_CTX_set_default_verify_paths(self->ssl_ctx);
        }

        if (!self->tls_skip_verify)
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_PEER, NULL);
    }

    self->ssl = SSL_new(self->ssl_ctx);
    if (!self->ssl) return -1;

    SSL_set_fd(self->ssl, self->fd);
    if (self->host) {
        SSL_set_tlsext_host_name(self->ssl, self->host);
        if (!self->tls_skip_verify) {
            X509_VERIFY_PARAM *vpm = SSL_get0_param(self->ssl);
            /* set1_ip_asc parses host as a textual IP and returns 0 on
               failure — fall back to set1_host for DNS names. */
            if (vpm && !X509_VERIFY_PARAM_set1_ip_asc(vpm, self->host)) {
                X509_VERIFY_PARAM_set_hostflags(vpm, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
                if (!X509_VERIFY_PARAM_set1_host(vpm, self->host, 0))
                    return -1;
            }
        }
    }

    return 0;
}

static void nats_ssl_cleanup(nats_t *self)
{
    if (self->ssl) {
        SSL_free(self->ssl);
        self->ssl = NULL;
    }
    self->ssl_handshaking = 0;
}

static int nats_ssl_handshake(nats_t *self)
{
    int ret = SSL_connect(self->ssl);
    if (ret == 1) {
        self->ssl_handshaking = 0;
        return 1;
    }
    int err = SSL_get_error(self->ssl, ret);
    if (err == SSL_ERROR_WANT_READ) {
        if (!self->reading) {
            ev_io_start(self->loop, &self->rio);
            self->reading = 1;
        }
        return 0;
    }
    if (err == SSL_ERROR_WANT_WRITE) {
        if (!self->writing) {
            ev_io_start(self->loop, &self->wio);
            self->writing = 1;
        }
        return 0;
    }
    return -1;
}

/* Emit "<prefix>: <openssl-error>", clean up the connection. */
static void nats_ssl_fail(nats_t *self, const char *prefix)
{
    char errbuf[256];
    char msg[320];
    unsigned long e = ERR_peek_last_error();
    if (e) {
        ERR_error_string_n(e, errbuf, sizeof(errbuf));
        ERR_clear_error();
    } else {
        snprintf(errbuf, sizeof(errbuf), "unknown SSL error");
    }
    snprintf(msg, sizeof(msg), "%s: %s", prefix, errbuf);
    nats_emit_error(self, msg);
    nats_cleanup(self);
}
#endif

/* ================================================================
 * JSON string escaper (for CONNECT command)
 * ================================================================ */

static int json_escape_string(char *dst, size_t dst_size, const char *src)
{
    size_t di = 0;
    const unsigned char *s = (const unsigned char *)src;

    /* Need room for opening quote, at least one char, closing quote, NUL */
    if (dst_size < 3) {
        if (dst_size > 0) dst[0] = '\0';
        return 0;
    }

    dst[di++] = '"';

    for (; *s; s++) {
        size_t need = (*s == '"' || *s == '\\') ? 2 : (*s < 0x20) ? 6 : 1;
        if (di + need + 2 > dst_size) break; /* +2 for closing quote + NUL */

        if (*s == '"') {
            dst[di++] = '\\'; dst[di++] = '"';
        } else if (*s == '\\') {
            dst[di++] = '\\'; dst[di++] = '\\';
        } else if (*s < 0x20) {
            di += snprintf(dst + di, dst_size - di, "\\u%04x", *s);
        } else {
            dst[di++] = *s;
        }
    }

    dst[di++] = '"';
    dst[di] = '\0';
    return (int)di;
}

/* ================================================================
 * Random hex for inbox prefix
 * ================================================================ */

/* Read nbytes from /dev/urandom; fall back to rand() per byte. */
static void nats_random_bytes(unsigned char *out, int nbytes)
{
    int got = 0;
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd >= 0) {
        while (got < nbytes) {
            ssize_t n = read(fd, out + got, nbytes - got);
            if (n > 0) got += n;
            else if (n == 0 || (errno != EINTR && errno != EAGAIN)) break;
        }
        close(fd);
    }
    int i;
    for (i = got; i < nbytes; i++)
        out[i] = (unsigned char)(rand() & 0xFF);
}

static void nats_gen_hex(char *buf, int nbytes)
{
    static const char hex[] = "0123456789abcdef";
    unsigned char rnd[16];
    if (nbytes < 0) nbytes = 0;
    if (nbytes > (int)sizeof(rnd)) nbytes = (int)sizeof(rnd);
    nats_random_bytes(rnd, nbytes);
    int i;
    for (i = 0; i < nbytes; i++) {
        buf[i*2]   = hex[rnd[i] >> 4];
        buf[i*2+1] = hex[rnd[i] & 0x0F];
    }
}

static void nats_setup_inbox(nats_t *self)
{
    char hex[20];
    nats_gen_hex(hex, 8);
    snprintf(self->inbox_prefix, sizeof(self->inbox_prefix),
             "_INBOX.%.16s.", hex);
    self->next_req_id = 1;
}

/* ================================================================
 * Subscription management
 * ================================================================ */

static nats_sub_t *nats_find_sub(nats_t *self, uint64_t sid)
{
    char key[24];
    int klen = snprintf(key, sizeof(key), "%" UVuf, (UV)sid);
    SV **svp = hv_fetch(self->sub_map, key, klen, 0);
    if (svp && SvIOK(*svp))
        return INT2PTR(nats_sub_t *, SvIVX(*svp));
    return NULL;
}

static void nats_register_sub(nats_t *self, nats_sub_t *sub)
{
    char key[24];
    int klen = snprintf(key, sizeof(key), "%" UVuf, (UV)sub->sid);
    hv_store(self->sub_map, key, klen, newSViv(PTR2IV(sub)), 0);
    ngx_queue_insert_tail(&self->subs, &sub->queue);
}

static void nats_unregister_sub(nats_t *self, nats_sub_t *sub)
{
    char key[24];
    int klen = snprintf(key, sizeof(key), "%" UVuf, (UV)sub->sid);
    hv_delete(self->sub_map, key, klen, G_DISCARD);
}

static void nats_remove_sub(nats_t *self, nats_sub_t *sub)
{
    nats_unregister_sub(self, sub);
    ngx_queue_remove(&sub->queue);
    CLEAR_HANDLER(sub->subject);
    CLEAR_HANDLER(sub->queue_group);
    CLEAR_HANDLER(sub->cb);
    Safefree(sub);
}

static void nats_resub_all(nats_t *self)
{
    ngx_queue_t *q;
    char buf[MAX_CONTROL_LINE];

    ngx_queue_foreach(q, &self->subs) {
        nats_sub_t *sub = ngx_queue_data(q, nats_sub_t, queue);
        STRLEN slen;
        const char *subj = SvPV(sub->subject, slen);
        int n;

        if (sub->queue_group) {
            STRLEN glen;
            const char *grp = SvPV(sub->queue_group, glen);
            n = snprintf(buf, sizeof(buf), "SUB %.*s %.*s %" UVuf "\r\n",
                         (int)slen, subj, (int)glen, grp, (UV)sub->sid);
        } else {
            n = snprintf(buf, sizeof(buf), "SUB %.*s %" UVuf "\r\n",
                         (int)slen, subj, (UV)sub->sid);
        }
        wbuf_append(self, buf, n);

        /* Restore auto-unsub if partially consumed */
        if (sub->max_msgs > 0) {
            int remaining = sub->max_msgs - sub->received;
            if (remaining < 1) remaining = 1;
            n = snprintf(buf, sizeof(buf), "UNSUB %" UVuf " %d\r\n",
                         (UV)sub->sid, remaining);
            wbuf_append(self, buf, n);
        }
    }
}

/* ================================================================
 * Connection management
 * ================================================================ */

static void nats_stop_watchers(nats_t *self)
{
    if (self->reading) {
        ev_io_stop(self->loop, &self->rio);
        self->reading = 0;
    }
    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

static void nats_stop_timers(nats_t *self)
{
    if (self->connect_timer_active) {
        ev_timer_stop(self->loop, &self->connect_timer);
        self->connect_timer_active = 0;
    }
    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
    if (self->ping_timer_active) {
        ev_timer_stop(self->loop, &self->ping_timer);
        self->ping_timer_active = 0;
    }
    if (self->prepare_active) {
        ev_prepare_stop(self->loop, &self->prepare_watcher);
        self->prepare_active = 0;
    }
}

static void nats_cancel_all_requests(nats_t *self, const char *err)
{
    dSP;
    while (!ngx_queue_empty(&self->req_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->req_queue);
        nats_req_t *req = ngx_queue_data(q, nats_req_t, queue);
        ngx_queue_remove(q);

        if (req->timer_active) {
            ev_timer_stop(self->loop, &req->timer);
            req->timer_active = 0;
        }

        if (req->cb) {
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(&PL_sv_undef);
            PUSHs(sv_2mortal(newSVpv(err, 0)));
            PUTBACK;
            call_sv(req->cb, G_DISCARD);
            FREETMPS; LEAVE;
            SvREFCNT_dec(req->cb);
        }
        Safefree(req);
    }
}

static void nats_skip_waiting(nats_t *self)
{
    while (!ngx_queue_empty(&self->wait_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
        nats_pub_t *pub = ngx_queue_data(q, nats_pub_t, queue);
        ngx_queue_remove(q);
        if (pub->data)
            Safefree(pub->data);
        Safefree(pub);
        self->waiting_count--;
    }
}

static void nats_cleanup(nats_t *self)
{
    int was_connected = self->connected || self->connecting;

    nats_stop_watchers(self);
    nats_stop_timers(self);

    self->connected = 0;
    self->connecting = 0;
    self->pings_outstanding = 0;
    self->parse_state = PARSE_OP;
    self->ldm = 0;  /* lame-duck flag is per-connection */

#ifdef HAVE_OPENSSL
    nats_ssl_cleanup(self);
#endif

    if (self->fd >= 0) {
        close(self->fd);
        self->fd = -1;
    }

    self->rbuf_len = 0;
    self->wbuf_len = 0;
    self->wbuf_off = 0;

    nats_cancel_all_requests(self, "disconnected");

    /* Drain pending PONG callbacks (flush + drain markers). Fire each
       cb with a single error arg so callers learn the flush failed
       rather than hang forever waiting for a PONG that won't arrive. */
    while (!ngx_queue_empty(&self->pong_cbs)) {
        ngx_queue_t *pq = ngx_queue_head(&self->pong_cbs);
        nats_pong_cb_t *pcb = ngx_queue_data(pq, nats_pong_cb_t, queue);
        ngx_queue_remove(pq);
        if (pcb->cb) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSVpvn("disconnected", 12)));
            PUTBACK;
            call_sv(pcb->cb, G_DISCARD);
            FREETMPS; LEAVE;
            SvREFCNT_dec(pcb->cb);
        }
        Safefree(pcb);
    }
    /* Drain marker (drain_cb) is a separate field, fired on PONG normally;
       on cleanup it would otherwise leak. Fire it with error too. */
    if (self->draining && self->drain_cb) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpvn("disconnected", 12)));
        PUTBACK;
        call_sv(self->drain_cb, G_DISCARD);
        FREETMPS; LEAVE;
        CLEAR_HANDLER(self->drain_cb);
        self->draining = 0;
    }

    if (was_connected && self->on_disconnect) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(self->on_disconnect, G_DISCARD);
        FREETMPS; LEAVE;
    }

    nats_schedule_reconnect(self);
}

static void nats_emit_error(nats_t *self, const char *err)
{
    if (self->on_error) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSVpv(err, 0)));
        PUTBACK;
        call_sv(self->on_error, G_DISCARD);
        FREETMPS; LEAVE;
    } else {
        croak("EV::Nats: %s", err);
    }
}

/* ================================================================
 * CONNECT command builder
 * ================================================================ */

#define CONNECT_BUF_SIZE 8192
#define CONNECT_APPEND(fmt, ...) \
    do { \
        if (off >= (int)sizeof(buf)) { overflow = 1; break; } \
        int _n = snprintf(buf + off, sizeof(buf) - off, fmt, ##__VA_ARGS__); \
        if (_n < 0 || _n >= (int)(sizeof(buf) - off)) { overflow = 1; break; } \
        off += _n; \
    } while(0)

static void nats_send_connect(nats_t *self)
{
    char buf[CONNECT_BUF_SIZE];
    int off = 0;
    int overflow = 0;
    char escaped[1024];

    CONNECT_APPEND("CONNECT {");
    CONNECT_APPEND("\"verbose\":%s,\"pedantic\":%s,\"echo\":%s",
                   self->verbose ? "true" : "false",
                   self->pedantic ? "true" : "false",
                   self->echo ? "true" : "false");
    CONNECT_APPEND(",\"protocol\":1");
    if (self->no_responders)
        CONNECT_APPEND(",\"no_responders\":true");
    CONNECT_APPEND(",\"headers\":true");
    CONNECT_APPEND(",\"lang\":\"perl-xs\",\"version\":\"0.02\"");

    if (self->user) {
        int elen = json_escape_string(escaped, sizeof(escaped), self->user);
        CONNECT_APPEND(",\"user\":%.*s", elen, escaped);
        if (self->pass) {
            elen = json_escape_string(escaped, sizeof(escaped), self->pass);
            CONNECT_APPEND(",\"pass\":%.*s", elen, escaped);
        }
    }
    if (self->token) {
        int elen = json_escape_string(escaped, sizeof(escaped), self->token);
        CONNECT_APPEND(",\"auth_token\":%.*s", elen, escaped);
    }
    if (self->name) {
        int elen = json_escape_string(escaped, sizeof(escaped), self->name);
        CONNECT_APPEND(",\"name\":%.*s", elen, escaped);
    }
    if (self->jwt) {
        int elen = json_escape_string(escaped, sizeof(escaped), self->jwt);
        CONNECT_APPEND(",\"jwt\":%.*s", elen, escaped);
    }
  #ifdef HAVE_OPENSSL
    if (self->nkey_seed && self->server_nonce) {
        /* Sign nonce with NKey */
        char sig[128];
        char pub[64];
        if (nats_nkey_sign(self->nkey_seed, self->server_nonce,
                           strlen(self->server_nonce), sig, sizeof(sig)) > 0 &&
            nats_nkey_public(self->nkey_seed, pub, sizeof(pub)) > 0) {
            CONNECT_APPEND(",\"nkey\":\"%s\",\"sig\":\"%s\"", pub, sig);
        }
    }
  #endif

    CONNECT_APPEND("}\r\n");

    if (overflow) {
        nats_emit_error(self, "CONNECT command too long (auth/name fields)");
        nats_cleanup(self);
        return;
    }

    wbuf_append(self, buf, off);

    nats_resub_all(self);

    wbuf_append(self, "PING\r\n", 6);
}

/* ================================================================
 * Protocol parser
 * ================================================================ */

/* Parse a decimal token as size_t. Returns 0 on success, -1 on
   non-digits, empty input, or overflow. */
static int nats_parse_decimal(const char *tok, size_t tok_len, size_t *out)
{
    size_t v = 0;
    size_t i;
    if (tok_len == 0) return -1;
    for (i = 0; i < tok_len; i++) {
        if (tok[i] < '0' || tok[i] > '9') return -1;
        size_t d = (size_t)(tok[i] - '0');
        if (v > (SIZE_MAX - d) / 10) return -1;
        v = v * 10 + d;
    }
    *out = v;
    return 0;
}

static int nats_parse_msg_args(nats_t *self, char *line, size_t len)
{
    char *p = line;
    char *end = line + len;
    char *tok_start;

    if (len < 4) return -1;
    p += 4;

    /* subject */
    tok_start = p;
    while (p < end && *p != ' ' && *p != '\t') p++;
    if (p == tok_start) return -1;
    self->msg_subject_off = tok_start - self->rbuf;
    self->msg_subject_len = p - tok_start;

    while (p < end && (*p == ' ' || *p == '\t')) p++;

    /* sid */
    tok_start = p;
    while (p < end && *p != ' ' && *p != '\t') p++;
    {
        size_t sid;
        if (nats_parse_decimal(tok_start, p - tok_start, &sid) != 0) return -1;
        self->msg_sid = (uint64_t)sid;
    }

    while (p < end && (*p == ' ' || *p == '\t')) p++;

    /* Remaining tokens: [reply-to] <#bytes> — use token counting like HMSG */
    int ntokens = 0;
    char *tokens[3];
    size_t token_lens[3];
    char *tp = p;
    while (tp < end && ntokens < 3) {
        while (tp < end && (*tp == ' ' || *tp == '\t')) tp++;
        if (tp >= end) break;
        tokens[ntokens] = tp;
        while (tp < end && *tp != ' ' && *tp != '\t') tp++;
        token_lens[ntokens] = tp - tokens[ntokens];
        ntokens++;
    }

    if (ntokens == 1) {
        /* no reply-to, just #bytes */
        self->msg_reply_off = 0;
        self->msg_reply_len = 0;
        if (nats_parse_decimal(tokens[0], token_lens[0], &self->msg_total_len) != 0)
            return -1;
    } else if (ntokens == 2) {
        /* reply-to + #bytes */
        self->msg_reply_off = tokens[0] - self->rbuf;
        self->msg_reply_len = token_lens[0];
        if (nats_parse_decimal(tokens[1], token_lens[1], &self->msg_total_len) != 0)
            return -1;
    } else {
        return -1;
    }

    self->msg_hdr_len = 0;
    self->msg_type = MSG_TYPE_MSG;
    return 0;
}

static int nats_parse_hmsg_args(nats_t *self, char *line, size_t len)
{
    char *p = line;
    char *end = line + len;
    char *tok_start;

    if (len < 5) return -1;
    p += 5;

    /* subject */
    tok_start = p;
    while (p < end && *p != ' ' && *p != '\t') p++;
    if (p == tok_start) return -1;
    self->msg_subject_off = tok_start - self->rbuf;
    self->msg_subject_len = p - tok_start;

    while (p < end && (*p == ' ' || *p == '\t')) p++;

    /* sid */
    tok_start = p;
    while (p < end && *p != ' ' && *p != '\t') p++;
    {
        size_t sid;
        if (nats_parse_decimal(tok_start, p - tok_start, &sid) != 0) return -1;
        self->msg_sid = (uint64_t)sid;
    }

    while (p < end && (*p == ' ' || *p == '\t')) p++;

    int ntokens = 0;
    char *tokens[4];
    size_t token_lens[4];
    char *tp = p;
    while (tp < end && ntokens < 4) {
        while (tp < end && (*tp == ' ' || *tp == '\t')) tp++;
        if (tp >= end) break;
        tokens[ntokens] = tp;
        while (tp < end && *tp != ' ' && *tp != '\t') tp++;
        token_lens[ntokens] = tp - tokens[ntokens];
        ntokens++;
    }

    int hdr_idx, len_idx;
    if (ntokens == 2) {
        self->msg_reply_off = 0;
        self->msg_reply_len = 0;
        hdr_idx = 0; len_idx = 1;
    } else if (ntokens == 3) {
        self->msg_reply_off = tokens[0] - self->rbuf;
        self->msg_reply_len = token_lens[0];
        hdr_idx = 1; len_idx = 2;
    } else {
        return -1;
    }
    if (nats_parse_decimal(tokens[hdr_idx], token_lens[hdr_idx], &self->msg_hdr_len) != 0
     || nats_parse_decimal(tokens[len_idx], token_lens[len_idx], &self->msg_total_len) != 0) {
        return -1;
    }

    self->msg_type = MSG_TYPE_HMSG;
    return 0;
}

static void nats_process_msg(nats_t *self, char *payload, size_t len)
{
    nats_sub_t *sub = nats_find_sub(self, self->msg_sid);
    if (!sub) return;

    self->msgs_in++;
    self->bytes_in += len;
    sub->received++;

    int max_msgs = sub->max_msgs;
    int received = sub->received;
    uint64_t sid = sub->sid;

    if (sub->cb) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 4);

        PUSHs(sv_2mortal(newSVpvn(self->rbuf + self->msg_subject_off, self->msg_subject_len)));

        if (self->msg_type == MSG_TYPE_HMSG && self->msg_hdr_len > 0 && self->msg_hdr_len <= len) {
            PUSHs(sv_2mortal(newSVpvn(payload + self->msg_hdr_len, len - self->msg_hdr_len)));
        } else {
            PUSHs(sv_2mortal(newSVpvn(payload, len)));
        }

        if (self->msg_reply_len > 0) {
            PUSHs(sv_2mortal(newSVpvn(self->rbuf + self->msg_reply_off, self->msg_reply_len)));
        } else {
            PUSHs(&PL_sv_undef);
        }

        if (self->msg_type == MSG_TYPE_HMSG && self->msg_hdr_len > 0) {
            PUSHs(sv_2mortal(newSVpvn(payload, self->msg_hdr_len)));
        }

        PUTBACK;
        call_sv(sub->cb, G_DISCARD);
        FREETMPS; LEAVE;
    }

    if (max_msgs > 0 && received >= max_msgs) {
        sub = nats_find_sub(self, sid);
        if (sub)
            nats_remove_sub(self, sub);
    }
}

static void nats_check_inbox_response(nats_t *self, const char *subject, size_t subject_len,
                                       const char *payload, size_t payload_len,
                                       const char *headers, size_t headers_len)
{
    size_t pfx_len = strlen(self->inbox_prefix);
    if (subject_len <= pfx_len || memcmp(subject, self->inbox_prefix, pfx_len) != 0)
        return;

    const char *id_str = subject + pfx_len;
    size_t id_len = subject_len - pfx_len;
    uint64_t req_id = 0;
    size_t i;
    for (i = 0; i < id_len; i++) {
        if (id_str[i] < '0' || id_str[i] > '9') return;
        req_id = req_id * 10 + (id_str[i] - '0');
    }

    ngx_queue_t *q;
    ngx_queue_foreach(q, &self->req_queue) {
        nats_req_t *req = ngx_queue_data(q, nats_req_t, queue);
        if (req->req_id == req_id) {
            ngx_queue_remove(q);
            if (req->timer_active) {
                ev_timer_stop(self->loop, &req->timer);
                req->timer_active = 0;
            }
            if (req->cb) {
                dSP;
                int is_no_responders = (headers && headers_len >= 12 &&
                                        memcmp(headers, "NATS/1.0 503", 12) == 0);
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 3);
                if (is_no_responders) {
                    PUSHs(&PL_sv_undef);
                    PUSHs(sv_2mortal(newSVpvn("no responders", 13)));
                } else {
                    PUSHs(sv_2mortal(newSVpvn(payload, payload_len)));
                    PUSHs(&PL_sv_undef);
                    if (headers && headers_len > 0)
                        PUSHs(sv_2mortal(newSVpvn(headers, headers_len)));
                }
                PUTBACK;
                call_sv(req->cb, G_DISCARD);
                FREETMPS; LEAVE;
                SvREFCNT_dec(req->cb);
            }
            Safefree(req);
            return;
        }
    }
}

static void nats_process_line(nats_t *self, char *line, size_t len)
{
    if (len > 0 && line[len-1] == '\r')
        len--;

    if (len == 0) return;

    /* INFO */
    if (len > 5 && (line[0] == 'I' || line[0] == 'i') &&
        (line[1] == 'N' || line[1] == 'n') &&
        (line[2] == 'F' || line[2] == 'f') &&
        (line[3] == 'O' || line[3] == 'o') &&
        line[4] == ' ') {

        CLEAR_HANDLER(self->server_info_json);
        self->server_info_json = newSVpvn(line + 5, len - 5);

        {
            char *p = line + 5;
            char *e = line + len;
            char *found;

            found = strstr(p, "\"max_payload\":");
            if (found && found < e) {
                found += 14;
                self->max_payload = 0;
                while (found < e && *found >= '0' && *found <= '9') {
                    self->max_payload = self->max_payload * 10 + (*found - '0');
                    found++;
                }
            }

            nats_parse_connect_urls(self, p, e - p);

            /* Parse nonce for NKey auth */
            found = strstr(p, "\"nonce\":\"");
            if (found && found < e) {
                found += 9;
                const char *nend = memchr(found, '"', e - found);
                if (nend) {
                    size_t nlen = nend - found;
                    if (self->server_nonce) Safefree(self->server_nonce);
                    Newx(self->server_nonce, nlen + 1, char);
                    memcpy(self->server_nonce, found, nlen);
                    self->server_nonce[nlen] = '\0';
                }
            }

            /* Parse ldm (lame duck mode) */
            found = strstr(p, "\"ldm\":");
            if (found && found < e) {
                found += 6;
                while (found < e && (*found == ' ' || *found == '\t')) found++;
                if (found < e && *found == 't') {
                    if (!self->ldm) {
                        self->ldm = 1;
                        if (self->on_ldm) {
                            dSP;
                            ENTER; SAVETMPS;
                            PUSHMARK(SP);
                            PUTBACK;
                            call_sv(self->on_ldm, G_DISCARD);
                            FREETMPS; LEAVE;
                        }
                    }
                }
            }
        }

        if (self->connecting) {
#ifdef HAVE_OPENSSL
            if (self->tls && !self->ssl) {
                if (nats_ssl_setup(self) != 0) {
                    nats_ssl_fail(self, "SSL setup failed");
                    return;
                }
                self->ssl_handshaking = 1;
                int hret = nats_ssl_handshake(self);
                if (hret < 0) {
                    nats_ssl_fail(self, "SSL handshake failed");
                    return;
                }
                if (hret == 1) {
                    self->ssl_handshaking = 0;
                    nats_send_connect(self);
                    nats_try_write(self);
                }
                /* hret == 0: handshake in progress; nats_on_read will resume. */
                return;
            }
#endif
            nats_send_connect(self);
            nats_try_write(self);
        }
        return;
    }

    /* MSG */
    if (len >= 4 && line[0] == 'M' && line[1] == 'S' && line[2] == 'G' && line[3] == ' ') {
        if (nats_parse_msg_args(self, line, len) == 0) {
            if (self->msg_total_len > (size_t)self->max_payload) {
                nats_emit_error(self, "server sent message exceeding max_payload");
                nats_cleanup(self);
                return;
            }
            self->parse_state = PARSE_MSG_BODY;
        }
        return;
    }

    /* HMSG */
    if (len >= 5 && line[0] == 'H' && line[1] == 'M' && line[2] == 'S' && line[3] == 'G' && line[4] == ' ') {
        if (nats_parse_hmsg_args(self, line, len) == 0) {
            if (self->msg_total_len > (size_t)self->max_payload) {
                nats_emit_error(self, "server sent message exceeding max_payload");
                nats_cleanup(self);
                return;
            }
            self->parse_state = PARSE_MSG_BODY;
        }
        return;
    }

    /* PING */
    if (len == 4 && line[0] == 'P' && line[1] == 'I' && line[2] == 'N' && line[3] == 'G') {
        wbuf_append(self, "PONG\r\n", 6);
        nats_try_write(self);
        return;
    }

    /* PONG */
    if (len == 4 && line[0] == 'P' && line[1] == 'O' && line[2] == 'N' && line[3] == 'G') {
        if (self->pings_outstanding > 0)
            self->pings_outstanding--;

        if (self->connecting && !self->connected) {
            self->connecting = 0;
            self->connected = 1;
            self->reconnect_attempts = 0;

            if (self->connect_timer_active) {
                ev_timer_stop(self->loop, &self->connect_timer);
                self->connect_timer_active = 0;
            }

            nats_start_ping_timer(self);

            if (self->on_connect) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                PUTBACK;
                call_sv(self->on_connect, G_DISCARD);
                FREETMPS; LEAVE;
            }

            nats_drain_waiting(self);
        }

        /* Fire flush/PONG callback (one per PONG, FIFO) */
        if (!ngx_queue_empty(&self->pong_cbs)) {
            ngx_queue_t *pq = ngx_queue_head(&self->pong_cbs);
            nats_pong_cb_t *pcb = ngx_queue_data(pq, nats_pong_cb_t, queue);
            ngx_queue_remove(pq);
            if (pcb->cb) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 1);
                PUSHs(&PL_sv_undef);  /* success: no error */
                PUTBACK;
                call_sv(pcb->cb, G_DISCARD);
                FREETMPS; LEAVE;
                SvREFCNT_dec(pcb->cb);
            } else if (self->draining) {
                /* Drain marker: fire drain callback and disconnect */
                self->draining = 0;
                if (self->drain_cb) {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    EXTEND(SP, 1);
                    PUSHs(&PL_sv_undef);  /* success: no error */
                    PUTBACK;
                    call_sv(self->drain_cb, G_DISCARD);
                    FREETMPS; LEAVE;
                    CLEAR_HANDLER(self->drain_cb);
                }
                Safefree(pcb);
                self->intentional_disconnect = 1;
                nats_cleanup(self);
                return;
            }
            Safefree(pcb);
        }

        return;
    }

    /* +OK */
    if (len >= 3 && line[0] == '+' && line[1] == 'O' && line[2] == 'K') {
        return;
    }

    /* -ERR */
    if (len >= 4 && line[0] == '-' && line[1] == 'E' && line[2] == 'R' && line[3] == 'R') {
        char *msg = line + 4;
        size_t mlen = len - 4;
        while (mlen > 0 && (*msg == ' ' || *msg == '\'')) { msg++; mlen--; }
        while (mlen > 0 && msg[mlen-1] == '\'') mlen--;

        char errbuf[512];
        snprintf(errbuf, sizeof(errbuf), "%.*s", (int)mlen, msg);

        if (strstr(errbuf, "authorization") || strstr(errbuf, "authentication")) {
            self->intentional_disconnect = 1;
        }
        nats_emit_error(self, errbuf);
        nats_cleanup(self);
        return;
    }
}

/* ================================================================
 * IO callbacks
 * ================================================================ */

static void nats_on_read(struct ev_loop *loop, ev_io *w, int revents)
{
    nats_t *self = (nats_t *)((char *)w - offsetof(nats_t, rio));
    (void)revents;

#ifdef HAVE_OPENSSL
    if (self->ssl_handshaking) {
        int hret = nats_ssl_handshake(self);
        if (hret == 0) return;
        if (hret < 0) {
            nats_ssl_fail(self, "SSL handshake failed");
            return;
        }
        self->ssl_handshaking = 0;
        if (self->writing) {
            ev_io_stop(self->loop, &self->wio);
            self->writing = 0;
        }
        /* Handshake completed after the post-INFO upgrade. Send CONNECT
           over the now-encrypted channel. */
        if (self->connecting) {
            nats_send_connect(self);
            nats_try_write(self);
        }
    }
#endif

    buf_ensure(&self->rbuf, &self->rbuf_cap, self->rbuf_len + BUF_INIT_SIZE);

    ssize_t n = nats_io_read(self, self->rbuf + self->rbuf_len,
                             self->rbuf_cap - self->rbuf_len);

    if (n <= 0) {
        if (n == 0) {
            nats_cleanup(self);
        } else if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
            nats_emit_error(self, strerror(errno));
            nats_cleanup(self);
        }
        return;
    }

    self->rbuf_len += n;

    size_t consumed = 0;

    while (consumed < self->rbuf_len) {
        if (self->fd < 0) break;
#ifdef HAVE_OPENSSL
        /* If processing INFO triggered a TLS upgrade, stop parsing rbuf as
           plaintext — subsequent bytes belong to the TLS handshake. */
        if (self->ssl_handshaking) break;
#endif

        if (self->parse_state == PARSE_OP) {
            char *start = self->rbuf + consumed;
            char *nl = (char *)memchr(start, '\n', self->rbuf_len - consumed);
            if (!nl) break;

            size_t line_len = nl - start;
            nats_process_line(self, start, line_len);
            consumed += line_len + 1;

        } else if (self->parse_state == PARSE_MSG_BODY) {
            size_t need = self->msg_total_len + 2;
            size_t avail = self->rbuf_len - consumed;
            if (avail < need) break;

            char *payload = self->rbuf + consumed;

            /* Dispatch inbox responses, skip normal sub delivery for inbox */
            if (self->inbox_sub_sid && self->msg_sid == self->inbox_sub_sid) {
                const char *hdrs = NULL;
                size_t hdrs_len = 0;
                const char *body = payload;
                size_t body_len = self->msg_total_len;

                if (self->msg_type == MSG_TYPE_HMSG && self->msg_hdr_len > 0 &&
                    self->msg_hdr_len <= self->msg_total_len) {
                    hdrs = payload;
                    hdrs_len = self->msg_hdr_len;
                    body = payload + self->msg_hdr_len;
                    body_len = self->msg_total_len - self->msg_hdr_len;
                }

                self->msgs_in++;
                self->bytes_in += self->msg_total_len;
                nats_check_inbox_response(self, self->rbuf + self->msg_subject_off, self->msg_subject_len,
                                          body, body_len, hdrs, hdrs_len);
            } else {
                nats_process_msg(self, payload, self->msg_total_len);
            }

            consumed += need;
            self->parse_state = PARSE_OP;
        }
    }

    if (self->fd >= 0 && consumed > 0 && consumed <= self->rbuf_len) {
        self->rbuf_len -= consumed;
        if (self->rbuf_len > 0)
            memmove(self->rbuf, self->rbuf + consumed, self->rbuf_len);
    }
}

static void nats_try_write(nats_t *self)
{
    if (self->fd < 0) return;

    while (self->wbuf_off < self->wbuf_len) {
        ssize_t n = nats_io_write(self, self->wbuf + self->wbuf_off,
                                  self->wbuf_len - self->wbuf_off);
        if (n <= 0) {
            if (n == 0 || errno == EAGAIN || errno == EWOULDBLOCK) {
                if (!self->writing) {
                    ev_io_start(self->loop, &self->wio);
                    self->writing = 1;
                }
                return;
            }
            if (errno == EINTR)
                continue;
            nats_emit_error(self, strerror(errno));
            nats_cleanup(self);
            return;
        }
        self->wbuf_off += n;
    }

    self->wbuf_off = 0;
    self->wbuf_len = 0;

    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

static void nats_on_write(struct ev_loop *loop, ev_io *w, int revents)
{
    nats_t *self = (nats_t *)((char *)w - offsetof(nats_t, wio));
    (void)loop; (void)revents;

    if (self->connecting && !self->connected) {
        int err = 0;
        socklen_t errlen = sizeof(err);
        getsockopt(self->fd, SOL_SOCKET, SO_ERROR, &err, &errlen);
        if (err) {
            nats_emit_error(self, strerror(err));
            nats_cleanup(self);
            return;
        }
        /* TCP connect complete. NATS speaks plain text until INFO arrives;
           if TLS is configured, we upgrade once we've parsed INFO. So just
           switch to reading and wait for the server's INFO greeting. */
        if (self->writing) {
            ev_io_stop(self->loop, &self->wio);
            self->writing = 0;
        }
        if (!self->reading) {
            ev_io_start(self->loop, &self->rio);
            self->reading = 1;
        }
        return;
    }

    nats_try_write(self);
}

/* ================================================================
 * Timer callbacks
 * ================================================================ */

static void nats_on_connect_timeout(struct ev_loop *loop, ev_timer *w, int revents)
{
    nats_t *self = (nats_t *)((char *)w - offsetof(nats_t, connect_timer));
    (void)loop; (void)revents;
    self->connect_timer_active = 0;
    nats_emit_error(self, "connect timeout");
    nats_cleanup(self);
}

static void nats_on_reconnect_timer(struct ev_loop *loop, ev_timer *w, int revents)
{
    nats_t *self = (nats_t *)((char *)w - offsetof(nats_t, reconnect_timer));
    (void)loop; (void)revents;
    self->reconnect_timer_active = 0;
    self->reconnect_attempts++;
    self->intentional_disconnect = 0;
    if (self->server_pool_count > 0)
        nats_next_server(self);
    nats_do_connect(self);
}

static void nats_start_ping_timer(nats_t *self)
{
    if (self->ping_interval_ms <= 0) return;
    double interval = self->ping_interval_ms / 1000.0;
    ev_timer_set(&self->ping_timer, interval, interval);
    ev_timer_start(self->loop, &self->ping_timer);
    self->ping_timer_active = 1;
}

static void nats_on_ping_timer(struct ev_loop *loop, ev_timer *w, int revents)
{
    nats_t *self = (nats_t *)((char *)w - offsetof(nats_t, ping_timer));
    (void)loop; (void)revents;

    self->pings_outstanding++;
    if (self->max_pings_outstanding > 0 &&
        self->pings_outstanding > self->max_pings_outstanding) {
        nats_emit_error(self, "stale connection");
        nats_cleanup(self);
        return;
    }

    wbuf_append(self, "PING\r\n", 6);
    nats_try_write(self);
}

/* ================================================================
 * Write coalescing via ev_prepare
 * ================================================================ */

static void nats_on_prepare(struct ev_loop *loop, ev_prepare *w, int revents)
{
    nats_t *self = (nats_t *)((char *)w - offsetof(nats_t, prepare_watcher));
    (void)loop; (void)revents;

    if (self->wbuf_dirty && self->fd >= 0) {
        self->wbuf_dirty = 0;
        nats_try_write(self);
    }
}

static void nats_schedule_write(nats_t *self)
{
    if (self->batch_mode) return; /* writes batched, flushed on batch end */

    self->wbuf_dirty = 1;
    if (!self->prepare_active) {
        ev_prepare_start(self->loop, &self->prepare_watcher);
        self->prepare_active = 1;
    }

    /* Slow consumer detection */
    if (self->slow_consumer_bytes > 0 &&
        (self->wbuf_len - self->wbuf_off) > self->slow_consumer_bytes) {
        if (self->on_slow_consumer) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSVuv(self->wbuf_len - self->wbuf_off)));
            PUTBACK;
            call_sv(self->on_slow_consumer, G_DISCARD);
            FREETMPS; LEAVE;
        }
    }
}

/* ================================================================
 * Request timeout
 * ================================================================ */

static void nats_on_request_timeout(struct ev_loop *loop, ev_timer *w, int revents)
{
    nats_req_t *req = (nats_req_t *)((char *)w - offsetof(nats_req_t, timer));
    (void)loop; (void)revents;
    req->timer_active = 0;

    ngx_queue_remove(&req->queue);

    if (req->cb) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSVpvn("request timeout", 15)));
        PUTBACK;
        call_sv(req->cb, G_DISCARD);
        FREETMPS; LEAVE;
        SvREFCNT_dec(req->cb);
    }
    Safefree(req);
}

/* ================================================================
 * Write queue (for buffering during connect/reconnect)
 * ================================================================ */

static void nats_drain_waiting(nats_t *self)
{
    while (!ngx_queue_empty(&self->wait_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->wait_queue);
        nats_pub_t *pub = ngx_queue_data(q, nats_pub_t, queue);
        ngx_queue_remove(q);
        self->waiting_count--;

        wbuf_append(self, pub->data, pub->len);
        Safefree(pub->data);
        Safefree(pub);
    }

    if (self->wbuf_len > self->wbuf_off)
        nats_try_write(self);
}

static void nats_queue_write(nats_t *self, const char *data, size_t len)
{
    if (self->connected) {
        wbuf_append(self, data, len);
        nats_schedule_write(self);
    } else if (self->connecting ||
               (self->reconnect_enabled && self->reconnect_timer_active)) {
        nats_pub_t *pub;
        Newxz(pub, 1, nats_pub_t);
        Newx(pub->data, len, char);
        memcpy(pub->data, data, len);
        pub->len = len;
        ngx_queue_insert_tail(&self->wait_queue, &pub->queue);
        self->waiting_count++;
    } else {
        croak("not connected");
    }
}

/* ================================================================
 * TCP connection
 * ================================================================ */

static void nats_schedule_reconnect(nats_t *self)
{
    /* If a user callback (on_disconnect/on_error) already kicked off a fresh
       connect, don't stomp on it. */
    if (self->fd >= 0 || self->connecting || self->reconnect_timer_active)
        return;
    if (!self->intentional_disconnect && self->reconnect_enabled) {
        if (self->max_reconnect_attempts == 0 ||
            self->reconnect_attempts < self->max_reconnect_attempts) {
            /* Exponential backoff with jitter */
            int shift = self->reconnect_attempts > 5 ? 5 : self->reconnect_attempts;
            int delay = self->reconnect_delay_ms * (1 << shift);
            if (self->max_reconnect_delay_ms > 0 && delay > self->max_reconnect_delay_ms)
                delay = self->max_reconnect_delay_ms;
            double base = delay / 1000.0;
            unsigned char r[2];
            nats_random_bytes(r, 2);
            unsigned int rv = ((unsigned)r[0] << 8) | r[1];
            double jitter = base * (0.5 + (double)(rv % 1000) / 2000.0);
            ev_timer_set(&self->reconnect_timer, jitter, 0.0);
            ev_timer_start(self->loop, &self->reconnect_timer);
            self->reconnect_timer_active = 1;
        } else {
            nats_emit_error(self, "max reconnect attempts reached");
        }
    }
}

static void nats_free_server_pool(nats_t *self)
{
    while (!ngx_queue_empty(&self->server_pool)) {
        ngx_queue_t *q = ngx_queue_head(&self->server_pool);
        nats_server_t *srv = ngx_queue_data(q, nats_server_t, queue);
        ngx_queue_remove(q);
        Safefree(srv->host);
        Safefree(srv);
        self->server_pool_count--;
    }
}

static void nats_parse_connect_urls(nats_t *self, const char *json, size_t len)
{
    const char *key = "\"connect_urls\":[";
    const char *p = strstr(json, key);
    if (!p || p >= json + len) return;

    p += strlen(key);
    const char *end = json + len;

    nats_free_server_pool(self);

    while (p < end && *p != ']') {
        while (p < end && (*p == ' ' || *p == ',' || *p == '"')) p++;
        if (p >= end || *p == ']') break;

        const char *start = p;
        while (p < end && *p != '"' && *p != ',' && *p != ']') p++;

        size_t url_len = p - start;
        if (url_len > 0) {
            /* Parse host:port */
            const char *colon = NULL;
            const char *s;
            for (s = start + url_len - 1; s >= start; s--) {
                if (*s == ':') { colon = s; break; }
            }

            nats_server_t *srv;
            Newxz(srv, 1, nats_server_t);
            if (colon && colon > start) {
                size_t hlen = colon - start;
                Newx(srv->host, hlen + 1, char);
                memcpy(srv->host, start, hlen);
                srv->host[hlen] = '\0';
                srv->port = 0;
                const char *dp = colon + 1;
                while (dp < start + url_len && *dp >= '0' && *dp <= '9') {
                    srv->port = srv->port * 10 + (*dp - '0');
                    dp++;
                }
            } else {
                Newx(srv->host, url_len + 1, char);
                memcpy(srv->host, start, url_len);
                srv->host[url_len] = '\0';
                srv->port = 4222;
            }
            ngx_queue_insert_tail(&self->server_pool, &srv->queue);
            self->server_pool_count++;
        }

        while (p < end && *p == '"') p++;
    }
}

static void nats_next_server(nats_t *self)
{
    if (ngx_queue_empty(&self->server_pool)) return;

    /* Rotate: move head to tail, use new head */
    ngx_queue_t *q = ngx_queue_head(&self->server_pool);
    nats_server_t *srv = ngx_queue_data(q, nats_server_t, queue);

    nats_set_str(&self->host, srv->host);
    self->port = srv->port;

    /* Rotate this server to end of pool */
    ngx_queue_remove(q);
    ngx_queue_insert_tail(&self->server_pool, q);
}

static void nats_connect_tcp(nats_t *self)
{
    struct addrinfo hints, *res, *rp;
    char port_str[8];
    int fd = -1;

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    snprintf(port_str, sizeof(port_str), "%d", self->port);

    int rv = getaddrinfo(self->host, port_str, &hints, &res);
    if (rv != 0) {
        nats_emit_error(self, gai_strerror(rv));
        nats_schedule_reconnect(self);
        return;
    }

    for (rp = res; rp != NULL; rp = rp->ai_next) {
        fd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (fd < 0) continue;

        fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK);

        int flag = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &flag, sizeof(flag));

        if (self->keepalive > 0) {
            setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &flag, sizeof(flag));
            #ifdef TCP_KEEPIDLE
            setsockopt(fd, IPPROTO_TCP, TCP_KEEPIDLE, &self->keepalive, sizeof(self->keepalive));
            #endif
        }

        rv = connect(fd, rp->ai_addr, rp->ai_addrlen);
        if (rv == 0 || errno == EINPROGRESS) break;

        close(fd);
        fd = -1;
    }

    freeaddrinfo(res);

    if (fd < 0) {
        nats_emit_error(self, "connection failed");
        nats_schedule_reconnect(self);
        return;
    }

    self->fd = fd;
    self->connecting = 1;
    self->connected = 0;

    ev_io_init(&self->rio, nats_on_read, fd, EV_READ);
    ev_io_init(&self->wio, nats_on_write, fd, EV_WRITE);

    if (self->priority) {
        ev_set_priority(&self->rio, self->priority);
        ev_set_priority(&self->wio, self->priority);
    }

    ev_io_start(self->loop, &self->rio);
    self->reading = 1;

    if (rv != 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }

    if (self->connect_timeout_ms > 0) {
        ev_timer_set(&self->connect_timer, self->connect_timeout_ms / 1000.0, 0.0);
        ev_timer_start(self->loop, &self->connect_timer);
        self->connect_timer_active = 1;
    }
}

static void nats_connect_unix(nats_t *self)
{
    struct sockaddr_un addr;
    int fd;

    if (!self->path || strlen(self->path) >= sizeof(addr.sun_path)) {
        nats_emit_error(self, "invalid unix socket path");
        nats_schedule_reconnect(self);
        return;
    }

    fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        nats_emit_error(self, strerror(errno));
        nats_schedule_reconnect(self);
        return;
    }

    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK);

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, self->path, sizeof(addr.sun_path) - 1);

    int rv = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    if (rv != 0 && errno != EINPROGRESS) {
        close(fd);
        nats_emit_error(self, strerror(errno));
        nats_schedule_reconnect(self);
        return;
    }

    self->fd = fd;
    self->connecting = 1;
    self->connected = 0;

    ev_io_init(&self->rio, nats_on_read, fd, EV_READ);
    ev_io_init(&self->wio, nats_on_write, fd, EV_WRITE);

    if (self->priority) {
        ev_set_priority(&self->rio, self->priority);
        ev_set_priority(&self->wio, self->priority);
    }

    ev_io_start(self->loop, &self->rio);
    self->reading = 1;

    if (rv != 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }

    if (self->connect_timeout_ms > 0) {
        ev_timer_set(&self->connect_timer, self->connect_timeout_ms / 1000.0, 0.0);
        ev_timer_start(self->loop, &self->connect_timer);
        self->connect_timer_active = 1;
    }
}

/* Helper: connect via path or host */
static void nats_do_connect(nats_t *self)
{
    if (self->path)
        nats_connect_unix(self);
    else
        nats_connect_tcp(self);
}

/* ================================================================
 * XS interface
 * ================================================================ */

MODULE = EV::Nats  PACKAGE = EV::Nats

PROTOTYPES: DISABLE

BOOT:
{
    I_EV_API("EV::Nats");
    {
        HV *stash = gv_stashpv("EV::Nats", GV_ADD);
#ifdef HAVE_OPENSSL
        newCONSTSUB(stash, "HAS_TLS",  newSViv(1));
        newCONSTSUB(stash, "HAS_NKEY", newSViv(1));
#else
        newCONSTSUB(stash, "HAS_TLS",  newSViv(0));
        newCONSTSUB(stash, "HAS_NKEY", newSViv(0));
#endif
    }
}

EV::Nats
new(class, ...)
    char *class
  PREINIT:
    nats_t *self;
    int i;
  CODE:
    Newxz(self, 1, nats_t);
    self->magic = NATS_MAGIC_ALIVE;
    self->fd = -1;
    self->loop = EV_DEFAULT;
    self->max_payload = DEFAULT_MAX_PAYLOAD;
    self->port = 4222;
    self->echo = 1;
    self->ping_interval_ms = 120000;
    self->max_pings_outstanding = 2;
    self->reconnect_delay_ms = 2000;
    self->max_reconnect_delay_ms = 30000;
    self->max_reconnect_attempts = 60;

    ngx_queue_init(&self->subs);
    ngx_queue_init(&self->wait_queue);
    ngx_queue_init(&self->req_queue);

    self->next_sid = 1;

    ev_timer_init(&self->connect_timer, nats_on_connect_timeout, 0., 0.);
    ev_timer_init(&self->reconnect_timer, nats_on_reconnect_timer, 0., 0.);
    ev_timer_init(&self->ping_timer, nats_on_ping_timer, 0., 0.);
    ev_prepare_init(&self->prepare_watcher, nats_on_prepare);

    ngx_queue_init(&self->server_pool);
    ngx_queue_init(&self->pong_cbs);
    self->sub_map = newHV();

    nats_setup_inbox(self);

    if (items > 1 && (items - 1) % 2 == 0) {
        for (i = 1; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);

            if      (strcmp(key, "host")  == 0) nats_set_str_sv(&self->host,  val);
            else if (strcmp(key, "port")  == 0) self->port = SvIV(val);
            else if (strcmp(key, "path")  == 0) nats_set_str_sv(&self->path,  val);
            else if (strcmp(key, "user")  == 0) nats_set_str_sv(&self->user,  val);
            else if (strcmp(key, "pass")  == 0) nats_set_str_sv(&self->pass,  val);
            else if (strcmp(key, "token") == 0) nats_set_str_sv(&self->token, val);
            else if (strcmp(key, "name")  == 0) nats_set_str_sv(&self->name,  val);
            else if (strcmp(key, "on_error") == 0)
                self->on_error = newSVsv(val);
            else if (strcmp(key, "on_connect") == 0)
                self->on_connect = newSVsv(val);
            else if (strcmp(key, "on_disconnect") == 0)
                self->on_disconnect = newSVsv(val);
            else if (strcmp(key, "verbose") == 0)
                self->verbose = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "pedantic") == 0)
                self->pedantic = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "echo") == 0)
                self->echo = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "no_responders") == 0)
                self->no_responders = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "reconnect") == 0)
                self->reconnect_enabled = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "reconnect_delay") == 0)
                self->reconnect_delay_ms = SvIV(val);
            else if (strcmp(key, "max_reconnect_attempts") == 0)
                self->max_reconnect_attempts = SvIV(val);
            else if (strcmp(key, "max_reconnect_delay") == 0)
                self->max_reconnect_delay_ms = SvIV(val);
            else if (strcmp(key, "connect_timeout") == 0)
                self->connect_timeout_ms = SvIV(val);
            else if (strcmp(key, "ping_interval") == 0)
                self->ping_interval_ms = SvIV(val);
            else if (strcmp(key, "max_pings_outstanding") == 0)
                self->max_pings_outstanding = SvIV(val);
            else if (strcmp(key, "priority") == 0)
                self->priority = SvIV(val);
            else if (strcmp(key, "keepalive") == 0)
                self->keepalive = SvIV(val);
  #ifdef HAVE_OPENSSL
            else if (strcmp(key, "tls") == 0)
                self->tls = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "tls_ca_file") == 0)
                nats_set_str_sv(&self->tls_ca_file, val);
            else if (strcmp(key, "tls_skip_verify") == 0)
                self->tls_skip_verify = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "nkey_seed") == 0)
                nats_set_str_sv(&self->nkey_seed, val);
  #endif
            else if (strcmp(key, "jwt") == 0)
                nats_set_str_sv(&self->jwt, val);
            else if (strcmp(key, "slow_consumer_bytes") == 0)
                self->slow_consumer_bytes = (size_t)SvUV(val);
            else if (strcmp(key, "on_slow_consumer") == 0)
                self->on_slow_consumer = newSVsv(val);
            else if (strcmp(key, "on_lame_duck") == 0)
                self->on_ldm = newSVsv(val);
            else if (strcmp(key, "loop") == 0)
                self->loop = (struct ev_loop *)SvIVx(SvRV(val));
            else
                warn("EV::Nats::new: unknown option '%s'", key);
        }
    }

    if (self->host || self->path)
        nats_do_connect(self);

    RETVAL = self;
  OUTPUT:
    RETVAL

void
connect(self, host, port = 4222)
    EV::Nats self
    char *host
    int port
  CODE:
    if (self->connected || self->connecting)
        croak("already connected");

    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }

    nats_set_str(&self->path, NULL);
    nats_set_str(&self->host, host);
    self->port = port;
    self->intentional_disconnect = 0;

    nats_connect_tcp(self);

void
connect_unix(self, path)
    EV::Nats self
    char *path
  CODE:
    if (self->connected || self->connecting)
        croak("already connected");

    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }

    nats_set_str(&self->host, NULL);
    nats_set_str(&self->path, path);
    self->intentional_disconnect = 0;

    nats_connect_unix(self);

void
disconnect(self)
    EV::Nats self
  CODE:
    self->intentional_disconnect = 1;
    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
    nats_skip_waiting(self);
    nats_cleanup(self);

int
is_connected(self)
    EV::Nats self
  CODE:
    RETVAL = self->connected;
  OUTPUT:
    RETVAL

void
publish(self, subject, payload = &PL_sv_undef, reply = NULL)
    EV::Nats self
    SV *subject
    SV *payload
    const char *reply
  PREINIT:
    char hdr[MAX_CONTROL_LINE];
    STRLEN subj_len, pay_len;
    const char *subj_pv, *pay_pv;
  CODE:
    NATS_CROAK_UNLESS_CONNECTED(self);

    subj_pv = SvPV(subject, subj_len);

    if (SvOK(payload)) {
        pay_pv = SvPV(payload, pay_len);
    } else {
        pay_pv = "";
        pay_len = 0;
    }

    if (self->max_payload > 0 && pay_len > (size_t)self->max_payload)
        croak("payload exceeds max_payload (%d)", self->max_payload);

    int hdr_len;
    if (reply && *reply) {
        hdr_len = snprintf(hdr, sizeof(hdr), "PUB %.*s %s %lu\r\n",
                           (int)subj_len, subj_pv, reply, (unsigned long)pay_len);
    } else {
        hdr_len = snprintf(hdr, sizeof(hdr), "PUB %.*s %lu\r\n",
                           (int)subj_len, subj_pv, (unsigned long)pay_len);
    }

    self->msgs_out++;
    self->bytes_out += pay_len;

    if (self->connected) {
        wbuf_append(self, hdr, hdr_len);
        if (pay_len > 0) wbuf_append(self, pay_pv, pay_len);
        wbuf_append(self, "\r\n", 2);
        nats_schedule_write(self);
    } else {
        size_t total = hdr_len + pay_len + 2;
        char *buf;
        Newx(buf, total, char);
        memcpy(buf, hdr, hdr_len);
        if (pay_len > 0) memcpy(buf + hdr_len, pay_pv, pay_len);
        buf[hdr_len + pay_len] = '\r';
        buf[hdr_len + pay_len + 1] = '\n';
        nats_queue_write(self, buf, total);
        Safefree(buf);
    }

void
hpublish(self, subject, headers, payload = &PL_sv_undef, reply = NULL)
    EV::Nats self
    SV *subject
    SV *headers
    SV *payload
    const char *reply
  PREINIT:
    char hdr[MAX_CONTROL_LINE];
    STRLEN subj_len, hdr_data_len, pay_len;
    const char *subj_pv, *hdr_data_pv, *pay_pv;
  CODE:
    NATS_CROAK_UNLESS_CONNECTED(self);

    subj_pv = SvPV(subject, subj_len);
    hdr_data_pv = SvPV(headers, hdr_data_len);

    if (SvOK(payload)) {
        pay_pv = SvPV(payload, pay_len);
    } else {
        pay_pv = "";
        pay_len = 0;
    }

    size_t total_size = hdr_data_len + pay_len;
    if (self->max_payload > 0 && total_size > (size_t)self->max_payload)
        croak("message exceeds max_payload (%d)", self->max_payload);

    self->msgs_out++;
    self->bytes_out += total_size;

    int cmd_len;
    if (reply && *reply) {
        cmd_len = snprintf(hdr, sizeof(hdr), "HPUB %.*s %s %lu %lu\r\n",
                           (int)subj_len, subj_pv, reply,
                           (unsigned long)hdr_data_len, (unsigned long)total_size);
    } else {
        cmd_len = snprintf(hdr, sizeof(hdr), "HPUB %.*s %lu %lu\r\n",
                           (int)subj_len, subj_pv,
                           (unsigned long)hdr_data_len, (unsigned long)total_size);
    }

    if (self->connected) {
        wbuf_append(self, hdr, cmd_len);
        wbuf_append(self, hdr_data_pv, hdr_data_len);
        if (pay_len > 0) wbuf_append(self, pay_pv, pay_len);
        wbuf_append(self, "\r\n", 2);
        nats_schedule_write(self);
    } else {
        size_t total = cmd_len + total_size + 2;
        char *buf;
        Newx(buf, total, char);
        memcpy(buf, hdr, cmd_len);
        memcpy(buf + cmd_len, hdr_data_pv, hdr_data_len);
        if (pay_len > 0) memcpy(buf + cmd_len + hdr_data_len, pay_pv, pay_len);
        buf[cmd_len + total_size] = '\r';
        buf[cmd_len + total_size + 1] = '\n';
        nats_queue_write(self, buf, total);
        Safefree(buf);
    }

UV
subscribe(self, subject, cb, queue_group = NULL)
    EV::Nats self
    SV *subject
    SV *cb
    const char *queue_group
  PREINIT:
    nats_sub_t *sub;
    char buf[MAX_CONTROL_LINE];
    STRLEN subj_len;
    const char *subj_pv;
  CODE:
    subj_pv = SvPV(subject, subj_len);

    Newxz(sub, 1, nats_sub_t);
    sub->sid = self->next_sid++;
    sub->subject = newSVpvn(subj_pv, subj_len);
    sub->cb = newSVsv(cb);
    sub->queue_group = (queue_group && *queue_group) ? newSVpv(queue_group, 0) : NULL;
    sub->max_msgs = 0;
    sub->received = 0;
    nats_register_sub(self, sub);

    int n;
    if (queue_group && *queue_group) {
        n = snprintf(buf, sizeof(buf), "SUB %.*s %s %" UVuf "\r\n",
                     (int)subj_len, subj_pv, queue_group, (UV)sub->sid);
    } else {
        n = snprintf(buf, sizeof(buf), "SUB %.*s %" UVuf "\r\n",
                     (int)subj_len, subj_pv, (UV)sub->sid);
    }

    if (self->connected || self->connecting)
        nats_queue_write(self, buf, n);

    RETVAL = (UV)sub->sid;
  OUTPUT:
    RETVAL

void
unsubscribe(self, sid, max_msgs = 0)
    EV::Nats self
    UV sid
    int max_msgs
  PREINIT:
    char buf[64];
  CODE:
    /* Queue UNSUB while connected/connecting/reconnecting, mirroring
       subscribe(). When fully disconnected (no reconnect armed) the
       local-only update is enough; nats_resub_all will not resubscribe
       a removed sub on the next reconnect. */
    int can_queue = self->connected || self->connecting
                  || (self->reconnect_enabled && self->reconnect_timer_active);

    if (max_msgs > 0) {
        nats_sub_t *sub = nats_find_sub(self, (uint64_t)sid);
        if (sub)
            sub->max_msgs = max_msgs;

        int n = snprintf(buf, sizeof(buf), "UNSUB %" UVuf " %d\r\n", sid, max_msgs);
        if (can_queue)
            nats_queue_write(self, buf, n);
    } else {
        nats_sub_t *sub = nats_find_sub(self, (uint64_t)sid);
        int n = snprintf(buf, sizeof(buf), "UNSUB %" UVuf "\r\n", sid);
        if (can_queue)
            nats_queue_write(self, buf, n);
        if (sub)
            nats_remove_sub(self, sub);
    }

void
request(self, subject, payload, cb, timeout_ms = 5000)
    EV::Nats self
    SV *subject
    SV *payload
    SV *cb
    int timeout_ms
  PREINIT:
    char reply_subj[80];
    char hdr[MAX_CONTROL_LINE];
    STRLEN subj_len, pay_len;
    const char *subj_pv, *pay_pv;
  CODE:
    NATS_CROAK_UNLESS_CONNECTED(self);

    subj_pv = SvPV(subject, subj_len);
    if (SvOK(payload)) {
        pay_pv = SvPV(payload, pay_len);
    } else {
        pay_pv = "";
        pay_len = 0;
    }

    if (self->max_payload > 0 && pay_len > (size_t)self->max_payload)
        croak("payload exceeds max_payload (%d)", self->max_payload);

    if (!self->inbox_sub_sid) {
        char inbox_wild[48];
        snprintf(inbox_wild, sizeof(inbox_wild), "%s*", self->inbox_prefix);

        nats_sub_t *sub;
        Newxz(sub, 1, nats_sub_t);
        sub->sid = self->next_sid++;
        sub->subject = newSVpv(inbox_wild, 0);
        sub->cb = NULL;
        sub->queue_group = NULL;
        nats_register_sub(self, sub);
        self->inbox_sub_sid = sub->sid;

        char sbuf[MAX_CONTROL_LINE];
        int sn = snprintf(sbuf, sizeof(sbuf), "SUB %s %" UVuf "\r\n",
                          inbox_wild, (UV)sub->sid);
        nats_queue_write(self, sbuf, sn);
    }

    uint64_t req_id = self->next_req_id++;
    snprintf(reply_subj, sizeof(reply_subj), "%s%" UVuf, self->inbox_prefix, (UV)req_id);

    nats_req_t *req;
    Newxz(req, 1, nats_req_t);
    req->req_id = req_id;
    req->cb = newSVsv(cb);
    req->self = self;
    ngx_queue_insert_tail(&self->req_queue, &req->queue);

    if (timeout_ms > 0) {
        ev_timer_init(&req->timer, nats_on_request_timeout, timeout_ms / 1000.0, 0.0);
        ev_timer_start(self->loop, &req->timer);
        req->timer_active = 1;
    }

    int hdr_len = snprintf(hdr, sizeof(hdr), "PUB %.*s %s %lu\r\n",
                           (int)subj_len, subj_pv, reply_subj, (unsigned long)pay_len);

    size_t total = hdr_len + pay_len + 2;
    char *buf;
    Newx(buf, total, char);
    memcpy(buf, hdr, hdr_len);
    if (pay_len > 0) memcpy(buf + hdr_len, pay_pv, pay_len);
    buf[hdr_len + pay_len] = '\r';
    buf[hdr_len + pay_len + 1] = '\n';

    nats_queue_write(self, buf, total);
    Safefree(buf);

void
ping(self)
    EV::Nats self
  CODE:
    NATS_CROAK_UNLESS_CONNECTED(self);
    wbuf_append(self, "PING\r\n", 6);
    nats_try_write(self);

void
flush(self, cb = NULL)
    EV::Nats self
    SV *cb
  CODE:
    if (!self->connected)
        croak("not connected");
    wbuf_append(self, "PING\r\n", 6);
    nats_try_write(self);
    if (cb && SvOK(cb)) {
        nats_pong_cb_t *pcb;
        Newxz(pcb, 1, nats_pong_cb_t);
        pcb->cb = newSVsv(cb);
        ngx_queue_insert_tail(&self->pong_cbs, &pcb->queue);
    }

SV *
server_info(self)
    EV::Nats self
  CODE:
    if (self->server_info_json)
        RETVAL = newSVsv(self->server_info_json);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

int
max_payload(self, ...)
    EV::Nats self
  CODE:
    if (items > 1)
        self->max_payload = SvIV(ST(1));
    RETVAL = self->max_payload;
  OUTPUT:
    RETVAL

int
waiting_count(self)
    EV::Nats self
  CODE:
    RETVAL = self->waiting_count;
  OUTPUT:
    RETVAL

void
skip_waiting(self)
    EV::Nats self
  CODE:
    nats_skip_waiting(self);

void
reconnect(self, enable, ...)
    EV::Nats self
    int enable
  CODE:
    self->reconnect_enabled = enable;
    if (items > 2) self->reconnect_delay_ms = SvIV(ST(2));
    if (items > 3) self->max_reconnect_attempts = SvIV(ST(3));

int
reconnect_enabled(self)
    EV::Nats self
  CODE:
    RETVAL = self->reconnect_enabled;
  OUTPUT:
    RETVAL

int
connect_timeout(self, ...)
    EV::Nats self
  CODE:
    if (items > 1)
        self->connect_timeout_ms = SvIV(ST(1));
    RETVAL = self->connect_timeout_ms;
  OUTPUT:
    RETVAL

int
ping_interval(self, ...)
    EV::Nats self
  CODE:
    if (items > 1)
        self->ping_interval_ms = SvIV(ST(1));
    RETVAL = self->ping_interval_ms;
  OUTPUT:
    RETVAL

int
max_pings_outstanding(self, ...)
    EV::Nats self
  CODE:
    if (items > 1)
        self->max_pings_outstanding = SvIV(ST(1));
    RETVAL = self->max_pings_outstanding;
  OUTPUT:
    RETVAL

int
priority(self, ...)
    EV::Nats self
  CODE:
    if (items > 1)
        self->priority = SvIV(ST(1));
    RETVAL = self->priority;
  OUTPUT:
    RETVAL

int
keepalive(self, ...)
    EV::Nats self
  CODE:
    if (items > 1)
        self->keepalive = SvIV(ST(1));
    RETVAL = self->keepalive;
  OUTPUT:
    RETVAL

void
on_error(self, ...)
    EV::Nats self
  PPCODE:
    if (items > 1) {
        CLEAR_HANDLER(self->on_error);
        if (SvOK(ST(1)))
            self->on_error = newSVsv(ST(1));
    }
    if (GIMME_V != G_VOID && self->on_error)
        PUSHs(sv_2mortal(newSVsv(self->on_error)));

void
on_connect(self, ...)
    EV::Nats self
  PPCODE:
    if (items > 1) {
        CLEAR_HANDLER(self->on_connect);
        if (SvOK(ST(1)))
            self->on_connect = newSVsv(ST(1));
    }
    if (GIMME_V != G_VOID && self->on_connect)
        PUSHs(sv_2mortal(newSVsv(self->on_connect)));

void
on_disconnect(self, ...)
    EV::Nats self
  PPCODE:
    if (items > 1) {
        CLEAR_HANDLER(self->on_disconnect);
        if (SvOK(ST(1)))
            self->on_disconnect = newSVsv(ST(1));
    }
    if (GIMME_V != G_VOID && self->on_disconnect)
        PUSHs(sv_2mortal(newSVsv(self->on_disconnect)));

#ifdef HAVE_OPENSSL

void
tls(self, enable, ca_file = NULL, skip_verify = 0)
    EV::Nats self
    int enable
    const char *ca_file
    int skip_verify
  CODE:
    self->tls = enable;
    self->tls_skip_verify = skip_verify;
    nats_set_str(&self->tls_ca_file, (ca_file && *ca_file) ? ca_file : NULL);

#endif

void
stats(self)
    EV::Nats self
  PPCODE:
    EXTEND(SP, 8);
    PUSHs(sv_2mortal(newSVpvs("msgs_in")));
    PUSHs(sv_2mortal(newSVuv(self->msgs_in)));
    PUSHs(sv_2mortal(newSVpvs("msgs_out")));
    PUSHs(sv_2mortal(newSVuv(self->msgs_out)));
    PUSHs(sv_2mortal(newSVpvs("bytes_in")));
    PUSHs(sv_2mortal(newSVuv(self->bytes_in)));
    PUSHs(sv_2mortal(newSVpvs("bytes_out")));
    PUSHs(sv_2mortal(newSVuv(self->bytes_out)));

void
reset_stats(self)
    EV::Nats self
  CODE:
    self->msgs_in = 0;
    self->msgs_out = 0;
    self->bytes_in = 0;
    self->bytes_out = 0;

SV *
new_inbox(self)
    EV::Nats self
  CODE:
  {
    char inbox[80];
    int len = snprintf(inbox, sizeof(inbox), "%s%" UVuf, self->inbox_prefix, (UV)self->next_req_id++);
    RETVAL = newSVpvn(inbox, len);
  }
  OUTPUT:
    RETVAL

int
subscription_count(self)
    EV::Nats self
  CODE:
    RETVAL = HvKEYS(self->sub_map);
  OUTPUT:
    RETVAL

void
batch(self, code)
    EV::Nats self
    SV *code
  CODE:
    self->batch_mode = 1;
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(code, G_DISCARD);
        FREETMPS; LEAVE;
    }
    self->batch_mode = 0;
    if (self->wbuf_len > self->wbuf_off) {
        self->wbuf_dirty = 1;
        if (!self->prepare_active) {
            ev_prepare_start(self->loop, &self->prepare_watcher);
            self->prepare_active = 1;
        }
        /* Check slow consumer after batch */
        if (self->slow_consumer_bytes > 0 &&
            (self->wbuf_len - self->wbuf_off) > self->slow_consumer_bytes &&
            self->on_slow_consumer) {
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(sv_2mortal(newSVuv(self->wbuf_len - self->wbuf_off)));
            PUTBACK;
            call_sv(self->on_slow_consumer, G_DISCARD);
            FREETMPS; LEAVE;
        }
    }

void
slow_consumer(self, bytes_threshold, cb = NULL)
    EV::Nats self
    UV bytes_threshold
    SV *cb
  CODE:
    self->slow_consumer_bytes = (size_t)bytes_threshold;
    CLEAR_HANDLER(self->on_slow_consumer);
    if (cb && SvOK(cb))
        self->on_slow_consumer = newSVsv(cb);

void
on_lame_duck(self, ...)
    EV::Nats self
  PPCODE:
    if (items > 1) {
        CLEAR_HANDLER(self->on_ldm);
        if (SvOK(ST(1)))
            self->on_ldm = newSVsv(ST(1));
    }
    if (GIMME_V != G_VOID && self->on_ldm)
        PUSHs(sv_2mortal(newSVsv(self->on_ldm)));

  #ifdef HAVE_OPENSSL

void
nkey_seed(self, seed)
    EV::Nats self
    const char *seed
  CODE:
    nats_set_str(&self->nkey_seed, seed);

SV *
nkey_public_from_seed(class, seed)
    SV *class
    const char *seed
  CODE:
    (void)class;
    {
        char pub[64];
        int n = nats_nkey_public(seed, pub, sizeof(pub));
        if (n <= 0)
            croak("invalid NKey seed");
        RETVAL = newSVpvn(pub, n);
    }
  OUTPUT:
    RETVAL

SV *
nkey_generate_user_seed(class)
    SV *class
  CODE:
    (void)class;
    {
        unsigned char raw[36];
        /* S+User seed: b1 = PrefixByteSeed | (PrefixByteUser >> 5) = 0x95;
           b2 = (PrefixByteUser & 31) << 3 = 0x00. */
        raw[0] = 0x95;
        raw[1] = 0x00;
        nats_random_bytes(raw + 2, 32);
        uint16_t crc = nats_crc16(raw, 34);
        raw[34] = crc & 0xFF;
        raw[35] = (crc >> 8) & 0xFF;
        /* 36 bytes -> 58 base32 chars (288 bits, 57 full chars + 1 flush). */
        char enc[60];
        int n = nats_base32_encode(raw, sizeof(raw), enc, sizeof(enc));
        if (n < 0) croak("base32 buffer overflow");
        RETVAL = newSVpvn(enc, n);
    }
  OUTPUT:
    RETVAL

  #endif

void
jwt(self, jwt_token)
    EV::Nats self
    const char *jwt_token
  CODE:
    nats_set_str(&self->jwt, jwt_token);

void
drain(self, cb = NULL)
    EV::Nats self
    SV *cb
  CODE:
    if (!self->connected || self->draining)
        return;
    self->draining = 1;
    CLEAR_HANDLER(self->drain_cb);
    if (cb && SvOK(cb))
        self->drain_cb = newSVsv(cb);

    /* Send UNSUB for all subscriptions */
    {
        ngx_queue_t *q;
        char buf[64];
        ngx_queue_foreach(q, &self->subs) {
            nats_sub_t *sub = ngx_queue_data(q, nats_sub_t, queue);
            int n = snprintf(buf, sizeof(buf), "UNSUB %" UVuf "\r\n", (UV)sub->sid);
            wbuf_append(self, buf, n);
        }
    }

    /* Enqueue PING fence via pong_cbs — naturally ordered after any pending flush cbs.
       Use NULL cb; the PONG handler checks draining after firing pong_cb. */
    wbuf_append(self, "PING\r\n", 6);
    nats_try_write(self);
    {
        nats_pong_cb_t *pcb;
        Newxz(pcb, 1, nats_pong_cb_t);
        pcb->cb = NULL; /* drain completion marker */
        ngx_queue_insert_tail(&self->pong_cbs, &pcb->queue);
    }

void
DESTROY(self)
    EV::Nats self
  CODE:
    if (self->magic != NATS_MAGIC_ALIVE)
        return;

    self->magic = 0;
    self->intentional_disconnect = 1;

    if (PL_dirty) {
        if (self->fd >= 0)
            close(self->fd);
        return;
    }

    CLEAR_HANDLER(self->on_error);
    CLEAR_HANDLER(self->on_connect);
    CLEAR_HANDLER(self->on_disconnect);

    nats_stop_watchers(self);
    nats_stop_timers(self);

    while (!ngx_queue_empty(&self->req_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->req_queue);
        nats_req_t *req = ngx_queue_data(q, nats_req_t, queue);
        ngx_queue_remove(q);
        if (req->timer_active)
            ev_timer_stop(self->loop, &req->timer);
        CLEAR_HANDLER(req->cb);
        Safefree(req);
    }
    nats_skip_waiting(self);

    while (!ngx_queue_empty(&self->pong_cbs)) {
        ngx_queue_t *pq = ngx_queue_head(&self->pong_cbs);
        nats_pong_cb_t *pcb = ngx_queue_data(pq, nats_pong_cb_t, queue);
        ngx_queue_remove(pq);
        CLEAR_HANDLER(pcb->cb);
        Safefree(pcb);
    }

    while (!ngx_queue_empty(&self->subs)) {
        ngx_queue_t *q = ngx_queue_head(&self->subs);
        nats_sub_t *sub = ngx_queue_data(q, nats_sub_t, queue);
        nats_remove_sub(self, sub);
    }

    if (self->fd >= 0) {
        close(self->fd);
        self->fd = -1;
    }

    CLEAR_HANDLER(self->server_info_json);
    CLEAR_HANDLER(self->drain_cb);

    nats_free_server_pool(self);
    if (self->sub_map) {
        SvREFCNT_dec((SV *)self->sub_map);
        self->sub_map = NULL;
    }

  #ifdef HAVE_OPENSSL
    nats_ssl_cleanup(self);
    if (self->ssl_ctx) { SSL_CTX_free(self->ssl_ctx); self->ssl_ctx = NULL; }
    Safefree(self->tls_ca_file);
  #endif

    Safefree(self->rbuf);
    Safefree(self->wbuf);
    Safefree(self->host);
    Safefree(self->path);
    Safefree(self->user);
    Safefree(self->pass);
    Safefree(self->token);
    Safefree(self->name);
    Safefree(self->nkey_seed);
    Safefree(self->jwt);
    Safefree(self->server_nonce);
    CLEAR_HANDLER(self->on_slow_consumer);
    CLEAR_HANDLER(self->on_ldm);

    Safefree(self);
