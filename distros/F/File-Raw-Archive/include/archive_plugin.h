/*
 * archive_plugin.h - Plugin system for File::Raw::Archive
 *
 * An "archive plugin" is a named bundle of read/write phase callbacks
 * for a specific archive format (tar, zip, cpio, ar). Sister dists
 * register additional formats at BOOT time the same way File::Raw's
 * file_plugin.h works for byte transforms.
 *
 * Symbols are exported from Archive.so via RTLD_GLOBAL; downstream
 * modules call into them through the function symbols defined here.
 */

#ifndef ARCHIVE_PLUGIN_H
#define ARCHIVE_PLUGIN_H

#include "EXTERN.h"
#include "perl.h"

#include <stddef.h>
#include <stdint.h>

/* Entry types. Matches POSIX archive flavours. */
typedef enum {
    AE_FILE     = 1,
    AE_DIR      = 2,
    AE_SYMLINK  = 3,
    AE_HARDLINK = 4,
    AE_FIFO     = 5,
    AE_CHAR     = 6,
    AE_BLOCK    = 7,
    AE_OTHER    = 8
} ArchiveEntryType;

/* One xattr entry. The plugin owns the storage; freed on
 * read_close / write completion. */
typedef struct {
    const char *key;     /* e.g. "user.checksum" */
    size_t      key_len;
    const char *value;   /* arbitrary bytes (binary-safe) */
    size_t      value_len;
} ArchiveXattr;

/* Per-entry metadata. The plugin populates this on read_next; the
 * Archive layer populates it on write_add. Pointers are borrowed from
 * plugin-owned storage with a lifetime of "until the next read_next /
 * write_add or close". */
typedef struct {
    const char *name;
    size_t      name_len;
    uint64_t    size;        /* content length in bytes */
    uint64_t    mtime;       /* unix epoch seconds */
    uint32_t    mtime_ns;    /* fractional nanoseconds 0..999_999_999 */
    uint32_t    mode;        /* POSIX mode bits */
    uint32_t    uid;
    uint32_t    gid;
    int         type;        /* ArchiveEntryType */
    const char *link_target;
    size_t      link_target_len;
    int         is_sparse;
    const ArchiveXattr *xattrs;
    size_t              xattr_count;
    void       *priv;        /* plugin-private scratch */
} ArchiveEntry;

/* Byte source/sink: the Archive layer wires these to either real fds
 * or a streaming codec (e.g. gzip inflater). The plugin sees a uniform
 * pull/push interface and never knows the difference. */

/* Returns bytes read, 0 = EOF, -1 = error. */
typedef int (*archive_pull_fn)(void *src_state, char *buf, size_t len);

/* Returns bytes written, -1 = error. */
typedef int (*archive_push_fn)(void *sink_state, const char *buf, size_t len);

typedef struct ArchivePlugin ArchivePlugin;

/* Read-side phases. */
typedef int  (*archive_read_open_fn) (pTHX_ const ArchivePlugin *self,
                                      archive_pull_fn pull, void *src,
                                      HV *opts, void **out_cursor);
typedef int  (*archive_read_next_fn) (pTHX_ const ArchivePlugin *self,
                                      void *cursor, ArchiveEntry *out);
typedef int  (*archive_read_data_fn) (pTHX_ const ArchivePlugin *self,
                                      void *cursor, char *buf, size_t len);
typedef void (*archive_read_close_fn)(pTHX_ const ArchivePlugin *self,
                                      void *cursor);

/* Optional. NULL = format does not support random access; the
 * Archive layer falls back to scanning forward via read_next. */
typedef int  (*archive_read_seek_to_fn)(pTHX_ const ArchivePlugin *self,
                                        void *cursor,
                                        const char *name, size_t name_len);

/* Write-side phases. */
typedef int  (*archive_write_open_fn) (pTHX_ const ArchivePlugin *self,
                                       archive_push_fn push, void *sink,
                                       HV *opts, void **out_cursor);
typedef int  (*archive_write_add_fn)  (pTHX_ const ArchivePlugin *self,
                                       void *cursor,
                                       const ArchiveEntry *entry,
                                       const char *content, size_t len);
typedef int  (*archive_write_close_fn)(pTHX_ const ArchivePlugin *self,
                                       void *cursor);

/* Magic-byte sniffing for plugin => 'auto'. Receives up to `len` bytes
 * from the start of the archive; returns confidence 0..100. */
typedef int  (*archive_probe_fn)(const char *bytes, size_t len);

struct ArchivePlugin {
    const char                  *name;
    archive_probe_fn             probe;
    archive_read_open_fn         read_open;
    archive_read_next_fn         read_next;
    archive_read_data_fn         read_data;
    archive_read_close_fn        read_close;
    archive_read_seek_to_fn      read_seek_to;
    archive_write_open_fn        write_open;
    archive_write_add_fn         write_add;
    archive_write_close_fn       write_close;
    void                        *state;
};

/* Registry. Mirrors file_plugin.h's shape so the patterns match. */
int archive_register_plugin(pTHX_ const ArchivePlugin *plugin);
int archive_unregister_plugin(pTHX_ const char *name);
const ArchivePlugin *archive_lookup_plugin(pTHX_ const char *name);
const ArchivePlugin *archive_probe_for(pTHX_ const char *bytes, size_t len);

/* Apply xattrs to an open file descriptor using the platform's native
 * extended-attribute API. Returns 0 on success, -1 on the first
 * error (errno set). On platforms without xattr support (Windows),
 * returns 0 without doing anything. */
int archive_apply_xattrs(int fd, const ArchiveXattr *xattrs, size_t n);

#endif /* ARCHIVE_PLUGIN_H */
