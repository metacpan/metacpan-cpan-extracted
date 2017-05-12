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

MODULE = Gtk2::HScrollbar	PACKAGE = Gtk2::HScrollbar	PREFIX = gtk_hscrollbar_

## GtkWidget* gtk_hscrollbar_new (GtkAdjustment *adjustment)
GtkWidget *
gtk_hscrollbar_new (class, adjustment=NULL)
	GtkAdjustment_ornull * adjustment
    ALIAS:
	Gtk2::HScrollBar::new = 1
    C_ARGS:
	adjustment
    CLEANUP:
	PERL_UNUSED_VAR (ix);


=for apidoc Gtk2::HScrollBar::new

A typo in days long past resulted in the package names for Gtk2::HScrollbar
and Gtk2::VScrollbar being misspelled with a capital C<B>, despite the fact
that only the proper name (with the small C<b>) was actually registered
with the Glib type system.  For backward compatibility with Gtk2-1.00,
Gtk2::HScrollBar->new calls Gtk2::HScrollbar->new without complaint.

=cut
