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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/GnomeCanvas/xs/GnomeCanvasItem.xs,v 1.8 2004/08/16 02:10:26 muppetman Exp $
 */
#include "gnomecanvasperl.h"

MODULE = Gnome2::Canvas::Item	PACKAGE = Gnome2::Canvas::Item	PREFIX = gnome_canvas_item_

=for apidoc parent
=for signature $canvasgroup = $item->parent
Fetch I<$item>'s parent group item.
=cut

=for apidoc
=for signature $canvas = $item->canvas
Fetch the Gnome2::Canvas to which I<$item> is attached.
=cut
SV *
canvas (item)
	GnomeCanvasItem * item
    ALIAS:
	parent = 1
    CODE:
	RETVAL = NULL;
	switch (ix) {
	    case 0: RETVAL = newSVGnomeCanvas (item->canvas); break;
	    case 1: RETVAL = newSVGnomeCanvasGroup_ornull (item->parent); break;
	}
    OUTPUT:
	RETVAL


##  GnomeCanvasItem *gnome_canvas_item_new (GnomeCanvasGroup *parent, GType type, const gchar *first_arg_name, ...) 
=for apidoc
=for arg ... property name => value pairs
Factory constructor for Gnome2::Canvas::Item subclasses.
=cut
GnomeCanvasItem *
gnome_canvas_item_new (class, parent, object_class, ...)
	GnomeCanvasGroup *parent
	const char * object_class
    PREINIT:
	GValue value = {0, };
	GType gtype;
	int i;
    CODE:
	if (0 != ((items - 3) % 2))
		croak ("expected name => value pairs to follow object class;"
		       "odd number of arguments detected");
	gtype = gperl_object_type_from_package (object_class);
	if (!gtype)
		croak ("%s is not registered with gperl as an object type",
		       object_class);
	RETVAL = gnome_canvas_item_new (parent, gtype, NULL);
	for (i = 3; i < items ; i+=2) {
		const char * name = SvPV_nolen (ST (i));
		SV * newval = ST (i + 1);
		GParamSpec * pspec;
		pspec = g_object_class_find_property 
					(G_OBJECT_GET_CLASS (RETVAL), name);
		if (!pspec)
			croak ("property %s not found in object class %s",
			       name, g_type_name (gtype));
		g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
		gperl_value_from_sv (&value, newval);
		g_object_set_property (G_OBJECT (RETVAL), name, &value);
		g_value_unset (&value);
	}
    OUTPUT:
	RETVAL

 ## use g_object_set instead
##  void gnome_canvas_item_set (GnomeCanvasItem *item, const gchar *first_arg_name, ...) 
##  void gnome_canvas_item_set_valist (GnomeCanvasItem *item, const gchar *first_arg_name, va_list args) 

##  void gnome_canvas_item_move (GnomeCanvasItem *item, double dx, double dy) 
void
gnome_canvas_item_move (item, dx, dy)
	GnomeCanvasItem *item
	double dx
	double dy

##  void gnome_canvas_item_affine_relative (GnomeCanvasItem *item, const double affine[6]) 
=for apidoc
=for arg affine (arrayref) affine transformation matrix
Combines I<$affine> with I<$item>'s current transformation.
=cut
void
gnome_canvas_item_affine_relative (item, affine)
	GnomeCanvasItem *item
	SV * affine
    C_ARGS:
	item, SvArtAffine (affine)

##  void gnome_canvas_item_affine_absolute (GnomeCanvasItem *item, const double affine[6]) 
=for apidoc
=for arg affine (arrayref) affine transformation matrix
Replaces I<$item>'s transformation matrix.
=cut
void
gnome_canvas_item_affine_absolute (item, affine)
	GnomeCanvasItem *item
	SV * affine
    C_ARGS:
	item, SvArtAffine (affine)

##  void gnome_canvas_item_raise (GnomeCanvasItem *item, int positions) 
void
gnome_canvas_item_raise (item, positions)
	GnomeCanvasItem *item
	int positions

##  void gnome_canvas_item_lower (GnomeCanvasItem *item, int positions) 
void
gnome_canvas_item_lower (item, positions)
	GnomeCanvasItem *item
	int positions

##  void gnome_canvas_item_raise_to_top (GnomeCanvasItem *item) 
void
gnome_canvas_item_raise_to_top (item)
	GnomeCanvasItem *item

##  void gnome_canvas_item_lower_to_bottom (GnomeCanvasItem *item) 
void
gnome_canvas_item_lower_to_bottom (item)
	GnomeCanvasItem *item

##  void gnome_canvas_item_show (GnomeCanvasItem *item) 
void
gnome_canvas_item_show (item)
	GnomeCanvasItem *item

##  void gnome_canvas_item_hide (GnomeCanvasItem *item) 
void
gnome_canvas_item_hide (item)
	GnomeCanvasItem *item

##  int gnome_canvas_item_grab (GnomeCanvasItem *item, unsigned int event_mask, GdkCursor *cursor, guint32 etime) 
GdkGrabStatus
gnome_canvas_item_grab (item, event_mask, cursor, etime=GDK_CURRENT_TIME)
	GnomeCanvasItem *item
	GdkEventMask event_mask
	GdkCursor *cursor
	guint32 etime

##  void gnome_canvas_item_ungrab (GnomeCanvasItem *item, guint32 etime) 
void
gnome_canvas_item_ungrab (item, etime=GDK_CURRENT_TIME)
	GnomeCanvasItem *item
	guint32 etime

##  void gnome_canvas_item_w2i (GnomeCanvasItem *item, double *x, double *y) 
void gnome_canvas_item_w2i (GnomeCanvasItem * item, IN_OUTLIST double x, IN_OUTLIST double y)

##  void gnome_canvas_item_i2w (GnomeCanvasItem *item, double *x, double *y) 
void gnome_canvas_item_i2w (GnomeCanvasItem *item, IN_OUTLIST double x, IN_OUTLIST double y) 

##  void gnome_canvas_item_i2w_affine (GnomeCanvasItem *item, double affine[6]) 
##  void gnome_canvas_item_i2c_affine (GnomeCanvasItem *item, double affine[6]) 
=for apidoc i2c_affine
=for signature $affine = $item->i2c_affine
=for arg a (__hide__)
Fetch the affine transform that converts from item-relative coordinates to
canvas pixel coordinates.

Note: This method was completely broken for all
$Gnome2::Canvas::VERSION < 1.002.
=cut

=for apidoc
=for signature $affine = $item->i2w_affine
=for arg a (__hide__)
Fetch the affine transform that converts from item's coordinate system to
world coordinates.

Note: This method was completely broken for all
$Gnome2::Canvas::VERSION < 1.002.
=cut
SV *
gnome_canvas_item_i2w_affine (item, a=NULL)
	GnomeCanvasItem *item
	SV * a
    ALIAS:
	i2c_affine = 1
    PREINIT:
	double affine[6];
    CODE:
	if (a != NULL || items > 1)
		warn ("Gnome2::Canvas::%s() was broken before 1.002;"
		      " the second parameter does nothing (see the Gnome2::"
		      "Canvas manpage)",
		      ix == 0 ? "i2w_affine" : "i2c_affine");
	if (ix == 1)
		gnome_canvas_item_i2c_affine (item, affine);
	else
		gnome_canvas_item_i2w_affine (item, affine);
	RETVAL = newSVArtAffine (affine);
    OUTPUT:
	RETVAL


##  void gnome_canvas_item_reparent (GnomeCanvasItem *item, GnomeCanvasGroup *new_group) 
void
gnome_canvas_item_reparent (item, new_group)
	GnomeCanvasItem *item
	GnomeCanvasGroup *new_group

##  void gnome_canvas_item_grab_focus (GnomeCanvasItem *item) 
void
gnome_canvas_item_grab_focus (item)
	GnomeCanvasItem *item

##  void gnome_canvas_item_get_bounds (GnomeCanvasItem *item, double *x1, double *y1, double *x2, double *y2) 
void gnome_canvas_item_get_bounds (GnomeCanvasItem *item, OUTLIST double x1, OUTLIST double y1, OUTLIST double x2, OUTLIST double y2) 

##  void gnome_canvas_item_request_update (GnomeCanvasItem *item) 
void
gnome_canvas_item_request_update (item)
	GnomeCanvasItem *item

