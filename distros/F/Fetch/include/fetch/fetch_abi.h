#ifndef FETCH_ABI_H
#define FETCH_ABI_H

/* Shared C ABI between Fetch (the provider) and consumers such as
 * Reverse::Proxy. It is resolved at RUNTIME via Fetch::_abi_ptr - a DBI-style
 * function-pointer table - so there is no link-time symbol coupling and each
 * dist builds and upgrades independently. A consumer vendors a copy of this
 * header at a pinned FETCH_ABI_VERSION and checks abi_version at boot; a
 * mismatch means "fall back", never a crash.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, AV, HV, STRLEN and pTHX are defined. */

#define FETCH_ABI_VERSION 2

/* one outbound request header; lengths are explicit (a value may be binary) */
typedef struct fetch_hdr {
    const char *name; STRLEN nlen;
    const char *val;  STRLEN vlen;
} fetch_hdr;

/* Called once when the upstream request settles, to shape the value the
 * returned future resolves to (for a proxy: a PSGI [ status, \@hdrs, \@body ]).
 *   ok = 1 -> status/headers/body describe the upstream response; headers is
 *             the flat [k,v,...] AV and body the content SV, both borrowed;
 *             err = NULL.
 *   ok = 0 -> transport failure/cancel; status = 0, headers = NULL,
 *             body = NULL, err = the failure SV (borrowed) or NULL.
 * Must return a new (+1-owned) SV; the caller settles the future with it and
 * then drops the reference. Must not croak. */
typedef SV *(*fetch_map_cb)(pTHX_ int ok, int status, AV *headers, SV *body,
                            SV *err, void *ud);

/* Streaming callbacks (see request_stream); ud is the consumer's context.
 * on_headers fires once with the status and the flat [k,v,...] header AV;
 * on_body fires per body chunk (chunk borrowed); on_done fires once at the end
 * (ok=1 success; ok=0 with err the failure SV or NULL). */
typedef void (*fetch_on_headers)(pTHX_ int status, AV *headers, void *ud);
typedef void (*fetch_on_body)(pTHX_ const char *chunk, STRLEN len, void *ud);
typedef void (*fetch_on_done)(pTHX_ int ok, SV *err, void *ud);

/* v2 outbound observer. `start` fires once per HOP - a redirect chain is
 * several requests and each is observed - with the merged header list still
 * MUTABLE: push a name and a value onto `headers` and the request carries
 * them. That is the point of the hook; a tracing layer has to be able to add
 * a `traceparent` to a request the application wrote.
 * It returns an opaque token, handed back to `done` when that same hop
 * settles, so a consumer can correlate the two without a lookup table.
 * `done` fires exactly ONCE per start, with exactly one of res (the response)
 * and err (the failure) non-NULL - including a timeout, a DNS failure and a
 * refused connection, which are the endings an instrumented client most wants
 * and the easiest to leak. Both are borrowed. Neither may croak. */
typedef void *(*fetch_obs_start_cb)(pTHX_ const char *method, STRLEN mlen,
                                    const char *url, STRLEN ulen,
                                    AV *headers, void *ud);
typedef void  (*fetch_obs_done_cb)(pTHX_ void *token, SV *res, SV *err,
                                   void *ud);

typedef struct fetch_abi {
    int abi_version;                 /* == FETCH_ABI_VERSION */

    /* Construct a Fetch user agent from flat key/value SV pairs (the same
     * options Fetch->new takes: loop, pool_size, tls_verify, timeout, agent,
     * headers, cookie_jar, keep_alive, max_redirects, simple_response). kv has
     * nkv SVs (nkv even). Returns the blessed Fetch UA SV (+1 owned). */
    SV *(*ua_new)(pTHX_ SV **kv, int nkv);

    /* Issue one HTTP request on $ua_sv (a Fetch object), building the request
     * entirely from C (no Perl option hash on the hot path). method and url are
     * NUL-terminated; body may be NULL. max_redirects < 0 means "use the UA's
     * own default". When the request settles, `map` shapes the result. Returns
     * the derived future SV (a Fetch::Future, +1 owned by the caller) - hand it
     * to an awaiting server or call ->get on it. */
    SV *(*request)(pTHX_ SV *ua_sv,
                   const char *method, const char *url,
                   const fetch_hdr *hdrs, int nhdrs,
                   const char *body, STRLEN blen,
                   double timeout, int max_redirects,
                   fetch_map_cb map, void *ud);

    /* Extract parts from an already-resolved response hashref (a blessed
     * Fetch::Response or the raw simple_response hash), no method dispatch.
     * Any out-ptr may be NULL; *headers and *body are borrowed. For the
     * blocking (non-Hyperman) path. */
    void (*res_parts)(pTHX_ SV *res, int *status, AV **headers, SV **body);

    /* Like request, but streams the response instead of buffering: on_headers
     * fires once up front, on_body per chunk, on_done at completion. Returns
     * the request future SV (+1 owned) - keep it alive until on_done fires.
     * max_redirects < 0 uses the UA default. */
    SV *(*request_stream)(pTHX_ SV *ua_sv, const char *method, const char *url,
                          const fetch_hdr *hdrs, int nhdrs,
                          const char *body, STRLEN blen,
                          double timeout, int max_redirects,
                          fetch_on_headers on_headers, fetch_on_body on_body,
                          fetch_on_done on_done, void *ud);

    /* Raw blocking upstream connection for an Upgrade/WebSocket tunnel. TLS
     * (tls=1) reuses Fetch's client SSL_CTX, so the consumer tunnels to a
     * wss/https upstream without linking OpenSSL. All pure C (no pTHX):
     *   tunnel_connect -> opaque handle (NULL on failure)
     *   tunnel_fd      -> underlying fd, for select()
     *   tunnel_read    -> bytes (>0), 0 = EOF, -1 = error
     *   tunnel_write_all -> 0 all written, -1 = error
     *   tunnel_pending -> bytes buffered in TLS (drain before select); 0 plain
     *   tunnel_close   -> shut down and free the handle */
    void *(*tunnel_connect)(const char *host, int port, int tls, int verify);
    int   (*tunnel_fd)(void *conn);
    IV    (*tunnel_read)(void *conn, char *buf, IV len);
    IV    (*tunnel_write_all)(void *conn, const char *buf, IV len);
    int   (*tunnel_pending)(void *conn);
    void  (*tunnel_close)(void *conn);

    /* ---- v2: observe outbound requests ---------------------------------- *
     * Fetch had no way to see a request go out. `headers` is a per-request
     * option the CALLER sets, which is no use to anything wanting to annotate
     * a request the application wrote, or to be told how it ended.
     *
     * Registration is process-global rather than per agent: an agent is a
     * per-worker object and a process may hold several, while an observer is
     * a property of the process. Register at boot. There is no
     * deregistration. Returns 1, or 0 when the table is full. */
    int (*on_request)(pTHX_ fetch_obs_start_cb start, fetch_obs_done_cb done,
                      void *ud);
} fetch_abi;

/* How many outbound observers Fetch will hold. Fixed, so registration
 * allocates nothing and an uninstrumented request pays one branch. */
#define FETCH_ABI_MAX_OBSERVERS 8

#endif /* FETCH_ABI_H */
