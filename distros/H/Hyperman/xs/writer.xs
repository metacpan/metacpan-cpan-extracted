MODULE = Hyperman		PACKAGE = Hyperman::Writer

# The psgi.streaming writer, handed out by the responder: ->write($chunk),
# ->close. EOF-delimited (Connection: close), so close ends stream+socket.

# Payload is [fd, id] for HTTP/1.1, or [fd, gen, stream_id, "h2"] for HTTP/2.
void
write(self, data)
    SV *self
    SV *data
    CODE:
    {
        AV *w = (AV *)SvRV(self);
        if (av_len(w) >= 3) {           /* h2 form */
            SV **f = av_fetch(w, 0, 0);
            SV **g = av_fetch(w, 1, 0);
            SV **s = av_fetch(w, 2, 0);
            if (f && g && s)
                hm_h2_writer_write(aTHX_ (int)SvIV(*f), SvUV(*g),
                                   (int32_t)SvIV(*s), data);
        } else {
            SV **f = av_fetch(w, 0, 0);
            SV **i = av_fetch(w, 1, 0);
            if (f && i)
                hm_stream_write(aTHX_ (int)SvIV(*f), SvUV(*i), data);
        }
    }

void
close(self)
    SV *self
    CODE:
    {
        AV *w = (AV *)SvRV(self);
        if (av_len(w) >= 3) {           /* h2 form */
            SV **f = av_fetch(w, 0, 0);
            SV **g = av_fetch(w, 1, 0);
            SV **s = av_fetch(w, 2, 0);
            if (f && g && s)
                hm_h2_writer_close(aTHX_ (int)SvIV(*f), SvUV(*g),
                                   (int32_t)SvIV(*s));
        } else {
            SV **f = av_fetch(w, 0, 0);
            SV **i = av_fetch(w, 1, 0);
            if (f && i)
                hm_stream_close(aTHX_ (int)SvIV(*f), SvUV(*i));
        }
    }
