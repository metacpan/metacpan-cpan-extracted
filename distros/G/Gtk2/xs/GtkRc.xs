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

MODULE = Gtk2::Rc	PACKAGE = Gtk2::Rc	PREFIX = gtk_rc_

## void _gtk_rc_init (void)

## void gtk_rc_add_default_file (const gchar *filename)
void
gtk_rc_add_default_file (class, filename)
	GPerlFilename filename
    C_ARGS:
	filename

=for apidoc
Returns the list of files that GTK+ will read at the end of Gtk2->init.
=cut
## gchar** gtk_rc_get_default_files (void)
void
gtk_rc_get_default_files (class)
    PREINIT:
	gchar **filenames = NULL;
	int i;
    PPCODE:
	PERL_UNUSED_VAR (ax);
	filenames = gtk_rc_get_default_files ();
	if (filenames)
		for (i = 0; filenames[i]; i++)
			XPUSHs (sv_2mortal (gperl_sv_from_filename (filenames[i])));

## void gtk_rc_set_default_files (gchar **filenames)
=for apidoc
=for signature Gtk2::Rc->set_default_files (file1, ...)
=for arg file1 (GPerlFilename)
=for arg ... of strings, the rc files to be parsed
Sets the list of files that GTK+ will read at the end of Gtk2->init.
=cut
void
gtk_rc_set_default_files (class, ...)
    PREINIT:
	gchar **filenames = NULL;
	int i;
    CODE:
	filenames = g_new0(gchar*, items);

	for( i = 1; i < items; i++ )
		filenames[i - 1] = gperl_filename_from_sv (ST(i));

	gtk_rc_set_default_files(filenames);
	g_free(filenames);

## GtkStyle* gtk_rc_get_style (GtkWidget *widget)
GtkStyle*
gtk_rc_get_style (class, widget)
	GtkWidget *widget
    C_ARGS:
	widget

## GtkStyle* gtk_rc_get_style_by_paths (GtkSettings *settings, const char *widget_path, const char *class_path, GType type)
GtkStyle *
gtk_rc_get_style_by_paths (class, settings, widget_path, class_path, package)
	GtkSettings *settings
	const char  * widget_path
	const char  * class_path
	const char  * package
    PREINIT:
	GType gtype = {0,};
    CODE:
	gtype = gperl_object_type_from_package (package);
	RETVAL = gtk_rc_get_style_by_paths
			(settings, widget_path, class_path, gtype);
    OUTPUT:
	RETVAL

## gboolean gtk_rc_reparse_all_for_settings (GtkSettings *settings, gboolean force_load)
gboolean
gtk_rc_reparse_all_for_settings (class, settings, force_load)
	GtkSettings *settings
	gboolean force_load
    C_ARGS:
	settings, force_load

#if GTK_CHECK_VERSION (2, 4, 0)

## void gtk_rc_reset_styles (GtkSettings *settings)
void gtk_rc_reset_styles (class, settings)
	GtkSettings *settings
    C_ARGS:
	settings

#endif

# TODO: GScanner * not in typemap
## gchar* gtk_rc_find_pixmap_in_path (GtkSettings *settings, GScanner *scanner, const gchar *pixmap_file)
#gchar*
#gtk_rc_find_pixmap_in_path (settings, scanner, pixmap_file)
#	GtkSettings *settings
#	GScanner *scanner
#	const gchar *pixmap_file

## void gtk_rc_parse (const gchar *filename)
void
gtk_rc_parse (class, filename)
	GPerlFilename filename
    C_ARGS:
	filename

## void gtk_rc_parse_string (const gchar *rc_string)
void
gtk_rc_parse_string (class, rc_string)
	const gchar * rc_string
    C_ARGS:
	rc_string

## gboolean gtk_rc_reparse_all (void)
gboolean
gtk_rc_reparse_all (class)
    C_ARGS:
	/* void */

# API docs: "This function is not useful for applications and should not be used."
### gchar* gtk_rc_find_module_in_path (const gchar *module_file)
#gchar_own *
#gtk_rc_find_module_in_path (class, module_file)
#	const gchar * module_file
#    C_ARGS:
#	module_file

## gchar* gtk_rc_get_theme_dir (void)
gchar_own *
gtk_rc_get_theme_dir (class)
    C_ARGS:
	/* void */

## gchar* gtk_rc_get_module_dir (void)
gchar_own *
gtk_rc_get_module_dir (class)
    C_ARGS:
	/* void */

## gchar* gtk_rc_get_im_module_path (void)
gchar_own *
gtk_rc_get_im_module_path (class)
    C_ARGS:
	/* void */

## gchar* gtk_rc_get_im_module_file (void)
gchar_own *
gtk_rc_get_im_module_file (class)
    C_ARGS:
	/* void */

MODULE = Gtk2::Rc	PACKAGE = Gtk2::RcStyle	PREFIX = gtk_rc_style_

SV *
name (style, new=NULL)
	GtkRcStyle *style
	SV *new
    ALIAS:
	font_desc  = 1
	xthickness = 2
	ythickness = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = newSVGChar (style->name); break;
		case 1: RETVAL = newSVPangoFontDescription (style->font_desc); break;
		case 2: RETVAL = newSViv (style->xthickness); break;
		case 3: RETVAL = newSViv (style->ythickness); break;
		default:
			RETVAL = NULL;
			g_assert_not_reached ();
	}

	if (items == 2) {
		switch (ix) {
		    case 0:
			if (style->name)
				g_free (style->name);
			style->name = gperl_sv_is_defined (new)
			            ? g_strdup (SvGChar (new))
				    : NULL;
			break;
		    case 1:
			if (style->font_desc)
				pango_font_description_free (style->font_desc);
			style->font_desc = gperl_sv_is_defined (new)
			                 ? SvPangoFontDescription (new)
					 : NULL;
			if (style->font_desc)
				style->font_desc = pango_font_description_copy
							(style->font_desc);
			break;
		    case 2: style->xthickness = SvIV (new); break;
		    case 3: style->ythickness = SvIV (new); break;
		    default:
			g_assert_not_reached ();
		}
	}
    OUTPUT:
	RETVAL

SV *
bg_pixmap_name (style, state, new=NULL)
	GtkRcStyle *style
	GtkStateType state
	gchar_ornull *new
    CODE:
	RETVAL = style->bg_pixmap_name[state]
	       ? newSVGChar (style->bg_pixmap_name[state])
	       : NULL;
	if (items == 3) {
		if (style->bg_pixmap_name[state])
			g_free (style->bg_pixmap_name[state]);
		style->bg_pixmap_name[state] = new ? g_strdup (new) : NULL;
	}
    OUTPUT:
	RETVAL

GtkRcFlags
color_flags (style, state, new=0)
	GtkRcStyle *style
	GtkStateType state
	GtkRcFlags new
    CODE:
	RETVAL = style->color_flags[state];
	if (items == 3)
		style->color_flags[state] = new;
    OUTPUT:
	RETVAL

GdkColor_copy *
fg (style, state, new=NULL)
	GtkRcStyle *style
	GtkStateType state
	GdkColor_ornull *new
    ALIAS:
	bg   = 1
	text = 2
	base = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = &(style->fg[state]); break;
		case 1: RETVAL = &(style->bg[state]); break;
		case 2: RETVAL = &(style->text[state]); break;
		case 3: RETVAL = &(style->base[state]); break;
		default:
			RETVAL = NULL;
			g_assert_not_reached ();
	}

	if (items == 3) {
		switch (ix) {
			case 0: style->fg[state]   = *new; break;
			case 1: style->bg[state]   = *new; break;
			case 2: style->text[state] = *new; break;
			case 3: style->base[state] = *new; break;
			default:
				g_assert_not_reached ();
		}
	}
    OUTPUT:
	RETVAL

## GtkRcStyle* gtk_rc_style_new (void)
GtkRcStyle_noinc *
gtk_rc_style_new (class)
    C_ARGS:
	/*void*/

# GtkRcStyle* gtk_rc_style_copy (GtkRcStyle *orig)
GtkRcStyle_noinc *
gtk_rc_style_copy (orig)
	GtkRcStyle * orig

# should happen automagically
## void gtk_rc_style_ref (GtkRcStyle *rc_style)
## void gtk_rc_style_unref (GtkRcStyle *rc_style)
