MODULE = Hyperman		PACKAGE = Hyperman::Writer

# The psgi.streaming writer, handed out by the responder: ->write($chunk),
# ->close.
#
# Payload shapes, discriminated on length because a writer is a blessed AV
# and not three classes:
#
#   [fd, id]                        HTTP/1.1, EOF-delimited (Connection: close)
#   [fd, gen, stream_id, "h2"]      HTTP/2, buffered until close
#   [udp_fd, qid, stream_id, "h3"]  HTTP/3, the same shape over QUIC
#   [handle, serial, "stream"]      an ABI v6 stream handle (hm_stream.h),
#                                   the transport-neutral one: the same three
#                                   calls write a body over HTTP/1.1 or over
#                                   an h2 stream, and the branch is inside
#                                   the handle rather than out here.
#
# The four-element forms are told apart by the TAG at index 3, not by length.
# Length was enough while h2 was the only one; h3 has the same arity, so a
# length test would route every h3 writer into hm_h2_writer_write and write
# an HTTP/3 body into an nghttp2 session. Existing h2 writers already carry
# their tag, so keying on it changes no behaviour.
#
# The serial is carried for diagnostics only. What proves a handle is live is
# the registry, which every entry point consults before dereferencing it, so
# ->write after the connection died is a return value and not a crash.

void
write(self, data)
    SV *self
    SV *data
    CODE:
    {
        AV *w = (AV *)SvRV(self);
        SSize_t n = av_len(w);
        if (n == 2) {                   /* stream-handle form */
            SV **h = av_fetch(w, 0, 0);
            STRLEN l;
            const char *p = SvPV(data, l);
            if (h)
                hm_stream_write_h(aTHX_ INT2PTR(void *, SvIV(*h)), p, l);
        } else if (n >= 3) {            /* h2 or h3: told apart by the tag */
            SV **f = av_fetch(w, 0, 0);
            SV **g = av_fetch(w, 1, 0);
            SV **s = av_fetch(w, 2, 0);
            if (f && g && s) {
                if (hm_writer_tag_is(aTHX_ w, "h3", 2))
                    hm_h3_writer_write(aTHX_ (int)SvIV(*f), SvUV(*g),
                                       (int64_t)SvIV(*s), data);
                else
                    hm_h2_writer_write(aTHX_ (int)SvIV(*f), SvUV(*g),
                                       (int32_t)SvIV(*s), data);
            }
        } else {
            SV **f = av_fetch(w, 0, 0);
            SV **i = av_fetch(w, 1, 0);
            if (f && i)
                hm_stream_write(aTHX_ (int)SvIV(*f), SvUV(*i), data);
        }
    }

# Only the stream-handle form owns anything C-side. The other two shapes are
# a pair of integers naming a connection the server owns, so this is a no-op
# for them - and a writer dropped without ->close still ends its body, which
# is the same promise a lexical filehandle makes.
void
DESTROY(self)
    SV *self
    CODE:
    {
        AV *w = (AV *)SvRV(self);
        if (av_len(w) == 2) {
            SV **h = av_fetch(w, 0, 0);
            if (h && SvIV(*h)) {
                hm_stream_close_h(aTHX_ INT2PTR(void *, SvIV(*h)));
                sv_setiv(*h, 0);
            }
        }
    }

void
close(self)
    SV *self
    CODE:
    {
        AV *w = (AV *)SvRV(self);
        SSize_t n = av_len(w);
        if (n == 2) {                   /* stream-handle form */
            SV **h = av_fetch(w, 0, 0);
            if (h && SvIV(*h)) {
                hm_stream_close_h(aTHX_ INT2PTR(void *, SvIV(*h)));
                /* the handle is freed; blank the slot so a second ->close
                 * cannot hand the registry a stale pointer to compare */
                sv_setiv(*h, 0);
            }
        } else if (n >= 3) {            /* h2 or h3: told apart by the tag */
            SV **f = av_fetch(w, 0, 0);
            SV **g = av_fetch(w, 1, 0);
            SV **s = av_fetch(w, 2, 0);
            if (f && g && s) {
                if (hm_writer_tag_is(aTHX_ w, "h3", 2))
                    hm_h3_writer_close(aTHX_ (int)SvIV(*f), SvUV(*g),
                                       (int64_t)SvIV(*s));
                else
                    hm_h2_writer_close(aTHX_ (int)SvIV(*f), SvUV(*g),
                                       (int32_t)SvIV(*s));
            }
        } else {
            SV **f = av_fetch(w, 0, 0);
            SV **i = av_fetch(w, 1, 0);
            if (f && i)
                hm_stream_close(aTHX_ (int)SvIV(*f), SvUV(*i));
        }
    }

# The other ending, for a producer that failed part way through a body. Only
# the stream-handle form has one: the older two shapes have no verb for it,
# and inventing a graceful close here would be exactly the lie this exists to
# avoid, so they are left alone and the caller is told nothing happened.
IV
abort(self)
    SV *self
    CODE:
    {
        AV *w = (AV *)SvRV(self);
        RETVAL = HM_ABI_STREAM_STALE;
        if (av_len(w) == 2) {
            SV **h = av_fetch(w, 0, 0);
            if (h && SvIV(*h)) {
                RETVAL = hm_stream_abort_h(aTHX_ INT2PTR(void *, SvIV(*h)));
                sv_setiv(*h, 0);        /* freed; a later ->close is a no-op */
            }
        }
    }
    OUTPUT:
        RETVAL
