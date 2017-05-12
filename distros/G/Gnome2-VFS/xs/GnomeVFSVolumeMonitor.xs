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

MODULE = Gnome2::VFS::VolumeMonitor	PACKAGE = Gnome2::VFS::VolumeMonitor::Client

BOOT:
	gperl_object_set_no_warn_unreg_subclass (GNOME_VFS_TYPE_VOLUME_MONITOR, TRUE);

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::VolumeMonitor	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::VolumeMonitor
=cut

##  GnomeVFSVolumeMonitor *gnome_vfs_get_volume_monitor (void)
GnomeVFSVolumeMonitor *
gnome_vfs_get_volume_monitor (class)
    C_ARGS:
	/* void */

# --------------------------------------------------------------------------- #

MODULE = Gnome2::VFS::VolumeMonitor	PACKAGE = Gnome2::VFS::VolumeMonitor	PREFIX = gnome_vfs_volume_monitor_

#if !VFS_CHECK_VERSION (2, 8, 1)

void
DESTROY (monitor)
    CODE:
	/* do nada to avoid finalizing the monitor. */

#endif

##  GList * gnome_vfs_volume_monitor_get_mounted_volumes (GnomeVFSVolumeMonitor *volume_monitor)
void
gnome_vfs_volume_monitor_get_mounted_volumes (volume_monitor)
	GnomeVFSVolumeMonitor *volume_monitor
    PREINIT:
	GList *volumes = NULL, *i;
    PPCODE:
	volumes = gnome_vfs_volume_monitor_get_mounted_volumes (volume_monitor);

	for (i = volumes; i; i = i->next) {
		XPUSHs (sv_2mortal (newSVGnomeVFSVolume (i->data)));
		gnome_vfs_volume_unref (i->data);
	}

	g_list_free (volumes);

##  GList * gnome_vfs_volume_monitor_get_connected_drives (GnomeVFSVolumeMonitor *volume_monitor)
void
gnome_vfs_volume_monitor_get_connected_drives (volume_monitor)
	GnomeVFSVolumeMonitor *volume_monitor
    PREINIT:
	GList *drives = NULL, *i;
    PPCODE:
	drives = gnome_vfs_volume_monitor_get_connected_drives (volume_monitor);

	for (i = drives; i; i = i->next) {
		XPUSHs (sv_2mortal (newSVGnomeVFSDrive (i->data)));
		gnome_vfs_drive_unref (i->data);
	}

	g_list_free (drives);

##  GnomeVFSVolume * gnome_vfs_volume_monitor_get_volume_for_path (GnomeVFSVolumeMonitor *volume_monitor, const char *path)
GnomeVFSVolume *
gnome_vfs_volume_monitor_get_volume_for_path (volume_monitor, path)
	GnomeVFSVolumeMonitor *volume_monitor
	const char *path

##  GnomeVFSVolume * gnome_vfs_volume_monitor_get_volume_by_id (GnomeVFSVolumeMonitor *volume_monitor, gulong id)
GnomeVFSVolume *
gnome_vfs_volume_monitor_get_volume_by_id (volume_monitor, id)
	GnomeVFSVolumeMonitor *volume_monitor
	gulong id

##  GnomeVFSDrive * gnome_vfs_volume_monitor_get_drive_by_id (GnomeVFSVolumeMonitor *volume_monitor, gulong id)
GnomeVFSDrive *
gnome_vfs_volume_monitor_get_drive_by_id (volume_monitor, id)
	GnomeVFSVolumeMonitor *volume_monitor
	gulong id
