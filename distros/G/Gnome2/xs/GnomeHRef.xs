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

MODULE = Gnome2::HRef	PACKAGE = Gnome2::HRef	PREFIX = gnome_href_

GtkWidget *
gnome_href_new (class, url, text)
	const gchar *url
	const gchar *text
    C_ARGS:
	url, text

void
gnome_href_set_url (href, url)
	GnomeHRef *href
	const gchar *url

const gchar *
gnome_href_get_url (href)
	GnomeHRef * href

void
gnome_href_set_text (href, text)
	GnomeHRef *href
	const gchar *text

const gchar *
gnome_href_get_text (href)
	GnomeHRef * href

void
gnome_href_set_label (href, label)
	GnomeHRef *href
	const gchar *label

const gchar *
gnome_href_get_label (href)
	GnomeHRef * href
