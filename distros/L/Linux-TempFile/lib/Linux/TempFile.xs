#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

MODULE = Linux::TempFile PACKAGE = Linux::TempFile

int
_open_tmpfile(const char* dir)
CODE:
    int fd = open(dir, O_TMPFILE | O_RDWR, S_IRUSR | S_IWUSR);
    if (fd == -1) {
        croak("%s", strerror(errno));
    }
    RETVAL = fd;
OUTPUT:
    RETVAL

void
_linkat(const char* oldpath, const char* newpath)
CODE:
    int rc = linkat(AT_FDCWD, oldpath, AT_FDCWD, newpath, AT_SYMLINK_FOLLOW);
    if (rc == -1) {
        croak("%s", strerror(errno));
    }
