=head1 NAME

Glib::EV - Coerce Glib into using the EV module as event loop.

=head1 SYNOPSIS

 use Glib::EV;

 # example with Gtk2:
 use Gtk2 -init;
 use Glib::EV;
 use EV; # any order
 my $timer = EV::timer 1, 1, sub { print "I am here!\n" };
 main Gtk2;
 # etc., it just works

 # You can even move the glib mainloop into a coroutine:
 use Gtk2 -init;
 use Coro;
 use Coro::EV;
 use Glib::EV;
 async { main Gtk2 };
 # ... do other things

=head1 DESCRIPTION

If you want to use glib/gtk+ in an EV program, then you need to look at
the EV::Glib module, not this one, as this module requires you to run a
Glib or Gtk+ main loop in your program.

If you want to use EV in an Glib/Gtk+ program, you are at the right place
here.

This module coerces the Glib event loop to use the EV high performance
event loop as underlying event loop, i.e. EV will be used by Glib for all
events.

This makes Glib compatible to EV. Calls into the Glib main loop are more
or less equivalent to calls to C<EV::loop> (but not vice versa, you
I<have> to use the Glib mainloop functions).

=over 4

=item * The Glib perl module is not used.

This module has no dependency on the existing Glib perl interface, as it
uses glib directly. The Glib module can, however, be used without any
problems (as long as everybody uses shared libraries to keep everybody
else happy).

=item * The default context will be changed when the module is loaded.

Loading this module will automatically "patch" the default context of
libglib, so normally nothing more is required.

=item * Glib does not allow recursive invocations.

This means that none of your event watchers might call into Glib
functions or functions that might call glib functions (basically all Gtk2
functions). It might work, but that's your problem....

=cut

package Glib::EV;

use Carp ();
use EV ();

our $default_poll_func;

BEGIN {
   $VERSION = '2.02';

   require XSLoader;
   XSLoader::load (Glib::EV, $VERSION);

   $default_poll_func = install (undef);
}

=back

=cut

=head1 BUGS

  * No documented API to patch other main contexts.

=head1 SEE ALSO

L<EV>, L<Glib>, L<Glib::MainLoop>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

