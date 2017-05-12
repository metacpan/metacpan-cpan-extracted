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

MODULE = Gnome2::VFS	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::main

=cut

BOOT:
#include "register.xsh"
#include "boot.xsh"
	gperl_handle_logs_for ("libgnomevfs");

=for apidoc

Returns the major, minor and micro version numbers of GnomeVFS.

=cut
void
GET_VERSION_INFO (class)
    PPCODE:
	PERL_UNUSED_VAR (ax);
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (VFS_MAJOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (VFS_MINOR_VERSION)));
	PUSHs (sv_2mortal (newSViv (VFS_MICRO_VERSION)));

bool
CHECK_VERSION (class, major, minor, micro)
	int major
	int minor
	int micro
    CODE:
	RETVAL = VFS_CHECK_VERSION (major, minor, micro);
    OUTPUT:
	RETVAL

=for apidoc

Returns a GnomeVFSResult and a GnomeVFSURI.

=cut
##  GnomeVFSResult gnome_vfs_find_directory (GnomeVFSURI *near_uri, GnomeVFSFindDirectoryKind kind, GnomeVFSURI **result, gboolean create_if_needed, gboolean find_if_needed, guint permissions)
void
gnome_vfs_find_directory (class, near_uri, kind, create_if_needed, find_if_needed, permissions)
	GnomeVFSURI *near_uri
	GnomeVFSFindDirectoryKind kind
	gboolean create_if_needed
	gboolean find_if_needed
	guint permissions
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSURI *result_uri;
    PPCODE:
	result = gnome_vfs_find_directory (near_uri, kind, &result_uri, create_if_needed, find_if_needed, permissions);
	EXTEND (sp, 2);
	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));
	PUSHs (sv_2mortal (newSVGnomeVFSURI (result_uri)));

##  const char *gnome_vfs_result_to_string (GnomeVFSResult result)
const char *
gnome_vfs_result_to_string (class, result)
	GnomeVFSResult result
    C_ARGS:
	result
