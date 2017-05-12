/*
 * Copyright (c) 2003-2005 by the gtk2-perl team (see the file AUTHORS)
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
 * The next three functions are also used in GtkInfoBar.xs, thus they are not
 * declared static.
 */

/*
 * GtkDialog interprets the response id as completely user-defined for
 * positive values, and as special enums for negative values.  so, we
 * will handle the response_id as a plain SV so we can implement this
 * special behavior.
 */

gint
gtk2perl_dialog_response_id_from_sv (SV * sv)
{
	int n;
	if (looks_like_number (sv))
		return SvIV (sv);
	if (!gperl_try_convert_enum (GTK_TYPE_RESPONSE_TYPE, sv, &n))
		croak ("response_id should be either a GtkResponseType or an integer");
	return n;
}

SV *
gtk2perl_dialog_response_id_to_sv (gint response)
{
	return gperl_convert_back_enum_pass_unknown (GTK_TYPE_RESPONSE_TYPE,
	                                             response);
}

/*
GtkDialog's response event is defined in Gtk as having a signal parameter
of type G_TYPE_INT, but GtkResponseType values are passed through it.

this custom marshaller allows us to catch and convert enum codes like those
returned by $dialog->run , instead of requiring the callback to deal with
the raw negative numeric values for the predefined constants.
*/
void
gtk2perl_dialog_response_marshal (GClosure * closure,
                                  GValue * return_value,
                                  guint n_param_values,
                                  const GValue * param_values,
                                  gpointer invocation_hint,
                                  gpointer marshal_data)
{
	dGPERL_CLOSURE_MARSHAL_ARGS;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	PERL_UNUSED_VAR (return_value);
	PERL_UNUSED_VAR (n_param_values);
	PERL_UNUSED_VAR (invocation_hint);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	/* the second parameter for this signal is defined as an int
	 * but is actually a response code, and can have GtkResponseType
	 * values. */
	XPUSHs (sv_2mortal (gtk2perl_dialog_response_id_to_sv
				(g_value_get_int (param_values + 1))));

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_DISCARD);

	/*
	 * clean up 
	 */

	FREETMPS;
	LEAVE;
}

MODULE = Gtk2::Dialog	PACKAGE = Gtk2::Dialog	PREFIX = gtk_dialog_

=for position SYNOPSIS

=head1 SYNOPSIS

  # create a new dialog with some buttons - one stock, one not.
  $dialog = Gtk2::Dialog->new ($title, $parent_window, $flags,
                               'gtk-cancel' => 'cancel',
                               'Do it'      => 'ok');
  # create window contents for yourself.
  $dialog->get_content_area ()->add ($some_widget);

  $dialog->set_default_response ('ok');

  # show and interact modally -- blocks until the user
  # activates a response.
  $response = $dialog->run;
  if ($response eq 'ok') {
      do_the_stuff ();
  }

  # activating a response does not destroy the window,
  # that's up to you.
  $dialog->destroy;

=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Dialog boxes are a convenient way to prompt the user for a small amount of
input, eg. to display a message, ask a question, or anything else that does not
require extensive effort on the user's part. 

GTK+ treats a dialog as a window split vertically. The top section is a
Gtk2::VBox, and is where widgets such as a Gtk2::Label or a Gtk2::Entry should
be packed. The bottom area is known as the "action_area". This is generally
used for packing buttons into the dialog which may perform functions such as
cancel, ok, or apply.  The two areas are separated by a Gtk2::HSeparator. 

GtkDialog boxes are created with a call to C<< Gtk2::Dialog->new >>.  The
multi-argument form (and its alias, C<new_with_buttons> is recommended; it
allows you to set the dialog title, some convenient flags, and add simple
buttons all in one go.

If I<$dialog> is a newly created dialog, the two primary areas of the window
can be accessed as C<< $dialog->get_content_area () >> and
C<< $dialog->get_action_area () >>, as can be seen from the example, below.

A 'modal' dialog (that is, one which freezes the rest of the application from
user input), can be created by calling the Gtk2::Window method C<set_modal> on
the dialog.  You can also pass the 'modal' flag to C<new>.

If you add buttons to GtkDialog using C<new>, C<new_with_buttons>,
C<add_button>, C<add_buttons>, or C<add_action_widget>, clicking the button
will emit a signal called "response" with a response ID that you specified.
GTK+ will never assign a meaning to positive response IDs; these are entirely
user-defined.  But for convenience, you can use the response IDs in the
Gtk2::ResponseType enumeration.  If a dialog receives a delete event, the
"response" signal will be emitted with a response ID of 'delete-event'.

If you want to block waiting for a dialog to return before returning control
flow to your code, you can call C<< $dialog->run >>.  This function enters a
recursive main loop and waits for the user to respond to the dialog, returning
the  response ID corresponding to the button the user clicked. 

For the simple dialog in the following example, in reality you'd probably use
Gtk2::MessageDialog to save yourself some effort.  But you'd need to create the
dialog contents manually if you had more than a simple message in the dialog. 

 # Function to open a dialog box displaying the message provided.
 
 sub quick_message {
    my $message = shift;
    my $dialog = Gtk2::Dialog->new ('Message', $main_app_window,
                                    'destroy-with-parent',
                                    'gtk-ok' => 'none');
    my $label = Gtk2::Label->new (message);
    $dialog->get_content_area ()->add ($label);

    # Ensure that the dialog box is destroyed when the user responds.
    $dialog->signal_connect (response => sub { $_[0]->destroy });

    $dialog->show_all;
 }

=head2 Delete, Close and Destroy

In the default keybindings the "Esc" key calls the C<close> action
signal.  The default in that signal is to synthesise a C<delete-event>
like a window manager close would do.

A delete-event first runs the C<response> signal with ID
C<"delete-event">, but the handler there can't influence the default
destroy behaviour of the C<delete-event> signal.  See L<Gtk2::Window>
for notes on destroy vs hide.

If you add your own "Close" button to the dialog, perhaps using the
builtin C<close> response ID, you must make your C<response> signal
handler do whatever's needed for closing.  Often a good thing is just
to run the C<close> action signal the same as the Esc key.

    sub my_response_handler {
      my ($dialog, $response) = @_;
      if ($response eq 'close') {
        $self->signal_emit ('close');

      } elsif ...
    }

=cut

=for position post_signals

Note that currently in a Perl subclass of C<Gtk2::Dialog> a class
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

=for enum GtkDialogFlags
=cut

BOOT:
	gperl_signal_set_marshaller_for (GTK_TYPE_DIALOG, "response",
	                                 gtk2perl_dialog_response_marshal);

=for apidoc Gtk2::Dialog::vbox __hide__
=cut

=for apidoc Gtk2::Dialog::action_area __hide__
=cut

GtkWidget *
get_content_area (dialog)
	GtkDialog * dialog
    ALIAS:
	Gtk2::Dialog::vbox = 1
	Gtk2::Dialog::get_action_area = 2
	Gtk2::Dialog::action_area = 3
    CODE:
	switch(ix) {
	case 0:
	case 1:
#if GTK_CHECK_VERSION (2, 14, 0)
		RETVAL = gtk_dialog_get_content_area (dialog);
#else
		RETVAL = dialog->vbox;
#endif
		break;
	case 2:
	case 3:
#if GTK_CHECK_VERSION (2, 14, 0)
		RETVAL = gtk_dialog_get_action_area (dialog);
#else
		RETVAL = dialog->action_area;
#endif
		break;
	default:
		RETVAL = NULL;
		g_assert_not_reached ();
	}
    OUTPUT:
	RETVAL

##GtkWidget *
##gtk_dialog_new (class)
##
##GtkWidget* gtk_dialog_new_with_buttons (const gchar     *title,
##                                        GtkWindow       *parent,
##                                        GtkDialogFlags   flags,
##                                        const gchar     *first_button_text,
##                                        ...);

=for apidoc Gtk2::Dialog::new_with_buttons
=for signature $widget = Gtk2::Dialog->new_with_buttons ($title, $parent, $flags, ...)
=for arg ... of button-text => response-id pairs.

Alias for the multi-argument version of C<< Gtk2::Dialog->new >>.

=cut

=for apidoc
=for signature $widget = Gtk2::Dialog->new;
=for signature $widget = Gtk2::Dialog->new ($title, $parent, $flags, ...)
=for arg title (string) window title
=for arg parent (GtkWindow_ornull) make the new dialog transient for this window
=for arg flags (GtkDialogFlags) interesting properties
=for arg ... of button-text => response-id pairs.

The multi-argument form takes the same list of text => response-id pairs as
C<< $dialog->add_buttons >>.  Do not pack widgets directly into the window;
add them to C<< $dialog->get_content_area () >>.

Here's a simple example:

 $dialog = Gtk2::Dialog->new ('A cool dialog',
                              $main_app_window,
                              [qw/modal destroy-with-parent/],
                              'gtk-ok'     => 'accept',
                              'gtk-cancel' => 'reject');

=cut
GtkWidget *
gtk_dialog_new (class, ...)
    ALIAS:
	Gtk2::Dialog::new_with_buttons = 1
    PREINIT:
	int i;
	gchar * title;
	GtkWidget * dialog;
	GtkWindow * parent;
	int flags;
    CODE:
	PERL_UNUSED_VAR (ix);
	if (items == 1) {
		/* the easy way out... */
		dialog = gtk_dialog_new ();

	} else if ((items < 4) || (items % 2)) {
		croak ("USAGE: Gtk2::Dialog->new ()\n"
		       "  or Gtk2::Dialog->new (TITLE, PARENT, FLAGS, ...)\n"
		       "  where ... is a series of button text and response id pairs");
	} else {
		title = SvGChar (ST (1));
		parent = SvGtkWindow_ornull (ST (2));
		flags = SvGtkDialogFlags (ST (3));

		/* we can't really pass on a varargs call (at least, i don't
		 * know how to convert from perl stack to C va_list), so we
		 * have to duplicate a bit of the functionality of the C
		 * version.  luckily it's nothing too intense. */

		dialog = gtk_dialog_new ();
		if (title)
			gtk_window_set_title (GTK_WINDOW (dialog), title);
		if (parent)
			gtk_window_set_transient_for (GTK_WINDOW (dialog), parent);
		if (flags & GTK_DIALOG_MODAL)
			gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
		if (flags & GTK_DIALOG_DESTROY_WITH_PARENT)
			gtk_window_set_destroy_with_parent (GTK_WINDOW (dialog), TRUE);
		if (flags & GTK_DIALOG_NO_SEPARATOR)
			gtk_dialog_set_has_separator (GTK_DIALOG (dialog), FALSE);

		/* skip the first 4 stack items --- we've already seen them! */
		for (i = 4; i < items; i += 2) {
			gchar * text = SvGChar (ST (i));
			int response_id =
				gtk2perl_dialog_response_id_from_sv (ST (i+1));
			gtk_dialog_add_button (GTK_DIALOG (dialog), text,
			                       response_id);
		}
	}
	RETVAL = dialog;
    OUTPUT:
	RETVAL


=for apidoc
=for signature $responsetype = $dialog->run
Blocks in a recursive main loop until the dialog either emits the response
signal, or is destroyed.  If the dialog is destroyed during the call to
C<< $dialog->run >>, the function returns 'GTK_RESPONSE_NONE' ('none').
Otherwise, it returns the response ID from the "response" signal emission.
Before entering the recursive main loop, C<< $dialog->run >> calls
C<< $widget->show >> on I<$dialog> for you. Note that you still need to show
any children of the dialog yourself. 

During C<run>, the default behavior of "delete_event" is disabled; if the
dialog receives "delete_event", it will not be destroyed as windows usually
are, and C<run> will return 'delete-event'.
Also, during C<run> the dialog will be modal.  You can force C<run> to return
at any time by calling C<< $dialog->response >> to emit the "response" signal.
Destroying the dialog during C<run> is a very bad idea, because your post-run
code won't know whether the dialog was destroyed or not. 

After C<run> returns, you are responsible for hiding or destroying the dialog
if you wish to do so. 

Typical usage of this function might be: 

  if ('accept' eq $dialog->run) {
         do_application_specific_something ();
  } else {
         do_nothing_since_dialog_was_cancelled ();
  }
  $dialog->destroy;

=cut
SV *
gtk_dialog_run (dialog)
	GtkDialog * dialog
    CODE:
	RETVAL = gtk2perl_dialog_response_id_to_sv (gtk_dialog_run (dialog));
    OUTPUT:
	RETVAL


=for apidoc
=for arg response_id (GtkResponseType)
Emit the response signal, as though the user had clicked on the button with
I<$response_id>.
=cut
void
gtk_dialog_response (dialog, response_id)
	GtkDialog * dialog
	SV        * response_id
    C_ARGS:
	dialog, gtk2perl_dialog_response_id_from_sv (response_id)



=for apidoc
=for arg button_text (string) may be arbitrary text with mnenonics, or stock ids
=for arg response_id (GtkResponseType)
Returns the created button.
=cut
GtkWidget *
gtk_dialog_add_button (dialog, button_text, response_id)
	GtkDialog   * dialog
	const gchar * button_text
	SV          * response_id
    CODE:
	RETVAL = gtk_dialog_add_button (dialog, button_text,
	                                gtk2perl_dialog_response_id_from_sv (
	                                  response_id));
    OUTPUT:
	RETVAL

=for apidoc
=for arg ... of button-text => response-id pairs
Like calling C<< $dialog->add_button >> repeatedly, except you don't get the
created widgets back.  The buttons go from left to right, so the first button
added will be the left-most one.
=cut
void
gtk_dialog_add_buttons (dialog, ...)
	GtkDialog * dialog
    PREINIT:
	int i;
    CODE:
	if (!(items % 2))
		croak("gtk_dialog_add_buttons: odd number of parameters");
	/* we can't make var args, so we'll call add_button for each */
	for (i = 1; i < items; i += 2)
		gtk_dialog_add_button (dialog, SvGChar (ST (i)),
		                       gtk2perl_dialog_response_id_from_sv (
		                         ST (i+1)));

=for apidoc
=for arg response_id (GtkResponseType)
Enable or disable an action button by its I<$response_id>.
=cut
void
gtk_dialog_set_response_sensitive (dialog, response_id, setting)
	GtkDialog * dialog
	SV        * response_id
	gboolean    setting
    CODE:
	gtk_dialog_set_response_sensitive (dialog,
	                                   gtk2perl_dialog_response_id_from_sv (
	                                     response_id),
	                                   setting);

=for apidoc
=for arg response_id (GtkResponseType)
=cut
void
gtk_dialog_add_action_widget (dialog, child, response_id)
	GtkDialog   * dialog
	GtkWidget   * child
	SV          * response_id
    CODE:
	gtk_dialog_add_action_widget (dialog, child,
	                              gtk2perl_dialog_response_id_from_sv (
	                                response_id));


=for apidoc
=for arg response_id (GtkResponseType)
=cut
void
gtk_dialog_set_default_response (dialog, response_id)
	GtkDialog * dialog
	SV        * response_id
    CODE:
	gtk_dialog_set_default_response (dialog,
	                                 gtk2perl_dialog_response_id_from_sv (
	                                   response_id));

void
gtk_dialog_set_has_separator (dialog, setting)
	GtkDialog * dialog
	gboolean   setting

gboolean
gtk_dialog_get_has_separator (dialog)
	GtkDialog * dialog

#if GTK_CHECK_VERSION (2, 6, 0)

##  void gtk_dialog_set_alternative_button_order (GtkDialog *dialog, gint first_response_id, ...)
void
gtk_dialog_set_alternative_button_order (dialog, ...)
	GtkDialog *dialog
    PREINIT:
	gint n_params, i;
	gint *new_order;
    CODE:
	if ((n_params = (items - 1)) > 0) {
		new_order = g_new0 (gint, n_params);
		for (i = 1; i < items; i++)
			new_order[i - 1] = gtk2perl_dialog_response_id_from_sv (
			                     ST (i));

		gtk_dialog_set_alternative_button_order_from_array (
			dialog, n_params, new_order);

		g_free (new_order);
	}

#endif

#if GTK_CHECK_VERSION (2, 8, 0)

##  gint gtk_dialog_get_response_for_widget (GtkDialog *dialog, GtkWidget *widget);
SV *
gtk_dialog_get_response_for_widget (dialog, widget)
	GtkDialog *dialog
	GtkWidget *widget
    PREINIT:
	gint tmp;
    CODE:
	tmp = gtk_dialog_get_response_for_widget (dialog, widget);
	RETVAL = gtk2perl_dialog_response_id_to_sv (tmp);
    OUTPUT:
	RETVAL

#endif

#if GTK_CHECK_VERSION (2, 20, 0)

##  GtkWidget *widget gtk_dialog_get_widget_for_response (GtkDialog *dialog, gint);
=for arg response_id (GtkResponseType)
=cut
GtkWidget *
gtk_dialog_get_widget_for_response (dialog, response_id)
	GtkDialog *dialog
	SV *response_id
    C_ARGS:
	dialog, gtk2perl_dialog_response_id_from_sv (response_id)

#endif

MODULE = Gtk2::Dialog	PACKAGE = Gtk2	PREFIX = gtk_

#if GTK_CHECK_VERSION (2, 6, 0)

# don't override the pod from Gtk2.pm...
=for object Gtk2::main
=cut

##  gboolean gtk_alternative_dialog_button_order (GdkScreen *screen);
gboolean
gtk_alternative_dialog_button_order (class, screen=NULL)
	GdkScreen_ornull *screen
    C_ARGS:
	screen

#endif
