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
 * $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/xs/DiaHandleTool.xs,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $
 */

#include "diacanvas2perl.h"

MODULE = Gnome2::Dia::HandleTool	PACKAGE = Gnome2::Dia::HandleTool	PREFIX = dia_handle_tool_

# Should those be mutators?  Properties?
# ##  Accessors.
# gint
# glue_distance (tool)
# 	DiaHandleTool *tool
#     CODE:
# 	RETVAL = tool->glue_distance;
#     OUTPUT:
# 	RETVAL

# DiaHandle *
# grabbed_handle (tool)
# 	DiaHandleTool *tool
#     CODE:
# 	RETVAL = tool->grabbed_handle;
#     OUTPUT:
# 	RETVAL

# DiaCanvasItem *
# connect_to (tool)
# 	DiaHandleTool *tool
#     CODE:
# 	RETVAL = tool->connect_to;
#     OUTPUT:
# 	RETVAL

# DiaEventMask
# event_mask (tool)
# 	DiaHandleTool *tool
#     CODE:
# 	RETVAL = tool->event_mask;
#     OUTPUT:
# 	RETVAL

##  DiaTool * dia_handle_tool_new (void)
DiaTool_noinc *
dia_handle_tool_new (class)
    C_ARGS:
	/* void */

##  void dia_handle_tool_set_grabbed_handle (DiaHandleTool *tool, DiaHandle *handle)
void
dia_handle_tool_set_grabbed_handle (tool, handle)
	DiaHandleTool *tool
	DiaHandle *handle
