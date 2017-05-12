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
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaCanvasItem.xs,v 1.3 2004/09/26 12:05:57 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

/* ------------------------------------------------------------------------- */

static SV *
newSVDiaCanvasItemHandles (GList *handles)
{
	AV *av;
	GList *i;

	if (!handles)
		return &PL_sv_undef;

	av = newAV ();

	for (i = handles; i != NULL; i = i->next)
		av_push (av, newSVDiaHandle (i->data));

	return newRV_noinc ((SV *) av);
}

static GList *
SvDiaCanvasItemHandles (SV *sv)
{
	AV *av;
	int i;
	GList *handles = NULL;

	if (! (sv && SvOK (sv) && SvRV (sv) && SvTYPE (SvRV(sv)) == SVt_PVAV))
		croak ("handle lists have to be array references");

	av = (AV *) SvRV (sv);

	for (i = 0; i <= av_len (av); i++) {
		SV **handle = av_fetch (av, i, 0);
		if (handle && SvOK (*handle))
			handles = g_list_append (handles,
			                         SvDiaHandle (*handle));
	}

	return handles;
}

/* ------------------------------------------------------------------------- */

static GPerlBoxedWrapperClass dia_affine_wrapper_class;
static GPerlBoxedWrapperClass dia_canvas_item_handles_wrapper_class;

static SV *
dia_affine_wrap (GType type,
                 const char *package,
                 gpointer affine,
		 gboolean own)
{
	return newSVDiaAffine (affine);
}

static gpointer
dia_affine_unwrap (GType type,
                   const char *package,
                   SV *sv)
{
	return SvDiaAffine (sv);
}

static SV *
dia_canvas_item_handles_wrap (GType type,
                              const char *package,
                              gpointer handles,
		              gboolean own)
{
	return newSVDiaCanvasItemHandles (handles);
}

static gpointer
dia_canvas_item_handles_unwrap (GType type,
                                const char *package,
                                SV *sv)
{
	return SvDiaCanvasItemHandles (sv);
}

/* ------------------------------------------------------------------------- */

static void
dia2perl_canvas_item_update (DiaCanvasItem *item,
                             gdouble affine[6])
{
	dSP;

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	EXTEND (SP, 7);
	PUSHs (sv_2mortal (newSVDiaCanvasItem (item)));
	PUSHs (sv_2mortal (newSVDiaAffine (affine)));

	PUTBACK;
	call_method ("UPDATE", G_VOID|G_DISCARD);

	FREETMPS;
	LEAVE;
}

static void
dia2perl_canvas_item_class_init (DiaCanvasItemClass *class)
{
	class->update = dia2perl_canvas_item_update;
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Dia::CanvasItem	PACKAGE = Gnome2::Dia::CanvasItem	PREFIX = dia_canvas_item_

BOOT:
{
	dia_affine_wrapper_class.wrap = (GPerlBoxedWrapFunc) dia_affine_wrap;
	dia_affine_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc) dia_affine_unwrap;
	dia_affine_wrapper_class.destroy = NULL;

	dia_canvas_item_handles_wrapper_class.wrap = (GPerlBoxedWrapFunc) dia_canvas_item_handles_wrap;
	dia_canvas_item_handles_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc) dia_canvas_item_handles_unwrap;
	dia_canvas_item_handles_wrapper_class.destroy = NULL;

	gperl_register_boxed (DIA_TYPE_AFFINE, "Gnome2::Dia::Affine", &dia_affine_wrapper_class);
	gperl_register_boxed (DIA_TYPE_CANVAS_ITEM_HANDLES, "Gnome2::Dia::CanvasItemHandles", &dia_canvas_item_handles_wrapper_class);
}

##  Dummies for types that don't have a module.
=for object Gnome2::Dia::CanvasImage
=cut

=for object Gnome2::Dia::CanvasText
=cut

=for object Gnome2::Dia::Selector
=cut

##  Back to DiaCanvasItem.
=for object Gnome2::Dia::CanvasItem
=cut

##  Accessors.
DiaCanvasItemFlags
flags (item)
	DiaCanvasItem *item
    CODE:
	RETVAL = item->flags;
    OUTPUT:
	RETVAL

DiaCanvas *
canvas (item)
	DiaCanvasItem *item
    CODE:
	RETVAL = item->canvas;
    OUTPUT:
	RETVAL

DiaRectangle *
bounds (item)
	DiaCanvasItem *item
    CODE:
	RETVAL = &item->bounds;
    OUTPUT:
	RETVAL

void
connected_handles (item)
	DiaCanvasItem *item
    PREINIT:
	GList *i;
    PPCODE:
	for (i = item->connected_handles; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVDiaHandle (i->data)));

##  DiaCanvasItem* dia_canvas_item_create (GType type, const gchar *first_arg_name, ...)
DiaCanvasItem_noinc *
dia_canvas_item_create (class, type, ...)
	const char *type
    PREINIT:
	GType real_type;
	int i;
    CODE:
	if (((items - 2) % 2) != 0)
		croak ("expected name => value pairs to follow object class; "
		       "odd number of arguments detected");

	real_type = gperl_object_type_from_package (type);
	if (!real_type)
		croak ("%s is not registered with Perl as an object type",
		       type);

	RETVAL = dia_canvas_item_create (real_type, NULL);

	for (i = 2; i < items ; i += 2) {
		const char *name = SvPV_nolen (ST (i));
		SV *new_value = ST (i + 1);
		GParamSpec *pspec;
		GValue value = {0, };

		pspec = g_object_class_find_property (
		          G_OBJECT_GET_CLASS (RETVAL), name);
		if (!pspec)
			croak ("property %s not found in object class %s",
			       name, g_type_name (real_type));

		g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
		gperl_value_from_sv (&value, new_value);
		g_object_set_property (G_OBJECT (RETVAL), name, &value);
		g_value_unset (&value);
	}
    OUTPUT:
	RETVAL

##  void dia_canvas_item_set_parent (DiaCanvasItem *item, DiaCanvasItem *new_parent)
void
dia_canvas_item_set_parent (item, new_parent)
	DiaCanvasItem *item
	DiaCanvasItem_ornull *new_parent

##  void dia_canvas_item_request_update (DiaCanvasItem *item)
void
dia_canvas_item_request_update (item)
	DiaCanvasItem *item

##  void dia_canvas_item_update_now (DiaCanvasItem *item)
void
dia_canvas_item_update_now (item)
	DiaCanvasItem *item

##  void dia_canvas_item_update_child (DiaCanvasItem *item, DiaCanvasItem *child, gdouble affine[6])
void
dia_canvas_item_update_child (item, child, affine)
	DiaCanvasItem *item
	DiaCanvasItem *child
	SV *affine
    C_ARGS:
	item, child, SvDiaAffine (affine)

##  void dia_canvas_item_affine_w2i (DiaCanvasItem *item, gdouble affine[6])
SV *
dia_canvas_item_affine_w2i (item)
	DiaCanvasItem *item
    PREINIT:
	gdouble affine[6] = {0,};
    CODE:
	dia_canvas_item_affine_w2i (item, affine);
	RETVAL = newSVDiaAffine (affine);
    OUTPUT:
	RETVAL

##  void dia_canvas_item_affine_i2w (DiaCanvasItem *item, gdouble affine[6])
SV *
dia_canvas_item_affine_i2w (item)
	DiaCanvasItem *item
    PREINIT:
	gdouble affine[6] = {0,};
    CODE:
	dia_canvas_item_affine_i2w (item, affine);
	RETVAL = newSVDiaAffine (affine);
    OUTPUT:
	RETVAL

##  void dia_canvas_item_affine_point_w2i (DiaCanvasItem *item, gdouble *x, gdouble *y)
void dia_canvas_item_affine_point_w2i (DiaCanvasItem *item, IN_OUTLIST gdouble x, IN_OUTLIST gdouble y)

##  void dia_canvas_item_affine_point_i2w (DiaCanvasItem *item, gdouble *x, gdouble *y)
void dia_canvas_item_affine_point_i2w (DiaCanvasItem *item, IN_OUTLIST gdouble x, IN_OUTLIST gdouble y)

##  void dia_canvas_item_update_handles_i2w (DiaCanvasItem *item)
void
dia_canvas_item_update_handles_i2w (item)
	DiaCanvasItem *item

##  void dia_canvas_item_update_handles_w2i (DiaCanvasItem *item)
void
dia_canvas_item_update_handles_w2i (item)
	DiaCanvasItem *item

##  gboolean dia_canvas_item_connect (DiaCanvasItem *item, DiaHandle *handle)
gboolean
dia_canvas_item_connect (item, handle)
	DiaCanvasItem *item
	DiaHandle *handle

##  gboolean dia_canvas_item_disconnect (DiaCanvasItem *item, DiaHandle *handle)
gboolean
dia_canvas_item_disconnect (item, handle)
	DiaCanvasItem *item
	DiaHandle *handle

##  gboolean dia_canvas_item_disconnect_handles (DiaCanvasItem *item)
gboolean
dia_canvas_item_disconnect_handles (item)
	DiaCanvasItem *item

##  void dia_canvas_item_select (DiaCanvasItem *item)
void
dia_canvas_item_select (item)
	DiaCanvasItem *item

##  void dia_canvas_item_unselect (DiaCanvasItem *item)
void
dia_canvas_item_unselect (item)
	DiaCanvasItem *item

##  gboolean dia_canvas_item_is_selected (DiaCanvasItem *item)
gboolean
dia_canvas_item_is_selected (item)
	DiaCanvasItem *item

##  void dia_canvas_item_focus (DiaCanvasItem *item)
void
dia_canvas_item_focus (item)
	DiaCanvasItem *item

##  void dia_canvas_item_unfocus (DiaCanvasItem *item)
void
dia_canvas_item_unfocus (item)
	DiaCanvasItem *item

##  gboolean dia_canvas_item_is_focused (DiaCanvasItem *item)
gboolean
dia_canvas_item_is_focused (item)
	DiaCanvasItem *item

##  void dia_canvas_item_grab (DiaCanvasItem *item)
void
dia_canvas_item_grab (item)
	DiaCanvasItem *item

##  void dia_canvas_item_ungrab (DiaCanvasItem *item)
void
dia_canvas_item_ungrab (item)
	DiaCanvasItem *item

##  gboolean dia_canvas_item_is_grabbed (DiaCanvasItem *item)
gboolean
dia_canvas_item_is_grabbed (item)
	DiaCanvasItem *item

##  void dia_canvas_item_visible (DiaCanvasItem *item)
void
dia_canvas_item_visible (item)
	DiaCanvasItem *item

##  void dia_canvas_item_invisible (DiaCanvasItem *item)
void
dia_canvas_item_invisible (item)
	DiaCanvasItem *item

##  gboolean dia_canvas_item_is_visible (DiaCanvasItem *item)
gboolean
dia_canvas_item_is_visible (item)
	DiaCanvasItem *item

##  void dia_canvas_item_identity (DiaCanvasItem *item)
void
dia_canvas_item_identity (item)
	DiaCanvasItem *item

##  void dia_canvas_item_scale (DiaCanvasItem *item, gdouble sx, gdouble sy)
void
dia_canvas_item_scale (item, sx, sy)
	DiaCanvasItem *item
	gdouble sx
	gdouble sy

##  void dia_canvas_item_rotate (DiaCanvasItem *item, gdouble degrees)
void
dia_canvas_item_rotate (item, degrees)
	DiaCanvasItem *item
	gdouble degrees

##  void dia_canvas_item_shear_x (DiaCanvasItem *item, gdouble dx, gdouble dy)
void
dia_canvas_item_shear_x (item, dx, dy)
	DiaCanvasItem *item
	gdouble dx
	gdouble dy

##  void dia_canvas_item_shear_y (DiaCanvasItem *item, gdouble dx, gdouble dy)
void
dia_canvas_item_shear_y (item, dx, dy)
	DiaCanvasItem *item
	gdouble dx
	gdouble dy

##  void dia_canvas_item_move (DiaCanvasItem *item, gdouble dx, gdouble dy)
void
dia_canvas_item_move (item, dx, dy)
	DiaCanvasItem *item
	gdouble dx
	gdouble dy

##  void dia_canvas_item_flip (DiaCanvasItem *item, gboolean horz, gboolean vert)
void
dia_canvas_item_flip (item, horz, vert)
	DiaCanvasItem *item
	gboolean horz
	gboolean vert

##  void dia_canvas_item_move_interactive (DiaCanvasItem *item, gdouble dx, gdouble dy)
void
dia_canvas_item_move_interactive (item, dx, dy)
	DiaCanvasItem *item
	gdouble dx
	gdouble dy

##  void dia_canvas_item_expand_bounds (DiaCanvasItem *item, gdouble d)
void
dia_canvas_item_expand_bounds (item, d)
	DiaCanvasItem *item
	gdouble d

##  void dia_canvas_item_bb_affine (DiaCanvasItem* item, gdouble affine[6], gdouble *x1, gdouble *y1, gdouble *x2, gdouble *y2)
void
dia_canvas_item_bb_affine (item, affine)
	DiaCanvasItem *item
	SV *affine
    PREINIT:
	gdouble x1;
	gdouble y1;
	gdouble x2;
	gdouble y2;
    PPCODE:
	dia_canvas_item_bb_affine (item, SvDiaAffine (affine), &x1, &y1, &x2, &y2);
	EXTEND (sp, 4);
	PUSHs (sv_2mortal (newSVnv (x1)));
	PUSHs (sv_2mortal (newSVnv (y1)));
	PUSHs (sv_2mortal (newSVnv (x2)));
	PUSHs (sv_2mortal (newSVnv (y2)));

##  gboolean dia_canvas_item_get_shape_iter (DiaCanvasItem *item, DiaCanvasIter *iter)
DiaCanvasIter_copy *
dia_canvas_item_get_shape_iter (item)
	DiaCanvasItem *item
    PREINIT:
	DiaCanvasIter iter;
    CODE:
	if (!dia_canvas_item_get_shape_iter (item, &iter))
		XSRETURN_UNDEF;
	RETVAL = &iter;
    OUTPUT:
	RETVAL

##  gboolean dia_canvas_item_shape_next (DiaCanvasItem *item, DiaCanvasIter *iter)
gboolean
dia_canvas_item_shape_next (item, iter)
	DiaCanvasItem *item
	DiaCanvasIter *iter

##  DiaShape* dia_canvas_item_shape_value (DiaCanvasItem *item, DiaCanvasIter *iter)
DiaShape *
dia_canvas_item_shape_value (item, iter)
	DiaCanvasItem *item
	DiaCanvasIter *iter

##  void dia_canvas_item_preserve_property (DiaCanvasItem *item, const gchar *property_name)
void
dia_canvas_item_preserve_property (item, property_name)
	DiaCanvasItem *item
	const gchar *property_name

##  void dia_canvas_item_set_child_of (DiaCanvasItem *item, DiaCanvasItem *new_parent)
void
dia_canvas_item_set_child_of (item, new_parent)
	DiaCanvasItem *item
	DiaCanvasItem_ornull *new_parent

# --------------------------------------------------------------------------- #

=for apidoc __hide__
=cut
void
_INSTALL_OVERRIDES (const char *package)
    PREINIT:
	GType type;
	DiaCanvasItemClass *class;
    CODE:
	type = gperl_object_type_from_package (package);

	if (!type)
		croak ("package '%s' is not registered with Gtk2-Perl",
		       package);

	if (!g_type_is_a (type, DIA_TYPE_CANVAS_ITEM))
		croak ("%s(%s) is not a DiaCanvasItem",
		       package, g_type_name (type));

	/* peek should suffice, as the bindings should keep this class
	 * alive for us. */
	class = g_type_class_peek (type);

	if (!class)
		croak ("internal problem: can't peek at type class for %s(%d)",
		       g_type_name (type), type);

	dia2perl_canvas_item_class_init (class);

=for apidoc Gnome2::Dia::CanvasItem::UPDATE __hide__
=cut

void
UPDATE (item, ...)
	DiaCanvasItem *item
    ALIAS:
    PREINIT:
	DiaCanvasItemClass *class;
	GType this, parent;
    CODE:
	/* look up his parent */
	this = G_OBJECT_TYPE (item);
	parent = g_type_parent (this);
	if (!g_type_is_a (parent, DIA_TYPE_CANVAS_ITEM))
		croak ("parent of %s is not a DiaCanvasItem",
		       g_type_name (this));

	/* that's our boy.  call one of his functions. */
	class = g_type_class_peek (parent);

	switch (ix) {
	    case 0: /* UPDATE */
		if (class->update)
			class->update (item,
			               SvDiaAffine (ST (1)));
		break;
	    default:
		g_assert_not_reached ();
	}

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::CanvasItem	PACKAGE = Gnome2::Dia::CanvasText	PREFIX = dia_canvas_text_

BOOT:
	gperl_set_isa ("Gnome2::Dia::CanvasText", "Gnome2::Dia::CanvasEditable");

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::CanvasItem	PACKAGE = Gnome2::Dia::CanvasLine	PREFIX = dia_canvas_line_

##  gint dia_canvas_line_get_closest_segment (DiaCanvasLine *line, gdouble x, gdouble y)
gint
dia_canvas_line_get_closest_segment (line, x, y)
	DiaCanvasLine *line
	gdouble x
	gdouble y
