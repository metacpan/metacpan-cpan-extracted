/*
 * Copyright (C) 2003, 2013 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gnome2::ModuleInfo	PACKAGE = Gnome2::ModuleInfo

GnomeModuleInfo *
libgnome (class)
    ALIAS:
	Gnome2::ModuleInfo::libgnomeui = 1
	Gnome2::ModuleInfo::bonobo = 2
    CODE:
	switch (ix) {
		/* casting off const to avoid compiler warnings */
		case 0: RETVAL = (GnomeModuleInfo*) LIBGNOME_MODULE; break;
		case 1: RETVAL = (GnomeModuleInfo*) LIBGNOME_MODULE; break;
		case 2: RETVAL = (GnomeModuleInfo*) gnome_bonobo_module_info_get (); break;
		default: RETVAL = NULL;
	}
    OUTPUT:
	RETVAL


SV *
name (module_info)
	GnomeModuleInfo * module_info
    ALIAS:
	Gnome2::ModuleInfo::version = 1
	Gnome2::ModuleInfo::description = 2
	Gnome2::ModuleInfo::opt_prefix = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = newSVpv (module_info->name, 0); break;
		case 1: RETVAL = newSVpv (module_info->version, 0); break;
		case 2: RETVAL = newSVpv (module_info->description, 0); break;
		case 3: RETVAL = newSVpv (module_info->opt_prefix, 0); break;
		default: RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL
