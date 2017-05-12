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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaShape.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

/* ------------------------------------------------------------------------- */

SV *
newSVDiaShape (DiaShape *shape)
{
	return gperl_new_boxed (shape, dia_shape_get_type (shape), FALSE);
}

SV *
newSVDiaShape_own (DiaShape *shape)
{
	return gperl_new_boxed (shape, dia_shape_get_type (shape), TRUE);
}

DiaShape *
SvDiaShape (SV *sv)
{
	return gperl_get_boxed_check (sv,
		gperl_boxed_type_from_package (sv_reftype (SvRV (sv), TRUE)));
}

/* ------------------------------------------------------------------------- */

static SV *
newSVDiaDashStyle (DiaDashStyle *style)
{
	AV *av;
	int i;

	if (!style)
		return &PL_sv_undef;

	av = newAV ();

	for (i = 0; i < style->n_dash; i++)
		av_push (av, newSVnv (style->dash[i]));

	return newRV_noinc ((SV *) av);
}

static DiaDashStyle *
SvDiaDashStyle (SV *sv)
{
	AV *av;
	SV **value;
	DiaDashStyle *style;
	int i, length;

	if (! (sv && SvOK (sv) && SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVAV))
		croak ("DiaDashStyles have to be array references");

	av = (AV *) SvRV (sv);
	length = av_len (av) + 1;

	/* sizeof (DiaDashStyle) already contains memory for one gdouble, hence
	   the - 1. */
	style = gperl_alloc_temp (sizeof (DiaDashStyle) +
	                          sizeof (gdouble) * (length - 1));
	style->n_dash = length;

	for (i = 0; i < style->n_dash; i++) {
		value = av_fetch (av, i, 0);
		if (value && SvOK (*value))
			style->dash[i] = SvNV (*value);
	}

	return style;
}

/* ------------------------------------------------------------------------- */

static GPerlBoxedWrapperClass dia_dash_style_wrapper_class;

static SV *
dia_dash_style_wrap (GType type,
                     const char *package,
                     gpointer point,
                     gboolean own)
{
	return newSVDiaDashStyle (point);
}

static gpointer
dia_dash_style_unwrap (GType type,
                       const char *package,
                       SV *sv)
{
	return SvDiaDashStyle (sv);
}

/* ------------------------------------------------------------------------- */

MODULE = Gnome2::Dia::Shape	PACKAGE = Gnome2::Dia::Shape	PREFIX = dia_shape_

BOOT:
{
	dia_dash_style_wrapper_class.wrap = (GPerlBoxedWrapFunc) dia_dash_style_wrap;
	dia_dash_style_wrapper_class.unwrap = (GPerlBoxedUnwrapFunc) dia_dash_style_unwrap;
	dia_dash_style_wrapper_class.destroy = NULL;

	gperl_register_boxed (DIA_TYPE_DASH_STYLE, "Gnome2::Dia::DashStyle", &dia_dash_style_wrapper_class);
}

##  DiaShape* dia_shape_new (DiaShapeType type)
DiaShape_own *
dia_shape_new (class, type)
	DiaShapeType type
    C_ARGS:
	type

##  void dia_shape_request_update (DiaShape *shape)
void
dia_shape_request_update (shape)
	DiaShape *shape

##  Deprecated.
##  void dia_shape_set_visibility (DiaShape *shape, DiaShapeVisibility vis)
##  #define dia_shape_get_visibility(shape) ((DiaShapeVisibility) ((shape) ? DIA_SHAPE (shape)->visibility : 0))

##  void dia_shape_set_color (DiaShape *shape, DiaColor color)
void
dia_shape_set_color (shape, color)
	DiaShape *shape
	DiaColor color

##  /* Not implemented yet: */
##  gboolean dia_shape_get_bounds (DiaShape *shape, DiaRectangle *bb)

# --------------------------------------------------------------------------- #

##  void dia_shape_line (DiaShape *shape, DiaPoint *start, DiaPoint *end)
void
dia_shape_line (shape, start, end)
	DiaShape *shape
	DiaPoint *start
	DiaPoint *end

##  void dia_shape_rectangle (DiaShape *shape, DiaPoint *upper_left, DiaPoint *lower_right)
void
dia_shape_rectangle (shape, upper_left, lower_right)
	DiaShape *shape
	DiaPoint *upper_left
	DiaPoint *lower_right

##  void dia_shape_polyline (DiaShape *shape, guint n_points, DiaPoint *points)
##  void dia_shape_polygon (DiaShape *shape, guint n_points, DiaPoint *points)
void
dia_shape_polyline (shape, ...)
	DiaShape *shape
    ALIAS:
	Gnome2::Dia::Shape::polygon = 1
    PREINIT:
	guint n_points;
	DiaPoint *points;
    CODE:
	n_points = items - 1;

	if (n_points > 0) {
		int i;

		points = g_new0 (DiaPoint, n_points);

		for (i = 1; i < items; i++)
			points[i - 1] = *(SvDiaPoint (ST (i)));

		switch (ix) {
			case 0:
				dia_shape_polyline (shape, n_points, points);
				break;
			case 1:
				dia_shape_polygon (shape, n_points, points);
				break;
			default:
				g_free (points);
				g_assert_not_reached ();
		}

		g_free (points);
	}

##  /* Not implemented yet: */
##  void dia_shape_arc (DiaShape *shape, DiaPoint *begin, DiaPoint *middle, DiaPoint *end)

##  void dia_shape_bezier (DiaShape *shape, DiaPoint *start, guint n_points, DiaPoint *points)
void
dia_shape_bezier (shape, start, ...)
	DiaShape *shape
	DiaPoint *start
    PREINIT:
	guint n_points;
	DiaPoint *points;
    CODE:
	n_points = items - 2;

	if (n_points > 0) {
		int i;

		points = g_new0 (DiaPoint, n_points);

		for (i = 2; i < items; i++)
			points[i - 2] = *(SvDiaPoint (ST (i)));

		dia_shape_bezier (shape, start, n_points, points);
		g_free (points);
	}

##  void dia_shape_ellipse (DiaShape *shape, DiaPoint *center, gdouble width, gdouble height)
void
dia_shape_ellipse (shape, center, width, height)
	DiaShape *shape
	DiaPoint *center
	gdouble width
	gdouble height

##  void dia_shape_text (DiaShape *shape, PangoFontDescription *font_desc, const gchar *text)
void
dia_shape_text (shape, font_desc, text)
	DiaShape *shape
	PangoFontDescription *font_desc
	const gchar *text

##  void dia_shape_image (DiaShape *shape, GdkPixbuf *image)
void
dia_shape_image (shape, image)
	DiaShape *shape
	GdkPixbuf *image

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Shape	PACKAGE = Gnome2::Dia::Shape::Path	PREFIX = dia_shape_path_

BOOT:
	gperl_set_isa ("Gnome2::Dia::Shape::Path", "Gnome2::Dia::Shape");

##  #define dia_shape_path_new() dia_shape_new(DIA_SHAPE_PATH)
DiaShape_own *
dia_shape_path_new (class)
    C_ARGS:
	/* void */

##  void dia_shape_path_set_fill_color (DiaShape *shape, DiaColor fill_color)
void
dia_shape_path_set_fill_color (shape, fill_color)
	DiaShape *shape
	DiaColor fill_color

##  void dia_shape_path_set_line_width (DiaShape *shape, gdouble line_width)
void
dia_shape_path_set_line_width (shape, line_width)
	DiaShape *shape
	gdouble line_width

##  void dia_shape_path_set_join (DiaShape *shape, DiaJoinStyle join)
void
dia_shape_path_set_join (shape, join)
	DiaShape *shape
	DiaJoinStyle join

##  void dia_shape_path_set_cap (DiaShape *shape, DiaCapStyle cap)
void
dia_shape_path_set_cap (shape, cap)
	DiaShape *shape
	DiaCapStyle cap

##  void dia_shape_path_set_fill (DiaShape *shape, DiaFillStyle fill)
void
dia_shape_path_set_fill (shape, fill)
	DiaShape *shape
	DiaFillStyle fill

##  void dia_shape_path_set_cyclic (DiaShape *shape, gboolean cyclic)
void
dia_shape_path_set_cyclic (shape, cyclic)
	DiaShape *shape
	gboolean cyclic

##  void dia_shape_path_set_clipping (DiaShape *shape, gboolean clipping)
void
dia_shape_path_set_clipping (shape, clipping)
	DiaShape *shape
	gboolean clipping

##  void dia_shape_path_set_dash (DiaShape *shape, gdouble offset, guint n_dash, gdouble *dash)
void
dia_shape_path_set_dash (shape, offset, ...)
	DiaShape *shape
	gdouble offset
    PREINIT:
	guint n_dash;
	gdouble *dash;
    CODE:
	n_dash = items - 2;

	if (n_dash > 0) {
		int i;

		dash = g_new0 (gdouble, n_dash);

		for (i = 2; i < items; i++)
			dash[i - 2] = SvNV (ST (i));

		dia_shape_path_set_dash (shape, offset, n_dash, dash);
		g_free (dash);
	}

##  gboolean dia_shape_path_is_clip_path (DiaShape *shape)
gboolean
dia_shape_path_is_clip_path (shape)
	DiaShape *shape

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Shape	PACKAGE = Gnome2::Dia::Shape::Bezier	PREFIX = dia_shape_bezier_

BOOT:
	gperl_set_isa ("Gnome2::Dia::Shape::Bezier", "Gnome2::Dia::Shape");

##  #define dia_shape_bezier_new() dia_shape_new(DIA_SHAPE_BEZIER)
DiaShape_own *
dia_shape_bezier_new (class)
    C_ARGS:
	/* void */

##  void dia_shape_bezier_set_fill_color (DiaShape *shape, DiaColor fill_color)
void
dia_shape_bezier_set_fill_color (shape, fill_color)
	DiaShape *shape
	DiaColor fill_color

##  void dia_shape_bezier_set_line_width (DiaShape *shape, gdouble line_width)
void
dia_shape_bezier_set_line_width (shape, line_width)
	DiaShape *shape
	gdouble line_width

##  void dia_shape_bezier_set_join (DiaShape *shape, DiaJoinStyle join)
void
dia_shape_bezier_set_join (shape, join)
	DiaShape *shape
	DiaJoinStyle join

##  void dia_shape_bezier_set_cap (DiaShape *shape, DiaCapStyle cap)
void
dia_shape_bezier_set_cap (shape, cap)
	DiaShape *shape
	DiaCapStyle cap

##  void dia_shape_bezier_set_fill (DiaShape *shape, DiaFillStyle fill)
void
dia_shape_bezier_set_fill (shape, fill)
	DiaShape *shape
	DiaFillStyle fill

##  void dia_shape_bezier_set_cyclic (DiaShape *shape, gboolean cyclic)
void
dia_shape_bezier_set_cyclic (shape, cyclic)
	DiaShape *shape
	gboolean cyclic

##  void dia_shape_bezier_set_clipping (DiaShape *shape, gboolean clipping)
void
dia_shape_bezier_set_clipping (shape, clipping)
	DiaShape *shape
	gboolean clipping

##  void dia_shape_bezier_set_dash (DiaShape *shape, gdouble offset, guint n_dash, gdouble *dash)
void
dia_shape_bezier_set_dash (shape, offset, ...)
	DiaShape *shape
	gdouble offset
    PREINIT:
	guint n_dash;
	gdouble *dash;
    CODE:
	n_dash = items - 2;

	if (n_dash > 0) {
		int i;

		dash = g_new0 (gdouble, n_dash);

		for (i = 2; i < items; i++)
			dash[i - 2] = SvNV (ST (i));

		dia_shape_bezier_set_dash (shape, offset, n_dash, dash);
		g_free (dash);
	}

##  gboolean dia_shape_bezier_is_clip_path (DiaShape *shape)
gboolean
dia_shape_bezier_is_clip_path (shape)
	DiaShape *shape

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Shape	PACKAGE = Gnome2::Dia::Shape::Ellipse	PREFIX = dia_shape_ellipse_

BOOT:
	gperl_set_isa ("Gnome2::Dia::Shape::Ellipse", "Gnome2::Dia::Shape");

##  #define dia_shape_ellipse_new() dia_shape_new(DIA_SHAPE_ELLIPSE)
DiaShape_own *
dia_shape_ellipse_new (class)
    C_ARGS:
	/* void */

##  void dia_shape_ellipse_set_fill_color (DiaShape *shape, DiaColor fill_color)
void
dia_shape_ellipse_set_fill_color (shape, fill_color)
	DiaShape *shape
	DiaColor fill_color

##  void dia_shape_ellipse_set_line_width (DiaShape *shape, gdouble line_width)
void
dia_shape_ellipse_set_line_width (shape, line_width)
	DiaShape *shape
	gdouble line_width

##  void dia_shape_ellipse_set_fill (DiaShape *shape, DiaFillStyle fill)
void
dia_shape_ellipse_set_fill (shape, fill)
	DiaShape *shape
	DiaFillStyle fill

##  void dia_shape_ellipse_set_clipping (DiaShape *shape, gboolean clipping)
void
dia_shape_ellipse_set_clipping (shape, clipping)
	DiaShape *shape
	gboolean clipping

##  void dia_shape_ellipse_set_dash (DiaShape *shape, gdouble offset, guint n_dash, gdouble *dash)
void
dia_shape_ellipse_set_dash (shape, offset, ...)
	DiaShape *shape
	gdouble offset
    PREINIT:
	guint n_dash;
	gdouble *dash;
    CODE:
	n_dash = items - 2;

	if (n_dash > 0) {
		int i;

		dash = g_new0 (gdouble, n_dash);

		for (i = 2; i < items; i++)
			dash[i - 2] = SvNV (ST (i));

		dia_shape_ellipse_set_dash (shape, offset, n_dash, dash);
		g_free (dash);
	}

##  gboolean dia_shape_ellipse_is_clip_path (DiaShape *shape)
gboolean
dia_shape_ellipse_is_clip_path (shape)
	DiaShape *shape

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Shape	PACKAGE = Gnome2::Dia::Shape::Text	PREFIX = dia_shape_text_

BOOT:
	gperl_set_isa ("Gnome2::Dia::Shape::Text", "Gnome2::Dia::Shape");

##  #define dia_shape_text_new() dia_shape_new(DIA_SHAPE_TEXT)
DiaShape_own *
dia_shape_text_new (class)
    C_ARGS:
	/* void */

##  void dia_shape_text_set_font_description (DiaShape *shape, PangoFontDescription *font_desc)
void
dia_shape_text_set_font_description (shape, font_desc)
	DiaShape *shape
	PangoFontDescription *font_desc

##  void dia_shape_text_set_text (DiaShape *shape, const gchar *text)
void
dia_shape_text_set_text (shape, text)
	DiaShape *shape
	const gchar *text

##  There's no such thing as static strings when you use the bindings.
##  void dia_shape_text_set_static_text (DiaShape *shape, const gchar *text)

##  void dia_shape_text_set_affine (DiaShape *shape, gdouble affine[6])
void
dia_shape_text_set_affine (shape, affine)
	DiaShape *shape
	SV *affine
    C_ARGS:
	shape, SvDiaAffine (affine)

##  void dia_shape_text_set_pos (DiaShape *shape, DiaPoint *pos)
void
dia_shape_text_set_pos (shape, pos)
	DiaShape *shape
	DiaPoint *pos

##  void dia_shape_text_set_text_width (DiaShape *shape, gdouble width)
void
dia_shape_text_set_text_width (shape, width)
	DiaShape *shape
	gdouble width

##  void dia_shape_text_set_line_spacing (DiaShape *shape, gdouble line_spacing)
void
dia_shape_text_set_line_spacing (shape, line_spacing)
	DiaShape *shape
	gdouble line_spacing

##  void dia_shape_text_set_max_width (DiaShape *shape, gdouble width)
void
dia_shape_text_set_max_width (shape, width)
	DiaShape *shape
	gdouble width

##  void dia_shape_text_set_max_height (DiaShape *shape, gdouble height)
void
dia_shape_text_set_max_height (shape, height)
	DiaShape *shape
	gdouble height

##  void dia_shape_text_set_justify (DiaShape *shape, gboolean justify)
void
dia_shape_text_set_justify (shape, justify)
	DiaShape *shape
	gboolean justify

##  void dia_shape_text_set_markup (DiaShape *shape, gboolean markup)
void
dia_shape_text_set_markup (shape, markup)
	DiaShape *shape
	gboolean markup

##  void dia_shape_text_set_wrap_mode (DiaShape *shape, DiaWrapMode wrap_mode)
void
dia_shape_text_set_wrap_mode (shape, wrap_mode)
	DiaShape *shape
	DiaWrapMode wrap_mode

##  void dia_shape_text_set_alignment (DiaShape *shape, PangoAlignment alignment)
void
dia_shape_text_set_alignment (shape, alignment)
	DiaShape *shape
	PangoAlignment alignment

##  PangoLayout* dia_shape_text_to_pango_layout (DiaShape *shape, gboolean fill)
PangoLayout *
dia_shape_text_to_pango_layout (shape, fill)
	DiaShape *shape
	gboolean fill

##  void dia_shape_text_fill_pango_layout (DiaShape *shape, PangoLayout *layout)
void
dia_shape_text_fill_pango_layout (shape, layout)
	DiaShape *shape
	PangoLayout *layout

##  Deprecated.
##  gboolean dia_shape_text_cursor_from_pos (DiaShape *shape, DiaPoint *pos, gint *cursor)
##  gint
##  dia_shape_text_cursor_from_pos (shape, pos)
##  	DiaShape *shape
##  	DiaPoint *pos
##      PREINIT:
##  	gint cursor;
##      CODE:
##  	if (!dia_shape_text_cursor_from_pos (shape, pos, &cursor))
##  		XSRETURN_UNDEF;
##  	RETVAL = cursor;
##      OUTPUT:
##  	RETVAL

# --------------------------------------------------------------------------- #

MODULE = Gnome2::Dia::Shape	PACKAGE = Gnome2::Dia::Shape::Image	PREFIX = dia_shape_image_

BOOT:
	gperl_set_isa ("Gnome2::Dia::Shape::Image", "Gnome2::Dia::Shape");

##  #define dia_shape_image_new() dia_shape_new(DIA_SHAPE_IMAGE)
DiaShape_own *
dia_shape_image_new (class)
    C_ARGS:
	/* void */

##  void dia_shape_image_set_affine (DiaShape *shape, gdouble affine[6])
void
dia_shape_image_set_affine (shape, affine)
	DiaShape *shape
	SV *affine
    C_ARGS:
	shape, SvDiaAffine (affine)

##  void dia_shape_image_set_pos (DiaShape *shape, DiaPoint *pos)
void
dia_shape_image_set_pos (shape, pos)
	DiaShape *shape
	DiaPoint *pos
