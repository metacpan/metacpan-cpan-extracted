/*
 * archive.h - internal helpers for File::Raw::Archive
 *
 * Public archive plugin API lives in archive_plugin.h. This header is
 * for symbols shared between archive.c and the built-in tar.c plugin
 * (and not exported to consumers).
 */

#ifndef ARCHIVE_H
#define ARCHIVE_H

#include "archive_plugin.h"

#include <stddef.h>
#include <stdint.h>

#define ARCHIVE_DEFAULT_CHUNK   (64 * 1024)

/* ============================================================
 * Built-in byte sources / sinks
 * ============================================================ */

/* fd-backed source. State is the fd as int*; pull does read(2). */
typedef struct { int fd; } archive_fd_state_t;
int  archive_pull_fd  (void *state, char *buf, size_t len);
int  archive_push_fd  (void *state, const char *buf, size_t len);

/* memory-buffer source (and sink: dynamic SV-like buffer the layer
 * grows). */
typedef struct {
    const char *buf;
    size_t      len;
    size_t      pos;
} archive_membuf_src_t;
int  archive_pull_membuf(void *state, char *buf, size_t len);

typedef struct {
    char  *buf;
    size_t cap;
    size_t len;
} archive_membuf_sink_t;
int  archive_push_membuf(void *state, const char *buf, size_t len);
void archive_membuf_sink_init(archive_membuf_sink_t *s);
void archive_membuf_sink_free(archive_membuf_sink_t *s);

/* gzip streaming source: wraps an fd through libz inflate. We talk to
 * libz directly here (rather than going through File::Raw::Gzip's
 * not-yet-public-C streaming API). When that API ships in Gzip 0.02,
 * this can be reduced to a thin shim. */
typedef struct archive_gz_src archive_gz_src_t;
archive_gz_src_t *archive_gz_src_new (int fd, size_t chunk_size);
void              archive_gz_src_free(archive_gz_src_t *s);
int               archive_pull_gz   (void *state, char *buf, size_t len);

typedef struct archive_gz_sink archive_gz_sink_t;
archive_gz_sink_t *archive_gz_sink_new (int fd, size_t chunk_size, int level);
int                archive_gz_sink_finish(archive_gz_sink_t *s);
void               archive_gz_sink_free(archive_gz_sink_t *s);
int                archive_push_gz    (void *state, const char *buf, size_t len);

/* ============================================================
 * Built-in tar plugin (registered at BOOT from archive.c)
 * ============================================================ */

extern ArchivePlugin tar_plugin;

#endif /* ARCHIVE_H */
