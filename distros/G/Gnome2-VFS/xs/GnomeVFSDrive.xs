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

/* ------------------------------------------------------------------------- */

/* From GnomeVFSVolume.xs. */

extern GPerlCallback *
vfs2perl_volume_op_callback_create (SV *func,
                                    SV *data);

extern void
vfs2perl_volume_op_callback (gboolean succeeded,
                             char *error,
                             char *detailed_error,
                             GPerlCallback *callback);

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::Drive	PACKAGE = Gnome2::VFS::Drive	PREFIX = gnome_vfs_drive_

##  gulong gnome_vfs_drive_get_id (GnomeVFSDrive *drive)
gulong
gnome_vfs_drive_get_id (drive)
	GnomeVFSDrive *drive

##  GnomeVFSDeviceType gnome_vfs_drive_get_device_type (GnomeVFSDrive *drive)
GnomeVFSDeviceType
gnome_vfs_drive_get_device_type (drive)
	GnomeVFSDrive *drive

##  char * gnome_vfs_drive_get_device_path (drive)
char *
gnome_vfs_drive_get_device_path (drive)
	GnomeVFSDrive *drive

##  char * gnome_vfs_drive_get_activation_uri (drive)
char *
gnome_vfs_drive_get_activation_uri (drive)
	GnomeVFSDrive *drive

##  char * gnome_vfs_drive_get_display_name (drive)
char *
gnome_vfs_drive_get_display_name (drive)
	GnomeVFSDrive *drive

##  char * gnome_vfs_drive_get_icon (drive)
char *
gnome_vfs_drive_get_icon (drive)
	GnomeVFSDrive *drive

##  gboolean gnome_vfs_drive_is_user_visible (drive)
gboolean
gnome_vfs_drive_is_user_visible (drive)
	GnomeVFSDrive *drive

##  gboolean gnome_vfs_drive_is_connected (drive)
gboolean
gnome_vfs_drive_is_connected (drive)
	GnomeVFSDrive *drive

##  gboolean gnome_vfs_drive_is_mounted (drive)
gboolean
gnome_vfs_drive_is_mounted (drive)
	GnomeVFSDrive *drive

##  gint gnome_vfs_drive_compare (a, b)
gint
gnome_vfs_drive_compare (a, b)
	GnomeVFSDrive *a
	GnomeVFSDrive *b

##  void gnome_vfs_drive_mount (GnomeVFSDrive *drive, GnomeVFSVolumeOpCallback callback, gpointer user_data)
##  void gnome_vfs_drive_unmount (GnomeVFSDrive *drive, GnomeVFSVolumeOpCallback callback, gpointer user_data)
##  void gnome_vfs_drive_eject (GnomeVFSDrive *drive, GnomeVFSVolumeOpCallback callback, gpointer user_data)
void
gnome_vfs_drive_mount (drive, func, data=NULL)
	GnomeVFSDrive *drive
	SV *func
	SV *data
    ALIAS:
	Gnome2::VFS::Drive::unmount = 1
	Gnome2::VFS::Drive::eject = 2
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_volume_op_callback_create (func, data);

	switch (ix) {
		case 0: gnome_vfs_drive_mount (drive,
	                                       (GnomeVFSVolumeOpCallback)
	                                         vfs2perl_volume_op_callback,
	                                       callback);
		        break;

		case 1: gnome_vfs_drive_unmount (drive,
	                                         (GnomeVFSVolumeOpCallback)
	                                           vfs2perl_volume_op_callback,
	                                         callback);
		        break;

		case 2: gnome_vfs_drive_eject (drive,
	                                       (GnomeVFSVolumeOpCallback)
	                                         vfs2perl_volume_op_callback,
	                                       callback);
		        break;

		default: g_assert_not_reached ();
	}

#if VFS_CHECK_VERSION (2, 8, 0)

##  GList * gnome_vfs_drive_get_mounted_volumes (GnomeVFSDrive *drive)
void
gnome_vfs_drive_get_mounted_volumes (drive)
	GnomeVFSDrive *drive
    PREINIT:
	GList *list = NULL, *i;
    PPCODE:
	list = gnome_vfs_drive_get_mounted_volumes (drive);

	for (i = list; i; i = i->next) {
		XPUSHs (sv_2mortal (newSVGnomeVFSVolume (i->data)));
	}

	gnome_vfs_drive_volume_list_free (list);

##  char * gnome_vfs_drive_get_hal_udi (drive)
char *
gnome_vfs_drive_get_hal_udi (drive)
	GnomeVFSDrive *drive

#endif /* 2.8 */

#if VFS_CHECK_VERSION (2, 16, 0)

gboolean gnome_vfs_drive_needs_eject (GnomeVFSDrive *drive);

#endif
