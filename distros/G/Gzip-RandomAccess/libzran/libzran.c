/* The following code is based on work by Iain Wade (libzran conversion)
 * and Mark Adler (zran.c, from the gzip distribution) */
/*
  zran.c is Copyright (C) 2005 Mark Adler.

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  Jean-loup Gailly jloup@gzip.org
  Mark Adler madler@alumni.caltech.edu

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "zlib.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <assert.h>
#include "libzran.h"

static void zran_file_cleanup(struct zran_file *zf, int flags);
static int zran_inflate_open(struct zran_file *zf, int wbits);
static int zran_deflate_open(struct zran_file *zf, int level);
static void zran_index_cleanup(struct zran *zran, int flags);
static int zran_index_open(struct zran *zran);
static struct point *zran_index_load_point(struct zran *zran);
static void zran_index_next_point(struct zran *zran);
static int zran_index_save_point(struct zran_file *zf, struct point *point);

#define ZRAN_FL_CLOSE 1
#define ZRAN_EOF_POINT(x) ((x)->data_type & 64)

static void zran_file_cleanup(struct zran_file *zf, int flags)
{
    TRACE("zran_file_cleanup(%s, %d)\n", zf->filename, flags);

    if (zf->type == INFLATE)
	(void)inflateEnd(&(zf->stream));
    else if (zf->type == DEFLATE)
	(void)deflateEnd(&(zf->stream));

    zf->type = UNUSED;

    if ((flags & ZRAN_FL_CLOSE) && zf->file)
    {
	fclose(zf->file);
	zf->file = NULL;
    }
}

static int zran_inflate_open(struct zran_file *zf, int wbits)
{
    int ret;

    TRACE("zran_inflate_open(%s, %d)\n", zf->filename, wbits);

    if (!zf->file && !(zf->file = fopen(zf->filename, "r")))
	goto err;

    if (fseek(zf->file, 0, SEEK_SET) < 0)
	goto err;

    zran_file_cleanup(zf, 0);

    memset(&(zf->stream), 0, sizeof(z_stream));

    /* allocate inflate state */
    zf->stream.zalloc = Z_NULL;
    zf->stream.zfree = Z_NULL;
    zf->stream.opaque = Z_NULL;
    zf->stream.avail_in = 0;
    zf->stream.next_in = Z_NULL;

    if ((ret = inflateInit2(&(zf->stream), wbits)) != Z_OK)
	goto err;

    zf->type = INFLATE;

    return 1;
err:
    zran_file_cleanup(zf, ZRAN_FL_CLOSE);

    return 0;
}

static int zran_deflate_open(struct zran_file *zf, int level)
{
    int ret;

    TRACE("zran_deflate_open(%s, %d)\n", zf->filename, level);

    if (!zf->file && !(zf->file = fopen(zf->filename, "w")))
	goto err;

    if (fseek(zf->file, 0, SEEK_SET) < 0)
	goto err;

    zran_file_cleanup(zf, 0);

    memset(&(zf->stream), 0, sizeof(z_stream));

    /* allocate deflate state */
    zf->stream.zalloc = Z_NULL;
    zf->stream.zfree = Z_NULL;
    zf->stream.opaque = Z_NULL;

    if ((ret = deflateInit(&(zf->stream), level)) != Z_OK)
	goto err;

    zf->type = DEFLATE;

    return 1;
err:
    zran_file_cleanup(zf, ZRAN_FL_CLOSE);

    return 0;
}

static void zran_index_cleanup(struct zran *zran, int flags)
{
    TRACE("zran_index_cleanup(%s, %d)\n", zran->index.filename, flags);

    if (zran->point)
    {
	free(zran->point);
	zran->point = NULL;
    }

    if (zran->next)
    {
	free(zran->next);
	zran->next = NULL;
    }

    zran_file_cleanup(&(zran->index), flags);
}

static int zran_index_open(struct zran *zran)
{
    TRACE("zran_index_open(%s)\n", zran->index.filename);

    zran_index_cleanup(zran, ZRAN_FL_CLOSE);

    if (!zran_inflate_open(&(zran->index), GZIP_AUTO))
	goto err;

    zran_index_next_point(zran);

    return 1;
err:
    return 0;
}

int zran_index_available(struct zran *zran)
{
    TRACE("zran_index_available(%s)\n", zran->index.filename);

    if (zran->point)
	return 1;

    if (!(zran_index_open(zran)))
	goto err;

    if (!(zran->point))
	goto err;

    return 1;
err:
    return 0;
}

void zran_cleanup(struct zran *zran)
{
    TRACE("zran_cleanup(%p)\n", zran);

    zran_index_cleanup(zran, ZRAN_FL_CLOSE);

    free(zran->index.filename);
    zran->index.filename = NULL;

    zran_file_cleanup(&(zran->data), ZRAN_FL_CLOSE);

    free(zran->data.filename);
    zran->data.filename = NULL;

    free(zran);
}

struct zran *zran_init(char *filename, char *index_filename)
{
    struct zran *zran;

    TRACE("zran_init(%s)\n", filename);

    if (!(zran = malloc(sizeof(struct zran))))
	goto err;

    memset(zran, 0, sizeof(struct zran));
    zran->data.last.offset = -1;
    zran->data.last.point = -1;

    if (!(zran->data.filename = strdup(filename)))
	goto err;

    if (index_filename)
    {
	if (!(zran->index.filename = strdup(index_filename)))
	    goto err;
    }
    else
    {
	if (asprintf(&(zran->index.filename), "%s.idx", filename) < 0)
	    goto err;
    }

    return zran;
err:
    zran_cleanup(zran);
    return NULL;
}

static struct point *zran_index_load_point(struct zran *zran)
{
    int ret;
    struct point *point;

    TRACE("zran_index_load_point(%p)\n", zran);

    if (!(point = malloc(sizeof(struct point))))
	goto err;

    zran->index.stream.next_out = (Bytef *)point;
    zran->index.stream.avail_out = sizeof(struct point);

    /* run inflate() on input until output buffer not full */
    do {
	if (zran->index.stream.avail_in == 0)
	{
	    if (!(zran->index.stream.avail_in = fread(zran->index.buf, 1, sizeof(zran->index.buf), zran->index.file)) || ferror(zran->index.file))
		goto err;

	    zran->index.stream.next_in = (Bytef *)&(zran->index.buf);
	}

	switch (ret = inflate(&(zran->index.stream), Z_NO_FLUSH))
	{
	case Z_OK:
	    break;
	case Z_STREAM_END:
	    if (zran->index.stream.avail_out == 0)
		break;
	default:
	    assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
	    zran_file_cleanup(&(zran->index), 0);
	    goto err;
	}
    } while (zran->index.stream.avail_out != 0);

    return point;
err:
    if (point)
	free(point);
    return NULL;
}

static void zran_index_next_point(struct zran *zran)
{
    TRACE("zran_index_next_point(%p)\n", zran);

    if (!zran->point)
    {
	if (!(zran->point = zran_index_load_point(zran)))
	    return;

	if (!zran->next)
	    zran->next = zran_index_load_point(zran);
    }
    else
    {
	free(zran->point);
	zran->point = zran->next;
	zran->next = zran_index_load_point(zran);
    }
}

static int zran_index_save_point(struct zran_file *zf, struct point *point)
{
    char out[CHUNK];
    unsigned have;
    int ret, flush;

    if (point)
	TRACE("POINT: out=%llu, in=%llu\n", point->out, point->in);

    zf->stream.avail_in = point ? sizeof(struct point) : 0;
    zf->stream.next_in = (Bytef *)point;
    flush = point ? Z_NO_FLUSH : Z_FINISH;

    /* run deflate() on input until output buffer not full, finish
       compression if all of source has been read in */
    do {
	zf->stream.avail_out = CHUNK;
	zf->stream.next_out = (Bytef *)out;
	ret = deflate(&(zf->stream), flush);    /* no bad return value */
	assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
	have = CHUNK - zf->stream.avail_out;
	if (fwrite(out, 1, have, zf->file) != have || ferror(zf->file))
	    goto err;
    } while (zf->stream.avail_out == 0);
    assert(zf->stream.avail_in == 0);     /* all input will be used */

    if (flush == Z_FINISH)
    {
	assert(ret == Z_STREAM_END);	/* stream will be complete */

	/* clean up and return */
	zran_file_cleanup(zf, 0);
    }

    return 1;
err:
    zran_file_cleanup(zf, ZRAN_FL_CLOSE);
    return 0;
}

/* Use the index to read len bytes from offset into buf, return bytes read or
   negative for error (Z_DATA_ERROR or Z_MEM_ERROR).  If data is requested past
   the end of the uncompressed data, then extract() will return a value less
   than len, indicating how much as actually read into buf.  This function
   should not return a data error unless the file was modified since the index
   was generated.  extract() may also return Z_ERRNO if there is an error on
   reading or seeking the input file. */
int zran_extract(struct zran *zran, off_t offset, void *buf, int len)
{
    int ret;
    off_t skip;
    unsigned char discard[WINSIZE];

    /* proceed only if something reasonable to do */
    if (len < 0)
	return -1;

    /* index position needs (?:re)?setting */
    if (!zran->point || zran->point->out > offset || ZRAN_EOF_POINT(zran->point))
	zran_index_open(zran);

    if (!zran->point || ZRAN_EOF_POINT(zran->point))
	return -1;

    while (zran->next && (zran->next->out <= offset) && !ZRAN_EOF_POINT(zran->next))
	zran_index_next_point(zran);

TRACE("last(offset=%lld,point=%lld) offset=%lld, point=%p(out=%llu) next=%p(out=%llu) len=%ld\n",
    zran->data.last.offset, zran->data.last.point, offset, zran->point, zran->point->out, zran->next, zran->next->out, len);

if (zran->data.last.offset <= offset && zran->data.last.point == zran->point->out)
{
    skip = offset - zran->data.last.offset;
    TRACE("fast-path (skip=%lld)\n", skip);
}
else
{
    int bits = zran->point->data_type & 7;
    TRACE("POINT: in=%llu, out=%llu, bits=%u\n", zran->point->in, zran->point->out, bits);

    zran_inflate_open(&(zran->data), RAW_INFLATE);

    if ((ret = fseeko(zran->data.file, zran->point->in - (bits ? 1 : 0), SEEK_SET)) < 0)
	goto extract_ret;

    if (bits)
    {
	if ((ret = getc(zran->data.file)) == -1)
	{
	    ret = ferror(zran->data.file) ? Z_ERRNO : Z_DATA_ERROR;
	    goto extract_ret;
	}

	(void)inflatePrime(&(zran->data.stream), bits, ret >> (8 - bits));
    }

    (void)inflateSetDictionary(&(zran->data.stream), zran->point->window, WINSIZE);

    /* skip uncompressed bytes until offset reached, then satisfy request */
    skip = offset - zran->point->out;
    zran->data.stream.avail_in = 0;
}

    zran->data.last.offset = offset+len;
    zran->data.last.point = zran->point->out;

    do {
	/* define where to put uncompressed data, and how much */
	if (skip == 0) {	  /* at offset now */
	    zran->data.stream.avail_out = len;
	    zran->data.stream.next_out = buf;
	    skip = -1;		       /* only do this once */
	}
	if (skip > WINSIZE) {	     /* skip WINSIZE bytes */
	    zran->data.stream.avail_out = WINSIZE;
	    zran->data.stream.next_out = discard;
	    skip -= WINSIZE;
	}
	else if (skip > 0) {	     /* last skip */
	    zran->data.stream.avail_out = (unsigned)skip;
	    zran->data.stream.next_out = discard;
	    skip = 0;
	}

	/* uncompress until avail_out filled, or end of stream */
	do {
	    if (zran->data.stream.avail_in == 0) {
		zran->data.stream.avail_in = fread(zran->data.buf, 1, sizeof(zran->data.buf), zran->data.file);
		if (ferror(zran->data.file)) {
		    ret = Z_ERRNO;
		    goto extract_ret;
		}
		if (zran->data.stream.avail_in == 0) {
		    ret = Z_DATA_ERROR;
		    goto extract_ret;
		}
		zran->data.stream.next_in = zran->data.buf;
	    }
	    ret = inflate(&(zran->data.stream), Z_NO_FLUSH);       /* normal inflate */
	    if (ret == Z_NEED_DICT)
		ret = Z_DATA_ERROR;
	    if (ret == Z_MEM_ERROR || ret == Z_DATA_ERROR)
		goto extract_ret;
	    if (ret == Z_STREAM_END)
		break;
	} while (zran->data.stream.avail_out != 0);

	/* if reach end of stream, then don't keep trying to get more */
	if (ret == Z_STREAM_END)
	    break;

	/* do until offset reached and requested data read, or stream ends */
    } while (skip >= 0);

    /* compute number of uncompressed bytes read after offset */
    ret = skip >= 0 ? 0 : len - zran->data.stream.avail_out;

    return ret;

    /* clean up and return bytes read or error */
  extract_ret:
    TRACE("closing on failure\n");
    zran_file_cleanup(&(zran->data), ZRAN_FL_CLOSE);
    return -1;
}

/* Make one entire pass through the compressed stream and build an index, with
   access points about every span bytes of uncompressed output -- span is
   chosen to balance the speed of random access against the memory requirements
   of the list, about 32K bytes per access point.  Note that data after the end
   of the first zlib or gzip stream in the file is ignored.  build_index()
   returns the number of access points on success (>= 1), Z_MEM_ERROR for out
   of memory, Z_DATA_ERROR for an error in the input file, or Z_ERRNO for a
   file read error.  On success, *built points to the resulting index. */
int zran_build_index(struct zran *zran, off_t span, FILE *out)
{
    int ret;
    off_t totin, totout;	/* our own total counters to avoid 4GB limit */
    off_t last;	 /* totout value of last access point */
    unsigned char input[CHUNK];
    unsigned char window[WINSIZE];
    void *ptr;
    int consumed, produced;

    zran_index_cleanup(zran, ZRAN_FL_CLOSE);

    if (!zran_inflate_open(&(zran->data), GZIP_AUTO))
	goto build_index_error;

    if (!zran_deflate_open(&(zran->index), Z_BEST_COMPRESSION))
	goto build_index_error;

    /* inflate the input, maintain a sliding window, and build an index -- this
       also validates the integrity of the compressed data using the check
       information at the end of the gzip or zlib stream */
    totin = totout = last = 0;
    zran->data.stream.avail_out = 0;
    do {
	/* get some compressed data from input file */
	if (!(zran->data.stream.avail_in = fread(input, 1, CHUNK, zran->data.file)) || ferror(zran->data.file))
	{
	    ret = Z_ERRNO;
	    goto build_index_error;
	}

	zran->data.stream.next_in = input;

	/* process all of that, or until end of stream */
	do {
	    /* reset sliding window if necessary */
	    if (zran->data.stream.avail_out == 0)
	    {
		zran->data.stream.avail_out = WINSIZE;
		zran->data.stream.next_out = window;
	    }

	    /* inflate until out of input, output, or at end of block --
	       update the total input and output counters */
	    ptr = zran->data.stream.next_out;
	    produced = zran->data.stream.avail_out;
	    consumed = zran->data.stream.avail_in;
	    ret = inflate(&(zran->data.stream), Z_BLOCK);      /* return at end of block */
	    totin += (consumed -= zran->data.stream.avail_in);
	    totout += (produced -= zran->data.stream.avail_out);

	    if (ret == Z_NEED_DICT)
		ret = Z_DATA_ERROR;
	    if (ret == Z_MEM_ERROR || ret == Z_DATA_ERROR)
		goto build_index_error;
	    if (ret == Z_STREAM_END)
		break;

	    if (out && produced)
	    {
		if (fwrite(ptr, 1, produced, out) != produced || ferror(out))
		    goto build_index_error;
	    }

	    /* if at end of block, consider adding an index entry (note that if
	       data_type indicates an end-of-block, then all of the
	       uncompressed data from that block has been delivered, and none
	       of the compressed data after that block has been consumed,
	       except for up to seven bits) -- the totout == 0 provides an
	       entry point after the zlib or gzip header, and assures that the
	       index always has at least one access point */

	    if ( (zran->data.stream.data_type & 128)
		 && ((zran->data.stream.data_type & 64) || totout == 0 || totin - last > span) )
	    {
		struct point point;

		/* fill in entry and increment how many we have */
		point.data_type = zran->data.stream.data_type;
		point.in = totin;
		point.out = totout;
		if (zran->data.stream.avail_out)
		    memcpy(point.window, window + WINSIZE - zran->data.stream.avail_out, zran->data.stream.avail_out);
		if (zran->data.stream.avail_out < WINSIZE)
		    memcpy(point.window + zran->data.stream.avail_out, window, WINSIZE - zran->data.stream.avail_out);

		if (!(zran_index_save_point(&(zran->index), &point)))
		    goto build_index_error;

		last = totin;
	    }
	} while (zran->data.stream.avail_in != 0);
    } while (ret != Z_STREAM_END);

    if (!(zran_index_save_point(&(zran->index), NULL))) /* finish up */
	goto build_index_error;

    zran_file_cleanup(&(zran->index), ZRAN_FL_CLOSE);
    zran_file_cleanup(&(zran->data), ZRAN_FL_CLOSE);

    return 0;

    /* return error */
  build_index_error:
    TRACE("could not build index\n");
    return -1;
}

off_t zran_uncompressed_size(struct zran *zran) {
    zran_index_open(zran);
    if (!zran->point)
	return -1;

    while (zran->next) {
	zran_index_next_point(zran);
    }

    if (!ZRAN_EOF_POINT(zran->point)) {
	/* last point is not the last block - truncated? */
	return -1;
    }

    return zran->point->out;
}

