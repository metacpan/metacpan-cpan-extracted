/*
 * dirent_win.h - minimal directory iteration for Windows, under names
 * that collide with nothing. Two releases proved the ambient spellings
 * are a minefield: defining DIR/opendir clashed with the dirent.h that
 * perl.h pulls in (0.11, every Windows toolchain), and leaning on the
 * ambient opendir instead either fails to link (MSVC: Eshu.xs #undefs
 * the PerlDir_* remaps, and msvcrt has no opendir) or links against
 * MinGW's own dirent whose struct layout is not the one perl's header
 * compiled us against, so readdir returns garbage names (0.12). So:
 * eshu_opendir/eshu_readdir/eshu_closedir over EshuDIR, self-contained
 * on FindFirstFile/FindNextFile/FindClose (kernel32, always linked),
 * static, no exported or imported CRT dir symbols at all.
 *
 * Only the d_name field of struct eshu_dirent is populated (all we
 * use). The -A variants are named explicitly so a UNICODE define in
 * the environment cannot change the struct behind us.
 */

#ifndef DIRENT_WIN_H
#define DIRENT_WIN_H

#ifndef _WIN32
#  error "dirent_win.h is for Windows only"
#endif

#ifndef WIN32_LEAN_AND_MEAN
#  define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifndef ESHU_NAME_MAX
#  define ESHU_NAME_MAX 260
#endif

struct eshu_dirent {
    char d_name[ESHU_NAME_MAX + 1];
};

typedef struct {
    HANDLE            hFind;
    WIN32_FIND_DATAA  wfd;
    struct eshu_dirent ent;
    int               first;  /* 1 = FindFirstFile result not yet returned */
    int               done;
} EshuDIR;

static EshuDIR *eshu_opendir(const char *path) {
    char pattern[MAX_PATH];
    EshuDIR *d;

    if (!path || !*path) { errno = ENOENT; return NULL; }
    if (snprintf(pattern, sizeof(pattern), "%s\\*", path) >= (int)sizeof(pattern)) {
        errno = ENAMETOOLONG; return NULL;
    }

    d = (EshuDIR *)calloc(1, sizeof(EshuDIR));
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

static struct eshu_dirent *eshu_readdir(EshuDIR *d) {
    if (!d || d->done) return NULL;

    if (d->first) {
        d->first = 0;
    } else {
        if (!FindNextFileA(d->hFind, &d->wfd)) {
            d->done = 1;
            return NULL;
        }
    }

    strncpy(d->ent.d_name, d->wfd.cFileName, ESHU_NAME_MAX);
    d->ent.d_name[ESHU_NAME_MAX] = '\0';
    return &d->ent;
}

static int eshu_closedir(EshuDIR *d) {
    if (!d) return -1;
    if (d->hFind != INVALID_HANDLE_VALUE)
        FindClose(d->hFind);
    free(d);
    return 0;
}

#endif /* DIRENT_WIN_H */
