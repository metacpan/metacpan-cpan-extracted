/*
 * Copyright (C) 2003 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * $Id$
 */

#include "vfs2perl.h"

MODULE = Gnome2::VFS::URI	PACKAGE = Gnome2::VFS::URI	PREFIX = gnome_vfs_uri_

##  GnomeVFSURI *gnome_vfs_uri_new (const gchar *text_uri)
GnomeVFSURI_own *
gnome_vfs_uri_new (class, text_uri)
	const gchar *text_uri
    C_ARGS:
	text_uri

##  GnomeVFSURI *gnome_vfs_uri_resolve_relative (const GnomeVFSURI *base, const gchar *relative_reference)
GnomeVFSURI_own *
gnome_vfs_uri_resolve_relative (base, relative_reference)
	const GnomeVFSURI *base
	const gchar *relative_reference

###  GnomeVFSURI *gnome_vfs_uri_ref (GnomeVFSURI *uri)
#GnomeVFSURI *
#gnome_vfs_uri_ref (uri)
#	GnomeVFSURI *uri

###  void gnome_vfs_uri_unref (GnomeVFSURI *uri)
#void
#gnome_vfs_uri_unref (uri)
#	GnomeVFSURI *uri

##  GnomeVFSURI *gnome_vfs_uri_append_string (const GnomeVFSURI *uri, const char *uri_fragment)
GnomeVFSURI_own *
gnome_vfs_uri_append_string (base, uri_fragment)
	const GnomeVFSURI *base
	const char *uri_fragment

##  GnomeVFSURI *gnome_vfs_uri_append_path (const GnomeVFSURI *uri, const char *path)
GnomeVFSURI_own *
gnome_vfs_uri_append_path (base, path)
	const GnomeVFSURI *base
	const char *path

##  GnomeVFSURI *gnome_vfs_uri_append_file_name (const GnomeVFSURI *uri, const gchar *filename)
GnomeVFSURI_own *
gnome_vfs_uri_append_file_name (base, filename)
	const GnomeVFSURI *base
	const gchar *filename

##  gchar *gnome_vfs_uri_to_string (const GnomeVFSURI *uri, GnomeVFSURIHideOptions hide_options)
gchar_own *
gnome_vfs_uri_to_string (uri, hide_options=GNOME_VFS_URI_HIDE_NONE)
	const GnomeVFSURI *uri
	GnomeVFSURIHideOptions hide_options

###  GnomeVFSURI *gnome_vfs_uri_dup (const GnomeVFSURI *uri)
#GnomeVFSURI *
#gnome_vfs_uri_dup (uri)
#	const GnomeVFSURI *uri

##  gboolean gnome_vfs_uri_is_local (const GnomeVFSURI *uri)
gboolean
gnome_vfs_uri_is_local (uri)
	const GnomeVFSURI *uri

##  gboolean gnome_vfs_uri_has_parent (const GnomeVFSURI *uri)
gboolean
gnome_vfs_uri_has_parent (uri)
	const GnomeVFSURI *uri

##  GnomeVFSURI *gnome_vfs_uri_get_parent (const GnomeVFSURI *uri)
GnomeVFSURI_own *
gnome_vfs_uri_get_parent (uri)
	const GnomeVFSURI *uri

# FIXME: unless someone begs for this, I won't touch it.
###  GnomeVFSToplevelURI *gnome_vfs_uri_get_toplevel (const GnomeVFSURI *uri)
#GnomeVFSToplevelURI *
#gnome_vfs_uri_get_toplevel (uri)
#	const GnomeVFSURI *uri

##  guint gnome_vfs_uri_get_host_name (const GnomeVFSURI *uri)
const gchar *
gnome_vfs_uri_get_host_name (uri)
	const GnomeVFSURI *uri

##  guint gnome_vfs_uri_get_scheme (const GnomeVFSURI *uri)
const gchar *
gnome_vfs_uri_get_scheme (uri)
	const GnomeVFSURI *uri

##  guint gnome_vfs_uri_get_host_port (const GnomeVFSURI *uri)
guint
gnome_vfs_uri_get_host_port (uri)
	const GnomeVFSURI *uri

##  guint gnome_vfs_uri_get_user_name (const GnomeVFSURI *uri)
const gchar *
gnome_vfs_uri_get_user_name (uri)
	const GnomeVFSURI *uri

##  guint gnome_vfs_uri_get_password (const GnomeVFSURI *uri)
const gchar *
gnome_vfs_uri_get_password (uri)
	const GnomeVFSURI *uri

##  void gnome_vfs_uri_set_host_name (GnomeVFSURI *uri, const gchar *host_name)
void
gnome_vfs_uri_set_host_name (uri, host_name)
	GnomeVFSURI *uri
	const gchar *host_name

##  void gnome_vfs_uri_set_host_port (GnomeVFSURI *uri, guint host_port)
void
gnome_vfs_uri_set_host_port (uri, host_port)
	GnomeVFSURI *uri
	guint host_port

##  void gnome_vfs_uri_set_user_name (GnomeVFSURI *uri, const gchar *user_name)
void
gnome_vfs_uri_set_user_name (uri, user_name)
	GnomeVFSURI *uri
	const gchar *user_name

##  void gnome_vfs_uri_set_password (GnomeVFSURI *uri, const gchar *password)
void
gnome_vfs_uri_set_password (uri, password)
	GnomeVFSURI *uri
	const gchar *password

##  gboolean gnome_vfs_uri_equal (const GnomeVFSURI *a, const GnomeVFSURI *b)
gboolean
gnome_vfs_uri_equal (a, b)
	const GnomeVFSURI *a
	const GnomeVFSURI *b

##  gboolean gnome_vfs_uri_is_parent (const GnomeVFSURI *possible_parent, const GnomeVFSURI *possible_child, gboolean recursive)
gboolean
gnome_vfs_uri_is_parent (possible_parent, possible_child, recursive)
	const GnomeVFSURI *possible_parent
	const GnomeVFSURI *possible_child
	gboolean recursive

### const gchar *gnome_vfs_uri_get_path (const GnomeVFSURI *uri)
const gchar *
gnome_vfs_uri_get_path (uri)
	const GnomeVFSURI *uri

### const gchar *gnome_vfs_uri_get_fragment_identifier (const GnomeVFSURI *uri)
const gchar *
gnome_vfs_uri_get_fragment_identifier (uri)
	const GnomeVFSURI *uri

##  gchar *gnome_vfs_uri_extract_dirname (const GnomeVFSURI *uri)
gchar_own *
gnome_vfs_uri_extract_dirname (uri)
	const GnomeVFSURI *uri

##  gchar *gnome_vfs_uri_extract_short_name (const GnomeVFSURI *uri)
gchar_own *
gnome_vfs_uri_extract_short_name (uri)
	const GnomeVFSURI *uri

##  gchar *gnome_vfs_uri_extract_short_path_name (const GnomeVFSURI *uri)
gchar_own *
gnome_vfs_uri_extract_short_path_name (uri)
	const GnomeVFSURI *uri

###  gint gnome_vfs_uri_hequal (gconstpointer a, gconstpointer b)
#gint
#gnome_vfs_uri_hequal (a, b)
#	gconstpointer a
#	gconstpointer b

###  guint gnome_vfs_uri_hash (gconstpointer p)
#guint
#gnome_vfs_uri_hash (p)
#	gconstpointer p

=for apidoc

Returns a list of GnomeVFSURI's.

=cut
##  GList *gnome_vfs_uri_list_parse (const gchar* uri_list)
##  GList *gnome_vfs_uri_list_ref (GList *list)
##  GList *gnome_vfs_uri_list_unref (GList *list)
##  GList *gnome_vfs_uri_list_copy (GList *list)
##  void gnome_vfs_uri_list_free (GList *list)
void
gnome_vfs_uri_list_parse (class, uri_list)
	const gchar *uri_list
    PREINIT:
	GList *i, *list = NULL;
    PPCODE:
	list = gnome_vfs_uri_list_parse (uri_list);
	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGnomeVFSURI (i->data)));
	gnome_vfs_uri_list_free (list);

##  char *gnome_vfs_uri_make_full_from_relative (const char *base_uri, const char *relative_uri)
char *
gnome_vfs_uri_make_full_from_relative (class, base_uri, relative_uri)
	const char *base_uri
	const char *relative_uri
    C_ARGS:
	base_uri, relative_uri

#if VFS_CHECK_VERSION (2, 16, 0)

GnomeVFSURI_own * gnome_vfs_uri_resolve_symbolic_link (const GnomeVFSURI *base, const gchar *symbolic_link);

#endif
