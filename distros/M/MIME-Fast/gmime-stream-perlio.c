/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 *  Authors: Piotr Klaban <makler@man.torun.pl>
 *
 *  Copyright 2003,2004 Piotr Klaban
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Street #330, Boston, MA 02111-1307, USA.
 *
 */

#define PERL_NO_GET_CONTEXT     /* we want efficiency */

#include "gmime-stream-perlio.h"

// static PerlInterpreter *my_perl;

static void g_mime_stream_perlio_class_init (GMimeStreamPerlIOClass *klass);
static void g_mime_stream_perlio_init (GMimeStreamPerlIO *stream, GMimeStreamPerlIOClass *klass);
static void g_mime_stream_perlio_finalize (GObject *object);

static ssize_t stream_read (GMimeStream *stream, char *buf, size_t len);
static ssize_t stream_write (GMimeStream *stream, char *buf, size_t len);
static int stream_flush (GMimeStream *stream);
static int stream_close (GMimeStream *stream);
static gboolean stream_eos (GMimeStream *stream);
static int stream_reset (GMimeStream *stream);
static off_t stream_seek (GMimeStream *stream, off_t offset, GMimeSeekWhence whence);
static off_t stream_tell (GMimeStream *stream);
static ssize_t stream_length (GMimeStream *stream);
static GMimeStream *stream_substream (GMimeStream *stream, off_t start, off_t end);


static GMimeStreamClass *parent_class = NULL;


GType
g_mime_stream_perlio_get_type (void)
{
	static GType type = 0;
	
	if (!type) {
		static const GTypeInfo info = {
			sizeof (GMimeStreamPerlIOClass),
			NULL, /* base_class_init */
			NULL, /* base_class_finalize */
			(GClassInitFunc) g_mime_stream_perlio_class_init,
			NULL, /* class_finalize */
			NULL, /* class_data */
			sizeof (GMimeStreamPerlIO),
			16,   /* n_preallocs */
			(GInstanceInitFunc) g_mime_stream_perlio_init,
		};
		
		type = g_type_register_static (GMIME_TYPE_STREAM, "GMimeStreamPerlIO", &info, 0);
	}
	
	return type;
}


static void
g_mime_stream_perlio_class_init (GMimeStreamPerlIOClass *klass)
{
	GMimeStreamClass *stream_class = GMIME_STREAM_CLASS (klass);
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	
	parent_class = g_type_class_ref (GMIME_TYPE_STREAM);
	
	object_class->finalize = g_mime_stream_perlio_finalize;
	
	stream_class->read = stream_read;
	stream_class->write = stream_write;
	stream_class->flush = stream_flush;
	stream_class->close = stream_close;
	stream_class->eos = stream_eos;
	stream_class->reset = stream_reset;
	stream_class->seek = stream_seek;
	stream_class->tell = stream_tell;
	stream_class->length = stream_length;
	stream_class->substream = stream_substream;
}

static void
g_mime_stream_perlio_init (GMimeStreamPerlIO *stream, GMimeStreamPerlIOClass *klass)
{
	stream->owner = TRUE;
	stream->fp = NULL;
}

static void
g_mime_stream_perlio_finalize (GObject *object)
{
	GMimeStreamPerlIO *stream = (GMimeStreamPerlIO *) object;
	dTHX;
	
	if (stream->owner && stream->fp)
		PerlIO_close (stream->fp);
	
	G_OBJECT_CLASS (parent_class)->finalize (object);
}


static ssize_t
stream_read (GMimeStream *stream, char *buf, size_t len)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	ssize_t nread;
	dTHX;
	
	if (stream->bound_end != -1 && stream->position >= stream->bound_end)
		return -1;
	
	if (stream->bound_end != -1)
		len = MIN (stream->bound_end - stream->position, len);
	
	/* make sure we are at the right position */
	PerlIO_seek (fstream->fp, stream->position, SEEK_SET);
	
	nread = PerlIO_read (fstream->fp, buf, len);
	
	if (nread > 0)
		stream->position += nread;
	
	return nread;
}

static ssize_t
stream_write (GMimeStream *stream, char *buf, size_t len)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	ssize_t nwritten;
	dTHX;
	
	if (stream->bound_end != -1 && stream->position >= stream->bound_end)
		return -1;
	
	if (stream->bound_end != -1)
		len = MIN (stream->bound_end - stream->position, len);
	
	/* make sure we are at the right position */
	PerlIO_seek (fstream->fp, stream->position, SEEK_SET);
	
	nwritten = PerlIO_write (fstream->fp, buf, len);
	
	if (nwritten > 0)
		stream->position += nwritten;
	
	return nwritten;
}

static int
stream_flush (GMimeStream *stream)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	dTHX;

	g_return_val_if_fail (fstream->fp != NULL, -1);
	
	return PerlIO_flush (fstream->fp);
}

static int
stream_close (GMimeStream *stream)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	int ret;
	dTHX;

	g_return_val_if_fail (fstream->fp != NULL, -1);
	
	ret = PerlIO_close (fstream->fp);
	if (ret != -1)
		fstream->fp = NULL;
	
	return ret;
}

static gboolean
stream_eos (GMimeStream *stream)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	dTHX;

	g_return_val_if_fail (fstream->fp != NULL, TRUE);
	
	if (stream->bound_end == -1)
		return PerlIO_eof (fstream->fp) ? TRUE : FALSE;
	else
		return stream->position >= stream->bound_end;
}

static int
stream_reset (GMimeStream *stream)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	int ret;
	dTHX;

	g_return_val_if_fail (fstream->fp != NULL, -1);
	
	if (stream->position == stream->bound_start)
		return 0;
	
	ret = PerlIO_seek (fstream->fp, stream->bound_start, SEEK_SET);
	if (ret != -1)
		stream->position = stream->bound_start;
	
	return ret;
}

static off_t
stream_seek (GMimeStream *stream, off_t offset, GMimeSeekWhence whence)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	off_t real = stream->position;
	int ret;
	dTHX;

	g_return_val_if_fail (fstream->fp != NULL, -1);
	
	switch (whence) {
	case GMIME_STREAM_SEEK_SET:
		real = offset;
		break;
	case GMIME_STREAM_SEEK_CUR:
		real = stream->position + offset;
		break;
	case GMIME_STREAM_SEEK_END:
		if (stream->bound_end == -1) {
			PerlIO_seek (fstream->fp, offset, SEEK_END);
			real = PerlIO_tell (fstream->fp);
			if (real != -1) {
				if (real < stream->bound_start)
					real = stream->bound_start;
				stream->position = real;
			}
			return real;
		}
		real = stream->bound_end + offset;
		break;
	}
	
	if (stream->bound_end != -1)
		real = MIN (real, stream->bound_end);
	real = MAX (real, stream->bound_start);
	
	ret = PerlIO_seek (fstream->fp, real, SEEK_SET);
	if (ret == -1)
		return -1;
	
	stream->position = real;
	
	return real;
}

static off_t
stream_tell (GMimeStream *stream)
{
	return stream->position;
}

static ssize_t
stream_length (GMimeStream *stream)
{
	GMimeStreamPerlIO *fstream = (GMimeStreamPerlIO *) stream;
	off_t bound_end;
	dTHX;
	
	if (stream->bound_start != -1 && stream->bound_end != -1)
		return stream->bound_end - stream->bound_start;
	
	PerlIO_seek (fstream->fp, 0, SEEK_END);
	bound_end = PerlIO_tell (fstream->fp);
	PerlIO_seek (fstream->fp, stream->position, SEEK_SET);
	
	if (bound_end < stream->bound_start)
		return -1;
	
	return bound_end - stream->bound_start;
}

static GMimeStream *
stream_substream (GMimeStream *stream, off_t start, off_t end)
{
	GMimeStreamPerlIO *fstream;

	fstream = g_object_new (GMIME_TYPE_STREAM_PERLIO, NULL, NULL);
	fstream->owner = FALSE;
	fstream->fp = GMIME_STREAM_PERLIO (stream)->fp;

	g_mime_stream_construct (GMIME_STREAM (fstream), start, end);

	return GMIME_STREAM (fstream);
}


/**
 * g_mime_stream_perlio_new:
 * @fp: PerlIO pointer
 *
 * Creates a new GMimeStreamPerlIO object around @fp.
 *
 * Returns a stream using @fp.
 **/
GMimeStream *
g_mime_stream_perlio_new (PerlIO *fp)
{
	GMimeStreamPerlIO *fstream;
	dTHX;
	
	fstream = g_object_new (GMIME_TYPE_STREAM_PERLIO, NULL, NULL);
	fstream->owner = TRUE;
	fstream->fp = fp;
	
	GMIME_STREAM (fstream)->bound_end = -1;
	
	g_mime_stream_construct (GMIME_STREAM (fstream), PerlIO_tell (fp), -1);
	
	return GMIME_STREAM (fstream);
}


/**
 * g_mime_stream_perlio_new_with_bounds:
 * @fp: PerlIO pointer
 * @start: start boundary
 * @end: end boundary
 *
 * Creates a new GMimeStreamPerlIO object around @fp with bounds @start
 * and @end.
 *
 * Returns a stream using @fp with bounds @start and @end.
 **/
GMimeStream *
g_mime_stream_perlio_new_with_bounds (PerlIO *fp, off_t start, off_t end)
{
	GMimeStreamPerlIO *fstream;
	
	fstream = g_object_new (GMIME_TYPE_STREAM_PERLIO, NULL, NULL);
	fstream->owner = TRUE;
	fstream->fp = fp;
	
	g_mime_stream_construct (GMIME_STREAM (fstream), start, end);

	return GMIME_STREAM (fstream);
}


/**
 * g_mime_stream_perlio_get_owner:
 * @stream: PerlIO stream
 *
 * Gets whether or not @stream owns the backend PerlIO pointer.
 *
 * Returns %TRUE if @stream owns the backend PerlIO pointer or %FALSE
 * otherwise.
 **/
gboolean
g_mime_stream_perlio_get_owner (GMimeStreamPerlIO *stream)
{
	g_return_val_if_fail (GMIME_IS_STREAM_PERLIO (stream), FALSE);
	
	return stream->owner;
}


/**
 * g_mime_stream_perlio_set_owner:
 * @stream: PerlIO stream
 * @owner: owner
 *
 * Sets whether or not @stream owns the backend PerlIO pointer.
 *
 * Note: @owner should be %TRUE if the stream should fclose() the
 * backend PerlIO pointer when destroyed or %FALSE otherwise.
 **/
void
g_mime_stream_perlio_set_owner (GMimeStreamPerlIO *stream, gboolean owner)
{
	g_return_if_fail (GMIME_IS_STREAM_PERLIO (stream));
	
	stream->owner = owner;
}
