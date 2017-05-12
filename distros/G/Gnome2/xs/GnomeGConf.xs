/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

MODULE = Gnome2::GConf	PACKAGE = Gnome2::GConf	PREFIX = gnome_gconf_

=for object Gnome2::main

=cut

##  gchar *gnome_gconf_get_gnome_libs_settings_relative (const gchar *subkey) 
gchar_own *
gnome_gconf_get_gnome_libs_settings_relative (class, subkey)
	const gchar *subkey
    C_ARGS:
	subkey

##  gchar *gnome_gconf_get_app_settings_relative (GnomeProgram *program, const gchar *subkey) 
gchar_own *
gnome_gconf_get_app_settings_relative (class, program, subkey)
	GnomeProgram *program
	const gchar *subkey
    C_ARGS:
	program, subkey

