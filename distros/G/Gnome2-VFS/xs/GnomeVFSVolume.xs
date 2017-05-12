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

/* Also used in GnomeVFSDrive.xs. */

GPerlCallback *
vfs2perl_volume_op_callback_create (SV *func, SV *data)
{
	GType param_types[3] = {
		G_TYPE_BOOLEAN,
		G_TYPE_STRING,
		G_TYPE_STRING
	};
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, 0);
}

void
vfs2perl_volume_op_callback (gboolean succeeded,
                             char *error,
                             char *detailed_error,
                             GPerlCallback *callback)
{
	gperl_callback_invoke (callback, NULL, succeeded, error,
	                                       detailed_error);
	gperl_callback_destroy (callback);
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::VFS::Volume	PACKAGE = Gnome2::VFS::Volume	PREFIX = gnome_vfs_volume_

##  gulong gnome_vfs_volume_get_id (GnomeVFSVolume *volume)
gulong
gnome_vfs_volume_get_id (volume)
	GnomeVFSVolume *volume

##  GnomeVFSVolumeType gnome_vfs_volume_get_volume_type (GnomeVFSVolume *volume)
GnomeVFSVolumeType
gnome_vfs_volume_get_volume_type (volume)
	GnomeVFSVolume *volume

##  GnomeVFSDeviceType gnome_vfs_volume_get_device_type (GnomeVFSVolume *volume)
GnomeVFSDeviceType
gnome_vfs_volume_get_device_type (volume)
	GnomeVFSVolume *volume

##  GnomeVFSDrive * gnome_vfs_volume_get_drive (GnomeVFSVolume *volume)
GnomeVFSDrive *
gnome_vfs_volume_get_drive (volume)
	GnomeVFSVolume *volume

##  char * gnome_vfs_volume_get_device_path (GnomeVFSVolume *volume)
char_own *
gnome_vfs_volume_get_device_path (volume)
	GnomeVFSVolume *volume

##  char * gnome_vfs_volume_get_activation_uri (GnomeVFSVolume *volume)
char_own *
gnome_vfs_volume_get_activation_uri (volume)
	GnomeVFSVolume *volume

##  char * gnome_vfs_volume_get_filesystem_type (GnomeVFSVolume *volume)
char_own *
gnome_vfs_volume_get_filesystem_type (volume)
	GnomeVFSVolume *volume

##  char * gnome_vfs_volume_get_display_name (GnomeVFSVolume *volume)
char_own *
gnome_vfs_volume_get_display_name (volume)
	GnomeVFSVolume *volume

##  char * gnome_vfs_volume_get_icon (GnomeVFSVolume *volume)
char_own *
gnome_vfs_volume_get_icon (volume)
	GnomeVFSVolume *volume

##  gboolean gnome_vfs_volume_is_user_visible (GnomeVFSVolume *volume)
gboolean
gnome_vfs_volume_is_user_visible (volume)
	GnomeVFSVolume *volume

##  gboolean gnome_vfs_volume_is_read_only (GnomeVFSVolume *volume)
gboolean
gnome_vfs_volume_is_read_only (volume)
	GnomeVFSVolume *volume

##  gboolean gnome_vfs_volume_is_mounted (GnomeVFSVolume *volume)
gboolean
gnome_vfs_volume_is_mounted (volume)
	GnomeVFSVolume *volume

##  gboolean gnome_vfs_volume_handles_trash (GnomeVFSVolume *volume)
gboolean
gnome_vfs_volume_handles_trash (volume)
	GnomeVFSVolume *volume

##  gint gnome_vfs_volume_compare (GnomeVFSVolume *a, GnomeVFSVolume *b)
gint
gnome_vfs_volume_compare (a, b)
	GnomeVFSVolume *a
	GnomeVFSVolume *b


##  void gnome_vfs_volume_unmount (GnomeVFSVolume *volume, GnomeVFSVolumeOpCallback callback, gpointer user_data)
##  void gnome_vfs_volume_eject (GnomeVFSVolume *volume, GnomeVFSVolumeOpCallback callback, gpointer user_data)
void
gnome_vfs_volume_unmount (volume, func, data=NULL)
	GnomeVFSVolume *volume
	SV *func
	SV *data
    ALIAS:
	Gnome2::VFS::Volume::eject = 1
    PREINIT:
	GPerlCallback *callback;
    CODE:
	callback = vfs2perl_volume_op_callback_create (func, data);

	switch (ix) {
		case 0: gnome_vfs_volume_unmount (volume,
	                                          (GnomeVFSVolumeOpCallback)
	                                            vfs2perl_volume_op_callback,
	                                          callback);
		        break;

		case 1: gnome_vfs_volume_eject (volume,
	                                        (GnomeVFSVolumeOpCallback)
	                                          vfs2perl_volume_op_callback,
	                                        callback);
		        break;

		default: g_assert_not_reached ();
	}

#if VFS_CHECK_VERSION (2, 8, 0)

##  char * gnome_vfs_volume_get_hal_udi (GnomeVFSVolume *volume)
char *
gnome_vfs_volume_get_hal_udi (volume)
	GnomeVFSVolume *volume

#endif

MODULE = Gnome2::VFS::Volume	PACKAGE = Gnome2::VFS	PREFIX = gnome_vfs_

=for object Gnome2::VFS::Volume
=cut

##  void gnome_vfs_connect_to_server (char *uri, char *display_name, char *icon)
void
gnome_vfs_connect_to_server (class, uri, display_name, icon)
	char *uri
	char *display_name
	char *icon
    C_ARGS:
	uri, display_name, icon
