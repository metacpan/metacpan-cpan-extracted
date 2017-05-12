/*
 * Copyright 2010 by the gtk2-perl team (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, see <http://www.gnu.org/licenses/>.
 */

#include "gtk2perl.h"
#include "gtk2perl-private.h" /* for the custom response id handling */

MODULE = Gtk2::InfoBar	PACKAGE = Gtk2::InfoBar	PREFIX = gtk_info_bar_

BOOT:
	gperl_signal_set_marshaller_for (GTK_TYPE_INFO_BAR, "response",
	                                 gtk2perl_dialog_response_marshal);

=for position post_signals

Note that currently in a Perl subclass of C<Gtk2::InfoBar> a class
closure, ie. class default signal handler, for the C<response> signal
will be called with the response ID just as an integer, it's not
turned into an enum string like C<"ok"> the way a handler setup with
C<signal_connect> receives.

Hopefully this will change in the future, so don't count on it.  In
the interim the easiest thing to do is install your default handler in
C<INIT_INSTANCE> with a C<signal_connect>.  (The subtleties of what
order handlers are called in will differ, but often that doesn't
matter.)

=cut

=for enum GtkResponseType

The response type is somewhat abnormal as far as gtk2-perl enums go.  In C,
this enum lists named, predefined integer values for a field that is other
composed of whatever integer values you like.  In Perl, we allow this to
be either one of the string constants listed here or any positive integer
value.  For example, 'ok', 'cancel', 4, and 42 are all valid response ids.
You cannot use arbitrary string values, they must be integers.  Be careful,
because unknown string values tend to be mapped to 0.

=cut


=for apidoc Gtk2::InfoBar::new_with_buttons
=for signature $widget = Gtk2::InfoBar->new_with_buttons (...)
=for arg ... of button-text => response-id pairs.

Alias for the multi-argument version of C<< Gtk2::InfoBar->new >>.

=cut

=for apidoc
=for signature $widget = Gtk2::InfoBar->new;
=for signature $widget = Gtk2::InfoBar->new (...)
=for arg ... of button-text => response-id pairs.

The multi-argument form takes the same list of text => response-id pairs as
C<< $infobar->add_buttons >>.  Do not pack widgets directly into the infobar;
add them to C<< $infobar->get_content_area () >>.

Here's a simple example:

 $infobar = Gtk2::InfoBar->new ('gtk-ok'     => 'accept',
                                'gtk-cancel' => 'reject');

=cut
GtkWidget *
gtk_info_bar_new (class, ...)
    ALIAS:
	Gtk2::InfoBar::new_with_buttons = 1
    PREINIT:
	int i;
	GtkWidget * info_bar;
    CODE:
	PERL_UNUSED_VAR (ix);
	if (items == 1) {
		/* the easy way out... */
		info_bar = gtk_info_bar_new ();
	} else if ( !(items % 2) ) {
		croak ("USAGE: Gtk2::InfoBar->new ()\n"
		       "  or Gtk2::InfoBar->new (...)\n"
		       "  where ... is a series of button text and response id pairs");
	} else {
		/* we can't really pass on a varargs call (at least, i don't
		 * know how to convert from perl stack to C va_list), so we
		 * have to duplicate a bit of the functionality of the C
		 * version.  luckily it's nothing too intense. */

		info_bar = gtk_info_bar_new ();

		for (i = 1; i < items; i += 2) {
			gchar * text = SvGChar (ST (i));
			int response_id =
				gtk2perl_dialog_response_id_from_sv (ST (i+1));
			gtk_info_bar_add_button (GTK_INFO_BAR (info_bar), text,
			                         response_id);
		}
	}
	RETVAL = info_bar;
    OUTPUT:
	RETVAL


GtkWidget *
gtk_info_bar_add_button (info_bar, button_text, response_id)
	GtkInfoBar  * info_bar
	const gchar * button_text
	SV          * response_id
    CODE:
	RETVAL = gtk_info_bar_add_button (info_bar, button_text,
	                                  gtk2perl_dialog_response_id_from_sv (
	                                    response_id));
    OUTPUT:
	RETVAL

=for apidoc
=for arg ... of button-text => response-id pairs
Like calling C<< $infobar->add_button >> repeatedly, except you don't get the
created widgets back.  The buttons go from left to right, so the first button
added will be the left-most one.
=cut
void
gtk_info_bar_add_buttons (info_bar, ...)
	GtkInfoBar * info_bar
    PREINIT:
	int i;
    CODE:
	if (!(items % 2))
		croak("gtk_info_bar_add_buttons: odd number of parameters");
	/* we can't make var args, so we'll call add_button for each */
	for (i = 1; i < items; i += 2)
		gtk_info_bar_add_button (info_bar, SvGChar (ST (i)),
		                         gtk2perl_dialog_response_id_from_sv (
		                           ST (i+1)));

=for apidoc
=for arg response_id (GtkResponseType)
=cut
void
gtk_info_bar_add_action_widget (info_bar, child, response_id)
	GtkInfoBar  * info_bar
	GtkWidget   * child
	SV          * response_id
    CODE:
	gtk_info_bar_add_action_widget (info_bar, child,
	                                gtk2perl_dialog_response_id_from_sv (
	                                  response_id));

=for apidoc
=for arg response_id (GtkResponseType)
Enable or disable an action button by its I<$response_id>.
=cut
void
gtk_info_bar_set_response_sensitive (info_bar, response_id, setting)
	GtkInfoBar * info_bar
	SV         * response_id
	gboolean    setting
    CODE:
	gtk_info_bar_set_response_sensitive (
		info_bar,
		gtk2perl_dialog_response_id_from_sv (response_id),
		setting);


=for apidoc
=for arg response_id (GtkResponseType)
=cut
void
gtk_info_bar_set_default_response (info_bar, response_id)
	GtkInfoBar * info_bar
	SV         * response_id
    CODE:
	gtk_info_bar_set_default_response (info_bar,
	                                   gtk2perl_dialog_response_id_from_sv (
	                                     response_id));

=for apidoc
=for arg response_id (GtkResponseType)
=cut
void
gtk_info_bar_response (info_bar, response_id)
	GtkInfoBar * info_bar
	SV         * response_id
    C_ARGS:
	info_bar, gtk2perl_dialog_response_id_from_sv (response_id)


void
gtk_info_bar_set_message_type (info_bar, type);
	GtkInfoBar * info_bar
	GtkMessageType type

GtkMessageType
gtk_info_bar_get_message_type (info_bar);
	GtkInfoBar * info_bar

GtkWidget *
gtk_info_bar_get_action_area (info_bar)
	GtkInfoBar * info_bar

GtkWidget *
gtk_info_bar_get_content_area (info_bar)
	GtkInfoBar * info_bar


