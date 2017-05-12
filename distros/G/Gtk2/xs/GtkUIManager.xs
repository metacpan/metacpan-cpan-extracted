/*
 * Copyright (c) 2003 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::UIManager	PACKAGE = Gtk2::UIManager	PREFIX = gtk_ui_manager_

GtkUIManager_noinc *gtk_ui_manager_new (class);
    C_ARGS:
	/*void*/

void gtk_ui_manager_set_add_tearoffs (GtkUIManager *self, gboolean add_tearoffs);

gboolean gtk_ui_manager_get_add_tearoffs (GtkUIManager *self);

void gtk_ui_manager_insert_action_group (GtkUIManager *self, GtkActionGroup *action_group, gint pos);

void gtk_ui_manager_remove_action_group (GtkUIManager *self, GtkActionGroup *action_group);

void gtk_ui_manager_get_action_groups (GtkUIManager *self);
    PREINIT:
	GList * groups, * i;
    PPCODE:
	groups = gtk_ui_manager_get_action_groups (self);
	for (i = groups ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkActionGroup (i->data)));

GtkAccelGroup *gtk_ui_manager_get_accel_group (GtkUIManager *self);

GtkWidget *gtk_ui_manager_get_widget (GtkUIManager *self, const gchar *path);

## GSList *gtk_ui_manager_get_toplevels (GtkUIManager *self, GtkUIManagerItemType types);
void
gtk_ui_manager_get_toplevels (GtkUIManager *self, GtkUIManagerItemType types)
    PREINIT:
	GSList * toplevels, * i;
    PPCODE:
	toplevels = gtk_ui_manager_get_toplevels (self, types);
	for (i = toplevels ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkWidget (i->data)));
	g_slist_free (toplevels);

GtkAction *gtk_ui_manager_get_action (GtkUIManager *self, const gchar *path);

=for apidoc __gerror__
=cut
guint gtk_ui_manager_add_ui_from_string (GtkUIManager *self, const gchar_length *buffer, int length(buffer));
    PREINIT:
	GError * error = NULL;
    CODE:
	RETVAL = gtk_ui_manager_add_ui_from_string (self, buffer, STRLEN_length_of_buffer, &error);
	if (!RETVAL)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

=for apidoc __gerror__
=cut
guint gtk_ui_manager_add_ui_from_file (GtkUIManager *self, const gchar *filename);
    PREINIT:
	GError * error = NULL;
    CODE:
	RETVAL = gtk_ui_manager_add_ui_from_file (self, filename, &error);
	if (!RETVAL)
		gperl_croak_gerror (NULL, error);
    OUTPUT:
	RETVAL

void gtk_ui_manager_add_ui (GtkUIManager *self, guint merge_id, const gchar *path, const gchar *name, const gchar_ornull *action, GtkUIManagerItemType type, gboolean top);

void gtk_ui_manager_remove_ui (GtkUIManager *self, guint merge_id);

gchar_own *gtk_ui_manager_get_ui (GtkUIManager *self);

void gtk_ui_manager_ensure_update (GtkUIManager *self);

guint gtk_ui_manager_new_merge_id (GtkUIManager *self);


