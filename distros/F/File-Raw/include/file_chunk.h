/*
 * file_chunk.h - pull reads for File::Raw
 *
 * File::Raw's streaming has always been push: file_plugin_dispatch_stream
 * opens the path, reads the chunks and feeds them to a plugin's stream
 * phase. That is the right shape when File::Raw owns the loop. It is the
 * wrong shape for a consumer whose own parser owns the loop and asks for
 * bytes when it wants them - a pull reader, an incremental decoder, a
 * state machine fed from more than one source. Such a consumer had
 * nothing to call and fell back to core open/read.
 *
 * These three functions are the pull half. A handle is opened once,
 * read from as often as the caller likes, and closed:
 *
 *     IV h = file_chunk_open(aTHX_ path, 65536);
 *     if (h < 0) { ... errno ... }
 *     for (;;) {
 *         const char *buf;
 *         IV n = file_chunk_read(aTHX_ h, &buf);
 *         if (n < 0) { ... errno ... }
 *         my_parser_feed(p, buf, (size_t)n, n == 0);
 *         if (n == 0) break;
 *     }
 *     file_chunk_close(aTHX_ h);
 *
 * The bytes are not copied: buf points into the handle's own buffer and
 * is valid until the next file_chunk_read on that handle, or its close.
 * A consumer that needs them longer copies them.
 *
 * The Perl surface, File::Raw::chunk_iter, is a thin XSUB over exactly
 * these functions. There is one implementation; this header does not
 * promise a second.
 *
 * Symbol layout follows file_plugin.h: declarations here, implementation
 * in file.c (Raw.so), consumers calling into Raw.so through the exported
 * symbols. Include it after perl.h.
 */

#ifndef FILE_CHUNK_H
#define FILE_CHUNK_H

#include "EXTERN.h"
#include "perl.h"

/* file_plugin.h defines FILE_RAW_API (dllexport while building Raw.dll,
 * dllimport in a consumer, nothing on the GNU toolchains). Including it
 * here keeps this header usable on its own. */
#include "file_plugin.h"

/*
 * Open a file for chunked reading. `size` is the number of bytes a read
 * fills to; it must be greater than zero, and a caller with no opinion
 * should pass 65536. Returns a handle, or -1 with errno set from open(2)
 * - the file is opened O_RDONLY, and O_BINARY as well on Windows, so a
 * consumer does not have to remember that.
 *
 * The handle is an index into a process-global registry shared with the
 * line iterator, not a pointer: the registry is reallocated as it grows,
 * so nothing may hold a pointer into it across calls. It is not shared
 * between interpreter threads.
 */
FILE_RAW_API IV   file_chunk_open (pTHX_ const char *path, size_t size);

/*
 * Read the next chunk. Fills to the handle's size, retrying short reads
 * and EINTR, and returns short only at end of file. On success returns
 * the byte count and sets *buf to the bytes (into the handle's buffer,
 * valid until the next call on this handle); returns 0 at end of file,
 * with *buf set to the buffer and nothing to read; returns -1 with errno
 * set on a read error, with *buf NULL.
 *
 * `buf` may be NULL to skip a chunk. This function never croaks: a
 * consumer in the middle of its own parse wants the errno, not a
 * longjmp past its state.
 */
FILE_RAW_API IV   file_chunk_read (pTHX_ IV handle, const char **buf);

/*
 * Close a handle and release its slot. Safe on a handle that was never
 * opened (-1) and on one already closed; call it once per successful
 * open and discard the handle after, because the slot is reused.
 */
FILE_RAW_API void file_chunk_close(pTHX_ IV handle);

#endif /* FILE_CHUNK_H */
