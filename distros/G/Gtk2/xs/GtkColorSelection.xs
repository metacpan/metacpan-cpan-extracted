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

MODULE = Gtk2::ColorSelection	PACKAGE = Gtk2::ColorSelection	PREFIX = gtk_color_selection_

GtkWidget *
gtk_color_selection_new (class)
    C_ARGS:
	/* void */

## gboolean gtk_color_selection_get_has_opacity_control (GtkColorSelection *colorsel)
gboolean
gtk_color_selection_get_has_opacity_control (colorsel)
	GtkColorSelection * colorsel

## void gtk_color_selection_set_has_opacity_control (GtkColorSelection *colorsel, gboolean has_opacity)
void
gtk_color_selection_set_has_opacity_control (colorsel, has_opacity)
	GtkColorSelection * colorsel
	gboolean            has_opacity

## gboolean gtk_color_selection_get_has_palette (GtkColorSelection *colorsel)
gboolean
gtk_color_selection_get_has_palette (colorsel)
	GtkColorSelection * colorsel

## void gtk_color_selection_set_has_palette (GtkColorSelection *colorsel, gboolean has_palette)
void
gtk_color_selection_set_has_palette (colorsel, has_palette)
	GtkColorSelection * colorsel
	gboolean            has_palette

## void gtk_color_selection_set_current_color (GtkColorSelection *colorsel, GdkColor *color)
void
gtk_color_selection_set_current_color (colorsel, color)
	GtkColorSelection * colorsel
	GdkColor          * color

# void gtk_color_selection_set_current_alpha (GtkColorSelection *colorsel, guint16 alpha)
void
gtk_color_selection_set_current_alpha (colorsel, alpha)
	GtkColorSelection * colorsel
	guint16             alpha

## void gtk_color_selection_get_current_color (GtkColorSelection *colorsel, GdkColor *color)
GdkColor_copy *
gtk_color_selection_get_current_color (colorsel)
	GtkColorSelection * colorsel
    PREINIT:
	GdkColor color;
    CODE:
	gtk_color_selection_get_current_color (colorsel, &color);
	RETVAL = &color;
    OUTPUT:
	RETVAL

# guint16 gtk_color_selection_get_current_alpha (GtkColorSelection *colorsel)
guint16
gtk_color_selection_get_current_alpha (colorsel)
	GtkColorSelection * colorsel

## void gtk_color_selection_set_previous_color (GtkColorSelection *colorsel, GdkColor *color)
void
gtk_color_selection_set_previous_color (colorsel, color)
	GtkColorSelection * colorsel
	GdkColor          * color

# void gtk_color_selection_set_previous_alpha (GtkColorSelection *colorsel, guint16 alpha)
void
gtk_color_selection_set_previous_alpha (colorsel, alpha)
	GtkColorSelection * colorsel
	guint16             alpha

## void gtk_color_selection_get_previous_color (GtkColorSelection *colorsel, GdkColor *color)
GdkColor_copy *
gtk_color_selection_get_previous_color (colorsel)
	GtkColorSelection * colorsel
    PREINIT:
	GdkColor color;
    CODE:
	gtk_color_selection_get_previous_color (colorsel, &color);
	RETVAL = &color;
    OUTPUT:
	RETVAL

# guint16 gtk_color_selection_get_previous_alpha (GtkColorSelection *colorsel)
guint16
gtk_color_selection_get_previous_alpha (colorsel)
	GtkColorSelection * colorsel

## gboolean gtk_color_selection_is_adjusting (GtkColorSelection *colorsel)
gboolean
gtk_color_selection_is_adjusting (colorsel)
	GtkColorSelection * colorsel

## gboolean gtk_color_selection_palette_from_string (const gchar *str, GdkColor **colors, gint *n_colors)
=for apidoc
Returns a list of Gtk2::Gdk::color's.
=cut
void
gtk_color_selection_palette_from_string (class, string)
	gchar * string
    PREINIT:
	GdkColor * colors;
	gint n_colors;
	int i;
    PPCODE:
	if (!gtk_color_selection_palette_from_string (string,
						&colors, &n_colors))
		XSRETURN_EMPTY;
	EXTEND (SP, n_colors);
	for (i = 0; i < n_colors; i++)
		PUSHs (sv_2mortal (newSVGdkColor_copy (&(colors[i]))));
	g_free (colors);

## gchar* gtk_color_selection_palette_to_string (const GdkColor *colors, gint n_colors)
=for apidoc
=for signature (string) = Gtk::ColorSelection->palette_to_string (...)
=for arg ... of Gtk2::Gdk::Color's for the palette
Encodes a palette as a string, useful for persistent storage.
=cut
SV *
gtk_color_selection_palette_to_string (class, ...)
    PREINIT:
	GdkColor * colors;
	gint n_colors;
	gchar * string;
	int i;
    CODE:
	n_colors = items - 1;
	for (i = 0 ; i < n_colors ; i++) {
		/* this will croak if any of the items are not valid */
		gperl_get_boxed_check (ST (i+1), GDK_TYPE_COLOR);
	}
	/* now that we know we won't croak, it's safe to alloc some memory. */
	colors = g_new0 (GdkColor, n_colors);
	for (i = 0 ; i < n_colors ; i++) {
		GdkColor * c =
			gperl_get_boxed_check (ST (i+1), GDK_TYPE_COLOR);
		colors[i] = *c;
	}
	string = gtk_color_selection_palette_to_string (colors, n_colors);
	RETVAL = newSVpv (string, 0);
	g_free (colors);
	g_free (string);
    OUTPUT:
	RETVAL


# TODO: GtkColorSelectionChangePaletteFunc not in typemap (that's a mouthfull)
## GtkColorSelectionChangePaletteFunc gtk_color_selection_set_change_palette_hook (GtkColorSelectionChangePaletteFunc func)
#GtkColorSelectionChangePaletteFunc
#gtk_color_selection_set_change_palette_hook (func)
#	GtkColorSelectionChangePaletteFunc func

# TODO: no marshaller for GtkColorSelectionChangePaletteWithScreenFunc either
## GtkColorSelectionChangePaletteWithScreenFunc gtk_color_selection_set_change_palette_with_screen_hook (GtkColorSelectionChangePaletteWithScreenFunc func)

# deprecated
## void gtk_color_selection_get_color (GtkColorSelection *colorsel, gdouble *color)

# deprecated
## void gtk_color_selection_set_update_policy (GtkColorSelection *colorsel, GtkUpdateType policy)

# deprecated
#void gtk_color_selection_set_color (GtkColorSelection *colorsel, gdouble *color)

#GtkType gtk_color_selection_get_type (void) G_GNUC_CONST

