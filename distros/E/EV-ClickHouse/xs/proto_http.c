/* --- HTTP request building --- */

/* Tiny base64 encoder (RFC 4648). Writes ((src_len + 2) / 3) * 4 bytes plus
 * a NUL into dst (caller-allocated). Used only for HTTP basic auth. */
static size_t base64_encode(const unsigned char *src, size_t src_len, char *dst) {
    static const char ALPHA[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    size_t i, o = 0;
    for (i = 0; i + 3 <= src_len; i += 3) {
        dst[o++] = ALPHA[ src[i]   >> 2];
        dst[o++] = ALPHA[((src[i]   & 0x03) << 4) | (src[i+1] >> 4)];
        dst[o++] = ALPHA[((src[i+1] & 0x0f) << 2) | (src[i+2] >> 6)];
        dst[o++] = ALPHA[  src[i+2] & 0x3f];
    }
    if (i < src_len) {
        dst[o++] = ALPHA[src[i] >> 2];
        if (i + 1 == src_len) {
            dst[o++] = ALPHA[(src[i] & 0x03) << 4];
            dst[o++] = '=';
        } else {
            dst[o++] = ALPHA[((src[i]   & 0x03) << 4) | (src[i+1] >> 4)];
            dst[o++] = ALPHA[ (src[i+1] & 0x0f) << 2];
        }
        dst[o++] = '=';
    }
    dst[o] = '\0';
    return o;
}

/*
 * Build HTTP POST request. Used for both SELECT (sql in body, url_sql=NULL)
 * and INSERT (url_sql="INSERT ... FORMAT TabSeparated" in URL, data in body).
 * Returns malloc'd buffer with full request.
 */
static char* build_http_post_request(ev_clickhouse_t *self,
                                       const char *url_sql, size_t url_sql_len,
                                       const char *body_data, size_t body_data_len,
                                       HV *defaults, HV *overrides,
                                       size_t *req_len) {
    char *req;
    size_t req_cap;
    size_t pos = 0;
    char *body = NULL;
    size_t body_len = body_data_len;
    const char *content_encoding = NULL;

    /* compress body if requested */
    if (self->compress && body_data_len > 0) {
        size_t gz_len;
        body = gzip_compress(body_data, body_data_len, &gz_len);
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
        + url_sql_len * 3
        + settings_url_params_size(defaults, overrides);
    char *params;
    size_t plen = 0;
    Newx(params, params_cap, char);
    if (self->database) {
        plen = (size_t)snprintf(params, params_cap, "?database=");
        plen += url_encode(self->database, strlen(self->database), params + plen);
        plen += (size_t)snprintf(params + plen, params_cap - plen, "&wait_end_of_query=1");
    } else {
        plen = (size_t)snprintf(params, params_cap, "?wait_end_of_query=1");
    }
    if (self->session_id) {
        plen += (size_t)snprintf(params + plen, params_cap - plen, "&session_id=");
        plen += url_encode(self->session_id, strlen(self->session_id), params + plen);
    }
    if (url_sql) {
        plen += (size_t)snprintf(params + plen, params_cap - plen, "&query=");
        plen += url_encode(url_sql, url_sql_len, params + plen);
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

    /* user/password are quoted as-is in the X-ClickHouse-* form, or
     * base64-expanded ((n+2)/3)*4 in the Basic auth form. The 4/3 factor
     * is enough either way. */
    req_cap = 512 + body_len + plen
           + (self->host ? strlen(self->host) : 0)
           + (self->user ? strlen(self->user) * 2 : 0)
           + (self->password ? strlen(self->password) * 2 : 0);
    Newx(req, req_cap, char);

    /* request line + headers */
    pos += snprintf(req + pos, req_cap - pos,
                    "POST /%s HTTP/1.1\r\n", params);
    Safefree(params);
    pos += snprintf(req + pos, req_cap - pos,
                    "Host: %s:%u\r\n", self->host, self->port);
    if (self->http_basic_auth && self->user) {
        /* "user:pass" → base64. Single allocation: [cred][b64]. */
        size_t ul = strlen(self->user);
        size_t pl = self->password ? strlen(self->password) : 0;
        size_t cred_len = ul + 1 + pl;
        size_t b64_cap = ((cred_len + 2) / 3) * 4 + 1;
        char *buf;
        Newx(buf, cred_len + b64_cap, char);
        memcpy(buf, self->user, ul);
        buf[ul] = ':';
        if (pl) memcpy(buf + ul + 1, self->password, pl);
        base64_encode((const unsigned char *)buf, cred_len, buf + cred_len);
        pos += snprintf(req + pos, req_cap - pos,
                        "Authorization: Basic %s\r\n", buf + cred_len);
        Safefree(buf);
    } else {
        if (self->user)
            pos += snprintf(req + pos, req_cap - pos,
                            "X-ClickHouse-User: %s\r\n", self->user);
        if (self->password && self->password[0])
            pos += snprintf(req + pos, req_cap - pos,
                            "X-ClickHouse-Key: %s\r\n", self->password);
    }
    pos += snprintf(req + pos, req_cap - pos, "Connection: keep-alive\r\n");
    if (self->compress)
        pos += snprintf(req + pos, req_cap - pos, "Accept-Encoding: gzip\r\n");
    if (content_encoding)
        pos += snprintf(req + pos, req_cap - pos, "%s", content_encoding);
    pos += snprintf(req + pos, req_cap - pos,
                    "Content-Length: %lu\r\n\r\n", (unsigned long)body_len);

    /* body */
    if (body_len > 0) {
        if (pos + body_len > req_cap) {
            req_cap = pos + body_len + 1;
            Renew(req, req_cap, char);
        }
        Copy(body ? body : body_data, req + pos, body_len, char);
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

/* Length-bounded uint parser. Stops at the first non-digit OR at `len`,
 * whichever comes first. Used to parse X-ClickHouse-Summary values out
 * of a non-NUL-terminated header buffer without letting strtoull scan
 * into bytes past the header on malformed input. */
static uint64_t parse_uint_within(const char *p, size_t len) {
    uint64_t n = 0;
    size_t i;
    for (i = 0; i < len; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c < '0' || c > '9') break;
        n = n * 10 + (c - '0');
    }
    return n;
}

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

/* Format an HTTP error response into a Newx-allocated "HTTP NNN: ..." message
 * and update self->last_error_code. Body may be gzip-compressed. Caller must
 * Safefree the returned pointer. */
static char* format_http_error(ev_clickhouse_t *self, int status,
                                const char *body, size_t body_len, int is_gzip) {
    char *errmsg;
    char *err_body = (char *)body;
    size_t err_len = body_len;
    if (is_gzip && body_len > 0) {
        size_t dec_len;
        char *dec = gzip_decompress(body, body_len, &dec_len);
        if (dec) { err_body = dec; err_len = dec_len; }
    }
    while (err_len > 0 && (err_body[err_len-1] == '\n' || err_body[err_len-1] == '\r'))
        err_len--;
    self->last_error_code = parse_ch_error_code(err_body, err_len);
    Newx(errmsg, err_len + 64, char);
    snprintf(errmsg, err_len + 64, "HTTP %d: %.*s",
             status, (int)err_len, err_body);
    if (err_body != body) Safefree(err_body);
    return errmsg;
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

    /* parse X-ClickHouse-Summary: {"read_rows":"N","read_bytes":"N",...}
     * to populate profile_rows/profile_bytes for HTTP, mirroring the
     * native protocol's SERVER_PROFILE_INFO packet. */
    val = find_header(self->recv_buf, hdr_end, "X-ClickHouse-Summary", &val_len);
    if (val && val_len > 12) {
        size_t i;
        for (i = 0; i + 12 < val_len; i++) {
            if (val[i] != '"') continue;
            /* val isn't NUL-terminated (it points into recv_buf), so use
             * parse_uint_within which takes an explicit length cap rather
             * than scanning until a non-digit/NUL like strtoull would. */
            if (i + 13 < val_len
                && memcmp(val + i + 1, "read_rows\":\"", 12) == 0)
                self->profile_rows = parse_uint_within(val + i + 13,
                                                       val_len - (i + 13));
            else if (i + 14 < val_len
                     && memcmp(val + i + 1, "read_bytes\":\"", 13) == 0)
                self->profile_bytes = parse_uint_within(val + i + 14,
                                                        val_len - (i + 14));
        }
    }

    size_t consumed;
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
                 * corrupt the stream for subsequent requests.
                 * Apply both the hard ceiling and the user's
                 * opt-in max_recv_buffer (when set) to the
                 * post-decode body size. */
                size_t cap = CH_MAX_DECOMPRESS_SIZE;
                if (self->max_recv_buffer > 0
                    && self->max_recv_buffer < cap)
                    cap = self->max_recv_buffer;
                if (decoded_len + chunk_size < decoded_len
                    || decoded_len + chunk_size > cap) {
                    if (decoded) Safefree(decoded);
                    self->send_count--;
                    teardown_after_deliver(self,
                        "chunked response too large", "connection closed");
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
        consumed = cp - self->recv_buf;
    } else {
        /* Content-Length based */
        if (self->recv_len < hdr_end + content_length) return; /* need more data */
        body = self->recv_buf + hdr_end;
        body_len = content_length;
        consumed = hdr_end + content_length;
    }

    /* deliver response (body, body_len, consumed are set; decoded may be NULL) */
    self->send_count--;
    if (status == 200) {
        char *final_body = (char *)body;
        size_t final_len = body_len;

        if (is_gzip && body_len > 0) {
            size_t dec_len;
            char *dec = gzip_decompress(body, body_len, &dec_len);
            if (!dec) {
                if (decoded) Safefree(decoded);
                recv_consume(self, consumed);
                int destroyed = deliver_error(self, "gzip decompression failed");
                if (destroyed) return;
                goto done;
            }
            /* Apply user's opt-in max_recv_buffer to the gzip-decoded
             * body too — same trip-wire semantics as the chunked path
             * and the on_readable raw-recv check. Tear the connection
             * down on overflow so subsequent queries can't slip past
             * the cap on the same socket (matches the chunked path's
             * behaviour and the POD contract). */
            if (self->max_recv_buffer > 0
                && dec_len > self->max_recv_buffer) {
                Safefree(dec);
                if (decoded) Safefree(decoded);
                teardown_after_deliver(self,
                    "gzip body exceeds max_recv_buffer", "connection closed");
                return;
            }
            final_body = dec;
            final_len = dec_len;
        }

        {
            int is_raw = peek_cb_raw(self);
            int destroyed;
            if (is_raw) {
                /* raw mode — deliver body as scalar, skip TSV parsing */
                destroyed = deliver_raw_body(self, final_body, final_len);
            } else {
                AV *rows = NULL;
                if (final_len > 0)
                    rows = parse_tab_separated(final_body, final_len);
                destroyed = deliver_rows(self, rows);
            }
            if (final_body != body) Safefree(final_body);
            if (decoded) Safefree(decoded);
            recv_consume(self, consumed);
            if (destroyed) return;
        }
    } else {
        /* error */
        char *errmsg = format_http_error(self, status, body, body_len, is_gzip);
        if (decoded) Safefree(decoded);
        recv_consume(self, consumed);
        int destroyed = deliver_error(self, errmsg);
        Safefree(errmsg);
        if (destroyed) return;
    }

    if (self->magic != EV_CH_MAGIC) return;

done:
    /* Stop query timeout timer on response */
    stop_timing(self);
    pipeline_advance(self);
    return;

need_more:
    /* incomplete response — keep reading */
    if (decoded) Safefree(decoded);
    return;
}

