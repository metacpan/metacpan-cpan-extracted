/*
 * Base64.xs - File::Raw plugin bindings for File::Raw::Base64.
 *
 * Two plugins registered at BOOT:
 *   "base64"    - standard alphabet (RFC 4648 §4)
 *   "base64url" - URL-safe alphabet (RFC 4648 §5)
 *
 * Both share the same C codec (b64.c). The plugin's `state` slot
 * carries an integer flag (0 / 1) telling the read/write callbacks
 * which alphabet to seed; per-call options merge on top via the
 * standard FilePluginContext::options HV.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* file_plugin.h comes from File::Raw via ExtUtils::Depends -- the
   consumer Makefile.PL adds the right -I to find it. */
#include "file_plugin.h"
#include "b64.h"

#include <string.h>

/* ============================================================
 * Option decoding
 * ============================================================ */

static const char *VALID_OPT_KEYS[] = {
    "wrap", "urlsafe", "padding", "pem", "pem_label", "strict", "eol",
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

/* Holds string SVs we extract from the options HV so the C strings
 * outlive the call into b64_*. The HV itself is mortal in File::Raw's
 * dispatch, so the string PVs are valid for the call duration anyway —
 * but we copy into the struct's own slots to keep the lifetime
 * obviously local. */
typedef struct {
    b64_options_t opts;
    /* Backing storage for opts.pem_label and opts.eol. The caller
     * passes these through the options HV; we point at the SV's PV
     * since the HV stays mortal until after the b64 call returns. */
} decode_state_t;

static void
decode_opts(pTHX_ HV *opts_hv, b64_options_t *opts)
{
    HE *he;

    if (!opts_hv) return;

    hv_iterinit(opts_hv);
    while ((he = hv_iternext(opts_hv))) {
        I32 klen_i;
        const char *key;
        STRLEN klen;
        SV *val;

        key  = hv_iterkey(he, &klen_i);
        klen = (STRLEN)klen_i;
        val  = hv_iterval(opts_hv, he);

        if (!known_opt(key, klen)) {
            croak("File::Raw::Base64: unknown option '%.*s'",
                  (int)klen, key);
        }
        if (!SvOK(val)) continue;

        if (klen == 4 && memcmp(key, "wrap", 4) == 0) {
            IV n = SvIV(val);
            if (n < 0) croak("File::Raw::Base64: wrap must be >= 0");
            opts->wrap = (int)n;
        } else if (klen == 7 && memcmp(key, "urlsafe", 7) == 0) {
            opts->urlsafe = SvTRUE(val) ? 1 : 0;
        } else if (klen == 7 && memcmp(key, "padding", 7) == 0) {
            opts->padding = SvTRUE(val) ? 1 : 0;
        } else if (klen == 3 && memcmp(key, "pem", 3) == 0) {
            opts->pem = SvTRUE(val) ? 1 : 0;
        } else if (klen == 9 && memcmp(key, "pem_label", 9) == 0) {
            STRLEN llen;
            const char *lp;
            lp = SvPV(val, llen);
            if (llen == 0)
                croak("File::Raw::Base64: pem_label must be non-empty");
            /* memchr for NUL: PEM markers can't contain NULs. */
            if (memchr(lp, '\0', llen) != NULL)
                croak("File::Raw::Base64: pem_label must not contain NUL");
            opts->pem_label = lp;
        } else if (klen == 6 && memcmp(key, "strict", 6) == 0) {
            opts->strict = SvTRUE(val) ? 1 : 0;
        } else if (klen == 3 && memcmp(key, "eol", 3) == 0) {
            STRLEN elen;
            const char *ep;
            ep = SvPV(val, elen);
            if (elen == 0 || elen > 2)
                croak("File::Raw::Base64: eol must be 1 or 2 bytes");
            opts->eol = ep;
        }
        /* "plugin" key: ignored. */
    }
}

/* ============================================================
 * Plugin callbacks
 * ============================================================ */

/* Plugin state is a tiny `int` (0 = standard alphabet, 1 = URL-safe).
 * We use a static int per plugin and stash its address in
 * FilePlugin.state. */
static int alphabet_std = 0;
static int alphabet_url = 1;

static void
seed_from_state(b64_options_t *opts, void *state)
{
    b64_options_init(opts);
    if (state) {
        opts->urlsafe = *(int *)state;
    }
}

static SV *
b64_read_cb(pTHX_ FilePluginContext *ctx)
{
    b64_options_t opts;
    STRLEN ilen;
    const char *ipv;
    unsigned char *out = NULL;
    size_t out_cap = 0, out_len = 0, err_off = 0;
    int rc;
    SV *result;

    seed_from_state(&opts, ctx->plugin_state);
    if (ctx->options) decode_opts(aTHX_ ctx->options, &opts);

    if (!ctx->data) return &PL_sv_undef;
    ipv = SvPV(ctx->data, ilen);

    rc = b64_decode(ipv, ilen, &opts, &out, &out_cap, &out_len, &err_off);
    if (rc != B64_OK) {
        free(out);
        croak("File::Raw::Base64: %s at byte offset %lu",
              b64_strerror(rc), (unsigned long)err_off);
    }

    result = newSVpvn(out_len ? (const char *)out : "", out_len);
    free(out);
    return result;
}

static SV *
b64_write_cb(pTHX_ FilePluginContext *ctx)
{
    b64_options_t opts;
    STRLEN ilen;
    const char *ipv;
    char *out = NULL;
    size_t out_cap = 0, out_len = 0, err_off = 0;
    int rc;
    SV *result;

    seed_from_state(&opts, ctx->plugin_state);
    if (ctx->options) decode_opts(aTHX_ ctx->options, &opts);

    if (!ctx->data) return &PL_sv_undef;
    ipv = SvPV(ctx->data, ilen);

    rc = b64_encode((const unsigned char *)ipv, ilen, &opts,
                    &out, &out_cap, &out_len, &err_off);
    if (rc != B64_OK) {
        free(out);
        croak("File::Raw::Base64: %s at byte offset %lu",
              b64_strerror(rc), (unsigned long)err_off);
    }

    result = newSVpvn(out_len ? out : "", out_len);
    free(out);
    return result;
}

/* Plugin descriptors. Static-storage lifetime so the registry's
 * non-owning pointer stays valid for the life of the process. */
static FilePlugin base64_plugin;
static FilePlugin base64url_plugin;

/* ============================================================ */

MODULE = File::Raw::Base64   PACKAGE = File::Raw::Base64

PROTOTYPES: DISABLE

BOOT:
    memset(&base64_plugin,    0, sizeof base64_plugin);
    memset(&base64url_plugin, 0, sizeof base64url_plugin);
    base64_plugin.name      = "base64";
    base64_plugin.read_fn   = b64_read_cb;
    base64_plugin.write_fn  = b64_write_cb;
    base64_plugin.state     = &alphabet_std;
    base64url_plugin.name     = "base64url";
    base64url_plugin.read_fn  = b64_read_cb;
    base64url_plugin.write_fn = b64_write_cb;
    base64url_plugin.state    = &alphabet_url;
    file_register_plugin(aTHX_ &base64_plugin);
    file_register_plugin(aTHX_ &base64url_plugin);
