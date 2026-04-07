/*
 * file.c - Fast IO operations using direct system calls
 *
 * Features:
 * - slurp/spew with minimal overhead
 * - Memory-mapped file access (mmap)
 * - Efficient line iteration
 * - Direct stat access
 * - Windows and POSIX support
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "include/file_compat.h"
#include "include/file_hooks.h"

#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <string.h>

#ifdef _WIN32
    #include <io.h>
    #include <windows.h>
    #include <direct.h>
    /* 
     * Windows compatibility - use Perl's wrapper functions
     * We DON'T redefine open/read/write/close/stat/fstat/access here
     * because Perl's XSUB.h already defines them to work correctly.
     * Just define the flags and other missing bits.
     */
    #define O_RDONLY _O_RDONLY
    #define O_WRONLY _O_WRONLY
    #define O_RDWR _O_RDWR
    #define O_CREAT _O_CREAT
    #define O_TRUNC _O_TRUNC
    #define O_APPEND _O_APPEND
    #define O_BINARY _O_BINARY
    #ifndef S_ISREG
        #define S_ISREG(m) (((m) & _S_IFMT) == _S_IFREG)
    #endif
    #ifndef S_ISDIR
        #define S_ISDIR(m) (((m) & _S_IFMT) == _S_IFDIR)
    #endif
    #define R_OK 4
    #define W_OK 2
    /* ssize_t for Windows */
    #ifndef ssize_t
        #ifdef _WIN64
            typedef __int64 ssize_t;
        #else
            typedef int ssize_t;
        #endif
    #endif
    /* Windows doesn't have real uid/gid - use dummy values */
    #define FILE_FAKE_UID 1000
    #define FILE_FAKE_GID 1000
    /*
     * On Windows with PERL_IMPLICIT_SYS, Perl redefines open() to
     * PerlLIO_open() which only accepts 2 args. Use _open() directly
     * for the 3-arg form (path, flags, mode).
     */
    #define file_open3(path, flags, mode) _open(path, flags, mode)
#else
    #define file_open3(path, flags, mode) open(path, flags, mode)
    #include <unistd.h>
    #include <sys/mman.h>
    #include <utime.h>      /* For utime - more portable than utimes */
    #include <dirent.h>     /* For readdir */
    #if defined(__linux__)
        #include <sys/sendfile.h>  /* Zero-copy file transfer */
    #endif
    #if defined(__APPLE__)
        #include <copyfile.h>      /* macOS native file copy */
    #endif
#endif

/* Default buffer size for reads - 64KB is optimal for most systems */
#define FILE_BUFFER_SIZE 65536

/* Larger buffer for bulk operations */
#define FILE_BULK_BUFFER_SIZE 262144

/* Threshold for mmap-based slurp (4MB) */
#define MMAP_SLURP_THRESHOLD (4 * 1024 * 1024)

/* Branch prediction hints */
#ifndef LIKELY
#if defined(__GNUC__) || defined(__clang__)
    #define LIKELY(x)   __builtin_expect(!!(x), 1)
    #define UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
    #define LIKELY(x)   (x)
    #define UNLIKELY(x) (x)
#endif
#endif

/* posix_fadvise hints for kernel optimization */
#if defined(__linux__) || defined(__FreeBSD__) || defined(__NetBSD__)
    #define HAVE_POSIX_FADVISE 1
    #define advise_sequential(fd, len) posix_fadvise(fd, 0, len, POSIX_FADV_SEQUENTIAL)
    #define advise_dontneed(fd, len) posix_fadvise(fd, 0, len, POSIX_FADV_DONTNEED)
#else
    #define HAVE_POSIX_FADVISE 0
    #define advise_sequential(fd, len) ((void)0)
    #define advise_dontneed(fd, len) ((void)0)
#endif

/* ============================================
   File hooks - lazy approach with simple pointer checks
   ============================================ */

/* Global hook pointers - NULL when no hooks registered (fast check) */
static file_hook_func g_file_read_hook = NULL;
static void *g_file_read_hook_data = NULL;
static file_hook_func g_file_write_hook = NULL;
static void *g_file_write_hook_data = NULL;

/* Hook linked lists for multiple hooks per phase */
static FileHookEntry *g_file_hooks[4] = { NULL, NULL, NULL, NULL };

/* ============================================
   Stat cache - like Perl's _ special filehandle
   ============================================ */
#define STAT_CACHE_PATH_MAX 1024

static struct {
    char path[STAT_CACHE_PATH_MAX];
    Stat_t st;
    int valid;
#ifdef _WIN32
    int uid;
    int gid;
#else
    uid_t uid;
    gid_t gid;
#endif
} g_stat_cache = { "", {0}, 0, 0, 0 };

/* Get cached stat or perform new stat */
static int cached_stat(const char *path, Stat_t *st) {
    dTHX;
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        *st = g_stat_cache.st;
        return 0;
    }
    
    if (stat(path, st) < 0) {
        g_stat_cache.valid = 0;
        return -1;
    }
    
    /* Cache the result */
    size_t len = strlen(path);
    if (len < STAT_CACHE_PATH_MAX) {
        memcpy(g_stat_cache.path, path, len + 1);
        g_stat_cache.st = *st;
#ifdef _WIN32
        /* Windows doesn't have real uid/gid concepts */
        g_stat_cache.uid = FILE_FAKE_UID;
        g_stat_cache.gid = FILE_FAKE_GID;
#else
        g_stat_cache.uid = geteuid();
        g_stat_cache.gid = getegid();
#endif
        g_stat_cache.valid = 1;
    }
    
    return 0;
}

/* Invalidate cache (call after write operations) */
static void invalidate_stat_cache(void) {
    g_stat_cache.valid = 0;
}

/* Invalidate cache for specific path */
static void invalidate_stat_cache_path(const char *path) {
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
}

/* Check readable using cached stat */
static int file_is_readable_cached(const char *path) {
    dTHX;
#ifdef _WIN32
    return access(path, R_OK) == 0;
#else
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    
    if (g_stat_cache.uid == 0) return 1;  /* root can read anything */
    
    if (st.st_uid == g_stat_cache.uid) {
        return (st.st_mode & S_IRUSR) != 0;
    } else if (st.st_gid == g_stat_cache.gid) {
        return (st.st_mode & S_IRGRP) != 0;
    } else {
        return (st.st_mode & S_IROTH) != 0;
    }
#endif
}

/* Check writable using cached stat */
static int file_is_writable_cached(const char *path) {
    dTHX;
#ifdef _WIN32
    return access(path, W_OK) == 0;
#else
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    
    if (g_stat_cache.uid == 0) return 1;  /* root can write anything */
    
    if (st.st_uid == g_stat_cache.uid) {
        return (st.st_mode & S_IWUSR) != 0;
    } else if (st.st_gid == g_stat_cache.gid) {
        return (st.st_mode & S_IWGRP) != 0;
    } else {
        return (st.st_mode & S_IWOTH) != 0;
    }
#endif
}

/* Check executable using cached stat */
static int file_is_executable_cached(const char *path) {
    dTHX;
#ifdef _WIN32
    /* Windows: check file extension for executability */
    const char *ext = strrchr(path, '.');
    if (ext) {
        if (_stricmp(ext, ".exe") == 0 || _stricmp(ext, ".bat") == 0 ||
            _stricmp(ext, ".cmd") == 0 || _stricmp(ext, ".com") == 0) {
            return access(path, R_OK) == 0;
        }
    }
    return 0;
#else
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    
    if (g_stat_cache.uid == 0) return 1;  /* root can execute anything */
    
    if (st.st_uid == g_stat_cache.uid) {
        return (st.st_mode & S_IXUSR) != 0;
    } else if (st.st_gid == g_stat_cache.gid) {
        return (st.st_mode & S_IXGRP) != 0;
    } else {
        return (st.st_mode & S_IXOTH) != 0;
    }
#endif
}

/* Implementation of C API */

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

/* ============================================
   Custom op support for compile-time optimization
   ============================================ */

/* Custom op registrations */
static XOP file_slurp_xop;
static XOP file_spew_xop;
static XOP file_exists_xop;
static XOP file_size_xop;
static XOP file_is_file_xop;
static XOP file_is_dir_xop;
static XOP file_lines_xop;
static XOP file_unlink_xop;
static XOP file_mkdir_xop;
static XOP file_rmdir_xop;
static XOP file_basename_xop;
static XOP file_dirname_xop;
static XOP file_extname_xop;
static XOP file_touch_xop;
static XOP file_clear_stat_cache_xop;
static XOP file_mtime_xop;
static XOP file_atime_xop;
static XOP file_ctime_xop;
static XOP file_mode_xop;
static XOP file_is_link_xop;
static XOP file_is_readable_xop;
static XOP file_is_writable_xop;
static XOP file_is_executable_xop;
static XOP file_readdir_xop;
static XOP file_slurp_raw_xop;
static XOP file_copy_xop;
static XOP file_move_xop;
static XOP file_chmod_xop;
static XOP file_append_xop;
static XOP file_atomic_spew_xop;

/* Forward declarations for internal functions */
static SV* file_slurp_internal(pTHX_ const char *path);
static SV* file_slurp_raw_internal(pTHX_ const char *path);
static int file_spew_internal(pTHX_ const char *path, SV *data);
static int file_append_internal(pTHX_ const char *path, SV *data);
static IV file_size_internal(const char *path);
static IV file_mtime_internal(const char *path);
static IV file_atime_internal(const char *path);
static IV file_ctime_internal(const char *path);
static IV file_mode_internal(const char *path);
static int file_exists_internal(const char *path);
static int file_is_file_internal(const char *path);
static int file_is_dir_internal(const char *path);
static int file_is_link_internal(const char *path);
static int file_is_readable_internal(const char *path);
static int file_is_writable_internal(const char *path);
static int file_is_executable_internal(const char *path);
static AV* file_split_lines(pTHX_ SV *content);
static int file_unlink_internal(const char *path);
static int file_copy_internal(pTHX_ const char *src, const char *dst);
static int file_move_internal(pTHX_ const char *src, const char *dst);
static int file_mkdir_internal(const char *path, int mode);
static int file_rmdir_internal(const char *path);
static int file_touch_internal(const char *path);
static int file_chmod_internal(const char *path, int mode);
static AV* file_readdir_internal(pTHX_ const char *path);
static int file_atomic_spew_internal(pTHX_ const char *path, SV *data);
static SV* file_basename_internal(pTHX_ const char *path);
static SV* file_dirname_internal(pTHX_ const char *path);
static SV* file_extname_internal(pTHX_ const char *path);

/* Typedef for pp functions */
typedef OP* (*file_ppfunc)(pTHX);

/* ============================================
   Custom OP implementations - fastest path
   ============================================ */

/* pp_file_slurp: single path arg on stack - OPTIMIZED HOT PATH */
static OP* pp_file_slurp(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    int fd;
    Stat_t st;
    SV *result;
    char *buf;
    ssize_t n, total;

    /* If hooks registered, use full path with hook support */
    if (g_file_read_hook || g_file_hooks[FILE_HOOK_PHASE_READ]) {
        result = file_slurp_internal(aTHX_ path);
        PUSHs(sv_2mortal(result));  
        PUTBACK;
        return NORMAL;
    }

    /* Fast path: direct syscalls, no hooks */
#ifdef _WIN32
    fd = open(path, O_RDONLY | O_BINARY);
#else
    fd = open(path, O_RDONLY);
#endif
    if (fd < 0) {
        PUSHs(&PL_sv_undef);
        PUTBACK;
        return NORMAL;
    }

    if (fstat(fd, &st) < 0 || !S_ISREG(st.st_mode)) {
        close(fd);
        PUSHs(&PL_sv_undef);
        PUTBACK;
        return NORMAL;
    }

    /* Empty file */
    if (st.st_size == 0) {
        close(fd);
        result = newSVpvs("");
        PUSHs(sv_2mortal(result));
        PUTBACK;
        return NORMAL;
    }

    /* Hint to kernel: sequential read */
    advise_sequential(fd, st.st_size);

    /* Pre-allocate exact size */
    result = newSV(st.st_size + 1);
    SvPOK_on(result);
    buf = SvPVX(result);

#ifndef _WIN32
    /* Large files: use mmap for zero-copy */
    if (st.st_size >= MMAP_SLURP_THRESHOLD) {
        void *map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (map != MAP_FAILED) {
            #ifdef MADV_SEQUENTIAL
            madvise(map, st.st_size, MADV_SEQUENTIAL);
            #endif
            memcpy(buf, map, st.st_size);
            buf[st.st_size] = '\0';
            SvCUR_set(result, st.st_size);
            munmap(map, st.st_size);
            close(fd);
            PUSHs(sv_2mortal(result));
            PUTBACK;
            return NORMAL;
        }
        /* mmap failed, fall through to read */
    }
#endif

    /* Single read - common case for small/medium files */
    n = read(fd, buf, st.st_size);
    if (n == st.st_size) {
        /* Got everything in one read - fast path */
        close(fd);
        buf[n] = '\0';
        SvCUR_set(result, n);
        PUSHs(sv_2mortal(result));
        PUTBACK;
        return NORMAL;
    }
    
    /* Short read or error - need loop */
    if (n < 0) {
        if (errno == EINTR) {
            n = 0;  /* Start from beginning */
        } else {
            close(fd);
            SvREFCNT_dec(result);
            PUSHs(&PL_sv_undef);
            PUTBACK;
            return NORMAL;
        }
    }
    
    total = n;
    while (total < st.st_size) {
        n = read(fd, buf + total, st.st_size - total);
        if (n < 0) {
            if (errno == EINTR) continue;
            close(fd);
            SvREFCNT_dec(result);
            PUSHs(&PL_sv_undef);
            PUTBACK;
            return NORMAL;
        }
        if (n == 0) break;
        total += n;
    }
    
    close(fd);
    buf[total] = '\0';
    SvCUR_set(result, total);
    
    PUSHs(sv_2mortal(result));
    PUTBACK;
    return NORMAL;
}

/* pp_file_spew: path and data on stack */
static OP* pp_file_spew(pTHX) {
    dSP;
    SV *data = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_spew_internal(aTHX_ path, data) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_exists: single path arg on stack */
static OP* pp_file_exists(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_exists_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_size: single path arg on stack */
static OP* pp_file_size(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_size_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_file: single path arg on stack */
static OP* pp_file_is_file(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_file_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_dir: single path arg on stack */
static OP* pp_file_is_dir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_dir_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_lines: single path arg on stack */
static OP* pp_file_lines(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    SV *content = file_slurp_internal(aTHX_ path);
    AV *lines;

    if (content == &PL_sv_undef) {
        lines = newAV();
    } else {
        lines = file_split_lines(aTHX_ content);
        SvREFCNT_dec(content);
    }

    PUSHs(sv_2mortal(newRV_noinc((SV*)lines)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_unlink: single path arg on stack */
static OP* pp_file_unlink(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_unlink_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_clear_stat_cache: optional path arg - clears stat cache */
static OP* pp_file_clear_stat_cache(pTHX) {
    dSP;
    SV *path_sv = POPs;
    
    if (SvOK(path_sv)) {
        /* Clear cache for specific path */
        const char *path = SvPV_nolen(path_sv);
        invalidate_stat_cache_path(path);
    } else {
        /* Clear entire cache */
        invalidate_stat_cache();
    }
    
    PUSHs(&PL_sv_yes);
    PUTBACK;
    return NORMAL;
}

/* pp_file_mkdir: single path arg on stack (mode defaults to 0755) */
static OP* pp_file_mkdir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_mkdir_internal(path, 0755) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_rmdir: single path arg on stack */
static OP* pp_file_rmdir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_rmdir_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_touch: single path arg on stack */
static OP* pp_file_touch(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_touch_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_basename: single path arg on stack */
static OP* pp_file_basename(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(file_basename_internal(aTHX_ path)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_dirname: single path arg on stack */
static OP* pp_file_dirname(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(file_dirname_internal(aTHX_ path)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_extname: single path arg on stack */
static OP* pp_file_extname(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(file_extname_internal(aTHX_ path)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_mtime: single path arg on stack */
static OP* pp_file_mtime(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_mtime_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_atime: single path arg on stack */
static OP* pp_file_atime(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_atime_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_ctime: single path arg on stack */
static OP* pp_file_ctime(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_ctime_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_mode: single path arg on stack */
static OP* pp_file_mode(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(sv_2mortal(newSViv(file_mode_internal(path))));
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_link: single path arg on stack */
static OP* pp_file_is_link(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_link_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_readable: single path arg on stack */
static OP* pp_file_is_readable(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_readable_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_writable: single path arg on stack */
static OP* pp_file_is_writable(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_writable_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_is_executable: single path arg on stack */
static OP* pp_file_is_executable(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_is_executable_internal(path) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_readdir: single path arg on stack */
static OP* pp_file_readdir(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    AV *result = file_readdir_internal(aTHX_ path);
    PUSHs(sv_2mortal(newRV_noinc((SV*)result)));
    PUTBACK;
    return NORMAL;
}

/* pp_file_slurp_raw: single path arg on stack (bypasses hooks) */
static OP* pp_file_slurp_raw(pTHX) {
    dSP;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    SV *result = file_slurp_raw_internal(aTHX_ path);
    PUSHs(sv_2mortal(result));
    PUTBACK;
    return NORMAL;
}

/* pp_file_copy: src and dst on stack */
static OP* pp_file_copy(pTHX) {
    dSP;
    SV *dst_sv = POPs;
    SV *src_sv = POPs;
    const char *src = SvPV_nolen(src_sv);
    const char *dst = SvPV_nolen(dst_sv);
    PUSHs(file_copy_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_move: src and dst on stack */
static OP* pp_file_move(pTHX) {
    dSP;
    SV *dst_sv = POPs;
    SV *src_sv = POPs;
    const char *src = SvPV_nolen(src_sv);
    const char *dst = SvPV_nolen(dst_sv);
    PUSHs(file_move_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_chmod: path and mode on stack */
static OP* pp_file_chmod(pTHX) {
    dSP;
    SV *mode_sv = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    int mode = SvIV(mode_sv);
    PUSHs(file_chmod_internal(path, mode) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_append: path and data on stack */
static OP* pp_file_append(pTHX) {
    dSP;
    SV *data = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_append_internal(aTHX_ path, data) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* pp_file_atomic_spew: path and data on stack */
static OP* pp_file_atomic_spew(pTHX) {
    dSP;
    SV *data = POPs;
    SV *path_sv = POPs;
    const char *path = SvPV_nolen(path_sv);
    PUSHs(file_atomic_spew_internal(aTHX_ path, data) ? &PL_sv_yes : &PL_sv_no);
    PUTBACK;
    return NORMAL;
}

/* ============================================
   Call checkers for compile-time optimization
   ============================================ */

/* 1-arg call checker (slurp, exists, size, is_file, is_dir, lines) */
static OP* file_call_checker_1arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    file_ppfunc ppfunc = (file_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *argop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    /* Navigate to first child */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    /* Get the args: pushmark -> arg -> cv */
    argop = OpSIBLING(pushop);
    if (!argop) return entersubop;

    cvop = OpSIBLING(argop);
    if (!cvop) return entersubop;

    /* Verify exactly 1 arg */
    if (OpSIBLING(argop) != cvop) return entersubop;

    /* Detach arg from tree */
    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(argop, NULL);

    /* Create as OP_NULL first to avoid -DDEBUGGING assertion in newUNOP,
       then convert to OP_CUSTOM */
    newop = newUNOP(OP_NULL, 0, argop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;

    op_free(entersubop);
    return newop;
}

/* 2-arg call checker (spew, append) */
static OP* file_call_checker_2arg(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    file_ppfunc ppfunc = (file_ppfunc)SvIVX(ckobj);
    OP *pushop, *cvop, *pathop, *dataop;
    OP *newop;

    PERL_UNUSED_ARG(namegv);

    /* Navigate to first child */
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) {
        pushop = cUNOPx(pushop)->op_first;
    }

    /* Get the args: pushmark -> path -> data -> cv */
    pathop = OpSIBLING(pushop);
    if (!pathop) return entersubop;

    dataop = OpSIBLING(pathop);
    if (!dataop) return entersubop;

    cvop = OpSIBLING(dataop);
    if (!cvop) return entersubop;

    /* Verify exactly 2 args */
    if (OpSIBLING(dataop) != cvop) return entersubop;

    /* Detach args from tree */
    OpMORESIB_set(pushop, cvop);
    OpLASTSIB_set(pathop, NULL);
    OpLASTSIB_set(dataop, NULL);

    /* Create as OP_NULL first to avoid -DDEBUGGING assertion in newBINOP,
       then convert to OP_CUSTOM */
    newop = newBINOP(OP_NULL, 0, pathop, dataop);
    newop->op_type = OP_CUSTOM;
    newop->op_ppaddr = ppfunc;

    op_free(entersubop);
    return newop;
}

/* Install 1-arg function with call checker */
static void install_file_func_1arg(pTHX_ const char *pkg, const char *name,
                                    XSUBADDR_t xsub, file_ppfunc ppfunc) {
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, file_call_checker_1arg, ckobj);
}

/* Install 2-arg function with call checker */
static void install_file_func_2arg(pTHX_ const char *pkg, const char *name,
                                    XSUBADDR_t xsub, file_ppfunc ppfunc) {
    char full_name[256];
    CV *cv;
    SV *ckobj;

    snprintf(full_name, sizeof(full_name), "%s::%s", pkg, name);
    cv = newXS(full_name, xsub, __FILE__);

    ckobj = newSViv(PTR2IV(ppfunc));
    cv_set_call_checker(cv, file_call_checker_2arg, ckobj);
}

/* ============================================
   Memory-mapped file registry
   ============================================ */

typedef struct {
    void *addr;         /* Mapped address */
    size_t len;         /* Mapped length */
    int refcount;       /* Reference count */
#ifdef _WIN32
    HANDLE file_handle; /* Windows file handle */
    HANDLE map_handle;  /* Windows mapping handle */
#else
    int fd;             /* File descriptor (POSIX) */
#endif
} MmapEntry;

static MmapEntry *g_mmaps = NULL;
static IV g_mmaps_size = 0;
static IV g_mmaps_count = 0;

/* Free list for mmap reuse */
static IV *g_free_mmaps = NULL;
static IV g_free_mmaps_size = 0;
static IV g_free_mmaps_count = 0;

/* ============================================
   Line iterator registry
   ============================================ */

typedef struct {
    int fd;             /* File descriptor */
    char *buffer;       /* Read buffer */
    size_t buf_size;    /* Buffer size */
    size_t buf_pos;     /* Current position in buffer */
    size_t buf_len;     /* Valid data length in buffer */
    int eof;            /* End of file reached */
    int refcount;       /* Reference count */
    char *path;         /* File path (for reopening) */
} LineIterEntry;

static LineIterEntry *g_iters = NULL;
static IV g_iters_size = 0;
static IV g_iters_count = 0;

static IV *g_free_iters = NULL;
static IV g_free_iters_size = 0;
static IV g_free_iters_count = 0;

/* ============================================
   Initialization
   ============================================ */

static int file_initialized = 0;

/* Forward declaration for callback registry init */
static void file_init_callback_registry(pTHX);

static void file_init(pTHX) {
    if (file_initialized) return;

    g_mmaps_size = 16;
    Newxz(g_mmaps, g_mmaps_size, MmapEntry);
    g_free_mmaps_size = 16;
    Newxz(g_free_mmaps, g_free_mmaps_size, IV);

    g_iters_size = 16;
    Newxz(g_iters, g_iters_size, LineIterEntry);
    g_free_iters_size = 16;
    Newxz(g_free_iters, g_free_iters_size, IV);

    /* Initialize callback registry with built-in predicates */
    file_init_callback_registry(aTHX);

    file_initialized = 1;
}

/* ============================================
   Fast slurp - read entire file into SV
   ============================================ */

static SV* file_slurp_internal(pTHX_ const char *path) {
    int fd;
    Stat_t st;
    SV *result;
    char *buf;
    ssize_t total = 0, n;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    /* O_NOATIME avoids updating access time - reduces disk writes */
    #ifdef __linux__
    int open_flags = O_RDONLY | O_NOATIME;
    #else
    int open_flags = O_RDONLY;
    #endif
#endif

    fd = open(path, open_flags);
#ifdef __linux__
    /* Fallback if O_NOATIME fails (not owner) */
    if (fd < 0 && errno == EPERM) {
        fd = open(path, O_RDONLY);
    }
#endif
    if (fd < 0) {
        return &PL_sv_undef;
    }

    if (fstat(fd, &st) < 0) {
        close(fd);
        return &PL_sv_undef;
    }

    /* Hint to kernel: sequential read pattern */
    advise_sequential(fd, st.st_size);

    /* Pre-allocate exact size for regular files */
    if (S_ISREG(st.st_mode) && st.st_size > 0) {
#ifndef _WIN32
        /* For large files, use mmap + memcpy - faster than read() syscalls */
        if (st.st_size >= MMAP_SLURP_THRESHOLD) {
            void *map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (map != MAP_FAILED) {
                /* Hint: we'll read sequentially */
                #ifdef MADV_SEQUENTIAL
                madvise(map, st.st_size, MADV_SEQUENTIAL);
                #endif
                
                result = newSV(st.st_size + 1);
                SvPOK_on(result);
                buf = SvPVX(result);
                memcpy(buf, map, st.st_size);
                buf[st.st_size] = '\0';
                SvCUR_set(result, st.st_size);
                
                munmap(map, st.st_size);
                close(fd);
                goto apply_hooks;
            }
            /* mmap failed, fall through to read() */
        }
#endif
        result = newSV(st.st_size + 1);
        SvPOK_on(result);
        buf = SvPVX(result);

        /* Read in one shot if possible */
        while (total < st.st_size) {
            n = read(fd, buf + total, st.st_size - total);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    } else {
        /* Stream or unknown size - read in chunks */
        size_t capacity = FILE_BUFFER_SIZE;
        result = newSV(capacity);
        SvPOK_on(result);
        buf = SvPVX(result);

        while (1) {
            if (total >= (ssize_t)capacity - 1) {
                capacity *= 2;
                SvGROW(result, capacity);
                buf = SvPVX(result);
            }

            n = read(fd, buf + total, capacity - total - 1);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    }

    close(fd);

apply_hooks:
    /* Run read hooks if registered (lazy - just pointer check) */
    if (g_file_read_hook || g_file_hooks[FILE_HOOK_PHASE_READ]) {
        SV *hooked = file_run_hooks(aTHX_ FILE_HOOK_PHASE_READ, path, result);
        if (!hooked) {
            SvREFCNT_dec(result);
            return &PL_sv_undef;
        }
        if (hooked != result) {
            SvREFCNT_dec(result);
            result = hooked;
        }
    }

    return result;
}

/* ============================================
   Fast slurp binary - same as slurp but explicit
   (bypasses hooks - for raw binary data)
   ============================================ */

static SV* file_slurp_raw_internal(pTHX_ const char *path) {
    int fd;
    Stat_t st;
    SV *result;
    char *buf;
    ssize_t total = 0, n;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    #ifdef __linux__
    int open_flags = O_RDONLY | O_NOATIME;
    #else
    int open_flags = O_RDONLY;
    #endif
#endif

    fd = open(path, open_flags);
#ifdef __linux__
    if (fd < 0 && errno == EPERM) {
        fd = open(path, O_RDONLY);
    }
#endif
    if (fd < 0) {
        return &PL_sv_undef;
    }

    if (fstat(fd, &st) < 0) {
        close(fd);
        return &PL_sv_undef;
    }

    /* Hint to kernel: sequential read pattern */
    advise_sequential(fd, st.st_size);

    if (S_ISREG(st.st_mode) && st.st_size > 0) {
#ifndef _WIN32
        /* For large files, use mmap + memcpy */
        if (st.st_size >= MMAP_SLURP_THRESHOLD) {
            void *map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (map != MAP_FAILED) {
                #ifdef MADV_SEQUENTIAL
                madvise(map, st.st_size, MADV_SEQUENTIAL);
                #endif
                
                result = newSV(st.st_size + 1);
                SvPOK_on(result);
                buf = SvPVX(result);
                memcpy(buf, map, st.st_size);
                buf[st.st_size] = '\0';
                SvCUR_set(result, st.st_size);
                
                munmap(map, st.st_size);
                close(fd);
                return result;
            }
        }
#endif
        result = newSV(st.st_size + 1);
        SvPOK_on(result);
        buf = SvPVX(result);

        while (total < st.st_size) {
            n = read(fd, buf + total, st.st_size - total);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    } else {
        size_t capacity = FILE_BUFFER_SIZE;
        result = newSV(capacity);
        SvPOK_on(result);
        buf = SvPVX(result);

        while (1) {
            if (total >= (ssize_t)capacity - 1) {
                capacity *= 2;
                SvGROW(result, capacity);
                buf = SvPVX(result);
            }

            n = read(fd, buf + total, capacity - total - 1);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                SvREFCNT_dec(result);
                return &PL_sv_undef;
            }
            if (n == 0) break;
            total += n;
        }

        buf[total] = '\0';
        SvCUR_set(result, total);
    }

    close(fd);
    return result;  /* No hooks for raw */
}

static SV* file_slurp_raw(pTHX_ const char *path) {
    return file_slurp_raw_internal(aTHX_ path);
}

/* ============================================
   Fast spew - write SV to file
   ============================================ */

static int file_spew_internal(pTHX_ const char *path, SV *data) {
    int fd;
    const char *buf;
    STRLEN len;
    ssize_t n;
    SV *write_data = data;
    int free_write_data = 0;
#ifdef _WIN32
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
#else
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC;
#endif

    /* Run write hooks if registered (lazy - just pointer check) */
    if (UNLIKELY(g_file_write_hook || g_file_hooks[FILE_HOOK_PHASE_WRITE])) {
        SV *hooked = file_run_hooks(aTHX_ FILE_HOOK_PHASE_WRITE, path, data);
        if (!hooked) {
            return 0;  /* Hook cancelled the write */
        }
        if (hooked != data) {
            write_data = hooked;
            free_write_data = 1;
        }
    }

    buf = SvPV(write_data, len);

    fd = file_open3(path, open_flags, 0644);
    if (UNLIKELY(fd < 0)) {
        if (free_write_data) SvREFCNT_dec(write_data);
        return 0;
    }

#if defined(__linux__)
    /* Pre-allocate space for large files to avoid fragmentation */
    if (len >= 65536) {
        posix_fallocate(fd, 0, len);
    }
#endif

    /* Fast path: single write for common case */
    n = write(fd, buf, len);
    if (LIKELY(n == (ssize_t)len)) {
        close(fd);
        if (free_write_data) SvREFCNT_dec(write_data);
        /* Invalidate cache for this path */
        if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
            g_stat_cache.valid = 0;
        }
        return 1;
    }

    /* Handle partial write or error */
    if (n < 0) {
        if (errno != EINTR) {
            close(fd);
            if (free_write_data) SvREFCNT_dec(write_data);
            return 0;
        }
        n = 0;
    }

    /* Loop for remaining data (rare) */
    {
        ssize_t written = n;
        while ((size_t)written < len) {
            n = write(fd, buf + written, len - written);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                if (free_write_data) SvREFCNT_dec(write_data);
                return 0;
            }
            written += n;
        }
    }

    close(fd);
    if (free_write_data) SvREFCNT_dec(write_data);
    /* Invalidate cache for this path */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
}

/* ============================================
   Fast append - append SV to file
   ============================================ */

static int file_append_internal(pTHX_ const char *path, SV *data) {
    int fd;
    const char *buf;
    STRLEN len;
    ssize_t n;
#ifdef _WIN32
    int open_flags = O_WRONLY | O_CREAT | O_APPEND | O_BINARY;
#else
    int open_flags = O_WRONLY | O_CREAT | O_APPEND;
#endif

    buf = SvPV(data, len);

    fd = file_open3(path, open_flags, 0644);
    if (UNLIKELY(fd < 0)) {
        return 0;
    }

    /* Fast path: single write for common case */
    n = write(fd, buf, len);
    if (LIKELY(n == (ssize_t)len)) {
        close(fd);
        /* Invalidate cache for this path */
        if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
            g_stat_cache.valid = 0;
        }
        return 1;
    }

    /* Handle partial write or error */
    if (n < 0) {
        if (errno != EINTR) {
            close(fd);
            return 0;
        }
        n = 0;
    }

    /* Loop for remaining data (rare) */
    {
        ssize_t written = n;
        while ((size_t)written < len) {
            n = write(fd, buf + written, len - written);
            if (n < 0) {
                if (errno == EINTR) continue;
                close(fd);
                return 0;
            }
            written += n;
        }
    }

    close(fd);
    /* Invalidate cache for this path */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
}

/* ============================================
   Memory-mapped file operations
   ============================================ */

static void ensure_mmaps_capacity(IV needed) {
    if (needed >= g_mmaps_size) {
        IV new_size = g_mmaps_size ? g_mmaps_size * 2 : 16;
        IV i;
        while (new_size <= needed) new_size *= 2;
        Renew(g_mmaps, new_size, MmapEntry);
        for (i = g_mmaps_size; i < new_size; i++) {
            g_mmaps[i].addr = NULL;
            g_mmaps[i].len = 0;
            g_mmaps[i].refcount = 0;
#ifdef _WIN32
            g_mmaps[i].file_handle = INVALID_HANDLE_VALUE;
            g_mmaps[i].map_handle = INVALID_HANDLE_VALUE;
#else
            g_mmaps[i].fd = -1;
#endif
        }
        g_mmaps_size = new_size;
    }
}

static IV alloc_mmap_slot(void) {
    IV idx;

    if (g_free_mmaps_count > 0) {
        return g_free_mmaps[--g_free_mmaps_count];
    }

    ensure_mmaps_capacity(g_mmaps_count);
    idx = g_mmaps_count++;
    return idx;
}

static void free_mmap_slot(IV idx) {
    dTHX;
    MmapEntry *entry;

    if (idx < 0 || idx >= g_mmaps_count) return;

    entry = &g_mmaps[idx];
#ifdef _WIN32
    if (entry->addr) {
        UnmapViewOfFile(entry->addr);
    }
    if (entry->map_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(entry->map_handle);
    }
    if (entry->file_handle != INVALID_HANDLE_VALUE) {
        CloseHandle(entry->file_handle);
    }
    entry->file_handle = INVALID_HANDLE_VALUE;
    entry->map_handle = INVALID_HANDLE_VALUE;
#else
    if (entry->addr && entry->addr != MAP_FAILED) {
        munmap(entry->addr, entry->len);
    }
    if (entry->fd >= 0) {
        close(entry->fd);
    }
    entry->fd = -1;
#endif
    entry->addr = NULL;
    entry->len = 0;
    entry->refcount = 0;

    if (g_free_mmaps_count >= g_free_mmaps_size) {
        g_free_mmaps_size *= 2;
        Renew(g_free_mmaps, g_free_mmaps_size, IV);
    }
    g_free_mmaps[g_free_mmaps_count++] = idx;
}

static IV file_mmap_open(pTHX_ const char *path, int writable) {
    IV idx;
    void *addr;
    size_t file_size;

#ifdef _WIN32
    HANDLE file_handle;
    HANDLE map_handle;
    LARGE_INTEGER size;
    DWORD access = writable ? GENERIC_READ | GENERIC_WRITE : GENERIC_READ;
    DWORD share = FILE_SHARE_READ;
    DWORD protect = writable ? PAGE_READWRITE : PAGE_READONLY;
    DWORD map_access = writable ? FILE_MAP_WRITE : FILE_MAP_READ;

    file_handle = CreateFileA(path, access, share, NULL, OPEN_EXISTING,
                              FILE_ATTRIBUTE_NORMAL, NULL);
    if (file_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }

    if (!GetFileSizeEx(file_handle, &size)) {
        CloseHandle(file_handle);
        return -1;
    }

    if (size.QuadPart == 0) {
        CloseHandle(file_handle);
        return -1;
    }

    file_size = (size_t)size.QuadPart;

    map_handle = CreateFileMappingA(file_handle, NULL, protect, 0, 0, NULL);
    if (map_handle == NULL) {
        CloseHandle(file_handle);
        return -1;
    }

    addr = MapViewOfFile(map_handle, map_access, 0, 0, 0);
    if (addr == NULL) {
        CloseHandle(map_handle);
        CloseHandle(file_handle);
        return -1;
    }

    idx = alloc_mmap_slot();
    g_mmaps[idx].addr = addr;
    g_mmaps[idx].len = file_size;
    g_mmaps[idx].file_handle = file_handle;
    g_mmaps[idx].map_handle = map_handle;
    g_mmaps[idx].refcount = 1;

#else
    int fd;
    Stat_t st;
    int flags = writable ? O_RDWR : O_RDONLY;
    int prot = writable ? (PROT_READ | PROT_WRITE) : PROT_READ;

    fd = open(path, flags);
    if (fd < 0) {
        return -1;
    }

    if (fstat(fd, &st) < 0) {
        close(fd);
        return -1;
    }

    if (st.st_size == 0) {
        /* Can't mmap empty file */
        close(fd);
        return -1;
    }

    file_size = st.st_size;

    addr = mmap(NULL, st.st_size, prot, MAP_SHARED, fd, 0);
    if (addr == MAP_FAILED) {
        close(fd);
        return -1;
    }

    idx = alloc_mmap_slot();
    g_mmaps[idx].addr = addr;
    g_mmaps[idx].len = file_size;
    g_mmaps[idx].fd = fd;
    g_mmaps[idx].refcount = 1;
#endif

    return idx;
}

static SV* file_mmap_get_sv(pTHX_ IV idx) {
    MmapEntry *entry;
    SV *sv;

    if (idx < 0 || idx >= g_mmaps_count) {
        return &PL_sv_undef;
    }

    entry = &g_mmaps[idx];
#ifdef _WIN32
    if (!entry->addr) {
        return &PL_sv_undef;
    }
#else
    if (!entry->addr || entry->addr == MAP_FAILED) {
        return &PL_sv_undef;
    }
#endif

    /* Create an SV that points directly to the mapped memory */
    sv = newSV(0);
    SvUPGRADE(sv, SVt_PV);
    SvPV_set(sv, (char*)entry->addr);
    SvCUR_set(sv, entry->len);
    SvLEN_set(sv, 0);  /* Don't free this memory! */
    SvPOK_on(sv);
    SvREADONLY_on(sv);

    return sv;
}

static void file_mmap_close(IV idx) {
    dTHX;
    if (idx < 0 || idx >= g_mmaps_count) return;

    MmapEntry *entry = &g_mmaps[idx];
    entry->refcount--;
    if (entry->refcount <= 0) {
        free_mmap_slot(idx);
    }
}

static void file_mmap_sync(IV idx) {
    dTHX;
    MmapEntry *entry;

    if (idx < 0 || idx >= g_mmaps_count) return;

    entry = &g_mmaps[idx];
#ifdef _WIN32
    if (entry->addr) {
        FlushViewOfFile(entry->addr, entry->len);
    }
#else
    if (entry->addr && entry->addr != MAP_FAILED) {
        msync(entry->addr, entry->len, MS_SYNC);
    }
#endif
}

/* ============================================
   Line iterator operations
   ============================================ */

static void ensure_iters_capacity(IV needed) {
    if (needed >= g_iters_size) {
        IV new_size = g_iters_size ? g_iters_size * 2 : 16;
        IV i;
        while (new_size <= needed) new_size *= 2;
        Renew(g_iters, new_size, LineIterEntry);
        for (i = g_iters_size; i < new_size; i++) {
            g_iters[i].fd = -1;
            g_iters[i].buffer = NULL;
            g_iters[i].buf_size = 0;
            g_iters[i].buf_pos = 0;
            g_iters[i].buf_len = 0;
            g_iters[i].eof = 0;
            g_iters[i].refcount = 0;
            g_iters[i].path = NULL;
        }
        g_iters_size = new_size;
    }
}

static IV alloc_iter_slot(void) {
    IV idx;

    if (g_free_iters_count > 0) {
        return g_free_iters[--g_free_iters_count];
    }

    ensure_iters_capacity(g_iters_count);
    idx = g_iters_count++;
    return idx;
}

static void free_iter_slot(IV idx) {
    dTHX;
    LineIterEntry *entry;

    if (idx < 0 || idx >= g_iters_count) return;

    entry = &g_iters[idx];
    if (entry->fd >= 0) {
        close(entry->fd);
    }
    if (entry->buffer) {
        Safefree(entry->buffer);
    }
    if (entry->path) {
        Safefree(entry->path);
    }

    entry->fd = -1;
    entry->buffer = NULL;
    entry->buf_size = 0;
    entry->buf_pos = 0;
    entry->buf_len = 0;
    entry->eof = 0;
    entry->refcount = 0;
    entry->path = NULL;

    if (g_free_iters_count >= g_free_iters_size) {
        g_free_iters_size *= 2;
        Renew(g_free_iters, g_free_iters_size, IV);
    }
    g_free_iters[g_free_iters_count++] = idx;
}

static IV file_lines_open(pTHX_ const char *path) {
    int fd;
    IV idx;
    LineIterEntry *entry;
    size_t path_len;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    int open_flags = O_RDONLY;
#endif

    fd = open(path, open_flags);
    if (fd < 0) {
        return -1;
    }

    idx = alloc_iter_slot();
    entry = &g_iters[idx];

    entry->fd = fd;
    entry->buf_size = FILE_BUFFER_SIZE;
    Newx(entry->buffer, entry->buf_size, char);
    entry->buf_pos = 0;
    entry->buf_len = 0;
    entry->eof = 0;
    entry->refcount = 1;

    path_len = strlen(path);
    Newx(entry->path, path_len + 1, char);
    memcpy(entry->path, path, path_len + 1);

    return idx;
}

static SV* file_lines_next(pTHX_ IV idx) {
    LineIterEntry *entry;
    char *line_start;
    char *newline;
    size_t line_len;
    SV *result;
    ssize_t n;

    if (idx < 0 || idx >= g_iters_count) {
        return &PL_sv_undef;
    }

    entry = &g_iters[idx];
    if (entry->fd < 0) {
        return &PL_sv_undef;
    }

    while (1) {
        /* Look for newline in current buffer */
        if (entry->buf_pos < entry->buf_len) {
            line_start = entry->buffer + entry->buf_pos;
            newline = memchr(line_start, '\n', entry->buf_len - entry->buf_pos);

            if (newline) {
                line_len = newline - line_start;
                result = newSVpvn(line_start, line_len);
                entry->buf_pos += line_len + 1;
                return result;
            }
        }

        /* No newline found, need more data */
        if (entry->eof) {
            /* Return remaining data if any */
            if (entry->buf_pos < entry->buf_len) {
                line_len = entry->buf_len - entry->buf_pos;
                result = newSVpvn(entry->buffer + entry->buf_pos, line_len);
                entry->buf_pos = entry->buf_len;
                return result;
            }
            return &PL_sv_undef;
        }

        /* Move remaining data to start of buffer */
        if (entry->buf_pos > 0) {
            size_t remaining = entry->buf_len - entry->buf_pos;
            if (remaining > 0) {
                memmove(entry->buffer, entry->buffer + entry->buf_pos, remaining);
            }
            entry->buf_len = remaining;
            entry->buf_pos = 0;
        }

        /* Expand buffer if needed */
        if (entry->buf_len >= entry->buf_size - 1) {
            entry->buf_size *= 2;
            Renew(entry->buffer, entry->buf_size, char);
        }

        /* Read more data */
        n = read(entry->fd, entry->buffer + entry->buf_len,
                 entry->buf_size - entry->buf_len - 1);
        if (n < 0) {
            if (errno == EINTR) continue;
            return &PL_sv_undef;
        }
        if (n == 0) {
            entry->eof = 1;
        } else {
            entry->buf_len += n;
        }
    }
}

static int file_lines_eof(IV idx) {
    dTHX;
    LineIterEntry *entry;

    if (idx < 0 || idx >= g_iters_count) {
        return 1;
    }

    entry = &g_iters[idx];
    return entry->eof && entry->buf_pos >= entry->buf_len;
}

static void file_lines_close(IV idx) {
    dTHX;
    if (idx < 0 || idx >= g_iters_count) return;

    LineIterEntry *entry = &g_iters[idx];
    entry->refcount--;
    if (entry->refcount <= 0) {
        free_iter_slot(idx);
    }
}

/* ============================================
   Fast stat operations
   ============================================ */

static IV file_size_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_size;
}

static int file_exists_internal(const char *path) {
    dTHX;
    Stat_t st;
    return cached_stat(path, &st) == 0;
}

static int file_is_file_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    return S_ISREG(st.st_mode);
}

static int file_is_dir_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) return 0;
    return S_ISDIR(st.st_mode);
}

static int file_is_readable_internal(const char *path) {
    dTHX;
    return file_is_readable_cached(path);
}

static int file_is_writable_internal(const char *path) {
    dTHX;
    return file_is_writable_cached(path);
}

static IV file_mtime_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_mtime;
}

static IV file_atime_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_atime;
}

static IV file_ctime_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_ctime;
}

static IV file_mode_internal(const char *path) {
    dTHX;
    Stat_t st;
    if (cached_stat(path, &st) < 0) {
        return -1;
    }
    return st.st_mode & 07777;  /* Return permission bits only */
}

/* Combined stat - returns all attributes in one syscall */
static HV* file_stat_all_internal(pTHX_ const char *path) {
    Stat_t st;
    HV *result;

    if (cached_stat(path, &st) < 0) {
        return NULL;
    }

    result = newHV();
    hv_store(result, "size", 4, newSViv(st.st_size), 0);
    hv_store(result, "mtime", 5, newSViv(st.st_mtime), 0);
    hv_store(result, "atime", 5, newSViv(st.st_atime), 0);
    hv_store(result, "ctime", 5, newSViv(st.st_ctime), 0);
    hv_store(result, "mode", 4, newSViv(st.st_mode & 07777), 0);
    hv_store(result, "is_file", 7, S_ISREG(st.st_mode) ? &PL_sv_yes : &PL_sv_no, 0);
    hv_store(result, "is_dir", 6, S_ISDIR(st.st_mode) ? &PL_sv_yes : &PL_sv_no, 0);
    hv_store(result, "dev", 3, newSViv(st.st_dev), 0);
    hv_store(result, "ino", 3, newSViv(st.st_ino), 0);
    hv_store(result, "nlink", 5, newSViv(st.st_nlink), 0);
    hv_store(result, "uid", 3, newSViv(st.st_uid), 0);
    hv_store(result, "gid", 3, newSViv(st.st_gid), 0);

    return result;
}

static int file_is_link_internal(const char *path) {
    dTHX;
#ifdef _WIN32
    /* Windows: check for reparse point */
    DWORD attrs = GetFileAttributesA(path);
    if (attrs == INVALID_FILE_ATTRIBUTES) return 0;
    return (attrs & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
#else
    Stat_t st;
    if (lstat(path, &st) < 0) return 0;
    return S_ISLNK(st.st_mode);
#endif
}

static int file_is_executable_internal(const char *path) {
    dTHX;
#ifdef _WIN32
    /* Windows: check file extension */
    const char *ext = strrchr(path, '.');
    if (ext) {
        if (_stricmp(ext, ".exe") == 0 || _stricmp(ext, ".bat") == 0 ||
            _stricmp(ext, ".cmd") == 0 || _stricmp(ext, ".com") == 0) {
            return 1;
        }
    }
    return 0;
#else
    return file_is_executable_cached(path);
#endif
}

/* ============================================
   File manipulation operations
   ============================================ */

static int file_unlink_internal(const char *path) {
    dTHX;
    int result;
#ifdef _WIN32
    result = _unlink(path) == 0;
#else
    result = unlink(path) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_copy_internal(pTHX_ const char *src, const char *dst) {
#if defined(__APPLE__)
    /* macOS: Use native copyfile() for best performance and metadata */
    Stat_t st;
    int result;
    if (stat(src, &st) < 0) return 0;
    result = copyfile(src, dst, NULL, COPYFILE_DATA) == 0;
    if (result && g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
#elif defined(__linux__)
    /* Linux: Use sendfile() for zero-copy transfer */
    int fd_src, fd_dst;
    Stat_t st;
    off_t offset = 0;
    ssize_t sent;

    fd_src = open(src, O_RDONLY);
    if (fd_src < 0) return 0;

    if (fstat(fd_src, &st) < 0 || !S_ISREG(st.st_mode)) {
        close(fd_src);
        return 0;
    }

    fd_dst = file_open3(dst, O_WRONLY | O_CREAT | O_TRUNC, st.st_mode & 07777);
    if (fd_dst < 0) {
        close(fd_src);
        return 0;
    }

    /* sendfile() for zero-copy - much faster than read/write */
    while (offset < st.st_size) {
        sent = sendfile(fd_dst, fd_src, &offset, st.st_size - offset);
        if (sent < 0) {
            if (errno == EINTR) continue;
            if (errno == EINVAL || errno == ENOSYS) {
                /* sendfile not supported, fallback to read/write */
                char *buffer;
                ssize_t n_read, n_written, written;
                int result = 0;

                /* Reposition to where we left off */
                lseek(fd_src, offset, SEEK_SET);

                Newx(buffer, FILE_BULK_BUFFER_SIZE, char);
                while (1) {
                    n_read = read(fd_src, buffer, FILE_BULK_BUFFER_SIZE);
                    if (n_read < 0) {
                        if (errno == EINTR) continue;
                        break;
                    }
                    if (n_read == 0) { result = 1; break; }

                    written = 0;
                    while (written < n_read) {
                        n_written = write(fd_dst, buffer + written, n_read - written);
                        if (n_written < 0) {
                            if (errno == EINTR) continue;
                            goto fallback_cleanup;
                        }
                        written += n_written;
                    }
                }
fallback_cleanup:
                Safefree(buffer);
                close(fd_src);
                close(fd_dst);
                if (result && g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
                    g_stat_cache.valid = 0;
                }
                return result;
            }
            close(fd_src);
            close(fd_dst);
            return 0;
        }
        if (sent == 0) break;
    }

    close(fd_src);
    close(fd_dst);
    /* Invalidate cache for dst */
    if (g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
#else
    /* Portable fallback: read/write loop */
    int fd_src, fd_dst;
    char *buffer;
    ssize_t n_read, n_written, written;
    Stat_t st;
    int result = 0;
#ifdef _WIN32
    int open_flags_r = O_RDONLY | O_BINARY;
    int open_flags_w = O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
#else
    int open_flags_r = O_RDONLY;
    int open_flags_w = O_WRONLY | O_CREAT | O_TRUNC;
#endif

    fd_src = open(src, open_flags_r);
    if (fd_src < 0) return 0;

    if (fstat(fd_src, &st) < 0) {
        close(fd_src);
        return 0;
    }

    fd_dst = file_open3(dst, open_flags_w, st.st_mode & 07777);
    if (fd_dst < 0) {
        close(fd_src);
        return 0;
    }

    Newx(buffer, FILE_BULK_BUFFER_SIZE, char);

    while (1) {
        n_read = read(fd_src, buffer, FILE_BULK_BUFFER_SIZE);
        if (n_read < 0) {
            if (errno == EINTR) continue;
            goto cleanup;
        }
        if (n_read == 0) break;

        written = 0;
        while (written < n_read) {
            n_written = write(fd_dst, buffer + written, n_read - written);
            if (n_written < 0) {
                if (errno == EINTR) continue;
                goto cleanup;
            }
            written += n_written;
        }
    }

    result = 1;

cleanup:
    Safefree(buffer);
    close(fd_src);
    close(fd_dst);
    if (result && g_stat_cache.valid && strcmp(dst, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
#endif
}

static int file_move_internal(pTHX_ const char *src, const char *dst) {
    int result;
    
    /* Try rename first (fast path for same filesystem) */
    if (rename(src, dst) == 0) {
        result = 1;
    }
    /* If EXDEV, copy then delete (cross-device move) */
    else if (errno == EXDEV) {
        if (file_copy_internal(aTHX_ src, dst)) {
            result = file_unlink_internal(src);
        } else {
            return 0;
        }
    } else {
        return 0;
    }
    
    /* Invalidate cache for both paths */
    if (g_stat_cache.valid) {
        if (strcmp(src, g_stat_cache.path) == 0 || strcmp(dst, g_stat_cache.path) == 0) {
            g_stat_cache.valid = 0;
        }
    }
    return result;
}

static int file_touch_internal(const char *path) {
    dTHX;
    int result;
#ifdef _WIN32
    HANDLE h;
    FILETIME ft;
    SYSTEMTIME st;
    result = 0;

    /* Try to open existing file */
    h = CreateFileA(path, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
                    NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        return 0;
    }

    GetSystemTime(&st);
    SystemTimeToFileTime(&st, &ft);
    result = SetFileTime(h, NULL, &ft, &ft) != 0;
    CloseHandle(h);
#else
    int fd;
    /* Try to update times on existing file - utime(path, NULL) sets to current time */
    if (utime(path, NULL) == 0) {
        result = 1;
    } else {
        /* File doesn't exist, create it */
        fd = file_open3(path, O_WRONLY | O_CREAT, 0644);
        if (fd < 0) {
            return 0;
        }
        close(fd);
        result = 1;
    }
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_chmod_internal(const char *path, int mode) {
    dTHX;
    int result;
#ifdef _WIN32
    result = _chmod(path, mode) == 0;
#else
    result = chmod(path, mode) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_mkdir_internal(const char *path, int mode) {
    dTHX;
    int result;
#ifdef _WIN32
    PERL_UNUSED_VAR(mode);
    result = _mkdir(path) == 0;
#else
    result = mkdir(path, mode) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

static int file_rmdir_internal(const char *path) {
    dTHX;
    int result;
#ifdef _WIN32
    result = _rmdir(path) == 0;
#else
    result = rmdir(path) == 0;
#endif
    /* Invalidate cache if this path was cached */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return result;
}

/* ============================================
   Directory listing
   ============================================ */

static AV* file_readdir_internal(pTHX_ const char *path) {
    AV *result = newAV();

#ifdef _WIN32
    WIN32_FIND_DATAA fd;
    HANDLE h;
    char pattern[MAX_PATH];
    size_t len = strlen(path);

    if (len + 3 > MAX_PATH) return result;

    memcpy(pattern, path, len);
    if (len > 0 && path[len-1] != '\\' && path[len-1] != '/') {
        pattern[len++] = '\\';
    }
    pattern[len++] = '*';
    pattern[len] = '\0';

    h = FindFirstFileA(pattern, &fd);
    if (h == INVALID_HANDLE_VALUE) return result;

    do {
        /* Skip . and .. */
        if (strcmp(fd.cFileName, ".") != 0 && strcmp(fd.cFileName, "..") != 0) {
            av_push(result, newSVpv(fd.cFileName, 0));
        }
    } while (FindNextFileA(h, &fd));

    FindClose(h);
#else
    DIR *dir;
    struct dirent *entry;

    dir = opendir(path);
    if (!dir) return result;

    while ((entry = readdir(dir)) != NULL) {
        /* Skip . and .. */
        if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
            av_push(result, newSVpv(entry->d_name, 0));
        }
    }

    closedir(dir);
#endif

    return result;
}

/* ============================================
   Path manipulation
   ============================================ */

static SV* file_basename_internal(pTHX_ const char *path) {
    const char *p;
    size_t len = strlen(path);

    if (len == 0) return newSVpvs("");

    /* Skip trailing slashes */
    while (len > 0 && (path[len-1] == '/' || path[len-1] == '\\')) {
        len--;
    }
    if (len == 0) return newSVpvs("");

    /* Find last separator */
    p = path + len - 1;
    while (p > path && *p != '/' && *p != '\\') {
        p--;
    }
    if (*p == '/' || *p == '\\') p++;

    return newSVpvn(p, (path + len) - p);
}

static SV* file_dirname_internal(pTHX_ const char *path) {
    const char *end;
    size_t len = strlen(path);

    if (len == 0) return newSVpvs(".");

    /* Skip trailing slashes */
    end = path + len - 1;
    while (end > path && (*end == '/' || *end == '\\')) {
        end--;
    }

    /* Find last separator */
    while (end > path && *end != '/' && *end != '\\') {
        end--;
    }

    if (end == path) {
        if (*end == '/' || *end == '\\') {
            return newSVpvn(path, 1);
        }
        return newSVpvs(".");
    }

    /* Skip multiple trailing slashes in dirname */
    while (end > path && (*(end-1) == '/' || *(end-1) == '\\')) {
        end--;
    }

    return newSVpvn(path, end - path);
}

static SV* file_extname_internal(pTHX_ const char *path) {
    const char *dot;
    const char *basename;
    size_t len = strlen(path);

    if (len == 0) return newSVpvs("");

    /* Find basename first */
    basename = path + len - 1;
    while (basename > path && *basename != '/' && *basename != '\\') {
        basename--;
    }
    if (*basename == '/' || *basename == '\\') basename++;

    /* Find last dot in basename */
    dot = strrchr(basename, '.');
    if (!dot || dot == basename) return newSVpvs("");

    return newSVpv(dot, 0);
}

static SV* file_join_internal(pTHX_ AV *parts) {
    SV *result;
    SSize_t i, len;
    STRLEN total_len = 0;
    char *buf, *p;
    int need_sep;

    len = av_len(parts) + 1;
    if (len == 0) return newSVpvs("");

    /* Calculate total length */
    for (i = 0; i < len; i++) {
        SV **sv = av_fetch(parts, i, 0);
        if (sv && SvPOK(*sv)) {
            total_len += SvCUR(*sv) + 1;  /* +1 for separator */
        }
    }

    result = newSV(total_len + 1);
    SvPOK_on(result);
    buf = SvPVX(result);
    p = buf;
    need_sep = 0;

    for (i = 0; i < len; i++) {
        SV **sv = av_fetch(parts, i, 0);
        if (sv && SvPOK(*sv)) {
            STRLEN part_len;
            const char *part = SvPV(*sv, part_len);

            if (part_len == 0) continue;

            /* Skip leading separator if we already have one */
            while (part_len > 0 && (*part == '/' || *part == '\\')) {
                if (!need_sep && p == buf) break;  /* Keep root slash */
                part++;
                part_len--;
            }

            if (need_sep && part_len > 0) {
#ifdef _WIN32
                *p++ = '\\';
#else
                *p++ = '/';
#endif
            }

            if (part_len > 0) {
                memcpy(p, part, part_len);
                p += part_len;

                /* Check if ends with separator */
                need_sep = (*(p-1) != '/' && *(p-1) != '\\');
            }
        }
    }

    *p = '\0';
    SvCUR_set(result, p - buf);
    return result;
}

/* ============================================
   Head and Tail operations
   ============================================ */

static AV* file_head_internal(pTHX_ const char *path, IV n) {
    AV *result = newAV();
    IV idx;
    SV *line;
    IV count = 0;

    if (n <= 0) return result;

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) return result;

    while (count < n && (line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
        av_push(result, line);
        count++;
    }

    file_lines_close(idx);
    return result;
}

static AV* file_tail_internal(pTHX_ const char *path, IV n) {
    AV *result = newAV();
    AV *buffer;
    SV *line;
    IV idx;
    SSize_t i, buf_len;

    if (n <= 0) return result;

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) return result;

    /* Use circular buffer to keep last N lines */
    buffer = newAV();
    av_extend(buffer, n - 1);

    while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
        if (av_len(buffer) + 1 >= n) {
            SV *old = av_shift(buffer);
            SvREFCNT_dec(old);
        }
        av_push(buffer, line);
    }

    file_lines_close(idx);

    /* Copy buffer to result */
    buf_len = av_len(buffer) + 1;
    for (i = 0; i < buf_len; i++) {
        SV **sv = av_fetch(buffer, i, 0);
        if (sv) {
            av_push(result, newSVsv(*sv));
        }
    }

    SvREFCNT_dec((SV*)buffer);
    return result;
}

/* ============================================
   Atomic spew - write to temp file then rename
   ============================================ */

static int file_atomic_spew_internal(pTHX_ const char *path, SV *data) {
    char temp_path[4096];
    int fd;
    const char *buf;
    STRLEN len;
    ssize_t written = 0, n;
    static int counter = 0;
#ifdef _WIN32
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC | O_BINARY;
    int pid = (int)GetCurrentProcessId();
#else
    int open_flags = O_WRONLY | O_CREAT | O_TRUNC;
    int pid = (int)getpid();
#endif

    /* Create temp file name in same directory */
    snprintf(temp_path, sizeof(temp_path), "%s.tmp.%d.%d", path, pid, counter++);

    buf = SvPV(data, len);

    fd = file_open3(temp_path, open_flags, 0644);
    if (fd < 0) {
        return 0;
    }

    while ((size_t)written < len) {
        n = write(fd, buf + written, len - written);
        if (n < 0) {
            if (errno == EINTR) continue;
            close(fd);
            file_unlink_internal(temp_path);
            return 0;
        }
        written += n;
    }

#ifdef _WIN32
    /* Sync to disk on Windows */
    _commit(fd);
#else
    /* Sync to disk on POSIX */
    fsync(fd);
#endif

    close(fd);

    /* Atomic rename */
    if (rename(temp_path, path) != 0) {
        file_unlink_internal(temp_path);
        return 0;
    }

    /* Invalidate cache for this path */
    if (g_stat_cache.valid && strcmp(path, g_stat_cache.path) == 0) {
        g_stat_cache.valid = 0;
    }
    return 1;
}

/* ============================================
   Split lines utility
   ============================================ */

static AV* file_split_lines(pTHX_ SV *content) {
    AV *lines;
    const char *start, *end, *p;
    STRLEN len;

    start = SvPV(content, len);
    end = start + len;
    lines = newAV();

    while (start < end) {
        p = memchr(start, '\n', end - start);
        if (p) {
            av_push(lines, newSVpvn(start, p - start));
            start = p + 1;
        } else {
            if (start < end) {
                av_push(lines, newSVpvn(start, end - start));
            }
            break;
        }
    }

    return lines;
}

/* ============================================
   XS Functions
   ============================================ */

static XS(xs_slurp) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::slurp(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_slurp_internal(aTHX_ path));
    XSRETURN(1);
}

static XS(xs_slurp_raw) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::slurp_raw(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_slurp_raw(aTHX_ path));
    XSRETURN(1);
}

static XS(xs_spew) {
    dXSARGS;
    const char *path;

    if (items != 2) croak("Usage: file::spew(path, data)");

    path = SvPV_nolen(ST(0));
    if (file_spew_internal(aTHX_ path, ST(1))) {
        ST(0) = &PL_sv_yes;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

static XS(xs_append) {
    dXSARGS;
    const char *path;

    if (items != 2) croak("Usage: file::append(path, data)");

    path = SvPV_nolen(ST(0));
    if (file_append_internal(aTHX_ path, ST(1))) {
        ST(0) = &PL_sv_yes;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

static XS(xs_size) {
    dXSARGS;
    const char *path;
    IV size;

    if (items != 1) croak("Usage: file::size(path)");

    path = SvPV_nolen(ST(0));
    size = file_size_internal(path);
    ST(0) = sv_2mortal(newSViv(size));
    XSRETURN(1);
}

static XS(xs_mtime) {
    dXSARGS;
    const char *path;
    IV mtime;

    if (items != 1) croak("Usage: file::mtime(path)");

    path = SvPV_nolen(ST(0));
    mtime = file_mtime_internal(path);
    ST(0) = sv_2mortal(newSViv(mtime));
    XSRETURN(1);
}

static XS(xs_exists) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::exists(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_exists_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_is_file) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_file(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_file_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_is_dir) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_dir(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_dir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_is_readable) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_readable(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_readable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_is_writable) {
    dXSARGS;
    const char *path;

    if (items != 1) croak("Usage: file::is_writable(path)");

    path = SvPV_nolen(ST(0));
    ST(0) = file_is_writable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_lines) {
    dXSARGS;
    const char *path;
    AV *lines;
    int fd;
    Stat_t st;
    char *buffer;
    char *p, *end, *line_start;
    size_t file_size;
    ssize_t total_read, n;
#ifdef _WIN32
    int open_flags = O_RDONLY | O_BINARY;
#else
    int open_flags = O_RDONLY;
#endif

    if (items != 1) croak("Usage: file::lines(path)");

    path = SvPV_nolen(ST(0));

    fd = open(path, open_flags);
    if (UNLIKELY(fd < 0)) {
        ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));
        XSRETURN(1);
    }

    /* Get file size for single-read optimization */
    if (UNLIKELY(fstat(fd, &st) < 0 || st.st_size == 0)) {
        close(fd);
        ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));
        XSRETURN(1);
    }

    file_size = st.st_size;
    Newx(buffer, file_size + 1, char);

    /* Read entire file in one syscall when possible */
    total_read = 0;
    while ((size_t)total_read < file_size) {
        n = read(fd, buffer + total_read, file_size - total_read);
        if (UNLIKELY(n < 0)) {
            if (errno == EINTR) continue;
            break;
        }
        if (n == 0) break;
        total_read += n;
    }
    close(fd);

    if (UNLIKELY(total_read == 0)) {
        Safefree(buffer);
        ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));
        XSRETURN(1);
    }

    lines = newAV();
    /* Pre-extend array based on estimated lines */
    av_extend(lines, total_read / 40);

    /* Single scan through buffer - no memmove, no buffer resize */
    line_start = buffer;
    end = buffer + total_read;
    p = buffer;

    while (p < end) {
        p = memchr(p, '\n', end - p);
        if (LIKELY(p != NULL)) {
            av_push(lines, newSVpvn(line_start, p - line_start));
            p++;
            line_start = p;
        } else {
            /* Last line without trailing newline */
            if (line_start < end) {
                av_push(lines, newSVpvn(line_start, end - line_start));
            }
            break;
        }
    }

    Safefree(buffer);

    ST(0) = sv_2mortal(newRV_noinc((SV*)lines));
    XSRETURN(1);
}

static XS(xs_mmap_open) {
    dXSARGS;
    const char *path;
    int writable;
    IV idx;
    HV *hash;

    if (items < 1 || items > 2) croak("Usage: file::mmap_open(path, [writable])");

    path = SvPV_nolen(ST(0));
    writable = (items > 1 && SvTRUE(ST(1))) ? 1 : 0;

    idx = file_mmap_open(aTHX_ path, writable);
    if (idx < 0) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    hash = newHV();
    hv_store(hash, "_idx", 4, newSViv(idx), 0);
    hv_store(hash, "_writable", 9, newSViv(writable), 0);

    ST(0) = sv_2mortal(sv_bless(newRV_noinc((SV*)hash), gv_stashpv("File::Raw::mmap", GV_ADD)));
    XSRETURN(1);
}

static XS(xs_mmap_data) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    if (items != 1) croak("Usage: $mmap->data");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        croak("Invalid mmap object");
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    ST(0) = sv_2mortal(file_mmap_get_sv(aTHX_ idx));
    XSRETURN(1);
}

static XS(xs_mmap_sync) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    if (items != 1) croak("Usage: $mmap->sync");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        croak("Invalid mmap object");
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    file_mmap_sync(idx);
    XSRETURN_EMPTY;
}

static XS(xs_mmap_close) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    if (items != 1) croak("Usage: $mmap->close");

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        croak("Invalid mmap object");
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    file_mmap_close(idx);
    hv_store(hash, "_idx", 4, newSViv(-1), 0);
    XSRETURN_EMPTY;
}

static XS(xs_mmap_DESTROY) {
    dXSARGS;
    HV *hash;
    SV **idx_sv;
    IV idx;

    PERL_UNUSED_VAR(items);

    if (PL_dirty) XSRETURN_EMPTY;

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV) {
        XSRETURN_EMPTY;
    }

    hash = (HV*)SvRV(ST(0));
    idx_sv = hv_fetch(hash, "_idx", 4, 0);
    idx = idx_sv ? SvIV(*idx_sv) : -1;

    if (idx >= 0) {
        file_mmap_close(idx);
    }
    XSRETURN_EMPTY;
}

static XS(xs_lines_iter) {
    dXSARGS;
    const char *path;
    IV idx;
    SV *idx_sv;

    if (items != 1) croak("Usage: file::lines_iter(path)");

    path = SvPV_nolen(ST(0));
    idx = file_lines_open(aTHX_ path);

    if (idx < 0) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    /* Use simple IV reference - much faster than hash */
    idx_sv = newSViv(idx);
    ST(0) = sv_2mortal(sv_bless(newRV_noinc(idx_sv), gv_stashpv("File::Raw::lines", GV_ADD)));
    XSRETURN(1);
}

static XS(xs_lines_iter_next) {
    dXSARGS;
    SV *rv;
    IV idx;
    LineIterEntry *entry;
    char *line_start;
    char *newline;
    size_t line_len;
    SV *result;
    ssize_t n;

    if (items != 1) croak("Usage: $iter->next");

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        croak("Invalid lines iterator object");
    }

    /* Direct IV access - no hash lookup */
    idx = SvIV(SvRV(rv));

    if (UNLIKELY(idx < 0 || idx >= g_iters_count)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    entry = &g_iters[idx];
    if (UNLIKELY(entry->fd < 0)) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    /* Inline buffer parsing for speed */
    while (1) {
        /* Look for newline in current buffer */
        if (entry->buf_pos < entry->buf_len) {
            line_start = entry->buffer + entry->buf_pos;
            newline = memchr(line_start, '\n', entry->buf_len - entry->buf_pos);

            if (newline) {
                line_len = newline - line_start;
                result = newSVpvn(line_start, line_len);
                entry->buf_pos += line_len + 1;
                ST(0) = sv_2mortal(result);
                XSRETURN(1);
            }
        }

        /* No newline found, need more data */
        if (entry->eof) {
            /* Return remaining data if any */
            if (entry->buf_pos < entry->buf_len) {
                line_len = entry->buf_len - entry->buf_pos;
                result = newSVpvn(entry->buffer + entry->buf_pos, line_len);
                entry->buf_pos = entry->buf_len;
                ST(0) = sv_2mortal(result);
                XSRETURN(1);
            }
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }

        /* Move remaining data to start of buffer */
        if (entry->buf_pos > 0) {
            size_t remaining = entry->buf_len - entry->buf_pos;
            if (remaining > 0) {
                memmove(entry->buffer, entry->buffer + entry->buf_pos, remaining);
            }
            entry->buf_len = remaining;
            entry->buf_pos = 0;
        }

        /* Expand buffer if needed */
        if (entry->buf_len >= entry->buf_size - 1) {
            entry->buf_size *= 2;
            Renew(entry->buffer, entry->buf_size, char);
        }

        /* Read more data */
        n = read(entry->fd, entry->buffer + entry->buf_len,
                 entry->buf_size - entry->buf_len - 1);
        if (n < 0) {
            if (errno == EINTR) continue;
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        }
        if (n == 0) {
            entry->eof = 1;
        } else {
            entry->buf_len += n;
        }
    }
}

static XS(xs_lines_iter_eof) {
    dXSARGS;
    SV *rv;
    IV idx;
    LineIterEntry *entry;

    if (items != 1) croak("Usage: $iter->eof");

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        croak("Invalid lines iterator object");
    }

    /* Direct IV access and inline eof check */
    idx = SvIV(SvRV(rv));

    if (UNLIKELY(idx < 0 || idx >= g_iters_count)) {
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
    }

    entry = &g_iters[idx];
    ST(0) = (entry->eof && entry->buf_pos >= entry->buf_len) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_lines_iter_close) {
    dXSARGS;
    SV *rv, *inner;
    IV idx;

    if (items != 1) croak("Usage: $iter->close");

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        croak("Invalid lines iterator object");
    }

    inner = SvRV(rv);
    idx = SvIV(inner);

    file_lines_close(idx);
    sv_setiv(inner, -1);  /* Mark as closed */
    XSRETURN_EMPTY;
}

static XS(xs_lines_iter_DESTROY) {
    dXSARGS;
    SV *rv;
    IV idx;

    PERL_UNUSED_VAR(items);

    if (PL_dirty) XSRETURN_EMPTY;

    rv = ST(0);
    if (UNLIKELY(!SvROK(rv))) {
        XSRETURN_EMPTY;
    }

    idx = SvIV(SvRV(rv));

    if (idx >= 0) {
        file_lines_close(idx);
    }
    XSRETURN_EMPTY;
}

/* ============================================
   Callback registry for line processing
   Allows C-level predicates for maximum speed
   ============================================ */

/* Predicate function type for line processing */
typedef bool (*file_line_predicate)(pTHX_ SV *line);

/* Registered callback entry */
typedef struct {
    file_line_predicate predicate;  /* C function pointer (NULL for Perl-only) */
    SV *perl_callback;              /* Perl callback (for fallback or custom) */
} FileLineCallback;

/* Global callback registry */
static HV *g_file_callback_registry = NULL;

/* Built-in C predicates */
static bool pred_is_blank(pTHX_ SV *line) {
    STRLEN len;
    const char *s = SvPV(line, len);
    STRLEN i;
    for (i = 0; i < len; i++) {
        if (s[i] != ' ' && s[i] != '\t' && s[i] != '\r' && s[i] != '\n') {
            return FALSE;
        }
    }
    return TRUE;
}

static bool pred_is_not_blank(pTHX_ SV *line) {
    return !pred_is_blank(aTHX_ line);
}

static bool pred_is_empty(pTHX_ SV *line) {
    return SvCUR(line) == 0;
}

static bool pred_is_not_empty(pTHX_ SV *line) {
    return SvCUR(line) > 0;
}

static bool pred_is_comment(pTHX_ SV *line) {
    STRLEN len;
    const char *s = SvPV(line, len);
    /* Skip leading whitespace */
    while (len > 0 && (*s == ' ' || *s == '\t')) {
        s++;
        len--;
    }
    return len > 0 && *s == '#';
}

static bool pred_is_not_comment(pTHX_ SV *line) {
    return !pred_is_comment(aTHX_ line);
}

/* Cleanup callback registry during global destruction */
static void file_cleanup_callback_registry(pTHX_ void *data) {
    PERL_UNUSED_ARG(data);

    /* During global destruction, just NULL out pointers.
     * Perl handles SV cleanup; trying to free them ourselves
     * can cause crashes due to destruction order. */
    if (PL_dirty) {
        g_file_callback_registry = NULL;
        return;
    }

    /* Normal cleanup - not during global destruction */
    g_file_callback_registry = NULL;
}

static void file_init_callback_registry(pTHX) {
    SV *sv;
    FileLineCallback *cb;

    if (g_file_callback_registry) return;
    g_file_callback_registry = newHV();

    /* Register built-in predicates with both naming conventions */
    /* blank / is_blank */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_blank;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "blank", 5, sv, 0);
    hv_store(g_file_callback_registry, "is_blank", 8, SvREFCNT_inc(sv), 0);

    /* not_blank / is_not_blank */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_not_blank;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "not_blank", 9, sv, 0);
    hv_store(g_file_callback_registry, "is_not_blank", 12, SvREFCNT_inc(sv), 0);

    /* empty / is_empty */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_empty;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "empty", 5, sv, 0);
    hv_store(g_file_callback_registry, "is_empty", 8, SvREFCNT_inc(sv), 0);

    /* not_empty / is_not_empty */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_not_empty;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "not_empty", 9, sv, 0);
    hv_store(g_file_callback_registry, "is_not_empty", 12, SvREFCNT_inc(sv), 0);

    /* comment / is_comment */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_comment;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "comment", 7, sv, 0);
    hv_store(g_file_callback_registry, "is_comment", 10, SvREFCNT_inc(sv), 0);

    /* not_comment / is_not_comment */
    Newxz(cb, 1, FileLineCallback);
    cb->predicate = pred_is_not_comment;
    cb->perl_callback = NULL;
    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, "not_comment", 11, sv, 0);
    hv_store(g_file_callback_registry, "is_not_comment", 14, SvREFCNT_inc(sv), 0);
}

static FileLineCallback* file_get_callback(pTHX_ const char *name) {
    SV **svp;
    if (!g_file_callback_registry) return NULL;
    svp = hv_fetch(g_file_callback_registry, name, strlen(name), 0);
    if (svp && SvIOK(*svp)) {
        return INT2PTR(FileLineCallback*, SvIVX(*svp));
    }
    return NULL;
}

/* Process lines with callback - MULTICALL optimized (Perl >= 5.14 only) */
static XS(xs_each_line) {
    dXSARGS;
#if PERL_VERSION >= 14
    dMULTICALL;
#endif
    const char *path;
    SV *callback;
    IV idx;
    CV *block_cv;
    SV *old_defsv;
    SV *line_sv;
    LineIterEntry *entry;
    char *line_start;
    char *newline;
    size_t line_len;
    ssize_t n;
#if PERL_VERSION >= 14
    U8 gimme = G_VOID;
#endif

    if (items != 2) croak("Usage: file::each_line(path, callback)");

    path = SvPV_nolen(ST(0));
    callback = ST(1);

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV) {
        croak("Second argument must be a code reference");
    }

    block_cv = (CV*)SvRV(callback);
    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        XSRETURN_EMPTY;
    }

    entry = &g_iters[idx];

    old_defsv = DEFSV;
    line_sv = newSV(256);
    DEFSV = line_sv;

#if PERL_VERSION >= 14
    PUSH_MULTICALL(block_cv);
#endif

    while (1) {
        /* Look for newline in current buffer */
        if (entry->buf_pos < entry->buf_len) {
            line_start = entry->buffer + entry->buf_pos;
            newline = memchr(line_start, '\n', entry->buf_len - entry->buf_pos);

            if (newline) {
                line_len = newline - line_start;
                sv_setpvn(line_sv, line_start, line_len);
                entry->buf_pos += line_len + 1;
#if PERL_VERSION >= 14
                MULTICALL;
#else
                { dSP; PUSHMARK(SP); call_sv((SV*)block_cv, G_VOID|G_DISCARD); }
#endif
                continue;
            }
        }

        /* No newline found, need more data */
        if (entry->eof) {
            /* Return remaining data if any */
            if (entry->buf_pos < entry->buf_len) {
                line_len = entry->buf_len - entry->buf_pos;
                sv_setpvn(line_sv, entry->buffer + entry->buf_pos, line_len);
                entry->buf_pos = entry->buf_len;
#if PERL_VERSION >= 14
                MULTICALL;
#else
                { dSP; PUSHMARK(SP); call_sv((SV*)block_cv, G_VOID|G_DISCARD); }
#endif
            }
            break;
        }

        /* Move remaining data to start of buffer */
        if (entry->buf_pos > 0) {
            size_t remaining = entry->buf_len - entry->buf_pos;
            if (remaining > 0) {
                memmove(entry->buffer, entry->buffer + entry->buf_pos, remaining);
            }
            entry->buf_len = remaining;
            entry->buf_pos = 0;
        }

        /* Expand buffer if needed */
        if (entry->buf_len >= entry->buf_size - 1) {
            entry->buf_size *= 2;
            Renew(entry->buffer, entry->buf_size, char);
        }

        /* Read more data */
        n = read(entry->fd, entry->buffer + entry->buf_len,
                 entry->buf_size - entry->buf_len - 1);
        if (n < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (n == 0) {
            entry->eof = 1;
        } else {
            entry->buf_len += n;
        }
    }

#if PERL_VERSION >= 14
    POP_MULTICALL;
#endif
    SvREFCNT_dec(line_sv);
    DEFSV = old_defsv;
    file_lines_close(idx);
    XSRETURN_EMPTY;
}

/* Grep lines with callback or registered predicate name */
static XS(xs_grep_lines) {
    dXSARGS;
    const char *path;
    SV *predicate;
    IV idx;
    SV *line;
    AV *result;
    CV *block_cv = NULL;
    FileLineCallback *fcb = NULL;

    if (items != 2) croak("Usage: file::grep_lines(path, &predicate or $name)");

    path = SvPV_nolen(ST(0));
    predicate = ST(1);
    result = newAV();

    /* Check if predicate is a name or coderef */
    if (SvROK(predicate) && SvTYPE(SvRV(predicate)) == SVt_PVCV) {
        block_cv = (CV*)SvRV(predicate);
    } else {
        const char *name = SvPV_nolen(predicate);
        fcb = file_get_callback(aTHX_ name);
        if (!fcb) {
            croak("File::Raw::grep_lines: unknown predicate '%s'", name);
        }
    }

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
        XSRETURN(1);
    }

    /* C predicate path - fastest */
    if (fcb && fcb->predicate) {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            if (fcb->predicate(aTHX_ line)) {
                av_push(result, line);
            } else {
                SvREFCNT_dec(line);
            }
        }
        file_lines_close(idx);
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
        XSRETURN(1);
    }

    /* Call Perl callback */
    {
        SV *cb_sv = fcb ? fcb->perl_callback : (SV*)block_cv;
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV count;
            SV *result_sv;
            bool matches = FALSE;
            PUSHMARK(SP);
            XPUSHs(line);
            PUTBACK;
            count = call_sv(cb_sv, G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                result_sv = POPs;
                matches = SvTRUE(result_sv);
            }
            PUTBACK;
            if (matches) {
                av_push(result, line);
            } else {
                SvREFCNT_dec(line);
            }
        }
    }

    file_lines_close(idx);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* Count lines matching predicate */
static XS(xs_count_lines) {
    dXSARGS;
    const char *path;
    SV *predicate = NULL;
    IV idx;
    SV *line;
    IV count = 0;
    CV *block_cv = NULL;
    FileLineCallback *fcb = NULL;

    if (items < 1 || items > 2) croak("Usage: file::count_lines(path, [&predicate or $name])");

    path = SvPV_nolen(ST(0));

    /* If no predicate, just count newlines - no SV creation needed */
    if (items == 1) {
        int fd;
        char *buffer;
        ssize_t n, total_read = 0;
        char *p, *end;
        char last_char = '\n';  /* Assume last char is newline (handles empty file) */
#ifdef _WIN32
        int open_flags = O_RDONLY | O_BINARY;
#else
        int open_flags = O_RDONLY;
#endif
        fd = open(path, open_flags);
        if (UNLIKELY(fd < 0)) {
            ST(0) = sv_2mortal(newSViv(0));
            XSRETURN(1);
        }

        Newx(buffer, FILE_BUFFER_SIZE, char);
        count = 0;

        while ((n = read(fd, buffer, FILE_BUFFER_SIZE)) > 0) {
            p = buffer;
            end = buffer + n;
            while ((p = memchr(p, '\n', end - p)) != NULL) {
                count++;
                p++;
            }
            total_read += n;
            last_char = buffer[n - 1];
        }
        close(fd);
        Safefree(buffer);

        /* If file doesn't end with newline, count the last line */
        if (total_read > 0 && last_char != '\n') {
            count++;
        }

        ST(0) = sv_2mortal(newSViv(count));
        XSRETURN(1);
    }

    predicate = ST(1);

    /* Check if predicate is a name or coderef */
    if (SvROK(predicate) && SvTYPE(SvRV(predicate)) == SVt_PVCV) {
        block_cv = (CV*)SvRV(predicate);
    } else {
        const char *name = SvPV_nolen(predicate);
        fcb = file_get_callback(aTHX_ name);
        if (!fcb) {
            croak("File::Raw::count_lines: unknown predicate '%s'", name);
        }
    }

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        ST(0) = sv_2mortal(newSViv(0));
        XSRETURN(1);
    }

    /* C predicate path - fastest */
    if (fcb && fcb->predicate) {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            if (fcb->predicate(aTHX_ line)) {
                count++;
            }
            SvREFCNT_dec(line);
        }
        file_lines_close(idx);
        ST(0) = sv_2mortal(newSViv(count));
        XSRETURN(1);
    }

    /* Call Perl callback */
    {
        SV *cb_sv = fcb ? fcb->perl_callback : (SV*)block_cv;
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV n;
            SV *result_sv;
            bool matches = FALSE;
            PUSHMARK(SP);
            XPUSHs(line);
            PUTBACK;
            n = call_sv(cb_sv, G_SCALAR);
            SPAGAIN;
            if (n > 0) {
                result_sv = POPs;
                matches = SvTRUE(result_sv);
            }
            PUTBACK;
            if (matches) {
                count++;
            }
            SvREFCNT_dec(line);
        }
    }

    file_lines_close(idx);
    ST(0) = sv_2mortal(newSViv(count));
    XSRETURN(1);
}

/* Find first line matching predicate */
static XS(xs_find_line) {
    dXSARGS;
    const char *path;
    SV *predicate;
    IV idx;
    SV *line;
    CV *block_cv = NULL;
    FileLineCallback *fcb = NULL;

    if (items != 2) croak("Usage: file::find_line(path, &predicate or $name)");

    path = SvPV_nolen(ST(0));
    predicate = ST(1);

    /* Check if predicate is a name or coderef */
    if (SvROK(predicate) && SvTYPE(SvRV(predicate)) == SVt_PVCV) {
        block_cv = (CV*)SvRV(predicate);
    } else {
        const char *name = SvPV_nolen(predicate);
        fcb = file_get_callback(aTHX_ name);
        if (!fcb) {
            croak("File::Raw::find_line: unknown predicate '%s'", name);
        }
    }

    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        XSRETURN_UNDEF;
    }

    /* C predicate path - fastest */
    if (fcb && fcb->predicate) {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            if (fcb->predicate(aTHX_ line)) {
                file_lines_close(idx);
                ST(0) = sv_2mortal(line);
                XSRETURN(1);
            }
            SvREFCNT_dec(line);
        }
        file_lines_close(idx);
        XSRETURN_UNDEF;
    }

    /* Call Perl callback */
    {
        SV *cb_sv = fcb ? fcb->perl_callback : (SV*)block_cv;
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV n;
            SV *result_sv;
            bool matches = FALSE;
            PUSHMARK(SP);
            XPUSHs(line);
            PUTBACK;
            n = call_sv(cb_sv, G_SCALAR);
            SPAGAIN;
            if (n > 0) {
                result_sv = POPs;
                matches = SvTRUE(result_sv);
            }
            PUTBACK;
            if (matches) {
                file_lines_close(idx);
                ST(0) = sv_2mortal(line);
                XSRETURN(1);
            }
            SvREFCNT_dec(line);
        }
    }

    file_lines_close(idx);
    XSRETURN_UNDEF;
}

/* Map lines with callback */
static XS(xs_map_lines) {
    dXSARGS;
    const char *path;
    SV *callback;
    IV idx;
    SV *line;
    AV *result;
    CV *block_cv;

    if (items != 2) croak("Usage: file::map_lines(path, &callback)");

    path = SvPV_nolen(ST(0));
    callback = ST(1);
    result = newAV();

    if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV) {
        croak("Second argument must be a code reference");
    }

    block_cv = (CV*)SvRV(callback);
    idx = file_lines_open(aTHX_ path);
    if (idx < 0) {
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
        XSRETURN(1);
    }

    /* Call Perl callback */
    {
        while ((line = file_lines_next(aTHX_ idx)) != &PL_sv_undef) {
            dSP;
            IV count;
            SV *result_sv;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(line));
            PUTBACK;
            count = call_sv(callback, G_SCALAR);
            SPAGAIN;
            if (count > 0) {
                result_sv = POPs;
                av_push(result, SvREFCNT_inc(result_sv));
            }
            PUTBACK;
        }
    }

    file_lines_close(idx);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* Register a Perl callback */
static XS(xs_register_line_callback) {
    dXSARGS;
    const char *name;
    STRLEN name_len;
    SV *coderef;
    FileLineCallback *cb;
    SV *sv;

    if (items != 2) croak("Usage: file::register_line_callback($name, \\&coderef)");

    name = SvPV(ST(0), name_len);
    coderef = ST(1);

    if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
        croak("File::Raw::register_line_callback: second argument must be a coderef");
    }

    file_init_callback_registry(aTHX);

    /* If already registered, just update the perl_callback in place */
    {
        FileLineCallback *existing = file_get_callback(aTHX_ name);
        if (existing) {
            /* Update existing - free old perl_callback and set new one */
            if (existing->perl_callback) {
                SvREFCNT_dec(existing->perl_callback);
            }
            existing->perl_callback = newSVsv(coderef);
            existing->predicate = NULL;  /* Clear any C predicate */
            XSRETURN_YES;
        }
    }

    Newxz(cb, 1, FileLineCallback);
    cb->predicate = NULL;  /* No C function */
    cb->perl_callback = newSVsv(coderef);

    sv = newSViv(PTR2IV(cb));
    hv_store(g_file_callback_registry, name, name_len, sv, 0);

    XSRETURN_YES;
}

/* List registered callbacks */
static XS(xs_list_line_callbacks) {
    dXSARGS;
    AV *result;
    HE *entry;

    PERL_UNUSED_VAR(items);

    result = newAV();
    if (g_file_callback_registry) {
        hv_iterinit(g_file_callback_registry);
        while ((entry = hv_iternext(g_file_callback_registry))) {
            av_push(result, newSVsv(hv_iterkeysv(entry)));
        }
    }

    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* ============================================
   Hook registration XS functions
   ============================================ */

/* Register a Perl read hook */
static XS(xs_register_read_hook) {
    dXSARGS;
    SV *coderef;
    FileHookEntry *entry;

    if (items != 1) croak("Usage: file::register_read_hook(\\&coderef)");

    coderef = ST(0);
    if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
        croak("File::Raw::register_read_hook: argument must be a coderef");
    }

    /* Use the hook list for Perl callbacks */
    Newxz(entry, 1, FileHookEntry);
    entry->name = "perl_read_hook";
    entry->c_func = NULL;
    entry->perl_callback = newSVsv(coderef);
    entry->priority = FILE_HOOK_PRIORITY_NORMAL;
    entry->user_data = NULL;
    entry->next = g_file_hooks[FILE_HOOK_PHASE_READ];
    g_file_hooks[FILE_HOOK_PHASE_READ] = entry;

    XSRETURN_YES;
}

/* Register a Perl write hook */
static XS(xs_register_write_hook) {
    dXSARGS;
    SV *coderef;
    FileHookEntry *entry;

    if (items != 1) croak("Usage: file::register_write_hook(\\&coderef)");

    coderef = ST(0);
    if (!SvROK(coderef) || SvTYPE(SvRV(coderef)) != SVt_PVCV) {
        croak("File::Raw::register_write_hook: argument must be a coderef");
    }

    /* Use the hook list for Perl callbacks */
    Newxz(entry, 1, FileHookEntry);
    entry->name = "perl_write_hook";
    entry->c_func = NULL;
    entry->perl_callback = newSVsv(coderef);
    entry->priority = FILE_HOOK_PRIORITY_NORMAL;
    entry->user_data = NULL;
    entry->next = g_file_hooks[FILE_HOOK_PHASE_WRITE];
    g_file_hooks[FILE_HOOK_PHASE_WRITE] = entry;

    XSRETURN_YES;
}

/* Clear all hooks for a phase */
static XS(xs_clear_hooks) {
    dXSARGS;
    const char *phase_name;
    FileHookPhase phase;
    FileHookEntry *entry, *next;

    if (items != 1) croak("Usage: file::clear_hooks($phase)");

    phase_name = SvPV_nolen(ST(0));

    if (strcmp(phase_name, "read") == 0) {
        phase = FILE_HOOK_PHASE_READ;
        g_file_read_hook = NULL;
        g_file_read_hook_data = NULL;
    } else if (strcmp(phase_name, "write") == 0) {
        phase = FILE_HOOK_PHASE_WRITE;
        g_file_write_hook = NULL;
        g_file_write_hook_data = NULL;
    } else if (strcmp(phase_name, "open") == 0) {
        phase = FILE_HOOK_PHASE_OPEN;
    } else if (strcmp(phase_name, "close") == 0) {
        phase = FILE_HOOK_PHASE_CLOSE;
    } else {
        croak("File::Raw::clear_hooks: unknown phase '%s' (use read, write, open, close)", phase_name);
    }

    /* Free hook list */
    entry = g_file_hooks[phase];
    while (entry) {
        next = entry->next;
        if (entry->perl_callback) {
            SvREFCNT_dec(entry->perl_callback);
        }
        Safefree(entry);
        entry = next;
    }
    g_file_hooks[phase] = NULL;

    XSRETURN_YES;
}

/* Check if hooks are registered for a phase */
static XS(xs_has_hooks) {
    dXSARGS;
    const char *phase_name;
    FileHookPhase phase;
    int has;

    if (items != 1) croak("Usage: file::has_hooks($phase)");

    phase_name = SvPV_nolen(ST(0));

    if (strcmp(phase_name, "read") == 0) {
        phase = FILE_HOOK_PHASE_READ;
        has = (g_file_read_hook != NULL) || (g_file_hooks[phase] != NULL);
    } else if (strcmp(phase_name, "write") == 0) {
        phase = FILE_HOOK_PHASE_WRITE;
        has = (g_file_write_hook != NULL) || (g_file_hooks[phase] != NULL);
    } else if (strcmp(phase_name, "open") == 0) {
        phase = FILE_HOOK_PHASE_OPEN;
        has = (g_file_hooks[phase] != NULL);
    } else if (strcmp(phase_name, "close") == 0) {
        phase = FILE_HOOK_PHASE_CLOSE;
        has = (g_file_hooks[phase] != NULL);
    } else {
        croak("File::Raw::has_hooks: unknown phase '%s' (use read, write, open, close)", phase_name);
    }

    ST(0) = has ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* New stat functions */
static XS(xs_atime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::atime(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_atime_internal(path)));
    XSRETURN(1);
}

static XS(xs_ctime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::ctime(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_ctime_internal(path)));
    XSRETURN(1);
}

static XS(xs_mode) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::mode(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_mode_internal(path)));
    XSRETURN(1);
}

/* Combined stat - all attributes in one syscall */
static XS(xs_stat_all) {
    dXSARGS;
    const char *path;
    HV *result;
    if (items != 1) croak("Usage: File::Raw::stat(path)");
    path = SvPV_nolen(ST(0));
    result = file_stat_all_internal(aTHX_ path);
    if (result == NULL) {
        ST(0) = &PL_sv_undef;
    } else {
        ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    }
    XSRETURN(1);
}

static XS(xs_is_link) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::is_link(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_link_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_is_executable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::is_executable(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_executable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* File manipulation functions */
static XS(xs_unlink) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::unlink(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_unlink_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_copy) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file::copy(src, dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_copy_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_move) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file::move(src, dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_move_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_touch) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::touch(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_touch_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_clear_stat_cache) {
    dXSARGS;
    if (items > 1) croak("Usage: file::clear_stat_cache() or file::clear_stat_cache(path)");
    
    if (items == 1 && SvOK(ST(0))) {
        const char *path = SvPV_nolen(ST(0));
        invalidate_stat_cache_path(path);
    } else {
        invalidate_stat_cache();
    }
    
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

static XS(xs_chmod) {
    dXSARGS;
    const char *path;
    int mode;
    if (items != 2) croak("Usage: file::chmod(path, mode)");
    path = SvPV_nolen(ST(0));
    mode = SvIV(ST(1));
    ST(0) = file_chmod_internal(path, mode) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_mkdir) {
    dXSARGS;
    const char *path;
    int mode = 0755;
    if (items < 1 || items > 2) croak("Usage: file::mkdir(path, [mode])");
    path = SvPV_nolen(ST(0));
    if (items > 1) mode = SvIV(ST(1));
    ST(0) = file_mkdir_internal(path, mode) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_rmdir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::rmdir(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_rmdir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

static XS(xs_readdir) {
    dXSARGS;
    const char *path;
    AV *result;
    if (items != 1) croak("Usage: file::readdir(path)");
    path = SvPV_nolen(ST(0));
    result = file_readdir_internal(aTHX_ path);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* Path manipulation functions */
static XS(xs_basename) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::basename(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_basename_internal(aTHX_ path));
    XSRETURN(1);
}

static XS(xs_dirname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::dirname(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_dirname_internal(aTHX_ path));
    XSRETURN(1);
}

static XS(xs_extname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file::extname(path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_extname_internal(aTHX_ path));
    XSRETURN(1);
}

static XS(xs_join) {
    dXSARGS;
    AV *parts;
    SSize_t i;

    if (items < 1) croak("Usage: file::join(part1, part2, ...)");

    parts = newAV();
    for (i = 0; i < items; i++) {
        av_push(parts, newSVsv(ST(i)));
    }

    ST(0) = sv_2mortal(file_join_internal(aTHX_ parts));
    SvREFCNT_dec((SV*)parts);
    XSRETURN(1);
}

/* Head and tail */
static XS(xs_head) {
    dXSARGS;
    const char *path;
    AV *result;
    IV n = 10;  /* Default to 10 lines */
    if (items < 1 || items > 2) croak("Usage: file::head(path, [n])");
    path = SvPV_nolen(ST(0));
    if (items > 1) n = SvIV(ST(1));
    result = file_head_internal(aTHX_ path, n);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

static XS(xs_tail) {
    dXSARGS;
    const char *path;
    AV *result;
    IV n = 10;  /* Default to 10 lines */
    if (items < 1 || items > 2) croak("Usage: file::tail(path, [n])");
    path = SvPV_nolen(ST(0));
    if (items > 1) n = SvIV(ST(1));
    result = file_tail_internal(aTHX_ path, n);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

/* Atomic spew */
static XS(xs_atomic_spew) {
    dXSARGS;
    const char *path;
    if (items != 2) croak("Usage: file::atomic_spew(path, data)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_atomic_spew_internal(aTHX_ path, ST(1)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* ============================================
   Function-style XS (for import)
   ============================================ */

XS_EXTERNAL(XS_file_func_slurp) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_slurp($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_slurp_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_spew) {
    dXSARGS;
    const char *path;
    if (items != 2) croak("Usage: file_spew($path, $data)");
    path = SvPV_nolen(ST(0));
    if (file_spew_internal(aTHX_ path, ST(1))) {
        ST(0) = &PL_sv_yes;
    } else {
        ST(0) = &PL_sv_no;
    }
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_exists) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_exists($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_exists_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_size) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_size($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_size_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_file) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_file($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_file_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_dir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_dir($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_dir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_lines) {
    dXSARGS;
    const char *path;
    SV *content;
    AV *lines;
    if (items != 1) croak("Usage: file_lines($path)");
    path = SvPV_nolen(ST(0));
    content = file_slurp_internal(aTHX_ path);

    if (content == &PL_sv_undef) {
        lines = newAV();
    } else {
        lines = file_split_lines(aTHX_ content);
        SvREFCNT_dec(content);
    }

    ST(0) = sv_2mortal(newRV_noinc((SV*)lines));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_unlink) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_unlink($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_unlink_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_mkdir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_mkdir($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_mkdir_internal(path, 0755) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_rmdir) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_rmdir($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_rmdir_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_touch) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_touch($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_touch_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_clear_stat_cache) {
    dXSARGS;
    if (items > 1) croak("Usage: file_clear_stat_cache() or file_clear_stat_cache($path)");
    
    if (items == 1 && SvOK(ST(0))) {
        const char *path = SvPV_nolen(ST(0));
        invalidate_stat_cache_path(path);
    } else {
        invalidate_stat_cache();
    }
    
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_basename) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_basename($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_basename_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_dirname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_dirname($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_dirname_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_extname) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_extname($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_extname_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_mtime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_mtime($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_mtime_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_atime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_atime($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_atime_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_ctime) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_ctime($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_ctime_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_mode) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_mode($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(newSViv(file_mode_internal(path)));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_link) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_link($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_link_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_readable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_readable($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_readable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_writable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_writable($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_writable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_is_executable) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_is_executable($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_is_executable_internal(path) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_readdir) {
    dXSARGS;
    const char *path;
    AV *result;
    if (items != 1) croak("Usage: file_readdir($path)");
    path = SvPV_nolen(ST(0));
    result = file_readdir_internal(aTHX_ path);
    ST(0) = sv_2mortal(newRV_noinc((SV*)result));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_slurp_raw) {
    dXSARGS;
    const char *path;
    if (items != 1) croak("Usage: file_slurp_raw($path)");
    path = SvPV_nolen(ST(0));
    ST(0) = sv_2mortal(file_slurp_raw_internal(aTHX_ path));
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_copy) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file_copy($src, $dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_copy_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_move) {
    dXSARGS;
    const char *src;
    const char *dst;
    if (items != 2) croak("Usage: file_move($src, $dst)");
    src = SvPV_nolen(ST(0));
    dst = SvPV_nolen(ST(1));
    ST(0) = file_move_internal(aTHX_ src, dst) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_chmod) {
    dXSARGS;
    const char *path;
    int mode;
    if (items != 2) croak("Usage: file_chmod($path, $mode)");
    path = SvPV_nolen(ST(0));
    mode = SvIV(ST(1));
    ST(0) = file_chmod_internal(path, mode) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_append) {
    dXSARGS;
    const char *path;
    if (items != 2) croak("Usage: file_append($path, $data)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_append_internal(aTHX_ path, ST(1)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_EXTERNAL(XS_file_func_atomic_spew) {
    dXSARGS;
    const char *path;
    if (items != 2) croak("Usage: file_atomic_spew($path, $data)");
    path = SvPV_nolen(ST(0));
    ST(0) = file_atomic_spew_internal(aTHX_ path, ST(1)) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

/* Function entry for selective import */
typedef struct {
    const char *name;       /* Name without file_ prefix (e.g., "slurp") */
    int args;               /* 1 or 2 arguments */
    void (*xs_func)(pTHX_ CV*);
    Perl_ppaddr_t pp_func;
} ImportEntry;

static const ImportEntry import_funcs[] = {
    /* 1-arg functions */
    {"slurp", 1, XS_file_func_slurp, pp_file_slurp},
    {"slurp_raw", 1, XS_file_func_slurp_raw, pp_file_slurp_raw},
    {"exists", 1, XS_file_func_exists, pp_file_exists},
    {"size", 1, XS_file_func_size, pp_file_size},
    {"is_file", 1, XS_file_func_is_file, pp_file_is_file},
    {"is_dir", 1, XS_file_func_is_dir, pp_file_is_dir},
    {"lines", 1, XS_file_func_lines, pp_file_lines},
    {"unlink", 1, XS_file_func_unlink, pp_file_unlink},
    {"mkdir", 1, XS_file_func_mkdir, pp_file_mkdir},
    {"rmdir", 1, XS_file_func_rmdir, pp_file_rmdir},
    {"touch", 1, XS_file_func_touch, pp_file_touch},
    {"clear_stat_cache", 1, XS_file_func_clear_stat_cache, pp_file_clear_stat_cache},
    {"basename", 1, XS_file_func_basename, pp_file_basename},
    {"dirname", 1, XS_file_func_dirname, pp_file_dirname},
    {"extname", 1, XS_file_func_extname, pp_file_extname},
    {"mtime", 1, XS_file_func_mtime, pp_file_mtime},
    {"atime", 1, XS_file_func_atime, pp_file_atime},
    {"ctime", 1, XS_file_func_ctime, pp_file_ctime},
    {"mode", 1, XS_file_func_mode, pp_file_mode},
    {"is_link", 1, XS_file_func_is_link, pp_file_is_link},
    {"is_readable", 1, XS_file_func_is_readable, pp_file_is_readable},
    {"is_writable", 1, XS_file_func_is_writable, pp_file_is_writable},
    {"is_executable", 1, XS_file_func_is_executable, pp_file_is_executable},
    {"readdir", 1, XS_file_func_readdir, pp_file_readdir},
    /* 2-arg functions */
    {"spew", 2, XS_file_func_spew, pp_file_spew},
    {"copy", 2, XS_file_func_copy, pp_file_copy},
    {"move", 2, XS_file_func_move, pp_file_move},
    {"chmod", 2, XS_file_func_chmod, pp_file_chmod},
    {"append", 2, XS_file_func_append, pp_file_append},
    {"atomic_spew", 2, XS_file_func_atomic_spew, pp_file_atomic_spew},
    {NULL, 0, NULL, NULL}
};

#define IMPORT_FUNCS_COUNT (sizeof(import_funcs) / sizeof(import_funcs[0]) - 1)

static void install_import_entry(pTHX_ const char *pkg, const ImportEntry *e) {
    char full_name[256];
    snprintf(full_name, sizeof(full_name), "file_%s", e->name);
    if (e->args == 1) {
        install_file_func_1arg(aTHX_ pkg, full_name, e->xs_func, e->pp_func);
    } else {
        install_file_func_2arg(aTHX_ pkg, full_name, e->xs_func, e->pp_func);
    }
}

static void install_all_imports(pTHX_ const char *pkg) {
    int i;
    for (i = 0; import_funcs[i].name != NULL; i++) {
        install_import_entry(aTHX_ pkg, &import_funcs[i]);
    }
}

/* file::import - import function-style accessors with custom ops */
XS_EXTERNAL(XS_file_import) {
    dXSARGS;
    const char *pkg;
    int i, j;

    /* Get caller's package */
    pkg = CopSTASHPV(PL_curcop);

    /* No args after package name = no imports */
    if (items <= 1) {
        XSRETURN_EMPTY;
    }

    /* Process each requested import */
    for (i = 1; i < items; i++) {
        STRLEN len;
        const char *arg = SvPV(ST(i), len);

        /* Check for :all or import (both mean import everything) */
        if ((len == 4 && strEQ(arg, ":all")) ||
            (len == 6 && strEQ(arg, "import"))) {
            install_all_imports(aTHX_ pkg);
            XSRETURN_EMPTY;  /* :all means we're done */
        }

        /* Look up the requested function */
        for (j = 0; import_funcs[j].name != NULL; j++) {
            if (strEQ(arg, import_funcs[j].name)) {
                install_import_entry(aTHX_ pkg, &import_funcs[j]);
                break;
            }
        }

        /* If not found, warn but don't die */
        if (import_funcs[j].name == NULL) {
            warn("File::Raw: '%s' is not exported", arg);
        }
    }

    XSRETURN_EMPTY;
}

/* ============================================
   Boot
   ============================================ */

XS_EXTERNAL(boot_File__Raw) {
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);

    file_init(aTHX);

    /* Register custom ops */
    XopENTRY_set(&file_slurp_xop, xop_name, "file_slurp");
    XopENTRY_set(&file_slurp_xop, xop_desc, "file slurp");
    XopENTRY_set(&file_slurp_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_slurp, &file_slurp_xop);

    XopENTRY_set(&file_spew_xop, xop_name, "file_spew");
    XopENTRY_set(&file_spew_xop, xop_desc, "file spew");
    XopENTRY_set(&file_spew_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_spew, &file_spew_xop);

    XopENTRY_set(&file_exists_xop, xop_name, "file_exists");
    XopENTRY_set(&file_exists_xop, xop_desc, "file exists");
    XopENTRY_set(&file_exists_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_exists, &file_exists_xop);

    XopENTRY_set(&file_size_xop, xop_name, "file_size");
    XopENTRY_set(&file_size_xop, xop_desc, "file size");
    XopENTRY_set(&file_size_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_size, &file_size_xop);

    XopENTRY_set(&file_is_file_xop, xop_name, "file_is_file");
    XopENTRY_set(&file_is_file_xop, xop_desc, "file is_file");
    XopENTRY_set(&file_is_file_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_file, &file_is_file_xop);

    XopENTRY_set(&file_is_dir_xop, xop_name, "file_is_dir");
    XopENTRY_set(&file_is_dir_xop, xop_desc, "file is_dir");
    XopENTRY_set(&file_is_dir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_dir, &file_is_dir_xop);

    XopENTRY_set(&file_lines_xop, xop_name, "file_lines");
    XopENTRY_set(&file_lines_xop, xop_desc, "file lines");
    XopENTRY_set(&file_lines_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_lines, &file_lines_xop);

    XopENTRY_set(&file_unlink_xop, xop_name, "file_unlink");
    XopENTRY_set(&file_unlink_xop, xop_desc, "file unlink");
    XopENTRY_set(&file_unlink_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_unlink, &file_unlink_xop);

    XopENTRY_set(&file_mkdir_xop, xop_name, "file_mkdir");
    XopENTRY_set(&file_mkdir_xop, xop_desc, "file mkdir");
    XopENTRY_set(&file_mkdir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_mkdir, &file_mkdir_xop);

    XopENTRY_set(&file_rmdir_xop, xop_name, "file_rmdir");
    XopENTRY_set(&file_rmdir_xop, xop_desc, "file rmdir");
    XopENTRY_set(&file_rmdir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_rmdir, &file_rmdir_xop);

    XopENTRY_set(&file_touch_xop, xop_name, "file_touch");
    XopENTRY_set(&file_touch_xop, xop_desc, "file touch");
    XopENTRY_set(&file_touch_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_touch, &file_touch_xop);

    XopENTRY_set(&file_clear_stat_cache_xop, xop_name, "file_clear_stat_cache");
    XopENTRY_set(&file_clear_stat_cache_xop, xop_desc, "clear stat cache");
    XopENTRY_set(&file_clear_stat_cache_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_file_clear_stat_cache, &file_clear_stat_cache_xop);

    XopENTRY_set(&file_basename_xop, xop_name, "file_basename");
    XopENTRY_set(&file_basename_xop, xop_desc, "file basename");
    XopENTRY_set(&file_basename_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_basename, &file_basename_xop);

    XopENTRY_set(&file_dirname_xop, xop_name, "file_dirname");
    XopENTRY_set(&file_dirname_xop, xop_desc, "file dirname");
    XopENTRY_set(&file_dirname_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_dirname, &file_dirname_xop);

    XopENTRY_set(&file_extname_xop, xop_name, "file_extname");
    XopENTRY_set(&file_extname_xop, xop_desc, "file extname");
    XopENTRY_set(&file_extname_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_extname, &file_extname_xop);

    XopENTRY_set(&file_mtime_xop, xop_name, "file_mtime");
    XopENTRY_set(&file_mtime_xop, xop_desc, "file mtime");
    XopENTRY_set(&file_mtime_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_mtime, &file_mtime_xop);

    XopENTRY_set(&file_atime_xop, xop_name, "file_atime");
    XopENTRY_set(&file_atime_xop, xop_desc, "file atime");
    XopENTRY_set(&file_atime_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_atime, &file_atime_xop);

    XopENTRY_set(&file_ctime_xop, xop_name, "file_ctime");
    XopENTRY_set(&file_ctime_xop, xop_desc, "file ctime");
    XopENTRY_set(&file_ctime_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_ctime, &file_ctime_xop);

    XopENTRY_set(&file_mode_xop, xop_name, "file_mode");
    XopENTRY_set(&file_mode_xop, xop_desc, "file mode");
    XopENTRY_set(&file_mode_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_mode, &file_mode_xop);

    XopENTRY_set(&file_is_link_xop, xop_name, "file_is_link");
    XopENTRY_set(&file_is_link_xop, xop_desc, "file is_link");
    XopENTRY_set(&file_is_link_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_link, &file_is_link_xop);

    XopENTRY_set(&file_is_readable_xop, xop_name, "file_is_readable");
    XopENTRY_set(&file_is_readable_xop, xop_desc, "file is_readable");
    XopENTRY_set(&file_is_readable_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_readable, &file_is_readable_xop);

    XopENTRY_set(&file_is_writable_xop, xop_name, "file_is_writable");
    XopENTRY_set(&file_is_writable_xop, xop_desc, "file is_writable");
    XopENTRY_set(&file_is_writable_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_writable, &file_is_writable_xop);

    XopENTRY_set(&file_is_executable_xop, xop_name, "file_is_executable");
    XopENTRY_set(&file_is_executable_xop, xop_desc, "file is_executable");
    XopENTRY_set(&file_is_executable_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_is_executable, &file_is_executable_xop);

    XopENTRY_set(&file_readdir_xop, xop_name, "file_readdir");
    XopENTRY_set(&file_readdir_xop, xop_desc, "file readdir");
    XopENTRY_set(&file_readdir_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_readdir, &file_readdir_xop);

    XopENTRY_set(&file_slurp_raw_xop, xop_name, "file_slurp_raw");
    XopENTRY_set(&file_slurp_raw_xop, xop_desc, "file slurp_raw");
    XopENTRY_set(&file_slurp_raw_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_file_slurp_raw, &file_slurp_raw_xop);

    XopENTRY_set(&file_copy_xop, xop_name, "file_copy");
    XopENTRY_set(&file_copy_xop, xop_desc, "file copy");
    XopENTRY_set(&file_copy_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_copy, &file_copy_xop);

    XopENTRY_set(&file_move_xop, xop_name, "file_move");
    XopENTRY_set(&file_move_xop, xop_desc, "file move");
    XopENTRY_set(&file_move_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_move, &file_move_xop);

    XopENTRY_set(&file_chmod_xop, xop_name, "file_chmod");
    XopENTRY_set(&file_chmod_xop, xop_desc, "file chmod");
    XopENTRY_set(&file_chmod_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_chmod, &file_chmod_xop);

    XopENTRY_set(&file_append_xop, xop_name, "file_append");
    XopENTRY_set(&file_append_xop, xop_desc, "file append");
    XopENTRY_set(&file_append_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_append, &file_append_xop);

    XopENTRY_set(&file_atomic_spew_xop, xop_name, "file_atomic_spew");
    XopENTRY_set(&file_atomic_spew_xop, xop_desc, "file atomic_spew");
    XopENTRY_set(&file_atomic_spew_xop, xop_class, OA_BINOP);
    Perl_custom_op_register(aTHX_ pp_file_atomic_spew, &file_atomic_spew_xop);

    /* Install functions with call checker for custom op optimization */
    {
        CV *cv;
        SV *ckobj;

        /* 1-arg functions with call checker */
        cv = newXS("File::Raw::size", xs_size, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_size));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::mtime", xs_mtime, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_mtime));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::atime", xs_atime, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_atime));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::ctime", xs_ctime, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_ctime));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::mode", xs_mode, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_mode));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::exists", xs_exists, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_exists));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_file", xs_is_file, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_file));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_dir", xs_is_dir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_dir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_link", xs_is_link, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_link));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_readable", xs_is_readable, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_readable));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_writable", xs_is_writable, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_writable));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::is_executable", xs_is_executable, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_is_executable));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        /* File manipulation - 1-arg */
        cv = newXS("File::Raw::unlink", xs_unlink, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_unlink));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::mkdir", xs_mkdir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_mkdir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::rmdir", xs_rmdir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_rmdir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::touch", xs_touch, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_touch));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::clear_stat_cache", xs_clear_stat_cache, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_clear_stat_cache));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::basename", xs_basename, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_basename));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::dirname", xs_dirname, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_dirname));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::extname", xs_extname, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_extname));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::slurp", xs_slurp, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_slurp));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::slurp_raw", xs_slurp_raw, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_slurp_raw));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::lines", xs_lines, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_lines));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        cv = newXS("File::Raw::readdir", xs_readdir, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_readdir));
        cv_set_call_checker(cv, file_call_checker_1arg, ckobj);

        /* 2-arg functions with call checker */
        cv = newXS("File::Raw::spew", xs_spew, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_spew));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::append", xs_append, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_append));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::copy", xs_copy, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_copy));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::move", xs_move, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_move));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::chmod", xs_chmod, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_chmod));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);

        cv = newXS("File::Raw::atomic_spew", xs_atomic_spew, __FILE__);
        ckobj = newSViv(PTR2IV(pp_file_atomic_spew));
        cv_set_call_checker(cv, file_call_checker_2arg, ckobj);
    }

    /* Functions without custom op optimization */
    newXS("File::Raw::join", xs_join, __FILE__);
    newXS("File::Raw::each_line", xs_each_line, __FILE__);
    newXS("File::Raw::grep_lines", xs_grep_lines, __FILE__);
    newXS("File::Raw::count_lines", xs_count_lines, __FILE__);
    newXS("File::Raw::find_line", xs_find_line, __FILE__);
    newXS("File::Raw::map_lines", xs_map_lines, __FILE__);
    newXS("File::Raw::register_line_callback", xs_register_line_callback, __FILE__);
    newXS("File::Raw::list_line_callbacks", xs_list_line_callbacks, __FILE__);

    /* File hooks */
    newXS("File::Raw::register_read_hook", xs_register_read_hook, __FILE__);
    newXS("File::Raw::register_write_hook", xs_register_write_hook, __FILE__);
    newXS("File::Raw::clear_hooks", xs_clear_hooks, __FILE__);
    newXS("File::Raw::has_hooks", xs_has_hooks, __FILE__);

    /* Combined stat - all attributes in one syscall */
    newXS("File::Raw::stat", xs_stat_all, __FILE__);

    /* Head and tail */
    newXS("File::Raw::head", xs_head, __FILE__);
    newXS("File::Raw::tail", xs_tail, __FILE__);

    /* Import function */
    newXS("File::Raw::import", XS_file_import, __FILE__);

    /* Memory-mapped files */
    newXS("File::Raw::mmap_open", xs_mmap_open, __FILE__);
    newXS("File::Raw::mmap::data", xs_mmap_data, __FILE__);
    newXS("File::Raw::mmap::sync", xs_mmap_sync, __FILE__);
    newXS("File::Raw::mmap::close", xs_mmap_close, __FILE__);
    newXS("File::Raw::mmap::DESTROY", xs_mmap_DESTROY, __FILE__);

    /* Line iterators */
    newXS("File::Raw::lines_iter", xs_lines_iter, __FILE__);
    newXS("File::Raw::lines::next", xs_lines_iter_next, __FILE__);
    newXS("File::Raw::lines::eof", xs_lines_iter_eof, __FILE__);
    newXS("File::Raw::lines::close", xs_lines_iter_close, __FILE__);
    newXS("File::Raw::lines::DESTROY", xs_lines_iter_DESTROY, __FILE__);

    /* Register cleanup for global destruction */
    Perl_call_atexit(aTHX_ file_cleanup_callback_registry, NULL);

#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 22)
    Perl_xs_boot_epilog(aTHX_ ax);
#else
    XSRETURN_YES;
#endif
}
