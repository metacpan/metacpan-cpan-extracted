#ifndef JSF_URI_H
#define JSF_URI_H

/* Minimal URI-reference resolution (RFC 3986 sec 5) for $id / $ref. Enough for
 * JSON Schema references: scheme://authority/path plus a fragment. Query strings
 * are not used by schema identifiers and are folded into the path if present.
 * All results are mortal SVs. Needs the Perl API. */

/* remove_dot_segments (RFC 3986 sec 5.2.4) on a path buffer, in place-ish. */
static SV *jsf_uri__remove_dots(pTHX_ const char *in, STRLEN len) {
    SV *out = sv_2mortal(newSVpvn("", 0));
    const char *p = in, *end = in + len;
    while (p < end) {
        if (end - p >= 3 && p[0] == '.' && p[1] == '.' && p[2] == '/') p += 3;
        else if (end - p >= 2 && p[0] == '.' && p[1] == '/') p += 2;
        else if (end - p >= 3 && p[0] == '/' && p[1] == '.' && p[2] == '/') p += 2;
        else if (end - p == 2 && p[0] == '/' && p[1] == '.') { sv_catpvn(out, "/", 1); p += 2; }
        else if (end - p >= 4 && p[0]=='/' && p[1]=='.' && p[2]=='.' && p[3]=='/') {
            p += 3;
            { char *b = SvPVX(out); STRLEN l = SvCUR(out); while (l > 0 && b[l-1] != '/') l--; if (l>0) l--; SvCUR_set(out, l); }
        }
        else if (end - p == 3 && p[0]=='/' && p[1]=='.' && p[2]=='.') {
            sv_catpvn(out, "/", 1); p += 3;
            { char *b = SvPVX(out); STRLEN l = SvCUR(out); if (l>0) l--; while (l > 0 && b[l-1] != '/') l--; SvCUR_set(out, l ? l : 0); if (!l) sv_catpvn(out,"/",1); }
        }
        else if (end - p == 1 && (p[0] == '.')) p += 1;
        else if (end - p == 2 && p[0]=='.' && p[1]=='.') p += 2;
        else {
            const char *s = p; if (*s == '/') s++; while (s < end && *s != '/') s++;
            sv_catpvn(out, p, s - p); p = s;
        }
    }
    return out;
}

/* split a URI into scheme(":" incl), authority("//" incl), path, fragment(no #).
 * Any missing part is empty. Returns via out-SVs (all mortal). */
static void jsf_uri__split(pTHX_ const char *u, STRLEN n,
                           SV **scheme, SV **auth, SV **path, SV **frag) {
    STRLEN i = 0, s = 0; const char *hash;
    STRLEN flen = 0; const char *fp = NULL;
    *scheme = sv_2mortal(newSVpvn("", 0));
    *auth   = sv_2mortal(newSVpvn("", 0));
    *path   = sv_2mortal(newSVpvn("", 0));
    *frag   = sv_2mortal(newSVpvn("", 0));
    hash = (const char *)memchr(u, '#', n);
    if (hash) { fp = hash + 1; flen = n - (hash - u) - 1; n = hash - u; }
    /* scheme: ALPHA *( ALPHA / DIGIT / + / - / . ) ":" */
    if (n && isALPHA((U8)u[0])) {
        i = 1; while (i < n && (isALNUM((U8)u[i]) || u[i]=='+' || u[i]=='-' || u[i]=='.')) i++;
        if (i < n && u[i] == ':') { sv_setpvn(*scheme, u, i + 1); s = i + 1; }
    }
    if (n - s >= 2 && u[s] == '/' && u[s+1] == '/') {
        STRLEN a = s + 2; while (a < n && u[a] != '/') a++;
        sv_setpvn(*auth, u + s, a - s); s = a;
    }
    sv_setpvn(*path, u + s, n - s);
    if (fp) sv_setpvn(*frag, fp, flen);
}

/* resolve ref against base (both NUL-agnostic SVs), returning absolute URI incl
 * fragment as a mortal SV (RFC 3986 sec 5.3, no query handling). */
static SV *jsf_uri_resolve(pTHX_ SV *base, SV *ref) {
    STRLEN bl, rl; const char *bs = SvPV_const(base, bl), *rs = SvPV_const(ref, rl);
    SV *bsc,*bau,*bpa,*bfr, *rsc,*rau,*rpa,*rfr;
    SV *Tsc,*Tau,*Tpa,*out;
    jsf_uri__split(aTHX_ bs, bl, &bsc,&bau,&bpa,&bfr);
    jsf_uri__split(aTHX_ rs, rl, &rsc,&rau,&rpa,&rfr);

    if (SvCUR(rsc)) { Tsc = rsc; Tau = rau; Tpa = jsf_uri__remove_dots(aTHX_ SvPVX(rpa), SvCUR(rpa)); }
    else {
        Tsc = bsc;
        if (SvCUR(rau)) { Tau = rau; Tpa = jsf_uri__remove_dots(aTHX_ SvPVX(rpa), SvCUR(rpa)); }
        else {
            Tau = bau;
            if (SvCUR(rpa) == 0) { Tpa = bpa; }
            else if (SvPVX(rpa)[0] == '/') { Tpa = jsf_uri__remove_dots(aTHX_ SvPVX(rpa), SvCUR(rpa)); }
            else {
                /* merge base path with relative path */
                SV *merged = sv_2mortal(newSVpvn("", 0));
                if (SvCUR(bau) && SvCUR(bpa) == 0) sv_catpvn(merged, "/", 1);
                else { STRLEN l = SvCUR(bpa); const char *b = SvPVX(bpa); while (l>0 && b[l-1] != '/') l--; sv_catpvn(merged, b, l); }
                sv_catsv(merged, rpa);
                Tpa = jsf_uri__remove_dots(aTHX_ SvPVX(merged), SvCUR(merged));
            }
        }
    }
    out = sv_2mortal(newSVpvn("", 0));
    sv_catsv(out, Tsc); sv_catsv(out, Tau); sv_catsv(out, Tpa);
    sv_catpvn(out, "#", 1);
    sv_catsv(out, rfr);
    return out;
}

/* base document URI (scheme+authority+path, no fragment) of a full URI SV */
static SV *jsf_uri_base_of(pTHX_ SV *u) {
    STRLEN l; const char *s = SvPV_const(u, l);
    const char *hash = (const char *)memchr(s, '#', l);
    return sv_2mortal(newSVpvn(s, hash ? (STRLEN)(hash - s) : l));
}

#endif /* JSF_URI_H */
