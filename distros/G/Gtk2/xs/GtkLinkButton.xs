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
gtk2perl_link_button_uri_func_create (SV * func,
                                      SV * data)
{
	GType param_types[2];
	param_types[0] = GTK_TYPE_LINK_BUTTON;
	param_types[1] = G_TYPE_STRING;
	return gperl_callback_new (func, data, G_N_ELEMENTS (param_types),
				   param_types, G_TYPE_NONE);
}

static void
gtk2perl_link_button_uri_func (GtkLinkButton *button,
                               const gchar *link,
                               gpointer user_data)
{
	GPerlCallback * callback = (GPerlCallback*) user_data;

	gperl_callback_invoke (callback, NULL, button, link);
}

MODULE = Gtk2::LinkButton	PACKAGE = Gtk2::LinkButton	PREFIX = gtk_link_button_

GtkWidget *
gtk_link_button_new (class, const gchar *url, const gchar *label=NULL)
    ALIAS:
        new_with_label = 1
    CODE:
        PERL_UNUSED_VAR (ix);
        if (label)
                RETVAL = gtk_link_button_new_with_label (url, label);
        else
                RETVAL = gtk_link_button_new (url);
    OUTPUT:
        RETVAL

const gchar *gtk_link_button_get_uri (GtkLinkButton *link_button);

void gtk_link_button_set_uri (GtkLinkButton *link_button, const gchar *uri);

=for apidoc
Pass undef for I<func> to unset the URI hook.

Note that the current implementation does B<not> return the old hook function.
This means that there is no way to restore an old hook once you overwrote it.
=cut
## GtkLinkButtonUriFunc gtk_link_button_set_uri_hook (GtkLinkButtonUriFunc func, gpointer data, GDestroyNotify destroy);
void
gtk_link_button_set_uri_hook (class, SV *func, SV *data=NULL)
    CODE:
        if (!gperl_sv_is_defined (func)) {
		gtk_link_button_set_uri_hook (NULL, NULL, NULL);
	} else {
		GPerlCallback * callback;
		callback = gtk2perl_link_button_uri_func_create (func, data);
		gtk_link_button_set_uri_hook
			(gtk2perl_link_button_uri_func,
			 callback,
			 (GDestroyNotify) gperl_callback_destroy);
	}

#if GTK_CHECK_VERSION (2, 14, 0)

gboolean gtk_link_button_get_visited (GtkLinkButton *link_button);

void gtk_link_button_set_visited (GtkLinkButton *link_button, gboolean visited);

#endif /* 2.14 */
