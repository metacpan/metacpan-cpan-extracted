/* --- Async TCP connect, I/O dispatch, timers, keepalive, reconnect,
 *     pipeline advance, and OpenSSL one-time init. ---
 *
 * Forward decls for symbols defined later in this file but called from
 * earlier in the same file (cross-file callers use the forwards in
 * ClickHouse.xs).
 */
static void io_cb(EV_P_ ev_io *w, int revents);
static void on_connect_done(ev_clickhouse_t *self);

#ifdef HAVE_OPENSSL
/* Drain OpenSSL's per-thread error queue into self->last_tls_error
 * (most recent error wins). Safe to call when the queue is empty —
 * we leave the previous value untouched. */
static void capture_tls_error(ev_clickhouse_t *self) {
    unsigned long e = 0, last = 0;
    while ((e = ERR_get_error()) != 0) last = e;
    if (!last) return;
    char buf[256];
    ERR_error_string_n(last, buf, sizeof(buf));
    CLEAR_STR(self->last_tls_error);
    self->last_tls_error = savepv(buf);
}
#endif

static void start_connect(ev_clickhouse_t *self) {
    struct addrinfo hints, *res = NULL;
    int fd, ret;
    char port_str[16];

    self->connect_gen++;

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
        fail_connection(self, errbuf);
        return;
    }

    fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (fd < 0) {
        freeaddrinfo(res);
        fail_connection(self, "socket() failed");
        return;
    }

    /* non-blocking */
    {
        int fl = fcntl(fd, F_GETFL);
        if (fl < 0 || fcntl(fd, F_SETFL, fl | O_NONBLOCK) < 0) {
            freeaddrinfo(res);
            close(fd);
            fail_connection(self, "fcntl O_NONBLOCK failed");
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
        fail_connection(self, errbuf);
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

/* Mark the connection as ready, fire on_connect, dispatch queued queries.
 * Returns 1 if self was freed. */
static int finish_connect(ev_clickhouse_t *self) {
    stop_timing(self);
    self->connected = 1;
    CLEAR_STR(self->last_tls_error);    /* successful connect supersedes stale TLS error */
    if (self->on_connect &&
        fire_zero_arg_cb(self, self->on_connect, "connect")) return 1;
    if (!ngx_queue_empty(&self->send_queue))
        return pipeline_advance(self);
    return 0;
}

static void on_connect_done(ev_clickhouse_t *self) {
    self->connecting = 0;
    self->reconnect_attempts = 0;

    stop_writing(self);
    /* Keep the connect_timeout timer armed across the TLS handshake and
     * native ServerHello phases — finish_connect() stops it once the
     * connection is fully ready to accept queries. */

#ifdef HAVE_OPENSSL
    if (self->tls_enabled) {
        int ret;
        self->ssl_ctx = SSL_CTX_new(TLS_client_method());
        if (!self->ssl_ctx) {
            fail_connection(self, "SSL_CTX_new failed");
            return;
        }
        SSL_CTX_set_default_verify_paths(self->ssl_ctx);
        if (self->tls_skip_verify)
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_NONE, NULL);
        else
            SSL_CTX_set_verify(self->ssl_ctx, SSL_VERIFY_PEER, NULL);
        if (self->tls_ca_file) {
            if (SSL_CTX_load_verify_locations(self->ssl_ctx, self->tls_ca_file, NULL) != 1) {
                capture_tls_error(self);
                fail_connection(self, "SSL_CTX_load_verify_locations failed");
                return;
            }
        }
        /* Mutual TLS: load client certificate + private key when both
         * are configured. SSL_CTX_check_private_key verifies that the
         * private key matches the loaded certificate's public half. */
        if (self->tls_cert_file && self->tls_key_file) {
            if (SSL_CTX_use_certificate_chain_file(self->ssl_ctx, self->tls_cert_file) != 1) {
                capture_tls_error(self);
                fail_connection(self, "SSL_CTX_use_certificate_chain_file failed");
                return;
            }
            if (SSL_CTX_use_PrivateKey_file(self->ssl_ctx, self->tls_key_file, SSL_FILETYPE_PEM) != 1) {
                capture_tls_error(self);
                fail_connection(self, "SSL_CTX_use_PrivateKey_file failed");
                return;
            }
            if (SSL_CTX_check_private_key(self->ssl_ctx) != 1) {
                capture_tls_error(self);
                fail_connection(self, "TLS client cert / private key mismatch");
                return;
            }
        } else if (self->tls_cert_file || self->tls_key_file) {
            fail_connection(self, "tls_cert_file and tls_key_file must both be set");
            return;
        }
        self->ssl = SSL_new(self->ssl_ctx);
        if (!self->ssl) {
            capture_tls_error(self);
            fail_connection(self, "SSL_new failed");
            return;
        }
        SSL_set_fd(self->ssl, self->fd);

        int host_is_ip = is_ip_literal(self->host);

        /* SNI must not be sent for IP address literals (RFC 6066 s3) */
        if (!host_is_ip)
            SSL_set_tlsext_host_name(self->ssl, self->host);

        /* Verify server certificate matches hostname or IP */
        if (!self->tls_skip_verify) {
            X509_VERIFY_PARAM *param = SSL_get0_param(self->ssl);
            X509_VERIFY_PARAM_set_hostflags(param, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
            if (host_is_ip)
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
                capture_tls_error(self);
                fail_connection(self, "SSL_connect failed");
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
        send_replace(self, hello, hello_len);

        self->native_state = NATIVE_WAIT_HELLO;
        start_writing(self);
        return;
    }

    /* HTTP protocol: connection is ready */
    (void)finish_connect(self);
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
            return teardown_io_error(self, strerror(errno), "write error");
        }
        if (n == 0)
            return teardown_io_error(self, "connection closed during write",
                                     "connection closed");
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
        teardown_io_error(self, strerror(errno), "read error");
        return;
    }

    if (n == 0) {
        /* connection closed — fire on_error and drain pending if we
         * have an in-flight request or haven't finished handshake */
        int had_inflight = (self->send_count > 0 || !self->connected);
        int has_queued = !ngx_queue_empty(&self->send_queue);

        if (had_inflight) {
            int gen = self->connect_gen;
            emit_error(self, "connection closed by server");
            if (check_destroyed(self)) return;
            if (self->connect_gen != gen) return;
            /* Only cancel in-flight cb_queue (irrecoverable).
             * Keep send_queue if auto_reconnect — those haven't been sent yet. */
            if (!self->auto_reconnect || !has_queued) {
                if (cancel_pending(self, "connection closed")) return;
            } else {
                /* Cancel only the in-flight cb_queue entries */
                self->callback_depth++;
                drain_cb_queue(self, "connection closed");
                self->callback_depth--;
                if (check_destroyed(self)) return;
            }
            if (self->connect_gen != gen) return;
        }
        if (cleanup_connection(self)) return;   /* on_disconnect freed self */

        /* Auto-reconnect if we have queued requests or flag is set */
        if (self->auto_reconnect && self->host) {
            schedule_reconnect(self);
        }
        return;
    }

    self->recv_len += n;

    /* Defensive ceiling: a runaway response (server stuck in a bad state,
     * pathological row sizes, or a header-injection attack) shouldn't be
     * able to consume unbounded memory. Caller opts in via max_recv_buffer;
     * 0 (default) keeps the historical behaviour of growing without limit
     * up to CH_MAX_DECOMPRESS_SIZE on compressed paths. */
    if (self->max_recv_buffer > 0 && self->recv_len > self->max_recv_buffer) {
        char errmsg[80];
        snprintf(errmsg, sizeof(errmsg),
                 "recv buffer %lu exceeded max_recv_buffer %lu",
                 (unsigned long)self->recv_len,
                 (unsigned long)self->max_recv_buffer);
        teardown_io_error(self, errmsg, "recv buffer overflow");
        return;
    }

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

        stop_writing(self);
        /* Don't stop the connect_timeout timer here — it must keep
         * running across TLS handshake and native ServerHello stages.
         * finish_connect() stops it once the connection is fully ready. */

        if (getsockopt(self->fd, SOL_SOCKET, SO_ERROR, &err, &errlen) < 0)
            err = errno;
        if (err != 0) {
            char errbuf[256];
            snprintf(errbuf, sizeof(errbuf), "connect: %s", strerror(err));
            fail_connection(self, errbuf);
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
                send_replace(self, hello, hello_len);
                self->native_state = NATIVE_WAIT_HELLO;
                start_writing(self);
                return;
            }

            /* HTTP protocol: fire on_connect */
            (void)finish_connect(self);
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
                capture_tls_error(self);
                fail_connection(self, "SSL handshake failed");
            }
            return;
        }
    }
#endif

    if (revents & EV_WRITE) {
        if (try_write(self)) return;
        if (self->fd < 0) return;
        if (self->pending_addendum_finish && self->send_pos >= self->send_len) {
            self->pending_addendum_finish = 0;
            self->native_state = NATIVE_IDLE;
            if (finish_connect(self)) return;
        }
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

    /* Treat any pre-`connected=1` timeout as a connect timeout — covers
     * TCP connect, TLS handshake, and native ServerHello stages. */
    if (!self->connected) {
        stop_writing(self);
        fail_connection(self, "connect timeout");
    } else {
        /* query timeout */
        CLEAR_SV(self->native_rows);
        CLEAR_SV(self->native_col_names);
        CLEAR_SV(self->native_col_types);
        CLEAR_SV(self->native_totals);
        CLEAR_SV(self->native_extremes);
        lc_free_dicts(self);
        CLEAR_INSERT(self);
        CLEAR_STR(self->insert_err);
        self->native_state = NATIVE_IDLE;
        if (self->send_count > 0) self->send_count--;

        int gen = self->connect_gen;
        /* Must reconnect — server may still be processing */
        if (teardown_after_deliver(self, "query timeout", "query timeout")) return;
        if (self->connect_gen != gen) return;
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

    /* Native: enqueue like the HTTP branch below rather than writing into
     * send_buf, so a queued query can never overwrite the unsent ping and the
     * PONG is matched to its callback by the normal response path. The send
     * entry carries a deadline so a server that never PONGs is detected. */
    if (self->protocol == PROTO_NATIVE) {
        size_t ping_len;
        char *ping = build_native_ping(&ping_len);
        ev_ch_send_t *s = alloc_send();
        s->data = ping;
        s->data_len = ping_len;
        s->cb = SvREFCNT_inc(keepalive_noop_cb);
        s->query_timeout = self->query_timeout > 0
            ? self->query_timeout : self->keepalive;
        enqueue_send(self, s);
    } else {
        /* HTTP: enqueue a real ping with a no-op callback. ClickHouse's
         * HTTP server closes idle connections after a few seconds, so
         * relying on TCP keepalive (kernel default ~2h) is not enough. */
        size_t req_len;
        char *req = build_http_ping_request(self, &req_len);
        ev_ch_send_t *s = alloc_send();
        s->data = req;
        s->data_len = req_len;
        s->cb = SvREFCNT_inc(keepalive_noop_cb);
        enqueue_send(self, s);
    }
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
    if (self->reconnect_max_attempts > 0
        && self->reconnect_attempts >= self->reconnect_max_attempts) {
        /* Give up so the user isn't trapped in an infinite loop on a
         * permanent failure (bad host, wrong creds). Drain any queries
         * still in send_queue first so their callbacks see the failure
         * instead of being silently orphaned. */
        emit_error(self, "max reconnect attempts exceeded");
        if (check_destroyed(self)) return;
        (void)cancel_pending(self, "max reconnect attempts exceeded");
        return;
    }
    /* Always defer through ev_timer so a synchronous start_connect failure
     * (e.g. getaddrinfo error) cannot cause unbounded fail_connection ->
     * schedule_reconnect -> start_connect recursion on the C stack. A
     * delay of 0 fires on the next event-loop iteration, not inline. */
    double delay = self->reconnect_delay > 0 ? self->reconnect_delay : 0.0;
    int i;
    for (i = 0; i < self->reconnect_attempts && i < 20; i++)
        delay *= 2;
    if (self->reconnect_max_delay > 0 && delay > self->reconnect_max_delay)
        delay = self->reconnect_max_delay;
    /* Apply jitter AFTER the cap so a configured ceiling isn't silently
     * exceeded. rand() / RAND_MAX is uniform in [0, 1]; clamping to the
     * cap again keeps the worst case bounded. */
    if (self->reconnect_jitter > 0 && delay > 0) {
        double j = ((double)rand() / (double)RAND_MAX) * self->reconnect_jitter;
        delay += delay * j;
        if (self->reconnect_max_delay > 0 && delay > self->reconnect_max_delay)
            delay = self->reconnect_max_delay;
    }
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

/* Send one request at a time, wait for response, then send the next.
 * Returns 1 if self was freed (caller must not access self). */
static int pipeline_advance(ev_clickhouse_t *self) {
    if (!self->connected) return 0;

    if (self->send_count > 0) {
        start_reading(self);
        return 0;
    }

    /* Check drain callback when all pending work is done */
    if (ngx_queue_empty(&self->send_queue) && self->pending_count == 0
        && self->on_drain) {
        SV *drain_cb = self->on_drain;
        self->on_drain = NULL;
        if (fire_zero_arg_cb(self, drain_cb, "drain")) {
            SvREFCNT_dec(drain_cb);
            return 1;
        }
        /* Dropping the last ref to the drain CV can free a closure that
         * captured $ch — DESTROY then runs. Guard with callback_depth so
         * the free is deferred, then detect it before touching self. */
        self->callback_depth++;
        SvREFCNT_dec(drain_cb);
        self->callback_depth--;
        if (check_destroyed(self)) return 1;
    }

    /* Restart keepalive timer when idle (start_keepalive is a no-op if already
     * timing or if keepalive disabled) */
    if (ngx_queue_empty(&self->send_queue) && self->pending_count == 0)
        start_keepalive(self);

    /* send next request from queue */
    if (!ngx_queue_empty(&self->send_queue)) {
        /* Stop keepalive during active query */
        stop_keepalive(self);
        emit_trace(self, "dispatch query (pending=%d)", self->pending_count);

        /* on_trace is user code: it may have called finish()/reset() or
         * dropped the last reference (DESTROY), any of which drains or
         * frees the send queue. Re-validate the connection and re-derive
         * the head entry AFTER the trace so we never touch a send struct
         * that cancel_pending has already released to the freelist. */
        if (self->magic != EV_CH_MAGIC || !self->connected
            || ngx_queue_empty(&self->send_queue))
            return check_destroyed(self);

        ngx_queue_t *q = ngx_queue_head(&self->send_queue);
        ev_ch_send_t *send = ngx_queue_data(q, ev_ch_send_t, queue);

        /* set up send buffer */
        ensure_send_cap(self, send->data_len);
        Copy(send->data, self->send_buf, send->data_len, char);
        self->send_len = send->data_len;
        self->send_pos = 0;

        /* move cb to recv queue */
        SV *dispatched_cb = send->cb;
        ngx_queue_remove(q);
        push_cb_owned_ex(self, send->cb, send->raw,
                          send->on_data, send->on_complete,
                          send->query_timeout);
        CLEAR_SV(send->on_data);
        send->on_complete = NULL;       /* ownership transferred to cbt */
        /* Track query_id + dispatch start time (used by on_query_complete). */
        CLEAR_STR(self->last_query_id);
        if (send->query_id) { self->last_query_id = send->query_id; send->query_id = NULL; }
        self->query_start_time = ev_now(self->loop);

        /* on_query_start: fire with the resolved query_id, just before
         * the write side runs. Suppressed for keepalive PINGs to match
         * on_query_complete semantics. */
        if (self->on_query_start && !IS_KEEPALIVE_CB(dispatched_cb)) {
            dSP;
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(self->last_query_id
                  ? sv_2mortal(newSVpv(self->last_query_id, 0))
                  : &PL_sv_undef);
            PUTBACK;
            int gen_before = self->connect_gen;
            self->callback_depth++;
            PINNED_CALL_SV(self->on_query_start, G_EVAL | G_VOID | G_DISCARD);
            self->callback_depth--;
            WARN_AND_CLEAR_ERRSV("on_query_start");
            FREETMPS; LEAVE;
            /* The handler may have torn the connection down: DESTROY
             * (dropped the last ref), reset() (rotated it — connect_gen
             * bumped), or finish() (closed it — connected cleared). In
             * every case the cb was already delivered by cancel_pending;
             * drop the local send entry (already dequeued, so cancel_pending
             * never saw it) without dispatching it. Falling through on a
             * !connected struct would re-arm a stray query-timeout timer
             * and leave send_count stuck at 1. The `||` short-circuits
             * before reading self->connect_gen when self has been freed. */
            int destroyed = check_destroyed(self);
            if (destroyed || self->connect_gen != gen_before
                || !self->connected) {
                Safefree(send->data);
                CLEAR_INSERT(send);
                release_send(send);
                return destroyed ? 1 : 0;
            }
        }

        /* Clear per-query accumulated state so accessors don't return
         * the previous query's data. native_rows is already NULL at
         * EndOfStream; col_names/types are also cleared here so DDL
         * (or any query that emits no DATA block) does not leave the
         * previous SELECT's schema visible. */
        CLEAR_SV(self->native_col_names);
        CLEAR_SV(self->native_col_types);
        CLEAR_SV(self->native_totals);
        CLEAR_SV(self->native_extremes);
        self->last_error_code = 0;
        self->profile_rows = 0;
        self->profile_bytes = 0;
        self->profile_rows_before_limit = 0;
        if (self->progress_period > 0) {
            memset(self->progress_acc, 0, sizeof(self->progress_acc));
            self->progress_last = 0.0;
        }

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
        double qt = send->query_timeout;
        release_send(send);
        self->send_count++;

        /* Start query timeout timer */
        double timeout = qt > 0 ? qt : self->query_timeout;
        if (timeout > 0 && !self->timing) {
            ev_timer_set(&self->timer, (ev_tstamp)timeout, 0.0);
            ev_timer_start(self->loop, &self->timer);
            self->timing = 1;
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
