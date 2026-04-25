/*
 * file_hooks_impl.h - Hook system implementation
 *
 * Header-only implementation of the C-API declared in file_hooks.h.
 * Inclusion model: a single .c file in each linkable image (Raw.so, plus
 * any test extension that wants to call the hook API directly) #includes
 * this once. The state lives as file-scope statics in that translation
 * unit.
 *
 * Why a header rather than a separate .c shipped alongside Raw:
 *   - Unix builds load Raw.so with RTLD_GLOBAL (and macOS uses flat
 *     namespace), so the *function* symbols dedupe at load time and
 *     external XS extensions transparently mutate Raw.so's hook state.
 *   - Windows/Cygwin can't dedupe across DLLs without an import library
 *     for Raw.dll. Including this header inside the test extension lets
 *     it link cleanly; cross-DLL state sharing is then unavailable on
 *     those platforms (the test suite skips the affected subtests).
 */

#ifndef FILE_HOOKS_IMPL_H
#define FILE_HOOKS_IMPL_H

#include "file_hooks.h"

/* Global hook pointers - NULL when no hooks registered (fast check) */
static file_hook_func g_file_read_hook = NULL;
static void *g_file_read_hook_data = NULL;
static file_hook_func g_file_write_hook = NULL;
static void *g_file_write_hook_data = NULL;

/* Hook linked lists for multiple hooks per phase */
static FileHookEntry *g_file_hooks[4] = { NULL, NULL, NULL, NULL };

void file_set_read_hook(pTHX_ file_hook_func func, void *user_data) {
    PERL_UNUSED_CONTEXT;
    g_file_read_hook = func;
    g_file_read_hook_data = user_data;
}

void file_set_write_hook(pTHX_ file_hook_func func, void *user_data) {
    PERL_UNUSED_CONTEXT;
    g_file_write_hook = func;
    g_file_write_hook_data = user_data;
}

file_hook_func file_get_read_hook(void) {
    return g_file_read_hook;
}

file_hook_func file_get_write_hook(void) {
    return g_file_write_hook;
}

int file_has_hooks(FileHookPhase phase) {
    /* Fast path for simple hooks */
    if (phase == FILE_HOOK_PHASE_READ && g_file_read_hook) return 1;
    if (phase == FILE_HOOK_PHASE_WRITE && g_file_write_hook) return 1;
    /* Check hook list */
    return g_file_hooks[phase] != NULL;
}

int file_register_hook_c(pTHX_ FileHookPhase phase, const char *name,
                         file_hook_func func, int priority, void *user_data) {
    FileHookEntry *entry, *prev, *curr;

    if (phase > FILE_HOOK_PHASE_CLOSE) return 0;

    /* Allocate new entry */
    Newxz(entry, 1, FileHookEntry);
    entry->name = name;  /* Caller owns the string */
    entry->c_func = func;
    entry->perl_callback = NULL;
    entry->priority = priority;
    entry->user_data = user_data;
    entry->next = NULL;

    /* Insert in priority order */
    prev = NULL;
    curr = g_file_hooks[phase];
    while (curr && curr->priority <= priority) {
        prev = curr;
        curr = curr->next;
    }

    if (prev) {
        entry->next = prev->next;
        prev->next = entry;
    } else {
        entry->next = g_file_hooks[phase];
        g_file_hooks[phase] = entry;
    }

    return 1;
}

int file_unregister_hook(pTHX_ FileHookPhase phase, const char *name) {
    FileHookEntry *prev, *curr;
    PERL_UNUSED_CONTEXT;

    if (phase > FILE_HOOK_PHASE_CLOSE) return 0;

    prev = NULL;
    curr = g_file_hooks[phase];
    while (curr) {
        if (strcmp(curr->name, name) == 0) {
            if (prev) {
                prev->next = curr->next;
            } else {
                g_file_hooks[phase] = curr->next;
            }
            if (curr->perl_callback) {
                SvREFCNT_dec(curr->perl_callback);
            }
            Safefree(curr);
            return 1;
        }
        prev = curr;
        curr = curr->next;
    }
    return 0;
}

SV* file_run_hooks(pTHX_ FileHookPhase phase, const char *path, SV *data) {
    FileHookContext ctx;
    FileHookEntry *entry;
    SV *result = data;
    file_hook_func simple_hook = NULL;
    void *simple_data = NULL;

    /* Check simple hooks first */
    if (phase == FILE_HOOK_PHASE_READ && g_file_read_hook) {
        simple_hook = g_file_read_hook;
        simple_data = g_file_read_hook_data;
    } else if (phase == FILE_HOOK_PHASE_WRITE && g_file_write_hook) {
        simple_hook = g_file_write_hook;
        simple_data = g_file_write_hook_data;
    }

    /* Run simple hook if present */
    if (simple_hook) {
        ctx.path = path;
        ctx.data = result;
        ctx.phase = phase;
        ctx.user_data = simple_data;
        ctx.cancel = 0;

        result = simple_hook(aTHX_ &ctx);
        if (!result || ctx.cancel) return NULL;
    }

    /* Run hook chain */
    for (entry = g_file_hooks[phase]; entry; entry = entry->next) {
        ctx.path = path;
        ctx.data = result;
        ctx.phase = phase;
        ctx.user_data = entry->user_data;
        ctx.cancel = 0;

        if (entry->c_func) {
            result = entry->c_func(aTHX_ &ctx);
        } else if (entry->perl_callback) {
            /* Call Perl callback */
            dSP;
            int count;

            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            mXPUSHs(newSVpv(path, 0));
            mXPUSHs(SvREFCNT_inc(result));
            PUTBACK;

            count = call_sv(entry->perl_callback, G_SCALAR);

            SPAGAIN;
            if (count > 0) {
                SV *ret = POPs;
                if (SvOK(ret)) {
                    result = newSVsv(ret);
                } else {
                    ctx.cancel = 1;
                }
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }

        if (!result || ctx.cancel) return NULL;
    }

    return result;
}

#endif /* FILE_HOOKS_IMPL_H */
