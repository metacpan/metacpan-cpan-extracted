typedef struct {
    const unsigned char *buf;
    const unsigned char *end;
    UV depth;
    int allow_control;
} fujson_parse_ctx;

static SV *fujson_parse(pTHX_ fujson_parse_ctx *);

static void fujson_parse_ws(pTHX_ fujson_parse_ctx *ctx) {
    unsigned char x;
    while (ctx->buf < ctx->end) {
        x = *ctx->buf;
        if (!(x == 0x09 || x == 0x0a || x == 0x0d || x == 0x20)) break;
        ctx->buf++;
    }
}

static inline int fujson_parse_string_escape(pTHX_ fujson_parse_ctx *ctx, fustr *r) {
    unsigned int n, s;
    ctx->buf++; /* '\\' */
    if (UNLIKELY(ctx->buf == ctx->end)) return 1;
    switch (*(ctx->buf++)) {
        case '"': *(r->cur++) = '\"'; break;
        case '\\':*(r->cur++) = '\\'; break;
        case '/': *(r->cur++) = '/';  break; /* We don't escape this one */
        case 'b': if (!ctx->allow_control) return 1; *(r->cur++) = 0x08; break;
        case 't': *(r->cur++) = 0x09; break;
        case 'n': *(r->cur++) = 0x0a; break;
        case 'f': if (!ctx->allow_control) return 1; *(r->cur++) = 0x0c; break;
        case 'r': *(r->cur++) = 0x0d; break;
        case 'u':
            /* (awful code adapted from ncdu) */
#define h4(b) (fu_hexdig((b)[0])<<12) + (fu_hexdig((b)[1])<<8) + (fu_hexdig((b)[2])<<4) + fu_hexdig((b)[3])
            if (ctx->end - ctx->buf < 4) return 1;
            n = h4(ctx->buf);
            if (n >= 0x10000 || (n & 0xfc00) == 0xdc00) return 1;
            ctx->buf += 4;
            if ((n & 0xfc00) == 0xd800) { /* high surrogate */
                if (ctx->end - ctx->buf < 6) return 1;
                if (ctx->buf[0] != '\\' || ctx->buf[1] != 'u') return 1;
                s = h4(ctx->buf+2);
                if (s >= 0x10000 || (s & 0xfc00) != 0xdc00) return 1;
                n = 0x10000 + (((n & 0x03ff) << 10) | (s & 0x03ff));
                ctx->buf += 6;
            }
            if (!ctx->allow_control &&
                    (n <= 8 || n == 0x0b || n == 0x0c || (n >= 0x0e && n <= 0x1f) || n == 0x7f))
                return 1;
            r->cur = (char *)uvchr_to_utf8((U8 *)r->cur, n);
            if (n >= 0x80) r->setutf8 = 1;
            break;
#undef h4
        default:
            return 1;
    }
    return 0;
}

static int fujson_parse_string_buf(pTHX_ fujson_parse_ctx *ctx, fustr *r) {
    size_t len;
    unsigned char x;
    ctx->buf++; /* '"' */
    while (true) {
        fustr_reserve(r, 4);
        if (UNLIKELY(ctx->buf == ctx->end)) return 1;
        x = *ctx->buf;
        if (UNLIKELY(x == '"')) {
            ctx->buf++;
            return 0;
        } else if (UNLIKELY(x == '\\')) {
            if (fujson_parse_string_escape(aTHX_ ctx, r)) return 1;
        } else if (x >= 0x80) {
            if (UNLIKELY((len = isC9_STRICT_UTF8_CHAR(ctx->buf, ctx->end)) == 0)) return 1;
            memcpy(r->cur, ctx->buf, len);
            r->cur += len;
            ctx->buf += len;
            r->setutf8 = 1;
        } else if (x >= 0x20) {
            *(r->cur++) = x;
            ctx->buf++;
        } else return 1;
    }
}

static SV *fujson_parse_string(pTHX_ fujson_parse_ctx *ctx) {
    fustr r;
    fustr_init(&r, NULL, SIZE_MAX);
    if (fujson_parse_string_buf(aTHX_ ctx, &r)) {
        if (r.sv) SvREFCNT_dec(r.sv);
        return NULL;
    } else {
        return fustr_done(&r);
    }
}

/* Validate JSON grammar of a number, increments ctx->buf to the end of the
 * number and returns -1 on error, 0 if it's an int, 1 for floats. */
static int fujson_parse_number_grammar(fujson_parse_ctx *ctx) {
    int ret = 0;
    if (*ctx->buf == '-') ctx->buf++;
    if (ctx->buf == ctx->end) return -1;
    if (*ctx->buf == '0' && (ctx->buf+1 == ctx->end ||
                !(ctx->buf[1] == '.' || ctx->buf[1] == 'e' || ctx->buf[1] == 'E'))) {
        /* rfc8259 permits "-0", so we'll not check for that */
        ctx->buf++;
        return 0;
    }
#define DIG1 \
    if (ctx->buf == ctx->end || *ctx->buf < '0' || *ctx->buf > '9') return -1; \
    ctx->buf++; \
    while (ctx->buf != ctx->end && *ctx->buf >= '0' && *ctx->buf <= '9') ctx->buf++;

    /* int part */
    DIG1;
    /* decimal part */
    if (ctx->buf != ctx->end && *ctx->buf == '.') {
        ret = 1;
        ctx->buf++;
        DIG1;
    }
    /* exponent */
    if (ctx->buf != ctx->end && (*ctx->buf == 'e' || *ctx->buf == 'E')) {
        ret = 1;
        ctx->buf++;
        if (ctx->buf == ctx->end) return -1;
        if (*ctx->buf == '+' || *ctx->buf == '-') ctx->buf++;
        DIG1;
    }

#undef DIG1
    return ret;
}

static SV *fujson_parse_number(pTHX_ fujson_parse_ctx *ctx) {
    const unsigned char *start = ctx->buf;
    int isnum = fujson_parse_number_grammar(ctx);
    if (isnum == -1) return NULL;

    UV uv;
    const char *end = (const char *)ctx->buf;
    /* grok_atoUV() in this context can only return false on overflow */
    if (!isnum && grok_atoUV((const char *)(*start == '-' ? start+1 : start), &uv, &end)) {
        if (*start != '-') return newSVuv(uv);
        if (uv <= ((UV)IV_MAX)+1) return newSViv(-uv);
    }

    /* floating point or overflowed integer, might lose precision */
    NV val;
    my_atof3((const char *)start, &val, ctx->buf - start); /* this function is not documented to be public... */
    return newSVnv(val);
}

static SV *fujson_parse_array(pTHX_ fujson_parse_ctx *ctx) {
    AV *av = newAV();
    SV *r;
    if (--ctx->depth == 0) return NULL;
    ctx->buf++; /* '[' */
    fujson_parse_ws(aTHX_ ctx);
    if (ctx->buf == ctx->end) goto err;
    if (*ctx->buf == ']') goto done;
    while (true) {
        if (!(r = fujson_parse(aTHX_ ctx))) goto err;
        av_push_simple(av, r);
        fujson_parse_ws(aTHX_ ctx);
        if (ctx->buf == ctx->end) goto err;
        if (*ctx->buf == ']') goto done;
        if (*ctx->buf != ',') goto err;
        ctx->buf++;
    }
done:
    ctx->buf++; /* ']' */
    ctx->depth++;
    return newRV_noinc((SV *)av);
err:
    SvREFCNT_dec((SV *)av);
    return NULL;
}

static SV *fujson_parse_obj(pTHX_ fujson_parse_ctx *ctx) {
    HV *hv = newHV();
    SV *val;
    char *keystart;
    UV keyhash;
    fustr key;
    fustr_init(&key, NULL, SIZE_MAX);

    if (--ctx->depth == 0) return NULL;
    ctx->buf++; /* '{' */
    fujson_parse_ws(aTHX_ ctx);
    if (ctx->buf == ctx->end) goto err;
    if (*ctx->buf == '}') goto done;
    while (true) {
        /* key */
        if (*ctx->buf != '"') goto err;
        if (fujson_parse_string_buf(aTHX_ ctx, &key)) goto err;
        keystart = fustr_start(&key);
        if (key.setutf8) keyhash = 0;
        else PERL_HASH(keyhash, keystart, key.cur - keystart);
        if (hv_common(hv, NULL, keystart, key.cur - keystart, key.setutf8, HV_FETCH_ISEXISTS, NULL, keyhash)) goto err;

        /* ':' */
        fujson_parse_ws(aTHX_ ctx);
        if (ctx->buf == ctx->end) goto err;
        if (*ctx->buf != ':') goto err;
        ctx->buf++;

        /* value */
        if (!(val = fujson_parse(aTHX_ ctx))) goto err;
        hv_common(hv, NULL, keystart, key.cur - keystart, key.setutf8, HV_FETCH_ISSTORE|HV_FETCH_JUST_SV, val, keyhash);
        key.cur = keystart;
        key.setutf8 = 0;

        fujson_parse_ws(aTHX_ ctx);
        if (ctx->buf == ctx->end) goto err;
        if (*ctx->buf == '}') goto done;
        if (*ctx->buf != ',') goto err;
        ctx->buf++;
        fujson_parse_ws(aTHX_ ctx);
    }
done:
    if (key.sv) SvREFCNT_dec(key.sv);
    ctx->buf++; /* '}' */
    ctx->depth++;
    return newRV_noinc((SV *)hv);
err:
    if (key.sv) SvREFCNT_dec(key.sv);
    SvREFCNT_dec((SV *)hv);
    return NULL;
}

static SV *fujson_parse(pTHX_ fujson_parse_ctx *ctx) {
    fujson_parse_ws(aTHX_ ctx);
    if (ctx->buf == ctx->end) return NULL;
    switch (*ctx->buf) {
        case '"': return fujson_parse_string(aTHX_ ctx);
        case '{': return fujson_parse_obj(aTHX_ ctx);
        case '[': return fujson_parse_array(aTHX_ ctx);
        case 't':
            if (ctx->end - ctx->buf < 4) return NULL;
            if (memcmp(ctx->buf, "true", 4) != 0) return NULL;
            ctx->buf += 4;
            return newSV_true();
        case 'f':
            if (ctx->end - ctx->buf < 5) return NULL;
            if (memcmp(ctx->buf, "false", 5) != 0) return NULL;
            ctx->buf += 5;
            return newSV_false();
        case 'n':
            if (ctx->end - ctx->buf < 4) return NULL;
            if (memcmp(ctx->buf, "null", 4) != 0) return NULL;
            ctx->buf += 4;
            return newSV(0);
        default:
            if (*ctx->buf == '-' || (*ctx->buf >= '0' && *ctx->buf <= '9'))
                return fujson_parse_number(aTHX_ ctx);
    }
    return NULL;
}

static SV *fujson_parse_xs(pTHX_ I32 ax, I32 argc, SV *val) {
    I32 i = 1;
    char *arg;
    SV *r;
    SV *offset = NULL;
    UV maxlen = 0;
    int decutf8 = 0;
    STRLEN buflen;
    fujson_parse_ctx ctx;

    ctx.depth = 0;
    ctx.allow_control = 0;
    while (i < argc) {
        arg = SvPV_nolen(ST(i));
        i++;
        if (i == argc) croak("Odd name/value argument for json_parse()");
        r = ST(i);
        i++;

        if (strcmp(arg, "utf8") == 0) decutf8 = SvTRUEx(r);
        else if (strcmp(arg, "max_size") == 0) maxlen = SvUV(r);
        else if (strcmp(arg, "max_depth") == 0) ctx.depth = SvUV(r);
        else if (strcmp(arg, "allow_control") == 0) ctx.allow_control = SvTRUE(r);
        else if (strcmp(arg, "offset") == 0) offset = r;
        else croak("Unknown flag: '%s'", arg);
    }
    if (maxlen == 0) maxlen = 1<<30;
    if (ctx.depth == 0) ctx.depth = 512;

    arg = decutf8 ? SvPVbyte(val, buflen) : SvPVutf8(val, buflen);
    ctx.buf = (const unsigned char *)arg;
    ctx.end = ctx.buf + buflen;

    if (offset) {
        if (!SvROK(offset)) croak("Offset must be a reference to a scalar");
        offset = SvRV(offset);
        if (!looks_like_number(offset) || SvIV(offset) < 0) croak("Offset must be a positive integer");
        if (SvUV(offset) >= buflen) croak("Offset too large");
        ctx.buf += SvUV(offset);
        if ((UV)(ctx.end - ctx.buf) > maxlen) ctx.end = ctx.buf + maxlen;

    } else if ((UV)(ctx.end - ctx.buf) > maxlen)
        croak("Input string is larger than max_size");

    r = fujson_parse(aTHX_ &ctx);
    if (!r) croak("JSON parsing failed at offset %"UVuf, (UV)((char *)ctx.buf - arg));

    fujson_parse_ws(aTHX_ &ctx);
    if (offset) {
        if (ctx.buf == ctx.end) sv_set_undef(offset);
        else SvUV_set(offset, (UV)((char *)ctx.buf - arg));
    } else if (ctx.buf != ctx.end) {
        SvREFCNT_dec(r);
        croak("garbage after JSON value at offset %"UVuf, (UV)((char *)ctx.buf - arg));
    }

    return sv_2mortal(r);
}
