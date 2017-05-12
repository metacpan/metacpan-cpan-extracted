/*
 * Copyright (c) 2004 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::CellRendererCombo	PACKAGE = Gtk2::CellRendererCombo	PREFIX = gtk_cell_renderer_combo_

##  GtkCellRenderer * gtk_cell_renderer_combo_new (void);
GtkCellRenderer *
gtk_cell_renderer_combo_new (class)
    C_ARGS:
	/* void */
