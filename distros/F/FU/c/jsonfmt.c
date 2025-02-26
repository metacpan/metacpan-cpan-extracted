typedef struct {
    fustr *out;
    UV depth;
    int canon;
    int pretty; /* <0 when disabled, current nesting level otherwise */
} fujson_fmt_ctx;

static void fujson_fmt(pTHX_ fujson_fmt_ctx *, SV *);

static void fujson_fmt_indent(pTHX_ fujson_fmt_ctx *ctx) {
    if (ctx->pretty >= 0) {
        char *buf = fustr_write_buf(ctx->out, 1 + ctx->pretty*3);
        *buf = '\n';
        memset(buf+1, ' ', ctx->pretty*3);
    }
}

static void fujson_fmt_str(pTHX_ fujson_fmt_ctx *ctx, const char *stri, size_t len, int utf8) {
    size_t off = 0, loff;
    const unsigned char *str = (const unsigned char *)stri;
    unsigned char *buf;
    unsigned char x = 0;

    fustr_write_ch(ctx->out, '\"');
    fustr_reserve(ctx->out, len);

    while (off < len) {
        /* Fast path: no escaping needed */
        loff = off;
        if (utf8) {
            /* assume >=0x80 is valid utf8 */
            while (off < len) {
                x = str[off];
                if (x <= 0x1f || x == '"' || x == '\\' || x == 0x7f) break;
                off++;
            }
        } else {
            /* binary strings need special handling for >=0x80 */
            while (off < len) {
                x = str[off];
                if (x <= 0x1f || x == '"' || x == '\\' || x >= 0x7f) break;
                off++;
            }
        }
        fustr_write(ctx->out, (char *)str+loff, off-loff);

        if (off < len) { /* early break, which means current byte needs special processing */
            switch (x) {
                case '"':  fustr_write(ctx->out, "\\\"", 2); break;
                case '\\': fustr_write(ctx->out, "\\\\", 2); break;
                case 0x08: fustr_write(ctx->out, "\\b", 2); break;
                case 0x09: fustr_write(ctx->out, "\\t", 2); break;
                case 0x0a: fustr_write(ctx->out, "\\n", 2); break;
                case 0x0c: fustr_write(ctx->out, "\\f", 2); break;
                case 0x0d: fustr_write(ctx->out, "\\r", 2); break;
                default:
                    if (x < 0x80) {
                        buf = (unsigned char *)fustr_write_buf(ctx->out, 6);
                        memcpy(buf, "\\u00", 4);
                        buf[4] = PL_hexdigit[(x >> 4) & 0x0f];
                        buf[5] = PL_hexdigit[x & 0x0f];
                    } else { /* x >= 0x80, !utf8, so encode as 2-byte UTF-8 */
                        buf = (unsigned char *)fustr_write_buf(ctx->out, 2);
                        buf[0] = 0xc0 | (x >> 6);
                        buf[1] = 0x80 | (x & 0x3f);
                    }
            }
            off++;
        }
    }

    fustr_write_ch(ctx->out, '\"');
}

static const char fujson_digits[] =
    "00010203040506070809"
    "10111213141516171819"
    "20212223242526272829"
    "30313233343536373839"
    "40414243444546474849"
    "50515253545556575859"
    "60616263646566676869"
    "70717273747576777879"
    "80818283848586878889"
    "90919293949596979899";

static void fujson_fmt_int(pTHX_ fujson_fmt_ctx *ctx, SV *val) {
    char buf[32];
    char *r = buf+31;
    int neg = 0;
    IV iv;
    UV uv;

    if (SvIsUV(val)) { /* Why is this macro not documented? */
        uv = SvUV_nomg(val);
    } else {
        iv = SvIV_nomg(val);
        neg = iv < 0;
        uv = neg ? -iv : iv;
    }

    if (uv == 0) {
        fustr_write_ch(ctx->out, '0');
        return;
    }

    while (uv >= 10) {
        r -= 2;
        memcpy(r, fujson_digits + ((uv % 100)<<1), 2);
        uv /= 100;
    }
    if (uv > 0) *(--r) = '0' + (uv % 10);
    if (neg) *(--r) = '-';
    fustr_write(ctx->out, r, 31 - (r - buf));
}

static void fujson_fmt_av(pTHX_ fujson_fmt_ctx *ctx, AV *av) {
    int i, len = av_count(av);
    fustr_write_ch(ctx->out, '[');
    ctx->pretty++;
    for (i=0; i<len; i++) {
        if (i) fustr_write_ch(ctx->out, ',');
        fujson_fmt_indent(aTHX_ ctx);
        SV **sv = av_fetch(av, i, 0);
        if (sv) fujson_fmt(aTHX_ ctx, *sv); /* sv will have magic if av is tied, but fujson_fmt() handles that. */
        else fustr_write(ctx->out, "null", 4);
    }
    ctx->pretty--;
    if (i) fujson_fmt_indent(aTHX_ ctx);
    fustr_write_ch(ctx->out, ']');
}

static int fujson_fmt_hvcmp(const void *pa, const void *pb) {
    dTHX;
    HE *a = *(HE **)pa;
    HE *b = *(HE **)pb;
    STRLEN alen, blen;
    char *astr = HePV(a, alen);
    char *bstr = HePV(b, blen);
    int autf = HeUTF8(a);
    int butf = HeUTF8(b);

    if (autf == butf) {
        int cmp = memcmp(bstr, astr, alen < blen ? alen : blen);
        return cmp != 0 ? cmp : blen < alen ? -1 : blen == alen ? 0 : 1;
    }
    return autf ?  bytes_cmp_utf8((const U8*)bstr, blen, (const U8*)astr, alen)
                : -bytes_cmp_utf8((const U8*)astr, alen, (const U8*)bstr, blen);
}

static void fujson_fmt_hvkv(pTHX_ fujson_fmt_ctx *ctx, HV *hv, HE *he, char **hestr) {
    STRLEN helen;
    if (*hestr) fustr_write_ch(ctx->out, ',');
    fujson_fmt_indent(aTHX_ ctx);
    *hestr = HePV(he, helen);
    fujson_fmt_str(aTHX_ ctx, *hestr, helen, HeUTF8(he));
    if (ctx->pretty > 0) fustr_write(ctx->out, " : ", 3);
    else fustr_write_ch(ctx->out, ':');
    fujson_fmt(aTHX_ ctx, UNLIKELY(SvMAGICAL(hv)) ? hv_iterval(hv, he) : HeVAL(he));
}

static void fujson_fmt_hv(pTHX_ fujson_fmt_ctx *ctx, HV *hv) {
    HE *he;
    char *hestr = NULL;

    int numkeys = hv_iterinit(hv);
    fustr_write_ch(ctx->out, '{');
    ctx->pretty++;

    /* Canonical order on tied hashes is not supported. Cpanel::JSON::XS has
     * code to deal with that case and it's absolutely horrifying. */
    if (ctx->canon && !(SvMAGICAL(hv) && SvTIED_mg((SV*)hv, PERL_MAGIC_tied))) {
        SAVETMPS;
        if (numkeys < 4) numkeys = 4;
        if (SvMAGICAL(hv)) numkeys = 32;

        SV *keys_sv = sv_2mortal(newSV(numkeys * sizeof(HE*)));
        HE **keys = (HE **)SvPVX(keys_sv);
        int i = 0;

        while ((he = hv_iternext(hv))) {
            if (i >= numkeys) {
                numkeys += numkeys >> 1;
                keys = (HE **)SvGROW(keys_sv, numkeys * sizeof(HE*));
                numkeys = SvLEN(keys_sv) / sizeof(HE*);
            }
            keys[i++] = he;
        }
        qsort(keys, i, sizeof(HE *), fujson_fmt_hvcmp);
        while (i--) fujson_fmt_hvkv(aTHX_ ctx, hv, keys[i], &hestr);
        FREETMPS;

    } else {
        while ((he = hv_iternext(hv))) fujson_fmt_hvkv(aTHX_ ctx, hv, he, &hestr);
    }
    ctx->pretty--;
    if (hestr) fujson_fmt_indent(aTHX_ ctx);
    fustr_write_ch(ctx->out, '}');
}

static void fujson_fmt_obj(pTHX_ fujson_fmt_ctx *ctx, SV *rv, SV *obj) {
    dSP;

    GV *method = gv_fetchmethod_autoload(SvSTASH(obj), "TO_JSON", 0);
    if (!method) croak("unable to format '%s' object as JSON", HvNAME(SvSTASH(obj)));

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(rv);

    PUTBACK;
    call_sv((SV *)GvCV(method), G_SCALAR);
    SPAGAIN;

    /* JSON::XS describes this error as "surprisingly common"... I'd be
     * surprised indeed if it happens at all, but I suppose it can't hurt to
     * copy their check; this sounds like be a pain to debug otherwise. */
    if (SvROK(TOPs) && SvRV(TOPs) == obj)
        croak("%s::TO_JSON method returned same object as was passed instead of a new one", HvNAME(SvSTASH(obj)));

    obj = POPs;
    PUTBACK;
    fujson_fmt(aTHX_ ctx, obj);

    FREETMPS;
    LEAVE;
}

static void fujson_fmt(pTHX_ fujson_fmt_ctx *ctx, SV *val) {
    SvGETMAGIC(val);

    int r = fu_2bool(aTHX_ val);
    if (r != -1) { /* Must check SvISBOOL() before IOKp & POKp, because it implies both flags */
        if (r) fustr_write(ctx->out, "true", 4);
        else fustr_write(ctx->out, "false", 5);
    } else if (SvPOKp(val)) {
        fujson_fmt_str(aTHX_ ctx, SvPVX(val), SvCUR(val), SvUTF8(val));
    } else if (SvNOKp(val)) { /* Must check before IOKp, because integer conversion might have been lossy */
        NV nv = SvNV_nomg(val);
        if (isinfnan(nv)) croak("unable to format floating point NaN or Inf as JSON");
        /* XXX: Cpanel::JSON::XS appears to always append a ".0" for round numbers, other modules do not. */
        /* XXX#2: This doesn't support quadmath. Makefile.PL checks for that */
        fustr_reserve(ctx->out, NV_DIG+1);
        Gconvert(nv, NV_DIG, 0, ctx->out->cur);
        ctx->out->cur += strlen(ctx->out->cur);
    } else if (SvIOKp(val)) {
        fujson_fmt_int(aTHX_ ctx, val);
    } else if (SvROK(val)) {
        /* Simply consider every reference a form of nesting. TO_JSON may
         * return a scalar, but it may also return another TO_JSON object and
         * cause a stack overflow that way. */
        if (--ctx->depth == 0) croak("max_depth exceeded while formatting JSON");
        SV *rv = SvRV(val);
        SvGETMAGIC(rv);
        if (UNLIKELY(SvOBJECT(rv))) fujson_fmt_obj(aTHX_ ctx, val, rv);
        else if (SvTYPE(rv) == SVt_PVHV) fujson_fmt_hv(aTHX_ ctx, (HV *)rv);
        else if (SvTYPE(rv) == SVt_PVAV) fujson_fmt_av(aTHX_ ctx, (AV *)rv);
        else croak("unable to format reference '%s' as JSON", SvPV_nolen(val));
        ctx->depth++;
    } else if (!SvOK(val)) {
        fustr_write(ctx->out, "null", 4);
    } else {
        croak("unable to format unknown value '%s' as JSON", SvPV_nolen(val));
    }
}


static SV *fujson_fmt_xs(pTHX_ I32 ax, I32 argc, SV *val) {
    I32 i = 1;
    int encutf8 = 0;
    char *arg;
    SV *r;
    fustr out;
    fujson_fmt_ctx ctx;

    out.maxlen = 0;
    ctx.out = &out;
    ctx.depth = 0;
    ctx.pretty = INT_MIN;
    ctx.canon = 0;
    while (i < argc) {
        arg = SvPV_nolen(ST(i));
        i++;
        if (i == argc) croak("Odd name/value argument for json_format()");
        r = ST(i);
        i++;

        if (strcmp(arg, "canonical") == 0) ctx.canon = SvPVXtrue(r);
        else if (strcmp(arg, "pretty") == 0) ctx.pretty = SvPVXtrue(r) ? 0 : INT_MIN;
        else if (strcmp(arg, "utf8") == 0) encutf8 = SvPVXtrue(r);
        else if (strcmp(arg, "max_size") == 0) out.maxlen = SvUV(r);
        else if (strcmp(arg, "max_depth") == 0) ctx.depth = SvUV(r);
        else croak("Unknown flag: '%s'", arg);
    }
    if (out.maxlen == 0) out.maxlen = 1<<30;
    if (ctx.depth == 0) ctx.depth = 512;

    fustr_init(&out, sv_newmortal(), out.maxlen);
    fujson_fmt(aTHX_ &ctx, val);
    if (ctx.pretty >= 0) fustr_write_ch(&out, '\n');
    r = fustr_done(&out);
    if (!encutf8) SvUTF8_on(r);
    return r;
}
