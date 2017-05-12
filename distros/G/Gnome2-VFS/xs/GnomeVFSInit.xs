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

MODULE = Gnome2::VFS::Init	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::main

=cut

##  gboolean gnome_vfs_init (void) 
gboolean
gnome_vfs_init (class)
    C_ARGS:
	/* void */

##  gboolean gnome_vfs_initialized (void) 
gboolean
gnome_vfs_initialized (class)
    C_ARGS:
	/* void */

##  void gnome_vfs_shutdown (void) 
void
gnome_vfs_shutdown (class)
    C_ARGS:
	/* void */
