#include "unique-perl.h"


MODULE = Gtk2::UniqueBackend  PACKAGE = Gtk2::UniqueBackend  PREFIX = unique_backend_

=for object Gtk2::UniqueBackend - Backend abstraction
=cut

=for position DESCRIPTION

=head1 DESCRIPTION

Gkt2::UniqueBackend is the base, abstract class implemented by the different IPC
mechanisms used by Gtk2::Unique. Each Gtk2::UniqueApp instance creates a
Gkt2::UniqueBackend to request the name or to send messages.

=cut


=for apidoc

Creates a Gkt2::UniqueBackend using the default backend defined at compile time.
You can override the default backend by setting the UNIQUE_BACKEND environment
variable with the name of the desired backend.

=cut
UniqueBackend_noinc*
unique_backend_create (class)
	C_ARGS: /* No args */


const gchar*
unique_backend_get_name (UniqueBackend *backend)


void
unique_backend_set_name (UniqueBackend *backend, const gchar *name)


const gchar*
unique_backend_get_startup_id (UniqueBackend *backend)


void
unique_backend_set_startup_id (UniqueBackend *backend, const gchar *startup_id)


GdkScreen*
unique_backend_get_screen (UniqueBackend *backend)


void
unique_backend_set_screen (UniqueBackend *backend, GdkScreen *screen)


=for apidoc

Retrieves the current workspace.

=cut
guint
unique_backend_get_workspace (UniqueBackend *backend)


=for apidoc

Requests the name set using C<Gtk2::set_name()> and this backend.

=cut
gboolean
unique_backend_request_name  (UniqueBackend *backend)


=for apidoc

Sends command_id, and optionally message_data, to a running instance using
backend.

=cut
UniqueResponse
unique_backend_send_message (UniqueBackend *backend, gint command_id, UniqueMessageData_ornull *message_data, guint time_)

