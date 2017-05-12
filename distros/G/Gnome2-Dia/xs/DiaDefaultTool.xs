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
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaDefaultTool.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::DefaultTool	PACKAGE = Gnome2::Dia::DefaultTool	PREFIX = dia_default_tool_

##  DiaTool * dia_default_tool_new (void)
DiaTool_noinc *
dia_default_tool_new (class)
    C_ARGS:
	/* void */

##  void dia_default_tool_set_handle_tool (DiaDefaultTool *tool, DiaTool *handle_tool)
void
dia_default_tool_set_handle_tool (tool, handle_tool)
	DiaDefaultTool *tool
	DiaTool *handle_tool

##  DiaTool * dia_default_tool_get_handle_tool (DiaDefaultTool *tool)
DiaTool *
dia_default_tool_get_handle_tool (tool)
	DiaDefaultTool *tool

##  void dia_default_tool_set_item_tool (DiaDefaultTool *tool, DiaTool *item_tool)
void
dia_default_tool_set_item_tool (tool, item_tool)
	DiaDefaultTool *tool
	DiaTool *item_tool

##  DiaTool * dia_default_tool_get_item_tool (DiaDefaultTool *tool)
DiaTool *
dia_default_tool_get_item_tool (tool)
	DiaDefaultTool *tool

##  void dia_default_tool_set_selection_tool (DiaDefaultTool *tool, DiaTool *selection_tool)
void
dia_default_tool_set_selection_tool (tool, selection_tool)
	DiaDefaultTool *tool
	DiaTool *selection_tool

##  DiaTool * dia_default_tool_get_selection_tool (DiaDefaultTool *tool)
DiaTool *
dia_default_tool_get_selection_tool (tool)
	DiaDefaultTool *tool
