/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::CellRendererSpinner	PACKAGE = Gtk2::CellRendererSpinner	PREFIX = gtk_cell_renderer_spinner_

GtkCellRenderer *
gtk_cell_renderer_spinner_new (class)
    C_ARGS:
	/* void */
