#include "unique-perl.h"


MODULE = Gtk2::UniqueMessageData  PACKAGE = Gtk2::UniqueMessageData  PREFIX = unique_message_data_

=for object Gtk2::UniqueMessageData - Message container for Gtk2::UniqueApp
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

This class wraps the messages passed to a C<Gtk2::UniqueApp>. Usually you will
never create a message with the Perl API has this is done by the bindings on
your behalf. Since messages are only read through the Perl bidings the methods
for setting the contents of a message are not accessible.

What's important to understand is that a C<Gtk2::MessageData> is a generic
container for all message types (text, data, filename and uris). There's no way
to query what kind of message a C<Gtk2::MessageData> holds. It is the
responsability of each application to know it in advance and to call the proper
get methods. If you don't call the proper get method you could have a
segmentation fault in your application as the C library will try to unmarshall
the message with the wrong code.

You can retrieve the data set using C<Gkt2::MessageData::get()>,
C<Gkt2::MessageData::get_text()> or C<Gkt2::MessageData::get_uris()>.

=cut


=for apidoc

Retrieves the raw data of the message.

=cut
SV*
unique_message_data_get (UniqueMessageData *message_data)
	PREINIT:
		const guchar *string = NULL;
		gsize length = 0;
		
	CODE:
		string = unique_message_data_get(message_data, &length);
		if (string == NULL) {XSRETURN_UNDEF;}
		
		RETVAL = newSVpvn(string, length);
	
	OUTPUT:
		RETVAL


=for apidoc

Retrieves the text.

=cut
gchar*
unique_message_data_get_text (UniqueMessageData *message_data)


=for apidoc

Retrieves the filename.

=cut
gchar*
unique_message_data_get_filename (UniqueMessageData *message_data)


=for apidoc

Retrieves the URIs as an array.

=cut
void
unique_message_data_get_uris (UniqueMessageData *message_data)
	PREINIT:
		gchar **uris = NULL;
		gchar *uri = NULL;
		gint i = 0;
		
	PPCODE:
		uris = unique_message_data_get_uris(message_data);
		if (uris == NULL) {XSRETURN_EMPTY;}
		
		for (i = 0; TRUE; ++i) {
			uri = uris[i];
			if (uri == NULL) {break;}
			
			XPUSHs(sv_2mortal(newSVGChar(uri)));
		}
		g_strfreev(uris);


=for apidoc

Returns a pointer to the screen from where the message came. You can use
C<Gkt2::Window::set_screen()> to move windows or dialogs to the right screen.
This field is always set by the Unique library.

=cut
GdkScreen*
unique_message_data_get_screen (UniqueMessageData *message_data)


=for apidoc

Retrieves the startup notification id set inside message_data. This field is
always set by the Unique library.
=cut
const gchar*
unique_message_data_get_startup_id (UniqueMessageData *message_data)


=for apidoc

Retrieves the workspace number from where the message came. This field is
always set by the Unique library.

=cut
guint
unique_message_data_get_workspace (UniqueMessageData *message_data)

