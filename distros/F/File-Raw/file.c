/*
 * file.c - Fast IO operations using direct system calls
 *
 * Features:
 * - slurp/spew with minimal overhead
 * - Memory-mapped file access (mmap)
 * - Efficient line iteration
 * - Direct stat access
 * - Windows and POSIX support
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "include/file_compat.h"
#include "include/file_plugin.h"

#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>

#ifdef _WIN32
    #include <io.h>
    #include <windows.h>
    #include <direct.h>
    /* 
     * Windows compatibility - use Perl's wrapper functions
     * We DON'T redefine open/read/write/close/stat/fstat/access here
     * because Perl's XSUB.h already defines them to work correctly.
     * Just define the flags and other missing bits.
     */
    #define O_RDONLY _O_RDONLY
    #define O_WRONLY _O_WRONLY
    #define O_RDWR _O_RDWR
    #define O_CREAT _O_CREAT
    #define O_TRUNC _O_TRUNC
    #define O_APPEND _O_APPEND
    #define O_BINARY _O_BINARY
    #ifndef S_ISREG
        #define S_ISREG(m) (((m) & _S_IFMT) == _S_IFREG)
    #endif
    #ifndef S_ISDIR
        #define S_ISDIR(m) (((m) & _S_IFMT) == _S_IFDIR)
    #endif
    #define R_OK 4
    #define W_OK 2
    /* ssize_t for Windows */
    #ifndef ssize_t
        #ifdef _WIN64
            typedef __int64 ssize_t;
        #else
            typedef int ssize_t;
        #endif
    #endif
    /* Windows doesn't have real uid/gid - use dummy values */
    #define FILE_FAKE_UID 1000
    #define FILE_FAKE_GID 1000
    /*
     * On Windows with PERL_IMPLICIT_SYS, Perl redefines open() to
     * PerlLIO_open() which only accepts 2 args. Use _open() directly
     * for the 3-arg form (path, flags, mode).
     */
    #define file_open3(path, flags, mode) _open(path, flags, mode)
#else
    #define file_open3(path, flags, mode) open(path, flags, mode)
    #include <unistd.h>
    #include <sys/mman.h>
    #include <utime.h>      /* For utime - more portable than utimes */
    #include <dirent.h>     /* For readdir */
    #if defined(__linux__)
        #include <sys/sendfile.h>  /* Zero-copy file transfer */
    #endif
    #if defined(__APPLE__)
        #include <copyfile.h>      /* macOS native file copy */
    #endif
#endif

/* Default buffer size for reads - 64KB is optimal for most systems */
#define FILE_BUFFER_SIZE 65536

/* Larger buffer for bulk operations */
#define FILE_BULK_BUFFER_SIZE 262144

/* Threshold for mmap-based slurp (4MB) */
#define MMAP_SLURP_THRESHOLD (4 * 1024 * 1024)

/* Branch prediction hints */
#ifndef LIKELY
#if defined(__GNUC__) || defined(__clang__)
    #define LIKELY(x)   __builtin_expect(!!(x), 1)
    #define UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
    #define LIKELY(x)   (x)
    #define UNLIKELY(x) (x)
#endif
#endif

/* posix_fadvise hints for kernel optimization */
#if defined(__linux__) || defined(__FreeBSD__) || defined(__NetBSD__)
    #define HAVE_POSIX_FADVISE 1
    #define advise_sequential(fd, len) posix_fadvise(fd, 0, len, POSIX_FADV_SEQUENTIAL)
    #define advise_dontneed(fd, len) posix_fadvise(fd, 0, len, POSIX_FADV_DONTNEED)
#else
    #define HAVE_POSIX_FADVISE 0
    #define advise_sequential(fd, len) ((void)0)
    #define advise_dontneed(fd, len) ((void)0)
#endif

/* ============================================
   Plugin registry + dispatch helpers.
   Storage and definitions live here in the Raw.so TU; downstream XS
   modules see only file_plugin.h and resolve the function symbols at
   load time via RTLD_GLOBAL.
   ============================================ */

/* Registry: name (PV) -> FilePlugin* (stored via PTR2IV in the SV). */
static HV *g_file_plugin_registry = NULL;

/* One-pointer cache: short-circuits HV lookup when the same plugin is
 * used in tight loops (e.g. each_line). */
static const FilePlugin *g_file_last_plugin = NULL;

static void file_plugin_registry_init(pTHX) {
    if (!g_file_plugin_registry)
        g_file_plugin_registry = newHV();
}

int file_register_plugin(pTHX_ const FilePlugin *plugin) {
    SV *entry;
    STRLEN name_len;

    if (!plugin || !plugin->name || !*plugin->name) return -1;

    file_plugin_registry_init(aTHX);
    name_len = strlen(plugin->name);
    if (hv_exists(g_file_plugin_registry, plugin->name, name_len))
        return 0;

    entry = newSViv(PTR2IV(plugin));
    if (!hv_store(g_file_plugin_registry, plugin->name, name_len, entry, 0)) {
        SvREFCNT_dec(entry);
        return -1;
    }
    return 1;
}

int file_unregister_plugin(pTHX_ const char *name) {
    if (!g_file_plugin_registry || !name) return 0;
    if (g_file_last_plugin && strcmp(g_file_last_plugin->name, name) == 0)
        g_file_last_plugin = NULL;
    return hv_delete(g_file_plugin_registry, name, strlen(name), G_DISCARD)
           ? 1 : 0;
}

const FilePlugin *file_lookup_plugin(pTHX_ const char *name) {
    SV **svp;
    const FilePlugin *p;

    if (!name) return NULL;
    if (g_file_last_plugin && strcmp(g_file_last_plugin->name, name) == 0)
        return g_file_last_plugin;
    if (!g_file_plugin_registry) return NULL;

    svp = hv_fetch(g_file_plugin_registry, name, strlen(name), 0);
    if (!svp || !*svp) return NULL;
    p = INT2PTR(const FilePlugin*, SvIV(*svp));
    g_file_last_plugin = p;
    return p;
}

/* ---- option-HV builder ---- */

HV* file_plugin_build_opts(pTHX_ SV **stack, int start, int items,
                           const char *fn_name) {
    HV *opts;
    int i;
    int has_plugin = 0;

    if (start >= items) return NULL;
    if ((items - start) % 2 != 0)
        croak("File::Raw::%s: odd number of options (expected key => value pairs)",
              fn_name);

    opts = newHV();
    for (i = start; i < items; i += 2) {
        SV *key_sv = stack[i];
        SV *val_sv = stack[i + 1];
        STRLEN key_len;
        const char *key;

        if (!SvOK(key_sv))
            croak("File::Raw::%s: option key at position %d is undef",
                  fn_name, i);
        key = SvPV(key_sv, key_len);
        if (!hv_store(opts, key, (I32)key_len, SvREFCNT_inc(val_sv), 0)) {
            SvREFCNT_dec(val_sv);
            SvREFCNT_dec((SV*)opts);
            croak("File::Raw::%s: failed to store option '%s'", fn_name, key);
        }
        if (key_len == 6 && memcmp(key, "plugin", 6) == 0)
            has_plugin = 1;
    }

    if (!has_plugin) {
        SvREFCNT_dec((SV*)opts);
        croak("File::Raw::%s: options passed without 'plugin' key", fn_name);
    }
    return opts;
}

/* ---- dispatch helpers ---- */

/* FilePluginChain — internal-only resolution result for a single dispatch
 * call.
 *
 * Two shapes:
 *
 *   Single-plugin (fast path, count == 1, shared == NULL):
 *     plugins[0] is the resolved plugin; opts is passed to it directly
 *     (no per-plugin slicing). This is the only path used when the
 *     caller passed `plugin => 'name'` as a scalar string — preserves
 *     today's behaviour byte-for-byte.
 *
 *   Chain (count >= 1, shared != NULL):
 *     `plugin => [a, b, c]` (arrayref). `shared` holds top-level keys
 *     that did not match any plugin name's per-plugin sub-hash;
 *     `per_plugin[i]` (may be NULL) holds the sub-hashref the user
 *     gave for plugins[i]. `file_plugin_chain_iter_opts` builds a
 *     fresh per-iteration HV from these. */
typedef struct {
    const FilePlugin **plugins;     /* count slots */
    int                count;
    HV                *shared;      /* NULL on single-plugin fast path */
    HV               **per_plugin;  /* count slots, each may be NULL */
} FilePluginChain;

static void
file_plugin_chain_init(FilePluginChain *chain) {
    memset(chain, 0, sizeof *chain);
}

static void
file_plugin_chain_free(pTHX_ FilePluginChain *chain) {
    int i;
    if (chain->per_plugin) {
        for (i = 0; i < chain->count; i++) {
            if (chain->per_plugin[i])
                SvREFCNT_dec((SV *)chain->per_plugin[i]);
        }
        Safefree(chain->per_plugin);
        chain->per_plugin = NULL;
    }
    if (chain->shared) {
        SvREFCNT_dec((SV *)chain->shared);
        chain->shared = NULL;
    }
    if (chain->plugins) {
        Safefree(chain->plugins);
        chain->plugins = NULL;
    }
    chain->count = 0;
}

/* Resolve plugin chain. Accepts scalar (single-plugin fast path) or
 * arrayref (chain). Croaks on undef, empty arrayref, unknown plugin
 * name, or wrong-shape value. Caller must call file_plugin_chain_free
 * on `out` before returning. */
static void
file_plugin_resolve_chain(pTHX_ HV *opts, const char *fn_name,
                          FilePluginChain *out)
{
    SV **slot;
    SV  *plugin_sv;
    AV  *plugins_av;
    SSize_t n;
    SSize_t i;

    file_plugin_chain_init(out);

    slot = hv_fetchs(opts, "plugin", 0);
    if (!slot || !*slot || !SvOK(*slot))
        croak("File::Raw::%s: missing 'plugin' option", fn_name);
    plugin_sv = *slot;

    /* Scalar fast path — single-plugin call, opts passed straight through. */
    if (!SvROK(plugin_sv)) {
        const char *name = SvPV_nolen(plugin_sv);
        const FilePlugin *p = file_lookup_plugin(aTHX_ name);
        if (!p) croak("File::Raw::%s: unknown plugin '%s'", fn_name, name);
        Newx(out->plugins, 1, const FilePlugin *);
        out->plugins[0] = p;
        out->count = 1;
        return;
    }

    if (SvTYPE(SvRV(plugin_sv)) != SVt_PVAV)
        croak("File::Raw::%s: 'plugin' must be a string or arrayref of "
              "plugin names", fn_name);

    plugins_av = (AV *)SvRV(plugin_sv);
    n = av_len(plugins_av) + 1;
    if (n <= 0)
        croak("File::Raw::%s: empty plugin chain", fn_name);

    Newx(out->plugins, n, const FilePlugin *);
    out->count = (int)n;

    for (i = 0; i < n; i++) {
        SV **np = av_fetch(plugins_av, i, 0);
        const char *name;
        const FilePlugin *p;
        if (!np || !*np || !SvOK(*np))
            croak("File::Raw::%s: undef plugin name at chain index %ld",
                  fn_name, (long)i);
        if (SvROK(*np))
            croak("File::Raw::%s: plugin name at chain index %ld must "
                  "be a string", fn_name, (long)i);
        name = SvPV_nolen(*np);
        p = file_lookup_plugin(aTHX_ name);
        if (!p)
            croak("File::Raw::%s: unknown plugin '%s' (chain index %ld)",
                  fn_name, name, (long)i);
        out->plugins[i] = p;
    }

    /* Build shared HV + per-plugin slots. Walk every key in opts:
     *   - 'plugin'   → skip (already consumed)
     *   - matches a plugin name AND is a hashref → per-plugin sub-hash
     *   - otherwise → shared bag, visible to every iteration */
    out->shared = newHV();
    Newxz(out->per_plugin, n, HV *);

    {
        HE *he;
        hv_iterinit(opts);
        while ((he = hv_iternext(opts))) {
            I32 klen_i;
            const char *key = hv_iterkey(he, &klen_i);
            STRLEN klen = (STRLEN)klen_i;
            SV *val = hv_iterval(opts, he);
            int matched = -1;

            if (klen == 6 && memcmp(key, "plugin", 6) == 0) continue;

            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
                int j;
                for (j = 0; j < (int)n; j++) {
                    const char *pn = out->plugins[j]->name;
                    STRLEN plen = strlen(pn);
                    if (plen == klen && memcmp(key, pn, klen) == 0) {
                        matched = j;
                        break;
                    }
                }
            }

            if (matched >= 0) {
                out->per_plugin[matched] = (HV *)SvRV(val);
                SvREFCNT_inc((SV *)out->per_plugin[matched]);
            } else {
                (void)hv_store(out->shared, key, klen,
                               SvREFCNT_inc(val), 0);
            }
        }
    }
}

/* Resolve for phases that don't support chaining (RECORD, STREAM).
 * Croaks if the user passed an arrayref. */
static const FilePlugin *
file_plugin_resolve_single(pTHX_ HV *opts, const char *fn_name)
{
    SV **slot = hv_fetchs(opts, "plugin", 0);
    const char *name;
    const FilePlugin *p;
    if (!slot || !*slot || !SvOK(*slot))
        croak("File::Raw::%s: missing 'plugin' option", fn_name);
    if (SvROK(*slot))
        croak("File::Raw::%s: plugin chains are not supported for the "
              "'%s' phase (record/stream); pass a single plugin name "
              "instead", fn_name, fn_name);
    name = SvPV_nolen(*slot);
    p = file_lookup_plugin(aTHX_ name);
    if (!p) croak("File::Raw::%s: unknown plugin '%s'", fn_name, name);
    return p;
}

/* Build the per-iteration ctx->options HV for chain mode: shared bag
 * with the indexed plugin's sub-hash overlaid on top (sub-hash wins on
 * conflict). The 'plugin' key is set to the iterating plugin's own
 * name, so plugins that read it (e.g. Separated's known_opt list)
 * don't see something stale or array-shaped. Returns a fresh HV the
 * dispatcher must SvREFCNT_dec after the iteration. */
static HV *
file_plugin_chain_iter_opts(pTHX_ FilePluginChain *chain, int idx)
{
    HV *iter = newHV();
    HE *he;

    if (chain->shared) {
        hv_iterinit(chain->shared);
        while ((he = hv_iternext(chain->shared))) {
            I32 klen_i;
            const char *key = hv_iterkey(he, &klen_i);
            SV *val = hv_iterval(chain->shared, he);
            (void)hv_store(iter, key, klen_i, SvREFCNT_inc(val), 0);
        }
    }
    if (chain->per_plugin && chain->per_plugin[idx]) {
        HV *pp = chain->per_plugin[idx];
        hv_iterinit(pp);
        while ((he = hv_iternext(pp))) {
            I32 klen_i;
            const char *key = hv_iterkey(he, &klen_i);
            SV *val = hv_iterval(pp, he);
            (void)hv_store(iter, key, klen_i, SvREFCNT_inc(val), 0);
        }
    }
    (void)hv_store(iter, "plugin", 6,
                   newSVpv(chain->plugins[idx]->name, 0), 0);
    return iter;
}

/* READ dispatcher.
 *
 * Single-plugin scalar path: identical to today — opts goes straight
 * through, plugin's return SV is returned bare, caller manages
 * `if (out != bytes)` decref.
 *
 * Chain path: walks the resolved plugin list left-to-right, threading
 * each plugin's return SV into the next call's ctx->data. Refcount
 * discipline tracks "do we own the current SV?" so that whether the
 * chain returns the input bytes unchanged or a fresh SV, the contract
 * the caller sees is identical to the single-plugin path. */
SV* file_plugin_dispatch_read(pTHX_ HV *opts, const char *path, SV *bytes) {
    FilePluginChain chain;
    SV *current;
    int we_own;
    int i;

    file_plugin_resolve_chain(aTHX_ opts, "slurp", &chain);

    /* Scalar fast path: zero allocation overhead vs. today. */
    if (chain.shared == NULL) {
        const FilePlugin *p = chain.plugins[0];
        FilePluginContext ctx;
        SV *out;
        if (!p->read_fn) {
            file_plugin_chain_free(aTHX_ &chain);
            croak("File::Raw: plugin '%s' has no read phase", p->name);
        }
        ctx.path         = path;
        ctx.data         = bytes;
        ctx.callback     = NULL;
        ctx.options      = opts;
        ctx.phase        = FILE_PLUGIN_PHASE_READ;
        ctx.cancel       = 0;
        ctx.plugin_state = p->state;
        ctx.call_state   = NULL;
        out = p->read_fn(aTHX_ &ctx);
        file_plugin_chain_free(aTHX_ &chain);
        if (ctx.cancel) return NULL;
        return out;
    }

    /* Chain path. */
    current = bytes;
    we_own  = 0;

    for (i = 0; i < chain.count; i++) {
        const FilePlugin *p = chain.plugins[i];
        FilePluginContext ctx;
        HV *iter_opts;
        SV *next;

        if (!p->read_fn) {
            if (we_own) SvREFCNT_dec(current);
            file_plugin_chain_free(aTHX_ &chain);
            croak("File::Raw: plugin '%s' has no read phase "
                  "(chain index %d)", p->name, i);
        }

        iter_opts        = file_plugin_chain_iter_opts(aTHX_ &chain, i);
        ctx.path         = path;
        ctx.data         = current;
        ctx.callback     = NULL;
        ctx.options      = iter_opts;
        ctx.phase        = FILE_PLUGIN_PHASE_READ;
        ctx.cancel       = 0;
        ctx.plugin_state = p->state;
        ctx.call_state   = NULL;

        next = p->read_fn(aTHX_ &ctx);
        SvREFCNT_dec((SV *)iter_opts);

        if (ctx.cancel || !next) {
            if (we_own) SvREFCNT_dec(current);
            file_plugin_chain_free(aTHX_ &chain);
            return NULL;
        }

        if (next != current) {
            if (we_own) SvREFCNT_dec(current);
            current = next;
            we_own  = 1;   /* per existing convention, plugin gives us +1 */
        }
        /* else: plugin returned the same SV; ownership unchanged. */
    }

    file_plugin_chain_free(aTHX_ &chain);
    /* Contract matches today's: if we never replaced bytes, we return
     * bytes (caller still owns the +1 we never touched). If we replaced
     * it, we return the fresh SV with +1 from the last plugin, exactly
     * as today's single-plugin path would. */
    return current;
}

/* WRITE dispatcher. Mirror image of READ — same chain mechanics, but
 * iterates RIGHT TO LEFT. The user's payload (which can be structured —
 * AoA, AoH, etc.) flows into the *last* plugin first; that plugin emits
 * bytes; subsequent (earlier-listed) plugins wrap those bytes. The byte
 * stream produced by the FIRST plugin is what gets written to disk.
 *
 * Mnemonic: same array spelling for read and write — the array describes
 * the encoding stack from outermost wrapper to innermost format. */
SV* file_plugin_dispatch_write(pTHX_ HV *opts, const char *path, SV *payload) {
    FilePluginChain chain;
    SV *current;
    int we_own;
    int i;

    file_plugin_resolve_chain(aTHX_ opts, "spew", &chain);

    if (chain.shared == NULL) {
        const FilePlugin *p = chain.plugins[0];
        FilePluginContext ctx;
        SV *out;
        if (!p->write_fn) {
            file_plugin_chain_free(aTHX_ &chain);
            croak("File::Raw: plugin '%s' has no write phase", p->name);
        }
        ctx.path         = path;
        ctx.data         = payload;
        ctx.callback     = NULL;
        ctx.options      = opts;
        ctx.phase        = FILE_PLUGIN_PHASE_WRITE;
        ctx.cancel       = 0;
        ctx.plugin_state = p->state;
        ctx.call_state   = NULL;
        out = p->write_fn(aTHX_ &ctx);
        file_plugin_chain_free(aTHX_ &chain);
        if (ctx.cancel) return NULL;
        return out;
    }

    current = payload;
    we_own  = 0;

    for (i = chain.count - 1; i >= 0; i--) {
        const FilePlugin *p = chain.plugins[i];
        FilePluginContext ctx;
        HV *iter_opts;
        SV *next;

        if (!p->write_fn) {
            if (we_own) SvREFCNT_dec(current);
            file_plugin_chain_free(aTHX_ &chain);
            croak("File::Raw: plugin '%s' has no write phase "
                  "(chain index %d)", p->name, i);
        }

        iter_opts        = file_plugin_chain_iter_opts(aTHX_ &chain, i);
        ctx.path         = path;
        ctx.data         = current;
        ctx.callback     = NULL;
        ctx.options      = iter_opts;
        ctx.phase        = FILE_PLUGIN_PHASE_WRITE;
        ctx.cancel       = 0;
        ctx.plugin_state = p->state;
        ctx.call_state   = NULL;

        next = p->write_fn(aTHX_ &ctx);
        SvREFCNT_dec((SV *)iter_opts);

        if (ctx.cancel || !next) {
            if (we_own) SvREFCNT_dec(current);
            file_plugin_chain_free(aTHX_ &chain);
            return NULL;
        }

        if (next != current) {
            if (we_own) SvREFCNT_dec(current);
            current = next;
            we_own  = 1;
        }
    }

    file_plugin_chain_free(aTHX_ &chain);
    return current;
}

/* RECORD dispatcher — single-plugin only. Chains are rejected because
 * a "record" is one already-parsed unit; threading it through multiple
 * record fns would require the records to remain the same shape across
 * links, which collapses the abstraction. */
SV* file_plugin_dispatch_record(pTHX_ HV *opts, const char *path, SV *record) {
    const FilePlugin *p = file_plugin_resolve_single(aTHX_ opts, "record");
    FilePluginContext ctx;
    SV *out;

    if (!p->record_fn)
        croak("File::Raw: plugin '%s' has no record phase", p->name);

    ctx.path         = path;
    ctx.data         = NULL;
    ctx.callback     = NULL;
    ctx.options      = opts;
    ctx.phase        = FILE_PLUGIN_PHASE_RECORD;
    ctx.cancel       = 0;
    ctx.plugin_state = p->state;
    ctx.call_state   = NULL;

    out = p->record_fn(aTHX_ &ctx, record);
    if (ctx.cancel) return NULL;
    return out;
}

/* file_plugin_dispatch_stream is defined below - it relies on
 * FILE_BUFFER_SIZE and the platform open()/read() wrappers. */
SV* file_plugin_dispatch_stream(pTHX_ HV *opts, const char *path, SV *cb) {
    const FilePlugin *p = file_plugin_resolve_single(aTHX_ opts, "each_line");
    FilePluginContext ctx;
    char buf[FILE_BUFFER_SIZE];
    int fd;
    ssize_t n;
    int cancelled = 0;

    if (!p->stream_fn)
        croak("File::Raw: plugin '%s' has no stream phase", p->name);

    /* O_BINARY on Windows: without it the CRT puts the descriptor in
     * text mode and strips \r from any \r\n in the read buffer before
     * the plugin's stream hook sees it. Hash-style plugins (and any
     * other binary consumer) then see a different byte stream than
     * the one-shot read path, which already sets O_BINARY. No-op on
     * Unix where O_BINARY is defined to 0. */
    {
        int open_flags = O_RDONLY;
#ifdef _WIN32
        open_flags |= O_BINARY;
#endif
        fd = file_open3(path, open_flags, 0);
    }
    if (fd < 0) return NULL;

    ctx.path         = path;
    ctx.data         = NULL;
    ctx.callback     = cb;
    ctx.options      = opts;
    ctx.phase        = FILE_PLUGIN_PHASE_STREAM;
    ctx.cancel       = 0;
    ctx.plugin_state = p->state;
    ctx.call_state   = NULL;

    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        if (p->stream_fn(aTHX_ &ctx, buf, (size_t)n, 0) || ctx.cancel) {
            cancelled = 1;
            break;
        }
    }
    if (!cancelled) {
        /* EOF flush so the plugin can emit any buffered final record. */
        p->stream_fn(aTHX_ &ctx, NULL, 0, 1);
    }
    close(fd);
    return (cancelled || ctx.cancel) ? NULL : &PL_sv_yes;
}

/* ============================================
   Stat cache - like Perl's _ special filehandle
   ============================================ */
#define STAT_CACHE_PATH_MAX 1024

static struct {
    char path[STAT_CACHE_PATH_MAX];
    Stat_t st;
    int valid;
#ifdef _WIN32
    int uid;
    int gid;
#else
    uid_t uid;
    gid_t gid;
#endif
} g_stat_cache = { "", {0}, 0, 0, 0 };

/* Get cached stat or perform new stat */
static int cached_stat(const char *path, Stat_t *st) {
    dTHX;
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        *st = g_stat_cache.st;
        return 0;
    }
    
    if (stat(path, st) < 0) {
        g_stat_cache.valid = 0;
        return -1;
    }
    
    /* Cache the result */
    size_t len = strlen(path);
    if (len < STAT_CACHE_PATH_MAX) {
        memcpy(g_stat_cache.path, path, len + 1);
        g_stat_cache.st = *st;
#ifdef _WIN32
        /* Windows doesn't have real uid/gid concepts */
        g_stat_cache.uid = FILE_FAKE_UID;
        g_stat_cache.gid = FILE_FAKE_GID;
#else
        g_stat_cache.uid = geteuid();
        g_stat_cache.gid = getegid();
#endif
        g_stat_cache.valid = 1;
    }
    
    return 0;
}

/* Invalidate cache (call after write operations) */
static void invalidate_stat_cache(void) {
    g_stat_cache.valid = 0;
}

/* Invalidate cache for specific path */
static void invalidate_stat_cache_path(const char *path) {
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
}

/* Check readable using cached stat */
static int file_is_readable_cached(const char *path) {
    dTHX;
#ifdef _WIN32
    return access(path, R_OK) == 0;
#else
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    
    if (g_stat_cache.uid == 0) return 1;  /* root can read anything */
    
    if (st.st_uid == g_stat_cache.uid) {
        return (st.st_mode & S_IRUSR) != 0;
    } else if (st.st_gid == g_stat_cache.gid) {
        return (st.st_mode & S_IRGRP) != 0;
    } else {
        return (st.st_mode & S_IROTH) != 0;
    }
#endif
}

/* Check writable using cached stat */
static int file_is_writable_cached(const char *path) {
    dTHX;
#ifdef _WIN32
    return access(path, W_OK) == 0;
#else
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    
    if (g_stat_cache.uid == 0) return 1;  /* root can write anything */
    
    if (st.st_uid == g_stat_cache.uid) {
        return (st.st_mode & S_IWUSR) != 0;
    } else if (st.st_gid == g_stat_cache.gid) {
        return (st.st_mode & S_IWGRP) != 0;
    } else {
        return (st.st_mode & S_IWOTH) != 0;
    }
#endif
}

/* Check executable using cached stat */
static int file_is_executable_cached(const char *path) {
    dTHX;
#ifdef _WIN32
    /* Windows: check file extension for executability */
    const char *ext = strrchr(path, '.');
    if (ext) {
        if (_stricmp(ext, ".exe") == 0 || _stricmp(ext, ".bat") == 0 ||
            _stricmp(ext, ".cmd") == 0 || _stricmp(ext, ".com") == 0) {
            return access(path, R_OK) == 0;
        }
    }
    return 0;
#else
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    
    if (g_stat_cache.uid == 0) return 1;  /* root can execute anything */
    
    if (st.st_uid == g_stat_cache.uid) {
        return (st.st_mode & S_IXUSR) != 0;
    } else if (st.st_gid == g_stat_cache.gid) {
        return (st.st_mode & S_IXGRP) != 0;
    } else {
        return (st.st_mode & S_IXOTH) != 0;
    }
#endif
}


/* ============================================
   Custom op support for compile-time optimization
   ============================================ */

/* Custom op registrations */
static XOP file_slurp_xop;
static XOP file_spew_xop;
static XOP file_exists_xop;
static XOP file_size_xop;
static XOP file_is_file_xop;
static XOP file_is_dir_xop;
static XOP file_lines_xop;
static XOP file_unlink_xop;
static XOP file_mkdir_xop;
static XOP file_rmdir_xop;
static XOP file_basename_xop;
static XOP file_dirname_xop;
static XOP file_extname_xop;
static XOP file_touch_xop;
static XOP file_clear_stat_cache_xop;
static XOP file_mtime_xop;
static XOP file_atime_xop;
static XOP file_ctime_xop;
static XOP file_mode_xop;
static XOP file_is_link_xop;
static XOP file_is_readable_xop;
static XOP file_is_writable_xop;
static XOP file_is_executable_xop;
static XOP file_readdir_xop;
static XOP file_slurp_raw_xop;
static XOP file_copy_xop;
static XOP file_move_xop;
static XOP file_chmod_xop;
static XOP file_append_xop;
static XOP file_atomic_spew_xop;

/* Forward declarations for internal functions */
static SV* file_slurp_internal(pTHX_ const char *path);
static SV* file_slurp_raw_internal(pTHX_ const char *path);
static int file_spew_internal(pTHX_ const char *path, SV *data);
static int file_append_internal(pTHX_ const char *path, SV *data);
static IV file_size_internal(const char *path);
static IV file_mtime_internal(const char *path);
static IV file_atime_internal(const char *path);
static IV file_ctime_internal(const char *path);
static IV file_mode_internal(const char *path);
static int file_exists_internal(const char *path);
static int file_is_file_internal(const char *path);
static int file_is_dir_internal(const char *path);
static int file_is_link_internal(const char *path);
static int file_is_readable_internal(const char *path);
static int file_is_writable_internal(const char *path);
static int file_is_executable_internal(const char *path);
static AV* file_split_lines(pTHX_ SV *content);
static int file_unlink_internal(const char *path);
static int file_copy_internal(pTHX_ const char *src, const char *dst);
static int file_move_internal(pTHX_ const char *src, const char *dst);
static int file_mkdir_internal(const char *path, int mode);
static int file_rmdir_internal(const char *path);
static int file_touch_internal(const char *path);
static int file_chmod_internal(const char *path, int mode);
static AV* file_readdir_internal(pTHX_ const char *path);
static int file_atomic_spew_internal(pTHX_ const char *path, SV *data);
static SV* file_basename_internal(pTHX_ const char *path);
static SV* file_dirname_internal(pTHX_ const char *path);
static SV* file_extname_internal(pTHX_ const char *path);

/* Typedef for pp functions */
typedef OP* (*file_ppfunc)(pTHX);

/* ============================================
   Custom OP implementations - fastest path
   ============================================ */

/* pp_file_slurp: single path arg on stack - OPTIMIZED HOT PATH */
static OP* pp_file_slurp(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    int fd;
    Stat_t st;
    SV *result;
    char *buf;
    ssize_t n, total;

    /* Fast path: direct syscalls. The custom op only fires when the
     * call-checker accepted exactly one arg, so there is no plugin tail
     * to dispatch here - the variadic XSUB owns that path. */
#ifdef _WIN32
    fd = open(path, O_RDONLY | O_BINARY);
#else
    fd = open(path, O_RDONLY);
#endif
    if (fd < 0) {
        PUSHs(&PL_sv_undef);
        PUTBACK;
        return NORMAL;
    }

    if (fstat(fd, &st) < 0 || !S_ISREG(st.st_mode)) {
        close(fd);
        PUSHs(&PL_sv_undef);
        PUTBACK;
        return NORMAL;
    }

    /* Empty file */
    if (st.st_size == 0) {
        close(fd);
        result = newSVpvs("");
        PUSHs(sv_2mortal(result));
        PUTBACK;
        return NORMAL;
    }

    /* Hint to kernel: sequential read */
    advise_sequential(fd, st.st_size);

    /* Pre-allocate exact size */
    result = newSV(st.st_size + 1);
    SvPOK_on(result);
    buf = SvPVX(result);

#ifndef _WIN32
    /* Large files: use mmap for zero-copy */
    if (st.st_size >= MMAP_SLURP_THRESHOLD) {
        void *map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (map != MAP_FAILED) {
            #ifdef MADV_SEQUENTIAL
            madvise(map, st.st_size, MADV_SEQUENTIAL);
            #endif
            memcpy(buf, map, st.st_size);
            buf[st.st_size] = '\0';
            SvCUR_set(result, st.st_size);
            munmap(map, st.st_size);
            close(fd);
            PUSHs(sv_2mortal(result));
            PUTBACK;
            return NORMAL;
        }
        /* mmap failed, fall through to read */
    }
#endif

    /* Single read - common case for small/medium files */
    n = read(fd, buf, st.st_size);
    if (n == st.st_size) {
        /* Got everything in one read - fast path */
        close(fd);
        buf[n] = '\0';
        SvCUR_set(result, n);
        PUSHs(sv_2mortal(result));
        PUTBACK;
        return NORMAL;
    }
    
    /* Short read or error - need loop */
    if (n < 0) {
        if (errno == EINTR) {
            n = 0;  /* Start from beginning */
        } else {
            close(fd);
            SvREFCNT_dec(result);
            PUSHs(&PL_sv_undef);
            PUTBACK;
            return NORMAL;
        }
    }
    
    total = n;
    while (total < st.st_size) {
        n = read(fd, buf + total, st.st_size - total);
        if (n < 0) {
            if (errno == EINTR) continue;
            close(fd);
            SvREFCNT_dec(result);
            PUSHs(&PL_sv_undef);
            PUTBACK;
            return NORMAL;
        }
        if (n == 0) break;
        total += n;
    }
    
    close(fd);
    buf[total] = '\0';
    SvCUR_set(result, total);
    
    PUSHs(sv_2mortal(result));
    PUTBACK;
    return NORMAL;
}

/* pp_file_spew: path and data on stack */
static OP* pp_file_spew(pTHX) {
    dSP;
    SV *data = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_spew_internal(aTHX_ path, data) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_exists: single path arg on stack */
static OP* pp_file_exists(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_exists_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_size: single path arg on stack */
static OP* pp_file_size(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_size_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_file: single path arg on stack */
static OP* pp_file_is_file(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_file_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_dir: single path arg on stack */
static OP* pp_file_is_dir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_dir_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_lines: single path arg on stack */
static OP* pp_file_lines(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    SV *content = file_slurp_internal(aTHX_ path);
    AV *lines;

    if (content == &PL_sv_undef) {
        lines = newAV();
    } else {
        lines = file_split_lines(aTHX_ content);
        SvREFCNT_dec(content);
    }

    PUSHs(sv_2mortal(newRV_noinc((SV*)lines)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_unlink: single path arg on stack */
static OP* pp_file_unlink(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_unlink_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_clear_stat_cache: optional path arg - clears stat cache */
static OP* pp_file_clear_stat_cache(pTHX) {
    dSP;
    SV *path_sv = POPs;
    
    if (SvOK(path_sv)) {
        /* Clear cache for specific path */
        const char *path = SvPV_nolen(path_sv);
        invalidate_stat_cache_path(path);
    } else {
        /* Clear entire cache */
        invalidate_stat_cache();
    }
    
    PUSHs(&PL_sv_yes);
    PUTBACK;
    return NORMAL;
}

/* pp_file_mkdir: single path arg on stack (mode defaults to 0755) */
static OP* pp_file_mkdir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_mkdir_internal(path, 0755) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_rmdir: single path arg on stack */
static OP* pp_file_rmdir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_rmdir_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_touch: single path arg on stack */
static OP* pp_file_touch(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_touch_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_basename: single path arg on stack */
static OP* pp_file_basename(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(file_basename_internal(aTHX_ path)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_dirname: single path arg on stack */
static OP* pp_file_dirname(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(file_dirname_internal(aTHX_ path)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_extname: single path arg on stack */
static OP* pp_file_extname(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(file_extname_internal(aTHX_ path)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_mtime: single path arg on stack */
static OP* pp_file_mtime(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_mtime_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_atime: single path arg on stack */
static OP* pp_file_atime(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_atime_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_ctime: single path arg on stack */
static OP* pp_file_ctime(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_ctime_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_mode: single path arg on stack */
static OP* pp_file_mode(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_mode_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_link: single path arg on stack */
static OP* pp_file_is_link(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_link_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_readable: single path arg on stack */
static OP* pp_file_is_readable(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_readable_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_writable: single path arg on stack */
static OP* pp_file_is_writable(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_writable_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_executable: single path arg on stack */
static OP* pp_file_is_executable(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_executable_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_readdir: single path arg on stack */
static OP* pp_file_readdir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    AV *result = file_readdir_internal(aTHX_ path);
    PUSHs(sv_2mortal(newRV_noinc((SV*)result)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_slurp_raw: single path arg on stack (bypasses hooks) */
static OP* pp_file_slurp_raw(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    SV *result = file_slurp_raw_internal(aTHX_ path);
    PUSHs(sv_2mortal(result));
    PUTBACK;
    return NORMAL;
}

/* pp_file_copy: src and dst on stack */
static OP* pp_file_copy(pTHX) {
    dSP;
    SV *dst_sv = POPs;
    SV *src_sv = POPs;
    const char *src = SvPV_nolen(src_sv);
    const char *dst = SvPV_nolen(dst_sv);
    PUSHs(file_copy_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_move: src and dst on stack */
static OP* pp_file_move(pTHX) {
    dSP;
    SV *dst_sv = POPs;
    SV *src_sv = POPs;
    const char *src = SvPV_nolen(src_sv);
    const char *dst = SvPV_nolen(dst_sv);
    PUSHs(file_move_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_chmod: path and mode on stack */
static OP* pp_file_chmod(pTHX) {
    dSP;
    SV *mode_sv = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    int mode = SvIV(mode_sv);
    PUSHs(file_chmod_internal(path, mode) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_append: path and data on stack */
static OP* pp_file_append(pTHX) {
    dSP;
    SV *data = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_append_internal(aTHX_ path, data) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_atomic_spew: path and data on stack */
static OP* pp_file_atomic_spew(pTHX) {
    dSP;
    SV *data = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_atomic_spew_internal(aTHX_ path, data) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* ============================================
   Call checkers for compile-time optimization
   ============================================ */

/* Count args between pushop's first sibling and the trailing cv op.
 * The last sibling in the chain is the cv (we don't replace it), so the
 * arg count is (total siblings) - 1. Returns -1 if the chain is shorter
 * than expected (no args at all). */
static int file_count_call_args(OP *pushop) {
    OP *o = OpSIBLING(pushop);
    int n = 0;
    while (o) {
        n++;
        o = OpSIBLING(o);
    }
    return n > 0 ? n - 1 : -1;
}

/* 1-arg call checker (slurp, exists, size, is_file, is_dir, lines).
 * Bails when items != 1 so the regular XSUB sees the full arg list -
 * critical for the plugin tail (slurp($p, plugin => ..., key => val)). */
static OP* file_call_checker_1arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    file_ppfunc ppfunc = (file_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *argop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    /* Navigate to first child */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    if (file_count_call_args(pushop) != 1) return entersubop;

    /* Get the args: pushmark -> arg -> cv */
    argop = OpSIBLING(pushop);
    if (!argop) return entersubop;

    cvop = OpSIBLING(argop);
    if (!cvop) return entersubop;

    /* Detach arg from tree */
    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(argop, NULL);

    /* Force scalar context so function calls return exactly one value */
    argop = op_contextualize(argop, G_SCALAR);

    /* Create as OP_NULL first to avoid -DDEBUGGING assertion in newUNOP,
       then convert to OP_CUSTOM */
    newop = newUNOP(OP_NULL, 0, argop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;

    op_free(entersubop);
    return newop;
}

/* 2-arg call checker (spew, append).
 * Bails when items != 2 so the regular XSUB sees the full arg list -
 * critical for the plugin tail (spew($p, $data, plugin => ..., ...)). */
static OP* file_call_checker_2arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    file_ppfunc ppfunc = (file_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *pathop, *dataop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    /* Navigate to first child */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    if (file_count_call_args(pushop) != 2) return entersubop;

    /* Get the args: pushmark -> path -> data -> cv */
    pathop = OpSIBLING(pushop);
    if (!pathop) return entersubop;

    dataop = OpSIBLING(pathop);
    if (!dataop) return entersubop;

    cvop = OpSIBLING(dataop);
    if (!cvop) return entersubop;

    /* Detach args from tree */
    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(pathop, NULL);
    OpLASTSIB_set(dataop, NULL);

    /* Force scalar context on both args so function calls
       return exactly one value on the stack */
    pathop = op_contextualize(pathop, G_SCALAR);
    dataop = op_contextualize(dataop, G_SCALAR);

    /* Create as OP_NULL first to avoid -DDEBUGGING assertion in newBINOP,
       then convert to OP_CUSTOM */
    newop = newBINOP(OP_NULL, 0, pathop, dataop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;

    op_free(entersubop);
    return newop;
}

/* Install 1-arg function with call checker */
static void install_file_func_1arg(pTHX_ const char *pkg, const char *name,
                                    XSUBADDR_t xsub, file_ppfunc ppfunc) {
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, file_call_checker_1arg, ckobj);
}

/* Install 2-arg function with call checker */
static void install_file_func_2arg(pTHX_ const char *pkg, const char *name,
                                    XSUBADDR_t xsub, file_ppfunc ppfunc) {
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, file_call_checker_2arg, ckobj);
}

/* ============================================
   Memory-mapped file registry
   ============================================ */

typedef struct {
    void *addr;         /* Mapped address */
    size_t len;         /* Mapped length */
    int refcount;       /* Reference count */
#ifdef _WIN32
    HANDLE file_handle; /* Windows file handle */
    HANDLE map_handle;  /* Windows mapping handle */
#else
    int fd;             /* File descriptor (POSIX) */
#endif
} MmapEntry;

static MmapEntry *g_mmaps = NULL;
static IV g_mmaps_size = 0;
static IV g_mmaps_count = 0;

/* Free list for mmap reuse */
static IV *g_free_mmaps = NULL;
static IV g_free_mmaps_size = 0;
static IV g_free_mmaps_count = 0;

/* ============================================
   Line iterator registry
   ============================================ */

typedef struct {
    int fd;             /* File descriptor (-1 in record-iter mode) */
    char *buffer;       /* Read buffer (NULL in record-iter mode)   */
    size_t buf_size;    /* Buffer size */
    size_t buf_pos;     /* Current position in buffer */
    size_t buf_len;     /* Valid data length in buffer */
    int eof;            /* End of file reached */
    int refcount;       /* Reference count */
    char *path;         /* File path (for reopening) */
    /* Record-iterator mode (set when lines_iter was called with a
     * plugin tail). When records is non-NULL, next/eof/close walk the
     * AoA instead of reading bytes from fd. */
    AV *records;
    SSize_t records_idx;
} LineIterEntry;

static LineIterEntry *g_iters = NULL;
static IV g_iters_size = 0;
static IV g_iters_count = 0;

static IV *g_free_iters = NULL;
static IV g_free_iters_size = 0;
static IV g_free_iters_count = 0;

/* ============================================
   Initialization
   ============================================ */

static int file_initialized = 0;

/* Forward declaration for callback registry init */
static void file_init_callback_registry(pTHX);

static void file_init(pTHX) {
    if (file_initialized) return;

    g_mmaps_size = 16;
    Newxz(g_mmaps, g_mmaps_size, MmapEntry);
    g_free_mmaps_size = 16;
    Newxz(g_free_mmaps, g_free_mmaps_size, IV);

    g_iters_size = 16;
    Newxz(g_iters, g_iters_size, LineIterEntry);
    g_free_iters_size = 16;
    Newxz(g_free_iters, g_free_iters_size, IV);

    /* Initialize callback registry with built-in predicates */
    file_init_callback_registry(aTHX);

    file_initialized = 1;
}

/* ============================================
   Fast slurp - read entire file into SV
   ============================================ */

static SV* file_slurp_internal(pTHX_ const char *path) {
    int fd;
    Stat_t st;
    SV *result;
    char *buf;
    ssize_t total = 0, n;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    /* O_NOATIME avoids updating access time - reduces disk writes */
    #ifdef __linux__
    int open_flags = O_RDONLY | O_NOATIME;
    #else
    int open_flags = O_RDONLY;
    #endif
#endif

    fd = open(path, open_flags);
#ifdef __linux__
    /* Fallback if O_NOATIME fails (not owner) */
    if (fd < 0 && errno == EPERM) {
        fd = open(path, O_RDONLY);
    }
#endif
    if (fd < 0) {
        return &PL_sv_undef;
    }

    if (fstat(fd, &st) < 0) {
        close(fd);
        return &PL_sv_undef;
    }

    /* Hint to kernel: sequential read pattern */
    advise_sequential(fd, st.st_size);

    /* Pre-allocate exact size for regular files */
    if (S_ISREG(st.st_mode) && st.st_size > 0) {
#ifndef _WIN32
        /* For large files, use mmap + memcpy - faster than read() syscalls */
        if (st.st_size >= MMAP_SLURP_THRESHOLD) {
            void *map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (map != MAP_FAILED) {
                /* Hint: we'll read sequentially */
                #ifdef MADV_SEQUENTIAL
                madvise(map, st.st_size, MADV_SEQUENTIAL);
                #endif
                
                result = newSV(st.st_size + 1);
                SvPOK_on(result);
                buf = SvPVX(result);
                memcpy(buf, map, st.st_size);
                buf[st.st_size] = '\0';
                SvCUR_set(result, st.st_size);
                
                munmap(map, st.st_size);
                close(fd);
                goto done;
            }
            /* mmap failed, fall through to read() */
        }
#endif
        result = newSV(st.st_size + 1);
        SvPOK_on(result);
        buf = SvPVX(result);

        /* Read in one shot if possible */
        while (total < st.st_size) {
            n = read(fd, buf + total, st.st_size - total);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    } else {
        /* Stream or unknown size - read in chunks */
        size_t capacity = FILE_BUFFER_SIZE;
        result = newSV(capacity);
        SvPOK_on(result);
        buf = SvPVX(result);

        while (1) {
            if (total >= (ssize_t)capacity - 1) {
                capacity *= 2;
                SvGROW(result, capacity);
                buf = SvPVX(result);
            }

            n = read(fd, buf + total, capacity - total - 1);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    }

    close(fd);

done:
    return result;
}

/* ============================================
   Fast slurp binary - same as slurp but explicit
   (bypasses hooks - for raw binary data)
   ============================================ */

static SV* file_slurp_raw_internal(pTHX_ const char *path) {
    int fd;
    Stat_t st;
    SV *result;
    char *buf;
    ssize_t total = 0, n;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    #ifdef __linux__
    int open_flags = O_RDONLY | O_NOATIME;
    #else
    int open_flags = O_RDONLY;
    #endif
#endif

    fd = open(path, open_flags);
#ifdef __linux__
    if (fd < 0 && errno == EPERM) {
        fd = open(path, O_RDONLY);
    }
#endif
    if (fd < 0) {
        return &PL_sv_undef;
    }

    if (fstat(fd, &st) < 0) {
        close(fd);
        return &PL_sv_undef;
    }

    /* Hint to kernel: sequential read pattern */
    advise_sequential(fd, st.st_size);

    if (S_ISREG(st.st_mode) && st.st_size > 0) {
#ifndef _WIN32
        /* For large files, use mmap + memcpy */
        if (st.st_size >= MMAP_SLURP_THRESHOLD) {
            void *map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (map != MAP_FAILED) {
                #ifdef MADV_SEQUENTIAL
                madvise(map, st.st_size, MADV_SEQUENTIAL);
                #endif
                
                result = newSV(st.st_size + 1);
                SvPOK_on(result);
                buf = SvPVX(result);
                memcpy(buf, map, st.st_size);
                buf[st.st_size] = '\0';
                SvCUR_set(result, st.st_size);
                
                munmap(map, st.st_size);
                close(fd);
                return result;
            }
        }
#endif
        result = newSV(st.st_size + 1);
        SvPOK_on(result);
        buf = SvPVX(result);

        while (total < st.st_size) {
            n = read(fd, buf + total, st.st_size - total);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    } else {
        size_t capacity = FILE_BUFFER_SIZE;
        result = newSV(capacity);
        SvPOK_on(result);
        buf = SvPVX(result);

        while (1) {
            if (total >= (ssize_t)capacity - 1) {
                capacity *= 2;
                SvGROW(result, capacity);
                buf = SvPVX(result);
            }

            n = read(fd, buf + total, capacity - total - 1);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    }

    close(fd);
    return result;  /* No hooks for raw */
}

static SV* file_slurp_raw(pTHX_ const char *path) {
    return file_slurp_raw_internal(aTHX_ path);
}

/* ============================================
   Fast spew - write SV to file
   ============================================ */

static int file_spew_internal(pTHX_ const char *path, SV *data) {
    int fd;
    const char *buf;
    STRLEN len;
    ssize_t n;
    SV *write_data = data;
    int free_write_data = 0;
#ifdef _WIN32
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
#else
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC;
#endif

    buf = SvPV(write_data, len);

    fd = file_open3(path, open_flags, 0644);
    if (UNLIKELY(fd < 0)) {
        if (free_write_data) SvREFCNT_dec(write_data);
        return 0;
    }

#if defined(__linux__)
    /* Pre-allocate space for large files to avoid fragmentation */
    if (len >= 65536) {
        posix_fallocate(fd, 0, len);
    }
#endif

    /* Fast path: single write for common case */
    n = write(fd, buf, len);
    if (LIKELY(n == (ssize_t)len)) {
        close(fd);
        if (free_write_data) SvREFCNT_dec(write_data);
        /* Invalidate cache for this path */
        if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
            g_stat_cache.valid = 0;
        }
        return 1;
    }

    /* Handle partial write or error */
    if (n < 0) {
        if (errno != EINTR) {
            close(fd);
            if (free_write_data) SvREFCNT_dec(write_data);
            return 0;
        }
        n = 0;
    }

    /* Loop for remaining data (rare) */
    {
        ssize_t written = n;
        while ((size_t)written < len) {
            n = write(fd, buf + written, len - written);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                if (free_write_data) SvREFCNT_dec(write_data);
                return 0;
            }
            written += n;
        }
    }

    close(fd);
    if (free_write_data) SvREFCNT_dec(write_data);
    /* Invalidate cache for this path */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
}

/* ============================================
   Fast append - append SV to file
   ============================================ */

static int file_append_internal(pTHX_ const char *path, SV *data) {
    int fd;
    const char *buf;
    STRLEN len;
    ssize_t n;
#ifdef _WIN32
    int open_flags = O_WRONLY | O_CREAT | O_APPEND | O_BINARY;
#else
    int open_flags = O_WRONLY | O_CREAT | O_APPEND;
#endif

    buf = SvPV(data, len);

    fd = file_open3(path, open_flags, 0644);
    if (UNLIKELY(fd < 0)) {
        return 0;
    }

    /* Fast path: single write for common case */
    n = write(fd, buf, len);
    if (LIKELY(n == (ssize_t)len)) {
        close(fd);
        /* Invalidate cache for this path */
        if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
            g_stat_cache.valid = 0;
        }
        return 1;
    }

    /* Handle partial write or error */
    if (n < 0) {
        if (errno != EINTR) {
            close(fd);
            return 0;
        }
        n = 0;
    }

    /* Loop for remaining data (rare) */
    {
        ssize_t written = n;
        while ((size_t)written < len) {
            n = write(fd, buf + written, len - written);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                return 0;
            }
            written += n;
        }
    }

    close(fd);
    /* Invalidate cache for this path */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
}

/* ============================================
   Memory-mapped file operations
   ============================================ */

static void ensure_mmaps_capacity(IV needed) {
    if (needed >= g_mmaps_size) {
        IV new_size = g_mmaps_size ? g_mmaps_size * 2 : 16;
        IV i;
        while (new_size <= needed) new_size *= 2;
        Renew(g_mmaps, new_size, MmapEntry);
        for (i = g_mmaps_size; i < new_size; i++) {
            g_mmaps[i].addr = NULL;
            g_mmaps[i].len = 0;
            g_mmaps[i].refcount = 0;
#ifdef _WIN32
            g_mmaps[i].file_handle = INVALID_HANDLE_VALUE;
            g_mmaps[i].map_handle = INVALID_HANDLE_VALUE;
#else
            g_mmaps[i].fd = -1;
#endif
        }
        g_mmaps_size = new_size;
    }
}

static IV alloc_mmap_slot(void) {
    IV idx;

    if (g_free_mmaps_count > 0) {
        return g_free_mmaps[--g_free_mmaps_count];
    }

    ensure_mmaps_capacity(g_mmaps_count);
    idx = g_mmaps_count++;
    return idx;
}

static void free_mmap_slot(IV idx) {
    dTHX;
    MmapEntry *entry;

    if (idx < 0 || idx >= g_mmaps_count) return;

    entry = &g_mmaps[idx];
#ifdef _WIN32
    if (entry->addr) {
        UnmapViewOfFile(entry->addr);
    }
    if (entry->map_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(entry->map_handle);
    }
    if (entry->file_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(entry->file_handle);
    }
    entry->file_handle = INVALID_HANDLE_VALUE;
    entry->map_handle = INVALID_HANDLE_VALUE;
#else
    if (entry->addr && entry->addr != MAP_FAILED) {
        munmap(entry->addr, entry->len);
    }
    if (entry->fd >= 0) {
        close(entry->fd);
    }
    entry->fd = -1;
#endif
    entry->addr = NULL;
    entry->len = 0;
    entry->refcount = 0;

    if (g_free_mmaps_count >= g_free_mmaps_size) {
        g_free_mmaps_size *= 2;
        Renew(g_free_mmaps, g_free_mmaps_size, IV);
    }
    g_free_mmaps[g_free_mmaps_count++] = idx;
}

static IV file_mmap_open(pTHX_ const char *path, int writable) {
    IV idx;
    void *addr;
    size_t file_size;

#ifdef _WIN32
    HANDLE file_handle;
    HANDLE map_handle;
    LARGE_INTEGER size;
    DWORD access = writable ? GENERIC_READ | GENERIC_WRITE : GENERIC_READ;
    DWORD share = FILE_SHARE_READ;
    DWORD protect = writable ? PAGE_READWRITE : PAGE_READONLY;
    DWORD map_access = writable ? FILE_MAP_WRITE : FILE_MAP_READ;

    file_handle = CreateFileA(path, access, share, NULL, OPEN_EXISTING,
                              FILE_ATTRIBUTE_NORMAL, NULL);
    if (file_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }

    if (!GetFileSizeEx(file_handle, &size)) {
        CloseHandle(file_handle);
        return -1;
    }

    if (size.QuadPart == 0) {
        CloseHandle(file_handle);
        return -1;
    }

    file_size = (size_t)size.QuadPart;

    map_handle = CreateFileMappingA(file_handle, NULL, protect, 0, 0, NULL);
    if (map_handle == NULL) {
        CloseHandle(file_handle);
        return -1;
    }

    addr = MapViewOfFile(map_handle, map_access, 0, 0, 0);
    if (addr == NULL) {
        CloseHandle(map_handle);
        CloseHandle(file_handle);
        return -1;
    }

    idx = alloc_mmap_slot();
    g_mmaps[idx].addr = addr;
    g_mmaps[idx].len = file_size;
    g_mmaps[idx].file_handle = file_handle;
    g_mmaps[idx].map_handle = map_handle;
    g_mmaps[idx].refcount = 1;

#else
    int fd;
    Stat_t st;
    int flags = writable ? O_RDWR : O_RDONLY;
    int prot = writable ? (PROT_READ | PROT_WRITE) : PROT_READ;

    fd = open(path, flags);
    if (fd < 0) {
        return -1;
    }

    if (fstat(fd, &st) < 0) {
        close(fd);
        return -1;
    }

    if (st.st_size == 0) {
        /* Can't mmap empty file */
        close(fd);
        return -1;
    }

    file_size = st.st_size;

    addr = mmap(NULL, st.st_size, prot, MAP_SHARED, fd, 0);
    if (addr == MAP_FAILED) {
        close(fd);
        return -1;
    }

    idx = alloc_mmap_slot();
    g_mmaps[idx].addr = addr;
    g_mmaps[idx].len = file_size;
    g_mmaps[idx].fd = fd;
    g_mmaps[idx].refcount = 1;
#endif

    return idx;
}

static SV* file_mmap_get_sv(pTHX_ IV idx) {
    MmapEntry *entry;
    SV *sv;

    if (idx < 0 || idx >= g_mmaps_count) {
        return &PL_sv_undef;
    }

    entry = &g_mmaps[idx];
#ifdef _WIN32
    if (!entry->addr) {
        return &PL_sv_undef;
    }
#else
    if (!entry->addr || entry->addr == MAP_FAILED) {
        return &PL_sv_undef;
    }
#endif

    /* Create an SV that points directly to the mapped memory */
    sv = newSV(0);
    SvUPGRADE(sv, SVt_PV);
    SvPV_set(sv, (char*)entry->addr);
    SvCUR_set(sv, entry->len);
    SvLEN_set(sv, 0);  /* Don't free this memory! */
    SvPOK_on(sv);
    SvREADONLY_on(sv);

    return sv;
}

static void file_mmap_close(IV idx) {
    dTHX;
    if (idx < 0 || idx >= g_mmaps_count) return;

    MmapEntry *entry = &g_mmaps[idx];
    entry->refcount--;
    if (entry->refcount <= 0) {
        free_mmap_slot(idx);
    }
}

static void file_mmap_sync(IV idx) {
    dTHX;
    MmapEntry *entry;

    if (idx < 0 || idx >= g_mmaps_count) return;

    entry = &g_mmaps[idx];
#ifdef _WIN32
    if (entry->addr) {
        FlushViewOfFile(entry->addr, entry->len);
    }
#else
    if (entry->addr && entry->addr != MAP_FAILED) {
        msync(entry->addr, entry->len, MS_SYNC);
    }
#endif
}

/* ============================================
   Line iterator operations
   ============================================ */

static void ensure_iters_capacity(IV needed) {
    if (needed >= g_iters_size) {
        IV new_size = g_iters_size ? g_iters_size * 2 : 16;
        IV i;
        while (new_size <= needed) new_size *= 2;
        Renew(g_iters, new_size, LineIterEntry);
        for (i = g_iters_size; i < new_size; i++) {
            g_iters[i].fd = -1;
            g_iters[i].buffer = NULL;
            g_iters[i].buf_size = 0;
            g_iters[i].buf_pos = 0;
            g_iters[i].buf_len = 0;
            g_iters[i].eof = 0;
            g_iters[i].refcount = 0;
            g_iters[i].path = NULL;
        }
        g_iters_size = new_size;
    }
}

static IV alloc_iter_slot(void) {
    IV idx;

    if (g_free_iters_count > 0) {
        return g_free_iters[--g_free_iters_count];
    }

    ensure_iters_capacity(g_iters_count);
    idx = g_iters_count++;
    return idx;
}

static void free_iter_slot(IV idx) {
    dTHX;
    LineIterEntry *entry;

    if (idx < 0 || idx >= g_iters_count) return;

    entry = &g_iters[idx];
    if (entry->fd >= 0) {
        close(entry->fd);
    }
    if (entry->buffer) {
        Safefree(entry->buffer);
    }
    if (entry->path) {
        Safefree(entry->path);
    }
    if (entry->records) {
        SvREFCNT_dec((SV *)entry->records);
    }

    entry->fd = -1;
    entry->buffer = NULL;
    entry->buf_size = 0;
    entry->buf_pos = 0;
    entry->buf_len = 0;
    entry->eof = 0;
    entry->refcount = 0;
    entry->path = NULL;
    entry->records = NULL;
    entry->records_idx = 0;

    if (g_free_iters_count >= g_free_iters_size) {
        g_free_iters_size *= 2;
        Renew(g_free_iters, g_free_iters_size, IV);
    }
    g_free_iters[g_free_iters_count++] = idx;
}

static IV file_lines_open(pTHX_ const char *path) {
    int fd;
    IV idx;
    LineIterEntry *entry;
    size_t path_len;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    int open_flags = O_RDONLY;
#endif

    fd = open(path, open_flags);
    if (fd < 0) {
        return -1;
    }

    idx = alloc_iter_slot();
    entry = &g_iters[idx];

    entry->fd = fd;
    entry->buf_size = FILE_BUFFER_SIZE;
    Newx(entry->buffer, entry->buf_size, char);
    entry->buf_pos = 0;
    entry->buf_len = 0;
    entry->eof = 0;
    entry->refcount = 1;

    path_len = strlen(path);
    Newx(entry->path, path_len + 1, char);
    memcpy(entry->path, path, path_len + 1);

    /* Byte-line mode: ensure record-mode fields stay NULL even if
     * alloc_iter_slot reused a slot whose previous owner was a
     * record-iter (free_iter_slot already clears them, but be explicit
     * - this was overlooked before the field was added). */
    entry->records      = NULL;
    entry->records_idx  = 0;

    return idx;
}

static SV* file_lines_next(pTHX_ IV idx) {
    LineIterEntry *entry;
    char *line_start;
    char *newline;
    size_t line_len;
    SV *result;
    ssize_t n;

    if (idx < 0 || idx >= g_iters_count) {
        return &PL_sv_undef;
    }

    entry = &g_iters[idx];
    if (entry->fd < 0) {
        return &PL_sv_undef;
    }

    while (1) {
        /* Look for newline in current buffer */
        if (entry->buf_pos < entry->buf_len) {
            line_start = entry->buffer + entry->buf_pos;
            newline = memchr(line_start, '\n', entry->buf_len - entry->buf_pos);

            if (newline) {
                line_len = newline - line_start;
                result = newSVpvn(line_start, line_len);
                entry->buf_pos += line_len + 1;
                return result;
            }
        }

        /* No newline found, need more data */
        if (entry->eof) {
            /* Return remaining data if any */
            if (entry->buf_pos < entry->buf_len) {
                line_len = entry->buf_len - entry->buf_pos;
                result = newSVpvn(entry->buffer + entry->buf_pos, line_len);
                entry->buf_pos = entry->buf_len;
                return result;
            }
            return &PL_sv_undef;
        }

        /* Move remaining data to start of buffer */
        if (entry->buf_pos > 0) {
            size_t remaining = entry->buf_len - entry->buf_pos;
            if (remaining > 0) {
                memmove(entry->buffer, entry->buffer + entry->buf_pos, remaining);
            }
            entry->buf_len = remaining;
            entry->buf_pos = 0;
        }

        /* Expand buffer if needed */
        if (entry->buf_len >= entry->buf_size - 1) {
            entry->buf_size *= 2;
            Renew(entry->buffer, entry->buf_size, char);
        }

        /* Read more data */
        n = read(entry->fd, entry->buffer + entry->buf_len,
                 entry->buf_size - entry->buf_len - 1);
        if (n < 0) {
            if (errno == EINTR) continue;
            return &PL_sv_undef;
        }
        if (n == 0) {
            entry->eof = 1;
        } else {
            entry->buf_len += n;
        }
    }
}

static int file_lines_eof(IV idx) {
    dTHX;
    LineIterEntry *entry;

    if (idx < 0 || idx >= g_iters_count) {
        return 1;
    }

    entry = &g_iters[idx];
    return entry->eof && entry->buf_pos >= entry->buf_len;
}

static void file_lines_close(IV idx) {
    dTHX;
    if (idx < 0 || idx >= g_iters_count) return;

    LineIterEntry *entry = &g_iters[idx];
    entry->refcount--;
    if (entry->refcount <= 0) {
        free_iter_slot(idx);
    }
}

/* ============================================
   Fast stat operations
   ============================================ */

static IV file_size_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_size;
}

static int file_exists_internal(const char *path) {
    dTHX;
    Stat_t st;
    return cached_stat(path, &st) == 0;
}

static int file_is_file_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    return S_ISREG(st.st_mode);
}

static int file_is_dir_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    return S_ISDIR(st.st_mode);
}

static int file_is_readable_internal(const char *path) {
    dTHX;
    return file_is_readable_cached(path);
}

static int file_is_writable_internal(const char *path) {
    dTHX;
    return file_is_writable_cached(path);
}

static IV file_mtime_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_mtime;
}

static IV file_atime_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_atime;
}

static IV file_ctime_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_ctime;
}

static IV file_mode_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_mode & 07777;  /* Return permission bits only */
}

/* Combined stat - returns all attributes in one syscall */
static HV* file_stat_all_internal(pTHX_ const char *path) {
    Stat_t st;
    HV *result;

    if (cached_stat(path, &st) < 0) {
        return NULL;
    }

    result = newHV();
    hv_store(result, "size", 4, newSViv(st.st_size), 0);
    hv_store(result, "mtime", 5, newSViv(st.st_mtime), 0);
    hv_store(result, "atime", 5, newSViv(st.st_atime), 0);
    hv_store(result, "ctime", 5, newSViv(st.st_ctime), 0);
    hv_store(result, "mode", 4, newSViv(st.st_mode & 07777), 0);
    hv_store(result, "is_file", 7, S_ISREG(st.st_mode) ? &PL_sv_yes : &PL_sv_no, 0);
    hv_store(result, "is_dir", 6, S_ISDIR(st.st_mode) ? &PL_sv_yes : &PL_sv_no, 0);
    hv_store(result, "dev", 3, newSViv(st.st_dev), 0);
    hv_store(result, "ino", 3, newSViv(st.st_ino), 0);
    hv_store(result, "nlink", 5, newSViv(st.st_nlink), 0);
    hv_store(result, "uid", 3, newSViv(st.st_uid), 0);
    hv_store(result, "gid", 3, newSViv(st.st_gid), 0);

    return result;
}

static int file_is_link_internal(const char *path) {
    dTHX;
#ifdef _WIN32
    /* Windows: check for reparse point */
    DWORD attrs = GetFileAttributesA(path);
    if (attrs == INVALID_FILE_ATTRIBUTES) return 0;
    return (attrs & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
#else
    Stat_t st;
    if (lstat(path, &st) < 0) return 0;
    return S_ISLNK(st.st_mode);
#endif
}

static int file_is_executable_internal(const char *path) {
    dTHX;
#ifdef _WIN32
    /* Windows: check file extension */
    const char *ext = strrchr(path, '.');
    if (ext) {
        if (_stricmp(ext, ".exe") == 0 || _stricmp(ext, ".bat") == 0 ||
            _stricmp(ext, ".cmd") == 0 || _stricmp(ext, ".com") == 0) {
            return 1;
        }
    }
    return 0;
#else
    return file_is_executable_cached(path);
#endif
}

/* ============================================
   File manipulation operations
   ============================================ */

static int file_unlink_internal(const char *path) {
    dTHX;
    int result;
#ifdef _WIN32
    result = _unlink(path) == 0;
#else
    result = unlink(path) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_copy_internal(pTHX_ const char *src, const char *dst) {
#if defined(__APPLE__)
    /* macOS: Use native copyfile() for best performance and metadata */
    Stat_t st;
    int result;
    if (stat(src, &st) < 0) return 0;
    result = copyfile(src, dst, NULL, COPYFILE_DATA) == 0;
    if (result && g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
#elif defined(__linux__)
    /* Linux: Use sendfile() for zero-copy transfer */
    int fd_src, fd_dst;
    Stat_t st;
    off_t offset = 0;
    ssize_t sent;

    fd_src = open(src, O_RDONLY);
    if (fd_src < 0) return 0;

    if (fstat(fd_src, &st) < 0 || !S_ISREG(st.st_mode)) {
        close(fd_src);
        return 0;
    }

    fd_dst = file_open3(dst, O_WRONLY | O_CREAT | O_TRUNC, st.st_mode & 07777);
    if (fd_dst < 0) {
        close(fd_src);
        return 0;
    }

    /* sendfile() for zero-copy - much faster than read/write */
    while (offset < st.st_size) {
        sent = sendfile(fd_dst, fd_src, &offset, st.st_size - offset);
        if (sent < 0) {
            if (errno == EINTR) continue;
            if (errno == EINVAL || errno == ENOSYS) {
                /* sendfile not supported, fallback to read/write */
                char *buffer;
                ssize_t n_read, n_written, written;
                int result = 0;

                /* Reposition to where we left off */
                lseek(fd_src, offset, SEEK_SET);

                Newx(buffer, FILE_BULK_BUFFER_SIZE, char);
                while (1) {
                    n_read = read(fd_src, buffer, FILE_BULK_BUFFER_SIZE);
                    if (n_read < 0) {
                        if (errno == EINTR) continue;
                        break;
                    }
                    if (n_read == 0) { result = 1; break; }

                    written = 0;
                    while (written < n_read) {
                        n_written = write(fd_dst, buffer + written, n_read - written);
                        if (n_written < 0) {
                            if (errno == EINTR) continue;
                            goto fallback_cleanup;
                        }
                        written += n_written;
                    }
                }
fallback_cleanup:
                Safefree(buffer);
                close(fd_src);
                close(fd_dst);
                if (result && g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
                    g_stat_cache.valid = 0;
                }
                return result;
            }
            close(fd_src);
            close(fd_dst);
            return 0;
        }
        if (sent == 0) break;
    }

    close(fd_src);
    close(fd_dst);
    /* Invalidate cache for dst */
    if (g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
#else
    /* Portable fallback: read/write loop */
    int fd_src, fd_dst;
    char *buffer;
    ssize_t n_read, n_written, written;
    Stat_t st;
    int result = 0;
#ifdef _WIN32
    int open_flags_r = O_RDONLY | O_BINARY;
    int open_flags_w = O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
#else
    int open_flags_r = O_RDONLY;
    int open_flags_w = O_WRONLY | O_CREAT | O_TRUNC;
#endif

    fd_src = open(src, open_flags_r);
    if (fd_src < 0) return 0;

    if (fstat(fd_src, &st) < 0) {
        close(fd_src);
        return 0;
    }

    fd_dst = file_open3(dst, open_flags_w, st.st_mode & 07777);
    if (fd_dst < 0) {
        close(fd_src);
        return 0;
    }

    Newx(buffer, FILE_BULK_BUFFER_SIZE, char);

    while (1) {
        n_read = read(fd_src, buffer, FILE_BULK_BUFFER_SIZE);
        if (n_read < 0) {
            if (errno == EINTR) continue;
            goto cleanup;
        }
        if (n_read == 0) break;

        written = 0;
        while (written < n_read) {
            n_written = write(fd_dst, buffer + written, n_read - written);
            if (n_written < 0) {
                if (errno == EINTR) continue;
                goto cleanup;
            }
            written += n_written;
        }
    }

    result = 1;

cleanup:
    Safefree(buffer);
    close(fd_src);
    close(fd_dst);
    if (result && g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
#endif
}

static int file_move_internal(pTHX_ const char *src, const char *dst) {
    int result;
    
    /* Try rename first (fast path for same filesystem) */
    if (rename(src, dst) == 0) {
        result = 1;
    }
    /* If EXDEV, copy then delete (cross-device move) */
    else if (errno == EXDEV) {
        if (file_copy_internal(aTHX_ src, dst)) {
            result = file_unlink_internal(src);
        } else {
            return 0;
        }
    } else {
        return 0;
    }
    
    /* Invalidate cache for both paths */
    if (g_stat_cache.valid) {
        if (strcmp(src, g_stat_cache.path) == 0 || strcmp(dst, g_stat_cache.path) == 0) {
            g_stat_cache.valid = 0;
        }
    }
    return result;
}

static int file_touch_internal(const char *path) {
    dTHX;
    int result;
#ifdef _WIN32
    HANDLE h;
    FILETIME ft;
    SYSTEMTIME st;
    result = 0;

    /* Try to open existing file */
    h = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
                    NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        return 0;
    }

    GetSystemTime(&st);
    SystemTimeToFileTime(&st, &ft);
    result = SetFileTime(h, NULL, &ft, &ft) != 0;
    CloseHandle(h);
#else
    int fd;
    /* Try to update times on existing file - utime(path, NULL) sets to current time */
    if (utime(path, NULL) == 0) {
        result = 1;
    } else {
        /* File doesn't exist, create it */
        fd = file_open3(path, O_WRONLY | O_CREAT, 0644);
        if (fd < 0) {
            return 0;
        }
        close(fd);
        result = 1;
    }
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_chmod_internal(const char *path, int mode) {
    dTHX;
    int result;
#ifdef _WIN32
    result = _chmod(path, mode) == 0;
#else
    result = chmod(path, mode) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_mkdir_internal(const char *path, int mode) {
    dTHX;
    int result;
#ifdef _WIN32
    PERL_UNUSED_VAR(mode);
    result = _mkdir(path) == 0;
#else
    result = mkdir(path, mode) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_rmdir_internal(const char *path) {
    dTHX;
    int result;
#ifdef _WIN32
    result = _rmdir(path) == 0;
#else
    result = rmdir(path) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

/* ============================================
   Directory listing
   ============================================ */

static AV* file_readdir_internal(pTHX_ const char *path) {
    AV *result = newAV();

#ifdef _WIN32
    WIN32_FIND_DATAA fd;
    HANDLE h;
    char pattern[MAX_PATH];
    size_t len = strlen(path);

    if (len + 3 > MAX_PATH) return result;

    memcpy(pattern, path, len);
    if (len > 0 && path[len-1] != '\\' && path[len-1] != '/') {
        pattern[len++] = '\\';
    }
    pattern[len++] = '*';
    pattern[len] = '\0';

    h = FindFirstFileA(pattern, &fd);
    if (h == INVALID_HANDLE_VALUE) return result;

    do {
        /* Skip . and .. */
        if (strcmp(fd.cFileName, ".") != 0 && strcmp(fd.cFileName, "..") != 0) {
            av_push(result, newSVpv(fd.cFileName, 0));
        }
    } while (FindNextFileA(h, &fd));

    FindClose(h);
#else
    DIR *dir;
    struct dirent *entry;

    dir = opendir(path);
    if (!dir) return result;

    while ((entry = readdir(dir)) != NULL) {
        /* Skip . and .. */
        if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            av_push(result, newSVpv(entry->d_name, 0));
        }
    }

    closedir(dir);
#endif

    return result;
}

/* ============================================
   Path manipulation
   ============================================ */

static SV* file_basename_internal(pTHX_ const char *path) {
    const char *p;
    size_t len = strlen(path);

    if (len == 0) return newSVpvs("");

    /* Skip trailing slashes */
    while (len > 0 && (path[len-1] == '/' || path[len-1] == '\\')) {
        len--;
    }
    if (len == 0) return newSVpvs("");

    /* Find last separator */
    p = path + len - 1;
    while (p > path && *p != '/' && *p != '\\') {
        p--;
    }
    if (*p == '/' || *p == '\\') p++;

    return newSVpvn(p, (path + len) - p);
}

static SV* file_dirname_internal(pTHX_ const char *path) {
    const char *end;
    size_t len = strlen(path);

    if (len == 0) return newSVpvs(".");

    /* Skip trailing slashes */
    end = path + len - 1;
    while (end > path && (*end == '/' || *end == '\\')) {
        end--;
    }

    /* Find last separator */
    while (end > path && *end != '/' && *end != '\\') {
        end--;
    }

    if (end == path) {
        if (*end == '/' || *end == '\\') {
            return newSVpvn(path, 1);
        }
        return newSVpvs(".");
    }

    /* Skip multiple trailing slashes in dirname */
    while (end > path && (*(end-1) == '/' || *(end-1) == '\\')) {
        end--;
    }

    return newSVpvn(path, end - path);
}

static SV* file_extname_internal(pTHX_ const char *path) {
    const char *dot;
    const char *basename;
    size_t len = strlen(path);

    if (len == 0) return newSVpvs("");

    /* Find basename first */
    basename = path + len - 1;
    while (basename > path && *basename != '/' && *basename != '\\') {
        basename--;
    }
    if (*basename == '/' || *basename == '\\') basename++;

    /* Find last dot in basename */
    dot = strrchr(basename, '.');
    if (!dot || dot == basename) return newSVpvs("");

    return newSVpv(dot, 0);
}

static SV* file_join_internal(pTHX_ AV *parts) {
    SV *result;
    SSize_t i, len;
    STRLEN total_len = 0;
    char *buf, *p;
    int need_sep;

    len = av_len(parts) + 1;
    if (len == 0) return newSVpvs("");

    /* Calculate total length */
    for (i = 0; i < len; i++) {
        SV **sv = av_fetch(parts, i, 0);
        if (sv && SvPOK(*sv)) {
            total_len += SvCUR(*sv) + 1;  /* +1 for separator */
        }
    }

    result = newSV(total_len + 1);
    SvPOK_on(result);
    buf = SvPVX(result);
    p = buf;
    need_sep = 0;

    for (i = 0; i < len; i++) {
        SV **sv = av_fetch(parts, i, 0);
        if (sv && SvPOK(*sv)) {
            STRLEN part_len;
            const char *part = SvPV(*sv, part_len);

            if (part_len == 0) continue;

            /* Skip leading separator if we already have one */
            while (part_len > 0 && (*part == '/' || *part == '\\')) {
                if (!need_sep && p == buf) break;  /* Keep root slash */
                part++;
                part_len--;
            }

            if (need_sep && part_len > 0) {
#ifdef _WIN32
                *p++ = '\\';
#else
                *p++ = '/';
#endif
            }

            if (part_len > 0) {
                memcpy(p, part, part_len);
                p += part_len;

                /* Check if ends with separator */
                need_sep = (*(p-1) != '/' && *(p-1) != '\\');
            }
        }
    }

    *p = '\0';
    SvCUR_set(result, p - buf);
    return result;
}

/* ============================================
   Head and Tail operations
   ============================================ */

static AV* file_head_internal(pTHX_ const char *path, IV n) {
    AV *result = newAV();
    IV idx;
    SV *line;
    IV count = 0;

    if (n <= 0) return result;

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) return result;

    while (count < n && (line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
        av_push(result, line);
        count++;
    }

    file_lines_close(idx);
    return result;
}

static AV* file_tail_internal(pTHX_ const char *path, IV n) {
    AV *result = newAV();
    AV *buffer;
    SV *line;
    IV idx;
    SSize_t i, buf_len;

    if (n <= 0) return result;

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) return result;

    /* Use circular buffer to keep last N lines */
    buffer = newAV();
    av_extend(buffer, n - 1);

    while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
        if (av_len(buffer) + 1 >= n) {
            SV *old = av_shift(buffer);
            SvREFCNT_dec(old);
        }
        av_push(buffer, line);
    }

    file_lines_close(idx);

    /* Copy buffer to result */
    buf_len = av_len(buffer) + 1;
    for (i = 0; i < buf_len; i++) {
        SV **sv = av_fetch(buffer, i, 0);
        if (sv) {
            av_push(result, newSVsv(*sv));
        }
    }

    SvREFCNT_dec((SV*)buffer);
    return result;
}

/* range_lines: 1-based, half-open in count style.
 * range_lines($p, 1, 10)  -> first 10 lines (same as head($p, 10))
 * range_lines($p, 5, 3)   -> lines 5, 6, 7
 * If `from` is past EOF or `count <= 0`, returns an empty AV (no error).
 * `from < 1` is also treated as empty (caller error - documented).
 *
 * Implementation: skip-then-take using the existing line iterator. SVs
 * for the skipped lines are allocated and immediately freed; that's
 * O(skip) cheap work but bounded by line size, not file size. For very
 * large skips (millions of lines) a buffer-scan-without-allocation
 * variant would help; deferred until benchmarks demand it. */
static AV* file_range_internal(pTHX_ const char *path, IV from, IV count) {
    AV *result = newAV();
    IV idx, i;
    SV *line;

    if (count <= 0 || from < 1) return result;

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) return result;

    /* Skip lines 1 .. from-1 */
    for (i = 0; i < from - 1; i++) {
        line = file_lines_next(aTHX_ idx);
        if (line == &PL_sv_undef) {
            file_lines_close(idx);
            return result;
        }
        SvREFCNT_dec(line);
    }

    /* Take `count` lines starting at line `from` */
    av_extend(result, count - 1);
    for (i = 0; i < count; i++) {
        line = file_lines_next(aTHX_ idx);
        if (line == &PL_sv_undef) break;
        av_push(result, line);
    }

    file_lines_close(idx);
    return result;
}

/* ============================================
   Atomic spew - write to temp file then rename
   ============================================ */

static int file_atomic_spew_internal(pTHX_ const char *path, SV *data) {
    char temp_path[4096];
    int fd;
    const char *buf;
    STRLEN len;
    ssize_t written = 0, n;
    static int counter = 0;
#ifdef _WIN32
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
    int pid = (int)GetCurrentProcessId();
#else
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC;
    int pid = (int)getpid();
#endif

    /* Create temp file name in same directory */
    snprintf(temp_path, sizeof(temp_path), "%s.tmp.%d.%d", path, pid, counter++);

    buf = SvPV(data, len);

    fd = file_open3(temp_path, open_flags, 0644);
    if (fd < 0) {
        return 0;
    }

    while ((size_t)written < len) {
        n = write(fd, buf + written, len - written);
        if (n < 0) {
            if (errno == EINTR) continue;
            close(fd);
            file_unlink_internal(temp_path);
            return 0;
        }
        written += n;
    }

#ifdef _WIN32
    /* Sync to disk on Windows */
    _commit(fd);
#else
    /* Sync to disk on POSIX */
    fsync(fd);
#endif

    close(fd);

    /* Atomic rename */
    if (rename(temp_path, path) != 0) {
        file_unlink_internal(temp_path);
        return 0;
    }

    /* Invalidate cache for this path */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
}

/* ============================================
   Split lines utility
   ============================================ */

static AV* file_split_lines(pTHX_ SV *content) {
    AV *lines;
    const char *start, *end, *p;
    STRLEN len;

    start = SvPV(content, len);
    end = start + len;
    lines = newAV();

    while (start < end) {
        p = memchr(start, '\n', end - start);
        if (p) {
            av_push(lines, newSVpvn(start, p - start));
            start = p + 1;
        } else {
            if (start < end) {
                av_push(lines, newSVpvn(start, end - start));
            }
            break;
        }
    }

    return lines;
}

/* ============================================
   XS Functions
   ============================================ */

XS_INTERNAL(xs_slurp) {
    dXSARGS;
    const char *path;
    SV *bytes;

    if (items < 1)
        croak("Usage: file::slurp(path [, plugin => ..., key => value ...])");

    path  = SvPV_nolen(ST(0));
    bytes = file_slurp_internal(aTHX_ path);

    if (items > 1) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 1, items, "slurp");
        SV *out  = file_plugin_dispatch_read(aTHX_ opts, path, bytes);
        SvREFCNT_dec((SV *)opts);
        if (!out) {
            SvREFCNT_dec(bytes);
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }
        if (out != bytes) {
            SvREFCNT_dec(bytes);
            bytes = out;
        }
    }

    ST(0) = sv_2mortal(bytes);
    XSRETURN(1);
}

XS_INTERNAL(xs_slurp_raw) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::slurp_raw(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_slurp_raw(aTHX_ path));
    XSRETURN(1);
}

XS_INTERNAL(xs_spew) {
    dXSARGS;
    const char *path;
    SV *payload;
    SV *bytes_to_write = NULL;

    if (items < 2)
        croak("Usage: file::spew(path, data [, plugin => ..., key => value ...])");

    path    = SvPV_nolen(ST(0));
    payload = ST(1);

    if (items > 2) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "spew");
        bytes_to_write = file_plugin_dispatch_write(aTHX_ opts, path, payload);
        SvREFCNT_dec((SV *)opts);
        if (!bytes_to_write) {
            ST(0) = &PL_sv_no;
            XSRETURN(1);
        }
        payload = sv_2mortal(bytes_to_write);
    }

    ST(0) = file_spew_internal(aTHX_ path, payload) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_append) {
    dXSARGS;
    const char *path;
    SV *payload;
    SV *bytes_to_write = NULL;

    if (items < 2)
        croak("Usage: file::append(path, data [, plugin => ..., key => value ...])");

    path    = SvPV_nolen(ST(0));
    payload = ST(1);

    if (items > 2) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "append");
        bytes_to_write = file_plugin_dispatch_write(aTHX_ opts, path, payload);
        SvREFCNT_dec((SV *)opts);
        if (!bytes_to_write) {
            ST(0) = &PL_sv_no;
            XSRETURN(1);
        }
        payload = sv_2mortal(bytes_to_write);
    }

    ST(0) = file_append_internal(aTHX_ path, payload) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_size) {
    dXSARGS;
    const char *path;
    IV size;

    if (items != 1) croak("Usage: file::size(path)");

    path = SvPV_nolen(ST(0));
    size = file_size_internal(path);
    ST(0) = sv_2mortal(newSViv(size));
    XSRETURN(1);
}

XS_INTERNAL(xs_mtime) {
    dXSARGS;
    const char *path;
    IV mtime;

    if (items != 1) croak("Usage: file::mtime(path)");

    path = SvPV_nolen(ST(0));
    mtime = file_mtime_internal(path);
    ST(0) = sv_2mortal(newSViv(mtime));
    XSRETURN(1);
}

XS_INTERNAL(xs_exists) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::exists(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_exists_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_file) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_file(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_file_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_dir) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_dir(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_dir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_readable) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_readable(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_readable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_writable) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_writable(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_writable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_lines) {
    dXSARGS;
    const char *path;
    AV *lines;
    int fd;
    Stat_t st;
    char *buffer;
    char *p, *end, *line_start;
    size_t file_size;
    ssize_t total_read, n;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    int open_flags = O_RDONLY;
#endif

    if (items < 1)
        croak("Usage: file::lines(path [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));

    /* Plugin path: route the slurp through plugin READ. If the plugin
     * returns an arrayref we hand that back unchanged (each element is
     * a record). If it returns bytes we fall through to the byte-split
     * helper below by stashing them in `buffer`. */
    if (items > 1) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 1, items, "lines");
        SV *bytes = file_slurp_internal(aTHX_ path);
        SV *out   = file_plugin_dispatch_read(aTHX_ opts, path, bytes);
        SvREFCNT_dec((SV *)opts);
        if (!out) {
            SvREFCNT_dec(bytes);
            ST(0) = sv_2mortal(newRV_noinc((SV *)newAV()));
            XSRETURN(1);
        }
        if (out != bytes) SvREFCNT_dec(bytes);
        if (SvROK(out) && SvTYPE(SvRV(out)) == SVt_PVAV) {
            ST(0) = sv_2mortal(out);
            XSRETURN(1);
        }
        /* Plugin returned bytes - reuse the byte-split path below. */
        {
            STRLEN len;
            const char *pv = SvPV(out, len);
            AV *result = newAV();
            const char *cursor = pv;
            const char *bend = pv + len;
            const char *nl;
            av_extend(result, len / 40);
            while (cursor < bend) {
                nl = (const char *)memchr(cursor, '\n', bend - cursor);
                if (nl) {
                    av_push(result, newSVpvn(cursor, nl - cursor));
                    cursor = nl + 1;
                } else {
                    if (cursor < bend)
                        av_push(result, newSVpvn(cursor, bend - cursor));
                    break;
                }
            }
            SvREFCNT_dec(out);
            ST(0) = sv_2mortal(newRV_noinc((SV *)result));
            XSRETURN(1);
        }
    }

    fd = open(path, open_flags);
    if (UNLIKELY(fd < 0)) {
        ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));
        XSRETURN(1);
    }

    /* Get file size for single-read optimization */
    if (UNLIKELY(fstat(fd, &st) < 0 || st.st_size == 0)) {
        close(fd);
        ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));
        XSRETURN(1);
    }

    file_size = st.st_size;
    Newx(buffer, file_size + 1, char);

    /* Read entire file in one syscall when possible */
    total_read = 0;
    while ((size_t)total_read < file_size) {
        n = read(fd, buffer + total_read, file_size - total_read);
        if (UNLIKELY(n < 0)) {
            if (errno == EINTR) continue;
            break;
        }
        if (n == 0) break;
        total_read += n;
    }
    close(fd);

    if (UNLIKELY(total_read == 0)) {
        Safefree(buffer);
        ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));
        XSRETURN(1);
    }

    lines = newAV();
    /* Pre-extend array based on estimated lines */
    av_extend(lines, total_read / 40);

    /* Single scan through buffer - no memmove, no buffer resize */
    line_start = buffer;
    end = buffer + total_read;
    p = buffer;

    while (p < end) {
        p = memchr(p, '\n', end - p);
        if (LIKELY(p != NULL)) {
            av_push(lines, newSVpvn(line_start, p - line_start));
            p++;
            line_start = p;
        } else {
            /* Last line without trailing newline */
            if (line_start < end) {
                av_push(lines, newSVpvn(line_start, end - line_start));
            }
            break;
        }
    }

    Safefree(buffer);

    ST(0) = sv_2mortal(newRV_noinc((SV*)lines));
    XSRETURN(1);
}

XS_INTERNAL(xs_mmap_open) {
    dXSARGS;
    const char *path;
    int writable;
    IV idx;
    HV *hash;

    if (items < 1 || items > 2) croak("Usage: file::mmap_open(path, [writable])");

    path = SvPV_nolen(ST(0));
    writable = (items > 1 && SvTRUE(ST(1))) ? 1 : 0;

    idx = file_mmap_open(aTHX_ path, writable);
    if (idx < 0) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    hash = newHV();
    hv_store(hash, "_idx", 4, newSViv(idx), 0);
    hv_store(hash, "_writable", 9, newSViv(writable), 0);

    ST(0) = sv_2mortal(sv_bless(newRV_noinc((SV*)hash), gv_stashpv("File::Raw::mmap", GV_ADD)));
    XSRETURN(1);
}

XS_INTERNAL(xs_mmap_data) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    if (items != 1) croak("Usage: $mmap->data");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        croak("Invalid mmap object");
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    ST(0) = sv_2mortal(file_mmap_get_sv(aTHX_ idx));
    XSRETURN(1);
}

XS_INTERNAL(xs_mmap_sync) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    if (items != 1) croak("Usage: $mmap->sync");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        croak("Invalid mmap object");
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    file_mmap_sync(idx);
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_mmap_close) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    if (items != 1) croak("Usage: $mmap->close");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        croak("Invalid mmap object");
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    file_mmap_close(idx);
    hv_store(hash, "_idx", 4, newSViv(-1), 0);
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_mmap_DESTROY) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    PERL_UNUSED_VAR(items);

    if (PL_dirty) XSRETURN_EMPTY;

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        XSRETURN_EMPTY;
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    if (idx >= 0) {
        file_mmap_close(idx);
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_lines_iter) {
    dXSARGS;
    const char *path;
    IV idx;
    SV *idx_sv;

    if (items < 1)
        croak("Usage: file::lines_iter(path [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));

    /* Plugin path: slurp + dispatch READ, wrap the resulting AoA in an
     * iterator that walks records in order. This is eager (whole AoA
     * held in memory) - for true streaming use each_line($p, $cb,
     * plugin => ...). The iterator interface itself is preserved so
     * code that stores the iterator handle still composes. */
    if (items > 1) {
        HV *opts;
        SV *bytes;
        SV *out;
        AV *records;
        LineIterEntry *entry;

        opts = file_plugin_build_opts(aTHX_ &ST(0), 1, items, "lines_iter");
        bytes = file_slurp_internal(aTHX_ path);
        out = file_plugin_dispatch_read(aTHX_ opts, path, bytes);
        SvREFCNT_dec((SV *)opts);
        if (!out) {
            SvREFCNT_dec(bytes);
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }
        if (out != bytes) SvREFCNT_dec(bytes);
        if (!SvROK(out) || SvTYPE(SvRV(out)) != SVt_PVAV) {
            SvREFCNT_dec(out);
            croak("File::Raw::lines_iter: plugin must return an arrayref of records");
        }
        records = (AV *)SvRV(out);
        SvREFCNT_inc(records);   /* keep the AV alive on its own */
        SvREFCNT_dec(out);       /* drop the RV wrapper */

        idx = alloc_iter_slot();
        entry = &g_iters[idx];
        entry->fd           = -1;        /* sentinel: no file behind us */
        entry->buffer       = NULL;
        entry->buf_size     = 0;
        entry->buf_pos      = 0;
        entry->buf_len      = 0;
        entry->eof          = 0;
        entry->refcount     = 1;
        entry->path         = NULL;
        entry->records      = records;
        entry->records_idx  = 0;

        idx_sv = newSViv(idx);
        ST(0) = sv_2mortal(sv_bless(newRV_noinc(idx_sv),
                                    gv_stashpv("File::Raw::lines", GV_ADD)));
        XSRETURN(1);
    }

    idx = file_lines_open(aTHX_ path);

    if (idx < 0) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    /* Use simple IV reference - much faster than hash */
    idx_sv = newSViv(idx);
    ST(0) = sv_2mortal(sv_bless(newRV_noinc(idx_sv), gv_stashpv("File::Raw::lines", GV_ADD)));
    XSRETURN(1);
}

XS_INTERNAL(xs_lines_iter_next) {
    dXSARGS;
    SV *rv;
    IV idx;
    LineIterEntry *entry;
    char *line_start;
    char *newline;
    size_t line_len;
    SV *result;
    ssize_t n;

    if (items != 1) croak("Usage: $iter->next");

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        croak("Invalid lines iterator object");
    }

    /* Direct IV access - no hash lookup */
    idx = SvIV(SvRV(rv));

    if (UNLIKELY(idx < 0 || idx >= g_iters_count)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    entry = &g_iters[idx];

    /* Record-iter mode: walk the AoA we collected at lines_iter() time. */
    if (entry->records) {
        SSize_t total = av_len(entry->records) + 1;
        if (entry->records_idx >= total) {
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }
        SV **rp = av_fetch(entry->records, entry->records_idx++, 0);
        ST(0) = (rp && *rp) ? sv_2mortal(newSVsv(*rp)) : &PL_sv_undef;
        XSRETURN(1);
    }

    if (UNLIKELY(entry->fd < 0)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    /* Inline buffer parsing for speed */
    while (1) {
        /* Look for newline in current buffer */
        if (entry->buf_pos < entry->buf_len) {
            line_start = entry->buffer + entry->buf_pos;
            newline = memchr(line_start, '\n', entry->buf_len - entry->buf_pos);

            if (newline) {
                line_len = newline - line_start;
                result = newSVpvn(line_start, line_len);
                entry->buf_pos += line_len + 1;
                ST(0) = sv_2mortal(result);
                XSRETURN(1);
            }
        }

        /* No newline found, need more data */
        if (entry->eof) {
            /* Return remaining data if any */
            if (entry->buf_pos < entry->buf_len) {
                line_len = entry->buf_len - entry->buf_pos;
                result = newSVpvn(entry->buffer + entry->buf_pos, line_len);
                entry->buf_pos = entry->buf_len;
                ST(0) = sv_2mortal(result);
                XSRETURN(1);
            }
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }

        /* Move remaining data to start of buffer */
        if (entry->buf_pos > 0) {
            size_t remaining = entry->buf_len - entry->buf_pos;
            if (remaining > 0) {
                memmove(entry->buffer, entry->buffer + entry->buf_pos, remaining);
            }
            entry->buf_len = remaining;
            entry->buf_pos = 0;
        }

        /* Expand buffer if needed */
        if (entry->buf_len >= entry->buf_size - 1) {
            entry->buf_size *= 2;
            Renew(entry->buffer, entry->buf_size, char);
        }

        /* Read more data */
        n = read(entry->fd, entry->buffer + entry->buf_len,
                 entry->buf_size - entry->buf_len - 1);
        if (n < 0) {
            if (errno == EINTR) continue;
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }
        if (n == 0) {
            entry->eof = 1;
        } else {
            entry->buf_len += n;
        }
    }
}

XS_INTERNAL(xs_lines_iter_eof) {
    dXSARGS;
    SV *rv;
    IV idx;
    LineIterEntry *entry;

    if (items != 1) croak("Usage: $iter->eof");

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        croak("Invalid lines iterator object");
    }

    /* Direct IV access and inline eof check */
    idx = SvIV(SvRV(rv));

    if (UNLIKELY(idx < 0 || idx >= g_iters_count)) {
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
    }

    entry = &g_iters[idx];
    if (entry->records) {
        ST(0) = (entry->records_idx >= (av_len(entry->records) + 1))
                  ? &PL_sv_yes : &PL_sv_no;
        XSRETURN(1);
    }
    ST(0) = (entry->eof && entry->buf_pos >= entry->buf_len) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_lines_iter_close) {
    dXSARGS;
    SV *rv, *inner;
    IV idx;

    if (items != 1) croak("Usage: $iter->close");

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        croak("Invalid lines iterator object");
    }

    inner = SvRV(rv);
    idx = SvIV(inner);

    file_lines_close(idx);
    sv_setiv(inner, -1);  /* Mark as closed */
    XSRETURN_EMPTY;
}

XS_INTERNAL(xs_lines_iter_DESTROY) {
    dXSARGS;
    SV *rv;
    IV idx;

    PERL_UNUSED_VAR(items);

    if (PL_dirty) XSRETURN_EMPTY;

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        XSRETURN_EMPTY;
    }

    idx = SvIV(SvRV(rv));

    if (idx >= 0) {
        file_lines_close(idx);
    }
    XSRETURN_EMPTY;
}

/* ============================================
   Callback registry for line processing
   Allows C-level predicates for maximum speed
   ============================================ */

/* Predicate function type for line processing */
typedef bool (*file_line_predicate)(pTHX_ SV *line);

/* Registered callback entry */
typedef struct {
    file_line_predicate predicate;  /* C function pointer (NULL for Perl-only) */
    SV *perl_callback;              /* Perl callback (for fallback or custom) */
} FileLineCallback;

/* Global callback registry */
static HV *g_file_callback_registry = NULL;

/* Built-in C predicates */
static bool pred_is_blank(pTHX_ SV *line) {
    STRLEN len;
    const char *s = SvPV(line, len);
    STRLEN i;
    for (i = 0; i < len; i++) {
        if (s[i] != ' ' && s[i] != '\t' && s[i] != '\r' && s[i] != '\n') {
            return FALSE;
        }
    }
    return TRUE;
}

static bool pred_is_not_blank(pTHX_ SV *line) {
    return !pred_is_blank(aTHX_ line);
}

static bool pred_is_empty(pTHX_ SV *line) {
    return SvCUR(line) == 0;
}

static bool pred_is_not_empty(pTHX_ SV *line) {
    return SvCUR(line) > 0;
}

static bool pred_is_comment(pTHX_ SV *line) {
    STRLEN len;
    const char *s = SvPV(line, len);
    /* Skip leading whitespace */
    while (len > 0 && (*s == ' ' || *s == '\t')) {
        s++;
        len--;
    }
    return len > 0 && *s == '#';
}

static bool pred_is_not_comment(pTHX_ SV *line) {
    return !pred_is_comment(aTHX_ line);
}

/* Cleanup callback registry during global destruction */
static void file_cleanup_callback_registry(pTHX_ void *data) {
    PERL_UNUSED_ARG(data);

    /* During global destruction, just NULL out pointers.
     * Perl handles SV cleanup; trying to free them ourselves
     * can cause crashes due to destruction order. */
    if (PL_dirty) {
        g_file_callback_registry = NULL;
        return;
    }

    /* Normal cleanup - not during global destruction */
    g_file_callback_registry = NULL;
}

static void file_init_callback_registry(pTHX) {
    SV *sv;
    FileLineCallback *cb;

    if (g_file_callback_registry) return;
    g_file_callback_registry = newHV();

    /* Register built-in predicates with both naming conventions */
    /* blank / is_blank */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_blank;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "blank", 5, sv, 0);
    hv_store(g_file_callback_registry, "is_blank", 8, SvREFCNT_inc(sv), 0);

    /* not_blank / is_not_blank */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_not_blank;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "not_blank", 9, sv, 0);
    hv_store(g_file_callback_registry, "is_not_blank", 12, SvREFCNT_inc(sv), 0);

    /* empty / is_empty */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_empty;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "empty", 5, sv, 0);
    hv_store(g_file_callback_registry, "is_empty", 8, SvREFCNT_inc(sv), 0);

    /* not_empty / is_not_empty */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_not_empty;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "not_empty", 9, sv, 0);
    hv_store(g_file_callback_registry, "is_not_empty", 12, SvREFCNT_inc(sv), 0);

    /* comment / is_comment */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_comment;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "comment", 7, sv, 0);
    hv_store(g_file_callback_registry, "is_comment", 10, SvREFCNT_inc(sv), 0);

    /* not_comment / is_not_comment */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_not_comment;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "not_comment", 11, sv, 0);
    hv_store(g_file_callback_registry, "is_not_comment", 14, SvREFCNT_inc(sv), 0);
}

static FileLineCallback* file_get_callback(pTHX_ const char *name) {
    SV **svp;
    if (!g_file_callback_registry) return NULL;
    svp = hv_fetch(g_file_callback_registry, name, strlen(name), 0);
    if (svp && SvIOK(*svp)) {
        return INT2PTR(FileLineCallback*, SvIVX(*svp));
    }
    return NULL;
}

/* Process lines with callback - MULTICALL optimized (Perl >= 5.14 only) */
XS_INTERNAL(xs_each_line) {
    dXSARGS;
#if PERL_VERSION >= 14
    dMULTICALL;
#endif
    const char *path;
    SV *callback;
    IV idx;
    CV *block_cv;
    SV *old_defsv;
    SV *line_sv;
    LineIterEntry *entry;
    char *line_start;
    char *newline;
    size_t line_len;
    ssize_t n;
#if PERL_VERSION >= 14
    U8 gimme = G_VOID;
#endif

    if (items < 2)
        croak("Usage: file::each_line(path, callback [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));
    callback = ST(1);

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV) {
        croak("Second argument must be a code reference");
    }

    /* Plugin path: route through streaming dispatch. The plugin's
     * stream fn owns the record emission and calls back to `callback`
     * per record (typically once for each parsed CSV row, etc.). */
    if (items > 2) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "each_line");
        (void)file_plugin_dispatch_stream(aTHX_ opts, path, callback);
        SvREFCNT_dec((SV *)opts);
        XSRETURN_EMPTY;
    }

    block_cv = (CV*)SvRV(callback);
    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        XSRETURN_EMPTY;
    }

    entry = &g_iters[idx];

    old_defsv = DEFSV;
    line_sv = newSV(256);
    DEFSV = line_sv;

#if PERL_VERSION >= 14
    PUSH_MULTICALL(block_cv);
#endif

    while (1) {
        /* Look for newline in current buffer */
        if (entry->buf_pos < entry->buf_len) {
            line_start = entry->buffer + entry->buf_pos;
            newline = memchr(line_start, '\n', entry->buf_len - entry->buf_pos);

            if (newline) {
                line_len = newline - line_start;
                sv_setpvn(line_sv, line_start, line_len);
                entry->buf_pos += line_len + 1;
#if PERL_VERSION >= 14
                MULTICALL;
#else
                { dSP; PUSHMARK(SP); call_sv((SV*)block_cv, G_VOID|G_DISCARD); }
#endif
                continue;
            }
        }

        /* No newline found, need more data */
        if (entry->eof) {
            /* Return remaining data if any */
            if (entry->buf_pos < entry->buf_len) {
                line_len = entry->buf_len - entry->buf_pos;
                sv_setpvn(line_sv, entry->buffer + entry->buf_pos, line_len);
                entry->buf_pos = entry->buf_len;
#if PERL_VERSION >= 14
                MULTICALL;
#else
                { dSP; PUSHMARK(SP); call_sv((SV*)block_cv, G_VOID|G_DISCARD); }
#endif
            }
            break;
        }

        /* Move remaining data to start of buffer */
        if (entry->buf_pos > 0) {
            size_t remaining = entry->buf_len - entry->buf_pos;
            if (remaining > 0) {
                memmove(entry->buffer, entry->buffer + entry->buf_pos, remaining);
            }
            entry->buf_len = remaining;
            entry->buf_pos = 0;
        }

        /* Expand buffer if needed */
        if (entry->buf_len >= entry->buf_size - 1) {
            entry->buf_size *= 2;
            Renew(entry->buffer, entry->buf_size, char);
        }

        /* Read more data */
        n = read(entry->fd, entry->buffer + entry->buf_len,
                 entry->buf_size - entry->buf_len - 1);
        if (n < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (n == 0) {
            entry->eof = 1;
        } else {
            entry->buf_len += n;
        }
    }

#if PERL_VERSION >= 14
    POP_MULTICALL;
#endif
    SvREFCNT_dec(line_sv);
    DEFSV = old_defsv;
    file_lines_close(idx);
    XSRETURN_EMPTY;
}

/* Run plugin READ, expect arrayref result. Returns the underlying AV*
 * (whose RV is stored in *out_holder for the caller to refcount-dec).
 * Returns NULL if the plugin cancelled. Croaks if the plugin returned
 * a non-arrayref (predicate-style XSUBs need an iterable). */
static AV *file_records_via_plugin(pTHX_ HV *opts, const char *path,
                                   SV **out_holder)
{
    SV *bytes = file_slurp_internal(aTHX_ path);
    SV *out   = file_plugin_dispatch_read(aTHX_ opts, path, bytes);
    if (!out) {
        SvREFCNT_dec(bytes);
        return NULL;
    }
    if (out != bytes) SvREFCNT_dec(bytes);
    if (!SvROK(out) || SvTYPE(SvRV(out)) != SVt_PVAV) {
        SvREFCNT_dec(out);
        croak("File::Raw: plugin must return an arrayref of records "
              "for predicate-style operations");
    }
    *out_holder = out;
    return (AV *)SvRV(out);
}

/* Apply a coderef predicate to one record. Returns 1 if matched, 0 otherwise.
 * Used by the plugin path of grep/count/find. */
static int file_call_predicate_cv(pTHX_ CV *cv, SV *record) {
    int matches = 0;
    int n;
    SV *r;
    dSP;
    PUSHMARK(SP);
    XPUSHs(record);
    PUTBACK;
    n = call_sv((SV *)cv, G_SCALAR);
    SPAGAIN;
    if (n > 0) {
        r = POPs;
        matches = SvTRUE(r) ? 1 : 0;
    }
    PUTBACK;
    return matches;
}

/* Grep lines with callback or registered predicate name */
XS_INTERNAL(xs_grep_lines) {
    dXSARGS;
    const char *path;
    SV *predicate;
    IV idx;
    SV *line;
    AV *result;
    CV *block_cv = NULL;
    FileLineCallback *fcb = NULL;

    if (items < 2)
        croak("Usage: file::grep_lines(path, &predicate or $name [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));
    predicate = ST(1);

    /* Plugin path: records come from plugin READ; predicate must be a coderef. */
    if (items > 2) {
        HV *opts;
        SV *holder = NULL;
        AV *records;
        SSize_t i, n;
        AV *matched;

        if (!SvROK(predicate) || SvTYPE(SvRV(predicate)) != SVt_PVCV)
            croak("File::Raw::grep_lines: predicate must be a coderef when "
                  "a plugin is in use (predicate-name sugar is legacy 2-arg only)");

        opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "grep_lines");
        records = file_records_via_plugin(aTHX_ opts, path, &holder);
        SvREFCNT_dec((SV *)opts);
        if (!records) {
            ST(0) = sv_2mortal(newRV_noinc((SV *)newAV()));
            XSRETURN(1);
        }

        matched = newAV();
        n = av_len(records) + 1;
        for (i = 0; i < n; i++) {
            SV **rp = av_fetch(records, i, 0);
            SV *rec = (rp && *rp) ? *rp : &PL_sv_undef;
            if (file_call_predicate_cv(aTHX_ (CV *)SvRV(predicate), rec))
                av_push(matched, SvREFCNT_inc(rec));
        }
        SvREFCNT_dec(holder);
        ST(0) = sv_2mortal(newRV_noinc((SV *)matched));
        XSRETURN(1);
    }
    result = newAV();

    /* Check if predicate is a name or coderef */
    if (SvROK(predicate) && SvTYPE(SvRV(predicate)) == SVt_PVCV) {
        block_cv = (CV*)SvRV(predicate);
    } else {
        const char *name = SvPV_nolen(predicate);
        fcb = file_get_callback(aTHX_ name);
        if (!fcb) {
            croak("File::Raw::grep_lines: unknown predicate '%s'", name);
        }
    }

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
        XSRETURN(1);
    }

    /* C predicate path - fastest */
    if (fcb && fcb->predicate) {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            if (fcb->predicate(aTHX_ line)) {
                av_push(result, line);
            } else {
                SvREFCNT_dec(line);
            }
        }
        file_lines_close(idx);
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
        XSRETURN(1);
    }

    /* Call Perl callback */
    {
        SV *cb_sv = fcb ? fcb->perl_callback : (SV*)block_cv;
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV count;
            SV *result_sv;
            bool matches = FALSE;
            PUSHMARK(SP);
            XPUSHs(line);
            PUTBACK;
            count = call_sv(cb_sv, G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                result_sv = POPs;
                matches = SvTRUE(result_sv);
            }
            PUTBACK;
            if (matches) {
                av_push(result, line);
            } else {
                SvREFCNT_dec(line);
            }
        }
    }

    file_lines_close(idx);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* Count lines matching predicate */
XS_INTERNAL(xs_count_lines) {
    dXSARGS;
    const char *path;
    SV *predicate = NULL;
    IV idx;
    SV *line;
    IV count = 0;
    CV *block_cv = NULL;
    FileLineCallback *fcb = NULL;

    if (items < 1)
        croak("Usage: file::count_lines(path [, &predicate or $name] [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));

    /* Plugin path: if items > 2 we definitely have a plugin tail. Otherwise
     * if items == 2 and ST(1) looks like the start of options (a string key
     * with a value missing - i.e. items == 2 but ST(1) is a known options
     * key like "plugin"), users use the explicit form by passing a coderef
     * or undef as the predicate slot first. Keep it strict: plugin tail
     * begins at position 2, so items must be >= 3 (predicate may be undef). */
    if (items > 2) {
        HV *opts;
        SV *holder = NULL;
        AV *records;
        SSize_t i, n;
        IV matched = 0;
        int has_pred = SvOK(ST(1));

        if (has_pred && (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV))
            croak("File::Raw::count_lines: predicate must be a coderef or undef "
                  "when a plugin is in use");

        opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "count_lines");
        records = file_records_via_plugin(aTHX_ opts, path, &holder);
        SvREFCNT_dec((SV *)opts);
        if (!records) {
            ST(0) = sv_2mortal(newSViv(0));
            XSRETURN(1);
        }
        n = av_len(records) + 1;
        if (!has_pred) {
            matched = n;
        } else {
            for (i = 0; i < n; i++) {
                SV **rp = av_fetch(records, i, 0);
                SV *rec = (rp && *rp) ? *rp : &PL_sv_undef;
                if (file_call_predicate_cv(aTHX_ (CV *)SvRV(ST(1)), rec))
                    matched++;
            }
        }
        SvREFCNT_dec(holder);
        ST(0) = sv_2mortal(newSViv(matched));
        XSRETURN(1);
    }

    /* If no predicate, just count newlines - no SV creation needed */
    if (items == 1) {
        int fd;
        char *buffer;
        ssize_t n, total_read = 0;
        char *p, *end;
        char last_char = '\n';  /* Assume last char is newline (handles empty file) */
#ifdef _WIN32
        int open_flags = O_RDONLY | O_BINARY;
#else
        int open_flags = O_RDONLY;
#endif
        fd = open(path, open_flags);
        if (UNLIKELY(fd < 0)) {
            ST(0) = sv_2mortal(newSViv(0));
            XSRETURN(1);
        }

        Newx(buffer, FILE_BUFFER_SIZE, char);
        count = 0;

        while ((n = read(fd, buffer, FILE_BUFFER_SIZE)) > 0) {
            p = buffer;
            end = buffer + n;
            while ((p = memchr(p, '\n', end - p)) != NULL) {
                count++;
                p++;
            }
            total_read += n;
            last_char = buffer[n - 1];
        }
        close(fd);
        Safefree(buffer);

        /* If file doesn't end with newline, count the last line */
        if (total_read > 0 && last_char != '\n') {
            count++;
        }

        ST(0) = sv_2mortal(newSViv(count));
        XSRETURN(1);
    }

    predicate = ST(1);

    /* Check if predicate is a name or coderef */
    if (SvROK(predicate) && SvTYPE(SvRV(predicate)) == SVt_PVCV) {
        block_cv = (CV*)SvRV(predicate);
    } else {
        const char *name = SvPV_nolen(predicate);
        fcb = file_get_callback(aTHX_ name);
        if (!fcb) {
            croak("File::Raw::count_lines: unknown predicate '%s'", name);
        }
    }

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        ST(0) = sv_2mortal(newSViv(0));
        XSRETURN(1);
    }

    /* C predicate path - fastest */
    if (fcb && fcb->predicate) {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            if (fcb->predicate(aTHX_ line)) {
                count++;
            }
            SvREFCNT_dec(line);
        }
        file_lines_close(idx);
        ST(0) = sv_2mortal(newSViv(count));
        XSRETURN(1);
    }

    /* Call Perl callback */
    {
        SV *cb_sv = fcb ? fcb->perl_callback : (SV*)block_cv;
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV n;
            SV *result_sv;
            bool matches = FALSE;
            PUSHMARK(SP);
            XPUSHs(line);
            PUTBACK;
            n = call_sv(cb_sv, G_SCALAR);
            SPAGAIN;
            if (n > 0) {
                result_sv = POPs;
                matches = SvTRUE(result_sv);
            }
            PUTBACK;
            if (matches) {
                count++;
            }
            SvREFCNT_dec(line);
        }
    }

    file_lines_close(idx);
    ST(0) = sv_2mortal(newSViv(count));
    XSRETURN(1);
}

/* Find first line matching predicate */
XS_INTERNAL(xs_find_line) {
    dXSARGS;
    const char *path;
    SV *predicate;
    IV idx;
    SV *line;
    CV *block_cv = NULL;
    FileLineCallback *fcb = NULL;

    if (items < 2)
        croak("Usage: file::find_line(path, &predicate or $name [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));
    predicate = ST(1);

    if (items > 2) {
        HV *opts;
        SV *holder = NULL;
        AV *records;
        SSize_t i, n;

        if (!SvROK(predicate) || SvTYPE(SvRV(predicate)) != SVt_PVCV)
            croak("File::Raw::find_line: predicate must be a coderef when "
                  "a plugin is in use");

        opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "find_line");
        records = file_records_via_plugin(aTHX_ opts, path, &holder);
        SvREFCNT_dec((SV *)opts);
        if (!records) XSRETURN_UNDEF;

        n = av_len(records) + 1;
        for (i = 0; i < n; i++) {
            SV **rp = av_fetch(records, i, 0);
            SV *rec = (rp && *rp) ? *rp : &PL_sv_undef;
            if (file_call_predicate_cv(aTHX_ (CV *)SvRV(predicate), rec)) {
                SV *winner = newSVsv(rec);
                SvREFCNT_dec(holder);
                ST(0) = sv_2mortal(winner);
                XSRETURN(1);
            }
        }
        SvREFCNT_dec(holder);
        XSRETURN_UNDEF;
    }

    /* Check if predicate is a name or coderef */
    if (SvROK(predicate) && SvTYPE(SvRV(predicate)) == SVt_PVCV) {
        block_cv = (CV*)SvRV(predicate);
    } else {
        const char *name = SvPV_nolen(predicate);
        fcb = file_get_callback(aTHX_ name);
        if (!fcb) {
            croak("File::Raw::find_line: unknown predicate '%s'", name);
        }
    }

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        XSRETURN_UNDEF;
    }

    /* C predicate path - fastest */
    if (fcb && fcb->predicate) {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            if (fcb->predicate(aTHX_ line)) {
                file_lines_close(idx);
                ST(0) = sv_2mortal(line);
                XSRETURN(1);
            }
            SvREFCNT_dec(line);
        }
        file_lines_close(idx);
        XSRETURN_UNDEF;
    }

    /* Call Perl callback */
    {
        SV *cb_sv = fcb ? fcb->perl_callback : (SV*)block_cv;
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV n;
            SV *result_sv;
            bool matches = FALSE;
            PUSHMARK(SP);
            XPUSHs(line);
            PUTBACK;
            n = call_sv(cb_sv, G_SCALAR);
            SPAGAIN;
            if (n > 0) {
                result_sv = POPs;
                matches = SvTRUE(result_sv);
            }
            PUTBACK;
            if (matches) {
                file_lines_close(idx);
                ST(0) = sv_2mortal(line);
                XSRETURN(1);
            }
            SvREFCNT_dec(line);
        }
    }

    file_lines_close(idx);
    XSRETURN_UNDEF;
}

/* Map lines with callback */
XS_INTERNAL(xs_map_lines) {
    dXSARGS;
    const char *path;
    SV *callback;
    IV idx;
    SV *line;
    AV *result;
    if (items < 2)
        croak("Usage: file::map_lines(path, &callback [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));
    callback = ST(1);
    result = newAV();

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV) {
        croak("Second argument must be a code reference");
    }

    if (items > 2) {
        HV *opts;
        SV *holder = NULL;
        AV *records;
        SSize_t i, n;
        AV *out;

        SvREFCNT_dec((SV *)result);
        opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "map_lines");
        records = file_records_via_plugin(aTHX_ opts, path, &holder);
        SvREFCNT_dec((SV *)opts);
        if (!records) {
            ST(0) = sv_2mortal(newRV_noinc((SV *)newAV()));
            XSRETURN(1);
        }
        out = newAV();
        n = av_len(records) + 1;
        av_extend(out, n);
        for (i = 0; i < n; i++) {
            SV **rp = av_fetch(records, i, 0);
            SV *rec = (rp && *rp) ? *rp : &PL_sv_undef;
            int rn;
            SV *rv;
            dSP;
            PUSHMARK(SP);
            XPUSHs(rec);
            PUTBACK;
            rn = call_sv(callback, G_SCALAR);
            SPAGAIN;
            if (rn > 0) {
                rv = POPs;
                av_push(out, SvREFCNT_inc(rv));
            }
            PUTBACK;
        }
        SvREFCNT_dec(holder);
        ST(0) = sv_2mortal(newRV_noinc((SV *)out));
        XSRETURN(1);
    }

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
        XSRETURN(1);
    }

    /* Call Perl callback */
    {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV count;
            SV *result_sv;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(line));
            PUTBACK;
            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                result_sv = POPs;
                av_push(result, SvREFCNT_inc(result_sv));
            }
            PUTBACK;
        }
    }

    file_lines_close(idx);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* ============================================
   Perl bridge for the plugin API.

   Perl plugins are registered as a hashref of phase coderefs:

       File::Raw::register_plugin('csv', {
           read   => sub { my ($path, $bytes,  $opts) = @_; ... },
           write  => sub { my ($path, $rows,   $opts) = @_; ... },
           record => sub { my ($path, $record, $opts) = @_; ... },
       });

   The bridge allocates a PerlPluginBridge holding the coderef SVs plus
   a FilePlugin block whose function pointers are static C thunks. The
   thunks recover the bridge from FilePluginContext::plugin_state and
   call the appropriate coderef. The bridge is pinned in
   g_perl_plugins so we can free it on unregister.

   The 'stream' phase is intentionally not supported from Perl: a Perl
   stream plugin would be invoked once per chunk by file.c's read loop,
   and the per-call call_sv overhead defeats the point of streaming.
   Perl plugins that need record-by-record callbacks should implement
   the 'record' phase instead - File::Raw drives the iteration.
   ============================================ */

typedef struct PerlPluginBridge {
    char        *name;     /* strdup'd; pointer is stored in plugin.name */
    SV          *read_cv;
    SV          *write_cv;
    SV          *record_cv;
    FilePlugin   plugin;
} PerlPluginBridge;

static HV *g_perl_plugins = NULL;

static void perl_plugin_bridge_free(pTHX_ PerlPluginBridge *b) {
    if (!b) return;
    if (b->read_cv)   SvREFCNT_dec(b->read_cv);
    if (b->write_cv)  SvREFCNT_dec(b->write_cv);
    if (b->record_cv) SvREFCNT_dec(b->record_cv);
    if (b->name)      Safefree(b->name);
    Safefree(b);
}

static SV *perl_plugin_thunk_read(pTHX_ FilePluginContext *ctx) {
    PerlPluginBridge *b = (PerlPluginBridge *)ctx->plugin_state;
    SV *result;
    int count;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(ctx->path ? ctx->path : "", 0)));
    XPUSHs(sv_2mortal(newSVsv(ctx->data)));
    XPUSHs(sv_2mortal(newRV_inc((SV *)ctx->options)));
    PUTBACK;

    count = call_sv(b->read_cv, G_SCALAR | G_EVAL);

    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *err = newSVsv(ERRSV);
        FREETMPS;
        LEAVE;
        croak_sv(err);
    }
    if (count > 0) {
        SV *ret = POPs;
        if (SvOK(ret)) {
            result = newSVsv(ret);
        } else {
            ctx->cancel = 1;
            result = NULL;
        }
    } else {
        ctx->cancel = 1;
        result = NULL;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

static SV *perl_plugin_thunk_write(pTHX_ FilePluginContext *ctx) {
    PerlPluginBridge *b = (PerlPluginBridge *)ctx->plugin_state;
    SV *result;
    int count;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(ctx->path ? ctx->path : "", 0)));
    XPUSHs(sv_2mortal(newSVsv(ctx->data)));
    XPUSHs(sv_2mortal(newRV_inc((SV *)ctx->options)));
    PUTBACK;

    count = call_sv(b->write_cv, G_SCALAR | G_EVAL);

    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *err = newSVsv(ERRSV);
        FREETMPS;
        LEAVE;
        croak_sv(err);
    }
    if (count > 0) {
        SV *ret = POPs;
        if (SvOK(ret)) {
            result = newSVsv(ret);
        } else {
            ctx->cancel = 1;
            result = NULL;
        }
    } else {
        ctx->cancel = 1;
        result = NULL;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

static SV *perl_plugin_thunk_record(pTHX_ FilePluginContext *ctx, SV *record) {
    PerlPluginBridge *b = (PerlPluginBridge *)ctx->plugin_state;
    SV *result;
    int count;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(ctx->path ? ctx->path : "", 0)));
    XPUSHs(sv_2mortal(newSVsv(record)));
    XPUSHs(sv_2mortal(newRV_inc((SV *)ctx->options)));
    PUTBACK;

    count = call_sv(b->record_cv, G_SCALAR | G_EVAL);

    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *err = newSVsv(ERRSV);
        FREETMPS;
        LEAVE;
        croak_sv(err);
    }
    if (count > 0) {
        SV *ret = POPs;
        if (SvOK(ret)) {
            result = newSVsv(ret);
        } else {
            result = &PL_sv_undef;  /* exclude */
        }
    } else {
        result = &PL_sv_undef;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

/* ============================================
   Built-in 'predicate' plugin.

   Records flow through plugin->record_fn(), which looks up a predicate by
   name in g_file_callback_registry. The record fn returns the record SV
   when the predicate matches, or &PL_sv_undef when it does not -
   callers (grep/count/find) interpret this via truthiness.

   The 'name' option is required:

       File::Raw::grep_lines($p, plugin => 'predicate', name => 'is_blank');

   Predicates registered as Perl coderefs are invoked with the record in
   $_; the same convention as grep_lines's per-record callbacks.
   ============================================ */

static SV *predicate_plugin_record(pTHX_ FilePluginContext *ctx, SV *record) {
    SV **svp;
    const char *pred_name;
    STRLEN pred_name_len;
    FileLineCallback *cb;

    svp = hv_fetchs(ctx->options, "name", 0);
    if (!svp || !*svp || !SvOK(*svp))
        croak("File::Raw plugin 'predicate': missing 'name' option");
    pred_name = SvPV(*svp, pred_name_len);

    if (!g_file_callback_registry)
        file_init_callback_registry(aTHX);

    svp = hv_fetch(g_file_callback_registry, pred_name, pred_name_len, 0);
    if (!svp || !*svp)
        croak("File::Raw plugin 'predicate': unknown predicate '%s'", pred_name);
    cb = INT2PTR(FileLineCallback *, SvIV(*svp));

    if (cb->predicate) {
        return cb->predicate(aTHX_ record) ? record : &PL_sv_undef;
    } else if (cb->perl_callback) {
        SV *old_defsv = DEFSV;
        SV *result_sv;
        int count;
        bool matched = FALSE;
        dSP;

        DEFSV = record;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = call_sv(cb->perl_callback, G_SCALAR);
        SPAGAIN;
        if (count > 0) {
            result_sv = POPs;
            matched = SvTRUE(result_sv);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        DEFSV = old_defsv;
        return matched ? record : &PL_sv_undef;
    }
    return &PL_sv_undef;
}

static FilePlugin g_predicate_plugin = {
    "predicate",
    NULL,                       /* read   */
    NULL,                       /* write  */
    predicate_plugin_record,    /* record */
    NULL,                       /* stream */
    NULL                        /* state - the global registry is consulted directly */
};

/* Public XSUBs for the predicate registry that backs the 'predicate'
 * plugin. Adding here also makes the entry visible to the legacy 2-arg
 * grep_lines($p, $name) sugar, which looks names up in the same HV. */

XS_INTERNAL(xs_register_predicate) {
    dXSARGS;
    const char *name;
    STRLEN name_len;
    SV *coderef;
    FileLineCallback *cb;
    FileLineCallback *existing;
    SV *sv;

    if (items != 2)
        croak("Usage: File::Raw::register_predicate($name, \\&coderef)");

    name = SvPV(ST(0), name_len);
    coderef = ST(1);

    if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV)
        croak("File::Raw::register_predicate: second arg must be a coderef");

    file_init_callback_registry(aTHX);

    existing = file_get_callback(aTHX_ name);
    if (existing) {
        if (existing->perl_callback) SvREFCNT_dec(existing->perl_callback);
        existing->perl_callback = newSVsv(coderef);
        existing->predicate = NULL;
        XSRETURN_YES;
    }

    Newxz(cb, 1, FileLineCallback);
    cb->predicate = NULL;
    cb->perl_callback = newSVsv(coderef);
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, name, name_len, sv, 0);

    XSRETURN_YES;
}

XS_INTERNAL(xs_list_predicates) {
    dXSARGS;
    AV *result = newAV();
    HE *he;

    PERL_UNUSED_VAR(items);

    if (g_file_callback_registry) {
        hv_iterinit(g_file_callback_registry);
        while ((he = hv_iternext(g_file_callback_registry))) {
            I32 klen;
            const char *kname = hv_iterkey(he, &klen);
            av_push(result, newSVpvn(kname, klen));
        }
    }

    ST(0) = sv_2mortal(newRV_noinc((SV *)result));
    XSRETURN(1);
}

XS_INTERNAL(xs_register_plugin) {
    dXSARGS;
    const char *name;
    STRLEN name_len;
    SV *spec;
    HV *spec_hv;
    SV **svp;
    PerlPluginBridge *b;
    int rc;
    int override = 0;

    if (items < 2 || items > 3)
        croak("Usage: File::Raw::register_plugin($name, \\%%phases [, $override])");

    name = SvPV(ST(0), name_len);
    if (name_len == 0)
        croak("File::Raw::register_plugin: name must be non-empty");

    spec = ST(1);
    if (!SvROK(spec) || SvTYPE(SvRV(spec)) != SVt_PVHV)
        croak("File::Raw::register_plugin: second arg must be a hashref");
    spec_hv = (HV *)SvRV(spec);

    if (items == 3) override = SvTRUE(ST(2));

    if (override) (void)file_unregister_plugin(aTHX_ name);

    Newxz(b, 1, PerlPluginBridge);
    b->name = savepv(name);

    svp = hv_fetchs(spec_hv, "read", 0);
    if (svp && *svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
        b->read_cv = newSVsv(*svp);
        b->plugin.read_fn = perl_plugin_thunk_read;
    }
    svp = hv_fetchs(spec_hv, "write", 0);
    if (svp && *svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
        b->write_cv = newSVsv(*svp);
        b->plugin.write_fn = perl_plugin_thunk_write;
    }
    svp = hv_fetchs(spec_hv, "record", 0);
    if (svp && *svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVCV) {
        b->record_cv = newSVsv(*svp);
        b->plugin.record_fn = perl_plugin_thunk_record;
    }
    /* hv_existss is 5.36+. Use hv_exists for portability. */
    if (hv_exists(spec_hv, "stream", 6))
        croak("File::Raw::register_plugin: 'stream' phase not supported "
              "from Perl - implement 'record' instead, or write a C plugin");

    if (!b->plugin.read_fn && !b->plugin.write_fn && !b->plugin.record_fn) {
        perl_plugin_bridge_free(aTHX_ b);
        croak("File::Raw::register_plugin: at least one of read/write/record "
              "must be a coderef");
    }

    b->plugin.name  = b->name;
    b->plugin.state = b;

    rc = file_register_plugin(aTHX_ &b->plugin);
    if (rc != 1) {
        perl_plugin_bridge_free(aTHX_ b);
        if (rc == 0)
            croak("File::Raw::register_plugin: plugin '%s' is already registered",
                  name);
        croak("File::Raw::register_plugin: invalid plugin spec for '%s'", name);
    }

    if (!g_perl_plugins) g_perl_plugins = newHV();
    hv_store(g_perl_plugins, name, name_len, newSViv(PTR2IV(b)), 0);

    XSRETURN_YES;
}

XS_INTERNAL(xs_unregister_plugin) {
    dXSARGS;
    const char *name;
    STRLEN name_len;
    SV **svp;
    int removed_perl = 0;

    if (items != 1)
        croak("Usage: File::Raw::unregister_plugin($name)");

    name = SvPV(ST(0), name_len);

    if (g_perl_plugins) {
        svp = hv_fetch(g_perl_plugins, name, name_len, 0);
        if (svp && *svp) {
            PerlPluginBridge *b = INT2PTR(PerlPluginBridge *, SvIV(*svp));
            (void)hv_delete(g_perl_plugins, name, name_len, G_DISCARD);
            (void)file_unregister_plugin(aTHX_ name);
            perl_plugin_bridge_free(aTHX_ b);
            removed_perl = 1;
        }
    }
    if (!removed_perl)
        (void)file_unregister_plugin(aTHX_ name);

    XSRETURN_YES;
}

XS_INTERNAL(xs_list_plugins) {
    dXSARGS;
    AV *result = newAV();
    HE *he;

    PERL_UNUSED_VAR(items);

    if (g_file_plugin_registry) {
        hv_iterinit(g_file_plugin_registry);
        while ((he = hv_iternext(g_file_plugin_registry))) {
            I32 klen;
            const char *kname = hv_iterkey(he, &klen);
            av_push(result, newSVpvn(kname, klen));
        }
    }

    ST(0) = sv_2mortal(newRV_noinc((SV *)result));
    XSRETURN(1);
}

/* New stat functions */
XS_INTERNAL(xs_atime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::atime(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_atime_internal(path)));
    XSRETURN(1);
}

XS_INTERNAL(xs_ctime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::ctime(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_ctime_internal(path)));
    XSRETURN(1);
}

XS_INTERNAL(xs_mode) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::mode(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_mode_internal(path)));
    XSRETURN(1);
}

/* Combined stat - all attributes in one syscall */
XS_INTERNAL(xs_stat_all) {
    dXSARGS;
    const char *path;
    HV *result;
    if (items != 1) croak("Usage: File::Raw::stat(path)");
    path = SvPV_nolen(ST(0));
    result = file_stat_all_internal(aTHX_ path);
    if (result == NULL) {
        ST(0) = &PL_sv_undef;
    } else {
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    }
    XSRETURN(1);
}

XS_INTERNAL(xs_is_link) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::is_link(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_link_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_is_executable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::is_executable(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_executable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* File manipulation functions */
XS_INTERNAL(xs_unlink) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::unlink(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_unlink_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_copy) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file::copy(src, dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_copy_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_move) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file::move(src, dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_move_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_touch) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::touch(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_touch_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_clear_stat_cache) {
    dXSARGS;
    if (items > 1) croak("Usage: file::clear_stat_cache() or file::clear_stat_cache(path)");
    
    if (items == 1 && SvOK(ST(0))) {
        const char *path = SvPV_nolen(ST(0));
        invalidate_stat_cache_path(path);
    } else {
        invalidate_stat_cache();
    }
    
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

XS_INTERNAL(xs_chmod) {
    dXSARGS;
    const char *path;
    int mode;
    if (items != 2) croak("Usage: file::chmod(path, mode)");
    path = SvPV_nolen(ST(0));
    mode = SvIV(ST(1));
    ST(0) = file_chmod_internal(path, mode) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_mkdir) {
    dXSARGS;
    const char *path;
    int mode = 0755;
    if (items < 1 || items > 2) croak("Usage: file::mkdir(path, [mode])");
    path = SvPV_nolen(ST(0));
    if (items > 1) mode = SvIV(ST(1));
    ST(0) = file_mkdir_internal(path, mode) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_rmdir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::rmdir(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_rmdir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(xs_readdir) {
    dXSARGS;
    const char *path;
    AV *result;
    if (items != 1) croak("Usage: file::readdir(path)");
    path = SvPV_nolen(ST(0));
    result = file_readdir_internal(aTHX_ path);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* Path manipulation functions */
XS_INTERNAL(xs_basename) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::basename(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_basename_internal(aTHX_ path));
    XSRETURN(1);
}

XS_INTERNAL(xs_dirname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::dirname(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_dirname_internal(aTHX_ path));
    XSRETURN(1);
}

XS_INTERNAL(xs_extname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::extname(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_extname_internal(aTHX_ path));
    XSRETURN(1);
}

XS_INTERNAL(xs_join) {
    dXSARGS;
    AV *parts;
    SSize_t i;

    if (items < 1) croak("Usage: file::join(part1, part2, ...)");

    parts = newAV();
    for (i = 0; i < items; i++) {
        av_push(parts, newSVsv(ST(i)));
    }

    ST(0) = sv_2mortal(file_join_internal(aTHX_ parts));
    SvREFCNT_dec((SV*)parts);
    XSRETURN(1);
}

/* mkpath: recursive mkdir */
XS_INTERNAL(xs_mkpath) {
    dXSARGS;
    const char *path;
    STRLEN path_len;
    char buf[4096];
    STRLEN i;
    int created = 0;

    if (items != 1) croak("Usage: file_mkpath(path)");
    path = SvPV(ST(0), path_len);
    if (path_len >= sizeof(buf)) croak("Path too long");

    for (i = 0; i <= path_len; i++) {
        if (i == path_len || path[i] == '/' || path[i] == '\\') {
            if (i == 0) {
                /* Root / or drive-relative */
                buf[0] = path[0];
                buf[1] = '\0';
                continue;
            }
            memcpy(buf, path, i);
            buf[i] = '\0';

            /* Skip drive letter portion like C: */
            if (i == 2 && buf[1] == ':') continue;

            if (!file_is_dir_internal(buf)) {
                if (file_mkdir_internal(buf, 0755))
                    created = 1;
            }
        }
    }

    ST(0) = created || file_is_dir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* rm_rf: recursive remove directory */
static void file_rm_rf_internal(pTHX_ const char *path) {
    AV *entries;
    SSize_t i, len;

    if (!file_is_dir_internal(path)) {
        file_unlink_internal(path);
        return;
    }

    entries = file_readdir_internal(aTHX_ path);
    len = av_len(entries) + 1;
    for (i = 0; i < len; i++) {
        SV **sv = av_fetch(entries, i, 0);
        if (sv) {
            AV *join_parts = newAV();
            SV *child_sv;
            const char *child;

            av_push(join_parts, newSVpv(path, 0));
            av_push(join_parts, newSVsv(*sv));
            child_sv = file_join_internal(aTHX_ join_parts);
            child = SvPV_nolen(child_sv);

            if (file_is_dir_internal(child)) {
                file_rm_rf_internal(aTHX_ child);
            } else {
                file_unlink_internal(child);
            }

            SvREFCNT_dec(child_sv);
            SvREFCNT_dec((SV*)join_parts);
        }
    }
    SvREFCNT_dec((SV*)entries);
    file_rmdir_internal(path);
}

XS_INTERNAL(xs_rm_rf) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file_rm_rf(path)");
    path = SvPV_nolen(ST(0));
    file_rm_rf_internal(aTHX_ path);
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

/* Head and tail */
/* head/tail share an arg-parsing convention: even items means $n is at
 * ST(1) and the plugin tail (if any) begins at ST(2); odd items means
 * $n is omitted and the plugin tail begins at ST(1). This avoids the
 * ambiguity of "is ST(1) a count or the first option key?". */
XS_INTERNAL(xs_head) {
    dXSARGS;
    const char *path;
    AV *result;
    IV n = 10;
    int n_positional;

    if (items < 1)
        croak("Usage: file::head(path [, n] [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));
    n_positional = (items % 2 == 0) ? 2 : 1;
    if (n_positional == 2) n = SvIV(ST(1));

    if (items > n_positional) {
        HV *opts;
        SV *holder = NULL;
        AV *records;
        AV *out;
        SSize_t i, total, take;

        opts = file_plugin_build_opts(aTHX_ &ST(0), n_positional, items, "head");
        records = file_records_via_plugin(aTHX_ opts, path, &holder);
        SvREFCNT_dec((SV *)opts);
        if (!records) {
            ST(0) = sv_2mortal(newRV_noinc((SV *)newAV()));
            XSRETURN(1);
        }
        out = newAV();
        total = av_len(records) + 1;
        take = (n < (IV)total) ? n : total;
        if (take < 0) take = 0;
        av_extend(out, take);
        for (i = 0; i < take; i++) {
            SV **rp = av_fetch(records, i, 0);
            av_push(out, SvREFCNT_inc(rp && *rp ? *rp : &PL_sv_undef));
        }
        SvREFCNT_dec(holder);
        ST(0) = sv_2mortal(newRV_noinc((SV *)out));
        XSRETURN(1);
    }

    result = file_head_internal(aTHX_ path, n);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

XS_INTERNAL(xs_tail) {
    dXSARGS;
    const char *path;
    AV *result;
    IV n = 10;
    int n_positional;

    if (items < 1)
        croak("Usage: file::tail(path [, n] [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));
    n_positional = (items % 2 == 0) ? 2 : 1;
    if (n_positional == 2) n = SvIV(ST(1));

    if (items > n_positional) {
        HV *opts;
        SV *holder = NULL;
        AV *records;
        AV *out;
        SSize_t i, total, start, take;

        opts = file_plugin_build_opts(aTHX_ &ST(0), n_positional, items, "tail");
        records = file_records_via_plugin(aTHX_ opts, path, &holder);
        SvREFCNT_dec((SV *)opts);
        if (!records) {
            ST(0) = sv_2mortal(newRV_noinc((SV *)newAV()));
            XSRETURN(1);
        }
        out = newAV();
        total = av_len(records) + 1;
        take  = (n < (IV)total) ? n : total;
        if (take < 0) take = 0;
        start = total - take;
        av_extend(out, take);
        for (i = start; i < total; i++) {
            SV **rp = av_fetch(records, i, 0);
            av_push(out, SvREFCNT_inc(rp && *rp ? *rp : &PL_sv_undef));
        }
        SvREFCNT_dec(holder);
        ST(0) = sv_2mortal(newRV_noinc((SV *)out));
        XSRETURN(1);
    }

    result = file_tail_internal(aTHX_ path, n);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* range_lines(path, from, count [, plugin => ..., key => value ...])
 *
 * 1-based, half-open in count style: range_lines($p, 5, 3) returns
 * lines 5, 6, 7 (or fewer if EOF arrives first). Symmetric with
 * head/tail in shape and plugin behaviour. */
XS_INTERNAL(xs_range_lines) {
    dXSARGS;
    const char *path;
    IV from, count;
    AV *result;

    if (items < 3)
        croak("Usage: file::range_lines(path, from, count "
              "[, plugin => ..., key => value ...])");

    path  = SvPV_nolen(ST(0));
    from  = SvIV(ST(1));
    count = SvIV(ST(2));

    /* Plugin path: slice the plugin's record AoA. Same eager trade-off
     * as head/tail/lines under a plugin tail. */
    if (items > 3) {
        HV *opts;
        SV *holder = NULL;
        AV *records;
        AV *out;
        SSize_t i, total, start, end;

        opts = file_plugin_build_opts(aTHX_ &ST(0), 3, items, "range_lines");
        records = file_records_via_plugin(aTHX_ opts, path, &holder);
        SvREFCNT_dec((SV *)opts);
        if (!records) {
            ST(0) = sv_2mortal(newRV_noinc((SV *)newAV()));
            XSRETURN(1);
        }
        out = newAV();
        if (from < 1 || count <= 0) {
            SvREFCNT_dec(holder);
            ST(0) = sv_2mortal(newRV_noinc((SV *)out));
            XSRETURN(1);
        }
        total = av_len(records) + 1;
        start = from - 1;            /* 1-based -> 0-based */
        if (start >= total) {
            SvREFCNT_dec(holder);
            ST(0) = sv_2mortal(newRV_noinc((SV *)out));
            XSRETURN(1);
        }
        end = start + count;
        if (end > total) end = total;
        av_extend(out, end - start - 1);
        for (i = start; i < end; i++) {
            SV **rp = av_fetch(records, i, 0);
            av_push(out, SvREFCNT_inc(rp && *rp ? *rp : &PL_sv_undef));
        }
        SvREFCNT_dec(holder);
        ST(0) = sv_2mortal(newRV_noinc((SV *)out));
        XSRETURN(1);
    }

    result = file_range_internal(aTHX_ path, from, count);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* Atomic spew */
XS_INTERNAL(xs_atomic_spew) {
    dXSARGS;
    const char *path;
    SV *payload;
    SV *bytes_to_write = NULL;

    if (items < 2)
        croak("Usage: file::atomic_spew(path, data [, plugin => ..., key => value ...])");

    path    = SvPV_nolen(ST(0));
    payload = ST(1);

    if (items > 2) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "atomic_spew");
        bytes_to_write = file_plugin_dispatch_write(aTHX_ opts, path, payload);
        SvREFCNT_dec((SV *)opts);
        if (!bytes_to_write) {
            ST(0) = &PL_sv_no;
            XSRETURN(1);
        }
        payload = sv_2mortal(bytes_to_write);
    }

    ST(0) = file_atomic_spew_internal(aTHX_ path, payload) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* ============================================
   Function-style XS (for import)
   ============================================ */

XS_EXTERNAL(XS_file_func_slurp) {
    dXSARGS;
    const char *path;
    SV *bytes;

    if (items < 1)
        croak("Usage: file_slurp($path [, plugin => ..., key => value ...])");

    path  = SvPV_nolen(ST(0));
    bytes = file_slurp_internal(aTHX_ path);

    if (items > 1) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 1, items, "slurp");
        SV *out  = file_plugin_dispatch_read(aTHX_ opts, path, bytes);
        SvREFCNT_dec((SV *)opts);
        if (!out) {
            SvREFCNT_dec(bytes);
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }
        if (out != bytes) {
            SvREFCNT_dec(bytes);
            bytes = out;
        }
    }
    ST(0) = sv_2mortal(bytes);
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_spew) {
    dXSARGS;
    const char *path;
    SV *payload;

    if (items < 2)
        croak("Usage: file_spew($path, $data [, plugin => ..., key => value ...])");

    path    = SvPV_nolen(ST(0));
    payload = ST(1);

    if (items > 2) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "spew");
        SV *out  = file_plugin_dispatch_write(aTHX_ opts, path, payload);
        SvREFCNT_dec((SV *)opts);
        if (!out) { ST(0) = &PL_sv_no; XSRETURN(1); }
        payload = sv_2mortal(out);
    }
    ST(0) = file_spew_internal(aTHX_ path, payload) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_exists) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_exists($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_exists_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_size) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_size($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_size_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_file) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_file($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_file_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_dir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_dir($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_dir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_lines) {
    dXSARGS;
    const char *path;
    SV *content;
    AV *lines;

    if (items < 1)
        croak("Usage: file_lines($path [, plugin => ..., key => value ...])");

    path = SvPV_nolen(ST(0));

    if (items > 1) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 1, items, "lines");
        SV *bytes = file_slurp_internal(aTHX_ path);
        SV *out   = file_plugin_dispatch_read(aTHX_ opts, path, bytes);
        SvREFCNT_dec((SV *)opts);
        if (!out) {
            SvREFCNT_dec(bytes);
            ST(0) = sv_2mortal(newRV_noinc((SV *)newAV()));
            XSRETURN(1);
        }
        if (out != bytes) SvREFCNT_dec(bytes);
        if (SvROK(out) && SvTYPE(SvRV(out)) == SVt_PVAV) {
            ST(0) = sv_2mortal(out);
            XSRETURN(1);
        }
        lines = file_split_lines(aTHX_ out);
        SvREFCNT_dec(out);
        ST(0) = sv_2mortal(newRV_noinc((SV *)lines));
        XSRETURN(1);
    }

    content = file_slurp_internal(aTHX_ path);
    if (content == &PL_sv_undef) {
        lines = newAV();
    } else {
        lines = file_split_lines(aTHX_ content);
        SvREFCNT_dec(content);
    }
    ST(0) = sv_2mortal(newRV_noinc((SV*)lines));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_unlink) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_unlink($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_unlink_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_mkdir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_mkdir($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_mkdir_internal(path, 0755) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_rmdir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_rmdir($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_rmdir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_touch) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_touch($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_touch_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_clear_stat_cache) {
    dXSARGS;
    if (items > 1) croak("Usage: file_clear_stat_cache() or file_clear_stat_cache($path)");
    
    if (items == 1 && SvOK(ST(0))) {
        const char *path = SvPV_nolen(ST(0));
        invalidate_stat_cache_path(path);
    } else {
        invalidate_stat_cache();
    }
    
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_basename) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_basename($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_basename_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_dirname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_dirname($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_dirname_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_extname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_extname($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_extname_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_mtime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_mtime($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_mtime_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_atime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_atime($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_atime_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_ctime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_ctime($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_ctime_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_mode) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_mode($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_mode_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_link) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_link($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_link_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_readable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_readable($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_readable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_writable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_writable($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_writable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_executable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_executable($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_executable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_readdir) {
    dXSARGS;
    const char *path;
    AV *result;
    if (items != 1) croak("Usage: file_readdir($path)");
    path = SvPV_nolen(ST(0));
    result = file_readdir_internal(aTHX_ path);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_slurp_raw) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_slurp_raw($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_slurp_raw_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_copy) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file_copy($src, $dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_copy_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_move) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file_move($src, $dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_move_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_chmod) {
    dXSARGS;
    const char *path;
    int mode;
    if (items != 2) croak("Usage: file_chmod($path, $mode)");
    path = SvPV_nolen(ST(0));
    mode = SvIV(ST(1));
    ST(0) = file_chmod_internal(path, mode) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_append) {
    dXSARGS;
    const char *path;
    SV *payload;

    if (items < 2)
        croak("Usage: file_append($path, $data [, plugin => ..., key => value ...])");

    path    = SvPV_nolen(ST(0));
    payload = ST(1);

    if (items > 2) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "append");
        SV *out  = file_plugin_dispatch_write(aTHX_ opts, path, payload);
        SvREFCNT_dec((SV *)opts);
        if (!out) { ST(0) = &PL_sv_no; XSRETURN(1); }
        payload = sv_2mortal(out);
    }
    ST(0) = file_append_internal(aTHX_ path, payload) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_atomic_spew) {
    dXSARGS;
    const char *path;
    SV *payload;

    if (items < 2)
        croak("Usage: file_atomic_spew($path, $data [, plugin => ..., key => value ...])");

    path    = SvPV_nolen(ST(0));
    payload = ST(1);

    if (items > 2) {
        HV *opts = file_plugin_build_opts(aTHX_ &ST(0), 2, items, "atomic_spew");
        SV *out  = file_plugin_dispatch_write(aTHX_ opts, path, payload);
        SvREFCNT_dec((SV *)opts);
        if (!out) { ST(0) = &PL_sv_no; XSRETURN(1); }
        payload = sv_2mortal(out);
    }
    ST(0) = file_atomic_spew_internal(aTHX_ path, payload) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* Function entry for selective import */
typedef struct {
    const char *name;       /* Name without file_ prefix (e.g., "slurp") */
    int args;               /* 1 or 2 arguments */
    void (*xs_func)(pTHX_ CV*);
    Perl_ppaddr_t pp_func;
} ImportEntry;

static const ImportEntry import_funcs[] = {
    /* 1-arg functions */
    {"slurp", 1, XS_file_func_slurp, pp_file_slurp},
    {"slurp_raw", 1, XS_file_func_slurp_raw, pp_file_slurp_raw},
    {"exists", 1, XS_file_func_exists, pp_file_exists},
    {"size", 1, XS_file_func_size, pp_file_size},
    {"is_file", 1, XS_file_func_is_file, pp_file_is_file},
    {"is_dir", 1, XS_file_func_is_dir, pp_file_is_dir},
    {"lines", 1, XS_file_func_lines, pp_file_lines},
    {"unlink", 1, XS_file_func_unlink, pp_file_unlink},
    {"mkdir", 1, XS_file_func_mkdir, pp_file_mkdir},
    {"rmdir", 1, XS_file_func_rmdir, pp_file_rmdir},
    {"touch", 1, XS_file_func_touch, pp_file_touch},
    {"clear_stat_cache", 1, XS_file_func_clear_stat_cache, pp_file_clear_stat_cache},
    {"basename", 1, XS_file_func_basename, pp_file_basename},
    {"dirname", 1, XS_file_func_dirname, pp_file_dirname},
    {"extname", 1, XS_file_func_extname, pp_file_extname},
    {"mtime", 1, XS_file_func_mtime, pp_file_mtime},
    {"atime", 1, XS_file_func_atime, pp_file_atime},
    {"ctime", 1, XS_file_func_ctime, pp_file_ctime},
    {"mode", 1, XS_file_func_mode, pp_file_mode},
    {"is_link", 1, XS_file_func_is_link, pp_file_is_link},
    {"is_readable", 1, XS_file_func_is_readable, pp_file_is_readable},
    {"is_writable", 1, XS_file_func_is_writable, pp_file_is_writable},
    {"is_executable", 1, XS_file_func_is_executable, pp_file_is_executable},
    {"readdir", 1, XS_file_func_readdir, pp_file_readdir},
    /* 2-arg functions */
    {"spew", 2, XS_file_func_spew, pp_file_spew},
    {"copy", 2, XS_file_func_copy, pp_file_copy},
    {"move", 2, XS_file_func_move, pp_file_move},
    {"chmod", 2, XS_file_func_chmod, pp_file_chmod},
    {"append", 2, XS_file_func_append, pp_file_append},
    {"atomic_spew", 2, XS_file_func_atomic_spew, pp_file_atomic_spew},
    /* variadic functions (args=0 means plain newXS, no custom op) */
    {"join", 0, xs_join, NULL},
    {"mkpath", 0, xs_mkpath, NULL},
    {"rm_rf", 0, xs_rm_rf, NULL},
    {"range_lines", 0, xs_range_lines, NULL},
    {NULL, 0, NULL, NULL}
};

#define IMPORT_FUNCS_COUNT (sizeof(import_funcs) / sizeof(import_funcs[0]) - 1)

static void install_import_entry(pTHX_ const char *pkg, const ImportEntry *e) {
    char short_name[256];
    snprintf(short_name, sizeof(short_name), "file_%s", e->name);
    if (e->args == 0) {
        /* Variadic: plain newXS, no custom op */
        char full_name[256];
        snprintf(full_name, sizeof(full_name), "%s::%s", pkg, short_name);
        newXS(full_name, e->xs_func, __FILE__);
    } else if (e->args == 1) {
        install_file_func_1arg(aTHX_ pkg, short_name, e->xs_func, e->pp_func);
    } else {
        install_file_func_2arg(aTHX_ pkg, short_name, e->xs_func, e->pp_func);
    }
}

static void install_all_imports(pTHX_ const char *pkg) {
    int i;
    for (i = 0; import_funcs[i].name != NULL; i++) {
        install_import_entry(aTHX_ pkg, &import_funcs[i]);
    }
}

/* file::import - import function-style accessors with custom ops */
XS_EXTERNAL(XS_file_import) {
    dXSARGS;
    const char *pkg;
    int i, j;

    /* Get caller's package */
    pkg = CopSTASHPV(PL_curcop);

    /* No args after package name = no imports */
    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    /* Process each requested import */
    for (i = 1; i < items; i++) {
        STRLEN len;
        const char *arg = SvPV(ST(i), len);

        /* Check for :all or import (both mean import everything) */
        if ((len == 4 && strEQ(arg, ":all")) ||
            (len == 6 && strEQ(arg, "import"))) {
            install_all_imports(aTHX_ pkg);
            XSRETURN_EMPTY;  /* :all means we're done */
        }

        /* Look up the requested function */
        for (j = 0; import_funcs[j].name != NULL; j++) {
            if (strEQ(arg, import_funcs[j].name)) {
                install_import_entry(aTHX_ pkg, &import_funcs[j]);
                break;
            }
        }

        /* If not found, warn but don't die */
        if (import_funcs[j].name == NULL) {
            warn("File::Raw: '%s' is not exported", arg);
        }
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Boot
   ============================================ */

XS_EXTERNAL(boot_File__Raw) {
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);

    file_init(aTHX);

    /* Register custom ops */
    XopENTRY_set(&file_slurp_xop, xop_name, "file_slurp");
    XopENTRY_set(&file_slurp_xop, xop_desc, "file slurp");
    XopENTRY_set(&file_slurp_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_slurp, &file_slurp_xop);

    XopENTRY_set(&file_spew_xop, xop_name, "file_spew");
    XopENTRY_set(&file_spew_xop, xop_desc, "file spew");
    XopENTRY_set(&file_spew_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_spew, &file_spew_xop);

    XopENTRY_set(&file_exists_xop, xop_name, "file_exists");
    XopENTRY_set(&file_exists_xop, xop_desc, "file exists");
    XopENTRY_set(&file_exists_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_exists, &file_exists_xop);

    XopENTRY_set(&file_size_xop, xop_name, "file_size");
    XopENTRY_set(&file_size_xop, xop_desc, "file size");
    XopENTRY_set(&file_size_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_size, &file_size_xop);

    XopENTRY_set(&file_is_file_xop, xop_name, "file_is_file");
    XopENTRY_set(&file_is_file_xop, xop_desc, "file is_file");
    XopENTRY_set(&file_is_file_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_file, &file_is_file_xop);

    XopENTRY_set(&file_is_dir_xop, xop_name, "file_is_dir");
    XopENTRY_set(&file_is_dir_xop, xop_desc, "file is_dir");
    XopENTRY_set(&file_is_dir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_dir, &file_is_dir_xop);

    XopENTRY_set(&file_lines_xop, xop_name, "file_lines");
    XopENTRY_set(&file_lines_xop, xop_desc, "file lines");
    XopENTRY_set(&file_lines_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_lines, &file_lines_xop);

    XopENTRY_set(&file_unlink_xop, xop_name, "file_unlink");
    XopENTRY_set(&file_unlink_xop, xop_desc, "file unlink");
    XopENTRY_set(&file_unlink_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_unlink, &file_unlink_xop);

    XopENTRY_set(&file_mkdir_xop, xop_name, "file_mkdir");
    XopENTRY_set(&file_mkdir_xop, xop_desc, "file mkdir");
    XopENTRY_set(&file_mkdir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_mkdir, &file_mkdir_xop);

    XopENTRY_set(&file_rmdir_xop, xop_name, "file_rmdir");
    XopENTRY_set(&file_rmdir_xop, xop_desc, "file rmdir");
    XopENTRY_set(&file_rmdir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_rmdir, &file_rmdir_xop);

    XopENTRY_set(&file_touch_xop, xop_name, "file_touch");
    XopENTRY_set(&file_touch_xop, xop_desc, "file touch");
    XopENTRY_set(&file_touch_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_touch, &file_touch_xop);

    XopENTRY_set(&file_clear_stat_cache_xop, xop_name, "file_clear_stat_cache");
    XopENTRY_set(&file_clear_stat_cache_xop, xop_desc, "clear stat cache");
    XopENTRY_set(&file_clear_stat_cache_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_file_clear_stat_cache, &file_clear_stat_cache_xop);

    XopENTRY_set(&file_basename_xop, xop_name, "file_basename");
    XopENTRY_set(&file_basename_xop, xop_desc, "file basename");
    XopENTRY_set(&file_basename_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_basename, &file_basename_xop);

    XopENTRY_set(&file_dirname_xop, xop_name, "file_dirname");
    XopENTRY_set(&file_dirname_xop, xop_desc, "file dirname");
    XopENTRY_set(&file_dirname_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_dirname, &file_dirname_xop);

    XopENTRY_set(&file_extname_xop, xop_name, "file_extname");
    XopENTRY_set(&file_extname_xop, xop_desc, "file extname");
    XopENTRY_set(&file_extname_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_extname, &file_extname_xop);

    XopENTRY_set(&file_mtime_xop, xop_name, "file_mtime");
    XopENTRY_set(&file_mtime_xop, xop_desc, "file mtime");
    XopENTRY_set(&file_mtime_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_mtime, &file_mtime_xop);

    XopENTRY_set(&file_atime_xop, xop_name, "file_atime");
    XopENTRY_set(&file_atime_xop, xop_desc, "file atime");
    XopENTRY_set(&file_atime_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_atime, &file_atime_xop);

    XopENTRY_set(&file_ctime_xop, xop_name, "file_ctime");
    XopENTRY_set(&file_ctime_xop, xop_desc, "file ctime");
    XopENTRY_set(&file_ctime_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_ctime, &file_ctime_xop);

    XopENTRY_set(&file_mode_xop, xop_name, "file_mode");
    XopENTRY_set(&file_mode_xop, xop_desc, "file mode");
    XopENTRY_set(&file_mode_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_mode, &file_mode_xop);

    XopENTRY_set(&file_is_link_xop, xop_name, "file_is_link");
    XopENTRY_set(&file_is_link_xop, xop_desc, "file is_link");
    XopENTRY_set(&file_is_link_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_link, &file_is_link_xop);

    XopENTRY_set(&file_is_readable_xop, xop_name, "file_is_readable");
    XopENTRY_set(&file_is_readable_xop, xop_desc, "file is_readable");
    XopENTRY_set(&file_is_readable_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_readable, &file_is_readable_xop);

    XopENTRY_set(&file_is_writable_xop, xop_name, "file_is_writable");
    XopENTRY_set(&file_is_writable_xop, xop_desc, "file is_writable");
    XopENTRY_set(&file_is_writable_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_writable, &file_is_writable_xop);

    XopENTRY_set(&file_is_executable_xop, xop_name, "file_is_executable");
    XopENTRY_set(&file_is_executable_xop, xop_desc, "file is_executable");
    XopENTRY_set(&file_is_executable_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_executable, &file_is_executable_xop);

    XopENTRY_set(&file_readdir_xop, xop_name, "file_readdir");
    XopENTRY_set(&file_readdir_xop, xop_desc, "file readdir");
    XopENTRY_set(&file_readdir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_readdir, &file_readdir_xop);

    XopENTRY_set(&file_slurp_raw_xop, xop_name, "file_slurp_raw");
    XopENTRY_set(&file_slurp_raw_xop, xop_desc, "file slurp_raw");
    XopENTRY_set(&file_slurp_raw_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_slurp_raw, &file_slurp_raw_xop);

    XopENTRY_set(&file_copy_xop, xop_name, "file_copy");
    XopENTRY_set(&file_copy_xop, xop_desc, "file copy");
    XopENTRY_set(&file_copy_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_copy, &file_copy_xop);

    XopENTRY_set(&file_move_xop, xop_name, "file_move");
    XopENTRY_set(&file_move_xop, xop_desc, "file move");
    XopENTRY_set(&file_move_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_move, &file_move_xop);

    XopENTRY_set(&file_chmod_xop, xop_name, "file_chmod");
    XopENTRY_set(&file_chmod_xop, xop_desc, "file chmod");
    XopENTRY_set(&file_chmod_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_chmod, &file_chmod_xop);

    XopENTRY_set(&file_append_xop, xop_name, "file_append");
    XopENTRY_set(&file_append_xop, xop_desc, "file append");
    XopENTRY_set(&file_append_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_append, &file_append_xop);

    XopENTRY_set(&file_atomic_spew_xop, xop_name, "file_atomic_spew");
    XopENTRY_set(&file_atomic_spew_xop, xop_desc, "file atomic_spew");
    XopENTRY_set(&file_atomic_spew_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_atomic_spew, &file_atomic_spew_xop);

    /* Install functions with call checker for custom op optimization */
    {
        CV *cv;
        SV *ckobj;

        /* 1-arg functions with call checker */
        cv = newXS("File::Raw::size", xs_size, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_size));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::mtime", xs_mtime, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_mtime));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::atime", xs_atime, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_atime));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::ctime", xs_ctime, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_ctime));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::mode", xs_mode, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_mode));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::exists", xs_exists, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_exists));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_file", xs_is_file, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_file));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_dir", xs_is_dir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_dir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_link", xs_is_link, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_link));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_readable", xs_is_readable, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_readable));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_writable", xs_is_writable, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_writable));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_executable", xs_is_executable, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_executable));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        /* File manipulation - 1-arg */
        cv = newXS("File::Raw::unlink", xs_unlink, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_unlink));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::mkdir", xs_mkdir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_mkdir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::rmdir", xs_rmdir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_rmdir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::touch", xs_touch, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_touch));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::clear_stat_cache", xs_clear_stat_cache, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_clear_stat_cache));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::basename", xs_basename, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_basename));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::dirname", xs_dirname, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_dirname));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::extname", xs_extname, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_extname));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::slurp", xs_slurp, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_slurp));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::slurp_raw", xs_slurp_raw, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_slurp_raw));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::lines", xs_lines, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_lines));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::readdir", xs_readdir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_readdir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        /* 2-arg functions with call checker */
        cv = newXS("File::Raw::spew", xs_spew, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_spew));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::append", xs_append, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_append));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::copy", xs_copy, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_copy));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::move", xs_move, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_move));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::chmod", xs_chmod, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_chmod));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::atomic_spew", xs_atomic_spew, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_atomic_spew));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);
    }

    /* Functions without custom op optimization */
    newXS("File::Raw::join", xs_join, __FILE__);
    newXS("File::Raw::mkpath", xs_mkpath, __FILE__);
    newXS("File::Raw::rm_rf", xs_rm_rf, __FILE__);
    newXS("File::Raw::each_line", xs_each_line, __FILE__);
    newXS("File::Raw::grep_lines", xs_grep_lines, __FILE__);
    newXS("File::Raw::count_lines", xs_count_lines, __FILE__);
    newXS("File::Raw::find_line", xs_find_line, __FILE__);
    newXS("File::Raw::map_lines", xs_map_lines, __FILE__);

    /* Plugin API */
    newXS("File::Raw::register_plugin", xs_register_plugin, __FILE__);
    newXS("File::Raw::unregister_plugin", xs_unregister_plugin, __FILE__);
    newXS("File::Raw::list_plugins", xs_list_plugins, __FILE__);
    newXS("File::Raw::register_predicate", xs_register_predicate, __FILE__);
    newXS("File::Raw::list_predicates", xs_list_predicates, __FILE__);

    /* Built-in 'predicate' plugin: routes the eight built-in line
     * predicates and any user-registered ones through plugin dispatch.
     * Initialise the predicate storage first so the plugin's record fn
     * always sees a populated registry. */
    file_init_callback_registry(aTHX);
    if (file_register_plugin(aTHX_ &g_predicate_plugin) != 1) {
        croak("File::Raw boot: failed to register built-in 'predicate' plugin");
    }

    /* Combined stat - all attributes in one syscall */
    newXS("File::Raw::stat", xs_stat_all, __FILE__);

    /* Head and tail */
    newXS("File::Raw::head", xs_head, __FILE__);
    newXS("File::Raw::tail", xs_tail, __FILE__);
    newXS("File::Raw::range_lines", xs_range_lines, __FILE__);

    /* Import function */
    newXS("File::Raw::import", XS_file_import, __FILE__);

    /* Memory-mapped files */
    newXS("File::Raw::mmap_open", xs_mmap_open, __FILE__);
    newXS("File::Raw::mmap::data", xs_mmap_data, __FILE__);
    newXS("File::Raw::mmap::sync", xs_mmap_sync, __FILE__);
    newXS("File::Raw::mmap::close", xs_mmap_close, __FILE__);
    newXS("File::Raw::mmap::DESTROY", xs_mmap_DESTROY, __FILE__);

    /* Line iterators */
    newXS("File::Raw::lines_iter", xs_lines_iter, __FILE__);
    newXS("File::Raw::lines::next", xs_lines_iter_next, __FILE__);
    newXS("File::Raw::lines::eof", xs_lines_iter_eof, __FILE__);
    newXS("File::Raw::lines::close", xs_lines_iter_close, __FILE__);
    newXS("File::Raw::lines::DESTROY", xs_lines_iter_DESTROY, __FILE__);

    /* Register cleanup for global destruction */
    Perl_call_atexit(aTHX_ file_cleanup_callback_registry, NULL);

#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 22)
    Perl_xs_boot_epilog(aTHX_ ax);
#else
    XSRETURN_YES;
#endif
}
