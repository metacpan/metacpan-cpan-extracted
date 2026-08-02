MODULE = Fetch		PACKAGE = Fetch::CookieJar

# RFC-6265-ish cookie store; the jar is a C struct behind a blessed IV and all
# logic lives in include/fetch/ft_cookiejar.h.

SV *
new(class, ...)
    SV *class
    CODE:
    {
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        ft_jar *j = ft_jar_new();
        if (!j) croak("Fetch::CookieJar: out of memory");
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(j))),
                          gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    CODE:
        ft_jar_free(ft_jar_of(aTHX_ self));

# Parse one Set-Cookie value in the context of the request host/path; returns
# the jar on a store/delete, or undef if the value was malformed/ignored.
SV *
set_cookie(self, str, host, req_path)
    SV         *self
    SV         *str
    const char *host
    const char *req_path
    CODE:
    {
        int touched = 0;
        if (SvOK(str)) {
            STRLEN sl;
            const char *ss = SvPV(str, sl);
            if (sl) touched = ft_jar_set_cookie(ft_jar_of(aTHX_ self),
                                                ss, host, req_path);
        }
        RETVAL = touched ? SvREFCNT_inc(self) : newSV(0);
    }
    OUTPUT:
        RETVAL

# Pull every Set-Cookie from a Fetch::Response (or Fetch::Headers) and store.
SV *
extract(self, src, host, req_path)
    SV         *self
    SV         *src
    const char *host
    const char *req_path
    CODE:
    {
        ft_jar *j = ft_jar_of(aTHX_ self);
        SV *h = src;
        int own_h = 0;
        if (SvROK(src) && ft_obj_can(aTHX_ src, "headers")) {
            dSP;
            int n;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(src);
            PUTBACK;
            n = call_method("headers", G_SCALAR);
            SPAGAIN;
            /* keep a real ref: the returned SV would otherwise be freed by the
             * FREETMPS below before the get_all call can use it. */
            if (n) { h = SvREFCNT_inc(POPs); own_h = 1; }
            else   { h = &PL_sv_undef; }
            PUTBACK; FREETMPS; LEAVE;
        }
        if (SvROK(h) && ft_obj_can(aTHX_ h, "get_all")) {
            dSP;
            int n, i;
            SV **tmp;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(h);
            XPUSHs(sv_2mortal(newSVpvs("set-cookie")));
            PUTBACK;
            n = call_method("get_all", G_ARRAY);
            SPAGAIN;
            Newx(tmp, n > 0 ? n : 1, SV *);
            for (i = n - 1; i >= 0; i--) tmp[i] = POPs;   /* restore order */
            PUTBACK;
            for (i = 0; i < n; i++) {
                if (SvOK(tmp[i])) {
                    STRLEN vl;
                    const char *vs = SvPV(tmp[i], vl);
                    if (vl) ft_jar_set_cookie(j, vs, host, req_path);
                }
            }
            Safefree(tmp);
            FREETMPS; LEAVE;
        }
        if (own_h) SvREFCNT_dec(h);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# The Cookie header value for a request, or undef if nothing matches.
SV *
cookie_header(self, host, req_path, secure)
    SV         *self
    const char *host
    const char *req_path
    int         secure
    CODE:
    {
        char *s = ft_jar_cookie_str(ft_jar_of(aTHX_ self), host, req_path, secure);
        RETVAL = s ? newSVpv(s, 0) : newSV(0);
        free(s);
    }
    OUTPUT:
        RETVAL

SV *
clear(self)
    SV *self
    CODE:
        ft_jar_clear(ft_jar_of(aTHX_ self));
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

int
count(self)
    SV *self
    CODE:
        RETVAL = (int)ft_jar_of(aTHX_ self)->n;
    OUTPUT:
        RETVAL

int
purge(self)
    SV *self
    CODE:
        RETVAL = ft_jar_purge(ft_jar_of(aTHX_ self));
    OUTPUT:
        RETVAL
