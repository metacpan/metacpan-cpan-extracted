#ifndef DD_SYSTEM_MENU_NATIVE_H
#define DD_SYSTEM_MENU_NATIVE_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef _WIN32
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>
#  include <wchar.h>
#else
#  include <sys/types.h>
#  include <sys/wait.h>
#  include <spawn.h>
#  include <unistd.h>
#  include <fcntl.h>
#  include <libgen.h>
#  include <dlfcn.h>
#  include <pthread.h>
extern char **environ;
#endif

#ifdef _WIN32
static HANDLE helper_process = NULL;
static HANDLE helper_write = NULL;
static HANDLE helper_read = NULL;
static SRWLOCK helper_lock = SRWLOCK_INIT;
#else
static int helper_fd = -1;
static int event_fd = -1;
static pid_t helper_pid = -1;
static pthread_mutex_t helper_lock = PTHREAD_MUTEX_INITIALIZER;
#endif

#ifdef _WIN32
static void lock_helper(void) { AcquireSRWLockExclusive(&helper_lock); }
static void unlock_helper(void) { ReleaseSRWLockExclusive(&helper_lock); }
#else
static void lock_helper(void) { pthread_mutex_lock(&helper_lock); }
static void unlock_helper(void) { pthread_mutex_unlock(&helper_lock); }
#endif

#ifdef _WIN32
static void close_helper_state_unlocked(void)
{
    if (helper_write) { CloseHandle(helper_write); helper_write = NULL; }
    if (helper_read) { CloseHandle(helper_read); helper_read = NULL; }
    if (helper_process) { CloseHandle(helper_process); helper_process = NULL; }
}

static int helper_is_running_unlocked(void)
{
    DWORD rc;
    if (!helper_process) return 0;
    rc = WaitForSingleObject(helper_process, 0);
    if (rc == WAIT_TIMEOUT) return 1;
    close_helper_state_unlocked();
    return 0;
}

static int find_helper_path(wchar_t *out, size_t out_count)
{
    HMODULE mod = NULL;
    DWORD n;
    wchar_t *slash;
    const wchar_t *leaf = L"system_menu_helper.exe";

    if (!GetModuleHandleExW(
            GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
            GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            (LPCWSTR)(const void *)&find_helper_path,
            &mod))
        return 0;

    n = GetModuleFileNameW(mod, out, (DWORD)out_count);
    if (!n || n >= out_count) return 0;

    slash = wcsrchr(out, L'\\');
    if (!slash) slash = wcsrchr(out, L'/');
    if (!slash) return 0;
    slash++;

    if ((size_t)(slash - out) + wcslen(leaf) + 1 > out_count)
        return 0;
    wcscpy(slash, leaf);

    return GetFileAttributesW(out) != INVALID_FILE_ATTRIBUTES;
}

static int write_all_win(HANDLE h, const char *buf, size_t len)
{
    while (len) {
        DWORD n = 0;
        DWORD want = len > 0x7fffffffU ? 0x7fffffffU : (DWORD)len;
        if (!WriteFile(h, buf, want, &n, NULL) || n == 0)
            return 0;
        buf += n;
        len -= n;
    }
    return 1;
}
#else
static void close_helper_state_unlocked(void)
{
    if (helper_fd >= 0) { close(helper_fd); helper_fd = -1; }
    if (event_fd >= 0) { close(event_fd); event_fd = -1; }
    helper_pid = -1;
}

static int helper_is_running_unlocked(void)
{
    int status;
    pid_t rc;
    if (helper_pid <= 0) return 0;
    rc = waitpid(helper_pid, &status, WNOHANG);
    if (rc == 0) return 1;
    if (rc == helper_pid || (rc < 0 && errno == ECHILD)) {
        close_helper_state_unlocked();
        return 0;
    }
    return 0;
}

static int find_helper_path(char *out, size_t out_size)
{
    Dl_info info;
    char bundle_path[PATH_MAX];
    char *dir;
    if (dladdr((void *)&find_helper_path, &info) == 0 || !info.dli_fname)
        return 0;
    if (strlen(info.dli_fname) >= sizeof(bundle_path)) return 0;
    strcpy(bundle_path, info.dli_fname);
    dir = dirname(bundle_path);
    if (snprintf(out, out_size, "%s/system_menu_helper", dir) >= (int)out_size)
        return 0;
    return access(out, X_OK) == 0;
}

static int write_all_posix(int fd, const char *buf, size_t len)
{
    while (len) {
        ssize_t n = write(fd, buf, len);
        if (n < 0) {
            if (errno == EINTR) continue;
            return 0;
        }
        buf += n;
        len -= (size_t)n;
    }
    return 1;
}
#endif

#endif
