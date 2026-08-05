#ifndef JSF_FETCH_H
#define JSF_FETCH_H

/* Default remote-document resolution through Fetch's C ABI (fetch_abi.h). When a
 * $ref/$dynamicRef names an http(s) document and the caller passed no resolver,
 * we GET it via the ABI and decode the body as JSON. Fetch is loaded and its ABI
 * resolved LAZILY on first use - a schema with only local references never loads
 * Fetch, and a missing Fetch simply means "no auto-fetch" (the ref then fails to
 * resolve like any other). Needs the Perl API (perl.h, included by the .xs). */

#include "fetch_abi.h"   /* via ExtUtils::Depends; runtime version-checked below */

static const fetch_abi *JSF_FETCH = NULL;   /* resolved on first fetch */
static int              JSF_FETCH_TRIED = 0;
static SV              *JSF_FETCH_UA = NULL; /* process-lifetime UA */

/* Resolve Fetch's ABI table once; 1 if available. */
static int jsf_fetch_init(pTHX) {
    dSP; int count; IV p = 0;
    if (JSF_FETCH) return 1;
    if (JSF_FETCH_TRIED) return 0;
    JSF_FETCH_TRIED = 1;

    eval_pv("require Fetch;", FALSE);           /* trap a missing Fetch */
    if (SvTRUE(ERRSV)) return 0;

    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    count = call_pv("Fetch::_abi_ptr", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) p = POPi;
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;

    if (p) {
        const fetch_abi *a = INT2PTR(const fetch_abi *, p);
        if (a && a->abi_version == FETCH_ABI_VERSION) JSF_FETCH = a;
    }
    return JSF_FETCH != NULL;
}

/* the request settles here: hand back the body on a 2xx, else undef */
static SV *jsf_fetch_map(pTHX_ int ok, int status, AV *headers, SV *body, SV *err, void *ud) {
    PERL_UNUSED_ARG(headers); PERL_UNUSED_ARG(err); PERL_UNUSED_ARG(ud);
    if (ok && status >= 200 && status < 300 && body && SvOK(body)) return newSVsv(body);
    return newSV(0);
}

/* A fetched remote document that is not valid JSON must fail the $ref
 * gracefully (return NULL), not croak. The ABI decode croaks on bad input and
 * cannot be trapped portably from C here, so this cold path keeps decoding
 * through File::Raw::JSON under G_EVAL; the hot schema-text path uses the ABI
 * directly (jsf_json_decode). */
static SV *jsf_fetch_decode(pTHX_ SV *text) {
    dSP; int count; SV *ret = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 1); PUSHs(text); PUTBACK;
    count = call_pv("File::Raw::JSON::file_json_decode", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) { SV *r = POPs; if (SvROK(r)) ret = newSVsv(r); }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return ret ? sv_2mortal(ret) : NULL;
}

/* GET an http(s) URI via the ABI and decode the body; mortal ref, or NULL. */
static SV *jsf_fetch_uri(pTHX_ const char *uri, STRLEN ulen) {
    SV *f, *body = NULL, *url;
    if (!((ulen >= 7 && strnEQ(uri, "http://", 7)) ||
          (ulen >= 8 && strnEQ(uri, "https://", 8)))) return NULL;
    if (!jsf_fetch_init(aTHX)) return NULL;
    if (!JSF_FETCH_UA) JSF_FETCH_UA = JSF_FETCH->ua_new(aTHX_ NULL, 0);
    if (!JSF_FETCH_UA) return NULL;

    url = sv_2mortal(newSVpvn(uri, ulen));   /* NUL-terminated by newSVpvn */
    f = JSF_FETCH->request(aTHX_ JSF_FETCH_UA, "GET", SvPVX(url),
                           NULL, 0, NULL, 0, 30.0, -1, jsf_fetch_map, NULL);
    if (!f) return NULL;
    {
        dSP; int count;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 1); PUSHs(sv_2mortal(f)); PUTBACK;
        count = call_method("get", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) { SV *r = POPs; if (SvOK(r)) body = newSVsv(r); }
        else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
    }
    if (!body) return NULL;
    return jsf_fetch_decode(aTHX_ sv_2mortal(body));
}

#endif /* JSF_FETCH_H */
