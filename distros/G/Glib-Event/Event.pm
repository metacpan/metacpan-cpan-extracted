=head1 NAME

Glib::Event - Coerce Glib into using the Event module as event loop.

=head1 SYNOPSIS

 use Glib::Event;

 # example with Gtk2:
 use Gtk2 -init;
 use Glib::Event;
 use Event; # any order
 Event->timer (after => 1, interval => 1, cb => sub { print "I am here!\n" });
 main Gtk2;
 # etc., it just works

 # You can even move the glib mainloop into a coroutine:
 use Gtk2 -init;
 use Coro;
 use Coro::Event;
 use Glib::Event;
 async { main Gtk2 };
 # ... do other things

=head1 DESCRIPTION

This module coerces the Glib event loop to use the Event module as
underlying event loop, i.e. Event will be used by Glib for all events.

This makes Glib compatible to Event. Calls into the Glib main loop
are more or less equivalent to calls to C<Event::loop>.

=over 4

=item * The Glib perl module is not used.

This module has no dependency on the existing Glib perl interface, as it
uses glib directly. The Glib module can, however, be used without any
problems.

=item * The default context will be changed when the module is loaded.

Loading this module will automatically "patch" the default context of
libglib, so normally nothing more is required.

=item * Glib does not allow recursive invocations.

This means that none of your event watchers might call into Glib
functions or functions that might call glib functions (basically all Gtk2
functions). It might work, but that's your problem....

=cut

package Glib::Event;

use Carp ();
use Event ();

our $default_poll_func;

BEGIN {
   $VERSION = 0.2;

   require XSLoader;
   XSLoader::load (Glib::Event, $VERSION);

   $default_poll_func = install (undef);
}

=back

=cut

=head1 BUGS

  * No documented API to patch other main contexts.
  * Uses one_event, which is inefficient.

=head1 SEE ALSO

L<Event>, L<Glib>, L<Glib::MainLoop>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

