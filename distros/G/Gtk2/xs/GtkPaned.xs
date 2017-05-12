/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
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

MODULE = Gtk2::Paned	PACKAGE = Gtk2::Paned	PREFIX = gtk_paned_

=for object

Gtk2::Paned is the base class for widgets with two panes, arranged either
horizontally (Gtk2::HPaned) or vertically (Gtk2::VPaned).  Child widgets are
added to the panes of the widget with C<< $paned->pack1 >> and
C<< $paned->pack2 >>.  The division between the two children is set by default
from the size requests of the children, but it can be adjusted by the user. 

A paned widget draws a separator between the two child widgets and a small
handle that the user can drag to adjust the division.  It does not draw any
relief around the children or around the separator.  Often, it is useful to put
each child inside a Gtk2::Frame with the shadow type set to 'in' so that the
gutter appears as a ridge. 

Each child has two options that can be set, resize and shrink.  If resize is
true, then when the Gtk2::Paned is resized, that child will expand or shrink
along with the paned widget.  If shrink is true, then when that child can be
made smaller than its requisition by the user.  Setting shrink to FALSE allows
the application to set a minimum size.  If resize is false for both children,
then this is treated as if resize is true for both children. 

The application can set the position of the slider as if it were set by the
user, by calling C<< $paned->set_position >>. 

=cut

void gtk_paned_add1 (GtkPaned *paned, GtkWidget *child)

void gtk_paned_add2 (GtkPaned *paned, GtkWidget *child)

void gtk_paned_pack1 (GtkPaned *paned, GtkWidget *child, gboolean resize, gboolean shrink)

void gtk_paned_pack2 (GtkPaned *paned, GtkWidget *child, gboolean resize, gboolean shrink)

GtkWidget *
child1 (GtkPaned * paned)
    ALIAS:
	Gtk2::Paned::child2 = 1
	Gtk2::Paned::get_child1 = 2
	Gtk2::Paned::get_child2 = 3
    CODE:
	RETVAL = NULL;
	switch (ix) {
		case 0:
		case 2:
			RETVAL = paned->child1; break;
		case 1:
		case 3:
			RETVAL = paned->child2; break;
		default:
			RETVAL = NULL;
			g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

=for apidoc Gtk2::Paned::child1_resize
=for signature boolean = $paned->child1_resize
=for signature $paned->child1_resize (newval)
=for arg newval (gboolean)
C<child1_resize> determines whether the first child should expand when 
I<$paned> is resized.
=cut

=for apidoc Gtk2::Paned::child1_shrink
=for signature boolean = $paned->child1_shrink
=for signature $paned->child1_shrink (newval)
=for arg newval (gboolean)
C<child1_shrink> determines whether the first child may be made smaller
than its requisition.
=cut

=for apidoc Gtk2::Paned::child2_resize
=for signature boolean = $paned->child2_resize
=for signature $paned->child2_resize (newval)
=for arg newval (gboolean)
C<child2_resize> determines whether the second child should expand when 
I<$paned> is resized.
=cut

=for apidoc Gtk2::Paned::child2_shrink
=for signature boolean = $paned->child2_shrink
=for signature $paned->child2_shrink (newval)
=for arg newval (gboolean)
C<child2_shrink> determines whether the second child may be made smaller
than its requisition.
=cut

gboolean
child1_resize (GtkPaned * paned, SV * newval=NULL)
    ALIAS:
	Gtk2::Paned::child1_shrink = 1
	Gtk2::Paned::child2_resize = 2
	Gtk2::Paned::child2_shrink = 3
    CODE:
	switch (ix) {
		case 0: RETVAL = paned->child1_resize; break;
		case 1: RETVAL = paned->child1_shrink; break;
		case 2: RETVAL = paned->child2_resize; break;
		case 3: RETVAL = paned->child2_shrink; break;
		default:
			RETVAL = FALSE;
			g_assert_not_reached ();
	}
	if (newval) {
		gboolean newbool = SvIV (newval);
		switch (ix) {
			case 0: paned->child1_resize = newbool; break;
			case 1: paned->child1_shrink = newbool; break;
			case 2: paned->child2_resize = newbool; break;
			case 3: paned->child2_shrink = newbool; break;
			default:
				g_assert_not_reached ();
		}
	}
    OUTPUT:
	RETVAL

## gint gtk_paned_get_position (GtkPaned *paned)
gint
gtk_paned_get_position (paned)
	GtkPaned * paned

## void gtk_paned_set_position (GtkPaned *paned, gint position)
void
gtk_paned_set_position (paned, position)
	GtkPaned * paned
	gint       position

##void gtk_paned_compute_position (GtkPaned *paned, gint allocation, gint child1_req, gint child2_req)
void
gtk_paned_compute_position (paned, allocation, child1_req, child2_req)
	GtkPaned * paned
	gint       allocation
	gint       child1_req
	gint       child2_req

#if GTK_CHECK_VERSION (2, 20, 0)

GdkWindow * gtk_paned_get_handle_window (GtkPaned *paned);

#endif /* 2.20 */
