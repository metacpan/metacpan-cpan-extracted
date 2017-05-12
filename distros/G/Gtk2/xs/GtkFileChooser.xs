/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::FileChooser PACKAGE = Gtk2::FileChooser PREFIX = gtk_file_chooser_

=for enum GtkFileChooserAction
=cut

=for enum GtkFileChooserError
=cut

## Configuration
##
void gtk_file_chooser_set_action (GtkFileChooser *chooser, GtkFileChooserAction action);

GtkFileChooserAction gtk_file_chooser_get_action (GtkFileChooser *chooser);

void gtk_file_chooser_set_local_only (GtkFileChooser *chooser, gboolean files_only);

gboolean gtk_file_chooser_get_local_only (GtkFileChooser *chooser);

void gtk_file_chooser_set_select_multiple (GtkFileChooser *chooser, gboolean select_multiple);

gboolean gtk_file_chooser_get_select_multiple (GtkFileChooser *chooser);

## Filename manipulation
##
void gtk_file_chooser_set_current_name (GtkFileChooser *chooser, const gchar *name);

gchar_own * gtk_file_chooser_get_filename (GtkFileChooser *chooser);

gboolean gtk_file_chooser_set_filename (GtkFileChooser *chooser, const char *filename);

gboolean gtk_file_chooser_select_filename (GtkFileChooser *chooser, const char *filename);

void gtk_file_chooser_unselect_filename (GtkFileChooser *chooser, const char *filename);

void gtk_file_chooser_select_all (GtkFileChooser *chooser);

void gtk_file_chooser_unselect_all (GtkFileChooser *chooser);

void gtk_file_chooser_get_filenames (GtkFileChooser *chooser);
    PREINIT:
	GSList * names, * i;
    PPCODE:
	names = gtk_file_chooser_get_filenames (chooser);
	for (i = names ; i != NULL ; i = i->next) {
		XPUSHs (sv_2mortal (newSVGChar (i->data)));
		g_free (i->data);
	}
	g_slist_free (names);

gboolean gtk_file_chooser_set_current_folder (GtkFileChooser *chooser, const gchar *filename);

gchar_own *gtk_file_chooser_get_current_folder (GtkFileChooser *chooser);



## URI manipulation
##
gchar_own * gtk_file_chooser_get_uri (GtkFileChooser *chooser);

gboolean gtk_file_chooser_set_uri (GtkFileChooser *chooser, const char *uri);

gboolean gtk_file_chooser_select_uri (GtkFileChooser *chooser, const char *uri);

void gtk_file_chooser_unselect_uri (GtkFileChooser *chooser, const char *uri);

void gtk_file_chooser_get_uris (GtkFileChooser *chooser);
    PREINIT:
	GSList * uris, * i;
    PPCODE:
	uris = gtk_file_chooser_get_uris (chooser);
	for (i = uris ; i != NULL ; i = i->next) {
		XPUSHs (sv_2mortal (newSVGChar (i->data)));
		g_free (i->data);
	}
	g_slist_free (uris);



gboolean gtk_file_chooser_set_current_folder_uri (GtkFileChooser *chooser, const gchar *uri);

gchar_own *gtk_file_chooser_get_current_folder_uri (GtkFileChooser *chooser);



## Preview widget
##

void gtk_file_chooser_set_preview_widget (GtkFileChooser *chooser, GtkWidget *preview_widget);

GtkWidget *gtk_file_chooser_get_preview_widget (GtkFileChooser *chooser);

void gtk_file_chooser_set_preview_widget_active (GtkFileChooser *chooser, gboolean active);

gboolean gtk_file_chooser_get_preview_widget_active (GtkFileChooser *chooser);



## char *gtk_file_chooser_get_preview_filename (GtkFileChooser *file_chooser);
GPerlFilename_own gtk_file_chooser_get_preview_filename (GtkFileChooser *file_chooser);
    CODE:
	RETVAL = gtk_file_chooser_get_preview_filename (file_chooser);
	if (!RETVAL)
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

## char *gtk_file_chooser_get_preview_uri (GtkFileChooser *file_chooser);
gchar_own *gtk_file_chooser_get_preview_uri (GtkFileChooser *file_chooser);
    CODE:
	RETVAL = gtk_file_chooser_get_preview_uri (file_chooser);
	if (!RETVAL)
		XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

void gtk_file_chooser_set_use_preview_label (GtkFileChooser *chooser, gboolean use_label);

gboolean gtk_file_chooser_get_use_preview_label (GtkFileChooser *chooser);


## Extra widget
##
void gtk_file_chooser_set_extra_widget (GtkFileChooser *chooser, GtkWidget *extra_widget);

GtkWidget *gtk_file_chooser_get_extra_widget (GtkFileChooser *chooser);

## List of user selectable filters
##
void gtk_file_chooser_add_filter (GtkFileChooser *chooser, GtkFileFilter *filter);

void gtk_file_chooser_remove_filter (GtkFileChooser *chooser, GtkFileFilter *filter);

void gtk_file_chooser_list_filters (GtkFileChooser *chooser);
    PREINIT:
	GSList * filters, * i;
    PPCODE:
	filters = gtk_file_chooser_list_filters (chooser);
	for (i = filters ; i != NULL ; i = i->next)
		XPUSHs (sv_2mortal (newSVGtkFileFilter (i->data)));
	g_slist_free (filters);

## Current filter
##
void gtk_file_chooser_set_filter (GtkFileChooser *chooser, GtkFileFilter *filter);

GtkFileFilter *gtk_file_chooser_get_filter (GtkFileChooser *chooser);

## Per-application shortcut folders

=for apidoc __gerror__
=cut
void
gtk_file_chooser_add_shortcut_folder (GtkFileChooser *chooser, const char *folder);
    ALIAS:
	add_shortcut_folder        = 0
	remove_shortcut_folder     = 1
	add_shortcut_folder_uri    = 2
	remove_shortcut_folder_uri = 3
    PREINIT:
	GError * error = NULL;
	gboolean ret = FALSE;
    CODE:
	switch (ix) {
	    case 0: ret = gtk_file_chooser_add_shortcut_folder (chooser, folder, &error); break;
	    case 1: ret = gtk_file_chooser_remove_shortcut_folder (chooser, folder, &error); break;
	    case 2: ret = gtk_file_chooser_add_shortcut_folder_uri (chooser, folder, &error); break;
	    case 3: ret = gtk_file_chooser_remove_shortcut_folder_uri (chooser, folder, &error); break;
	    default:
		g_assert_not_reached ();
	}
	if (!ret)
		gperl_croak_gerror (NULL, error);

## GSList *gtk_file_chooser_list_shortcut_folders (GtkFileChooser *chooser);
## GSList *gtk_file_chooser_list_shortcut_folder_uris (GtkFileChooser *chooser);

void gtk_file_chooser_list_shortcut_folders (GtkFileChooser *chooser);
    ALIAS:
	list_shortcut_folders     = 0
	list_shortcut_folder_uris = 1
    PREINIT:
	GSList * slist, * i;
    PPCODE:
	if (ix == 0)
		slist = gtk_file_chooser_list_shortcut_folders (chooser);
	else
		slist = gtk_file_chooser_list_shortcut_folder_uris (chooser);
	for (i = slist ; i != NULL ; i = i->next) {
		XPUSHs (sv_2mortal (newSVGChar (i->data)));
		g_free (i->data);
	}
	g_slist_free (slist);

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_file_chooser_set_show_hidden (GtkFileChooser *chooser, gboolean show_hidden)

gboolean gtk_file_chooser_get_show_hidden (GtkFileChooser *chooser)

#endif

#if GTK_CHECK_VERSION (2, 8, 0)

void gtk_file_chooser_set_do_overwrite_confirmation (GtkFileChooser *chooser, gboolean do_overwrite_confirmation);

gboolean gtk_file_chooser_get_do_overwrite_confirmation (GtkFileChooser *chooser);

#endif

#if GTK_CHECK_VERSION (2, 18, 0)

void gtk_file_chooser_set_create_folders (GtkFileChooser *chooser, gboolean create_folders);

gboolean gtk_file_chooser_get_create_folders (GtkFileChooser *chooser);

#endif

