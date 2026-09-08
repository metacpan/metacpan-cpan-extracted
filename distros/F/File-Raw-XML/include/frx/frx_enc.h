#ifndef FRX_ENC_H
#define FRX_ENC_H

/* The transcoder in front of the lexer, full profile only.
 *
 * XML 1.0 section 4.3.3 says every conforming processor accepts UTF-16,
 * and Latin-1 and US-ASCII are what the rest of the world declares. The
 * lexer stays a UTF-8 lexer: this step turns the caller's bytes into one
 * malloc'd UTF-8 buffer owned by the parse, and the only thing it shares
 * with the lexer is the offset map, so a refusal in a UTF-16 document
 * still names the byte the user can find with a hex editor. Anything
 * beyond these four is decision G's territory: the caller transcodes on
 * its side and says `encoding => 'UTF-8'`.
 *
 * Detection is XML 1.0 appendix F, in this order: a byte order mark; the
 * first four bytes for the `<?xm` pattern in each width; else UTF-8. A
 * UTF-8-compatible start is then told apart by peeking at the encoding
 * declaration's name, which is ASCII in every encoding this accepts, so
 * a document declaring iso-8859-1 is transcoded from it. The lexer
 * afterwards checks the declaration it parses against what was detected
 * (frx_lex.h): a BOM contradicted by the declaration is fatal, and so is
 * a UTF-16 document declaring anything but UTF-16. UCS-4 and EBCDIC are
 * detected and refused by name.
 *
 * The output is sized once from the bounds: UTF-16 to UTF-8 is at most
 * 1.5x, Latin-1 at most 2x, so max_bytes is checked on the input and the
 * output cannot exceed twice it.
 *
 * The map is one checkpoint per FRX_ENC_STEP input bytes recording the
 * matching output offset; mapping an output offset back re-walks from the
 * nearest checkpoint. The error path pays; the parse path does not.
 *
 * Under strict none of this runs: the 0.01 checks in frx_lex.h refuse
 * UTF-16 by BOM or first pair and every declared non-UTF-8 encoding.
 *
 * Needs frx_err.h, frx_utf8.h. */

enum {
    FRX_ENC_UTF8 = 0,
    FRX_ENC_UTF16LE,
    FRX_ENC_UTF16BE,
    FRX_ENC_LATIN1,
    FRX_ENC_ASCII,
    FRX_ENC_UNSUPPORTED             /* detected, refused by name */
};

#define FRX_ENC_STEP 4096

typedef struct frx_enc {
    int     kind;                   /* FRX_ENC_* */
    int     bom;                    /* bytes of byte order mark consumed from the input */
    int     override;               /* the caller named the encoding; the declaration is not checked */
    char   *out;                    /* malloc'd UTF-8; NULL when the input is used as it is */
    size_t  out_len;
    size_t *map;                    /* map[i] = output offset at input offset bom + i * FRX_ENC_STEP */
    size_t  n_map;
} frx_enc;

static const char *
frx_enc_name(int kind)
{
    switch (kind) {
    case FRX_ENC_UTF8:    return "UTF-8";
    case FRX_ENC_UTF16LE: return "UTF-16LE";
    case FRX_ENC_UTF16BE: return "UTF-16BE";
    case FRX_ENC_LATIN1:  return "ISO-8859-1";
    case FRX_ENC_ASCII:   return "US-ASCII";
    default:              return "unsupported";
    }
}

static int
frx_enc_ieq(const char *v, size_t n, const char *lit)
{
    size_t i;
    if (n != strlen(lit)) return 0;
    for (i = 0; i < n; i++) {
        unsigned char a = (unsigned char)v[i], b = (unsigned char)lit[i];
        if (a >= 'A' && a <= 'Z') a = (unsigned char)(a - 'A' + 'a');
        if (a != b) return 0;
    }
    return 1;
}

/* an encoding name, case-insensitively, to a kind; -1 when not one of ours.
 * The names are the IANA ones and their common aliases. */
static int
frx_enc_kind_by_name(const char *v, size_t n)
{
    if (frx_enc_ieq(v, n, "utf-8") || frx_enc_ieq(v, n, "utf8"))           return FRX_ENC_UTF8;
    if (frx_enc_ieq(v, n, "utf-16le"))                                       return FRX_ENC_UTF16LE;
    if (frx_enc_ieq(v, n, "utf-16be"))                                       return FRX_ENC_UTF16BE;
    if (frx_enc_ieq(v, n, "utf-16"))                                         return FRX_ENC_UTF16LE;   /* the endianness comes from the BOM */
    if (frx_enc_ieq(v, n, "iso-8859-1") || frx_enc_ieq(v, n, "iso_8859-1")
        || frx_enc_ieq(v, n, "latin1") || frx_enc_ieq(v, n, "l1"))           return FRX_ENC_LATIN1;
    if (frx_enc_ieq(v, n, "us-ascii") || frx_enc_ieq(v, n, "ascii")
        || frx_enc_ieq(v, n, "ansi_x3.4-1968"))                              return FRX_ENC_ASCII;
    return -1;
}

/* is the declared name consistent with what was detected? "utf-16" is
 * consistent with either endianness; "utf-16le" only with LE. */
static int
frx_enc_declared_matches(int kind, const char *v, size_t n)
{
    int d = frx_enc_kind_by_name(v, n);
    if (d < 0) return 0;
    if (d == kind) return 1;
    if (frx_enc_ieq(v, n, "utf-16") && (kind == FRX_ENC_UTF16LE || kind == FRX_ENC_UTF16BE)) return 1;
    return 0;
}

/* the encoding declaration's value, peeked from the first line of an
 * ASCII-compatible input: `<?xml ... encoding = "name"`; 0 when absent */
static int
frx_enc_peek_declaration(const unsigned char *in, size_t len, const char **v, size_t *n)
{
    size_t i = 0, limit = len < 256 ? len : 256;
    if (len < 6 || memcmp(in, "<?xml", 5) != 0 || !frx_is_s(in[5])) return 0;
    for (i = 5; i + 8 < limit; i++) {
        if (in[i] == '?' && in[i + 1] == '>') return 0;
        if (memcmp(in + i, "encoding", 8) == 0 && frx_is_s(in[i - 1])) {
            size_t j = i + 8;
            unsigned char q;
            size_t start;
            while (j < limit && frx_is_s(in[j])) j++;
            if (j >= limit || in[j] != '=') return 0;
            j++;
            while (j < limit && frx_is_s(in[j])) j++;
            if (j >= limit) return 0;
            q = in[j];
            if (q != '"' && q != '\'') return 0;
            start = ++j;
            while (j < limit && in[j] != q) j++;
            if (j >= limit) return 0;
            *v = (const char *)in + start;
            *n = j - start;
            return 1;
        }
    }
    return 0;
}

/* Appendix F. Fills e->kind and e->bom; a name the caller supplied wins
 * over everything. 0 on a refusal with err set (an unsupported family or
 * an unknown override). */
static int
frx_enc_detect(frx_enc *e, const unsigned char *in, size_t len, const char *override, frx_err *err)
{
    const char *v;
    size_t n;

    e->kind = FRX_ENC_UTF8;
    e->bom  = 0;
    e->override = 0;

    /* a BOM is consumed whatever else is decided */
    if (len >= 3 && in[0] == 0xEF && in[1] == 0xBB && in[2] == 0xBF) { e->kind = FRX_ENC_UTF8; e->bom = 3; }
    else if (len >= 4 && in[0] == 0 && in[1] == 0 && in[2] == 0xFE && in[3] == 0xFF)      { e->kind = FRX_ENC_UNSUPPORTED; }
    else if (len >= 4 && in[0] == 0xFF && in[1] == 0xFE && in[2] == 0 && in[3] == 0)      { e->kind = FRX_ENC_UNSUPPORTED; }
    else if (len >= 2 && in[0] == 0xFE && in[1] == 0xFF) { e->kind = FRX_ENC_UTF16BE; e->bom = 2; }
    else if (len >= 2 && in[0] == 0xFF && in[1] == 0xFE) { e->kind = FRX_ENC_UTF16LE; e->bom = 2; }

    if (override) {
        int k = frx_enc_kind_by_name(override, strlen(override));
        if (k < 0) return (frx_err_set(err, FRX_E_ENCODING, 0, "the encoding named by the caller is not one this parser supports"), 0);
        if (frx_enc_ieq(override, strlen(override), "utf-16") && e->bom == 0)
            k = FRX_ENC_UTF16BE;                    /* RFC 2781: no BOM, big-endian */
        if (e->kind == FRX_ENC_UNSUPPORTED) e->kind = k;
        else if (e->bom && k != e->kind && !(e->kind == FRX_ENC_UTF16LE && frx_enc_ieq(override, strlen(override), "utf-16")))
            return (frx_err_set(err, FRX_E_ENCODING, 0, "the encoding named by the caller contradicts the byte order mark"), 0);
        else e->kind = k;
        e->override = 1;
        return 1;
    }

    if (e->kind == FRX_ENC_UNSUPPORTED)
        return (frx_err_set(err, FRX_E_ENCODING, 0, "UCS-4 is not supported; transcode to UTF-8 or UTF-16 first"), 0);
    if (e->bom) return 1;

    /* no BOM: the first four bytes */
    if (len >= 4) {
        if (in[0] == 0 && in[1] == '<' && in[2] == 0 && in[3] == '?')      { e->kind = FRX_ENC_UTF16BE; return 1; }
        if (in[0] == '<' && in[1] == 0 && in[2] == '?' && in[3] == 0)      { e->kind = FRX_ENC_UTF16LE; return 1; }
        if (in[0] == 0 && in[1] == 0 && in[2] == 0 && in[3] == '<')
            return (frx_err_set(err, FRX_E_ENCODING, 0, "UCS-4 is not supported; transcode to UTF-8 or UTF-16 first"), 0);
        if (in[0] == '<' && in[1] == 0 && in[2] == 0 && in[3] == 0)
            return (frx_err_set(err, FRX_E_ENCODING, 0, "UCS-4 is not supported; transcode to UTF-8 or UTF-16 first"), 0);
        if (in[0] == 0x4C && in[1] == 0x6F && in[2] == 0xA7 && in[3] == 0x94)
            return (frx_err_set(err, FRX_E_ENCODING, 0, "EBCDIC is not supported; transcode to UTF-8 first"), 0);
    }
    /* UTF-8 compatible: a declaration may name Latin-1 or ASCII */
    if (frx_enc_peek_declaration(in, len, &v, &n)) {
        int k = frx_enc_kind_by_name(v, n);
        if (k == FRX_ENC_LATIN1 || k == FRX_ENC_ASCII) e->kind = k;
        /* anything else is the lexer's to judge against UTF-8 */
    }
    return 1;
}

/* one scalar from the input at pos under kind; returns bytes consumed, 0
 * on a malformed unit with *what set */
static size_t
frx_enc_step(int kind, const unsigned char *in, size_t len, size_t pos,
             unsigned long *cp, const char **what)
{
    switch (kind) {
    case FRX_ENC_UTF16LE:
    case FRX_ENC_UTF16BE: {
        unsigned u, lo;
        if (len - pos < 2) { *what = "an odd trailing byte in UTF-16 input"; return 0; }
        u = kind == FRX_ENC_UTF16LE ? (unsigned)(in[pos] | (in[pos + 1] << 8))
                                    : (unsigned)((in[pos] << 8) | in[pos + 1]);
        if (u >= 0xDC00 && u <= 0xDFFF) { *what = "an unpaired low surrogate in UTF-16 input"; return 0; }
        if (u >= 0xD800 && u <= 0xDBFF) {
            if (len - pos < 4) { *what = "a high surrogate with nothing after it in UTF-16 input"; return 0; }
            lo = kind == FRX_ENC_UTF16LE ? (unsigned)(in[pos + 2] | (in[pos + 3] << 8))
                                         : (unsigned)((in[pos + 2] << 8) | in[pos + 3]);
            if (lo < 0xDC00 || lo > 0xDFFF) { *what = "a high surrogate not followed by a low surrogate in UTF-16 input"; return 0; }
            *cp = 0x10000 + (((unsigned long)u - 0xD800) << 10) + (lo - 0xDC00);
            return 4;
        }
        *cp = u;
        return 2;
    }
    case FRX_ENC_LATIN1:
        *cp = in[pos];
        return 1;
    case FRX_ENC_ASCII:
        if (in[pos] >= 0x80) { *what = "a byte outside US-ASCII in input declared US-ASCII"; return 0; }
        *cp = in[pos];
        return 1;
    default:
        *cp = in[pos];
        return 1;
    }
}

/* Transcode the input after the BOM into e->out. For UTF-8 nothing is
 * allocated: out stays NULL and the caller uses the input past the BOM.
 * 0 on refusal with err set at the input offset. */
static int
frx_enc_run(frx_enc *e, const unsigned char *in, size_t len, frx_err *err)
{
    size_t pos, o = 0, cap, next_cp;
    const char *what = NULL;

    e->out = NULL; e->out_len = 0; e->map = NULL; e->n_map = 0;
    if (e->kind == FRX_ENC_UTF8) return 1;

    cap = (len - (size_t)e->bom) * 2 + 4;
    e->out = (char *)malloc(cap);
    e->n_map = (len - (size_t)e->bom) / FRX_ENC_STEP + 2;
    e->map = (size_t *)malloc(e->n_map * sizeof *e->map);
    if (!e->out || !e->map) {
        free(e->out); free(e->map); e->out = NULL; e->map = NULL;
        frx_err_set(err, FRX_E_NOMEM, 0, "out of memory");
        return 0;
    }
    next_cp = 0;
    for (pos = (size_t)e->bom; pos < len; ) {
        unsigned long cp;
        size_t n;
        if (pos - (size_t)e->bom >= next_cp) {
            e->map[next_cp / FRX_ENC_STEP] = o;
            next_cp += FRX_ENC_STEP;
        }
        n = frx_enc_step(e->kind, in, len, pos, &cp, &what);
        if (!n) {
            frx_err_set(err, FRX_E_ENCODING, pos, what);
            err->enc = frx_enc_name(e->kind);
            free(e->out); free(e->map); e->out = NULL; e->map = NULL;
            return 0;
        }
        o += frx_utf8_encode(cp, (unsigned char *)e->out + o);
        pos += n;
    }
    e->out[o] = '\0';
    e->out_len = o;
    /* a final checkpoint so the map is never walked past its end */
    e->map[next_cp / FRX_ENC_STEP] = o;
    return 1;
}

/* the input offset that produced output offset out_off, for a message */
static size_t
frx_enc_input_offset(const frx_enc *e, const unsigned char *in, size_t len, size_t out_off)
{
    size_t i, pos, o;
    if (!e->out) return out_off + (size_t)e->bom;
    /* the last checkpoint at or before out_off */
    i = 0;
    while (i + 1 < e->n_map && (i + 1) * FRX_ENC_STEP + (size_t)e->bom < len && e->map[i + 1] <= out_off) i++;
    pos = (size_t)e->bom + i * FRX_ENC_STEP;
    o   = e->map[i];
    while (pos < len && o < out_off) {
        unsigned long cp;
        const char *what;
        unsigned char tmp[4];
        size_t n = frx_enc_step(e->kind, in, len, pos, &cp, &what);
        if (!n) break;
        o   += frx_utf8_encode(cp, tmp);
        pos += n;
    }
    return pos;
}

static void
frx_enc_free(frx_enc *e)
{
    free(e->out);
    free(e->map);
    e->out = NULL;
    e->map = NULL;
}

#endif /* FRX_ENC_H */
