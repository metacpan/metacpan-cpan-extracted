/*
 * Copyright (c) 2003-2006 by the gtk2-perl team (see the file AUTHORS)
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

static char *
format_message (SV * format, SV ** start, int count)
{
	/* text passed to GTK+ must be UTF-8.  force it. */
	STRLEN patlen;
	gchar * pat;
	SV * message = sv_newmortal ();

	SvUTF8_on (message);
	sv_utf8_upgrade (format);
	pat = SvPV (format, patlen);
	sv_vsetpvfn (message, pat, patlen, NULL, start, count, Null(bool*));

	return SvPV_nolen (message);
}

MODULE = Gtk2::MessageDialog	PACKAGE = Gtk2::MessageDialog	PREFIX = gtk_message_dialog_

=for position SYNOPSIS

=head1 SYNOPSIS

  #
  # A modal dialog.  Note that the message is a printf-style format.
  #
  $dialog = Gtk2::MessageDialog->new ($main_application_window,
                                      'destroy-with-parent',
                                      'question', # message type
                                      'yes-no', # which set of buttons?
                                      "Pay me $%.2f?", $amount);
  $response = $dialog->run;
  if ($response eq 'yes') {
      send_bill ();
  }
  $dialog->destroy;

  #
  # A non-modal dialog.
  #
  $dialog = Gtk2::MessageDialog->new ($main_application_window,
                                      'destroy-with-parent',
                                      'question', # message type
                                      'ok-cancel', # which set of buttons?
                                      "Self-destruct now?");
  # react whenever the user responds.
  $dialog->signal_connect (response => sub {
             my ($self, $response) = @_;
             if ($response eq 'ok') {
                     do_the_thing ();
             }
             $self->destroy;
  });
  $dialog->show_all;

=cut


=for position DESCRIPTION

=head1 DESCRIPTION


Gtk2::MessageDialog is a dialog with an image representing the type of message
(Error, Question, etc.) alongside some message text.  It's simply a convenience
widget; you could construct the equivalent of Gtk2::MessageDialog from Gtk2::Dialog
without too much effort, but Gtk2::MessageDialog saves typing and helps create a
consistent look and feel for your application.

The easiest way to do a modal message dialog is to use C<< $dialog->run >>, which
automatically makes your dialog modal and waits for the user to respond to it.
You can also pass in the GTK_DIALOG_MODAL flag when creating the MessageDialog.

=cut


=for apidoc
=for args format a printf format specifier.  may be undef.
=for args ... arguments for I<$format>
Create a new Gtk2::Dialog with a simple message.  It will also include an
icon, as determined by I<$type>.  If you need buttons not available through
Gtk2::ButtonsType, use 'none' and add buttons with C<< $dialog->add_buttons >>.
=cut
GtkWidget *
gtk_message_dialog_new (class, parent, flags, type, buttons, format, ...)
	GtkWindow_ornull * parent
	GtkDialogFlags flags
	GtkMessageType type
	GtkButtonsType buttons
	SV * format
    CODE:
	if (gperl_sv_is_defined (format))
		/* the double-indirection is necessary to avoid % chars in the
		 * message string being misinterpreted. */
		RETVAL = gtk_message_dialog_new (
		           parent, flags, type, buttons,
	                   "%s",
		           format_message (format, &(ST (6)), items - 6));
	else
		RETVAL = gtk_message_dialog_new (parent, flags, type,
		                                 buttons, NULL);
		/* -Wall warns about the NULL format string here, but
		 * gtk_message_dialog_new() explicitly allows it. */
    OUTPUT:
	RETVAL

#if GTK_CHECK_VERSION(2,4,0)

=for apidoc
=for arg message a string containing Pango markup
Like C<new>, but allowing Pango markup tags in the message.  Note that this
version is not variadic.
=cut
GtkWidget *
gtk_message_dialog_new_with_markup (class, parent, flags, type, buttons, message)
	GtkWindow_ornull * parent
	GtkDialogFlags flags
	GtkMessageType type
	GtkButtonsType buttons
	gchar_ornull * message
    CODE:
	/* -Wall warns about the NULL format string here, but
	 * gtk_message_dialog_new() explicitly allows it. */
	RETVAL = gtk_message_dialog_new (parent, flags, type, buttons, NULL);
	gtk_message_dialog_set_markup (GTK_MESSAGE_DIALOG (RETVAL), message);
    OUTPUT:
	RETVAL

void
gtk_message_dialog_set_markup (GtkMessageDialog *message_dialog, const gchar *str)

#endif

#if GTK_CHECK_VERSION(2,6,0)

void
gtk_message_dialog_format_secondary_text (message_dialog, message_format, ...)
	GtkMessageDialog *message_dialog
	SV * message_format
    CODE:
	if (gperl_sv_is_defined (message_format))
		gtk_message_dialog_format_secondary_text (
		  message_dialog,
		  "%s",
		  format_message (message_format, &(ST (2)), items - 2));
	else
		gtk_message_dialog_format_secondary_text (message_dialog, NULL);

void
gtk_message_dialog_format_secondary_markup (message_dialog, message_format, ...)
	GtkMessageDialog *message_dialog
	SV * message_format
    CODE:
	if (gperl_sv_is_defined (message_format))
		gtk_message_dialog_format_secondary_markup (
		  message_dialog,
		  "%s",
		  format_message (message_format, &(ST (2)), items - 2));
	else
		gtk_message_dialog_format_secondary_markup (message_dialog, NULL);

#endif

#if GTK_CHECK_VERSION(2,10,0)

void gtk_message_dialog_set_image (GtkMessageDialog *dialog, GtkWidget *image);

#endif

#if GTK_CHECK_VERSION (2, 14, 0)

GtkWidget* gtk_message_dialog_get_image (GtkMessageDialog *dialog);

#endif /* 2.14 */

#if GTK_CHECK_VERSION (2, 22, 0)

GtkWidget * gtk_message_dialog_get_message_area (GtkMessageDialog *message_dialog);

#endif /* 2.22 */
