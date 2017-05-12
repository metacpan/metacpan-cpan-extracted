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
#include <gperl_marshal.h>
#include <libgnomevfs/gnome-vfs-job-limit.h>

/* ------------------------------------------------------------------------- */

#if 0
GHashTable *vfs2perl_async_callbacks = NULL;
G_LOCK_DEFINE_STATIC (vfs2perl_async_callbacks);

void
vfs2perl_async_callbacks_add (GnomeVFSAsyncHandle *handle, GPerlCallback *callback)
{
	G_LOCK (vfs2perl_async_callbacks);
	{
		GList *list;

		if (vfs2perl_async_callbacks == NULL)
			vfs2perl_async_callbacks =
			  g_hash_table_new_full (NULL,
			                         NULL,
			                         NULL,
			                         (GDestroyNotify)
			                           g_list_free);

		list = g_hash_table_lookup (vfs2perl_async_callbacks, handle);
		list = g_list_append (list, callback);

		g_hash_table_insert (vfs2perl_async_callbacks, handle, list);
	}
	G_UNLOCK (vfs2perl_async_callbacks);
}

void vfs2perl_async_callbacks_destroy (GnomeVFSAsyncHandle *handle)
{
	G_LOCK (vfs2perl_async_callbacks);
	{
		if (vfs2perl_async_callbacks != NULL) {
			GList *list = g_hash_table_lookup (vfs2perl_async_callbacks, handle);

			if (list != NULL) {
				/* GPerlCallback *callback = g_list_last (list)->data;

				if (callback != NULL)
					gperl_callback_destroy (callback); */

				GList *i;

				for (i = list; i != NULL; i = i->next)
					if (i->data != NULL)
						gperl_callback_destroy ((GPerlCallback *) i->data);

				if (g_list_length (list) == 0)
					g_hash_table_remove (vfs2perl_async_callbacks, handle);
			}

			if (g_hash_table_size (vfs2perl_async_callbacks) == 0) {
				g_hash_table_destroy (vfs2perl_async_callbacks);
				vfs2perl_async_callbacks = NULL;
			}
		}
	}
	G_UNLOCK (vfs2perl_async_callbacks);
}
#endif

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_async_callback (GnomeVFSAsyncHandle *handle,
                         GnomeVFSResult result,
                         GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_read_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_async_read_callback (GnomeVFSAsyncHandle *handle,
                              GnomeVFSResult result,
                              char* buffer,
                              GnomeVFSFileSize bytes_requested,
                              GnomeVFSFileSize bytes_read,
                              GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 5);
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVpv (buffer, bytes_read)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileSize (bytes_requested)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileSize (bytes_read)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_write_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_async_write_callback (GnomeVFSAsyncHandle *handle,
                               GnomeVFSResult result,
                               char* buffer,
                               GnomeVFSFileSize bytes_requested,
                               GnomeVFSFileSize bytes_written,
                               GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 5);
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVpv (buffer, bytes_written)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileSize (bytes_requested)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileSize (bytes_written)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_directory_load_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_async_directory_load_callback (GnomeVFSAsyncHandle *handle,
                                        GnomeVFSResult result,
                                        GList *list,
                                        guint entries_read,
                                        GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileInfoGList (list)));
	PUSHs (sv_2mortal (newSVuv (entries_read)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_get_file_info_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_async_get_file_info_callback (GnomeVFSAsyncHandle *handle,
                                       GList *results,
                                       GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSGetFileInfoResultGList (results)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_xfer_progress_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

/* G_LOCK_DEFINE_STATIC (vfs2perl_async_xfer_progress_callback); */

static void
vfs2perl_async_xfer_progress_callback (GnomeVFSAsyncHandle *handle,
                                       GnomeVFSXferProgressInfo *info,
                                       GPerlCallback *callback)
{
	/* G_LOCK (vfs2perl_async_xfer_progress_callback);
	{ */
		dGPERL_CALLBACK_MARSHAL_SP;
		GPERL_CALLBACK_MARSHAL_INIT (callback);

		ENTER;
		SAVETMPS;

		PUSHMARK (SP);

		EXTEND (SP, 2);
		PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
		PUSHs (sv_2mortal (newSVGnomeVFSXferProgressInfo (info)));
		if (callback->data)
			XPUSHs (sv_2mortal (newSVsv (callback->data)));

		PUTBACK;

		call_sv (callback->func, G_DISCARD);

		FREETMPS;
		LEAVE;
	/* }
	G_UNLOCK (vfs2perl_async_xfer_progress_callback); */
}

extern GPerlCallback *
vfs2perl_xfer_progress_callback_create (SV *func, SV *data);

extern gint
vfs2perl_xfer_progress_callback (GnomeVFSXferProgressInfo *info,
                                 GPerlCallback *callback);

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_find_directory_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_async_find_directory_callback (GnomeVFSAsyncHandle *handle,
                                        GList *results,
                                        GPerlCallback *callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSFindDirectoryResultGList (results)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_async_set_file_info_callback_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, 0);
}

static void
vfs2perl_async_set_file_info_callback (GnomeVFSAsyncHandle *handle,
                                       GnomeVFSResult result,
                                       GnomeVFSFileInfo *file_info,
                                       GPerlCallback* callback)
{
	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle)));
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileInfo (file_info)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	call_sv (callback->func, G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::Async	PACKAGE = Gnome2::VFS::Async	PREFIX = gnome_vfs_async_

##  void gnome_vfs_async_set_job_limit (int limit) 
void
gnome_vfs_async_set_job_limit (class, limit)
	int limit
    C_ARGS:
	limit

##  int gnome_vfs_async_get_job_limit (void) 
int
gnome_vfs_async_get_job_limit (class)
    C_ARGS:
	/* void */

##  void gnome_vfs_async_open (GnomeVFSAsyncHandle **handle_return, const gchar *text_uri, GnomeVFSOpenMode open_mode, int priority, GnomeVFSAsyncOpenCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_open (class, text_uri, open_mode, priority, func, data=NULL)
	const gchar *text_uri
	GnomeVFSOpenMode open_mode
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_callback_create (func, data);

	gnome_vfs_async_open (&RETVAL,
                              text_uri,
                              open_mode,
                              priority,
                              (GnomeVFSAsyncOpenCallback)
                                vfs2perl_async_callback,
                              callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

###  void gnome_vfs_async_open_uri (GnomeVFSAsyncHandle **handle_return, GnomeVFSURI *uri, GnomeVFSOpenMode open_mode, int priority, GnomeVFSAsyncOpenCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_open_uri (class, uri, open_mode, priority, func, data=NULL)
	GnomeVFSURI *uri
	GnomeVFSOpenMode open_mode
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_callback_create (func, data);

	gnome_vfs_async_open_uri (&RETVAL,
                                  uri,
                                  open_mode,
                                  priority,
                                  (GnomeVFSAsyncOpenCallback)
                                    vfs2perl_async_callback,
                                  callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

###  void gnome_vfs_async_open_as_channel (GnomeVFSAsyncHandle **handle_return, const gchar *text_uri, GnomeVFSOpenMode open_mode, guint advised_block_size, int priority, GnomeVFSAsyncOpenAsChannelCallback callback, gpointer callback_data) 
#void
#gnome_vfs_async_open_as_channel (handle_return, text_uri, open_mode, advised_block_size, priority, callback, callback_data)
#	GnomeVFSAsyncHandle **handle_return
#	const gchar *text_uri
#	GnomeVFSOpenMode open_mode
#	guint advised_block_size
#	int priority
#	GnomeVFSAsyncOpenAsChannelCallback callback
#	gpointer callback_data

###  void gnome_vfs_async_open_uri_as_channel (GnomeVFSAsyncHandle **handle_return, GnomeVFSURI *uri, GnomeVFSOpenMode open_mode, guint advised_block_size, int priority, GnomeVFSAsyncOpenAsChannelCallback callback, gpointer callback_data) 
#void
#gnome_vfs_async_open_uri_as_channel (handle_return, uri, open_mode, advised_block_size, priority, callback, callback_data)
#	GnomeVFSAsyncHandle **handle_return
#	GnomeVFSURI *uri
#	GnomeVFSOpenMode open_mode
#	guint advised_block_size
#	int priority
#	GnomeVFSAsyncOpenAsChannelCallback callback
#	gpointer callback_data

##  void gnome_vfs_async_create (GnomeVFSAsyncHandle **handle_return, const gchar *text_uri, GnomeVFSOpenMode open_mode, gboolean exclusive, guint perm, int priority, GnomeVFSAsyncOpenCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_create (class, text_uri, open_mode, exclusive, perm, priority, func, data=NULL)
	const gchar *text_uri
	GnomeVFSOpenMode open_mode
	gboolean exclusive
	guint perm
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_callback_create (func, data);

	gnome_vfs_async_create (&RETVAL,
	                        text_uri,
	                        open_mode,
	                        exclusive,
	                        perm,
	                        priority,
	                        (GnomeVFSAsyncCreateCallback)
	                          vfs2perl_async_callback,
	                        callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

##  void gnome_vfs_async_create_uri (GnomeVFSAsyncHandle **handle_return, GnomeVFSURI *uri, GnomeVFSOpenMode open_mode, gboolean exclusive, guint perm, int priority, GnomeVFSAsyncOpenCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_create_uri (class, uri, open_mode, exclusive, perm, priority, func, data=NULL)
	GnomeVFSURI *uri
	GnomeVFSOpenMode open_mode
	gboolean exclusive
	guint perm
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_callback_create (func, data);

	gnome_vfs_async_create_uri (&RETVAL,
	                            uri,
	                            open_mode,
	                            exclusive,
	                            perm,
	                            priority,
	                            (GnomeVFSAsyncOpenCallback)
	                              vfs2perl_async_callback,
	                            callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

##  void gnome_vfs_async_create_symbolic_link (GnomeVFSAsyncHandle **handle_return, GnomeVFSURI *uri, const gchar *uri_reference, int priority, GnomeVFSAsyncOpenCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_create_symbolic_link (class, uri, uri_reference, priority, func, data=NULL)
	GnomeVFSURI *uri
	const gchar *uri_reference
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_callback_create (func, data);

	gnome_vfs_async_create_symbolic_link (&RETVAL,
	                                      uri,
	                                      uri_reference,
	                                      priority,
	                                      (GnomeVFSAsyncOpenCallback)
	                                        vfs2perl_async_callback,
	                                      callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

##  void gnome_vfs_async_get_file_info (GnomeVFSAsyncHandle **handle_return, GList *uri_list, GnomeVFSFileInfoOptions options, int priority, GnomeVFSAsyncGetFileInfoCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_get_file_info (class, uri_ref, options, priority, func, data=NULL)
	SV *uri_ref
	GnomeVFSFileInfoOptions options
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GList *uri_list;
    CODE:
	callback = vfs2perl_async_get_file_info_callback_create (func, data);
	uri_list = SvGnomeVFSURIGList (uri_ref);

	gnome_vfs_async_get_file_info (&RETVAL,
	                               uri_list,
	                               options,
	                               priority,
	                               (GnomeVFSAsyncGetFileInfoCallback)
	                                 vfs2perl_async_get_file_info_callback,
	                               callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	g_list_free (uri_list);

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

##  void gnome_vfs_async_set_file_info (GnomeVFSAsyncHandle **handle_return, GnomeVFSURI *uri, GnomeVFSFileInfo *info, GnomeVFSSetFileInfoMask mask, GnomeVFSFileInfoOptions options, int priority, GnomeVFSAsyncSetFileInfoCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_set_file_info (class, uri, info, mask, options, priority, func, data=NULL)
	GnomeVFSURI *uri
	GnomeVFSFileInfo *info
	GnomeVFSSetFileInfoMask mask
	GnomeVFSFileInfoOptions options
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_set_file_info_callback_create (func, data);

	gnome_vfs_async_set_file_info (&RETVAL,
	                               uri,
	                               info,
	                               mask,
	                               options,
	                               priority,
	                               (GnomeVFSAsyncSetFileInfoCallback)
	                                 vfs2perl_async_set_file_info_callback,
	                               callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

##  void gnome_vfs_async_load_directory (GnomeVFSAsyncHandle **handle_return, const gchar *text_uri, GnomeVFSFileInfoOptions options, guint items_per_notification, int priority, GnomeVFSAsyncDirectoryLoadCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_load_directory (class, text_uri, options, items_per_notification, priority, func, data=NULL)
	const gchar *text_uri
	GnomeVFSFileInfoOptions options
	guint items_per_notification
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_directory_load_callback_create (func, data);

	gnome_vfs_async_load_directory (&RETVAL,
	                                text_uri,
	                                options,
                                        items_per_notification,
	                                priority,
	                                (GnomeVFSAsyncDirectoryLoadCallback)
	                                  vfs2perl_async_directory_load_callback,
	                                callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

##  void gnome_vfs_async_load_directory_uri (GnomeVFSAsyncHandle **handle_return, GnomeVFSURI *uri, GnomeVFSFileInfoOptions options, guint items_per_notification, int priority, GnomeVFSAsyncDirectoryLoadCallback callback, gpointer callback_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_load_directory_uri (class, uri, options, items_per_notification, priority, func, data=NULL)
	GnomeVFSURI *uri
	GnomeVFSFileInfoOptions options
	guint items_per_notification
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_directory_load_callback_create (func, data);

	gnome_vfs_async_load_directory_uri (&RETVAL,
	                                    uri,
	                                    options,
                                            items_per_notification,
	                                    priority,
	                                    (GnomeVFSAsyncDirectoryLoadCallback)
	                                      vfs2perl_async_directory_load_callback,
	                                    callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSAsyncHandle.

=cut
##  GnomeVFSResult gnome_vfs_async_xfer (GnomeVFSAsyncHandle **handle_return, GList *source_uri_list, GList *target_uri_list, GnomeVFSXferOptions xfer_options, GnomeVFSXferErrorMode error_mode, GnomeVFSXferOverwriteMode overwrite_mode, int priority, GnomeVFSAsyncXferProgressCallback progress_update_callback, gpointer update_callback_data, GnomeVFSXferProgressCallback progress_sync_callback, gpointer sync_callback_data) 
void
gnome_vfs_async_xfer (class, source_ref, target_ref, xfer_options, error_mode, overwrite_mode, priority, func_update, data_update, func_sync, data_sync=NULL)
	SV *source_ref
	SV *target_ref
	GnomeVFSXferOptions xfer_options
	GnomeVFSXferErrorMode error_mode
	GnomeVFSXferOverwriteMode overwrite_mode
	int priority
	SV *func_update
	SV *data_update
	SV *func_sync
	SV *data_sync
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSAsyncHandle *handle_return;
	GList *source_uri_list;
	GList *target_uri_list;
	GPerlCallback *callback_update;
	GPerlCallback *callback_sync;
    PPCODE:
	source_uri_list = SvGnomeVFSURIGList (source_ref);
	target_uri_list = SvGnomeVFSURIGList (target_ref);

	callback_update = vfs2perl_async_xfer_progress_callback_create (func_update, data_update);
	callback_sync = vfs2perl_xfer_progress_callback_create (func_sync, data_sync);

	result = gnome_vfs_async_xfer (&handle_return,
	                               source_uri_list,
	                               target_uri_list,
	                               xfer_options,
	                               error_mode,
	                               overwrite_mode,
	                               priority,
	                               (GnomeVFSAsyncXferProgressCallback)
	                                 vfs2perl_async_xfer_progress_callback,
	                               callback_update,
	                               (GnomeVFSXferProgressCallback)
	                                 vfs2perl_xfer_progress_callback,
	                               callback_sync);

	/* vfs2perl_async_callbacks_add (handle_return, callback_update);
	vfs2perl_async_callbacks_add (handle_return, callback_sync); */

	g_list_free (source_uri_list);
	g_list_free (target_uri_list);

	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSAsyncHandle (handle_return)));

	/* FIXME, FIXME, FIXME: what about callback destruction? */

##  void gnome_vfs_async_find_directory (GnomeVFSAsyncHandle **handle_return, GList *near_uri_list, GnomeVFSFindDirectoryKind kind, gboolean create_if_needed, gboolean find_if_needed, guint permissions, int priority, GnomeVFSAsyncFindDirectoryCallback callback, gpointer user_data) 
GnomeVFSAsyncHandle *
gnome_vfs_async_find_directory (class, near_ref, kind, create_if_needed, find_if_needed, permissions, priority, func, data=NULL)
	SV *near_ref
	GnomeVFSFindDirectoryKind kind
	gboolean create_if_needed
	gboolean find_if_needed
	guint permissions
	int priority
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GList *near_uri_list;
    CODE:
	near_uri_list = SvGnomeVFSURIGList (near_ref);
	callback = vfs2perl_async_find_directory_callback_create (func, data);

	gnome_vfs_async_find_directory (&RETVAL,
	                                near_uri_list,
	                                kind,
	                                create_if_needed,
	                                find_if_needed,
	                                permissions,
	                                priority,
	                                (GnomeVFSAsyncFindDirectoryCallback)
	                                  vfs2perl_async_find_directory_callback,
	                                callback);

	/* vfs2perl_async_callbacks_add (RETVAL, callback); */

	g_list_free (near_uri_list);

	/* FIXME, FIXME, FIXME: what about callback destruction? */
    OUTPUT:
	RETVAL

###  void gnome_vfs_async_create_as_channel (GnomeVFSAsyncHandle **handle_return, const gchar *text_uri, GnomeVFSOpenMode open_mode, gboolean exclusive, guint perm, int priority, GnomeVFSAsyncCreateAsChannelCallback callback, gpointer callback_data) 
#void
#gnome_vfs_async_create_as_channel (handle_return, text_uri, open_mode, exclusive, perm, priority, callback, callback_data)
#	GnomeVFSAsyncHandle **handle_return
#	const gchar *text_uri
#	GnomeVFSOpenMode open_mode
#	gboolean exclusive
#	guint perm
#	int priority
#	GnomeVFSAsyncCreateAsChannelCallback callback
#	gpointer callback_data

###  void gnome_vfs_async_create_uri_as_channel (GnomeVFSAsyncHandle **handle_return, GnomeVFSURI *uri, GnomeVFSOpenMode open_mode, gboolean exclusive, guint perm, int priority, GnomeVFSAsyncCreateAsChannelCallback callback, gpointer callback_data) 
#void
#gnome_vfs_async_create_uri_as_channel (handle_return, uri, open_mode, exclusive, perm, priority, callback, callback_data)
#	GnomeVFSAsyncHandle **handle_return
#	GnomeVFSURI *uri
#	GnomeVFSOpenMode open_mode
#	gboolean exclusive
#	guint perm
#	int priority
#	GnomeVFSAsyncCreateAsChannelCallback callback
#	gpointer callback_data

###  void gnome_vfs_async_file_control (GnomeVFSAsyncHandle *handle, const char *operation, gpointer operation_data, GDestroyNotify operation_data_destroy_func, GnomeVFSAsyncFileControlCallback callback, gpointer callback_data) 
#void
#gnome_vfs_async_file_control (handle, operation, operation_data, operation_data_destroy_func, callback, callback_data)
#	GnomeVFSAsyncHandle *handle
#	const char *operation
#	gpointer operation_data
#	GDestroyNotify operation_data_destroy_func
#	GnomeVFSAsyncFileControlCallback callback
#	gpointer callback_data

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Async	PACKAGE = Gnome2::VFS::Async::Handle	PREFIX = gnome_vfs_async_

# void
# DESTROY (handle)
# 	GnomeVFSAsyncHandle *handle
#     CODE:
# 	vfs2perl_async_callbacks_destroy (handle);

##  void gnome_vfs_async_close (GnomeVFSAsyncHandle *handle, GnomeVFSAsyncCloseCallback callback, gpointer callback_data) 
void
gnome_vfs_async_close (handle, func, data=NULL)
	GnomeVFSAsyncHandle *handle
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_callback_create (func, data);

	gnome_vfs_async_close (handle,
                               (GnomeVFSAsyncCloseCallback)
                                 vfs2perl_async_callback,
                               callback);

	/* vfs2perl_async_callbacks_add (handle, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */

# FIXME: destroy callback here?  docs say:
# «Its possible to still receive another call or two on the callback.»
##  void gnome_vfs_async_cancel (GnomeVFSAsyncHandle *handle) 
void
gnome_vfs_async_cancel (handle)
	GnomeVFSAsyncHandle *handle

##  void gnome_vfs_async_read (GnomeVFSAsyncHandle *handle, gpointer buffer, guint bytes, GnomeVFSAsyncReadCallback callback, gpointer callback_data) 
void
gnome_vfs_async_read (handle, bytes, func, data=NULL)
	GnomeVFSAsyncHandle *handle
	guint bytes
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	char *buffer;
    CODE:
	callback = vfs2perl_async_read_callback_create (func, data);
	buffer = g_new0 (char, bytes);

	gnome_vfs_async_read (handle,
	                      buffer,
	                      bytes,
	                      (GnomeVFSAsyncReadCallback)
	                        vfs2perl_async_read_callback,
	                      callback);

	/* vfs2perl_async_callbacks_add (handle, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction?
	                        and the buffer? */

##  void gnome_vfs_async_write (GnomeVFSAsyncHandle *handle, gconstpointer buffer, guint bytes, GnomeVFSAsyncWriteCallback callback, gpointer callback_data) 
void
gnome_vfs_async_write (handle, buffer, bytes, func, data=NULL)
	GnomeVFSAsyncHandle *handle
	char* buffer
	guint bytes
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_write_callback_create (func, data);

	gnome_vfs_async_write (handle,
	                       buffer,
	                       bytes,
	                       (GnomeVFSAsyncWriteCallback)
	                         vfs2perl_async_write_callback,
	                       callback);

	/* vfs2perl_async_callbacks_add (handle, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */

#if VFS_CHECK_VERSION (2, 6, 0)

##  void gnome_vfs_async_seek (GnomeVFSAsyncHandle *handle, GnomeVFSSeekPosition whence, GnomeVFSFileOffset offset, GnomeVFSAsyncSeekCallback callback, gpointer callback_data) 
void
gnome_vfs_async_seek (handle, whence, offset, func, data=NULL)
	GnomeVFSAsyncHandle *handle
	GnomeVFSSeekPosition whence
	GnomeVFSFileOffset offset
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_async_callback_create (func, data);

	gnome_vfs_async_seek (handle,
	                      whence,
	                      offset,
	                      (GnomeVFSAsyncSeekCallback)
	                        vfs2perl_async_callback,
	                      callback);

	/* vfs2perl_async_callbacks_add (handle, callback); */

	/* FIXME, FIXME, FIXME: what about callback destruction? */

#endif /* 2.6 */
