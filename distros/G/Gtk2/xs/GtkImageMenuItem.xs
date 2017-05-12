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

MODULE = Gtk2::ImageMenuItem	PACKAGE = Gtk2::ImageMenuItem	PREFIX = gtk_image_menu_item_

## GtkWidget* gtk_image_menu_item_new (void)
## GtkWidget* gtk_image_menu_item_new_with_mnemonic (const gchar *label)
## GtkWidget* gtk_image_menu_item_new_with_label (const gchar *label)
GtkWidget *
gtk_image_menu_item_new (class, label=NULL)
	const gchar * label
    ALIAS:
	Gtk2::ImageMenuItem::new_with_mnemonic = 1
	Gtk2::ImageMenuItem::new_with_label = 2
    CODE:
	if( label ) {
		if (ix == 2)
			RETVAL = gtk_image_menu_item_new_with_label (label);
		else
			RETVAL = gtk_image_menu_item_new_with_mnemonic(label);
	} else
		RETVAL = gtk_image_menu_item_new();
    OUTPUT:
	RETVAL

## GtkWidget* gtk_image_menu_item_new_from_stock (const gchar *stock_id, GtkAccelGroup *accel_group)
GtkWidget *
gtk_image_menu_item_new_from_stock (class, stock_id, accel_group=NULL)
	const gchar          * stock_id
	GtkAccelGroup_ornull * accel_group
    C_ARGS:
	stock_id, accel_group

## void gtk_image_menu_item_set_image (GtkImageMenuItem *image_menu_item, GtkWidget *image)
void
gtk_image_menu_item_set_image (image_menu_item, image)
	GtkImageMenuItem * image_menu_item
	GtkWidget        * image

## GtkWidget* gtk_image_menu_item_get_image (GtkImageMenuItem *image_menu_item)
GtkWidget *
gtk_image_menu_item_get_image (image_menu_item)
	GtkImageMenuItem * image_menu_item


#if GTK_CHECK_VERSION (2, 16, 0)

## gboolean gtk_image_menu_item_get_use_stock (GtkImageMenuItem *image_menu_item);
gboolean
gtk_image_menu_item_get_use_stock (image_menu_item)
	GtkImageMenuItem * image_menu_item

## void gtk_image_menu_item_set_use_stock (GtkImageMenuItem *image_menu_item, gboolean use_stock);
void
gtk_image_menu_item_set_use_stock (image_menu_item, use_stock)
	GtkImageMenuItem * image_menu_item
	gboolean           use_stock

## void gtk_image_menu_item_set_accel_group (GtkImageMenuItem *image_menu_item, GtkAccelGroup *accel_group);
void
gtk_image_menu_item_set_accel_group (image_menu_item, accel_group)
	GtkImageMenuItem * image_menu_item
	GtkAccelGroup    * accel_group


gboolean gtk_image_menu_item_get_always_show_image (GtkImageMenuItem *image_menu_item);

void	 gtk_image_menu_item_set_always_show_image (GtkImageMenuItem *image_menu_item, gboolean always_show);

#endif /* 2.16 */

