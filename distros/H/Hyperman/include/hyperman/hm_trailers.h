#ifndef HM_TRAILERS_H
#define HM_TRAILERS_H

/* Trailer fields: header-shaped fields that follow a body.
 *
 * The response array stays a triple. A fourth element would not survive the
 * middleware that rebuilds [status, headers, body], so trailers travel only
 * through the two calls that end a body explicitly: Hyperman::Writer->close
 * and the ABI's stream_close_trailers. Both hand their list to
 * hm_trailers_build below, which is the one place the rules live.
 *
 * gRPC is the consumer. Its call status is a trailer and nothing else, since
 * the HTTP status of a gRPC reply is 200 whatever happened to the call.
 *
 * A list is judged whole, before a byte is sent:
 *
 *   refused, with a message and the body left open: not an array reference,
 *   an odd length, an empty or undefined name, a name with a character
 *   outside the RFC 9110 token set (which excludes the ':' of an h2
 *   pseudo-header), an undefined value, a control character other than tab
 *   in a value. On HTTP/1.1 a trailer is written raw after the last chunk,
 *   so CR or LF in one would split the response.
 *
 *   dropped quietly, as the same names already are from a header list:
 *   connection-level fields, which HTTP/2 forbids outright, and the framing
 *   and routing fields a receiver must never learn from a trailer. A proxy
 *   that merged a trailing content-length into the header block would frame
 *   the next message by it.
 *
 *   rewritten: names lowercased for HTTP/2, values trimmed of surrounding
 *   blanks since every parser discards them anyway. */

/* RFC 9110 tchar: ALPHA, DIGIT and the fifteen punctuation marks. */
static int hm_tchar_ok(unsigned char ch) {
    if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
        || (ch >= '0' && ch <= '9'))
        return 1;
    switch (ch) {
        case '!': case '#': case '$': case '%': case '&': case '\'':
        case '*': case '+': case '-': case '.': case '^': case '_':
        case '`': case '|': case '~':
            return 1;
        default:
            return 0;
    }
}

/* The names a trailer section never carries, matched in any case. */
static int hm_trailer_banned(const char *n, STRLEN l) {
    switch (l) {
        case 2:  return hm_strncasecmp(n, "te", 2) == 0;
        case 4:  return hm_strncasecmp(n, "host", 4) == 0;
        case 7:  return hm_strncasecmp(n, "upgrade", 7) == 0
                     || hm_strncasecmp(n, "trailer", 7) == 0;
        case 10: return hm_strncasecmp(n, "connection", 10) == 0
                     || hm_strncasecmp(n, "keep-alive", 10) == 0;
        case 14: return hm_strncasecmp(n, "content-length", 14) == 0;
        case 16: return hm_strncasecmp(n, "proxy-connection", 16) == 0;
        case 17: return hm_strncasecmp(n, "transfer-encoding", 17) == 0;
        default: return 0;
    }
}

/* A refusal: the partial list goes, the message becomes the caller's
 * mortal, and NULL is the result. */
static AV *hm_trailers_refuse(pTHX_ AV *partial, SV **err, SV *msg) {
    if (partial) SvREFCNT_dec((SV *)partial);
    *err = sv_2mortal(msg);
    return NULL;
}

/* Check a trailer list and build the one that goes to the wire.
 *
 * `given` is whatever the application passed. The result is a new AV the
 * caller owns, holding lowercased names and trimmed values in order, or
 * NULL. NULL with *err clear means there is nothing to send: no list, an
 * empty one, or one made only of banned names, and the body then ends as a
 * plain close ends it. NULL with *err set is a refusal, *err being a mortal
 * SV that says what was wrong. */
static AV *hm_trailers_build(pTHX_ SV *given, SV **err) {
    AV *in, *out;
    SSize_t i, n;
    *err = NULL;
    if (!given || !SvOK(given)) return NULL;
    if (!SvROK(given) || SvTYPE(SvRV(given)) != SVt_PVAV)
        return hm_trailers_refuse(aTHX_ NULL, err, newSVpvs(
            "trailers must be an array reference of name => value pairs"));
    in = (AV *)SvRV(given);
    n = av_len(in) + 1;
    if (n & 1)
        return hm_trailers_refuse(aTHX_ NULL, err, newSVpvs(
            "trailers must be name => value pairs (an odd number of "
            "elements was given)"));
    out = newAV();
    for (i = 0; i < n; i += 2) {
        SV **k = av_fetch(in, i, 0);
        SV **v = av_fetch(in, i + 1, 0);
        STRLEN kl, vl, j, from, to;
        const char *ks, *vs;
        SV *name;
        char *lc;
        if (!(k && *k && SvOK(*k)) || !(ks = SvPV(*k, kl), kl))
            return hm_trailers_refuse(aTHX_ out, err,
                                      newSVpvs("a trailer name is empty"));
        for (j = 0; j < kl; j++)
            if (!hm_tchar_ok((unsigned char)ks[j]))
                return hm_trailers_refuse(aTHX_ out, err, newSVpvf(
                    "trailer name '%" SVf "' is not a valid field name",
                    SVfARG(*k)));
        if (!(v && *v && SvOK(*v)))
            return hm_trailers_refuse(aTHX_ out, err, newSVpvf(
                "trailer '%" SVf "' has an undefined value", SVfARG(*k)));
        vs = SvPV(*v, vl);
        from = 0;
        to = vl;
        while (from < to && (vs[from] == ' ' || vs[from] == '\t')) from++;
        while (to > from && (vs[to - 1] == ' ' || vs[to - 1] == '\t')) to--;
        for (j = from; j < to; j++) {
            unsigned char ch = (unsigned char)vs[j];
            if ((ch < 0x20 && ch != '\t') || ch == 0x7f)
                return hm_trailers_refuse(aTHX_ out, err, newSVpvf(
                    "trailer '%" SVf "' has a control character in its value "
                    "(CR, LF and NUL would split the response)",
                    SVfARG(*k)));
        }
        if (hm_trailer_banned(ks, kl)) continue;
        name = newSVpvn(ks, kl);
        lc = SvPVX(name);
        for (j = 0; j < kl; j++)
            if (lc[j] >= 'A' && lc[j] <= 'Z') lc[j] = (char)(lc[j] + 32);
        av_push(out, name);
        av_push(out, newSVpvn(vs + from, to - from));
    }
    if (av_len(out) < 0) {
        SvREFCNT_dec((SV *)out);
        return NULL;
    }
    return out;
}

#endif /* HM_TRAILERS_H */
