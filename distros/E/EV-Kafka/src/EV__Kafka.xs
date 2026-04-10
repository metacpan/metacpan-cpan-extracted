#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"
#include "ngx-queue.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/time.h>

#ifdef HAVE_OPENSSL
  #include <openssl/ssl.h>
  #include <openssl/err.h>
  #include <openssl/x509v3.h>
  #include <openssl/hmac.h>
  #include <openssl/sha.h>
  #include <openssl/rand.h>
  #include <openssl/bio.h>
  #include <openssl/buffer.h>
  #include <openssl/evp.h>
#endif

#ifdef HAVE_LZ4
  #include <lz4.h>
#endif

#ifdef HAVE_ZLIB
  #include <zlib.h>
#endif

/* ================================================================
 * Constants
 * ================================================================ */

#define KF_MAGIC_ALIVE 0xCAFEBEEF
#define KF_MAGIC_FREED 0xDEADCAFE

#define KF_BUF_INIT 16384

/* Connection states */
#define CONN_DISCONNECTED    0
#define CONN_CONNECTING      1
#define CONN_TLS_HANDSHAKE   2
#define CONN_SASL_HANDSHAKE  3
#define CONN_SASL_AUTH       4
#define CONN_API_VERSIONS    5
#define CONN_READY           6

/* Kafka API keys */
#define API_PRODUCE            0
#define API_FETCH              1
#define API_LIST_OFFSETS       2
#define API_METADATA           3
#define API_OFFSET_COMMIT      8
#define API_OFFSET_FETCH       9
#define API_FIND_COORDINATOR  10
#define API_JOIN_GROUP        11
#define API_HEARTBEAT         12
#define API_LEAVE_GROUP       13
#define API_SYNC_GROUP        14
#define API_DESCRIBE_GROUPS   15
#define API_LIST_GROUPS       16
#define API_SASL_HANDSHAKE    17
#define API_API_VERSIONS      18
#define API_CREATE_TOPICS     19
#define API_DELETE_TOPICS     20
#define API_INIT_PRODUCER_ID  22
#define API_ADD_PARTITIONS_TXN 24
#define API_END_TXN           26
#define API_TXN_OFFSET_COMMIT 28
#define API_SASL_AUTHENTICATE 36

#define API_VERSIONS_MAX_KEY  64

/* Compression types */
#define COMPRESS_NONE  0
#define COMPRESS_GZIP  1
#define COMPRESS_SNAPPY 2
#define COMPRESS_LZ4   3
#define COMPRESS_ZSTD  4

#define CLEAR_HANDLER(field) \
    do { if (NULL != (field)) { SvREFCNT_dec(field); (field) = NULL; } } while(0)

/* ================================================================
 * Type declarations
 * ================================================================ */

typedef struct kf_buf_s kf_buf_t;
typedef struct ev_kafka_conn_s ev_kafka_conn_t;
typedef struct ev_kafka_conn_cb_s ev_kafka_conn_cb_t;
typedef struct kf_topic_meta_s kf_topic_meta_t;
typedef struct kf_partition_meta_s kf_partition_meta_t;
typedef struct kf_consumer_group_s kf_consumer_group_t;
typedef struct ev_kafka_s ev_kafka_t;

typedef ev_kafka_conn_t* EV__Kafka__Conn;
typedef ev_kafka_t* EV__Kafka;

/* ================================================================
 * Dynamic buffer
 * ================================================================ */

struct kf_buf_s {
    char   *data;
    size_t  len;
    size_t  cap;
};

static void kf_buf_init(kf_buf_t *b) {
    Newx(b->data, 256, char);
    b->len = 0;
    b->cap = 256;
}

static void kf_buf_grow(kf_buf_t *b, size_t need) {
    if (b->cap >= need) return;
    size_t newcap = b->cap * 2;
    if (newcap < need) newcap = need;
    Renew(b->data, newcap, char);
    b->cap = newcap;
}

static void kf_buf_free(kf_buf_t *b) {
    if (b->data) { Safefree(b->data); b->data = NULL; }
    b->len = 0;
    b->cap = 0;
}

static void kf_buf_append(kf_buf_t *b, const char *data, size_t len) {
    kf_buf_grow(b, b->len + len);
    Copy(data, b->data + b->len, len, char);
    b->len += len;
}

static void kf_buf_append_i8(kf_buf_t *b, int8_t val) {
    kf_buf_grow(b, b->len + 1);
    b->data[b->len++] = val;
}

static void kf_buf_append_i16(kf_buf_t *b, int16_t val) {
    kf_buf_grow(b, b->len + 2);
    uint16_t v = htons((uint16_t)val);
    memcpy(b->data + b->len, &v, 2);
    b->len += 2;
}

static void kf_buf_append_i32(kf_buf_t *b, int32_t val) {
    kf_buf_grow(b, b->len + 4);
    uint32_t v = htonl((uint32_t)val);
    memcpy(b->data + b->len, &v, 4);
    b->len += 4;
}

static void kf_buf_append_i64(kf_buf_t *b, int64_t val) {
    kf_buf_grow(b, b->len + 8);
    uint32_t hi = htonl((uint32_t)((uint64_t)val >> 32));
    uint32_t lo = htonl((uint32_t)((uint64_t)val & 0xFFFFFFFF));
    memcpy(b->data + b->len, &hi, 4);
    memcpy(b->data + b->len + 4, &lo, 4);
    b->len += 8;
}

/* Kafka STRING: INT16 length + bytes. NULL → -1 length */
static void kf_buf_append_string(kf_buf_t *b, const char *s, int16_t len) {
    kf_buf_append_i16(b, len);
    if (len > 0) kf_buf_append(b, s, len);
}

static void kf_buf_append_nullable_string(kf_buf_t *b, const char *s, int16_t len) {
    if (!s) {
        kf_buf_append_i16(b, -1);
    } else {
        kf_buf_append_i16(b, len);
        if (len > 0) kf_buf_append(b, s, len);
    }
}

/* Kafka BYTES: INT32 length + bytes */
static void kf_buf_append_bytes(kf_buf_t *b, const char *s, int32_t len) {
    kf_buf_append_i32(b, len);
    if (len > 0) kf_buf_append(b, s, len);
}

static void kf_buf_append_nullable_bytes(kf_buf_t *b, const char *s, int32_t len) {
    if (!s) {
        kf_buf_append_i32(b, -1);
    } else {
        kf_buf_append_i32(b, len);
        if (len > 0) kf_buf_append(b, s, len);
    }
}

/* Unsigned varint (ZigZag for signed is not used in Kafka framing) */
static void kf_buf_append_uvarint(kf_buf_t *b, uint64_t val) {
    kf_buf_grow(b, b->len + 10);
    while (val >= 0x80) {
        b->data[b->len++] = (char)((val & 0x7F) | 0x80);
        val >>= 7;
    }
    b->data[b->len++] = (char)val;
}

/* Signed varint (ZigZag encoding) */
static void kf_buf_append_varint(kf_buf_t *b, int64_t val) {
    uint64_t uval = ((uint64_t)val << 1) ^ (uint64_t)(val >> 63);
    kf_buf_append_uvarint(b, uval);
}

/* Compact string: uvarint(len+1) + bytes. NULL → 0 */
static void kf_buf_append_compact_string(kf_buf_t *b, const char *s, int32_t len) {
    if (!s) {
        kf_buf_append_uvarint(b, 0);
    } else {
        kf_buf_append_uvarint(b, (uint64_t)len + 1);
        if (len > 0) kf_buf_append(b, s, len);
    }
}

/* Tagged fields: just 0 = no tagged fields */
static void kf_buf_append_tagged_fields(kf_buf_t *b) {
    kf_buf_append_uvarint(b, 0);
}

/* ================================================================
 * Wire read helpers (big-endian)
 * ================================================================ */

static int16_t kf_read_i16(const char *buf) {
    uint16_t v;
    memcpy(&v, buf, 2);
    return (int16_t)ntohs(v);
}

static int32_t kf_read_i32(const char *buf) {
    uint32_t v;
    memcpy(&v, buf, 4);
    return (int32_t)ntohl(v);
}

static int64_t kf_read_i64(const char *buf) {
    uint32_t hi, lo;
    memcpy(&hi, buf, 4);
    memcpy(&lo, buf + 4, 4);
    return ((int64_t)ntohl(hi) << 32) | (uint32_t)ntohl(lo);
}

/* Read unsigned varint, returns bytes consumed or -1 on error */
static int kf_read_uvarint(const char *buf, const char *end, uint64_t *out) {
    uint64_t val = 0;
    int shift = 0;
    const char *p = buf;
    while (p < end) {
        uint8_t b = (uint8_t)*p++;
        val |= ((uint64_t)(b & 0x7F)) << shift;
        if (!(b & 0x80)) {
            *out = val;
            return (int)(p - buf);
        }
        shift += 7;
        if (shift >= 64) return -1;
    }
    return -1; /* incomplete */
}

/* Read signed varint (ZigZag) */
static int kf_read_varint(const char *buf, const char *end, int64_t *out) {
    uint64_t uval;
    int n = kf_read_uvarint(buf, end, &uval);
    if (n < 0) return n;
    *out = (int64_t)((uval >> 1) ^ -(int64_t)(uval & 1));
    return n;
}

/* Read Kafka STRING: i16 len + bytes. Returns pointer into buf, sets *len. Returns bytes consumed. */
static int kf_read_string(const char *buf, const char *end, const char **out, int16_t *slen) {
    if (end - buf < 2) return -1;
    int16_t len = kf_read_i16(buf);
    if (len < 0) { /* nullable null */
        *out = NULL;
        *slen = 0;
        return 2;
    }
    if (end - buf < 2 + len) return -1;
    *out = buf + 2;
    *slen = len;
    return 2 + len;
}

/* Read compact string: uvarint(len+1) + bytes */
static int kf_read_compact_string(const char *buf, const char *end, const char **out, int32_t *slen) {
    uint64_t raw;
    int n = kf_read_uvarint(buf, end, &raw);
    if (n < 0) return -1;
    if (raw == 0) {
        *out = NULL;
        *slen = 0;
        return n;
    }
    int32_t len = (int32_t)(raw - 1);
    if (end - buf - n < len) return -1;
    *out = buf + n;
    *slen = len;
    return n + len;
}

/* Skip tagged fields */
static int kf_skip_tagged_fields(const char *buf, const char *end) {
    uint64_t count;
    int n = kf_read_uvarint(buf, end, &count);
    if (n < 0) return -1;
    const char *p = buf + n;
    uint64_t i;
    for (i = 0; i < count; i++) {
        uint64_t tag;
        int tn = kf_read_uvarint(p, end, &tag);
        if (tn < 0) return -1;
        p += tn;
        uint64_t dlen;
        int dn = kf_read_uvarint(p, end, &dlen);
        if (dn < 0) return -1;
        p += dn;
        if ((uint64_t)(end - p) < dlen) return -1;
        p += dlen;
    }
    return (int)(p - buf);
}

/* ================================================================
 * CRC32C (software implementation)
 * ================================================================ */

static uint32_t crc32c_table[256];
static int crc32c_table_inited = 0;

static void crc32c_init_table(void) {
    uint32_t i, j;
    for (i = 0; i < 256; i++) {
        uint32_t crc = i;
        for (j = 0; j < 8; j++) {
            if (crc & 1)
                crc = (crc >> 1) ^ 0x82F63B78;
            else
                crc >>= 1;
        }
        crc32c_table[i] = crc;
    }
    crc32c_table_inited = 1;
}

static uint32_t crc32c(const char *buf, size_t len) {
    uint32_t crc = 0xFFFFFFFF;
    size_t i;
    if (!crc32c_table_inited) crc32c_init_table();
    for (i = 0; i < len; i++)
        crc = crc32c_table[(crc ^ (uint8_t)buf[i]) & 0xFF] ^ (crc >> 8);
    return crc ^ 0xFFFFFFFF;
}

/* ================================================================
 * Connection callback struct
 * ================================================================ */

struct ev_kafka_conn_cb_s {
    SV          *cb;
    ngx_queue_t  queue;
    int32_t      correlation_id;
    int16_t      api_key;
    int16_t      api_version;
    int          internal;  /* 1 = internal handshake cb, don't invoke Perl */
};

/* ================================================================
 * Broker connection struct (Layer 1)
 * ================================================================ */

struct ev_kafka_conn_s {
    unsigned int magic;
    struct ev_loop *loop;
    int fd;
    int state;

    /* EV watchers */
    ev_io rio, wio;
    ev_timer timer;
    int reading, writing, timing;

    /* TLS */
#ifdef HAVE_OPENSSL
    SSL_CTX *ssl_ctx;
    SSL     *ssl;
#endif
    int tls_enabled;
    char *tls_ca_file;
    int tls_skip_verify;

    /* Connection params */
    char *host;
    int   port;
    int   node_id;

    /* SASL */
    char *sasl_mechanism;
    char *sasl_username;
    char *sasl_password;

    /* SCRAM state */
    int scram_step;
    char *scram_nonce;
    char *scram_client_first;
    size_t scram_client_first_len;

    /* Buffers */
    char   *rbuf;
    size_t  rbuf_len, rbuf_cap;
    char   *wbuf;
    size_t  wbuf_len, wbuf_off, wbuf_cap;

    /* Request/response correlation */
    ngx_queue_t cb_queue;
    int32_t next_correlation_id;
    int pending_count;

    /* Client identity */
    char *client_id;
    int   client_id_len;

    /* API version negotiation */
    int16_t api_versions[API_VERSIONS_MAX_KEY];
    int api_versions_known;

    /* Event handlers */
    SV *on_error;
    SV *on_connect;
    SV *on_disconnect;

    /* Reconnection */
    int auto_reconnect;
    int reconnect_delay_ms;
    ev_timer reconnect_timer;
    int reconnect_timing;
    int intentional_disconnect;

    /* Safety */
    int callback_depth;

    /* Back-pointer to cluster */
    ev_kafka_t *cluster;
    ngx_queue_t cluster_queue;
};

/* ================================================================
 * Forward declarations
 * ================================================================ */

static void conn_io_cb(EV_P_ ev_io *w, int revents);
static void conn_timer_cb(EV_P_ ev_timer *w, int revents);
static void conn_reconnect_timer_cb(EV_P_ ev_timer *w, int revents);
static void conn_start_reading(ev_kafka_conn_t *self);
static void conn_stop_reading(ev_kafka_conn_t *self);
static void conn_start_writing(ev_kafka_conn_t *self);
static void conn_stop_writing(ev_kafka_conn_t *self);
static void conn_emit_error(pTHX_ ev_kafka_conn_t *self, const char *msg);
static void conn_cleanup(pTHX_ ev_kafka_conn_t *self);
static int  conn_check_destroyed(ev_kafka_conn_t *self);
static void conn_cancel_pending(pTHX_ ev_kafka_conn_t *self, const char *err);
static void conn_on_connect_done(pTHX_ ev_kafka_conn_t *self);
static void conn_process_responses(pTHX_ ev_kafka_conn_t *self);
static void conn_schedule_reconnect(pTHX_ ev_kafka_conn_t *self);
static int32_t conn_send_request(pTHX_ ev_kafka_conn_t *self,
    int16_t api_key, int16_t api_version, kf_buf_t *body, SV *cb,
    int internal, int no_response);
static void conn_send_api_versions(pTHX_ ev_kafka_conn_t *self);
static void conn_start_connect(pTHX_ ev_kafka_conn_t *self,
    const char *host, int port, double timeout);
static void conn_send_sasl_handshake(pTHX_ ev_kafka_conn_t *self);
static void conn_parse_sasl_handshake_response(pTHX_ ev_kafka_conn_t *self,
    const char *data, size_t len);
static void conn_send_sasl_authenticate(pTHX_ ev_kafka_conn_t *self);
static void conn_parse_sasl_authenticate_response(pTHX_ ev_kafka_conn_t *self,
    const char *data, size_t len);

/* Response parsers */
static SV* conn_parse_metadata_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_produce_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_fetch_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_list_offsets_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_find_coordinator_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_join_group_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_sync_group_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_heartbeat_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_offset_commit_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_offset_fetch_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_leave_group_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_create_topics_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_delete_topics_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_init_producer_id_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_add_partitions_to_txn_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_end_txn_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);
static SV* conn_parse_txn_offset_commit_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len);

#ifdef HAVE_OPENSSL
static int is_ip_literal(const char *host);
#endif

/* ================================================================
 * I/O helpers (with optional TLS)
 * ================================================================ */

static ssize_t kf_io_read(ev_kafka_conn_t *self, void *buf, size_t len) {
#ifdef HAVE_OPENSSL
    if (self->ssl) {
        int ssl_len = (len > (size_t)INT_MAX) ? INT_MAX : (int)len;
        int ret = SSL_read(self->ssl, buf, ssl_len);
        if (ret <= 0) {
            int err = SSL_get_error(self->ssl, ret);
            if (err == SSL_ERROR_WANT_READ) {
                errno = EAGAIN;
                return -1;
            }
            if (err == SSL_ERROR_WANT_WRITE) {
                conn_start_writing(self);
                errno = EAGAIN;
                return -1;
            }
            if (err == SSL_ERROR_ZERO_RETURN) return 0;
            errno = EIO;
            return -1;
        }
        return ret;
    }
#endif
    return read(self->fd, buf, len);
}

static ssize_t kf_io_write(ev_kafka_conn_t *self, const void *buf, size_t len) {
#ifdef HAVE_OPENSSL
    if (self->ssl) {
        int ssl_len = (len > (size_t)INT_MAX) ? INT_MAX : (int)len;
        int ret = SSL_write(self->ssl, buf, ssl_len);
        if (ret <= 0) {
            int err = SSL_get_error(self->ssl, ret);
            if (err == SSL_ERROR_WANT_WRITE) {
                errno = EAGAIN;
                return -1;
            }
            if (err == SSL_ERROR_WANT_READ) {
                conn_start_reading(self);
                errno = EAGAIN;
                return -1;
            }
            errno = EIO;
            return -1;
        }
        return ret;
    }
#endif
    return write(self->fd, buf, len);
}

/* ================================================================
 * Buffer management
 * ================================================================ */

static void conn_ensure_rbuf(ev_kafka_conn_t *self, size_t need) {
    if (self->rbuf_cap >= need) return;
    size_t newcap = self->rbuf_cap * 2;
    if (newcap < need) newcap = need;
    Renew(self->rbuf, newcap, char);
    self->rbuf_cap = newcap;
}

static void conn_ensure_wbuf(ev_kafka_conn_t *self, size_t need) {
    if (self->wbuf_cap >= need) return;
    size_t newcap = self->wbuf_cap * 2;
    if (newcap < need) newcap = need;
    Renew(self->wbuf, newcap, char);
    self->wbuf_cap = newcap;
}

/* ================================================================
 * Watcher control
 * ================================================================ */

static void conn_start_reading(ev_kafka_conn_t *self) {
    if (!self->reading && self->fd >= 0) {
        ev_io_start(self->loop, &self->rio);
        self->reading = 1;
    }
}

static void conn_stop_reading(ev_kafka_conn_t *self) {
    if (self->reading) {
        ev_io_stop(self->loop, &self->rio);
        self->reading = 0;
    }
}

static void conn_start_writing(ev_kafka_conn_t *self) {
    if (!self->writing && self->fd >= 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }
}

static void conn_stop_writing(ev_kafka_conn_t *self) {
    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

/* ================================================================
 * Callback invocation helpers
 * ================================================================ */

static void conn_emit_error(pTHX_ ev_kafka_conn_t *self, const char *msg) {
    if (!self->on_error)
        croak("EV::Kafka::Conn: %s", msg);

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(msg, 0)));
        PUTBACK;
        call_sv(self->on_error, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) {
            warn("EV::Kafka::Conn: on_error callback error: %s", SvPV_nolen(ERRSV));
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
}

static void conn_emit_connect(pTHX_ ev_kafka_conn_t *self) {
    if (!self->on_connect) return;

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(self->on_connect, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) {
            warn("EV::Kafka::Conn: on_connect callback error: %s", SvPV_nolen(ERRSV));
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
}

static void conn_emit_disconnect(pTHX_ ev_kafka_conn_t *self) {
    if (!self->on_disconnect) return;

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(self->on_disconnect, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) {
            warn("EV::Kafka::Conn: on_disconnect callback error: %s", SvPV_nolen(ERRSV));
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
}

/* Invoke a command callback: cb->(result, error) */
static void conn_invoke_cb(pTHX_ ev_kafka_conn_t *self, SV *cb, SV *result, SV *error) {
    if (!cb) return;

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs(result ? result : &PL_sv_undef);
        PUSHs(error  ? error  : &PL_sv_undef);
        PUTBACK;
        call_sv(cb, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) {
            warn("EV::Kafka::Conn: callback error: %s", SvPV_nolen(ERRSV));
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
}

static int conn_check_destroyed(ev_kafka_conn_t *self) {
    return self->magic != KF_MAGIC_ALIVE;
}

/* ================================================================
 * Connection cleanup
 * ================================================================ */

static void conn_cleanup(pTHX_ ev_kafka_conn_t *self) {
    conn_stop_reading(self);
    conn_stop_writing(self);
    if (self->timing) {
        ev_timer_stop(self->loop, &self->timer);
        self->timing = 0;
    }
#ifdef HAVE_OPENSSL
    if (self->ssl) {
        SSL_free(self->ssl);
        self->ssl = NULL;
    }
    if (self->ssl_ctx) {
        SSL_CTX_free(self->ssl_ctx);
        self->ssl_ctx = NULL;
    }
#endif
    if (self->fd >= 0) {
        close(self->fd);
        self->fd = -1;
    }
    self->state = CONN_DISCONNECTED;
}

static void conn_cancel_pending(pTHX_ ev_kafka_conn_t *self, const char *err) {
    SV *err_sv = newSVpv(err, 0);
    ngx_queue_t *q;

    while (!ngx_queue_empty(&self->cb_queue)) {
        q = ngx_queue_head(&self->cb_queue);
        ngx_queue_remove(q);
        ev_kafka_conn_cb_t *cbt = ngx_queue_data(q, ev_kafka_conn_cb_t, queue);
        self->pending_count--;
        if (cbt->cb && !cbt->internal) {
            conn_invoke_cb(aTHX_ self, cbt->cb, NULL, sv_2mortal(newSVsv(err_sv)));
            if (conn_check_destroyed(self)) {
                SvREFCNT_dec(cbt->cb);
                Safefree(cbt);
                SvREFCNT_dec(err_sv);
                return;
            }
        }
        if (cbt->cb) SvREFCNT_dec(cbt->cb);
        Safefree(cbt);
    }
    SvREFCNT_dec(err_sv);
}

static void conn_handle_disconnect(pTHX_ ev_kafka_conn_t *self, const char *reason) {
    conn_cleanup(aTHX_ self);

    conn_emit_disconnect(aTHX_ self);
    if (conn_check_destroyed(self)) return;

    conn_cancel_pending(aTHX_ self, reason);
    if (conn_check_destroyed(self)) return;

    if (!self->intentional_disconnect && self->auto_reconnect) {
        conn_schedule_reconnect(aTHX_ self);
    }
}

/* ================================================================
 * Reconnection
 * ================================================================ */

static void conn_reconnect_timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_kafka_conn_t *self = (ev_kafka_conn_t *)((char *)w - offsetof(ev_kafka_conn_t, reconnect_timer));
    dTHX;
    (void)loop;
    (void)revents;

    self->reconnect_timing = 0;
    if (self->magic != KF_MAGIC_ALIVE) return;
    if (self->state != CONN_DISCONNECTED) return;
    if (!self->host) return;

    conn_start_connect(aTHX_ self, self->host, self->port, 10.0);
}

static void conn_schedule_reconnect(pTHX_ ev_kafka_conn_t *self) {
    if (self->reconnect_timing) return;
    double delay = self->reconnect_delay_ms / 1000.0;
    if (delay < 0.01) delay = 1.0;
    ev_timer_init(&self->reconnect_timer, conn_reconnect_timer_cb, delay, 0.0);
    ev_timer_start(self->loop, &self->reconnect_timer);
    self->reconnect_timing = 1;
}

/* ================================================================
 * Request framing
 * ================================================================ */

/* Build request header + body, append to wbuf, enqueue callback.
 * For api_version >= threshold, uses compact header (v2).
 * ApiVersions v3+ uses flexible (v1) request header.
 * Returns correlation_id.
 */
static int32_t conn_send_request(pTHX_ ev_kafka_conn_t *self,
    int16_t api_key, int16_t api_version, kf_buf_t *body, SV *cb,
    int internal, int no_response)
{
    int32_t corr_id = self->next_correlation_id++;
    kf_buf_t hdr;
    kf_buf_init(&hdr);

    /* Request header v1 (non-flexible): api_key, api_version, correlation_id, client_id */
    /* Request header v2 (flexible): same + tagged_fields */
    /* ApiVersions v3+ uses header v2 (flexible) */
    int flexible = (api_key == API_API_VERSIONS && api_version >= 3);

    kf_buf_append_i16(&hdr, api_key);
    kf_buf_append_i16(&hdr, api_version);
    kf_buf_append_i32(&hdr, corr_id);

    if (flexible) {
        /* compact string for client_id */
        kf_buf_append_compact_string(&hdr, self->client_id, self->client_id_len);
        kf_buf_append_tagged_fields(&hdr);
    } else {
        kf_buf_append_nullable_string(&hdr, self->client_id, self->client_id_len);
    }

    /* Total size = header + body */
    size_t raw_size = hdr.len + body->len;
    if (raw_size > (size_t)INT32_MAX) {
        kf_buf_free(&hdr);
        croak("request too large");
    }
    int32_t total_size = (int32_t)raw_size;

    /* Compact wbuf if sent prefix wastes significant space */
    if (self->wbuf_off > 0 && self->wbuf_off > self->wbuf_len / 2) {
        self->wbuf_len -= self->wbuf_off;
        if (self->wbuf_len > 0)
            memmove(self->wbuf, self->wbuf + self->wbuf_off, self->wbuf_len);
        self->wbuf_off = 0;
    }

    /* Append to wbuf: [size:i32][header][body] */
    conn_ensure_wbuf(self, self->wbuf_len + 4 + total_size);
    {
        uint32_t sz = htonl((uint32_t)total_size);
        memcpy(self->wbuf + self->wbuf_len, &sz, 4);
        self->wbuf_len += 4;
    }
    Copy(hdr.data, self->wbuf + self->wbuf_len, hdr.len, char);
    self->wbuf_len += hdr.len;
    Copy(body->data, self->wbuf + self->wbuf_len, body->len, char);
    self->wbuf_len += body->len;

    kf_buf_free(&hdr);

    /* Enqueue callback (skip for no-response requests like acks=0) */
    if (!no_response) {
        ev_kafka_conn_cb_t *cbt;
        Newxz(cbt, 1, ev_kafka_conn_cb_t);
        cbt->correlation_id = corr_id;
        cbt->api_key = api_key;
        cbt->api_version = api_version;
        cbt->internal = internal;
        if (cb) {
            cbt->cb = cb;
            SvREFCNT_inc(cb);
        }
        ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
        self->pending_count++;
    }

    conn_start_writing(self);

    return corr_id;
}

/* ================================================================
 * ApiVersions (API 18)
 * ================================================================ */

static void conn_send_api_versions(pTHX_ ev_kafka_conn_t *self) {
    kf_buf_t body;
    kf_buf_init(&body);

    /* ApiVersions v0: empty body, most compatible */
    self->state = CONN_API_VERSIONS;
    conn_send_request(aTHX_ self, API_API_VERSIONS, 0, &body, NULL, 1, 0);
    kf_buf_free(&body);
}

static void conn_parse_api_versions_response(pTHX_ ev_kafka_conn_t *self,
    const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    int i;

    /* Initialize all as unsupported */
    for (i = 0; i < API_VERSIONS_MAX_KEY; i++)
        self->api_versions[i] = -1;

    if (end - p < 2) goto err;
    int16_t error_code = kf_read_i16(p); p += 2;
    if (error_code != 0) {
        char errbuf[128];
        snprintf(errbuf, sizeof(errbuf), "ApiVersions error: %d", error_code);
        conn_emit_error(aTHX_ self, errbuf);
        if (conn_check_destroyed(self)) return;
        conn_handle_disconnect(aTHX_ self, errbuf);
        return;
    }

    /* v0 response: array(api_key:i16, min_version:i16, max_version:i16) */
    if (end - p < 4) goto err;
    int32_t count = kf_read_i32(p); p += 4;

    for (i = 0; i < count; i++) {
        if (end - p < 6) goto err;
        int16_t key = kf_read_i16(p); p += 2;
        /* int16_t min_version = kf_read_i16(p); */ p += 2;
        int16_t max_version = kf_read_i16(p); p += 2;

        if (key >= 0 && key < API_VERSIONS_MAX_KEY)
            self->api_versions[key] = max_version;
    }

    self->api_versions_known = 1;

    /* Handshake complete (or continue to SASL) */
    if (self->sasl_mechanism) {
        self->state = CONN_SASL_HANDSHAKE;
        conn_send_sasl_handshake(aTHX_ self);
    } else {
        self->state = CONN_READY;
        conn_emit_connect(aTHX_ self);
    }
    return;

err:
    conn_emit_error(aTHX_ self, "malformed ApiVersions response");
    if (conn_check_destroyed(self)) return;
    conn_handle_disconnect(aTHX_ self, "malformed ApiVersions response");
}

/* ================================================================
 * SASL Handshake (API 17) + Authenticate (API 36)
 * ================================================================ */

static void conn_send_sasl_handshake(pTHX_ ev_kafka_conn_t *self) {
    kf_buf_t body;
    kf_buf_init(&body);

    /* SaslHandshake v1: mechanism (STRING) */
    STRLEN mech_len = strlen(self->sasl_mechanism);
    kf_buf_append_string(&body, self->sasl_mechanism, (int16_t)mech_len);

    self->state = CONN_SASL_HANDSHAKE;
    conn_send_request(aTHX_ self, API_SASL_HANDSHAKE, 1, &body, NULL, 1, 0);
    kf_buf_free(&body);
}

static void conn_parse_sasl_handshake_response(pTHX_ ev_kafka_conn_t *self,
    const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;

    if (end - p < 2) goto err;
    int16_t error_code = kf_read_i16(p); p += 2;

    /* skip mechanisms array */
    if (end - p < 4) goto err;
    int32_t count = kf_read_i32(p); p += 4;
    int32_t i;
    for (i = 0; i < count; i++) {
        const char *s; int16_t slen;
        int n = kf_read_string(p, end, &s, &slen);
        if (n < 0) goto err;
        p += n;
    }

    if (error_code != 0) {
        conn_emit_error(aTHX_ self, "SASL handshake failed: mechanism not supported");
        if (conn_check_destroyed(self)) return;
        conn_handle_disconnect(aTHX_ self, "SASL handshake failed");
        return;
    }

    /* Proceed to authenticate */
    conn_send_sasl_authenticate(aTHX_ self);
    return;

err:
    conn_emit_error(aTHX_ self, "malformed SaslHandshake response");
    if (conn_check_destroyed(self)) return;
    conn_handle_disconnect(aTHX_ self, "malformed SaslHandshake response");
}

/* SCRAM state for multi-step SASL */
#define SCRAM_STEP_CLIENT_FIRST  0
#define SCRAM_STEP_CLIENT_FINAL  1
#define SCRAM_STEP_DONE          2

static void conn_send_sasl_authenticate(pTHX_ ev_kafka_conn_t *self) {
    kf_buf_t body;
    kf_buf_init(&body);

    if (self->sasl_mechanism && strcmp(self->sasl_mechanism, "PLAIN") == 0) {
        /* PLAIN: \0username\0password */
        STRLEN ulen = self->sasl_username ? strlen(self->sasl_username) : 0;
        STRLEN plen = self->sasl_password ? strlen(self->sasl_password) : 0;
        int32_t auth_len = 1 + (int32_t)ulen + 1 + (int32_t)plen;

        kf_buf_append_i32(&body, auth_len);
        kf_buf_append_i8(&body, 0);
        if (ulen > 0) kf_buf_append(&body, self->sasl_username, ulen);
        kf_buf_append_i8(&body, 0);
        if (plen > 0) kf_buf_append(&body, self->sasl_password, plen);
    }
#ifdef HAVE_OPENSSL
    else if (self->sasl_mechanism &&
        (strcmp(self->sasl_mechanism, "SCRAM-SHA-256") == 0 ||
         strcmp(self->sasl_mechanism, "SCRAM-SHA-512") == 0)) {
        /* SCRAM client-first-message: n,,n=<user>,r=<nonce> */
        char nonce[33];
        {
            unsigned char rnd[16];
            int i;
            RAND_bytes(rnd, 16);
            for (i = 0; i < 16; i++)
                snprintf(nonce + i*2, 3, "%02x", rnd[i]);
            nonce[32] = '\0';
        }

        /* save nonce for later steps */
        if (self->scram_nonce) Safefree(self->scram_nonce);
        self->scram_nonce = savepv(nonce);
        self->scram_step = SCRAM_STEP_CLIENT_FIRST;

        kf_buf_t msg;
        kf_buf_init(&msg);
        kf_buf_append(&msg, "n,,n=", 5);
        kf_buf_append(&msg, self->sasl_username, strlen(self->sasl_username));
        kf_buf_append(&msg, ",r=", 3);
        kf_buf_append(&msg, nonce, 32);

        /* save client-first-message-bare for later binding */
        if (self->scram_client_first) Safefree(self->scram_client_first);
        /* bare = after "n,," */
        self->scram_client_first = savepvn(msg.data + 3, msg.len - 3);
        self->scram_client_first_len = msg.len - 3;

        kf_buf_append_i32(&body, (int32_t)msg.len);
        kf_buf_append(&body, msg.data, msg.len);
        kf_buf_free(&msg);
    }
#endif
    else {
        conn_emit_error(aTHX_ self, "unsupported SASL mechanism");
        kf_buf_free(&body);
        return;
    }

    self->state = CONN_SASL_AUTH;
    conn_send_request(aTHX_ self, API_SASL_AUTHENTICATE, 2, &body, NULL, 1, 0);
    kf_buf_free(&body);
}

static void conn_parse_sasl_authenticate_response(pTHX_ ev_kafka_conn_t *self,
    const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;

    if (end - p < 2) goto err;
    int16_t error_code = kf_read_i16(p); p += 2;

    const char *errmsg_str = NULL;
    int16_t errmsg_len = 0;
    {
        int n = kf_read_string(p, end, &errmsg_str, &errmsg_len);
        if (n < 0) goto err;
        p += n;
    }

    /* auth_bytes */
    const char *auth_data = NULL;
    int32_t auth_data_len = 0;
    if (end - p >= 4) {
        auth_data_len = kf_read_i32(p); p += 4;
        if (auth_data_len > 0 && end - p >= auth_data_len) {
            auth_data = p;
            p += auth_data_len;
        }
    }

    if (error_code != 0) {
        char errbuf[512];
        if (errmsg_str && errmsg_len > 0)
            snprintf(errbuf, sizeof(errbuf), "SASL auth failed: %.*s", (int)errmsg_len, errmsg_str);
        else
            snprintf(errbuf, sizeof(errbuf), "SASL auth failed: error %d", error_code);
        conn_emit_error(aTHX_ self, errbuf);
        if (conn_check_destroyed(self)) return;
        conn_handle_disconnect(aTHX_ self, "SASL auth failed");
        return;
    }

#ifdef HAVE_OPENSSL
    /* SCRAM multi-step handling */
    if (self->sasl_mechanism && self->scram_step == SCRAM_STEP_CLIENT_FIRST && auth_data) {
        /* Server-first-message: r=<nonce>,s=<salt>,i=<iterations> */
        /* Parse server response, compute proof, send client-final */
        const char *server_nonce = NULL;
        size_t server_nonce_len = 0;
        const char *salt_b64 = NULL;
        size_t salt_b64_len = 0;
        int iterations = 0;
        {
            const char *sp = auth_data;
            const char *se = auth_data + auth_data_len;
            while (sp < se) {
                if (sp + 2 <= se && sp[0] == 'r' && sp[1] == '=') {
                    sp += 2; server_nonce = sp;
                    while (sp < se && *sp != ',') sp++;
                    server_nonce_len = sp - server_nonce;
                } else if (sp + 2 <= se && sp[0] == 's' && sp[1] == '=') {
                    sp += 2; salt_b64 = sp;
                    while (sp < se && *sp != ',') sp++;
                    salt_b64_len = sp - salt_b64;
                } else if (sp + 2 <= se && sp[0] == 'i' && sp[1] == '=') {
                    sp += 2;
                    iterations = atoi(sp);
                    while (sp < se && *sp != ',') sp++;
                }
                if (sp < se && *sp == ',') sp++;
                else sp++;
            }
        }

        if (!server_nonce || !salt_b64 || iterations <= 0) {
            conn_emit_error(aTHX_ self, "SCRAM: malformed server-first-message");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "SCRAM auth failed");
            return;
        }

        /* RFC 5802: server nonce must start with client nonce */
        if (server_nonce_len < 32 ||
            memcmp(server_nonce, self->scram_nonce, 32) != 0) {
            conn_emit_error(aTHX_ self, "SCRAM: server nonce mismatch");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "SCRAM auth failed");
            return;
        }

        int is_sha512 = (strcmp(self->sasl_mechanism, "SCRAM-SHA-512") == 0);
        const EVP_MD *md = is_sha512 ? EVP_sha512() : EVP_sha256();
        int digest_len = is_sha512 ? 64 : 32;

        /* Decode salt from base64 */
        unsigned char salt[128];
        int salt_len;
        {
            BIO *b64 = BIO_new(BIO_f_base64());
            BIO *bmem = BIO_new_mem_buf(salt_b64, (int)salt_b64_len);
            bmem = BIO_push(b64, bmem);
            BIO_set_flags(bmem, BIO_FLAGS_BASE64_NO_NL);
            salt_len = BIO_read(bmem, salt, sizeof(salt));
            BIO_free_all(bmem);
            if (salt_len <= 0) {
                conn_emit_error(aTHX_ self, "SCRAM: bad salt");
                if (conn_check_destroyed(self)) return;
                conn_handle_disconnect(aTHX_ self, "SCRAM auth failed");
                return;
            }
        }

        /* SaltedPassword = Hi(password, salt, iterations) using PBKDF2 */
        unsigned char salted_password[64];
        PKCS5_PBKDF2_HMAC(self->sasl_password, strlen(self->sasl_password),
            salt, salt_len, iterations, md, digest_len, salted_password);

        /* ClientKey = HMAC(SaltedPassword, "Client Key") */
        unsigned char client_key[64];
        unsigned int ck_len = digest_len;
        HMAC(md, salted_password, digest_len,
            (unsigned char *)"Client Key", 10, client_key, &ck_len);

        /* StoredKey = H(ClientKey) */
        unsigned char stored_key[64];
        {
            EVP_MD_CTX *ctx = EVP_MD_CTX_new();
            unsigned int sk_len;
            EVP_DigestInit_ex(ctx, md, NULL);
            EVP_DigestUpdate(ctx, client_key, digest_len);
            EVP_DigestFinal_ex(ctx, stored_key, &sk_len);
            EVP_MD_CTX_free(ctx);
        }

        /* AuthMessage = client-first-bare + "," + server-first + "," + client-final-without-proof */
        char channel_binding_b64[] = "biws"; /* base64("n,,") */
        kf_buf_t auth_msg;
        kf_buf_init(&auth_msg);
        kf_buf_append(&auth_msg, self->scram_client_first, self->scram_client_first_len);
        kf_buf_append(&auth_msg, ",", 1);
        kf_buf_append(&auth_msg, auth_data, auth_data_len);
        kf_buf_append(&auth_msg, ",c=", 3);
        kf_buf_append(&auth_msg, channel_binding_b64, 4);
        kf_buf_append(&auth_msg, ",r=", 3);
        kf_buf_append(&auth_msg, server_nonce, server_nonce_len);

        /* ClientSignature = HMAC(StoredKey, AuthMessage) */
        unsigned char client_sig[64];
        unsigned int cs_len = digest_len;
        HMAC(md, stored_key, digest_len,
            (unsigned char *)auth_msg.data, auth_msg.len, client_sig, &cs_len);

        /* ClientProof = ClientKey XOR ClientSignature */
        unsigned char proof[64];
        int di;
        for (di = 0; di < digest_len; di++)
            proof[di] = client_key[di] ^ client_sig[di];

        kf_buf_free(&auth_msg);

        /* Base64 encode proof */
        char proof_b64[256];
        {
            BIO *b64 = BIO_new(BIO_f_base64());
            BIO *bmem = BIO_new(BIO_s_mem());
            b64 = BIO_push(b64, bmem);
            BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
            BIO_write(b64, proof, digest_len);
            BIO_flush(b64);
            BUF_MEM *bptr;
            BIO_get_mem_ptr(b64, &bptr);
            int plen = bptr->length < 255 ? (int)bptr->length : 255;
            memcpy(proof_b64, bptr->data, plen);
            proof_b64[plen] = '\0';
            BIO_free_all(b64);
        }

        /* Build client-final-message: c=biws,r=<server_nonce>,p=<proof> */
        kf_buf_t final_msg;
        kf_buf_init(&final_msg);
        kf_buf_append(&final_msg, "c=", 2);
        kf_buf_append(&final_msg, channel_binding_b64, 4);
        kf_buf_append(&final_msg, ",r=", 3);
        kf_buf_append(&final_msg, server_nonce, server_nonce_len);
        kf_buf_append(&final_msg, ",p=", 3);
        kf_buf_append(&final_msg, proof_b64, strlen(proof_b64));

        /* Send client-final via SaslAuthenticate */
        kf_buf_t body;
        kf_buf_init(&body);
        kf_buf_append_i32(&body, (int32_t)final_msg.len);
        kf_buf_append(&body, final_msg.data, final_msg.len);

        self->scram_step = SCRAM_STEP_CLIENT_FINAL;
        conn_send_request(aTHX_ self, API_SASL_AUTHENTICATE, 2, &body, NULL, 1, 0);
        kf_buf_free(&body);
        kf_buf_free(&final_msg);
        return;
    }

    if (self->sasl_mechanism && self->scram_step == SCRAM_STEP_CLIENT_FINAL) {
        /* Server-final-message: v=<server_signature> — we just verify no error */
        self->scram_step = SCRAM_STEP_DONE;
        /* fall through to CONN_READY */
    }
#endif

    /* Auth success — connection is ready */
    self->state = CONN_READY;
    conn_emit_connect(aTHX_ self);
    return;

err:
    conn_emit_error(aTHX_ self, "malformed SaslAuthenticate response");
    if (conn_check_destroyed(self)) return;
    conn_handle_disconnect(aTHX_ self, "malformed SaslAuthenticate response");
}

/* ================================================================
 * Response dispatch
 * ================================================================ */

static void conn_dispatch_response(pTHX_ ev_kafka_conn_t *self,
    ev_kafka_conn_cb_t *cbt, const char *data, size_t len)
{
    /* Internal handshake responses */
    if (cbt->internal) {
        switch (cbt->api_key) {
            case API_API_VERSIONS:
                conn_parse_api_versions_response(aTHX_ self, data, len);
                break;
            case API_SASL_HANDSHAKE:
                conn_parse_sasl_handshake_response(aTHX_ self, data, len);
                break;
            case API_SASL_AUTHENTICATE:
                conn_parse_sasl_authenticate_response(aTHX_ self, data, len);
                break;
            default: break;
        }
        return;
    }

    /* User-facing responses: parse and invoke callback */
    if (!cbt->cb) return;

    switch (cbt->api_key) {
        case API_METADATA: {
            /* Parse metadata response and return as Perl hash */
            SV *result = conn_parse_metadata_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_PRODUCE: {
            SV *result = conn_parse_produce_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_FETCH: {
            SV *result = conn_parse_fetch_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_LIST_OFFSETS: {
            SV *result = conn_parse_list_offsets_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_FIND_COORDINATOR: {
            SV *result = conn_parse_find_coordinator_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_JOIN_GROUP: {
            SV *result = conn_parse_join_group_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_SYNC_GROUP: {
            SV *result = conn_parse_sync_group_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_HEARTBEAT: {
            SV *result = conn_parse_heartbeat_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_OFFSET_COMMIT: {
            SV *result = conn_parse_offset_commit_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_OFFSET_FETCH: {
            SV *result = conn_parse_offset_fetch_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_LEAVE_GROUP: {
            SV *result = conn_parse_leave_group_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_CREATE_TOPICS: {
            SV *result = conn_parse_create_topics_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_DELETE_TOPICS: {
            SV *result = conn_parse_delete_topics_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_INIT_PRODUCER_ID: {
            SV *result = conn_parse_init_producer_id_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_ADD_PARTITIONS_TXN: {
            SV *result = conn_parse_add_partitions_to_txn_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_END_TXN: {
            SV *result = conn_parse_end_txn_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        case API_TXN_OFFSET_COMMIT: {
            SV *result = conn_parse_txn_offset_commit_response(aTHX_ self, cbt->api_version, data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, result, NULL);
            break;
        }
        default: {
            /* Unknown API — return raw bytes */
            SV *result = newSVpvn(data, len);
            conn_invoke_cb(aTHX_ self, cbt->cb, sv_2mortal(result), NULL);
            break;
        }
    }
}

/* ================================================================
 * RecordBatch encoder (for Produce requests)
 * ================================================================ */

/* Build a single Record (within a RecordBatch).
 * Format: length(varint), attributes(i8=0), timestampDelta(varint),
 *         offsetDelta(varint), key(varint-bytes), value(varint-bytes),
 *         headers(varint array of {key:varint-str, value:varint-bytes})
 */
static void kf_encode_record(kf_buf_t *b, int offset_delta, int64_t ts_delta,
    const char *key, STRLEN key_len, const char *value, STRLEN value_len,
    HV *headers)
{
    kf_buf_t rec;
    kf_buf_init(&rec);

    kf_buf_append_i8(&rec, 0); /* attributes */
    kf_buf_append_varint(&rec, ts_delta);
    kf_buf_append_varint(&rec, offset_delta);

    /* key */
    if (key) {
        kf_buf_append_varint(&rec, (int64_t)key_len);
        kf_buf_append(&rec, key, key_len);
    } else {
        kf_buf_append_varint(&rec, -1);
    }

    /* value */
    if (value) {
        kf_buf_append_varint(&rec, (int64_t)value_len);
        kf_buf_append(&rec, value, value_len);
    } else {
        kf_buf_append_varint(&rec, -1);
    }

    /* headers */
    if (headers && HvUSEDKEYS(headers) > 0) {
        kf_buf_append_varint(&rec, (int64_t)HvUSEDKEYS(headers));
        HE *entry;
        hv_iterinit(headers);
        while ((entry = hv_iternext(headers))) {
            I32 hklen;
            const char *hkey = hv_iterkey(entry, &hklen);
            SV *hval = hv_iterval(headers, entry);
            STRLEN hvlen;
            const char *hvstr = SvPV(hval, hvlen);

            kf_buf_append_varint(&rec, (int64_t)hklen);
            kf_buf_append(&rec, hkey, hklen);
            kf_buf_append_varint(&rec, (int64_t)hvlen);
            kf_buf_append(&rec, hvstr, hvlen);
        }
    } else {
        kf_buf_append_varint(&rec, 0); /* 0 headers */
    }

    /* Write record: length(varint) + body */
    kf_buf_append_varint(b, (int64_t)rec.len);
    kf_buf_append(b, rec.data, rec.len);
    kf_buf_free(&rec);
}

/* Build a RecordBatch containing a single record.
 * Returns the complete RecordBatch bytes in *out.
 * Caller must kf_buf_free(out) when done.
 */
/* Multi-record batch encoder with producer ID support */
static void kf_encode_record_batch_multi(pTHX_ kf_buf_t *out,
    AV *records_av, int64_t timestamp, int compression,
    int64_t producer_id, int16_t producer_epoch, int32_t base_sequence,
    int is_transactional)
{
    kf_buf_t records;
    kf_buf_init(&records);
    SSize_t i, count = av_len(records_av) + 1;

    for (i = 0; i < count; i++) {
        SV **elem = av_fetch(records_av, i, 0);
        if (!elem || !SvROK(*elem))
            croak("produce_batch: record element must be a hashref");
        HV *rh = (HV*)SvRV(*elem);
        SV **key_sv = hv_fetch(rh, "key", 3, 0);
        SV **val_sv = hv_fetch(rh, "value", 5, 0);
        SV **hdr_sv = hv_fetch(rh, "headers", 7, 0);
        const char *key = NULL; STRLEN key_len = 0;
        const char *val = NULL; STRLEN val_len = 0;
        HV *hdrs = NULL;
        if (key_sv && SvOK(*key_sv)) key = SvPV(*key_sv, key_len);
        if (val_sv && SvOK(*val_sv)) val = SvPV(*val_sv, val_len);
        if (hdr_sv && SvROK(*hdr_sv) && SvTYPE(SvRV(*hdr_sv)) == SVt_PVHV)
            hdrs = (HV*)SvRV(*hdr_sv);
        kf_encode_record(&records, (int)i, 0, key, key_len, val, val_len, hdrs);
    }

    kf_buf_t inner;
    kf_buf_init(&inner);

    int16_t attrs = (int16_t)(compression & 0x07);
    if (is_transactional) attrs |= 0x10; /* bit 4 = isTransactional */
    kf_buf_append_i16(&inner, attrs);
    kf_buf_append_i32(&inner, (int32_t)(count - 1)); /* lastOffsetDelta */
    kf_buf_append_i64(&inner, timestamp);
    kf_buf_append_i64(&inner, timestamp);
    kf_buf_append_i64(&inner, producer_id);
    kf_buf_append_i16(&inner, producer_epoch);
    kf_buf_append_i32(&inner, base_sequence);

#ifdef HAVE_LZ4
    if (compression == COMPRESS_LZ4) {
        int max_compressed = LZ4_compressBound((int)records.len);
        char *compressed;
        Newx(compressed, max_compressed, char);
        int clen = LZ4_compress_default(records.data, compressed,
            (int)records.len, max_compressed);
        if (clen > 0) {
            kf_buf_append_i32(&inner, (int32_t)count);
            kf_buf_append(&inner, compressed, clen);
        } else {
            uint16_t zero = 0;
            memcpy(inner.data, &zero, 2);
            kf_buf_append_i32(&inner, (int32_t)count);
            kf_buf_append(&inner, records.data, records.len);
        }
        Safefree(compressed);
    } else
#endif
#ifdef HAVE_ZLIB
    if (compression == COMPRESS_GZIP) {
        size_t dest_cap = compressBound((uLong)records.len) + 32;
        char *compressed;
        Newx(compressed, dest_cap, char);
        z_stream zs;
        Zero(&zs, 1, z_stream);
        int zinit = deflateInit2(&zs, Z_DEFAULT_COMPRESSION, Z_DEFLATED,
                                  MAX_WBITS + 16, 8, Z_DEFAULT_STRATEGY);
        int zok = 0;
        if (zinit == Z_OK) {
            zs.next_in  = (Bytef *)records.data;
            zs.avail_in = (uInt)records.len;
            zs.next_out = (Bytef *)compressed;
            zs.avail_out = (uInt)dest_cap;
            if (deflate(&zs, Z_FINISH) == Z_STREAM_END) zok = 1;
            deflateEnd(&zs);
        }
        if (zok) {
            kf_buf_append_i32(&inner, (int32_t)count);
            kf_buf_append(&inner, compressed, zs.total_out);
        } else {
            uint16_t zero = 0;
            memcpy(inner.data, &zero, 2);
            kf_buf_append_i32(&inner, (int32_t)count);
            kf_buf_append(&inner, records.data, records.len);
        }
        Safefree(compressed);
    } else
#endif
    {
        (void)compression;
        kf_buf_append_i32(&inner, (int32_t)count);
        kf_buf_append(&inner, records.data, records.len);
    }

    uint32_t crc_val = crc32c(inner.data, inner.len);
    int32_t batch_length = 4 + 1 + 4 + (int32_t)inner.len;

    kf_buf_init(out);
    kf_buf_append_i64(out, 0);
    kf_buf_append_i32(out, batch_length);
    kf_buf_append_i32(out, 0);
    kf_buf_append_i8(out, 2);
    kf_buf_append_i32(out, (int32_t)crc_val);
    kf_buf_append(out, inner.data, inner.len);

    kf_buf_free(&inner);
    kf_buf_free(&records);
}

/* Single-record convenience wrapper */
static void kf_encode_record_batch(kf_buf_t *out,
    const char *key, STRLEN key_len,
    const char *value, STRLEN value_len,
    HV *headers, int64_t timestamp, int compression)
{
    kf_buf_t records;
    kf_buf_init(&records);
    kf_encode_record(&records, 0, 0, key, key_len, value, value_len, headers);

    kf_buf_t inner;
    kf_buf_init(&inner);

    int16_t attrs = (int16_t)(compression & 0x07);
    kf_buf_append_i16(&inner, attrs);
    kf_buf_append_i32(&inner, 0);           /* lastOffsetDelta */
    kf_buf_append_i64(&inner, timestamp);
    kf_buf_append_i64(&inner, timestamp);
    kf_buf_append_i64(&inner, -1);          /* producerId */
    kf_buf_append_i16(&inner, -1);          /* producerEpoch */
    kf_buf_append_i32(&inner, -1);          /* baseSequence */

#ifdef HAVE_LZ4
    if (compression == COMPRESS_LZ4) {
        int max_compressed = LZ4_compressBound((int)records.len);
        char *compressed;
        Newx(compressed, max_compressed, char);
        int clen = LZ4_compress_default(records.data, compressed,
            (int)records.len, max_compressed);
        if (clen > 0) {
            kf_buf_append_i32(&inner, 1);   /* records count */
            kf_buf_append(&inner, compressed, clen);
        } else {
            /* fallback to uncompressed */
            /* rewrite attrs to 0 */
            uint16_t zero = 0;
            memcpy(inner.data, &zero, 2);
            kf_buf_append_i32(&inner, 1);
            kf_buf_append(&inner, records.data, records.len);
        }
        Safefree(compressed);
    } else
#endif
#ifdef HAVE_ZLIB
    if (compression == COMPRESS_GZIP) {
        size_t dest_cap = compressBound((uLong)records.len) + 32;
        char *compressed;
        Newx(compressed, dest_cap, char);
        z_stream zs;
        Zero(&zs, 1, z_stream);
        int zinit = deflateInit2(&zs, Z_DEFAULT_COMPRESSION, Z_DEFLATED,
                                  MAX_WBITS + 16, 8, Z_DEFAULT_STRATEGY);
        int zok = 0;
        if (zinit == Z_OK) {
            zs.next_in  = (Bytef *)records.data;
            zs.avail_in = (uInt)records.len;
            zs.next_out = (Bytef *)compressed;
            zs.avail_out = (uInt)dest_cap;
            if (deflate(&zs, Z_FINISH) == Z_STREAM_END) zok = 1;
            deflateEnd(&zs);
        }
        if (zok) {
            kf_buf_append_i32(&inner, 1);
            kf_buf_append(&inner, compressed, zs.total_out);
        } else {
            uint16_t zero = 0;
            memcpy(inner.data, &zero, 2);
            kf_buf_append_i32(&inner, 1);
            kf_buf_append(&inner, records.data, records.len);
        }
        Safefree(compressed);
    } else
#endif
    {
        (void)compression;
        kf_buf_append_i32(&inner, 1);       /* records count */
        kf_buf_append(&inner, records.data, records.len);
    }

    uint32_t crc_val = crc32c(inner.data, inner.len);

    int32_t batch_length = 4 + 1 + 4 + (int32_t)inner.len;

    kf_buf_init(out);
    kf_buf_append_i64(out, 0);              /* baseOffset = 0 */
    kf_buf_append_i32(out, batch_length);
    kf_buf_append_i32(out, 0);              /* partitionLeaderEpoch */
    kf_buf_append_i8(out, 2);               /* magic = 2 */
    kf_buf_append_i32(out, (int32_t)crc_val); /* CRC32C */
    kf_buf_append(out, inner.data, inner.len);

    kf_buf_free(&inner);
    kf_buf_free(&records);
}

/* ================================================================
 * Response parsers
 * ================================================================ */

/* Metadata response parser (API 3) */
static SV* conn_parse_metadata_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *brokers_av = newAV();
    AV *topics_av = newAV();
    int n;

    (void)self;

    /* For v9+ (flexible versions), fields use compact encoding */
    int flexible = (version >= 9);

    if (flexible) {
        /* throttle_time_ms */
        if (end - p < 4) goto done;
        /* int32_t throttle = kf_read_i32(p); */ p += 4;

        /* brokers: compact array */
        uint64_t raw;
        n = kf_read_uvarint(p, end, &raw);
        if (n < 0) goto done;
        p += n;
        int32_t broker_count = (int32_t)(raw - 1);
        int32_t i;

        for (i = 0; i < broker_count; i++) {
            HV *bh = newHV();
            if (end - p < 4) goto done;
            int32_t nid = kf_read_i32(p); p += 4;
            hv_store(bh, "node_id", 7, newSViv(nid), 0);

            const char *host; int32_t hlen;
            n = kf_read_compact_string(p, end, &host, &hlen);
            if (n < 0) goto done;
            p += n;
            hv_store(bh, "host", 4, newSVpvn(host ? host : "", host ? hlen : 0), 0);

            if (end - p < 4) goto done;
            int32_t port = kf_read_i32(p); p += 4;
            hv_store(bh, "port", 4, newSViv(port), 0);

            /* rack: compact nullable string */
            const char *rack; int32_t rlen;
            n = kf_read_compact_string(p, end, &rack, &rlen);
            if (n < 0) goto done;
            p += n;

            /* tagged fields */
            n = kf_skip_tagged_fields(p, end);
            if (n < 0) goto done;
            p += n;

            av_push(brokers_av, newRV_noinc((SV*)bh));
        }

        /* cluster_id */
        const char *cid; int32_t cidlen;
        n = kf_read_compact_string(p, end, &cid, &cidlen);
        if (n < 0) goto done;
        p += n;

        /* controller_id */
        if (end - p < 4) goto done;
        int32_t controller_id = kf_read_i32(p); p += 4;
        hv_store(result, "controller_id", 13, newSViv(controller_id), 0);

        /* topics: compact array */
        n = kf_read_uvarint(p, end, &raw);
        if (n < 0) goto done;
        p += n;
        int32_t topic_count = (int32_t)(raw - 1);

        for (i = 0; i < topic_count; i++) {
            HV *th = newHV();
            if (end - p < 2) goto done;
            int16_t terr = kf_read_i16(p); p += 2;
            hv_store(th, "error_code", 10, newSViv(terr), 0);

            const char *tname; int32_t tnlen;
            n = kf_read_compact_string(p, end, &tname, &tnlen);
            if (n < 0) goto done;
            p += n;
            hv_store(th, "name", 4, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

            /* topic_id (UUID, 16 bytes) — v10+ */
            if (version >= 10) {
                if (end - p < 16) goto done;
                p += 16;
            }

            /* is_internal */
            if (end - p < 1) goto done;
            p += 1;

            /* partitions: compact array */
            n = kf_read_uvarint(p, end, &raw);
            if (n < 0) goto done;
            p += n;
            int32_t part_count = (int32_t)(raw - 1);
            AV *parts_av = newAV();
            int32_t j;

            for (j = 0; j < part_count; j++) {
                HV *ph = newHV();
                if (end - p < 2) goto done;
                int16_t perr = kf_read_i16(p); p += 2;
                hv_store(ph, "error_code", 10, newSViv(perr), 0);

                if (end - p < 4) goto done;
                int32_t pid = kf_read_i32(p); p += 4;
                hv_store(ph, "partition", 9, newSViv(pid), 0);

                if (end - p < 4) goto done;
                int32_t leader = kf_read_i32(p); p += 4;
                hv_store(ph, "leader", 6, newSViv(leader), 0);

                /* leader_epoch — v7+ */
                if (version >= 7) {
                    if (end - p < 4) goto done;
                    p += 4;
                }

                /* replicas: compact array of i32 */
                n = kf_read_uvarint(p, end, &raw);
                if (n < 0) goto done;
                p += n;
                int32_t rcount = (int32_t)(raw - 1);
                if (end - p < (ptrdiff_t)(rcount * 4)) goto done;
                p += rcount * 4;

                /* isr: compact array of i32 */
                n = kf_read_uvarint(p, end, &raw);
                if (n < 0) goto done;
                p += n;
                rcount = (int32_t)(raw - 1);
                if (end - p < (ptrdiff_t)(rcount * 4)) goto done;
                p += rcount * 4;

                /* offline_replicas: compact array of i32 — v5+ */
                if (version >= 5) {
                    n = kf_read_uvarint(p, end, &raw);
                    if (n < 0) goto done;
                    p += n;
                    rcount = (int32_t)(raw - 1);
                    if (end - p < (ptrdiff_t)(rcount * 4)) goto done;
                    p += rcount * 4;
                }

                /* tagged fields */
                n = kf_skip_tagged_fields(p, end);
                if (n < 0) goto done;
                p += n;

                av_push(parts_av, newRV_noinc((SV*)ph));
            }
            hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);

            /* topic authorized operations — v8+ */
            if (version >= 8) {
                if (end - p < 4) goto done;
                p += 4;
            }

            /* tagged fields */
            n = kf_skip_tagged_fields(p, end);
            if (n < 0) goto done;
            p += n;

            av_push(topics_av, newRV_noinc((SV*)th));
        }
    } else {
        /* Non-flexible (v0-v8) — use classic STRING/ARRAY encoding */
        /* throttle_time_ms (v3+) */
        if (version >= 3) {
            if (end - p < 4) goto done;
            p += 4;
        }

        /* brokers array */
        if (end - p < 4) goto done;
        int32_t broker_count = kf_read_i32(p); p += 4;
        int32_t i;
        for (i = 0; i < broker_count; i++) {
            HV *bh = newHV();
            if (end - p < 4) goto done;
            int32_t nid = kf_read_i32(p); p += 4;
            hv_store(bh, "node_id", 7, newSViv(nid), 0);

            const char *host; int16_t hlen;
            n = kf_read_string(p, end, &host, &hlen);
            if (n < 0) goto done;
            p += n;
            hv_store(bh, "host", 4, newSVpvn(host ? host : "", host ? hlen : 0), 0);

            if (end - p < 4) goto done;
            int32_t port = kf_read_i32(p); p += 4;
            hv_store(bh, "port", 4, newSViv(port), 0);

            /* rack (v1+) */
            if (version >= 1) {
                const char *r; int16_t rlen;
                n = kf_read_string(p, end, &r, &rlen);
                if (n < 0) goto done;
                p += n;
            }

            av_push(brokers_av, newRV_noinc((SV*)bh));
        }

        /* cluster_id (v2+) */
        if (version >= 2) {
            const char *cid; int16_t cidlen;
            n = kf_read_string(p, end, &cid, &cidlen);
            if (n < 0) goto done;
            p += n;
        }

        /* controller_id (v1+) */
        if (version >= 1) {
            if (end - p < 4) goto done;
            int32_t cid = kf_read_i32(p); p += 4;
            hv_store(result, "controller_id", 13, newSViv(cid), 0);
        }

        /* topics array */
        if (end - p < 4) goto done;
        int32_t topic_count = kf_read_i32(p); p += 4;
        for (i = 0; i < topic_count; i++) {
            HV *th = newHV();
            if (end - p < 2) goto done;
            int16_t terr = kf_read_i16(p); p += 2;
            hv_store(th, "error_code", 10, newSViv(terr), 0);

            const char *tname; int16_t tnlen;
            n = kf_read_string(p, end, &tname, &tnlen);
            if (n < 0) goto done;
            p += n;
            hv_store(th, "name", 4, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

            /* is_internal (v1+) */
            if (version >= 1) {
                if (end - p < 1) goto done;
                p += 1;
            }

            /* partitions */
            if (end - p < 4) goto done;
            int32_t part_count = kf_read_i32(p); p += 4;
            AV *parts_av = newAV();
            int32_t j;
            for (j = 0; j < part_count; j++) {
                HV *ph = newHV();
                if (end - p < 2) goto done;
                int16_t perr = kf_read_i16(p); p += 2;
                hv_store(ph, "error_code", 10, newSViv(perr), 0);

                if (end - p < 4) goto done;
                int32_t pid = kf_read_i32(p); p += 4;
                hv_store(ph, "partition", 9, newSViv(pid), 0);

                if (end - p < 4) goto done;
                int32_t leader = kf_read_i32(p); p += 4;
                hv_store(ph, "leader", 6, newSViv(leader), 0);

                /* leader_epoch (v7+) */
                if (version >= 7) {
                    if (end - p < 4) goto done;
                    p += 4;
                }

                /* replicas */
                if (end - p < 4) goto done;
                int32_t rcount = kf_read_i32(p); p += 4;
                if (end - p < (ptrdiff_t)(rcount * 4)) goto done;
                p += rcount * 4;

                /* isr */
                if (end - p < 4) goto done;
                rcount = kf_read_i32(p); p += 4;
                if (end - p < (ptrdiff_t)(rcount * 4)) goto done;
                p += rcount * 4;

                /* offline_replicas (v5+) */
                if (version >= 5) {
                    if (end - p < 4) goto done;
                    rcount = kf_read_i32(p); p += 4;
                    if (end - p < (ptrdiff_t)(rcount * 4)) goto done;
                    p += rcount * 4;
                }

                av_push(parts_av, newRV_noinc((SV*)ph));
            }
            hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);

            av_push(topics_av, newRV_noinc((SV*)th));
        }
    }

done:
    hv_store(result, "brokers", 7, newRV_noinc((SV*)brokers_av), 0);
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* Stub parsers — return raw bytes wrapped in hash with error_code */
/* Produce response parser (API 0, v0-v7) */
static SV* conn_parse_produce_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;

    (void)self;

    /* responses: ARRAY */
    if (end - p < 4) goto done;
    int32_t topic_count = kf_read_i32(p); p += 4;
    int32_t i;

    for (i = 0; i < topic_count; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "topic", 5, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        /* partitions: ARRAY */
        if (end - p < 4) goto done;
        int32_t part_count = kf_read_i32(p); p += 4;
        AV *parts_av = newAV();
        int32_t j;

        for (j = 0; j < part_count; j++) {
            HV *ph = newHV();
            if (end - p < 4) goto done;
            int32_t pid = kf_read_i32(p); p += 4;
            hv_store(ph, "partition", 9, newSViv(pid), 0);

            if (end - p < 2) goto done;
            int16_t err = kf_read_i16(p); p += 2;
            hv_store(ph, "error_code", 10, newSViv(err), 0);

            if (end - p < 8) goto done;
            int64_t base_offset = kf_read_i64(p); p += 8;
            hv_store(ph, "base_offset", 11, newSViv(base_offset), 0);

            /* log_append_time (v2+) */
            if (version >= 2) {
                if (end - p < 8) goto done;
                p += 8;
            }

            /* log_start_offset (v5+) */
            if (version >= 5) {
                if (end - p < 8) goto done;
                p += 8;
            }

            av_push(parts_av, newRV_noinc((SV*)ph));
        }
        hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);
        av_push(topics_av, newRV_noinc((SV*)th));
    }

    /* throttle_time_ms (v1+) */
    if (version >= 1 && end - p >= 4) {
        int32_t throttle = kf_read_i32(p); p += 4;
        hv_store(result, "throttle_time_ms", 16, newSViv(throttle), 0);
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* ================================================================
 * RecordBatch decoder (for Fetch responses)
 * ================================================================ */

/* Decode records from a RecordBatch, push them as hashrefs onto records_av.
 * Returns number of records decoded, or -1 on error. */
static int kf_decode_record_batch(pTHX_ const char *data, size_t len,
    AV *records_av, int64_t *out_base_offset)
{
    const char *p = data;
    const char *end = data + len;
    int n;

    if (end - p < 12) return -1;
    int64_t base_offset = kf_read_i64(p); p += 8;
    if (out_base_offset) *out_base_offset = base_offset;
    int32_t batch_length = kf_read_i32(p); p += 4;

    if (end - p < batch_length) return -1;
    const char *batch_end = p + batch_length;

    if (batch_end - p < 9) return -1;
    /* int32_t partition_leader_epoch = kf_read_i32(p); */ p += 4;
    int8_t magic = (int8_t)*p; p += 1;
    if (magic != 2) return -1; /* only support magic=2 (current format) */
    /* int32_t crc = kf_read_i32(p); */ p += 4; /* skip CRC check for speed */

    if (batch_end - p < 36) return -1;
    int16_t attributes = kf_read_i16(p); p += 2;
    int compression_type = attributes & 0x07;
    /* int32_t last_offset_delta = kf_read_i32(p); */ p += 4;
    int64_t first_timestamp = kf_read_i64(p); p += 8;
    /* int64_t max_timestamp = kf_read_i64(p); */ p += 8;
    /* int64_t producer_id = kf_read_i64(p); */ p += 8;
    /* int16_t producer_epoch = kf_read_i16(p); */ p += 2;
    /* int32_t base_sequence = kf_read_i32(p); */ p += 4;

    if (batch_end - p < 4) return -1;
    int32_t record_count = kf_read_i32(p); p += 4;

    /* Decompress if needed */
    const char *rec_data = p;
    const char *rec_end = batch_end;
    char *decompressed = NULL;

    if (compression_type != COMPRESS_NONE && batch_end > p) {
        size_t compressed_len = batch_end - p;
        size_t decomp_cap = compressed_len * 4;
        if (decomp_cap < 4096) decomp_cap = 4096;

#ifdef HAVE_ZLIB
        if (compression_type == COMPRESS_GZIP) {
            int zok = 0;
            while (!zok && decomp_cap < 64 * 1024 * 1024) {
                Newx(decompressed, decomp_cap, char);
                z_stream zs;
                Zero(&zs, 1, z_stream);
                int zinit = inflateInit2(&zs, MAX_WBITS + 16);
                if (zinit != Z_OK) {
                    Safefree(decompressed);
                    decompressed = NULL;
                    break;
                }
                zs.next_in  = (Bytef *)p;
                zs.avail_in = (uInt)compressed_len;
                zs.next_out = (Bytef *)decompressed;
                zs.avail_out = (uInt)decomp_cap;
                int zret = inflate(&zs, Z_FINISH);
                size_t dest_len = zs.total_out;
                inflateEnd(&zs);
                if (zret == Z_STREAM_END) {
                    rec_data = decompressed;
                    rec_end = decompressed + dest_len;
                    zok = 1;
                } else if (zret == Z_BUF_ERROR || zret == Z_OK) {
                    Safefree(decompressed);
                    decompressed = NULL;
                    decomp_cap *= 2;
                } else {
                    Safefree(decompressed);
                    decompressed = NULL;
                    break;
                }
            }
        }
#endif
#ifdef HAVE_LZ4
        if (compression_type == COMPRESS_LZ4) {
            Newx(decompressed, decomp_cap, char);
            int dlen = LZ4_decompress_safe(p, decompressed,
                (int)compressed_len, (int)decomp_cap);
            if (dlen > 0) {
                rec_data = decompressed;
                rec_end = decompressed + dlen;
            } else {
                Safefree(decompressed);
                decompressed = NULL;
            }
        }
#endif
    }

    const char *rp = rec_data;
    int32_t i;
    for (i = 0; i < record_count; i++) {
        int64_t rec_len;
        n = kf_read_varint(rp, rec_end, &rec_len);
        if (n < 0) { if (decompressed) Safefree(decompressed); return -1; }
        rp += n;
        if (rec_end - rp < rec_len) { if (decompressed) Safefree(decompressed); return -1; }
        const char *this_rec_end = rp + rec_len;

        if (this_rec_end - rp < 1) { if (decompressed) Safefree(decompressed); return -1; }
        /* int8_t rec_attrs = (int8_t)*rp; */ rp += 1;

        int64_t ts_delta;
        n = kf_read_varint(rp, this_rec_end, &ts_delta);
        if (n < 0) { if (decompressed) Safefree(decompressed); return -1; }
        rp += n;

        int64_t offset_delta;
        n = kf_read_varint(rp, this_rec_end, &offset_delta);
        if (n < 0) { if (decompressed) Safefree(decompressed); return -1; }
        rp += n;

        /* key */
        int64_t key_len;
        n = kf_read_varint(rp, this_rec_end, &key_len);
        if (n < 0) { if (decompressed) Safefree(decompressed); return -1; }
        rp += n;
        const char *key_data = NULL;
        if (key_len >= 0) {
            if (this_rec_end - rp < key_len) { if (decompressed) Safefree(decompressed); return -1; }
            key_data = rp;
            rp += key_len;
        }

        /* value */
        int64_t val_len;
        n = kf_read_varint(rp, this_rec_end, &val_len);
        if (n < 0) { if (decompressed) Safefree(decompressed); return -1; }
        rp += n;
        const char *val_data = NULL;
        if (val_len >= 0) {
            if (this_rec_end - rp < val_len) { if (decompressed) Safefree(decompressed); return -1; }
            val_data = rp;
            rp += val_len;
        }

        /* headers */
        int64_t hdr_count;
        n = kf_read_varint(rp, this_rec_end, &hdr_count);
        if (n < 0) { if (decompressed) Safefree(decompressed); return -1; }
        rp += n;
        HV *hdr_hv = NULL;
        if (hdr_count > 0) {
            hdr_hv = newHV();
            int64_t h;
            for (h = 0; h < hdr_count; h++) {
                int64_t hk_len;
                n = kf_read_varint(rp, this_rec_end, &hk_len);
                if (n < 0) { SvREFCNT_dec((SV*)hdr_hv); if (decompressed) Safefree(decompressed); return -1; }
                rp += n;
                const char *hk_data = rp;
                if (this_rec_end - rp < hk_len) { SvREFCNT_dec((SV*)hdr_hv); if (decompressed) Safefree(decompressed); return -1; }
                rp += hk_len;

                int64_t hv_len;
                n = kf_read_varint(rp, this_rec_end, &hv_len);
                if (n < 0) { SvREFCNT_dec((SV*)hdr_hv); if (decompressed) Safefree(decompressed); return -1; }
                rp += n;
                const char *hv_data = rp;
                if (hv_len >= 0) {
                    if (this_rec_end - rp < hv_len) { SvREFCNT_dec((SV*)hdr_hv); if (decompressed) Safefree(decompressed); return -1; }
                    rp += hv_len;
                }

                hv_store(hdr_hv, hk_data, (I32)hk_len,
                    hv_len >= 0 ? newSVpvn(hv_data, (STRLEN)hv_len) : newSV(0), 0);
            }
        }

        HV *rec_hv = newHV();
        hv_store(rec_hv, "offset", 6, newSViv(base_offset + offset_delta), 0);
        hv_store(rec_hv, "timestamp", 9, newSViv(first_timestamp + ts_delta), 0);
        hv_store(rec_hv, "key", 3,
            key_data ? newSVpvn(key_data, (STRLEN)key_len) : newSV(0), 0);
        hv_store(rec_hv, "value", 5,
            val_data ? newSVpvn(val_data, (STRLEN)val_len) : newSV(0), 0);
        if (hdr_hv)
            hv_store(rec_hv, "headers", 7, newRV_noinc((SV*)hdr_hv), 0);

        av_push(records_av, newRV_noinc((SV*)rec_hv));

        rp = this_rec_end; /* skip any remaining bytes in the record */
    }

    if (decompressed) Safefree(decompressed);
    return record_count;
}

/* Fetch response parser (API 1, v4-v7 non-flexible) */
static SV* conn_parse_fetch_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;

    (void)self;

    /* throttle_time_ms (v1+) */
    if (version >= 1) {
        if (end - p < 4) goto done;
        int32_t throttle = kf_read_i32(p); p += 4;
        hv_store(result, "throttle_time_ms", 16, newSViv(throttle), 0);
    }

    /* error_code (v7+) */
    if (version >= 7) {
        if (end - p < 2) goto done;
        p += 2;
    }

    /* session_id (v7+) */
    if (version >= 7) {
        if (end - p < 4) goto done;
        p += 4;
    }

    /* responses: ARRAY */
    if (end - p < 4) goto done;
    int32_t topic_count = kf_read_i32(p); p += 4;
    int32_t i;

    for (i = 0; i < topic_count; i++) {
        HV *th = newHV();

        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "topic", 5, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        /* partitions: ARRAY */
        if (end - p < 4) goto done;
        int32_t part_count = kf_read_i32(p); p += 4;
        AV *parts_av = newAV();
        int32_t j;

        for (j = 0; j < part_count; j++) {
            HV *ph = newHV();

            if (end - p < 4) goto done;
            int32_t pid = kf_read_i32(p); p += 4;
            hv_store(ph, "partition", 9, newSViv(pid), 0);

            if (end - p < 2) goto done;
            int16_t err = kf_read_i16(p); p += 2;
            hv_store(ph, "error_code", 10, newSViv(err), 0);

            if (end - p < 8) goto done;
            int64_t hw = kf_read_i64(p); p += 8;
            hv_store(ph, "high_watermark", 14, newSViv(hw), 0);

            /* last_stable_offset (v4+) */
            if (version >= 4) {
                if (end - p < 8) goto done;
                int64_t lso = kf_read_i64(p); p += 8;
                hv_store(ph, "last_stable_offset", 18, newSViv(lso), 0);
            }

            /* log_start_offset (v5+) */
            if (version >= 5) {
                if (end - p < 8) goto done;
                p += 8;
            }

            /* aborted_transactions (v4+) */
            if (version >= 4) {
                if (end - p < 4) goto done;
                int32_t at_count = kf_read_i32(p); p += 4;
                int32_t at;
                for (at = 0; at < at_count; at++) {
                    if (end - p < 16) goto done;
                    p += 16; /* producer_id(i64) + first_offset(i64) */
                }
            }

            /* record_set: BYTES (records data) */
            if (end - p < 4) goto done;
            int32_t records_size = kf_read_i32(p); p += 4;

            AV *records_av = newAV();
            if (records_size > 0 && end - p >= records_size) {
                const char *rp = p;
                const char *rend = p + records_size;

                /* May contain multiple RecordBatches */
                while (rp < rend && rend - rp >= 12) {
                    int64_t bo;
                    int32_t bl = kf_read_i32(rp + 8);
                    if (bl < 0 || rend - rp < 12 + bl) break;
                    kf_decode_record_batch(aTHX_ rp, 12 + (size_t)bl, records_av, &bo);
                    rp += 12 + bl;
                }

                p += records_size;
            } else if (records_size > 0) {
                p = end; /* truncated */
            }

            hv_store(ph, "records", 7, newRV_noinc((SV*)records_av), 0);
            av_push(parts_av, newRV_noinc((SV*)ph));
        }

        hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);
        av_push(topics_av, newRV_noinc((SV*)th));
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* ListOffsets response parser (API 2, v1+) */
static SV* conn_parse_list_offsets_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;

    (void)self;

    /* throttle_time_ms (v2+) */
    if (version >= 2) {
        if (end - p < 4) goto done;
        p += 4;
    }

    /* topics: ARRAY */
    if (end - p < 4) goto done;
    int32_t topic_count = kf_read_i32(p); p += 4;
    int32_t i;

    for (i = 0; i < topic_count; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "topic", 5, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        if (end - p < 4) goto done;
        int32_t part_count = kf_read_i32(p); p += 4;
        AV *parts_av = newAV();
        int32_t j;

        for (j = 0; j < part_count; j++) {
            HV *ph = newHV();
            if (end - p < 4) goto done;
            int32_t pid = kf_read_i32(p); p += 4;
            hv_store(ph, "partition", 9, newSViv(pid), 0);

            if (end - p < 2) goto done;
            int16_t err = kf_read_i16(p); p += 2;
            hv_store(ph, "error_code", 10, newSViv(err), 0);

            if (version >= 1) {
                if (end - p < 8) goto done;
                int64_t ts = kf_read_i64(p); p += 8;
                hv_store(ph, "timestamp", 9, newSViv(ts), 0);
            }

            if (end - p < 8) goto done;
            int64_t offset = kf_read_i64(p); p += 8;
            hv_store(ph, "offset", 6, newSViv(offset), 0);

            /* leader_epoch (v4+) */
            if (version >= 4) {
                if (end - p < 4) goto done;
                p += 4;
            }

            av_push(parts_av, newRV_noinc((SV*)ph));
        }
        hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);
        av_push(topics_av, newRV_noinc((SV*)th));
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* FindCoordinator response parser (API 10, v0-v3) */
static SV* conn_parse_find_coordinator_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    int n;
    (void)self;

    /* throttle_time_ms (v1+) */
    if (version >= 1) {
        if (end - p < 4) goto done;
        p += 4;
    }

    if (end - p < 2) goto done;
    int16_t err = kf_read_i16(p); p += 2;
    hv_store(result, "error_code", 10, newSViv(err), 0);

    /* error_message (v1+) */
    if (version >= 1) {
        const char *emsg; int16_t elen;
        n = kf_read_string(p, end, &emsg, &elen);
        if (n < 0) goto done;
        p += n;
        if (emsg && elen > 0)
            hv_store(result, "error_message", 13, newSVpvn(emsg, elen), 0);
    }

    if (end - p < 4) goto done;
    int32_t nid = kf_read_i32(p); p += 4;
    hv_store(result, "node_id", 7, newSViv(nid), 0);

    const char *host; int16_t hlen;
    n = kf_read_string(p, end, &host, &hlen);
    if (n < 0) goto done;
    p += n;
    hv_store(result, "host", 4, newSVpvn(host ? host : "", host ? hlen : 0), 0);

    if (end - p < 4) goto done;
    int32_t port = kf_read_i32(p); p += 4;
    hv_store(result, "port", 4, newSViv(port), 0);

done:
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* JoinGroup response parser (API 11, v0-v5) */
static SV* conn_parse_join_group_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    int n;
    (void)self;

    /* throttle_time_ms (v2+) */
    if (version >= 2) {
        if (end - p < 4) goto done;
        p += 4;
    }

    if (end - p < 2) goto done;
    int16_t err = kf_read_i16(p); p += 2;
    hv_store(result, "error_code", 10, newSViv(err), 0);

    if (end - p < 4) goto done;
    int32_t gen = kf_read_i32(p); p += 4;
    hv_store(result, "generation_id", 13, newSViv(gen), 0);

    /* protocol_type (v7+) — skip for now, we use v5 max */

    const char *proto; int16_t plen;
    n = kf_read_string(p, end, &proto, &plen);
    if (n < 0) goto done;
    p += n;
    if (proto)
        hv_store(result, "protocol_name", 13, newSVpvn(proto, plen), 0);

    const char *leader; int16_t llen;
    n = kf_read_string(p, end, &leader, &llen);
    if (n < 0) goto done;
    p += n;
    if (leader)
        hv_store(result, "leader", 6, newSVpvn(leader, llen), 0);

    /* skip_assignment (v9+) — not applicable */

    const char *member_id; int16_t mlen;
    n = kf_read_string(p, end, &member_id, &mlen);
    if (n < 0) goto done;
    p += n;
    if (member_id)
        hv_store(result, "member_id", 9, newSVpvn(member_id, mlen), 0);

    /* members array */
    if (end - p < 4) goto done;
    int32_t mcount = kf_read_i32(p); p += 4;
    AV *members_av = newAV();
    int32_t i;
    for (i = 0; i < mcount; i++) {
        HV *mh = newHV();

        const char *mid; int16_t midlen;
        n = kf_read_string(p, end, &mid, &midlen);
        if (n < 0) goto done;
        p += n;
        if (mid)
            hv_store(mh, "member_id", 9, newSVpvn(mid, midlen), 0);

        /* group_instance_id (v5+) */
        if (version >= 5) {
            const char *gi; int16_t gilen;
            n = kf_read_string(p, end, &gi, &gilen);
            if (n < 0) goto done;
            p += n;
        }

        /* metadata: BYTES */
        if (end - p < 4) goto done;
        int32_t mdlen = kf_read_i32(p); p += 4;
        if (mdlen > 0) {
            if (end - p < mdlen) goto done;
            hv_store(mh, "metadata", 8, newSVpvn(p, mdlen), 0);
            p += mdlen;
        }

        av_push(members_av, newRV_noinc((SV*)mh));
    }
    hv_store(result, "members", 7, newRV_noinc((SV*)members_av), 0);

done:
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* SyncGroup response parser (API 14, v0-v3) */
static SV* conn_parse_sync_group_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    (void)self;

    /* throttle_time_ms (v1+) */
    if (version >= 1) {
        if (end - p < 4) goto done;
        p += 4;
    }

    if (end - p < 2) goto done;
    int16_t err = kf_read_i16(p); p += 2;
    hv_store(result, "error_code", 10, newSViv(err), 0);

    /* assignment: BYTES */
    if (end - p < 4) goto done;
    int32_t alen = kf_read_i32(p); p += 4;
    if (alen > 0 && end - p >= alen) {
        hv_store(result, "assignment", 10, newSVpvn(p, alen), 0);
        p += alen;
    }

done:
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* Heartbeat response parser (API 12) */
static SV* conn_parse_heartbeat_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    (void)self;

    if (version >= 1 && end - p >= 4) p += 4; /* throttle_time_ms */
    if (end - p >= 2) {
        int16_t err = kf_read_i16(p); p += 2;
        hv_store(result, "error_code", 10, newSViv(err), 0);
    }

    return sv_2mortal(newRV_noinc((SV*)result));
}

/* OffsetCommit response parser (API 8, v0-v7) */
static SV* conn_parse_offset_commit_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;
    (void)self;

    if (version >= 3 && end - p >= 4) p += 4; /* throttle_time_ms */

    if (end - p < 4) goto done;
    int32_t tc = kf_read_i32(p); p += 4;
    int32_t i;
    for (i = 0; i < tc; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "topic", 5, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        if (end - p < 4) goto done;
        int32_t pc = kf_read_i32(p); p += 4;
        AV *parts_av = newAV();
        int32_t j;
        for (j = 0; j < pc; j++) {
            HV *ph = newHV();
            if (end - p < 6) goto done;
            int32_t pid = kf_read_i32(p); p += 4;
            int16_t err = kf_read_i16(p); p += 2;
            hv_store(ph, "partition", 9, newSViv(pid), 0);
            hv_store(ph, "error_code", 10, newSViv(err), 0);
            av_push(parts_av, newRV_noinc((SV*)ph));
        }
        hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);
        av_push(topics_av, newRV_noinc((SV*)th));
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* OffsetFetch response parser (API 9, v0-v5) */
static SV* conn_parse_offset_fetch_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;
    (void)self;

    if (version >= 3 && end - p >= 4) p += 4; /* throttle_time_ms */

    if (end - p < 4) goto done;
    int32_t tc = kf_read_i32(p); p += 4;
    int32_t i;
    for (i = 0; i < tc; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "topic", 5, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        if (end - p < 4) goto done;
        int32_t pc = kf_read_i32(p); p += 4;
        AV *parts_av = newAV();
        int32_t j;
        for (j = 0; j < pc; j++) {
            HV *ph = newHV();
            if (end - p < 4) goto done;
            int32_t pid = kf_read_i32(p); p += 4;
            hv_store(ph, "partition", 9, newSViv(pid), 0);

            if (end - p < 8) goto done;
            int64_t offset = kf_read_i64(p); p += 8;
            hv_store(ph, "offset", 6, newSViv(offset), 0);

            /* leader_epoch (v5+) */
            if (version >= 5 && end - p >= 4) p += 4;

            const char *meta_str; int16_t meta_len;
            n = kf_read_string(p, end, &meta_str, &meta_len);
            if (n < 0) goto done;
            p += n;

            if (end - p < 2) goto done;
            int16_t err = kf_read_i16(p); p += 2;
            hv_store(ph, "error_code", 10, newSViv(err), 0);

            av_push(parts_av, newRV_noinc((SV*)ph));
        }
        hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);
        av_push(topics_av, newRV_noinc((SV*)th));
    }

    /* error_code (v2+) */
    if (version >= 2 && end - p >= 2) {
        int16_t err = kf_read_i16(p); p += 2;
        hv_store(result, "error_code", 10, newSViv(err), 0);
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* LeaveGroup response parser (API 13, v0-v3) */
static SV* conn_parse_leave_group_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    (void)self;

    if (version >= 1 && end - p >= 4) p += 4; /* throttle_time_ms */
    if (end - p >= 2) {
        int16_t err = kf_read_i16(p); p += 2;
        hv_store(result, "error_code", 10, newSViv(err), 0);
    }

    return sv_2mortal(newRV_noinc((SV*)result));
}

/* CreateTopics response parser (API 19, v0-v4) */
static SV* conn_parse_create_topics_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;
    (void)self;

    if (version >= 2 && end - p >= 4) p += 4; /* throttle_time_ms */

    if (end - p < 4) goto done;
    int32_t tc = kf_read_i32(p); p += 4;
    int32_t i;
    for (i = 0; i < tc; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "name", 4, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        if (end - p < 2) goto done;
        int16_t err = kf_read_i16(p); p += 2;
        hv_store(th, "error_code", 10, newSViv(err), 0);

        /* error_message (v1+) */
        if (version >= 1) {
            const char *emsg; int16_t elen;
            n = kf_read_string(p, end, &emsg, &elen);
            if (n < 0) goto done;
            p += n;
            if (emsg && elen > 0)
                hv_store(th, "error_message", 13, newSVpvn(emsg, elen), 0);
        }

        av_push(topics_av, newRV_noinc((SV*)th));
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* DeleteTopics response parser (API 20, v0-v3) */
static SV* conn_parse_delete_topics_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;
    (void)self;

    if (version >= 1 && end - p >= 4) p += 4; /* throttle_time_ms */

    if (end - p < 4) goto done;
    int32_t tc = kf_read_i32(p); p += 4;
    int32_t i;
    for (i = 0; i < tc; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "name", 4, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        if (end - p < 2) goto done;
        int16_t err = kf_read_i16(p); p += 2;
        hv_store(th, "error_code", 10, newSViv(err), 0);

        av_push(topics_av, newRV_noinc((SV*)th));
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* InitProducerId response parser (API 22, v0-v2) */
static SV* conn_parse_init_producer_id_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    (void)self;

    if (version >= 1 && end - p >= 4) p += 4; /* throttle_time_ms */

    if (end - p < 2) goto done;
    int16_t err = kf_read_i16(p); p += 2;
    hv_store(result, "error_code", 10, newSViv(err), 0);

    if (end - p < 8) goto done;
    int64_t producer_id = kf_read_i64(p); p += 8;
    hv_store(result, "producer_id", 11, newSViv(producer_id), 0);

    if (end - p < 2) goto done;
    int16_t producer_epoch = kf_read_i16(p); p += 2;
    hv_store(result, "producer_epoch", 14, newSViv(producer_epoch), 0);

done:
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* AddPartitionsToTxn response parser (API 24, v0-v1) */
static SV* conn_parse_add_partitions_to_txn_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;
    (void)self; (void)version;

    if (end - p < 4) goto done;
    p += 4; /* throttle_time_ms */

    if (end - p < 4) goto done;
    int32_t tc = kf_read_i32(p); p += 4;
    int32_t i;
    for (i = 0; i < tc; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "topic", 5, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        if (end - p < 4) goto done;
        int32_t pc = kf_read_i32(p); p += 4;
        AV *parts_av = newAV();
        int32_t j;
        for (j = 0; j < pc; j++) {
            HV *ph = newHV();
            if (end - p < 6) goto done;
            int32_t pid = kf_read_i32(p); p += 4;
            int16_t err = kf_read_i16(p); p += 2;
            hv_store(ph, "partition", 9, newSViv(pid), 0);
            hv_store(ph, "error_code", 10, newSViv(err), 0);
            av_push(parts_av, newRV_noinc((SV*)ph));
        }
        hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);
        av_push(topics_av, newRV_noinc((SV*)th));
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* EndTxn response parser (API 26, v0-v1) */
static SV* conn_parse_end_txn_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    (void)self; (void)version;

    if (end - p >= 4) p += 4; /* throttle_time_ms */
    if (end - p >= 2) {
        int16_t err = kf_read_i16(p); p += 2;
        hv_store(result, "error_code", 10, newSViv(err), 0);
    }

    return sv_2mortal(newRV_noinc((SV*)result));
}

/* TxnOffsetCommit response parser (API 28, v0-v2) */
static SV* conn_parse_txn_offset_commit_response(pTHX_ ev_kafka_conn_t *self,
    int16_t version, const char *data, size_t len)
{
    const char *p = data;
    const char *end = data + len;
    HV *result = newHV();
    AV *topics_av = newAV();
    int n;
    (void)self;

    if (version >= 1 && end - p >= 4) p += 4; /* throttle_time_ms */

    if (end - p < 4) goto done;
    int32_t tc = kf_read_i32(p); p += 4;
    int32_t i;
    for (i = 0; i < tc; i++) {
        HV *th = newHV();
        const char *tname; int16_t tnlen;
        n = kf_read_string(p, end, &tname, &tnlen);
        if (n < 0) goto done;
        p += n;
        hv_store(th, "topic", 5, newSVpvn(tname ? tname : "", tname ? tnlen : 0), 0);

        if (end - p < 4) goto done;
        int32_t pc = kf_read_i32(p); p += 4;
        AV *parts_av = newAV();
        int32_t j;
        for (j = 0; j < pc; j++) {
            HV *ph = newHV();
            if (end - p < 6) goto done;
            int32_t pid = kf_read_i32(p); p += 4;
            int16_t err = kf_read_i16(p); p += 2;
            hv_store(ph, "partition", 9, newSViv(pid), 0);
            hv_store(ph, "error_code", 10, newSViv(err), 0);
            av_push(parts_av, newRV_noinc((SV*)ph));
        }
        hv_store(th, "partitions", 10, newRV_noinc((SV*)parts_av), 0);
        av_push(topics_av, newRV_noinc((SV*)th));
    }

done:
    hv_store(result, "topics", 6, newRV_noinc((SV*)topics_av), 0);
    return sv_2mortal(newRV_noinc((SV*)result));
}

/* ================================================================
 * Response processing loop
 * ================================================================ */

static void conn_process_responses(pTHX_ ev_kafka_conn_t *self) {
    while (self->rbuf_len >= 4) {
        int32_t msg_size = kf_read_i32(self->rbuf);
        if (msg_size < 0 || msg_size > 256 * 1024 * 1024) {
            conn_emit_error(aTHX_ self, "invalid response size");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "invalid response size");
            return;
        }

        if (self->rbuf_len < (size_t)(4 + msg_size))
            break; /* incomplete response */

        const char *msg = self->rbuf + 4;

        /* correlation_id is first 4 bytes of message */
        if (msg_size < 4) {
            conn_emit_error(aTHX_ self, "response too short");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "response too short");
            return;
        }

        int32_t corr_id = kf_read_i32(msg);
        const char *payload = msg + 4;
        size_t payload_len = (size_t)msg_size - 4;

        /* Find matching callback (should be head of queue — Kafka guarantees ordering) */
        ev_kafka_conn_cb_t *cbt = NULL;
        if (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            cbt = ngx_queue_data(q, ev_kafka_conn_cb_t, queue);
            if (cbt->correlation_id != corr_id) {
                /* Out of order — shouldn't happen with Kafka, but handle gracefully */
                char errbuf[128];
                snprintf(errbuf, sizeof(errbuf),
                    "correlation ID mismatch: expected %d, got %d",
                    cbt->correlation_id, corr_id);
                conn_emit_error(aTHX_ self, errbuf);
                if (conn_check_destroyed(self)) return;
                conn_handle_disconnect(aTHX_ self, "correlation ID mismatch");
                return;
            }
            ngx_queue_remove(q);
            self->pending_count--;
        }

        /* Dispatch BEFORE compacting — payload points into rbuf */
        size_t consumed = 4 + (size_t)msg_size;
        if (cbt) {
            conn_dispatch_response(aTHX_ self, cbt, payload, payload_len);
            if (cbt->cb) SvREFCNT_dec(cbt->cb);
            Safefree(cbt);
            if (conn_check_destroyed(self)) return;
        }

        /* Compact rbuf after dispatch */
        self->rbuf_len -= consumed;
        if (self->rbuf_len > 0)
            memmove(self->rbuf, self->rbuf + consumed, self->rbuf_len);
    }
}

/* ================================================================
 * I/O callback
 * ================================================================ */

static void conn_io_cb(EV_P_ ev_io *w, int revents) {
    ev_kafka_conn_t *self = (ev_kafka_conn_t *)w->data;
    dTHX;
    (void)loop;

    if (!self || self->magic != KF_MAGIC_ALIVE) return;

    /* TCP connect in progress */
    if (self->state == CONN_CONNECTING) {
        int err = 0;
        socklen_t errlen = sizeof(err);

        if (self->timing) {
            ev_timer_stop(self->loop, &self->timer);
            self->timing = 0;
        }
        conn_stop_writing(self);

        if (getsockopt(self->fd, SOL_SOCKET, SO_ERROR, &err, &errlen) < 0)
            err = errno;
        if (err != 0) {
            char errbuf[256];
            snprintf(errbuf, sizeof(errbuf), "connect: %s", strerror(err));
            conn_emit_error(aTHX_ self, errbuf);
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, errbuf);
            return;
        }

        conn_on_connect_done(aTHX_ self);
        return;
    }

#ifdef HAVE_OPENSSL
    /* TLS handshake in progress */
    if (self->state == CONN_TLS_HANDSHAKE) {
        int ret = SSL_connect(self->ssl);
        if (ret == 1) {
            conn_stop_reading(self);
            conn_stop_writing(self);

            /* TLS done — proceed to ApiVersions (or SASL if needed) */
            conn_send_api_versions(aTHX_ self);
            conn_start_reading(self);
            return;
        }
        int err = SSL_get_error(self->ssl, ret);
        if (err == SSL_ERROR_WANT_READ) {
            conn_stop_writing(self);
            conn_start_reading(self);
        } else if (err == SSL_ERROR_WANT_WRITE) {
            conn_stop_reading(self);
            conn_start_writing(self);
        } else {
            conn_emit_error(aTHX_ self, "SSL_connect failed");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "SSL_connect failed");
        }
        return;
    }
#endif

    /* Write */
    if (revents & EV_WRITE) {
        while (self->wbuf_off < self->wbuf_len) {
            ssize_t n = kf_io_write(self, self->wbuf + self->wbuf_off,
                                     self->wbuf_len - self->wbuf_off);
            if (n < 0) {
                if (errno == EAGAIN || errno == EWOULDBLOCK) break;
                conn_emit_error(aTHX_ self, strerror(errno));
                if (conn_check_destroyed(self)) return;
                conn_handle_disconnect(aTHX_ self, "write error");
                return;
            }
            if (n == 0) {
                conn_handle_disconnect(aTHX_ self, "connection closed");
                return;
            }
            self->wbuf_off += n;
        }

        if (self->wbuf_off >= self->wbuf_len) {
            self->wbuf_off = 0;
            self->wbuf_len = 0;
            conn_stop_writing(self);
        }
    }

    /* Read */
    if (revents & EV_READ) {
        conn_ensure_rbuf(self, self->rbuf_len + 8192);
        ssize_t n = kf_io_read(self, self->rbuf + self->rbuf_len,
                                self->rbuf_cap - self->rbuf_len);
        if (n < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) return;
            conn_emit_error(aTHX_ self, strerror(errno));
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "read error");
            return;
        }
        if (n == 0) {
            conn_handle_disconnect(aTHX_ self, "connection closed by broker");
            return;
        }
        self->rbuf_len += n;

        conn_process_responses(aTHX_ self);
    }
}

/* ================================================================
 * Connect timer (timeout)
 * ================================================================ */

static void conn_timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_kafka_conn_t *self = (ev_kafka_conn_t *)w->data;
    dTHX;
    (void)loop;
    (void)revents;

    self->timing = 0;
    if (self->magic != KF_MAGIC_ALIVE) return;

    conn_emit_error(aTHX_ self, "connect timeout");
    if (conn_check_destroyed(self)) return;
    conn_handle_disconnect(aTHX_ self, "connect timeout");
}

/* ================================================================
 * TCP connect + handshake initiation
 * ================================================================ */

#ifdef HAVE_OPENSSL
static int is_ip_literal(const char *host) {
    struct in_addr addr4;
    struct in6_addr addr6;
    return (inet_pton(AF_INET, host, &addr4) == 1 ||
            inet_pton(AF_INET6, host, &addr6) == 1);
}
#endif

static void conn_on_connect_done(pTHX_ ev_kafka_conn_t *self) {
    /* TCP connected — set up I/O watchers if not already */

#ifdef HAVE_OPENSSL
    if (self->tls_enabled) {
        self->ssl_ctx = SSL_CTX_new(TLS_client_method());
        if (!self->ssl_ctx) {
            conn_emit_error(aTHX_ self, "SSL_CTX_new failed");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "SSL_CTX_new failed");
            return;
        }
        SSL_CTX_set_default_verify_paths(self->ssl_ctx);
        if (self->tls_skip_verify)
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_NONE, NULL);
        else
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_PEER, NULL);

        if (self->tls_ca_file) {
            if (SSL_CTX_load_verify_locations(self->ssl_ctx, self->tls_ca_file, NULL) != 1) {
                conn_emit_error(aTHX_ self, "SSL_CTX_load_verify_locations failed");
                if (conn_check_destroyed(self)) return;
                conn_handle_disconnect(aTHX_ self, "SSL_CTX_load_verify_locations failed");
                return;
            }
        }

        self->ssl = SSL_new(self->ssl_ctx);
        if (!self->ssl) {
            conn_emit_error(aTHX_ self, "SSL_new failed");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "SSL_new failed");
            return;
        }
        SSL_set_fd(self->ssl, self->fd);

        if (!is_ip_literal(self->host))
            SSL_set_tlsext_host_name(self->ssl, self->host);

        if (!self->tls_skip_verify) {
            X509_VERIFY_PARAM *param = SSL_get0_param(self->ssl);
            X509_VERIFY_PARAM_set_hostflags(param, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
            if (is_ip_literal(self->host))
                X509_VERIFY_PARAM_set1_ip_asc(param, self->host);
            else
                X509_VERIFY_PARAM_set1_host(param, self->host, 0);
        }

        self->state = CONN_TLS_HANDSHAKE;
        int ret = SSL_connect(self->ssl);
        if (ret == 1) {
            /* Immediate success */
            conn_send_api_versions(aTHX_ self);
            conn_start_reading(self);
            return;
        }
        int err = SSL_get_error(self->ssl, ret);
        if (err == SSL_ERROR_WANT_READ) {
            conn_start_reading(self);
        } else if (err == SSL_ERROR_WANT_WRITE) {
            conn_start_writing(self);
        } else {
            conn_emit_error(aTHX_ self, "SSL_connect failed");
            if (conn_check_destroyed(self)) return;
            conn_handle_disconnect(aTHX_ self, "SSL_connect failed");
        }
        return;
    }
#endif

    /* No TLS — send ApiVersions directly */
    conn_send_api_versions(aTHX_ self);
    conn_start_reading(self);
}

static void conn_start_connect(pTHX_ ev_kafka_conn_t *self,
    const char *host, int port, double timeout)
{
    struct addrinfo hints, *res, *rp;
    char port_str[16];
    int fd = -1;

    if (self->state != CONN_DISCONNECTED) {
        conn_cleanup(aTHX_ self);
    }

    /* Save host/port (skip if already pointing to same string, e.g. reconnect) */
    if (host != self->host) {
        if (self->host) Safefree(self->host);
        self->host = savepv(host);
    }
    self->port = port;
    self->intentional_disconnect = 0;

    snprintf(port_str, sizeof(port_str), "%d", port);

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    int gai_err = getaddrinfo(host, port_str, &hints, &res);
    if (gai_err != 0) {
        char errbuf[256];
        snprintf(errbuf, sizeof(errbuf), "resolve: %s", gai_strerror(gai_err));
        conn_emit_error(aTHX_ self, errbuf);
        return;
    }

    for (rp = res; rp; rp = rp->ai_next) {
        fd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (fd < 0) continue;

        /* Non-blocking */
        fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK);

        /* TCP_NODELAY */
        {
            int one = 1;
            setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
        }

        int ret = connect(fd, rp->ai_addr, rp->ai_addrlen);
        if (ret == 0) {
            /* Immediate connect */
            self->fd = fd;
            self->state = CONN_CONNECTING; /* will be advanced in on_connect_done */
            freeaddrinfo(res);

            ev_io_init(&self->rio, conn_io_cb, fd, EV_READ);
            self->rio.data = (void *)self;
            ev_io_init(&self->wio, conn_io_cb, fd, EV_WRITE);
            self->wio.data = (void *)self;

            conn_on_connect_done(aTHX_ self);
            return;
        }

        if (errno == EINPROGRESS) {
            self->fd = fd;
            self->state = CONN_CONNECTING;
            freeaddrinfo(res);

            ev_io_init(&self->rio, conn_io_cb, fd, EV_READ);
            self->rio.data = (void *)self;
            ev_io_init(&self->wio, conn_io_cb, fd, EV_WRITE);
            self->wio.data = (void *)self;

            conn_start_writing(self); /* wait for connect to complete */

            if (timeout > 0) {
                ev_timer_init(&self->timer, conn_timer_cb, timeout, 0.0);
                self->timer.data = (void *)self;
                ev_timer_start(self->loop, &self->timer);
                self->timing = 1;
            }
            return;
        }

        close(fd);
    }

    freeaddrinfo(res);
    conn_emit_error(aTHX_ self, "connect: all addresses failed");
}

/* ================================================================
 * Cluster client struct (Layer 2) — skeleton
 * ================================================================ */

struct kf_partition_meta_s {
    int32_t partition_id;
    int32_t leader_id;
    int16_t error_code;
};

struct kf_topic_meta_s {
    char *name;
    int name_len;
    int16_t error_code;
    int num_partitions;
    kf_partition_meta_t *partitions;
    ngx_queue_t queue;
};

struct kf_consumer_group_s {
    char *group_id;
    char *member_id;
    int32_t generation_id;
    int state;
    int32_t coordinator_node_id;
    ev_kafka_conn_t *coordinator;
    ev_timer heartbeat_timer;
    int heartbeat_timing;
    double heartbeat_interval;
    double session_timeout;
    double rebalance_timeout;
    SV *on_assign;
    SV *on_revoke;
    AV *subscriptions;
};

struct ev_kafka_s {
    unsigned int magic;
    struct ev_loop *loop;

    ngx_queue_t brokers;
    int broker_count;

    char **bootstrap_hosts;
    int   *bootstrap_ports;
    int    bootstrap_count;

    ngx_queue_t topics;
    ev_timer metadata_timer;
    int metadata_timing;
    double metadata_refresh_interval;
    int metadata_pending;

    char *client_id;
    int   client_id_len;

    int tls_enabled;
    char *tls_ca_file;
    int tls_skip_verify;
    char *sasl_mechanism;
    char *sasl_username;
    char *sasl_password;

    /* Producer */
    ngx_queue_t produce_batches;
    ev_timer linger_timer;
    int linger_timing;
    double linger_ms;
    int batch_size;
    int16_t acks;
    int32_t max_request_size;
    SV *partitioner;
    int rr_counter;

    /* Consumer */
    ngx_queue_t consume_partitions;
    SV *on_message;
    int32_t fetch_max_bytes;
    int32_t fetch_min_bytes;
    int32_t fetch_max_wait_ms;
    ev_timer fetch_timer;
    int fetch_timing;

    /* Consumer group */
    kf_consumer_group_t *group;

    /* Event handlers */
    SV *on_error;
    SV *on_connect;

    int callback_depth;
};

/* ================================================================
 * XS INTERFACE
 * ================================================================ */

MODULE = EV::Kafka  PACKAGE = EV::Kafka::Conn

PROTOTYPES: DISABLE

EV::Kafka::Conn
_new(char *cls, SV *loop_sv)
    CODE:
    {
        struct ev_loop *loop;
        ev_kafka_conn_t *self;

        if (SvOK(loop_sv) && sv_derived_from(loop_sv, "EV::Loop"))
            loop = (struct ev_loop *)SvIV(SvRV(loop_sv));
        else
            loop = EV_DEFAULT;

        Newxz(self, 1, ev_kafka_conn_t);
        self->magic = KF_MAGIC_ALIVE;
        self->loop = loop;
        self->fd = -1;
        self->state = CONN_DISCONNECTED;
        self->node_id = -1;
        self->next_correlation_id = 1;

        Newx(self->rbuf, KF_BUF_INIT, char);
        self->rbuf_cap = KF_BUF_INIT;
        self->rbuf_len = 0;
        Newx(self->wbuf, KF_BUF_INIT, char);
        self->wbuf_cap = KF_BUF_INIT;
        self->wbuf_len = 0;
        self->wbuf_off = 0;

        ngx_queue_init(&self->cb_queue);

        /* Default client_id */
        self->client_id = savepv("ev-kafka");
        self->client_id_len = 8;

        /* Default: no API versions known */
        {
            int i;
            for (i = 0; i < API_VERSIONS_MAX_KEY; i++)
                self->api_versions[i] = -1;
        }

        self->reconnect_delay_ms = 1000;

        RETVAL = self;
    }
    OUTPUT:
        RETVAL

void
DESTROY(EV::Kafka::Conn self)
    CODE:
    {
        if (self->magic != KF_MAGIC_ALIVE) return;

        self->intentional_disconnect = 1;
        conn_cleanup(aTHX_ self);
        conn_cancel_pending(aTHX_ self, "destroyed");

        self->magic = KF_MAGIC_FREED;

        if (self->reconnect_timing) {
            ev_timer_stop(self->loop, &self->reconnect_timer);
            self->reconnect_timing = 0;
        }

        CLEAR_HANDLER(self->on_error);
        CLEAR_HANDLER(self->on_connect);
        CLEAR_HANDLER(self->on_disconnect);

        if (self->host) Safefree(self->host);
        if (self->client_id) Safefree(self->client_id);
        if (self->sasl_mechanism) Safefree(self->sasl_mechanism);
        if (self->sasl_username) Safefree(self->sasl_username);
        if (self->sasl_password) Safefree(self->sasl_password);
        if (self->scram_nonce) Safefree(self->scram_nonce);
        if (self->scram_client_first) Safefree(self->scram_client_first);
        if (self->tls_ca_file) Safefree(self->tls_ca_file);
        if (self->rbuf) Safefree(self->rbuf);
        if (self->wbuf) Safefree(self->wbuf);

        Safefree(self);
    }

void
connect(EV::Kafka::Conn self, const char *host, int port, double timeout = 0)
    CODE:
    {
        conn_start_connect(aTHX_ self, host, port, timeout);
    }

void
disconnect(EV::Kafka::Conn self)
    CODE:
    {
        self->intentional_disconnect = 1;
        if (self->reconnect_timing) {
            ev_timer_stop(self->loop, &self->reconnect_timer);
            self->reconnect_timing = 0;
        }
        conn_handle_disconnect(aTHX_ self, "disconnected");
    }

int
connected(EV::Kafka::Conn self)
    CODE:
        RETVAL = (self->state == CONN_READY) ? 1 : 0;
    OUTPUT:
        RETVAL

int
state(EV::Kafka::Conn self)
    CODE:
        RETVAL = self->state;
    OUTPUT:
        RETVAL

int
pending(EV::Kafka::Conn self)
    CODE:
        RETVAL = self->pending_count;
    OUTPUT:
        RETVAL

void
on_error(EV::Kafka::Conn self, SV *cb = NULL)
    CODE:
    {
        CLEAR_HANDLER(self->on_error);
        if (cb && SvOK(cb)) {
            self->on_error = newSVsv(cb);
        }
    }

void
on_connect(EV::Kafka::Conn self, SV *cb = NULL)
    CODE:
    {
        CLEAR_HANDLER(self->on_connect);
        if (cb && SvOK(cb)) {
            self->on_connect = newSVsv(cb);
        }
    }

void
on_disconnect(EV::Kafka::Conn self, SV *cb = NULL)
    CODE:
    {
        CLEAR_HANDLER(self->on_disconnect);
        if (cb && SvOK(cb)) {
            self->on_disconnect = newSVsv(cb);
        }
    }

void
client_id(EV::Kafka::Conn self, const char *id = NULL)
    CODE:
    {
        if (id) {
            if (self->client_id) Safefree(self->client_id);
            self->client_id = savepv(id);
            self->client_id_len = strlen(id);
        }
    }

void
tls(EV::Kafka::Conn self, int enable, const char *ca_file = NULL, int skip_verify = 0)
    CODE:
    {
        self->tls_enabled = enable;
        if (self->tls_ca_file) { Safefree(self->tls_ca_file); self->tls_ca_file = NULL; }
        if (ca_file) self->tls_ca_file = savepv(ca_file);
        self->tls_skip_verify = skip_verify;
    }

void
sasl(EV::Kafka::Conn self, const char *mechanism, const char *username = NULL, const char *password = NULL)
    CODE:
    {
        if (self->sasl_mechanism) { Safefree(self->sasl_mechanism); self->sasl_mechanism = NULL; }
        if (self->sasl_username) { Safefree(self->sasl_username); self->sasl_username = NULL; }
        if (self->sasl_password) { Safefree(self->sasl_password); self->sasl_password = NULL; }
        if (SvOK(ST(1))) {
            self->sasl_mechanism = savepv(mechanism);
            if (username) self->sasl_username = savepv(username);
            if (password) self->sasl_password = savepv(password);
        }
    }

void
auto_reconnect(EV::Kafka::Conn self, int enable, int delay_ms = 1000)
    CODE:
    {
        self->auto_reconnect = enable;
        self->reconnect_delay_ms = delay_ms;
    }

void
metadata(EV::Kafka::Conn self, SV *topics_sv, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        kf_buf_t body;
        kf_buf_init(&body);

        /* Metadata v1-v4 (non-flexible) */
        int16_t ver = self->api_versions[API_METADATA];
        if (ver < 0) ver = 1;
        if (ver > 4) ver = 4;

        if (SvOK(topics_sv) && SvROK(topics_sv) && SvTYPE(SvRV(topics_sv)) == SVt_PVAV) {
            AV *topics = (AV*)SvRV(topics_sv);
            SSize_t i, count = av_len(topics) + 1;
            kf_buf_append_i32(&body, (int32_t)count);
            for (i = 0; i < count; i++) {
                SV **elem = av_fetch(topics, i, 0);
                STRLEN tlen;
                const char *tname = SvPV(*elem, tlen);
                kf_buf_append_string(&body, tname, (int16_t)tlen);
            }
        } else {
            kf_buf_append_i32(&body, -1); /* null array = all topics */
        }

        /* allow_auto_topic_creation (v4+) */
        if (ver >= 4)
            kf_buf_append_i8(&body, 1);

        conn_send_request(aTHX_ self, API_METADATA, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
api_versions(EV::Kafka::Conn self)
    PPCODE:
    {
        if (!self->api_versions_known)
            XSRETURN_UNDEF;

        HV *hv = newHV();
        int i;
        for (i = 0; i < API_VERSIONS_MAX_KEY; i++) {
            if (self->api_versions[i] >= 0) {
                char key[8];
                int klen = snprintf(key, sizeof(key), "%d", i);
                hv_store(hv, key, klen, newSViv(self->api_versions[i]), 0);
            }
        }
        EXTEND(SP, 1);
        mPUSHs(newRV_noinc((SV*)hv));
        XSRETURN(1);
    }

void
fetch(EV::Kafka::Conn self, const char *topic, int partition, SV *offset_sv, SV *cb, int max_bytes = 1048576)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int64_t offset = SvIV(offset_sv);
        STRLEN topic_len = strlen(topic);

        int16_t ver = self->api_versions[API_FETCH];
        if (ver < 0) ver = 4;
        if (ver > 7) ver = 7;

        kf_buf_t body;
        kf_buf_init(&body);

        kf_buf_append_i32(&body, -1);          /* replica_id = -1 (consumer) */
        kf_buf_append_i32(&body, 500);          /* max_wait_ms */
        kf_buf_append_i32(&body, 1);            /* min_bytes */

        /* max_bytes (v3+) */
        if (ver >= 3)
            kf_buf_append_i32(&body, max_bytes);

        /* isolation_level (v4+) */
        if (ver >= 4)
            kf_buf_append_i8(&body, 0);         /* READ_UNCOMMITTED */

        /* session_id + session_epoch (v7+) */
        if (ver >= 7) {
            kf_buf_append_i32(&body, 0);        /* session_id */
            kf_buf_append_i32(&body, -1);       /* session_epoch */
        }

        /* topics: ARRAY(1) */
        kf_buf_append_i32(&body, 1);
        kf_buf_append_string(&body, topic, (int16_t)topic_len);

        /* partitions: ARRAY(1) */
        kf_buf_append_i32(&body, 1);
        kf_buf_append_i32(&body, (int32_t)partition);

        /* fetch_offset */
        kf_buf_append_i64(&body, offset);

        /* log_start_offset (v5+) */
        if (ver >= 5)
            kf_buf_append_i64(&body, -1);

        /* partition_max_bytes */
        kf_buf_append_i32(&body, max_bytes);

        /* forgotten_topics_data (v7+) */
        if (ver >= 7)
            kf_buf_append_i32(&body, 0);        /* empty array */

        conn_send_request(aTHX_ self, API_FETCH, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
fetch_multi(EV::Kafka::Conn self, SV *topics_sv, SV *cb, int max_bytes = 1048576)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        /* topics_sv: { topic => [{partition => N, offset => N}, ...], ... } */
        if (!SvROK(topics_sv) || SvTYPE(SvRV(topics_sv)) != SVt_PVHV)
            croak("fetch_multi: expected hashref");
        HV *topics_hv = (HV*)SvRV(topics_sv);

        int16_t ver = self->api_versions[API_FETCH];
        if (ver < 0) ver = 4;
        if (ver > 7) ver = 7;

        kf_buf_t body;
        kf_buf_init(&body);

        kf_buf_append_i32(&body, -1);          /* replica_id */
        kf_buf_append_i32(&body, 500);          /* max_wait_ms */
        kf_buf_append_i32(&body, 1);            /* min_bytes */
        if (ver >= 3)
            kf_buf_append_i32(&body, max_bytes);
        if (ver >= 4)
            kf_buf_append_i8(&body, 0);         /* isolation_level */
        if (ver >= 7) {
            kf_buf_append_i32(&body, 0);        /* session_id */
            kf_buf_append_i32(&body, -1);       /* session_epoch */
        }

        /* topics array */
        kf_buf_append_i32(&body, (int32_t)HvUSEDKEYS(topics_hv));

        hv_iterinit(topics_hv);
        HE *entry;
        while ((entry = hv_iternext(topics_hv))) {
            I32 tlen;
            const char *tname = hv_iterkey(entry, &tlen);
            kf_buf_append_string(&body, tname, (int16_t)tlen);

            SV *parts_sv = hv_iterval(topics_hv, entry);
            if (!SvROK(parts_sv) || SvTYPE(SvRV(parts_sv)) != SVt_PVAV)
                croak("fetch_multi: value must be an arrayref");
            AV *parts_av = (AV*)SvRV(parts_sv);
            SSize_t i, pc = av_len(parts_av) + 1;
            kf_buf_append_i32(&body, (int32_t)pc);

            for (i = 0; i < pc; i++) {
                SV **elem = av_fetch(parts_av, i, 0);
                if (!elem || !SvROK(*elem))
                    croak("fetch_multi: partition entry must be a hashref");
                HV *ph = (HV*)SvRV(*elem);

                SV **pid_sv = hv_fetch(ph, "partition", 9, 0);
                int32_t pid = pid_sv ? (int32_t)SvIV(*pid_sv) : 0;
                kf_buf_append_i32(&body, pid);

                SV **off_sv = hv_fetch(ph, "offset", 6, 0);
                int64_t offset = off_sv ? (int64_t)SvIV(*off_sv) : 0;
                kf_buf_append_i64(&body, offset);

                if (ver >= 5)
                    kf_buf_append_i64(&body, -1);   /* log_start_offset */

                kf_buf_append_i32(&body, max_bytes); /* partition_max_bytes */
            }
        }

        if (ver >= 7)
            kf_buf_append_i32(&body, 0);        /* forgotten_topics_data */

        conn_send_request(aTHX_ self, API_FETCH, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
produce_batch(EV::Kafka::Conn self, const char *topic, int partition, SV *records_sv, SV *opts_sv = NULL, SV *cb = NULL)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        if (!SvROK(records_sv) || SvTYPE(SvRV(records_sv)) != SVt_PVAV)
            croak("produce_batch: expected arrayref of records");
        AV *records_av = (AV*)SvRV(records_sv);

        int16_t acks = 1;
        int compression = COMPRESS_NONE;
        int64_t producer_id = -1;
        int16_t producer_epoch = -1;
        int32_t base_sequence = -1;
        const char *txn_id = NULL;
        STRLEN txn_id_len = 0;

        if (opts_sv && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV) {
            HV *opts = (HV*)SvRV(opts_sv);
            SV **tmp;
            if ((tmp = hv_fetch(opts, "acks", 4, 0)))
                acks = (int16_t)SvIV(*tmp);
            if ((tmp = hv_fetch(opts, "transactional_id", 16, 0)) && SvOK(*tmp))
                txn_id = SvPV(*tmp, txn_id_len);
            if ((tmp = hv_fetch(opts, "compression", 11, 0))) {
                STRLEN clen;
                const char *cstr = SvPV(*tmp, clen);
                if (clen == 4 && memcmp(cstr, "none", 4) == 0) compression = COMPRESS_NONE;
#ifdef HAVE_LZ4
                else if (clen == 3 && memcmp(cstr, "lz4", 3) == 0) compression = COMPRESS_LZ4;
#endif
#ifdef HAVE_ZLIB
                else if (clen == 4 && memcmp(cstr, "gzip", 4) == 0) compression = COMPRESS_GZIP;
#endif
                else croak("unsupported compression: %.*s", (int)clen, cstr);
            }
            if ((tmp = hv_fetch(opts, "producer_id", 11, 0)))
                producer_id = (int64_t)SvIV(*tmp);
            if ((tmp = hv_fetch(opts, "producer_epoch", 14, 0)))
                producer_epoch = (int16_t)SvIV(*tmp);
            if ((tmp = hv_fetch(opts, "base_sequence", 13, 0)))
                base_sequence = (int32_t)SvIV(*tmp);
        } else if (opts_sv && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVCV) {
            cb = opts_sv;
            opts_sv = NULL;
        }

        struct timeval tv;
        gettimeofday(&tv, NULL);
        int64_t timestamp = (int64_t)tv.tv_sec * 1000 + tv.tv_usec / 1000;

        kf_buf_t batch;
        kf_encode_record_batch_multi(aTHX_ &batch, records_av, timestamp,
            compression, producer_id, producer_epoch, base_sequence,
            txn_id != NULL ? 1 : 0);

        int16_t ver = self->api_versions[API_PRODUCE];
        if (ver < 0) ver = 3;
        if (ver > 7) ver = 7;

        STRLEN topic_len = strlen(topic);

        kf_buf_t body;
        kf_buf_init(&body);

        if (ver >= 3)
            kf_buf_append_nullable_string(&body, txn_id, txn_id ? (int16_t)txn_id_len : 0);

        kf_buf_append_i16(&body, acks);
        kf_buf_append_i32(&body, 30000);

        kf_buf_append_i32(&body, 1);
        kf_buf_append_string(&body, topic, (int16_t)topic_len);
        kf_buf_append_i32(&body, 1);
        kf_buf_append_i32(&body, (int32_t)partition);
        kf_buf_append_i32(&body, (int32_t)batch.len);
        kf_buf_append(&body, batch.data, batch.len);

        conn_send_request(aTHX_ self, API_PRODUCE, ver, &body,
            (cb && SvOK(cb)) ? cb : NULL, 0, (acks == 0) ? 1 : 0);

        kf_buf_free(&body);
        kf_buf_free(&batch);
    }

void
list_offsets(EV::Kafka::Conn self, const char *topic, int partition, SV *timestamp_sv, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int64_t timestamp = SvIV(timestamp_sv);
        STRLEN topic_len = strlen(topic);

        /* -2 = earliest, -1 = latest */
        int16_t ver = self->api_versions[API_LIST_OFFSETS];
        if (ver < 0) ver = 1;
        if (ver > 5) ver = 5;

        kf_buf_t body;
        kf_buf_init(&body);

        kf_buf_append_i32(&body, -1);          /* replica_id */

        /* isolation_level (v2+) */
        if (ver >= 2)
            kf_buf_append_i8(&body, 0);

        /* topics: ARRAY(1) */
        kf_buf_append_i32(&body, 1);
        kf_buf_append_string(&body, topic, (int16_t)topic_len);

        /* partitions: ARRAY(1) */
        kf_buf_append_i32(&body, 1);
        kf_buf_append_i32(&body, (int32_t)partition);

        /* current_leader_epoch (v4+) */
        if (ver >= 4)
            kf_buf_append_i32(&body, -1);

        kf_buf_append_i64(&body, timestamp);

        conn_send_request(aTHX_ self, API_LIST_OFFSETS, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
produce(EV::Kafka::Conn self, const char *topic, int partition, SV *key_sv, SV *value_sv, SV *opts_sv = NULL, SV *cb = NULL)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        /* Handle optional opts hash: produce($topic, $part, $key, $val, \%opts, $cb)
         * or produce($topic, $part, $key, $val, $cb)
         */
        HV *headers = NULL;
        int16_t acks = 1;
        int compression = COMPRESS_NONE;

        if (opts_sv && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV) {
            HV *opts = (HV*)SvRV(opts_sv);
            SV **tmp;
            if ((tmp = hv_fetch(opts, "headers", 7, 0)) && SvROK(*tmp) && SvTYPE(SvRV(*tmp)) == SVt_PVHV)
                headers = (HV*)SvRV(*tmp);
            if ((tmp = hv_fetch(opts, "acks", 4, 0)))
                acks = (int16_t)SvIV(*tmp);
            if ((tmp = hv_fetch(opts, "compression", 11, 0))) {
                STRLEN clen;
                const char *cstr = SvPV(*tmp, clen);
                if (clen == 4 && memcmp(cstr, "none", 4) == 0) compression = COMPRESS_NONE;
#ifdef HAVE_LZ4
                else if (clen == 3 && memcmp(cstr, "lz4", 3) == 0) compression = COMPRESS_LZ4;
#endif
#ifdef HAVE_ZLIB
                else if (clen == 4 && memcmp(cstr, "gzip", 4) == 0) compression = COMPRESS_GZIP;
#endif
                else croak("unsupported compression: %.*s", (int)clen, cstr);
            }
        } else if (opts_sv && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVCV) {
            /* opts_sv is actually the callback */
            cb = opts_sv;
            opts_sv = NULL;
        }

        const char *key = NULL;
        STRLEN key_len = 0;
        if (SvOK(key_sv))
            key = SvPV(key_sv, key_len);

        const char *value = NULL;
        STRLEN value_len = 0;
        if (SvOK(value_sv))
            value = SvPV(value_sv, value_len);

        /* Build RecordBatch */
        int64_t timestamp;
        {
            SV **ts_tmp = NULL;
            if (opts_sv && SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV)
                ts_tmp = hv_fetch((HV*)SvRV(opts_sv), "timestamp", 9, 0);
            if (ts_tmp && SvOK(*ts_tmp)) {
                timestamp = (int64_t)SvIV(*ts_tmp);
            } else {
                struct timeval tv;
                gettimeofday(&tv, NULL);
                timestamp = (int64_t)tv.tv_sec * 1000 + tv.tv_usec / 1000;
            }
        }

        kf_buf_t batch;
        kf_encode_record_batch(&batch, key, key_len, value, value_len, headers, timestamp, compression);

        /* Use Produce version — cap at v7 */
        int16_t ver = self->api_versions[API_PRODUCE];
        if (ver < 0) ver = 3;
        if (ver > 7) ver = 7;

        STRLEN topic_len = strlen(topic);

        kf_buf_t body;
        kf_buf_init(&body);

        /* transactional_id (v3+): nullable string = null */
        if (ver >= 3)
            kf_buf_append_nullable_string(&body, NULL, 0);

        kf_buf_append_i16(&body, acks);     /* acks */
        kf_buf_append_i32(&body, 30000);    /* timeout_ms = 30s */

        /* topic_data: ARRAY(1) */
        kf_buf_append_i32(&body, 1);        /* 1 topic */
        kf_buf_append_string(&body, topic, (int16_t)topic_len);

        /* partition_data: ARRAY(1) */
        kf_buf_append_i32(&body, 1);        /* 1 partition */
        kf_buf_append_i32(&body, partition);

        /* record_set: BYTES (i32 length + record_batch) */
        kf_buf_append_i32(&body, (int32_t)batch.len);
        kf_buf_append(&body, batch.data, batch.len);

        conn_send_request(aTHX_ self, API_PRODUCE, ver, &body,
            (cb && SvOK(cb)) ? cb : NULL, 0, (acks == 0) ? 1 : 0);

        kf_buf_free(&body);
        kf_buf_free(&batch);
    }

void
find_coordinator(EV::Kafka::Conn self, const char *group_id, SV *cb, int key_type = 0)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_FIND_COORDINATOR];
        if (ver < 0) ver = 0;
        if (ver > 2) ver = 2;

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN glen = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)glen);

        /* key_type (v1+): 0=group, 1=transaction */
        if (ver >= 1)
            kf_buf_append_i8(&body, (int8_t)key_type);

        conn_send_request(aTHX_ self, API_FIND_COORDINATOR, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
join_group(EV::Kafka::Conn self, const char *group_id, const char *member_id, SV *topics_sv, SV *cb, int session_timeout_ms = 30000, int rebalance_timeout_ms = 60000, SV *group_instance_id_sv = NULL)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_JOIN_GROUP];
        if (ver < 0) ver = 1;
        if (ver > 5) ver = 5;

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN glen = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)glen);
        kf_buf_append_i32(&body, session_timeout_ms);

        /* rebalance_timeout_ms (v1+) */
        if (ver >= 1)
            kf_buf_append_i32(&body, rebalance_timeout_ms);

        STRLEN mlen = strlen(member_id);
        kf_buf_append_string(&body, member_id, (int16_t)mlen);

        /* group_instance_id (v5+) */
        if (ver >= 5) {
            if (group_instance_id_sv && SvOK(group_instance_id_sv)) {
                STRLEN gilen;
                const char *gi = SvPV(group_instance_id_sv, gilen);
                kf_buf_append_nullable_string(&body, gi, (int16_t)gilen);
            } else {
                kf_buf_append_nullable_string(&body, NULL, 0);
            }
        }

        /* protocol_type = "consumer" */
        kf_buf_append_string(&body, "consumer", 8);

        /* protocols: ARRAY(1) */
        kf_buf_append_i32(&body, 1);

        /* protocol name = "sticky" */
        kf_buf_append_string(&body, "sticky", 6);

        /* protocol metadata (ConsumerProtocol subscription) */
        /* Version:0, Topics:array, UserData:null */
        kf_buf_t meta;
        kf_buf_init(&meta);
        kf_buf_append_i16(&meta, 0); /* version */

        AV *topics = (AV*)SvRV(topics_sv);
        SSize_t i, tc = av_len(topics) + 1;
        kf_buf_append_i32(&meta, (int32_t)tc);
        for (i = 0; i < tc; i++) {
            SV **elem = av_fetch(topics, i, 0);
            STRLEN tlen;
            const char *tname = SvPV(*elem, tlen);
            kf_buf_append_string(&meta, tname, (int16_t)tlen);
        }
        kf_buf_append_nullable_bytes(&meta, NULL, 0); /* user_data = null */

        kf_buf_append_bytes(&body, meta.data, (int32_t)meta.len);
        kf_buf_free(&meta);

        conn_send_request(aTHX_ self, API_JOIN_GROUP, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
sync_group(EV::Kafka::Conn self, const char *group_id, int generation_id, const char *member_id, SV *assignments_sv, SV *cb, SV *group_instance_id_sv = NULL)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_SYNC_GROUP];
        if (ver < 0) ver = 0;
        if (ver > 3) ver = 3;

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN glen = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)glen);
        kf_buf_append_i32(&body, generation_id);

        STRLEN mlen = strlen(member_id);
        kf_buf_append_string(&body, member_id, (int16_t)mlen);

        /* group_instance_id (v3+) */
        if (ver >= 3) {
            if (group_instance_id_sv && SvOK(group_instance_id_sv)) {
                STRLEN gilen;
                const char *gi = SvPV(group_instance_id_sv, gilen);
                kf_buf_append_nullable_string(&body, gi, (int16_t)gilen);
            } else {
                kf_buf_append_nullable_string(&body, NULL, 0);
            }
        }

        /* assignments: ARRAY of {member_id, assignment_bytes} */
        if (SvOK(assignments_sv) && SvROK(assignments_sv)
            && SvTYPE(SvRV(assignments_sv)) == SVt_PVAV) {
            AV *assigns = (AV*)SvRV(assignments_sv);
            SSize_t i, ac = av_len(assigns) + 1;
            kf_buf_append_i32(&body, (int32_t)ac);

            for (i = 0; i < ac; i++) {
                SV **elem = av_fetch(assigns, i, 0);
                if (!elem || !SvROK(*elem)) continue;
                HV *ah = (HV*)SvRV(*elem);

                SV **mid_sv = hv_fetch(ah, "member_id", 9, 0);
                if (!mid_sv) continue;
                STRLEN mid_len;
                const char *mid = SvPV(*mid_sv, mid_len);
                kf_buf_append_string(&body, mid, (int16_t)mid_len);

                SV **data_sv = hv_fetch(ah, "assignment", 10, 0);
                if (!data_sv) { kf_buf_append_bytes(&body, NULL, 0); continue; }
                STRLEN dlen;
                const char *ddata = SvPV(*data_sv, dlen);
                kf_buf_append_bytes(&body, ddata, (int32_t)dlen);
            }
        } else {
            kf_buf_append_i32(&body, 0); /* empty array */
        }

        conn_send_request(aTHX_ self, API_SYNC_GROUP, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
heartbeat(EV::Kafka::Conn self, const char *group_id, int generation_id, const char *member_id, SV *cb, SV *group_instance_id_sv = NULL)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_HEARTBEAT];
        if (ver < 0) ver = 0;
        if (ver > 4) ver = 4;

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN glen = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)glen);
        kf_buf_append_i32(&body, generation_id);

        STRLEN mlen = strlen(member_id);
        kf_buf_append_string(&body, member_id, (int16_t)mlen);

        /* group_instance_id (v3+) */
        if (ver >= 3) {
            if (group_instance_id_sv && SvOK(group_instance_id_sv)) {
                STRLEN gilen;
                const char *gi = SvPV(group_instance_id_sv, gilen);
                kf_buf_append_nullable_string(&body, gi, (int16_t)gilen);
            } else {
                kf_buf_append_nullable_string(&body, NULL, 0);
            }
        }

        conn_send_request(aTHX_ self, API_HEARTBEAT, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
offset_commit(EV::Kafka::Conn self, const char *group_id, int generation_id, const char *member_id, SV *offsets_sv, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_OFFSET_COMMIT];
        if (ver < 0) ver = 2;
        if (ver > 7) ver = 7;

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN glen = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)glen);

        /* generation_id (v1+) */
        if (ver >= 1)
            kf_buf_append_i32(&body, generation_id);

        /* member_id (v1+) */
        if (ver >= 1) {
            STRLEN mlen = strlen(member_id);
            kf_buf_append_string(&body, member_id, (int16_t)mlen);
        }

        /* group_instance_id (v7+): null */
        if (ver >= 7)
            kf_buf_append_nullable_string(&body, NULL, 0);

        /* topics: ARRAY of {topic, partitions: [{partition, committed_offset, metadata}]} */
        AV *topics = (AV*)SvRV(offsets_sv);
        SSize_t i, tc = av_len(topics) + 1;
        kf_buf_append_i32(&body, (int32_t)tc);

        for (i = 0; i < tc; i++) {
            SV **elem = av_fetch(topics, i, 0);
            if (!elem || !SvROK(*elem)) continue;
            HV *th = (HV*)SvRV(*elem);
            SV **tname_sv = hv_fetch(th, "topic", 5, 0);
            if (!tname_sv) continue;
            STRLEN tnlen;
            const char *tname = SvPV(*tname_sv, tnlen);
            kf_buf_append_string(&body, tname, (int16_t)tnlen);

            SV **parts_sv = hv_fetch(th, "partitions", 10, 0);
            if (!parts_sv || !SvROK(*parts_sv)) { kf_buf_append_i32(&body, 0); continue; }
            AV *parts = (AV*)SvRV(*parts_sv);
            SSize_t j, pc = av_len(parts) + 1;
            kf_buf_append_i32(&body, (int32_t)pc);

            for (j = 0; j < pc; j++) {
                SV **pelem = av_fetch(parts, j, 0);
                if (!pelem || !SvROK(*pelem)) continue;
                HV *ph = (HV*)SvRV(*pelem);

                SV **pid_sv = hv_fetch(ph, "partition", 9, 0);
                kf_buf_append_i32(&body, pid_sv ? (int32_t)SvIV(*pid_sv) : 0);

                SV **off_sv = hv_fetch(ph, "offset", 6, 0);
                kf_buf_append_i64(&body, off_sv ? (int64_t)SvIV(*off_sv) : 0);

                /* leader_epoch (v6+) */
                if (ver >= 6)
                    kf_buf_append_i32(&body, -1);

                /* metadata: nullable string = empty */
                kf_buf_append_nullable_string(&body, "", 0);
            }
        }

        conn_send_request(aTHX_ self, API_OFFSET_COMMIT, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
offset_fetch(EV::Kafka::Conn self, const char *group_id, SV *topics_sv, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_OFFSET_FETCH];
        if (ver < 0) ver = 1;
        if (ver > 5) ver = 5;

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN glen = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)glen);

        /* topics: ARRAY */
        AV *topics = (AV*)SvRV(topics_sv);
        SSize_t i, tc = av_len(topics) + 1;
        kf_buf_append_i32(&body, (int32_t)tc);

        for (i = 0; i < tc; i++) {
            SV **elem = av_fetch(topics, i, 0);
            if (!elem || !SvROK(*elem)) continue;
            HV *th = (HV*)SvRV(*elem);
            SV **tname_sv = hv_fetch(th, "topic", 5, 0);
            if (!tname_sv) continue;
            STRLEN tnlen;
            const char *tname = SvPV(*tname_sv, tnlen);
            kf_buf_append_string(&body, tname, (int16_t)tnlen);

            SV **parts_sv = hv_fetch(th, "partitions", 10, 0);
            if (!parts_sv || !SvROK(*parts_sv)) { kf_buf_append_i32(&body, 0); continue; }
            AV *parts = (AV*)SvRV(*parts_sv);
            SSize_t j, pc = av_len(parts) + 1;
            kf_buf_append_i32(&body, (int32_t)pc);

            for (j = 0; j < pc; j++) {
                SV **pelem = av_fetch(parts, j, 0);
                kf_buf_append_i32(&body, pelem ? (int32_t)SvIV(*pelem) : 0);
            }
        }

        conn_send_request(aTHX_ self, API_OFFSET_FETCH, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
leave_group(EV::Kafka::Conn self, const char *group_id, const char *member_id, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_LEAVE_GROUP];
        if (ver < 0) ver = 0;
        if (ver > 3) ver = 3;

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN glen = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)glen);

        STRLEN mlen = strlen(member_id);
        kf_buf_append_string(&body, member_id, (int16_t)mlen);

        conn_send_request(aTHX_ self, API_LEAVE_GROUP, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
create_topics(EV::Kafka::Conn self, SV *topics_sv, int timeout_ms, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_CREATE_TOPICS];
        if (ver < 0) ver = 0;
        if (ver > 4) ver = 4;

        kf_buf_t body;
        kf_buf_init(&body);

        AV *topics = (AV*)SvRV(topics_sv);
        SSize_t i, tc = av_len(topics) + 1;
        kf_buf_append_i32(&body, (int32_t)tc);

        for (i = 0; i < tc; i++) {
            SV **elem = av_fetch(topics, i, 0);
            if (!elem || !SvROK(*elem)) continue;
            HV *th = (HV*)SvRV(*elem);

            SV **name_sv = hv_fetch(th, "name", 4, 0);
            if (!name_sv) continue;
            STRLEN nlen;
            const char *name = SvPV(*name_sv, nlen);
            kf_buf_append_string(&body, name, (int16_t)nlen);

            SV **np_sv = hv_fetch(th, "num_partitions", 14, 0);
            int32_t num_partitions = np_sv ? (int32_t)SvIV(*np_sv) : 1;
            kf_buf_append_i32(&body, num_partitions);

            SV **rf_sv = hv_fetch(th, "replication_factor", 18, 0);
            int16_t replication_factor = rf_sv ? (int16_t)SvIV(*rf_sv) : 1;
            kf_buf_append_i16(&body, replication_factor);

            /* assignments: empty array */
            kf_buf_append_i32(&body, 0);

            /* configs: empty array */
            kf_buf_append_i32(&body, 0);
        }

        kf_buf_append_i32(&body, timeout_ms);

        /* validate_only (v1+) */
        if (ver >= 1)
            kf_buf_append_i8(&body, 0);

        conn_send_request(aTHX_ self, API_CREATE_TOPICS, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
delete_topics(EV::Kafka::Conn self, SV *topics_sv, int timeout_ms, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_DELETE_TOPICS];
        if (ver < 0) ver = 0;
        if (ver > 3) ver = 3;

        kf_buf_t body;
        kf_buf_init(&body);

        AV *topics = (AV*)SvRV(topics_sv);
        SSize_t i, tc = av_len(topics) + 1;
        kf_buf_append_i32(&body, (int32_t)tc);

        for (i = 0; i < tc; i++) {
            SV **elem = av_fetch(topics, i, 0);
            if (!elem) continue;
            STRLEN tlen;
            const char *tname = SvPV(*elem, tlen);
            kf_buf_append_string(&body, tname, (int16_t)tlen);
        }

        kf_buf_append_i32(&body, timeout_ms);

        conn_send_request(aTHX_ self, API_DELETE_TOPICS, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
init_producer_id(EV::Kafka::Conn self, SV *transactional_id_sv, int txn_timeout_ms, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_INIT_PRODUCER_ID];
        if (ver < 0) ver = 0;
        if (ver > 1) ver = 1;

        kf_buf_t body;
        kf_buf_init(&body);

        if (SvOK(transactional_id_sv)) {
            STRLEN tlen;
            const char *tid = SvPV(transactional_id_sv, tlen);
            kf_buf_append_string(&body, tid, (int16_t)tlen);
        } else {
            kf_buf_append_nullable_string(&body, NULL, 0);
        }

        kf_buf_append_i32(&body, txn_timeout_ms);

        /* v2+: producer_id(i64=-1), producer_epoch(i16=-1) */
        if (ver >= 2) {
            kf_buf_append_i64(&body, -1);
            kf_buf_append_i16(&body, -1);
        }

        conn_send_request(aTHX_ self, API_INIT_PRODUCER_ID, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
add_partitions_to_txn(EV::Kafka::Conn self, const char *transactional_id, SV *producer_id_sv, int producer_epoch, SV *topics_sv, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_ADD_PARTITIONS_TXN];
        if (ver < 0) ver = 0;
        if (ver > 1) ver = 1;

        int64_t pid = SvIV(producer_id_sv);

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN tid_len = strlen(transactional_id);
        kf_buf_append_string(&body, transactional_id, (int16_t)tid_len);
        kf_buf_append_i64(&body, pid);
        kf_buf_append_i16(&body, (int16_t)producer_epoch);

        /* topics: ARRAY of {topic, partitions: ARRAY(i32)} */
        if (!SvROK(topics_sv) || SvTYPE(SvRV(topics_sv)) != SVt_PVAV)
            croak("add_partitions_to_txn: expected arrayref");
        AV *topics = (AV*)SvRV(topics_sv);
        SSize_t i, tc = av_len(topics) + 1;
        kf_buf_append_i32(&body, (int32_t)tc);

        for (i = 0; i < tc; i++) {
            SV **elem = av_fetch(topics, i, 0);
            if (!elem || !SvROK(*elem)) croak("add_partitions_to_txn: bad element");
            HV *th = (HV*)SvRV(*elem);
            SV **tname_sv = hv_fetch(th, "topic", 5, 0);
            if (!tname_sv) croak("add_partitions_to_txn: missing topic");
            STRLEN tnlen;
            const char *tname = SvPV(*tname_sv, tnlen);
            kf_buf_append_string(&body, tname, (int16_t)tnlen);

            SV **parts_sv = hv_fetch(th, "partitions", 10, 0);
            if (!parts_sv || !SvROK(*parts_sv)) croak("add_partitions_to_txn: missing partitions");
            AV *parts = (AV*)SvRV(*parts_sv);
            SSize_t j, pc = av_len(parts) + 1;
            kf_buf_append_i32(&body, (int32_t)pc);
            for (j = 0; j < pc; j++) {
                SV **pelem = av_fetch(parts, j, 0);
                kf_buf_append_i32(&body, pelem ? (int32_t)SvIV(*pelem) : 0);
            }
        }

        conn_send_request(aTHX_ self, API_ADD_PARTITIONS_TXN, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
end_txn(EV::Kafka::Conn self, const char *transactional_id, SV *producer_id_sv, int producer_epoch, int committed, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_END_TXN];
        if (ver < 0) ver = 0;
        if (ver > 1) ver = 1;

        int64_t pid = SvIV(producer_id_sv);

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN tid_len = strlen(transactional_id);
        kf_buf_append_string(&body, transactional_id, (int16_t)tid_len);
        kf_buf_append_i64(&body, pid);
        kf_buf_append_i16(&body, (int16_t)producer_epoch);
        kf_buf_append_i8(&body, committed ? 1 : 0);

        conn_send_request(aTHX_ self, API_END_TXN, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

void
txn_offset_commit(EV::Kafka::Conn self, const char *transactional_id, const char *group_id, SV *producer_id_sv, int producer_epoch, int generation_id, const char *member_id, SV *offsets_sv, SV *cb)
    CODE:
    {
        if (self->state != CONN_READY)
            croak("not connected");

        int16_t ver = self->api_versions[API_TXN_OFFSET_COMMIT];
        if (ver < 0) ver = 0;
        if (ver > 3) ver = 3;

        int64_t pid = SvIV(producer_id_sv);

        kf_buf_t body;
        kf_buf_init(&body);

        STRLEN tid_len = strlen(transactional_id);
        kf_buf_append_string(&body, transactional_id, (int16_t)tid_len);

        STRLEN gid_len = strlen(group_id);
        kf_buf_append_string(&body, group_id, (int16_t)gid_len);

        kf_buf_append_i64(&body, pid);
        kf_buf_append_i16(&body, (int16_t)producer_epoch);

        /* v3+: generation_id, member_id, group_instance_id */
        if (ver >= 3) {
            kf_buf_append_i32(&body, generation_id);
            STRLEN mid_len = strlen(member_id);
            kf_buf_append_string(&body, member_id, (int16_t)mid_len);
            kf_buf_append_nullable_string(&body, NULL, 0); /* group_instance_id */
        }

        /* offsets: ARRAY of {topic, partitions: [{partition, offset}]} */
        if (!SvROK(offsets_sv) || SvTYPE(SvRV(offsets_sv)) != SVt_PVAV)
            croak("txn_offset_commit: expected arrayref");
        AV *topics = (AV*)SvRV(offsets_sv);
        SSize_t i, tc = av_len(topics) + 1;
        kf_buf_append_i32(&body, (int32_t)tc);

        for (i = 0; i < tc; i++) {
            SV **elem = av_fetch(topics, i, 0);
            if (!elem || !SvROK(*elem)) croak("txn_offset_commit: bad element");
            HV *th = (HV*)SvRV(*elem);

            SV **tname_sv = hv_fetch(th, "topic", 5, 0);
            if (!tname_sv) croak("txn_offset_commit: missing topic");
            STRLEN tnlen;
            const char *tname = SvPV(*tname_sv, tnlen);
            kf_buf_append_string(&body, tname, (int16_t)tnlen);

            SV **parts_sv = hv_fetch(th, "partitions", 10, 0);
            if (!parts_sv || !SvROK(*parts_sv)) croak("txn_offset_commit: missing partitions");
            AV *parts = (AV*)SvRV(*parts_sv);
            SSize_t j, pc = av_len(parts) + 1;
            kf_buf_append_i32(&body, (int32_t)pc);

            for (j = 0; j < pc; j++) {
                SV **pelem = av_fetch(parts, j, 0);
                if (!pelem || !SvROK(*pelem)) croak("txn_offset_commit: bad partition");
                HV *ph = (HV*)SvRV(*pelem);

                SV **ppid_sv = hv_fetch(ph, "partition", 9, 0);
                kf_buf_append_i32(&body, ppid_sv ? (int32_t)SvIV(*ppid_sv) : 0);

                SV **off_sv = hv_fetch(ph, "offset", 6, 0);
                kf_buf_append_i64(&body, off_sv ? (int64_t)SvIV(*off_sv) : 0);

                /* leader_epoch (v2+) */
                if (ver >= 2)
                    kf_buf_append_i32(&body, -1);

                kf_buf_append_nullable_string(&body, "", 0); /* metadata */
            }
        }

        conn_send_request(aTHX_ self, API_TXN_OFFSET_COMMIT, ver, &body, cb, 0, 0);
        kf_buf_free(&body);
    }

MODULE = EV::Kafka  PACKAGE = EV::Kafka

EV::Kafka
_new(char *cls, SV *loop_sv)
    CODE:
    {
        struct ev_loop *loop;
        ev_kafka_t *self;

        if (SvOK(loop_sv) && sv_derived_from(loop_sv, "EV::Loop"))
            loop = (struct ev_loop *)SvIV(SvRV(loop_sv));
        else
            loop = EV_DEFAULT;

        Newxz(self, 1, ev_kafka_t);
        self->magic = KF_MAGIC_ALIVE;
        self->loop = loop;

        ngx_queue_init(&self->brokers);
        ngx_queue_init(&self->topics);
        ngx_queue_init(&self->produce_batches);
        ngx_queue_init(&self->consume_partitions);

        self->client_id = savepv("ev-kafka");
        self->client_id_len = 8;

        /* Producer defaults */
        self->linger_ms = 5.0;
        self->batch_size = 16384;
        self->acks = -1;
        self->max_request_size = 1048576;

        /* Consumer defaults */
        self->fetch_max_bytes = 1048576;
        self->fetch_min_bytes = 1;
        self->fetch_max_wait_ms = 500;

        /* Metadata defaults */
        self->metadata_refresh_interval = 300.0;

        RETVAL = self;
    }
    OUTPUT:
        RETVAL

void
DESTROY(EV::Kafka self)
    CODE:
    {
        if (self->magic != KF_MAGIC_ALIVE) return;
        self->magic = KF_MAGIC_FREED;

        /* Clean up broker connections */
        while (!ngx_queue_empty(&self->brokers)) {
            ngx_queue_t *q = ngx_queue_head(&self->brokers);
            ngx_queue_remove(q);
            ev_kafka_conn_t *conn = ngx_queue_data(q, ev_kafka_conn_t, cluster_queue);
            conn->cluster = NULL;
            conn->intentional_disconnect = 1;
            conn_cleanup(aTHX_ conn);
            /* Note: conn is owned by its Perl SV, will be freed by Perl GC */
        }

        /* Clean up topic metadata */
        while (!ngx_queue_empty(&self->topics)) {
            ngx_queue_t *q = ngx_queue_head(&self->topics);
            ngx_queue_remove(q);
            kf_topic_meta_t *tm = ngx_queue_data(q, kf_topic_meta_t, queue);
            if (tm->name) Safefree(tm->name);
            if (tm->partitions) Safefree(tm->partitions);
            Safefree(tm);
        }

        if (self->metadata_timing) {
            ev_timer_stop(self->loop, &self->metadata_timer);
            self->metadata_timing = 0;
        }
        if (self->linger_timing) {
            ev_timer_stop(self->loop, &self->linger_timer);
            self->linger_timing = 0;
        }
        if (self->fetch_timing) {
            ev_timer_stop(self->loop, &self->fetch_timer);
            self->fetch_timing = 0;
        }

        /* Free bootstrap */
        if (self->bootstrap_hosts) {
            int i;
            for (i = 0; i < self->bootstrap_count; i++)
                if (self->bootstrap_hosts[i]) Safefree(self->bootstrap_hosts[i]);
            Safefree(self->bootstrap_hosts);
        }
        if (self->bootstrap_ports) Safefree(self->bootstrap_ports);

        /* Free consumer group */
        if (self->group) {
            if (self->group->heartbeat_timing)
                ev_timer_stop(self->loop, &self->group->heartbeat_timer);
            if (self->group->group_id) Safefree(self->group->group_id);
            if (self->group->member_id) Safefree(self->group->member_id);
            CLEAR_HANDLER(self->group->on_assign);
            CLEAR_HANDLER(self->group->on_revoke);
            if (self->group->subscriptions) SvREFCNT_dec((SV*)self->group->subscriptions);
            Safefree(self->group);
        }

        CLEAR_HANDLER(self->on_error);
        CLEAR_HANDLER(self->on_connect);
        CLEAR_HANDLER(self->on_message);
        CLEAR_HANDLER(self->partitioner);

        if (self->client_id) Safefree(self->client_id);
        if (self->sasl_mechanism) Safefree(self->sasl_mechanism);
        if (self->sasl_username) Safefree(self->sasl_username);
        if (self->sasl_password) Safefree(self->sasl_password);
        if (self->tls_ca_file) Safefree(self->tls_ca_file);

        Safefree(self);
    }

int
_murmur2(SV *data_sv)
    CODE:
    {
        STRLEN len;
        const unsigned char *data = (const unsigned char *)SvPV(data_sv, len);
        uint32_t h = 0x9747b28c ^ (uint32_t)len;
        const uint32_t m = 0x5bd1e995;
        size_t i = 0;
        size_t remaining = len;

        while (remaining >= 4) {
            uint32_t k;
            memcpy(&k, data + i, 4); /* little-endian on x86, matches Java */
            k *= m;
            k ^= k >> 24;
            k *= m;
            h *= m;
            h ^= k;
            i += 4;
            remaining -= 4;
        }

        switch (remaining) {
            case 3: h ^= (uint32_t)data[i + 2] << 16; /* fallthrough */
            case 2: h ^= (uint32_t)data[i + 1] << 8;  /* fallthrough */
            case 1: h ^= (uint32_t)data[i]; h *= m;
        }

        h ^= h >> 13;
        h *= m;
        h ^= h >> 15;

        RETVAL = (int)(h & 0x7FFFFFFF);
    }
    OUTPUT:
        RETVAL

unsigned int
_crc32c(SV *data_sv)
    CODE:
    {
        STRLEN len;
        const char *data = SvPV(data_sv, len);
        RETVAL = crc32c(data, len);
    }
    OUTPUT:
        RETVAL

void
_error_name(int code)
    PPCODE:
    {
        const char *name = NULL;
        switch (code) {
            case  0: name = "NONE"; break;
            case  1: name = "OFFSET_OUT_OF_RANGE"; break;
            case  2: name = "CORRUPT_MESSAGE"; break;
            case  3: name = "UNKNOWN_TOPIC_OR_PARTITION"; break;
            case  5: name = "LEADER_NOT_AVAILABLE"; break;
            case  6: name = "NOT_LEADER_OR_FOLLOWER"; break;
            case  7: name = "REQUEST_TIMED_OUT"; break;
            case 10: name = "MESSAGE_TOO_LARGE"; break;
            case 15: name = "COORDINATOR_NOT_AVAILABLE"; break;
            case 16: name = "NOT_COORDINATOR"; break;
            case 17: name = "INVALID_TOPIC_EXCEPTION"; break;
            case 22: name = "ILLEGAL_GENERATION"; break;
            case 25: name = "UNKNOWN_MEMBER_ID"; break;
            case 27: name = "REBALANCE_IN_PROGRESS"; break;
            case 35: name = "UNSUPPORTED_VERSION"; break;
            case 36: name = "TOPIC_ALREADY_EXISTS"; break;
            case 39: name = "REASSIGNMENT_IN_PROGRESS"; break;
            case 41: name = "NOT_CONTROLLER"; break;
            case 47: name = "INVALID_REPLICATION_FACTOR"; break;
            case 58: name = "SASL_AUTHENTICATION_FAILED"; break;
            case 72: name = "LISTENER_NOT_FOUND"; break;
            case 79: name = "MEMBER_ID_REQUIRED"; break;
            default: name = "UNKNOWN"; break;
        }
        EXTEND(SP, 1);
        mPUSHp(name, strlen(name));
        XSRETURN(1);
    }

BOOT:
{
    I_EV_API("EV::Kafka");
    crc32c_init_table();
}
