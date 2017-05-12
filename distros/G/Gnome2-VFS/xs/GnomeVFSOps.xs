/*
 * Copyright (C) 2003-2005 by the gtk2-perl team
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
#include <gperl_marshal.h>

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_monitor_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_monitor_callback (GnomeVFSMonitorHandle *handle,
                           const gchar *monitor_uri,
                           const gchar *info_uri,
                           GnomeVFSMonitorEventType event_type,
                           GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVGnomeVFSMonitorHandle (handle)));
	PUSHs (sv_2mortal (newSVGChar (monitor_uri)));
	PUSHs (sv_2mortal (newSVGChar (info_uri)));
	PUSHs (sv_2mortal (newSVGnomeVFSMonitorEventType (event_type)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	SPAGAIN;

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::Ops	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::main

=cut

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSHandle.

=cut
##  GnomeVFSResult gnome_vfs_open (GnomeVFSHandle **handle, const gchar *text_uri, GnomeVFSOpenMode open_mode)
void
gnome_vfs_open (class, text_uri, open_mode)
	const gchar *text_uri
	GnomeVFSOpenMode open_mode
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSHandle *handle;
    PPCODE:
	result = gnome_vfs_open (&handle, text_uri, open_mode);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSHandle (handle)));


=for apidoc

Returns a GnomeVFSResult and a GnomeVFSHandle.

=cut
##  GnomeVFSResult gnome_vfs_create (GnomeVFSHandle **handle, const gchar *text_uri, GnomeVFSOpenMode open_mode, gboolean exclusive, guint perm) 
void
gnome_vfs_create (class, text_uri, open_mode, exclusive, perm)
	const gchar *text_uri
	GnomeVFSOpenMode open_mode
	gboolean exclusive
	guint perm
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSHandle *handle;
    PPCODE:
	result = gnome_vfs_create (&handle, text_uri, open_mode, exclusive, perm);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSHandle (handle)));

##  GnomeVFSResult gnome_vfs_unlink (const gchar *text_uri) 
GnomeVFSResult
gnome_vfs_unlink (class, text_uri)
	const gchar *text_uri
    C_ARGS:
	text_uri

##  GnomeVFSResult gnome_vfs_move (const gchar *old_text_uri, const gchar *new_text_uri, gboolean force_replace) 
GnomeVFSResult
gnome_vfs_move (class, old_text_uri, new_text_uri, force_replace)
	const gchar *old_text_uri
	const gchar *new_text_uri
	gboolean force_replace
    C_ARGS:
	old_text_uri, new_text_uri, force_replace


=for apidoc

Returns a GnomeVFSResult and a boolean.

=cut
##  GnomeVFSResult gnome_vfs_check_same_fs (const gchar *source, const gchar *target, gboolean *same_fs_return) 
void
gnome_vfs_check_same_fs (class, source, target)
	const gchar *source
	const gchar *target
    PREINIT:
	GnomeVFSResult result;
	gboolean same_fs_return;
    PPCODE:
	result = gnome_vfs_check_same_fs (source, target, &same_fs_return);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVuv (same_fs_return)));

##  GnomeVFSResult gnome_vfs_create_symbolic_link (GnomeVFSURI *uri, const gchar *target_reference) 
GnomeVFSResult
gnome_vfs_create_symbolic_link (class, uri, target_reference)
	GnomeVFSURI *uri
	const gchar *target_reference
    C_ARGS:
	uri, target_reference


=for apidoc

Returns a GnomeVFSResult and a GnomeVFSFileInfo.

=cut
##  GnomeVFSResult gnome_vfs_get_file_info (const gchar *text_uri, GnomeVFSFileInfo *info, GnomeVFSFileInfoOptions options) 
void
gnome_vfs_get_file_info (class, text_uri, options)
	const gchar *text_uri
	GnomeVFSFileInfoOptions options
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSFileInfo *info;
    PPCODE:
	info = gnome_vfs_file_info_new ();
	result = gnome_vfs_get_file_info (text_uri, info, options);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileInfo (info)));
	gnome_vfs_file_info_unref (info);

##  GnomeVFSResult gnome_vfs_truncate (const gchar *text_uri, GnomeVFSFileSize length) 
GnomeVFSResult
gnome_vfs_truncate (class, text_uri, length)
	const gchar *text_uri
	GnomeVFSFileSize length
    C_ARGS:
	text_uri, length

##  GnomeVFSResult gnome_vfs_make_directory (const gchar *text_uri, guint perm) 
GnomeVFSResult
gnome_vfs_make_directory (class, text_uri, perm)
	const gchar *text_uri
	guint perm
    C_ARGS:
	text_uri, perm

##  GnomeVFSResult gnome_vfs_remove_directory (const gchar *text_uri) 
GnomeVFSResult
gnome_vfs_remove_directory (class, text_uri)
	const gchar *text_uri
    C_ARGS:
	text_uri

##  GnomeVFSResult gnome_vfs_set_file_info (const gchar *text_uri, GnomeVFSFileInfo *info, GnomeVFSSetFileInfoMask mask) 
GnomeVFSResult
gnome_vfs_set_file_info (class, text_uri, info, mask)
	const gchar *text_uri
	GnomeVFSFileInfo *info
	GnomeVFSSetFileInfoMask mask
    C_ARGS:
	text_uri, info, mask

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Ops	PACKAGE = Gnome2::VFS::Handle	PREFIX = gnome_vfs_

##  GnomeVFSResult gnome_vfs_close (GnomeVFSHandle *handle) 
GnomeVFSResult
gnome_vfs_close (handle)
	GnomeVFSHandle *handle

=for apidoc

Returns a GnomeVFSResult, the number of bytes read and the buffer containing
the read content.

=cut
##  GnomeVFSResult gnome_vfs_read (GnomeVFSHandle *handle, gpointer buffer, GnomeVFSFileSize bytes, GnomeVFSFileSize *bytes_read) 
void
gnome_vfs_read (handle, bytes)
	GnomeVFSHandle *handle
	GnomeVFSFileSize bytes
    PREINIT:
	char *buffer;
	GnomeVFSResult result;
	GnomeVFSFileSize bytes_read = bytes;
    PPCODE:
	if (bytes <= 0)
		croak ("The number of bytes to read must be greater than 0");

	buffer = g_new0 (char, bytes);
	result = gnome_vfs_read (handle, buffer, bytes, &bytes_read);

	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVuv (bytes_read)));
	PUSHs (sv_2mortal (newSVpv (buffer, bytes_read)));

	g_free (buffer);

=for apidoc

Returns a GnomeVFSResult and the number of bytes written.

=cut
##  GnomeVFSResult gnome_vfs_write (GnomeVFSHandle *handle, gconstpointer buffer, GnomeVFSFileSize bytes, GnomeVFSFileSize *bytes_written) 
void
gnome_vfs_write (handle, buffer, bytes)
	GnomeVFSHandle *handle
	char *buffer;
	GnomeVFSFileSize bytes
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSFileSize bytes_written = bytes;
    PPCODE:
	result = gnome_vfs_write (handle, buffer, bytes, &bytes_written);
	EXTEND (sp, 3);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVuv (bytes_written)));

##  GnomeVFSResult gnome_vfs_seek (GnomeVFSHandle *handle, GnomeVFSSeekPosition whence, GnomeVFSFileOffset offset) 
GnomeVFSResult
gnome_vfs_seek (handle, whence, offset)
	GnomeVFSHandle *handle
	GnomeVFSSeekPosition whence
	GnomeVFSFileOffset offset

=for apidoc

Returns a GnomeVFSResult and the offset.

=cut
##  GnomeVFSResult gnome_vfs_tell (GnomeVFSHandle *handle, GnomeVFSFileSize *offset_return) 
void
gnome_vfs_tell (handle)
	GnomeVFSHandle *handle
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSFileSize offset_return;
    PPCODE:
	result = gnome_vfs_tell (handle, &offset_return);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSViv (offset_return)));

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSFileInfo.

=cut
##  GnomeVFSResult gnome_vfs_get_file_info_from_handle (GnomeVFSHandle *handle, GnomeVFSFileInfo *info, GnomeVFSFileInfoOptions options) 
void
gnome_vfs_get_file_info (handle, options)
	GnomeVFSHandle *handle
	GnomeVFSFileInfoOptions options
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSFileInfo *info;
    PPCODE:
	info = gnome_vfs_file_info_new ();
	result = gnome_vfs_get_file_info_from_handle (handle, info, options);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileInfo (info)));
	g_free (info);

##  GnomeVFSResult gnome_vfs_truncate_handle (GnomeVFSHandle *handle, GnomeVFSFileSize length) 
GnomeVFSResult
gnome_vfs_truncate (handle, length)
	GnomeVFSHandle *handle
	GnomeVFSFileSize length
    CODE:
	RETVAL = gnome_vfs_truncate_handle (handle, length);
    OUTPUT:
	RETVAL

#if VFS_CHECK_VERSION (2, 12, 0)

GnomeVFSResult gnome_vfs_forget_cache (GnomeVFSHandle *handle, GnomeVFSFileOffset offset, GnomeVFSFileSize size);

#endif

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Ops	PACKAGE = Gnome2::VFS::URI	PREFIX = gnome_vfs_uri_

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSHandle.

=cut
##  GnomeVFSResult gnome_vfs_open_uri (GnomeVFSHandle **handle, GnomeVFSURI *uri, GnomeVFSOpenMode open_mode) 
void
gnome_vfs_uri_open (uri, open_mode)
	GnomeVFSURI *uri
	GnomeVFSOpenMode open_mode
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSHandle *handle;
    PPCODE:
	result = gnome_vfs_open_uri (&handle, uri, open_mode);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSHandle (handle)));

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSHandle.

=cut
##  GnomeVFSResult gnome_vfs_create_uri (GnomeVFSHandle **handle, GnomeVFSURI *uri, GnomeVFSOpenMode open_mode, gboolean exclusive, guint perm) 
void
gnome_vfs_uri_create (uri, open_mode, exclusive, perm)
	GnomeVFSURI *uri
	GnomeVFSOpenMode open_mode
	gboolean exclusive
	guint perm
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSHandle *handle;
    PPCODE:
	result = gnome_vfs_create_uri (&handle, uri, open_mode, exclusive, perm);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSHandle (handle)));

##  GnomeVFSResult gnome_vfs_move_uri (GnomeVFSURI *old_uri, GnomeVFSURI *new_uri, gboolean force_replace) 
GnomeVFSResult
gnome_vfs_uri_move (old_uri, new_uri, force_replace)
	GnomeVFSURI *old_uri
	GnomeVFSURI *new_uri
	gboolean force_replace
    CODE:
	RETVAL = gnome_vfs_move_uri (old_uri, new_uri, force_replace);
    OUTPUT:
	RETVAL

=for apidoc

Returns a GnomeVFSResult and a boolean.

=cut
##  GnomeVFSResult gnome_vfs_check_same_fs_uris (GnomeVFSURI *source_uri, GnomeVFSURI *target_uri, gboolean *same_fs_return) 
void
gnome_vfs_uri_check_same_fs (source_uri, target_uri)
	GnomeVFSURI *source_uri
	GnomeVFSURI *target_uri
    PREINIT:
	GnomeVFSResult result;
	gboolean same_fs_return;
    PPCODE:
	result = gnome_vfs_check_same_fs_uris (source_uri, target_uri, &same_fs_return);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVuv (same_fs_return)));

##  gboolean gnome_vfs_uri_exists (GnomeVFSURI *uri) 
gboolean
gnome_vfs_uri_exists (uri)
	GnomeVFSURI *uri

##  GnomeVFSResult gnome_vfs_unlink_from_uri (GnomeVFSURI *uri) 
GnomeVFSResult
gnome_vfs_uri_unlink (uri)
	GnomeVFSURI *uri
    CODE:
	RETVAL = gnome_vfs_unlink_from_uri (uri);
    OUTPUT:
	RETVAL

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSFileInfo.

=cut
##  GnomeVFSResult gnome_vfs_get_file_info_uri (GnomeVFSURI *uri, GnomeVFSFileInfo *info, GnomeVFSFileInfoOptions options) 
void
gnome_vfs_uri_get_file_info (uri, options)
	GnomeVFSURI *uri
	GnomeVFSFileInfoOptions options
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSFileInfo *info;
    PPCODE:
	info = gnome_vfs_file_info_new ();
	result = gnome_vfs_get_file_info_uri (uri, info, options);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileInfo (info)));
	g_free (info);

##  GnomeVFSResult gnome_vfs_truncate_uri (GnomeVFSURI *uri, GnomeVFSFileSize length) 
GnomeVFSResult
gnome_vfs_uri_truncate (uri, length)
	GnomeVFSURI *uri
	GnomeVFSFileSize length
    CODE:
	RETVAL = gnome_vfs_truncate_uri (uri, length);
    OUTPUT:
	RETVAL

##  GnomeVFSResult gnome_vfs_make_directory_for_uri (GnomeVFSURI *uri, guint perm) 
GnomeVFSResult
gnome_vfs_uri_make_directory (uri, perm)
	GnomeVFSURI *uri
	guint perm
    CODE:
	RETVAL = gnome_vfs_make_directory_for_uri (uri, perm);
    OUTPUT:
	RETVAL

##  GnomeVFSResult gnome_vfs_remove_directory_from_uri (GnomeVFSURI *uri) 
GnomeVFSResult
gnome_vfs_uri_remove_directory (uri)
	GnomeVFSURI *uri
    CODE:
	RETVAL = gnome_vfs_remove_directory_from_uri (uri);
    OUTPUT:
	RETVAL

##  GnomeVFSResult gnome_vfs_set_file_info_uri (GnomeVFSURI *uri, GnomeVFSFileInfo *info, GnomeVFSSetFileInfoMask mask) 
GnomeVFSResult
gnome_vfs_uri_set_file_info (uri, info, mask)
	GnomeVFSURI *uri
	GnomeVFSFileInfo *info
	GnomeVFSSetFileInfoMask mask
    CODE:
	RETVAL = gnome_vfs_set_file_info_uri (uri, info, mask);
    OUTPUT:
	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Ops	PACKAGE = Gnome2::VFS::Monitor	PREFIX = gnome_vfs_monitor_

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSMonitorHandle.

=cut
##  GnomeVFSResult gnome_vfs_monitor_add (GnomeVFSMonitorHandle **handle, const gchar *text_uri, GnomeVFSMonitorType monitor_type, GnomeVFSMonitorCallback callback, gpointer user_data) 
void
gnome_vfs_monitor_add (class, text_uri, monitor_type, func, data=NULL)
	const gchar *text_uri
	GnomeVFSMonitorType monitor_type
	SV *func
	SV *data
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSMonitorHandle *handle;
	GPerlCallback *callback;
    PPCODE:
	callback = vfs2perl_monitor_callback_create (func, data);

	/* FIXME: destroy that callback somehow. */

	result = gnome_vfs_monitor_add (&handle,
	                                text_uri,
	                                monitor_type,
	                                (GnomeVFSMonitorCallback)
	                                  vfs2perl_monitor_callback,
	                                callback);

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSMonitorHandle (handle)));

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Ops	PACKAGE = Gnome2::VFS::Monitor::Handle	PREFIX = gnome_vfs_monitor_

##  GnomeVFSResult gnome_vfs_monitor_cancel (GnomeVFSMonitorHandle *handle) 
GnomeVFSResult
gnome_vfs_monitor_cancel (handle)
	GnomeVFSMonitorHandle *handle

# --------------------------------------------------------------------------- #

# according to the docs, not intended to be used directly.
###  GnomeVFSResult gnome_vfs_file_control (GnomeVFSHandle *handle, const char *operation, gpointer operation_data) 
#GnomeVFSResult
#gnome_vfs_file_control (handle, operation, operation_data)
#	GnomeVFSHandle *handle
#	const char *operation
#	gpointer operation_data
