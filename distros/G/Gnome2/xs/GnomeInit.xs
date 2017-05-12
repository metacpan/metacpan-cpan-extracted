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

MODULE = Gnome2::Init	PACKAGE = Gnome2	PREFIX = gnome_

=for object Gnome2::main

=cut

const char *
user_dir_get (class)
    ALIAS:
	Gnome2::user_private_dir_get = 1
	Gnome2::user_accels_dir_get = 2
    CODE:
	switch (ix) {
		case 0: RETVAL = gnome_user_dir_get (); break;
		case 1: RETVAL = gnome_user_private_dir_get (); break;
		case 2: RETVAL = gnome_user_accels_dir_get (); break;
		default: RETVAL = NULL;
	}
    OUTPUT:
	RETVAL

