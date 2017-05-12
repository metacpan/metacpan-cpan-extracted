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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomeCanvas/xs/GnomeCanvasPathDef.xs,v 1.8 2004/02/10 06:38:38 muppetman Exp $
 */
#include "gnomecanvasperl.h"


/*
 * if/when libgnomecanvas provides a boxed wrapper for GnomeCanvasPathDef,
 * we'll have to put these two functions behind version guards.
 */

static GnomeCanvasPathDef *
path_def_boxed_copy (GnomeCanvasPathDef * path_def)
{
	if (path_def)
		gnome_canvas_path_def_ref (path_def);
	return path_def;
}

GType
gnomecanvasperl_canvas_path_def_get_type (void)
{
	static GType id = 0;
	if (!id)
		id = g_boxed_type_register_static ("GnomeCanvasPathDef",
		              (GBoxedCopyFunc) path_def_boxed_copy,
		              (GBoxedFreeFunc) gnome_canvas_path_def_unref);
	return id;
}


MODULE = Gnome2::Canvas::PathDef	PACKAGE = Gnome2::Canvas::PathDef	PREFIX = gnome_canvas_path_def_

BOOT:
	gperl_register_boxed (GNOME_TYPE_CANVAS_PATH_DEF,
	                      "Gnome2::Canvas::PathDef", NULL);

##  GnomeCanvasPathDef * gnome_canvas_path_def_new (void) 
GnomeCanvasPathDef_own *
gnome_canvas_path_def_new (class)
    C_ARGS:
	/*void*/

##  GnomeCanvasPathDef * gnome_canvas_path_def_new_sized (gint length) 
GnomeCanvasPathDef_own *
gnome_canvas_path_def_new_sized (class, length)
	gint length
    C_ARGS:
	length

####  GnomeCanvasPathDef * gnome_canvas_path_def_new_from_bpath (ArtBpath * bpath) 
##GnomeCanvasPathDef *
##gnome_canvas_path_def_new_from_bpath (bpath)
##	ArtBpath * bpath
##
####  GnomeCanvasPathDef * gnome_canvas_path_def_new_from_static_bpath (ArtBpath * bpath) 
##GnomeCanvasPathDef *
##gnome_canvas_path_def_new_from_static_bpath (bpath)
##	ArtBpath * bpath
##
####  GnomeCanvasPathDef * gnome_canvas_path_def_new_from_foreign_bpath (ArtBpath * bpath) 
##GnomeCanvasPathDef *
##gnome_canvas_path_def_new_from_foreign_bpath (bpath)
##	ArtBpath * bpath

##  void gnome_canvas_path_def_finish (GnomeCanvasPathDef * path) 
void
gnome_canvas_path_def_finish (path)
	GnomeCanvasPathDef * path

##  void gnome_canvas_path_def_ensure_space (GnomeCanvasPathDef * path, gint space) 
void
gnome_canvas_path_def_ensure_space (path, space)
	GnomeCanvasPathDef * path
	gint space

####  void gnome_canvas_path_def_copy (GnomeCanvasPathDef * dst, const GnomeCanvasPathDef * src) 
=for apidoc
Copy the path from I<$src> into I<$dst>.

Note: this method has very different semantics than the copy provided
by Glib::Boxed.   C<duplicate> is the analog there.
=cut
void
gnome_canvas_path_def_copy (dst, src)
	GnomeCanvasPathDef * dst
	const GnomeCanvasPathDef * src

##  GnomeCanvasPathDef * gnome_canvas_path_def_duplicate (const GnomeCanvasPathDef * path) 
GnomeCanvasPathDef_own *
gnome_canvas_path_def_duplicate (path)
	GnomeCanvasPathDef * path

##  GnomeCanvasPathDef * gnome_canvas_path_def_concat (const GSList * list) 
=for apidoc
=for arg ... Gnome2::Canvas::PathDef objects to concatenate
=cut
GnomeCanvasPathDef_own *
gnome_canvas_path_def_concat (class, ...)
    PREINIT:
	GSList * list = NULL;
	int i;
    CODE:
	for (i = 1 ; i < items ; i++)
		list = g_slist_append (list, SvGnomeCanvasPathDef (ST (i)));
	RETVAL = gnome_canvas_path_def_concat (list);
    OUTPUT:
	RETVAL
    CLEANUP:
	g_slist_free (list);

####  GSList * gnome_canvas_path_def_split (const GnomeCanvasPathDef * path) 
=for apidoc
=for signature @pathdefs = $path->split
=cut
void
gnome_canvas_path_def_split (path)
	GnomeCanvasPathDef * path
    PREINIT:
	GSList * list, * i;
    PPCODE:
	list = gnome_canvas_path_def_split (path);
	for (i = list ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGnomeCanvasPathDef_own (i->data)));
	g_slist_free (list);
	

##  GnomeCanvasPathDef * gnome_canvas_path_def_open_parts (const GnomeCanvasPathDef * path) 
GnomeCanvasPathDef_own *
gnome_canvas_path_def_open_parts (path)
	const GnomeCanvasPathDef * path

##  GnomeCanvasPathDef * gnome_canvas_path_def_closed_parts (const GnomeCanvasPathDef * path) 
GnomeCanvasPathDef_own *
gnome_canvas_path_def_closed_parts (path)
	const GnomeCanvasPathDef * path

##  GnomeCanvasPathDef * gnome_canvas_path_def_close_all (const GnomeCanvasPathDef * path) 
GnomeCanvasPathDef_own *
gnome_canvas_path_def_close_all (path)
	const GnomeCanvasPathDef * path


##  void gnome_canvas_path_def_reset (GnomeCanvasPathDef * path) 
void
gnome_canvas_path_def_reset (path)
	GnomeCanvasPathDef * path

##  void gnome_canvas_path_def_moveto (GnomeCanvasPathDef * path, gdouble x, gdouble y) 
void
gnome_canvas_path_def_moveto (path, x, y)
	GnomeCanvasPathDef * path
	gdouble x
	gdouble y

##  void gnome_canvas_path_def_lineto (GnomeCanvasPathDef * path, gdouble x, gdouble y) 
void
gnome_canvas_path_def_lineto (path, x, y)
	GnomeCanvasPathDef * path
	gdouble x
	gdouble y

##  void gnome_canvas_path_def_lineto_moving (GnomeCanvasPathDef * path, gdouble x, gdouble y) 
void
gnome_canvas_path_def_lineto_moving (path, x, y)
	GnomeCanvasPathDef * path
	gdouble x
	gdouble y

##  void gnome_canvas_path_def_curveto (GnomeCanvasPathDef * path, gdouble x0, gdouble y0,gdouble x1, gdouble y1, gdouble x2, gdouble y2) 
void
gnome_canvas_path_def_curveto (path, x0, y0, x1, y1, x2, y2)
	GnomeCanvasPathDef * path
	gdouble x0
	gdouble y0
	gdouble x1
	gdouble y1
	gdouble x2
	gdouble y2

##  void gnome_canvas_path_def_closepath (GnomeCanvasPathDef * path) 
void
gnome_canvas_path_def_closepath (path)
	GnomeCanvasPathDef * path

##  void gnome_canvas_path_def_closepath_current (GnomeCanvasPathDef * path) 
void
gnome_canvas_path_def_closepath_current (path)
	GnomeCanvasPathDef * path

####  ArtBpath * gnome_canvas_path_def_bpath (const GnomeCanvasPathDef * path) 
##ArtBpath *
##gnome_canvas_path_def_bpath (path)
##	const GnomeCanvasPathDef * path

##  gint gnome_canvas_path_def_length (const GnomeCanvasPathDef * path) 
gint
gnome_canvas_path_def_length (path)
	GnomeCanvasPathDef * path

##  gboolean gnome_canvas_path_def_is_empty (const GnomeCanvasPathDef * path) 
gboolean
gnome_canvas_path_def_is_empty (path)
	GnomeCanvasPathDef * path

##  gboolean gnome_canvas_path_def_has_currentpoint (const GnomeCanvasPathDef * path) 
gboolean
gnome_canvas_path_def_has_currentpoint (path)
	GnomeCanvasPathDef * path

####  void gnome_canvas_path_def_currentpoint (const GnomeCanvasPathDef * path, ArtPoint * p) 
##void
##gnome_canvas_path_def_currentpoint (path, p)
##	const GnomeCanvasPathDef * path
##	ArtPoint * p
##
####  ArtBpath * gnome_canvas_path_def_last_bpath (const GnomeCanvasPathDef * path) 
##ArtBpath *
##gnome_canvas_path_def_last_bpath (path)
##	const GnomeCanvasPathDef * path
##
####  ArtBpath * gnome_canvas_path_def_first_bpath (const GnomeCanvasPathDef * path) 
##ArtBpath *
##gnome_canvas_path_def_first_bpath (path)
##	const GnomeCanvasPathDef * path

##  gboolean gnome_canvas_path_def_any_open (const GnomeCanvasPathDef * path) 
gboolean
gnome_canvas_path_def_any_open (path)
	GnomeCanvasPathDef * path

##  gboolean gnome_canvas_path_def_all_open (const GnomeCanvasPathDef * path) 
gboolean
gnome_canvas_path_def_all_open (path)
	GnomeCanvasPathDef * path

##  gboolean gnome_canvas_path_def_any_closed (const GnomeCanvasPathDef * path) 
gboolean
gnome_canvas_path_def_any_closed (path)
	GnomeCanvasPathDef * path

##  gboolean gnome_canvas_path_def_all_closed (const GnomeCanvasPathDef * path) 
gboolean
gnome_canvas_path_def_all_closed (path)
	GnomeCanvasPathDef * path

### will not be bound
####  void gnome_canvas_path_def_ref (GnomeCanvasPathDef * path) 
####  void gnome_canvas_path_def_unref (GnomeCanvasPathDef * path) 
