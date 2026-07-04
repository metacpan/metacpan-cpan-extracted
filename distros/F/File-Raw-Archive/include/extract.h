/*
 * extract.h - reusable per-entry write helpers for File::Raw::Archive.
 *
 * These functions encapsulate the work that was previously inlined in
 * Archive.pm's extract loop (mkpath, sysopen, syswrite, chmod, utime,
 * apply xattrs). Sister archive plugins (Zip, Cpio) can call them
 * directly, and Archive.xs's _extract_all_xs / _extract_one_xs use
 * them to drive the entire iteration in C.
 *
 * Most helpers are pure C (no Perl dependency). The two that drive a
 * plugin cursor (archive_write_entry_data, archive_extract_entry)
 * take pTHX_ because the plugin's read_data callback takes it.
 */

#ifndef ARCHIVE_EXTRACT_H
#define ARCHIVE_EXTRACT_H

#include "EXTERN.h"
#include "perl.h"

#include "archive_plugin.h"

#include <stddef.h>
#include <stdint.h>

/* Recursive mkpath at `mode` (typically 0755). Idempotent: if any
 * component already exists as a directory we leave it alone.
 * Returns 0 on success, -1 with errno set on failure. */
int archive_mkpath(const char *path, uint32_t mode);

/* mkpath of dirname(path). No-op if dirname is empty or "/". */
int archive_make_parent_dir(const char *path);

/* Refuse "/abs/..." and "../foo" / "foo/../bar" / "..". Returns 1 if
 * the path is safe to extract under a destination root, 0 otherwise. */
int archive_path_is_safe(const char *name, size_t name_len);

/* Create a directory entry. Recursive mkpath then chmod to `mode`. */
int archive_extract_dir(const char *out_path, uint32_t mode);

/* Create a symlink. Replaces any existing symlink at the same path
 * (but does NOT replace regular files). */
int archive_extract_symlink(const char *out_path, const char *target);

/* Apply mode/mtime/xattrs to an open fd. mtime can only be applied
 * portably via the path (utime), so this only handles fchmod + xattrs;
 * call archive_apply_metadata_path AFTER close to apply mtime. */
int archive_apply_metadata_fd(int fd, const ArchiveEntry *e, int apply_xattrs);

/* Apply chmod + utime to a path (after close). xattrs not applied
 * here because they're best done via fd. */
int archive_apply_metadata_path(const char *path, const ArchiveEntry *e);

/* Drain the current entry's payload from `cursor` and write into `fd`.
 * Buffers internally (64 KiB stack buffer). Returns 0 on success, -1
 * on read or write error (errno set). */
int archive_write_entry_data(pTHX_ const ArchivePlugin *plugin,
                             void *cursor, int fd);

/* The composite operation: open `out_path` at `e->mode`, write the
 * entry payload, fchmod + apply xattrs, close, utime.
 *
 * On error returns -1 with errno set; *errstage is populated with a
 * static string ("open" / "write" / "chmod" / "xattr" / "utime")
 * naming the syscall that failed - useful for error messages.
 *
 * Does NOT mkpath the parent directory; caller must do that first
 * (typically via archive_make_parent_dir). */
int archive_extract_entry(pTHX_ const ArchivePlugin *plugin,
                          void *cursor,
                          const ArchiveEntry *e,
                          const char *out_path,
                          int apply_xattrs,
                          const char **errstage);

/* Like archive_extract_entry but the content is already in memory
 * rather than coming from a plugin cursor. Used by parallel-extract
 * workers receiving payloads via the marshal layer. No pTHX needed -
 * pure C. */
int archive_extract_bytes(const ArchiveEntry *e,
                          const char *out_path,
                          const char *content, size_t content_len,
                          int apply_xattrs,
                          const char **errstage);

#endif /* ARCHIVE_EXTRACT_H */
