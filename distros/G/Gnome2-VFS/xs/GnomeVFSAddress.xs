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

MODULE = Gnome2::VFS::Address	PACKAGE = Gnome2::VFS::Address	PREFIX = gnome_vfs_address_

##  GnomeVFSAddress *gnome_vfs_address_new_from_string (const char *address)
GnomeVFSAddress_own *
gnome_vfs_address_new_from_string (class, address)
	const char *address
    C_ARGS:
	address

##  int gnome_vfs_address_get_family_type (GnomeVFSAddress *address)
int
gnome_vfs_address_get_family_type (address)
	GnomeVFSAddress *address

##  char * gnome_vfs_address_to_string (GnomeVFSAddress *address)
char_own *
gnome_vfs_address_to_string (address)
	GnomeVFSAddress *address

##  Should not be used, according to the docs.
##  GnomeVFSAddress *gnome_vfs_address_new_from_ipv4 (guint32 ipv4_address)
##  guint32 gnome_vfs_address_get_ipv4 (GnomeVFSAddress *address)

##  Not really usable from Perl, are they?
##  GnomeVFSAddress *gnome_vfs_address_new_from_sockaddr (struct sockaddr *sa, int len)
##  struct sockaddr *gnome_vfs_address_get_sockaddr (GnomeVFSAddress *address, guint16 port, int *len)

#if VFS_CHECK_VERSION (2, 13, 1) /* FIXME: 2.14 */

gboolean gnome_vfs_address_equal (const GnomeVFSAddress *a, const GnomeVFSAddress *b);

gboolean gnome_vfs_address_match (const GnomeVFSAddress *a, const GnomeVFSAddress *b, guint prefix);

#endif
