typedef struct fuxmlwr fuxmlwr;
struct fuxmlwr {
    SV *self;
    fuxmlwr *next, *prev;
    fustr out;
};

static fuxmlwr *fuxmlwr_tail = NULL;

static SV *fuxmlwr_new(pTHX) {
    fuxmlwr *wr = safemalloc(sizeof(*wr));
    wr->next = NULL;
    wr->prev = fuxmlwr_tail;
    if (fuxmlwr_tail) fuxmlwr_tail->next = wr;
    fuxmlwr_tail = wr;
    fustr_init(&wr->out, NULL, SIZE_MAX);
    return fu_selfobj(wr, "FU::XMLWriter");
}

static void fuxmlwr_destroy(pTHX_ fuxmlwr *wr) {
    if (fuxmlwr_tail == wr) fuxmlwr_tail = wr->next ? wr->next : wr->prev;
    if (wr->next) wr->next->prev = wr->prev;
    if (wr->prev) wr->prev->next = wr->next;
    if (wr->out.sv) SvREFCNT_dec(wr->out.sv);
    safefree(wr);
}


static void fuxmlwr_escape(pTHX_ fuxmlwr *wr, SV *sv) {
    if (SvROK(sv) && !SvAMAGIC(sv)) fu_confess("Invalid attempt to output bare reference");

    STRLEN len;
    const unsigned char *str = (unsigned char *)SvPV_const(sv, len);
    const unsigned char *tmp, *end = str + len;
    unsigned char x = 0;
    unsigned char *buf;
    int utf8 = SvUTF8(sv);

    while (str < end) {
        tmp = str;
        if (utf8) {
            while (tmp < end) {
                x = *tmp;
                if (x == '<' || x == '&' || x == '"') break;
                tmp++;
            }
        } else {
            while (tmp < end) {
                x = *tmp;
                if (x == '<' || x == '&' || x == '"' || x >= 0x80) break;
                tmp++;
            }
        }
        fustr_write(&wr->out, (const char *)str, tmp-str);
        if (tmp == end) return;
        switch (x) {
            case '<': fustr_write(&wr->out, "&lt;", 4); break;
            case '&': fustr_write(&wr->out, "&amp;", 5); break;
            case '"': fustr_write(&wr->out, "&quot;", 6); break;
            default:
                buf = (unsigned char *)fustr_write_buf(&wr->out, 2);
                buf[0] = 0xc0 | (x >> 6);
                buf[1] = 0x80 | (x & 0x3f);
                break;
        }
        str = tmp + 1;
    }
}


static int fuxmlwr_isnamechar(unsigned int x) {
    return (x|32)-'a' < 26 || x-'0' < 10 || x == '_' || x == ':' || x == '-';
}

// Validate a tag or attribute name. Pretty much /^[a-z0-9_:-]+$/i.
// This does not at all match with the XML and HTML standards, but this
// approach is simpler and catches the most important bugs anyway.
static void fuxmlwr_isname(const char *str) {
    const char *x = str;
    while (fuxmlwr_isnamechar(*x)) x++;
    if (*x || x == str) fu_confess("Invalid tag or attribute name: '%s'", str);
}


static void fuxmlwr_tag(pTHX_ fuxmlwr *wr, I32 ax, I32 offset, I32 argc, int selfclose, const char *tagname, int tagnamelen) {
    SV *key, *val;
    const char *keys, *lastkey = NULL;
    int isopen = 0;
    dSP;

    if (!selfclose && ((argc - offset) & 1) == 0) fu_confess("Invalid number of arguments");
    fustr_write_ch(&wr->out, '<');
    fustr_write(&wr->out, tagname, tagnamelen);

    while (offset < argc-1) {
        key = ST(offset);
        offset++;
        val = ST(offset);
        offset++;

        // Don't even try to stringify attribute names; non-string keys are always a bug.
        if (!SvPOK(key)) fu_confess("Non-string attribute");
        keys = SvPVX(key);

        SvGETMAGIC(val);
        /* TODO: Support boolean values */
        if (keys[0] == '+' && keys[1] == 0) {
            if (!SvOK(val)) {
                // ignore
            } else if (isopen) {
                fustr_write_ch(&wr->out, ' ');
                fuxmlwr_escape(aTHX_ wr, val);
            } else if (lastkey) {
                fustr_write_ch(&wr->out, ' ');
                fustr_write(&wr->out, lastkey, strlen(lastkey));
                fustr_write(&wr->out, "=\"", 2);
                fuxmlwr_escape(aTHX_ wr, val);
                isopen = 1;
            } else {
                fu_confess("Cannot use '+' as first attribute");
            }
        } else {
            if (isopen) {
                fustr_write_ch(&wr->out, '"');
                isopen = 0;
            }
            fuxmlwr_isname(keys);
            if (!SvOK(val)) {
                lastkey = keys;
            } else {
                fustr_write_ch(&wr->out, ' ');
                fustr_write(&wr->out, keys, SvCUR(key));
                fustr_write(&wr->out, "=\"", 2);
                fuxmlwr_escape(aTHX_ wr, val);
                isopen = 1;
            }
        }
    }

    if (isopen) fustr_write_ch(&wr->out, '"');

    if (offset < argc) {
        val = ST(offset);
        SvGETMAGIC(val);
    } else
        val = &PL_sv_undef;

    if (!SvOK(val)) { // undef
        fustr_write(&wr->out, " />", 3);
    } else if (SvROK(val) && strcmp(sv_reftype(SvRV(val), 0), "CODE") == 0) { // CODE ref
        fustr_write_ch(&wr->out, '>');
        PUSHMARK(SP);
        call_sv(val, G_VOID|G_DISCARD|G_NOARGS);
        fustr_write(&wr->out, "</", 2);
        fustr_write(&wr->out, tagname, tagnamelen);
        fustr_write_ch(&wr->out, '>');
    } else {
        fustr_write_ch(&wr->out, '>');
        fuxmlwr_escape(aTHX_ wr, val);
        fustr_write(&wr->out, "</", 2);
        fustr_write(&wr->out, tagname, tagnamelen);
        fustr_write_ch(&wr->out, '>');
    }
}
