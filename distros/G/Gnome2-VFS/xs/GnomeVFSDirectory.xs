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

/* ------------------------------------------------------------------------- */

static GPerlCallback *
vfs2perl_directory_visit_func_create (SV *func, SV *data)
{
	return gperl_callback_new (func, data, 0, NULL, G_TYPE_BOOLEAN);
}

static gboolean
vfs2perl_directory_visit_func (const gchar *rel_path,
                               GnomeVFSFileInfo *info,
                               gboolean recursing_will_loop,
                               GPerlCallback * callback,
                               gboolean *recurse)
{
	int n;
	gboolean stop;

	dGPERL_CALLBACK_MARSHAL_SP;
	GPERL_CALLBACK_MARSHAL_INIT (callback);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSVGChar (rel_path)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileInfo (info)));
	PUSHs (sv_2mortal (newSVuv (recursing_will_loop)));
	if (callback->data)
		XPUSHs (sv_2mortal (newSVsv (callback->data)));

	PUTBACK;

	n = call_sv (callback->func, G_ARRAY);

	SPAGAIN;

	if (n != 2)
		croak ("directory visit callback must return two booleans (stop and recurse)");

	/* POPi takes things off the *end* of the stack! */
	*recurse = POPi;
	stop = POPi;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return stop;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::Directory	PACKAGE = Gnome2::VFS::Directory	PREFIX = gnome_vfs_directory_

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSDirectoryHandle.

=cut
##  GnomeVFSResult gnome_vfs_directory_open (GnomeVFSDirectoryHandle **handle, const gchar *text_uri, GnomeVFSFileInfoOptions options) 
void
gnome_vfs_directory_open (class, text_uri, options)
	const gchar *text_uri
	GnomeVFSFileInfoOptions options
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSDirectoryHandle *handle;
    PPCODE:
	result = gnome_vfs_directory_open (&handle, text_uri, options);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSDirectoryHandle (handle)));


=for apidoc

Returns a GnomeVFSResult and a GnomeVFSDirectoryHandle.

=cut
##  GnomeVFSResult gnome_vfs_directory_open_from_uri (GnomeVFSDirectoryHandle **handle, GnomeVFSURI *uri, GnomeVFSFileInfoOptions options) 
void
gnome_vfs_directory_open_from_uri (class, uri, options)
	GnomeVFSURI *uri
	GnomeVFSFileInfoOptions options
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSDirectoryHandle *handle;
    PPCODE:
	result = gnome_vfs_directory_open_from_uri (&handle, uri, options);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSDirectoryHandle (handle)));

##  GnomeVFSResult gnome_vfs_directory_visit (const gchar *uri, GnomeVFSFileInfoOptions info_options, GnomeVFSDirectoryVisitOptions visit_options, GnomeVFSDirectoryVisitFunc callback, gpointer data) 
GnomeVFSResult
gnome_vfs_directory_visit (class, uri, info_options, visit_options, func, data=NULL)
	const gchar *uri
	GnomeVFSFileInfoOptions info_options
	GnomeVFSDirectoryVisitOptions visit_options
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_directory_visit_func_create (func, data);

	RETVAL = gnome_vfs_directory_visit (uri,
	                                    info_options,
	                                    visit_options,
	                                    (GnomeVFSDirectoryVisitFunc)
	                                      vfs2perl_directory_visit_func,
	                                    callback);

	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL

##  GnomeVFSResult gnome_vfs_directory_visit_uri (GnomeVFSURI *uri, GnomeVFSFileInfoOptions info_options, GnomeVFSDirectoryVisitOptions visit_options, GnomeVFSDirectoryVisitFunc callback, gpointer data) 
GnomeVFSResult
gnome_vfs_directory_visit_uri (class, uri, info_options, visit_options, func, data=NULL)
	GnomeVFSURI *uri
	GnomeVFSFileInfoOptions info_options
	GnomeVFSDirectoryVisitOptions visit_options
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_directory_visit_func_create (func, data);

	RETVAL = gnome_vfs_directory_visit_uri (uri,
	                                        info_options,
	                                        visit_options,
	                                        (GnomeVFSDirectoryVisitFunc)
	                                          vfs2perl_directory_visit_func,
	                                        callback);

	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL

##  GnomeVFSResult gnome_vfs_directory_visit_files (const gchar *text_uri, GList *file_list, GnomeVFSFileInfoOptions info_options, GnomeVFSDirectoryVisitOptions visit_options, GnomeVFSDirectoryVisitFunc callback, gpointer data) 
GnomeVFSResult
gnome_vfs_directory_visit_files (class, text_uri, file_ref, info_options, visit_options, func, data=NULL)
	const gchar *text_uri
	SV *file_ref
	GnomeVFSFileInfoOptions info_options
	GnomeVFSDirectoryVisitOptions visit_options
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GList *file_list;
    CODE:
	callback = vfs2perl_directory_visit_func_create (func, data);
	file_list = SvPVGList (file_ref);

	RETVAL = gnome_vfs_directory_visit_files (text_uri,
	                                          file_list,
	                                          info_options,
	                                          visit_options,
	                                          (GnomeVFSDirectoryVisitFunc)
	                                            vfs2perl_directory_visit_func,
	                                          callback);

	g_list_free (file_list);
	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL

##  GnomeVFSResult gnome_vfs_directory_visit_files_at_uri (GnomeVFSURI *uri, GList *file_list, GnomeVFSFileInfoOptions info_options, GnomeVFSDirectoryVisitOptions visit_options, GnomeVFSDirectoryVisitFunc callback, gpointer data) 
GnomeVFSResult
gnome_vfs_directory_visit_files_at_uri (class, uri, file_ref, info_options, visit_options, func, data=NULL)
	GnomeVFSURI *uri
	SV *file_ref
	GnomeVFSFileInfoOptions info_options
	GnomeVFSDirectoryVisitOptions visit_options
	SV *func
	SV *data
    PREINIT:
	GPerlCallback *callback;
	GList *file_list;
    CODE:
	callback = vfs2perl_directory_visit_func_create (func, data);
	file_list = SvPVGList (file_ref);

	RETVAL = gnome_vfs_directory_visit_files_at_uri (uri,
	                                                 file_list,
	                                                 info_options,
	                                                 visit_options,
	                                                 (GnomeVFSDirectoryVisitFunc)
	                                                   vfs2perl_directory_visit_func,
	                                                 callback);

	g_list_free (file_list);
	gperl_callback_destroy (callback);
    OUTPUT:
	RETVAL

=for apidoc

Returns a GnomeVFSResult and the GnomeVFSFileInfo's corresponding to the
directory's content.

=cut
##  GnomeVFSResult gnome_vfs_directory_list_load (GList **list, const gchar *text_uri, GnomeVFSFileInfoOptions options) 
void
gnome_vfs_directory_list_load (class, text_uri, options)
	const gchar *text_uri
	GnomeVFSFileInfoOptions options
    PREINIT:
	GnomeVFSResult result;
	GList *i, *list = NULL;
    PPCODE:
	result = gnome_vfs_directory_list_load (&list, text_uri, options);

	EXTEND (sp, 1);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));

	for (i = list; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGnomeVFSFileInfo (i->data)));

	gnome_vfs_file_info_list_free (list);

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::Directory	PACKAGE = Gnome2::VFS::Directory::Handle	PREFIX = gnome_vfs_directory_

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSFileInfo.

=cut
##  GnomeVFSResult gnome_vfs_directory_read_next (GnomeVFSDirectoryHandle *handle, GnomeVFSFileInfo *file_info) 
void
gnome_vfs_directory_read_next (handle)
	GnomeVFSDirectoryHandle *handle
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSFileInfo *file_info;
    PPCODE:
	file_info = gnome_vfs_file_info_new ();
	result = gnome_vfs_directory_read_next (handle, file_info);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSFileInfo (file_info)));
	gnome_vfs_file_info_unref (file_info);

##  GnomeVFSResult gnome_vfs_directory_close (GnomeVFSDirectoryHandle *handle) 
GnomeVFSResult
gnome_vfs_directory_close (handle)
	GnomeVFSDirectoryHandle *handle
