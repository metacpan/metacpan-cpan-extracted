/*
 * Copyright (c) 2007 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::RecentAction	PACKAGE = Gtk2::RecentAction	PREFIX = gtk_recent_action_

=for position SYNOPSIS

=head1 SYNOPSIS

  my $action = Gtk2::RecentAction->new (name => name,
                                        label => label,
                                        tooltip => tooltip,
                                        stock-id => stock_id,
                                        recent-manager => manager);

Note that the constructor slightly deviates from the convenience constructor in
the C API.  Instead of passing in a list of values for name, label, tooltip,
stock-id and value, you just use key => value pairs like with
Glib::Object::new.

=cut

gboolean gtk_recent_action_get_show_numbers (GtkRecentAction *action);

void gtk_recent_action_set_show_numbers (GtkRecentAction *action, gboolean show_numbers);
