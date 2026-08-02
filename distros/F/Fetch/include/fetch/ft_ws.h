#ifndef FT_WS_H
#define FT_WS_H

/* WebSocket (RFC 6455) client, native in C to match the rest of Fetch: the
 * HTTP/1.1 Upgrade handshake is verified here (SHA-1 + base64, no external
 * lib), then the connection switches to WebSocket framing - masked text/binary
 * frames out, reassembled messages in, with ping/pong and close handled
 * automatically. Runs on the same non-blocking connection and loop as an
 * ordinary request; the upgrade Future resolves to a Fetch::WebSocket.
 *
 * Included from ft_http.h after ft_recv/ft_send and the ft_conn struct. */

#include <stdint.h>

/* --- SHA-1 (public-domain style, for Sec-WebSocket-Accept) ---------------- */

typedef struct { uint32_t h[5]; uint64_t nbits; unsigned char buf[64]; size_t n; } ft_sha1;

static void ft_sha1_block(ft_sha1 *s, const unsigned char *p) {
    uint32_t w[80], a, b, c, d, e, t;
    int i;
    for (i = 0; i < 16; i++)
        w[i] = (uint32_t)p[i*4] << 24 | (uint32_t)p[i*4+1] << 16 |
               (uint32_t)p[i*4+2] << 8 | (uint32_t)p[i*4+3];
    for (i = 16; i < 80; i++) {
        t = w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16];
        w[i] = (t << 1) | (t >> 31);
    }
    a = s->h[0]; b = s->h[1]; c = s->h[2]; d = s->h[3]; e = s->h[4];
    for (i = 0; i < 80; i++) {
        uint32_t f, k;
        if      (i < 20) { f = (b & c) | (~b & d);            k = 0x5A827999; }
        else if (i < 40) { f = b ^ c ^ d;                     k = 0x6ED9EBA1; }
        else if (i < 60) { f = (b & c) | (b & d) | (c & d);   k = 0x8F1BBCDC; }
        else             { f = b ^ c ^ d;                     k = 0xCA62C1D6; }
        t = ((a << 5) | (a >> 27)) + f + e + k + w[i];
        e = d; d = c; c = (b << 30) | (b >> 2); b = a; a = t;
    }
    s->h[0] += a; s->h[1] += b; s->h[2] += c; s->h[3] += d; s->h[4] += e;
}

static void ft_sha1_init(ft_sha1 *s) {
    s->h[0] = 0x67452301; s->h[1] = 0xEFCDAB89; s->h[2] = 0x98BADCFE;
    s->h[3] = 0x10325476; s->h[4] = 0xC3D2E1F0; s->nbits = 0; s->n = 0;
}

static void ft_sha1_update(ft_sha1 *s, const void *data, size_t len) {
    const unsigned char *p = (const unsigned char *)data;
    s->nbits += (uint64_t)len * 8;
    while (len) {
        size_t take = 64 - s->n;
        if (take > len) take = len;
        memcpy(s->buf + s->n, p, take);
        s->n += take; p += take; len -= take;
        if (s->n == 64) { ft_sha1_block(s, s->buf); s->n = 0; }
    }
}

static void ft_sha1_final(ft_sha1 *s, unsigned char out[20]) {
    int i;
    unsigned char pad = 0x80;
    uint64_t nbits = s->nbits;
    ft_sha1_update(s, &pad, 1);
    { unsigned char z = 0; while (s->n != 56) ft_sha1_update(s, &z, 1); }
    for (i = 7; i >= 0; i--) { unsigned char b = (unsigned char)(nbits >> (i*8)); ft_sha1_update(s, &b, 1); }
    for (i = 0; i < 5; i++) {
        out[i*4]   = (unsigned char)(s->h[i] >> 24);
        out[i*4+1] = (unsigned char)(s->h[i] >> 16);
        out[i*4+2] = (unsigned char)(s->h[i] >> 8);
        out[i*4+3] = (unsigned char)(s->h[i]);
    }
}

/* --- base64 encode -------------------------------------------------------- */

static const char ft_b64tab[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/* encode `len` bytes into `out` (must hold 4*ceil(len/3)+1); NUL-terminates */
static void ft_b64enc(const unsigned char *in, size_t len, char *out) {
    size_t i = 0, o = 0;
    while (i + 3 <= len) {
        uint32_t v = in[i] << 16 | in[i+1] << 8 | in[i+2];
        out[o++] = ft_b64tab[(v >> 18) & 63];
        out[o++] = ft_b64tab[(v >> 12) & 63];
        out[o++] = ft_b64tab[(v >> 6) & 63];
        out[o++] = ft_b64tab[v & 63];
        i += 3;
    }
    if (len - i == 1) {
        uint32_t v = in[i] << 16;
        out[o++] = ft_b64tab[(v >> 18) & 63];
        out[o++] = ft_b64tab[(v >> 12) & 63];
        out[o++] = '='; out[o++] = '=';
    } else if (len - i == 2) {
        uint32_t v = in[i] << 16 | in[i+1] << 8;
        out[o++] = ft_b64tab[(v >> 18) & 63];
        out[o++] = ft_b64tab[(v >> 12) & 63];
        out[o++] = ft_b64tab[(v >> 6) & 63];
        out[o++] = '=';
    }
    out[o] = '\0';
}

#define FT_WS_GUID "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

/* Sec-WebSocket-Accept for a given client key: base64(sha1(key . GUID)). */
static void ft_ws_accept(const char *key, char out[30]) {
    ft_sha1 s;
    unsigned char dg[20];
    ft_sha1_init(&s);
    ft_sha1_update(&s, key, strlen(key));
    ft_sha1_update(&s, FT_WS_GUID, sizeof(FT_WS_GUID) - 1);
    ft_sha1_final(&s, dg);
    ft_b64enc(dg, 20, out);
}

/* --- randomness (client key + frame masks; not crypto-critical) ---------- */

/* portable random bytes (defined per-platform in ft_win.h) */
#define ft_ws_random(out, n) ft_os_random((out), (n))

/* A fresh 16-byte client key, base64-encoded (24 chars) into out[25]. */
static void ft_ws_genkey(char out[25]) {
    unsigned char k[16];
    ft_ws_random(k, 16);
    ft_b64enc(k, 16, out);
}

/* --- outgoing frames ------------------------------------------------------ */

static void ft_ws_wbuf_need(ft_conn *c, size_t extra) {
    if (c->ws_wlen + extra > c->ws_wcap) {
        c->ws_wcap = (c->ws_wlen + extra) * 2 + 64;
        Renew(c->ws_wbuf, c->ws_wcap, char);
    }
}

/* Queue one masked frame (client -> server frames MUST be masked). */
static void ft_ws_queue(ft_conn *c, int opcode, const unsigned char *data, size_t len) {
    unsigned char hdr[14], mask[4];
    size_t hl = 0, i;
    hdr[hl++] = (unsigned char)(0x80 | (opcode & 0x0f));   /* FIN + opcode */
    if (len < 126) {
        hdr[hl++] = (unsigned char)(0x80 | len);
    } else if (len < 65536) {
        hdr[hl++] = 0x80 | 126;
        hdr[hl++] = (unsigned char)(len >> 8);
        hdr[hl++] = (unsigned char)(len);
    } else {
        int s;
        hdr[hl++] = 0x80 | 127;
        for (s = 56; s >= 0; s -= 8) hdr[hl++] = (unsigned char)((uint64_t)len >> s);
    }
    ft_ws_random(mask, 4);
    memcpy(hdr + hl, mask, 4); hl += 4;

    ft_ws_wbuf_need(c, hl + len);
    memcpy(c->ws_wbuf + c->ws_wlen, hdr, hl);
    c->ws_wlen += hl;
    for (i = 0; i < len; i++)
        c->ws_wbuf[c->ws_wlen + i] = (char)(data[i] ^ mask[i & 3]);
    c->ws_wlen += len;
}

/* Push whatever is queued through the socket; arm WRITE if it would block. */
static int ft_ws_flush(pTHX_ ft_conn *c) {
    while (c->ws_woff < c->ws_wlen) {
        int want = 0;
        ssize_t n = ft_send(c, c->ws_wbuf + c->ws_woff, c->ws_wlen - c->ws_woff, &want);
        if (n > 0) { c->ws_woff += (size_t)n; continue; }
        if (n < 0 && want) return 1;                 /* would block: keep buffer */
        if (n < 0 && errno == EINTR) continue;
        return -1;                                   /* fatal */
    }
    c->ws_woff = c->ws_wlen = 0;                      /* drained */
    return 0;
}

/* --- inbound dispatch to Perl -------------------------------------------- */

/* Deliver a complete application message: resolve a pending next_message
 * future, else call on_message, else buffer it in the inbox. */
static void ft_ws_deliver(pTHX_ ft_conn *c, int is_binary, const char *data, size_t len) {
    SV *msg = newSVpvn(data, len);
    if (is_binary) SvUTF8_off(msg); else sv_utf8_decode(msg);
    if (c->ws_waiter) {
        SV *w = c->ws_waiter; c->ws_waiter = NULL;
        hmf_settle(aTHX_ w, HMF_DONE, &msg, 1);
        SvREFCNT_dec(w);
    } else if (c->ws_on_message) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(sv_2mortal(SvREFCNT_inc(msg)));
        PUTBACK;
        call_sv(c->ws_on_message, G_DISCARD | G_EVAL);
        if (SvTRUE(ERRSV)) warn("Fetch: on_message callback died: %s", SvPV_nolen(ERRSV));
        FREETMPS; LEAVE;
    } else {
        if (!c->ws_inbox) c->ws_inbox = newAV();
        av_push(c->ws_inbox, SvREFCNT_inc(msg));
    }
    SvREFCNT_dec(msg);
}

/* Mark the socket closed and notify; the Fetch::WebSocket object frees the
 * conn on DESTROY, so we only release the fd here. */
static void ft_ws_shutdown(pTHX_ ft_conn *c, const char *why) {
    if (c->ws_closed) return;
    c->ws_closed = 1;
    if (c->armed) {
        if (c->loop_sv) ft_loop_arm(aTHX_ c, 0);
        else            ft_unwatch_io(aTHX_ c->loop, c->fd, c->armed);
        c->armed = 0;
    }
    if (c->fd >= 0) { close(c->fd); c->fd = -1; }
    if (c->ws_waiter) {
        SV *w = c->ws_waiter; c->ws_waiter = NULL;
        SV *e = sv_2mortal(newSVpvf("Fetch: websocket %s", why ? why : "closed"));
        hmf_settle(aTHX_ w, HMF_FAILED, &e, 1);
        SvREFCNT_dec(w);
    }
    if (c->ws_on_close) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
        call_sv(c->ws_on_close, G_DISCARD | G_EVAL);
        FREETMPS; LEAVE;
    }
}

/* Parse and act on as many complete frames as are buffered in rbuf. */
static void ft_ws_feed(pTHX_ ft_conn *c) {
    for (;;) {
        unsigned char *b = (unsigned char *)c->rbuf + c->ws_pos;
        size_t avail = c->rlen - c->ws_pos;
        int fin, opcode, masked;
        uint64_t len;
        size_t hl;
        if (avail < 2) break;
        fin    = b[0] & 0x80;
        opcode = b[0] & 0x0f;
        masked = b[1] & 0x80;
        len    = b[1] & 0x7f;
        hl     = 2;
        if (len == 126) { if (avail < 4) break; len = ((uint64_t)b[2] << 8) | b[3]; hl = 4; }
        else if (len == 127) {
            int i; if (avail < 10) break;
            len = 0; for (i = 0; i < 8; i++) len = (len << 8) | b[2 + i]; hl = 10;
        }
        if (masked) hl += 4;
        if (len > (uint64_t)64 * 1024 * 1024) { ft_ws_shutdown(aTHX_ c, "frame too large"); return; }
        if (avail < hl + len) break;                 /* need the whole frame */

        {
            unsigned char *payload = b + hl;
            if (masked) {
                unsigned char *mk = b + hl - 4;
                uint64_t i; for (i = 0; i < len; i++) payload[i] ^= mk[i & 3];
            }
            if (opcode == 0x8) {                     /* close */
                ft_ws_queue(c, 0x8, NULL, 0);        /* echo close */
                ft_ws_flush(aTHX_ c);
                c->ws_pos += hl + (size_t)len;
                ft_ws_shutdown(aTHX_ c, "closed by peer");
                return;
            } else if (opcode == 0x9) {              /* ping -> pong */
                ft_ws_queue(c, 0xA, payload, (size_t)len);
            } else if (opcode == 0xA) {              /* pong: ignore */
            } else {                                 /* 0x0/0x1/0x2 data */
                if (opcode != 0x0) c->ws_msg_opcode = opcode;
                if (c->ws_mlen + len > c->ws_mcap) {
                    c->ws_mcap = (c->ws_mlen + (size_t)len) * 2 + 64;
                    Renew(c->ws_msg, c->ws_mcap, char);
                }
                memcpy(c->ws_msg + c->ws_mlen, payload, (size_t)len);
                c->ws_mlen += (size_t)len;
                if (fin) {
                    ft_ws_deliver(aTHX_ c, c->ws_msg_opcode == 0x2, c->ws_msg, c->ws_mlen);
                    c->ws_mlen = 0;
                }
            }
        }
        c->ws_pos += hl + (size_t)len;
    }
    /* compact consumed bytes */
    if (c->ws_pos > 0) {
        memmove(c->rbuf, c->rbuf + c->ws_pos, c->rlen - c->ws_pos);
        c->rlen -= c->ws_pos;
        c->ws_pos = 0;
    }
}

/* Arm READ (always, for inbound frames) plus WRITE when output is pending. */
static void ft_ws_rearm(pTHX_ ft_conn *c) {
    int mask = HM_EV_READ;
    if (c->ws_woff < c->ws_wlen) mask |= HM_EV_WRITE;
    ft_arm(aTHX_ c, mask);
}

/* One readiness pass while in WebSocket mode. */
static void ft_ws_step(pTHX_ ft_conn *c) {
    int fr;
    if (c->ws_closed) return;
    fr = ft_ws_flush(aTHX_ c);
    if (fr < 0) { ft_ws_shutdown(aTHX_ c, "send failed"); return; }
    for (;;) {
        int want = 0; ssize_t n;
        if (c->rlen + 65536 > c->rcap) {
            c->rcap = c->rcap ? c->rcap * 2 : 65536;
            Renew(c->rbuf, c->rcap, char);
        }
        n = ft_recv(c, c->rbuf + c->rlen, c->rcap - c->rlen, &want);
        if (n > 0) { c->rlen += (size_t)n; ft_ws_feed(aTHX_ c); if (c->ws_closed) return; continue; }
        if (n == 0) { ft_ws_shutdown(aTHX_ c, "connection closed"); return; }
        if (want) break;
        if (errno == EINTR) continue;
        ft_ws_shutdown(aTHX_ c, strerror(errno));
        return;
    }
    ft_ws_rearm(aTHX_ c);
}

/* Public send helpers used from xs/websocket.xs. opcode: 1 text, 2 binary. */
static void ft_ws_send(pTHX_ ft_conn *c, int opcode, const char *data, size_t len) {
    if (c->ws_closed) return;
    ft_ws_queue(c, opcode, (const unsigned char *)data, len);
    if (ft_ws_flush(aTHX_ c) < 0) { ft_ws_shutdown(aTHX_ c, "send failed"); return; }
    ft_ws_rearm(aTHX_ c);
}

static void ft_ws_close(pTHX_ ft_conn *c) {
    if (c->ws_closed) return;
    ft_ws_queue(c, 0x8, NULL, 0);
    ft_ws_flush(aTHX_ c);
    ft_ws_shutdown(aTHX_ c, "closed locally");
}

#endif /* FT_WS_H */
