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

/* ------------------------------------------------------------------------- */

GType
vfs2perl_gnome_vfs_uri_get_type (void)
{
	static GType t = 0;
	if (!t)
		t = g_boxed_type_register_static ("GnomeVFSURI",
		      (GBoxedCopyFunc) gnome_vfs_uri_ref,
		      (GBoxedFreeFunc) gnome_vfs_uri_unref);
	return t;
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSFileSize (GnomeVFSFileSize size)
{
	return newSVuv (size);
}

GnomeVFSFileSize
SvGnomeVFSFileSize (SV *size)
{
	return SvUV (size);
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSFileOffset (GnomeVFSFileOffset offset)
{
	return newSViv (offset);
}

GnomeVFSFileOffset
SvGnomeVFSFileOffset (SV *offset)
{
	return SvIV (offset);
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSHandle (GnomeVFSHandle *handle)
{
	SV *sv = newSV (0);

	return sv_setref_pv (sv, "Gnome2::VFS::Handle", handle);
}

GnomeVFSHandle *
SvGnomeVFSHandle (SV *handle)
{
	return INT2PTR (GnomeVFSHandle *, SvIV (SvRV (handle)));

}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSMonitorHandle (GnomeVFSMonitorHandle *handle)
{
	SV *sv = newSV (0);

	return sv_setref_pv (sv, "Gnome2::VFS::Monitor::Handle", handle);
}

GnomeVFSMonitorHandle *
SvGnomeVFSMonitorHandle (SV *handle)
{
	return INT2PTR (GnomeVFSMonitorHandle *, SvIV (SvRV (handle)));

}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSDirectoryHandle (GnomeVFSDirectoryHandle *handle)
{
	SV *sv = newSV (0);

	return sv_setref_pv (sv, "Gnome2::VFS::Directory::Handle", handle);
}

GnomeVFSDirectoryHandle *
SvGnomeVFSDirectoryHandle (SV *handle)
{
	return INT2PTR (GnomeVFSDirectoryHandle *, SvIV (SvRV (handle)));

}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSAsyncHandle (GnomeVFSAsyncHandle *handle)
{
	SV *sv = newSV (0);

	return sv_setref_pv (sv, "Gnome2::VFS::Async::Handle", handle);
}

GnomeVFSAsyncHandle *
SvGnomeVFSAsyncHandle (SV *handle)
{
	return INT2PTR (GnomeVFSAsyncHandle *, SvIV (SvRV (handle)));

}

/* ------------------------------------------------------------------------- */

#if VFS_CHECK_VERSION (2, 8, 0)

SV *
newSVGnomeVFSDNSSDBrowseHandle (GnomeVFSDNSSDBrowseHandle *handle)
{
	SV *sv = newSV (0);

	return sv_setref_pv (sv, "Gnome2::VFS::DNSSD::Browse::Handle", handle);
}

GnomeVFSDNSSDBrowseHandle *
SvGnomeVFSDNSSDBrowseHandle (SV *handle)
{
	return INT2PTR (GnomeVFSDNSSDBrowseHandle *, SvIV (SvRV (handle)));

}

#endif /* 2.8 */

/* ------------------------------------------------------------------------- */

#if VFS_CHECK_VERSION (2, 8, 0)

SV *
newSVGnomeVFSDNSSDResolveHandle (GnomeVFSDNSSDResolveHandle *handle)
{
	SV *sv = newSV (0);

	return sv_setref_pv (sv, "Gnome2::VFS::DNSSD::Resolve::Handle", handle);
}

GnomeVFSDNSSDResolveHandle *
SvGnomeVFSDNSSDResolveHandle (SV *handle)
{
	return INT2PTR (GnomeVFSDNSSDResolveHandle *, SvIV (SvRV (handle)));

}

#endif /* 2.8 */

/* ------------------------------------------------------------------------- */

#if VFS_CHECK_VERSION (2, 8, 0)

SV *
newSVGnomeVFSResolveHandle (GnomeVFSResolveHandle *handle)
{
	SV *sv = newSV (0);

	return sv_setref_pv (sv, "Gnome2::VFS::Resolve::Handle", handle);
}

GnomeVFSResolveHandle *
SvGnomeVFSResolveHandle (SV *handle)
{
	return INT2PTR (GnomeVFSResolveHandle *, SvIV (SvRV (handle)));

}

#endif /* 2.8 */

/* ------------------------------------------------------------------------- */

GnomeVFSApplication *
SvGnomeVFSApplication (SV *object)
{
	MAGIC *mg;

	if (!object || !SvOK (object) || !SvROK (object) || !(mg = mg_find (SvRV (object), PERL_MAGIC_ext)))
		return NULL;

	return (GnomeVFSApplication *) mg->mg_ptr;
}

SV *
newSVGnomeVFSApplication (GnomeVFSApplication *app_id)
{
	SV *rv;
	HV *stash;
	SV *object = (SV *) newHV ();

	sv_magic (object, 0, PERL_MAGIC_ext, app_id, 0);

	rv = newRV_noinc (object);
	stash = gv_stashpv ("Gnome2::VFS::Application", 1);

	return sv_bless (rv, stash);
}

/* ------------------------------------------------------------------------- */

#define VFS2PERL_CHECK_AND_STORE(_type, _key, _sv) \
		if (info->valid_fields & _type) \
			hv_store (object, _key, strlen (_key), _sv, 0);

SV *
newSVGnomeVFSFileInfo (GnomeVFSFileInfo *info)
{
	HV *object = newHV ();

	if (info && info->name && info->valid_fields) {
		hv_store (object, "name", 4, newSVpv (info->name, 0), 0);
		hv_store (object, "valid_fields", 12, newSVGnomeVFSFileInfoFields (info->valid_fields), 0);

		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_TYPE, "type", newSVGnomeVFSFileType (info->type));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_PERMISSIONS, "permissions", newSVGnomeVFSFilePermissions (info->permissions));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_FLAGS, "flags", newSVGnomeVFSFileFlags (info->flags));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_DEVICE, "device", newSViv (info->device));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_INODE, "inode", newSVuv (info->inode));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_LINK_COUNT, "link_count", newSVuv (info->link_count));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_SIZE, "size", newSVGnomeVFSFileSize (info->size));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_BLOCK_COUNT, "block_count", newSVGnomeVFSFileSize (info->block_count));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_IO_BLOCK_SIZE, "io_block_size", newSVuv (info->io_block_size));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_ATIME, "atime", newSViv (info->atime));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_MTIME, "mtime", newSViv (info->mtime));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_CTIME, "ctime", newSViv (info->ctime));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_SYMLINK_NAME, "symlink_name", newSVpv (info->symlink_name, 0));
		VFS2PERL_CHECK_AND_STORE (GNOME_VFS_FILE_INFO_FIELDS_MIME_TYPE, "mime_type", newSVpv (info->mime_type, 0));

		/* FIXME: what about GNOME_VFS_FILE_INFO_FIELDS_ACCESS? */
	}

	return sv_bless (newRV_noinc ((SV *) object),
	                 gv_stashpv ("Gnome2::VFS::FileInfo", 1));
}

#define VFS2PERL_FETCH_AND_CHECK(_type, _key, _member, _sv) \
		if (hv_exists (hv, _key, strlen (_key))) { \
			value = hv_fetch (hv, _key, strlen (_key), FALSE); \
			if (value) _member = _sv; \
			info->valid_fields |= _type; \
		}

GnomeVFSFileInfo *
SvGnomeVFSFileInfo (SV *object)
{
	HV *hv = (HV *) SvRV (object);
	SV **value;

	GnomeVFSFileInfo *info = gperl_alloc_temp (sizeof (GnomeVFSFileInfo));

	if (object && SvOK (object) && SvROK (object) && SvTYPE (SvRV (object)) == SVt_PVHV) {
		value = hv_fetch (hv, "name", 4, FALSE);
		if (value) info->name = SvPV_nolen (*value);

		info->valid_fields = GNOME_VFS_FILE_INFO_FIELDS_NONE;

		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_TYPE, "type", info->type, SvGnomeVFSFileType (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_PERMISSIONS, "permissions", info->permissions, SvGnomeVFSFilePermissions (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_FLAGS, "flags", info->flags, SvGnomeVFSFileFlags (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_DEVICE, "device", info->device, SvIV (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_INODE, "inode", info->inode, SvUV (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_LINK_COUNT, "link_count", info->link_count, SvUV (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_SIZE, "size", info->size, SvGnomeVFSFileSize (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_BLOCK_COUNT, "block_count", info->block_count, SvGnomeVFSFileSize (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_IO_BLOCK_SIZE, "io_block_size", info->io_block_size, SvUV (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_ATIME, "atime", info->atime, SvIV (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_MTIME, "mtime", info->mtime, SvIV (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_CTIME, "ctime", info->ctime, SvIV (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_SYMLINK_NAME, "symlink_name", info->symlink_name, SvPV_nolen (*value));
		VFS2PERL_FETCH_AND_CHECK (GNOME_VFS_FILE_INFO_FIELDS_MIME_TYPE, "mime_type", info->mime_type, SvPV_nolen (*value));

		/* FIXME: what about GNOME_VFS_FILE_INFO_FIELDS_ACCESS? */
	}

	return info;
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSXferProgressInfo (GnomeVFSXferProgressInfo *info)
{
	HV * hv = newHV ();

	if (info) {
		hv_store (hv, "status", 6, newSVGnomeVFSXferProgressStatus (info->status), 0);
		hv_store (hv, "vfs_status", 10, newSVGnomeVFSResult (info->vfs_status), 0);
		hv_store (hv, "phase", 5, newSVGnomeVFSXferPhase (info->phase), 0);
		hv_store (hv, "file_index", 10, newSVuv (info->file_index), 0);
		hv_store (hv, "files_total", 11, newSVuv (info->files_total), 0);
		hv_store (hv, "bytes_total", 11, newSVuv (info->bytes_total), 0);
		hv_store (hv, "file_size", 9, newSVuv (info->file_size), 0);
		hv_store (hv, "bytes_copied", 12, newSVuv (info->bytes_copied), 0);
		hv_store (hv, "total_bytes_copied", 18, newSVuv (info->total_bytes_copied), 0);
		hv_store (hv, "top_level_item", 14, newSVuv (info->top_level_item), 0);

		if (info->source_name)
			hv_store (hv, "source_name", 11, newSVGChar (info->source_name), 0);

		if (info->target_name)
			hv_store (hv, "target_name", 11, newSVGChar (info->target_name), 0);

		if (info->duplicate_count)
			hv_store (hv, "duplicate_count", 15, newSViv (info->duplicate_count), 0);

		/* FIXME: add a version check once the fix from teuf makes it
		          into an official release. */
		if (info->duplicate_name && info->phase != GNOME_VFS_XFER_PHASE_COMPLETED)
			hv_store (hv, "duplicate_name", 14, newSVGChar (info->duplicate_name), 0);
	}

	return newRV_noinc ((SV*) hv);
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSMimeApplication (GnomeVFSMimeApplication *application)
{
	HV *hash = newHV ();

	if (application == NULL)
		return &PL_sv_undef;

#if VFS_CHECK_VERSION (2, 10, 0)
	sv_magic ((SV *) hash, 0, PERL_MAGIC_ext, (const char *) application, 0);
#endif

	hv_store (hash, "id", 2, newSVpv (application->id, 0), 0);
	hv_store (hash, "name", 4, newSVpv (application->name, 0), 0);
	hv_store (hash, "command", 7, newSVpv (application->command, 0), 0);
	hv_store (hash, "can_open_multiple_files", 23, newSVuv (application->can_open_multiple_files), 0);
	hv_store (hash, "expects_uris", 12, newSVGnomeVFSMimeApplicationArgumentType (application->expects_uris), 0);
	hv_store (hash, "requires_terminal", 17, newSVuv (application->requires_terminal), 0);

	if (application->supported_uri_schemes != NULL) {
		AV *array = newAV ();
		GList *i;

		for (i = application->supported_uri_schemes; i != NULL; i = i->next)
			av_push (array, newSVpv (i->data, 0));

		hv_store (hash, "supported_uri_schemes", 21, newRV_noinc ((SV *) array), 0);
	}

	return sv_bless (newRV_noinc ((SV *) hash),
	                 gv_stashpv ("Gnome2::VFS::Mime::Application", 1));
}

GnomeVFSMimeApplication *
SvGnomeVFSMimeApplication (SV *object)
{
#if VFS_CHECK_VERSION (2, 10, 0)
	GnomeVFSMimeApplication *application;
	MAGIC *mg;

	if (!object || !SvOK (object) || !SvROK (object) || !(mg = mg_find (SvRV (object), PERL_MAGIC_ext)))
		return NULL;

	application = (GnomeVFSMimeApplication *) mg->mg_ptr;
#else
	GnomeVFSMimeApplication *application = gperl_alloc_temp (sizeof (GnomeVFSMimeApplication));

	if (object && SvOK (object) && SvROK (object) && SvTYPE (SvRV (object)) == SVt_PVHV) {
		HV *hv = (HV *) SvRV (object);
		SV **value;

		value = hv_fetch (hv, "id", 2, FALSE);
		if (value) application->id = SvPV_nolen (*value);

		value = hv_fetch (hv, "name", 4, FALSE);
		if (value) application->name = SvPV_nolen (*value);

		value = hv_fetch (hv, "command", 7, FALSE);
		if (value) application->command = SvPV_nolen (*value);

		value = hv_fetch (hv, "can_open_multiple_files", 23, FALSE);
		if (value) application->can_open_multiple_files = SvUV (*value);

		value = hv_fetch (hv, "expects_uris", 12, FALSE);
		if (value) application->expects_uris = SvGnomeVFSMimeApplicationArgumentType (*value);

		value = hv_fetch (hv, "requires_terminal", 17, FALSE);
		if (value) application->requires_terminal = SvUV (*value);

		value = hv_fetch (hv, "supported_uri_schemes", 21, FALSE);
		if (value && *value && SvOK (*value) && SvROK (*value) && SvTYPE (SvRV (*value)) == SVt_PVAV) {
			AV *array = (AV *) SvRV (*value);
			int i;

			application->supported_uri_schemes = NULL;

			for (i = 0; i <= av_len (array); i++) {
				value = av_fetch (array, i, 0);

				if (value)
					application->supported_uri_schemes = g_list_append (application->supported_uri_schemes, SvPV_nolen (*value));
			}
		}
	}
#endif

	return application;
}

/* ------------------------------------------------------------------------- */

GnomeVFSMimeType *
SvGnomeVFSMimeType (SV *object)
{
	MAGIC *mg;

	if (!object || !SvOK (object) || !SvROK (object) || !(mg = mg_find (SvRV (object), PERL_MAGIC_ext)))
		return NULL;

	return (GnomeVFSMimeType *) mg->mg_ptr;
}

SV *
newSVGnomeVFSMimeType (GnomeVFSMimeType *mime_type)
{
	SV *rv;
	HV *stash;
	SV *object = (SV *) newHV ();

	sv_magic (object, 0, PERL_MAGIC_ext, mime_type, 0);

	rv = newRV_noinc (object);
	stash = gv_stashpv ("Gnome2::VFS::Mime::Type", 1);

	return sv_bless (rv, stash);
}

/* -------------------------------------------------------------------------  */

GList *
SvPVGList (SV *ref)
{
	int i;

	AV *array;
	SV **value;

	GList *list = NULL;

	if (! (SvRV (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV))
		croak ("URI list has to be a reference to an array");

	array = (AV *) SvRV (ref);

	for (i = 0; i <= av_len (array); i++)
		if ((value = av_fetch (array, i, 0)) && SvOK (*value))
			list = g_list_append(list, SvPV_nolen (*value));

	return list;
}

/* ------------------------------------------------------------------------- */

GList *
SvGnomeVFSURIGList (SV *ref)
{
	int i;

	AV *array;
	SV **value;

	GList *list = NULL;

	if (! (SvRV (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV))
		croak ("URI list has to be a reference to an array");

	array = (AV *) SvRV (ref);

	for (i = 0; i <= av_len (array); i++)
		if ((value = av_fetch (array, i, 0)) && SvOK (*value))
			list = g_list_append(list, SvGnomeVFSURI (*value));

	return list;
}

/* ------------------------------------------------------------------------- */

char **
SvEnvArray (SV *ref)
{
	char **result = NULL;

	if (SvOK (ref)) {
		if (SvRV (ref) && SvTYPE (SvRV (ref)) == SVt_PVAV) {
			AV *array = (AV *) SvRV (ref);
			SV **string;

			int i, length = av_len (array);
			result = g_new0 (char *, length + 2);

			for (i = 0; i <= length; i++)
				if ((string = av_fetch (array, i, 0)) && SvOK (*string))
					result[i] = SvPV_nolen (*string);

			result[length + 1] = NULL;
		}
		else
			croak ("the environment parameter must be an array reference");
	}

	return result;
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSFileInfoGList (GList *list)
{
	AV *array = newAV ();

	for (; list != NULL; list = list->next)
		av_push (array, newSVGnomeVFSFileInfo (list->data));

	return newRV_noinc ((SV *) array);
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSGetFileInfoResultGList (GList *list)
{
	AV *array = newAV ();

	for (; list != NULL; list = list->next) {
		HV *hash = newHV ();
		GnomeVFSGetFileInfoResult* result = list->data;

		gnome_vfs_uri_ref (result->uri);

		hv_store (hash, "uri", 3, newSVGnomeVFSURI (result->uri), 0);
		hv_store (hash, "result", 6, newSVGnomeVFSResult (result->result), 0);
		hv_store (hash, "file_info", 9, newSVGnomeVFSFileInfo (result->file_info), 0);

		av_push (array, newRV_noinc ((SV *) hash));
	}

	return newRV_noinc ((SV *) array);
}

/* ------------------------------------------------------------------------- */

SV *
newSVGnomeVFSFindDirectoryResultGList (GList *list)
{
	AV *array = newAV ();

	for (; list != NULL; list = list->next) {
		HV *hash = newHV ();
		GnomeVFSFindDirectoryResult* result = list->data;

		hv_store (hash, "result", 6, newSVGnomeVFSResult (result->result), 0);

		if (result->uri) {
			gnome_vfs_uri_ref (result->uri);
			hv_store (hash, "uri", 3, newSVGnomeVFSURI (result->uri), 0);
		}

		av_push (array, newRV_noinc ((SV *) hash));
	}

	return newRV_noinc ((SV *) array);
}
