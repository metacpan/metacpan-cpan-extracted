#include "unique-perl.h"
#include <gperl_marshal.h>

G_CONST_RETURN gchar * unique_command_to_string (UniqueApp *app, gint command);
gint unique_command_from_string (UniqueApp *app, const gchar *command);

static void
perl_unique_app_marshall_message_received (
	GClosure *closure,
	GValue *return_value,
	guint n_param_values,
	const GValue *param_values,
	gpointer invocant_hint,
	gpointer marshal_data)
{
	UniqueApp *app;
	gint command;
	const gchar *command_name;

	dGPERL_CLOSURE_MARSHAL_ARGS;
	PERL_UNUSED_VAR (return_value);
	PERL_UNUSED_VAR (n_param_values);
	PERL_UNUSED_VAR (invocant_hint);

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	ENTER;
	SAVETMPS;
	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);

	app = (UniqueApp *) g_value_get_object (param_values + 0);
	command = g_value_get_int (param_values + 1);
	command_name = (const gchar *) unique_command_to_string (app, command);

	XPUSHs (sv_2mortal (newSVpv (command_name, 0)));
	XPUSHs (sv_2mortal (gperl_sv_from_value (param_values + 2)));
	XPUSHs (sv_2mortal (gperl_sv_from_value (param_values + 3)));

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;

	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_SCALAR);

	SPAGAIN;

	if (count != 1) {
		croak ("message-received handlers need to return a single value");
	}

	g_value_set_enum (return_value, SvUniqueResponse (POPs));

	FREETMPS;
	LEAVE;

}

=for object Gtk2::UniqueApp a single instance application

=cut

MODULE = Gtk2::UniqueApp  PACKAGE = Gtk2::UniqueApp  PREFIX = unique_app_

BOOT:
	gperl_signal_set_marshaller_for (
		UNIQUE_TYPE_APP,
		"message-received",
		perl_unique_app_marshall_message_received
	);

=for object Gtk2::UniqueApp - Base class for singleton applications
=cut

=for position SYNOPSIS

=head1 SYNOPSIS

    use Gtk2 '-init';
    use Gtk2::Unique;

    my $COMMAND_FOO = 1;
    my $COMMAND_BAR = 2;

	my $app = Gtk2::UniqueApp->new(
		"org.example.UnitTets", undef,
		foo => $COMMAND_FOO,
		bar => $COMMAND_BAR,
	);
	if ($app->is_running) {
		# The application is already running, send it a message
		$app->send_message_by_name('foo', text => "Hello world");
	}
	else {
		my $window = Gtk2::Window->new();
		my $label = Gtk2::Label->new("Waiting for a message");
		$window->add($label);
		$window->set_size_request(480, 120);
		$window->show_all();

		$window->signal_connect(delete_event => sub {
			Gtk2->main_quit();
			return TRUE;
		});

		# Watch the main window and register a handler that will be called each time
		# that there's a new message.
		$app->watch_window($window);
		$app->signal_connect('message-received' => sub {
			my ($app, $command, $message, $time) = @_;
			$label->set_text($message->get_text);
			return 'ok';
		});

		Gtk2->main();
	}

=for position DESCRIPTION

=head1 DESCRIPTION

B<Gtk2::UniqueApp> is the base class for single instance applications. You can
either create an instance of UniqueApp via C<Gtk2::UniqueApp-E<gt>new()> and
C<Gtk2::UniqueApp-E<gt>_with_commands()>; or you can subclass Gtk2::UniqueApp
with your own application class.

A Gtk2::UniqueApp instance is guaranteed to either be the first running at the
time of creation or be able to send messages to the currently running instance;
there is no race possible between the creation of the Gtk2::UniqueApp instance
and the call to C<Gtk2::UniqueApp::is_running()>.

The usual method for using the Gtk2::UniqueApp API is to create a new instance,
passing an application-dependent name as construction-only property; the
C<Gtk2::UniqueApp:name> property is required, and should be in the form of a
domain name, like I<org.gnome.YourApplication>.

After the creation, you should check whether an instance of your application is
already running, using C<Gtk2::UniqueApp::is_running()>; if this method returns
C<FALSE> the usual application construction sequence can continue; if it returns
C<TRUE> you can either exit or send a message using L<Gtk2::UniqueMessageData>
and C<Gtk2::UniqueMessageData::send_message()>.

You can define custom commands using C<Gtk2::UniqueApp::add_command()>: you need
to provide an arbitrary integer and a string for the command.

=cut

=for apidoc new_with_commands

An alias for C<Gtk2::UniqueApp-E<gt>new()>.

=cut
=for apidoc

Creates a new Gtk2::UniqueApp instance for name passing a start-up notification
id startup_id. The name must be a unique identifier for the application, and it
must be in form of a domain name, like I<org.gnome.YourApplication>.

If startup_id is C<undef> the DESKTOP_STARTUP_ID environment variable will be
check, and if that fails a "fake" startup notification id will be created.

Once you have created a Gtk2::UniqueApp instance, you should check if any other
instance is running, using C<Gtk2::UniqueApp::is_running()>. If another
instance is running you can send a command to it, using the
C<Gtk2::UniqueApp::send_message()> function; after that, the second instance
should quit. If no other instance is running, the usual logic for creating the
application can follow.

=cut
UniqueApp_noinc*
unique_app_new (class, const gchar *name, const gchar_ornull *startup_id, ...)
	ALIAS:
		new_with_commands = 1

	PREINIT:
		UniqueApp *app = NULL;

	CODE:
		PERL_UNUSED_VAR(ix);

		if (items == 3) {
			app = unique_app_new(name, startup_id);
		}
		else if (items > 3 && (items % 2 == 1)) {
			/* Calling unique_app_new_with_command(), First create a new app with
			   unique_app_new() and then populate the commands one by one with
			   unique_app_add_command().
			 */
			int i;
			app = unique_app_new(name, startup_id);

			for (i = 3; i < items; i += 2) {
				SV *command_name_sv = ST(i);
				SV *command_id_sv = ST(i + 1);
				gchar *command_name = NULL;
				gint command_id;

				if (! looks_like_number(command_id_sv)) {
					g_object_unref(G_OBJECT(app));
					croak(
						"Invalid command_id at position %d, expected a number but got '%s'",
						i,
						SvGChar(command_id_sv)
					);
				}
				command_name = SvGChar(command_name_sv);
				command_id = SvIV(command_id_sv);
				unique_app_add_command(app, command_name, command_id);
			}
		}
		else {
			croak(
				"Usage: Gtk2::UniqueApp->new(name, startup_id)"
				"or Gtk2::UniqueApp->new_with_commands(name, startup_id, @commands)"
			);
		}

		RETVAL = app;

	OUTPUT:
		RETVAL

=for apidoc

Adds command_name as a custom command that can be used by app. You must call
C<Gtk2::UniqueApp::add_command()> before C<Gtk2::UniqueApp::send_message()> in
order to use the newly added command.

The command name is used internally: you need to use the command's logical id in
C<Gtk2::UniqueApp::send_message()> and inside the I<message-received> signal.

=cut
void
unique_app_add_command (UniqueApp *app, const gchar *command_name, gint command_id)


=for apidoc

Makes app "watch" a window. Every watched window will receive startup notification changes automatically.

=cut
void
unique_app_watch_window (UniqueApp *app, GtkWindow *window)

=for apidoc

Checks whether another instance of app is running.

=cut
gboolean
unique_app_is_running (UniqueApp *app)


#
# $app->send_message($ID) -> unique_app_send_message(app, command_id, NULL);
# $app->send_message($ID, text => $text) -> set_text() unique_app_send_message(app, command_id, message);
# $app->send_message($ID, data => $data) -> set() unique_app_send_message(app, command_id, message);
# $app->send_message($ID, uris => @uri) -> set_uris() unique_app_send_message(app, command_id, message);
#
# $app->send_message_by_name('command') -> unique_app_send_message(app, command_id, NULL);
# $app->send_message_by_name('command', text => $text) -> set_text() unique_app_send_message(app, command_id, message);
# $app->send_message_by_name('command', data => $data) -> set() unique_app_send_message(app, command_id, message);
# $app->send_message_by_name('command', uris => @uri) -> set_uris() unique_app_send_message(app, command_id, message);
#
#

=for apidoc send_message

Same as C<Gkt2::UniqueApp::send_message_by_name()>, but uses a message id
instead of a name.

=cut
=for apidoc

Sends command to a running instance of app. If you need to pass data to the
instance, you have to indicate the type of message that will be passed. The
accepted types are:

=over

=item text

A plain text message

=item data

Rad data

=item filename

A file name

=item uris

URI, multiple values can be passed

=back

The running application will receive a I<message-received> signal and will call
the various signal handlers attach to it. If any handler returns a
C<Gtk2::UniqueResponse> different than C<ok>, the emission will stop.

Usages:

	$app->send_message_by_name(write => data => $data);
	$app->send_message_by_name(greet => text => "Hello World!");
	$app->send_message_by_name(open  => uris =>
		'http://search.cpan.org/',
		'http://www.gnome.org/',
	);

B<NOTE>: If you prefer to use an ID instead of a message name then use the
function C<Gkt2::UniqueApp::send_message()>. The usage is the same as this one.

=cut
UniqueResponse
unique_app_send_message_by_name (UniqueApp *app, SV *command, ...)
	ALIAS:
		send_message = 1

	PREINIT:
		UniqueMessageData *message = NULL;
		SV **s = NULL;
		gint command_id = 0;

	CODE:

		switch (ix) {
			case 0:
				{
					gchar *command_name = SvGChar(command);
					command_id = unique_command_from_string(app, command_name);
					if (command_id == 0) {
							croak("Command '%s' isn't registered with the application", command_name);
					}
				}
			break;

			case 1:
				{
					command_id = (gint) SvIV(command);
				}
			break;

			default:
				croak("Method called with the wrong name");
		}

		if (items == 4) {
			SV *sv_data;
			gchar *type;

			message = unique_message_data_new();
			type = SvGChar(ST(2));
			sv_data = ST(3);

			if (g_strcmp0(type, "data") == 0) {
				SV *sv;
				STRLEN length;
				char *data;

				data = SvPV(sv_data, length);
				unique_message_data_set(message, data, length);
			}
			else if (g_strcmp0(type, "text") == 0) {
				STRLEN length;
				char *text;

				length = sv_len(sv_data);
				text = SvGChar(sv_data);
				unique_message_data_set_text(message, text, length);
			}
			else if (g_strcmp0(type, "filename") == 0) {
				SV *sv;
				char *filename;

				filename = SvGChar(sv_data);
				unique_message_data_set_filename(message, filename);
			}
			else if (g_strcmp0(type, "uris") == 0) {
				gchar **uris = NULL;
				gsize length;
				AV *av = NULL;
				int i;

				if (SvTYPE(SvRV(sv_data)) != SVt_PVAV) {
					unique_message_data_free(message);
					croak("Value for the type 'uris' must be an array ref");
				}

				/* Convert the Perl array into a C array of strings */
				av = (AV*) SvRV(sv_data);
				length = av_len(av) + 2; /* last index + extra NULL padding */

				uris = g_new0(gchar *, length);
				for (i = 0; i < length - 1; ++i) {
					SV **uri_sv = av_fetch(av, i, FALSE);
					uris[i] = SvGChar(*uri_sv);
				}
				uris[length - 1] = NULL;

				unique_message_data_set_uris(message, uris);
				g_free(uris);
			}
			else {
				unique_message_data_free(message);
				croak("Parameter 'type' must be: 'data', 'text', 'filename' or 'uris'; got %s", type);
			}
		}
		else if (items == 2) {
			message = NULL;
		}
		else {
			croak(
				"Usage: $app->send_message($id, $type => $data)"
				" or $app->send_message($id, uris => [])"
				" or $app->send_message($id)"
			);
		}

		RETVAL = unique_app_send_message(app, command_id, message);

		if (message) {
			unique_message_data_free(message);
		}

	OUTPUT:
		RETVAL

