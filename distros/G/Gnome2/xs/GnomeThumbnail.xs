/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

MODULE = Gnome2::Thumbnail	PACKAGE = Gnome2::ThumbnailFactory	PREFIX = gnome_thumbnail_factory_

BOOT:
/* pass -Werror even if there are no xsubs at all */
#ifndef GNOME_TYPE_THUMBNAIL_FACTORY
	PERL_UNUSED_VAR (file);
#endif

#ifdef GNOME_TYPE_THUMBNAIL_FACTORY

##  GnomeThumbnailFactory *gnome_thumbnail_factory_new (GnomeThumbnailSize size) 
GnomeThumbnailFactory *
gnome_thumbnail_factory_new (class, size)
	GnomeThumbnailSize size
    C_ARGS:
	size

##  char * gnome_thumbnail_factory_lookup (GnomeThumbnailFactory *factory, const char *uri, time_t mtime) 
char *
gnome_thumbnail_factory_lookup (factory, uri, mtime)
	GnomeThumbnailFactory *factory
	const char *uri
	time_t mtime

##  gboolean gnome_thumbnail_factory_has_valid_failed_thumbnail (GnomeThumbnailFactory *factory, const char *uri, time_t mtime) 
gboolean
gnome_thumbnail_factory_has_valid_failed_thumbnail (factory, uri, mtime)
	GnomeThumbnailFactory *factory
	const char *uri
	time_t mtime

##  gboolean gnome_thumbnail_factory_can_thumbnail (GnomeThumbnailFactory *factory, const char *uri, const char *mime_type, time_t mtime) 
gboolean
gnome_thumbnail_factory_can_thumbnail (factory, uri, mime_type, mtime)
	GnomeThumbnailFactory *factory
	const char *uri
	const char *mime_type
	time_t mtime

##  GdkPixbuf * gnome_thumbnail_factory_generate_thumbnail (GnomeThumbnailFactory *factory, const char *uri, const char *mime_type) 
GdkPixbuf *
gnome_thumbnail_factory_generate_thumbnail (factory, uri, mime_type)
	GnomeThumbnailFactory *factory
	const char *uri
	const char *mime_type

##  void gnome_thumbnail_factory_save_thumbnail (GnomeThumbnailFactory *factory, GdkPixbuf *thumbnail, const char *uri, time_t original_mtime) 
void
gnome_thumbnail_factory_save_thumbnail (factory, thumbnail, uri, original_mtime)
	GnomeThumbnailFactory *factory
	GdkPixbuf *thumbnail
	const char *uri
	time_t original_mtime

##  void gnome_thumbnail_factory_create_failed_thumbnail (GnomeThumbnailFactory *factory, const char *uri, time_t mtime) 
void
gnome_thumbnail_factory_create_failed_thumbnail (factory, uri, mtime)
	GnomeThumbnailFactory *factory
	const char *uri
	time_t mtime

MODULE = Gnome2::Thumbnail	PACKAGE = Gtk2::Gdk::Pixbuf	PREFIX = gnome_thumbnail_

=for object Gnome2::Thumbnail
=cut

##  gboolean gnome_thumbnail_has_uri (GdkPixbuf *pixbuf, const char *uri) 
gboolean
gnome_thumbnail_has_uri (pixbuf, uri)
	GdkPixbuf *pixbuf
	const char *uri

##  gboolean gnome_thumbnail_is_valid (GdkPixbuf *pixbuf, const char *uri, time_t mtime) 
gboolean
gnome_thumbnail_is_valid (pixbuf, uri, mtime)
	GdkPixbuf *pixbuf
	const char *uri
	time_t mtime

##  char * gnome_thumbnail_md5 (const char *uri) 
char *
gnome_thumbnail_md5 (class, uri)
	const char *uri
    C_ARGS:
	uri

##  char * gnome_thumbnail_path_for_uri (const char *uri, GnomeThumbnailSize size) 
char *
gnome_thumbnail_path_for_uri (class, uri, size)
	const char *uri
	GnomeThumbnailSize size
    C_ARGS:
	uri, size

##  GdkPixbuf *gnome_thumbnail_scale_down_pixbuf (GdkPixbuf *pixbuf, int dest_width, int dest_height) 
GdkPixbuf *
gnome_thumbnail_scale_down_pixbuf (pixbuf, dest_width, dest_height)
	GdkPixbuf *pixbuf
	int dest_width
	int dest_height

#endif /* have GnomeThumbnailFactory */
