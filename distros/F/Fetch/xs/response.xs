MODULE = Fetch		PACKAGE = Fetch::Response

# A Fetch::Response is a blessed hashref built in C (ft_http.h):
#   status  => integer status code
#   headers => arrayref [ key, value, key, value, ... ]
#   content => response body bytes

SV *
status(self)
    SV *self
    CODE:
    {
        SV **e = hv_fetchs((HV *)SvRV(self), "status", 0);
        RETVAL = (e && *e) ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
content(self)
    SV *self
    CODE:
    {
        SV **e = hv_fetchs((HV *)SvRV(self), "content", 0);
        RETVAL = (e && *e) ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

# Decode the body as JSON into a Perl structure (dies on malformed JSON).
SV *
json(self)
    SV *self
    CODE:
    {
        SV **e = hv_fetchs((HV *)SvRV(self), "content", 0);
        RETVAL = ft_json_decode(aTHX_ (e && *e) ? *e : &PL_sv_undef);
    }
    OUTPUT:
        RETVAL

int
is_success(self)
    SV *self
    ALIAS:
        is_redirect = 1
    CODE:
    {
        SV **e = hv_fetchs((HV *)SvRV(self), "status", 0);
        IV s = (e && *e) ? SvIV(*e) : 0;
        RETVAL = ix == 0 ? (s >= 200 && s < 300) : (s >= 300 && s < 400);
    }
    OUTPUT:
        RETVAL

# The response headers as a Fetch::Headers. The C core builds a plain
# [k, v, k, v, ...] arrayref; bless it in place on first access (that class is
# itself such an arrayref, so @{$res->headers} still yields the flat list).
SV *
headers(self)
    SV *self
    CODE:
    {
        HV  *hv = (HV *)SvRV(self);
        SV **hp = hv_fetchs(hv, "headers", 0);
        SV  *h;
        if (!(hp && *hp && SvROK(*hp))) {
            /* defensive: hand back an empty Fetch::Headers */
            AV *av = newAV();
            h = sv_bless(newRV_noinc((SV *)av),
                         gv_stashpv("Fetch::Headers", GV_ADD));
            (void)hv_stores(hv, "headers", h);
            RETVAL = newSVsv(h);
        } else {
            h = *hp;
            if (!SvOBJECT(SvRV(h)))
                (void)sv_bless(h, gv_stashpv("Fetch::Headers", GV_ADD));
            RETVAL = newSVsv(h);
        }
    }
    OUTPUT:
        RETVAL

# Case-insensitive single-header lookup (first value).
SV *
header(self, name)
    SV *self
    SV *name
    CODE:
    {
        STRLEN nl;
        const char *ns = SvPV_const(name, nl);
        SV **hp = hv_fetchs((HV *)SvRV(self), "headers", 0);
        RETVAL = newSV(0);
        if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(*hp);
            SSize_t idx = ft_hdr_find(aTHX_ av, ns, nl);
            if (idx >= 0) {
                SV **v = av_fetch(av, idx + 1, 0);
                if (v && *v) { SvREFCNT_dec(RETVAL); RETVAL = newSVsv(*v); }
            }
        }
    }
    OUTPUT:
        RETVAL

# The response TRAILERS as a Fetch::Headers, or undef when the response
# carried none - which is every HTTP/1 response and most HTTP/2 ones.
#
# Kept separate from headers() rather than merged: a trailer arrived AFTER the
# body, and a consumer that cares about the difference has to be able to tell.
# The case that needs them is gRPC, where the call status lives in the
# trailers and nowhere else - a gRPC response is HTTP 200 whether it succeeded
# or failed, so a client that cannot read them can only report success.
SV *
trailers(self)
    SV *self
    CODE:
    {
        HV  *hv = (HV *)SvRV(self);
        SV **hp = hv_fetchs(hv, "trailers", 0);
        SV  *h;
        if (!(hp && *hp && SvROK(*hp))) XSRETURN_UNDEF;
        h = *hp;
        if (!SvOBJECT(SvRV(h)))
            (void)sv_bless(h, gv_stashpv("Fetch::Headers", GV_ADD));
        RETVAL = newSVsv(h);
    }
    OUTPUT:
        RETVAL
