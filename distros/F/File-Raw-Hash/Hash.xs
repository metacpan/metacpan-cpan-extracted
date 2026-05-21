/*
 * Hash.xs - File::Raw plugin bindings for File::Raw::Hash.
 *
 *   file_slurp($p, plugin => 'hash', algo => 'sha256', into => \my $d);
 *   file_slurp($p, plugin => 'hash', algos => [qw(sha256 md5)],
 *                                    into  => \my %digests);
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "file_plugin.h"
#include "hashx.h"

#include <string.h>
#include <stdlib.h>

/* ============================================================
 * Resolved options for a single plugin call.
 * ============================================================ */

#define MAX_ALGOS 8

typedef struct {
    hash_algo_id_t ids[MAX_ALGOS];
    int            n_ids;
    int            multi;          /* 0 = `algo`, 1 = `algos` */
    hash_format_t  format;
    SV            *into;           /* the user's ref SV; not refcount-bumped here */
    SV            *hmac_key_sv;    /* NULL if not set */
    int            xxh64_seed_set;
    uint64_t       xxh64_seed;
} hash_opts_t;

/* Phase context for `into` validation. RECORD wants an arrayref
 * because we push one entry per record; READ/WRITE/STREAM want a
 * scalar (single algo) or hash (multi-algo) ref. */
typedef enum {
    PHASE_ONE_SHOT = 0,
    PHASE_RECORD   = 1
} decode_phase_t;

static int
str_eq(const char *a, STRLEN alen, const char *b)
{
    return alen == strlen(b) && memcmp(a, b, alen) == 0;
}

static const char *VALID_OPT_KEYS[] = {
    "algo", "algos", "into", "format",
    "hmac_key", "xxh64_seed",
    "plugin",   /* always present from the dispatcher */
    NULL
};

static int
known_opt(const char *key, STRLEN klen)
{
    const char *const *p;
    for (p = VALID_OPT_KEYS; *p; p++) {
        if (str_eq(key, klen, *p)) return 1;
    }
    return 0;
}

/* Parse one algo name SV, croak on unknown. */
static hash_algo_id_t
parse_algo_sv(pTHX_ SV *sv)
{
    STRLEN alen;
    const char *ap;
    const hash_algo_info_t *info;

    if (!SvOK(sv))
        croak("File::Raw::Hash: algo name must not be undef");
    if (SvROK(sv))
        croak("File::Raw::Hash: algo name must be a string, not a reference");
    ap = SvPV(sv, alen);
    info = hash_algo_lookup(ap, alen);
    if (!info)
        croak("File::Raw::Hash: unknown algo '%.*s' "
              "(known: sha256 sha512 sha1 md5 crc32 xxh64 blake3)",
              (int)alen, ap);
    return info->id;
}

/* Decode the per-call options HV into a hash_opts_t. Croaks on any
 * validation failure. Caller passes a zeroed struct. */
static void
decode_opts(pTHX_ HV *opts_hv, hash_opts_t *opts, decode_phase_t phase)
{
    HE *he;
    SV *algo_sv  = NULL;
    SV *algos_sv = NULL;
    SV *fmt_sv   = NULL;
    SV *seed_sv  = NULL;

    if (!opts_hv) croak("File::Raw::Hash: missing options");

    /* First pass: validate keys + grab the ones we care about. */
    hv_iterinit(opts_hv);
    while ((he = hv_iternext(opts_hv))) {
        I32 klen_i;
        const char *key = hv_iterkey(he, &klen_i);
        STRLEN klen = (STRLEN)klen_i;
        SV *val = hv_iterval(opts_hv, he);

        if (!known_opt(key, klen)) {
            croak("File::Raw::Hash: unknown option '%.*s' (known: algo, "
                  "algos, into, format, hmac_key, xxh64_seed)",
                  (int)klen, key);
        }
        if      (str_eq(key, klen, "algo"))       algo_sv  = val;
        else if (str_eq(key, klen, "algos"))      algos_sv = val;
        else if (str_eq(key, klen, "into"))       opts->into = val;
        else if (str_eq(key, klen, "format"))     fmt_sv = val;
        else if (str_eq(key, klen, "hmac_key"))   opts->hmac_key_sv = val;
        else if (str_eq(key, klen, "xxh64_seed")) seed_sv = val;
        /* "plugin" key: silently ignored. */
    }

    /* Mutual exclusion. */
    if (algo_sv && SvOK(algo_sv) && algos_sv && SvOK(algos_sv))
        croak("File::Raw::Hash: 'algo' and 'algos' are mutually exclusive");

    /* Resolve algorithm list. */
    if (algos_sv && SvOK(algos_sv)) {
        AV *av;
        SSize_t n, i;
        if (!SvROK(algos_sv) || SvTYPE(SvRV(algos_sv)) != SVt_PVAV)
            croak("File::Raw::Hash: 'algos' must be an arrayref");
        av = (AV *)SvRV(algos_sv);
        n  = av_len(av) + 1;
        if (n < 1)
            croak("File::Raw::Hash: 'algos' arrayref is empty");
        if (n > MAX_ALGOS)
            croak("File::Raw::Hash: too many algos (%ld); max %d",
                  (long)n, MAX_ALGOS);
        for (i = 0; i < n; i++) {
            SV **slot = av_fetch(av, i, 0);
            if (!slot || !*slot)
                croak("File::Raw::Hash: undef entry in 'algos' at index %ld",
                      (long)i);
            opts->ids[i] = parse_algo_sv(aTHX_ *slot);
        }
        opts->n_ids = (int)n;
        opts->multi = 1;
    } else if (algo_sv && SvOK(algo_sv)) {
        opts->ids[0] = parse_algo_sv(aTHX_ algo_sv);
        opts->n_ids  = 1;
        opts->multi  = 0;
    } else {
        /* Default: single sha256. */
        opts->ids[0] = HA_SHA256;
        opts->n_ids  = 1;
        opts->multi  = 0;
    }

    /* Resolve format. */
    if (fmt_sv && SvOK(fmt_sv)) {
        STRLEN flen;
        const char *fp;
        if (SvROK(fmt_sv))
            croak("File::Raw::Hash: 'format' must be a string");
        fp = SvPV(fmt_sv, flen);
        if (hash_format_parse(fp, flen, &opts->format) != 0)
            croak("File::Raw::Hash: unknown format '%.*s' "
                  "(known: hex, HEX, base64, base64url, raw)",
                  (int)flen, fp);
    } else {
        opts->format = HF_HEX;
    }

    /* Resolve xxh64_seed. */
    if (seed_sv && SvOK(seed_sv)) {
        if (SvROK(seed_sv))
            croak("File::Raw::Hash: 'xxh64_seed' must be an integer");
        opts->xxh64_seed     = (uint64_t)SvUV(seed_sv);
        opts->xxh64_seed_set = 1;
    }

    /* HMAC key validation. The key itself can be any byte string
     * including binary / empty. Only the value's *type* is checked
     * here; per-algo HMAC-able-ness is checked when set_hmac runs. */
    if (opts->hmac_key_sv && SvOK(opts->hmac_key_sv)) {
        int j;
        if (SvROK(opts->hmac_key_sv))
            croak("File::Raw::Hash: 'hmac_key' must be a byte string, "
                  "not a reference");
        for (j = 0; j < opts->n_ids; j++) {
            const hash_algo_info_t *info = hash_algo_by_id(opts->ids[j]);
            if (!info->hmac_able)
                croak("File::Raw::Hash: HMAC is not defined for algo "
                      "'%s' (HMAC-able: sha256, sha512, sha1, md5)",
                      info->name);
        }
    } else {
        opts->hmac_key_sv = NULL;
    }

    /* Validate `into`. Required; shape depends on phase. */
    if (!opts->into || !SvOK(opts->into))
        croak("File::Raw::Hash: 'into' is required");
    if (!SvROK(opts->into))
        croak("File::Raw::Hash: 'into' must be a reference");

    if (phase == PHASE_RECORD) {
        if (SvTYPE(SvRV(opts->into)) != SVt_PVAV)
            croak("File::Raw::Hash: in record phase, 'into' must be an "
                  "ARRAY ref (one entry pushed per record)");
        return;
    }

    if (opts->multi) {
        if (SvTYPE(SvRV(opts->into)) != SVt_PVHV)
            croak("File::Raw::Hash: 'into' must be a hash ref when "
                  "'algos' is used");
    } else {
        SV *referent = SvRV(opts->into);
        svtype t = SvTYPE(referent);
        if (t == SVt_PVAV || t == SVt_PVHV || t == SVt_PVCV
            || t == SVt_PVGV || t == SVt_PVFM || t == SVt_PVIO)
            croak("File::Raw::Hash: 'into' must be a SCALAR ref for "
                  "single-algo (got %s ref)", sv_reftype(referent, 0));
    }
}

/* Helper: build, run and finalise a runner over the given bytes,
 * applying HMAC if a key is present. Returns 0 on success, croaks on
 * setup error. results[*] is owned by the runner and lives until
 * hash_runner_free. */
static void
run_full(pTHX_ const hash_opts_t *opts,
         const char *data, size_t len,
         hash_runner_t *runner, const hash_result_t **out_results)
{
    if (hash_runner_init(runner, opts->ids, opts->n_ids, opts->format,
                         opts->xxh64_seed) != 0)
        croak("File::Raw::Hash: out of memory initialising runner");

    if (opts->hmac_key_sv) {
        STRLEN klen;
        const unsigned char *kp =
            (const unsigned char *)SvPV(opts->hmac_key_sv, klen);
        if (hash_runner_set_hmac(runner, kp, (size_t)klen) != 0) {
            hash_runner_free(runner);
            /* Only reachable if a non-HMAC-able algo slipped past
             * decode_opts; defensive. */
            croak("File::Raw::Hash: HMAC mode rejected for the requested "
                  "algorithm set");
        }
    }

    if (data && len) hash_runner_update(runner, data, len);

    if (hash_runner_finish(runner, out_results) != 0) {
        hash_runner_free(runner);
        croak("File::Raw::Hash: out of memory finalising runner");
    }
}

/* Write digest results into the user's `into` target (READ/WRITE/STREAM
 * shape). For RECORD phase use append_record_results. */
static void
emit_results(pTHX_ const hash_opts_t *opts, const hash_result_t *results)
{
    int i;
    if (opts->multi) {
        HV *h = (HV *)SvRV(opts->into);
        for (i = 0; i < opts->n_ids; i++) {
            const hash_result_t *r = &results[i];
            SV *val = newSVpvn(r->out, r->out_len);
            if (opts->format != HF_RAW) SvUTF8_off(val);
            (void)hv_store(h, r->name, (I32)strlen(r->name), val, 0);
        }
    } else {
        SV *target = SvRV(opts->into);
        const hash_result_t *r = &results[0];
        sv_setpvn(target, r->out, r->out_len);
        if (opts->format != HF_RAW) SvUTF8_off(target);
    }
}

/* RECORD-phase emission: push one element into the user's arrayref.
 * Element shape mirrors the READ/WRITE convention:
 *   single algo  -> a scalar  (the digest)
 *   multi  algos -> a hashref (algo => digest, ...)
 */
static void
append_record_results(pTHX_ const hash_opts_t *opts,
                      const hash_result_t *results)
{
    AV *av = (AV *)SvRV(opts->into);
    int i;
    if (opts->multi) {
        HV *h = newHV();
        for (i = 0; i < opts->n_ids; i++) {
            const hash_result_t *r = &results[i];
            SV *val = newSVpvn(r->out, r->out_len);
            if (opts->format != HF_RAW) SvUTF8_off(val);
            (void)hv_store(h, r->name, (I32)strlen(r->name), val, 0);
        }
        av_push(av, newRV_noinc((SV *)h));
    } else {
        const hash_result_t *r = &results[0];
        SV *val = newSVpvn(r->out, r->out_len);
        if (opts->format != HF_RAW) SvUTF8_off(val);
        av_push(av, val);
    }
}

/* ============================================================
 * READ / WRITE callbacks (passthrough + side-channel digest).
 * ============================================================ */

static SV *
hash_one_shot(pTHX_ FilePluginContext *ctx)
{
    hash_opts_t opts;
    hash_runner_t runner;
    const hash_result_t *results = NULL;
    STRLEN dlen = 0;
    const char *dp = NULL;

    memset(&opts,   0, sizeof opts);
    memset(&runner, 0, sizeof runner);

    decode_opts(aTHX_ ctx->options, &opts, PHASE_ONE_SHOT);

    if (ctx->data && SvOK(ctx->data)) dp = SvPV(ctx->data, dlen);

    run_full(aTHX_ &opts, dp, (size_t)dlen, &runner, &results);
    emit_results(aTHX_ &opts, results);
    hash_runner_free(&runner);

    /* Passthrough. */
    if (!ctx->data) return newSVpvn("", 0);
    return SvREFCNT_inc_simple_NN(ctx->data);
}

static SV *
hash_read_cb(pTHX_ FilePluginContext *ctx)
{
    return hash_one_shot(aTHX_ ctx);
}

static SV *
hash_write_cb(pTHX_ FilePluginContext *ctx)
{
    return hash_one_shot(aTHX_ ctx);
}

/* ============================================================
 * RECORD callback (one digest per record, pushed into arrayref).
 * ============================================================ */

static SV *
hash_record_cb(pTHX_ FilePluginContext *ctx, SV *record)
{
    hash_opts_t opts;
    hash_runner_t runner;
    const hash_result_t *results = NULL;
    STRLEN dlen = 0;
    const char *dp = NULL;

    memset(&opts,   0, sizeof opts);
    memset(&runner, 0, sizeof runner);

    decode_opts(aTHX_ ctx->options, &opts, PHASE_RECORD);

    if (record && SvOK(record)) dp = SvPV(record, dlen);

    run_full(aTHX_ &opts, dp, (size_t)dlen, &runner, &results);
    append_record_results(aTHX_ &opts, results);
    hash_runner_free(&runner);

    /* Passthrough the record so downstream filters / map_lines see it
     * unchanged. The dispatcher mortalises on its way out. */
    if (!record) return &PL_sv_undef;
    return SvREFCNT_inc_simple_NN(record);
}

/* ============================================================
 * STREAM callback.
 * ============================================================ */

typedef struct {
    hash_runner_t runner;
    hash_opts_t   opts;
    SV           *into_ref;   /* +1 refcount */
} hash_stream_state_t;

static int
hash_stream_cb(pTHX_ FilePluginContext *ctx,
               const char *chunk, size_t len, int eof)
{
    hash_stream_state_t *st = (hash_stream_state_t *)ctx->call_state;

    if (!st) {
        st = (hash_stream_state_t *)calloc(1, sizeof *st);
        if (!st) {
            warn("File::Raw::Hash: stream alloc failed");
            ctx->cancel = 1;
            return 1;
        }
        decode_opts(aTHX_ ctx->options, &st->opts, PHASE_ONE_SHOT);
        if (hash_runner_init(&st->runner, st->opts.ids, st->opts.n_ids,
                             st->opts.format, st->opts.xxh64_seed) != 0) {
            free(st);
            warn("File::Raw::Hash: stream runner init failed");
            ctx->cancel = 1;
            return 1;
        }
        if (st->opts.hmac_key_sv) {
            STRLEN klen;
            const unsigned char *kp =
                (const unsigned char *)SvPV(st->opts.hmac_key_sv, klen);
            if (hash_runner_set_hmac(&st->runner, kp, (size_t)klen) != 0) {
                hash_runner_free(&st->runner);
                free(st);
                warn("File::Raw::Hash: stream HMAC setup failed");
                ctx->cancel = 1;
                return 1;
            }
        }
        st->into_ref = SvREFCNT_inc_simple_NN(st->opts.into);
        ctx->call_state = st;
    }

    if (chunk && len) {
        hash_runner_update(&st->runner, chunk, len);
    }

    if (eof) {
        const hash_result_t *results = NULL;
        if (hash_runner_finish(&st->runner, &results) != 0) {
            hash_runner_free(&st->runner);
            SvREFCNT_dec(st->into_ref);
            free(st);
            ctx->call_state = NULL;
            warn("File::Raw::Hash: stream finish failed");
            ctx->cancel = 1;
            return 1;
        }
        emit_results(aTHX_ &st->opts, results);
        hash_runner_free(&st->runner);
        SvREFCNT_dec(st->into_ref);
        free(st);
        ctx->call_state = NULL;
    }

    return 0; /* continue */
}

/* ============================================================ */

static FilePlugin hash_plugin;

MODULE = File::Raw::Hash   PACKAGE = File::Raw::Hash

PROTOTYPES: DISABLE

BOOT:
    memset(&hash_plugin, 0, sizeof hash_plugin);
    hash_plugin.name      = "hash";
    hash_plugin.read_fn   = hash_read_cb;
    hash_plugin.write_fn  = hash_write_cb;
    hash_plugin.record_fn = hash_record_cb;
    hash_plugin.stream_fn = hash_stream_cb;
    file_register_plugin(aTHX_ &hash_plugin);

# ============================================================
# Test helper: invoke the hash plugin's record_fn through File::Raw's
# dispatch_record entry point. Public name has a leading underscore to
# signal "not part of the supported API" - it exists so the test suite
# can exercise RECORD phase end-to-end before File::Raw exposes a
# user-facing per-record iterator.
# ============================================================

SV*
_test_record_one(record_sv, ...)
        SV *record_sv
    PREINIT:
        HV *opts;
        SV *result;
        int i;
    CODE:
        if ((items - 1) % 2 != 0)
            croak("File::Raw::Hash::_test_record_one: odd number of "
                  "key/value option args");
        opts = newHV();
        /* Default plugin to "hash" so the caller can omit it. */
        (void)hv_stores(opts, "plugin", newSVpvs("hash"));
        for (i = 1; i < items; i += 2) {
            STRLEN klen;
            const char *kp = SvPV(ST(i), klen);
            SV *vp = SvREFCNT_inc(ST(i + 1));
            (void)hv_store(opts, kp, (I32)klen, vp, 0);
        }
        result = file_plugin_dispatch_record(aTHX_ opts, NULL, record_sv);
        SvREFCNT_dec((SV *)opts);
        if (!result) {
            RETVAL = &PL_sv_undef;
            SvREFCNT_inc(RETVAL);
        } else {
            RETVAL = result;
        }
    OUTPUT:
        RETVAL
