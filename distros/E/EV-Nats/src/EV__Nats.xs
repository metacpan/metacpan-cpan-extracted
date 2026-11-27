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

/* Makefile.PL defines this from $EV::Nats::VERSION so the two cannot drift */
#ifndef EV_NATS_VERSION
#define EV_NATS_VERSION "0.00"
#endif

#ifdef HAVE_OPENSSL
  #include <openssl/ssl.h>
  #include <openssl/err.h>
  #include <openssl/x509v3.h>
  #include <openssl/rand.h>
#endif

#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) \
 || defined(__NetBSD__) || defined(__DragonFly__)
  #define NATS_HAVE_ARC4RANDOM 1
#endif

/* ================================================================
 * Constants
 * ================================================================ */


#define BUF_INIT_SIZE  16384
#define MAX_CONTROL_LINE 4096

#define DEFAULT_MAX_PAYLOAD (1024 * 1024)
#define MAX_SERVER_POOL 64

/* user inbox_prefix limit; the stored prefix adds ".<16 hex>." */
#define MAX_INBOX_BASE 64
#define INBOX_PREFIX_SIZE (MAX_INBOX_BASE + 20)
/* an inbox: the prefix plus a decimal uint64 */
#define INBOX_SUBJ_SIZE (INBOX_PREFIX_SIZE + 24)

#define MAX_INBOUND_LINE (64 * 1024)          /* INFO grows with connect_urls */
#define MAX_INBOUND_MSG (64 * 1024 * 1024)    /* JetStream replies exceed max_payload */

#define MSG_TYPE_MSG   0
#define MSG_TYPE_HMSG  1

#define CLEAR_HANDLER(field) \
    do { if (NULL != (field)) { SvREFCNT_dec(field); (field) = NULL; } } while(0)

/* Taken before firing: a drain_cb that disconnects must not find it still
   armed and recurse into cleanup. */
#define nats_fire_drain(self, err) \
    STMT_START { SV *_dcb = (self)->drain_cb; \
                 if (_dcb) { (self)->drain_cb = NULL; nats_call_str((self), _dcb, 0, (err)); \
                             SvREFCNT_dec(_dcb); } } STMT_END

/* a connection is on its way: writes queue until the handshake */
#define NATS_PENDING(self) \
    ((self)->connecting || ((self)->reconnect_enabled && (self)->reconnect_timer_active))


#define NATS_CROAK_UNLESS_CONNECTED(self) \
    do { \
        if (!(self)->connected && !NATS_PENDING(self)) \
            croak("not connected"); \
    } while(0)

/* ================================================================
 * Type declarations
 * ================================================================ */

typedef struct nats_s       nats_t;
typedef struct nats_sub_s   nats_sub_t;
typedef struct nats_pub_s   nats_pub_t;

typedef nats_t* EV__Nats;

static HV *nats_stash;

/* T_NATS: the stash test is the fast path; subclasses take sv_derived_from */
static nats_t *nats_self(pTHX_ SV *arg)
{
    if (SvROK(arg) && SvOBJECT(SvRV(arg))
        && (SvSTASH(SvRV(arg)) == nats_stash || sv_derived_from(arg, "EV::Nats"))) {
        nats_t *self = INT2PTR(nats_t *, SvIV(SvRV(arg)));
        if (!self)
            croak("EV::Nats: object already destroyed");
        return self;
    }
    croak("EV::Nats: not an EV::Nats object");
    return NULL;
}

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

/* one per client-sent PING, so the FIFO stays 1:1 with PONGs; PONG_DRAIN_LAST
   fences what callbacks published while the drain's PONG was on its way */
enum { PONG_FLUSH, PONG_DRAIN, PONG_DRAIN_LAST, PONG_INTERNAL };
typedef struct nats_pong_cb_s {
    SV *cb;                 /* PONG_FLUSH only; NULL for a cb-less flush */
    int kind;
    ngx_queue_t queue;
} nats_pong_cb_t;

typedef struct nats_server_s {
    char *host;
    int port;
    int implicit;   /* learned from connect_urls, pruned once unadvertised */
    int seen;
    ngx_queue_t queue;
} nats_server_t;

struct nats_pub_s {
    char *data;
    size_t len;
    uint64_t req_id;        /* the request this PUB carries, 0 for a publish */
    ngx_queue_t queue;
};

struct nats_s {
    struct ev_loop *loop;
    int fd;
    int connected;
    int connecting;
    int connect_pending;    /* nonblocking connect(2) still in flight */
    int connect_sent;       /* CONNECT, with every SUB, is in the write buffer */
    unsigned conn_gen;      /* bumped per socket: a callback may replace it */

    ev_io rio, wio;
    int reading, writing;

    char *rbuf;
    size_t rbuf_len, rbuf_cap;
    size_t rbuf_off;        /* parsed up to here; committed before each callback */

    char *wbuf;
    size_t wbuf_len, wbuf_off, wbuf_cap;

    SV *on_error;
    SV *on_connect;
    SV *on_disconnect;
    char *pending_croak;    /* no-on_error error, fired at wrapper exit */
    SV *pending_die;        /* a callback's die, rethrown at wrapper exit */

    ngx_queue_t subs;
    HV *sub_map;            /* raw sid bytes -> nats_sub_t* */
    uint64_t next_sid;

    ngx_queue_t wait_queue;
    int waiting_count;
    size_t wait_bytes;         /* queued bytes, capped by reconnect_buf_size */
    size_t reconnect_buf_size; /* 0 = unlimited */

    ev_prepare prepare_watcher;
    int prepare_active;
    int wbuf_dirty;

    char *host;
    int port;
    char *path; /* Unix socket path */

    /* getaddrinfo candidates kept across async connect failures for failover */
    struct addrinfo *ai_res;    /* the list to freeaddrinfo */
    struct addrinfo *ai_next;   /* next candidate to try */

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

    char inbox_prefix[INBOX_PREFIX_SIZE];
    /* new_inbox's own token: the request wildcard must not match it */
    char user_inbox_prefix[INBOX_PREFIX_SIZE];
    uint64_t next_req_id;
    ngx_queue_t req_queue;
    uint64_t inbox_sub_sid;

    /* one-shot internal callbacks fired when the connection drops */
    ngx_queue_t disc_watch;
    uint64_t next_watch_id;

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

    UV msgs_in;
    UV msgs_out;
    UV bytes_in;
    UV bytes_out;

    ngx_queue_t server_pool;
    int server_pool_count;

    int draining;
    SV *drain_cb;

    size_t slow_consumer_bytes;  /* wbuf threshold, 0 = disabled */
    SV *on_slow_consumer;
    int slow_fired;

    int batch_mode;

    ngx_queue_t pong_cbs;
    /* flushes made before the handshake completed; PINGed after it */
    ngx_queue_t flush_wait;

    char *nkey_seed;     /* base32 */
    char *jwt;
    char *server_nonce;

    int ldm;             /* lame duck mode */
    SV *on_ldm;

    /* Deferred destroy: DESTROY inside an event-loop callback only sets
       destroy_pending; the outermost nats_on_* wrapper frees (cb_depth) */
    int cb_depth;
    int destroy_pending;
    /* Borrowed owner referent; pinned across method-reachable user
       callbacks so DESTROY cannot free self mid-method. */
    SV *owner_sv;

#ifdef HAVE_OPENSSL
    SSL_CTX *ssl_ctx;
    SSL     *ssl;
    int tls;
    int tls_skip_verify;
    char *tls_ca_file;
    int ssl_handshaking;
    int ssl_write_len;
#endif
    SV *loop_sv;
};

typedef struct nats_req_s {
    uint64_t req_id;
    nats_t *nats;
    SV *cb;
    ev_timer timer;
    int timer_active;
    int queued;             /* PUB still in wait_queue, not yet on a socket */
    ngx_queue_t queue;
} nats_req_t;

typedef struct nats_watch_s {
    uint64_t id;
    SV *cb;
    ngx_queue_t queue;
} nats_watch_t;

/* ================================================================
 * Forward declarations
 * ================================================================ */

static void nats_connect_tcp(nats_t *self);
static void nats_connect_unix(nats_t *self);
static void nats_free_addrinfo(nats_t *self);
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
static int nats_send_connect(nats_t *self);
static void nats_try_write(nats_t *self);
static void nats_schedule_write(nats_t *self);
static void nats_process_line(nats_t *self, char *line, size_t len);
static void nats_parse(nats_t *self);
static void nats_process_msg(nats_t *self, char *payload, size_t len);
static void nats_emit_error(nats_t *self, const char *err);
static void nats_fail(nats_t *self, const char *err);
static void nats_cleanup(nats_t *self);
static void nats_destroy_now(nats_t *self);
static void nats_start_ping_timer(nats_t *self);
static void nats_drain_waiting(nats_t *self);
static void nats_setup_inbox(nats_t *self, const char *base);
static nats_sub_t *nats_find_sub(nats_t *self, uint64_t sid);
static void nats_remove_sub(nats_t *self, nats_sub_t *sub);
static void nats_cancel_requests(nats_t *self, const char *err, int queued);
static void nats_unqueue_requests(nats_t *self, uint64_t req_id);
static void nats_resub_all(nats_t *self);

/* Call a callback whose args are pushed, inside an ENTER/LEAVE. The pin lets
   it clear its own handler. Under a watcher a die is held until the wrapper
   has finished its bookkeeping, then rethrown; from a method it propagates. */
static void nats_invoke(nats_t *self, SV *cb)
{
    SV *pin = SvREFCNT_inc_simple_NN(cb);
    SAVEFREESV(pin);
    if (self->cb_depth == 0) {
        call_sv(pin, G_DISCARD);
        return;
    }
    call_sv(pin, G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV) && !self->pending_die)
        self->pending_die = newSVsv(ERRSV);
}

static void nats_call0(nats_t *self, SV *cb)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    nats_invoke(self, cb);
    FREETMPS; LEAVE;
}

/* cb->([undef,] $str), $str undef when str is NULL */
static void nats_call_str(nats_t *self, SV *cb, int lead_undef, const char *str)
{
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    if (lead_undef)
        PUSHs(&PL_sv_undef);
    PUSHs(str ? sv_2mortal(newSVpv(str, 0)) : &PL_sv_undef);
    PUTBACK;
    nats_invoke(self, cb);
    FREETMPS; LEAVE;
}

/* ================================================================
 * String helpers
 * ================================================================ */

static void nats_set_strn(char **dst, const char *src, size_t l)
{
    if (*dst) { Safefree(*dst); *dst = NULL; }
    if (src) {
        Newx(*dst, l + 1, char);
        memcpy(*dst, src, l);
        (*dst)[l] = '\0';
    }
}

static void nats_set_str(char **dst, const char *src)
{
    nats_set_strn(dst, src, src ? strlen(src) : 0);
}

/* undef means unset: NULL, not an empty string */
static void nats_set_str_sv(char **dst, SV *val)
{
    STRLEN l = 0;
    const char *s = SvOK(val) ? SvPV(val, l) : NULL;
    nats_set_strn(dst, s, l);
}

/* an int option: an IV out of range clamps instead of wrapping */
static int nats_clamp(IV v)
{
    return v > INT_MAX ? INT_MAX : v < INT_MIN ? INT_MIN : (int)v;
}

static int nats_int(SV *val)
{
    return nats_clamp(SvIV(val));
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

/* an empty buffer one large message grew is given back */
static void buf_trim(char **buf, size_t *cap)
{
    if (*cap > 1024 * 1024) {
        Safefree(*buf);
        *buf = NULL;
        *cap = 0;
    }
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

/* Bounded substring search for counted buffers: rbuf slices are not
   NUL-terminated, so strstr() is unsafe (memmem() is not portable). */
static const char *nats_memfind(const char *hay, size_t hay_len,
                                const char *needle, size_t needle_len)
{
    const char *last;
    const char *p;
    if (needle_len == 0) return hay;
    if (hay_len < needle_len) return NULL;
    last = hay + (hay_len - needle_len);
    p = hay;
    while (p <= last) {
        p = (const char *)memchr(p, needle[0], (size_t)(last - p) + 1);
        if (!p) return NULL;
        if (memcmp(p, needle, needle_len) == 0) return p;
        p++;
    }
    return NULL;
}

/* the value after an INFO key, past blanks; NULL when the key is absent */
static const char *nats_info_value(const char *p, const char *e, const char *key)
{
    size_t klen = strlen(key);
    const char *v = nats_memfind(p, (size_t)(e - p), key, klen);
    if (!v) return NULL;
    v += klen;
    while (v < e && (*v == ' ' || *v == '\t')) v++;
    return v;
}

/* ================================================================
 * NKey helpers (base32 + Ed25519)
 * ================================================================ */

#ifdef HAVE_OPENSSL
#include <openssl/evp.h>

/* NATS base32 decode (RFC 4648, no padding). dst_cap bounds the output:
   an over-long input (e.g. a hostile .creds seed) must not smash dst. */
static int nats_base32_decode(const char *src, size_t src_len,
                              unsigned char *dst, size_t dst_cap,
                              size_t *dst_len)
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
            if (di >= dst_cap) return -1;
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

/* CRC-16/XMODEM (poly 0x1021, init 0), as NKeys use; not CRC-16/IBM */
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

/* Decode and CRC-check a seed: prefix(2) + seed(32) + CRC(2) into raw */
static EVP_PKEY *nats_seed_key(const char *seed_encoded, unsigned char raw[64])
{
    size_t raw_len = 0;
    if (nats_base32_decode(seed_encoded, strlen(seed_encoded), raw, 64, &raw_len) != 0
        || raw_len != 36
        || nats_crc16(raw, 34) != ((uint16_t)raw[34] | ((uint16_t)raw[35] << 8)))
        return NULL;
    return EVP_PKEY_new_raw_private_key(EVP_PKEY_ED25519, NULL, raw + 2, 32);
}

static int nats_nkey_sign(const char *seed_encoded, const char *nonce, size_t nonce_len,
                          char *sig_out, size_t sig_out_size)
{
    unsigned char raw[64];
    EVP_PKEY *pkey = nats_seed_key(seed_encoded, raw);
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
    EVP_PKEY *pkey = nats_seed_key(seed_encoded, raw);
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

    /* prefix(1) + pubkey(32) + CRC16(2); operator and account keep their
       role, anything else signs as a user */
    unsigned char full[35];
    full[0] = role == 0x70 || role == 0x00 ? role : 0xA0;
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
        /* Retries keep the original length even if producers append more. */
        if (!self->ssl_write_len)
            self->ssl_write_len = len > (size_t)INT_MAX ? INT_MAX : (int)len;
        int n = SSL_write(self->ssl, buf, self->ssl_write_len);
        if (n <= 0) {
            int err = SSL_get_error(self->ssl, n);
            if (err == SSL_ERROR_WANT_WRITE || err == SSL_ERROR_WANT_READ) {
                errno = EAGAIN;
                return -1;
            }
            errno = EIO;
            return -1;
        }
        self->ssl_write_len = 0;
        return n;
    }
#endif
#ifdef MSG_NOSIGNAL
    return send(self->fd, buf, len, MSG_NOSIGNAL);
#else
    return write(self->fd, buf, len);
#endif
}

#ifdef HAVE_OPENSSL
#ifdef MSG_NOSIGNAL
/* OpenSSL's socket BIO writes without MSG_NOSIGNAL. Keep signal suppression
   local to this transport, including writes made during TLS reads. */
static BIO_METHOD *nats_socket_bio_method;

static int nats_bio_read(BIO *bio, char *buf, int len)
{
    nats_t *self = (nats_t *)BIO_get_data(bio);
    BIO_clear_retry_flags(bio);
    int n = read(self->fd, buf, len);
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR))
        BIO_set_retry_read(bio);
    return n;
}

static int nats_bio_write(BIO *bio, const char *buf, int len)
{
    nats_t *self = (nats_t *)BIO_get_data(bio);
    BIO_clear_retry_flags(bio);
    int n = send(self->fd, buf, len, MSG_NOSIGNAL);
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR))
        BIO_set_retry_write(bio);
    return n;
}

static long nats_bio_ctrl(BIO *bio, int cmd, long num, void *ptr)
{
    nats_t *self = (nats_t *)BIO_get_data(bio);
    (void)num;
    if (cmd == BIO_CTRL_FLUSH) return 1;
    if (cmd == BIO_C_GET_FD) {
        if (ptr) *(int *)ptr = self->fd;
        return self->fd;
    }
    return 0;
}

static BIO *nats_socket_bio(nats_t *self)
{
    if (!nats_socket_bio_method) {
        BIO_METHOD *method = BIO_meth_new(BIO_get_new_index() |
            BIO_TYPE_SOURCE_SINK | BIO_TYPE_DESCRIPTOR, "EV::Nats socket");
        if (!method) return NULL;
        BIO_meth_set_read(method, nats_bio_read);
        BIO_meth_set_write(method, nats_bio_write);
        BIO_meth_set_ctrl(method, nats_bio_ctrl);
        nats_socket_bio_method = method;
    }
    BIO *bio = BIO_new(nats_socket_bio_method);
    if (bio) {
        BIO_set_data(bio, self);
        BIO_set_init(bio, 1);
    }
    return bio;
}
#endif

static int nats_ssl_setup(nats_t *self)
{
    if (!self->ssl_ctx) {
        self->ssl_ctx = SSL_CTX_new(TLS_client_method());
        if (!self->ssl_ctx) return -1;

        /* a failed load (e.g. no fd left) must not be cached for later attempts */
        if (!(self->tls_ca_file && *self->tls_ca_file
                ? SSL_CTX_load_verify_locations(self->ssl_ctx, self->tls_ca_file, NULL)
                : SSL_CTX_set_default_verify_paths(self->ssl_ctx))) {
            SSL_CTX_free(self->ssl_ctx);
            self->ssl_ctx = NULL;
            return -1;
        }

        if (!self->tls_skip_verify)
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_PEER, NULL);
    }

    self->ssl = SSL_new(self->ssl_ctx);
    if (!self->ssl) return -1;
    SSL_set_mode(self->ssl, SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);

#ifdef MSG_NOSIGNAL
    BIO *bio = nats_socket_bio(self);
    if (!bio) {
        SSL_free(self->ssl);
        self->ssl = NULL;
        return -1;
    }
    SSL_set_bio(self->ssl, bio, bio);
#else
    SSL_set_fd(self->ssl, self->fd);
#endif
    if (self->host) {
        SSL_set_tlsext_host_name(self->ssl, self->host);
        if (!self->tls_skip_verify) {
            X509_VERIFY_PARAM *vpm = SSL_get0_param(self->ssl);
            /* set1_ip_asc fails for a DNS name; set1_host covers those */
            if (vpm && !X509_VERIFY_PARAM_set1_ip_asc(vpm, self->host)) {
                X509_VERIFY_PARAM_set_hostflags(vpm, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
                if (!X509_VERIFY_PARAM_set1_host(vpm, self->host, 0)) {
                    SSL_free(self->ssl);
                    self->ssl = NULL;
                    return -1;
                }
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
    self->ssl_write_len = 0;
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
        /* Stop the write watcher: leaving it armed spins the loop
           calling SSL_connect until the server's next flight arrives. */
        if (self->writing) {
            ev_io_stop(self->loop, &self->wio);
            self->writing = 0;
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
    nats_fail(self, msg);
}
#endif

/* ================================================================
 * JSON string escaper (for CONNECT command)
 * ================================================================ */

static int json_escape_string(char *dst, size_t dst_size, const char *src)
{
    size_t di = 0;
    const unsigned char *s = (const unsigned char *)src;

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

    if (*s) return -1;
    dst[di++] = '"';
    dst[di] = '\0';
    return (int)di;
}

/* ================================================================
 * Random hex for inbox prefix
 * ================================================================ */

/* 0 when no entropy source answered (e.g. no fd left for /dev/urandom)
   and the bytes came from a time-and-pid seeded rand() */
static int nats_random_bytes(unsigned char *out, int nbytes)
{
#ifdef HAVE_OPENSSL
    if (RAND_bytes(out, nbytes) == 1)
        return 1;
#endif
#ifdef NATS_HAVE_ARC4RANDOM
    arc4random_buf(out, nbytes);
    return 1;
#else
    int got = 0, i;
    static int seeded;
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd >= 0) {
        while (got < nbytes) {
            ssize_t n = read(fd, out + got, nbytes - got);
            if (n > 0) got += n;
            else if (n == 0 || (errno != EINTR && errno != EAGAIN)) break;
        }
        close(fd);
    }
    if (got == nbytes)
        return 1;
    if (!seeded) {
        srand((unsigned)time(NULL) ^ (unsigned)getpid() ^ (unsigned)(uintptr_t)&seeded);
        seeded = 1;
    }
    for (i = got; i < nbytes; i++)
        out[i] = (unsigned char)(rand() & 0xFF);
    return 0;
#endif
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

static void nats_setup_inbox(nats_t *self, const char *base)
{
    char hex[20];
    nats_gen_hex(hex, 8);
    snprintf(self->inbox_prefix, sizeof(self->inbox_prefix),
             "%s.%.16s.", base, hex);
    nats_gen_hex(hex, 8);
    snprintf(self->user_inbox_prefix, sizeof(self->user_inbox_prefix),
             "%s.%.16s.", base, hex);
    self->next_req_id = 1;
}

static int nats_inbox_base_ok(const char *p, size_t len)
{
    size_t i;
    if (len == 0 || len > MAX_INBOX_BASE || p[0] == '.' || p[len - 1] == '.')
        return 0;
    for (i = 0; i < len; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c <= 0x20 || c == 0x7f || c == '*' || c == '>')
            return 0;
        if (c == '.' && p[i + 1] == '.')
            return 0;
    }
    return 1;
}

/* ================================================================
 * Subscription management
 * ================================================================ */

static nats_sub_t *nats_find_sub(nats_t *self, uint64_t sid)
{
    SV **svp = hv_fetch(self->sub_map, (const char *)&sid, sizeof(sid), 0);
    if (svp && SvIOK(*svp))
        return INT2PTR(nats_sub_t *, SvIVX(*svp));
    return NULL;
}

static void nats_register_sub(nats_t *self, nats_sub_t *sub)
{
    hv_store(self->sub_map, (const char *)&sub->sid, sizeof(sub->sid), newSViv(PTR2IV(sub)), 0);
    ngx_queue_insert_tail(&self->subs, &sub->queue);
}

static void nats_unregister_sub(nats_t *self, nats_sub_t *sub)
{
    hv_delete(self->sub_map, (const char *)&sub->sid, sizeof(sub->sid), G_DISCARD);
}

static void nats_remove_sub(nats_t *self, nats_sub_t *sub)
{
    SV *cb = sub->cb;
    nats_unregister_sub(self, sub);
    ngx_queue_remove(&sub->queue);
    CLEAR_HANDLER(sub->subject);
    CLEAR_HANDLER(sub->queue_group);
    Safefree(sub);
    /* last: freeing the callback can run a DESTROY that calls back in */
    if (cb)
        SvREFCNT_dec(cb);
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

/* Fail the requests whose PUB was on the socket (queued 0) or is being
   dropped from the wait queue (queued 1); a queued PUB that survives a
   failed reconnect attempt must not report a failure it later contradicts. */
static void nats_cancel_requests(nats_t *self, const char *err, int queued)
{
    ngx_queue_t doomed, *q, *next;
    ngx_queue_init(&doomed);
    for (q = ngx_queue_head(&self->req_queue); q != ngx_queue_sentinel(&self->req_queue); q = next) {
        nats_req_t *req = ngx_queue_data(q, nats_req_t, queue);
        next = ngx_queue_next(q);
        if (req->queued != queued)
            continue;
        ngx_queue_remove(q);
        ngx_queue_insert_tail(&doomed, q);
        if (req->timer_active) {
            ev_timer_stop(self->loop, &req->timer);
            req->timer_active = 0;
        }
    }
    while (!ngx_queue_empty(&doomed)) {
        q = ngx_queue_head(&doomed);
        nats_req_t *req = ngx_queue_data(q, nats_req_t, queue);
        ngx_queue_remove(q);

        if (req->cb) {
            nats_call_str(self, req->cb, 1, err);
            SvREFCNT_dec(req->cb);
        }
        Safefree(req);
    }
}

/* One-shot; a watcher added by a callback waits for the next drop. */
static void nats_fire_disc_watchers(nats_t *self)
{
    uint64_t last = self->next_watch_id;
    while (!ngx_queue_empty(&self->disc_watch)) {
        ngx_queue_t *q = ngx_queue_head(&self->disc_watch);
        nats_watch_t *w = ngx_queue_data(q, nats_watch_t, queue);
        if (w->id > last)
            break;
        ngx_queue_remove(q);
        SV *cb = w->cb;
        Safefree(w);
        ENTER;
        SAVEFREESV(cb);
        nats_call0(self, cb);
        LEAVE;
    }
}

/* Fail flush callbacks with "disconnected"; free markers silently.
   Detached first, so a callback that flushes again cannot loop here. */
static void nats_fail_pong_queue(nats_t *self, ngx_queue_t *live)
{
    ngx_queue_t detached, *head = &detached;
    if (ngx_queue_empty(live))
        return;
    ngx_queue_init(head);
    ngx_queue_add(head, live);
    ngx_queue_init(live);
    while (!ngx_queue_empty(head)) {
        ngx_queue_t *pq = ngx_queue_head(head);
        nats_pong_cb_t *pcb = ngx_queue_data(pq, nats_pong_cb_t, queue);
        ngx_queue_remove(pq);
        if (pcb->cb) {
            nats_call_str(self, pcb->cb, 0, "disconnected");
            SvREFCNT_dec(pcb->cb);
        }
        Safefree(pcb);
    }
}

static void nats_free_pong_queue(ngx_queue_t *head)
{
    while (!ngx_queue_empty(head)) {
        ngx_queue_t *pq = ngx_queue_head(head);
        nats_pong_cb_t *pcb = ngx_queue_data(pq, nats_pong_cb_t, queue);
        ngx_queue_remove(pq);
        CLEAR_HANDLER(pcb->cb);
        Safefree(pcb);
    }
}

typedef struct {
    SV *cb;
    const char *err;
} nats_deferred_err_t;

static void nats_on_deferred_err(int revents, void *arg)
{
    nats_deferred_err_t *d = (nats_deferred_err_t *)arg;
    SV *cb = d->cb;
    const char *err = d->err;
    (void)revents;
    Safefree(d);
    dSP;
    ENTER; SAVETMPS;
    SAVEFREESV(cb);
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpv(err, 0)));
    PUTBACK;
    call_sv(cb, G_DISCARD);
    FREETMPS; LEAVE;
}

static void nats_defer_err(nats_t *self, SV *cb, const char *err)
{
    nats_deferred_err_t *d;
    Newx(d, 1, nats_deferred_err_t);
    d->cb = newSVsv(cb);
    d->err = err;
    ev_once(self->loop, -1, 0, 0., nats_on_deferred_err, d);
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
    self->wait_bytes = 0;
}

static void nats_cleanup(nats_t *self)
{
    SV *pin = self->owner_sv;
    if (pin) SvREFCNT_inc(pin);
    /* the socket was up: a refused or unreachable attempt is not a drop */
    int was_connected = self->connected || (self->connecting && !self->connect_pending);
    int established = self->connected;

    nats_stop_watchers(self);
    nats_stop_timers(self);

    self->connected = 0;
    self->connecting = 0;
    self->connect_pending = 0;
    self->connect_sent = 0;
    self->pings_outstanding = 0;
    self->ldm = 0;  /* lame-duck flag is per-connection */
    nats_set_str(&self->server_nonce, NULL);  /* stale nonce must not sign */

    nats_free_addrinfo(self);

#ifdef HAVE_OPENSSL
    nats_ssl_cleanup(self);
#endif

    if (self->fd >= 0) {
        close(self->fd);
        self->fd = -1;
    }

    self->rbuf_len = 0;
    self->rbuf_off = 0;
    self->wbuf_len = 0;
    self->wbuf_off = 0;
    buf_trim(&self->rbuf, &self->rbuf_cap);
    buf_trim(&self->wbuf, &self->wbuf_cap);

    nats_cancel_requests(self, "disconnected", 0);
    /* a fetch made during an outage still has its pull queued */
    if (established || self->intentional_disconnect)
        nats_fire_disc_watchers(self);

    nats_fail_pong_queue(self, &self->pong_cbs);
    self->draining = 0;
    nats_fire_drain(self, "disconnected");

    if (was_connected && self->on_disconnect)
        nats_call0(self, self->on_disconnect);

    nats_schedule_reconnect(self);
    if (pin) SvREFCNT_dec(pin);
}

static void nats_emit_error(nats_t *self, const char *err)
{
    if (self->on_error) {
        SV *pin = self->owner_sv;
        if (pin) SvREFCNT_inc(pin);
        nats_call_str(self, self->on_error, 0, err);
        if (pin) SvREFCNT_dec(pin);
    } else if (self->cb_depth > 0) {
        /* Async context with no handler: stashing the first error and
           croaking it at the outermost wrapper exit lets the caller's
           cleanup and reconnect logic run instead of longjmping past it. */
        if (!self->pending_croak)
            nats_set_str(&self->pending_croak, err);
    } else {
        croak("EV::Nats: %s", err);
    }
}

/* Report err, then tear down -- unless on_error already replaced the socket. */
static void nats_fail(nats_t *self, const char *err)
{
    unsigned gen = self->conn_gen;
    if (self->owner_sv)
        sv_2mortal(SvREFCNT_inc(self->owner_sv));
    nats_emit_error(self, err);
    if (gen == self->conn_gen)
        nats_cleanup(self);
}

/* Fire a deferred no-on_error croak after bookkeeping has run.
   Take-before-fire: the croak longjmps. */
static void
nats_fire_pending_croak(nats_t *self)
{
    char *msg = self->pending_croak;
    self->pending_croak = NULL;
    SV *sv = sv_2mortal(newSVpvf("EV::Nats: %s", msg));
    Safefree(msg);
    croak_sv(sv);
}

/* keeps pong_cbs 1:1 with the PINGs sent */
static void nats_push_pong_marker(nats_t *self)
{
    nats_pong_cb_t *pcb;
    Newxz(pcb, 1, nats_pong_cb_t);
    pcb->kind = PONG_INTERNAL;
    ngx_queue_insert_tail(&self->pong_cbs, &pcb->queue);
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

#define CONNECT_STR(key, val) \
    do { \
        int _e = json_escape_string(escaped, sizeof(escaped), (val)); \
        if (_e < 0) overflow = 1; \
        else CONNECT_APPEND(",\"" key "\":%.*s", _e, escaped); \
    } while (0)

/* 0 when it failed the connection instead: on_error may have replaced it */
static int nats_send_connect(nats_t *self)
{
    char buf[CONNECT_BUF_SIZE];
    /* sized to the whole buffer: production JWTs exceed 1 KB */
    int off = 0;
    int overflow = 0;
    char escaped[CONNECT_BUF_SIZE];

    CONNECT_APPEND("CONNECT {");
    CONNECT_APPEND("\"verbose\":%s,\"pedantic\":%s,\"echo\":%s",
                   self->verbose ? "true" : "false",
                   self->pedantic ? "true" : "false",
                   self->echo ? "true" : "false");
    CONNECT_APPEND(",\"protocol\":1");
    if (self->no_responders)
        CONNECT_APPEND(",\"no_responders\":true");
    CONNECT_APPEND(",\"headers\":true");
    CONNECT_APPEND(",\"lang\":\"perl-xs\",\"version\":\"" EV_NATS_VERSION "\"");

    if (self->user) {
        CONNECT_STR("user", self->user);
        if (self->pass)
            CONNECT_STR("pass", self->pass);
    }
    if (self->token)
        CONNECT_STR("auth_token", self->token);
    if (self->name)
        CONNECT_STR("name", self->name);
    if (self->jwt)
        CONNECT_STR("jwt", self->jwt);
#ifdef HAVE_OPENSSL
    if (self->nkey_seed && self->server_nonce) {
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
        /* deterministic local failure: retries cannot help */
        self->intentional_disconnect = 1;
        nats_fail(self, "CONNECT command too long (auth/name fields)");
        return 0;
    }

    wbuf_append(self, buf, off);

    nats_resub_all(self);
    self->connect_sent = 1;

    wbuf_append(self, "PING\r\n", 6);
    nats_push_pong_marker(self);
    return 1;
}

/* ================================================================
 * Protocol parser
 * ================================================================ */

/* 0 on success; -1 on empty input, a non-digit or overflow */
static int nats_parse_u64(const char *tok, size_t tok_len, uint64_t *out)
{
    uint64_t v = 0;
    size_t i;
    if (tok_len == 0) return -1;
    for (i = 0; i < tok_len; i++) {
        uint64_t d;
        if (tok[i] < '0' || tok[i] > '9') return -1;
        d = (uint64_t)(tok[i] - '0');
        if (v > (UINT64_MAX - d) / 10) return -1;
        v = v * 10 + d;
    }
    *out = v;
    return 0;
}

static int nats_parse_size(const char *tok, size_t tok_len, size_t *out)
{
    uint64_t v;
    if (nats_parse_u64(tok, tok_len, &v) != 0 || v > (uint64_t)SIZE_MAX) return -1;
    *out = (size_t)v;
    return 0;
}

/* MSG <subject> <sid> [reply] <#bytes>
   HMSG <subject> <sid> [reply] <#header bytes> <#total bytes> */
static int nats_parse_msg_line(nats_t *self, char *line, size_t len, int hmsg)
{
    char *p = line + (hmsg ? 5 : 4), *end = line + len;
    char *tok[6];
    size_t tlen[6];
    int n = 0, base = hmsg ? 4 : 3, i;

    while (n < 6) {
        while (p < end && (*p == ' ' || *p == '\t')) p++;
        if (p >= end) break;
        tok[n] = p;
        while (p < end && *p != ' ' && *p != '\t') p++;
        tlen[n] = p - tok[n];
        n++;
    }
    if (n != base && n != base + 1)
        return -1;
    i = n - base + 2;   /* index of the first length token */
    if (nats_parse_u64(tok[1], tlen[1], &self->msg_sid) != 0)
        return -1;
    self->msg_subject_off = tok[0] - self->rbuf;
    self->msg_subject_len = tlen[0];
    self->msg_reply_off = n > base ? (size_t)(tok[2] - self->rbuf) : 0;
    self->msg_reply_len = n > base ? tlen[2] : 0;
    self->msg_hdr_len = 0;
    if (hmsg) {
        if (nats_parse_size(tok[i], tlen[i], &self->msg_hdr_len) != 0)
            return -1;
        i++;
    }
    if (nats_parse_size(tok[i], tlen[i], &self->msg_total_len) != 0)
        return -1;
    /* an impossible header length delivers the frame as raw payload */
    if (self->msg_hdr_len > self->msg_total_len)
        self->msg_hdr_len = 0;
    self->msg_type = hmsg ? MSG_TYPE_HMSG : MSG_TYPE_MSG;
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

        if (self->msg_type == MSG_TYPE_HMSG && self->msg_hdr_len > 0 && self->msg_hdr_len <= len) {
            PUSHs(sv_2mortal(newSVpvn(payload, self->msg_hdr_len)));
        }

        PUTBACK;
        /* a callback that unsubscribes its own sid frees the sub mid-call */
        nats_invoke(self, sub->cb);
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

    uint64_t req_id;
    if (nats_parse_u64(subject + pfx_len, subject_len - pfx_len, &req_id) != 0)
        return;

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
                nats_invoke(self, req->cb);
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

    if (len > 5 && (line[0] == 'I' || line[0] == 'i') &&
        (line[1] == 'N' || line[1] == 'n') &&
        (line[2] == 'F' || line[2] == 'f') &&
        (line[3] == 'O' || line[3] == 'o') &&
        line[4] == ' ') {

        const char *p = line + 5, *e = line + len, *v;
        int enter_ldm;
        unsigned gen = self->conn_gen;
        CLEAR_HANDLER(self->server_info_json);
        self->server_info_json = newSVpvn(p, len - 5);

        if ((v = nats_info_value(p, e, "\"max_payload\":"))) {
            const char *d = v;
            uint64_t mp;
            while (d < e && *d >= '0' && *d <= '9') d++;
            if (d > v) {
                /* a hostile INFO must not wrap the signed field negative */
                if (nats_parse_u64(v, d - v, &mp) != 0 || mp > (uint64_t)INT_MAX)
                    mp = INT_MAX;
                if (mp > 0)
                    self->max_payload = (int)mp;
            }
        }

        nats_parse_connect_urls(self, p, e - p);

        if ((v = nats_info_value(p, e, "\"nonce\":")) && v < e && *v == '"') {
            const char *nend = memchr(v + 1, '"', e - v - 1);
            if (nend)
                nats_set_strn(&self->server_nonce, v + 1, nend - v - 1);
        }

        v = nats_info_value(p, e, "\"ldm\":");
        enter_ldm = v && v < e && *v == 't' && !self->ldm;

        if (self->connecting) {
            /* tls_required: CONNECT would leak credentials over plaintext
               before the server could reject it; refuse instead */
            int tls_active = 0;
#ifdef HAVE_OPENSSL
            tls_active = self->tls;
#endif
            v = nats_info_value(p, e, "\"tls_required\":");
            if (v && e - v >= 4 && memcmp(v, "true", 4) == 0 && !tls_active) {
                self->intentional_disconnect = 1;
                nats_fail(self, "server requires TLS but TLS is not enabled");
                return;
            }
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
                    if (nats_send_connect(self))
                        nats_try_write(self);
                }
                /* hret == 0: handshake in progress; nats_on_read will resume. */
            } else
#endif
            if (nats_send_connect(self))
                nats_try_write(self);
        }
        /* last: on_lame_duck may move to another server */
        if (enter_ldm && self->fd >= 0 && gen == self->conn_gen) {
            self->ldm = 1;
            if (self->on_ldm)
                nats_call0(self, self->on_ldm);
        }
        return;
    }

    if (len == 4 && memcmp(line, "PING", 4) == 0) {
        wbuf_append(self, "PONG\r\n", 6);
        nats_try_write(self);
        return;
    }

    if (len == 4 && memcmp(line, "PONG", 4) == 0) {
        nats_pong_cb_t *pcb = NULL;
        if (self->pings_outstanding > 0)
            self->pings_outstanding--;
        /* taken before any callback, whose nested loop may read more PONGs */
        if (!ngx_queue_empty(&self->pong_cbs)) {
            ngx_queue_t *pq = ngx_queue_head(&self->pong_cbs);
            pcb = ngx_queue_data(pq, nats_pong_cb_t, queue);
            ngx_queue_remove(pq);
        }

        if (self->connecting && !self->connected) {
            /* the CONNECT's PING, whose entry is an internal marker */
            if (pcb) {
                CLEAR_HANDLER(pcb->cb);
                Safefree(pcb);
            }
            self->connecting = 0;
            self->connected = 1;
            self->reconnect_attempts = 0;
            /* connect succeeded: drop the saved list; reconnect re-resolves */
            nats_free_addrinfo(self);

            if (self->connect_timer_active) {
                ev_timer_stop(self->loop, &self->connect_timer);
                self->connect_timer_active = 0;
            }

            nats_start_ping_timer(self);

            /* Drain the outage backlog first: publishes from on_connect
               must queue behind it, not jump ahead of it. */
            nats_drain_waiting(self);

            /* flushes made while connecting fence that backlog */
            if (self->connected && !ngx_queue_empty(&self->flush_wait)) {
                while (!ngx_queue_empty(&self->flush_wait)) {
                    ngx_queue_t *fq = ngx_queue_head(&self->flush_wait);
                    ngx_queue_remove(fq);
                    wbuf_append(self, "PING\r\n", 6);
                    ngx_queue_insert_tail(&self->pong_cbs, fq);
                }
                nats_schedule_write(self);
            }

            if (self->connected && self->on_connect)
                nats_call0(self, self->on_connect);
            return;
        }

        if (!pcb)
            return;
        if (pcb->kind == PONG_DRAIN || pcb->kind == PONG_DRAIN_LAST) {
            unsigned gen = self->conn_gen;
            /* drained subscriptions are gone; a later connect must not revive them */
            while (!ngx_queue_empty(&self->subs))
                nats_remove_sub(self, ngx_queue_data(ngx_queue_head(&self->subs), nats_sub_t, queue));
            self->inbox_sub_sid = 0;
            if (pcb->kind == PONG_DRAIN && self->wbuf_len > self->wbuf_off) {
                pcb->kind = PONG_DRAIN_LAST;
                wbuf_append(self, "PING\r\n", 6);
                ngx_queue_insert_tail(&self->pong_cbs, &pcb->queue);
                nats_try_write(self);
                return;
            }
            Safefree(pcb);
            self->draining = 0;
            nats_fire_drain(self, NULL);
            if (gen == self->conn_gen) {
                self->intentional_disconnect = 1;
                nats_cleanup(self);
            }
            return;
        }
        if (pcb->cb) {
            nats_call_str(self, pcb->cb, 0, NULL);
            SvREFCNT_dec(pcb->cb);
        }
        Safefree(pcb);
        return;
    }

    if (len >= 4 && memcmp(line, "-ERR", 4) == 0) {
        char *msg = line + 4;
        size_t mlen = len - 4;
        while (mlen > 0 && (*msg == ' ' || *msg == '\'')) { msg++; mlen--; }
        while (mlen > 0 && msg[mlen-1] == '\'') mlen--;

        char errbuf[512];
        snprintf(errbuf, sizeof(errbuf), "%.*s", (int)mlen, msg);

        /* nats-server capitalizes these; strcasestr is not portable, so
           lowercase a bounded copy. Auth errors are fatal: no reconnect. */
        {
            char lc[512];
            size_t i, n = strlen(errbuf);
            for (i = 0; i < n; i++)
                lc[i] = (errbuf[i] >= 'A' && errbuf[i] <= 'Z')
                      ? errbuf[i] + ('a' - 'A') : errbuf[i];
            lc[n] = '\0';
            /* the server keeps the connection open after these */
            if (strncmp(lc, "permissions violation", 21) == 0
                || strncmp(lc, "invalid subject", 15) == 0
                || strncmp(lc, "maximum subscriptions exceeded", 30) == 0) {
                nats_emit_error(self, errbuf);
                return;
            }
            /* a timeout means the client was slow, not refused: retry */
            if ((strstr(lc, "authorization") || strstr(lc, "authentication"))
                && !strstr(lc, "authentication timeout"))
                self->intentional_disconnect = 1;
        }
        nats_fail(self, errbuf);
        return;
    }
}

/* ================================================================
 * IO callbacks
 * ================================================================ */

static int nats_failover_next_addr(nats_t *self)
{
    if (!self->ai_next) return 0;
    nats_stop_watchers(self);
    close(self->fd);
    self->fd = -1;
    nats_connect_tcp(self);
    return 1;
}

static void nats_on_read_inner(nats_t *self)
{

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
        /* the post-INFO upgrade is done: CONNECT goes over TLS */
        if (self->connecting) {
            if (!nats_send_connect(self))
                return;
            nats_try_write(self);
        }
        if (self->fd < 0)
            return;
    }
#endif

    buf_ensure(&self->rbuf, &self->rbuf_cap, self->rbuf_len + BUF_INIT_SIZE);

    ssize_t n = nats_io_read(self, self->rbuf + self->rbuf_len,
                             self->rbuf_cap - self->rbuf_len);

    if (n <= 0) {
        if (n == 0) {
            nats_cleanup(self);
        } else if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
            /* a refused nonblocking connect can surface here as a read
               error, before nats_on_write's SO_ERROR check -- fail over too */
            if (self->connect_pending && nats_failover_next_addr(self))
                return;
            nats_fail(self, strerror(errno));
        }
        return;
    }

    self->rbuf_len += n;
    nats_parse(self);
}

static void nats_dispatch_msg(nats_t *self, char *payload)
{
    size_t total = self->msg_total_len, hl = self->msg_hdr_len;

    if (!(self->inbox_sub_sid && self->msg_sid == self->inbox_sub_sid)) {
        nats_process_msg(self, payload, total);
        return;
    }
    self->msgs_in++;
    self->bytes_in += total;
    nats_check_inbox_response(self, self->rbuf + self->msg_subject_off, self->msg_subject_len,
                              payload + hl, total - hl, hl ? payload : NULL, hl);
}

/* The parse offset is committed past each frame before its callback runs,
   so a callback that re-enters the loop resumes after it; nothing reads
   rbuf after a callback returns, so a nested pass may compact it. */
static void nats_parse(nats_t *self)
{
    while (self->fd >= 0 && self->rbuf_off < self->rbuf_len) {
#ifdef HAVE_OPENSSL
        /* bytes after an INFO that started TLS belong to the handshake */
        if (self->ssl_handshaking) break;
#endif
        size_t off = self->rbuf_off;
        char *start = self->rbuf + off;
        char *nl = (char *)memchr(start, '\n', self->rbuf_len - off);
        if (!nl) {
            if (self->rbuf_len - off > MAX_INBOUND_LINE)
                nats_fail(self, "maximum control line exceeded");
            break;
        }
        size_t line_len = nl - start;
        size_t len = line_len > 0 && start[line_len - 1] == '\r' ? line_len - 1 : line_len;
        int hmsg = len >= 5 && memcmp(start, "HMSG ", 5) == 0;

        if (hmsg || (len >= 4 && memcmp(start, "MSG ", 4) == 0)) {
            size_t body_off = off + line_len + 1;
            /* An unparseable frame is dropped: the sender is trusted, and
               killing the connection over one corrupt frame is an outage. */
            if (nats_parse_msg_line(self, start, len, hmsg) != 0) {
                self->rbuf_off = body_off;
                continue;
            }
            if (self->msg_total_len > MAX_INBOUND_MSG) {
                nats_fail(self, "server sent message exceeding 64 MiB");
                break;
            }
            if (self->rbuf_len - body_off < self->msg_total_len + 2)
                break;
            self->rbuf_off = body_off + self->msg_total_len + 2;
            nats_dispatch_msg(self, self->rbuf + body_off);
        } else {
            self->rbuf_off = off + line_len + 1;
            nats_process_line(self, start, line_len);
        }
    }
    if (self->rbuf_off > 0) {
        self->rbuf_len -= self->rbuf_off;
        if (self->rbuf_len > 0)
            memmove(self->rbuf, self->rbuf + self->rbuf_off, self->rbuf_len);
        else
            buf_trim(&self->rbuf, &self->rbuf_cap);
        self->rbuf_off = 0;
    }
}

/* cb_depth bracket: DESTROY during the dispatch only sets destroy_pending
   and the free runs here. nats_destroy_now frees self - touch nothing after.
   libev runs watchers outside any perl statement, so mortals made here
   (the pins in nats_fail) need this scope or they live until EV::run returns. */
static void nats_unwind(nats_t *self);

static void nats_dispatch(nats_t *self, void (*inner)(nats_t *))
{
    SV *pin = self->owner_sv;
    self->cb_depth++;
    if (pin) SvREFCNT_inc(pin);
    ENTER; SAVETMPS;
    inner(self);
    FREETMPS; LEAVE;
    if (pin) SvREFCNT_dec(pin);
    nats_unwind(self);
}

/* Closes a cb_depth bracket, a watcher's or a method's that runs callbacks:
   the deferred free, then a held die or a handler-less error. */
static void nats_unwind(nats_t *self)
{
    if (--self->cb_depth == 0) {
        SV *die = self->pending_die;
        self->pending_die = NULL;
        if (self->destroy_pending)
            nats_destroy_now(self);
        else if (die) {
            Safefree(self->pending_croak);
            self->pending_croak = NULL;
        } else if (self->pending_croak)
            nats_fire_pending_croak(self);
        if (die)
            croak_sv(sv_2mortal(die));
    }
}

/* Opens the bracket in a method whose work can run callbacks (a synchronous
   write failure tears down): a die is held to nats_unwind, so it cannot cut
   that work short. */
#define NATS_HOLD_DIES(self) STMT_START { \
    if ((self)->owner_sv) \
        sv_2mortal(SvREFCNT_inc((self)->owner_sv)); \
    (self)->cb_depth++; \
} STMT_END

#define NATS_WATCHER_CB(name, wtype, member) \
    static void name(struct ev_loop *loop, wtype *w, int revents) \
    { \
        (void)loop; (void)revents; \
        nats_dispatch((nats_t *)((char *)w - offsetof(nats_t, member)), name##_inner); \
    }

NATS_WATCHER_CB(nats_on_read, ev_io, rio)

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
            self->slow_fired = 0;
            nats_fail(self, strerror(errno));
            return;
        }
        self->wbuf_off += n;
    }

    self->wbuf_off = 0;
    self->wbuf_len = 0;
    buf_trim(&self->wbuf, &self->wbuf_cap);
    self->slow_fired = 0;   /* buffer drained: re-arm slow-consumer edge */

    if (self->writing) {
        ev_io_stop(self->loop, &self->wio);
        self->writing = 0;
    }
}

static void nats_on_write_inner(nats_t *self)
{
    if (self->connect_pending) {
        int err = 0;
        socklen_t errlen = sizeof(err);
        getsockopt(self->fd, SOL_SOCKET, SO_ERROR, &err, &errlen);
        if (err) {
            if (!nats_failover_next_addr(self))
                nats_fail(self, strerror(err));
            return;
        }
        /* TCP connect complete. Fall through: wbuf may already hold part
           of the CONNECT flush; nats_try_write disarms wio once empty. */
        self->connect_pending = 0;
    }

#ifdef HAVE_OPENSSL
    /* resume a TLS handshake stalled on SSL_ERROR_WANT_WRITE */
    if (self->ssl_handshaking) {
        int hret = nats_ssl_handshake(self);
        if (hret < 0) {
            nats_ssl_fail(self, "SSL handshake failed");
            return;
        }
        if (hret == 0) return;
        self->ssl_handshaking = 0;
        if (self->connecting && !nats_send_connect(self))
            return;
    }
#endif

    nats_try_write(self);
}

NATS_WATCHER_CB(nats_on_write, ev_io, wio)

/* ================================================================
 * Timer callbacks
 * ================================================================ */

static void nats_on_connect_timeout_inner(nats_t *self)
{
    self->connect_timer_active = 0;
    /* an address that swallows the SYN: the host's next one may answer */
    if (self->connect_pending && nats_failover_next_addr(self))
        return;
    nats_fail(self, "connect timeout");
}

NATS_WATCHER_CB(nats_on_connect_timeout, ev_timer, connect_timer)

static void nats_on_reconnect_timer_inner(nats_t *self)
{
    self->reconnect_timer_active = 0;
    self->reconnect_attempts++;
    self->intentional_disconnect = 0;
    if (self->server_pool_count > 0)
        nats_next_server(self);
    nats_do_connect(self);
}

NATS_WATCHER_CB(nats_on_reconnect_timer, ev_timer, reconnect_timer)

static void nats_start_ping_timer(nats_t *self)
{
    if (self->ping_interval_ms <= 0) return;
    double interval = self->ping_interval_ms / 1000.0;
    ev_timer_set(&self->ping_timer, interval, interval);
    ev_timer_start(self->loop, &self->ping_timer);
    self->ping_timer_active = 1;
}

static void nats_on_ping_timer_inner(nats_t *self)
{
    self->pings_outstanding++;
    if (self->max_pings_outstanding > 0 &&
        self->pings_outstanding > self->max_pings_outstanding) {
        nats_fail(self, "stale connection");
        return;
    }

    wbuf_append(self, "PING\r\n", 6);
    nats_push_pong_marker(self);
    nats_try_write(self);
}

NATS_WATCHER_CB(nats_on_ping_timer, ev_timer, ping_timer)

/* ================================================================
 * Write coalescing via ev_prepare
 * ================================================================ */

static void nats_on_prepare_inner(nats_t *self)
{
    if (self->wbuf_dirty && self->fd >= 0) {
        self->wbuf_dirty = 0;
        nats_try_write(self);
    }
    /* Arm-on-demand: every producer either try_writes directly or goes
       through nats_schedule_write, so an empty wbuf needs no watcher. */
    if (self->prepare_active && self->wbuf_off >= self->wbuf_len) {
        ev_prepare_stop(self->loop, &self->prepare_watcher);
        self->prepare_active = 0;
    }
}

NATS_WATCHER_CB(nats_on_prepare, ev_prepare, prepare_watcher)

/* the callers keep using self: the pin is mortal, not released on return */
static void nats_fire_slow_consumer(nats_t *self)
{
    if (self->owner_sv)
        sv_2mortal(SvREFCNT_inc(self->owner_sv));
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVuv(self->wbuf_len - self->wbuf_off)));
    PUTBACK;
    nats_invoke(self, self->on_slow_consumer);
    FREETMPS; LEAVE;
}

/* Edge-triggered slow-consumer check, shared by the write path and batch
   end: fires once when the buffer crosses the threshold and re-arms when
   a later call finds it drained back below. */
static void
nats_slow_check(nats_t *self)
{
    if (self->slow_consumer_bytes == 0 || !self->on_slow_consumer)
        return;
    if ((self->wbuf_len - self->wbuf_off) > self->slow_consumer_bytes) {
        if (!self->slow_fired) {
            self->slow_fired = 1;
            nats_fire_slow_consumer(self);
        }
    } else {
        self->slow_fired = 0;
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

    nats_slow_check(self);
}

/* ================================================================
 * Request timeout
 * ================================================================ */

/* Deliberately not cb_depth-guarded: nats_t is touched only before the
   callback, and the req is unlinked, so a connection-destroying callback is
   harmless. A live timer implies a live nats_t: teardown stops them all. */
static void nats_on_request_timeout(struct ev_loop *loop, ev_timer *w, int revents)
{
    nats_req_t *req = (nats_req_t *)((char *)w - offsetof(nats_req_t, timer));
    nats_t *self = req->nats;
    SV *cb = req->cb;
    (void)loop; (void)revents;

    ngx_queue_remove(&req->queue);
    if (req->queued)
        nats_unqueue_requests(self, req->req_id);
    Safefree(req);
    if (cb) {
        ENTER;
        SAVEFREESV(cb);
        nats_call_str(self, cb, 1, "request timeout");
        LEAVE;
    }
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
    self->wait_bytes = 0;
    {
        ngx_queue_t *q;
        ngx_queue_foreach(q, &self->req_queue)
            ngx_queue_data(q, nats_req_t, queue)->queued = 0;
    }

    if (self->wbuf_len > self->wbuf_off)
        nats_try_write(self);
}

/* Protocol fields are space-delimited: a blank or control byte silently
   reinterprets the frame (truncated subject, spoofed reply-to), so every
   caller-supplied subject, reply-to and queue group goes through here. */
static int
nats_field_ok(const char *p, size_t len)
{
    size_t i;
    for (i = 0; i < len; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c <= 0x20 || c == 0x7f)
            return 0;
    }
    return 1;
}

/* Check before allocating queued writes so a cap refusal strands nothing.
   Connected writes bypass the cap. */
static int nats_queue_cap_ok(nats_t *self, size_t len)
{
    if (self->connected || self->reconnect_buf_size == 0)
        return 1;
    return self->wait_bytes <= self->reconnect_buf_size
        && len <= self->reconnect_buf_size - self->wait_bytes;
}

/* SUB and UNSUB never wait in wait_queue. Before CONNECT the registry alone
   is enough, as CONNECT replays it; after it they follow the CONNECT in
   wbuf, so a failed attempt drops them with it. */
static void nats_sub_write(nats_t *self, const char *buf, size_t n)
{
    if (!self->connected && !(self->connecting && self->connect_sent))
        return;
    wbuf_append(self, buf, n);
    nats_schedule_write(self);
}

/* Unqueue the PUBs of request req_id, or of every request when 0: a
   request reported failed must not be sent later. */
static void nats_unqueue_requests(nats_t *self, uint64_t req_id)
{
    ngx_queue_t *q, *next;
    for (q = ngx_queue_head(&self->wait_queue); q != ngx_queue_sentinel(&self->wait_queue); q = next) {
        nats_pub_t *pub = ngx_queue_data(q, nats_pub_t, queue);
        next = ngx_queue_next(q);
        if (!pub->req_id || (req_id && pub->req_id != req_id))
            continue;
        ngx_queue_remove(q);
        self->waiting_count--;
        self->wait_bytes -= pub->len;
        Safefree(pub->data);
        Safefree(pub);
    }
}

/* no connection attempt is coming for the requests still queued */
static void nats_drop_queued_requests(nats_t *self)
{
    nats_unqueue_requests(self, 0);
    nats_cancel_requests(self, "disconnected", 1);
}

static void nats_cap_check(nats_t *self, size_t len)
{
    if (!nats_queue_cap_ok(self, len))
        croak("reconnect buffer full (%" UVuf " byte limit)", (UV)self->reconnect_buf_size);
}

/* A caller-supplied subject, reply-to or queue group; an optional one is
   NULL when undef or empty. */
static const char *nats_token(SV *sv, STRLEN *len, const char *what, int optional)
{
    const char *p;
    *len = 0;
    if (!sv || !SvOK(sv)) {
        if (optional) return NULL;
        croak("%s required", what);
    }
    p = SvPV(sv, *len);
    if (*len == 0) {
        if (optional) return NULL;
        croak("%s must not be empty", what);
    }
    if (!nats_field_ok(p, *len))
        croak("%s must not contain whitespace", what);
    return p;
}

/* The server answers an empty token with -ERR 'Invalid Subject'. */
static void nats_subscription_subject_check(const char *p, STRLEN len)
{
    STRLEN i;
    if (p[0] == '.' || p[len - 1] == '.')
        croak("subject must not have an empty token");
    for (i = 1; i < len; i++)
        if (p[i] == '.' && p[i - 1] == '.')
            croak("subject must not have an empty token");
}

static const char *nats_bytes(SV *sv, STRLEN *len)
{
    if (sv && SvOK(sv))
        return SvPV(sv, *len);
    *len = 0;
    return "";
}

static const char *nats_headers_pv(SV *sv, STRLEN *len)
{
    const char *p;
    if (!SvOK(sv))
        croak("headers required");
    p = SvPV(sv, *len);
    if (*len == 0)
        croak("headers must not be empty");
    if (*len < 8 || memcmp(p, "NATS/1.0", 8) != 0)
        croak("headers must start with NATS/1.0");
    return p;
}

/* PUB, or HPUB when hdrs is set, formatted into cmd; every refusal croaks
   here, before anything is queued. */
static int nats_frame_cmd(nats_t *self, char *cmd, size_t cmdsz,
                          const char *subj, STRLEN subj_len,
                          const char *reply, STRLEN reply_len,
                          const char *hdrs, STRLEN h_len, STRLEN pay_len)
{
    unsigned long body = (unsigned long)(h_len + pay_len);
    int n;
    if (self->max_payload > 0 && body > (unsigned long)self->max_payload)
        croak("%s exceeds max_payload (%d)", hdrs ? "message" : "payload", self->max_payload);
    if (hdrs)
        n = reply
            ? snprintf(cmd, cmdsz, "HPUB %.*s %.*s %lu %lu\r\n", (int)subj_len, subj,
                       (int)reply_len, reply, (unsigned long)h_len, body)
            : snprintf(cmd, cmdsz, "HPUB %.*s %lu %lu\r\n", (int)subj_len, subj,
                       (unsigned long)h_len, body);
    else
        n = reply
            ? snprintf(cmd, cmdsz, "PUB %.*s %.*s %lu\r\n", (int)subj_len, subj,
                       (int)reply_len, reply, body)
            : snprintf(cmd, cmdsz, "PUB %.*s %lu\r\n", (int)subj_len, subj, body);
    if (n < 0 || (size_t)n >= cmdsz)
        croak("subject too long");
    nats_cap_check(self, n + body + 2);
    return n;
}

/* The caller checked the connection state (NATS_CROAK_UNLESS_CONNECTED)
   and nats_frame_cmd the cap, with no user code since: nothing here croaks. */
static void nats_frame_write(nats_t *self, const char *cmd, int n,
                             const char *hdrs, STRLEN h_len,
                             const char *pay, STRLEN pay_len, uint64_t req_id)
{
    size_t total = n + h_len + pay_len + 2;
    nats_pub_t *pub;
    self->msgs_out++;
    self->bytes_out += h_len + pay_len;
    if (self->connected) {
        wbuf_append(self, cmd, n);
        if (h_len > 0) wbuf_append(self, hdrs, h_len);
        if (pay_len > 0) wbuf_append(self, pay, pay_len);
        wbuf_append(self, "\r\n", 2);
        nats_schedule_write(self);
        return;
    }
    Newxz(pub, 1, nats_pub_t);
    Newx(pub->data, total, char);
    memcpy(pub->data, cmd, n);
    if (h_len > 0) memcpy(pub->data + n, hdrs, h_len);
    if (pay_len > 0) memcpy(pub->data + n + h_len, pay, pay_len);
    pub->data[total - 2] = '\r';
    pub->data[total - 1] = '\n';
    pub->len = total;
    pub->req_id = req_id;
    ngx_queue_insert_tail(&self->wait_queue, &pub->queue);
    self->waiting_count++;
    self->wait_bytes += total;
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
    int gave_up = 0;
    if (!self->intentional_disconnect && self->reconnect_enabled) {
        if (self->max_reconnect_attempts == 0 ||
            self->reconnect_attempts < self->max_reconnect_attempts) {
            /* Exponential backoff with jitter */
            int shift = self->reconnect_attempts > 5 ? 5 : self->reconnect_attempts;
            int delay = self->reconnect_delay_ms * (1 << shift);
            if (self->max_reconnect_delay_ms > 0 && delay > self->max_reconnect_delay_ms)
                delay = self->max_reconnect_delay_ms;
            /* Floor: a zero delay would spin the loop at full tilt. */
            if (delay < 100)
                delay = 100;
            double base = delay / 1000.0;
            unsigned char r[2];
            nats_random_bytes(r, 2);
            unsigned int rv = ((unsigned)r[0] << 8) | r[1];
            double jitter = base * (0.5 + (double)(rv % 1000) / 2000.0);
            ev_timer_set(&self->reconnect_timer, jitter, 0.0);
            ev_timer_start(self->loop, &self->reconnect_timer);
            self->reconnect_timer_active = 1;
        } else {
            gave_up = 1;
        }
    }
    if (!self->reconnect_timer_active)
        nats_drop_queued_requests(self);
    /* the connection a queued flush waited for has failed */
    nats_fail_pong_queue(self, &self->flush_wait);
    if (gave_up)
        nats_emit_error(self, "max reconnect attempts reached");
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

static nats_server_t *nats_pool_find(nats_t *self, const char *host, size_t hlen, int port)
{
    ngx_queue_t *q;
    ngx_queue_foreach(q, &self->server_pool) {
        nats_server_t *srv = ngx_queue_data(q, nats_server_t, queue);
        if (srv->port == port && strlen(srv->host) == hlen &&
            memcmp(srv->host, host, hlen) == 0)
            return srv;
    }
    return NULL;
}

static nats_server_t *nats_pool_add(nats_t *self, const char *host, size_t hlen, int port, int implicit)
{
    nats_server_t *srv;
    if (self->server_pool_count >= MAX_SERVER_POOL)
        return NULL;
    Newxz(srv, 1, nats_server_t);
    nats_set_strn(&srv->host, host, hlen);
    srv->port = port;
    srv->implicit = implicit;
    srv->seen = 1;
    ngx_queue_insert_tail(&self->server_pool, &srv->queue);
    self->server_pool_count++;
    return srv;
}

/* As nats.go: learned servers no longer advertised are dropped; the
   configured server and the current one always stay. */
static void nats_parse_connect_urls(nats_t *self, const char *json, size_t len)
{
    const char *key = "\"connect_urls\":[";
    const char *p = nats_memfind(json, len, key, strlen(key));
    ngx_queue_t *q, *next;
    nats_server_t *cur;
    int first = ngx_queue_empty(&self->server_pool);
    if (!p) return;

    p += strlen(key);
    const char *end = json + len;

    ngx_queue_foreach(q, &self->server_pool)
        ngx_queue_data(q, nats_server_t, queue)->seen = 0;

    while (p < end && *p != ']') {
        while (p < end && (*p == ' ' || *p == ',' || *p == '"')) p++;
        if (p >= end || *p == ']') break;

        const char *start = p;
        if (p < end && *p == '[') {
            /* Bracketed IPv6 literal: consume through the closing bracket
               so the ']' terminator below doesn't split host from port.
               Bounded to this entry: an unbalanced '[' must not swallow
               the entries that follow it. */
            const char *q = p + 1;
            while (q < end && *q != ']' && *q != '"' && *q != ',') q++;
            if (q < end && *q == ']') p = (char *)q + 1;
        }
        while (p < end && *p != '"' && *p != ',' && *p != ']') p++;

        size_t url_len = p - start;
        if (url_len > 0) {
            /* Split host and port. IPv6 arrives bracketed ("[::1]:4222");
               strip the brackets, which getaddrinfo rejects. */
            const char *hstart = start;
            const char *hend = start + url_len;
            const char *pstart = NULL;
            size_t plen = 0;
            if (url_len > 2 && start[0] == '[') {
                const char *rb = memchr(start + 1, ']', url_len - 1);
                if (rb) {
                    hstart = start + 1;
                    hend = rb;
                    if (rb + 1 < start + url_len && rb[1] == ':') {
                        pstart = rb + 2;
                        plen = (start + url_len) - pstart;
                    }
                }
            } else {
                const char *colon = NULL;
                const char *s;
                for (s = start + url_len - 1; s >= start; s--) {
                    if (*s == ':') { colon = s; break; }
                }
                if (colon && colon > start) {
                    hend = colon;
                    pstart = colon + 1;
                    plen = (start + url_len) - pstart;
                }
            }

            int port = 4222;
            if (pstart && plen > 0) {
                long pval = 0;
                size_t i;
                for (i = 0; i < plen && pstart[i] >= '0' && pstart[i] <= '9'; i++) {
                    pval = pval * 10 + (pstart[i] - '0');
                    if (pval > 65535) { pval = 65535; break; }
                }
                if (i > 0)
                    port = (int)pval;
            }
            size_t hlen = hend - hstart;
            nats_server_t *srv = nats_pool_find(self, hstart, hlen, port);
            if (srv)
                srv->seen = 1;
            else
                nats_pool_add(self, hstart, hlen, port, 1);
        }

        while (p < end && *p == '"') p++;
    }

    if (!self->host)
        return;
    cur = nats_pool_find(self, self->host, strlen(self->host), self->port);
    for (q = ngx_queue_head(&self->server_pool); q != ngx_queue_sentinel(&self->server_pool); q = next) {
        nats_server_t *srv = ngx_queue_data(q, nats_server_t, queue);
        next = ngx_queue_next(q);
        if (srv->implicit && !srv->seen && srv != cur) {
            ngx_queue_remove(q);
            Safefree(srv->host);
            Safefree(srv);
            self->server_pool_count--;
        }
    }
    /* the current server stays even when it omits itself */
    if (!cur)
        cur = nats_pool_add(self, self->host, strlen(self->host), self->port, 1);
    /* first INFO after connect(): the current server is the configured one */
    if (cur && first)
        cur->implicit = 0;
}

static void nats_next_server(nats_t *self)
{
    if (ngx_queue_empty(&self->server_pool)) return;

    /* take the head, then rotate it to the tail */
    ngx_queue_t *q = ngx_queue_head(&self->server_pool);
    nats_server_t *srv = ngx_queue_data(q, nats_server_t, queue);

    nats_set_str(&self->host, srv->host);
    self->port = srv->port;
    /* host changed: any saved getaddrinfo candidates are stale */
    nats_free_addrinfo(self);

    ngx_queue_remove(q);
    ngx_queue_insert_tail(&self->server_pool, q);
}

/* rv: the connect(2) result, nonzero for EINPROGRESS */
static void nats_after_connect(nats_t *self, int fd, int rv)
{
#ifdef SO_NOSIGPIPE
    int flag = 1;
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &flag, sizeof(flag));
#endif
    self->fd = fd;
    self->conn_gen++;
    self->connecting = 1;
    self->connected = 0;
    /* EINPROGRESS: the first EV_WRITE must SO_ERROR-check the connect */
    self->connect_pending = (rv != 0);

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
        /* failover re-enters here with the timer still running: ev_timer_set
           on an active watcher corrupts libev's heap key, so stop it first */
        if (self->connect_timer_active) {
            ev_timer_stop(self->loop, &self->connect_timer);
            self->connect_timer_active = 0;
        }
        ev_now_update(self->loop);
        ev_timer_set(&self->connect_timer, self->connect_timeout_ms / 1000.0, 0.0);
        ev_timer_start(self->loop, &self->connect_timer);
        self->connect_timer_active = 1;
    }
}

static void nats_free_addrinfo(nats_t *self)
{
    if (self->ai_res)
        freeaddrinfo(self->ai_res);
    self->ai_res = NULL;
    self->ai_next = NULL;
}

/* Actual teardown behind DESTROY. With cb_depth > 0 DESTROY only sets
   destroy_pending and the outermost nats_on_* wrapper runs this once the
   callback returns. Callers must not touch self after this. */
static void nats_destroy_now(nats_t *self)
{
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

    nats_free_pong_queue(&self->pong_cbs);
    nats_free_pong_queue(&self->flush_wait);
    while (!ngx_queue_empty(&self->disc_watch)) {
        ngx_queue_t *q = ngx_queue_head(&self->disc_watch);
        nats_watch_t *w = ngx_queue_data(q, nats_watch_t, queue);
        ngx_queue_remove(q);
        CLEAR_HANDLER(w->cb);
        Safefree(w);
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
    nats_free_addrinfo(self);

    CLEAR_HANDLER(self->server_info_json);
    CLEAR_HANDLER(self->drain_cb);
    Safefree(self->pending_croak);
    CLEAR_HANDLER(self->pending_die);

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
    CLEAR_HANDLER(self->loop_sv);

    Safefree(self);
}

static int nats_socket(int domain, int type, int protocol)
{
#ifdef SOCK_CLOEXEC
    return socket(domain, type | SOCK_CLOEXEC, protocol);
#else
    int fd = socket(domain, type, protocol);
    if (fd >= 0)
        fcntl(fd, F_SETFD, FD_CLOEXEC);
    return fd;
#endif
}

static void nats_connect_tcp(nats_t *self)
{
    struct addrinfo hints, *rp;
    char port_str[8];
    int fd = -1;
    int rv = 0;

    /* Resolve once per host and keep the list: a connect that later fails
       via SO_ERROR fails over to the remaining candidates. */
    if (!self->ai_res) {
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;

        snprintf(port_str, sizeof(port_str), "%d", self->port);

        rv = getaddrinfo(self->host, port_str, &hints, &self->ai_res);
        if (rv != 0) {
            self->ai_res = NULL;
            nats_emit_error(self, gai_strerror(rv));
            nats_schedule_reconnect(self);
            return;
        }
        self->ai_next = self->ai_res;
    }

    for (rp = self->ai_next; rp != NULL; rp = rp->ai_next) {
        fd = nats_socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
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
        if (rv == 0 || errno == EINPROGRESS) {
            self->ai_next = rp->ai_next;
            nats_after_connect(self, fd, rv);
            return;
        }

        close(fd);
        fd = -1;
    }

    /* Address list exhausted: drop it so the next attempt re-resolves. */
    nats_free_addrinfo(self);

    if (self->connecting) {
        /* failover from an attempt in flight: unwind it, or it wedges */
        nats_fail(self, "connection failed");
        return;
    }
    nats_emit_error(self, "connection failed");
    nats_schedule_reconnect(self);
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

    fd = nats_socket(AF_UNIX, SOCK_STREAM, 0);
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

    nats_after_connect(self, fd, rv);
}

static void nats_do_connect(nats_t *self)
{
    if (self->path)
        nats_connect_unix(self);
    else
        nats_connect_tcp(self);
}

/* request() and hrequest(): headers is NULL for a plain PUB */
static void nats_request(nats_t *self, SV *subject, SV *headers, SV *payload,
                         SV *cb, int timeout_ms)
{
    char reply_subj[INBOX_SUBJ_SIZE];
    char cmd[MAX_CONTROL_LINE];
    STRLEN subj_len, pay_len, h_len = 0;
    const char *subj, *pay, *hdrs = NULL;

    NATS_CROAK_UNLESS_CONNECTED(self);
    subj = nats_token(subject, &subj_len, "subject", 0);
    if (headers)
        hdrs = nats_headers_pv(headers, &h_len);
    pay = nats_bytes(payload, &pay_len);
    /* the writes below can run on_slow_consumer, which may drop the last ref */
    if (self->owner_sv)
        sv_2mortal(SvREFCNT_inc(self->owner_sv));

    /* every refusal croaks before anything is registered or queued */
    uint64_t req_id = self->next_req_id;
    int rlen = snprintf(reply_subj, sizeof(reply_subj), "%s%llu",
                        self->inbox_prefix, (unsigned long long)req_id);
    int n = nats_frame_cmd(self, cmd, sizeof(cmd), subj, subj_len, reply_subj, rlen,
                           hdrs, h_len, pay_len);
    /* taken before the SUB write, whose on_slow_consumer may request too */
    self->next_req_id++;

    if (!self->inbox_sub_sid) {
        char sbuf[MAX_CONTROL_LINE];
        int sn = snprintf(sbuf, sizeof(sbuf), "SUB %s* %" UVuf "\r\n",
                          self->inbox_prefix, (UV)self->next_sid);
        nats_sub_t *sub;
        Newxz(sub, 1, nats_sub_t);
        sub->sid = self->next_sid++;
        sub->subject = newSVpvn(sbuf + 4, strlen(self->inbox_prefix) + 1);
        nats_register_sub(self, sub);
        self->inbox_sub_sid = sub->sid;
        nats_sub_write(self, sbuf, sn);
        /* the write may have run an on_slow_consumer that disconnected */
        NATS_CROAK_UNLESS_CONNECTED(self);
    }

    nats_req_t *req;
    Newxz(req, 1, nats_req_t);
    req->req_id = req_id;
    req->nats = self;
    req->cb = newSVsv(cb);
    req->queued = !self->connected;
    ngx_queue_insert_tail(&self->req_queue, &req->queue);

    if (timeout_ms > 0) {
        ev_now_update(self->loop);
        ev_timer_init(&req->timer, nats_on_request_timeout, timeout_ms / 1000.0, 0.0);
        ev_timer_start(self->loop, &req->timer);
        req->timer_active = 1;
    }

    nats_frame_write(self, cmd, n, hdrs, h_len, pay, pay_len, req_id);
}

/* ================================================================
 * XS interface
 * ================================================================ */

/* an explicit target supersedes the discovered pool; its INFO repopulates it */
static void nats_connect_begin(nats_t *self)
{
    if (self->connected || self->connecting)
        croak("already connected");
    if (self->owner_sv)
        sv_2mortal(SvREFCNT_inc(self->owner_sv));
    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
    self->intentional_disconnect = 0;
    self->reconnect_attempts = 0;
    nats_free_server_pool(self);
}

MODULE = EV::Nats  PACKAGE = EV::Nats

PROTOTYPES: DISABLE

BOOT:
{
    I_EV_API("EV::Nats");
    nats_stash = gv_stashpv("EV::Nats", GV_ADD);
#ifdef HAVE_OPENSSL
    newCONSTSUB(nats_stash, "HAS_TLS",  newSViv(1));
    newCONSTSUB(nats_stash, "HAS_NKEY", newSViv(1));
#else
    newCONSTSUB(nats_stash, "HAS_TLS",  newSViv(0));
    newCONSTSUB(nats_stash, "HAS_NKEY", newSViv(0));
#endif
}

SV *
new(class, ...)
    char *class
  PREINIT:
    nats_t *self;
    int i;
    SV *obj;
  CODE:
    Newxz(self, 1, nats_t);
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
    self->reconnect_buf_size = 8 * 1024 * 1024;

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
    ngx_queue_init(&self->flush_wait);
    ngx_queue_init(&self->disc_watch);
    self->sub_map = newHV();

    nats_setup_inbox(self, "_INBOX");

    /* mortal until returned: a croaking option frees self through DESTROY */
    obj = sv_2mortal(newRV_noinc(newSViv(PTR2IV(self))));
    sv_bless(obj, gv_stashpv(class, GV_ADD));
    self->owner_sv = SvRV(obj);

    if (items > 1 && (items - 1) % 2 == 0) {
        for (i = 1; i < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);

            if      (strcmp(key, "host")  == 0) nats_set_str_sv(&self->host,  val);
            else if (strcmp(key, "port")  == 0) self->port = nats_int(val);
            else if (strcmp(key, "path")  == 0) nats_set_str_sv(&self->path,  val);
            else if (strcmp(key, "user")  == 0) nats_set_str_sv(&self->user,  val);
            else if (strcmp(key, "pass")  == 0) nats_set_str_sv(&self->pass,  val);
            else if (strcmp(key, "token") == 0) nats_set_str_sv(&self->token, val);
            else if (strcmp(key, "name")  == 0) nats_set_str_sv(&self->name,  val);
            else if (strcmp(key, "on_error") == 0)
                self->on_error = SvOK(val) ? newSVsv(val) : NULL;
            else if (strcmp(key, "on_connect") == 0)
                self->on_connect = SvOK(val) ? newSVsv(val) : NULL;
            else if (strcmp(key, "on_disconnect") == 0)
                self->on_disconnect = SvOK(val) ? newSVsv(val) : NULL;
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
                self->reconnect_delay_ms = nats_int(val);
            else if (strcmp(key, "max_reconnect_attempts") == 0)
                self->max_reconnect_attempts = nats_int(val);
            else if (strcmp(key, "max_reconnect_delay") == 0)
                self->max_reconnect_delay_ms = nats_int(val);
            else if (strcmp(key, "reconnect_buf_size") == 0) {
                IV v = SvIV(val);
                self->reconnect_buf_size = v < 0 ? 0 : (size_t)v;
            }
            else if (strcmp(key, "connect_timeout") == 0)
                self->connect_timeout_ms = nats_int(val);
            else if (strcmp(key, "ping_interval") == 0)
                self->ping_interval_ms = nats_int(val);
            else if (strcmp(key, "max_pings_outstanding") == 0)
                self->max_pings_outstanding = nats_int(val);
            else if (strcmp(key, "priority") == 0) {
                IV v = SvIV(val);
                if (v < -2 || v > 2)
                    croak("EV::Nats::new: 'priority' must be between -2 and +2");
                self->priority = (int)v;
            }
            else if (strcmp(key, "keepalive") == 0)
                self->keepalive = nats_int(val);
#ifndef HAVE_OPENSSL
            /* refused rather than ignored: plaintext would send the credentials */
            else if ((strcmp(key, "tls") == 0 && SvTRUE(val))
                     || (strcmp(key, "tls_ca_file") == 0 && SvOK(val))
                     || (strcmp(key, "nkey_seed") == 0 && SvOK(val)))
                croak("EV::Nats::new: '%s' needs a build with OpenSSL", key);
            else if (strcmp(key, "tls") == 0 || strcmp(key, "tls_ca_file") == 0
                     || strcmp(key, "tls_skip_verify") == 0 || strcmp(key, "nkey_seed") == 0) {
                /* off or unset: nothing to refuse */
            }
#else
            else if (strcmp(key, "tls") == 0)
                self->tls = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "tls_ca_file") == 0)
                nats_set_str_sv(&self->tls_ca_file, val);
            else if (strcmp(key, "tls_skip_verify") == 0)
                self->tls_skip_verify = SvTRUE(val) ? 1 : 0;
            else if (strcmp(key, "nkey_seed") == 0) {
                if (SvOK(val)) {
                    STRLEN slen;
                    const char *seed = SvPV(val, slen);
                    char pub[64];
                    if (nats_nkey_public(seed, pub, sizeof(pub)) <= 0)
                        croak("invalid NKey seed");
                }
                nats_set_str_sv(&self->nkey_seed, val);
            }
#endif
            else if (strcmp(key, "jwt") == 0)
                nats_set_str_sv(&self->jwt, val);
            else if (strcmp(key, "slow_consumer_bytes") == 0)
                self->slow_consumer_bytes = (size_t)SvUV(val);
            else if (strcmp(key, "on_slow_consumer") == 0)
                self->on_slow_consumer = SvOK(val) ? newSVsv(val) : NULL;
            else if (strcmp(key, "on_lame_duck") == 0)
                self->on_ldm = SvOK(val) ? newSVsv(val) : NULL;
            else if (strcmp(key, "inbox_prefix") == 0) {
                if (SvOK(val)) {
                    STRLEN blen;
                    const char *base = SvPV(val, blen);
                    if (!nats_inbox_base_ok(base, blen))
                        croak("EV::Nats::new: invalid 'inbox_prefix'");
                    nats_setup_inbox(self, base);
                }
            }
            else if (strcmp(key, "loop") == 0) {
                if (!SvOK(val)) {
                    /* undef: keep the default loop */
                } else if (SvROK(val) && sv_derived_from(val, "EV::Loop")) {
                    self->loop = (struct ev_loop *)SvIVx(SvRV(val));
                    CLEAR_HANDLER(self->loop_sv);
                    self->loop_sv = newSVsv(val);
                } else {
                    croak("EV::Nats::new: 'loop' must be an EV::Loop");
                }
            }
            else
                warn("EV::Nats::new: unknown option '%s'", key);
        }
    }

    if (self->host || self->path) {
        NATS_HOLD_DIES(self);
        nats_do_connect(self);
        nats_unwind(self);
    }

    RETVAL = SvREFCNT_inc_simple_NN(obj);
  OUTPUT:
    RETVAL

void
connect(self, host, port = 4222)
    EV::Nats self
    char *host
    int port
  CODE:
    nats_connect_begin(self);
    nats_set_str(&self->path, NULL);
    nats_set_str(&self->host, host);
    self->port = port;
    NATS_HOLD_DIES(self);
    nats_connect_tcp(self);
    nats_unwind(self);

void
connect_unix(self, path)
    EV::Nats self
    char *path
  CODE:
    nats_connect_begin(self);
    nats_set_str(&self->host, NULL);
    nats_set_str(&self->path, path);
    NATS_HOLD_DIES(self);
    nats_connect_unix(self);
    nats_unwind(self);

void
disconnect(self)
    EV::Nats self
  CODE:
    NATS_HOLD_DIES(self);
    self->intentional_disconnect = 1;
    if (self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
    }
    nats_skip_waiting(self);
    nats_cancel_requests(self, "disconnected", 1);
    nats_cleanup(self);
    nats_unwind(self);

int
is_connected(self)
    EV::Nats self
  CODE:
    RETVAL = self->connected;
  OUTPUT:
    RETVAL

SV *
timer(self, after, repeat, cb)
    EV::Nats self
    NV after
    NV repeat
    SV *cb
  CODE:
    {
        dSP;
        ev_now_update(self->loop);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 4);
        if (self->loop_sv) PUSHs(self->loop_sv);
        PUSHs(sv_2mortal(newSVnv(after)));
        PUSHs(sv_2mortal(newSVnv(repeat)));
        PUSHs(cb);
        PUTBACK;
        call_pv(self->loop_sv ? "EV::Loop::timer" : "EV::timer", G_SCALAR);
        SPAGAIN;
        RETVAL = newSVsv(POPs);
        PUTBACK;
        FREETMPS; LEAVE;
    }
  OUTPUT:
    RETVAL

UV
watch_disconnect(self, cb)
    EV::Nats self
    SV *cb
  CODE:
    nats_watch_t *w;
    Newxz(w, 1, nats_watch_t);
    w->id = ++self->next_watch_id;
    w->cb = newSVsv(cb);
    ngx_queue_insert_tail(&self->disc_watch, &w->queue);
    RETVAL = (UV)w->id;
  OUTPUT:
    RETVAL

void
unwatch_disconnect(self, id)
    EV::Nats self
    UV id
  CODE:
    ngx_queue_t *q;
    ngx_queue_foreach(q, &self->disc_watch) {
        nats_watch_t *w = ngx_queue_data(q, nats_watch_t, queue);
        if (w->id == (uint64_t)id) {
            ngx_queue_remove(q);
            SvREFCNT_dec(w->cb);
            Safefree(w);
            break;
        }
    }

void
publish(self, subject, payload = &PL_sv_undef, reply = &PL_sv_undef)
    EV::Nats self
    SV *subject
    SV *payload
    SV *reply
  PREINIT:
    char cmd[MAX_CONTROL_LINE];
    STRLEN subj_len, reply_len, pay_len;
    const char *subj, *rep, *pay;
    int n;
  CODE:
    NATS_CROAK_UNLESS_CONNECTED(self);
    subj = nats_token(subject, &subj_len, "subject", 0);
    rep = nats_token(reply, &reply_len, "reply subject", 1);
    pay = nats_bytes(payload, &pay_len);
    n = nats_frame_cmd(self, cmd, sizeof(cmd), subj, subj_len, rep, reply_len, NULL, 0, pay_len);
    nats_frame_write(self, cmd, n, NULL, 0, pay, pay_len, 0);

void
hpublish(self, subject, headers, payload = &PL_sv_undef, reply = &PL_sv_undef)
    EV::Nats self
    SV *subject
    SV *headers
    SV *payload
    SV *reply
  PREINIT:
    char cmd[MAX_CONTROL_LINE];
    STRLEN subj_len, reply_len, h_len, pay_len;
    const char *subj, *rep, *hdrs, *pay;
    int n;
  CODE:
    NATS_CROAK_UNLESS_CONNECTED(self);
    subj = nats_token(subject, &subj_len, "subject", 0);
    rep = nats_token(reply, &reply_len, "reply subject", 1);
    hdrs = nats_headers_pv(headers, &h_len);
    pay = nats_bytes(payload, &pay_len);
    n = nats_frame_cmd(self, cmd, sizeof(cmd), subj, subj_len, rep, reply_len, hdrs, h_len, pay_len);
    nats_frame_write(self, cmd, n, hdrs, h_len, pay, pay_len, 0);

UV
subscribe(self, subject, cb, queue_group = &PL_sv_undef)
    EV::Nats self
    SV *subject
    SV *cb
    SV *queue_group
  PREINIT:
    nats_sub_t *sub;
    char buf[MAX_CONTROL_LINE];
    STRLEN subj_len, group_len;
    const char *subj, *group;
  CODE:
    subj = nats_token(subject, &subj_len, "subject", 0);
    nats_subscription_subject_check(subj, subj_len);
    group = nats_token(queue_group, &group_len, "queue group", 1);
    if (!SvROK(cb) || (SvTYPE(SvRV(cb)) != SVt_PVCV && !SvAMAGIC(cb)))
        croak("callback must be a code reference");

    /* formatted before anything is registered: a refusal strands nothing */
    uint64_t sid = self->next_sid;
    int n = group
        ? snprintf(buf, sizeof(buf), "SUB %.*s %.*s %" UVuf "\r\n",
                   (int)subj_len, subj, (int)group_len, group, (UV)sid)
        : snprintf(buf, sizeof(buf), "SUB %.*s %" UVuf "\r\n",
                   (int)subj_len, subj, (UV)sid);
    if (n < 0 || n >= (int)sizeof(buf))
        croak("subject too long");

    Newxz(sub, 1, nats_sub_t);
    sub->sid = self->next_sid++;
    sub->subject = newSVpvn(subj, subj_len);
    sub->cb = newSVsv(cb);
    sub->queue_group = group ? newSVpvn(group, group_len) : NULL;
    nats_register_sub(self, sub);
    nats_sub_write(self, buf, n);

    RETVAL = (UV)sid;
  OUTPUT:
    RETVAL

void
unsubscribe(self, sid, max_msgs_iv = 0)
    EV::Nats self
    UV sid
    IV max_msgs_iv
  PREINIT:
    char buf[64];
    int n;
    int max_msgs;
  CODE:
    max_msgs = nats_clamp(max_msgs_iv);
    nats_sub_t *sub = nats_find_sub(self, (uint64_t)sid);

    if (max_msgs > 0 && !(sub && sub->received >= max_msgs)) {
        if (sub)
            sub->max_msgs = max_msgs;
        n = snprintf(buf, sizeof(buf), "UNSUB %" UVuf " %d\r\n", sid, max_msgs);
    } else {
        if (sub)
            nats_remove_sub(self, sub);
        n = snprintf(buf, sizeof(buf), "UNSUB %" UVuf "\r\n", sid);
    }
    nats_sub_write(self, buf, n);

void
request(self, subject, payload, cb, timeout_ms = 5000)
    EV::Nats self
    SV *subject
    SV *payload
    SV *cb
    IV timeout_ms
  CODE:
    nats_request(self, subject, NULL, payload, cb, nats_clamp(timeout_ms));

void
hrequest(self, subject, headers, payload, cb, timeout_ms = 5000)
    EV::Nats self
    SV *subject
    SV *headers
    SV *payload
    SV *cb
    IV timeout_ms
  CODE:
    nats_request(self, subject, headers, payload, cb, nats_clamp(timeout_ms));

void
ping(self)
    EV::Nats self
  CODE:
    /* Unlike publish, a PING cannot be deferred: bytes appended pre-CONNECT
       would hit the wire before the CONNECT handshake. */
    if (!self->connected)
        croak("not connected");
    wbuf_append(self, "PING\r\n", 6);
    nats_push_pong_marker(self);
    NATS_HOLD_DIES(self);
    nats_try_write(self);
    nats_unwind(self);

void
flush(self, cb = NULL)
    EV::Nats self
    SV *cb
  PREINIT:
    nats_pong_cb_t *pcb;
  CODE:
    if (cb && !SvOK(cb))
        cb = NULL;
    if (!self->connected && !NATS_PENDING(self)) {
        if (!cb)
            croak("not connected");
        nats_defer_err(self, cb, "not connected");
        XSRETURN_EMPTY;
    }
    Newxz(pcb, 1, nats_pong_cb_t);
    if (cb)
        pcb->cb = newSVsv(cb);
    if (!self->connected) {
        ngx_queue_insert_tail(&self->flush_wait, &pcb->queue);
        XSRETURN_EMPTY;
    }
    wbuf_append(self, "PING\r\n", 6);
    /* Queue before the write, always (a NULL-cb placeholder without a
       callback): on a synchronous write failure nats_cleanup drains this
       entry instead of stranding it, and the 1:1 PING/PONG accounting
       survives a cb-less flush. */
    ngx_queue_insert_tail(&self->pong_cbs, &pcb->queue);
    NATS_HOLD_DIES(self);
    nats_try_write(self);
    nats_unwind(self);

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
    if (items > 1) {
        IV v = SvIV(ST(1));
        /* clamp: a negative limit would wrap to SIZE_MAX in the size_t guards */
        self->max_payload = v < 0 ? 0 : (v > INT_MAX ? INT_MAX : (int)v);
    }
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
    NATS_HOLD_DIES(self);
    nats_skip_waiting(self);
    nats_cancel_requests(self, "disconnected", 1);
    nats_unwind(self);

void
reconnect(self, enable, ...)
    EV::Nats self
    int enable
  CODE:
    self->reconnect_enabled = enable;
    if (items > 2) self->reconnect_delay_ms = nats_int(ST(2));
    if (items > 3) self->max_reconnect_attempts = nats_int(ST(3));
    if (!enable && self->reconnect_timer_active) {
        ev_timer_stop(self->loop, &self->reconnect_timer);
        self->reconnect_timer_active = 0;
        NATS_HOLD_DIES(self);
        nats_drop_queued_requests(self);
        nats_fail_pong_queue(self, &self->flush_wait);
        nats_unwind(self);
    }

int
reconnect_enabled(self)
    EV::Nats self
  CODE:
    RETVAL = self->reconnect_enabled;
  OUTPUT:
    RETVAL

UV
reconnect_buf_size(self, ...)
    EV::Nats self
  CODE:
    if (items > 1) {
        IV v = SvIV(ST(1));
        self->reconnect_buf_size = v < 0 ? 0 : (size_t)v;
    }
    RETVAL = (UV)self->reconnect_buf_size;
  OUTPUT:
    RETVAL

int
connect_timeout(self, ...)
    EV::Nats self
  ALIAS:
    max_pings_outstanding = 1
    keepalive = 2
  PREINIT:
    int *slot;
  CODE:
    slot = ix == 0 ? &self->connect_timeout_ms
         : ix == 1 ? &self->max_pings_outstanding : &self->keepalive;
    if (items > 1)
        *slot = nats_int(ST(1));
    RETVAL = *slot;
  OUTPUT:
    RETVAL

int
ping_interval(self, ...)
    EV::Nats self
  CODE:
    if (items > 1) {
        self->ping_interval_ms = nats_int(ST(1));
        /* ev_timer_set on an active watcher corrupts libev's heap */
        if (self->ping_timer_active) {
            ev_timer_stop(self->loop, &self->ping_timer);
            self->ping_timer_active = 0;
        }
        if (self->connected)
            nats_start_ping_timer(self);
    }
    RETVAL = self->ping_interval_ms;
  OUTPUT:
    RETVAL

int
priority(self, ...)
    EV::Nats self
  CODE:
    if (items > 1) {
        IV v = SvIV(ST(1));
        if (v < -2 || v > 2)
            croak("priority must be between -2 and +2");
        self->priority = (int)v;
    }
    RETVAL = self->priority;
  OUTPUT:
    RETVAL

void
on_error(self, ...)
    EV::Nats self
  ALIAS:
    on_connect = 1
    on_disconnect = 2
    on_lame_duck = 3
  PREINIT:
    SV **slot;
  PPCODE:
    slot = ix == 0 ? &self->on_error : ix == 1 ? &self->on_connect
         : ix == 2 ? &self->on_disconnect : &self->on_ldm;
    if (items > 1) {
        CLEAR_HANDLER(*slot);
        if (SvOK(ST(1)))
            *slot = newSVsv(ST(1));
    }
    if (GIMME_V != G_VOID && *slot)
        PUSHs(sv_2mortal(newSVsv(*slot)));

#ifdef HAVE_OPENSSL

void
tls(self, enable, ca_file = &PL_sv_undef, skip_verify = 0)
    EV::Nats self
    int enable
    SV *ca_file
    int skip_verify
  PREINIT:
    STRLEN ca_len = 0;
    const char *ca;
  CODE:
    ca = SvOK(ca_file) ? SvPV(ca_file, ca_len) : NULL;
    self->tls = enable;
    self->tls_skip_verify = skip_verify;
    nats_set_strn(&self->tls_ca_file, ca_len ? ca : NULL, ca_len);
    /* Drop the cached context so the next handshake picks the new CA and
       verify mode up; an active SSL holds its own reference, so this is
       safe on a live connection. */
    if (self->ssl_ctx) {
        SSL_CTX_free(self->ssl_ctx);
        self->ssl_ctx = NULL;
    }

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
    char inbox[INBOX_SUBJ_SIZE];
    int len = snprintf(inbox, sizeof(inbox), "%s%llu", self->user_inbox_prefix,
                       (unsigned long long)self->next_req_id++);
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

int
is_subscribed(self, sid)
    EV::Nats self
    UV sid
  CODE:
    RETVAL = nats_find_sub(self, (uint64_t)sid) != NULL;
  OUTPUT:
    RETVAL

void
batch(self, code)
    EV::Nats self
    SV *code
  CODE:
    self->batch_mode = 1;
    SV *pin = self->owner_sv;
    if (pin) SvREFCNT_inc(pin);
    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        /* G_EVAL: a die() must not longjmp past the batch_mode reset below;
           that would wedge the write path for the connection's lifetime */
        call_sv(code, G_DISCARD | G_EVAL);
        FREETMPS; LEAVE;
    }
    self->batch_mode = 0;
    if (self->wbuf_len > self->wbuf_off)
        nats_schedule_write(self);
    if (pin) SvREFCNT_dec(pin);
    /* state restored; rethrow so the caller still sees the exception */
    if (SvTRUE(ERRSV))
        croak_sv(ERRSV);

void
slow_consumer(self, bytes_threshold, cb = NULL)
    EV::Nats self
    UV bytes_threshold
    SV *cb
  CODE:
    self->slow_consumer_bytes = (size_t)bytes_threshold;
    self->slow_fired = 0;
    CLEAR_HANDLER(self->on_slow_consumer);
    if (cb && SvOK(cb))
        self->on_slow_consumer = newSVsv(cb);

#ifdef HAVE_OPENSSL

void
nkey_seed(self, seed)
    EV::Nats self
    const char *seed
  CODE:
    if (seed) {
        char pub[64];
        if (nats_nkey_public(seed, pub, sizeof(pub)) <= 0)
            croak("invalid NKey seed");
    }
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
        if (!nats_random_bytes(raw + 2, 32))
            croak("no entropy source for an NKey seed");
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
    if (!self->connected)
        croak("not connected");
    if (self->draining) {
        if (cb && SvOK(cb))
            croak("drain already in progress");
        return;
    }
    self->draining = 1;
    CLEAR_HANDLER(self->drain_cb);
    if (cb && SvOK(cb))
        self->drain_cb = newSVsv(cb);

    {
        ngx_queue_t *q;
        char buf[64];
        ngx_queue_foreach(q, &self->subs) {
            nats_sub_t *sub = ngx_queue_data(q, nats_sub_t, queue);
            int n = snprintf(buf, sizeof(buf), "UNSUB %" UVuf "\r\n", (UV)sub->sid);
            wbuf_append(self, buf, n);
        }
    }

    /* Queued before the write so a synchronous write failure cannot strand
       a marker that would tear down the next connection. */
    wbuf_append(self, "PING\r\n", 6);
    {
        nats_pong_cb_t *pcb;
        Newxz(pcb, 1, nats_pong_cb_t);
        pcb->kind = PONG_DRAIN;
        ngx_queue_insert_tail(&self->pong_cbs, &pcb->queue);
    }
    NATS_HOLD_DIES(self);
    nats_try_write(self);
    nats_unwind(self);

void
DESTROY(obj)
    SV *obj
  PREINIT:
    nats_t *self;
  CODE:
    if (!SvROK(obj) || !SvOBJECT(SvRV(obj)) || !sv_derived_from(obj, "EV::Nats"))
        return;
    self = INT2PTR(nats_t *, SvIV(SvRV(obj)));
    if (!self)
        return;
    /* methods called after an explicit DESTROY now croak instead of
       reaching freed memory */
    sv_setiv(SvRV(obj), 0);
    self->intentional_disconnect = 1;

    if (PL_dirty) {
        if (self->fd >= 0)
            close(self->fd);
        return;
    }

    /* DESTROY from inside an event-loop callback: defer the free until the
       outermost wrapper returns; its C frames still use self */
    if (self->cb_depth > 0) {
        self->destroy_pending = 1;
        return;
    }

    nats_destroy_now(self);
