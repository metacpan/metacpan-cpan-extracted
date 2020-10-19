/*
 * Copyright (C) 2004 by the gtk2-perl team
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

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::ItemTool	PACKAGE = Gnome2::Dia::ItemTool	PREFIX = dia_item_tool_

##  DiaTool * dia_handle_tool_new (void)
DiaTool_noinc *
dia_item_tool_new (class)
    C_ARGS:
	/* void */
