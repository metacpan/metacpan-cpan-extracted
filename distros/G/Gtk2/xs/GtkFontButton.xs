/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::FontButton	PACKAGE = Gtk2::FontButton	PREFIX = gtk_font_button_

## GtkWidget *gtk_font_button_new (void);
## GtkWidget *gtk_font_button_new_with_font (const gchar *fontname);
GtkWidget *
gtk_font_button_new (class, const gchar * fontname=NULL)
    ALIAS:
	new_with_font = 1
    CODE:
	PERL_UNUSED_VAR (ix);
	RETVAL = items == 2
	       ? gtk_font_button_new_with_font (fontname)
	       : gtk_font_button_new ();
    OUTPUT:
	RETVAL

const gchar *gtk_font_button_get_title (GtkFontButton *font_button);

void gtk_font_button_set_title (GtkFontButton *font_button, const gchar *title);

gboolean gtk_font_button_get_use_font (GtkFontButton *font_button);

void gtk_font_button_set_use_font (GtkFontButton *font_button, gboolean use_font);

gboolean gtk_font_button_get_use_size (GtkFontButton *font_button);

void gtk_font_button_set_use_size (GtkFontButton *font_button, gboolean use_size);

const gchar* gtk_font_button_get_font_name (GtkFontButton *font_button);

gboolean gtk_font_button_set_font_name (GtkFontButton *font_button, const gchar *fontname);

gboolean gtk_font_button_get_show_style (GtkFontButton *font_button);

void gtk_font_button_set_show_style (GtkFontButton *font_button, gboolean show_style);

gboolean gtk_font_button_get_show_size (GtkFontButton *font_button);

void gtk_font_button_set_show_size (GtkFontButton *font_button, gboolean show_size);


