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

MODULE = Gtk2::Arrow	PACKAGE = Gtk2::Arrow	PREFIX = gtk_arrow_

=for enum GtkArrowType
=cut

=for enum GtkShadowType
=cut

## GtkWidget* gtk_arrow_new (GtkArrowType arrow_type, GtkShadowType shadow_type)
GtkWidget *
gtk_arrow_new (class, arrow_type, shadow_type)
	GtkArrowType    arrow_type
	GtkShadowType   shadow_type
    C_ARGS:
	arrow_type, shadow_type

## void gtk_arrow_set (GtkArrow *arrow, GtkArrowType arrow_type, GtkShadowType shadow_type)
void
gtk_arrow_set (arrow, arrow_type, shadow_type)
	GtkArrow      * arrow
	GtkArrowType    arrow_type
	GtkShadowType   shadow_type

