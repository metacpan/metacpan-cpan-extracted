/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"

/* ------------------------------------------------------------------------- */

SV *
newSVGdkGeometry (GdkGeometry *geometry)
{
	HV *object = newHV ();

	if (geometry) {
		gperl_hv_take_sv_s (object, "min_width", newSViv (geometry->min_width));
		gperl_hv_take_sv_s (object, "min_height", newSViv (geometry->min_height));
		gperl_hv_take_sv_s (object, "max_width", newSViv (geometry->max_width));
		gperl_hv_take_sv_s (object, "max_height", newSViv (geometry->max_height));
		gperl_hv_take_sv_s (object, "base_width", newSViv (geometry->base_width));
		gperl_hv_take_sv_s (object, "base_height", newSViv (geometry->base_height));
		gperl_hv_take_sv_s (object, "width_inc", newSViv (geometry->width_inc));
		gperl_hv_take_sv_s (object, "height_inc", newSViv (geometry->height_inc));
		gperl_hv_take_sv_s (object, "min_aspect", newSVnv (geometry->min_aspect));
		gperl_hv_take_sv_s (object, "max_aspect", newSVnv (geometry->max_aspect));
		gperl_hv_take_sv_s (object, "win_gravity", newSVGdkGravity (geometry->win_gravity));
	}

	return sv_bless (newRV_noinc ((SV *) object),
	                 gv_stashpv ("Gtk2::Gdk::Geometry", 1));
}

#define GTK2PERL_GEOMETRY_FETCH(member, key, type) \
	member = hv_fetch (hv, key, strlen (key), FALSE); \
	if (member) geometry->member = type (*member);

GdkGeometry *
SvGdkGeometryReal (SV *object, GdkWindowHints *hints)
{
	HV *hv = (HV *) SvRV (object);
	SV **min_width, **min_height, **max_width, **max_height, **base_width,
	   **base_height, **width_inc, **height_inc, **min_aspect, **max_aspect,
	   **win_gravity;

	GdkGeometry *geometry = gperl_alloc_temp (sizeof (GdkGeometry));
	if (hints)
		*hints = 0;

	if (gperl_sv_is_hash_ref (object)) {
		GTK2PERL_GEOMETRY_FETCH (min_width, "min_width", SvIV);
		GTK2PERL_GEOMETRY_FETCH (min_height, "min_height", SvIV);
		GTK2PERL_GEOMETRY_FETCH (max_width, "max_width", SvIV);
		GTK2PERL_GEOMETRY_FETCH (max_height, "max_height", SvIV);
		GTK2PERL_GEOMETRY_FETCH (base_width, "base_width", SvIV);
		GTK2PERL_GEOMETRY_FETCH (base_height, "base_height", SvIV);
		GTK2PERL_GEOMETRY_FETCH (width_inc, "width_inc", SvIV);
		GTK2PERL_GEOMETRY_FETCH (height_inc, "height_inc", SvIV);
		GTK2PERL_GEOMETRY_FETCH (min_aspect, "min_aspect", SvNV);
		GTK2PERL_GEOMETRY_FETCH (max_aspect, "max_aspect", SvNV);
		GTK2PERL_GEOMETRY_FETCH (win_gravity, "win_gravity", SvGdkGravity);

		if (hints) {
			if (min_width && min_height)
				*hints |= GDK_HINT_MIN_SIZE;

			if (max_width && max_height)
				*hints |= GDK_HINT_MAX_SIZE;

			if (base_width && base_height)
				*hints |= GDK_HINT_BASE_SIZE;

			if (min_aspect && max_aspect)
				*hints |= GDK_HINT_ASPECT;

			if (width_inc && height_inc)
				*hints |= GDK_HINT_RESIZE_INC;

			if (win_gravity)
				*hints |= GDK_HINT_WIN_GRAVITY;
		}
	}

	return geometry;
}

GdkGeometry *
SvGdkGeometry (SV *object)
{
	return SvGdkGeometryReal (object, NULL);
}

/* ------------------------------------------------------------------------- */

SV *
newSVGdkAtom (GdkAtom atom)
{
	SV * sv = newSV(0);
	sv_setref_pv (sv, "Gtk2::Gdk::Atom", (void*)atom);
	return sv;
}

GdkAtom
SvGdkAtom (SV * sv)
{
	if (!gperl_sv_is_defined (sv))
		return (GdkAtom)NULL;
	else if (sv_derived_from (sv, "Gtk2::Gdk::Atom"))
                return INT2PTR (GdkAtom, SvIV ((SV*)SvRV (sv)));
        else
                croak ("variable is not of type Gtk2::Gdk::Atom");
	return (GdkAtom)NULL; /* not reached */
}

MODULE = Gtk2::Gdk::Types	PACKAGE = Gtk2::Gdk::Rectangle

GdkRectangle_copy *
new (class, x, y, width, height)
	gint x
	gint y
	gint width
	gint height
    PREINIT:
	GdkRectangle rect;
    CODE:
	rect.x = x;
	rect.y = y;
	rect.width = width;
	rect.height = height;
	RETVAL = &rect;
    OUTPUT:
	RETVAL

=for apidoc Gtk2::Gdk::Rectangle::x
=for signature integer = $rectangle->x
=for signature oldvalue = $rectangle->x ($newvalue)
=for arg newvalue (integer)
=cut

=for apidoc y
=for signature integer = $rectangle->y
=for signature oldvalue = $rectangle->y ($newvalue)
=for arg newvalue (integer)
=cut

=for apidoc width
=for signature integer = $rectangle->width
=for signature oldvalue = $rectangle->width ($newvalue)
=for arg newvalue (integer)
=cut

=for apidoc height
=for signature integer = $rectangle->height
=for signature oldvalue = $rectangle->height ($newvalue)
=for arg newvalue (integer)
=cut

gint
x (GdkRectangle *rectangle, SV *newvalue = 0)
    ALIAS:
	y = 1
	width = 2
	height = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = rectangle->x; break;
		case 1: RETVAL = rectangle->y; break;
		case 2: RETVAL = rectangle->width; break;
		case 3: RETVAL = rectangle->height; break;
		default:
			RETVAL = 0;
			g_assert_not_reached ();
	}
        if (newvalue) {
                switch (ix) {
                        case 0: rectangle->x      = SvIV (newvalue); break;
                        case 1: rectangle->y      = SvIV (newvalue); break;
                        case 2: rectangle->width  = SvIV (newvalue); break;
                        case 3: rectangle->height = SvIV (newvalue); break;
			default:
				g_assert_not_reached ();
                }
        }
    OUTPUT:
	RETVAL

=for apidoc
=for signature (x, y, width, height) = $rectangle->values
=cut
void
values (rectangle)
	GdkRectangle * rectangle
    PPCODE:
	EXTEND (SP, 4);
	PUSHs (sv_2mortal (newSViv (rectangle->x)));
	PUSHs (sv_2mortal (newSViv (rectangle->y)));
	PUSHs (sv_2mortal (newSViv (rectangle->width)));
	PUSHs (sv_2mortal (newSViv (rectangle->height)));

MODULE = Gtk2::Gdk::Types	PACKAGE = Gtk2::Gdk::Geometry

GdkGeometry *
new (class)
    PREINIT:
	GdkGeometry geometry;
    CODE:
	memset (&geometry, 0, sizeof (GdkGeometry));
	geometry.win_gravity = GDK_GRAVITY_NORTH_WEST;
	RETVAL = &geometry;
    OUTPUT:
	RETVAL

SV *
min_width (SV *object, SV *newvalue=NULL)
    ALIAS:
        min_height = 1
        max_width = 2
        max_height = 3
        base_width = 4
        base_height = 5
        width_inc = 6
        height_inc = 7
	min_aspect = 8
	max_aspect = 9
	win_gravity = 10
	gravity = 11
    PREINIT:
	SV **value = NULL;
	HV *geometry;
    CODE:
	geometry = (HV *) SvRV (object);
	RETVAL = &PL_sv_undef;

	switch (ix) {
		case 0: value = hv_fetch (geometry, "min_width", 9, 0); break;
		case 1: value = hv_fetch (geometry, "min_height", 10, 0); break;
		case 2: value = hv_fetch (geometry, "max_width", 9, 0); break;
		case 3: value = hv_fetch (geometry, "max_height", 10, 0); break;
		case 4: value = hv_fetch (geometry, "base_width", 10, 0); break;
		case 5: value = hv_fetch (geometry, "base_height", 11, 0); break;
		case 6: value = hv_fetch (geometry, "width_inc", 9, 0); break;
		case 7: value = hv_fetch (geometry, "height_inc", 10, 0); break;
		case 8: value = hv_fetch (geometry, "min_aspect", 10, 0); break;
		case 9: value = hv_fetch (geometry, "max_aspect", 10, 0); break;
		case 10: /* fall-through */
		case 11: value = hv_fetch (geometry, "win_gravity", 11, 0); break;
		default:
			g_assert_not_reached ();
	}

	if (value && gperl_sv_is_defined (*value))
		RETVAL = newSVsv (*value);

	if (items > 1) {
		newvalue = newSVsv (newvalue);

		switch (ix) {
			case 0: gperl_hv_take_sv_s (geometry, "min_width", newvalue); break;
			case 1: gperl_hv_take_sv_s (geometry, "min_height", newvalue); break;
			case 2: gperl_hv_take_sv_s (geometry, "max_width", newvalue); break;
			case 3: gperl_hv_take_sv_s (geometry, "max_height", newvalue); break;
			case 4: gperl_hv_take_sv_s (geometry, "base_width", newvalue); break;
			case 5: gperl_hv_take_sv_s (geometry, "base_height", newvalue); break;
			case 6: gperl_hv_take_sv_s (geometry, "width_inc", newvalue); break;
			case 7: gperl_hv_take_sv_s (geometry, "height_inc", newvalue); break;
			case 8: gperl_hv_take_sv_s (geometry, "min_aspect", newvalue); break;
			case 9: gperl_hv_take_sv_s (geometry, "max_aspect", newvalue); break;
			case 10: /* fall-through */
			case 11: gperl_hv_take_sv_s (geometry, "win_gravity", newvalue); break;
			default:
				g_assert_not_reached ();
		}
	}
    OUTPUT:
	RETVAL

## moved here because it makes plain sense
=for apidoc

=for signature (new_width, new_height) = $geometry->constrain_size ($width, $height)
=for signature (new_width, new_height) = $geometry->constrain_size ($flags, $width, $height)

=for arg flags (Gtk2::Gdk::WindowHints) optional, usually inferred from I<$geometry>

The $flags argument, describing which fields in the geometry are valid, is
optional.  If omitted it will be inferred from the geometry itself.

=cut
## void gdk_window_constrain_size (GdkGeometry *geometry, guint flags, gint width, gint height, gint *new_width, gint *new_height)
void
constrain_size (geometry_ref, ...)
	SV *geometry_ref
    PREINIT:
	GdkGeometry *geometry;
	GdkWindowHints flags;
	gint width;
	gint height;
	gint new_width;
	gint new_height;
    PPCODE:
	if (items == 4) {
		if (!gperl_sv_is_defined (ST (1)))
			warn ("Warning: You passed undef for the flags parameter.  Consider simply omitting it instead.");

		geometry = SvGdkGeometry (geometry_ref);
		flags = SvGdkWindowHints (ST (1));
		width = SvIV (ST (2));
		height = SvIV (ST (3));
	} else if (items == 3) {
		geometry = SvGdkGeometryReal (geometry_ref, &flags);
		width = SvIV (ST (1));
		height = SvIV (ST (2));
	} else {
		croak ("Usage: Gtk2::Gdk::Geometry::constrain_size(geometry, width, height) or Gtk2::Gdk::Geometry::constrain_size(geometry, flags, width, height)");
	}

	gdk_window_constrain_size (geometry, flags, width, height, &new_width, &new_height);
	EXTEND (SP, 2);
	PUSHs (sv_2mortal (newSViv (new_width)));
	PUSHs (sv_2mortal (newSViv (new_height)));

