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

/* Under PERL_IMPLICIT_SYS (every Strawberry perl) XSUB.h rewrites the
 * plain names malloc/calloc/realloc/free into PerlMem_* macros that
 * dereference my_perl. The frh_abi_* entry points below are plain C
 * with no interpreter to hand, so they fail to compile there; and the
 * runner they allocate is fed to hashx.c, which allocates with the
 * libc names, so mixing the two pools would free to the wrong one.
 * Undef the four so this file matches hashx.c. No-op on Unix. */
#undef malloc
#undef calloc
#undef realloc
#undef free

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

/* ============================================================
 * The C ABI - include/frh_abi.h. Perl-free thunks over the runner,
 * every runner initialised with HF_RAW so raw digest bytes come out
 * of the existing finish path (t/14-raw-parity.t proves that path
 * equals the formatted one, HMAC included).
 * ============================================================ */

#include "frh_abi.h"

/* The registry rows the ABI hands out. Filled once from the internal
 * table rather than aliased to it, so frh_algo_t owes nothing to
 * hash_algo_info_t's layout. */
static frh_algo_t FRH_ALGOS[HA_COUNT];
static int frh_algos_ready = 0;

static void frh_algos_fill(void)
{
    int i;
    if (frh_algos_ready)
        return;
    for (i = 0; i < HA_COUNT; i++) {
        const hash_algo_info_t *a = hash_algo_by_id((hash_algo_id_t)i);
        FRH_ALGOS[i].name        = a->name;
        FRH_ALGOS[i].id          = i;
        FRH_ALGOS[i].digest_size = a->digest_size;
        FRH_ALGOS[i].hmac_able   = a->hmac_able;
        FRH_ALGOS[i].block_size  = a->hmac_block_size;
    }
    frh_algos_ready = 1;
}

static const frh_algo_t *frh_abi_algo_by_name(const char *name, size_t len)
{
    const hash_algo_info_t *a;
    if (!name)
        return NULL;
    frh_algos_fill();
    a = hash_algo_lookup(name, len);
    return a ? &FRH_ALGOS[a->id] : NULL;
}

static const frh_algo_t *frh_abi_algo_by_id(int id)
{
    if (id < 0 || id >= HA_COUNT)
        return NULL;
    frh_algos_fill();
    return &FRH_ALGOS[id];
}

static int frh_abi_algo_count(void)
{
    return HA_COUNT;
}

/* The handle behind the opaque pointer. `finished` enforces the
 * exactly-once rule the internal finish does not: hash_runner_finish
 * tolerates a second call for leak safety but would re-finalise dead
 * contexts and hand back garbage. */
typedef struct {
    hash_runner_t r;
    int           finished;
} frh_runner_t;

static void *frh_abi_new_runner(const int *ids, int n,
                                unsigned long long seed)
{
    frh_runner_t *w;
    hash_algo_id_t *hids;
    int i;

    if (!ids || n < 1)
        return NULL;
    for (i = 0; i < n; i++)
        if (ids[i] < 0 || ids[i] >= HA_COUNT)
            return NULL;

    hids = (hash_algo_id_t *)malloc((size_t)n * sizeof *hids);
    if (!hids)
        return NULL;
    for (i = 0; i < n; i++)
        hids[i] = (hash_algo_id_t)ids[i];

    w = (frh_runner_t *)malloc(sizeof *w);
    if (!w) {
        free(hids);
        return NULL;
    }
    if (hash_runner_init(&w->r, hids, n, HF_RAW, (uint64_t)seed) != 0) {
        free(hids);
        free(w);
        return NULL;
    }
    free(hids);
    w->finished = 0;
    return w;
}

static int frh_abi_runner_set_hmac(void *vr, const unsigned char *key,
                                   size_t klen)
{
    frh_runner_t *w = (frh_runner_t *)vr;
    if (!w || w->finished)
        return -1;
    return hash_runner_set_hmac(&w->r, key, klen);
}

static void frh_abi_runner_update(void *vr, const void *data, size_t len)
{
    frh_runner_t *w = (frh_runner_t *)vr;
    if (!w || w->finished)
        return;
    hash_runner_update(&w->r, data, len);
}

static int frh_abi_runner_finish(void *vr, unsigned char **outs)
{
    frh_runner_t *w = (frh_runner_t *)vr;
    const hash_result_t *res;
    int i;

    if (!w || w->finished || !outs)
        return -1;
    /* validate every destination BEFORE finalising: a NULL discovered
     * mid-copy would leave the runner finished and the output partial,
     * the worst of both */
    for (i = 0; i < w->r.count; i++)
        if (!outs[i])
            return -1;
    if (hash_runner_finish(&w->r, &res) != 0)
        return -1;
    w->finished = 1;
    for (i = 0; i < w->r.count; i++) {
        const hash_algo_info_t *a = hash_algo_by_id(res[i].id);
        memcpy(outs[i], res[i].out, a->digest_size);
    }
    return 0;
}

static void frh_abi_runner_free(void *vr)
{
    frh_runner_t *w = (frh_runner_t *)vr;
    if (!w)
        return;
    hash_runner_free(&w->r);
    free(w);
}

/* One-shots: a runner born, fed and finished locally, so there is no
 * second finalisation code path to drift. */
static int frh_abi_digest_common(int id, const unsigned char *key,
                                 size_t klen,
                                 const unsigned char *in, size_t n,
                                 unsigned char *out)
{
    void *w;
    unsigned char *outs[1];
    int rc;

    if (!out)
        return -1;
    w = frh_abi_new_runner(&id, 1, 0);
    if (!w)
        return -1;
    if (key && frh_abi_runner_set_hmac(w, key, klen) != 0) {
        frh_abi_runner_free(w);
        return -1;
    }
    frh_abi_runner_update(w, in, n);
    outs[0] = out;
    rc = frh_abi_runner_finish(w, outs);
    frh_abi_runner_free(w);
    return rc;
}

static int frh_abi_digest(int id, const unsigned char *in, size_t n,
                          unsigned char *out)
{
    return frh_abi_digest_common(id, NULL, 0, in, n, out);
}

static int frh_abi_hmac(int id, const unsigned char *key, size_t klen,
                        const unsigned char *in, size_t n,
                        unsigned char *out)
{
    if (!key)
        return -1;
    return frh_abi_digest_common(id, key, klen, in, n, out);
}

static const frh_abi FRH_ABI = {
    FRH_ABI_VERSION,
    frh_abi_algo_by_name,
    frh_abi_algo_by_id,
    frh_abi_algo_count,
    frh_abi_digest,
    frh_abi_hmac,
    frh_abi_new_runner,
    frh_abi_runner_set_hmac,
    frh_abi_runner_update,
    frh_abi_runner_finish,
    frh_abi_runner_free
};

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
    {
        /* The CPU's SHA instructions when it has them; FRH_PORTABLE set true
         * in the environment keeps the C. Read from %ENV, not getenv(), which
         * does not see %ENV everywhere. */
        SV **svp = hv_fetchs(GvHVn(PL_envgv), "FRH_PORTABLE", 0);
        int portable = svp && SvTRUE(*svp);
        sha256_select(portable);
        sha1_select(portable);
    }

SV *
implementation()
    CODE:
    {
        /* Which code computes each algorithm: "portable" (C), or the name of
         * the CPU instructions in use. */
        HV *hv = newHV();
        int i, n = FRH_ABI.algo_count();
        for (i = 0; i < n; i++) {
            const frh_algo_t *a = FRH_ABI.algo_by_id(i);
            const char *impl = !strcmp(a->name, "sha256") ? sha256_implementation()
                             : !strcmp(a->name, "sha1")   ? sha1_implementation()
                             : "portable";
            (void)hv_store(hv, a->name, (I32)strlen(a->name), newSVpv(impl, 0), 0);
        }
        RETVAL = newRV_noinc((SV *)hv);
    }
    OUTPUT:
        RETVAL

IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&FRH_ABI);
    OUTPUT:
        RETVAL

SV*
_abi_selftest()
    CODE:
    {
        /* Drive the table the way a C consumer would and report one
         * named flag per member group, plus the raw "abc" digest of
         * every algorithm as hex so the Perl tests can compare this
         * path against the plugin path byte for byte. */
        const frh_abi *H = &FRH_ABI;
        HV *hv = newHV();
        HV *digests = newHV();
        int registry_ok = 1, digest_ok = 1, hmac_ok = 0;
        int runner_ok = 0, edges_ok = 1;
        int i, n = H->algo_count();
        unsigned char buf[HASH_MAX_DIGEST_SIZE];
        char hex[HASH_MAX_DIGEST_SIZE * 2 + 1];

        /* registry: dense ids, names round-trip, sane sizes */
        for (i = 0; i < n; i++) {
            const frh_algo_t *a = H->algo_by_id(i);
            const frh_algo_t *b;
            if (!a || a->id != i || !a->name ||
                a->digest_size == 0 ||
                a->digest_size > HASH_MAX_DIGEST_SIZE) {
                registry_ok = 0;
                break;
            }
            b = H->algo_by_name(a->name, strlen(a->name));
            if (b != a) { registry_ok = 0; break; }
            if (a->hmac_able && a->block_size == 0) {
                registry_ok = 0;
                break;
            }
        }
        registry_ok = registry_ok
            && !H->algo_by_id(-1) && !H->algo_by_id(n)
            && !H->algo_by_name("nonesuch", 8);

        /* one-shot digest of "abc" per algorithm, reported as hex */
        for (i = 0; i < n; i++) {
            const frh_algo_t *a = H->algo_by_id(i);
            size_t j;
            if (H->digest(i, (const unsigned char *)"abc", 3, buf) != 0) {
                digest_ok = 0;
                continue;
            }
            for (j = 0; j < a->digest_size; j++)
                sprintf(hex + 2 * j, "%02x", buf[j]);
            (void)hv_store(digests, a->name, (I32)strlen(a->name),
                           newSVpvn(hex, a->digest_size * 2), 0);
        }

        /* HMAC: RFC 2202 case 1, checked here in C so the vector
         * guards the table even if the Perl tests thin out */
        {
            const frh_algo_t *sha1 =
                H->algo_by_name("sha1", 4);
            static const unsigned char want[20] = {
                0xb6,0x17,0x31,0x86,0x55,0x05,0x72,0x64,0xe2,0x8b,
                0xc0,0xb6,0xfb,0x37,0x8c,0x8e,0xf1,0x46,0xbe,0x00
            };
            unsigned char key[20];
            memset(key, 0x0b, sizeof key);
            if (sha1 &&
                H->hmac(sha1->id, key, sizeof key,
                        (const unsigned char *)"Hi There", 8, buf) == 0)
                hmac_ok = memcmp(buf, want, 20) == 0;
        }

        /* lockstep: sha256+blake3 over a split stream equals the
         * one-shots over the joined stream */
        {
            const frh_algo_t *s = H->algo_by_name("sha256", 6);
            const frh_algo_t *b = H->algo_by_name("blake3", 6);
            if (s && b) {
                int ids[2];
                unsigned char o1[HASH_MAX_DIGEST_SIZE];
                unsigned char o2[HASH_MAX_DIGEST_SIZE];
                unsigned char *outs[2];
                void *r;
                ids[0] = s->id; ids[1] = b->id;
                outs[0] = o1; outs[1] = o2;
                r = H->new_runner(ids, 2, 0);
                if (r) {
                    unsigned char w1[HASH_MAX_DIGEST_SIZE];
                    unsigned char w2[HASH_MAX_DIGEST_SIZE];
                    H->runner_update(r, "lock", 4);
                    H->runner_update(r, "", 0);
                    H->runner_update(r, "step", 4);
                    runner_ok = H->runner_finish(r, outs) == 0
                        && H->digest(s->id, (const unsigned char *)
                                     "lockstep", 8, w1) == 0
                        && H->digest(b->id, (const unsigned char *)
                                     "lockstep", 8, w2) == 0
                        && memcmp(o1, w1, s->digest_size) == 0
                        && memcmp(o2, w2, b->digest_size) == 0;
                    /* edge: a second finish refuses */
                    edges_ok = edges_ok
                        && H->runner_finish(r, outs) == -1;
                    H->runner_free(r);
                }
            }
        }

        /* edges: free(NULL); set_hmac including a non-hmac_able algo
         * fails atomically and the runner stays usable plain */
        H->runner_free(NULL);
        {
            const frh_algo_t *s = H->algo_by_name("sha256", 6);
            const frh_algo_t *c = H->algo_by_name("crc32", 5);
            if (s && c) {
                int ids[2];
                unsigned char o1[HASH_MAX_DIGEST_SIZE];
                unsigned char o2[HASH_MAX_DIGEST_SIZE];
                unsigned char *outs[2];
                void *r;
                ids[0] = s->id; ids[1] = c->id;
                outs[0] = o1; outs[1] = o2;
                r = H->new_runner(ids, 2, 0);
                edges_ok = edges_ok && r
                    && H->runner_set_hmac(r,
                          (const unsigned char *)"k", 1) == -1;
                if (r) {
                    H->runner_update(r, "abc", 3);
                    edges_ok = edges_ok
                        && H->runner_finish(r, outs) == 0;
                    H->runner_free(r);
                }
            }
            /* bad ids refuse */
            edges_ok = edges_ok
                && H->digest(-1, (const unsigned char *)"x", 1, buf) == -1
                && H->digest(n, (const unsigned char *)"x", 1, buf) == -1
                && !H->new_runner(NULL, 1, 0);
        }

        (void)hv_stores(hv, "version",     newSViv(H->version));
        (void)hv_stores(hv, "registry_ok", newSViv(registry_ok));
        (void)hv_stores(hv, "digest_ok",   newSViv(digest_ok));
        (void)hv_stores(hv, "hmac_ok",     newSViv(hmac_ok));
        (void)hv_stores(hv, "runner_ok",   newSViv(runner_ok));
        (void)hv_stores(hv, "edges_ok",    newSViv(edges_ok));
        (void)hv_stores(hv, "digests",     newRV_noinc((SV *)digests));
        RETVAL = newRV_noinc((SV *)hv);
    }
    OUTPUT:
        RETVAL

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

SV *
_test_feed(algo_sv, data_sv, offset, ...)
        SV *algo_sv
        SV *data_sv
        IV offset
    PREINIT:
        STRLEN nlen, len, done = 0;
        const char *name, *data;
        const frh_algo_t *a;
        void *r;
        unsigned char *mem, *buf, out[HASH_MAX_DIGEST_SIZE], *outs[1];
        char hex[HASH_MAX_DIGEST_SIZE * 2 + 1];
        int id, k = 3;
        size_t j;
    CODE:
        /* For the oracle tests: digest data_sv through the C ABI's
         * runner, from a buffer offset bytes past an aligned start,
         * fed in the chunk sizes given after the offset (cycled; the
         * rest in one call when none are given). Returns hex. */
        name = SvPV(algo_sv, nlen);
        a = FRH_ABI.algo_by_name(name, nlen);
        if (!a) croak("File::Raw::Hash::_test_feed: unknown algorithm");
        if (offset < 0 || offset > 63) croak("File::Raw::Hash::_test_feed: offset 0-63");
        data = SvPVbyte(data_sv, len);
        Newx(mem, len + 64 + 1, unsigned char);
        buf = mem + offset;
        if (len) Copy(data, buf, len, unsigned char);
        id = a->id;
        r = FRH_ABI.new_runner(&id, 1, 0);
        if (!r) { Safefree(mem); croak("File::Raw::Hash::_test_feed: no runner"); }
        while (done < len) {
            STRLEN take = len - done;
            if (items > 3) {
                IV want = SvIV(ST(k));
                if (++k >= items) k = 3;
                if (want > 0 && (STRLEN)want < take) take = (STRLEN)want;
            }
            FRH_ABI.runner_update(r, buf + done, take);
            done += take;
        }
        outs[0] = out;
        if (FRH_ABI.runner_finish(r, outs) != 0) {
            FRH_ABI.runner_free(r);
            Safefree(mem);
            croak("File::Raw::Hash::_test_feed: finish failed");
        }
        FRH_ABI.runner_free(r);
        Safefree(mem);
        for (j = 0; j < a->digest_size; j++)
            sprintf(hex + 2 * j, "%02x", out[j]);
        RETVAL = newSVpvn(hex, a->digest_size * 2);
    OUTPUT:
        RETVAL
