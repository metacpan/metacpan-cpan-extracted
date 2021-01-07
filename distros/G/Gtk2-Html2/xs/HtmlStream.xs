/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
   Copyright (C) 2004 muppet
   Copyright (C) 2000-2001 CodeFactory AB
   Copyright (C) 2000-2001 Jonas Borgström <jonas@codefactory.se>
   Copyright (C) 2000-2001 Anders Carlsson <andersca@codefactory.se>
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, see
   <https://www.gnu.org/licenses/>.
*/
#include "gtkhtml2perl.h"

/* these are used for the stream constructor, which isn't yet bound,
 * and probably won't be bound if there's no reason you'd want to
 * construct a stream outside of gtkhtml2 itself. */
#if 0
/*
typedef void (* HtmlStreamCloseFunc) (HtmlStream *stream,
 				      gpointer user_data);
*/
static void
html_stream_close_func (HtmlStream *stream,
                        gpointer user_data)
{
	//
}

/*
typedef void (* HtmlStreamWriteFunc) (HtmlStream *stream,
 				      const gchar *buffer,
 				      guint size,
 				      gpointer user_data);
*/
static void
html_stream_write_func (HtmlStream *stream,
 		        const gchar *buffer,
 		        guint size,
 		        gpointer user_data)
{
	//
}
#endif

/*
typedef void (* HtmlStreamCancelFunc) (HtmlStream *stream,
 				      gpointer user_data,
 				      gpointer cancel_data);
*/
static void
html_stream_cancel_func (HtmlStream *stream,
                         gpointer user_data,
                         gpointer cancel_data)
{
	GPerlCallback * callback = (GPerlCallback*) cancel_data;
	gperl_callback_invoke (callback, NULL, stream, user_data);
}

MODULE = Gtk2::Html2::Stream	PACKAGE = Gtk2::Html2::Stream	PREFIX = html_stream_

 ## typedef struct _HtmlStream HtmlStream;
 ## typedef struct _HtmlStreamClass HtmlStreamClass;
 ## typedef void (* HtmlStreamCloseFunc) (HtmlStream *stream,
 ## 				      gpointer user_data);
 ## 
 ## typedef void (* HtmlStreamWriteFunc) (HtmlStream *stream,
 ## 				      const gchar *buffer,
 ## 				      guint size,
 ## 				      gpointer user_data);
 ## 
 ## typedef void (* HtmlStreamCancelFunc) (HtmlStream *stream,
 ## 				      gpointer user_data,
 ## 				      gpointer cancel_data);
 ## 
 ## 
 ## #define HTML_TYPE_STREAM (html_stream_get_type ())
 ## #define HTML_STREAM(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), HTML_TYPE_STREAM, HtmlStream))
 ## #define HTML_STREAM_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), HTML_TYPE_STREAM, HtmlStreamClass))
 ## #define HTML_IS_STREAM(obj) (G_TYPE_CHECK_INSTANCE_TYPE((obj), HTML_TYPE_STREAM))
 ## #define HTML_IS_STREAM_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), HTML_TYPE_STREAM))
 ## #define HTML_STREAM_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), HTML_TYPE_STREAM, HtmlStreamClass))
 ## 
 ## struct _HtmlStream {
 ## 	GObject parent_object;
 ## 	HtmlStreamWriteFunc write_func;
 ## 	HtmlStreamCloseFunc close_func;
 ## 	HtmlStreamCancelFunc cancel_func;
 ## 	gpointer user_data, cancel_data;
 ## 	gint written;
 ## 	char *mime_type;
 ## };
 ## 
 ## struct _HtmlStreamClass {
 ## 	GObjectClass parent_class;
 ## };
 ## 
 ## GType html_stream_get_type (void);

## ## HtmlStream *html_stream_new (HtmlStreamWriteFunc write_func, HtmlStreamCloseFunc close_func, gpointer user_data);
##HtmlStream_noinc *
##html_stream_new (class, SV * write_func, SV * close_func, SV * user_data=NULL)
##    CODE:
##	RETVAL = html_stream_new (html_stream_write_func,
##	                          html_stream_close_func, gpointer user_data);
##    OUTPUT:
##	RETVAL

##void html_stream_write (HtmlStream *stream, const gchar *buffer, guint size);
##void html_stream_write (HtmlStream *stream, const gchar_length *buffer, int length(buffer));
 ## this needs to be char*, not gchar*, because the utf8-mangling causes
 ## Bad Juju in image readers and such.
void html_stream_write (HtmlStream *stream, const char *buffer, int length(buffer));

void html_stream_close (HtmlStream *stream);

void html_stream_destroy (HtmlStream *stream);

gint html_stream_get_written (HtmlStream *stream);

void html_stream_cancel (HtmlStream *stream);

##void html_stream_set_cancel_func (HtmlStream *stream, HtmlStreamCancelFunc abort_func, gpointer cancel_data);
void html_stream_set_cancel_func (HtmlStream *stream, SV * abort_func, SV * cancel_data=NULL)
    PREINIT:
	GPerlCallback * callback = NULL;
	GType param_types[] = {
		HTML_TYPE_STREAM,
		GPERL_TYPE_SV
	};
    CODE:
	callback = gperl_callback_new (abort_func, cancel_data,
				       G_N_ELEMENTS (param_types),
				       param_types, G_TYPE_NONE);
	html_stream_set_cancel_func (stream,
				     html_stream_cancel_func,
				     callback);
	/* FIXME leaking the callback */

const char *html_stream_get_mime_type (HtmlStream *stream);

void html_stream_set_mime_type (HtmlStream *stream, const char *mime_type);

