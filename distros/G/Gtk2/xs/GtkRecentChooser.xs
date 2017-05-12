/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

static gint
gtk2perl_recent_sort_func (GtkRecentInfo *a,
			   GtkRecentInfo *b,
			   gpointer       user_data)
{
  GPerlCallback *callback = (GPerlCallback *) user_data;
  GValue value = { 0, };
  gint retval;

  g_value_init (&value, callback->return_type);

  gperl_callback_invoke (callback, &value, a, b);
  retval = g_value_get_int (&value);

  g_value_unset (&value);

  return retval;
}

static GPerlCallback *
gtk2perl_recent_sort_func_create (SV *func,
				  SV *data)
{
  GType param_types[2];

  param_types[0] = GTK_TYPE_RECENT_INFO;
  param_types[1] = GTK_TYPE_RECENT_INFO;

  return gperl_callback_new (func, data,
		  	     G_N_ELEMENTS (param_types), param_types,
			     G_TYPE_INT);
}

MODULE = Gtk2::RecentChooser	PACKAGE = Gtk2::RecentChooser	PREFIX = gtk_recent_chooser_


=for enum GtkRecentSortType
=cut

=for enum GtkRecentChooserError
=cut

#
# Configuration
#
void
gtk_recent_chooser_set_show_private (GtkRecentChooser *chooser, gboolean show_private)

gboolean
gtk_recent_chooser_get_show_private (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_show_not_found (GtkRecentChooser *chooser, gboolean show_not_found)

gboolean
gtk_recent_chooser_get_show_not_found (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_select_multiple (GtkRecentChooser *chooser, gboolean select_multiple)

gboolean
gtk_recent_chooser_get_select_multiple (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_limit (GtkRecentChooser *chooser, gint limit)

gint
gtk_recent_chooser_get_limit (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_local_only (GtkRecentChooser *chooser, gboolean local_only)

gboolean
gtk_recent_chooser_get_local_only (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_show_tips (GtkRecentChooser *chooser, gboolean show_tips)

gboolean
gtk_recent_chooser_get_show_tips (GtkRecentChooser *chooser)

# these are a gtk mistake, and we should not bind them.
##void
##gtk_recent_chooser_set_show_numbers (GtkRecentChooser *chooser, gboolean show_numbers)
##
##gboolean
##gtk_recent_chooser_get_show_numbers (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_show_icons (GtkRecentChooser *chooser, gboolean show_icons)

gboolean
gtk_recent_chooser_get_show_icons (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_sort_type (GtkRecentChooser *chooser, GtkRecentSortType sort_type)

GtkRecentSortType
gtk_recent_chooser_get_sort_type (GtkRecentChooser *chooser)

void
gtk_recent_chooser_set_sort_func (chooser, sort_func, sort_data=NULL)
	GtkRecentChooser *chooser
	SV *sort_func
	SV *sort_data
    PREINIT:
        GPerlCallback *func;
    CODE:
        func = gtk2perl_recent_sort_func_create (sort_func, sort_data);
	gtk_recent_chooser_set_sort_func (chooser,
					  gtk2perl_recent_sort_func,
					  func,
					  (GDestroyNotify) gperl_callback_destroy);

#
# Items handling
#
=for apidoc __gerror__
=cut
void
gtk_recent_chooser_set_current_uri (GtkRecentChooser *chooser, const gchar *uri)
    PREINIT:
        GError *error = NULL;
    CODE:
        gtk_recent_chooser_set_current_uri (chooser, uri, &error);
	if (error)
		gperl_croak_gerror (NULL, error);

gchar_own *
gtk_recent_chooser_get_current_uri (GtkRecentChooser *chooser)

GtkRecentInfo *
gtk_recent_chooser_get_current_item (GtkRecentChooser *chooser)

=for apidoc __gerror__
=cut
void
gtk_recent_chooser_select_uri (GtkRecentChooser *chooser, const gchar *uri)
    PREINIT:
        GError *error = NULL;
    CODE:
        gtk_recent_chooser_select_uri (chooser, uri, &error);
	if (error)
		gperl_croak_gerror (NULL, error);

void
gtk_recent_chooser_unselect_uri (GtkRecentChooser *chooser, const gchar *uri)

void
gtk_recent_chooser_select_all (GtkRecentChooser *chooser)

void
gtk_recent_chooser_unselect_all (GtkRecentChooser *chooser)

=for apidoc
=for signature (list) = $chooser->get_items
=cut
void
gtk_recent_chooser_get_items (GtkRecentChooser *chooser)
    PREINIT:
        GList *items, *l;
    PPCODE:
        items = gtk_recent_chooser_get_items (chooser);

	for (l = items; l != NULL; l = l->next)
		XPUSHs (sv_2mortal (newSVGtkRecentInfo_own (l->data)));

	g_list_free (items);

=for apidoc
=for signature (list) = $chooser->get_uris
=cut
void
gtk_recent_chooser_get_uris (GtkRecentChooser *chooser)
    PREINIT:
        gchar **uris;
	gsize length, i;
    PPCODE:
        uris = gtk_recent_chooser_get_uris (chooser, &length);
	if (length == 0)
		XSRETURN_EMPTY;

	EXTEND (SP, length);
	for (i = 0; i < length; i++)
		PUSHs (sv_2mortal (newSVGChar (uris[i])));

	g_strfreev (uris);

#
# Filters
#
void
gtk_recent_chooser_add_filter (GtkRecentChooser *chooser, GtkRecentFilter *filter)

void
gtk_recent_chooser_remove_filter (GtkRecentChooser *chooser, GtkRecentFilter *filter)

=for apidoc
=for signature (filters) = $chooser->list_filters
=cut
void
gtk_recent_chooser_list_filters (GtkRecentChooser *chooser)
    PREINIT:
        GSList *filters, *i;
    PPCODE:
        filters = gtk_recent_chooser_list_filters (chooser);
	for (i = filters; i != NULL; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkRecentFilter (i->data)));
	g_slist_free (filters);

void
gtk_recent_chooser_set_filter (GtkRecentChooser *chooser, GtkRecentFilter *filter)

GtkRecentFilter *
gtk_recent_chooser_get_filter (GtkRecentChooser *chooser)
