/*
 * file_plugin.h - Plugin system for File::Raw
 *
 * A "plugin" is a named bundle of
 * up to four phase callbacks (read / write / record / stream) that
 * downstream XS modules (or pure-Perl code via the bridge) register at
 * BOOT time. Callers opt in per call by passing
 *
 *     File::Raw::slurp($path, plugin => 'csv', sep => ';')
 *
 * Options after the positional args become an HV that is exposed to the
 * plugin via FilePluginContext::options. The HV is per-call and mortal:
 * a plugin must SvREFCNT_inc anything it intends to keep beyond return.
 *
 * Symbol layout follows the same RTLD_GLOBAL pattern as the rest of
 * File::Raw: declarations live here; the implementation lives in
 * file.c (Raw.so), and all other XS modules call into Raw.so through
 * the exported function symbols.
 */

#ifndef FILE_PLUGIN_H
#define FILE_PLUGIN_H

#include "EXTERN.h"
#include "perl.h"

/* Phase identifiers. A plugin only has to implement the phases it cares
 * about; unimplemented phases are NULL function pointers and any caller
 * that requests them gets a croak. */
typedef enum {
    FILE_PLUGIN_PHASE_READ      = 1,  /* whole-file slurp transform           */
    FILE_PLUGIN_PHASE_WRITE     = 2,  /* whole-file spew/append transform     */
    FILE_PLUGIN_PHASE_RECORD    = 3,  /* per-record dispatch (predicate/map)  */
    FILE_PLUGIN_PHASE_STREAM    = 4   /* chunked feed for streaming           */
} FilePluginPhase;

/* Per-call dispatch context. Lifetime: single dispatch call. */
typedef struct FilePluginContext {
    const char  *path;          /* file path, NUL-terminated, may be NULL    */
    SV          *data;          /* read: bytes from disk; write: payload     */
    SV          *callback;      /* per-record cb when streaming, else NULL   */
    HV          *options;       /* per-call opts; mortal; never NULL         */
    int          phase;         /* FILE_PLUGIN_PHASE_*                       */
    int          cancel;        /* set non-zero to cancel op                 */
    void        *plugin_state;  /* opaque, copied from FilePlugin::state     */
    void        *call_state;    /* NULL on entry; plugin scratch slot for    */
                                /* per-dispatch state. Survives across       */
                                /* chunks within one STREAM dispatch; reset  */
                                /* every fresh dispatch. Plugin owns the     */
                                /* alloc/free lifecycle.                     */
} FilePluginContext;

/* Phase function signatures. */
typedef SV*  (*file_plugin_read_fn)   (pTHX_ FilePluginContext *ctx);
typedef SV*  (*file_plugin_write_fn)  (pTHX_ FilePluginContext *ctx);
/* RECORD: returns the record (possibly transformed) to include, or
 * &PL_sv_undef to exclude (caller interprets - grep filters on truthi-
 * ness, map keeps everything non-NULL). Return NULL or set ctx->cancel
 * to abort iteration. */
typedef SV*  (*file_plugin_record_fn) (pTHX_ FilePluginContext *ctx, SV *record);
typedef int  (*file_plugin_stream_fn) (pTHX_ FilePluginContext *ctx,
                                       const char *chunk, size_t len, int eof);

/* Plugin registration block. The caller owns the storage - typically a
 * file-scope static in the BOOT TU - and must keep it alive for as long
 * as the plugin is registered. The registry stores the pointer, not a
 * copy. */
typedef struct FilePlugin {
    const char            *name;
    /* Field names are suffixed with _fn because plain `read`/`write` collide
     * with Perl's host-IO macros on Win32 (PerlLIO_read/PerlLIO_write), which
     * textually expand any `read`/`write` token followed by `(`. */
    file_plugin_read_fn    read_fn;
    file_plugin_write_fn   write_fn;
    file_plugin_record_fn  record_fn;
    file_plugin_stream_fn  stream_fn;
    void                  *state;
} FilePlugin;

/* ============================================
   C registry API (exported from Raw.so via RTLD_GLOBAL)
   ============================================ */

/* Register a plugin. Returns 1 on success, 0 if a plugin with the same
 * name is already registered (use file_unregister_plugin first), -1 on
 * invalid input (NULL plugin, NULL/empty name). */
int file_register_plugin(pTHX_ const FilePlugin *plugin);

/* Remove a plugin by name. Returns 1 if found and removed, 0 if not. */
int file_unregister_plugin(pTHX_ const char *name);

/* Look up a plugin by name. Returns the registered struct or NULL. */
const FilePlugin *file_lookup_plugin(pTHX_ const char *name);

/* ============================================
   Dispatch helpers used by File::Raw XSUBs

   Each helper:
   - extracts 'plugin' from the HV (croaks if missing)
   - looks up the plugin (croaks if unknown)
   - confirms the phase function pointer is non-NULL (croaks otherwise)
   - builds a FilePluginContext on the stack
   - invokes the phase function
   ============================================ */

/* READ phase: bytes -> transformed SV. NULL return means cancelled. */
SV*  file_plugin_dispatch_read  (pTHX_ HV *opts, const char *path, SV *bytes);

/* WRITE phase: payload -> bytes SV. NULL return means cancelled. */
SV*  file_plugin_dispatch_write (pTHX_ HV *opts, const char *path, SV *payload);

/* STREAM phase: opens path, reads in chunks, feeds plugin which emits
 * records via cb. Returns &PL_sv_yes on success, NULL on cancel. */
SV*  file_plugin_dispatch_stream(pTHX_ HV *opts, const char *path, SV *cb);

/* RECORD phase: invokes plugin->record once with a single pre-built
 * record. Returns the record value the plugin emitted (caller-mortal-
 * ised) or NULL on cancel. */
SV*  file_plugin_dispatch_record(pTHX_ HV *opts, const char *path, SV *record);

/* ============================================
   Variadic-XSUB option parsing helper

   Pulls (key => value) pairs from ST(start) .. ST(items-1) into a fresh
   HV. Croaks on odd parity or non-string keys. Caller owns the HV and
   must SvREFCNT_dec it after dispatch. Returns NULL when start == items
   (no extra args). The HV always has 'plugin' key after this returns
   (helper croaks otherwise) so dispatch helpers can rely on it.
   ============================================ */
HV*  file_plugin_build_opts(pTHX_ SV **stack, int start, int items,
                            const char *fn_name);

#endif /* FILE_PLUGIN_H */
