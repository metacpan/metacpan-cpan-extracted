/*
 * Copyright (c) 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::Activatable	PACKAGE = Gtk2::Activatable	PREFIX = gtk_activatable_

void gtk_activatable_do_set_related_action (GtkActivatable *activatable, GtkAction *action);

GtkAction_ornull * gtk_activatable_get_related_action (GtkActivatable *activatable);

gboolean gtk_activatable_get_use_action_appearance (GtkActivatable *activatable);

void gtk_activatable_sync_action_properties (GtkActivatable *activatable, GtkAction *action);

void gtk_activatable_set_related_action (GtkActivatable *activatable, GtkAction *action);

void gtk_activatable_set_use_action_appearance (GtkActivatable *activatable, gboolean use_appearance);
