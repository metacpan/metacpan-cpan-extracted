/*
 * arch_io.c - registry + byte source/sink implementations.
 *
 * Mirrors the same shape File::Raw uses for file_plugin.h: a small
 * static array of registered plugins, lookup by name, probe-based
 * auto-detection. Sister dists call archive_register_plugin from BOOT.
 *
 * Byte sources/sinks: fd, membuf, gzip streaming inflater/deflater.
 * The gzip wrappers talk to libz directly; when File::Raw::Gzip 0.02
 * exposes its streaming state machine in gz.h these wrappers can be
 * simplified to a pull-through.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "archive_plugin.h"
#include "arch_io.h"

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <zlib.h>

#ifdef __linux__
# include <sys/xattr.h>
# define ARCHIVE_HAVE_XATTR 1
#endif
#ifdef __APPLE__
# include <sys/xattr.h>
# define ARCHIVE_HAVE_XATTR 1
# define ARCHIVE_DARWIN_XATTR 1
#endif
#if defined(__FreeBSD__) || defined(__DragonFly__)
# include <sys/types.h>
# include <sys/extattr.h>
# define ARCHIVE_HAVE_EXTATTR 1
#endif

/* ============================================================
 * Registry
 * ============================================================ */

#define MAX_ARCHIVE_PLUGINS 16
static const ArchivePlugin *g_plugins[MAX_ARCHIVE_PLUGINS];
static int g_plugin_count = 0;

int
archive_register_plugin(pTHX_ const ArchivePlugin *plugin)
{
    if (!plugin || !plugin->name || !*plugin->name) return -1;
    if (g_plugin_count >= MAX_ARCHIVE_PLUGINS) return -1;
    int i;
    for (i = 0; i < g_plugin_count; i++) {
        if (strcmp(g_plugins[i]->name, plugin->name) == 0) return 0;
    }
    g_plugins[g_plugin_count++] = plugin;
    return 1;
}

int
archive_unregister_plugin(pTHX_ const char *name)
{
    int i, j;
    if (!name) return 0;
    for (i = 0; i < g_plugin_count; i++) {
        if (strcmp(g_plugins[i]->name, name) == 0) {
            for (j = i + 1; j < g_plugin_count; j++) {
                g_plugins[j - 1] = g_plugins[j];
            }
            g_plugin_count--;
            return 1;
        }
    }
    return 0;
}

const ArchivePlugin *
archive_lookup_plugin(pTHX_ const char *name)
{
    int i;
    if (!name) return NULL;
    for (i = 0; i < g_plugin_count; i++) {
        if (strcmp(g_plugins[i]->name, name) == 0) return g_plugins[i];
    }
    return NULL;
}

const ArchivePlugin *
archive_probe_for(pTHX_ const char *bytes, size_t len)
{
    int i, best_score = 0;
    const ArchivePlugin *best = NULL;
    for (i = 0; i < g_plugin_count; i++) {
        if (!g_plugins[i]->probe) continue;
        int score = g_plugins[i]->probe(bytes, len);
        if (score > best_score) {
            best_score = score;
            best = g_plugins[i];
        }
    }
    return best;
}

/* ============================================================
 * fd source / sink
 * ============================================================ */

int
archive_pull_fd(void *state, char *buf, size_t len)
{
    archive_fd_state_t *s = (archive_fd_state_t *)state;
    ssize_t total = 0;
    while ((size_t)total < len) {
        ssize_t n = read(s->fd, buf + total, len - total);
        if (n < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (n == 0) break;  /* EOF */
        total += n;
    }
    return (int)total;
}

int
archive_push_fd(void *state, const char *buf, size_t len)
{
    archive_fd_state_t *s = (archive_fd_state_t *)state;
    size_t total = 0;
    while (total < len) {
        ssize_t n = write(s->fd, buf + total, len - total);
        if (n < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        total += n;
    }
    return (int)total;
}

/* ============================================================
 * membuf source / sink
 * ============================================================ */

int
archive_pull_membuf(void *state, char *buf, size_t len)
{
    archive_membuf_src_t *s = (archive_membuf_src_t *)state;
    size_t avail = (s->pos < s->len) ? (s->len - s->pos) : 0;
    size_t take  = (avail < len) ? avail : len;
    if (take) memcpy(buf, s->buf + s->pos, take);
    s->pos += take;
    return (int)take;
}

void
archive_membuf_sink_init(archive_membuf_sink_t *s)
{
    s->buf = NULL;
    s->cap = 0;
    s->len = 0;
}

void
archive_membuf_sink_free(archive_membuf_sink_t *s)
{
    if (s->buf) free(s->buf);
    s->buf = NULL;
    s->cap = 0;
    s->len = 0;
}

int
archive_push_membuf(void *state, const char *buf, size_t len)
{
    archive_membuf_sink_t *s = (archive_membuf_sink_t *)state;
    if (s->len + len > s->cap) {
        size_t want = s->cap ? s->cap * 2 : 4096;
        while (want < s->len + len) want *= 2;
        char *p = (char *)realloc(s->buf, want);
        if (!p) return -1;
        s->buf = p;
        s->cap = want;
    }
    memcpy(s->buf + s->len, buf, len);
    s->len += len;
    return (int)len;
}

/* ============================================================
 * gzip streaming source
 * ============================================================ */

struct archive_gz_src {
    int      fd;
    z_stream zs;
    int      zs_inited;
    int      stream_end;
    char    *raw;
    size_t   raw_cap;
    int      eof;
};

archive_gz_src_t *
archive_gz_src_new(int fd, size_t chunk_size)
{
    archive_gz_src_t *s = (archive_gz_src_t *)calloc(1, sizeof *s);
    if (!s) return NULL;
    s->fd      = fd;
    s->raw_cap = chunk_size ? chunk_size : ARCHIVE_DEFAULT_CHUNK;
    s->raw     = (char *)malloc(s->raw_cap);
    if (!s->raw) { free(s); return NULL; }
    if (inflateInit2(&s->zs, MAX_WBITS | 32) != Z_OK) {
        free(s->raw);
        free(s);
        return NULL;
    }
    s->zs_inited = 1;
    return s;
}

void
archive_gz_src_free(archive_gz_src_t *s)
{
    if (!s) return;
    if (s->zs_inited) inflateEnd(&s->zs);
    free(s->raw);
    free(s);
}

int
archive_pull_gz(void *state, char *buf, size_t len)
{
    archive_gz_src_t *s = (archive_gz_src_t *)state;
    if (s->stream_end) return 0;

    s->zs.next_out  = (Bytef *)buf;
    s->zs.avail_out = (uInt)len;

    while (s->zs.avail_out > 0) {
        if (s->zs.avail_in == 0 && !s->eof) {
            ssize_t n = read(s->fd, s->raw, s->raw_cap);
            if (n < 0) {
                if (errno == EINTR) continue;
                return -1;
            }
            if (n == 0) {
                s->eof = 1;
            } else {
                s->zs.next_in  = (Bytef *)s->raw;
                s->zs.avail_in = (uInt)n;
            }
        }

        int rc = inflate(&s->zs, s->eof ? Z_FINISH : Z_NO_FLUSH);
        if (rc == Z_STREAM_END) {
            s->stream_end = 1;
            break;
        }
        if (rc == Z_BUF_ERROR && s->eof && s->zs.avail_in == 0) {
            return -1;
        }
        if (rc != Z_OK && rc != Z_BUF_ERROR) return -1;
    }

    return (int)(len - s->zs.avail_out);
}

/* ============================================================
 * gzip streaming sink
 * ============================================================ */

struct archive_gz_sink {
    int      fd;
    z_stream zs;
    int      zs_inited;
    char    *out;
    size_t   out_cap;
};

archive_gz_sink_t *
archive_gz_sink_new(int fd, size_t chunk_size, int level)
{
    archive_gz_sink_t *s = (archive_gz_sink_t *)calloc(1, sizeof *s);
    if (!s) return NULL;
    s->fd      = fd;
    s->out_cap = chunk_size ? chunk_size : ARCHIVE_DEFAULT_CHUNK;
    s->out     = (char *)malloc(s->out_cap);
    if (!s->out) { free(s); return NULL; }
    if (level < 0 || level > 9) level = 6;
    if (deflateInit2(&s->zs, level, Z_DEFLATED, MAX_WBITS | 16, 8,
                     Z_DEFAULT_STRATEGY) != Z_OK) {
        free(s->out);
        free(s);
        return NULL;
    }
    s->zs_inited = 1;
    return s;
}

static int
gz_sink_drain(archive_gz_sink_t *s, int finish)
{
    int flush = finish ? Z_FINISH : Z_NO_FLUSH;
    for (;;) {
        s->zs.next_out  = (Bytef *)s->out;
        s->zs.avail_out = (uInt)s->out_cap;
        int rc = deflate(&s->zs, flush);
        size_t produced = s->out_cap - s->zs.avail_out;
        if (produced) {
            archive_fd_state_t fdst = { s->fd };
            if (archive_push_fd(&fdst, s->out, produced) < 0) return -1;
        }
        if (rc == Z_STREAM_END) return 0;
        if (rc != Z_OK) return -1;
        if (!finish && s->zs.avail_in == 0) return 0;
    }
}

int
archive_push_gz(void *state, const char *buf, size_t len)
{
    archive_gz_sink_t *s = (archive_gz_sink_t *)state;
    s->zs.next_in  = (Bytef *)buf;
    s->zs.avail_in = (uInt)len;
    if (gz_sink_drain(s, 0) < 0) return -1;
    return (int)len;
}

int
archive_gz_sink_finish(archive_gz_sink_t *s)
{
    s->zs.next_in  = NULL;
    s->zs.avail_in = 0;
    return gz_sink_drain(s, 1);
}

void
archive_gz_sink_free(archive_gz_sink_t *s)
{
    if (!s) return;
    if (s->zs_inited) deflateEnd(&s->zs);
    free(s->out);
    free(s);
}

/* ============================================================
 * Cross-platform xattr application
 * ============================================================ */

int
archive_apply_xattrs(int fd, const ArchiveXattr *xattrs, size_t n)
{
    if (!xattrs || !n) return 0;
#if defined(ARCHIVE_HAVE_XATTR)
    size_t i;
    for (i = 0; i < n; i++) {
        char keybuf[256];
        if (xattrs[i].key_len >= sizeof keybuf) { errno = ENAMETOOLONG; return -1; }
        memcpy(keybuf, xattrs[i].key, xattrs[i].key_len);
        keybuf[xattrs[i].key_len] = '\0';
# if defined(ARCHIVE_DARWIN_XATTR)
        if (fsetxattr(fd, keybuf, xattrs[i].value, xattrs[i].value_len, 0, 0) < 0) return -1;
# else
        if (fsetxattr(fd, keybuf, xattrs[i].value, xattrs[i].value_len, 0) < 0) return -1;
# endif
    }
    return 0;
#elif defined(ARCHIVE_HAVE_EXTATTR)
    size_t i;
    for (i = 0; i < n; i++) {
        char keybuf[256];
        if (xattrs[i].key_len >= sizeof keybuf) { errno = ENAMETOOLONG; return -1; }
        memcpy(keybuf, xattrs[i].key, xattrs[i].key_len);
        keybuf[xattrs[i].key_len] = '\0';
        const char *name = keybuf;
        int ns = EXTATTR_NAMESPACE_USER;
        if (strncmp(keybuf, "user.", 5) == 0) name = keybuf + 5;
        else if (strncmp(keybuf, "system.", 7) == 0) {
            name = keybuf + 7;
            ns = EXTATTR_NAMESPACE_SYSTEM;
        }
        if (extattr_set_fd(fd, ns, name, xattrs[i].value, xattrs[i].value_len) < 0) return -1;
    }
    return 0;
#else
    (void)fd;
    return 0;
#endif
}
