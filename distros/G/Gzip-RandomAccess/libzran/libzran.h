#ifndef __LIBZRAN_H__
#define _GNU_SOURCE 1

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#ifdef DEBUG
#define TRACE(fmt, args...) fprintf(stderr, "%s[%d]: " fmt, __FUNCTION__, getpid(), ##args)
#else
#define TRACE(fmt, args...)
#endif

#define WINSIZE 32768U      /* sliding window size */
#define CHUNK 16384      /* file input buffer size */

#define GZIP_AUTO 32+MAX_WBITS
#define RAW_INFLATE -MAX_WBITS

/* access point entry */
struct point {
    off_t out;    /* corresponding offset in uncompressed data */
    off_t in;      /* offset in input file of first full byte */
    int data_type;      /* z_stream data_type field: number of bits (1-7) from byte at in - 1, or 0, & 64 if last block */
    unsigned char window[WINSIZE];  /* preceding 32K of uncompressed data */
};

struct zran_last {
    off_t offset;
    off_t point;
};

struct zran_file {
    char *filename;
    FILE *file;
    z_stream stream;
    unsigned char buf[CHUNK];
    enum {
	UNUSED = 0,
	INFLATE,
	DEFLATE
    } type;
    struct zran_last last;
};

struct zran {
    struct zran_file data;
    struct zran_file index;
    struct point *point;
    struct point *next;
};

void zran_cleanup(struct zran *zran);
struct zran *zran_init(char *filename, char *index_filename);
int zran_extract(struct zran *zran, off_t offset, void *buf, int len);
int zran_index_available(struct zran *zran);
int zran_build_index(struct zran *zran, off_t span, FILE *output);
off_t zran_uncompressed_size(struct zran *zran);

#define __LIBZRAN_H__
#endif
