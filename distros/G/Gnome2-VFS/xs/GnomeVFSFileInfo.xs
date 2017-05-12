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

/* ------------------------------------------------------------------------- */

#ifdef VFS2PERL_BROKEN_FILE_PERMISSIONS

/*
 * GnomeVFSFilePermissions is supposed to be a GFlags type, but on some
 * early releases, it appears that glib-mkenums misread the definition and
 * registered it as a GEnum type, instead.  This causes some big problems
 * for using the type in the bindings; if we do nothing, we get incessant
 * assertions that the type is not a GFlags type, but if we register it as
 * an enum instead, we get errors because bit-combination values aren't
 * part of the enum set.  The only real solution is to hijack the type
 * macro to point to our own special get_type and registration which does
 * it properly.
 *
 * these are the values that are actually defined in my header for 2.0.2 
 * on redhat 8.0.  some of the values present in later versions are missing.
 *
 * - muppet, 18 nov 03
 */
static const GFlagsValue file_perms_values[] = {
  { GNOME_VFS_PERM_SUID,        "GNOME_VFS_PERM_SUID",        "suid"        },
  { GNOME_VFS_PERM_SGID,        "GNOME_VFS_PERM_SGID",        "sgid"        },  
  { GNOME_VFS_PERM_STICKY,      "GNOME_VFS_PERM_STICKY",      "sticky"      },
  { GNOME_VFS_PERM_USER_READ,   "GNOME_VFS_PERM_USER_READ",   "user-read"   },
  { GNOME_VFS_PERM_USER_WRITE,  "GNOME_VFS_PERM_USER_WRITE",  "user-write"  },
  { GNOME_VFS_PERM_USER_EXEC,   "GNOME_VFS_PERM_USER_EXEC",   "user-exec"   },
  { GNOME_VFS_PERM_USER_ALL,    "GNOME_VFS_PERM_USER_ALL",    "user-all"    },
  { GNOME_VFS_PERM_GROUP_READ,  "GNOME_VFS_PERM_GROUP_READ",  "group-read"  },
  { GNOME_VFS_PERM_GROUP_WRITE, "GNOME_VFS_PERM_GROUP_WRITE", "group-write" },
  { GNOME_VFS_PERM_GROUP_EXEC,  "GNOME_VFS_PERM_GROUP_EXEC",  "group-exec"  },
  { GNOME_VFS_PERM_GROUP_ALL,   "GNOME_VFS_PERM_GROUP_ALL",   "group-all"   },
  { GNOME_VFS_PERM_OTHER_READ,  "GNOME_VFS_PERM_OTHER_READ",  "other-read"  },
  { GNOME_VFS_PERM_OTHER_WRITE, "GNOME_VFS_PERM_OTHER_WRITE", "other-write" },
  { GNOME_VFS_PERM_OTHER_EXEC,  "GNOME_VFS_PERM_OTHER_EXEC",  "other-exec"  },
  { GNOME_VFS_PERM_OTHER_ALL,   "GNOME_VFS_PERM_OTHER_ALL",   "other-all"   },
};

GType
_vfs2perl_gnome_vfs_file_permissions_get_type (void)
{
	static GType type = 0;

	if (!type)
		type = g_flags_register_static ("VFS2PerlFilePermissions",
		                                file_perms_values);

	return type;
}

#endif /* VFS2PERL_BROKEN_FILE_PERMISSIONS */

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::FileInfo	PACKAGE = Gnome2::VFS::FileInfo	PREFIX = gnome_vfs_file_info_

=for apidocs

Creates a new GnomeVFSFileInfo object from I<hash_ref> for use with
Gnome2::VFS::FileInfo::matches, for example.  Normally, you can always directly
use a hash reference if you're asked for a GnomeVFSFileInfo.

=cut
GnomeVFSFileInfo *
gnome_vfs_file_info_new (class, hash_ref)
	SV *hash_ref
    CODE:
	/* All this really doesn't do much more than just bless the reference,
	   because on the way out, the struct will be converted to a hash
	   reference again.  Not really efficient, but future-safe. */
	RETVAL = SvGnomeVFSFileInfo (hash_ref);
    OUTPUT:
	RETVAL

##  gboolean gnome_vfs_file_info_matches (const GnomeVFSFileInfo *a, const GnomeVFSFileInfo *b) 
gboolean
gnome_vfs_file_info_matches (a, b)
	const GnomeVFSFileInfo *a
	const GnomeVFSFileInfo *b

##  const char * gnome_vfs_file_info_get_mime_type (GnomeVFSFileInfo *info)
const char *
gnome_vfs_file_info_get_mime_type (info)
	GnomeVFSFileInfo *info
