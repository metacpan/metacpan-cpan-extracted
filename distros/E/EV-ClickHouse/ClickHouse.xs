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
/* CH_CLIENT_REVISION is the protocol revision we negotiate. Bumping it
 * unlocks server features (extra Progress fields, parallel-replica
 * extensions, quota-key handshake additions, …) but each step requires
 * matching client-side handling, otherwise the server starts sending
 * fields we'd misframe. 54459 is the conservative anchor that lights up
 * everything we currently parse. */
#define CH_CLIENT_REVISION 54459

/* Protocol revision thresholds */
#define DBMS_MIN_REVISION_WITH_BLOCK_INFO          51903
#define DBMS_MIN_REVISION_WITH_SERVER_DISPLAY_NAME 54372
#define DBMS_MIN_REVISION_WITH_VERSION_PATCH       54401
#define DBMS_MIN_REVISION_WITH_PROGRESS_WRITES     54420
#define DBMS_MIN_REVISION_WITH_SERVER_TIMEZONE     54423
#define DBMS_MIN_PROTOCOL_VERSION_WITH_ADDENDUM    54458

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
#define SERVER_TIMEZONE_UPDATE  17

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
    int dns_pending;            /* set while EV::cares is resolving the host;
                                   query()/insert()/ping() queue against this
                                   state so calls between new() and connect
                                   don't croak with "not connected" */
    unsigned int connect_gen;   /* bumped by every start_connect; lets
                                   fail_connection notice when the user
                                   started a new connect from on_error */
    int protocol;               /* PROTO_HTTP or PROTO_NATIVE */

#ifdef HAVE_OPENSSL
    SSL_CTX *ssl_ctx;
    SSL *ssl;
#endif
    int tls_enabled;
    char *tls_ca_file;
    char *tls_cert_file;            /* client certificate (mutual TLS) */
    char *tls_key_file;             /* client private key (mutual TLS) */

    /* connection params */
    char *host, *user, *password, *database;
    unsigned int port;

    /* send/recv buffers */
    char *send_buf;
    size_t send_len, send_pos, send_cap;
    char *recv_buf;
    size_t recv_len, recv_cap;
    char *http_decoded;         /* chunked body accumulated so far (NULL = none) */
    size_t http_decoded_len;
    size_t http_decoded_cap;
    size_t http_chunk_off;      /* offset into recv_buf of next unparsed chunk hdr */
    int http_chunk_active;      /* 1 = a partially decoded chunked body is held */

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
    char *query_log_comment;        /* prepended as a SQL block comment per query */
    int compress;
    double connect_timeout;
    HV *default_settings;           /* connection-level ClickHouse settings */

    SV *on_connect;
    SV *on_error;
    SV *on_progress;
    SV *on_disconnect;
    SV *on_query_complete;          /* fires after each query (success or error) */
    SV *on_query_start;             /* fires when a query is dispatched */
    SV *on_log;                     /* native SERVER_LOG packets */
    SV *on_failover;                /* multi-host: ($oh, $op, $nh, $np, $msg) */
    char *last_tls_error;           /* OpenSSL error from last failed handshake */
    char    **failover_hosts;       /* parallel arrays: hosts + ports.        */
    unsigned int *failover_ports;   /* NULL if multi-host failover disabled.  */
    int       failover_n;
    int       failover_idx;
    unsigned int failover_default_port;
    double query_start_time;        /* ev_now() captured in pipeline_advance */
    int tls_skip_verify;
    double query_timeout;
    size_t max_query_size;          /* 0 = unlimited; client-side croak guard */
    size_t max_recv_buffer;         /* 0 = unlimited; defensive recv ceiling */
    int http_basic_auth;            /* 0=X-ClickHouse-{User,Key} (default);
                                     * 1=Authorization: Basic ... (for proxies) */
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
    double reconnect_jitter;        /* fractional [0, 1+]: actual delay
                                       picks uniformly in [d, d*(1+jitter)] */
    int reconnect_attempts;
    int reconnect_max_attempts;   /* 0 = unlimited */
    int pending_addendum_finish;  /* set when addendum partially written;
                                   * io_cb completes finish_connect after drain */
    ev_timer reconnect_timer;
    int reconnect_timing;
    /* on_progress throttling (0 = fire every packet) */
    double progress_period;
    double progress_last;          /* ev_now() of last on_progress dispatch */
    uint64_t progress_acc[5];      /* coalesced totals since last dispatch */
    /* LowCardinality cross-block dictionary state */
    SV ***lc_dicts;           /* array of dictionaries, one per column */
    uint64_t *lc_dict_sizes;  /* size of each dictionary */
    int lc_num_cols;          /* number of columns with LC state */
};

struct ev_ch_cb_s {
    SV          *cb;
    int          raw;        /* return raw response body instead of parsed rows */
    SV          *on_data;    /* per-query streaming callback (fires per block) */
    SV          *on_complete;/* per-query on_query_complete override (or NULL) */
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
    SV          *on_complete;    /* per-query on_query_complete override */
    double       query_timeout;  /* per-query timeout */
    char        *query_id;       /* query_id for tracking */
    ngx_queue_t  queue;
};

/* Forward declarations for helpers defined further down (or in xs/io.c)
 * but called from earlier code in this file or from xs/*.c included
 * before the definition site. */
static void timer_cb(EV_P_ ev_timer *w, int revents);
static void stop_keepalive(ev_clickhouse_t *self);
static void schedule_reconnect(ev_clickhouse_t *self);
static void lc_free_dicts(ev_clickhouse_t *self);
static void start_reading(ev_clickhouse_t *self);
static void stop_reading(ev_clickhouse_t *self);
static void start_writing(ev_clickhouse_t *self);
static void stop_writing(ev_clickhouse_t *self);
static void emit_error(ev_clickhouse_t *self, const char *msg);
static void emit_trace(ev_clickhouse_t *self, const char *fmt, ...);
static int cleanup_connection(ev_clickhouse_t *self);
static int  cancel_pending(ev_clickhouse_t *self, const char *errmsg);
static int  check_destroyed(ev_clickhouse_t *self);
static char *safe_strdup(const char *s);
static void failover_free(ev_clickhouse_t *self);
static int  finish_connect(ev_clickhouse_t *self);
static int  try_write(ev_clickhouse_t *self);
static int  pipeline_advance(ev_clickhouse_t *self);

/* Two helpers shared between the PL_dirty and normal arms of DESTROY:
 * adding a new on_* slot or persistent string requires touching only
 * one place. on_failover is omitted from CONNECTION_HANDLERS because
 * failover_free() handles it together with the host ring. */
#define CLEAR_CONNECTION_HANDLERS(self) do { \
    CLEAR_SV((self)->on_connect); \
    CLEAR_SV((self)->on_error); \
    CLEAR_SV((self)->on_progress); \
    CLEAR_SV((self)->on_disconnect); \
    CLEAR_SV((self)->on_query_complete); \
    CLEAR_SV((self)->on_query_start); \
    CLEAR_SV((self)->on_log); \
    CLEAR_SV((self)->on_drain); \
    CLEAR_SV((self)->on_trace); \
} while (0)

#define CLEAR_PERSISTENT_STATE(self) do { \
    CLEAR_STR((self)->last_tls_error); \
    CLEAR_STR((self)->last_query_id); \
    CLEAR_STR((self)->host); \
    CLEAR_STR((self)->user); \
    CLEAR_STR((self)->password); \
    CLEAR_STR((self)->database); \
    CLEAR_STR((self)->session_id); \
    CLEAR_STR((self)->query_log_comment); \
    CLEAR_STR((self)->tls_ca_file); \
    CLEAR_STR((self)->tls_cert_file); \
    CLEAR_STR((self)->tls_key_file); \
    CLEAR_STR((self)->server_name); \
    CLEAR_STR((self)->server_display_name); \
    CLEAR_STR((self)->server_timezone); \
    CLEAR_STR((self)->insert_err); \
    CLEAR_STR((self)->recv_buf); \
    CLEAR_STR((self)->http_decoded); \
    CLEAR_STR((self)->send_buf); \
    CLEAR_SV((self)->native_rows); \
    CLEAR_SV((self)->native_col_names); \
    CLEAR_SV((self)->native_col_types); \
    CLEAR_SV((self)->native_totals); \
    CLEAR_SV((self)->native_extremes); \
    CLEAR_SV((self)->default_settings); \
} while (0)

#include "xs/macros.h"
#include "xs/queues.c"

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

static void stop_timing(ev_clickhouse_t *self) {
    if (self->timing) {
        ev_timer_stop(self->loop, &self->timer);
        self->timing = 0;
    }
}

static int check_destroyed(ev_clickhouse_t *self) {
    if (self->magic == EV_CH_FREED && self->callback_depth == 0) {
        Safefree(self);
        return 1;
    }
    return 0;
}

/* Free the per-connection failover host list (allocated by setter). */
/* Free just the host-list arrays. Called from _set_failover before
 * re-populating + from failover_free below. Keeps on_failover alive. */
static void failover_free_hosts(ev_clickhouse_t *self) {
    if (self->failover_hosts) {
        for (int i = 0; i < self->failover_n; i++)
            if (self->failover_hosts[i]) Safefree(self->failover_hosts[i]);
        Safefree(self->failover_hosts);
        self->failover_hosts = NULL;
    }
    if (self->failover_ports) {
        Safefree(self->failover_ports);
        self->failover_ports = NULL;
    }
    self->failover_n   = 0;
    self->failover_idx = 0;
}

/* Full failover-state teardown including the on_failover SV. DESTROY only. */
static void failover_free(ev_clickhouse_t *self) {
    failover_free_hosts(self);
    if (self->on_failover) {
        SvREFCNT_dec(self->on_failover);
        self->on_failover = NULL;
    }
}

/* Word-boundary case-insensitive match against the failover-trigger
 * keyword set. Used by emit_error to decide whether to rotate the
 * multi-host ring. Returns 1 on match, 0 otherwise. */
static int failover_msg_match(const char *msg) {
    static const char *KEYWORDS[] = {
        "connect", "refused", "timeout", "unreachable", "route",
        "reset", "closed", "broken", "down", "dns", "resolution",
        "getaddrinfo", NULL,
    };
    if (!msg) return 0;
    for (const char **k = KEYWORDS; *k; k++) {
        size_t kl = strlen(*k);
        const char *p = msg;
        for (;;) {
            const char *m = NULL;
            for (const char *q = p; *q; q++) {
                if (strncasecmp(q, *k, kl) == 0) { m = q; break; }
            }
            if (!m) break;
            int boundary_l = (m == msg) || !isalnum((unsigned char)m[-1]);
            int boundary_r = !isalnum((unsigned char)m[kl]);
            if (boundary_l && boundary_r) return 1;
            p = m + 1;
        }
    }
    return 0;
}

/* Advance failover ring + fire on_failover callback (if set). Caller is
 * responsible for callback_depth bookkeeping. */
static void failover_advance(ev_clickhouse_t *self, const char *msg) {
    if (!self->failover_hosts || self->failover_n <= 0) return;
    if (!failover_msg_match(msg)) return;
    char *old_host = self->host ? safe_strdup(self->host) : NULL;
    unsigned int old_port = self->port;
    self->failover_idx = (self->failover_idx + 1) % self->failover_n;
    CLEAR_STR(self->host);
    self->host = safe_strdup(self->failover_hosts[self->failover_idx]);
    self->port = self->failover_ports[self->failover_idx];
    if (self->on_failover) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(old_host ? sv_2mortal(newSVpv(old_host, 0)) : &PL_sv_undef);
        mXPUSHu(old_port);
        XPUSHs(sv_2mortal(newSVpv(self->host, 0)));
        mXPUSHu(self->port);
        XPUSHs(sv_2mortal(newSVpv(msg ? msg : "", 0)));
        PUTBACK;
        PINNED_CALL_SV(self->on_failover, G_DISCARD | G_EVAL);
        WARN_AND_CLEAR_ERRSV("on_failover");
        FREETMPS; LEAVE;
    }
    if (old_host) Safefree(old_host);
}

static void emit_error(ev_clickhouse_t *self, const char *msg) {
    /* Guard callback_depth across BOTH dispatches: failover_advance can
     * fire on_failover, and a user reset/finish from there must not
     * cause Safefree(self) before emit_error finishes its own work.
     * Caller must invoke check_destroyed() afterwards. */
    self->callback_depth++;
    failover_advance(self, msg);
    if (!self->on_error) goto done;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(msg, 0)));
        PUTBACK;

        PINNED_CALL_SV(self->on_error, G_DISCARD | G_EVAL);
        WARN_AND_CLEAR_ERRSV("error handler");

        FREETMPS;
        LEAVE;
    }
done:
    self->callback_depth--;
}

/* emit_error + cancel_pending + cleanup_connection. Returns 1 if self was
 * freed; on 0 the connection is still gone, so caller should return either way.
 * Re-checks connect_gen after BOTH emit_error and cancel_pending so a user
 * reset() from on_error OR from any error-callback dispatched by
 * cancel_pending wins over our teardown. */
static int teardown_io_error(ev_clickhouse_t *self, const char *emit_msg,
                             const char *cancel_msg) {
    int gen = self->connect_gen;
    emit_error(self, emit_msg);
    if (check_destroyed(self)) return 1;
    if (self->connect_gen != gen) return 0;
    if (cancel_pending(self, cancel_msg)) return 1;
    if (self->connect_gen != gen) return 0;
    return cleanup_connection(self);   /* 1 if on_disconnect freed self */
}

static int fail_connection(ev_clickhouse_t *self, const char *msg) {
    int gen = self->connect_gen;
    if (teardown_io_error(self, msg, msg)) return 1;
    /* gen mismatch means user reset() inside a callback — don't override
     * their new connect with an auto-reconnect. */
    if (self->connect_gen == gen && self->auto_reconnect && self->host)
        schedule_reconnect(self);
    return 0;
}

/* Invoke a zero-argument callback (on_connect, on_disconnect, on_drain).
 * Self-guards callback_depth and consumes ERRSV; caller decides whether to
 * SvREFCNT_dec the captured cb. Returns 1 if self was freed. */
static int fire_zero_arg_cb(ev_clickhouse_t *self, SV *cb, const char *what) {
    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        PINNED_CALL_SV(cb, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) {
            warn("EV::ClickHouse: exception in %s handler: %s",
                 what, SvPV_nolen(ERRSV));
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
    return check_destroyed(self);
}

static void emit_trace(ev_clickhouse_t *self, const char *fmt, ...) {
    char buf[512];
    va_list ap;
    if (!self->on_trace) return;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);

    /* Guard callback_depth; deliberately skip check_destroyed because most
     * callers continue to use self after emit_trace — outer check_destroyed
     * picks up the EV_CH_FREED state on the next opportunity. */
    self->callback_depth++;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv(buf, 0)));
        PUTBACK;
        PINNED_CALL_SV(self->on_trace, G_DISCARD | G_EVAL);
        WARN_AND_CLEAR_ERRSV("trace handler");
        FREETMPS;
        LEAVE;
    }
    self->callback_depth--;
}

/* Pop the head cb_queue entry. If `out_on_complete` is non-NULL, the
 * per-query on_query_complete override (if any) is moved into *out_on_complete
 * with ownership transferred to the caller (caller must SvREFCNT_dec). */
static SV* pop_cb_ex(ev_clickhouse_t *self, SV **out_on_complete) {
    ngx_queue_t *q;
    ev_ch_cb_t *cbt;
    SV *cb;

    if (out_on_complete) *out_on_complete = NULL;
    if (ngx_queue_empty(&self->cb_queue)) return NULL;

    q = ngx_queue_head(&self->cb_queue);
    cbt = ngx_queue_data(q, ev_ch_cb_t, queue);

    cb = cbt->cb;
    CLEAR_SV(cbt->on_data);
    if (out_on_complete) {
        *out_on_complete = cbt->on_complete;   /* transfer ownership */
        cbt->on_complete = NULL;
    } else {
        CLEAR_SV(cbt->on_complete);
    }
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
    WARN_AND_CLEAR_ERRSV("callback");
    SvREFCNT_dec(cb);
}

/* Invoke `cb` with (undef, errmsg). Caller manages callback_depth. */
static void invoke_err_cb(SV *cb, const char *errmsg) {
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

/* Fire on_query_complete with (query_id, rows, bytes, error_code, duration_s, errmsg).
 * Caller must guard callback_depth around any invoke that follows. Safe to
 * call when on_query_complete is unset. `override` (when non-NULL) is the
 * per-query override hook from the settings hashref; it REPLACES the
 * connection-level handler for this query so per-query instrumentation
 * doesn't double-count against global metrics. */
static void fire_on_query_complete_ex(ev_clickhouse_t *self, const char *errmsg,
                                       SV *override) {
    SV *target = override ? override : self->on_query_complete;
    if (!target) return;
    double dur = self->query_start_time > 0
               ? ev_now(self->loop) - self->query_start_time : 0.0;
    self->callback_depth++;
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 6);
        PUSHs(self->last_query_id
              ? sv_2mortal(newSVpv(self->last_query_id, 0)) : &PL_sv_undef);
        PUSHs(sv_2mortal(newSVuv(self->profile_rows)));
        PUSHs(sv_2mortal(newSVuv(self->profile_bytes)));
        PUSHs(sv_2mortal(newSViv(self->last_error_code)));
        PUSHs(sv_2mortal(newSVnv(dur)));
        PUSHs(errmsg ? sv_2mortal(newSVpv(errmsg, 0)) : &PL_sv_undef);
        PUTBACK;
        PINNED_CALL_SV(target, G_DISCARD | G_EVAL);
        WARN_AND_CLEAR_ERRSV("on_query_complete");
        FREETMPS; LEAVE;
    }
    self->callback_depth--;
    /* Reset so a subsequent fire for a never-dispatched cancelled
     * query (e.g. from cancel_pending draining send_queue) sees
     * query_start_time == 0 and reports dur = 0.0, not a stale
     * duration carried over from the previous in-flight query. */
    self->query_start_time = 0;
}

/* IS_KEEPALIVE_CB is defined in xs/macros.h; keepalive_noop_cb is the
 * sentinel that backs it (declared below this comment). */

static int deliver_error(ev_clickhouse_t *self, const char *errmsg) {
    SV *oqc = NULL;
    SV *cb = pop_cb_ex(self, &oqc);
    if (cb == NULL) {
        fire_on_query_complete_ex(self, errmsg, oqc);
        if (oqc) SvREFCNT_dec(oqc);
        return check_destroyed(self);
    }

    self->callback_depth++;
    if (!IS_KEEPALIVE_CB(cb)) fire_on_query_complete_ex(self, errmsg, oqc);
    invoke_err_cb(cb, errmsg);
    if (oqc) SvREFCNT_dec(oqc);
    self->callback_depth--;
    return check_destroyed(self);
}

/* Returns 1 if self was freed. */
static int deliver_rows(ev_clickhouse_t *self, AV *rows) {
    SV *oqc = NULL;
    SV *cb = pop_cb_ex(self, &oqc);
    if (cb == NULL) {
        if (rows) SvREFCNT_dec((SV*)rows);
        fire_on_query_complete_ex(self, NULL, oqc);
        if (oqc) SvREFCNT_dec(oqc);
        return check_destroyed(self);
    }

    self->callback_depth++;
    if (!IS_KEEPALIVE_CB(cb)) fire_on_query_complete_ex(self, NULL, oqc);
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUSHs(rows ? sv_2mortal(newRV_noinc((SV*)rows)) : &PL_sv_undef);
        PUTBACK;
        invoke_cb(cb);
        FREETMPS;
        LEAVE;
    }
    if (oqc) SvREFCNT_dec(oqc);
    self->callback_depth--;
    return check_destroyed(self);
}

/* Deliver raw response body as scalar string. Returns 1 if self was freed. */
static int deliver_raw_body(ev_clickhouse_t *self, const char *data, size_t len) {
    SV *oqc = NULL;
    SV *cb = pop_cb_ex(self, &oqc);
    if (cb == NULL) {
        fire_on_query_complete_ex(self, NULL, oqc);
        if (oqc) SvREFCNT_dec(oqc);
        return check_destroyed(self);
    }

    self->callback_depth++;
    if (!IS_KEEPALIVE_CB(cb)) fire_on_query_complete_ex(self, NULL, oqc);
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
    if (oqc) SvREFCNT_dec(oqc);
    self->callback_depth--;
    return check_destroyed(self);
}

/* deliver_error + cancel_pending + cleanup_connection. Mirrors
 * teardown_io_error but for paths that consume the in-flight callback
 * (via deliver_error) rather than firing on_error. Returns 1 if self
 * was freed; on 0 the connection is gone — caller must return either
 * way. Re-checks connect_gen after BOTH dispatches so a user reset()
 * from the delivered error-cb OR from any error-cb dispatched by
 * cancel_pending wins over our teardown. */
static int teardown_after_deliver(ev_clickhouse_t *self,
                                  const char *deliver_msg,
                                  const char *cancel_msg) {
    int gen = self->connect_gen;
    if (deliver_error(self, deliver_msg)) return 1;
    if (self->connect_gen != gen) return 0;
    if (cancel_pending(self, cancel_msg)) return 1;
    if (self->connect_gen != gen) return 0;
    return cleanup_connection(self);   /* 1 if on_disconnect freed self */
}

/* on_complete refcount: caller transfers an already-owned ref (or NULL).
 * Mirror semantics: the send entry held its own SvREFCNT_inc; we adopt
 * that ref here and clear send->on_complete in the call site. */
static void push_cb_owned_ex(ev_clickhouse_t *self, SV *cb, int raw,
                              SV *on_data, SV *on_complete,
                              double query_timeout) {
    ev_ch_cb_t *cbt = alloc_cbt();
    cbt->cb = cb;
    cbt->raw = raw;
    cbt->on_data = on_data ? SvREFCNT_inc(on_data) : NULL;
    cbt->on_complete = on_complete;  /* ownership adopted */
    cbt->query_timeout = query_timeout;
    ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);
}

static SV* handler_accessor(SV **slot, SV *handler, int has_arg) {
    if (has_arg) {
        CLEAR_SV(*slot);
        if (handler && SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
            *slot = SvREFCNT_inc(handler);
        }
    }
    return *slot ? SvREFCNT_inc(*slot) : &PL_sv_undef;
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

/* Write a SQL block comment "<slashstar> <cmt> <starslash> " to buf.
 * Returns bytes written, or 0 if cmt is NULL. Both call sites reserve
 * strlen(cmt) + 7 bytes for the comment plus the 7 framing bytes. */
static size_t qlc_emit_prefix(char *buf, const char *cmt) {
    size_t cl, off = 0;
    if (!cmt) return 0;
    cl = strlen(cmt);
    memcpy(buf + off, "/* ", 3); off += 3;
    memcpy(buf + off, cmt, cl); off += cl;
    memcpy(buf + off, " */ ", 4); off += 4;
    return off;
}

static int has_http_unsafe_chars(const char *s) {
    /* XS gives us NUL-terminated C strings, so only reject CR/LF. */
    if (!s) return 0;
    for (; *s; s++)
        if (*s == '\r' || *s == '\n') return 1;
    return 0;
}

/* Drop the first `n` bytes from recv_buf, shifting any remaining bytes left. */
static inline void recv_consume(struct ev_clickhouse_s *self, size_t n) {
    /* Saturating: a user callback fired from inside the parser may
     * call reset() which zeroes recv_len; an unguarded subtract would
     * underflow size_t to a huge value and the next ch_read would write
     * past the buffer. */
    if (n >= self->recv_len) { self->recv_len = 0; return; }
    memmove(self->recv_buf, self->recv_buf + n, self->recv_len - n);
    self->recv_len -= n;
}

static void ensure_send_cap(struct ev_clickhouse_s *self, size_t need);

/* Replace send_buf content with `src` (heap-allocated, freed here). */
static inline void send_replace(struct ev_clickhouse_s *self, char *src, size_t len) {
    ensure_send_cap(self, len);
    Copy(src, self->send_buf, len, char);
    self->send_len = len;
    self->send_pos = 0;
    Safefree(src);
}

static int is_ip_literal(const char *s) {
    struct in_addr  a4;
    struct in6_addr a6;
    return (inet_pton(AF_INET, s, &a4) == 1 ||
            inet_pton(AF_INET6, s, &a6) == 1);
}

/* Tears down the socket + per-connection state, then fires on_disconnect.
 * Returns 1 if on_disconnect freed self (caller must not touch self), else 0. */
static int cleanup_connection(ev_clickhouse_t *self) {
    int was_connected = self->connected;

    if (was_connected) emit_trace(self, "disconnect");
    stop_reading(self);
    stop_writing(self);
    stop_keepalive(self);
    stop_timing(self);

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
    self->dns_pending = 0;       /* finish/reset interrupts async DNS */
    self->send_len = 0;
    self->send_pos = 0;
    self->recv_len = 0;
    if (self->http_decoded) Safefree(self->http_decoded);
    self->http_decoded = NULL;
    self->http_decoded_len = 0;
    self->http_decoded_cap = 0;
    self->http_chunk_off = 0;
    self->http_chunk_active = 0;
    self->send_count = 0;
    self->pending_addendum_finish = 0;
    self->native_state = NATIVE_IDLE;
    CLEAR_SV(self->native_rows);
    CLEAR_SV(self->native_col_names);
    CLEAR_SV(self->native_col_types);
    CLEAR_SV(self->native_totals);
    CLEAR_SV(self->native_extremes);
    lc_free_dicts(self);
    CLEAR_INSERT(self);
    CLEAR_STR(self->insert_err);

    /* Fire on_disconnect AFTER state is reset, so a handler that queues
     * new queries or calls reconnect sees clean state. The handler can
     * drop the last $ch ref (-> DESTROY); propagate that so callers
     * don't touch a freed self. */
    if (was_connected && self->on_disconnect)
        return fire_zero_arg_cb(self, self->on_disconnect, "disconnect");
    return 0;
}

/* Fire user error callback + on_query_complete (per-query override or
 * connection-level — fire_on_query_complete_ex falls back). Honors the
 * documented "fires after every query (success or error)" contract for
 * cancelled queries. oqc is consumed (refcount-dec'd) here.
 * HTTP keepalive PINGs are suppressed to match the success-path behavior:
 * users instrumenting via on_query_complete shouldn't see spurious zero-
 * row completions for pings they didn't initiate. */
static void fire_err_and_complete(ev_clickhouse_t *self, SV *cb,
                                   const char *errmsg, SV *oqc) {
    /* Fire on_query_complete BEFORE the user cb to match the order
     * used by deliver_error / deliver_rows on the normal path —
     * instrumentation observers expect the global hook to run first.
     * Keepalive PINGs are suppressed to match the success-path
     * behavior so observers don't see spurious zero-row completions. */
    if (!IS_KEEPALIVE_CB(cb))
        fire_on_query_complete_ex(self, errmsg, oqc);
    if (oqc) SvREFCNT_dec(oqc);
    /* A user error callback may drop the last ref to $ch (DESTROY runs
     * deferred while callback_depth > 0). invoke_err_cb itself is safe
     * either way — caller's outer magic check handles the next loop. */
    invoke_err_cb(cb, errmsg);
}

/* Drain in-flight cb_queue, delivering errmsg to each callback and resetting
 * send_count. Caller manages callback_depth. */
static void drain_cb_queue(ev_clickhouse_t *self, const char *errmsg) {
    while (!ngx_queue_empty(&self->cb_queue)) {
        SV *oqc = NULL;
        SV *cb = pop_cb_ex(self, &oqc);
        if (cb == NULL) break;
        fire_err_and_complete(self, cb, errmsg, oqc);
        if (self->magic != EV_CH_MAGIC) break;
    }
    self->send_count = 0;
}

/* Returns 1 if self was freed. */
static int cancel_pending(ev_clickhouse_t *self, const char *errmsg) {
    self->callback_depth++;

    while (!ngx_queue_empty(&self->send_queue)) {
        ngx_queue_t *q = ngx_queue_head(&self->send_queue);
        ev_ch_send_t *send = ngx_queue_data(q, ev_ch_send_t, queue);
        SV *cb  = send->cb;
        SV *oqc = send->on_complete;     /* transfer ownership for fire below */
        send->on_complete = NULL;
        ngx_queue_remove(q);
        Safefree(send->data);
        CLEAR_INSERT(send);
        CLEAR_SV(send->on_data);
        release_send(send);
        self->pending_count--;

        fire_err_and_complete(self, cb, errmsg, oqc);
        if (self->magic != EV_CH_MAGIC) break;
    }

    drain_cb_queue(self, errmsg);
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
    /* Guard the b->len + need sum itself: a wraparound would make the
     * loop condition false and let nbuf_append memcpy past the buffer. */
    if (need > SIZE_MAX - b->len) croak("native buffer overflow");
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
    /* len==0 with data==NULL is memcpy(dst, NULL, 0) — strict UB */
    if (len) memcpy(b->data + b->len, data, len);
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

static void nbuf_le64(native_buf_t *b, uint64_t v) {
    nbuf_grow(b, 8);
    Copy(&v, b->data + b->len, 8, char);
    b->len += 8;
}

static void nbuf_ledouble(native_buf_t *b, double d) {
    uint64_t v;
    Copy(&d, &v, 8, char);
    nbuf_le64(b, v);
}

/* Write a parameter value as a Field::dump-format quoted string.
 * ClickHouse's Field::restoreFromDump for String parses a single-quoted token
 * with backslash escaping for ' and \. Without escaping, embedded single
 * quotes truncate the value silently. */
static void nbuf_quoted_param(native_buf_t *b, const char *s, size_t len) {
    size_t i, esc = 0;
    for (i = 0; i < len; i++) if (s[i] == '\'' || s[i] == '\\') esc++;
    nbuf_varuint(b, (uint64_t)(len + esc + 2));
    nbuf_grow(b, len + esc + 2);
    b->data[b->len++] = '\'';
    if (esc == 0) {
        memcpy(b->data + b->len, s, len);
        b->len += len;
    } else {
        for (i = 0; i < len; i++) {
            if (s[i] == '\'' || s[i] == '\\') b->data[b->len++] = '\\';
            b->data[b->len++] = s[i];
        }
    }
    b->data[b->len++] = '\'';
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

/* Settings keys consumed by the client and never sent to the server. */
static int is_client_only_key(const char *key, I32 klen) {
    return (klen == 3 && memcmp(key, "raw", 3) == 0)
        || (klen == 8 && memcmp(key, "query_id", 8) == 0)
        || (klen == 7 && memcmp(key, "on_data", 7) == 0)
        || (klen == 13 && memcmp(key, "query_timeout", 13) == 0)
        || (klen == 6 && memcmp(key, "params", 6) == 0)
        || (klen == 8 && memcmp(key, "external", 8) == 0)
        || (klen == 10 && memcmp(key, "idempotent", 10) == 0)
        || (klen == 17 && memcmp(key, "on_query_complete", 17) == 0);
}

/* Upper bound on bytes needed for "&key=value" URL-encoded settings pairs. */
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

/* Write merged param_* entries as native parameters block.
 * Format: (String name, VarUInt flags=2, String quoted-value)* — name is the
 * portion after the "param_" prefix. Caller writes the empty-name terminator. */
static void write_native_params(native_buf_t *b, HV *defaults, HV *overrides) {
    HE *entry;
    if (overrides) {
        hv_iterinit(overrides);
        while ((entry = hv_iternext(overrides))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            char *val = SvPV(hv_iterval(overrides, entry), vlen);
            if (klen <= 6 || memcmp(key, "param_", 6) != 0) continue;
            nbuf_varuint(b, (uint64_t)(klen - 6));
            nbuf_append(b, key + 6, (size_t)(klen - 6));
            nbuf_varuint(b, 2);  /* flags: CUSTOM */
            nbuf_quoted_param(b, val, vlen);
        }
    }
    if (defaults) {
        hv_iterinit(defaults);
        while ((entry = hv_iternext(defaults))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            char *val;
            if (klen <= 6 || memcmp(key, "param_", 6) != 0) continue;
            if (overrides && hv_exists(overrides, key, klen)) continue;
            val = SvPV(hv_iterval(defaults, entry), vlen);
            nbuf_varuint(b, (uint64_t)(klen - 6));
            nbuf_append(b, key + 6, (size_t)(klen - 6));
            nbuf_varuint(b, 2);  /* flags: CUSTOM */
            nbuf_quoted_param(b, val, vlen);
        }
    }
}

/* Write merged settings in native protocol wire format.
 * Format per setting: String name, UInt8 is_important(0), String value.
 * Terminated by empty name string (written by caller). */
static void write_native_settings(native_buf_t *b, HV *defaults, HV *overrides) {
    HE *entry;

    if (overrides) {
        hv_iterinit(overrides);
        while ((entry = hv_iternext(overrides))) {
            I32 klen;
            STRLEN vlen;
            char *key = hv_iterkey(entry, &klen);
            char *val = SvPV(hv_iterval(overrides, entry), vlen);
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

/* Textually included so all helpers stay file-local statics and the
 * compiler sees one translation unit. Order matters: each file may
 * call into helpers defined above it, but not below. xs/io.c must
 * come last because it's the only file that reaches into every other
 * subsystem (TCP/TLS, HTTP, native, types). */
#include "xs/codecs.c"
#include "xs/proto_http.c"
#include "xs/proto_native_build.c"
#include "xs/types.c"
#include "xs/proto_native_parse.c"
#include "xs/io.c"

/* --- XS interface --- */

MODULE = EV::ClickHouse  PACKAGE = EV::ClickHouse

BOOT:
{
    I_EV_API("EV::ClickHouse");
    ch_openssl_init();
    /* Permanent no-op CV used for internal callbacks (HTTP keepalive ping). */
    keepalive_noop_cb = newRV_inc((SV*)get_cv("EV::ClickHouse::__keepalive_noop", GV_ADD));
    /* Per-process rand() seed so reconnect_jitter desynchronises forks
     * (otherwise every worker generates the same sequence and the
     * jitter is uniform across the herd, defeating its purpose). */
    srand((unsigned)time(NULL) ^ (unsigned)getpid());
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
    stop_timing(self);
    stop_keepalive(self);
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
            CLEAR_INSERT(send);
            CLEAR_SV(send->on_data);
            CLEAR_SV(send->on_complete);
            SvREFCNT_dec(send->cb);
            release_send(send);
        }
        while (!ngx_queue_empty(&self->cb_queue)) {
            ngx_queue_t *q = ngx_queue_head(&self->cb_queue);
            ev_ch_cb_t *cbt = ngx_queue_data(q, ev_ch_cb_t, queue);
            ngx_queue_remove(q);
            CLEAR_SV(cbt->on_data);
            CLEAR_SV(cbt->on_complete);
            SvREFCNT_dec(cbt->cb);
            release_cbt(cbt);
        }

  #ifdef HAVE_OPENSSL
        if (self->ssl) { SSL_free(self->ssl); self->ssl = NULL; }
        if (self->ssl_ctx) { SSL_CTX_free(self->ssl_ctx); self->ssl_ctx = NULL; }
  #endif
        if (self->fd >= 0) close(self->fd);
        CLEAR_CONNECTION_HANDLERS(self);
        CLEAR_PERSISTENT_STATE(self);
        failover_free(self);
        CLEAR_INSERT(self);
        lc_free_dicts(self);
        Safefree(self);
        return;
    }

    if (cancel_pending(self, "object destroyed"))
        return;  /* inner DESTROY already freed self */

    /* A user callback fired from cancel_pending may have called
     * $ch->reset() which re-arms watchers / opens a fresh fd.
     * Stop everything again before tearing the struct down so the
     * EV loop can't dispatch into freed memory. */
    stop_reading(self);
    stop_writing(self);
    stop_timing(self);
    stop_keepalive(self);
    if (self->reconnect_timing) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timing = 0;
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

    self->loop = NULL;
    self->connected = 0;

    CLEAR_CONNECTION_HANDLERS(self);
    CLEAR_PERSISTENT_STATE(self);
    failover_free(self);
    lc_free_dicts(self);
    CLEAR_INSERT(self);

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
    CLEAR_STR(self->tls_ca_file);
    self->tls_ca_file = safe_strdup(path);
}

void
_set_tls_cert_file(EV::ClickHouse self, const char *path)
CODE:
{
    CLEAR_STR(self->tls_cert_file);
    self->tls_cert_file = safe_strdup(path);
}

void
_set_tls_key_file(EV::ClickHouse self, const char *path)
CODE:
{
    CLEAR_STR(self->tls_key_file);
    self->tls_key_file = safe_strdup(path);
}

void
connect(EV::ClickHouse self, const char *host, unsigned int port, const char *user, const char *password, const char *database)
CODE:
{
    if (self->connected || self->connecting) croak("already connected");
    if (has_http_unsafe_chars(host) || has_http_unsafe_chars(user) ||
        has_http_unsafe_chars(password) || has_http_unsafe_chars(database))
        croak("connection parameters must not contain CR or LF");

    CLEAR_STR(self->host);
    CLEAR_STR(self->user);
    CLEAR_STR(self->password);
    CLEAR_STR(self->database);

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
    if (!self->host) croak("no previous connection to reset");
    if (cancel_pending(self, "connection reset")) return;
    if (cleanup_connection(self)) return;   /* on_disconnect freed self */
    start_connect(self);
}

void
finish(EV::ClickHouse self)
CODE:
{
    if (cancel_pending(self, "connection finished")) return;
    (void)cleanup_connection(self);   /* nothing follows — freed-or-not is moot */
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

    if (!self->connected && !self->connecting && !self->dns_pending) croak("not connected");
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
        croak("callback must be a CODE reference");

    if (self->protocol == PROTO_NATIVE && (self->insert_data || self->insert_av))
        croak("cannot queue native query while INSERT is pending");

    /* Extract client-side options from settings */
    SV *on_data_sv = NULL;
    SV *on_complete_sv = NULL;
    HV *external = NULL;       /* per-query external tables (native only) */
    HV *settings_copy = NULL;  /* owned copy if we need to expand params */
    if (settings) {
        settings_copy = expand_params(aTHX_ settings);
        if (settings_copy) settings = settings_copy;
        SV **svp = hv_fetch(settings, "raw", 3, 0);
        if (svp) raw = SvTRUE(*svp) ? 1 : 0;
        svp = hv_fetch(settings, "on_data", 7, 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV)
            on_data_sv = *svp;
        svp = hv_fetch(settings, "on_query_complete", 17, 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV)
            on_complete_sv = *svp;
        svp = hv_fetch(settings, "external", 8, 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV
            && HvKEYS((HV *)SvRV(*svp)) > 0)
            external = (HV *)SvRV(*svp);
    }

    sql = SvPV(sql_sv, sql_len);

    if (self->max_query_size > 0 && sql_len > self->max_query_size) {
        if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
        croak("query size %lu exceeds max_query_size %lu",
              (unsigned long)sql_len, (unsigned long)self->max_query_size);
    }

    if (raw && self->protocol == PROTO_NATIVE) {
        if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
        croak("raw mode is only supported with the HTTP protocol");
    }

    if (on_data_sv && self->protocol == PROTO_HTTP) {
        if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
        croak("on_data is only supported with the native protocol");
    }

    if (external && self->protocol == PROTO_HTTP) {
        if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
        croak("external tables are only supported with the native protocol");
    }

    /* Optionally prepend a SQL block comment carrying query_log_comment
     * for system.query_log traceability. Connection-level setting; the
     * prefix lives for the query call only. */
    char *qlc_sql = NULL;
    if (self->query_log_comment) {
        size_t qlc_sql_len = strlen(self->query_log_comment) + sql_len + 7;
        Newx(qlc_sql, qlc_sql_len + 1, char);
        size_t off = qlc_emit_prefix(qlc_sql, self->query_log_comment);
        memcpy(qlc_sql + off, sql, sql_len);
        qlc_sql[qlc_sql_len] = '\0';
        sql = qlc_sql;
        sql_len = qlc_sql_len;
    }

    if (self->protocol == PROTO_HTTP) {
        req = build_http_post_request(self, NULL, 0, sql, sql_len,
                                       self->default_settings, settings,
                                       &req_len);
    } else {
        char *ext_data = NULL;
        size_t ext_len = 0;
        if (external) {
            char ext_errbuf[256];
            ext_errbuf[0] = '\0';
            ext_data = build_external_tables(aTHX_ self, external, &ext_len,
                                             ext_errbuf, sizeof(ext_errbuf));
            if (!ext_data) {
                if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
                if (qlc_sql) Safefree(qlc_sql);
                croak("%s", ext_errbuf);
            }
        }
        req = build_native_query(self, sql, sql_len,
                                  self->default_settings, settings,
                                  ext_data, ext_len, &req_len);
        if (ext_data) Safefree(ext_data);
    }
    if (qlc_sql) Safefree(qlc_sql);

    s = alloc_send();
    s->data = req;
    s->data_len = req_len;
    s->raw = raw;
    if (on_data_sv)     s->on_data     = SvREFCNT_inc(on_data_sv);
    if (on_complete_sv) s->on_complete = SvREFCNT_inc(on_complete_sv);
    if (settings) send_apply_settings(s, settings);
    s->cb = SvREFCNT_inc(cb);
    if (settings_copy) SvREFCNT_dec((SV*)settings_copy);
    enqueue_send(self, s);
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

    if (!self->connected && !self->connecting && !self->dns_pending) croak("not connected");
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
        croak("callback must be a CODE reference");

    table = SvPV(table_sv, table_len);

    /* Detect arrayref-of-arrayrefs vs TSV string */
    if (SvROK(data_sv) && SvTYPE(SvRV(data_sv)) == SVt_PVAV) {
        data_is_av = 1;
        data_av = (AV *)SvRV(data_sv);
    }

    /* Native two-phase INSERT can only have one in flight at a time */
    if (self->protocol == PROTO_NATIVE && (self->insert_data || self->insert_av))
        croak("cannot pipeline native INSERT: previous INSERT still pending");

    /* Validate/serialize HTTP TSV data first — serialize_av_to_tsv can croak,
     * and we don't want to leak settings_copy or insert_sql via longjmp. */
    char *tsv_buf = NULL;
    STRLEN tsv_len = 0;
    const char *http_data = NULL;
    if (self->protocol == PROTO_HTTP) {
        if (data_is_av) {
            tsv_buf = serialize_av_to_tsv(aTHX_ data_av, &tsv_len);
            http_data = tsv_buf;
        } else {
            http_data = SvPV(data_sv, tsv_len);
        }
    }

    /* Expand params => { x => 1 } to param_x => '1' AND idempotent => 1|$tok
     * to insert_deduplication_token in a single owned settings copy. */
    HV *settings_copy = NULL;
    if (settings) {
        SV **idem = hv_fetch(settings, "idempotent", 10, 0);
        settings_copy = expand_params(aTHX_ settings);
        /* `idempotent => 1` (true scalar) auto-mints a token;
         * `idempotent => "any-other-string"` is used as the literal token;
         * a falsy value (0 / "" / undef / not present) is a no-op. */
        if (idem && SvTRUE(*idem)) {
            if (!settings_copy) {
                settings_copy = newHVhv(settings);
            }
            (void)hv_delete(settings_copy, "idempotent", 10, G_DISCARD);
            STRLEN tlen = 0;
            const char *tstr = NULL;
            char tbuf[48];
            int generate = 1;
            if (SvPOK(*idem) || SvIOK(*idem) || SvNOK(*idem)) {
                tstr = SvPV(*idem, tlen);
                /* Only the literal "1" auto-generates; any other truthy
                 * stringy value is the user's own token. */
                if (!(tlen == 1 && tstr[0] == '1')) generate = 0;
            }
            if (generate) {
                static uint64_t idem_seq = 0;
                idem_seq++;
                tlen = (size_t)snprintf(tbuf, sizeof(tbuf),
                    "ev-ch-%lld-%d-%llu",
                    (long long)time(NULL), (int)getpid(),
                    (unsigned long long)idem_seq);
                tstr = tbuf;
            }
            (void)hv_store(settings_copy, "insert_deduplication_token", 26,
                           newSVpvn(tstr, tlen), 0);
        }
        /* `async_insert => 1` toggles ClickHouse server-side INSERT batching;
         * fills in wait_for_async_insert=0 unless the caller overrode it. */
        SV **async = hv_fetch(settings, "async_insert", 12, 0);
        if (async && SvTRUE(*async)) {
            if (!settings_copy) settings_copy = newHVhv(settings);
            (void)hv_store(settings_copy, "async_insert", 12, newSViv(1), 0);
            if (!hv_exists(settings_copy, "wait_for_async_insert", 21))
                (void)hv_store(settings_copy, "wait_for_async_insert", 21,
                               newSViv(0), 0);
        }
        if (settings_copy) settings = settings_copy;
    }

    /* Build "insert into table format TabSeparated" (no inline data),
     * optionally prefixed with the connection's query_log_comment so the
     * server's system.query_log shows the same tag for selects and
     * inserts (parity with the query() XSUB above). */
    size_t qlc_extra = self->query_log_comment
                     ? strlen(self->query_log_comment) + 7
                     : 0;
    char *insert_sql;
    Newx(insert_sql, table_len + qlc_extra + 64, char);
    size_t off = qlc_emit_prefix(insert_sql, self->query_log_comment);
    size_t insert_sql_len = off + (size_t)snprintf(insert_sql + off,
                               table_len + 64,
                               "insert into %.*s format TabSeparated",
                               (int)table_len, table);

    if (self->protocol == PROTO_HTTP) {
        req = build_http_post_request(self, insert_sql, insert_sql_len,
                                       http_data, tsv_len,
                                       self->default_settings, settings,
                                       &req_len);
        if (tsv_buf) Safefree(tsv_buf);
    } else {
        /* Native two-phase: phase 1 sends the query (no data), phase 2
         * sends the binary Data block once we have the sample block.
         * INSERT carries no external tables. */
        req = build_native_query(self, insert_sql, insert_sql_len,
                                  self->default_settings, settings,
                                  NULL, 0, &req_len);
    }
    Safefree(insert_sql);

    s = alloc_send();
    s->data = req;
    s->data_len = req_len;
    if (settings) send_apply_settings(s, settings);
    /* Per-query on_query_complete override: extract BEFORE freeing
     * settings_copy (matches query() XSUB pattern; otherwise the
     * hv_fetch below would read a freed HV). */
    if (settings) {
        SV **svp = hv_fetch(settings, "on_query_complete", 17, 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV)
            s->on_complete = SvREFCNT_inc(*svp);
    }
    if (settings_copy) SvREFCNT_dec((SV*)settings_copy);

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
    enqueue_send(self, s);
}

void
ping(EV::ClickHouse self, SV *cb)
CODE:
{
    ev_ch_send_t *s;
    char *req;
    size_t req_len;

    if (!self->connected && !self->connecting && !self->dns_pending) croak("not connected");
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
        croak("callback must be a CODE reference");

    if (self->protocol == PROTO_HTTP) {
        req = build_http_ping_request(self, &req_len);
    } else {
        req = build_native_ping(&req_len);
    }

    s = alloc_send();
    s->data = req;
    s->data_len = req_len;
    s->cb = SvREFCNT_inc(cb);
    enqueue_send(self, s);
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

# Snapshot of pending queries: returns arrayref of hashrefs. The
# in-flight head (if any) appears first with state => 'in_flight',
# query_id => last_query_id, age => seconds since dispatch. Queued
# entries follow in dispatch order with state => 'queued' and the
# query_id from settings (or undef if none was supplied). We only
# expose what is cheaply reachable from struct state — full SQL or
# settings hashes aren't retained after enqueue.
SV*
pending_queries(EV::ClickHouse self)
CODE:
{
    AV *out = newAV();
    if (!ngx_queue_empty(&self->cb_queue)) {
        HV *h = newHV();
        (void)hv_stores(h, "state", newSVpvs("in_flight"));
        (void)hv_stores(h, "query_id",
                        self->last_query_id
                            ? newSVpv(self->last_query_id, 0)
                            : newSV(0));
        double age = self->query_start_time > 0
                   ? ev_now(self->loop) - self->query_start_time : 0.0;
        (void)hv_stores(h, "age", newSVnv(age));
        av_push(out, newRV_noinc((SV *)h));
    }
    ngx_queue_t *q;
    for (q = ngx_queue_head(&self->send_queue);
         q != ngx_queue_sentinel(&self->send_queue);
         q = ngx_queue_next(q)) {
        ev_ch_send_t *s = ngx_queue_data(q, ev_ch_send_t, queue);
        HV *h = newHV();
        (void)hv_stores(h, "state", newSVpvs("queued"));
        (void)hv_stores(h, "query_id",
                        s->query_id ? newSVpv(s->query_id, 0) : newSV(0));
        (void)hv_stores(h, "age", newSVnv(0.0));
        av_push(out, newRV_noinc((SV *)h));
    }
    RETVAL = newRV_noinc((SV *)out);
}
OUTPUT:
    RETVAL

# Diagnostic snapshot of internal struct state — useful for debugging
# stuck connections / leaks. Returns a hashref with a small fixed set
# of fields; do NOT script against this in production (the shape may
# change between versions).
SV*
dump_state(EV::ClickHouse self)
CODE:
{
    HV *h = newHV();
    (void)hv_stores(h, "connected",       newSViv(self->connected ? 1 : 0));
    (void)hv_stores(h, "connecting",      newSViv(self->connecting ? 1 : 0));
    (void)hv_stores(h, "dns_pending",     newSViv(self->dns_pending ? 1 : 0));
    (void)hv_stores(h, "pending_count",   newSViv(self->pending_count));
    (void)hv_stores(h, "callback_depth",  newSViv(self->callback_depth));
    (void)hv_stores(h, "send_len",        newSVuv((UV)self->send_len));
    (void)hv_stores(h, "send_pos",        newSVuv((UV)self->send_pos));
    (void)hv_stores(h, "send_cap",        newSVuv((UV)self->send_cap));
    (void)hv_stores(h, "recv_len",        newSVuv((UV)self->recv_len));
    (void)hv_stores(h, "recv_cap",        newSVuv((UV)self->recv_cap));
    (void)hv_stores(h, "fd",              newSViv(self->fd));
    (void)hv_stores(h, "protocol",        newSVpv(self->protocol == PROTO_NATIVE ? "native" : "http", 0));
    (void)hv_stores(h, "server_revision", newSViv(self->server_revision));
    (void)hv_stores(h, "reconnect_attempts", newSViv(self->reconnect_attempts));
    (void)hv_stores(h, "host",
        self->host ? newSVpv(self->host, 0) : newSV(0));
    (void)hv_stores(h, "port",            newSVuv(self->port));
    (void)hv_stores(h, "send_count",      newSVuv((UV)self->send_count));
    (void)hv_stores(h, "compress",        newSViv(self->compress ? 1 : 0));
    (void)hv_stores(h, "tls",             newSViv(self->ssl ? 1 : 0));
    RETVAL = newRV_noinc((SV *)h);
}
OUTPUT:
    RETVAL

SV *
current_host(EV::ClickHouse self)
CODE:
{
    RETVAL = self->host ? newSVpv(self->host, 0) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

unsigned int
current_port(EV::ClickHouse self)
CODE:
{
    RETVAL = self->port;
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
    if (self->server_revision) {
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

UV
server_revision(EV::ClickHouse self)
CODE:
{
    RETVAL = (UV)self->server_revision;
}
OUTPUT:
    RETVAL

void
skip_pending(EV::ClickHouse self)
CODE:
{
    /* Cancel queued + in-flight callbacks first (delivers errors), then
     * tear down the socket if a request was on the wire — capture the
     * had_inflight state up front because cancel_pending zeroes send_count. */
    int had_inflight = self->send_count > 0;
    if (cancel_pending(self, "skipped")) return;
    CLEAR_INSERT(self);
    CLEAR_STR(self->insert_err);
    if (had_inflight)
        (void)cleanup_connection(self);   /* nothing follows — freed-or-not is moot */
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
    CLEAR_STR(self->session_id);
    self->session_id = safe_strdup(sid);
}

void
_set_query_log_comment(EV::ClickHouse self, const char *cmt)
CODE:
{
    CLEAR_STR(self->query_log_comment);
    self->query_log_comment = safe_strdup(cmt);
}

void
_set_host(EV::ClickHouse self, const char *host, unsigned int port)
CODE:
{
    CLEAR_STR(self->host);
    self->host = safe_strdup(host);
    self->port = port;
    /* Don't reset reconnect_attempts here — that would defeat
     * reconnect_max_attempts for failover (every host advance would
     * restart the budget). Backoff naturally widens across the rotation,
     * which is what we want when every server is unreachable. */
}

void
_set_dns_pending(EV::ClickHouse self, int v)
CODE:
{
    self->dns_pending = v ? 1 : 0;
}

int
_take_dns_pending(EV::ClickHouse self)
CODE:
{
    /* Atomically read-and-clear. Returns 1 only on the first call after
     * dns_pending was set, so the Perl DNS callback can detect a finish
     * that ran during resolution and skip the post-DNS connect. */
    RETVAL = self->dns_pending;
    self->dns_pending = 0;
}
OUTPUT:
    RETVAL

void
_set_connect_timeout(EV::ClickHouse self, NV val)
CODE:
{
    self->connect_timeout = val;
}

void
_set_tls(EV::ClickHouse self, int val)
CODE:
#ifdef HAVE_OPENSSL
    self->tls_enabled = val;
#else
    if (val) croak("TLS support not compiled in (OpenSSL not found)");
#endif

void
_set_settings(EV::ClickHouse self, SV *href)
CODE:
{
    if (!(SvROK(href) && SvTYPE(SvRV(href)) == SVt_PVHV))
        croak("settings must be a HASH reference");
    CLEAR_SV(self->default_settings);
    self->default_settings = (HV *)SvREFCNT_inc(SvRV(href));
}

SV*
on_disconnect(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_disconnect, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_query_complete(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_query_complete, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_query_start(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_query_start, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
on_log(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_log, handler, items > 1);
}
OUTPUT:
    RETVAL

SV*
last_tls_error(EV::ClickHouse self)
CODE:
{
    RETVAL = self->last_tls_error ? newSVpv(self->last_tls_error, 0) : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV*
on_failover(EV::ClickHouse self, SV *handler = NULL)
CODE:
{
    RETVAL = handler_accessor(&self->on_failover, handler, items > 1);
}
OUTPUT:
    RETVAL

void
_set_failover(EV::ClickHouse self, SV *hosts_av_ref, unsigned int default_port)
CODE:
{
    failover_free_hosts(self);
    if (!SvOK(hosts_av_ref)) return;
    if (!(SvROK(hosts_av_ref) && SvTYPE(SvRV(hosts_av_ref)) == SVt_PVAV))
        croak("_set_failover: hosts must be an arrayref");
    AV *hosts = (AV*)SvRV(hosts_av_ref);
    SSize_t n = av_top_index(hosts) + 1;
    if (n <= 0) return;
    Newx(self->failover_hosts, n, char *);
    Newx(self->failover_ports, n, unsigned int);
    self->failover_n = (int)n;
    self->failover_idx = 0;
    self->failover_default_port = default_port;
    /* Each entry is "host" or "host:port" or "[ipv6]:port". Parse here so
     * the hot emit_error path doesn't have to. */
    for (SSize_t i = 0; i < n; i++) {
        SV **e = av_fetch(hosts, i, 0);
        if (!e || !SvOK(*e)) {
            self->failover_hosts[i] = safe_strdup("");
            self->failover_ports[i] = default_port;
            continue;
        }
        STRLEN sl;
        const char *s = SvPV(*e, sl);
        unsigned int port = default_port;
        char *host = NULL;
        const char *colon;
        if (sl > 0 && s[0] == '[') {
            const char *close = (const char *)memchr(s, ']', sl);
            if (close) {
                Newx(host, close - s, char);
                memcpy(host, s + 1, close - s - 1);
                host[close - s - 1] = '\0';
                if (close + 1 < s + sl && close[1] == ':')
                    port = (unsigned int)atoi(close + 2);
            }
        }
        if (!host && (colon = (const char *)memchr(s, ':', sl))) {
            size_t hl = colon - s;
            Newx(host, hl + 1, char);
            memcpy(host, s, hl);
            host[hl] = '\0';
            port = (unsigned int)atoi(colon + 1);
        }
        if (!host) host = safe_strdup(s);
        self->failover_hosts[i] = host;
        self->failover_ports[i] = port;
    }
}

SV *
server_timezone(EV::ClickHouse self)
CODE:
{
    RETVAL = self->server_timezone ? newSVpv(self->server_timezone, 0)
                                   : &PL_sv_undef;
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
_set_max_recv_buffer(EV::ClickHouse self, UV val)
CODE:
{
    self->max_recv_buffer = (size_t)val;
}

void
_set_http_basic_auth(EV::ClickHouse self, int v)
CODE:
{
    self->http_basic_auth = v ? 1 : 0;
}

void
_set_max_query_size(EV::ClickHouse self, UV val)
CODE:
{
    self->max_query_size = (size_t)val;
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
    RETVAL = self->native_col_names ? newRV_inc((SV*)self->native_col_names)
                                    : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
last_query_id(EV::ClickHouse self)
CODE:
{
    RETVAL = self->last_query_id ? newSVpv(self->last_query_id, 0)
                                 : &PL_sv_undef;
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
    RETVAL = self->native_col_types ? newRV_inc((SV*)self->native_col_types)
                                    : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
last_totals(EV::ClickHouse self)
CODE:
{
    RETVAL = self->native_totals ? newRV_inc((SV*)self->native_totals)
                                 : &PL_sv_undef;
}
OUTPUT:
    RETVAL

SV *
last_extremes(EV::ClickHouse self)
CODE:
{
    RETVAL = self->native_extremes ? newRV_inc((SV*)self->native_extremes)
                                   : &PL_sv_undef;
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
_set_reconnect_jitter(EV::ClickHouse self, double val)
CODE:
{
    self->reconnect_jitter = val < 0 ? 0 : val;
}

void
_set_reconnect_max_attempts(EV::ClickHouse self, int val)
CODE:
{
    self->reconnect_max_attempts = val;
}

void
_set_progress_period(EV::ClickHouse self, double val)
CODE:
{
    self->progress_period = val;
}

void
drain(EV::ClickHouse self, SV *cb)
CODE:
{
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
        croak("drain callback must be a CODE reference");
    CLEAR_SV(self->on_drain);
    if (self->pending_count == 0 && ngx_queue_empty(&self->send_queue)) {
        /* Nothing pending — fire immediately */
        (void)fire_zero_arg_cb(self, cb, "drain");
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
        start_writing(self);
        /* We still need to wait for EndOfStream or Exception from server */
    } else if (self->protocol == PROTO_HTTP && self->send_count > 0) {
        /* HTTP: close connection to cancel */
        CLEAR_SV(self->native_rows);
        int gen = self->connect_gen;
        if (cancel_pending(self, "query cancelled")) return;
        if (self->connect_gen != gen) return;
        if (cleanup_connection(self)) return;   /* on_disconnect freed self */
        if (self->auto_reconnect && self->host)
            schedule_reconnect(self);
    }
}

# --- XS-resident hot-path helpers (Streamer, Pool, Iterator, breaker) ---
# Each takes the Perl object hash directly; they read/write hash slots
# from C and call back into Perl only for the cold paths (_flush,
# on_high_water; EV::run is invoked via the C API).

SV *
_streamer_push_row(SV *self_sv, SV *row)
CODE:
{
    if (!(SvROK(self_sv) && SvTYPE(SvRV(self_sv)) == SVt_PVHV))
        croak("_streamer_push_row: self must be a hash ref");
    HV *self = (HV*)SvRV(self_sv);

    SV **buf_p = hv_fetchs(self, "buffer", 0);
    if (!buf_p || !SvROK(*buf_p) || SvTYPE(SvRV(*buf_p)) != SVt_PVAV)
        croak("_streamer_push_row: buffer slot missing");
    AV *buffer = (AV*)SvRV(*buf_p);

    SV *to_push;
    if (SvROK(row) && SvTYPE(SvRV(row)) == SVt_PVHV) {
        SV **cols_p = hv_fetchs(self, "columns", 0);
        if (!cols_p || !SvROK(*cols_p) || SvTYPE(SvRV(*cols_p)) != SVt_PVAV)
            croak("push_row(\\%%hash) requires columns => [...] at insert_streamer creation");
        AV *cols = (AV*)SvRV(*cols_p);
        HV *h = (HV*)SvRV(row);
        SSize_t n = av_top_index(cols) + 1;
        AV *out = newAV();
        av_extend(out, n - 1);
        for (SSize_t i = 0; i < n; i++) {
            SV **col = av_fetch(cols, i, 0);
            if (!col) { av_push(out, newSV(0)); continue; }
            STRLEN cl;
            const char *cp = SvPV(*col, cl);
            SV **vp = hv_fetch(h, cp, cl, 0);
            av_push(out, vp ? newSVsv(*vp) : newSV(0));
        }
        to_push = newRV_noinc((SV*)out);
    } else {
        to_push = newSVsv(row);
    }
    av_push(buffer, to_push);
    SSize_t buf_n = av_top_index(buffer) + 1;

    SV **bs_p = hv_fetchs(self, "batch_size", 0);
    SSize_t batch = bs_p ? SvIV(*bs_p) : 10000;
    int need_flush = buf_n >= batch;

    int need_hw = 0;
    SV **hw_p = hv_fetchs(self, "high_water", 0);
    SSize_t hw = hw_p ? SvIV(*hw_p) : 0;
    if (hw && buf_n >= hw) {
        SV **act_p = hv_fetchs(self, "high_water_active", 0);
        if (!act_p || !SvTRUE(*act_p)) {
            (void)hv_stores(self, "high_water_active", newSViv(1));
            need_hw = 1;
        }
    }

    /* G_EVAL on both dispatches: insert() reachable from _flush can
     * croak ("not connected" etc.); the user's on_high_water is also
     * untrusted. Match the rest of the codebase's exception policy. */
    if (need_flush) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self_sv);
        PUTBACK;
        call_method("_flush", G_DISCARD | G_EVAL);
        WARN_AND_CLEAR_ERRSV("Streamer _flush");
        FREETMPS; LEAVE;
    }

    if (need_hw) {
        SV **cb_p = hv_fetchs(self, "on_high_water", 0);
        if (cb_p && SvROK(*cb_p) && SvTYPE(SvRV(*cb_p)) == SVt_PVCV) {
            SV **inflight_p = hv_fetchs(self, "in_flight", 0);
            IV inflight = inflight_p ? SvIV(*inflight_p) : 0;
            dSP;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            mXPUSHi(buf_n);
            mXPUSHi(inflight);
            PUTBACK;
            PINNED_CALL_SV(*cb_p, G_DISCARD | G_EVAL);
            WARN_AND_CLEAR_ERRSV("on_high_water");
            FREETMPS; LEAVE;
        }
    }

    /* Return self to allow chaining ($s->push_row(...)->push_row(...))
     * without allocating a fresh RV per call. */
    RETVAL = SvREFCNT_inc(self_sv);
}
OUTPUT:
    RETVAL

SV *
_pool_pick(SV *pool_sv)
CODE:
{
    if (!(SvROK(pool_sv) && SvTYPE(SvRV(pool_sv)) == SVt_PVHV))
        croak("_pool_pick: pool must be a hash ref");
    HV *pool = (HV*)SvRV(pool_sv);

    SV **conns_p = hv_fetchs(pool, "conns", 0);
    if (!conns_p || !SvROK(*conns_p) || SvTYPE(SvRV(*conns_p)) != SVt_PVAV)
        croak("_pool_pick: conns slot missing");
    AV *conns = (AV*)SvRV(*conns_p);
    SSize_t n = av_top_index(conns) + 1;
    if (n <= 0) croak("_pool_pick: empty pool");

    SV **thresh_p = hv_fetchs(pool, "cb_thresh", 0);
    IV thresh = thresh_p ? SvIV(*thresh_p) : 0;
    AV *cb_state = NULL;
    double now = 0;
    if (thresh > 0) {
        SV **cs_p = hv_fetchs(pool, "cb_state", 0);
        if (cs_p && SvROK(*cs_p) && SvTYPE(SvRV(*cs_p)) == SVt_PVAV)
            cb_state = (AV*)SvRV(*cs_p);
        now = ev_time();
    }
    /* with_session "pinned" members get round-robined LAST — they're
     * still selectable but only as a fallback. _pinned is a refaddr-
     * keyed hash maintained by Pool::with_session in the .pm. */
    HV *pinned = NULL;
    {
        SV **p_p = hv_fetchs(pool, "_pinned", 0);
        if (p_p && SvROK(*p_p) && SvTYPE(SvRV(*p_p)) == SVt_PVHV)
            pinned = (HV*)SvRV(*p_p);
    }

    int stack_ties[64];
    int *ties = stack_ties;
    int ties_cap = 64;
    if (n > ties_cap) {
        Newx(ties, n, int);
        ties_cap = (int)n;
    }

    int best = -1;
    int best_n = 0;
    int n_ties = 0;
    /* 3 passes: live+unpinned, live (incl pinned), all members (fallback). */
    for (int pass = 0; pass < 3; pass++) {
        for (SSize_t i = 0; i < n; i++) {
            if (pass < 2 && cb_state) {
                SV **slot_sv = av_fetch(cb_state, i, 0);
                if (slot_sv && SvROK(*slot_sv) && SvTYPE(SvRV(*slot_sv)) == SVt_PVHV) {
                    HV *slot = (HV*)SvRV(*slot_sv);
                    SV **du_p = hv_fetchs(slot, "dead_until", 0);
                    if (du_p && SvNV(*du_p) > now) continue;
                }
            }
            SV **csv = av_fetch(conns, i, 0);
            if (!csv || !SvROK(*csv) || !sv_isa(*csv, "EV::ClickHouse")) continue;
            ev_clickhouse_t *ch = INT2PTR(ev_clickhouse_t*, SvIV(SvRV(*csv)));
            if (ch->magic != EV_CH_MAGIC) continue;     /* freed mid-callback */
            if (pass == 0 && pinned) {
                /* Match Pool::with_session's `refaddr($conn)` key —
                 * that's the address of the referent SV (SvRV(*csv)),
                 * not the struct pointer. */
                char key[32];
                int klen = snprintf(key, sizeof(key), "%lu",
                                     (unsigned long)(uintptr_t)SvRV(*csv));
                if (hv_exists(pinned, key, klen)) continue;
            }
            int pc = ch->pending_count;
            if (best < 0 || pc < best_n) {
                best_n = pc;
                best = (int)i;
                ties[0] = (int)i;
                n_ties = 1;
            } else if (pc == best_n) {
                if (n_ties < ties_cap) ties[n_ties++] = (int)i;
            }
        }
        if (best >= 0) break;
    }

    /* Defensive: if every entry was filtered out (sv_isa mismatch /
     * magic mismatch / external corruption) all three passes leave
     * best=-1. Free the heap ties array before croaking. */
    if (best < 0) {
        if (ties != stack_ties) Safefree(ties);
        croak("_pool_pick: no valid EV::ClickHouse entries in pool");
    }

    int picked;
    if (n_ties == 1) {
        picked = ties[0];
    } else {
        SV **idx_p = hv_fetchs(pool, "idx", 0);
        IV idx = idx_p ? SvIV(*idx_p) : 0;
        picked = ties[idx % n_ties];
        /* Store a monotonic counter, not (idx+1) % n_ties: n_ties varies
         * per call, so a mod-n_ties write would pin idx into the smallest
         * recent tie-set and starve higher tie indices under fluctuating
         * load. The mod is applied at read time above. */
        (void)hv_stores(pool, "idx", newSViv(idx + 1));
    }
    if (ties != stack_ties) Safefree(ties);

    SV **csv = av_fetch(conns, picked, 0);
    RETVAL = SvREFCNT_inc(*csv);
}
OUTPUT:
    RETVAL

SV *
_iterator_next(SV *self_sv, SV *timeout_sv = &PL_sv_undef)
CODE:
{
    if (!(SvROK(self_sv) && SvTYPE(SvRV(self_sv)) == SVt_PVHV))
        croak("_iterator_next: self must be a hash ref");
    HV *self = (HV*)SvRV(self_sv);
    SV **ch_p = hv_fetchs(self, "ch", 0);
    if (!ch_p || !SvROK(*ch_p) || !sv_isa(*ch_p, "EV::ClickHouse"))
        croak("_iterator_next: ch slot is not an EV::ClickHouse");
    ev_clickhouse_t *ch = INT2PTR(ev_clickhouse_t*, SvIV(SvRV(*ch_p)));
    struct ev_loop *loop = ch->loop ? ch->loop : EV_DEFAULT;

    SV **batches_p = hv_fetchs(self, "batches", 0);
    if (!batches_p || !SvROK(*batches_p) || SvTYPE(SvRV(*batches_p)) != SVt_PVAV)
        croak("_iterator_next: batches slot missing");
    AV *batches = (AV*)SvRV(*batches_p);

    double timeout = 0;
    if (SvOK(timeout_sv)) {
        double t = SvNV(timeout_sv);
        if (t > 0) timeout = t;
    }
    double expires = timeout > 0 ? ev_now(loop) + timeout : 0;

    ev_timer to;
    int armed = 0;

    while (av_top_index(batches) < 0) {
        SV **done_p = hv_fetchs(self, "done", 0);
        if (done_p && SvTRUE(*done_p)) break;
        if (expires) {
            double left = expires - ev_now(loop);
            if (left <= 0) {
                if (armed) { ev_timer_stop(loop, &to); armed = 0; }
                RETVAL = &PL_sv_undef;
                goto out;
            }
            ev_timer_init(&to, iter_timeout_cb, left, 0);
            ev_timer_start(loop, &to);
            armed = 1;
        }
        ev_run(loop, 0);
        if (armed) { ev_timer_stop(loop, &to); armed = 0; }
        if (av_top_index(batches) < 0) {
            SV **dp2 = hv_fetchs(self, "done", 0);
            if (!dp2 || !SvTRUE(*dp2)) {
                RETVAL = &PL_sv_undef;
                goto out;
            }
            break;
        }
    }

    if (av_top_index(batches) >= 0) {
        SV *b = av_shift(batches);
        RETVAL = b ? b : &PL_sv_undef;
    } else {
        RETVAL = &PL_sv_undef;
    }
out:
    ;
}
OUTPUT:
    RETVAL

void
_breaker_observe(SV *slot_sv, SV *err_sv, IV threshold, NV cooldown)
CODE:
{
    if (!(SvROK(slot_sv) && SvTYPE(SvRV(slot_sv)) == SVt_PVHV)) return;
    HV *slot = (HV*)SvRV(slot_sv);
    if (SvTRUE(err_sv)) {
        SV **fails_p = hv_fetchs(slot, "fails", 0);
        IV fails = (fails_p ? SvIV(*fails_p) : 0) + 1;
        (void)hv_stores(slot, "fails", newSViv(fails));
        if (threshold > 0 && fails >= threshold) {
            (void)hv_stores(slot, "dead_until",
                            newSVnv(ev_time() + cooldown));
        }
    } else {
        (void)hv_stores(slot, "fails",      newSViv(0));
        (void)hv_stores(slot, "dead_until", newSViv(0));
    }
}
