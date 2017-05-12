/*
 * Copyright (c) 2006 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
 * Boston, MA  02110-1301  USA.
 *
 * $Id$
 */

#include "gtk2perl.h"


static GPerlCallback *
gtk2perl_assistant_page_func_create (SV * func,
                                     SV * data)
{
	GType param_types[1];
	param_types[0] = G_TYPE_INT;

	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
	                           param_types, G_TYPE_INT);
}

static gint
gtk2perl_assistant_page_func (gint current_page,
                              gpointer data)
{
	GPerlCallback *callback = (GPerlCallback*) data;
	GValue value = {0, };
	gint retval;

	g_value_init (&value, G_TYPE_INT);
	retval = g_value_get_int (&value);
	gperl_callback_invoke (callback, &value, current_page);
	retval = g_value_get_int (&value);
	g_value_unset (&value);

	return retval;
}


MODULE = Gtk2::Assistant	PACKAGE = Gtk2::Assistant	PREFIX = gtk_assistant_

##struct _GtkAssistant
##{
##  GtkWindow  parent;
##
##  GtkWidget *cancel;
##  GtkWidget *forward;
##  GtkWidget *back;
##  GtkWidget *apply;
##  GtkWidget *close;
##  GtkWidget *last;
##
##  /*< private >*/
##  GtkAssistantPrivate *priv;
##};
GtkWidget_ornull *
get_cancel_button (GtkAssistant * assistant)
    ALIAS:
	get_forward_button = 1
	get_back_button = 2
	get_apply_button = 3
	get_close_button = 4
	get_last_button = 5
    CODE:
	switch (ix) {
	    case 0:	RETVAL = assistant->cancel;	break;
	    case 1:	RETVAL = assistant->forward;	break;
	    case 2:	RETVAL = assistant->back;	break;
	    case 3:	RETVAL = assistant->apply;	break;
	    case 4:	RETVAL = assistant->close;	break;
	    case 5:	RETVAL = assistant->last;	break;

	    default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL


GtkWidget * gtk_assistant_new (class);
    C_ARGS:
        /*void*/

gint gtk_assistant_get_current_page (GtkAssistant *assistant);

void gtk_assistant_set_current_page (GtkAssistant *assistant, gint page_num);

gint gtk_assistant_get_n_pages (GtkAssistant *assistant);

GtkWidget *gtk_assistant_get_nth_page (GtkAssistant *assistant, gint page_num);

gint gtk_assistant_prepend_page (GtkAssistant *assistant, GtkWidget *page);

gint gtk_assistant_append_page (GtkAssistant *assistant, GtkWidget *page);

gint gtk_assistant_insert_page (GtkAssistant *assistant, GtkWidget *page, gint position);

## void gtk_assistant_set_forward_page_func (GtkAssistant *assistant, GtkAssistantPageFunc page_func, gpointer data, GDestroyNotify destroy);
void gtk_assistant_set_forward_page_func (GtkAssistant *assistant, SV * func, SV * data=NULL);
    PREINIT:
        GPerlCallback * callback;
    CODE:
        callback = gtk2perl_assistant_page_func_create (func, data);
	gtk_assistant_set_forward_page_func
		(assistant,
		 gtk2perl_assistant_page_func, callback,
		 (GDestroyNotify) gperl_callback_destroy);

void gtk_assistant_set_page_type (GtkAssistant *assistant, GtkWidget *page, GtkAssistantPageType type);

GtkAssistantPageType gtk_assistant_get_page_type (GtkAssistant *assistant, GtkWidget *page);

void gtk_assistant_set_page_title (GtkAssistant *assistant, GtkWidget *page, const gchar *title);

const gchar *gtk_assistant_get_page_title (GtkAssistant *assistant, GtkWidget *page);

void gtk_assistant_set_page_header_image (GtkAssistant *assistant, GtkWidget *page, GdkPixbuf *pixbuf);

GdkPixbuf *gtk_assistant_get_page_header_image (GtkAssistant *assistant, GtkWidget *page);

void gtk_assistant_set_page_side_image (GtkAssistant *assistant, GtkWidget *page, GdkPixbuf *pixbuf);

GdkPixbuf *gtk_assistant_get_page_side_image (GtkAssistant *assistant, GtkWidget *page);

void gtk_assistant_set_page_complete (GtkAssistant *assistant, GtkWidget *page, gboolean complete);

gboolean gtk_assistant_get_page_complete (GtkAssistant *assistant, GtkWidget *page);

void gtk_assistant_add_action_widget (GtkAssistant *assistant, GtkWidget *child);

void gtk_assistant_remove_action_widget (GtkAssistant *assistant, GtkWidget *child);

void gtk_assistant_update_buttons_state (GtkAssistant *assistant);

#if GTK_CHECK_VERSION (2, 22, 0)

void gtk_assistant_commit (GtkAssistant *assistant);

#endif /* 2.22 */
