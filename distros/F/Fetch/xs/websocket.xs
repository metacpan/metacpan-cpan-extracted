MODULE = Fetch		PACKAGE = Fetch

# $ua->websocket($url, %opt) -> Fetch::Future resolving to a Fetch::WebSocket.
# The Upgrade handshake runs on the same non-blocking connection/loop as any
# request; on a verified 101 the Future yields the live socket.
SV *
websocket(self, url, ...)
    SV         *self
    const char *url
    CODE:
    {
        HV *opt = newHV();
        int i;
        for (i = 2; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(opt, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        RETVAL = ft_websocket(aTHX_ ft_ua_of(aTHX_ self), url, opt);
        SvREFCNT_dec((SV *)opt);
    }
    OUTPUT:
        RETVAL

MODULE = Fetch		PACKAGE = Fetch::WebSocket

# Send a text message (opcode 0x1); the payload is encoded as UTF-8.
void
send(self, data)
    SV *self
    SV *data
    CODE:
    {
        ft_conn *c = ft_ws_of(aTHX_ self);
        STRLEN len;
        const char *d = SvPVutf8(data, len);
        ft_ws_send(aTHX_ c, 0x1, d, len);
    }

# Send a binary message (opcode 0x2) - raw bytes, no encoding.
void
send_binary(self, data)
    SV *self
    SV *data
    CODE:
    {
        ft_conn *c = ft_ws_of(aTHX_ self);
        STRLEN len;
        const char *d = SvPVbyte(data, len);
        ft_ws_send(aTHX_ c, 0x2, d, len);
    }

# A Future resolving to the next inbound message (text decoded, binary raw).
SV *
next_message(self)
    SV *self
    CODE:
    {
        ft_conn *c = ft_ws_of(aTHX_ self);
        RETVAL = hmf_new(aTHX_ "Fetch::Future");
        if (c->ws_inbox && av_len(c->ws_inbox) >= 0) {
            SV *msg = av_shift(c->ws_inbox);            /* buffered already */
            hmf_settle(aTHX_ RETVAL, HMF_DONE, &msg, 1);
            SvREFCNT_dec(msg);
        } else if (c->ws_closed) {
            SV *e = sv_2mortal(newSVpvs("Fetch: websocket closed"));
            hmf_settle(aTHX_ RETVAL, HMF_FAILED, &e, 1);
        } else {
            if (c->ws_waiter) SvREFCNT_dec(c->ws_waiter);
            c->ws_waiter = SvREFCNT_inc(RETVAL);        /* resolved on arrival */
        }
    }
    OUTPUT:
        RETVAL

# Install a persistent callback for each inbound message; any already buffered
# are delivered immediately.
void
on_message(self, cb)
    SV *self
    SV *cb
    CODE:
    {
        ft_conn *c = ft_ws_of(aTHX_ self);
        if (c->ws_on_message) SvREFCNT_dec(c->ws_on_message);
        c->ws_on_message = SvREFCNT_inc(cb);
        if (c->ws_inbox) {
            while (av_len(c->ws_inbox) >= 0) {
                SV *msg = av_shift(c->ws_inbox);
                dSP;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(sv_2mortal(msg));
                PUTBACK;
                call_sv(cb, G_DISCARD | G_EVAL);
                FREETMPS; LEAVE;
            }
        }
    }

# Install a callback fired once when the socket closes.
void
on_close(self, cb)
    SV *self
    SV *cb
    CODE:
    {
        ft_conn *c = ft_ws_of(aTHX_ self);
        if (c->ws_on_close) SvREFCNT_dec(c->ws_on_close);
        c->ws_on_close = SvREFCNT_inc(cb);
    }

# True once the socket has closed.
int
is_closed(self)
    SV *self
    CODE:
        RETVAL = ft_ws_of(aTHX_ self)->ws_closed;
    OUTPUT:
        RETVAL

# Send a close frame and shut the socket down.
void
close(self)
    SV *self
    CODE:
        ft_ws_close(aTHX_ ft_ws_of(aTHX_ self));

void
DESTROY(self)
    SV *self
    CODE:
    {
        ft_conn *c = ft_ws_of(aTHX_ self);
        if (c) ft_conn_free(aTHX_ c);
    }
