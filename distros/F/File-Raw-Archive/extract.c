/*
 * extract.c - reusable per-entry write helpers (Phase A of XS refactor).
 *
 * Pure C except where the plugin's read_data callback drags pTHX_ in.
 * No callers wired up yet; Phase B onward replaces Perl loops with
 * single XSUB calls into these helpers.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"

#include "archive_plugin.h"
#include "extract.h"

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <utime.h>

#define ARCHIVE_PATH_MAX 4096
#define ARCHIVE_DATA_CHUNK (64 * 1024)

/* ============================================================
 * Path safety
 * ============================================================ */

int
archive_path_is_safe(const char *name, size_t name_len)
{
    size_t i = 0;
    if (name_len == 0) return 0;
    if (name[0] == '/') return 0;            /* absolute */
    while (i < name_len) {
        size_t start = i;
        while (i < name_len && name[i] != '/') i++;
        size_t comp = i - start;
        if (comp == 2 && name[start] == '.' && name[start + 1] == '.') return 0;
        if (i < name_len) i++;               /* skip the '/' */
    }
    return 1;
}

/* ============================================================
 * Recursive mkpath
 * ============================================================ */

int
archive_mkpath(const char *path, uint32_t mode)
{
    char buf[ARCHIVE_PATH_MAX];
    size_t n = strlen(path);
    size_t i;
    if (n == 0) return 0;
    if (n >= sizeof buf) { errno = ENAMETOOLONG; return -1; }
    memcpy(buf, path, n + 1);

    for (i = 0; i <= n; i++) {
        if (buf[i] == '/' || buf[i] == '\0') {
            if (i == 0) continue;            /* leading "/" */
            char saved = buf[i];
            buf[i] = '\0';
            struct stat st;
            if (stat(buf, &st) < 0) {
                if (errno != ENOENT) { buf[i] = saved; return -1; }
                if (mkdir(buf, mode ? mode : 0755) < 0 && errno != EEXIST) {
                    buf[i] = saved;
                    return -1;
                }
            } else if (!S_ISDIR(st.st_mode)) {
                buf[i] = saved;
                errno = ENOTDIR;
                return -1;
            }
            buf[i] = saved;
        }
    }
    return 0;
}

int
archive_make_parent_dir(const char *path)
{
    const char *slash = strrchr(path, '/');
    if (!slash || slash == path) return 0;   /* no parent or "/x" */
    size_t parent_len = (size_t)(slash - path);
    char buf[ARCHIVE_PATH_MAX];
    if (parent_len >= sizeof buf) { errno = ENAMETOOLONG; return -1; }
    memcpy(buf, path, parent_len);
    buf[parent_len] = '\0';
    return archive_mkpath(buf, 0755);
}

/* ============================================================
 * Directory / symlink entries
 * ============================================================ */

int
archive_extract_dir(const char *out_path, uint32_t mode)
{
    if (archive_mkpath(out_path, mode ? (mode & 07777) : 0755) < 0) return -1;
    if (mode) {
        /* mkpath used `mode` for newly-created components; existing
         * components keep their existing mode. Force the leaf to
         * match what the archive wanted. */
        if (chmod(out_path, mode & 07777) < 0) return -1;
    }
    return 0;
}

int
archive_extract_symlink(const char *out_path, const char *target)
{
    struct stat st;
    if (lstat(out_path, &st) == 0 && S_ISLNK(st.st_mode)) {
        unlink(out_path);
    }
    if (symlink(target, out_path) < 0) return -1;
    return 0;
}

/* ============================================================
 * Metadata application
 * ============================================================ */

int
archive_apply_metadata_fd(int fd, const ArchiveEntry *e, int apply_xattrs)
{
    if (e->mode) {
        if (fchmod(fd, e->mode & 07777) < 0) return -1;
    }
    if (apply_xattrs && e->xattrs && e->xattr_count > 0) {
        if (archive_apply_xattrs(fd, e->xattrs, e->xattr_count) < 0) return -1;
    }
    return 0;
}

int
archive_apply_metadata_path(const char *path, const ArchiveEntry *e)
{
    if (e->mode) {
        if (chmod(path, e->mode & 07777) < 0) return -1;
    }
    if (e->mtime) {
        struct utimbuf t;
        t.actime  = (time_t)e->mtime;
        t.modtime = (time_t)e->mtime;
        if (utime(path, &t) < 0) return -1;
    }
    return 0;
}

/* ============================================================
 * Payload pump
 * ============================================================ */

int
archive_write_entry_data(pTHX_ const ArchivePlugin *plugin,
                         void *cursor, int fd)
{
    char buf[ARCHIVE_DATA_CHUNK];
    for (;;) {
        int n = plugin->read_data(aTHX_ plugin, cursor, buf, sizeof buf);
        if (n < 0) return -1;
        if (n == 0) break;                  /* end of entry */
        size_t put = 0;
        while (put < (size_t)n) {
            ssize_t w = write(fd, buf + put, (size_t)n - put);
            if (w < 0) {
                if (errno == EINTR) continue;
                return -1;
            }
            put += (size_t)w;
        }
    }
    return 0;
}

/* ============================================================
 * Composite extract
 * ============================================================ */

int
archive_extract_entry(pTHX_ const ArchivePlugin *plugin,
                      void *cursor,
                      const ArchiveEntry *e,
                      const char *out_path,
                      int apply_xattrs,
                      const char **errstage)
{
    int fd;

    if (errstage) *errstage = NULL;

    fd = open(out_path, O_WRONLY | O_CREAT | O_TRUNC,
              e->mode ? (mode_t)(e->mode & 07777) : (mode_t)0644);
    if (fd < 0) {
        if (errstage) *errstage = "open";
        return -1;
    }

    if (archive_write_entry_data(aTHX_ plugin, cursor, fd) < 0) {
        if (errstage) *errstage = "write";
        int saved = errno;
        close(fd);
        unlink(out_path);
        errno = saved;
        return -1;
    }

    if (archive_apply_metadata_fd(fd, e, apply_xattrs) < 0) {
        if (errstage) *errstage = "chmod_or_xattr";
        int saved = errno;
        close(fd);
        errno = saved;
        return -1;
    }

    if (close(fd) < 0) {
        if (errstage) *errstage = "close";
        return -1;
    }

    if (e->mtime) {
        struct utimbuf t;
        t.actime  = (time_t)e->mtime;
        t.modtime = (time_t)e->mtime;
        if (utime(out_path, &t) < 0) {
            if (errstage) *errstage = "utime";
            return -1;
        }
    }

    return 0;
}

int
archive_extract_bytes(const ArchiveEntry *e,
                      const char *out_path,
                      const char *content, size_t content_len,
                      int apply_xattrs,
                      const char **errstage)
{
    int fd;

    if (errstage) *errstage = NULL;

    fd = open(out_path, O_WRONLY | O_CREAT | O_TRUNC,
              e->mode ? (mode_t)(e->mode & 07777) : (mode_t)0644);
    if (fd < 0) {
        if (errstage) *errstage = "open";
        return -1;
    }

    if (content_len > 0 && content) {
        size_t put = 0;
        while (put < content_len) {
            ssize_t w = write(fd, content + put, content_len - put);
            if (w < 0) {
                if (errno == EINTR) continue;
                if (errstage) *errstage = "write";
                int saved = errno;
                close(fd);
                unlink(out_path);
                errno = saved;
                return -1;
            }
            put += (size_t)w;
        }
    }

    if (archive_apply_metadata_fd(fd, e, apply_xattrs) < 0) {
        if (errstage) *errstage = "chmod_or_xattr";
        int saved = errno;
        close(fd);
        errno = saved;
        return -1;
    }

    if (close(fd) < 0) {
        if (errstage) *errstage = "close";
        return -1;
    }

    if (e->mtime) {
        struct utimbuf t;
        t.actime  = (time_t)e->mtime;
        t.modtime = (time_t)e->mtime;
        if (utime(out_path, &t) < 0) {
            if (errstage) *errstage = "utime";
            return -1;
        }
    }

    return 0;
}
