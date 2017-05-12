/*
 * Copyright (C) 2004 by the gtk2-perl team
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

MODULE = Gnome2::VFS::Resolve	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::Resolve
=cut

##  GnomeVFSResult gnome_vfs_resolve (const char *hostname, GnomeVFSResolveHandle **handle)
void
gnome_vfs_resolve (class, hostname)
	const char *hostname
    PREINIT:
	GnomeVFSResult result;
	GnomeVFSResolveHandle *handle = NULL;
    PPCODE:
	result = gnome_vfs_resolve (hostname, &handle);

	PUSHs (sv_2mortal (newSVGnomeVFSResult (result)));

	if (result == GNOME_VFS_OK) {
		XPUSHs (sv_2mortal (newSVGnomeVFSResolveHandle (handle)));
	}

MODULE = Gnome2::VFS::Resolve	PACKAGE = Gnome2::VFS::Resolve::Handle	PREFIX = gnome_vfs_resolve_

void
DESTROY (handle)
	GnomeVFSResolveHandle *handle
    CODE:
	gnome_vfs_resolve_free (handle);

##  gboolean gnome_vfs_resolve_next_address (GnomeVFSResolveHandle *handle, GnomeVFSAddress **address)
GnomeVFSAddress_ornull *
gnome_vfs_resolve_next_address (handle)
	GnomeVFSResolveHandle *handle
    PREINIT:
	GnomeVFSAddress *address = NULL;
    CODE:
	RETVAL = gnome_vfs_resolve_next_address (handle, &address) ?
	           address :
	           NULL;
    OUTPUT:
	RETVAL

##  void gnome_vfs_resolve_reset_to_beginning (GnomeVFSResolveHandle *handle)
void
gnome_vfs_resolve_reset_to_beginning (handle)
	GnomeVFSResolveHandle *handle
