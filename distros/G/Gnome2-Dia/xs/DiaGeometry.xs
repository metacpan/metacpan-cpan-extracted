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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaGeometry.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

/* ------------------------------------------------------------------------- */

SV *
newSVDiaRectangle (DiaRectangle *rectangle)
{
	AV *av;

	if (!rectangle)
		return &PL_sv_undef;

	av = newAV ();

	av_push (av, newSVnv (rectangle->left));
	av_push (av, newSVnv (rectangle->top));
	av_push (av, newSVnv (rectangle->right));
	av_push (av, newSVnv (rectangle->bottom));

	return newRV_noinc ((SV *) av);
}

DiaRectangle *
SvDiaRectangle (SV *sv)
{
	AV *av;
	SV **value;
	DiaRectangle *rectangle;

	if (! (sv && SvOK (sv) && SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVAV))
		croak ("DiaRectangles have to be array references with four elements: "
		       "left, top, right, bottom");

	av = (AV *) SvRV (sv);
	rectangle = gperl_alloc_temp (sizeof (DiaRectangle));

	value = av_fetch (av, 0, 0);
	if (value && SvOK (*value))
		rectangle->left = SvNV (*value);

	value = av_fetch (av, 1, 0);
	if (value && SvOK (*value))
		rectangle->top = SvNV (*value);

	value = av_fetch (av, 2, 0);
	if (value && SvOK (*value))
		rectangle->right = SvNV (*value);

	value = av_fetch (av, 3, 0);
	if (value && SvOK (*value))
		rectangle->bottom = SvNV (*value);

	return rectangle;
}

/* ------------------------------------------------------------------------- */

SV *
newSVDiaPoint (DiaPoint *point)
{
	AV *av;

	if (!point)
		return &PL_sv_undef;

	av = newAV ();

	av_push (av, newSVnv (point->x));
	av_push (av, newSVnv (point->y));

	return newRV_noinc ((SV *) av);
}

DiaPoint *
SvDiaPoint (SV *sv)
{
	AV *av;
	SV **value;
	DiaPoint *point;

	if (! (sv && SvOK (sv) && SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVAV))
		croak ("DiaPoints have to be array references with two elements: "
		       "x, y");

	av = (AV *) SvRV (sv);
	point = gperl_alloc_temp (sizeof (DiaPoint));

	value = av_fetch (av, 0, 0);
	if (value && SvOK (*value))
		point->x = SvNV (*value);

	value = av_fetch (av, 1, 0);
	if (value && SvOK (*value))
		point->y = SvNV (*value);

	return point;
}

/* ------------------------------------------------------------------------- */

SV *
newSVDiaAffine (gdouble affine[6])
{
	AV *av;

	if (!affine)
		return &PL_sv_undef;

	av = newAV ();

	av_push (av, newSVnv (affine[0]));
	av_push (av, newSVnv (affine[1]));
	av_push (av, newSVnv (affine[2]));
	av_push (av, newSVnv (affine[3]));
	av_push (av, newSVnv (affine[4]));
	av_push (av, newSVnv (affine[5]));

	return newRV_noinc ((SV *) av);
}

gdouble *
SvDiaAffine (SV *sv)
{
	AV *av;
	gdouble *affine;

	if (! (sv && SvOK (sv) && SvRV (sv) && SvTYPE (SvRV(sv)) == SVt_PVAV &&
	       5 == av_len ((AV *) SvRV (sv))))
		croak ("affine transformations must be expressed as a "
		       "reference to an array containing the six transform "
		       "values");

	av = (AV *) SvRV (sv);

	affine = gperl_alloc_temp (6 * sizeof (gdouble));
	affine[0] = SvNV (*av_fetch (av, 0, 0));
	affine[1] = SvNV (*av_fetch (av, 1, 0));
	affine[2] = SvNV (*av_fetch (av, 2, 0));
	affine[3] = SvNV (*av_fetch (av, 3, 0));
	affine[4] = SvNV (*av_fetch (av, 4, 0));
	affine[5] = SvNV (*av_fetch (av, 5, 0));

	return affine;
}

/* ------------------------------------------------------------------------- */

SV *
newSVDiaColor (DiaColor color)
{
	return newSVuv (color);
}

DiaColor
SvDiaColor (SV *sv)
{
	return SvUV (sv);
}

/* ------------------------------------------------------------------------- */

static GPerlBoxedWrapperClass dia_point_wrapper_class;
static GPerlBoxedWrapperClass dia_rectangle_wrapper_class;

static SV *
dia_point_wrap (GType type,
                const char *package,
                gpointer point,
                gboolean own)
{
	return newSVDiaPoint (point);
}

static gpointer
dia_point_unwrap (GType type,
                  const char *package,
                  SV *sv)
{
	return SvDiaPoint (sv);
}

static SV *
dia_rectangle_wrap (GType type,
                    const char *package,
                    gpointer rectangle,
		    gboolean own)
{
	return newSVDiaRectangle (rectangle);
}

static gpointer
dia_rectangle_unwrap (GType type,
                      const char *package,
                      SV *sv)
{
	return SvDiaRectangle (sv);
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Dia::Geometry	PACKAGE = Gnome2::Dia::Geometry

BOOT:
{
	dia_point_wrapper_class.wrap = (GPerlBoxedWrapFunc) dia_point_wrap;
	dia_point_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc) dia_point_unwrap;
	dia_point_wrapper_class.destroy = NULL;

	dia_rectangle_wrapper_class.wrap = (GPerlBoxedWrapFunc) dia_rectangle_wrap;
	dia_rectangle_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc) dia_rectangle_unwrap;
	dia_rectangle_wrapper_class.destroy = NULL;

	gperl_register_boxed (DIA_TYPE_POINT, "Gnome2::Dia::Point", &dia_point_wrapper_class);
	gperl_register_boxed (DIA_TYPE_RECTANGLE, "Gnome2::Dia::Point", &dia_rectangle_wrapper_class);
}
