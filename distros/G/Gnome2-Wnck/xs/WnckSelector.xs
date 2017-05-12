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
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/xs/WnckSelector.xs,v 1.2 2007/08/02 20:15:43 kaffeetisch Exp $
 */

#include "wnck2perl.h"

MODULE = Gnome2::Wnck::Selector	PACKAGE = Gnome2::Wnck::Selector	PREFIX = wnck_selector_

# GtkWidget *wnck_selector_new (void);
GtkWidget *wnck_selector_new (class)
    C_ARGS:
	/* void */
