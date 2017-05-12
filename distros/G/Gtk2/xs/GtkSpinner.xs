/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::Spinner	PACKAGE = Gtk2::Spinner	PREFIX = gtk_spinner_

GtkWidget *
gtk_spinner_new (class)
    C_ARGS:
	/* void */

void gtk_spinner_start (GtkSpinner *spinner);

void gtk_spinner_stop (GtkSpinner *spinner);
