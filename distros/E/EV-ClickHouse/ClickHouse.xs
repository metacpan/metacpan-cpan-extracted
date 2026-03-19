#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "EVAPI.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <zlib.h>

#define CH_MAX_DECOMPRESS_SIZE (128 * 1024 * 1024)  /* 128 MB safety limit */

#ifdef HAVE_LZ4
#include <lz4.h>
#include "cityhash.h"

#define CH_LZ4_METHOD     0x82
#define CH_CHECKSUM_SIZE  16
#define CH_COMPRESS_HEADER_SIZE 9   /* 1 (method) + 4 (compressed_size) + 4 (uncompressed_size) */
#endif

#ifdef HAVE_OPENSSL
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>
#endif

#include "ngx_queue.h"

typedef struct ev_clickhouse_s ev_clickhouse_t;
typedef struct ev_ch_cb_s ev_ch_cb_t;
typedef struct ev_ch_send_s ev_ch_send_t;

typedef ev_clickhouse_t* EV__ClickHouse;
typedef struct ev_loop* EV__Loop;

#define EV_CH_MAGIC 0xC11C4011
#define EV_CH_FREED 0xFEEDFACE

#define PROTO_HTTP   0
#define PROTO_NATIVE 1

#define RECV_BUF_INIT 8192
#define SEND_BUF_INIT 4096

/* ClickHouse native protocol client info */
#define CH_CLIENT_NAME "EV::ClickHouse"
#define CH_CLIENT_VERSION_MAJOR 0
#define CH_CLIENT_VERSION_MINOR 1
#define CH_CLIENT_REVISION 54459

/* Protocol revision thresholds */
#define DBMS_MIN_REVISION_WITH_BLOCK_INFO          51903
#define DBMS_MIN_REVISION_WITH_SERVER_DISPLAY_NAME 54372
#define DBMS_MIN_REVISION_WITH_VERSION_PATCH       54401
#define DBMS_MIN_REVISION_WITH_PROGRESS_WRITES     54420
#define DBMS_MIN_REVISION_WITH_SERVER_TIMEZONE     54423
#define DBMS_MIN_REVISION_WITH_OPENTELEMETRY       54442
#define DBMS_MIN_REVISION_WITH_CUSTOM_SERIALIZATION 54454
#define DBMS_MIN_PROTOCOL_VERSION_WITH_INITIAL_QUERY_START_TIME 54449
#define DBMS_MIN_PROTOCOL_VERSION_WITH_ADDENDUM    54458
#define DBMS_MIN_PROTOCOL_VERSION_WITH_PARAMETERS  54459

/* Client packet types */
#define CLIENT_HELLO  0
#define CLIENT_QUERY  1
#define CLIENT_DATA   2
#define CLIENT_CANCEL 3
#define CLIENT_PING   4

/* Server packet types */
#define SERVER_HELLO         0
#define SERVER_DATA          1
#define SERVER_EXCEPTION     2
#define SERVER_PROGRESS      3
#define SERVER_PONG          4
#define SERVER_END_OF_STREAM 5
#define SERVER_PROFILE_INFO  6
#define SERVER_TOTALS        7
#define SERVER_EXTREMES      8
#define SERVER_LOG              10
#define SERVER_TABLE_COLUMNS    11
#define SERVER_PROFILE_EVENTS   14

/* Query kind */
#define QUERY_INITIAL 1

/* Query stage */
#define STAGE_COMPLETE 2

/* Native protocol states */
#define NATIVE_IDLE             0
#define NATIVE_WAIT_HELLO       1
#define NATIVE_WAIT_RESULT      2
#define NATIVE_WAIT_INSERT_META 3

/* Decode flags for column value formatting (opt-in) */
#define DECODE_DT_STR     (1 << 0)  /* Date/DateTime/DateTime64 → string */
#define DECODE_DEC_SCALE  (1 << 1)  /* Decimal → scaled NV */
#define DECODE_ENUM_STR   (1 << 2)  /* Enum → string label */
#define DECODE_NAMED_ROWS (1 << 3)  /* results as arrayref of hashrefs */

struct ev_clickhouse_s {
    unsigned int magic;
    struct ev_loop *loop;

    int fd;
    ev_io rio, wio;
    ev_timer timer;
    int reading, writing, timing;
    int connected, connecting;
    int protocol;               /* PROTO_HTTP or PROTO_NATIVE */

#ifdef HAVE_OPENSSL
    SSL_CTX *ssl_ctx;
    SSL *ssl;
#endif
    int tls_enabled;
    char *tls_ca_file;

    /* connection params */
    char *host, *user, *password, *database;
    unsigned int port;

    /* send/recv buffers */
    char *send_buf;
    size_t send_len, send_pos, send_cap;
    char *recv_buf;
    size_t recv_len, recv_cap;

    /* native protocol state */
    char *server_name;
    char *server_display_name;
    char *server_timezone;
    unsigned int server_version_major, server_version_minor, server_revision;
    unsigned int server_version_patch;
    int native_state;           /* NATIVE_IDLE, NATIVE_WAIT_HELLO, NATIVE_WAIT_RESULT, ... */
    AV *native_rows;            /* accumulate rows across Data blocks */
    char *insert_data;          /* pending TabSeparated data for two-phase INSERT */
    size_t insert_data_len;
    SV *insert_av;              /* pending AV* of AV*s for arrayref INSERT */
    char *insert_err;           /* deferred error from unsupported INSERT encoding */

    /* queues */
    ngx_queue_t cb_queue;
    ngx_queue_t send_queue;
    int pending_count;
    int send_count;

    /* options */
    char *session_id;
    int compress;
    double connect_timeout;
    HV *default_settings;           /* connection-level ClickHouse settings */

    SV *on_connect;
    SV *on_error;
    SV *on_progress;
    SV *on_disconnect;
    int tls_skip_verify;
    double query_timeout;
    int auto_reconnect;
    uint32_t decode_flags;
    AV *native_col_names;   /* column names from last native result */
    AV *native_col_types;   /* column type strings from last native result */
    SV *on_drain;           /* callback fired when pending_count drops to 0 */
    char *last_query_id;    /* query_id of the last dispatched query */
    SV *on_trace;           /* debug trace callback */
    ev_timer ka_timer;      /* keepalive timer */
    double keepalive;       /* keepalive interval (0 = disabled) */
    int ka_timing;
    int callback_depth;
    /* error info from last SERVER_EXCEPTION or HTTP error */
    int32_t last_error_code;
    /* profile info from last SERVER_PROFILE_INFO */
    uint64_t profile_rows;
    uint64_t profile_bytes;
    uint64_t profile_rows_before_limit;
    /* totals / extremes from last native query */
    AV *native_totals;
    AV *native_extremes;
    /* reconnect backoff */
    double reconnect_delay;
    double reconnect_max_delay;
    int reconnect_attempts;
    ev_timer reconnect_timer;
    int reconnect_timing;
    /* LowCardinality cross-block dictionary state */
    SV ***lc_dicts;           /* array of dictionaries, one per column */
    uint64_t *lc_dict_sizes;  /* size of each dictionary */
    int lc_num_cols;          /* number of columns with LC state */
};

struct ev_ch_cb_s {
    SV          *cb;
    int          raw;        /* return raw response body instead of parsed rows */
    SV          *on_data;    /* per-query streaming callback (fires per block) */
    double       query_timeout;  /* per-query timeout (0=use default) */
    ngx_queue_t  queue;
};

struct ev_ch_send_s {
    char        *data;      /* full HTTP request or native packet */
    size_t       data_len;
    SV          *cb;
    char        *insert_data;     /* deferred TSV data for native INSERT */
    size_t       insert_data_len;
    SV          *insert_av;      /* deferred AV* data for native INSERT */
    int          raw;            /* return raw response body */
    SV          *on_data;        /* per-query streaming callback */
    double       query_timeout;  /* per-query timeout */
    char        *query_id;       /* query_id for tracking */
    ngx_queue_t  queue;
};

/* forward declarations */
static void io_cb(EV_P_ ev_io *w, int revents);
static void timer_cb(EV_P_ ev_timer *w, int revents);
static void ka_timer_cb(EV_P_ ev_timer *w, int revents);
static void start_keepalive(ev_clickhouse_t *self);
static void stop_keepalive(ev_clickhouse_t *self);
static void schedule_reconnect(ev_clickhouse_t *self);
static void lc_free_dicts(ev_clickhouse_t *self);
static void start_reading(ev_clickhouse_t *self);
static void stop_reading(ev_clickhouse_t *self);
static void start_writing(ev_clickhouse_t *self);
static void stop_writing(ev_clickhouse_t *self);
static void emit_error(ev_clickhouse_t *self, const char *msg);
static void emit_trace(ev_clickhouse_t *self, const char *fmt, ...);
static void cleanup_connection(ev_clickhouse_t *self);
static int  cancel_pending(ev_clickhouse_t *self, const char *errmsg);
static int  check_destroyed(ev_clickhouse_t *self);
static void on_connect_done(ev_clickhouse_t *self);
static void process_http_response(ev_clickhouse_t *self);
static int try_write(ev_clickhouse_t *self);
static int pipeline_advance(ev_clickhouse_t *self);
static void on_readable(ev_clickhouse_t *self);

/* --- freelist for cb_queue entries --- */

static ev_ch_cb_t *cbt_freelist = NULL;

static ev_ch_cb_t* alloc_cbt(void) {
    ev_ch_cb_t *cbt;
    if (cbt_freelist) {
        cbt = cbt_freelist;
        cbt_freelist = *(ev_ch_cb_t **)cbt;
    } else {
        Newx(cbt, 1, ev_ch_cb_t);
    }
    cbt->raw = 0;
    cbt->on_data = NULL;
    cbt->query_timeout = 0;
    return cbt;
}

static void release_cbt(ev_ch_cb_t *cbt) {
    *(ev_ch_cb_t **)cbt = cbt_freelist;
    cbt_freelist = cbt;
}

/* --- freelist for send_queue entries --- */

static ev_ch_send_t *send_freelist = NULL;

static ev_ch_send_t* alloc_send(void) {
    ev_ch_send_t *s;
    if (send_freelist) {
        s = send_freelist;
        send_freelist = *(ev_ch_send_t **)s;
    } else {
        Newx(s, 1, ev_ch_send_t);
    }
    s->insert_data = NULL;
    s->insert_data_len = 0;
    s->insert_av = NULL;
    s->raw = 0;
    s->on_data = NULL;
    s->query_timeout = 0;
    s->query_id = NULL;
    return s;
}

static void release_send(ev_ch_send_t *s) {
    if (s->query_id) { Safefree(s->query_id); s->query_id = NULL; }
    *(ev_ch_send_t **)s = send_freelist;
    send_freelist = s;
}

/* --- watcher helpers --- */

static void start_reading(ev_clickhouse_t *self) {
    if (!self->reading && self->fd >= 0) {
        ev_io_start(self->loop, &self->rio);
        self->reading = 1;
    }
}

static void stop_reading(ev_clickhouse_t *self) {
    if (self->reading) {
        ev_io_stop(self->loop, &self->rio);
        self->reading = 0;
    }
}

static void start_writing(ev_clickhouse_t *self) {
    if (!self->writing && self->fd >= 0) {
        ev_io_start(self->loop, &self->wio);
        self->writing = 1;
    }
}

static void stop_writing(ev_clickhouse_t *self) {
    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

static int check_destroyed(ev_clickhouse_t *self) {
    if (self->magic == EV_CH_FREED && self->callback_depth == 0) {
        Safefree(self);
        return 1;
    }
    return 0;
}

static void emit_error(ev_clickhouse_t *self, const char *msg) {
    if (NULL == self->on_error) return;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(msg, 0)));
    PUTBACK;

    call_sv(self->on_error, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::ClickHouse: exception in error handler: %s", SvPV_nolen(ERRSV));
    }

    FREETMPS;
    LEAVE;
}

static void emit_trace(ev_clickhouse_t *self, const char *fmt, ...) {
    char buf[512];
    va_list ap;
    if (NULL == self->on_trace) return;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(buf, 0)));
        PUTBACK;
        call_sv(self->on_trace, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV))
            warn("EV::ClickHouse: exception in trace handler: %s", SvPV_nolen(ERRSV));
        FREETMPS;
        LEAVE;
    }
}

static SV* pop_cb(ev_clickhouse_t *self) {
    ngx_queue_t *q;
    ev_ch_cb_t *cbt;
    SV *cb;

    if (ngx_queue_empty(&self->cb_queue)) return NULL;

    q = ngx_queue_head(&self->cb_queue);
    cbt = ngx_queue_data(q, ev_ch_cb_t, queue);

    cb = cbt->cb;
    if (cbt->on_data) { SvREFCNT_dec(cbt->on_data); cbt->on_data = NULL; }
    ngx_queue_remove(q);
    self->pending_count--;
    release_cbt(cbt);

    return cb;
}

/* Peek the on_data callback from front of cb_queue (NULL if none) */
static SV* peek_cb_on_data(ev_clickhouse_t *self) {
    ngx_queue_t *q;
    ev_ch_cb_t *cbt;
    if (ngx_queue_empty(&self->cb_queue)) return NULL;
    q = ngx_queue_head(&self->cb_queue);
    cbt = ngx_queue_data(q, ev_ch_cb_t, queue);
    return cbt->on_data;
}

static int peek_cb_raw(ev_clickhouse_t *self) {
    ngx_queue_t *q;
    ev_ch_cb_t *cbt;
    if (ngx_queue_empty(&self->cb_queue)) return 0;
    q = ngx_queue_head(&self->cb_queue);
    cbt = ngx_queue_data(q, ev_ch_cb_t, queue);
    return cbt->raw;
}

static void invoke_cb(SV *cb) {
    call_sv(cb, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV)) {
        warn("EV::ClickHouse: exception in callback: %s", SvPV_nolen(ERRSV));
    }
    SvREFCNT_dec(cb);
}

/* Returns 1 if self was freed. */
static int deliver_error(ev_clickhouse_t *self, const char *errmsg) {
    SV *cb = pop_cb(self);
    if (cb == NULL) return 0;

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUSHs(&PL_sv_undef);
        PUSHs(sv_2mortal(newSVpv(errmsg, 0)));
        PUTBACK;
        invoke_cb(cb);
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
    return check_destroyed(self);
}

/* Returns 1 if self was freed. */
static int deliver_rows(ev_clickhouse_t *self, AV *rows) {
    SV *cb = pop_cb(self);
    if (cb == NULL) {
        if (rows) SvREFCNT_dec((SV*)rows);
        return 0;
    }

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        if (rows) {
            PUSHs(sv_2mortal(newRV_noinc((SV*)rows)));
        } else {
            PUSHs(&PL_sv_undef);
        }
        PUTBACK;
        invoke_cb(cb);
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
    return check_destroyed(self);
}

/* Deliver raw response body as scalar string. Returns 1 if self was freed. */
static int deliver_raw_body(ev_clickhouse_t *self, const char *data, size_t len) {
    SV *cb = pop_cb(self);
    if (cb == NULL) return 0;

    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUSHs(sv_2mortal(newSVpvn(data, len)));
        PUTBACK;
        invoke_cb(cb);
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
    return check_destroyed(self);
}

static void push_cb_owned_ex(ev_clickhouse_t *self, SV *cb, int raw,
                              SV *on_data, double query_timeout) {
    ev_ch_cb_t *cbt = alloc_cbt();
    cbt->cb = cb;
    cbt->raw = raw;
    cbt->on_data = on_data ? SvREFCNT_inc(on_data) : NULL;
    cbt->query_timeout = query_timeout;
    ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
    /* pending_count already counted */
}

static SV* handler_accessor(SV **slot, SV *handler, int has_arg) {
    if (has_arg) {
        if (NULL != *slot) {
            SvREFCNT_dec(*slot);
            *slot = NULL;
        }
        if (NULL != handler && SvOK(handler) &&
            SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
            *slot = SvREFCNT_inc(handler);
        }
    }
    return (NULL != *slot) ? SvREFCNT_inc(*slot) : &PL_sv_undef;
}

static char* safe_strdup(const char *s) {
    char *d;
    size_t len;
    if (!s) return NULL;
    len = strlen(s);
    Newx(d, len + 1, char);
    Copy(s, d, len + 1, char);
    return d;
}

static int has_http_unsafe_chars(const char *s) {
    if (!s) return 0;
    for (; *s; s++)
        if (*s == '\r' || *s == '\n') return 1;
    return 0;
}

static int is_ip_literal(const char *s) {
    struct in_addr  a4;
    struct in6_addr a6;
    return (inet_pton(AF_INET, s, &a4) == 1 ||
            inet_pton(AF_INET6, s, &a6) == 1);
}

static void cleanup_connection(ev_clickhouse_t *self) {
    int was_connected = self->connected;

    if (was_connected) emit_trace(self, "disconnect");
    stop_reading(self);
    stop_writing(self);
    stop_keepalive(self);
    if (self->timing) {
        ev_timer_stop(self->loop, &self->timer);
        self->timing = 0;
    }

#ifdef HAVE_OPENSSL
    if (self->ssl) {
        SSL_shutdown(self->ssl);
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

    self->connected = 0;
    self->connecting = 0;

    /* fire on_disconnect if we were connected */
    if (was_connected && NULL != self->on_disconnect) {
        self->callback_depth++;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            call_sv(self->on_disconnect, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV))
                warn("EV::ClickHouse: exception in disconnect handler: %s",
                     SvPV_nolen(ERRSV));
            FREETMPS;
            LEAVE;
        }
        self->callback_depth--;
    }
    self->send_len = 0;
    self->send_pos = 0;
    self->recv_len = 0;
    self->send_count = 0;
    self->native_state = NATIVE_IDLE;
    if (self->native_rows) {
        SvREFCNT_dec((SV*)self->native_rows);
        self->native_rows = NULL;
    }
    if (self->native_col_names) {
        SvREFCNT_dec((SV*)self->native_col_names);
        self->native_col_names = NULL;
    }
    if (self->native_col_types) {
        SvREFCNT_dec((SV*)self->native_col_types);
        self->native_col_types = NULL;
    }
    if (self->native_totals) {
        SvREFCNT_dec((SV*)self->native_totals);
        self->native_totals = NULL;
    }
    if (self->native_extremes) {
        SvREFCNT_dec((SV*)self->native_extremes);
        self->native_extremes = NULL;
    }
    lc_free_dicts(self);
    if (self->insert_data) {
        Safefree(self->insert_data);
        self->insert_data = NULL;
        self->insert_data_len = 0;
    }
    if (self->insert_av) {
        SvREFCNT_dec(self->insert_av);
        self->insert_av = NULL;
    }
    if (self->insert_err) {
        Safefree(self->insert_err);
        self->insert_err = NULL;
    }
}

/* Returns 1 if self was freed. */
static int cancel_pending(ev_clickhouse_t *self, const char *errmsg) {
    self->callback_depth++;

    while (!ngx_queue_empty(&self->send_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->send_queue);
        ev_ch_send_t *send = ngx_queue_data(q, ev_ch_send_t, queue);
        SV *cb = send->cb;
        ngx_queue_remove(q);
        Safefree(send->data);
        if (send->insert_data) Safefree(send->insert_data);
        if (send->insert_av) { SvREFCNT_dec(send->insert_av); send->insert_av = NULL; }
        if (send->on_data) { SvREFCNT_dec(send->on_data); send->on_data = NULL; }
        release_send(send);
        self->pending_count--;

        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUSHs(&PL_sv_undef);
            PUSHs(sv_2mortal(newSVpv(errmsg, 0)));
            PUTBACK;
            invoke_cb(cb);
            FREETMPS;
            LEAVE;
        }
        if (self->magic != EV_CH_MAGIC) break;
    }

    while (!ngx_queue_empty(&self->cb_queue)) {
        SV *cb = pop_cb(self);
        if (cb == NULL) break;

        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUSHs(&PL_sv_undef);
            PUSHs(sv_2mortal(newSVpv(errmsg, 0)));
            PUTBACK;
            invoke_cb(cb);
            FREETMPS;
            LEAVE;
        }
        if (self->magic != EV_CH_MAGIC) break;
    }

    self->send_count = 0;
    self->callback_depth--;
    return check_destroyed(self);
}

/* --- I/O helpers (with optional TLS) --- */

static ssize_t ch_read(ev_clickhouse_t *self, void *buf, size_t len) {
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
                start_writing(self);
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

static ssize_t ch_write(ev_clickhouse_t *self, const void *buf, size_t len) {
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
                start_reading(self);
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

/* --- Buffer management --- */

static void ensure_recv_cap(ev_clickhouse_t *self, size_t need) {
    if (self->recv_cap >= need) return;
    if (need > SIZE_MAX / 2) croak("recv buffer overflow");
    size_t newcap = self->recv_cap * 2;
    if (newcap < need) newcap = need;
    Renew(self->recv_buf, newcap, char);
    self->recv_cap = newcap;
}

static void ensure_send_cap(ev_clickhouse_t *self, size_t need) {
    if (self->send_cap >= need) return;
    if (need > SIZE_MAX / 2) croak("send buffer overflow");
    size_t newcap = self->send_cap * 2;
    if (newcap < need) newcap = need;
    Renew(self->send_buf, newcap, char);
    self->send_cap = newcap;
}

/* --- Native protocol buffer (for building packets) --- */

typedef struct {
    char *data;
    size_t len;
    size_t cap;
} native_buf_t;

static void nbuf_init(native_buf_t *b) {
    b->cap = 256;
    b->len = 0;
    Newx(b->data, b->cap, char);
}

static void nbuf_grow(native_buf_t *b, size_t need) {
    if (b->len + need > b->cap) {
        while (b->len + need > b->cap) {
            if (b->cap > SIZE_MAX / 2) croak("native buffer overflow");
            b->cap *= 2;
        }
        Renew(b->data, b->cap, char);
    }
}

static void nbuf_append(native_buf_t *b, const char *data, size_t len) {
    nbuf_grow(b, len);
    memcpy(b->data + b->len, data, len);
    b->len += len;
}

static void nbuf_varuint(native_buf_t *b, uint64_t n) {
    nbuf_grow(b, 10);
    while (n >= 0x80) {
        b->data[b->len++] = (char)((n & 0x7F) | 0x80);
        n >>= 7;
    }
    b->data[b->len++] = (char)n;
}

static void nbuf_string(native_buf_t *b, const char *s, size_t len) {
    nbuf_varuint(b, (uint64_t)len);
    nbuf_append(b, s, len);
}

static void nbuf_cstring(native_buf_t *b, const char *s) {
    nbuf_string(b, s, s ? strlen(s) : 0);
}

static void nbuf_u8(native_buf_t *b, uint8_t v) {
    nbuf_grow(b, 1);
    b->data[b->len++] = (char)v;
}

/* --- Native protocol read helpers (from recv_buf) --- */

/* Returns 1=success, 0=need more data, -1=overflow */
static int read_varuint(const char *buf, size_t len, size_t *pos, uint64_t *out) {
    uint64_t val = 0;
    unsigned shift = 0;
    size_t p = *pos;
    while (p < len) {
        uint8_t byte = (uint8_t)buf[p++];
        val |= (uint64_t)(byte & 0x7F) << shift;
        if (!(byte & 0x80)) {
            *out = val;
            *pos = p;
            return 1;
        }
        shift += 7;
        if (shift >= 64) return -1;
    }
    return 0;
}

static int read_native_string_alloc(const char *buf, size_t len, size_t *pos,
                                     char **out, size_t *out_len) {
    uint64_t slen;
    size_t saved = *pos;
    int rc = read_varuint(buf, len, pos, &slen);
    if (rc <= 0) { *pos = saved; return rc; }
    if (slen > len - *pos) { *pos = saved; return 0; }
    Newx(*out, slen + 1, char);
    Copy(buf + *pos, *out, slen, char);
    (*out)[slen] = '\0';
    if (out_len) *out_len = (size_t)slen;
    *pos += slen;
    return 1;
}

/* Read a string without allocating — returns pointer into buf */
static int read_native_string_ref(const char *buf, size_t len, size_t *pos,
                                   const char **out, size_t *out_len) {
    uint64_t slen;
    size_t saved = *pos;
    int rc = read_varuint(buf, len, pos, &slen);
    if (rc <= 0) { *pos = saved; return rc; }
    if (slen > len - *pos) { *pos = saved; return 0; }
    *out = buf + *pos;
    *out_len = (size_t)slen;
    *pos += slen;
    return 1;
}

static int read_u8(const char *buf, size_t len, size_t *pos, uint8_t *out) {
    if (*pos + 1 > len) return 0;
    *out = (uint8_t)buf[*pos];
    (*pos)++;
    return 1;
}

static int read_i32(const char *buf, size_t len, size_t *pos, int32_t *out) {
    if (*pos + 4 > len) return 0;
    memcpy(out, buf + *pos, 4);
    *pos += 4;
    return 1;
}

/* Skip VarUInt without storing */
static int skip_varuint(const char *buf, size_t len, size_t *pos) {
    uint64_t dummy;
    return read_varuint(buf, len, pos, &dummy);
}

/* Skip native string */
static int skip_native_string(const char *buf, size_t len, size_t *pos) {
    uint64_t slen;
    size_t saved = *pos;
    int rc = read_varuint(buf, len, pos, &slen);
    if (rc <= 0) { *pos = saved; return rc; }
    if (slen > len - *pos) { *pos = saved; return 0; }
    *pos += slen;
    return 1;
}

/* --- URL encoding --- */

static size_t url_encode(const char *src, size_t src_len, char *dst) {
    static const char hex[] = "0123456789ABCDEF";
    size_t j = 0;
    size_t i;
    for (i = 0; i < src_len; i++) {
        unsigned char c = (unsigned char)src[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~') {
            dst[j++] = c;
        } else {
            dst[j++] = '%';
            dst[j++] = hex[c >> 4];
            dst[j++] = hex[c & 0x0F];
        }
    }
    return j;
}

/* --- Per-query settings helpers --- */

/* Compute buffer space needed for URL-encoded settings params.
 * Returns bytes needed for "&key=value" pairs (with URL encoding). */
static int is_client_only_key(const char *key, I32 klen) {
    return (klen == 3 && memcmp(key, "raw", 3) == 0)
        || (klen == 8 && memcmp(key, "query_id", 8) == 0)
        || (klen == 7 && memcmp(key, "on_data", 7) == 0)
        || (klen == 13 && memcmp(key, "query_timeout", 13) == 0)
        || (klen == 6 && memcmp(key, "params", 6) == 0);
}

static size_t settings_url_params_size(HV *defaults, HV *overrides) {
    size_t total = 0;
    HE *entry;
    if (overrides) {
        hv_iterinit(overrides);
        while ((entry = hv_iternext(overrides))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            if (is_client_only_key(key, klen)) continue;
            (void)SvPV(hv_iterval(overrides, entry), vlen);
            total += 2 + (size_t)klen * 3 + (size_t)vlen * 3;
        }
    }
    if (defaults) {
        hv_iterinit(defaults);
        while ((entry = hv_iternext(defaults))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            if (overrides && hv_exists(overrides, key, klen))
                continue;  /* overridden */
            if (is_client_only_key(key, klen)) continue;
            (void)SvPV(hv_iterval(defaults, entry), vlen);
            total += 2 + (size_t)klen * 3 + (size_t)vlen * 3;
        }
    }
    return total;
}

/* Append merged settings as URL params (&key=encoded_value).
 * Extracts query_id into *query_id_out (caller must not free — points into HV).
 * Per-query overrides take precedence over connection defaults.
 * Returns new position in params buffer. */
static size_t append_settings_url_params(char *params, size_t plen,
                                          HV *defaults, HV *overrides,
                                          const char **query_id_out, STRLEN *query_id_len_out) {
    HE *entry;
    *query_id_out = NULL;
    *query_id_len_out = 0;

    /* Write overrides first */
    if (overrides) {
        hv_iterinit(overrides);
        while ((entry = hv_iternext(overrides))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            char *val = SvPV(hv_iterval(overrides, entry), vlen);
            if (klen == 8 && memcmp(key, "query_id", 8) == 0) {
                *query_id_out = val;
                *query_id_len_out = vlen;
                continue;
            }
            if (is_client_only_key(key, klen)) continue;
            params[plen++] = '&';
            plen += url_encode(key, (size_t)klen, params + plen);
            params[plen++] = '=';
            plen += url_encode(val, vlen, params + plen);
        }
    }
    /* Write defaults, skipping keys present in overrides */
    if (defaults) {
        hv_iterinit(defaults);
        while ((entry = hv_iternext(defaults))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            char *val = SvPV(hv_iterval(defaults, entry), vlen);
            if (overrides && hv_exists(overrides, key, klen))
                continue;
            if (klen == 8 && memcmp(key, "query_id", 8) == 0) {
                if (!*query_id_out) {
                    *query_id_out = val;
                    *query_id_len_out = vlen;
                }
                continue;
            }
            if (is_client_only_key(key, klen)) continue;
            params[plen++] = '&';
            plen += url_encode(key, (size_t)klen, params + plen);
            params[plen++] = '=';
            plen += url_encode(val, vlen, params + plen);
        }
    }
    return plen;
}

/* Write merged settings in native protocol wire format.
 * Format per setting: String name, UInt8 is_important(0), String value.
 * Terminated by empty name string (written by caller). */
static void write_native_settings(native_buf_t *b, HV *defaults, HV *overrides,
                                    const char **query_id_out, STRLEN *query_id_len_out) {
    HE *entry;
    if (query_id_out) *query_id_out = NULL;
    if (query_id_len_out) *query_id_len_out = 0;

    if (overrides) {
        hv_iterinit(overrides);
        while ((entry = hv_iternext(overrides))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            char *val = SvPV(hv_iterval(overrides, entry), vlen);
            if (klen == 8 && memcmp(key, "query_id", 8) == 0) {
                if (query_id_out) {
                    *query_id_out = val;
                    *query_id_len_out = vlen;
                }
                continue;
            }
            if (is_client_only_key(key, klen)) continue;
            /* param_* keys go in the parameters block, not settings */
            if (klen > 6 && memcmp(key, "param_", 6) == 0) continue;
            nbuf_varuint(b, (uint64_t)klen);
            nbuf_append(b, key, (size_t)klen);
            nbuf_u8(b, 0);  /* is_important = 0 */
            nbuf_varuint(b, (uint64_t)vlen);
            nbuf_append(b, val, vlen);
        }
    }
    if (defaults) {
        hv_iterinit(defaults);
        while ((entry = hv_iternext(defaults))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            char *val = SvPV(hv_iterval(defaults, entry), vlen);
            if (overrides && hv_exists(overrides, key, klen))
                continue;
            if (klen == 8 && memcmp(key, "query_id", 8) == 0) {
                if (query_id_out && !*query_id_out) {
                    *query_id_out = val;
                    *query_id_len_out = vlen;
                }
                continue;
            }
            if (is_client_only_key(key, klen)) continue;
            if (klen > 6 && memcmp(key, "param_", 6) == 0) continue;
            nbuf_varuint(b, (uint64_t)klen);
            nbuf_append(b, key, (size_t)klen);
            nbuf_u8(b, 0);  /* is_important = 0 */
            nbuf_varuint(b, (uint64_t)vlen);
            nbuf_append(b, val, vlen);
        }
    }
}

/* --- Gzip compression/decompression --- */

/* Compress data with gzip. Returns malloc'd buffer, sets *out_len. NULL on error. */
static char* gzip_compress(const char *data, size_t data_len, size_t *out_len) {
    z_stream strm;
    char *out;
    size_t out_cap;
    int ret;

    if (data_len > (size_t)UINT_MAX) return NULL;

    Zero(&strm, 1, z_stream);
    ret = deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY);
    if (ret != Z_OK) return NULL;

    out_cap = deflateBound(&strm, (uLong)data_len);
    if (out_cap > (size_t)UINT_MAX) { deflateEnd(&strm); return NULL; }
    Newx(out, out_cap, char);

    strm.next_in = (Bytef *)data;
    strm.avail_in = (uInt)data_len;
    strm.next_out = (Bytef *)out;
    strm.avail_out = (uInt)out_cap;

    ret = deflate(&strm, Z_FINISH);
    if (ret != Z_STREAM_END) {
        Safefree(out);
        deflateEnd(&strm);
        return NULL;
    }

    *out_len = strm.total_out;
    deflateEnd(&strm);
    return out;
}

/* Decompress gzip data. Returns malloc'd buffer, sets *out_len. NULL on error. */
static char* gzip_decompress(const char *data, size_t data_len, size_t *out_len) {
    z_stream strm;
    char *out;
    size_t out_cap;
    int ret;

    if (data_len > (size_t)UINT_MAX) return NULL;

    Zero(&strm, 1, z_stream);
    ret = inflateInit2(&strm, 15 + 16); /* auto-detect gzip */
    if (ret != Z_OK) return NULL;

    out_cap = data_len * 4;
    if (out_cap < 4096) out_cap = 4096;
    Newx(out, out_cap, char);

    strm.next_in = (Bytef *)data;
    strm.avail_in = (uInt)data_len;

    *out_len = 0;
    do {
        if (*out_len + 4096 > out_cap) {
            out_cap *= 2;
            if (out_cap > CH_MAX_DECOMPRESS_SIZE) {
                Safefree(out);
                inflateEnd(&strm);
                return NULL;
            }
            Renew(out, out_cap, char);
        }
        strm.next_out = (Bytef *)(out + *out_len);
        strm.avail_out = (uInt)(out_cap - *out_len);

        ret = inflate(&strm, Z_NO_FLUSH);
        if (ret == Z_STREAM_ERROR || ret == Z_DATA_ERROR ||
            ret == Z_MEM_ERROR || ret == Z_BUF_ERROR) {
            Safefree(out);
            inflateEnd(&strm);
            return NULL;
        }
        *out_len = strm.total_out;
    } while (ret != Z_STREAM_END);

    inflateEnd(&strm);
    return out;
}

#ifdef HAVE_LZ4

/*
 * Decompress a ClickHouse LZ4 compressed block.
 * Input: compressed block starting at checksum (16 + 9 + payload bytes).
 * Returns malloc'd buffer with decompressed data, sets *out_len.
 * Returns NULL on error or if need more data (sets *need_more=1).
 */
static char* ch_lz4_decompress(const char *data, size_t data_len,
                                size_t *out_len, size_t *consumed,
                                int *need_more, const char **err_reason) {
    uint32_t compressed_with_header, uncompressed_size;
    uint32_t payload_size;
    uint8_t method;
    char *out;
    int ret;

    *need_more = 0;
    *consumed = 0;
    if (err_reason) *err_reason = NULL;

    /* Need at least checksum (16) + header (9) */
    if (data_len < CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE) {
        *need_more = 1;
        return NULL;
    }

    /* Read header fields (after 16-byte checksum) */
    method = (uint8_t)data[CH_CHECKSUM_SIZE];
    if (method != CH_LZ4_METHOD) {
        if (err_reason) *err_reason = "unsupported compression method";
        return NULL;
    }
    memcpy(&compressed_with_header, data + CH_CHECKSUM_SIZE + 1, 4);
    memcpy(&uncompressed_size, data + CH_CHECKSUM_SIZE + 5, 4);

    if (uncompressed_size > CH_MAX_DECOMPRESS_SIZE) {
        if (err_reason) *err_reason = "decompressed size exceeds 128 MB limit";
        return NULL;
    }

    if (compressed_with_header < CH_COMPRESS_HEADER_SIZE) {
        if (err_reason) *err_reason = "compressed_with_header too small";
        return NULL;
    }

    payload_size = compressed_with_header - CH_COMPRESS_HEADER_SIZE;

    /* Need full block */
    if (data_len < CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + payload_size) {
        *need_more = 1;
        return NULL;
    }

    /* Verify checksum */
    {
        ch_uint128_t expected, actual;
        memcpy(&expected.lo, data, 8);
        memcpy(&expected.hi, data + 8, 8);
        actual = ch_city_hash128(data + CH_CHECKSUM_SIZE, compressed_with_header);
        if (actual.lo != expected.lo || actual.hi != expected.hi) {
            if (err_reason) *err_reason = "CityHash128 checksum mismatch";
            return NULL;
        }
    }

    Newx(out, uncompressed_size, char);
    ret = LZ4_decompress_safe(data + CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE,
                              out, (int)payload_size, (int)uncompressed_size);
    if (ret < 0 || (uint32_t)ret != uncompressed_size) {
        Safefree(out);
        if (err_reason) *err_reason = "LZ4 decompression failed";
        return NULL;
    }

    *out_len = uncompressed_size;
    *consumed = CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + payload_size;
    return out;
}

/*
 * Compress data into a ClickHouse LZ4 compressed block.
 * Returns malloc'd buffer (checksum + header + LZ4 payload), sets *out_len.
 */
static char* ch_lz4_compress(const char *data, size_t data_len, size_t *out_len) {
    int max_compressed;
    if (data_len > (size_t)INT_MAX) return NULL;
    max_compressed = LZ4_compressBound((int)data_len);
    char *out;
    int compressed_size;
    uint32_t compressed_with_header;
    ch_uint128_t checksum;

    Newx(out, CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + max_compressed, char);

    compressed_size = LZ4_compress_default(
        data, out + CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE,
        (int)data_len, max_compressed);

    if (compressed_size <= 0) {
        Safefree(out);
        return NULL;
    }

    compressed_with_header = (uint32_t)compressed_size + CH_COMPRESS_HEADER_SIZE;

    /* Write header */
    out[CH_CHECKSUM_SIZE] = (char)CH_LZ4_METHOD;
    memcpy(out + CH_CHECKSUM_SIZE + 1, &compressed_with_header, 4);
    {   uint32_t uncomp = (uint32_t)data_len;
        memcpy(out + CH_CHECKSUM_SIZE + 5, &uncomp, 4);
    }

    /* Compute checksum over header + compressed data */
    checksum = ch_city_hash128(out + CH_CHECKSUM_SIZE, compressed_with_header);
    memcpy(out, &checksum.lo, 8);
    memcpy(out + 8, &checksum.hi, 8);

    *out_len = CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE + compressed_size;
    return out;
}

#endif /* HAVE_LZ4 */

/* --- Days-since-epoch calculation for Date encoding --- */

static int32_t date_string_to_days(const char *s, size_t len) {
    int year, month, day;
    if (len >= 10 && s[4] == '-' && s[7] == '-') {
        year = atoi(s);
        month = atoi(s + 5);
        day = atoi(s + 8);
        /* civil_from_days algorithm (Howard Hinnant) */
        if (month <= 2) { year--; month += 9; } else { month -= 3; }
        {
            int era = (year >= 0 ? year : year - 399) / 400;
            unsigned yoe = (unsigned)(year - era * 400);
            unsigned doy = (153 * (unsigned)month + 2) / 5 + (unsigned)day - 1;
            unsigned doe = yoe * 365 + yoe/4 - yoe/100 + doy;
            return (int32_t)(era * 146097 + (int)doe - 719468);
        }
    }
    /* fallback: numeric value */
    return (int32_t)strtol(s, NULL, 10);
}

static uint32_t datetime_string_to_epoch(const char *s, size_t len) {
    int hour = 0, min = 0, sec = 0;
    if (len >= 10 && s[4] == '-' && s[7] == '-') {
        if (len >= 19) {
            hour = atoi(s + 11);
            min = atoi(s + 14);
            sec = atoi(s + 17);
        }
        {
            int32_t days = date_string_to_days(s, 10);
            return (uint32_t)((int64_t)days * 86400 + hour * 3600 + min * 60 + sec);
        }
    }
    return (uint32_t)strtoul(s, NULL, 10);
}

/* --- TabSeparated parser --- */

/* Parse TabSeparated body into AV of AV. Handles \N -> undef, backslash escapes. */
static AV* parse_tab_separated(const char *data, size_t len) {
    AV *rows = newAV();
    const char *p = data;
    const char *end = data + len;
    const char *line_start;
    AV *row;
    char *buf;
    size_t buf_len;

    /* pre-allocate scratch buffer for unescaping */
    Newx(buf, len + 1, char);

    while (p < end) {
        /* skip trailing empty line */
        if (p + 1 == end && *p == '\n') break;

        row = newAV();
        line_start = p;

        while (p <= end) {
            int is_end_of_line = (p == end || *p == '\n');
            int is_tab = (!is_end_of_line && *p == '\t');

            if (is_end_of_line || is_tab) {
                const char *field_start = line_start;
                size_t field_len = p - field_start;

                /* check for \N (NULL) */
                if (field_len == 2 && field_start[0] == '\\' && field_start[1] == 'N') {
                    av_push(row, newSV(0));
                } else {
                    /* unescape */
                    buf_len = 0;
                    const char *s = field_start;
                    const char *s_end = field_start + field_len;
                    while (s < s_end) {
                        if (*s == '\\' && s + 1 < s_end) {
                            s++;
                            switch (*s) {
                                case 'n': buf[buf_len++] = '\n'; break;
                                case 't': buf[buf_len++] = '\t'; break;
                                case '\\': buf[buf_len++] = '\\'; break;
                                case '\'': buf[buf_len++] = '\''; break;
                                case '0': buf[buf_len++] = '\0'; break;
                                case 'a': buf[buf_len++] = '\a'; break;
                                case 'b': buf[buf_len++] = '\b'; break;
                                case 'f': buf[buf_len++] = '\f'; break;
                                case 'r': buf[buf_len++] = '\r'; break;
                                default: buf[buf_len++] = '\\'; buf[buf_len++] = *s; break;
                            }
                            s++;
                        } else {
                            buf[buf_len++] = *s++;
                        }
                    }
                    av_push(row, newSVpvn(buf, buf_len));
                }

                if (is_tab) {
                    p++;
                    line_start = p;
                } else {
                    if (p < end) p++; /* skip \n */
                    break;
                }
            } else {
                p++;
            }
        }
        av_push(rows, newRV_noinc((SV*)row));
    }

    Safefree(buf);
    return rows;
}

/* --- HTTP request building --- */

/*
 * Build HTTP POST request for a query.
 * SQL goes in body. Returns malloc'd buffer with full request.
 */
static char* build_http_query_request(ev_clickhouse_t *self, const char *sql,
                                       size_t sql_len, int do_compress,
                                       HV *defaults, HV *overrides,
                                       size_t *req_len) {
    char *req;
    size_t req_cap;
    size_t pos = 0;
    char *body = NULL;
    size_t body_len = sql_len;
    const char *content_encoding = NULL;

    /* compress body if requested */
    if (do_compress && sql_len > 0) {
        size_t gz_len;
        body = gzip_compress(sql, sql_len, &gz_len);
        if (body) {
            body_len = gz_len;
            content_encoding = "Content-Encoding: gzip\r\n";
        }
    }

    /* build URL params (dynamically allocated) */
    const char *query_id = NULL;
    STRLEN query_id_len = 0;
    size_t params_cap = 128
        + (self->database ? strlen(self->database) * 3 : 0)
        + (self->session_id ? strlen(self->session_id) * 3 : 0)
        + settings_url_params_size(defaults, overrides);
    char *params;
    size_t plen = 0;
    Newx(params, params_cap, char);
    if (self->database) {
        size_t db_len = strlen(self->database);
        char *enc_db;
        Newx(enc_db, db_len * 3 + 1, char);
        size_t enc_len = url_encode(self->database, db_len, enc_db);
        plen = (size_t)snprintf(params, params_cap, "?database=%.*s&wait_end_of_query=1",
                        (int)enc_len, enc_db);
        Safefree(enc_db);
    } else {
        plen = (size_t)snprintf(params, params_cap, "?wait_end_of_query=1");
    }
    if (self->session_id) {
        size_t sid_len = strlen(self->session_id);
        char *enc_sid;
        Newx(enc_sid, sid_len * 3 + 1, char);
        size_t enc_len = url_encode(self->session_id, sid_len, enc_sid);
        plen += (size_t)snprintf(params + plen, params_cap - plen,
                         "&session_id=%.*s", (int)enc_len, enc_sid);
        Safefree(enc_sid);
    }
    plen = append_settings_url_params(params, plen,
                                       defaults, overrides,
                                       &query_id, &query_id_len);
    if (query_id) {
        size_t need = plen + 10 + query_id_len * 3 + 1;
        if (need > params_cap) {
            params_cap = need;
            Renew(params, params_cap, char);
        }
        plen += (size_t)snprintf(params + plen, params_cap - plen, "&query_id=");
        plen += url_encode(query_id, query_id_len, params + plen);
    }
    params[plen] = '\0';

    req_cap = 512 + body_len + plen
           + (self->host ? strlen(self->host) : 0)
           + (self->user ? strlen(self->user) : 0)
           + (self->password ? strlen(self->password) : 0);
    Newx(req, req_cap, char);

    /* request line */
    pos += snprintf(req + pos, req_cap - pos,
                    "POST /%s HTTP/1.1\r\n", params);
    Safefree(params);

    /* headers */
    pos += snprintf(req + pos, req_cap - pos,
                    "Host: %s:%u\r\n", self->host, self->port);
    if (self->user) {
        pos += snprintf(req + pos, req_cap - pos,
                        "X-ClickHouse-User: %s\r\n", self->user);
    }
    if (self->password && self->password[0]) {
        pos += snprintf(req + pos, req_cap - pos,
                        "X-ClickHouse-Key: %s\r\n", self->password);
    }
    pos += snprintf(req + pos, req_cap - pos, "Connection: keep-alive\r\n");

    if (content_encoding)
        pos += snprintf(req + pos, req_cap - pos, "%s", content_encoding);

    if (self->compress)
        pos += snprintf(req + pos, req_cap - pos, "Accept-Encoding: gzip\r\n");

    pos += snprintf(req + pos, req_cap - pos,
                    "Content-Length: %lu\r\n\r\n", (unsigned long)body_len);

    /* body */
    if (body_len > 0) {
        if (pos + body_len > req_cap) {
            req_cap = pos + body_len + 1;
            Renew(req, req_cap, char);
        }
        Copy(body ? body : sql, req + pos, body_len, char);
        pos += body_len;
    }

    if (body) Safefree(body);

    *req_len = pos;
    return req;
}

/*
 * Build HTTP POST request for INSERT with data.
 * Query goes in URL param, data in body.
 */
static char* build_http_insert_request(ev_clickhouse_t *self, const char *table,
                                        size_t table_len, const char *data,
                                        size_t data_len, int do_compress,
                                        HV *defaults, HV *overrides,
                                        size_t *req_len) {
    char *req;
    size_t req_cap;
    size_t pos = 0;
    char *body = NULL;
    size_t body_len = data_len;
    const char *content_encoding = NULL;

    if (do_compress && data_len > 0) {
        size_t gz_len;
        body = gzip_compress(data, data_len, &gz_len);
        if (body) {
            body_len = gz_len;
            content_encoding = "Content-Encoding: gzip\r\n";
        }
    }

    /* build query string: INSERT INTO <table> FORMAT TabSeparated */
    size_t isql_cap = table_len + 64;
    char *insert_sql;
    Newx(insert_sql, isql_cap, char);
    int isql_len = snprintf(insert_sql, isql_cap,
                            "INSERT INTO %.*s FORMAT TabSeparated",
                            (int)table_len, table);

    const char *query_id = NULL;
    STRLEN query_id_len = 0;
    size_t params_cap = 128
        + (self->database ? strlen(self->database) * 3 : 0)
        + (self->session_id ? strlen(self->session_id) * 3 : 0)
        + (size_t)isql_len * 3
        + settings_url_params_size(defaults, overrides);
    char *params;
    size_t plen = 0;
    Newx(params, params_cap, char);
    if (self->database) {
        size_t db_len = strlen(self->database);
        char *enc_db;
        Newx(enc_db, db_len * 3 + 1, char);
        size_t enc_len = url_encode(self->database, db_len, enc_db);
        plen = (size_t)snprintf(params, params_cap, "?database=%.*s&wait_end_of_query=1",
                        (int)enc_len, enc_db);
        Safefree(enc_db);
    } else {
        plen = (size_t)snprintf(params, params_cap, "?wait_end_of_query=1");
    }
    if (self->session_id) {
        size_t sid_len = strlen(self->session_id);
        char *enc_sid;
        Newx(enc_sid, sid_len * 3 + 1, char);
        size_t enc_len = url_encode(self->session_id, sid_len, enc_sid);
        plen += (size_t)snprintf(params + plen, params_cap - plen,
                         "&session_id=%.*s", (int)enc_len, enc_sid);
        Safefree(enc_sid);
    }
    {
        char *enc_q;
        Newx(enc_q, isql_len * 3 + 1, char);
        size_t enc_len = url_encode(insert_sql, isql_len, enc_q);
        Safefree(insert_sql);
        plen += (size_t)snprintf(params + plen, params_cap - plen,
                         "&query=%.*s", (int)enc_len, enc_q);
        Safefree(enc_q);
    }
    plen = append_settings_url_params(params, plen,
                                       defaults, overrides,
                                       &query_id, &query_id_len);
    if (query_id) {
        size_t need = plen + 10 + query_id_len * 3 + 1;
        if (need > params_cap) {
            params_cap = need;
            Renew(params, params_cap, char);
        }
        plen += (size_t)snprintf(params + plen, params_cap - plen, "&query_id=");
        plen += url_encode(query_id, query_id_len, params + plen);
    }
    params[plen] = '\0';

    req_cap = 512 + body_len + plen
           + (self->host ? strlen(self->host) : 0)
           + (self->user ? strlen(self->user) : 0)
           + (self->password ? strlen(self->password) : 0);
    Newx(req, req_cap, char);

    pos += snprintf(req + pos, req_cap - pos,
                    "POST /%s HTTP/1.1\r\n", params);
    Safefree(params);
    pos += snprintf(req + pos, req_cap - pos,
                    "Host: %s:%u\r\n", self->host, self->port);
    if (self->user) {
        pos += snprintf(req + pos, req_cap - pos,
                        "X-ClickHouse-User: %s\r\n", self->user);
    }
    if (self->password && self->password[0]) {
        pos += snprintf(req + pos, req_cap - pos,
                        "X-ClickHouse-Key: %s\r\n", self->password);
    }
    pos += snprintf(req + pos, req_cap - pos, "Connection: keep-alive\r\n");

    if (do_compress)
        pos += snprintf(req + pos, req_cap - pos, "Accept-Encoding: gzip\r\n");

    if (content_encoding)
        pos += snprintf(req + pos, req_cap - pos, "%s", content_encoding);

    pos += snprintf(req + pos, req_cap - pos,
                    "Content-Length: %lu\r\n\r\n", (unsigned long)body_len);

    if (body_len > 0) {
        if (pos + body_len > req_cap) {
            req_cap = pos + body_len + 1;
            Renew(req, req_cap, char);
        }
        Copy(body ? body : data, req + pos, body_len, char);
        pos += body_len;
    }

    if (body) Safefree(body);

    *req_len = pos;
    return req;
}

/* Build HTTP GET /ping request */
static char* build_http_ping_request(ev_clickhouse_t *self, size_t *req_len) {
    char *req;
    size_t req_cap = 128 + (self->host ? strlen(self->host) : 0);
    size_t pos = 0;

    Newx(req, req_cap, char);
    pos = snprintf(req, req_cap,
                   "GET /ping HTTP/1.1\r\n"
                   "Host: %s:%u\r\n"
                   "Connection: keep-alive\r\n\r\n",
                   self->host, self->port);
    if (pos >= req_cap) pos = req_cap - 1;
    *req_len = pos;
    return req;
}

/* --- HTTP response parsing --- */

/* Find \r\n\r\n in recv_buf. Returns offset past it, or 0 if not found. */
static size_t find_header_end(const char *buf, size_t len) {
    size_t i;
    if (len < 4) return 0;
    for (i = 0; i <= len - 4; i++) {
        if (buf[i] == '\r' && buf[i+1] == '\n' &&
            buf[i+2] == '\r' && buf[i+3] == '\n') {
            return i + 4;
        }
    }
    return 0;
}

/* Extract ClickHouse error code from HTTP error body ("Code: NNN. ...") */
static int32_t parse_ch_error_code(const char *body, size_t len) {
    if (len > 6 && memcmp(body, "Code: ", 6) == 0)
        return (int32_t)atoi(body + 6);
    return 0;
}

/* Parse HTTP status line, extract status code */
static int parse_http_status(const char *buf, size_t len) {
    /* HTTP/1.1 200 OK\r\n */
    const char *p = buf;
    const char *end = buf + len;
    int status;

    /* skip "HTTP/1.x " */
    while (p < end && *p != ' ') p++;
    if (p >= end) return 0;
    p++;

    status = atoi(p);
    if (status < 100 || status > 599) return 500; /* treat malformed as server error */
    return status;
}

/* Find header value (case-insensitive). Returns pointer into buf or NULL. */
static const char* find_header(const char *headers, size_t headers_len,
                                const char *name, size_t *value_len) {
    size_t name_len = strlen(name);
    const char *p = headers;
    const char *end = headers + headers_len;

    while (p < end) {
        const char *line_end = p;
        while (line_end < end && *line_end != '\r') line_end++;

        if ((size_t)(line_end - p) > name_len + 1 && p[name_len] == ':') {
            int match = 1;
            size_t i;
            for (i = 0; i < name_len; i++) {
                if (tolower((unsigned char)p[i]) != tolower((unsigned char)name[i])) {
                    match = 0;
                    break;
                }
            }
            if (match) {
                const char *val = p + name_len + 1;
                while (val < line_end && *val == ' ') val++;
                *value_len = line_end - val;
                return val;
            }
        }

        /* advance past \r\n */
        if (line_end + 2 <= end) p = line_end + 2;
        else break;
    }
    return NULL;
}

/* Parse a complete HTTP response from recv_buf. */
static void process_http_response(ev_clickhouse_t *self) {
    size_t hdr_end;
    int status;
    const char *val;
    size_t val_len;
    size_t content_length = 0;
    int chunked = 0;
    int is_gzip = 0;
    const char *body;
    size_t body_len;
    char *decoded = NULL;
    size_t decoded_len = 0;
    size_t decoded_cap = 0;

    if (self->recv_len == 0 || self->send_count == 0) return;

    /* find headers end */
    hdr_end = find_header_end(self->recv_buf, self->recv_len);
    if (hdr_end == 0) return; /* need more data */

    /* parse status */
    status = parse_http_status(self->recv_buf, hdr_end);

    /* parse Content-Length */
    val = find_header(self->recv_buf, hdr_end, "Content-Length", &val_len);
    if (val) {
        content_length = (size_t)strtoul(val, NULL, 10);
    }

    /* check Transfer-Encoding: chunked */
    val = find_header(self->recv_buf, hdr_end, "Transfer-Encoding", &val_len);
    if (val && val_len >= 7 && strncasecmp(val, "chunked", 7) == 0) {
        chunked = 1;
    }

    /* check Content-Encoding: gzip */
    val = find_header(self->recv_buf, hdr_end, "Content-Encoding", &val_len);
    if (val && val_len >= 4 && strncasecmp(val, "gzip", 4) == 0) {
        is_gzip = 1;
    }

    if (chunked) {
        /* decode chunked transfer encoding */
        const char *cp = self->recv_buf + hdr_end;
        const char *cp_end = self->recv_buf + self->recv_len;

        {
            int chunked_complete = 0;
            while (cp < cp_end) {
                /* read chunk size */
                const char *nl = cp;
                unsigned long chunk_size;
                while (nl < cp_end && *nl != '\r') nl++;
                if (nl + 2 > cp_end) goto need_more; /* need more data */

                chunk_size = strtoul(cp, NULL, 16);
                cp = nl + 2; /* skip \r\n */

                if (chunk_size == 0) {
                    /* terminal chunk; skip trailing \r\n */
                    if (cp + 2 > cp_end) goto need_more;
                    cp += 2;
                    chunked_complete = 1;
                    break;
                }

                if ((size_t)(cp_end - cp) < 2
                    || chunk_size > (size_t)(cp_end - cp) - 2) goto need_more;

                /* guard against overflow and unbounded growth —
                 * close connection since remaining chunks would
                 * corrupt the stream for subsequent requests */
                if (decoded_len + chunk_size < decoded_len
                    || decoded_len + chunk_size > CH_MAX_DECOMPRESS_SIZE) {
                    if (decoded) Safefree(decoded);
                    self->send_count--;
                    int destroyed = deliver_error(self, "chunked response too large");
                    if (destroyed) return;
                    if (cancel_pending(self, "connection closed")) return;
                    cleanup_connection(self);
                    return;
                }
                if (decoded == NULL) {
                    decoded_cap = chunk_size + 256;
                    Newx(decoded, decoded_cap, char);
                } else if (decoded_len + chunk_size > decoded_cap) {
                    decoded_cap = (decoded_len + chunk_size) * 2;
                    Renew(decoded, decoded_cap, char);
                }
                Copy(cp, decoded + decoded_len, chunk_size, char);
                decoded_len += chunk_size;
                cp += chunk_size + 2; /* skip chunk data + \r\n */
            }

            if (!chunked_complete) goto need_more;
        }

        body = decoded;
        body_len = decoded_len;

        /* deliver response */
        self->send_count--;
        if (status == 200) {
            char *final_body = (char *)body;
            size_t final_len = body_len;

            if (is_gzip && body_len > 0) {
                size_t dec_len;
                char *dec = gzip_decompress(body, body_len, &dec_len);
                if (dec) {
                    final_body = dec;
                    final_len = dec_len;
                } else {
                    if (decoded) Safefree(decoded);
                    size_t consumed = cp - self->recv_buf;
                    if (consumed < self->recv_len)
                        memmove(self->recv_buf, self->recv_buf + consumed,
                                self->recv_len - consumed);
                    self->recv_len -= consumed;
                    int destroyed = deliver_error(self, "gzip decompression failed");
                    if (destroyed) return;
                    goto done;
                }
            }

            {
            int is_raw = peek_cb_raw(self);
            size_t consumed = cp - self->recv_buf;

            if (is_raw) {
                /* raw mode — deliver body as scalar, skip TSV parsing */
                int destroyed = deliver_raw_body(self, final_body, final_len);
                if (final_body != body) Safefree(final_body);
                if (decoded) Safefree(decoded);
                if (consumed < self->recv_len)
                    memmove(self->recv_buf, self->recv_buf + consumed,
                            self->recv_len - consumed);
                self->recv_len -= consumed;
                if (destroyed) return;
            } else {
                AV *rows = NULL;
                if (final_len > 0)
                    rows = parse_tab_separated(final_body, final_len);
                if (final_body != body) Safefree(final_body);
                if (decoded) Safefree(decoded);
                if (consumed < self->recv_len)
                    memmove(self->recv_buf, self->recv_buf + consumed,
                            self->recv_len - consumed);
                self->recv_len -= consumed;
                if (deliver_rows(self, rows)) return;
            }
            }
        } else {
            /* error */
            char *errmsg;
            char *err_body = (char *)body;
            size_t err_len = body_len;

            if (is_gzip && body_len > 0) {
                size_t dec_len;
                char *dec = gzip_decompress(body, body_len, &dec_len);
                if (dec) {
                    err_body = dec;
                    err_len = dec_len;
                }
            }

            while (err_len > 0 && (err_body[err_len-1] == '\n' || err_body[err_len-1] == '\r'))
                err_len--;
            self->last_error_code = parse_ch_error_code(err_body, err_len);
            Newx(errmsg, err_len + 64, char);
            snprintf(errmsg, err_len + 64, "HTTP %d: %.*s",
                     status, (int)err_len, err_body);
            if (err_body != body) Safefree(err_body);
            if (decoded) Safefree(decoded);

            size_t consumed = cp - self->recv_buf;
            if (consumed < self->recv_len) {
                memmove(self->recv_buf, self->recv_buf + consumed,
                        self->recv_len - consumed);
            }
            self->recv_len -= consumed;

            int destroyed = deliver_error(self, errmsg);
            Safefree(errmsg);
            if (destroyed) return;
        }
    } else {
        /* Content-Length based */
        if (self->recv_len < hdr_end + content_length) return; /* need more data */

        body = self->recv_buf + hdr_end;
        body_len = content_length;

        self->send_count--;
        if (status == 200) {
            char *final_body = (char *)body;
            size_t final_len = body_len;

            if (is_gzip && body_len > 0) {
                size_t dec_len;
                char *dec = gzip_decompress(body, body_len, &dec_len);
                if (dec) {
                    final_body = dec;
                    final_len = dec_len;
                } else {
                    size_t consumed = hdr_end + content_length;
                    if (consumed < self->recv_len)
                        memmove(self->recv_buf, self->recv_buf + consumed,
                                self->recv_len - consumed);
                    self->recv_len -= consumed;
                    int destroyed = deliver_error(self, "gzip decompression failed");
                    if (destroyed) return;
                    goto done;
                }
            }

            {
            int is_raw = peek_cb_raw(self);
            size_t consumed = hdr_end + content_length;

            if (is_raw) {
                int destroyed = deliver_raw_body(self, final_body, final_len);
                if (final_body != body) Safefree(final_body);
                if (consumed < self->recv_len)
                    memmove(self->recv_buf, self->recv_buf + consumed,
                            self->recv_len - consumed);
                self->recv_len -= consumed;
                if (destroyed) return;
            } else {
                AV *rows = NULL;
                if (final_len > 0)
                    rows = parse_tab_separated(final_body, final_len);
                if (final_body != body) Safefree(final_body);
                if (consumed < self->recv_len)
                    memmove(self->recv_buf, self->recv_buf + consumed,
                            self->recv_len - consumed);
                self->recv_len -= consumed;
                if (deliver_rows(self, rows)) return;
            }
            }
        } else {
            char *errmsg;
            char *err_body = (char *)body;
            size_t err_len = body_len;

            if (is_gzip && body_len > 0) {
                size_t dec_len;
                char *dec = gzip_decompress(body, body_len, &dec_len);
                if (dec) {
                    err_body = dec;
                    err_len = dec_len;
                }
            }

            while (err_len > 0 && (err_body[err_len-1] == '\n' || err_body[err_len-1] == '\r'))
                err_len--;
            self->last_error_code = parse_ch_error_code(err_body, err_len);
            Newx(errmsg, err_len + 64, char);
            snprintf(errmsg, err_len + 64, "HTTP %d: %.*s",
                     status, (int)err_len, err_body);

            if (err_body != body) Safefree(err_body);

            size_t consumed = hdr_end + content_length;
            if (consumed < self->recv_len) {
                memmove(self->recv_buf, self->recv_buf + consumed,
                        self->recv_len - consumed);
            }
            self->recv_len -= consumed;

            int destroyed = deliver_error(self, errmsg);
            Safefree(errmsg);
            if (destroyed) return;
        }
    }

    if (self->magic != EV_CH_MAGIC) return;

done:
    /* Stop query timeout timer on response */
    if (self->timing) {
        ev_timer_stop(self->loop, &self->timer);
        self->timing = 0;
    }
    pipeline_advance(self);
    return;

need_more:
    /* incomplete response — keep reading */
    if (decoded) Safefree(decoded);
    return;
}

/* --- Native protocol packet builders --- */

static char* build_native_hello(ev_clickhouse_t *self, size_t *out_len) {
    native_buf_t b;
    nbuf_init(&b);

    nbuf_varuint(&b, CLIENT_HELLO);
    nbuf_cstring(&b, CH_CLIENT_NAME);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MAJOR);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MINOR);
    nbuf_varuint(&b, CH_CLIENT_REVISION);
    nbuf_cstring(&b, self->database ? self->database : "default");
    nbuf_cstring(&b, self->user ? self->user : "default");
    nbuf_cstring(&b, self->password ? self->password : "");

    *out_len = b.len;
    return b.data;
}

static char* build_native_ping(size_t *out_len) {
    native_buf_t b;
    nbuf_init(&b);
    nbuf_varuint(&b, CLIENT_PING);
    *out_len = b.len;
    return b.data;
}

/* Build an empty Data block (signals end of client data after Query) */
static void nbuf_empty_data_block(native_buf_t *b, int do_compress) {
    nbuf_varuint(b, CLIENT_DATA);
    nbuf_cstring(b, "");   /* table name — outside compression */

    /* block body: block info + num_cols + num_rows */
#ifdef HAVE_LZ4
    if (do_compress) {
        native_buf_t body;
        char *compressed;
        size_t comp_len;

        nbuf_init(&body);
        nbuf_varuint(&body, 1);    /* field_num = 1 */
        nbuf_u8(&body, 0);         /* is_overflows = false */
        nbuf_varuint(&body, 2);    /* field_num = 2 */
        {
            int32_t bucket = -1;
            nbuf_append(&body, (const char *)&bucket, 4);
        }
        nbuf_varuint(&body, 0);    /* end of block info */
        nbuf_varuint(&body, 0);    /* num_columns = 0 */
        nbuf_varuint(&body, 0);    /* num_rows = 0 */

        compressed = ch_lz4_compress(body.data, body.len, &comp_len);
        Safefree(body.data);
        if (compressed) {
            nbuf_append(b, compressed, comp_len);
            Safefree(compressed);
            return;
        }
        /* LZ4 failed (should never happen) — fall through to uncompressed */
    }
#else
    (void)do_compress;
#endif

    /* block info (revision >= DBMS_MIN_REVISION_WITH_BLOCK_INFO) */
    nbuf_varuint(b, 1);    /* field_num = 1 */
    nbuf_u8(b, 0);         /* is_overflows = false */
    nbuf_varuint(b, 2);    /* field_num = 2 */
    {
        int32_t bucket = -1;
        nbuf_append(b, (const char *)&bucket, 4); /* bucket_num = -1 */
    }
    nbuf_varuint(b, 0);    /* end of block info */
    nbuf_varuint(b, 0);    /* num_columns = 0 */
    nbuf_varuint(b, 0);    /* num_rows = 0 */
}

static char* build_native_query(ev_clickhouse_t *self, const char *sql,
                                 size_t sql_len, HV *defaults,
                                 HV *overrides, size_t *out_len) {
    native_buf_t b;
    const char *query_id = NULL;
    STRLEN query_id_len = 0;
    nbuf_init(&b);

    /* Pre-scan settings for query_id (needed before settings block) */
    {
        SV **svp;
        if (overrides && (svp = hv_fetch(overrides, "query_id", 8, 0)))
            query_id = SvPV(*svp, query_id_len);
        else if (defaults && (svp = hv_fetch(defaults, "query_id", 8, 0)))
            query_id = SvPV(*svp, query_id_len);
    }

    /* Query packet */
    nbuf_varuint(&b, CLIENT_QUERY);
    if (query_id) {
        nbuf_varuint(&b, (uint64_t)query_id_len);
        nbuf_append(&b, query_id, query_id_len);
    } else {
        nbuf_cstring(&b, "");  /* query_id (empty = auto) */
    }

    /* Client info — field order must match ClientInfo::read() */
    nbuf_u8(&b, QUERY_INITIAL);
    nbuf_cstring(&b, "");  /* initial_user */
    nbuf_cstring(&b, "");  /* initial_query_id */
    nbuf_cstring(&b, "[::ffff:127.0.0.1]:0"); /* initial_address */

    /* initial_query_start_time_microseconds (revision >= 54449) */
    {
        uint64_t zero64 = 0;
        nbuf_append(&b, (const char *)&zero64, 8);
    }

    /* iface_type: 1=TCP, os_user, client_hostname, client_name */
    nbuf_u8(&b, 1);
    nbuf_cstring(&b, "");  /* os_user */
    nbuf_cstring(&b, "");  /* client_hostname */
    nbuf_cstring(&b, CH_CLIENT_NAME);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MAJOR);
    nbuf_varuint(&b, CH_CLIENT_VERSION_MINOR);
    nbuf_varuint(&b, CH_CLIENT_REVISION);

    /* quota_key_in_client_info (always present, revision >= ~54060) */
    nbuf_cstring(&b, "");

    /* distributed_depth (revision >= 54448) */
    nbuf_varuint(&b, 0);

    /* version_patch (revision >= 54401) */
    nbuf_varuint(&b, 0);

    /* OpenTelemetry trace context (revision >= 54442): no trace */
    nbuf_u8(&b, 0);

    /* parallel_replicas (revision >= 54453) */
    nbuf_varuint(&b, 0);  /* collaborate_with_initiator */
    nbuf_varuint(&b, 0);  /* count_participating_replicas */
    nbuf_varuint(&b, 0);  /* number_of_current_replica */

    /* Settings (serialized as strings: revision >= 54429)
     * Format: repeated (String name, UInt8 is_important, String value),
     * terminated by empty name. */
    write_native_settings(&b, defaults, overrides, NULL, NULL);
    nbuf_cstring(&b, "");  /* empty name = end of settings */

    /* interserver_secret: empty string (revision >= 54441) */
    nbuf_cstring(&b, "");

    /* state (stage), compression, query */
    nbuf_varuint(&b, STAGE_COMPLETE);
#ifdef HAVE_LZ4
    nbuf_varuint(&b, self->compress ? 1 : 0);
#else
    nbuf_varuint(&b, 0);
#endif
    nbuf_string(&b, sql, sql_len);

    /* Parameters block (revision >= 54459):
     * Format: repeated (String name, VarUInt flags, String value),
     * terminated by empty name.  Values are wrapped in single quotes
     * (ClickHouse Field::dump format for strings — the server uses
     * Field::restoreFromDump to parse them). */
    if (overrides) {
        HE *pe;
        hv_iterinit(overrides);
        while ((pe = hv_iternext(overrides))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(pe, &klen);
            char *val = SvPV(hv_iterval(overrides, pe), vlen);
            if (klen > 6 && memcmp(key, "param_", 6) == 0) {
                /* strip param_ prefix: native protocol uses bare names */
                nbuf_varuint(&b, (uint64_t)(klen - 6));
                nbuf_append(&b, key + 6, (size_t)(klen - 6));
                nbuf_varuint(&b, 2);  /* flags: CUSTOM = 0x02 */
                /* value: wrap in single quotes for Field::dump format */
                nbuf_varuint(&b, (uint64_t)(vlen + 2));
                nbuf_append(&b, "'", 1);
                nbuf_append(&b, val, vlen);
                nbuf_append(&b, "'", 1);
            }
        }
    }
    if (defaults) {
        HE *pe;
        hv_iterinit(defaults);
        while ((pe = hv_iternext(defaults))) {
            I32 klen;
            char *key = hv_iterkey(pe, &klen);
            if (klen > 6 && memcmp(key, "param_", 6) == 0) {
                if (overrides && hv_exists(overrides, key, klen))
                    continue;
                STRLEN vlen;
                char *val = SvPV(hv_iterval(defaults, pe), vlen);
                /* strip param_ prefix: native protocol uses bare names */
                nbuf_varuint(&b, (uint64_t)(klen - 6));
                nbuf_append(&b, key + 6, (size_t)(klen - 6));
                nbuf_varuint(&b, 2);  /* flags: CUSTOM = 0x02 */
                nbuf_varuint(&b, (uint64_t)(vlen + 2));
                nbuf_append(&b, "'", 1);
                nbuf_append(&b, val, vlen);
                nbuf_append(&b, "'", 1);
            }
        }
    }
    nbuf_cstring(&b, "");  /* empty name = end of parameters */

    /* Append empty Data block */
    nbuf_empty_data_block(&b, self->compress);

    *out_len = b.len;
    return b.data;
}

/* --- Native protocol column decoder --- */

/* Column type codes for decoding. */
enum {
    CT_INT8, CT_INT16, CT_INT32, CT_INT64,
    CT_UINT8, CT_UINT16, CT_UINT32, CT_UINT64,
    CT_FLOAT32, CT_FLOAT64,
    CT_STRING, CT_FIXEDSTRING,
    CT_ARRAY, CT_NULLABLE,
    CT_DATE, CT_DATE32, CT_DATETIME, CT_DATETIME64,
    CT_UUID, CT_ENUM8, CT_ENUM16,
    CT_DECIMAL32, CT_DECIMAL64, CT_DECIMAL128,
    CT_LOWCARDINALITY, CT_NOTHING,
    CT_BOOL, CT_IPV4, CT_IPV6,
    CT_INT128, CT_UINT128,
    CT_INT256, CT_UINT256,
    CT_TUPLE, CT_MAP,
    CT_UNKNOWN
};

typedef struct col_type_s col_type_t;
struct col_type_s {
    int code;
    int param;            /* FixedString(N), DateTime64 precision, Decimal scale */
    col_type_t *inner;    /* Nullable, Array, LowCardinality */
    col_type_t **inners;  /* Tuple elements, Map key+value */
    int num_inners;
    char *type_str;       /* full type string (for Enum label lookup) */
    size_t type_str_len;
    char *tz;             /* timezone for DateTime/DateTime64 (NULL = UTC) */
};

static void free_col_type(col_type_t *t) {
    int i;
    if (!t) return;
    if (t->inner) free_col_type(t->inner);
    if (t->inners) {
        for (i = 0; i < t->num_inners; i++)
            free_col_type(t->inners[i]);
        Safefree(t->inners);
    }
    if (t->type_str) Safefree(t->type_str);
    if (t->tz) Safefree(t->tz);
    Safefree(t);
}

/* Forward declaration */
static col_type_t* parse_col_type(const char *type, size_t len);

/*
 * Parse comma-separated type list inside Tuple(...) or Map(...).
 * Handles nested parentheses correctly.
 * Sets t->inners and t->num_inners.
 */
static void parse_type_list(col_type_t *t, const char *inner, size_t inner_len) {
    int depth = 0, count = 0;
    size_t i, start = 0;

    /* Count elements */
    for (i = 0; i <= inner_len; i++) {
        if (i < inner_len && inner[i] == '(') depth++;
        else if (i < inner_len && inner[i] == ')') depth--;
        else if (i == inner_len || (inner[i] == ',' && depth == 0))
            count++;
    }

    Newxz(t->inners, count, col_type_t*);
    t->num_inners = count;

    /* Parse each element */
    count = 0;
    depth = 0;
    start = 0;
    for (i = 0; i <= inner_len; i++) {
        if (i < inner_len && inner[i] == '(') depth++;
        else if (i < inner_len && inner[i] == ')') depth--;
        else if (i == inner_len || (inner[i] == ',' && depth == 0)) {
            size_t s = start, e = i;
            while (s < e && inner[s] == ' ') s++;
            while (e > s && inner[e-1] == ' ') e--;
            /* Strip named tuple field prefix: "name Type" -> "Type" */
            {
                size_t sp;
                for (sp = s; sp < e; sp++) {
                    if (inner[sp] == '(') break; /* type with parens, stop */
                    if (inner[sp] == ' ') { s = sp + 1; break; }
                }
            }
            t->inners[count++] = parse_col_type(inner + s, e - s);
            start = i + 1;
        }
    }
}

static col_type_t* parse_col_type(const char *type, size_t len) {
    col_type_t *t;
    Newxz(t, 1, col_type_t);

    if (len == 4 && memcmp(type, "Int8", 4) == 0)          t->code = CT_INT8;
    else if (len == 5 && memcmp(type, "Int16", 5) == 0)     t->code = CT_INT16;
    else if (len == 5 && memcmp(type, "Int32", 5) == 0)     t->code = CT_INT32;
    else if (len == 5 && memcmp(type, "Int64", 5) == 0)     t->code = CT_INT64;
    else if (len == 5 && memcmp(type, "UInt8", 5) == 0)     t->code = CT_UINT8;
    else if (len == 6 && memcmp(type, "UInt16", 6) == 0)    t->code = CT_UINT16;
    else if (len == 6 && memcmp(type, "UInt32", 6) == 0)    t->code = CT_UINT32;
    else if (len == 6 && memcmp(type, "UInt64", 6) == 0)    t->code = CT_UINT64;
    else if (len == 7 && memcmp(type, "Float32", 7) == 0)   t->code = CT_FLOAT32;
    else if (len == 7 && memcmp(type, "Float64", 7) == 0)   t->code = CT_FLOAT64;
    else if (len == 6 && memcmp(type, "String", 6) == 0)    t->code = CT_STRING;
    else if (len > 12 && memcmp(type, "FixedString(", 12) == 0) {
        t->code = CT_FIXEDSTRING;
        t->param = atoi(type + 12);
    }
    else if (len > 6 && memcmp(type, "Array(", 6) == 0) {
        t->code = CT_ARRAY;
        t->inner = parse_col_type(type + 6, len - 7);
    }
    else if (len > 9 && memcmp(type, "Nullable(", 9) == 0) {
        t->code = CT_NULLABLE;
        t->inner = parse_col_type(type + 9, len - 10);
    }
    else if (len > 15 && memcmp(type, "LowCardinality(", 15) == 0) {
        t->code = CT_LOWCARDINALITY;
        t->inner = parse_col_type(type + 15, len - 16);
    }
    else if (len == 4 && memcmp(type, "Date", 4) == 0)      t->code = CT_DATE;
    else if (len == 6 && memcmp(type, "Date32", 6) == 0)    t->code = CT_DATE32;
    else if (len == 8 && memcmp(type, "DateTime", 8) == 0)  t->code = CT_DATETIME;
    else if (len > 9 && memcmp(type, "DateTime(", 9) == 0) {
        t->code = CT_DATETIME;
        /* DateTime('timezone') — extract timezone */
        {
            const char *q = memchr(type + 9, '\'', len - 9);
            if (q) {
                const char *qe = memchr(q + 1, '\'', type + len - q - 1);
                if (qe && qe > q + 1) {
                    size_t tzlen = qe - q - 1;
                    Newx(t->tz, tzlen + 1, char);
                    Copy(q + 1, t->tz, tzlen, char);
                    t->tz[tzlen] = '\0';
                }
            }
        }
    }
    else if (len > 11 && memcmp(type, "DateTime64(", 11) == 0) {
        t->code = CT_DATETIME64;
        t->param = atoi(type + 11);
        /* DateTime64(N, 'timezone') — extract timezone */
        {
            const char *comma = memchr(type + 11, ',', len - 11);
            if (comma) {
                const char *q = memchr(comma, '\'', type + len - comma);
                if (q) {
                    const char *qe = memchr(q + 1, '\'', type + len - q - 1);
                    if (qe && qe > q + 1) {
                        size_t tzlen = qe - q - 1;
                        Newx(t->tz, tzlen + 1, char);
                        Copy(q + 1, t->tz, tzlen, char);
                        t->tz[tzlen] = '\0';
                    }
                }
            }
        }
    }
    else if (len == 4 && memcmp(type, "UUID", 4) == 0)      t->code = CT_UUID;
    else if (len > 6 && memcmp(type, "Enum8(", 6) == 0) {
        t->code = CT_ENUM8;
        Newx(t->type_str, len + 1, char);
        Copy(type, t->type_str, len, char);
        t->type_str[len] = '\0';
        t->type_str_len = len;
    }
    else if (len > 7 && memcmp(type, "Enum16(", 7) == 0) {
        t->code = CT_ENUM16;
        Newx(t->type_str, len + 1, char);
        Copy(type, t->type_str, len, char);
        t->type_str[len] = '\0';
        t->type_str_len = len;
    }
    else if (len > 10 && memcmp(type, "Decimal32(", 10) == 0) {
        t->code = CT_DECIMAL32;
        t->param = atoi(type + 10);
    }
    else if (len > 10 && memcmp(type, "Decimal64(", 10) == 0) {
        t->code = CT_DECIMAL64;
        t->param = atoi(type + 10);
    }
    else if (len > 11 && memcmp(type, "Decimal128(", 11) == 0) {
        t->code = CT_DECIMAL128;
        t->param = atoi(type + 11);
    }
    else if (len > 8 && memcmp(type, "Decimal(", 8) == 0) {
        int precision = atoi(type + 8);
        const char *comma = memchr(type + 8, ',', len - 8);
        t->param = comma ? atoi(comma + 1) : 0;
        if (precision <= 9) t->code = CT_DECIMAL32;
        else if (precision <= 18) t->code = CT_DECIMAL64;
        else t->code = CT_DECIMAL128;
    }
    else if (len == 7 && memcmp(type, "Nothing", 7) == 0) t->code = CT_NOTHING;
    else if (len == 4 && memcmp(type, "Bool", 4) == 0)   t->code = CT_BOOL;
    else if (len == 4 && memcmp(type, "IPv4", 4) == 0)    t->code = CT_IPV4;
    else if (len == 4 && memcmp(type, "IPv6", 4) == 0)    t->code = CT_IPV6;
    else if (len == 6 && memcmp(type, "Int128", 6) == 0)  t->code = CT_INT128;
    else if (len == 7 && memcmp(type, "UInt128", 7) == 0) t->code = CT_UINT128;
    else if (len == 6 && memcmp(type, "Int256", 6) == 0)  t->code = CT_INT256;
    else if (len == 7 && memcmp(type, "UInt256", 7) == 0) t->code = CT_UINT256;
    else if (len > 6 && memcmp(type, "Tuple(", 6) == 0) {
        t->code = CT_TUPLE;
        parse_type_list(t, type + 6, len - 7);
    }
    else if (len > 4 && memcmp(type, "Map(", 4) == 0) {
        t->code = CT_MAP;
        parse_type_list(t, type + 4, len - 5);
    }
    else if (len > 7 && memcmp(type, "Nested(", 7) == 0) {
        /* Nested(name1 Type1, name2 Type2) = Array(Tuple(Type1, Type2)) */
        col_type_t *tuple;
        Newxz(tuple, 1, col_type_t);
        tuple->code = CT_TUPLE;
        parse_type_list(tuple, type + 7, len - 8);
        t->code = CT_ARRAY;
        t->inner = tuple;
    }
    else if (len > 25 && memcmp(type, "SimpleAggregateFunction(", 24) == 0) {
        /* SimpleAggregateFunction(func, Type...) — skip func, parse inner type(s) */
        const char *inner = type + 24;
        size_t inner_len = len - 25;
        /* Find first comma at depth 0 — that separates func from type */
        size_t ci;
        int depth = 0;
        for (ci = 0; ci < inner_len; ci++) {
            if (inner[ci] == '(') depth++;
            else if (inner[ci] == ')') depth--;
            else if (inner[ci] == ',' && depth == 0) break;
        }
        if (ci < inner_len) {
            /* Skip comma and whitespace */
            ci++;
            while (ci < inner_len && inner[ci] == ' ') ci++;
            Safefree(t);
            t = parse_col_type(inner + ci, inner_len - ci);
        } else {
            t->code = CT_UNKNOWN;
        }
    }
    else {
        /* Unknown type — treat as String (read raw bytes) */
        t->code = CT_UNKNOWN;
    }

    return t;
}

/* Size in bytes for fixed-width types. Returns 0 for variable-width. */
static size_t col_type_fixed_size(col_type_t *t) {
    switch (t->code) {
        case CT_INT8:  case CT_UINT8:  case CT_ENUM8:  case CT_BOOL: return 1;
        case CT_INT16: case CT_UINT16: case CT_ENUM16: case CT_DATE: return 2;
        case CT_INT32: case CT_UINT32: case CT_FLOAT32:
        case CT_DECIMAL32: case CT_DATE32: case CT_DATETIME:
        case CT_IPV4: return 4;
        case CT_INT64: case CT_UINT64: case CT_FLOAT64:
        case CT_DECIMAL64: case CT_DATETIME64: return 8;
        case CT_UUID: case CT_DECIMAL128:
        case CT_INT128: case CT_UINT128: case CT_IPV6: return 16;
        case CT_INT256: case CT_UINT256: return 32;
        case CT_FIXEDSTRING: return (size_t)t->param;
        default: return 0;
    }
}

/* --- Decode helper functions for opt-in type formatting --- */

/* Convert days since Unix epoch to "YYYY-MM-DD" */
static SV* days_to_date_sv(int32_t days) {
    time_t t = (time_t)days * 86400;
    struct tm tm;
    char buf[11];
    if (!gmtime_r(&t, &tm)) return newSVpvn("0000-00-00", 10);
    snprintf(buf, sizeof(buf), "%04d-%02d-%02d",
             tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday);
    return newSVpvn(buf, 10);
}

/* Convert epoch seconds to "YYYY-MM-DD HH:MM:SS", tz-aware */
static SV* epoch_to_datetime_sv(uint32_t epoch) {
    time_t t = (time_t)epoch;
    struct tm tm;
    char buf[20];
    if (!gmtime_r(&t, &tm)) return newSVpvn("0000-00-00 00:00:00", 19);
    snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d",
             tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
             tm.tm_hour, tm.tm_min, tm.tm_sec);
    return newSVpvn(buf, 19);
}

/* Like epoch_to_datetime_sv but uses localtime_r (TZ must already be set by caller) */
static SV* epoch_to_datetime_sv_local(uint32_t epoch) {
    time_t t = (time_t)epoch;
    struct tm tm;
    char buf[20];
    if (!localtime_r(&t, &tm)) return newSVpvn("0000-00-00 00:00:00", 19);
    snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d",
             tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
             tm.tm_hour, tm.tm_min, tm.tm_sec);
    return newSVpvn(buf, 19);
}

/* Convert DateTime64 to "YYYY-MM-DD HH:MM:SS.fff...", use_local=1 for localtime */
static SV* dt64_to_datetime_sv_ex(int64_t val, int precision, int use_local) {
    int64_t scale = 1;
    int p;
    int64_t epoch, frac;
    time_t t;
    struct tm tm;
    char buf[32];
    int n;

    for (p = 0; p < precision; p++) scale *= 10;
    epoch = val / scale;
    frac = val % scale;
    if (frac < 0) { epoch--; frac += scale; }

    t = (time_t)epoch;
    if (use_local) {
        if (!localtime_r(&t, &tm)) return newSVpvn("0000-00-00 00:00:00", 19);
    } else {
        if (!gmtime_r(&t, &tm)) return newSVpvn("0000-00-00 00:00:00", 19);
    }
    n = snprintf(buf, sizeof(buf), "%04d-%02d-%02d %02d:%02d:%02d",
                 tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
                 tm.tm_hour, tm.tm_min, tm.tm_sec);
    if (precision > 0 && n < 30) {
        char fracbuf[16];
        int fi;
        snprintf(fracbuf, sizeof(fracbuf), "%0*lld", precision, (long long)frac);
        buf[n++] = '.';
        for (fi = 0; fi < precision && n < 31; fi++)
            buf[n++] = fracbuf[fi];
    }
    return newSVpvn(buf, n);
}


/* Set TZ environment variable and call tzset(); returns saved old TZ (caller must free) */
static char* set_tz(const char *tz) {
    char *old_tz = getenv("TZ");
    char *saved = NULL;
    if (old_tz) {
        size_t l = strlen(old_tz);
        Newx(saved, l + 1, char);
        Copy(old_tz, saved, l + 1, char);
    }
    setenv("TZ", tz, 1);
    tzset();
    return saved;
}

/* Restore TZ from saved value (which may be NULL), then free saved */
static void restore_tz(char *saved) {
    if (saved) {
        setenv("TZ", saved, 1);
        Safefree(saved);
    } else {
        unsetenv("TZ");
    }
    tzset();
}

/* Compute 10^n as double */
static double pow10_int(int n) {
    double r = 1.0;
    int i;
    for (i = 0; i < n; i++) r *= 10.0;
    return r;
}

/* Parse enum label for a given code from type string like "Enum8('a'=1,'b'=2)" */
static SV* enum_label_for_code(const char *type_str, size_t type_str_len, int code) {
    /* Find the opening '(' */
    const char *p = memchr(type_str, '(', type_str_len);
    const char *end;
    if (!p) return newSViv(code);
    p++;
    end = type_str + type_str_len - 1; /* skip closing ')' */

    while (p < end) {
        /* Skip whitespace */
        while (p < end && *p == ' ') p++;
        if (p >= end || *p != '\'') break;
        p++; /* skip opening quote */

        /* Read label (handle escaped quotes) */
        {
            const char *label_start = p;
            size_t label_len;
            int val;

            while (p < end && !(*p == '\'' && (p + 1 >= end || *(p+1) != '\''))) {
                if (*p == '\'' && p + 1 < end && *(p+1) == '\'') { p += 2; continue; }
                p++;
            }
            label_len = p - label_start;
            if (p < end) p++; /* skip closing quote */

            /* Skip ' = ' */
            while (p < end && (*p == ' ' || *p == '=')) p++;

            /* Read integer value */
            val = (int)strtol(p, NULL, 10);

            if (val == code) return newSVpvn(label_start, label_len);

            /* Skip to next entry */
            while (p < end && *p != ',') p++;
            if (p < end) p++; /* skip comma */
        }
    }
    /* Not found — return numeric code */
    return newSViv(code);
}

/*
 * Decode a column of `nrows` values from the native binary format.
 * Returns an array of SVs (one per row). Returns NULL on failure.
 * Sets *decode_err=1 on definitive errors (vs needing more data).
 * Advances *pos past the consumed bytes.
 */

#ifdef __SIZEOF_INT128__
static SV* int128_to_sv(const char *p, int is_signed) {
    unsigned __int128 uv;
    char dbuf[42];
    int dlen = 0, neg = 0, k;
    if (is_signed) {
        __int128 sv;
        memcpy(&sv, p, 16);
        neg = sv < 0;
        uv = neg ? -(unsigned __int128)sv : (unsigned __int128)sv;
    } else {
        memcpy(&uv, p, 16);
    }
    do {
        dbuf[dlen++] = '0' + (int)(uv % 10);
        uv /= 10;
    } while (uv);
    if (neg) dbuf[dlen++] = '-';
    for (k = 0; k < dlen/2; k++) {
        char tmp = dbuf[k]; dbuf[k] = dbuf[dlen-1-k]; dbuf[dlen-1-k] = tmp;
    }
    return newSVpvn(dbuf, dlen);
}
#endif

/* Convert a 256-bit LE unsigned integer (as 4 x uint64_t) to decimal string.
 * Works on all platforms (no __int128 required). */
static SV* uint256_to_sv(const char *p) {
    /* Copy into 4 x uint64_t LE limbs: v[0] = lowest */
    uint64_t v[4];
    char dbuf[80];
    int dlen = 0, k;

    memcpy(v, p, 32);

    /* Handle zero */
    if (v[0] == 0 && v[1] == 0 && v[2] == 0 && v[3] == 0)
        return newSVpvn("0", 1);

    /* Repeatedly divide by 10, collecting remainders */
    while (v[0] || v[1] || v[2] || v[3]) {
        uint64_t rem = 0;
        int i;
        for (i = 3; i >= 0; i--) {
#ifdef __SIZEOF_INT128__
            unsigned __int128 cur = ((unsigned __int128)rem << 64) | v[i];
            v[i] = (uint64_t)(cur / 10);
            rem = (uint64_t)(cur % 10);
#else
            /* Without 128-bit: split each 64-bit limb into hi32:lo32 */
            uint64_t hi = (rem << 32) | (v[i] >> 32);
            uint64_t q_hi = hi / 10;
            uint64_t r_hi = hi % 10;
            uint64_t lo = (r_hi << 32) | (v[i] & 0xFFFFFFFFULL);
            uint64_t q_lo = lo / 10;
            rem = lo % 10;
            v[i] = (q_hi << 32) | q_lo;
#endif
        }
        dbuf[dlen++] = '0' + (int)rem;
    }
    for (k = 0; k < dlen/2; k++) {
        char tmp = dbuf[k]; dbuf[k] = dbuf[dlen-1-k]; dbuf[dlen-1-k] = tmp;
    }
    return newSVpvn(dbuf, dlen);
}

static SV* int256_to_sv(const char *p, int is_signed) {
    if (is_signed && ((unsigned char)p[31] & 0x80)) {
        /* Negative: two's complement negate, format, prepend '-' */
        unsigned char neg[32];
        int i, carry = 1;
        SV *sv;
        STRLEN svlen;
        char *s;
        for (i = 0; i < 32; i++) {
            int b = (unsigned char)(~((unsigned char)p[i])) + carry;
            neg[i] = (unsigned char)(b & 0xFF);
            carry = b >> 8;
        }
        sv = uint256_to_sv((const char *)neg);
        /* Prepend '-' */
        s = SvPV(sv, svlen);
        {
            SV *result = newSV(svlen + 1);
            SvPOK_on(result);
            SvCUR_set(result, svlen + 1);
            *SvPVX(result) = '-';
            Copy(s, SvPVX(result) + 1, svlen, char);
            SvPVX(result)[svlen + 1] = '\0';
            SvREFCNT_dec(sv);
            return result;
        }
    }
    return uint256_to_sv(p);
}

static SV** decode_column_ex(const char *buf, size_t len, size_t *pos,
                              uint64_t nrows, col_type_t *ct, int *decode_err,
                              uint32_t decode_flags, ev_clickhouse_t *lc_self,
                              int lc_col_idx);

static SV** decode_column(const char *buf, size_t len, size_t *pos,
                           uint64_t nrows, col_type_t *ct, int *decode_err,
                           uint32_t decode_flags) {
    return decode_column_ex(buf, len, pos, nrows, ct, decode_err, decode_flags, NULL, -1);
}

static SV** decode_column_ex(const char *buf, size_t len, size_t *pos,
                              uint64_t nrows, col_type_t *ct, int *decode_err,
                              uint32_t decode_flags, ev_clickhouse_t *lc_self,
                              int lc_col_idx) {
    SV **out;
    uint64_t i;
    size_t fsz;

    Newxz(out, nrows ? nrows : 1, SV*);

    if (ct->code == CT_NOTHING) {
        /* Nothing type: 1 placeholder byte ('0') per row */
        if (*pos > len || nrows > len - *pos) goto fail;
        *pos += nrows;
        for (i = 0; i < nrows; i++)
            out[i] = newSV(0);
        return out;
    }

    if (ct->code == CT_NULLABLE) {
        /* null bitmap: nrows bytes of UInt8 */
        uint8_t *nulls;
        SV **inner;
        if (*pos > len || nrows > len - *pos) goto fail;
        Newx(nulls, nrows, uint8_t);
        Copy(buf + *pos, nulls, nrows, uint8_t);
        *pos += nrows;

        /* decode inner column */
        inner = decode_column(buf, len, pos, nrows, ct->inner, decode_err, decode_flags);
        if (!inner) { Safefree(nulls); goto fail; }

        for (i = 0; i < nrows; i++) {
            if (nulls[i]) {
                SvREFCNT_dec(inner[i]);
                out[i] = newSV(0); /* undef */
            } else {
                out[i] = inner[i];
            }
        }
        Safefree(nulls);
        Safefree(inner);
        return out;
    }

    if (ct->code == CT_LOWCARDINALITY) {
        /*
         * LowCardinality wire format (all multi-byte integers are UInt64 LE):
         *   PREFIX:  UInt64 key_version (1=SharedDicts, 2=SingleDict)
         *   DATA:    UInt64 serialization_type (bits 0-7: index type,
         *            bit 8: NeedGlobalDictionary, bit 9: HasAdditionalKeys,
         *            bit 10: NeedUpdateDictionary)
         *            if NeedUpdateDictionary: UInt64 num_keys + dictionary data
         *            UInt64 num_indices + index data
         */
        uint64_t version, ser_type, num_keys, num_indices;
        size_t saved = *pos;
        int key_type;
        size_t idx_size;
        SV **dict = NULL;
        int dict_borrowed = 0;  /* 1 if dict points to lc_self storage */

        /* key_version: UInt64 (from serializeBinaryBulkStatePrefix) */
        if (*pos + 8 > len) goto fail;
        memcpy(&version, buf + *pos, 8); *pos += 8;

        /* serialization_type: UInt64 */
        if (*pos + 8 > len) { *pos = saved; goto fail; }
        memcpy(&ser_type, buf + *pos, 8); *pos += 8;

        key_type = (int)(ser_type & 0xFF);
        /* key_type: 0=UInt8, 1=UInt16, 2=UInt32, 3=UInt64 */

        /* Read dictionary if NeedUpdateDictionary (bit 10) */
        if (ser_type & (1ULL << 10)) {
            if (*pos + 8 > len) { *pos = saved; goto fail; }
            memcpy(&num_keys, buf + *pos, 8); *pos += 8;

            dict = decode_column(buf, len, pos, num_keys, ct->inner, decode_err, decode_flags);
            if (!dict) { *pos = saved; goto fail; }
        } else {
            /* NeedUpdateDictionary=0: reuse dictionary from prior block */
            if (lc_self && lc_col_idx >= 0 && lc_col_idx < lc_self->lc_num_cols
                && lc_self->lc_dicts[lc_col_idx]) {
                dict = lc_self->lc_dicts[lc_col_idx];
                num_keys = lc_self->lc_dict_sizes[lc_col_idx];
                dict_borrowed = 1;
            } else {
                if (decode_err) *decode_err = 1;
                *pos = saved;
                goto fail;
            }
        }

        /* Read indices: UInt64 num_indices + index data */
        if (*pos + 8 > len) {
            if (dict && !dict_borrowed) { for (i = 0; i < num_keys; i++) SvREFCNT_dec(dict[i]); Safefree(dict); }
            *pos = saved; goto fail;
        }
        memcpy(&num_indices, buf + *pos, 8); *pos += 8;

        idx_size = (key_type == 0) ? 1 : (key_type == 1) ? 2 :
                   (key_type == 2) ? 4 : 8;
        if (num_indices != nrows) {
            if (dict && !dict_borrowed) { for (i = 0; i < num_keys; i++) SvREFCNT_dec(dict[i]); Safefree(dict); }
            *pos = saved; if (decode_err) *decode_err = 1; goto fail;
        }
        if (*pos > len || num_indices > (len - *pos) / idx_size) {
            if (dict && !dict_borrowed) { for (i = 0; i < num_keys; i++) SvREFCNT_dec(dict[i]); Safefree(dict); }
            *pos = saved; goto fail;
        }

        /* Store new dictionary for cross-block reuse (after validation) */
        if (!dict_borrowed && lc_self && lc_col_idx >= 0 && lc_col_idx < lc_self->lc_num_cols) {
            if (lc_self->lc_dicts[lc_col_idx]) {
                uint64_t di;
                for (di = 0; di < lc_self->lc_dict_sizes[lc_col_idx]; di++)
                    SvREFCNT_dec(lc_self->lc_dicts[lc_col_idx][di]);
                Safefree(lc_self->lc_dicts[lc_col_idx]);
            }
            SV **dcopy;
            Newx(dcopy, num_keys > 0 ? num_keys : 1, SV*);
            for (i = 0; i < num_keys; i++)
                dcopy[i] = SvREFCNT_inc(dict[i]);
            lc_self->lc_dicts[lc_col_idx] = dcopy;
            lc_self->lc_dict_sizes[lc_col_idx] = num_keys;
        }

        for (i = 0; i < nrows; i++) {
            uint64_t idx = 0;
            memcpy(&idx, buf + *pos + i * idx_size, idx_size);
            if (dict && idx < num_keys) {
                out[i] = SvREFCNT_inc(dict[idx]);
            } else {
                out[i] = newSV(0); /* undef for missing dict entry */
            }
        }
        *pos += num_indices * idx_size;

        if (dict && !dict_borrowed) {
            for (i = 0; i < num_keys; i++) SvREFCNT_dec(dict[i]);
            Safefree(dict);
        }
        return out;
    }

    if (ct->code == CT_STRING) {
        for (i = 0; i < nrows; i++) {
            const char *s;
            size_t slen;
            if (read_native_string_ref(buf, len, pos, &s, &slen) <= 0) {
                /* clean up already-created SVs */
                uint64_t j;
                for (j = 0; j < i; j++) SvREFCNT_dec(out[j]);
                goto fail;
            }
            out[i] = newSVpvn(s, slen);
        }
        return out;
    }

    if (ct->code == CT_ARRAY) {
        /* offsets: nrows x UInt64 */
        uint64_t *offsets;
        SV **elems;
        uint64_t total, prev;

        if (*pos > len || nrows > (len - *pos) / 8) goto fail;
        Newx(offsets, nrows, uint64_t);
        Copy(buf + *pos, offsets, nrows, uint64_t);
        *pos += nrows * 8;

        /* validate offset monotonicity */
        prev = 0;
        for (i = 0; i < nrows; i++) {
            if (offsets[i] < prev) { Safefree(offsets); goto fail; }
            prev = offsets[i];
        }

        total = nrows > 0 ? offsets[nrows - 1] : 0;

        /* decode all inner elements */
        elems = decode_column(buf, len, pos, total, ct->inner, decode_err, decode_flags);
        if (!elems) { Safefree(offsets); goto fail; }

        /* build AV for each row */
        prev = 0;
        for (i = 0; i < nrows; i++) {
            uint64_t count = offsets[i] - prev;
            AV *av = newAV();
            uint64_t j;
            if (count > 0) av_extend(av, count - 1);
            for (j = 0; j < count; j++) {
                av_push(av, elems[prev + j]);
            }
            out[i] = newRV_noinc((SV*)av);
            prev = offsets[i];
        }

        Safefree(offsets);
        Safefree(elems);
        return out;
    }

    if (ct->code == CT_TUPLE) {
        /* Tuple: each element is a separate column, transpose to row arrays */
        SV ***cols;
        int j;

        Newxz(cols, ct->num_inners, SV**);
        for (j = 0; j < ct->num_inners; j++) {
            cols[j] = decode_column(buf, len, pos, nrows, ct->inners[j], decode_err, decode_flags);
            if (!cols[j]) {
                int k;
                for (k = 0; k < j; k++) {
                    for (i = 0; i < nrows; i++) SvREFCNT_dec(cols[k][i]);
                    Safefree(cols[k]);
                }
                Safefree(cols);
                goto fail;
            }
        }

        for (i = 0; i < nrows; i++) {
            AV *av = newAV();
            av_extend(av, ct->num_inners - 1);
            for (j = 0; j < ct->num_inners; j++)
                av_push(av, cols[j][i]);
            out[i] = newRV_noinc((SV*)av);
        }

        for (j = 0; j < ct->num_inners; j++) Safefree(cols[j]);
        Safefree(cols);
        return out;
    }

    if (ct->code == CT_MAP) {
        if (ct->num_inners != 2) { if (decode_err) *decode_err = 1; goto fail; }
        /* Map(K,V): wire format same as Array — offsets + keys column + values column */
        uint64_t *offsets, total, prev;
        SV **keys_col, **vals_col;

        if (*pos > len || nrows > (len - *pos) / 8) goto fail;
        Newx(offsets, nrows, uint64_t);
        Copy(buf + *pos, offsets, nrows, uint64_t);
        *pos += nrows * 8;

        /* validate offset monotonicity */
        prev = 0;
        for (i = 0; i < nrows; i++) {
            if (offsets[i] < prev) { Safefree(offsets); goto fail; }
            prev = offsets[i];
        }

        total = nrows > 0 ? offsets[nrows - 1] : 0;

        keys_col = decode_column(buf, len, pos, total, ct->inners[0], decode_err, decode_flags);
        if (!keys_col) { Safefree(offsets); goto fail; }

        vals_col = decode_column(buf, len, pos, total, ct->inners[1], decode_err, decode_flags);
        if (!vals_col) {
            for (i = 0; i < total; i++) SvREFCNT_dec(keys_col[i]);
            Safefree(keys_col);
            Safefree(offsets);
            goto fail;
        }

        prev = 0;
        for (i = 0; i < nrows; i++) {
            uint64_t count = offsets[i] - prev;
            HV *hv = newHV();
            uint64_t j;
            for (j = 0; j < count; j++) {
                STRLEN klen;
                const char *kstr = SvPV(keys_col[prev + j], klen);
                {
                    SV *val_sv = SvREFCNT_inc(vals_col[prev + j]);
                    if (!hv_store(hv, kstr, klen, val_sv, 0))
                        SvREFCNT_dec(val_sv);
                }
            }
            out[i] = newRV_noinc((SV*)hv);
            prev = offsets[i];
        }

        for (i = 0; i < total; i++) {
            SvREFCNT_dec(keys_col[i]);
            SvREFCNT_dec(vals_col[i]);
        }
        Safefree(keys_col);
        Safefree(vals_col);
        Safefree(offsets);
        return out;
    }

    /* Fixed-width types */
    fsz = col_type_fixed_size(ct);
    if (ct->code == CT_FIXEDSTRING && fsz == 0) {
        /* FixedString(0): 0 bytes per row, produce empty strings */
        for (i = 0; i < nrows; i++)
            out[i] = newSVpvn("", 0);
        return out;
    }
    if (fsz > 0) {
        char *saved_tz = NULL;
        int tz_set = 0;

        if (*pos > len || nrows > (len - *pos) / fsz) goto fail;

        /* Set timezone for DateTime/DateTime64 columns with explicit tz */
        if (ct->tz && (decode_flags & DECODE_DT_STR) &&
            (ct->code == CT_DATETIME || ct->code == CT_DATETIME64)) {
            saved_tz = set_tz(ct->tz);
            tz_set = 1;
        }

        for (i = 0; i < nrows; i++) {
            const char *p = buf + *pos + i * fsz;
            switch (ct->code) {
                case CT_INT8:    out[i] = newSViv(*(int8_t*)p); break;
                case CT_INT16:   { int16_t v; memcpy(&v, p, 2); out[i] = newSViv(v); break; }
                case CT_INT32:   { int32_t v; memcpy(&v, p, 4); out[i] = newSViv(v); break; }
                case CT_INT64:   { int64_t v; memcpy(&v, p, 8); out[i] = newSViv((IV)v); break; }
                case CT_UINT8: case CT_BOOL:
                                 out[i] = newSVuv(*(uint8_t*)p); break;
                case CT_UINT16:  { uint16_t v; memcpy(&v, p, 2); out[i] = newSVuv(v); break; }
                case CT_UINT32:  { uint32_t v; memcpy(&v, p, 4); out[i] = newSVuv(v); break; }
                case CT_UINT64:  { uint64_t v; memcpy(&v, p, 8); out[i] = newSVuv((UV)v); break; }
                case CT_FLOAT32: { float v; memcpy(&v, p, 4); out[i] = newSVnv(v); break; }
                case CT_FLOAT64: { double v; memcpy(&v, p, 8); out[i] = newSVnv(v); break; }
                case CT_ENUM8:
                    if (decode_flags & DECODE_ENUM_STR)
                        out[i] = enum_label_for_code(ct->type_str, ct->type_str_len, *(int8_t*)p);
                    else
                        out[i] = newSViv(*(int8_t*)p);
                    break;
                case CT_ENUM16: {
                    int16_t v; memcpy(&v, p, 2);
                    if (decode_flags & DECODE_ENUM_STR)
                        out[i] = enum_label_for_code(ct->type_str, ct->type_str_len, v);
                    else
                        out[i] = newSViv(v);
                    break;
                }
                case CT_DATE: {
                    uint16_t v; memcpy(&v, p, 2);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = days_to_date_sv((int32_t)v);
                    else
                        out[i] = newSVuv(v);
                    break;
                }
                case CT_DATE32: {
                    int32_t v; memcpy(&v, p, 4);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = days_to_date_sv(v);
                    else
                        out[i] = newSViv(v);
                    break;
                }
                case CT_DATETIME: {
                    uint32_t v; memcpy(&v, p, 4);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = tz_set ? epoch_to_datetime_sv_local(v)
                                        : epoch_to_datetime_sv(v);
                    else
                        out[i] = newSVuv(v);
                    break;
                }
                case CT_DATETIME64: {
                    int64_t v; memcpy(&v, p, 8);
                    if (decode_flags & DECODE_DT_STR)
                        out[i] = dt64_to_datetime_sv_ex(v, ct->param, tz_set);
                    else
                        out[i] = newSViv((IV)v);
                    break;
                }
                case CT_DECIMAL32: {
                    int32_t v; memcpy(&v, p, 4);
                    if (decode_flags & DECODE_DEC_SCALE)
                        out[i] = newSVnv((double)v / pow10_int(ct->param));
                    else
                        out[i] = newSViv(v);
                    break;
                }
                case CT_DECIMAL64: {
                    int64_t v; memcpy(&v, p, 8);
                    if (decode_flags & DECODE_DEC_SCALE)
                        out[i] = newSVnv((double)v / pow10_int(ct->param));
                    else
                        out[i] = newSViv((IV)v);
                    break;
                }
                case CT_DECIMAL128: {
                  #ifdef __SIZEOF_INT128__
                    if (decode_flags & DECODE_DEC_SCALE) {
                        __int128 sv128;
                        memcpy(&sv128, p, 16);
                        /* Use long double for Decimal128 to preserve more precision */
                        out[i] = newSVnv((NV)((long double)sv128 / (long double)pow10_int(ct->param)));
                    } else {
                        out[i] = int128_to_sv(p, 1);
                    }
                  #else
                    out[i] = newSVpvn(p, 16);
                  #endif
                    break;
                }
                case CT_UUID: {
                    /* UUID: two LE UInt64 halves, each reversed for display */
                    char ustr[37];
                    const unsigned char *u = (const unsigned char *)p;
                    snprintf(ustr, sizeof(ustr),
                        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                        u[7],u[6],u[5],u[4],u[3],u[2],u[1],u[0],
                        u[15],u[14],u[13],u[12],u[11],u[10],u[9],u[8]);
                    out[i] = newSVpvn(ustr, 36);
                    break;
                }
                case CT_IPV4: {
                    /* UInt32 LE, MSB is first octet */
                    uint32_t v;
                    struct in_addr addr;
                    char abuf[INET_ADDRSTRLEN];
                    memcpy(&v, p, 4);
                    addr.s_addr = htonl(v);
                    inet_ntop(AF_INET, &addr, abuf, sizeof(abuf));
                    out[i] = newSVpv(abuf, 0);
                    break;
                }
                case CT_IPV6: {
                    /* 16 bytes in network byte order */
                    char abuf[INET6_ADDRSTRLEN];
                    inet_ntop(AF_INET6, p, abuf, sizeof(abuf));
                    out[i] = newSVpv(abuf, 0);
                    break;
                }
                case CT_INT128: {
                  #ifdef __SIZEOF_INT128__
                    out[i] = int128_to_sv(p, 1);
                  #else
                    out[i] = newSVpvn(p, 16);
                  #endif
                    break;
                }
                case CT_UINT128: {
                  #ifdef __SIZEOF_INT128__
                    out[i] = int128_to_sv(p, 0);
                  #else
                    out[i] = newSVpvn(p, 16);
                  #endif
                    break;
                }
                case CT_INT256:
                    out[i] = int256_to_sv(p, 1); break;
                case CT_UINT256:
                    out[i] = int256_to_sv(p, 0); break;
                case CT_FIXEDSTRING: default:
                    out[i] = newSVpvn(p, fsz); break;
            }
        }
        if (tz_set) restore_tz(saved_tz);
        *pos += nrows * fsz;
        return out;
    }

    /* CT_UNKNOWN: try reading as String */
    for (i = 0; i < nrows; i++) {
        const char *s;
        size_t slen;
        if (read_native_string_ref(buf, len, pos, &s, &slen) <= 0) {
            uint64_t j;
            for (j = 0; j < i; j++) SvREFCNT_dec(out[j]);
            goto fail;
        }
        out[i] = newSVpvn(s, slen);
    }
    return out;

fail:
    Safefree(out);
    return NULL;
}

/* --- Native protocol column encoder (for INSERT) --- */

/* TSV unescape: \\ → \, \n → newline, \t → tab, \0 → null byte */
static size_t tsv_unescape(const char *src, size_t src_len, char *dst) {
    size_t i, j = 0;
    for (i = 0; i < src_len; i++) {
        if (src[i] == '\\' && i + 1 < src_len) {
            switch (src[i+1]) {
                case '\\': dst[j++] = '\\'; i++; break;
                case 'n':  dst[j++] = '\n'; i++; break;
                case 't':  dst[j++] = '\t'; i++; break;
                case '0':  dst[j++] = '\0'; i++; break;
                case '\'': dst[j++] = '\''; i++; break;
                case 'b':  dst[j++] = '\b'; i++; break;
                case 'r':  dst[j++] = '\r'; i++; break;
                case 'a':  dst[j++] = '\a'; i++; break;
                case 'f':  dst[j++] = '\f'; i++; break;
                default:   dst[j++] = src[i]; break;
            }
        } else {
            dst[j++] = src[i];
        }
    }
    return j;
}

static int is_tsv_null(const char *s, size_t len) {
    return len == 2 && s[0] == '\\' && s[1] == 'N';
}

/* TSV escape: inverse of tsv_unescape — appends escaped bytes to buffer */
static void tsv_escape(native_buf_t *b, const char *s, size_t len) {
    size_t i, start = 0;
    for (i = 0; i < len; i++) {
        char esc = 0;
        switch (s[i]) {
            case '\\': esc = '\\'; break;
            case '\t': esc = 't';  break;
            case '\n': esc = 'n';  break;
            case '\0': esc = '0';  break;
            case '\b': esc = 'b';  break;
            case '\r': esc = 'r';  break;
            case '\a': esc = 'a';  break;
            case '\f': esc = 'f';  break;
        }
        if (esc) {
            if (i > start)
                nbuf_append(b, s + start, i - start);
            nbuf_grow(b, 2);
            b->data[b->len++] = '\\';
            b->data[b->len++] = esc;
            start = i + 1;
        }
    }
    if (start < len)
        nbuf_append(b, s + start, len - start);
}

/* Serialize an AV of AVs to TabSeparated format for HTTP INSERT.
 * Returns malloc'd buffer; caller must Safefree(). */
static char* serialize_av_to_tsv(pTHX_ AV *rows, size_t *out_len) {
    native_buf_t b;
    SSize_t nrows = av_len(rows) + 1;
    SSize_t r;

    nbuf_init(&b);

    for (r = 0; r < nrows; r++) {
        SV **row_svp = av_fetch(rows, r, 0);
        AV *row;
        SSize_t ncols, c;

        if (!row_svp || !SvROK(*row_svp) ||
            SvTYPE(SvRV(*row_svp)) != SVt_PVAV) {
            Safefree(b.data);
            croak("insert data: row %" IVdf " is not an ARRAY ref", (IV)r);
        }
        row = (AV *)SvRV(*row_svp);
        ncols = av_len(row) + 1;

        for (c = 0; c < ncols; c++) {
            SV **val_svp = av_fetch(row, c, 0);
            if (c > 0)
                nbuf_u8(&b, '\t');

            if (!val_svp || !SvOK(*val_svp)) {
                nbuf_append(&b, "\\N", 2);
            } else {
                STRLEN vlen;
                const char *v = SvPV(*val_svp, vlen);
                tsv_escape(&b, v, vlen);
            }
        }
        nbuf_u8(&b, '\n');
    }

    *out_len = b.len;
    return b.data;
}

/*
 * Encode a column of text values into native binary format.
 * Returns 1 on success, 0 if type is unsupported (caller falls back to inline SQL).
 */
static int encode_column_text(native_buf_t *b,
                               const char **values, size_t *value_lens,
                               uint64_t nrows, col_type_t *ct) {
    uint64_t i;

    switch (ct->code) {
    case CT_INT8: case CT_ENUM8: {
        for (i = 0; i < nrows; i++) {
            int8_t v = (int8_t)strtol(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 1);
        }
        return 1;
    }
    case CT_INT16: case CT_ENUM16: {
        for (i = 0; i < nrows; i++) {
            int16_t v = (int16_t)strtol(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 2);
        }
        return 1;
    }
    case CT_INT32: case CT_DATE32: {
        for (i = 0; i < nrows; i++) {
            int32_t v;
            if (ct->code == CT_DATE32 && value_lens[i] >= 10
                && values[i][4] == '-')
                v = date_string_to_days(values[i], value_lens[i]);
            else
                v = (int32_t)strtol(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_INT64: {
        for (i = 0; i < nrows; i++) {
            int64_t v = (int64_t)strtoll(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_UINT8: case CT_BOOL: {
        for (i = 0; i < nrows; i++) {
            uint8_t v = (uint8_t)strtoul(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 1);
        }
        return 1;
    }
    case CT_UINT16: case CT_DATE: {
        for (i = 0; i < nrows; i++) {
            uint16_t v;
            if (ct->code == CT_DATE && value_lens[i] >= 10
                && values[i][4] == '-')
                v = (uint16_t)date_string_to_days(values[i], value_lens[i]);
            else
                v = (uint16_t)strtoul(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 2);
        }
        return 1;
    }
    case CT_UINT32: case CT_DATETIME: {
        for (i = 0; i < nrows; i++) {
            uint32_t v;
            if (ct->code == CT_DATETIME && value_lens[i] >= 10
                && values[i][4] == '-')
                v = datetime_string_to_epoch(values[i], value_lens[i]);
            else
                v = (uint32_t)strtoul(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_UINT64: {
        for (i = 0; i < nrows; i++) {
            uint64_t v = (uint64_t)strtoull(values[i], NULL, 10);
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_FLOAT32: {
        for (i = 0; i < nrows; i++) {
            float v = strtof(values[i], NULL);
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_FLOAT64: {
        for (i = 0; i < nrows; i++) {
            double v = strtod(values[i], NULL);
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DATETIME64: {
        for (i = 0; i < nrows; i++) {
            int64_t v;
            if (value_lens[i] >= 10 && values[i][4] == '-') {
                uint32_t epoch = datetime_string_to_epoch(values[i], value_lens[i]);
                int s;
                v = (int64_t)epoch;
                for (s = 0; s < ct->param; s++) v *= 10;
                /* parse fractional seconds if present (e.g. ".123") */
                if (value_lens[i] >= 20 && values[i][19] == '.') {
                    const char *fp = values[i] + 20;
                    const char *fe = values[i] + value_lens[i];
                    int64_t frac = 0;
                    int digits = 0, prec = ct->param;
                    while (fp < fe && digits < prec) {
                        frac = frac * 10 + (*fp - '0');
                        fp++;
                        digits++;
                    }
                    while (digits < prec) { frac *= 10; digits++; }
                    v += frac;
                }
            } else {
                v = (int64_t)strtoll(values[i], NULL, 10);
            }
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DECIMAL32: {
        for (i = 0; i < nrows; i++) {
            const char *p = values[i];
            int neg = 0;
            int64_t integer_part = 0, frac_part = 0;
            int frac_digits = 0, scale = ct->param, s;
            if (*p == '-') { neg = 1; p++; }
            else if (*p == '+') p++;
            while (*p >= '0' && *p <= '9') { integer_part = integer_part * 10 + (*p - '0'); p++; }
            if (*p == '.') {
                p++;
                while (*p >= '0' && *p <= '9' && frac_digits < scale) {
                    frac_part = frac_part * 10 + (*p - '0');
                    p++;
                    frac_digits++;
                }
            }
            for (s = frac_digits; s < scale; s++) frac_part *= 10;
            for (s = 0; s < scale; s++) integer_part *= 10;
            {
                int64_t raw = integer_part + frac_part;
                if (neg) raw = -raw;
                int32_t v = (int32_t)raw;
                nbuf_append(b, (const char *)&v, 4);
            }
        }
        return 1;
    }
    case CT_DECIMAL64: {
        for (i = 0; i < nrows; i++) {
            const char *p = values[i];
            int neg = 0;
            int64_t integer_part = 0, frac_part = 0;
            int frac_digits = 0, scale = ct->param, s;
            if (*p == '-') { neg = 1; p++; }
            else if (*p == '+') p++;
            while (*p >= '0' && *p <= '9') { integer_part = integer_part * 10 + (*p - '0'); p++; }
            if (*p == '.') {
                p++;
                while (*p >= '0' && *p <= '9' && frac_digits < scale) {
                    frac_part = frac_part * 10 + (*p - '0');
                    p++;
                    frac_digits++;
                }
            }
            for (s = frac_digits; s < scale; s++) frac_part *= 10;
            for (s = 0; s < scale; s++) integer_part *= 10;
            {
                int64_t v = integer_part + frac_part;
                if (neg) v = -v;
                nbuf_append(b, (const char *)&v, 8);
            }
        }
        return 1;
    }
    case CT_STRING: {
        for (i = 0; i < nrows; i++) {
            if (memchr(values[i], '\\', value_lens[i])) {
                char *tmp;
                size_t ulen;
                Newx(tmp, value_lens[i], char);
                ulen = tsv_unescape(values[i], value_lens[i], tmp);
                nbuf_string(b, tmp, ulen);
                Safefree(tmp);
            } else {
                nbuf_string(b, values[i], value_lens[i]);
            }
        }
        return 1;
    }
    case CT_FIXEDSTRING: {
        size_t fsz = (size_t)ct->param;
        for (i = 0; i < nrows; i++) {
            if (memchr(values[i], '\\', value_lens[i])) {
                char *tmp;
                size_t ulen;
                size_t tmp_sz = value_lens[i] > fsz ? value_lens[i] : fsz;
                Newxz(tmp, tmp_sz, char);
                ulen = tsv_unescape(values[i], value_lens[i], tmp);
                (void)ulen;
                nbuf_append(b, tmp, fsz);
                Safefree(tmp);
            } else {
                nbuf_grow(b, fsz);
                {
                    size_t cplen = value_lens[i] < fsz ? value_lens[i] : fsz;
                    memcpy(b->data + b->len, values[i], cplen);
                    if (cplen < fsz)
                        memset(b->data + b->len + cplen, 0, fsz - cplen);
                }
                b->len += fsz;
            }
        }
        return 1;
    }
    case CT_UUID: {
        /* Parse "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" → 16 bytes LE halves */
        for (i = 0; i < nrows; i++) {
            unsigned char ubytes[16];
            const char *s = values[i];
            size_t slen = value_lens[i];
            if (slen >= 36) {
                /* parse hex digits, skip dashes */
                unsigned char raw[16];
                int k = 0, j;
                for (j = 0; j < (int)slen && k < 32; j++) {
                    char c = s[j];
                    if (c == '-') continue;
                    {
                        unsigned char nibble;
                        if (c >= '0' && c <= '9') nibble = c - '0';
                        else if (c >= 'a' && c <= 'f') nibble = 10 + c - 'a';
                        else if (c >= 'A' && c <= 'F') nibble = 10 + c - 'A';
                        else nibble = 0;
                        if (k % 2 == 0) raw[k/2] = nibble << 4;
                        else raw[k/2] |= nibble;
                    }
                    k++;
                }
                /* Reverse each 8-byte half for LE storage */
                for (k = 0; k < 8; k++) ubytes[k] = raw[7 - k];
                for (k = 0; k < 8; k++) ubytes[8 + k] = raw[15 - k];
            } else {
                memset(ubytes, 0, 16);
            }
            nbuf_append(b, (const char *)ubytes, 16);
        }
        return 1;
    }
    case CT_IPV4: {
        for (i = 0; i < nrows; i++) {
            struct in_addr addr;
            uint32_t v = 0;
            char tmp[64];
            size_t cplen = value_lens[i] < 63 ? value_lens[i] : 63;
            memcpy(tmp, values[i], cplen);
            tmp[cplen] = '\0';
            if (inet_pton(AF_INET, tmp, &addr) == 1)
                v = ntohl(addr.s_addr);
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_IPV6: {
        for (i = 0; i < nrows; i++) {
            unsigned char addr[16];
            char tmp[64];
            size_t cplen = value_lens[i] < 63 ? value_lens[i] : 63;
            memcpy(tmp, values[i], cplen);
            tmp[cplen] = '\0';
            memset(addr, 0, 16);
            inet_pton(AF_INET6, tmp, addr);
            nbuf_append(b, (const char *)addr, 16);
        }
        return 1;
    }
    case CT_NULLABLE: {
        /* null bitmap + inner column */
        uint8_t *nulls;
        const char **inner_vals;
        size_t *inner_lens;
        static const char zero_str[] = "0";
        static const char empty_str[] = "";

        Newx(nulls, nrows, uint8_t);
        Newxz(inner_vals, nrows, const char *);
        Newx(inner_lens, nrows, size_t);

        for (i = 0; i < nrows; i++) {
            if (is_tsv_null(values[i], value_lens[i])) {
                nulls[i] = 1;
                /* placeholder for null — use zero/empty depending on inner type */
                if (ct->inner->code == CT_STRING || ct->inner->code == CT_FIXEDSTRING) {
                    inner_vals[i] = empty_str;
                    inner_lens[i] = 0;
                } else {
                    inner_vals[i] = zero_str;
                    inner_lens[i] = 1;
                }
            } else {
                nulls[i] = 0;
                inner_vals[i] = values[i];
                inner_lens[i] = value_lens[i];
            }
        }

        nbuf_append(b, (const char *)nulls, nrows);
        {
            int rc = encode_column_text(b, inner_vals, inner_lens, nrows, ct->inner);
            Safefree(nulls);
            Safefree(inner_vals);
            Safefree(inner_lens);
            return rc;
        }
    }
    case CT_LOWCARDINALITY: {
        /* Trivial 1:1 dictionary: each value is its own dict entry.
         * This is correct wire format, just not deduplicated. */
        int key_type;
        size_t idx_size;
        uint64_t ser_type, version = 1;
        native_buf_t dict_buf;
        int rc;

        if (nrows <= 0xFF) { key_type = 0; idx_size = 1; }
        else if (nrows <= 0xFFFF) { key_type = 1; idx_size = 2; }
        else { key_type = 2; idx_size = 4; }

        ser_type = (uint64_t)key_type | (1ULL << 9) | (1ULL << 10);
        /* HasAdditionalKeys | NeedUpdateDictionary */

        /* version (prefix) */
        nbuf_append(b, (const char *)&version, 8);
        /* serialization_type */
        nbuf_append(b, (const char *)&ser_type, 8);
        /* num_keys */
        {
            uint64_t nk = nrows;
            nbuf_append(b, (const char *)&nk, 8);
        }
        /* dictionary data: encode as inner type */
        nbuf_init(&dict_buf);
        rc = encode_column_text(&dict_buf, values, value_lens, nrows, ct->inner);
        if (!rc) { Safefree(dict_buf.data); return 0; }
        nbuf_append(b, dict_buf.data, dict_buf.len);
        Safefree(dict_buf.data);
        /* num_indices */
        {
            uint64_t ni = nrows;
            nbuf_append(b, (const char *)&ni, 8);
        }
        /* indices: [0, 1, 2, ..., nrows-1] */
        for (i = 0; i < nrows; i++) {
            if (idx_size == 1) {
                uint8_t idx = (uint8_t)i;
                nbuf_append(b, (const char *)&idx, 1);
            } else if (idx_size == 2) {
                uint16_t idx = (uint16_t)i;
                nbuf_append(b, (const char *)&idx, 2);
            } else {
                uint32_t idx = (uint32_t)i;
                nbuf_append(b, (const char *)&idx, 4);
            }
        }
        return 1;
    }
    default:
        return 0;  /* unsupported type — fall back to inline SQL */
    }
}

/*
 * Encode a column of Perl SV values into native binary format.
 * Like encode_column_text() but takes SVs directly — no TSV parsing/unescaping.
 * Returns 1 on success, 0 if type is unsupported.
 */
static int encode_column_sv(pTHX_ native_buf_t *b,
                            SV **values, uint64_t nrows,
                            col_type_t *ct) {
    uint64_t i;

    switch (ct->code) {
    case CT_INT8: case CT_ENUM8: {
        for (i = 0; i < nrows; i++) {
            int8_t v = SvIOK(values[i]) ? (int8_t)SvIV(values[i])
                     : (int8_t)strtol(SvPV_nolen(values[i]), NULL, 10);
            nbuf_append(b, (const char *)&v, 1);
        }
        return 1;
    }
    case CT_INT16: case CT_ENUM16: {
        for (i = 0; i < nrows; i++) {
            int16_t v = SvIOK(values[i]) ? (int16_t)SvIV(values[i])
                      : (int16_t)strtol(SvPV_nolen(values[i]), NULL, 10);
            nbuf_append(b, (const char *)&v, 2);
        }
        return 1;
    }
    case CT_INT32: case CT_DATE32: {
        for (i = 0; i < nrows; i++) {
            int32_t v;
            if (SvIOK(values[i])) {
                v = (int32_t)SvIV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SvPV(values[i], vlen);
                if (ct->code == CT_DATE32 && vlen >= 10 && s[4] == '-')
                    v = date_string_to_days(s, vlen);
                else
                    v = (int32_t)strtol(s, NULL, 10);
            }
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_INT64: {
        for (i = 0; i < nrows; i++) {
            int64_t v = SvIOK(values[i]) ? (int64_t)SvIV(values[i])
                      : (int64_t)strtoll(SvPV_nolen(values[i]), NULL, 10);
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_UINT8: case CT_BOOL: {
        for (i = 0; i < nrows; i++) {
            uint8_t v = SvIOK(values[i]) ? (uint8_t)SvUV(values[i])
                      : (uint8_t)strtoul(SvPV_nolen(values[i]), NULL, 10);
            nbuf_append(b, (const char *)&v, 1);
        }
        return 1;
    }
    case CT_UINT16: case CT_DATE: {
        for (i = 0; i < nrows; i++) {
            uint16_t v;
            if (SvIOK(values[i])) {
                v = (uint16_t)SvUV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SvPV(values[i], vlen);
                if (ct->code == CT_DATE && vlen >= 10 && s[4] == '-')
                    v = (uint16_t)date_string_to_days(s, vlen);
                else
                    v = (uint16_t)strtoul(s, NULL, 10);
            }
            nbuf_append(b, (const char *)&v, 2);
        }
        return 1;
    }
    case CT_UINT32: case CT_DATETIME: {
        for (i = 0; i < nrows; i++) {
            uint32_t v;
            if (SvIOK(values[i])) {
                v = (uint32_t)SvUV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SvPV(values[i], vlen);
                if (ct->code == CT_DATETIME && vlen >= 10 && s[4] == '-')
                    v = datetime_string_to_epoch(s, vlen);
                else
                    v = (uint32_t)strtoul(s, NULL, 10);
            }
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_UINT64: {
        for (i = 0; i < nrows; i++) {
            uint64_t v = SvIOK(values[i]) ? (uint64_t)SvUV(values[i])
                       : (uint64_t)strtoull(SvPV_nolen(values[i]), NULL, 10);
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_FLOAT32: {
        for (i = 0; i < nrows; i++) {
            float v = SvNOK(values[i]) ? (float)SvNV(values[i])
                    : strtof(SvPV_nolen(values[i]), NULL);
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_FLOAT64: {
        for (i = 0; i < nrows; i++) {
            double v = SvNOK(values[i]) ? SvNV(values[i])
                     : strtod(SvPV_nolen(values[i]), NULL);
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DATETIME64: {
        for (i = 0; i < nrows; i++) {
            int64_t v;
            if (SvIOK(values[i])) {
                v = (int64_t)SvIV(values[i]);
            } else {
                STRLEN vlen;
                const char *s = SvPV(values[i], vlen);
                if (vlen >= 10 && s[4] == '-') {
                    uint32_t epoch = datetime_string_to_epoch(s, vlen);
                    int sc;
                    v = (int64_t)epoch;
                    for (sc = 0; sc < ct->param; sc++) v *= 10;
                    if (vlen >= 20 && s[19] == '.') {
                        const char *fp = s + 20;
                        const char *fe = s + vlen;
                        int64_t frac = 0;
                        int digits = 0, prec = ct->param;
                        while (fp < fe && digits < prec) {
                            frac = frac * 10 + (*fp - '0');
                            fp++;
                            digits++;
                        }
                        while (digits < prec) { frac *= 10; digits++; }
                        v += frac;
                    }
                } else {
                    v = (int64_t)strtoll(s, NULL, 10);
                }
            }
            nbuf_append(b, (const char *)&v, 8);
        }
        return 1;
    }
    case CT_DECIMAL32: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *p = SvPV(values[i], vlen);
            int neg = 0;
            int64_t integer_part = 0, frac_part = 0;
            int frac_digits = 0, scale = ct->param, s;
            if (*p == '-') { neg = 1; p++; }
            else if (*p == '+') p++;
            while (*p >= '0' && *p <= '9') { integer_part = integer_part * 10 + (*p - '0'); p++; }
            if (*p == '.') {
                p++;
                while (*p >= '0' && *p <= '9' && frac_digits < scale) {
                    frac_part = frac_part * 10 + (*p - '0'); p++; frac_digits++;
                }
            }
            for (s = frac_digits; s < scale; s++) frac_part *= 10;
            for (s = 0; s < scale; s++) integer_part *= 10;
            {
                int64_t raw = integer_part + frac_part;
                if (neg) raw = -raw;
                int32_t v = (int32_t)raw;
                nbuf_append(b, (const char *)&v, 4);
            }
        }
        return 1;
    }
    case CT_DECIMAL64: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *p = SvPV(values[i], vlen);
            int neg = 0;
            int64_t integer_part = 0, frac_part = 0;
            int frac_digits = 0, scale = ct->param, s;
            if (*p == '-') { neg = 1; p++; }
            else if (*p == '+') p++;
            while (*p >= '0' && *p <= '9') { integer_part = integer_part * 10 + (*p - '0'); p++; }
            if (*p == '.') {
                p++;
                while (*p >= '0' && *p <= '9' && frac_digits < scale) {
                    frac_part = frac_part * 10 + (*p - '0'); p++; frac_digits++;
                }
            }
            for (s = frac_digits; s < scale; s++) frac_part *= 10;
            for (s = 0; s < scale; s++) integer_part *= 10;
            {
                int64_t v = integer_part + frac_part;
                if (neg) v = -v;
                nbuf_append(b, (const char *)&v, 8);
            }
        }
        return 1;
    }
    case CT_STRING: {
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *v = SvPV(values[i], vlen);
            nbuf_string(b, v, vlen);
        }
        return 1;
    }
    case CT_FIXEDSTRING: {
        size_t fsz = (size_t)ct->param;
        for (i = 0; i < nrows; i++) {
            STRLEN vlen;
            const char *v = SvPV(values[i], vlen);
            size_t cplen = (size_t)vlen < fsz ? (size_t)vlen : fsz;
            nbuf_grow(b, fsz);
            memcpy(b->data + b->len, v, cplen);
            if (cplen < fsz)
                memset(b->data + b->len + cplen, 0, fsz - cplen);
            b->len += fsz;
        }
        return 1;
    }
    case CT_UUID: {
        for (i = 0; i < nrows; i++) {
            unsigned char ubytes[16];
            STRLEN slen;
            const char *s = SvPV(values[i], slen);
            if (slen >= 36) {
                unsigned char raw[16];
                int k = 0, j;
                for (j = 0; j < (int)slen && k < 32; j++) {
                    char c = s[j];
                    if (c == '-') continue;
                    {
                        unsigned char nibble;
                        if (c >= '0' && c <= '9') nibble = c - '0';
                        else if (c >= 'a' && c <= 'f') nibble = 10 + c - 'a';
                        else if (c >= 'A' && c <= 'F') nibble = 10 + c - 'A';
                        else nibble = 0;
                        if (k % 2 == 0) raw[k/2] = nibble << 4;
                        else raw[k/2] |= nibble;
                    }
                    k++;
                }
                for (k = 0; k < 8; k++) ubytes[k] = raw[7 - k];
                for (k = 0; k < 8; k++) ubytes[8 + k] = raw[15 - k];
            } else {
                memset(ubytes, 0, 16);
            }
            nbuf_append(b, (const char *)ubytes, 16);
        }
        return 1;
    }
    case CT_IPV4: {
        for (i = 0; i < nrows; i++) {
            struct in_addr addr;
            uint32_t v = 0;
            char tmp[64];
            STRLEN vlen;
            const char *s = SvPV(values[i], vlen);
            size_t cplen = (size_t)vlen < 63 ? (size_t)vlen : 63;
            memcpy(tmp, s, cplen);
            tmp[cplen] = '\0';
            if (inet_pton(AF_INET, tmp, &addr) == 1)
                v = ntohl(addr.s_addr);
            nbuf_append(b, (const char *)&v, 4);
        }
        return 1;
    }
    case CT_IPV6: {
        for (i = 0; i < nrows; i++) {
            unsigned char addr[16];
            char tmp[64];
            STRLEN vlen;
            const char *s = SvPV(values[i], vlen);
            size_t cplen = (size_t)vlen < 63 ? (size_t)vlen : 63;
            memcpy(tmp, s, cplen);
            tmp[cplen] = '\0';
            memset(addr, 0, 16);
            inet_pton(AF_INET6, tmp, addr);
            nbuf_append(b, (const char *)addr, 16);
        }
        return 1;
    }
    case CT_NULLABLE: {
        uint8_t *nulls;
        SV **inner_vals;
        SV *zero_sv;

        Newx(nulls, nrows, uint8_t);
        Newx(inner_vals, nrows ? nrows : 1, SV *);
        zero_sv = newSViv(0);

        for (i = 0; i < nrows; i++) {
            if (!SvOK(values[i])) {
                nulls[i] = 1;
                inner_vals[i] = zero_sv;
            } else {
                nulls[i] = 0;
                inner_vals[i] = values[i];
            }
        }

        nbuf_append(b, (const char *)nulls, nrows);
        {
            int rc = encode_column_sv(aTHX_ b, inner_vals, nrows, ct->inner);
            Safefree(nulls);
            Safefree(inner_vals);
            SvREFCNT_dec(zero_sv);
            return rc;
        }
    }
    case CT_LOWCARDINALITY: {
        int key_type;
        size_t idx_size;
        uint64_t ser_type, version = 1;
        native_buf_t dict_buf;
        int rc;

        if (nrows <= 0xFF) { key_type = 0; idx_size = 1; }
        else if (nrows <= 0xFFFF) { key_type = 1; idx_size = 2; }
        else { key_type = 2; idx_size = 4; }

        ser_type = (uint64_t)key_type | (1ULL << 9) | (1ULL << 10);

        nbuf_append(b, (const char *)&version, 8);
        nbuf_append(b, (const char *)&ser_type, 8);
        {
            uint64_t nk = nrows;
            nbuf_append(b, (const char *)&nk, 8);
        }
        nbuf_init(&dict_buf);
        rc = encode_column_sv(aTHX_ &dict_buf, values, nrows, ct->inner);
        if (!rc) { Safefree(dict_buf.data); return 0; }
        nbuf_append(b, dict_buf.data, dict_buf.len);
        Safefree(dict_buf.data);
        {
            uint64_t ni = nrows;
            nbuf_append(b, (const char *)&ni, 8);
        }
        for (i = 0; i < nrows; i++) {
            if (idx_size == 1) {
                uint8_t idx = (uint8_t)i;
                nbuf_append(b, (const char *)&idx, 1);
            } else if (idx_size == 2) {
                uint16_t idx = (uint16_t)i;
                nbuf_append(b, (const char *)&idx, 2);
            } else {
                uint32_t idx = (uint32_t)i;
                nbuf_append(b, (const char *)&idx, 4);
            }
        }
        return 1;
    }
    case CT_ARRAY: {
        /* Each value must be an AV ref. Wire format: offsets + flat inner data */
        uint64_t total = 0;
        uint64_t *offsets;
        SV **all_elems;
        uint64_t pos = 0;
        int rc;

        for (i = 0; i < nrows; i++) {
            AV *av;
            if (!SvROK(values[i]) || SvTYPE(SvRV(values[i])) != SVt_PVAV)
                return 0;
            av = (AV *)SvRV(values[i]);
            { SSize_t cnt = av_len(av) + 1; if (cnt > 0) total += (uint64_t)cnt; }
        }

        Newx(offsets, nrows, uint64_t);
        Newx(all_elems, total ? total : 1, SV *);

        for (i = 0; i < nrows; i++) {
            AV *av = (AV *)SvRV(values[i]);
            SSize_t n = av_len(av) + 1, j;
            for (j = 0; j < n; j++) {
                SV **ep = av_fetch(av, j, 0);
                all_elems[pos++] = ep ? *ep : &PL_sv_undef;
            }
            offsets[i] = pos;
        }

        /* write offsets as uint64 LE */
        nbuf_append(b, (const char *)offsets, nrows * 8);
        rc = encode_column_sv(aTHX_ b, all_elems, total, ct->inner);
        Safefree(offsets);
        Safefree(all_elems);
        return rc;
    }
    case CT_TUPLE: {
        /* Each value must be an AV ref with num_inners elements */
        int j;
        for (j = 0; j < ct->num_inners; j++) {
            SV **col_vals;
            int rc;
            Newx(col_vals, nrows ? nrows : 1, SV *);
            for (i = 0; i < nrows; i++) {
                AV *av;
                SV **ep;
                if (!SvROK(values[i]) || SvTYPE(SvRV(values[i])) != SVt_PVAV) {
                    Safefree(col_vals);
                    return 0;
                }
                av = (AV *)SvRV(values[i]);
                ep = av_fetch(av, j, 0);
                col_vals[i] = ep ? *ep : &PL_sv_undef;
            }
            rc = encode_column_sv(aTHX_ b, col_vals, nrows, ct->inners[j]);
            Safefree(col_vals);
            if (!rc) return 0;
        }
        return 1;
    }
    case CT_MAP: {
        /* Each value must be a hashref. Wire format: offsets + key column + value column */
        uint64_t total = 0;
        uint64_t *offsets;
        SV **all_keys, **all_vals;
        uint64_t pos = 0;
        int rc;

        if (ct->num_inners != 2) return 0;

        for (i = 0; i < nrows; i++) {
            HV *hv;
            if (!SvROK(values[i]) || SvTYPE(SvRV(values[i])) != SVt_PVHV)
                return 0;
            hv = (HV *)SvRV(values[i]);
            total += HvUSEDKEYS(hv);
        }

        Newx(offsets, nrows, uint64_t);
        Newx(all_keys, total ? total : 1, SV *);
        Newx(all_vals, total ? total : 1, SV *);

        for (i = 0; i < nrows; i++) {
            HV *hv = (HV *)SvRV(values[i]);
            HE *he;
            hv_iterinit(hv);
            while ((he = hv_iternext(hv))) {
                all_keys[pos] = hv_iterkeysv(he);
                all_vals[pos] = hv_iterval(hv, he);
                pos++;
            }
            offsets[i] = pos;
        }

        nbuf_append(b, (const char *)offsets, nrows * 8);
        rc = encode_column_sv(aTHX_ b, all_keys, total, ct->inners[0]);
        if (rc) rc = encode_column_sv(aTHX_ b, all_vals, total, ct->inners[1]);
        Safefree(offsets);
        Safefree(all_keys);
        Safefree(all_vals);
        return rc;
    }
    default:
        return 0;
    }
}

/*
 * Wrap a filled Data block body into a CLIENT_DATA packet with optional LZ4 + empty trailing block.
 * Consumes body->data (frees it). Returns malloc'd packet, or NULL on failure.
 */
static char* wrap_data_block(ev_clickhouse_t *self, native_buf_t *body, size_t *out_len) {
    native_buf_t pkt;

    nbuf_init(&pkt);
    nbuf_varuint(&pkt, CLIENT_DATA);
    nbuf_cstring(&pkt, "");   /* table name — outside compression */

  #ifdef HAVE_LZ4
    if (self->compress) {
        char *compressed;
        size_t comp_len;
        compressed = ch_lz4_compress(body->data, body->len, &comp_len);
        Safefree(body->data);
        body->data = NULL;
        if (compressed) {
            nbuf_append(&pkt, compressed, comp_len);
            Safefree(compressed);
        } else {
            Safefree(pkt.data);
            *out_len = 0;
            return NULL;
        }
    } else
  #endif
    {
        nbuf_append(&pkt, body->data, body->len);
        Safefree(body->data);
        body->data = NULL;
    }

    nbuf_empty_data_block(&pkt, self->compress);

    *out_len = pkt.len;
    return pkt.data;
}

/*
 * Build a native protocol Data block from TabSeparated text data.
 * col_names/col_types_str are string references into the sample block buffer.
 * Returns malloc'd packet data (CLIENT_DATA + block), or NULL on failure.
 */
static char* build_native_insert_data(ev_clickhouse_t *self,
                                       const char *tsv_data, size_t tsv_len,
                                       const char **col_names, size_t *col_name_lens,
                                       const char **col_types_str, size_t *col_type_lens,
                                       col_type_t **col_types,
                                       int num_cols,
                                       size_t *out_len) {
    /* Parse TSV into rows and fields */
    int nrows = 0, max_rows = 64;
    const char **fields = NULL;  /* flat array: fields[row * num_cols + col] */
    size_t *field_lens = NULL;
    const char *p = tsv_data;
    const char *end = tsv_data + tsv_len;

    Newxz(fields, max_rows * num_cols, const char *);
    Newx(field_lens, max_rows * num_cols, size_t);

    while (p < end) {
        const char *line_end = memchr(p, '\n', end - p);
        const char *line_limit = line_end ? line_end : end;
        int col;

        /* skip empty trailing line */
        if (p == line_limit) { p = line_limit + 1; continue; }

        if (nrows >= max_rows) {
            if (max_rows > INT_MAX / 2 ||
                (num_cols > 0 && max_rows * 2 > INT_MAX / num_cols)) {
                Safefree(fields);
                Safefree(field_lens);
                *out_len = 0;
                return NULL;
            }
            max_rows *= 2;
            Renew(fields, max_rows * num_cols, const char *);
            Renew(field_lens, max_rows * num_cols, size_t);
        }

        /* split line by tabs */
        {
            const char *fp = p;
            for (col = 0; col < num_cols; col++) {
                const char *tab;
                if (fp > line_limit) fp = line_limit;
                if (col < num_cols - 1) {
                    tab = memchr(fp, '\t', line_limit - fp);
                    if (!tab) tab = line_limit;
                } else {
                    tab = line_limit;
                }
                fields[nrows * num_cols + col] = fp;
                field_lens[nrows * num_cols + col] = tab - fp;
                fp = tab + 1;
            }
        }
        nrows++;
        p = line_limit + 1;
    }

    if (nrows == 0) {
        Safefree(fields);
        Safefree(field_lens);
        *out_len = 0;
        return NULL;
    }

    /* Build the Data block body: block info + num_cols + num_rows + columns */
    {
        native_buf_t body;
        int col;

        nbuf_init(&body);

        /* block info */
        nbuf_varuint(&body, 1);    /* field_num = 1 */
        nbuf_u8(&body, 0);         /* is_overflows = false */
        nbuf_varuint(&body, 2);    /* field_num = 2 */
        {
            int32_t bucket = -1;
            nbuf_append(&body, (const char *)&bucket, 4);
        }
        nbuf_varuint(&body, 0);    /* end of block info */
        nbuf_varuint(&body, (uint64_t)num_cols);
        nbuf_varuint(&body, (uint64_t)nrows);

        /* encode each column */
        for (col = 0; col < num_cols; col++) {
            const char **col_vals;
            size_t *col_vlens;
            int row;

            /* column name and type */
            nbuf_string(&body, col_names[col], col_name_lens[col]);
            nbuf_string(&body, col_types_str[col], col_type_lens[col]);
            nbuf_u8(&body, 0);  /* has_custom_serialization = false */

            /* gather column values from row-major fields */
            Newxz(col_vals, nrows, const char *);
            Newx(col_vlens, nrows, size_t);
            for (row = 0; row < nrows; row++) {
                col_vals[row] = fields[row * num_cols + col];
                col_vlens[row] = field_lens[row * num_cols + col];
            }

            if (!encode_column_text(&body, col_vals, col_vlens,
                                    (uint64_t)nrows, col_types[col])) {
                Safefree(col_vals);
                Safefree(col_vlens);
                Safefree(body.data);
                Safefree(fields);
                Safefree(field_lens);
                *out_len = (size_t)-1;  /* sentinel: encode failure */
                return NULL;
            }
            Safefree(col_vals);
            Safefree(col_vlens);
        }

        Safefree(fields);
        Safefree(field_lens);

        {
            char *result = wrap_data_block(self, &body, out_len);
            if (!result) { *out_len = 0; return NULL; }
            return result;
        }
    }
}

/*
 * Build a native protocol Data block from an AV of AV refs.
 * Like build_native_insert_data() but encodes SVs directly via encode_column_sv().
 */
static char* build_native_insert_data_from_av(pTHX_ ev_clickhouse_t *self,
                                               AV *rows,
                                               const char **col_names, size_t *col_name_lens,
                                               const char **col_types_str, size_t *col_type_lens,
                                               col_type_t **col_types,
                                               int num_cols,
                                               size_t *out_len) {
    SSize_t nrows = av_len(rows) + 1;
    native_buf_t body;
    int col;

    if (nrows <= 0) {
        *out_len = 0;
        return NULL;
    }

    nbuf_init(&body);

    /* block info */
    nbuf_varuint(&body, 1);    /* field_num = 1 */
    nbuf_u8(&body, 0);         /* is_overflows = false */
    nbuf_varuint(&body, 2);    /* field_num = 2 */
    {
        int32_t bucket = -1;
        nbuf_append(&body, (const char *)&bucket, 4);
    }
    nbuf_varuint(&body, 0);    /* end of block info */
    nbuf_varuint(&body, (uint64_t)num_cols);
    nbuf_varuint(&body, (uint64_t)nrows);

    /* encode each column */
    for (col = 0; col < num_cols; col++) {
        SV **col_vals;
        SSize_t row;

        nbuf_string(&body, col_names[col], col_name_lens[col]);
        nbuf_string(&body, col_types_str[col], col_type_lens[col]);
        nbuf_u8(&body, 0);  /* has_custom_serialization = false */

        /* gather column values from row-major AV */
        Newx(col_vals, nrows, SV *);
        for (row = 0; row < nrows; row++) {
            SV **row_svp = av_fetch(rows, row, 0);
            AV *row_av;
            SV **val_svp;

            if (!row_svp || !SvROK(*row_svp) || SvTYPE(SvRV(*row_svp)) != SVt_PVAV) {
                Safefree(col_vals);
                Safefree(body.data);
                *out_len = (size_t)-1;  /* sentinel: encode failure */
                return NULL;
            }
            row_av = (AV *)SvRV(*row_svp);
            val_svp = av_fetch(row_av, col, 0);
            col_vals[row] = (val_svp && *val_svp) ? *val_svp : &PL_sv_undef;
        }

        if (!encode_column_sv(aTHX_ &body, col_vals, (uint64_t)nrows, col_types[col])) {
            Safefree(col_vals);
            Safefree(body.data);
            *out_len = (size_t)-1;  /* sentinel: encode failure */
            return NULL;
        }
        Safefree(col_vals);
    }

    {
        char *result = wrap_data_block(self, &body, out_len);
        if (!result) { *out_len = 0; return NULL; }
        return result;
    }
}

/* --- Native protocol response parser --- */

/*
 * Skip block info fields (revision >= DBMS_MIN_REVISION_WITH_BLOCK_INFO).
 * Returns 1 on success, 0 if need more data.
 */
static int skip_block_info(const char *buf, size_t len, size_t *pos) {
    for (;;) {
        uint64_t field_num;
        int rc = read_varuint(buf, len, pos, &field_num);
        if (rc == 0) return 0;
        if (rc < 0) return -1;
        if (field_num == 0) return 1;  /* end marker */
        if (field_num == 1) {
            /* is_overflows: UInt8 */
            uint8_t dummy;
            rc = read_u8(buf, len, pos, &dummy);
            if (rc <= 0) return rc;
        } else if (field_num == 2) {
            /* bucket_num: Int32 */
            int32_t dummy;
            rc = read_i32(buf, len, pos, &dummy);
            if (rc <= 0) return rc;
        } else {
            return -1;  /* protocol error */
        }
    }
}

/*
 * Try to parse one server packet from recv_buf.
 * Returns:
 *   1  = packet consumed, continue reading
 *   0  = need more data
 *  -1  = error (message in *errmsg, caller must Safefree)
 *   2  = EndOfStream
 *   3  = Pong
 *   4  = Hello parsed (self->server_* fields populated)
 */
static int parse_native_packet(ev_clickhouse_t *self, char **errmsg) {
    const char *buf = self->recv_buf;
    size_t len = self->recv_len;
    size_t pos = 0;
    uint64_t ptype;
    int rc;

    rc = read_varuint(buf, len, &pos, &ptype);
    if (rc == 0) return 0;
    if (rc < 0) {
        *errmsg = safe_strdup("malformed packet type");
        return -1;
    }

    switch ((int)ptype) {

    case SERVER_HELLO: {
        char *sname = NULL;
        size_t sname_len;
        uint64_t major, minor, revision;

        rc = read_native_string_alloc(buf, len, &pos, &sname, &sname_len);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed server name"); return -1; }

        rc = read_varuint(buf, len, &pos, &major);
        if (rc == 0) { Safefree(sname); return 0; }
        if (rc < 0) { Safefree(sname); *errmsg = safe_strdup("malformed server version major"); return -1; }

        rc = read_varuint(buf, len, &pos, &minor);
        if (rc == 0) { Safefree(sname); return 0; }
        if (rc < 0) { Safefree(sname); *errmsg = safe_strdup("malformed server version minor"); return -1; }

        rc = read_varuint(buf, len, &pos, &revision);
        if (rc == 0) { Safefree(sname); return 0; }
        if (rc < 0) { Safefree(sname); *errmsg = safe_strdup("malformed server revision"); return -1; }

        if (self->server_name) Safefree(self->server_name);
        self->server_name = sname;
        self->server_version_major = (unsigned int)major;
        self->server_version_minor = (unsigned int)minor;
        self->server_revision = (unsigned int)revision;

        /* timezone (our revision >= 54423) */
        if (CH_CLIENT_REVISION >= DBMS_MIN_REVISION_WITH_SERVER_TIMEZONE) {
            char *tz = NULL;
            rc = read_native_string_alloc(buf, len, &pos, &tz, NULL);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed timezone"); return -1; }
            if (self->server_timezone) Safefree(self->server_timezone);
            self->server_timezone = tz;
        }

        /* display_name (our revision >= 54372) */
        if (CH_CLIENT_REVISION >= DBMS_MIN_REVISION_WITH_SERVER_DISPLAY_NAME) {
            char *dn = NULL;
            rc = read_native_string_alloc(buf, len, &pos, &dn, NULL);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed display name"); return -1; }
            if (self->server_display_name) Safefree(self->server_display_name);
            self->server_display_name = dn;
        }

        /* version_patch (our revision >= 54401) */
        if (CH_CLIENT_REVISION >= DBMS_MIN_REVISION_WITH_VERSION_PATCH) {
            uint64_t patch;
            rc = read_varuint(buf, len, &pos, &patch);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed version patch"); return -1; }
            self->server_version_patch = (unsigned int)patch;
        }

        /* consume from recv_buf */
        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;
        return 4;
    }

    case SERVER_DATA:
    case SERVER_TOTALS:
    case SERVER_EXTREMES: {
        uint64_t num_cols, num_rows;
        const char *dbuf;   /* data buffer (may point to decompressed data) */
        size_t dlen, dpos;
        char *decompressed = NULL;

        /* table name — outside compression */
        rc = skip_native_string(buf, len, &pos);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed table name"); return -1; }

#ifdef HAVE_LZ4
        if (self->compress) {
            /* Decompress the block body — may span multiple LZ4 sub-blocks.
             * ClickHouse's CompressedWriteBuffer flushes at ~1MB, so a single
             * Data packet can produce multiple consecutive compressed frames. */
            size_t comp_consumed;
            int need_more;
            const char *lz4_err = NULL;
            decompressed = ch_lz4_decompress(buf + pos, len - pos,
                                              &dlen, &comp_consumed,
                                              &need_more, &lz4_err);
            if (!decompressed) {
                if (need_more) return 0;
                *errmsg = safe_strdup(lz4_err ? lz4_err : "LZ4 decompression failed");
                return -1;
            }
            pos += comp_consumed;

            /* Decompress any additional sub-blocks.  A compressed sub-block
             * starts with 16 bytes of checksum followed by method byte 0x82.
             * If the remaining data doesn't match that signature, it belongs
             * to the next server packet — stop decompressing. */
            while (len - pos >= CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE
                   && (uint8_t)buf[pos + CH_CHECKSUM_SIZE] == CH_LZ4_METHOD) {
                size_t extra_len, extra_consumed;
                int extra_need_more;
                const char *extra_err = NULL;
                char *extra = ch_lz4_decompress(buf + pos, len - pos,
                                                 &extra_len, &extra_consumed,
                                                 &extra_need_more, &extra_err);
                if (!extra) {
                    if (extra_need_more) {
                        /* Partial sub-block — need more network data.
                         * Discard what we decompressed so far; we'll retry
                         * from the beginning when more data arrives. */
                        Safefree(decompressed);
                        return 0;
                    }
                    /* Decompression error */
                    Safefree(decompressed);
                    *errmsg = safe_strdup(extra_err ? extra_err : "LZ4 decompression failed");
                    return -1;
                }
                /* Append to decompressed buffer */
                Renew(decompressed, dlen + extra_len, char);
                Copy(extra, decompressed + dlen, extra_len, char);
                dlen += extra_len;
                pos += extra_consumed;
                Safefree(extra);
            }

            dbuf = decompressed;
            dpos = 0;
        } else
#endif
        {
            dbuf = buf;
            dlen = len;
            dpos = pos;
        }

        /* block info */
        if (CH_CLIENT_REVISION >= DBMS_MIN_REVISION_WITH_BLOCK_INFO) {
            rc = skip_block_info(dbuf, dlen, &dpos);
            if (rc == 0) {
                if (decompressed) { Safefree(decompressed); *errmsg = safe_strdup("truncated compressed block"); return -1; }
                return 0;
            }
            if (rc < 0) { if (decompressed) Safefree(decompressed); *errmsg = safe_strdup("malformed block info"); return -1; }
        }

        rc = read_varuint(dbuf, dlen, &dpos, &num_cols);
        if (rc == 0) {
            if (decompressed) { Safefree(decompressed); *errmsg = safe_strdup("truncated compressed block"); return -1; }
            return 0;
        }
        if (rc < 0) { if (decompressed) Safefree(decompressed); *errmsg = safe_strdup("malformed num_cols"); return -1; }

        rc = read_varuint(dbuf, dlen, &dpos, &num_rows);
        if (rc == 0) {
            if (decompressed) { Safefree(decompressed); *errmsg = safe_strdup("truncated compressed block"); return -1; }
            return 0;
        }
        if (rc < 0) { if (decompressed) Safefree(decompressed); *errmsg = safe_strdup("malformed num_rows"); return -1; }

        /* Empty data block — skip or handle column names/types */
        if (num_rows == 0) {
            /* INSERT two-phase: server sent sample block with column structure */
            if (self->native_state == NATIVE_WAIT_INSERT_META
                && (self->insert_data || self->insert_av) && num_cols > 0) {
                const char **cnames;
                size_t *cname_lens;
                const char **ctypes_str;
                size_t *ctype_lens;
                col_type_t **ctypes;
                char *data_pkt;
                size_t data_pkt_len;
                uint64_t c;

                Newxz(cnames, num_cols, const char *);
                Newxz(cname_lens, num_cols, size_t);
                Newxz(ctypes_str, num_cols, const char *);
                Newxz(ctype_lens, num_cols, size_t);
                Newxz(ctypes, num_cols, col_type_t *);

                for (c = 0; c < num_cols; c++) {
                    ctypes[c] = NULL;
                    rc = read_native_string_ref(dbuf, dlen, &dpos,
                            &cnames[c], &cname_lens[c]);
                    if (rc <= 0) {
                        for (c = 0; c < num_cols; c++) if (ctypes[c]) free_col_type(ctypes[c]);
                        Safefree(cnames); Safefree(cname_lens);
                        Safefree(ctypes_str); Safefree(ctype_lens);
                        Safefree(ctypes);
                        if (decompressed) Safefree(decompressed);
                        if (rc < 0 || decompressed) { *errmsg = safe_strdup("malformed cname"); return -1; }
                        return 0;
                    }
                    rc = read_native_string_ref(dbuf, dlen, &dpos,
                            &ctypes_str[c], &ctype_lens[c]);
                    if (rc <= 0) {
                        for (c = 0; c < num_cols; c++) if (ctypes[c]) free_col_type(ctypes[c]);
                        Safefree(cnames); Safefree(cname_lens);
                        Safefree(ctypes_str); Safefree(ctype_lens);
                        Safefree(ctypes);
                        if (decompressed) Safefree(decompressed);
                        if (rc < 0 || decompressed) { *errmsg = safe_strdup("malformed ctype"); return -1; }
                        return 0;
                    }
                    ctypes[c] = parse_col_type(ctypes_str[c], ctype_lens[c]);

                    /* custom serialization flag (revision >= 54446) */
                    if (dpos >= dlen) {
                        for (c = 0; c < num_cols; c++) if (ctypes[c]) free_col_type(ctypes[c]);
                        Safefree(cnames); Safefree(cname_lens);
                        Safefree(ctypes_str); Safefree(ctype_lens);
                        Safefree(ctypes);
                        if (decompressed) Safefree(decompressed);
                        if (decompressed) { *errmsg = safe_strdup("truncated custom_ser"); return -1; }
                        return 0;
                    }
                    if ((uint8_t)dbuf[dpos]) {
                        for (c = 0; c < num_cols; c++) if (ctypes[c]) free_col_type(ctypes[c]);
                        Safefree(cnames); Safefree(cname_lens);
                        Safefree(ctypes_str); Safefree(ctype_lens);
                        Safefree(ctypes);
                        if (decompressed) Safefree(decompressed);
                        *errmsg = safe_strdup("custom serialization not supported");
                        return -1;
                    }
                    dpos++;
                }

                /* Build binary data block from stored data */
                if (self->insert_av) {
                    data_pkt = build_native_insert_data_from_av(aTHX_ self,
                        (AV *)SvRV(self->insert_av),
                        cnames, cname_lens, ctypes_str, ctype_lens,
                        ctypes, (int)num_cols, &data_pkt_len);
                } else {
                    data_pkt = build_native_insert_data(self,
                        self->insert_data, self->insert_data_len,
                        cnames, cname_lens, ctypes_str, ctype_lens,
                        ctypes, (int)num_cols, &data_pkt_len);
                }

                for (c = 0; c < num_cols; c++)
                    free_col_type(ctypes[c]);
                Safefree(cnames); Safefree(cname_lens);
                Safefree(ctypes_str); Safefree(ctype_lens);
                Safefree(ctypes);

                {
                /* Check encode-failure sentinel before freeing insert data */
                int encode_failed = (!data_pkt && data_pkt_len == (size_t)-1);

                /* Free stored INSERT data */
                if (self->insert_data) {
                    Safefree(self->insert_data);
                    self->insert_data = NULL;
                    self->insert_data_len = 0;
                }
                if (self->insert_av) {
                    SvREFCNT_dec(self->insert_av);
                    self->insert_av = NULL;
                }

                if (decompressed) Safefree(decompressed);
                else pos = dpos;
                if (pos < self->recv_len) {
                    memmove(self->recv_buf, self->recv_buf + pos,
                            self->recv_len - pos);
                }
                self->recv_len -= pos;

                if (!data_pkt) {
                    /* Send empty Data block to complete the INSERT protocol */
                    native_buf_t fallback;
                    nbuf_init(&fallback);
                    nbuf_empty_data_block(&fallback, self->compress);
                    data_pkt = fallback.data;
                    data_pkt_len = fallback.len;
                    if (encode_failed)
                        self->insert_err = safe_strdup(
                            "native INSERT encoding failed (unsupported type)");
                }
                }

                /* Send the data block — write to send_buf and start writing */
                self->native_state = NATIVE_WAIT_RESULT;
                ensure_send_cap(self, data_pkt_len);
                Copy(data_pkt, self->send_buf, data_pkt_len, char);
                self->send_len = data_pkt_len;
                self->send_pos = 0;
                Safefree(data_pkt);
                if (try_write(self)) return -2;
                return 1;
            }

            /* INSERT two-phase with 0-column sample block: free data,
             * send empty Data block, transition to WAIT_RESULT */
            if (self->native_state == NATIVE_WAIT_INSERT_META
                && (self->insert_data || self->insert_av) && num_cols == 0) {
                native_buf_t fallback;

                if (self->insert_data) {
                    Safefree(self->insert_data);
                    self->insert_data = NULL;
                    self->insert_data_len = 0;
                }
                if (self->insert_av) {
                    SvREFCNT_dec(self->insert_av);
                    self->insert_av = NULL;
                }

                if (decompressed) Safefree(decompressed);
                else pos = dpos;
                if (pos < self->recv_len) {
                    memmove(self->recv_buf, self->recv_buf + pos,
                            self->recv_len - pos);
                }
                self->recv_len -= pos;

                nbuf_init(&fallback);
                nbuf_empty_data_block(&fallback, self->compress);
                self->native_state = NATIVE_WAIT_RESULT;
                ensure_send_cap(self, fallback.len);
                Copy(fallback.data, self->send_buf, fallback.len, char);
                self->send_len = fallback.len;
                self->send_pos = 0;
                Safefree(fallback.data);
                self->insert_err = safe_strdup(
                    "INSERT failed: server sent 0-column sample block");
                if (try_write(self)) return -2;
                return 1;
            }

            /* Normal empty block — skip column names/types/custom_serialization */
            {
                uint64_t c;
                for (c = 0; c < num_cols; c++) {
                    if (skip_native_string(dbuf, dlen, &dpos) <= 0) {
                        if (decompressed) Safefree(decompressed);
                        return 0;
                    }
                    if (skip_native_string(dbuf, dlen, &dpos) <= 0) {
                        if (decompressed) Safefree(decompressed);
                        return 0;
                    }
                    /* custom serialization flag (revision >= 54446) */
                    if (dpos >= dlen) {
                        if (decompressed) Safefree(decompressed);
                        return 0;
                    }
                    if ((uint8_t)dbuf[dpos]) {
                        if (decompressed) Safefree(decompressed);
                        *errmsg = safe_strdup("custom serialization not supported");
                        return -1;
                    }
                    dpos++;
                }
            }
            if (decompressed) Safefree(decompressed);
            else pos = dpos;  /* uncompressed: advance pos to match dpos */
            if (pos < self->recv_len) {
                memmove(self->recv_buf, self->recv_buf + pos,
                        self->recv_len - pos);
            }
            self->recv_len -= pos;
            return 1;
        }

        /* Decode columns and convert to rows */
        {
            SV ***columns = NULL;
            col_type_t **col_types = NULL;
            const char **cnames = NULL;
            size_t *cname_lens = NULL;
            uint64_t c, r;
            int named = (self->decode_flags & DECODE_NAMED_ROWS) ? 1 : 0;

            Newxz(columns, num_cols, SV**);
            Newxz(col_types, num_cols, col_type_t*);
            if (named) {
                Newxz(cnames, num_cols, const char *);
                Newx(cname_lens, num_cols, size_t);
            }

            for (c = 0; c < num_cols; c++) {
                const char *cname, *ctype;
                size_t cname_len, ctype_len;

                columns[c] = NULL;
                col_types[c] = NULL;

                rc = read_native_string_ref(dbuf, dlen, &dpos, &cname, &cname_len);
                if (rc == 0) {
                    if (decompressed) { *errmsg = safe_strdup("truncated cname"); goto data_error; }
                    goto data_need_more;
                }
                if (rc < 0) { *errmsg = safe_strdup("malformed cname"); goto data_error; }

                if (named) {
                    cnames[c] = cname;
                    cname_lens[c] = cname_len;
                }

                /* Save column names/types on first data block of each query */
                if (c == 0 && !self->native_rows && self->native_col_names) {
                    SvREFCNT_dec((SV*)self->native_col_names);
                    self->native_col_names = NULL;
                    if (self->native_col_types) {
                        SvREFCNT_dec((SV*)self->native_col_types);
                        self->native_col_types = NULL;
                    }
                }
                if (!self->native_col_names) {
                    if (c == 0) {
                        self->native_col_names = newAV();
                        self->native_col_types = newAV();
                    }
                }
                if (self->native_col_names && av_len(self->native_col_names) + 1 < (SSize_t)num_cols)
                    av_push(self->native_col_names, newSVpvn(cname, cname_len));

                rc = read_native_string_ref(dbuf, dlen, &dpos, &ctype, &ctype_len);
                if (rc == 0) {
                    if (decompressed) { *errmsg = safe_strdup("truncated ctype"); goto data_error; }
                    goto data_need_more;
                }
                if (rc < 0) { *errmsg = safe_strdup("malformed ctype"); goto data_error; }

                col_types[c] = parse_col_type(ctype, ctype_len);
                if (self->native_col_types && av_len(self->native_col_types) + 1 < (SSize_t)num_cols)
                    av_push(self->native_col_types, newSVpvn(ctype, ctype_len));

                /* custom serialization flag (revision >= 54446) */
                if (dpos >= dlen) {
                    if (decompressed) { *errmsg = safe_strdup("truncated custom_ser"); goto data_error; }
                    goto data_need_more;
                }
                if ((uint8_t)dbuf[dpos]) {
                    *errmsg = safe_strdup("custom serialization not supported");
                    goto data_error;
                }
                dpos++;

                /* Allocate LC dict state on first column of first block */
                if (c == 0 && !self->lc_dicts && num_cols > 0) {
                    Newxz(self->lc_dicts, num_cols, SV**);
                    Newxz(self->lc_dict_sizes, num_cols, uint64_t);
                    self->lc_num_cols = (int)num_cols;
                }

                {
                    int col_err = 0;
                    columns[c] = decode_column_ex(dbuf, dlen, &dpos, num_rows, col_types[c], &col_err, self->decode_flags, self, (int)c);
                    if (!columns[c]) {
                        if (col_err || decompressed) {
                            *errmsg = safe_strdup("decode_column failed");
                            goto data_error;
                        }
                        goto data_need_more;
                    }
                }
            }

            /* Convert column-oriented to row-oriented */
            {
            AV **target;
            if (ptype == SERVER_TOTALS) {
                if (!self->native_totals) self->native_totals = newAV();
                target = &self->native_totals;
            } else if (ptype == SERVER_EXTREMES) {
                if (!self->native_extremes) self->native_extremes = newAV();
                target = &self->native_extremes;
            } else {
                if (!self->native_rows) self->native_rows = newAV();
                target = &self->native_rows;
            }

            if (named) {
                for (r = 0; r < num_rows; r++) {
                    HV *hv = newHV();
                    for (c = 0; c < num_cols; c++) {
                        if (!hv_store(hv, cnames[c], cname_lens[c], columns[c][r], 0))
                            SvREFCNT_dec(columns[c][r]);
                    }
                    av_push(*target, newRV_noinc((SV*)hv));
                }
            } else {
                for (r = 0; r < num_rows; r++) {
                    AV *row = newAV();
                    if (num_cols > 0)
                        av_extend(row, num_cols - 1);
                    for (c = 0; c < num_cols; c++) {
                        av_push(row, columns[c][r]);
                    }
                    av_push(*target, newRV_noinc((SV*)row));
                }
            }
            }

            /* Fire on_data streaming callback if set (only for DATA, not TOTALS/EXTREMES) */
            {
                SV *on_data = (ptype == SERVER_DATA) ? peek_cb_on_data(self) : NULL;
                if (on_data && self->native_rows) {
                    self->callback_depth++;
                    {
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        PUSHs(sv_2mortal(newRV_inc((SV*)self->native_rows)));
                        PUTBACK;
                        call_sv(on_data, G_DISCARD | G_EVAL);
                        if (SvTRUE(ERRSV))
                            warn("EV::ClickHouse: exception in on_data handler: %s",
                                 SvPV_nolen(ERRSV));
                        FREETMPS; LEAVE;
                    }
                    self->callback_depth--;
                    /* Clear accumulated rows for next block */
                    SvREFCNT_dec((SV*)self->native_rows);
                    self->native_rows = NULL;
                    if (check_destroyed(self)) {
                        if (cnames) Safefree(cnames);
                        if (cname_lens) Safefree(cname_lens);
                        for (c = 0; c < num_cols; c++) {
                            Safefree(columns[c]);
                            free_col_type(col_types[c]);
                        }
                        Safefree(columns); Safefree(col_types);
                        if (decompressed) Safefree(decompressed);
                        return -2;
                    }
                }
            }

            /* Cleanup column arrays (SVs moved to rows, don't dec refcnt) */
            for (c = 0; c < num_cols; c++) {
                Safefree(columns[c]);
                free_col_type(col_types[c]);
            }
            Safefree(columns);
            Safefree(col_types);
            if (cnames) Safefree(cnames);
            if (cname_lens) Safefree(cname_lens);
            if (decompressed) Safefree(decompressed);
            else pos = dpos;  /* uncompressed: advance pos to match dpos */

            /* Consume from recv_buf */
            if (pos < self->recv_len) {
                memmove(self->recv_buf, self->recv_buf + pos,
                        self->recv_len - pos);
            }
            self->recv_len -= pos;
            return 1;

        data_error:
        data_need_more:
            /* Cleanup partial decode */
            for (c = 0; c < num_cols; c++) {
                if (columns[c]) {
                    uint64_t j;
                    for (j = 0; j < num_rows; j++) {
                        if (columns[c][j]) SvREFCNT_dec(columns[c][j]);
                    }
                    Safefree(columns[c]);
                }
                if (col_types[c]) free_col_type(col_types[c]);
            }
            Safefree(columns);
            Safefree(col_types);
            if (cnames) Safefree(cnames);
            if (cname_lens) Safefree(cname_lens);
            if (decompressed) Safefree(decompressed);
            if (*errmsg) {
                /* data_error: flush recv_buf — data is malformed, cannot resume */
                self->recv_len = 0;
                return -1;
            }
            return 0;
        }
    }

    case SERVER_EXCEPTION: {
        /* code: Int32, name: String, message: String,
         * stack_trace: String, has_nested: UInt8 */
        int32_t code;
        const char *name, *msg, *stack;
        size_t name_len, msg_len, stack_len;
        uint8_t has_nested;
        char *err;

        /* We just read the top-level exception */
        rc = read_i32(buf, len, &pos, &code);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception code"); return -1; }

        rc = read_native_string_ref(buf, len, &pos, &name, &name_len);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception name"); return -1; }

        rc = read_native_string_ref(buf, len, &pos, &msg, &msg_len);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception message"); return -1; }

        rc = read_native_string_ref(buf, len, &pos, &stack, &stack_len);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception stack"); return -1; }

        rc = read_u8(buf, len, &pos, &has_nested);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed exception has_nested"); return -1; }

        /* Skip nested exceptions */
        while (has_nested) {
            rc = read_i32(buf, len, &pos, &code);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }

            rc = skip_native_string(buf, len, &pos);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }

            rc = skip_native_string(buf, len, &pos);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }

            rc = skip_native_string(buf, len, &pos);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }

            rc = read_u8(buf, len, &pos, &has_nested);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed nested exception"); return -1; }
        }

        self->last_error_code = code;

        Newx(err, msg_len + name_len + 64, char);
        snprintf(err, msg_len + name_len + 64, "Code: %d. %.*s: %.*s",
                 (int)code, (int)name_len, name, (int)msg_len, msg);

        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;

        *errmsg = err;
        return -1;
    }

    case SERVER_PROGRESS: {
        /* rows: VarUInt, bytes: VarUInt, total_rows: VarUInt,
         * written_rows: VarUInt (>= 54420), written_bytes: VarUInt (>= 54420)
         */
        uint64_t p_rows, p_bytes, p_total, p_wrows = 0, p_wbytes = 0;
        rc = read_varuint(buf, len, &pos, &p_rows);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed progress packet"); return -1; }

        rc = read_varuint(buf, len, &pos, &p_bytes);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed progress packet"); return -1; }

        rc = read_varuint(buf, len, &pos, &p_total);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed progress packet"); return -1; }

        if (CH_CLIENT_REVISION >= DBMS_MIN_REVISION_WITH_PROGRESS_WRITES) {
            rc = read_varuint(buf, len, &pos, &p_wrows);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed progress packet"); return -1; }

            rc = read_varuint(buf, len, &pos, &p_wbytes);
            if (rc == 0) return 0;
            if (rc < 0) { *errmsg = safe_strdup("malformed progress packet"); return -1; }
        }

        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;

        if (NULL != self->on_progress) {
            dSP;
            self->callback_depth++;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 5);
            PUSHs(sv_2mortal(newSVuv(p_rows)));
            PUSHs(sv_2mortal(newSVuv(p_bytes)));
            PUSHs(sv_2mortal(newSVuv(p_total)));
            PUSHs(sv_2mortal(newSVuv(p_wrows)));
            PUSHs(sv_2mortal(newSVuv(p_wbytes)));
            PUTBACK;
            call_sv(self->on_progress, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV))
                warn("EV::ClickHouse: exception in progress handler: %s",
                     SvPV_nolen(ERRSV));
            FREETMPS; LEAVE;
            self->callback_depth--;
            if (check_destroyed(self)) return -2; /* destroyed */
        }

        return 1;
    }

    case SERVER_PROFILE_INFO: {
        uint64_t pi_rows, pi_blocks, pi_bytes, pi_applied_limit;
        uint64_t pi_rows_before_limit, pi_calc_rows_before_limit;

        rc = read_varuint(buf, len, &pos, &pi_rows);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed profile_info packet"); return -1; }
        rc = read_varuint(buf, len, &pos, &pi_blocks);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed profile_info packet"); return -1; }
        rc = read_varuint(buf, len, &pos, &pi_bytes);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed profile_info packet"); return -1; }
        rc = read_varuint(buf, len, &pos, &pi_applied_limit);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed profile_info packet"); return -1; }
        rc = read_varuint(buf, len, &pos, &pi_rows_before_limit);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed profile_info packet"); return -1; }
        rc = read_varuint(buf, len, &pos, &pi_calc_rows_before_limit);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed profile_info packet"); return -1; }

        self->profile_rows = pi_rows;
        self->profile_bytes = pi_bytes;
        self->profile_rows_before_limit = pi_rows_before_limit;
        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;
        return 1;
    }

    case SERVER_TABLE_COLUMNS: {
        /* Format: string(table_name) + string(column_description) */
        rc = skip_native_string(buf, len, &pos);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed table_columns packet"); return -1; }
        rc = skip_native_string(buf, len, &pos);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed table_columns packet"); return -1; }
        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;
        return 1;
    }

    case SERVER_LOG: {
        /* Contains a Data block — parse like SERVER_DATA but discard */
        const char *lbuf;
        size_t llen, lpos;
        char *log_decompressed = NULL;

        /* table name — outside compression */
        rc = skip_native_string(buf, len, &pos);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed server log block"); return -1; }

#ifdef HAVE_LZ4
        if (self->compress) {
            size_t comp_consumed;
            int need_more;
            const char *lz4_err = NULL;
            log_decompressed = ch_lz4_decompress(buf + pos, len - pos,
                                                  &llen, &comp_consumed,
                                                  &need_more, &lz4_err);
            if (!log_decompressed) {
                if (need_more) return 0;
                *errmsg = safe_strdup("server log: LZ4 decompression failed");
                return -1;
            }
            pos += comp_consumed;

            /* Additional sub-blocks (same logic as SERVER_DATA) */
            while (len - pos >= CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE
                   && (uint8_t)buf[pos + CH_CHECKSUM_SIZE] == CH_LZ4_METHOD) {
                size_t extra_len, extra_consumed;
                int extra_need_more;
                const char *extra_err = NULL;
                char *extra = ch_lz4_decompress(buf + pos, len - pos,
                                                 &extra_len, &extra_consumed,
                                                 &extra_need_more, &extra_err);
                if (!extra) {
                    if (extra_need_more) {
                        Safefree(log_decompressed);
                        return 0;
                    }
                    Safefree(log_decompressed);
                    *errmsg = safe_strdup(extra_err ? extra_err : "server log: LZ4 decompression failed");
                    return -1;
                }
                Renew(log_decompressed, llen + extra_len, char);
                Copy(extra, log_decompressed + llen, extra_len, char);
                llen += extra_len;
                pos += extra_consumed;
                Safefree(extra);
            }

            lbuf = log_decompressed;
            lpos = 0;
        } else
#endif
        {
            lbuf = buf;
            llen = len;
            lpos = pos;
        }

        /* block info */
        if (CH_CLIENT_REVISION >= DBMS_MIN_REVISION_WITH_BLOCK_INFO) {
            rc = skip_block_info(lbuf, llen, &lpos);
            if (rc <= 0) { if (log_decompressed) Safefree(log_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed server log block"); return rc; }
        }
        uint64_t nc, nr;
        rc = read_varuint(lbuf, llen, &lpos, &nc);
        if (rc <= 0) { if (log_decompressed) Safefree(log_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed server log block"); return rc; }
        rc = read_varuint(lbuf, llen, &lpos, &nr);
        if (rc <= 0) { if (log_decompressed) Safefree(log_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed server log block"); return rc; }

        if (nc > 0) {
            uint64_t c;
            for (c = 0; c < nc; c++) {
                const char *ctype;
                size_t ctype_len;
                rc = skip_native_string(lbuf, llen, &lpos);
                if (rc <= 0) { if (log_decompressed) Safefree(log_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed server log block"); return rc; }
                rc = read_native_string_ref(lbuf, llen, &lpos, &ctype, &ctype_len);
                if (rc <= 0) { if (log_decompressed) Safefree(log_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed server log block"); return rc; }
                /* custom serialization flag (revision >= 54446) */
                if (lpos >= llen) { if (log_decompressed) Safefree(log_decompressed); return 0; }
                if ((uint8_t)lbuf[lpos]) { if (log_decompressed) Safefree(log_decompressed); *errmsg = safe_strdup("custom serialization not supported"); return -1; }
                lpos++;
                if (nr > 0) {
                    col_type_t *ct = parse_col_type(ctype, ctype_len);
                    int log_col_err = 0;
                    SV **vals = decode_column(lbuf, llen, &lpos, nr, ct, &log_col_err, 0);
                    if (!vals) {
                        free_col_type(ct);
                        if (log_col_err || log_decompressed) {
                            if (log_decompressed) Safefree(log_decompressed);
                            *errmsg = safe_strdup("malformed server log block");
                            return -1;
                        }
                        return 0;
                    }
                    uint64_t j;
                    for (j = 0; j < nr; j++) SvREFCNT_dec(vals[j]);
                    Safefree(vals);
                    free_col_type(ct);
                }
            }
        }

        if (!log_decompressed) pos = lpos;
        if (log_decompressed) Safefree(log_decompressed);

        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;
        return 1;
    }

    case SERVER_PROFILE_EVENTS:
        /* Same structure as SERVER_LOG — data block to discard.
         * Fall through to SERVER_LOG handler would work, but SERVER_LOG
         * is above us.  Just skip: table_name + rest handled like LOG. */
    {
        const char *pebuf;
        size_t pelen, pepos;
        char *pe_decompressed = NULL;

        rc = skip_native_string(buf, len, &pos);
        if (rc == 0) return 0;
        if (rc < 0) { *errmsg = safe_strdup("malformed profile_events block"); return -1; }

#ifdef HAVE_LZ4
        if (self->compress) {
            size_t comp_consumed;
            int need_more;
            const char *lz4_err = NULL;
            pe_decompressed = ch_lz4_decompress(buf + pos, len - pos,
                                                 &pelen, &comp_consumed,
                                                 &need_more, &lz4_err);
            if (!pe_decompressed) {
                if (need_more) return 0;
                /* Profile events may be uncompressed — fall back */
                goto pe_uncompressed;
            }
            pos += comp_consumed;
            while (len - pos >= CH_CHECKSUM_SIZE + CH_COMPRESS_HEADER_SIZE
                   && (uint8_t)buf[pos + CH_CHECKSUM_SIZE] == CH_LZ4_METHOD) {
                size_t extra_len, extra_consumed;
                int extra_need_more;
                const char *extra_err = NULL;
                char *extra = ch_lz4_decompress(buf + pos, len - pos,
                                                 &extra_len, &extra_consumed,
                                                 &extra_need_more, &extra_err);
                if (!extra) {
                    if (extra_need_more) { Safefree(pe_decompressed); return 0; }
                    Safefree(pe_decompressed);
                    *errmsg = safe_strdup("profile_events: LZ4 decompression failed");
                    return -1;
                }
                Renew(pe_decompressed, pelen + extra_len, char);
                Copy(extra, pe_decompressed + pelen, extra_len, char);
                pelen += extra_len;
                pos += extra_consumed;
                Safefree(extra);
            }
            pebuf = pe_decompressed;
            pepos = 0;
        } else
#endif
        {
#ifdef HAVE_LZ4
            pe_uncompressed:
#endif
            pebuf = buf;
            pelen = len;
            pepos = pos;
        }

        if (CH_CLIENT_REVISION >= DBMS_MIN_REVISION_WITH_BLOCK_INFO) {
            rc = skip_block_info(pebuf, pelen, &pepos);
            if (rc <= 0) { if (pe_decompressed) Safefree(pe_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed profile_events block"); return rc; }
        }
        uint64_t pe_nc, pe_nr;
        rc = read_varuint(pebuf, pelen, &pepos, &pe_nc);
        if (rc <= 0) { if (pe_decompressed) Safefree(pe_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed profile_events block"); return rc; }
        rc = read_varuint(pebuf, pelen, &pepos, &pe_nr);
        if (rc <= 0) { if (pe_decompressed) Safefree(pe_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed profile_events block"); return rc; }

        if (pe_nc > 0) {
            uint64_t c;
            for (c = 0; c < pe_nc; c++) {
                const char *ctype;
                size_t ctype_len;
                rc = skip_native_string(pebuf, pelen, &pepos);
                if (rc <= 0) { if (pe_decompressed) Safefree(pe_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed profile_events block"); return rc; }
                rc = read_native_string_ref(pebuf, pelen, &pepos, &ctype, &ctype_len);
                if (rc <= 0) { if (pe_decompressed) Safefree(pe_decompressed); if (rc < 0) *errmsg = safe_strdup("malformed profile_events block"); return rc; }
                /* custom serialization flag */
                if (pepos >= pelen) { if (pe_decompressed) Safefree(pe_decompressed); return 0; }
                if ((uint8_t)pebuf[pepos]) { if (pe_decompressed) Safefree(pe_decompressed); *errmsg = safe_strdup("custom serialization not supported"); return -1; }
                pepos++;
                if (pe_nr > 0) {
                    col_type_t *ct = parse_col_type(ctype, ctype_len);
                    int pe_col_err = 0;
                    SV **vals = decode_column(pebuf, pelen, &pepos, pe_nr, ct, &pe_col_err, 0);
                    if (!vals) {
                        free_col_type(ct);
                        if (pe_col_err || pe_decompressed) {
                            if (pe_decompressed) Safefree(pe_decompressed);
                            *errmsg = safe_strdup("malformed profile_events block");
                            return -1;
                        }
                        return 0;
                    }
                    uint64_t j;
                    for (j = 0; j < pe_nr; j++) SvREFCNT_dec(vals[j]);
                    Safefree(vals);
                    free_col_type(ct);
                }
            }
        }

        if (!pe_decompressed) pos = pepos;
        if (pe_decompressed) Safefree(pe_decompressed);

        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;
        return 1;
    }

    case SERVER_PONG:
        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;
        return 3;

    case SERVER_END_OF_STREAM:
        if (pos < self->recv_len) {
            memmove(self->recv_buf, self->recv_buf + pos,
                    self->recv_len - pos);
        }
        self->recv_len -= pos;
        return 2;

    default: {
        /* Unknown packet type */
        char err[64];
        snprintf(err, sizeof(err), "unknown server packet type: %llu",
                 (unsigned long long)ptype);
        *errmsg = safe_strdup(err);
        self->recv_len = 0;
        return -1;
    }
    }
}

/*
 * Process native protocol responses from recv_buf.
 * Called from on_readable when protocol == PROTO_NATIVE.
 */
static void process_native_response(ev_clickhouse_t *self) {
    while (self->recv_len > 0 && self->magic == EV_CH_MAGIC) {
        char *errmsg = NULL;
        int rc;
        rc = parse_native_packet(self, &errmsg);

        if (rc == 0) {
            /* need more data */
            return;
        }

        if (rc == -2) {
            /* object destroyed inside callback */
            return;
        }

        if (rc == 4) {
            /* ServerHello received — send addendum (revision >= 54458) */
            if (self->native_state == NATIVE_WAIT_HELLO) {
                /* Addendum: quota_key (only if server supports it) */
                if (self->server_revision >= DBMS_MIN_PROTOCOL_VERSION_WITH_ADDENDUM) {
                    native_buf_t ab;
                    nbuf_init(&ab);
                    nbuf_cstring(&ab, "");  /* quota_key */
                    ensure_send_cap(self, ab.len);
                    Copy(ab.data, self->send_buf, ab.len, char);
                    self->send_len = ab.len;
                    self->send_pos = 0;
                    Safefree(ab.data);
                    if (try_write(self)) return;
                }
                self->native_state = NATIVE_IDLE;
                self->connected = 1;

                /* fire on_connect */
                if (NULL != self->on_connect) {
                    self->callback_depth++;
                    {
                        dSP;
                        ENTER;
                        SAVETMPS;
                        PUSHMARK(SP);
                        PUTBACK;
                        call_sv(self->on_connect, G_DISCARD | G_EVAL);
                        if (SvTRUE(ERRSV)) {
                            warn("EV::ClickHouse: exception in connect handler: %s",
                                 SvPV_nolen(ERRSV));
                        }
                        FREETMPS;
                        LEAVE;
                    }
                    self->callback_depth--;
                    if (check_destroyed(self)) return;
                }
                /* start pipeline if queries were queued during connect */
                if (!ngx_queue_empty(&self->send_queue))
                    pipeline_advance(self);
            }
            /* pipeline_advance -> try_write may free self; no data
             * in recv_buf for the just-dispatched request yet */
            return;
        }

        if (rc == -1) {
            /* error */
            if (self->native_state == NATIVE_WAIT_HELLO) {
                /* Hello failed — connection-level error */
                self->callback_depth++;
                emit_error(self, errmsg);
                self->callback_depth--;
                Safefree(errmsg);
                if (check_destroyed(self)) return;
                if (cancel_pending(self, "connection failed")) return;
                cleanup_connection(self);
                return;
            }

            /* Stop query timeout timer */
            if (self->timing) {
                ev_timer_stop(self->loop, &self->timer);
                self->timing = 0;
            }

            /* Query error — deliver to callback */
            if (self->native_rows) {
                SvREFCNT_dec((SV*)self->native_rows);
                self->native_rows = NULL;
            }
            if (self->insert_data) {
                Safefree(self->insert_data);
                self->insert_data = NULL;
                self->insert_data_len = 0;
            }
            if (self->insert_av) {
                SvREFCNT_dec(self->insert_av);
                self->insert_av = NULL;
            }
            if (self->insert_err) {
                Safefree(self->insert_err);
                self->insert_err = NULL;
            }
            self->native_state = NATIVE_IDLE;
            self->recv_len = 0; /* flush malformed data */
            if (self->send_count > 0) self->send_count--;
            lc_free_dicts(self);
            int destroyed = deliver_error(self, errmsg);
            Safefree(errmsg);
            if (destroyed) return;

            /* advance pipeline — may free self via try_write error */
            pipeline_advance(self);
            return;
        }

        if (rc == 2) {
            /* EndOfStream — deliver accumulated rows or deferred error */
            if (self->timing) {
                ev_timer_stop(self->loop, &self->timer);
                self->timing = 0;
            }
            self->native_state = NATIVE_IDLE;
            if (self->send_count > 0) self->send_count--;
            lc_free_dicts(self);

            if (self->insert_err) {
                char *err = self->insert_err;
                self->insert_err = NULL;
                if (self->native_rows) {
                    SvREFCNT_dec((SV*)self->native_rows);
                    self->native_rows = NULL;
                }
                int destroyed = deliver_error(self, err);
                Safefree(err);
                if (destroyed) return;
            } else {
                AV *rows = self->native_rows;
                self->native_rows = NULL;
                if (deliver_rows(self, rows)) return;
            }

            /* advance pipeline — may free self via try_write error */
            pipeline_advance(self);
            return;
        }

        if (rc == 3) {
            /* Pong — deliver success to callback */
            if (self->timing) {
                ev_timer_stop(self->loop, &self->timer);
                self->timing = 0;
            }
            self->native_state = NATIVE_IDLE;
            if (self->send_count > 0) self->send_count--;
            AV *rows = newAV();
            if (deliver_rows(self, rows)) return;
            pipeline_advance(self);
            return;
        }

        /* rc == 1: Data/Progress/ProfileInfo — continue reading */
    }
}

/* --- Async TCP connect --- */

static void start_connect(ev_clickhouse_t *self) {
    struct addrinfo hints, *res = NULL;
    int fd, ret;
    char port_str[16];

    emit_trace(self, "connect %s:%u (%s)",
               self->host, self->port,
               self->protocol == PROTO_NATIVE ? "native" : "http");
    snprintf(port_str, sizeof(port_str), "%u", self->port);

    Zero(&hints, 1, struct addrinfo);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    ret = getaddrinfo(self->host, port_str, &hints, &res);
    if (ret != 0) {
        char errbuf[256];
        snprintf(errbuf, sizeof(errbuf), "getaddrinfo: %s", gai_strerror(ret));
        self->callback_depth++;
        emit_error(self, errbuf);
        self->callback_depth--;
        if (check_destroyed(self)) return;
        if (cancel_pending(self, errbuf)) return;
        cleanup_connection(self);
        return;
    }

    fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (fd < 0) {
        freeaddrinfo(res);
        self->callback_depth++;
        emit_error(self, "socket() failed");
        self->callback_depth--;
        if (check_destroyed(self)) return;
        if (cancel_pending(self, "socket() failed")) return;
        cleanup_connection(self);
        return;
    }

    /* non-blocking */
    {
        int fl = fcntl(fd, F_GETFL);
        if (fl < 0 || fcntl(fd, F_SETFL, fl | O_NONBLOCK) < 0) {
            freeaddrinfo(res);
            close(fd);
            self->callback_depth++;
            emit_error(self, "fcntl O_NONBLOCK failed");
            self->callback_depth--;
            if (check_destroyed(self)) return;
            if (cancel_pending(self, "fcntl O_NONBLOCK failed")) return;
            cleanup_connection(self);
            return;
        }
    }

    /* TCP_NODELAY */
    {
        int one = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
    }

    self->fd = fd;
    self->connecting = 1;

    ret = connect(fd, res->ai_addr, res->ai_addrlen);
    freeaddrinfo(res);

    if (ret == 0) {
        /* connected immediately — connected=1 is deferred for native
         * (until ServerHello) and TLS (until handshake completes) */
        self->connecting = 0;
        if (self->protocol != PROTO_NATIVE && !self->tls_enabled)
            self->connected = 1;
        ev_io_init(&self->rio, io_cb, self->fd, EV_READ);
        self->rio.data = (void *)self;
        ev_io_init(&self->wio, io_cb, self->fd, EV_WRITE);
        self->wio.data = (void *)self;
        on_connect_done(self);
        return;
    }

    if (errno != EINPROGRESS) {
        char errbuf[256];
        snprintf(errbuf, sizeof(errbuf), "connect: %s", strerror(errno));
        close(fd);
        self->fd = -1;
        self->connecting = 0;
        self->callback_depth++;
        emit_error(self, errbuf);
        self->callback_depth--;
        if (check_destroyed(self)) return;
        if (cancel_pending(self, errbuf)) return;
        cleanup_connection(self);
        return;
    }

    /* in progress — wait for writability */
    ev_io_init(&self->rio, io_cb, self->fd, EV_READ);
    self->rio.data = (void *)self;
    ev_io_init(&self->wio, io_cb, self->fd, EV_WRITE);
    self->wio.data = (void *)self;

    start_writing(self);

    if (self->connect_timeout > 0) {
        ev_timer_set(&self->timer, (ev_tstamp)self->connect_timeout, 0.0);
        ev_timer_start(self->loop, &self->timer);
        self->timing = 1;
    }
}

static void on_connect_done(ev_clickhouse_t *self) {
    self->connecting = 0;
    self->reconnect_attempts = 0;

    stop_writing(self);
    if (self->timing) {
        ev_timer_stop(self->loop, &self->timer);
        self->timing = 0;
    }

#ifdef HAVE_OPENSSL
    if (self->tls_enabled) {
        int ret;
        self->ssl_ctx = SSL_CTX_new(TLS_client_method());
        if (!self->ssl_ctx) {
            self->callback_depth++;
            emit_error(self, "SSL_CTX_new failed");
            self->callback_depth--;
            if (check_destroyed(self)) return;
            if (cancel_pending(self, "SSL_CTX_new failed")) return;
            cleanup_connection(self);
            return;
        }
        SSL_CTX_set_default_verify_paths(self->ssl_ctx);
        if (self->tls_skip_verify)
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_NONE, NULL);
        else
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_PEER, NULL);
        if (self->tls_ca_file) {
            if (SSL_CTX_load_verify_locations(self->ssl_ctx, self->tls_ca_file, NULL) != 1) {
                self->callback_depth++;
                emit_error(self, "SSL_CTX_load_verify_locations failed");
                self->callback_depth--;
                if (check_destroyed(self)) return;
                if (cancel_pending(self, "SSL_CTX_load_verify_locations failed")) return;
                cleanup_connection(self);
                return;
            }
        }
        self->ssl = SSL_new(self->ssl_ctx);
        if (!self->ssl) {
            self->callback_depth++;
            emit_error(self, "SSL_new failed");
            self->callback_depth--;
            if (check_destroyed(self)) return;
            if (cancel_pending(self, "SSL_new failed")) return;
            cleanup_connection(self);
            return;
        }
        SSL_set_fd(self->ssl, self->fd);

        /* SNI must not be sent for IP address literals (RFC 6066 s3) */
        if (!is_ip_literal(self->host))
            SSL_set_tlsext_host_name(self->ssl, self->host);

        /* Verify server certificate matches hostname or IP */
        if (!self->tls_skip_verify) {
            X509_VERIFY_PARAM *param = SSL_get0_param(self->ssl);
            X509_VERIFY_PARAM_set_hostflags(param, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
            if (is_ip_literal(self->host))
                X509_VERIFY_PARAM_set1_ip_asc(param, self->host);
            else
                X509_VERIFY_PARAM_set1_host(param, self->host, 0);
        }

        ret = SSL_connect(self->ssl);
        if (ret == 1) {
            /* handshake done immediately */
            goto handshake_done;
        } else {
            int err = SSL_get_error(self->ssl, ret);
            if (err == SSL_ERROR_WANT_READ) {
                start_reading(self);
            } else if (err == SSL_ERROR_WANT_WRITE) {
                start_writing(self);
            } else {
                self->callback_depth++;
                emit_error(self, "SSL_connect failed");
                self->callback_depth--;
                if (check_destroyed(self)) return;
                if (cancel_pending(self, "SSL_connect failed")) return;
                cleanup_connection(self);
                return;
            }
            /* continue TLS handshake in io_cb */
            return;
        }
    }
handshake_done:
#endif

    if (self->protocol == PROTO_NATIVE) {
        /* Send ClientHello and wait for ServerHello */
        size_t hello_len;
        char *hello = build_native_hello(self, &hello_len);
        ensure_send_cap(self, hello_len);
        Copy(hello, self->send_buf, hello_len, char);
        self->send_len = hello_len;
        self->send_pos = 0;
        Safefree(hello);

        self->native_state = NATIVE_WAIT_HELLO;
        start_writing(self);
        return;
    }

    /* HTTP protocol: connection is ready */
    self->connected = 1;

    if (NULL != self->on_connect) {
        self->callback_depth++;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            call_sv(self->on_connect, G_DISCARD | G_EVAL);
            if (SvTRUE(ERRSV)) {
                warn("EV::ClickHouse: exception in connect handler: %s", SvPV_nolen(ERRSV));
            }
            FREETMPS;
            LEAVE;
        }
        self->callback_depth--;
        if (check_destroyed(self)) return;
    }

    /* start pipeline if queries were queued during connect */
    if (!ngx_queue_empty(&self->send_queue))
        pipeline_advance(self);
}

/* --- I/O callbacks --- */

/* Returns 1 if self was freed (caller must not access self). */
static int try_write(ev_clickhouse_t *self) {
    while (self->send_pos < self->send_len) {
        ssize_t n = ch_write(self, self->send_buf + self->send_pos,
                             self->send_len - self->send_pos);
        if (n < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                start_writing(self);
                return 0;
            }
            /* write error */
            self->callback_depth++;
            emit_error(self, strerror(errno));
            self->callback_depth--;
            if (check_destroyed(self)) return 1;
            if (cancel_pending(self, "write error")) return 1;
            cleanup_connection(self);
            return 0;
        }
        if (n == 0) {
            self->callback_depth++;
            emit_error(self, "connection closed during write");
            self->callback_depth--;
            if (check_destroyed(self)) return 1;
            if (cancel_pending(self, "connection closed")) return 1;
            cleanup_connection(self);
            return 0;
        }
        self->send_pos += n;
    }

    /* all sent */
    stop_writing(self);
    self->send_len = 0;
    self->send_pos = 0;

    /* start reading responses */
    start_reading(self);

    /* check if more to send */
    if (!ngx_queue_empty(&self->send_queue))
        return pipeline_advance(self);
    return 0;
}

static void on_readable(ev_clickhouse_t *self) {
    ssize_t n;

    ensure_recv_cap(self, self->recv_len + 4096);
    n = ch_read(self, self->recv_buf + self->recv_len,
                self->recv_cap - self->recv_len);

    if (n < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) return;
        self->callback_depth++;
        emit_error(self, strerror(errno));
        self->callback_depth--;
        if (check_destroyed(self)) return;
        if (cancel_pending(self, "read error")) return;
        cleanup_connection(self);
        return;
    }

    if (n == 0) {
        /* connection closed — fire on_error and drain pending if we
         * have an in-flight request or haven't finished handshake */
        int had_inflight = (self->send_count > 0 || !self->connected);
        int has_queued = !ngx_queue_empty(&self->send_queue);

        if (had_inflight) {
            self->callback_depth++;
            emit_error(self, "connection closed by server");
            self->callback_depth--;
            if (check_destroyed(self)) return;
            /* Only cancel in-flight cb_queue (irrecoverable).
             * Keep send_queue if auto_reconnect — those haven't been sent yet. */
            if (!self->auto_reconnect || !has_queued) {
                if (cancel_pending(self, "connection closed")) return;
            } else {
                /* Cancel only the in-flight cb_queue entries */
                while (!ngx_queue_empty(&self->cb_queue)) {
                    SV *cb = pop_cb(self);
                    if (cb == NULL) break;
                    self->callback_depth++;
                    {
                        dSP;
                        ENTER; SAVETMPS;
                        PUSHMARK(SP);
                        PUSHs(&PL_sv_undef);
                        PUSHs(sv_2mortal(newSVpv("connection closed", 0)));
                        PUTBACK;
                        invoke_cb(cb);
                        FREETMPS; LEAVE;
                    }
                    self->callback_depth--;
                    if (check_destroyed(self)) return;
                }
                self->send_count = 0;
            }
        }
        cleanup_connection(self);

        /* Auto-reconnect if we have queued requests or flag is set */
        if (self->auto_reconnect && self->host && self->magic == EV_CH_MAGIC) {
            schedule_reconnect(self);
        }
        return;
    }

    self->recv_len += n;

    if (self->protocol == PROTO_HTTP) {
        process_http_response(self);
    } else {
        process_native_response(self);
    }
}

static void io_cb(EV_P_ ev_io *w, int revents) {
    ev_clickhouse_t *self = (ev_clickhouse_t *)w->data;
    (void)loop;

    if (self == NULL || self->magic != EV_CH_MAGIC) return;

    if (self->connecting) {
        /* check connect result */
        int err = 0;
        socklen_t errlen = sizeof(err);

        if (self->timing) {
            ev_timer_stop(self->loop, &self->timer);
            self->timing = 0;
        }
        stop_writing(self);

        if (getsockopt(self->fd, SOL_SOCKET, SO_ERROR, &err, &errlen) < 0)
            err = errno;
        if (err != 0) {
            char errbuf[256];
            snprintf(errbuf, sizeof(errbuf), "connect: %s", strerror(err));
            self->callback_depth++;
            emit_error(self, errbuf);
            self->callback_depth--;
            if (check_destroyed(self)) return;
            if (cancel_pending(self, errbuf)) return;
            cleanup_connection(self);
            return;
        }

        on_connect_done(self);
        return;
    }

#ifdef HAVE_OPENSSL
    if (self->ssl && !self->connected && self->native_state != NATIVE_WAIT_HELLO
        && self->native_state != NATIVE_WAIT_RESULT
        && self->native_state != NATIVE_WAIT_INSERT_META) {
        /* TLS handshake in progress */
        int ret = SSL_connect(self->ssl);
        if (ret == 1) {
            stop_reading(self);
            stop_writing(self);

            if (self->protocol == PROTO_NATIVE) {
                /* Send ClientHello over TLS, then wait for ServerHello */
                size_t hello_len;
                char *hello = build_native_hello(self, &hello_len);
                ensure_send_cap(self, hello_len);
                Copy(hello, self->send_buf, hello_len, char);
                self->send_len = hello_len;
                self->send_pos = 0;
                Safefree(hello);
                self->native_state = NATIVE_WAIT_HELLO;
                start_writing(self);
                return;
            }

            /* HTTP protocol: fire on_connect */
            self->connected = 1;
            if (NULL != self->on_connect) {
                self->callback_depth++;
                {
                    dSP;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    PUTBACK;
                    call_sv(self->on_connect, G_DISCARD | G_EVAL);
                    if (SvTRUE(ERRSV)) {
                        warn("EV::ClickHouse: exception in connect handler: %s", SvPV_nolen(ERRSV));
                    }
                    FREETMPS;
                    LEAVE;
                }
                self->callback_depth--;
                if (check_destroyed(self)) return;
            }
            if (!ngx_queue_empty(&self->send_queue))
                pipeline_advance(self);
            return;
        } else {
            int err = SSL_get_error(self->ssl, ret);
            stop_reading(self);
            stop_writing(self);
            if (err == SSL_ERROR_WANT_READ) {
                start_reading(self);
            } else if (err == SSL_ERROR_WANT_WRITE) {
                start_writing(self);
            } else {
                self->callback_depth++;
                emit_error(self, "SSL handshake failed");
                self->callback_depth--;
                if (check_destroyed(self)) return;
                if (cancel_pending(self, "SSL handshake failed")) return;
                cleanup_connection(self);
            }
            return;
        }
    }
#endif

    if (revents & EV_WRITE) {
        if (try_write(self)) return;
        if (self->fd < 0) return;
    }

    if (revents & EV_READ) {
        on_readable(self);
    }
}

static void timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_clickhouse_t *self = (ev_clickhouse_t *)w->data;
    (void)loop;
    (void)revents;

    if (self == NULL || self->magic != EV_CH_MAGIC) return;

    self->timing = 0;

    if (self->connecting) {
        stop_writing(self);
        self->callback_depth++;
        emit_error(self, "connect timeout");
        self->callback_depth--;
        if (check_destroyed(self)) return;
        if (cancel_pending(self, "connect timeout")) return;
        cleanup_connection(self);
    } else {
        /* query timeout */
        if (self->native_rows) {
            SvREFCNT_dec((SV*)self->native_rows);
            self->native_rows = NULL;
        }
        if (self->native_col_names) {
            SvREFCNT_dec((SV*)self->native_col_names);
            self->native_col_names = NULL;
        }
        if (self->native_col_types) {
            SvREFCNT_dec((SV*)self->native_col_types);
            self->native_col_types = NULL;
        }
        lc_free_dicts(self);
        if (self->insert_data) {
            Safefree(self->insert_data);
            self->insert_data = NULL;
            self->insert_data_len = 0;
        }
        if (self->insert_av) {
            SvREFCNT_dec(self->insert_av);
            self->insert_av = NULL;
        }
        if (self->insert_err) {
            Safefree(self->insert_err);
            self->insert_err = NULL;
        }
        self->native_state = NATIVE_IDLE;
        if (self->send_count > 0) self->send_count--;

        if (deliver_error(self, "query timeout")) return;

        /* Must reconnect — server may still be processing */
        if (cancel_pending(self, "query timeout")) return;
        cleanup_connection(self);
        if (self->auto_reconnect && self->host)
            schedule_reconnect(self);
    }
}

/* --- Keepalive timer callback --- */

static void ka_timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_clickhouse_t *self = (ev_clickhouse_t *)((char *)w -
        offsetof(ev_clickhouse_t, ka_timer));
    (void)revents;

    if (self->magic != EV_CH_MAGIC) return;
    if (!self->connected || self->send_count > 0) return;

    /* Send a ping to keep the connection alive */
    if (self->protocol == PROTO_NATIVE) {
        native_buf_t pkt;
        nbuf_init(&pkt);
        nbuf_varuint(&pkt, CLIENT_PING);
        ensure_send_cap(self, self->send_len + pkt.len);
        Copy(pkt.data, self->send_buf + self->send_len, pkt.len, char);
        self->send_len += pkt.len;
        Safefree(pkt.data);
        if (!self->writing) start_writing(self);
    }
    /* HTTP: no-op ping — just rely on TCP keepalive or let the
     * connection drop and auto-reconnect handles it. */
}

static void start_keepalive(ev_clickhouse_t *self) {
    if (self->keepalive > 0 && !self->ka_timing && self->connected) {
        ev_timer_init(&self->ka_timer, ka_timer_cb, self->keepalive, self->keepalive);
        ev_timer_start(self->loop, &self->ka_timer);
        self->ka_timing = 1;
    }
}

static void stop_keepalive(ev_clickhouse_t *self) {
    if (self->ka_timing) {
        ev_timer_stop(self->loop, &self->ka_timer);
        self->ka_timing = 0;
    }
}

/* --- Reconnect with backoff --- */

static void reconnect_timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_clickhouse_t *self = (ev_clickhouse_t *)((char *)w -
        offsetof(ev_clickhouse_t, reconnect_timer));
    (void)revents; (void)loop;
    self->reconnect_timing = 0;
    if (self->magic != EV_CH_MAGIC || self->connected || self->connecting) return;
    start_connect(self);
}

static void schedule_reconnect(ev_clickhouse_t *self) {
    if (!self->auto_reconnect || !self->host || self->magic != EV_CH_MAGIC) return;
    if (self->reconnect_delay <= 0) {
        self->reconnect_attempts = 0;
        start_connect(self);
        return;
    }
    double delay = self->reconnect_delay;
    int i;
    for (i = 0; i < self->reconnect_attempts && i < 20; i++)
        delay *= 2;
    if (self->reconnect_max_delay > 0 && delay > self->reconnect_max_delay)
        delay = self->reconnect_max_delay;
    self->reconnect_attempts++;
    if (self->reconnect_timing) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timing = 0;
    }
    ev_timer_init(&self->reconnect_timer, reconnect_timer_cb, delay, 0);
    ev_timer_start(self->loop, &self->reconnect_timer);
    self->reconnect_timing = 1;
}

/* Free LowCardinality cross-block dictionary state */
static void lc_free_dicts(ev_clickhouse_t *self) {
    if (self->lc_dicts) {
        int c;
        for (c = 0; c < self->lc_num_cols; c++) {
            if (self->lc_dicts[c]) {
                uint64_t j;
                for (j = 0; j < self->lc_dict_sizes[c]; j++)
                    SvREFCNT_dec(self->lc_dicts[c][j]);
                Safefree(self->lc_dicts[c]);
            }
        }
        Safefree(self->lc_dicts);
        Safefree(self->lc_dict_sizes);
        self->lc_dicts = NULL;
        self->lc_dict_sizes = NULL;
        self->lc_num_cols = 0;
    }
}

/* --- Pipeline orchestrator --- */

/*
 * ClickHouse HTTP does not support true HTTP pipelining.
 * We send one request at a time, wait for the response, then send the next.
 */
/* Returns 1 if self was freed (caller must not access self). */
static int pipeline_advance(ev_clickhouse_t *self) {
    if (!self->connected) return 0;

    /* if we're still waiting for a response, just ensure reading */
    if (self->send_count > 0) {
        start_reading(self);
        return 0;
    }

    /* Check drain callback when all pending work is done */
    if (ngx_queue_empty(&self->send_queue) && self->pending_count == 0
        && self->on_drain) {
        SV *drain_cb = self->on_drain;
        self->on_drain = NULL;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            self->callback_depth++;
            call_sv(drain_cb, G_DISCARD | G_EVAL);
            self->callback_depth--;
            if (SvTRUE(ERRSV))
                warn("EV::ClickHouse: drain callback died: %s",
                     SvPV_nolen(ERRSV));
            FREETMPS;
            LEAVE;
        }
        SvREFCNT_dec(drain_cb);
        if (check_destroyed(self)) return 1;
    }

    /* Restart keepalive timer when idle */
    if (ngx_queue_empty(&self->send_queue) && self->pending_count == 0
        && self->keepalive > 0 && !self->ka_timing) {
        start_keepalive(self);
    }

    /* send next request from queue */
    if (!ngx_queue_empty(&self->send_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->send_queue);
        ev_ch_send_t *send = ngx_queue_data(q, ev_ch_send_t, queue);

        /* Stop keepalive during active query */
        stop_keepalive(self);
        emit_trace(self, "dispatch query (pending=%d)", self->pending_count);

        /* set up send buffer */
        ensure_send_cap(self, send->data_len);
        Copy(send->data, self->send_buf, send->data_len, char);
        self->send_len = send->data_len;
        self->send_pos = 0;

        /* move cb to recv queue */
        ngx_queue_remove(q);
        push_cb_owned_ex(self, send->cb, send->raw,
                          send->on_data, send->query_timeout);
        if (send->on_data) { SvREFCNT_dec(send->on_data); send->on_data = NULL; }
        /* Track query_id */
        if (self->last_query_id) { Safefree(self->last_query_id); self->last_query_id = NULL; }
        if (send->query_id) { self->last_query_id = send->query_id; send->query_id = NULL; }

        /* transfer deferred insert data from send entry to self */
        if (send->insert_data) {
            self->insert_data = send->insert_data;
            self->insert_data_len = send->insert_data_len;
            send->insert_data = NULL;
        }
        if (send->insert_av) {
            self->insert_av = send->insert_av;
            send->insert_av = NULL;
        }

        Safefree(send->data);
        {
            double qt = send->query_timeout;
            release_send(send);
            self->send_count++;

            /* Start query timeout timer */
            {
                double timeout = qt > 0 ? qt : self->query_timeout;
                if (timeout > 0 && !self->timing) {
                    ev_timer_set(&self->timer, (ev_tstamp)timeout, 0.0);
                    ev_timer_start(self->loop, &self->timer);
                    self->timing = 1;
                }
            }
        }

        if (self->protocol == PROTO_NATIVE) {
            if (self->insert_data || self->insert_av)
                self->native_state = NATIVE_WAIT_INSERT_META;
            else
                self->native_state = NATIVE_WAIT_RESULT;
        }

        return try_write(self);
    }
    return 0;
}

/* --- OpenSSL init (must be in plain C, not inside XS BOOT) --- */

static void ch_openssl_init(void) {
#ifdef HAVE_OPENSSL
#if OPENSSL_VERSION_NUMBER >= 0x10100000L
    OPENSSL_init_ssl(0, NULL);
#else
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();
#endif
#endif
}

/* --- XS interface --- */

MODULE = EV::ClickHouse  PACKAGE = EV::ClickHouse

BOOT:
{
    I_EV_API("EV::ClickHouse");
    ch_openssl_init();
}

EV::ClickHouse
_new(char *class, EV::Loop loop)
CODE:
{
    PERL_UNUSED_VAR(class);
    Newxz(RETVAL, 1, ev_clickhouse_t);
    RETVAL->magic = EV_CH_MAGIC;
    RETVAL->loop = loop;
    RETVAL->fd = -1;
    RETVAL->protocol = PROTO_HTTP;
    ngx_queue_init(&RETVAL->cb_queue);
    ngx_queue_init(&RETVAL->send_queue);

    Newx(RETVAL->recv_buf, RECV_BUF_INIT, char);
    RETVAL->recv_cap = RECV_BUF_INIT;
    Newx(RETVAL->send_buf, SEND_BUF_INIT, char);
    RETVAL->send_cap = SEND_BUF_INIT;

    ev_init(&RETVAL->timer, timer_cb);
    RETVAL->timer.data = (void *)RETVAL;
}
OUTPUT:
    RETVAL

void
DESTROY(EV::ClickHouse self)
CODE:
{
    if (self->magic != EV_CH_MAGIC) return;

    stop_reading(self);
    stop_writing(self);
    if (self->timing) {
        ev_timer_stop(self->loop, &self->timer);
        self->timing = 0;
    }
    if (self->ka_timing) {
        ev_timer_stop(self->loop, &self->ka_timer);
        self->ka_timing = 0;
    }
    if (self->reconnect_timing) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timing = 0;
    }

    if (PL_dirty) {
        self->magic = EV_CH_FREED;
        while (!ngx_queue_empty(&self->send_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->send_queue);
            ev_ch_send_t *send = ngx_queue_data(q, ev_ch_send_t, queue);
            ngx_queue_remove(q);
            Safefree(send->data);
            if (send->insert_data) Safefree(send->insert_data);
            if (send->insert_av) SvREFCNT_dec(send->insert_av);
            if (send->on_data) SvREFCNT_dec(send->on_data);
            SvREFCNT_dec(send->cb);
            release_send(send);
        }
        while (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            ev_ch_cb_t *cbt = ngx_queue_data(q, ev_ch_cb_t, queue);
            ngx_queue_remove(q);
            if (cbt->on_data) SvREFCNT_dec(cbt->on_data);
            SvREFCNT_dec(cbt->cb);
            release_cbt(cbt);
        }

  #ifdef HAVE_OPENSSL
        if (self->ssl) { SSL_free(self->ssl); self->ssl = NULL; }
        if (self->ssl_ctx) { SSL_CTX_free(self->ssl_ctx); self->ssl_ctx = NULL; }
  #endif
        if (self->fd >= 0) close(self->fd);
        if (self->host) Safefree(self->host);
        if (self->user) Safefree(self->user);
        if (self->password) Safefree(self->password);
        if (self->database) Safefree(self->database);
        if (self->session_id) Safefree(self->session_id);
        if (self->tls_ca_file) Safefree(self->tls_ca_file);
        if (self->server_name) Safefree(self->server_name);
        if (self->server_display_name) Safefree(self->server_display_name);
        if (self->server_timezone) Safefree(self->server_timezone);
        if (self->native_rows) { SvREFCNT_dec((SV*)self->native_rows); self->native_rows = NULL; }
        if (self->native_col_names) { SvREFCNT_dec((SV*)self->native_col_names); self->native_col_names = NULL; }
        if (self->native_col_types) { SvREFCNT_dec((SV*)self->native_col_types); self->native_col_types = NULL; }
        if (self->native_totals) { SvREFCNT_dec((SV*)self->native_totals); self->native_totals = NULL; }
        if (self->native_extremes) { SvREFCNT_dec((SV*)self->native_extremes); self->native_extremes = NULL; }
        if (self->default_settings) { SvREFCNT_dec((SV*)self->default_settings); self->default_settings = NULL; }
        if (self->on_disconnect) { SvREFCNT_dec(self->on_disconnect); self->on_disconnect = NULL; }
        if (self->on_drain) { SvREFCNT_dec(self->on_drain); self->on_drain = NULL; }
        if (self->on_trace) { SvREFCNT_dec(self->on_trace); self->on_trace = NULL; }
        if (self->last_query_id) Safefree(self->last_query_id);
        if (self->ka_timing) { ev_timer_stop(self->loop, &self->ka_timer); self->ka_timing = 0; }
        if (self->insert_data) Safefree(self->insert_data);
        if (self->insert_av) SvREFCNT_dec(self->insert_av);
        if (self->insert_err) Safefree(self->insert_err);
        if (self->recv_buf) Safefree(self->recv_buf);
        if (self->send_buf) Safefree(self->send_buf);
        Safefree(self);
        return;
    }

    if (cancel_pending(self, "object destroyed"))
        return;  /* inner DESTROY already freed self */

  #ifdef HAVE_OPENSSL
    if (self->ssl) {
        SSL_shutdown(self->ssl);
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

    self->loop = NULL;
    self->connected = 0;

    if (NULL != self->on_connect) {
        SvREFCNT_dec(self->on_connect);
        self->on_connect = NULL;
    }
    if (NULL != self->on_error) {
        SvREFCNT_dec(self->on_error);
        self->on_error = NULL;
    }
    if (NULL != self->on_progress) {
        SvREFCNT_dec(self->on_progress);
        self->on_progress = NULL;
    }
    if (NULL != self->on_disconnect) {
        SvREFCNT_dec(self->on_disconnect);
        self->on_disconnect = NULL;
    }
    if (NULL != self->on_drain) {
        SvREFCNT_dec(self->on_drain);
        self->on_drain = NULL;
    }
    if (NULL != self->on_trace) {
        SvREFCNT_dec(self->on_trace);
        self->on_trace = NULL;
    }
    if (self->last_query_id) { Safefree(self->last_query_id); self->last_query_id = NULL; }
    if (self->host) { Safefree(self->host); self->host = NULL; }
    if (self->user) { Safefree(self->user); self->user = NULL; }
    if (self->password) { Safefree(self->password); self->password = NULL; }
    if (self->database) { Safefree(self->database); self->database = NULL; }
    if (self->session_id) { Safefree(self->session_id); self->session_id = NULL; }
    if (self->tls_ca_file) { Safefree(self->tls_ca_file); self->tls_ca_file = NULL; }
    if (self->server_name) { Safefree(self->server_name); self->server_name = NULL; }
    if (self->server_display_name) { Safefree(self->server_display_name); self->server_display_name = NULL; }
    if (self->server_timezone) { Safefree(self->server_timezone); self->server_timezone = NULL; }
    if (self->native_rows) { SvREFCNT_dec((SV*)self->native_rows); self->native_rows = NULL; }
    if (self->native_col_names) { SvREFCNT_dec((SV*)self->native_col_names); self->native_col_names = NULL; }
    if (self->native_col_types) { SvREFCNT_dec((SV*)self->native_col_types); self->native_col_types = NULL; }
    if (self->native_totals) { SvREFCNT_dec((SV*)self->native_totals); self->native_totals = NULL; }
    if (self->native_extremes) { SvREFCNT_dec((SV*)self->native_extremes); self->native_extremes = NULL; }
    lc_free_dicts(self);
    if (self->default_settings) { SvREFCNT_dec((SV*)self->default_settings); self->default_settings = NULL; }
    if (self->insert_data) { Safefree(self->insert_data); self->insert_data = NULL; }
    if (self->insert_av) { SvREFCNT_dec(self->insert_av); self->insert_av = NULL; }
    if (self->insert_err) { Safefree(self->insert_err); self->insert_err = NULL; }
    if (self->recv_buf) { Safefree(self->recv_buf); self->recv_buf = NULL; }
    if (self->send_buf) { Safefree(self->send_buf); self->send_buf = NULL; }

    self->magic = EV_CH_FREED;
    if (self->callback_depth == 0) {
        Safefree(self);
    }
    /* else: check_destroyed() will Safefree when callback_depth reaches 0 */
}

void
_set_tls_ca_file(EV::ClickHouse self, const char *path)
CODE:
{
    if (self->tls_ca_file) Safefree(self->tls_ca_file);
    self->tls_ca_file = safe_strdup(path);
}

void
connect(EV::ClickHouse self, const char *host, unsigned int port, const char *user, const char *password, const char *database)
CODE:
{
    if (self->connected || self->connecting) {
        croak("already connected");
    }
    if (has_http_unsafe_chars(host) || has_http_unsafe_chars(user) ||
        has_http_unsafe_chars(password) || has_http_unsafe_chars(database)) {
        croak("connection parameters must not contain CR or LF");
    }

    if (self->host) Safefree(self->host);
    if (self->user) Safefree(self->user);
    if (self->password) Safefree(self->password);
    if (self->database) Safefree(self->database);

    self->host = safe_strdup(host);
    self->port = port;
    self->user = safe_strdup(user);
    self->password = safe_strdup(password);
    self->database = safe_strdup(database);

    start_connect(self);
}

void
reset(EV::ClickHouse self)
CODE:
{
    if (NULL == self->host) {
        croak("no previous connection to reset");
    }

    if (cancel_pending(self, "connection reset")) return;
    cleanup_connection(self);
    start_connect(self);
}

void
finish(EV::ClickHouse self)
CODE:
{
    if (cancel_pending(self, "connection finished")) return;
    cleanup_connection(self);
}

void
query(EV::ClickHouse self, SV *sql_sv, ...)
CODE:
{
    STRLEN sql_len;
    const char *sql;
    ev_ch_send_t *s;
    char *req;
    size_t req_len;
    SV *cb;
    HV *settings = NULL;
    int raw = 0;

    if (items == 3) {
        cb = ST(2);
    } else if (items == 4) {
        if (!(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV))
            croak("settings must be a HASH reference");
        settings = (HV *)SvRV(ST(2));
        cb = ST(3);
    } else {
        croak("Usage: $ch->query($sql, [\\%%settings], $cb)");
    }

    if (!self->connected && !self->connecting) {
        croak("not connected");
    }
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) {
        croak("callback must be a CODE reference");
    }

    if (self->protocol == PROTO_NATIVE && (self->insert_data || self->insert_av)) {
        croak("cannot queue native query while INSERT is pending");
    }

    /* Extract client-side options from settings */
    SV *on_data_sv = NULL;
    double query_timeout = 0;
    HV *settings_copy = NULL;  /* owned copy if we need to expand params */
    if (settings) {
        SV **svp;
        /* Expand params => { x => 1 } to param_x => '1' in a copy */
        svp = hv_fetch(settings, "params", 6, 0);
        if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
            HV *phv = (HV *)SvRV(*svp);
            HE *pe;
            /* Copy settings to avoid mutating caller's hashref */
            settings_copy = newHVhv(settings);
            settings = settings_copy;
            hv_iterinit(phv);
            while ((pe = hv_iternext(phv))) {
                I32 pklen;
                char *pkey = hv_iterkey(pe, &pklen);
                SV *pval = hv_iterval(phv, pe);
                char *prefixed;
                Newx(prefixed, pklen + 7, char);
                Copy("param_", prefixed, 6, char);
                Copy(pkey, prefixed + 6, pklen, char);
                (void)hv_store(settings, prefixed, pklen + 6,
                               newSVsv(pval), 0);
                Safefree(prefixed);
            }
        }
        svp = hv_fetch(settings, "raw", 3, 0);
        if (svp)
            raw = SvTRUE(*svp) ? 1 : 0;
        svp = hv_fetch(settings, "on_data", 7, 0);
        if (svp && SvOK(*svp) && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV)
            on_data_sv = *svp;
        svp = hv_fetch(settings, "query_timeout", 13, 0);
        if (svp && SvOK(*svp))
            query_timeout = SvNV(*svp);
    }

    sql = SvPV(sql_sv, sql_len);

    if (raw && self->protocol == PROTO_NATIVE) {
        if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
        croak("raw mode is only supported with the HTTP protocol");
    }

    if (on_data_sv && self->protocol == PROTO_HTTP) {
        if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
        croak("on_data is only supported with the native protocol");
    }

    if (self->protocol == PROTO_HTTP) {
        req = build_http_query_request(self, sql, sql_len, self->compress,
                                        self->default_settings, settings,
                                        &req_len);
    } else {
        req = build_native_query(self, sql, sql_len,
                                  self->default_settings, settings, &req_len);
    }

    s = alloc_send();
    s->data = req;
    s->data_len = req_len;
    s->raw = raw;
    if (on_data_sv) s->on_data = SvREFCNT_inc(on_data_sv);
    s->query_timeout = query_timeout;
    if (settings) {
        SV **qid = hv_fetch(settings, "query_id", 8, 0);
        if (qid && SvOK(*qid)) {
            STRLEN qlen;
            const char *qstr = SvPV(*qid, qlen);
            Newx(s->query_id, qlen + 1, char);
            Copy(qstr, s->query_id, qlen, char);
            s->query_id[qlen] = '\0';
        }
    }
    s->cb = SvREFCNT_inc(cb);
    if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
    ngx_queue_insert_tail(&self->send_queue, &s->queue);
    self->pending_count++;

    if (self->connected && self->callback_depth == 0)
        pipeline_advance(self);
}

void
insert(EV::ClickHouse self, SV *table_sv, SV *data_sv, ...)
CODE:
{
    STRLEN table_len;
    const char *table;
    ev_ch_send_t *s;
    char *req;
    size_t req_len;
    SV *cb;
    HV *settings = NULL;
    int data_is_av = 0;
    AV *data_av = NULL;

    if (items == 4) {
        cb = ST(3);
    } else if (items == 5) {
        if (!(SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVHV))
            croak("settings must be a HASH reference");
        settings = (HV *)SvRV(ST(3));
        cb = ST(4);
    } else {
        croak("Usage: $ch->insert($table, $data, [\\%%settings], $cb)");
    }

    if (!self->connected && !self->connecting) {
        croak("not connected");
    }
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) {
        croak("callback must be a CODE reference");
    }

    table = SvPV(table_sv, table_len);

    /* Detect arrayref-of-arrayrefs vs TSV string */
    if (SvROK(data_sv) && SvTYPE(SvRV(data_sv)) == SVt_PVAV) {
        data_is_av = 1;
        data_av = (AV *)SvRV(data_sv);
    }

    if (self->protocol == PROTO_HTTP) {
        STRLEN data_len;
        const char *data;
        char *tsv_buf = NULL;

        if (data_is_av) {
            tsv_buf = serialize_av_to_tsv(aTHX_ data_av, &data_len);
            data = tsv_buf;
        } else {
            data = SvPV(data_sv, data_len);
        }

        req = build_http_insert_request(self, table, table_len,
                                         data, data_len, self->compress,
                                         self->default_settings, settings,
                                         &req_len);
        if (tsv_buf) Safefree(tsv_buf);
    } else {
        /* Native insert: two-phase approach.
         * Phase 1: send INSERT query without inline data, receive sample block.
         * Phase 2: encode data as binary columnar Data block, send compressed. */
        char *insert_sql;
        size_t insert_sql_len;

        /* Only one native INSERT at a time */
        if (self->insert_data || self->insert_av) {
            croak("cannot pipeline native INSERT: previous INSERT still pending");
        }

        /* Build: "INSERT INTO table FORMAT TabSeparated" (no inline data) */
        Newx(insert_sql, table_len + 64, char);
        insert_sql_len = snprintf(insert_sql, table_len + 64,
                                   "INSERT INTO %.*s FORMAT TabSeparated",
                                   (int)table_len, table);
        req = build_native_query(self, insert_sql, insert_sql_len,
                                  self->default_settings, settings, &req_len);
        Safefree(insert_sql);
    }

    s = alloc_send();
    s->data = req;
    s->data_len = req_len;
    if (settings) {
        SV **qid = hv_fetch(settings, "query_id", 8, 0);
        if (qid && SvOK(*qid)) {
            STRLEN qlen;
            const char *qstr = SvPV(*qid, qlen);
            Newx(s->query_id, qlen + 1, char);
            Copy(qstr, s->query_id, qlen, char);
            s->query_id[qlen] = '\0';
        }
    }

    /* For native INSERT, store data in the send entry (deferred to dispatch).
     * Even empty data needs the two-phase INSERT protocol to send an empty
     * DATA block. */
    if (self->protocol == PROTO_NATIVE) {
        if (data_is_av) {
            s->insert_av = SvREFCNT_inc(data_sv);
        } else {
            STRLEN data_len;
            const char *data = SvPV(data_sv, data_len);
            Newx(s->insert_data, data_len > 0 ? data_len : 1, char);
            if (data_len > 0)
                Copy(data, s->insert_data, data_len, char);
            s->insert_data_len = data_len;
        }
    }

    s->cb = SvREFCNT_inc(cb);
    ngx_queue_insert_tail(&self->send_queue, &s->queue);
    self->pending_count++;

    if (self->connected && self->callback_depth == 0)
        pipeline_advance(self);
}

void
ping(EV::ClickHouse self, SV *cb)
CODE:
{
    ev_ch_send_t *s;
    char *req;
    size_t req_len;

    if (!self->connected && !self->connecting) {
        croak("not connected");
    }
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) {
        croak("callback must be a CODE reference");
    }

    if (self->protocol == PROTO_HTTP) {
        req = build_http_ping_request(self, &req_len);
    } else {
        req = build_native_ping(&req_len);
    }

    s = alloc_send();
    s->data = req;
    s->data_len = req_len;
    s->cb = SvREFCNT_inc(cb);
    ngx_queue_insert_tail(&self->send_queue, &s->queue);
    self->pending_count++;

    if (self->connected && self->callback_depth == 0)
        pipeline_advance(self);
}

SV*
on_connect(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_connect, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_error(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_error, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_progress(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_progress, handler, items > 1);
}
OUTPUT:
    RETVAL

int
is_connected(EV::ClickHouse self)
CODE:
{
    RETVAL = self->connected ? 1 : 0;
}
OUTPUT:
    RETVAL

int
pending_count(EV::ClickHouse self)
CODE:
{
    RETVAL = self->pending_count;
}
OUTPUT:
    RETVAL

SV *
server_info(EV::ClickHouse self)
CODE:
{
    if (self->server_name) {
        char buf[256];
        int n = snprintf(buf, sizeof(buf), "%s %u.%u.%u (revision %u)",
                         self->server_name,
                         self->server_version_major,
                         self->server_version_minor,
                         self->server_version_patch,
                         self->server_revision);
        if (n >= (int)sizeof(buf)) n = (int)sizeof(buf) - 1;
        RETVAL = newSVpvn(buf, n);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

SV *
server_version(EV::ClickHouse self)
CODE:
{
    if (self->server_name) {
        char buf[64];
        int n = snprintf(buf, sizeof(buf), "%u.%u.%u",
                         self->server_version_major,
                         self->server_version_minor,
                         self->server_version_patch);
        if (n >= (int)sizeof(buf)) n = (int)sizeof(buf) - 1;
        RETVAL = newSVpvn(buf, n);
    } else {
        RETVAL = &PL_sv_undef;
    }
}
OUTPUT:
    RETVAL

void
skip_pending(EV::ClickHouse self)
CODE:
{
    if (self->send_count > 0) {
        cleanup_connection(self);
    }
    if (self->insert_data) {
        Safefree(self->insert_data);
        self->insert_data = NULL;
        self->insert_data_len = 0;
    }
    if (self->insert_av) {
        SvREFCNT_dec(self->insert_av);
        self->insert_av = NULL;
    }
    if (self->insert_err) {
        Safefree(self->insert_err);
        self->insert_err = NULL;
    }
    if (cancel_pending(self, "skipped")) return;
}

void
_set_protocol(EV::ClickHouse self, int proto)
CODE:
{
    self->protocol = proto;
}

void
_set_compress(EV::ClickHouse self, int val)
CODE:
{
    self->compress = val;
}

void
_set_session_id(EV::ClickHouse self, const char *sid)
CODE:
{
    if (self->session_id) Safefree(self->session_id);
    self->session_id = safe_strdup(sid);
}

void
_set_connect_timeout(EV::ClickHouse self, NV val)
CODE:
{
    self->connect_timeout = val;
}

void
_set_tls(EV::ClickHouse self, int val)
CODE:
{
  #ifdef HAVE_OPENSSL
    self->tls_enabled = val;
  #else
    if (val) croak("TLS support not compiled in (OpenSSL not found)");
  #endif
}

void
_set_settings(EV::ClickHouse self, SV *href)
CODE:
{
    if (!(SvROK(href) && SvTYPE(SvRV(href)) == SVt_PVHV))
        croak("settings must be a HASH reference");
    if (self->default_settings)
        SvREFCNT_dec((SV *)self->default_settings);
    self->default_settings = (HV *)SvRV(href);
    SvREFCNT_inc((SV *)self->default_settings);
}

SV*
on_disconnect(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_disconnect, handler, items > 1);
}
OUTPUT:
    RETVAL

SV *
server_timezone(EV::ClickHouse self)
CODE:
{
    if (self->server_timezone)
        RETVAL = newSVpv(self->server_timezone, 0);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

void
_set_tls_skip_verify(EV::ClickHouse self, int val)
CODE:
{
    self->tls_skip_verify = val;
}

void
_set_query_timeout(EV::ClickHouse self, NV val)
CODE:
{
    self->query_timeout = val;
}

void
_set_auto_reconnect(EV::ClickHouse self, int val)
CODE:
{
    self->auto_reconnect = val;
}

void
_set_decode_flags(EV::ClickHouse self, unsigned int flags)
CODE:
{
    self->decode_flags = (uint32_t)flags;
}

SV *
column_names(EV::ClickHouse self)
CODE:
{
    if (self->native_col_names)
        RETVAL = newRV_inc((SV*)self->native_col_names);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
last_query_id(EV::ClickHouse self)
CODE:
{
    if (self->last_query_id)
        RETVAL = newSVpv(self->last_query_id, 0);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
last_error_code(EV::ClickHouse self)
CODE:
{
    RETVAL = newSViv(self->last_error_code);
}
OUTPUT:
    RETVAL

SV *
column_types(EV::ClickHouse self)
CODE:
{
    if (self->native_col_types)
        RETVAL = newRV_inc((SV*)self->native_col_types);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
last_totals(EV::ClickHouse self)
CODE:
{
    if (self->native_totals)
        RETVAL = newRV_inc((SV*)self->native_totals);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
last_extremes(EV::ClickHouse self)
CODE:
{
    if (self->native_extremes)
        RETVAL = newRV_inc((SV*)self->native_extremes);
    else
        RETVAL = &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
profile_rows_before_limit(EV::ClickHouse self)
CODE:
{
    RETVAL = newSVuv(self->profile_rows_before_limit);
}
OUTPUT:
    RETVAL

SV *
profile_rows(EV::ClickHouse self)
CODE:
{
    RETVAL = newSVuv(self->profile_rows);
}
OUTPUT:
    RETVAL

SV *
profile_bytes(EV::ClickHouse self)
CODE:
{
    RETVAL = newSVuv(self->profile_bytes);
}
OUTPUT:
    RETVAL

SV*
on_trace(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_trace, handler, items > 1);
}
OUTPUT:
    RETVAL

void
_set_keepalive(EV::ClickHouse self, double val)
CODE:
{
    self->keepalive = val;
}

void
_set_reconnect_delay(EV::ClickHouse self, double val)
CODE:
{
    self->reconnect_delay = val;
}

void
_set_reconnect_max_delay(EV::ClickHouse self, double val)
CODE:
{
    self->reconnect_max_delay = val;
}

void
drain(EV::ClickHouse self, SV *cb)
CODE:
{
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
        croak("drain callback must be a CODE reference");
    if (self->on_drain) SvREFCNT_dec(self->on_drain);
    if (self->pending_count == 0 && ngx_queue_empty(&self->send_queue)) {
        /* Nothing pending — fire immediately */
        self->on_drain = NULL;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            self->callback_depth++;
            call_sv(cb, G_DISCARD | G_EVAL);
            self->callback_depth--;
            if (SvTRUE(ERRSV))
                warn("EV::ClickHouse: drain callback died: %s",
                     SvPV_nolen(ERRSV));
            FREETMPS;
            LEAVE;
        }
        check_destroyed(self);
    } else {
        self->on_drain = SvREFCNT_inc(cb);
    }
}

void
cancel(EV::ClickHouse self)
CODE:
{
    if (self->protocol == PROTO_NATIVE && self->send_count > 0) {
        /* Send CLIENT_CANCEL packet */
        native_buf_t pkt;
        nbuf_init(&pkt);
        nbuf_varuint(&pkt, CLIENT_CANCEL);
        ensure_send_cap(self, self->send_len + pkt.len);
        Copy(pkt.data, self->send_buf + self->send_len, pkt.len, char);
        self->send_len += pkt.len;
        Safefree(pkt.data);
        if (!self->writing) start_writing(self);
        /* We still need to wait for EndOfStream or Exception from server */
    } else if (self->protocol == PROTO_HTTP && self->send_count > 0) {
        /* HTTP: close connection to cancel */
        if (self->native_rows) {
            SvREFCNT_dec((SV*)self->native_rows);
            self->native_rows = NULL;
        }
        if (cancel_pending(self, "query cancelled")) return;
        cleanup_connection(self);
        if (self->auto_reconnect && self->host)
            schedule_reconnect(self);
    }
}
