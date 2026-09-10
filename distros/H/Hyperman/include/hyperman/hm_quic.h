#ifndef HM_QUIC_H
#define HM_QUIC_H

/* QUIC transport (ngtcp2 + ngtcp2_crypto_ossl). Enabled by Makefile.PL when
 * all of ngtcp2, ngtcp2_crypto_ossl, nghttp3 and an OpenSSL that can hand
 * them its handshake are found (-DHM_HAVE_HTTP3); otherwise everything here
 * compiles to stubs and `http3 => 1` errors at runtime.
 *
 * This file owns the transport: the UDP listener, the datagram read loop,
 * the Destination Connection ID map, hm_qconn, and the expiry heap. HTTP/3
 * semantics live next door in hm_http3.h. Included from hm_core.h after
 * hm_tls.h (QUIC's handshake is a TLS handshake) and hm_http2.h.
 *
 * Two shapes here deliberately do NOT follow the HTTP/2 template:
 *
 *   - QUIC keeps NO backend timer. ngtcp2 wants its expiry rearmed after
 *     essentially every packet, and every backend's timer is too expensive
 *     for that: epoll burns an fd per timer and deletes with a linear scan
 *     over 65536 entries, kqueue floors at 1ms (too coarse for a
 *     sub-millisecond PTO), poll appends and linear-deletes, io_uring leaks
 *     until completion, and hm_dispatch's HM_TW_C branch frees an hm_tw that
 *     the arm just allocated. So there is a min-heap on the loop and the
 *     rearm is a sift: no syscall, no allocation.
 *
 *   - QUIC PULLS. hm_h2_cb_send pushes into hm_wb_put and then hm_flush;
 *     nghttp3 has no send callback at all, and bytes leave through
 *     nghttp3_conn_writev_stream -> ngtcp2_conn_writev_stream -> sendto. So
 *     the h3 equivalent of hm_h2_flush_send lives HERE rather than in
 *     hm_http3.h, and a QUIC connection has no wbuf, no hm_flush and no
 *     write watcher.
 *
 * Deliberately deferred, decided rather than missed: connection migration
 * (path_validation is accepted, the initial path is kept), 0-RTT (refused
 * explicitly rather than mis-handled), key update beyond
 * ngtcp2_crypto_update_key_cb, ECN, GSO/GRO/sendmmsg, the datagram
 * extension (RFC 9221), CBPF/eBPF reuseport steering, and IPv6 - the whole
 * dist is IPv4-only at the listener, and h3 inherits that. */

#ifdef HM_HAVE_HTTP3

#include <ngtcp2/ngtcp2.h>
#include <ngtcp2/ngtcp2_crypto.h>
#include <ngtcp2/ngtcp2_crypto_ossl.h>
#include <nghttp3/nghttp3.h>
#include <openssl/rand.h>

/* A QUIC packet must fit the path MTU, so a real one is never near this.
 * The buffer is generous anyway because a datagram larger than it is
 * TRUNCATED by recvfrom rather than refused, and a truncated packet fails
 * its AEAD and is dropped - correct, but a silent drop is a bad thing to
 * debug. At this size nothing legitimate can reach that path. */
#define HM_QUIC_MAX_UDP 65536

static int hm_quic_available(void) { return 1; }

/* ---- Connection IDs ------------------------------------------------------
 *
 * Everything from here down to and including the lookup is dTHX-FREE, the
 * same constraint that lets hm_parse.h be fuzzed standalone. It faces
 * unauthenticated UDP, which is a worse position than the HTTP/1 parser is
 * in: a packet reaches this code before anything has been decrypted or
 * authenticated, and a mistake here misroutes one client's packets into
 * another client's connection - a data disclosure, not a crash.
 *
 * The length we mint. 16 leaves plenty of room against collision while
 * keeping the header small; the wire can hand us up to 20 (and, for an
 * unsupported version, up to 255 - see hm_quic_triage). */
#define HM_QUIC_CIDLEN     16
#define HM_QUIC_CIDBUCKETS 1024        /* power of two */

/* The worker index lives in the FIRST byte of every CID we mint. That is a
 * fixed offset from the start of a short-header packet, which is what a
 * reuseport-steering BPF program can read. The steering itself is deferred,
 * but where the index lives is not: retrofitting it means changing every
 * CID already in flight, so the room is reserved from the first packet. */
#define HM_QUIC_CID_WORKER(cid) ((cid)->data[0])

typedef struct hm_quic_srv hm_quic_srv;

typedef struct hm_qcid {
    struct hm_qcid *hnext;             /* bucket chain                    */
    struct hm_qcid *cnext;             /* the owning connection's list    */
    hm_qconn       *qc;
    uint8_t         len;
    uint8_t         data[NGTCP2_MAX_CIDLEN];
} hm_qcid;

/* A QUIC connection. A PARALLEL struct to hm_conn rather than an extension
 * of it, and the reasons are load-bearing:
 *
 *   - loop->conns is indexed by fd and N QUIC connections share ONE fd, so
 *     putting these there means rewriting every loop->conns[fd] site -
 *     hm_dispatch, hm_run_again, hm_deliver, the writers, hm_detach, the LRU
 *     walk in hm_sweep, the pooling in hm_close.
 *   - rbuf, wbuf, writing, keepalive, bsrc, spill_fd and tls_hs are all
 *     meaningless here. ngtcp2 owns framing, retransmission and flow
 *     control, and there is no write buffer because QUIC pulls.
 *
 * `id` comes from the same hm_id_counter the TCP side uses, so the existing
 * generation-guard idiom carries over unchanged: the pair a Writer or a
 * parked closure holds becomes (udp_fd, id) instead of (fd, id), a stale
 * ticket is a no-op, and it can never be a wrong-connection hit. */
struct hm_qconn {
    hm_quic_srv *srv;
    UV           id;                   /* generation, from hm_id_counter  */
    hm_qcid     *cids;                 /* every CID routing to this conn  */
    uint64_t     expiry;               /* ngtcp2_conn_get_expiry()        */
    int          heap_idx;             /* position in loop->qheap, or -1  */
    hm_qconn    *next;                 /* srv->conns                      */
    hm_qconn    *idnext;               /* srv->ids bucket chain           */

    ngtcp2_conn         *conn;
    /* What ngtcp2_crypto hangs off the SSL as application data, and the ONLY
     * thing that may go there: its callbacks read it back as this type and
     * call get_conn through it, so anything else is a call through a garbage
     * pointer. */
    ngtcp2_crypto_conn_ref conn_ref;
    ngtcp2_crypto_ossl_ctx *ossl;
    void                *ssl;          /* SSL *, owned by ossl once set   */
    void                *h3;           /* nghttp3_conn *, or NULL         */
    void                *h3_streams;   /* hm_h3_stream list (hm_http3.h)  */
    ngtcp2_path_storage  path;
    struct sockaddr_storage peer;
    socklen_t            peerlen;
    char                 peer_str[INET6_ADDRSTRLEN];  /* REMOTE_ADDR    */
    int                  peer_port;

    /* Mirrors hm_conn's, so $env reports TLS the same way on either
     * transport. OpenSSL owns the strings for the life of the session. */
    const char  *tls_proto;
    const char  *tls_cipher;
    void        *tls_peer;             /* hm_tls_peer *, if a client cert  */

    unsigned char handshake_done;      /* off srv->handshaking once true  */
    unsigned char closing;             /* CONNECTION_CLOSE sent           */
    unsigned char draining;
};

/* One per listener, not per loop: a CID minted on listener A must not be
 * resolvable on listener B, and scoping the table this way makes teardown
 * obviously bounded rather than a search. */
struct hm_quic_srv {
    hm_listener *lst;
    hm_loop     *loop;
    int          worker_idx;
    hm_qcid     *cids[HM_QUIC_CIDBUCKETS];   /* by connection id          */
    hm_qconn    *ids[HM_QUIC_CIDBUCKETS];    /* by qconn->id, for the shim */
    hm_qconn    *conns;                      /* every live connection     */
    int          nconns;
    int          handshaking;                /* half-open, drives Retry   */
    void        *ssl_ctx;                    /* SSL_CTX *, QUIC-side      */
    /* The per-process secret behind stateless reset and Retry tokens.
     * Generated ONCE, before the fork, for the same reason the TLS
     * ticket key is: under SO_REUSEPORT a client's token can land on a
     * different worker, and a per-worker secret makes every such token
     * unverifiable. */
    uint8_t      secret[32];
};

/* Filled before any worker forks; every srv copies it. */
static uint8_t hm_quic_secret[32];
static int     hm_quic_secret_ready = 0;

static void hm_quic_secret_init(void);

static uint32_t hm_quic_hash(const uint8_t *d, size_t n) {
    uint32_t h = 2166136261u;                /* FNV-1a */
    size_t i;
    for (i = 0; i < n; i++) { h ^= d[i]; h *= 16777619u; }
    return h;
}

/* A hit compares the FULL length with memcmp. Never a prefix: two CIDs
 * sharing a prefix are two different connections, and a prefix match would
 * hand one client's packets to the other. */
static hm_qconn *hm_quic_cid_find(hm_quic_srv *srv, const uint8_t *d, size_t n) {
    hm_qcid *e;
    if (!srv || n == 0 || n > NGTCP2_MAX_CIDLEN) return NULL;
    e = srv->cids[hm_quic_hash(d, n) & (HM_QUIC_CIDBUCKETS - 1)];
    for (; e; e = e->hnext)
        if (e->len == n && memcmp(e->data, d, n) == 0) return e->qc;
    return NULL;
}

/* Add one CID to a connection. ngtcp2 mints extras through
 * NEW_CONNECTION_ID, which is why a connection owns a LIST rather than one.
 * 1 on success, 0 if the CID is unusable or already mapped. */
static int hm_quic_cid_add(hm_quic_srv *srv, hm_qconn *qc,
                           const uint8_t *d, size_t n) {
    hm_qcid *e;
    uint32_t b;
    if (!srv || !qc || n == 0 || n > NGTCP2_MAX_CIDLEN) return 0;
    if (hm_quic_cid_find(srv, d, n)) return 0;
    b = hm_quic_hash(d, n) & (HM_QUIC_CIDBUCKETS - 1);
    e = (hm_qcid *)hm_xcalloc(1, sizeof(hm_qcid));
    e->qc  = qc;
    e->len = (uint8_t)n;
    memcpy(e->data, d, n);
    e->hnext = srv->cids[b];
    srv->cids[b] = e;
    e->cnext = qc->cids;
    qc->cids = e;
    return 1;
}

/* Retire one CID (ngtcp2's remove_connection_id callback). */
static void hm_quic_cid_remove(hm_quic_srv *srv, const uint8_t *d, size_t n) {
    hm_qcid **pp, *e = NULL;
    uint32_t b;
    if (!srv || n == 0 || n > NGTCP2_MAX_CIDLEN) return;
    b = hm_quic_hash(d, n) & (HM_QUIC_CIDBUCKETS - 1);
    for (pp = &srv->cids[b]; *pp; pp = &(*pp)->hnext) {
        if ((*pp)->len == n && memcmp((*pp)->data, d, n) == 0) {
            e = *pp; *pp = e->hnext; break;
        }
    }
    if (!e) return;
    {   /* and off its connection's list */
        hm_qcid **cp;
        for (cp = &e->qc->cids; *cp; cp = &(*cp)->cnext)
            if (*cp == e) { *cp = e->cnext; break; }
    }
    free(e);
}

/* Every CID this connection answers to, at close. Walks the CONNECTION'S
 * list - never a scan of the buckets, which would be 1024 chain walks to
 * retire a handful of entries. */
static void hm_quic_cid_drop_conn(hm_quic_srv *srv, hm_qconn *qc) {
    hm_qcid *e = qc->cids;
    while (e) {
        hm_qcid *next = e->cnext;
        hm_qcid **pp;
        uint32_t b = hm_quic_hash(e->data, e->len) & (HM_QUIC_CIDBUCKETS - 1);
        for (pp = &srv->cids[b]; *pp; pp = &(*pp)->hnext)
            if (*pp == e) { *pp = e->hnext; break; }
        free(e);
        e = next;
    }
    qc->cids = NULL;
}

/* The (udp_fd, id) shim: the generation-guard idiom the TCP side uses, over
 * a transport with no fd per connection. Hashed rather than walked, because
 * this resolves once per response and a worker can hold thousands. */
static hm_qconn *hm_quic_conn_by_id(hm_quic_srv *srv, UV id) {
    hm_qconn *qc;
    uint32_t b;
    if (!srv) return NULL;
    b = hm_quic_hash((const uint8_t *)&id, sizeof(id)) & (HM_QUIC_CIDBUCKETS - 1);
    for (qc = srv->ids[b]; qc; qc = qc->idnext)
        if (qc->id == id) return qc;
    return NULL;
}

static void hm_quic_id_add(hm_quic_srv *srv, hm_qconn *qc) {
    uint32_t b = hm_quic_hash((const uint8_t *)&qc->id, sizeof(qc->id))
               & (HM_QUIC_CIDBUCKETS - 1);
    qc->idnext = srv->ids[b];
    srv->ids[b] = qc;
}

static void hm_quic_id_remove(hm_quic_srv *srv, hm_qconn *qc) {
    uint32_t b = hm_quic_hash((const uint8_t *)&qc->id, sizeof(qc->id))
               & (HM_QUIC_CIDBUCKETS - 1);
    hm_qconn **pp;
    for (pp = &srv->ids[b]; *pp; pp = &(*pp)->idnext)
        if (*pp == qc) { *pp = qc->idnext; break; }
    qc->idnext = NULL;
}

/* ---- the expiry heap -----------------------------------------------------
 *
 * A min-heap keyed on each connection's ngtcp2_conn_get_expiry(), with the
 * position cached on the connection so a rearm is a sift: no syscall, no
 * allocation, O(log n). The backend timer vtables cannot carry this - epoll
 * burns an fd per timer and deletes with a linear scan over 65536 entries,
 * kqueue floors at 1ms, poll appends and linear-deletes, io_uring leaks
 * until completion - and ngtcp2 rearms after essentially every packet. */

static void hm_qheap_swap(hm_qheap *h, int i, int j) {
    hm_qconn *t = h->a[i];
    h->a[i] = h->a[j];
    h->a[j] = t;
    h->a[i]->heap_idx = i;
    h->a[j]->heap_idx = j;
}

static void hm_qheap_up(hm_qheap *h, int i) {
    while (i > 0) {
        int p = (i - 1) / 2;
        if (h->a[p]->expiry <= h->a[i]->expiry) break;
        hm_qheap_swap(h, i, p);
        i = p;
    }
}

static void hm_qheap_down(hm_qheap *h, int i) {
    for (;;) {
        int l = 2 * i + 1, r = l + 1, m = i;
        if (l < h->n && h->a[l]->expiry < h->a[m]->expiry) m = l;
        if (r < h->n && h->a[r]->expiry < h->a[m]->expiry) m = r;
        if (m == i) break;
        hm_qheap_swap(h, i, m);
        i = m;
    }
}

/* Insert, or move an existing entry. Both directions: ngtcp2 moves a
 * deadline EARLIER as often as later (a PTO arms sooner than the idle
 * timeout it replaces), so sifting only one way would leave the heap
 * unordered and the loop sleeping past a deadline. */
static void hm_qheap_set(hm_qheap *h, hm_qconn *qc, uint64_t expiry) {
    if (qc->heap_idx >= 0) {
        uint64_t old = qc->expiry;
        qc->expiry = expiry;
        if (expiry < old) hm_qheap_up(h, qc->heap_idx);
        else              hm_qheap_down(h, qc->heap_idx);
        return;
    }
    if (h->n == h->cap) {
        int cap = h->cap ? h->cap * 2 : 16;
        h->a = (hm_qconn **)hm_xrealloc(h->a, (size_t)cap * sizeof(hm_qconn *));
        h->cap = cap;
    }
    qc->expiry   = expiry;
    qc->heap_idx = h->n;
    h->a[h->n++] = qc;
    hm_qheap_up(h, qc->heap_idx);
}

static void hm_qheap_remove(hm_qheap *h, hm_qconn *qc) {
    int i = qc->heap_idx;
    if (i < 0) return;
    qc->heap_idx = -1;
    h->n--;
    if (i == h->n) return;             /* it was the last slot */
    h->a[i] = h->a[h->n];
    h->a[i]->heap_idx = i;
    /* The replacement came from the bottom, so it can belong in either
     * direction relative to where it landed. */
    hm_qheap_up(h, i);
    hm_qheap_down(h, i);
}

/* ---- packet triage -------------------------------------------------------
 *
 * The first thing that touches an attacker-controlled datagram. Kept
 * separate, and dTHX-free, so it can be fuzzed on its own.
 *
 * Returns 0 and fills *out when the packet names a connection we can look
 * up, 1 when it is well-formed but names no connection we hold (a new
 * handshake, or a stray), NGTCP2_ERR_VERSION_NEGOTIATION when the client
 * asked for a version we do not speak, and -1 when it is not decodable. */
static int hm_quic_triage(hm_quic_srv *srv, const uint8_t *pkt, size_t len,
                          ngtcp2_version_cid *vc, hm_qconn **out) {
    int rv;
    size_t n;
    *out = NULL;
    /* ngtcp2 ASSERTS datalen is non-zero, and this library is built with
     * assertions live, so an empty datagram would abort the worker rather
     * than be rejected. hm_quic_readable skips those already; the guard is
     * repeated here because this function is the fuzz target and must hold
     * on its own. */
    if (len == 0) return -1;
    rv = ngtcp2_pkt_decode_version_cid(vc, pkt, len, HM_QUIC_CIDLEN);
    if (rv == NGTCP2_ERR_VERSION_NEGOTIATION) return rv;   /* vc is filled */
    if (rv != 0) return -1;
    /* dcidlen is NOT bounded by NGTCP2_MAX_CIDLEN here. The decoder handles
     * Connection IDs up to 255 bytes, because a longer one is legal in a
     * packet naming a version we do not support - and this is the length
     * that would otherwise be handed to memcmp against a 20-byte buffer. */
    n = vc->dcidlen;
    if (n == 0 || n > NGTCP2_MAX_CIDLEN) return 1;
    *out = hm_quic_cid_find(srv, vc->dcid, n);
    return *out ? 0 : 1;
}

/* Defined below, beside the ngtcp2 wiring; declared here because the packet
 * path is written in the order a datagram travels rather than in dependency
 * order, and reading it that way is worth two forward declarations. */
static void      hm_quic_rand_bytes(uint8_t *d, size_t n);
static void      hm_quic_conn_free(pTHX_ hm_qconn *qc);
static int       hm_quic_write(pTHX_ hm_qconn *qc);

/* HTTP/3 lives next door in hm_http3.h, included AFTER this file because it
 * is built on hm_qconn. These are the places the transport reaches up into
 * it: a QUIC connection owns an nghttp3 session, and stream events have to
 * cross from one to the other. */
static int       hm_h3_session_start(pTHX_ hm_qconn *qc);
static void      hm_h3_session_free(pTHX_ hm_qconn *qc);
static int       hm_h3_recv_stream(pTHX_ hm_qconn *qc, int64_t sid,
                                   const uint8_t *data, size_t datalen,
                                   int fin);
static int       hm_h3_stream_gone(pTHX_ hm_qconn *qc, int64_t sid,
                                   uint64_t app_error_code);
static int       hm_h3_acked(pTHX_ hm_qconn *qc, int64_t sid, uint64_t n);
static nghttp3_ssize hm_h3_pull(pTHX_ hm_qconn *qc, int64_t *psid, int *pfin,
                                nghttp3_vec *vec, size_t veccnt);
static int       hm_h3_wrote(pTHX_ hm_qconn *qc, int64_t sid, size_t n);
static int       hm_h3_unblock(pTHX_ hm_qconn *qc, int64_t sid);
static hm_qconn *hm_quic_conn_new(pTHX_ hm_quic_srv *srv,
                                  const ngtcp2_version_cid *vc,
                                  const ngtcp2_pkt_hd *hd,
                                  const ngtcp2_cid *retry_odcid,
                                  const struct sockaddr *peer,
                                  socklen_t peerlen);

/* ---- address validation --------------------------------------------------
 *
 * A QUIC server sends its first flight - certificate and all - to an address
 * it has not heard back from, so a spoofed source address turns it into an
 * amplifier. Two answers, and both are in the library rather than written
 * here: no token in this codebase is hand-rolled crypto.
 *
 *   Retry     the server refuses to continue until the client echoes a token
 *             back from the address it claims. One extra round trip, so it
 *             is NOT unconditional - it is what the server does once it is
 *             carrying more half-open handshakes than the threshold below.
 *             That is the posture that matters: cheap when idle, defensive
 *             under load.
 *   NEW_TOKEN issued after every completed handshake, so a client that comes
 *             back skips validation entirely and pays no round trip even
 *             while the server is retrying everyone else.
 *
 * Both are verified against the ONE pre-fork secret, for the reason the TLS
 * ticket key carries the same rule: under SO_REUSEPORT a client's token can
 * land on a different worker than the one that minted it, and a per-worker
 * secret would make every such token unverifiable. */

/* Half-open handshakes tolerated before Retry is demanded of new clients. */
#define HM_QUIC_RETRY_THRESHOLD 64

/* How long a token stays good. Long enough for a client to come back on the
 * same address, short enough that a stolen one is not useful for long. */
#define HM_QUIC_RETRY_TIMEOUT   (10 * NGTCP2_SECONDS)
#define HM_QUIC_TOKEN_TIMEOUT   (3600 * NGTCP2_SECONDS)

/* Demand a Retry: the client must come back echoing this token. */
static void hm_quic_send_retry(hm_quic_srv *srv, const ngtcp2_pkt_hd *hd,
                               const struct sockaddr *peer, socklen_t peerlen) {
    uint8_t token[NGTCP2_CRYPTO_MAX_RETRY_TOKENLEN2];
    uint8_t buf[512];
    ngtcp2_cid scid = {0};
    ngtcp2_ssize tlen, n;

    /* A fresh Connection ID for the Retry, which the client will then use as
     * its destination - it is not ours to keep, so it is not put in the map. */
    hm_quic_rand_bytes(scid.data, HM_QUIC_CIDLEN);
    scid.datalen = HM_QUIC_CIDLEN;
    HM_QUIC_CID_WORKER(&scid) = (uint8_t)srv->worker_idx;

    tlen = ngtcp2_crypto_generate_retry_token2(
               token, srv->secret, sizeof(srv->secret), hd->version,
               (const ngtcp2_sockaddr *)peer, (ngtcp2_socklen)peerlen,
               &scid, &hd->dcid, hm_now_ns());
    if (tlen < 0) return;

    n = ngtcp2_crypto_write_retry(buf, sizeof(buf), hd->version,
                                  &hd->scid, &scid, &hd->dcid,
                                  token, (size_t)tlen);
    if (n > 0) (void)hm_os_sendto(srv->lst->udp_fd, buf, (size_t)n,
                                  peer, peerlen);
}

/* A short-header packet naming a Connection ID we have never heard of. The
 * usual cause is a client still talking to a server that has restarted, and
 * without an answer it retries until its idle timeout. A Stateless Reset
 * tells it to give up now.
 *
 * Only for packets big enough to be worth answering, and the reply is always
 * SMALLER than what arrived: this path is unauthenticated by definition, so
 * it must never be an amplifier. */
static void hm_quic_send_stateless_reset(hm_quic_srv *srv,
                                         const ngtcp2_version_cid *vc,
                                         size_t inlen,
                                         const struct sockaddr *peer,
                                         socklen_t peerlen) {
    uint8_t token[NGTCP2_STATELESS_RESET_TOKENLEN];
    uint8_t rnd[64], buf[256];
    ngtcp2_cid cid = {0};
    ngtcp2_ssize n;
    if (inlen < 41) return;                 /* too small to be worth a reply */
    if (vc->dcidlen == 0 || vc->dcidlen > NGTCP2_MAX_CIDLEN) return;
    memcpy(cid.data, vc->dcid, vc->dcidlen);
    cid.datalen = vc->dcidlen;
    if (ngtcp2_crypto_generate_stateless_reset_token(
            token, srv->secret, sizeof(srv->secret), &cid) != 0) return;
    hm_quic_rand_bytes(rnd, sizeof(rnd));
    n = ngtcp2_pkt_write_stateless_reset(buf, sizeof(buf) < inlen - 1
                                                 ? sizeof(buf) : inlen - 1,
                                         token, rnd, sizeof(rnd));
    if (n > 0) (void)hm_os_sendto(srv->lst->udp_fd, buf, (size_t)n,
                                  peer, peerlen);
}

/* Answer a client asking for a QUIC version we do not speak. Cheap, and
 * without it such a client gets silence and retries until it gives up. */
static void hm_quic_send_vn(hm_quic_srv *srv, const ngtcp2_version_cid *vc,
                            const struct sockaddr *peer, socklen_t peerlen) {
    uint8_t buf[256];
    uint32_t versions[1];
    ngtcp2_ssize n;
    uint8_t seed;
    versions[0] = NGTCP2_PROTO_VER_V1;
    hm_quic_rand_bytes(&seed, 1);
    /* The reply swaps the connection ids, which is what tells the client
     * this answers its packet. */
    n = ngtcp2_pkt_write_version_negotiation(buf, sizeof(buf), seed,
                                             vc->scid, vc->scidlen,
                                             vc->dcid, vc->dcidlen,
                                             versions, 1);
    if (n > 0) (void)hm_os_sendto(srv->lst->udp_fd, buf, (size_t)n,
                                  peer, peerlen);
}

/* One datagram, start to finish: triage, then either an existing connection
 * or a new one, then read it and write whatever that produced.
 *
 * A bad packet from an unauthenticated peer is not an error, so nothing here
 * has a failure a caller could act on - it returns 0 either way and the
 * packet is dropped. */
static int hm_quic_packet(pTHX_ hm_loop *loop, hm_listener *lst,
                          const unsigned char *pkt, size_t len,
                          const struct sockaddr *peer, socklen_t peerlen) {
    hm_quic_srv *srv = (hm_quic_srv *)lst->quic;
    ngtcp2_version_cid vc;
    ngtcp2_path path;
    ngtcp2_pkt_info pi;
    hm_qconn *qc = NULL;
    int rv;

    loop->datagrams++;
    if (!srv) return 0;

    rv = hm_quic_triage(srv, pkt, len, &vc, &qc);
    if (rv == NGTCP2_ERR_VERSION_NEGOTIATION) {
        hm_quic_send_vn(srv, &vc, peer, peerlen);
        return 0;
    }
    if (rv < 0) return 0;                     /* not decodable */

    if (!qc) {
        ngtcp2_pkt_hd hd;
        ngtcp2_cid odcid = {0};
        const ngtcp2_cid *odcidp = NULL;   /* set only when Retry validated */

        if (loop->stopping) return 0;

        /* Not an Initial and no connection: this names a Connection ID that
         * is gone - almost always a client still talking to a server that
         * has restarted - so tell it to stop rather than let it retry until
         * its idle timeout. */
        if (ngtcp2_accept(&hd, pkt, len) != 0) {
            if (vc.version == 0)            /* short header */
                hm_quic_send_stateless_reset(srv, &vc, len, peer, peerlen);
            return 0;
        }

        if (loop->http3_max_conns && loop->h3_live >= loop->http3_max_conns)
            return 0;

        if (hd.tokenlen == 0) {
            /* No token. Cheap while the server is idle; once it is carrying
             * more half-open handshakes than the threshold, make the client
             * prove its address first. */
            if (srv->handshaking >= HM_QUIC_RETRY_THRESHOLD) {
                hm_quic_send_retry(srv, &hd, peer, peerlen);
                return 0;
            }
        } else if (hd.token[0] == NGTCP2_CRYPTO_TOKEN_MAGIC_RETRY2) {
            if (ngtcp2_crypto_verify_retry_token2(
                    &odcid, hd.token, hd.tokenlen,
                    srv->secret, sizeof(srv->secret), hd.version,
                    (const ngtcp2_sockaddr *)peer, (ngtcp2_socklen)peerlen,
                    &hd.dcid, HM_QUIC_RETRY_TIMEOUT, hm_now_ns()) != 0)
                return 0;                   /* forged or stale: say nothing */
            odcidp = &odcid;
        } else if (hd.token[0] == NGTCP2_CRYPTO_TOKEN_MAGIC_REGULAR) {
            /* A NEW_TOKEN from a previous visit. Good, or ignored - a bad one
             * is not grounds to refuse, only to stop trusting the address. */
            if (ngtcp2_crypto_verify_regular_token(
                    hd.token, hd.tokenlen, srv->secret, sizeof(srv->secret),
                    (const ngtcp2_sockaddr *)peer, (ngtcp2_socklen)peerlen,
                    HM_QUIC_TOKEN_TIMEOUT, hm_now_ns()) != 0
                && srv->handshaking >= HM_QUIC_RETRY_THRESHOLD) {
                hm_quic_send_retry(srv, &hd, peer, peerlen);
                return 0;
            }
        } else if (srv->handshaking >= HM_QUIC_RETRY_THRESHOLD) {
            hm_quic_send_retry(srv, &hd, peer, peerlen);
            return 0;
        }

        qc = hm_quic_conn_new(aTHX_ srv, &vc, &hd, odcidp, peer, peerlen);
        if (!qc) return 0;
    }

    memset(&pi, 0, sizeof(pi));
    path = qc->path.path;
    path.remote.addr    = (ngtcp2_sockaddr *)peer;
    path.remote.addrlen = peerlen;

    if (ngtcp2_conn_read_pkt(qc->conn, &path, &pi, pkt, len, hm_now_ns()) != 0) {
        hm_quic_conn_free(aTHX_ qc);
        return 0;
    }
    hm_quic_write(aTHX_ qc);
    return 0;
}

/* ---- selftests -----------------------------------------------------------
 *
 * The CID one is the highest-value unit test in the whole feature: a map bug
 * misroutes one client's packets into another client's connection, which is
 * a data disclosure, and no black-box test against a real client will catch
 * it. Both drive the real structures, with bare hm_qconns - the map and the
 * heap touch nothing else, so a real ngtcp2 connection would only make the
 * test harder to run without making it prove more.
 *
 * Deterministic pseudo-random, so a failure is reproducible. */
static uint32_t hm_quic_st_rand(uint32_t *s) {
    *s ^= *s << 13; *s ^= *s >> 17; *s ^= *s << 5;
    return *s;
}

#define HM_QUIC_ST_CONNS 64
#define HM_QUIC_ST_PER   8

static int hm_quic_cid_selftest(void) {
    hm_quic_srv *srv = (hm_quic_srv *)hm_xcalloc(1, sizeof(hm_quic_srv));
    hm_qconn *qcs = (hm_qconn *)hm_xcalloc(HM_QUIC_ST_CONNS, sizeof(hm_qconn));
    uint8_t (*cid)[NGTCP2_MAX_CIDLEN] =
        (uint8_t (*)[NGTCP2_MAX_CIDLEN])
        hm_xcalloc(HM_QUIC_ST_CONNS * HM_QUIC_ST_PER, NGTCP2_MAX_CIDLEN);
    uint32_t seed = 0x9e3779b9u;
    int i, j, ok = 1;

    for (i = 0; i < HM_QUIC_ST_CONNS; i++) {
        qcs[i].id = (UV)(1000 + i);
        qcs[i].heap_idx = -1;
        hm_quic_id_add(srv, &qcs[i]);
        for (j = 0; j < HM_QUIC_ST_PER; j++) {
            int k = i * HM_QUIC_ST_PER + j, b;
            for (b = 0; b < HM_QUIC_CIDLEN; b++)
                cid[k][b] = (uint8_t)hm_quic_st_rand(&seed);
            /* the worker index lives in byte 0 and is not random */
            cid[k][0] = 0;
            /* ... which means byte 0 collides across every connection, so
             * this also proves the lookup is not keyed on a prefix */
            if (!hm_quic_cid_add(srv, &qcs[i], cid[k], HM_QUIC_CIDLEN)) ok = 0;
        }
    }

    /* every CID resolves, and to the RIGHT connection */
    for (i = 0; i < HM_QUIC_ST_CONNS * HM_QUIC_ST_PER; i++)
        if (hm_quic_cid_find(srv, cid[i], HM_QUIC_CIDLEN)
            != &qcs[i / HM_QUIC_ST_PER]) ok = 0;

    /* the id table resolves too - the (udp_fd, id) shim */
    for (i = 0; i < HM_QUIC_ST_CONNS; i++)
        if (hm_quic_conn_by_id(srv, (UV)(1000 + i)) != &qcs[i]) ok = 0;
    if (hm_quic_conn_by_id(srv, 999)) ok = 0;

    if (hm_quic_cid_find(srv, cid[0], 0))                     ok = 0;
    if (hm_quic_cid_find(srv, cid[0], NGTCP2_MAX_CIDLEN + 1)) ok = 0;

    /* A prefix must not resolve to the connection it is a prefix OF.
     *
     * Testing that with a bare short lookup proves nothing, and this test
     * asserted exactly that until it was mutation-checked: FNV over n bytes
     * puts a 15-byte query in a different bucket from the 16-byte entry, so
     * the query misses on the bucket and the length comparison inside the
     * chain never runs at all. Removing `e->len == n` entirely left the
     * suite green.
     *
     * So the collision is FORCED. Two CIDs of different lengths, one a
     * strict prefix of the other, searched until they land in the same
     * bucket - which is the only arrangement in which the length check is
     * load-bearing, and the arrangement a different hash function would
     * make common. */
    {
        uint8_t longer[NGTCP2_MAX_CIDLEN];
        uint32_t want, tries;
        int placed = 0;
        for (i = 0; i < NGTCP2_MAX_CIDLEN; i++)
            longer[i] = (uint8_t)hm_quic_st_rand(&seed);
        longer[0] = 0;
        /* The short form's bucket is fixed - it reads only the first
         * HM_QUIC_CIDLEN bytes - so the search varies the TAIL those bytes
         * do not cover until the long form lands in it.
         *
         * All four tail bytes, not just the last: FNV's final step is
         * `h ^= b; h *= prime`, so varying one byte reaches at most 256 of
         * the 1024 buckets and the target is usually not among them. That
         * mistake made this loop fail three times in four. */
        want = hm_quic_hash(longer, HM_QUIC_CIDLEN) & (HM_QUIC_CIDBUCKETS - 1);
        for (tries = 0; tries < 200000 && !placed; tries++) {
            if ((hm_quic_hash(longer, NGTCP2_MAX_CIDLEN)
                 & (HM_QUIC_CIDBUCKETS - 1)) == want) { placed = 1; break; }
            for (i = HM_QUIC_CIDLEN; i < NGTCP2_MAX_CIDLEN; i++)
                longer[i] = (uint8_t)hm_quic_st_rand(&seed);
        }
        if (!placed) ok = 0;           /* never happens; not silently skipped */
        else {
            if (!hm_quic_cid_add(srv, &qcs[1], longer, NGTCP2_MAX_CIDLEN)) ok = 0;
            if (!hm_quic_cid_add(srv, &qcs[2], longer, HM_QUIC_CIDLEN))    ok = 0;
            if (hm_quic_cid_find(srv, longer, NGTCP2_MAX_CIDLEN) != &qcs[1]) ok = 0;
            if (hm_quic_cid_find(srv, longer, HM_QUIC_CIDLEN)    != &qcs[2]) ok = 0;
            hm_quic_cid_remove(srv, longer, NGTCP2_MAX_CIDLEN);
            hm_quic_cid_remove(srv, longer, HM_QUIC_CIDLEN);
        }
    }

    /* drop one connection: its CIDs go, every other one still resolves */
    hm_quic_cid_drop_conn(srv, &qcs[7]);
    hm_quic_id_remove(srv, &qcs[7]);
    for (i = 0; i < HM_QUIC_ST_CONNS * HM_QUIC_ST_PER; i++) {
        hm_qconn *got = hm_quic_cid_find(srv, cid[i], HM_QUIC_CIDLEN);
        if (i / HM_QUIC_ST_PER == 7) { if (got) ok = 0; }
        else if (got != &qcs[i / HM_QUIC_ST_PER]) ok = 0;
    }
    if (hm_quic_conn_by_id(srv, 1007)) ok = 0;

    /* retiring a single CID leaves its connection's others alone */
    hm_quic_cid_remove(srv, cid[0], HM_QUIC_CIDLEN);
    if (hm_quic_cid_find(srv, cid[0], HM_QUIC_CIDLEN))      ok = 0;
    if (hm_quic_cid_find(srv, cid[1], HM_QUIC_CIDLEN) != &qcs[0]) ok = 0;

    for (i = 0; i < HM_QUIC_ST_CONNS; i++)
        if (i != 7) hm_quic_cid_drop_conn(srv, &qcs[i]);
    free(cid); free(qcs); free(srv);
    return ok;
}

/* Address-validation tokens. The property that matters is not that a token
 * verifies - it is that it verifies for the address it was minted for and
 * for NO OTHER, because a token that travels is one an attacker can replay
 * from a spoofed source. The crypto is all the library's; what is under test
 * is that it was called with the right arguments. */
static int hm_quic_token_selftest(void) {
    uint8_t secret[32];
    uint8_t token[NGTCP2_CRYPTO_MAX_RETRY_TOKENLEN2];
    uint8_t reg[NGTCP2_CRYPTO_MAX_REGULAR_TOKENLEN];
    struct sockaddr_in a, b;
    ngtcp2_cid scid = {0}, odcid = {0}, got = {0};
    ngtcp2_tstamp now = hm_now_ns();
    ngtcp2_ssize tlen, rlen;
    int ok = 1;

    hm_quic_rand_bytes(secret, sizeof(secret));
    memset(&a, 0, sizeof(a));
    a.sin_family      = AF_INET;
    a.sin_port        = htons(4433);
    a.sin_addr.s_addr = htonl(0x7f000001);      /* 127.0.0.1 */
    b = a;
    b.sin_addr.s_addr = htonl(0x7f000002);      /* 127.0.0.2 */

    hm_quic_rand_bytes(scid.data, HM_QUIC_CIDLEN);  scid.datalen  = HM_QUIC_CIDLEN;
    hm_quic_rand_bytes(odcid.data, HM_QUIC_CIDLEN); odcid.datalen = HM_QUIC_CIDLEN;

    tlen = ngtcp2_crypto_generate_retry_token2(
               token, secret, sizeof(secret), NGTCP2_PROTO_VER_V1,
               (const ngtcp2_sockaddr *)&a, sizeof(a), &scid, &odcid, now);
    if (tlen <= 0) return 0;
    if (token[0] != NGTCP2_CRYPTO_TOKEN_MAGIC_RETRY2) ok = 0;

    /* the address it was minted for */
    if (ngtcp2_crypto_verify_retry_token2(
            &got, token, (size_t)tlen, secret, sizeof(secret),
            NGTCP2_PROTO_VER_V1, (const ngtcp2_sockaddr *)&a, sizeof(a),
            &scid, HM_QUIC_RETRY_TIMEOUT, now) != 0) ok = 0;
    /* ...and it hands back the id the client used BEFORE the Retry, which is
     * what the transport parameters then have to echo */
    if (got.datalen != odcid.datalen
        || memcmp(got.data, odcid.data, got.datalen) != 0) ok = 0;

    /* a DIFFERENT address must not verify: that is the whole point */
    if (ngtcp2_crypto_verify_retry_token2(
            &got, token, (size_t)tlen, secret, sizeof(secret),
            NGTCP2_PROTO_VER_V1, (const ngtcp2_sockaddr *)&b, sizeof(b),
            &scid, HM_QUIC_RETRY_TIMEOUT, now) == 0) ok = 0;

    /* nor a different Connection ID */
    {
        ngtcp2_cid other = scid;
        other.data[0] ^= 0xff;
        if (ngtcp2_crypto_verify_retry_token2(
                &got, token, (size_t)tlen, secret, sizeof(secret),
                NGTCP2_PROTO_VER_V1, (const ngtcp2_sockaddr *)&a, sizeof(a),
                &other, HM_QUIC_RETRY_TIMEOUT, now) == 0) ok = 0;
    }

    /* nor a different secret - which is why one is generated before the fork
     * and shared, rather than per worker */
    {
        uint8_t other[32];
        hm_quic_rand_bytes(other, sizeof(other));
        if (ngtcp2_crypto_verify_retry_token2(
                &got, token, (size_t)tlen, other, sizeof(other),
                NGTCP2_PROTO_VER_V1, (const ngtcp2_sockaddr *)&a, sizeof(a),
                &scid, HM_QUIC_RETRY_TIMEOUT, now) == 0) ok = 0;
    }

    /* nor a tampered one */
    token[tlen / 2] ^= 0x01;
    if (ngtcp2_crypto_verify_retry_token2(
            &got, token, (size_t)tlen, secret, sizeof(secret),
            NGTCP2_PROTO_VER_V1, (const ngtcp2_sockaddr *)&a, sizeof(a),
            &scid, HM_QUIC_RETRY_TIMEOUT, now) == 0) ok = 0;
    token[tlen / 2] ^= 0x01;

    /* nor an expired one */
    if (ngtcp2_crypto_verify_retry_token2(
            &got, token, (size_t)tlen, secret, sizeof(secret),
            NGTCP2_PROTO_VER_V1, (const ngtcp2_sockaddr *)&a, sizeof(a),
            &scid, HM_QUIC_RETRY_TIMEOUT,
            now + HM_QUIC_RETRY_TIMEOUT + NGTCP2_SECONDS) == 0) ok = 0;

    /* NEW_TOKEN: the same address rule, and a DIFFERENT magic byte - the
     * receive path tells the two kinds apart by that before it tries to
     * verify either, so they must not collide. */
    rlen = ngtcp2_crypto_generate_regular_token(
               reg, secret, sizeof(secret),
               (const ngtcp2_sockaddr *)&a, sizeof(a), now);
    if (rlen <= 0) return 0;
    if (reg[0] != NGTCP2_CRYPTO_TOKEN_MAGIC_REGULAR) ok = 0;
    if (reg[0] == NGTCP2_CRYPTO_TOKEN_MAGIC_RETRY2)  ok = 0;
    if (ngtcp2_crypto_verify_regular_token(
            reg, (size_t)rlen, secret, sizeof(secret),
            (const ngtcp2_sockaddr *)&a, sizeof(a),
            HM_QUIC_TOKEN_TIMEOUT, now) != 0) ok = 0;
    if (ngtcp2_crypto_verify_regular_token(
            reg, (size_t)rlen, secret, sizeof(secret),
            (const ngtcp2_sockaddr *)&b, sizeof(b),
            HM_QUIC_TOKEN_TIMEOUT, now) == 0) ok = 0;

    /* a stateless reset token is a pure function of secret and id: the same
     * pair must give the same token after a restart, or a client that has
     * one cannot recognise the reset it is sent */
    {
        uint8_t t1[NGTCP2_STATELESS_RESET_TOKENLEN];
        uint8_t t2[NGTCP2_STATELESS_RESET_TOKENLEN];
        ngtcp2_cid other = scid;
        if (ngtcp2_crypto_generate_stateless_reset_token(
                t1, secret, sizeof(secret), &scid) != 0) ok = 0;
        if (ngtcp2_crypto_generate_stateless_reset_token(
                t2, secret, sizeof(secret), &scid) != 0) ok = 0;
        if (memcmp(t1, t2, sizeof(t1)) != 0) ok = 0;     /* reproducible  */
        other.data[0] ^= 0xff;
        if (ngtcp2_crypto_generate_stateless_reset_token(
                t2, secret, sizeof(secret), &other) != 0) ok = 0;
        if (memcmp(t1, t2, sizeof(t1)) == 0) ok = 0;     /* ...but per id */
    }
    return ok;
}

static int hm_quic_heap_selftest(void) {
    hm_qheap h;
    hm_qconn *qcs = (hm_qconn *)hm_xcalloc(256, sizeof(hm_qconn));
    uint32_t seed = 0x243f6a88u;
    uint64_t last;
    int i, ok = 1;
    memset(&h, 0, sizeof(h));
    for (i = 0; i < 256; i++) qcs[i].heap_idx = -1;

    /* push in random order */
    for (i = 0; i < 256; i++)
        hm_qheap_set(&h, &qcs[i], (uint64_t)hm_quic_st_rand(&seed));
    if (h.n != 256) ok = 0;

    /* every position agrees with the entry that holds it */
    for (i = 0; i < h.n; i++) if (h.a[i]->heap_idx != i) ok = 0;

    /* move deadlines BOTH ways - the rearm does both, and a sift that only
     * goes one way leaves the loop sleeping past a deadline */
    for (i = 0; i < 256; i += 2)
        hm_qheap_set(&h, &qcs[i], (uint64_t)hm_quic_st_rand(&seed));
    for (i = 1; i < 256; i += 2)
        hm_qheap_set(&h, &qcs[i], (uint64_t)hm_quic_st_rand(&seed) >> 4);
    for (i = 0; i < h.n; i++) if (h.a[i]->heap_idx != i) ok = 0;

    /* removing from the middle keeps it a heap */
    for (i = 0; i < 64; i++) hm_qheap_remove(&h, &qcs[i * 3]);
    for (i = 0; i < h.n; i++) if (h.a[i]->heap_idx != i) ok = 0;

    /* draining the minimum is monotonic, which is the whole contract */
    last = 0;
    while (h.n) {
        hm_qconn *m = h.a[0];
        if (m->expiry < last) ok = 0;
        last = m->expiry;
        hm_qheap_remove(&h, m);
    }
    if (h.n != 0) ok = 0;

    if (h.a) free(h.a);
    free(qcs);
    return ok;
}

/* The UDP listener is readable. Mirrors hm_accept's fairness cap: take at
 * most a batch in one wakeup and let the next iteration resume, since the
 * socket stays level-readable. Without the cap one busy client's flight
 * starves every other connection this worker holds.
 *
 * The single hm_os_recvfrom call site. When recvmsg arrives - for the local
 * address and ECN - or recvmmsg for batching, it is this loop that changes
 * and nothing else. */
/* ---- ngtcp2 wiring -------------------------------------------------------
 *
 * Eleven of the callbacks come ready-made from ngtcp2_crypto; the handful
 * below are the real glue. The connection is created on the first Initial
 * that names no CID we hold, and torn down by the idle timeout or a close.
 *
 * Everything from here on may allocate and may touch the interpreter, so
 * the dTHX-free rule stops at the CID lookup above. */

/* Unpredictable bytes, from the OpenSSL that is already linked - HTTP/3
 * cannot be built without TLS, so this needs no platform shim of its own.
 * A guessable Connection ID is a routing oracle, so a failure here zeroes
 * rather than falling back to something weaker; the connection that gets a
 * zero CID fails to route, which is the safe direction. */
static void hm_quic_rand_bytes(uint8_t *d, size_t n) {
    if (RAND_bytes(d, (int)n) != 1) memset(d, 0, n);
}

static ngtcp2_conn *hm_quic_get_conn(ngtcp2_crypto_conn_ref *ref) {
    return ((hm_qconn *)ref->user_data)->conn;
}

static void hm_quic_cb_rand(uint8_t *dest, size_t destlen,
                            const ngtcp2_rand_ctx *rand_ctx) {
    (void)rand_ctx;
    hm_quic_rand_bytes(dest, destlen);
}

/* ngtcp2 mints extra Connection IDs through NEW_CONNECTION_ID; each one has
 * to be routable to this connection, which is what the map is for. The
 * worker index goes in byte 0 - a fixed offset a steering program can read -
 * and the rest is random. */
static int hm_quic_cb_get_new_cid(ngtcp2_conn *conn, ngtcp2_cid *cid,
                                  uint8_t *token, size_t cidlen,
                                  void *user_data) {
    hm_qconn *qc = (hm_qconn *)user_data;
    (void)conn;
    if (cidlen > NGTCP2_MAX_CIDLEN) return NGTCP2_ERR_CALLBACK_FAILURE;
    hm_quic_rand_bytes(cid->data, cidlen);
    cid->datalen = cidlen;
    HM_QUIC_CID_WORKER(cid) = (uint8_t)qc->srv->worker_idx;
    if (ngtcp2_crypto_generate_stateless_reset_token(
            token, qc->srv->secret, sizeof(qc->srv->secret), cid) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    if (!hm_quic_cid_add(qc->srv, qc, cid->data, cid->datalen))
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

static int hm_quic_cb_remove_cid(ngtcp2_conn *conn, const ngtcp2_cid *cid,
                                 void *user_data) {
    hm_qconn *qc = (hm_qconn *)user_data;
    (void)conn;
    hm_quic_cid_remove(qc->srv, cid->data, cid->datalen);
    return 0;
}

static int hm_quic_cb_handshake_completed(ngtcp2_conn *conn, void *user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)user_data;
    SSL *ssl = (SSL *)qc->ssl;
    (void)conn;
    /* The same capture the TCP side does, through the same function: a QUIC
     * handshake IS a TLS handshake, so a client certificate presented over
     * HTTP/3 is reported exactly as one over HTTP/1.1 or HTTP/2. */
    if (ssl) hm_tls_capture_ssl(ssl, &qc->tls_proto, &qc->tls_cipher,
                                &qc->tls_peer);
    /* Counted so a test can see it: a completed QUIC handshake is entirely
     * C-side and leaves no trace an application could report on. */
    qc->srv->loop->h3_conns++;
    /* The control and QPACK streams cannot be opened before there is a
     * connection to open them on, so the HTTP/3 session starts here and
     * not at connection creation. */
    if (!qc->h3 && hm_h3_session_start(aTHX_ qc) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    if (!qc->handshake_done) {
        qc->handshake_done = 1;
        if (qc->srv->handshaking > 0) qc->srv->handshaking--;
    }
    /* NEW_TOKEN, so this client's next visit skips address validation
     * entirely - no Retry round trip even while the server is demanding one
     * of everybody else. It is bound to the address it was issued to, which
     * is what makes it safe to trust on the way back in. */
    {
        uint8_t token[NGTCP2_CRYPTO_MAX_REGULAR_TOKENLEN];
        ngtcp2_ssize n = ngtcp2_crypto_generate_regular_token(
            token, qc->srv->secret, sizeof(qc->srv->secret),
            (const ngtcp2_sockaddr *)&qc->peer, (ngtcp2_socklen)qc->peerlen,
            hm_now_ns());
        if (n > 0) (void)ngtcp2_conn_submit_new_token(conn, token, (size_t)n);
    }
    return 0;
}

/* Streams are HTTP/3's business (hm_http3.h). Until that lands the transport
 * accepts and discards them, which is what lets a handshake be tested on its
 * own. */
static int hm_quic_cb_recv_stream_data(ngtcp2_conn *conn, uint32_t flags,
                                       int64_t stream_id, uint64_t offset,
                                       const uint8_t *data, size_t datalen,
                                       void *user_data,
                                       void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)user_data;
    (void)conn; (void)offset; (void)stream_user_data;
    /* Stream bytes belong to HTTP/3. nghttp3 credits the flow-control window
     * back through recv_data and deferred_consume, so it is NOT credited
     * here as well - doing both opens the window twice and lets a peer send
     * past what was advertised. */
    if (hm_h3_recv_stream(aTHX_ qc, stream_id, data, datalen,
                          (flags & NGTCP2_STREAM_DATA_FLAG_FIN) ? 1 : 0) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

/* The peer opened this stream's send window again. nghttp3 has to be told,
 * or a stream it stopped offering when the window closed is never offered
 * again and the response simply stops. */
static int hm_quic_cb_extend_max_stream_data(ngtcp2_conn *conn,
                                             int64_t stream_id,
                                             uint64_t max_data,
                                             void *user_data,
                                             void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)user_data;
    (void)conn; (void)max_data; (void)stream_user_data;
    if (hm_h3_unblock(aTHX_ qc, stream_id) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

static int hm_quic_cb_stream_close(ngtcp2_conn *conn, uint32_t flags,
                                   int64_t stream_id, uint64_t app_error_code,
                                   void *user_data, void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)user_data;
    (void)conn; (void)stream_user_data;
    if (!(flags & NGTCP2_STREAM_CLOSE_FLAG_APP_ERROR_CODE_SET))
        app_error_code = NGHTTP3_H3_NO_ERROR;
    if (hm_h3_stream_gone(aTHX_ qc, stream_id, app_error_code) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

/* Bytes the peer acknowledged. nghttp3 hands back POINTERS into our own
 * buffers, so this is what says they may be reused - the half nghttp2 never
 * needed, because there the body was copied into a window it owned. */
static int hm_quic_cb_acked_stream_data(ngtcp2_conn *conn, int64_t stream_id,
                                        uint64_t offset, uint64_t datalen,
                                        void *user_data,
                                        void *stream_user_data) {
    dTHX;
    hm_qconn *qc = (hm_qconn *)user_data;
    (void)conn; (void)offset; (void)stream_user_data;
    if (hm_h3_acked(aTHX_ qc, stream_id, datalen) != 0)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

static void hm_quic_settings(hm_qconn *qc, ngtcp2_settings *s,
                             ngtcp2_transport_params *p) {
    ngtcp2_settings_default(s);
    ngtcp2_transport_params_default(p);
    s->initial_ts = hm_now_ns();
    s->rand_ctx.native_handle = NULL;
    /* A server must not send more than three times what it received before
     * the client's address is validated. ngtcp2 enforces that itself, but
     * only if it is fed honest byte counts and paths - which is why nothing
     * here writes around it. */
    p->initial_max_stream_data_bidi_local  = 256 * 1024;
    p->initial_max_stream_data_bidi_remote = 256 * 1024;
    p->initial_max_stream_data_uni         = 256 * 1024;
    p->initial_max_data                    = 1024 * 1024;
    p->initial_max_streams_bidi            = 128;
    p->initial_max_streams_uni             = 8;
    p->max_idle_timeout                    = 30 * NGTCP2_SECONDS;
    p->stateless_reset_token_present       = 0;
    (void)qc;
}

static void hm_quic_secret_init(void) {
    if (hm_quic_secret_ready) return;
    hm_quic_rand_bytes(hm_quic_secret, sizeof(hm_quic_secret));
    hm_quic_secret_ready = 1;
}

/* The QUIC context is built by hm_tls.h through hm_tls_ctx_one with
 * HM_TLSCTX_QUIC, not here. That is what gets it the same certificate, the
 * same client-cert policy and the same SESSION TICKET KEY as the listener's
 * TCP context - a QUIC context minting its own key silently costs every
 * cross-protocol resumption a full handshake. The ALPN callback, the TLS 1.3
 * pin and the 0-RTT refusal live there too, beside their TCP counterparts.
 */

static hm_quic_srv *hm_quic_srv_new(hm_loop *loop, hm_listener *lst, int widx) {
    hm_quic_srv *srv;
    unsigned char kbuf[HM_TLS_TKEY_MAX];
    size_t klen = 0;
    const unsigned char *tkey = NULL;
    void *ctx;
    /* The key the TCP context of this same listener is already using. */
    if (lst->tls_ctx && hm_tls_ctx_tkey(lst->tls_ctx, kbuf, &klen)) tkey = kbuf;
    ctx = hm_tls_quic_ctx_build(lst->tls_cert, lst->tls_key, lst->tls_ca,
                                lst->tls_verify, tkey, klen);
    if (!ctx) return NULL;
    srv = (hm_quic_srv *)hm_xcalloc(1, sizeof(hm_quic_srv));
    srv->lst        = lst;
    srv->loop       = loop;
    srv->worker_idx = widx;
    srv->ssl_ctx    = ctx;
    hm_quic_secret_init();
    memcpy(srv->secret, hm_quic_secret, sizeof(srv->secret));
    return srv;
}

/* ---- one connection ------------------------------------------------------ */

static void hm_quic_conn_free(pTHX_ hm_qconn *qc) {
    hm_quic_srv *srv = qc->srv;
    hm_qconn **pp;
    hm_qheap_remove(&srv->loop->qheap, qc);
    hm_quic_cid_drop_conn(srv, qc);
    hm_quic_id_remove(srv, qc);
    for (pp = &srv->conns; *pp; pp = &(*pp)->next)
        if (*pp == qc) { *pp = qc->next; break; }
    srv->nconns--;
    if (!qc->handshake_done && srv->handshaking > 0) srv->handshaking--;
    if (srv->loop->h3_live > 0) srv->loop->h3_live--;
    hm_h3_session_free(aTHX_ qc);
    if (qc->conn) ngtcp2_conn_del(qc->conn);
    /* The ossl ctx owns the SSL once it has been handed over, so the SSL is
     * freed through it and never directly - freeing both is a double free. */
    if (qc->ossl) ngtcp2_crypto_ossl_ctx_del(qc->ossl);
    else if (qc->ssl) SSL_free((SSL *)qc->ssl);
    if (qc->tls_peer) {
        hm_tls_peer *tp = (hm_tls_peer *)qc->tls_peer;
        if (tp->subject) free(tp->subject);
        if (tp->issuer)  free(tp->issuer);
        free(tp);
        qc->tls_peer = NULL;
    }
    free(qc);
}

/* Rearm this connection's place in the loop's expiry heap. Called after
 * every read and every write, because that is how often ngtcp2 moves it. */
static void hm_quic_rearm(hm_qconn *qc) {
    ngtcp2_tstamp t = ngtcp2_conn_get_expiry(qc->conn);
    if (t == UINT64_MAX) hm_qheap_remove(&qc->srv->loop->qheap, qc);
    else                 hm_qheap_set(&qc->srv->loop->qheap, qc, (uint64_t)t);
}

/* The write half. QUIC PULLS: there is no send callback and no write
 * buffer - bytes are asked for and handed straight to sendto. This is the
 * counterpart of hm_h2_flush_send, and it lives here rather than in
 * hm_http3.h for exactly that reason. 0 to keep the connection, -1 if it
 * was freed. */
static int hm_quic_write(pTHX_ hm_qconn *qc) {
    uint8_t buf[1452];                     /* a conservative path MTU */
    ngtcp2_path_storage ps;
    ngtcp2_pkt_info pi;
    for (;;) {
        nghttp3_vec vec[16];
        ngtcp2_ssize n, wrote = 0;
        nghttp3_ssize nvec = 0;
        int64_t sid = -1;
        int fin = 0;
        uint32_t flags = NGTCP2_WRITE_STREAM_FLAG_MORE;

        /* Ask HTTP/3 what it wants sent, then hand that to the transport.
         * This is the direction the h2 template does not have: nghttp2
         * PUSHED through a send callback, nghttp3 is PULLED from here. */
        if (qc->h3) {
            nvec = hm_h3_pull(aTHX_ qc, &sid, &fin, vec,
                              sizeof(vec) / sizeof(vec[0]));
            if (nvec < 0) { hm_quic_conn_free(aTHX_ qc); return -1; }
        }
        if (sid < 0) flags = NGTCP2_WRITE_STREAM_FLAG_NONE;
        else if (fin) flags |= NGTCP2_WRITE_STREAM_FLAG_FIN;

        ngtcp2_path_storage_zero(&ps);
        n = ngtcp2_conn_writev_stream(qc->conn, &ps.path, &pi, buf, sizeof(buf),
                                      &wrote, flags, sid,
                                      (const ngtcp2_vec *)vec, (size_t)nvec,
                                      hm_now_ns());
        if (n < 0) {
            if (n == NGTCP2_ERR_WRITE_MORE) {
                /* Accepted into the packet being built but not yet framed
                 * out; tell nghttp3 how much it may release and go round. */
                if (wrote > 0 && hm_h3_wrote(aTHX_ qc, sid, (size_t)wrote) != 0) {
                    hm_quic_conn_free(aTHX_ qc);
                    return -1;
                }
                continue;
            }
            if (n == NGTCP2_ERR_STREAM_DATA_BLOCKED
                || n == NGTCP2_ERR_STREAM_SHUT_WR) {
                /* This stream cannot progress; others on the connection
                 * still can, so block it rather than the whole session. */
                if (qc->h3 && sid >= 0)
                    nghttp3_conn_block_stream((nghttp3_conn *)qc->h3, sid);
                continue;
            }
            hm_quic_conn_free(aTHX_ qc);
            return -1;
        }
        if (wrote > 0 && hm_h3_wrote(aTHX_ qc, sid, (size_t)wrote) != 0) {
            hm_quic_conn_free(aTHX_ qc);
            return -1;
        }
        if (n == 0) break;                 /* nothing more to send */
        if (hm_os_sendto(qc->srv->lst->udp_fd, buf, (size_t)n,
                         (struct sockaddr *)&qc->peer, qc->peerlen) < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) break;
            hm_quic_conn_free(aTHX_ qc);
            return -1;
        }
        qc->srv->loop->bytes_out += (UV)n;
        qc->srv->loop->datagrams_out++;
    }
    hm_quic_rearm(qc);
    return 0;
}

/* A new connection, from an Initial naming no CID we hold. */
static hm_qconn *hm_quic_conn_new(pTHX_ hm_quic_srv *srv,
                                  const ngtcp2_version_cid *vc,
                                  const ngtcp2_pkt_hd *hd,
                                  const ngtcp2_cid *retry_odcid,
                                  const struct sockaddr *peer,
                                  socklen_t peerlen) {
    ngtcp2_callbacks cbs;
    ngtcp2_settings settings;
    ngtcp2_transport_params params;
    ngtcp2_cid dcid = {0}, scid = {0}, ocid = {0};
    hm_qconn *qc;
    SSL *ssl;
    struct sockaddr_storage local;
    socklen_t locallen = sizeof(local);

    qc = (hm_qconn *)hm_xcalloc(1, sizeof(hm_qconn));
    qc->srv      = srv;
    qc->id       = ++hm_id_counter;
    qc->heap_idx = -1;
    memcpy(&qc->peer, peer, peerlen);
    qc->peerlen  = peerlen;
    /* Formatted once here rather than per request: REMOTE_ADDR is wanted on
     * every request this connection ever carries, and the address does not
     * change (migration is deferred). */
    hm_fmt_peer(qc->peer_str, sizeof(qc->peer_str), &qc->peer_port,
                (struct sockaddr *)&qc->peer);

    /* Our own Connection ID, with the worker index where a steering program
     * can find it. The client's SCID becomes our DCID. */
    hm_quic_rand_bytes(scid.data, HM_QUIC_CIDLEN);
    scid.datalen = HM_QUIC_CIDLEN;
    HM_QUIC_CID_WORKER(&scid) = (uint8_t)srv->worker_idx;
    memcpy(dcid.data, vc->scid, vc->scidlen);
    dcid.datalen = vc->scidlen;
    memcpy(ocid.data, vc->dcid, vc->dcidlen);
    ocid.datalen = vc->dcidlen;

    memset(&cbs, 0, sizeof(cbs));
    /* The eleven ngtcp2_crypto supplies ready-made. */
    cbs.recv_client_initial       = ngtcp2_crypto_recv_client_initial_cb;
    cbs.recv_crypto_data          = ngtcp2_crypto_recv_crypto_data_cb;
    cbs.encrypt                   = ngtcp2_crypto_encrypt_cb;
    cbs.decrypt                   = ngtcp2_crypto_decrypt_cb;
    cbs.hp_mask                   = ngtcp2_crypto_hp_mask_cb;
    cbs.update_key                = ngtcp2_crypto_update_key_cb;
    cbs.delete_crypto_aead_ctx    = ngtcp2_crypto_delete_crypto_aead_ctx_cb;
    cbs.delete_crypto_cipher_ctx  = ngtcp2_crypto_delete_crypto_cipher_ctx_cb;
    cbs.get_path_challenge_data   = ngtcp2_crypto_get_path_challenge_data_cb;
    cbs.version_negotiation       = ngtcp2_crypto_version_negotiation_cb;
    /* ...and the glue that is actually ours. */
    cbs.rand                      = hm_quic_cb_rand;
    cbs.get_new_connection_id     = hm_quic_cb_get_new_cid;
    cbs.remove_connection_id      = hm_quic_cb_remove_cid;
    cbs.handshake_completed       = hm_quic_cb_handshake_completed;
    cbs.recv_stream_data          = hm_quic_cb_recv_stream_data;
    cbs.stream_close              = hm_quic_cb_stream_close;
    cbs.acked_stream_data_offset  = hm_quic_cb_acked_stream_data;
    cbs.extend_max_stream_data    = hm_quic_cb_extend_max_stream_data;

    hm_quic_settings(qc, &settings, &params);
    if (retry_odcid) {
        /* Validated by Retry. The transport parameters must then name the id
         * the client used BEFORE the Retry as the original, and the one it
         * used after as retry_scid - the client checks both, and getting
         * them the wrong way round fails the handshake with no useful error. */
        params.original_dcid         = *retry_odcid;
        params.retry_scid            = hd->dcid;
        params.retry_scid_present    = 1;
    } else {
        params.original_dcid         = ocid;
    }
    params.original_dcid_present = 1;
    if (hd->tokenlen) {
        settings.token     = hd->token;
        settings.tokenlen  = hd->tokenlen;
        settings.token_type = retry_odcid ? NGTCP2_TOKEN_TYPE_RETRY
                                          : NGTCP2_TOKEN_TYPE_NEW_TOKEN;
    }

    if (getsockname(srv->lst->udp_fd, (struct sockaddr *)&local, &locallen) < 0)
        locallen = 0;
    ngtcp2_path_storage_init(&qc->path,
                             (struct sockaddr *)&local, locallen,
                             (struct sockaddr *)&qc->peer, peerlen, NULL);

    if (ngtcp2_conn_server_new(&qc->conn, &dcid, &scid, &qc->path.path,
                               vc->version, &cbs, &settings, &params,
                               NULL, qc) != 0) {
        free(qc);
        return NULL;
    }

    ssl = SSL_new((SSL_CTX *)srv->ssl_ctx);
    if (!ssl || ngtcp2_crypto_ossl_ctx_new(&qc->ossl, ssl) != 0
        || ngtcp2_crypto_ossl_configure_server_session(ssl) != 0) {
        if (ssl && !qc->ossl) SSL_free(ssl);
        ngtcp2_conn_del(qc->conn);
        free(qc);
        return NULL;
    }
    qc->ssl = ssl;
    qc->conn_ref.get_conn  = hm_quic_get_conn;
    qc->conn_ref.user_data = qc;
    SSL_set_app_data(ssl, &qc->conn_ref);
    /* Without this the SSL has no side and the first Initial comes back as
     * NGTCP2_ERR_CRYPTO with nothing in the error queue to say why. The TLS
     * paths elsewhere in this dist get their accept state from SSL_accept;
     * QUIC never calls it, because ngtcp2 drives the handshake itself. */
    SSL_set_accept_state(ssl);
    ngtcp2_conn_set_tls_native_handle(qc->conn, qc->ossl);

    if (!hm_quic_cid_add(srv, qc, scid.data, scid.datalen)) {
        hm_quic_conn_free(aTHX_ qc);
        return NULL;
    }
    /* The client's ORIGINAL destination id, the random one it invented for
     * its first Initial, is routed here too. Until the client has seen our
     * reply it keeps addressing that, so without this a retransmitted
     * Initial - which is every handshake with any loss, and was every second
     * packet in testing - looks like a brand new connection and builds a
     * second one that then fails. Retired by ngtcp2 through
     * remove_connection_id once the handshake has moved on. */
    if (ocid.datalen && ocid.datalen <= NGTCP2_MAX_CIDLEN)
        (void)hm_quic_cid_add(srv, qc, ocid.data, ocid.datalen);
    hm_quic_id_add(srv, qc);
    qc->next = srv->conns;
    srv->conns = qc;
    srv->nconns++;
    srv->handshaking++;
    srv->loop->h3_live++;
    return qc;
}

/* The soonest QUIC deadline, or UINT64_MAX when there is none. */
static uint64_t hm_quic_next_deadline(hm_loop *loop) {
    return loop->qheap.n ? loop->qheap.a[0]->expiry : (uint64_t)-1;
}

/* Every connection whose deadline has passed. Called once per loop turn,
 * after the dispatch, and gated on the heap being non-empty - which is one
 * compare on a server with no QUIC listener. */
static void hm_quic_expire(pTHX_ hm_loop *loop) {
    uint64_t now = hm_now_ns();
    while (loop->qheap.n && loop->qheap.a[0]->expiry <= now) {
        hm_qconn *qc = loop->qheap.a[0];
        if (ngtcp2_conn_handle_expiry(qc->conn, now) != 0) {
            hm_quic_conn_free(aTHX_ qc);
            continue;
        }
        if (hm_quic_write(aTHX_ qc) < 0) continue;
        /* hm_quic_write rearmed it; if the deadline did not move we would
         * spin, so a connection that stays due is dropped rather than
         * looped on. */
        if (loop->qheap.n && loop->qheap.a[0] == qc && qc->expiry <= now)
            hm_quic_conn_free(aTHX_ qc);
    }
}

/* Build this worker's QUIC server for a listener, and tear it down. Called
 * from hm_attach_server and hm_loop_free beside the TCP half. */
static void hm_quic_srv_attach(pTHX_ hm_loop *loop, hm_listener *lst, int widx) {
    PERL_UNUSED_CONTEXT;
    if (lst->udp_fd < 0 || lst->quic) return;
    lst->quic = (void *)hm_quic_srv_new(loop, lst, widx);
    if (lst->quic) lst->quic_ctx = ((hm_quic_srv *)lst->quic)->ssl_ctx;
}

/* Tell every live connection the server is going away.
 *
 * A QUIC connection is not reachable through anything fd-indexed, so none of
 * the TCP shutdown path touches it: without this a client waits out its idle
 * timeout instead of being told, and a restart looks like a network fault.
 * CONNECTION_CLOSE is written directly rather than through the pull loop,
 * because the connection is being torn down and there is nothing after it. */
static void hm_quic_shutdown(pTHX_ hm_loop *loop) {
    int i;
    for (i = 0; i < loop->nlisteners; i++) {
        hm_quic_srv *srv = (hm_quic_srv *)loop->listeners[i].quic;
        hm_qconn *qc;
        if (!srv) continue;
        for (qc = srv->conns; qc; qc = qc->next) {
            uint8_t buf[1452];
            ngtcp2_path_storage ps;
            ngtcp2_pkt_info pi;
            ngtcp2_ccerr err;
            ngtcp2_ssize n;
            if (qc->closing || qc->draining) continue;
            ngtcp2_ccerr_default(&err);
            ngtcp2_path_storage_zero(&ps);
            n = ngtcp2_conn_write_connection_close(qc->conn, &ps.path, &pi,
                                                   buf, sizeof(buf), &err,
                                                   hm_now_ns());
            if (n > 0) (void)hm_os_sendto(srv->lst->udp_fd, buf, (size_t)n,
                                          (struct sockaddr *)&qc->peer,
                                          qc->peerlen);
            qc->closing = 1;
        }
    }
}

/* Install a rebuilt QUIC context on a listener.
 *
 * Connections already up keep the SSL they hold - their handshake is long
 * finished and the certificate is not consulted again - so nothing in flight
 * is disturbed. The next handshake this worker accepts uses the new one.
 * Exactly the rule the TCP side follows. */
static void hm_quic_ctx_swap(pTHX_ hm_listener *lst, void *fresh) {
    hm_quic_srv *srv = (hm_quic_srv *)lst->quic;
    PERL_UNUSED_CONTEXT;
    if (!srv || !fresh) return;
    if (srv->ssl_ctx) SSL_CTX_free((SSL_CTX *)srv->ssl_ctx);
    srv->ssl_ctx  = fresh;
    lst->quic_ctx = fresh;
}

static void hm_quic_srv_free(pTHX_ hm_listener *lst) {
    hm_quic_srv *srv = (hm_quic_srv *)lst->quic;
    if (!srv) return;
    while (srv->conns) hm_quic_conn_free(aTHX_ srv->conns);
    if (srv->ssl_ctx) SSL_CTX_free((SSL_CTX *)srv->ssl_ctx);
    free(srv);
    lst->quic = NULL;
    lst->quic_ctx = NULL;
}

/* Run the decoder over bytes a test hands in. The first thing that touches
 * an attacker-controlled datagram, reachable from Perl so the hand-built
 * cases - a valid Initial, a truncated one, garbage, an unsupported version
 * with an over-long Connection ID - can be written as byte strings. */
static void hm_quic_decode_probe(const unsigned char *p, size_t n,
                                 int *rv, uint32_t *ver,
                                 size_t *dlen, size_t *slen) {
    ngtcp2_version_cid vc;
    memset(&vc, 0, sizeof(vc));
    if (n == 0) { *rv = -1; *ver = 0; *dlen = 0; *slen = 0; return; }
    *rv = ngtcp2_pkt_decode_version_cid(&vc, p, n, HM_QUIC_CIDLEN);
    *ver  = vc.version;
    *dlen = vc.dcidlen;
    *slen = vc.scidlen;
}

static void hm_quic_readable(pTHX_ hm_loop *loop, hm_listener *lst) {
    static unsigned char buf[HM_QUIC_MAX_UDP];
    int batch = 0;
    if (loop->stopping) return;
    for (;;) {
        struct sockaddr_storage ss;
        socklen_t slen = sizeof(ss);
        ssize_t n = hm_os_recvfrom(lst->udp_fd, buf, sizeof(buf),
                                   (struct sockaddr *)&ss, &slen);
        if (n < 0) break;                      /* EAGAIN: drained */
        if (n == 0) continue;                  /* an empty datagram is not QUIC */
        hm_quic_packet(aTHX_ loop, lst, buf, (size_t)n,
                       (struct sockaddr *)&ss, slen);
        if (++batch >= 64) break;
    }
}

/* The runtime QUIC stack banner, the counterpart to hm_tls_library. Both
 * library versions, because a QUIC problem is as often nghttp3's as
 * ngtcp2's and a bug report naming one of them is half a report. Built once
 * and cached: it is a diagnostic, not a hot path. */
static const char *hm_quic_library(void) {
    static char buf[96];
    if (!buf[0]) {
        const ngtcp2_info  *q = ngtcp2_version(0);
        const nghttp3_info *h = nghttp3_version(0);
        snprintf(buf, sizeof(buf), "ngtcp2 %s, nghttp3 %s",
                 (q && q->version_str) ? q->version_str : "?",
                 (h && h->version_str) ? h->version_str : "?");
    }
    return buf;
}

#else /* !HM_HAVE_HTTP3 */

static int hm_quic_available(void) { return 0; }
static const char *hm_quic_library(void) { return 0; }
static int hm_quic_cid_selftest(void)  { return 0; }
static int hm_quic_heap_selftest(void) { return 0; }
static int hm_quic_token_selftest(void) { return 0; }
static void hm_quic_expire(pTHX_ hm_loop *loop) {
    PERL_UNUSED_CONTEXT; (void)loop;
}
static void hm_quic_srv_attach(pTHX_ hm_loop *loop, hm_listener *lst, int widx) {
    PERL_UNUSED_CONTEXT; (void)loop; (void)lst; (void)widx;
}
static void hm_quic_srv_free(pTHX_ hm_listener *lst) {
    PERL_UNUSED_CONTEXT; (void)lst;
}
static void hm_quic_shutdown(pTHX_ hm_loop *loop) {
    PERL_UNUSED_CONTEXT; (void)loop;
}
static void hm_quic_ctx_swap(pTHX_ hm_listener *lst, void *fresh) {
    PERL_UNUSED_CONTEXT; (void)lst; (void)fresh;
}
static uint64_t hm_quic_next_deadline(hm_loop *loop) {
    (void)loop; return (uint64_t)-1;
}
static void hm_quic_secret_init(void) { }
static void hm_quic_decode_probe(const unsigned char *p, size_t n,
                                 int *rv, uint32_t *ver,
                                 size_t *dlen, size_t *slen) {
    (void)p; (void)n;
    *rv = -1; *ver = 0; *dlen = 0; *slen = 0;
}

/* Never reached - a listener only gets a udp_fd when http3 is on, and that
 * is refused at boot on this build - but it has to compile, because the
 * routing in hm_dispatch is not itself conditional. */
static void hm_quic_readable(pTHX_ hm_loop *loop, hm_listener *lst) {
    PERL_UNUSED_CONTEXT;
    (void)loop; (void)lst;
}

#endif /* HM_HAVE_HTTP3 */

#endif /* HM_QUIC_H */
