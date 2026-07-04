/*
 * Archive.xs - File::Raw::Archive XS shim.
 *
 * Registers the built-in tar plugin at BOOT. Exposes thin XSUBs that
 * the Perl-facing layer (File/Raw/Archive.pm) drives:
 *   _open_read, _read_next, _read_data, _read_close
 *   _open_write, _write_add, _write_close
 *   _extract_to_fd, _apply_xattrs
 *   _list_plugins, _probe
 *
 * Higher-level convenience (each, list, extract, extract_all, pack)
 * lives in pure Perl over these primitives.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "archive_plugin.h"
#include "arch_io.h"
#include "tar.h"
#include "extract.h"
#include "marshal.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <utime.h>

#define ARCHIVE_PATH_MAX 4096

/* ============================================================
 * Object slot layout
 * ============================================================
 *
 * Reader / Writer / Entry are blessed AVs (Object::Proto pattern).
 * Compile-time slot indices replace runtime hash-key lookups, which
 * is faster and keeps every per-entry access in C to a pointer + add.
 *
 * Reader  AV:  [ handle, consumed, closed, cur_entry ]
 * Writer  AV:  [ handle, closed ]
 * Entry   AV:  [ reader, meta, slurped ]
 * Meta    AV:  [ name, size, mode, mtime, mtime_ns, uid, gid, type,
 *               link_target, xattrs, is_sparse ]
 *
 * `handle` is a blessed-IV-ref to archive_handle_t* (class
 * File::Raw::Archive::Reader or ::Writer); its DESTROY frees the C
 * struct via maybe_free_handle. `meta` is a plain RV-AV. `xattrs`
 * stays a hashref because callers index into it by arbitrary key.
 */

#define R_HANDLE     0
#define R_CONSUMED   1
#define R_CLOSED     2
#define R_CUR_ENTRY  3
#define R_SLOT_COUNT 4

#define W_HANDLE     0
#define W_CLOSED     1
#define W_SLOT_COUNT 2

#define E_READER     0
#define E_META       1
#define E_SLURPED    2
#define E_SLOT_COUNT 3

#define M_NAME        0
#define M_SIZE        1
#define M_MODE        2
#define M_MTIME       3
#define M_MTIME_NS    4
#define M_UID         5
#define M_GID         6
#define M_TYPE        7
#define M_LINK_TARGET 8
#define M_XATTRS      9
#define M_IS_SPARSE   10
#define M_SLOT_COUNT  11

#ifndef XS_EXTERNAL
#define XS_EXTERNAL(name) XS(name)
#endif

/* ============================================================
 * Reader / writer state
 * ============================================================ */

typedef struct {
    int                  fd;
    archive_fd_state_t   fd_state;
    archive_gz_src_t    *gz_src;
    archive_gz_sink_t   *gz_sink;
    const ArchivePlugin *plugin;
    void                *cursor;
    int                  is_writer;
    int                  closed;
    /* The most recently emitted entry from Reader::next, kept here so
     * Reader::next can drain its payload before advancing. Owned by
     * the handle (refcount +1); released on next/close. */
    SV                  *cur_entry_rv;
    int                  consumed;   /* current entry's payload drained? */
} archive_handle_t;

static archive_handle_t *
make_handle(void)
{
    archive_handle_t *h = (archive_handle_t *)calloc(1, sizeof *h);
    if (h) h->fd = -1;
    return h;
}

static void
free_handle(pTHX_ archive_handle_t *h)
{
    if (!h || h->closed) return;
    h->closed = 1;
    if (h->cur_entry_rv) {
        SvREFCNT_dec(h->cur_entry_rv);
        h->cur_entry_rv = NULL;
    }
    if (h->plugin && h->cursor) {
        if (h->is_writer) {
            if (h->plugin->write_close)
                h->plugin->write_close(aTHX_ h->plugin, h->cursor);
        } else {
            if (h->plugin->read_close)
                h->plugin->read_close(aTHX_ h->plugin, h->cursor);
        }
    }
    if (h->gz_src)  archive_gz_src_free(h->gz_src);
    if (h->gz_sink) {
        archive_gz_sink_finish(h->gz_sink);
        archive_gz_sink_free(h->gz_sink);
    }
    if (h->fd >= 0) close(h->fd);
    free(h);
}

/* Forward decls: defined further down but used by open_reader below. */
static int  sniff_gzip(int fd);
static int  resolve_compression(pTHX_ int fd, HV *opts);
static const ArchivePlugin *resolve_plugin(pTHX_ HV *opts, int fd, int gz);

/* Common reader-open helper used by every top-level path-taking
 * method. Mirrors what _open_read does but factored for reuse from
 * list/extract/extract_all/each. Returns archive_handle_t* on success
 * or NULL after croaking. */
static archive_handle_t *
open_reader(pTHX_ SV *path_sv, HV *opts)
{
    archive_handle_t *h;
    int gz, fd;
    const ArchivePlugin *plugin;
    archive_pull_fn pull;
    void *src;

    fd = open(SvPV_nolen(path_sv), O_RDONLY);
    if (fd < 0) croak("File::Raw::Archive: cannot open '%s': %s",
                      SvPV_nolen(path_sv), strerror(errno));

    gz = resolve_compression(aTHX_ fd, opts);
    plugin = resolve_plugin(aTHX_ opts, fd, gz);
    if (!plugin) {
        close(fd);
        croak("File::Raw::Archive: no plugin selected (auto-detection failed)");
    }

    h = make_handle();
    if (!h) { close(fd); croak("File::Raw::Archive: out of memory"); }
    h->fd = fd;
    h->plugin = plugin;
    h->consumed = 1;  /* no entry yet -> nothing to drain */

    if (gz) {
        h->gz_src = archive_gz_src_new(fd, ARCHIVE_DEFAULT_CHUNK);
        if (!h->gz_src) {
            free_handle(aTHX_ h);
            croak("File::Raw::Archive: gzip stream init failed");
        }
        pull = archive_pull_gz;
        src  = h->gz_src;
    } else {
        h->fd_state.fd = fd;
        pull = archive_pull_fd;
        src  = &h->fd_state;
    }

    if (plugin->read_open(aTHX_ plugin, pull, src, opts, &h->cursor) < 0) {
        free_handle(aTHX_ h);
        croak("File::Raw::Archive: read_open failed");
    }
    return h;
}

/* Drain the current entry's payload bytes if not already consumed.
 * Called between read_next invocations and during close. */
static void
drain_current_entry(pTHX_ archive_handle_t *h)
{
    if (h->consumed) return;
    char buf[16 * 1024];
    int n;
    while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                     buf, sizeof buf)) > 0) {}
    h->consumed = 1;
    if (n < 0) croak("File::Raw::Archive: read_data failed");
}

/* Common writer-open helper. */
static archive_handle_t *
open_writer(pTHX_ SV *path_sv, HV *opts)
{
    archive_handle_t *h;
    int gz = 0, fd;
    const ArchivePlugin *plugin;
    archive_push_fn push;
    void *sink;

    if (opts) {
        SV **sv = hv_fetchs(opts, "compression", 0);
        if (sv && *sv && SvOK(*sv)) {
            STRLEN nn;
            const char *pp = SvPV(*sv, nn);
            if (nn == 4 && memcmp(pp, "gzip", 4) == 0) gz = 1;
            else if (nn == 4 && memcmp(pp, "auto", 4) == 0) {
                STRLEN pl;
                const char *pp2 = SvPV(path_sv, pl);
                if (pl >= 3 && memcmp(pp2 + pl - 3, ".gz", 3) == 0) gz = 1;
            }
        }
    }

    fd = open(SvPV_nolen(path_sv), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) croak("File::Raw::Archive: cannot open '%s' for write: %s",
                      SvPV_nolen(path_sv), strerror(errno));

    {
        SV **sv = opts ? hv_fetchs(opts, "plugin", 0) : NULL;
        if (sv && *sv && SvOK(*sv)) {
            STRLEN nn;
            const char *pp = SvPV(*sv, nn);
            char namebuf[64];
            if (nn >= sizeof namebuf) {
                close(fd);
                croak("File::Raw::Archive: plugin name too long");
            }
            memcpy(namebuf, pp, nn);
            namebuf[nn] = '\0';
            plugin = archive_lookup_plugin(aTHX_ namebuf);
        } else {
            plugin = archive_lookup_plugin(aTHX_ "tar");
        }
    }
    if (!plugin) { close(fd); croak("File::Raw::Archive: unknown plugin"); }

    h = make_handle();
    if (!h) { close(fd); croak("File::Raw::Archive: out of memory"); }
    h->fd = fd;
    h->plugin = plugin;
    h->is_writer = 1;
    h->consumed = 1;

    if (gz) {
        int level = 6;
        if (opts) {
            SV **lsv = hv_fetchs(opts, "level", 0);
            if (lsv && *lsv && SvOK(*lsv)) level = (int)SvIV(*lsv);
        }
        h->gz_sink = archive_gz_sink_new(fd, ARCHIVE_DEFAULT_CHUNK, level);
        if (!h->gz_sink) {
            free_handle(aTHX_ h);
            croak("File::Raw::Archive: gzip sink init failed");
        }
        push = archive_push_gz;
        sink = h->gz_sink;
    } else {
        h->fd_state.fd = fd;
        push = archive_push_fd;
        sink = &h->fd_state;
    }

    if (plugin->write_open(aTHX_ plugin, push, sink, opts, &h->cursor) < 0) {
        free_handle(aTHX_ h);
        croak("File::Raw::Archive: write_open failed (bad format option?)");
    }
    return h;
}

/* ============================================================
 * Helpers
 * ============================================================ */

/* Detect gzip magic 1f 8b at offset 0. */
static int
sniff_gzip(int fd)
{
    unsigned char magic[2];
    off_t pos = lseek(fd, 0, SEEK_CUR);
    if (pos < 0) return 0;
    ssize_t n = read(fd, magic, 2);
    lseek(fd, pos, SEEK_SET);
    if (n < 2) return 0;
    return (magic[0] == 0x1f && magic[1] == 0x8b);
}

/* Resolve compression option: returns 1 if gzip should be used. */
static int
resolve_compression(pTHX_ int fd, HV *opts)
{
    if (!opts) return sniff_gzip(fd);
    SV **sv = hv_fetchs(opts, "compression", 0);
    if (!sv || !*sv || !SvOK(*sv)) return sniff_gzip(fd);
    STRLEN n;
    const char *p = SvPV(*sv, n);
    if (n == 4 && memcmp(p, "auto", 4) == 0) return sniff_gzip(fd);
    if (n == 4 && memcmp(p, "gzip", 4) == 0) return 1;
    if (n == 4 && memcmp(p, "none", 4) == 0) return 0;
    return sniff_gzip(fd);
}

/* Resolve plugin option: returns plugin or NULL with error string. */
static const ArchivePlugin *
resolve_plugin(pTHX_ HV *opts, int fd, int gz)
{
    SV **sv = opts ? hv_fetchs(opts, "plugin", 0) : NULL;
    if (sv && *sv && SvOK(*sv)) {
        STRLEN n;
        const char *p = SvPV(*sv, n);
        if (n == 4 && memcmp(p, "auto", 4) == 0) {
            /* Probe by reading the first block. */
            char probe_buf[512];
            off_t pos = lseek(fd, 0, SEEK_CUR);
            if (pos < 0) return NULL;
            /* If gzip-wrapped, we'd need to inflate to probe. For now,
             * default to tar when auto + gzip. */
            if (gz) return archive_lookup_plugin(aTHX_ "tar");
            ssize_t got = read(fd, probe_buf, sizeof probe_buf);
            lseek(fd, pos, SEEK_SET);
            if (got <= 0) return NULL;
            return archive_probe_for(aTHX_ probe_buf, (size_t)got);
        }
        char namebuf[64];
        if (n >= sizeof namebuf) return NULL;
        memcpy(namebuf, p, n);
        namebuf[n] = '\0';
        return archive_lookup_plugin(aTHX_ namebuf);
    }
    return archive_lookup_plugin(aTHX_ "tar");
}

/* Build a snapshot hashref from an ArchiveEntry. Used only by `list`
 * for a friendlier AoH return shape. Internal Entry objects use AV
 * slot indices (entry_to_av) for speed. */
static SV *
entry_to_hv_snapshot(pTHX_ const ArchiveEntry *e)
{
    HV *h = newHV();
    hv_stores(h, "name",     newSVpvn(e->name ? e->name : "", e->name_len));
    hv_stores(h, "size",     newSVuv((UV)e->size));
    hv_stores(h, "mode",     newSVuv((UV)e->mode));
    hv_stores(h, "mtime",    newSVuv((UV)e->mtime));
    hv_stores(h, "mtime_ns", newSVuv((UV)e->mtime_ns));
    hv_stores(h, "uid",      newSVuv((UV)e->uid));
    hv_stores(h, "gid",      newSVuv((UV)e->gid));
    hv_stores(h, "type",     newSViv((IV)e->type));
    hv_stores(h, "is_sparse", newSViv(e->is_sparse));
    if (e->link_target)
        hv_stores(h, "link_target",
                  newSVpvn(e->link_target, e->link_target_len));
    if (e->xattr_count > 0) {
        HV *xh = newHV();
        size_t i;
        for (i = 0; i < e->xattr_count; i++) {
            hv_store(xh, e->xattrs[i].key, (I32)e->xattrs[i].key_len,
                     newSVpvn(e->xattrs[i].value, e->xattrs[i].value_len), 0);
        }
        hv_stores(h, "xattrs", newRV_noinc((SV *)xh));
    }
    return newRV_noinc((SV *)h);
}

/* Build a meta AV from an ArchiveEntry. Slot layout: M_NAME..M_IS_SPARSE.
 * Returns RV-AV at refcount +1. Slots that aren't applicable (e.g.
 * link_target on a regular file) are left empty rather than stored as
 * undef so size() sees a missing slot and returns the default. */
static SV *
entry_to_av(pTHX_ const ArchiveEntry *e)
{
    AV *meta = newAV();
    av_extend(meta, M_SLOT_COUNT - 1);
    av_store(meta, M_NAME,
             newSVpvn(e->name ? e->name : "", e->name_len));
    av_store(meta, M_SIZE,        newSVuv((UV)e->size));
    av_store(meta, M_MODE,        newSVuv((UV)e->mode));
    av_store(meta, M_MTIME,       newSVuv((UV)e->mtime));
    av_store(meta, M_MTIME_NS,    newSVuv((UV)e->mtime_ns));
    av_store(meta, M_UID,         newSVuv((UV)e->uid));
    av_store(meta, M_GID,         newSVuv((UV)e->gid));
    av_store(meta, M_TYPE,        newSViv((IV)e->type));
    av_store(meta, M_IS_SPARSE,   newSViv(e->is_sparse));
    if (e->link_target) {
        av_store(meta, M_LINK_TARGET,
                 newSVpvn(e->link_target, e->link_target_len));
    }
    if (e->xattr_count > 0) {
        HV *xh = newHV();
        size_t i;
        for (i = 0; i < e->xattr_count; i++) {
            hv_store(xh, e->xattrs[i].key, (I32)e->xattrs[i].key_len,
                     newSVpvn(e->xattrs[i].value, e->xattrs[i].value_len), 0);
        }
        av_store(meta, M_XATTRS, newRV_noinc((SV *)xh));
    }
    return newRV_noinc((SV *)meta);
}

/* Decode a Perl entry hashref into ArchiveEntry. The returned entry
 * borrows pointers into SVs that must outlive the call - caller keeps
 * the hash alive until write_add returns. */
static void
hv_to_entry(pTHX_ HV *h, ArchiveEntry *e,
            ArchiveXattr *xattr_buf, size_t xattr_buf_n,
            size_t *xattr_used)
{
    memset(e, 0, sizeof *e);
    *xattr_used = 0;

    SV **sv = hv_fetchs(h, "name", 0);
    if (sv && *sv && SvOK(*sv)) {
        STRLEN nl;
        e->name = SvPV(*sv, nl);
        e->name_len = nl;
    }
    sv = hv_fetchs(h, "type", 0);
    if (sv && *sv && SvOK(*sv)) e->type = (int)SvIV(*sv);
    else e->type = AE_FILE;

    sv = hv_fetchs(h, "mode", 0);
    if (sv && *sv && SvOK(*sv)) e->mode = (uint32_t)SvUV(*sv);

    sv = hv_fetchs(h, "size", 0);
    if (sv && *sv && SvOK(*sv)) e->size = (uint64_t)SvUV(*sv);

    sv = hv_fetchs(h, "mtime", 0);
    if (sv && *sv && SvOK(*sv)) {
        if (SvNOKp(*sv) || (SvPOKp(*sv) && strchr(SvPV_nolen(*sv), '.'))) {
            NV nv = SvNV(*sv);
            uint64_t whole = (uint64_t)nv;
            double frac = nv - (double)whole;
            if (frac < 0) frac = 0;
            e->mtime = whole;
            e->mtime_ns = (uint32_t)(frac * 1e9 + 0.5);
            if (e->mtime_ns >= 1000000000U) {
                e->mtime++;
                e->mtime_ns -= 1000000000U;
            }
        } else {
            e->mtime = (uint64_t)SvUV(*sv);
        }
    }
    sv = hv_fetchs(h, "mtime_ns", 0);
    if (sv && *sv && SvOK(*sv)) e->mtime_ns = (uint32_t)SvUV(*sv);

    sv = hv_fetchs(h, "uid", 0);
    if (sv && *sv && SvOK(*sv)) e->uid = (uint32_t)SvUV(*sv);
    sv = hv_fetchs(h, "gid", 0);
    if (sv && *sv && SvOK(*sv)) e->gid = (uint32_t)SvUV(*sv);

    sv = hv_fetchs(h, "link_target", 0);
    if (sv && *sv && SvOK(*sv)) {
        STRLEN ll;
        e->link_target = SvPV(*sv, ll);
        e->link_target_len = ll;
    }

    sv = hv_fetchs(h, "xattrs", 0);
    if (sv && *sv && SvROK(*sv) && SvTYPE(SvRV(*sv)) == SVt_PVHV) {
        HV *xh = (HV *)SvRV(*sv);
        hv_iterinit(xh);
        HE *he;
        while ((he = hv_iternext(xh)) && *xattr_used < xattr_buf_n) {
            I32 klen_i;
            const char *k = hv_iterkey(he, &klen_i);
            SV *v = hv_iterval(xh, he);
            STRLEN vlen;
            const char *vp = SvPV(v, vlen);
            xattr_buf[*xattr_used].key = k;
            xattr_buf[*xattr_used].key_len = (size_t)klen_i;
            xattr_buf[*xattr_used].value = vp;
            xattr_buf[*xattr_used].value_len = vlen;
            (*xattr_used)++;
        }
        e->xattrs = xattr_buf;
        e->xattr_count = *xattr_used;
    }
}

/* Bless a handle pointer into a class. */
static SV *
new_handle_obj(pTHX_ archive_handle_t *h, const char *cls)
{
    SV *iv = newSViv(PTR2IV(h));
    SV *rv = newRV_noinc(iv);
    return sv_bless(rv, gv_stashpv(cls, GV_ADD));
}

static archive_handle_t *
unwrap_handle(pTHX_ SV *sv)
{
    if (!SvROK(sv) || !SvIOK(SvRV(sv))) return NULL;
    return INT2PTR(archive_handle_t *, SvIV(SvRV(sv)));
}

/* Idempotent close-and-free for a blessed-IV-ref handle SV. After the
 * first call, the underlying IV is set to 0 so subsequent calls (e.g.
 * from DESTROY after an explicit close) become no-ops without a double
 * free. */
static void
maybe_free_handle(pTHX_ SV *handle_sv)
{
    if (!handle_sv || !SvROK(handle_sv)) return;
    SV *iv_sv = SvRV(handle_sv);
    if (!SvIOK(iv_sv)) return;
    archive_handle_t *h = INT2PTR(archive_handle_t *, SvIV(iv_sv));
    if (!h) return;
    free_handle(aTHX_ h);
    sv_setiv(iv_sv, 0);
}

/* Hash-key lookup helper. Returns the SV* at key, or NULL if not
 * present / not defined. dTHX picks up the interpreter from
 * PERL_GET_THX so callers don't have to thread pTHX_ through. */
static SV *
hv_get(HV *h, const char *key, I32 klen)
{
    dTHX;
    SV **p = hv_fetch(h, key, klen, 0);
    if (!p || !*p || !SvOK(*p)) return NULL;
    return *p;
}

/* SAVEDESTRUCTOR_X target: closes a handle when the current dynamic
 * scope unwinds, including via croak. Used by the new public top-
 * level XSUBs that own the open + work + close lifecycle. */
static void
free_handle_destructor(pTHX_ void *data)
{
    free_handle(aTHX_ (archive_handle_t *)data);
}

/* Compile-time platform gate for parallel extract: needs fork(2)/
 * pipe(2)/waitpid(2). Windows lacks them, so parallel=N silently
 * falls back to sequential there. */
static int
parallel_supported(void)
{
#ifdef _WIN32
    return 0;
#else
    return 1;
#endif
}

/* Build an opts HV from a variadic-style stack pointer. `args` should
 * be the address of ST(start) at the call site so this function works
 * outside an XSUB. The HV is mortalised. Caller must have validated
 * that (count) is even. */
static HV *
build_opts_from_args(pTHX_ SV **args, int count)
{
    HV *opts = newHV();
    sv_2mortal((SV *)opts);
    int i;
    for (i = 0; i + 1 < count; i += 2) {
        STRLEN klen;
        const char *kp = SvPV(args[i], klen);
        hv_store(opts, kp, klen, newSVsv(args[i + 1]), 0);
    }
    return opts;
}

/* The shared sequential extract-all loop. Croaks on error; caller is
 * responsible for handle lifetime via SAVEDESTRUCTOR_X. */
static void
do_extract_all_seq(pTHX_ archive_handle_t *h,
                   const char *dest, size_t dest_len,
                   int apply_xattrs, int unsafe_paths,
                   SV *filter_sv)
{
    char path_buf[ARCHIVE_PATH_MAX];
    char skip_buf[16 * 1024];
    int has_filter;

    if (!h || h->is_writer || h->closed)
        croak("File::Raw::Archive::extract_all: invalid handle");
    if (dest_len == 0 || dest_len >= sizeof path_buf - 2)
        croak("File::Raw::Archive::extract_all: bad dest length");

    has_filter = (filter_sv && SvOK(filter_sv) && SvROK(filter_sv) &&
                  SvTYPE(SvRV(filter_sv)) == SVt_PVCV);

    if (archive_mkpath(dest, 0755) < 0) {
        croak("File::Raw::Archive::extract_all: cannot create dest '%s': %s",
              dest, strerror(errno));
    }

    for (;;) {
        ArchiveEntry e;
        int rc = h->plugin->read_next(aTHX_ h->plugin, h->cursor, &e);
        if (rc < 0) croak("File::Raw::Archive: malformed archive");
        if (rc == 0) break;

        if (!unsafe_paths) {
            if (!archive_path_is_safe(e.name, e.name_len)) {
                croak("File::Raw::Archive::extract_all: refusing unsafe path '%.*s'",
                      (int)e.name_len, e.name);
            }
        }

        if (has_filter) {
            int keep = 1;
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            SV *entry_rv = entry_to_av(aTHX_ &e);
            sv_2mortal(entry_rv);
            XPUSHs(entry_rv);
            PUTBACK;
            int count = call_sv(filter_sv, G_SCALAR);
            SPAGAIN;
            if (count >= 1) {
                SV *r = POPs;
                keep = SvTRUE(r) ? 1 : 0;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
            if (!keep) {
                int n;
                while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                                 skip_buf, sizeof skip_buf)) > 0) {}
                if (n < 0) croak("File::Raw::Archive: read_data failed");
                continue;
            }
        }

        if (dest_len + 1 + e.name_len + 1 > sizeof path_buf) {
            croak("File::Raw::Archive::extract_all: path too long for '%.*s'",
                  (int)e.name_len, e.name);
        }
        memcpy(path_buf, dest, dest_len);
        path_buf[dest_len] = '/';
        memcpy(path_buf + dest_len + 1, e.name, e.name_len);
        path_buf[dest_len + 1 + e.name_len] = '\0';

        switch (e.type) {
        case AE_DIR:
            if (archive_extract_dir(path_buf, e.mode) < 0) {
                croak("File::Raw::Archive::extract_all: mkdir '%s': %s",
                      path_buf, strerror(errno));
            }
            break;
        case AE_SYMLINK: {
            const char *target = e.link_target ? e.link_target : "";
            if (archive_extract_symlink(path_buf, target) < 0) {
                warn("File::Raw::Archive: symlink failed for %s: %s",
                     path_buf, strerror(errno));
            }
            int n;
            while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                             skip_buf, sizeof skip_buf)) > 0) {}
            if (n < 0) croak("File::Raw::Archive: read_data failed");
            break;
        }
        case AE_FILE: {
            if (archive_make_parent_dir(path_buf) < 0) {
                croak("File::Raw::Archive::extract_all: mkpath parent '%s': %s",
                      path_buf, strerror(errno));
            }
            const char *errstage = NULL;
            if (archive_extract_entry(aTHX_ h->plugin, h->cursor, &e,
                                      path_buf, apply_xattrs,
                                      &errstage) < 0) {
                croak("File::Raw::Archive::extract_all: %s '%s': %s",
                      errstage ? errstage : "?", path_buf, strerror(errno));
            }
            break;
        }
        default: {
            int n;
            while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                             skip_buf, sizeof skip_buf)) > 0) {}
            if (n < 0) croak("File::Raw::Archive: read_data failed");
            break;
        }
        }
    }
}

/* Shared list helper. Returns RV-AV with one entry per archive entry. */
static SV *
do_list(pTHX_ archive_handle_t *h)
{
    char skip_buf[16 * 1024];
    AV *rows;

    if (!h || h->is_writer || h->closed)
        croak("File::Raw::Archive::list: invalid handle");

    rows = newAV();
    for (;;) {
        ArchiveEntry e;
        int rc = h->plugin->read_next(aTHX_ h->plugin, h->cursor, &e);
        if (rc < 0) {
            SvREFCNT_dec((SV *)rows);
            croak("File::Raw::Archive: malformed archive");
        }
        if (rc == 0) break;

        /* list() returns an AoH for friendlier external consumption.
         * Internal Entry objects use AV slots; this is a snapshot. */
        SV *entry_rv = entry_to_hv_snapshot(aTHX_ &e);
        av_push(rows, entry_rv);

        int n;
        while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                         skip_buf, sizeof skip_buf)) > 0) {}
        if (n < 0) {
            SvREFCNT_dec((SV *)rows);
            croak("File::Raw::Archive: read_data failed");
        }
    }
    return newRV_noinc((SV *)rows);
}

/* Shared single-entry extract helper. Returns 1 if found+written, 0
 * if name not in archive. */
static IV
do_extract_one(pTHX_ archive_handle_t *h,
               const char *match_name, STRLEN match_len,
               const char *dest_path, int apply_xattrs)
{
    char skip_buf[16 * 1024];

    if (!h || h->is_writer || h->closed)
        croak("File::Raw::Archive::extract: invalid handle");

    for (;;) {
        ArchiveEntry e;
        int rc = h->plugin->read_next(aTHX_ h->plugin, h->cursor, &e);
        if (rc < 0) croak("File::Raw::Archive: malformed archive");
        if (rc == 0) return 0;

        if (e.name_len == match_len
                && memcmp(e.name, match_name, match_len) == 0) {
            if (e.type == AE_FILE) {
                if (archive_make_parent_dir(dest_path) < 0) {
                    croak("File::Raw::Archive::extract: mkpath parent '%s': %s",
                          dest_path, strerror(errno));
                }
                const char *errstage = NULL;
                if (archive_extract_entry(aTHX_ h->plugin, h->cursor, &e,
                                          dest_path, apply_xattrs,
                                          &errstage) < 0) {
                    croak("File::Raw::Archive::extract: %s '%s': %s",
                          errstage ? errstage : "?", dest_path, strerror(errno));
                }
            } else if (e.type == AE_DIR) {
                if (archive_extract_dir(dest_path, e.mode) < 0) {
                    croak("File::Raw::Archive::extract: mkdir '%s': %s",
                          dest_path, strerror(errno));
                }
            } else if (e.type == AE_SYMLINK) {
                const char *target = e.link_target ? e.link_target : "";
                if (archive_extract_symlink(dest_path, target) < 0) {
                    warn("File::Raw::Archive::extract: symlink failed for %s: %s",
                         dest_path, strerror(errno));
                }
            }
            return 1;
        }

        int n;
        while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                         skip_buf, sizeof skip_buf)) > 0) {}
        if (n < 0) croak("File::Raw::Archive: read_data failed");
    }
}

/* Build a File::Raw::Archive::Entry blessed AV pointing back at the
 * shared `reader_sv`. Slots: [reader, meta, slurped]. Returns
 * RV-AV at +1; caller mortalises if needed. */
static SV *
build_entry_obj(pTHX_ SV *reader_sv, SV *meta_rv)
{
    AV *entry = newAV();
    av_extend(entry, E_SLOT_COUNT - 1);
    av_store(entry, E_READER, SvREFCNT_inc(reader_sv));
    av_store(entry, E_META,   meta_rv);    /* takes ownership */
    /* E_SLURPED stays empty until ->slurp memoises bytes there. */
    SV *obj = newRV_noinc((SV *)entry);
    sv_bless(obj, gv_stashpv("File::Raw::Archive::Entry", GV_ADD));
    return obj;
}

/* Shared each-iteration helper. Calls cb_sv per entry, optionally
 * filtered. cb_sv must be a CV ref. The reader_sv is a blessed Reader
 * hashref (built by the caller) that Entry objects link back to so
 * `$entry->slurp` / `$entry->_skip` keep working. Croaks on error. */
static void
do_each(pTHX_ archive_handle_t *h, SV *reader_sv,
        SV *cb_sv, SV *filter_sv)
{
    char skip_buf[16 * 1024];
    int has_filter;

    if (!h || h->is_writer || h->closed)
        croak("File::Raw::Archive::each: invalid handle");

    has_filter = (filter_sv && SvOK(filter_sv) && SvROK(filter_sv) &&
                  SvTYPE(SvRV(filter_sv)) == SVt_PVCV);

    for (;;) {
        ArchiveEntry e;
        int rc = h->plugin->read_next(aTHX_ h->plugin, h->cursor, &e);
        if (rc < 0) croak("File::Raw::Archive: malformed archive");
        if (rc == 0) break;

        SV *entry_rv = entry_to_av(aTHX_ &e);    /* RV-HV at +1 */
        SV *entry_obj = build_entry_obj(aTHX_ reader_sv, entry_rv);

        if (has_filter) {
            int keep = 1;
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(SvREFCNT_inc(entry_obj)));
            PUTBACK;
            int count = call_sv(filter_sv, G_SCALAR);
            SPAGAIN;
            if (count >= 1) {
                SV *r = POPs;
                keep = SvTRUE(r) ? 1 : 0;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
            if (!keep) {
                SvREFCNT_dec(entry_obj);
                int n;
                while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                                 skip_buf, sizeof skip_buf)) > 0) {}
                if (n < 0) croak("File::Raw::Archive: read_data failed");
                continue;
            }
        }

        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(SvREFCNT_inc(entry_obj)));
            PUTBACK;
            call_sv(cb_sv, G_VOID | G_DISCARD);
            FREETMPS;
            LEAVE;
        }

        SvREFCNT_dec(entry_obj);

        /* Drain any unread payload bytes so the cursor advances. */
        int n;
        while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                         skip_buf, sizeof skip_buf)) > 0) {}
        if (n < 0) croak("File::Raw::Archive: read_data failed");
    }
}

/* ============================================================
 * Parallel extract: worker loop body + parent orchestrator
 * ============================================================
 *
 * The parent process iterates the archive, slurps each regular file's
 * payload, marshals (path, content, metadata, xattrs) into a single
 * binary record, and writes it to one of N forked children's pipes
 * round-robin. Each child runs `do_worker_loop` (this same function
 * body) and writes file/chmod/utime errors back to a shared error
 * pipe. After the parent finishes dispatch and closes all worker job
 * pipes (signalling EOF), it drains the error pipe and reaps the
 * children. Any error → consolidated croak.
 *
 * fork(2) inside an XSUB is safe as long as the child path doesn't
 * unwind back through Perl - we _exit(2) directly so Perl END / DESTROY
 * blocks don't fire and corrupt shared state. */

static void
do_worker_loop(int job_fd, int err_fd)
{
    ParallelJob job;
    char errbuf[1024];
    ArchiveEntry e;
    for (;;) {
        int rc = marshal_read_job(job_fd, &job);
        if (rc == 1) break;            /* clean EOF */
        if (rc < 0) {
            const char *m = "worker: malformed job\n";
            ssize_t _ignored = write(err_fd, m, strlen(m));
            (void)_ignored;
            break;
        }

        memset(&e, 0, sizeof e);
        e.name        = job.path;
        e.name_len    = job.path_len;
        e.size        = job.content_len;
        e.mode        = job.mode;
        e.mtime       = job.mtime;
        e.mtime_ns    = job.mtime_ns;
        e.uid         = job.uid;
        e.gid         = job.gid;
        e.type        = AE_FILE;
        e.xattrs      = job.xattrs;
        e.xattr_count = job.xattr_count;

        const char *stage = NULL;
        if (archive_extract_bytes(&e, job.path,
                                  job.content, job.content_len,
                                  job.apply_xattrs, &stage) < 0) {
            int n = snprintf(errbuf, sizeof errbuf,
                             "%s: %s: %s\n",
                             job.path, stage ? stage : "?",
                             strerror(errno));
            if (n > 0) {
                if ((size_t)n > sizeof errbuf) n = (int)sizeof errbuf;
                ssize_t _ignored = write(err_fd, errbuf, (size_t)n);
                (void)_ignored;
            }
        }

        parallel_job_free(&job);
    }
}

typedef struct {
    int   write_fd;
    pid_t pid;
} parallel_worker_t;

static void
do_extract_all_parallel(pTHX_ archive_handle_t *h,
                        const char *dest, size_t dest_len,
                        int parallel, int apply_xattrs,
                        SV *filter_sv, int unsafe_paths)
{
    char path_buf[ARCHIVE_PATH_MAX];
    char skip_buf[16 * 1024];
    parallel_worker_t *workers = NULL;
    int err_r = -1, err_w = -1;
    int num_started = 0;
    int has_filter;
    int dispatch_err = 0;
    char err_msg[512] = "";
    int err_pipe[2];
    struct sigaction old_sigpipe, new_sa;
    int i, rr = 0;

    if (!h || h->is_writer || h->closed)
        croak("File::Raw::Archive::extract_all: invalid handle");
    if (dest_len == 0 || dest_len >= sizeof path_buf - 2)
        croak("File::Raw::Archive::extract_all: bad dest length");
    if (parallel < 1) parallel = 1;

    has_filter = (filter_sv && SvOK(filter_sv) && SvROK(filter_sv) &&
                  SvTYPE(SvRV(filter_sv)) == SVt_PVCV);

    if (archive_mkpath(dest, 0755) < 0) {
        croak("File::Raw::Archive::extract_all: cannot create dest '%s': %s",
              dest, strerror(errno));
    }

    if (pipe(err_pipe) < 0) croak("pipe: %s", strerror(errno));
    err_r = err_pipe[0];
    err_w = err_pipe[1];

    workers = (parallel_worker_t *)calloc(parallel, sizeof *workers);
    if (!workers) {
        close(err_r); close(err_w);
        croak("File::Raw::Archive: out of memory");
    }

    /* Ignore SIGPIPE while workers are alive. A worker crash would
     * otherwise SIGPIPE the parent on the next dispatch write. */
    new_sa.sa_handler = SIG_IGN;
    sigemptyset(&new_sa.sa_mask);
    new_sa.sa_flags = 0;
    sigaction(SIGPIPE, &new_sa, &old_sigpipe);

    for (i = 0; i < parallel; i++) {
        int job_pipe[2];
        if (pipe(job_pipe) < 0) {
            int saved = errno;
            int j;
            for (j = 0; j < num_started; j++) {
                close(workers[j].write_fd);
                kill(workers[j].pid, SIGTERM);
                waitpid(workers[j].pid, NULL, 0);
            }
            close(err_r); close(err_w);
            free(workers);
            sigaction(SIGPIPE, &old_sigpipe, NULL);
            croak("File::Raw::Archive: pipe: %s", strerror(saved));
        }
        pid_t pid = fork();
        if (pid < 0) {
            int saved = errno;
            int j;
            close(job_pipe[0]); close(job_pipe[1]);
            for (j = 0; j < num_started; j++) {
                close(workers[j].write_fd);
                kill(workers[j].pid, SIGTERM);
                waitpid(workers[j].pid, NULL, 0);
            }
            close(err_r); close(err_w);
            free(workers);
            sigaction(SIGPIPE, &old_sigpipe, NULL);
            croak("File::Raw::Archive: fork: %s", strerror(saved));
        }
        if (pid == 0) {
            /* Child: keep its job-read fd and the shared err-write fd;
             * everything else inherited from the parent gets closed. */
            int j;
            close(job_pipe[1]);
            close(err_r);
            for (j = 0; j < num_started; j++) {
                close(workers[j].write_fd);
            }
            do_worker_loop(job_pipe[0], err_w);
            close(job_pipe[0]);
            close(err_w);
            _exit(0);
        }
        /* Parent. */
        close(job_pipe[0]);
        workers[num_started].write_fd = job_pipe[1];
        workers[num_started].pid = pid;
        num_started++;
    }
    close(err_w); err_w = -1;

    /* Dispatch loop. */
    for (;;) {
        ArchiveEntry e;
        int rc = h->plugin->read_next(aTHX_ h->plugin, h->cursor, &e);
        if (rc < 0) {
            snprintf(err_msg, sizeof err_msg, "malformed archive");
            dispatch_err = 1;
            break;
        }
        if (rc == 0) break;

        if (!unsafe_paths) {
            if (!archive_path_is_safe(e.name, e.name_len)) {
                snprintf(err_msg, sizeof err_msg,
                         "refusing unsafe path '%.*s'",
                         (int)e.name_len, e.name);
                dispatch_err = 1;
                break;
            }
        }

        if (has_filter) {
            int keep = 1;
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            SV *entry_rv = entry_to_av(aTHX_ &e);
            sv_2mortal(entry_rv);
            XPUSHs(entry_rv);
            PUTBACK;
            int count = call_sv(filter_sv, G_SCALAR);
            SPAGAIN;
            if (count >= 1) {
                SV *r = POPs;
                keep = SvTRUE(r) ? 1 : 0;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
            if (!keep) {
                int n;
                while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                                 skip_buf, sizeof skip_buf)) > 0) {}
                if (n < 0) { snprintf(err_msg, sizeof err_msg, "read_data failed"); dispatch_err = 1; break; }
                continue;
            }
        }

        if (dest_len + 1 + e.name_len + 1 > sizeof path_buf) {
            snprintf(err_msg, sizeof err_msg,
                     "path too long for '%.*s'", (int)e.name_len, e.name);
            dispatch_err = 1;
            break;
        }
        memcpy(path_buf, dest, dest_len);
        path_buf[dest_len] = '/';
        memcpy(path_buf + dest_len + 1, e.name, e.name_len);
        path_buf[dest_len + 1 + e.name_len] = '\0';

        if (e.type == AE_DIR) {
            if (archive_extract_dir(path_buf, e.mode) < 0) {
                snprintf(err_msg, sizeof err_msg,
                         "mkdir '%s': %s", path_buf, strerror(errno));
                dispatch_err = 1;
                break;
            }
            continue;
        }
        if (e.type == AE_SYMLINK) {
            const char *target = e.link_target ? e.link_target : "";
            if (archive_extract_symlink(path_buf, target) < 0) {
                warn("File::Raw::Archive: symlink failed for %s: %s",
                     path_buf, strerror(errno));
            }
            int n;
            while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                             skip_buf, sizeof skip_buf)) > 0) {}
            if (n < 0) { snprintf(err_msg, sizeof err_msg, "read_data failed"); dispatch_err = 1; break; }
            continue;
        }
        if (e.type != AE_FILE) {
            int n;
            while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                             skip_buf, sizeof skip_buf)) > 0) {}
            if (n < 0) { snprintf(err_msg, sizeof err_msg, "read_data failed"); dispatch_err = 1; break; }
            continue;
        }

        /* Regular file: ensure parent dir exists, slurp content, marshal, dispatch. */
        if (archive_make_parent_dir(path_buf) < 0) {
            snprintf(err_msg, sizeof err_msg,
                     "mkpath parent '%s': %s", path_buf, strerror(errno));
            dispatch_err = 1;
            break;
        }

        char *content = NULL;
        size_t content_cap = 0, content_len = 0;
        int read_err = 0;
        for (;;) {
            if (content_len + 16384 > content_cap) {
                size_t new_cap = content_cap ? content_cap * 2 : 65536;
                while (new_cap < content_len + 16384) new_cap *= 2;
                char *p = (char *)realloc(content, new_cap);
                if (!p) { read_err = 1; break; }
                content = p;
                content_cap = new_cap;
            }
            int n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                         content + content_len, 16384);
            if (n < 0) { read_err = 1; break; }
            if (n == 0) break;
            content_len += (size_t)n;
        }
        if (read_err) {
            free(content);
            snprintf(err_msg, sizeof err_msg, "read_data failed for '%s'", path_buf);
            dispatch_err = 1;
            break;
        }

        char *payload = NULL;
        size_t payload_len = 0;
        if (marshal_job(path_buf, strlen(path_buf),
                        content, content_len,
                        e.mode,
                        e.mtime, e.mtime_ns,
                        e.uid, e.gid,
                        apply_xattrs,
                        e.xattrs, e.xattr_count,
                        &payload, &payload_len) < 0) {
            free(content);
            snprintf(err_msg, sizeof err_msg, "marshal_job: out of memory");
            dispatch_err = 1;
            break;
        }
        free(content);

        if (marshal_send(workers[rr].write_fd, payload, payload_len) < 0) {
            int saved = errno;
            free(payload);
            snprintf(err_msg, sizeof err_msg,
                     "pipe write to worker %d: %s", rr, strerror(saved));
            dispatch_err = 1;
            break;
        }
        free(payload);
        rr = (rr + 1) % parallel;
    }

    /* Close all worker write fds (signals EOF). */
    for (i = 0; i < num_started; i++) {
        if (workers[i].write_fd >= 0) {
            close(workers[i].write_fd);
            workers[i].write_fd = -1;
        }
    }

    /* Drain error pipe (workers' per-job errors). */
    SV *errors_sv = sv_2mortal(newSVpvs(""));
    {
        char buf[4096];
        for (;;) {
            ssize_t n = read(err_r, buf, sizeof buf);
            if (n < 0) {
                if (errno == EINTR) continue;
                break;
            }
            if (n == 0) break;
            sv_catpvn(errors_sv, buf, (STRLEN)n);
        }
    }
    close(err_r);

    /* Reap. */
    for (i = 0; i < num_started; i++) {
        waitpid(workers[i].pid, NULL, 0);
    }
    free(workers);

    /* Restore SIGPIPE handler. */
    sigaction(SIGPIPE, &old_sigpipe, NULL);

    if (dispatch_err) {
        croak("File::Raw::Archive::extract_all: %s", err_msg);
    }
    STRLEN err_len;
    const char *err_pv = SvPV(errors_sv, err_len);
    if (err_len > 0) {
        croak("File::Raw::Archive::extract_all: errors during parallel extract:\n  %.*s",
              (int)err_len, err_pv);
    }
}

/* ============================================================
 * Custom-op accessor infrastructure (Entry methods)
 * ============================================================
 *
 * `$entry->name`, `->size`, `->is_dir` etc. are normally method
 * dispatches: ENTERSUB walks @ISA, finds our XSUB, sets up a CALL
 * frame, runs the XSUB body, returns. We can do better at compile
 * time by replacing the ENTERSUB op with a custom op that jumps
 * straight to a lightweight pp_* handler. The handler reads the
 * entry's slot directly and returns - no @ISA walk, no method-cache
 * touch, no XSUB call frame.
 *
 * Mechanism (Object::Proto pattern):
 *   - Define one pp_entry_accessor handler that uses op_targ to
 *     know which Meta slot to read (M_NAME .. M_IS_SPARSE).
 *   - Define one pp_entry_predicate for is_file / is_dir / etc.
 *   - At BOOT, register a call checker on each accessor's CV.
 *     The checker walks the op tree at compile time and rewrites
 *     ENTERSUB to OP_CUSTOM with op_ppaddr / op_targ set.
 *   - The checker bails (returns the original entersubop unchanged)
 *     on call forms it can't handle - dynamic method names,
 *     stashed coderefs, extra args - so the XSUB still runs.
 *
 * Skipped on perl < 5.14 (cv_set_call_checker not available);
 * the XSUB methods stay correct on those builds, just slower.
 */

#if PERL_VERSION_GE(5,14,0)

static XOP entry_accessor_xop;
static XOP entry_predicate_xop;

static OP *
pp_entry_accessor(pTHX)
{
    dSP;
    SV *self_sv = POPs;
    int slot = (int)PL_op->op_targ;
    SV *result = &PL_sv_undef;

    if (SvROK(self_sv) && SvTYPE(SvRV(self_sv)) == SVt_PVAV) {
        AV *self = (AV *)SvRV(self_sv);
        SV **meta_ref = av_fetch(self, E_META, 0);
        if (meta_ref && *meta_ref && SvROK(*meta_ref)
                && SvTYPE(SvRV(*meta_ref)) == SVt_PVAV) {
            AV *meta = (AV *)SvRV(*meta_ref);
            SV **val = av_fetch(meta, slot, 0);
            if (val && *val && SvOK(*val)) {
                result = sv_2mortal(SvREFCNT_inc(*val));
            } else {
                /* Numeric defaults for the integer-typed slots, to
                 * match the XSUB accessor behaviour. */
                switch (slot) {
                case M_SIZE: case M_MODE: case M_MTIME: case M_MTIME_NS:
                case M_UID:  case M_GID:  case M_TYPE:  case M_IS_SPARSE:
                    result = sv_2mortal(newSViv(0));
                    break;
                default:
                    /* string-typed slots: stay undef. */
                    break;
                }
            }
        }
    }

    XPUSHs(result);
    RETURN;
}

static OP *
pp_entry_predicate(pTHX)
{
    dSP;
    SV *self_sv = POPs;
    int kind = (int)PL_op->op_targ;
    IV t = (IV)AE_FILE;
    int rc = 0;

    if (SvROK(self_sv) && SvTYPE(SvRV(self_sv)) == SVt_PVAV) {
        AV *self = (AV *)SvRV(self_sv);
        SV **meta_ref = av_fetch(self, E_META, 0);
        if (meta_ref && *meta_ref && SvROK(*meta_ref)
                && SvTYPE(SvRV(*meta_ref)) == SVt_PVAV) {
            AV *meta = (AV *)SvRV(*meta_ref);
            SV **type_ref = av_fetch(meta, M_TYPE, 0);
            if (type_ref && *type_ref && SvOK(*type_ref))
                t = SvIV(*type_ref);
        }
    }

    switch (kind) {
    case 1: rc = (t == AE_FILE);    break;
    case 2: rc = (t == AE_DIR);     break;
    case 3: rc = (t == AE_SYMLINK); break;
    case 4: rc = (t == AE_SYMLINK || t == AE_HARDLINK); break;
    }
    XPUSHs(rc ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* Call checker shared by accessors and predicates. ckobj packs the
 * slot/kind in the high bits and a 1-bit "predicate?" flag in the low
 * bit so the same checker function can dispatch to either pp_*. */
static OP *
entry_method_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj)
{
    OP *pushop, *self_op, *cv_op, *newop;
    IV packed;
    int slot_or_kind;
    int is_predicate;

    PERL_UNUSED_ARG(namegv);

    packed = SvIV(ckobj);
    is_predicate = (int)(packed & 1);
    slot_or_kind = (int)(packed >> 1);

    /* Walk: entersub -> pushmark -> invocant -> &method_cv. We require
     * exactly one invocant (no extra args), otherwise bail. */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }
    self_op = OpSIBLING(pushop);
    if (!self_op) return entersubop;
    cv_op = OpSIBLING(self_op);
    if (!cv_op) return entersubop;
    if (OpSIBLING(cv_op)) return entersubop;   /* extra args */

    /* Detach self_op from the entersub tree. */
    OpMORESIB_set(pushop, cv_op);
    OpLASTSIB_set(self_op, NULL);
    self_op = op_contextualize(self_op, G_SCALAR);

    /* Build OP_NULL first (avoids -DDEBUGGING newUNOP assert), then
     * convert to OP_CUSTOM and set op_ppaddr / op_targ. */
    newop = newUNOP(OP_NULL, 0, self_op);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = is_predicate ? pp_entry_predicate : pp_entry_accessor;
    newop->op_targ = (PADOFFSET)slot_or_kind;

    op_free(entersubop);
    return newop;
}

static void
install_entry_method_checker(pTHX_ const char *method,
                             int slot_or_kind, int is_predicate)
{
    char full[128];
    snprintf(full, sizeof full,
             "File::Raw::Archive::Entry::%s", method);
    CV *cv = get_cv(full, 0);
    if (!cv) return;
    SV *ckobj = newSViv(((IV)slot_or_kind << 1)
                       | (is_predicate ? 1 : 0));
    cv_set_call_checker(cv, entry_method_checker, ckobj);
}

#endif /* PERL_VERSION_GE(5,14,0) */

/* ============================================================ */

MODULE = File::Raw::Archive   PACKAGE = File::Raw::Archive

PROTOTYPES: DISABLE

BOOT:
    archive_register_plugin(aTHX_ &tar_plugin);
    {
        HV *stash = gv_stashpv("File::Raw::Archive", GV_ADD);
        newCONSTSUB(stash, "AE_FILE",     newSViv(AE_FILE));
        newCONSTSUB(stash, "AE_DIR",      newSViv(AE_DIR));
        newCONSTSUB(stash, "AE_SYMLINK",  newSViv(AE_SYMLINK));
        newCONSTSUB(stash, "AE_HARDLINK", newSViv(AE_HARDLINK));
        newCONSTSUB(stash, "AE_FIFO",     newSViv(AE_FIFO));
        newCONSTSUB(stash, "AE_CHAR",     newSViv(AE_CHAR));
        newCONSTSUB(stash, "AE_BLOCK",    newSViv(AE_BLOCK));
        newCONSTSUB(stash, "AE_OTHER",    newSViv(AE_OTHER));
    }
#if PERL_VERSION_GE(5,14,0)
    /* Register custom-op replacements for Entry method dispatch.
     * After this, `$entry->name` etc. compiles into a direct AV-slot
     * lookup with no @ISA walk and no XSUB call frame. */
    XopENTRY_set(&entry_accessor_xop,  xop_name,  "entry_accessor");
    XopENTRY_set(&entry_accessor_xop,  xop_desc,  "Entry method accessor");
    XopENTRY_set(&entry_accessor_xop,  xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_entry_accessor, &entry_accessor_xop);

    XopENTRY_set(&entry_predicate_xop, xop_name,  "entry_predicate");
    XopENTRY_set(&entry_predicate_xop, xop_desc,  "Entry type predicate");
    XopENTRY_set(&entry_predicate_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_entry_predicate, &entry_predicate_xop);

    /* Slot accessors. */
    install_entry_method_checker(aTHX_ "name",        M_NAME,        0);
    install_entry_method_checker(aTHX_ "size",        M_SIZE,        0);
    install_entry_method_checker(aTHX_ "mode",        M_MODE,        0);
    install_entry_method_checker(aTHX_ "mtime",       M_MTIME,       0);
    install_entry_method_checker(aTHX_ "mtime_ns",    M_MTIME_NS,    0);
    install_entry_method_checker(aTHX_ "uid",         M_UID,         0);
    install_entry_method_checker(aTHX_ "gid",         M_GID,         0);
    install_entry_method_checker(aTHX_ "type",        M_TYPE,        0);
    install_entry_method_checker(aTHX_ "link_target", M_LINK_TARGET, 0);
    install_entry_method_checker(aTHX_ "xattrs",      M_XATTRS,      0);
    install_entry_method_checker(aTHX_ "is_sparse",   M_IS_SPARSE,   0);

    /* Type predicates: kind=1..4 keyed to the switch in pp_entry_predicate. */
    install_entry_method_checker(aTHX_ "is_file",    1, 1);
    install_entry_method_checker(aTHX_ "is_dir",     2, 1);
    install_entry_method_checker(aTHX_ "is_symlink", 3, 1);
    install_entry_method_checker(aTHX_ "is_link",    4, 1);
#endif

SV *
_open_read(path_sv, opts_sv)
    SV *path_sv
    SV *opts_sv
PREINIT:
    HV *opts = NULL;
    archive_handle_t *h = NULL;
    int gz, fd;
    const ArchivePlugin *plugin;
    archive_pull_fn pull;
    void *src;
CODE:
    if (!SvOK(path_sv)) croak("File::Raw::Archive::_open_read: undef path");
    if (SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV)
        opts = (HV *)SvRV(opts_sv);

    fd = open(SvPV_nolen(path_sv), O_RDONLY);
    if (fd < 0) croak("File::Raw::Archive: cannot open '%s': %s",
                      SvPV_nolen(path_sv), strerror(errno));

    gz = resolve_compression(aTHX_ fd, opts);
    plugin = resolve_plugin(aTHX_ opts, fd, gz);
    if (!plugin) {
        close(fd);
        croak("File::Raw::Archive: no plugin selected (auto-detection failed)");
    }

    h = make_handle();
    if (!h) { close(fd); croak("File::Raw::Archive: out of memory"); }
    h->fd = fd;
    h->plugin = plugin;

    if (gz) {
        h->gz_src = archive_gz_src_new(fd, ARCHIVE_DEFAULT_CHUNK);
        if (!h->gz_src) {
            free_handle(aTHX_ h);
            croak("File::Raw::Archive: gzip stream init failed");
        }
        pull = archive_pull_gz;
        src = h->gz_src;
    } else {
        h->fd_state.fd = fd;
        pull = archive_pull_fd;
        src  = &h->fd_state;
    }

    if (plugin->read_open(aTHX_ plugin, pull, src, opts, &h->cursor) < 0) {
        free_handle(aTHX_ h);
        croak("File::Raw::Archive: read_open failed");
    }

    RETVAL = new_handle_obj(aTHX_ h, "File::Raw::Archive::Reader");
OUTPUT:
    RETVAL

SV *
_read_next(handle_sv)
    SV *handle_sv
PREINIT:
    archive_handle_t *h;
    ArchiveEntry e;
    int rc;
CODE:
    h = unwrap_handle(aTHX_ handle_sv);
    if (!h || h->closed || h->is_writer)
        croak("File::Raw::Archive::_read_next: invalid handle");
    rc = h->plugin->read_next(aTHX_ h->plugin, h->cursor, &e);
    if (rc < 0) croak("File::Raw::Archive: malformed archive");
    if (rc == 0) RETVAL = &PL_sv_undef;
    else RETVAL = entry_to_av(aTHX_ &e);
OUTPUT:
    RETVAL

SV *
_read_data(handle_sv, max_bytes_sv = NULL)
    SV *handle_sv
    SV *max_bytes_sv
PREINIT:
    archive_handle_t *h;
    UV want = 0;
    SV *out;
    char buf[64 * 1024];
    int n;
CODE:
    h = unwrap_handle(aTHX_ handle_sv);
    if (!h || h->closed || h->is_writer)
        croak("File::Raw::Archive::_read_data: invalid handle");
    if (max_bytes_sv && SvOK(max_bytes_sv)) want = SvUV(max_bytes_sv);
    out = newSVpvn("", 0);
    /* If `want` set, read exactly that many. Otherwise drain the entry. */
    while (1) {
        size_t take = sizeof buf;
        if (want > 0) {
            UV remain = want - (UV)SvCUR(out);
            if (remain == 0) break;
            if (remain < take) take = (size_t)remain;
        }
        n = h->plugin->read_data(aTHX_ h->plugin, h->cursor, buf, take);
        if (n < 0) { SvREFCNT_dec(out); croak("File::Raw::Archive: read_data failed"); }
        if (n == 0) break;
        sv_catpvn(out, buf, (STRLEN)n);
        if (want == 0 && (size_t)n < take) {
            /* Either entry done or short read; if entry has more,
             * the next iteration will return more. read_data returns
             * 0 only at end-of-entry. */
        }
    }
    RETVAL = out;
OUTPUT:
    RETVAL

void
_read_close(handle_sv)
    SV *handle_sv
PREINIT:
    archive_handle_t *h;
CODE:
    h = unwrap_handle(aTHX_ handle_sv);
    if (h) free_handle(aTHX_ h);

SV *
_open_write(path_sv, opts_sv)
    SV *path_sv
    SV *opts_sv
PREINIT:
    HV *opts = NULL;
    archive_handle_t *h = NULL;
    int gz = 0, fd;
    const ArchivePlugin *plugin;
    archive_push_fn push;
    void *sink;
CODE:
    if (!SvOK(path_sv)) croak("File::Raw::Archive::_open_write: undef path");
    if (SvROK(opts_sv) && SvTYPE(SvRV(opts_sv)) == SVt_PVHV)
        opts = (HV *)SvRV(opts_sv);

    {
        SV **sv = opts ? hv_fetchs(opts, "compression", 0) : NULL;
        if (sv && *sv && SvOK(*sv)) {
            STRLEN nn;
            const char *pp = SvPV(*sv, nn);
            if ((nn == 4 && memcmp(pp, "gzip", 4) == 0)) gz = 1;
            else if (nn == 4 && memcmp(pp, "auto", 4) == 0) {
                /* On write, "auto" means look at suffix; if .gz, gzip. */
                STRLEN pl;
                const char *pp2 = SvPV(path_sv, pl);
                if (pl >= 3 && memcmp(pp2 + pl - 3, ".gz", 3) == 0) gz = 1;
            }
        }
    }

    fd = open(SvPV_nolen(path_sv), O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) croak("File::Raw::Archive: cannot open '%s' for write: %s",
                      SvPV_nolen(path_sv), strerror(errno));

    {
        SV **sv = opts ? hv_fetchs(opts, "plugin", 0) : NULL;
        if (sv && *sv && SvOK(*sv)) {
            STRLEN nn;
            const char *pp = SvPV(*sv, nn);
            char namebuf[64];
            if (nn >= sizeof namebuf) {
                close(fd);
                croak("File::Raw::Archive: plugin name too long");
            }
            memcpy(namebuf, pp, nn);
            namebuf[nn] = '\0';
            plugin = archive_lookup_plugin(aTHX_ namebuf);
        } else {
            plugin = archive_lookup_plugin(aTHX_ "tar");
        }
    }
    if (!plugin) { close(fd); croak("File::Raw::Archive: unknown plugin"); }

    h = make_handle();
    if (!h) { close(fd); croak("File::Raw::Archive: out of memory"); }
    h->fd = fd;
    h->plugin = plugin;
    h->is_writer = 1;

    if (gz) {
        int level = 6;
        if (opts) {
            SV **lsv = hv_fetchs(opts, "level", 0);
            if (lsv && *lsv && SvOK(*lsv)) level = (int)SvIV(*lsv);
        }
        h->gz_sink = archive_gz_sink_new(fd, ARCHIVE_DEFAULT_CHUNK, level);
        if (!h->gz_sink) { free_handle(aTHX_ h); croak("File::Raw::Archive: gzip sink init failed"); }
        push = archive_push_gz;
        sink = h->gz_sink;
    } else {
        h->fd_state.fd = fd;
        push = archive_push_fd;
        sink = &h->fd_state;
    }

    if (plugin->write_open(aTHX_ plugin, push, sink, opts, &h->cursor) < 0) {
        free_handle(aTHX_ h);
        croak("File::Raw::Archive: write_open failed (bad format option?)");
    }

    RETVAL = new_handle_obj(aTHX_ h, "File::Raw::Archive::Writer");
OUTPUT:
    RETVAL

void
_write_add(handle_sv, entry_sv, content_sv)
    SV *handle_sv
    SV *entry_sv
    SV *content_sv
PREINIT:
    archive_handle_t *h;
    HV *eh;
    ArchiveEntry e;
    ArchiveXattr xbuf[64];
    size_t xused = 0;
    STRLEN clen = 0;
    const char *cp = NULL;
CODE:
    h = unwrap_handle(aTHX_ handle_sv);
    if (!h || h->closed || !h->is_writer)
        croak("File::Raw::Archive::_write_add: invalid handle");
    if (!SvROK(entry_sv) || SvTYPE(SvRV(entry_sv)) != SVt_PVHV)
        croak("File::Raw::Archive::_write_add: entry must be a hashref");
    eh = (HV *)SvRV(entry_sv);
    hv_to_entry(aTHX_ eh, &e, xbuf, sizeof xbuf / sizeof xbuf[0], &xused);

    if (SvOK(content_sv)) {
        cp = SvPV(content_sv, clen);
        /* If caller didn't set entry size, use the content length. */
        if (e.size == 0 && clen > 0) e.size = clen;
    }

    if (h->plugin->write_add(aTHX_ h->plugin, h->cursor, &e, cp, clen) < 0)
        croak("File::Raw::Archive::_write_add: write failed (entry exceeds format limits?)");

void
_write_close(handle_sv)
    SV *handle_sv
PREINIT:
    archive_handle_t *h;
CODE:
    h = unwrap_handle(aTHX_ handle_sv);
    if (!h) return;
    if (!h->closed && h->plugin && h->cursor && h->is_writer) {
        if (h->plugin->write_close(aTHX_ h->plugin, h->cursor) < 0)
            croak("File::Raw::Archive::_write_close: failed");
        h->cursor = NULL;  /* prevent double-close */
    }
    /* gz_sink finish is handled in free_handle. */
    if (h->gz_sink) {
        if (archive_gz_sink_finish(h->gz_sink) < 0)
            croak("File::Raw::Archive::_write_close: gzip finalise failed");
    }
    free_handle(aTHX_ h);

int
_apply_xattrs(fd_iv, xattrs_sv)
    IV fd_iv
    SV *xattrs_sv
PREINIT:
    HV *xh;
    ArchiveXattr buf[64];
    size_t n = 0;
    int rc;
CODE:
    if (!SvROK(xattrs_sv) || SvTYPE(SvRV(xattrs_sv)) != SVt_PVHV) XSRETURN_IV(0);
    xh = (HV *)SvRV(xattrs_sv);
    hv_iterinit(xh);
    HE *he;
    while ((he = hv_iternext(xh)) && n < sizeof buf / sizeof buf[0]) {
        I32 klen_i;
        const char *k = hv_iterkey(he, &klen_i);
        SV *v = hv_iterval(xh, he);
        STRLEN vlen;
        const char *vp = SvPV(v, vlen);
        buf[n].key = k;
        buf[n].key_len = (size_t)klen_i;
        buf[n].value = vp;
        buf[n].value_len = vlen;
        n++;
    }
    rc = archive_apply_xattrs((int)fd_iv, buf, n);
    RETVAL = rc;
OUTPUT:
    RETVAL

SV *
_list_plugins()
PREINIT:
    AV *av;
    int i;
CODE:
    av = newAV();
    /* We don't expose iteration in the public API, so do a small
     * lookup-by-name dance. Currently only "tar" is built-in; sister
     * dists register more. */
    static const char *known[] = { "tar", "zip", "cpio", "ar", NULL };
    for (i = 0; known[i]; i++) {
        if (archive_lookup_plugin(aTHX_ known[i])) {
            av_push(av, newSVpv(known[i], 0));
        }
    }
    RETVAL = newRV_noinc((SV *)av);
OUTPUT:
    RETVAL

void
_extract_all_xs(handle_sv, dest_sv, apply_xattrs_iv, unsafe_paths_iv, filter_sv)
    SV *handle_sv
    SV *dest_sv
    IV apply_xattrs_iv
    IV unsafe_paths_iv
    SV *filter_sv
PREINIT:
    archive_handle_t *h;
    const char *dest;
    STRLEN dest_len;
CODE:
    h = unwrap_handle(aTHX_ handle_sv);
    if (!SvOK(dest_sv))
        croak("File::Raw::Archive::_extract_all_xs: dest required");
    dest = SvPV(dest_sv, dest_len);
    do_extract_all_seq(aTHX_ h, dest, dest_len,
                       (int)apply_xattrs_iv, (int)unsafe_paths_iv,
                       filter_sv);

SV *
_list_xs(handle_sv)
    SV *handle_sv
CODE:
    RETVAL = do_list(aTHX_ unwrap_handle(aTHX_ handle_sv));
OUTPUT:
    RETVAL

IV
_extract_one_xs(handle_sv, name_sv, dest_sv, apply_xattrs_iv)
    SV *handle_sv
    SV *name_sv
    SV *dest_sv
    IV apply_xattrs_iv
PREINIT:
    archive_handle_t *h;
    STRLEN match_len;
    const char *match_name;
    const char *dest_path;
CODE:
    h = unwrap_handle(aTHX_ handle_sv);
    if (!SvOK(name_sv) || !SvOK(dest_sv))
        croak("File::Raw::Archive::_extract_one_xs: name and dest required");
    match_name = SvPV(name_sv, match_len);
    dest_path  = SvPV_nolen(dest_sv);
    RETVAL = do_extract_one(aTHX_ h, match_name, match_len,
                            dest_path, (int)apply_xattrs_iv);
OUTPUT:
    RETVAL

void
_send_job_xs(fd_iv, path_sv, content_sv, mode_iv, mtime_iv, mtime_ns_iv, uid_iv, gid_iv, apply_xattrs_iv, xattrs_sv)
    IV fd_iv
    SV *path_sv
    SV *content_sv
    IV mode_iv
    IV mtime_iv
    IV mtime_ns_iv
    IV uid_iv
    IV gid_iv
    IV apply_xattrs_iv
    SV *xattrs_sv
PREINIT:
    int fd;
    STRLEN path_len = 0;
    STRLEN content_len = 0;
    const char *path;
    const char *content = "";
    char *buf = NULL;
    size_t buf_len = 0;
    ArchiveXattr xbuf[64];
    size_t xn = 0;
CODE:
    fd = (int)fd_iv;
    if (!SvOK(path_sv))
        croak("File::Raw::Archive::_send_job_xs: path required");
    path = SvPV(path_sv, path_len);
    if (SvOK(content_sv)) {
        content = SvPV(content_sv, content_len);
    }
    if (SvROK(xattrs_sv) && SvTYPE(SvRV(xattrs_sv)) == SVt_PVHV) {
        HV *xh = (HV *)SvRV(xattrs_sv);
        hv_iterinit(xh);
        HE *he;
        while ((he = hv_iternext(xh)) && xn < sizeof xbuf / sizeof xbuf[0]) {
            I32 klen_i;
            const char *k = hv_iterkey(he, &klen_i);
            SV *v = hv_iterval(xh, he);
            STRLEN vlen;
            const char *vp = SvPV(v, vlen);
            xbuf[xn].key       = k;
            xbuf[xn].key_len   = (size_t)klen_i;
            xbuf[xn].value     = vp;
            xbuf[xn].value_len = vlen;
            xn++;
        }
    }

    if (marshal_job(path, path_len,
                    content, content_len,
                    (uint32_t)mode_iv,
                    (uint64_t)mtime_iv, (uint32_t)mtime_ns_iv,
                    (uint32_t)uid_iv, (uint32_t)gid_iv,
                    (int)apply_xattrs_iv,
                    xbuf, xn,
                    &buf, &buf_len) < 0) {
        croak("File::Raw::Archive::_send_job_xs: out of memory");
    }
    if (marshal_send(fd, buf, buf_len) < 0) {
        int saved = errno;
        free(buf);
        errno = saved;
        croak("File::Raw::Archive::_send_job_xs: pipe write: %s",
              strerror(saved));
    }
    free(buf);

void
_worker_loop_xs(job_fd_iv, err_fd_iv)
    IV job_fd_iv
    IV err_fd_iv
CODE:
    do_worker_loop((int)job_fd_iv, (int)err_fd_iv);

# ====================================================================
# Public top-level class methods. Each one owns the open + work + close
# lifecycle: the user never sees a Reader/Writer handle for these. The
# handle is freed via SAVEDESTRUCTOR_X so a croak inside the work
# helper cleanly closes the fd and frees the cursor.
# ====================================================================

void
list(...)
PPCODE:
{
    if (items < 2)
        croak("Usage: \\$class->list(\\$path, %%opts)");
    if ((items - 2) % 2 != 0)
        croak("File::Raw::Archive::list: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(2), items - 2);
    archive_handle_t *h = open_reader(aTHX_ ST(1), opts);
    SAVEDESTRUCTOR_X(free_handle_destructor, h);
    SV *result = do_list(aTHX_ h);
    XPUSHs(sv_2mortal(result));
    XSRETURN(1);
}

IV
extract(...)
PPCODE:
{
    if (items < 4)
        croak("Usage: \\$class->extract(\\$path, \\$name, \\$dest, %%opts)");
    if ((items - 4) % 2 != 0)
        croak("File::Raw::Archive::extract: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(4), items - 4);
    int apply_xattrs = 1;
    SV **xv = hv_fetchs(opts, "xattrs", 0);
    if (xv && *xv && SvOK(*xv)) apply_xattrs = SvTRUE(*xv) ? 1 : 0;

    archive_handle_t *h = open_reader(aTHX_ ST(1), opts);
    SAVEDESTRUCTOR_X(free_handle_destructor, h);

    STRLEN match_len;
    const char *match_name = SvPV(ST(2), match_len);
    const char *dest_path  = SvPV_nolen(ST(3));
    IV rc = do_extract_one(aTHX_ h, match_name, match_len, dest_path,
                           apply_xattrs);
    XPUSHs(sv_2mortal(newSViv(rc)));
    XSRETURN(1);
}

IV
extract_all(...)
PPCODE:
{
    if (items < 3)
        croak("Usage: \\$class->extract_all(\\$path, \\$dest, %%opts)");
    if ((items - 3) % 2 != 0)
        croak("File::Raw::Archive::extract_all: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(3), items - 3);
    int apply_xattrs = 1;
    int unsafe_paths = 0;
    int parallel     = 1;
    SV *filter = NULL;
    SV **xv;

    xv = hv_fetchs(opts, "xattrs", 0);
    if (xv && *xv && SvOK(*xv)) apply_xattrs = SvTRUE(*xv) ? 1 : 0;
    xv = hv_fetchs(opts, "unsafe_paths", 0);
    if (xv && *xv && SvOK(*xv)) unsafe_paths = SvTRUE(*xv) ? 1 : 0;
    xv = hv_fetchs(opts, "entry_filter", 0);
    if (xv && *xv && SvOK(*xv)) filter = *xv;
    xv = hv_fetchs(opts, "parallel", 0);
    if (xv && *xv && SvOK(*xv)) parallel = (int)SvIV(*xv);

    if (parallel > 1 && !parallel_supported()) {
        warn("File::Raw::Archive: parallel extract not supported on this "
             "platform; falling back to sequential\n");
        parallel = 1;
    }

    archive_handle_t *h = open_reader(aTHX_ ST(1), opts);
    SAVEDESTRUCTOR_X(free_handle_destructor, h);

    STRLEN dest_len;
    const char *dest = SvPV(ST(2), dest_len);
    if (parallel > 1) {
        do_extract_all_parallel(aTHX_ h, dest, dest_len,
                                parallel, apply_xattrs,
                                filter, unsafe_paths);
    } else {
        do_extract_all_seq(aTHX_ h, dest, dest_len,
                           apply_xattrs, unsafe_paths, filter);
    }
    XPUSHs(sv_2mortal(newSViv(1)));
    XSRETURN(1);
}

void
each(...)
PPCODE:
{
    if (items < 3)
        croak("Usage: \\$class->each(\\$path, %%opts, sub { ... })");
    SV *cb_sv = ST(items - 1);
    if (!SvROK(cb_sv) || SvTYPE(SvRV(cb_sv)) != SVt_PVCV)
        croak("File::Raw::Archive::each: last arg must be a coderef");
    int opts_end = items - 1;
    if ((opts_end - 2) % 2 != 0)
        croak("File::Raw::Archive::each: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(2), opts_end - 2);
    SV *filter = NULL;
    SV **xv = hv_fetchs(opts, "entry_filter", 0);
    if (xv && *xv && SvOK(*xv)) filter = *xv;

    archive_handle_t *h = open_reader(aTHX_ ST(1), opts);

    /* Build a Reader AV equivalent to what File::Raw::Archive->open
     * returns. The Entry objects we hand to the callback link back to
     * this so $entry->slurp / $entry->_skip work the same as on the
     * iterator API. The Reader's DESTROY (XSUB) frees `h` via
     * maybe_free_handle when the AV refcount hits zero - either at
     * XSUB exit (if no Entry stashed it) or whenever the last stashed
     * Entry is collected. */
    AV *reader_av = newAV();
    av_extend(reader_av, R_SLOT_COUNT - 1);
    av_store(reader_av, R_HANDLE,
             new_handle_obj(aTHX_ h, "File::Raw::Archive::Reader"));
    av_store(reader_av, R_CONSUMED, newSViv(1));
    av_store(reader_av, R_CLOSED,   newSViv(0));
    SV *reader_sv = sv_2mortal(newRV_noinc((SV *)reader_av));
    sv_bless(reader_sv, gv_stashpv("File::Raw::Archive::Reader", GV_ADD));

    do_each(aTHX_ h, reader_sv, cb_sv, filter);
    XSRETURN_EMPTY;
}

SV *
open(...)
PPCODE:
{
    if (items < 2)
        croak("Usage: \\$class->open(\\$path, %%opts)");
    if ((items - 2) % 2 != 0)
        croak("File::Raw::Archive::open: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(2), items - 2);
    archive_handle_t *h = open_reader(aTHX_ ST(1), opts);
    SV *handle_sv = new_handle_obj(aTHX_ h, "File::Raw::Archive::Reader");

    AV *self = newAV();
    av_extend(self, R_SLOT_COUNT - 1);
    av_store(self, R_HANDLE,    handle_sv);     /* takes ownership */
    av_store(self, R_CONSUMED,  newSViv(1));
    av_store(self, R_CLOSED,    newSViv(0));
    /* R_CUR_ENTRY left empty until the first ->next. */
    SV *obj = sv_bless(newRV_noinc((SV *)self),
                       gv_stashpv("File::Raw::Archive::Reader", GV_ADD));
    XPUSHs(sv_2mortal(obj));
    XSRETURN(1);
}

SV *
create(...)
PPCODE:
{
    if (items < 2)
        croak("Usage: \\$class->create(\\$path, %%opts)");
    if ((items - 2) % 2 != 0)
        croak("File::Raw::Archive::create: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(2), items - 2);
    archive_handle_t *h = open_writer(aTHX_ ST(1), opts);
    SV *handle_sv = new_handle_obj(aTHX_ h, "File::Raw::Archive::Writer");

    AV *self = newAV();
    av_extend(self, W_SLOT_COUNT - 1);
    av_store(self, W_HANDLE, handle_sv);
    av_store(self, W_CLOSED, newSViv(0));
    SV *obj = sv_bless(newRV_noinc((SV *)self),
                       gv_stashpv("File::Raw::Archive::Writer", GV_ADD));
    XPUSHs(sv_2mortal(obj));
    XSRETURN(1);
}

# ====================================================================
MODULE = File::Raw::Archive   PACKAGE = File::Raw::Archive::Reader
# ====================================================================

SV *
next(self_sv)
    SV *self_sv
PREINIT:
    AV *self;
    SV *handle_sv;
    archive_handle_t *h;
    SV **handle_ref, **closed_ref, **cur_entry_ref, **consumed_ref;
CODE:
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV)
        croak("File::Raw::Archive::Reader::next: invalid invocant");
    self = (AV *)SvRV(self_sv);

    closed_ref = av_fetch(self, R_CLOSED, 0);
    if (closed_ref && *closed_ref && SvTRUE(*closed_ref))
        croak("File::Raw::Archive::Reader::next: reader is closed");

    handle_ref = av_fetch(self, R_HANDLE, 0);
    if (!handle_ref || !*handle_ref)
        croak("File::Raw::Archive::Reader::next: missing handle");
    handle_sv = *handle_ref;
    h = unwrap_handle(aTHX_ handle_sv);
    if (!h || h->is_writer)
        croak("File::Raw::Archive::Reader::next: invalid handle");

    /* Drain previous entry's payload if not consumed. */
    cur_entry_ref = av_fetch(self, R_CUR_ENTRY, 0);
    consumed_ref  = av_fetch(self, R_CONSUMED,  0);
    if (cur_entry_ref && *cur_entry_ref && SvOK(*cur_entry_ref) &&
        (!consumed_ref || !*consumed_ref || !SvTRUE(*consumed_ref))) {
        char buf[16 * 1024];
        int n;
        while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                         buf, sizeof buf)) > 0) {}
        if (n < 0)
            croak("File::Raw::Archive::Reader::next: read_data failed");
    }

    {
        ArchiveEntry e;
        int rc = h->plugin->read_next(aTHX_ h->plugin, h->cursor, &e);
        if (rc < 0)
            croak("File::Raw::Archive: malformed archive");
        if (rc == 0) {
            av_store(self, R_CUR_ENTRY, &PL_sv_undef);
            av_store(self, R_CONSUMED,  newSViv(1));
            XSRETURN_UNDEF;
        }
        SV *entry_rv  = entry_to_av(aTHX_ &e);
        SV *entry_obj = build_entry_obj(aTHX_ self_sv, entry_rv);
        av_store(self, R_CUR_ENTRY, SvREFCNT_inc(entry_obj));
        av_store(self, R_CONSUMED,  newSViv(0));
        RETVAL = entry_obj;
    }
OUTPUT:
    RETVAL

SV *
_handle(self_sv)
    SV *self_sv
PREINIT:
    AV *self;
    SV **handle_ref;
CODE:
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV)
        XSRETURN_UNDEF;
    self = (AV *)SvRV(self_sv);
    handle_ref = av_fetch(self, R_HANDLE, 0);
    if (!handle_ref || !*handle_ref) XSRETURN_UNDEF;
    RETVAL = SvREFCNT_inc(*handle_ref);
OUTPUT:
    RETVAL

void
_mark_consumed(self_sv)
    SV *self_sv
PREINIT:
    AV *self;
CODE:
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV) return;
    self = (AV *)SvRV(self_sv);
    av_store(self, R_CONSUMED, newSViv(1));

void
close(self_sv)
    SV *self_sv
PREINIT:
    AV *self;
    SV **closed_ref, **handle_ref;
CODE:
    if (!SvROK(self_sv)) return;
    if (SvTYPE(SvRV(self_sv)) != SVt_PVAV) {
        /* Bare blessed-IV-ref form: close it directly. */
        maybe_free_handle(aTHX_ self_sv);
        return;
    }
    self = (AV *)SvRV(self_sv);
    closed_ref = av_fetch(self, R_CLOSED, 0);
    if (closed_ref && *closed_ref && SvTRUE(*closed_ref)) return;
    av_store(self, R_CLOSED, newSViv(1));
    /* Clear cur_entry so any stashed entry's slurp fails cleanly
     * rather than reading from a freed handle. */
    av_store(self, R_CUR_ENTRY, &PL_sv_undef);
    handle_ref = av_fetch(self, R_HANDLE, 0);
    if (handle_ref && *handle_ref) maybe_free_handle(aTHX_ *handle_ref);
    av_store(self, R_HANDLE, &PL_sv_undef);

void
DESTROY(self_sv)
    SV *self_sv
PREINIT:
    AV *self;
    SV **closed_ref, **handle_ref;
CODE:
    if (!SvROK(self_sv)) return;
    if (SvTYPE(SvRV(self_sv)) != SVt_PVAV) {
        /* Bare blessed-IV-ref handle: free underlying C struct now. */
        maybe_free_handle(aTHX_ self_sv);
        return;
    }
    self = (AV *)SvRV(self_sv);
    closed_ref = av_fetch(self, R_CLOSED, 0);
    if (closed_ref && *closed_ref && SvTRUE(*closed_ref)) return;
    handle_ref = av_fetch(self, R_HANDLE, 0);
    if (handle_ref && *handle_ref) maybe_free_handle(aTHX_ *handle_ref);

# ====================================================================
MODULE = File::Raw::Archive   PACKAGE = File::Raw::Archive::Writer
# ====================================================================

void
add(...)
PPCODE:
{
    if (items < 1)
        croak("Usage: \\$writer->add(name => ..., content => ..., ...)");
    SV *self_sv = ST(0);
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV)
        croak("File::Raw::Archive::Writer::add: invalid invocant");
    AV *self = (AV *)SvRV(self_sv);
    if ((items - 1) % 2 != 0)
        croak("File::Raw::Archive::Writer::add: odd number of fields");

    HV *fields = newHV();
    sv_2mortal((SV *)fields);
    SV *content_sv = NULL;
    int i;
    for (i = 1; i + 1 < items; i += 2) {
        STRLEN klen;
        const char *kp = SvPV(ST(i), klen);
        if (klen == 7 && memcmp(kp, "content", 7) == 0) {
            content_sv = ST(i + 1);
        } else {
            hv_store(fields, kp, klen, newSVsv(ST(i + 1)), 0);
        }
    }

    /* Default type by name suffix or link_target presence. */
    {
        SV **type_ref = hv_fetchs(fields, "type", 0);
        if (!type_ref || !*type_ref || !SvOK(*type_ref)) {
            int type = AE_FILE;
            SV **name_ref = hv_fetchs(fields, "name", 0);
            SV **link_ref = hv_fetchs(fields, "link_target", 0);
            int has_link = (link_ref && *link_ref && SvOK(*link_ref));
            if (name_ref && *name_ref && SvOK(*name_ref)) {
                STRLEN nl;
                const char *np = SvPV(*name_ref, nl);
                if (nl > 0 && np[nl - 1] == '/')      type = AE_DIR;
                else if (has_link)                    type = AE_SYMLINK;
                else                                  type = AE_FILE;
            } else if (has_link) {
                type = AE_SYMLINK;
            }
            hv_stores(fields, "type", newSViv(type));
        }
    }
    /* Default mode by type. */
    {
        SV **mode_ref = hv_fetchs(fields, "mode", 0);
        if (!mode_ref || !*mode_ref || !SvOK(*mode_ref)) {
            SV **t = hv_fetchs(fields, "type", 0);
            int type = (t && *t) ? (int)SvIV(*t) : AE_FILE;
            IV mode = (type == AE_DIR     ? 0755
                     : type == AE_SYMLINK ? 0777
                     :                      0644);
            hv_stores(fields, "mode", newSViv(mode));
        }
    }

    SV **handle_ref = av_fetch(self, W_HANDLE, 0);
    if (!handle_ref || !*handle_ref)
        croak("File::Raw::Archive::Writer::add: missing handle");
    archive_handle_t *h = unwrap_handle(aTHX_ *handle_ref);
    if (!h || !h->is_writer)
        croak("File::Raw::Archive::Writer::add: invalid handle");

    ArchiveEntry e;
    ArchiveXattr xbuf[64];
    size_t xused = 0;
    hv_to_entry(aTHX_ fields, &e, xbuf, sizeof xbuf / sizeof xbuf[0], &xused);

    STRLEN clen = 0;
    const char *cp = NULL;
    if (content_sv && SvOK(content_sv)) {
        cp = SvPV(content_sv, clen);
        if (e.size == 0 && clen > 0) e.size = clen;
    }

    if (h->plugin->write_add(aTHX_ h->plugin, h->cursor, &e, cp, clen) < 0)
        croak("File::Raw::Archive::Writer::add: write failed (entry exceeds format limits?)");

    XSRETURN_YES;
}

void
close(self_sv)
    SV *self_sv
PREINIT:
    AV *self;
    SV **closed_ref, **handle_ref;
CODE:
    if (!SvROK(self_sv)) return;
    if (SvTYPE(SvRV(self_sv)) != SVt_PVAV) {
        maybe_free_handle(aTHX_ self_sv);
        return;
    }
    self = (AV *)SvRV(self_sv);
    closed_ref = av_fetch(self, W_CLOSED, 0);
    if (closed_ref && *closed_ref && SvTRUE(*closed_ref)) return;
    av_store(self, W_CLOSED, newSViv(1));
    handle_ref = av_fetch(self, W_HANDLE, 0);
    if (handle_ref && *handle_ref) maybe_free_handle(aTHX_ *handle_ref);
    av_store(self, W_HANDLE, &PL_sv_undef);

void
DESTROY(self_sv)
    SV *self_sv
PREINIT:
    AV *self;
    SV **closed_ref, **handle_ref;
CODE:
    if (!SvROK(self_sv)) return;
    if (SvTYPE(SvRV(self_sv)) != SVt_PVAV) {
        maybe_free_handle(aTHX_ self_sv);
        return;
    }
    self = (AV *)SvRV(self_sv);
    closed_ref = av_fetch(self, W_CLOSED, 0);
    if (closed_ref && *closed_ref && SvTRUE(*closed_ref)) return;
    handle_ref = av_fetch(self, W_HANDLE, 0);
    if (handle_ref && *handle_ref) maybe_free_handle(aTHX_ *handle_ref);

# ====================================================================
MODULE = File::Raw::Archive   PACKAGE = File::Raw::Archive::Entry
# ====================================================================
#
# Entry is a blessed hashref with:
#   reader  => Reader hashref (back-link, carries the C handle)
#   meta    => entry-metadata hashref (name, size, mode, ...)
#   slurped => undef OR the cached payload SV
#
# Accessors fetch from `meta`. slurp pulls payload via the reader's
# handle and caches it so a second slurp returns the same bytes.

# Macro-style helper: read a key from $self->{meta} and return it,
# or undef. Used by every accessor.

SV *
name(self_sv)
    SV *self_sv
ALIAS:
    File::Raw::Archive::Entry::name        = M_NAME
    File::Raw::Archive::Entry::size        = M_SIZE
    File::Raw::Archive::Entry::mode        = M_MODE
    File::Raw::Archive::Entry::mtime       = M_MTIME
    File::Raw::Archive::Entry::mtime_ns    = M_MTIME_NS
    File::Raw::Archive::Entry::uid         = M_UID
    File::Raw::Archive::Entry::gid         = M_GID
    File::Raw::Archive::Entry::type        = M_TYPE
    File::Raw::Archive::Entry::link_target = M_LINK_TARGET
    File::Raw::Archive::Entry::xattrs      = M_XATTRS
    File::Raw::Archive::Entry::is_sparse   = M_IS_SPARSE
PREINIT:
    AV *self, *meta;
    SV **meta_ref, **val;
CODE:
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV)
        XSRETURN_UNDEF;
    self = (AV *)SvRV(self_sv);
    meta_ref = av_fetch(self, E_META, 0);
    if (!meta_ref || !*meta_ref || !SvROK(*meta_ref)
            || SvTYPE(SvRV(*meta_ref)) != SVt_PVAV)
        XSRETURN_UNDEF;
    meta = (AV *)SvRV(*meta_ref);
    val = av_fetch(meta, ix, 0);
    if (!val || !*val || !SvOK(*val)) {
        /* Numeric defaults for the integer-shaped accessors. */
        switch (ix) {
        case M_SIZE: case M_MODE: case M_MTIME: case M_MTIME_NS:
        case M_UID:  case M_GID:  case M_TYPE:  case M_IS_SPARSE:
            RETVAL = newSViv(0);
            break;
        default:
            XSRETURN_UNDEF;
        }
    } else {
        RETVAL = SvREFCNT_inc(*val);
    }
OUTPUT:
    RETVAL

IV
is_file(self_sv)
    SV *self_sv
ALIAS:
    File::Raw::Archive::Entry::is_file    = 1
    File::Raw::Archive::Entry::is_dir     = 2
    File::Raw::Archive::Entry::is_symlink = 3
    File::Raw::Archive::Entry::is_link    = 4
PREINIT:
    AV *self, *meta;
    SV **meta_ref, **type_ref;
    IV t;
CODE:
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV)
        XSRETURN_IV(0);
    self = (AV *)SvRV(self_sv);
    meta_ref = av_fetch(self, E_META, 0);
    if (!meta_ref || !*meta_ref || !SvROK(*meta_ref)
            || SvTYPE(SvRV(*meta_ref)) != SVt_PVAV)
        XSRETURN_IV(0);
    meta = (AV *)SvRV(*meta_ref);
    type_ref = av_fetch(meta, M_TYPE, 0);
    t = (type_ref && *type_ref && SvOK(*type_ref))
        ? SvIV(*type_ref) : (IV)AE_FILE;
    switch (ix) {
    case 1: RETVAL = (t == AE_FILE)    ? 1 : 0; break;
    case 2: RETVAL = (t == AE_DIR)     ? 1 : 0; break;
    case 3: RETVAL = (t == AE_SYMLINK) ? 1 : 0; break;
    case 4: RETVAL = (t == AE_SYMLINK || t == AE_HARDLINK) ? 1 : 0; break;
    default: RETVAL = 0;
    }
OUTPUT:
    RETVAL

# slurp: pull the entry's payload bytes via the reader's plugin/cursor.
# Memoised in $self->{slurped} so a second call returns the same SV.

SV *
slurp(self_sv)
    SV *self_sv
PREINIT:
    AV *self, *reader_av;
    SV **slurped_ref, **reader_ref, **handle_ref;
    archive_handle_t *h;
    char buf[64 * 1024];
    int n;
    SV *result;
CODE:
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV)
        croak("File::Raw::Archive::Entry::slurp: invalid invocant");
    self = (AV *)SvRV(self_sv);
    slurped_ref = av_fetch(self, E_SLURPED, 0);
    if (slurped_ref && *slurped_ref && SvOK(*slurped_ref)) {
        RETVAL = SvREFCNT_inc(*slurped_ref);
    } else {
        reader_ref = av_fetch(self, E_READER, 0);
        if (!reader_ref || !*reader_ref || !SvROK(*reader_ref)
                || SvTYPE(SvRV(*reader_ref)) != SVt_PVAV)
            croak("File::Raw::Archive::Entry::slurp: missing reader");
        reader_av = (AV *)SvRV(*reader_ref);
        handle_ref = av_fetch(reader_av, R_HANDLE, 0);
        if (!handle_ref || !*handle_ref)
            croak("File::Raw::Archive::Entry::slurp: missing handle");
        h = unwrap_handle(aTHX_ *handle_ref);
        if (!h || h->is_writer)
            croak("File::Raw::Archive::Entry::slurp: invalid handle");
        result = newSVpvn("", 0);
        while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                         buf, sizeof buf)) > 0) {
            sv_catpvn(result, buf, n);
        }
        if (n < 0) {
            SvREFCNT_dec(result);
            croak("File::Raw::Archive::Entry::slurp: read_data failed");
        }
        /* Memoise + mark reader's cur_entry as consumed. */
        av_store(self,      E_SLURPED,  SvREFCNT_inc(result));
        av_store(reader_av, R_CONSUMED, newSViv(1));
        RETVAL = result;
    }
OUTPUT:
    RETVAL

SV *
read(self_sv, n_sv)
    SV *self_sv
    SV *n_sv
PREINIT:
    AV *self, *reader_av;
    SV **reader_ref, **handle_ref;
    archive_handle_t *h;
    UV want;
    SV *result;
    char buf[64 * 1024];
    int got;
CODE:
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV)
        croak("File::Raw::Archive::Entry::read: invalid invocant");
    self = (AV *)SvRV(self_sv);
    reader_ref = av_fetch(self, E_READER, 0);
    if (!reader_ref || !*reader_ref || !SvROK(*reader_ref)
            || SvTYPE(SvRV(*reader_ref)) != SVt_PVAV)
        croak("File::Raw::Archive::Entry::read: missing reader");
    reader_av = (AV *)SvRV(*reader_ref);
    handle_ref = av_fetch(reader_av, R_HANDLE, 0);
    if (!handle_ref || !*handle_ref)
        croak("File::Raw::Archive::Entry::read: missing handle");
    h = unwrap_handle(aTHX_ *handle_ref);
    if (!h || h->is_writer)
        croak("File::Raw::Archive::Entry::read: invalid handle");
    if (!n_sv || !SvOK(n_sv))
        croak("File::Raw::Archive::Entry::read: byte count required");
    want = SvUV(n_sv);
    result = newSVpvn("", 0);
    while ((UV)SvCUR(result) < want) {
        size_t chunk = sizeof buf;
        UV remain = want - (UV)SvCUR(result);
        if (remain < chunk) chunk = (size_t)remain;
        got = h->plugin->read_data(aTHX_ h->plugin, h->cursor, buf, chunk);
        if (got < 0) {
            SvREFCNT_dec(result);
            croak("File::Raw::Archive::Entry::read: read_data failed");
        }
        if (got == 0) break;
        sv_catpvn(result, buf, got);
    }
    RETVAL = result;
OUTPUT:
    RETVAL

void
_skip(self_sv)
    SV *self_sv
ALIAS:
    File::Raw::Archive::Entry::_skip  = 0
    File::Raw::Archive::Entry::_drain = 1
PREINIT:
    AV *self, *reader_av;
    SV **reader_ref, **handle_ref, **consumed_ref;
    archive_handle_t *h;
    char buf[16 * 1024];
    int n;
CODE:
    PERL_UNUSED_VAR(ix);
    if (!SvROK(self_sv) || SvTYPE(SvRV(self_sv)) != SVt_PVAV) return;
    self = (AV *)SvRV(self_sv);
    reader_ref = av_fetch(self, E_READER, 0);
    if (!reader_ref || !*reader_ref || !SvROK(*reader_ref)
            || SvTYPE(SvRV(*reader_ref)) != SVt_PVAV) return;
    reader_av = (AV *)SvRV(*reader_ref);
    consumed_ref = av_fetch(reader_av, R_CONSUMED, 0);
    if (consumed_ref && *consumed_ref && SvTRUE(*consumed_ref)) return;
    handle_ref = av_fetch(reader_av, R_HANDLE, 0);
    if (!handle_ref || !*handle_ref) return;
    h = unwrap_handle(aTHX_ *handle_ref);
    if (!h) return;
    while ((n = h->plugin->read_data(aTHX_ h->plugin, h->cursor,
                                     buf, sizeof buf)) > 0) {}
    if (n < 0)
        croak("File::Raw::Archive::Entry::_skip: read_data failed");
    av_store(reader_av, R_CONSUMED, newSViv(1));

SV *
_new(class_sv, reader_sv, meta_sv)
    SV *class_sv
    SV *reader_sv
    SV *meta_sv
PREINIT:
    AV *self;
    const char *cls;
CODE:
    cls = SvPV_nolen(class_sv);
    self = newAV();
    av_extend(self, E_SLOT_COUNT - 1);
    av_store(self, E_READER, SvREFCNT_inc(reader_sv));
    av_store(self, E_META,   SvREFCNT_inc(meta_sv));
    RETVAL = sv_bless(newRV_noinc((SV *)self), gv_stashpv(cls, GV_ADD));
OUTPUT:
    RETVAL

# ====================================================================
MODULE = File::Raw::Archive   PACKAGE = File::Raw::Archive
# ====================================================================
#
# Function-style entry points: callable as plain functions instead of
# class methods, so they slot into File::Raw's `file_<verb>` family.
# Same semantics as the matching class methods minus the leading
# `$class` arg. Imported into the caller's package via `import` below.

SV *
file_archive_open(...)
PPCODE:
{
    if (items < 1)
        croak("Usage: file_archive_open(\\$path, %%opts)");
    if ((items - 1) % 2 != 0)
        croak("file_archive_open: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(1), items - 1);
    archive_handle_t *h = open_reader(aTHX_ ST(0), opts);
    SV *handle_sv = new_handle_obj(aTHX_ h, "File::Raw::Archive::Reader");

    AV *self = newAV();
    av_extend(self, R_SLOT_COUNT - 1);
    av_store(self, R_HANDLE,    handle_sv);
    av_store(self, R_CONSUMED,  newSViv(1));
    av_store(self, R_CLOSED,    newSViv(0));
    SV *obj = sv_bless(newRV_noinc((SV *)self),
                       gv_stashpv("File::Raw::Archive::Reader", GV_ADD));
    XPUSHs(sv_2mortal(obj));
    XSRETURN(1);
}

SV *
file_archive_create(...)
PPCODE:
{
    if (items < 1)
        croak("Usage: file_archive_create(\\$path, %%opts)");
    if ((items - 1) % 2 != 0)
        croak("file_archive_create: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(1), items - 1);
    archive_handle_t *h = open_writer(aTHX_ ST(0), opts);
    SV *handle_sv = new_handle_obj(aTHX_ h, "File::Raw::Archive::Writer");

    AV *self = newAV();
    av_extend(self, W_SLOT_COUNT - 1);
    av_store(self, W_HANDLE, handle_sv);
    av_store(self, W_CLOSED, newSViv(0));
    SV *obj = sv_bless(newRV_noinc((SV *)self),
                       gv_stashpv("File::Raw::Archive::Writer", GV_ADD));
    XPUSHs(sv_2mortal(obj));
    XSRETURN(1);
}

SV *
file_archive_list(...)
PPCODE:
{
    if (items < 1)
        croak("Usage: file_archive_list(\\$path, %%opts)");
    if ((items - 1) % 2 != 0)
        croak("file_archive_list: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(1), items - 1);
    archive_handle_t *h = open_reader(aTHX_ ST(0), opts);
    SAVEDESTRUCTOR_X(free_handle_destructor, h);
    SV *result = do_list(aTHX_ h);
    XPUSHs(sv_2mortal(result));
    XSRETURN(1);
}

IV
file_archive_extract(...)
PPCODE:
{
    if (items < 3)
        croak("Usage: file_archive_extract(\\$path, \\$name, \\$dest, %%opts)");
    if ((items - 3) % 2 != 0)
        croak("file_archive_extract: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(3), items - 3);
    int apply_xattrs = 1;
    SV **xv = hv_fetchs(opts, "xattrs", 0);
    if (xv && *xv && SvOK(*xv)) apply_xattrs = SvTRUE(*xv) ? 1 : 0;

    archive_handle_t *h = open_reader(aTHX_ ST(0), opts);
    SAVEDESTRUCTOR_X(free_handle_destructor, h);

    STRLEN match_len;
    const char *match_name = SvPV(ST(1), match_len);
    const char *dest_path  = SvPV_nolen(ST(2));
    IV rc = do_extract_one(aTHX_ h, match_name, match_len, dest_path,
                           apply_xattrs);
    XPUSHs(sv_2mortal(newSViv(rc)));
    XSRETURN(1);
}

IV
file_archive_extract_all(...)
PPCODE:
{
    if (items < 2)
        croak("Usage: file_archive_extract_all(\\$path, \\$dest, %%opts)");
    if ((items - 2) % 2 != 0)
        croak("file_archive_extract_all: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(2), items - 2);
    int apply_xattrs = 1;
    int unsafe_paths = 0;
    int parallel     = 1;
    SV *filter = NULL;
    SV **xv;

    xv = hv_fetchs(opts, "xattrs", 0);
    if (xv && *xv && SvOK(*xv)) apply_xattrs = SvTRUE(*xv) ? 1 : 0;
    xv = hv_fetchs(opts, "unsafe_paths", 0);
    if (xv && *xv && SvOK(*xv)) unsafe_paths = SvTRUE(*xv) ? 1 : 0;
    xv = hv_fetchs(opts, "entry_filter", 0);
    if (xv && *xv && SvOK(*xv)) filter = *xv;
    xv = hv_fetchs(opts, "parallel", 0);
    if (xv && *xv && SvOK(*xv)) parallel = (int)SvIV(*xv);

    if (parallel > 1 && !parallel_supported()) {
        warn("File::Raw::Archive: parallel extract not supported on this "
             "platform; falling back to sequential\n");
        parallel = 1;
    }

    archive_handle_t *h = open_reader(aTHX_ ST(0), opts);
    SAVEDESTRUCTOR_X(free_handle_destructor, h);

    STRLEN dest_len;
    const char *dest = SvPV(ST(1), dest_len);
    if (parallel > 1) {
        do_extract_all_parallel(aTHX_ h, dest, dest_len,
                                parallel, apply_xattrs,
                                filter, unsafe_paths);
    } else {
        do_extract_all_seq(aTHX_ h, dest, dest_len,
                           apply_xattrs, unsafe_paths, filter);
    }
    XPUSHs(sv_2mortal(newSViv(1)));
    XSRETURN(1);
}

void
file_archive_each(...)
PPCODE:
{
    if (items < 2)
        croak("Usage: file_archive_each(\\$path, %%opts, sub { ... })");
    SV *cb_sv = ST(items - 1);
    if (!SvROK(cb_sv) || SvTYPE(SvRV(cb_sv)) != SVt_PVCV)
        croak("file_archive_each: last arg must be a coderef");
    int opts_end = items - 1;
    if ((opts_end - 1) % 2 != 0)
        croak("file_archive_each: odd number of options");
    HV *opts = build_opts_from_args(aTHX_ &ST(1), opts_end - 1);
    SV *filter = NULL;
    SV **xv = hv_fetchs(opts, "entry_filter", 0);
    if (xv && *xv && SvOK(*xv)) filter = *xv;

    archive_handle_t *h = open_reader(aTHX_ ST(0), opts);

    /* Build a Reader AV equivalent so Entry objects can call back. */
    AV *reader_av = newAV();
    av_extend(reader_av, R_SLOT_COUNT - 1);
    av_store(reader_av, R_HANDLE,
             new_handle_obj(aTHX_ h, "File::Raw::Archive::Reader"));
    av_store(reader_av, R_CONSUMED, newSViv(1));
    av_store(reader_av, R_CLOSED,   newSViv(0));
    SV *reader_sv = sv_2mortal(newRV_noinc((SV *)reader_av));
    sv_bless(reader_sv, gv_stashpv("File::Raw::Archive::Reader", GV_ADD));

    do_each(aTHX_ h, reader_sv, cb_sv, filter);
    XSRETURN_EMPTY;
}

# Public surface installer. Called as
#     use File::Raw::Archive qw(import);     # all six
# or  use File::Raw::Archive qw(each list);  # specific subset
# Walks the requested name list and aliases each into the caller's
# stash as `file_archive_<name>`.

void
import(...)
PPCODE:
{
    /* ST(0) is the class. The rest are export-tag style names. */
    static const char * const known_names[] = {
        "open", "create", "list", "each", "extract", "extract_all", NULL
    };
    HV *caller_stash;
    {
        const char *caller_pkg = NULL;
        const PERL_CONTEXT *cx = caller_cx(0, NULL);
        if (cx && CxTYPE(cx) == CXt_SUB) {
            caller_pkg = HvNAME_get(CopSTASH(cx->blk_oldcop));
        }
        if (!caller_pkg) caller_pkg = "main";
        caller_stash = gv_stashpv(caller_pkg, GV_ADD);
    }

    /* If only the bareword "import" is requested, install all known
     * names. Otherwise install just the requested subset. */
    int install_all = 0;
    int i;
    for (i = 1; i < items; i++) {
        if (!SvOK(ST(i))) continue;
        STRLEN nl;
        const char *np = SvPV(ST(i), nl);
        if ((nl == 6 && memcmp(np, "import", 6) == 0)
         || (nl == 4 && memcmp(np, ":all",   4) == 0)) {
            install_all = 1;
            break;
        }
    }

    int n;
    for (n = 0; known_names[n]; n++) {
        const char *name = known_names[n];
        int wanted = install_all;
        if (!wanted) {
            int j;
            for (j = 1; j < items; j++) {
                if (!SvOK(ST(j))) continue;
                STRLEN nl;
                const char *np = SvPV(ST(j), nl);
                if (nl == strlen(name) && memcmp(np, name, nl) == 0) {
                    wanted = 1;
                    break;
                }
            }
        }
        if (!wanted) continue;

        /* Source CV: File::Raw::Archive::file_archive_<name> */
        char src_full[128];
        snprintf(src_full, sizeof src_full,
                 "File::Raw::Archive::file_archive_%s", name);
        CV *src_cv = get_cv(src_full, 0);
        if (!src_cv) {
            warn("File::Raw::Archive::import: %s not installed at BOOT",
                 src_full);
            continue;
        }

        /* Destination CV name: file_archive_<name> in caller's stash. */
        char dst_short[64];
        snprintf(dst_short, sizeof dst_short, "file_archive_%s", name);
        GV *dst_gv = (GV *)*hv_fetch(caller_stash, dst_short,
                                     (I32)strlen(dst_short), 1);
        if (!isGV(dst_gv)) gv_init(dst_gv, caller_stash, dst_short,
                                   strlen(dst_short), GV_ADDMULTI);
        GvCV_set(dst_gv, src_cv);
        SvREFCNT_inc((SV *)src_cv);
    }
    XSRETURN_EMPTY;
}




