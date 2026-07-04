/*
 * marshal.h - Binary job marshalling for parallel extract workers.
 *
 * Replaces Storable nfreeze/thaw on the parallel-extract hot path.
 * One writer (the parent process), one reader per pipe (a child
 * worker), fixed-shape records: no schema discovery overhead, no
 * Perl <-> C round-trip per field.
 *
 * Wire format (all multi-byte ints in network byte order):
 *
 *   [ u32 record_len ]    -- bytes that follow this header
 *   [ u32 path_len    ][ path bytes ][ NUL ]
 *   [ u32 content_len ][ content bytes              ]
 *   [ u32 mode        ]
 *   [ u64 mtime       ][ u32 mtime_ns ]
 *   [ u32 uid         ][ u32 gid      ]
 *   [ u32 apply_xattrs_flag ]
 *   [ u32 xattr_count ]
 *     for each xattr:
 *       [ u32 key_len   ][ key bytes ][ NUL ]
 *       [ u32 value_len ][ value bytes      ]
 *
 * Path and xattr keys carry trailing NULs in the wire so the receiver
 * can pass them straight to syscalls (open/setxattr) without a copy.
 * Lengths exclude the NUL.
 */

#ifndef ARCHIVE_MARSHAL_H
#define ARCHIVE_MARSHAL_H

#include "archive_plugin.h"

#include <stddef.h>
#include <stdint.h>

/* Build a marshalled payload (excludes the leading u32 record_len -
 * marshal_send writes it). *out_payload is malloc'd; caller frees.
 * Returns 0 on success, -1 on out-of-memory. */
int marshal_job(const char *path, size_t path_len,
                const char *content, size_t content_len,
                uint32_t mode,
                uint64_t mtime, uint32_t mtime_ns,
                uint32_t uid, uint32_t gid,
                int apply_xattrs,
                const ArchiveXattr *xattrs, size_t xattr_count,
                char **out_payload, size_t *out_len);

/* Write the leading u32 record_len + payload to fd. Returns 0 on
 * success, -1 on error (errno set). */
int marshal_send(int fd, const char *payload, size_t payload_len);

/* Decoded job. String pointers borrow from the single arena _arena;
 * xattrs[] is a separate small allocation. Free via parallel_job_free. */
typedef struct {
    char         *path;       /* NUL-terminated */
    size_t        path_len;
    char         *content;
    size_t        content_len;
    uint32_t      mode;
    uint64_t      mtime;
    uint32_t      mtime_ns;
    uint32_t      uid;
    uint32_t      gid;
    int           apply_xattrs;
    ArchiveXattr *xattrs;
    size_t        xattr_count;
    char         *_arena;
    size_t        _arena_len;
} ParallelJob;

/* Returns 0 on success, 1 on clean EOF (no more jobs), -1 on error. */
int marshal_read_job(int fd, ParallelJob *out);

void parallel_job_free(ParallelJob *j);

#endif /* ARCHIVE_MARSHAL_H */
