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


#ifndef __GMIME_STREAM_PERLIO_H__
#define __GMIME_STREAM_PERLIO_H__

#ifdef __cplusplus
extern "C" {
#pragma }
#endif /* __cplusplus */

#include <EXTERN.h>
#include <perl.h>
 
#include <glib.h>
#include <gmime/gmime-stream.h>

#define GMIME_TYPE_STREAM_PERLIO            (g_mime_stream_perlio_get_type ())
#define GMIME_STREAM_PERLIO(obj)            (GMIME_CHECK_CAST ((obj), GMIME_TYPE_STREAM_PERLIO, GMimeStreamPerlIO))
#define GMIME_STREAM_PERLIO_CLASS(klass)    (GMIME_CHECK_CLASS_CAST ((klass), GMIME_TYPE_STREAM_PERLIO, GMimeStreamPerlIOClass))
#define GMIME_IS_STREAM_PERLIO(obj)         (GMIME_CHECK_TYPE ((obj), GMIME_TYPE_STREAM_PERLIO))
#define GMIME_IS_STREAM_PERLIO_CLASS(klass) (GMIME_CHECK_CLASS_TYPE ((klass), GMIME_TYPE_STREAM_PERLIO))
#define GMIME_STREAM_PERLIO_GET_CLASS(obj)  (GMIME_CHECK_GET_CLASS ((obj), GMIME_TYPE_STREAM_PERLIO, GMimeStreamPerlIOClass))

typedef struct _GMimeStreamPerlIO GMimeStreamPerlIO;
typedef struct _GMimeStreamPerlIOClass GMimeStreamPerlIOClass;

struct _GMimeStreamPerlIO {
	GMimeStream parent_object;
	
	gboolean owner;
	PerlIO *fp;
};

struct _GMimeStreamPerlIOClass {
	GMimeStreamClass parent_class;
	
};


GType g_mime_stream_perlio_get_type (void);

GMimeStream *g_mime_stream_perlio_new (PerlIO *fp);
GMimeStream *g_mime_stream_perlio_new_with_bounds (PerlIO *fp, off_t start, off_t end);

void g_mime_stream_perlio_set_owner (GMimeStreamPerlIO *stream, gboolean owner);
gboolean g_mime_stream_perlio_get_owner (GMimeStreamPerlIO *stream);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __GMIME_STREAM_PERLIO_H__ */
