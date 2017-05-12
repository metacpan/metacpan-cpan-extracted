=head1 NAME

EV::Glib - Embed the glib main loop into EV

=head1 SYNOPSIS

 use EV::Glib;

=head1 DESCRIPTION

If you want to use EV in a Glib/Gtk+ program, then you need to look at
the Glib::EV module, not this one, as this module requires you to run EV
in your main program.

If you want to use Glib/Gtk+ in an EV program, you are at the right place
here.

This module embeds the Glib main loop into EV, that is, EV will also handle
Glib events.

This makes Glib compatible to EV. Calls into the EV main loop are more
or less equivalent to calls to Glib::MainLoop (but not vice versa, you
I<have> to use the EV loop functions).

=over 4

=item * The Glib perl module is not used.

This module has no dependency on the existing Glib perl interface, as it
uses glib directly. The Glib module can, however, be used without any
problems (as long as everybody uses shared libraries to keep everybody
else happy).

=item * The default context will be added to EV when the module is loaded.

Loading this module will automatically integrate the default context into
EV, so normally nothing else is required.

=item * There will be no g_main_loop or gtk_main loop available.

The EV event loop is not the gtk+ main loop. That means that things like
C<gtk_main_quit> will not work at all, as there is no glib mainloop. You
I<have> to use EV's equivalents, i.e. C<EV::unloop>.

=item * You cannot call any glib loop functions while its context is active.

This module uses a prepare watcher at lowest priority to dispatch glib
events and activate the main context. The context will be deactivated in a
check watcher of highest priority.

That means that glib events will be dispatched with lowest priority, and
that you cannot call any glib main functions (or functions calling it) on
the default mainloop in highest-priority watchers and in lowest-priority
prepare watchers.

=item * EV::Glib watchers will (currently) keep the mainloop alive.

That means that, after loading this module, C<EV::loop> calls will never
return unless you call C<EV::unloop> explicitly. Future versions might fix
this problem so that Glib keeps the EV loop alive only when it has active
events waiting.

=cut

package EV::Glib;

use Carp ();
use EV ();

BEGIN {
   $VERSION = '2.01';

   require XSLoader;
   XSLoader::load (EV::Glib, $VERSION);

   install (undef);
}

=back

=cut

=head1 BUGS

  * No documented API to use other main contexts.

=head1 SEE ALSO

L<EV>, L<Glib::EV>, L<Glib>, L<Glib::MainLoop>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

