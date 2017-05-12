/*
 * Copyright (c) 2003-2006, 2009 by the gtk2-perl team (see the file AUTHORS)
 *
 * Licensed under the LGPL, see LICENSE file for more information.
 *
 * $Id$
 */

#include "gtk2perl.h"

MODULE = Gtk2::Action	PACKAGE = Gtk2::Action	PREFIX = gtk_action_

=for position post_interfaces

=head1 CONSTRUCTOR

=head2 action = Gtk2::Action->B<new> (key=>value,...)

Create and return a new action object.  Note that this is the C<new>
of L<Glib::Object|Glib::Object>, not C<gtk_action_new>.  Eg.

    Gtk2::Action->new (name => 'open-foo',
		       stock_id => 'gtk-open',
		       tooltip => 'Start a foo');

The keyword/value style is more flexible and a little clearer than the
four direct arguments of C<gtk_action_new> (and also works better for
subclasses).

=cut

const gchar* gtk_action_get_name (GtkAction *action);

void gtk_action_activate (GtkAction *action);

gboolean gtk_action_is_sensitive (GtkAction *action);

gboolean gtk_action_get_sensitive (GtkAction *action);

gboolean gtk_action_is_visible (GtkAction *action);

gboolean gtk_action_get_visible (GtkAction *action);

GtkWidget* gtk_action_create_icon (GtkAction *action, GtkIconSize icon_size);

GtkWidget* gtk_action_create_menu_item (GtkAction *action);

#if GTK_CHECK_VERSION (2, 12, 0)

GtkWidget* gtk_action_create_menu (GtkAction *action);

#endif

GtkWidget* gtk_action_create_tool_item (GtkAction *action);

void gtk_action_connect_proxy (GtkAction *action, GtkWidget *proxy);

void gtk_action_disconnect_proxy (GtkAction *action, GtkWidget *proxy);

void gtk_action_get_proxies (GtkAction *action);
    PREINIT:
	GSList * i;
    PPCODE:
	for (i = gtk_action_get_proxies (action) ; i != NULL ; i = i->next)
		/* We can't use newSVGtkWidget here because it always sinks the
		 * widget.  gtk_action_get_proxies might return floating
		 * widgets though, and with newSVGtkWidget we would end up
		 * owning them.  When the SV wrapper then goes out of scope,
		 * the widgets would be destroyed -- and GtkAction would hold
		 * on to dangling pointers. */
		XPUSHs (sv_2mortal (gperl_new_object (G_OBJECT (i->data), FALSE)));

void gtk_action_connect_accelerator (GtkAction *action);

void gtk_action_disconnect_accelerator (GtkAction *action);

## /* protected ... for use by child actions */
void gtk_action_block_activate_from (GtkAction *action, GtkWidget *proxy);

void gtk_action_unblock_activate_from (GtkAction *action, GtkWidget *proxy);

## /* protected ... for use by action groups */
void gtk_action_set_accel_path (GtkAction *action, const gchar *accel_path);

void gtk_action_set_accel_group (GtkAction *action, GtkAccelGroup_ornull *accel_group);

#if GTK_CHECK_VERSION (2, 6, 0)

void gtk_action_set_sensitive (GtkAction *action, gboolean sensitive);

void gtk_action_set_visible (GtkAction *action, gboolean visible);

const gchar* gtk_action_get_accel_path (GtkAction *action);

#endif

#if GTK_CHECK_VERSION (2, 16, 0)

void gtk_action_set_label (GtkAction *action, const gchar *label);

const gchar_ornull * gtk_action_get_label (GtkAction *action);

void gtk_action_set_short_label (GtkAction *action, const gchar *short_label);

const gchar_ornull * gtk_action_get_short_label (GtkAction *action);

void gtk_action_set_tooltip (GtkAction *action, const gchar_ornull *tooltip);

const gchar_ornull * gtk_action_get_tooltip (GtkAction *action);

void gtk_action_set_stock_id (GtkAction *action,const gchar_ornull *stock_id);

const gchar_ornull * gtk_action_get_stock_id (GtkAction *action);

void gtk_action_set_icon_name (GtkAction *action, const gchar_ornull *icon_name);

const gchar_ornull * gtk_action_get_icon_name (GtkAction *action);

void gtk_action_set_visible_horizontal (GtkAction *action, gboolean visible_horizontal);

gboolean gtk_action_get_visible_horizontal (GtkAction *action);

void gtk_action_set_visible_vertical (GtkAction *action, gboolean visible_vertical);

gboolean gtk_action_get_visible_vertical (GtkAction *action);

void gtk_action_set_is_important (GtkAction *action, gboolean is_important);

gboolean gtk_action_get_is_important (GtkAction *action);

# FIXME GIcon not in typemap
# void gtk_action_set_gicon (GtkAction *action, GIcon *icon);
#
# GIcon * gtk_action_get_gicon (GtkAction *action);

void gtk_action_block_activate (GtkAction *action);

void gtk_action_unblock_activate (GtkAction *action);

#endif

#if GTK_CHECK_VERSION (2, 20, 0)

gboolean gtk_action_get_always_show_image (GtkAction *action);

void gtk_action_set_always_show_image (GtkAction *action, gboolean always_show);

#endif /* 2.20 */


#if GTK_CHECK_VERSION (2, 10, 0)

MODULE = Gtk2::Action	PACKAGE = Gtk2::Widget	PREFIX = gtk_widget_

GtkAction_ornull * gtk_widget_get_action (GtkWidget *widget);

#endif

