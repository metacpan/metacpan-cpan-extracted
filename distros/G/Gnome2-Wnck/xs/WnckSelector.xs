/*
 * Copyright (C) 2006 by the gtk2-perl team
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see
 * <https://www.gnu.org/licenses/>.
 *
 * $Id$
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Selector	PACKAGE = Gnome2::Wnck::Selector	PREFIX = wnck_selector_

=for object Gnome2::Wnck::Selector - a window selector widget, showing the list of windows as a menu

=cut

# GtkWidget *wnck_selector_new (void);
GtkWidget *wnck_selector_new (class)
    C_ARGS:
	/* void */
