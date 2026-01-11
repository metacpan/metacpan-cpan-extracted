#define FCGI_BEGIN_REQUEST       1
#define FCGI_ABORT_REQUEST       2
#define FCGI_END_REQUEST         3
#define FCGI_PARAMS              4
#define FCGI_STDIN               5
#define FCGI_STDOUT              6
#define FCGI_STDERR              7
#define FCGI_DATA                8
#define FCGI_GET_VALUES          9
#define FCGI_GET_VALUES_RESULT  10
#define FCGI_UNKNOWN_TYPE       11

#define FUFE_OK     0
#define FUFE_EOF   -1  /* unexpected protocol-level EOF */
#define FUFE_IO    -2
#define FUFE_PROTO -3
#define FUFE_PLEN  -4
#define FUFE_CLEN  -5
#define FUFE_ABORT -6  /* explicit abort or client-level EOF */
#define FUFE_NOREQ -7  /* protocol-level EOF before we received anything */
#define FUFE_SEND  -8  /* error in send() */

#define FUFCGI_MAX_DATA 65535

typedef struct {
    SV *self;
    int fd;
    int maxproc;
    int keepconn;

    int reqid;
    HV *headers;
    HV *params;

    /* Single buffer for reading & writing, we only do one thing at a time */
    char buf[8 + FUFCGI_MAX_DATA + 255]; /* fits a maximum-length fcgi record */
    int len; /* total number of bytes in the buffer */
    int off; /* number of bytes consumed */
} fufcgi;

typedef struct {
    unsigned char type;
    unsigned short id;
    int len;
    char *data;
} fufcgi_rec;


/* Incremental param length & name parser */
typedef enum {
    FUFC_INIT, FUFC_L1, FUFC_L2, FUFC_L3,
    FUFC_V0, FUFC_V1, FUFC_V2, FUFC_V3,
    FUFC_N0, FUFC_NX
} fufcgi_paramstate;

typedef struct {
    int namelen;
    int vallen;
    int state;
    int namerd;
    char *name;
    char namebuf[128]; /* We don't support longer param names */
} fufcgi_param;

/* Returns NULL on error or ptr to value (or 'end' if !done) */
static char *fufcgi_param_parse(fufcgi_param *p, char *buf, char *end) {
    while (buf < end) {
        switch (p->state) {
            case FUFC_INIT:
                p->vallen = p->namerd = 0;
                if (*buf & 0x80) {
                    p->namelen = (*buf & 0x1f) << 24;
                    p->state = FUFC_L1;
                } else {
                    p->namelen = *buf;
                    p->state = FUFC_V0;
                }
                break;
            case FUFC_L1:
                p->namelen |= ((unsigned char)*buf) << 16;
                p->state = FUFC_L2;
                break;
            case FUFC_L2:
                p->namelen |= ((unsigned char)*buf) << 8;
                p->state = FUFC_L3;
                break;
            case FUFC_L3:
                p->namelen |= (unsigned char)*buf;
                p->state = FUFC_V0;
                if (p->namelen > (int)sizeof(p->namebuf)) return NULL;
                break;
            case FUFC_V0:
                if (*buf & 0x80) {
                    p->vallen = (*buf & 0x1f) << 24;
                    p->state = FUFC_V1;
                } else {
                    p->vallen = *buf;
                    p->state = p->namelen ? FUFC_N0 : FUFC_INIT;
                }
                break;
            case FUFC_V1:
                p->vallen |= ((unsigned char)*buf) << 16;
                if (p->vallen) return NULL; /* Let's just disallow param values > 64 KiB */
                p->state = FUFC_V2;
                break;
            case FUFC_V2:
                p->vallen |= ((unsigned char)*buf) << 8;
                p->state = FUFC_V3;
                break;
            case FUFC_V3:
                p->vallen |= (unsigned char)*buf;
                p->state = FUFC_N0;
                break;
            case FUFC_N0:
                if (p->namelen <= end - buf) {
                    p->name = buf;
                    p->state = FUFC_INIT;
                    return buf + p->namelen;
                } else {
                    p->name = p->namebuf;
                    p->name[0] = *buf;
                    p->namerd = 1;
                    p->state = FUFC_NX;
                }
                break;
            case FUFC_NX:
                p->name[p->namerd++] = *buf;
                if (p->namerd == p->namelen) {
                    p->state = FUFC_INIT;
                    return buf + 1;
                }
                break;
        }
        buf++;
    }
    return buf;
}

static int fufcgi_fill(fufcgi *ctx, int len) {
    if ((int)sizeof(ctx->buf) - ctx->off < len) {
        memmove(ctx->buf, ctx->buf+ctx->off, ctx->len - ctx->off);
        ctx->len -= ctx->off;
        ctx->off = 0;
    }
    while (ctx->len - ctx->off < len) {
        ssize_t r = read(ctx->fd, ctx->buf+ctx->len, sizeof(ctx->buf) - ctx->len);
        if (r <= 0) return r == 0 ? FUFE_EOF : FUFE_IO;
        ctx->len += r;
    }
    return FUFE_OK;
}

static int fufcgi_read_record(fufcgi *ctx, fufcgi_rec *rec) {
    int r;
    if ((r = fufcgi_fill(ctx, 8)) != FUFE_OK) return r;

    if (ctx->buf[ctx->off] != 1) return FUFE_PROTO; /* version */
    rec->type = ctx->buf[ctx->off+1];
    rec->id = fu_frombeU(16, ctx->buf+ctx->off+2);
    rec->len = fu_frombeU(16, ctx->buf+ctx->off+4);
    int pad = (unsigned char)ctx->buf[ctx->off+6];
    ctx->off += 8;

    if ((r = fufcgi_fill(ctx, rec->len + pad)) != FUFE_OK) return r;
    rec->data = ctx->buf + ctx->off;
    ctx->off += rec->len + pad;
    return FUFE_OK;
}

/* Unbuffered write of a single record, first 8 bytes of 'buf' are filled out
 * by this function, record contents must come after. */
static int fufcgi_write_record(fufcgi *ctx, fufcgi_rec *hdr, char *buf) {
    buf[0] = 1;
    buf[1] = hdr->type;
    fu_tobeU(16, buf+2, hdr->id);
    fu_tobeU(16, buf+4, hdr->len);
    buf[6] = 0;
    buf[7] = 0;
    int len = hdr->len + 8;
    while (len > 0) {
        int r = send(ctx->fd, buf, len, MSG_NOSIGNAL);
        if (r <= 0) return FUFE_SEND;
        buf += r;
        len -= r;
    }
    return FUFE_OK;
}

static int fufcgi_handle_values(fufcgi *ctx, fufcgi_rec *rec, char *buf) {
    int reslen = 8;
    char *param = rec->data;
    char *end = rec->data + rec->len;
    fufcgi_param p;
    p.state = FUFC_INIT;

    while (param < end) {
        if ((param = fufcgi_param_parse(&p, param, end)) == NULL) return FUFE_PLEN;
        if (p.state != FUFC_INIT) return FUFE_PROTO;
        if (p.vallen > end - param) return FUFE_PROTO;
        if (reslen >= 100) return FUFE_PROTO; /* implies requested params were duplicated */

        if (p.namelen == 14 && memcmp(p.name, "FCGI_MAX_CONNS", 14) == 0) {
            memcpy(buf+reslen, "\x0e\0FCGI_MAX_CONNS", 16);
            int l = sprintf(buf+reslen+16, "%d", ctx->maxproc);
            buf[reslen+1] = l;
            reslen += 16 + l;

        } else if (p.namelen == 13 && memcmp(p.name, "FCGI_MAX_REQS", 13) == 0) {
            memcpy(buf+reslen, "\x0d\0FCGI_MAX_REQS", 15);
            int l = sprintf(buf+reslen+15, "%d", ctx->maxproc);
            buf[reslen+1] = l;
            reslen += 15 + l;

        } else if (p.namelen == 15 && memcmp(p.name, "FCGI_MPXS_CONNS", 15) == 0) {
            memcpy(buf+reslen, "\x0f\1FCGI_MPXS_CONNS0", 18);
            reslen += 18;
        }

        param += p.vallen;
    }
    rec->type = FCGI_GET_VALUES_RESULT;
    rec->len = reslen - 8;
    return fufcgi_write_record(ctx, rec, buf);
}

/* Read a PARAMS/STDIN/ABORT record corresponding to the current id, starts
 * reading a new request if id=0. */
static int fufcgi_read_req_record(fufcgi *ctx, fufcgi_rec *rec) {
    int r;
    char tmp[128]; /* Large enough for a FCGI_GET_VALUES_RESULT */
    while (1) {
        if ((r = fufcgi_read_record(ctx, rec)) != FUFE_OK) return r == FUFE_EOF && ctx->len == 0 ? FUFE_NOREQ : r;

        switch (rec->type) {
            case FCGI_PARAMS:
            case FCGI_STDIN:
            case FCGI_ABORT_REQUEST:
                if (rec->id != ctx->reqid) return FUFE_PROTO;
                return FUFE_OK;
            case FCGI_BEGIN_REQUEST:
                if (!rec->id || rec->id == ctx->reqid) return FUFE_PROTO;
                if (rec->len != 8) return FUFE_PROTO;
                ctx->keepconn = rec->data[2] & 1;
                if (rec->data[0] != 0 || rec->data[1] != 1) { /* FCGI_RESPONDER */
                    memcpy(tmp+8, "\0\0\0\0\3\0\0\0", 8); /* FCGI_UNKNOWN_ROLE */
                    rec->type = FCGI_END_REQUEST;
                    rec->len = 8;
                    if ((r = fufcgi_write_record(ctx, rec, tmp)) != FUFE_OK) return r;
                    if (!ctx->keepconn) return FUFE_EOF;
                } else if (ctx->reqid) {
                    memcpy(tmp+8, "\0\0\0\0\1\0\0\0", 8); /* FCGI_CANT_MPX_CONN */
                    rec->type = FCGI_END_REQUEST;
                    rec->len = 8;
                    if ((r = fufcgi_write_record(ctx, rec, tmp)) != FUFE_OK) return r;
                    if (!ctx->keepconn) return FUFE_EOF;
                } else {
                    ctx->reqid = rec->id;
                }
                break;
            case FCGI_GET_VALUES:
                if (rec->id) return FUFE_PROTO;
                if ((r = fufcgi_handle_values(ctx, rec, tmp)) != FUFE_OK) return r;
                break;
            default:
                memset(tmp+8, 0, 8);
                tmp[8] = rec->type;
                rec->type = FCGI_UNKNOWN_TYPE;
                rec->len = 8;
                rec->id = 0;
                if ((r = fufcgi_write_record(ctx, rec, tmp)) != FUFE_OK) return r;
                break;
        }
    }
}

static int fufcgi_read_params(pTHX_ fufcgi *ctx, fufcgi_rec *rec) {
    int r;
    fufcgi_param p;
    p.state = FUFC_INIT;

    SV *valsv = NULL;
    char *val = NULL;
    int valleft = 0;

    while (1) {
        if ((r = fufcgi_read_req_record(ctx, rec)) != FUFE_OK) return r;
        if (rec->type == FCGI_ABORT_REQUEST) return FUFE_OK;
        if (rec->type != FCGI_PARAMS) return FUFE_PROTO;
        if (rec->len == 0) return p.state != FUFC_INIT || valleft ? FUFE_PROTO : FUFE_OK;

        char *buf = rec->data;
        char *end = rec->data + rec->len;
        while (buf < end) {
            if (valleft) {
                r = valleft > end - buf ? end - buf : valleft;
                if (val) {
                    memcpy(val, buf, r);
                    val += r;
                }
                valleft -= r;
                buf += r;
                if (val && !valleft) {
                    *val = 0;
                    SvCUR_set(valsv, p.vallen);
                }
                continue;
            }
            if ((buf = fufcgi_param_parse(&p, buf, end)) == NULL) return FUFE_PLEN;
            if (p.state != FUFC_INIT) break;

            valsv = NULL;
            val = NULL;
            valleft = p.vallen;

            /* https://www.rfc-editor.org/rfc/rfc3875 */

            /* Request header */
            if (p.namelen > 5 && memcmp(p.name, "HTTP_", 5) == 0) {
                p.namelen -= 5;
                p.name += 5;
                for (r=0; r<p.namelen; r++)
                    p.name[r] = p.name[r] == '_' ? '-' : p.name[r] >= 'A' && p.name[r] <= 'Z' ? p.name[r] | 0x20 : p.name[r];
                if (!(p.namelen == 14 && memcmp(p.name, "content-length", 14) == 0)
                        && !(p.namelen == 12 && memcmp(p.name, "content-type", 12) == 0)) {
                    valsv = newSV(p.vallen+1);
                    hv_store(ctx->headers, p.name, p.namelen, valsv, 0);
                }

            } else if (p.namelen == 14 && memcmp(p.name, "CONTENT_LENGTH", 14) == 0) {
                valsv = newSV(p.vallen+1);
                hv_stores(ctx->headers, "content-length", valsv);

            } else if (p.namelen == 12 && memcmp(p.name, "CONTENT_TYPE", 12) == 0) {
                valsv = newSV(p.vallen+1);
                hv_stores(ctx->headers, "content-type", valsv);

            } else if (p.namelen == 11 && memcmp(p.name, "REMOTE_ADDR", 11) == 0) {
                valsv = newSV(p.vallen+1);
                hv_stores(ctx->params, "ip", valsv);

            } else if (p.namelen == 12 && memcmp(p.name, "QUERY_STRING", 12) == 0) {
                valsv = newSV(p.vallen+1);
                hv_stores(ctx->params, "qs", valsv);

            } else if (p.namelen == 14 && memcmp(p.name, "REQUEST_METHOD", 14) == 0) {
                valsv = newSV(p.vallen+1);
                hv_stores(ctx->params, "method", valsv);

            /* Not in rfc3875; there's no standardized parameter for the URI,
             * but every FastCGI-capable web server includes this one */
            } else if (p.namelen == 11 && memcmp(p.name, "REQUEST_URI", 11) == 0) {
                valsv = newSV(p.vallen+1);
                hv_stores(ctx->params, "path", valsv);

            } else { /* ignore */ }

            if (valsv) {
                SvPOK_only(valsv);
                val = SvPVX(valsv);
                *val = 0; /* in case vallen = 0 */
            }
        }
    }
}

static int fufcgi_read_req(pTHX_ fufcgi *ctx, SV *headers, SV *params) {
    if (ctx->reqid) fu_confess("Invalid attempt to read FastCGI request before finishing the previous one");
    fufcgi_rec rec;
    int r;

    ctx->off = ctx->len = 0;
    ctx->headers = (HV *)SvRV(headers);
    ctx->params = (HV *)SvRV(params);
    if ((r = fufcgi_read_params(aTHX_ ctx, &rec)) != FUFE_OK) return r;

    int stdinlen = 0;
    SV **contentlength = hv_fetchs(ctx->headers, "content-length", 0);
    if (contentlength && *contentlength) {
        UV uv = 0;
        char *v = SvPV_nolen(*contentlength);
        if (*v && !grok_atoUV(v, &uv, NULL)) return FUFE_CLEN;
        if (uv >= INT_MAX) return FUFE_CLEN;
        stdinlen = uv;
    }

    SV *sv = newSV(stdinlen+1);
    hv_stores(ctx->params, "body", sv);
    SvPOK_only(sv);
    char *stdinbuf = SvPVX(sv);
    int stdinleft = stdinlen;

    while (1) {
        if (rec.type == FCGI_ABORT_REQUEST) return FUFE_ABORT;
        else if (rec.type == FCGI_PARAMS) {
            if (rec.len != 0) return FUFE_PROTO;
        } else if (rec.type == FCGI_STDIN) {
            if (rec.len == 0) {
                *stdinbuf = 0;
                SvCUR_set(sv, stdinlen - stdinleft);
                return stdinleft == 0 ? FUFE_OK : FUFE_ABORT;
            }
            if (rec.len > stdinleft) return FUFE_PROTO;
            memcpy(stdinbuf, rec.data, rec.len);
            stdinbuf += rec.len;
            stdinleft -= rec.len;
        } else {
            return FUFE_PROTO;
        }
        if ((r = fufcgi_read_req_record(ctx, &rec)) != FUFE_OK) return r;
    }
}

static void fufcgi_flush(pTHX_ fufcgi *ctx) {
    fufcgi_rec hdr;
    if (ctx->len > 0) {
        hdr.len = ctx->len;
        hdr.type = FCGI_STDOUT;
        hdr.id = ctx->reqid;
        if (fufcgi_write_record(ctx, &hdr, ctx->buf) != FUFE_OK)
            croak("%s\n", strerror(errno));
        ctx->len = 0;
    }
}

static void fufcgi_print(pTHX_ fufcgi *ctx, const char *buf, int len) {
    int r;
    while (len > 0) {
        r = len > FUFCGI_MAX_DATA - ctx->len ? FUFCGI_MAX_DATA - ctx->len : len;
        memcpy(ctx->buf+8+ctx->len, buf, r);
        ctx->len += r;
        len -= r;
        buf += r;
        if (ctx->len >= FUFCGI_MAX_DATA) fufcgi_flush(aTHX_ ctx);
    }
}

static void fufcgi_done(pTHX_ fufcgi *ctx) {
    fufcgi_rec hdr;
    fufcgi_flush(aTHX_ ctx);

    hdr.len = 0;
    hdr.type = FCGI_STDOUT;
    hdr.id = ctx->reqid;
    if (fufcgi_write_record(ctx, &hdr, ctx->buf) != FUFE_OK)
        croak("%s\n", strerror(errno));

    memcpy(ctx->buf+8, "\0\0\0\0\0\0\0\0", 8); /* FCGI_REQUEST_COMPLETE */
    hdr.type = FCGI_END_REQUEST;
    hdr.len = 8;
    if (fufcgi_write_record(ctx, &hdr, ctx->buf) != FUFE_OK)
        croak("%s\n", strerror(errno));

    ctx->reqid = ctx->len = ctx->off = 0;
}
