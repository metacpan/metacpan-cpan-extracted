/*
 * Gzip.xs - File::Raw plugin bindings for File::Raw::Gzip.
 *
 * Single plugin "gzip" registered at BOOT. READ inflates, WRITE
 * deflates, STREAM inflates a chunk at a time and emits decompressed
 * lines through the user callback (each_line). Per-call options arrive
 * via FilePluginContext::options and are validated/decoded by
 * decode_opts() below.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* gz.c uses raw libc malloc/realloc/free; the unsigned char *out
 * pointers we receive back are libc-allocated. On Strawberry / Win32
 * Perl (PERL_IMPLICIT_SYS), iperlsys.h redefines free as a 1-arg
 * macro that routes through PerlMem_free, which tracks per-interpreter
 * pool ownership. Freeing a libc-malloc'd pointer through
 * PerlMem_free triggers "Free to wrong pool ... at t line N" at
 * global destruction (or sooner) on every Gzip read/write call site.
 * Undef the four memory macros so the free()s below resolve to the
 * libc free that matches the libc malloc in gz.c. No-op on Unix. */
#undef malloc
#undef free
#undef realloc
#undef calloc

#include "file_plugin.h"
#include "gz.h"

#include <string.h>
#include <zlib.h>

/* XS_EXTERNAL not defined on perl < 5.16. */
#ifndef XS_EXTERNAL
#define XS_EXTERNAL(name) XS(name)
#endif

/* ============================================================
 * Option decoding
 * ============================================================ */

static const char *VALID_OPT_KEYS[] = {
    "level", "mode", "chunk_size", "strategy", "mem_level",
    /* present in the HV File::Raw built for our dispatch call; we
     * recognise and ignore it so unknown-key detection doesn't fire. */
    "plugin",
    NULL
};

static int
known_opt(const char *key, STRLEN klen)
{
    const char *const *p;
    for (p = VALID_OPT_KEYS; *p; p++) {
        if (strlen(*p) == klen && memcmp(*p, key, klen) == 0) return 1;
    }
    return 0;
}

static gz_mode_t
parse_mode(const char *s, STRLEN len)
{
    if (len == 4 && memcmp(s, "gzip", 4) == 0) return GZ_MODE_GZIP;
    if (len == 4 && memcmp(s, "zlib", 4) == 0) return GZ_MODE_ZLIB;
    if (len == 3 && memcmp(s, "raw",  3) == 0) return GZ_MODE_RAW;
    if (len == 4 && memcmp(s, "auto", 4) == 0) return GZ_MODE_AUTO;
    return (gz_mode_t)-1;
}

static int
parse_strategy(const char *s, STRLEN len)
{
    if (len == 7 && memcmp(s, "default",     7) == 0) return Z_DEFAULT_STRATEGY;
    if (len == 8 && memcmp(s, "filtered",    8) == 0) return Z_FILTERED;
    if (len == 12 && memcmp(s, "huffman_only",12) == 0) return Z_HUFFMAN_ONLY;
    if (len == 3 && memcmp(s, "rle",         3) == 0) return Z_RLE;
    if (len == 5 && memcmp(s, "fixed",       5) == 0) return Z_FIXED;
    return -1;
}

static void
decode_opts(pTHX_ HV *opts_hv, gz_options_t *opts)
{
    if (!opts_hv) return;

    hv_iterinit(opts_hv);
    HE *he;
    while ((he = hv_iternext(opts_hv))) {
        I32 klen_i;
        const char *key = hv_iterkey(he, &klen_i);
        STRLEN klen = (STRLEN)klen_i;
        SV *val = hv_iterval(opts_hv, he);

        if (!known_opt(key, klen)) {
            croak("File::Raw::Gzip: unknown option '%.*s'",
                  (int)klen, key);
        }
        if (!SvOK(val)) continue;

        if (klen == 5 && memcmp(key, "level", 5) == 0) {
            IV n = SvIV(val);
            if (n < 0 || n > 9)
                croak("File::Raw::Gzip: level must be 0..9");
            opts->level = (int)n;
        } else if (klen == 4 && memcmp(key, "mode", 4) == 0) {
            STRLEN slen;
            const char *sp = SvPV(val, slen);
            gz_mode_t m = parse_mode(sp, slen);
            if ((int)m < 0)
                croak("File::Raw::Gzip: mode must be one of "
                      "gzip / zlib / raw / auto");
            opts->mode = m;
        } else if (klen == 10 && memcmp(key, "chunk_size", 10) == 0) {
            IV n = SvIV(val);
            if (n <= 0 || n > (IV)(64 * 1024 * 1024))
                croak("File::Raw::Gzip: chunk_size must be 1..67108864");
            opts->chunk_size = (size_t)n;
        } else if (klen == 8 && memcmp(key, "strategy", 8) == 0) {
            STRLEN slen;
            const char *sp = SvPV(val, slen);
            int s = parse_strategy(sp, slen);
            if (s < 0)
                croak("File::Raw::Gzip: strategy must be one of "
                      "default / filtered / huffman_only / rle / fixed");
            opts->strategy = s;
        } else if (klen == 9 && memcmp(key, "mem_level", 9) == 0) {
            IV n = SvIV(val);
            if (n < 1 || n > 9)
                croak("File::Raw::Gzip: mem_level must be 1..9");
            opts->mem_level = (int)n;
        }
        /* "plugin" key: ignored. */
    }
}

/* ============================================================
 * Plugin callbacks
 * ============================================================ */

static SV *
gz_read_cb(pTHX_ FilePluginContext *ctx)
{
    gz_options_t opts;
    gz_options_init(&opts);
    /* Decode default already = AUTO; no further seeding needed. */
    if (ctx->options) decode_opts(aTHX_ ctx->options, &opts);

    if (!ctx->data) return &PL_sv_undef;
    STRLEN ilen;
    const char *ipv = SvPV(ctx->data, ilen);

    unsigned char *out = NULL;
    size_t out_cap = 0, out_len = 0;
    gz_err_t rc = gz_inflate((const unsigned char *)ipv, ilen, &opts,
                             &out, &out_cap, &out_len);
    if (rc != GZ_OK) {
        free(out);
        croak("File::Raw::Gzip: %s", gz_strerror(rc));
    }

    SV *result = newSVpvn(out_len ? (const char *)out : "", out_len);
    free(out);
    return result;
}

static SV *
gz_write_cb(pTHX_ FilePluginContext *ctx)
{
    gz_options_t opts;
    gz_options_init(&opts);
    /* Encoder default: gzip wrap. AUTO is decode-only. */
    opts.mode = GZ_MODE_GZIP;
    if (ctx->options) decode_opts(aTHX_ ctx->options, &opts);

    if (!ctx->data) return &PL_sv_undef;
    STRLEN ilen;
    const char *ipv = SvPV(ctx->data, ilen);

    unsigned char *out = NULL;
    size_t out_cap = 0, out_len = 0;
    gz_err_t rc = gz_deflate((const unsigned char *)ipv, ilen, &opts,
                             &out, &out_cap, &out_len);
    if (rc != GZ_OK) {
        free(out);
        croak("File::Raw::Gzip: %s", gz_strerror(rc));
    }

    SV *result = newSVpvn(out_len ? (const char *)out : "", out_len);
    free(out);
    return result;
}

/* ============================================================
 * STREAM phase
 *
 * Driven by File::Raw::each_line($p, $cb, plugin => 'gzip'). File::Raw
 * opens the file and feeds us raw bytes a chunk at a time; we own the
 * inflate state and a "carry" buffer (the partial trailing line that
 * hasn't seen a newline yet) across calls via FilePluginContext::
 * call_state. Each complete decompressed line is emitted to the user
 * callback with $_ bound to the line, mirroring File::Raw's builtin
 * each_line.
 * ============================================================ */

typedef struct {
    z_stream       zs;
    int            zs_inited;
    int            stream_end;     /* set once inflate returned Z_STREAM_END   */
    unsigned char *carry;          /* partial line buffer (no '\n' inside)     */
    size_t         carry_len;
    size_t         carry_cap;
    SV            *line_sv;        /* reused $_ target across emissions        */
} gz_stream_state_t;

static int
mode_to_inflate_wbits(gz_mode_t mode)
{
    switch (mode) {
    case GZ_MODE_GZIP: return MAX_WBITS | 16;        /* 31 */
    case GZ_MODE_ZLIB: return MAX_WBITS;             /* 15 */
    case GZ_MODE_RAW:  return -MAX_WBITS;            /* -15 */
    case GZ_MODE_AUTO: return MAX_WBITS | 32;        /* 47 */
    }
    return MAX_WBITS | 32;
}

static void
gz_stream_state_free(pTHX_ gz_stream_state_t *st)
{
    if (!st) return;
    if (st->zs_inited) { inflateEnd(&st->zs); st->zs_inited = 0; }
    if (st->carry)     { Safefree(st->carry); st->carry = NULL; }
    if (st->line_sv)   { SvREFCNT_dec(st->line_sv); st->line_sv = NULL; }
    Safefree(st);
}

static void
gz_carry_append(pTHX_ gz_stream_state_t *st, const unsigned char *p, size_t n)
{
    if (!n) return;
    if (st->carry_len + n > st->carry_cap) {
        size_t want = st->carry_cap ? st->carry_cap : 256;
        while (want < st->carry_len + n) want *= 2;
        Renew(st->carry, want, unsigned char);
        st->carry_cap = want;
    }
    memcpy(st->carry + st->carry_len, p, n);
    st->carry_len += n;
}

/* Emit one line: $_ = (carry ++ buf[0..n]) ; cb->() ; clear carry. */
static void
gz_emit_line(pTHX_ gz_stream_state_t *st, SV *cb,
             const unsigned char *buf, size_t n)
{
    dSP;
    if (st->carry_len) {
        sv_setpvn(st->line_sv, (const char *)st->carry, st->carry_len);
        if (n) sv_catpvn(st->line_sv, (const char *)buf, n);
        st->carry_len = 0;
    } else {
        sv_setpvn(st->line_sv, (const char *)buf, n);
    }

    ENTER;
    SAVETMPS;
    SAVE_DEFSV;
    DEFSV = st->line_sv;
    PUSHMARK(SP);
    call_sv(cb, G_VOID | G_DISCARD);
    FREETMPS;
    LEAVE;
}

/* Scan `buf` for newlines, emitting one line per newline and stashing
 * the trailing partial line in st->carry. */
static void
gz_split_and_emit(pTHX_ gz_stream_state_t *st, SV *cb,
                  const unsigned char *buf, size_t n)
{
    const unsigned char *p = buf;
    const unsigned char *end = buf + n;
    while (p < end) {
        const unsigned char *nl = (const unsigned char *)
            memchr(p, '\n', (size_t)(end - p));
        if (!nl) {
            gz_carry_append(aTHX_ st, p, (size_t)(end - p));
            return;
        }
        gz_emit_line(aTHX_ st, cb, p, (size_t)(nl - p));
        p = nl + 1;
    }
}

static int
gz_stream_cb(pTHX_ FilePluginContext *ctx,
             const char *chunk, size_t len, int eof)
{
    gz_stream_state_t *st = (gz_stream_state_t *)ctx->call_state;
    SV *cb = ctx->callback;
    unsigned char zout[64 * 1024];
    int z_rc;

    if (!st) {
        gz_options_t opts;
        int wbits;
        gz_options_init(&opts);
        if (ctx->options) decode_opts(aTHX_ ctx->options, &opts);
        wbits = mode_to_inflate_wbits(opts.mode);

        Newxz(st, 1, gz_stream_state_t);
        st->line_sv = newSV(256);

        z_rc = inflateInit2(&st->zs, wbits);
        if (z_rc != Z_OK) {
            gz_stream_state_free(aTHX_ st);
            ctx->cancel = 1;
            croak("File::Raw::Gzip: zlib inflateInit2 failed (%d)", z_rc);
        }
        st->zs_inited = 1;
        ctx->call_state = st;
    }

    if (chunk && len > 0 && !st->stream_end) {
        st->zs.next_in  = (Bytef *)chunk;
        st->zs.avail_in = (uInt)len;
        while (st->zs.avail_in > 0 && !st->stream_end) {
            st->zs.next_out  = zout;
            st->zs.avail_out = (uInt)sizeof(zout);
            z_rc = inflate(&st->zs, Z_NO_FLUSH);
            {
                size_t produced = sizeof(zout) - st->zs.avail_out;
                if (produced) gz_split_and_emit(aTHX_ st, cb, zout, produced);
            }
            if (z_rc == Z_STREAM_END) { st->stream_end = 1; break; }
            if (z_rc == Z_BUF_ERROR && st->zs.avail_out > 0) {
                /* Needs more input; will get it on next chunk. */
                break;
            }
            if (z_rc != Z_OK) {
                gz_stream_state_free(aTHX_ st);
                ctx->call_state = NULL;
                ctx->cancel = 1;
                croak("File::Raw::Gzip: %s", zError(z_rc));
            }
        }
    }

    if (eof) {
        /* Drain any tail still buffered inside zlib (unlikely after the
         * loop above for a healthy stream, but safe to attempt). */
        if (!st->stream_end) {
            do {
                st->zs.next_out  = zout;
                st->zs.avail_out = (uInt)sizeof(zout);
                z_rc = inflate(&st->zs, Z_FINISH);
                {
                    size_t produced = sizeof(zout) - st->zs.avail_out;
                    if (produced) gz_split_and_emit(aTHX_ st, cb, zout, produced);
                }
                if (z_rc == Z_STREAM_END) { st->stream_end = 1; break; }
                if (z_rc == Z_BUF_ERROR && st->zs.avail_out == 0) continue;
                if (z_rc == Z_OK)         continue;
                /* Any other code: input ended before the gzip trailer. */
                gz_stream_state_free(aTHX_ st);
                ctx->call_state = NULL;
                ctx->cancel = 1;
                croak("File::Raw::Gzip: input ended before stream completion");
            } while (1);
        }
        if (st->carry_len) {
            gz_emit_line(aTHX_ st, cb, NULL, 0);
        }
        gz_stream_state_free(aTHX_ st);
        ctx->call_state = NULL;
    }

    return 0;
}

/* Plugin descriptor. Static-storage lifetime so the registry's
 * non-owning pointer stays valid for the life of the process. */
static FilePlugin gzip_plugin;

/* ============================================================ */

MODULE = File::Raw::Gzip   PACKAGE = File::Raw::Gzip

PROTOTYPES: DISABLE

BOOT:
    memset(&gzip_plugin, 0, sizeof gzip_plugin);
    gzip_plugin.name      = "gzip";
    gzip_plugin.read_fn   = gz_read_cb;
    gzip_plugin.write_fn  = gz_write_cb;
    gzip_plugin.record_fn = NULL;
    gzip_plugin.stream_fn = gz_stream_cb;
    gzip_plugin.state     = NULL;
    file_register_plugin(aTHX_ &gzip_plugin);
