/*
 * Separated.xs - Perl XS bindings for the File::Raw::Separated parser core.
 *
 * Surface:
 *   In-memory primitives:
 *     parse_buf($scalar [, \%opts])               -> \@rows
 *     parse_buf_each($scalar, $code [, \%opts])   ;callback per row
 *     parse_stream($path, $code [, \%opts])       ;chunked file streamer
 *     plus dialect-pinning aliases csv_* and tsv_* (Perl-side, .pm)
 *
 *   File::Raw plugin integration:
 *     At BOOT we register two plugins ("csv", "tsv") via
 *     include/file_plugin.h. They expose a READ phase that turns
 *     File::Raw::slurp($p, plugin => 'csv', ...) into AoA. Per-call
 *     options arrive through ctx->options (a per-call HV) and merge
 *     on top of the dialect's defaults held in ctx->plugin_state.
 *     There is no more global hook state, no enable/disable, no
 *     get/set/with_options scaffolding - all of that lived to back the
 *     old hook system; the plugin model passes options inline.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "include/separated_parser.h"
/* file_plugin.h comes from File::Raw via ExtUtils::Depends -- the
   consumer Makefile.PL adds the right -I to find it. */
#include "file_plugin.h"

#include <string.h>
#include <ctype.h>
#include <fcntl.h>
#include <errno.h>

/* XS_EXTERNAL was added in 5.16; older perls (5.10/5.14) need this
   fallback or our `import` XSUB forward-decl + definition won't
   expand and BOOT can't take its address. */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif

/* ============================================================
 * Option decoding
 *
 * Reads a Perl hashref of options into a separated_options_t.
 * Unknown keys croak (catches typos like 'seperator').
 * Caller is expected to have already seeded sensible defaults
 * before calling this (so the merge is "user opts on top of defaults").
 * ============================================================ */

static const char *VALID_OPT_KEYS[] = {
    "sep", "quote", "escape", "strict", "eol", "trim",
    "empty_is_undef", "binary", "header", "max_field_len",
    /* dialect: selects the seeded defaults (csv | tsv). Consumed by
     * seed_opts_for_dialect() before decode_opts() runs; listed here so
     * known_opt() doesn't reject it during the merge sweep. */
    "dialect",
    /* plugin: present in the HV that File::Raw builds for its dispatch
     * call (e.g. slurp($p, plugin => 'csv', sep => ';')). The plugin
     * machinery uses it to look us up; for our merge sweep it's a
     * known-and-ignored key. */
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

/* Take the first byte of a string SV, croaking if empty.
 * Used for sep / quote / escape (each must be exactly one byte;
 * single-byte ASCII for v0.01 — multi-byte separators are a future stretch). */
static int
sv_first_byte(pTHX_ SV *sv, const char *what)
{
    STRLEN len;
    const char *p = SvPV(sv, len);
    if (len < 1) croak("File::Raw::Separated: %s must be a non-empty string", what);
    return (unsigned char)p[0];
}

static separated_eol_t
sv_to_eol(pTHX_ SV *sv)
{
    STRLEN len;
    const char *p = SvPV(sv, len);
    if (len == 4 && memcmp(p, "auto", 4) == 0) return SEPARATED_EOL_AUTO;
    if (len == 2 && memcmp(p, "lf",   2) == 0) return SEPARATED_EOL_LF;
    if (len == 4 && memcmp(p, "crlf", 4) == 0) return SEPARATED_EOL_CRLF;
    if (len == 2 && memcmp(p, "cr",   2) == 0) return SEPARATED_EOL_CR;
    croak("File::Raw::Separated: eol must be one of auto|lf|crlf|cr (got '%.*s')",
          (int)len, p);
}

/* Dialect pinning: AUTO reads the `dialect` key from the user's hash (default
 * CSV); CSV/TSV force the dialect regardless of what the hash says. The
 * dialect-prefixed XSUBs (csv_parse_buf, tsv_parse_stream, …) all forward
 * with a non-AUTO pin — they used to be Perl-side wrappers that mutated the
 * opts hash via _pin_dialect; the pin now happens here instead. */
typedef enum {
    DIALECT_AUTO = 0,
    DIALECT_CSV  = 1,
    DIALECT_TSV  = 2,
} dialect_pin_t;

/* Read the optional `dialect` key from a user-supplied options hashref
 * (may be NULL) and seed *opts with the corresponding defaults.
 * If `pin` is CSV/TSV the hash's dialect key is ignored entirely.
 * Defaults to CSV. Croaks on an unknown dialect string.
 * This MUST be called before decode_opts() so user-supplied keys layer
 * cleanly on top of the dialect's defaults. */
static void
seed_opts_for_dialect(pTHX_ HV *hv, separated_options_t *opts, dialect_pin_t pin)
{
    SV **slot;
    if (pin == DIALECT_CSV) { separated_options_init_csv(opts); return; }
    if (pin == DIALECT_TSV) { separated_options_init_tsv(opts); return; }
    if (hv && (slot = hv_fetchs(hv, "dialect", 0)) && *slot && SvOK(*slot)) {
        STRLEN dlen;
        const char *dpv = SvPV(*slot, dlen);
        if (dlen == 3 && memcmp(dpv, "csv", 3) == 0) {
            separated_options_init_csv(opts);
            return;
        }
        if (dlen == 3 && memcmp(dpv, "tsv", 3) == 0) {
            separated_options_init_tsv(opts);
            return;
        }
        croak("File::Raw::Separated: dialect must be 'csv' or 'tsv' (got '%.*s')",
              (int)dlen, dpv);
    }
    /* default: CSV */
    separated_options_init_csv(opts);
}

/* Same as above, but takes a plain SV instead of looking up a hash key.
 * Used by the class-method state setters (set_options('csv'|'tsv', ...)). */
static int
parse_dialect_sv(pTHX_ SV *sv, const char *fn)
{
    STRLEN dlen;
    const char *dpv;
    if (!sv || !SvOK(sv))
        croak("%s: dialect (first arg) must be 'csv' or 'tsv'", fn);
    dpv = SvPV(sv, dlen);
    if (dlen == 3 && memcmp(dpv, "csv", 3) == 0) return 0;  /* csv slot */
    if (dlen == 3 && memcmp(dpv, "tsv", 3) == 0) return 1;  /* tsv slot */
    croak("%s: dialect must be 'csv' or 'tsv' (got '%.*s')",
          fn, (int)dlen, dpv);
}

/* Merge an options hashref (may be NULL or undef) into *opts.
 * Croaks on unknown key or wrong-shape value. */
static void
decode_opts(pTHX_ HV *hv, separated_options_t *opts)
{
    if (!hv) return;

    hv_iterinit(hv);
    HE *he;
    while ((he = hv_iternext(hv))) {
        I32 klen_i;
        const char *key = hv_iterkey(he, &klen_i);
        STRLEN klen = (STRLEN)klen_i;
        SV *val = hv_iterval(hv, he);

        if (!known_opt(key, klen)) {
            croak("File::Raw::Separated: unknown option '%.*s'",
                  (int)klen, key);
        }

        /* Treat undef value as "use default" — i.e. skip; gives callers
         * a way to express "I don't care, use the seeded default". */
        if (!SvOK(val)) continue;

        if      (klen == 3 && memcmp(key, "sep",   3) == 0) opts->sep   = sv_first_byte(aTHX_ val, "sep");
        else if (klen == 5 && memcmp(key, "quote", 5) == 0) opts->quote = sv_first_byte(aTHX_ val, "quote");
        else if (klen == 6 && memcmp(key, "escape",6) == 0) opts->escape= sv_first_byte(aTHX_ val, "escape");
        else if (klen == 6 && memcmp(key, "strict",6) == 0) opts->strict= SvTRUE(val) ? 1 : 0;
        else if (klen == 3 && memcmp(key, "eol",   3) == 0) opts->eol_mode = sv_to_eol(aTHX_ val);
        else if (klen == 4 && memcmp(key, "trim",  4) == 0) opts->trim  = SvTRUE(val) ? 1 : 0;
        else if (klen == 14 && memcmp(key, "empty_is_undef", 14) == 0) opts->empty_is_undef = SvTRUE(val) ? 1 : 0;
        else if (klen == 6 && memcmp(key, "binary",6) == 0) opts->binary= SvTRUE(val) ? 1 : 0;
        else if (klen == 6 && memcmp(key, "header",6) == 0) opts->header= SvTRUE(val) ? 1 : 0;
        else if (klen == 13 && memcmp(key, "max_field_len", 13) == 0) {
            IV n = SvIV(val);
            if (n < 0) croak("File::Raw::Separated: max_field_len must be >= 0");
            opts->max_field_len = (size_t)n;
        }
    }
}

/* ============================================================
 * Dispatcher state — passed through the C parser as user-data
 * ============================================================ */

typedef struct {
#ifdef PERL_IMPLICIT_CONTEXT
    PerlInterpreter *my_perl;   /* used by dTHXa(c->my_perl) in callbacks */
#endif
    AV *result;          /* used in collect mode (as_callback == 0) */
    AV *current_row;     /* AV reused across rows in collect mode */
    SV *cb;              /* user callback in callback mode (1) */
    AV *row_av;          /* one reusable AV for callback mode */
    int as_callback;
    int empty_is_undef;
    int binary;
    /* Header mode: when 1, first emitted row is consumed as keys and
     * subsequent rows are emitted as hashrefs keyed by those names. */
    int header_mode;
    AV *headers;         /* NULL until first row consumed in header mode */
    /* When the user callback dies, we propagate via a stash. */
    SV *die_msg;
} dispatch_ctx_t;

/* Build a single field SV from the parser's borrowed pointer. */
static SV *
make_field_sv(pTHX_ const char *field, STRLEN len, int is_null,
              int empty_is_undef, int binary)
{
    PERL_UNUSED_VAR(empty_is_undef);
    if (is_null) return newSV(0);     /* PL_sv_undef would be SVREADONLY */
    SV *sv = newSVpvn(field ? field : "", len);
    if (!binary) sv_utf8_decode(sv);
    return sv;
}

/* Header-mode helpers (used by both collect_cb and each_cb).
 *
 * Contract:
 *   - First row in header mode is taken as the header. Duplicate keys
 *     croak. Subsequent calls see ctx->headers != NULL.
 *   - Subsequent rows are zipped against the header into a fresh HV.
 *     Row arity > header arity croaks. Row arity < header arity pads
 *     trailing keys with undef.
 *   - Field SVs are copied into the HV via newSVsv (the source AV gets
 *     av_clear'd or freed afterwards). */

static void
check_no_duplicate_headers(pTHX_ AV *headers)
{
    HV *seen = newHV();
    SSize_t n = av_len(headers) + 1;
    SSize_t i;
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(headers, i, 0);
        STRLEN klen;
        const char *kpv;
        if (!kp || !*kp) continue;
        kpv = SvPV(*kp, klen);
        if (hv_exists(seen, kpv, klen)) {
            SvREFCNT_dec((SV *)seen);
            croak("File::Raw::Separated: duplicate header key '%.*s'",
                  (int)klen, kpv);
        }
        (void)hv_store(seen, kpv, klen, &PL_sv_yes, 0);
    }
    SvREFCNT_dec((SV *)seen);
}

static HV *
build_header_row_hv(pTHX_ AV *headers, AV *row)
{
    HV *hv = newHV();
    SSize_t hcount = av_len(headers) + 1;
    SSize_t rcount = av_len(row) + 1;
    SSize_t i;
    if (rcount > hcount) {
        SvREFCNT_dec((SV *)hv);
        croak("File::Raw::Separated: row has %ld field(s), header has %ld",
              (long)rcount, (long)hcount);
    }
    for (i = 0; i < hcount; i++) {
        SV **kp = av_fetch(headers, i, 0);
        STRLEN klen;
        const char *kpv;
        SV *val;
        if (!kp || !*kp) continue;
        kpv = SvPV(*kp, klen);
        if (i < rcount) {
            SV **vp = av_fetch(row, i, 0);
            val = (vp && *vp) ? newSVsv(*vp) : newSV(0);
        } else {
            val = newSV(0);
        }
        (void)hv_store(hv, kpv, klen, val, 0);
    }
    return hv;
}

/* Extract caller-supplied header names from an options HV. Returns:
 *   - NULL if `header` is missing, false-ish, or `header => 1` (the
 *     "consume the file's first row as headers" mode);
 *   - a fresh AV (refcount 1, owned by caller) of header-name SVs when
 *     `header => [name, name, ...]` was supplied. Validates: arrayref,
 *     non-empty, no undef entries, no duplicates.
 *
 * The caller installs the returned AV directly into dispatch_ctx_t::
 * headers BEFORE the parser starts emitting fields, which short-
 * circuits the each_cb / collect_cb "first row becomes headers" branch
 * so row 0 is treated as data and emitted as a hashref. */
static AV *
extract_explicit_headers(pTHX_ HV *opts)
{
    SV **slot;
    SV  *val;
    AV  *user_av;
    AV  *out;
    SSize_t i, n;

    if (!opts) return NULL;
    slot = hv_fetchs(opts, "header", 0);
    if (!slot || !*slot || !SvOK(*slot)) return NULL;
    val = *slot;

    /* `header => 1` (or any non-arrayref truthy) keeps legacy behaviour. */
    if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV) return NULL;

    user_av = (AV *)SvRV(val);
    n = av_len(user_av) + 1;
    if (n <= 0)
        croak("File::Raw::Separated: header => [] is empty; "
              "use header => 1 to consume the file's first row, "
              "or supply at least one name");

    out = newAV();
    av_extend(out, n - 1);
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(user_av, i, 0);
        if (!kp || !*kp || !SvOK(*kp)) {
            SvREFCNT_dec((SV *)out);
            croak("File::Raw::Separated: header => [...] entry %ld is undef",
                  (long)i);
        }
        /* Copy to detach from the caller's arrayref. */
        av_push(out, newSVsv(*kp));
    }
    /* Reuses the same dup-check the implicit path uses for symmetry. */
    check_no_duplicate_headers(aTHX_ out);
    return out;
}

/* Field callback for as_callback == 0: accumulate into AoA (or
 * arrayref-of-hashref if header_mode). */
static int
collect_cb(const char *field, size_t len, int eor, void *ud)
{
    dispatch_ctx_t *c = (dispatch_ctx_t *)ud;
    dTHXa(c->my_perl);
    int is_null = (len == SEPARATED_FIELD_NULL_LEN);
    SV *sv = make_field_sv(aTHX_ field, is_null ? 0 : (STRLEN)len, is_null,
                           c->empty_is_undef, c->binary);
    av_push(c->current_row, sv);
    if (eor) {
        if (c->header_mode && !c->headers) {
            /* First row is the header. Validate duplicates, then steal. */
            check_no_duplicate_headers(aTHX_ c->current_row);
            c->headers = c->current_row;
            c->current_row = newAV();
            /* Do NOT push to result. */
        } else if (c->header_mode) {
            /* Subsequent row: zip against headers into hash. */
            HV *row_hv = build_header_row_hv(aTHX_ c->headers, c->current_row);
            av_push(c->result, newRV_noinc((SV *)row_hv));
            av_clear(c->current_row);
        } else {
            av_push(c->result, newRV_noinc((SV *)c->current_row));
            c->current_row = newAV();
        }
    }
    return 0;
}

/* Field callback for as_callback == 1: invoke user code per row. */
static int
each_cb(const char *field, size_t len, int eor, void *ud)
{
    dispatch_ctx_t *c = (dispatch_ctx_t *)ud;
    dTHXa(c->my_perl);
    int is_null = (len == SEPARATED_FIELD_NULL_LEN);
    SV *sv = make_field_sv(aTHX_ field, is_null ? 0 : (STRLEN)len, is_null,
                           c->empty_is_undef, c->binary);
    av_push(c->row_av, sv);
    if (eor) {
        /* Header mode: first row is consumed as headers, no callback. */
        if (c->header_mode && !c->headers) {
            check_no_duplicate_headers(aTHX_ c->row_av);
            /* Steal row_av as headers; allocate fresh row_av for next row. */
            c->headers = c->row_av;
            c->row_av = newAV();
            return 0;
        }

        /* Build the arg the callback sees: AV (default) or HV (header). */
        SV *rowref;
        if (c->header_mode) {
            HV *row_hv = build_header_row_hv(aTHX_ c->headers, c->row_av);
            rowref = newRV_noinc((SV *)row_hv);
        } else {
            rowref = newRV_inc((SV *)c->row_av);  /* +1, not consumed */
        }
        sv_2mortal(rowref);

        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(rowref);
        PUTBACK;

        int count;
        I32 flags = G_DISCARD | G_EVAL;
        count = call_sv(c->cb, flags);
        SPAGAIN;
        PERL_UNUSED_VAR(count);

        /* Did the callback die? Stash the message and abort the parse. */
        SV *errsv = ERRSV;
        if (SvTRUE(errsv)) {
            c->die_msg = newSVsv(errsv);
            FREETMPS; LEAVE;
            av_clear(c->row_av);   /* prepare for cleanup */
            return 1;              /* tell parser to abort */
        }

        FREETMPS; LEAVE;
        av_clear(c->row_av);
    }
    return 0;
}

/* The shared dispatcher. `input_pv` / `input_len` is the byte buffer
 * to parse; `opts` is fully resolved. as_callback selects collect vs
 * callback mode. cb is the user code in callback mode (NULL otherwise).
 *
 * Returns:
 *   collect mode (as_callback == 0):  AV* of rowrefs (caller must mortalise)
 *   callback mode (as_callback == 1): NULL (no return value)
 *
 * On parse error, croaks. On callback-die, croaks with the propagated msg.
 */
static AV *
separated_parse_dispatch(pTHX_ const char *input_pv, STRLEN input_len,
                         const separated_options_t *opts,
                         int as_callback, SV *cb,
                         AV *explicit_headers)
{
    dispatch_ctx_t ctx;
    memset(&ctx, 0, sizeof ctx);
#ifdef PERL_IMPLICIT_CONTEXT
    ctx.my_perl = aTHX;
#endif
    ctx.empty_is_undef = opts->empty_is_undef;
    ctx.binary = opts->binary;
    /* Force header_mode on when explicit names were supplied, so
     * callbacks emit hashrefs from row 0. Caller is responsible for
     * passing this only when meaningful (e.g. only on the read side). */
    ctx.header_mode = opts->header || (explicit_headers != NULL);
    ctx.headers = explicit_headers;   /* takes ownership */
    ctx.as_callback = as_callback;

    separated_field_cb fcb;
    if (as_callback) {
        ctx.cb = cb;
        ctx.row_av = newAV();
        fcb = each_cb;
    } else {
        ctx.result = newAV();
        ctx.current_row = newAV();
        fcb = collect_cb;
    }

    size_t err_off = 0;
    long rc = separated_parse(input_pv, input_len, opts, fcb, &ctx, &err_off);

    if (rc < 0) {
        /* Cleanup. */
        if (as_callback) {
            SvREFCNT_dec((SV *)ctx.row_av);
        } else {
            SvREFCNT_dec((SV *)ctx.current_row);
            SvREFCNT_dec((SV *)ctx.result);
        }
        if (ctx.headers) SvREFCNT_dec((SV *)ctx.headers);
        if (ctx.die_msg) {
            STRLEN dlen;
            const char *dpv = SvPV(ctx.die_msg, dlen);
            /* Re-raise the original die message verbatim. Not using
             * croak_sv (5.13.1+) for 5.8/5.10 compat. */
            SV *msg_mortal = sv_2mortal(ctx.die_msg);
            PERL_UNUSED_VAR(msg_mortal);
            croak("%.*s", (int)dlen, dpv);
        }
        croak("File::Raw::Separated: %s at byte offset %lu",
              separated_strerror((separated_err_t)rc), (unsigned long)err_off);
    }

    if (as_callback) {
        SvREFCNT_dec((SV *)ctx.row_av);
        if (ctx.headers) SvREFCNT_dec((SV *)ctx.headers);
        return NULL;
    }

    /* Trailing in-progress row — should always be empty if the parser
     * finished successfully. Free it. */
    SvREFCNT_dec((SV *)ctx.current_row);
    if (ctx.headers) SvREFCNT_dec((SV *)ctx.headers);
    return ctx.result;
}


#define SEPARATED_STREAM_CHUNK 65536

static void
separated_parse_dispatch_stream(pTHX_ const char *path,
                                const separated_options_t *opts,
                                SV *cb,
                                AV *explicit_headers)
{
    dispatch_ctx_t ctx;
    memset(&ctx, 0, sizeof ctx);
#ifdef PERL_IMPLICIT_CONTEXT
    ctx.my_perl = aTHX;
#endif
    ctx.empty_is_undef = opts->empty_is_undef;
    ctx.binary = opts->binary;
    ctx.header_mode = opts->header || (explicit_headers != NULL);
    ctx.headers = explicit_headers;   /* takes ownership */
    ctx.as_callback = 1;
    ctx.cb = cb;
    ctx.row_av = newAV();

    separated_ctx_t *parser = separated_init(opts, each_cb, &ctx);
    if (!parser) {
        SvREFCNT_dec((SV *)ctx.row_av);
        croak("File::Raw::Separated: out of memory initialising parser");
    }

    int fd = PerlLIO_open(path, O_RDONLY);
    if (fd < 0) {
        int saved_errno = errno;
        separated_free(parser);
        SvREFCNT_dec((SV *)ctx.row_av);
        croak("File::Raw::Separated: cannot open %s: %s",
              path, Strerror(saved_errno));
    }

    /* Local buffer per call. Stack-allocated so concurrent calls in
     * different threads don't collide on a static. */
    char buf[SEPARATED_STREAM_CHUNK];
    separated_err_t parse_err = SEPARATED_OK;
    int read_errno = 0;
    SSize_t n;

    while ((n = PerlLIO_read(fd, buf, sizeof buf)) > 0) {
        parse_err = separated_feed(parser, buf, (size_t)n);
        if (parse_err != SEPARATED_OK) break;
    }
    if (n < 0) read_errno = errno;

    /* Only call _finish on success — on error the context is already
     * sticky-failed and _finish would just no-op anyway, but staying
     * symmetric makes intent clearer. */
    if (parse_err == SEPARATED_OK && read_errno == 0) {
        parse_err = separated_finish(parser);
    }

    PerlLIO_close(fd);

    /* Pull diagnostics out before freeing the parser. */
    size_t err_off = (parse_err != SEPARATED_OK)
                       ? separated_offset(parser) : 0;
    SV *die_msg = ctx.die_msg;
    ctx.die_msg = NULL;

    separated_free(parser);
    SvREFCNT_dec((SV *)ctx.row_av);
    if (ctx.headers) SvREFCNT_dec((SV *)ctx.headers);

    /* Order: callback-die > read error > parse error. The first
     * cleanly explains user code aborting; the second is always
     * recoverable info; the third is our domain. */
    if (die_msg) {
        STRLEN dlen;
        const char *dpv = SvPV(die_msg, dlen);
        SV *m = sv_2mortal(die_msg);
        PERL_UNUSED_VAR(m);
        croak("%.*s", (int)dlen, dpv);
    }
    if (read_errno) {
        croak("File::Raw::Separated: read error on %s: %s",
              path, Strerror(read_errno));
    }
    if (parse_err != SEPARATED_OK) {
        croak("File::Raw::Separated: %s at byte offset %lu in %s",
              separated_strerror(parse_err),
              (unsigned long)err_off, path);
    }
}

/* ============================================================
 * Plugin integration with File::Raw
 *
 * BOOT registers two plugins ("csv" and "tsv") via file_register_plugin
 * (declared in include/file_plugin.h). Each plugin's `state` slot points
 * to a static separated_options_t carrying the dialect's defaults.
 *
 * The READ phase fires from File::Raw::slurp($p, plugin => 'csv', ...).
 * Per-call options arrive in ctx->options as an HV; we layer them on
 * top of *(ctx->plugin_state) and parse the slurped bytes into AoA.
 *
 * No global enable/disable knob: callers without a `plugin =>` opt get
 * the unmodified bytes back from File::Raw, by definition.
 * ============================================================ */

/* Per-dialect default options. The plugin struct's `state` field points
 * here; sep_read copies into a stack-local before merging ctx->options
 * on top, so concurrent calls don't fight over the defaults table. */
static separated_options_t csv_default_opts;
static separated_options_t tsv_default_opts;

static SV *
sep_read(pTHX_ FilePluginContext *ctx)
{
    separated_options_t local;
    STRLEN len;
    const char *pv;
    AV *result;

    /* Start from the dialect defaults. plugin_state always points to
     * one of csv_default_opts / tsv_default_opts; treat NULL as csv
     * defensively. */
    if (ctx->plugin_state)
        local = *(const separated_options_t *)ctx->plugin_state;
    else
        separated_options_init_csv(&local);

    /* Merge the per-call options HV on top. ctx->options is the same
     * HV file_plugin_dispatch_read built from the variadic XSUB args;
     * decode_opts ignores the 'plugin' key (added to VALID_OPT_KEYS in
     * an earlier pass) and the 'dialect' key (likewise ignored).
     *
     * No seed_opts_for_dialect call here — the dialect is fully implied
     * by which plugin fired, and the defaults already live in *local. */
    if (ctx->options) decode_opts(aTHX_ ctx->options, &local);

    if (!ctx->data) return &PL_sv_undef;
    pv = SvPV(ctx->data, len);
    {
        AV *xhdr = extract_explicit_headers(aTHX_ ctx->options);
        result = separated_parse_dispatch(aTHX_ pv, len, &local, 0, NULL, xhdr);
    }
    /* result is a fresh AV with refcount 1; wrap without bumping. */
    return newRV_noinc((SV *)result);
}

/* ============================================================
 * sep_write - WRITE phase
 *
 * Fires from File::Raw::spew / append / atomic_spew when the caller
 * passes plugin => 'csv' (or 'tsv'). Serialises an arrayref of arrayref
 * rows into bytes following RFC 4180 conventions: fields containing the
 * separator, quote character, CR, or LF are quoted; embedded quote
 * characters are doubled (or backslash-escaped if opts.escape is set).
 *
 * Hashref rows are not currently accepted (would require an explicit
 * header => [keys] order to be deterministic). Undef fields emit as
 * empty.
 * ============================================================ */

static SV *
sep_write(pTHX_ FilePluginContext *ctx)
{
    separated_options_t o;
    AV *rows;
    SSize_t nrows, i, j;
    char *buf;
    STRLEN buf_len, buf_cap;
    char eol[2];
    int eol_len;
    SV *out;

    if (ctx->plugin_state)
        o = *(const separated_options_t *)ctx->plugin_state;
    else
        separated_options_init_csv(&o);
    if (ctx->options) decode_opts(aTHX_ ctx->options, &o);

    if (!ctx->data || !SvROK(ctx->data) ||
        SvTYPE(SvRV(ctx->data)) != SVt_PVAV)
        croak("File::Raw::Separated: write expects an arrayref of rows");

    rows = (AV *)SvRV(ctx->data);
    nrows = av_len(rows) + 1;

    /* EOL. AUTO degrades to LF for write since we have nothing to
     * auto-detect; CRLF and CR honour the explicit pin. */
    switch (o.eol_mode) {
        case SEPARATED_EOL_CRLF: eol[0] = '\r'; eol[1] = '\n'; eol_len = 2; break;
        case SEPARATED_EOL_CR:   eol[0] = '\r';                eol_len = 1; break;
        default:                 eol[0] = '\n';                eol_len = 1; break;
    }

    buf_cap = 4096;
    Newx(buf, buf_cap, char);
    buf_len = 0;

#define SEP_BUF_ENSURE(n) do {                                            \
    STRLEN _need = buf_len + (STRLEN)(n);                                 \
    if (_need > buf_cap) {                                                \
        while (_need > buf_cap) buf_cap *= 2;                             \
        Renew(buf, buf_cap, char);                                        \
    }                                                                     \
} while (0)

    for (i = 0; i < nrows; i++) {
        SV **rowp = av_fetch(rows, i, 0);
        AV *row;
        SSize_t nfields;

        if (!rowp || !*rowp || !SvROK(*rowp) ||
            SvTYPE(SvRV(*rowp)) != SVt_PVAV) {
            Safefree(buf);
            croak("File::Raw::Separated: row %ld is not an arrayref", (long)i);
        }
        row = (AV *)SvRV(*rowp);
        nfields = av_len(row) + 1;

        for (j = 0; j < nfields; j++) {
            SV **fieldp = av_fetch(row, j, 0);
            STRLEN flen;
            const char *fpv;
            int needs_quote = 0;

            if (j > 0) { SEP_BUF_ENSURE(1); buf[buf_len++] = (char)o.sep; }

            if (!fieldp || !*fieldp || !SvOK(*fieldp)) continue;
            fpv = SvPV(*fieldp, flen);

            /* Decide if quoting is needed. Only relevant when the
             * dialect actually has a quote char. TSV with quote=-1
             * emits raw and is the caller's problem if it contains tab
             * or newline. */
            if (o.quote >= 0) {
                STRLEN k;
                for (k = 0; k < flen; k++) {
                    char c = fpv[k];
                    if (c == (char)o.sep || c == (char)o.quote ||
                        c == '\n' || c == '\r') {
                        needs_quote = 1;
                        break;
                    }
                }
            }

            if (needs_quote) {
                STRLEN k;
                /* worst case: every byte doubles + open + close quote */
                SEP_BUF_ENSURE(flen * 2 + 2);
                buf[buf_len++] = (char)o.quote;
                for (k = 0; k < flen; k++) {
                    char c = fpv[k];
                    if (c == (char)o.quote) {
                        if (o.escape >= 0)
                            buf[buf_len++] = (char)o.escape;
                        else
                            buf[buf_len++] = (char)o.quote;  /* RFC 4180 */
                    }
                    buf[buf_len++] = c;
                }
                buf[buf_len++] = (char)o.quote;
            } else {
                SEP_BUF_ENSURE(flen);
                memcpy(buf + buf_len, fpv, flen);
                buf_len += flen;
            }
        }

        SEP_BUF_ENSURE(eol_len);
        memcpy(buf + buf_len, eol, eol_len);
        buf_len += eol_len;
    }

#undef SEP_BUF_ENSURE

    out = newSVpvn(buf, buf_len);
    Safefree(buf);
    return out;
}

/* ============================================================
 * sep_stream - STREAM phase
 *
 * Fires from File::Raw::each_line($p, $cb, plugin => 'csv'). File::Raw
 * opens the file and feeds us chunks; we own the parser context across
 * calls via FilePluginContext::call_state. On the EOF call we flush
 * any trailing field/row, free the parser, and clear call_state.
 *
 * The user's callback is invoked once per emitted record (arrayref or
 * hashref under header mode), driven by the same each_cb the in-memory
 * callback variant uses.
 * ============================================================ */

typedef struct {
    dispatch_ctx_t      disp;
    separated_ctx_t    *parser;
    separated_options_t opts;   /* parser copies internally; keep for clarity */
    int                 destroyed;
} sep_stream_state_t;

static void
sep_stream_state_free(pTHX_ sep_stream_state_t *st)
{
    if (!st || st->destroyed) return;
    st->destroyed = 1;
    if (st->parser) { separated_free(st->parser); st->parser = NULL; }
    if (st->disp.row_av)  { SvREFCNT_dec((SV *)st->disp.row_av);  st->disp.row_av = NULL; }
    if (st->disp.headers) { SvREFCNT_dec((SV *)st->disp.headers); st->disp.headers = NULL; }
    if (st->disp.die_msg) { SvREFCNT_dec(st->disp.die_msg); st->disp.die_msg = NULL; }
    Safefree(st);
}

static int
sep_stream(pTHX_ FilePluginContext *ctx, const char *chunk, size_t len, int eof)
{
    sep_stream_state_t *st = (sep_stream_state_t *)ctx->call_state;
    separated_err_t rc;

    /* First call: build state from defaults + per-call opts, init parser. */
    if (!st) {
        /* Extract / validate explicit headers BEFORE allocating state -
         * a validation croak here would otherwise leak the partially-
         * built state (no destructor has been hooked up yet). */
        AV *xhdr = extract_explicit_headers(aTHX_ ctx->options);

        Newxz(st, 1, sep_stream_state_t);

        if (ctx->plugin_state)
            st->opts = *(const separated_options_t *)ctx->plugin_state;
        else
            separated_options_init_csv(&st->opts);
        if (ctx->options) decode_opts(aTHX_ ctx->options, &st->opts);

#ifdef PERL_IMPLICIT_CONTEXT
        st->disp.my_perl = aTHX;
#endif
        st->disp.empty_is_undef = st->opts.empty_is_undef;
        st->disp.binary         = st->opts.binary;
        st->disp.headers        = xhdr;            /* takes ownership; NULL means "use first row" */
        st->disp.header_mode    = st->opts.header || (xhdr != NULL);
        st->disp.as_callback    = 1;
        st->disp.cb             = ctx->callback;
        st->disp.row_av         = newAV();

        st->parser = separated_init(&st->opts, each_cb, &st->disp);
        if (!st->parser) {
            sep_stream_state_free(aTHX_ st);
            ctx->cancel = 1;
            croak("File::Raw::Separated: out of memory initialising parser");
        }
        ctx->call_state = st;
    }

    if (chunk && len > 0) {
        rc = separated_feed(st->parser, chunk, len);
        if (rc != SEPARATED_OK) {
            SV *die_msg = st->disp.die_msg;
            size_t off = separated_offset(st->parser);
            ctx->cancel = 1;
            if (die_msg) {
                STRLEN dlen;
                SV *m = newSVsv(die_msg);
                const char *dpv = SvPV(m, dlen);
                sep_stream_state_free(aTHX_ st);
                ctx->call_state = NULL;
                sv_2mortal(m);
                croak("%.*s", (int)dlen, dpv);
            }
            sep_stream_state_free(aTHX_ st);
            ctx->call_state = NULL;
            croak("File::Raw::Separated: %s at byte offset %lu",
                  separated_strerror(rc), (unsigned long)off);
        }
    }

    if (eof) {
        rc = separated_finish(st->parser);
        if (rc != SEPARATED_OK) {
            SV *die_msg = st->disp.die_msg;
            size_t off = separated_offset(st->parser);
            ctx->cancel = 1;
            if (die_msg) {
                STRLEN dlen;
                SV *m = newSVsv(die_msg);
                const char *dpv = SvPV(m, dlen);
                sep_stream_state_free(aTHX_ st);
                ctx->call_state = NULL;
                sv_2mortal(m);
                croak("%.*s", (int)dlen, dpv);
            }
            sep_stream_state_free(aTHX_ st);
            ctx->call_state = NULL;
            croak("File::Raw::Separated: %s at byte offset %lu",
                  separated_strerror(rc), (unsigned long)off);
        }
        sep_stream_state_free(aTHX_ st);
        ctx->call_state = NULL;
    }

    return 0;
}

/* Plugin descriptors. Static-storage lifetime so the registry's
 * non-owning pointer stays valid for the life of the process. */
static FilePlugin csv_plugin;
static FilePlugin tsv_plugin;

/* ============================================================
 * Per-XSUB helpers
 *
 * The nine XSUBs (parse_buf / parse_buf_each / parse_stream and the
 * six dialect-pinned csv_ / tsv_ variants) all do the same work modulo
 * dialect pinning. Bodies live here so each XSUB is a one-liner; the
 * dialect-prefixed variants used to be pure-Perl wrappers in the .pm
 * that mutated the opts hash via _pin_dialect - that's gone now.
 * ============================================================ */

static HV *
opts_to_hv(pTHX_ const char *fn, SV *opts)
{
    if (!opts || !SvOK(opts)) return NULL;
    if (!SvROK(opts) || SvTYPE(SvRV(opts)) != SVt_PVHV)
        croak("%s: options argument must be a hashref", fn);
    return (HV *)SvRV(opts);
}

static SV *
do_parse_buf(pTHX_ const char *fn, SV *input, SV *opts, dialect_pin_t pin)
{
    separated_options_t o;
    HV *opts_hv = opts_to_hv(aTHX_ fn, opts);
    STRLEN ilen;
    const char *ipv;
    AV *result;

    seed_opts_for_dialect(aTHX_ opts_hv, &o, pin);
    decode_opts(aTHX_ opts_hv, &o);

    ipv = SvPV(input, ilen);
    {
        AV *xhdr = extract_explicit_headers(aTHX_ opts_hv);
        result = separated_parse_dispatch(aTHX_ ipv, ilen, &o, 0, NULL, xhdr);
    }
    return newRV_noinc((SV *)result);
}

static void
do_parse_buf_each(pTHX_ const char *fn, SV *input, SV *code, SV *opts,
                  dialect_pin_t pin)
{
    separated_options_t o;
    HV *opts_hv;
    STRLEN ilen;
    const char *ipv;

    if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
        croak("%s: code argument must be a CODE ref", fn);
    opts_hv = opts_to_hv(aTHX_ fn, opts);
    seed_opts_for_dialect(aTHX_ opts_hv, &o, pin);
    decode_opts(aTHX_ opts_hv, &o);

    ipv = SvPV(input, ilen);
    {
        AV *xhdr = extract_explicit_headers(aTHX_ opts_hv);
        (void)separated_parse_dispatch(aTHX_ ipv, ilen, &o, 1, code, xhdr);
    }
}

static void
do_parse_stream(pTHX_ const char *fn, SV *path, SV *code, SV *opts,
                dialect_pin_t pin)
{
    separated_options_t o;
    HV *opts_hv;
    STRLEN plen;
    const char *path_pv;

    if (!SvOK(path)) croak("%s: path must be defined", fn);
    if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
        croak("%s: code argument must be a CODE ref", fn);
    opts_hv = opts_to_hv(aTHX_ fn, opts);
    seed_opts_for_dialect(aTHX_ opts_hv, &o, pin);
    decode_opts(aTHX_ opts_hv, &o);

    path_pv = SvPV(path, plen);
    PERL_UNUSED_VAR(plen);
    {
        AV *xhdr = extract_explicit_headers(aTHX_ opts_hv);
        separated_parse_dispatch_stream(aTHX_ path_pv, &o, code, xhdr);
    }
}

/* ============================================================
 * Import dispatcher
 *
 * `use File::Raw::Separated qw(import|:all|:unified|:csv|:tsv|<name>)`
 * lands in XS_File__Raw__Separated_import, which walks the requested
 * names and `newXS`'s "${caller}::file_${name}" -> the matching XSUB
 * pointer into the caller's symbol table. Mirrors File::Raw's import
 * (file.c XS_file_import) — same `file_` prefix convention so the two
 * modules compose: `use File::Raw qw(import); use File::Raw::Separated
 * qw(import);` lands `file_slurp` *and* `file_parse_buf` etc. in the
 * same package without collision.
 *
 * The xs_func slots are populated at BOOT time by looking up each
 * already-registered XSUB via get_cv() and stashing CvXSUB(cv); avoids
 * fragile forward-declarations of static XSUBs that xsubpp may have
 * emitted with PERL_EUPXS_ALWAYS_EXPORT either set or not.
 * ============================================================ */

typedef struct {
    const char *name;
    XSUBADDR_t  xs_func;
} ImportEntry;

/* Index ranges used by the tag handlers below. Keep in sync. */
#define IMPORT_UNIFIED_LO 0
#define IMPORT_UNIFIED_HI 3   /* exclusive */
#define IMPORT_CSV_LO     3
#define IMPORT_CSV_HI     6
#define IMPORT_TSV_LO     6
#define IMPORT_TSV_HI     9

static ImportEntry g_import_funcs[] = {
    /* :unified */
    { "parse_buf",          NULL },
    { "parse_buf_each",     NULL },
    { "parse_stream",       NULL },
    /* :csv */
    { "csv_parse_buf",      NULL },
    { "csv_parse_buf_each", NULL },
    { "csv_parse_stream",   NULL },
    /* :tsv */
    { "tsv_parse_buf",      NULL },
    { "tsv_parse_buf_each", NULL },
    { "tsv_parse_stream",   NULL },
    { NULL, NULL }
};

static void
populate_import_table(pTHX)
{
    int i;
    for (i = 0; g_import_funcs[i].name; i++) {
        char full[256];
        CV *cv;
        snprintf(full, sizeof full,
                 "File::Raw::Separated::%s", g_import_funcs[i].name);
        cv = get_cv(full, 0);
        if (!cv || !CvISXSUB(cv))
            croak("File::Raw::Separated boot: missing XSUB '%s'", full);
        g_import_funcs[i].xs_func = CvXSUB(cv);
    }
}

static void
install_one(pTHX_ const char *pkg, const ImportEntry *e)
{
    char full[256];
    snprintf(full, sizeof full, "%s::file_%s", pkg, e->name);
    newXS(full, e->xs_func, __FILE__);
}

static void
install_range(pTHX_ const char *pkg, int lo, int hi)
{
    int i;
    for (i = lo; i < hi; i++) install_one(aTHX_ pkg, &g_import_funcs[i]);
}

XS_EXTERNAL(XS_File__Raw__Separated_import);
XS_EXTERNAL(XS_File__Raw__Separated_import)
{
    dXSARGS;
    const char *pkg = CopSTASHPV(PL_curcop);
    int i, j;
    int matched;

    /* No imports requested: bare `use File::Raw::Separated;` lands
     * here with items==1 (just the package name). Plugin BOOT has
     * already registered csv/tsv with File::Raw — nothing more to do. */
    if (items <= 1) XSRETURN_EMPTY;

    for (i = 1; i < items; i++) {
        STRLEN len;
        const char *arg = SvPV(ST(i), len);

        if (len > 0 && arg[0] == ':') {
            if (len == 4 && memcmp(arg, ":all", 4) == 0) {
                install_range(aTHX_ pkg, 0, IMPORT_TSV_HI);
                continue;
            }
            if (len == 8 && memcmp(arg, ":unified", 8) == 0) {
                install_range(aTHX_ pkg, IMPORT_UNIFIED_LO, IMPORT_UNIFIED_HI);
                continue;
            }
            if (len == 4 && memcmp(arg, ":csv", 4) == 0) {
                install_range(aTHX_ pkg, IMPORT_CSV_LO, IMPORT_CSV_HI);
                continue;
            }
            if (len == 4 && memcmp(arg, ":tsv", 4) == 0) {
                install_range(aTHX_ pkg, IMPORT_TSV_LO, IMPORT_TSV_HI);
                continue;
            }
            warn("File::Raw::Separated: unknown tag '%.*s'", (int)len, arg);
            continue;
        }

        /* Bare `import` is shorthand for `:all`, matching the File::Raw
         * idiom: `use File::Raw qw(import);`. */
        if (len == 6 && memcmp(arg, "import", 6) == 0) {
            install_range(aTHX_ pkg, 0, IMPORT_TSV_HI);
            continue;
        }

        matched = 0;
        for (j = 0; g_import_funcs[j].name; j++) {
            if (strlen(g_import_funcs[j].name) == len
                && memcmp(arg, g_import_funcs[j].name, len) == 0) {
                install_one(aTHX_ pkg, &g_import_funcs[j]);
                matched = 1;
                break;
            }
        }
        if (!matched)
            warn("File::Raw::Separated: '%.*s' is not exported",
                 (int)len, arg);
    }

    XSRETURN_EMPTY;
}

/* ============================================================
 * XS surface
 * ============================================================ */

MODULE = File::Raw::Separated   PACKAGE = File::Raw::Separated

PROTOTYPES: DISABLE

BOOT:
    /* Seed the per-dialect defaults the plugins point at. */
    separated_options_init_csv(&csv_default_opts);
    separated_options_init_tsv(&tsv_default_opts);

    /* Build and register the CSV plugin. Only the READ phase is wired
     * for now; WRITE/RECORD/STREAM stay NULL until the parser core
     * grows a serialiser and File::Raw teaches each_line/grep_lines
     * the plugin pipeline. */
    csv_plugin.name      = "csv";
    csv_plugin.read_fn   = sep_read;
    csv_plugin.write_fn  = sep_write;
    csv_plugin.record_fn = NULL;
    csv_plugin.stream_fn = sep_stream;
    csv_plugin.state     = &csv_default_opts;
    if (file_register_plugin(aTHX_ &csv_plugin) <= 0)
        warn("File::Raw::Separated: failed to register 'csv' plugin");

    tsv_plugin.name      = "tsv";
    tsv_plugin.read_fn   = sep_read;
    tsv_plugin.write_fn  = sep_write;
    tsv_plugin.record_fn = NULL;
    tsv_plugin.stream_fn = sep_stream;
    tsv_plugin.state     = &tsv_default_opts;
    if (file_register_plugin(aTHX_ &tsv_plugin) <= 0)
        warn("File::Raw::Separated: failed to register 'tsv' plugin");

    /* Populate g_import_funcs[].xs_func from the just-registered XSUBs;
     * the dispatcher uses these pointers when stamping `file_*` aliases
     * into callers' packages. Boot order: xsubpp emits the newXS_deffile
     * registrations *before* this initialisation block, so get_cv() is
     * guaranteed to find each one. */
    populate_import_table(aTHX);

    /* Override Exporter::import (we no longer inherit it; .pm has been
     * stripped of the Exporter glue) with our XS dispatcher so
     * `use File::Raw::Separated qw(...)` lands in our import directly. */
    newXS("File::Raw::Separated::import",
          XS_File__Raw__Separated_import, __FILE__);


# =====================================================================
# Parser entry points
# =====================================================================
#
# Nine XSUBs, three logical groups, all thin shims over the do_* helpers
# above:
#
#   Unified (dialect read from opts hash, defaults to csv):
#     parse_buf($input [, \%opts])               -> \@rows
#     parse_buf_each($input, $cb [, \%opts])
#     parse_stream($path, $cb [, \%opts])
#
#   CSV-pinned (dialect key in opts ignored):
#     csv_parse_buf, csv_parse_buf_each, csv_parse_stream
#
#   TSV-pinned:
#     tsv_parse_buf, tsv_parse_buf_each, tsv_parse_stream
#
# xsubpp registers them in package File::Raw::Separated; users get them
# under `file_` prefix in their own namespace via `use File::Raw::Separated
# qw(import|:all|:unified|:csv|:tsv|<name>)` (see import dispatcher above).
#
# parse_stream / *_parse_stream open the file directly via PerlLIO,
# bypassing File::Raw's read hook (no recursion / no double-parse).

SV *
parse_buf(input, opts = NULL)
        SV *input
        SV *opts
    CODE:
        RETVAL = do_parse_buf(aTHX_ "parse_buf", input, opts, DIALECT_AUTO);
    OUTPUT:
        RETVAL

SV *
csv_parse_buf(input, opts = NULL)
        SV *input
        SV *opts
    CODE:
        RETVAL = do_parse_buf(aTHX_ "csv_parse_buf", input, opts, DIALECT_CSV);
    OUTPUT:
        RETVAL

SV *
tsv_parse_buf(input, opts = NULL)
        SV *input
        SV *opts
    CODE:
        RETVAL = do_parse_buf(aTHX_ "tsv_parse_buf", input, opts, DIALECT_TSV);
    OUTPUT:
        RETVAL


void
parse_buf_each(input, code, opts = NULL)
        SV *input
        SV *code
        SV *opts
    PPCODE:
        do_parse_buf_each(aTHX_ "parse_buf_each", input, code, opts, DIALECT_AUTO);
        XSRETURN_EMPTY;

void
csv_parse_buf_each(input, code, opts = NULL)
        SV *input
        SV *code
        SV *opts
    PPCODE:
        do_parse_buf_each(aTHX_ "csv_parse_buf_each", input, code, opts, DIALECT_CSV);
        XSRETURN_EMPTY;

void
tsv_parse_buf_each(input, code, opts = NULL)
        SV *input
        SV *code
        SV *opts
    PPCODE:
        do_parse_buf_each(aTHX_ "tsv_parse_buf_each", input, code, opts, DIALECT_TSV);
        XSRETURN_EMPTY;


void
parse_stream(path, code, opts = NULL)
        SV *path
        SV *code
        SV *opts
    PPCODE:
        do_parse_stream(aTHX_ "parse_stream", path, code, opts, DIALECT_AUTO);
        XSRETURN_EMPTY;

void
csv_parse_stream(path, code, opts = NULL)
        SV *path
        SV *code
        SV *opts
    PPCODE:
        do_parse_stream(aTHX_ "csv_parse_stream", path, code, opts, DIALECT_CSV);
        XSRETURN_EMPTY;

void
tsv_parse_stream(path, code, opts = NULL)
        SV *path
        SV *code
        SV *opts
    PPCODE:
        do_parse_stream(aTHX_ "tsv_parse_stream", path, code, opts, DIALECT_TSV);
        XSRETURN_EMPTY;

