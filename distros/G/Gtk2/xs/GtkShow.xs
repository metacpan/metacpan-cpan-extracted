/*
 * Copyright (c) 2008 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::Show	PACKAGE = Gtk2	PREFIX = gtk_

=for object Gtk2::main
=cut

=for apidoc __function__
=cut
# gboolean gtk_show_uri (GdkScreen *screen, const gchar *uri, guint32 timestamp, GError **error);
void
gtk_show_uri (GdkScreen_ornull *screen, const gchar *uri, guint32 timestamp=GDK_CURRENT_TIME)
    PREINIT:
	GError *error = NULL;
    CODE:
	if (!gtk_show_uri (screen, uri, timestamp, &error)) {
		gperl_croak_gerror (NULL, error);
	}
