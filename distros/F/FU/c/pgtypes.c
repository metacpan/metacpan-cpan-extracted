typedef struct fupg_tio fupg_tio;

/* Send function, takes a Perl value and should write the binary encoded
 * format into the given fustr. */
typedef void (*fupg_send_fn)(pTHX_ const fupg_tio *, SV *, fustr *);

/* Receive function, takes a binary string and should return a Perl value. */
typedef SV *(*fupg_recv_fn)(pTHX_ const fupg_tio *, const char *, int);

typedef struct {
    char n[64];
} fupg_name;

/* Record/composite type definition */
typedef struct {
    int nattrs;
    struct {
        Oid oid;
        fupg_name name;
    } attrs[];
} fupg_record;

/* Type I/O context */
struct fupg_tio {
    Oid oid;
    const char *name;
    fupg_send_fn send;
    fupg_recv_fn recv;
    union {
        fupg_tio *arrayelem;
        struct {
            const fupg_record *info;
            fupg_tio *tio;
        } record;
        SV *cb;
    };
};

typedef struct {
    Oid oid;
    Oid elemoid; /* For arrays & domain types; relid for records */
    fupg_name name;
    fupg_send_fn send;
    fupg_recv_fn recv;
} fupg_type;



#define RECVFN(name) static SV *fupg_recv_##name(pTHX_ const fupg_tio *ctx __attribute__((unused)), const char *buf, int len)
#define SENDFN(name) static void fupg_send_##name(pTHX_ const fupg_tio *ctx __attribute__((unused)), SV *val, fustr *out)
#define RERR(msg, ...) fu_confess("Error parsing value for type '%s' (oid %u): "msg, ctx->name, ctx->oid __VA_OPT__(,) __VA_ARGS__)
#define SERR(msg, ...) fu_confess("Error converting Perl value '%s' to type '%s' (oid %u): "msg, SvPV_nolen(val), ctx->name, ctx->oid __VA_OPT__(,) __VA_ARGS__)
#define RLEN(l) if (l != len) RERR("expected %d bytes but got %d", l, len)

/* Perl likes to play loose with SV-to-integer conversions, but that's not
 * very fun when trying to store values in a database. Text-based bind
 * parameters get stricter validation by Postgres, so let's emulate some of
 * that for binary parameters as well. */
#define SIV(min, max) IV iv;\
    if (SvIOK(val)) iv = SvIV(val); \
    else if (SvNOK(val)) { \
        NV nv = SvNV(val); \
        if (nv < IV_MIN || nv > IV_MAX || fabs((double)(nv - floor(nv))) > 0.0000000001) SERR("expected integer");\
        iv = SvIV(val); \
    } else if (SvPOK(val)) {\
        STRLEN sl; \
        UV uv; \
        char *s = SvPV(val, sl); \
        if (*s == '-' && grok_atoUV(s+1, &uv, NULL) && uv <= ((UV)IV_MAX)+1) iv = SvIV(val);\
        else if (grok_atoUV(s, &uv, NULL) && uv <= IV_MAX) iv = SvIV(val);\
        else SERR("expected integer");\
    } else SERR("expected integer");\
    if (iv < min || iv > max) SERR("integer out of range")

/* These are simply marker functions, not supposed to be called directly */
RECVFN(domain) { (void)buf; (void)len; RERR("domain type should not be handled by this function"); }
SENDFN(domain) { (void)out; SERR("domain type should not be handled by this function"); }

RECVFN(bool) {
    RLEN(1);
    return *buf ? newSV_true() : newSV_false();
}

SENDFN(bool) {
    int r = fu_2bool(aTHX_ val);
    if (r < 0) {
        STRLEN l;
        const char *x = SvPV(val, l);
        if (l == 0 || (l == 1 && (*x == '0' || *x == 'f'))) r = 0;
        else if (l == 1 && (*x == '1' || *x == 't')) r = 1;
        else SERR("invalid boolean value: %s", x);
    }
    fustr_write_ch(out, r);
}

RECVFN(void) {
    RLEN(0);
    (void)buf;
    return newSV(0);
}

SENDFN(void) {
    (void)val; (void)out;
}

RECVFN(int2) {
    RLEN(2);
    return newSViv(fu_frombeI(16, buf));
}

SENDFN(int2) {
    SIV(-32768, 32767);
    fustr_writebeI(16, out, iv);
}

RECVFN(int4) {
    RLEN(4);
    return newSViv(fu_frombeI(32, buf));
}

SENDFN(int4) {
    SIV(-2147483648, 2147483647);
    fustr_writebeI(32, out, iv);
}

RECVFN(int8) {
    RLEN(8);
    return newSViv(fu_frombeI(64, buf));
}

SENDFN(int8) {
    SIV(IV_MIN, IV_MAX);
    fustr_writebeI(64, out, iv);
}

RECVFN(uint4) {
    RLEN(4);
    return newSViv(fu_frombeU(32, buf));
}

SENDFN(uint4) {
    SIV(0, UINT32_MAX);
    fustr_writebeU(32, out, iv);
}

RECVFN(uint8) {
    RLEN(8);
    return newSVuv(fu_frombeU(64, buf));
}

SENDFN(uint8) {
    /* Doesn't have the nice input validation of 'SIV', but this type is pretty rare anyway */
    fustr_writebeU(64, out, SvUV(val));
}

RECVFN(bytea) {
    return newSVpvn(buf, len);
}

SENDFN(bytea) {
    STRLEN len;
    const char *buf = SvPVbyte(val, len);
    fustr_write(out, buf, len);
}

RECVFN(hex) {
    SV *r = newSV(len ? len * 2 : 1);
    SvPOK_only(r);
    char *out = SvPVX(r);
    const unsigned char *in = (const unsigned char *)buf;
    int i;
    for (i=0; i<len; i++) {
        *out++ = PL_hexdigit[(in[i] >> 4) & 0x0f];
        *out++ = PL_hexdigit[in[i] & 0x0f];
    }
    *out = 0;
    SvCUR_set(r, len * 2);
    return r;
}

SENDFN(hex) {
    STRLEN len;
    const char *in = SvPV(val, len);
    const char *end = in + len;
    if (len % 2) SERR("Invalid hex string");
    while (in < end) {
        int v = (fu_hexdig(*in)<<4) + fu_hexdig(in[1]);
        if (v > 0xff) SERR("Invalid hex string");
        fustr_write_ch(out, v);
        in += 2;
    }
}

RECVFN(char) {
    RLEN(1);
    return newSVpvn(buf, len);
}

SENDFN(char) {
    STRLEN len;
    const char *buf = SvPVbyte(val, len);
    if (len != 1) SERR("expected 1-byte string");
    fustr_write(out, buf, len);
}

/* Works for many text-based column types, including receiving any value in the text format */
RECVFN(text) {
    if (!is_c9strict_utf8_string((const U8*)buf, len)) RERR("invalid UTF-8");
    return newSVpvn_utf8(buf, len, 1);
}

SENDFN(text) {
    STRLEN len;
    const char *buf = SvPVutf8(val, len);
    fustr_write(out, buf, len);
}

RECVFN(float4) {
    RLEN(4);
    return newSVnv(fu_frombeT(float, 32, buf));
}

SENDFN(float4) {
    if (!looks_like_number(val)) SERR("expected a number");
    fustr_writebeT(float, 32, out, SvNV(val));
}

RECVFN(float8) {
    RLEN(8);
    return newSVnv(fu_frombeT(double, 64, buf));
}

SENDFN(float8) {
    if (!looks_like_number(val)) SERR("expected a number");
    fustr_writebeT(double, 64, out, SvNV(val));
}

RECVFN(json) {
    fujson_parse_ctx json = {
        .buf = (const unsigned char *)buf,
        .end = (const unsigned char *)buf + len,
        .depth = 512
    };
    SV *sv = fujson_parse(aTHX_ &json);
    if (sv == NULL) RERR("invalid JSON");
    if (json.buf != json.end) RERR("trailing garbage");
    return sv;
}

SENDFN(json) {
    fujson_fmt_ctx json = { .out = out, .depth = 512, .canon = 1, .pretty = 0 };
    fujson_fmt(aTHX_ &json, val);
}

RECVFN(jsonb) {
    if (len <= 1 || *buf != 1) RERR("invalid JSONB");
    return fupg_recv_json(aTHX_ ctx, buf+1, len-1);
}

SENDFN(jsonb) {
    fustr_write_ch(out, 1);
    fupg_send_json(aTHX_ ctx, val, out);
}

RECVFN(jsonpath) {
    if (len <= 1 || *buf != 1) RERR("invalid jsonpath");
    return fupg_recv_text(aTHX_ ctx, buf+1, len-1);
}

SENDFN(jsonpath) {
    fustr_write_ch(out, 1);
    fupg_send_text(aTHX_ ctx, val, out);
}


#define ARRAY_MAXDIM 100

static SV *fupg_recv_array_elem(pTHX_ const fupg_tio *elem, const char *header, U32 dim, U32 ndim, const char **buf, const char *end) {
    SV *r;
    if (dim == ndim) {
        if (end - *buf < 4) fu_confess("Invalid array format");
        I32 len = fu_frombeI(32, *buf);
        *buf += 4;

        if (end - *buf < len) fu_confess("Invalid array format");
        if (len >= 0) {
            r = elem->recv(aTHX_ elem, *buf, len);
            *buf += len;
        } else {
            r = newSV(0);
        }

    } else {
        U32 n = fu_frombeU(32, header + dim*8);
        AV *av = newAV_alloc_x(n);
        r = sv_2mortal(newRV_noinc((SV *)av)); /* need to mortalize, we may croak */
        U32 i;
        for (i=0; i<n; i++)
            av_push_simple(av, fupg_recv_array_elem(aTHX_ elem, header, dim+1, ndim, buf, end));
        SvREFCNT_inc(r); /* We're safe now, make sure it survives the mortal stack cleanup */
    }
    return r;
}

RECVFN(array) {
    if (len < 12) RERR("input data too short");
    U32 ndim = fu_frombeU(32, buf);
    // buf+4 is hasnull, can safely ignore
    Oid elemtype = fu_frombeU(32, buf+8);
    if (elemtype != ctx->arrayelem->oid) RERR("invalid element type, expected %u but got %u", ctx->arrayelem->oid, elemtype);

    if (ndim == 0) return newRV_noinc((SV *)newAV());
    if (ndim > ARRAY_MAXDIM) RERR("too many dimensions");
    if ((U32)len < 12 + ndim*8) RERR("input data too short");

    const char *header = buf + 12;
    const char *data = header + ndim * 8;
    return fupg_recv_array_elem(aTHX_ ctx->arrayelem, header, 0, ndim, &data, buf+len);
}

void fupg_send_array_elem(pTHX_ const fupg_tio *elem, const U32 *dims, U32 dim, U32 ndim, SV *v, fustr *out, int *hasnull) {
    SvGETMAGIC(v);
    if (dim == ndim) {
        if (!SvOK(v)) {
            fustr_write(out, "\xff\xff\xff\xff", 4);
            *hasnull = 1;
            return;
        }
        size_t lenoff = fustr_len(out);
        fustr_write(out, "\0\0\0\0", 4);
        elem->send(aTHX_ elem, v, out);
        fu_tobeU(32, fustr_start(out) + lenoff, fustr_len(out) - lenoff - 4);
        return;
    }

    if (!SvROK(v)) fu_confess("Invalid array structure in bind parameter");
    v = SvRV(v);
    SvGETMAGIC(v);
    if (SvTYPE(v) != SVt_PVAV) fu_confess("Invalid array structure in bind parameter");
    AV *av = (AV*)v;
    if (av_count(av) != dims[dim]) fu_confess("Invalid array structure in bind parameter");
    U32 i;
    for (i=0; i<dims[dim]; i++) {
        SV **sv = av_fetch(av, i, 0);
        if (!sv || !*sv) fu_confess("Invalid array structure in bind parameter");
        fupg_send_array_elem(aTHX_ elem, dims, dim+1, ndim, *sv, out, hasnull);
    }
}

SENDFN(array) {
    U32 ndim = 0;
    U32 dims[ARRAY_MAXDIM];

    /* First figure out ndim and length-per-dim. The has-null flag and
     * verification that each array-per-dimension has the same length is done
     * while writing the elements.
     * This is prone to errors if the elem type also accepts arrays as input,
     * not quite sure how to deal with that case. */
    SV *v = val;
    while (true) {
        SvGETMAGIC(v);
        if (!SvROK(v)) break;
        v = SvRV(v);
        SvGETMAGIC(v);
        if (SvTYPE(v) != SVt_PVAV) break;
        if (ndim >= ARRAY_MAXDIM) SERR("too many dimensions");
        dims[ndim] = av_count((AV*)v);
        if (ndim > 0 && dims[ndim] == 0) SERR("nested arrays may not be empty");
        ndim++;
        SV **sv = av_fetch((AV*)v, 0, 0);
        if (!sv || !*sv) break;
        v = *sv;
    }
    if (ndim == 0) SERR("expected an array");
    if (dims[0] == 0) ndim = 0;

    /* Write header */
    fustr_writebeU(32, out, ndim);
    fustr_write(out, "\0\0\0\0", 4); /* Placeholder for isnull */
    size_t hasnull_off = fustr_len(out) - 1;
    fustr_writebeU(32, out, ctx->arrayelem->oid);
    U32 i;
    for (i=0; i<ndim; i++) {
        fustr_writebeU(32, out, dims[i]);
        /* int2vector and oidvector expect 0-based indexing,
         * everything else defaults to 1-based indexing. */
        if (ctx->oid == 22 || ctx->oid == 30) fustr_write(out, "\0\0\0\0", 4);
        else fustr_write(out, "\0\0\0\1", 4);
    }
    if (ndim == 0) return;

    /* write the elements */
    int hasnull = 0;
    fupg_send_array_elem(aTHX_ ctx->arrayelem, dims, 0, ndim, val, out, &hasnull);
    if (hasnull) fustr_start(out)[hasnull_off] = 1;
}

#undef ARRAY_MAXDIM


RECVFN(record) {
    if (len < 4) RERR("input data too short");
    I32 nfields = fu_frombeI(32, buf);
    if (nfields != ctx->record.info->nattrs) RERR("expected %d fields but got %d", ctx->record.info->nattrs, nfields);
    buf += 4; len -= 4;
    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV *)hv));
    I32 i;
    for (i=0; i<nfields; i++) {
        if (len < 8) RERR("input data too short");
        U32 oid = fu_frombeU(32, buf);
        if (oid != ctx->record.info->attrs[i].oid)
            RERR("expected field %d to be of type %u but got %u", i, ctx->record.info->attrs[i].oid, oid);
        I32 vlen = fu_frombeI(32, buf+4);
        SV *r;
        buf += 8; len -= 8;
        if (vlen > len) RERR("input data too short");
        if (vlen >= 0) {
            r = ctx->record.tio[i].recv(aTHX_ ctx->record.tio+i, buf, vlen);
            buf += vlen; len -= vlen;
        } else {
            r = newSV(0);
        }
        hv_store(hv, ctx->record.info->attrs[i].name.n, -strlen(ctx->record.info->attrs[i].name.n), r, 0);
    }
    return SvREFCNT_inc(sv);
}

SENDFN(record) {
    if (!SvROK(val)) SERR("expected a hashref");
    SV *sv = SvRV(val);
    SvGETMAGIC(sv);
    if (SvTYPE(sv) != SVt_PVHV) SERR("expected a hashref");
    HV *hv = (HV *)sv;

    fustr_writebeU(32, out, ctx->record.info->nattrs);
    I32 i;
    for (i=0; i<ctx->record.info->nattrs; i++) {
        fustr_writebeI(32, out, ctx->record.info->attrs[i].oid);
        SV **rsv = hv_fetch(hv, ctx->record.info->attrs[i].name.n, -strlen(ctx->record.info->attrs[i].name.n), 0);
        if (!rsv || !*rsv) {
            fustr_writebeI(32, out, -1);
            continue;
        }
        sv = *rsv;
        SvGETMAGIC(sv);
        if (!SvOK(sv)) {
            fustr_writebeI(32, out, -1);
            continue;
        }
        size_t lenoff = fustr_len(out);
        fustr_write(out, "\0\0\0\0", 4);
        ctx->record.tio[i].send(aTHX_ ctx->record.tio+i, sv, out);
        fu_tobeU(32, fustr_start(out) + lenoff, fustr_len(out) - lenoff - 4);
    }
}


RECVFN(perlcb) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    mXPUSHs(newSVpvn(buf, len));
    PUTBACK;
    call_sv(ctx->cb, G_SCALAR);
    SPAGAIN;

    SV *ret = POPs;
    SvREFCNT_inc(ret);
    PUTBACK;

    FREETMPS;
    LEAVE;
    return ret;
}

SENDFN(perlcb) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(val);

    PUTBACK;
    call_sv(ctx->cb, G_SCALAR);
    SPAGAIN;

    SV *ret = POPs;
    PUTBACK;

    STRLEN len;
    const char *buf = SvPV(ret, len);
    fustr_write(out, buf, len);

    FREETMPS;
    LEAVE;
}


RECVFN(inet) { /* Also works for cidr */
    char tmp[128];
    if (len < 8) RERR("input data too short");
    // 0: ip_family, 1: mask_bits, 2: is_cidr, 3: addrsize, 4: address

    if (buf[0] == 2) { /* INET */
        RLEN(8);
        if (!inet_ntop(AF_INET, buf+4, tmp, sizeof(tmp)-1)) RERR("%s", strerror(errno));
    } else if (buf[0] == 3) { /* INET6 */
        RLEN(20);
        if (!inet_ntop(AF_INET6, buf+4, tmp, sizeof(tmp)-1)) RERR("%s", strerror(errno));
    } else RERR("unknown address type");

    if (buf[2] || buf[1] != (buf[0] == 2 ? 32 : (char)128))
        return newSVpvf("%s/%d", tmp, (unsigned char)buf[1]);
    return newSVpv(tmp, 0);
}

SENDFN(inet) {
    char tmp[128];
    STRLEN len;
    const char *in = SvPV(val, len);
    if (len >= sizeof(tmp)) SERR("input too long");
    char family = strchr(in, ':') ? 3 : 2;
    char *wr = fustr_write_buf(out, family == 2 ? 8 : 20);
    unsigned char *mask = (unsigned char*)wr+1;
    wr[0] = family;
    *mask = family == 2 ? 32 : 128;
    wr[2] = ctx->oid == 650;
    wr[3] = family == 2 ? 4 : 16;

    char *slash = strchr(in, '/');
    if (slash && slash - in < 100) {
        memcpy(tmp, in, slash - in);
        tmp[slash - in] = 0;
        in = tmp;
    }
    if (inet_pton(family == 2 ? AF_INET : AF_INET6, in, wr+4) != 1)
        SERR("invalid address");

    if (slash) {
        UV uv = 129;
        if (!grok_atoUV(slash+1, &uv, NULL) || uv > *mask)
            SERR("invalid mask");
        *mask = uv;
    }
}

RECVFN(uuid) {
    RLEN(16);
    char tmp[64];
    char *out = tmp;
    const unsigned char *in = (const unsigned char *)buf;
    int i;
    for (i=0; i<16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10) *out++ = '-';
        *out++ = PL_hexdigit[(in[i] >> 4) & 0x0f];
        *out++ = PL_hexdigit[in[i] & 0x0f];
    }
    *out = '\0';
    return newSVpv(tmp, 0);
}

SENDFN(uuid) {
    const char *in = SvPV_nolen(val);
    int bytes = 0;
    unsigned char dig = 0x10;
    if (*in == '{') in++;
    for (; *in; in++) {
        if (*in == '}') break;
        if (dig == 0x10 && *in == '-') continue;
        int x = fu_hexdig(*in);
        if (x > 0x10) SERR("invalid UUID");
        if (bytes >= 16) SERR("invalid UUID");
        if (dig == 0x10) dig = x;
        else {
            fustr_write_ch(out, (dig << 4) + x);
            bytes++;
            dig = 0x10;
        }
    }
    if (dig != 0x10 || bytes != 16) SERR("invalid UUID");
}

/* Postgres uses 2000-01-01 as epoch, we stick with POSIX 1970-01-01 */
#define UNIX_PG_EPOCH (10957*86400)

RECVFN(timestamp) {
    RLEN(8);
    return newSVnv(((NV)fu_frombeI(64, buf) / 1000000) + UNIX_PG_EPOCH);
}

SENDFN(timestamp) {
    if (!looks_like_number(val)) SERR("expected a number");
    I64 ts = (SvNV(val) - UNIX_PG_EPOCH) * 1000000;
    fustr_writebeI(64, out, ts);
}

RECVFN(date) {
    RLEN(4);
    return newSVuv(((UV)fu_frombeI(32, buf)) * 86400 + UNIX_PG_EPOCH);
}

SENDFN(date) {
    if (!looks_like_number(val)) SERR("expected a number");
    fustr_writebeI(32, out, (SvIV(val) - UNIX_PG_EPOCH) / 86400);
}

RECVFN(date_str) {
    RLEN(4);
    time_t ts = ((time_t)fu_frombeI(32, buf)) * 86400 + UNIX_PG_EPOCH;
    struct tm tm;
    gmtime_r(&ts, &tm);
    return newSVpvf("%04d-%02d-%02d", tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday);
}

SENDFN(date_str) {
    int year, month, day;
    if (sscanf(SvPV_nolen(val), "%4d-%2d-%2d", &year, &month, &day) != 3) SERR("invalid date format");
    /* Can't use mktime() hackery here because libc has no UTC variant. Code
     * below is adapted from PostgreSQL date2j() instead. */
    if (month > 2) {
        month += 1;
        year += 4800;
    } else {
        month += 13;
        year += 4799;
    }
    int century = year / 100;
    int v = year * 365 - 32167;
    v += year / 4 - century + century / 4;
    v += 7834 * month / 256 + day;
    v -= 2451545; /* Julian -> Postgres */
    fustr_writebeI(32, out, v);
}

#undef UNIX_PG_EPOCH

RECVFN(time) {
    RLEN(8);
    return newSVnv(((NV)fu_frombeI(64, buf)) / 1000000);
}

SENDFN(time) {
    if (!looks_like_number(val)) SERR("expected a number");
    fustr_writebeI(64, out, SvNV(val) * 1000000);
}



/* VNDB types */

const char vndbtag_alpha[] = "\0""abcdefghijklmnopqrstuvwxyz?????";

static I16 vndbtag_parse(char **str) {
    I16 tag = 0;
    if (**str >= 'a' && **str <= 'z') {
        tag = (**str - 'a' + 1) << 10;
        (*str)++;
        if (**str >= 'a' && **str <= 'z') {
            tag |= (**str - 'a' + 1) << 5;
            (*str)++;
            if (**str >= 'a' && **str <= 'z') {
                tag |= **str - 'a' + 1;
                (*str)++;
            }
        }
    }
    return tag;
}

void vndbtag_fmt(I16 tag, char *out) {
    out[0] = vndbtag_alpha[(tag >> 10) & 31];
    out[1] = vndbtag_alpha[(tag >>  5) & 31];
    out[2] = vndbtag_alpha[(tag >>  0) & 31];
    out[3] = 0;
}

RECVFN(vndbtag) {
    RLEN(2);
    SV *r = newSV(4);
    SvPOK_only(r);
    vndbtag_fmt(fu_frombeI(16, buf), SvPVX(r));
    SvCUR_set(r, strlen(SvPVX(r)));
    return r;
}

SENDFN(vndbtag) {
    char *t = SvPV_nolen(val);
    I16 v = vndbtag_parse(&t);
    if (*t) SERR("Invalid vndbtag: '%s'", SvPV_nolen(val));
    fustr_writebeI(16, out, v);
}


#define VNDBID2_MAXNUM (((I64)1<<48)-1)

RECVFN(vndbid) {
    RLEN(8);
    I64 v = fu_frombeI(64, buf);
    char tbuf[4];
    vndbtag_fmt(v >> 48, tbuf);
    return newSVpvf("%s%"UVuf, tbuf, (UV)(v & VNDBID2_MAXNUM));
}

SENDFN(vndbid) {
    char *ostr = SvPV_nolen(val), *str = ostr;
    UV num;
    I16 tag = vndbtag_parse(&str);
    if (!grok_atoUV(str, &num, NULL) || num > VNDBID2_MAXNUM) SERR("invalid vndbid '%s'", ostr);
    fustr_writebeI(64, out, ((I64)tag)<<48 | num);
}


#undef SIV
#undef RLEN
#undef RECVFN
#undef SENDFN




/* List of types we handle directly in this module.
   Ideally, this includes everything returned by:

     SELECT oid, typname, typelem, typreceive
       FROM pg_type t
      WHERE typtype = 'b'
        AND typnamespace = 'pg_catalog'::regnamespace
        AND (typelem = 0 OR EXISTS(SELECT 1 FROM pg_type e WHERE e.oid = t.typelem AND e.typtype = 'b'))
      ORDER by oid

   (i.e. all base types and arrays of base types)
   Plus hopefully a bunch of common extension types.

   The "reg#" types are a bit funny: the Postgres devs obviously realized that
   writing JOINs is cumbersome, so they hacked together a numeric identifier
   type that automatically resolves to a string when formatted as text, or
   performs a lookup in the database when parsing text. In the text format, you
   don't get to see the numeric identifier, but sadly that conversion is not
   performed in the byte format so we're dealing with numbers instead. Oh well.
   Not worth writing custom lookup code for, users will have to adapt.

   Ordered by oid to support binary search.
   (name is only used when formatting error messages, for now) */
#define BUILTINS \
    B(   16, "bool",           bool  )\
    B(   17, "bytea",          bytea )\
    B(   18, "char",           char  )\
    B(   19, "name",           text  )\
    B(   20, "int8",           int8  )\
    B(   21, "int2",           int2  )\
    A(   22, "int2vector",     21    )\
    B(   23, "int4",           int4  )\
    B(   24, "regproc",        uint4 )\
    B(   25, "text",           text  )\
    B(   26, "oid",            uint4 )\
    /*   27  tid: u32 block, u16 offset; represent as hash? */ \
    B(   28, "xid",            uint4 )\
    B(   29, "cid",            uint4 )\
    A(   30, "oidvector",      26    )\
    B(  114, "json",           json  )\
    B(  142, "xml",            text  )\
    A(  143, "_xml",           142   )\
    B(  194, "pg_node_tree",   text  ) /* can't be used as a bind param */\
    A(  199, "_json",          114   )\
    A(  271, "_xid8",          5069  )\
    /*  600  point    */\
    /*  601  lseg     */\
    /*  602  path     */\
    /*  603  box      */\
    /*  604  polygon  */\
    /*  628  line     */\
    A(  629, "_line",          628   )\
    B(  650, "cidr",           inet  )\
    A(  651, "_cidr",          650   )\
    B(  700, "float4",         float4)\
    B(  701, "float8",         float8)\
    /*  718  circle   */\
    A(  719, "_circle",        718   )\
    /*  774  macaddr8 */\
    A(  775, "_macaddr8",      774   )\
    /*  790  money    */\
    A(  791, "_money",         790   )\
    /*  829  macaddr  */\
    B(  869, "inet",           inet  )\
    A( 1000, "_bool",          16    )\
    A( 1001, "_bytea",         17    )\
    A( 1002, "_char",          18    )\
    A( 1003, "_name",          19    )\
    A( 1005, "_int2",          21    )\
    A( 1006, "_int2vector",    22    )\
    A( 1007, "_int4",          23    )\
    A( 1008, "_regproc",       24    )\
    A( 1009, "_text",          25    )\
    A( 1010, "_tid",           27    )\
    A( 1011, "_xid",           28    )\
    A( 1012, "_cid",           29    )\
    A( 1013, "_oidvector",     30    )\
    A( 1014, "_bpchar",        1042  )\
    A( 1015, "_varchar",       1043  )\
    A( 1016, "_int8",          20    )\
    A( 1017, "_point",         600   )\
    A( 1018, "_lseg",          601   )\
    A( 1019, "_path",          602   )\
    A( 1020, "_box",           603   )\
    A( 1021, "_float4",        700   )\
    A( 1022, "_float8",        701   )\
    A( 1027, "_polygon",       604   )\
    A( 1028, "_oid",           26    )\
    /* 1033  aclitem, does not support send/recv */\
    /* A( 1034, "_aclitem",       1033  ) */\
    A( 1040, "_macaddr",       829   )\
    A( 1041, "_inet",          869   )\
    B( 1042, "bpchar",         text  )\
    B( 1043, "varchar",        text  )\
    B( 1082, "date",           date  )\
    B( 1083, "time",           time  )\
    B( 1114, "timestamp",      timestamp)\
    A( 1115, "_timestamp",     1114  )\
    A( 1182, "_date",          1082  )\
    A( 1183, "_time",          1083  )\
    B( 1184, "timestamptz",    timestamp)\
    A( 1185, "_timestamptz",   1184  )\
    /* 1186  interval    */\
    A( 1187, "_interval",      1186  )\
    A( 1231, "_numeric",       1700  )\
    /* 1266  timetz      */\
    A( 1270, "_timetz",        1266  )\
    /* 1560  bit         */\
    A( 1561, "_bit",           1560  )\
    /* 1562  varbit      */\
    A( 1563, "_varbit",        1562  )\
    /* 1700  numeric     */\
    B( 1790, "refcursor",      text  )\
    A( 2201, "_refcursor",     1790  )\
    B( 2202, "regprocedure",   uint4 )\
    B( 2203, "regoper",        uint4 )\
    B( 2204, "regoperator",    uint4 )\
    B( 2205, "regclass",       uint4 )\
    B( 2206, "regtype",        uint4 )\
    A( 2207, "_regprocedure",  2202  )\
    A( 2208, "_regoper",       2203  )\
    A( 2209, "_regoperator",   2204  )\
    A( 2210, "_regclass",      2205  )\
    A( 2211, "_regtype",       2206  )\
    B( 2278, "void",           void  )\
    A( 2949, "_txid_snapshot", 2970  )\
    B( 2950, "uuid",           uuid  )\
    A( 2951, "_uuid",          2950  )\
    /* 2970  txid_snapshot: same as pg_snapshot */\
    /* 3220  pg_lsn: uint64 with custom formatting */\
    A( 3221, "_pg_lsn",        3220  )\
    /* 3361  pg_ndistinct    */\
    /* 3402  pg_dependencies */\
    /* 3614  tsvector        */\
    /* 3615  tsquery         */\
    /* 3642  gtsvector, does not support send/recv */\
    A( 3643, "_tsvector",      3614  )\
    /*A( 3644, "_gtsvector",     3642  )*/\
    A( 3645, "_tsquery",       3615  )\
    B( 3734, "regconfig",      uint4 )\
    A( 3735, "_regconfig",     3734  )\
    B( 3769, "regdictionary",  uint4 )\
    A( 3770, "_regdictionary", 3769  )\
    B( 3802, "jsonb",          jsonb )\
    A( 3807, "_jsonb",         3802  )\
    B( 4072, "jsonpath",       jsonpath)\
    A( 4073, "_jsonpath",      4072  )\
    B( 4089, "regnamespace",   uint4 )\
    A( 4090, "_regnamespace",  4089  )\
    B( 4096, "regrole",        uint4 )\
    A( 4097, "_regrole",       4096  )\
    B( 4191, "regcollation",   uint4 )\
    A( 4192, "_regcollation",  4191  )\
    /* 4600  pg_brin_bloom_summary        */\
    /* 4601  pg_brin_minmax_multi_summary */\
    /* 5017  pg_mcv_list                  */\
    /* 5038  pg_snapshot: int4 nxip, int8 xmin, int8 xmax, int8 xip */\
    A( 5039, "_pg_snapshot",   5038  )\
    B( 5069, "xid8",           uint8 )

static const fupg_type fupg_builtin[] = {
#define B(oid, name, fun) { oid, 0, {name"\0"}, fupg_send_##fun, fupg_recv_##fun },
#define A(oid, name, eoid) { oid, eoid, {name"\0"}, fupg_send_array, fupg_recv_array },
    BUILTINS
#undef B
#undef A
};

#undef BUILTINS
#define FUPG_BUILTIN (sizeof(fupg_builtin) / sizeof(fupg_type))


/* List of types identified by name */

#define DYNOID\
    T("vndbtag",   vndbtag)\
    T("vndbid",    vndbid)

static const fupg_type fupg_dynoid[] = {
#define T(name, fun) { 0, 0, {name"\0"}, fupg_send_##fun, fupg_recv_##fun },
    DYNOID
#undef T
};

#undef DYNOID
#define FUPG_DYNOID (sizeof(fupg_dynoid) / sizeof(fupg_type))


/* List of special types for use with set_type() */

#define SPECIALS\
    T("$date_str",   date_str)\
    T("$hex",        hex     )

static const fupg_type fupg_specials[] = {
#define T(name, fun) { 0, 0, {name"\0"}, fupg_send_##fun, fupg_recv_##fun },
    SPECIALS
#undef T
};

#undef SPECIALS
#define FUPG_SPECIALS (sizeof(fupg_specials) / sizeof(fupg_type))


static const fupg_type fupg_type_perlcb = { 0, 0, {"$perl_cb"}, fupg_send_perlcb, fupg_recv_perlcb };


static const fupg_type *fupg_type_byoid(const fupg_type *list, int len, Oid oid) {
    int i, b = 0, e = len-1;
    while (b <= e) {
        i = b + (e - b)/2;
        if (list[i].oid == oid) return list+i;
        if (list[i].oid < oid) b = i+1;
        else e = i-1;
    }
    return NULL;
}

static const fupg_type *fupg_builtin_byoid(Oid oid) {
    return fupg_type_byoid(fupg_builtin, FUPG_BUILTIN, oid);
}

static const fupg_type *fupg_dynoid_byname(const char *name) {
    size_t i;
    for (i=0; i<FUPG_DYNOID; i++)
        if (strcmp(fupg_dynoid[i].name.n, name) == 0)
            return fupg_dynoid+i;
    return NULL;
}

static const fupg_type *fupg_builtin_byname(const char *name) {
    size_t i;
    const fupg_type *r = fupg_dynoid_byname(name);
    if (r) return r;

    /* XXX: Can use binary search here if the list of specials grows.
     * That list does not have to be ordered by oid. */
    for (i=0; i<FUPG_SPECIALS; i++)
        if (strcmp(fupg_specials[i].name.n, name) == 0)
            return fupg_specials+i;

    for (i=0; i<FUPG_BUILTIN; i++)
        if (strcmp(fupg_builtin[i].name.n, name) == 0)
            return fupg_builtin+i;
    return NULL;
}
