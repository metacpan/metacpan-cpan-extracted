/*
 * tar.h - tar plugin internals.
 *
 * The plugin descriptor `tar_plugin` is exported and registered from
 * archive.c's BOOT path. tar_plugin's read/write callbacks are
 * implemented in tar.c.
 */

#ifndef TAR_H
#define TAR_H

#include "archive_plugin.h"

#include <stddef.h>
#include <stdint.h>

#define TAR_BLOCK_SIZE 512

/* Tar header layout. All numeric fields are NUL-terminated octal in
 * ASCII. Strings are NUL-terminated unless the field is full. */
typedef struct {
    char name[100];
    char mode[8];
    char uid[8];
    char gid[8];
    char size[12];
    char mtime[12];
    char chksum[8];
    char typeflag;
    char linkname[100];
    char magic[6];        /* "ustar\0" or "ustar " (gnu) */
    char version[2];
    char uname[32];
    char gname[32];
    char devmajor[8];
    char devminor[8];
    char prefix[155];
    char pad[12];
} tar_header_t;

/* Tar typeflag values we care about. */
#define TF_REGULAR       '0'
#define TF_AREGULAR      '\0'   /* old-style regular file */
#define TF_HARDLINK      '1'
#define TF_SYMLINK       '2'
#define TF_CHAR          '3'
#define TF_BLOCK         '4'
#define TF_DIRECTORY     '5'
#define TF_FIFO          '6'
#define TF_PAX_FILE      'x'    /* PAX per-file extended header */
#define TF_PAX_GLOBAL    'g'    /* PAX global extended header */
#define TF_GNU_LONGNAME  'L'    /* GNU @LongLink for filename */
#define TF_GNU_LONGLINK  'K'    /* GNU @LongLink for symlink target */

#endif /* TAR_H */
