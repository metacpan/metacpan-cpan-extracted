/*
 * Copyright (c) 2009 by the gtk2-perl team (see the file AUTHORS)
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
 */

#include "gtk2perl.h"

MODULE = Gtk2::Orientable	PACKAGE = Gtk2::Orientable	PREFIX = gtk_orientable_

=for object Gtk2::Orientable - Interface for flippable widgets
=cut

GtkOrientation gtk_orientable_get_orientation (GtkOrientable *orientable);

void gtk_orientable_set_orientation (GtkOrientable *orientable, GtkOrientation orientation);
