/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::ToggleAction	PACKAGE = Gtk2::ToggleAction	PREFIX = gtk_toggle_action_

=for position SYNOPSIS

=head1 SYNOPSIS

  my $action = Gtk2::ToggleAction->new (name => 'one',
                                        tooltip => 'One');

=for position DESCRIPTION

=head1 DESCRIPTION

Note that C<new> is the plain L<Glib::Object> C<new> (see
L<Gtk2::Action>).  The name, label, tooltip and stock_id arguments of
the C code C<gtk_toggle_action_new()> can be given as key/value pairs,
plus other property values like active or sensitive.

=cut

void gtk_toggle_action_toggled (GtkToggleAction *action);

void gtk_toggle_action_set_active (GtkToggleAction *action, gboolean is_active);

gboolean gtk_toggle_action_get_active (GtkToggleAction *action);

void gtk_toggle_action_set_draw_as_radio (GtkToggleAction *action, gboolean draw_as_radio);

gboolean gtk_toggle_action_get_draw_as_radio (GtkToggleAction *action);

