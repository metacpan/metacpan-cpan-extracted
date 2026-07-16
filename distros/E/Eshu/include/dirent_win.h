/*
 * dirent_win.h — minimal opendir/readdir/closedir for MSVC on Windows
 *
 * Wraps FindFirstFile/FindNextFile/FindClose.
 * Only the d_name field of struct dirent is populated (all we use).
 */

#ifndef DIRENT_WIN_H
#define DIRENT_WIN_H

#ifndef _WIN32
#  error "dirent_win.h is for Windows / MSVC only"
#endif

#ifndef WIN32_LEAN_AND_MEAN
#  define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define NAME_MAX 260

struct dirent {
    char d_name[NAME_MAX + 1];
};

typedef struct {
    HANDLE          hFind;
    WIN32_FIND_DATA wfd;
    struct dirent   ent;
    int             first;   /* 1 = FindFirstFile result not yet returned */
    int             done;
} DIR;

static DIR *opendir(const char *path) {
    char pattern[MAX_PATH];
    DIR *d;

    if (!path || !*path) { errno = ENOENT; return NULL; }
    if (snprintf(pattern, sizeof(pattern), "%s\\*", path) >= (int)sizeof(pattern)) {
        errno = ENAMETOOLONG; return NULL;
    }

    d = (DIR *)calloc(1, sizeof(DIR));
    if (!d) { errno = ENOMEM; return NULL; }

    d->hFind = FindFirstFileA(pattern, &d->wfd);
    if (d->hFind == INVALID_HANDLE_VALUE) {
        free(d);
        errno = ENOENT;
        return NULL;
    }
    d->first = 1;
    d->done  = 0;
    return d;
}

static struct dirent *readdir(DIR *d) {
    if (!d || d->done) return NULL;

    if (d->first) {
        d->first = 0;
    } else {
        if (!FindNextFileA(d->hFind, &d->wfd)) {
            d->done = 1;
            return NULL;
        }
    }

    strncpy(d->ent.d_name, d->wfd.cFileName, NAME_MAX);
    d->ent.d_name[NAME_MAX] = '\0';
    return &d->ent;
}

static int closedir(DIR *d) {
    if (!d) return -1;
    if (d->hFind != INVALID_HANDLE_VALUE)
        FindClose(d->hFind);
    free(d);
    return 0;
}

#endif /* DIRENT_WIN_H */
