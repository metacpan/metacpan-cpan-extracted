/*
 * Copyright (C) 2003, 2013 by the gtk2-perl team
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

MODULE = Gnome2::VFS::ApplicationRegistry	PACKAGE = Gnome2::VFS::ApplicationRegistry	PREFIX = gnome_vfs_application_registry_

SV *
gnome_vfs_application_registry_new (class, app_id)
	const char *app_id
    CODE:
	RETVAL = newSVGnomeVFSApplication (app_id);
    OUTPUT:
	RETVAL

##  GnomeVFSResult gnome_vfs_application_registry_sync (void) 
GnomeVFSResult
gnome_vfs_application_registry_sync (class)
    C_ARGS:
	/* void */

##  void gnome_vfs_application_registry_shutdown (void) 
void
gnome_vfs_application_registry_shutdown (class)
    C_ARGS:
	/* void */

##  void gnome_vfs_application_registry_reload (void) 
void
gnome_vfs_application_registry_reload (class)
    C_ARGS:
	/* void */

=for apidoc

Returns a list of valid application id's that can handle this MIME type.

=cut
##  GList *gnome_vfs_application_registry_get_applications(const char *mime_type) 
void
gnome_vfs_application_registry_get_applications (class, mime_type=NULL)
	const char *mime_type
    PREINIT:
	GList *i, *results = NULL;
    PPCODE:
	results = gnome_vfs_application_registry_get_applications (mime_type);
	for (i = results; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVpv (i->data, 0)));
	g_list_free (results);

MODULE = Gnome2::VFS::ApplicationRegistry	PACKAGE = Gnome2::VFS::Application	PREFIX = gnome_vfs_application_registry_

##  gboolean gnome_vfs_application_registry_exists (const char *app_id) 
gboolean
gnome_vfs_application_registry_exists (app_id)
	GnomeVFSApplication *app_id

=for apidoc

Returns a list of valid keys for that application.

=cut
##  GList *gnome_vfs_application_registry_get_keys (const char *app_id) 
void
gnome_vfs_application_registry_get_keys (app_id)
	GnomeVFSApplication *app_id
    PREINIT:
	GList *i, *results = NULL;
    PPCODE:
	results = gnome_vfs_application_registry_get_keys (app_id);
	for (i = results; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVpv (i->data, 0)));
	g_list_free (results);

##  const char *gnome_vfs_application_registry_peek_value (const char *app_id, const char *key)
const char *
gnome_vfs_application_registry_peek_value (app_id, key)
	GnomeVFSApplication *app_id
	const char *key

=for apidoc

Returns the actual value and a boolean indicating whether the requested key was
found.

=cut
##  gboolean gnome_vfs_application_registry_get_bool_value (const char *app_id, const char *key, gboolean *got_key) 
void
gnome_vfs_application_registry_get_bool_value (app_id, key)
	GnomeVFSApplication *app_id
	const char *key
    PREINIT:
	gboolean result;
	gboolean got_key;
    PPCODE:
	result = gnome_vfs_application_registry_get_bool_value (app_id, key, &got_key);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVuv (result)));
	PUSHs (sv_2mortal (newSVuv (got_key)));

##  void gnome_vfs_application_registry_remove_application(const char *app_id) 
void
gnome_vfs_application_registry_remove_application (app_id)
	GnomeVFSApplication *app_id

##  void gnome_vfs_application_registry_set_value (const char *app_id, const char *key, const char *value) 
void
gnome_vfs_application_registry_set_value (app_id, key, value)
	GnomeVFSApplication *app_id
	const char *key
	const char *value

##  void gnome_vfs_application_registry_set_bool_value (const char *app_id, const char *key, gboolean value) 
void
gnome_vfs_application_registry_set_bool_value (app_id, key, value)
	GnomeVFSApplication *app_id
	const char *key
	gboolean value

##  void gnome_vfs_application_registry_unset_key (const char *app_id, const char *key) 
void
gnome_vfs_application_registry_unset_key (app_id, key)
	GnomeVFSApplication *app_id
	const char *key

=for apidoc

Returns a list of MIME types this application can handle.

=cut
##  GList *gnome_vfs_application_registry_get_mime_types (const char *app_id) 
void
gnome_vfs_application_registry_get_mime_types (app_id)
	GnomeVFSApplication *app_id
    PREINIT:
	GList *i, *results = NULL;
    PPCODE:
	results = gnome_vfs_application_registry_get_mime_types (app_id);
	for (i = results; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVpv (i->data, 0)));
	g_list_free (results);

##  gboolean gnome_vfs_application_registry_supports_mime_type (const char *app_id, const char *mime_type) 
gboolean
gnome_vfs_application_registry_supports_mime_type (app_id, mime_type)
	GnomeVFSApplication *app_id
	const char *mime_type

##  gboolean gnome_vfs_application_registry_supports_uri_scheme (const char *app_id, const char *uri_scheme) 
gboolean
gnome_vfs_application_registry_supports_uri_scheme (app_id, uri_scheme)
	GnomeVFSApplication *app_id
	const char *uri_scheme

##  void gnome_vfs_application_registry_clear_mime_types (const char *app_id) 
void
gnome_vfs_application_registry_clear_mime_types (app_id)
	GnomeVFSApplication *app_id

##  void gnome_vfs_application_registry_add_mime_type (const char *app_id, const char *mime_type) 
void
gnome_vfs_application_registry_add_mime_type (app_id, mime_type)
	GnomeVFSApplication *app_id
	const char *mime_type

##  void gnome_vfs_application_registry_remove_mime_type (const char *app_id, const char *mime_type) 
void
gnome_vfs_application_registry_remove_mime_type (app_id, mime_type)
	GnomeVFSApplication *app_id
	const char *mime_type

##  GnomeVFSMimeApplication * gnome_vfs_application_registry_get_mime_application(const char *app_id) 
GnomeVFSMimeApplication *
gnome_vfs_application_registry_get_mime_application (app_id)
	GnomeVFSApplication *app_id

MODULE = Gnome2::VFS::ApplicationRegistry	PACKAGE = Gnome2::VFS::Mime::Application	PREFIX = gnome_vfs_mime_application_

##  gboolean gnome_vfs_application_is_user_owned_application (const GnomeVFSMimeApplication *application) 
gboolean
gnome_vfs_mime_application_is_user_owned (application)
	const GnomeVFSMimeApplication *application
    CODE:
	RETVAL = gnome_vfs_application_is_user_owned_application (application);
    OUTPUT:
	RETVAL

##  void gnome_vfs_application_registry_save_mime_application(const GnomeVFSMimeApplication *application) 
void
gnome_vfs_mime_application_save (application)
	const GnomeVFSMimeApplication *application
    CODE:
	gnome_vfs_application_registry_save_mime_application (application);
