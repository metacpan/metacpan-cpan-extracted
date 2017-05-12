/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

/*
typedef gboolean (* GtkEntryCompletionMatchFunc) (GtkEntryCompletion *completion,
                                                  const gchar        *key,
                                                  GtkTreeIter        *iter,
                                                  gpointer            user_data);
*/
static gboolean
gtk2perl_entry_completion_match_func (GtkEntryCompletion *completion,
                                      const gchar        *key,
                                      GtkTreeIter        *iter,
                                      gpointer            user_data)
{
	GPerlCallback * callback = (GPerlCallback*)user_data;
	GValue value = {0,};
	gboolean ret;

	g_value_init (&value, G_TYPE_BOOLEAN);
	gperl_callback_invoke (callback, &value, completion, key, iter);
	ret = g_value_get_boolean (&value);
	g_value_unset (&value);

	return ret;
}

MODULE = Gtk2::EntryCompletion	PACKAGE = Gtk2::EntryCompletion	PREFIX = gtk_entry_completion_

# GtkEntryCompletion is a direct GObject descendent, so we need _noinc.

GtkEntryCompletion_noinc *gtk_entry_completion_new (class)
    C_ARGS:
	/*void*/


GtkWidget *gtk_entry_completion_get_entry (GtkEntryCompletion *entry);


void gtk_entry_completion_set_model (GtkEntryCompletion *completion, GtkTreeModel_ornull *model);

GtkTreeModel *gtk_entry_completion_get_model (GtkEntryCompletion *completion);


## void gtk_entry_completion_set_match_func (GtkEntryCompletion *completion, GtkEntryCompletionMatchFunc func, gpointer func_data, GDestroyNotify func_notify);
void
gtk_entry_completion_set_match_func (GtkEntryCompletion *completion, SV * func, SV * func_data=NULL)
    PREINIT:
	GType param_types[3];
	GPerlCallback * callback;
    CODE:
	param_types[0] = GTK_TYPE_ENTRY_COMPLETION;
	param_types[1] = G_TYPE_STRING;
	param_types[2] = GTK_TYPE_TREE_ITER;

	callback = gperl_callback_new (func, func_data, 3, param_types,
	                               G_TYPE_BOOLEAN);
	gtk_entry_completion_set_match_func
	                            (completion,
	                             gtk2perl_entry_completion_match_func,
	                             callback,
	                             (GDestroyNotify) gperl_callback_destroy);

void gtk_entry_completion_set_minimum_key_length (GtkEntryCompletion *completion, gint length);

gint gtk_entry_completion_get_minimum_key_length (GtkEntryCompletion *completion);

void gtk_entry_completion_complete (GtkEntryCompletion *completion);


void gtk_entry_completion_insert_action_text (GtkEntryCompletion *completion, gint index, const gchar *text);

void gtk_entry_completion_insert_action_markup (GtkEntryCompletion *completion, gint index, const gchar *markup);

void gtk_entry_completion_delete_action (GtkEntryCompletion *completion, gint index);

##
## /* convenience */
##
void gtk_entry_completion_set_text_column (GtkEntryCompletion *completion, gint column);

#if GTK_CHECK_VERSION (2, 6, 0)

gint gtk_entry_completion_get_text_column (GtkEntryCompletion *completion);

void gtk_entry_completion_insert_prefix (GtkEntryCompletion *completion);

void gtk_entry_completion_set_inline_completion (GtkEntryCompletion *completion, gboolean inline_completion);

gboolean gtk_entry_completion_get_inline_completion (GtkEntryCompletion *completion);

void gtk_entry_completion_set_popup_completion (GtkEntryCompletion *completion, gboolean popup_completion);

gboolean gtk_entry_completion_get_popup_completion (GtkEntryCompletion *completion);

#endif

#if GTK_CHECK_VERSION(2, 8, 0)

void gtk_entry_completion_set_popup_set_width (GtkEntryCompletion *completion, gboolean popup_set_width);

gboolean gtk_entry_completion_get_popup_set_width (GtkEntryCompletion *completion);

void gtk_entry_completion_set_popup_single_match (GtkEntryCompletion *completion, gboolean popup_single_match);

gboolean gtk_entry_completion_get_popup_single_match (GtkEntryCompletion *completion);

#endif

#if GTK_CHECK_VERSION(2, 12, 0)

void gtk_entry_completion_set_inline_selection (GtkEntryCompletion *completion, gboolean inline_selection);

gboolean gtk_entry_completion_get_inline_selection (GtkEntryCompletion *completion);

const gchar_ornull *gtk_entry_completion_get_completion_prefix (GtkEntryCompletion *completion);

#endif
