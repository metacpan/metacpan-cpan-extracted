/*
 * JSON.xs - File::Raw::JSON XS surface
 *
 * Two FilePlugins (json, jsonl) registered at BOOT against File::Raw's
 * plugin API (see <file_plugin.h>). All four phases wired:
 *   READ   - bytes -> Perl structure
 *   WRITE  - Perl structure -> bytes
 *   STREAM - chunked feed for jsonl (json plugin rejects with helpful msg)
 *   RECORD - not implemented (record-derived ops route through READ)
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "file_plugin.h"
#include "file_raw_json.h"

#include <string.h>
#include <stdlib.h>

/* ============================================================
 * Boolean singletons + default stash (declared extern in frj.h so the
 * codec can hand them out from the parse hot path). Allocated in
 * BOOT and marked read-only - users mutating the inner SV would
 * corrupt every other reference, so we make the OS catch the mistake
 * at write time. */

SV *g_frj_true_sv      = NULL;
SV *g_frj_false_sv     = NULL;
HV *g_frj_default_stash = NULL;

static const char *g_boolean_class_name = "File::Raw::JSON::Boolean";

static void
init_boolean_singletons(pTHX)
{
    SV *t_inner, *f_inner;
    if (g_frj_true_sv) return;

    g_frj_default_stash = gv_stashpv(g_boolean_class_name, GV_ADD);

    /* Singletons are NOT marked SvREADONLY: Perl's overload machinery
     * sets magic on the blessed RV the first time `use overload` is
     * processed against the class, and that magic write fails on a
     * read-only RV with "Modification of a read-only value". The
     * inner scalar could be read-only without breaking overload setup
     * but in practice overload-blessing also touches the inner state,
     * so we just leave both writable. The convention "don't mutate
     * the singleton" is documented; users who do are on their own. */
    t_inner = newSViv(1);
    f_inner = newSViv(0);
    g_frj_true_sv  = sv_bless(newRV_noinc(t_inner), g_frj_default_stash);
    g_frj_false_sv = sv_bless(newRV_noinc(f_inner), g_frj_default_stash);
}

static HV *
get_boolean_stash(pTHX)
{
    if (!g_frj_default_stash) init_boolean_singletons(aTHX);
    return g_frj_default_stash;
}

static HV *
resolve_boolean_stash(pTHX_ const char *class_name)
{
    if (!class_name) return get_boolean_stash(aTHX);
    return gv_stashpv(class_name, GV_ADD);
}

/* Alias an existing File::Raw::JSON CV into the caller's package
 * under the same short name.  Mirrors File::Raw's selective-import
 * recipe (file.c install_import_entry): create a fresh CV in the
 * destination glob whose XSUB pointer matches the source. */
static void
fjson_install_alias(pTHX_ const char *pkg, const char *name)
{
    char src_full[256];
    char dst_full[256];
    CV *src;
    snprintf(src_full, sizeof(src_full), "File::Raw::JSON::%s", name);
    snprintf(dst_full, sizeof(dst_full), "%s::%s", pkg, name);
    src = get_cv(src_full, 0);
    if (!src) {
        warn("File::Raw::JSON: source CV '%s' not found", src_full);
        return;
    }
    /* newXS overwrites the destination CV if one already exists. */
    newXS(dst_full, CvXSUB(src), __FILE__);
}

/* Build a transient options HV from a trailing key/value pair list.
 * Returns a mortal HV* or NULL if there are no options.  Croaks on
 * odd-count input.  Used by file_json_decode / file_json_encode -
 * lets us reuse decode_opts() unchanged.  ax/items mirror dXSARGS;
 * first_idx is the position of the first key on the stack. */
static HV *
build_opts_hv(pTHX_ I32 ax, I32 items, I32 first_idx, const char *fn)
{
    HV *opts;
    I32 i;
    if (first_idx >= items) return NULL;
    if ((items - first_idx) % 2 != 0)
        croak("%s: odd number of options", fn);
    opts = newHV();
    sv_2mortal((SV *)opts);
    for (i = first_idx; i + 1 < items; i += 2) {
        STRLEN klen;
        const char *key = SvPV(ST(i), klen);
        SV *vcopy = newSVsv(ST(i + 1));
        if (!hv_store(opts, key, klen, vcopy, 0))
            SvREFCNT_dec(vcopy);
    }
    return opts;
}

/* ============================================================
 * Option decoding
 *
 * Maps a Perl HV onto json_options_t. Unknown keys croak (catches
 * typos like 'pretty_print'). The boolean_class option is returned
 * separately because it lives outside the struct. */

static const char *VALID_OPT_KEYS[] = {
    "mode", "pretty", "indent", "sort_keys", "canonical",
    "utf8", "relaxed", "allow_nonref", "allow_nan_inf",
    "ordered",
    "max_depth", "eol", "boolean_class",
    "plugin",   /* present in HV file_plugin_dispatch_* builds */
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

static const char *
decode_opts(pTHX_ HV *opts_hv, json_options_t *o)
{
    const char *boolean_class = NULL;
    HE *he;

    if (!opts_hv) return NULL;

    hv_iterinit(opts_hv);
    while ((he = hv_iternext(opts_hv))) {
        I32 klen_i;
        const char *key = hv_iterkey(he, &klen_i);
        STRLEN klen = (STRLEN)klen_i;
        SV *val = hv_iterval(opts_hv, he);

        if (!known_opt(key, klen)) {
            croak("File::Raw::JSON: unknown option '%.*s'",
                  (int)klen, key);
        }
        if (!SvOK(val)) continue;

        if (klen == 4 && memcmp(key, "mode", 4) == 0) {
            STRLEN mlen;
            const char *mpv = SvPV(val, mlen);
            if (mlen == 8 && memcmp(mpv, "document", 8) == 0)
                o->mode = JSON_MODE_DOCUMENT;
            else if (mlen == 5 && memcmp(mpv, "lines", 5) == 0)
                o->mode = JSON_MODE_LINES;
            else
                croak("File::Raw::JSON: mode must be 'document' or 'lines' "
                      "(got '%.*s')", (int)mlen, mpv);
        }
        else if (klen == 6 && memcmp(key, "pretty", 6) == 0)
            o->pretty = SvTRUE(val) ? 1 : 0;
        else if (klen == 6 && memcmp(key, "indent", 6) == 0) {
            IV n = SvIV(val);
            if (n != 2 && n != 4)
                croak("File::Raw::JSON: indent must be 2 or 4 (got %ld); "
                      "arbitrary indent strings planned for v0.02",
                      (long)n);
            o->indent = (int)n;
        }
        else if (klen == 9 && memcmp(key, "sort_keys", 9) == 0)
            o->sort_keys = SvTRUE(val) ? 1 : 0;
        else if (klen == 9 && memcmp(key, "canonical", 9) == 0)
            o->canonical = SvTRUE(val) ? 1 : 0;
        else if (klen == 4 && memcmp(key, "utf8", 4) == 0)
            o->utf8 = SvTRUE(val) ? 1 : 0;
        else if (klen == 7 && memcmp(key, "relaxed", 7) == 0)
            o->relaxed = SvTRUE(val) ? 1 : 0;
        else if (klen == 12 && memcmp(key, "allow_nonref", 12) == 0)
            o->allow_nonref = SvTRUE(val) ? 1 : 0;
        else if (klen == 13 && memcmp(key, "allow_nan_inf", 13) == 0)
            o->allow_nan_inf = SvTRUE(val) ? 1 : 0;
        else if (klen == 7 && memcmp(key, "ordered", 7) == 0)
            o->ordered = SvTRUE(val) ? 1 : 0;
        else if (klen == 9 && memcmp(key, "max_depth", 9) == 0) {
            IV n = SvIV(val);
            if (n < 1) croak("File::Raw::JSON: max_depth must be >= 1");
            o->max_depth = (int)n;
        }
        else if (klen == 3 && memcmp(key, "eol", 3) == 0) {
            STRLEN elen;
            const char *epv = SvPV(val, elen);
            if (elen == 0 || elen > 3)
                croak("File::Raw::JSON: eol must be 1-3 bytes "
                      "(got %lu)", (unsigned long)elen);
            memcpy(o->eol, epv, elen);
            o->eol[elen] = '\0';
            o->eol_len = (int)elen;
        }
        else if (klen == 13 && memcmp(key, "boolean_class", 13) == 0) {
            STRLEN clen;
            boolean_class = SvPV(val, clen);
            (void)clen;
        }
        /* "plugin" is the dispatch key; ignore here. */
    }
    return boolean_class;
}

/* ============================================================
 * Plugin phase functions
 * ============================================================ */

/* Per-plugin state pointers (so the plugin descriptor can carry mode). */
static json_mode_t MODE_DOCUMENT_TAG = JSON_MODE_DOCUMENT;
static json_mode_t MODE_LINES_TAG    = JSON_MODE_LINES;

static SV *
json_read(pTHX_ FilePluginContext *ctx)
{
    json_options_t o;
    const char *boolean_class;
    HV *bool_stash;
    STRLEN len;
    const char *pv;

    json_options_defaults(&o);
    if (ctx->plugin_state)
        o.mode = *(const json_mode_t *)ctx->plugin_state;

    boolean_class = decode_opts(aTHX_ ctx->options, &o);
    bool_stash = resolve_boolean_stash(aTHX_ boolean_class);

    if (!ctx->data) return &PL_sv_undef;
    pv = SvPV(ctx->data, len);

    if (o.mode == JSON_MODE_LINES) {
        AV *av = json_decode_lines(aTHX_ pv, len, &o, bool_stash);
        return newRV_noinc((SV *)av);
    }
    return json_decode_document(aTHX_ pv, len, &o, bool_stash);
}

static SV *
json_write(pTHX_ FilePluginContext *ctx)
{
    json_options_t o;
    json_options_defaults(&o);
    if (ctx->plugin_state)
        o.mode = *(const json_mode_t *)ctx->plugin_state;
    (void)decode_opts(aTHX_ ctx->options, &o);

    if (o.mode == JSON_MODE_LINES) {
        return json_encode_lines(aTHX_ ctx->data, &o);
    }
    return json_encode_document(aTHX_ ctx->data, &o);
}

/* The 'json' plugin rejects STREAM with a helpful redirect. */
static int
json_stream_reject(pTHX_ FilePluginContext *ctx,
                   const char *chunk, size_t len, int eof)
{
    PERL_UNUSED_ARG(chunk);
    PERL_UNUSED_ARG(len);
    PERL_UNUSED_ARG(eof);
    ctx->cancel = 1;
    croak("File::Raw::JSON: the 'json' plugin does not support streaming; "
          "use 'jsonl' for concatenated JSON values, or slurp the whole "
          "document via File::Raw::slurp(...)");
    return 1;
}

/* ============================================================
 * jsonl streaming
 *
 * Buffers bytes across chunks; brace-balancer slices off complete
 * top-level values; each is parsed by yyjson and emitted via
 * call_sv(ctx->callback, ...). Mirrors File::Raw::Separated's
 * sep_stream pattern. State lives in ctx->call_state. */

typedef struct {
    char           *acc_buf;
    STRLEN          acc_len;
    STRLEN          acc_cap;
    json_options_t  opts;
    HV             *bool_stash;
    SV             *die_msg;        /* propagation slot */
} jsonl_stream_state_t;

static void
jsonl_stream_state_free(pTHX_ jsonl_stream_state_t *s)
{
    if (!s) return;
    if (s->acc_buf) Safefree(s->acc_buf);
    if (s->die_msg) SvREFCNT_dec(s->die_msg);
    Safefree(s);
}

static void
jsonl_acc_append(pTHX_ jsonl_stream_state_t *s, const char *p, STRLEN n)
{
    if (s->acc_len + n > s->acc_cap) {
        STRLEN newcap = s->acc_cap ? s->acc_cap : 8192;
        while (newcap < s->acc_len + n) newcap *= 2;
        Renew(s->acc_buf, newcap, char);
        s->acc_cap = newcap;
    }
    if (n) memcpy(s->acc_buf + s->acc_len, p, n);
    s->acc_len += n;
}

static int
jsonl_emit_one(pTHX_ FilePluginContext *ctx, jsonl_stream_state_t *s,
               const char *vp, STRLEN vlen)
{
    yyjson_read_err err;
    yyjson_doc *doc;
    SV *value;
    int count, rc = 0;
    SV *errsv;

    doc = yyjson_read_opts((char *)vp, (size_t)vlen,
                           0, NULL, &err);
    if (!doc) {
        char ctx_buf[64];
        STRLEN copy_len = vlen < sizeof(ctx_buf) - 1
                            ? vlen : sizeof(ctx_buf) - 1;
        memcpy(ctx_buf, vp, copy_len);
        ctx_buf[copy_len] = '\0';
        ctx->cancel = 1;
        croak("File::Raw::JSON: stream parse error: %s near \"%s\"",
              err.msg ? err.msg : "unknown", ctx_buf);
    }
    value = json_sv_from_yyjson(aTHX_ yyjson_doc_get_root(doc),
                                s->bool_stash, s->opts.ordered,
                                s->opts.max_depth);
    yyjson_doc_free(doc);

    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(value));
        PUTBACK;
        count = call_sv(ctx->callback, G_DISCARD | G_EVAL);
        SPAGAIN;
        PERL_UNUSED_VAR(count);
        errsv = ERRSV;
        if (SvTRUE(errsv)) {
            s->die_msg = newSVsv(errsv);
            rc = 1;
        }
        FREETMPS; LEAVE;
    }
    return rc;
}

static int
jsonl_drain_buffer(pTHX_ FilePluginContext *ctx, jsonl_stream_state_t *s,
                   int allow_truncate)
{
    STRLEN cursor = 0;
    while (cursor < s->acc_len) {
        STRLEN start, end, np;
        jsonl_scan_t rc = json_jsonl_next(s->acc_buf + cursor,
                                          s->acc_len - cursor,
                                          &start, &end, &np);
        if (rc == JSONL_FOUND) {
            if (jsonl_emit_one(aTHX_ ctx, s,
                               s->acc_buf + cursor + start, end - start)) {
                return 1;       /* user die */
            }
            cursor += np;
            continue;
        }
        if (rc == JSONL_NEED_MORE) {
            /* Shift the unconsumed prefix to the front and bail until
             * the next chunk arrives. The "junk before the value" case
             * (i.e. start > 0 with NEED_MORE) means leading whitespace
             * + truncated value; just shift everything from cursor. */
            if (cursor > 0) {
                memmove(s->acc_buf, s->acc_buf + cursor,
                        s->acc_len - cursor);
                s->acc_len -= cursor;
            }
            if (!allow_truncate) return 0;
            /* eof + truncated value: croak. */
            ctx->cancel = 1;
            croak("File::Raw::JSON: truncated trailing JSON value at end "
                  "of stream");
        }
        /* JSONL_NO_OPENER: only whitespace remains, or junk byte. */
        cursor += start;
        if (cursor >= s->acc_len) break;     /* all whitespace */
        if (s->opts.relaxed) { cursor++; continue; }
        ctx->cancel = 1;
        croak("File::Raw::JSON: unexpected byte at offset %lu in stream "
              "(expected '{' or '[' to start a JSONL value)",
              (unsigned long)cursor);
    }
    /* Drop the consumed prefix so the buffer doesn't grow without
     * bound across chunks. */
    if (cursor > 0 && cursor < s->acc_len) {
        memmove(s->acc_buf, s->acc_buf + cursor, s->acc_len - cursor);
        s->acc_len -= cursor;
    } else if (cursor >= s->acc_len) {
        s->acc_len = 0;
    }
    return 0;
}

static int
jsonl_stream(pTHX_ FilePluginContext *ctx,
             const char *chunk, size_t len, int eof)
{
    jsonl_stream_state_t *s = (jsonl_stream_state_t *)ctx->call_state;

    if (!s) {
        const char *boolean_class;
        Newxz(s, 1, jsonl_stream_state_t);
        json_options_defaults(&s->opts);
        if (ctx->plugin_state)
            s->opts.mode = *(const json_mode_t *)ctx->plugin_state;
        boolean_class = decode_opts(aTHX_ ctx->options, &s->opts);
        s->bool_stash = resolve_boolean_stash(aTHX_ boolean_class);
        s->acc_cap = 8192;
        Newx(s->acc_buf, s->acc_cap, char);
        s->acc_len = 0;
        ctx->call_state = s;
    }

    if (chunk && len > 0) {
        jsonl_acc_append(aTHX_ s, chunk, len);
    }

    if (jsonl_drain_buffer(aTHX_ ctx, s, eof ? 1 : 0)) {
        SV *die_msg = s->die_msg;
        STRLEN dlen;
        SV *m = die_msg ? newSVsv(die_msg) : NULL;
        jsonl_stream_state_free(aTHX_ s);
        ctx->call_state = NULL;
        ctx->cancel = 1;
        if (m) {
            const char *dpv = SvPV(m, dlen);
            sv_2mortal(m);
            croak("%.*s", (int)dlen, dpv);
        }
        croak("File::Raw::JSON: stream cancelled");
    }

    if (eof) {
        jsonl_stream_state_free(aTHX_ s);
        ctx->call_state = NULL;
    }
    return 0;
}

/* ============================================================
 * Plugin descriptors. Statics so the registry's non-owning pointer
 * stays valid for the life of the process.
 * ============================================================ */

static FilePlugin json_plugin;
static FilePlugin jsonl_plugin;

/* ============================================================ */

MODULE = File::Raw::JSON    PACKAGE = File::Raw::JSON

PROTOTYPES: DISABLE

# ---- direct in-memory codec entry points ------------------------
#
# file_json_decode($bytes, ?key => value, ...)  -> parsed value
# file_json_encode($value, ?key => value, ...)  -> JSON bytes
#
# These bypass File::Raw's plugin pipeline entirely - no path, no
# syscalls, just bytes <-> Perl structure.  Same options grammar as
# the plugin tail (mode, pretty, indent, sort_keys, canonical,
# ordered, relaxed, allow_nonref, allow_nan_inf, max_depth, eol,
# boolean_class, utf8); odd-count tails croak.  See build_opts_hv
# above the first MODULE block for the option-collection helper.

# File::Raw::JSON->import(...) - selective installer.  Mirrors
# File::Raw's pattern (file.c XS_file_import).  `use File::Raw::JSON`
# with no arg list = no-op; with a list of names, each requested
# function CV is aliased into the caller's package via newXS, sharing
# the underlying XSUB pointer with the source CV.
#
# Recognised: file_json_decode, file_json_encode, :codec (= both),
# :all (= same).  Unknown names warn but don't die, matching File::Raw.
void
import(...)
PREINIT:
    const char *pkg;
    I32 i;
PPCODE:
    pkg = CopSTASHPV(PL_curcop);
    if (items <= 1) XSRETURN_EMPTY;

    for (i = 1; i < items; i++) {
        STRLEN len;
        const char *arg = SvPV(ST(i), len);

        if ((len == 6 && strEQ(arg, ":codec")) ||
            (len == 4 && strEQ(arg, ":all")))
        {
            fjson_install_alias(aTHX_ pkg, "file_json_decode");
            fjson_install_alias(aTHX_ pkg, "file_json_encode");
            continue;
        }
        if ((len == 16 && strEQ(arg, "file_json_decode")) ||
            (len == 16 && strEQ(arg, "file_json_encode")))
        {
            fjson_install_alias(aTHX_ pkg, arg);
            continue;
        }
        warn("File::Raw::JSON: '%.*s' is not exported", (int)len, arg);
    }
    XSRETURN_EMPTY;

SV *
file_json_decode(bytes, ...)
    SV *bytes
PREINIT:
    json_options_t o;
    HV *opts_hv;
    const char *boolean_class;
    HV *bool_stash;
    STRLEN len;
    const char *pv;
CODE:
    json_options_defaults(&o);
    o.mode = JSON_MODE_DOCUMENT;
    opts_hv = build_opts_hv(aTHX_ ax, items, 1, "file_json_decode");
    boolean_class = decode_opts(aTHX_ opts_hv, &o);
    bool_stash = resolve_boolean_stash(aTHX_ boolean_class);

    if (!bytes || !SvOK(bytes)) XSRETURN_UNDEF;
    pv = SvPV(bytes, len);

    if (o.mode == JSON_MODE_LINES) {
        AV *av = json_decode_lines(aTHX_ pv, len, &o, bool_stash);
        RETVAL = newRV_noinc((SV *)av);
    } else {
        SV *out = json_decode_document(aTHX_ pv, len, &o, bool_stash);
        RETVAL = out ? out : &PL_sv_undef;
        if (RETVAL == &PL_sv_undef) SvREFCNT_inc(RETVAL);
    }
OUTPUT:
    RETVAL

SV *
file_json_encode(value, ...)
    SV *value
PREINIT:
    json_options_t o;
    HV *opts_hv;
CODE:
    json_options_defaults(&o);
    o.mode = JSON_MODE_DOCUMENT;
    opts_hv = build_opts_hv(aTHX_ ax, items, 1, "file_json_encode");
    (void)decode_opts(aTHX_ opts_hv, &o);

    if (o.mode == JSON_MODE_LINES) {
        RETVAL = json_encode_lines(aTHX_ value, &o);
    } else {
        RETVAL = json_encode_document(aTHX_ value, &o);
    }
    if (!RETVAL) {
        RETVAL = &PL_sv_undef;
        SvREFCNT_inc(RETVAL);
    }
OUTPUT:
    RETVAL

BOOT:
{
    init_boolean_singletons(aTHX);

    json_plugin.name      = "json";
    json_plugin.read_fn   = json_read;
    json_plugin.write_fn  = json_write;
    json_plugin.record_fn = NULL;
    json_plugin.stream_fn = json_stream_reject;
    json_plugin.state     = &MODE_DOCUMENT_TAG;
    if (file_register_plugin(aTHX_ &json_plugin) <= 0)
        warn("File::Raw::JSON: failed to register 'json' plugin");

    jsonl_plugin.name      = "jsonl";
    jsonl_plugin.read_fn   = json_read;     /* mode tag selects MODE_LINES */
    jsonl_plugin.write_fn  = json_write;
    jsonl_plugin.record_fn = NULL;
    jsonl_plugin.stream_fn = jsonl_stream;
    jsonl_plugin.state     = &MODE_LINES_TAG;
    if (file_register_plugin(aTHX_ &jsonl_plugin) <= 0)
        warn("File::Raw::JSON: failed to register 'jsonl' plugin");
}


# ============================================================
# File::Raw::JSON::Boolean - XSUB constructors + overload bodies
# ============================================================
#
# All four overload entry points (bool / numify / stringify / not)
# run as XSUBs rather than Perl subs, ~3x faster than the pure-Perl
# overload that was here before. The overload table itself is still
# wired up by `use overload ...` in Boolean.pm - that's the cheapest
# way to register, and the dispatch cost is identical regardless of
# whether the body is a Perl sub or an XSUB.
#
# Calling convention: overload invokes our handlers with three args
# (self, other, swap). We only need self; ignore the rest. Returning
# the static PL_sv_yes / PL_sv_no avoids per-call SV allocation.

MODULE = File::Raw::JSON    PACKAGE = File::Raw::JSON::Boolean

PROTOTYPES: DISABLE

void
TRUE(...)
    PPCODE:
        PERL_UNUSED_VAR(items);
        if (!g_frj_true_sv) init_boolean_singletons(aTHX);
        SvREFCNT_inc_simple_void(g_frj_true_sv);
        XPUSHs(sv_2mortal(g_frj_true_sv));
        XSRETURN(1);

void
FALSE(...)
    PPCODE:
        PERL_UNUSED_VAR(items);
        if (!g_frj_false_sv) init_boolean_singletons(aTHX);
        SvREFCNT_inc_simple_void(g_frj_false_sv);
        XPUSHs(sv_2mortal(g_frj_false_sv));
        XSRETURN(1);

SV *
overload_bool(self, other, swap)
    SV *self
    SV *other
    SV *swap
    OVERLOAD: bool
    CODE:
        PERL_UNUSED_VAR(other);
        PERL_UNUSED_VAR(swap);
        RETVAL = (SvROK(self) && SvTRUE(SvRV(self)))
                   ? &PL_sv_yes : &PL_sv_no;
        SvREFCNT_inc_simple_void(RETVAL);  /* OUTPUT typemap will mortalise */
    OUTPUT:
        RETVAL

SV *
overload_numify(self, other, swap)
    SV *self
    SV *other
    SV *swap
    OVERLOAD: 0+
    CODE:
        PERL_UNUSED_VAR(other);
        PERL_UNUSED_VAR(swap);
        RETVAL = newSViv(
            (SvROK(self) && SvTRUE(SvRV(self))) ? 1 : 0
        );
    OUTPUT:
        RETVAL

SV *
overload_stringify(self, other, swap)
    SV *self
    SV *other
    SV *swap
    OVERLOAD: \"\"
    CODE:
        PERL_UNUSED_VAR(other);
        PERL_UNUSED_VAR(swap);
        RETVAL = newSVpvn(
            (SvROK(self) && SvTRUE(SvRV(self))) ? "1" : "0", 1
        );
    OUTPUT:
        RETVAL

SV *
overload_not(self, other, swap)
    SV *self
    SV *other
    SV *swap
    OVERLOAD: !
    CODE:
        PERL_UNUSED_VAR(other);
        PERL_UNUSED_VAR(swap);
        if (SvROK(self) && SvTRUE(SvRV(self)))
            RETVAL = newSVpvn("", 0);
        else
            RETVAL = newSViv(1);
    OUTPUT:
        RETVAL

int
is_true(self)
    SV *self
    CODE:
        RETVAL = (SvROK(self) && sv_isa(self, "File::Raw::JSON::Boolean")
                  && SvTRUE(SvRV(self))) ? 1 : 0;
    OUTPUT:
        RETVAL

int
is_false(self)
    SV *self
    CODE:
        RETVAL = (SvROK(self) && sv_isa(self, "File::Raw::JSON::Boolean")
                  && !SvTRUE(SvRV(self))) ? 1 : 0;
    OUTPUT:
        RETVAL
