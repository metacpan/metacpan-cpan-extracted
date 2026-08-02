#ifndef FT_JSON_H
#define FT_JSON_H

/* JSON for the `json =>` request option (encode) and Fetch::Response->json
 * (decode). Uses Cpanel::JSON::XS when installed, falling back to core
 * JSON::PP; a single ->utf8 codec is built lazily and reused. Booleans follow
 * JSON::PP semantics - true/false <-> JSON::PP::Boolean (\1 / \0), null <->
 * undef - which Cpanel::JSON::XS is compatible with, so values round-trip. */

/* the shared codec (a Cpanel::JSON::XS or JSON::PP object, ->utf8) */
static SV *ft_json_codec(pTHX) {
    static SV *codec = NULL;
    SV *c;
    if (codec) return codec;
    c = eval_pv("require Cpanel::JSON::XS; "
                "Cpanel::JSON::XS->new->utf8->allow_nonref->canonical", 0);
    if (!c || !SvROK(c))
        c = eval_pv("require JSON::PP; "
                    "JSON::PP->new->utf8->allow_nonref->canonical", 0);
    if (!c || !SvROK(c))
        croak("Fetch: JSON needs Cpanel::JSON::XS or JSON::PP installed");
    codec = newSVsv(c);
    return codec;
}

/* $data -> JSON bytes (UTF-8). Dies (with the codec's message) on error. */
static SV *ft_json_encode(pTHX_ SV *data) {
    dSP;
    SV *codec = ft_json_codec(aTHX);
    SV *out;
    int n;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(codec);
    PUSHs(data);
    PUTBACK;
    n = call_method("encode", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *err = sv_2mortal(newSVsv(ERRSV));
        if (n) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        croak_sv(err);
    }
    out = n ? newSVsv(POPs) : newSV(0);
    PUTBACK; FREETMPS; LEAVE;
    return out;
}

/* JSON bytes -> Perl data. Dies (with the codec's message) on malformed JSON. */
static SV *ft_json_decode(pTHX_ SV *bytes) {
    dSP;
    SV *codec = ft_json_codec(aTHX);
    SV *out;
    int n;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(codec);
    PUSHs(bytes);
    PUTBACK;
    n = call_method("decode", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *err = sv_2mortal(newSVsv(ERRSV));
        if (n) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        croak_sv(err);
    }
    out = n ? newSVsv(POPs) : newSV(0);
    PUTBACK; FREETMPS; LEAVE;
    return out;
}

#endif /* FT_JSON_H */
