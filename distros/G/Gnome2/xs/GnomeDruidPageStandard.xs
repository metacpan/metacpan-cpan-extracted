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

MODULE = Gnome2::DruidPageStandard	PACKAGE = Gnome2::DruidPageStandard	PREFIX = gnome_druid_page_standard_

## GtkWidget*  gnome_druid_page_standard_new   (void);
GtkWidget * 
gnome_druid_page_standard_new (class)
    C_ARGS:
	/* void */

## GtkWidget*  gnome_druid_page_standard_new_with_vals (const gchar *title, GdkPixbuf *logo, GdkPixbuf *top_watermark);
GtkWidget *
gnome_druid_page_standard_new_with_vals (class, title, logo=NULL, top_watermark=NULL)
	const gchar *title
	GdkPixbuf_ornull *logo
	GdkPixbuf_ornull *top_watermark
    C_ARGS:
	title, logo, top_watermark

## void gnome_druid_page_standard_set_title (GnomeDruidPageStandard *druid_page_standard, const gchar *title) 
void
gnome_druid_page_standard_set_title (druid_page_standard, title)
	GnomeDruidPageStandard *druid_page_standard
	const gchar *title

## void gnome_druid_page_standard_set_logo (GnomeDruidPageStandard *druid_page_standard, GdkPixbuf *logo_image) 
void
gnome_druid_page_standard_set_logo (druid_page_standard, logo_image)
	GnomeDruidPageStandard *druid_page_standard
	GdkPixbuf_ornull *logo_image

## void gnome_druid_page_standard_set_top_watermark (GnomeDruidPageStandard *druid_page_standard, GdkPixbuf *top_watermark_image) 
void
gnome_druid_page_standard_set_top_watermark (druid_page_standard, top_watermark_image)
	GnomeDruidPageStandard *druid_page_standard
	GdkPixbuf_ornull *top_watermark_image

## void gnome_druid_page_standard_set_title_foreground (GnomeDruidPageStandard *druid_page_standard, GdkColor *color) 
void
gnome_druid_page_standard_set_title_foreground (druid_page_standard, color)
	GnomeDruidPageStandard *druid_page_standard
	GdkColor *color

## void gnome_druid_page_standard_set_background (GnomeDruidPageStandard *druid_page_standard, GdkColor *color) 
void
gnome_druid_page_standard_set_background (druid_page_standard, color)
	GnomeDruidPageStandard *druid_page_standard
	GdkColor *color

## void gnome_druid_page_standard_set_logo_background (GnomeDruidPageStandard *druid_page_standard, GdkColor *color) 
void
gnome_druid_page_standard_set_logo_background (druid_page_standard, color)
	GnomeDruidPageStandard *druid_page_standard
	GdkColor *color

## void gnome_druid_page_standard_set_contents_background (GnomeDruidPageStandard *druid_page_standard, GdkColor *color) 
void
gnome_druid_page_standard_set_contents_background (druid_page_standard, color)
	GnomeDruidPageStandard *druid_page_standard
	GdkColor *color

## void gnome_druid_page_standard_append_item (GnomeDruidPageStandard *druid_page_standard, const gchar *question, GtkWidget *item, const gchar *additional_info) 
void
gnome_druid_page_standard_append_item (druid_page_standard, question, item, additional_info)
	GnomeDruidPageStandard *druid_page_standard
	const gchar *question
	GtkWidget *item
	const gchar *additional_info

# Since the vbox member isn't available as an object property, we provide a
# separate accessor.
GtkWidget *
vbox (druid_page_standard)
	GnomeDruidPageStandard * druid_page_standard
    CODE:
	RETVAL = druid_page_standard->vbox;
    OUTPUT:
	RETVAL
