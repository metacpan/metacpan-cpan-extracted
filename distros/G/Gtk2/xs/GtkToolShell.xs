/*
 * Copyright (c) 2008 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ToolShell	PACKAGE = Gtk2::ToolShell	PREFIX = gtk_tool_shell_

GtkIconSize gtk_tool_shell_get_icon_size (GtkToolShell *shell);

GtkOrientation gtk_tool_shell_get_orientation (GtkToolShell *shell);

GtkReliefStyle gtk_tool_shell_get_relief_style (GtkToolShell *shell);

GtkToolbarStyle gtk_tool_shell_get_style (GtkToolShell *shell);

void gtk_tool_shell_rebuild_menu (GtkToolShell *shell);

#if GTK_CHECK_VERSION (2, 20, 0)

PangoEllipsizeMode  gtk_tool_shell_get_ellipsize_mode   (GtkToolShell *shell);

gfloat              gtk_tool_shell_get_text_alignment   (GtkToolShell *shell);

GtkOrientation      gtk_tool_shell_get_text_orientation (GtkToolShell *shell);

GtkSizeGroup_ornull *      gtk_tool_shell_get_text_size_group  (GtkToolShell *shell);

#endif /* 2.20 */
