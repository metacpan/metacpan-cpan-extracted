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

MODULE = Gnome2::Util	PACKAGE = Gnome2::Util	PREFIX = gnome_util_

const char *
gnome_util_extension (class, path)
	const char *path
    CODE:
	RETVAL = g_extension_pointer (path);
    OUTPUT:
	RETVAL

gchar_own *
gnome_util_prepend_user_home (class, file)
	const gchar *file
    C_ARGS:
	file

gchar_own *
gnome_util_home_file (class, file)
	const gchar *file
    C_ARGS:
	file

char *
gnome_util_user_shell (class)
    C_ARGS:
	/* void */
