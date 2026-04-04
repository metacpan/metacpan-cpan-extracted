/*
 * file_hooks.h - Hook system for file module
 *
 * Provides extensible hooks for encoding, transformations, etc.
 * Available from both Perl and C/XS.
 *
 * Design: Lazy approach - just a pointer check, no overhead when unused.
 */

#ifndef FILE_HOOKS_H
#define FILE_HOOKS_H

#include "EXTERN.h"
#include "perl.h"

/* ============================================
   Hook type definitions
   ============================================ */

/* Hook priorities - lower runs first */
typedef enum {
    FILE_HOOK_PRIORITY_FIRST    = 0,
    FILE_HOOK_PRIORITY_EARLY    = 100,
    FILE_HOOK_PRIORITY_NORMAL   = 500,
    FILE_HOOK_PRIORITY_LATE     = 900,
    FILE_HOOK_PRIORITY_LAST     = 1000
} FileHookPriority;

/* Hook phases */
typedef enum {
    FILE_HOOK_PHASE_READ,     /* After reading, before returning */
    FILE_HOOK_PHASE_WRITE,    /* Before writing */
    FILE_HOOK_PHASE_OPEN,     /* Before opening file */
    FILE_HOOK_PHASE_CLOSE     /* After closing file */
} FileHookPhase;

/* Hook context passed to callbacks */
typedef struct {
    const char *path;         /* File path */
    SV *data;                 /* Data SV (may be modified in place) */
    FileHookPhase phase;      /* Which phase */
    void *user_data;          /* User-provided context */
    int cancel;               /* Set to 1 to cancel operation */
} FileHookContext;

/*
 * C hook function signature
 * Return: modified SV (or same SV if unchanged), NULL to cancel
 * The hook receives ownership and must return an SV with proper refcount
 */
typedef SV* (*file_hook_func)(pTHX_ FileHookContext *ctx);

/* Hook registration structure */
typedef struct file_hook_entry {
    const char *name;              /* Hook name for identification */
    file_hook_func c_func;         /* C function (fast path) */
    SV *perl_callback;             /* Perl callback (fallback) */
    int priority;                  /* Execution order */
    void *user_data;               /* User context */
    struct file_hook_entry *next;  /* Linked list for multiple hooks */
} FileHookEntry;

/* ============================================
   C API - For use by other XS modules
   ============================================ */

/*
 * Register a C hook function
 * Returns 1 on success, 0 on failure
 * Thread-safe: No (call during module init only)
 */
int file_register_hook_c(pTHX_
                         FileHookPhase phase,
                         const char *name,
                         file_hook_func func,
                         int priority,
                         void *user_data);

/*
 * Unregister a hook by name
 * Returns 1 if found and removed, 0 if not found
 */
int file_unregister_hook(pTHX_ FileHookPhase phase, const char *name);

/*
 * Check if any hooks are registered for a phase
 * Use this for fast bailout before creating context
 * Returns: 1 if hooks exist, 0 if none
 */
int file_has_hooks(FileHookPhase phase);

/*
 * Execute hooks for a phase
 * Returns: transformed SV, or NULL if cancelled
 * The returned SV may be the same as input or a new one
 */
SV* file_run_hooks(pTHX_ FileHookPhase phase, const char *path, SV *data);

/*
 * Simple single-hook registration (most common case)
 * Overwrites any existing hook for this phase
 * Pass NULL func to clear the hook
 */
void file_set_read_hook(pTHX_ file_hook_func func, void *user_data);
void file_set_write_hook(pTHX_ file_hook_func func, void *user_data);

/*
 * Simple hook check (inline for speed)
 * Returns the hook function or NULL
 */
file_hook_func file_get_read_hook(void);
file_hook_func file_get_write_hook(void);

/* ============================================
   Convenience macros for XS modules
   ============================================ */

/* Fast path check - use before allocating context */
#define FILE_HAS_READ_HOOK()   (file_get_read_hook() != NULL)
#define FILE_HAS_WRITE_HOOK()  (file_get_write_hook() != NULL)

/* Run hook if present, otherwise return original */
#define FILE_RUN_READ_HOOK(path, sv) \
    (FILE_HAS_READ_HOOK() ? file_run_hooks(aTHX_ FILE_HOOK_PHASE_READ, path, sv) : sv)

#define FILE_RUN_WRITE_HOOK(path, sv) \
    (FILE_HAS_WRITE_HOOK() ? file_run_hooks(aTHX_ FILE_HOOK_PHASE_WRITE, path, sv) : sv)

#endif /* FILE_HOOKS_H */
