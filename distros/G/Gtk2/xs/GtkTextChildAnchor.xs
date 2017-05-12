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

MODULE = Gtk2::TextChildAnchor	PACKAGE = Gtk2::TextChildAnchor	PREFIX = gtk_text_child_anchor_

##  GtkTextChildAnchor* gtk_text_child_anchor_new (void) 
GtkTextChildAnchor_noinc *
gtk_text_child_anchor_new (class)
    C_ARGS:
	/* void */

##  GList* gtk_text_child_anchor_get_widgets (GtkTextChildAnchor *anchor) 
=for apidoc
Returns a list of Gtk2::Widgets.
=cut
void
gtk_text_child_anchor_get_widgets (anchor)
	GtkTextChildAnchor *anchor
    PREINIT:
	GList *widgets, *i;
    PPCODE:
	widgets = gtk_text_child_anchor_get_widgets (anchor);
	for (i = widgets; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkWidget (i->data)));
	g_list_free (widgets);

##  gboolean gtk_text_child_anchor_get_deleted (GtkTextChildAnchor *anchor) 
gboolean
gtk_text_child_anchor_get_deleted (anchor)
	GtkTextChildAnchor *anchor
