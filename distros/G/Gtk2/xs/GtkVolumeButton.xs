/*
 * Copyright (c) 2007 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::VolumeButton	PACKAGE = Gtk2::VolumeButton	PREFIX = gtk_volume_button_

# GtkWidget * gtk_volume_button_new (void);
GtkWidget *
gtk_volume_button_new (class)
    C_ARGS:
	/* void */
