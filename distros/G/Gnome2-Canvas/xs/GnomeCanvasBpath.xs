/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomeCanvas/xs/GnomeCanvasBpath.xs,v 1.1 2003/07/05 04:50:57 muppetman Exp $
 */
#include "gnomecanvasperl.h"

/*
 * libgnomecanvas installs the object property bpath with G_TYPE_POINTER.
 * because of this, we can't use any of our existing bindings tools, because
 * G_TYPE_POINTER carries no type information and doesn't take anything 
 * useful like copy and free functions.  i filed a bug report about this,
 * #116734.
 *
 * as a workaround, you must use extra functions to set and get the bpath.
 */

MODULE = Gnome2::Canvas::Bpath	PACKAGE = Gnome2::Canvas::Bpath

##
## TODO: if/when libgnomecanvas fixes the bpath to be a boxed type, we'll
## need to add an #ifdef around this, based on the library version.
##

void
set_path_def (bpath, path_def)
	GnomeCanvasBpath * bpath
	GnomeCanvasPathDef * path_def
    CODE:
	g_object_set (G_OBJECT (bpath), "bpath", path_def, NULL);

GnomeCanvasPathDef_copy *
get_path_def (bpath)
	GnomeCanvasBpath * bpath
    CODE:
	g_object_get (G_OBJECT (bpath), "bpath", (gpointer) &RETVAL, NULL);
    OUTPUT:
	RETVAL
