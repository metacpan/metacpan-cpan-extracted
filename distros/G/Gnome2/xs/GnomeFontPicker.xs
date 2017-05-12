/*
 * Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

/* gnome-font-picker.h was deprecated in 2003 */
#undef GNOME_DISABLE_DEPRECATED

MODULE = Gnome2::FontPicker	PACKAGE = Gnome2::FontPicker	PREFIX = gnome_font_picker_

GtkWidget *
gnome_font_picker_new (class)
    C_ARGS:
	/* void */

## void gnome_font_picker_set_title (GnomeFontPicker *gfp, const gchar *title) 
void
gnome_font_picker_set_title (gfp, title)
	GnomeFontPicker *gfp
	const gchar *title

## const gchar* gnome_font_picker_get_title (GnomeFontPicker *gfp) 
const gchar*
gnome_font_picker_get_title (gfp)
	GnomeFontPicker *gfp

## GnomeFontPickerMode gnome_font_picker_get_mode (GnomeFontPicker *gfp) 
GnomeFontPickerMode
gnome_font_picker_get_mode (gfp)
	GnomeFontPicker *gfp

## void gnome_font_picker_set_mode (GnomeFontPicker *gfp, GnomeFontPickerMode mode) 
void
gnome_font_picker_set_mode (gfp, mode)
	GnomeFontPicker *gfp
	GnomeFontPickerMode mode

## void gnome_font_picker_fi_set_use_font_in_label (GnomeFontPicker *gfp, gboolean use_font_in_label, gint size) 
void
gnome_font_picker_fi_set_use_font_in_label (gfp, use_font_in_label, size)
	GnomeFontPicker *gfp
	gboolean use_font_in_label
	gint size

## void gnome_font_picker_fi_set_show_size (GnomeFontPicker *gfp, gboolean show_size) 
void
gnome_font_picker_fi_set_show_size (gfp, show_size)
	GnomeFontPicker *gfp
	gboolean show_size

## void gnome_font_picker_uw_set_widget (GnomeFontPicker *gfp, GtkWidget *widget) 
void
gnome_font_picker_uw_set_widget (gfp, widget)
	GnomeFontPicker *gfp
	GtkWidget *widget

## GtkWidget * gnome_font_picker_uw_get_widget (GnomeFontPicker *gfp) 
GtkWidget *
gnome_font_picker_uw_get_widget (gfp)
	GnomeFontPicker *gfp

## const gchar* gnome_font_picker_get_font_name (GnomeFontPicker *gfp) 
const gchar*
gnome_font_picker_get_font_name (gfp)
	GnomeFontPicker *gfp

## gboolean gnome_font_picker_set_font_name (GnomeFontPicker *gfp, const gchar *fontname) 
gboolean
gnome_font_picker_set_font_name (gfp, fontname)
	GnomeFontPicker *gfp
	const gchar *fontname

## void gnome_font_picker_set_preview_text (GnomeFontPicker *gfp, const gchar *text) 
void
gnome_font_picker_set_preview_text (gfp, text)
	GnomeFontPicker *gfp
	const gchar *text

const gchar* gnome_font_picker_get_preview_text (GnomeFontPicker *gfp);
