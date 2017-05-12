/*
 * Copyright (c) 2003-2009 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::Style	PACKAGE = Gtk2::Style	PREFIX = gtk_style_

BOOT:
	/* theme engines can provide subclasses on GtkStyle which may have
	 * any name they like, and will not be registered with the gperl
	 * bindings type subsystem.  any time a user has the theme set to
	 * anything other than the default, one of these unregistered
	 * styles comes through.  set this to keep gperl_get_object from
	 * spewing harmless and unavoidable warnings all over stderr. */
	gperl_object_set_no_warn_unreg_subclass (GTK_TYPE_STYLE, TRUE);

SV *
black (style)
	GtkStyle * style
    ALIAS:
	Gtk2::Style::white = 1
	Gtk2::Style::font_desc = 2
	Gtk2::Style::xthickness = 3
	Gtk2::Style::ythickness = 4
	Gtk2::Style::black_gc = 5
	Gtk2::Style::white_gc = 6
    CODE:
	switch (ix) {
	    case 0: RETVAL = newSVGdkColor (&(style->black)); break;
	    case 1: RETVAL = newSVGdkColor (&(style->white)); break;
	    case 2: RETVAL = newSVPangoFontDescription_copy (style->font_desc); break;
	    case 3: RETVAL = newSViv (style->xthickness); break;
	    case 4: RETVAL = newSViv (style->ythickness); break;
	    case 5: RETVAL = newSVGdkGC (style->black_gc); break;
	    case 6: RETVAL = newSVGdkGC (style->white_gc); break;
	    default: 
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

GdkColor *
fg (style, state)
	GtkStyle * style
	GtkStateType state
    ALIAS:
	Gtk2::Style::bg = 1
	Gtk2::Style::light = 2
	Gtk2::Style::dark = 3
	Gtk2::Style::mid = 4
	Gtk2::Style::text = 5
	Gtk2::Style::base = 6
	Gtk2::Style::text_aa = 7
    CODE:
	switch (ix) {
	    case 0: RETVAL = &(style->fg[state]); break;
	    case 1: RETVAL = &(style->bg[state]); break;
	    case 2: RETVAL = &(style->light[state]); break;
	    case 3: RETVAL = &(style->dark[state]); break;
	    case 4: RETVAL = &(style->mid[state]); break;
	    case 5: RETVAL = &(style->text[state]); break;
	    case 6: RETVAL = &(style->base[state]); break;
	    case 7: RETVAL = &(style->text_aa[state]); break;
	    default: 
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

# legitimate reference, not a copy
GdkGC *
fg_gc (style, state)
	GtkStyle * style
	GtkStateType state
    ALIAS:
	Gtk2::Style::bg_gc = 1
	Gtk2::Style::light_gc = 2
	Gtk2::Style::dark_gc = 3
	Gtk2::Style::mid_gc = 4
	Gtk2::Style::text_gc = 5
	Gtk2::Style::base_gc = 6
	Gtk2::Style::text_aa_gc = 7
    CODE:
	switch (ix) {
	    case 0: RETVAL = style->fg_gc[state]; break;
	    case 1: RETVAL = style->bg_gc[state]; break;
	    case 2: RETVAL = style->light_gc[state]; break;
	    case 3: RETVAL = style->dark_gc[state]; break;
	    case 4: RETVAL = style->mid_gc[state]; break;
	    case 5: RETVAL = style->text_gc[state]; break;
	    case 6: RETVAL = style->base_gc[state]; break;
	    case 7: RETVAL = style->text_aa_gc[state]; break;
	    default: 
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL


# legitimate reference, not a copy
GdkPixmap *
bg_pixmap (style, state, pixmap=NULL)
	GtkStyle * style
	GtkStateType state
	GdkPixmap_ornull * pixmap
    CODE:
	RETVAL = style->bg_pixmap[state];
	if (items > 2 && style->bg_pixmap[state] != pixmap) {
		if (style->bg_pixmap[state])
			g_object_unref (style->bg_pixmap[state]);
		style->bg_pixmap[state] = pixmap;
		if (pixmap)
			g_object_ref (pixmap);
	}
    OUTPUT:
	RETVAL


 ## GtkStyle* gtk_style_new (void)
GtkStyle_noinc*
gtk_style_new (class)
    C_ARGS:
	/* void */


 ## GtkStyle* gtk_style_copy (GtkStyle *style)
GtkStyle_noinc*
gtk_style_copy (style)
	GtkStyle *style

gboolean
gtk_style_attached (style)
	GtkStyle *style
    CODE:
	RETVAL = GTK_STYLE_ATTACHED (style);
    OUTPUT:
	RETVAL

 ## GtkStyle* gtk_style_attach (GtkStyle *style, GdkWindow *window)
GtkStyle *
gtk_style_attach (style, window)
	GtkStyle *style
	GdkWindow *window
    CLEANUP:
	if (RETVAL != style)
		/* claim ownership of new object */
		g_object_unref (RETVAL);

 ## void gtk_style_detach (GtkStyle *style)
void
gtk_style_detach (style)
	GtkStyle *style

# deprecated
 ## GtkStyle* gtk_style_ref (GtkStyle *style)
 ## void gtk_style_unref (GtkStyle *style)

 ## void gtk_style_set_background (GtkStyle *style, GdkWindow *window, GtkStateType state_type)
void
gtk_style_set_background (style, window, state_type)
	GtkStyle *style
	GdkWindow *window
	GtkStateType state_type

 ## void gtk_style_apply_default_background (GtkStyle *style, GdkWindow *window, gboolean set_bg, GtkStateType state_type, GdkRectangle *area, gint x, gint y, gint width, gint height)
void
gtk_style_apply_default_background (style, window, set_bg, state_type, area, x, y, width, height)
	GtkStyle *style
	GdkWindow *window
	gboolean set_bg
	GtkStateType state_type
	GdkRectangle_ornull *area
	gint x
	gint y
	gint width
	gint height

 ## GtkIconSet* gtk_style_lookup_icon_set (GtkStyle *style, const gchar *stock_id)
GtkIconSet*
gtk_style_lookup_icon_set (style, stock_id)
	GtkStyle *style
	const gchar *stock_id

 ## GdkPixbuf* gtk_style_render_icon (GtkStyle *style, const GtkIconSource *source, GtkTextDirection direction, GtkStateType state, GtkIconSize size, GtkWidget *widget, const gchar *detail)
GdkPixbuf_noinc*
gtk_style_render_icon (style, source, direction, state, size, widget, detail=NULL)
	GtkStyle *style
	GtkIconSource *source
	GtkTextDirection direction
	GtkStateType state
	GtkIconSize size
	GtkWidget_ornull *widget
	const gchar_ornull *detail

MODULE = Gtk2::Style	PACKAGE = Gtk2::Style	PREFIX = gtk_

 ## void gtk_paint_flat_box (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_flat_box (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_hline (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x1, gint x2, gint y)
void
gtk_paint_hline (style, window, state_type, area, widget, detail, x1, x2, y)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x1
	gint x2
	gint y

 ## void gtk_paint_vline (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint y1_, gint y2_, gint x)
void
gtk_paint_vline (style, window, state_type, area, widget, detail, y1_, y2_, x)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint y1_
	gint y2_
	gint x

 ## void gtk_paint_shadow (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_shadow (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_polygon (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, GdkPoint *points, gint npoints, gboolean fill)
=for apidoc
=for arg x1 (gint) x coordinate of the first vertex
=for arg y1 (gint) y coordinate of the first vertex
=for arg ... pairs of x and y coordinates
=cut
void
gtk_paint_polygon (style, window, state_type, shadow_type, area, widget, detail, fill, x1, y1, ...)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gboolean fill
    PREINIT:
	GdkPoint *points;
	gint npoints, i;
    CODE:
#define first 8
	npoints = (items - first) / 2;
	points = g_new (GdkPoint, npoints);
	for (i = 0 ; i < npoints ; i++) {
		points[i].x = SvIV (ST (first + 2*i));
		points[i].y = SvIV (ST (first + 2*i + 1));
	}
	gtk_paint_polygon (style, window, state_type, shadow_type,
	                   area, widget, detail, points, npoints, fill);
	g_free (points);
#undef first

 ## void gtk_paint_arrow (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, GtkArrowType arrow_type, gboolean fill, gint x, gint y, gint width, gint height)
void
gtk_paint_arrow (style, window, state_type, shadow_type, area, widget, detail, arrow_type, fill, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	GtkArrowType arrow_type
	gboolean fill
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_diamond (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_diamond (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_box (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_box (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_check (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_check (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_option (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_option (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_tab (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_tab (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_shadow_gap (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, gchar *detail, gint x, gint y, gint width, gint height, GtkPositionType gap_side, gint gap_x, gint gap_width)
void
gtk_paint_shadow_gap (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height, gap_side, gap_x, gap_width)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height
	GtkPositionType gap_side
	gint gap_x
	gint gap_width

 ## void gtk_paint_box_gap (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, gchar *detail, gint x, gint y, gint width, gint height, GtkPositionType gap_side, gint gap_x, gint gap_width)
void
gtk_paint_box_gap (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height, gap_side, gap_x, gap_width)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height
	GtkPositionType gap_side
	gint gap_x
	gint gap_width

 ## void gtk_paint_extension (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, gchar *detail, gint x, gint y, gint width, gint height, GtkPositionType gap_side)
void
gtk_paint_extension (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height, gap_side)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height
	GtkPositionType gap_side

 ## void gtk_paint_focus (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height)
void
gtk_paint_focus (style, window, state_type, area, widget, detail, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height

 ## void gtk_paint_slider (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height, GtkOrientation orientation)
void
gtk_paint_slider (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height, orientation)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x
	gint y
	gint width
	gint height
	GtkOrientation orientation

 ## void gtk_paint_handle (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GtkShadowType shadow_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, gint width, gint height, GtkOrientation orientation)
void
gtk_paint_handle (style, window, state_type, shadow_type, area, widget, detail, x, y, width, height, orientation)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GtkShadowType shadow_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar *detail
	gint x
	gint y
	gint width
	gint height
	GtkOrientation orientation

 ## void gtk_paint_expander (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, GtkExpanderStyle expander_style)
void
gtk_paint_expander (style, window, state_type, area, widget, detail, x, y, expander_style)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GdkRectangle_ornull *area
	GtkWidget *widget
	const gchar_ornull *detail
	gint x
	gint y
	GtkExpanderStyle expander_style

 ## void gtk_paint_layout (GtkStyle *style, GdkWindow *window, GtkStateType state_type, gboolean use_text, GdkRectangle *area, GtkWidget *widget, const gchar *detail, gint x, gint y, PangoLayout *layout)
void
gtk_paint_layout (style, window, state_type, use_text, area, widget, detail, x, y, layout)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	gboolean use_text
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	gint x
	gint y
	PangoLayout *layout

 ## void gtk_paint_resize_grip (GtkStyle *style, GdkWindow *window, GtkStateType state_type, GdkRectangle *area, GtkWidget *widget, const gchar *detail, GdkWindowEdge edge, gint x, gint y, gint width, gint height)
void
gtk_paint_resize_grip (style, window, state_type, area, widget, detail, edge, x, y, width, height)
	GtkStyle *style
	GdkDrawable *window
	GtkStateType state_type
	GdkRectangle_ornull *area
	GtkWidget_ornull *widget
	const gchar_ornull *detail
	GdkWindowEdge edge
	gint x
	gint y
	gint width
	gint height

#if GTK_CHECK_VERSION (2, 20, 0)

void gtk_paint_spinner (GtkStyle *style, GdkWindow *window, GtkStateType state_type, const GdkRectangle_ornull *area, GtkWidget_ornull *widget, const gchar_ornull *detail, guint step, gint x, gint y, gint width, gint height);

#endif /* 2.20 */

MODULE = Gtk2::Style	PACKAGE = Gtk2	PREFIX = gtk_

#if GTK_CHECK_VERSION (2, 4, 0)

=for object Gtk2::Style
=cut

void
gtk_draw_insertion_cursor (class, widget, drawable, area, location, is_primary, direction, draw_arrow)
	GtkWidget *widget
	GdkDrawable *drawable
	GdkRectangle *area
	GdkRectangle *location
	gboolean is_primary
	GtkTextDirection direction
	gboolean draw_arrow
    C_ARGS:
	widget, drawable, area, location, is_primary, direction, draw_arrow

#endif

MODULE = Gtk2::Style	PACKAGE = Gtk2::Style	PREFIX = gtk_style_

#if GTK_CHECK_VERSION (2, 10, 0)

GdkColor_copy *
gtk_style_lookup_color (GtkStyle *style, const gchar *color_name)
    PREINIT:
        GdkColor color;
    CODE:
        if (!gtk_style_lookup_color (style, color_name, &color))
                XSRETURN_UNDEF;
        RETVAL = &color;
    OUTPUT:
        RETVAL

#endif

#if GTK_CHECK_VERSION (2, 16, 0)

=for apidoc
=for signature list = $style->get (widget_package, ...)
=for signature list = $style->get_style_property (widget_package, ...)
=for arg widget_package (string) widget package name (ex: 'Gtk2::TreeView')
=for arg ... (list) list of property names

Fetch and return the values for the style properties named in I<...> for a
widget of type I<widget_package>.  I<get> is an alias for
I<get_style_property>.

    my $size = $style->get_style_property ("expander-size");

B<Note>: The I<get> method shadows I<Glib::Object::get> (see
L<Glib::Object/get and set>).  This shouldn't be a problem since
I<Gtk2::Style> defines no properties (as of gtk+ 2.16).  If you have a
class that's derived from Gtk2::Style and adds a property or if a new
version of gtk+ adds a property to I<Gtk2::Style> then the property
can be accessed with I<get_property>.
=cut
void
gtk_style_get (style, widget_package, ...)
	GtkStyle *style
	const char *widget_package
    ALIAS:
	get_style_property = 1
    PREINIT:
	int i;
	GType widget_type;
	gpointer class;
    CODE:
	/* Use CODE: instead of PPCODE: so we can handle the stack ourselves in
	 * order to avoid that xsubs called by gtk_style_get_style_property
	 * overwrite what we put on the stack. */

	PERL_UNUSED_VAR (ix);

	widget_type = gperl_type_from_package (widget_package);
	if (widget_type == 0)
		croak ("package %s is not registered with GPerl", widget_package);

	if (! g_type_is_a (widget_type, GTK_TYPE_WIDGET))
		croak ("%s is not a subclass of Gtk2::Widget", widget_package);


	class = g_type_class_ref (widget_type);
	if (class == NULL)
		croak ("can't find type class for type %s", widget_package);

	for (i = 2 ; i < items ; i++) {
		GValue value = {0, };
		gchar *name = SvGChar (ST (i));
		GParamSpec *pspec =
			gtk_widget_class_find_style_property (class, name);

		if (pspec) {
			g_value_init (&value, G_PARAM_SPEC_VALUE_TYPE (pspec));
			gtk_style_get_style_property (style, widget_type, name, &value);
			ST (i - 2) = sv_2mortal (gperl_sv_from_value (&value));
			g_value_unset (&value);
		}
		else {
			g_type_class_unref (class);
			croak ("type %s does not support style property '%s'",
			       widget_package, name);
		}
	}

	g_type_class_unref (class);

	XSRETURN (items - 2);

#endif
