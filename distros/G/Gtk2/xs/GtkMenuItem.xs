/*
 * Copyright (c) 2003, 2010 by the gtk2-perl team (see the file AUTHORS)
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
#include <gperl_marshal.h>

/*

  void (* toggle_size_request)  (GtkMenuItem *menu_item,
                                 gint        *requisition);

*/

static void
gtk2perl_menu_item_toggle_size_request_marshal (GClosure * closure,
                                                GValue * return_value,
                                                guint n_param_values,
                                                const GValue * param_values,
                                                gpointer invocation_hint,
                                                gpointer marshal_data)
{
	gint * requisition;
	dGPERL_CLOSURE_MARSHAL_ARGS;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	PERL_UNUSED_VAR (return_value);
	PERL_UNUSED_VAR (n_param_values);
	PERL_UNUSED_VAR (invocation_hint);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	requisition = g_value_get_pointer (param_values+1);

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_SCALAR);

	if (count == 1) {
		*requisition = POPi;
	} else {
		/* NOTE: croaking here can cause bad things to happen to the
		 * app, because croaking in signal handlers is bad juju. */
		croak ("an toggle-size-request signal handler must return one "
		       "item (the requisition), but the callback returned %d "
		       "items", count);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;
}

MODULE = Gtk2::MenuItem	PACKAGE = Gtk2::MenuItem	PREFIX = gtk_menu_item_

=for position DESCRIPTION

=head1 DESCRIPTION

If a MenuItem is created with a C<$label> string, or if the C<label>
property is set later, then it should be destroyed with
C<< $item->destroy >>.  Just dropping the last Perl ref is not enough
because (as of Gtk through to 2.18) there's a circular reference from
the child C<Gtk2::AccelLabel> back up to the item (the C<accel-widget>
property).

When a MenuItem is in a C<Gtk2::Menu> a C<destroy> happens
automatically.  Dropping the last ref to a Menu calls C<destroy> on
its children, as usual for a container.  But if you remove a MenuItem
with a label from a menu (or never add it to one) then be sure to
C<< $item->destroy >> explicitly.

=cut

BOOT:
	gperl_signal_set_marshaller_for (GTK_TYPE_MENU_ITEM, "toggle_size_request",
	                                 gtk2perl_menu_item_toggle_size_request_marshal);

=for apidoc Gtk2::MenuItem::new
If a C<$label> argument is given then this is C<new_with_mnemonic>.
=cut
GtkWidget*
gtk_menu_item_new (class, label=NULL)
	const gchar * label
    ALIAS:
	Gtk2::MenuItem::new_with_mnemonic = 1
	Gtk2::MenuItem::new_with_label = 2
    CODE:
	if (label) {
		if (ix == 2)
			RETVAL = gtk_menu_item_new_with_label (label);
		else
			RETVAL = gtk_menu_item_new_with_mnemonic (label);
	} else
		RETVAL = gtk_menu_item_new ();
    OUTPUT:
	RETVAL

void
gtk_menu_item_set_submenu (menu_item, submenu)
	GtkMenuItem *menu_item
	GtkWidget_ornull *submenu

GtkWidget_ornull*
gtk_menu_item_get_submenu (menu_item)
	GtkMenuItem *menu_item

void
gtk_menu_item_remove_submenu (menu_item)
	GtkMenuItem *menu_item

void
gtk_menu_item_select (menu_item)
	GtkMenuItem *menu_item

void
gtk_menu_item_deselect (menu_item)
	GtkMenuItem *menu_item

void
gtk_menu_item_activate (menu_item)
	GtkMenuItem *menu_item

void gtk_menu_item_toggle_size_request (GtkMenuItem *menu_item, OUTLIST gint requisition)

void
gtk_menu_item_toggle_size_allocate (menu_item, allocation)
	GtkMenuItem *menu_item
	gint allocation

void
gtk_menu_item_set_right_justified (menu_item, right_justified)
	GtkMenuItem *menu_item
	gboolean right_justified

gboolean
gtk_menu_item_get_right_justified (menu_item)
	GtkMenuItem *menu_item

void
gtk_menu_item_set_accel_path (menu_item, accel_path)
	GtkMenuItem *menu_item
	const gchar *accel_path

 ##void _gtk_menu_item_refresh_accel_path (GtkMenuItem *menu_item, const gchar *prefix, GtkAccelGroup *accel_group, gboolean group_changed)

#if GTK_CHECK_VERSION (2, 14, 0)

const gchar* gtk_menu_item_get_accel_path (GtkMenuItem *menu_item);

#endif /* 2.14 */

#if GTK_CHECK_VERSION (2, 16, 0)

gboolean
gtk_menu_item_get_use_underline (GtkMenuItem *menu_item)

void
gtk_menu_item_set_use_underline (GtkMenuItem *menu_item, gboolean use_underline)

const gchar * gtk_menu_item_get_label (GtkMenuItem *menu_item);

void gtk_menu_item_set_label (GtkMenuItem *menu_item, const gchar *label);

#endif /* 2.16 */

